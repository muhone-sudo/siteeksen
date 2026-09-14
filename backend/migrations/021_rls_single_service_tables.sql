-- =====================================================
-- 021 — SATIR DÜZEYİ GÜVENLİK (RLS) — İKİNCİ DİLİM
--
-- 020 numaralı migration RLS'i yalnızca 7 tabloda açmıştı (personel, belge,
-- bildirim). Bu migration, aynı ölçütü karşılayan tabloları ekler:
-- TEK BİR SERVİSİN okuyup yazdığı tablolar.
--
-- Ölçüt neden bu: `units`, `properties`, `monthly_assessments` gibi tabloları
-- on servis okur. Onlara RLS açmak, henüz `pkg/dbscope` kullanımına geçmemiş
-- her servisi ÇALIŞMAZ hâle getirirdi. Bu migration'dan önce ilgili sekiz
-- servisin deposu kapsamlı sorguya geçirildi; sıra tersine dönerse uygulama
-- bozulur.
--
-- KAPSAM — bu dilimde korunan tablolar ve tek kullanıcısı:
--
--   vehicles, parking_zones, parking_logs              → parking-service
--   visitors                                           → visitor-service
--   inventory_items, _categories, _movements           → inventory-service
--   assets, asset_categories, asset_maintenance        → asset-service
--   patrol_checkpoints, patrol_routes, patrol_logs     → patrol-service
--   bulletin_posts, bulletin_comments, _messages       → bulletin-service
--   surveys, survey_options, survey_votes              → survey-service + nps-service
--
-- Anket tablolarının İKİ servisi vardır: nps-service ayrı tablo açmaz, anket
-- altyapısını kullanır. Bu yüzden ikisi de aynı dilimde kapsamlı sorguya
-- geçirildi — biri geçip diğeri geçmeseydi RLS açıldığı an NPS çalışmazdı.
--
-- Kapsam dışı bırakılan tabloların listesi ve sayısı doğrulama betiğinde
-- raporlanır (`verify-stack.sh` §32). "Kısmen yapıldı", ancak sınırı ölçülüp
-- yazıldığında dürüst bir cevaptır.
--
-- HATIRLATMA: RLS SÜPER KULLANICIYI BAĞLAMAZ — `FORCE ROW LEVEL SECURITY`
-- bile. Uygulama `siteeksen_app` rolüyle bağlanmalıdır (bkz. 020).
-- =====================================================

