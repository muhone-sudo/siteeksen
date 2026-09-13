-- ============================================================================
-- 014 — Yönetişim katmanı: işletme projesi, genel kurul, defterler, icra takibi
-- ============================================================================
--
-- NEDEN VAR:
--
-- 634 sayılı Kat Mülkiyeti Kanunu'nun zorunlu kıldığı çekirdek süreçlerin HİÇBİRİ
-- için veri modeli yoktu (tasks/gap-analizi.md Bölüm A, tasks/modul-envanteri.md
-- M-16…M-20). Bir site yönetimi yazılımı bu süreçler olmadan mevzuata uygun
-- çalışamaz:
--
--   * İŞLETME PROJESİ (m.37): Yönetici, tahmini gelir-gider ve her bağımsız bölüme
--     düşen payı gösteren projeyi hazırlar, kat maliklerine ve bağımsız bölümden
--     fiilen yararlananlara TEBLİĞ eder. Tebliğden itibaren 7 GÜN içinde itiraz
--     edilmezse proje KESİNLEŞİR ve İİK m.68'deki anlamda "belge" niteliği kazanır;
--     yani doğrudan icra takibine dayanak olur. Bu yüzden tebliğ tarihi, itiraz
--     süresi ve kesinleşme anı KAYIT ALTINDA olmak zorundadır.
--
--   * GENEL KURUL (m.29-33): Çağrı en az 15 gün önce; toplantı ve karar yeter sayısı
--     SAYI ve ARSA PAYI bakımından ayrı ayrı hesaplanır; oy hakkı ve vekâlet sınırları
--     vardır. Nisap yanlış hesaplanırsa alınan karar hükümsüz olur. Bu yüzden katılım
--     ve oylar arsa payı ile birlikte saklanır.
--
--   * DEFTERLER (m.32, m.36): Karar defteri ve işletme defteri notere onaylattırılır;
--     karar defteri takvim yılı bitiminden itibaren BİR AY içinde notere kapattırılır.
--     Karar defteri sonradan değiştirilemez olmalıdır — burada girdiler ekle-only
--     tutulur ve HASH ZİNCİRİ ile birbirine bağlanır; bir kaydın sonradan değiştirilmesi
--     zinciri kırar ve denetimde görünür.
--
--   * İCRA/HUKUK (m.22, İİK m.68): Ödenmeyen ortak gider için icra takibi ve dava;
--     yeni malikin müteselsil sorumluluğu; kanuni ipotek hakkı. Takibin hangi belgeye
--     (kesinleşmiş işletme projesi ya da kurul kararı) dayandığı izlenebilir olmalıdır.
--
-- Oranlar, süreler ve nisaplar bu dosyaya GÖMÜLMEZ; `legal_parameters` tablosundan
-- (migration 012) okunur. Böylece mevzuat değişikliği şema değişikliği gerektirmez.
--
-- Tüm ifadeler idempotenttir.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) İŞLETME PROJESİ (KMK m.37)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS operating_budgets (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    period_year    INT  NOT NULL,
    -- DRAFT: hazırlanıyor · NOTIFIED: tebliğ edildi, itiraz süresi işliyor
    -- FINAL: kesinleşti (İİK m.68 belgesi) · CANCELLED: iptal
    status         VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    total_amount   DECIMAL(14,2) NOT NULL DEFAULT 0,
    prepared_by    UUID REFERENCES users(id),
    prepared_at    TIMESTAMPTZ,
    -- Tebliğ anı: itiraz süresi buradan işlemeye başlar (m.37/2)
    notified_at    TIMESTAMPTZ,
    notice_method  VARCHAR(40),           -- IMZA_KARSILIGI, TAAHHUTLU_MEKTUP, ...
    objection_deadline DATE,              -- notified_at + BUDGET_OBJECTION_DAYS
    finalized_at   TIMESTAMPTZ,
    -- Genel kurul kararı ile kabul edildiyse kararın referansı
    decision_ref   TEXT,
    note           TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT operating_budgets_status_check
        CHECK (status IN ('DRAFT', 'NOTIFIED', 'FINAL', 'CANCELLED')),
    CONSTRAINT operating_budgets_year_check
        CHECK (period_year BETWEEN 2000 AND 2200)
);

-- Bir site için bir yılda yalnızca bir yürürlükteki işletme projesi olabilir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_operating_budgets_active
    ON operating_budgets (property_id, period_year)
    WHERE status <> 'CANCELLED';

CREATE INDEX IF NOT EXISTS idx_operating_budgets_property
    ON operating_budgets (property_id, period_year DESC);

