# Todo — Aktif İş Kuyruğu

**Bu dosya 2026-09-09'da sıfırdan yeniden yazıldı.** Önceki sürüm, doğrulanmamış "✅" işaretleri içerdiği
için geçersiz kabul edildi (bkz. `tasks/audit-raporu.md`). Eski sürüm git geçmişinde durmaktadır.

> Önceki sürümdeki **"Oturum Talimatları (Otonom — Kullanıcı Uyuyor)"** bölümü o oturuma özeldi ve
> **artık geçerli değildir.** Commit/push politikası: `tasks/questions.md` S-17 (varsayılan: commit edilmez).

Kanıt seviyeleri: `tasks/dogrulama-politikasi.md` §1. Kanıtsız madde `[D1]`'den yükseğe çıkarılamaz.

---

## Geliştirme ortamını açma (hızlı)

```bash
# Backend (PostgreSQL + gerçek veriye bağlı servisler + gateway)
bash backend/scripts/dev-up.sh

# Panel (ayrı terminal)
cd admin && npm run dev      # http://localhost:3001
```

Demo giriş: `5551234567` / `Demo123!` (yönetici) · `5559876543` / `Demo123!` (kiracı)

---

## Bu oturumun kapsamı

| Aşama | Durum |
|---|---|
| A. Denetim (iddia vs gerçek) | **Bitti** — `tasks/audit-raporu.md` + `tasks/audit/` (5 kanıt dosyası) |
| B. Olması gereken modüllerin tanımlanması | **Bitti** — `tasks/modul-envanteri.md` (60 modül) |
| C. Gap analizi (eksikler + mantık hataları) | **Bitti** — `tasks/gap-analizi.md` (B01-B97 + özellik bazlı eksikler) |
| D. Doğrulama politikası | **Bitti** — `tasks/dogrulama-politikasi.md` |
| E. Yol haritası + ustalık planı | **Bitti** — `tasks/roadmap.md` |
| F. Kullanıcıya sorular | **Bitti** — `tasks/questions.md` (S-01…S-18) |
| G. Geliştirme: FAZ 0 (dürüstlük onarımı) | **sürüyor** |

## Doğrulama ortamı — ÇÖZÜLDÜ (2026-09-12)

Kullanıcı talimatıyla local iş **WSL (Ubuntu 24.04)** üzerinden yürütülüyor; Windows'taki AppLocker
kısıtı orada yok (`questions.md` S-01).

