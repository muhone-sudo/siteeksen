-- =====================================================
-- 052 — KARGO TESLİM KANITI: İMZA VE FOTOĞRAF (TEST_RAPORU 2.3)
--
-- Teslimde dokunmatik imza ve paket fotoğrafı dosya deposuna (pkg/storage; belge
-- arşiviyle aynı depo, anahtar öneki packages/) yazılır. Kolonlarda depo anahtarı ve
-- SHA-256 özeti tutulur: dosya sonradan değiştirilirse özet tutmaz (ispat değeri).
--
-- KVKK periyodik imhası (043, PACKAGE) kayıt alanlarını anonimleştirirken dosya
-- anahtarlarını storage_deletion_queue'ya bırakır; depoya erişimi olan kargo servisi
-- kuyruğu işleyip dosyaları siler (önceden bağlantı silinir, dosya depoda kalırdı).
-- =====================================================

ALTER TABLE packages ADD COLUMN IF NOT EXISTS delivery_signature_sha256 VARCHAR(64);
ALTER TABLE packages ADD COLUMN IF NOT EXISTS delivery_photo_sha256 VARCHAR(64);

CREATE TABLE IF NOT EXISTS storage_deletion_queue (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    storage_key  TEXT NOT NULL CHECK (length(storage_key) > 0),
    reason       VARCHAR(40) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_storage_deletion_queue_property ON storage_deletion_queue(property_id, created_at);

ALTER TABLE storage_deletion_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage_deletion_queue FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS storage_deletion_queue_property_scope ON storage_deletion_queue;
CREATE POLICY storage_deletion_queue_property_scope ON storage_deletion_queue
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

-- Kuyruğu işleyen servis uygulama rolüyle bağlanır; RLS nedeniyle hangi sitelerde iş
-- olduğunu göremez. Yalnızca KİMLİK dönen fonksiyon (028'deki desen); site verisine
-- erişim yine site kapsamıyla (RLS) yapılır. Pasif sitelerin dosyaları da silinmelidir.
CREATE OR REPLACE FUNCTION storage_deletion_property_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT DISTINCT property_id FROM storage_deletion_queue ORDER BY property_id
$$;
REVOKE ALL ON FUNCTION storage_deletion_property_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION storage_deletion_property_ids() TO siteeksen_app;

COMMENT ON TABLE storage_deletion_queue IS 'Silinecek depo dosyaları (KVKK imhası sonrası); kargo servisi işler — 052';
