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

### Kritik Mimari Notlar — GERÇEK DURUM (2026-09-09 denetimi)

> Aşağıdaki notlar kod denetimiyle doğrulanmıştır. Bu bölümdeki hiçbir ifade "olması gerekeni" değil,
> **bugün gerçekte olanı** anlatır. Ayrıntı ve `dosya:satır` kanıtı: `tasks/audit-raporu.md`.

- **Yalnızca 3 servis gerçek:** 25 servisten `identity`, `finance` ve `community` PostgreSQL'e bağlıdır.
  Kalan **22 servis sabit JSON döndürür** ve yazma isteklerine `2xx` dönüp veriyi **hiçbir yere kaydetmez**.
  Bir modül üzerinde çalışırken önce o servisin gerçek mi mock mu olduğunu `tasks/gap-analizi.md` Bölüm A'dan doğrula.
- ~~**Veritabanı temiz makinede KURULAMIYOR**~~ → **DÜZELTİLDİ (2026-09-12).** `004`/`005`'teki tablo
  çakışmaları ve `005`'teki geçersiz UUID giderildi. Sıfırdan kurulum artık çalışıyor: 11 migration,
  61 tablo. **Kanıt:** `bash backend/scripts/verify-stack.sh` → 42/42 kontrol geçti.
- ~~**Demo kullanıcı girişi çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Seed'deki bozuk bcrypt hash
  yeniden üretildi. Demo giriş: **`5551234567` / `Demo123!`** (ikinci hesap: `5559876543`).
  **Kanıt:** gerçek identity-service'e `POST /auth/login` → HTTP 200 + JWT; yanlış şifre → 401.
- **Gateway gerçek bir reverse proxy'dir** (25 servise yönlendirir) **ama kimlik doğrulaması yoktur.**
  Kong'da da JWT plugin'i yoktur → maaş, TCKN, IBAN ve **API anahtarları** token'sız erişilebilir.
  Gateway'in `/dashboard/*` ve `/reports/*` uçları hâlâ uydurma veri döndürür.
- ~~**`go build ./...` BAŞARISIZ**~~ → **DÜZELTİLDİ (2026-09-12).** Ölü `backend/api/` dizini kaldırıldı
  (kırık import + `X-User-Role` başlığına güvenen sahte yetki kontrolü içeriyordu); ayrıca
  `pkg/integrations/sms` ve `pkg/integrations/whatsapp` paketlerindeki derleme hataları giderildi.
  **Kanıt:** `go build ./...` ve `go vet ./...` → çıkış kodu 0.
- ~~**Denetim izi (audit log) çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Migration `011` ile şema
  koda uyumlu hale getirildi (`property_id`, `request_id`, `status_code` eklendi, `tenant_id` zorunluluğu
  kaldırıldı); `pkg/audit` yeniden yazıldı; `pkg/middleware` artık hatayı yutmuyor ve 403'leri `DENIED`
  olarak ayırıyor. **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı geçiyor + uçtan uca
  istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- **Multi-tenancy fiilen yoktur:** `pkg/tenant` (294 satır) hiçbir yere bağlı değildir — `X-Tenant-ID`
  yaklaşımı geri alınmıştır. İzolasyonun tek dayanağı JWT'deki `property_id`'dir ve bu değer
  `POST /users/me/active-property` sahiplik doğrulaması yapmadığı için **istemci tarafından değiştirilebilir**.
  Roller ayrıca siteye göre değil **globaldir**.
- **Para hesaplarında kritik hatalar:** `GetUnitBalance` kartezyen join nedeniyle bakiyeyi kullanıcı
  sayısıyla çarpar; ödeme akışı `monthly_assessments.paid_amount`'ı **hiç güncellemez** (ödeyen sakin
  sonsuza dek borçlu kalır). Doğru bakiye hesabı `unit_balances` view'ında (`001:422`) hazırdır.
- **Ödeme, Firebase, Kafka, MongoDB, AI entegrasyonları YOKTUR.** `pkg/payment` (iyzico),
  `pkg/notification` (FCM), `pkg/ai`, `pkg/integrations/*` (~3.900 satır) yazılmış ama **hiçbir yerden
  import edilmez**. `go.mod`'da MongoDB sürücüsü ve Kafka kütüphanesi bile yoktur.
  AI fatura tarama kullanıcıya her seferinde sabit "AYEDAŞ 2.450,75 TL" döndürür.
- **Ölü şema:** 61 tablonun 47'si (%77) hiçbir kod tarafından kullanılmaz; `005_new_modules.sql`'in
  45 KB'ının tamamı ölüdür.
- **Admin panel API hedefi:** `NEXT_PUBLIC_API_URL` env yoksa `http://localhost:8000/api/v1` (Kong).
  Docker'da gateway'e (8888) yönlendirilmiştir. `.env.example` ise 8000 der → **3 farklı değer** vardır.
