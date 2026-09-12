# Denetim Raporu — "Yapıldı" İddiaları vs Gerçek Durum

**Tarih:** 2026-09-08 / 09
**Kapsam:** Tüm repo — 25 Go servisi, gateway, 61 tablo / 10 migration, Next.js admin paneli, 2 Flutter uygulaması, Kong, k8s, CI/CD, OpenAPI, hukuki metinler.
**Yöntem:** Statik kod denetimi. Her bulgu `dosya:satır` kanıtına bağlı.
**Ayrıntılı kanıt dosyaları:** `tasks/audit/` (5 dosya, ~370 KB)

## Bu denetim neden yapıldı

Kullanıcı tespiti: *"Yapıldığı iddia edilen ve işaretlenen işler yapılmamış çıkıyor."*
Denetim bu tespiti doğruladı ve **ölçtü**.

## Doğrulama kısıtı (dürüstlük notu)

Bu makinede **Go, Flutter, Docker ve psql kurulu değil**; kurumsal AppLocker politikası kullanıcı yazılabilir
dizinlerden çalıştırılabilir dosya açılmasını engelliyor (portable Go denemesi "Access is denied" ile başarısız oldu).
Bu nedenle:

- Backend ve mobil iddiaları **statik** olarak denetlendi — `go build`, `go test`, `flutter analyze` çalıştırılamadı.
- **Fiilen çalıştırılarak doğrulanan tek şeyler:** (1) admin panelinin `npm install` + `npm run build` ile
  gerçekten derlendiği (21 sayfa, çıkış kodu 0); (2) demo kullanıcı bcrypt hash'inin hiçbir aday şifreyle
  eşleşmediği (`bcryptjs` ile fiilen test edildi).
- Geçmiş oturumlardaki "canlı doğrulandı" ifadelerinin bu repoda **hiçbir kanıtı yok**; başka bir makinede
  yapılmış olabilir ama tekrar üretilebilir değil.

---

# 1. ÖZET: Sayılarla durum

