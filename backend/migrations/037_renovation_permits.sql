-- =====================================================
-- 037 — TADİLAT İZNİ (FAZ 7.5, M-45)
--
-- Bağımsız bölümdeki ya da ortak yerdeki tadilatın kaydı yoktu: kim, ne zaman,
-- hangi müteahhitle, hangi kapsamda çalışacak; komşulara haber verildi mi;
-- teminat alındı mı, iade edildi mi — hiçbiri izlenemiyordu.
--
-- Hukuki çerçeve (koda gömülü oran YOK; oran legal_parameters'tan okunur):
--   * KMK m.19/2: kat maliki kendi bölümünde ANAYAPIYA ZARAR VERECEK değişiklik
--     yapamaz; ortak yerlerde inşaat, onarım, tesis ve DIŞ CEPHE rengi için
--     bütün kat maliklerinin BEŞTE DÖRDÜNÜN YAZILI RIZASI gerekir
--     (MAJORITY_CONSTRUCTION_CONSENT).
--   * 3194 s. İmar Kanunu m.21: taşıyıcı unsuru, dış cepheyi, ıslak hacimleri
--     etkileyen ESASLI tadilat ruhsata tabidir; boya, sıva, döşeme, tesisat
--     tamiri gibi taşıyıcıyı etkilemeyen işler değildir.
--   * Çalışma saati ulusal mevzuatta konut içi tadilat için belirlenmemiştir
--     (Çevresel Gürültü Kontrol Yönetmeliği komşu/evsel gürültüyü kapsamaz);
--     yönetim planı ya da kurul kararıyla belirlenir → site ayarı
--     RENOVATION_HOURS, onay anında izne kopyalanır.
--
-- Kapsam türleri:
--   INTERIOR    taşıyıcıya dokunmayan iç tadilat — yönetim onayı
--   STRUCTURAL  taşıyıcı sistem / esaslı tadilat — yapı ruhsatı/izin no zorunlu
--   COMMON_AREA ortak yerde değişiklik — 4/5 yazılı rıza ya da kabul edilmiş
--   FACADE      dış cephe, balkon, pencere   genel kurul maddesi zorunlu
-- =====================================================

CREATE TABLE IF NOT EXISTS renovation_permits (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id          UUID NOT NULL REFERENCES units(id),
    applicant_id     UUID NOT NULL REFERENCES users(id),
    scope            VARCHAR(20) NOT NULL
                     CHECK (scope IN ('INTERIOR', 'STRUCTURAL', 'COMMON_AREA', 'FACADE')),
    description      TEXT NOT NULL,
    contractor_name  VARCHAR(200),
    contractor_phone VARCHAR(30),
    start_date       DATE NOT NULL,
    end_date         DATE NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'STOPPED', 'COMPLETED', 'CANCELLED')),
    -- Onay anındaki site kuralları (sonradan değişen ayar verilmiş izni değiştirmesin)
    work_hours       TEXT,
    conditions       TEXT,
    deposit_amount   NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (deposit_amount >= 0),
    deposit_refunded NUMERIC(14,2) CHECK (deposit_refunded >= 0),
    permit_ref       TEXT,          -- yapı ruhsatı / belediye izni (STRUCTURAL)
    agenda_item_id   UUID REFERENCES assembly_agenda_items(id),
    consent_required INT,
    consent_count    INT,
    decision_note    TEXT,
    decided_by       UUID REFERENCES users(id),
    decided_at       TIMESTAMPTZ,
    stop_reason      TEXT,
    stopped_at       TIMESTAMPTZ,
    completion_note  TEXT,
    completed_by     UUID REFERENCES users(id),
    completed_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT renovation_permits_dates CHECK (end_date >= start_date),
    CONSTRAINT renovation_permits_refund_le_deposit
        CHECK (deposit_refunded IS NULL OR deposit_refunded <= deposit_amount),
    -- Gerekçesiz ret/durdurma/teminat kesintisi olmaz.
    CONSTRAINT renovation_permits_reject_reason
        CHECK (status <> 'REJECTED' OR length(trim(COALESCE(decision_note, ''))) > 0),
    CONSTRAINT renovation_permits_stop_reason
        CHECK (status <> 'STOPPED' OR length(trim(COALESCE(stop_reason, ''))) > 0),
    CONSTRAINT renovation_permits_retained_reason
        CHECK (deposit_refunded IS NULL OR deposit_refunded = deposit_amount
               OR length(trim(COALESCE(completion_note, ''))) > 0),
    -- Kapsamın hukuki ön koşulu veritabanında da aranır (yalnızca arayüzde değil).
    CONSTRAINT renovation_permits_structural_ref
        CHECK (scope <> 'STRUCTURAL' OR status NOT IN ('APPROVED', 'COMPLETED')
               OR length(trim(COALESCE(permit_ref, ''))) > 0),
    CONSTRAINT renovation_permits_common_consent
        CHECK (scope NOT IN ('COMMON_AREA', 'FACADE') OR status NOT IN ('APPROVED', 'COMPLETED')
               OR agenda_item_id IS NOT NULL
               OR (consent_required IS NOT NULL AND consent_count >= consent_required))
);
CREATE INDEX IF NOT EXISTS idx_renovation_permits_property ON renovation_permits(property_id, status, start_date);
CREATE INDEX IF NOT EXISTS idx_renovation_permits_unit ON renovation_permits(unit_id);

-- Kat maliklerinin yazılı rızası (KMK m.19/2). Yönetim, imzalı belgeyi aldıktan
-- sonra kaydeder; belge tarihi ve referansı saklanır.
CREATE TABLE IF NOT EXISTS renovation_consents (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permit_id     UUID NOT NULL REFERENCES renovation_permits(id) ON DELETE CASCADE,
    owner_user_id UUID NOT NULL REFERENCES users(id),
    consented_on  DATE NOT NULL,
    document_ref  TEXT,
    recorded_by   UUID REFERENCES users(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (permit_id, owner_user_id)
);
CREATE INDEX IF NOT EXISTS idx_renovation_consents_permit ON renovation_consents(permit_id);

ALTER TABLE renovation_permits ENABLE ROW LEVEL SECURITY;
ALTER TABLE renovation_permits FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS renovation_permits_property_scope ON renovation_permits;
CREATE POLICY renovation_permits_property_scope ON renovation_permits
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE renovation_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE renovation_consents FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS renovation_consents_property_scope ON renovation_consents;
CREATE POLICY renovation_consents_property_scope ON renovation_consents
    USING (EXISTS (SELECT 1 FROM renovation_permits p
                   WHERE p.id = renovation_consents.permit_id AND p.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM renovation_permits p
                        WHERE p.id = renovation_consents.permit_id AND p.property_id = current_property_id()));

-- İzin ve rıza kaydı hesap verebilirlik kaydıdır (izinsiz tadilat, hasar,
-- teminat uyuşmazlığında delil): uygulama rolü silemez.
REVOKE DELETE, TRUNCATE ON renovation_permits FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON renovation_consents FROM siteeksen_app;

COMMENT ON TABLE renovation_permits IS 'Tadilat izni (KMK m.19/2, İmar K. m.21) — 037';
COMMENT ON TABLE renovation_consents IS 'Ortak yer/dış cephe değişikliği için kat maliki yazılı rızası (KMK m.19/2) — 037';
