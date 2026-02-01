# Uygulama Mağazası Yayın Rehberi

## Google Play Store

### 1. Geliştirici Hesabı Oluşturma

1. [Google Play Console](https://play.google.com/console) adresine gidin
2. Google hesabınızla giriş yapın
3. **Tek seferlik $25 kayıt ücreti** ödeyin
4. Geliştirici bilgilerini doldurun:
   - Geliştirici adı: SiteEksen
   - E-posta: developer@siteeksen.com
   - Telefon: [Telefon numarası]

### 2. Uygulama Oluşturma

1. "Uygulama oluştur" butonuna tıklayın
2. Uygulama detayları:
   - **Varsayılan dil:** Türkçe
   - **Uygulama adı:** SiteEksen
   - **Uygulama türü:** Uygulama
   - **Ücretsiz/Ücretli:** Ücretsiz

### 3. Mağaza Girişi

#### Kısa Açıklama (80 karakter)
```
Site ve apartman yönetimi için mobil uygulama. Aidat, sayaç, duyurular.
```

#### Tam Açıklama (4000 karakter)
```
SiteEksen ile site ve apartman yönetimi artık çok kolay!

🏠 NELER YAPABİLİRSİNİZ?

✅ AİDAT TAKİBİ
• Aidat borçlarınızı anlık görüntüleyin
• Güvenli online ödeme yapın
• Ödeme geçmişinizi takip edin

✅ SAYAÇ OKUMA
• Isı ve su sayaçlarınızı görün
• Aylık tüketim raporlarınızı inceleyin
• Tüketim karşılaştırmaları yapın

✅ DUYURULAR
• Site duyurularını anlık alın
• Önemli bilgileri kaçırmayın
• Bildirimlerle haberdar olun

✅ TALEP VE ŞİKAYET
• Teknik arıza bildirin
• Talep durumunuzu takip edin
• Yönetime mesaj gönderin

✅ ARAÇ VE KARGO
• Araç bilgilerinizi yönetin
• Kargo bildirimlerinizi alın

📱 KOLAY KULLANIM
• Modern ve kullanıcı dostu arayüz
• Hızlı giriş (biyometrik destekli)
• 7/24 erişim

🔒 GÜVENLİ
• Banka düzeyinde güvenlik
• Şifrelenmiş veriler
• KVKK uyumlu

Site yönetiminiz SiteEksen kullanıyorsa hemen indirin!
```

#### Ekran Görüntüleri (Gerekli)
- Minimum 2, maksimum 8 adet
- Boyut: 1080x1920 (telefon), 2048x1536 (tablet)
- Ana ekranlarda:
  1. Ana sayfa / Dashboard
  2. Aidat listesi
  3. Ödeme ekranı
  4. Duyurular
  5. Talep oluşturma

#### Uygulama İkonu
- Boyut: 512x512 px
- Format: PNG, 32-bit, alfa şeffaflığı ile

#### Özellik Grafiği
- Boyut: 1024x500 px
- Mağaza başlık görseli

### 4. İçerik Derecelendirmesi

IARC anketini doldurun:
- Şiddet içeriği: Yok
- Seksüel içerik: Yok
- İlaç referansı: Yok
- Dil: Yok
- Kullanıcı etkileşimi: Var (mesajlaşma)

**Beklenen derecelendirme:** PEGI 3 / Everyone

### 5. Gizlilik Politikası

URL: `https://siteeksen.com/legal/gizlilik-politikasi`

### 6. Uygulama Yükleme

```bash
# Flutter build
cd mobile
flutter build appbundle --release

# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

### 7. Test Aşamaları

1. **Dahili test** → Ekip içi test (hemen yayınlanır)
2. **Kapalı test** → Beta kullanıcılar (hemen yayınlanır)
3. **Açık test** → Genel beta (hemen yayınlanır)
4. **Üretim** → Tam yayın (1-3 gün inceleme)

---

## Apple App Store

### 1. Apple Developer Program

1. [Apple Developer](https://developer.apple.com/programs/) adresine gidin
2. **Yıllık $99 üyelik ücreti** ödeyin
3. D-U-N-S numarası gerekebilir (kurumsal için)
4. Onay süreci: 1-2 gün

### 2. App Store Connect Kurulumu

1. [App Store Connect](https://appstoreconnect.apple.com) giriş
2. "My Apps" → "+" → "New App"
3. Bilgiler:
   - Platform: iOS
   - Bundle ID: com.siteeksen.app
   - SKU: SITEEKSEN001
   - Kullanıcı Erişim: Tam Erişim

### 3. Sertifika ve Profiller

Xcode veya Apple Developer portalından:

1. **Sertifikalar:**
   - Distribution Certificate (production için)
   
2. **App ID:**
   - Explicit App ID: com.siteeksen.app
   - Capabilities: Push Notifications, Sign in with Apple

3. **Provisioning Profile:**
   - App Store Distribution profili

### 4. Mağaza Bilgileri

Tüm bilgiler Google Play ile aynı, ancak:
- Ekran görüntüleri farklı boyutlarda (iPhone, iPad)
- "What's New" bölümü (güncelleme notları)

### 5. App Review Kuralları

Dikkat edilecekler:
- ✅ Gizlilik politikası linki
- ✅ Login gerektiriyorsa test hesabı sağlayın
- ✅ Ödeme sistemleri Apple Pay kullanmalı (app içi satın alma)
- ✅ Minimum iOS sürümü belirtin

### 6. Uygulama Yükleme

```bash
# iOS build
cd mobile
flutter build ipa --release

# veya Xcode'dan Archive → Distribute App
```

### 7. İnceleme Süreci

- Ortalama süre: 24-48 saat
- Reddedilirse düzeltme yapıp tekrar gönderin
- "Expedited Review" acil durumlar için talep edilebilir

---

## Kontrol Listesi

### Google Play Store
- [ ] Geliştirici hesabı ($25 ödendi)
- [ ] Store listing tamamlandı
- [ ] Ekran görüntüleri yüklendi
- [ ] Gizlilik politikası linki eklendi
- [ ] İçerik derecelendirmesi tamamlandı
- [ ] AAB dosyası yüklendi
- [ ] Dahili test geçildi
- [ ] Üretime yayınlandı

### Apple App Store
- [ ] Apple Developer Program ($99/yıl)
- [ ] Sertifikalar oluşturuldu
- [ ] App Store Connect kuruldu
- [ ] Store bilgileri dolduruldu
- [ ] Ekran görüntüleri yüklendi
- [ ] Test hesabı bilgileri sağlandı
- [ ] IPA dosyası yüklendi
- [ ] Review onaylandı

---

## Faydalı Linkler

- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com)
- [Google Play Politikaları](https://play.google.com/about/developer-content-policy/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
