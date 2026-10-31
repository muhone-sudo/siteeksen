# "Usta & Hizmet" — SiteEksen tedarikçi pazaryeri (plan, kullanıcı onayı 2026-10-31)

## Context

Hedef: SiteEksen'e gelir getiren yeni bir ürün. Esnaf, dükkan, tedarikçi; hizmet ve mal satmak isteyen herkes (konumdan bağımsız) normal
kullanıcı kaydı yapar, ardından dükkanlarını/işletmelerini ve hizmetlerini, adres ve konumlarıyla kaydeder. Apartman yönetiminden ayrı kendi
panelleri (web + mobil uygulama) vardır, yalnız kendileriyle ilgili yerleri görürler. Böylece bir tedarikçi havuzu oluşur. Site yönetimi, malik
ve sakinler bu havuzdan oturdukları yerdeki tedarikçilerle görüşüp fiyat alır. SiteEksen aradaki ticaretten **devre dışı bırakılamayan** bir
yöntemle kazanır; sakin için erişim çok basittir.

Sızıntıya dayanıklılığın ilkesi: ücret, tedarikçi değeri (müşteri adayı) ALDIĞI ANDA ve önceden yüklenmiş bakiyeden alınır.
Anlaşmanın platformda bitmesine bağlı değildir. Taraflar sonradan telefonla anlaşsa da gelir alınmış olur.

## İş modeli (kararlar)

| # | Karar |
|---|---|
| K1 | Gelir = tedarikçi paketi (abonelik) + kabul edilen talep başına ücret. Platform içi ödeme komisyonu sonraki aşama |
| K2 | Alıcılar: site yönetimi (site giderleri) + sakin/malik/kiracı/vekil (kendi dairesi) |
| K3 | Kapsam: hizmet + mal, **teklif usulü** (talep → teklif → seçim). Sepet/stok/kargo yok |
| K4 | Tedarikçi hesabı belge doğrulamasından geçmeden havuzda görünmez (vergi levhası / oda kaydı + kimlik); SiteEksen onaylar. Ücretsiz paket dahil |
| K5 | Paketler: **Ücretsiz** (listelenir, talep ücreti yüksek, telefon vitrinde görünmez) · **Ücretli** (üst sıra, rozet, düşük talep ücreti / ayda X dahil talep, yeni taleplerde **anında SMS + öncelik penceresi**, telefon vitrinde görünür) |
| K6 | Önceden yüklenen bakiye (iyzico ile kart). Paket aidatı ve talep ücreti bakiyeden düşer; borç oluşmaz. Geçersiz talep iadesi yalnız platform onayıyla bakiyeye. Bakiye başka amaçla harcanamaz, çekilemez; üyelik sona ererse kalan bakiyeyi platform elle (havale) iade eder ve kaydeder |
| K7 | Yakınlık: her işletmenin adresi + harita konumu + hizmet alanı (km yarıçap / tüm il / Türkiye geneli). Sitenin koordinatı yoksa ilçe eşleşmesi yedek |
| K8 | Sakin: mevcut sakin uygulamasında "Usta & Hizmet" sekmesi. Yönetim: panel + yönetici uygulamasında "Teklif topla" |
| K9 | Talep en fazla 4 tedarikçi hesabı tarafından kabul edilir. Ücretli paketler yeni talebi ilk N dakika (platform ayarı, ör. 30 dk) tek başına görür ve SMS alır, sonra bütün uygun tedarikçiler görür. Talep süresinde (platform ayarı, ör. 72 saat) dolmazsa kapanır, alıcıya bildirilir |
| K10 | Uygulama içi mesaj; ücret ödenince alıcının adı, telefonu (gizlemediyse) ve site adresi açılır; daire numarası mesajla paylaşılır |
| K11 | Puan/yorum yalnız platformda teklifi seçilip tamamlanan işe. Tedarikçi "tamamlandı" der, alıcı onaylar ya da itiraz eder; alıcı 7 gün yanıt vermezse iş kendiliğinden tamamlanır. Yorumu alıcı yazar, tedarikçi yanıtlar |
| K12 | Yönetim alımında teklif karşılaştırma → seçilen teklif tek tıkla onay bekleyen gider kaydı ya da önceden doldurulmuş sözleşme formu; karşılaştırma kurul ve denetçiye açık |
| K13 | Gelir paylaşımı yok (site/yönetim şirketi pay almaz) |
| K14 | Talep ücreti **kategoriye göre sabit**. Site alımları kendi kategorilerindedir (ör. "Daire temizliği" sakin, "Site temizliği" yönetim); her kategori kimin talep açabileceğini bilir. Fiyatlar platform panelinden yönetilir, koda gömülmez; paket indirimi uygulanır |
| K15 | Tedarikçi arayüzü: mevcut Next.js panelinde ayrı `/tedarikci` alanı (web, telefona uyumlu) + **SiteEksen Tedarikçi** Flutter uygulaması (Android; iOS için Apple geliştirici hesabı gerekir). Platform için `/platform` alanı ve `PLATFORM_ADMIN` rolü |
| K16 | Bir tedarikçi hesabı **birden çok işletme/şube** kaydeder: her işletmenin adresi, konumu, hizmet alanı, kategorileri, hizmet/ürün kalemleri, telefonu ve puanı ayrıdır. Paket, bakiye ve hesap doğrulaması hesap düzeyindedir |
| K17 | Her işletme hizmet/ürün kalemlerini tanıtır: ad, açıklama, fiyat aralığı ya da "teklifle", birim, fotoğraf. Sakin havuzda bunları görür |

