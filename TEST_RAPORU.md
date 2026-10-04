# SiteEksen Kapsamlı Test ve Eksik Hizmetler Raporu

**Tarih:** 04 Ekim 2026  
**Test Ortamı:** Yerel Ön Yüz (`http://localhost:3001`), API Gateway (`http://localhost:8888`), PostgreSQL 16  
**Test Kapsamı:** İnsan tipi tarayıcı arayüzü (UI) ve arka uç (API Gateway & Mikroservisler) uçtan uca fonksiyonel ve çapraz etki testleri  
**Test Hesabı:** Telefon: `5551234567` / Şifre: `Demo123!` (Site Yöneticisi: Ahmet Yılmaz, Güneş Sitesi)  
**Doğrulama Standardı:** `CLAUDE.md` ve `tasks/dogrulama-politikasi.md` (D0-D4 canlı kanıt politikası)

---

## 1. Yönetici Özeti

SiteEksen yönetim platformunda yer alan tüm menüler, alt hizmetler, form girdileri, durum makineleri ve çapraz modül etkileşimleri hem tarayıcı arayüzü üzerinden insan gibi tıklanarak hem de arka planda API çağrıları seviyesinde test edilmiştir.

* **Toplam İncelenen Modül / Sayfa Sayısı:** 35+
* **Başarıyla Geçen ve Doğrulanan Hizmet Sayısı:** 27
* **Testi Geçemeyen veya İstenileni Tam Veremeyen Hizmet Sayısı:** 8

Bu rapor, özellikle **testi geçemeyen, hata veren (`4xx/5xx`) veya altyapı eksikliği nedeniyle beklenen sonucu üretemeyen hizmetleri**, geliştirme ekibine doğrudan iş emri olarak verilebilecek teknik detaylarıyla sunmaktadır.

---

## 2. Testi Geçemeyen / Eksik Kalan Hizmetler (Geliştirme Listesi)

Aşağıdaki 8 hizmet yapılan testlerde ya doğrudan hata üretmiş, ya yasal/mantıksal kısıt nedeniyle tamamlanamamış ya da altyapısı yarım bırakılmıştır:

### 2.1. Tesisler ve Ortak Alan Rezervasyonu (`/reservations`)
* **Hizmet / Modül:** Tesis Yönetimi & Rezervasyon Motoru (`services/reservation`)
* **Test Edilen İşlem:** Ortak sosyal tesislerin (Havuz, Tenis Kortu, Toplantı Salonu vb.) listelenmesi, yeni tesis eklenmesi ve sakin tarafından rezervasyon oluşturulması.
* **Alınan Test Sonucu:**
  * `GET /api/v1/facilities` çağrıldığında sistem boş dizi dönmektedir (`data: []`).
  * Ön yüzde seçilebilecek hiçbir tesis bulunmadığı için ne yönetici ne de sakinler rezervasyon akışını başlatabilmektedir.
* **Kök Neden:**
  1. Backend `services/reservation` servisinde yeni tesis eklemeye yarayan `POST /api/v1/facilities` uç noktası yazılmamıştır.
  2. Veritabanındaki `facilities` tablosuna başlangıç tohum (seed) verisi eklenmemiştir.
  3. Yönetim panelinde yöneticinin yeni tesis tanımlayabileceği bir form veya arayüz modalı bulunmamaktadır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] `services/reservation` servisine `POST /api/v1/facilities` ucu eklenmeli (`name`, `capacity`, `requires_approval`, `open_time`, `close_time`, `buffer_minutes`, `cancellation_deadline_hours`).
  - [ ] Veritabanına başlangıç tohum verisi olarak en az 2 tesis eklenmeli (ör. *Sosyal Tesis Toplantı Salonu*, *Tenis Kortu*).
  - [ ] Yönetim paneli Rezervasyon sayfasına `+ Yeni Tesis Ekle` modalı ve form doğrulamaları bağlanmalı.

---

