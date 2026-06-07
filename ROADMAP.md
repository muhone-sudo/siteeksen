# ROADMAP

Proje ilerleme durumu ve planlaması.

---

## Durum Göstergesi
- ✅ Tamamlandı
- 🔄 Devam ediyor
- 📋 Planlandı
- ❌ Yapılmadı

---

## Backend Mikroservisler

| Servis | Durum | Port | Notlar |
|--------|-------|------|--------|
| identity | ✅ | 8081 | Docker'da aktif; gerçek `residents`/`units` modülü eklendi (Mock→DB Faz 1) |
| finance | ✅ | 8082 | Docker'da aktif, iyzico entegre |
| community | ✅ | 8083 | Docker'da aktif |
| iot | ✅ | 8084 | Docker'da aktif, MongoDB bağlı |
| notification | ✅ | 8085 | Docker'da aktif, Firebase + Kafka |
| expense | ✅ | 8086 | Servis yazıldı, docker-compose'a eklenmedi |
| asset | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| banking | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| bulletin | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| contract | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| document | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| energy_analytics | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| esg | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| inventory | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| meeting_wizard | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| nps | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| package | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| parking | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| patrol | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| personnel | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| reservation | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| settings | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| smart_collection | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| survey | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| visitor | ✅ | — | Servis yazıldı, docker-compose'a eklenmedi |
| gateway (dev) | ✅ | 8888 | Docker'da aktif |

