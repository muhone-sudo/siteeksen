-- =====================================================
-- 071 — MALİKİN GÖRÜNÜRLÜK POLİTİKASI (altıncı tur D6; KVKK m.4 ölçülülük)
--
-- Kullanıcı kararları (2026-10-11): devirden sonra malikin neyi göreceğini malik DEĞİL yönetim belirler (malik kiracı
-- üzerinde baskı kurabilir). Site bazında TEK politika (daire bazında ayar hedefli baskı aracı olurdu), varsayılan EN DAR,
-- değişiklik kurul üyesi onayı ister, kiracı malikin neyi gördüğünü görür.
--
-- Seçenekli alanlar (V9, hepsi varsayılan KAPALI):
--   show_tenant_contact     kiracının adı ve maskeli telefonu
--   show_tenant_debt_total  kiracı sorumluluğundaki kullanım borcunun toplamı
--   show_tenant_overdue     vadesi geçen kullanım borcu ve malike aylık uyarı
--   show_unit_requests      dairenin arıza/talep kayıtları
-- Her zaman görünür (seçenek değil): malik sınıfı borç, genel kurul/oy, dairenin oturum durumu, kiracılık bitiş süreçleri,
-- kiracılığı bitmiş açık kullanım borcu (V6). Hiç görünmez: ziyaretçi, kargo, sayaç/pusula ayrıntısı, hane üyeleri.
--
-- Akış: yönetim (yönetici ya da kurul üyesi) önerir → öneren dışında bir KURUL ÜYESİ onaylar → yürürlüğe girer, önceki
-- sürüm SUPERSEDED olur. Kayıt silinmez; seçenekler önerildikten sonra değiştirilemez (yeni öneri gerekir).
-- =====================================================

CREATE TABLE IF NOT EXISTS owner_visibility_policies (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id            UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    status                 VARCHAR(12) NOT NULL DEFAULT 'PENDING'
                           CHECK (status IN ('PENDING', 'ACTIVE', 'SUPERSEDED', 'REJECTED', 'CANCELLED')),
    show_tenant_contact    BOOLEAN NOT NULL DEFAULT false,
    show_tenant_debt_total BOOLEAN NOT NULL DEFAULT false,
    show_tenant_overdue    BOOLEAN NOT NULL DEFAULT false,
    show_unit_requests     BOOLEAN NOT NULL DEFAULT false,
    note                   TEXT NOT NULL DEFAULT '',
    proposed_by            UUID NOT NULL REFERENCES users(id),
    proposed_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    decided_by             UUID REFERENCES users(id),
    decided_at             TIMESTAMPTZ,
    decision_note          TEXT NOT NULL DEFAULT '',
    -- Kurul üyesi onayı: öneren kendi önerisini onaylayamaz.
    CONSTRAINT owner_visibility_four_eyes CHECK (status <> 'ACTIVE' OR (decided_by IS NOT NULL AND decided_by <> proposed_by))
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_owner_visibility_active ON owner_visibility_policies(property_id) WHERE status = 'ACTIVE';
CREATE UNIQUE INDEX IF NOT EXISTS uq_owner_visibility_pending ON owner_visibility_policies(property_id) WHERE status = 'PENDING';
CREATE INDEX IF NOT EXISTS idx_owner_visibility_property ON owner_visibility_policies(property_id, proposed_at DESC);

ALTER TABLE owner_visibility_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_visibility_policies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS owner_visibility_policies_property_scope ON owner_visibility_policies;
CREATE POLICY owner_visibility_policies_property_scope ON owner_visibility_policies
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
DROP POLICY IF EXISTS owner_visibility_policies_identity_read ON owner_visibility_policies;
CREATE POLICY owner_visibility_policies_identity_read ON owner_visibility_policies FOR SELECT TO siteeksen_identity USING (true);

REVOKE DELETE, TRUNCATE ON owner_visibility_policies FROM siteeksen_app;
GRANT SELECT, INSERT, UPDATE ON owner_visibility_policies TO siteeksen_app;
GRANT SELECT ON owner_visibility_policies TO siteeksen_identity;

-- Seçenekler ve öneren önerildikten sonra değişmez; yalnız durum ve karar alanları güncellenir.
CREATE OR REPLACE FUNCTION owner_visibility_guard() RETURNS trigger AS $$
BEGIN
    IF current_user NOT IN ('siteeksen_app', 'siteeksen_identity') THEN
        RETURN NEW;
    END IF;
    IF (NEW.show_tenant_contact, NEW.show_tenant_debt_total, NEW.show_tenant_overdue, NEW.show_unit_requests,
        NEW.proposed_by, NEW.proposed_at, NEW.property_id, NEW.note)
       IS DISTINCT FROM
       (OLD.show_tenant_contact, OLD.show_tenant_debt_total, OLD.show_tenant_overdue, OLD.show_unit_requests,
        OLD.proposed_by, OLD.proposed_at, OLD.property_id, OLD.note) THEN
        RAISE EXCEPTION 'Görünürlük önerisi değiştirilemez; yeni öneri açılmalı' USING ERRCODE = 'check_violation';
    END IF;
    IF OLD.status IN ('SUPERSEDED', 'REJECTED', 'CANCELLED') THEN
        RAISE EXCEPTION 'Kapanmış görünürlük kaydı değiştirilemez' USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_owner_visibility_guard ON owner_visibility_policies;
CREATE TRIGGER trg_owner_visibility_guard BEFORE UPDATE ON owner_visibility_policies
    FOR EACH ROW EXECUTE FUNCTION owner_visibility_guard();

-- Etkin politika (yoksa en dar: hepsi kapalı). SECURITY INVOKER: çağıranın kapsamında.
CREATE OR REPLACE FUNCTION owner_visibility(p_property uuid)
RETURNS TABLE (show_tenant_contact boolean, show_tenant_debt_total boolean, show_tenant_overdue boolean, show_unit_requests boolean)
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(bool_or(p.show_tenant_contact), false), COALESCE(bool_or(p.show_tenant_debt_total), false),
           COALESCE(bool_or(p.show_tenant_overdue), false), COALESCE(bool_or(p.show_unit_requests), false)
    FROM owner_visibility_policies p WHERE p.property_id = p_property AND p.status = 'ACTIVE'
$$;
GRANT EXECUTE ON FUNCTION owner_visibility(uuid) TO siteeksen_app, siteeksen_identity;

COMMENT ON TABLE owner_visibility_policies IS
    'Devirden sonra malikin göreceği seçenekli alanlar: site bazında, yönetim önerir, kurul üyesi onaylar, varsayılan en dar — 071';
