-- =====================================================
-- 033 — SİTE KURUCUSU: SAHTE "YÖNETİM" BÖLÜMÜ YERİNE YÖNETİCİ ROLÜ
--
-- SORUN: site oluşturma (POST /users/me/properties) kurucuyu sahte bir
-- bağımsız bölüme (blok A, kapı 'YÖNETİM', arsa payı 0, OFFICE) MALİK olarak
-- bağlıyordu. Kurucunun yönetim rolü olmadığı için yeni site yönetilemiyordu;
-- sahte bölüm de eşit dağıtılan giderlerden pay alıyor, daire sayısını
-- şişiriyordu. Kod düzeltildi (kurucu property_roles'ta MANAGER olur); bu
-- migration önceden açılmış sitelerdeki izleri aynı duruma getirir.
--
-- NE YAPAR (yalnızca bu desene birebir uyan bölümler için):
--   1. Bölüme bağlı aktif malike, yoksa MANAGER rolü verilir (atama izi:
--      granted_by = kendisi, decision_ref bu migration).
--   2. Sahte bağ pasifleştirilir (silinmez: geçmiş korunur).
--   3. Bölüm silinmiş olarak işaretlenir (deleted = 1); tahakkukta yer almaz.
-- Sahte bölüme daha önce yazılmış tahakkuk varsa SİLİNMEZ; sayısı uyarıyla
-- bildirilir ve yönetimin incelemesi gerekir.
-- =====================================================

DO $$
DECLARE
    fake_count integer;
    charged integer;
BEGIN
    CREATE TEMP TABLE fake_units ON COMMIT DROP AS
        SELECT id, property_id FROM units
        WHERE door_number = 'YÖNETİM' AND share_ratio = 0
          AND unit_type = 'OFFICE' AND block = 'A' AND deleted = 0;
    SELECT count(*) INTO fake_count FROM fake_units;
    IF fake_count = 0 THEN
        RETURN;
    END IF;

    INSERT INTO property_roles (user_id, property_id, role, granted_by, decision_ref)
    SELECT DISTINCT ru.resident_id, f.property_id, 'MANAGER', ru.resident_id,
           'Site kurulumu (033): kurucu geçici yönetici — KMK m.34 uyarınca kat malikleri kurulu kararıyla teyit edilmeli'
    FROM fake_units f
    JOIN resident_units ru ON ru.unit_id = f.id AND ru.is_active AND ru.role = 'OWNER'
    WHERE NOT EXISTS (
        SELECT 1 FROM property_roles pr
        WHERE pr.user_id = ru.resident_id AND pr.property_id = f.property_id
          AND pr.role = 'MANAGER' AND pr.is_active);

    UPDATE resident_units SET is_active = false, end_date = CURRENT_DATE
    WHERE unit_id IN (SELECT id FROM fake_units) AND is_active;

    UPDATE units SET deleted = 1, updated_at = NOW() WHERE id IN (SELECT id FROM fake_units);

    SELECT count(*) INTO charged FROM monthly_assessments
    WHERE unit_id IN (SELECT id FROM fake_units) AND deleted = 0;
    RAISE NOTICE '033: % sahte YÖNETİM bölümü dönüştürüldü', fake_count;
    IF charged > 0 THEN
        RAISE WARNING '033: sahte bölümlere yazılmış % tahakkuk var; silinmedi, yönetim incelemeli', charged;
    END IF;
END $$;
