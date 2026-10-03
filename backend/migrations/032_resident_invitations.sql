-- =====================================================
-- 032 — SAKİN DAVETİ (kullanıcı kararı S-20, 2026-10-03)
--
-- SORUN: başka bir sitede kayıtlı kişinin telefonuyla sakin eklenince hesap
-- önceden SESSİZCE bağlanıyor ve kişinin adı/e-postası yöneticiye dönüyordu
-- (B25). 031 öncesi düzeltme bunu 409 ile engelledi; ancak iki sitede dairesi
-- olan kişi (yönetim şirketi müşterilerinde yaygın) ikinci siteye hiç
-- eklenemiyordu.
--
-- ÇÖZÜM: davet. Yönetici telefonu girer; kişinin bu siteyle bağı yoksa bağ
-- KURULMAZ, davet açılır. Kişi kendi uygulamasında kabul ederse daireye
-- bağlanır, reddederse hiçbir şey olmaz. Yöneticiye kişinin adı/e-postası
-- gösterilmez. Davet 14 gün geçerlidir (süre dolumu okunurken hesaplanır;
-- zamanlanmış iş gerekmez; aynı kişiye yeniden davet açılırken süresi dolan
-- bekleyen davet EXPIRED olarak kapatılır). Kayıt silinmez: kimin, kimi, ne zaman davet
-- ettiği ve yanıtın zamanı iz olarak kalır (KVKK hesap verebilirlik).
--
-- ERİŞİM: yalnızca kimlik servisi (davet, dizin verisidir). Uygulama rolüne
-- hiçbir yetki verilmez; RLS de açıktır.
-- =====================================================

CREATE TABLE IF NOT EXISTS resident_invitations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id      UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role         VARCHAR(20) NOT NULL CHECK (role IN ('OWNER', 'TENANT', 'PROXY')),
    status       VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                 CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELLED', 'EXPIRED')),
    invited_by   UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at   TIMESTAMPTZ NOT NULL DEFAULT now() + interval '14 days',
    responded_at TIMESTAMPTZ
);

-- Aynı kişiye aynı daire ve rol için aynı anda tek bekleyen davet.
CREATE UNIQUE INDEX IF NOT EXISTS uq_resident_invitations_pending
    ON resident_invitations(user_id, unit_id, role) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_resident_invitations_user ON resident_invitations(user_id);
CREATE INDEX IF NOT EXISTS idx_resident_invitations_property ON resident_invitations(property_id, created_at DESC);

-- 020'deki varsayılan yetkiler yeni tabloyu uygulama rolüne de açar; geri alınır.
REVOKE ALL ON resident_invitations FROM siteeksen_app;
-- Silme yok: davet geçmişi iz olarak kalır.
GRANT SELECT, INSERT, UPDATE ON resident_invitations TO siteeksen_identity;

ALTER TABLE resident_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE resident_invitations FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS resident_invitations_property_scope ON resident_invitations;
CREATE POLICY resident_invitations_property_scope ON resident_invitations
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS resident_invitations_identity_all ON resident_invitations;
CREATE POLICY resident_invitations_identity_all ON resident_invitations TO siteeksen_identity
    USING (true) WITH CHECK (true);

COMMENT ON TABLE resident_invitations IS
    'Başka sitede kayıtlı kişiyi sakin olarak ekleme daveti; kişi kabul edince resident_units yazılır (032, S-20).';