| Alan | İddia | Gerçek |
|---|---|---|
| Backend servisi | 25 servis "✅ yazıldı" | **3'ü** gerçek veritabanına bağlı (identity, finance, community). **22'si** sabit JSON döndürüyor, yazma işlemlerini hiçbir yere kaydetmiyor |
| Repo derlemesi | — | **`go build ./...` başarısız** (kırık import: `backend/api/handlers/api_credentials_handler.go:8`) |
| Veritabanı kurulumu | "PostgreSQL + migrations ✅ 5 migration tamamlandı" | **10 migration var ve temiz bir veritabanında KURULAMIYOR** — 004 ve 005 çöküyor (bkz. §3.1) |
| Denetim izi (audit log) | "gerçek `INSERT INTO audit_logs` ile tamamlandı ✅" | **INSERT her seferinde hata veriyor** (kolon adları şemada yok), hata yutuluyor → tablo kalıcı olarak **boş** |
| Demo giriş | `5551234567 / demo123` | **Hiçbir şifreyle giriş yapılamıyor** — seed'deki bcrypt hash bozuk (fiilen test edildi) |
| Kimlik doğrulama | JWT 15dk/7gün ✅ | Süreler doğru, ama **gateway'de ve Kong'da auth yok**; 22 servis tamamen açık (maaş, IBAN, TCKN, API anahtarları dahil) |
| Multi-tenant | "her istek `X-Tenant-ID` taşımalı" | `pkg/tenant` **hiçbir yere bağlı değil** (294 satır ölü kod); izolasyonun tek dayanağı olan `property_id` **istemci tarafından değiştirilebiliyor** |
| Soft-delete | "23 tabloya `deleted` + identity/finance filtreleri ✅" | 21 tablo; **hiçbir yerde `SET deleted = 1` yazan kod yok** → özellik tamamen işlevsiz; 11 sorguda filtre eksik |
| Admin panel | Neredeyse tüm sayfalar "✅ gerçek API'ye bağlandı" | 16 sayfanın **6'sı** API'ye hiç dokunmuyor, **8'i** hata alınca sessizce uydurma veri gösteriyor; yazma işlemi gerçekten backend'e giden **3** sayfa |
| Sakin mobil | 13 ekran "✅" | **8 ekran** hiç ağ çağrısı içermiyor; **12/18 route** kullanıcı arayüzünden ulaşılamıyor; **release APK'da INTERNET izni yok** (release build hiç çalışmaz); `ios/` klasörü yok |
| Yönetici mobil | 24 ekran "✅" | **16 modül** hiç ağ kodu içermiyor; **17 ekran** menüden erişilemiyor; `api_client` taban adresi yanlış (`/v1` ≠ `/api/v1`) → üretimde her çağrı 404 |
| Ödeme (iyzico) | "✅ sandbox bağlantısı kurulu" | **Hiç ödeme entegrasyonu yok.** `pkg/payment` ölü kod; mobilde ödeme ekranı hiçbir ağ çağrısı yapmadan "Ödeme Başarılı!" gösteriyor |
| Firebase push | "✅" | **Hiç yok.** Mobilde tek satır Firebase kodu yok; `google-services.json` yok; backend `log.Printf` yapıyor |
| Kafka | "notification servisi tüketiyor" | **Kafka kütüphanesi `go.mod`'da bile yok**; hiçbir consumer yok |
| MongoDB | "iot ✅ MongoDB bağlı" | **MongoDB sürücüsü `go.mod`'da yok**; iot servisi tamamen sabit JSON |
| AI fatura tarama | "✅ OpenAI Vision" | Sabit "AYEDAŞ 2.450,75 TL" yanıtı. Gerçek OpenAI kodu var ama **ölü**; `OPENAI_API_KEY` hiçbir yerde tanımlı değil |
| Banka entegrasyonu | "✅ `turkish_banks.go`" | Dosya yolu bile yanlış; **hiç import edilmiyor**; 5 bankanın 4'ü boş stub; Ziraat yanıtı `_ = body` ile atıyor |
| SMS / WhatsApp | "✅ hazır" | Kod **gerçek ve iyi yazılmış** ama hiçbir yere bağlı değil (ölü) |
| Raporlama | "Faz 5 ✅ gerçek PDF/Excel" | PDF/Excel motoru **gerçek**; ama rapor içeriği **hardcoded** ("Ahmet Yılmaz", "Temmuz 2026") — hangi siteyi/dönemi isterseniz aynı sahte rapor |
| Dashboard istatistikleri | "Faz 3 ✅ aggregator tamamlandı" | Kod yazılmış ama **yanıt zarfı uyuşmazlığı yüzünden hiç çalışmıyor** → her koşulda sabit 156/180/12/3/2 |
| Sayaç yönetimi | "Faz 4 ✅ iot-service DB şemasına bağlandı" | Tamamen mock; `submitReading` sabit `12.5` döndürüyor; `meters`/`meter_readings` tablolarına hiç dokunulmuyor |
| Birim testleri | "pkg/reports testleri yazıldı ve doğrulandı ✅" | 4 test dosyasının **3'ü kendi içinde tanımladığı sahte fonksiyonları** test ediyor; üretim kodunu çalıştıran tek dosya `pkg/reports/reports_test.go` (o da yalnızca "byte dizisi boş değil" kontrolü) → gerçek kapsam ~**%0,5** |
| CI/CD | "✅" | **İlk adımda çöküyor** (`go-version: 1.21` ⟷ `go.mod: 1.24`); lint/test adımları `\|\| true` ile hata yutuyor; Trivy `exit-code` verilmediği için kapı işlevi görmüyor; var olmayan Deployment'lara `rollout restart` |
| Kubernetes | "✅ manifests" | 25 servisin **2'si** + admin panel; **ingress yolu yanlış** (`/v1/...` ≠ `/api/v1/...`) → üretimde tüm istekler 404 |
| Kong | "24 servis, tüm servisler için CORS ve rate-limiting ✅" | 24 servis + CORS doğru; **rate-limiting yalnızca 6/24**; **JWT plugin'i 0**; banking ve gateway Kong'da yok |
| OpenAPI | — | İlk commit'ten kalma; 14 path; sonradan eklenen **hiçbir** endpoint yok; 2 dokümante endpoint kodda yok |
| Ölü şema | — | 61 tablonun **47'si (%77)** hiçbir kod tarafından kullanılmıyor; `005_new_modules.sql`'in 45 KB'ının tamamı ölü |
| Ölü kod | — | ~**3.900 satır** bağlanmamış Go paketi (`pkg/tenant`, `pkg/encryption`, `pkg/payment`, `pkg/notification`, `pkg/ai`, `pkg/integrations/*`, `banking/provider`) |