### Akış (sakin talebi, uçtan uca)
1. Sakin "Usta & Hizmet" → havuza göz atar (yakındaki işletmeler, hizmetleri, fiyat aralıkları, puanları) ya da doğrudan kategori seçer →
   açıklama + fotoğraf + zaman + "telefonum gizli kalsın". Göndermeden önce "yakınınızda bu kategoride N onaylı işletme var" görür (0 ise talep
   açılmaz, bunu söyler). KVKK onayı: "talebim ve iletişim bilgim, kabul eden en fazla 4 tedarikçiyle paylaşılır".
2. Eşleşen tedarikçiler (önce ücretli paket: SMS + öncelik penceresi; sonra herkes) maskeli önizleme görür: kategori, ilçe, mesafe, açıklama,
   fotoğraf, "telefon gizli mi", **kabul ücreti**. Bakiyesi yetmeyen de görür, "bakiye yükle" yönlendirmesi alır.
3. Tedarikçi "Kabul et" → aynı işlemde (dahil talep hakkı varsa önce o, yoksa bakiye) ücret düşülür + kabul sayısı artar (4'ü aşamaz;
   bir hesap aynı talebi bir kez kabul eder, birden çok şubesi uygun olsa da). Alıcı bilgileri açılır, mesajlaşma başlar.
4. Tedarikçi teklif verir (tutar, açıklama, geçerlilik). Alıcı teklifleri yan yana görür, birini seçer; diğerlerine "başka teklif seçildi" gider.
   Alıcı hiçbirini seçmeden talebi kapatabilir; kabul ücretleri iade edilmez (müşteri adayı teslim edilmiştir), itiraz yolu açıktır.
5. İş biter → tedarikçi "tamamlandı" → alıcı onaylar ya da itiraz eder (ya da 7 gün sonra otomatik) → alıcı puan ve yorum yazar (işletmeye).
6. Geçersiz talep (sahte, yanlış kategori, alıcıya ulaşılamıyor) bildirimi → platform inceler → onaylarsa ücret bakiyeye (dahil talepse hak geri).

Vitrinden **"bu işletmeye gönder"**: talep yalnız o işletmeye gider (dört kişilik kota ve öncelik penceresi uygulanmaz), kabul ücreti aynıdır.

### Sızıntıya karşı önlemler
- Ücret, alıcı bilgisi açılmadan önce alınır; anlaşma dışarıda yapılsa da gelir alınmıştır.
- Alıcının telefonu ve adresi ücretten önce görünmez. Açıklama metnindeki telefon/e-posta kalıbı otomatik gizlenir (fotoğraf denetlenmez; şikâyetle platform kaldırır).
- Ücretsiz paketteki işletmenin telefonu vitrinde görünmez: sakin ona talep açarak ulaşır (tedarikçi kabul ücretini öder). Vitrinde telefon
  göstermek ücretli paketin hakkıdır (abonelikle ödenmiştir). Hizmet kalemlerinin açıklamasında da telefon/e-posta kalıbı gizlenir.