### 2.2. Isı Pay Ölçer ve Tüketim Paylaştırma Motoru (`/meters`)
* **Hizmet / Modül:** IoT ve Tüketim Dağıtım Motoru (`services/iot` / `consumption`)
* **Test Edilen İşlem:** `POST /api/v1/consumption/allocate` uç noktası ile 12.000 TL tutarındaki ortak yakıt/ısınma faturasının 25 bağımsız bölüme paylaştırılması.
* **Alınan Test Sonucu:**
  ```json
  HTTP 422 Unprocessable Entity
  {
    "error": "Sabit pay kullanım alanına göre dağıtılır; eksik alanı sıfır saymak o bölümü paydan muaf tutup diğerlerine yüklerdi."
  }
  ```
* **Kök Neden:** Kat Mülkiyeti Kanunu ve 5627 s. Enerji Verimliliği Kanunu gereği merkezi ısınmanın %30'luk sabit ortak gider payı dairelerin kullanım alanına (m²) göre dağıtılır. Ancak sistemdeki mevcut dairelerin çoğunda `gross_area_m2` veya `net_area_m2` alanı boş (`null` veya `0`) bırakıldığı için paylaştırma algoritması adaletsiz hesaplama yapmamak adına işlemi durdurmaktadır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] Bağımsız Bölüm (Daire) oluşturma ve düzenleme formunda (`/dashboard/units`) `gross_area_m2` alanının girilmesi zorunlu (`required`) hale getirilmeli.
  - [ ] Tüketim paylaştırma öncesinde sistem eksik m² alanına sahip daireleri listeleyen bir ön doğrulama ekranı sunmalı ve yöneticiden bu alanları tamamlamasını istemelidir.

---

### 2.3. Kargo Teslimatında İmza ve Fotoğraf Saklama (`/packages`)
* **Hizmet / Modül:** Güvenlik ve Kargo Teslimat Takibi (`services/package`)
* **Test Edilen İşlem:** Güvenliğe gelen kargo paketinin sakine teslim edilmesi (`POST /api/v1/packages/:id/deliver`).
* **Alınan Test Sonucu:**
  ```json
  HTTP 200 OK
  {
    "status": "DELIVERED",
    "note": "Teslim kaydedildi. İmza/fotoğraf SAKLANMADI; dosya depolama altyapısı henüz yoktur."
  }
  ```
* **Kök Neden:** Sistemde `services/document` (belge arşivi, SHA-256 doğrulama ve yerel disk depolama) servisi hazır ve çalışır durumda olmasına rağmen; kargo teslimatı anında teslim alanın dijital imzasını veya paketin teslim fotoğrafını belge servisine aktaran köprü entegrasyonu yazılmamıştır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] Kargo teslim modalına dokunmatik imza alanı (canvas) ve teslim fotoğrafı yükleme alanı eklenmeli.
  - [ ] Yüklenen görsel `services/document` servisine `related_type: "PACKAGE"` ve `related_id: package_id` üst verisiyle aktarılmalı; teslim kaydının hukuki ispat niteliği tamamlanmalıdır.

---

### 2.4. Dış İletişim Kanalları — SMS ve E-Posta Entegrasyonları (`/notifications`)
* **Hizmet / Modül:** Bildirim ve Kimlik Doğrulama Servisleri (`services/notification`, `pkg/notify`, `/credentials`)
* **Test Edilen İşlem:** Yeni sakin (Mehmet Öztürk) eklendiğinde tek kullanımlık aktivasyon kodunun SMS ile iletilmesi ve acil site duyurularının gönderilmesi.
* **Alınan Test Sonucu:**
  * `GET /api/v1/notifications/summary` çıktısında sadece `providers: ['in_app', 'log']` sağlayıcıları aktiftir.
  * Yeni sakin eklendiğinde üretilen aktivasyon kodu (`SRMVPMUX`) sakinin telefonuna SMS olarak gidememektedir. Yöneticinin ekrandaki kodu manuel kopyalayıp sakine WhatsApp/telefonla iletmesi gerekmektedir.
