-- =====================================================
-- 063 — FATURA SAPMA UYARISI VE TÜKETİM PUSULASINA İTİRAZ (beşinci tur B8, Şikayetvar "payölçer / absürt fatura")
--
-- 1) Paylaştırma yayımlanırken kullanım alanı başına tüketimi site medyanının 3 katını aşan
--    bölüm varsa yönetici bunu görür ve teyit etmeden yayımlayamaz. Teyit eden ve hangi bölümler
--    olduğu pusulayla birlikte saklanır.
-- 2) Sakin kendi bölümünün pusulasına gerekçeli itiraz eder; yönetim yanıtlar (kabul/ret ve
--    açıklama). Yayımlanmış pusula DEĞİŞMEZ (056); kabul edilen itirazda düzeltme yönetimin
--    açıklamasındaki yolla (yeniden okuma, alacak dekontu vb.) yapılır. Kayıt silinemez.
-- =====================================================

ALTER TABLE consumption_allocations ADD COLUMN IF NOT EXISTS outliers_confirmed_by UUID REFERENCES users(id);
ALTER TABLE consumption_allocations ADD COLUMN IF NOT EXISTS outlier_units JSONB;
COMMENT ON COLUMN consumption_allocations.outlier_units IS 'Yayımda site medyanının 3 katını aşan bölümler [{unit_id,unit_name,ratio}] ve teyit eden — 063';

CREATE TABLE IF NOT EXISTS consumption_statement_objections (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    allocation_id UUID NOT NULL REFERENCES consumption_allocations(id) ON DELETE CASCADE,
    unit_id       UUID NOT NULL REFERENCES units(id),
    user_id       UUID NOT NULL REFERENCES users(id),
    reason        TEXT NOT NULL CHECK (length(trim(reason)) >= 10),
    status        VARCHAR(10) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'ACCEPTED', 'REJECTED')),
    response      TEXT,
    responded_by  UUID REFERENCES users(id),
    responded_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (status = 'OPEN' OR (responded_at IS NOT NULL AND length(trim(COALESCE(response, ''))) >= 5))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_statement_objection_open
    ON consumption_statement_objections (allocation_id, unit_id) WHERE status = 'OPEN';
CREATE INDEX IF NOT EXISTS idx_statement_objections_property ON consumption_statement_objections (property_id, status);

ALTER TABLE consumption_statement_objections ENABLE ROW LEVEL SECURITY;
ALTER TABLE consumption_statement_objections FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS consumption_statement_objections_property_scope ON consumption_statement_objections;
CREATE POLICY consumption_statement_objections_property_scope ON consumption_statement_objections
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE DELETE, TRUNCATE ON consumption_statement_objections FROM siteeksen_app;

-- Yanıtlanmış itiraz değiştirilemez; açık itirazda yalnızca yanıt alanları yazılabilir.
CREATE OR REPLACE FUNCTION consumption_statement_objections_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF OLD.status <> 'OPEN' THEN
        RAISE EXCEPTION 'Yanıtlanmış itiraz değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.reason <> OLD.reason OR NEW.user_id <> OLD.user_id OR NEW.unit_id <> OLD.unit_id
       OR NEW.allocation_id <> OLD.allocation_id OR NEW.created_at <> OLD.created_at THEN
        RAISE EXCEPTION 'İtirazın gerekçesi, sahibi ve tarihi değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS consumption_statement_objections_guard ON consumption_statement_objections;
CREATE TRIGGER consumption_statement_objections_guard BEFORE UPDATE ON consumption_statement_objections
    FOR EACH ROW EXECUTE FUNCTION consumption_statement_objections_guard();

COMMENT ON TABLE consumption_statement_objections IS 'Tüketim pusulasına sakin itirazı ve yönetim yanıtı; silinemez, yanıttan sonra değişmez — 063';
