-- =====================================================
-- 023 — SATIR DÜZEYİ GÜVENLİK (RLS) — DÖRDÜNCÜ DİLİM
--
-- Ölçüt aynı: TEK BİR SERVİSİN okuyup yazdığı tablolar. Bu dilimden önce
-- finance, expense ve community servislerinin depoları `pkg/dbscope`
-- kullanımına geçirildi.
--
--   payments, payment_assessments, late_fee_accruals,
--   assessment_details, consumption_invoices          → finance-service
--   expenses, expense_distributions                   → expense-service
--   requests, announcements, announcement_reads       → community-service
--
-- 022'de `expenses`, `expense_categories` ile aynı dilime bırakılmıştı. Bu
-- gerekçe yanlıştı: kapsamlı sorgu yapan bir servis için kategori tablosunun
-- RLS'siz kalması hiçbir şeyi bozmaz, yalnızca o tabloyu korumasız bırakır.
-- Bozan, KAPSAMSIZ sorgunun RLS'li tabloya çarpmasıdır; expense artık
-- kapsamlı sorgu yapıyor.
--
-- DİLİME ALINMAYANLAR (çok servisli; hepsi geçirilmeden açılamaz):
--   expense_categories     → expense + finance
--   monthly_assessments    → finance + governance + smart_collection
--   meters, meter_readings → iot + energy_analytics + esg + finance
--
-- `monthly_assessments` RLS'siz olsa da ona bağlı alt tabloların politikası
-- onun `property_id`'sini kullanır; bu güvenlidir çünkü karşılaştırma
-- politikanın içinde yapılır, uygulamanın filtresine güvenilmez.
--
-- HATIRLATMA: RLS SÜPER KULLANICIYI BAĞLAMAZ (bkz. 020).
-- =====================================================

-- -----------------------------------------------------
-- payments — property_id kolonu EKLENİR
--
-- Ödemenin sitesi bugüne kadar yalnızca dolaylı olarak biliniyordu:
-- `unit_id` üzerinden (ama birden çok daireyi kapsayan ödemede unit_id BOŞ
-- bırakılır) ya da payment_assessments → monthly_assessments üzerinden (ama
-- ödeme satırı alt satırlardan ÖNCE yazıldığı için INSERT anında bu yol
-- yoktur ve WITH CHECK her yeni ödemeyi reddederdi). Doğrudan kolon hem
-- politikayı mümkün kılar hem de site bazlı ödeme raporunu (gap B56) basit
-- bir filtreye indirger.
--
-- Mevcut satırlar tahakkuk üzerinden doldurulur. Tahakkuku olmayan ödeme
-- (veri hatası) NULL kalır ve RLS altında GÖRÜNMEZ — sessizce bir siteye
-- atanmaz. Yeni satırlar için boşluk NOT VALID CHECK ile yasaklanır:
-- kısıt eski satırları doğrulamaz ama her yeni INSERT/UPDATE'e uygulanır,
-- böylece şema her ortamda aynı olur.
-- -----------------------------------------------------
ALTER TABLE payments ADD COLUMN IF NOT EXISTS property_id UUID REFERENCES properties(id);

UPDATE payments p
SET property_id = src.property_id
FROM (
    SELECT DISTINCT ON (pa.payment_id) pa.payment_id, ma.property_id
    FROM payment_assessments pa
    JOIN monthly_assessments ma ON ma.id = pa.assessment_id
    ORDER BY pa.payment_id, ma.property_id
) src
WHERE p.id = src.payment_id AND p.property_id IS NULL;

ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_property_required;
ALTER TABLE payments ADD CONSTRAINT payments_property_required
    CHECK (property_id IS NOT NULL) NOT VALID;

