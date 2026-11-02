-- 084: Paket sınırları (M14) — işletme (şube) sayısı ve işletme başına hizmet kalemi sayısı; boş = sınırsız.
-- Sınır iki yerde uygulanır: eklemede (servis, satır kilidiyle) ve görünürlükte (burada). Paket düşünce sınırı aşan kayıt
-- silinmez; vitrinde, işletme sayfasında ve eşleşmede görünmez, pakete yeniden geçilince hemen geri gelir.
ALTER TABLE mp_packages ADD COLUMN IF NOT EXISTS max_businesses INT;
ALTER TABLE mp_packages ADD COLUMN IF NOT EXISTS max_services_per_business INT;
ALTER TABLE mp_packages DROP CONSTRAINT IF EXISTS mp_packages_limits;
ALTER TABLE mp_packages ADD CONSTRAINT mp_packages_limits CHECK (
    (max_businesses IS NULL OR max_businesses BETWEEN 1 AND 1000) AND
    (max_services_per_business IS NULL OR max_services_per_business BETWEEN 1 AND 1000));

-- Yayındaki işletme, hesabın yayındaki işletmeleri arasında (en eskiden başlayarak) ilk max_businesses içindeyse sınır içindedir.
-- Yayında olmayan işletme zaten görünmez; sınır onu etkilemez.
CREATE OR REPLACE FUNCTION mp_business_within_limit(p_business UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT p.max_businesses IS NULL OR b.status <> 'PUBLISHED' OR
           (SELECT count(*) FROM mp_businesses o WHERE o.account_id = b.account_id AND o.status = 'PUBLISHED'
              AND (o.created_at, o.id) < (b.created_at, b.id)) < p.max_businesses
    FROM mp_businesses b JOIN mp_supplier_accounts a ON a.id = b.account_id JOIN mp_packages p ON p.id = a.package_id
    WHERE b.id = p_business
$$;

-- Etkin hizmet kalemi, işletmenin etkin kalemleri arasında (tedarikçinin sırasıyla) ilk max_services_per_business içindeyse sınır içindedir.
CREATE OR REPLACE FUNCTION mp_service_within_limit(p_service UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT p.max_services_per_business IS NULL OR NOT s.is_active OR
           (SELECT count(*) FROM mp_business_services o WHERE o.business_id = s.business_id AND o.is_active
              AND (o.sort_order, o.created_at, o.id) < (s.sort_order, s.created_at, s.id)) < p.max_services_per_business
    FROM mp_business_services s JOIN mp_supplier_accounts a ON a.id = s.account_id JOIN mp_packages p ON p.id = a.package_id
    WHERE s.id = p_service
$$;

-- Alıcı, talebini kabul etmiş işletmeyi (teklif, iş, mesaj, puan için) işletme vitrinden düşse de görür: kapatılmış, askıya
-- alınmış ya da paket sınırı dışında kalmış olabilir. Yalnız o sitenin talebini kabul etmiş işletmeler.
CREATE OR REPLACE FUNCTION mp_business_dealt_with_site(p_business UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT current_property_id() IS NOT NULL AND EXISTS (
        SELECT 1 FROM mp_request_dispatch d JOIN mp_requests r ON r.id = d.request_id
        WHERE d.business_id = p_business AND d.accepted_at IS NOT NULL AND r.property_id = current_property_id())
$$;

CREATE OR REPLACE FUNCTION mp_business_is_public(p_business UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT EXISTS (SELECT 1 FROM mp_businesses b JOIN mp_supplier_accounts a ON a.id = b.account_id
                   WHERE b.id = p_business AND b.status = 'PUBLISHED' AND a.status = 'APPROVED')
           AND mp_business_within_limit(p_business)
$$;

REVOKE ALL ON FUNCTION mp_business_within_limit(UUID), mp_service_within_limit(UUID), mp_business_dealt_with_site(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_business_within_limit(UUID), mp_service_within_limit(UUID), mp_business_dealt_with_site(UUID) TO siteeksen_app;

CREATE OR REPLACE VIEW mp_business_public WITH (security_invoker = true) AS
SELECT b.id, b.name, b.description, b.city, b.district, b.latitude, b.longitude, b.service_area, b.radius_km,
       CASE WHEN pa.phone_in_showcase THEN b.phone END AS phone,
       pa.rank_weight, pa.priority_access, pa.paid_package,
       b.rating_count, CASE WHEN b.rating_count > 0 THEN round(b.rating_sum::numeric / b.rating_count, 2) END AS rating_avg,
       b.completed_jobs, b.account_id,
       COALESCE((SELECT array_agg(bc.category_id) FROM mp_business_categories bc WHERE bc.business_id = b.id), '{}') AS category_ids
FROM mp_businesses b
CROSS JOIN LATERAL mp_account_public(b.account_id) pa
WHERE b.status = 'PUBLISHED' AND pa.approved AND mp_business_within_limit(b.id);

CREATE OR REPLACE VIEW mp_business_services_public WITH (security_invoker = true) AS
SELECT s.id, s.business_id, s.name, s.description, s.price_min_kurus, s.price_max_kurus, s.unit, s.photo_key, s.sort_order
FROM mp_business_services s
WHERE s.is_active AND mp_business_is_public(s.business_id) AND mp_service_within_limit(s.id);

DROP POLICY IF EXISTS mp_businesses_public_read ON mp_businesses;
CREATE POLICY mp_businesses_public_read ON mp_businesses FOR SELECT
    USING (status = 'PUBLISHED' AND (SELECT approved FROM mp_account_public(account_id)) AND mp_business_within_limit(id));
DROP POLICY IF EXISTS mp_businesses_buyer_read ON mp_businesses;
CREATE POLICY mp_businesses_buyer_read ON mp_businesses FOR SELECT USING (mp_business_dealt_with_site(id));
DROP POLICY IF EXISTS mp_business_services_public_read ON mp_business_services;
CREATE POLICY mp_business_services_public_read ON mp_business_services FOR SELECT
    USING (is_active AND mp_business_is_public(business_id) AND mp_service_within_limit(id));

COMMENT ON COLUMN mp_packages.max_businesses IS 'Kapatılmamış işletme sınırı (boş = sınırsız); görünürlükte en eski yayındaki N işletme — 084';
COMMENT ON COLUMN mp_packages.max_services_per_business IS 'İşletme başına hizmet kalemi sınırı (boş = sınırsız); görünürlükte sıradaki ilk N etkin kalem — 084';
