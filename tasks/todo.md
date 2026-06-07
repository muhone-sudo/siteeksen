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
- 📋 Backend birim testleri (şu an sadece integration_test.go var)
- 📋 OpenAI Vision entegrasyonu gerçek API key ile test
- 📋 Banka entegrasyonu gerçek ortamda test
- 📋 Kafka consumer genişletme
- 📋 Admin app: Belge Yönetimi ekranı
- 📋 Mobil: NPS + ESG ekranları

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
