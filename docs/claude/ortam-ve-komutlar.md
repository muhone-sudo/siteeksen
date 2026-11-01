# Ortam, doğrulama betikleri ve komutlar

> `CLAUDE.md`'den taşındı (2026-10-29). İçerik değiştirilmedi.

### Doğrulama ortamı

**2026-10-26 itibarıyla çalışma doğrudan Linux'ta (Ubuntu 24.04.5) yapılır.** Eski WSL/Windows
(AppLocker) düzeni artık kullanılmıyor.

| Araç | Durum | Not |
|---|---|---|
| Go 1.27.3 | Kurulu | `/snap/bin/go` (betikler `/usr/local/go/bin`'i de PATH'e ekler) |
| Docker 29.9 (Docker Desktop) | Kurulu | Kapalıysa: `systemctl --user start docker-desktop` |
| PostgreSQL istemcisi | Ana makinede yok (sudo yok) | Docker'daki `postgres:16-alpine` istemcisi: `export PATH=$PWD/backend/scripts/tools/pg-docker:$PATH` (psql/pg_dump/pg_restore). Sunucu zaten Docker kabında çalışır. |
| Node 22 / npm | Kurulu | `admin/node_modules` kurulu |
| Flutter 3.47.8 | `~/flutter` | `export PATH=$HOME/flutter/bin:$PATH` (snap'teki 3.38.9 projeye eski; kullanılmaz) |

Repo yolu: `/home/muhone/projeler/sitesen`

`verify-stack.sh` PDF kontrolleri için Python'da `pypdf`, fotoğraf denetimi (adım 77) test görselleri için `pillow` gerekir: `python3 -m venv ~/.venv-siteeksen && ~/.venv-siteeksen/bin/pip install pypdf pillow`
ve doğrulamadan önce `export PATH=$HOME/.venv-siteeksen/bin:$PATH`.

**Doğrulama betikleri**

| Betik | Kapsam | Ne zaman |
|---|---|---|
| `bash backend/scripts/verify-stack.sh` | **1359 kontrol** — gofmt, dağıtım dosyası tutarlılığı, sıfırdan PostgreSQL, `cmd/migrate` ile 72 migration ve rol ataması, RLS (123 tablo, çapraz site uçtan uca testleri, rol yetkileri), şema denetimi, tam idempotency, `pkg/audit`+`pkg/legalparams`+`pkg/money`+`pkg/storage`+nisap testleri, ve uçtan uca: identity (giriş, roller, hesap etkinleştirme, şifre değiştirme, giriş kilidi), gateway (kimlik doğrulama), finance (ödeme→borç, gecikme tazminatı), governance (işletme projesi, nisap, defter zinciri), 501 dürüstlüğü ve 20 modülün uçtan uca sınanması (gider, personel, ziyaretçi, otopark, rezervasyon, kargo, sözleşme, belge, demirbaş, stok, anket, sayaç/ısı payı, bildirim, devriye, duyuru, ilan, ayarlar, enerji, tahsilat riski, NPS/ESG) zamanlanmış bildirimler (`cmd/scheduler`), yedekten geri yükleme ve kişisel veri anahtarı döndürme (`cmd/rotate-pii`); 2026-10-10 itibarıyla ayrıca SMS/SMTP (sahte Netgsm), PDF/Excel dökümleri, borcu yoktur belgesi, sayaç değişimi ve tüketim pusulası, geçiş cihazı canlılığı, yurt dışı telefon, site pasifleştirme, alacak dekontu ve banka ekstresi, kartla ödeme (IYZWSv2 imzasını doğrulayan sahte iyzico); 2026-10-11 itibarıyla ayrıca yeni borç bildirimi, yönetimin tahsilat girişi, şifremi unuttum, kendi telefon/e-posta değişikliği, malikin kiracı yönetimi, kademeli giriş kilidi, ilişik kesme tarihi, fatura sapma uyarısı ve pusula itirazı, havale dekontu | **Backend'e dokunan her değişiklikten sonra** |
| `bash backend/scripts/verify-mobile.sh` | **10 kontrol** — iki Flutter uygulaması için `pub get` + `analyze` (bilgi düzeyi dahil) + `test`, arayüzde uydurma veri taraması ve release manifestinde INTERNET izni | Mobil değişikliklerden sonra |
| `cd admin && npx tsc --noEmit && npm run lint && npm run build` | Panel | Panel değişikliklerinden sonra |
| `bash backend/scripts/dev-up.sh` | Geliştirme ortamını ayağa kaldırır | Elle deneme için |

Kural: Bir madde ancak çalıştığı **kanıtlandıktan** sonra tamamlandı işaretlenir
(`tasks/dogrulama-politikasi.md`). Go, Flutter, Docker ve PostgreSQL kurulu olduğu için
**"doğrulanamadı" mazereti artık yoktur.**

## Commands

### Full Stack (Docker)
```bash
cp .env.example .env                          # gizli değerleri doldur (boşsa compose açılmaz)
docker compose up -d --build                  # postgres → migrate → 25 servis → gateway → panel
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
