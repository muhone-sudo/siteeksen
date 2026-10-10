-- =====================================================
-- 055 — BORCU YOKTUR BELGESİ (Apsiyon BUG-04)
--
-- Apsiyon şikâyeti: son ödeme günü gelmemiş cari aidat "borç" sayıldığı için kredi/tapu
-- işleminde istenen borcu yoktur yazısı verilmiyordu. Hukuki ayrım:
--   * vadesi geçmiş (muaccel) borç: due_date < belge günü ve ödenmemiş → takip konusu
--   * vadesi gelmemiş (müeccel) cari tahakkuk: temerrüt ve gecikme tazminatı yok
-- Belge yalnızca vadesi geçmiş borç SIFIRSA üretilir; vadesi gelmemiş tutar belgede ayrıca
-- gösterilir. Belge değiştirilemez; doğrulama kodu (SHA-256) ile herkes (banka, tapu
-- memuru) kimlik doğrulamadan geçerliliğini sınayabilir — kişisel veri döndürülmez.
-- =====================================================

CREATE TABLE IF NOT EXISTS clearance_certificates (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id       UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    unit_id           UUID NOT NULL REFERENCES units(id),
    requested_by      UUID REFERENCES users(id),
    as_of_date        DATE NOT NULL,
    issued_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at        DATE NOT NULL,
    not_due_kurus     BIGINT NOT NULL DEFAULT 0 CHECK (not_due_kurus >= 0),
    verification_code CHAR(64) NOT NULL UNIQUE,
    CHECK (expires_at > as_of_date)
);
CREATE INDEX IF NOT EXISTS idx_clearance_certificates_unit ON clearance_certificates(property_id, unit_id, issued_at DESC);

ALTER TABLE clearance_certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE clearance_certificates FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS clearance_certificates_property_scope ON clearance_certificates;
CREATE POLICY clearance_certificates_property_scope ON clearance_certificates
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE UPDATE, DELETE, TRUNCATE ON clearance_certificates FROM siteeksen_app;

-- Kimliksiz doğrulama: yalnızca site adı, bölüm etiketi ve tarihler döner (KVKK m.4
-- veri minimizasyonu — kişi adı, tutar, telefon yok). Kod 256 bit; tahmin edilemez.
CREATE OR REPLACE FUNCTION verify_clearance_certificate(p_code text)
RETURNS TABLE (property_name text, unit_label text, as_of_date date, issued_at timestamptz, expires_at date)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT p.name::text, (COALESCE(u.block, '') || '-' || u.door_number)::text, c.as_of_date, c.issued_at, c.expires_at
    FROM clearance_certificates c
    JOIN properties p ON p.id = c.property_id
    JOIN units u ON u.id = c.unit_id
    WHERE c.verification_code = lower(p_code)
$$;
REVOKE ALL ON FUNCTION verify_clearance_certificate(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION verify_clearance_certificate(text) TO siteeksen_app;

COMMENT ON TABLE clearance_certificates IS 'Borcu yoktur belgesi: vadesi geçmiş borç sıfırken üretilir, SHA-256 kodla doğrulanır (Apsiyon BUG-04) — 055';
