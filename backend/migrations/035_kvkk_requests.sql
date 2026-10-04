-- =====================================================
-- 035 — KVKK İLGİLİ KİŞİ BAŞVURULARI (FAZ 7.8)
--
-- 6698 s. KVKK m.11 ilgili kişiye (sakin, personel) verilerinin işlenip
-- işlenmediğini öğrenme, düzeltme, silme, itiraz gibi haklar tanır; m.13/2
-- veri sorumlusunun başvuruyu EN GEÇ 30 GÜN içinde sonuçlandırmasını ister.
-- Bugüne kadar başvuruyu almanın, süresini izlemenin ve yanıtı kayda
-- geçirmenin hiçbir yolu yoktu.
--
-- Süre koda gömülmez: KVKK_RESPONSE_DAYS (kanunla sabit, siteye göre
-- değiştirilemez). Son gün başvuru anında hesaplanıp kayda yazılır
-- (sonradan değişen parametre geçmiş başvurunun süresini değiştirmesin).
-- =====================================================

INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, is_mandatory, description)
SELECT 'KVKK_RESPONSE_DAYS', 30, 'DAY',
       '6698 s. KVKK m.13/2 — veri sorumlusu başvuruyu en kısa sürede ve en geç otuz gün içinde ücretsiz sonuçlandırır',
       true, 'İlgili kişi başvurusunun yanıt süresi'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'KVKK_RESPONSE_DAYS' AND property_id IS NULL);

CREATE TABLE IF NOT EXISTS kvkk_requests (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id   UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    user_id       UUID NOT NULL REFERENCES users(id),
    request_type  VARCHAR(20) NOT NULL
                  CHECK (request_type IN ('INFO', 'CORRECTION', 'ERASURE', 'OBJECTION', 'COMPENSATION', 'OTHER')),
    description   TEXT NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'ANSWERED', 'REJECTED')),
    due_date      DATE NOT NULL,
    response      TEXT,
    responded_by  UUID REFERENCES users(id),
    responded_at  TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT kvkk_requests_response_present
        CHECK (status = 'OPEN' OR (response IS NOT NULL AND length(trim(response)) > 0))
);
CREATE INDEX IF NOT EXISTS idx_kvkk_requests_property ON kvkk_requests(property_id, status, due_date);
CREATE INDEX IF NOT EXISTS idx_kvkk_requests_user ON kvkk_requests(user_id);

ALTER TABLE kvkk_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE kvkk_requests FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS kvkk_requests_property_scope ON kvkk_requests;
CREATE POLICY kvkk_requests_property_scope ON kvkk_requests
    USING (property_id = current_property_id())
    WITH CHECK (property_id = current_property_id());
-- Başvuru ve yanıt hesap verebilirlik kaydıdır: uygulama rolü silemez.
REVOKE DELETE, TRUNCATE ON kvkk_requests FROM siteeksen_app;

COMMENT ON TABLE kvkk_requests IS 'KVKK m.11 ilgili kişi başvuruları; yanıt süresi m.13/2 (035).';
