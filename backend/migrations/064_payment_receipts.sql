-- =====================================================
-- 064 — HAVALE BİLDİRİMİNE DEKONT DOSYASI (beşinci tur B9, Şikayetvar "dekont gönderdim, borç düşmedi")
--
-- Önceden havale bildiriminde yalnızca açıklama/dekont NUMARASI yazılabiliyordu; sakin dekontun
-- kendisini gösteremiyor, yönetici banka hareketini ararken dayanak göremiyordu. Artık sakin onay
-- bekleyen ödemesine PDF ya da görsel ekler (en çok 3), yönetici indirir. Dosya `pkg/storage`'da,
-- özeti (SHA-256) burada; kayıt silinemez ve değiştirilemez (kanıt niteliği).
-- Dekont YALNIZCA dayanaktır: borç, yönetici onayıyla ya da banka ekstresi eşleşmesiyle düşer.
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_receipts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    payment_id   UUID NOT NULL REFERENCES payments(id),
    storage_key  TEXT NOT NULL,
    file_name    VARCHAR(200) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    size_bytes   BIGINT NOT NULL CHECK (size_bytes > 0),
    sha256       CHAR(64) NOT NULL,
    uploaded_by  UUID NOT NULL REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payment_receipts_payment ON payment_receipts (payment_id);

ALTER TABLE payment_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_receipts FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payment_receipts_property_scope ON payment_receipts;
CREATE POLICY payment_receipts_property_scope ON payment_receipts
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, DELETE, TRUNCATE ON payment_receipts FROM siteeksen_app;

COMMENT ON TABLE payment_receipts IS 'Havale bildirimine eklenen dekont dosyası (özetli); silinemez, değiştirilemez — 064';
