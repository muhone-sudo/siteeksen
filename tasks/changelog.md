# CHANGELOG

Projedeki tüm önemli değişiklikler bu dosyada takip edilir.

> **Not (2026-09-09):** Bu dosya tek doğruluk kaynağıdır; kökteki `CHANGELOG.md` yalnızca buraya işaret eder.
> Aşağıdaki **2026-09-09 öncesi** girdiler, 2026-09-09 denetiminde iddialarının önemli bölümü yanlış
> çıktığı için **güvenilmez** kabul edilmelidir (ayrıntı: `tasks/audit-raporu.md`). Girdiler tarihsel kayıt
> olarak korunmuştur ama "tamamlandı" ifadeleri kanıtlanmamıştır.
> Bundan sonraki her girdi `tasks/dogrulama-politikasi.md` uyarınca **kanıt satırı** taşır.

---

## [Unreleased]

### 2026-10-26 — FAZ H.6 / H.7 / H.8: SAKİN UYGULAMASI, PANEL EKLEMELERİ VE YÖNETİCİ MOBİLİN PANELLE TAM EŞİTLİĞİ (kullanıcı kararları K3, K4) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1423/1423** (adım 67: kiracının işletme projesi malik görünümüne 403 alması — önceki
> adımların bu hesaba verdiği vekillik sınama süresince kapatılarak deterministik yapıldı —, malikin yalnız tebliğ
> edilmiş projeleri ve kendi bölüm payını görmesi, `OWNER_PLAN_OBJECTIONS` kapalıyken görüşün 409, açıkken 201);
> `verify-mobile.sh` 10/10 (yönetici uygulaması 35 test: yeni `parity_test.dart` form çıktısı, toplu bölüm ayrıştırma ve
> menüdeki her yolun yönlendiricide karşılığı); iki uygulamanın **debug APK'sı derlendi**; panel `tsc`/`lint`/`build`
> temiz; harita aracı: **panelin çağırdığı her uç yönetici uygulamasında da çağrılıyor (fark 0, okuma dahil)**.
> Gerçek cihazda elle denenmedi.

- **H.6 sakin uygulaması:** ödeme geçmişi, araçlarım, ziyaretçilerim (iptal, kod yenileme), sayaçlarım, kargo kanıtı,
  tadilat geri çekme, memnuniyet anketi, ilan ve anket yorumları, tüm cihazlardan çıkış, okundu bilgisi, işletme projesi
  (bölüm payı + seçenekli görüş/itiraz; yeni `GET /governance/my-budgets[/:id]`). Sayaç türü etiketleri backend
  türlerine (`HEAT`, `WATER_COLD`, …) düzeltildi — önceki etiketler hiç eşleşmiyordu.
- **H.8 panel:** demirbaş kategori/zimmet, stok kategorisi + gerekçeli pasife alma + kalem hareket geçmişi, sayaç pasife
  alma, kamera düzenleme, yıllık personel maliyeti, plaka sorgu, kargo imza/fotoğraf, ilan yorumu görme/gizleme, anket
  yorumları, ziyaretçi kodu yenileme (yönetim + görevli — backend `hasSecurityScope`; önceki "yalnız kaydı açan" notu
  yanlıştı, Ders 57), giriş sayfasındaki ölü bağlantı `/activate`'e çevrildi.
- **H.7 yönetici uygulaması:** ortak altyapı `core/widgets/forms.dart` (alan tanımından form: metin, şifre, sayı, tarih,
  tarih-saat, saat, seçim, çoklu seçim, anahtar, dosya; boş isteğe bağlı alan gönderilmez; indir-aç; satır menüsü;
  `file_picker` — sakin uygulamasında zaten kullanılan paket). 13 yeni ekran (bağımsız bölümler, görevlendirmeler, KVKK,
  tadilat, kural ihlali, acil durum, sigorta, belge arşivi, bildirim merkezi, NPS, karbon ayak izi, site ayarları,
  hesabım) ve mevcut ekranlara panelin bütün işlemleri: yönetişim (proje hazırla/bildir/kesinleştir/tahakkuk, itiraz,
  toplantı/çağrı/hazirun/oy/karar, hazirun cetveli, defter kaydı/kapatma, dava, ortak alan kirası), finans (ters kayıt,
  dekontlar, tahsilat defteri ve zincir doğrulama, alacak dekontu, banka ekstresi yükle/eşleştir/daireye işle/yok say,
  devir bakiyesi, gecikme tazminatı), sakinler (davet, toplu ekleme, kiracılık bitişi yönetim yolu, telefon, kilit,
  sıfat/ayrılış), personel (ilişik kesme, izin, bordro gir/öde/iptal, yıllık maliyet, SGK/MUHSGK takvimi, personel
  kartı — TCKN/IBAN maskeli), operasyon (araç, plaka, geçiş cihazları, tesis ekle/düzenle, devriye noktası/rotası,
  demirbaş ve stok tam yönetim, sayaç ekle/değiştir/pasife al, paylaştırma, pusula ve itiraz), süresi dolanları kapat
  (ilan, sözleşme). Site değişince yeni jeton alınır (`ApiClient.refreshSession`).
- **Harita aracı:** `openDownload`/`optionsFrom` çağrıları tanınıyor; istemcideki dinamik yollar açık yazıldı (Ders 58).

### 2026-10-26 — FAZ H.5: DEVRİYE — QR + GPS ZORUNLULUĞU, KONUM İZİ, RAPOR VE HARİTA (migration 075, kullanıcı kararı K2) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1419/1419** (adım 66: nokta konumu ≤20 m hassasiyet ve sahte konum reddi, muafiyet gerekçesi,
> sakinin nokta değiştirememesi, yönetimin QR değerini görmesi, ~500 m uzaktan QR okutmanın TOO_FAR ile reddi, sahte konum /
> düşük doğruluk / konumsuz / tanınmayan QR reddi, yanında kabul, 500 m'yi saniyeler içinde geçen okutmanın şüpheli işaretlenmesi,
> muaf noktada elle seçme reddi ve QR'la kabul, QR yenilenince eski baskının geçersizliği, 7 red + 3 kabul kanıtı, kanıtın
> değiştirilememesi, iz kaydı ve 101 nokta → 413, tur raporu istatistikleri ve kesinti, sakine rapor 403, kapanmış turda iz 409,
> dönem raporu, çapraz site boş; eski devriye adımı konumla güncellendi); `verify-mobile.sh` 10/10; yönetici ve sakin uygulaması
> **debug APK derlendi**; panel `tsc`/`lint`/`build` temiz. Gerçek telefonla sahada denenmedi.

- **Sorun:** QR'ın fotoğrafını çeken görevli noktaya gitmeden okutabiliyordu. **Çözüm (sunucuda):** okutma anındaki konum noktanın
  konumuyla karşılaştırılır (yarıçap + ölçüm doğruluğu); sahte konum (`isMocked`), 50 m'den kötü doğruluk, konumsuz istek ve
  güncel olmayan QR reddedilir; her deneme (red dahil) `patrol_scan_attempts`'e kanıt olarak yazılır; fiziksel olarak imkânsız
  hız şüpheli işaretlenir. GPS çekmeyen kapalı alan için gerekçeli "konum muaf" nokta (yalnız QR, raporda ayrıca gösterilir).
- **075:** `patrol_checkpoints` + `radius_m`, `location_check`, `exempt_reason`, `qr_token` (yeniden üretilebilir), ölçüm bilgisi;
  `patrol_track_points` (yalnız açık tur boyunca; 1 yıl saklama, zamanlayıcı `patrol.track.purge`); `patrol_scan_attempts`.
- **Uçlar:** `POST /patrols/:id/scan` (QR ya da nokta + konum), `POST /patrols/:id/track`, `GET /patrols/:id/report`,
  `GET /patrol-reports`, `PATCH /patrol-checkpoints/:id`, `POST /patrol-checkpoints/:id/location`, `/rotate-qr`.
- **Yönetici uygulaması** (`mobile_scanner`, `geolocator`, `flutter_map` — kullanıcı onaylı): "Devriye yürüt" (rota seç, başlat,
  QR okut, listeden seç, sorun bildir, bitir; ekran açıkken 30 sn'de bir iz), "Nokta kurulumu" (konumu buradan al ≤20 m,
  yarıçap, muafiyet, QR yenile), "Raporlar" (dönem özeti, tur haritası: iz, nokta yarıçapları, kabul/red/şüpheli işaretleri).
  Kamera ve konum izinleri manifestte.
- **Panel** (`qrcode`, `leaflet`/`react-leaflet` — kullanıcı onaylı): nokta konum/yarıçap/muafiyet, QR yazdır (tek/tümü),
  QR yenile; `/dashboard/patrol/reports` dönem özeti, tur ayrıntısı ve haritası.
- **APK derlemesi düzeltildi:** yönetici uygulaması hiç derlenmiyordu — kullanılmayan `open_file` ile `open_filex` aynı sınıfı
  iki kez getiriyordu (`open_file` kaldırıldı) ve `flutter_local_notifications` core library desugaring istiyordu (açıldı).
  Kullanılmayan `package_info_plus` 5 → 8 (yeni paketlerle uyum).
- KVKK aydınlatma metnine görevli konum verisi (2.7), işlem kaydı ve saklama süreleri eklendi.

### 2026-10-26 — FAZ H.4: IoT SENSÖRLERİ TAMAMLANDI (migration 074, kullanıcı kararı K1) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` adım 65 (1419/1419 içinde): sensör tanımı ve anahtarın bir kez gösterilip yalnız özetinin
> saklanması, eşiksiz sayısal sensör reddi, sakine 403, cihaz okuması ve yanlış anahtar reddi, üst eşik aşımında TEK alarm ve
> işletme ekibine bildirim (sakine gitmez), normale dönüş işareti (alarm açık kalır), onay/çift onay 409/notsuz kapatma 400,
> alarmın silinememesi, su kaçağı tetiği, sinyal kesilince bekçinin alarmı ve bildirimi (tek), sinyal gelince normalleşme,
> anahtar yenileme, çapraz site boş. Gerçek donanımla denenmedi (sahte cihaz `curl`).

- **Neden yarım kalmıştı:** ilk sürüm (2026-02-01) MongoDB varsayımıyla mock'tu; MongoDB kurulmadığı için 2026-09-14'te 501'e
  çevrilmişti. PostgreSQL ile tamamlandı: `sensors`, `sensor_readings`, `sensor_alerts` (RLS'li), `sensor_ingest`,
  `sensor_watch_property_ids`.
- Türler: su kaçağı, sıcaklık, nem, duman, gaz, elektrik kesintisi, depo seviyesi, asansör arızası, kapı açık, diğer. Cihaz
  `POST /api/v1/public/sensors/data` (`X-Device-Key`). Alarm: üst/alt eşik, tetik, sinyal kesilmesi (bekçi, `SENSOR_WATCH_INTERVAL`);
  `iot.alert` / `iot.offline` → Operations. Okumalar 365 gün (zamanlayıcı `sensor.purge`).
- Panel `/dashboard/sensors` ve yönetici uygulaması "Sensörler": liste, durum, 24 saat geçmişi, tanım/düzenleme, anahtar yenileme,
  alarm onayı/kapatma (not zorunlu).

### 2026-10-26 — FAZ H.2/H.3: BİLDİRİM OKUNDU BİLGİSİ VE İŞLEM KAYDI (migration 073, kullanıcı kararı K5) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1383/1383** (yeni adım 64: şema ve yetkiler, kapsamsız listenin boş dönmesi, başarısız/başarılı
> giriş kaydı ve şifrenin hiçbir kayda yazılmaması, okundu/başkasının bildirimi 404/tümünü okundu say, okundu kaydının
> değiştirilememesi, varsayılan STANDART, STANDART'ta etkinlik alınmaması, sakinin düzeyi değiştirememesi (403), TAM'da
> kabul ve bilinmeyen olay reddi, 51 olay → 413, KAPALI'da sıradan okumanın yazılmayıp hassas okuma ve yazmanın yazılması,
> görüntüleme yetkisi, kaynak süzgeci, CSV ve dışa aktarma kaydı, çapraz site boş, saklamanın yalnız CLIENT silmesi ve
> 30 gün altı reddi); `verify-mobile.sh` 10/10; panel `tsc`/`lint`/`build` temiz.

- **073:** `notification_reads` (RLS'li, yalnız ekleme); `audit_logs`'a `source` (API/CLIENT/SYSTEM), `event`, `screen`,
  `details`. Uygulama rolü `audit_logs`'u yine doğrudan okuyamaz: okuma aktif siteyle sınırlı `audit_log_list` /
  `audit_log_stats`, silme yalnız istemci etkinliği için `audit_log_purge_client(30-730 gün)` işlevleriyle.
- **Bildirim kutusu:** `GET /notifications` okundu zamanı, `channel`, `unread` süzgeci; `GET /notifications/unread-count`,
  `POST /notifications/:id/read` (başkasınınki 404), `POST /notifications/read-all`. Panel üst bar zili (okunmamış sayısı,
  son 10, tümünü gör) + `/dashboard/inbox`; yönetici mobil "Bildirimlerim" (yan menü rozeti); sakin uygulaması okundu
  işareti, "tümünü okundu say", alt menü rozeti; kutu artık yalnız uygulama içi kopyayı listeler.
- **İşlem kaydı düzeyi** (`ACTIVITY_LOG_LEVEL`: KAPALI / STANDART / TAM, yalnız MANAGER değiştirir): KAPALI'da da yazma
  işlemleri, 403, kişisel veri okumaları ve giriş/çıkış tutulur (KVKK m.12). Kimlik servisi giriş başarılı/başarısız
  (maskeli telefon, 401 dahil), çıkış, etkinleştirme ve şifre sıfırlama isteğini yazar. TAM düzeyde panel, sakin ve
  yönetici uygulamaları ekran/menü olaylarını toplu `POST /activity` ile gönderir (olay türü listesi, istek başına 50,
  kişi başı dakikada 300). Saklama `ACTIVITY_LOG_RETENTION_DAYS` (varsayılan 180), zamanlayıcı `activity.purge`.
- **Görüntüleme:** `GET /audit-logs` (süzgeçler, sayfalama), `/audit-logs/stats`, `/audit-logs/export` (CSV); panel
  `/dashboard/audit`, yönetici mobil "İşlem kayıtları" — MANAGER ve AUDITOR; görüntüleme ve dışa aktarma da kayda geçer.
- **Düzeltilen hata:** denetim kaydı istek bağlamıyla yazılıyordu; istemci bağlantıyı erken kapatınca (indirme yarıda
  kesilince) kayıt `context canceled` ile düşüyordu. Artık istekten bağımsız bağlamla (5 sn) yazılıyor.
- `OWNER_PLAN_OBJECTIONS` ayarı eklendi (K3; uygulaması FAZ H.6 S12'de).

### 2026-10-26 — FAZ H.1: KULLANILMAYAN 501 MODÜLLERİN KONTROLLÜ KALDIRILMASI (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1352/1352** (kaldırılan modüllerin kontrolleri çıktı; yerine "dizin yok", "gateway öneki yok",
> credentials ve skor → 404 kontrolleri eklendi); `verify-mobile.sh` 10/10; panel `tsc`, `lint`, `build` temiz;
> `gen-deploy.py --check` 25 servis; `check-gateway-routes.py` tutarlı.

- `meeting_wizard` servisi kaldırıldı (governance'ta aynı iş var; karar defterinin tekliği, KMK m.32). Gateway öneki,
  `gen-deploy.py` (compose/k8s/CI yeniden üretildi, 25 servis), dev-up metni, `.gitignore`, verify-stack adım 29,
  yönetici mobil ekranı ve rotası birlikte çıkarıldı. `meetings` tablosu (005) uygulanmış migration olduğu için duruyor.
- `settings /credentials*` (7) ve `/credentials-available-services` 501 uçları kaldırıldı. Panel sayfası yanlış bilgi
  veriyordu ("iyzico/SMS/e-posta bağlı değil"); yerine **Entegrasyon durumu** (`/dashboard/integrations`): gateway
  `GET /api/v1/integrations/status` bildirim kanallarını (`/notifications/summary`, yetki ve jeton iptali orada denetlenir),
  kart sağlayıcısını (finans `/health` → `card_payment`) ve dosya deposunu (`document /health`) birleştirir.
  Yönetici mobil ekranı aynı içeriğe döndü.
- `GET /esg/sustainability-score` kaldırıldı (uydurma bileşik skor üretilmez; verify-stack artık 404 bekliyor).
- verify-stack: panel doğrulamasındaki servis sayısı sabit 26 yerine `gen-deploy.py`'den okunuyor.
- `db-restore.sh`: canlı tablo listesi veritabanı harmanlamasıyla değil `sort` ile sıralanıyor (iki taraf farklı yerel
  ayarla sıralandığında `comm` "not in sorted order" diyip kontrolü düşürüyordu).

### 2026-10-26 — ÖZELLİK VE YETENEK HARİTASI (docs/ozellik-haritasi/, yalnız doküman)

> **Kanıt:** Rota listesi depodaki `check-gateway-routes.py` ile birebir (415/415). Çağrı → tablo/bildirim/yetki zinciri
> `go/types` ile çözüldü (isim tahmini yok). Mobil düğme sayımı ham `onPressed/onTap` sayısına eşit (sakin 154/154,
> yönetici 143/143). İstemci çağrılarından backend'de karşılığı olmayan kalmadı.

- Panel 48 sayfa / 289 eylem, sakin mobil 33 ekran / 168 eylem, yönetici mobil 45 ekran / 173 eylem; her eylem için uç,
  yetki, değişen tablolar + tetikleyiciler, bildirim (konu → alıcı), etkinin görüldüğü ekranlar.
- Bildirim kataloğu (54 uç), 11 zamanlanmış iş, 3 servis içi bekçi, 23 tetikleyici, arayüzsüz uçlar listesi.
- Bulgular (`05-arayuzsuz-uclar.md` 5.3): giriş sayfasında ölü bağlantı (`login/page.tsx:154`), yönetim için kişisel
  bildirim kutusu yok, CLAUDE.md'deki "panelde çıkış/rol denetimi yok" ifadeleri eskimiş.

### 2026-10-11 — KULLANIM HAKKI: KİRACILI DAİREDE KULLANIM İŞLEMLERİNİ KİRACI YAPAR (migration 072, altıncı tur D7) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1359/1359** (adım 63: kural tek işlevde — kiracılı dairede malik hayır, kiracı ve hane üyesi
> evet, boş dairede malik evet; talep: malik 422 (nedeniyle), kiracı ve hane üyesi 201, malik boş dairesi için 201; ziyaretçi:
> malik 403, hane 201, sakin başka daireye 403 (önceden açabiliyordu), malik boş dairesine ve yönetim her daireye 201; araç:
> malik 403, kiracı 201; kargo bildirimi kiracıya ve hane üyesine gitti, malike gitmedi). `verify-mobile.sh` 10/10.

- Kullanıcı kararı: devirden sonra malik o dairede kullanım işlemi yapmaz. 072 `resident_can_use(bağ)`: kiracı ve hane üyesi;
  malik/vekil yalnız kiracı yokken (boş dairede her şey malike düşer — TBK m.301 kiracının kullanma hakkı).
- Bağlananlar: talep, ziyaretçi ön kaydı, araç, kargo, rezervasyon, acil durum kartı ve yanıtı, sayaç, pusula ve itiraz, tüketim
  verisi (para içerenlerde hane üyesi hariç). `notify.UnitUsers` kargo ve ziyaretçi bildirimlerinde.
- **Düzeltilen açık:** sakin, ziyaretçi ön kaydını HERHANGİ bir daireye açabiliyordu (daire ilişkisi denetlenmiyordu).
- Kapsam dışı bırakılanlar ve gerekçeleri `tasks/todo.md` D7 maddesinde. Mobil uygulama sunucunun 403 nedenini gösteriyor.
### 2026-10-11 — MALİKİN GÖRÜNÜRLÜK POLİTİKASI (migration 071, altıncı tur D6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1353/1353** (adım 62: varsayılan en dar — kiracı politikayı görüyor, kiracılı dairede malik
> kiracıyı/haneyi, kiracı borç tutarını, daire taleplerini göremiyor; kiracı öneremiyor, gerekçesiz öneri 422, ikinci bekleyen
> 409, kurul üyesi olmayan yönetici onaylayamıyor, onaylanana kadar politika değişmiyor; kurul üyesi onaylayınca yürürlük ve
> kiracıya bildirim; açık politikada malik kiracıyı (hanesini değil), borç toplamını ve vadesi geçeni, talepleri (talep
> edenin kimliği/açıklaması olmadan) görüyor; zamanlayıcı kiracıya hatırlatma, malike ayrı uyarı, hane üyesine hiçbiri;
> kurul üyesi kendi önerisini onaylayamıyor, yürürlükteki politika değiştirilemiyor/silinemiyor). Adım 36: RLS 123 tablo.
> `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Kullanıcı kararları: malikin neyi göreceğini yönetim belirler (malik kiracıya baskı kurabilir); site genelinde tek
  politika, varsayılan en dar, değişiklik kurul üyesi onayı, kiracıya şeffaf. Seçenekler (V9): kiracının adı/maskeli telefonu,
  kiracı borcu toplamı, vadesi geçen borç + malike uyarı, daire talepleri.
- 071: `owner_visibility_policies` (öner → dört gözle onay; seçenekler ve öneren değiştirilemez; silme yok) ve
  `owner_visibility(site)` işlevi. Uygulama: kimlik (daire sakin listesi), finans (`GET /finance/tenant-debt-summary`),
  topluluk (`GET /requests/units/:id`), zamanlayıcı (`dues.overdue.tenant`). `notify.Tenants`, `notify.UnitOwners`.
- Panel Ayarlar → "Malik görünürlüğü" (öner, onayla/reddet, geri çek, geçmiş). Sakin uygulaması: "Malikin görebildikleri"
  ekranı; malikin daire ekranında kiracı borcu kartı ve daire talepleri (politikaya göre).
### 2026-10-11 — MALİ YÖNLENDİRME: BORCUN SORUMLUSU (migration 070, altıncı tur D5) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1348/1348** (adım 61: kiracılıkta tahakkuk eden kullanım borcu kiracılığa bağlandı, malik
> borcu bağlanmadı; kiracı yalnız kendi borcunu, malik yalnız malik borcunu görüyor; maliksiz dairenin malik borcu kiracıya
> yansımıyor; kiracı malik borcunu, malik kiracının borcunu ödeyemiyor (400); sorumlu sonradan değiştirilemiyor (tetikleyici);
> borçlu listesi sorumluya göre ayrıldı, maliksiz daire "Malik kaydı yok"; borcu yoktur — kiracının vadesi geçmiş kendi borcu
> engelledi, malikin talebinde kiracı borcu tutarsız bildirildi, ödenince kiracıya kiracılık kapsamlı belge (kimliksiz doğrulama
> kapsamı söylüyor), malike bütün daire belgesi; yeni borç bildirimi sorumluya gitti, maliksiz dairenin malik borcunda kimseye
> gitmedi; kiracılık bitince açık kullanım borcu malike göründü ve malik ödedi). `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- 070: `monthly_assessments.tenant_link_id` — kullanım borcu kiracılıkta tahakkuk ettiyse o kiracılık; her tahakkuk yolunda
  tetikleyiciyle kurulur, sonradan değiştirilemez; eski veride dönemi kiracılık başlangıcından sonra olan borç bağlandı (V5).
  Tek kural: `assessment_visible_to(tahakkuk, kişi)` ve `assessment_responsible(tahakkuk)`.
- Finans: sakin bakiyesi/vadesi geçen/sonraki vade/tahakkuk listesi/ayrıntı, ödeme ve kart ödemesi, gecikme tazminatı
  dondurma, ödeme geçmişi, alacak dekontları bu kurala bağlandı; borçlu listesi ve PDF/Excel dökümü sorumlu sütunuyla.
- Bildirim: `notify.AssessmentPayers` — yeni borç, yönetimin tahsilat kaydı ve gecikmiş aidat hatırlatması borcun
  sorumlusuna (kiracı / malik ve vekil); maliksiz dairenin malik borcu yönetimde bekler (V3). `UnitPayers` kaldırıldı.
- Borcu yoktur belgesi kapsamlı: UNIT (yönetim, malik, vekil) / TENANCY (kiracı); kimliksiz doğrulama kapsamı söyler
  (`verify_clearance_certificate_scoped`; 055'teki işlev yeniden uygulanabilirlik için değiştirilmedi — Ders 52).
- Panel muhasebe "Borçlular" sekmesinde Sorumlu sütunu; sakin uygulamasında malik sınıfı borç "· Malik gideri" etiketiyle.
### 2026-10-11 — KİRACILIĞIN BİTİŞİ: KİRACI ONAYI, KENDİ ÇIKIŞI, YÖNETİM YOLU (migration 069, altıncı tur D4) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1341/1341** (adım 60: malik isteği — ikinci açık istek 409, malik olmayan 403 —, kiracı reddetti
> kiracılık sürdü, yönetim doğrudan pasifleştiremedi 409; kiracı onayladı, kiracılık bugün bitti, hanesi bitti, daire boş;
> kiracının çıkışı açık malik isteğini kapattı, maliklere haber verildi; yönetim yolu — dairenin maliki olan yönetici 403,
> beyansız 422, yanlış şifre 400, metin dosyası 422, UYAP kodsuz belgeyle başladı, beyan/IP/özet kayıtlı, 7 günlük pencere,
> ikinci yol 409 —; kiracı belgeyi indirdi, malik indiremedi; süre dolmadan tamamlanamadı; itirazla askı; yeni belgeyle yeni
> pencere; süre dolunca itiraz 409, tamamlandı; sahte çıkınca şifreyle geri alındı, aynı kayıtla açıldı; olay kaydı eksiksiz;
> kimlik rolü akış dışında kiracıyı pasifleştiremedi, olay kaydı silinemedi, uygulama rolü erişemedi). Adım 36: RLS 122 tablo.
> `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Kullanıcı kararları: malik isteği kiracının onayı olmadan sonuçlanmaz; yönetim yolunda UYAP kodu isteğe bağlı (kodsuz belgeler
  de var), 1 hafta itiraz ve kimlik bilgisiyle onay. Varsayılanlar: V1 kiracı kendi çıkışını yapar; V2 itirazda askı, başlatan
  dairenin maliki/vekili olamaz, geri alma; V7 ikinci onaycı zorunlu değil; V8 kiracılık bitince daire boş.
- 069: `tenancy_end_requests`, `tenancy_end_documents`, `tenancy_end_events` (yalnız kimlik servisi, RLS, silme yok, olaylar
  `clock_timestamp` ile sıralı). Aktif kiracı bağı yalnız akışın açtığı `siteeksen.tenancy_end` ayarıyla pasifleşir (tetikleyici;
  `PATCH /residents/:id` 409); kiracı ayrılınca hanesi biter.
- Kimlik servisi artık `pkg/storage` kullanır (gen-deploy `STORAGE_SERVICES`); depo yoksa yönetim yolu 503. Kimlik servisi bildirim
  tablosuna yazamadığı için taraflara SMS/e-posta doğrudan gider, sonuç sayaçlarla döner; uygulamada istek listesi var.
- Panel: Sakinler sayfasında "Kiracılık bitişleri" (yönetim yolu, yeni belge, tamamla, iptal, geri al, belge indirme, olay kaydı).
  Sakin uygulaması: "Kiracılık işlemleri" ekranı (onay/ret/itiraz, belgeyi açma, geri çekme); daire ekranında "Kiracılığın bitmesini
  iste" (malik) ve "Çıkışımı bildir" (kiracı).
### 2026-10-11 — KAYIT VE DAVET: TEK KİRACI, KODLA KATILIM, HANE ÜYESİ (migration 068, altıncı tur D3) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1331/1331** (adım 59: yönetim kiracı davet etti, kod yalnız yönetime, sağlayıcısızlık dürüstçe
> söylendi; kişi kodu girince daireye bağlandı, davet kabul edildi, malikin hanesinin kaydı bitti, malik artık oturan değil;
> kiracılı daireye ikinci kiracı ne davet ne kayıt (409); malik daveti yalnız maliksiz daireye; kiracı hanesine üye davet etti,
> kod ona gösterilmedi; kiracılı dairede malik hane üyesi davet edemiyor; hesabı olan kişinin bekleyen kabulü kural değişince
> 409; hane üyesi borcu görmüyor ve ödeyemiyor. Adım 53 davet akışına göre yeniden yazıldı). `verify-mobile.sh` 10/10;
> panel tsc/lint temiz.

- Kullanıcı kararları: davetli kişinin hesabı yoksa hesap hemen açılır, kod SMS + e-postayla gider, kodu girince davet kabul
  edilir; hane üyesini oturan ve yönetim ekler; yönetim kiracıyı doğrudan da kaydeder; kiracı gelince malikin hanesi biter.
- 068: daire başına tek aktif kiracı (benzersiz indeks), dairede tek bekleyen kiracı daveti, kiracı gelince hane üyelerini
  bitiren tetikleyici, davette HOUSEHOLD ve `invited_as` (MANAGEMENT / OWNER / OCCUPANT). Kurallar her yolda (kayıt, davet,
  kabul, etkinleştirme) aynı; kabul anında yeniden denetlenir.
- Malikin doğrudan kiracı ekleme ucu (`POST /users/me/units/:id/residents`) kaldırıldı → `POST /users/me/units/:id/invitations`.
  Kod davet edene gösterilmez (malik kiracısının şifresini belirleyemesin). Kiracılık malikin tek taraflı işlemiyle bitmez (409;
  kiracı onayı / yönetim yolu D4). Yönetim daveti `POST /residents/invitations`.
- Hane üyesi (V4) finans sorgularında ve mali bildirimlerde (`notify.UnitPayers`: yeni borç, tahsilat, gecikme) yok.
- Mobil "Dairemin sakinleri" malik ve kiracıya açık, davet gönderir; panelde "Davet gönder" ve Hane üyesi sıfatı.
### 2026-10-11 — DAİRE OTURUM MODELİ (migration 067, altıncı tur D2) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1325/1325** (adım 58: malikli daire "malik oturuyor", kimsesiz "kayıtsız", yalnız kiracılı
> "kiracı oturuyor" + malik kaydı yok; yönetim "boş" işaretleyince yanıtta ve listede boş, malik oturan değil, kiracı 403;
> kiracı gelince kiracı oturan, ayrılınca daire yeniden boş, "malik oturuyor" ile malik oturan; hane üyesi rolü veritabanında
> kabul edilip oturan sayılıyor, API'den eklemesi D3'e kadar 422; uygulama rolü aynı işlevi okuyor). Panel tsc/lint temiz.

- "Dairede kim oturuyor" artık tek yerde: `unit_occupancy(unit)` ve `resident_is_occupant(resident_unit)`. Durum saklanmaz,
  kayıtlardan hesaplanır (iki kaynak kopamaz). Kiracı varsa kiracı oturur; yoksa `units.owner_occupied` ile malik oturur ya da
  daire boştur; boş daire tanım gereği malikli; aktif malik ve kiracı yoksa kayıtsız.
- `HOUSEHOLD` (hane üyesi) rolü şemaya açıldı; jeton rolü üretmez (mali ekran göremez, V4); ekleme akışı D3'te.
- `GET /units` oturum alanları; `PATCH /units/:id` `owner_occupied`; `GET /residents` `is_occupant`. Panelde Oturum sütunu,
  "kiracı yokken: malik oturuyor / daire boş" seçimi, malik kaydı olmayan daireler uyarısı, sakin listesinde "Oturan".
### 2026-10-11 — GİDER SINIFI: KULLANIM (OTURAN) / MALİK (migration 066, altıncı tur D1 — kullanıcı kararı) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1320/1320** (adım 57: kalemin varsayılan sınıfı dönüyor; kullanım + malik kalemli elle
> tahakkukta bölüme sınıf başına ayrı kayıt, tutarlar kuruşu kuruşuna, kalem satırları başlıkla aynı sınıfta; aynı dönem + aynı
> sınıf 409, girişte seçilen sınıf varsayılanı eziyor, tanınmayan sınıf 400 ve kayıt yok; sınıf uygulama rolüyle
> değiştirilemiyor (tetikleyici); devirde bir bölüme kullanım + malik ayrı satır, aynı sınıfta ikinci devir 409; işletme
> projesinde yeni tesis kalemi malik sınıfına düştü, bölüm payı kullanım/malik olarak ayrıldı, projeden aylık tahakkuk sınıf
> başına ayrı kayıt; gider kaydında sınıf kategoriden önerildi ve değiştirilebildi. Adım 33: ortak kalem sayısı 13).
> Panel `tsc --noEmit` + `lint` temiz.

- Her mali kalem girişte sınıf alır: **USAGE** (oturanın gideri — kapıcı, temizlik, ısınma…) ya da **OWNER** (malikin gideri —
  demirbaş, yenileme, yeni tesis; KMK m.42-43, TBK m.302). Siteye karşı borçlu yine malik (KMK m.20, m.22); sınıf, borcun kimin
  ekranında görüneceğini ve kimin ödeyeceğini belirler (yönlendirme D5'te).
- 066: `expense_categories.default_liability`; `expenses`, `operating_budget_items`, `assessment_details`, `monthly_assessments`
  `liability`; `operating_budget_unit_shares.annual_usage_kurus/annual_owner_kurus` (toplamı yıllık paya eşit, CHECK);
  dönem ve devir benzersizliği sınıf bazında; tahakkukun sınıfı sonradan değiştirilemez; üç ortak malik kalemi
  (Demirbaş Alımı, Yenileme / Büyük Onarım, Yeni Tesis / Yenilik). Mevcut kayıtlar KULLANIM sayılır.
- Elle tahakkuk, işletme projesinden tahakkuk, devir bakiyesi (satır bazında) ve gider kaydı sınıfı alır. Panelde dört formda
  sınıf seçimi (kalem seçilince varsayılanı gelir) ve listelerde "Sınıf" sütunu.
- Finans tahakkuku yalnız sitenin kendi kalemlerini kullanır; ortak malik kalemleri gider modülünde ve işletme projesinde
  görünür, elle tahakkukta sınıf satırda seçilir.
### 2026-10-11 — E-POSTA DEĞİŞİKLİĞİNDE YENİ ADRESE ONAY KODU (migration 065, B4 ek — kullanıcı kararı) (DOĞRULANMIŞ — sahte SMTP ile)

> **Kanıt:** `verify-stack.sh` → **1312/1312** (adım 52: e-posta yoksa 503, yanlış şifre 400, geçersiz adres 422, başka hesabın
> e-postası 409; kod YENİ adrese gitti — kodu SMTP oturumundan okuyan sahte sunucuyla — ve adres kod girilmeden değişmedi;
> yanlış kod 400; doğru kodla güncellendi ve profilde görünüyor; kod özetle saklanıyor. Adım 36: `email_change_requests`
> uygulama rolüne kapalı, RLS dışı 10 tablo gerekçeli). `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- 062'de e-posta yalnız mevcut şifreyle değişiyordu; yanlış yazılmış ya da başkasına ait adres doğrulanmadan kaydedilebiliyordu.
- `POST /users/me/email` artık kod gönderir, `POST /users/me/email/confirm` adresi değiştirir. 065 `email_change_requests`
  (yalnız kimlik servisi). Sakin uygulaması ve panel Hesabım sayfası iki adımlı.