-- -----------------------------------------------------
-- parking-service
-- -----------------------------------------------------
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS vehicles_property_scope ON vehicles;
CREATE POLICY vehicles_property_scope ON vehicles
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE parking_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE parking_zones FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS parking_zones_property_scope ON parking_zones;
CREATE POLICY parking_zones_property_scope ON parking_zones
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE parking_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE parking_logs FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS parking_logs_property_scope ON parking_logs;
CREATE POLICY parking_logs_property_scope ON parking_logs
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- visitor-service
-- -----------------------------------------------------
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS visitors_property_scope ON visitors;
CREATE POLICY visitors_property_scope ON visitors
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- inventory-service
--
-- inventory_movements'te property_id YOKTUR; kapsam kalem üzerinden gelir.
-- Alt sorgudaki inventory_items da RLS'e tabidir ve aynı kapsamı görür.
-- Özyineleme yoktur: items politikası yalnızca current_property_id() okur.
-- -----------------------------------------------------
-- KATEGORİ TABLOLARINDA GLOBAL SATIRLAR VARDIR.
--
-- `inventory_categories` ve `asset_categories`, `property_id IS NULL` olan
-- ORTAK kategoriler taşır (005 numaralı migration'ın tohum verisi: "Temizlik
-- Malzemeleri", "Asansör" gibi). Depo katmanı bunları bilerek okur
-- (`WHERE property_id = $1 OR property_id IS NULL`).
--
-- Katı bir politika (`property_id = current_property_id()`) bu satırları her
-- siteden GİZLERDİ: kimse hata almaz, kategoriler sessizce kaybolurdu.
-- Bu yüzden OKUMA global satırlara izin verir.
--
-- YAZMA vermez: WITH CHECK içinde NULL kabul edilmez. Uygulama kendi başına
-- global kategori ÜRETEMEZ — üretebilseydi, tek bir hatalı istek o satırı
-- platformdaki HER siteye görünür kılardı. Global satırlar yalnızca
-- migration ile, sahip kullanıcı tarafından eklenir.
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_categories FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventory_categories_property_scope ON inventory_categories;
CREATE POLICY inventory_categories_property_scope ON inventory_categories
    USING (property_id IS NULL OR property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventory_items_property_scope ON inventory_items;
CREATE POLICY inventory_items_property_scope ON inventory_items
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS inventory_movements_property_scope ON inventory_movements;
CREATE POLICY inventory_movements_property_scope ON inventory_movements
    USING (EXISTS (SELECT 1 FROM inventory_items i
                    WHERE i.id = inventory_movements.item_id
                      AND i.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM inventory_items i
                         WHERE i.id = inventory_movements.item_id
                           AND i.property_id = current_property_id()));

-- -----------------------------------------------------
-- asset-service
-- -----------------------------------------------------
-- Global satırlar için gerekçe: yukarıda inventory_categories'te açıklandı.
ALTER TABLE asset_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_categories FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS asset_categories_property_scope ON asset_categories;
CREATE POLICY asset_categories_property_scope ON asset_categories
    USING (property_id IS NULL OR property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS assets_property_scope ON assets;
CREATE POLICY assets_property_scope ON assets
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE asset_maintenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_maintenance FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS asset_maintenance_property_scope ON asset_maintenance;
CREATE POLICY asset_maintenance_property_scope ON asset_maintenance
    USING (EXISTS (SELECT 1 FROM assets a
                    WHERE a.id = asset_maintenance.asset_id
                      AND a.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM assets a
                         WHERE a.id = asset_maintenance.asset_id
                           AND a.property_id = current_property_id()));

-- -----------------------------------------------------
-- patrol-service
-- -----------------------------------------------------
ALTER TABLE patrol_checkpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrol_checkpoints FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS patrol_checkpoints_property_scope ON patrol_checkpoints;
CREATE POLICY patrol_checkpoints_property_scope ON patrol_checkpoints
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE patrol_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrol_routes FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS patrol_routes_property_scope ON patrol_routes;
CREATE POLICY patrol_routes_property_scope ON patrol_routes
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE patrol_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrol_logs FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS patrol_logs_property_scope ON patrol_logs;
CREATE POLICY patrol_logs_property_scope ON patrol_logs
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

-- -----------------------------------------------------
-- bulletin-service
--
-- bulletin_messages bugün hiçbir kod tarafından kullanılmıyor. Yine de
-- korunuyor: korunan bir tablonun korunmayan çocuğu, izolasyonda açık
-- kapıdır. Tabloyu ileride kullanacak kod, korumayı hazır bulur.
-- -----------------------------------------------------
ALTER TABLE bulletin_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bulletin_posts FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bulletin_posts_property_scope ON bulletin_posts;
CREATE POLICY bulletin_posts_property_scope ON bulletin_posts
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE bulletin_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bulletin_comments FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bulletin_comments_property_scope ON bulletin_comments;
CREATE POLICY bulletin_comments_property_scope ON bulletin_comments
    USING (EXISTS (SELECT 1 FROM bulletin_posts p
                    WHERE p.id = bulletin_comments.post_id
                      AND p.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM bulletin_posts p
                         WHERE p.id = bulletin_comments.post_id
                           AND p.property_id = current_property_id()));

ALTER TABLE bulletin_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE bulletin_messages FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bulletin_messages_property_scope ON bulletin_messages;
CREATE POLICY bulletin_messages_property_scope ON bulletin_messages
    USING (EXISTS (SELECT 1 FROM bulletin_posts p
                    WHERE p.id = bulletin_messages.post_id
                      AND p.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM bulletin_posts p
                         WHERE p.id = bulletin_messages.post_id
                           AND p.property_id = current_property_id()));

-- -----------------------------------------------------
-- survey-service + nps-service
--
-- Oy tablosunda kapsam anket üzerinden gelir. Oyun GİZLİLİĞİ ayrı bir
-- konudur ve uygulama katmanında korunur (anonim anketlerde oy veren
-- döndürülmez); RLS burada yalnızca SİTE izolasyonu sağlar.
-- -----------------------------------------------------
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE surveys FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS surveys_property_scope ON surveys;
CREATE POLICY surveys_property_scope ON surveys
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());

ALTER TABLE survey_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_options FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS survey_options_property_scope ON survey_options;
CREATE POLICY survey_options_property_scope ON survey_options
    USING (EXISTS (SELECT 1 FROM surveys s
                    WHERE s.id = survey_options.survey_id
                      AND s.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM surveys s
                         WHERE s.id = survey_options.survey_id
                           AND s.property_id = current_property_id()));

ALTER TABLE survey_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_votes FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS survey_votes_property_scope ON survey_votes;
CREATE POLICY survey_votes_property_scope ON survey_votes
    USING (EXISTS (SELECT 1 FROM surveys s
                    WHERE s.id = survey_votes.survey_id
                      AND s.property_id = current_property_id()))
    WITH CHECK (EXISTS (SELECT 1 FROM surveys s
                         WHERE s.id = survey_votes.survey_id
                           AND s.property_id = current_property_id()));

-- -----------------------------------------------------
-- Alt tabloların ebeveyn aramaları indeksli olmalı
--
-- RLS politikası her satır için EXISTS alt sorgusu çalıştırır. Ebeveyn
-- anahtarı indeksli değilse bu, tablo taramasına döner ve koruma
-- "yavaşlığı yüzünden kapatılan" bir şeye dönüşür. Korumanın kalıcı olması
-- için maliyeti burada düşürülür.
-- -----------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_inventory_movements_item ON inventory_movements(item_id);
CREATE INDEX IF NOT EXISTS idx_asset_maintenance_asset ON asset_maintenance(asset_id);
CREATE INDEX IF NOT EXISTS idx_bulletin_comments_post ON bulletin_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_bulletin_messages_post ON bulletin_messages(post_id);
CREATE INDEX IF NOT EXISTS idx_survey_options_survey ON survey_options(survey_id);
CREATE INDEX IF NOT EXISTS idx_survey_votes_survey ON survey_votes(survey_id);