- Puan, "doğrulanmış iş" sayısı ve sıralama yalnız platformda tamamlanan işlerle büyür.
- Talepleri yalnız doğrulanmış site sakinleri ve yöneticileri açabilir (tedarikçiye sunulan değer budur). Sakin başına günlük talep sınırı (platform ayarı).

### Çıkar çatışması
Bir sitede yönetim görevi (property_roles) olan kişi aynı zamanda tedarikçiyse, o sitenin **yönetim** taleplerini göremez ve kabul edemez.

## Teknik tasarım

### Kimlik ve roller (`services/identity`)
- Yeni platform rolleri (`users.roles`): `SUPPLIER`, `PLATFORM_ADMIN`. Roller **eklenir**, birbirini dışlamaz: aynı kişi bir sitede sakin/yönetici
  ve aynı zamanda tedarikçi olabilir. `/dashboard` erişimi bugünkü gibi site rollerine bağlı kalır; `/tedarikci` SUPPLIER, `/platform` PLATFORM_ADMIN ister.
- Tedarikçi kaydı: önce telefon + SMS kodu (her numaraya aynı yanıt; kodu doğrulayan numaranın sahibi olduğunu kanıtlamış olur), **ancak
  ondan sonra** hesap durumu açıklanır: yeni numara → şifre belirler; kayıtlı ve etkin hesap → mevcut şifresini girer, hesabına SUPPLIER eklenir
  (`users.phone` UNIQUE, ikinci hesap açılmaz); kayıtlı ama hiç etkinleştirilmemiş hesap → kodla şifre belirler (mevcut etkinleştirme).
- Site rolü olmayan (yalnız SUPPLIER/PLATFORM_ADMIN) kullanıcı da giriş yapabilir; jetonda site kapsamı olmaz. Bugünkü giriş/aktif site akışı
  bu durumda hata vermemeli (doğrulanacak).
