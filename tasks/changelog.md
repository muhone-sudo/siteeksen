# CHANGELOG

Projedeki tüm önemli değişiklikler bu dosyada takip edilir.

> **Not (2026-09-09):** Bu dosya tek doğruluk kaynağıdır; kökteki `CHANGELOG.md` yalnızca buraya işaret eder.
> Aşağıdaki **2026-09-09 öncesi** girdiler, 2026-09-09 denetiminde iddialarının önemli bölümü yanlış
> çıktığı için **güvenilmez** kabul edilmelidir (ayrıntı: `tasks/audit-raporu.md`). Girdiler tarihsel kayıt
> olarak korunmuştur ama "tamamlandı" ifadeleri kanıtlanmamıştır.
> Bundan sonraki her girdi `tasks/dogrulama-politikasi.md` uyarınca **kanıt satırı** taşır.

---

## [Unreleased]

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
