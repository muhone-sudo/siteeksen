-- =====================================================
-- 069 — KİRACILIĞIN BİTİŞİ (altıncı tur D4; KMK m.22, TBK m.347 vd.)
--
-- Kullanıcı kararları (2026-10-11):
--   - Malik kiracılığın bitmesini isterse KİRACININ ONAYI şarttır; kiracı reddederse kiracılık sürer.
--   - Kiracı kendi çıkışını bildirir (V1); malik onayı gerekmez, maliklere bilgi gider.
--   - Yönetim yolu: belge (UYAP doğrulama kodu İSTEĞE BAĞLI — kodsuz belgeler de var), kimlik bilgisiyle onaylanan
--     beyan, 1 hafta itiraz. İtiraz edilirse işlem askıda kalır; yalnız kiracının onayıyla ya da yeni belgeyle (yeni
--     7 gün) ilerler. İşlemi başlatan o dairenin maliki/vekili olamaz. Belge sahte çıkarsa geri alınır (V2, V7).
--   - Kiracılık bitince kiracının hanesinin kaydı biter, daire boş olur (V8).
--
-- Sistemde kiracılığı bitirmek kimseyi evinden çıkarmaz: yalnız o dairenin uygulama erişimini ve bildirimlerini keser.
-- Yine de tek taraflı bitiş baskı aracı olmasın diye bu tablo dışında bitiş YOKTUR: kimlik ve uygulama rolleri aktif
-- kiracı bağını ancak bu akışın işlem içinde açtığı `siteeksen.tenancy_end` ayarıyla pasifleştirebilir.
--
-- ERİŞİM: yalnız kimlik servisi (dizin verisi). Silme yok; her adım değiştirilemez olay kaydına yazılır.
-- =====================================================

CREATE TABLE IF NOT EXISTS tenancy_end_requests (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id        UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id            UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    tenant_link_id     UUID NOT NULL REFERENCES resident_units(id) ON DELETE CASCADE,
    kind               VARCHAR(16) NOT NULL CHECK (kind IN ('OWNER_REQUEST', 'TENANT_EXIT', 'MANAGEMENT')),
    status             VARCHAR(20) NOT NULL CHECK (status IN ('PENDING_TENANT', 'OBJECTION_WINDOW', 'SUSPENDED',
                                                              'COMPLETED', 'REJECTED', 'CANCELLED', 'REVERSED')),
    requested_by       UUID NOT NULL REFERENCES users(id),
    reason             TEXT NOT NULL DEFAULT '',
    objection_deadline TIMESTAMPTZ,
    end_date           DATE,
    closed_by          UUID REFERENCES users(id),
    closed_at          TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Yönetim yolu gerekçesiz açılamaz; itiraz penceresi yalnız yönetim yolunda vardır.
    CONSTRAINT tenancy_end_management_reason CHECK (kind <> 'MANAGEMENT' OR length(trim(reason)) >= 10),
    CONSTRAINT tenancy_end_window CHECK (status <> 'OBJECTION_WINDOW' OR (kind = 'MANAGEMENT' AND objection_deadline IS NOT NULL)),
    CONSTRAINT tenancy_end_completed CHECK (status NOT IN ('COMPLETED', 'REVERSED') OR end_date IS NOT NULL)
);
-- Kiracı bağı başına tek açık istek.
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenancy_end_open
    ON tenancy_end_requests(tenant_link_id) WHERE status IN ('PENDING_TENANT', 'OBJECTION_WINDOW', 'SUSPENDED');
