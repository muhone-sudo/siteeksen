-- =====================================================
-- 044 — İSTEMCİ HATA RAPORLARI (todo 3.6: mobil çökme raporu)
--
-- Mobil uygulamalarda yakalanmayan hata ve çökmelerin hiçbir izi yoktu
-- (Firebase Crashlytics yok, S-10/S-15). Uygulamalar artık hatayı kendi
-- API'mize bildirir. Kişisel veri riski: hata metni/yığın izi kişisel veri
-- taşıyabilir → kısaltılır, kullanıcı kimliği dışında kişi bilgisi alınmaz;
-- saklama süresi KVKK imha kurallarına bağlanır (CLIENT_ERROR, kayıt silinir).
-- =====================================================

CREATE TABLE IF NOT EXISTS client_error_reports (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id     UUID REFERENCES users(id),
    app         VARCHAR(20) NOT NULL CHECK (app IN ('mobile', 'admin_app', 'admin_panel')),
    app_version VARCHAR(40),
    platform    VARCHAR(40),
    fatal       BOOLEAN NOT NULL DEFAULT false,
    message     TEXT NOT NULL CHECK (length(message) <= 2000),
    stack       TEXT CHECK (length(stack) <= 8000),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_client_error_reports_property ON client_error_reports(property_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_client_error_reports_user ON client_error_reports(user_id, created_at DESC);

ALTER TABLE client_error_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_error_reports FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS client_error_reports_property_scope ON client_error_reports;
CREATE POLICY client_error_reports_property_scope ON client_error_reports
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, TRUNCATE ON client_error_reports FROM siteeksen_app;

-- İmha kategorisi: istemci hata raporları (silme ile imha).
ALTER TABLE data_retention_rules DROP CONSTRAINT IF EXISTS data_retention_rules_category_check;
ALTER TABLE data_retention_rules ADD CONSTRAINT data_retention_rules_category_check
    CHECK (category IN ('VISITOR', 'PARKING_LOG', 'PACKAGE', 'CLIENT_ERROR'));

COMMENT ON TABLE client_error_reports IS 'Mobil/panel istemci hata raporları (3.6); kısaltılmış, imhaya tabi — 044';
