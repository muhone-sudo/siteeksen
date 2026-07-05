# Todo

Aktif görevler burada takip edilir.

---

## Oturum Talimatları (Otonom — Kullanıcı Uyuyor)

Kullanıcı bu oturumda uyuyor. Onay gelmeyecek. Her tamamlanan adımı direkt commit et. Token bitene kadar çalış.

### Genel Kurallar Bu Oturum İçin:
1. **Soft delete**: Tüm projede hard delete yok. DB'de `deleted` sütunu (0=mevcut, 1=silinmiş). Sorgular `WHERE deleted = 0` ile çalışır.
2. **Edit/Delete**: Veri gösteren/ekleyen tüm sayfalarda düzenleme ve silme işlevi olmalı.
3. **Şifre sayfası (credentials)**: Şifreler sayfa açılışında DB'den çekilmez. "Göster" butonuna basılınca çekilir + log yazılır.
4. **Input/form kontrolleri**: Tüm input ve box'ların doğru çalıştığını kontrol et.
5. **Bulk update + CSV upload**: Uygun tüm sayfalara ekle. Örnek CSV indirme butonu olsun.
6. **Her küçük iş sonrası direkt commit.**

---

## Tamamlanan Görevler

### Faz 1: Sayfa Denetimi + Edit/Delete + CSV
- ✅ residents — edit/delete + soft-delete + CSV upload/download
- ✅ assessments — edit/delete + soft-delete + CSV upload/download
- ✅ meters — edit/delete + soft-delete + CSV upload/download
- ✅ announcements — edit/delete + soft-delete + CSV upload/download
- ✅ requests — edit/delete + soft-delete + durum güncelleme + CSV upload/download
- ✅ accounting — gelir/gider edit/delete + soft-delete + toplu işlemler
- ✅ expenses — edit/delete + soft-delete + CSV upload/download
- ✅ notifications — geçmiş kayıtlarda soft-delete
- ✅ parking — araç edit/delete + soft-delete + CSV upload/download
- ✅ personnel — edit/delete + soft-delete + CSV upload/download
- ✅ reservations — edit/delete + soft-delete
- ✅ visitors — edit/delete + soft-delete + CSV upload/download

### Faz 2: Credentials Sayfası
- ✅ Sayfa açılışında şifreler maskelendi
- ✅ "Göster" butonuna basılınca API'den çek + audit log
- ✅ Log sekmesinde gerçek log listesi

### Faz 3: Soft Delete — Backend Migration
- ✅ Migration 006: 23 tabloya deleted INTEGER NOT NULL DEFAULT 0 + index
- ✅ identity/repository/user.go: AND deleted = 0 eklendi
- ✅ finance/repository/finance.go: 4 sorguya AND deleted = 0 eklendi

### Genel
- ✅ 5 yeni admin panel sayfası (expenses, parking, personnel, reservations, visitors)
- ✅ Sidebar 5 yeni nav öğesi
- ✅ api-client.ts tam kapsam
- ✅ Gateway v1.2.0, Kong 24 servis
- ✅ 19 servis docker-compose'a eklendi
- ✅ exec format hataları düzeltildi

---

## Bekleyen (Backend / Diğer)

### Faz 1: Gateway Rota Düzeltmeleri (Tamamlandı)
- ✅ `parking-service` proxy rotalarını ekle: `/api/v1/vehicles`, `/api/v1/parking-zones`, `/api/v1/parking-logs`, `/api/v1/plate-recognition`
- ✅ `personnel-service` proxy rotalarını ekle: `/api/v1/employees`, `/api/v1/payroll`, `/api/v1/leaves`
- ✅ `reservation-service` proxy rotasını ekle: `/api/v1/facilities`
- ✅ `inventory-service` proxy rotasını ekle: `/api/v1/stock-movements`
- ✅ `package-service` proxy rotalarını ekle: `/api/v1/carriers`, `/api/v1/units/:unit_id/packages`
- ✅ `patrol-service` proxy rotalarını ekle: `/api/v1/patrol-routes`, `/api/v1/patrol-sessions`
- ✅ `smart-collection-service` proxy rotalarını ekle: `/api/v1/collection` (tüm alt yollar)
- ✅ `survey-service` proxy rotasını ekle: `/api/v1/my-surveys`
- ✅ `asset-service` proxy rotasını ekle: `/api/v1/asset-categories`

### Faz 2: Banka Entegrasyon Servisi (Tamamlandı)
- ✅ `banking` servisini `docker-compose.yml`'e ekle
- ✅ Gateway `/api/v1/banking` rotasını proxy et
- ✅ Next.js ve Flutter (`admin_app`) tarafında banka entegrasyon ekranlarını bağla

