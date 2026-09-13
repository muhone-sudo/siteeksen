-- =====================================================
-- 018 — JETON İPTALİ (ÇIKIŞ)
--
-- Neden: JWT durumsuzdur; "çıkış yap" düğmesi jetonu geçersiz kılmıyordu.
-- Çalınan ya da paylaşılan bir jeton, süresi dolana kadar (erişim jetonu
-- 15 dk, yenileme jetonu 7 GÜN) geçerli kalıyordu. Ortak bilgisayardan
-- çıkış yapan bir sakinin oturumu fiilen kapanmıyordu.
--
-- Çözüm: iptal edilen jetonların `jti` değeri burada tutulur ve kimlik
-- doğrulama sırasında bakılır. Kayıt, jetonun kendi son kullanma tarihine
-- kadar saklanır; sonra silinebilir (o tarihten sonra jeton zaten geçersizdir).
--
-- Neden reddetme listesi (denylist), kabul listesi (allowlist) değil:
-- kabul listesi her oturum için kayıt tutmayı ve her istekte yazmayı gerektirir;
-- reddetme listesi yalnızca çıkış yapılan jetonlar kadar büyür.
-- =====================================================

CREATE TABLE IF NOT EXISTS revoked_tokens (
    -- Jetonun benzersiz kimliği (JWT `jti` claim'i).
    jti UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,

    token_type VARCHAR(10) NOT NULL CHECK (token_type IN ('ACCESS', 'REFRESH')),

    -- Jetonun kendi son kullanma tarihi. Bu tarihten sonra kayıt temizlenebilir.
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason VARCHAR(40) NOT NULL DEFAULT 'LOGOUT'
);

CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires ON revoked_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_revoked_tokens_user ON revoked_tokens(user_id);

-- -----------------------------------------------------
-- Toplu iptal (tüm cihazlardan çıkış)
--
-- Kullanıcının o ana kadar üretilmiş TÜM jetonlarını geçersiz kılmak için
-- tek tek `jti` toplamak gerekmez: bu tarihten ÖNCE üretilmiş jetonlar
-- reddedilir. Jetonun `iat` (issued at) değeri bu tarihle karşılaştırılır.
--
-- Şifre değiştirme ve hesap ele geçirme şüphesinde de kullanılır.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS user_token_invalidation (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    -- Bu andan ÖNCE üretilmiş jetonlar geçersizdir.
    invalidate_before TIMESTAMPTZ NOT NULL,
    reason VARCHAR(40) NOT NULL DEFAULT 'LOGOUT_ALL',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------
-- Temizlik yardımcısı
--
-- Süresi dolmuş kayıtları siler. Zamanlanmış görev altyapısı olmadığı için
-- uygulama tarafından çıkışta çağrılır (amorti edilmiş temizlik).
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION purge_expired_revoked_tokens()
RETURNS INT AS $$
DECLARE
    deleted INT;
BEGIN
    DELETE FROM revoked_tokens WHERE expires_at < now();
    GET DIAGNOSTICS deleted = ROW_COUNT;
    RETURN deleted;
END;
$$ LANGUAGE plpgsql;
