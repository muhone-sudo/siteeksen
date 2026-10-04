-- =====================================================
-- 034 — AÇILIŞ (DEVİR) BAKİYESİ (FAZ 8.1)
--
-- SORUN: başka bir yönetimden/yazılımdan geçen site, dairelerin devreden
-- borçlarını sisteme girmenin hiçbir yolunu bulamıyordu. Tahakkuk tablosu
-- (unit, yıl, ay) benzersizdi; devir tutarı aynı ayın aidatıyla çakışırdı.
--
-- ÇÖZÜM: tahakkuka tür (REGULAR / OPENING) ve açıklama eklenir.
--   - Dönem benzersizliği yalnızca olağan tahakkuklar içindir.
--   - Her bölümün en çok bir etkin devir kaydı olur.
--   - Devir, bakiye, borçlu listesi ve ödeme akışına olağan borç gibi girer;
--     dönem tahsilat özetine girmez (bir döneme ait değildir) ve OTOMATİK
--     GECİKME TAZMİNATI İŞLETİLMEZ: önceki yönetimin tazminat hesabı bilinmez,
--     devir tutarına dahil olabilir; ayrıca işletmek çift tahsilat olurdu.
-- =====================================================

ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS kind VARCHAR(20) NOT NULL DEFAULT 'REGULAR';
ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS description TEXT;

DO $$
DECLARE
    c text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_assessments_kind_check') THEN
        ALTER TABLE monthly_assessments
            ADD CONSTRAINT monthly_assessments_kind_check CHECK (kind IN ('REGULAR', 'OPENING'));
    END IF;
    -- 001'deki UNIQUE(unit_id, period_year, period_month) kısıtının adı
    -- sürüme göre değişebileceği için kolonlarından bulunup kaldırılır.
    FOR c IN
        SELECT con.conname FROM pg_constraint con
        WHERE con.conrelid = 'monthly_assessments'::regclass AND con.contype = 'u'
          AND (SELECT array_agg(a.attname::text ORDER BY a.attname)
               FROM unnest(con.conkey) k JOIN pg_attribute a
                 ON a.attrelid = con.conrelid AND a.attnum = k)
              = ARRAY['period_month', 'period_year', 'unit_id']
    LOOP
        EXECUTE format('ALTER TABLE monthly_assessments DROP CONSTRAINT %I', c);
    END LOOP;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_monthly_assessments_regular_period
    ON monthly_assessments(unit_id, period_year, period_month) WHERE kind = 'REGULAR';
CREATE UNIQUE INDEX IF NOT EXISTS uq_monthly_assessments_opening
    ON monthly_assessments(unit_id) WHERE kind = 'OPENING' AND deleted = 0;

COMMENT ON COLUMN monthly_assessments.kind IS
    'REGULAR: dönem aidatı; OPENING: devreden (açılış) borç — dönem özetine girmez, otomatik gecikme tazminatı işletilmez (034).';
