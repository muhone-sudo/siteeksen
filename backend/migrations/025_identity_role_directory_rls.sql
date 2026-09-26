-- =====================================================
-- 025 — KİMLİK ROLÜ, DİZİN TABLOLARINDA RLS, EN AZ YETKİ
--
-- 024'e kadar kimlik ve dizin tabloları (users, properties, units, blocks,
-- resident_units, property_roles) RLS dışındaydı ve 24 servisin ortak rolü
-- `siteeksen_app` bu tabloların TAMAMINI okuyup YAZABİLİYORDU. Somut sonuç:
--
--   * Herhangi bir servisteki tek bir hatalı sorgu ya da enjeksiyon, BÜTÜN
--     sitelerin kullanıcılarının telefonunu, e-postasını ve PAROLA ÖZETİNİ
--     (password_hash) okuyabilirdi.
--   * Kargo servisi bir kullanıcının rolünü, otopark servisi bir dairenin
--     arsa payını değiştirebilirdi — bunları yapması için hiçbir neden yok.
--   * Her servis jeton iptal kayıtlarını SİLEBİLİR, yani çıkış yapılmış bir
--     oturumu geri açabilirdi; denetim kayıtlarını da silebilirdi.
--
-- Bu tabloları tek bir site kapsamına bağlamak kimlik servisini bozar:
-- giriş telefonla kullanıcı arar (henüz site yok) ve site seçimi kullanıcının
-- BÜTÜN sitelerini listeler. Çözüm iki rol ayırmaktır:
--
--   siteeksen_identity  → yalnızca kimlik servisi. YALNIZCA dizin ve jeton
--                         iptal tablolarına erişir; site verisine (aidat,
--                         personel, belge...) HİÇ erişemez. Dizin tablolarında
--                         bütün satırları görür (açık politika, aşağıda).
--   siteeksen_app       → diğer 23 servis. Dizin tablolarını YALNIZCA OKUR,
--                         yalnızca aktif sitenin satırlarını görür ve
--                         users.password_hash / TCKN sütunlarını HİÇ göremez.
--
-- BYPASSRLS kullanılmadı: yönetilen PostgreSQL hizmetlerinde (RDS, Cloud SQL)
-- ana kullanıcı bu özniteliği veremez. Onun yerine yalnızca kimlik rolüne
-- uygulanan açık politikalar tanımlandı; bu her ortamda çalışır ve hangi
-- tablonun kimlik rolüne açık olduğu şemada okunur.
--
-- Parola: rol NOLOGIN yaratılır; parola dağıtımda IDENTITY_DB_PASSWORD
-- ortam değişkeniyle `cmd/migrate` tarafından atanır. Depoya YAZILMAZ.
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'siteeksen_identity') THEN
        CREATE ROLE siteeksen_identity NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO siteeksen_identity;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON users, properties, units, blocks, resident_units, property_roles,
       revoked_tokens, user_token_invalidation
    TO siteeksen_identity;
-- Kimlik servisi de denetim izine yazar (kullanıcı ve sakin uçları,
-- middleware.AuditLog). Okuyamaz, silemez.
GRANT INSERT ON audit_logs TO siteeksen_identity;
GRANT EXECUTE ON FUNCTION current_property_id() TO siteeksen_identity;

-- -----------------------------------------------------
-- Uygulama rolü: en az yetki
-- -----------------------------------------------------

-- Dizin tabloları: salt-okur. Bu tablolara kimlik servisi dışında yazan
-- hiçbir kod yok (doğrulandı); yazma yetkisi yalnızca saldırı yüzeyiydi.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
    ON users, properties, units, blocks, resident_units, property_roles
    FROM siteeksen_app;

-- users: sütun düzeyinde okuma. Parola özeti ve TCKN'nin iki biçimi
-- uygulama rolüne HİÇ açılmaz. Sütun listesi şemadan üretilir; bundan sonra
-- eklenecek bir sütun, açıkça izin verilene kadar KAPALI kalır.
REVOKE SELECT ON users FROM siteeksen_app;
DO $$
DECLARE
    cols text;
BEGIN
    SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
      INTO cols
      FROM information_schema.columns
     WHERE table_schema = 'public' AND table_name = 'users'
       AND column_name NOT IN ('password_hash', 'tc_encrypted', 'tc_hash', 'phone_encrypted');
    EXECUTE format('GRANT SELECT (%s) ON users TO siteeksen_app', cols);
END $$;

