# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Çalışma Disiplini (Token ve Bağlam Yönetimi)

- **Token Tasarrufu:** Bu projeyi token tasarrufu yaparak yürüt. Uzun açıklamalar yapma. Özellikle istenmedikçe yaptıklarını detaylıca yazma. Sadece çok kısa ve net ne yaptığını ya da ne yapılacağını yaz.
- **Her Oturumda ve Her Promttan Sonra Oku:** Oluşturulan `.md`, `walkthrough.md` (geçmişte yapılan değişiklikleri, testleri ve doğrulamaları anlamak için) ve aşağıdaki dosyaların içlerindeki en son tamamlanan konuyu ya da maddeyi oku:
  - `tasks/roadmap.md`
  - `tasks/lessons.md`
  - `tasks/todo.md`
  - `tasks/changelog.md`
- **Tamamlanmamış ve Yapılacak Konuları Oku:** Aşağıdaki dosyalar için hem tamamlanmamış konuyu/maddeyi hem de yapılacak konuyu/maddeyi oku:
  - `tasks/todo.md`
  - `tasks/roadmap.md`
- **Dosya Oluşturma:** Bu `.md` dosyaları en başta oluşturulmamışsa ya da boşsa, oluştur ve içerisini doldur.
- **Varsayım Yok:** Kesinlikle varsayım yapma. Doğrulanabilir ya da doğrulanmış gerçek metotları dene. Gerçekçi davran. Bilmediğin, anlamadığın ya da bulamadığın şeyler için kullanıcıya sor, ne yapılacağına beraber karar verin.
- **Ustalık Yol Haritası:** Çalıştığın tüm konularda, projelerde ya da çalışmalarda dünya çapında uzman olmak için bir ustalık yol haritası oluştur. Bu yol haritasını `tasks/roadmap.md` dosyasına yaz. İlgili maddeler ya da konular tamamlandıkça tamamlandı olarak işaretle. En iyi %1'in kullandığı ama pek paylaşmadığı teknikleri, gizli kaynakları ve alışılmadık yaklaşımları dahil et.
- **Infinite Loop Prevention:** Eğer bir sorunu çözerken birkaç denemede başarılı olamazsan (sonsuz döngü), dur ve durumu kullanıcıya bildir. Birlikte karar verilecektir.
- **Eksiksiz İş Yapma:** İşi savsaklama, üşenme, verilen görevi eksik yapma, tam yap. Sadece örnekleri çalışır şekilde oluşturup kalanını çalışmayacak şekilde bırakma.

---

## Workflow Orchestration
### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update tasks/lessons.md with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes -- don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests -- then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

---

## Task Management

1. Plan First: Write plan to tasks/todo.md with checkable items
2. Verify Plan: Check in before starting implementation
3. Track Progress: Mark items complete as you go
4. Explain Changes: High-level summary at each step
5. Document Results: Add review section to tasks/todo.md
6. Capture Lessons: Update tasks/lessons.md after corrections

---

## Core Principles

- Simplicity First: Make every change as simple as possible. Impact minimal code.
- No Laziness: Find root causes. No temporary fixes. Senior developer standards.
- Minimal Impact: Only touch what's necessary. No side effects with new bugs.

---

## Proje Takip Dosyaları

Herhangi bir göreve başlamadan önce sırasıyla şu dosyalara bak:

1. **`tasks/dogrulama-politikasi.md`** — **ÖNCE BUNU OKU.** "Tamamlandı" ne zaman yazılabilir, kanıt
   seviyeleri (D0-D4), "Bitti" tanımı ve **sessiz başarısızlık yasağı**. `✅` işareti artık kullanılmaz.
2. **`tasks/roadmap.md`** — Yol haritası (9 faz), modül durumları ve ustalık yol haritası. **Tek kaynak**;
   kökteki `ROADMAP.md` yalnızca buraya işaret eder.
3. **`tasks/todo.md`** — Aktif iş kuyruğu.
4. **`tasks/audit-raporu.md`** — 2026-09-09 denetimi: hangi iddianın gerçek olduğu.
   *Bu tarihten önceki dokümanlarda yazılanlara güvenmeden önce buraya bak.*