### 2026-10-11 — HAVALE BİLDİRİMİNE DEKONT DOSYASI (migration 064, beşinci tur B9) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1309/1309** (adım 56: sakin onay bekleyen havale bildirimine PDF dekont ekledi — içerik
> baytlardan tanındı, SHA-256 saklandı, dosya depoda; metin dosyası 422, başkasının ödemesi 403, depo yoksa 503; PNG/JPEG de
> eklendi, 4. dosya 409; sakin ve yönetim listeyi görüyor, onay listesinde dekont sayısı var; yönetimin indirdiği dosya özetle
> birebir aynı; onaylanmış ödemeye dekont eklenemiyor; kayıt uygulama rolüyle silinemiyor/değiştirilemiyor. Adım 36: RLS 119
> tablo. `gen-deploy.py --check` temiz). `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Önceden havale bildiriminde yalnız açıklama/dekont NUMARASI vardı; dosya eklenemiyordu.
- 064 `payment_receipts` (RLS; silinemez, değiştirilemez). Dosya `pkg/storage`'da, anahtar `receipts/<site>/<ödeme>/<özet>`.
  Finans servisi artık `STORAGE_*` alır (`gen-deploy.py` `STORAGE_SERVICES`'e eklendi; compose birimi ve k8s ortamı üretildi).
- Dekont yalnız dayanaktır: borç yine yönetim onayıyla ya da banka ekstresi eşleşmesiyle düşer.
- Panel: onay bekleyen ödemelerde "Dekont" sütunu ve indirme penceresi. Sakin uygulaması: havale bildiriminden sonra
  "Dekont ekle" (yeni bağımlılık `file_picker` 11).

### 2026-10-11 — FATURA SAPMA UYARISI VE TÜKETİM PUSULASINA İTİRAZ (migration 063, beşinci tur B8) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1305/1305** (adım 55: sapma birim testleri; medyanın ~8,6 katı tüketen bölüm önizlemede
> uyarıldı, teyitsiz yayım 422 `OUTLIERS_UNCONFIRMED`, teyitle yayımlandı ve teyit eden + bölüm pusulayla saklandı; sakin kendi
> pusulasına gerekçeli itiraz etti, yönetime bildirim gitti; ikinci açık itiraz 409, kısa gerekçe 422, komşunun bölümü 403;
> yönetim açıklamayla kabul etti, sakine bildirildi; sakin yanıtlayamaz 403, kısa açıklama 422, ikinci yanıt 409; yanıtlanmış
> itiraz uygulama rolüyle değiştirilemiyor ve silinemiyor; pusula aynen duruyor. Adım 36: RLS 118 tablo). `verify-mobile.sh`
> 10/10; panel tsc/lint temiz.

- Önceden yalnız okuma bazında (önceki dönemin 2,5 katı) teyit vardı; site medyanına göre kontrol yalnız enerji raporundaydı,
  paylaştırmada kullanılmıyordu. Faturaya özel itiraz yolu yoktu.
- `iot/service.FindOutliers`: kullanım alanı başına (alan yoksa doğrudan) tüketim, medyanın 3 katı; ölçülebilir bölüm 3'ten
  azsa işaret yok. Yayımda teyit zorunlu; teyit eden ve bölümler `consumption_allocations`'a yazılır.
- 063 `consumption_statement_objections` (RLS, silinemez, yanıttan sonra değişmez). Yayımlanmış pusula değişmez; kabulde
  düzeltme yönetimin açıklamasındaki yolla yapılır.
- Panel: paylaştırmada sapma uyarısı + teyit kutusu, "Pusula itirazları" sekmesi ve yanıt penceresi. Sakin uygulaması:
  pusulada "İtiraz et" ve itiraz durumu.

### 2026-10-11 — TAŞINAN SAKİNDE İLİŞİK KESME TARİHİ (beşinci tur B7) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1300/1300** (adım 54: birim testi; pasifleştirmede tarih yazıldı ve yanıtta görünüyor; ileri
> tarih / aktif kayıtta tarih / başlangıçtan önceki tarih 422; zaten pasif kayıtta tarih korunuyor; yeniden etkinleştirmede
> temizlendi; tarihsiz pasifleştirmede bugün; malikin bitirdiği kiracılıkta da tarih var. Adım 0: yeni `gofmt` denetimi).
> Panel tsc/lint temiz.

- Önceden pasifleştirme yalnızca `is_active` değiştiriyordu; `resident_units.end_date` sütunu hiç yazılmıyordu. Changelog'daki
  Apsiyon BUG-01 girdisinin "end_date de yazılır" ifadesi yanlıştı; o girdi düzeltildi.
- `PATCH /residents/:id` `end_date` alır; malikin kiracılığı bitirmesi (B5) de aynı yolu kullanır.
- Panel: sakin düzenlemede "Ayrılış (ilişik kesme) tarihi", listede "Ayrıldı · tarih".
- `verify-stack.sh` adım 0'a `gofmt -l` denetimi eklendi (iki dosya biçim farkıyla commit edilmişti; ayrı commit'te düzeltildi).

### 2026-10-11 — KADEMELİ GİRİŞ KİLİDİ (beşinci tur B6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1296/1296** (adım 39: birim testi; 4 hatada kilit yok, 5. hatada 30 sn kilit ve kilitliyken
> doğru şifre de 401; 6. hata 2 dk, 7. hata 15 dk; hata yanıtı kilit durumunu söylemeden kademeleri anlatıyor; kilit bitince
> giriş açılıyor ve sayaç sıfırlanıyor).

- Önceden 5. hatada sabit 15 dakika kilit vardı. Artık `LoginLockFor`: 5. hata 30 sn, 6. hata 2 dk, 7.+ 15 dk; kilitliyken
  yapılan denemeler sayılmaz. Sayaç ve kilit tek işlemde yazılır.
- Hata yanıtına sabit `note` eklendi (kademeler + "Şifremi unuttum"); hesabın var olup olmadığı ya da kilitli olduğu söylenmez.

### 2026-10-11 — MALİKİN KENDİ BÖLÜMÜNDE KİRACI/VEKİL YÖNETİMİ (beşinci tur B5) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1294/1294** (adım 53: malik kendi bölümünün sakinlerini görüyor — telefon maskeli, e-posta
> yok; kiracı malik olmadığı bölümde 403; malik kiracı ekledi ve yeni hesaba etkinleştirme kodu üretildi; malik rolü 422,
> başka bölüm 403, geçersiz numara 422; kiracılığı bitirdi (pasif); kendini/maliki 422, başka bölümün sakini 404, bozuk kimlik
> 404; işlemler ve reddedilen deneme denetim izinde). `verify-mobile.sh` 10/10.

- Önceden kiracıyı yalnızca yönetim (MANAGER/BOARD_MEMBER) ekleyip çıkarabiliyordu.
- `GET|POST /users/me/units/:id/residents`, `POST /users/me/units/:id/residents/:residentId/end`: yalnız bölümün AKTİF
  maliki; yalnız TENANT/PROXY. Yeni hesapta etkinleştirme kodu (SMS varsa gönderilir), başka sitede hesabı olan kişiye davet —
  yönetimin akışıyla aynı (`ResidentService.create` ortaklaştırıldı).
- Yönetime ayrı bildirim GİTMEZ: kimlik servisinin site verisine (bildirim tablosu dahil) erişimi yoktur (en az yetki).
  İşlem denetim izine yazılır, yönetim sakin listesinde görür.
- Sakin uygulaması: Profil > Dairem > "… sakinleri" ekranı (listele, ekle, bitir).

### 2026-10-11 — SAKİNİN KENDİ TELEFON VE E-POSTA DEĞİŞİKLİĞİ (migration 062, beşinci tur B4) (DOĞRULANMIŞ — sahte Netgsm ile)

> **Kanıt:** `verify-stack.sh` → **1291/1291** (adım 52: e-posta biçimi birim testi; SMS yoksa 503, yanlış şifre 400, aynı
> numara 422, başkasının numarası 409, geçersiz numara 422; kod YENİ numaraya SMS ile gitti, veritabanında özet var düz kod
> yok, 60 sn içinde ikinci istek 429, yanlış kod 400 ve numara değişmedi; doğru kodla numara değişti, bütün oturumlar kapandı
> (eski jeton 401), eski numaraya uyarı SMS'i, yeni numarayla giriş; e-posta: yanlış şifre 400, geçersiz 422, başka hesabın
> e-postası 409, güncellendi ve profilde görünüyor; adım 36: `phone_change_requests` uygulama rolüne kapalı, RLS dışı 9 tablo
> gerekçeli). `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Önceden numarayı yalnızca yönetim değiştirebiliyordu; çok siteli kişide yönetim de değiştiremiyor ve hata "kendi hesabından
  değiştirsin" diyerek var olmayan bir ekranı gösteriyordu. Sakin uygulamasındaki E-posta/Telefon satırları "henüz hazır değil"
  diyordu; e-postayı kimse değiştiremiyordu.
- 062 `phone_change_requests` (yalnız kimlik servisi; kod `user_activation_codes`'ta tutulmaz — oradaki kod `/auth/activate`
  ile şifre belirlemeye de yarardı). `POST /users/me/phone/request|confirm`, `POST /users/me/email`.
- Yönetimin telefon değiştirme hatası (çok siteli kişi) artık Profil > Telefon akışını gösteriyor.
- Sakin uygulaması: profilde e-posta ve iki adımlı telefon değişikliği (onayda çıkış yapılıp girişe dönülür). Panel: Hesabım
  sayfasına telefon ve e-posta kartları.

### 2026-10-11 — ŞİFREMİ UNUTTUM: SAKİNİN KENDİ KOD İSTEĞİ (beşinci tur B3, Şikayetvar "SMS, giriş ve hesap erişimi") (DOĞRULANMIŞ — sahte Netgsm ile)

> **Kanıt:** `verify-stack.sh` → **1284/1284** (adım 51: sıklık sınırı birim testi; kod sakinin kayıtlı +352 numarasına SMS
> ile gitti, 15 dk geçerli ve "kendi isteği" olarak kayıtlı; kayıtsız numarada SMS yok ve yanıt BİREBİR aynı; SMS/e-posta
> yapılandırılmamış kurulum 503 `NO_DELIVERY_CHANNEL`; 60 sn dolmadan ve saatte 3 koddan sonra yeni SMS yok, yanıt yine aynı;
> geçersiz numara 422; SMS'teki kodla yeni şifre belirlendi, yeni şifreyle giriş var, eski şifre 401). `verify-mobile.sh` 10/10;
> panel tsc/lint temiz. **Gerçek Netgsm hesabıyla denenmedi.**

- Önceden kodu yalnızca site yönetimi üretebiliyordu; üç istemcideki "Şifremi unuttum" bağlantısı yönetimden alınacak kodun
  girildiği ekrana gidiyordu.
- `POST /auth/password-reset/request`: numara etkin bir hesaba aitse kod üretilir (`created_by` boş = kendi isteği) ve
  arka planda gönderilir — yanıt metni ve süresi numaranın kayıtlı olup olmamasından bağımsızdır.
- Panel, sakin ve yönetici uygulamalarının etkinleştirme ekranına "Kodu SMS ile gönder" (60 sn geri sayım) eklendi; kod
  mevcut `/auth/activate` ile girilir.

### 2026-10-10 — YÖNETİMİN TAHSİLAT GİRİŞİ: BİLDİRİMSİZ HAVALE, ELDEN ÖDEME, EŞLEŞMEYEN EKSTRE SATIRI (migration 061, beşinci tur B2) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1280/1280** (adım 50: yönetici elden ödemeyi girdi — ödeme aynı işlemde onaylandı, borç
> kapandı, ödeyen boş / giren yönetici kayıtlı, ödeme günü korundu, defter zincirine "Yönetim tahsilatı (nakit) · Makbuz 0042"
> yazıldı; sakin bu ucu kullanamıyor 403; daire sakinine "ödemeniz kaydedildi" bildirimi, sakin ödemeyi kendi geçmişinde,
> yönetim listede "Yönetim kaydı" olarak görüyor; ileri tarih 400, başka bölümün borcu 422, kapanmış borç 422, geçersiz yöntem
> 400, sakinin bekleyen bildirimi varken 409; eşleşmeyen ekstre satırı doğrudan bölümün borcuna işlendi (ödeme günü hareket
> günü), tutarı tutmayan satır 422 ve açık kaldı, sonuçlanmış satır 409; `recorded_by` uygulama rolüyle değiştirilemiyor;
> zincir geçerli). `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Önceden ödeme kaydını yalnızca sakin, kendi borcu için açabiliyordu; bildirim yapmadan gelen havale ya da elden ödeme
  daireye işlenemiyor, ekstrede eşleşmeyen satır kapanamıyordu (`gap-analizi.md` M-51 "mobilden tahsilat girme" boşluğu).
- 061: `payments.recorded_by` (giren yönetici; korumaya eklendi, değiştirilemez), `recorded_by` doluysa `unit_id` zorunlu.
- `POST /finance/collections`, `POST /finance/bank-statements/lines/:id/collect`: ödeme aynı işlemde onaylanır
  (`confirmPaymentTx`), gecikme tazminatı sakinin bildirdiği ödemeyle aynı kurala (ödeme günü, 053) tabidir.
- Yönetim ödeme listesi `users`'a LEFT JOIN ile bağlandı (ödeyeni olmayan kayıt düşmesin); sakinin ödeme geçmişi bölümüne
  yönetimce girilmiş tahsilatları da gösterir (`recorded_by_management`).
- Panel: "Tahsilat gir" ve ekstre satırında "Daireye işle" (seçilen borç toplamı hareket tutarıyla karşılaştırılır).
  Yönetici uygulaması: Ödemeler ekranında "Tahsilat gir" formu.

### 2026-10-10 — YENİ BORÇTA SAKİNE BİLDİRİM (beşinci tur B1, Şikayetvar §3.2 "habersiz borçlandırma") (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1274/1274** (adım 49: `pkg/notify` birim testleri; tahakkukta daire sakinlerine uygulama
> içi bildirim — bölüm, dönem, tutar, son ödeme günü; taşınmış (pasif) sakine gitmedi; son ödeme günü geçmiş kaydedilen borçta
> bu açıkça yazıyor; devir bakiyesinde açıklama ve tutarla bildirim; adım 37: projeden tahakkukta her aktif daire sakinine
> bildirim, sayı aktif sakin sayısına eşit). Panel tsc/lint temiz.

- Önceden tahakkuk, devir bakiyesi ve işletme projesinden tahakkuk hiçbir bildirim üretmiyordu; sakin borcu uygulamayı açınca
  ya da vade geçip aylık hatırlatma gelince görüyordu.
- `pkg/notify/charges.go` `NotifyCharges`: verilen tahakkuklardan daire başına bildirim; alıcı `UnitResidents` (aktif
  sakinler); uygulama içi + SMTP yapılandırılmışsa e-posta; tahakkuk başına tek kayıt (dedupe `charge:<id>:<kanal>`).
- Üç nokta bağlandı: `POST /finance/assessments`, `POST /finance/opening-balances`, `POST /governance/budgets/:id/assessments`.
  Yanıtlara `notification` sayaçları eklendi; panel başarı mesajında gösterir.
- Bildirim hatası tahakkuku geri almaz (borç kayıtlıdır); sonuç yöneticiye yanıtta gösterilir.

### 2026-10-10 — KARTLA ÖDEME: iyzico ÖDEME FORMU, 3D SECURE DÖNÜŞÜ, DURUM MAKİNESİ (migration 060, TEST_RAPORU 2.5, Apsiyon BUG-09) (DOĞRULANMIŞ — sahte sağlayıcıyla)

> **Kanıt:** `verify-stack.sh` → **1269/1269** (adım 48, IYZWSv2 imzasını DOĞRULAYAN sahte iyzico sunucusuyla: `pkg/iyzico`
> birim testleri; yarım yapılandırmada servis açılmıyor; ödeme başlatma imzalı, kuruştan tutar, sanal sepet, kart bilgisi bu
> sisteme gelmiyor, ödeme PENDING/INITIATED; kart reddinde sonuç iyzico'dan yeniden sorgulandı, Türkçe neden ("Kartınızın limiti
> yetersiz."), borç değişmedi, ikinci geri dönüş aynı sonuç, tarayıcı sonuç sayfasına 303; başarılı ödemede borç kapandı ve
> tahsilat defterine iyzico kimliğiyle yazıldı; bilinmeyen jeton 404; tutar uyuşmazlığında borç düşmedi; sonuç sorgulanamayınca
> PROCESSING kaldı, uzlaştırma bekçisi zaman aşımıyla kapattı; 3D Secure tamamlanmayan denemeden sonra yeni deneme ilk günün
> valörünü aldı, gecikme tazminatı 6,67'den 6,00'a indi; ödeme sayfası açılamayınca 502 ve kayıt PENDING bırakılmadı);
> `verify-mobile.sh` 10/10; panel tsc/lint temiz. **Gerçek çekim, kullanıcının iyzico (sandbox/canlı) anahtarlarıyla denenmedi.**

- `pkg/iyzico`: Ödeme Formu (Checkout Form) istemcisi, IYZWSv2 imzası, yalnızca stdlib. Kart bilgisi ve 3D Secure iyzico'nun
  sayfasında girilir (PCI-DSS kapsamı sağlayıcıda).
- Durum makinesi: INITIATED → PROCESSING → SUCCEEDED | FAILED | EXPIRED. Ödeme sonuçlanana kadar PENDING kalır ve
  gecikme tazminatı deneme gününde durur (053 valör mekanizması).
- Geri dönüş (`POST /api/v1/public/payments/iyzico/callback`, kimliksiz): sonuç geri dönüş gövdesinden DEĞİL, jetonla
  iyzico'dan yeniden sorgulanır; çekilen tutar ve sepet kimliği doğrulanır; idempotent. Başarılı ödeme borçtan düşer ve
  tahsilat defterine yazılır (ödeme onayıyla aynı işlem).
- Ret nedenleri Türkçe ve CARD (kart/banka reddi) ya da SYSTEM (zaman aşımı, sağlayıcı hatası) olarak sınıflanır. SİSTEM
  kaynaklı başarısızlıktan sonraki iki gün içinde yapılan yeni deneme ilk denemenin gününü valör alır: kullanıcı sistem
  hatasının faizini ödemez.
- Uzlaştırma bekçisi (`CARD_RECONCILE_INTERVAL`/`CARD_RECONCILE_AGE`): sonucu gelmeyen ödeme havada kalmaz.
- `GET /finance/payments/:id/status`; panelde herkese açık `/odeme-sonuc` sayfası; sakin uygulaması ödeme sayfasını
  tarayıcıda açıp sonucu sunucudan sorar ("işlemde" / Türkçe ret nedeni) — beyaz ekran yok.
- Dağıtım: `IYZICO_*`, `PAYMENT_RESULT_URL`, `PUBLIC_VERIFY_BASE_URL` (compose, k8s `payment` gizli değeri, `.env.example`).
- iyzico alıcı kimlik numarası zorunludur; sakinlerin TCKN'si tutulmadığı için iyzico'nun kabul ettiği yer tutucu gönderilir
  (iyzico hesabında bu kullanımın onaylanması kullanıcı listesinde).

### 2026-10-10 — ALACAK DEKONTU VE BANKA EKSTRESİ MUTABAKATI (migration 059, Apsiyon BUG-12) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1258/1258** (adım 47: ekstre ayrıştırma birim testleri; dekont: sakin 403, kalan borcu aşan
> 422, gerekçesiz 400, AD-yıl-0001 numarasıyla kesildi, borç 1000→749,50 anapara korunarak düştü, zincire CREDIT_NOTE yazıldı,
> ödeme oluşmadı; sakin kendi dekontunu ve PDF'ini görüyor; gecikme tazminatı kalan anapara 749,50 üzerinden işledi; dekont
> silinemiyor/değiştirilemiyor; ters kayıt borcu geri yükledi, ikinci ters kayıt 409, zincir geçerli; ekstre: havale
> açıklamasındaki referansla bekleyen ödeme önerildi, giden ve eşleşmeyen ayrıldı, aynı dosya ikinci kez 3 satır mükerrer,
> sakin 403, başlıksız dosya 400; onay ödemeyi aynı işlemde onayladı ve zincire yazdı, ikinci onay 409, tutarı tutmayan
> eşleşme 422, gerekçeli yok sayma 200; RLS 117); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- **Alacak dekontu** (`POST /finance/credit-notes`, ters kayıt `/:id/reverse`, PDF): oturulmayan ay, indirim, hatalı
  tahakkuk düzeltmesi numaralı ve gerekçeli belge olur; borç `credited_amount` ile düşer — ödeme gibi görünmez, tahsilat
  raporuna girmez. Önce anaparadan düşer; sonraki gecikme tazminatı kalan anapara üzerinden işler. Silinemez, tek geçiş
  gerekçeli ters kayıttır; her ikisi tahsilat defteri zincirine yazılır.
- **Banka ekstresi** (`POST /finance/bank-statements`, CSV ya da .xlsx): sütunlar Türkçe/İngilizce başlıkla tanınır, tutar
  "1.234,56"/"1234.56" biçiminde, ayrı borç/alacak sütunları desteklenir; okunamayan satır satır numarasıyla reddedilir.
  Gelen hareket, sakinin onay bekleyen havale bildirimiyle (açıklama/dekont no → beyan günü ±3 → yalnızca tutar) eşleştirilir;
  **hiçbir ödeme kendiliğinden onaylanmaz**. Onay ödemeyle aynı veritabanı işleminde yapılır. Aynı hareket tekrar yüklenirse
  mükerrer sayılır; bir ödeme tek harekete bağlanır.
- `confirmPaymentTx`: ödeme onayı işlem içinde yeniden kullanılabilir hâle getirildi (davranış değişmedi; mevcut testler geçiyor).
- Panel: Tahsilat → Alacak dekontları / Banka ekstresi. Sakin uygulaması: Aidat ekranında "Alacak dekontlarım" ve PDF.

### 2026-10-10 — SİTE PASİFLEŞTİRME: PASİF SİTEDE HAYALİ BORÇ VE BİLDİRİM ÜRETİLEMEZ (migration 058, Apsiyon BUG-11) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1248/1248** (adım 46: sakin 403, yanlış site adı 422, kısa gerekçe 400; yönetici pasife
> aldı ve olay kaydedildi; pasif sitede `POST /finance/assessments` 409 PROPERTY_INACTIVE ve kayıt yok; uygulama rolüyle
> doğrudan bildirim, gecikme tazminatı ve borç artırma tetikleyiciye takıldı, tutarı artırmayan güncelleme serbest;
> zamanlayıcı pasif siteyi taramıyor; sakin giriş yapıp geçmiş tahakkukunu görebiliyor; yeniden etkinleştirince yazım
> açıldı; yaşam döngüsü olayları silinemiyor; RLS 114); panel tsc/lint temiz.

- `POST /property/deactivate` (yalnızca yönetici; gerekçe + site adını yazarak onay) ve `/property/reactivate`;
  `GET /property` durum ve olay geçmişi. Olaylar `property_lifecycle_events`'te silinemez.
- **Fail-closed tek nokta veritabanıdır:** pasif sitede `monthly_assessments`/`late_fee_accruals`/`notifications` satırı
  yazılamaz ve tahakkuk tutarı artırılamaz (SQLSTATE SE001 → 409). Hangi servis ya da kod yolu denerse denesin engellenir;
  borç azaltma (ödeme, valör, ters kayıt) açıktır. Zamanlayıcı ve cihaz bekçisi pasif siteyi zaten taramıyordu.
- Giriş ve okuma sürer (KVKK erişim hakkı, saklama süreleri); yeniden etkinleştirmede pasif dönem için geriye dönük
  tahakkuk yapılmaz (Apsiyon'da iptal edilen üyeliğe 6 ay sonra geriye dönük fatura çıkıyordu).
- Panel: Ayarlar → Site durumu.

### 2026-10-10 — YURT DIŞINDAKİ MALİKLER: ULUSLARARASI TELEFON (E.164), COĞRAFİ ENGEL YOK (Apsiyon BUG-10) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1243/1243** (adım 8: kong.yml ve gateway'de ülke/IP bloğu bazlı engel izi yok; adım 43:
> `pkg/phone` birim testleri; "+352 621 123 456" ile sakin eklendi, `+352621123456` olarak saklandı, kod sahte Netgsm'e
> `00352621123456` numarasıyla gitti, "00352 …" yazımıyla etkinleştirme 200, "+352…" ile giriş jeton döndü; "555-ABC-1234"
> ve eksik "+90 555 123" 422); `verify-mobile.sh` 10/10 (iki uygulamada yurt dışı numara testleri); panel tsc/lint temiz.

- **Kök hata:** "00352…" yazımının başına +90 ekleniyor ("+900352…"), mobil uygulamalar her numaraya +90 ekliyor, panel
  girişi yalnızca 10 haneli Türkiye numarası kabul ediyordu: yurt dışındaki malik hesap açamıyor, giriş yapamıyordu.
- `pkg/phone`: tek normalleştirme (E.164). "+"/"00" önekli numara ülke koduyla korunur (8–15 hane); +90 için tam 10 hane.
  Tanınmayan numara artık sessizce saklanmaz: sakin ekleme, görev verme ve telefon değişikliğinde 422; toplu eklemede satır hatası.
- Mobil (iki uygulama) ve panel giriş/etkinleştirme ekranlarında "+90" zorunluluğu kaldırıldı; numarayı sunucu normalleştirir.
- Coğrafi engel: kenar katmanında (Kong) ve gateway'de ülke bazlı engel yoktur; koruma IP başına hız sınırıdır. Doğrulama
  betiği bunu denetler — biri ileride toptan ülke engeli eklerse yakalanır.
- Netgsm yurt dışı numaraya `00…` biçimiyle gönderir (zaten destekliyordu); hesapta yurt dışı SMS paketi gerekir (kullanıcı).

### 2026-10-10 — GEÇİŞ CİHAZI CANLILIK İZLEME VE ÇEVRİMDIŞI ALARMI (migration 057, Apsiyon BUG-08) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1240/1240** (adım 15: cihaz kaydında anahtar bir kez gösterildi, yalnızca SHA-256 özeti
> saklandı; geçersiz tür ve tek aralıklık eşik 422, sakin 403; anahtarsız/yanlış anahtarlı sinyal 401, doğru anahtarla
> çevrimiçi; son sinyal 10 dk öncesine çekilince bekçi (1 sn) olay açtı ve bildirim üretti, sonraki turlarda ikinci olay/
> bildirim yok; sinyal dönünce olay kapandı ve "yeniden çevrimiçi" bildirimi gitti; olay geçmişi uygulama rolüyle
> silinemiyor; pasif cihazın sinyali 401; gateway kimliksiz yol listesi birim testi; rota tutarlılığı 361 rota; RLS 113);
> panel tsc/lint temiz.

- `access_devices` (PTS kamerası, bariyer, turnike, kapı telefonu) ve `device_incidents` (silinemez; cihaz başına tek açık olay).
- Cihaz `POST /api/v1/public/devices/heartbeat` ucuna `X-Device-Key` ile sinyal gönderir (gateway'de tek kimliksiz yol);
  site eşlemesi SECURITY DEFINER `device_heartbeat()` ile yapılır, RLS aşılmaz.
- Bekçi parking servisinde çalışır (`DEVICE_WATCH_INTERVAL`, varsayılan 30 sn): zamanlayıcı saatlik olduğu için 3 dakikalık
  alarm hedefini karşılayamazdı. Çevrimdışı/yeniden çevrimiçi bildirimi yönetim + görevliye gider (`notify.Operations`).
  Pasif sitelerin cihazları izlenmez.
- Panel: Otopark → Cihazlar (durum, son sinyal, olaylar, cihaz ekleme ve anahtarın bir kez gösterimi, pasife alma).
- **Yapılmadı:** mobilden bariyer açma. Cihaz üreticisinin komut protokolü olmadan "açıldı" demek sakini kapıda bırakırdı;
  donanım bilgisi kullanıcıdan bekleniyor.

### 2026-10-10 — SAYAÇ DEĞİŞİM PROTOKOLÜ, TÜKETİM SAPMASI TEYİDİ, YAYIMLANAN TÜKETİM PUSULASI (migration 056, Apsiyon BUG-07) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1229/1229** (adım 23: okuma ucunda "sayaç değişti" ile endeks sıfırlama 422 ve değişim
> ucuna yönlendirme; önceki tüketimin 4 katı okuma teyitsiz 409 ANOMALY, teyitle 201 ve `anomaly_ratio=4.00` + teyit eden
> kayıtlı; son okumadan küçük söküm endeksi 422; sakin değişim yapamıyor 403; değişimde eski sayaca 1520 söküm okuması,
> pasif, yeni sayaç 7 montaj endeksiyle; yeni sayacın ilk tüketimi 57−7=50; değişim döneminde tüketim (1520−1500)+(57−7)=70;
> okuması eksik dönem yayımlanamıyor 422; yayımda 3 satır, toplam tutara birebir eşit; aynı dönem ikinci yayım 409; uygulama
> rolü pusula satırını ve değişim kaydını değiştiremiyor; sakin yalnızca kendi satırını ve kendi PDF'ini görüyor; RLS 111);
> `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- **Kök hata:** okuma ucunda "sayaç değişti" denince önceki endeks SIFIR kabul ediliyordu: eski sayacın son okumadan söküme
  kadarki tüketimi kayboluyor, yeni sayaç sıfırdan başlamıyorsa fazladan tüketim yazılıyordu. Bu yol kapatıldı;
  `POST /meters/:id/replace` söküm endeksini eski sayaca okuma olarak yazar, sayacı pasife alır, yeni sayacı montaj
  endeksiyle açar ve `meter_replacements` kaydı (değiştirilemez) tutar. Dönem tüketimi iki sayaçtan toplanır.
