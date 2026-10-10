-- =====================================================
-- 062 — SAKİNİN KENDİ TELEFON DEĞİŞİKLİĞİ (beşinci tur B4, Şikayetvar "numara değişikliği")
--
-- Önceden numarayı yalnızca site yönetimi değiştirebiliyordu; kişi birden çok sitede
-- kayıtlıysa yönetim de değiştiremiyor ve hata mesajı var olmayan bir ekranı gösteriyordu.
-- Artık kişi kendi hesabından değiştirir: mevcut şifresiyle ister, yeni numaraya SMS ile
-- giden kodla yeni numaranın kendisine ait olduğunu kanıtlar.
--
-- Kodlar `user_activation_codes`'ta TUTULMAZ: o tablodaki açık kod `/auth/activate` ile şifre
-- belirlemeye yarar; numara değişikliği kodunun şifre sıfırlamada kullanılabilmesi açık olurdu.
-- Tablo yalnızca kimlik servisinindir (kişi bazlı, site verisi değil): RLS dışında, uygulama
-- rolüne kapalı (user_activation_codes ile aynı gerekçe, 027).
-- =====================================================

CREATE TABLE IF NOT EXISTS phone_change_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    new_phone       VARCHAR(20) NOT NULL,
    code_hash       TEXT NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    used_at         TIMESTAMPTZ,
    failed_attempts INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_phone_change_open ON phone_change_requests (user_id) WHERE used_at IS NULL;

REVOKE ALL ON phone_change_requests FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON phone_change_requests TO siteeksen_identity;

COMMENT ON TABLE phone_change_requests IS 'Sakinin kendi telefon değişikliği: yeni numaraya SMS kodu (özet), 15 dk, 5 deneme — 062';
