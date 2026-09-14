-- =====================================================
-- 020 — SATIR DÜZEYİ GÜVENLİK (RLS) — BİRİNCİ DİLİM
--
-- Neden: izolasyon bugüne kadar YALNIZCA uygulama katmanındaydı. Her sorguya
-- elle `WHERE property_id = $1` yazılıyordu; tek bir sorguda bu filtre
-- unutulursa başka sitenin verisi sızardı ve bunu yakalayan hiçbir şey yoktu.
-- RLS, filtreyi veritabanına taşır: filtre unutulsa bile satır dönmez.
--
-- KAPSAM — DÜRÜSTLÜK: Bu migration RLS'i TÜM tablolara açmaz.
-- Yalnızca TEK BİR SERVİS tarafından okunan/yazılan tablolara açılır:
--
--   employees, employee_leaves, payroll          → personnel-service
--   documents, document_access_logs              → document-service
--   notifications, notification_preferences      → notification-service
--
-- Gerekçe: `units`, `properties`, `monthly_assessments` gibi tabloları birçok
-- servis okur. Onlara RLS açmak, henüz kapsamlı sorguya geçmemiş servisleri
-- ÇALIŞMAZ hâle getirirdi. Yarım açılmış bir RLS, kapalı RLS'ten kötüdür:
-- bazı yerlerde korur, bazı yerlerde uygulamayı bozar ve kimse tam olarak
-- hangisinin geçerli olduğunu bilmez. Kalan tablolar, ilgili servisler
-- `pkg/dbscope` kullanımına geçtikçe ayrı migration'larla eklenecektir
-- (bkz. tasks/todo.md FAZ 2.6).
--
-- FORCE ROW LEVEL SECURITY: tablo SAHİBİ de politikalara tabidir.
--
-- DİKKAT: FORCE bile SÜPER KULLANICIYI bağlamaz. Uygulama süper kullanıcıyla
-- bağlanırsa RLS hiçbir zaman devreye girmez. Bu yüzden aşağıda yetkisi
-- sınırlı `siteeksen_app` rolü oluşturulur ve uygulama onunla bağlanmalıdır.
-- Doğrulama betiği bu durumu ayrıca sınar.
-- =====================================================

-- Kapsam değişkeni okunamadığında politikalar hiçbir satırı eşleştirmemelidir.
-- `current_setting(..., true)` değişken tanımlı değilse NULL döner ve
-- NULL karşılaştırması FALSE üretir → hiçbir satır görünmez (fail-closed).
CREATE OR REPLACE FUNCTION current_property_id()
RETURNS UUID AS $$
DECLARE
    v TEXT;
BEGIN
    v := current_setting('app.property_id', true);
    IF v IS NULL OR v = '' THEN
        RETURN NULL;
    END IF;
    RETURN v::uuid;
EXCEPTION WHEN others THEN
    -- Geçersiz UUID de kapsam yokluğu sayılır; hata fırlatıp sorguyu
    -- patlatmak yerine hiçbir satır döndürmemek daha güvenlidir.
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION current_property_id() IS
    'RLS politikalarının okuduğu site kapsamı. pkg/dbscope tarafından her '
    'transaction başında SET LOCAL ile ayarlanır. Ayarlanmamışsa NULL döner '
    've hiçbir satır eşleşmez (fail-closed).';

-- -----------------------------------------------------
-- UYGULAMA ROLÜ — RLS'in çalışması için ZORUNLU
--
-- ÖNEMLİ: PostgreSQL'de satır düzeyi güvenliği SÜPER KULLANICIYI HİÇ BAĞLAMAZ;
-- `FORCE ROW LEVEL SECURITY` bile bunu değiştirmez. Uygulama veritabanına
-- süper kullanıcıyla bağlandığı sürece RLS tamamen dekoratiftir: politikalar
-- tanımlıdır ama hiçbir zaman devreye girmez.
--
-- Bu yüzden uygulama, yetkisi sınırlı ayrı bir rolle bağlanmalıdır. Rol burada
-- PAROLASIZ ve NOLOGIN olarak oluşturulur: parola bir migration dosyasına —
-- yani sürüm deposuna — yazılamaz. Parola ve LOGIN yetkisi kurulum sırasında
-- verilir:
--
--   ALTER ROLE siteeksen_app LOGIN PASSWORD '<gizli>';
--
-- Rolün DDL yetkisi yoktur: uygulama tablo düşüremez, politika değiştiremez.
-- Migration'lar sahip kullanıcıyla çalıştırılmaya devam eder.
-- -----------------------------------------------------
DO $role$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'siteeksen_app') THEN
        CREATE ROLE siteeksen_app NOLOGIN;
    END IF;