CREATE INDEX IF NOT EXISTS idx_payments_property ON payments(property_id);

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payments_property_scope ON payments;
CREATE POLICY payments_property_scope ON payments
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- payment_assessments: üst satır (ödeme) üzerinden. Ödeme aynı transaction'da
-- önce yazıldığı için WITH CHECK onu görür. Birincil anahtarın ilk kolonu
-- payment_id olduğu için ayrı indeks gerekmez.
ALTER TABLE payment_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_assessments FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payment_assessments_property_scope ON payment_assessments;
CREATE POLICY payment_assessments_property_scope ON payment_assessments
    USING (EXISTS (SELECT 1 FROM payments p
                   WHERE p.id = payment_assessments.payment_id
                     AND p.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM payments p
                        WHERE p.id = payment_assessments.payment_id
                          AND p.property_id = current_property_id()));

-- late_fee_accruals, assessment_details: tahakkuk üzerinden.
-- late_fee_accruals'ın UNIQUE (assessment_id, accrued_on) indeksi politikayı karşılar.
ALTER TABLE late_fee_accruals ENABLE ROW LEVEL SECURITY;
ALTER TABLE late_fee_accruals FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS late_fee_accruals_property_scope ON late_fee_accruals;
CREATE POLICY late_fee_accruals_property_scope ON late_fee_accruals
    USING (EXISTS (SELECT 1 FROM monthly_assessments ma
                   WHERE ma.id = late_fee_accruals.assessment_id
                     AND ma.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM monthly_assessments ma
                        WHERE ma.id = late_fee_accruals.assessment_id
                          AND ma.property_id = current_property_id()));

CREATE INDEX IF NOT EXISTS idx_assessment_details_assessment ON assessment_details(assessment_id);
ALTER TABLE assessment_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE assessment_details FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assessment_details_property_scope ON assessment_details;
CREATE POLICY assessment_details_property_scope ON assessment_details
    USING (EXISTS (SELECT 1 FROM monthly_assessments ma
                   WHERE ma.id = assessment_details.assessment_id
                     AND ma.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM monthly_assessments ma
                        WHERE ma.id = assessment_details.assessment_id
                          AND ma.property_id = current_property_id()));

-- consumption_invoices: bağımsız bölüm üzerinden. `units` RLS'siz; politika
-- onun property_id'sini kendi içinde karşılaştırır.
CREATE INDEX IF NOT EXISTS idx_consumption_invoices_unit ON consumption_invoices(unit_id);
ALTER TABLE consumption_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumption_invoices FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS consumption_invoices_property_scope ON consumption_invoices;
CREATE POLICY consumption_invoices_property_scope ON consumption_invoices
    USING (EXISTS (SELECT 1 FROM units u
                   WHERE u.id = consumption_invoices.unit_id
                     AND u.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM units u
                        WHERE u.id = consumption_invoices.unit_id
                          AND u.property_id = current_property_id()));

-- -----------------------------------------------------
-- expense-service
-- -----------------------------------------------------
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS expenses_property_scope ON expenses;
CREATE POLICY expenses_property_scope ON expenses
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE expense_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_distributions FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS expense_distributions_property_scope ON expense_distributions;
CREATE POLICY expense_distributions_property_scope ON expense_distributions
    USING (EXISTS (SELECT 1 FROM expenses e
                   WHERE e.id = expense_distributions.expense_id
                     AND e.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM expenses e
                        WHERE e.id = expense_distributions.expense_id
                          AND e.property_id = current_property_id()));

-- -----------------------------------------------------
-- community-service
-- -----------------------------------------------------
ALTER TABLE requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE requests FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS requests_property_scope ON requests;
CREATE POLICY requests_property_scope ON requests
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS announcements_property_scope ON announcements;
CREATE POLICY announcements_property_scope ON announcements
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- Birincil anahtarın ilk kolonu announcement_id; ayrı indeks gerekmez.
ALTER TABLE announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_reads FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS announcement_reads_property_scope ON announcement_reads;
CREATE POLICY announcement_reads_property_scope ON announcement_reads
    USING (EXISTS (SELECT 1 FROM announcements a
                   WHERE a.id = announcement_reads.announcement_id
                     AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM announcements a
                        WHERE a.id = announcement_reads.announcement_id
                          AND a.property_id = current_property_id()));
