-- =====================================================
-- 058 — SİTE YAŞAM DÖNGÜSÜ: PASİFLEŞTİRME (Apsiyon BUG-11)
--
-- Site yönetimi hizmeti bıraktıktan sonra sistem sakinlere her ay "hayali" aidat borcu
-- yazmaya ve bildirim göndermeye devam ediyordu. Burada site pasife alınınca:
--   * yeni tahakkuk (monthly_assessments), gecikme tazminatı (late_fee_accruals) ve
--     bildirim (notifications) satırı YAZILAMAZ — kod yolu ne olursa olsun, tetikleyiciyle
--     (fail-closed). Zamanlayıcı ve cihaz bekçisi pasif siteyi zaten taramaz (028, 057).
--   * Okuma sürer: sakinler geçmiş borç/ödeme kayıtlarını görebilir (KVKK m.11 erişim hakkı,
--     VUK saklama süreleri); veriler silinmez.
-- Pasifleştirme ve yeniden etkinleştirme gerekçeli ve silinemez olay olarak saklanır.
-- =====================================================

UPDATE properties SET is_active = true WHERE is_active IS NULL;
ALTER TABLE properties ALTER COLUMN is_active SET DEFAULT true;
ALTER TABLE properties ALTER COLUMN is_active SET NOT NULL;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ;
ALTER TABLE properties ADD COLUMN IF NOT EXISTS deactivation_reason TEXT;

CREATE TABLE IF NOT EXISTS property_lifecycle_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    action       VARCHAR(20) NOT NULL CHECK (action IN ('DEACTIVATED','REACTIVATED')),
    reason       TEXT NOT NULL CHECK (length(trim(reason)) >= 5),
    actor_id     UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_property_lifecycle_property ON property_lifecycle_events(property_id, created_at DESC);
ALTER TABLE property_lifecycle_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_lifecycle_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS property_lifecycle_events_property_scope ON property_lifecycle_events;
CREATE POLICY property_lifecycle_events_property_scope ON property_lifecycle_events
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS property_lifecycle_events_identity_all ON property_lifecycle_events;
CREATE POLICY property_lifecycle_events_identity_all ON property_lifecycle_events TO siteeksen_identity
    USING (true) WITH CHECK (true);
GRANT SELECT, INSERT ON property_lifecycle_events TO siteeksen_identity;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON property_lifecycle_events FROM siteeksen_app;
REVOKE UPDATE, DELETE, TRUNCATE ON property_lifecycle_events FROM siteeksen_identity;

-- Site etkin mi? (yalnızca mantıksal değer döner; tetikleyici çağıranın RLS kapsamından bağımsız çalışır)
CREATE OR REPLACE FUNCTION property_is_active(p uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COALESCE((SELECT is_active FROM properties WHERE id = p), false)
$$;
REVOKE ALL ON FUNCTION property_is_active(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION property_is_active(uuid) TO siteeksen_app, siteeksen_identity;

-- Pasif sitede yeni borç ve bildirim yazılamaz. SQLSTATE SE001: servisler 409'a çevirir.
CREATE OR REPLACE FUNCTION forbid_inactive_property()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF NEW.property_id IS NOT NULL AND NOT property_is_active(NEW.property_id) THEN
        RAISE EXCEPTION 'site pasif: % tablosuna yeni kayıt yazılamaz', TG_TABLE_NAME
            USING ERRCODE = 'SE001',
                  HINT = 'Site pasife alındığında tahakkuk, gecikme tazminatı ve bildirim üretilmez (Apsiyon BUG-11).';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS monthly_assessments_active_property ON monthly_assessments;
CREATE TRIGGER monthly_assessments_active_property BEFORE INSERT ON monthly_assessments
    FOR EACH ROW EXECUTE FUNCTION forbid_inactive_property();
-- late_fee_accruals site sütunu taşımaz; site tahakkuktan bulunur.
CREATE OR REPLACE FUNCTION forbid_inactive_property_late_fee()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    p uuid;
BEGIN
    SELECT property_id INTO p FROM monthly_assessments WHERE id = NEW.assessment_id;
    IF p IS NOT NULL AND NOT property_is_active(p) THEN
        RAISE EXCEPTION 'site pasif: gecikme tazminatı işletilemez'
            USING ERRCODE = 'SE001',
                  HINT = 'Site pasife alındığında tahakkuk, gecikme tazminatı ve bildirim üretilmez (Apsiyon BUG-11).';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS late_fee_accruals_active_property ON late_fee_accruals;
CREATE TRIGGER late_fee_accruals_active_property BEFORE INSERT ON late_fee_accruals
    FOR EACH ROW EXECUTE FUNCTION forbid_inactive_property_late_fee();
-- Var olan tahakkukta borç ARTIRILAMAZ (gecikme tazminatı tahakkuka yazılarak da işler);
-- azaltma (valör, ödeme, ters kayıt) serbesttir — pasif sitede de borç düşebilmeli.
CREATE OR REPLACE FUNCTION forbid_inactive_property_increase()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
    IF (COALESCE(NEW.total_amount, 0) > COALESCE(OLD.total_amount, 0) OR COALESCE(NEW.late_fee, 0) > COALESCE(OLD.late_fee, 0))
       AND NOT property_is_active(NEW.property_id) THEN
        RAISE EXCEPTION 'site pasif: tahakkuk tutarı artırılamaz'
            USING ERRCODE = 'SE001',
                  HINT = 'Site pasife alındığında tahakkuk, gecikme tazminatı ve bildirim üretilmez (Apsiyon BUG-11).';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS monthly_assessments_active_property_increase ON monthly_assessments;
CREATE TRIGGER monthly_assessments_active_property_increase BEFORE UPDATE OF total_amount, late_fee ON monthly_assessments
    FOR EACH ROW EXECUTE FUNCTION forbid_inactive_property_increase();
DROP TRIGGER IF EXISTS notifications_active_property ON notifications;
CREATE TRIGGER notifications_active_property BEFORE INSERT ON notifications
    FOR EACH ROW EXECUTE FUNCTION forbid_inactive_property();

COMMENT ON TABLE property_lifecycle_events IS 'Site pasifleştirme/yeniden etkinleştirme olayları; silinemez (Apsiyon BUG-11) — 058';