CREATE INDEX IF NOT EXISTS idx_tenancy_end_property ON tenancy_end_requests(property_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tenancy_end_unit ON tenancy_end_requests(unit_id);

-- Yönetim yolunun belgeleri (yeni belgeyle yeni pencere açılır; eskisi kalır).
CREATE TABLE IF NOT EXISTS tenancy_end_documents (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id       UUID NOT NULL REFERENCES tenancy_end_requests(id) ON DELETE CASCADE,
    document_kind    VARCHAR(20) NOT NULL CHECK (document_kind IN ('TAHLIYE_KARARI', 'ICRA_TAHLIYE', 'TASINMA_TUTANAGI', 'DIGER')),
    uyap_code        VARCHAR(64),
    storage_key      TEXT NOT NULL,
    file_name        TEXT NOT NULL,
    content_type     VARCHAR(50) NOT NULL,
    size_bytes       BIGINT NOT NULL CHECK (size_bytes > 0),
    sha256           CHAR(64) NOT NULL,
    uploaded_by      UUID NOT NULL REFERENCES users(id),
    -- Kimlik bilgisiyle onaylanan beyan: yükleyen şifresini yeniden girdi; metin, IP ve zaman saklanır.
    attestation_text TEXT NOT NULL,
    attested_ip      TEXT NOT NULL,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tenancy_end_documents_request ON tenancy_end_documents(request_id);

-- Değiştirilemez olay kaydı: kim, ne zaman, ne yaptı (itirazlar ve pencereler dahil).
CREATE TABLE IF NOT EXISTS tenancy_end_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id  UUID NOT NULL REFERENCES tenancy_end_requests(id) ON DELETE CASCADE,
    event       VARCHAR(20) NOT NULL CHECK (event IN ('CREATED', 'APPROVED', 'DECLINED', 'OBJECTED', 'DOCUMENT_ADDED',
                                                       'COMPLETED', 'CANCELLED', 'REVERSED')),
    actor_id    UUID NOT NULL REFERENCES users(id),
    note        TEXT NOT NULL DEFAULT '',
    -- clock_timestamp: aynı işlemdeki olaylar (oluşturma + belge) yazılış sırasıyla sıralanır.
    created_at  TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
CREATE INDEX IF NOT EXISTS idx_tenancy_end_events_request ON tenancy_end_events(request_id, created_at);

-- 020'deki varsayılan yetkiler yeni tabloları uygulama rolüne de açar; geri alınır.
REVOKE ALL ON tenancy_end_requests, tenancy_end_documents, tenancy_end_events FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE ON tenancy_end_requests TO siteeksen_identity;
GRANT SELECT, INSERT ON tenancy_end_documents, tenancy_end_events TO siteeksen_identity;

ALTER TABLE tenancy_end_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenancy_end_requests FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenancy_end_requests_property_scope ON tenancy_end_requests;
CREATE POLICY tenancy_end_requests_property_scope ON tenancy_end_requests
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS tenancy_end_requests_identity_all ON tenancy_end_requests;
CREATE POLICY tenancy_end_requests_identity_all ON tenancy_end_requests TO siteeksen_identity USING (true) WITH CHECK (true);

ALTER TABLE tenancy_end_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenancy_end_documents FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenancy_end_documents_property_scope ON tenancy_end_documents;
CREATE POLICY tenancy_end_documents_property_scope ON tenancy_end_documents
    USING (EXISTS (SELECT 1 FROM tenancy_end_requests r WHERE r.id = tenancy_end_documents.request_id AND r.property_id = current_property_id()));
DROP POLICY IF EXISTS tenancy_end_documents_identity_all ON tenancy_end_documents;
CREATE POLICY tenancy_end_documents_identity_all ON tenancy_end_documents TO siteeksen_identity USING (true) WITH CHECK (true);

ALTER TABLE tenancy_end_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenancy_end_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenancy_end_events_property_scope ON tenancy_end_events;
CREATE POLICY tenancy_end_events_property_scope ON tenancy_end_events
    USING (EXISTS (SELECT 1 FROM tenancy_end_requests r WHERE r.id = tenancy_end_events.request_id AND r.property_id = current_property_id()));
DROP POLICY IF EXISTS tenancy_end_events_identity_all ON tenancy_end_events;
CREATE POLICY tenancy_end_events_identity_all ON tenancy_end_events TO siteeksen_identity USING (true) WITH CHECK (true);

-- Aktif kiracı bağı yalnız bitiş akışıyla pasifleşir (ya da kiracı rolünden çıkar). Süper kullanıcı (bakım) muaf.
CREATE OR REPLACE FUNCTION resident_units_tenancy_guard() RETURNS trigger AS $$
BEGIN
    IF current_user NOT IN ('siteeksen_identity', 'siteeksen_app') THEN
        RETURN NEW;
    END IF;
    IF OLD.role = 'TENANT' AND COALESCE(OLD.is_active, false)
       AND (NOT COALESCE(NEW.is_active, false) OR NEW.role <> 'TENANT')
       AND COALESCE(current_setting('siteeksen.tenancy_end', true), '') <> 'on' THEN
        RAISE EXCEPTION 'Kiracılık yalnız bitiş akışıyla biter (kiracının onayı, kendi çıkışı ya da yönetim yolu)'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_resident_units_tenancy_guard ON resident_units;
CREATE TRIGGER trg_resident_units_tenancy_guard
    BEFORE UPDATE OF is_active, role ON resident_units
    FOR EACH ROW EXECUTE FUNCTION resident_units_tenancy_guard();

-- Kiracı ayrılınca hanesinin kaydı da biter (V4/V8). Geliş tarafı 068'deki tetikleyicidedir.
CREATE OR REPLACE FUNCTION resident_units_tenant_departure() RETURNS trigger AS $$
BEGIN
    IF OLD.role = 'TENANT' AND COALESCE(OLD.is_active, false) AND NOT COALESCE(NEW.is_active, false) THEN
        UPDATE resident_units SET is_active = false, end_date = COALESCE(end_date, CURRENT_DATE)
        WHERE unit_id = NEW.unit_id AND role = 'HOUSEHOLD' AND is_active;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_resident_units_tenant_departure ON resident_units;
CREATE TRIGGER trg_resident_units_tenant_departure
    AFTER UPDATE OF is_active ON resident_units
    FOR EACH ROW EXECUTE FUNCTION resident_units_tenant_departure();

COMMENT ON TABLE tenancy_end_requests IS
    'Kiracılığın bitişi: malik isteği + kiracı onayı, kiracının çıkışı, yönetim yolu (belge, beyan, 7 gün itiraz) — 069';
