-- =====================================================
-- 054 — FİNANSAL KAYITLARIN DEĞİŞTİRİLEMEZLİĞİ VE TAHSİLAT DEFTERİ ZİNCİRİ (Apsiyon BUG-03)
--
-- Apsiyon şikâyeti: yönetici isteğiyle ödenmiş tutarlar geçmişe dönük silinmiş, sakin
-- ödediği parayla icralık olmuş. Bu sistemde ödeme/tahakkuk silen bir uç yoktu, ama
-- uygulama rolü (siteeksen_app) 020'den beri bu tablolarda DELETE yetkisine sahipti —
-- koruma yalnızca kodun iyi niyetine dayanıyordu.
--
--   * Ödeme, tahakkuk, ödeme-tahakkuk bağı, tahakkuk dökümü, tazminat izi ve gider
--     tabloları uygulama rolünce SİLİNEMEZ.
--   * Sonuçlanmış ödeme değiştirilemez; tek geçiş COMPLETED → REVERSED (ters kayıt,
--     gerekçe zorunlu). Ödenmiş tahakkukun anaparası değiştirilemez, silindi işaretlenemez;
--     ödenen tutar yalnızca ters kayıt işleminde azalabilir.
--   * finance_ledger: her tahsilat onayı ve ters kayıt, bir öncekinin SHA-256 özetine bağlı
--     zincire yazılır; kayıt değiştirilemez/silinemez. Kat maliki ve denetçi zinciri doğrular.
-- =====================================================

REVOKE DELETE, TRUNCATE ON payments, payment_assessments, monthly_assessments, assessment_details,
    late_fee_accruals, expenses FROM siteeksen_app;

ALTER TABLE payments ADD COLUMN IF NOT EXISTS reversed_at TIMESTAMPTZ;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reversed_by UUID REFERENCES users(id);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS reversal_reason TEXT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_status_check') THEN
        ALTER TABLE payments ADD CONSTRAINT payments_status_check
            CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED', 'REVERSED')) NOT VALID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_reversal_reason') THEN
        ALTER TABLE payments ADD CONSTRAINT payments_reversal_reason
            CHECK (status <> 'REVERSED' OR length(trim(COALESCE(reversal_reason, ''))) > 0) NOT VALID;
    END IF;
END $$;

-- Ödeme: tutar, kişi ve tahakkuk bağı değişmez; sonuçlanmış ödeme yalnızca ters kayda geçer.
-- Koruma UYGULAMA ROLÜNE uygulanır; şema sahibi (bakım, geri yükleme) bunu zaten devre dışı
-- bırakabilir — o yolla yapılan değişiklik tahsilat defteri zincirinde yakalanır.
CREATE OR REPLACE FUNCTION payments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF NEW.deleted IS DISTINCT FROM OLD.deleted AND OLD.status IN ('COMPLETED', 'REVERSED') THEN
        RAISE EXCEPTION 'Sonuçlanmış ödeme silinemez' USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.amount <> OLD.amount OR NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.property_id IS DISTINCT FROM OLD.property_id OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'Ödeme kaydının tutarı, sahibi ve tarihi değiştirilemez; düzeltme ters kayıtla yapılır'
            USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.value_date IS NOT NULL AND NEW.value_date IS DISTINCT FROM OLD.value_date THEN
        RAISE EXCEPTION 'Beyan edilen ödeme (valör) tarihi değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.status <> 'PENDING' AND NEW.status <> OLD.status
       AND NOT (OLD.status = 'COMPLETED' AND NEW.status = 'REVERSED') THEN
        RAISE EXCEPTION 'Sonuçlanmış ödemenin durumu değiştirilemez (% → %); yalnızca ters kayıt yapılabilir',
            OLD.status, NEW.status USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.status = 'REVERSED' AND ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
        RAISE EXCEPTION 'Ters kaydı yapılmış ödeme değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS payments_guard ON payments;
CREATE TRIGGER payments_guard BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION payments_guard();

