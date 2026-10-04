-- =====================================================
-- 049 — NET KULLANIM ALANI (TEST_RAPORU 2.2)
--
-- Merkezi ısıtma giderinin sabit payı (%30) bağımsız bölümlerin KAPALI KULLANIM
-- ALANINA göre dağıtılır (Isınma ve Sıhhi Sıcak Su Giderlerinin Paylaştırılmasına
-- İlişkin Yönetmelik m.3 "A: bağımsız bölümün kapalı kullanım alanı", m.8/1).
-- Paylaştırma `units.net_area_m2` kullanır; ama bölüm ekleme/düzenleme bu alanı hiç
-- almıyordu → ısı paylaştırması her sitede 422 ile duruyordu. Kimlik servisi artık
-- alanı alır (daire/dükkân/ofiste zorunlu). Bu migration:
--   * negatif/sıfır alanı ve brütten büyük neti veritabanında da reddeder
--   * demo sitedeki bölümlere (yalnızca SEED_DEMO_DATA açıkken) örnek alan yazar
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'units_area_rules') THEN
        ALTER TABLE units ADD CONSTRAINT units_area_rules CHECK (
            (net_area_m2 IS NULL OR net_area_m2 > 0)
            AND (gross_area_m2 IS NULL OR gross_area_m2 >= 0)
            AND (net_area_m2 IS NULL OR gross_area_m2 IS NULL OR gross_area_m2 = 0 OR net_area_m2 <= gross_area_m2)
        ) NOT VALID;
    END IF;
END $$;

COMMENT ON COLUMN units.net_area_m2 IS
    'Kapalı (net) kullanım alanı; merkezi ısıtmada sabit pay buna göre dağıtılır (Yön. m.3, m.8) — 049';

DO $seed$
BEGIN
    IF COALESCE(current_setting('siteeksen.seed_demo_data', true), 'true') <> 'true' THEN
        RETURN;
    END IF;
    -- Demo: brüt alanın %85'i (brüt yoksa arsa payıyla orantılı) örnek net alan.
    UPDATE units
    SET net_area_m2 = CASE WHEN COALESCE(gross_area_m2, 0) > 0 THEN round(gross_area_m2 * 0.85, 2)
                           ELSE round(share_ratio * 0.2, 2) END
    WHERE property_id = '11111111-1111-1111-1111-111111111111'
      AND net_area_m2 IS NULL AND share_ratio > 0
      AND COALESCE(unit_type, 'APARTMENT') IN ('APARTMENT', 'SHOP', 'OFFICE');
END $seed$;