- Yetki kontrolü servis tarafında (rol + hesap/işletme durumu); gateway bugünkü gibi yalnız kimliği doğrular ve başlıkları siler.
- Panel: `admin/src/lib/rbac.ts` `ROUTE_ROLES` + `admin/src/middleware.ts`; tedarikçi giriş/kayıt sayfaları `/tedarikci/giris`, `/tedarikci/kayit` (bugünkü `/login` girişte `/dashboard`'a yönlendirdiği için ayrı).

### Yeni servis `services/marketplace` (port 8111, gateway üzerinden)
Gateway yönlendirmesi `cmd/gateway/main.go`; Dockerfile/compose/k8s/CI `python3 backend/scripts/gen-deploy.py` ile üretilir.

Tablolar (tek migration `076_marketplace.sql`):
- `mp_settings` (öncelik penceresi dk, talep süresi saat, otomatik tamamlama gün, sakin günlük talep sınırı) — platform yönetir
- `mp_categories` (ad, üst kategori, talep ücreti kuruş, kim açabilir: SAKİN/YÖNETİM/İKİSİ, aktif mi)
- `mp_packages` (ad, aylık ücret, talep indirimi %, dahil talep, aylık SMS hakkı, öncelik penceresi hakkı, vitrinde telefon, sıralama ağırlığı)
- `mp_supplier_accounts` (user_id, ticari unvan, vergi no, durum: TASLAK/İNCELEMEDE/ONAYLI/ASKIDA, paket, paket yenileme tarihi,
  dönemde kalan dahil talep ve SMS hakkı) + `mp_account_documents` (`pkg/storage`; vergi levhası, kimlik, oda kaydı; onay/ret, gerekçe, onaylayan; erişim kaydı)
- `mp_businesses` (account_id, işletme adı, telefon, adres, il/ilçe, `latitude/longitude`, hizmet alanı: KM/İL/TÜRKİYE + yarıçap, durum:
  TASLAK/YAYINDA/KAPALI, puan özeti) + `mp_business_categories` + `mp_business_services` (ad, açıklama, fiyat alt/üst kuruş ya da "teklifle", birim, fotoğraf).
  Vitrin görünümü `mp_business_public` (yalnız onaylı hesabın yayındaki işletmeleri; telefon yalnız paket hakkı varsa; vergi no, belge, bakiye yok)
- `mp_wallet_ledger` (hesap düzeyinde, yalnız ekleme, değiştirilemez: yükleme, paket aidatı, talep ücreti, dahil talep kullanımı (0 TL), iade, kapanış iadesi (elle havale kaydı); bakiye = toplam; `pkg/money` kuruş)
- `mp_topups` (iyzico; `pkg/iyzico` Initialize/Retrieve, finans servisindeki kart ödeme dönüş akışı örnek). Dönüş ucu kimliksizdir (iyzico çağırır);
  sonuç yalnız sunucudan `Retrieve` ile doğrulanır, istemcinin söylediğine güvenilmez
- `mp_requests` (property_id, açan user_id, alıcı tipi SAKİN/YÖNETİM, kategori, açıklama, fotoğraflar, zaman, telefon gizli mi, hedef işletme (doğrudan taleplerde),
  durum: AÇIK/DOLDU/KAPANDI/İPTAL, son tarih)
- `mp_request_contacts` (request_id, ad, telefon, site adresi) — ayrı tablo; RLS ile yalnız alıcı tarafı ve **kabul edip ödemiş** hesap okur
- `mp_request_dispatch` (request_id, account_id, eşleşen en yakın business_id, mesafe, görünür olma zamanı, bildirim gönderildi mi, kabul zamanı, ücret ledger_id);
  hesap başına tek satır; 4 sınırı satır kilidiyle
- `mp_offers`, `mp_messages`, `mp_jobs` (seçilen teklif, tamamlandı/onay/itiraz/otomatik), `mp_reviews` (işletmeye), `mp_disputes`

Zamanlayıcı (`cmd/scheduler`, dakikalık): öncelik penceresi bitince ücretsiz tedarikçilere bildirim, talep süresi dolumu, otomatik tamamlama,
paket aidatı (bakiyeden; yetmezse ücretsize iniş), yarıda kalan bakiye yüklemelerinin uzlaştırılması.

RLS: alıcı tarafı tablolar mevcut site kapsamında (`app.property_id`, `pkg/dbscope`). Site kapsamı aynı sitedeki bütün sakinleri kapsadığından
sakinin yalnız **kendi** talebini görmesi servis katmanında ayrıca denetlenir (yönetim talepleri yalnız yönetim rollerine). `pkg/dbscope`'a
**tedarikçi kapsamı** (`app.supplier_account_id`) ve **platform kapsamı** eklenir. Politika: tedarikçi `mp_requests`'i yalnız kendisine dispatch ile
gönderilmişse ve görünür olma zamanı geldiyse görür; `mp_request_contacts`'ı yalnız kabul etmişse. `mp_business_public` her oturumlu kullanıcıya okunur.
verify-stack'teki RLS tablo sayısı ve RLS dışı liste kontrolü güncellenir.

Bildirim: `notifications.property_id` bugün NOT NULL ve `notifications_active_property` tetikleyicisine bağlı. Talep kaynaklı tedarikçi bildirimleri
talebin site kimliğini taşır; site dışı bildirimler (belge onayı, bakiye azaldı, paket yenilenemedi) için tabloya **tedarikçi alıcılı, sitesiz**
kayıt imkânı ve buna uygun RLS politikası eklenir (076 içinde); `pkg/notify` `Message`'a sitesiz gönderim eklenir. Bugünkü tekilleştirme indeksi
`(property_id, dedupe_key)`; `property_id` boşken PostgreSQL boşları farklı sayar → sitesiz kayıtlar için ayrı tekil indeks. Konular:
`market.request.new`, `market.offer.new`, `market.message`, `market.offer.accepted/declined`, `market.job.completed`, `market.review`,
`market.wallet.low`, `market.package.downgraded`, `market.supplier.approved/rejected`, `market.business.approved/rejected`, `market.dispute.resolved`,
`market.request.expired`. Alıcı kümeleri `pkg/notify/audience.go`'da. Tedarikçi kanalları: uygulama içi + e-posta herkese; SMS yalnız ücretli
pakette ve paketin aylık SMS hakkı kadar. Mobil uygulamada anlık bildirim Firebase'e (B11) bağlı; o gelene kadar uygulama açıldığında günceller.

Eşleşme: `properties.latitude/longitude` eklenir (panel site ayarlarında harita ile). Bir hesabın uygun işletmeleri arasından en yakını alınır.
Koşullar: kategori + kim açabilir, hesap ONAYLI, işletme YAYINDA, hizmet alanı (km: Haversine; il: aynı il; Türkiye geneli: her yer; site
koordinatı yoksa km yerine ilçe), çıkar çatışması yok. Bakiye eşleşmede **aranmaz**, kabul anında aranır (bakiyesi yetmeyen de görür, yüklemeye
yönlendirilir). Talepten sonra onaylanan tedarikçiler o talebe eklenmez. Vitrin sıralaması: paket ağırlığı, mesafe, puan, yanıt hızı; tedarikçi
kendi sırasının nedenini görür.
Harita: Leaflet (panel), `flutter_map` (mobil). Adres elle yazılır, konum iğneyle seçilir (ücretli adres çözümleme yok). Geliştirmede
OpenStreetMap karoları; OSM'nin kullanım politikası ticari ve yoğun kullanımı yasakladığı için yayında bir karo sağlayıcısı gerekir (M0).

Yönetim alımı: seçilen teklif → `services/expense`'te **onay bekleyen gider** (`status='PENDING'`, mevcut onay akışı; vergi no `vendor_tax_id`'ye
dolar, tedarikçi bağlanır) ya da `services/contract` sözleşme formu teklif bilgileriyle **önceden doldurulmuş** açılır, yönetici kaydeder
(sözleşme tablosunda taslak durumu yok; şema eklenmez). Çağrılar kullanıcının jetonuyla gateway üzerinden yapılır, yetkiyi mevcut servisler denetler.
Karşılaştırma tablosu kurul/denetçiye okunur.