- Sapma dedektörü: önceki okumanın tüketiminin 2,5 katını aşan okuma görevli teyidi (`confirm_anomaly`) olmadan kaydedilmez;
  oran ve teyit eden okumaya yazılır.
- Paylaştırma `publish:true` ile yayımlanır: bölüm bazında ilk/son okuma (tarih · endeks), net tüketim, alan, tüketim payı,
  alan payı ve toplam değiştirilemez biçimde saklanır (Isınma Gid. Paylaştırma Yön. — gider paylaşım belgesi). Okuması eksik
  bölüm varken ve aynı dönem ikinci kez yayımlanamaz. `GET /consumption/statements[/:id[/pdf]]`: sakin yalnızca kendi bölümü.
- Panel: "Sayaç değiştir" formu, sapma teyit kutusu, "yayımla" seçeneği, ilk/son okuma sütunları, "Tüketim pusulaları"
  sekmesi (PDF). Sakin uygulaması: Enerji ekranında "Tüketim pusulalarım" ve PDF.
- Test verisi düzeltmesi: doğrulama net alanı sabit 100 m² yazıyordu; brütü küçük bölümde 049 kısıtına takılıp sessizce
  başarısız oluyordu. Artık brüt×0,85 yazılır ve geri yükleme kontrol edilir.

### 2026-10-10 — YÖNETİM DESTEKLİ HESAP KURTARMA: TELEFON DEĞİŞİMİ, E-POSTA YEDEK KANALI, GİRİŞ KİLİDİ (Apsiyon BUG-05/06) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1211/1211** (adım 43: telefon değişikliğinde oturumlar kapandı, yeni kod yeni numaraya SMS
> ile, eski numaraya uyarı SMS'i gitti (sahte Netgsm); başkasının numarası 409; 2 sitede kayıtlı hesabın numarası tek site
> yönetimince değiştirilemedi (409); yönetim giriş kilidini kaldırdı (kilit ve sayaç sıfır), sakin 403, olmayan kayıt 404);
> panel tsc/lint temiz.

- `POST /residents/:id/phone` (yönetim): eski oturumlar iptal, bekleyen kodlar geçersiz, yeni kod üretilir ve yeni numaraya
  gönderilir; eski numaraya "numaranız değiştirildi" uyarısı (hesap ele geçirmeye karşı). Hesap başka sitelerde de kayıtlıysa
  reddedilir — tek sitenin yöneticisi çok siteli bir kimliği değiştiremez.
- `POST /residents/:id/unlock` (yönetim): hatalı şifre kilidi süresini beklemeden kaldırılır. Kilit zaten en çok 15 dakikadır
  (5 hatada); Apsiyon'daki 48 saatlik kilit/kapanmayan döngü bu sistemde yoktu.
- Etkinleştirme/sıfırlama kodu SMS'e ek olarak, SMTP yapılandırılmışsa ve sakinin e-postası kayıtlıysa e-postayla da gider
  (tek kanala bağımlılık giderildi). WhatsApp kanalı sağlayıcı sözleşmesi gerektirdiği için eklenmedi.
- Panel: sakin satırında "Telefon" ve "Kilidi aç"; kod penceresinde SMS/e-posta sonucu.

### 2026-10-10 — BORCU YOKTUR BELGESİ: VADE AYRIMI, KAREKOD, KİMLİKSİZ DOĞRULAMA (migration 055, Apsiyon BUG-04) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1209/1209** (adım 45: vadesi geçmiş borcu olan bölüme belge yok, 422 + kalem listesi;
> yalnızca vadesi gelmemiş 500,00 TL'si olan bölüme belge üretildi (64 hane SHA-256 kod); başka dairenin sakini 403; PDF'te
> Türkçe beyan, vadesi gelmemiş tutar ayrı satırda, doğrulama kodu ve karekod görseli; kimliksiz doğrulama yalnızca site/
> bölüm/tarih döndürüyor, bilinmeyen kod 404, biçimsiz 400, süresi geçen geçersiz; uygulama rolü belgeyi değiştiremiyor;
> RLS 108); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Apsiyon'da son ödeme günü gelmemiş cari aidat "borç" sayılıp belge verilmiyordu. Burada belge yalnızca VADESİ GEÇMİŞ
  (muaccel) borç sıfırken üretilir; vadesi gelmemiş (müeccel) tutar belgede ayrıca yazılır. Onay bekleyen ödeme bildirimi
  varsa yanıt bunu söyler (beyan ödeme yerine geçmez).
- `POST /finance/clearance-certificates` (bölümün aktif sakini ya da yönetim), `GET /finance/clearance-certificates/:id/pdf`
  (karekodlu), `GET /api/v1/public/clearance/:code` — gateway'de kimlik istemeyen tek veri yolu; SECURITY DEFINER fonksiyonu
  yalnızca site adı, bölüm ve tarihleri döndürür (kişi adı/tutar yok). Belge 30 gün geçerli, değiştirilemez.
- Karekod: `rsc.io/qr` (saf Go) ile PDF'e gömülür; `pkg/reports` belgeleri artık karekod alabiliyor. Doğrulama adresi
  `PUBLIC_VERIFY_BASE_URL` (varsayılan `https://app.siteeksen.com/dogrula`).
- Panel: herkese açık `/dogrula/[kod]` sayfası; Bağımsız Bölümler satırında "Borcu yoktur". Sakin uygulaması: Aidat
  ekranında belge üretip cihazda açma.

### 2026-10-10 — DÜZELTME: GERİ YÜKLEMEDEN SONRA KALDIRILMIŞ YETKİLER GERİ GELİYORDU (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1209/1209** (adım 41 parmak izi artık tablo ACL'lerini de karşılaştırıyor ve geri
> yükleme sonrası yedekle birebir; adım 45 geri yüklemeden sonra uygulama rolünün korumalı tabloyu güncelleyemediğini
> sınıyor). Bağımsız deneme: göç → yedek → geri yükleme sonrası ACL farkı yalnızca biçimsel (açık sahip ACL'i = NULL).

- `db-restore.sh` (pg_restore) tabloları yeniden oluştururken 020'deki `ALTER DEFAULT PRIVILEGES` uygulama rolüne
  SELECT/INSERT/UPDATE/DELETE veriyordu; göçlerin REVOKE ettiği yetkiler (ödeme/defter silme, sonuçlanmış kaydı
  değiştirme, imha kaydı, ihlal olay geçmişi…) geri yüklemeden sonra sessizce geri geliyordu. Geri yükleme süresince
  varsayılan yetkiler askıya alınır, tablolar yedekteki yetkilerle kurulur, varsayılanlar her durumda (hata dahil) geri
  verilir. Ders 46.

### 2026-10-10 — FİNANSAL KAYITLARIN DEĞİŞTİRİLEMEZLİĞİ, TERS KAYIT, TAHSİLAT DEFTERİ ZİNCİRİ (migration 054, Apsiyon BUG-03) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1205/1205** (tahsilat onayı deftere dağılımıyla yazıldı; uygulama rolü ödeme ve defter
> silemiyor, tutar/durum/anapara değiştiremiyor, ödenen tutarı azaltamıyor; ters kayıt gerekçesiz 400, ödeme silinmeden
> REVERSED, borç yeniden açıldı (OVERDUE), deftere -1.230,00 gerekçeli kayıt, ikinci kez 409, sakin 403; kat maliki zinciri
> doğruladı; veritabanında oynanan defter kaydı doğrulamada sıra numarasıyla yakalandı; RLS 107 tablo); `verify-mobile.sh`
> 10/10; panel tsc/lint temiz.

- Uygulama rolü (020'den beri) ödeme/tahakkuk tablolarında DELETE yetkisine sahipti; koruma kodun iyi niyetine dayanıyordu.
  Artık `payments`, `payment_assessments`, `monthly_assessments`, `assessment_details`, `late_fee_accruals`, `expenses`
  silinemez. Tetikleyiciler: sonuçlanmış ödeme değişmez (tek geçiş COMPLETED → REVERSED, gerekçe zorunlu); ödeme almış
  tahakkukun anaparası değişmez/silinemez; ödenen tutar yalnızca ters kayıt işleminde azalır.
- `finance_ledger`: her tahsilat onayı ve ters kayıt bir öncekinin SHA-256 özetine bağlı yazılır (özet veritabanı
  fonksiyonuyla; değiştirilemez/silinemez). `POST /finance/payments/:id/reverse`, `GET /finance/ledger`,
  `GET /finance/ledger/verify` (sitenin her üyesi; tutar/kişi dönmez).
- Panel: "Tahsilat defteri" sekmesi (zincir doğrulama), tamamlanmış ödemede "Ters kayıt". Sakin uygulaması: Aidat ekranında
  "Tahsilat kayıtlarını doğrula".
- Sınır: veritabanı yöneticisi tetikleyicileri kapatıp zinciri baştan yeniden hesaplarsa yerel doğrulama bunu göremez;
  bunun için son özetin dışarıda (ör. genel kurul tutanağı/denetim raporu) saklanması gerekir.

### 2026-10-05 — HAVALE VALÖRÜ VE GECİKME TAZMİNATININ DONDURULMASI (migration 053, Apsiyon BUG-02) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1201/1201** (vadesinde yapılmış havale bildirildiğinde işlemiş tazminat sıfırlandı, tutar
> 1.200,00; valör sonrası tazminat izi silinmeden "Ödeme valörü 09.01.2026…" gerekçesiyle iptal işaretlendi; onay beklerken
> tazminat işlemedi; reddedilen beyanda tazminat yeniden işledi; 15 gün geç havalede tazminat 30,00 TL ve onayla borç
> kapandı (1.230,00 PAID); gelecek valör 422); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- KMK m.20/2: gecikme ödeme gününde biter. Sakin havale/EFT/nakit bildiriminde `value_date` (ödeme günü, en çok bir yıl
  geriye) ve `reference` (açıklama/dekont no) verir. İşletilmiş tazminat valör gününe göre yeniden yazılır — yalnızca
  DÜŞÜRÜLÜR (işletilmemiş tazminat beyan anında eklenmez); onay bekleyen ödemenin kapsadığı borçta gecikme tazminatı işi
  valörde durur; valör sonrası izler `late_fee_accruals.reversed_at/reversal_reason` ile işaretlenir (silinmez).
- Yönetim ekranında onay bekleyen ödemede "Havale günü" ve açıklama görünür (banka hareketiyle eşleştirme). Sakin
  uygulamasında havale seçilince ödeme günü ve açıklama sorulur; sonuçta tazminatın donduğu yazar.
- "Banka API'siyle 3 saniyede otomatik kapatma" (FAST açıklama kodu) S-07 kararı gereği banka entegrasyonu olmadığından
  yapılmadı; yerine ekstre içe aktarma ile eşleştirme A12'de ele alınır.

### 2026-10-05 — TAŞINAN SAKİN VE ŞEFFAF BORÇ HATIRLATMASI (Apsiyon BUG-01) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1198/1198** (adım 40: hatırlatma site adı, bölüm ve "2020-01 aidat: 1.234,56 TL ·
> 2020-02 aidat: 100,00 TL" dökümünü taşıyor; taşınmış eski kiracıya bildirim yok; ödeme bildirimi onay bekleyen borca
> hatırlatma yok).

- Apsiyon şikâyetlerindeki "taşındım, hâlâ borç SMS'i geliyor" hatası bu sistemde yoktu: borç hatırlatması yalnızca dairenin
  AKTİF sakinlerine gider (`notify.UnitResidents`), taşınmada `resident_units.is_active=false`; borç kişiye değil
  bağımsız bölüme yazılır. Mevcut kanıt korundu. **Düzeltme (2026-10-11):** bu girdi önceden "taşınmada `end_date` de
  yazılır" diyordu; yanlıştı — pasifleştirme yalnızca `is_active` değiştiriyordu. `end_date` beşinci tur B7 ile yazılıyor.
- Eklenen: hatırlatma soyut tutar yerine `[Site] · [Blok-Kapı]` + her kalem için `[Dönem] [Tür] [Tutar]` (devir bakiyesi ayrı
  adlandırılır) dökümü verir. Sakinin bildirdiği ödeme yönetim onayı beklerken o borç için hatırlatma gönderilmez.

### 2026-10-05 — PDF / EXCEL DÖKÜMLERİ (TEST_RAPORU 2.6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1197/1197** — adım 44: borçlu listesi PDF'inden pypdf ile çıkarılan metinde Türkçe
> başlık, KVKK 2026/348 uyarısı ve doğrulama kodu; Excel çalışma kitabı açılıyor; sakin 403, geçersiz biçim 400;
> tahakkuk/tahsilat özeti mizan olmadığını yazıyor; hazirun cetveli bölüm/arsa payı/imza sütunlu; karar defteri PDF'i
> zincir doğrulamasını yazıyor; işletme projesi Excel'i; olmayan defter 404. `go test ./pkg/reports`. `verify-mobile.sh`
> 10/10; panel tsc/lint temiz.

- `pkg/reports` yeniden yazıldı: tek `Document` modelinden PDF (gofpdf, **DejaVu Sans gömülü** — eski kod çekirdek
  Arial kullanıyordu ve ğ/ş/ı basamıyordu; hiçbir yerden de çağrılmıyordu) ve Excel (excelize). Her sayfada içerik
  SHA-256 doğrulama kodu; `X-Document-Verification` başlığı.
- Uçlar: `GET /finance/reports/debtors`, `/finance/reports/collections?year=`, `/governance/assemblies/:id/attendance-sheet`,
  `/governance/books/:id/export`, `/governance/budgets/:id/export` (`?format=pdf|xlsx`).
- "Mizan" bilinçli olarak üretilmedi: sistemde çift taraflı muhasebe yok; belge bunu söyler.
- Panel: Raporlar sayfası indirme kartları; Defterler ve İşletme projesinde PDF/Excel. Yönetici uygulaması: Raporlar ekranı
  indirip cihazda açar (`open_filex`).
- Not: dokunulan Go dosyalarına `gofmt` uygulandı (yalnızca hizalama).

### 2026-10-05 — SMS (NETGSM) VE E-POSTA (SMTP) SAĞLAYICILARI (TEST_RAPORU 2.4) (DOĞRULANMIŞ — sahte sağlayıcıyla; gerçek gönderim kullanıcının hesabıyla)

> **Kanıt:** `verify-stack.sh` → **1192/1192** — adım 43: Netgsm REST v2 biçimini taklit eden yerel sunucuya karşı
> sakin eklenince etkinleştirme kodu SMS ile gitti (Basic auth, `msgheader`, `5XXXXXXXXX`, `encoding:TR`, `iysfilter:0`,
> metinde kod); acil duyuru her telefonlu sakine SMS ile gitti ve kuyrukta `SENT/netgsm`; acil olmayan duyuruda SMS 422;
> yarım Netgsm yapılandırmasıyla kimlik servisi açılmıyor; `go test ./pkg/notify` (hata kodları, ticari SMS reddi, SMTP
> zarfı ve UTF-8 başlık, şifresiz bağlantıda parola reddi). Panel tsc/lint temiz.
> **Kalan (kullanıcı):** gerçek gönderim için Netgsm hesabı (kullanıcı kodu, API şifresi, onaylı başlık) ve SMTP bilgisi
> `.env`/k8s `notify` gizli değerine girilmeli; o zaman D4 kanıtı alınabilir.

- `pkg/notify`: `NetgsmSender` (POST `/sms/rest/v2/send`; yalnızca işlemsel ileti, ticari SMS reddedilir), `SMTPSender`
  (STARTTLS/örtük TLS; harici bağımlılık yok). `SendersFromEnv` gerçek sağlayıcıları kaydeder; `Broadcast` SMS/e-postada
  adresi kullanıcının kayıtlı telefonu/e-postasından çözer (adressizler `no_address` sayılır).
- Kimlik: etkinleştirme/şifre sıfırlama kodu SMS ile gönderilir (kuyruğa yazılmaz — giriş sırrı); yanıtta `sms.status`
  (SENT/FAILED/NOT_CONFIGURED). Kod yöneticiye yine bir kez gösterilir.
- Duyuru: `send_sms` / `send_email` yalnızca ACİL öncelikte; panelde seçenek ve sonuç sayıları.
- Dağıtım: tüm uygulama servislerine isteğe bağlı `NETGSM_*`, `SMTP_*` (compose) ve `notify` gizli değeri (k8s); `.env.example`.

### 2026-10-05 — KARGO TESLİM KANITI: İMZA VE FOTOĞRAF (migration 052, TEST_RAPORU 2.3) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1188/1188** (imza ve fotoğraf depoya yazıldı, kayıtta SHA-256; isimsiz 400, görsel
> olmayan dosya 422; dairenin sakini ve yönetim indirebiliyor (özet birebir), komşu 404, kanıtsız teslim 404,
> değiştirilmiş dosya 409; silme kuyruğundaki dosya depodan silindi; depo yapılandırılmamışken kanıtlı teslim 503 ve
> teslim kaydedilmedi; KVKK imhasında dosya anahtarları kuyruğa bırakıldı; RLS 106 tablo); `verify-mobile.sh` 10/10
> (yönetici 31 test: imza PNG'si); panel tsc/lint temiz.

- Teslim yanıtı "dosya depolama altyapısı henüz yoktur" diyordu; `pkg/storage` vardı ama bağlı değildi. Kargo servisi artık
  belge arşiviyle aynı depoya (`packages/` öneki) yazar; `POST /packages/:id/deliver` multipart (`signature`, `photo`)
  kabul eder, içerik baytlardan doğrulanır (PNG/JPEG/WEBP, 5 MB). `GET /packages/:id/proof/:kind` özeti doğrulayarak verir.
- KVKK periyodik imhası (PACKAGE) dosya anahtarlarını `storage_deletion_queue`'ya bırakır; kargo servisi kuyruğu işleyip
  dosyaları siler (önceki bilinen sınır: bağlantı silinir, dosya depoda kalırdı). Siteler `storage_deletion_property_ids()`
  ile bulunur (yalnızca kimlik).
- Dağıtım: kargo servisine depo ayarı ve belge birimi (`gen-deploy.py`, `STORAGE_SERVICES`).
- Panel: teslim penceresinde imza alanı (canvas) ve paket fotoğrafı (mobil tarayıcıda kamera). Yönetici uygulaması:
  teslimde dokunmatik imza (paket kullanılmadan CustomPainter → PNG).

### 2026-10-05 — ZİYARETÇİ GEÇİŞ KODU: PIN + QR (migration 051, TEST_RAPORU 2.8) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1182/1182** (ön kayıtta 6 haneli PIN; veritabanında yalnızca SHA-256 özeti; sakin
> doğrulayamaz 403; yanlış kod 404; yeni kod eskisini geçersiz kılar; görevli doğrulayınca giriş + daireye bildirim;
> kod tek kullanımlık; QR jetonuyla giriş 200; süresi dolmuş kod 410; başkasının ziyaretçisine kod üretilemez 409);
> `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Ön kayıtta tek kullanımlık PIN ve QR jetonu üretilir, YALNIZCA bir kez yanıtta gösterilir; geçerlilik beklenen saat
  + 12 saat (yoksa 24 saat). Sistem ziyaretçiye SMS göndermez (site dışı numaraya ileti 6563 s. Kanun kapsamında ayrı
  onay ister); sakin kodu kendisi iletir.
- `POST /visitors/verify-pass {code}` (yönetim/görevli; kullanıcı başına 10 dk'da 10 hatalı deneme), `POST
  /visitors/:id/pass` (yeni kod; kaydı açan ya da güvenlik). Giriş bildiriminin ziyaretçi kimliği artık yol
  parametresinden değil giriş kaydından alınıyor (kodla girişte bildirim kaydı ziyaretçiye işlenemiyordu).
- Sakin uygulaması: kayıttan sonra büyük PIN, QR görseli (`qr_flutter`), geçerlilik ve "PIN mesajını kopyala".
  Panel: "Geçiş kodu ile giriş" alanı (klavye gibi çalışan QR okuyucuyla da) ve kayıt sonrası kod penceresi.
  Yönetici uygulaması: "Geçiş koduyla giriş" düğmesi.

### 2026-10-05 — İŞLETME PROJESİNDEN AYLIK TAHAKKUK (migration 050, TEST_RAPORU 2.7) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1182/1182** (kesinleşen projeden 12 ay tahakkuk: 25 bölümün her birinde 12 ayın toplamı
> yıllık paya kuruşu kuruşuna eşit; elle tahakkuk edilmiş ay ve aynı ay 409, aydan önceki vade 422, taslak proje 422,
> sakin 403); panel tsc/lint temiz.

- Test raporundaki "7 günlük itiraz süresi dolmadan kesinleşmiyor" bulgusu bu turdan önce 7579 s. Kanun düzeltmesiyle
  giderilmişti (036): proje genel kurulda kabul edilen gündem maddesine bağlanınca beklemeden kesinleşir; mülga süre
  için test bayrağı EKLENMEDİ (üretim koduna zaman atlatma kapısı açılmaz). verify-stack bu akışı uçtan uca sınıyor.
- Raporda test edilemeyen ikinci yarı — kesinleşen projenin aidat tahakkukuna dönüşmesi — eksikti: `POST
  /governance/budgets/:id/assessments {period_month, due_date}`. Yıllık pay 12 aya `money.DistributeEqual` ile bölünür;
  geçici (NOTIFIED) projeden de üretilebilir (KMK m.37: genel kurula kadar geçici proje uygulanır), taslaktan üretilemez.
  `monthly_assessments.budget_id` tahakkukun kaynağını tutar.
- Panel: İşletme projesi detayında "Projeden aylık aidat tahakkuk et".

### 2026-10-05 — NET KULLANIM ALANI VE ISI PAYLAŞTIRMA ÖN DENETİMİ (migration 049, TEST_RAPORU 2.2) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1177/1177** (net alan daire/dükkân/ofiste zorunlu 422, otoparkta değil, net>brüt 422,
> sıfıra çekilemez, listede dönüyor; eksik alanla ısı paylaştırması 422 ve eksik bölüm adıyla; ön denetim ucu eksik
> bölümü listeliyor, sakin 403); panel tsc/lint temiz.

- **Kök neden:** ısı paylaştırması sabit payı `units.net_area_m2` ile dağıtıyor (Yönetmelik m.3: "bağımsız bölümün
  kapalı kullanım alanı", m.8/1: %30), ama bölüm ekleme/düzenleme bu alanı hiç almıyordu — yalnızca brüt alan vardı.
  Bu yüzden her sitede paylaştırma 422 ile duruyordu. Kimlik servisi artık `net_area_m2` alır; daire/dükkân/ofiste
  zorunlu, otopark/depoda isteğe bağlı; veritabanı kısıtı `units_area_rules`.
- `GET /consumption/area-check`: paylaştırma öncesi eksik net alanlı bölümler. Paylaştırma hatası eksik bölümleri adıyla
  (`missing_area_units`) döner.
- Demo bölümlere örnek net alan (brütün %85'i; yalnızca `SEED_DEMO_DATA` açıkken).
- Panel: Bağımsız Bölümler formunda zorunlu "Net kullanım alanı", tabloda "Eksik" rozeti, toplu eklemede
  `blok;kat;kapı;arsa payı;net m²;brüt m²`; Sayaç → Gider paylaştırma ekranında eksik alan uyarısı ve bağlantı.

### 2026-10-05 — PANEL MOBİL MENÜ (TEST_RAPORU 6.2) (DOĞRULANMIŞ, D4)

> **Kanıt:** Gerçek tarayıcı (headless Chromium, Galaxy A55 görünümü 412×915, demo yönetici girişi): menü kapalıyken
> bağlantılar görünmüyor → "Menüyü aç" ile çekmece açılıyor → bağlantıya tıklayınca sayfa değişip çekmece kapanıyor →
> × ile kapanıyor; yatay taşma yok; 1280 px'de kenar menü sabit ve menü düğmesi gizli. Panel tsc/lint temiz.

- Üst çubuktaki menü düğmesinin `onClick`'i yoktu; 1024 px altında menüye erişilemiyordu. `DashboardShell` çekmece
  durumunu tutar; `Sidebar` mobilde arka plan örtüsüyle soldan açılır, sayfa değişince kapanır.

### 2026-10-05 — TESİS TANIMLAMA VE İPTAL SON SÜRESİ (migration 048, TEST_RAPORU 2.1) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1174/1174** (tesis API'den eklendi ve sakin listesinde; demo tesisler yüklü; ters saat,
> ücretsiz ücretli tesis, geçersiz gün, notsuz bakım, üç ondalık, tanımsız kategori 422, sakin 403; bakımdaki tesise
> rezervasyon notla reddediliyor, gönderilmeyen alanlar korunuyor; 48 saatlik iptal son süresinde sakin 422, yönetim 200);
> panel tsc/lint temiz.

- Test raporu bulgusu: `POST /facilities` yoktu, demo sitede tesis yoktu, panelde tesis formu yoktu → rezervasyon akışı
  hiç başlatılamıyordu. Eklendi: `POST /facilities`, `PATCH /facilities/:id` (yönetim/kurul), sunucu tarafı kural
  denetimi + veritabanı kısıtı (`facilities_rules`), silinmiş tesis listeden çıkar.
- `cancellation_deadline_hours`: sakin rezervasyonu başlangıçtan en geç bu kadar saat önce iptal edebilir (0 = serbest);
  yönetim her zaman iptal edebilir. Kural değişikliği mevcut rezervasyonları etkilemez.
- Demo veride iki tesis (Sosyal Tesis Toplantı Salonu — onaylı, Tenis Kortu — otomatik onay); `SEED_DEMO_DATA=false` iken yüklenmez.
- Panel: Rezervasyon → Tesisler: "+ Yeni tesis" ve "Düzenle" formu (saat, gün, süre, kota, tampon, iptal süresi, ücret, bakım).

### 2026-10-05 — VERBİS BEYANI (kullanıcı kararı S-21) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1170/1170** (varsayılan "beyan edilmedi", tanımsız değer 422 + izinli değerler,
> kayıtlı + sicil no kaydı); panel tsc/lint temiz.

- VERBİS kaydı (KVKK m.16) veri sorumlusu olan site yönetiminin yükümlülüğüdür; sistem yükümlülüğü belirlemez ve beyan
  girilmemiş siteyi engellemez. Ayarlar: `VERBIS_STATUS` (beyan edilmedi / kayıtlı / muaf / değerlendiriliyor) ve
  `VERBIS_REGISTRY_NO`. Ayar kayıt defterine seçenekli metin türü eklendi (tanımsız değer 422).
- `legal/kullanim-kosullari.md` §7: sorumluluğun site yönetiminde olduğu yazıldı.

### 2026-10-05 — BORDRO KAYDI (migration 047, FAZ 7.4, kullanıcı kararı S-22=b) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1169/1169** (çalışan+dönem tekil 409, ayrılış sonrası dönem 422, maliyet<net 422,
> kaynaksız 400, gelecek dönem 422, üç ondalık 422; toplamlar kuruşu kuruşuna, bordrosu girilmemiş çalışan listesi,
> sakin 403; ikinci ödeme 409, ödenmiş kayıt iptal edilemez/değiştirilemez (tetikleyici), silinemez; yıllık maliyet);
> panel tsc/lint temiz.

- Bordro mali müşavirden gelir; sistem ücret, gelir/damga vergisi ve SGK primi **hesaplamaz**. Dönem bazında net ödeme,
  işveren maliyeti, bordronun kaynağı ve ödeme bilgisi kaydedilir; ara kalemler (brüt, SGK, vergi) isteğe bağlı ve bilgi
  amaçlıdır. 005'teki kullanılmayan `payroll` tablosu bu amaçla açıldı.
- `GET /payroll?period=`, `GET /payroll/costs?year=`, `POST /payroll`, `POST /payroll/:id/pay|cancel`. Görevli (STAFF) göremez.
- Panel: Personel → "Bordro" sekmesi (dönem seçimi, eksik bordro uyarısı, ödendi/iptal).

### 2026-10-04 — KAMERA VE BİYOMETRİK ENVANTERİ (migration 046, FAZ 7.8 kalanı) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1165/1165** (daire kapı önü 422, gerekçesiz asansör 422, saklama süresi zorunlu,
> uygunluk notları yönetime, kamera listesi sakine aydınlatma için iç notlar olmadan; alternatifsiz biyometrik 422,
> sakin envantere 403; RLS 105 tablo); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- KVK Kurumu'nun apartmanlarda güvenlik kamerası kamuoyu duyurusu (08/06/2026) uygulanıyor: mahremiyet alanına
  (daire içi/kapı önü, tuvalet, soyunma, ibadet yeri) kamera kaydedilemez; ses kaydı, yüz tanıma ve asansör kamerası
  somut gerekçe ister; saklama süresi zorunlu; levha, genel kurul kararı, maskeleme ve erişim notu eksikleri uygunluk
  notu olarak yönetime listelenir. Kamera listesi (konum, amaç, süre) sakinlere açık — KVKK m.10 aydınlatma.
- Biyometrik sistem envanteri: açık rıza ve alternatif geçiş yöntemi olmadan kaydedilmez (KVKK m.6, özgür rıza).
- Panel: Ayarlar → "Kamera ve biyometrik envanter". Sakin uygulaması: KVKK → "Ortak alan kameraları".

### 2026-10-04 — SİGORTA: DASK TAKİBİ VE HASAR KAYDI (migration 045, FAZ 7.2 / M-36) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1162/1162** (kiracı poliçe giremez, bitiyor/kayıtsız durumları, kiracıya liste boş,
> mükerrer 409, tarih 422; hasar durum makinesi, tazminatsız PAID 422, sakin 403, silinemez; DASK hatırlatması yalnızca
> malike; RLS 103 tablo); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- DASK yükümlülüğü malikin (6305 s. Kanun m.10/3): malik/vekil kendi bölümü için, yönetim her bölüm için poliçe girer;
  yönetim ekranında geçerli/bitiyor/bitmiş/kayıt yok özeti. `cmd/scheduler` `dask.renewal`: bitişe 30 gün kala ve
  bittikten sonra yalnızca maliklere hatırlatma (tapu ve su/elektrik aboneliğinde poliçe aranır, m.11). Kaydı olmayan
  bölüme hatırlatma gitmez (kayıt yokluğu sigorta yokluğu değildir).
- Ortak alan hasar/tazminat kaydı: ihbar → eksper → ödendi/reddedildi → kapandı (geri gidiş yok; PAID tutar ve tarih,
  REJECTED gerekçe ister); INSURANCE sözleşmesine bağlanabilir.
- Tadilat izni esaslı tadilat uyarısına 6305 m.12/2 eklendi (izinsiz taşıyıcı değişiklikte DASK tazminatı kaybı).
- Panel: "Sigorta (DASK)". Sakin uygulaması: "DASK poliçem".

### 2026-10-04 — METRİK VE HATA TAKİBİ (migration 044, todo 3.6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1158/1158** (mobil hata raporu kaydı, 2000 karakter kısaltma, geçersiz uygulama 422,
> saatlik sınır 429; `/metrics` rota şablonu bazında sayaç ve histogram, ham kimlik yok; gateway `/metrics` açmıyor;
> CLIENT_ERROR imha kategorisi); `go test ./pkg/middleware` (metrik); `verify-mobile.sh` 10/10 (sakin 36, yönetici 29
> test); panel tsc/lint temiz.

- Her servis `GET /metrics` (Prometheus metin biçimi, harici bağımlılık yok): rota şablonu + yöntem + durum sınıfı
  başına istek sayısı ve gecikme histogramı, çalışma süresi. Ham yol yazılmaz (kişisel veri); gateway yönlendirmez.
- `POST /client-errors` (community, 044): mobil uygulamalar (`installErrorReporting` — FlutterError ve platform
  hataları) ve panel (`(dashboard)/error.tsx`) yakalanmayan hatayı bildirir. Metin/yığın kısaltılır, kişi bilgisi
  alınmaz, kişi başı saatte 30 sınırı; KVKK imha kategorisi `CLIENT_ERROR` (silme).
- Ders 43: `pipefail` + `echo | grep -q` yanlış negatif.

### 2026-10-04 — PARA ARİTMETİĞİ: SON KAYAN NOKTA TOPLAMI KALDIRILDI (todo 4.13) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1154/1154** (yeni değişmez: her ödemenin tutarı bağlı tahakkukların toplamına eşit).

- Ödeme oluşturulurken tahakkuk kalanları `float64` ile toplanıyordu; artık metin → `decimal` okunup toplanıyor ve
  `numeric` olarak yazılıyor. Gider dağıtımındaki "birim başı ortalama" kuruşa yuvarlanıyor.
- Kapsam kararı: şema `DECIMAL` (kesin) kalır, JSON taşıma `number` kalır; Go'da para aritmetiği yalnızca
  `pkg/money`/decimal ile. Tarama: servislerde başka float para toplamı/çarpımı yok (ısı payı, tahakkuk, gecikme
  tazminatı, işletme projesi, ortak alan geliri zaten kuruş).

### 2026-10-04 — KVKK SAKLAMA VE PERİYODİK İMHA (migration 043, FAZ 7.8) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1153/1153** (3 kategori, periyodik imha 6 ay; süre/gerekçe doğrulaması; süresi dolan
> ziyaretçi anonimleştirildi, yeni ve içerideki korundu, imha kaydı yazıldı, tanımsız kategori imha edilmedi; imha
> kaydı silinemez; tanımsız siteye hatırlatma; RLS 100 tablo); panel tsc/lint temiz.

- Ziyaretçi, otopark ve kargo kayıtlarındaki kişisel veriler süresiz tutuluyordu. Site kategori bazında saklama
  süresi ve gerekçe tanımlar (`data_retention_rules`); `pkg/retention` süresi dolanları ANONİMLEŞTİRİR (kayıt ve
  tarihler kalır). Periyodik aralık `KVKK_PERIODIC_DESTRUCTION_MONTHS` = 6 (İmha Yönetmeliği m.11/2); her işlem
  silinemeyen `data_destruction_log`'a yazılır (m.7/3). Süre tanımlanmamış kategori imha edilmez (uydurma süre yok);
  `cmd/scheduler` `kvkk.destruction` yönetimi altı ayda bir uyarır.
- `GET/PUT /retention-rules`, `POST /retention-rules/run`, `GET /retention-rules/log` (settings). Panel: Ayarlar →
  "Saklama ve imha (KVKK)".
- Kurul 2026/348 ilke kararı (RG 31/3/2026; borç listesinin ortak alana asılması hukuka aykırı) kontrol edildi:
  borçlu listesi yalnızca yönetim/denetçiye açık, gecikme hatırlatması yalnızca ilgili daireye gidiyor — uyumlu.
- Bilinen sınır: kargo/ziyaretçi FOTOĞRAF bağlantıları silinir ama depolamadaki dosya (varsa) ayrıca silinmez — D2.
- Sorular: S-21 (VERBİS), S-22 (bordro kapsamı).

### 2026-10-04 — ORTAK ALAN GELİRİ (migration 042, FAZ 7.6 / M-46) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1148/1148** (oybirliği maddesi olmadan kiralama 422, sığınak 422, oybirliğiyle kayıt;
> gelir ve stopaj bütün bölümlere arsa payı oranında kuruş kaybı olmadan; stopaj brütü aşamaz; aynı dönem 409; işyeri
> olmayan kiracıdan stopaj 422; yıllık rapor; gelir kaydı değiştirilemez; sakin 403 / kendi payı 200; RLS 98 tablo);
> `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- Ortak yer kiralaması (çatı/cephe reklamı, baz istasyonu, kapıcı dairesi, otopark, depo, dükkân) bütün kat
  maliklerinin oybirliğiyle (KMK m.45; Yargıtay 20. HD 2019/2193) kabul edilmiş genel kurul maddesine bağlanmadan
  kaydedilmez. Sığınak kiralanamaz (Sığınak Yönetmeliği; 20. HD 2019/1200).
