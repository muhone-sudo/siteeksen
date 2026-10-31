-- =====================================================
-- 077 — USTA & HİZMET PAZARYERİ (FAZ M2, docs/usta-hizmet/plan.md, kullanıcı onayı 2026-10-31)
--
-- Tedarikçiler (esnaf, dükkân, hizmet veren) kendi hesaplarıyla kayıt olur (076), işletmelerini ve hizmetlerini
-- tanıtır; site sakini ve yönetimi talep açar, yakındaki tedarikçiler talebi ücret karşılığı kabul eder, teklif verir.
--
-- Gelir ilkesi: ücret, tedarikçi müşteri adayını (iletişim bilgisini) ALDIĞI ANDA önceden yüklenmiş bakiyeden düşer.
-- Bakiye hesabın satırında tutulur ve CHECK ile eksiye düşemez (borç oluşmaz); her hareket değiştirilemez deftere yazılır.
--
-- Kapsamlar (pkg/dbscope):
--   app.property_id          — site (talep açan sakin/yönetim): kendi sitesinin talepleri
--   app.supplier_account_id  — tedarikçi hesabı: kendi satırları + kendisine GÖNDERİLMİŞ ve görünür olmuş talepler
--   app.platform_user_id     — platform yöneticisi / zamanlayıcı: pazaryeri tabloları (iletişim ve mesajlar HARİÇ)
-- Kimse başka bir tedarikçinin satırını, başka sitenin talebini göremez. Vitrin, kamuya açık sütunları veren
-- görünümlerden okunur (vergi no, belge, bakiye yoktur; telefon yalnız paketi izin veriyorsa).
-- =====================================================

-- --- Kapsam işlevleri ---
CREATE OR REPLACE FUNCTION current_supplier_account_id()
RETURNS UUID LANGUAGE sql STABLE AS $$
    SELECT NULLIF(current_setting('app.supplier_account_id', true), '')::uuid
$$;
COMMENT ON FUNCTION current_supplier_account_id() IS 'Tedarikçi kapsamı (pkg/dbscope.ForSupplier); boşsa NULL — 077';

CREATE OR REPLACE FUNCTION platform_scope()
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
    SELECT COALESCE(current_setting('app.platform_user_id', true), '') <> ''
$$;
COMMENT ON FUNCTION platform_scope() IS 'Platform kapsamı (pkg/dbscope.ForPlatform): pazaryeri yönetimi ve zamanlayıcı — 077';

-- --- Site konumu (eşleşme için; boşsa ilçe eşleşmesi kullanılır) ---
ALTER TABLE properties ADD COLUMN IF NOT EXISTS latitude NUMERIC(9,6);
ALTER TABLE properties ADD COLUMN IF NOT EXISTS longitude NUMERIC(9,6);
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'properties_coords_check') THEN
        ALTER TABLE properties ADD CONSTRAINT properties_coords_check CHECK (
            (latitude IS NULL AND longitude IS NULL) OR
            (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180));
    END IF;
END $$;

