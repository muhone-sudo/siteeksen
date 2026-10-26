-- =====================================================
-- 073 — BİLDİRİM OKUNDU BİLGİSİ VE İŞLEM KAYDI (FAZ H.2 / H.3, kullanıcı kararı K5 — 2026-10-26)
--
-- 1) notification_reads: kişinin kendi bildirimini okuduğu an. notifications tablosu DEĞİŞTİRİLMEZ:
--    gönderilmiş bildirim güncellenemez (016, notifications_sent_final), okundu bilgisi ayrı ve yalnız
--    eklenen bir kayıttır.
-- 2) audit_logs genişletilir — "her şey tek yerde" (kullanıcı kararı): kaynak (API / CLIENT / SYSTEM),
--    olay adı, ekran ve ayrıntı. İkinci bir log tablosu açılmaz.
--    Uygulama rolü audit_logs'u DOĞRUDAN okuyamaz (025) ve bu korunur: okuma, aktif siteyle sınırlı
--    SECURITY DEFINER işlevlerle yapılır. Silme yalnız istemci etkinliği (CLIENT) için ve saklama
--    süresine bağlı işlevle yapılır; zorunlu kayıtlar (API/SYSTEM) silinemez.
-- =====================================================

CREATE TABLE IF NOT EXISTS notification_reads (
    notification_id UUID NOT NULL REFERENCES notifications(id),
    user_id         UUID NOT NULL REFERENCES users(id),
    read_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (notification_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_notification_reads_user ON notification_reads (user_id);

ALTER TABLE notification_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_reads FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notification_reads_property_scope ON notification_reads;
CREATE POLICY notification_reads_property_scope ON notification_reads
    USING (EXISTS (SELECT 1 FROM notifications n
                   WHERE n.id = notification_reads.notification_id AND n.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM notifications n
                        WHERE n.id = notification_reads.notification_id AND n.property_id = current_property_id()));
REVOKE UPDATE, DELETE, TRUNCATE ON notification_reads FROM siteeksen_app;
GRANT SELECT, INSERT ON notification_reads TO siteeksen_app;

-- --- audit_logs genişletme ---
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS source VARCHAR(10) NOT NULL DEFAULT 'API';
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS event VARCHAR(80);
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS screen VARCHAR(160);
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS details JSONB;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'audit_logs_source_check') THEN
        ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_source_check CHECK (source IN ('API', 'CLIENT', 'SYSTEM'));
    END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_audit_logs_property_time ON audit_logs (property_id, created_at DESC);

-- Liste: yalnız aktif sitenin kayıtları. Kapsam yoksa hiç satır dönmez (fail-closed).
CREATE OR REPLACE FUNCTION audit_log_list(
    p_from TIMESTAMPTZ, p_to TIMESTAMPTZ, p_user UUID, p_action TEXT, p_entity TEXT,
    p_source TEXT, p_search TEXT, p_limit INT, p_offset INT)
RETURNS TABLE (
    id UUID, created_at TIMESTAMPTZ, user_id UUID, user_name TEXT, ip_address TEXT, action TEXT,
    entity_type TEXT, entity_id UUID, status_code INT, source TEXT, event TEXT, screen TEXT,
    details JSONB, request_id TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
    SELECT a.id, a.created_at, a.user_id,
           NULLIF(TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')), ''),
           host(a.ip_address), a.action, a.entity_type, a.entity_id, a.status_code, a.source, a.event,
           a.screen, a.details, a.request_id
    FROM audit_logs a
    LEFT JOIN users u ON u.id = a.user_id
    WHERE current_property_id() IS NOT NULL
      AND a.property_id = current_property_id()
      AND (p_from IS NULL OR a.created_at >= p_from)
      AND (p_to IS NULL OR a.created_at < p_to)
      AND (p_user IS NULL OR a.user_id = p_user)
      AND (p_action IS NULL OR a.action = p_action)
      AND (p_entity IS NULL OR a.entity_type = p_entity)
      AND (p_source IS NULL OR a.source = p_source)
      AND (p_search IS NULL OR a.event ILIKE '%' || p_search || '%' OR a.screen ILIKE '%' || p_search || '%'
           OR a.entity_type ILIKE '%' || p_search || '%')
    ORDER BY a.created_at DESC
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 100), 1), 1000) OFFSET GREATEST(COALESCE(p_offset, 0), 0)
$$;
REVOKE ALL ON FUNCTION audit_log_list(TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT, TEXT, TEXT, TEXT, INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION audit_log_list(TIMESTAMPTZ, TIMESTAMPTZ, UUID, TEXT, TEXT, TEXT, TEXT, INT, INT) TO siteeksen_app;

-- Özet: son 30 gün kaynak/işlem dağılımı ve en eski kayıt.
CREATE OR REPLACE FUNCTION audit_log_stats()
RETURNS TABLE (source TEXT, action TEXT, total BIGINT, oldest TIMESTAMPTZ)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
    SELECT a.source, a.action, count(*), min(a.created_at)
    FROM audit_logs a
    WHERE current_property_id() IS NOT NULL AND a.property_id = current_property_id()
      AND a.created_at >= now() - interval '30 days'
    GROUP BY a.source, a.action
    ORDER BY 3 DESC
$$;
REVOKE ALL ON FUNCTION audit_log_stats() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION audit_log_stats() TO siteeksen_app;

-- Saklama: YALNIZ istemci etkinliği (CLIENT) silinir; zorunlu kayıtlara dokunulmaz. Gün sınırı 30-730.
CREATE OR REPLACE FUNCTION audit_log_purge_client(p_days INT)
RETURNS BIGINT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    n BIGINT;
BEGIN
    IF current_property_id() IS NULL THEN
        RETURN 0;
    END IF;
    IF p_days IS NULL OR p_days < 30 OR p_days > 730 THEN
        RAISE EXCEPTION 'Saklama süresi 30-730 gün olmalı' USING ERRCODE = 'check_violation';
    END IF;
    DELETE FROM audit_logs
     WHERE property_id = current_property_id() AND source = 'CLIENT'
       AND created_at < now() - make_interval(days => p_days);
    GET DIAGNOSTICS n = ROW_COUNT;
    RETURN n;
END $$;
REVOKE ALL ON FUNCTION audit_log_purge_client(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION audit_log_purge_client(INT) TO siteeksen_app;