### Backend Yapılacaklar
- ✅ **identity-service: Gerçek `residents`/`units` modülü** — `GET/POST /api/v1/residents`, `GET/PATCH /api/v1/residents/:id`, `GET /api/v1/units`; `resident_units`/`users`/`units` JOIN sorgularıyla DB'ye bağlandı (Mock verilerin DB'ye bağlanması — Faz 1/6, Adım 1/4)
- ✅ **Gateway: `/api/v1/residents`+`/api/v1/units` mock handler'ları kaldırılıp identity-service'e proxy edildi** (Mock verilerin DB'ye bağlanması — Faz 1/6, Adım 2/4)
- ✅ **Mock→DB Faz 1 (Sakinler/Birimler) tamamlandı** — identity-service modülü → gateway proxy → admin panel → admin_app (4/4 adım); admin_app `/users?role=RESIDENT` konvansiyonu admin panelin `/residents` kontratıyla birleştirildi. Sıradaki faz: Faz 2 — Finans (Aidat/Ödemeler)
- ✅ **Demo gateway gerçek reverse proxy'ye dönüştürüldü** — identity, finance, community servislerine proxy; henüz olmayan servisler için mock
- ✅ **Tüm 19 yeni servis docker-compose.yml'e eklendi** — port atandı, Dockerfile yazıldı, hepsi çalışıyor
- ✅ **Kong `kong.yml` güncellendi** — 24 servis (tüm mikroservisler) Kong üzerinden yönlendiriliyor
- ✅ **Gateway v1.2.0** — 24 servise proxy routing; tüm yeni servisler docker-compose env'de tanımlı
- ✅ **KVKK açık rıza akışı + audit log aktif edildi** — migration `009_kvkk_consent.sql` (`users.kvkk_consent_at`), identity-service `POST /users/me/kvkk-consent` + login yanıtında `kvkk_consent_required`; `pkg/audit/` paketi ve gerçek `INSERT INTO audit_logs` ile tamamlanan `AuditLog()` middleware'i `identity`/`finance` route gruplarına bağlandı (Apsiyon karşılaştırması, Paket 5)
- ✅ **RBAC: Rol bazlı yetkilendirme aktif edildi** — `RequireRole()` middleware'i `MANAGER`/`AUDITOR`/`STAFF` rol sabitleriyle birlikte `POST /users/me/properties` endpoint'ine bağlandı; migration `008_manager_roles.sql` ile demo yöneticiye `MANAGER` rolü eklendi (Apsiyon karşılaştırması, Paket 3)
- 📋 Her servis için birim testleri yaz (şu an sadece `tests/integration_test.go` var)
- 📋 `pkg/integrations/ai/` — OpenAI Vision gerçek API key ile test edilmeli
- 📋 `pkg/integrations/bank/` — banka entegrasyonu gerçek ortamda test edilmeli
- 📋 Kafka consumer'ları genişlet (şu an sadece notification servisi tüketiyor)

---

## Admin Paneli (Next.js)

| Sayfa | Durum | Notlar |
|-------|-------|--------|
| Login | ✅ | NextAuth ile |
| Dashboard (genel bakış) | ✅ | |
| Sakinler | ✅ | Gerçek API'ye bağlandı — `apiClient.getResidents/getUnits/createResident/updateResident` (Mock→DB Faz 1, Adım 3/4); bakiye sütunu finance entegrasyonu bekleniyor |
| Aidatlar | ✅ | |
| Sayaçlar | ✅ | |
| Talepler | ✅ | |
| Duyurular | ✅ | |
| Raporlar | ✅ | |
| Ayarlar | ✅ | |
| Muhasebe | 🔄 | Sayfa var, backend bağlantısı eksik |
| Bildirimler | 🔄 | Sayfa var, backend bağlantısı eksik |
| API Kimlik Bilgileri | 🔄 | Sayfa var, backend bağlantısı eksik |

### Admin Panel Yapılacaklar
- ✅ `api-client.ts` gateway üzerinden gerçek servislere bağlandı
- ✅ Token refresh mantığı implement edildi
- ✅ **Muhasebe sayfası backend'e bağlandı** — expense servisi `/api/v1/expenses`
- ✅ **Bildirimler sayfası backend'e bağlandı** — notification servisi `/api/v1/notifications`
- ✅ **API Credentials sayfası backend'e bağlandı** — settings servisi `/api/v1/credentials`
- ✅ **Gider yönetimi sayfası eklendi** — `/dashboard/expenses`; fatura takibi, kategori filtreleme, mock fallback
- ✅ **Otopark sayfası eklendi** — `/dashboard/parking`; araç listesi, şu an içeridekiler, giriş/çıkış işlemleri
- ✅ **Personel sayfası eklendi** — `/dashboard/personnel`; çalışan listesi, izin talepleri, onaylama
- ✅ **Rezervasyon sayfası eklendi** — `/dashboard/reservations`; tesis ve rezervasyon yönetimi, iptal
- ✅ **Ziyaretçi sayfası eklendi** — `/dashboard/visitors`; giriş/çıkış takibi, QR kayıt, bugün/içeride filtreleme
- ✅ **Sidebar güncellendi** — 5 yeni nav öğesi eklendi (Gider Yönetimi, Otopark, Personel, Rezervasyon, Ziyaretçi)
- ✅ **Tüm sayfalara edit/delete eklendi** — Soft-delete pattern (deleted=1), onay modalı, shared add/edit form
- ✅ **CSV upload/download** — residents, expenses, parking, personnel, visitors, meters, assessments, announcements, requests sayfalarında gerçek CSV işleme + örnek CSV indirme
- ✅ **Credentials sayfası güvenlik** — Şifreler sayfa açılışında yüklenmiyor, "Göster" butonuyla çekiliyor + audit log
- ✅ **Muhasebe/Bildirimler/Sayaçlar** — Accounting edit/delete, notifications history delete, meters gerçek save readings
- ✅ **Backend soft-delete altyapısı** — Migration 006 (23 tablo + index), identity ve finance repository sorgularına `AND deleted = 0` filtresi
- ✅ **Sidebar site/apartman seçici gerçek backend'e bağlandı** — `GET /users/me/properties` → seçimde `setActiveProperty` → `refreshAccessToken` → reload zinciri; NextAuth session ↔ apiClient token köprüsü kuruldu; canlı ortamda uçtan uca doğrulandı
- ✅ **Yeni site ekleme özelliği** — `POST /users/me/properties` (identity) ile site + varsayılan unit + `resident_units(OWNER)` tek transaction'da oluşturuluyor; sidebar modalı ile oluştur → otomatik geçiş zinciri canlı ortamda doğrulandı
- ✅ **Property türü (`type`)** — migration `007_property_type.sql`; `properties.type` (SITE/APARTMENT/BUILDING, default SITE); sidebar "Yeni Taşınmaz Ekle" modalına Tür seçici eklendi

---

## Mobil Uygulama — Sakin (Flutter `mobile/`)

| Ekran | Durum | Notlar |
|-------|-------|--------|
| Ana Sayfa | ✅ | |
| Aidat/Ödeme | ✅ | |
| Talepler | ✅ | |
| Duyurular | ✅ | |
| İlan Panosu | ✅ | |
| Enerji Tüketimi | ✅ | |
| Koli Takibi | ✅ | |
| Rezervasyon | ✅ | |
| Ziyaretçi Ön Kayıt | ✅ | |
| Anketler | ✅ | |
| Belgeler | ✅ | |
| Varlıklar | ✅ | |
| Profil/Ayarlar | ✅ | |
| NPS değerlendirme | 📋 | nps servisi hazır, mobil ekran yok |
| ESG/Sürdürülebilirlik | 📋 | esg servisi hazır, mobil ekran yok |

### Mobil Yapılacaklar
- 📋 Gerçek API entegrasyonu (çoğu ekranda mock data var)
- 📋 Retrofit/Dio ile API client'ları tamamla
- 📋 Push notification alma ve gösterme akışını test et
- ✅ **Talep onay mekanizması** — `community-service` mock'tan gerçek DB-bağlı `requests` modülüne geçirildi; sakin "sorunum çözüldü" diyerek onaylayabiliyor (`CLOSED` + `user_confirmed_at`) ya da reddedip talebi `IN_PROGRESS`'e geri gönderebiliyor — `mobile`/`admin_app`/admin panel uçtan uca güncellendi (Apsiyon karşılaştırması, Paket 1 — son paket)
- ✅ **Biyometrik giriş (`local_auth`) tam entegrasyonu** — `mobile` ve `admin_app`'te `flutter_secure_storage` tabanlı kalıcı oturum + gerçek `apiClient.login()` akışı + parmak izi/yüz tanıma ile oturum yenileme (Apsiyon karşılaştırması, Paket 4)
- 📋 App Store / Google Play yayınlama (`docs/store-publishing-guide.md` hazır)
- ✅ **Android geri tuşu navigasyon düzeltmesi** — `main_screen.dart`'a `PopScope` eklendi (Apsiyon karşılaştırması, Paket 2)
- ✅ **KVKK açık rıza ekranı** — ilk girişte zorunlu, geçilemez (`PopScope(canPop: false)`) onay ekranı eklendi; `admin_app`'e de aynı akış uygulandı (Paket 5)

---

## Admin Mobil Uygulaması (Flutter `admin_app/`)

| Ekran | Durum | Notlar |
|-------|-------|--------|
| Login | ✅ | |
| Dashboard | ✅ | |
| Sakinler | ✅ | Gerçek API'ye bağlandı, `/users`→`/residents` konvansiyon birleştirmesi yapıldı (Mock→DB Faz 1, Adım 4/4 — Faz 1 tamamlandı) |
| Finans | ✅ | |
| Sayaçlar | ✅ | |
| Duyurular | ✅ | |
| Talepler | ✅ | |
| Raporlar | ✅ | |
| Personel Yönetimi | ✅ | |
| Rezervasyon Yönetimi | ✅ | |
| Ziyaretçi Yönetimi | ✅ | |
| Enerji Panosu | ✅ | |
| Otopark Yönetimi | ✅ | |
| Envanter Yönetimi | ✅ | |
| Gider Yönetimi | ✅ | AI fatura tarama dahil |
| Sözleşme Yönetimi | ✅ | |
| Varlık Yönetimi | ✅ | |
| İlan Panosu | ✅ | |
| Banka Entegrasyonu | ✅ | |
| Akıllı Tahsilat | ✅ | |
| Toplantı Sihirbazı | ✅ | |
| Koli Takibi | ✅ | |
| Güvenlik Turu | ✅ | |
| Anket Yönetimi | ✅ | |
| API Ayarları | ✅ | |
| Belge Yönetimi | 📋 | Servis hazır, admin app ekranı yok |
| NPS Analiz | 📋 | Servis hazır, ekran yok |
| ESG Raporu | 📋 | Servis hazır, ekran yok |

---

## Altyapı & DevOps

| Konu | Durum | Notlar |
|------|-------|--------|
| Docker Compose (geliştirme) | ✅ | |
| Kong API Gateway | ✅ | Temel 5 servis yönlendirmesi var |
| Kubernetes manifests | ✅ | `k8s/` dizininde |
| CI/CD (GitHub Actions) | ✅ | `.github/workflows/ci-cd.yaml` |
| PostgreSQL + migrations | ✅ | 5 migration tamamlandı |
| Redis | ✅ | |
| MongoDB (IoT) | ✅ | |
| Kafka | ✅ | Zookeeper ile |
| Kong güncelleme (yeni servisler) | 📋 | 20+ servis kong.yml'e eklenmeli |
| Üretim ortamı env değişkenleri | 📋 | `.env.example` mevcut |
| SSL/TLS yapılandırması | 📋 | |
| Monitoring / Alerting | 📋 | Grafana, Prometheus |
| Log aggregation | 📋 | ELK veya Loki |

---

## Entegrasyonlar

| Entegrasyon | Durum | Notlar |
|-------------|-------|--------|
| iyzico (ödeme) | ✅ | Sandbox bağlantısı kurulu |
| Firebase (push) | ✅ | `firebase-credentials.json` gerekli |
| SMS servisi | ✅ | `pkg/integrations/sms/` hazır |
| WhatsApp | ✅ | `pkg/integrations/whatsapp/` hazır |
| AI fatura tarama | ✅ | OpenAI Vision / Google Document AI |
| Banka entegrasyonu | ✅ | `services/banking/turkish_banks.go` |
| E-Devlet / Belediye | 📋 | Planlandı |
| e-Fatura | 📋 | Planlandı |