* **Kök Neden:** Harici SMS sağlayıcısı (Netgsm, İletiMerkezi, Twilio vb.) ve SMTP e-posta sağlayıcı adaptörleri kod tabanına bağlanmamıştır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] `pkg/notify` altına Türkiye içi çalışan bir SMS sağlayıcı adaptörü (Netgsm veya İletiMerkezi) eklenmeli.
  - [ ] `NOTIFICATION_PROVIDER_SMS` ortam değişkeniyle gerçek SMS gönderimi ve SMS şablon motoru devreye alınmalı.
  - [ ] Standart SMTP (veya AWS SES / SendGrid) yapılandırması tamamlanarak e-posta bildirimleri aktif edilmeli.

---

### 2.5. Çevrimiçi Tahsilat ve Sanal POS Altyapısı (`/accounting`)
* **Hizmet / Modül:** Finans ve Tahsilat Modülü (`services/finance`)
* **Test Edilen İşlem:** Sakin mobil/web arayüzünden kredi kartıyla aidat veya gecikme zammı borcu ödeme.
* **Alınan Test Sonucu:**
  * Sistemde `payment_gateway_ready: false` dönmektedir.
  * Sakin ekranında kredi kartıyla ödeme butonu aktif değildir. Ödemeler yalnızca banka havalesi/EFT yapılıp yöneticinin panelden dekont onaylaması (`confirmPayment`) yoluyla işlenebilmektedir.
* **Kök Neden:** `backend/pkg/payment` altındaki Iyzico / ParamPOS entegrasyon parametreleri `services/finance` servisine bağlanmamış ve 3D Secure geri dönüş (callback) uç noktası yazılmamıştır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] Iyzico / ParamPOS sanal POS entegrasyonu tamamlanmalı.
  - [ ] Sakin paneline kart bilgisi girme ve 3D Secure onay akışı eklenmeli.
  - [ ] Ödeme başarılı olduğunda ilgili aidat borcunu otomatik kapatan webhook/callback ucu (`POST /payments/webhook`) yazılmalıdır.

---

### 2.6. PDF ve Excel Rapor Çıktısı Motoru (`/reports`)
* **Hizmet / Modül:** Raporlama ve Analiz Modülü (`/dashboard/reports`)
* **Test Edilen İşlem:** Mali bilanço, mizan dökümü, hazirun cetveli, işletme projesi veya noter onaylı karar defterini PDF / Excel olarak indirme.
* **Alınan Test Sonucu:**
  * Raporlar sayfasında dosya indirme butonları bulunmamakta; sayfada şu uyarı yer almaktadır:
    > *"PDF / Excel rapor üretimi henüz yok. Canlı veriler tarayıcı yazdırma özelliğiyle alınabilir."*
* **Kök Neden:** Go backend veya ön yüz tarafında PDF oluşturma motoru (Gotenberg, wkhtmltopdf veya Go `go-pdf` kütüphanesi) ile Excel çıktı motoru (`excelize`) kurulmamıştır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] `services/finance` ve `services/governance` servislerine `.xlsx` formatında mizan, borçlu listesi ve hazirun dökümü veren uçlar eklenmeli (`excelize` paketi ile).
  - [ ] Genel Kurul Karar Defteri ve Denetim Raporu için resmi formatta, SHA-256 doğrulama kodunu içeren mühürlü PDF üretim servisi kurulmalı.

---

### 2.7. İşletme Projesi (Bütçe) Kesinleştirme Süre Kısıtı (`/governance/budgets`)
* **Hizmet / Modül:** Yönetişim ve Bütçe Modülü (`services/governance`)
* **Test Edilen İşlem:** Tebliğ edilen işletme projesinin kesinleştirilmesi (`POST /governance/budgets/:id/finalize`).
* **Alınan Test Sonucu:**
  ```json
  HTTP 409 Conflict
  {
    "error": "İtiraz süresi dolmadan proje kesinleşemez (KMK m.37/2)"
  }
  ```
