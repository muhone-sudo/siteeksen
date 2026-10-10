-- =====================================================
-- 057 — GEÇİŞ CİHAZI CANLILIK İZLEME (Apsiyon BUG-08)
--
-- Plaka tanıma kamerası / bariyer ünitesi bozulduğunda bunu merkeze bildiren bir mekanizma
-- yoktu; arıza ancak kapıda araç kuyruğu oluşunca fark ediliyordu. Artık her cihaz kayıtlıdır
-- ve kendi anahtarıyla düzenli canlılık sinyali (heartbeat) gönderir. Süre aşılırsa olay
-- (incident) açılır ve yönetime bildirim gider; sinyal geri gelince olay kapanır.
--
-- Cihaz anahtarı yalnızca SHA-256 özetiyle saklanır (bir kez gösterilir). Cihaz kimliksiz
-- uçtan çağırır; site eşlemesi SECURITY DEFINER işlevle yapılır — uygulama rolü RLS'i
-- aşmadan yalnızca kendi anahtarının cihazını günceller.
-- =====================================================

CREATE TABLE IF NOT EXISTS access_devices (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id            UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    name                   VARCHAR(120) NOT NULL CHECK (length(trim(name)) > 0),
    kind                   VARCHAR(20) NOT NULL CHECK (kind IN ('PTS_CAMERA','BARRIER','TURNSTILE','INTERCOM','OTHER')),
    location               VARCHAR(200),
    key_hash               CHAR(64) NOT NULL UNIQUE,
    heartbeat_interval_sec INT NOT NULL DEFAULT 60 CHECK (heartbeat_interval_sec BETWEEN 10 AND 3600),
    offline_after_sec      INT NOT NULL DEFAULT 180,
    last_seen_at           TIMESTAMPTZ,
    last_status            VARCHAR(200),
    is_active              BOOLEAN NOT NULL DEFAULT true,
    created_by             UUID REFERENCES users(id),
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Tek bir gecikmiş sinyal alarm üretmesin: eşik en az iki sinyal aralığı.
    CHECK (offline_after_sec >= 2 * heartbeat_interval_sec AND offline_after_sec <= 86400)
);
CREATE INDEX IF NOT EXISTS idx_access_devices_property ON access_devices(property_id) WHERE is_active;

CREATE TABLE IF NOT EXISTS device_incidents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    device_id     UUID NOT NULL REFERENCES access_devices(id) ON DELETE CASCADE,
    last_seen_at  TIMESTAMPTZ,
    detected_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    recovered_at  TIMESTAMPTZ,
    CHECK (recovered_at IS NULL OR recovered_at >= detected_at)
);
-- Cihaz başına en fazla bir açık olay: bekçi her turda yeni alarm üretmez.
CREATE UNIQUE INDEX IF NOT EXISTS uq_device_incidents_open ON device_incidents(device_id) WHERE recovered_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_device_incidents_property ON device_incidents(property_id, detected_at DESC);

ALTER TABLE access_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE access_devices FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS access_devices_property_scope ON access_devices;
CREATE POLICY access_devices_property_scope ON access_devices
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE device_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_incidents FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS device_incidents_property_scope ON device_incidents;
CREATE POLICY device_incidents_property_scope ON device_incidents
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
-- Cihaz silinmez (pasife alınır); olay geçmişi silinemez.
REVOKE DELETE, TRUNCATE ON access_devices, device_incidents FROM siteeksen_app;

-- Cihazın canlılık sinyali: anahtar özetiyle eşleşen AKTİF cihazı günceller, açık olayı kapatır.
-- Yalnızca kimlik döner; başka site verisine erişim vermez.
CREATE OR REPLACE FUNCTION device_heartbeat(p_key_hash text, p_status text)
RETURNS TABLE (device_id uuid, property_id uuid, recovered_incident uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    d_id uuid;
    p_id uuid;
    inc uuid;
BEGIN
    UPDATE access_devices d SET last_seen_at = now(), last_status = left(NULLIF(trim(p_status), ''), 200)
     WHERE d.key_hash = p_key_hash AND d.is_active
     RETURNING d.id, d.property_id INTO d_id, p_id;
    IF d_id IS NULL THEN
        RETURN;
    END IF;
    UPDATE device_incidents i SET recovered_at = now()
     WHERE i.device_id = d_id AND i.recovered_at IS NULL
     RETURNING i.id INTO inc;
    RETURN QUERY SELECT d_id, p_id, inc;
END;
$$;
REVOKE ALL ON FUNCTION device_heartbeat(text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION device_heartbeat(text, text) TO siteeksen_app;

-- Bekçi için: sinyal süresi aşılmış ve açık olayı olmayan aktif cihazların site kimlikleri.
-- Pasif sitelerin cihazları izlenmez.
CREATE OR REPLACE FUNCTION device_watch_property_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT DISTINCT d.property_id FROM access_devices d JOIN properties p ON p.id = d.property_id
     WHERE d.is_active AND COALESCE(p.is_active, true)
       AND COALESCE(d.last_seen_at, d.created_at) < now() - make_interval(secs => d.offline_after_sec)
       AND NOT EXISTS (SELECT 1 FROM device_incidents i WHERE i.device_id = d.id AND i.recovered_at IS NULL)
$$;
REVOKE ALL ON FUNCTION device_watch_property_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION device_watch_property_ids() TO siteeksen_app;

COMMENT ON TABLE access_devices IS 'Geçiş cihazları (PTS kamerası, bariyer); canlılık sinyali izlenir (Apsiyon BUG-08) — 057';
COMMENT ON TABLE device_incidents IS 'Cihaz çevrimdışı olayları; silinemez (Apsiyon BUG-08) — 057';