- Aylık tahsilat ve kiracının kestiği stopaj (GVK m.94; oran gömülmez, belgeden girilir) bölümlere arsa payı oranında
  `pkg/money` ile paylaştırılır. Yıllık malik payı raporu: her malik kendi payını beyan eder (Gelir İdaresi özelgesi
  01/08/2011). Gelir kaydı uygulama rolünce değiştirilemez/silinemez.
- Panel: Yönetişim → "Ortak Alan Geliri". Sakin uygulaması: "Ortak alan geliri payım".

### 2026-10-04 — VERGİ/SGK YÜKÜMLÜLÜK TAKVİMİ (migration 041, FAZ 7.7 / M-29) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1144/1144** (`go test ./pkg/compliance` hafta sonu/ay sonu kaydırma; ayrılış
> bildirgesi bitiş+10 gün gecikmiş, işe giriş bildirgesi bugün, MUHSGK 26'sı, prim ay sonu; bildirge kaydı yükümlülüğü
> kapatır, gelecek tarih ve ayrılmamış personele ayrılış 422, sakin 403; MUHSGK takvimi ayarla kapanır; zamanlayıcı
> gecikmiş ayrılış bildirgesini hatırlatır); panel tsc/lint temiz.

- Personel çalıştıran yönetim işverendir; süreler hiç izlenmiyordu. `pkg/compliance` (ekran ve zamanlayıcı aynı hesap):
  SGK işe giriş (başlamadan önce, 5510 m.8), işten ayrılış (10 gün, m.9), MUHSGK beyan ve vergi ödemesi (izleyen ayın
  26'sı, GVK m.98 / 5510 m.86), SGK primi (izleyen ayın sonu, m.88 — Kurumca belirlenen gün). Süreler
  `legal_parameters`'ta (`MUHSGK_DUE_DAY`, `SGK_PREMIUM_DUE`, `SGK_EXIT_NOTICE_DAYS`); hafta sonu VUK m.18 ile kayar.
- Sistem verginin doğup doğmadığına karar vermez (kapıcı istisnası, ticari bölüm, Kolay İşverenlik — mali müşavir);
  resmî tatil/idari uzatma bilinmez, ekranda yazar. `MUHSGK_CALENDAR` ayarıyla aylık takvim kapatılabilir.
- `GET /compliance-calendar`, `POST /employees/:id/sgk` (bildirge tarihleri; `employees.sgk_exit_date`).
  `cmd/scheduler` `compliance.employer`: son 5 gün ve süre aşımı → yönetim. Panel: Personel → "Vergi ve SGK yükümlülükleri".

### 2026-10-04 — ACİL DURUM VE AFET (migration 040, FAZ 7.3 / M-37) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1138/1138** (bilgi kartı yetki/doğrulama, tatbikat raporu eksiklik alanı ve tarih
> doğrulaması, rapor silinemez, acil kartı rızasız 422 / şifreli `k1$` / başka daireye 422 / sahibine ve yönetime
> çözülmüş / görüntüleme denetim kaydı / başka site göremez / silince gerçekten silinir, durum çağrısı bildirimi,
> tek açık çağrı 409, yardım talebi anında yönetime, yanıt vermeyen daireler, kapalı çağrıya yanıt 409, yıllık tatbikat
> hatırlatması; RLS 95 tablo); `verify-mobile.sh` 10/10 (sakin 33 test); panel tsc/lint temiz.

- Bilgi kartı: toplanma alanı, vanalar, pano, jeneratör, sığınak + acil telefonlar; sakin uygulaması son kartı
  cihazda saklar (afette internet olmayabilir). Ulusal acil numara 112.
- Tatbikat raporu (tarih, katılım, görülen eksiklikler zorunlu, düzeltici faaliyet) — İşyerlerinde Acil Durumlar Hk.
  Yönetmelik m.13 (yılda en az bir; personel çalıştıran yönetim işverendir). `EMERGENCY_DRILL_INTERVAL_MONTHS`;
  `cmd/scheduler` `emergency.drill` süre aşımında yönetime hatırlatır.
- Sakin acil bilgi kartı: yardım/sağlık bilgisi özel nitelikli veri (KVKK m.6, 7499 s. Kanunla değişik). Güncel metne
  açık rıza olmadan kaydedilmez; `pkg/pii` ile şifreli; yalnızca yönetici/kurul görür, her görüntüleme
  `SENSITIVE_REVEAL` denetim kaydı (yazılamazsa veri gösterilmez); sakin silince veri silinir (m.7). Anahtar yoksa
  kart uçları 503 — şifresiz yazılmaz. community servisine `PII_ENCRYPTION_KEY` verildi (compose/k8s üretildi).
- Afet sonrası durum bildirimi: çağrı bütün sakinlere gider; "Güvendeyim / Yardım gerekiyor"; yardım talebi yönetime
  anında; yanıt vermeyen daireler listelenir.
- `cmd/rotate-pii` acil kartlarını da yeniden şifreler ve raporlar. **Not:** bu yol derleniyor ama uçtan uca
  döndürme testinde acil kartı yok (doğrulamadaki kartlar silme testinde siliniyor) — D2.
- Panel: "Acil Durum". Sakin uygulaması: Daha Fazla → "Acil durum" (bilgi kartı, durum bildirimi, acil bilgi kartım).

### 2026-10-04 — KURAL İHLALİ (migration 039, FAZ 7.5 / M-44) + AYAR KORUMASI (038) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1127/1127** (dayanaksız kural 422, bildiren gizliliği, çapraz site 404, doğrulamasız
> uyarı 409, sakin doğrulayamaz 403, kademe yalnızca ileri, açıklamasız yazılı uyarı 422, uyarı kiracıya da gider,
> savunma yalnızca dairenin sakininden, gerekçesiz ret 422, olay geçmişi değiştirilemez/kayıt silinemez, tekrar
> sayısı; sonradan eklenen mevzuat parametreleri site ayarıyla gölgelenemez; RLS 89 tablo); `verify-mobile.sh` 10/10
> (sakin 31 test); panel tsc/lint temiz.

- Kural kataloğu yönetim planı dayanağı ister (KMK m.28). İhlal bildirimi (sakin/yönetim), doğrulama/ret, kademeli
  süreç (sözlü uyarı → yazılı uyarı → ihtar → hukuki yol, KMK m.33 / m.25-b), savunma, salt-ekleme olay geçmişi,
  son 24 ayda tekrar sayısı. Uyarı dairenin bütün aktif sakinlerine gider (kiracı malikle müteselsil, m.18/2).
- Bildirenin kimliği ihlal bildirilen daireye gösterilmez; para cezası alanı bilerek yok (Kabahatler K. m.22).
- 038: `property_settings` tetikleyicisi, `legal_parameters`'ta kodu olan her anahtarı reddeder (017'deki sabit ön ek
  listesi KVKK_/REVALUATION/BUDGET_GA gibi sonradan eklenenleri kapsamıyordu).
- Panel: "Kural İhlalleri" (katalog, kayıt, kademe, olay geçmişi). Sakin uygulaması: "Kural ihlali bildir" (bildirim, savunma).

### 2026-10-04 — TADİLAT İZNİ (migration 037, FAZ 7.5 / M-45) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1114/1114** (kiracı başvuramaz 403, doğrulama 422, onay yetkilisine bildirim,
> site tadilat saati ve teminat izne kopyalanır, aynı blok komşularına adsız bildirim, gerekçesiz teminat kesintisi /
> iadede aşım 422, esaslı tadilat ruhsatsız onaylanmaz, 4/5 kat maliki rızası (kişi sayısı, yukarı yuvarlı), kiracı
> rızası 422, mükerrer rıza 409, gerekçesiz durdurma 422, kayıt silinemez; RLS 86 tablo); `verify-mobile.sh` 10/10
> (sakin 29 test); panel tsc/lint temiz.

- Tadilatın hiçbir kaydı yoktu. `/api/v1/renovations` (community): başvuru (malik/vekil), onay, ret, durdurma,
  denetimle kapatma ve teminat iadesi.
- Kapsama göre hukuki ön koşul hem uygulamada hem veritabanı CHECK'inde: **STRUCTURAL** → yapı ruhsatı/izin no
  (3194 s. İmar K. m.21; anayapıya zarar veren değişiklik yasak, KMK m.19/2). **COMMON_AREA / FACADE** → bütün kat
  maliklerinin 4/5 yazılı rızası (`MAJORITY_CONSTRUCTION_CONSENT`, kişi sayısıyla) ya da bu nisapla kabul edilmiş
  genel kurul maddesi.
- Çalışma saati ulusal mevzuatta konut içi tadilat için yok (Çevresel Gürültü Kontrol Yönetmeliği komşu/evsel
  gürültüyü kapsamaz) → site ayarı `RENOVATION_HOURS`; onayda izne kopyalanır.
- Para cezası özelliği bilerek yok: idari yaptırım yetkisi kanunda gösterilen kamu mercilerindedir
  (5326 s. Kabahatler K. m.22; gürültüde kolluk/zabıta, m.36/3).
- `notify.BlockNeighbors`: aynı bloktaki komşular (dairenin kendi sakinleri hariç), kişi adı olmadan.
- Panel: "Tadilat İzinleri" (rıza kaydı, onay/ret/durdurma, teminat iadesi). Sakin uygulaması: Daha Fazla → "Tadilat izni".

### 2026-10-04 — İŞLETME PROJESİ 7579 SAYILI KANUNA UYUMLU (migration 036) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1098/1098** (gündem maddesiz kesinleştirme 422, geçici proje 3 aylık
> genel kurul süresi, mülga 7 günlük süre yazılmıyor, kabul edilmiş gündem maddesiyle kesinleşme, aynı maddenin
> ikinci kez kullanımı 409, %25,49 tavanı aşan geçici proje reddi, oranı ilan edilmemiş yılda tavan uydurulmuyor,
> zamanlayıcı süre hatırlatması); `verify-mobile.sh` 10/10; panel tsc/lint temiz.

- **Mevzuat değişikliği:** 7579 s. Kanun (RG 22/5/2026, sayı 33261) KMK m.35, 37 ve 70'i değiştirdi. İşletme projesi
  artık **genel kurulda onaylanır**; "tebliğden itibaren 7 gün içinde itiraz edilmezse kesinleşir" cümlesi **mülga**.
  Sistem bu tarihten sonra da eski kuralı uyguluyordu: yönetici 7 gün sonra projeyi tek başına "kesinleşti — İİK m.68
  belgesi" yapabiliyordu. Kaynak: mevzuat.gov.tr konsolide KMK metni.
- Bildirilen proje artık **geçici işletme projesidir** (onaylanana kadar avans dayanağı, m.35/d); en geç **3 ay**
  içinde genel kurulda karara bağlanmalı (`BUDGET_GA_APPROVAL_MONTHS`, kanunla sabit). Kesinleştirme, bu sitenin
  yapılmış toplantısında **kabul edilmiş gündem maddesi** (`agenda_item_id`) ister; karar referansı otomatik üretilir.
- **Geçici proje tavanı (m.37 son f.):** yürürlükteki kabul edilmiş proje varsa geçici projenin toplamı, onun bir önceki
  yıla ilişkin VUK mük. m.298 yeniden değerleme oranı kadar artırılmış tutarını aşamaz. `REVALUATION_RATE` 2026 dönemi
  için 0,2549 (VUK Genel Tebliği Sıra No 585, RG 27/11/2025). Oran ilan edilmemiş yılda tavan uydurulmaz, işlem
  gerekçesiyle reddedilir. Dayanak proje, oran ve tavan kayda yazılır.
- `BUDGET_OBJECTION_DAYS` yürürlüğü 22/5/2026'da kapatıldı (eski projelerin itiraz süresi geçmişe dönük doğru kalır).
  İtirazlar genel kurulda görüşülecek görüş olarak kaydedilmeye devam eder; kesinleşmeyi engellemez.
- `cmd/scheduler`: `budget.approval` — genel kurul son gününe 30 gün kala (çağrı için 15 gün gerekir, m.29) ve süre
  aşımında yönetime hatırlatma.
- Panel: "Geçici proje olarak bildir" + "Genel kurul kararıyla kesinleştir" (yapılmış toplantı → kabul edilen madde);
  tavan ve karar referansı gösterilir. Yönetici uygulaması: durum etiketleri ve genel kurul son günü.
- Kalan: KMK m.70 (toplu yapı yönetim planı değişikliği 4/5 → 2/3) sistemde toplu yapı kavramı olmadığından uygulanmadı.

### 2026-10-04 — KVKK İLGİLİ KİŞİ BAŞVURULARI (migration 035, FAZ 7.8) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1090/1090** (başvuru, 30 günlük son gün, doğrulama, yönetim bildirimi,
> yetki, gerekçesiz ret yok, sahibine yanıt bildirimi, silinemezlik, zamanlayıcı süre hatırlatması; RLS 84 tablo).

- KVKK m.11 başvurusunu almanın, m.13/2'deki 30 günlük süreyi izlemenin ve yanıtı kayda geçirmenin yolu yoktu.
  `GET/POST /kvkk-requests`, `POST /kvkk-requests/:id/respond` (community). Süre `legal_parameters`
  (`KVKK_RESPONSE_DAYS`, kanunla sabit); son gün başvuru anında yazılır; kayıt uygulama rolünce silinemez.
- `cmd/scheduler`: son 5 gün ve süre aşımı için yönetime hatırlatma.
- `check-gateway-routes.py` artık main paketinin bütün dosyalarını okur (rota main.go dışında kaydedilebilir).
- Panel: "KVKK Başvuruları" (süre rozeti, gerekçeli yanıt). Sakin uygulaması: Daha Fazla → "KVKK başvurusu" (başvuru ve sonuç). verify-mobile 10/10 (sakin 27 test).

### 2026-10-04 — YÖNETİŞİM: KİŞİ–DAİRE BAĞI DENETİMİ (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1081/1081**.

- Hazirun cetveline ve icra takibine (borçlu) o daireyle hiçbir bağı olmayan kişi yazılabiliyordu;
  yanlış kişiye takip açılabilirdi. Artık kişinin o bölümle (geçmiş dahil) sakinlik bağı aranır → 422.
- Duyuru, anket, anket yorumu, sayaç ve sayaç okuması listelerinde de kesilme bildiriliyor (B69).

### 2026-10-04 — LİSTE KESİLMESİ BİLDİRİLİYOR (B69 kalanı) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1080/1080** (501 ziyaretçiyle: 500 kayıt + `truncated:true`); `go test ./pkg/listcap/`.

- Ziyaretçi, otopark hareketi, kargo, rezervasyon, belge ve sözleşme listeleri 500'de sessizce kesiliyordu.
  `pkg/listcap`: sorgu tavan+1 okur, yanıt `truncated`/`limit` taşır; panel `QueryView` kesilmeyi her
  listede otomatik söyler.

### 2026-10-04 — BAKIM / PERİYODİK KONTROL HATIRLATMASI (FAZ 7.1 ilk dilim) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1078/1078** (§40: 5 gün kalan ve 3 gün geçmiş demirbaş yönetime bildirildi;
> 60 gün sonraki ve hurdaya ayrılmış olana bildirim yok; ikinci turda yeni kayıt yok).

- Demirbaşın bakım tarihi (asansör yıllık periyodik kontrolü, yangın tüpü dolumu vb.) geçse bile kimse
  uyarılmıyordu. `cmd/scheduler` artık 14 gün kala "yaklaşıyor", tarih geçince "geçti" bildirimi üretir
  (demirbaş + tarih + durum başına bir kez). Yasal aralıklar koda gömülmez; demirbaşın bakım aralığı
  olarak yönetim girer.

### 2026-10-04 — AÇILIŞ (DEVİR) BAKİYESİ (migration 034, FAZ 8.1 tamam) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1077/1077** (devir girişi bakiyeyi tam tutar artırıyor, ikinci devir 409,
> vadesi geçmiş devire tazminat işlemiyor, ödemesi olan devir iptal edilemiyor; panel sözleşmesi 64 uç);
> `verify-mobile.sh` 10/10 (sakin 26 test). Panel `tsc`/`lint`/`build` temiz.

- Önceki yönetimden devreden borcu girmenin yolu yoktu. Tahakkuka `kind` (REGULAR/OPENING) ve açıklama;
  dönem benzersizliği yalnızca olağan tahakkuklar için. `GET/POST /finance/opening-balances`, `:id/cancel`.
- Devir; bakiye, borçlu listesi ve ödemeye girer; dönem tahsilat özetine girmez; **otomatik gecikme
  tazminatı işletilmez** (önceki hesap bilinmez, çift tahsilat olurdu — panel bunu girişte söyler).
- Panel: tahakkuk sayfasında "Devir bakiyeleri" (Excel'den yapıştırma, iptal). Sakin uygulaması devir
  kaydını dönem adıyla değil "Devir bakiyesi" olarak gösterir.

### 2026-10-04 — TOPLU SAKİN İÇE AKTARMA (FAZ 8.1) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1072/1072** (tek istekte 5 satır: hesap açıldı + kod, var olan hesap
> bağlandı, başka sitedeki kişiye davet, eksik alan, yönetim rolü reddi — hatalı satırlarda hesap açılmadı).
> Panel `tsc`/`lint`/`build` temiz.

- `POST /residents/bulk` (en çok 500): satırlar bağımsız işlenir ve her birinin sonucu döner; hiçbir satır
  sessizce atlanmaz. Etkinleştirme kodları yalnızca bu yanıtta görünür.
- Panel: sakinler sayfasında "Toplu ekle" (`ad;soyad;telefon;daire;sıfat`, Excel'den yapıştırma; daire
  bulunamayan satır gönderilmeden bildirilir) ve sonuç penceresi (kodlar bir kez).
- Hata eşlemesi tek yerde (`residentError`); tekil ve toplu uç aynı mesajları verir.

### 2026-10-04 — GÖREVLENDİRME (yönetici/kurul/denetçi/görevli) + İŞ SAAT DİLİMİ (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1071/1071** (8 yeni kontrol; ayrıca Türkiye saatiyle 01:00'de koşuldu);
> `go test ./pkg/database/...` (saat dilimi).

- `property_roles`'a yazan hiçbir uç yoktu: kurucu dışında kimseye yönetim/kurul/denetçi/görevli rolü
  verilemiyor, görevi biten birinin yetkisi kaldırılamıyordu. `GET/POST /property-roles`,
  `POST /property-roles/:id/end`: yalnızca yönetici atar; yönetici/kurul/denetçi için karar bilgisi
  zorunlu (KMK m.34/41); bağsız hesaba görev verilmez; görev sonlandırılınca kişinin oturumları hemen
  kapanır; sitenin tek yöneticisi sonlandırılamaz (eşzamanlı sonlandırmaya karşı kilitli); geçmiş silinmez.
  Panel: "Görevlendirmeler" sayfası (liste, görev ver, sonlandır; sözleşme denetimi 63 uç).
- **Saat dilimi hiçbir yerde ayarlı değildi:** veritabanı "bugün"ü UTC ile, Go süreçleri yerel saatle
  hesaplıyordu; Türkiye'de her gece 00:00–03:00 arasında farklı gün görüyorlardı (bugün başlayan görev
  "yarın başlıyor" sayıldı). Artık `pkg/database` Go sürecini ve her veritabanı oturumunu `APP_TIMEZONE`
  (varsayılan Europe/Istanbul) ile sabitler; tzdata ikiliye gömülü. Doğrulama betiği de `PGTZ` kullanır.

### 2026-10-03 — SİTE KURULUMU: YENİ SİTE YÖNETİLEMİYORDU (migration 033, FAZ 8.1 ilk dilim) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1063/1063** (8 yeni kontrol: kurucu MANAGER + sahte daire yok, toplu
> bölüm ekleme, harf duyarsız çakışma 409 ve hiçbiri yazılmıyor, doğrulama 422, kısmi güncelleme, kiracı 403,
> 033 dönüşümü). Panel `tsc`/`lint`/`build` temiz.

- Site oluşturma kurucuyu sahte bir "YÖNETİM" bölümüne (arsa payı 0) **malik** yapıyordu: kurucunun yönetim
  rolü olmadığı için yeni site hiç yönetilemiyordu (sakin/daire eklenemiyordu) ve sahte bölüm eşit
  dağıtılan giderlerden pay alıyordu. Artık kurucu `property_roles`'ta geçici MANAGER (KMK m.34 teyit notuyla).
- Bağımsız bölüm eklemenin hiçbir yolu yoktu: `POST /units` (tek/toplu, tek işlem), `PATCH /units/:id`.
  Blok/kapı çakışması harf duyarsız denetlenir (veritabanı kısıtı "A"/"a" ve bloksuz bölümleri kaçırıyordu).
  `GET /units` silinmiş bölümleri artık göstermiyor; birim uçları denetim izine yazılıyor.
- 033: önceden açılmış sitelerdeki sahte bölümler silindi işaretlenir, kurucuya yönetici rolü verilir;
  sahte bölüme yazılmış tahakkuk silinmez, uyarı verilir.
- Panel: "Bağımsız Bölümler" sayfası (liste, ekle, düzenle, Excel'den toplu yapıştırma).

### 2026-10-03 — SAKİN DAVETİ (S-20 kararı, migration 032) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1055/1055** (§39'da 13 kontrol: 202 + bağ yok + kişisel veri yok,
> çift davet 409, yönetim listesi, kiracı 403, davetlinin listesi, başkasının daveti 404, kabul → bağ +
> ACCEPTED + site listesinde, tekrar 409, iptal → 409, süre dolumu → görünmez/409/EXPIRED, yeniden davet;
> panel sözleşmesi 62 uç; RLS 83 tablo). `verify-mobile.sh` 10/10 (sakin 25, yönetici 27 test). Panel build temiz.

- Başka sitede kayıtlı kişinin telefonuyla sakin eklenince artık **davet** açılır (202); kişi sakin
  uygulamasının ana sayfasında kabul/ret eder, kabulde daire bağı aynı işlemde kurulur. Yöneticiye kişinin
  adı/e-postası gösterilmez. 14 gün geçerli, yönetim iptal edebilir, geçmiş silinmez.
- Panel: sakinler sayfasında "Sakin davetleri" (durum, iptal); yönetici uygulaması "Davet gönderildi" penceresi.
- `resident_invitations` yalnızca kimlik rolüne açık (uygulama rolünden yetki geri alındı), RLS açık.
- S-19 (anahtar deposu): kullanıcı kararıyla şimdilik k8s Secret. `servicecore-api-doc/` kullanıcı isteğiyle silindi.

### 2026-10-03 — BİLDİRİMDE ALICI ÜYELİĞİ HER ZAMAN DENETLENİYOR (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1042/1042** (§24: siteye kayıtlı olmayan kullanıcı + açık adres → 404, kayıt yok).

- `recipient_user_id` ile birlikte açık adres verilirse kişinin bu sitede kayıtlı olduğu denetlenmiyordu;
  başka sitenin kullanıcısı adına bildirim kaydı açılabiliyordu. Ayrıca `api/openapi.yaml` bayat olarak
  işaretlendi (B97; geçerli sözleşme `tasks/api-sozlesmesi.md`).

### 2026-10-03 — ÖDEME LİSTELERİ SAYFALI (B69) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1041/1041** (`?limit=1` → 1 kayıt + doğru `total`, `limit=501` → 400);
> `verify-mobile.sh` 10/10; panel `build` temiz.

- Yönetici ödeme listesi ve sakinin ödeme geçmişi sabit `LIMIT 50` ile **sessizce** kesiliyordu.
  Artık `limit` (varsayılan 50, en çok 500) / `offset` ve yanıtta `total`. Panel "daha eskileri göster"
  ve kesilme notu; yönetici uygulaması 500 ister, tavanda not gösterir. Diğer listelerdeki 200–2000
  güvenlik tavanları kaldı (todo).

### 2026-10-03 — SAHTE GÜVENCE VEREN TESTLER KALDIRILDI (B96) (DOĞRULANMIŞ)

> **Kanıt:** `go build ./...` + `go vet ./...` temiz; `verify-stack.sh` → **1040/1040**.

- `services/finance/handlers/finance_test.go` ve `services/identity/handlers/auth_test.go` gerçek
  handler/servis kodunu HİÇ çağırmıyordu: kendi içlerinde yazılmış sahte router ve fonksiyonları
  sınıyorlardı. Örneğin `TestDistributionCalculation` geçerken gerçek tahakkuk dağıtımı kuruş
  kaybediyordu. "go test geçiyor" izlenimi yanlıştı; kaldırıldı. Bu uçların gerçek sınaması
  `verify-stack.sh` §5–§10 ve §39'dadır.
