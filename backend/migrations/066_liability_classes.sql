-- =====================================================
-- 066 — GİDER SINIFI: KULLANIM (oturan) / MALİK (altıncı tur D1; KMK m.20, m.22, m.42-43; TBK m.302, 317, 341)
--
-- Kullanıcı kararı (2026-10-11): her mali kalemde sınıf girişte seçilir ve uygulamadaki bütün mali
-- işler bu sınıfa uyar.
--   USAGE (KULLANIM) : daireyi kullananın gideri — kapıcı, temizlik, ısınma, ortak elektrik/su, bakım.
--                      Kira ilişkisinde kiracının yan gideridir (TBK m.317, m.341).
--   OWNER (MALİK)    : mülkiyetin gideri — demirbaş, yenilik, yeni tesis (havuz vb., KMK m.42-43), ana yapı
--                      onarımı/yenilemesi, zorunlu sigorta (TBK m.302). Oturan kim olursa olsun malikindir.
-- Siteye karşı borçlu her durumda malik, kiracı kira bedeliyle sınırlı müteselsil sorumlu (KMK m.20, m.22);
-- sınıf, kimin ekranında görüneceğini ve kimin ödeyeceğini belirler, kanuni sorumluluğu değiştirmez.
--
-- Bir bölüme aynı dönem için sınıf başına bir tahakkuk açılır (aynı ay KULLANIM + MALİK iki kayıt olabilir).
-- Mevcut kayıtlar KULLANIM sayılır (önceki modelde sınıf yoktu; hepsi tek aidattı).
-- =====================================================

DO $$
BEGIN
    -- Gider kategorisinin varsayılan sınıfı (girişte değiştirilebilir)
    ALTER TABLE expense_categories ADD COLUMN IF NOT EXISTS default_liability VARCHAR(10) NOT NULL DEFAULT 'USAGE';
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'expense_categories_liability_check') THEN
        ALTER TABLE expense_categories ADD CONSTRAINT expense_categories_liability_check CHECK (default_liability IN ('USAGE', 'OWNER'));
    END IF;

    ALTER TABLE expenses ADD COLUMN IF NOT EXISTS liability VARCHAR(10) NOT NULL DEFAULT 'USAGE';
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'expenses_liability_check') THEN
        ALTER TABLE expenses ADD CONSTRAINT expenses_liability_check CHECK (liability IN ('USAGE', 'OWNER'));
    END IF;

    ALTER TABLE operating_budget_items ADD COLUMN IF NOT EXISTS liability VARCHAR(10) NOT NULL DEFAULT 'USAGE';
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'operating_budget_items_liability_check') THEN
        ALTER TABLE operating_budget_items ADD CONSTRAINT operating_budget_items_liability_check CHECK (liability IN ('USAGE', 'OWNER'));
    END IF;

    -- İşletme projesinde bölüm payının sınıf dökümü (toplamı yıllık paya eşit)
    ALTER TABLE operating_budget_unit_shares ADD COLUMN IF NOT EXISTS annual_usage_kurus BIGINT;
    ALTER TABLE operating_budget_unit_shares ADD COLUMN IF NOT EXISTS annual_owner_kurus BIGINT NOT NULL DEFAULT 0;
    UPDATE operating_budget_unit_shares SET annual_usage_kurus = annual_kurus WHERE annual_usage_kurus IS NULL;
    ALTER TABLE operating_budget_unit_shares ALTER COLUMN annual_usage_kurus SET NOT NULL;
    ALTER TABLE operating_budget_unit_shares ALTER COLUMN annual_usage_kurus SET DEFAULT 0;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'operating_budget_unit_shares_liability_sum') THEN
        ALTER TABLE operating_budget_unit_shares ADD CONSTRAINT operating_budget_unit_shares_liability_sum
            CHECK (annual_usage_kurus >= 0 AND annual_owner_kurus >= 0 AND annual_usage_kurus + annual_owner_kurus = annual_kurus);
    END IF;

    ALTER TABLE assessment_details ADD COLUMN IF NOT EXISTS liability VARCHAR(10) NOT NULL DEFAULT 'USAGE';
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'assessment_details_liability_check') THEN
        ALTER TABLE assessment_details ADD CONSTRAINT assessment_details_liability_check CHECK (liability IN ('USAGE', 'OWNER'));
    END IF;

    ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS liability VARCHAR(10) NOT NULL DEFAULT 'USAGE';
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_assessments_liability_check') THEN
        ALTER TABLE monthly_assessments ADD CONSTRAINT monthly_assessments_liability_check CHECK (liability IN ('USAGE', 'OWNER'));
    END IF;
END $$;

-- Dönem benzersizliği sınıf bazında: aynı ay için bir KULLANIM ve bir MALİK tahakkuku olabilir.
DROP INDEX IF EXISTS uq_monthly_assessments_regular_period;
CREATE UNIQUE INDEX IF NOT EXISTS uq_monthly_assessments_regular_period
    ON monthly_assessments(unit_id, period_year, period_month, liability) WHERE kind = 'REGULAR';
DROP INDEX IF EXISTS uq_monthly_assessments_opening;
CREATE UNIQUE INDEX IF NOT EXISTS uq_monthly_assessments_opening
    ON monthly_assessments(unit_id, liability) WHERE kind = 'OPENING' AND deleted = 0;

-- Tahakkukun sınıfı sonradan değiştirilemez (kimin borcu olduğu ispat konusudur); 054 korumasına eklenir.
CREATE OR REPLACE FUNCTION monthly_assessments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF NEW.liability IS DISTINCT FROM OLD.liability THEN
        RAISE EXCEPTION 'Tahakkukun sınıfı (kullanım/malik) değiştirilemez; düzeltme alacak dekontu ve yeni tahakkukla yapılır'
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

-- Ortak (tüm sitelere açık) MALİK sınıfı kategoriler. Mevcut ortak kategoriler kullanım giderleridir.
INSERT INTO expense_categories (id, property_id, name, description, type, reflects_to_assessment, is_default, display_order,
                                distribution_type, default_liability)
VALUES
    ('10000000-0000-0000-0000-000000000101', NULL, 'Demirbaş Alımı', 'Ortak kullanım için demirbaş (malik gideri)', 'UNPLANNED', true, true, 101, 'SHARE_RATIO', 'OWNER'),
    ('10000000-0000-0000-0000-000000000102', NULL, 'Yenileme / Büyük Onarım', 'Çatı, cephe, asansör yenileme gibi ana yapı işleri (malik gideri)', 'UNPLANNED', true, true, 102, 'SHARE_RATIO', 'OWNER'),
    ('10000000-0000-0000-0000-000000000103', NULL, 'Yeni Tesis / Yenilik', 'Havuz, otopark gibi yeni tesis ve faydalı yenilik — KMK m.42-43 (malik gideri)', 'UNPLANNED', true, true, 103, 'SHARE_RATIO', 'OWNER')
ON CONFLICT (id) DO NOTHING;

COMMENT ON COLUMN monthly_assessments.liability IS 'USAGE: oturanın (kiracı/oturan malik) gideri; OWNER: malikin gideri (demirbaş, yenilik, yeni tesis) — 066';
COMMENT ON COLUMN expense_categories.default_liability IS 'Kategori seçilince önerilen sınıf; girişte değiştirilebilir — 066';
