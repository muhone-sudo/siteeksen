-- =====================================================
-- 060 — KARTLA ÖDEME: iyzico ÖDEME FORMU, 3D SECURE DÖNÜŞÜ, DURUM MAKİNESİ
--       (TEST_RAPORU 2.5, Apsiyon BUG-09)
--
-- Apsiyon şikâyeti: kart bilgisi girilmiş, çekim yapılmamış, ekran beyaz kalmış; ödeme
-- havada kalırken aidata bir gecede faiz yansımış. Burada kart ödemesi bir durum
-- makinesidir:
--   INITIATED (ödeme sayfası açıldı) → PROCESSING (banka dönüşü alındı, sonuç sorgulanıyor)
--   → SUCCEEDED (borç düştü) | FAILED (bankanın Türkçe ret nedeniyle) | EXPIRED (zaman aşımı)
-- Ödeme sonuçlanana kadar PENDING kalır: gecikme tazminatı deneme gününde durur (053 valör
-- mekanizması). Sistem kaynaklı başarısızlıkta (zaman aşımı, sağlayıcı hatası) iki gün içindeki
-- yeni deneme ilk denemenin gününü valör olarak devralır — kullanıcı sistem hatasının faizini ödemez.
-- Sonuç ASLA geri dönüş isteğinin gövdesine güvenilerek yazılmaz; sağlayıcıdan yeniden sorgulanır,
-- tutar ve sepet kimliği doğrulanır.
-- =====================================================

ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway VARCHAR(20);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_status VARCHAR(20);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_token VARCHAR(200);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_payment_id VARCHAR(64);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_error_code VARCHAR(40);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_error_message TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS failure_kind VARCHAR(10);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_updated_at TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_gateway_rules') THEN
        ALTER TABLE payments ADD CONSTRAINT payments_gateway_rules CHECK (
            (gateway_status IS NULL OR gateway_status IN ('INITIATED','PROCESSING','SUCCEEDED','FAILED','EXPIRED'))
            AND (failure_kind IS NULL OR failure_kind IN ('CARD','SYSTEM'))
            AND (gateway_status IS NULL OR gateway IS NOT NULL)
        );
    END IF;
END $$;
CREATE UNIQUE INDEX IF NOT EXISTS uq_payments_gateway_token ON payments(gateway_token) WHERE gateway_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_gateway_open ON payments(created_at) WHERE status = 'PENDING' AND gateway IS NOT NULL;

-- Sağlayıcının geri dönüşü kimliksizdir: jetondan ödeme ve site bulunur (yalnızca kimlik döner).
CREATE OR REPLACE FUNCTION card_payment_by_token(p_token text)
RETURNS TABLE (payment_id uuid, property_id uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT p.id, p.property_id FROM payments p WHERE p.gateway_token = p_token AND p.gateway IS NOT NULL
$$;
REVOKE ALL ON FUNCTION card_payment_by_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION card_payment_by_token(text) TO siteeksen_app;

-- Uzlaştırma bekçisi için: sonucu gelmemiş eski kart ödemeleri (yalnızca kimlik döner).
CREATE OR REPLACE FUNCTION card_payments_stale(p_age_secs int)
RETURNS TABLE (payment_id uuid, property_id uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT p.id, p.property_id FROM payments p
     WHERE p.status = 'PENDING' AND p.gateway IS NOT NULL
       AND p.gateway_status IN ('INITIATED','PROCESSING')
       AND p.created_at < now() - make_interval(secs => p_age_secs)
     ORDER BY p.created_at
     LIMIT 200
$$;
REVOKE ALL ON FUNCTION card_payments_stale(int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION card_payments_stale(int) TO siteeksen_app;

COMMENT ON COLUMN payments.gateway_status IS 'Kart ödemesi durumu: INITIATED/PROCESSING/SUCCEEDED/FAILED/EXPIRED (Apsiyon BUG-09) — 060';