5. **`tasks/gap-analizi.md`** — Modül durum matrisi, 97 numaralı mantık hatası (B01-B97), özellik bazlı eksikler.
6. **`tasks/modul-envanteri.md`** — Olması gereken 60 modülün mevzuat dayanaklı referans modeli.
7. **`tasks/questions.md`** — Kullanıcı kararı bekleyen konular (S-01…S-18) ve varsayılan kararlar.
8. **`tasks/lessons.md`** — Öğrenilen dersler.
9. **`tasks/changelog.md`** — Geçmişte ne yapıldığı (kanıtla). **Tek kaynak.**

Bu dosyalar okunduktan sonra ilgili kaynak dosyalara geç.

---

## Project Overview

**SiteEksen** — Türkiye kat mülkiyeti kanununa uyumlu site yönetim platformu. Go mikroservis backend,
Next.js admin paneli, iki Flutter mobil uygulaması (sakin + yönetici) içerir.

### Kritik Mimari Notlar — GERÇEK DURUM (2026-09-13 itibarıyla)

> Aşağıdaki notlar **çalıştırılarak** doğrulanmıştır. Bu bölümdeki hiçbir ifade "olması gerekeni"
> değil, **bugün gerçekte olanı** anlatır.
> Toplu kanıt: `bash backend/scripts/verify-stack.sh` → **886/886**,
> `bash backend/scripts/verify-mobile.sh` → **8/8**.
> Tarihçe ve `dosya:satır` kanıtı: `tasks/audit-raporu.md`, `tasks/changelog.md`.

**Hızlı başlangıç**

```bash
bash backend/scripts/dev-up.sh     # PostgreSQL + 24 servis + gateway (RLS'li app rolüyle)
cd admin && npm run dev            # http://localhost:3001
# Demo: 5551234567 / Demo123! (yönetici) · 5559876543 / Demo123! (kiracı)
```

- **FAZ 5 TAMAMLANDI (2026-09-14): 22 mock servisin tamamı ele alındı.**
  **20 servis gerçek veri katmanına bağlıdır:** `identity`, `finance`,
  `community` (talep + duyuru), `governance` (KMK yönetişim), `expense`,
  `personnel`, `visitor`, `parking`, `reservation`, `package` (kargo),
  `contract`, `document` (belge arşivi), `asset` (demirbaş), `inventory` (stok),
  `survey` (anket), `iot` (sayaç + ısı payı), `notification` (bildirim),
  `patrol` (devriye), `bulletin` (ilan panosu), `settings`,
  `energy_analytics`, `smart_collection`, `nps`, `esg`.
  **İki modül bilinçli olarak yazılmadı ve nedenini söyleyerek 501 döner:**
  `banking` (S-07 kullanıcı kararıyla sonraki sürüme bırakıldı) ve
  `meeting_wizard` (governance ile tekrar olurdu; oraya yönlendirir).
  Ayrıca `iot`'un sensör uçları ve `settings`'in kimlik bilgisi modülü gerçek
  değildir ve bunu açıkça bildirir.
