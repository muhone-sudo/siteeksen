-- =====================================================
-- 041 — VERGİ / SGK YÜKÜMLÜLÜK TAKVİMİ (FAZ 7.7, M-29)
--
-- Personel çalıştıran site yönetimi işverendir: işe giriş ve işten ayrılış
-- bildirgesi, aylık Muhtasar ve Prim Hizmet Beyannamesi (MUHSGK) ve prim ödemesi
-- sürelere bağlıdır; kaçırılması idari para cezası ve gecikme zammı doğurur.
-- Bugüne kadar bu sürelerin hiçbiri izlenmiyordu.
--
-- Sistem VERGİ DOĞURUP DOĞURMADIĞINA karar vermez (kapıcı ücreti istisnası, binada
-- ticari bölüm olup olmaması, Kolay İşverenlik gibi koşullara bağlıdır — mali
-- müşavir değerlendirir). Yalnızca süreyi gösterir ve hatırlatır; takvim site
-- ayarıyla (MUHSGK_CALENDAR) kapatılabilir.
--
-- Süreler koda gömülmez:
--   MUHSGK_DUE_DAY        26 — izleyen ayın 26'sı (GVK m.98; 5510 s. Kanun m.86;
--                         beyan ve vergi ödemesi aynı gün)
--   SGK_PREMIUM_DUE       'MONTH_END' — 5510 m.88: Kurumca belirlenen gün
--                         (Sosyal Sigorta İşlemleri Yönetmeliği: izleyen ayın sonu)
--   SGK_EXIT_NOTICE_DAYS  10 — 5510 m.9: hizmet akdinin sona ermesinden itibaren
--                         en geç on gün içinde işten ayrılış bildirimi
-- İşe giriş bildirgesi sigortalılık başlangıcından ÖNCE verilir (5510 m.8/1);
-- sürenin parametresi yoktur (başlama tarihinin kendisidir).
-- Son gün hafta sonuna denk gelirse izleyen iş gününe kayar (VUK m.18); resmî
-- tatil ve idari uzatmalar (ör. bayram) sistemde bilinmez, ekranda belirtilir.
-- =====================================================

INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, is_mandatory, description)
SELECT 'MUHSGK_DUE_DAY', 26, 'DAY_OF_MONTH',
       '193 s. GVK m.98 ve 5510 s. Kanun m.86 — Muhtasar ve Prim Hizmet Beyannamesi izleyen ayın 26. günü akşamına kadar '
       || 'verilir; beyan edilen vergiler aynı süre içinde ödenir. Son gün tatile rastlarsa VUK m.18',
       true, 'Aylık MUHSGK beyan ve vergi ödeme günü'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'MUHSGK_DUE_DAY' AND property_id IS NULL);

INSERT INTO legal_parameters (code, value_text, unit, legal_basis, is_mandatory, description)
SELECT 'SGK_PREMIUM_DUE', 'MONTH_END', 'RULE',
       '5510 s. Kanun m.88 — primler Kurumca belirlenecek günün sonuna kadar ödenir; Sosyal Sigorta İşlemleri '
       || 'Yönetmeliği uyarınca ilgili ayı izleyen ayın sonu',
       true, 'SGK prim ödeme son günü (izleyen ayın son günü)'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'SGK_PREMIUM_DUE' AND property_id IS NULL);

INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, is_mandatory, description)
SELECT 'SGK_EXIT_NOTICE_DAYS', 10, 'DAY',
       '5510 s. Kanun m.9 — sigortalılığı sona erenlerin durumu işverence en geç on gün içinde Kuruma bildirilir',
       true, 'İşten ayrılış bildirgesi süresi'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters WHERE code = 'SGK_EXIT_NOTICE_DAYS' AND property_id IS NULL);

-- İşten ayrılış bildirgesinin verildiği tarih (işe giriş: sgk_registration_date).
ALTER TABLE employees ADD COLUMN IF NOT EXISTS sgk_exit_date DATE;
COMMENT ON COLUMN employees.sgk_exit_date IS 'SGK işten ayrılış bildirgesinin verildiği tarih (5510 m.9, 10 gün) — 041';