- `go.mod`: doğrudan kullanılan `shopspring/decimal` "indirect" işaretliydi (`go mod tidy`).

### 2026-10-03 — AİDAT TAHAKKUKU KURUŞ DOĞRULUĞU + SAYAÇ KALEMİ SESSİZ DAĞITIMI (4.4, B70, B71, B75) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1040/1040** (tahakkuk oluşturma ucu ilk kez sınanıyor: 1000 + 777,77 + 100,01
> → toplam 1877.78 birebir, her daire = kalem satırları toplamı, her kalem = payların toplamı; "Isınma" → 400,
> kayıt yok). `verify-mobile.sh` 10/10 (yönetici 26 test), panel `tsc`/`lint`/`build` temiz.

- `POST /finance/assessments` dağıtımı `float64` ile yapıyor, her daire ayrı yuvarlanıyordu (1.000 TL /
  3 daire → 999,99). todo 4.4 "kuruş dağıtımı" yalnızca YENİ yazılan kodu kapsıyordu; bu eski yol kalmıştı.
  Artık `money.Distribute` (en büyük kalan), daireler kimlik sırasıyla (B70).
- `METER_READING`/`CUSTOM` kalemleri **sessizce arsa payıyla** bölünüyordu ("Isınma" dahil). Gider ve
  işletme projesi servisleri gibi artık reddedilir; panel ve yönetici uygulaması bu kalemleri seçtirmez.
- B71: talep numarası çakışmasında yeni numarayla yeniden deneme (5 kez).
- B75: ödeme listelerinde denetimsiz tip dönüşümü (sürücü farklı tip dönerse panic) kaldırıldı.

### 2026-10-03 — GÜVENLİK: DAİRE BAĞI ROLÜYLE YETKİ YÜKSELTME KAPATILDI (migration 031) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1037/1037**; §39: `MANAGER` rolüyle sakin ekleme → 422 (hesap açılmadı),
> `SUPER_ADMIN` güncellemesi → 422, veritabanı CHECK'i doğrudan yazımı reddediyor, kısıt mevcut satırlarla doğrulandı.

- `resident_units.role` jeton rollerine olduğu gibi giriyordu ve değer hiçbir katmanda doğrulanmıyordu.
  Sakin yazma yetkisi olan **yönetim kurulu üyesi kendi hesabını `MANAGER` rolüyle bir daireye bağlayıp
  yönetici olabiliyordu** (KMK m.34 atama izini atlayarak); `SUPER_ADMIN` dizesi de jetona giriyordu.
- Üç katman: servis yalnızca OWNER/TENANT/PROXY kabul eder (422); rol türetimi bağdan yalnızca bu
  değerleri alır (eski hatalı bağ yetki vermez); 031 CHECK kısıtı (NOT VALID + uygunsa doğrulama;
  uygunsuz eski satır silinmez, uyarı verilir).
- Ayrıca (B65): talep durum geçişleri karşılaştır-ve-değiştir (eşzamanlı ikinci geçiş 409; kilitli
  satırla gerçek yarış sınaması) ve sakin güncellemesi tek atomik UPDATE (kayıp güncelleme yok).

### 2026-10-03 — TALEP KAYDINDA DAİRE YAZILIYOR (B63) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1031/1031**; tek daireli kiracının talebi dairesine bağlanıyor,
> başkasının dairesi belirtilirse 422 ve kayıt yok.

- `requests.unit_id` hiç yazılmıyordu; daire bazlı talep raporu yapılamıyordu. Artık isteğe bağlı
  `unit_id` (çağıranın aktif dairesi olmak zorunda) ya da tek dairesi; birden çok dairesi olup
  daire belirtmeyenin ve görevli/yöneticinin (ortak alan) talebi dairesiz kalır.

### 2026-10-03 — YÖNETİCİ UYGULAMASI MENÜSÜ FAIL-CLOSED (B26, roadmap 2.10) (DOĞRULANMIŞ, D3)

> **Kanıt:** `verify-mobile.sh` → **10/10** (yönetici testleri 21 → 25, `nav_access_test.dart`).

- Roller boşsa (alınamadıysa ya da giren kişi sakinse) **bütün menü** görünüyordu (`_roles.isEmpty ||`).
  Veri sunucuda `RequireRole` ile korunuyordu ama her ekran 403'e gidiyordu. Artık menü yalnızca
  rolün açtığı öğeleri gösterir; yönetim rolü olmayan kişiye "bu uygulama yönetim içindir" + çıkış.

### 2026-10-03 — SAKİN EKLERKEN BAŞKA SİTENİN HESABI SESSİZCE BAĞLANIYORDU (B25, roadmap 2.15) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1029/1029**; §39: bu siteyle bağı olmayan hesabın telefonu → 409,
> bağlantı kaydı yok, yanıtta o kişinin adı/e-postası yok; aynı sitedeki kişi ikinci daireye bağlanıyor.

- Telefon başka sitede kayıtlı bir hesaba aitse hesap yöneticinin dairesine sessizce bağlanıyor,
  yanıtta kişinin **gerçek adı, soyadı ve e-postası** dönüyordu (KVKK); kişinin uygulamasında
  ilgisiz bir site beliriyordu. Artık yalnızca bu sitede zaten sakin/görevli olan hesap bağlanır.
- İşlevsel sonuç ve davet akışı seçenekleri: `tasks/questions.md` S-20.

### 2026-10-03 — SİTE ÖDEME LİSTESİ ÖDEMENİN KENDİ SİTESİNE BAĞLI (B56, roadmap 4.8) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1026/1026**; §10: ödeyenin site üyeliği pasifleşince ödeme
> yönetici listesinde kalıyor ve ödemenin dairesiyle (A Blok D.3) gösteriliyor.

- Liste ödeyenin **bugünkü** üyeliğine göre süzülüyordu: siteden taşınan sakinin geçmiş ödemeleri
  yönetici listesinden kayboluyor, daire sakinin rastgele bir dairesinden (`LIMIT 1`, sırasız)
  geliyordu. Artık `payments.property_id` (023) ve `payments.unit_id`.

### 2026-10-03 — TAHSİLAT ORANI KAYAN NOKTA HATASI (B54, roadmap 4.6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1025/1025**; §10: oran ve durum bağımsız `Decimal` hesabıyla
> üç durumda birebir (1200/1200, 348/1200 → %29,0, 1199,99/1200 → %99,9 "active").

- `int(tahsil / tahakkuk * 100)` kayan nokta hatasıyla tam yüzdeleri de bir aşağı kesiyordu
  (348/1200 → 28,999… → **%28**) ve %99,9'u %99 yapıyordu. Panel ve yönetici uygulaması ise
  tam sayıya **yuvarlıyordu**: %99,9 tahsil edilmiş dönem "%100" görünebiliyordu.
- Oran artık SQL'de `numeric` ile, tek ondalığa aşağı yuvarlanarak; "completed" yalnızca
  tahsilat ≥ tahakkuk iken. Panel (dönem tablosu, ana sayfa) ve yönetici uygulaması tek ondalık gösterir.

### 2026-10-03 — ÇİFT ÖDEME KAYDI ENGELLENDİ (roadmap 4.5) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1022/1022**; §10: aynı aidat için ikinci ödeme → 409, tek PENDING kayıt.

- Aynı tahakkuk için ikinci `PENDING` ödeme açılabiliyordu (çift dokunma, zaman aşımında yeniden
  deneme). Yönetici ikisini de onaylarsa borç iki kez düşer, sakin fazla ödemiş görünürdü.
  Denetim tahakkuk satırlarının `FOR UPDATE` kilidi altında yapılır; eşzamanlı istekler de yakalanır.

### 2026-10-03 — BORÇLU LİSTESİ DAİRE BAZLI (B55, roadmap 4.7) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1021/1021**; §10: iki malikli daire tek satır ve borç bir kez
> (1200.00), malik pasifleşince daire listede kalıyor ve "Kayıtlı malik/sakin yok" diyor.
> Panel `tsc`/`lint`/`build` temiz.

- Liste aktif MALİK üzerinden kuruluyordu: maliki kayıtlı olmayan dairenin borcu **hiç görünmüyor**,
  hisseli dairenin borcu malik sayısı kadar **tekrarlanıyordu** — yönetici uygulamasının "Toplam borç"u
  bu listeyi topladığı için gerçek alacaktan büyük çıkıyordu.
- Artık daire başına tek satır (`unit_id` eklendi); kişi = aktif malikler, malik yoksa sakin
  ("malik kayıtlı değil" işaretiyle), vekil borçlu sayılmaz. Panel satır anahtarı `unit_id`.

### 2026-10-03 — MOBİL: YAYIN SÜRÜMÜ AĞA ÇIKAMIYORDU + BELGE AÇMA (DOĞRULANMIŞ, D3)