-- Gider/gelir kalemleri
CREATE TABLE IF NOT EXISTS operating_budget_items (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id         UUID NOT NULL REFERENCES operating_budgets(id) ON DELETE CASCADE,
    category_id       UUID REFERENCES expense_categories(id),
    name              VARCHAR(200) NOT NULL,
    -- Tahmini yıllık tutar
    amount            DECIMAL(14,2) NOT NULL,
    -- KMK m.20: EQUAL (kapıcı/kaloriferci/bahçıvan/bekçi, yönetici aylığı) veya
    -- SHARE_RATIO (sigorta, ortak yer bakım/onarım, ortak tesis işletme) …
    distribution_type VARCHAR(20) NOT NULL,
    kind              VARCHAR(10) NOT NULL DEFAULT 'EXPENSE',  -- EXPENSE | INCOME
    note              TEXT,
    sort_order        INT NOT NULL DEFAULT 0,

    CONSTRAINT operating_budget_items_amount_check CHECK (amount >= 0),
    CONSTRAINT operating_budget_items_kind_check CHECK (kind IN ('EXPENSE', 'INCOME'))
);

CREATE INDEX IF NOT EXISTS idx_operating_budget_items_budget
    ON operating_budget_items (budget_id, sort_order);

-- Bağımsız bölüm başına düşen pay (m.37: "her kat malikine düşen tahmini miktar")
-- Tutarlar KURUŞ (tam sayı) tutulur: dağıtımda kuruş kaybı olmaması için
-- (bkz. pkg/money — en büyük kalan yöntemi).
CREATE TABLE IF NOT EXISTS operating_budget_unit_shares (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id    UUID NOT NULL REFERENCES operating_budgets(id) ON DELETE CASCADE,
    unit_id      UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    annual_kurus BIGINT NOT NULL,
    monthly_kurus BIGINT NOT NULL,
    -- Kalem bazlı döküm (hangi giderden ne kadar), denetim ve itiraz için
    breakdown    JSONB,

    CONSTRAINT operating_budget_unit_shares_amount_check CHECK (annual_kurus >= 0),
    UNIQUE (budget_id, unit_id)
);

-- İtirazlar (m.37/2: tebliğden itibaren 7 gün)
CREATE TABLE IF NOT EXISTS budget_objections (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id     UUID NOT NULL REFERENCES operating_budgets(id) ON DELETE CASCADE,
    unit_id       UUID REFERENCES units(id),
    user_id       UUID REFERENCES users(id),
    reason        TEXT NOT NULL,
    submitted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- İtirazın süresinde yapılıp yapılmadığı hesaplanabilir olmalı:
    -- submitted_at <= objection_deadline
    resolved_at   TIMESTAMPTZ,
    resolution    TEXT,
    status        VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    CONSTRAINT budget_objections_status_check
        CHECK (status IN ('OPEN', 'ACCEPTED', 'REJECTED', 'WITHDRAWN'))
);

CREATE INDEX IF NOT EXISTS idx_budget_objections_budget
    ON budget_objections (budget_id, status);

-- ---------------------------------------------------------------------------
-- 2) GENEL KURUL / KAT MALİKLERİ KURULU (KMK m.29-33)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS assemblies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id     UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    kind            VARCHAR(20) NOT NULL DEFAULT 'ORDINARY',  -- ORDINARY | EXTRAORDINARY
    -- İlk toplantıda yeter sayı sağlanamazsa ikinci toplantı yapılır (m.30/3).
    call_number     SMALLINT NOT NULL DEFAULT 1,
    scheduled_at    TIMESTAMPTZ NOT NULL,
    location        VARCHAR(300),
    -- m.29: çağrı toplantıdan en az 15 gün önce, imza karşılığı veya taahhütlü mektupla
    notice_sent_at  TIMESTAMPTZ,
    notice_method   VARCHAR(40),
    status          VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    held_at         TIMESTAMPTZ,
    -- Toplantı anındaki nisap fotoğrafı (sonradan yeniden hesaplanamaz olmalı)
    total_units             INT,
    total_share_ratio       NUMERIC(14,4),
    attended_units          INT,
    attended_share_ratio    NUMERIC(14,4),
    quorum_met              BOOLEAN,
    minutes_ref             TEXT,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT assemblies_kind_check CHECK (kind IN ('ORDINARY', 'EXTRAORDINARY')),
    CONSTRAINT assemblies_status_check
        CHECK (status IN ('PLANNED', 'NOTIFIED', 'HELD', 'CANCELLED')),
    CONSTRAINT assemblies_call_check CHECK (call_number IN (1, 2))
);