* **Kök Neden:** Kat Mülkiyeti Kanunu m.37/2 uyarınca tebliğden itibaren 7 günlük itiraz süresi dolmadan bütçe kesinleştirilemez. Bu hukuki mantık doğrudur; ancak yerel test/geliştirme ortamında tebligat tarihi ileri alınamadığı veya bir simülasyon bayrağı bulunmadığı için bütçenin kesinleşme ve otomatik aidat tahakkukuna dönüşme yaşam döngüsü test edilememektedir.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] **Hukuki İstisna:** KMK m.37/1 uyarınca Genel Kurul'da doğrudan kabul edilen işletme projelerinde 7 günlük itiraz süresi beklenmez, derhal kesinleşir. Bu nedenle bütçe oluşturulurken `source: "GENERAL_ASSEMBLY"` seçilmişse 7 günlük bekleme şartı aranmamalıdır.
  - [ ] **Test Simülasyonu:** Test ortamı (`NODE_ENV=development` veya `TEST_MODE=true`) için tebligat tarihini geriye çekebilme veya süreyi atlama parametresi eklenmelidir.

---

### 2.8. Ziyaretçi Giriş Doğrulama ve Geçiş Kodu Üretimi (`/visitors`)
* **Hizmet / Modül:** Ziyaretçi Yönetimi (`services/visitor`)
* **Test Edilen İşlem:** Beklenen ziyaretçi için güvenlik noktasında hızlı doğrulama yapılması.
* **Alınan Test Sonucu:**
  * Ziyaretçi kaydı `EXPECTED` olarak açılıyor ve arayüzden manuel `check-in` yapılabiliyor; ancak ziyaretçiye SMS veya telefonla iletilebilecek tek kullanımlık bir QR kod ya da PIN kodu üretilmemektedir.
* **Kök Neden:** Ziyaretçi modülünde tek kullanımlık geçiş jetonu (`pass_token` / TOTP) üreteci ve güvenlik doğrulama ucu bulunmamaktadır.
* **Yazılımcıya Verilecek İş (İş Emri):**
  - [ ] Ziyaretçi kaydı oluşturulduğunda 6 haneli bir PIN ve dinamik QR kod üretilmeli.
  - [ ] Güvenlik görevlisi ekranına PIN veya QR okutulduğunda tek tuşla daire sakinine teyit bildirimi düşüren hızlı geçiş ucu (`POST /visitors/verify-pass`) eklenmelidir.

---

## 3. Başarıyla Geçen ve Doğrulanan Hizmetler Tablosu

