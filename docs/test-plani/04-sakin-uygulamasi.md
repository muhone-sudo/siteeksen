# 4. Sakin uygulaması (web) — ekran ekran

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Uygulama: http://localhost:3002 (web derlemesi; tarayıcı penceresini telefon genişliğine — ~400 px — daraltın ya da cihaz araç çubuğunu kullanın). Adres çubuğuna `http://localhost:3002/#/<rota>` yazarak ekrana doğrudan gidilebilir; oturum yoksa giriş ekranına yönlenir. Web derlemesinde kamera (QR) ve konum (GPS) tarayıcı izniyle çalışır; izin penceresinde "İzin ver" seçin. Biyometrik giriş web'de yoktur (düğmesi görünmemeli).

### apple_widgets
- Dosya: `mobile/lib/core/widgets/apple_widgets.dart`

#### S-APPLE-WIDGETS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-00`

#### S-APPLE-WIDGETS-01 · Düğme: simge düğmesi (satır 35)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 35)" öğesine dokun (kaynak satırı 35); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-01`

#### S-APPLE-WIDGETS-02 · Düğme: simge düğmesi (satır 165)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 165)" öğesine dokun (kaynak satırı 165); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-02`

#### S-APPLE-WIDGETS-03 · Düğme: simge düğmesi (satır 215)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 215)" öğesine dokun (kaynak satırı 215); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-03`

#### S-APPLE-WIDGETS-04 · Düğme: simge düğmesi (satır 239)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 239)" öğesine dokun (kaynak satırı 239); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-04`

#### S-APPLE-WIDGETS-05 · Düğme: simge düğmesi (satır 292)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 292)" öğesine dokun (kaynak satırı 292); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-APPLE-WIDGETS-05`

---

### data_state
- Dosya: `mobile/lib/core/widgets/data_state.dart`

#### S-DATA-STATE-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/data_state.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/data_state.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-DATA-STATE-00`

#### S-DATA-STATE-01 · Düğme: Yeniden dene
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/data_state.dart`)
- **Adım:** "Yeniden dene" öğesine dokun (kaynak satırı 69); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DATA-STATE-01`

---

### future_list
- Dosya: `mobile/lib/core/widgets/future_list.dart`

#### S-FUTURE-LIST-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 90): Vazgeç
- **Adım:** Pencere (satır 107): Vazgeç
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-FUTURE-LIST-00`

#### S-FUTURE-LIST-01 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 94); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-FUTURE-LIST-01`

#### S-FUTURE-LIST-02 · Düğme: simge düğmesi (satır 95)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`)
- **Adım:** "simge düğmesi (satır 95)" öğesine dokun (kaynak satırı 95); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-FUTURE-LIST-02`

#### S-FUTURE-LIST-03 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 121); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-FUTURE-LIST-03`

#### S-FUTURE-LIST-04 · Düğme: Tamam
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/core/widgets/future_list.dart`)
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 122); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-FUTURE-LIST-04`

---

### announcements_screen
- Dosya: `mobile/lib/features/announcements/presentation/screens/announcements_screen.dart`