CREATE INDEX IF NOT EXISTS idx_assemblies_property
    ON assemblies (property_id, scheduled_at DESC);

CREATE TABLE IF NOT EXISTS assembly_agenda_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assembly_id   UUID NOT NULL REFERENCES assemblies(id) ON DELETE CASCADE,
    order_no      INT NOT NULL,
    title         VARCHAR(300) NOT NULL,
    description   TEXT,
    -- Bu gündem maddesi için aranan nisap. legal_parameters kodlarıyla eşleşir:
    -- MAJORITY_INNOVATION (m.42), MAJORITY_CONSTRUCTION_CONSENT (m.19/2),
    -- MAJORITY_MANAGEMENT_PLAN_CHANGE (m.28), UNANIMITY_TRANSFER_ACTS (m.45) …
    required_majority_code VARCHAR(80),
    decision_text VARCHAR(2000),
    decision_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    -- Oylar hem SAYI hem ARSA PAYI olarak tutulur (m.30/m.42)
    votes_for       INT NOT NULL DEFAULT 0,
    votes_against   INT NOT NULL DEFAULT 0,
    votes_abstain   INT NOT NULL DEFAULT 0,
    share_for       NUMERIC(14,4) NOT NULL DEFAULT 0,
    share_against   NUMERIC(14,4) NOT NULL DEFAULT 0,
    share_abstain   NUMERIC(14,4) NOT NULL DEFAULT 0,

    CONSTRAINT assembly_agenda_items_status_check
        CHECK (decision_status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'POSTPONED')),
    UNIQUE (assembly_id, order_no)
);

-- Katılım listesi (hazirun cetveli)
CREATE TABLE IF NOT EXISTS assembly_attendees (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assembly_id      UUID NOT NULL REFERENCES assemblies(id) ON DELETE CASCADE,
    unit_id          UUID NOT NULL REFERENCES units(id),
    user_id          UUID REFERENCES users(id),
    attendance_type  VARCHAR(10) NOT NULL DEFAULT 'SELF',  -- SELF | PROXY
    proxy_holder_id  UUID REFERENCES users(id),
    -- Toplantı anındaki arsa payı (sonradan değişse bile karar geçerliliği etkilenmemeli)
    share_ratio      NUMERIC(14,4) NOT NULL,
    registered_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT assembly_attendees_type_check CHECK (attendance_type IN ('SELF', 'PROXY')),
    CONSTRAINT assembly_attendees_proxy_check
        CHECK (attendance_type = 'SELF' OR proxy_holder_id IS NOT NULL),
    -- Bir bağımsız bölüm bir toplantıda bir kez temsil edilir
    UNIQUE (assembly_id, unit_id)
);

CREATE INDEX IF NOT EXISTS idx_assembly_attendees_assembly
    ON assembly_attendees (assembly_id);

-- Vekâletler (m.31: vekil, toplam oyun %5'inden fazlasını kullanamaz;
-- 40 ve daha az bağımsız bölümlü yapıda bir kişi en fazla 2 vekâlet alabilir)
CREATE TABLE IF NOT EXISTS assembly_proxies (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assembly_id     UUID NOT NULL REFERENCES assemblies(id) ON DELETE CASCADE,
    grantor_unit_id UUID NOT NULL REFERENCES units(id),
    grantor_user_id UUID REFERENCES users(id),
    holder_user_id  UUID NOT NULL REFERENCES users(id),
    document_ref    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (assembly_id, grantor_unit_id)
);

CREATE INDEX IF NOT EXISTS idx_assembly_proxies_holder
    ON assembly_proxies (assembly_id, holder_user_id);

-- Oy kayıtları
CREATE TABLE IF NOT EXISTS assembly_votes (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agenda_item_id UUID NOT NULL REFERENCES assembly_agenda_items(id) ON DELETE CASCADE,
    unit_id        UUID NOT NULL REFERENCES units(id),
    vote           VARCHAR(10) NOT NULL,   -- FOR | AGAINST | ABSTAIN
    share_ratio    NUMERIC(14,4) NOT NULL,
    cast_by        UUID REFERENCES users(id),
    cast_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT assembly_votes_value_check CHECK (vote IN ('FOR', 'AGAINST', 'ABSTAIN')),
    -- Her bağımsız bölüm her madde için bir kez oy kullanır (m.31: her BB 1 oy)
    UNIQUE (agenda_item_id, unit_id)
);