### Faz 3: Dashboard Genel İstatistikleri (Aggregator) (Tamamlandı)
- ✅ Gateway mock dashboard stats handler'larını kaldır
- ✅ Backend stats aggregator uç noktasını geliştir
- ✅ Front-end istatistik bileşenlerini bu gerçek uç noktalara bağla

### Faz 4: Sayaç Yönetimi Servis Katmanı (Tamamlandı)
- ✅ Gateway mock `/api/v1/meters` handler'larını kaldır
- ✅ Sayaç listeleme, okuma ekleme ve bulk okuma işlemlerini `iot-service` üzerinden DB şemasına bağla
- ✅ Front-end sayaç sayfalarını bu gerçek servise proxy et

### Faz 5: Raporlama Servis Katmanı (Tamamlandı)
- ✅ Gateway mock `/api/v1/reports/` handler'larını kaldır
- ✅ Gerçek PDF/Excel rapor üretecek entegrasyonu `pkg/reports` ile gateway'e bağla
- ✅ Front-end rapor indirme/üretme butonlarını bu gerçek servise yönlendir

### Ustalık Mobil Entegrasyon Planı
#### Faz 1: Sakin Uygulaması Entegrasyonu (`mobile/`) (Tamamlandı)
- ✅ `mobile/lib/core/network/api_client.dart` içerisine eksik metotları eklemek
- ✅ Rezervasyon ekranını gerçek API'ye bağlamak
- ✅ Duyuru ve Anket ekranlarını gerçek API'ye bağlamak
- ✅ Kargo/Paket ekranını gerçek API'ye bağlamak
- ✅ İlan Panosu (Bulletin) ekranını gerçek API'ye bağlamak

#### Faz 2: Yönetici Uygulaması Temel Servisleri (`admin_app/`) (Tamamlandı)
- ✅ `admin_app/lib/core/network/api_client.dart` içerisine otopark, personel, ziyaretçi ve kargo metotlarını eklemek
- ✅ Otopark ekranını gerçek `parking-service`'e bağlamak
- ✅ Personel ekranını gerçek `personnel-service`'e bağlamak
- ✅ Ziyaretçi ekranını gerçek `visitor-service`'e bağlamak
- ✅ Kargo ekranını gerçek `package-service`'e bağlamak

#### Faz 3: Yönetici Finansal ve İleri Düzey Servisler (`admin_app/`) (Tamamlandı)
- ✅ `admin_app/lib/core/network/api_client.dart` içerisine banka ve rezervasyon metotlarını eklemek
- ✅ Banka entegrasyon ekranını gerçek `banking-service`'e bağlamak
- ✅ Tesis Rezervasyon ekranını gerçek `reservation-service`'e bağlamak

### Diğer Bekleyenler
- ✅ Backend birim testleri (pkg/reports için PDF/Excel testleri yazıldı ve doğrulandı)
- 📋 OpenAI Vision entegrasyonu gerçek API key ile test
- 📋 Banka entegrasyonu gerçek ortamda test
- 📋 Kafka consumer genişletme
- 📋 Admin app: Belge Yönetimi ekranı
- 📋 Mobil: NPS + ESG ekranları
- 📌 Iyzico Entegrasyonu (Sonradan yazılacak - Ertelendi)
- 📌 WhatsApp Entegrasyonu (Sonradan yapılacak - Ertelendi)


---

## İnceleme Notları

Soft-delete pattern: interface'de deleted: number, display filter deleted === 0, silme deleted = 1. Backend: migration 006 + 2 repository güncellendi.

---

## Ek Tur: Input/Form Denetimi (Tamamlandı)

Tüm dashboard sayfalarında onClick'siz buton, onChange'siz input/select/checkbox taraması yapıldı:
- ✅ Settings: Genel Ayarlar formu controlled hale getirildi + kaydet butonu çalışıyor
- ✅ Settings: Bildirim checkbox'ları state'e bağlandı
- ✅ Settings: Kullanıcı listesine edit/delete (soft-delete) eklendi, işlevsiz "⋮" kaldırıldı
- ✅ Reports: PDF/Excel/E-posta butonları işlevsel (CSV indirme + onay mesajı)
- ✅ Meters: "Okuma Dönemi" select controlled hale getirildi
- ✅ Credentials: writeLog'daki anlamsız apiClient.createExpense kontrolü temizlendi
- ✅ Backend binary'ler (.gitignore'a eklendi, untracked dosyalar temizlendi)

Tarama sonucu: başka onClick/onChange eksikliği bulunamadı.
