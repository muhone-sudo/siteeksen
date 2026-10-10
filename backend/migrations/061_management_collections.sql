-- =====================================================
-- 061 — YÖNETİMİN TAHSİLAT GİRİŞİ (beşinci tur B2, Şikayetvar "ödedim, borç silinmedi")
--
-- Önceden ödeme kaydını yalnızca sakin, kendi borcu için açabiliyordu: sakin uygulamadan
-- bildirim yapmadan havale gönderdiyse ya da yönetime elden ödediyse, yönetici bu parayı
-- daireye işleyemiyordu. Banka ekstresinde eşleşmeyen satır da bir ödemeye bağlanmadan
-- kapanamıyordu; borç açık kalıyordu.
--
-- Yönetim artık tahsilatı kendisi girer: ödeme `recorded_by` (giren yönetici) ile açılır,
-- AYNI işlemde onaylanır ve tahsilat defterine (054) yazılır. Ödeyen kişi bilinmeyebilir;
-- `user_id` boş kalır, ödeme bölüme (`unit_id`) bağlıdır.
-- =====================================================

ALTER TABLE payments ADD COLUMN IF NOT EXISTS recorded_by UUID REFERENCES users(id);
COMMENT ON COLUMN payments.recorded_by IS 'Tahsilatı giren yönetici (sakin bildirimi değil); boşsa ödeme sakinin bildirimidir — 061';

-- Kimin girdiği de ispat konusudur: sonradan değiştirilemez (054 korumasına eklenir).
CREATE OR REPLACE FUNCTION payments_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF NEW.deleted IS DISTINCT FROM OLD.deleted AND OLD.status IN ('COMPLETED', 'REVERSED') THEN
        RAISE EXCEPTION 'Sonuçlanmış ödeme silinemez' USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.amount <> OLD.amount OR NEW.user_id IS DISTINCT FROM OLD.user_id
       OR NEW.property_id IS DISTINCT FROM OLD.property_id OR NEW.created_at <> OLD.created_at
       OR NEW.recorded_by IS DISTINCT FROM OLD.recorded_by THEN
        RAISE EXCEPTION 'Ödeme kaydının tutarı, sahibi, giren kişi ve tarihi değiştirilemez; düzeltme ters kayıtla yapılır'
            USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.value_date IS NOT NULL AND NEW.value_date IS DISTINCT FROM OLD.value_date THEN
        RAISE EXCEPTION 'Beyan edilen ödeme (valör) tarihi değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.status <> 'PENDING' AND NEW.status <> OLD.status
       AND NOT (OLD.status = 'COMPLETED' AND NEW.status = 'REVERSED') THEN
        RAISE EXCEPTION 'Sonuçlanmış ödemenin durumu değiştirilemez (% → %); yalnızca ters kayıt yapılabilir',
            OLD.status, NEW.status USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.status = 'REVERSED' AND ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
        RAISE EXCEPTION 'Ters kaydı yapılmış ödeme değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Yönetimin girdiği tahsilat bir bölüme bağlı olmalıdır (kimin borcunun kapandığı belli olsun).
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'payments_recorded_unit') THEN
        ALTER TABLE payments ADD CONSTRAINT payments_recorded_unit
            CHECK (recorded_by IS NULL OR unit_id IS NOT NULL);
    END IF;
END $$;
