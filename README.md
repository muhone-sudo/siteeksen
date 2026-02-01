# SiteEksen - Site Yönetim Platformu

Türkiye'deki Kat Mülkiyeti Kanunu'na tam uyumlu, mikroservis mimarisine sahip site yönetim platformu.

## 🏗️ Proje Yapısı

```
sitesen/
├── backend/                    # Go mikroservisler
│   ├── services/
│   │   ├── identity/          # Kimlik doğrulama servisi
│   │   └── finance/           # Finans servisi
│   ├── pkg/                   # Ortak paketler
│   │   ├── database/
│   │   ├── encryption/
│   │   └── middleware/
│   └── migrations/            # SQL migration dosyaları
├── mobile/                    # Flutter mobil uygulama
│   └── lib/
│       ├── core/             # Tema, router, network
│       └── features/         # Özellik modülleri
├── api/                      # OpenAPI spesifikasyonu
├── kong/                     # API Gateway yapılandırması
└── docker-compose.yml        # Tüm servisleri çalıştırma
```

## 🚀 Başlangıç

### Gereksinimler

- Docker & Docker Compose
- Go 1.21+
- Flutter 3.16+
- PostgreSQL 16

### Backend Başlatma

```bash
# Tüm servisleri başlat
docker-compose up -d

# Sadece veritabanını başlat
docker-compose up -d postgres redis

# Log'ları izle
docker-compose logs -f
```

### Mobil Uygulama

```bash
cd mobile

# Bağımlılıkları yükle
flutter pub get

# Build runner (model generation)
flutter pub run build_runner build

# Uygulamayı çalıştır
flutter run
```

## 📡 API Endpoint'leri

| Endpoint | Metod | Açıklama |
|----------|-------|----------|
| `/api/v1/auth/login` | POST | Kullanıcı girişi |
| `/api/v1/finance/debt-status` | GET | Borç durumu |
| `/api/v1/finance/assessments` | GET | Aidat listesi |
| `/api/v1/finance/payments` | POST | Ödeme başlat |
| `/api/v1/requests` | GET/POST | Talep yönetimi |

Detaylı API dokümantasyonu: `/api/openapi.yaml`

## 🔒 Güvenlik

- **Şifreleme:** AES-256-GCM (TCKN, telefon)
- **Kimlik Doğrulama:** JWT (15 dakika access, 7 gün refresh)
- **KVKK:** Audit log mekanizması aktif

## 📱 Mobil Ekranlar

- **Dashboard:** Borç durumu, ilan panosu, tüketim grafiği
- **Finans:** Aidat listesi, ödeme geçmişi
- **Talepler:** İş emri oluşturma ve takip
- **Daha Fazla:** Araçlar, duyurular, ayarlar

## 🔧 Ortam Değişkenleri

```env
# Backend
DB_HOST=localhost
DB_PORT=5432
DB_USER=siteeksen
DB_PASSWORD=your_password
DB_NAME=siteeksen
JWT_SECRET=your_jwt_secret

# Mobile
API_BASE_URL=http://localhost:8000/api/v1
```

## 📄 Lisans

Tüm hakları saklıdır © 2026 SiteEksen