### Arayüzler
- **Tedarikçi web** `admin/src/app/tedarikci/...` (ayrı layout/menü, `admin/src/components/ui/kit.tsx`): kayıt, hesap ve belgeler, işletmelerim
  (her biri: profil, adres + harita + hizmet alanı, kategoriler, hizmet/ürün kalemleri, telefon), paket, bakiye yükle/hareketler, gelen talepler
  (maskeli önizleme + ücret), kabul, teklif, mesajlar, işler, puanlar, faturalar.
- **SiteEksen Tedarikçi uygulaması** `supplier_app/` (Flutter; `mobile/`, `admin_app/` yapısı, `file_opener`, web derlemesi örnek): web panelinin aynısı.
- **Platform** `admin/src/app/platform/...`: hesap belge onayı, işletme yayın onayı, kategori ve ücretler, paketler, `mp_settings`, itiraz/iade,
  kapanış iadesi kaydı, şikâyet ve yorum denetimi, gelir raporu.
- **Sakin uygulaması** `mobile/lib/features/usta_hizmet/`: yukarıdaki akış + havuzda göz atma (işletme, hizmetler, fiyat aralığı, puan) ve "bu işletmeye gönder".
- **Yönetim** panel `/dashboard/usta-hizmet` + yönetici uygulaması: teklif topla, karşılaştır, gidere/sözleşmeye çevir.

## Aşamalar (MVP: tedarikçi + platform + sakin, ardından yönetim)

0. **İşletme ve hukuk (kullanıcı):** şirket/vergi, ETBİS (6563 aracı hizmet sağlayıcı), e-fatura/e-arşiv entegratörü, iyzico sözleşmesinin bu
   tahsilata uygunluğu, tedarikçi üyelik sözleşmesi, KVKK metinleri, paket ve ücret tutarları, harita karo sağlayıcısı, Apple hesabı (iOS istenirse).