- **Uygulama veritabanına SÜPER KULLANICIYLA BAĞLANMIYOR — dev-up, doğrulama,
  docker compose ve k8s'in dördünde de.** İki rol vardır:
  `siteeksen_identity` (yalnızca kimlik servisi: dizin + jeton iptal tabloları,
  site verisine erişim YOK) ve `siteeksen_app` (diğer 25 servis: RLS'e tabi,
  dizin tablolarını yalnızca okur, `users.password_hash`/TCKN sütunlarını
  göremez, denetim izini ve jeton iptalini silemez). Parolaları `cmd/migrate`
  `APP_DB_PASSWORD` / `IDENTITY_DB_PASSWORD` ile atar; depoya yazılmaz.
  RLS **81 tabloda** açık; dışarıda kalan 9 tablonun her biri gerekçelidir ve
  doğrulama listeyi birebir denetler. Tüm görünümler `security_invoker`
  (aksi hâlde görünüm sahibinin yetkisiyle RLS'i atlıyordu).
- **Dağıtım dosyaları tek kaynaktan üretilir:** `backend/scripts/gen-deploy.py`
  → 27 Dockerfile (root değil, uid 10001), `docker-compose.yml`, `k8s/*.yaml`,
  CI imaj matrisi. Elle düzenlenmez; `--check` kipi doğrulamada sapmayı yakalar.
  Compose zorunlu gizli değerler (`.env`, şablon `.env.example`) yoksa açılmaz.
- **Modüller artık gerçekten bildirim gönderiyor.** Altı modül `pkg/notify`
  üzerinden uygulama içi bildirim üretir. Alıcı kümesi (sakinler / daire
  sakinleri / yönetim) `pkg/notify/audience.go`'da tek yerde tanımlıdır:
  beş modül aynı sorguyu ayrı yazsaydı, birinde `is_active` filtresi
  unutulduğunda siteden taşınmış birine bildirim giderdi. Yanıtlar
  sayaçlarla döner; "gönderildi" sözcüğü yalnızca gerçekten gönderilen
  kayıt varsa geçer, sağlayıcısız kanallar "kuyrukta bekliyor" der.
- **"Yapay zekâ" iddiası kaldırıldı.** Enerji analizi, tahsilat riski ve karbon
  ayak izi GERÇEK hesaplar yapar ama YZ kullanmaz: formüller kodda yazılıdır,
  her sonuç gerekçesiyle döner. `ai_model_version`, `predictions`,
  `predicted_payment_probability` alanları bilerek boş bırakılır.
- **Dosya saklama artık var (S-09):** `pkg/storage`. Yerel dosya sistemi ya da S3
  uyumlu sağlayıcı (Oracle Object Storage / Cloudflare R2 / AWS S3). S3 imzalama
  (SigV4) harici bağımlılık olmadan, yalnızca stdlib ile yazıldı. Yapılandırma
  eksikse servis açılmaz — sessizce "yüklendi" demez.
- **Para hesapları `pkg/money` üzerinden, tam sayı KURUŞ ile yapılır.** Dağıtımda en büyük
  kalan yöntemi kullanılır; payların toplamı tutara birebir eşittir. Yeni para kodu
  `float64` kullanmaz.
- **Mevzuata bağlı hiçbir oran koda gömülmez.** Gecikme tazminatı, ısıtma paylaşımı,
  nisaplar ve vekâlet sınırları `legal_parameters` tablosundadır (`pkg/legalparams`);
  yürürlük tarihli ve hukuki dayanaklıdır. Kanunla sabit olanlar site bazında
  değiştirilemez (veritabanı tetikleyicisi).
- **Roller SİTE BAZLIDIR.** `users.roles` yalnızca platform rolleri içindir; site rolleri
  `property_roles`, sakinlik rolleri `resident_units` tablosundadır. Jeton rolleri aktif
  siteye göre üretilir.
- **Migration'lar `cmd/migrate` ile uygulanır** (sürüm tablosu, advisory lock, SHA-256
  sağlama, transaction). `docker-entrypoint-initdb.d` kullanılmaz. Uygulanmış bir
  migration dosyası **düzenlenmez** — çalıştırıcı sağlama uyuşmazlığında durur.
- ~~**Veritabanı temiz makinede KURULAMIYOR**~~ → **DÜZELTİLDİ (2026-09-12).** `004`/`005`'teki tablo
  çakışmaları ve `005`'teki geçersiz UUID giderildi. Sıfırdan kurulum artık çalışıyor: 11 migration,
  61 tablo. **Kanıt:** `bash backend/scripts/verify-stack.sh` → 42/42 kontrol geçti.
- ~~**Demo kullanıcı girişi çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Seed'deki bozuk bcrypt hash
  yeniden üretildi. Demo giriş: **`5551234567` / `Demo123!`** (ikinci hesap: `5559876543`).
  **Kanıt:** gerçek identity-service'e `POST /auth/login` → HTTP 200 + JWT; yanlış şifre → 401.
- ~~**Gateway'de kimlik doğrulaması yok**~~ → **DÜZELTİLDİ (2026-09-13).** `/api/v1/auth/*` ve
  `/health` dışındaki her yol geçerli JWT ister; `JWT_SECRET` yoksa fail-closed.
  İstemciden gelen `X-User-*`/`X-Property-Id`/`X-Tenant-Id` başlıkları **silinir**.
  CORS allowlist'e alındı; her isteğe `X-Request-Id` verilir. Kong'da 25 rotada `jwt`
  eklentisi var. Gateway'in uydurma `/dashboard/*` ve `/reports/*` yanıtları kaldırıldı.
  **Kanıt:** `verify-stack.sh` §8.
