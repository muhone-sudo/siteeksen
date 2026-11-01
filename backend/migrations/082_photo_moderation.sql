-- 082: Fotoğraf denetimi (FAZ M13.4). Hizmet kalemi ve talep fotoğrafları yüklenince kuyruğa girer; denetim servisi
-- (services/moderation) önce OCR ile iletişim bilgisi arar (bulursa otomatik ret), sonra açıksa yapay zekâya sorar
-- (temizse otomatik onay, değilse ya da hata olursa platformun elle onay kuyruğu). Vitrin ve tedarikçi yalnız onaylı
-- fotoğrafı görür; yükleyen kendi fotoğrafını ve durumunu görür.

CREATE TABLE IF NOT EXISTS photo_moderation (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    storage_key     TEXT NOT NULL UNIQUE,
    source          VARCHAR(16) NOT NULL CHECK (source IN ('SERVICE_PHOTO', 'REQUEST_PHOTO')),
    service_id      UUID REFERENCES mp_business_services(id) ON DELETE SET NULL,
    request_id      UUID REFERENCES mp_requests(id),
    account_id      UUID REFERENCES mp_supplier_accounts(id),
    property_id     UUID REFERENCES properties(id),
    uploaded_by     UUID REFERENCES users(id),
    content_type    VARCHAR(40) NOT NULL DEFAULT '',
    status          VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'REVIEW', 'APPROVED', 'REJECTED', 'REPLACED')),
    ocr_text        TEXT,
    ocr_findings    TEXT[] NOT NULL DEFAULT '{}',
    ai_provider     VARCHAR(60),
    ai_verdict      VARCHAR(10) CHECK (ai_verdict IN ('CLEAN', 'UNSAFE', 'ERROR')),
    ai_categories   TEXT[] NOT NULL DEFAULT '{}',
    ai_reason       TEXT,
    decision_source VARCHAR(10) CHECK (decision_source IN ('OCR', 'AI', 'PLATFORM')),
    decided_by      UUID REFERENCES users(id),
    decided_at      TIMESTAMPTZ,
    reason          TEXT,
    attempts        INT NOT NULL DEFAULT 0,
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error      TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT photo_moderation_owner CHECK (
        (source = 'SERVICE_PHOTO' AND account_id IS NOT NULL) OR
        (source = 'REQUEST_PHOTO' AND request_id IS NOT NULL AND property_id IS NOT NULL)),
    CONSTRAINT photo_moderation_reject_reason CHECK (status <> 'REJECTED' OR reason IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_photo_moderation_due ON photo_moderation (next_attempt_at) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_photo_moderation_status ON photo_moderation (status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_photo_moderation_service ON photo_moderation (service_id);
CREATE INDEX IF NOT EXISTS idx_photo_moderation_request ON photo_moderation (request_id);
CREATE INDEX IF NOT EXISTS idx_photo_moderation_account ON photo_moderation (account_id);
CREATE INDEX IF NOT EXISTS idx_photo_moderation_property ON photo_moderation (property_id);

-- Yapay zekâ sağlayıcı ayarı (tek satır; platform). Gizli değerler pkg/encryption ile şifreli saklanır, API'de geri okunmaz.
CREATE TABLE IF NOT EXISTS moderation_ai_settings (
    id            SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    enabled       BOOLEAN NOT NULL DEFAULT false,
    provider      VARCHAR(20) NOT NULL DEFAULT 'ANTHROPIC' CHECK (provider IN ('ANTHROPIC', 'OPENAI')),
    base_url      TEXT NOT NULL DEFAULT 'https://api.anthropic.com',
    model         VARCHAR(120) NOT NULL DEFAULT '',
    auth_type     VARCHAR(10) NOT NULL DEFAULT 'API_KEY' CHECK (auth_type IN ('API_KEY', 'BASIC', 'NONE')),
    api_key_enc   TEXT,
    username      VARCHAR(200) NOT NULL DEFAULT '',
    password_enc  TEXT,
    updated_by    UUID REFERENCES users(id),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO moderation_ai_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

ALTER TABLE photo_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE photo_moderation FORCE ROW LEVEL SECURITY;
ALTER TABLE moderation_ai_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_ai_settings FORCE ROW LEVEL SECURITY;

-- Yükleyen taraf (tedarikçi hesabı ya da talebin sitesi) kendi satırlarını görür ve ekler; tedarikçi değiştirdiği fotoğrafın
-- satırını yalnız REPLACED yapabilir. Karar (durum, OCR, yapay zekâ alanları) yalnız platform kapsamında yazılır.
DROP POLICY IF EXISTS photo_moderation_read ON photo_moderation;
CREATE POLICY photo_moderation_read ON photo_moderation FOR SELECT
    USING (platform_scope() OR account_id = current_supplier_account_id() OR property_id = current_property_id());
DROP POLICY IF EXISTS photo_moderation_insert ON photo_moderation;
CREATE POLICY photo_moderation_insert ON photo_moderation FOR INSERT
    WITH CHECK (status = 'PENDING' AND (platform_scope()
        OR (source = 'SERVICE_PHOTO' AND account_id = current_supplier_account_id())
        OR (source = 'REQUEST_PHOTO' AND property_id = current_property_id())));
DROP POLICY IF EXISTS photo_moderation_platform ON photo_moderation;
CREATE POLICY photo_moderation_platform ON photo_moderation FOR UPDATE USING (platform_scope()) WITH CHECK (platform_scope());
DROP POLICY IF EXISTS photo_moderation_replace ON photo_moderation;
CREATE POLICY photo_moderation_replace ON photo_moderation FOR UPDATE
    USING (source = 'SERVICE_PHOTO' AND account_id = current_supplier_account_id())
    WITH CHECK (source = 'SERVICE_PHOTO' AND account_id = current_supplier_account_id() AND status = 'REPLACED');
DROP POLICY IF EXISTS moderation_ai_settings_platform ON moderation_ai_settings;
CREATE POLICY moderation_ai_settings_platform ON moderation_ai_settings USING (platform_scope()) WITH CHECK (platform_scope());

-- Onay sorgusu her kapsamda çalışır (vitrin herkese açık; tedarikçi talep fotoğrafını görür): yalnız evet/hayır döner.
CREATE OR REPLACE FUNCTION photo_approved(p_key TEXT)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (SELECT 1 FROM photo_moderation WHERE storage_key = p_key AND status = 'APPROVED')
$$;
REVOKE ALL ON FUNCTION photo_approved(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION photo_approved(TEXT) TO siteeksen_app;

GRANT SELECT, INSERT, UPDATE ON photo_moderation TO siteeksen_app;
GRANT SELECT, UPDATE ON moderation_ai_settings TO siteeksen_app;

-- Bu migration'dan önce yüklenmiş fotoğraflar hiç denetlenmedi: kuyruğa girer (onaylanana kadar vitrinde görünmez).
-- Pazaryeri tabloları FORCE RLS altında: doldurma platform kapsamında yapılır, sonra kapsam boşaltılır.
SELECT set_config('app.platform_user_id', 'migration-082', false);
INSERT INTO photo_moderation (storage_key, source, service_id, account_id)
SELECT s.photo_key, 'SERVICE_PHOTO', s.id, b.account_id
FROM mp_business_services s JOIN mp_businesses b ON b.id = s.business_id
WHERE s.photo_key IS NOT NULL
ON CONFLICT (storage_key) DO NOTHING;
INSERT INTO photo_moderation (storage_key, source, request_id, property_id, uploaded_by)
SELECT k.key, 'REQUEST_PHOTO', r.id, r.property_id, r.requester_user_id
FROM mp_requests r CROSS JOIN LATERAL jsonb_array_elements_text(r.photo_keys) AS k(key)
ON CONFLICT (storage_key) DO NOTHING;
SELECT set_config('app.platform_user_id', '', false);

COMMENT ON TABLE photo_moderation IS 'Fotoğraf denetim kuyruğu: OCR + isteğe bağlı yapay zekâ + platform kararı — 082';
COMMENT ON TABLE moderation_ai_settings IS 'Fotoğraf denetiminde kullanılan yapay zekâ sağlayıcısı (gizli değerler şifreli) — 082';
