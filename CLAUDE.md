# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Çalışma Disiplini (Token ve Bağlam Yönetimi)

### Başlamadan önce
- Her görev için önce adımları madde madde yaz ve onayla, sonra başla.
- Adımlar atomik olmalı: tek dosya, tek fonksiyon, tek işlem. "Servisi yaz" değil, "servisin repository katmanını yaz."
- Tahmini adım sayısı 5'ten fazlaysa kullanıcıya bölüp bölmemesini sor.

### Çalışırken
- Her adım tamamlandığında o adımı tamamlandı olarak işaretle ve kullanıcıya bildir.
- Her anlamlı adımdan sonra commit at (commit için onay iste). Böylece bağlam sıfırlansa bile `git log` ile kaldığı yer görülür.
- Dosyayı okumadan düzenleme, her seferinde yeniden okuma — sadece gerekli bölümü oku.
- Aynı dosyayı birden fazla kez okuma, gereksiz araç çağrısı yapma.

### Her adımdan sonra (zorunlu rutin)
Her adım tamamlandığında, bir sonrakine geçmeden şunları yap:
1. `CHANGELOG.md` `[Unreleased]` bölümüne tamamlanan adımı ekle.
2. `ROADMAP.md`'de ilgili satırı güncelle (✅ işaretle).
3. Commit at (onay iste).

Bu rutin atlanmaz. Limit aniden geldiğinde son commit'e kadar olan her şey kayıtlıdır ve yeni oturum kaldığı yerden devam edebilir.

### Yeni oturumda
- `git log --oneline`, `CHANGELOG.md` ve `ROADMAP.md` okunmadan hiçbir şeye başlama.

---

## Workflow Orchestration

### 1. Plan Mode Default
- 3+ adım veya mimari karar içeren her görev için plan moduna gir.
- Bir şeyler ters giderse dur ve planı yeniden yaz, devam etme.
- Plan modu sadece inşa için değil, doğrulama adımları için de kullanılır.
- Belirsizliği azaltmak için başta detaylı spec yaz.

### 2. Subagent Stratejisi
- Ana bağlam penceresini temiz tutmak için subagent'leri aktif kullan.
- Araştırma, keşif ve paralel analizleri subagent'lere devret.
- Karmaşık problemlerde subagent ile daha fazla hesaplama kullan.
- Her subagent tek bir göreve odaklanmalı.

### 3. Kendini İyileştirme Döngüsü
- Aynı hatayı tekrar yapmamak için `tasks/lessons.md` dosyasına kural yaz.
- Hata oranı düşene kadar bu dersleri acımasızca güncelle.
- Her oturum başında `tasks/lessons.md`'yi oku.

### 4. Tamamlamadan Önce Doğrulama
- Çalıştığını kanıtlamadan hiçbir görevi tamamlandı olarak işaretleme.
- Değişiklikler için main ile farkı kontrol et.
- Testleri çalıştır, logları kontrol et, doğruluğu göster.

### 5. Zarafet Talebi (Dengeli)
- Basit olmayan değişiklikler için: "Daha zarif bir yol var mı?" diye sor.
- Bir fix hackish hissettiriyorsa: bildiğin her şeyle zarif çözümü uygula.
- Basit ve açık düzeltmelerde bunu atlat — aşırı mühendislik yapma.
- Sunmadan önce kendi çalışmana meydan oku.

### 6. Otonom Hata Düzeltme
- Bug raporu verildiğinde: direkt düzelt. Rehberlik isteme.
- Logları, hataları, başarısız testleri işaret et — sonra çöz.
- Kullanıcıdan sıfır bağlam geçişi gerektirir.
- Söylenmeden başarısız CI testlerini düzelt.

---

## Görev Yönetimi

1. **Önce Planla:** Planı `tasks/todo.md`'ye işaretlenebilir maddeler olarak yaz.
2. **Planı Doğrula:** Uygulamaya başlamadan önce kontrol et.
3. **İlerlemeyi Takip Et:** Tamamlanan maddeleri giderken işaretle.
4. **Değişiklikleri Açıkla:** Her adımda üst düzey özet ver.
5. **Sonuçları Belgele:** `tasks/todo.md`'ye inceleme bölümü ekle.
6. **Dersleri Kaydet:** Düzeltmelerden sonra `tasks/lessons.md`'yi güncelle.

---

## Temel Prensipler

- **Önce Basitlik:** Her değişikliği mümkün olduğunca basit yap. Minimal kodu etkile.
- **Tembellik Yok:** Kök nedenleri bul. Geçici düzeltme yok. Kıdemli geliştirici standartları.
- **Minimal Etki:** Sadece gerekli olanı değiştir. Yeni bug'larla yan etki yok.

---

## Proje Takip Dosyaları

Herhangi bir göreve başlamadan önce sırasıyla şu dosyalara bak:

1. **`ROADMAP.md`** — Hangi modüllerin tamamlandığını, hangilerinin eksik veya planlandığını gösterir. Yeni bir özellik eklendiğinde veya bir modül tamamlandığında bu dosyayı güncelle.
2. **`CHANGELOG.md`** — Geçmişte ne yapıldığını gösterir. Bir şeyin daha önce yazılıp yazılmadığını anlamak için ilk buraya bak. Her anlamlı değişiklikten sonra `[Unreleased]` bölümüne ekle.

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
