-- =====================================================
-- 031 — DAİRE BAĞININ ROLÜ YALNIZCA SAKİNLİK ROLÜ OLABİLİR
--
-- SORUN (YETKİ YÜKSELTME): `resident_units.role` jeton rollerine olduğu gibi
-- girer (kimlik servisi, GetPropertyRoles). Kolonda kısıt yoktu ve uygulama da
-- değeri doğrulamıyordu: sakin yazma yetkisi olan yönetim kurulu üyesi kendi
-- hesabını 'MANAGER' rolüyle bir daireye bağlayıp yönetici olabiliyordu;
-- yönetim rolleri ise yalnızca property_roles'ta, atama izi (KMK m.34) ile
-- verilmelidir.
--
-- ÇÖZÜM: kısıt yeni yazımları hemen engeller (NOT VALID). Mevcut satırlar
-- uygunsa kısıt doğrulanır; uygun olmayan satır varsa SİLİNMEZ ya da
-- değiştirilmez (hangi değere çevrileceği bilinemez) — uyarı verilir ve
-- kimlik servisi bu satırlardan rol türetmez. Doğrulama sayımı denetler.
-- =====================================================

ALTER TABLE resident_units DROP CONSTRAINT IF EXISTS resident_units_role_check;
ALTER TABLE resident_units ADD CONSTRAINT resident_units_role_check
    CHECK (role IN ('OWNER', 'TENANT', 'PROXY')) NOT VALID;

DO $$
DECLARE
    bad integer;
BEGIN
    SELECT count(*) INTO bad FROM resident_units
    WHERE role NOT IN ('OWNER', 'TENANT', 'PROXY');
    IF bad = 0 THEN
        ALTER TABLE resident_units VALIDATE CONSTRAINT resident_units_role_check;
    ELSE
        RAISE WARNING '031: % daire bağının rolü sakinlik rolü değil; elle incelenmeli (yetki vermezler)', bad;
    END IF;
END $$;

COMMENT ON CONSTRAINT resident_units_role_check ON resident_units IS
    'Yönetim rolleri yalnızca property_roles üzerinden verilir (031, yetki yükseltme düzeltmesi).';
