-- =====================================================
-- 027 — HESAP ETKİNLEŞTİRME, ŞİFRE DEĞİŞTİRME, GİRİŞ KİLİDİ
--
-- SORUN (2026-09-26): panelden eklenen sakin için rastgele bir geçici şifre
-- üretiliyor, özeti saklanıyor ve şifre HİÇ KİMSEYE iletilmiyordu. Şifre
-- belirleme akışı da yoktu. Sonuç: yönetimin eklediği hiçbir sakin sisteme
-- giriş yapamıyordu. Ayrıca girişte deneme sınırı yoktu (kaba kuvvet).
--
-- ÇÖZÜM:
--   * Yönetici sakin eklediğinde ya da "kod üret" dediğinde TEK KULLANIMLIK bir
--     etkinleştirme kodu üretilir; kod yöneticiye YALNIZCA BİR KEZ gösterilir.
--     SMS sağlayıcısı bağlı olmadığı için kodu sakine yönetici iletir (elden,
--     telefonla). Veritabanında kodun kendisi değil SHA-256 özeti saklanır.
--   * Kod 7 gün geçerlidir; 5 hatalı denemede kilitlenir; yenisi üretilince
--     eskisi geçersizleşir.
--   * Girişte art arda 5 hatalı denemeden sonra hesap 15 dakika kilitlenir.
-- =====================================================

CREATE TABLE IF NOT EXISTS user_activation_codes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code_hash       TEXT NOT NULL,
    purpose         VARCHAR(20) NOT NULL CHECK (purpose IN ('ACTIVATION', 'RESET')),
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    failed_attempts INT NOT NULL DEFAULT 0,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_activation_codes_user_open
    ON user_activation_codes (user_id) WHERE used_at IS NULL;

ALTER TABLE users ADD COLUMN IF NOT EXISTS password_set_at       TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until          TIMESTAMPTZ;

-- Mevcut hesaplar şifresini zaten biliyor sayılır (tohum/önceden açılmış).
-- Yalnızca bu migration anında NULL olanlar doldurulur; tekrar çalıştırmada
-- sonradan eklenen "henüz etkinleşmemiş" hesaplara dokunulmaz.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = 27) THEN
        UPDATE users SET password_set_at = created_at WHERE password_set_at IS NULL;
    END IF;
END $$;

-- Yalnızca kimlik servisi erişir. Uygulama rolü kodları hiç göremez.
REVOKE ALL ON user_activation_codes FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_activation_codes TO siteeksen_identity;
