-- =====================================================
-- 022 — SATIR DÜZEYİ GÜVENLİK (RLS) — ÜÇÜNCÜ DİLİM
--
-- Ölçüt yine aynı: TEK BİR SERVİSİN okuyup yazdığı tablolar.
--
--   facilities, reservations   → reservation-service
--   packages                   → package-service
--   contracts                  → contract-service
--
-- Bu migration'dan önce üç servisin deposu `pkg/dbscope` kullanımına
-- geçirildi. Sıra tersine dönerse uygulama bozulur: RLS açıkken kapsamsız
-- sorgu boş liste döndürür ve modül sessizce "veri yok" demeye başlar.
--
-- DİLİME ALINMAYANLAR VE NEDENİ (dürüstlük için yazılıyor):
--
--   expenses, expense_distributions   → expense-service (tek servis)
--   expense_categories                → expense-service + finance-service
--   meters, meter_readings            → iot + energy_analytics + esg + finance
--
-- `expense_categories` ve sayaç tabloları finance-service tarafından da
-- okunuyor. finance henüz kapsamlı sorguya geçmedi; RLS'i şimdi açmak aidat
-- ve ısı payı hesaplarını ÇALIŞMAZ hâle getirirdi. Bu tablolar, finance
-- geçirildikten sonra ayrı bir migration ile eklenecek. `expenses` tek
-- servisli olmasına rağmen aynı serviste `expense_categories` ile birlikte
-- sorgulandığı için onunla aynı dilime bırakıldı — birini açıp diğerini
-- açmamak, servisi yarı çalışır hâle getirirdi.
--
-- HATIRLATMA: RLS SÜPER KULLANICIYI BAĞLAMAZ. Uygulama `siteeksen_app`
-- rolüyle bağlanmalıdır (bkz. 020).
-- =====================================================

-- -----------------------------------------------------
-- reservation-service
--
-- Her iki tablo da property_id taşır; alt tablo yoktur. `reservations`
-- doğrudan tesis üzerinden de türetilebilirdi ama kendi property_id'si
-- olduğu için doğrudan karşılaştırma hem daha hızlı hem daha açıktır.
-- -----------------------------------------------------
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE facilities FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS facilities_property_scope ON facilities;
CREATE POLICY facilities_property_scope ON facilities
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS reservations_property_scope ON reservations;
CREATE POLICY reservations_property_scope ON reservations
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- package-service
-- -----------------------------------------------------
ALTER TABLE packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE packages FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS packages_property_scope ON packages;
CREATE POLICY packages_property_scope ON packages
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- contract-service
-- -----------------------------------------------------
ALTER TABLE contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE contracts FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS contracts_property_scope ON contracts;
CREATE POLICY contracts_property_scope ON contracts
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