-- ---------------------------------------------------------------------------
-- 3) DEFTERLER (KMK m.32, m.36)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS books (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    -- DECISION: karar defteri · OPERATING: işletme defteri
    kind             VARCHAR(20) NOT NULL,
    period_year      INT NOT NULL,
    notary_opened_at DATE,
    notary_closed_at DATE,
    notary_ref       TEXT,
    status           VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT books_kind_check CHECK (kind IN ('DECISION', 'OPERATING')),
    CONSTRAINT books_status_check CHECK (status IN ('OPEN', 'CLOSED')),
    UNIQUE (property_id, kind, period_year)
);

-- Defter kayıtları — EKLE-ONLY ve HASH ZİNCİRLİ.
--
-- Karar defteri hukuken sonradan değiştirilemez bir belgedir. Veritabanı düzeyinde
-- bunu garanti etmek için:
--   * UPDATE ve DELETE tetikleyici ile engellenir,
--   * her kayıt bir önceki kaydın hash'ini taşır; bir satır dışarıdan değiştirilirse
--     (örn. doğrudan SQL ile) zincir kırılır ve doğrulama bunu görür.
CREATE TABLE IF NOT EXISTS book_entries (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id      UUID NOT NULL REFERENCES books(id) ON DELETE RESTRICT,
    entry_no     INT NOT NULL,
    entry_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    title        VARCHAR(300) NOT NULL,
    body         TEXT NOT NULL,
    -- Kaydın kaynağı (genel kurul kararı, işletme projesi, ödeme vb.)
    source_type  VARCHAR(40),
    source_id    UUID,
    created_by   UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    prev_hash    CHAR(64),
    entry_hash   CHAR(64) NOT NULL,

    UNIQUE (book_id, entry_no)
);

CREATE INDEX IF NOT EXISTS idx_book_entries_book ON book_entries (book_id, entry_no);

-- Defter kayıtları değiştirilemez ve silinemez.
CREATE OR REPLACE FUNCTION book_entries_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION
        'Defter kaydı değiştirilemez veya silinemez (KMK m.32/36). Düzeltme için yeni kayıt açın.'
        USING ERRCODE = 'restrict_violation';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS book_entries_no_update ON book_entries;
CREATE TRIGGER book_entries_no_update
    BEFORE UPDATE OR DELETE ON book_entries
    FOR EACH ROW EXECUTE FUNCTION book_entries_append_only();

-- ---------------------------------------------------------------------------
-- 4) YÖNETİCİ / DENETÇİ GÖREV DÖNEMLERİ (KMK m.34, m.41)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS governing_terms (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id      UUID REFERENCES users(id),
    -- Yönetici dışarıdan (kat maliki olmayan) biri de olabilir (m.34/son)
    external_name VARCHAR(200),
    role         VARCHAR(20) NOT NULL,   -- MANAGER | AUDITOR | BOARD_MEMBER
    assembly_id  UUID REFERENCES assemblies(id),
    decision_ref TEXT,
    start_date   DATE NOT NULL,
    end_date     DATE,
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT governing_terms_role_check
        CHECK (role IN ('MANAGER', 'AUDITOR', 'BOARD_MEMBER')),
    CONSTRAINT governing_terms_person_check
        CHECK (user_id IS NOT NULL OR external_name IS NOT NULL),
    CONSTRAINT governing_terms_period_check
        CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_governing_terms_property
    ON governing_terms (property_id, role) WHERE is_active;

-- Yıllık hesap verme (m.39: takvim yılının birinci ayı içinde)
CREATE TABLE IF NOT EXISTS accountability_reports (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    period_year   INT NOT NULL,
    submitted_at  TIMESTAMPTZ,
    submitted_by  UUID REFERENCES users(id),
    assembly_id   UUID REFERENCES assemblies(id),
    total_income  DECIMAL(14,2),
    total_expense DECIMAL(14,2),
    closing_balance DECIMAL(14,2),
    document_ref  TEXT,
    status        VARCHAR(20) NOT NULL DEFAULT 'DRAFT',

    CONSTRAINT accountability_reports_status_check
        CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED')),
    UNIQUE (property_id, period_year)
);

-- Denetim tutanakları (m.41: en az 3 ayda bir)
CREATE TABLE IF NOT EXISTS audit_reports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    audited_from DATE NOT NULL,
    audited_to   DATE NOT NULL,
    auditor_id   UUID REFERENCES users(id),
    findings     TEXT,
    opinion      VARCHAR(20),    -- CLEAN | QUALIFIED | ADVERSE
    reported_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    book_entry_id UUID REFERENCES book_entries(id),

    CONSTRAINT audit_reports_period_check CHECK (audited_to >= audited_from),
    CONSTRAINT audit_reports_opinion_check
        CHECK (opinion IS NULL OR opinion IN ('CLEAN', 'QUALIFIED', 'ADVERSE'))
);

