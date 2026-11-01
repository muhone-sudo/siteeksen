-- =====================================================
-- 080 — USTA & HİZMET YÖNETİM ALIMI (FAZ M10, K12)
--
-- Site adına açılan talepte seçilen teklif onay bekleyen gidere ya da sözleşmeye çevrilir; bunun için yönetimin
-- tedarikçinin fatura bilgisine (unvan, vergi no, vergi dairesi) ihtiyacı vardır. Hesap tablosu siteye kapalıdır;
-- işlev bilgiyi yalnız çağıranın sitesindeki, site adına açılmış talebin işi için verir.
-- =====================================================

CREATE OR REPLACE FUNCTION mp_job_vendor(p_job UUID)
RETURNS TABLE (trade_name TEXT, tax_number TEXT, tax_office TEXT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT a.trade_name::text, a.tax_number::text, a.tax_office::text
    FROM mp_jobs j
    JOIN mp_requests r ON r.id = j.request_id
    JOIN mp_supplier_accounts a ON a.id = j.account_id
    WHERE j.id = p_job AND j.property_id = current_property_id() AND r.buyer_type = 'MANAGEMENT'
$$;
REVOKE ALL ON FUNCTION mp_job_vendor(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_job_vendor(UUID) TO siteeksen_app;
COMMENT ON FUNCTION mp_job_vendor(UUID) IS 'Site adına alımda seçilen tedarikçinin fatura bilgisi (gider/sözleşme kaydı için) — 080';
