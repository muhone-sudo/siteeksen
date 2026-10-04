-- =====================================================
-- 040 — ACİL DURUM VE AFET (FAZ 7.3, M-37)
--
-- Afet anında gereken bilgilerin (ana vana, gaz vanası, pano, toplanma alanı,
-- acil telefonlar) ve yardıma ihtiyacı olabilecek sakinlerin kaydı yoktu;
-- deprem sonrası "kim güvende, kim yardım bekliyor" sorusunu yanıtlamanın
-- yolu yoktu.
--
--   1. emergency_points   — kritik altyapı ve toplanma alanı kartı
--   2. emergency_contacts — sitenin acil iletişim listesi (ulusal numara 112)
--   3. emergency_drills   — tatbikat kaydı: tarih, eksiklikler, düzeltici
--                           faaliyet (İşyerlerinde Acil Durumlar Hk. Yönetmelik
--                           m.13: yılda en az bir; personel çalıştıran yönetim
--                           işverendir — 6331 s. Kanun)
--   4. resident_emergency_cards — sakin acil bilgi kartı. Sağlık/engellilik
--      bilgisi ÖZEL NİTELİKLİ kişisel veridir (KVKK m.6/1); işleme açık rızaya
--      dayanır (m.6/3-a, 7499 s. Kanunla değişik). Kurul'un "yeterli önlem"
--      şartı (m.6/4) için bilgi pkg/pii ile ŞİFRELİ tutulur; rıza zamanı ve
--      metin sürümü saklanır; sakin kartı silince kayıt GERÇEKTEN silinir (m.7).
--   5. safety_checks / safety_check_responses — afet sonrası durum bildirimi
--      ("güvendeyim" / "yardım gerekiyor").
-- =====================================================

INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, is_mandatory, description)
SELECT 'EMERGENCY_DRILL_INTERVAL_MONTHS', 12, 'MONTH',
       'İşyerlerinde Acil Durumlar Hakkında Yönetmelik (RG 18/6/2013, 28681) m.13 — acil durum planının uygulanabilirliği için '
       || 'yılda en az bir defa tatbikat yapılır ve tatbikat raporu hazırlanır (6331 s. İSG Kanunu m.11)',
       true, 'Tatbikatlar arası en uzun süre (personel çalıştıran site yönetimi işverendir)'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'EMERGENCY_DRILL_INTERVAL_MONTHS' AND property_id IS NULL);

CREATE TABLE IF NOT EXISTS emergency_points (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    kind        VARCHAR(30) NOT NULL CHECK (kind IN ('ASSEMBLY_AREA', 'WATER_VALVE', 'GAS_VALVE', 'ELECTRIC_PANEL',
                                                     'GENERATOR', 'FIRE_PUMP', 'FIRE_CABINET', 'FIRST_AID', 'SHELTER', 'OTHER')),
    name        VARCHAR(200) NOT NULL,
    location    TEXT NOT NULL,
    note        TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_emergency_points_property ON emergency_points(property_id, kind);

CREATE TABLE IF NOT EXISTS emergency_contacts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    category    VARCHAR(30) NOT NULL CHECK (category IN ('EMERGENCY', 'UTILITY', 'HOSPITAL', 'MANAGEMENT', 'SECURITY', 'TECHNICAL', 'OTHER')),
    name        VARCHAR(200) NOT NULL,
    phone       VARCHAR(30) NOT NULL,
    note        TEXT,
    sort_order  INT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_property ON emergency_contacts(property_id, sort_order);

CREATE TABLE IF NOT EXISTS emergency_drills (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id        UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    kind               VARCHAR(20) NOT NULL CHECK (kind IN ('FIRE', 'EARTHQUAKE', 'EVACUATION', 'FLOOD', 'OTHER')),
    drill_date         DATE NOT NULL,
    participants       INT CHECK (participants >= 0),
    findings           TEXT NOT NULL,        -- görülen eksiklikler (m.13: raporda zorunlu)
    corrective_actions TEXT,
    recorded_by        UUID REFERENCES users(id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_emergency_drills_property ON emergency_drills(property_id, drill_date DESC);

CREATE TABLE IF NOT EXISTS resident_emergency_cards (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id            UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id                UUID NOT NULL REFERENCES users(id),
    unit_id                UUID NOT NULL REFERENCES units(id),
    -- Özel nitelikli bilgi (yardım ihtiyacı, sağlık durumu): pkg/pii şifreli metni.
    needs_encrypted        TEXT NOT NULL,
    household_count        INT CHECK (household_count BETWEEN 1 AND 50),
    contact_name           VARCHAR(200),
    contact_phone          VARCHAR(30),
    consent_at             TIMESTAMPTZ NOT NULL,
    consent_version        VARCHAR(20) NOT NULL,
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (property_id, user_id, unit_id)
);
CREATE INDEX IF NOT EXISTS idx_resident_emergency_cards_property ON resident_emergency_cards(property_id);

CREATE TABLE IF NOT EXISTS safety_checks (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    kind        VARCHAR(20) NOT NULL CHECK (kind IN ('EARTHQUAKE', 'FIRE', 'FLOOD', 'EVACUATION', 'OTHER')),
    title       VARCHAR(200) NOT NULL,
    status      VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    opened_by   UUID REFERENCES users(id),
    opened_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at   TIMESTAMPTZ
);
-- Aynı anda tek açık durum bildirimi: iki ayrı çağrı sakinin hangisine yanıt
-- vereceğini belirsizleştirir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_safety_checks_open ON safety_checks(property_id) WHERE status = 'OPEN';

CREATE TABLE IF NOT EXISTS safety_check_responses (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_id     UUID NOT NULL REFERENCES safety_checks(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id),
    unit_id      UUID REFERENCES units(id),
    status       VARCHAR(10) NOT NULL CHECK (status IN ('SAFE', 'NEED_HELP')),
    note         TEXT,
    responded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (check_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_safety_check_responses_check ON safety_check_responses(check_id, status);

DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['emergency_points', 'emergency_contacts', 'emergency_drills',
                             'resident_emergency_cards', 'safety_checks'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('ALTER TABLE %I FORCE ROW LEVEL SECURITY', t);
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', t || '_property_scope', t);
        EXECUTE format('CREATE POLICY %I ON %I USING (property_id = current_property_id()) '
                       'WITH CHECK (property_id = current_property_id())', t || '_property_scope', t);
    END LOOP;
END $$;

ALTER TABLE safety_check_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE safety_check_responses FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS safety_check_responses_property_scope ON safety_check_responses;
CREATE POLICY safety_check_responses_property_scope ON safety_check_responses
    USING (EXISTS (SELECT 1 FROM safety_checks s
                   WHERE s.id = safety_check_responses.check_id AND s.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM safety_checks s
                        WHERE s.id = safety_check_responses.check_id AND s.property_id = current_property_id()));

-- Tatbikat raporu ve afet durum kayıtları delildir: silinemez.
REVOKE DELETE, TRUNCATE ON emergency_drills FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON safety_checks FROM siteeksen_app;
REVOKE DELETE, TRUNCATE ON safety_check_responses FROM siteeksen_app;
-- resident_emergency_cards için DELETE AÇIK KALIR: rıza geri alınınca veri silinir (KVKK m.7).

COMMENT ON TABLE resident_emergency_cards IS 'Sakin acil bilgi kartı; özel nitelikli veri şifreli, açık rızaya dayalı (KVKK m.6) — 040';
COMMENT ON TABLE safety_checks IS 'Afet sonrası durum bildirimi çağrısı — 040';
