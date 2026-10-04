-- =====================================================
-- 043 — KVKK SAKLAMA VE PERİYODİK İMHA (FAZ 7.8)
--
-- Ziyaretçi adı/telefonu/kimlik no, araç plakaları, kargo alıcıları süresiz
-- saklanıyordu. KVKK m.7: işleme amacı ortadan kalkan veri silinir, yok edilir
-- ya da anonim hâle getirilir. Kişisel Verilerin Silinmesi, Yok Edilmesi veya
-- Anonim Hale Getirilmesi Hakkında Yönetmelik (RG 28/10/2017, 30224):
--   m.11/2 — periyodik imha aralığı ALTI AYI geçemez
--   m.7/3  — imha işlemleri kayıt altına alınır, kayıt en az ÜÇ YIL saklanır
--
-- Saklama SÜRESİNİ kanun bu kayıtlar için belirlemez; veri sorumlusu (site)
-- politikasında belirler → data_retention_rules (dayanak/gerekçe zorunlu).
-- Kural tanımlanmamış kategori imha EDİLMEZ (uydurma süre yok) ama zamanlayıcı
-- yönetimi uyarır. İmha = anonimleştirme: kayıt sayısı ve tarihleri (istatistik,
-- defter bütünlüğü) kalır, kişiyi belirleyen alanlar silinir.
-- =====================================================

INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, is_mandatory, description)
SELECT 'KVKK_PERIODIC_DESTRUCTION_MONTHS', 6, 'MONTH',
       'Kişisel Verilerin Silinmesi, Yok Edilmesi veya Anonim Hale Getirilmesi Hk. Yönetmelik (RG 28/10/2017, 30224) m.11/2 — '
       || 'periyodik imha süresi altı ayı geçemez',
       true, 'Periyodik imha işlemleri arasındaki en uzun süre'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'KVKK_PERIODIC_DESTRUCTION_MONTHS' AND property_id IS NULL);

CREATE TABLE IF NOT EXISTS data_retention_rules (
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    category         VARCHAR(20) NOT NULL CHECK (category IN ('VISITOR', 'PARKING_LOG', 'PACKAGE')),
    retention_months INT NOT NULL CHECK (retention_months BETWEEN 1 AND 120),
    justification    TEXT NOT NULL CHECK (length(trim(justification)) > 0),
    updated_by       UUID REFERENCES users(id),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (property_id, category)
);

CREATE TABLE IF NOT EXISTS data_destruction_log (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    category     VARCHAR(20) NOT NULL,
    method       VARCHAR(20) NOT NULL CHECK (method IN ('ANONYMIZE', 'DELETE')),
    cutoff       TIMESTAMPTZ NOT NULL,
    record_count INT NOT NULL CHECK (record_count >= 0),
    executed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    executed_by  VARCHAR(60) NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_data_destruction_log_property ON data_destruction_log(property_id, category, executed_at DESC);

ALTER TABLE data_retention_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_retention_rules FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS data_retention_rules_property_scope ON data_retention_rules;
CREATE POLICY data_retention_rules_property_scope ON data_retention_rules
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

ALTER TABLE data_destruction_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_destruction_log FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS data_destruction_log_property_scope ON data_destruction_log;
CREATE POLICY data_destruction_log_property_scope ON data_destruction_log
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());

-- İmha kaydı en az üç yıl saklanır (m.7/3): uygulama rolü değiştiremez, silemez.
REVOKE UPDATE, DELETE, TRUNCATE ON data_destruction_log FROM siteeksen_app;

COMMENT ON TABLE data_retention_rules IS 'Site saklama süreleri (KVKK m.7; politika) — 043';
COMMENT ON TABLE data_destruction_log IS 'Periyodik imha kaydı; en az 3 yıl (İmha Yönetmeliği m.7/3) — 043';