-- Jeton iptal kayıtları: servisler yalnızca KONTROL eder; iptal eden ve
-- temizleyen yalnızca kimlik servisidir.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE
    ON revoked_tokens, user_token_invalidation
    FROM siteeksen_app;

-- Denetim kaydı: yalnızca EKLENİR. Hiçbir servis okumaz; silme/değiştirme
-- yetkisi, KVKK m.12 kapsamındaki izi yok etme imkânı demekti.
REVOKE SELECT, UPDATE, DELETE, TRUNCATE ON audit_logs FROM siteeksen_app;

-- Mevzuat parametreleri: servisler okur; değişiklik yalnızca migration ile
-- (kanunla sabit olanlar zaten tetikleyiciyle korunuyor — 012).
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON legal_parameters FROM siteeksen_app;

-- -----------------------------------------------------
-- Dizin tablolarında RLS
--
-- Her tabloda iki politika vardır:
--   *_property_scope  → herkese (uygulama rolü): yalnızca aktif site
--   *_identity_all    → YALNIZCA kimlik rolü: bütün satırlar
-- Politikalar izin verici (PERMISSIVE) olduğu için bir satır, rolüne uyan
-- politikalardan biri izin veriyorsa görünür.
-- -----------------------------------------------------

-- properties: yalnızca aktif sitenin kendisi
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS properties_property_scope ON properties;
CREATE POLICY properties_property_scope ON properties
    USING (id = current_property_id())
    WITH CHECK (id = current_property_id());
DROP POLICY IF EXISTS properties_identity_all ON properties;
CREATE POLICY properties_identity_all ON properties TO siteeksen_identity
    USING (true) WITH CHECK (true);

ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE units FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS units_property_scope ON units;
CREATE POLICY units_property_scope ON units
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS units_identity_all ON units;
CREATE POLICY units_identity_all ON units TO siteeksen_identity
    USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_blocks_property ON blocks(property_id);
ALTER TABLE blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocks FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS blocks_property_scope ON blocks;
CREATE POLICY blocks_property_scope ON blocks
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS blocks_identity_all ON blocks;
CREATE POLICY blocks_identity_all ON blocks TO siteeksen_identity
    USING (true) WITH CHECK (true);

-- resident_units: bağımsız bölüm üzerinden. idx_resident_units_unit mevcut.
ALTER TABLE resident_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE resident_units FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS resident_units_property_scope ON resident_units;
CREATE POLICY resident_units_property_scope ON resident_units
    USING (EXISTS (SELECT 1 FROM units u
                   WHERE u.id = resident_units.unit_id AND u.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM units u
                        WHERE u.id = resident_units.unit_id AND u.property_id = current_property_id()));
DROP POLICY IF EXISTS resident_units_identity_all ON resident_units;
CREATE POLICY resident_units_identity_all ON resident_units TO siteeksen_identity
    USING (true) WITH CHECK (true);

-- property_roles: 013'teki indeksler kısmidir (WHERE is_active); politika
-- is_active'e bakmadığı için onları kullanamaz. Tam indeks eklenir.
CREATE INDEX IF NOT EXISTS idx_property_roles_user_property ON property_roles(user_id, property_id);
ALTER TABLE property_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE property_roles FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS property_roles_property_scope ON property_roles;
CREATE POLICY property_roles_property_scope ON property_roles
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS property_roles_identity_all ON property_roles;
CREATE POLICY property_roles_identity_all ON property_roles TO siteeksen_identity
    USING (true) WITH CHECK (true);

-- users: aktif siteyle BAĞI olan kişiler — o sitede sakinlik kaydı (geçmiş
-- dahil: eski kayıtlardaki adlar kaybolmasın) ya da site rolü olanlar.
-- Başka bir sitenin sakini, bu sitenin servislerine görünmez.
-- İç alt sorgular resident_units / units / property_roles politikalarına da
-- tabidir; hepsi aynı kapsama bakar, döngü yoktur (hiçbiri users'a dönmez).
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS users_property_scope ON users;
CREATE POLICY users_property_scope ON users
    USING (
        EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON u.id = ru.unit_id
                WHERE ru.resident_id = users.id AND u.property_id = current_property_id())
        OR EXISTS (SELECT 1 FROM property_roles pr
                   WHERE pr.user_id = users.id AND pr.property_id = current_property_id())
    )
    WITH CHECK (false);
DROP POLICY IF EXISTS users_identity_all ON users;
CREATE POLICY users_identity_all ON users TO siteeksen_identity
    USING (true) WITH CHECK (true);