-- --- Ayarlar (platform yönetir; kodda sabit yok) ---
CREATE TABLE IF NOT EXISTS mp_settings (
    key         VARCHAR(60) PRIMARY KEY,
    value_int   INT NOT NULL CHECK (value_int >= 0),
    description TEXT NOT NULL,
    updated_by  UUID REFERENCES users(id),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
INSERT INTO mp_settings (key, value_int, description) VALUES
    ('priority_window_minutes', 30, 'Ücretli paketlerin yeni talebi tek başına gördüğü süre (dakika)'),
    ('request_ttl_hours', 72, 'Kabul dolmayan talebin açık kaldığı süre (saat)'),
    ('auto_complete_days', 7, 'Tedarikçi "tamamlandı" dedikten sonra alıcı yanıt vermezse işin kendiliğinden tamamlandığı süre (gün)'),
    ('resident_daily_request_limit', 3, 'Bir kişinin bir günde açabileceği en çok talep'),
    ('max_accepts_per_request', 4, 'Bir talebi kabul edebilecek en çok tedarikçi hesabı'),
    ('low_balance_threshold_kurus', 5000, 'Bakiye bu tutarın altına düşünce tedarikçiye uyarı gider (kuruş)')
ON CONFLICT (key) DO NOTHING;

-- --- Kategoriler ---
CREATE TABLE IF NOT EXISTS mp_categories (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id         UUID REFERENCES mp_categories(id) ON DELETE RESTRICT,
    name              VARCHAR(120) NOT NULL,
    request_fee_kurus BIGINT NOT NULL CHECK (request_fee_kurus >= 0),
    buyer_scope       VARCHAR(12) NOT NULL DEFAULT 'BOTH' CHECK (buyer_scope IN ('RESIDENT', 'MANAGEMENT', 'BOTH')),
    is_active         BOOLEAN NOT NULL DEFAULT true,
    sort_order        INT NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Üst kategorisi olmayanlar da tekil olsun: NULL'lar eşit sayılır (PostgreSQL 15+).
    UNIQUE NULLS NOT DISTINCT (parent_id, name)
);

-- --- Paketler ---
CREATE TABLE IF NOT EXISTS mp_packages (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name               VARCHAR(80) NOT NULL UNIQUE,
    monthly_fee_kurus  BIGINT NOT NULL CHECK (monthly_fee_kurus >= 0),
    fee_discount_pct   INT NOT NULL DEFAULT 0 CHECK (fee_discount_pct BETWEEN 0 AND 100),
    included_requests  INT NOT NULL DEFAULT 0 CHECK (included_requests >= 0),
    monthly_sms        INT NOT NULL DEFAULT 0 CHECK (monthly_sms >= 0),
    priority_access    BOOLEAN NOT NULL DEFAULT false,
    phone_in_showcase  BOOLEAN NOT NULL DEFAULT false,
    rank_weight        INT NOT NULL DEFAULT 0 CHECK (rank_weight >= 0),
    is_default         BOOLEAN NOT NULL DEFAULT false,
    is_active          BOOLEAN NOT NULL DEFAULT true,
    sort_order         INT NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Varsayılan (ücretsiz) paket: aidatı yoktur, öncelik ve vitrinde telefon vermez.
    CONSTRAINT mp_packages_default_free CHECK (NOT is_default OR (monthly_fee_kurus = 0 AND NOT priority_access AND NOT phone_in_showcase))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_mp_packages_default ON mp_packages (is_default) WHERE is_default;
INSERT INTO mp_packages (id, name, monthly_fee_kurus, is_default, sort_order)
VALUES ('7a000000-0000-4000-8000-000000000001', 'Ücretsiz', 0, true, 0)
ON CONFLICT (id) DO NOTHING;

-- --- Tedarikçi hesabı (hesap düzeyi: doğrulama, paket, bakiye) ---
CREATE TABLE IF NOT EXISTS mp_supplier_accounts (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
    trade_name            VARCHAR(200) NOT NULL DEFAULT '',
    tax_number            VARCHAR(11) NOT NULL DEFAULT '',
    tax_office            VARCHAR(120) NOT NULL DEFAULT '',
    status                VARCHAR(12) NOT NULL DEFAULT 'DRAFT'
                          CHECK (status IN ('DRAFT', 'REVIEW', 'APPROVED', 'SUSPENDED', 'CLOSED')),
    status_reason         TEXT,
    reviewed_by           UUID REFERENCES users(id),
    reviewed_at           TIMESTAMPTZ,
    package_id            UUID NOT NULL REFERENCES mp_packages(id),
    next_package_id       UUID REFERENCES mp_packages(id),
    package_renews_at     TIMESTAMPTZ,
    period_included_left  INT NOT NULL DEFAULT 0 CHECK (period_included_left >= 0),
    period_sms_left       INT NOT NULL DEFAULT 0 CHECK (period_sms_left >= 0),
    balance_kurus         BIGINT NOT NULL DEFAULT 0 CHECK (balance_kurus >= 0),
    terms_accepted_at     TIMESTAMPTZ NOT NULL,
    closed_at             TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT mp_accounts_tax_number_format CHECK (tax_number = '' OR tax_number ~ '^[0-9]{10,11}$')
);
CREATE INDEX IF NOT EXISTS idx_mp_accounts_status ON mp_supplier_accounts (status);
CREATE INDEX IF NOT EXISTS idx_mp_accounts_renew ON mp_supplier_accounts (package_renews_at) WHERE package_renews_at IS NOT NULL;

-- Kişinin tedarikçi hesabı: hesap kimliği bilinmeden RLS altında aranamaz; yalnız kimliği döner.
CREATE OR REPLACE FUNCTION mp_account_of_user(p_user UUID)
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT id FROM mp_supplier_accounts WHERE user_id = p_user
$$;
REVOKE ALL ON FUNCTION mp_account_of_user(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_account_of_user(UUID) TO siteeksen_app;

-- --- Hesap belgeleri (vergi levhası, kimlik, oda kaydı) ---
CREATE TABLE IF NOT EXISTS mp_account_documents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id    UUID NOT NULL REFERENCES mp_supplier_accounts(id) ON DELETE RESTRICT,
    doc_type      VARCHAR(20) NOT NULL CHECK (doc_type IN ('TAX_PLATE', 'ID_CARD', 'CHAMBER_RECORD', 'OTHER')),
    file_name     VARCHAR(255) NOT NULL,
    content_type  VARCHAR(100) NOT NULL,
    size_bytes    BIGINT NOT NULL CHECK (size_bytes > 0),
    sha256        CHAR(64) NOT NULL,
    storage_key   TEXT NOT NULL,
    status        VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    review_note   TEXT,
    reviewed_by   UUID REFERENCES users(id),
    reviewed_at   TIMESTAMPTZ,
    uploaded_by   UUID NOT NULL REFERENCES users(id),
    uploaded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mp_documents_account ON mp_account_documents (account_id);

-- Belge erişim kaydı (kimlik belgesi kişisel veridir; her indirme yazılır, silinemez).
CREATE TABLE IF NOT EXISTS mp_document_access_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id  UUID NOT NULL REFERENCES mp_account_documents(id),
    account_id   UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    user_id      UUID NOT NULL REFERENCES users(id),
    accessor     VARCHAR(10) NOT NULL CHECK (accessor IN ('OWNER', 'PLATFORM')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mp_doc_access_doc ON mp_document_access_logs (document_id);

-- --- İşletmeler (şubeler) ---
CREATE TABLE IF NOT EXISTS mp_businesses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id    UUID NOT NULL REFERENCES mp_supplier_accounts(id) ON DELETE RESTRICT,
    name          VARCHAR(200) NOT NULL,
    description   TEXT NOT NULL DEFAULT '',
    phone         VARCHAR(20) NOT NULL,
    address       TEXT NOT NULL,
    city          VARCHAR(100) NOT NULL,
    district      VARCHAR(100) NOT NULL,
    latitude      NUMERIC(9,6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude     NUMERIC(9,6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    service_area  VARCHAR(8) NOT NULL DEFAULT 'KM' CHECK (service_area IN ('KM', 'CITY', 'COUNTRY')),
    radius_km     INT CHECK (radius_km BETWEEN 1 AND 500),
    status        VARCHAR(10) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'REVIEW', 'PUBLISHED', 'REJECTED', 'CLOSED')),
    review_note   TEXT,
    reviewed_by   UUID REFERENCES users(id),
    reviewed_at   TIMESTAMPTZ,
    rating_sum    INT NOT NULL DEFAULT 0 CHECK (rating_sum >= 0),
    rating_count  INT NOT NULL DEFAULT 0 CHECK (rating_count >= 0),
    completed_jobs INT NOT NULL DEFAULT 0 CHECK (completed_jobs >= 0),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT mp_businesses_radius CHECK ((service_area = 'KM') = (radius_km IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_mp_businesses_account ON mp_businesses (account_id);
CREATE INDEX IF NOT EXISTS idx_mp_businesses_published ON mp_businesses (city, district) WHERE status = 'PUBLISHED';

CREATE TABLE IF NOT EXISTS mp_business_categories (
    business_id UUID NOT NULL REFERENCES mp_businesses(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES mp_categories(id) ON DELETE RESTRICT,
    account_id  UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    PRIMARY KEY (business_id, category_id)
);
CREATE INDEX IF NOT EXISTS idx_mp_business_categories_cat ON mp_business_categories (category_id);

CREATE TABLE IF NOT EXISTS mp_business_services (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id      UUID NOT NULL REFERENCES mp_businesses(id) ON DELETE CASCADE,
    account_id       UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    name             VARCHAR(200) NOT NULL,
    description      TEXT NOT NULL DEFAULT '',
    price_min_kurus  BIGINT CHECK (price_min_kurus >= 0),
    price_max_kurus  BIGINT CHECK (price_max_kurus >= 0),
    unit             VARCHAR(40) NOT NULL DEFAULT '',
    photo_key        TEXT,
    is_active        BOOLEAN NOT NULL DEFAULT true,
    sort_order       INT NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Fiyat ya aralıktır ya da "teklifle" (ikisi de boş); alt sınır üst sınırı geçemez.
    CONSTRAINT mp_services_price CHECK ((price_min_kurus IS NULL) = (price_max_kurus IS NULL) AND
                                        (price_min_kurus IS NULL OR price_min_kurus <= price_max_kurus))
);
CREATE INDEX IF NOT EXISTS idx_mp_services_business ON mp_business_services (business_id);

-- --- Bakiye yüklemeleri (iyzico) ---
CREATE TABLE IF NOT EXISTS mp_topups (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    amount_kurus        BIGINT NOT NULL CHECK (amount_kurus > 0),
    status              VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED')),
    idempotency_key     VARCHAR(100) NOT NULL,
    gateway_token       VARCHAR(200) UNIQUE,
    conversation_id     VARCHAR(100) NOT NULL,
    gateway_payment_id  VARCHAR(100),
    error_message       TEXT,
    created_by          UUID NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at        TIMESTAMPTZ,
    UNIQUE (account_id, idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_mp_topups_pending ON mp_topups (created_at) WHERE status = 'PENDING';

-- Kimliksiz ödeme dönüşü: jetonun hangi hesaba ait olduğu (yalnız kimlik döner).
CREATE OR REPLACE FUNCTION mp_topup_account(p_token TEXT)
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT account_id FROM mp_topups WHERE gateway_token = p_token
$$;
REVOKE ALL ON FUNCTION mp_topup_account(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_topup_account(TEXT) TO siteeksen_app;

-- --- Talepler ---
CREATE TABLE IF NOT EXISTS mp_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id),
    requester_user_id   UUID NOT NULL REFERENCES users(id),
    buyer_type          VARCHAR(10) NOT NULL CHECK (buyer_type IN ('RESIDENT', 'MANAGEMENT')),
    unit_id             UUID REFERENCES units(id),
    category_id         UUID NOT NULL REFERENCES mp_categories(id),
    target_business_id  UUID REFERENCES mp_businesses(id),
    description         TEXT NOT NULL,
    photo_keys          JSONB NOT NULL DEFAULT '[]',
    preferred_time      VARCHAR(200) NOT NULL DEFAULT '',
    phone_hidden        BOOLEAN NOT NULL DEFAULT false,
    city                VARCHAR(100) NOT NULL,
    district            VARCHAR(100) NOT NULL,
    latitude            NUMERIC(9,6),
    longitude           NUMERIC(9,6),
    status              VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'FULL', 'CLOSED', 'CANCELLED', 'EXPIRED')),
    accepted_count      INT NOT NULL DEFAULT 0 CHECK (accepted_count >= 0),
    max_accepts         INT NOT NULL CHECK (max_accepts >= 1),
    consent_at          TIMESTAMPTZ NOT NULL,
    expires_at          TIMESTAMPTZ NOT NULL,
    closed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT mp_requests_accept_cap CHECK (accepted_count <= max_accepts),
    CONSTRAINT mp_requests_unit CHECK (buyer_type = 'MANAGEMENT' OR unit_id IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_mp_requests_property ON mp_requests (property_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mp_requests_requester ON mp_requests (requester_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mp_requests_open ON mp_requests (expires_at) WHERE status = 'OPEN';

-- İletişim bilgisi ayrı tabloda: yalnız alıcının sitesi ve kabul edip ödemiş tedarikçi okur.
CREATE TABLE IF NOT EXISTS mp_request_contacts (
    request_id    UUID PRIMARY KEY REFERENCES mp_requests(id),
    property_id   UUID NOT NULL REFERENCES properties(id),
    contact_name  VARCHAR(200),
    contact_phone VARCHAR(20),
    site_name     VARCHAR(200),
    site_address  TEXT,
    anonymized_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS mp_request_dispatch (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id       UUID NOT NULL REFERENCES mp_requests(id),
    property_id      UUID NOT NULL REFERENCES properties(id),
    account_id       UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    business_id      UUID NOT NULL REFERENCES mp_businesses(id),
    distance_m       INT CHECK (distance_m >= 0),
    visible_at       TIMESTAMPTZ NOT NULL,
    notified_at      TIMESTAMPTZ,
    accepted_at      TIMESTAMPTZ,
    fee_kurus        BIGINT CHECK (fee_kurus >= 0),
    used_included    BOOLEAN NOT NULL DEFAULT false,
    fee_ledger_id    UUID,
    refunded_at      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (request_id, account_id)
);
CREATE INDEX IF NOT EXISTS idx_mp_dispatch_account ON mp_request_dispatch (account_id, visible_at DESC);
CREATE INDEX IF NOT EXISTS idx_mp_dispatch_notify ON mp_request_dispatch (visible_at) WHERE notified_at IS NULL;

-- --- Bakiye defteri (yalnız ekleme) ---
CREATE TABLE IF NOT EXISTS mp_wallet_ledger (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id    UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    kind          VARCHAR(20) NOT NULL CHECK (kind IN ('TOPUP', 'PACKAGE_FEE', 'REQUEST_FEE', 'INCLUDED_REQUEST', 'REFUND', 'CLOSURE_REFUND')),
    amount_kurus  BIGINT NOT NULL,
    balance_after BIGINT NOT NULL CHECK (balance_after >= 0),
    topup_id      UUID REFERENCES mp_topups(id),
    dispatch_id   UUID REFERENCES mp_request_dispatch(id),
    package_id    UUID REFERENCES mp_packages(id),
    note          TEXT NOT NULL DEFAULT '',
    created_by    UUID REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Yön kuralı: yükleme ve iade artı, ücret eksi, hak kullanımı sıfır, kapanış iadesi bakiyeyi sıfırlar (eksi).
    CONSTRAINT mp_ledger_sign CHECK (
        (kind IN ('TOPUP', 'REFUND') AND amount_kurus > 0) OR
        (kind IN ('PACKAGE_FEE', 'REQUEST_FEE', 'CLOSURE_REFUND') AND amount_kurus < 0) OR
        (kind = 'INCLUDED_REQUEST' AND amount_kurus = 0))
);
CREATE INDEX IF NOT EXISTS idx_mp_ledger_account ON mp_wallet_ledger (account_id, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_mp_ledger_topup ON mp_wallet_ledger (topup_id) WHERE kind = 'TOPUP';
CREATE UNIQUE INDEX IF NOT EXISTS uq_mp_ledger_dispatch_fee ON mp_wallet_ledger (dispatch_id) WHERE kind IN ('REQUEST_FEE', 'INCLUDED_REQUEST');
CREATE UNIQUE INDEX IF NOT EXISTS uq_mp_ledger_dispatch_refund ON mp_wallet_ledger (dispatch_id) WHERE kind = 'REFUND';
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'mp_dispatch_fee_ledger_fk') THEN
        ALTER TABLE mp_request_dispatch ADD CONSTRAINT mp_dispatch_fee_ledger_fk FOREIGN KEY (fee_ledger_id) REFERENCES mp_wallet_ledger(id);
    END IF;
END $$;

-- --- Teklif, mesaj, iş, puan, itiraz ---
CREATE TABLE IF NOT EXISTS mp_offers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id    UUID NOT NULL REFERENCES mp_requests(id),
    dispatch_id   UUID NOT NULL REFERENCES mp_request_dispatch(id),
    property_id   UUID NOT NULL REFERENCES properties(id),
    account_id    UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    business_id   UUID NOT NULL REFERENCES mp_businesses(id),
    amount_kurus  BIGINT NOT NULL CHECK (amount_kurus > 0),
    description   TEXT NOT NULL,
    valid_until   DATE NOT NULL,
    status        VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'WITHDRAWN', 'ACCEPTED', 'DECLINED')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mp_offers_request ON mp_offers (request_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_mp_offers_active ON mp_offers (dispatch_id) WHERE status = 'ACTIVE';

CREATE TABLE IF NOT EXISTS mp_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id      UUID NOT NULL REFERENCES mp_requests(id),
    dispatch_id     UUID NOT NULL REFERENCES mp_request_dispatch(id),
    property_id     UUID NOT NULL REFERENCES properties(id),
    account_id      UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    sender_side     VARCHAR(8) NOT NULL CHECK (sender_side IN ('BUYER', 'SUPPLIER')),
    sender_user_id  UUID NOT NULL REFERENCES users(id),
    body            TEXT NOT NULL,
    anonymized_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mp_messages_thread ON mp_messages (dispatch_id, created_at);

CREATE TABLE IF NOT EXISTS mp_jobs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id          UUID NOT NULL UNIQUE REFERENCES mp_requests(id),
    offer_id            UUID NOT NULL REFERENCES mp_offers(id),
    property_id         UUID NOT NULL REFERENCES properties(id),
    account_id          UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    business_id         UUID NOT NULL REFERENCES mp_businesses(id),
    status              VARCHAR(12) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'DONE_CLAIMED', 'COMPLETED', 'DISPUTED')),
    supplier_done_at    TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    completion_source   VARCHAR(10) CHECK (completion_source IN ('BUYER', 'AUTO')),
    dispute_note        TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_mp_jobs_claimed ON mp_jobs (supplier_done_at) WHERE status = 'DONE_CLAIMED';

CREATE TABLE IF NOT EXISTS mp_reviews (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id         UUID NOT NULL UNIQUE REFERENCES mp_jobs(id),
    property_id    UUID NOT NULL REFERENCES properties(id),
    account_id     UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    business_id    UUID NOT NULL REFERENCES mp_businesses(id),
    rating         INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment        TEXT NOT NULL DEFAULT '',
    reply          TEXT,
    replied_at     TIMESTAMPTZ,
    hidden_at      TIMESTAMPTZ,
    hidden_reason  TEXT,
    hidden_by      UUID REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT mp_reviews_hidden_reason CHECK (hidden_at IS NULL OR hidden_reason IS NOT NULL)
);
CREATE INDEX IF NOT EXISTS idx_mp_reviews_business ON mp_reviews (business_id, created_at DESC);

CREATE TABLE IF NOT EXISTS mp_disputes (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispatch_id    UUID NOT NULL UNIQUE REFERENCES mp_request_dispatch(id),
    request_id     UUID NOT NULL REFERENCES mp_requests(id),
    account_id     UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    reason_code    VARCHAR(16) NOT NULL CHECK (reason_code IN ('FAKE', 'WRONG_CATEGORY', 'UNREACHABLE', 'OTHER')),
    note           TEXT NOT NULL,
    status         VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'APPROVED', 'REJECTED')),
    decided_by     UUID REFERENCES users(id),
    decided_at     TIMESTAMPTZ,
    decision_note  TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT mp_disputes_decision CHECK (status = 'OPEN' OR (decided_by IS NOT NULL AND decision_note IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_mp_disputes_open ON mp_disputes (created_at) WHERE status = 'OPEN';

-- --- Değiştirilemezlik ---
CREATE OR REPLACE FUNCTION mp_ledger_immutable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Bakiye defteri değiştirilemez ve silinemez; düzeltme yeni bir hareketle yapılır'
        USING ERRCODE = 'SE001';
END;
$$;
DROP TRIGGER IF EXISTS mp_wallet_ledger_no_change ON mp_wallet_ledger;
CREATE TRIGGER mp_wallet_ledger_no_change BEFORE UPDATE OR DELETE ON mp_wallet_ledger
    FOR EACH ROW EXECUTE FUNCTION mp_ledger_immutable();

-- Puan ve yorum değiştirilemez, silinemez; yalnız tedarikçi yanıtı (bir kez) ve platformun gizlemesi yazılır.
CREATE OR REPLACE FUNCTION mp_reviews_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Yorum silinemez; gerekçeyle gizlenebilir' USING ERRCODE = 'SE001';
    END IF;
    IF NEW.rating <> OLD.rating OR NEW.comment <> OLD.comment OR NEW.job_id <> OLD.job_id
       OR NEW.business_id <> OLD.business_id OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'Puan ve yorum değiştirilemez' USING ERRCODE = 'SE001';
    END IF;
    IF OLD.reply IS NOT NULL AND NEW.reply IS DISTINCT FROM OLD.reply THEN
        RAISE EXCEPTION 'Tedarikçi yanıtı bir kez yazılır' USING ERRCODE = 'SE001';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS mp_reviews_guard ON mp_reviews;
CREATE TRIGGER mp_reviews_guard BEFORE UPDATE OR DELETE ON mp_reviews
    FOR EACH ROW EXECUTE FUNCTION mp_reviews_guard();

-- İşletme puan özeti ve tamamlanan iş sayısı: alıcı (site kapsamı) işletme satırına yazamaz; özetleri tetikleyici tutar.
CREATE OR REPLACE FUNCTION mp_business_rating_refresh() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    UPDATE mp_businesses b SET
        rating_sum   = COALESCE((SELECT sum(rating) FROM mp_reviews r WHERE r.business_id = b.id AND r.hidden_at IS NULL), 0),
        rating_count = (SELECT count(*) FROM mp_reviews r WHERE r.business_id = b.id AND r.hidden_at IS NULL)
    WHERE b.id = NEW.business_id;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS mp_reviews_rating_refresh ON mp_reviews;
CREATE TRIGGER mp_reviews_rating_refresh AFTER INSERT OR UPDATE OF hidden_at ON mp_reviews
    FOR EACH ROW EXECUTE FUNCTION mp_business_rating_refresh();

CREATE OR REPLACE FUNCTION mp_business_jobs_refresh() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status IS DISTINCT FROM 'COMPLETED' THEN
        UPDATE mp_businesses SET completed_jobs = completed_jobs + 1 WHERE id = NEW.business_id;
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS mp_jobs_completed_refresh ON mp_jobs;
CREATE TRIGGER mp_jobs_completed_refresh AFTER UPDATE OF status ON mp_jobs
    FOR EACH ROW EXECUTE FUNCTION mp_business_jobs_refresh();

DROP TRIGGER IF EXISTS mp_requests_active_property ON mp_requests;
CREATE TRIGGER mp_requests_active_property BEFORE INSERT ON mp_requests
    FOR EACH ROW EXECUTE FUNCTION forbid_inactive_property();

-- --- Vitrin: yayındaki işletmeler herkese okunur (politika), görünümler yalnız kamuya açık sütunları verir ---
-- Görünümler SORGULAYANIN yetkisiyle çalışır (security_invoker; verify-stack bütün görünümleri denetler). Hesap ve paket
-- bilgisi tedarikçi dışına kapalı olduğundan vitrin için gereken bayraklar tanımlayıcı işlevlerden okunur.
CREATE OR REPLACE FUNCTION mp_account_public(p_account UUID)
RETURNS TABLE (approved BOOLEAN, phone_in_showcase BOOLEAN, rank_weight INT, priority_access BOOLEAN, paid_package BOOLEAN)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT a.status = 'APPROVED', p.phone_in_showcase, p.rank_weight, p.priority_access, p.monthly_fee_kurus > 0
    FROM mp_supplier_accounts a JOIN mp_packages p ON p.id = a.package_id WHERE a.id = p_account
$$;
CREATE OR REPLACE FUNCTION mp_business_is_public(p_business UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (SELECT 1 FROM mp_businesses b JOIN mp_supplier_accounts a ON a.id = b.account_id
                   WHERE b.id = p_business AND b.status = 'PUBLISHED' AND a.status = 'APPROVED')
$$;
REVOKE ALL ON FUNCTION mp_account_public(UUID), mp_business_is_public(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_account_public(UUID), mp_business_is_public(UUID) TO siteeksen_app;

CREATE OR REPLACE VIEW mp_business_public WITH (security_invoker = true) AS
SELECT b.id, b.name, b.description, b.city, b.district, b.latitude, b.longitude, b.service_area, b.radius_km,
       CASE WHEN pa.phone_in_showcase THEN b.phone END AS phone,
       pa.rank_weight, pa.priority_access, pa.paid_package,
       b.rating_count, CASE WHEN b.rating_count > 0 THEN round(b.rating_sum::numeric / b.rating_count, 2) END AS rating_avg,
       b.completed_jobs, b.account_id,
       COALESCE((SELECT array_agg(bc.category_id) FROM mp_business_categories bc WHERE bc.business_id = b.id), '{}') AS category_ids
FROM mp_businesses b
CROSS JOIN LATERAL mp_account_public(b.account_id) pa
WHERE b.status = 'PUBLISHED' AND pa.approved;

CREATE OR REPLACE VIEW mp_business_services_public WITH (security_invoker = true) AS
SELECT s.id, s.business_id, s.name, s.description, s.price_min_kurus, s.price_max_kurus, s.unit, s.photo_key, s.sort_order
FROM mp_business_services s
WHERE s.is_active AND mp_business_is_public(s.business_id);

CREATE OR REPLACE VIEW mp_reviews_public WITH (security_invoker = true) AS
SELECT r.id, r.business_id, r.rating, r.comment, r.reply, r.replied_at, r.created_at
FROM mp_reviews r
WHERE r.hidden_at IS NULL AND mp_business_is_public(r.business_id);

COMMENT ON VIEW mp_business_public IS 'Vitrin: onaylı hesabın yayındaki işletmeleri; vergi no, belge, bakiye yok; telefon yalnız paket izin veriyorsa — 077';

-- --- Satır düzeyi güvenlik ---
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['mp_settings', 'mp_categories', 'mp_packages', 'mp_supplier_accounts', 'mp_account_documents',
        'mp_document_access_logs', 'mp_businesses', 'mp_business_categories', 'mp_business_services', 'mp_topups',
        'mp_requests', 'mp_request_contacts', 'mp_request_dispatch', 'mp_wallet_ledger', 'mp_offers', 'mp_messages',
        'mp_jobs', 'mp_reviews', 'mp_disputes']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- Ayar, kategori, paket: herkes okur; yalnız platform yazar.
DROP POLICY IF EXISTS mp_settings_read ON mp_settings;
CREATE POLICY mp_settings_read ON mp_settings FOR SELECT USING (true);
DROP POLICY IF EXISTS mp_settings_platform ON mp_settings;
CREATE POLICY mp_settings_platform ON mp_settings FOR UPDATE USING (platform_scope()) WITH CHECK (platform_scope());
DROP POLICY IF EXISTS mp_categories_read ON mp_categories;
CREATE POLICY mp_categories_read ON mp_categories FOR SELECT USING (true);
DROP POLICY IF EXISTS mp_categories_platform ON mp_categories;
CREATE POLICY mp_categories_platform ON mp_categories FOR ALL USING (platform_scope()) WITH CHECK (platform_scope());
DROP POLICY IF EXISTS mp_packages_read ON mp_packages;
CREATE POLICY mp_packages_read ON mp_packages FOR SELECT USING (true);
DROP POLICY IF EXISTS mp_packages_platform ON mp_packages;
CREATE POLICY mp_packages_platform ON mp_packages FOR ALL USING (platform_scope()) WITH CHECK (platform_scope());

-- Hesap düzeyindeki tablolar: tedarikçi kendi satırları; platform hepsi.
DROP POLICY IF EXISTS mp_accounts_scope ON mp_supplier_accounts;
CREATE POLICY mp_accounts_scope ON mp_supplier_accounts
    USING (id = current_supplier_account_id() OR platform_scope())
    WITH CHECK (id = current_supplier_account_id() OR platform_scope());
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['mp_account_documents', 'mp_document_access_logs', 'mp_businesses', 'mp_business_categories',
                             'mp_business_services', 'mp_topups', 'mp_wallet_ledger', 'mp_disputes']
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_scope', t);
        EXECUTE format('CREATE POLICY %I ON %I USING (account_id = current_supplier_account_id() OR platform_scope()) '
                       'WITH CHECK (account_id = current_supplier_account_id() OR platform_scope())', t || '_scope', t);
    END LOOP;
END $$;

-- Vitrin okuması: yayındaki işletme, kategorileri, etkin hizmet kalemleri ve gizlenmemiş yorumları her kapsamda okunur.
DROP POLICY IF EXISTS mp_businesses_public_read ON mp_businesses;
CREATE POLICY mp_businesses_public_read ON mp_businesses FOR SELECT
    USING (status = 'PUBLISHED' AND (SELECT approved FROM mp_account_public(account_id)));
DROP POLICY IF EXISTS mp_business_categories_public_read ON mp_business_categories;
CREATE POLICY mp_business_categories_public_read ON mp_business_categories FOR SELECT USING (mp_business_is_public(business_id));
DROP POLICY IF EXISTS mp_business_services_public_read ON mp_business_services;
CREATE POLICY mp_business_services_public_read ON mp_business_services FOR SELECT USING (is_active AND mp_business_is_public(business_id));
DROP POLICY IF EXISTS mp_reviews_public_read ON mp_reviews;
CREATE POLICY mp_reviews_public_read ON mp_reviews FOR SELECT USING (hidden_at IS NULL AND mp_business_is_public(business_id));

-- Talep: alıcının sitesi; kendisine gönderilmiş ve görünür olmuş tedarikçi (yalnız okur); platform.
DROP POLICY IF EXISTS mp_requests_scope ON mp_requests;
CREATE POLICY mp_requests_scope ON mp_requests
    USING (property_id = current_property_id() OR platform_scope()
           OR EXISTS (SELECT 1 FROM mp_request_dispatch d WHERE d.request_id = mp_requests.id
                      AND d.account_id = current_supplier_account_id() AND d.visible_at <= now()))
    WITH CHECK (property_id = current_property_id() OR platform_scope()
           OR EXISTS (SELECT 1 FROM mp_request_dispatch d WHERE d.request_id = mp_requests.id
                      AND d.account_id = current_supplier_account_id() AND d.visible_at <= now()));

-- İletişim: alıcının sitesi; kabul edip ödemiş tedarikçi. Platform OKUYAMAZ.
DROP POLICY IF EXISTS mp_contacts_scope ON mp_request_contacts;
CREATE POLICY mp_contacts_scope ON mp_request_contacts
    USING (property_id = current_property_id()
           OR EXISTS (SELECT 1 FROM mp_request_dispatch d WHERE d.request_id = mp_request_contacts.request_id
                      AND d.account_id = current_supplier_account_id() AND d.accepted_at IS NOT NULL))
    WITH CHECK (property_id = current_property_id() OR platform_scope());

-- Gönderim, teklif, iş, puan: alıcının sitesi + ilgili tedarikçi + platform.
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['mp_request_dispatch', 'mp_offers', 'mp_jobs', 'mp_reviews']
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_scope', t);
        EXECUTE format('CREATE POLICY %I ON %I USING (property_id = current_property_id() '
                       'OR account_id = current_supplier_account_id() OR platform_scope()) '
                       'WITH CHECK (property_id = current_property_id() '
                       'OR account_id = current_supplier_account_id() OR platform_scope())', t || '_scope', t);
    END LOOP;
END $$;
-- Gönderim satırı tedarikçiye ancak görünür olduğunda açılır (öncelik penceresi).
DROP POLICY IF EXISTS mp_request_dispatch_scope ON mp_request_dispatch;
CREATE POLICY mp_request_dispatch_scope ON mp_request_dispatch
    USING (property_id = current_property_id() OR platform_scope()
           OR (account_id = current_supplier_account_id() AND visible_at <= now()))
    WITH CHECK (property_id = current_property_id() OR platform_scope()
           OR (account_id = current_supplier_account_id() AND visible_at <= now()));

-- Mesaj: yalnız taraflar (alıcının sitesi + ilgili tedarikçi). Platform OKUYAMAZ.
DROP POLICY IF EXISTS mp_messages_scope ON mp_messages;
CREATE POLICY mp_messages_scope ON mp_messages
    USING (property_id = current_property_id() OR account_id = current_supplier_account_id())
    WITH CHECK (property_id = current_property_id() OR account_id = current_supplier_account_id());

-- --- Kişi tablosu: tedarikçi kendi kaydını, platform tedarikçi kayıtlarını okur (ad, telefon, e-posta) ---
DROP POLICY IF EXISTS users_supplier_self ON users;
-- Yalnız uygulama rolü: kimlik rolü bu politikayı değerlendirmez (pazaryeri tablolarını okuma yetkisi yoktur).
CREATE POLICY users_supplier_self ON users FOR SELECT TO siteeksen_app
    USING (id = (SELECT a.user_id FROM mp_supplier_accounts a WHERE a.id = current_supplier_account_id())
           OR (platform_scope() AND EXISTS (SELECT 1 FROM mp_supplier_accounts a WHERE a.user_id = users.id)));

-- --- Bildirimler: tedarikçi alıcılı, sitesiz kayıt ---
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS supplier_account_id UUID REFERENCES mp_supplier_accounts(id);
ALTER TABLE notifications ALTER COLUMN property_id DROP NOT NULL;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notifications_site_or_supplier') THEN
        ALTER TABLE notifications ADD CONSTRAINT notifications_site_or_supplier
            CHECK ((property_id IS NULL) <> (supplier_account_id IS NULL));
    END IF;
END $$;
-- Tekilleştirme: site kayıtlarında (property_id, dedupe_key) — 016; sitesiz kayıtlarda (supplier_account_id, dedupe_key).
CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_supplier_dedupe
    ON notifications (supplier_account_id, dedupe_key) WHERE supplier_account_id IS NOT NULL AND dedupe_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_supplier ON notifications (supplier_account_id, created_at DESC) WHERE supplier_account_id IS NOT NULL;
DROP POLICY IF EXISTS notifications_supplier_scope ON notifications;
CREATE POLICY notifications_supplier_scope ON notifications
    USING (supplier_account_id IS NOT NULL AND (supplier_account_id = current_supplier_account_id() OR platform_scope()))
    WITH CHECK (supplier_account_id IS NOT NULL AND (supplier_account_id = current_supplier_account_id() OR platform_scope()));
DROP POLICY IF EXISTS notification_reads_supplier_scope ON notification_reads;
CREATE POLICY notification_reads_supplier_scope ON notification_reads
    USING (EXISTS (SELECT 1 FROM notifications n WHERE n.id = notification_reads.notification_id
                   AND n.supplier_account_id = current_supplier_account_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM notifications n WHERE n.id = notification_reads.notification_id
                        AND n.supplier_account_id = current_supplier_account_id()));

-- --- Yetkiler ---
GRANT SELECT ON mp_settings, mp_categories, mp_packages TO siteeksen_app;
GRANT UPDATE ON mp_settings TO siteeksen_app;
GRANT INSERT, UPDATE ON mp_categories, mp_packages TO siteeksen_app;
GRANT SELECT, INSERT, UPDATE ON mp_supplier_accounts, mp_account_documents, mp_businesses, mp_business_services,
    mp_topups, mp_requests, mp_request_contacts, mp_request_dispatch, mp_offers, mp_jobs, mp_reviews, mp_disputes TO siteeksen_app;
GRANT SELECT, INSERT, DELETE ON mp_business_categories TO siteeksen_app;
GRANT DELETE ON mp_business_services TO siteeksen_app;
GRANT SELECT, INSERT ON mp_wallet_ledger, mp_document_access_logs, mp_messages TO siteeksen_app;
GRANT UPDATE (body, anonymized_at) ON mp_messages TO siteeksen_app;
GRANT SELECT ON mp_business_public, mp_business_services_public, mp_reviews_public TO siteeksen_app;
GRANT UPDATE (latitude, longitude) ON properties TO siteeksen_app;

COMMENT ON TABLE mp_wallet_ledger IS 'Tedarikçi bakiye defteri: yalnız ekleme; bakiye hesabın satırında, eksiye düşemez — 077';
COMMENT ON TABLE mp_request_contacts IS 'Talep sahibinin iletişim bilgisi: yalnız alıcının sitesi ve kabul edip ödemiş tedarikçi okur — 077';
