-- =====================================================
-- 042 — ORTAK ALAN GELİRİ (FAZ 7.6, M-46)
--
-- Çatı/cephe reklamı, baz istasyonu, kapıcı dairesi, otopark gibi ortak yer
-- kiralamaları ve gelirleri kayıt dışıydı.
--
-- Hukuki çerçeve:
--   * KMK m.45: ortak yerin kiraya verilmesi (çatı/dış duvar reklamı gibi önemli
--     yönetim işleri) BÜTÜN kat maliklerinin OYBİRLİĞİ ister (Yargıtay 20. HD
--     25.06.2019, E.2019/2193 K.2019/4422). Sözleşme, UNANIMITY_TRANSFER_ACTS
--     nisabıyla kabul edilmiş genel kurul maddesine bağlanmadan kaydedilmez.
--   * Sığınak kiraya verilemez (Sığınak Yönetmeliği); özel amaca tahsisli yer
--     tahsis kaldırılmadan oybirliğiyle dahi kiralanamaz (20. HD 2019/1200) —
--     sığınak türü bu yüzden listede YOK.
--   * Gelir kat maliklerinindir; aksi kararlaştırılmadıkça arsa payı oranında
--     paylaştırılır. Her malik kendi payını beyan eder (Gelir İdaresi özelgesi,
--     Rize Defterdarlığı 01/08/2011 B.07.4.DEF.0.53.10.00-GVK-85-12). Kiracı
--     işyeriyse ödediği kiradan stopaj yapar (GVK m.94); stopaj da paylaştırılır.
--     Oran koda gömülmez: stopaj tutarı kiracının yaptığı kesintiden girilir.
-- =====================================================

CREATE TABLE IF NOT EXISTS common_area_leases (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id        UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    area_kind          VARCHAR(20) NOT NULL
                       CHECK (area_kind IN ('ROOF_FACADE_AD', 'ANTENNA', 'CARETAKER_FLAT', 'PARKING', 'STORAGE', 'SHOP', 'OTHER')),
    area_name          VARCHAR(200) NOT NULL,
    tenant_name        VARCHAR(200) NOT NULL,
    tenant_is_business BOOLEAN NOT NULL DEFAULT false,
    start_date         DATE NOT NULL,
    end_date           DATE,
    monthly_rent       NUMERIC(14,2) NOT NULL CHECK (monthly_rent > 0),
    agenda_item_id     UUID NOT NULL REFERENCES assembly_agenda_items(id),
    status             VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'ENDED')),
    note               TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT common_area_leases_dates CHECK (end_date IS NULL OR end_date >= start_date)
);
CREATE INDEX IF NOT EXISTS idx_common_area_leases_property ON common_area_leases(property_id, status);

CREATE TABLE IF NOT EXISTS common_area_incomes (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lease_id          UUID NOT NULL REFERENCES common_area_leases(id),
    period            CHAR(7) NOT NULL CHECK (period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
    gross_amount      NUMERIC(14,2) NOT NULL CHECK (gross_amount > 0),
    withholding_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (withholding_amount >= 0),
    received_on       DATE NOT NULL,
    note              TEXT,
    recorded_by       UUID REFERENCES users(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT common_area_incomes_withholding_le_gross CHECK (withholding_amount <= gross_amount),
    UNIQUE (lease_id, period)
);

-- Gelirin bağımsız bölümlere arsa payı oranında dağılımı (kuruş, en büyük kalan).
CREATE TABLE IF NOT EXISTS common_area_income_shares (
    income_id         UUID NOT NULL REFERENCES common_area_incomes(id) ON DELETE CASCADE,
    unit_id           UUID NOT NULL REFERENCES units(id),
    gross_kurus       BIGINT NOT NULL,
    withholding_kurus BIGINT NOT NULL,
    PRIMARY KEY (income_id, unit_id)
);

ALTER TABLE common_area_leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_area_leases FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS common_area_leases_property_scope ON common_area_leases;
CREATE POLICY common_area_leases_property_scope ON common_area_leases
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE common_area_incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_area_incomes FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS common_area_incomes_property_scope ON common_area_incomes;
CREATE POLICY common_area_incomes_property_scope ON common_area_incomes
    USING (EXISTS (SELECT 1 FROM common_area_leases l WHERE l.id = common_area_incomes.lease_id AND l.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM common_area_leases l WHERE l.id = common_area_incomes.lease_id AND l.property_id = current_property_id()));

ALTER TABLE common_area_income_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE common_area_income_shares FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS common_area_income_shares_property_scope ON common_area_income_shares;
CREATE POLICY common_area_income_shares_property_scope ON common_area_income_shares
    USING (EXISTS (SELECT 1 FROM common_area_incomes i JOIN common_area_leases l ON l.id = i.lease_id
                   WHERE i.id = common_area_income_shares.income_id AND l.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM common_area_incomes i JOIN common_area_leases l ON l.id = i.lease_id
                        WHERE i.id = common_area_income_shares.income_id AND l.property_id = current_property_id()));

-- Gelir kaydı kat maliklerinin beyanına dayanaktır: silinemez, değiştirilemez.
REVOKE DELETE, TRUNCATE ON common_area_leases FROM siteeksen_app;
REVOKE UPDATE, DELETE, TRUNCATE ON common_area_incomes FROM siteeksen_app;
REVOKE UPDATE, DELETE, TRUNCATE ON common_area_income_shares FROM siteeksen_app;

COMMENT ON TABLE common_area_leases IS 'Ortak yer kiralaması; oybirliğiyle kabul edilmiş genel kurul maddesi zorunlu (KMK m.45) — 042';
COMMENT ON TABLE common_area_incomes IS 'Ortak alan kira geliri; kat maliklerine arsa payı oranında ait — 042';
