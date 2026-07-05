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

1. **`tasks/roadmap.md`** — Hangi modüllerin tamamlandığını, hangilerinin eksik veya planlandığını ve ustalık yol haritasını gösterir.
2. **`tasks/changelog.md`** — Geçmişte ne yapıldığını gösterir. Bir şeyin daha önce yazılıp yazılmadığını anlamak için ilk buraya bak. Her anlamlı değişiklikten sonra `[Unreleased]` bölümüne ekle.

Bu iki dosya okunduktan sonra ilgili kaynak dosyalara geç.

---

## Project Overview

**SiteEksen** — Türkiye kat mülkiyeti kanununa uyumlu site yönetim platformu. Go mikroservis backend, Next.js admin paneli, iki Flutter mobil uygulaması (sakin + yönetici) içerir.

### Kritik Mimari Notlar

- **Demo Gateway vs Gerçek Servisler**: `cmd/gateway/main.go` (port 8888) gerçek bir proxy DEĞİL, tamamen hardcoded mock data döndürüyor. Admin paneli şu an buna bağlı. Gerçek mikroservisler (identity, finance, community...) çalışıyor ama admin paneline bağlı değil.
- **Demo kullanıcılar** (gateway üzerinden): `5551234567 / demo123` (super_admin), `5559876543 / demo123` (resident)
- **Admin panel API hedefi**: `NEXT_PUBLIC_API_URL` env yoksa `http://localhost:8000/api/v1` (Kong) kullanır. Docker'da `http://gateway:8888/api`'ye yönlendirilmiş.
- **20+ backend servisi** yazıldı ama sadece 5'i (`identity`, `finance`, `community`, `iot`, `notification`) docker-compose'da aktif. Geri kalanlar standalone binary olarak var, hiçbir gateway'e bağlı değil.
- **Veritabanı şeması**: 5 migration ile tam kurulu — properties, blocks, units, users, visitors, vehicles, meters, assessments, payments, requests, announcements vb.
- **AI entegrasyonu**: `pkg/integrations/ai/` — OpenAI Vision (plaka tanıma, fatura tarama). Gerçek API key gerektirir.
- **Banka entegrasyonu**: `pkg/integrations/bank/` — HMAC-SHA256 imzalı ödeme istekleri. `services/banking/turkish_banks.go` Türk bankalarını tanımlar.
- **Multi-tenant**: Her istek `X-Tenant-ID` header veya subdomain taşımalı (`sitea.siteeksen.com`).

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
- Data fetching with TanStack Query v5; API client in `src/lib/api-client.ts`
- UI: Tailwind CSS + Radix UI primitives + lucide-react icons
- Forms: react-hook-form + zod validation
- Charts: Recharts

### Mobile Apps (Flutter)
Two separate Flutter apps sharing the same technology choices:
- **`mobile/`** — resident-facing app
- **`admin_app/`** — site manager mobile app

Common stack: Riverpod (state), go_router (navigation), Dio/Retrofit (HTTP), Freezed (immutable models), Firebase Messaging (push notifications), flutter_secure_storage (JWT storage).

### Infrastructure
- **PostgreSQL 16** — primary datastore; schema managed via sequential SQL migrations in `backend/migrations/`
- **Redis 7** — caching and session storage (identity uses DB 0, notification uses DB 1)
- **MongoDB 7** — IoT sensor time-series data only
- **Kafka** (Confluent) — async event bus; consumed by notification-service

### Multi-Tenancy
Tenant resolution is done in `pkg/tenant/middleware.go`. Each request must carry either a `X-Tenant-ID` header or the subdomain (e.g., `sitea.siteeksen.com`). Tenant context is then available downstream via Gin context.

### Security
- JWT: 15-minute access tokens, 7-day refresh tokens
- KVKK compliance: audit log mechanism active for sensitive data access
- Sensitive PII (TCKN, phone) encrypted at rest with AES-256-GCM (`pkg/encryption/`)
