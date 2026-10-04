-- =====================================================
-- 045 — SİGORTA: DASK TAKİBİ VE HASAR KAYDI (FAZ 7.2, M-36)
--
-- 6305 s. Afet Sigortaları Kanunu:
--   m.10/1 — KMK kapsamındaki bağımsız bölümler zorunlu deprem sigortasına (DASK) tabidir
--   m.10/3 — sigortayı MALİK ya da intifa hakkı sahibi yaptırır ve HER YIL yeniler
--   m.12/2 — projeye aykırı, taşıyıcıyı olumsuz etkileyen tadilatta tazminat hakkı kaybedilir
-- Yükümlülük malikindir; site yönetimi takip eder ve hatırlatır (zorlayamaz).
-- Ortak alan poliçeleri INSURANCE türü sözleşme olarak zaten izleniyor (contracts);
-- hasar/tazminat süreci bu migration'la kaydedilir.
-- =====================================================

CREATE TABLE IF NOT EXISTS unit_insurance_policies (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id     UUID NOT NULL REFERENCES units(id),
    kind        VARCHAR(10) NOT NULL DEFAULT 'DASK' CHECK (kind IN ('DASK', 'HOME')),
    policy_no   VARCHAR(60) NOT NULL,
    insurer     VARCHAR(120),
    start_date  DATE NOT NULL,
    end_date    DATE NOT NULL,
    recorded_by UUID REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unit_insurance_policies_dates CHECK (end_date > start_date),
    UNIQUE (unit_id, kind, policy_no)
);
CREATE INDEX IF NOT EXISTS idx_unit_insurance_policies_unit ON unit_insurance_policies(unit_id, kind, end_date DESC);

CREATE TABLE IF NOT EXISTS insurance_claims (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id    UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    contract_id    UUID REFERENCES contracts(id),     -- ortak alan poliçesi (INSURANCE sözleşmesi)
    occurred_on    DATE NOT NULL,
    description    TEXT NOT NULL,
    claimed_amount NUMERIC(14,2) CHECK (claimed_amount >= 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'REPORTED'
                   CHECK (status IN ('REPORTED', 'EXPERT_ASSIGNED', 'PAID', 'REJECTED', 'CLOSED')),
    insurer_ref    VARCHAR(80),
    paid_amount    NUMERIC(14,2) CHECK (paid_amount >= 0),
    paid_on        DATE,
    note           TEXT,
    created_by     UUID REFERENCES users(id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT insurance_claims_paid CHECK (status <> 'PAID' OR (paid_amount IS NOT NULL AND paid_on IS NOT NULL)),
    CONSTRAINT insurance_claims_rejected CHECK (status <> 'REJECTED' OR length(trim(COALESCE(note, ''))) > 0)
);
CREATE INDEX IF NOT EXISTS idx_insurance_claims_property ON insurance_claims(property_id, status);

ALTER TABLE unit_insurance_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_insurance_policies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS unit_insurance_policies_property_scope ON unit_insurance_policies;
CREATE POLICY unit_insurance_policies_property_scope ON unit_insurance_policies
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE insurance_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance_claims FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS insurance_claims_property_scope ON insurance_claims;
CREATE POLICY insurance_claims_property_scope ON insurance_claims
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

REVOKE DELETE, TRUNCATE ON unit_insurance_policies FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON insurance_claims FROM siteeksen_app;

COMMENT ON TABLE unit_insurance_policies IS 'Bağımsız bölüm DASK/konut poliçeleri; yükümlülük malikindir (6305 m.10/3) — 045';
COMMENT ON TABLE insurance_claims IS 'Ortak alan sigorta hasar/tazminat kaydı — 045';
