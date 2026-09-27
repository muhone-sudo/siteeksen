-- =====================================================
-- 029 — MEVZUAT PARAMETRELERİNDE SİTE İSTİSNALARI RLS ALTINDA
--
-- SORUN: `legal_parameters` sistem geneli varsayılanları (property_id NULL)
-- ve siteye özel istisnaları (yönetim planındaki gecikme oranı gibi) aynı
-- tabloda tutar. Tablo RLS dışındaydı; uygulama rolü her sitenin
-- istisnasını okuyabiliyordu. Çözümleyici (pkg/legalparams) kapsamsız havuz
-- kullandığı için RLS doğrudan açılsaydı site istisnaları SESSİZCE yok
-- sayılır, her site sistem varsayılanıyla hesaplanırdı.
--
-- ÇÖZÜM: çözümleyici artık her sorguyu site kapsamında (pkg/dbscope) yapar;
-- bu migration ile tablo, `expense_categories` modelindeki gibi korunur:
-- sistem geneli satırlar her sitede OKUNUR, siteye özel satır yalnızca kendi
-- sitesinde. Uygulama rolünün yazma yetkisi yoktur (012); yazma politikası
-- bilerek tanımlanmaz.
-- =====================================================

ALTER TABLE legal_parameters ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_parameters FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS legal_parameters_read ON legal_parameters;
CREATE POLICY legal_parameters_read ON legal_parameters
    FOR SELECT
    USING (property_id IS NULL OR property_id = current_property_id());