- ~~**`go build ./...` BAŞARISIZ**~~ → **DÜZELTİLDİ (2026-09-12).** Ölü `backend/api/` dizini kaldırıldı
  (kırık import + `X-User-Role` başlığına güvenen sahte yetki kontrolü içeriyordu); ayrıca
  `pkg/integrations/sms` ve `pkg/integrations/whatsapp` paketlerindeki derleme hataları giderildi.
  **Kanıt:** `go build ./...` ve `go vet ./...` → çıkış kodu 0.
- ~~**Denetim izi (audit log) çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Migration `011` ile şema
  koda uyumlu hale getirildi (`property_id`, `request_id`, `status_code` eklendi, `tenant_id` zorunluluğu
  kaldırıldı); `pkg/audit` yeniden yazıldı; `pkg/middleware` artık hatayı yutmuyor ve 403'leri `DENIED`
  olarak ayırıyor. **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı geçiyor + uçtan uca
  istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- **İzolasyon hem uygulama hem veritabanı katmanındadır.** JWT'deki `property_id`
  istemci tarafından değiştirilemez (sahiplik doğrulaması); her servis `pkg/dbscope`
  ile sorguyu site kapsamına bağlar (`SET LOCAL app.property_id`); RLS unutulan
  filtreyi yakalar. RLS'e geçiş sırasında **beş çapraz site açığı** bulundu ve
  kapatıldı (talep, ödeme, itiraz, karar defteri, görünümler). `pkg/tenant` ölü koddur.
- ~~**Para hesaplarında kritik hatalar**~~ → **DÜZELTİLDİ.** Bakiye kartezyen join'i giderildi
  (2026-09-12); ödeme artık `paid_amount`'ı günceller ve borcu düşürür (yönetici onay akışı,
  2026-09-13); gecikme tazminatı KMK m.20/2'ye göre hesaplanır.
  **Kanıt:** `verify-stack.sh` §10.
- **Ödeme sağlayıcısı, Firebase, Kafka, MongoDB ve AI entegrasyonları hâlâ YOKTUR.**
  `pkg/payment` (iyzico), `pkg/notification` (FCM), `pkg/ai`, `pkg/integrations/*` yazılmış
  ama **hiçbir yerden import edilmez**. Fark: artık bunlar **var gibi gösterilmiyor** —
  ödeme yanıtı `payment_gateway_ready:false` döndürüyor, panel/mobil "bağlı değil" diyor,
  uydurma AI yanıtları kaldırıldı.
- **Ölü şema büyük ölçüde canlandı.** `005_new_modules.sql`'in tablolarının
  neredeyse tamamı artık kullanılıyor: gider, personel, ziyaretçi, otopark,
  tesis/rezervasyon, kargo, sözleşme, demirbaş+bakım, stok+hareket, anket,
  devriye, ilan panosu. Kullanılmayan kalanlar: `bank_accounts`/`bank_transactions`
  (S-07 kararı), `meetings` (governance ile tekrar), `energy_analytics` ve
  `payment_risk_scores`'un "AI" kolonları (bilerek doldurulmuyor).
  `012`–`017` tablolarının **tamamı kullanılıyor**.
- **Admin panel API hedefi:** `NEXT_PUBLIC_API_URL` (yerel geliştirme:
  `http://localhost:8888/api/v1`). `admin/.env.local` `dev-up.sh` ile birlikte kullanılır.
- **Mobil taban adresleri düzeltildi:** her iki uygulama da
  `--dart-define=API_BASE_URL` ile yapılandırılabilir; varsayılan Android emülatöründen
  local gateway'e gider. **Kalan sorun:** sakin uygulamasının release APK'sında INTERNET
  izni yok ve `ios/` klasörü yok (todo FAZ 8).

### Doğrulama ortamı — WSL kullan

**Local çalışma ve doğrulama WSL (Ubuntu 24.04) üzerinden yapılır.** Kullanıcı talimatı (2026-09-12).

