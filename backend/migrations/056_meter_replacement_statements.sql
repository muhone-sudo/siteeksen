-- =====================================================
-- 056 — SAYAÇ DEĞİŞİM PROTOKOLÜ, TÜKETİM SAPMASI, KALICI TÜKETİM PUSULASI (Apsiyon BUG-07)
--
-- 1) Sayaç değişimi: önceden yeni sayacın ilk okumasında "sayaç değişti" denince önceki
--    endeks SIFIR kabul ediliyordu; eski sayacın son okumadan söküme kadarki tüketimi
--    kayboluyor, yeni sayaç sıfırdan başlamıyorsa da fazladan tüketim yazılıyordu. Artık
--    değişim ayrı bir işlemdir: eski sayacın SÖKÜM endeksi ve yeni sayacın MONTAJ endeksi
--    kaydedilir; dönem tüketimi = (söküm − eski son okuma) + (yeni son okuma − montaj).
-- 2) Sapma: önceki okumanın tüketiminin 2,5 katını aşan okuma, görevli onaylamadan
--    kaydedilmez; onaylanırsa oran ve onaylayan kayda geçer.
-- 3) Tüketim pusulası: paylaştırma YAYIMLANINCA bölüm bazında ilk/son okuma, net tüketim,
--    tüketim payı ve alan payı değiştirilemez biçimde saklanır; sakin kendi pusulasını görür
--    (Isınma Giderleri Paylaştırma Yönetmeliği: gider paylaşım belgesi).
-- =====================================================

CREATE TABLE IF NOT EXISTS meter_replacements (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id          UUID NOT NULL REFERENCES units(id),
    old_meter_id     UUID NOT NULL REFERENCES meters(id),
    new_meter_id     UUID NOT NULL REFERENCES meters(id),
    replaced_on      DATE NOT NULL,
    removal_value    NUMERIC(14,3) NOT NULL CHECK (removal_value >= 0),
    initial_value    NUMERIC(14,3) NOT NULL CHECK (initial_value >= 0),
    reason           TEXT NOT NULL CHECK (length(trim(reason)) > 0),
    created_by       UUID REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (old_meter_id)
);
ALTER TABLE meter_replacements ENABLE ROW LEVEL SECURITY;
ALTER TABLE meter_replacements FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS meter_replacements_property_scope ON meter_replacements;
CREATE POLICY meter_replacements_property_scope ON meter_replacements
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, DELETE, TRUNCATE ON meter_replacements FROM siteeksen_app;

ALTER TABLE meter_readings ADD COLUMN IF NOT EXISTS anomaly_ratio NUMERIC(10,2);
ALTER TABLE meter_readings ADD COLUMN IF NOT EXISTS anomaly_confirmed_by UUID REFERENCES users(id);

CREATE TABLE IF NOT EXISTS consumption_allocations (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id           UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    meter_type            VARCHAR(20) NOT NULL,
    period_from           DATE NOT NULL,
    period_to             DATE NOT NULL,
    total_kurus           BIGINT NOT NULL CHECK (total_kurus > 0),
    consumption_share_pct NUMERIC(6,3),
    area_share_pct        NUMERIC(6,3),
    basis_note            TEXT,
    published_by          UUID REFERENCES users(id),
    published_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (period_to >= period_from),
    UNIQUE (property_id, meter_type, period_from, period_to)
);
CREATE TABLE IF NOT EXISTS consumption_allocation_units (
    allocation_id    UUID NOT NULL REFERENCES consumption_allocations(id) ON DELETE CASCADE,
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id          UUID NOT NULL REFERENCES units(id),
    first_date       DATE,
    first_value      NUMERIC(14,3),
    last_date        DATE,
    last_value       NUMERIC(14,3),
    replaced         BOOLEAN NOT NULL DEFAULT false,
    consumption      NUMERIC(14,3) NOT NULL,
    usable_area      NUMERIC(10,2),
    consumption_kurus BIGINT NOT NULL,
    area_kurus       BIGINT NOT NULL,
    total_kurus      BIGINT NOT NULL,
    PRIMARY KEY (allocation_id, unit_id)
);
CREATE INDEX IF NOT EXISTS idx_consumption_allocation_units_unit ON consumption_allocation_units(property_id, unit_id);

ALTER TABLE consumption_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumption_allocations FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS consumption_allocations_property_scope ON consumption_allocations;
CREATE POLICY consumption_allocations_property_scope ON consumption_allocations
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE consumption_allocation_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumption_allocation_units FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS consumption_allocation_units_property_scope ON consumption_allocation_units;
CREATE POLICY consumption_allocation_units_property_scope ON consumption_allocation_units
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, DELETE, TRUNCATE ON consumption_allocations, consumption_allocation_units FROM siteeksen_app;

COMMENT ON TABLE meter_replacements IS 'Sayaç değişimi: söküm ve montaj endeksi; dönem tüketimi iki sayaçtan toplanır (Apsiyon BUG-07) — 056';
COMMENT ON TABLE consumption_allocations IS 'Yayımlanmış gider paylaştırması; değiştirilemez (Apsiyon BUG-07) — 056';
