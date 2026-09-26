-- =====================================================
-- 024 — SATIR DÜZEYİ GÜVENLİK (RLS) — BEŞİNCİ DİLİM + GÖRÜNÜM SIZINTISI
--
-- Bu dilimden önce kalan altı servis kapsamlı sorguya geçirildi:
-- governance, settings, smart_collection, iot, energy_analytics, esg.
-- Böylece ÇOK SERVİSLİ tabloların da bütün tüketicileri kapsamlı oldu:
--
--   monthly_assessments    → finance + governance + smart_collection
--   expense_categories     → expense + finance
--   meters, meter_readings → iot + energy_analytics + esg + finance
--
-- Ayrıca governance'ın 13, settings'in 2, smart_collection'ın 1 tablosu ve
-- hiçbir servisin kullanmadığı defteri kebir tabloları (ledger_entries,
-- ledger_lines — unit_balances görünümü üzerinden okunur) açılır.
--
-- GÖRÜNÜM SIZINTISI (bu migration'ın ikinci amacı):
-- PostgreSQL'de bir görünüm, alttaki tablolara varsayılan olarak GÖRÜNÜMÜN
-- SAHİBİNİN yetkisiyle erişir. Görünümler migration'ı çalıştıran süper
-- kullanıcıya aittir ve RLS süper kullanıcıyı bağlamaz. Sonuç: uygulama rolü
-- `SELECT * FROM monthly_expense_summary` ile 023'ten beri RLS'li olan
-- `expenses` tablosunun TÜM SİTELERE ait özetini okuyabiliyordu.
-- `security_invoker = true` (PostgreSQL 15+) görünümün sorgulayanın
-- yetkisiyle, dolayısıyla onun RLS kapsamıyla çalışmasını sağlar.
-- Doğrulama betiği bundan sonra eklenecek her görünümü de denetler.
--
-- DİLİM DIŞINDA KALANLAR (bilerek; gerekçe tasks/todo.md 2.6):
--   users, properties, units, resident_units, property_roles
--   → kimlik ve dizin tabloları. identity-service bir kullanıcının BÜTÜN
--     sitelerini listelemek zorundadır (site seçimi); tek site kapsamı bu
--     tablolara uymaz. Ayrı bir tasarım gerektirir.
--
-- HATIRLATMA: RLS SÜPER KULLANICIYI BAĞLAMAZ (bkz. 020).
-- =====================================================

-- -----------------------------------------------------
-- Ortak finans tabloları
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_monthly_assessments_property ON monthly_assessments(property_id);
ALTER TABLE monthly_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_assessments FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS monthly_assessments_property_scope ON monthly_assessments;
CREATE POLICY monthly_assessments_property_scope ON monthly_assessments
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- Ortak şablon kalemleri (property_id IS NULL) her sitede OKUNUR, uygulama
-- rolüyle YAZILAMAZ — asset_categories ile aynı model (021).
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS expense_categories_property_scope ON expense_categories;
CREATE POLICY expense_categories_property_scope ON expense_categories
    USING (property_id IS NULL OR property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- Sayaçlar bağımsız bölüme bağlıdır (iot her sorguda units ile birleştirir;
-- dairesiz sayaç zaten hiçbir ekranda görünmez).
ALTER TABLE meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE meters FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS meters_property_scope ON meters;
CREATE POLICY meters_property_scope ON meters
    USING (EXISTS (SELECT 1 FROM units u
                   WHERE u.id = meters.unit_id AND u.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM units u
                        WHERE u.id = meters.unit_id AND u.property_id = current_property_id()));

-- meter_readings → meters → units. İç alt sorgu `meters`'in kendi politikasına
-- da tabidir; iki katman aynı sonucu verir.
ALTER TABLE meter_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meter_readings FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS meter_readings_property_scope ON meter_readings;
CREATE POLICY meter_readings_property_scope ON meter_readings
    USING (EXISTS (SELECT 1 FROM meters m JOIN units u ON u.id = m.unit_id
                   WHERE m.id = meter_readings.meter_id AND u.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM meters m JOIN units u ON u.id = m.unit_id
                        WHERE m.id = meter_readings.meter_id AND u.property_id = current_property_id()));

-- Defteri kebir: ledger_lines, fiş (ledger_entries) üzerinden.
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ledger_entries_property_scope ON ledger_entries;
CREATE POLICY ledger_entries_property_scope ON ledger_entries
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

CREATE INDEX IF NOT EXISTS idx_ledger_lines_entry ON ledger_lines(entry_id);
ALTER TABLE ledger_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_lines FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ledger_lines_property_scope ON ledger_lines;
CREATE POLICY ledger_lines_property_scope ON ledger_lines
    USING (EXISTS (SELECT 1 FROM ledger_entries e
                   WHERE e.id = ledger_lines.entry_id AND e.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM ledger_entries e
                        WHERE e.id = ledger_lines.entry_id AND e.property_id = current_property_id()));

-- -----------------------------------------------------
-- settings-service, smart_collection-service
-- -----------------------------------------------------
ALTER TABLE property_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_settings FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS property_settings_property_scope ON property_settings;
CREATE POLICY property_settings_property_scope ON property_settings
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

CREATE INDEX IF NOT EXISTS idx_property_setting_history_property ON property_setting_history(property_id);
ALTER TABLE property_setting_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_setting_history FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS property_setting_history_property_scope ON property_setting_history;
CREATE POLICY property_setting_history_property_scope ON property_setting_history
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE payment_risk_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_risk_scores FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payment_risk_scores_property_scope ON payment_risk_scores;
CREATE POLICY payment_risk_scores_property_scope ON payment_risk_scores
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- governance-service — üst tablolar (property_id taşır)
-- -----------------------------------------------------
ALTER TABLE operating_budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_budgets FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS operating_budgets_property_scope ON operating_budgets;
CREATE POLICY operating_budgets_property_scope ON operating_budgets
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE assemblies ENABLE ROW LEVEL SECURITY;
ALTER TABLE assemblies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assemblies_property_scope ON assemblies;
CREATE POLICY assemblies_property_scope ON assemblies
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE books FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS books_property_scope ON books;
CREATE POLICY books_property_scope ON books
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE legal_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_cases FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS legal_cases_property_scope ON legal_cases;
CREATE POLICY legal_cases_property_scope ON legal_cases
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- governance-service — alt tablolar (ebeveyn üzerinden)
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_operating_budget_items_budget ON operating_budget_items(budget_id);
ALTER TABLE operating_budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_budget_items FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS operating_budget_items_property_scope ON operating_budget_items;
CREATE POLICY operating_budget_items_property_scope ON operating_budget_items
    USING (EXISTS (SELECT 1 FROM operating_budgets b
                   WHERE b.id = operating_budget_items.budget_id AND b.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM operating_budgets b
                        WHERE b.id = operating_budget_items.budget_id AND b.property_id = current_property_id()));

-- UNIQUE (budget_id, unit_id) indeksi politikayı karşılar.
ALTER TABLE operating_budget_unit_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE operating_budget_unit_shares FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS operating_budget_unit_shares_property_scope ON operating_budget_unit_shares;
CREATE POLICY operating_budget_unit_shares_property_scope ON operating_budget_unit_shares
    USING (EXISTS (SELECT 1 FROM operating_budgets b
                   WHERE b.id = operating_budget_unit_shares.budget_id AND b.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM operating_budgets b
                        WHERE b.id = operating_budget_unit_shares.budget_id AND b.property_id = current_property_id()));

CREATE INDEX IF NOT EXISTS idx_budget_objections_budget ON budget_objections(budget_id);
ALTER TABLE budget_objections ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_objections FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS budget_objections_property_scope ON budget_objections;
CREATE POLICY budget_objections_property_scope ON budget_objections
    USING (EXISTS (SELECT 1 FROM operating_budgets b
                   WHERE b.id = budget_objections.budget_id AND b.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM operating_budgets b
                        WHERE b.id = budget_objections.budget_id AND b.property_id = current_property_id()));

-- UNIQUE (assembly_id, order_no) indeksi politikayı karşılar.
ALTER TABLE assembly_agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE assembly_agenda_items FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assembly_agenda_items_property_scope ON assembly_agenda_items;
CREATE POLICY assembly_agenda_items_property_scope ON assembly_agenda_items
    USING (EXISTS (SELECT 1 FROM assemblies a
                   WHERE a.id = assembly_agenda_items.assembly_id AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM assemblies a
                        WHERE a.id = assembly_agenda_items.assembly_id AND a.property_id = current_property_id()));

-- UNIQUE (assembly_id, unit_id) indeksi politikayı karşılar.
ALTER TABLE assembly_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE assembly_attendees FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assembly_attendees_property_scope ON assembly_attendees;
CREATE POLICY assembly_attendees_property_scope ON assembly_attendees
    USING (EXISTS (SELECT 1 FROM assemblies a
                   WHERE a.id = assembly_attendees.assembly_id AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM assemblies a
                        WHERE a.id = assembly_attendees.assembly_id AND a.property_id = current_property_id()));

-- Kullanılmıyor (vekâlet assembly_attendees'te tutuluyor) ama açık bırakılmaz:
-- bir gün kullanılmaya başlandığında korumasız doğmasın.
ALTER TABLE assembly_proxies ENABLE ROW LEVEL SECURITY;
ALTER TABLE assembly_proxies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assembly_proxies_property_scope ON assembly_proxies;
CREATE POLICY assembly_proxies_property_scope ON assembly_proxies
    USING (EXISTS (SELECT 1 FROM assemblies a
                   WHERE a.id = assembly_proxies.assembly_id AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM assemblies a
                        WHERE a.id = assembly_proxies.assembly_id AND a.property_id = current_property_id()));

-- assembly_votes → gündem maddesi → toplantı. UNIQUE (agenda_item_id, unit_id)
-- indeksi politikayı karşılar.
ALTER TABLE assembly_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE assembly_votes FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assembly_votes_property_scope ON assembly_votes;
CREATE POLICY assembly_votes_property_scope ON assembly_votes
    USING (EXISTS (SELECT 1 FROM assembly_agenda_items ai JOIN assemblies a ON a.id = ai.assembly_id
                   WHERE ai.id = assembly_votes.agenda_item_id AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM assembly_agenda_items ai JOIN assemblies a ON a.id = ai.assembly_id
                        WHERE ai.id = assembly_votes.agenda_item_id AND a.property_id = current_property_id()));

ALTER TABLE book_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_entries FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS book_entries_property_scope ON book_entries;
CREATE POLICY book_entries_property_scope ON book_entries
    USING (EXISTS (SELECT 1 FROM books b
                   WHERE b.id = book_entries.book_id AND b.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM books b
                        WHERE b.id = book_entries.book_id AND b.property_id = current_property_id()));

CREATE INDEX IF NOT EXISTS idx_legal_case_events_case ON legal_case_events(case_id);
ALTER TABLE legal_case_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_case_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS legal_case_events_property_scope ON legal_case_events;
CREATE POLICY legal_case_events_property_scope ON legal_case_events
    USING (EXISTS (SELECT 1 FROM legal_cases c
                   WHERE c.id = legal_case_events.case_id AND c.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM legal_cases c
                        WHERE c.id = legal_case_events.case_id AND c.property_id = current_property_id()));

-- -----------------------------------------------------
-- GÖRÜNÜMLER — sorgulayanın yetkisiyle çalışsın
-- -----------------------------------------------------
ALTER VIEW unit_balances              SET (security_invoker = true);
ALTER VIEW monthly_collection_summary SET (security_invoker = true);
ALTER VIEW monthly_expense_summary    SET (security_invoker = true);
ALTER VIEW pii_encryption_status      SET (security_invoker = true);
-- Katalog görünümleri: pg_catalog herkese açıktır, davranış değişmez. Kural
-- istisnasız olsun diye bunlar da çevrilir (doğrulama TÜM görünümleri denetler).
ALTER VIEW rls_enabled_tables         SET (security_invoker = true);
ALTER VIEW rls_effective              SET (security_invoker = true);