Windows tarafında kurumsal AppLocker politikası, kullanıcı yazılabilir dizinlerden çalıştırılabilir
dosya açılmasını engeller; bu yüzden Windows'ta Go/Docker kurulamaz. **WSL'de bu kısıtlama yoktur.**

| Araç | Durum | Not |
|---|---|---|
| Go 1.24.7 | WSL'de kurulu | `/usr/local/go/bin` — PATH'e eklenmeli |
| Docker 27.5 | WSL'de çalışıyor | `docker info` OK |
| PostgreSQL istemcisi 16 | WSL'de kurulu | `psql` |
| Node 22 / npm | Hem Windows hem WSL | `admin/node_modules` Windows'ta kurulu |
| Flutter 3.47.4 | **WSL'de kurulu** (`~/flutter`) | `export PATH=$PATH:$HOME/flutter/bin` |

Repo yolu WSL'de: `/mnt/c/Users/md064615/Documents/Projeler/proje99`

**Doğrulama betikleri**

| Betik | Kapsam | Ne zaman |
|---|---|---|
| `bash backend/scripts/verify-stack.sh` | **981 kontrol** — dağıtım dosyası tutarlılığı, sıfırdan PostgreSQL, `cmd/migrate` ile 28 migration ve rol ataması, RLS (81 tablo, çapraz site uçtan uca testleri, rol yetkileri), şema denetimi, tam idempotency, `pkg/audit`+`pkg/legalparams`+`pkg/money`+`pkg/storage`+nisap testleri, ve uçtan uca: identity (giriş, roller, hesap etkinleştirme, şifre değiştirme, giriş kilidi), gateway (kimlik doğrulama), finance (ödeme→borç, gecikme tazminatı), governance (işletme projesi, nisap, defter zinciri), 501 dürüstlüğü ve 20 modülün uçtan uca sınanması (gider, personel, ziyaretçi, otopark, rezervasyon, kargo, sözleşme, belge, demirbaş, stok, anket, sayaç/ısı payı, bildirim, devriye, duyuru, ilan, ayarlar, enerji, tahsilat riski, NPS/ESG) ve zamanlanmış bildirimler (`cmd/scheduler`) | **Backend'e dokunan her değişiklikten sonra** |
| `bash backend/scripts/verify-mobile.sh` | **8 kontrol** — iki Flutter uygulaması için `pub get` + `analyze` + `test` ve arayüzde uydurma veri taraması | Mobil değişikliklerden sonra |
| `cd admin && npx tsc --noEmit && npm run lint && npm run build` | Panel | Panel değişikliklerinden sonra |
| `bash backend/scripts/dev-up.sh` | Geliştirme ortamını ayağa kaldırır | Elle deneme için |

Kural: Bir madde ancak çalıştığı **kanıtlandıktan** sonra tamamlandı işaretlenir
(`tasks/dogrulama-politikasi.md`). Go, Flutter, Docker ve PostgreSQL kurulu olduğu için
**"doğrulanamadı" mazereti artık yoktur.**

## Commands

### Full Stack (Docker)
```bash
cp .env.example .env                          # gizli değerleri doldur (boşsa compose açılmaz)
docker compose up -d --build                  # postgres → migrate → 26 servis → gateway → panel
docker compose logs -f identity-service       # tek servisin günlüğü
python3 backend/scripts/gen-deploy.py         # servis listesi değişince dağıtım dosyalarını üret
```

### Backend (Go)
All backend code lives in `backend/`. The Go module is `github.com/siteeksen/backend`.
```bash
cd backend
go build ./...                                # Build all services
go test ./tests/...                           # Run integration tests
go test ./services/identity/...              # Run tests for a specific service
go vet ./...                                  # Lint
```
Run a single service locally (requires env vars):
```bash
go run services/identity/main.go
```

### Admin Panel (Next.js)
```bash
cd admin
npm install
npm run dev      # Dev server on port 3001
npm run build
npm run lint
```

### Mobile Apps (Flutter)
Both `mobile/` (resident) and `admin_app/` (site manager) use the same stack.
```bash
cd mobile          # or admin_app
flutter pub get
flutter pub run build_runner build   # Regenerate freezed/json models
flutter run
```

## Architecture

