-- ============================================================================
-- 011 — Denetim izi (audit_logs) tablosunu çalışır hale getirme
-- ============================================================================
--
-- SORUN (2026-09-09 denetiminde tespit edildi):
--
-- `pkg/audit/audit.go` şu kolonlara yazıyordu:
--     user_id, user_ip, user_agent, action, resource_type, resource_id, old_values, new_values
--
-- Geçerli şema ise (`003_multi_tenant.sql:63-76`, ki 001'deki tabloyu DROP edip yeniden yaratıyor):
--     id, tenant_id (NOT NULL), user_id, action, entity_type, entity_id,
--     old_values, new_values, ip_address, user_agent, created_at
--
-- Yani üç kolon adı uyuşmuyordu (user_ip≠ip_address, resource_type≠entity_type,
-- resource_id≠entity_id) ve kod `tenant_id`'yi hiç doldurmuyordu. INSERT bu yüzden
-- HER çağrıda `42703 undefined_column` hatası veriyordu.
--
-- Hata `pkg/middleware/auth.go:115`'te `_ = audit.LogAction(...)` ile yutulduğu için
-- kimse fark etmedi: `audit_logs` tablosu kalıcı olarak BOŞ kaldı. Bu, hem KVKK
-- yükümlülüğünü hem de `legal/kvkk-aydinlatma.md`'deki "log tutuyoruz, 2 yıl saklıyoruz"
-- taahhüdünü karşılıksız bıraktı.
--
-- ÇÖZÜM:
--   1. `tenant_id` zorunluluğunu kaldır. Çok kiracılılık (`pkg/tenant`) hiçbir yere bağlı
--      değil ve `tenants` tablosu boş; NOT NULL bir yabancı anahtarı doldurmanın yolu yok.
--   2. `property_id` ekle — denetim izinin hangi siteye ait olduğu, tenant yerine bugün
--      gerçekten kullanılan kapsam alanıdır (JWT'deki `property_id` claim'i).
--   3. Sorgulanabilirlik için indeksler ekle (denetim raporu ve KVKK ilgili kişi
--      başvurusuna yanıt üretebilmek için gerekli).
--
-- Kod tarafındaki karşılık düzeltmesi: `pkg/audit/audit.go` artık şema kolon adlarını
-- (`ip_address`, `entity_type`, `entity_id`) kullanır ve `property_id` yazar.
--
-- Tüm ifadeler idempotenttir.
-- ============================================================================

-- 0) 001'den gelen ESKİ kolon adlarını tasfiye et.
--
-- 2026-09-13 notu: `003` daha önce `DROP TABLE audit_logs` ile 001'in tablosunu yok edip
-- yeniden yaratıyordu. Bu, migration her tekrarlandığında TÜM DENETİM İZİNİ SİLİYORDU
-- (madde 1.13), bu yüzden DROP kaldırıldı. Ancak o zaman 001'in tablosu yerinde kalıyor ve
-- eski kolonlar (`user_ip`, `resource_type NOT NULL`, `resource_id`) hayatta kalıyor;
-- `resource_type` NOT NULL olduğu için pkg/audit'in INSERT'ü başarısız oluyordu.
-- Burada veri yeni kolonlara taşınır ve eski kolonlar düşürülür (tek kaynak ilkesi).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'audit_logs' AND column_name = 'resource_type') THEN
        UPDATE audit_logs SET entity_type = resource_type WHERE entity_type IS NULL;
        ALTER TABLE audit_logs DROP COLUMN resource_type;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'audit_logs' AND column_name = 'resource_id') THEN
        UPDATE audit_logs SET entity_id = resource_id WHERE entity_id IS NULL;
        ALTER TABLE audit_logs DROP COLUMN resource_id;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'audit_logs' AND column_name = 'user_ip') THEN
        UPDATE audit_logs SET ip_address = user_ip WHERE ip_address IS NULL;
        ALTER TABLE audit_logs DROP COLUMN user_ip;
    END IF;

    -- Denetim kaydının zamanı saat dilimi taşımalıdır: KVKK/5651 kapsamında
    -- "ne zaman" sorusunun tek anlamlı yanıtı olması gerekir.
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'audit_logs' AND column_name = 'created_at'
                 AND data_type = 'timestamp without time zone') THEN
        ALTER TABLE audit_logs
            ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
    END IF;
END $$;

-- 1) tenant_id artık zorunlu değil
ALTER TABLE audit_logs ALTER COLUMN tenant_id DROP NOT NULL;

-- 2) Denetim kaydının kapsamı: hangi site/taşınmaz
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS property_id UUID REFERENCES properties(id);

-- 3) İsteği ilişkilendirmek için korelasyon kimliği (aynı istekten doğan kayıtları eşler)
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS request_id VARCHAR(64);

-- 4) HTTP durum kodu — yetkisiz erişim denemelerini (401/403) başarılı erişimlerden ayırmak için
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS status_code INT;

-- 5) İndeksler
CREATE INDEX IF NOT EXISTS idx_audit_logs_user       ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_property   ON audit_logs(property_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created    ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity     ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action     ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_request    ON audit_logs(request_id);
