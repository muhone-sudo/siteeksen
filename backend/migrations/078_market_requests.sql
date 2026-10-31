-- =====================================================
-- 078 — USTA & HİZMET TALEP EŞLEŞMESİ (FAZ M6, docs/usta-hizmet/plan.md)
--
-- Çıkar çatışması: bir sitede yönetim görevi (property_roles) olan kişi aynı zamanda tedarikçiyse, o sitenin YÖNETİM
-- taleplerini göremez ve kabul edemez. Talep site kapsamında açılır; tedarikçi hesabının sahibi bu kapsamda okunamaz
-- (hesap tablosu tedarikçiye ve platforma kapalı). İşlev yalnız çatışan hesapların kimliğini döner, kişiyi değil.
-- =====================================================

CREATE OR REPLACE FUNCTION mp_conflicted_accounts(p_property UUID)
RETURNS SETOF UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT a.id FROM mp_supplier_accounts a
    WHERE EXISTS (SELECT 1 FROM property_roles pr
                  WHERE pr.user_id = a.user_id AND pr.property_id = p_property AND COALESCE(pr.is_active, true)
                    AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE))
$$;
REVOKE ALL ON FUNCTION mp_conflicted_accounts(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_conflicted_accounts(UUID) TO siteeksen_app;
COMMENT ON FUNCTION mp_conflicted_accounts(UUID) IS 'Sitede yönetim görevi olan kişilerin tedarikçi hesapları (yönetim talebi gönderilmez) — 078';