### Backend Microservices
Each service under `backend/services/` is a standalone Go binary following the same layered structure:
```
services/<name>/
  main.go        # Gin router setup, DI wiring
  handlers/      # HTTP handler functions
  service/       # Business logic
  repository/    # pgx database queries
  models/        # Structs (request/response/DB)
```

Active services and their ports:
| Service | Port | Notes |
|---------|------|-------|
| identity | 8081 | Auth, JWT, users |
| finance | 8082 | Dues, payments (Iyzico) |
| community | 8083 | Requests, bulletin |
| iot | 8084 | Sensors (also uses MongoDB) |
| notification | 8085 | Firebase push, Kafka consumer |
| expense | 8086 | Gider ve kalem bazlı dağıtım (**gerçek DB**) |
| asset | 8087 | Demirbaş, bakım, amortisman (**gerçek DB**) |
| bulletin | 8089 | Sakin ilan panosu, onay akışı (**gerçek DB**) |
| contract | 8090 | Sözleşme takibi, ihbar penceresi (**gerçek DB**) |
| document | 8091 | Belge arşivi + dosya depolama (**gerçek DB + pkg/storage**) |
| energy_analytics | 8092 | Tüketim eğilimi, olağandışı tüketim (**gerçek DB, YZ yok**) |
| esg | 8093 | Karbon ayak izi (**gerçek DB**; katsayı kullanıcıdan) |
| inventory | 8094 | Sarf malzeme stoğu ve hareketleri (**gerçek DB**) |
| meeting_wizard | 8095 | **Yazılmadı** — governance'a yönlendirir (501) |
| nps | 8096 | Memnuniyet ölçümü (**gerçek DB**, anket altyapısı üzerinde) |
| package | 8097 | Kargo/paket takibi (**gerçek DB**) |
| parking | 8098 | Araç ve otopark hareketleri (**gerçek DB**) |
| patrol | 8099 | Devriye/tur kontrol (**gerçek DB**) |
| personnel | 8100 | Personel ve izin (**gerçek DB**) |
| reservation | 8101 | Ortak alan rezervasyonu, çakışma denetimi (**gerçek DB**) |
| settings | 8102 | Site işletme ayarları (**gerçek DB**; mevzuat parametrelerini ezemez) |
| smart_collection | 8103 | Ödeme riski, açıklanabilir skor (**gerçek DB, YZ yok**) |
| survey | 8104 | Anket/oylama (**gerçek DB**; genel kurul kararı üretmez) |
| visitor | 8105 | Ziyaretçi kayıt/çıkış (**gerçek DB**) |
| banking | 8106 | **Yazılmadı** — S-07 kullanıcı kararı (501) |
| governance | 8107 | KMK yönetişim: işletme projesi, genel kurul, defterler, icra (**gerçek DB**) |
| gateway | 8888 | Custom dev gateway (`cmd/gateway/`) — kimlik doğrulama kapısı |
| scheduler | 8110 | `cmd/scheduler` — zamana bağlı bildirimler (gecikmiş aidat, sözleşme ihbarı, açık devriye); yalnızca `/health`, gateway'e bağlı değil |

All 26 services are in docker-compose, k8s and the CI image matrix (generated by `backend/scripts/gen-deploy.py`).

### Shared Packages (`backend/pkg/`)
- `database/` — pgx connection pool, config from env (`DB_USER` is `siteeksen_app` or `siteeksen_identity`, never the superuser)
- `dbscope/` — **every repository query goes through `dbscope.For(pool, propertyID)`**; sets `app.property_id` per transaction so RLS applies. New repository code must use it.
- `middleware/` — JWT auth (+ revocation check), site-scoped roles into Gin context, `RequireRole`, `AuditLog`
- `audit/`, `revocation/`, `authtoken/` — KVKK audit trail, token revocation, JWT
- `pii/` — AES-256-GCM + HMAC blind index for TCKN/IBAN; `legalparams/` — mevzuat parametreleri; `money/` — kuruş aritmetiği
- `notify/` — outbox bildirim + alıcı kümeleri (`audience.go`); `storage/` — local / S3 (SigV4)
- `tenant/`, `payment/`, `notification/`, `ai/`, `integrations/` — **ölü kod, hiçbir yerden import edilmez**

