-- =====================================================
-- 074 — IoT SENSÖRLERİ (FAZ H.4, kullanıcı kararı K1 — 2026-10-26)
--
-- İlk sürüm (2026-02-01) sensörleri MongoDB varsayımıyla mock olarak yazmıştı; MongoDB hiç kurulmadığı için
-- 2026-09-14'te dürüstçe 501'e çevrilmişti. Özellik PostgreSQL ile tamamlanır:
--   sensors          — tanım, eşikler, cihaz anahtarının ÖZETİ (anahtar bir kez gösterilir, 057 geçiş cihazı modeli)
--   sensor_readings  — zaman serisi; saklama kuralıyla budanır
--   sensor_alerts    — eşik aşımı / tetik / sinyal kesilmesi; açık alarm sensör ve tür başına tektir
-- Cihaz veri gönderirken kimliği yoktur; site kapsamı anahtar özetinden SECURITY DEFINER işlevle çözülür.
-- =====================================================

CREATE TABLE IF NOT EXISTS sensors (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id           UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name                  VARCHAR(120) NOT NULL CHECK (length(trim(name)) > 0),
    sensor_type           VARCHAR(30) NOT NULL CHECK (sensor_type IN ('WATER_LEAK','TEMPERATURE','HUMIDITY','SMOKE','GAS',
                              'POWER_OUTAGE','TANK_LEVEL','ELEVATOR_FAULT','DOOR_OPEN','OTHER')),
    location              VARCHAR(200),
    unit_label            VARCHAR(20),
    -- Sayısal sensörde eşik dışı değer alarm açar; ikili sensörde (kaçak, duman, gaz, kesinti, arıza, kapı)
    -- 1 = tetiklendi, 0 = normal.
    min_threshold         NUMERIC(12,3),
    max_threshold         NUMERIC(12,3),
    key_hash              CHAR(64) NOT NULL UNIQUE,
    offline_after_minutes INT NOT NULL DEFAULT 30 CHECK (offline_after_minutes BETWEEN 2 AND 1440),
    last_value            NUMERIC(12,3),
    last_seen_at          TIMESTAMPTZ,
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_by            UUID REFERENCES users(id),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (min_threshold IS NULL OR max_threshold IS NULL OR min_threshold < max_threshold)
);
CREATE INDEX IF NOT EXISTS idx_sensors_property ON sensors(property_id) WHERE is_active;

CREATE TABLE IF NOT EXISTS sensor_readings (
    id           BIGSERIAL PRIMARY KEY,
    sensor_id    UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    value        NUMERIC(12,3) NOT NULL,
    recorded_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    received_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_sensor_time ON sensor_readings(sensor_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_sensor_readings_property_time ON sensor_readings(property_id, recorded_at);

CREATE TABLE IF NOT EXISTS sensor_alerts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    sensor_id        UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    kind             VARCHAR(12) NOT NULL CHECK (kind IN ('HIGH','LOW','TRIGGERED','OFFLINE')),
    value            NUMERIC(12,3),
    threshold        NUMERIC(12,3),
    status           VARCHAR(12) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','ACKNOWLEDGED','CLOSED')),
    opened_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    normalized_at    TIMESTAMPTZ,
    acknowledged_at  TIMESTAMPTZ,
    acknowledged_by  UUID REFERENCES users(id),
    closed_at        TIMESTAMPTZ,
    closed_by        UUID REFERENCES users(id),
    close_note       TEXT,
    CHECK (status <> 'CLOSED' OR closed_at IS NOT NULL)
);
-- Aynı sensörde aynı türden tek açık (ya da onaylanmış ama kapanmamış) alarm: her okumada yeni alarm açılmaz.
CREATE UNIQUE INDEX IF NOT EXISTS uq_sensor_alerts_open ON sensor_alerts(sensor_id, kind) WHERE status <> 'CLOSED';
CREATE INDEX IF NOT EXISTS idx_sensor_alerts_property ON sensor_alerts(property_id, opened_at DESC);

ALTER TABLE sensors ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensors FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sensors_property_scope ON sensors;
CREATE POLICY sensors_property_scope ON sensors
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE sensor_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_readings FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sensor_readings_property_scope ON sensor_readings;
CREATE POLICY sensor_readings_property_scope ON sensor_readings
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE sensor_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_alerts FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sensor_alerts_property_scope ON sensor_alerts;
CREATE POLICY sensor_alerts_property_scope ON sensor_alerts
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE DELETE, TRUNCATE ON sensors, sensor_alerts FROM siteeksen_app;
REVOKE UPDATE, TRUNCATE ON sensor_readings FROM siteeksen_app;

-- Cihazdan gelen okuma: anahtar özetinden sensörü bulur, okumayı yazar ve son değeri günceller.
-- Kapsam (site) bu işlevde çözülür; dönen site kimliğiyle servis alarm değerlendirmesini kapsamlı yapar.
CREATE OR REPLACE FUNCTION sensor_ingest(p_key_hash text, p_value numeric, p_recorded_at timestamptz)
RETURNS TABLE (sensor_id uuid, property_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    s_id uuid;
    p_id uuid;
    at   timestamptz := COALESCE(p_recorded_at, now());
BEGIN
    -- Cihaz saati sapabilir: gelecekteki ya da 1 günden eski zaman damgası sunucu zamanıyla değiştirilir.
    IF at > now() + interval '5 minutes' OR at < now() - interval '1 day' THEN
        at := now();
    END IF;
    UPDATE sensors s SET last_value = p_value, last_seen_at = now(), updated_at = now()
     WHERE s.key_hash = p_key_hash AND s.is_active
     RETURNING s.id, s.property_id INTO s_id, p_id;
    IF s_id IS NULL THEN
        RETURN;
    END IF;
    INSERT INTO sensor_readings (sensor_id, property_id, value, recorded_at) VALUES (s_id, p_id, p_value, at);
    RETURN QUERY SELECT s_id, p_id;
END;
$$;
REVOKE ALL ON FUNCTION sensor_ingest(text, numeric, timestamptz) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION sensor_ingest(text, numeric, timestamptz) TO siteeksen_app;

-- Sinyali kesilmiş (ve henüz OFFLINE alarmı olmayan) sensörü olan siteler — bekçi bunları tarar.
CREATE OR REPLACE FUNCTION sensor_watch_property_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT DISTINCT s.property_id FROM sensors s JOIN properties p ON p.id = s.property_id
     WHERE s.is_active AND COALESCE(p.is_active, true)
       AND COALESCE(s.last_seen_at, s.created_at) < now() - make_interval(mins => s.offline_after_minutes)
       AND NOT EXISTS (SELECT 1 FROM sensor_alerts a WHERE a.sensor_id = s.id AND a.kind = 'OFFLINE' AND a.status <> 'CLOSED')
$$;
REVOKE ALL ON FUNCTION sensor_watch_property_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION sensor_watch_property_ids() TO siteeksen_app;

COMMENT ON TABLE sensors IS 'IoT sensörleri; cihaz anahtarının yalnız özeti saklanır (074)';
COMMENT ON TABLE sensor_readings IS 'Sensör okumaları (zaman serisi); saklama kuralıyla budanır (074)';
COMMENT ON TABLE sensor_alerts IS 'Sensör alarmları; silinemez, kapatılır (074)';