END
$role$;

GRANT USAGE ON SCHEMA public TO siteeksen_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO siteeksen_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO siteeksen_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO siteeksen_app;

-- Sonraki migration'larda oluşturulacak nesneler için de aynı yetkiler.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO siteeksen_app;

-- -----------------------------------------------------
-- personnel-service tabloları
-- -----------------------------------------------------
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS employees_property_scope ON employees;
CREATE POLICY employees_property_scope ON employees
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- employee_leaves'te property_id yoktur; kapsam personel üzerinden gelir.
-- Alt sorgu da RLS'e tabidir ve aynı kapsamı görür — özyineleme yoktur çünkü
-- employees politikası yalnızca current_property_id() okur.
ALTER TABLE employee_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_leaves FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS employee_leaves_property_scope ON employee_leaves;
CREATE POLICY employee_leaves_property_scope ON employee_leaves
    USING (EXISTS (SELECT 1 FROM employees e
                    WHERE e.id = employee_leaves.employee_id
                      AND e.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM employees e
                         WHERE e.id = employee_leaves.employee_id
                           AND e.property_id = current_property_id()));

ALTER TABLE payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE payroll FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS payroll_property_scope ON payroll;
CREATE POLICY payroll_property_scope ON payroll
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- document-service tabloları
-- -----------------------------------------------------
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS documents_property_scope ON documents;
CREATE POLICY documents_property_scope ON documents
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE document_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_access_logs FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS document_access_logs_property_scope ON document_access_logs;
CREATE POLICY document_access_logs_property_scope ON document_access_logs
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- notification-service tabloları
-- -----------------------------------------------------
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notifications_property_scope ON notifications;
CREATE POLICY notifications_property_scope ON notifications
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- notification_preferences'te property_id NULL olabilir: kullanıcının tüm
-- siteler için geçerli tercihi. Bu satırlar her kapsamda görünür — tercih,
-- kullanıcının kendi kararıdır ve site verisi değildir.
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notification_prefs_property_scope ON notification_preferences;
CREATE POLICY notification_prefs_property_scope ON notification_preferences
    USING (property_id IS NULL OR property_id = current_property_id())
    WITH CHECK (property_id IS NULL OR property_id = current_property_id());

-- -----------------------------------------------------
-- Bakım işleri için kapsam belirleme
--
-- `cmd/encrypt-pii` gibi bakım araçları tüm siteleri dolaşır. Bunlar her site
-- için kapsamı ayrı ayrı ayarlar; genel bir "her şeyi gör" kapısı AÇILMAZ.
-- Böyle bir kapı, uygulamada tek satırlık bir hatayla tüm izolasyonu
-- devre dışı bırakabilirdi.
-- -----------------------------------------------------
CREATE OR REPLACE VIEW rls_enabled_tables AS
SELECT c.relname::text AS table_name,
       c.relrowsecurity AS rls_enabled,
       c.relforcerowsecurity AS rls_forced,
       (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity
ORDER BY c.relname;

COMMENT ON VIEW rls_enabled_tables IS
    'Satır düzeyi güvenliği açık tablolar. rls_forced FALSE ise tablo sahibi '
    'politikalara tabi değildir. Uygulama SÜPER KULLANICIYLA bağlanıyorsa RLS '
    'hiçbir koşulda çalışmaz; siteeksen_app rolü kullanılmalıdır.';

-- Uygulamanın süper kullanıcıyla bağlanıp bağlanmadığını tek sorguyla görmek için.
CREATE OR REPLACE VIEW rls_effective AS
SELECT current_user::text          AS connected_as,
       usesuper                    AS is_superuser,
       NOT usesuper                AS rls_effective,
       CASE WHEN usesuper
            THEN 'UYARI: süper kullanıcı RLS politikalarını ATLAR; izolasyon YOK.'
            ELSE 'RLS bu bağlantı için geçerli.' END AS note
FROM pg_user WHERE usename = current_user;