| # | Hizmet / Modül | Test Edilen İşlem | Doğrulanan Durum ve Çapraz Etki | Kanıt Seviyesi |
|---|---|---|---|:---:|
| 1 | **Kimlik & Oturum** | `/login`, `/users/me/password` | Başarılı giriş, JWT, şifre değişimi, eski jetonun anında geçersiz kılınması (401). | `[D4]` |
| 2 | **Sakinler** | Sakin ekleme & Aktivasyon | Sakin oluşturuldu, tek kullanımlık kodla şifre belirledi (`/auth/activate`), daireye bağlandı. | `[D4]` |
| 3 | **Bağımsız Bölümler** | Daire ekleme (`/units`) | Yeni bağımsız bölüm eklendi (B-15), toplam bağımsız bölüm sayısı 24'ten 25'e yükseldi. | `[D4]` |
| 4 | **Roller & Görevler** | Denetçi rolü atama & bitirme | `AUDITOR` rolü atandı, tarih formatı (`YYYY-MM-DD`) denetlendi, rol kapatıldı. | `[D4]` |
| 5 | **Talepler & Arızalar** | Talep açma, çözme, onaylama | Sakin arıza talebi açtı (`TLP-FECA521F`), yönetici çözdü, sakin memnuniyet onayı verdi. | `[D4]` |
| 6 | **Duyurular** | Sabitlenmiş duyuru & anlık push | Duyuru yayınlandı, sitedeki tüm aktif sakinlere anında bildirim gitti (`recipients: 3`). | `[D4]` |
| 7 | **İlan Panosu** | İlan verme, onaylama, kapatma | Sakin ilan verdi (`PENDING`), yönetici onayladı (`APPROVED`), yayından kaldırdı (`CLOSED`). | `[D4]` |
| 8 | **Anketler & Oylama** | Anket açma, oylama, yasal uyarı | Anket yayınlandı, oy kullanıldı, KMK m.29-32 yasal çekincesi sonuçlarda korundu. | `[D4]` |
| 9 | **Aidat Tahakkuku** | Eşit gider dağıtımı (`EQUAL`) | 25.000 TL gider 25 daireye tam 1.000'er TL olarak tahakkuk ettirildi. Borçlu listesi güncellendi. | `[D4]` |
| 10 | **Gecikme Tazminatı** | KMK m.20/2 yasal faiz hesabı | Vadesi geçen 26 borca aylık %5 üzerinden 806.25 TL gecikme tazminatı işletildi. | `[D4]` |
| 11 | **Gider Yönetimi** | Arsa payı dağıtımı (`SHARE_RATIO`) | 4.500 TL asansör bakım gideri zemin katlar hariç arsa payına göre bölüştürüldü. | `[D4]` |
| 12 | **Sayaç Okuma** | Isı sayaç tüketim girişi | Önceki endeksten küçük değer girilemedi (`422`), doğru tüketim kaydedildi. | `[D4]` |
| 13 | **Tahsilat Riski** | 4 bileşenli risk skorlaması | 25 dairenin borç ödeme riski kural motoruyla hesaplandı ve anlık görüntüsü saklandı. | `[D4]` |
| 14 | **Genel Kurul Toplantısı**| Çağrı, nisap ve tutanak | Toplantı açıldı, nisap yetersizliğinde otomatik ret ve Karar Defteri'ne yazım sağlandı. | `[D4]` |
| 15 | **Karar Defteri** | Blokzincir tipi kriptografik defter | Kararlar SHA-256 zinciriyle yazıldı, `/verify` ile defter bütünlüğü doğrulandı (`valid: true`). | `[D4]` |
| 16 | **İcra & Hukuk** | İlamlı/İlamsız icra takibi | İcra dosyası açıldı; anapara ve gecikme faizi borçtan bağlandı, İİK m.68 uyarısı verildi. | `[D4]` |
| 17 | **Sözleşmeler** | Otomatik yenilenen bakım sözleşmesi| 12 aylık bakım sözleşmesi kaydedildi, yenileme ve ihbar süreleri bağlandı. | `[D4]` |
| 18 | **Belge Arşivi** | Upload, Download, Log, Archive | Gerçek dosya yüklendi (SHA-256 özeti), indirildi, KVKK erişim günlüğü tutuldu, arşivlendi. | `[D4]` |
| 19 | **Ziyaretçi Yönetimi** | Check-In, Check-Out & Bildirim | Ziyaretçi geldiğinde daire sakinine anında uygulama içi bildirim gitti; çıkış yapıldı. | `[D4]` |
| 20 | **Kargo Takibi** | Kargo kabul, bildirim, iade | Kargo geldiğinde sakine bildirim gitti; bulunamayan kargo firmaya iade edildi (`RETURNED`). | `[D4]` |
| 21 | **Otopark & Plaka** | Sakin araç kaydı, 0 TL muafiyet | Sakin aracı kaydedildi; giriş-çıkışta sakin olduğu için otomatik 0 TL ücret uygulandı. | `[D4]` |
| 22 | **Devriye Kontrolü** | Güvenlik devriye kontrol noktası | Yangın merdiveni için barkodlu kontrol noktası oluşturuldu. | `[D4]` |
| 23 | **Personel & İzin** | TCKN algoritması & PII maskeleme | Hatalı TCKN reddedildi, geçerli TCKN maskelendi (`123*****50`), izin onaylandı. | `[D4]` |
| 24 | **Demirbaş Yönetimi** | Demirbaş kaydı ve hurdaya ayırma | Asansör motoru kaydedildi; ömrü bittiğinde silinmeyip `DISPOSED` statüsüne alındı. | `[D4]` |
| 25 | **Stok & Sarf Malzeme** | İrsaliyeli depo giriş / çıkış | Açılış stoğu kuralı doğrulandı, depoya 3 adet kimyasal girişi ve 2 adet çıkışı yapıldı. | `[D4]` |
| 26 | **KVKK Başvuruları** | Veri sahibi talebi ve yanıtlama | Sakin kişisel veri dökümü talep etti; yönetici yasal 30 günlük süre içinde yanıtladı. | `[D4]` |
| 27 | **Site Ayarları** | Mevzuat parametresi koruması | KMK m.20/2 faiz oranını ezme denemesi engellendi (`422`); izinli ayarlar güncellendi. | `[D4]` |

