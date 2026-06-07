# CHANGELOG

Projedeki tüm önemli değişiklikler bu dosyada takip edilir.

---

## [Unreleased]

### Eklendi
- **Yeni site ekleme özelliği** — Sidebar'daki "+ Yeni Site Ekle" butonu artık çalışıyor: `POST /users/me/properties` endpoint'i (identity servisi) tek transaction içinde `properties` + varsayılan `unit` ("A-YÖNETİM") + `resident_units` (`OWNER`) satırlarını oluşturuyor — böylece yeni site mevcut `GetUserProperties` join zincirinde anında görünüyor. Frontend'de modal form (Site Adı, Adres, Şehir, İlçe) → oluşturma → otomatik aktif site seçimi → token yenileme → sayfa yenileme zinciri canlı ortamda uçtan uca doğrulandı.
- **Property türü (`type`) — şema değişikliği** — `properties` tablosuna `type VARCHAR(20) NOT NULL DEFAULT 'SITE'` kolonu eklendi (migration `007_property_type.sql`, idempotent). `SITE`/`APARTMENT`/`BUILDING` değerleri destekleniyor; geçersiz/boş değer servis katmanında `SITE`'a normalize ediliyor. Sidebar'daki modal "Yeni Taşınmaz Ekle" olarak güncellendi, "Tür" seçici (Site/Apartman/Bina) eklendi. Canlı ortamda üç senaryo (geçerli tür, eksik tür, geçersiz tür) uçtan uca test edildi.

### Düzeltildi
- **Sidebar: Site/apartman seçici gerçek backend kontratına bağlandı** — `<select>` hiçbir state'e bağlı değildi, seçim panele yansımıyordu. İlk denemede eklenen `X-Tenant-ID` header yaklaşımı, backend'de o middleware hiç bağlı olmadığı için geri alındı; bunun yerine identity serviste hazır olan gerçek mekanizmaya bağlandı: `GET /users/me/properties` (gerçek site listesi) → seçimde `POST /users/me/active-property` (DB güncelleme) → `/auth/refresh` (yeni `property_id` claim'li JWT) → sayfa yenileme. Zincir canlı ortamda uçtan uca test edildi.
- **NextAuth ↔ apiClient token köprüsü eklendi** — `session.accessToken`/`refreshToken` daha önce hiçbir yerde kullanılmıyordu; `apiClient`'in `localStorage`'ındaki token hep boştu, gerçek backend çağrıları sessizce 401 alıp mock'a düşüyordu. Artık `Sidebar` `useSession()` ile token'ları `apiClient.setToken()`'a köprülüyor.
- **Migration 006 (soft-delete) DB'ye uygulandı** — dosya önceki oturumda yazılmış ama hiç çalıştırılmamıştı; `users` tablosunda `deleted` kolonu yoktu ve bu yüzden TÜM giriş istekleri "Geçersiz telefon veya şifre" hatasıyla başarısız oluyordu. Migration idempotent (`IF NOT EXISTS`) olduğu için güvenle uygulandı.
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
