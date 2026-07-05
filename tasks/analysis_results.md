# SiteEksen Sistem Genel Analiz Raporu (Eksik & Mock Özellikler)

Bu rapor, önyüz (Next.js admin & Flutter mobil) ve backend (Go mikroservisleri) arasındaki entegrasyon açıklarını, gateway yönlendirme eksikliklerini ve mock olarak çalışan özellikleri detaylandırır.

---

## 1. Tamamen Mock (Sabit Veri) Olan Özellikler
Bu özellikler backend servislerinde bulunmamakta, API Gateway üzerinde statik JSON/dosya döndürülerek taklit edilmektedir:

*   **Dashboard Genel İstatistikleri (`GET /api/v1/dashboard/stats`)**
    *   *Durum:* Gateway (`backend/cmd/gateway/main.go`) içinde hardcoded olarak mock veriler (sakin sayısı, doluluk oranı vb.) dönüyor.
    *   *Eksik:* Backend'de bu verileri mikroservislerden toplayıp (aggregator) döndürecek bir dashboard/stats mekanizması veya servisi yok.
*   **Sayaç Yönetimi (`/api/v1/meters` & `/api/v1/meters/readings`)**
    *   *Durum:* Sayaç listeleri ve okumaları tamamen gateway üzerinde mock handler ile statik JSON olarak döndürülüyor.
    *   *Eksik:* Backend tarafında bir sayaç yönetim modülü/servisi bulunmuyor.
*   **Raporlama Modülü (`/api/v1/reports/generate` & `/api/v1/reports/:id/download`)**
    *   *Durum:* Rapor oluşturma ve PDF indirme işlemleri gateway üzerinde mock edilerek boş/sahte bir PDF (`%PDF-1.4 mock`) döndürülüyor.
    *   *Eksik:* Rapor üretmekten sorumlu bir backend servisi bulunmuyor veya gateway'e bağlı değil.

---

## 2. API Gateway Yönlendirme Eksiklikleri (404 Hatası Alan Gerçek Servisler)
Aşağıdaki servisler backend tarafında tam olarak kodlanmış ve docker-compose ile çalıştırılıyor olmalarına rağmen, API Gateway (`backend/cmd/gateway/main.go`) içinde sadece ana servis isimleri proxy edilmiş, ancak ilişkili diğer API yolları (endpoints) tanımlanmadığı için front-end tarafından çağrıldıklarında **404 Not Found** hatası vermektedir:

### A. Otopark Yönetimi (`parking-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(parkingURL), "/api/v1/parking")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/vehicles` (Araç kayıt ve listeleme)
    *   `/api/v1/parking-zones` (Otopark alanları)
    *   `/api/v1/parking-logs` (Giriş/çıkış logları)
    *   `/api/v1/plate-recognition` (AI plaka tanıma)
*   *Sonuç:* Next.js admin paneli araçları yüklemeye çalıştığında veya plaka tanıma yapıldığında 404 hatası alınır.

### B. Personel ve İzin Yönetimi (`personnel-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(personnelURL), "/api/v1/personnel")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/employees` (Personel listeleme/ekleme)
    *   `/api/v1/payroll` (Bordro işlemleri)
    *   `/api/v1/leaves` (İzin talepleri ve onayları)
*   *Sonuç:* Admin panelde personel listeleri ve izin onaylama işlemleri çalışmamaktadır.

### C. Rezervasyon Yönetimi (`reservation-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(reservationURL), "/api/v1/reservations")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/facilities` (Ortak alan tesis listesi)
*   *Sonuç:* Rezervasyon sayfasında tesisler listelenemediği için yeni rezervasyon oluşturulamaz.

### D. Envanter Yönetimi (`inventory-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(inventoryURL), "/api/v1/inventory")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/stock-movements` (Stok giriş/çıkış ve düzenleme)
*   *Sonuç:* Stok hareketleri eklenirken veya listelenirken hata alınır.

### E. Kargo/Paket Yönetimi (`package-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(packageURL), "/api/v1/packages")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/carriers` (Kargo firmaları listesi)
    *   `/api/v1/units/:unit_id/packages` (Bağımsız bölüm kargoları)
*   *Sonuç:* Kargo girişi yapılırken taşıyıcı firmalar yüklenemez.

### F. Devriye Yönetimi (`patrol-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(patrolURL), "/api/v1/patrol")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/patrol-routes` (Devriye rotaları)
    *   `/api/v1/patrol-sessions` (Devriye oturumları ve raporları)
*   *Sonuç:* Devriye yönetimi ekranları 404 hatası verir.

### G. Akıllı Tahsilat Yönetimi (`smart-collection-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(smartCollectionURL), "/api/v1/smart-collection")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/collection` (Tüm alt rotalar: `/risks`, `/strategies`, `/predictions`, `/forecast`)
*   *Sonuç:* Akıllı tahsilat ve yapay zeka analiz ekranları 404 hatası verir.

### H. Anket Yönetimi (`survey-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(surveyURL), "/api/v1/surveys")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/my-surveys` (Sakine özel anket listesi)
*   *Sonuç:* Mobil uygulamada sakinler anket listesini çekemez.

### I. Varlık/Asset Yönetimi (`asset-service`)
*   *Gateway Rota Tanımı:* `proxyPaths(mux, newProxy(assetURL), "/api/v1/assets")`
*   *Backend Tarafında Sunulan Ama Proxy Edilmeyen Uç Noktalar:*
    *   `/api/v1/asset-categories` (Demirbaş kategorileri)
*   *Sonuç:* Demirbaş eklenirken kategori listesi çekilemez.

---

## 3. Docker-Compose'a ve Gateway'e Dahil Edilmemiş Servisler

*   **Banka Entegrasyon Servisi (`banking`)**
    *   *Durum:* Backend altında `backend/services/banking` klasöründe Go kodları (`main.go`, `turkish_banks.go`) bulunmaktadır.
    *   *Eksik:* `docker-compose.yml` dosyasına eklenmemiştir, container olarak ayağa kalkmaz ve API Gateway üzerinde proxy tanımı yoktur.