---

## 4. Geliştirme Ekibi İçin Öncelik Sıralaması

1. **Öncelik 1 (Kritik - Hizmet Alınamıyor):**
   - **Tesisler & Rezervasyon:** `POST /facilities` ucu, seed verileri ve arayüz modalı yapılmalı.
   - **Isı Payı Tüketim Dağıtımı:** Daire ekleme/düzenlemede m² zorunlu tutulmalı; eksik alanlar tamamlanmalı.
   - **SMS Entegrasyonu:** Sakin aktivasyon kodları ve acil duyurular için SMS adaptörü bağlanmalı.
   - **Web Mobil Hamburger Menüsü:** Üst çubuktaki menü butonuna (`lg:hidden`) mobil drawer açma işlevi bağlanmalı.
2. **Öncelik 2 (Önemli - Finans ve Raporlama):**
   - **Sanal POS (Online Tahsilat):** Iyzico entegrasyonu ve 3D Secure akışı tamamlanmalı.
   - **PDF/Excel Rapor Motoru:** Resmi mizan, bütçe ve karar defteri dökümleri için motor eklenmeli.
   - **Mobil iOS Desteği:** Her iki Flutter uygulamasına `ios/` desteği ve Podfile tanımlanmalı.
3. **Öncelik 3 (Tamamlayıcı - Operasyonel Mükemmellik):**
   - **Kargo İmzası/Fotoğrafı:** Belge servisi entegrasyonuyla teslimat ispatı tamamlanmalı.
   - **Ziyaretçi QR/PIN Kodu:** Hızlı geçiş jetonu ve güvenlik doğrulama ekranı yapılmalı.
   - **Bütçe Kesinleştirme İstisnası:** Genel kurul kaynaklı bütçeler için derhal kesinleştirme kuralı işletilmeli.

---

## 5. Mobil Uygulamalar (Sakin ve Yönetici) Raporu

Projede tek bir mobil uygulama değil, kullanıcı rollerine göre ayrılmış **2 ayrı Flutter mobil uygulaması** mevcuttur:

1. **`mobile/` (`siteeksen_mobile`)**: Site Sakinleri için Flutter Mobil Uygulaması.
2. **`admin_app/` (`siteeksen_admin`)**: Site Yöneticileri, Yönetim Kurulu, Denetçiler ve Görevliler için Flutter Mobil Uygulaması.

### 5.1. Yönetici ve Sakin Ayrımı (RBAC Güvenlik Mimarisi)
* **Aynı uygulamayı mı kullanıyorlar?** Hayır, farklı uygulamaları kullanmaktadırlar.
* **Güvenlik Duvarı:** `admin_app` içerisinde `hasAdminAppAccess` kontrolü fail-closed mantığıyla çalışmaktadır. Sakin (`RESIDENT`), kiracı (`TENANT`) veya malik (`OWNER`) rolündeki hesaplar yönetici uygulamasına giriş yapsalar dahi hiçbir yönetim menüsüne erişemezler.
* **Rol Kısıtlamaları:** Yönetici uygulamasında bir Denetçi (`AUDITOR`) girdiğinde harcama veya sakin ekleme yetkileri gizlenir, yalnızca denetim ve inceleme modülleri açılır.

### 5.2. Mobil Birim & Entegrasyon Test Sonuçları
Flutter SDK WSL (Ubuntu 24.04) üzerinde `/home/md064615/flutter/bin/flutter` (Flutter 3.47.4 / Dart 3.13.3) ile çalıştırılmış ve projenin resmi `backend/scripts/verify-mobile.sh` doğrulama motoruyla test edilmiştir.

