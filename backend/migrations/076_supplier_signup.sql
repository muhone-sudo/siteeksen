-- =====================================================
-- 076 — TEDARİKÇİ KAYDI: telefon doğrulaması (FAZ M1, "Usta & Hizmet", docs/usta-hizmet/plan.md)
--
-- Tedarikçi kendisi kayıt olur (sakin gibi yönetim tarafından eklenmez). Önce numarasına SMS ile
-- kod gider; kayıtlı ve kayıtsız her numaraya aynı yanıt verilir. Kod doğrulandıktan sonra (numaranın
-- sahibi olduğu kanıtlanmıştır) hesabın durumu açıklanır ve kısa ömürlü, tek kullanımlık bir
-- tamamlama jetonu verilir: yeni numara hesap açar, kayıtlı numara mevcut hesabına SUPPLIER rolü ekler.
--
-- Kodlar `user_activation_codes`'ta TUTULMAZ: o tablo kullanıcıya bağlıdır (yeni numaranın kullanıcısı
-- yoktur) ve oradaki açık kod `/auth/activate` ile şifre belirlemeye yarar. Tablo yalnızca kimlik
-- servisinindir (kişi bazlı, site verisi değil): RLS dışında, uygulama rolüne kapalı (027, 062 ile aynı gerekçe).
-- =====================================================

CREATE TABLE IF NOT EXISTS phone_verifications (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone                 VARCHAR(20) NOT NULL,
    purpose               VARCHAR(30) NOT NULL CHECK (purpose IN ('SUPPLIER_SIGNUP')),
    code_hash             TEXT NOT NULL,
    expires_at            TIMESTAMPTZ NOT NULL,
    failed_attempts       INT NOT NULL DEFAULT 0,
    verified_at           TIMESTAMPTZ,
    completion_hash       TEXT,
    completion_expires_at TIMESTAMPTZ,
    used_at               TIMESTAMPTZ,
    request_ip            VARCHAR(64),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_phone ON phone_verifications (phone, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_ip ON phone_verifications (request_ip, created_at DESC);

REVOKE ALL ON phone_verifications FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON phone_verifications TO siteeksen_identity;

COMMENT ON TABLE phone_verifications IS 'Tedarikçi kaydı telefon doğrulaması: SMS kodu (özet), 15 dk, 5 deneme; doğrulamadan sonra tek kullanımlık tamamlama jetonu (özet) — 076';
