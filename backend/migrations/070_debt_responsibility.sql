-- =====================================================
-- 070 — BORCUN SORUMLUSU (altıncı tur D5; KMK m.20, m.22; TBK m.317, m.341)
--
-- Kullanıcı kararı (2026-10-11): uygulamadaki bütün mali işler gider sınıfına (066) uyar. Kararlar:
--   V3 Malik kaydı olmayan dairede MALİK sınıfı borç yönetimde "malik kaydı yok" ile bekler; kiracıya yansımaz.
--   V4 Hane üyesi mali ekranları görmez.
--   V6 Borcun sorumlusu tahakkuk anında saptanır (sınıf + o günkü oturan); kiracılık bitince açık KULLANIM borcu
--      malike de görünür (KMK m.20: siteye karşı asıl borçlu malik).
--
-- Model: KULLANIM sınıfı borç, dairede aktif kiracı varken tahakkuk ettiyse o KİRACILIĞA (resident_units satırı)
-- bağlanır (`tenant_link_id`). Kural tek işlevde: `assessment_visible_to(tahakkuk, kişi)`.
--   - kiracı: yalnız kendi kiracılığına bağlı borç,
--   - malik / vekil: malik sınıfı + kiracılığa bağlı olmayan kullanım borcu + kiracılığı bitmiş borç (V6),
--   - hane üyesi: hiçbiri.
-- Bağ tahakkuk anında veritabanında kurulur (her tahakkuk yolu: elle, işletme projesi, devir, düzeltme) ve
-- sonradan değiştirilemez (054/066 korumasına eklenir).
-- =====================================================

ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS tenant_link_id UUID REFERENCES resident_units(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_monthly_assessments_tenant_link ON monthly_assessments(tenant_link_id) WHERE tenant_link_id IS NOT NULL;
COMMENT ON COLUMN monthly_assessments.tenant_link_id IS
    'KULLANIM borcu kiracılıkta tahakkuk ettiyse o kiracılık (resident_units); borcun sorumlusu — 070 (V6)';

-- Eski veri (V5): dönemi kiracılık başlangıcından sonra olan kullanım borcu dairenin şu anki aktif kiracısına bağlanır.
UPDATE monthly_assessments ma SET tenant_link_id = ru.id
FROM resident_units ru
WHERE ma.tenant_link_id IS NULL AND ma.liability = 'USAGE'
  AND ru.unit_id = ma.unit_id AND ru.role = 'TENANT' AND ru.is_active
  AND ru.start_date < (make_date(ma.period_year, ma.period_month, 1) + interval '1 month');

-- Tahakkuk anında sorumlu kiracılık saptanır.
CREATE OR REPLACE FUNCTION monthly_assessments_tenant_link() RETURNS trigger AS $$
BEGIN
    IF NEW.tenant_link_id IS NULL AND COALESCE(NEW.liability, 'USAGE') = 'USAGE' THEN
        SELECT ru.id INTO NEW.tenant_link_id FROM resident_units ru
        WHERE ru.unit_id = NEW.unit_id AND ru.role = 'TENANT' AND ru.is_active
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_monthly_assessments_tenant_link ON monthly_assessments;
CREATE TRIGGER trg_monthly_assessments_tenant_link
    BEFORE INSERT ON monthly_assessments
    FOR EACH ROW EXECUTE FUNCTION monthly_assessments_tenant_link();

-- Sınıf ve sorumlu sonradan değiştirilemez (uygulama rolü); 066 korumasının üstüne.
CREATE OR REPLACE FUNCTION monthly_assessments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF NEW.liability IS DISTINCT FROM OLD.liability THEN
        RAISE EXCEPTION 'Tahakkukun sınıfı (kullanım/malik) değiştirilemez; düzeltme alacak dekontu ve yeni tahakkukla yapılır'
            USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.tenant_link_id IS DISTINCT FROM OLD.tenant_link_id THEN
        RAISE EXCEPTION 'Borcun sorumlusu (kiracılık) tahakkuktan sonra değiştirilemez'
            USING ERRCODE = 'check_violation';
    END IF;
    IF COALESCE(OLD.paid_amount, 0) > 0 THEN
        IF NEW.base_amount <> OLD.base_amount THEN
            RAISE EXCEPTION 'Ödeme almış tahakkukun anaparası değiştirilemez; düzeltme alacak dekontuyla yapılır'
                USING ERRCODE = 'check_violation';
        END IF;
        IF NEW.deleted <> OLD.deleted THEN
            RAISE EXCEPTION 'Ödeme almış tahakkuk silinemez' USING ERRCODE = 'check_violation';
        END IF;
    END IF;
    IF COALESCE(NEW.paid_amount, 0) < COALESCE(OLD.paid_amount, 0)
       AND COALESCE(current_setting('siteeksen.reversal', true), '') <> 'on' THEN
        RAISE EXCEPTION 'Ödenen tutar azaltılamaz; yalnızca ödemenin ters kaydı yapılabilir'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Borcu kim görür / öder (tek kural). SECURITY INVOKER: çağıranın RLS kapsamında çalışır.
CREATE OR REPLACE FUNCTION assessment_visible_to(p_assessment uuid, p_user uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
    SELECT EXISTS (
        SELECT 1
        FROM monthly_assessments ma
        JOIN resident_units ru ON ru.unit_id = ma.unit_id AND ru.resident_id = p_user AND ru.is_active
        LEFT JOIN resident_units t ON t.id = ma.tenant_link_id
        WHERE ma.id = p_assessment
          AND CASE ru.role
                  WHEN 'TENANT' THEN ma.tenant_link_id = ru.id
                  WHEN 'OWNER' THEN NOT COALESCE(t.is_active, false)
                  WHEN 'PROXY' THEN NOT COALESCE(t.is_active, false)
                  ELSE false
              END)
$$;
COMMENT ON FUNCTION assessment_visible_to(uuid, uuid) IS
    'Kiracı kendi kiracılığının borcunu; malik/vekil malik sınıfını, kiracılığa bağlı olmayanı ve kiracılığı bitmişi görür; hane üyesi hiç (070)';

-- Borcun sorumlusu: aktif kiracılığa bağlıysa TENANT, değilse OWNER (malik yoksa yönetimde bekler — V3).
CREATE OR REPLACE FUNCTION assessment_responsible(p_assessment uuid) RETURNS text
LANGUAGE sql STABLE AS $$
    SELECT CASE WHEN COALESCE(t.is_active, false) THEN 'TENANT' ELSE 'OWNER' END
    FROM monthly_assessments ma LEFT JOIN resident_units t ON t.id = ma.tenant_link_id
    WHERE ma.id = p_assessment
$$;

GRANT EXECUTE ON FUNCTION assessment_visible_to(uuid, uuid), assessment_responsible(uuid) TO siteeksen_app;

-- Borcu yoktur belgesinin kapsamı: malik/yönetim bütün daireyi; kiracı yalnız kendi kiracılığının kullanım borcunu.
ALTER TABLE clearance_certificates ADD COLUMN IF NOT EXISTS scope VARCHAR(10) NOT NULL DEFAULT 'UNIT';
ALTER TABLE clearance_certificates ADD COLUMN IF NOT EXISTS tenant_link_id UUID REFERENCES resident_units(id) ON DELETE SET NULL;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'clearance_certificates_scope_check') THEN
        ALTER TABLE clearance_certificates ADD CONSTRAINT clearance_certificates_scope_check
            CHECK (scope IN ('UNIT', 'TENANCY'));
    END IF;
END $$;
COMMENT ON COLUMN clearance_certificates.scope IS 'UNIT: bölümün bütün borcu; TENANCY: kiracılık dönemi kullanım borcu (070)';

-- Kimliksiz doğrulama kapsamı da söyler (kişi adı/tutar yine dönmez — 055 ilkesi). 055'teki işlevin dönüş tipi
-- değiştirilmez (migration'lar yeniden uygulanabilir kalmalı); kapsamlı sürüm ayrı işlevdir.
CREATE OR REPLACE FUNCTION verify_clearance_certificate_scoped(p_code text)
RETURNS TABLE (property_name text, unit_label text, as_of_date date, issued_at timestamptz, expires_at date, scope text)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT p.name::text, (COALESCE(u.block, '') || '-' || u.door_number)::text, c.as_of_date, c.issued_at, c.expires_at, c.scope::text
    FROM clearance_certificates c
    JOIN properties p ON p.id = c.property_id
    JOIN units u ON u.id = c.unit_id
    WHERE c.verification_code = lower(p_code)
$$;
REVOKE ALL ON FUNCTION verify_clearance_certificate_scoped(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION verify_clearance_certificate_scoped(text) TO siteeksen_app;