## İddia doğrulama skoru

| Alan | Denetlenen iddia | YANLIŞ | KISMEN | DOĞRU |
|---|---|---|---|---|
| Backend servisleri | 31 | 14 | 6 | 11 |
| Veri katmanı / altyapı | 13 | 7 | 4 | 2 |
| Admin panel | 10 | 6 | 3 | 1 |
| Yönetici mobil | 13 | 6 | 5 | 2 |
| Sakin mobil | 11 | 5 | 4 | 2 |
| **TOPLAM** | **78** | **38** | **22** | **18** |

**Dokümanlardaki iddiaların %49'u yanlış, %28'i kısmen doğru, yalnızca %23'ü doğru.**

---

# 2. Kök nedenler (asıl çözülmesi gereken)

Tek tek hataları düzeltmek yetmez; bu tabloyu üreten **5 sistemik neden** var:

### KN-1 · "Tamamlandı" için kanıt zorunluluğu yok
`✅` işareti, "dosya yazıldı" anlamında kullanılmış. Hiçbir satırda "nasıl doğrulandı" bilgisi yok.
Sonuç: derlenmeyen kod, çalışmayan sorgu, boş kalan tablo hep "tamamlandı" görünüyor.
→ Çözüm: `tasks/dogrulama-politikasi.md` (kanıt seviyeleri D0–D4) + roadmap'te zorunlu **Kanıt** kolonu.

### KN-2 · Hataların sessizce yutulması
Sistem, hata durumunda **yalan söyleyecek** şekilde yazılmış:
- `_ = audit.LogAction(...)` → denetim izi hiç yazılmıyor, kimse fark etmiyor (`pkg/middleware/auth.go:115`)
- `r.pool.Exec(...)` dönüşü atılıyor → ödeme-tahakkuk bağlantısı sessizce kaybolabiliyor (`finance/repository/finance.go:220`)
- Admin panelde 9 noktada `catch { mock göster }` → sunucu çökse bile kullanıcı uydurma rakam görüyor
- Mobilde her `catch` boş listeye düşüyor → kullanıcı "veri yok" sanıyor, sunucunun çöktüğünü hiç anlamıyor
- 22 serviste yazma işlemi `201 Created` dönüyor ama hiçbir yere kaydetmiyor
→ Çözüm: sessiz fallback yasağı; kaydetmeyen uç nokta `501` dönmeli; hata kullanıcıya görünmeli.

### KN-3 · Kurulumun tekrar üretilebilir olmaması
Temiz bir makinede `docker compose up` **çalışmıyor** (§3.1). Bugün çalışan ortam, elle yapılmış
müdahalelerin toplamı (CHANGELOG'un kendisi migration'ların üç kez elle uygulandığını yazıyor) ve
**kaybolursa geri getirilemez**. Migration sürüm takibi yok.
→ Çözüm: migration çakışmalarını gider + migration çalıştırıcı ekle + `down -v && up` ile uçtan uca doğrula.

### KN-4 · Tek doğruluk kaynağının olmaması
- `ROADMAP.md` **kendi içinde** çelişiyor (satır 51 "hepsi compose'a eklendi" ⟷ 24-43 "eklenmedi"; satır 52 "Kong 24 servis" ⟷ 183 "Kong'a eklenmeli")
- `ROADMAP.md` ile `tasks/todo.md` çelişiyor (iyzico ✅ ⟷ ertelendi; WhatsApp ✅ ⟷ ertelendi)
- Kök `ROADMAP.md` = `tasks/roadmap.md` (ikiz kopya), kök `CHANGELOG.md` = `tasks/changelog.md`
- Aynı entegrasyon 2-3 kez yazılmış (iyzico ×2, FCM ×2, OpenAI ×2, banka listesi ×2, karbon hesabı ×2 — **farklı sonuçlarla**)
- İki giriş kapısı (Kong 8000 / gateway 8888) farklı route kümeleriyle; `NEXT_PUBLIC_API_URL` 3 farklı değerde
→ Çözüm: tek kaynak ilkesi; ikiz dosyaları işaretçiye çevir; yinelenen paketleri sil.

### KN-5 · Genişliğin derinliğe tercih edilmesi
25 servis, 61 tablo, 37 ekran açıldı; hiçbiri uçtan uca bitmedi. Şema modüller için yazıldı ama kod bağlanmadı
(%77 ölü şema). Arayüzler "dolu" göründüğü için ilerleme hissi oluştu, oysa veri kalıcı değil.
→ Çözüm: dikey dilim disiplini — bir modül şema→servis→API→panel→mobil→test hattının tamamında bitmeden yenisi açılmaz.