- **Kurulu:** Go 1.24.7 (WSL'e kuruldu), Docker 27.5.1, psql 16, Node 22
- **Eksik:** Flutter → mobil işler hâlâ `[D1]` kalır (`questions.md` S-01b)

**Kalıcı doğrulama betiği:** `bash backend/scripts/verify-stack.sh`
Sıfırdan PostgreSQL → 11 migration → şema denetimi → idempotency → `pkg/audit` testi →
identity-service'i ayağa kaldırıp gerçek HTTP istekleri. **42 kontrol.**
Backend'e dokunan her değişiklikten sonra çalıştırılır.

---

# FAZ 0 — Dürüstlük Onarımı (aktif)

**İlke:** Sistemin kullanıcıya yalan söylemesini durdur. Yeni özellik yok.
**Neden ilk:** Yanlış rakam gösteren bir mali ekran, hiç göstermeyenden daha zararlıdır.

## 0.A — Admin panel

- [x] **[D2] 0.A.1 🔴 Giriş şifresinin log'a yazılması kaldırıldı**
      `admin/src/app/api/auth/[...nextauth]/route.ts` — `console.log(credentials)` silindi;
      hata ayıklama için yalnızca **maskelenmiş** telefon (`maskPhone`) ve HTTP durumu loglanıyor. *(B16)*
      **Kanıt:** `npm run build` → çıkış kodu 0
- [x] **[D2] 0.A.2 🔴 Sessiz mock fallback'ler kaldırıldı**
      expenses, personnel, parking, reservations, visitors, accounting, notifications, credentials —
      hardcoded veri dizileri silindi; `loadError` + `<ErrorState onRetry>` kalıbına geçildi.
      Özet/istatistik kartları hata durumunda uydurma sayı yerine `—` gösteriyor. *(B79)*
      Ortak bileşen eklendi: `admin/src/components/ui/data-state.tsx`
- [x] **[D2] 0.A.3 🔴 Credentials sayfasındaki uydurma şifre kaldırıldı**
      `"demo-sifre-2026"` silindi; backend'de şifre gösterme ucu olmadığı için özellik dürüstçe
      devre dışı ve nedeni ekranda açıklanıyor. Erişim kaydının yalnızca yerel olduğu belirtiliyor. *(B80)*
- [x] **[D2] 0.A.4 🔴 Sahte "kaydedildi/gönderildi" mesajları kaldırıldı**
      `settings` (kaydetmeden "Kaydedildi"), `notifications` (`catch{}` → gönderilmemişken başarı),
      `reports` (`alert("e-posta gönderildi")`), `accounting` (sahte toplu "hızlı işlem" modalı). *(B81)*
      Bildirim gönderimi artık yalnızca sunucu onayladığında başarı gösteriyor; hata görünür.
- [x] **[D2] 0.A.5 🟠 Sahte soft-delete kaldırıldı**
      Gerçek silme ucu olanlar API'ye bağlandı (`deleteEmployee`, `deleteVehicle`, `cancelReservation`);
      olmayanlar sahte başarı yerine dürüst hata mesajı veriyor. *(B83, B60)*
- [x] **[D2] 0.A.6 🟠 Çıkış (logout) düğmesi eklendi**
      `components/layout/header.tsx` — `signOut({callbackUrl:"/login"})` ile profil menüsünde.
      Ayrıca hardcoded "Ahmet Yılmaz / Yönetim Kurulu Başkanı" kaldırılıp gerçek oturum bilgisi
      (`useSession`) gösteriliyor; çalışmayan arama kutusu ve sahte bildirim rozeti kaldırıldı. *(B91)*
- [x] **[D2] 0.A.9 Doğrulama:** `npm run build` → **çıkış kodu 0** (21 sayfa)
- [x] **[D2] 0.A.7 🟠 Var olmayan uçlar düzeltildi** *(B95)*
      `getFinanceOverview` yayında olmayan `/finance/overview`'a gidiyordu (mobilde);
      gerçek uca (`/finance/assessments/overview`) yönlendirildi. Liste uçlarının yanıt
      biçimi tek sözleşmeye (`{"data": [...]}`) çekildi ve istemciler iki biçime de
      toleranslı hâle getirildi.
- [x] **[D2] 0.A.8 🟡 Ölü kod temizlendi** *(B93)* — `hooks.ts`'teki 17 kancanın
      kullanılmayan **13'ü** silindi. Ölü kod, olmayan bir veri katmanı izlenimi veriyordu.
- [x] **[D2] 0.A.10 🟠 Rol bazlı erişim kontrolü eklendi** *(B28)*
      Panelde HİÇBİR kontrol yoktu; giriş yapan herkes adres çubuğuna yazarak maaş
      bordrosuna ve sistem API anahtarlarına erişebiliyordu.
      `src/lib/rbac.ts` (yol → rol eşlemesi, hukuki gerekçeleriyle) + `middleware.ts`
      sunucu tarafı kontrolü + menü süzme + `/dashboard/forbidden` açıklama sayfası.
      Denetçi mali ekranları okur ama yazamaz (KMK m.41, görevler ayrılığı).
      **Kanıt:** `npx tsc --noEmit`, `npm run lint`, `npm run build` → hepsi temiz.
- [x] **[D2] 0.A.11 Admin panelde kalan uydurma veriler temizlendi**
      Ana sayfa (sabit "124 sakin / ₺45.600 / %87", uydurma 12 aylık grafik, var olmayan
      kişilere ait "son ödemeler"), talepler (yalnızca yerel state'i değiştiren durum
      güncellemesi), sayaçlar (sunucuya hiç istek göndermeyen "Okumaları Kaydet"),
      ayarlar (sahte yöneticiler, iyzico/Firebase/SMTP için yanlış "Bağlı" rozetleri,
      uydurma "Pro Plan ₺299/ay" ve 3 ödenmiş fatura).

## 0.B — Backend (Go)

- [x] **[D2] 0.B.3 🟠 Yutulan hatalar görünür kılındı (kısmi)**
      `pkg/middleware/auth.go` — `_ = audit.LogAction(...)` kaldırıldı, hata loglanıyor;
      `finance/repository/finance.go` — ödeme-tahakkuk bağlantısındaki yok sayılan `err` düzeltildi
      ve tüm akış tek transaction'a alındı. *(KN-2, B59, B47)*
      **Kanıt:** `go build ./...` + `go vet ./...` → 0
- [x] **[D4] 0.B.1 🔴 Kaydetmeyen uçlar `501`'e çevrildi** *(B78, B79, B84)*
      22 mock servisin **tüm** uçları (yalnızca yazma değil — okuma uçları da uydurma veri
      döndürüyordu) artık `501 Not Implemented` döndürüyor. Ortak sözleşme: `pkg/stub`.
      Yanıt gövdesi modül adını, "istek İŞLENMEDİ" uyarısını ve doküman referansını içerir;
      `X-SiteEksen-Not-Implemented: true` başlığı eklenir. Sağlık ucu artık `"healthy"` değil
      `"not_implemented"` der (servis ayakta ama işlevsiz).
      Etkilenen servisler: asset, banking, bulletin, contract, document, energy_analytics, esg,
      expense, inventory, iot, meeting_wizard, notification, nps, package, parking, patrol,
      personnel, reservation, settings, smart_collection, survey, visitor.
      **Kanıt:** `verify-stack.sh` §7 — çalışan servise `GET /api/v1/vehicles` → **501**,
      `POST /api/v1/vehicles` → **501**, başlık mevcut; kaynaklarda uydurma isim taraması → 0 satır.
- [x] **[D4] 0.B.2 🟠 Yanlış sağlık bilgileri (`ai_enabled` vb.) kaldırıldı** *(B84)*
      `energy_analytics`, `smart_collection`, `meeting_wizard` sağlık uçları yapılandırmaya
      bakmadan `ai_enabled: true` diyordu. Bu gövdeler `stub.Health()` ile değiştirildi.
      **Kanıt:** `grep -rn "ai_enabled" services/` → 0 sonuç.
- [x] **[D4] 0.B.4 🟡 Community'nin 4 auth'suz modülü `AuthMiddleware` + `501` arkasına alındı** *(C-1, B78)*
      Duyuru/anket/ilan/rezervasyon uçları **token'sız** POST/PUT/DELETE kabul ediyordu
      (herkes duyuru oluşturup silebilirdi). Tümü `AuthMiddleware` arkasına alındı ve `501` döndürüyor.
      Gerçek DB'ye bağlı `requests` modülü değişmedi. Sağlık ucu hangi modülün kalıcı olduğunu bildiriyor.
      **Kanıt:** `go build`/`go vet` → 0; `verify-stack.sh` 47/47.
- [x] **[D4] 0.B.5 🟠 Kalan yok sayılan `err`'ler giderildi** *(M-2)*
      `esg`/`nps`/`banking`/`parking`/`visitor`'daki yutulan hatalar, ilgili gövdeler
      tamamen kaldırıldığı için ortadan kalktı.
      **Kanıt:** `grep -rn "_ = .*err\|ShouldBindJSON(&req)$" services/ pkg/` → 0 sonuç.

---

# FAZ 1 — Kurulabilirlik (büyük kısmı tamamlandı ve doğrulandı)

**Çıkış ölçütü sağlandı:** Temiz bir makinede veritabanı sıfırdan kurulabiliyor ve demo giriş çalışıyor.
**Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **42/42 kontrol geçti** (2026-09-12)

- [x] **[D4] 1.1 Migration 004 `expense_categories` çakışması giderildi** *(B01)*
      Tablo yeniden tanımlanmak yerine 001'in tablosuna eksik kolonlar eklendi; böylece finance (001)
      ve expense (004) sözleşmeleri tek tabloda birleşti. Varsayılan kategorilere KMK m.20'ye göre
      `distribution_type` atandı (eşit / arsa payı), hukuki teyit notu düşüldü.
      **Kanıt:** temiz DB'de `004` → OK
- [x] **[D4] 1.2 Migration 005 `vehicles` çakışması giderildi** *(B02)*
      `CREATE TABLE IF NOT EXISTS` yerine idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`;
      `plate_number` NOT NULL kısıtı kaldırıldı, veri `plate` kolonuna taşındı, `property_id`
      birimden türetildi; `idx_vehicles_unit` çakışması `IF NOT EXISTS` ile giderildi.
      **Kanıt:** `005` → OK; **005 sonrası 29 tablo artık oluşuyor** (toplam 61 tablo)
- [x] **[D4] 1.2b Migration 005'teki geçersiz UUID düzeltildi** *(denetimde yakalanmamıştı)*
      `inventory_categories` seed'inde `ic0000...` kimlikleri kullanılıyordu; `i` hex olmadığı için
      `invalid input syntax for type uuid` hatası veriyordu. `1c` prefix'ine çevrildi.
- [x] **[D4] 1.3 006'nın zincir çöküşü giderildi** *(B03)* — 005 tamamlandığı için `reservations` vb.
      tablolar artık mevcut; 006 sorunsuz uygulanıyor.
- [x] **[D4] 1.7 Demo giriş onarıldı** *(B06)*
      Seed'deki bcrypt hash hiçbir şifreyle eşleşmiyordu (fiilen doğrulandı) ve iki kullanıcıda
      aynıydı. Yeni hash'ler `cost=12` ile üretilip doğrulandı. **Giriş: `5551234567` / `Demo123!`**
      **Kanıt:** gerçek identity-service'e `POST /auth/login` → **HTTP 200 + JWT**; yanlış şifre → **401**
- [x] **[D4] 1.9 `go build ./...` onarıldı** *(B04)*
      Ölü `backend/api/` dizini kaldırıldı (kırık import + `X-User-Role` başlığına güvenen sahte
      süper-admin kontrolü). Ayrıca gizli kalmış iki derleme hatası giderildi:
      `pkg/integrations/sms` (kullanılmayan `body`, bakiye hiç parse edilmiyordu) ve
      `pkg/integrations/whatsapp` (tanımsız `MediaContent` tipi).
      **Kanıt:** `go build ./...` → 0, `go vet ./...` → 0
- [x] **[D3] 1.14 Kalıcı doğrulama betiği eklendi** — `backend/scripts/verify-stack.sh` (42 kontrol)

### FAZ 1 — kalanlar
- [x] **[D4] 1.4 Migration'lar tam idempotent yapıldı** *(B08)*
      001'deki 25 `CREATE TABLE` ve 24 `CREATE INDEX`, 003/005'teki 91 index ifadesi
      `IF NOT EXISTS` aldı; 004'teki `CREATE TRIGGER` öncesine `DROP TRIGGER IF EXISTS`
      eklendi; `002` tümüyle koruma altına alındı. Her migration artık transaction içinde
      uygulanıyor (çalıştırıcı sarmalıyor).
      **Kanıt:** `verify-stack.sh` §4b — **11 migration dosyasının tamamı** temiz kurulumdan
      sonra yeniden uygulandığında hatasız geçiyor.
- [x] **[D4] 1.5 🔴 Migration çalıştırıcı eklendi** *(B05)* — `backend/cmd/migrate`
      `schema_migrations` sürüm tablosu, PostgreSQL **advisory lock** (eşzamanlı çalıştırma
      koruması), **SHA-256 sağlama denetimi** (uygulanmış bir migration sonradan
      değiştirilmişse durur) ve migration başına transaction. `-status`, `-dry-run` bayrakları.
      Docker imajı: `backend/cmd/migrate/Dockerfile`.
      **Kanıt:** `verify-stack.sh` §2 (11 migration uygulandı, `schema_migrations` 11 kayıt) ve
      §4a (ikinci çağrıda hiçbir şey uygulamıyor). Sağlama koruması fiilen sınandı: kayıtlı
      sağlama bozulduğunda çalıştırıcı hata verip **çıkış kodu 1** döndürdü.
- [x] **[D4] 1.7b Seed `initdb.d` dışına taşındı** — `docker-compose.yml`'deki
      `./backend/migrations:/docker-entrypoint-initdb.d` mount'u kaldırıldı; migration'ları
      artık tek seferlik `migrate` servisi uyguluyor ve tüm servisler onun **başarıyla
      tamamlanmasını** bekliyor (`service_completed_successfully`).
      Demo veri `SEED_DEMO_DATA` ile kontrol ediliyor: üretimde `false` verildiğinde
      migration uygulanmış sayılır (sürüm zinciri kırılmaz) ama **bilinen şifreli demo
      hesaplar açılmaz**.
- [x] **[D4] 1.8 Seed verisi tutarlı hâle getirildi** *(B15)*
      `total_units=24` deniyordu ama 6 birim vardı; `total_share_ratio=10000` iken birimlerin
      arsa payı toplamı 2480'di. Bu tutarsızlık **arsa payına göre dağıtımı (KMK m.20/1-b)
      test edilemez** kılıyordu: payda yanlış olduğu için her tahakkuk hatalı çıkardı.
      Artık 2 blok × 12 = **24 bağımsız bölüm** var ve arsa payları **tam 10000** ediyor.
      Gider kalemlerinin dağıtım türleri de KMK m.20'ye göre düzeltildi.
      **Kanıt:** `verify-stack.sh` §4d — SQL ile `total_units` ve arsa payı toplamı doğrulanıyor.
- [x] **[D4] 1.10 Servis varsayılan portları eşitlendi** *(B13)*
      13 servisin `main.go` varsayılanı compose/gateway tablosundan farklıydı ve 4 çift aynı
      varsayılan porta sahipti (document/parking, banking/esg, nps/package,
      energy_analytics/settings) → local'de ikisi birden çalıştırılamıyordu.
      Kanonik tablo: gateway yönlendirmesi + docker-compose. Fark **0**.
- [x] **[D4] 1.11 `firebase-credentials.json` mount'u kaldırıldı** *(B07)*
      Dosya depoda yok; Docker eksik yolu **dizin** olarak yaratıp `docker-compose up`'ı
      kırıyordu. Firebase zaten koda hiç bağlı değil (denetim bulgusu).
      **Kanıt:** `docker compose config` → çıkış kodu 0.
- [x] **[D4] 1.12 CI gerçek kapı hâline getirildi** *(B09, B10, B11)*
      Go sürümü `1.21` → **1.24** (`go.mod` ile aynı); `go build ./...`, `go vet ./...`,
      `gofmt` denetimi ve `go test -race ./...` eklendi; admin'de `|| true` kaldırıldı
      (`npm run lint`, `tsc --noEmit`, `npm run build`); Trivy artık `exit-code: 1` ile **kapı**
      ve ayrıca **sır taraması** yapıyor; mobil için iki uygulama da matris olarak
      `flutter analyze`/`flutter test` çalıştırıyor; yeni **verify-stack** işi tüm uçtan uca
      doğrulamayı CI'da koşuyor. Dağıtım işi secret yoksa sessizce "başarılı" görünmüyor.
      **Kanıt:** aynı komutlar local'de çalıştırıldı — `gofmt -l` boş, `go test ./...` 6/6 paket
      geçti, `npm run build` 0, `flutter analyze`/`flutter test` her iki uygulamada 0.
- [x] **[D4] 1.13 `003`'ün `audit_logs` DROP'u kaldırıldı** *(B14)*
      `DROP TABLE IF EXISTS audit_logs;` migration her tekrarlandığında **KVKK kapsamındaki
      tüm denetim izini siliyordu**. Artık tablo düşürülmüyor; eksik kolonlar idempotent
      `ALTER` ile ekleniyor. `011` ayrıca 001'den kalan eski kolonları (`user_ip`,
      `resource_type NOT NULL`, `resource_id`) veriyi taşıyarak tasfiye ediyor ve
      `created_at`'i `TIMESTAMPTZ`'ye çeviriyor.
      **Kanıt:** `verify-stack.sh` §4c — tabloya kayıt atılıp 003 yeniden uygulanıyor, kayıt
      hâlâ orada.
- [x] **[D2] 1.6 Geri alma (2026-09-27)** — `down` betiği BİLEREK yazılmadı (denetim izi/defterleri silerdi); geri alma = yedekten geri yükleme: `backend/scripts/db-backup.sh` / `db-restore.sh`, yordam `docs/runbook-veritabani-geri-alma.md`. **Kanıt:** `verify-stack.sh` adım 41 (yıkıcı migration taklidi → geri yükleme → birebir).

### Flutter doğrulaması — AÇILDI (2026-09-13)
- [x] **[D4] Flutter 3.47.4 WSL'e kuruldu** *(S-01b)* → mobil işler artık `[D1]` değil,
      çalıştırılarak doğrulanabiliyor.
- [x] **[D4] İki uygulamanın da derlenmeyen `widget_test.dart`'ı düzeltildi**
      Her ikisi de `flutter create` şablonundan kalan, var olmayan `MyApp` sınıfını çağıran
      sayaç testiydi → `flutter analyze` **hata** veriyordu ve çalıştırılabilir tek test yoktu.
      Gerçek duman testleriyle değiştirildi (2+2 test).
- [x] **[D4] Mobilde ölü kod ve kullanılmayan import'lar temizlendi**
      Rotaya hiç bağlı olmayan `home_screen.dart` silindi: sabit "Ahmet Yılmaz", sabit
      **"Borcunuz Bulunmamaktadır"** kartı, uydurma tüketim grafiği ve uydurma kampanyalar
      içeriyordu. 13 kullanılmayan import/alan kaldırıldı.
      **Kanıt:** `bash backend/scripts/verify-mobile.sh` → her iki uygulamada
      `flutter analyze` **hata/uyarı yok**, `flutter test` geçiyor.
- [x] **[D3] Mobil doğrulama betiği eklendi** — `backend/scripts/verify-mobile.sh`

---

# FAZ 2 — Kimlik, yetki, izolasyon (başladı)

- [x] **[D4] 2.1 🔴 Gateway'e kimlik doğrulaması eklendi** *(B17, B18)*
      **Sorun:** `cmd/gateway` 25 servise yönlendiriyor ama **hiçbir jeton doğrulaması
      yapmıyordu**; Kong'da da kimlik eklentisi yoktu. Maaş, TCKN, IBAN ve **API anahtarları**
      token'sız erişilebiliyordu.
      **Çözüm:**
      - `pkg/authtoken` — jeton doğrulamanın tek kaynağı (çatıdan bağımsız). `pkg/middleware`
        de artık bunu kullanıyor; mantık iki yerde çoğaltılmıyor.
      - Gateway: `/api/v1/auth/*` ve `/health` dışındaki her yol geçerli JWT ister; `JWT_SECRET`
        yoksa **fail-closed** (500).
      - Gateway istemciden gelen `X-User-Id`, `X-User-Role`, `X-Property-Id`, `X-Tenant-Id`
        gibi kimlik başlıklarını **siliyor** (aşağı akışta kimlik sahteciliği engellendi).
      - CORS artık joker `*` değil, `CORS_ALLOWED_ORIGINS` allowlist'i.
      - Her isteğe `X-Request-Id` veriliyor (denetim izi ilişkilendirmesi — FAZ 3.5).
      - `kong/kong.yml`: `/api/v1/auth` dışındaki **24 rotada** `jwt` eklentisi; consumer anahtarı
        Kong env vault'tan (`{vault://env/jwt-secret}`) okunuyor; CORS joker kökenleri kaldırıldı.
      - `identity`: jetonlara Kong'un beklediği `iss: "siteeksen"` claim'i eklendi.
      **Kanıt:** `go test ./pkg/authtoken/...` → 6/6 geçti (alg=none, yanlış anahtar, süresi dolmuş,
      anahtar yok senaryoları dahil). `verify-stack.sh` §8: gateway üzerinden token'sız `/users/me`
      → **401**, geçersiz jeton → **401**, `/auth/login` → **200**, geçerli jetonla `/users/me` → **200**.
- [x] **[D4] 2.2 🔴 Gateway'deki uydurma mali rapor üretimi kaldırıldı** *(B87)*
      `/api/v1/reports/generate` içi tamamen sabit (uydurma daire, sakin adı ve tutarlar) olan
      **indirilebilir PDF/Excel** üretiyordu. Gerçek mali veriye bağlanana kadar `501` döner.
      Gerçek rapor üretimi finance-service içinde yapılacaktır (FAZ 4/6).
      **Kanıt:** `verify-stack.sh` §8 → `POST /api/v1/reports/generate` → **501**.
- [x] **[D4] 2.3 🟠 Dashboard özetindeki uydurma sayılar kaldırıldı** *(B79)*
      `/dashboard/stats` kaynaklara ulaşamazsa `156 sakin / 245.000 TL gelir / %94 tahsilat`
      sabitlerini döndürüyordu. Artık ulaşılamayan kaynak için **alan hiç dönmez** ve
      `unavailable[]` listesinde nedeniyle bildirilir (`partial: true`).
      `recent-payments` sessizce boş liste döndürmek yerine `502` veriyor (boş liste "ödeme yok"
      anlamına gelir — bu yanlış bilgidir).
- [x] **[D4] 2.4 🔴 `POST /users/me/active-property` sahiplik doğrulaması** *(B21)*
      Gelen `property_id` HİÇ doğrulanmıyordu. JWT'deki `property_id` tüm izolasyonun tek
      dayanağı olduğu için, herhangi bir kullanıcı tek istekle **başka bir sitenin verisine**
      geçebiliyordu. Artık `resident_units` üzerinden aktif bağ aranıyor; yoksa **403**
      (400 değil — bu bir yetki ihlalidir ve denetim izinde `DENIED` olarak ayrışır).
      **Kanıt:** yabancı siteye geçiş → **403**, kendi sitesine → **200**.
- [x] **[D4] 2.5 🔴 Roller siteye göre kapsamlandı** *(B22)*
      `users.roles` global olduğu için bir sitede MANAGER olan kişi **tüm sitelerde**
      yöneticiydi — çok kiracılı bir SaaS'ta doğrudan izolasyon ihlali.
      `migrations/013` ile `property_roles` tablosu (atama izi, geçerlilik dönemi, karar
      referansı — KMK m.34 yönetici genel kurul kararıyla atanır).
      Jeton rolleri aktif siteye göre üç kaynaktan birleştiriliyor: `property_roles`
      (yönetim) + `resident_units` (sakinlik) + `users.roles` (yalnız platform rolleri).
      Rol çözümlemesi başarısızsa jeton **üretilmiyor** (boş rolle devam etmek, yetki
      kontrollerini sessizce atlatan bir jeton üretmek demektir).
      **Kanıt:** kiracı jetonunda MANAGER **yok**, TENANT var; yönetici jetonunda MANAGER var.
- [x] **[D4] 2.9 🟠 Rol bazlı erişim kontrolü — sunucu ve panel** *(B28)*
      Sunucu: finance ve governance servislerinde `RequireRole`. Site geneli borçlu/ödeme
      listeleri ve tahakkuk oluşturma yalnızca yönetime açık; **denetçi okur, yazamaz**
      (KMK m.41 görevler ayrılığı).
      Panel: `src/lib/rbac.ts` + `middleware.ts` + menü süzme (bkz. 0.A.10).
      **Kanıt:** yönetici `/finance/debtors` → 200, kiracı → **403**; yetkisiz deneme
      denetim izine `DENIED` olarak yazıldı.
- [x] **[D4] 2.6 🔴 Tenant izolasyonu (PostgreSQL RLS)** — **TAMAMLANDI (2026-09-26).**
      81 tabloda RLS (migration 020-026); 26 servisin tamamı `pkg/dbscope` kullanıyor.
      Kimlik servisi ayrı rol (`siteeksen_identity`), uygulama rolü en az yetkiyle.
      RLS dışında kalan 8 tablo gerekçeli ve doğrulama listeyi birebir denetliyor.
      Geçiş sırasında bulunan ve kapatılan açıklar: talep durumu (başka sitenin talebi
      ilerletilebiliyordu), ödeme (başka sitenin tahakkuku bağlanabiliyordu), bütçe
      itirazı (başka site sonuçlandırabiliyordu; kiracı/başkasının dairesi adına itiraz),
      karar defteri (başka site yazabiliyordu), görünümler (RLS'i atlıyordu).
      **Kanıt:** `verify-stack.sh` §32-36 — uçtan uca çapraz site testleri dahil.
- [x] **[D4] 2.7 🟠 Çıkışta jeton iptali** — `revoked_tokens` + toplu iptal (§30).
      Uygulama rolü iptal kaydını artık silemez (migration 025).
- [x] **[D4] 2.8 🟠 Hassas alanların şifrelenmesi** — TCKN/IBAN AES-256-GCM + blind index (§31).

---

# FAZ 3 — Denetim izi (ilk madde tamamlandı)

- [x] **[D4] 3.1 🔴 Denetim izi çalışır hale getirildi** *(B59)*
      **Sorun:** `pkg/audit` şemada olmayan kolonlara (`user_ip`, `resource_type`, `resource_id`)
      yazıyordu; INSERT her çağrıda `42703` hatası veriyor, hata `_ =` ile yutuluyor ve
      `audit_logs` tablosu kalıcı olarak boş kalıyordu — `legal/kvkk-aydinlatma.md`'deki
      "log tutuyoruz" taahhüdü karşılıksızdı.
      **Çözüm:** Migration `011` (şema ↔ kod uyumu, `property_id`/`request_id`/`status_code` eklendi,
      `tenant_id` zorunluluğu kaldırıldı) + `pkg/audit` yeniden yazıldı (tipli `Entry`) +
      `pkg/middleware` hatayı loglar hale getirildi, 403'ler `DENIED` olarak ayrıştırıldı,
      401'ler gürültü olmasın diye yazılmıyor.
      **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı **2/2 geçti**;
      uçtan uca istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- [x] **[D3] 3.2 `old_values`/`new_values` alanları yazılabilir hale geldi** (tipli `Entry` ile)
- [x] **[D4] 3.4 Hassas veri okuma logu (2026-10-03)** — her korumalı GET `VIEW` olarak
      (kullanıcı, site, kayıt kimliği, durum kodu) yazılıyordu ama hiç sınanmamıştı; reddedilen
      okuma `DENIED`, maskesiz TCKN/IBAN ayrıca `PII_REVEAL`, belge `document_access_logs`.
      Sır gösterme ucu yok (kimlik bilgisi modülü 501). **Sınır:** liste okumalarında tek tek
      kayıt kimlikleri yazılmaz (kim, ne zaman, hangi liste yazılır).
      **Kanıt:** `verify-stack.sh` §31 → personel kaydı okuması (maaş), sakin listesi (telefon/e-posta)
      ve sakinin reddedilen denemesi denetim izinde; 1019/1019.
- [x] **[D4] 3.5 Yapılandırılmış log + istek kimliği (2026-09-26)** — 26 servis + gateway JSON günlük
      (`middleware.NewRouter`: request_id, route şablonu, status, süre, kullanıcı, site; ham yol/sorgu
      YAZILMAZ). İstemci `X-Request-Id`'si doğrulanır: 64 karakteri aşan değer denetim kaydını
      düşürüyordu (denetimden kaçma) — kapatıldı. **Kanıt:** `verify-stack.sh` §37-D3.

---

# FAZ 4 — Para doğruluğu (ilk düzeltmeler yapıldı)

- [x] **[D2] 4.1 🔴 `GetUnitBalance` kartezyen join'i düzeltildi** *(B45)*
      `JOIN users u ON ll.unit_id = (...)` koşulu `u`'ya referans vermediği için CROSS JOIN'di;
      bakiye **kullanıcı sayısıyla çarpılıyordu** (156 sakinli sitede 1.200 TL borç → 187.200 TL).
      Hesap artık 001'de tanımlı ve doğru yazılmış `unit_balances` view'ı üzerinden, sakinin
      **tüm** aktif bağımsız bölümlerini kapsayacak şekilde yapılıyor.
      **Kanıt:** `go build`/`go vet` → 0. *(Sayısal doğruluk testi FAZ 4.12'de yazılacak.)*
- [x] **[D2] 4.2b Ödeme kaydı tek transaction'a alındı + IDOR kapatıldı** *(B47, B24, B53)*
      Sahiplik doğrulaması (`resident_units` join + `FOR UPDATE`), `deleted = 0` filtresi,
      `payment_assessments.amount` yazımı, `payments.unit_id` doldurulması, hata yutmanın
      kaldırılması. Sahte `checkout.siteeksen.com` adresi kaldırıldı; yanıta
      `payment_gateway_ready: false` eklendi.
- [x] **[D2] 4.6b Ham veritabanı hatalarının istemciye sızması engellendi** (ödeme ucu) *(B37)*
- [x] **[D4] 4.2 `paid_amount` güncellemesi — ödeme onay akışı** *(B46)*
      Ödeme kaydı oluşuyor ama `paid_amount` HİÇ güncellenmiyordu; ödemesini yapan sakin
      **sonsuza dek borçlu** kalıyor, borçlu listesinden düşmüyordu.
      Ödeme sağlayıcısı yok (S-06) ama Türkiye'de aidatların büyük kısmı havale/EFT ile
      tahsil ediliyor; **yönetici onayı** gerçek bir iş akışıdır ve sağlayıcı geldiğinde
      aynı repository çağrısı webhook'tan kullanılabilir.
      Tek transaction, `FOR UPDATE`, yalnızca `PENDING` onaylanabilir, başka siteye ait
      ödeme 403, `RejectPayment` ile borç değişmeden reddetme.
      **Kanıt:** onay öncesi borç değişmiyor; sonrasında `0,00 → 1.200,00` ve `PAID`;
      çift onay → **409**; `has_debt:false`.
- [x] **[D4] 4.3 Para tipi kuruşa çevrildi** *(B50)* — `pkg/money`: `Kurus` (int64),
      `FromTRY`/`TRY`, decimal tabanlı dönüşüm. Yeni yazılan tüm para kodu (işletme projesi
      dağıtımı, gecikme tazminatı, icra takibi tutarları) kuruş kullanıyor.
      **Kanıt:** `go test ./pkg/money/...` — float sapması testi dahil 9 test.
- [x] **[D4] 4.4 Kuruş yuvarlama + kalan dağıtımı** *(B51)* — **en büyük kalan**
      (largest remainder) yöntemi: tüm paylar aşağı yuvarlanır, artan kuruşlar en büyük
      kesirli kalana sahip paylara birer birer dağıtılır. Payların toplamı tutara
      **birebir** eşittir ve dağıtım **belirlenimcidir** (aynı girdi → aynı çıktı; yeniden
      hesaplamada daireler arasında kuruş yer değiştirmez).
      **Kanıt:** 2000 rastgele senaryoda kuruş kaybı yok; `verify-stack.sh` §11'de gerçek
      işletme projesinde 33.600.000 kuruş birebir tutuyor.
- [x] **[D4] 4.5 Gecikme tazminatı tahakkuku (KMK m.20/2)** — hiç hesaplanmıyordu.
      `POST /finance/late-fees/accrue`; oran mevzuat tablosundan; anapara = ödenmemiş
      **asıl** borç (tazminat üzerinden tazminat işlenmez); **idempotent** (yeniden yazılır,
      eklenmez); `late_fee_accruals` tablosuna gün/oran/anapara izi.
      **Kanıt:** 30 gün → **60,00 TL**, toplam **1.260,00 TL**, ikinci çalıştırmada değişmiyor.
- [x] **[D4] 4.12 Bakiye için sayısal doğruluk testi (2026-10-03)** — test yazılınca asıl hata
      çıktı: `unit_balances` hiç yazılmayan `ledger_lines`'tan okuyordu; sakinin
      `/finance/debt-status`'u borcu ne olursa olsun **0 / has_debt:false** diyordu (mobil "borç yok").
      Eski "ödeme sonrası has_debt:false" kontrolü ödemeden önce de geçerdi. Migration 030 görünümü
      tahakkuklara bağladı (panel borçlu listesiyle aynı kaynak).
      **Kanıt:** `verify-stack.sh` §10 → API bakiyesi bağımsız SQL toplamına birebir eşit (1200.00),
      onaydan sonra tam 1.200,00 düşüyor (→ 0.00); 1016/1016.
- [x] **[D4] B69 (2026-10-04):** ödeme listeleri sayfalı; yoğun 6 listede kesilme `truncated` ile bildiriliyor. Duyuru, anket, anket yorumu, sayaç ve sayaç okuması da aynı kalıpta.
- [x] **[D4] 4.13 (2026-10-04, kapsam kararı):** Go içindeki son kayan nokta para toplamı (ödeme oluşturma: tahakkuk kalanlarının float64 toplamı) decimal'e çevrildi; gider ortalaması kuruşa yuvarlanıyor. Şema `DECIMAL` kalır (kesin); JSON taşıma `number` olarak kalır — iki ondalıklı değer taşınırken bozulmaz, aritmetik yalnızca `pkg/money`/decimal ile yapılır. Kanıt: verify-stack "ödeme tutarı = bağlı tahakkukların toplamı". Eski not:
      **4.13 Mevcut `float64` para alanlarının kuruşa göçü** (not 2026-10-03: tahakkuk dağıtımı kuruşa geçti; kalan float alanlar yalnızca DECIMAL değerlerin taşınması/gösterimi) — yeni kod kuruş kullanıyor,
      `monthly_assessments`/`payments` tablolarındaki `DECIMAL` alanlar korunuyor.
      Tam göç ayrı bir migration ve istemci uyumu gerektirir.

## 0.C — Mobil (Flutter) — tamamlandı

> Flutter 3.47.4 WSL'e kuruldu; bu bölümdeki maddeler artık `[D1]` değil, çalıştırılarak
> doğrulanmıştır. **Toplu kanıt:** `bash backend/scripts/verify-mobile.sh` → 8/8.

- [x] **[D4] 0.C.1 🔴 Sahte ödeme ekranı gerçek API'ye bağlandı** *(B49)*
      Borç koda gömülüydü (₺1.250) ve "Öde → Onayla" **hiç ağ çağrısı yapmadan**
      "Ödeme Başarılı!" diyordu. Artık `/finance/debt-status` + `/finance/assessments`;
      ödeme isteği gerçekten gönderiliyor; `payment_gateway_ready:false` iken tahsilatın
      YAPILMADIĞI açıkça söyleniyor.
- [x] **[D4] 0.C.2 🔴 Sahte başarı mesajları kaldırıldı** *(B81)*
      Sakin: talep oluşturma (gerçek `createRequest`'e bağlandı, uydurma takip numarası
      kaldırıldı), ziyaretçi ön kaydı ("SMS gönderildi" yalanı kaldırıldı), belge yükleme.
      Yönetici: tahakkuk, sayaç, duyuru, gider, rapor ekranları.
- [x] **[D4] 0.C.3 🟠 Sessiz boş-listeye düşme kaldırıldı** *(B82)*
      Ortak bileşenler: `core/widgets/data_state.dart` — `LoadingView`, `ErrorStateView`
      (yeniden dene), `EmptyStateView`, `NotImplementedNotice`, `toUserMessage`.
      "Veri yok" ile "veri alınamadı" artık ayrı gösteriliyor.
- [x] **[D4] 0.C.4 🟠 Ölü rotalar ve boş `onTap`'lar giderildi** *(B89, B90)*
      Sakin uygulamasında rotaya bağlı olmayan `home_screen.dart` silindi (sabit
      "Borcunuz Bulunmamaktadır" kartı içeriyordu); "Daha Fazla" menüsündeki 10 boş
      `onTap` gerçek rotalara bağlandı; çalışmayan "Çıkış Yap" düzeltildi.
- [x] **[D4] 0.C.5 🟠 Yanlış güvence metni kaldırıldı** *(B85)*
      `api_settings_screen` "şifrelenmiş saklanır, her değişiklik kayıt altındadır" derken
      ekranın tamamı mock'tu ve 7 entegrasyon "aktif" görünüyordu. Gerçek duruma çevrildi.
- [x] **[D4] 0.C.6 `flutter analyze` bilgi (info) uyarıları sıfırlandı (2026-10-03)** — kalan 63
      uyarı (`prefer_const`, `withOpacity`, `Matrix4.scale`, `Radio.groupValue` → `RadioGroup`)
      giderildi; info düzeyi artık verify-mobile ve CI'da KAPI (`--no-fatal-infos` kaldırıldı).
      **Kanıt:** `verify-mobile.sh` → 8/8, iki uygulamada "hata/uyarı/bilgi yok".

## 0.D — Hukuki metinler — tamamlandı

- [x] **[D2] 0.D.1 🟡 Doğrulanamayan taahhütler düzeltildi** *(B86)*
      Güvenlik bölümü yeniden yazıldı: "AES-256", "TLS 1.3", "günlük yedekleme",
      "periyodik sızma testi" sağlanıyormuş gibi sayılıyordu; hiçbiri uygulanmıyordu.
      Artık **uygulanan** ve **uygulanmayan** tedbirler ayrı listelendi.
      Eksik zorunlu unsur **"toplama yöntemi ve hukuki sebep"** (KVKK m.10) eklendi;
      her işleme konusu için hukuki sebep (m.5/m.6) ve KMK/İİK dayanağı tabloya işlendi.
- [x] **[D2] 0.D.2 🟡 Placeholder alanlar işaretlendi** — üç metnin başına
      "TASLAK — yayına hazır değil" uyarısı kondu; doldurulmamış alanlar ve hukuk onayı
      eksikliği açıkça belirtildi.

## FAZ 0 çıkış ölçütü

Arayüzde gerçekten yapılmayan hiçbir işlem için başarı mesajı yok; hiçbir ekran uydurma veri göstermiyor;
kalıcı olmayan hiçbir uç nokta `2xx` dönmüyor.

---

# FAZ 6 — Yönetişim katmanı (KMK) — çekirdek tamamlandı

Yeni servis: `backend/services/governance` (port 8107). 22 mock servisin aksine **baştan**
gerçek veri katmanına bağlı yazıldı. Şema: `migrations/014`.

- [x] **[D4] 6.1 İşletme projesi / yıllık bütçe (KMK m.37)**
      Kalem bazlı bütçe; her bağımsız bölüme düşen pay `pkg/money` ile **kuruş** üzerinden
      ve en büyük kalan yöntemiyle, kalem dökümüyle birlikte hesaplanıyor.
      Tebliğ → **7 günlük** itiraz süresi (mevzuat tablosundan) → kesinleşme.
      Kesinleşen proje **İİK m.68** anlamında belge olarak işaretleniyor.
      Tebliğ edilmeden ya da süre dolmadan kesinleştirme **409** ile reddediliyor;
      açık itiraz varsa kesinleşme engelleniyor.
      **Kanıt:** 336.000 TL'lik projede payların toplamı **33.600.000 kuruş** (birebir);
      eşit dağıtılan kalemde daireler arası fark ≤ 1 kuruş.
- [x] **[D4] 6.2 Kat malikleri kurulu / genel kurul (KMK m.29-33)**
      Çağrı **15 günden** geç yapılırsa işlem reddediliyor (geç çağrı, kararı iptal
      edilebilir kılar). Nisap **sayı VE arsa payı** bakımından ayrı ayrı; "yarıdan fazla"
      tam yarıyı kapsamıyor. İkinci toplantıda yeter sayı aranmıyor (m.30/3).
      Vekâlet sınırları uygulanıyor (m.31: toplam oyun %5'i; 40 ve altı BB'de kişi başı 2).
      Özel nisaplarda payda **tüm kat malikleri**, olağan kararda ikinci toplantıda
      **katılanlar**. 4/5, oybirliği ve salt çoğunluk ayrı ayrı hesaplanıyor.
      **Kanıt:** 14 birim testi + `verify-stack.sh` §11 (12/24 katılımda nisap yok,
      13/24'te var).
- [x] **[D4] 6.3 Defterler (KMK m.32, m.36)**
      Karar ve işletme defteri; kayıtlar **ekle-only** ve **SHA-256 hash zincirli**.
      UPDATE/DELETE veritabanı tetikleyicisiyle engelli; `/verify` ucu zinciri baştan sona
      doğruluyor. Notere kapatma süresi (1 ay) aşılırsa uyarı döndürülüyor.
      **Kanıt:** zincir doğrulaması geçti; doğrudan SQL ile `UPDATE` denemesi reddedildi.
- [x] **[D3] 6.4 İcra / dava / kanuni ipotek (KMK m.22, İİK m.68)**
      Takip kaydı, olay geçmişi; borç tutarı tahakkuklardan hesaplanıyor (elle girilmiyor);
      dayanak belge belirtilmezse uyarı veriliyor.
- [x] **[D3] 6.5 Yönetici/denetçi görev dönemleri, yıllık hesap verme (m.39), denetim
      tutanakları (m.41)** — şema hazır (`governing_terms`, `accountability_reports`,
      `audit_reports`); uçlar sonraki turda.
- [x] **[D4] 6.6 Genel kurul kararı → karar defteri otomatik bağlantısı (2026-09-26)**
      Gündem maddesi sonuçlandığında karar (kabul ya da red) AYNI TRANSACTION'da toplantı
      yılının karar defterine yazılır: oy dağılımı, nisap gerekçesi, kaynak = gündem maddesi.
      Defter kapalıysa karar da yazılmaz (madde PENDING kalır; yarım işlem yok).
      **Kanıt:** `verify-stack.sh` §37-G — tek kayıt, zincir geçerli, kapalı defterde 409.
- [x] **6.7 Panel arayüzleri** — işletme projesi, genel kurul, defterler, icra ekranları
      (2026-09-26, `8d9528d`). Mobil kaldı.

---

# Sıradaki fazlar (özet)

Ayrıntı: `tasks/roadmap.md`

| Faz | Kapsam | Durum (2026-09-13) |
|---|---|---|
| FAZ 0 | Dürüstlük onarımı | **Tamamlandı** — uydurma veri ve sahte başarı mesajı kalmadı |
| FAZ 1 | Kurulabilirlik — migration çalıştırıcı, idempotency, portlar, CI | **Tamamlandı** (1.6: geri alma yedekten geri yükleme ile, 2026-09-27) |
| FAZ 2 | Kimlik/yetki/izolasyon | **Tamamlandı (2026-09-14)** — gateway auth, site bazlı roller, sahiplik doğrulaması, RBAC, **jeton iptali (2.7)**, **TCKN/IBAN şifrelemesi (2.8)**, **RLS birinci dilimi (2.6)**. RLS kalan tablolara servis servis genişletilecek |
| FAZ 3 | Denetim izi + gözlemlenebilirlik | **Tamamlandı (2026-10-03).** Okuma kaydı (3.4) ve yapılandırılmış log (3.5) uçtan uca sınanıyor |
| FAZ 4 | Para doğruluğu | **Çekirdek tamam** — ödeme borçtan düşüyor, kuruş dağıtımı, gecikme tazminatı. Kalan: bakiye testi (4.12), tam kuruş göçü (4.13) |
| FAZ 5 | 22 mock servisi gerçeğe çevirme | **TAMAMLANDI (2026-09-14)** — 20 servis gerçek veri katmanında; 2 servis (banka, toplantı sihirbazı) gerekçeli kapsam kararıyla 501 |
| FAZ 6 | Yönetişim katmanı (KMK) | **Çekirdek tamam** — işletme projesi, genel kurul, defterler, icra. Kalan: arayüzler (6.7) |
| FAZ 7 | Uyum ve operasyonel derinlik | Başlamadı |
| FAZ 8 | Ölçek ve ticarileşme | Başlamadı |

---

# Karar bekleyen bloklayıcılar — KALMADI

`tasks/questions.md`'deki **18 sorunun tamamı 2026-09-13'te yanıtlandı** ve yanıtlar
uygulandı. Bloklayıcı yok; kalan işler yalnızca iş gücü meselesi.

Uygulanan kararların özeti:

| # | Karar | Uygulanma |
|---|---|---|
| S-01 / S-01b | WSL kullan, ne gerekiyorsa kur | Go 1.24.7 + Flutter 3.47.4 kuruldu |
| S-02 | Finans şeması dondurması **iptal** | 012/013/014 migration'ları yazıldı |
| S-03 | 22 mock servisin **hepsini tamamla** | **8/22 tamamlandı** (2026-09-13); kalan 14'ü dürüstçe 501 |
| S-04 | Her iki KVKK modelini de destekle | Veri modeli site bazlı; hukuki metin taslak işaretli |
| S-05 | Mevzuatı araştır, parametre yap | `legal_parameters` + `pkg/legalparams` (26 parametre) |
| S-06 | Sağlayıcıdan bağımsız ödeme arayüzü | `payment_gateway_ready:false` + yönetici onay akışı |
| S-07 / S-08 | Banka ve e-fatura **sonraki sürüme** | Yapılmadı (karar gereği) |
| S-09 | Oracle/Cloudflare/AWS uyumlu depolama | **Tamamlandı** — `pkg/storage` (local + S3/SigV4, harici bağımlılık yok) |
| S-10 / S-11 | Sağlayıcı bağımsız bildirim + AI yalnız backend | **Yapılmadı** — sıradaki iş |
| S-12…S-16 | Varsayılanları uygula | Veri modeli çok siteli; blok bazlı gider destekli |
| S-17 | Her madde sonrası commit, bölüm sonunda push | Uygulanıyor — **push kimlik bilgisi gerekiyor** |
| S-18 | Kök `ROADMAP.md`/`CHANGELOG.md` işaretçi olsun | Uygulandı |

---

# FAZ 5 — modül dönüşüm durumu (S-03: "hepsini tamamla")

Her modül için ölçüt: gerçek veri katmanı + RBAC + KVKK sınırı + `verify-stack.sh`
içinde kendi adımı. Bir modül baştan sona bitmeden diğerine geçilmez (dikey dilim).

| # | Modül | Durum | Doğrulama adımı |
|---|---|---|---|
| 1 | gider (expense) | **Tamamlandı** | §12 |
| 2 | personel | **Tamamlandı** | §13 |
| 3 | ziyaretçi | **Tamamlandı** | §14 |
| 4 | otopark | **Tamamlandı** | §15 |
| 5 | rezervasyon | **Tamamlandı** | §16 |
| 6 | kargo (package) | **Tamamlandı** | §17 |
| 7 | sözleşme | **Tamamlandı** | §18 |
| 8 | belge arşivi | **Tamamlandı** | §19 |
| 9 | demirbaş (asset) | **Tamamlandı** | §20 |
| 10 | stok (inventory) | **Tamamlandı** | §21 |
| 11 | anket (survey) | **Tamamlandı** | §22 |
| 12 | sayaç/IoT + ısı payı | **Tamamlandı** | §23 |
| 13 | bildirim (notification) | **Tamamlandı** (S-10) | §24 |
| 14 | devriye (patrol) | **Tamamlandı** | §25 |
| 15 | duyuru + ilan panosu | **Tamamlandı** | §26 |
| 16 | ayarlar (settings) | **Tamamlandı** | §27 |
| 17 | enerji analitiği | **Tamamlandı** (YZ yok) | §28 |
| 18 | akıllı tahsilat | **Tamamlandı** (YZ yok) | §28 |
| 19 | NPS | **Tamamlandı** | §29 |
| 20 | ESG / karbon | **Tamamlandı** (katsayı kullanıcıdan) | §29 |
| 21 | banka (banking) | **Yazılmadı — S-07 kullanıcı kararı**; 501 + gerekçe | §29 |
| 22 | toplantı sihirbazı | **Yazılmadı — governance ile tekrar**; yönlendirir | §29 |

### Bu fazda bilerek YAPILMAYANLAR (gerekçeli)

| Konu | Neden |
|---|---|
| Banka entegrasyonu | S-07: kullanıcı sonraki sürüme bıraktı. Ayrıca API sözleşmesi ve alan şifrelemesi (2.8) yok; yanlış eşleştirme sakinin borcunu siler |
| Toplantı sihirbazı | Governance'ta zaten var; ikinci tablo karar defterinin tekliğini (KMK m.32) bozar |
| Ses kaydı / transkript / AI özet | Altyapı yok; ayrıca genel kurul ses kaydı KVKK m.5-6 kapsamında ayrı dayanak ve açık rıza sorunu doğurur |
| IoT sensör uçları | Zaman serisi deposu (MongoDB) kurulu değil, `go.mod`'da bile yok |
| Entegrasyon kimlik bilgisi kasası | Alan düzeyinde şifreleme (2.8) olmadan sağlayıcı anahtarı saklanmaz |
| Bileşik "sürdürülebilirlik skoru" | Kabul görmüş formülü yok; uydurma ağırlıkla üretilen sayı bir şey ölçmez |

---

# Sıradaki işler (öncelik sırasıyla)

FAZ 5 ve FAZ 2'nin çekirdeği bittiği için öncelik arayüzlere ve RLS'in
yaygınlaştırılmasına kayıyor.

1. ~~**RLS'i kalan tablolara yay (2.6 devamı).**~~ **TAMAMLANDI (2026-09-26).**
   81 tablo; kimlik rolü; dağıtım dosyaları (`gen-deploy.py`) tek kaynaktan.
   **Kalan küçük işler:**
   - **TAMAMLANDI (2026-09-27):** Kong tek yukarı akış (gateway) + kenar sınırları. Eski not: `kong/kong.yml` artık isteğe bağlı profil; rotaları gateway'le birebir
     değil. Ya gateway'e yönlendiren tek rotaya indirilmeli ya da kaldırılmalı.
   - ~~`legal_parameters` site bazlı istisna satırları RLS dışında (salt-okur).~~ **TAMAMLANDI (2026-09-27, 029)** — çözümleyici kapsamlı; RLS 82 tablo.
     `pkg/legalparams` çözümleyicisi kapsamsız havuz kullanıyor; RLS açılırsa
     site istisnaları SESSİZCE yok sayılırdı. Önce çözümleyici kapsamlı olmalı.
2. ~~**FAZ 6.7 — yönetişim arayüzleri.**~~ **TAMAMLANDI** (`8d9528d`: işletme projesi, genel kurul, defterler, mevzuat ekranları; 2026-10-03 tsc/lint/build temiz). Eski not: Governance servisi API olarak hazır ama
   panelde ekranı yok: işletme projesi, genel kurul, karar defteri.
3. ~~**Modülleri bildirim altyapısına bağlama.**~~ **TAMAMLANDI (2026-09-14).**
   Duyuru, rezervasyon onay/red, kargo, anket yayını, ziyaretçi girişi ve
   düşük stok uyarısı uygulama içi bildirim üretiyor. Alıcı kümesi
   `pkg/notify/audience.go`'da tek yerde.
   **Kalan:** devriye aksaması, sözleşme ihbar penceresi ve gecikmiş aidat
   için bildirim yok. Bunlar bir olay anına değil ZAMAN geçmesine bağlı
   olduğu için zamanlanmış bir iş (scheduler) gerektiriyor.
   **TAMAMLANDI (2026-09-26) — `cmd/scheduler` (migration 028).** Gecikmiş aidat
   (daireye ayda en fazla bir), sözleşme ihbar son günü / süresi dolmuş ACTIVE
   sözleşme, süresini aşan açık devriye; eksik/çok hızlı tur olay bildirimi.
   Tekrar yok (`dedupe_key`), çok kopyada advisory lock, `-once` kipi, `/health`.
   **Kanıt:** `verify-stack.sh` adım 40 (15 kontrol) — iki site yalıtımı, ikinci
   turda sıfır yeni kayıt. **Bilinçli sınır:** planlı tur saatleri
   (`patrol_routes.schedule_times`) API'de tanımlanamıyor; "hiç başlatılmamış
   planlı tur" ölçülemez ve uydurulmaz.
4. ~~**Panel ve mobil arayüzler.**~~ **TAMAMLANDI** — panel: 34 ekran gerçek API sözleşmesine bağlı (`8d9528d`). Eski not: 20 gerçek modülün çoğunun panelde karşılığı yok.
   **Mobil TAMAMLANDI (2026-09-27):** iki uygulama da gerçek API sözleşmesine bağlı
   (sakin 24, yönetici 21 test; `verify-mobile.sh` 10/10). **Belge açma TAMAMLANDI (2026-10-03, D3):**
   indir → SHA-256 doğrula → geçici dizin → cihaz uygulaması. Cihazda elle denenmedi (emülatör yok).
   **Release manifestlerinde INTERNET izni yoktu** → eklendi, verify-mobile denetliyor.
5. **FAZ 3 kalanı** — **3.4 TAMAMLANDI (2026-10-03).** Eski not: hassas veri okuma logu belge ve personel için yapıldı
   (`document_access_logs`, `PII_REVEAL`); sakin uçlarına da genişletilecek.
   Yapılandırılmış log (3.5).
6. ~~**Panelde çıkış (logout) düğmesi yok**~~ **TAMAMLANDI** — başlık menüsünde
   çıkış düğmesi erişim ve yenileme jetonunu iptal eder; şifre değiştirme de var.
7. ~~**1.6 migration geri alma (down) betikleri.**~~ **TAMAMLANDI (2026-09-27)** — yedek/geri yükleme yordamı, adım 41.
8. **Anahtar yönetimi.** **Döndürme TAMAMLANDI (2026-10-03)** — anahtar halkası,
   `cmd/rotate-pii`, `docs/runbook-anahtar-dondurme.md`, verify adım 42 (1012/1012).
   **Kalan:** anahtar deposu (vault/KMS) seçimi kullanıcı kararı bekliyor (questions S-19).
   Eski not: `PII_ENCRYPTION_KEY` ve `siteeksen_app` parolası bugün
   ortam değişkeniyle veriliyor. Üretim için anahtar deposu (vault) ve anahtar
   döndürme (rotation) yordamı yazılmalı — şifreli veriyi yeniden şifrelemek
   gerekeceği için bu, planlanması gereken bir iştir.
9. ~~**İlan panosu bildirimleri.**~~ **TAMAMLANDI (2026-09-27)** — ayrıca denetçinin ilan kapatma/yorum gizleme açığı kapatıldı. Yeni ilan yönetime, onay/ret ilan sahibine bildirim
   üretmiyor (yanıt "BİLDİRİM GÖNDERİLMEDİ" diyor). `pkg/notify` ile bağlanmalı.
10. ~~**Eskimiş sunucu notları.**~~ **TAMAMLANDI (2026-09-27)** — süre dolumu bilerek elle; zamanlayıcı bildirim üretir. `contract`/`bulletin` `expire-due` yanıtları "zamanlanmış görev
    altyapısı yoktur" diyor; `cmd/scheduler` artık var. Zamanlayıcı süre dolumunu yapıyorsa not
    düzeltilmeli, yapmıyorsa iş zamanlayıcıya eklenmeli.
11. ~~**`/dashboard/stats` yalnızca geliştirme gateway'inde.**~~ **ÇÖZÜLDÜ (2026-09-27)** — gateway her ortamda tek giriş; Kong ona yönlendirir. Üretim yolu (Kong) bu toplamayı
    yapmaz; Kong temizliği (madde 1) ile birlikte karara bağlanmalı.

---

# İnceleme notları

## 2026-10-11 — Altıncı tur: malik / kiracı / oturan ve gider sınıfı (KMK m.20, m.22, m.42-43; TBK m.302, 317, 341)

Kullanıcı kararları (2026-10-11):
- Her mali kalemde sınıf girişte seçilir: **KULLANIM** (oturan öder: kapıcı, temizlik, ısınma, ortak elektrik/su…) ya da
  **MALİK** (demirbaş, yenilik, havuz gibi yeni tesis, ana yapı onarımı). Uygulamadaki TÜM mali işler bu sınıfa uyar.
- Sakin kendi başına üye olamaz. Maliki yönetim kaydeder; yönetim malik olmadan kiracıyı da kaydedebilir; yalnız kiracıyla
  kayıtlı daireye malik sonradan davet edilir. Daire boş olabilir ama malik kayıtlı olmalı; boş dairede her şey malike düşer.
- Kiracıyı malik ya da yönetim SMS + e-postayla davet eder. Dairede aktif kiracı varken davet gönderilemez (yönetim dahil).
- Hane üyesi olur (oturanın hanesi). Devirden sonra malik o dairede kullanım işlemi (talep, rezervasyon, ziyaretçi…) yapmaz.
- Devirden sonra malikin göreceği seçenekli alanları malik DEĞİL yönetim belirler; site bazında tek politika, varsayılan en dar,
  değişiklik kurul üyesi onayı ister; kiracı malikin neyi gördüğünü görür.
- Kiracılık bitişi: malik isterse kiracı onayı şart. Yönetim yolu: belge (UYAP kodu isteğe bağlı), kimlik bilgisiyle onay,
  1 hafta itiraz.

Varsayılan kararlar (kullanıcı aksini söyleyene kadar; `questions.md`'ye işlenecek):
- V1 Kiracı kendi çıkışını malik onayı olmadan yapar (oturanın hakkı); malike bilgi gider.
- V2 Yönetim yolunda itiraz edilirse işlem askıda kalır; yalnız kiracının onayıyla ya da yeni bir belgeyle (yeni 7 gün) ilerler.
  İşlemi başlatan, o dairenin maliki olamaz. Sahte çıkarsa kiracılık geçmişiyle geri açılır.
- V3 Malik kaydı olmayan dairede MALİK sınıfı borç "malik kaydı yok" uyarısıyla yönetimde bekler; kiracıya yansımaz.
- V4 Hane üyesi kullanım özelliklerini kullanır, mali ekranları görmez; oturanın kaydı bitince düşer.
- V5 Mevcut veride aktif kiracısı olan dairede kiracı, olmayanda malik "oturan" sayılır; yönetim düzeltebilir.
- V6 Borcun sorumlusu tahakkuk anında saptanır (sınıf + o günkü oturan); kiracılık bitince açık KULLANIM borcu malike de görünür
  (KMK m.20 asıl sorumlu malik).

Aşamalar (her biri ayrı commit, verify-stack + gerekirse verify-mobile + panel):
- [x] **D1 Gider sınıfı** (verify 1320/1320, panel tsc/lint) — 066: `expense_categories.default_liability`, `expenses.liability`, `operating_budget_items.liability`,
  `assessment_details.liability`, `monthly_assessments.liability`; dönem benzersizliği (bölüm, dönem, sınıf). Elle tahakkuk,
  işletme projesinden tahakkuk, devir bakiyesi ve gider kaydı sınıfı alır; bir bölüme dönem başına sınıf başına bir tahakkuk.
- [x] **D2 Daire oturum modeli** (verify 1325/1325, panel tsc/lint) — 067: `units.owner_occupied`, HOUSEHOLD rolü (şemada;
  ekleme D3), `unit_occupancy()` / `resident_is_occupant()` (durum saklanmaz, kayıtlardan hesaplanır: KİRACI OTURUYOR /
  MALİK OTURUYOR / BOŞ / KAYITSIZ; boş daire tanım gereği malikli). Panel: Oturum sütunu, "kiracı yokken" seçimi, malik
  kaydı yok uyarısı, sakinlerde "Oturan". **D3'e taşındı:** daire başına tek aktif kiracı kısıtı — mevcut kiracı ekleme
  akışları (ve verify'daki çoklu kiracılı fixture'lar) davet akışıyla birlikte değişecek.
D3 kullanıcı kararları (2026-10-11): (1) Davet edilen kişinin hesabı yoksa hesap HEMEN açılır, etkinleştirme kodu SMS +
e-postayla gider; kişi kodu girince (hesabını etkinleştirince) davet kabul edilmiş olur ve devir gerçekleşir. Hesabı olan kişi
uygulamada kabul eder. (2) Hane üyesini dairede oturan ve yönetim ekler; kiracılı dairede malik ekleyemez. (3) Yönetim kiracıyı
doğrudan da kaydeder, davet de gönderir; ikisinde de aktif kiracı varken engel. (4) Kiracı gelince malikin o dairedeki hane
üyelerinin kaydı biter (pasif, iz kalır).
- [x] **D3 Kayıt ve davet** (verify 1331/1331, mobil 10/10, panel tsc/lint) — yönetim maliki/kiracıyı kaydeder; malik ya da
  yönetim kiracıyı SMS + e-postayla davet eder (dolu dairede engel); kiracı kodla katılır, kabulde devir; kiracılı daireye malik
  daveti; hane üyesi daveti. B5'in doğrudan ekleme/bitirme uçları kaldırıldı.

### Kalan plan (2026-10-11, kullanıcı: "önce planla sonra uygula")

İlke: her madde kendi arayüzüyle (panel + sakin uygulaması) birlikte biter; ayrı commit; verify-stack + verify-mobile + panel
tsc/lint. Sıra: D4 → D5 → D6 → D7 → D8. Kararlar: V1–V6 (yukarıda) ve aşağıdaki V7–V9 (varsayılan; kullanıcı aksini
söyleyene kadar). Kullanıcı cevabı (2026-10-11, 5. soru): UYAP doğrulama kodu olmayan belgeler de var → kod isteğe bağlı;
1 hafta itiraz yolu ve kimlik bilgisiyle onay kalır.

- V7 Yönetim yolunda ikinci onaycı ZORUNLU DEĞİL (kullanıcı yalnız itiraz + kimlik onayını tuttu). Koruma: başlatan o dairenin
  maliki/vekili olamaz, şifre yeniden girilerek beyan, belge kiracıya açık, itirazla askı, geri alma.
- V8 Kiracılık bitince daire "boş" olur (`owner_occupied=false`); malik oturuyorsa yönetim ya da malik değiştirir. Kiracının
  hanesinin kaydı da biter.
- V9 Görünürlük politikasının seçenekli alanları (hepsi varsayılan KAPALI): kiracının adı ve maskeli telefonu; kiracı
  sorumluluğundaki kullanım borcunun toplamı; vadesi geçen kullanım borcu ve malike uyarısı; dairenin arıza/talep kayıtları.
  Her zaman görünür (seçenek değil): malik sınıfı borçlar, genel kurul/oy, dairenin oturum durumu, kiracılık bitiş süreçleri,
  kiracılık bitmişse açık kullanım borcu (V6). Hiç görünmez: ziyaretçi, kargo, sayaç/pusula ayrıntısı, hane üyeleri.

- [x] **D4 Kiracılık bitişi** (verify 1341/1341, mobil 10/10, panel tsc/lint) — 069 `tenancy_end_requests` (yalnız kimlik servisi, RLS, silme yok):
  tür OWNER_REQUEST / TENANT_EXIT / MANAGEMENT; durum PENDING_TENANT / OBJECTION_WINDOW / SUSPENDED / COMPLETED / REJECTED /
  CANCELLED / REVERSED; kiracı bağı başına tek açık istek.
  - Malik isteği → kiracı onaylar (biter) ya da reddeder (kalır); malik bekleyen isteğini iptal eder.
  - Kiracının kendi çıkışı (V1) → hemen biter; maliklere SMS/e-posta bilgisi.
  - Yönetim yolu: yönetici/kurul üyesi, o dairenin maliki/vekili DEĞİLSE; belge (PDF/görsel, `pkg/storage`; depo yoksa 503),
    belge türü, UYAP kodu isteğe bağlı, gerekçe, şifre yeniden girilerek beyan (TCK m.204–207 uyarısı, IP ve zaman kaydı).
    7 gün itiraz penceresi; kiracı belgeyi görür, itiraz ederse SUSPENDED; askıdaki istek yalnız kiracı onayıyla ya da yeni
    belgeyle (yeni 7 gün) ilerler; süre itirazsız dolunca yönetim "tamamla" der; sahte çıkarsa "geri al" kiracılığı açar.
  - Bitişte: kiracı bağı pasif + bitiş tarihi, hanesi biter (tetikleyici), daire boş (V8).
  - Yönetimin PATCH ile aktif kiracıyı pasifleştirmesi / kiracı rolünü değiştirmesi kapanır (409 → bitiş akışı).
  - Kimlik servisi bildirim tablosuna yazamaz: tarafa SMS/e-posta doğrudan + uygulamada istek listesi; işlemler denetim izinde.
  - Arayüz: panel "Kiracılık bitişleri" (yönetim yolu, tamamla, geri al, belge); sakin uygulaması istekler ekranı (onay/ret/
    itiraz, belgeyi görme), kiracının "çıkışımı bildir", malikin "kiracılığın bitmesini iste".
- [x] **D5 Mali yönlendirme** (verify 1348/1348, mobil 10/10, panel tsc/lint) — 070: `monthly_assessments.tenant_link_id` (KULLANIM borcu kiracılıkta tahakkuk ettiyse o kiracı
  bağı; V6 anlık görüntü). Eski veride: dairenin şu anki aktif kiracısı, dönemi kiracılık başlangıcından sonraysa (V5).
  - Görünürlük kuralı tek SQL işlevinde (`assessment_visible_to(assessment, user)`): kiracı yalnız kendi kiracılığının kullanım
    borcu; malik/vekil malik sınıfı + kendisine düşen kullanım borcu + kiracılığı bitmiş açık kullanım borcu; hane üyesi hiç.
  - Sakin borç listesi/özet, ödeme ve kart ödemesi yetkisi, alacak dekontları, borcu yoktur belgesi (malik tam; kiracı yalnız
    kendi kullanım borcu) bu işlevle; yeni borç / tahsilat / gecikme bildirimleri borcun sorumlusuna.
  - V3: maliksiz dairede malik sınıfı borç yönetim listesinde "malik kaydı yok" ile; kimseye bildirim gitmez.
  - Yönetim: borçlu listesi, tahakkuk özeti ve PDF/Excel dökümleri sınıf + sorumlu sütunuyla.
  - Arayüz: panel tahakkuk/borçlu sütunları; sakin uygulamasında borçlarda sınıf etiketi.
- [x] **D6 Görünürlük politikası** (verify 1353/1353, mobil 10/10, panel tsc/lint) — 071 `owner_visibility_policies` (site başına tek etkin sürüm + değiştirilemez geçmiş):
  V9 seçenekleri, varsayılan hepsi kapalı. Yönetim önerir, öneren dışında bir KURUL ÜYESİ onaylayınca yürürlüğe girer; etkilenen
  kiracılara bildirim. Uygulama: kimlik servisi (kiracı adı/telefonu), finans (kiracı borç toplamı, vadesi geçen uyarısı),
  topluluk (daire talepleri), zamanlayıcı (malike vadesi geçen uyarısı). Kiracı ve malik politikayı uygulamada görür.
  - Arayüz: panel politika sayfası (öner/onayla/geçmiş); sakin uygulamasında "Malikim neyi görüyor".
- [x] **D7 Kullanım hakkı** (verify 1359/1359, mobil 10/10) — 072 `resident_can_use()`: kiracı ve hane üyesi kullanır; malik/vekil
  yalnız dairede aktif kiracı yokken (malik oturuyor ya da boş — boş dairede her şey malike düşer). Bağlananlar: talep, ziyaretçi
  ön kaydı (önceden daireyle ilişki HİÇ denetlenmiyordu), araç, kargo listesi, rezervasyon, acil durum kartı/yanıtı, sayaç,
  pusula ve itiraz, tüketim verisi (para içerenlerde hane üyesi hariç — V4); kargo ve ziyaretçi bildirimleri
  `notify.UnitUsers`. **Bilerek kapsam dışı:** ilan panosu (malik satılık/kiralık ilanı verebilir), anket/NPS (anket servisi
  malik oyunu ayrıca sayar), tadilat izni (malik/vekil başvurur — kiracının tadilatı malik iznine bağlı, TBK m.321), kural
  ihlali bildirimi (malik de muhatap). Mobil: sunucunun 403 nedeni artık kullanıcıya gösteriliyor.- [x] **D8 Kapanış** (panel tsc/lint/build temiz; verify 1359/1359; mobil 10/10) — `questions.md`'ye V1–V9; `legal/kvkk-aydinlatma.md` (bitiş belgeleri, görünürlük politikası, davet
  verisi); CLAUDE.md ve changelog; uçtan uca gözden geçirme (panel build dahil).
**Altıncı tur sonucu (2026-10-11):** D1–D8 tamamlandı — migration 066-072, verify-stack **1359/1359**, verify-mobile
**10/10**, panel tsc/lint/build temiz, RLS 123 tablo. Kararlar ve varsayılanlar `questions.md` S-23. Kullanıcı girdisi
bekleyenler değişmedi: B10 (destek kanalı), B11 (Firebase), iyzico sandbox anahtarı, Netgsm/SMTP gerçek hesap, PTS protokolü,
defter baş özetinin dış çapası.
## 2026-10-10 — Beşinci tur (Şikayetvar raporu: uygulama aksaklıkları)

Kaynak: `apsiyon_urun_gelistirme_raporu.md` §6.6 (koddan doğrulanmış eksikler). Kapsam kararı (kullanıcı,
2026-10-10): yalnızca uygulama aksaklıkları ve olsa iyi olacaklar; komisyon, fiyat, faiz/gecikme tazminatı,
sözleşme politikasına dokunulmaz. Her madde ayrı commit; her backend maddesinden sonra verify-stack,
mobil maddelerden sonra verify-mobile, panel maddelerinden sonra tsc+lint+build.

- [x] **B1 Yeni borçta sakine bildirim** (verify 1274/1274) — `pkg/notify/charges.go`: verilen tahakkuk kimliklerinden daire
  bazında bildirim (dönem/devir, tutar, son ödeme; uygulama içi + SMTP varsa e-posta; dedupe `charge:<id>`).
  Üç tahakkuk noktası: finance `POST /assessments`, finance `POST /opening-balances`, governance
  `POST /budgets/:id/assessments`. Yanıta `notification` sayaçları. verify: bildirim kaydı, taşınmış sakine
  gitmemesi, ikinci çağrıda çift kayıt olmaması.
- [x] **B2 Yöneticinin tahsilat girişi** (verify 1280/1280, mobil 10/10) — migration 061 (`payments.recorded_by`, korumaya eklenir).
  `POST /finance/collections` {unit_id, assessment_ids, payment_method BANK_TRANSFER|CASH, value_date,
  reference}: ödeme açılır ve aynı işlemde onaylanır (defter zinciri). Ekstrede eşleşmeyen satır
  `assessment_ids` ile doğrudan daireye işlenir. Daire sakinine "ödemeniz kaydedildi" bildirimi.
  Panel: muhasebede "Tahsilat gir" + ekstre satırında "Daireye işle"; yönetici uygulaması: tahsilat formu.
- [x] **B3 Şifremi unuttum (self-servis)** (verify 1284/1284, mobil 10/10) — `POST /auth/password-reset/request` {phone}: hesap var mı
  söylenmez; kod SMS + e-postayla gider; sıklık sınırı (60 sn, saatte 3). Kod mevcut etkinleştirme
  ekranında girilir. SMS/e-posta yapılandırılmamışsa bunu açıkça söyler. Üç istemcide "Şifremi unuttum" →
  numara ekranı.
- [x] **B4 Sakinin kendi telefon/e-posta değişikliği** (verify 1291/1291, mobil 10/10) — e-posta: mevcut şifreyle; telefon: şifre + yeni
  numaraya SMS kodu (sahiplik kanıtı), onayda diğer oturumlar kapanır, eski numaraya uyarı. Çok siteli kişi
  çıkmazının mesajı bu akışa yönlendirir. Mobil profildeki "henüz hazır değil" satırları çalışır.
- [x] **B5 Malikin kiracı yönetimi** (verify 1294/1294, mobil 10/10) — malik kendi dairesine kiracı/vekil ekler ve
  kiracılığı bitirir; yönetime ayrı bildirim yok (kimlik servisi bildirim tablosuna erişemez), işlem denetim izinde. Sakin uygulamasında "Dairem" bölümü.
- [x] **B6 Kademeli giriş kilidi** (verify 1296/1296) — 5. hata 30 sn, 6. hata 2 dk, 7.+ hata 15 dk; yanıt kalan süreyi
  SÖYLEMEZ (hesap/kilit varlığı sızardı), kademeleri sabit metinle anlatır.
- [x] **B7 İlişik kesme tarihi** (verify 1300/1300) — pasifleştirmede `resident_units.end_date` (isteğe bağlı tarih, varsayılan
  bugün), yeniden etkinleştirmede temizlenir; panel listesinde görünür. Changelog satır 231 düzeltilir.
- [x] **B8 Fatura sapma uyarısı + itiraz** (verify 1305/1305, mobil 10/10) — paylaştırmada kullanım alanı başına tüketim site medyanının
  3 katını aşan bölümler listelenir, yayım yönetici teyidi ister. Sakin tüketim pusulasına itiraz eder,
  yönetim yanıtlar, iki tarafa bildirim (063). Panel sayaç sayfası + sakin enerji ekranı.
- [x] **B9 Havale bildirimine dekont dosyası** (verify 1309/1309, mobil 10/10) — sakin bekleyen ödemesine PDF/görsel ekler (`pkg/storage`),
  yönetim indirir. Mobil dosya seçici (yeni paket: `file_picker`).
- [ ] **B10 Yönetim → SiteEksen destek talebi** — KARAR BEKLİYOR (kullanıcı): talepleri SiteEksen tarafında kim, hangi
  kanaldan yanıtlayacak? Sistemde platform hesabı (SUPER_ADMIN) hiç tanımlı değil (seed/panel yok); bu bir işletme kararı.
- [ ] **B11 Push bildirim** — BAŞLANMAZ: Firebase projesi ve `google-services.json` kullanıcıdan (S-10).

**Tur sonucu (2026-10-11):** B1-B9 tamam; verify-stack **1309/1309** (yeni `gofmt` denetimi dahil), verify-mobile **10/10**,
panel tsc/lint/build temiz. 64 migration, RLS 119 tablo, RLS dışı 9 tablo. Açık: B10 (destek talebini kim/hangi kanaldan
yanıtlayacak — kullanıcı kararı), B11 (Firebase).

## 2026-10-05 — Dördüncü tur (kullanıcı kararları + TEST_RAPORU + Apsiyon şikâyetleri)

Kararlar (kullanıcı, 2026-10-05): S-22 → bordro mali müşavirden gelir, sistem ödeme ve maliyeti kaydeder;
S-21 → VERBİS opsiyonel, yükümlülük site yönetiminde; S-19 ve iOS → olduğu gibi kalır.

- [x] K1 kararları `questions.md`'ye işle
- [x] K2 bordro kaydı (S-22, FAZ 7.4) — 047, verify 1169/1169
- [x] K3 VERBİS beyanı (S-21) — opsiyonel, engellemez; verify 1170/1170
- [x] T1 tesis ekleme/düzenleme ucu + panel formu + demo tesis (TEST 2.1) — 048, verify 1174/1174
- [x] T2 m² zorunlu + paylaştırma öncesi eksik alan listesi (TEST 2.2) — 049, verify 1177/1177
- [x] T3 kargo teslim imzası/fotoğrafı depolamaya (TEST 2.3) — 052, verify 1188/1188, mobil 10/10
- [x] T4 SMS (Netgsm) + SMTP adaptörü (TEST 2.4) — sahte sağlayıcıyla uçtan uca (verify 1192/1192); gerçek gönderim için kullanıcı hesap bilgisi girecek
- [x] T5 sanal POS (iyzico) + 3D Secure dönüşü + ödeme durumu (TEST 2.5, BUG-09) — 060, sahte iyzico ile verify 1269/1269, mobil 10/10
- [ ] T5b iyzico sandbox anahtarıyla gerçek uçtan uca deneme — KULLANICI anahtarı bekliyor (kod hazır)
- [x] T6 PDF/Excel rapor motoru (TEST 2.6) — verify 1197/1197, mobil 10/10
- [x] T7 bütçe kesinleştirme — 7579 sonrası durum kanıtı (TEST 2.7) + projeden tahakkuk (050), verify 1182/1182
- [x] T8 ziyaretçi PIN/QR + hızlı doğrulama (TEST 2.8) — 051, verify 1182/1182, mobil 10/10
- [x] T9 panel mobil menü (TEST 6.2) — tarayıcı testi 412×915
- [x] A1 taşınan sakin (BUG-01) — mevcut koruma kanıtı + bildirim metni şeffaflığı; verify 1198/1198
- [x] A2 havale beyanında valör, gecikme tazminatı dondurma ve iz (BUG-02) — 053, verify 1201/1201
- [x] A3 finansal silinemezlik + ters kayıt (BUG-03) — 054, verify 1205/1205
- [x] A4 borcu yoktur belgesi + doğrulama (BUG-04) — 055, verify 1209/1209
- [x] A5 telefon değişimi / kod yeniden üretimi (BUG-05) — verify 1211/1211
- [x] A6 yönetici giriş kilidi kaldırma (BUG-06) — verify 1211/1211
- [x] A7 tüketim pusulası, sayaç değişimi, sapma uyarısı (BUG-07) — 056, verify 1229/1229, mobil 10/10
- [x] A8 cihaz canlılık izleme (BUG-08) — 057, verify 1240/1240 · bariyer uzaktan açma donanım protokolü bekliyor (kullanıcı)
- [x] A10 uluslararası telefon / geo-blok yok (BUG-10) — pkg/phone, verify 1243/1243, mobil 10/10 · Netgsm yurt dışı SMS paketi (kullanıcı)
- [x] A11 site pasifleştirme (BUG-11) — 058, verify 1248/1248
- [x] A12 alacak dekontu + banka ekstresi mutabakatı (BUG-12) — 059, verify 1258/1258, mobil 10/10

**Tur sonucu (2026-10-10):** verify-stack **1269/1269**, verify-mobile **10/10**, panel tsc/lint/build temiz;
60 migration, RLS 117 tablo. Açık kalan yalnızca kullanıcı girdisi bekleyenler: T5b (iyzico sandbox anahtarı),
PTS bariyer komut protokolü (A8 uzaktan açma), Netgsm/SMTP hesapları, defter baş özetinin dış çapası.

## 2026-10-04 — Üçüncü tur (tamamlandı)

**Bitti (commit d71a4ea):** İşletme projesi 7579 s. Kanuna uyumlu (036): genel kurul onayı, geçici proje
3 ay, yeniden değerleme tavanı, zamanlayıcı hatırlatması. verify-stack 1098/1098, verify-mobile 10/10.

**Bitti:** FAZ 7.5 tadilat izni (037), ayar koruması (038), kural ihlali (039), acil durum ve afet (040), vergi/SGK takvimi (041), ortak alan geliri (042), KVKK saklama/imha (043), 4.13 para aritmetiği, 3.6 metrik/hata takibi (044), 7.2 DASK/hasar (045), kamera/biyometrik envanteri (046) — verify-stack 1165/1165, verify-mobile 10/10.
- Kalan: 7.4 bordro (S-22 kararı bekliyor). Kullanıcı kararı bekleyen: S-19, S-21, S-22, iOS paket kimliği.

**Not:** dev-up ve panel (`npm run dev`) arka planda çalışıyor; dev DB 036/037'yi içermiyor (yeniden başlatınca uygulanır).
## 2026-10-04 — Kurulum, görevlendirme, devir, KVKK, saat dilimi (otonom, ikinci tur)

**Doğrulama:** `verify-stack.sh` **1090/1090**, `verify-mobile.sh` **10/10** (sakin 27, yönetici 27),
panel `tsc`/`lint`/`build` temiz, panel sözleşmesi 65 uç.

**Yapılan:** sakin daveti (S-20 kararı, 032); site kurulumu — kurucu yönetici, bölüm toplu ekleme (033);
görevlendirme API'si + oturum iptali; iş saat dilimi sabitlendi (gece yarısı gün kayması); toplu sakin
içe aktarma; devir bakiyesi (034); demirbaş bakım hatırlatması (7.1); liste kesilmesi bildirimi (B69);
yönetişimde kişi–daire bağı; KVKK ilgili kişi başvuruları + süre hatırlatması (035); paneller ve mobil ekranlar.

**Sıradaki (büyük):** 7.3 acil durum, 7.4 bordro/SGK (mevzuat oranları), 7.5 ihlal/tadilat izni,
7.6 ortak alan geliri, 7.7 vergi takvimi, 7.8 saklama/imha; 4.13 tam kuruş göçü; 3.6 metrik.
**Kullanıcı kararı bekleyen:** S-19 (sonra), iOS paket kimliği (sonra).

## 2026-10-03 — Anahtar döndürme, para doğruluğu ve güvenlik turu (otonom)

**Doğrulama (son durum):** `verify-stack.sh` **1042/1042**, `verify-mobile.sh` **10/10**
(sakin 24, yönetici 26 test), panel `tsc` + `lint` + `build` temiz. Her madde ayrı commit.

**Yapılan:** PII anahtar halkası + `cmd/rotate-pii` (todo 8); sakin bakiyesi herkes için 0'dı
(030); borçlu listesi daire bazlı (B55); çift bekleyen ödeme (4.5); tahsilat oranı kayan nokta
(B54); ödeme listesi ödemenin sitesine bağlı (B56) ve sayfalı (B69); tahakkuk dağıtımı kuruş +
sayaç kalemi sessiz dağıtımı (4.4/B70); **yetki yükseltme: daire bağı rolü jetona doğrulanmadan
giriyordu (031)**; başka sitenin hesabını sessizce bağlama (B25); talep `unit_id` (B63), talep/sakin
yarışları (B65), talep numarası çakışması (B71), tip dönüşümü panic (B75); okuma kaydı kanıtı (3.4);
mobil: release manifestinde INTERNET izni yoktu, belge açma, analiz uyarıları sıfır (0.C.6),
yönetici menüsü fail-closed (B26); sahte testler kaldırıldı (B96); 37 MB ikili depodan çıkarıldı.

**Kullanıcı kararı bekleyen:** S-19 (vault/KMS), S-20 (başka sitedeki kişiyi davetle ekleme),
`servicecore-api-doc/` klasörünün amacı, `ios/` için paket kimliği, git push kimlik bilgisi.

## 2026-09-13 — Dürüstlük tamamlandı, güvenlik ve yönetişim turu

**Yapılan:** `questions.md`'deki 18 sorunun tamamı yanıtlandıktan sonra kararlar
uygulandı. FAZ 0 (dürüstlük) ve FAZ 1 (kurulabilirlik) tamamlandı; FAZ 2 (güvenlik),
FAZ 4 (para doğruluğu) ve FAZ 6 (yönetişim) çekirdeği yazıldı.

**Doğrulama:** `verify-stack.sh` **102/102**, `verify-mobile.sh` **8/8**,
admin panel `tsc` + `lint` + `build` temiz.

**Bu turda bulunan ve denetimde yakalanmamış hatalar:**

1. `002_seed_data.sql` tekrar uygulanamıyordu (PK çakışması) — idempotency testi olmadığı
   için görülmemişti.
2. 004'teki `CREATE TRIGGER` idempotent değildi.
3. 003'ten `DROP TABLE audit_logs` kaldırılınca 001'in eski kolonları (`resource_type NOT NULL`)
   ortaya çıktı ve `pkg/audit` INSERT'ü kırıldı — 011'de tasfiye edildi.
4. Finance liste uçları iki farklı yanıt biçimi kullanıyordu (`[...]` ve `{"data": [...]}`);
   istemciler bu farkı bilmediği için **çalışan bir sunucuda bile** hata gösteriyordu.
5. `admin_app` API taban adresi yayında olmayan bir alan adına ve yanlış yola
   (`/v1` yerine `/api/v1`) gidiyordu → uygulama hiçbir ortamda çalışmıyordu.
6. Admin panelde ESLint yapılandırması yoktu; `npm run lint` etkileşimli soru sorup
   CI'da takılıyordu.

**Ders:** Bu altı hatanın hiçbiri kod okuyarak bulunamazdı; hepsi **çalıştırınca** ortaya
çıktı. Doğrulama betiği her tur genişletildiği için her yeni kontrol yeni bir hata buldu.

## 2026-09-09 — Denetim ve planlama turu

**Yapılan:** Tüm repo 5 paralel denetim ekseninde incelendi (backend servisleri, veri katmanı/altyapı,
admin panel, sakin mobil, yönetici mobil). 78 doküman iddiası kod kanıtına karşı test edildi.

**Sonuç:** İddiaların **%49'u yanlış**, %28'i kısmen doğru, %23'ü doğru.
25 servisin yalnızca 3'ü veritabanına bağlı; veritabanı temiz makinede kurulamıyor; denetim izi hiç
çalışmıyor; gateway'de kimlik doğrulama yok; para hesaplarında kritik hatalar var (bakiye kullanıcı
sayısıyla çarpılıyor, ödeme hiç tamamlanmıyor).

**Kök nedenler (asıl çözülen):**
1. "Tamamlandı" için kanıt zorunluluğu yoktu → `dogrulama-politikasi.md` ile kanıt seviyeleri (D0-D4) getirildi
2. Hatalar sessizce yutuluyordu → sessiz başarısızlık yasağı kuralı yazıldı
3. Kurulum tekrar üretilemezdi → FAZ 1'in tamamı buna ayrıldı
4. Tek doğruluk kaynağı yoktu (dokümanlar kendi içinde çelişiyordu) → `tasks/` tek kaynak, kök dosyalar işaretçi
5. Genişlik derinliğe tercih edilmişti (%77 ölü şema) → dikey dilim ilkesi getirildi

**Doğru yapılmış işler korundu:** identity `residents` modülü, `POST /users/me/properties` transaction'ı,
KVKK rıza akışı (backend), tahakkuk dağıtım matematiği, community talep durum makinesi ve sakin onayı,
PDF/Excel motoru, SMS/WhatsApp entegrasyon kodu, `unit_balances` view'ı, şema para tipleri (`DECIMAL`),
`.gitignore` hijyeni. Ayrıntı: `audit-raporu.md` §4.

**Not:** Bu turda hiçbir kaynak kod dosyası değiştirilmedi — yalnızca `tasks/` altındaki planlama
dosyaları yazıldı ve `.agents/AGENTS.md` silinmesi (kullanıcı tarafından) doğrulandı.
