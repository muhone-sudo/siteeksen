-- =====================================================
-- 047 — BORDRO KAYDI (FAZ 7.4, kullanıcı kararı S-22 = b)
--
-- Bordro mali müşavirden gelir. Sistem ücret, gelir vergisi, damga vergisi ve SGK
-- primi HESAPLAMAZ; oranlar her yıl değişir ve hata doğrudan çalışanın ücretine
-- yansır. Sistem yalnızca dönem bazında:
--   * çalışana ödenen NET tutarı,
--   * sitenin toplam İŞVEREN MALİYETİNİ (brüt + işveren SGK + işsizlik payı),
--   * isteğe bağlı olarak bordrodaki ara kalemleri (bilgi amaçlı, doğrulanmaz),
--   * bordronun kaynağını (mali müşavir / bordro no) ve ödeme bilgisini
-- kaydeder. 005'te tanımlı ama hiç kullanılmayan `payroll` tablosu bu amaçla açılır.
--
-- Kurallar:
--   * net > 0, işveren maliyeti >= net (maliyet nette eksik olamaz)
--   * dönem YYYY-AA; çalışan başına dönem tekildir (005'teki UNIQUE)
--   * ÖDENDİ durumunda ödeme tarihi zorunlu; ödenmiş kayıt değiştirilemez
--   * kayıt silinemez (uygulama rolünden DELETE alınır); hatalı kayıt İPTAL edilir
-- =====================================================

ALTER TABLE payroll ADD COLUMN IF NOT EXISTS employer_cost DECIMAL(12,2);
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS source_ref TEXT;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS recorded_by UUID REFERENCES users(id);
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS cancel_reason TEXT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payroll_record_rules') THEN
        ALTER TABLE payroll ADD CONSTRAINT payroll_record_rules CHECK (
            period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'
            AND net_salary IS NOT NULL AND net_salary > 0
            AND employer_cost IS NOT NULL AND employer_cost >= net_salary
            AND length(trim(COALESCE(source_ref, ''))) > 0
            AND (payment_status <> 'PAID' OR payment_date IS NOT NULL)
            AND (payment_status <> 'CANCELLED' OR length(trim(COALESCE(cancel_reason, ''))) > 0)
        );
    END IF;
END $$;

-- Ödenmiş ya da iptal edilmiş bordro kaydı değiştirilemez; bekleyen kayıt yalnızca
-- ödendi/iptal durumuna geçebilir ya da tutarları düzeltilebilir.
CREATE OR REPLACE FUNCTION payroll_guard() RETURNS trigger AS $$
BEGIN
    IF OLD.payment_status IN ('PAID', 'CANCELLED') THEN
        RAISE EXCEPTION 'Sonuçlanmış bordro kaydı değiştirilemez (durum: %)', OLD.payment_status
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.employee_id <> OLD.employee_id OR NEW.period <> OLD.period OR NEW.property_id <> OLD.property_id THEN
        RAISE EXCEPTION 'Bordro kaydının çalışanı, dönemi ve sitesi değiştirilemez'
            USING ERRCODE = 'check_violation';
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payroll_guard ON payroll;
CREATE TRIGGER payroll_guard BEFORE UPDATE ON payroll FOR EACH ROW EXECUTE FUNCTION payroll_guard();

REVOKE DELETE, TRUNCATE ON payroll FROM siteeksen_app;

CREATE INDEX IF NOT EXISTS idx_payroll_property_period ON payroll(property_id, period);

COMMENT ON TABLE payroll IS 'Bordro KAYDI: mali müşavirden gelen net ödeme ve işveren maliyeti; hesap yapılmaz (S-22) — 047';
COMMENT ON COLUMN payroll.employer_cost IS 'Sitenin toplam işveren maliyeti (brüt + işveren SGK + işsizlik) — bordrodan girilir';
COMMENT ON COLUMN payroll.source_ref IS 'Bordronun kaynağı: mali müşavir, bordro/tahakkuk no';