---

# 3. Kritik bulgular (öncelik sırasıyla)

Aşağıdakiler "hata" değil, **ürünü kullanılamaz ya da güvensiz kılan** maddelerdir.

## 3.1 🔴 Veritabanı sıfırdan kurulamıyor
İki migration temiz bir veritabanında hata verip **tüm kurulumu durduruyor** (postgres entrypoint
`ON_ERROR_STOP=1` ile çalışır):

1. **`004_expense_management.sql`** — `expense_categories` tablosu `001`'de zaten farklı kolonlarla var.
   `CREATE TABLE IF NOT EXISTS` sessizce atlanıyor, ardından satır 19-30'daki `INSERT` `001`'de bulunmayan
   `description`/`type`/`reflects_to_assessment` kolonlarına yazmaya çalışıyor →
   `column "description" does not exist`. → `expenses`, `expense_invoices`, `expense_distributions` **hiç oluşmuyor**.
2. **`005_new_modules.sql`** — `vehicles` tablosu `001`'de `property_id`/`plate` kolonları **olmadan** var.
   Satır 102'deki `CREATE UNIQUE INDEX ... ON vehicles(property_id, plate)` hata veriyor →
   satır 107'den sonraki **29 tablonun hiçbiri oluşmuyor** (parking, facilities, reservations, bank_accounts,
   surveys, packages, assets, contracts, employees, payroll, inventory, meetings...).
3. Zincir etkisi: `006_soft_delete.sql:18` var olmayan `reservations` tablosunu `ALTER` etmeye çalışıp çöküyor.

**Sonuç:** CHANGELOG'daki "migration'ları üç kez elle uygulamak zorunda kaldım" gözleminin kök nedeni
migration çalıştırıcı eksikliği **değil**, çakışan şema. Her ikisi de düzeltilmeli.