```text
=== 0) Araç sürümü ===
  Flutter 3.47.4 • channel stable

=== mobile (Sakin Uygulaması) ===
  [GEÇTİ]    mobile: flutter pub get
  [GEÇTİ]    mobile: flutter analyze (0 hata, 0 uyarı, 0 bilgi - tertemiz)
  [GEÇTİ]    mobile: flutter test (+27 test başarıyla geçti)

=== admin_app (Yönetici Uygulaması) ===
  [GEÇTİ]    admin_app: flutter pub get
  [GEÇTİ]    admin_app: flutter analyze (0 hata, 0 uyarı, 0 bilgi - tertemiz)
  [GEÇTİ]    admin_app: flutter test (+27 test başarıyla geçti)

=== Dürüstlük Kontrolü ===
  [GEÇTİ]    Ağ çağrısı yapmayan sahte 'Ödeme Başarılı' mesajı yok
  [GEÇTİ]    Arayüze sabit gömülmüş sahte kullanıcı adı yok

=== Yayın Derlemesi (Ağ İzni) ===
  [GEÇTİ]    mobile: release manifestinde INTERNET izni var
  [GEÇTİ]    admin_app: release manifestinde INTERNET izni var

=== SONUÇ: 10 / 10 KONTROL GEÇTİ ===
```

### 5.3. Mobil Modül Envanteri ve Eksiklik Analizi

#### A) Sakin Mobil Uygulaması (`mobile/`)
* **Var Olan Modüller (13 Modül / 18 Ekran):**
  - Kimlik: Giriş, Aktivasyon koduyla şifre belirleme, Zorunlu KVKK açık rıza, Biyometrik (FaceID/Parmak izi) giriş.
  - Ana Sayfa: Daire borç özeti, acil bildirimler, duyurular.
  - Finans: Aidat borç listesi, gecikme faizi, havale/EFT dekont bildirme.
  - Talepler: Arıza bildirimi açma ve **yöneticinin çözdüğü arızaya sakin onay/ret verme akışı**.
  - İlan Panosu, Anketler, Kargo Takibi, Tesis Rezervasyonu & İptal, Ziyaretçi Ön Kaydı, Sayaç Tüketim Grafikleri, Belgeler ve KVKK Başvuruları.
* **Eksikler & Yapılacaklar:**
  - ❌ **Sanal POS ile Kartlı Tahsilat:** Kredi kartıyla doğrudan aidat ödeme uçları backend'de bağlı değil.
  - ❌ **Ziyaretçi Geçiş QR / SMS Linki:** Ön kayıt açıldığında misafire iletilecek dinamik link/QR üretilmiyor.
  - ❌ **iOS Klasörü (`ios/`):** Yalnızca `android/` klasörü mevcut, iPhone/App Store derlemesi alınamıyor.

#### B) Yönetici Mobil Uygulaması (`admin_app/`)
* **Var Olan Modüller (20 Modül / 27 Ekran):**
  - Yönetim Özeti (Dashboard): Site metrikleri ve bekleyen işler.
  - Sakinler: Sakin listeleme, arama, filtreleme, yeni sakin ekleme, aktivasyon kodu üretme, pasife alma.
  - Finans & Muhasebe: Aidat tahakkuku çıkarma (Eşit, Arsa Payı, Alan m²), onay bekleyen havale/EFT ödemelerini onaylama/reddetme, borçlu listesi.
  - Giderler: Fatura işleme, tedarikçi bağlama, arsa payı dağıtımı, yönetim onayı/reddi.
  - Talep Yönetimi: Arıza durumunu güncelleme (`IN_PROGRESS`, `RESOLVED`).
  - Saha Operasyonları: Ziyaretçi check-in/out, kargo kabul/teslim/iade, otopark plaka sorgu, devriye barkod okuma, stok depo giriş/çıkış, demirbaş hurdaya ayırma, personel izin onayı, duyuru sabitleme, sayaç endeks okuma, anket açma/kapatma, ilan onay/ret akışı.
  - Yönetişim: İşletme projesi ve noter onaylı Karar Defteri bütünlüğünü mobilden salt-okunur doğrulama.
* **Eksikler & Yapılacaklar:**
  - ❌ **Kargo Teslim İmzası:** Güvenlik görevlisinin sakine teslim ederken dokunmatik imza/fotoğraf alması eksik.
  - ❌ **Rapor İndirme Motoru:** PDF/Excel döküm motoru bağlı değil.
  - ❌ **iOS Klasörü (`ios/`):** `admin_app/ios` klasörü bulunmamaktadır.

