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
- [ ] **1.6 Down (geri alma) betikleri** — `cmd/migrate` ileri yönlüdür; geri alma yok.

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
- [ ] **3.4 Hassas veri okuma logu** (TCKN, maaş, sır gösterme)
- [ ] **3.5 Yapılandırılmış log + istek kimliği** (`request_id` kolonu hazır, üretimi eksik)

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
- [ ] **4.12 Bakiye için sayısal doğruluk testi** — dağıtım testleri yazıldı; `unit_balances`
      view'ı için veritabanı destekli sayısal test hâlâ eksik.
- [ ] **4.13 Mevcut `float64` para alanlarının kuruşa göçü** — yeni kod kuruş kullanıyor,
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
- [ ] **0.C.6 🟡 `flutter analyze` bilgi (info) düzeyi uyarıları** — iki uygulamada ~450
      `prefer_const` / `withOpacity` uyarısı. CI'da kapı DEĞİL (`--no-fatal-infos`).

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
| FAZ 1 | Kurulabilirlik — migration çalıştırıcı, idempotency, portlar, CI | **Tamamlandı** (1.6 down betikleri hariç) |
| FAZ 2 | Kimlik/yetki/izolasyon | **Tamamlandı (2026-09-14)** — gateway auth, site bazlı roller, sahiplik doğrulaması, RBAC, **jeton iptali (2.7)**, **TCKN/IBAN şifrelemesi (2.8)**, **RLS birinci dilimi (2.6)**. RLS kalan tablolara servis servis genişletilecek |
| FAZ 3 | Denetim izi + gözlemlenebilirlik | Çalışıyor. Hassas veri okuma logu (3.4) **belgeler için yapıldı** (`document_access_logs`); diğer hassas uçlar ve yapılandırılmış log (3.5) kaldı |
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
   - `kong/kong.yml` artık isteğe bağlı profil; rotaları gateway'le birebir
     değil. Ya gateway'e yönlendiren tek rotaya indirilmeli ya da kaldırılmalı.
   - `legal_parameters` site bazlı istisna satırları RLS dışında (salt-okur).
     `pkg/legalparams` çözümleyicisi kapsamsız havuz kullanıyor; RLS açılırsa
     site istisnaları SESSİZCE yok sayılırdı. Önce çözümleyici kapsamlı olmalı.
2. **FAZ 6.7 — yönetişim arayüzleri.** Governance servisi API olarak hazır ama
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
4. **Panel ve mobil arayüzler.** 20 gerçek modülün çoğunun panelde karşılığı yok.
5. **FAZ 3 kalanı** — hassas veri okuma logu belge ve personel için yapıldı
   (`document_access_logs`, `PII_REVEAL`); sakin uçlarına da genişletilecek.
   Yapılandırılmış log (3.5).
6. ~~**Panelde çıkış (logout) düğmesi yok**~~ **TAMAMLANDI** — başlık menüsünde
   çıkış düğmesi erişim ve yenileme jetonunu iptal eder; şifre değiştirme de var.
7. **1.6 migration geri alma (down) betikleri.**
8. **Anahtar yönetimi.** `PII_ENCRYPTION_KEY` ve `siteeksen_app` parolası bugün
   ortam değişkeniyle veriliyor. Üretim için anahtar deposu (vault) ve anahtar
   döndürme (rotation) yordamı yazılmalı — şifreli veriyi yeniden şifrelemek
   gerekeceği için bu, planlanması gereken bir iştir.

---

# İnceleme notları

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
