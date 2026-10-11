-- =====================================================
-- 068 — KAYIT VE DAVET KURALLARI (altıncı tur D3; KMK m.20, m.22)
--
-- Kullanıcı kararları (2026-10-11):
--   - Kiracıyı malik ya da yönetim davet eder (SMS + e-posta); yönetim doğrudan da kaydedebilir. Dairede aktif
--     kiracı varken kiracı daveti/kaydı yapılamaz — yönetim dahil.
--   - Hane üyesini dairede oturan ve yönetim ekler.
--   - Kiracı gelince malikin o dairedeki hane üyelerinin kaydı biter (oturan hane değişti; iz kalır).
--   - Yalnız kiracıyla kayıtlı daireye malik davet edilebilir (uygulama kuralı, kimlik servisi).
--
-- Kurallar veritabanında da tutulur: kayıt hangi yoldan gelirse gelsin (yönetim kaydı, davet kabulü, hesap
-- etkinleştirmeyle kabul, elle düzeltme) aynı kısıt geçerlidir.
-- =====================================================

-- Daire başına tek aktif kiracı (kiracının hanesi HOUSEHOLD rolüyle kaydolur).
DO $$
BEGIN
    IF EXISTS (SELECT unit_id FROM resident_units WHERE is_active AND role = 'TENANT' GROUP BY unit_id HAVING count(*) > 1) THEN
        RAISE WARNING '068: birden çok aktif kiracısı olan daire var; tek kiracı kısıtı KURULMADI — yönetim fazlalıkları hane üyesine çevirip migration''ı yeniden denemeli';
    ELSE
        CREATE UNIQUE INDEX IF NOT EXISTS uq_resident_units_one_active_tenant
            ON resident_units(unit_id) WHERE is_active AND role = 'TENANT';
    END IF;
END $$;

-- Kiracı gelince (yeni kayıt ya da yeniden etkinleşme) dairede o ana kadarki hane üyelerinin kaydı biter:
-- onlar malikin (önceki oturanın) hanesidir. Kiracının hanesi kiracıdan SONRA eklenir.
CREATE OR REPLACE FUNCTION resident_units_tenant_arrival() RETURNS trigger AS $$
BEGIN
    IF NEW.role = 'TENANT' AND COALESCE(NEW.is_active, false)
       AND (TG_OP = 'INSERT' OR NOT COALESCE(OLD.is_active, false) OR OLD.role IS DISTINCT FROM 'TENANT') THEN
        UPDATE resident_units SET is_active = false, end_date = COALESCE(end_date, CURRENT_DATE)
        WHERE unit_id = NEW.unit_id AND role = 'HOUSEHOLD' AND is_active AND id <> NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_resident_units_tenant_arrival ON resident_units;
CREATE TRIGGER trg_resident_units_tenant_arrival
    AFTER INSERT OR UPDATE OF is_active, role ON resident_units
    FOR EACH ROW EXECUTE FUNCTION resident_units_tenant_arrival();

-- Davet: hane üyesi rolü; davet edenin sıfatı (yönetim / malik / oturan) iz için saklanır.
ALTER TABLE resident_invitations DROP CONSTRAINT IF EXISTS resident_invitations_role_check;
ALTER TABLE resident_invitations ADD CONSTRAINT resident_invitations_role_check
    CHECK (role IN ('OWNER', 'TENANT', 'PROXY', 'HOUSEHOLD'));
ALTER TABLE resident_invitations ADD COLUMN IF NOT EXISTS invited_as VARCHAR(12) NOT NULL DEFAULT 'MANAGEMENT';
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'resident_invitations_invited_as_check') THEN
        ALTER TABLE resident_invitations ADD CONSTRAINT resident_invitations_invited_as_check
            CHECK (invited_as IN ('MANAGEMENT', 'OWNER', 'OCCUPANT'));
    END IF;
END $$;

-- Dairede aynı anda tek bekleyen kiracı daveti (iki kişiye birden kiracılık teklif edilemez).
-- Süresi dolmuş bekleyen davetler okunurken zaten EXPIRED görünür (032); kalıcı olarak kapatılır.
UPDATE resident_invitations SET status = 'EXPIRED' WHERE status = 'PENDING' AND expires_at <= now();
DO $$
BEGIN
    IF EXISTS (SELECT unit_id FROM resident_invitations WHERE status = 'PENDING' AND role = 'TENANT'
               GROUP BY unit_id HAVING count(*) > 1) THEN
        RAISE WARNING '068: aynı daire için birden çok bekleyen kiracı daveti var; tek davet kısıtı KURULMADI — fazlalıklar iptal edilip migration yeniden denenmeli';
    ELSE
        CREATE UNIQUE INDEX IF NOT EXISTS uq_resident_invitations_unit_tenant_pending
            ON resident_invitations(unit_id) WHERE status = 'PENDING' AND role = 'TENANT';
    END IF;
END $$;

COMMENT ON COLUMN resident_invitations.invited_as IS 'Davet edenin sıfatı: MANAGEMENT | OWNER | OCCUPANT (068)';
