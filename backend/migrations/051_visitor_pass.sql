-- =====================================================
-- 051 — ZİYARETÇİ GEÇİŞ KODU (TEST_RAPORU 2.8)
--
-- Ön kaydı yapılan ziyaretçi için tek kullanımlık 6 haneli PIN ve QR jetonu üretilir;
-- sakin bunu ziyaretçiye kendisi iletir (sistem site dışı numaraya ileti göndermez).
-- Güvenlik görevlisi PIN'i girer ya da QR'ı okutur → giriş kaydedilir ve daireye
-- uygulama içi teyit bildirimi düşer.
--
-- Kodun KENDİSİ saklanmaz, yalnızca SHA-256 özeti (veritabanı sızıntısında geçerli
-- kod ele geçmez). PIN site içinde, beklenen (EXPECTED) ziyaretçiler arasında
-- tekildir; QR özeti zaten genel tekildir (005: qr_code UNIQUE).
-- =====================================================

ALTER TABLE visitors ADD COLUMN IF NOT EXISTS pin_hash VARCHAR(64);

CREATE UNIQUE INDEX IF NOT EXISTS uq_visitors_active_pin
    ON visitors(property_id, pin_hash) WHERE status = 'EXPECTED' AND pin_hash IS NOT NULL;

COMMENT ON COLUMN visitors.pin_hash IS 'Geçiş PIN''inin SHA-256 özeti (site kimliğiyle); kodun kendisi saklanmaz — 051';
COMMENT ON COLUMN visitors.qr_code IS 'QR geçiş jetonunun SHA-256 özeti — 051';