-- Ödeme-tahakkuk bağı değişmez (hangi borcun hangi parayla kapandığı ispat konusudur).
CREATE OR REPLACE FUNCTION payment_assessments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    RAISE EXCEPTION 'Ödeme-tahakkuk bağı değiştirilemez' USING ERRCODE = 'check_violation';
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS payment_assessments_guard ON payment_assessments;
CREATE TRIGGER payment_assessments_guard BEFORE UPDATE ON payment_assessments FOR EACH ROW EXECUTE FUNCTION payment_assessments_guard();

-- Tahakkuk: ödeme almış borcun anaparası değişmez, silindi işaretlenemez; ödenen tutar
-- yalnızca ters kayıt işleminde (siteeksen.reversal oturum ayarı) azalabilir.
CREATE OR REPLACE FUNCTION monthly_assessments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF COALESCE(OLD.paid_amount, 0) > 0 THEN
        IF NEW.base_amount <> OLD.base_amount THEN
            RAISE EXCEPTION 'Ödeme almış tahakkukun anaparası değiştirilemez; düzeltme alacak dekontuyla yapılır'
                USING ERRCODE = 'check_violation';
        END IF;
        IF NEW.deleted <> OLD.deleted THEN
            RAISE EXCEPTION 'Ödeme almış tahakkuk silinemez' USING ERRCODE = 'check_violation';
        END IF;
    END IF;
    IF COALESCE(NEW.paid_amount, 0) < COALESCE(OLD.paid_amount, 0)
       AND COALESCE(current_setting('siteeksen.reversal', true), '') <> 'on' THEN
        RAISE EXCEPTION 'Ödenen tutar azaltılamaz; yalnızca ödemenin ters kaydı yapılabilir'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS monthly_assessments_guard ON monthly_assessments;
CREATE TRIGGER monthly_assessments_guard BEFORE UPDATE ON monthly_assessments FOR EACH ROW EXECUTE FUNCTION monthly_assessments_guard();

CREATE TABLE IF NOT EXISTS finance_ledger (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    seq          BIGINT NOT NULL,
    entry_type   VARCHAR(30) NOT NULL CHECK (entry_type IN ('PAYMENT_CONFIRMED', 'PAYMENT_REVERSED', 'CREDIT_NOTE')),
    payment_id   UUID REFERENCES payments(id),
    amount_kurus BIGINT NOT NULL,
    detail       JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by   UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    prev_hash    CHAR(64),
    entry_hash   CHAR(64) NOT NULL,
    UNIQUE (property_id, seq)
);
CREATE INDEX IF NOT EXISTS idx_finance_ledger_payment ON finance_ledger(payment_id);

ALTER TABLE finance_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE finance_ledger FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS finance_ledger_property_scope ON finance_ledger;
CREATE POLICY finance_ledger_property_scope ON finance_ledger
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, DELETE, TRUNCATE ON finance_ledger FROM siteeksen_app;

-- Zincir özeti veritabanında hesaplanır: ekleme ve doğrulama AYNI fonksiyonu kullanır
-- (jsonb'nin kanonik metni dahil), böylece istemci ile sunucu arasında biçim farkı oluşmaz.
CREATE OR REPLACE FUNCTION finance_ledger_hash(p_prev text, p_property uuid, p_seq bigint, p_type text,
    p_payment uuid, p_amount bigint, p_detail jsonb, p_created timestamptz) RETURNS text
LANGUAGE sql STABLE AS $$
    SELECT encode(sha256(convert_to(concat_ws('|', COALESCE(p_prev, ''), p_property::text, p_seq::text, p_type,
        COALESCE(p_payment::text, ''), p_amount::text, p_detail::text,
        to_char(p_created AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US')), 'UTF8')), 'hex')
$$;

COMMENT ON TABLE finance_ledger IS 'Tahsilat defteri: onay/ters kayıt SHA-256 zinciri; değiştirilemez (Apsiyon BUG-03) — 054';