- **Mobil uygulamalar üretimde çalışmaz:** sakin uygulamasının release APK'sında INTERNET izni yok;
  `ios/` klasörü yok; yönetici uygulamasının taban adresi `/v1` (backend `/api/v1` bekler) → her çağrı 404.

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
| Flutter | **Kurulu değil** | Mobil doğrulaması için kurulmalı |

Repo yolu WSL'de: `/mnt/c/Users/md064615/Documents/Projeler/proje99`

**Doğrulama betiği:** `bash backend/scripts/verify-stack.sh`
Sıfırdan PostgreSQL kurar, 11 migration'ı uygular, şemayı denetler, idempotency sınar,
`pkg/audit` testini gerçek veritabanına karşı çalıştırır ve identity-service'i ayağa kaldırıp
gerçek HTTP istekleriyle giriş/yetki/denetim izi akışlarını doğrular (42 kontrol).
**Backend'e dokunan her değişiklikten sonra çalıştırılmalıdır.**

Kural: Bir madde ancak çalıştığı **kanıtlandıktan** sonra tamamlandı işaretlenir
(`tasks/dogrulama-politikasi.md`). Doğrulama artık mümkün olduğu için "doğrulanamadı" mazereti
yalnızca Flutter tarafı için geçerlidir.

## Commands

### Full Stack (Docker)
```bash
docker-compose up -d                          # Start all services
docker-compose up -d postgres redis           # Start only databases
docker-compose logs -f                        # Follow all logs
docker-compose logs -f identity-service       # Follow a specific service
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
| gateway | 8888 | Custom dev gateway (`cmd/gateway/`) |

Many more services exist in `backend/services/` (parking, personnel, visitor, energy_analytics, reservation, contract, document, etc.) but are not yet wired into docker-compose.

### Shared Packages (`backend/pkg/`)
- `database/` — pgx connection pool, config from env
- `middleware/` — JWT auth middleware; extracts `user_id`, `property_id`, `roles` into Gin context
- `tenant/` — multi-tenancy via `X-Tenant-ID` header or subdomain; use `TenantMiddleware()` on routes that need it
- `encryption/` — AES-256-GCM for sensitive fields (TCKN, phone numbers)
- `payment/`, `notification/`, `reports/`, `ai/`, `integrations/` — domain-specific shared utilities

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
- **PostgreSQL 16** — primary datastore; schema managed via sequential SQL migrations in `backend/migrations/`
- **Redis 7** — caching and session storage (identity uses DB 0, notification uses DB 1)
- **MongoDB 7** — IoT sensor time-series data only
- **Kafka** (Confluent) — async event bus; consumed by notification-service

### Multi-Tenancy — **fiilen yok**
`pkg/tenant/middleware.go` yazılmıştır ama **hiçbir route'a bağlı değildir** (294 satır ölü kod);
`X-Tenant-ID` yaklaşımı geri alınmıştır. Bugün izolasyonun tek dayanağı JWT'deki `property_id` claim'idir ve:
- `POST /users/me/active-property` sahiplik doğrulaması yapmadığı için bu değer **istemci tarafından
  seçilebilir** (`identity/repository/user.go:87-91`),
- roller siteye göre değil **globaldir** (`users.roles TEXT[]`) → bir sitede `MANAGER` olan kişi tüm
  sitelerde yöneticidir,
- 11 sorguda `deleted = 0` filtresi, bazı sorgularda tenant filtresi eksiktir.

Kalıcı çözüm için önerilen yaklaşım PostgreSQL satır düzeyi güvenliğidir (RLS) — bkz. `tasks/roadmap.md` §U.1.

### Security — **beyan ile gerçek arasındaki fark**
| Beyan | Gerçek |
|---|---|
| JWT 15 dk / 7 gün | **Doğru** (`identity/service/auth.go:138-140`) |
| KVKK audit log aktif | **Çalışmıyor** — kolon adları şemayla uyuşmuyor, hata yutuluyor, tablo boş |
| TCKN/telefon AES-256-GCM ile şifreli | **Şifrelenmiyor** — `pkg/encryption` hiçbir yerden import edilmiyor; TCKN düz metin JSON olarak, üstelik kimliksiz uçlardan servis ediliyor |
| Rol bazlı yetkilendirme | `RequireRole` **tek** endpoint'te bağlı; panelde hiç yok; yönetici mobilde fail-open |
| — | `JWT_SECRET` boşsa **boş anahtarla** token doğrulanıyor; compose'da bilinen bir default var |
| — | Gateway ve Kong'da **kimlik doğrulama yok**; CORS her yerde `*` |
| — | Giriş şifresi düz metin olarak sunucu log'una yazılıyor (`admin/src/app/api/auth/[...nextauth]/route.ts:17`) |

Bu maddeler `tasks/roadmap.md` FAZ 2'de ele alınır. `legal/kvkk-aydinlatma.md` içindeki güvenlik
taahhütleri bugünkü gerçekle çelişmektedir (FAZ 0.D).