#### S-ANNOUNCEMENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/announcements
- **Adım:** Ekranı aç: http://localhost:3002/#/announcements — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /announcements` (community)
- **Adım:** Başlık (satır 80): Duyurular
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-ANNOUNCEMENTS-00`

#### S-ANNOUNCEMENTS-01 · Düğme: ${a[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/announcements
- **Adım:** "${a[" öğesine dokun (kaynak satırı 99); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /announcements/:id/read` (community, `services/community/main.go:124`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `announcement_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM announcement_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/announcements/:id/read' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/announcements`, Sakin `announcements_screen`, Sakin `resident_home_screen`, Yön.mobil `announcements_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-ANNOUNCEMENTS-01`

---

### activate_screen
- Dosya: `mobile/lib/features/auth/presentation/screens/activate_screen.dart`

#### S-ACTIVATE-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/activate
- **Adım:** Ekranı aç: http://localhost:3002/#/activate — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Mesaj (satır 118): Şifreniz belirlendi. Şimdi giriş yapabilirsiniz.
- **Adım:** Başlık (satır 131): Şifre Belirle
- **Adım:** Alan (satır 160): Telefon Numarası
- **Adım:** Alan (satır 160): 0555 123 45 67 · yurt dışı: +49 …
- **Adım:** Alan (satır 178): Kod
- **Adım:** Alan (satır 185): Yeni Şifre
- **Adım:** Alan (satır 192): Yeni Şifre (tekrar)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-ACTIVATE-00`

#### S-ACTIVATE-01 · Düğme: Yeniden gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/activate
- **Adım:** "Yeniden gönder" öğesine dokun (kaynak satırı 165)
- **Beklenen (yazma):** `POST /auth/password-reset/request` (identity, `services/identity/main.go:83`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/password-reset/request' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.self_reset` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.self_reset%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `S-ACTIVATE-01`

#### S-ACTIVATE-02 · Düğme: Şifremi Belirle
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/activate
- **Adım:** "Şifremi Belirle" öğesine dokun (kaynak satırı 196)
- **Beklenen (yazma):** `POST /auth/activate` (identity, `services/identity/main.go:81`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/activate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-ACTIVATE-02`

---

### kvkk_consent_screen
- Dosya: `mobile/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`

#### S-KVKK-CONSENT-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk-consent
- **Adım:** Ekranı aç: http://localhost:3002/#/kvkk-consent — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
- **Adım:** Başlık (satır 40): Kişisel Verilerin Korunması
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-CONSENT-00`

#### S-KVKK-CONSENT-01 · Düğme: Onaylıyorum ve Devam Ediyorum
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk-consent
- **Adım:** "Onaylıyorum ve Devam Ediyorum" öğesine dokun (kaynak satırı 84)
- **Beklenen (yazma):** `POST /users/me/kvkk-consent` (identity, `services/identity/main.go:103`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/kvkk-consent' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-CONSENT-01`

---

### login_screen
- Dosya: `mobile/lib/features/auth/presentation/screens/login_screen.dart`

#### S-LOGIN-00 · Ekran açılışı ve görünüm
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** Ekranı aç: http://localhost:3002/#/login — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Alan (satır 107): Telefon Numarası
- **Adım:** Alan (satır 109): 0555 123 45 67 · yurt dışı: +49 …
- **Adım:** Alan (satır 128): Şifre
- **Adım:** Mesaj (satır 236): Giriş başarısız: telefon veya şifre hatalı
- **Adım:** Pencere (satır 255): Biyometrik Giriş
- **Adım:** Mesaj (satır 293): Oturum yenilenemedi, lütfen şifrenizle giriş yapın
- **Adım:** Mesaj (satır 299): Biyometrik doğrulama başarısız
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-00`

#### S-LOGIN-01 · Düğme: simge düğmesi (satır 130)
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "simge düğmesi (satır 130)" öğesine dokun (kaynak satırı 130); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-01`

#### S-LOGIN-02 · Düğme: Şifremi Unuttum
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Şifremi Unuttum" öğesine dokun (kaynak satırı 155); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-02`

#### S-LOGIN-03 · Düğme: Giriş Yap
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Giriş Yap" öğesine dokun (kaynak satırı 163); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/login` (identity, `services/identity/main.go:78`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/login' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-03`

#### S-LOGIN-04 · Düğme: Biyometrik Giriş
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Biyometrik Giriş" öğesine dokun (kaynak satırı 180); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-04`

#### S-LOGIN-05 · Düğme: Hesabı Etkinleştir
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Hesabı Etkinleştir" öğesine dokun (kaynak satırı 200); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-05`

#### S-LOGIN-06 · Düğme: Hayır
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Hayır" öğesine dokun (kaynak satırı 261); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-06`

#### S-LOGIN-07 · Düğme: Etkinleştir
- **Hesap:** her hesap · **Nerede:** http://localhost:3002/#/login
- **Adım:** "Etkinleştir" öğesine dokun (kaynak satırı 265); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-LOGIN-07`

---

### bulletin_board_mobile_screen
- Dosya: `mobile/lib/features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart`

#### S-BULLETIN-BOARD-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** Ekranı aç: http://localhost:3002/#/bulletin — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /bulletins/:id/comments` (bulletin); `GET /bulletins` (bulletin)
- **Adım:** Başlık (satır 70): İlan Panosu
- **Adım:** Alan (satır 202): Kategori
- **Adım:** Alan (satır 208): Başlık
- **Adım:** Alan (satır 214): Açıklama
- **Adım:** Alan (satır 221): Fiyat (₺, isteğe bağlı)
- **Adım:** Alan (satır 343): Yorum yazın
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-00`

#### S-BULLETIN-BOARD-01 · Düğme: İlan Ver
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "İlan Ver" öğesine dokun (kaynak satırı 71); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /bulletins` (bulletin, `services/bulletin/main.go:85`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `bulletin.pending` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.pending%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-01`

#### S-BULLETIN-BOARD-02 · Düğme: ${b[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "${b[" öğesine dokun (kaynak satırı 128); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /bulletins/:id/close` (bulletin, `services/bulletin/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-02`

#### S-BULLETIN-BOARD-03 · Düğme: Kapat
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 150)
- **Beklenen (yazma):** `POST /bulletins/:id/close` (bulletin, `services/bulletin/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-03`

#### S-BULLETIN-BOARD-04 · Seçim: Kategori
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "Kategori" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-04`

#### S-BULLETIN-BOARD-05 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 230); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-05`

#### S-BULLETIN-BOARD-06 · Düğme: simge düğmesi (satır 344)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/bulletin
- **Adım:** "simge düğmesi (satır 344)" öğesine dokun (kaynak satırı 344)
- **Beklenen (yazma):** `POST /bulletins/:id/comments` (bulletin, `services/bulletin/main.go:136`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_comments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bulletin_comments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/comments' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-BULLETIN-BOARD-06`

---

### common_income_screen
- Dosya: `mobile/lib/features/common_income/presentation/screens/common_income_screen.dart`

#### S-COMMON-INCOME-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/common-income
- **Adım:** Ekranı aç: http://localhost:3002/#/common-income — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /governance/common-area/my-share` (governance)
- **Adım:** Başlık (satır 34): Ortak alan geliri payım
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-COMMON-INCOME-00`

#### S-COMMON-INCOME-01 · Düğme: simge düğmesi (satır 44)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/common-income
- **Adım:** "simge düğmesi (satır 44)" öğesine dokun (kaynak satırı 44); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-COMMON-INCOME-01`

#### S-COMMON-INCOME-02 · Düğme: simge düğmesi (satır 46)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/common-income
- **Adım:** "simge düğmesi (satır 46)" öğesine dokun (kaynak satırı 46); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-COMMON-INCOME-02`

---

### dask_screen
- Dosya: `mobile/lib/features/dask/presentation/screens/dask_screen.dart`

#### S-DASK-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/dask
- **Adım:** Ekranı aç: http://localhost:3002/#/dask — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /insurance/dask` (contract)
- **Adım:** Pencere (satır 45): ${r[
- **Adım:** Alan (satır 48): Poliçe no
- **Adım:** Alan (satır 49): Sigorta şirketi
- **Adım:** Mesaj (satır 87): Poliçe kaydedildi
- **Adım:** Başlık (satır 97): DASK poliçem
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-DASK-00`

#### S-DASK-01 · Düğme: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/dask
- **Adım:** "${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}" öğesine dokun (kaynak satırı 50); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DASK-01`

#### S-DASK-02 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/dask
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 71); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DASK-02`

#### S-DASK-03 · Düğme: Kaydet
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/dask
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 72); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DASK-03`

#### S-DASK-04 · Düğme: Poliçe gir
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/dask
- **Adım:** "Poliçe gir" öğesine dokun (kaynak satırı 113); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /insurance/dask` (contract, `services/contract/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `unit_insurance_policies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM unit_insurance_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/dask' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Sakin `dask_screen`, Yön.mobil `insurance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-DASK-04`

---

### documents_screen
- Dosya: `mobile/lib/features/documents/presentation/screens/documents_screen.dart`

#### S-DOCUMENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/documents
- **Adım:** Ekranı aç: http://localhost:3002/#/documents — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /documents` (document); `GET /documents/:id/download` (document)
- **Adım:** Başlık (satır 96): Belgeler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-DOCUMENTS-00`

#### S-DOCUMENTS-01 · Düğme: ${d[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/documents
- **Adım:** "${d[" öğesine dokun (kaynak satırı 113)
- **Beklenen (okuma):** `GET /documents/:id/download` (document) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `S-DOCUMENTS-01`

---

### emergency_screen
- Dosya: `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart`

#### S-EMERGENCY-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** Ekranı aç: http://localhost:3002/#/emergency — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /emergency/info` (community); `GET /emergency/checks` (community); `GET /emergency/cards/me` (community); `GET /users/me/properties` (identity)
- **Adım:** Mesaj (satır 99): ${res[
- **Adım:** Başlık (satır 110): Acil durum
- **Adım:** Mesaj (satır 230): Kayıtlı daireniz bulunamadı
- **Adım:** Mesaj (satır 242): ${res[
- **Adım:** Mesaj (satır 258): Kartınız ve rızanız silindi
- **Adım:** Başlık (satır 267): Acil bilgi kartım
- **Adım:** Alan (satır 279): Tahliyede yardım ihtiyacı
- **Adım:** Alan (satır 279): ör. tekerlekli sandalye, yatağa bağlı yakın, bebek
- **Adım:** Alan (satır 281): Ulaşılacak yakın (isteğe bağlı)
- **Adım:** Alan (satır 282): Yakının telefonu (isteğe bağlı)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-00`

#### S-EMERGENCY-01 · Düğme: Güvendeyim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** "Güvendeyim" öğesine dokun (kaynak satırı 140)
- **Beklenen (yazma):** `POST /emergency/checks/:id/respond` (community, `services/community/emergency.go:326`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `safety_check_responses` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM safety_check_responses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/checks/:id/respond' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `safety.need_help` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'safety.need_help%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-01`

#### S-EMERGENCY-02 · Düğme: Yardım gerekiyor
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** "Yardım gerekiyor" öğesine dokun (kaynak satırı 143)
- **Beklenen (yazma):** `POST /emergency/checks/:id/respond` (community, `services/community/emergency.go:326`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `safety_check_responses` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM safety_check_responses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/checks/:id/respond' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `safety.need_help` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'safety.need_help%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-02`

#### S-EMERGENCY-03 · Düğme: Acil bilgi kartım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** "Acil bilgi kartım" öğesine dokun (kaynak satırı 174); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-03`

#### S-EMERGENCY-04 · Düğme: Açık rızamla kaydet
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** "Açık rızamla kaydet" öğesine dokun (kaynak satırı 290)
- **Beklenen (yazma):** `PUT /emergency/cards/me` (community, `services/community/emergency.go:202`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_emergency_cards` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM resident_emergency_cards ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/cards/me' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-04`

#### S-EMERGENCY-05 · Düğme: Kartımı ve rızamı sil
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/emergency
- **Adım:** "Kartımı ve rızamı sil" öğesine dokun (kaynak satırı 294)
- **Beklenen (yazma):** `DELETE /emergency/cards/me` (community, `services/community/emergency.go:242`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_emergency_cards` — satır silinmiş olmalı: `SELECT xmin, * FROM resident_emergency_cards ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/cards/me' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-EMERGENCY-05`

---

### energy_consumption_mobile_screen
- Dosya: `mobile/lib/features/energy/presentation/screens/energy_consumption_mobile_screen.dart`

#### S-ENERGY-CONSUMPTION-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** Ekranı aç: http://localhost:3002/#/energy — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /consumption/statements` (iot); `GET /consumption/objections` (iot); `GET /consumption/statements/:id/pdf` (iot); `GET /finance/consumption/summary` (finance)
- **Adım:** Pencere (satır 395): Pusulaya itiraz
- **Adım:** Alan (satır 402): Gerekçe
- **Adım:** Alan (satır 403): Ör. sayaçta okunan değer, okuma tarihi, fotoğrafınızın tarihi
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-00`

#### S-ENERGY-CONSUMPTION-01 · Düğme: simge düğmesi (satır 231)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** "simge düğmesi (satır 231)" öğesine dokun (kaynak satırı 231); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-01`

#### S-ENERGY-CONSUMPTION-02 · Düğme: PDF
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** "PDF" öğesine dokun (kaynak satırı 340)
- **Beklenen (okuma):** `GET /consumption/statements/:id/pdf` (iot) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-02`

#### S-ENERGY-CONSUMPTION-03 · Düğme: İtiraz et
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** "İtiraz et" öğesine dokun (kaynak satırı 367); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /consumption/statements/:id/objections` (iot, `services/iot/main.go:471`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - Veritabanı tetikleyicileri çalışır: `consumption_statement_objections_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `consumption_statement_objections` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM consumption_statement_objections ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/consumption/statements/:id/objections' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `statement.objection` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'statement.objection%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Yön.mobil `meters_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-03`

#### S-ENERGY-CONSUMPTION-04 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 406); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-04`

#### S-ENERGY-CONSUMPTION-05 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/energy
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 407); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-ENERGY-CONSUMPTION-05`

---

### dues_payment_screen
- Dosya: `mobile/lib/features/finance/presentation/screens/dues_payment_screen.dart`

#### S-DUES-PAYMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** Ekranı aç: http://localhost:3002/#/finance/payment — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/properties` (identity); `GET /finance/clearance-certificates/:id/pdf` (finance); `GET /finance/credit-notes` (finance); `GET /finance/credit-notes/:id/pdf` (finance); `GET /finance/ledger/verify` (finance); `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance); `GET /finance/payments/:id/status` (finance)
- **Adım:** Dosya seçme (satır 18)
- **Adım:** Dosya seçme (satır 18)
- **Adım:** Başlık (satır 95): Aidat Ödeme
- **Adım:** Pencere (satır 367): Borcu yoktur belgesi
- **Adım:** Pencere (satır 388): Alacak dekontlarım
- **Adım:** Pencere (satır 446): Tahsilat kayıtları
- **Adım:** Pencere (satır 463): Ödeme Onayı
- **Adım:** Alan (satır 491): Havale açıklaması / dekont no (isteğe bağlı)
- **Adım:** Pencere (satır 532): Ödeme oluşturulamadı
- **Adım:** Pencere (satır 559): Ödeme işlemde
- **Adım:** Pencere (satır 609): Tamam
- **Adım:** Dosya seçme (satır 633)
- **Adım:** Pencere (satır 661): Tutar: ${formatTry(amount)}
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-00`

#### S-DUES-PAYMENT-01 · Düğme: Borcu yoktur belgesi
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Borcu yoktur belgesi" öğesine dokun (kaynak satırı 100); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/clearance-certificates` (finance, `services/finance/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41)
  - **Veritabanı (Adminer → SQL komutu):**
    - `clearance_certificates` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM clearance_certificates ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/clearance-certificates' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/units`, Sakin `dues_payment_screen`, Yön.mobil `units_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-01`

#### S-DUES-PAYMENT-02 · Düğme: Alacak dekontlarım
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Alacak dekontlarım" öğesine dokun (kaynak satırı 106); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /finance/credit-notes` (finance), `GET /finance/credit-notes/:id/pdf` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-02`

#### S-DUES-PAYMENT-03 · Düğme: Tahsilat kayıtlarını doğrula
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tahsilat kayıtlarını doğrula" öğesine dokun (kaynak satırı 112); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /finance/ledger/verify` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-03`

#### S-DUES-PAYMENT-04 · Düğme: Ödenecek tahakkuk yok / ${formatTry(_currentBalance)} Öde
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Ödenecek tahakkuk yok / ${formatTry(_currentBalance)} Öde" öğesine dokun (kaynak satırı 330); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Adım:** Dış bağlantı yeni sekmede açılır (kart ödemesinde sahte iyzico sayfası: http://localhost:18000/iyzico/pay/…)
- **Beklenen (yazma):** `POST /finance/payments/:id/receipts` (finance, `services/finance/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `payment_receipts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_receipts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/receipts' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`
- **Beklenen (yazma):** `POST /finance/payments` (finance, `services/finance/main.go:93`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `assessment_visible_to`
  - Veritabanı tetikleyicileri çalışır: `late_fee_accruals_active_property`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payment_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `late_fee_accruals` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payment_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-04`

#### S-DUES-PAYMENT-05 · Düğme: Tamam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 370); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-05`

#### S-DUES-PAYMENT-06 · Düğme: PDF
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "PDF" öğesine dokun (kaynak satırı 406)
- **Beklenen (okuma):** `GET /finance/credit-notes/:id/pdf` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-06`

#### S-DUES-PAYMENT-07 · Düğme: Kapat
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 415); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-07`

#### S-DUES-PAYMENT-08 · Düğme: Tamam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 449); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-08`

#### S-DUES-PAYMENT-09 · Düğme: Havaleyi yaptığınız gün
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Havaleyi yaptığınız gün" öğesine dokun (kaynak satırı 472); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-09`

#### S-DUES-PAYMENT-10 · Düğme: İptal
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "İptal" öğesine dokun (kaynak satırı 498); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-10`

#### S-DUES-PAYMENT-11 · Düğme: Devam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Devam" öğesine dokun (kaynak satırı 501); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-11`

#### S-DUES-PAYMENT-12 · Düğme: Tamam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 536); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-12`

#### S-DUES-PAYMENT-13 · Düğme: Arka planda bekle
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Arka planda bekle" öğesine dokun (kaynak satırı 574)
- **Beklenen (okuma):** `GET /finance/debt-status` (finance), `GET /finance/assessments` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-13`

#### S-DUES-PAYMENT-14 · Düğme: Tamam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 613)
- **Beklenen (okuma):** `GET /finance/debt-status` (finance), `GET /finance/assessments` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-14`

#### S-DUES-PAYMENT-15 · Düğme: Dekont ekle
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Dekont ekle" öğesine dokun (kaynak satırı 689)
- **Beklenen (yazma):** `POST /finance/payments/:id/receipts` (finance, `services/finance/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `payment_receipts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_receipts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/receipts' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-15`

#### S-DUES-PAYMENT-16 · Düğme: Tamam
- **Hesap:** KİRACI (kullanım borcu) ve MALİK_B1 (kendi dairesi) · **Nerede:** http://localhost:3002/#/finance/payment
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 697)
- **Beklenen (okuma):** `GET /finance/debt-status` (finance), `GET /finance/assessments` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-DUES-PAYMENT-16`

---

### finance_screen
- Dosya: `mobile/lib/features/finance/presentation/screens/finance_screen.dart`

#### S-FINANCE-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/finance
- **Adım:** Ekranı aç: http://localhost:3002/#/finance — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance)
- **Adım:** Başlık (satır 76): Finansal Durumum
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-FINANCE-00`

#### S-FINANCE-01 · Düğme: Öde
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/finance
- **Adım:** "Öde" öğesine dokun (kaynak satırı 161)
- **Beklenen (okuma):** `GET /finance/debt-status` (finance), `GET /finance/assessments` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-FINANCE-01`

---

### payment_history_screen
- Dosya: `mobile/lib/features/finance/presentation/screens/payment_history_screen.dart`

#### S-PAYMENT-HISTORY-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/payment-history
- **Adım:** Ekranı aç: http://localhost:3002/#/payment-history — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/my-payments` (finance)
- **Adım:** Başlık (satır 39): Ödeme Geçmişi
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-PAYMENT-HISTORY-00`

---

### my_budgets_screen
- Dosya: `mobile/lib/features/governance/presentation/screens/my_budgets_screen.dart`

#### S-MY-BUDGETS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 (işletme projesi malik içindir) · **Nerede:** http://localhost:3002/#/my-budgets
- **Adım:** Ekranı aç: http://localhost:3002/#/my-budgets — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /governance/my-budgets` (governance); `GET /governance/my-budgets/:id` (governance)
- **Adım:** Başlık (satır 37): İşletme Projesi
- **Adım:** Başlık (satır 95): İşletme projesi
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-BUDGETS-00`

#### S-MY-BUDGETS-01 · Düğme: ${b[
- **Hesap:** MALİK_B1 (işletme projesi malik içindir) · **Nerede:** http://localhost:3002/#/my-budgets
- **Adım:** "${b[" öğesine dokun (kaynak satırı 47); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-BUDGETS-01`

#### S-MY-BUDGETS-02 · Düğme: ${u[
- **Hesap:** MALİK_B1 (işletme projesi malik içindir) · **Nerede:** http://localhost:3002/#/my-budgets
- **Adım:** "${u[" öğesine dokun (kaynak satırı 81); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-BUDGETS-02`

#### S-MY-BUDGETS-03 · Düğme: Görüş / itiraz bildir
- **Hesap:** MALİK_B1 (işletme projesi malik içindir) · **Nerede:** http://localhost:3002/#/my-budgets
- **Adım:** "Görüş / itiraz bildir" öğesine dokun (kaynak satırı 142); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /governance/budgets/:id/objections` (governance, `services/governance/main.go:114`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `budget_objections` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM budget_objections ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/objections' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-BUDGETS-03`

---

### main_screen
- Dosya: `mobile/lib/features/home/presentation/screens/main_screen.dart`

#### S-MAIN-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/home/presentation/screens/main_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/home/presentation/screens/main_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /notifications/unread-count` (notification)
- **Adım:** Pencere (satır 66): Uygulamadan çık
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MAIN-00`

#### S-MAIN-01 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/home/presentation/screens/main_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 70); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MAIN-01`

#### S-MAIN-02 · Düğme: Çık
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/home/presentation/screens/main_screen.dart`)
- **Adım:** "Çık" öğesine dokun (kaynak satırı 74); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MAIN-02`

---

### resident_home_screen
- Dosya: `mobile/lib/features/home/presentation/screens/resident_home_screen.dart`

#### S-RESIDENT-HOME-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** Ekranı aç: http://localhost:3002/#/ — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me` (identity); `GET /finance/debt-status` (finance); `GET /announcements` (community)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-00`

#### S-RESIDENT-HOME-01 · Düğme: Duyurular
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Duyurular" öğesine dokun (kaynak satırı 179); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-01`

#### S-RESIDENT-HOME-02 · Düğme: Aidat Öde
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Aidat Öde" öğesine dokun (kaynak satırı 236); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-02`

#### S-RESIDENT-HOME-03 · Düğme: Ziyaretçi
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Ziyaretçi" öğesine dokun (kaynak satırı 256); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-03`

#### S-RESIDENT-HOME-04 · Düğme: Rezervasyon
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Rezervasyon" öğesine dokun (kaynak satırı 262); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-04`

#### S-RESIDENT-HOME-05 · Düğme: Talep
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Talep" öğesine dokun (kaynak satırı 268); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-05`

#### S-RESIDENT-HOME-06 · Düğme: Anket
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Anket" öğesine dokun (kaynak satırı 274); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-06`

#### S-RESIDENT-HOME-07 · Düğme: Taleplerim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Taleplerim" öğesine dokun (kaynak satırı 298); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-07`

#### S-RESIDENT-HOME-08 · Düğme: Kargolarım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Kargolarım" öğesine dokun (kaynak satırı 305); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-08`

#### S-RESIDENT-HOME-09 · Düğme: Tüketim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Tüketim" öğesine dokun (kaynak satırı 312); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-09`

#### S-RESIDENT-HOME-10 · Düğme: Belgeler
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "Belgeler" öğesine dokun (kaynak satırı 319); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-10`

#### S-RESIDENT-HOME-11 · Düğme: simge düğmesi (satır 361)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/
- **Adım:** "simge düğmesi (satır 361)" öğesine dokun (kaynak satırı 361); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RESIDENT-HOME-11`

---

### invitations_banner
- Dosya: `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`

#### S-INVITATIONS-BANNER-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/invitations` (identity)
- **Adım:** Mesaj (satır 62): ${res[
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-INVITATIONS-BANNER-00`

#### S-INVITATIONS-BANNER-01 · Düğme: Yeniden dene
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`)
- **Adım:** "Yeniden dene" öğesine dokun (kaynak satırı 82)
- **Beklenen (okuma):** `GET /users/me/invitations` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-INVITATIONS-BANNER-01`

#### S-INVITATIONS-BANNER-02 · Düğme: Reddet
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`)
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 109)
- **Beklenen (yazma):** `POST /users/me/invitations/:id/accept` (identity, `services/identity/main.go:128`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/invitations/:id/accept' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /users/me/invitations/:id/decline` (identity, `services/identity/main.go:129`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/invitations/:id/decline' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-INVITATIONS-BANNER-02`

#### S-INVITATIONS-BANNER-03 · Düğme: Kabul et
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`)
- **Adım:** "Kabul et" öğesine dokun (kaynak satırı 114)
- **Beklenen (yazma):** `POST /users/me/invitations/:id/accept` (identity, `services/identity/main.go:128`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/invitations/:id/accept' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /users/me/invitations/:id/decline` (identity, `services/identity/main.go:129`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/invitations/:id/decline' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-INVITATIONS-BANNER-03`

---

### kvkk_requests_screen
- Dosya: `mobile/lib/features/kvkk/presentation/screens/kvkk_requests_screen.dart`

#### S-KVKK-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** Ekranı aç: http://localhost:3002/#/kvkk — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /kvkk-requests` (community); `GET /privacy/cameras` (settings)
- **Adım:** Pencere (satır 61): Yeni KVKK başvurusu
- **Adım:** Alan (satır 78): Talebiniz
- **Adım:** Alan (satır 78): Kısaca açıklayın (en az 10 karakter)
- **Adım:** Mesaj (satır 93): ${res[
- **Adım:** Başlık (satır 103): KVKK başvurularım
- **Adım:** Başlık (satır 163): Ortak alan kameraları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-00`

#### S-KVKK-REQUESTS-01 · Seçim: simge düğmesi (satır 65)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** "simge düğmesi (satır 65)" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-01`

#### S-KVKK-REQUESTS-02 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 83); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-02`

#### S-KVKK-REQUESTS-03 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 84); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-03`

#### S-KVKK-REQUESTS-04 · Düğme: Başvuru yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** "Başvuru yap" öğesine dokun (kaynak satırı 104); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /kvkk-requests` (community, `services/community/kvkk.go:52`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `kvkk_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM kvkk_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/kvkk-requests' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `kvkk.request` → alıcı: yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'kvkk.request%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/kvkk`, Sakin `kvkk_requests_screen`, Yön.mobil `kvkk_requests_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-04`

#### S-KVKK-REQUESTS-05 · Düğme: Ortak alan kameraları
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/kvkk
- **Adım:** "Ortak alan kameraları" öğesine dokun (kaynak satırı 127); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-KVKK-REQUESTS-05`

---

### my_meters_screen
- Dosya: `mobile/lib/features/meters/presentation/screens/my_meters_screen.dart`

#### S-MY-METERS-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-meters
- **Adım:** Ekranı aç: http://localhost:3002/#/my-meters — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /meter-readings` (iot)
- **Adım:** Başlık (satır 18): Sayaçlarım
- **Adım:** Başlık (satır 44): ${meter[
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-METERS-00`

#### S-MY-METERS-01 · Düğme: ${_types[
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-meters
- **Adım:** "${_types[" öğesine dokun (kaynak satırı 23); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-METERS-01`

---

### more_screen
- Dosya: `mobile/lib/features/more/presentation/screens/more_screen.dart`

#### S-MORE-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** Ekranı aç: http://localhost:3002/#/more — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me` (identity)
- **Adım:** Başlık (satır 73): Daha Fazla
- **Adım:** Pencere (satır 283): Çıkış Yap
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-00`

#### S-MORE-01 · Düğme: Bildirimlerim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Bildirimlerim" öğesine dokun (kaynak satırı 78); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-01`

#### S-MORE-02 · Düğme: Duyurular
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Duyurular" öğesine dokun (kaynak satırı 83); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-02`

#### S-MORE-03 · Düğme: Ödeme Geçmişi
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Ödeme Geçmişi" öğesine dokun (kaynak satırı 88); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-03`

#### S-MORE-04 · Düğme: Ziyaretçilerim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Ziyaretçilerim" öğesine dokun (kaynak satırı 93); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-04`

#### S-MORE-05 · Düğme: Araçlarım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Araçlarım" öğesine dokun (kaynak satırı 98); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-05`

#### S-MORE-06 · Düğme: Sayaçlarım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Sayaçlarım" öğesine dokun (kaynak satırı 103); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-06`

#### S-MORE-07 · Düğme: Memnuniyet Anketi
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Memnuniyet Anketi" öğesine dokun (kaynak satırı 108); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-07`

#### S-MORE-08 · Düğme: İşletme Projesi
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "İşletme Projesi" öğesine dokun (kaynak satırı 113); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-08`

#### S-MORE-09 · Düğme: Anketler
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Anketler" öğesine dokun (kaynak satırı 118); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-09`

#### S-MORE-10 · Düğme: İlan Panosu
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "İlan Panosu" öğesine dokun (kaynak satırı 123); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-10`

#### S-MORE-11 · Düğme: Kargo Takibi
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Kargo Takibi" öğesine dokun (kaynak satırı 128); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-11`

#### S-MORE-12 · Düğme: Rezervasyonlarım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Rezervasyonlarım" öğesine dokun (kaynak satırı 133); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-12`

#### S-MORE-13 · Düğme: Ziyaretçi Ön Kaydı
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Ziyaretçi Ön Kaydı" öğesine dokun (kaynak satırı 138); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-13`

#### S-MORE-14 · Düğme: Tüketim
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Tüketim" öğesine dokun (kaynak satırı 143); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-14`

#### S-MORE-15 · Düğme: Belgeler
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Belgeler" öğesine dokun (kaynak satırı 148); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-15`

#### S-MORE-16 · Düğme: DASK poliçem
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "DASK poliçem" öğesine dokun (kaynak satırı 153); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-16`

#### S-MORE-17 · Düğme: Ortak alan geliri payım
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Ortak alan geliri payım" öğesine dokun (kaynak satırı 158); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-17`

#### S-MORE-18 · Düğme: Acil durum
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Acil durum" öğesine dokun (kaynak satırı 163); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-18`

#### S-MORE-19 · Düğme: Kural ihlali bildir
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Kural ihlali bildir" öğesine dokun (kaynak satırı 168); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-19`

#### S-MORE-20 · Düğme: Tadilat izni
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Tadilat izni" öğesine dokun (kaynak satırı 173); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-20`

#### S-MORE-21 · Düğme: KVKK başvurusu
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "KVKK başvurusu" öğesine dokun (kaynak satırı 178); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-21`

#### S-MORE-22 · Düğme: Profil ve Ayarlar
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Profil ve Ayarlar" öğesine dokun (kaynak satırı 184); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-22`

#### S-MORE-23 · Düğme: Hakkında
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Hakkında" öğesine dokun (kaynak satırı 189); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-23`

#### S-MORE-24 · Düğme: Çıkış Yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Çıkış Yap" öğesine dokun (kaynak satırı 195); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-24`

#### S-MORE-25 · Düğme: Profili düzenle
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Profili düzenle" öğesine dokun (kaynak satırı 259); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-25`

#### S-MORE-26 · Düğme: İptal
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "İptal" öğesine dokun (kaynak satırı 287); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-26`

#### S-MORE-27 · Düğme: Çıkış Yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "Çıkış Yap" öğesine dokun (kaynak satırı 290); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-27`

#### S-MORE-28 · Düğme: simge düğmesi (satır 321)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/more
- **Adım:** "simge düğmesi (satır 321)" öğesine dokun (kaynak satırı 321); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MORE-28`

---

### notifications_screen
- Dosya: `mobile/lib/features/notifications/presentation/screens/notifications_screen.dart`

#### S-NOTIFICATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/notifications
- **Adım:** Ekranı aç: http://localhost:3002/#/notifications — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /notifications` (notification)
- **Adım:** Başlık (satır 67): Bildirimlerim
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-NOTIFICATIONS-00`

#### S-NOTIFICATIONS-01 · Düğme: Tümünü okundu say
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/notifications
- **Adım:** "Tümünü okundu say" öğesine dokun (kaynak satırı 68)
- **Beklenen (yazma):** `POST /notifications/read-all` (notification, `services/notification/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications/read-all' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Panel `/tedarikci/(panel)/bildirimler`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-NOTIFICATIONS-01`

#### S-NOTIFICATIONS-02 · Düğme: ${n[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/notifications
- **Adım:** "${n[" öğesine dokun (kaynak satırı 88)
- **Beklenen (yazma):** `POST /notifications/:id/read` (notification, `services/notification/main.go:84`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications/:id/read' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Panel `/tedarikci/(panel)/bildirimler`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-NOTIFICATIONS-02`

---

### nps_screen
- Dosya: `mobile/lib/features/nps/presentation/screens/nps_screen.dart`

#### S-NPS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/nps
- **Adım:** Ekranı aç: http://localhost:3002/#/nps — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Başlık (satır 33): Memnuniyet Anketi
- **Adım:** Alan (satır 83): Yorum (isteğe bağlı)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-NPS-00`

#### S-NPS-01 · Düğme: Yanıtla
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/nps
- **Adım:** "Yanıtla" öğesine dokun (kaynak satırı 50); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-NPS-01`

#### S-NPS-02 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/nps
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 88); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-NPS-02`

---

### package_tracking_mobile_screen
- Dosya: `mobile/lib/features/packages/presentation/screens/package_tracking_mobile_screen.dart`

#### S-PACKAGE-TRACKING-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/packages
- **Adım:** Ekranı aç: http://localhost:3002/#/packages — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /packages` (package); `GET /packages/:id/proof/:kind` (package)
- **Adım:** Başlık (satır 52): Kargolarım
- **Adım:** Pencere (satır 128): Kapat
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-PACKAGE-TRACKING-00`

#### S-PACKAGE-TRACKING-01 · Düğme: Menü: İmzayı gör
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/packages
- **Adım:** "Menü: İmzayı gör" öğesine dokun (kaynak satırı 114)
- **Beklenen (okuma):** `GET /packages/:id/proof/:kind` (package) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-PACKAGE-TRACKING-01`

#### S-PACKAGE-TRACKING-02 · Düğme: Menü: Fotoğrafı gör
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/packages
- **Adım:** "Menü: Fotoğrafı gör" öğesine dokun (kaynak satırı 115)
- **Beklenen (okuma):** `GET /packages/:id/proof/:kind` (package) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-PACKAGE-TRACKING-02`

#### S-PACKAGE-TRACKING-03 · Düğme: Kapat
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/packages
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 131); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PACKAGE-TRACKING-03`

---

### owner_visibility_screen
- Dosya: `mobile/lib/features/profile/presentation/screens/owner_visibility_screen.dart`

#### S-OWNER-VISIBILITY-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/owner_visibility_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/owner_visibility_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /settings/owner-visibility` (settings)
- **Adım:** Başlık (satır 68): Malikin görebildikleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-OWNER-VISIBILITY-00`

---

### profile_settings_screen
- Dosya: `mobile/lib/features/profile/presentation/screens/profile_settings_screen.dart`

#### S-PROFILE-SETTINGS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** Ekranı aç: http://localhost:3002/#/profile — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me` (identity); `GET /users/me/properties` (identity); `GET /notification-preferences` (notification)
- **Adım:** Başlık (satır 103): Profil
- **Adım:** Mesaj (satır 336): Tercih kaydedilemedi: ${toUserMessage(e)}
- **Adım:** Pencere (satır 380): Tüm cihazlardan çıkış
- **Adım:** Pencere (satır 403): Çıkış Yap
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-00`

#### S-PROFILE-SETTINGS-01 · Düğme: ${units[i][
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "${units[i][" öğesine dokun (kaynak satırı 190); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-01`

#### S-PROFILE-SETTINGS-02 · Düğme: E-posta
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "E-posta" öğesine dokun (kaynak satırı 211); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/email` (identity, `services/identity/main.go:110`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `email_change_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `email_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/email' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.email_change` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_change%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Beklenen (yazma):** `POST /users/me/email/confirm` (identity, `services/identity/main.go:111`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `email_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/email/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.email_changed` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_changed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-02`

#### S-PROFILE-SETTINGS-03 · Düğme: Telefon
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Telefon" öğesine dokun (kaynak satırı 220); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/phone/request` (identity, `services/identity/main.go:108`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `phone_change_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `phone_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/phone/request' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.phone_change` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_change%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Beklenen (yazma):** `POST /users/me/phone/confirm` (identity, `services/identity/main.go:109`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `phone_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/phone/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.phone_changed` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_changed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-03`

#### S-PROFILE-SETTINGS-04 · Düğme: Şifre Değiştir
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Şifre Değiştir" öğesine dokun (kaynak satırı 263); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/password` (identity, `services/identity/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/password' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-04`

#### S-PROFILE-SETTINGS-05 · Düğme: Tüm Cihazlardan Çıkış
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Tüm Cihazlardan Çıkış" öğesine dokun (kaynak satırı 270); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Beklenen (yazma):** `POST /users/me/logout-all` (identity, `services/identity/main.go:105`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/logout-all' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-05`

#### S-PROFILE-SETTINGS-06 · Düğme: KVKK Aydınlatma Metni
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "KVKK Aydınlatma Metni" öğesine dokun (kaynak satırı 288); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-06`

#### S-PROFILE-SETTINGS-07 · Düğme: Çıkış Yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Çıkış Yap" öğesine dokun (kaynak satırı 305); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-07`

#### S-PROFILE-SETTINGS-08 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 384); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-08`

#### S-PROFILE-SETTINGS-09 · Düğme: Hepsini kapat
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Hepsini kapat" öğesine dokun (kaynak satırı 385); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-09`

#### S-PROFILE-SETTINGS-10 · Düğme: İptal
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "İptal" öğesine dokun (kaynak satırı 408); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-10`

#### S-PROFILE-SETTINGS-11 · Düğme: Çıkış Yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/profile
- **Adım:** "Çıkış Yap" öğesine dokun (kaynak satırı 411); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-PROFILE-SETTINGS-11`

---

### tenancy_requests_screen
- Dosya: `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`

#### S-TENANCY-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/tenancy-requests` (identity); `GET /users/me/tenancy-requests/:id/documents/:docId` (identity)
- **Adım:** Mesaj (satır 84): ${res[
- **Adım:** Pencere (satır 95): Vazgeç
- **Adım:** Pencere (satır 117): Vazgeç
- **Adım:** Başlık (satır 211): Kiracılık işlemleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-00`

#### S-TENANCY-REQUESTS-01 · Düğme: Vazgeç
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 99); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-01`

#### S-TENANCY-REQUESTS-02 · Düğme: Gönder
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 100); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-02`

#### S-TENANCY-REQUESTS-03 · Düğme: Vazgeç
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 121); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-03`

#### S-TENANCY-REQUESTS-04 · Düğme: Onayla
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 122); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-04`

#### S-TENANCY-REQUESTS-05 · Düğme: Reddet
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 147); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/approve` (identity, `services/identity/main.go:121`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/decline` (identity, `services/identity/main.go:122`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/decline' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-05`

#### S-TENANCY-REQUESTS-06 · Düğme: Onayla
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 156)
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/approve` (identity, `services/identity/main.go:121`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/decline` (identity, `services/identity/main.go:122`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/decline' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-06`

#### S-TENANCY-REQUESTS-07 · Düğme: İtiraz et
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "İtiraz et" öğesine dokun (kaynak satırı 166); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/object` (identity, `services/identity/main.go:123`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/object' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-07`

#### S-TENANCY-REQUESTS-08 · Düğme: Geri çek
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "Geri çek" öğesine dokun (kaynak satırı 175)
- **Beklenen (yazma):** `POST /users/me/tenancy-requests/:id/cancel` (identity, `services/identity/main.go:124`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/tenancy-requests/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-08`

#### S-TENANCY-REQUESTS-09 · Düğme: ${_docKind[
- **Hesap:** KİRACI (kiracılık bitişi talebini yanıtlar) ve MALİK_A4 (talebi açar) · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`)
- **Adım:** "${_docKind[" öğesine dokun (kaynak satırı 197)
- **Beklenen (okuma):** `GET /users/me/tenancy-requests/:id/documents/:docId` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `S-TENANCY-REQUESTS-09`

---

### unit_residents_screen
- Dosya: `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`

#### S-UNIT-RESIDENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/units/:id/residents` (identity); `GET /finance/tenant-debt-summary` (finance); `GET /requests/units/:unitId` (community)
- **Adım:** Pencere (satır 101): Kaydı bitir
- **Adım:** Mesaj (satır 115): ${res[
- **Adım:** Pencere (satır 128): Vazgeç
- **Adım:** Mesaj (satır 153): ${res[
- **Adım:** Pencere (satır 167): Daire talepleri
- **Adım:** Pencere (satır 202): Davet gönder
- **Adım:** Alan (satır 215): Sıfat
- **Adım:** Alan (satır 223): Ad
- **Adım:** Alan (satır 225): Soyad
- **Adım:** Alan (satır 230): Telefon
- **Adım:** Alan (satır 230): 0555 123 45 67 · yurt dışı: +49 …
- **Adım:** Alan (satır 234): E-posta (isteğe bağlı)
- **Adım:** Pencere (satır 279): Davet gönderildi
- **Adım:** Başlık (satır 291): ${widget.unitName} sakinleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-00`

#### S-UNIT-RESIDENTS-01 · Düğme: Vazgeç
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 106); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-01`

#### S-UNIT-RESIDENTS-02 · Düğme: Bitir
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Bitir" öğesine dokun (kaynak satırı 107); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-02`

#### S-UNIT-RESIDENTS-03 · Düğme: Vazgeç
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 137); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-03`

#### S-UNIT-RESIDENTS-04 · Düğme: İste / Bildir
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "İste / Bildir" öğesine dokun (kaynak satırı 138); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-04`

#### S-UNIT-RESIDENTS-05 · Düğme: Kapat
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 182); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-05`

#### S-UNIT-RESIDENTS-06 · Seçim: Kiracı
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Kiracı" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-06`

#### S-UNIT-RESIDENTS-07 · Düğme: Vazgeç
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 239); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-07`

#### S-UNIT-RESIDENTS-08 · Düğme: Gönder
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 240); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-08`

#### S-UNIT-RESIDENTS-09 · Düğme: Tamam
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 282); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-09`

#### S-UNIT-RESIDENTS-10 · Düğme: Malikin görebildikleri
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Malikin görebildikleri" öğesine dokun (kaynak satırı 292); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-10`

#### S-UNIT-RESIDENTS-11 · Düğme: Daire talepleri
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Daire talepleri" öğesine dokun (kaynak satırı 298); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /requests/units/:unitId` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-11`

#### S-UNIT-RESIDENTS-12 · Düğme: Kiracılık işlemleri
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Kiracılık işlemleri" öğesine dokun (kaynak satırı 299); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-12`

#### S-UNIT-RESIDENTS-13 · Düğme: Menü: OWNER / Kiracılığın bitmesini iste / Çıkışımı bildir
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Menü: OWNER / Kiracılığın bitmesini iste / Çıkışımı bildir" öğesine dokun (kaynak satırı 309)
- **Beklenen (yazma):** `POST /users/me/units/:id/tenancy-end` (identity, `services/identity/main.go:118`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/units/:id/tenancy-end' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /users/me/units/:id/tenancy-exit` (identity, `services/identity/main.go:119`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/units/:id/tenancy-exit' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-13`

#### S-UNIT-RESIDENTS-14 · Düğme: Davet gönder
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Davet gönder" öğesine dokun (kaynak satırı 313); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/units/:id/invitations` (identity, `services/identity/main.go:115`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER/PROXY/TENANT
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/units/:id/invitations' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.invitation` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.invitation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-14`

#### S-UNIT-RESIDENTS-15 · Düğme: Bitir
- **Hesap:** MALİK_A4 · **Nerede:** http://localhost:3002 (başka bir ekrandan açılan bileşen/pencere; `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`)
- **Adım:** "Bitir" öğesine dokun (kaynak satırı 351); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/units/:id/residents/:residentId/end` (identity, `services/identity/main.go:116`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/units/:id/residents/:residentId/end' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `S-UNIT-RESIDENTS-15`

---

### renovations_screen
- Dosya: `mobile/lib/features/renovation/presentation/screens/renovations_screen.dart`

#### S-RENOVATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** Ekranı aç: http://localhost:3002/#/renovations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /renovations` (community); `GET /users/me/properties` (identity)
- **Adım:** Pencere (satır 71): Başvuruyu geri çek
- **Adım:** Mesaj (satır 83): Başvuru geri çekildi
- **Adım:** Mesaj (satır 104): Tadilat başvurusunu dairenin maliki ya da vekili yapabilir.
- **Adım:** Pencere (satır 118): Tadilat başvurusu
- **Adım:** Alan (satır 126): Daire
- **Adım:** Alan (satır 136): Kapsam
- **Adım:** Alan (satır 150): Yapılacak iş
- **Adım:** Alan (satır 150): En az 10 karakter
- **Adım:** Alan (satır 152): Usta / firma (isteğe bağlı)
- **Adım:** Mesaj (satır 192): Başvurunuz alındı. ${res[
- **Adım:** Başlık (satır 202): Tadilat izinleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-00`

#### S-RENOVATIONS-01 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 75); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-01`

#### S-RENOVATIONS-02 · Düğme: Geri çek
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Geri çek" öğesine dokun (kaynak satırı 76); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-02`

#### S-RENOVATIONS-03 · Seçim: ${u[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-03`

#### S-RENOVATIONS-04 · Seçim: Kapsam
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Kapsam" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-04`

#### S-RENOVATIONS-05 · Düğme: Tarih: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Tarih: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))}" öğesine dokun (kaynak satırı 153); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-05`

#### S-RENOVATIONS-06 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 175); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-06`

#### S-RENOVATIONS-07 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 176); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-07`

#### S-RENOVATIONS-08 · Düğme: Başvuru yap
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Başvuru yap" öğesine dokun (kaynak satırı 203); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /renovations` (community, `services/community/renovation.go:88`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `isManagement` (backend/services/community/main.go:257)
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `renovation.request` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.request%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-08`

#### S-RENOVATIONS-09 · Düğme: Geri çek
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/renovations
- **Adım:** "Geri çek" öğesine dokun (kaynak satırı 228); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /renovations/:id/cancel` (community, `services/community/renovation.go:149`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-RENOVATIONS-09`

---

### create_request_screen
- Dosya: `mobile/lib/features/requests/presentation/screens/create_request_screen.dart`

#### S-CREATE-REQUEST-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** Ekranı aç: http://localhost:3002/#/requests/create — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Başlık (satır 82): Yeni Talep
- **Adım:** Pencere (satır 354): Talep Oluşturuldu
- **Adım:** Pencere (satır 402): Tamam
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-00`

#### S-CREATE-REQUEST-01 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 96); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /requests` (community, `services/community/main.go:82`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/requests' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/requests`, Sakin `requests_screen`, Sakin `unit_residents_screen`, Yön.mobil `request_detail_screen`, Yön.mobil `requests_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-01`

#### S-CREATE-REQUEST-02 · Düğme: simge düğmesi (satır 125)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** "simge düğmesi (satır 125)" öğesine dokun (kaynak satırı 125); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-02`

#### S-CREATE-REQUEST-03 · Düğme: simge düğmesi (satır 244)
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** "simge düğmesi (satır 244)" öğesine dokun (kaynak satırı 244); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-03`

#### S-CREATE-REQUEST-04 · Düğme: Tamam
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 385); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-04`

#### S-CREATE-REQUEST-05 · Düğme: Tamam
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests/create
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 414); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-REQUEST-05`

---

### requests_screen
- Dosya: `mobile/lib/features/requests/presentation/screens/requests_screen.dart`

#### S-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests
- **Adım:** Ekranı aç: http://localhost:3002/#/requests — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /requests` (community)
- **Adım:** Başlık (satır 68): Taleplerim
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Güncel
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tamamlanmış
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-REQUESTS-00`

#### S-REQUESTS-01 · Düğme: Yeni Talep
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests
- **Adım:** "Yeni Talep" öğesine dokun (kaynak satırı 72)
- **Beklenen (okuma):** `GET /requests` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-REQUESTS-01`

#### S-REQUESTS-02 · Düğme: Devam ediyor
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests
- **Adım:** "Devam ediyor" öğesine dokun (kaynak satırı 132)
- **Beklenen (yazma):** `POST /requests/:id/confirm-resolution` (community, `services/community/main.go:86`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/requests/:id/confirm-resolution' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/requests`, Sakin `requests_screen`, Sakin `unit_residents_screen`, Yön.mobil `request_detail_screen`, Yön.mobil `requests_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-REQUESTS-02`

#### S-REQUESTS-03 · Düğme: Sorunum çözüldü
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/requests
- **Adım:** "Sorunum çözüldü" öğesine dokun (kaynak satırı 136)
- **Beklenen (yazma):** `POST /requests/:id/confirm-resolution` (community, `services/community/main.go:86`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/requests/:id/confirm-resolution' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/requests`, Sakin `requests_screen`, Sakin `unit_residents_screen`, Yön.mobil `request_detail_screen`, Yön.mobil `requests_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-REQUESTS-03`

---

### create_reservation_screen
- Dosya: `mobile/lib/features/reservations/presentation/screens/create_reservation_screen.dart`

#### S-CREATE-RESERVATION-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/reservation
- **Adım:** Ekranı aç: http://localhost:3002/#/reservation — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /facilities` (reservation); `GET /facilities/:id/slots` (reservation)
- **Adım:** Başlık (satır 115): Rezervasyon Yap
- **Adım:** Pencere (satır 246): Tamam
- **Adım:** Mesaj (satır 260): Rezervasyon oluşturulamadı: ${toUserMessage(e)}
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-RESERVATION-00`

#### S-CREATE-RESERVATION-01 · Düğme: Rezervasyon Yap
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/reservation
- **Adım:** "Rezervasyon Yap" öğesine dokun (kaynak satırı 216); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /reservations` (reservation, `services/reservation/main.go:147`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `reservations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM reservations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/reservations' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-RESERVATION-01`

#### S-CREATE-RESERVATION-02 · Düğme: Tamam
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/reservation
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 254); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-CREATE-RESERVATION-02`

---

### my_reservations_screen
- Dosya: `mobile/lib/features/reservations/presentation/screens/my_reservations_screen.dart`

#### S-MY-RESERVATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-reservations
- **Adım:** Ekranı aç: http://localhost:3002/#/my-reservations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /reservations` (reservation)
- **Adım:** Pencere (satır 44): Rezervasyonu iptal et
- **Adım:** Alan (satır 46): Gerekçe (isteğe bağlı)
- **Adım:** Mesaj (satır 59): ${res[
- **Adım:** Başlık (satır 70): Rezervasyonlarım
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-RESERVATIONS-00`

#### S-MY-RESERVATIONS-01 · Düğme: Vazgeç
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-reservations
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 48); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-RESERVATIONS-01`

#### S-MY-RESERVATIONS-02 · Düğme: İptal et
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-reservations
- **Adım:** "İptal et" öğesine dokun (kaynak satırı 49); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-RESERVATIONS-02`

#### S-MY-RESERVATIONS-03 · Düğme: Yeni
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-reservations
- **Adım:** "Yeni" öğesine dokun (kaynak satırı 71)
- **Beklenen (okuma):** `GET /reservations` (reservation) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-RESERVATIONS-03`

#### S-MY-RESERVATIONS-04 · Düğme: İptal
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-reservations
- **Adım:** "İptal" öğesine dokun (kaynak satırı 106); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /reservations/:id/cancel` (reservation, `services/reservation/main.go:238`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `canManage` (backend/services/reservation/main.go:441)
  - **Veritabanı (Adminer → SQL komutu):**
    - `reservations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM reservations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/reservations/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-RESERVATIONS-04`

---

### surveys_mobile_screen
- Dosya: `mobile/lib/features/surveys/presentation/screens/surveys_mobile_screen.dart`

#### S-SURVEYS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/surveys
- **Adım:** Ekranı aç: http://localhost:3002/#/surveys — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /surveys` (survey); `GET /surveys/:id` (survey); `GET /surveys/:id/comments` (survey)
- **Adım:** Başlık (satır 58): Anketler
- **Adım:** Mesaj (satır 162): ${res[
- **Adım:** Başlık (satır 182): Anket
- **Adım:** Alan (satır 237): Yorum (isteğe bağlı)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-SURVEYS-00`

#### S-SURVEYS-01 · Düğme: ${s[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/surveys
- **Adım:** "${s[" öğesine dokun (kaynak satırı 75)
- **Beklenen (okuma):** `GET /surveys` (survey) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-SURVEYS-01`

#### S-SURVEYS-02 · Düğme: Oy Ver
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/surveys
- **Adım:** "Oy Ver" öğesine dokun (kaynak satırı 242)
- **Beklenen (yazma):** `POST /surveys/:id/vote` (survey, `services/survey/main.go:143`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: OWNER
  - **Veritabanı (Adminer → SQL komutu):**
    - `survey_votes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM survey_votes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/vote' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-SURVEYS-02`

#### S-SURVEYS-03 · Düğme: Yorumları gör
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/surveys
- **Adım:** "Yorumları gör" öğesine dokun (kaynak satırı 255); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /surveys/:id/comments` (survey) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-SURVEYS-03`

---

### market_request_screens
- Dosya: `mobile/lib/features/usta_hizmet/presentation/screens/market_request_screens.dart`

#### S-MARKET-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** Ekranı aç: http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace); `GET /market/requests/match-count` (marketplace); `GET /market/requests/:id` (marketplace); `GET /market/requests/:id/offers` (marketplace); `GET /market/requests/:id/messages/:dispatchId` (marketplace); `GET /market/requests/:id/job` (marketplace)
- **Adım:** Dosya seçme (satır 5)
- **Adım:** Dosya seçme (satır 5)
- **Adım:** Dosya seçme (satır 67)
- **Adım:** Mesaj (satır 71): Fotoğraf 5 MB sınırını aşıyor.
- **Adım:** Mesaj (satır 99): Talebiniz ${r[
- **Adım:** Başlık (satır 113): (dinamik)
- **Adım:** Alan (satır 126): Kategori
- **Adım:** Alan (satır 149): Ne yapılmasını istiyorsunuz?
- **Adım:** Alan (satır 152): Uygun zaman (isteğe bağlı)
- **Adım:** Başlık (satır 223): Talebim
- **Adım:** Alan (satır 372): Yorumunuz (isteğe bağlı)
- **Adım:** Başlık (satır 418): (dinamik)
- **Adım:** Alan (satır 460): Mesajınız
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-00`

#### S-MARKET-REQUESTS-01 · Seçim: ${c[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "${c[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen (okuma):** `GET /market/requests/match-count` (marketplace) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-01`

#### S-MARKET-REQUESTS-02 · Düğme: Fotoğraf ekle
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Fotoğraf ekle" öğesine dokun (kaynak satırı 162); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-02`

#### S-MARKET-REQUESTS-03 · Düğme: Gönderiliyor… / Talebi gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Gönderiliyor… / Talebi gönder" öğesine dokun (kaynak satırı 172)
- **Beklenen (yazma):** `POST /market/requests` (marketplace, `services/marketplace/main.go:85`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_requests_active_property` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_request_contacts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_request_contacts ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_request_dispatch` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_request_dispatch ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_request_dispatch` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_request_dispatch ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /market/requests/:id/photos` (marketplace, `services/marketplace/main.go:87`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_requests_active_property` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `photo_moderation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM photo_moderation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/photos' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/isletmeler/[id]`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-03`

#### S-MARKET-REQUESTS-04 · Düğme: Bu teklifi seç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Bu teklifi seç" öğesine dokun (kaynak satırı 274); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /market/requests/:id/offers/:offerId/select` (marketplace, `services/marketplace/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_jobs_completed_refresh`, `mp_requests_active_property` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_jobs` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_jobs ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_offers` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_offers ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/offers/:offerId/select' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-04`

#### S-MARKET-REQUESTS-05 · Düğme: Mesaj
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Mesaj" öğesine dokun (kaynak satırı 282); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-05`

#### S-MARKET-REQUESTS-06 · Düğme: Teklif seçmeden talebi kapat
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Teklif seçmeden talebi kapat" öğesine dokun (kaynak satırı 297); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /market/requests/:id/close` (marketplace, `services/marketplace/main.go:92`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_requests_active_property` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_offers` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_offers ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-06`

#### S-MARKET-REQUESTS-07 · Düğme: İş tamamlandı, onaylıyorum
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "İş tamamlandı, onaylıyorum" öğesine dokun (kaynak satırı 350)
- **Beklenen (yazma):** `POST /market/requests/:id/job/confirm` (marketplace, `services/marketplace/main.go:96`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_jobs_completed_refresh` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_jobs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_jobs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/job/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-07`

#### S-MARKET-REQUESTS-08 · Düğme: İtiraz et
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "İtiraz et" öğesine dokun (kaynak satırı 352); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /market/requests/:id/job/dispute` (marketplace, `services/marketplace/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_jobs_completed_refresh` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_jobs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_jobs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/job/dispute' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-08`

#### S-MARKET-REQUESTS-09 · Düğme: $i yıldız
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "$i yıldız" öğesine dokun (kaynak satırı 366); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-09`

#### S-MARKET-REQUESTS-10 · Düğme: Puanı gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Puanı gönder" öğesine dokun (kaynak satırı 373)
- **Beklenen (yazma):** `POST /market/requests/:id/review` (marketplace, `services/marketplace/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `mp_reviews_guard`, `mp_reviews_rating_refresh` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_reviews` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_reviews ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/review' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/puanlar`, Panel `/tedarikci/(panel)/talepler/[id]`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-10`

#### S-MARKET-REQUESTS-11 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta/talep, http://localhost:3002/#/usta/talepler/:id, http://localhost:3002/#/usta/talepler/:id/mesaj/:dispatchId
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 461)
- **Beklenen (yazma):** `POST /market/requests/:id/messages/:dispatchId` (marketplace, `services/marketplace/main.go:94`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_messages` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_messages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/requests/:id/messages/:dispatchId' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/talepler/[id]`, Sakin `market_request_screens`
- **Sonuç:** http://localhost:18000/sonuc → `S-MARKET-REQUESTS-11`

---

### usta_screen
- Dosya: `mobile/lib/features/usta_hizmet/presentation/screens/usta_screen.dart`

#### S-USTA-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id
- **Adım:** Ekranı aç: http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace); `GET /market/showcase` (marketplace); `GET /market/showcase/:id` (marketplace)
- **Adım:** Başlık (satır 59): Usta & Hizmet
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Yakınımdakiler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Taleplerim
- **Adım:** Başlık (satır 192): İşletme
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-USTA-00`

#### S-USTA-01 · Düğme: Talep aç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id
- **Adım:** "Talep aç" öğesine dokun (kaynak satırı 63); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-USTA-01`

#### S-USTA-02 · Düğme: ${r[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id
- **Adım:** "${r[" öğesine dokun (kaynak satırı 129); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-USTA-02`

#### S-USTA-03 · Düğme: ${b[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id
- **Adım:** "${b[" öğesine dokun (kaynak satırı 165); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-USTA-03`

#### S-USTA-04 · Düğme: Bu işletmeye talep gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/usta, http://localhost:3002/#/usta/isletme/:id
- **Adım:** "Bu işletmeye talep gönder" öğesine dokun (kaynak satırı 218); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-USTA-04`

---

### vehicles_screen
- Dosya: `mobile/lib/features/vehicles/presentation/screens/vehicles_screen.dart`

#### S-VEHICLES-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/vehicles
- **Adım:** Ekranı aç: http://localhost:3002/#/vehicles — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/properties` (identity)
- **Adım:** Başlık (satır 53): Araçlarım
- **Adım:** Alan (satır 106): Plaka *
- **Adım:** Alan (satır 106): 34 ABC 123
- **Adım:** Alan (satır 109): Marka
- **Adım:** Alan (satır 110): Model
- **Adım:** Alan (satır 111): Renk
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-VEHICLES-00`

#### S-VEHICLES-01 · Düğme: ${u[
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/vehicles
- **Adım:** "${u[" öğesine dokun (kaynak satırı 30); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VEHICLES-01`

#### S-VEHICLES-02 · Düğme: Araç ekle
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/vehicles
- **Adım:** "Araç ekle" öğesine dokun (kaynak satırı 54); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /vehicles` (parking, `services/parking/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `vehicles` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM vehicles ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/vehicles' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-VEHICLES-02`

#### S-VEHICLES-03 · Düğme: Kaldır
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/vehicles
- **Adım:** "Kaldır" öğesine dokun (kaynak satırı 66); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `DELETE /vehicles/:id` (parking, `services/parking/main.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `vehicles` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM vehicles ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/vehicles/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-VEHICLES-03`

#### S-VEHICLES-04 · Düğme: Kaydet
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/vehicles
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 113); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VEHICLES-04`

---

### violations_screen
- Dosya: `mobile/lib/features/violations/presentation/screens/violations_screen.dart`

#### S-VIOLATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** Ekranı aç: http://localhost:3002/#/violations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /violations` (community); `GET /site-rules` (community); `GET /units` (identity)
- **Adım:** Mesaj (satır 68): Yönetim henüz kural tanımlamamış.
- **Adım:** Pencere (satır 76): Kural ihlali bildir
- **Adım:** Alan (satır 82): Kural
- **Adım:** Alan (satır 91): Daire
- **Adım:** Alan (satır 101): Ne oldu?
- **Adım:** Alan (satır 101): Tarih, saat ve olayı yazın (en az 10 karakter)
- **Adım:** Mesaj (satır 117): ${res[
- **Adım:** Pencere (satır 128): Savunma
- **Adım:** Alan (satır 130): Açıklamanız
- **Adım:** Mesaj (satır 141): Savunmanız yönetime iletildi
- **Adım:** Başlık (satır 151): Kural ihlalleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-00`

#### S-VIOLATIONS-01 · Seçim: ${r[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "${r[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-01`

#### S-VIOLATIONS-02 · Seçim: ${u[
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-02`

#### S-VIOLATIONS-03 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 108); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-03`

#### S-VIOLATIONS-04 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 109); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-04`

#### S-VIOLATIONS-05 · Düğme: Vazgeç
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 132); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-05`

#### S-VIOLATIONS-06 · Düğme: Gönder
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 133); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-06`

#### S-VIOLATIONS-07 · Düğme: Bildir
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Bildir" öğesine dokun (kaynak satırı 152); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /violations` (community, `services/community/violation.go:131`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `isManagement` (backend/services/community/main.go:257)
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.reported` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.reported%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-07`

#### S-VIOLATIONS-08 · Düğme: Savunma
- **Hesap:** MALİK_B1 · **Nerede:** http://localhost:3002/#/violations
- **Adım:** "Savunma" öğesine dokun (kaynak satırı 176); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /violations/:id/respond` (community, `services/community/violation.go:173`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/respond' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.response` → alıcı: onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.response%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-VIOLATIONS-08`

---

### my_visitors_screen
- Dosya: `mobile/lib/features/visitors/presentation/screens/my_visitors_screen.dart`

#### S-MY-VISITORS-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** Ekranı aç: http://localhost:3002/#/my-visitors — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 37): $name için yeni kod
- **Adım:** Başlık (satır 60): Ziyaretçilerim
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-00`

#### S-MY-VISITORS-01 · Düğme: PIN mesajını kopyala
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** "PIN mesajını kopyala" öğesine dokun (kaynak satırı 47); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-01`

#### S-MY-VISITORS-02 · Düğme: Tamam
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 51); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-02`

#### S-MY-VISITORS-03 · Düğme: Ön kayıt
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** "Ön kayıt" öğesine dokun (kaynak satırı 61); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-03`

#### S-MY-VISITORS-04 · Düğme: Menü: Kodu yenile
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** "Menü: Kodu yenile" öğesine dokun (kaynak satırı 107)
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-04`

#### S-MY-VISITORS-05 · Düğme: Menü: İptal et
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/my-visitors
- **Adım:** "Menü: İptal et" öğesine dokun (kaynak satırı 108)
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-MY-VISITORS-05`

---

### visitor_preregister_screen
- Dosya: `mobile/lib/features/visitors/presentation/screens/visitor_preregister_screen.dart`

#### S-VISITOR-PREREGISTER-00 · Ekran açılışı ve görünüm
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** Ekranı aç: http://localhost:3002/#/visitor-preregister — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/properties` (identity)
- **Adım:** Başlık (satır 73): Ziyaretçi Ön Kayıt
- **Adım:** Pencere (satır 426): Ön Kayıt Oluşturuldu
- **Adım:** Pencere (satır 500): Tamam
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-00`

#### S-VISITOR-PREREGISTER-01 · Düğme: simge düğmesi (satır 95)
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "simge düğmesi (satır 95)" öğesine dokun (kaynak satırı 95); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-01`

#### S-VISITOR-PREREGISTER-02 · Düğme: Tarih
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "Tarih" öğesine dokun (kaynak satırı 199); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-02`

#### S-VISITOR-PREREGISTER-03 · Düğme: Saat
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "Saat" öğesine dokun (kaynak satırı 240); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-03`

#### S-VISITOR-PREREGISTER-04 · Düğme: Gönderiliyor… / Ön Kayıt Oluştur
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "Gönderiliyor… / Ön Kayıt Oluştur" öğesine dokun (kaynak satırı 313); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /visitors` (visitor, `services/visitor/main.go:100`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-04`

#### S-VISITOR-PREREGISTER-05 · Düğme: ${u[
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "${u[" öğesine dokun (kaynak satırı 363); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-05`

#### S-VISITOR-PREREGISTER-06 · Düğme: PIN mesajını kopyala
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "PIN mesajını kopyala" öğesine dokun (kaynak satırı 465); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-06`

#### S-VISITOR-PREREGISTER-07 · Düğme: Tamam
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 483); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-07`

#### S-VISITOR-PREREGISTER-08 · Düğme: Tamam
- **Hesap:** KİRACI · **Nerede:** http://localhost:3002/#/visitor-preregister
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 512); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `S-VISITOR-PREREGISTER-08`

---
