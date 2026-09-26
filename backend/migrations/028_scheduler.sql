-- =====================================================
-- 028 — ZAMANLANMIŞ BİLDİRİMLER İÇİN SİTE LİSTESİ
--
-- SORUN: gecikmiş aidat, sözleşme ihbar penceresi ve süresi aşılan devriye
-- bir olay anına değil ZAMAN geçmesine bağlıdır; bunları bir işçi
-- (cmd/scheduler) düzenli aralıklarla tarar. İşçi uygulama rolüyle
-- (siteeksen_app) bağlanır ve RLS nedeniyle `properties` tablosunda yalnızca
-- kapsamındaki siteyi görür — hangi sitelerin taranacağını bilemez.
--
-- ÇÖZÜM: yalnızca AKTİF sitelerin KİMLİKLERİNİ dönen bir fonksiyon. Başka hiçbir
-- sütun dönmez; işçi her siteyi kendi kapsamıyla (pkg/dbscope) ayrı ayrı işler,
-- yani site verisine erişim yine RLS'e tabidir. Kimliklerin kendisi hassas
-- değildir: kimliği bilmek, o sitenin verisine erişim sağlamaz.
--
-- Uygulama rolüne BYPASSRLS ya da `properties` üzerinde geniş okuma vermek
-- yerine bu yol seçildi: yetki, gereken tek bilgiyle sınırlıdır.
-- =====================================================

CREATE OR REPLACE FUNCTION scheduler_property_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
-- SECURITY DEFINER fonksiyonda arama yolu sabitlenir; aksi hâlde çağıran,
-- kendi şemasında aynı adlı bir tablo tanımlayarak fonksiyonu kandırabilirdi.
SET search_path = public, pg_temp
AS $$
    SELECT id FROM properties WHERE COALESCE(is_active, true) ORDER BY id
$$;

REVOKE ALL ON FUNCTION scheduler_property_ids() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION scheduler_property_ids() TO siteeksen_app;

COMMENT ON FUNCTION scheduler_property_ids() IS
    'cmd/scheduler için aktif site kimlikleri. Yalnızca kimlik döner; site verisi RLS ile korunmaya devam eder.';