## 3.2 🔴 Denetim izi (audit log) hiç çalışmıyor — KVKK riski
`pkg/audit/audit.go:28` şu kolonlara yazıyor: `user_ip`, `resource_type`, `resource_id`.
Geçerli şema (`003_multi_tenant.sql:63-76`, ki `001`'deki tabloyu **DROP edip** yeniden yaratıyor) ise
`ip_address`, `entity_type`, `entity_id` ve **`tenant_id NOT NULL`** kullanıyor.
→ INSERT **her çağrıda** `42703 undefined_column` veriyor; hata `pkg/middleware/auth.go:115`'te
`_ = audit.LogAction(...)` ile yutuluyor → `audit_logs` tablosu **kalıcı olarak boş**.

Bu, `legal/kvkk-aydinlatma.md`'de "log tutuyoruz, 2 yıl saklıyoruz" taahhüdüyle **doğrudan çelişiyor**.

## 3.3 🔴 Kimlik doğrulama yok — hassas veriler internete açık
- Gateway'de auth middleware yok (`cmd/gateway/main.go:422`), Kong'da JWT plugin'i **0**.
- 22 servisin hiçbirinde `AuthMiddleware` yok.
- CORS `Access-Control-Allow-Origin: *` ve `Authorization` başlığı her yerde açık.

**Token olmadan erişilebilen uçlar:** `/api/v1/employees` + `/payroll` (maaş, TCKN),
`/api/v1/credentials` (**API anahtarları — yazma ve silme dahil**), `/api/v1/bank-accounts` (IBAN),
`/api/v1/visitors` (TCKN), `/api/v1/announcements` (POST/PUT/DELETE), `/api/v1/reports/generate`,
`/api/v1/sensors/:id/data` (kimliksiz veri yutma), `/api/v1/plate-recognition` (sabit `ALLOW` — bariyere
bağlanırsa her araca geçiş izni verir).

## 3.4 🔴 Multi-tenant izolasyonu kırılabilir
`POST /users/me/active-property` sahiplik doğrulaması yapmıyor
(`identity/repository/user.go:87-91` — sorguda `resident_units` kontrolü yok).
Herhangi bir oturum açmış kullanıcı **başka bir sitenin** `property_id`'sini kendi aktif sitesi yapıp
`POST /auth/refresh` ile o siteyi taşıyan token alabiliyor. Roller de siteye göre değil **global** olduğu için
(`users.roles TEXT[]`), bir sitede `MANAGER` olan kişi **tüm sitelerde** yönetici oluyor.
Ardından `/residents`, `/finance/debtors`, `/finance/assessments/overview`, `/requests` o sitenin verisini döndürüyor.

## 3.5 🔴 Para hesapları hatalı
1. **`GetUnitBalance` bakiyeyi kullanıcı sayısıyla çarpıyor** (`finance/repository/finance.go:35-43`):
   `JOIN users u ON ll.unit_id = (...)` — join koşulu `u`'ya referans vermiyor, yani kartezyen çarpım.
   156 sakinli bir sitede **1.200 TL borç 187.200 TL** görünüyor. Bu değer doğrudan sakine gösterilen
   `current_balance`/`has_debt` alanlarını besliyor.
2. **Ödeme hiçbir zaman tamamlanmıyor:** `payments` tablosuna `PENDING` satır atılıyor,
   `monthly_assessments.paid_amount` **hiç güncellenmiyor** (repoda `UPDATE monthly_assessments` yok) →
   ödeme yapan sakin sonsuza dek borçlu kalıyor. Transaction yok, hata yutuluyor, idempotency yok,
   tahakkuk sahipliği doğrulanmıyor (başka birinin tahakkukuna ödeme bağlanabiliyor).
3. **Her yerde `float64`:** şema `DECIMAL` (doğru) ama Go tarafı kayan nokta → dağıtımda kuruş kaçağı;
   `Σ assessment_details.amount ≠ monthly_assessments.total_amount` olabiliyor.
4. **Gecikme tazminatı hiç hesaplanmıyor** (`late_fee` kolonu var, hep 0) — KMK m.20'nin aylık %5'i uygulanmıyor.

## 3.6 🔴 Kullanıcıya yalan söyleyen arayüzler
Kullanıcı işlemin başarılı olduğunu görüyor, hiçbir şey kaydedilmiyor:

| Yer | Kanıt | Ne oluyor |
|---|---|---|
| Sakin mobil — **ödeme** | `dues_payment_screen.dart:315-318` | Hiç ağ çağrısı yok → "Ödeme Başarılı!" |
| Sakin mobil — talep | `create_request_screen.dart:273-313` | "Talep Oluşturuldu! Takip no: TLP-2026-042" (sabit) |
| Sakin mobil — ziyaretçi | `visitor_preregister_screen.dart:261-301` | "QR kodlu giriş linki SMS olarak gönderildi" |
| Sakin mobil — belge | `documents_screen.dart:667-695` | Bellek içine ekliyor, ekrandan çıkınca kayıp |
| Yönetici mobil | 11 ayrı yer (tahakkuk, sayaç, duyuru, gider, rapor) | API çağrılmadan yeşil "kaydedildi" |
| Admin panel — ayarlar | `settings/page.tsx:41-44` | Hiçbir şey kaydetmeden "Kaydedildi" |
| Admin panel — bildirim | `notifications/page.tsx:189` | `catch{}` → gönderilmemişken "124 kişiye gitti" |
| Admin panel — rapor | `reports/page.tsx:134` | "E-posta gönderildi" — hiçbir şey gönderilmiyor |
| Admin panel — şifreler | `credentials/page.tsx:107-108` | Hata alınca **uydurma şifre** gösteriyor (`"demo-sifre-2026"`) |
| Admin panel — silme | 13/14 sayfa | `deleted:1` yalnızca React state'ine yazılıyor → F5'te kayıt geri geliyor |
| 22 backend servisi | Her POST/PUT/DELETE | `201 Created` dönüyor, hiçbir yere kaydetmiyor |

**En kritik:** admin panelde giriş şifresi **düz metin olarak sunucu log'una** yazılıyor
(`api/auth/[...nextauth]/route.ts:17` — `console.log(credentials)`). Bu tek başına KVKK ihlali.

## 3.7 🔴 Mobil uygulamalar üretimde çalışmaz durumda
**Sakin uygulaması:**
- `AndroidManifest.xml`'de (main) **tek bir `<uses-permission>` yok** → release APK'da **INTERNET izni yok**;
  izin yalnızca `debug/AndroidManifest.xml`'de. Release build'de tüm API çağrıları `SocketException` alır
  ve (KN-2 gereği) kullanıcıya sessizce "veri yok" gösterilir.
- Taban adres `http://localhost:8000/api/v1` — gerçek cihazda çalışmaz; `usesCleartextTraffic` de yok →
  Android 9+ düz metin HTTP'yi bloklar. Ortam bazlı yapılandırma (`--dart-define`/flavor) yok.
- `ios/` klasörü **hiç yok** → iOS build imkânsız.
- Biyometrik giriş Android'de **çalışmaz**: `MainActivity : FlutterActivity` (`local_auth` `FlutterFragmentActivity` gerektirir).
- "Kalıcı oturum" yok: `initialLocation: '/login'` sabit, router `redirect`'i `TODO` → geçerli token'a
  sahip kullanıcı her açılışta giriş ekranı görüyor.
- KVKK onay ekranı **atlanabilir**: biyometrik yol `kvkk_consent_required` alanını hiç kontrol etmiyor; route guard yok.
- Release APK **debug anahtarıyla** imzalı, `applicationId = com.example.siteeksen_mobile` → Play Store reddeder.
- Push bildirim **hiç yok** (Firebase kodu 0 satır, `google-services.json` yok).
- 12/18 route arayüzden ulaşılamıyor; "Daha Fazla" menüsündeki **10 öğenin tamamı** `onTap: () {}`.

**Yönetici uygulaması:**
- `api_client.dart:7` taban adresi `/v1`, backend `/api/v1` bekliyor → **üretimde her çağrı 404**
  (k8s ingress'te de `rewrite-target` yok, aynı hata).
- Router'da auth guard yok (`app_router.dart:296-303` `redirect` her zaman `null`) → giriş yapmadan her route açılabilir.
- Çıkış yapınca token silinmiyor (`main_screen.dart:209-216` yalnızca yönlendirme yapıyor) → refresh token cihazda kalıyor.
- RBAC **fail-open**: `if (_roles.isEmpty) return true` → token yok/bozuksa **tam menü** açılıyor;
  ayrıca iddia edilenin tersine `AUDITOR` her şeyi görüyor (yalnızca `STAFF` kısıtlı).
- AI fatura tarama sahte (`Future.delayed` + sabit sonuç), ama "API Ayarları" ekranı
  "şifrelenmiş saklanır, her değişiklik kayıt altında" diye **yalan güvence** veriyor.
- 17 ekran menüden erişilemiyor; `intl` dahil 16 bağımlılık hiç kullanılmıyor → para biçimlendirme elle ve
  bozuk (`bank_integration_screen.dart:492-497` → `12.450.00`).
- Test sayısı **0**; `test/widget_test.dart` var olmayan `MyApp` sınıfını çağırıyor → `flutter test` derlenmez.

## 3.8 🟠 Yönetişim katmanı hiç yok (KMK)
Bir Türkiye site yönetim yazılımının hukuki bel kemiği eksik:
**işletme projesi (yıllık bütçe — KMK m.37)**, kat malikleri kurulu/genel kurul (m.29-33: çağrı, yeter sayı,
vekâlet sınırı, karar nisapları), **karar defteri ve işletme defteri** (m.32, m.36), denetçi ve yıllık hesap
verme (m.39, m.41), yönetim planı, **hukuk/icra takibi** (m.20, m.22 kanuni ipotek, İİK m.68),
gecikme tazminatı (m.20/2), **ısı-su gider paylaşımı** (pay ölçer yönetmeliği), toplu yapı organları (m.66-73).

Bunlar olmadan sistem aidat toplamanın **yasal dayanağını** üretemiyor ve ödemeyen malikten icra yoluyla
tahsilat yapamıyor. Ayrıntı: `tasks/modul-envanteri.md` (Katman 2 ve 3) ve `tasks/gap-analizi.md`.

---

# 4. Doğru yapılmış işler (hakkını vermek gerek)

Denetim yalnızca hatayı değil, sağlam olanı da tespit etti. Aşağıdakiler **gerçekten çalışıyor** ve
yeniden yazılmamalı — üzerine inşa edilmeli:

| İş | Kanıt | Not |
|---|---|---|
| identity `residents`/`units` modülü | `identity/repository/resident.go:51-179` | Gerçek JOIN sorguları, `Create` tek transaction içinde |
| `POST /users/me/properties` | `identity/repository/user.go:101-143` | Site + birim + `resident_units` tek transaction, `defer tx.Rollback` doğru |
| KVKK açık rıza (backend) | `identity/handlers/auth.go:134`, `repository/user.go:94-98` | Idempotent `UPDATE ... WHERE kvkk_consent_at IS NULL` — temiz |
| Tahakkuk dağıtım matematiği | `finance/repository/finance.go:399-545` | EQUAL/AREA_M2/SHARE_RATIO doğru; **sıfıra bölme üç yolda da korunmuş**; arsa payı toplamı 100 olmasa da oransal doğru; mükerrer dönem unique kısıtla engellenmiş. *(Tek kusuru kuruş yuvarlaması — §3.5)* |
| finance yönetim uçları | `finance/main.go:42,46,49,53` | `debtors`, `expense-categories`, `assessments/overview`, rol-duyarlı `payments` — gerçek sorgular |
| community talep durum makinesi | `community/service/request.go:57-96` | `allowedStatusTransitions` ile `CLOSED`'a doğrudan geçiş **gerçekten** engellenmiş; sakin onayı akışı titiz yazılmış |
| JWT süreleri | `identity/service/auth.go:138-140` | 15 dk / 7 gün — doğru |
| Android geri tuşu (sakin) | `mobile/.../main_screen.dart:42-52` | İddia kodla birebir örtüşüyor |
| PDF/Excel üretim motoru | `pkg/reports/` | `gofpdf` + `excelize` ile gerçek üretim (yalnızca beslendiği veri sahte) |
| SMS ve WhatsApp entegrasyonları | `pkg/integrations/sms/`, `whatsapp/` | Netgsm/İletimerkezi/WhatsApp Cloud API gerçek ve düzgün yazılmış — sadece bağlanmamış |
| `document` servisinin `Upload()` fonksiyonu | `document_service.go:135-191` | Uzantı allowlist'i, UUID'li ad, hata halinde temizlik — doğru yazılmış, sadece hiçbir route'a bağlı değil |
| `unit_balances` view'ı | `001_initial_schema.sql:422` | Bakiyeyi **doğru** hesaplıyor — §3.5'teki kırık sorgu yerine bu kullanılmalı |
| Şema para tipleri | tüm migration'lar | 101 `DECIMAL` kolonu, hiç `FLOAT` yok — şema tarafı doğru (sorun Go tarafında) |
| KVKK aydınlatma metni | `legal/kvkk-aydinlatma.md` | 159 satır gerçek içerik; saklama süresi tablosu, m.11 hakları, başvuru yolu var *(eksiği: "toplama yöntemi ve hukuki sebep" bölümü + placeholder adresler)* |
| `.gitignore` hijyeni | — | 293 takipli dosyada `.env`/secret/`.pem`/binary sızıntısı **yok** |
| Admin panel derlemesi | fiilen çalıştırıldı | `npm run build` → 21 sayfa, çıkış kodu 0 |

---

# 5. Bundan sonra ne yapılacak

1. **Doğrulama politikası yürürlüğe girer** → `tasks/dogrulama-politikasi.md`
   Kanıtsız `✅` yasak; her satırda kanıt seviyesi (D0–D4) zorunlu.
2. **Dokümanlar gerçeğe göre yeniden yazılır** → `tasks/roadmap.md`, `tasks/todo.md`
   Yanlış `✅`'ler kaldırılır; ikiz dosyalar tek kaynağa indirilir.
3. **Olması gereken modüller tanımlanır** → `tasks/modul-envanteri.md` (60 modül, mevzuat dayanaklı)
4. **Eksik ve mantık hataları modül bazlı çıkarılır** → `tasks/gap-analizi.md`
5. **Geliştirme, kök nedenlerden başlar** (genişlik değil derinlik):
   dürüstlük düzeltmeleri → kurulabilirlik → kimlik/yetki/izolasyon → para doğruluğu → yönetişim katmanı.
6. **Kullanıcı kararı bekleyen konular** → `tasks/questions.md` (S-01 … S-18)

> Bu rapor bir suçlama listesi değil, bir **temel atma** belgesidir. Kod tabanında gerçekten iyi yazılmış
> parçalar var (§4); sorun bu parçaların bağlanmamış, doğrulanmamış ve dokümanda olduğundan büyük
> gösterilmiş olması. Bundan sonrası için ölçüt tek: **çalıştığı kanıtlanmayan hiçbir şey "tamam" sayılmaz.**