---

## 6. Samsung Galaxy A55 Web Responsive Test Raporu

**Hedef Cihaz:** Samsung Galaxy A55 5G  
**Ekran Çözünürlüğü:** 1080 x 2340 piksel, 19.5:9 oran  
**CSS Viewport Boyutu:** **412 x 915 piksel**  
**Test Edilen Ön Yüz:** `http://localhost:3001` (Next.js 14)  
**Test Yöntemi:** `browser_subagent` tarayıcı motoru üzerinden 412x915 çözünürlükte adım adım sayfa denetimi ve ekran yakalama.

### 6.1. Ekran Bazlı Responsive Doğrulama Sonuçları

| Sayfa / Bileşen | Galaxy A55 (412x915) Davranışı | Yatay Taşma (Overflow) | Durum |
|---|---|:---:|:---:|
| **Dashboard (`/dashboard`)** | 4'lü metrik kartları tek sütunda dikey dizilmektedir. Grafikler ve son talepler kartı ekrana tam oturmaktadır. | ❌ Yok (`scrollWidth === 412`) | ✅ Başarılı |
| **Sakinler (`/dashboard/residents`)** | Filtre ve arama çubuğu tam genişlikte yerleşmektedir. Tablo `overflow-x-auto` içinde yatay kaydırılabilmektedir. | ❌ Yok (Kendi içinde kayar) | ✅ Başarılı |
| **Sakin Ekle Modalı** | 412px genişlikte modal ekran sınırları içinde kalmakta; Ad, Soyad, Telefon, Daire ve Rol seçim alanları bozulmadan doldurulabilmektedir. | ❌ Yok | ✅ Başarılı |
| **Finans & Muhasebe (`/dashboard/accounting`)** | Toplam tahsilat, borçlu sayısı ve gecikme zammı kartları düzgün istiflenmekte; borçlu tablosu rahatça kaydırılabilmektedir. | ❌ Yok | ✅ Başarılı |
| **Talepler (`/dashboard/requests`)** | Talep kartları ve durum rozetleri (`OPEN`, `IN_PROGRESS`, `RESOLVED`) alt alta düzgün yerleşmekte, metinler kırpılmamaktadır. | ❌ Yok | ✅ Başarılı |
| **İlan Panosu (`/dashboard/bulletins`)** | İlan kartları tek sütun grid olarak dikey dizilmekte; onay/ret butonları parmakla kolayca basılabilecek boyuttadır. | ❌ Yok | ✅ Başarılı |
| **Ayarlar (`/dashboard/settings`)** | Ayar başlıkları, açıklama metinleri ve durum rozetleri düzenli listelenmektedir. | ❌ Yok | ✅ Başarılı |

### 6.2. Tespit Edilen Kritik Arayüz Hatası (UI Bug)

> [!WARNING]
> **Üst Çubuk Hamburger Menü Butonunun İşlevsiz Olması (Critical Mobile Nav Bug):**  
> * **Bileşen:** `admin/src/components/Header.tsx` (veya `DashboardLayout.tsx`) içindeki `button.lg:hidden` (Hamburger Menü Butonu).  
> * **Hata:** Ekran genişliği `< 1024px` olduğunda masaüstü sol kenar çubuğu (Sidebar) otomatik olarak gizlenmektedir (`hidden lg:flex`). Ancak üst çubuktaki mobil menü butonuna tıklandığında hiçbir yan menü (Drawer) açılmamaktadır.  
> * **Kök Neden:** Buton arayüzde görsel olarak mevcuttur ancak React tarafında açılır çekmeceyi tetikleyecek bir `onClick` olay dinleyicisi veya `MobileSidebar` modalı bağlanmamıştır.  
> * **Çözüm Talimatı:** Mobil görünümde hamburger butonuna tıklandığında sol taraftan açılan bir Drawer (çekmece menü) bileşeni ve `isOpen` state'i eklenmelidir.
