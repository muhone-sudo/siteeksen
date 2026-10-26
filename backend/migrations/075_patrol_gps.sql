-- =====================================================
-- 075 — DEVRİYE: QR + GPS ZORUNLULUĞU, KONUM İZİ, OKUTMA DENEMELERİ (FAZ H.5, kullanıcı kararı K2 — 2026-10-26)
--
-- Sorun: QR'ın fotoğrafını çeken görevli noktaya gitmeden okutabilir. Çözüm: okutma anındaki konum sunucuda
-- noktanın konumuyla karşılaştırılır (yarıçap + ölçüm doğruluğu); sahte konum (Android isMocked) ve yetersiz
-- doğruluk reddedilir; her deneme — reddedilenler dahil — kanıt olarak saklanır. Tur süresince konum izi tutulur
-- (yalnız açık tur boyunca; KVKK m.4 ölçülülük).
-- Kapalı alanda (bodrum, kazan dairesi) GPS zayıfsa nokta gerekçeyle "konum muaf" yapılabilir; muaf okutma
-- raporda ayrıca gösterilir.
-- =====================================================

ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS radius_m INT NOT NULL DEFAULT 30;
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS location_accuracy_m NUMERIC(8,2);
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS location_set_at TIMESTAMPTZ;
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS location_set_by UUID REFERENCES users(id);
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS location_check VARCHAR(10) NOT NULL DEFAULT 'REQUIRED';
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS exempt_reason TEXT;
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS exempt_by UUID REFERENCES users(id);
ALTER TABLE patrol_checkpoints ADD COLUMN IF NOT EXISTS qr_token VARCHAR(64);
UPDATE patrol_checkpoints SET qr_token = replace(gen_random_uuid()::text, '-', '') WHERE qr_token IS NULL;
ALTER TABLE patrol_checkpoints ALTER COLUMN qr_token SET DEFAULT replace(gen_random_uuid()::text, '-', '');
ALTER TABLE patrol_checkpoints ALTER COLUMN qr_token SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_patrol_checkpoints_qr_token ON patrol_checkpoints(qr_token);
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'patrol_checkpoints_radius_check') THEN
        ALTER TABLE patrol_checkpoints ADD CONSTRAINT patrol_checkpoints_radius_check CHECK (radius_m BETWEEN 5 AND 500);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'patrol_checkpoints_location_check_check') THEN
        ALTER TABLE patrol_checkpoints ADD CONSTRAINT patrol_checkpoints_location_check_check
            CHECK (location_check IN ('REQUIRED', 'EXEMPT'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'patrol_checkpoints_exempt_reason_check') THEN
        ALTER TABLE patrol_checkpoints ADD CONSTRAINT patrol_checkpoints_exempt_reason_check
            CHECK (location_check <> 'EXEMPT' OR (exempt_reason IS NOT NULL AND length(trim(exempt_reason)) > 0));
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS patrol_track_points (
    id             BIGSERIAL PRIMARY KEY,
    patrol_log_id  UUID NOT NULL REFERENCES patrol_logs(id) ON DELETE CASCADE,
    property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    recorded_at    TIMESTAMPTZ NOT NULL,
    received_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    latitude       NUMERIC(10,7) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude      NUMERIC(10,7) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    accuracy_m     NUMERIC(8,2),
    speed_mps      NUMERIC(8,2),
    is_mocked      BOOLEAN NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_patrol_track_points_log ON patrol_track_points(patrol_log_id, recorded_at);
CREATE INDEX IF NOT EXISTS idx_patrol_track_points_property ON patrol_track_points(property_id, recorded_at);

CREATE TABLE IF NOT EXISTS patrol_scan_attempts (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patrol_log_id  UUID NOT NULL REFERENCES patrol_logs(id) ON DELETE CASCADE,
    property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    checkpoint_id  UUID REFERENCES patrol_checkpoints(id),
    guard_id       UUID NOT NULL REFERENCES users(id),
    method         VARCHAR(10) NOT NULL CHECK (method IN ('QR', 'MANUAL')),
    latitude       NUMERIC(10,7),
    longitude      NUMERIC(10,7),
    accuracy_m     NUMERIC(8,2),
    is_mocked      BOOLEAN NOT NULL DEFAULT false,
    distance_m     NUMERIC(10,2),
    accepted       BOOLEAN NOT NULL,
    reason         VARCHAR(40),
    location_exempt BOOLEAN NOT NULL DEFAULT false,
    suspicious     BOOLEAN NOT NULL DEFAULT false,
    note           TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (accepted OR reason IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_patrol_scan_attempts_log ON patrol_scan_attempts(patrol_log_id, created_at);
CREATE INDEX IF NOT EXISTS idx_patrol_scan_attempts_property ON patrol_scan_attempts(property_id, created_at);

ALTER TABLE patrol_track_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrol_track_points FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS patrol_track_points_property_scope ON patrol_track_points;
CREATE POLICY patrol_track_points_property_scope ON patrol_track_points
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE patrol_scan_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrol_scan_attempts FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS patrol_scan_attempts_property_scope ON patrol_scan_attempts;
CREATE POLICY patrol_scan_attempts_property_scope ON patrol_scan_attempts
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
-- Kanıt kayıtları değiştirilemez; konum izi yalnız saklama işiyle silinir.
REVOKE UPDATE, DELETE, TRUNCATE ON patrol_scan_attempts FROM siteeksen_app;
REVOKE UPDATE, TRUNCATE ON patrol_track_points FROM siteeksen_app;

COMMENT ON TABLE patrol_track_points IS 'Devriye konum izi; yalnız açık tur boyunca toplanır, 1 yıl saklanır (075)';
COMMENT ON TABLE patrol_scan_attempts IS 'Devriye okutma denemeleri (kabul ve red); kanıt kaydı, değiştirilemez (075)';