### API Gateway
**Kong** (port 8000) routes production traffic to services using declarative config at `kong/kong.yml`. For local dev, the lightweight custom gateway at `cmd/gateway/` (port 8888) is used instead.

### Admin Panel (Next.js 14)
- App router under `admin/src/app/(dashboard)/dashboard/`
- Pages: residents, assessments, accounting, requests, announcements, meters, notifications, credentials, reports, settings
- Auth via NextAuth.js (`next-auth`)
- API client in `src/lib/api-client.ts`
- UI: Tailwind CSS + lucide-react icons
- **Denetim notu:** `zod`, `react-hook-form`, `recharts`, `date-fns` ve 7 Radix UI paketi `package.json`'da
  kurulu ama `src/` altında **hiç kullanılmıyor**. `src/lib/hooks.ts`'teki 17 hook'un 13'ü ölü kod.
  TanStack Query kurulu; yeni kod yazarken bu paketleri ya gerçekten kullan ya da bağımlılıktan çıkar.
  Ayrıca panelde **rol bazlı erişim kontrolü yok** (`session.user.roles` hiçbir sayfada okunmuyor) ve
  **çıkış (logout) düğmesi yok**.

### Mobile Apps (Flutter)
Two separate Flutter apps sharing the same technology choices:
- **`mobile/`** — resident-facing app
- **`admin_app/`** — site manager mobile app

Bildirilen ortak yığın: Riverpod, go_router, Dio, flutter_secure_storage.

**Denetim notu (gerçek durum):**
- **Riverpod pratikte kullanılmıyor** — yalnızca router provider'ında; 43 ekran `setState` ile çalışıyor.
- **Freezed / json_serializable / Retrofit hiç kullanılmıyor** (paketler kurulu, 0 kullanım; üretilmiş
  `*.g.dart`/`*.freezed.dart` dosyası yok). Tüm API yanıtları `Map<String, dynamic>` olarak elle işleniyor
  → tip güvenliği yok (anket ekranı, API veri döndürdüğü an var olmayan alanı okuyup çöküyor).
- **Firebase Messaging hiç kullanılmıyor** — mobilde tek satır Firebase kodu yok, `google-services.json` yok.
  Push bildirim akışı hiç kurulmamıştır.
- **`intl` kullanılmıyor** → para/tarih biçimlendirme elle yapılıyor ve hatalı (örn. `12.450.00`).
- Sakin uygulamasında 13/22, yönetici uygulamasında 16 bağımlılık hiç import edilmemiş.
- Test sayısı: sakin 1 (derlenmiyor), yönetici 0 (`test/widget_test.dart` var olmayan sınıfı çağırıyor).

### Infrastructure
- **PostgreSQL 16** — tek veri deposu; şema `backend/migrations/` (26 migration, `cmd/migrate`)
- Redis, MongoDB ve Kafka **kullanılmıyor** (kodda bağlantı yok) ve compose'dan kaldırıldı.

### Multi-Tenancy (site izolasyonu) — **çalışıyor, iki katmanlı**
- **Uygulama katmanı:** JWT `property_id` (site seçiminde sahiplik doğrulanır), site bazlı roller
  (`property_roles`), her sorguda `property_id` filtresi.
- **Veritabanı katmanı:** 81 tabloda RLS; kapsam `pkg/dbscope` ile verilir. Kapsam yoksa sorgu
  hiç satır döndürmez (fail-closed). Alt tablolar ebeveyn üzerinden `EXISTS` ile korunur.
- Yeni tablo eklerken: RLS + politika + (alt tabloysa) ebeveyn anahtarına indeks; doğrulama
  RLS dışında kalan tablo listesini birebir denetler, eklenen tablo unutulursa yakalanır.
- `pkg/tenant` (X-Tenant-ID) ölü koddur; kullanılmaz.