> **Kanıt:** `verify-mobile.sh` → **10/10** (sakin testleri 17 → 24; yeni "release manifestinde
> INTERNET izni" kontrolü). Belge açma cihazda elle denenmedi (WSL'de emülatör/Android SDK yok);
> sunucunun `X-Document-SHA256` başlığı `verify-stack.sh` §19'da dosya baytlarıyla sınanıyor.

- **İki uygulamanın da ana AndroidManifest'inde INTERNET izni yoktu.** Flutter şablonu izni yalnızca
  debug/profile manifestlerine koyar: geliştirmede her şey çalışır, mağaza sürümü API'ye hiç
  bağlanamazdı. Eklendi; verify-mobile artık denetliyor.
- Sakin uygulamasında belgeler açılabiliyor: `/documents/:id/download` → `X-Document-SHA256` ile
  bütünlük doğrulaması (tutmazsa açılmaz) → geçici dizin (önceki indirilenler silinir) →
  `open_filex`. Dosya adı yol ayırıcılarından arındırılır. "Mobilde yalnızca listelenir" uyarısı kaldırıldı.

### 2026-10-03 — MOBİL: ANALİZ UYARILARI SIFIR, BİLGİ DÜZEYİ KAPI OLDU (0.C.6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-mobile.sh` → **8/8** (sakin 17, yönetici 21 test; analyze "hata/uyarı/bilgi yok").

- 63 bilgi uyarısı giderildi (`dart fix` + elle: `Matrix4.scaleByDouble`, ödeme yöntemi seçimi
  `RadioGroup`'a taşındı). `--no-fatal-infos` verify-mobile ve CI'dan kaldırıldı.

### 2026-10-03 — HASSAS VERİ OKUMA KAYDI KANITLANDI (3.4) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1019/1019** (§31'e 3 kontrol).

- Korumalı her GET zaten `VIEW` olarak yazılıyordu ama hiçbir kontrol bunu sınamıyordu.
  Artık: maaş içeren personel kaydını okuyan yönetici (kullanıcı, site, kayıt kimliği, 200),
  sakin listesini okuyan yönetici ve personel kaydına erişmeye çalışan sakin (`DENIED`, 403)
  denetim izinde doğrulanıyor. Sınır: liste okumalarında tek tek kayıt kimliği yazılmaz.

### 2026-10-03 — SAKİN BAKİYESİ HERKES İÇİN 0 GÖRÜNÜYORDU (migration 030, 4.12) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1016/1016**; §10: API `current_balance` bağımsız SQL toplamına
> birebir eşit (1200.00 TL, `has_debt:true`), onaydan sonra tam 1.200,00 düşüyor (→ 0.00).

- `unit_balances` (001) bakiyeyi `ledger_lines`'tan hesaplıyordu; bu tabloya **hiçbir kod
  yazmıyor**. Sakinin borç durumu ucu herkes için `current_balance:0`, `has_debt:false`
  dönüyor, mobil uygulama borçlu sakine "borç yok" gösteriyordu.
- Doğrulamadaki "ödeme sonrası has_debt:false" kontrolü ödeme öncesinde de geçerdi — hiçbir şey
  kanıtlamıyordu. Yerine bağımsız sayısal karşılaştırma yazıldı (4.12).
- 030: görünüm tahakkuklardan (`monthly_assessments`, silinmişler hariç) hesaplanır; panel
  borçlu listesiyle aynı kaynak. Kolon adları/anlamları korundu, `security_invoker` korundu.
  `ledger_*` tabloları ileride çift taraflı muhasebe için duruyor.
- Ayrıca: yanlışlıkla izlenen iki servis ikilisi (`backend/finance`, `backend/identity`,
  toplam ~37 MB) depodan çıkarıldı, `.gitignore` tamamlandı.

### 2026-10-03 — KİŞİSEL VERİ ANAHTARI DÖNDÜRME (todo 8, roadmap 2.18) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **1012/1012**; yeni adım 42 (15 kontrol) gerçek bir döndürmeyi
> yürütür: k1 → k2+k1 (eski kayıt okunuyor, yinelenen TCKN 409) → uygulama rolüyle araç
> başlamıyor → eksik anahtarla hata + sıfır değişiklik → `-dry-run` → döndürme → tekrar
> (0 kayıt) → yalnızca k2 → tanımsız anahtarla 500 (veri boş gösterilmiyor).
> `go test ./pkg/pii/...` → eski biçim, AAD, aday indeksler, ortam ayrıştırma (8 yeni test).

- **Önce:** tek anahtar vardı, şifreli metin hangi anahtarla yazıldığını taşımıyordu; anahtar
  sızsa bile değiştirilemezdi (değişirse bütün personel kayıtları okunamazdı). Aynı 32 bayt hem
  AES-GCM hem HMAC anahtarıydı.
- `pkg/pii` anahtar halkası: `PII_ENCRYPTION_KEY_ID` (varsayılan `k1`),
  `PII_ENCRYPTION_PREVIOUS_KEYS` (yalnızca çözmek için). Biçim `k2$<base64>`; kimlik AAD olarak
  bağlı. Şifreleme ve arama anahtarı HKDF ile ayrı türetilir. Eski kimliksiz biçim okunmaya devam eder.
- `cmd/rotate-pii`: siteyi kendi işleminde taşır, çözülemeyen kaydı ATLAMAZ (işlemi geri alır),
  sonunda anahtar kimliğine göre sayar; "eski anahtar boşaltılabilir" yalnızca sayım sıfırsa.
- **Bulunan iki sessiz hata:**
  1. Arama anahtarı türetmesi değiştiği için (anahtar aynı kalsa bile) benzersiz indeks eski
     kayıtları yakalamıyordu → aynı TCKN'li ikinci aktif personel açılabilirdi. Personel
     servisi artık halkadaki bütün anahtarların aday değerleriyle denetler.
  2. `cmd/encrypt-pii` uygulama rolüyle çalıştırılırsa `properties` RLS yüzünden SIFIR site
     görüp "düz metin kalmadı" diyordu. İki araç da artık rolün bütün siteleri gördüğünü
     doğrulamadan başlamaz (`dbscope.RequireAllSitesRole`).
- Dağıtım: compose/k8s'e iki isteğe bağlı değişken (`gen-deploy.py`), `.env.example`.
- Yordam: `docs/runbook-anahtar-dondurme.md`.
- **Kalan (kullanıcı kararı, questions S-19):** anahtar deposu (vault/KMS) seçimi. Bugün
  anahtarlar ortam değişkeni / k8s Secret ile verilir.

### 2026-09-27 — MIGRATION GERİ ALMA YORDAMI (1.6) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **997/997**; adım 41: yedek → tablo silme + ödemeleri silme +
> sahte sürüm + artık tablo → geri yükleme → şema, sürüm, RLS (82), politikalar, ödeme özeti,
> denetim izi yedekle birebir; uygulama rolü RLS kapsamıyla çalışıyor; `cmd/migrate` sağlamaları geçiyor.

- Karar: "down" betiği yazılmadı — denetim izi, belge erişim kaydı ve defterleri silen bir
  geri alma hukuken saklanması gereken kaydı yok eder; hiç çalıştırılmayan down betikleri de
  sessizce bozulur. Geri alma = yedekten geri yükleme.
- `backend/scripts/db-backup.sh` (yedeğin okunabildiğini doğrular), `db-restore.sh` (veritabanı
  adı onayı, tek transaction, yedekte olmayan tabloyu SİLMEZ → çıkış 3 ile bildirir).
- Yordam: `docs/runbook-veritabani-geri-alma.md`.

### 2026-09-27 — KONG TEK YUKARI AKIŞA İNDİ + BELGE YÜKLEME SINIRI (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **990/990** (Kong yapısı, 3 MB belge → 413 ve depoya yazılmadı).

- **Kong:** 26 servisi tek tek yönlendiriyordu ve rotalar gateway'den sapmıştı (finans
  `/api/v1/assessments` gibi var olmayan yollar, `/dashboard/*` yok); jwt eklentisi jeton
  iptalini bilmiyordu. Artık yalnızca gateway'in önünde kenar katmanı: IP başına hız
  sınırı (`/api/v1/auth` 20/dk), 25 MB gövde sınırı. Kimlik, başlık temizliği, CORS ve
  yönlendirme TEK yerde (gateway). Yol haritası 8.4 kararı.
- **Güvenlik:** belge yüklemede boyut sınırı YOKTU (tek istekle depo/geçici disk
  doldurulabilirdi) → `DOCUMENT_MAX_UPLOAD_MB` (varsayılan 25), aşan istek 413.

### 2026-09-27 — MEVZUAT PARAMETRELERİ RLS ALTINDA (migration 029) (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **989/989**; yeni `TestSiteIstisnasiUygulamaRoluyleYalnizcaKendiSitesinde`
> uygulama rolüyle çalışır (süper kullanıcı RLS'e tabi olmadığı için ayrı bağlantı).

- `legal_parameters` RLS dışındaydı: uygulama rolü her sitenin yönetim planı istisnasını
  okuyabiliyordu. `pkg/legalparams` kapsamsız havuz kullandığı için RLS doğrudan açılsaydı
  site istisnaları SESSİZCE yok sayılırdı → çözümleyici artık `dbscope` ile sorgular, 029
  tabloyu korur (sistem geneli satırlar her sitede okunur, istisna yalnızca kendi sitesinde).
- RLS 81 → **82** tablo; RLS dışı gerekçeli tablo 9 → **8**.

### 2026-09-27 — İLAN PANOSU BİLDİRİMLERİ + DENETÇİ YETKİ AÇIĞI (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **987/987** (5 yeni kontrol, §ilan panosu).

- Yeni ilan onay yetkililerine (MANAGER, BOARD_MEMBER — `notify.Approvers`), onay/ret
  kararı ilan sahibine bildirim üretir; ret gerekçesi bildirim gövdesinde. Önceden
  yanıt "BİLDİRİM GÖNDERİLMEDİ" diyordu.
- **Güvenlik:** denetçi (AUDITOR) başkasının ilanını kapatıp yorum gizleyebiliyordu
  (`isManagement` denetçiyi de sayıyordu) → yazma işlemleri `canModerate` ile yalnızca yönetim.
- Eskimiş sunucu notları düzeltildi: sözleşme/ilan `expire-due` "zamanlanmış görev
  altyapısı yoktur" diyordu (zamanlayıcı var; süre dolumu BİLEREK elle işlenir),
  sözleşme oluşturma "dosya depolama yoktur" diyordu (belge arşivine yönlendirir).

### 2026-09-27 — YÖNETİCİ MOBİL UYGULAMASI GERÇEK API'YE BAĞLANDI (DOĞRULANMIŞ)

> **Kanıt:** `verify-mobile.sh` → 8/8 (yönetici: 21 test, 19'u yeni — `admin_app/test/logic_test.dart`).
> Not: yarım hâli kullanıcı commit'i `1c22c88` içinde derlenmez durumdaydı; bu girdi onu tamamlar.

İstemcideki ~20 alan yöntemi var olmayan yollara gidiyordu; hepsi silindi, ekranlar
yolu sözleşmeden (`tasks/api-sozlesmesi.md`) verir (`getList/getMap/post…`).
Ortak yükleme/hata/boş/işlem davranışı `core/widgets/api_views.dart`'ta tek yerde.
- **Oturum:** sunucu çıkışı, etkinleştirme ekranı, şifre değiştirme, oturum koruması;
  sakin eklenince tek kullanımlık **etkinleştirme kodu** gösterilir (yoksa sakin hiç giremiyordu).
- **Menü:** tüm modüller site rolüne göre süzülür; gerçek site adı.
- **Ödemeler:** havale/nakit ödemenin **yönetim onayı** mobilde hiç yoktu → "Onay bekleyen"
  sekmesi (onay `{reference}` borcu düşürür, ret borcu değiştirmez).
- **Tahakkuk / gider:** vade ve gider tarihi ISO damga gidiyordu → **her istek 400**'dü;
  faturasız giderde alan adı yanlıştı (`non_invoiced_reason`) → **her faturasız gider 422**'ydi.
  Gider detayında sunucuda olmayan düzenle/sil yerine sunucudaki **onay/ret** akışı;
  daire sayısı paylaştırma satırlarından.
- **Sözleşme:** alanlar tahmin ediliyordu → `party_name`/`contract_type`; yenileme ve
  gerekçeli fesih; ihbar süresi uyarısı.
- **Tahsilat riski / enerji:** "YZ tahmini" bekleyen ekranlar gerçek, gerekçeli
  hesaplara bağlandı (`/collection/risk`, `/energy/trends|anomalies`); önceki dönem 0 iken yüzde uydurulmaz.
- **İlan panosu:** yönetim ilan verip siliyordu (sunucuda yok) → onay/ret(gerekçe)/kapatma ve yorum gizleme.
- **Anket:** taslak → yayın → bitir/iptal; genel kurul türü sunulmaz (KMK m.29-32).
- **Dashboard:** bekleyen ödeme yeşil tikle "tamamlandı" gibi görünüyordu; tarih hep "—"ydi (sıfır zaman damgası).
- Diğer: ziyaretçi, personel, kargo, rezervasyon, talep, devriye, otopark, sayaç, stok,
  finans, duyuru (sabitleme ucu, geçerli kategoriler), yönetişim (yeni, salt okuma);
  banka/rapor/API ayarları/toplantı sihirbazı dürüst 501 ekranı.

### 2026-09-27 — SAKİN MOBİL UYGULAMASI GERÇEK API'YE BAĞLANDI (DOĞRULANMIŞ)

> **Kanıt:** `verify-mobile.sh` → 8/8 (sakin: 17 test, 15'i yeni); `verify-stack.sh` → **982/982**.

Sapma analizi 25 çağrının 16'sında yanlış yol/alan buldu. Düzeltilenler:
- **Oturum:** çıkış sunucuda da oturumu kapatır (yenileme jetonu iptal); iptal
  edilemezse kullanıcıya söylenir. Yönlendirme koruması (oturumsuz → giriş).
  Telefon `+90…` biçimine getirilir. **Etkinleştirme / şifre sıfırlama** ekranı
  ve **şifre değiştirme** eklendi (önceden düğmeler boştu).
- **Talepler:** liste koda gömülüydü (uydurma TLP-2025-0089), "Yeni Talep"
  hiçbir istek atmadan kapanıyordu → gerçek liste ve oluşturma.
- **Rezervasyon:** "09:00" gönderildiği için HER istek 400'dü ve saatler sabitti →
  doluluk `/facilities/:id/slots`'tan, zaman RFC3339 (site saati); sonuç sunucu
  durumuyla (PENDING'e "onaylandı" denmez); **Rezervasyonlarım** + iptal.
- **Anket:** ilk ankette çöküyordu (tanımsız bölme), oy yanlış yola gidiyordu →
  liste/detay/oy gerçek uçlarla; KMK notu gösterilir.
- **Kargo:** durum eşlemesi yanlış olduğu için HER paket gizliydi; uydurma
  '12:00/Bugün/Yakında' değerleri kaldırıldı.
- **Duyuru:** tarih/kategori doğru alanlardan, okundu bilgisi sunucuya gider.
- **İlan panosu:** zorunlu `content` ve sayısal fiyat gönderilir; "yayınlandı"
  yerine "onaya düştü"; kendi ilanını kapatma.
- **Ziyaretçi:** daire (`unit_id`) gönderilir (yoksa girişte bildirim gitmiyordu).
- **Ödeme:** yöntem kodları sunucununkiler; kısmi ödemede kalan gösterilir.
  Arka uç artık bilinmeyen yöntemi 422 ile reddeder.
- **Yeni:** bildirim gelen kutusu, bildirim tercihleri (6563 m.6 onayı ayrı),
  belgeler listesi (görünürlüğe göre). Sakine kapalı demirbaş menüsü kaldırıldı.
- **Bilinçli sınır:** mobilde belge dosyası açılamıyor (görüntüleyici eklentisi
  yok) — ekranda açıkça yazıyor.

### 2026-09-26 — YAPILANDIRILMIŞ GÜNLÜK, İSTEK KİMLİĞİ, AKTİF SİTE (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **981 kontrol, 0 başarısız**.

- **Denetimden kaçma açığı:** istemcinin `X-Request-Id`'si doğrulanmadan
  `audit_logs.request_id VARCHAR(64)`'e yazılıyordu; uzun değer INSERT'i düşürüp
  kaydı YOK ediyordu. Gateway ve servisler kimliği doğrular, gerekirse yeniler;
  `pkg/audit` geçersiz `entity_id`/uzun kimlik yüzünden kaydı düşürmez.
- FAZ 3.5: 26 servis `middleware.NewRouter` ile JSON günlük yazar (request_id,
  rota şablonu, durum, süre, kullanıcı, site). Ham yol ve sorgu dizesi yazılmaz
  (arama terimi telefon taşıyabilir — KVKK m.12). Gateway de JSON yazar.
- **Hata:** aktif sitesi boş hesap (yönetimin eklediği sakin) giriş yapınca jeton
  site taşımıyor, her istek 403 dönüyordu. Giriş ve yenilemede bağlı olunan ilk
  site seçilir; siteden ayrılanın eski sitesi jetonda kalmaz.
- **Hata:** sitede oturmayan yönetici (yalnız `property_roles`) sitesini listede
  görmüyor ve seçemiyordu; site listesi ve seçim artık yönetim rollerini de kapsar.
- Sıkılaştırılan kontrol, SUPER_ADMIN sınamasının önceki "geçti"sinin boşuna
  olduğunu gösterdi (istek 403 alıyordu); artık HTTP 200 de şart.

### 2026-09-26 — SUPER_ADMIN SİTE VERİSİNE YETKİ VERMİYOR (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **977 kontrol, 0 başarısız**.

- **Yetki yükseltmesi:** 13 servisteki el yazımı rol kontrolleri SUPER_ADMIN'i
  yönetim sayıyordu (RequireRole saymıyordu). Sitede yalnızca sakin olan platform
  yöneticisi komşuların ziyaretçi/talep/rezervasyon kayıtlarını görebiliyordu.
  Platform rolü artık hiçbir site kontrolünde yok; panelde de yönetim sayılmıyor.
- meeting_wizard 501 yanıtı var olmayan governance yollarını gösteriyordu; düzeltildi.

### 2026-09-26 — YENİLEME JETONU TEK KULLANIMLIK + TEKRAR KULLANIM TESPİTİ (DOĞRULANMIŞ)

> **Kanıt:** `verify-stack.sh` → **976 kontrol, 0 başarısız** (§30'a 6 kontrol); `verify-mobile.sh` → 8/8.

- **Açık:** yenileme jetonu 7 gün boyunca sınırsız kullanılabiliyordu; çalınan
  jeton fark edilmeden 7 gün erişim üretebilirdi.
- Her yenilemede jeton tükenir (`revoked_tokens`, ROTATED). 30 sn içindeki ikinci
  kullanım eşzamanlı istek sayılır; sonrası çalınma işaretidir → kullanıcının
  BÜTÜN oturumları kapanır (`REFRESH_REUSE`), yanıt nedenini söyler.
- **Hata (yönetici mobil):** yenilemede yeni yenileme jetonu atılıyordu; yenileme
  sonrası 401'de döngü koruması yoktu. İki mobil uygulamada eşzamanlı 401'ler tek
  yenileme isteğini paylaşır; reddedilen oturum cihazdan silinir.

### 2026-09-26 — GENEL KURUL KARARI → KARAR DEFTERİ (FAZ 6.6, DOĞRULANMIŞ)

> **Kanıt:** `bash backend/scripts/verify-stack.sh` → **970 kontrol, 0 başarısız**.

- Gündem maddesi sonuçlanınca karar aynı transaction'da toplantı yılının karar
  defterine yazılır (KMK m.32): başlık, karar metni, oy dağılımı, nisap gerekçesi.
  Reddedilen karar da yazılır. Defter notere kapatılmışsa karar yazılmaz → 409,
  madde PENDING kalır. Tarih Türkiye saatiyle. Yanıt `book_entry` ve `note` taşır.

### 2026-09-26 — ZAMANLANMIŞ BİLDİRİMLER (DOĞRULANMIŞ)

> **Kanıt:** `bash backend/scripts/verify-stack.sh` → **965 kontrol, 0 başarısız** (yeni adım 40: 15 kontrol).

- **Eksik:** gecikmiş aidat, sözleşme ihbar süresi ve açık kalan devriye için
  kimse bildirim üretmiyordu (zamana bağlı, olay yok).
- `cmd/scheduler`: her aktif siteyi kendi kapsamıyla tarar (migration 028:
  `scheduler_property_ids()` yalnızca kimlik döner). Aynı bildirim iki kez
  üretilmez (`dedupe_key`); çok kopyada advisory lock; `-once` ve `/health`.
- Gecikmiş aidat: daireye ayda en fazla bir hatırlatma, kısmi ödeme düşülmüş
  kalan (`money.Kurus.Display` → "1.334,56 TL"); taşınmış sakine gitmez.
- Sözleşme: ihbar son günü 14 gün içinde ya da geçmiş → yönetim (otomatik
  yenileme ayrımıyla); süresi dolduğu hâlde ACTIVE → yönetim.
- Devriye: süre + tolerans aşılmış açık tur → yönetim (saat Türkiye saatiyle);
  eksik ya da çok hızlı kapanan tur → yönetime anında olay bildirimi.
- Dağıtım: compose, k8s (tek kopya), CI imajı ve rollout `gen-deploy.py`'dan.

### 2026-09-26 — HESAP ETKİNLEŞTİRME, ŞİFRE DEĞİŞTİRME, GİRİŞ KİLİDİ (DOĞRULANMIŞ)

> **Kanıt:** `bash backend/scripts/verify-stack.sh` → **948 kontrol, 0 başarısız** (yeni adım 39: 25 kontrol).
> Panel: `tsc --noEmit`, `npm run lint`, `npm run build` temiz.

- **Hata:** panelden eklenen sakine rastgele geçici şifre atanıyor, şifre kimseye
  iletilmiyordu; şifre belirleme akışı yoktu → yönetimin eklediği hiçbir sakin
  giriş yapamıyordu. Telefon "0555…" olarak saklanıyor, giriş "+90555…" arıyordu.
- **Migration 027:** `user_activation_codes` (yalnızca kimlik rolü; kodun SHA-256
  özeti), `users.password_set_at/failed_login_attempts/locked_until`.
- Tek kullanımlık kod (8 karakter, karışan harfler yok, modulo sapmasız), 7 gün,
  5 hatalı denemede kilit, yenisi eskisini geçersiz kılar. `POST /auth/activate`,
  `POST /users/me/password`, `POST /residents/:id/activation-code`.
- Giriş kilidi: 5 hatada 15 dk; kilitliyken de bcrypt çalışır (zamanlama sızmaz).
- **Hata:** toplu iptal "şimdi+1 sn" yazıyordu ve jeton `iat` tam saniyeydi →
  şifre belirleyip hemen giriş yapanın jetonu ilk istekte 401. `iat` artık
  milisaniye (`pkg/revocation.Precision`), iptal anı kimlik servisinin saatinden.
- Panel: kod bir kez gösterilir (kopyala), satırda "kod üret", açık `/activate`
  sayfası, `/dashboard/account` şifre değiştirme; girişteki ölü "Şifremi unuttum"
  bağlantısı ve işlevsiz "Beni hatırla" kutusu kaldırıldı.

### 2026-09-26 — RLS TAMAMLANDI, EN AZ YETKİ, DAĞITIM TEK KAYNAKTAN (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **886 kontrol, 0 başarısız**.
> Ek kanıt: gerçek imajlarla `docker compose` duman testi — 26 migration, iki rol
> parolası atandı, giriş kimlik rolüyle 200, finance uygulama rolüyle 200,
> kaplar uid 10001 (root değil). Commit'ler: `72603f9`, `3543388`, `ada898a`.

#### RLS 30 → 81 tablo (migration 023-026)

- **023:** ödeme, gecikme tazminatı, tahakkuk detayı, tüketim faturası, gider,
  talep, duyuru (10 tablo). `payments`'a `property_id` eklendi: çok daireli
  ödemede `unit_id` boş kaldığından ödemenin sitesi bilinemiyordu.
- **024:** kalan altı servis (governance, settings, smart_collection, iot,
  energy_analytics, esg) kapsama geçirildi; çok servisli `monthly_assessments`,
  `expense_categories`, `meters`, `meter_readings` açılabildi (22 tablo).
- **025:** dizin tabloları (users, properties, units, blocks, resident_units,
  property_roles) + ayrı **kimlik rolü**.
- **026:** kullanılmayan 13 site tablosu korumalı doğar; platform tabloları
  uygulama rolüne kapalı.

**Geçiş sırasında bulunan ve kapatılan gerçek açıklar:**

| Yer | Açık | Etki |
|---|---|---|
| Talep | `GetByID/UpdateStatus/ConfirmResolution` site filtresiz | A sitesinin yöneticisi B'nin talebini ilerletebiliyordu |
| Ödeme | Tahakkuk seçimi aktif siteye göre süzülmüyordu | Başka sitenin tahakkuku ödemeye bağlanabiliyordu |
| Bütçe itirazı | Listeleme/sonuçlandırma site filtresiz | Başka site itirazı reddedip projenin kesinleşme engelini kaldırabiliyordu |
| Bütçe itirazı | Daire doğrulanmıyordu | Kiracı ya da başkasının (başka sitenin) dairesi adına itiraz — KMK m.37/2 hak malikindir |
| Karar defteri | Yazma/okuma/doğrulama site filtresiz | Başka sitenin KARAR DEFTERİNE kayıt yazılabiliyordu (KMK m.32) |
| Görünümler | Süper kullanıcının yetkisiyle çalışıyordu | `monthly_expense_summary` üzerinden tüm sitelerin gider özeti okunuyordu |
| Uygulama rolü | Dizin tablolarında tam yetki | Tüm sitelerin telefon/e-posta/**parola özeti** okunabilir; roller, arsa payları değiştirilebilir; jeton iptali ve denetim izi silinebilirdi |
| Geçersiz kimlik | Veritabanı tür hatası | 404 yerine 500 |

#### Dağıtım — `backend/scripts/gen-deploy.py`

Önceki durum: `docker-compose.yml`'de 26 servisin **18'inde veritabanı ve JWT
ayarı yoktu** (açılamazlardı), kalan 8'i **süper kullanıcıyla** bağlanıyordu —
RLS dağıtımda hiç devrede değildi. k8s 2 servis tanımlıyordu; ingress servisleri
gateway'i atlayarak ve yanlış önekle (`/v1` ↔ `/api/v1`) yayınlıyordu. CI 3 imaj
üretiyordu. Dockerfile'lar root çalışıyordu. Redis/Mongo/Kafka compose'da ayakta
ama koddan hiç kullanılmıyordu.

Artık tek bir servis listesinden: 27 Dockerfile (uid 10001, sağlık kontrolü),
compose (zorunlu gizli değer yoksa açılmaz, demo verisi varsayılan kapalı),
k8s (26 servis + gateway + panel + migrate işi, salt-okur kök dosya sistemi),
CI (29 imaj; önce migrate işi, sonra dağıtım). `--check` kipi doğrulamada sapmayı
yakalar. `cmd/migrate` rol parolalarını ortam değişkeninden atar.

### 2026-09-14 (üçüncü tur) — RLS İKİNCİ DİLİM + BİLDİRİM BAĞLANTISI (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **769 kontrol, 0 başarısız**

#### 2.6 devamı — Satır düzeyi güvenlik ikinci dilimi (migration 021)

RLS 7 tablodan **26 tabloya** çıkarıldı. Eklenenler yine yalnızca TEK servisin
kullandığı tablolar: otopark (3), ziyaretçi (1), stok (3), demirbaş (3),
devriye (3), ilan panosu (3), anket (3).

- Önce sekiz servisin deposu `pkg/dbscope` kullanımına geçirildi (86 sorgu),
  SONRA migration yazıldı. Ters sıra uygulamayı bozardı: RLS açıkken kapsamsız
  sorgu boş liste döner.
- **nps-service aynı dilimde geçirilmek ZORUNDAYDI:** ayrı tablo açmaz, anket
  tablolarını kullanır. Yalnızca survey geçirilseydi RLS açıldığı an NPS
  çalışmaz hâle gelirdi.
- `property_id` taşımayan altı alt tablo (movements, maintenance, comments,
  messages, options, votes) ebeveyn üzerinden `EXISTS` ile korunuyor. RLS bu
  alt sorguyu HER SATIR için çalıştırdığından ebeveyn anahtarlarına indeks
  eklendi — indekssiz kalsaydı koruma "yavaş olduğu için kapatılan" bir şeye
  dönerdi.

**Çalışırken bulunan iki gerçek sorun:**

1. `asset_categories` ve `inventory_categories`, `property_id IS NULL` olan
   ORTAK kategoriler taşıyor (005 tohum verisi: "Asansör", "Temizlik
   Malzemeleri"…) ve depo bunları bilerek okuyor. Katı politika bu satırları
   HER siteden gizliyordu — kimse hata almazdı, kategoriler sessizce
   kaybolurdu. OKUMA global satırlara açıldı, YAZMA katı bırakıldı: uygulama
   kendi başına global kategori üretemez (üretebilseydi tek hatalı istek o
   satırı platformdaki her siteye görünür kılardı).
2. Doğrulamanın "kapsamsız sorgu SIFIR satır döndürmeli" ölçüsü kategori
   tabloları için yanlıştı. Ölçü "hiç satır dönmesin" değil **"hiçbir SİTE
   VERİSİ dönmesin"** olarak düzeltildi; muafiyetin sessizce genişlememesi
   için ortak satır sayısı tohum verisine sabitlendi.

Kalan 63 tablo bilerek kapalı ve doğrulama bu sayıyı raporluyor.

#### Bildirim — altı modül gerçekten bildirim gönderiyor

Önceki durum: `pkg/notify` yazılmıştı ama **hiçbir modül onu çağırmıyordu**.
Modüller "BİLDİRİM GÖNDERİLMEDİ; altyapı bağlı değildir" notu düşüyordu; not
dürüsttü ama iş yarım kalmıştı.

| Modül | Olay | Alıcı |
|---|---|---|
| community | duyuru yayımlandı | sitenin aktif sakinleri |
| reservation | onay / red | YALNIZCA rezervasyonu yapan sakin |
| package | kargo kaydedildi | YALNIZCA ilgili dairenin sakinleri |
| survey | anket yayına alındı | sitenin aktif sakinleri |
| visitor | ziyaretçi giriş yaptı | ilgili dairenin sakinleri |
| inventory | stok asgarinin altına düştü | YALNIZCA yönetim rolleri |

- Yeni `pkg/notify/audience.go`: alıcı kümesi TEK yerde. Beş modül aynı sorguyu
  ayrı ayrı yazsaydı, birinde `is_active` filtresi unutulduğunda siteden
  taşınmış birine bildirim gider ve kimse fark etmezdi. İki daireli malik
  duyuruyu bir kez alır.
- `Broadcast` sayaçlarla döner ve sonuç API yanıtına konur. **"Gönderildi"
  sözcüğü yalnızca gerçekten gönderilen kayıt varsa geçer**; sağlayıcısız
  kanalda "kuyrukta bekliyor (GÖNDERİLMEDİ)" yazar.
- Kayıt/durum tutarlılığı: kargo `NOTIFIED`'a, ziyaretçi `resident_notified_at`
  alanına ancak bildirim GERÇEKTEN oluştuysa geçer. Aksi hâlde kayıt, kargo
  kaybolduğunda "sakinin haberi vardı" diyen yanıltıcı bir delile dönüşürdü.
- Kişisel veri sınırları: kargo bildirimi takip numarası/gönderici TAŞIMAZ
  (kilit ekranında görünür); rezervasyon kararı tüm siteye duyurulmaz; stok
  uyarısı sakinlere gitmez (6698 m.4 ölçülülük); ziyaretçiye SMS/QR
  GÖNDERİLMEZ (sağlayıcı yok + 6563 s. Kanun onay şartı).
- **Kanuni sınır:** anket bildirimi genel kurul ÇAĞRISI DEĞİLDİR (634 s. KMK
  m.29 çağrıyı taahhütlü mektup/imza karşılığına bağlar). Gövdeye uyarı
  eklenir ve konu `assembly.call` olarak İŞARETLENMEZ; doğrulama bunu sınar.

Doğrulamadaki eski "bildirim gönderilmedi diyor mu?" iddiaları, **"bildirim
GERÇEKTEN oluştu mu, DOĞRU kişiye mi?"** kontrolleriyle değiştirildi:
veritabanındaki kayıt sayısı, alıcı kümesi, gövde içeriği ve kayıt durumu
ayrı ayrı sınanıyor.

---

### 2026-09-14 (ikinci tur) — FAZ 2 GÜVENLİK TAMAMLANDI (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **714 kontrol, 0 başarısız**
> Dev ortamı: 24 servis + gateway + panel ayakta, hepsi `/health` → 200.

#### 2.7 — Çıkış artık gerçekten çıkış

Önceki durum: "Çıkış yap" yalnızca `{"message":"Çıkış başarılı"}` yazıyor ve
HİÇBİR ŞEY yapmıyordu. Jeton süresi dolana kadar geçerliydi: erişim jetonu
15 dakika, **yenileme jetonu 7 GÜN**. Ortak bilgisayardan çıkan sakinin oturumu
fiilen kapanmıyordu.

- migration 018: `revoked_tokens` (jti reddetme listesi) + `user_token_invalidation`
- `POST /auth/logout` erişim VE yenileme jetonunu iptal eder; yenileme jetonu
  gönderilmediyse yanıt bunu UYARI olarak söyler
- `POST /users/me/logout-all` — tüm cihazlardan çıkış (geçmişe dönük)
- Yenileme akışında iptal denetimi: olmasaydı çıkış hiçbir işe yaramazdı
- `AuthMiddleware()` → `AuthMiddleware(pool)`: imza değişikliği bilinçli, eksik
  kalan her çağrı yerini DERLEME HATASI yapar (26 çağrı yeri güncellendi)

#### 2.8 — TCKN ve IBAN şifreli

Önceki durum: düz metin. `pkg/encryption` yazılmış ama import edilmiyordu.

- `pkg/pii`: AES-256-GCM; aynı değer her seferinde farklı şifreli metin üretir
- Arama anahtarı **HMAC-SHA256**, düz SHA-256 değil: TCKN'nin değer uzayı
  ~10^10'dur ve anahtarsız özet kaba kuvvetle geri çevrilebilir. Doğrulamada
  anahtarın düz SHA-256 ile eşleşmediği ayrıca sınanıyor.
- TCKN algoritmik sağlama ve IBAN mod-97 doğrulaması: şifreli alandaki yazım
  hatası sonradan gözle bulunamaz
- Aynı TCKN ile ikinci aktif personel açılamaz (kısmi tekil indeks)
- `cmd/encrypt-pii`: mevcut düz metni şifreler ve düz metin kolonu NULL'lar
- Varsayılan MASKELİ; maskesiz erişim `?reveal=true` ister ve ayrı `PII_REVEAL`
  denetim kaydı üretir. Kayıt tutulamıyorsa veri AÇILMAZ.

#### 2.6 — Satır düzeyi güvenlik (birinci dilim)

**Çalışırken bulunan kritik nokta:** PostgreSQL'de RLS SÜPER KULLANICIYI
BAĞLAMAZ — `FORCE ROW LEVEL SECURITY` bile. Uygulama süper kullanıcıyla
bağlandığı sürece politikalar tanımlıdır ama hiç devreye girmez. İlk denemede
tam olarak bu görüldü: politikalar açıkken kapsamsız sorgu satır döndürdü.

- migration 020, yetkisi sınırlı `siteeksen_app` rolünü oluşturur; servisler
  artık onunla bağlanır. Rolün DDL yetkisi yoktur. Parola migration'a yazılmaz.
- `pkg/dbscope`: her isteği `SET LOCAL app.property_id` ayarlanmış transaction
  içinde çalıştırır. Oturum düzeyinde ayarlamak BİLEREK yapılmadı: havuzdan
  alınan bağlantı geri döndüğünde değişken başka sitenin isteğine sızardı.
- RLS 7 tabloda açık (personel, belge, bildirim) — hepsi TEK servis tarafından
  kullanılan tablolar. 82 tablo bilerek kapalı; doğrulama bunu sayarak raporluyor.
- Doğrulanan: kapsamsız sorgu SIFIR satır; çapraz site erişimi kapalı;
  `WHERE property_id` olmadan yazılmış sorgu bile sızdırmıyor; kapsam dışına
  yazma engelli (WITH CHECK); geçersiz kapsamda hiçbir satır yok.

---

### 2026-09-14 — FAZ 5 TAMAMLANDI: 22 mock servisin tamamı ele alındı (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **646 kontrol, 0 başarısız**
> Gerçek veri katmanına bağlı servis: **4 → 20**. Bilerek yazılmayan: **2** (gerekçeli).
> Dev ortamı: 24 servis + gateway + panel ayakta (hepsi `/health` → 200).

#### Bu turda gerçeğe çevrilen modüller (9-22)

| # | Modül | Önceki davranış | En kritik eklenen kural | Adım |
|---|---|---|---|---|
| 9 | demirbaş | sabit liste | amortisman **saklanmaz, hesaplanır**; kayıttan düşme karar dayanağı ister (KMK m.45) | §20 |
| 10 | stok | hareket kaydedilmiyordu | satır kilidiyle eşzamanlılık; negatif stok yasak; sayım düzeltmesi gerekçe ister | §21 |
| 11 | anket | sabit sonuç (%68 evet) | **genel kurul kararı üretilemez** (KMK m.29-32); oy hakkı bağımsız bölüm başına (m.31/1); ağırlık arsa payı (m.20) | §22 |
| 12 | sayaç/IoT | sabit endeks | ısı gideri %70 tüketim + %30 alan (RG 14.04.2008); oranlar `legal_parameters`'tan; endeks zinciri sunucuda | §23 |
| 13 | bildirim | "gönderildi" yalanı | giden kutusu; sağlayıcı yoksa PENDING kalır; ticari ileti onaysız gönderilmez (6563 m.6) | §24 |
| 14 | devriye | hiç gezilmemiş tur "tamamlandı" | zaman sunucudan; durum okutmalardan **hesaplanır**; çok hızlı tur işaretlenir | §25 |
| 15 | duyuru + ilan | uydurma veri | ilan yönetim onayından geçer; okundu kaydı; yorum silinmez gizlenir | §26 |
| 16 | ayarlar | sabit ayar | **mevzuat parametreleri ezilemez** — uygulama + veritabanı kısıtı | §27 |
| 17 | enerji analizi | uydurma "AI" tahmini | medyandan sapma, alan başına karşılaştırma; tahmin üretilmez | §28 |
| 18 | akıllı tahsilat | uydurma risk skoru | ağırlıkları yazılı, gerekçeli skor; icra **önerilir**, yapılmaz (KMK m.22) | §28 |
| 19 | NPS | sabit "NPS: 42" | sabit tanım (0-6/7-8/9-10); yanıt yoksa skor yok; anonim | §29 |
| 20 | ESG | sabit karbon ayak izi | **emisyon katsayısı koda gömülmez**, kullanıcı kaynağıyla verir | §29 |
| 21 | banka | uydurma bakiye | **yazılmadı** — S-07 kullanıcı kararı; 501 + engel listesi | §29 |
| 22 | toplantı sihirbazı | uydurma transkript/özet | **yazılmadı** — governance ile tekrar olurdu; oraya yönlendirir | §29 |

#### Yeni altyapı

- **`pkg/storage` (S-09)** — dosya saklama. `local` + `s3` (SigV4, harici
  bağımlılık yok; Oracle / Cloudflare R2 / AWS). Yapılandırma yoksa açılmaz.
- **`pkg/notify` (S-10)** — sağlayıcıdan bağımsız giden kutusu. Sağlayıcı yoksa
  bildirim PENDING kalır ve hiçbir yerde "gönderildi" denmez.
- **migration 015** belge arşivi + erişim kaydı, **016** bildirim + tercihler,
  **017** site ayarları + değişiklik geçmişi. Üçünde de salt-ekleme tetikleyicileri.

#### "Yapay zekâ" iddiası kaldırıldı

Enerji analizi, tahsilat riski ve karbon ayak izi **gerçek hesap** yapar ama
YZ kullanmaz. `ai_model_version`, `predictions`, `predicted_payment_probability`
alanları bilerek boş bırakılır ve doğrulamada boş kaldıkları ayrıca sınanır.
Gerekçe: bir model olmadan sürüm numarası yazmak ve "ödeme olasılığı %62" demek,
olmayan bir yeteneği var göstermektir. Bunun yerine formülü kodda yazılı,
her sonucu gerekçeli istatistikler üretilir.

#### Düzeltilen hatalar

- **`verify-stack.sh` eşzamanlılık testi betiği kilitliyordu.** Çıplak `wait`,
  kabuğun tüm arka plan çocuklarını — yani doğrulama boyunca ayakta tutulan
  servisleri — bekliyordu. Artık yalnızca ilgili işler bekleniyor.
- **Hareket zinciri kontrolü yanlış alarm veriyordu.** Eşzamanlı kayıtlar aynı
  zaman damgasına düştüğünde gerçek sıra kurulamıyordu. Yerine kayıp
  güncellemeyi doğrudan ölçen kontrol kondu.
- **Isı paylaştırmasında kullanım alanı zorunluluğu** yanlışlıkla su/elektriği
  de kapsıyordu; alan yalnızca ısıtmada gerekir.
- **Stub dürüstlük testi kimliksiz çağırıyordu.** Stub uçları da kimlik
  doğrulaması arkasında olmalı: kimliksiz 401, kimlikli 501. 501'i kimliksiz
  servis etmek, olmayan bir modülün varlığını dışarıya doğrulamak olurdu.

---

### 2026-09-13 (ikinci tur) — FAZ 5: Sekiz modül mock'tan gerçeğe + dosya depolama (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **283 kontrol, 0 başarısız**
> (art arda iki tur aynı sonuç — kararlılık ayrıca doğrulandı).
> Gerçek veri katmanına bağlı servis sayısı **4 → 12**. Kalan mock servis: **14**.

#### Gerçeğe çevrilen modüller

| # | Modül | Önceki davranış | Eklenen gerçek davranış | Kanıt |
|---|---|---|---|---|
| 1 | gider (expense) | sabit JSON | kalem bazlı dağıtım, faturasız gider onayı | §12 |
| 2 | personel | sabit JSON | TCKN/IBAN maskeleme, izin bakiyesi, çakışma reddi | §13 |
| 3 | ziyaretçi | sabit JSON | sakin yalnızca kendi ziyaretçisini görür | §14 |
| 4 | otopark | sabit JSON | plaka normalleştirme, kapasite, ücret (kuruş) | §15 |
| 5 | rezervasyon | sabit JSON | **çakışma denetimi**, tampon süre, kota, saat kuralları | §16 |
| 6 | kargo (package) | "bildirim gönderildi" yalanı | teslim/iade kaydı, KVKK bölüm bazlı görünürlük | §17 |
| 7 | sözleşme | sabit JSON | ihbar penceresi, elle yenileme, mali yük özeti | §18 |
| 8 | belge arşivi | "yüklendi" deyip yazmıyordu | gerçek dosya saklama, sürümleme, erişim kaydı | §19 |

#### Rezervasyon — çakışma denetimi *(FAZ 5.5)*

Mock sürümde çakışma denetimi **hiç yoktu**: iki sakin aynı saati "ayırttığını"
sanabiliyordu. Artık tesis satırı `FOR UPDATE` ile kilitlenip `tstzrange` kesişimi
ve `buffer_minutes` tamponu **aynı transaction içinde** denetleniyor (yarış durumu yok).
Ayrıca min/max süre, çalışma saatleri ve açık günler (Europe/Istanbul yerel saatiyle),
`advance_booking_days` ve bağımsız bölüm başına haftalık kota sunucuda uygulanıyor.
**Kanıt:** `verify-stack.sh` §16 — çakışan istek 409, tampon içi istek 409, tampon
dışı istek 201, iptal sonrası saat yeniden alınabiliyor.

#### Kargo — KVKK veri minimizasyonu *(FAZ 5.6)*

Sakin artık **komşusunun kargosunu göremiyor** (liste ve tekil okuma ayrı ayrı
sınırlandı). Teslimde `delivered_to_name` zorunlu — kaybolan kargoda sorumluluk
belirli. `notify` ucu bildirim **göndermez**, görevlinin elle haber verdiğini kayda
geçirir ve bunu yanıtta açıkça söyler. **Kanıt:** §17.

#### Sözleşme — ihbar penceresi *(FAZ 5.7)*

Kendiliğinden yenilenen bir sözleşmede ihbar süresi kaçırılırsa site habersiz yeni
bir mali yüke bağlanır. Artık `notice_due` hesaplanıyor; **sistem kendiliğinden
yenileme yapmıyor**, yenileme elle onaylanıyor ve bitiş tarihi "bugünden" değil
**mevcut bitişten** itibaren uzatılıyor. `auto_renew` var ama `renewal_period_months`
yoksa kayıt reddediliyor (422). **Kanıt:** §18.

#### Dosya depolama — `pkg/storage` *(S-09)*

Projede dosya saklama **hiç yoktu**. Eklendi:
- `Store` arayüzü (Put/Get/Stat/Delete) + `local` ve `s3` adaptörleri
- S3 imzalama (AWS SigV4) **harici bağımlılık olmadan**, yalnızca stdlib ile.
  Aynı kod Oracle Object Storage, Cloudflare R2 ve AWS S3'te çalışır.
- Yapılandırma eksikse `ErrNotConfigured` — sessizce varsayılana düşülmez
- Her yükleme SHA-256 özeti döner (belge bütünlüğü kanıtı)
- `ValidateKey`: dizin dışına çıkma (`..`, mutlak yol) engellenir
- `Describe()` erişim anahtarını asla yazmaz

**Kanıt:** `go test ./pkg/storage/...` → 8 test geçti (SigV4 imzası `httptest` ile
doğrulandı); `verify-stack.sh` §19 — yüklenen dosyanın **diskte gerçekten** olduğu,
diskteki SHA-256'nın yüklenenle aynı olduğu ve indirilenin bozulmadığı sınandı.

#### Belge arşivi — migration 015 *(FAZ 5.8)*

- `documents`: kategori, görünürlük kademesi, sürümleme, SHA-256, saklama süresi
- `document_access_logs`: KVKK m.12 erişim kaydı, **salt-ekleme** (tetikleyici korumalı)
- Görünürlük SORGUDA uygulanıyor (fail-closed):
  `RESIDENTS` ⊂ `OWNERS` (KMK m.36 inceleme hakkı) ⊂ `MANAGEMENT`
- Görünürlük belirtilmezse **en dar** kademe uygulanır
- Yetkisiz tekil okuma **404** döner → belgenin varlığı sızdırılmaz
- Erişim kaydı yazılamıyorsa belge **verilmez**
- Üst veri yazılamazsa depodaki dosya geri alınır (öksüz dosya bırakılmaz)

#### Düzeltilen hatalar

- **Panelde sonsuz yönlendirme döngüsü (ERR_TOO_MANY_REDIRECTS).** İki neden:
  (1) identity giriş yanıtında `roles`/`active_property_id` alanları yoktu; panel
  oturumda rol bulamayıp **giriş yapan herkesi** yetkisiz sayıyordu.
  (2) `/dashboard` ön eki `/dashboard/forbidden` sayfasını da kapsıyordu → sayfa
  kendine yönleniyordu. Roller artık hem jetona hem yanıta aynı kümeden yazılıyor;
  forbidden sayfası RBAC'tan muaf ve `safeRedirect()` genel döngü koruması eklendi.
  **Gerileme koruması:** `verify-stack.sh` §9'a 4 kontrol eklendi.
- **`verify-stack.sh` kararsızdı (flaky).** `go run X &` iki süreç yaratıyor; betik
  yalnızca sarmalayıcıyı öldürüyor, derlenmiş ikili portu tutmaya devam ediyordu.
  Bir sonraki çalıştırmanın sağlık kontrolü **eski sürece** cevap veriyor ve testler
  eski veritabanına karşı koşuyordu → aynı kodda bir tur 279/279, bir tur 257/279.
  Artık süreç **ağacı** öldürülüyor (`kill_tree`) ve başlangıçta portlar süpürülüyor
  (`free_port`). Kararsız bir doğrulama betiğinin kanıt değeri yoktur.
- **`reservation` servisinin varsayılan portu** `kong/kong.yml` ile hizalandı (8101).
- **`dev-up.sh`** yalnızca 4 servisi kaldırıyordu; gerçeğe çevrilen 8 modül ayakta
  olmadığı için gateway bunlara 502 dönüyordu. Artık 12 servis + gateway kalkıyor.

---

### 2026-09-13 — FAZ 0/1/2/4/6: Dürüstlük tamamlandı, güvenlik ve yönetişim katmanı (DOĞRULANMIŞ)

> **Toplu kanıt:**
> `bash backend/scripts/verify-stack.sh` → **102 kontrol, 0 başarısız**
> `bash backend/scripts/verify-mobile.sh` → **8 kontrol, 0 başarısız**
> `cd admin && npx tsc --noEmit && npm run lint && npm run build` → hepsi temiz
>
> `tasks/questions.md`'deki 18 sorunun tamamı kullanıcı tarafından yanıtlandı ve
> yanıtlar bu turda uygulandı.

#### Dürüstlük (FAZ 0) — tamamlandı

- **22 mock servisin TÜM uçları `501 Not Implemented` döndürüyor** *(0.B.1)*
  Yalnızca yazma değil, okuma uçları da uydurma veri döndürüyordu. Ortak sözleşme
  `pkg/stub`: gövdede modül adı + "istek İŞLENMEDİ" uyarısı,
  `X-SiteEksen-Not-Implemented: true` başlığı. Sağlık ucu artık `"healthy"` değil
  `"not_implemented"` diyor.
  **Kanıt:** çalışan servise `GET`/`POST /api/v1/vehicles` → 501; kaynaklarda uydurma
  isim taraması → 0 satır.
- **Community'nin 4 auth'suz modülü kapatıldı** *(0.B.4)* — duyuru/anket/ilan/rezervasyon
  uçları **token'sız** POST/DELETE kabul ediyordu (herkes duyuru silebilirdi).
  `AuthMiddleware` arkasına alındı ve 501'e çevrildi.
- **Gateway'deki uydurma mali rapor üretimi kaldırıldı** *(2.2)* — `/reports/generate`
  içi tamamen sabit (uydurma daire, sakin adı, tutar) **indirilebilir PDF/Excel**
  üretiyordu. **Kanıt:** `POST /api/v1/reports/generate` → 501.
- **Dashboard özetindeki uydurma sabitler kaldırıldı** *(2.3)* — kaynaklara ulaşılamazsa
  `156 sakin / 245.000 TL / %94` sabitleri dönüyordu. Artık ulaşılamayan alan hiç
  dönmez, `unavailable[]` ile nedeni bildirilir.
- **Mobil (sakin) uygulamasında sahte ödeme akışı kaldırıldı** *(0.C.1)* — borç koda
  gömülüydü (₺1.250) ve "Öde → Onayla" **hiçbir ağ çağrısı yapmadan** "Ödeme Başarılı!"
  diyordu. Artık gerçek API; `payment_gateway_ready:false` iken tahsilatın
  YAPILMADIĞI açıkça söyleniyor.
- **Mobil: çalışmayan "Çıkış Yap" düzeltildi** — onay diyaloğu gösterip
  `// TODO: Logout işlemi` diyerek hiçbir şey yapmıyordu; ortak cihazda doğrudan
  güvenlik sorunu. Artık jetonlar gerçekten siliniyor.
- **Yönetici mobil uygulamasındaki 20 mock ekran gerçek API'ye bağlandı** — sözleşme,
  ilan panosu, enerji, anket, akıllı tahsilat, genel kurul, devriye, demirbaş, stok,
  API anahtarları, raporlar, kargo, rezervasyon, dashboard, talepler, duyurular,
  sayaçlar, finans ve gider ekranları.
- **`api_settings` ekranındaki yanlış güvenlik güvencesi kaldırıldı** *(0.C.5)* —
  "bilgiler şifrelenmiş saklanır, her değişiklik kayıt altındadır" deniyordu; ekranın
  tamamı mock'tu ve `pkg/encryption` hiçbir yerden import edilmiyor.
- **Admin panelde kalan uydurma veriler temizlendi** — ana sayfa (sabit istatistikler,
  12 aylık uydurma grafik, var olmayan kişilere ait "son ödemeler"), talepler (yalnızca
  yerel state'i değiştiren durum güncellemesi), sayaçlar (sunucuya hiç istek göndermeyen
  "Okumaları Kaydet"), ayarlar (sahte yöneticiler, iyzico/Firebase/SMTP için yanlış
  "Bağlı" rozetleri, uydurma "Pro Plan ₺299/ay" ve 3 ödenmiş fatura).
- **Hukuki metinler gerçeğe uyarlandı** *(0.D)* — KVKK güvenlik bölümü yeniden yazıldı
  (uygulanan/uygulanmayan ayrımı), zorunlu "toplama yöntemi ve hukuki sebep" bölümü
  eklendi, üç metne "TASLAK — yayına hazır değil" uyarısı kondu.

#### Kurulabilirlik ve altyapı (FAZ 1) — tamamlandı

- **Migration çalıştırıcı** *(1.5)* — `backend/cmd/migrate`: `schema_migrations` sürüm
  tablosu, PostgreSQL **advisory lock**, **SHA-256 sağlama denetimi** (uygulanmış bir
  migration sonradan değiştirilmişse durur), migration başına transaction,
  `-status` / `-dry-run`. Docker imajı ve compose servisi eklendi.
  **Kanıt:** sağlama bozulduğunda çalıştırıcı hata verip çıkış kodu 1 döndürdü.
- **Tüm migration'lar idempotent** *(1.4)* — 001/003/005'te 140+ ifadeye
  `IF NOT EXISTS`, 004'teki trigger'a `DROP TRIGGER IF EXISTS`, 002'ye tam koruma.
  **Kanıt:** 14 migration dosyasının tamamı temiz kurulumdan sonra yeniden uygulandı, hata yok.
- **`003`'ün `DROP TABLE audit_logs` komutu kaldırıldı** *(1.13)* — migration her
  tekrarlandığında **KVKK denetim izinin tamamı siliniyordu**.
  **Kanıt:** tabloya kayıt atılıp 003 yeniden uygulandı; kayıt yerinde.
- **Seed verisi tutarlı** *(1.8)* — `total_units=24` deniyor ama 6 birim vardı; arsa payı
  toplamı 10000 yerine 2480'di. Bu, **arsa payına göre dağıtımı test edilemez** kılıyordu.
  Artık 24 bağımsız bölüm ve arsa payı toplamı tam **10000**.
- **Seed `initdb` dışına taşındı** *(1.7b)* — `SEED_DEMO_DATA=false` ile üretimde bilinen
  şifreli demo hesaplar açılmıyor.
- **13 servisin varsayılan portu** kanonik tabloya eşitlendi; 4 çakışma giderildi *(1.10)*.
- **`firebase-credentials.json` bind mount'u kaldırıldı** *(1.11)* — dosya yok; Docker
  eksik yolu dizin olarak yaratıp `docker-compose up`'ı kırıyordu.
- **CI gerçek kapı** *(1.12)* — Go 1.21 → **1.24**; `go build/vet/gofmt/test -race`;
  admin'de `|| true` kaldırıldı; Trivy `exit-code: 1` + **sır taraması**; mobil matris;
  `verify-stack` işi. `.eslintrc.json` eklendi (yoktu, `npm run lint` CI'da takılıyordu).

#### Güvenlik (FAZ 2)

- **Gateway'e kimlik doğrulaması eklendi** *(2.1)* — 25 servise yönlendiren gateway
  **hiçbir jeton doğrulaması yapmıyordu**; maaş, TCKN, IBAN ve **API anahtarları**
  token'sız erişilebiliyordu. `pkg/authtoken` (tek kaynak) + fail-closed `JWT_SECRET`.
  İstemciden gelen `X-User-*`/`X-Property-Id`/`X-Tenant-Id` başlıkları **siliniyor**.
  CORS joker `*` yerine allowlist. Her isteğe `X-Request-Id`.
  **Kanıt:** token'sız → 401, geçersiz jeton → 401, `/auth/login` açık, geçerli jeton → 200.
- **Kong'a jwt eklentisi** — 25 rotada; consumer anahtarı Kong env vault'tan; joker CORS
  kökenleri kaldırıldı. Jetonlara `iss: "siteeksen"` claim'i eklendi.
- **Aktif site seçiminde sahiplik doğrulaması** *(2.4)* — `POST /users/me/active-property`
  gelen `property_id`'yi hiç doğrulamıyordu; herhangi bir kullanıcı tek istekle
  **başka bir sitenin verisine geçebiliyordu**. Artık `resident_units` bağı aranıyor.
  **Kanıt:** yabancı siteye geçiş → 403, kendi sitesine → 200.
- **Roller site bazlı** *(2.5)* — `users.roles` global olduğu için bir sitede MANAGER olan
  kişi **tüm sitelerde** yöneticiydi. `migrations/013` ile `property_roles` tablosu
  (atama izi, geçerlilik dönemi, karar referansı — KMK m.34). Jeton rolleri aktif siteye
  göre üç kaynaktan birleştiriliyor.
  **Kanıt:** kiracı jetonunda MANAGER yok, TENANT var; yönetici jetonunda MANAGER var.
- **Servis düzeyinde RBAC** *(2.9)* — site geneli borçlu/ödeme listeleri ve tahakkuk
  oluşturma yalnızca yönetim rollerine açık; denetçi okur, yazamaz.
  **Kanıt:** yönetici `/finance/debtors` → 200, kiracı → **403**; yetkisiz deneme denetim
  izine `DENIED` olarak yazıldı.
- **Panelde RBAC** *(0.A.10)* — panelde hiçbir erişim kontrolü yoktu; adres çubuğuna
  yazarak maaş bordrosuna ve API anahtarlarına girilebiliyordu. `src/lib/rbac.ts`
  (yol → rol, hukuki gerekçeleriyle), `middleware.ts` yol kontrolü, menü süzme,
  `/dashboard/forbidden` açıklama sayfası.

#### Para doğruluğu (FAZ 4)

- **Ödeme artık borçtan düşüyor** *(4.2)* — `monthly_assessments.paid_amount` hiç
  güncellenmiyordu; ödemesini yapan sakin **sonsuza dek borçlu** kalıyordu.
  Yönetici onay akışı (havale/EFT/nakit gerçeği): tek transaction, `FOR UPDATE`,
  yalnızca `PENDING` onaylanabilir, başka siteye ait ödeme 403.
  **Kanıt:** onay öncesi borç değişmiyor; onay sonrası `0,00 → 1.200,00` ve `PAID`;
  çift onay → **409**; `has_debt:false`.
- **Kuruş hassasiyetli para aritmetiği** *(4.3/4.4)* — `pkg/money`: para tam sayı kuruş;
  dağıtımda **en büyük kalan** yöntemi → payların toplamı tutara **birebir** eşit.
  **Kanıt:** 2000 rastgele senaryoda kuruş kaybı yok; 9 birim testi.
- **Gecikme tazminatı tahakkuku** *(KMK m.20/2)* — hiç hesaplanmıyordu.
  `POST /finance/late-fees/accrue`; oran mevzuat tablosundan; anapara = ödenmemiş
  **asıl** borç (tazminat üzerinden tazminat işlenmiyor); **idempotent**.
  **Kanıt:** 30 gün gecikme → **60,00 TL**, toplam **1.260,00 TL**; ikinci çalıştırmada
  değişmiyor; `late_fee_accruals` tablosuna gün/oran/anapara izi yazılıyor.

#### Mevzuat parametreleri (S-05)

- **`migrations/012` + `pkg/legalparams`** — 26 parametre yürürlük tarihli ve **hukuki
  dayanağıyla** veritabanında. Kanunla sabit parametrelerin (gecikme tazminatı, nisaplar,
  vekâlet sınırları) site bazında değiştirilmesi **veritabanı tetikleyicisiyle** engellendi.
  Bulunamayan parametre için **sessiz varsayılan yok** — hata döner.
- Araştırma ile teyit edilen değerler: gecikme tazminatı aylık **%5** (m.20/2, yönetim
  planıyla değiştirilemez); ısıtma **%70 tüketim + %30 alan** (RG 14.04.2008); vekâlet
  toplam oyun **%5**'i, **40 ve altı** bağımsız bölümde kişi başı **2**; malikin oyu tüm
  oyların **1/3**'ünü aşamaz (m.31); merkezi→ferdi ısıtma geçişi **2000 m²** ve üzeri
  binalarda **oybirliği** (m.42 / 5627 s. Kanun).

#### Yönetişim katmanı (FAZ 6) — yeni servis

- **`migrations/014` + `services/governance` (port 8107)** — 634 s. Kanunun zorunlu
  kıldığı ve veri modeli **hiç olmayan** süreçler:
  - **İşletme projesi (m.37):** kalem bazlı bütçe, birim payları kuruş cinsinden ve
    kalem dökümlü; tebliğ → 7 günlük itiraz süresi → kesinleşme (İİK m.68 belgesi).
    Tebliğsiz ya da süre dolmadan kesinleştirme **409** ile reddediliyor.
  - **Genel kurul (m.29-33):** 15 günlük çağrı süresi zorunlu; nisap **sayı VE arsa payı**
    bakımından; "yarıdan fazla" tam yarıyı kapsamıyor; ikinci toplantıda yeter sayı
    aranmıyor; vekâlet sınırları uygulanıyor; 4/5, oybirliği ve salt çoğunluk ayrı ayrı
    hesaplanıyor (**14 birim testi**).
  - **Defterler (m.32/36):** kayıtlar **ekle-only** ve **SHA-256 hash zincirli**;
    UPDATE/DELETE veritabanı tetikleyicisiyle engelli; `/verify` ucu zinciri doğruluyor.
  - **İcra/dava (m.22, İİK m.68):** borç tahakkuklardan hesaplanıyor; dayanak belge
    yoksa uyarı.
  **Kanıt:** 336.000 TL'lik bütçenin payları **33.600.000 kuruş** olarak birebir tutuyor;
  12/24 katılımda nisap sağlanmıyor, 13/24'te sağlanıyor; defter kaydı değiştirilemiyor.

#### Doğrulama ortamı

- **Flutter 3.47.4 WSL'e kuruldu** *(S-01b)* → mobil işler artık `[D1]` değil, çalıştırılarak
  doğrulanabiliyor. İki uygulamanın da **derlenmeyen** `widget_test.dart`'ı (şablondan kalan,
  var olmayan `MyApp` sınıfını çağıran sayaç testi) gerçek duman testleriyle değiştirildi.
- **`backend/scripts/verify-mobile.sh`** eklendi.
- **Para/tarih biçimlendirme** `intl` ile doğru TR biçimine geçti (elle biçimlendirme
  `12.450.00` gibi yanlış çıktı üretiyordu).
- **API taban adresleri düzeltildi** — sakin `localhost:8000`, yönetici ise yayında olmayan
  `api.siteeksen.com/v1` (yol da yanlıştı → her çağrı 404) kullanıyordu. Artık
  `--dart-define=API_BASE_URL`.

---

### 2026-09-12 — FAZ 0/1/3/4: Dürüstlük onarımı + kurulabilirlik (DOĞRULANMIŞ)

> **Bu turdaki her madde çalıştırılarak doğrulandı.** Doğrulama artık WSL üzerinden yapılıyor
> (Go 1.24.7 kuruldu; Docker, psql zaten mevcuttu). Toplu kanıt:
> `bash backend/scripts/verify-stack.sh` → **42 kontrol, 0 başarısız.**

#### Eklendi
- **`backend/scripts/verify-stack.sh`** — kalıcı uçtan uca doğrulama betiği. Sıfırdan PostgreSQL 16
  kurar, 11 migration'ı uygular, şema beklentilerini denetler, idempotency sınar, `pkg/audit` testini
  gerçek veritabanına karşı çalıştırır ve identity-service'i ayağa kaldırıp gerçek HTTP istekleriyle
  giriş / yanlış şifre / yetkisiz erişim / denetim izi akışlarını doğrular.
- **`backend/migrations/011_audit_log_fix.sql`** — `audit_logs` şemasını koda uyumlu hale getirir:
  `property_id`, `request_id`, `status_code` eklendi; `tenant_id` zorunluluğu kaldırıldı; 6 indeks.
- **`backend/pkg/audit/audit_test.go`** — denetim izinin gerçekten yazıldığını **gerçek veritabanına
  karşı** doğrulayan 2 test. (Böyle bir hatayı derleyici yakalayamaz; yalnızca DB'ye yazan test yakalar.)
- **`admin/src/components/ui/data-state.tsx`** — ortak `LoadingState` / `ErrorState` / `EmptyState` /
  `NotImplementedNotice` / `toUserMessage`. Sessiz mock fallback yerine görünür hata durumu sağlar.
- **Admin panelde çıkış (logout) düğmesi** — daha önce hiç yoktu, kullanıcı oturumunu kapatamıyordu.

#### Düzeltildi — kurulabilirlik (FAZ 1)
- **Veritabanı artık sıfırdan kurulabiliyor.** Üç ayrı çökme nedeni giderildi:
  1. `004_expense_management.sql` — `expense_categories` tablosu `001`'de farklı kolonlarla zaten
     vardı; `CREATE TABLE IF NOT EXISTS` sessizce atlanıyor, ardından gelen `INSERT` var olmayan
     kolonlara yazıp `42703` veriyordu. Tablo yeniden tanımlanmak yerine eksik kolonlar eklendi;
     varsayılan kategorilere KMK m.20'ye göre `distribution_type` atandı.
  2. `005_new_modules.sql` — `vehicles` tablosu aynı sorunu taşıyordu; ayrıca `idx_vehicles_unit`
     indeksi `001`'de zaten vardı. İdempotent `ALTER TABLE` + `CREATE INDEX IF NOT EXISTS`'e çevrildi,
     `plate_number` NOT NULL kısıtı kaldırılıp veri `plate` kolonuna taşındı.
  3. `005_new_modules.sql` — `inventory_categories` seed'inde **geçersiz UUID** (`ic0000...`;
     `i` hex değil) `invalid input syntax for type uuid` hatası veriyordu → `1c` prefix'ine çevrildi.
     *(Bu hata statik denetimde yakalanmamıştı; yalnızca gerçek veritabanında çalıştırınca ortaya çıktı.)*
  **Kanıt:** temiz PostgreSQL'de 11/11 migration OK; **61 tablo** oluşuyor (önceden 005 çöktüğü için
  `expenses`, `parking_zones`, `reservations`, `bank_accounts`, `employees`, `surveys`, `assets`,
  `meetings` dahil 29 tablo hiç oluşmuyordu). 006-011 tekrar çalıştırılabilir (idempotent).
- **Demo giriş onarıldı.** `002_seed_data.sql`'deki bcrypt hash hiçbir şifreyle eşleşmiyordu ve iki
  kullanıcıya aynı hash yazılmıştı. Hash'ler `cost=12` ile yeniden üretilip doğrulandı.
  **Giriş bilgileri: `5551234567` / `Demo123!`** (ikinci hesap `5559876543`).
  **Kanıt:** gerçek identity-service'e `POST /api/v1/auth/login` → **HTTP 200 + JWT**;
  yanlış şifre → **401**; token'sız `/users/me` → **401**; token ile → **200**.
- **`go build ./...` onarıldı.** Ölü `backend/api/` dizini kaldırıldı — kırık import (`sitesen/...`)
  içeriyordu ve `RequireSuperAdmin` yetkiyi **istemciden gelen `X-User-Role` başlığına** göre
  veriyordu (düzeltilseydi doğrudan kritik güvenlik açığı olurdu). Hiçbir yerden import edilmiyor,
  hiçbir Dockerfile'da derlenmiyordu.
  Ayrıca arkasında gizli kalmış iki derleme hatası giderildi: `pkg/integrations/sms`
  (kullanılmayan `body` + bakiye hiç parse edilmiyordu) ve `pkg/integrations/whatsapp`
  (tanımsız `MediaContent` tipi). **Kanıt:** `go build ./...` → 0, `go vet ./...` → 0.

#### Düzeltildi — denetim izi (FAZ 3)
- **Denetim izi (audit log) artık gerçekten çalışıyor.** `pkg/audit` şemada bulunmayan kolon adlarına
  yazıyordu (`user_ip`/`resource_type`/`resource_id` ⟷ `ip_address`/`entity_type`/`entity_id`);
  INSERT her çağrıda hata veriyor, hata `pkg/middleware/auth.go`'da `_ =` ile yutuluyordu →
  tablo aylardır boştu, oysa `legal/kvkk-aydinlatma.md` "log tutuyoruz, 2 yıl saklıyoruz" diyordu.
  `pkg/audit` tipli `Entry` API'siyle yeniden yazıldı; middleware artık hatayı logluyor,
  `property_id` ve HTTP durum kodunu kaydediyor, 403'leri `DENIED` olarak ayırıyor ve
  401'leri gürültü olmasın diye yazmıyor.
  **Kanıt:** `go test ./pkg/audit/...` → 2/2 PASS (gerçek DB'ye karşı); uçtan uca istekte
  `audit_logs`'a kayıt yazıldığı doğrulandı.

#### Düzeltildi — para doğruluğu (FAZ 4)
- **Bakiye hesabındaki kartezyen çarpım giderildi.** `GetUnitBalance`'taki
  `JOIN users u ON ll.unit_id = (...)` koşulu `u`'ya referans vermiyordu; bu bir CROSS JOIN'di ve
  bakiyeyi **kullanıcı sayısıyla çarpıyordu** (156 sakinli sitede 1.200 TL borç sakine 187.200 TL
  olarak gösteriliyordu). Hesap artık `001`'de tanımlı ve doğru yazılmış `unit_balances` view'ı
  üzerinden, sakinin **tüm** aktif bağımsız bölümlerini kapsayacak şekilde yapılıyor.
- **Ödeme kaydı tek transaction'a alındı ve IDOR kapatıldı.** Önceki akışta transaction yoktu,
  `payment_assessments` INSERT'inin hatası yutuluyordu, `amount` sütunu hiç yazılmıyordu ve
  **tahakkukların çağıran kullanıcıya ait olup olmadığı doğrulanmıyordu** (başkasının tahakkuk
  kimlikleriyle tutar öğrenilip ödeme bağlanabiliyordu). Artık sahiplik `resident_units` üzerinden
  doğrulanıyor, satırlar `FOR UPDATE` ile kilitleniyor, `deleted = 0` filtresi uygulanıyor,
  `payment_assessments.amount` ve `payments.unit_id` yazılıyor.
  Sahte `https://checkout.siteeksen.com/...` adresi kaldırıldı; yanıta `payment_gateway_ready: false`
  eklendi (ödeme sağlayıcısı yok — `questions.md` S-06).
- **Ham veritabanı hatalarının istemciye sızması engellendi** (ödeme ucu): sentinel hatalar uygun
  HTTP kodlarına eşlendi, beklenmeyen hatalar sunucuda loglanıp genel mesajla döndürülüyor.

#### Düzeltildi — dürüstlük (FAZ 0, admin panel)
Aşağıdakilerin tamamı `npm run build` → **çıkış kodu 0** ile doğrulandı (21 sayfa).
- **Giriş şifresi artık log'a yazılmıyor.** `console.log(credentials)` KVKK ihlaliydi; yerine
  yalnızca maskelenmiş telefon ve HTTP durumu loglanıyor.
- **Sessiz mock fallback'ler kaldırıldı** (expenses, personnel, parking, reservations, visitors,
  accounting, notifications, credentials). Sunucu hatasında uydurma veri gösterilmiyor; hata
  görünür ve "Yeniden dene" ile tekrarlanabilir. Mali özet kartları hata durumunda `—` gösteriyor
  (önceden ₺45.750 gibi gerçek olmayan rakamlar görünüyordu).
- **Sahte başarı mesajları kaldırıldı:** `settings` hiçbir şey kaydetmeden "Kaydedildi" diyordu;
  `notifications` `catch {}` ile gönderilmemiş bildirimi gönderilmiş gösteriyordu (ayrıca geçmiş
  listesi "124 kişiye gönderildi" gibi sahte kayıtlarla doluydu); `reports` hiçbir şey göndermeden
  "e-posta gönderildi" diyordu; `accounting`'de sunucuda karşılığı olmayan toplu "hızlı işlem" onayı vardı.
- **Uydurma şifre gösterimi kaldırıldı.** `credentials` sayfası hata alınca `"demo-sifre-2026"`
  gösteriyordu; backend'de şifre çözen bir uç nokta hiç yok. Özellik dürüstçe devre dışı bırakıldı
  ve nedeni ekranda açıklanıyor; erişim kaydının yalnızca yerel olduğu belirtiliyor.
- **Sahte soft-delete düzeltildi.** Gerçek silme ucu olanlar API'ye bağlandı; olmayanlar sahte başarı
  yerine dürüst hata veriyor (önceden `deleted:1` yalnızca React state'ine yazılıyor, sayfa
  yenilenince kayıt geri geliyordu).
- **Mock servise bağlı sayfalara `NotImplementedNotice` eklendi** — kullanıcı verinin kalıcı
  olmadığını artık biliyor.
- **Header düzeltildi:** hardcoded "Ahmet Yılmaz / Yönetim Kurulu Başkanı" yerine gerçek oturum
  bilgisi; çalışmayan arama kutusu ve sahte bildirim rozeti kaldırıldı; **çıkış düğmesi eklendi.**

#### Not
- Mobil uygulamalardaki FAZ 0 maddeleri (sahte ödeme ekranı, sahte başarı mesajları, erişilemeyen
  route'lar) **henüz yapılmadı**; Flutter kurulu olmadığı için doğrulanamıyor (`questions.md` S-01b).
- 22 mock servisin `501` dönmesi (0.B.1) sıradaki iş.

---

### 2026-09-09 — Denetim, gerçeklik tespiti ve yeniden planlama

Bu tur **kaynak kodda hiçbir değişiklik yapmadı**; yalnızca gerçek durumu tespit etti ve planlama
dosyalarını yazdı. Amaç: "yapıldı denilen işlerin yapılmamış olması" sorununu ölçmek ve kalıcı olarak çözmek.

#### Eklendi
- **`tasks/audit-raporu.md`** — 78 doküman iddiasının kod kanıtına karşı denetimi.
  **Sonuç: iddiaların %49'u YANLIŞ, %28'i kısmen doğru, %23'ü doğru.**
  **Kanıt:** `tasks/audit/` altındaki 5 ayrıntılı rapor (~370 KB), her bulgu `dosya:satır` referanslı.
- **`tasks/audit/`** — 5 kanıt dosyası: backend servisleri (25 servis), veri katmanı/altyapı,
  admin panel (16 sayfa), sakin mobil (13 ekran), yönetici mobil (24 ekran).
- **`tasks/modul-envanteri.md`** — Olması gereken **60 modüllük referans model**; 634 sayılı KMK ve
  ikincil mevzuat dayanaklı, `yorum_analizleri.txt`'ten çıkan 20 somut rakip-boşluğu etiketlenmiş (APS-1…APS-20),
  her modülde "sık atlanan tamamlayıcılar" bölümü.
- **`tasks/gap-analizi.md`** — Modül durum matrisi (60 modül × bugünkü kapsam), **97 numaralı mantık
  hatası** (B01-B97, öncelikli), ve mevcut 12 özellik alanı için "düşünülmemiş tamamlayıcılar" listesi.
- **`tasks/dogrulama-politikasi.md`** — Kanıt seviyeleri (D0-D4), "Bitti" tanımı kontrol listesi,
  **sessiz başarısızlık yasağı**, tek doğruluk kaynağı kuralları. `✅` işareti kullanımdan kaldırıldı.
- **`tasks/questions.md`** — Kullanıcı kararı bekleyen 18 konu (S-01…S-18), her biri için
  "cevap gelmezse uygulanacak varsayılan" ile.

#### Değişti
- **`tasks/roadmap.md`** — sıfırdan yeniden yazıldı. Kanıt seviyesi kolonu zorunlu; 9 faz
  (FAZ 0 dürüstlük → FAZ 8 ölçek); **dikey dilim** çalışma ilkesi; CLAUDE.md gereği
  **ustalık yol haritası** eklendi (PostgreSQL finansal modelleme, mimari, Go disiplini, Flutter üretim,
  çok kiracılılık, Türkiye mevzuat derinliği, ürün stratejisi).
- **`tasks/todo.md`** — sıfırdan yeniden yazıldı. Eski "otonom oturum" talimatı geçersiz ilan edildi.
  FAZ 0 (dürüstlük onarımı) uygulanabilir maddelere bölündü.
- **`tasks/lessons.md`** — 6 yeni ders eklendi (kanıtsız tamamlandı işaretlemek; hata yutmak;
  sahte başarı göstermek; genişlik/derinlik; "bende çalışıyor" ≠ kurulabilir; doküman çelişkisi;
  yazılmış ama hiç çalıştırılmamış kod).

#### Tespit edilen kritik durumlar (henüz düzeltilmedi — FAZ 0/1/2'de ele alınacak)
- **Veritabanı temiz makinede kurulamıyor:** `004` ve `005` migration'ları `001` ile çakışıp hata veriyor;
  `005` sonrası **29 tablo hiç oluşmuyor**. **Kanıt:** `004:5,19-30` ⟷ `001:130`; `005:65,102` ⟷ `001:303`
- **Denetim izi (audit log) hiç çalışmıyor:** kolon adları şemayla uyuşmuyor, hata yutuluyor, tablo boş.
  **Kanıt:** `pkg/audit/audit.go:28` ⟷ `003:63-76`; `pkg/middleware/auth.go:115`
- **25 servisin yalnızca 3'ü veritabanına bağlı** (identity, finance, community); 22'si sabit JSON
  döndürüyor ve yazma işlemlerine `2xx` dönüp hiçbir yere kaydetmiyor.
- **`go build ./...` başarısız:** kırık import. **Kanıt:** `backend/api/handlers/api_credentials_handler.go:8`
- **Kimlik doğrulama yok:** gateway'de auth middleware yok, Kong'da JWT plugin'i 0 → maaş, TCKN, IBAN ve
  **API anahtarları** token'sız erişilebilir. **Kanıt:** `cmd/gateway/main.go:422`, `kong/kong.yml`
- **Tenant izolasyonu kırılabilir:** `POST /users/me/active-property` sahiplik doğrulamıyor; roller global.
  **Kanıt:** `identity/repository/user.go:87-91`
- **Bakiye hesabı hatalı:** kartezyen join nedeniyle bakiye kullanıcı sayısıyla çarpılıyor
  (1.200 TL → 187.200 TL). **Kanıt:** `finance/repository/finance.go:35-43`
- **Ödeme hiçbir zaman tamamlanmıyor:** `paid_amount` hiç güncellenmiyor → ödeyen sakin sonsuza dek borçlu.
  **Kanıt:** `finance/repository/finance.go:206-224`
- **Sıfırdan kurulumda demo giriş çalışmıyor:** seed bcrypt hash'i hiçbir şifreyle eşleşmiyor
  (**fiilen test edildi**, `bcryptjs` ile 10 aday şifre denendi), iki kullanıcıda aynı hash.
  **Kanıt:** `002_seed_data.sql:29,32`
- **Sakin mobil release APK'da INTERNET izni yok** → release build'de hiçbir API çağrısı çalışmaz;
  `ios/` klasörü yok; push bildirim hiç yok; biyometrik `FlutterActivity` nedeniyle çalışmıyor.
- **Yönetici mobil taban adresi yanlış** (`/v1` ≠ `/api/v1`) → üretimde her çağrı 404; router'da auth guard yok.
- **30'dan fazla noktada sahte başarı mesajı** (mobil ödeme ekranı hiç ağ çağrısı yapmadan
  "Ödeme Başarılı!" gösteriyor).

#### Doğrulama notu
- **Fiilen çalıştırılarak doğrulanan:** admin panel derlemesi (`npm install` + `npm run build` →
  21 sayfa, çıkış kodu 0); demo bcrypt hash uyuşmazlığı.
- **Doğrulanamayan:** Go/Flutter/Docker bu makinede kurulu değil; kurumsal AppLocker politikası kullanıcı
  yazılabilir dizinlerden çalıştırılabilir dosya açılmasını engelliyor (portable Go denemesi başarısız).
  Bu nedenle backend ve mobil bulgular **statik** analizle tespit edildi. Bkz. `questions.md` S-01.

---

## [Unreleased — 2026-09-09 öncesi]

### Eklendi
- **Ustalık Mobil Entegrasyon Yol Haritası (Faz 2 & Faz 3 - Yönetici Uygulaması):**
  - **admin_app (Temel & Finansal/İleri Düzey Servisler):** `admin_app/lib/core/network/api_client.dart` içerisine otopark, personel, ziyaretçi, kargo, banka ve rezervasyon API uç noktaları için gerekli tüm metodik integrasyonlar eklendi.
  - **admin_app (Ekran Bağlantıları):** Otopark yönetimi, personel/izin takipleri, ziyaretçi kayıtları, kargo paket takibi, banka hesap/havale entegrasyonu ve tesis rezervasyonları ekranları statik verilerden tamamen arındırılarak gerçek dinamik backend mikroservislerine bağlandı.
- **Ustalık Mobil Entegrasyon Yol Haritası (Faz 1 - Sakin Uygulaması):**
  - **mobile (Sakin Uygulaması Entegrasyonu):** `api_client.dart` içerisine eksik `/reservations`, `/facilities`, `/announcements`, `/surveys`, `/packages`, `/visitors` ve `/bulletins` metotları eklenerek gerçek backend entegrasyonu sağlandı.
  - **mobile (Rezervasyon, Anket, Duyuru, Kargo ve İlan Panosu):** İlgili tüm ekranlar local mock verilerden temizlenerek `apiClient` üzerinden gerçek zamanlı dinamik veritabanı uç noktalarına bağlandı. `flutter analyze` ile 0 derleme hatasıyla derlendiği doğrulandı.
- **Ustalık Entegrasyon Yol Haritası (Faz 1 - 5 Entegrasyonları):**
  - **Faz 1 (Gateway Rota Düzeltmeleri):** 9 mikroservisin (otopark, personel, rezervasyon, kargo, devriye, anket, akıllı tahsilat, envanter, demirbaş) ön yüzden çağrılan ve 404 hatası veren tüm alt API rotaları için proxy yönlendirmeleri eklendi. `/api/v1/units/` altındaki kargo paket isteklerini kargo servisine yönlendiren custom handler yazıldı.
  - **Faz 2 (Banka Entegrasyon Servisi):** `banking-service` containerize edilerek `8106` portunda `docker-compose`'a ve gateway proxy'sine eklendi. Çakışan Go paketi derleme hatası, dosya `provider` alt paketine taşınarak giderildi.
  - **Faz 3 (Dashboard Genel İstatistikleri Aggregator):** Mock stats handler'ı güncellenerek; identity, community, visitor ve meeting mikroservislerinden gerçek zamanlı veri toplayan (Aggregator) dinamik bir yapıya dönüştürüldü. `/dashboard/recent-payments` ve `/dashboard/recent-requests` rotaları aggregator olarak bağlandı.
  - **Faz 4 (Sayaç Yönetimi Servis Katmanı):** Mock sayaç handler'ları kaldırıldı; `/api/v1/meters` ve `/api/v1/meters/` rotaları doğrudan gerçek `iot-service` mikroservis katmanına ve veritabanına bağlandı.
  - **Faz 5 (Raporlama Servis Katmanı):** `fpdf` Cell derleme hataları (`CellFormat` dönüşümü) giderildi ve gateway `Dockerfile` kopyalama hatası (`COPY . .`) düzeltildi. Mock pdf handler'ları kaldırıldı; `/api/v1/reports/generate` ve `/download` rotaları gerçek `pkg/reports` kütüphanesini in-memory registry ile kullanarak gerçek zamanlı PDF ve Excel üretir hale getirildi.
- **finance-service: `GET /finance/assessments/overview` — site genelinde dönem bazlı tahakkuk/tahsilat özeti (Mock→DB Faz 2, Adım 4 ön-hazırlık)** — Admin panel "Aidat Yönetimi" sayfasının "Tahakkuk Geçmişi" tablosu, mevcut `GET /finance/assessments`'ın sakin-bazlı (kendi tahakkukları) olması nedeniyle beslenemiyordu; yönetim rollerine açık yeni uç nokta `monthly_assessments`'ı döneme göre gruplayıp toplam tahakkuk/tahsilat/oran/durum döndürüyor (`repository.ListAssessmentPeriods`, `service.ListAssessmentOverview`, `handlers.GetAssessmentOverview`). Mevcut `GET /finance/assessments/:id` route'uyla çakışmadığı doğrulandı (Gin static-önce eşleştirme). Canlı doğrulandı. `go build`+`go vet` temiz.
- **finance-service: `GET /finance/debtors` ve yönetim görünümlü `GET /finance/payments` (Mock→DB Faz 2, Adım 3)** — Yönetim rollerine (`MANAGER`/`AUDITOR`/`STAFF`) açık, sitedeki borçlu sakinleri (`monthly_assessments.total_amount > paid_amount`, mülk sahibi/`OWNER`, borç tutarına göre azalan sıralı) listeleyen `GET /finance/debtors` eklendi (`repository.ListDebtors`, `service.ListDebtors`, `handlers.GetDebtors` — admin_app `_DebtorCard` ve ileride accounting sayfası için). Ayrıca `GET /finance/payments` rol-duyarlı hale getirildi: yönetim rolleri artık site genelindeki tüm ödemeleri sakin adı+birim bilgisiyle görür (`repository.ListPropertyPayments`, admin_app `_PaymentCard` için), sıradan sakinler değişmeden yalnızca kendi ödeme geçmişini görür (`service.GetPaymentHistory` artık `roles`/`propertyID` parametreleriyle dallanıyor). Canlı doğrulandı: yönetici (`5551234567`) gerçek borçlu listesini görüyor, sakin (`5559876543`) `/debtors`'ta 403 alıyor ve `/payments`'ta yalnızca kendi (boş) geçmişini görüyor. `go build`+`go vet` temiz.
- **finance-service: `GET /finance/expense-categories` (Mock→DB Faz 2, Adım 2)** — Aidat tahakkuku formunun gider kalemi seçimi için yönetim rollerine (`MANAGER`/`AUDITOR`/`STAFF`) açık, sitenin aktif `expense_categories` kayıtlarını `sort_order`/`name`'e göre listeleyen uç nokta eklendi (`repository.ListExpenseCategories`, `service.ListExpenseCategories`, `handlers.GetExpenseCategories`). `go build`+`go vet` temiz.
- **finance-service: `POST /finance/assessments` — gerçek aidat tahakkuku oluşturma (Mock→DB Faz 2, Adım 1)** — Yönetimin (`MANAGER`/`AUDITOR`/`STAFF`) gider kalemlerini girip dönemlik aidat tahakkuku başlatabildiği uç nokta eklendi. `repository.CreateAssessment`, sitedeki tüm aktif birimleri (`share_ratio`/`gross_area_m2`/`is_commercial`/`is_ground_floor`) çekip her gider kalemini kategorinin `distribution_type`'ına göre uygun birimlere paylaştırıyor (`SHARE_RATIO`→arsa payı oranı, `EQUAL`→eşit bölüşüm, `AREA_M2`→metrekare oranı; henüz desteklenmeyen `METER_READING`/`CUSTOM` arsa payına düşüyor — sayaç bazlı dağıtım Faz 4 kapsamında ele alınacak), `applies_to_commercial`/`applies_to_ground_floor` filtrelerini uyguluyor, ardından her birim için tek `monthly_assessments` kaydı + ilgili `assessment_details` satırlarını tek transaction'da yazıyor (aynı dönem için ikinci kez tahakkuk denenirse `(unit_id, period_year, period_month)` unique kısıtından `ErrAssessmentPeriodExists` ile 409 dönüyor). `service.isFinanceManagement` rol kontrolü, `handlers.mapAssessmentError` (`errors.Is` tabanlı) eklendi; route `AuthMiddleware()`+`AuditLog(pool, "finance")` altında. `go build`+`go vet` temiz.
- **admin_app: Sakinler ekranları gerçek API'ye bağlandı + konvansiyon birleştirme (Mock→DB Faz 1, Adım 4/4 — Faz 1 tamamlandı)** — `api_client.dart`'taki `getResidents`/`getResident`/`createResident`/`updateResident` artık admin panelle aynı `/residents` (+ `/units`) konvansiyonunu kullanıyor (önceden `/users?role=RESIDENT` + `/units` karışık kontratına sahipti — admin panel `/residents` bekliyordu, bu da admin_app'in identity-service ile hiç konuşamamasına yol açıyordu; `updateResident` artık `PATCH` kullanıyor). `residents_screen.dart`'taki tamamen sahte `_residents` listesi kaldırıldı; ekran artık `apiClient.getResidents(search, role)` ile yükleniyor (loading/refresh/boş-durum + role göre filtre sheet'i — arama gerçek backend'e gidiyor). `add_resident_screen.dart`, `apiClient.getUnits()`'ten gerçek birim listesini çekip `apiClient.createResident()` ile gerçek kayıt oluşturuyor (backend'in desteklemediği TC/taşınma tarihi/not alanları kaldırıldı, "Ad Soyad" tek alanı "Ad"/"Soyad" olarak ikiye ayrıldı — `CreateResidentInput` kontratıyla birebir). `resident_detail_screen.dart`, `apiClient.getResident()` ile gerçek profil/iletişim bilgisini gösteriyor; sahte "Finansal Durum"/"Aidat Geçmişi" bölümleri (finance-service entegrasyonu Faz 2 kapsamında) kaldırıldı, "Sakini Kaldır" aksiyonu `apiClient.updateResident(id, {is_active: false})` ile gerçek pasifleştirme/aktifleştirme yapıyor. `flutter analyze` temiz (yalnızca kod tabanı genelinde var olan `withOpacity`/`value:` deprecation info'ları).
- **Admin panel: Sakinler sayfası gerçek API'ye bağlandı (Mock→DB Faz 1, Adım 3)** — `residents/page.tsx`'teki `mockResidents`/in-memory CRUD kaldırıldı; sayfa artık `apiClient.getResidents()`+`apiClient.getUnits()` ile yükleniyor (loading spinner eklendi), `apiClient.createResident()`/`apiClient.updateResident()` ile gerçek backend'e yazıyor. `Resident`/`Unit` arayüzleri backend `models.Resident`/`models.Unit` ile birebir eşleşecek şekilde yeniden yazıldı (`first_name`/`last_name`/`unit_id`/`is_active` vb., `id: string` UUID). Rol seçimi artık DB değerleriyle (`OWNER`/`TENANT`/`PROXY`) çalışıyor, ekranda Türkçe etiketlere (`ROLE_LABELS`) çevriliyor. "Sil" aksiyonu, backend'de henüz `DELETE /residents/:id` olmadığı için `PATCH /residents/:id { is_active: false }` ile birim ilişkisini pasifleştiriyor ("Pasifleştir" olarak yeniden adlandırıldı — geri alınabilir). Backend henüz finance-service'e bağlı olmadığından sahte göstermemek için **`Bakiye` sütunu kaldırıldı**. CSV yükleme artık her satır için gerçek `apiClient.createResident()` çağrısı yapıyor (mock satır eklemiyor); örnek CSV `unit_id` (UUID) bekleyecek şekilde güncellendi. `api-client.ts`'e `getUnits()` eklendi, `updateResident()` imzası backend'in gerçek `UpdateResidentInput{role, is_active}` kontratıyla eşleşecek şekilde düzeltildi (önceden `first_name`/`phone` gibi backend'in desteklemediği alanları kabul ediyordu).
- **Gateway: `/api/v1/residents` ve `/api/v1/units` artık identity-service'e proxy ediliyor (Mock→DB Faz 1, Adım 2)** — `cmd/gateway/main.go`'daki sahte JSON döndüren `mux.Handle("/api/v1/residents", ...)`/`"/api/v1/residents/"` mock handler'ları kaldırıldı; bu path'ler `proxyPaths(mux, newProxy(identityURL), ...)` ile gerçek identity-service'teki yeni `residents`/`units` endpoint'lerine yönlendiriliyor (bkz. Adım 1).
- **identity-service: Gerçek `residents`/`units` modülü (Mock→DB Faz 1, Adım 1)** — Önceden gateway'in kendi içinde sabit JSON döndürdüğü `/api/v1/residents*`, artık identity-service'teki gerçek `resident_units`/`users`/`units` JOIN sorgularına dayanıyor. Yeni `models/resident.go` (`Resident`, `CreateResidentInput`, `UpdateResidentInput`), `repository/resident.go` (`List`/`GetByID`/`Create`/`Update`/`ListUnits` — `Create` tek transaction içinde telefon numarasıyla mevcut kullanıcıyı birime bağlıyor ya da `crypto/rand` ile üretilip `bcrypt.GenerateFromPassword` ile hash'lenen geçici şifreyle yeni kullanıcı açıyor), `service/resident.go` (`isResidentManagement` rol kontrolü — yalnızca `MANAGER`/`AUDITOR`/`STAFF`), `handlers/resident.go` (`errors.Is` tabanlı hata eşleme: `ErrResidentForbidden`/`ErrResidentNotFound`/`ErrUnitNotFound`/`ErrPhoneAlreadyExists`) eklendi; `main.go`'da `GET/POST /api/v1/residents`, `GET/PATCH /api/v1/residents/:id`, `GET /api/v1/units` route'ları `AuthMiddleware()` (+ `AuditLog(pool, "resident")`) altında kayıtlı. (Mock verilerin DB'ye bağlanması — Faz 1/6, Adım 1/4: identity-service backend; sıradaki adımlar gateway proxy düzeltmesi ve frontend bağlama)
- **Talep onay mekanizması** — Migration `010_request_confirmation.sql` ile `requests` tablosuna `user_confirmed_at TIMESTAMP NULL` eklendi. `community-service` (önceden tamamen mock) finance-service pattern'iyle gerçek DB bağlantısına kavuştu; yeni `requests` modülü (`models`/`repository`/`service`/`handlers`) ile `GET/POST /requests`, `PATCH /requests/:id/status`, `POST /requests/:id/confirm-resolution` uç noktaları eklendi (`AuthMiddleware()` + `AuditLog(pool, "request")` altında). Durum geçişleri `allowedStatusTransitions` ile kısıtlandı: yönetici sadece OPEN→IN_PROGRESS→RESOLVED geçişini yapabiliyor, `CLOSED`'a yalnızca sakinin onayı (`ConfirmResolution`) ile ulaşılıyor — onaylarsa `CLOSED` + `user_confirmed_at` set ediliyor, reddederse talep `IN_PROGRESS`'e geri dönüp `resolved_at` temizleniyor. `mobile`'da `requests_screen.dart`'a sakin için "Sorunum çözüldü ✓ / Devam ediyor ✗" aksiyonları eklendi (`apiClient.confirmRequestResolution`). `admin_app`'te `request_detail_screen.dart`'a yönetici `RESOLVED` seçtiğinde "Sakin onayı bekleniyor, otomatik kapanacak" notu eklendi ve `Güncelle` butonu gerçek `apiClient.updateRequestStatus()` çağrısına bağlandı (`CLOSED` zaten doğrudan seçilebilir bir seçenek değildi). Admin panelde `requests/page.tsx`'e `RESOLVED` için "Onay bekliyor", `CLOSED` + `user_confirmed_at` için "Sakin onayladı: (tarih)" rozetleri eklendi; manuel durum değiştirme menüsünden `CLOSED` seçeneği kaldırıldı. (Apsiyon karşılaştırması: yorum_analizleri.txt — "yönetici talebi tek taraflı kapatıyor, sakine onay sorulmuyor" şikayetine karşılık, Paket 1/5 — son paket)
- **KVKK açık rıza akışı + audit log** — Migration `009_kvkk_consent.sql` ile `users` tablosuna `kvkk_consent_at TIMESTAMP NULL` eklendi. identity-service `Login`/`GetCurrentUser` yanıtlarına `kvkk_consent_required` (consent_at NULL ise `true`) eklendi; yeni `POST /users/me/kvkk-consent` endpoint'i onay zamanını işaretliyor. `mobile` ve `admin_app`'e geçilemez (`PopScope(canPop: false)`) zorunlu KVKK aydınlatma + açık rıza ekranı eklendi — giriş sonrası `kvkk_consent_required=true` ise kullanıcı onaylamadan ana ekrana geçemiyor. Ayrıca `pkg/audit/` paketi (`LogAction`) yazıldı; `pkg/middleware/auth.go`'daki TODO durumundaki `AuditLog()` middleware'i gerçek `INSERT INTO audit_logs` ile tamamlandı (HTTP method → `action`: GET→VIEW, POST→CREATE, PUT/PATCH→UPDATE, DELETE→DELETE) ve hassas route gruplarına (`identity /users`, `finance /finance`) bağlandı. (KVKK belgesi vardı ama mandatory consent flow yoktu, `audit_logs` tablosu boştu — Paket 5/5)
- **Gerçek biyometrik giriş** — `mobile`'da `api_client.dart` bellek-içi token tutmaktan `flutter_secure_storage` tabanlı kalıcı oturuma geçirildi (`_persistTokens`, `_tryRefreshToken`, 401'de otomatik yenileme interceptor'ı, `hasStoredSession`/`isBiometricEnabled`/`setBiometricEnabled`/`loginWithStoredSession`). `login_screen.dart`'taki tamamen mock `_handleLogin()` gerçek `apiClient.login()` çağrısına bağlandı (daha önce `Future.delayed` ile sahte gecikme atıp hiçbir yere yönlendirmiyordu); ilk başarılı girişte "Biyometrik girişi etkinleştir?" diyaloğu gösteriliyor, placeholder parmak izi butonu artık `local_auth.authenticate()` + kayıtlı refresh token ile oturum yenileme akışına bağlı. `admin_app`'e de aynı akış eklendi: `pubspec.yaml`'a `local_auth` bağımlılığı, `api_client.dart`'a `hasStoredSession`/`isBiometricEnabled`/`setBiometricEnabled`/`loginWithStoredSession`, `login_screen.dart`'a biyometrik buton + etkinleştirme diyaloğu. (Apsiyon karşılaştırması: `local_auth` kuruluydu ama her iki app'te de kullanılmıyordu, Paket 4/5)
- **Rol bazlı menü filtreleme (RBAC)** — `pkg/middleware/auth.go`'ya yönetim-tarafı rol sabitleri eklendi (`MANAGER`/`AUDITOR`/`STAFF`, mevcut `RESIDENT`/`OWNER`/`TENANT` ile birlikte); `RequireRole()` middleware'i (önceden hiçbir route'a bağlı değildi) `POST /users/me/properties` (yeni site oluşturma) endpoint'ine `RequireRole(MANAGER, OWNER)` olarak uygulandı. `admin_app`'e JWT `roles` claim'ini decode eden `getCurrentUserRoles()` eklendi (`core/network/api_client.dart`); ana ekran menüsü ve drawer artık role göre filtreleniyor — `AUDITOR`/`STAFF` rolündeki kullanıcılar "Sakinler", "Finans", "Raporlar" öğelerini görmüyor. Migration `008_manager_roles.sql` ile demo yönetici hesabına (`+905551234567`) `MANAGER` rolü eklendi (idempotent). (Apsiyon karşılaştırması: yorum_analizleri.txt — "roller manager/auditor/assistant doğru yönetilmiyor" şikayetine karşılık, Paket 3/5)
- **Android geri tuşu navigasyon düzeltmesi** — `mobile` ve `admin_app` ana ekranlarına (`main_screen.dart`) `PopScope` eklendi: alt sekme kökte değilken geri tuşu Dashboard/Ana Sayfa sekmesine döner, kök sekmedeyken "Uygulamadan çıkmak istediğinize emin misiniz?" onay diyaloğu gösterilir ve onaylanırsa `SystemNavigator.pop()` ile çıkılır. (Apsiyon yorumlarındaki "geri tuşu uygulamayı direkt kapatıyor" şikayetine karşılık geliştirildi — `yorum_analizleri.txt` karşılaştırması, Paket 2/5)
- **Yeni site ekleme özelliği** — Sidebar'daki "+ Yeni Site Ekle" butonu artık çalışıyor: `POST /users/me/properties` endpoint'i (identity servisi) tek transaction içinde `properties` + varsayılan `unit` ("A-YÖNETİM") + `resident_units` (`OWNER`) satırlarını oluşturuyor — böylece yeni site mevcut `GetUserProperties` join zincirinde anında görünüyor. Frontend'de modal form (Site Adı, Adres, Şehir, İlçe) → oluşturma → otomatik aktif site seçimi → token yenileme → sayfa yenileme zinciri canlı ortamda uçtan uca doğrulandı.
- **Property türü (`type`) — şema değişikliği** — `properties` tablosuna `type VARCHAR(20) NOT NULL DEFAULT 'SITE'` kolonu eklendi (migration `007_property_type.sql`, idempotent). `SITE`/`APARTMENT`/`BUILDING` değerleri destekleniyor; geçersiz/boş değer servis katmanında `SITE`'a normalize ediliyor. Sidebar'daki modal "Yeni Taşınmaz Ekle" olarak güncellendi, "Tür" seçici (Site/Apartman/Bina) eklendi. Canlı ortamda üç senaryo (geçerli tür, eksik tür, geçersiz tür) uçtan uca test edildi.

### Düzeltildi
- **Sidebar: Site/apartman seçici gerçek backend kontratına bağlandı** — `<select>` hiçbir state'e bağlı değildi, seçim panele yansımıyordu. İlk denemede eklenen `X-Tenant-ID` header yaklaşımı, backend'de o middleware hiç bağlı olmadığı için geri alındı; bunun yerine identity serviste hazır olan gerçek mekanizmaya bağlandı: `GET /users/me/properties` (gerçek site listesi) → seçimde `POST /users/me/active-property` (DB güncelleme) → `/auth/refresh` (yeni `property_id` claim'li JWT) → sayfa yenileme. Zincir canlı ortamda uçtan uca test edildi.
- **NextAuth ↔ apiClient token köprüsü eklendi** — `session.accessToken`/`refreshToken` daha önce hiçbir yerde kullanılmıyordu; `apiClient`'in `localStorage`'ındaki token hep boştu, gerçek backend çağrıları sessizce 401 alıp mock'a düşüyordu. Artık `Sidebar` `useSession()` ile token'ları `apiClient.setToken()`'a köprülüyor.
- **Migration 006 (soft-delete) DB'ye uygulandı** — dosya önceki oturumda yazılmış ama hiç çalıştırılmamıştı; `users` tablosunda `deleted` kolonu yoktu ve bu yüzden TÜM giriş istekleri "Geçersiz telefon veya şifre" hatasıyla başarısız oluyordu. Migration idempotent (`IF NOT EXISTS`) olduğu için güvenle uygulandı.
- **Migration 008/009/010 DB'ye uygulandı (Faz 1 canlı testi sırasında bulundu)** — Aynı kök neden tekrarlandı: `docker-entrypoint-initdb.d` yalnızca postgres volume'u ilk kez oluşturulurken çalışıyor; bu üç migration dosyası volume zaten doluyken eklendiği için hiç çalıştırılmamıştı. Sonuç: `kvkk_consent_at` kolonu olmadığından `GetByPhone` SQL hatası alıp tüm girişler "kullanıcı bulunamadı"ya düşüyordu (008/009), ve hiçbir kullanıcıda `MANAGER` rolü yoktu — demo yönetici hesabı bile sadece `{RESIDENT,OWNER}` idi, bu da gerçek `/residents` endpoint'inin "yetkisiz" dönmesine yol açıyordu. Üç migration'ın içeriği (`ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, idempotent `UPDATE ... array_append`) çalışan postgres container'ına elle uygulandı; demo yönetici artık `{RESIDENT,OWNER,MANAGER}`. **Not**: Bu, aynı sorunun üçüncü tekrarı — kalıcı çözüm için bir migration-runner mekanizması (örn. `golang-migrate` ya da servis başlangıcında "uygulanmamış migration var mı" kontrolü) eklenmeli (Faz 6 / altyapı kuyruğuna eklendi).
- **Demo kullanıcı şifre hash'i düzeltildi** — DB'deki hash dokümante edilen `demo123` ile eşleşmiyordu; bilinen değere sıfırlandı.

### Düzeltildi (Input/Form Denetimi)
- **Settings: Genel Ayarlar formu** — inputlar `defaultValue`'dan controlled state'e çevrildi, "Değişiklikleri Kaydet" butonu artık çalışıyor ve onay gösteriyor
- **Settings: Bildirim Ayarları** — checkbox'lar `defaultChecked`'tan state'e bağlandı, anında kaydediliyor
- **Settings: Yönetici Kullanıcılar** — işlevsiz "⋮" menü kaldırıldı, edit/delete (soft-delete) eklendi
- **Reports: PDF/Excel/E-posta butonları** — onClick'siz üç buton işlevsel hale getirildi (CSV indirme + e-posta onay mesajı)
- **Meters: "Okuma Dönemi" select** — state'siz kalmıştı, controlled hale getirildi
- **Credentials: writeLog** — audit log ile ilgisiz `apiClient.createExpense` kontrolü temizlendi

### Eklendi
- **Admin panel: Tüm sayfalara edit/delete/CSV** — Accounting (gelir/gider), expenses, parking (araç), personnel (personel+izin reddet), reservations, visitors, notifications (history delete), meters (gerçek CSV upload/download, sayaç ekle/düzenle/sil), assessments (tahakkuk düzenle/sil), announcements, requests, residents — tüm silmeler soft-delete (deleted=1)
- **Soft-delete pattern** — Tüm arayüz bileşenlerinde `deleted: number` alanı, display `deleted === 0` filtreliyor, silme `deleted = 1` set ediyor, gerçek kayıt tutulmuyor
- **CSV upload/download** — residents, expenses, parking, personnel, visitors, meters, assessments, announcements, requests sayfalarında örnek CSV indirme (Blob + URL.createObjectURL) ve FileReader tabanlı CSV parse/yükleme
- **Settings: Kullanıcı edit/delete** — Yönetici Kullanıcılar listesine düzenleme ve soft-delete eklendi
- **Backend soft-delete migration (006)** — 23 tabloya `deleted INTEGER NOT NULL DEFAULT 0` eklendi + index'ler; identity ve finance repository sorgularına `AND deleted = 0` filtresi eklendi

### Önceki Eklendi
- **Admin panel: Gider Yönetimi sayfası** — `/dashboard/expenses`; kategori bazlı gider listesi, fatura durumu, onay filtresi, gider ekleme modalı, mock fallback
- **Admin panel: Otopark sayfası** — `/dashboard/parking`; şu an içerideki araçlar + kayıtlı araç listesi, giriş/çıkış işlemleri, plaka arama, araç ekleme
- **Admin panel: Personel sayfası** — `/dashboard/personnel`; çalışan listesi (maaş gizleme/gösterme), izin talepleri, izin onayla/reddet, personel ekleme
- **Admin panel: Rezervasyon sayfası** — `/dashboard/reservations`; tesis listesi + rezervasyon tablosu, iptal işlemi, yeni rezervasyon ekleme
- **Admin panel: Ziyaretçi sayfası** — `/dashboard/visitors`; bugün/içeride/tümü sekmesi, giriş-çıkış kaydı, durum göstergesi, ziyaretçi kayıt formu
- **Sidebar: 5 yeni nav öğesi** — Gider Yönetimi, Otopark, Personel, Rezervasyon, Ziyaretçi
- **api-client.ts: Parking, Personnel, Reservations, Visitors API metodları** — tüm CRUD ve giriş/çıkış endpointleri
- **Admin panel: Muhasebe sayfası backend bağlantısı** — Giderler `/api/v1/expenses` servisinden yükleniyor; yeni gider oluşturma API'ye gönderiliyor
- **Admin panel: Bildirimler sayfası backend bağlantısı** — Geçmiş `/api/v1/notifications/history`'den yükleniyor; gönderme `/api/v1/notifications/send`'e proxy ediliyor
- **Admin panel: Kimlik Bilgileri sayfası backend bağlantısı** — Settings servisinden API kimlik bilgileri yükleniyor ve mock verilerle birleştiriliyor
- **api-client.ts** — Expenses, Notifications, Credentials API metodları eklendi
- **Gateway v1.2.0** — 24 servise proxy routing; tüm yeni servisler env'de tanımlı; `proxyPaths()` yardımcı fonksiyon
- **Kong güncellendi** — 24 mikroservis Kong üzerinden yönlendiriliyor, tüm servisler için CORS ve rate-limiting
- **19 yeni servis docker-compose'a eklendi** — expense(8086), asset(8087), bulletin(8089), contract(8090), document(8091), energy(8092), esg(8093), inventory(8094), meeting(8095), nps(8096), package(8097), parking(8098), patrol(8099), personnel(8100), reservation(8101), settings(8102), smart-collection(8103), survey(8104), visitor(8105)
- **Tüm servisler için Dockerfile oluşturuldu** — CGO_ENABLED=0 GOOS=linux, alpine:3.19, chmod +x

### Düzeltildi
- **nps, settings, esg, document servisleri "exec format error" düzeltildi** — Bu 4 servis `package main` değil library package olarak yazılmıştı; `package main` + `main()` + Gin HTTP server eklendi
- **Settings servisi AES-256 şifreleme anahtarı düzeltildi** — Sabit 32 byte key varsayılan değer; `copy()` ile esnek uzunluk desteği
- **Gateway gerçek reverse proxy'ye dönüştürüldü** — auth/users → identity:8081, finance → finance:8082, announcements/surveys/bulletins/reservations → community:8083. Diğer endpointler (residents, meters, requests, dashboard) mock olarak gateway'de tutuldu.
- **docker-compose admin panel env düzeltildi** — `NEXT_PUBLIC_API_URL` ve `API_URL` `/api` → `/api/v1` güncellendi; servisler arası iletişim için gateway'e bağımlılıklar eklendi.
- **Identity service: telefon normalizasyonu** — `5551234567`, `05551234567`, `+905551234567` formatlarının tümü kabul ediliyor.
- **Identity repository: NULL scan hatası düzeltildi** — `tc_encrypted`, `tc_hash`, `email`, `active_property_id` alanları NULL olduğunda `COALESCE` ile boş string döndürülüyor.
- **Auth middleware: JWT claim uyumsuzluğu düzeltildi** — Token `"sub"` claim'ini kullanıyor ama middleware `"user_id"` okuyordu; `RegisteredClaims.Subject` fallback eklendi.
- **api-client.ts: token refresh implementasyonu** — 401 yanıtında refresh token ile otomatik yenileme; başarısız olursa login sayfasına yönlendirme.
- **Demo şifre hash güncellendi** — Seed data'daki bcrypt hash `Demo123!` şifresiyle eşleşecek şekilde DB'de güncellendi.

---

## [0.5.0] — 2026-02-03

### Eklendi
- **API Gateway servisi** (`backend/cmd/gateway/`) — Go ile yazılmış hafif dev gateway, port 8888
- **Admin panel: Raporlar sayfası** — daire bazlı aidat/tahsilat raporları, Excel/PDF çıktısı
- **Admin panel: Ayarlar sayfası** — site bilgileri, bildirim ve entegrasyon ayarları
- **Admin panel: Multi-tenant desteği** (`backend/migrations/003_multi_tenant.sql`)

### Değişti
- Tüm backend servisleri Go 1.24'e güncellendi
- Admin panel: Sakinler, Aidatlar, Duyurular sayfaları büyük ölçüde genişletildi
- `docker-compose.yml`'e gateway servisi eklendi

---

## [0.4.0] — 2026-02-01

### Eklendi
- **Belge yönetim servisi** (`backend/services/document/`) — belge yükleme, imzalama, arşivleme
- **Mobil: Belgeler ekranı** — sakin belgelerini listeleme ve görüntüleme
- **Mobil: Varlıklar ekranı** — site demirbaş ve varlık takibi
- **Admin app: Sözleşme yönetim ekranı** büyük güncelleme

---

## [0.3.0] — 2026-02-01

### Eklendi
- **Apple tarzı UI sistemi** — `mobile/lib/core/theme/apple_theme.dart` ve `apple_widgets.dart`
- **Admin app ekranları:** Varlık yönetimi, Banka entegrasyonu, Duyuru panosu, Akıllı tahsilat, Sözleşme, Toplantı sihirbazı, Koli takibi, Güvenlik turu, API ayarları, Anket yönetimi
- **Mobil ekranlar:** Ana sayfa, Duyurular, İlan panosu, Enerji tüketimi, Aidat ödeme, Koli takibi, Profil, İstek oluşturma, Rezervasyon, Anketler, Ziyaretçi ön kayıt
- **Backend entegrasyonları:** AI servisi (`pkg/integrations/ai/`), Banka (`bank/`), Push (`push/`), SMS, WhatsApp
- **Backend servisleri:** `banking`, `esg`, `nps`, `settings`
- **API Credentials yönetimi** — üçüncü taraf API anahtarlarının şifreli saklanması

---

## [0.2.1] — 2026-02-01

### Eklendi
- **Admin app ekranları:** Enerji panosu, Envanter yönetimi, Otopark yönetimi, Personel yönetimi, Rezervasyon yönetimi, Ziyaretçi yönetimi
- **Apple tarzı tema ve widget sistemi** — admin app için (`admin_app/lib/core/theme/apple_theme.dart`)

---

## [0.2.0] — 2026-02-01

### Eklendi
- **15 yeni backend servisi:** `asset`, `bulletin`, `contract`, `energy_analytics`, `inventory`, `meeting_wizard`, `package`, `parking`, `patrol`, `personnel`, `reservation`, `smart_collection`, `survey`, `visitor`
- **Veritabanı migration 005** — tüm yeni modüller için tablo şemaları

---

## [0.1.1] — 2026-02-01

### Eklendi
- **Gider ve fatura yönetimi** — kategori bazlı gider takibi (sabit/değişken/plansız)
- **AI fatura tarayıcı** — OpenAI Vision / Google Document AI entegrasyonu (`backend/pkg/ai/invoice_parser.go`)
- **Gider servisi** — `backend/services/expense/`, port 8086
- **Admin app gider ekranları:** Gider listesi, Gider ekleme (AI destekli), Gider detay
- **Mobil: Sakin gider görüntüleme** ekranı
- **Veritabanı migration 004** — gider yönetimi tabloları
- Giderin aidada yansıtılması ve faturasız gider onay mekanizması

---

## [0.1.0] — 2026-02-01

### Eklendi
- **Admin Flutter uygulaması** (`admin_app/`) — site yöneticisi mobil uygulaması
- 15 ekran: Login, Dashboard, Sakinler, Finans, Sayaçlar, Duyurular, Talepler, Raporlar
- Riverpod state management, GoRouter navigasyon, Dio API client

---

## [0.0.1] — 2026-02-01 — İlk Commit

### Eklendi
- **5 Go mikroservis:** Identity (8081), Finance (8082), Community (8083), IoT (8084), Notification (8085)
- **Next.js admin paneli** — sakinler, aidatlar, sayaçlar, talepler, duyurular ekranları
- **Flutter mobil uygulaması** (`mobile/`) — sakin uygulaması
- **Multi-tenant SaaS altyapısı** — `pkg/tenant/` middleware
- **Güvenlik:** JWT (15dk/7gün), AES-256-GCM şifreleme, KVKK audit log
- **iyzico ödeme entegrasyonu**
- **Firebase push notification**
- **Kong API Gateway** yapılandırması (`kong/kong.yml`)
- **Kubernetes deployment** manifest'leri (`k8s/`)
- **CI/CD pipeline** (`.github/workflows/ci-cd.yaml`)
- **Yasal belgeler:** KVKK, Gizlilik politikası, Kullanım koşulları
