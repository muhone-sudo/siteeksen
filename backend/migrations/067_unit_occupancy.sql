-- =====================================================
-- 067 — DAİRE OTURUM MODELİ (altıncı tur D2; KMK m.20, m.22)
--
-- Kullanıcı kararı (2026-10-11): daire boş olabilir ama maliki kayıtlı olmalıdır; boş dairede her şey malike
-- düşer. Kiracı oturuyorsa kullanım işlemlerini kiracı (ve hanesi) yapar; devirden sonra malik kullanım
-- işlemi yapmaz. Bunun için "dairede kim oturuyor" sorusunun TEK yerde cevabı gerekir.
--
-- Oturum durumu saklanmaz, kayıtlardan HESAPLANIR (iki kaynak birbirinden kopamaz):
--   TENANT_OCCUPIED : dairede aktif kiracı var (maliki kayıtlı olmayabilir — yönetim malikten önce kiracıyı
--                     kaydedebilir; o durumda "malik kaydı yok" uyarısı verilir)
--   OWNER_OCCUPIED  : kiracı yok, aktif malik var ve malik oturuyor (units.owner_occupied)
--   VACANT          : kiracı yok, aktif malik var, daire boş — boş daire maliksiz olamaz
--   UNREGISTERED    : dairede aktif malik de kiracı da yok
-- `units.owner_occupied` yalnız kiracısız dairede anlam taşır; mevcut veride malik oturuyor sayılır (V5).
--
-- HOUSEHOLD (hane üyesi): oturanın hanesi. Rol burada yalnız şemaya açılır; ekleme akışı ve yetkileri D3/D7'de.
-- Hane üyesi jeton rolü üretmez (identity yalnız OWNER/TENANT/PROXY'den rol türetir) — mali ekran göremez (V4).
-- =====================================================

ALTER TABLE units ADD COLUMN IF NOT EXISTS owner_occupied BOOLEAN NOT NULL DEFAULT true;
COMMENT ON COLUMN units.owner_occupied IS
    'Kiracısız dairede malik oturuyor mu (false: daire boş). Kiracı varken anlamı yoktur — 067';

ALTER TABLE resident_units DROP CONSTRAINT IF EXISTS resident_units_role_check;
ALTER TABLE resident_units ADD CONSTRAINT resident_units_role_check
    CHECK (role IN ('OWNER', 'TENANT', 'PROXY', 'HOUSEHOLD')) NOT VALID;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM resident_units WHERE role NOT IN ('OWNER', 'TENANT', 'PROXY', 'HOUSEHOLD')) THEN
        ALTER TABLE resident_units VALIDATE CONSTRAINT resident_units_role_check;
    ELSE
        RAISE WARNING '067: sakinlik rolü dışında rol taşıyan daire bağı var; elle incelenmeli (yetki vermezler)';
    END IF;
END $$;
COMMENT ON CONSTRAINT resident_units_role_check ON resident_units IS
    'Yönetim rolleri yalnızca property_roles üzerinden verilir (031); HOUSEHOLD hane üyesidir (067).';

-- Dairenin oturum durumu. SECURITY INVOKER (varsayılan): çağıranın RLS kapsamında çalışır.
CREATE OR REPLACE FUNCTION unit_occupancy(p_unit uuid) RETURNS text
LANGUAGE sql STABLE AS $$
    SELECT CASE
        WHEN EXISTS (SELECT 1 FROM resident_units r WHERE r.unit_id = p_unit AND r.is_active AND r.role = 'TENANT')
            THEN 'TENANT_OCCUPIED'
        WHEN NOT EXISTS (SELECT 1 FROM resident_units r WHERE r.unit_id = p_unit AND r.is_active AND r.role = 'OWNER')
            THEN 'UNREGISTERED'
        WHEN (SELECT u.owner_occupied FROM units u WHERE u.id = p_unit)
            THEN 'OWNER_OCCUPIED'
        ELSE 'VACANT'
    END
$$;
COMMENT ON FUNCTION unit_occupancy(uuid) IS
    'TENANT_OCCUPIED | OWNER_OCCUPIED | VACANT | UNREGISTERED — kayıtlardan hesaplanır, saklanmaz (067)';

-- Daire bağının sahibi o dairede OTURAN tarafta mı (kullanım işlemleri ona ve hanesine aittir).
-- Kiracı oturur; kiracı yokken malik oturuyorsa malik oturur; hane üyesi oturanın hanesidir; vekil oturmaz.
CREATE OR REPLACE FUNCTION resident_is_occupant(p_resident_unit uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
    SELECT COALESCE((
        SELECT ru.is_active AND CASE ru.role
            WHEN 'TENANT' THEN true
            WHEN 'HOUSEHOLD' THEN true
            WHEN 'OWNER' THEN unit_occupancy(ru.unit_id) = 'OWNER_OCCUPIED'
            ELSE false
        END
        FROM resident_units ru WHERE ru.id = p_resident_unit), false)
$$;
COMMENT ON FUNCTION resident_is_occupant(uuid) IS
    'Kiracı ve hane üyesi oturur; kiracısız ve malik oturan dairede malik oturur; vekil oturmaz (067)';

GRANT EXECUTE ON FUNCTION unit_occupancy(uuid), resident_is_occupant(uuid) TO siteeksen_app, siteeksen_identity;