### Security — **beyan ile gerçek arasındaki fark**
| Konu | Durum (2026-09-13) |
|---|---|
| JWT 15 dk / 7 gün | **Doğru** |
| `JWT_SECRET` boşsa davranış | **Fail-closed** — istek reddedilir; boş anahtarla doğrulama yapılmaz |
| Gateway / Kong kimlik doğrulama | **Var** — gateway'de `/auth/*` dışı her yol JWT ister; Kong'da 25 rotada `jwt` eklentisi |
| CORS | **Allowlist** (`CORS_ALLOWED_ORIGINS`); joker `*` kalmadı |
| KVKK denetim izi | **Çalışıyor** — kullanıcı, IP, işlem, kaynak, durum kodu yazılıyor; 403'ler `DENIED` |
| Rol bazlı yetkilendirme | **Site bazlı roller** + gerçek servislerin hepsinde `RequireRole` + panelde `middleware.ts` ve menü süzme. Roller giriş yanıtında da döner (2026-09-13 düzeltmesi; yoksa panel herkesi yetkisiz sayıyordu). |
| Belge erişim kaydı | **Var** — `document_access_logs`, salt-ekleme (tetikleyici korumalı), KVKK m.12 |
| Ticari elektronik ileti | **Onaysız gönderilmez** — 6563 s. Kanun m.6; onay zamanı ve kaynağı saklanır |
| Modül bildirimleri | **Bağlı (2026-09-14)** — duyuru, rezervasyon kararı, kargo, anket, ziyaretçi girişi ve düşük stok uygulama içi bildirim üretir. Alıcı kümesi `pkg/notify/audience.go`'da TEK yerde. Kargo bildirimi takip numarası taşımaz; stok uyarısı sakinlere gitmez; anket bildirimi genel kurul çağrısı olarak işaretlenmez (KMK m.29) |
| Ayarların mevzuatı ezmesi | **Engellendi** — uygulama + veritabanı CHECK kısıtı (migration 017) |
| Aktif site seçimi | **Sahiplik doğrulanıyor** — başkasının sitesine geçiş 403 |
| Giriş şifresi loglanması | **Kaldırıldı** — yalnızca maskelenmiş telefon ve HTTP durumu loglanıyor |
| İstemci kimlik başlıkları | Gateway `X-User-*` / `X-Property-Id` / `X-Tenant-Id` başlıklarını **siler** |
| TCKN/IBAN şifreleme | **VAR** — AES-256-GCM; arama için HMAC blind index (düz SHA-256 değil). Anahtar yoksa personel servisi açılmaz. Varsayılan MASKELİ; maskesiz erişim ayrı `PII_REVEAL` denetim kaydı üretir |
| Tenant izolasyonu (RLS) | **81 TABLODA AÇIK** (migration 020-026). 26 servisin tamamı `pkg/dbscope` kullanır. RLS dışında kalan 9 tablo gerekçeli: `audit_logs` (yalnızca ekleme), `legal_parameters` (salt-okur), `revoked_tokens`/`user_token_invalidation` (salt-okur), `tenants`/`invoices`/`usage_metrics`/`schema_migrations`/`user_activation_codes` (uygulama rolüne kapalı) |
| Hesap etkinleştirme / şifre | **VAR (027)** — yönetici sakin ekleyince tek kullanımlık kod bir kez gösterilir (SMS yok, yönetici iletir); kod özeti saklanır, 7 gün, 5 denemede kilit. Şifre değiştirme/sıfırlama bütün oturumları kapatır. Girişte 5 hatada 15 dk kilit. Jeton `iat` milisaniye hassasiyetinde (`pkg/revocation.Precision`) |
| Veritabanı rolleri | **En az yetki** — kimlik servisi ayrı rol (site verisine erişemez); uygulama rolü parola özetini/TCKN'yi göremez, dizin tablolarına yazamaz, denetim izini ve jeton iptalini silemez |
| Dağıtım | compose/k8s/CI tek kaynaktan; kaplar root değil; compose varsayılan parolayla açılmaz; k8s'te tek giriş kapısı gateway |
| Çıkışta jeton iptali | **VAR** — `revoked_tokens` + toplu iptal. Çıkışta erişim VE yenileme jetonu iptal edilir; iptal tüm servislerde geçerlidir. Yenileme jetonu **tek kullanımlık**; tükenmiş jetonun 30 sn sonra yeniden kullanımı bütün oturumları kapatır |

`legal/kvkk-aydinlatma.md` 2026-09-13'te **gerçek duruma göre** düzeltildi: uygulanan ve
uygulanmayan tedbirler ayrı listelenmiştir; karşılığı olmayan taahhüt kalmamıştır.
