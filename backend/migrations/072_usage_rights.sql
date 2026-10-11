-- =====================================================
-- 072 — KULLANIM HAKKI (altıncı tur D7; KMK m.18-19, TBK m.301)
--
-- Kullanıcı kararı (2026-10-11): devirden sonra malik o dairede kullanım işlemi (talep, rezervasyon, ziyaretçi, kargo,
-- otopark, acil durum kartı/yanıtı, sayaç/pusula/itiraz) yapmaz; bunlar oturanın ve hanesinin hakkıdır.
-- Kural: kiracı ve hane üyesi kullanır; malik ve vekil ancak dairede aktif kiracı YOKSA (malik oturuyor ya da boş —
-- boş dairede her şey malike düşer) kullanır. Kurallar kiracının kiralananı kullanma hakkından gelir (TBK m.301).
--
-- Kapsam dışı (bilerek): ilan panosu (malik "satılık/kiralık" ilanı verebilir), anket/NPS (anket malik oyuna göre de
-- sayılabilir — survey servisi ayırır), tadilat izni (malik/vekil başvurur; kiracının tadilatı malik iznine bağlıdır —
-- TBK m.321), kural ihlali bildirimleri (malik de muhataptır).
-- =====================================================

CREATE OR REPLACE FUNCTION resident_can_use(p_resident_unit uuid) RETURNS boolean
LANGUAGE sql STABLE AS $$
    SELECT COALESCE((
        SELECT COALESCE(ru.is_active, false) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE) AND CASE ru.role
            WHEN 'TENANT' THEN true
            WHEN 'HOUSEHOLD' THEN true
            WHEN 'OWNER' THEN unit_occupancy(ru.unit_id) <> 'TENANT_OCCUPIED'
            WHEN 'PROXY' THEN unit_occupancy(ru.unit_id) <> 'TENANT_OCCUPIED'
            ELSE false
        END
        FROM resident_units ru WHERE ru.id = p_resident_unit), false)
$$;
COMMENT ON FUNCTION resident_can_use(uuid) IS
    'Kullanım işlemi hakkı: kiracı ve hane üyesi; malik/vekil yalnız dairede aktif kiracı yokken (072)';
GRANT EXECUTE ON FUNCTION resident_can_use(uuid) TO siteeksen_app, siteeksen_identity;