-- ---------------------------------------------------------------------------
-- 5) HUKUK / İCRA TAKİBİ (KMK m.22, İİK m.68)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS legal_cases (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id       UUID REFERENCES units(id),
    debtor_user_id UUID REFERENCES users(id),
    -- EXECUTION: icra takibi · LAWSUIT: dava · MORTGAGE: kanuni ipotek (m.22/2)
    case_type     VARCHAR(20) NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'PREPARING',
    principal_kurus BIGINT NOT NULL DEFAULT 0,
    late_fee_kurus  BIGINT NOT NULL DEFAULT 0,
    -- Takibin dayandığı belge: kesinleşmiş işletme projesi ya da kat malikleri
    -- kurulu kararı (m.37/son — İİK m.68 anlamında belge)
    basis_document_type VARCHAR(30),
    basis_document_id   UUID,
    filed_at      DATE,
    office_or_court VARCHAR(200),
    file_no       VARCHAR(100),
    lawyer_name   VARCHAR(200),
    note          TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT legal_cases_type_check
        CHECK (case_type IN ('EXECUTION', 'LAWSUIT', 'MORTGAGE')),
    CONSTRAINT legal_cases_status_check
        CHECK (status IN ('PREPARING', 'FILED', 'OBJECTED', 'CONCLUDED', 'COLLECTED', 'WITHDRAWN')),
    CONSTRAINT legal_cases_basis_check
        CHECK (basis_document_type IS NULL
               OR basis_document_type IN ('OPERATING_BUDGET', 'ASSEMBLY_DECISION', 'COURT_ORDER'))
);

CREATE INDEX IF NOT EXISTS idx_legal_cases_property ON legal_cases (property_id, status);
CREATE INDEX IF NOT EXISTS idx_legal_cases_unit ON legal_cases (unit_id);

CREATE TABLE IF NOT EXISTS legal_case_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id     UUID NOT NULL REFERENCES legal_cases(id) ON DELETE CASCADE,
    event_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    event_type  VARCHAR(40) NOT NULL,
    description TEXT,
    amount_kurus BIGINT,
    created_by  UUID REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_legal_case_events_case
    ON legal_case_events (case_id, event_date DESC);

-- ---------------------------------------------------------------------------
-- 6) GECİKME TAZMİNATI TAHAKKUKU (KMK m.20/2)
--
-- Gecikme tazminatı bugüne kadar hiç hesaplanmıyordu. Hesaplanan tazminatın
-- HANGİ GÜN, HANGİ ORANLA ve hangi anapara üzerinden üretildiği izlenebilir
-- olmalıdır; aksi hâlde borçlu itiraz ettiğinde savunulamaz.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS late_fee_accruals (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id   UUID NOT NULL REFERENCES monthly_assessments(id) ON DELETE CASCADE,
    accrued_on      DATE NOT NULL,
    overdue_days    INT NOT NULL,
    principal_kurus BIGINT NOT NULL,
    monthly_rate    NUMERIC(10,6) NOT NULL,
    fee_kurus       BIGINT NOT NULL,
    legal_basis     TEXT NOT NULL DEFAULT 'KMK m.20/2',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Aynı tahakkuk için aynı gün iki kez tazminat işletilemez (idempotency).
    UNIQUE (assessment_id, accrued_on)
);

CREATE INDEX IF NOT EXISTS idx_late_fee_accruals_assessment
    ON late_fee_accruals (assessment_id, accrued_on DESC);

COMMENT ON TABLE operating_budgets IS 'İşletme projesi (KMK m.37). FINAL durumu İİK m.68 belgesi niteliği taşır.';
COMMENT ON TABLE assemblies IS 'Kat malikleri kurulu toplantıları (KMK m.29-33). Nisap sayı VE arsa payı ile hesaplanır.';
COMMENT ON TABLE book_entries IS 'Defter kayıtları — ekle-only ve hash zincirli (KMK m.32/36).';
COMMENT ON TABLE legal_cases IS 'Ortak gider alacağı için icra/dava/kanuni ipotek takibi (KMK m.22, İİK m.68).';
COMMENT ON TABLE late_fee_accruals IS 'Gecikme tazminatı tahakkuk izi (KMK m.20/2, aylık %5).';
