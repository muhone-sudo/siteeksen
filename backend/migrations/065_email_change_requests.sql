-- =====================================================
-- 065 — E-POSTA DEĞİŞİKLİĞİNDE YENİ ADRESE ONAY KODU (beşinci tur B4 ek, kullanıcı kararı 2026-10-11)
--
-- 062'de e-posta yalnızca mevcut şifreyle değişiyordu; yanlış yazılmış ya da başkasına ait bir adres
-- doğrulanmadan kaydedilebiliyordu (şifre sıfırlama kodları o adrese gidecekti). Artık kod YENİ adrese
-- gider; kod girilince adres değişir. Tablo yalnızca kimlik servisinindir (kişi bazlı, site verisi
-- değil): RLS dışında, uygulama rolüne kapalı (user_activation_codes / phone_change_requests ile aynı).
-- =====================================================

CREATE TABLE IF NOT EXISTS email_change_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    new_email       VARCHAR(254) NOT NULL,
    code_hash       TEXT NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    failed_attempts INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_email_change_open ON email_change_requests (user_id) WHERE used_at IS NULL;

REVOKE ALL ON email_change_requests FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON email_change_requests TO siteeksen_identity;

COMMENT ON TABLE email_change_requests IS 'E-posta değişikliği: yeni adrese giden kod (özet), 15 dk, 5 deneme — 065';
