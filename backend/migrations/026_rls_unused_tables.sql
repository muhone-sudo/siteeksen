-- =====================================================
-- 026 — HENÜZ KULLANILMAYAN TABLOLAR: KORUMASIZ DOĞMASINLAR
--
-- Aşağıdaki tabloları bugün hiçbir servis okumuyor ya da yazmıyor
-- (doğrulandı). Yine de açık bırakılmaz: bir gün bir modül onları kullanmaya
-- başladığında, geliştirici RLS'i hatırlamak zorunda kalmamalı — koruma
-- tabloyla birlikte gelmeli. Kapsamlı sorgu yapmayan yeni kod bu tablolarda
-- BOŞ sonuç alır ve bunu ilk denemede fark eder; tersi (sessiz sızıntı)
-- fark edilmezdi.
--
-- Üç grup:
--   1. Site tabloları            → property_id ile kapsam
--   2. Ortak şablonlu tablolar   → ortak satırlar okunur, yazılamaz
--   3. Platform (SaaS) tabloları → uygulama rolüne HİÇ açık değil
-- =====================================================

-- 1) Site tabloları -----------------------------------------------------------
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['accountability_reports', 'audit_reports', 'bank_accounts',
                             'bank_transactions', 'energy_analytics', 'governing_terms',
                             'management_staff', 'meetings']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_property_scope', t);
        EXECUTE format('CREATE POLICY %I ON %I
                          USING (property_id = current_property_id())
                          WITH CHECK (property_id = current_property_id())',
                       t || '_property_scope', t);
    END LOOP;
END $$;

-- 2) Ortak şablonlu tablolar (property_id IS NULL satırları platform geneli) --
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['chart_of_accounts', 'consumption_tariffs', 'request_categories']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_property_scope', t);
        EXECUTE format('CREATE POLICY %I ON %I
                          USING (property_id IS NULL OR property_id = current_property_id())
                          WITH CHECK (property_id = current_property_id())',
                       t || '_property_scope', t);
    END LOOP;
END $$;

-- Alt tablolar: ebeveyn üzerinden
CREATE INDEX IF NOT EXISTS idx_expense_invoices_expense ON expense_invoices(expense_id);
ALTER TABLE expense_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_invoices FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS expense_invoices_property_scope ON expense_invoices;
CREATE POLICY expense_invoices_property_scope ON expense_invoices
    USING (EXISTS (SELECT 1 FROM expenses e
                   WHERE e.id = expense_invoices.expense_id AND e.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM expenses e
                        WHERE e.id = expense_invoices.expense_id AND e.property_id = current_property_id()));

CREATE INDEX IF NOT EXISTS idx_request_comments_request ON request_comments(request_id);
ALTER TABLE request_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_comments FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS request_comments_property_scope ON request_comments;
CREATE POLICY request_comments_property_scope ON request_comments
    USING (EXISTS (SELECT 1 FROM requests r
                   WHERE r.id = request_comments.request_id AND r.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM requests r
                        WHERE r.id = request_comments.request_id AND r.property_id = current_property_id()));

-- 3) Platform tabloları -------------------------------------------------------
-- tenants / invoices / usage_metrics SaaS abonelik ve faturalamasıdır; bir
-- sitenin verisi değil, PLATFORMUN verisidir. Site servislerinin bunlara
-- erişmesi için hiçbir neden yok (pkg/tenant ölü koddur). schema_migrations
-- da yalnızca migration çalıştırıcısınındır.
REVOKE ALL ON tenants, invoices, usage_metrics, schema_migrations FROM siteeksen_app;
