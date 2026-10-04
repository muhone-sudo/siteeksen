-- =====================================================
-- 039 — KURAL İHLALİ (FAZ 7.5, M-44)
--
-- Yönetim planı kurallarının (gürültü, evcil hayvan, otopark, çöp, ortak alan
-- işgali…) ihlali hiçbir yerde kaydedilmiyordu; uyarı verildi mi, savunma
-- alındı mı, tekrar mı ediyor — izlenemiyordu.
--
-- Hukuki çerçeve:
--   * KMK m.18: malikler, kiracılar ve bölümden sürekli yararlananlar yönetim
--     planına uymakla yükümlüdür; kiracı malikle MÜTESELSİL sorumludur → uyarı
--     dairenin bütün aktif sakinlerine (malik + kiracı) gider.
--   * KMK m.28: yönetim planı bütün malikleri bağlayan sözleşmedir → her kural
--     yönetim planındaki dayanağını (madde) TAŞIMAK ZORUNDADIR.
--   * Site yönetimi PARA CEZASI veremez: idari yaptırım kararı yalnızca kanunda
--     gösterilen kamu mercilerinindir (5326 s. Kabahatler K. m.22; gürültüde
--     kolluk/zabıta, m.36/3). Bu yüzden şemada ceza tutarı alanı YOKTUR.
--   * Yaptırım yolu: uyarı → yazılı uyarı → ihtar → sulh hukuk mahkemesinden
--     hâkimin müdahalesi (KMK m.33); hâkim kararına rağmen bir yıl ısrar
--     çekilmezlik sayılır (m.25/b).
--   * Bildiren kişinin kimliği ihlal edilen daireye gösterilmez (KVKK m.4
--     ölçülülük; komşuluk ilişkisinin korunması).
-- =====================================================

CREATE TABLE IF NOT EXISTS site_rules (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id         UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    category            VARCHAR(20) NOT NULL DEFAULT 'OTHER'
                        CHECK (category IN ('NOISE', 'PET', 'PARKING', 'WASTE', 'COMMON_AREA', 'RENOVATION', 'OTHER')),
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    management_plan_ref TEXT NOT NULL CHECK (length(trim(management_plan_ref)) > 0),
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_site_rules_property ON site_rules(property_id, is_active);

CREATE TABLE IF NOT EXISTS rule_violations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    rule_id      UUID NOT NULL REFERENCES site_rules(id),
    unit_id      UUID NOT NULL REFERENCES units(id),
    reported_by  UUID NOT NULL REFERENCES users(id),
    description  TEXT NOT NULL,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    status       VARCHAR(20) NOT NULL DEFAULT 'OPEN'
                 CHECK (status IN ('OPEN', 'VERIFIED', 'DISMISSED', 'RESOLVED')),
    -- Kademeli süreç; yalnızca ileri gider (uygulama karşılaştır-ve-değiştir ile).
    stage        VARCHAR(20) NOT NULL DEFAULT 'NONE'
                 CHECK (stage IN ('NONE', 'VERBAL_WARNING', 'WRITTEN_WARNING', 'FORMAL_NOTICE', 'LEGAL')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rule_violations_property ON rule_violations(property_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rule_violations_unit ON rule_violations(unit_id, created_at DESC);

-- Olay geçmişi salt eklemelidir: uyarının verildiği ve savunmanın alındığı
-- an, sonradan mahkemeye (KMK m.33) taşınacak dosyanın delilidir.
CREATE TABLE IF NOT EXISTS rule_violation_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    violation_id UUID NOT NULL REFERENCES rule_violations(id) ON DELETE CASCADE,
    event_type   VARCHAR(20) NOT NULL
                 CHECK (event_type IN ('REPORTED', 'VERIFIED', 'DISMISSED', 'VERBAL_WARNING', 'WRITTEN_WARNING',
                                       'FORMAL_NOTICE', 'LEGAL', 'RESPONSE', 'RESOLVED')),
    note         TEXT,
    actor_id     UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_rule_violation_events_violation ON rule_violation_events(violation_id, created_at);

ALTER TABLE site_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE site_rules FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS site_rules_property_scope ON site_rules;
CREATE POLICY site_rules_property_scope ON site_rules
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE rule_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_violations FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rule_violations_property_scope ON rule_violations;
CREATE POLICY rule_violations_property_scope ON rule_violations
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE rule_violation_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE rule_violation_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rule_violation_events_property_scope ON rule_violation_events;
CREATE POLICY rule_violation_events_property_scope ON rule_violation_events
    USING (EXISTS (SELECT 1 FROM rule_violations v
                   WHERE v.id = rule_violation_events.violation_id AND v.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM rule_violations v
                        WHERE v.id = rule_violation_events.violation_id AND v.property_id = current_property_id()));

REVOKE DELETE, TRUNCATE ON site_rules FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON rule_violations FROM siteeksen_app;
REVOKE UPDATE, DELETE, TRUNCATE ON rule_violation_events FROM siteeksen_app;

COMMENT ON TABLE site_rules IS 'Yönetim planına dayanan site kuralları (KMK m.28) — 039';
COMMENT ON TABLE rule_violations IS 'Kural ihlali; para cezası alanı bilerek yok (Kabahatler K. m.22) — 039';
COMMENT ON TABLE rule_violation_events IS 'İhlal olay geçmişi; salt ekleme (KMK m.33 dosyası) — 039';