1. Kimlik. 2. Servis + migration 076. 3. Tedarikçi hesabı, belgeler, işletmeler, hizmet kalemleri. 4. Platform paneli.
5. Bakiye ve paket. 6. Talep, eşleşme, kabul. 7. Teklif, mesaj, iş, puan, iade, denetim, gelir raporu, saklama.
8. Sakin "Usta & Hizmet". 9. SiteEksen Tedarikçi uygulaması. 10. Yönetim alımı. 11. Tarayıcı test planı. 12. Yayın öncesi.
13. Sonra: platform içi ödeme + komisyon, kart iadesi altyapısı, push (Firebase), iOS, öne çıkarma reklamı.

## Doğrulama

- `bash backend/scripts/verify-stack.sh` yeni senaryolar: tedarikçi kaydı → belge → onay → işletme yayını; mevcut sakin telefonuyla kayıtta hesap birleşmesi;
  ücretsiz tedarikçi öncelik penceresinde talebi göremez; ücretten önce iletişim bilgisi dönmez; aynı anda 5 kabulde biri reddedilir; iki şubesi uygun hesap
  bir kez kabul eder; bakiye yetmezse kabul yok; platform onaylı iade; paket aidatı yetmezse ücretsize iniş; çıkar çatışması; RLS (tedarikçi başkasının
  talep/teklifini, site A sakini site B talebini, aynı sitedeki komşusunun talebini göremez); sahte iyzico ile bakiye yükleme; sitesiz bildirim ve tekilleştirme.
- `bash backend/scripts/verify-mobile.sh`: `supplier_app` + sakin uygulamasındaki yeni sekme.
- Panel: `cd admin && npx tsc --noEmit && npm run lint && npm run build`.
- Arayüz: test ortamında (`test-ortami.sh`) headless tarayıcıyla tıklanarak; her aşama kendi test verisini ekler; sonda tarayıcı test planına yeni bölüm.

## Yapılacaklar

Uygulama maddeleri ve kanıt koşulları: `tasks/todo.md` → "FAZ M — Usta & Hizmet".

## Kurguyla karşılaştırmada düzeltilenler (son tur)

İstenmeden eklenip geri alınanlar ya da kullanıcıya sorularak karara bağlananlar:
1. **Öncelik penceresi** (bir varsayıma dayanarak eklenmişti) → kullanıcı kararıyla kaldı: SMS + öncelik penceresi.
2. **Ücretin alıcı tipine göre ayrılması** (kullanıcı "kategoriye göre sabit" demişti) → geri alındı; site alımları ayrı kategoriler, kategori kimin açabileceğini bilir.
3. **72 saat yanıtsızlıkta otomatik iade** (istenmemişti) → kaldırıldı; iade yalnız platform onayıyla.
4. **Kart iadesi altyapısı** (bakiye iadesi kuralı büyütülmüştü) → ilk sürümde platformun elle (havale) iadesini kaydetmesi; kart iadesi sonraki aşama.
5. **Vitrinde telefon yalnız ücretli pakette** → kullanıcı kararıyla kaldı.

Kurguda olup planda eksik ya da çelişkili olanlar:
6. **Birden çok dükkan** ("dükkanlarını kaydedecekler") → hesap + işletmeler modeli; paket/bakiye/doğrulama hesapta, adres/konum/hizmet/puan işletmede;
   aynı talebi bir hesap yalnız bir kez kabul eder (iki şubesi uygun olsa da).
7. **Hizmetlerin kaydı** ("hizmetlerini de kaydedecekler") → hizmet/ürün kalemleri (ad, açıklama, fiyat aralığı, birim, fotoğraf); sakin havuzda görür.
8. **"Konum bağımsız"** → hizmet alanına "Türkiye geneli" eklendi (kargoyla mal satan tedarikçi).
9. **Doğrudan talep çelişkisi** (hem "4 kotadan sayılır" hem "yalnız o tedarikçiye gider") → yalnız o işletmeye gider, kota ve pencere yok.

## Ayrıca kayıtlı bekleyen işler (`tasks/todo.md`)
Bildirimsiz akışlara bildirim (06 E7), yönetici uygulaması küçük arayüz (06 E8), görevli ana sayfa yetki kartları, belge erişim kaydı FK,
tarayıcı testi sonuçlarının düzeltilmesi, B10, B11, T5b, S-19.
