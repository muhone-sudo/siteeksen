-- =====================================================
-- 046 — KAMERA VE BİYOMETRİK SİSTEM ENVANTERİ (FAZ 7.8 kalanı)
--
-- KVK Kurumu'nun apartmanlarda güvenlik kamerası kamuoyu duyurusu (08/06/2026):
--   * kamera kararı KMK'ya uygun alınır; sakinlerin makul mahremiyet beklentisi gözetilir
--   * bağımsız bölüm içini/merdiven boşluğunu gören konum, tuvalet/soyunma/ibadet yeri YASAK
--   * dar açı, gereksiz alan maskelenir; asansör için somut gerekçe gerekir
--   * yüz tanıma ve ses kaydı gibi yoğun müdahale içeren özelliklerden kaçınılır
--   * kayıtlar yalnızca gerektiği süre saklanır; erişim yetkiliyle sınırlıdır
--   * sakinler açık ve görünür biçimde aydınlatılır (levha) — KVKK m.10
-- Biyometrik veri özel nitelikli kişisel veridir (KVKK m.6/1); işlenmesi açık rızaya
-- dayanır (m.6/3-a). Rızanın özgür olması için rıza vermeyene ALTERNATİF geçiş
-- yöntemi sunulmalıdır — alternatifsiz sistem kaydedilmez.
-- =====================================================

CREATE TABLE IF NOT EXISTS camera_devices (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id              UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    location                 VARCHAR(200) NOT NULL,
    area_type                VARCHAR(20) NOT NULL
                             CHECK (area_type IN ('ENTRANCE', 'PERIMETER', 'PARKING', 'GARDEN', 'LOBBY', 'CORRIDOR', 'ELEVATOR', 'OTHER')),
    purpose                  TEXT NOT NULL CHECK (length(trim(purpose)) > 0),
    retention_days           INT NOT NULL CHECK (retention_days BETWEEN 1 AND 365),
    notice_posted            BOOLEAN NOT NULL DEFAULT false,   -- aydınlatma levhası asılı mı
    masked                   BOOLEAN NOT NULL DEFAULT false,   -- gereksiz alan maskelendi mi
    audio_recording          BOOLEAN NOT NULL DEFAULT false,
    face_recognition         BOOLEAN NOT NULL DEFAULT false,
    intensive_justification  TEXT,                             -- ses/yüz tanıma/asansör için zorunlu gerekçe
    decision_ref             TEXT,                             -- kat malikleri kurulu kararı
    access_note              TEXT,                             -- kayıtlara kimler erişir
    is_active                BOOLEAN NOT NULL DEFAULT true,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT camera_devices_intensive_reason CHECK (
        NOT (audio_recording OR face_recognition OR area_type = 'ELEVATOR')
        OR length(trim(COALESCE(intensive_justification, ''))) > 0)
);
CREATE INDEX IF NOT EXISTS idx_camera_devices_property ON camera_devices(property_id, is_active);

CREATE TABLE IF NOT EXISTS biometric_systems (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id        UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name               VARCHAR(200) NOT NULL,
    method             VARCHAR(20) NOT NULL CHECK (method IN ('FINGERPRINT', 'FACE', 'PALM', 'IRIS', 'OTHER')),
    purpose            TEXT NOT NULL CHECK (length(trim(purpose)) > 0),
    alternative_method TEXT NOT NULL CHECK (length(trim(alternative_method)) > 0),
    consent_based      BOOLEAN NOT NULL CHECK (consent_based),
    retention_note     TEXT,
    is_active          BOOLEAN NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE camera_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE camera_devices FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS camera_devices_property_scope ON camera_devices;
CREATE POLICY camera_devices_property_scope ON camera_devices
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE biometric_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE biometric_systems FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS biometric_systems_property_scope ON biometric_systems;
CREATE POLICY biometric_systems_property_scope ON biometric_systems
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

REVOKE DELETE, TRUNCATE ON camera_devices FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON biometric_systems FROM siteeksen_app;

COMMENT ON TABLE camera_devices IS 'Kamera envanteri; KVK Kurumu apartman kamera duyurusu (08/06/2026) — 046';
COMMENT ON TABLE biometric_systems IS 'Biyometrik sistem envanteri; açık rıza + alternatif yöntem zorunlu (KVKK m.6) — 046';
