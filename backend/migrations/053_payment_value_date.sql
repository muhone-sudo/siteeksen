-- =====================================================
-- 053 — HAVALE/EFT VALÖRÜ VE GECİKME TAZMİNATININ DONDURULMASI (Apsiyon BUG-02)
--
-- KMK m.20/2: gecikme tazminatı "ödemede geciktiği günler" için işler — gecikme,
-- sakinin parayı gönderdiği gün (valör) biter, yöneticinin onayladığı gün değil.
-- Önceden sakin havaleyi zamanında yapsa bile yönetici onaylayana kadar tazminat
-- işlemeye devam ediyordu.
--
--   * payments.value_date: sakinin beyan ettiği ödeme (valör) tarihi
--   * payments.payer_reference: havale açıklaması / dekont numarası (beyan)
--   * Onay bekleyen ödemenin kapsadığı borçta tazminat valör tarihinde DONAR;
--     valörden sonraki tahakkuk izleri silinmez, "iptal" işaretlenir (gerekçeli)
-- =====================================================

ALTER TABLE payments ADD COLUMN IF NOT EXISTS value_date DATE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payer_reference VARCHAR(140);

ALTER TABLE late_fee_accruals ADD COLUMN IF NOT EXISTS reversed_at TIMESTAMPTZ;
ALTER TABLE late_fee_accruals ADD COLUMN IF NOT EXISTS reversal_reason TEXT;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'late_fee_accruals_reversal_reason') THEN
        ALTER TABLE late_fee_accruals ADD CONSTRAINT late_fee_accruals_reversal_reason
            CHECK (reversed_at IS NULL OR length(trim(COALESCE(reversal_reason, ''))) > 0);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_payment_assessments_assessment ON payment_assessments(assessment_id);

COMMENT ON COLUMN payments.value_date IS 'Sakinin beyan ettiği ödeme (valör) tarihi; gecikme tazminatı bu günde durur (KMK m.20/2) — 053';
COMMENT ON COLUMN late_fee_accruals.reversed_at IS 'Valör sonrası işletilmiş tazminat izinin iptal zamanı (kayıt silinmez) — 053';
