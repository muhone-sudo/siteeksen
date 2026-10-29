# 5. Yönetici uygulaması (web) — ekran ekran

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Uygulama: http://localhost:3003 (web derlemesi; tarayıcı penceresini telefon genişliğine — ~400 px — daraltın ya da cihaz araç çubuğunu kullanın). Adres çubuğuna `http://localhost:3003/#/<rota>` yazarak ekrana doğrudan gidilebilir; oturum yoksa giriş ekranına yönlenir. Web derlemesinde kamera (QR) ve konum (GPS) tarayıcı izniyle çalışır; izin penceresinde "İzin ver" seçin. Biyometrik giriş web'de yoktur (düğmesi görünmemeli).

### api_views
- Dosya: `admin_app/lib/core/widgets/api_views.dart`

#### Y-API-VIEWS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 61): Vazgeç
- **Adım:** Pencere (satır 93): Vazgeç
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-VIEWS-00`

#### Y-API-VIEWS-01 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 75); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-VIEWS-01`

#### Y-API-VIEWS-02 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`)
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 76); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-VIEWS-02`

#### Y-API-VIEWS-03 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 97); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-VIEWS-03`

#### Y-API-VIEWS-04 · Düğme: simge düğmesi (satır 98)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/api_views.dart`)
- **Adım:** "simge düğmesi (satır 98)" öğesine dokun (kaynak satırı 98); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-VIEWS-04`

---

### apple_widgets
- Dosya: `admin_app/lib/core/widgets/apple_widgets.dart`

#### Y-APPLE-WIDGETS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-00`

#### Y-APPLE-WIDGETS-01 · Düğme: simge düğmesi (satır 79)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 79)" öğesine dokun (kaynak satırı 79); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-01`

#### Y-APPLE-WIDGETS-02 · Düğme: simge düğmesi (satır 147)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 147)" öğesine dokun (kaynak satırı 147); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-02`

#### Y-APPLE-WIDGETS-03 · Düğme: simge düğmesi (satır 259)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 259)" öğesine dokun (kaynak satırı 259); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-03`

#### Y-APPLE-WIDGETS-04 · Düğme: simge düğmesi (satır 359)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 359)" öğesine dokun (kaynak satırı 359); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-04`

#### Y-APPLE-WIDGETS-05 · Düğme: simge düğmesi (satır 407)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 407)" öğesine dokun (kaynak satırı 407); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-05`

#### Y-APPLE-WIDGETS-06 · Düğme: simge düğmesi (satır 579)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/apple_widgets.dart`)
- **Adım:** "simge düğmesi (satır 579)" öğesine dokun (kaynak satırı 579); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-APPLE-WIDGETS-06`

---

### data_state
- Dosya: `admin_app/lib/core/widgets/data_state.dart`

#### Y-DATA-STATE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/data_state.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/data_state.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DATA-STATE-00`

#### Y-DATA-STATE-01 · Düğme: Yeniden dene
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/data_state.dart`)
- **Adım:** "Yeniden dene" öğesine dokun (kaynak satırı 69); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DATA-STATE-01`

---

### forms
- Dosya: `admin_app/lib/core/widgets/forms.dart`

#### Y-FORMS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Dosya seçme (satır 7)
- **Adım:** Dosya seçme (satır 7)
- **Adım:** Dosya seçme (satır 136)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-00`

#### Y-FORMS-01 · Seçim: simge düğmesi (satır 181)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** "simge düğmesi (satır 181)" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-01`

#### Y-FORMS-02 · Düğme: simge düğmesi (satır 205)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** "simge düğmesi (satır 205)" öğesine dokun (kaynak satırı 205); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-02`

#### Y-FORMS-03 · Düğme: simge düğmesi (satır 247)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** "simge düğmesi (satır 247)" öğesine dokun (kaynak satırı 247); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-03`

#### Y-FORMS-04 · Düğme: simge düğmesi (satır 267)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** "simge düğmesi (satır 267)" öğesine dokun (kaynak satırı 267); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-04`

#### Y-FORMS-05 · Düğme: simge düğmesi (satır 338)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/forms.dart`)
- **Adım:** "simge düğmesi (satır 338)" öğesine dokun (kaynak satırı 338); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FORMS-05`

---

### signature_pad
- Dosya: `admin_app/lib/core/widgets/signature_pad.dart`

#### Y-SIGNATURE-PAD-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/signature_pad.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/signature_pad.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 98): Temizle
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SIGNATURE-PAD-00`

#### Y-SIGNATURE-PAD-01 · Düğme: Temizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/signature_pad.dart`)
- **Adım:** "Temizle" öğesine dokun (kaynak satırı 102); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SIGNATURE-PAD-01`

#### Y-SIGNATURE-PAD-02 · Düğme: İmzasız teslim
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/signature_pad.dart`)
- **Adım:** "İmzasız teslim" öğesine dokun (kaynak satırı 103); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SIGNATURE-PAD-02`

#### Y-SIGNATURE-PAD-03 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/core/widgets/signature_pad.dart`)
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 104); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SIGNATURE-PAD-03`

---

### account_screen
- Dosya: `admin_app/lib/features/account/presentation/screens/account_screen.dart`

#### Y-ACCOUNT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** Ekranı aç: http://localhost:3003/#/account — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /users/me/properties` (identity)
- **Adım:** Mesaj (satır 39): Site değiştirildi
- **Adım:** Başlık (satır 50): Hesabım
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-00`

#### Y-ACCOUNT-01 · Düğme: Şifre değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "Şifre değiştir" öğesine dokun (kaynak satırı 52); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/password` (identity, `services/identity/main.go:102`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/password' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-01`

#### Y-ACCOUNT-02 · Düğme: Telefon numarası değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "Telefon numarası değiştir" öğesine dokun (kaynak satırı 53)
- **Beklenen (yazma):** `POST /users/me/phone/request` (identity, `services/identity/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `phone_change_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `phone_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/phone/request' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.phone_change` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_change%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Beklenen (yazma):** `POST /users/me/phone/confirm` (identity, `services/identity/main.go:105`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `phone_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM phone_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/phone/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.phone_changed` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_changed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-02`

#### Y-ACCOUNT-03 · Düğme: E-posta değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "E-posta değiştir" öğesine dokun (kaynak satırı 59)
- **Beklenen (yazma):** `POST /users/me/email` (identity, `services/identity/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `email_change_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `email_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/email' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.email_change` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_change%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Beklenen (yazma):** `POST /users/me/email/confirm` (identity, `services/identity/main.go:107`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `email_change_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM email_change_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/email/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.email_changed` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_changed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-03`

#### Y-ACCOUNT-04 · Düğme: Çıkış yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "Çıkış yap" öğesine dokun (kaynak satırı 65); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:87`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-04`

#### Y-ACCOUNT-05 · Düğme: Yeni site
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "Yeni site" öğesine dokun (kaynak satırı 69); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/properties` (identity, `services/identity/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: MANAGER/OWNER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `properties`, `property_roles` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/properties' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Beklenen (yazma):** `POST /users/me/active-property` (identity, `services/identity/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/active-property' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-05`

#### Y-ACCOUNT-06 · Düğme: ${p[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/account
- **Adım:** "${p[" öğesine dokun (kaynak satırı 99)
- **Beklenen (yazma):** `POST /users/me/active-property` (identity, `services/identity/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/active-property' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACCOUNT-06`

---

### announcements_screen
- Dosya: `admin_app/lib/features/announcements/presentation/screens/announcements_screen.dart`

#### Y-ANNOUNCEMENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** Ekranı aç: http://localhost:3003/#/announcements — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /announcements` (community); `GET /announcements/:id/read-stats` (community)
- **Adım:** Mesaj (satır 88): İşlem yapılamadı: ${toUserMessage(e)}
- **Adım:** Pencere (satır 103): Okunma durumu
- **Adım:** Başlık (satır 117): Duyurular
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-00`

#### Y-ANNOUNCEMENTS-01 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 106); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-01`

#### Y-ANNOUNCEMENTS-02 · Düğme: simge düğmesi (satır 120)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** "simge düğmesi (satır 120)" öğesine dokun (kaynak satırı 120)
- **Beklenen (okuma):** `GET /announcements` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-02`

#### Y-ANNOUNCEMENTS-03 · Düğme: Duyuru Yayınla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** "Duyuru Yayınla" öğesine dokun (kaynak satırı 127); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-03`

#### Y-ANNOUNCEMENTS-04 · Düğme: Menü: Sabitlemeyi kaldır / Sabitle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** "Menü: Sabitlemeyi kaldır / Sabitle" öğesine dokun (kaynak satırı 200)
- **Beklenen (yazma):** `POST /announcements/:id/pin` (community, `services/community/main.go:173`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `announcements` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM announcements ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/announcements/:id/pin' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/announcements`, Sakin `announcements_screen`, Sakin `resident_home_screen`, Yön.mobil `announcements_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-04`

#### Y-ANNOUNCEMENTS-05 · Düğme: Menü: Okunma durumu
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements
- **Adım:** "Menü: Okunma durumu" öğesine dokun (kaynak satırı 206)
- **Beklenen (okuma):** `GET /announcements/:id/read-stats` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-ANNOUNCEMENTS-05`

---

### create_announcement_screen
- Dosya: `admin_app/lib/features/announcements/presentation/screens/create_announcement_screen.dart`

#### Y-CREATE-ANNOUNCEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements/create
- **Adım:** Ekranı aç: http://localhost:3003/#/announcements/create — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Başlık (satır 56): Duyuru Yayınla
- **Adım:** Alan (satır 87): Başlık *
- **Adım:** Alan (satır 98): İçerik *
- **Adım:** Alan (satır 110): Kategori
- **Adım:** Mesaj (satır 221): Duyuru yayınlanamadı: ${toUserMessage(e)}
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ANNOUNCEMENT-00`

#### Y-CREATE-ANNOUNCEMENT-01 · Düğme: Yayınla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements/create
- **Adım:** "Yayınla" öğesine dokun (kaynak satırı 59)
- **Beklenen (yazma):** `POST /announcements` (community, `services/community/main.go:138`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `announcements` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM announcements ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/announcements' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `announcement`, `announcement.urgent` → alıcı: sitenin bütün aktif sakinleri (`Residents`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'announcement%' OR n.topic LIKE 'announcement.urgent%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/announcements`, Sakin `announcements_screen`, Sakin `resident_home_screen`, Yön.mobil `announcements_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ANNOUNCEMENT-01`

#### Y-CREATE-ANNOUNCEMENT-02 · Seçim: Genel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/announcements/create
- **Adım:** "Genel" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ANNOUNCEMENT-02`

---

### asset_management_screen
- Dosya: `admin_app/lib/features/assets/presentation/screens/asset_management_screen.dart`

#### Y-ASSET-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/assets
- **Adım:** Ekranı aç: http://localhost:3003/#/assets — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /asset-categories` (asset); `GET /assets` (asset); `GET /assets-summary` (asset); `GET /assets/:id/maintenance` (asset); `GET /assets/:id` (asset)
- **Adım:** Başlık (satır 80): Demirbaşlar
- **Adım:** Başlık (satır 152): ${a[
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ASSET-MANAGEMENT-00`

#### Y-ASSET-MANAGEMENT-01 · Düğme: Kategori ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/assets
- **Adım:** "Kategori ekle" öğesine dokun (kaynak satırı 84)
- **Beklenen (yazma):** `POST /asset-categories` (asset, `services/asset/main.go:183`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `asset_categories` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM asset_categories ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/asset-categories' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-ASSET-MANAGEMENT-01`

#### Y-ASSET-MANAGEMENT-02 · Düğme: Demirbaş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/assets
- **Adım:** "Demirbaş" öğesine dokun (kaynak satırı 87)
- **Beklenen (yazma):** `POST /assets` (asset, `services/asset/main.go:202`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assets` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/assets' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-ASSET-MANAGEMENT-02`

#### Y-ASSET-MANAGEMENT-03 · Düğme: ${a[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/assets
- **Adım:** "${a[" öğesine dokun (kaynak satırı 107); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ASSET-MANAGEMENT-03`

---

### audit_screen
- Dosya: `admin_app/lib/features/audit/presentation/screens/audit_screen.dart`

#### Y-AUDIT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** Ekranı aç: http://localhost:3003/#/audit — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /audit-logs` (settings); `GET /audit-logs/stats` (settings)
- **Adım:** Başlık (satır 79): İşlem Kayıtları
- **Adım:** Başlık (satır 88): Kayıt istatistiği
- **Adım:** Alan (satır 114): İşlem
- **Adım:** Alan (satır 126): Kaynak
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-00`

#### Y-AUDIT-01 · Düğme: Ara
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** "Ara" öğesine dokun (kaynak satırı 82); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-01`

#### Y-AUDIT-02 · Düğme: Kayıt istatistiği
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** "Kayıt istatistiği" öğesine dokun (kaynak satırı 83)
- **Beklenen (okuma):** `GET /audit-logs/stats` (settings) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-02`

#### Y-AUDIT-03 · Seçim: Tümü
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** "Tümü" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-03`

#### Y-AUDIT-04 · Seçim: Tümü
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** "Tümü" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-04`

#### Y-AUDIT-05 · Düğme: ${_actions[r[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/audit
- **Adım:** "${_actions[r[" öğesine dokun (kaynak satırı 148); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-AUDIT-05`

---

### activate_screen
- Dosya: `admin_app/lib/features/auth/presentation/screens/activate_screen.dart`

#### Y-ACTIVATE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/activate
- **Adım:** Ekranı aç: http://localhost:3003/#/activate — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Mesaj (satır 118): Şifreniz belirlendi. Şimdi giriş yapabilirsiniz.
- **Adım:** Başlık (satır 131): Şifre Belirle
- **Adım:** Alan (satır 160): Telefon Numarası
- **Adım:** Alan (satır 160): 0555 123 45 67 · yurt dışı: +49 …
- **Adım:** Alan (satır 178): Kod
- **Adım:** Alan (satır 185): Yeni Şifre
- **Adım:** Alan (satır 192): Yeni Şifre (tekrar)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATE-00`

#### Y-ACTIVATE-01 · Düğme: Yeniden gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/activate
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
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATE-01`

#### Y-ACTIVATE-02 · Düğme: Şifremi Belirle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/activate
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
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATE-02`

---

### kvkk_consent_screen
- Dosya: `admin_app/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`

#### Y-KVKK-CONSENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/kvkk-consent
- **Adım:** Ekranı aç: http://localhost:3003/#/kvkk-consent — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
- **Adım:** Başlık (satır 40): Kişisel Verilerin Korunması
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-KVKK-CONSENT-00`

#### Y-KVKK-CONSENT-01 · Düğme: Onaylıyorum ve Devam Ediyorum
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/kvkk-consent
- **Adım:** "Onaylıyorum ve Devam Ediyorum" öğesine dokun (kaynak satırı 84)
- **Beklenen (yazma):** `POST /users/me/kvkk-consent` (identity, `services/identity/main.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/kvkk-consent' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-KVKK-CONSENT-01`

---

### login_screen
- Dosya: `admin_app/lib/features/auth/presentation/screens/login_screen.dart`

#### Y-LOGIN-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** Ekranı aç: http://localhost:3003/#/login — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 95): Biyometrik Giriş
- **Adım:** Alan (satır 225): Telefon Numarası
- **Adım:** Alan (satır 226): +90 555 123 4567
- **Adım:** Alan (satır 243): Şifre
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-00`

#### Y-LOGIN-01 · Düğme: Hayır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "Hayır" öğesine dokun (kaynak satırı 101); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-01`

#### Y-LOGIN-02 · Düğme: Etkinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "Etkinleştir" öğesine dokun (kaynak satırı 105); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-02`

#### Y-LOGIN-03 · Düğme: simge düğmesi (satır 245)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "simge düğmesi (satır 245)" öğesine dokun (kaynak satırı 245); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-03`

#### Y-LOGIN-04 · Düğme: Giriş Yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "Giriş Yap" öğesine dokun (kaynak satırı 264); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/login` (identity, `services/identity/main.go:78`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/login' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-04`

#### Y-LOGIN-05 · Düğme: Biyometrik Giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "Biyometrik Giriş" öğesine dokun (kaynak satırı 278); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-05`

#### Y-LOGIN-06 · Düğme: Şifremi Unuttum / Hesabı Etkinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/login
- **Adım:** "Şifremi Unuttum / Hesabı Etkinleştir" öğesine dokun (kaynak satırı 290); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-LOGIN-06`

---

### bulletin_board_screen
- Dosya: `admin_app/lib/features/bulletin/presentation/screens/bulletin_board_screen.dart`

#### Y-BULLETIN-BOARD-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** Ekranı aç: http://localhost:3003/#/bulletin — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /bulletins/:id/comments` (bulletin); `GET /bulletins` (bulletin); `GET /bulletins-summary` (bulletin)
- **Adım:** Başlık (satır 170): İlan Panosu
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Onay bekleyen
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Yayında
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tümü
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-00`

#### Y-BULLETIN-BOARD-01 · Düğme: Gizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "Gizle" öğesine dokun (kaynak satırı 104); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `DELETE /bulletin-comments/:id` (bulletin, `services/bulletin/main.go:154`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_comments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_comments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletin-comments/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-01`

#### Y-BULLETIN-BOARD-02 · Düğme: ${b[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "${b[" öğesine dokun (kaynak satırı 149); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `DELETE /bulletin-comments/:id` (bulletin, `services/bulletin/main.go:154`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_comments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_comments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletin-comments/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-02`

#### Y-BULLETIN-BOARD-03 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 155); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /bulletins/:id/reject` (bulletin, `services/bulletin/main.go:183`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `bulletin.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-03`

#### Y-BULLETIN-BOARD-04 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 156)
- **Beklenen (yazma):** `POST /bulletins/:id/approve` (bulletin, `services/bulletin/main.go:170`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `bulletin.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-04`

#### Y-BULLETIN-BOARD-05 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 158); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /bulletins/:id/close` (bulletin, `services/bulletin/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-05`

#### Y-BULLETIN-BOARD-06 · Düğme: Süresi dolanları kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/bulletin
- **Adım:** "Süresi dolanları kapat" öğesine dokun (kaynak satırı 174); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /bulletins/expire-due` (bulletin, `services/bulletin/main.go:205`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/expire-due' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-BULLETIN-BOARD-06`

---

### smart_collection_screen
- Dosya: `admin_app/lib/features/collection/presentation/screens/smart_collection_screen.dart`

#### Y-SMART-COLLECTION-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/collection
- **Adım:** Ekranı aç: http://localhost:3003/#/collection — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /collection/risk` (smart_collection)
- **Adım:** Başlık (satır 68): Tahsilat Riski
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SMART-COLLECTION-00`

#### Y-SMART-COLLECTION-01 · Düğme: Skorları kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/collection
- **Adım:** "Skorları kaydet" öğesine dokun (kaynak satırı 72); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /collection/risk/snapshot` (smart_collection, `services/smart_collection/main.go:120`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `payment_risk_scores` — satır silinmiş olmalı: `SELECT xmin, * FROM payment_risk_scores ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payment_risk_scores` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_risk_scores ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/collection/risk/snapshot' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SMART-COLLECTION-01`

---

### contract_management_screen
- Dosya: `admin_app/lib/features/contracts/presentation/screens/contract_management_screen.dart`

#### Y-CONTRACT-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** Ekranı aç: http://localhost:3003/#/contracts — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /contracts` (contract); `GET /contracts-summary` (contract)
- **Adım:** Başlık (satır 129): Sözleşmeler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Yürürlükte
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: 60 günde bitenler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tümü
- **Adım:** Mesaj (satır 245): Bitiş tarihi başlangıçtan önce olamaz
- **Adım:** Alan (satır 286): Tür
- **Adım:** Alan (satır 292): Başlık *
- **Adım:** Alan (satır 297): Karşı taraf (firma / kişi) *
- **Adım:** Alan (satır 321): Ödeme
- **Adım:** Alan (satır 332): Tutar (₺)
- **Adım:** Alan (satır 338): Yenileme süresi (ay)
- **Adım:** Alan (satır 344): İhbar süresi (gün)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-00`

#### Y-CONTRACT-MANAGEMENT-01 · Düğme: Feshet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Feshet" öğesine dokun (kaynak satırı 115); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /contracts/:id/terminate` (contract, `services/contract/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/:id/terminate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-01`

#### Y-CONTRACT-MANAGEMENT-02 · Düğme: Yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Yenile" öğesine dokun (kaynak satırı 117); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /contracts/:id/renew` (contract, `services/contract/main.go:138`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/:id/renew' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-02`

#### Y-CONTRACT-MANAGEMENT-03 · Düğme: Süresi dolanları kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Süresi dolanları kapat" öğesine dokun (kaynak satırı 133); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /contracts/expire-due` (contract, `services/contract/main.go:172`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/expire-due' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-03`

#### Y-CONTRACT-MANAGEMENT-04 · Düğme: Sözleşme
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Sözleşme" öğesine dokun (kaynak satırı 151); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-04`

#### Y-CONTRACT-MANAGEMENT-05 · Seçim: Tür
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Tür" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-05`

#### Y-CONTRACT-MANAGEMENT-06 · Düğme: Başlangıç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Başlangıç" öğesine dokun (kaynak satırı 300); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-06`

#### Y-CONTRACT-MANAGEMENT-07 · Düğme: Bitiş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Bitiş" öğesine dokun (kaynak satırı 309); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-07`

#### Y-CONTRACT-MANAGEMENT-08 · Düğme: simge düğmesi (satır 313)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "simge düğmesi (satır 313)" öğesine dokun (kaynak satırı 313); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-08`

#### Y-CONTRACT-MANAGEMENT-09 · Seçim: Aylık
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Aylık" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-09`

#### Y-CONTRACT-MANAGEMENT-10 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/contracts
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 348)
- **Beklenen (yazma):** `POST /contracts` (contract, `services/contract/main.go:117`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CONTRACT-MANAGEMENT-10`

---

### dashboard_screen
- Dosya: `admin_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`

#### Y-DASHBOARD-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** Ekranı aç: http://localhost:3003/#/ — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/payments` (finance); `GET /dashboard/stats` (gateway)
- **Adım:** Başlık (satır 108): Dashboard
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-00`

#### Y-DASHBOARD-01 · Düğme: simge düğmesi (satır 111)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "simge düğmesi (satır 111)" öğesine dokun (kaynak satırı 111)
- **Beklenen (okuma):** `GET /finance/payments` (finance), `GET /dashboard/stats` (gateway) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-01`

#### Y-DASHBOARD-02 · Düğme: Tahakkuk Oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Tahakkuk Oluştur" öğesine dokun (kaynak satırı 146); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-02`

#### Y-DASHBOARD-03 · Düğme: Duyuru Yayınla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Duyuru Yayınla" öğesine dokun (kaynak satırı 154); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-03`

#### Y-DASHBOARD-04 · Düğme: Sayaç Oku
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Sayaç Oku" öğesine dokun (kaynak satırı 166); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-04`

#### Y-DASHBOARD-05 · Düğme: Rapor Oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Rapor Oluştur" öğesine dokun (kaynak satırı 174); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-05`

#### Y-DASHBOARD-06 · Düğme: Tümünü Gör
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Tümünü Gör" öğesine dokun (kaynak satırı 193); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-06`

#### Y-DASHBOARD-07 · Düğme: Toplam Sakin
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Toplam Sakin" öğesine dokun (kaynak satırı 231); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-07`

#### Y-DASHBOARD-08 · Düğme: Dönem Tahsilatı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Dönem Tahsilatı" öğesine dokun (kaynak satırı 238); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-08`

#### Y-DASHBOARD-09 · Düğme: Tahsilat Oranı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Tahsilat Oranı" öğesine dokun (kaynak satırı 245); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-09`

#### Y-DASHBOARD-10 · Düğme: Açık Talep
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "Açık Talep" öğesine dokun (kaynak satırı 253); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-10`

#### Y-DASHBOARD-11 · Düğme: simge düğmesi (satır 320)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "simge düğmesi (satır 320)" öğesine dokun (kaynak satırı 320); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-11`

#### Y-DASHBOARD-12 · Düğme: simge düğmesi (satır 379)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/
- **Adım:** "simge düğmesi (satır 379)" öğesine dokun (kaynak satırı 379); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DASHBOARD-12`

---

### documents_screen
- Dosya: `admin_app/lib/features/documents/presentation/screens/documents_screen.dart`

#### Y-DOCUMENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/documents
- **Adım:** Ekranı aç: http://localhost:3003/#/documents — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /documents` (document); `GET /documents-summary` (document); `GET /documents/:id/download` (document); `GET /documents/:id/access-log` (document)
- **Adım:** Başlık (satır 71): Belge arşivi
- **Adım:** Başlık (satır 110): Erişim — ${x[
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-DOCUMENTS-00`

#### Y-DOCUMENTS-01 · Düğme: Yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/documents
- **Adım:** "Yükle" öğesine dokun (kaynak satırı 80); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /documents` (document, `services/document/main.go:171`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `documents_supersede` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/documents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/documents`, Sakin `documents_screen`, Yön.mobil `documents_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-DOCUMENTS-01`

---

### emergency_screen
- Dosya: `admin_app/lib/features/emergency/presentation/screens/emergency_screen.dart`

#### Y-EMERGENCY-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** Ekranı aç: http://localhost:3003/#/emergency — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /emergency/cards` (community); `GET /emergency/checks` (community); `GET /emergency/info` (community); `GET /emergency/drills` (community); `GET /emergency/checks/:id/responses` (community)
- **Adım:** Mesaj (satır 66): Çağrı açıldı. ${(r[
- **Adım:** Başlık (satır 87): Sakin acil bilgi kartları
- **Adım:** Başlık (satır 110): Acil durum ve afet
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Durum bildirimi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Noktalar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İletişim
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tatbikatlar
- **Adım:** Başlık (satır 254): Durum yanıtları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-00`

#### Y-EMERGENCY-01 · Düğme: simge düğmesi (satır 52)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "simge düğmesi (satır 52)" öğesine dokun (kaynak satırı 52); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-01`

#### Y-EMERGENCY-02 · Düğme: Acil bilgi kartları
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "Acil bilgi kartları" öğesine dokun (kaynak satırı 112)
- **Beklenen (okuma):** `GET /emergency/cards` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-02`

#### Y-EMERGENCY-03 · Düğme: ${s[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "${s[" öğesine dokun (kaynak satırı 127); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-03`

#### Y-EMERGENCY-04 · Düğme: simge düğmesi (satır 159)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "simge düğmesi (satır 159)" öğesine dokun (kaynak satırı 159)
- **Beklenen (yazma):** `DELETE /emergency/points/:id` (community, `services/community/emergency.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/points/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-04`

#### Y-EMERGENCY-05 · Düğme: Ulusal acil: ${d[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "Ulusal acil: ${d[" öğesine dokun (kaynak satırı 189); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Adım:** Dış bağlantı yeni sekmede açılır (kart ödemesinde sahte iyzico sayfası: http://localhost:18000/iyzico/pay/…)
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-05`

#### Y-EMERGENCY-06 · Düğme: ${c[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "${c[" öğesine dokun (kaynak satırı 195); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Adım:** Dış bağlantı yeni sekmede açılır (kart ödemesinde sahte iyzico sayfası: http://localhost:18000/iyzico/pay/…)
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-06`

#### Y-EMERGENCY-07 · Düğme: simge düğmesi (satır 200)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "simge düğmesi (satır 200)" öğesine dokun (kaynak satırı 200)
- **Beklenen (yazma):** `DELETE /emergency/contacts/:id` (community, `services/community/emergency.go:117`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/contacts/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-07`

#### Y-EMERGENCY-08 · Düğme: Çağrıyı kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/emergency
- **Adım:** "Çağrıyı kapat" öğesine dokun (kaynak satırı 277)
- **Beklenen (yazma):** `POST /emergency/checks/:id/close` (community, `services/community/emergency.go:383`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `safety_checks` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM safety_checks ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/checks/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-EMERGENCY-08`

---

### energy_dashboard_screen
- Dosya: `admin_app/lib/features/energy/presentation/screens/energy_dashboard_screen.dart`

#### Y-ENERGY-DASHBOARD-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/energy
- **Adım:** Ekranı aç: http://localhost:3003/#/energy — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /energy/trends` (energy_analytics); `GET /energy/anomalies` (energy_analytics)
- **Adım:** Başlık (satır 51): Tüketim Analizi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Eğilim
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Olağandışı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ENERGY-DASHBOARD-00`

---

### esg_screen
- Dosya: `admin_app/lib/features/esg/presentation/screens/esg_screen.dart`

#### Y-ESG-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/esg
- **Adım:** Ekranı aç: http://localhost:3003/#/esg — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /esg/consumption` (esg)
- **Adım:** Başlık (satır 52): Karbon ayak izi
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ESG-00`

#### Y-ESG-01 · Düğme: Başlangıç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/esg
- **Adım:** "Başlangıç" öğesine dokun (kaynak satırı 61); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ESG-01`

#### Y-ESG-02 · Düğme: Bitiş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/esg
- **Adım:** "Bitiş" öğesine dokun (kaynak satırı 62); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ESG-02`

#### Y-ESG-03 · Düğme: Hesapla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/esg
- **Adım:** "Hesapla" öğesine dokun (kaynak satırı 75); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /esg/carbon-footprint` (esg, `services/esg/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: AUDITOR/BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/esg/carbon-footprint' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ESG-03`

---

### add_expense_screen
- Dosya: `admin_app/lib/features/expenses/presentation/screens/add_expense_screen.dart`

#### Y-ADD-EXPENSE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/add
- **Adım:** Ekranı aç: http://localhost:3003/#/expenses/add — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /expense-categories` (expense)
- **Adım:** Başlık (satır 95): Gider Ekle
- **Adım:** Alan (satır 154): Kategori *
- **Adım:** Alan (satır 198): Açıklama *
- **Adım:** Alan (satır 209): Tutar (₺) *
- **Adım:** Alan (satır 224): Tarih *
- **Adım:** Alan (satır 271): Faturasız olma nedeni *
- **Adım:** Alan (satır 331): Firma Adı
- **Adım:** Alan (satır 336): Fatura No
- **Adım:** Mesaj (satır 386): Kategori seçin.
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-EXPENSE-00`

#### Y-ADD-EXPENSE-01 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/add
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 98)
- **Beklenen (yazma):** `POST /expenses` (expense, `services/expense/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expense_distributions` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expense_distributions ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `expenses` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-EXPENSE-01`

#### Y-ADD-EXPENSE-02 · Seçim: name / category_name /
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/add
- **Adım:** "name / category_name /" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-EXPENSE-02`

#### Y-ADD-EXPENSE-03 · Düğme: Tarih *
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/add
- **Adım:** "Tarih *" öğesine dokun (kaynak satırı 220); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-EXPENSE-03`

---

### expense_detail_screen
- Dosya: `admin_app/lib/features/expenses/presentation/screens/expense_detail_screen.dart`

#### Y-EXPENSE-DETAIL-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/:id
- **Adım:** Ekranı aç: http://localhost:3003/#/expenses/:id — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /expenses/:id` (expense)
- **Adım:** Başlık (satır 89): Gider Detayı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSE-DETAIL-00`

#### Y-EXPENSE-DETAIL-01 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/:id
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 96); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /expenses/:id/reject` (expense, `services/expense/main.go:73`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expenses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSE-DETAIL-01`

#### Y-EXPENSE-DETAIL-02 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses/:id
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 98); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /expenses/:id/approve` (expense, `services/expense/main.go:72`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expenses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSE-DETAIL-02`

---

### expenses_screen
- Dosya: `admin_app/lib/features/expenses/presentation/screens/expenses_screen.dart`

#### Y-EXPENSES-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** Ekranı aç: http://localhost:3003/#/expenses — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /expenses` (expense); `GET /expenses/summary` (expense)
- **Adım:** Başlık (satır 92): Gider Yönetimi
- **Adım:** Başlık (satır 100): ${DateTime.now().year} gider özeti
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-00`

#### Y-EXPENSES-01 · Düğme: ${DateTime.now().year} gider özeti
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "${DateTime.now().year} gider özeti" öğesine dokun (kaynak satırı 95)
- **Beklenen (okuma):** `GET /expenses/summary` (expense) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-01`

#### Y-EXPENSES-02 · Düğme: ${_monthName(_month)} $_year
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "${_monthName(_month)} $_year" öğesine dokun (kaynak satırı 126); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /expenses` (expense) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-02`

#### Y-EXPENSES-03 · Düğme: Tümü
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Tümü" öğesine dokun (kaynak satırı 158); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-03`

#### Y-EXPENSES-04 · Düğme: Aidata Yansıyan
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Aidata Yansıyan" öğesine dokun (kaynak satırı 162); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-04`

#### Y-EXPENSES-05 · Düğme: Faturasız
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Faturasız" öğesine dokun (kaynak satırı 166); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-05`

#### Y-EXPENSES-06 · Düğme: Onay Bekleyen
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Onay Bekleyen" öğesine dokun (kaynak satırı 170); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-06`

#### Y-EXPENSES-07 · Düğme: Gider Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Gider Ekle" öğesine dokun (kaynak satırı 181)
- **Beklenen (okuma):** `GET /expenses` (expense) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-07`

#### Y-EXPENSES-08 · Düğme: simge düğmesi (satır 268)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "simge düğmesi (satır 268)" öğesine dokun (kaynak satırı 268); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-08`

#### Y-EXPENSES-09 · Düğme: simge düğmesi (satır 308)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "simge düğmesi (satır 308)" öğesine dokun (kaynak satırı 308); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-09`

#### Y-EXPENSES-10 · Düğme: Faturasız
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/expenses
- **Adım:** "Faturasız" öğesine dokun (kaynak satırı 437); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-EXPENSES-10`

---

### resident_expenses_screen
- Dosya: `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`

#### Y-RESIDENT-EXPENSES-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /expenses` (expense)
- **Adım:** Başlık (satır 70): Site Giderleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-00`

#### Y-RESIDENT-EXPENSES-01 · Düğme: Dönem seç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** "Dönem seç" öğesine dokun (kaynak satırı 73); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /expenses` (expense) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-01`

#### Y-RESIDENT-EXPENSES-02 · Düğme: ${_monthName(_month)} $_year
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** "${_monthName(_month)} $_year" öğesine dokun (kaynak satırı 189); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /expenses` (expense) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-02`

#### Y-RESIDENT-EXPENSES-03 · Düğme: simge düğmesi (satır 230)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** "simge düğmesi (satır 230)" öğesine dokun (kaynak satırı 230); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-03`

#### Y-RESIDENT-EXPENSES-04 · Düğme: Faturayı Görüntüle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** "Faturayı Görüntüle" öğesine dokun (kaynak satırı 375); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-04`

#### Y-RESIDENT-EXPENSES-05 · Düğme: simge düğmesi (satır 413)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`)
- **Adım:** "simge düğmesi (satır 413)" öğesine dokun (kaynak satırı 413); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-EXPENSES-05`

---

### collection_entry_screen
- Dosya: `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`

#### Y-COLLECTION-ENTRY-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/units/:id/open-assessments` (finance); `GET /units` (identity)
- **Adım:** Başlık (satır 103): (dinamik)
- **Adım:** Alan (satır 117): Daire
- **Adım:** Alan (satır 162): Açıklama / makbuz no
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-COLLECTION-ENTRY-00`

#### Y-COLLECTION-ENTRY-01 · Seçim: ${u[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`)
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen (okuma):** `GET /finance/units/:id/open-assessments` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-COLLECTION-ENTRY-01`

#### Y-COLLECTION-ENTRY-02 · Düğme: Ödeme günü
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`)
- **Adım:** "Ödeme günü" öğesine dokun (kaynak satırı 152); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-COLLECTION-ENTRY-02`

#### Y-COLLECTION-ENTRY-03 · Düğme: Kaydediliyor… / Kaydet ve borçtan düş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`)
- **Adım:** "Kaydediliyor… / Kaydet ve borçtan düş" öğesine dokun (kaynak satırı 166)
- **Beklenen (yazma):** `POST /finance/bank-statements/lines/:id/collect` (finance, `services/finance/main.go:156`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; `assessment_visible_to`
  - Veritabanı tetikleyicileri çalışır: `late_fee_accruals_active_property`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payment_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payment_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements/lines/:id/collect' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `payment.recorded` → alıcı: borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'payment.recorded%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Beklenen (yazma):** `POST /finance/collections` (finance, `services/finance/main.go:155`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; `assessment_visible_to`
  - Veritabanı tetikleyicileri çalışır: `late_fee_accruals_active_property`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payment_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payment_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/collections' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `payment.recorded` → alıcı: borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'payment.recorded%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-COLLECTION-ENTRY-03`

---

### create_assessment_screen
- Dosya: `admin_app/lib/features/finance/presentation/screens/create_assessment_screen.dart`

#### Y-CREATE-ASSESSMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** Ekranı aç: http://localhost:3003/#/finance/assessments/create — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/expense-categories` (finance); `GET /units` (identity)
- **Adım:** Başlık (satır 112): Tahakkuk Oluştur
- **Adım:** Alan (satır 152): Yıl
- **Adım:** Alan (satır 163): Ay
- **Adım:** Mesaj (satır 309): En az bir gider kalemi ekleyin.
- **Adım:** Mesaj (satır 313): Her kalem için kategori ve sıfırdan büyük tutar girin.
- **Adım:** Alan (satır 395): Kalem
- **Adım:** Alan (satır 416): Tutar (₺)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-00`

#### Y-CREATE-ASSESSMENT-01 · Seçim: $y
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "$y" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-01`

#### Y-CREATE-ASSESSMENT-02 · Seçim: Ay
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "Ay" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-02`

#### Y-CREATE-ASSESSMENT-03 · Düğme: Son Ödeme Tarihi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "Son Ödeme Tarihi" öğesine dokun (kaynak satırı 174); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-03`

#### Y-CREATE-ASSESSMENT-04 · Düğme: Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "Ekle" öğesine dokun (kaynak satırı 193); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-04`

#### Y-CREATE-ASSESSMENT-05 · Düğme: Tahakkuk Oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "Tahakkuk Oluştur" öğesine dokun (kaynak satırı 272)
- **Beklenen (yazma):** `POST /finance/assessments` (finance, `services/finance/main.go:135`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `assessment_details` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assessment_details ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/assessments' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `dues.created` → alıcı: borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-05`

#### Y-CREATE-ASSESSMENT-06 · Seçim: name / category_name /
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "name / category_name /" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-06`

#### Y-CREATE-ASSESSMENT-07 · Düğme: simge düğmesi (satır 426)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/assessments/create
- **Adım:** "simge düğmesi (satır 426)" öğesine dokun (kaynak satırı 426); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CREATE-ASSESSMENT-07`

---

### finance_screen
- Dosya: `admin_app/lib/features/finance/presentation/screens/finance_screen.dart`

#### Y-FINANCE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** Ekranı aç: http://localhost:3003/#/finance — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/assessments/overview` (finance); `GET /finance/debtors` (finance)
- **Adım:** Başlık (satır 40): Finans
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Dönemler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Borçlular
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Devir bakiyeleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-00`

#### Y-FINANCE-01 · Düğme: Gecikme tazminatı işlet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** "Gecikme tazminatı işlet" öğesine dokun (kaynak satırı 43)
- **Beklenen (yazma):** `POST /finance/late-fees/accrue` (finance, `services/finance/main.go:143`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `late_fee_accruals_active_property`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `late_fee_accruals` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `late_fee_accruals` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM late_fee_accruals ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/late-fees/accrue' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-01`

#### Y-FINANCE-02 · Düğme: Ödemeler
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** "Ödemeler" öğesine dokun (kaynak satırı 44); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-02`

#### Y-FINANCE-03 · Düğme: Tahakkuk
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** "Tahakkuk" öğesine dokun (kaynak satırı 53); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-03`

#### Y-FINANCE-04 · Düğme: simge düğmesi (satır 62)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** "simge düğmesi (satır 62)" öğesine dokun (kaynak satırı 62); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-04`

#### Y-FINANCE-05 · Düğme: simge düğmesi (satır 64)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance
- **Adım:** "simge düğmesi (satır 64)" öğesine dokun (kaynak satırı 64); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-05`

---

### finance_tools_screen
- Dosya: `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`

#### Y-FINANCE-TOOLS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/ledger/verify` (finance); `GET /finance/ledger` (finance); `GET /finance/units/:id/open-assessments` (finance); `GET /finance/credit-notes` (finance); `GET /finance/credit-notes/:id/pdf` (finance); `GET /finance/bank-statements` (finance); `GET /finance/payments/pending` (finance); `GET /finance/bank-statements/:id` (finance); `GET /units` (identity); `GET /finance/opening-balances` (finance)
- **Adım:** Başlık (satır 27): Tahsilat defteri
- **Adım:** Mesaj (satır 96): Borcu kalan tahakkuk yok
- **Adım:** Başlık (satır 118): Alacak dekontları
- **Adım:** Başlık (satır 187): Banka ekstresi
- **Adım:** Başlık (satır 237): Hareketler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-00`

#### Y-FINANCE-TOOLS-01 · Düğme: Zinciri doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** "Zinciri doğrula" öğesine dokun (kaynak satırı 28)
- **Beklenen (okuma):** `GET /finance/ledger/verify` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-01`

#### Y-FINANCE-TOOLS-02 · Düğme: Dekont kes
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** "Dekont kes" öğesine dokun (kaynak satırı 119); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/credit-notes` (finance, `services/finance/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `credit_notes_guard`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `credit_notes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM credit_notes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/credit-notes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-02`

#### Y-FINANCE-TOOLS-03 · Düğme: Yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** "Yükle" öğesine dokun (kaynak satırı 188); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/bank-statements` (finance, `services/finance/main.go:150`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bank_statement_imports` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bank_statement_imports ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Yön.mobil `finance_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-03`

#### Y-FINANCE-TOOLS-04 · Düğme: ${x[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** "${x[" öğesine dokun (kaynak satırı 193); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-04`

#### Y-FINANCE-TOOLS-05 · Düğme: Devir gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`)
- **Adım:** "Devir gir" öğesine dokun (kaynak satırı 352); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/credit-notes` (finance, `services/finance/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `credit_notes_guard`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `credit_notes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM credit_notes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/credit-notes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-FINANCE-TOOLS-05`

---

### payments_screen
- Dosya: `admin_app/lib/features/finance/presentation/screens/payments_screen.dart`

#### Y-PAYMENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** Ekranı aç: http://localhost:3003/#/finance/payments — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/payments/:id/receipts` (finance); `GET /finance/payments/:id/receipts/:receiptId/download` (finance); `GET /finance/payments/pending` (finance); `GET /finance/payments` (finance)
- **Adım:** Başlık (satır 94): Dekontlar — ${p[
- **Adım:** Başlık (satır 150): Ödemeler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Onay bekleyen
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tümü
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-00`

#### Y-PAYMENTS-01 · Düğme: ${r[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "${r[" öğesine dokun (kaynak satırı 98)
- **Beklenen (okuma):** `GET /finance/payments/:id/receipts/:receiptId/download` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-01`

#### Y-PAYMENTS-02 · Düğme: ${p[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "${p[" öğesine dokun (kaynak satırı 132)
- **Beklenen (okuma):** `GET /finance/payments/:id/receipts` (finance), `GET /finance/payments/:id/receipts/:receiptId/download` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-02`

#### Y-PAYMENTS-03 · Düğme: Ters kayıt
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "Ters kayıt" öğesine dokun (kaynak satırı 133)
- **Beklenen (yazma):** `POST /finance/payments/:id/reverse` (finance, `services/finance/main.go:139`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/reverse' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-03`

#### Y-PAYMENTS-04 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 135); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/payments/:id/reject` (finance, `services/finance/main.go:140`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payments_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Sakin `dues_payment_screen`, Sakin `payment_history_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-04`

#### Y-PAYMENTS-05 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 137); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /finance/payments/:id/confirm` (finance, `services/finance/main.go:138`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-05`

#### Y-PAYMENTS-06 · Düğme: Tahsilat gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/finance/payments
- **Adım:** "Tahsilat gir" öğesine dokun (kaynak satırı 162); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PAYMENTS-06`

---

### governance_screen
- Dosya: `admin_app/lib/features/governance/presentation/screens/governance_screen.dart`

#### Y-GOVERNANCE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** Ekranı aç: http://localhost:3003/#/governance — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /governance/assemblies` (governance); `GET /governance/assemblies/:id` (governance); `GET /governance/budgets` (governance); `GET /governance/budgets/:id/export` (governance); `GET /governance/budgets/:id/export` (governance); `GET /governance/budgets/:id` (governance); `GET /governance/budgets/:id/objections` (governance); `GET /units` (identity); `GET /residents` (identity); `GET /governance/assemblies/:id` (governance); `GET /governance/assemblies/:id/attendees` (governance); `GET /governance/assemblies/:id/quorum` (governance); `GET /governance/assemblies/:id/attendance-sheet` (governance); `GET /governance/assemblies/:id/attendance-sheet` (governance); `GET /governance/books/:id/entries` (governance); `GET /governance/books/:id/verify` (governance); `GET /governance/books/:id/export` (governance); `GET /governance/legal-cases` (governance); `GET /governance/common-area/leases` (governance); `GET /governance/common-area/report` (governance)
- **Adım:** Başlık (satır 88): Yönetişim (KMK)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İşletme projesi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Genel kurul
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Defterler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İcra ve dava
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Ortak alan
- **Adım:** Mesaj (satır 192): En az bir kalem ekleyin
- **Adım:** Mesaj (satır 203): ${r[
- **Adım:** Başlık (satır 223): İşletme projesi hazırla
- **Adım:** Alan (satır 232): Not
- **Adım:** Başlık (satır 311): İşletme projesi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Özet
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Daire payları
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İtirazlar
- **Adım:** Mesaj (satır 475): Toplantı bilgisi ve en az bir gündem maddesi gerekli
- **Adım:** Mesaj (satır 486): Toplantı planlandı
- **Adım:** Başlık (satır 500): Toplantı planla
- **Adım:** Pencere (satır 572): ${r[
- **Adım:** Başlık (satır 588): Genel kurul
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-00`

#### Y-GOVERNANCE-01 · Düğme: simge düğmesi (satır 111)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 111)" öğesine dokun (kaynak satırı 111); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-01`

#### Y-GOVERNANCE-02 · Düğme: ${b[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "${b[" öğesine dokun (kaynak satırı 148); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-02`

#### Y-GOVERNANCE-03 · Düğme: Taslak kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Taslak kaydet" öğesine dokun (kaynak satırı 224)
- **Beklenen (yazma):** `POST /governance/budgets` (governance, `services/governance/main.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budget_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budget_unit_shares` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_unit_shares ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budgets` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-03`

#### Y-GOVERNANCE-04 · Düğme: simge düğmesi (satır 228)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 228)" öğesine dokun (kaynak satırı 228); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-04`

#### Y-GOVERNANCE-05 · Düğme: simge düğmesi (satır 230)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 230)" öğesine dokun (kaynak satırı 230); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-05`

#### Y-GOVERNANCE-06 · Düğme: ${_items[i][
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "${_items[i][" öğesine dokun (kaynak satırı 236); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-06`

#### Y-GOVERNANCE-07 · Düğme: simge düğmesi (satır 240)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 240)" öğesine dokun (kaynak satırı 240); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-07`

#### Y-GOVERNANCE-08 · Düğme: Kalem
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Kalem" öğesine dokun (kaynak satırı 242); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-08`

#### Y-GOVERNANCE-09 · Düğme: Geçici proje olarak bildir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Geçici proje olarak bildir" öğesine dokun (kaynak satırı 342)
- **Beklenen (yazma):** `POST /governance/budgets/:id/notify` (governance, `services/governance/main.go:90`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budgets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-09`

#### Y-GOVERNANCE-10 · Düğme: Genel kurul kararıyla kesinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Genel kurul kararıyla kesinleştir" öğesine dokun (kaynak satırı 343)
- **Beklenen (yazma):** `POST /governance/budgets/:id/finalize` (governance, `services/governance/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budgets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/finalize' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-10`

#### Y-GOVERNANCE-11 · Düğme: Aylık aidat tahakkuk et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Aylık aidat tahakkuk et" öğesine dokun (kaynak satırı 344)
- **Beklenen (yazma):** `POST /governance/budgets/:id/assessments` (governance, `services/governance/main.go:92`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `monthly_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/assessments' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `dues.created` → alıcı: borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-11`

#### Y-GOVERNANCE-12 · Düğme: ${formatDateTime(a[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "${formatDateTime(a[" öğesine dokun (kaynak satırı 427); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-12`

#### Y-GOVERNANCE-13 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 501)
- **Beklenen (yazma):** `POST /governance/budgets` (governance, `services/governance/main.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budget_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budget_unit_shares` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_unit_shares ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budgets` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-13`

#### Y-GOVERNANCE-14 · Düğme: Toplantı bilgisi / ${h[ / ] ==  /  ?  /  :  / } · ${h[ / ]}. toplantı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Toplantı bilgisi / ${h[ / ] ==  /  ?  /  :  / } · ${h[ / ]}. toplantı" öğesine dokun (kaynak satırı 503); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-14`

#### Y-GOVERNANCE-15 · Düğme: simge düğmesi (satır 515)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 515)" öğesine dokun (kaynak satırı 515); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-15`

#### Y-GOVERNANCE-16 · Düğme: Madde
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Madde" öğesine dokun (kaynak satırı 517); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-16`

#### Y-GOVERNANCE-17 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 576); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-17`

#### Y-GOVERNANCE-18 · Düğme: Çağrıyı kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Çağrıyı kaydet" öğesine dokun (kaynak satırı 619)
- **Beklenen (yazma):** `POST /governance/assemblies/:id/notify` (governance, `services/governance/main.go:96`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assemblies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assemblies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-18`

#### Y-GOVERNANCE-19 · Düğme: Hazirune ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Hazirune ekle" öğesine dokun (kaynak satırı 629)
- **Beklenen (yazma):** `POST /governance/assemblies/:id/attendees` (governance, `services/governance/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assembly_attendees` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assembly_attendees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/attendees' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-19`

#### Y-GOVERNANCE-20 · Düğme: Toplantıyı yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Toplantıyı yap" öğesine dokun (kaynak satırı 631)
- **Beklenen (yazma):** `POST /governance/assemblies/:id/hold` (governance, `services/governance/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assemblies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assemblies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/hold' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-20`

#### Y-GOVERNANCE-21 · Düğme: Cetvel PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Cetvel PDF" öğesine dokun (kaynak satırı 659)
- **Beklenen (okuma):** `GET /governance/assemblies/:id/attendance-sheet` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-21`

#### Y-GOVERNANCE-22 · Düğme: Excel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Excel" öğesine dokun (kaynak satırı 660)
- **Beklenen (okuma):** `GET /governance/assemblies/:id/attendance-sheet` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-22`

#### Y-GOVERNANCE-23 · Seçim: Karar defteri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "Karar defteri" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-23`

#### Y-GOVERNANCE-24 · Düğme: simge düğmesi (satır 717)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 717)" öğesine dokun (kaynak satırı 717); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-24`

#### Y-GOVERNANCE-25 · Düğme: simge düğmesi (satır 719)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 719)" öğesine dokun (kaynak satırı 719); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-25`

#### Y-GOVERNANCE-26 · Düğme: simge düğmesi (satır 895)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 895)" öğesine dokun (kaynak satırı 895); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-26`

#### Y-GOVERNANCE-27 · Düğme: simge düğmesi (satır 897)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/governance
- **Adım:** "simge düğmesi (satır 897)" öğesine dokun (kaynak satırı 897); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-GOVERNANCE-27`

---

### insurance_screen
- Dosya: `admin_app/lib/features/insurance/presentation/screens/insurance_screen.dart`

#### Y-INSURANCE-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/insurance
- **Adım:** Ekranı aç: http://localhost:3003/#/insurance — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /insurance/dask` (contract); `GET /insurance/claims` (contract)
- **Adım:** Başlık (satır 39): Sigorta
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: DASK
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Hasar kayıtları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INSURANCE-00`

#### Y-INSURANCE-01 · Düğme: Poliçe gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/insurance
- **Adım:** "Poliçe gir" öğesine dokun (kaynak satırı 62)
- **Beklenen (yazma):** `POST /insurance/dask` (contract, `services/contract/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `unit_insurance_policies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM unit_insurance_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/dask' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Sakin `dask_screen`, Yön.mobil `insurance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INSURANCE-01`

#### Y-INSURANCE-02 · Düğme: Hasar kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/insurance
- **Adım:** "Hasar kaydet" öğesine dokun (kaynak satırı 94)
- **Beklenen (yazma):** `POST /insurance/claims` (contract, `services/contract/main.go:114`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `insurance_claims` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM insurance_claims ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/claims' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Yön.mobil `insurance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INSURANCE-02`

#### Y-INSURANCE-03 · Düğme: İlerlet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/insurance
- **Adım:** "İlerlet" öğesine dokun (kaynak satırı 121)
- **Beklenen (yazma):** `POST /insurance/claims/:id/status` (contract, `services/contract/main.go:115`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `insurance_claims` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM insurance_claims ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/claims/:id/status' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Yön.mobil `insurance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INSURANCE-03`

---

### inventory_management_screen
- Dosya: `admin_app/lib/features/inventory/presentation/screens/inventory_management_screen.dart`

#### Y-INVENTORY-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** Ekranı aç: http://localhost:3003/#/inventory — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /inventory-categories` (inventory); `GET /inventory-movements` (inventory); `GET /inventory` (inventory); `GET /inventory-summary` (inventory); `GET /inventory/:id/movements` (inventory)
- **Adım:** Pencere (satır 67): ${item[
- **Adım:** Alan (satır 74): Hareket
- **Adım:** Alan (satır 85): Miktar (${item[
- **Adım:** Başlık (satır 121): Stok
- **Adım:** Başlık (satır 189): (dinamik)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-00`

#### Y-INVENTORY-MANAGEMENT-01 · Seçim: Giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Giriş" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-01`

#### Y-INVENTORY-MANAGEMENT-02 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 96); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-02`

#### Y-INVENTORY-MANAGEMENT-03 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 97); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-03`

#### Y-INVENTORY-MANAGEMENT-04 · Düğme: Son hareketler
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Son hareketler" öğesine dokun (kaynak satırı 125)
- **Beklenen (okuma):** `GET /inventory-movements` (inventory) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-04`

#### Y-INVENTORY-MANAGEMENT-05 · Düğme: Kategori ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Kategori ekle" öğesine dokun (kaynak satırı 130)
- **Beklenen (yazma):** `POST /inventory-categories` (inventory, `services/inventory/main.go:179`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_categories` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM inventory_categories ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory-categories' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-05`

#### Y-INVENTORY-MANAGEMENT-06 · Düğme: Kalem
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inventory
- **Adım:** "Kalem" öğesine dokun (kaynak satırı 133)
- **Beklenen (yazma):** `POST /inventory` (inventory, `services/inventory/main.go:197`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM inventory_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INVENTORY-MANAGEMENT-06`

---

### kvkk_requests_screen
- Dosya: `admin_app/lib/features/kvkk/presentation/screens/kvkk_requests_screen.dart`

#### Y-KVKK-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/kvkk
- **Adım:** Ekranı aç: http://localhost:3003/#/kvkk — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /kvkk-requests` (community)
- **Adım:** Başlık (satır 37): KVKK başvuruları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-KVKK-REQUESTS-00`

#### Y-KVKK-REQUESTS-01 · Düğme: Yanıtla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/kvkk
- **Adım:** "Yanıtla" öğesine dokun (kaynak satırı 54)
- **Beklenen (yazma):** `POST /kvkk-requests/:id/respond` (community, `services/community/kvkk.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `kvkk_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM kvkk_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/kvkk-requests/:id/respond' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `kvkk.response` → alıcı: işlemin muhatabı (k.UserID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'kvkk.response%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/kvkk`, Sakin `kvkk_requests_screen`, Yön.mobil `kvkk_requests_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-KVKK-REQUESTS-01`

---

### main_screen
- Dosya: `admin_app/lib/features/main/presentation/screens/main_screen.dart`

#### Y-MAIN-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /notifications/unread-count` (notification); `GET /users/me/properties` (identity)
- **Adım:** Pencere (satır 200): Uygulamadan çık
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-00`

#### Y-MAIN-01 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 204); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-01`

#### Y-MAIN-02 · Düğme: Çık
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "Çık" öğesine dokun (kaynak satırı 205); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-02`

#### Y-MAIN-03 · Düğme: simge düğmesi (satır 266)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "simge düğmesi (satır 266)" öğesine dokun (kaynak satırı 266); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-03`

#### Y-MAIN-04 · Düğme: Şifre Değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "Şifre Değiştir" öğesine dokun (kaynak satırı 281); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /users/me/password` (identity, `services/identity/main.go:102`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/users/me/password' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-04`

#### Y-MAIN-05 · Düğme: Çıkış Yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "Çıkış Yap" öğesine dokun (kaynak satırı 289); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:87`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-05`

#### Y-MAIN-06 · Düğme: Çıkış yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/main/presentation/screens/main_screen.dart`)
- **Adım:** "Çıkış yap" öğesine dokun (kaynak satırı 328); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /auth/logout` (identity, `services/identity/main.go:87`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `revoked_tokens` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM revoked_tokens ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/auth/logout' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-MAIN-06`

---

### meter_reading_screen
- Dosya: `admin_app/lib/features/meters/presentation/screens/meter_reading_screen.dart`

#### Y-METER-READING-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters/reading
- **Adım:** Ekranı aç: http://localhost:3003/#/meters/reading — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /meters` (iot)
- **Adım:** Mesaj (satır 75): $ok / ${entries.length} okuma kaydedildi
- **Adım:** Başlık (satır 81): Sayaç Okuma
- **Adım:** Alan (satır 118): Yeni değer
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-METER-READING-00`

#### Y-METER-READING-01 · Düğme: simge düğmesi (satır 84)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters/reading
- **Adım:** "simge düğmesi (satır 84)" öğesine dokun (kaynak satırı 84); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-METER-READING-01`

#### Y-METER-READING-02 · Düğme: Kaydediliyor… / Girilen okumaları kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters/reading
- **Adım:** "Kaydediliyor… / Girilen okumaları kaydet" öğesine dokun (kaynak satırı 97)
- **Beklenen (yazma):** `POST /meter-readings` (iot, `services/iot/main.go:161`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `meter_readings` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meter_readings ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meter-readings' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-METER-READING-02`

---

### meters_screen
- Dosya: `admin_app/lib/features/meters/presentation/screens/meters_screen.dart`

#### Y-METERS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** Ekranı aç: http://localhost:3003/#/meters — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /meters` (iot); `GET /meter-readings` (iot); `GET /consumption/statements` (iot); `GET /consumption/statements/:id/pdf` (iot); `GET /consumption/objections` (iot); `GET /consumption/area-check` (iot)
- **Adım:** Başlık (satır 85): Sayaçlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Sayaçlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Okumalar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Paylaştır
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Pusulalar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İtirazlar
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-00`

#### Y-METERS-01 · Düğme: Sayaç ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** "Sayaç ekle" öğesine dokun (kaynak satırı 87)
- **Beklenen (yazma):** `POST /meters` (iot, `services/iot/main.go:188`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `meters` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meters ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meters' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-01`

#### Y-METERS-02 · Düğme: Okuma gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** "Okuma gir" öğesine dokun (kaynak satırı 90); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-02`

#### Y-METERS-03 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** "PDF" öğesine dokun (kaynak satırı 164)
- **Beklenen (okuma):** `GET /consumption/statements/:id/pdf` (iot) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-03`

#### Y-METERS-04 · Düğme: Yanıtla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** "Yanıtla" öğesine dokun (kaynak satırı 184)
- **Beklenen (yazma):** `POST /consumption/objections/:id/respond` (iot, `services/iot/main.go:473`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `consumption_statement_objections_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `consumption_statement_objections` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM consumption_statement_objections ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/consumption/objections/:id/respond' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `statement.objection.answer` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'statement.objection.answer%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-04`

#### Y-METERS-05 · Düğme: Hesapla / yayımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/meters
- **Adım:** "Hesapla / yayımla" öğesine dokun (kaynak satırı 273); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /consumption/allocate` (iot, `services/iot/main.go:239`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `consumption_allocation_units` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM consumption_allocation_units ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `consumption_allocations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM consumption_allocations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/consumption/allocate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-METERS-05`

---

### inbox_screen
- Dosya: `admin_app/lib/features/notifications/presentation/screens/inbox_screen.dart`

#### Y-INBOX-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inbox
- **Adım:** Ekranı aç: http://localhost:3003/#/inbox — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /notifications` (notification)
- **Adım:** Başlık (satır 27): Bildirimlerim
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INBOX-00`

#### Y-INBOX-01 · Düğme: Tümünü okundu say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inbox
- **Adım:** "Tümünü okundu say" öğesine dokun (kaynak satırı 30)
- **Beklenen (yazma):** `POST /notifications/read-all` (notification, `services/notification/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications/read-all' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-INBOX-01`

#### Y-INBOX-02 · Düğme: ${n[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/inbox
- **Adım:** "${n[" öğesine dokun (kaynak satırı 62); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-INBOX-02`

---

### notification_center_screen
- Dosya: `admin_app/lib/features/notifications/presentation/screens/notification_center_screen.dart`

#### Y-NOTIFICATION-CENTER-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/notification-center
- **Adım:** Ekranı aç: http://localhost:3003/#/notification-center — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /residents` (identity); `GET /notifications/outbox` (notification); `GET /notifications/summary` (notification); `GET /notification-preferences` (notification)
- **Adım:** Başlık (satır 53): Bildirim merkezi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Giden kutusu
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tercihlerim
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-NOTIFICATION-CENTER-00`

#### Y-NOTIFICATION-CENTER-01 · Düğme: Gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/notification-center
- **Adım:** "Gönder" öğesine dokun (kaynak satırı 57)
- **Beklenen (yazma):** `POST /notifications` (notification, `services/notification/main.go:158`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{{in}.Topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `Y-NOTIFICATION-CENTER-01`

---

### nps_screen
- Dosya: `admin_app/lib/features/nps/presentation/screens/nps_screen.dart`

#### Y-NPS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/nps
- **Adım:** Ekranı aç: http://localhost:3003/#/nps — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /nps` (nps); `GET /nps/:id/comments` (nps); `GET /nps/:id` (nps)
- **Adım:** Başlık (satır 33): Memnuniyet (NPS)
- **Adım:** Başlık (satır 80): (dinamik)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-NPS-00`

#### Y-NPS-01 · Düğme: Ölçüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/nps
- **Adım:** "Ölçüm" öğesine dokun (kaynak satırı 35)
- **Beklenen (yazma):** `POST /nps` (nps, `services/nps/main.go:159`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `survey_options` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM survey_options ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `surveys` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/nps' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-NPS-01`

#### Y-NPS-02 · Düğme: ${s[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/nps
- **Adım:** "${s[" öğesine dokun (kaynak satırı 52); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-NPS-02`

---

### package_tracking_screen
- Dosya: `admin_app/lib/features/packages/presentation/screens/package_tracking_screen.dart`

#### Y-PACKAGE-TRACKING-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** Ekranı aç: http://localhost:3003/#/packages — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /packages-summary` (package); `GET /packages` (package); `GET /packages/:id/proof/:kind` (package); `GET /packages/:id/proof/:kind` (package); `GET /units` (identity)
- **Adım:** Başlık (satır 37): Kargo
- **Adım:** Pencere (satır 157): Kargo kabul
- **Adım:** Alan (satır 165): Daire
- **Adım:** Alan (satır 173): Alıcı adı
- **Adım:** Alan (satır 175): Kargo firması
- **Adım:** Alan (satır 176): Takip numarası
- **Adım:** Alan (satır 179): Tür
- **Adım:** Alan (satır 187): Saklama yeri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-00`

#### Y-PACKAGE-TRACKING-01 · Düğme: Kargo kabul
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Kargo kabul" öğesine dokun (kaynak satırı 48); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /packages` (package, `services/package/main.go:133`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `package.received` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'package.received%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-01`

#### Y-PACKAGE-TRACKING-02 · Düğme: Menü: Sakine haber verildi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Menü: Sakine haber verildi" öğesine dokun (kaynak satırı 124)
- **Beklenen (yazma):** `POST /packages/:id/deliver` (package, `services/package/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/deliver' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/return` (package, `services/package/main.go:214`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/return' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/notify` (package, `services/package/main.go:162`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-02`

#### Y-PACKAGE-TRACKING-03 · Düğme: Menü: Teslim et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Menü: Teslim et" öğesine dokun (kaynak satırı 125)
- **Beklenen (yazma):** `POST /packages/:id/deliver` (package, `services/package/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/deliver' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/return` (package, `services/package/main.go:214`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/return' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/notify` (package, `services/package/main.go:162`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-03`

#### Y-PACKAGE-TRACKING-04 · Düğme: Menü: İade et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Menü: İade et" öğesine dokun (kaynak satırı 126)
- **Beklenen (yazma):** `POST /packages/:id/deliver` (package, `services/package/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/deliver' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/return` (package, `services/package/main.go:214`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/return' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/notify` (package, `services/package/main.go:162`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-04`

#### Y-PACKAGE-TRACKING-05 · Seçim: ${u[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-05`

#### Y-PACKAGE-TRACKING-06 · Seçim: Paket
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Paket" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-06`

#### Y-PACKAGE-TRACKING-07 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 192); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-07`

#### Y-PACKAGE-TRACKING-08 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/packages
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 193); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PACKAGE-TRACKING-08`

---

### parking_management_screen
- Dosya: `admin_app/lib/features/parking/presentation/screens/parking_management_screen.dart`

#### Y-PARKING-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** Ekranı aç: http://localhost:3003/#/parking — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /parking-logs` (parking); `GET /vehicles` (parking); `GET /parking-zones` (parking); `GET /access-devices` (parking); `GET /vehicles/plate/:plate` (parking); `GET /access-devices/incidents` (parking)
- **Adım:** Başlık (satır 49): Otopark
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İçeride
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Araçlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Bölgeler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Cihazlar
- **Adım:** Pencere (satır 186): ${v[
- **Adım:** Pencere (satır 234): Cihaz anahtarı
- **Adım:** Başlık (satır 260): Çevrimdışı olayları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-00`

#### Y-PARKING-MANAGEMENT-01 · Düğme: Plaka sorgula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Plaka sorgula" öğesine dokun (kaynak satırı 51); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /vehicles/plate/:plate` (parking) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-01`

#### Y-PARKING-MANAGEMENT-02 · Düğme: Giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Giriş" öğesine dokun (kaynak satırı 54); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /parking-logs/entry` (parking, `services/parking/main.go:145`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `parking_logs` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/parking-logs/entry' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-02`

#### Y-PARKING-MANAGEMENT-03 · Düğme: Çıkış
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Çıkış" öğesine dokun (kaynak satırı 68)
- **Beklenen (yazma):** `POST /parking-logs/:id/exit` (parking, `services/parking/main.go:184`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `parking_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/parking-logs/:id/exit' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-03`

#### Y-PARKING-MANAGEMENT-04 · Düğme: Araç kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Araç kaydet" öğesine dokun (kaynak satırı 84)
- **Beklenen (yazma):** `POST /vehicles` (parking, `services/parking/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `vehicles` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM vehicles ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/vehicles' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-04`

#### Y-PARKING-MANAGEMENT-05 · Düğme: Cihaz ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Cihaz ekle" öğesine dokun (kaynak satırı 129); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /access-devices` (parking, `services/parking/devices.go:86`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `access_devices` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM access_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/access-devices' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-05`

#### Y-PARKING-MANAGEMENT-06 · Düğme: Çevrimdışı olayları
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Çevrimdışı olayları" öğesine dokun (kaynak satırı 132); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-06`

#### Y-PARKING-MANAGEMENT-07 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 195); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-07`

#### Y-PARKING-MANAGEMENT-08 · Düğme: Kopyala
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Kopyala" öğesine dokun (kaynak satırı 242); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-08`

#### Y-PARKING-MANAGEMENT-09 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/parking
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 243); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PARKING-MANAGEMENT-09`

---

### checkpoint_setup_screen
- Dosya: `admin_app/lib/features/patrol/presentation/screens/checkpoint_setup_screen.dart`

#### Y-CHECKPOINT-SETUP-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** Ekranı aç: http://localhost:3003/#/patrol/points — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /patrol-checkpoints` (patrol)
- **Adım:** Mesaj (satır 25): Konum ölçülüyor…
- **Adım:** Mesaj (satır 30): Sahte konum algılandı; kaydedilmedi.
- **Adım:** Pencere (satır 83): Yeni QR değeri
- **Adım:** Başlık (satır 133): Devriye noktaları
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-00`

#### Y-CHECKPOINT-SETUP-01 · Düğme: Kopyala
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Kopyala" öğesine dokun (kaynak satırı 87); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-01`

#### Y-CHECKPOINT-SETUP-02 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 88); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-02`

#### Y-CHECKPOINT-SETUP-03 · Düğme: Tur tanımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Tur tanımla" öğesine dokun (kaynak satırı 134)
- **Beklenen (yazma):** `POST /patrol-routes` (patrol, `services/patrol/main.go:236`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_routes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_routes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-routes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-03`

#### Y-CHECKPOINT-SETUP-04 · Düğme: Nokta
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Nokta" öğesine dokun (kaynak satırı 136)
- **Beklenen (yazma):** `POST /patrol-checkpoints` (patrol, `services/patrol/main.go:207`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-04`

#### Y-CHECKPOINT-SETUP-05 · Düğme: Menü: Konumu buradan al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Menü: Konumu buradan al" öğesine dokun (kaynak satırı 162)
- **Beklenen (yazma):** `POST /patrol-checkpoints/:id/location` (patrol, `services/patrol/gps.go:100`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id/location' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-05`

#### Y-CHECKPOINT-SETUP-06 · Düğme: Menü: Yarıçap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Menü: Yarıçap" öğesine dokun (kaynak satırı 163)
- **Beklenen (yazma):** `PATCH /patrol-checkpoints/:id` (patrol, `services/patrol/gps.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-06`

#### Y-CHECKPOINT-SETUP-07 · Düğme: Menü: Konum denetimini aç / Konumdan muaf tut
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Menü: Konum denetimini aç / Konumdan muaf tut" öğesine dokun (kaynak satırı 164)
- **Beklenen (yazma):** `PATCH /patrol-checkpoints/:id` (patrol, `services/patrol/gps.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-07`

#### Y-CHECKPOINT-SETUP-08 · Düğme: Menü: QR yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/points
- **Adım:** "Menü: QR yenile" öğesine dokun (kaynak satırı 165)
- **Beklenen (yazma):** `POST /patrol-checkpoints/:id/rotate-qr` (patrol, `services/patrol/gps.go:101`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id/rotate-qr' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-CHECKPOINT-SETUP-08`

---

### patrol_control_screen
- Dosya: `admin_app/lib/features/patrol/presentation/screens/patrol_control_screen.dart`

#### Y-PATROL-CONTROL-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol
- **Adım:** Ekranı aç: http://localhost:3003/#/patrol — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /patrols` (patrol); `GET /patrols-summary` (patrol); `GET /patrol-routes` (patrol)
- **Adım:** Başlık (satır 29): Devriye
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Turlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Güzergâhlar
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-CONTROL-00`

#### Y-PATROL-CONTROL-01 · Düğme: Devriye yürüt
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol
- **Adım:** "Devriye yürüt" öğesine dokun (kaynak satırı 32); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-CONTROL-01`

#### Y-PATROL-CONTROL-02 · Düğme: Raporlar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol
- **Adım:** "Raporlar" öğesine dokun (kaynak satırı 33); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-CONTROL-02`

#### Y-PATROL-CONTROL-03 · Düğme: Nokta kurulumu
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol
- **Adım:** "Nokta kurulumu" öğesine dokun (kaynak satırı 34); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-CONTROL-03`

---

### patrol_report_screen
- Dosya: `admin_app/lib/features/patrol/presentation/screens/patrol_report_screen.dart`

#### Y-PATROL-REPORT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/reports
- **Adım:** Ekranı aç: http://localhost:3003/#/patrol/reports — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /patrol-reports` (patrol); `GET /patrols/:id/report` (patrol)
- **Adım:** Başlık (satır 35): Devriye raporları
- **Adım:** Başlık (satır 88): Tur raporu
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-REPORT-00`

#### Y-PATROL-REPORT-01 · Düğme: ${p[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/patrol/reports
- **Adım:** "${p[" öğesine dokun (kaynak satırı 66); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-REPORT-01`

---

### patrol_run_screen
- Dosya: `admin_app/lib/features/patrol/presentation/screens/patrol_run_screen.dart`

#### Y-PATROL-RUN-00 · Ekran açılışı ve görünüm
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** Ekranı aç: http://localhost:3003/#/patrol/run — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /patrol-routes` (patrol); `GET /patrol-checkpoints` (patrol); `GET /patrols` (patrol)
- **Adım:** Mesaj (satır 134): $e
- **Adım:** Mesaj (satır 151): $e
- **Adım:** Başlık (satır 238): Devriye yürüt
- **Adım:** Başlık (satır 332): Nokta QR kodunu okutun
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-00`

#### Y-PATROL-RUN-01 · Düğme: ${_points[
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "${_points[" öğesine dokun (kaynak satırı 191); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-01`

#### Y-PATROL-RUN-02 · Düğme: QR okut
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "QR okut" öğesine dokun (kaynak satırı 253)
- **Beklenen (yazma):** `POST /patrols/:id/scan` (patrol, `services/patrol/gps.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_scan_attempts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_scan_attempts ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `patrol_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols/:id/scan' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-02`

#### Y-PATROL-RUN-03 · Düğme: Listeden seç
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "Listeden seç" öğesine dokun (kaynak satırı 260); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /patrols/:id/scan` (patrol, `services/patrol/gps.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_scan_attempts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_scan_attempts ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `patrol_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols/:id/scan' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-03`

#### Y-PATROL-RUN-04 · Düğme: Sorun bildir
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "Sorun bildir" öğesine dokun (kaynak satırı 261); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /patrols/:id/issues` (patrol, `services/patrol/main.go:155`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols/:id/issues' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-04`

#### Y-PATROL-RUN-05 · Düğme: Turu bitir
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "Turu bitir" öğesine dokun (kaynak satırı 262); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /patrols/:id/complete` (patrol, `services/patrol/main.go:179`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols/:id/complete' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `patrol.issue` → alıcı: yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'patrol.issue%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Beklenen (yazma):** `POST /patrols/:id/track` (patrol, `services/patrol/gps.go:90`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_track_points` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_track_points ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols/:id/track' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Yön.mobil `patrol_report_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-05`

#### Y-PATROL-RUN-06 · Düğme: Başlat
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3003/#/patrol/run
- **Adım:** "Başlat" öğesine dokun (kaynak satırı 281)
- **Beklenen (yazma):** `POST /patrols` (patrol, `services/patrol/main.go:133`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_logs` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrols' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PATROL-RUN-06`

---

### personnel_management_screen
- Dosya: `admin_app/lib/features/personnel/presentation/screens/personnel_management_screen.dart`

#### Y-PERSONNEL-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** Ekranı aç: http://localhost:3003/#/personnel — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /employees` (personnel); `GET /employees/summary` (personnel); `GET /leaves` (personnel); `GET /payroll` (personnel); `GET /payroll/costs` (personnel); `GET /compliance-calendar` (personnel); `GET /employees/:id` (personnel)
- **Adım:** Başlık (satır 79): Personel
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Personel
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İzinler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Bordro
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Yükümlülükler
- **Adım:** Başlık (satır 407): (dinamik)
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-00`

#### Y-PERSONNEL-MANAGEMENT-01 · Düğme: İzin gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "İzin gir" öğesine dokun (kaynak satırı 81)
- **Beklenen (yazma):** `POST /leaves` (personnel, `services/personnel/main.go:83`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employee_leaves` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM employee_leaves ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/leaves' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-01`

#### Y-PERSONNEL-MANAGEMENT-02 · Düğme: Personel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "Personel" öğesine dokun (kaynak satırı 90)
- **Beklenen (yazma):** `POST /employees` (personnel, `services/personnel/main.go:81`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employees` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/employees' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-02`

#### Y-PERSONNEL-MANAGEMENT-03 · Düğme: simge düğmesi (satır 113)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "simge düğmesi (satır 113)" öğesine dokun (kaynak satırı 113); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-03`

#### Y-PERSONNEL-MANAGEMENT-04 · Düğme: simge düğmesi (satır 245)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "simge düğmesi (satır 245)" öğesine dokun (kaynak satırı 245); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-04`

#### Y-PERSONNEL-MANAGEMENT-05 · Düğme: simge düğmesi (satır 247)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "simge düğmesi (satır 247)" öğesine dokun (kaynak satırı 247); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-05`

#### Y-PERSONNEL-MANAGEMENT-06 · Düğme: Bordro gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "Bordro gir" öğesine dokun (kaynak satırı 267)
- **Beklenen (yazma):** `POST /payroll` (personnel, `services/personnel/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payroll_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payroll` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payroll ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/payroll' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-06`

#### Y-PERSONNEL-MANAGEMENT-07 · Seçim: ${DateTime.now().year - i}
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "${DateTime.now().year - i}" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-07`

#### Y-PERSONNEL-MANAGEMENT-08 · Düğme: Verildi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/personnel
- **Adım:** "Verildi" öğesine dokun (kaynak satırı 374)
- **Beklenen (yazma):** `POST /employees/:id/sgk` (personnel, `services/personnel/main.go:90`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employees` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/employees/:id/sgk' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-PERSONNEL-MANAGEMENT-08`

---

### renovations_screen
- Dosya: `admin_app/lib/features/renovations/presentation/screens/renovations_screen.dart`

#### Y-RENOVATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** Ekranı aç: http://localhost:3003/#/renovations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /renovations` (community); `GET /residents` (identity); `GET /renovations/:id` (community)
- **Adım:** Mesaj (satır 66): Başvuru kaydedildi. ${r[
- **Adım:** Başlık (satır 83): Tadilat izinleri
- **Adım:** Başlık (satır 152): Tadilat izni
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-00`

#### Y-RENOVATIONS-01 · Düğme: Başvuru
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Başvuru" öğesine dokun (kaynak satırı 84); açılan pencere/formu gerçekçi değerlerle doldurup onayla
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
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-01`

#### Y-RENOVATIONS-02 · Düğme: ${p[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "${p[" öğesine dokun (kaynak satırı 91); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-02`

#### Y-RENOVATIONS-03 · Düğme: Rıza kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Rıza kaydet" öğesine dokun (kaynak satırı 187)
- **Beklenen (yazma):** `POST /renovations/:id/consents` (community, `services/community/renovation.go:161`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_consents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM renovation_consents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/consents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-03`

#### Y-RENOVATIONS-04 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Onayla" öğesine dokun (kaynak satırı 192)
- **Beklenen (yazma):** `POST /renovations/:id/approve` (community, `services/community/renovation.go:190`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `renovation.approved`, `renovation.neighbors` → alıcı: aynı bloktaki diğer dairelerin sakinleri (`BlockNeighbors`); işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.approved%' OR n.topic LIKE 'renovation.neighbors%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-04`

#### Y-RENOVATIONS-05 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Reddet" öğesine dokun (kaynak satırı 193)
- **Beklenen (yazma):** `POST /renovations/:id/reject` (community, `services/community/renovation.go:284`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `renovation.rejected` → alıcı: işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.rejected%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-05`

#### Y-RENOVATIONS-06 · Düğme: Denetle ve kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Denetle ve kapat" öğesine dokun (kaynak satırı 202)
- **Beklenen (yazma):** `POST /renovations/:id/complete` (community, `services/community/renovation.go:320`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/complete' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `renovation.completed` → alıcı: işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.completed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-06`

#### Y-RENOVATIONS-07 · Düğme: Çalışmayı durdur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/renovations
- **Adım:** "Çalışmayı durdur" öğesine dokun (kaynak satırı 214)
- **Beklenen (yazma):** `POST /renovations/:id/stop` (community, `services/community/renovation.go:302`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_permits` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM renovation_permits ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/stop' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `renovation.stopped` → alıcı: işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.stopped%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RENOVATIONS-07`

---

### reports_screen
- Dosya: `admin_app/lib/features/reports/presentation/screens/reports_screen.dart`

#### Y-REPORTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reports
- **Adım:** Ekranı aç: http://localhost:3003/#/reports — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/reports/debtors` (finance); `GET /finance/reports/debtors` (finance); `GET /finance/reports/collections` (finance); `GET /finance/reports/collections` (finance)
- **Adım:** Başlık (satır 29): Raporlar
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-REPORTS-00`

#### Y-REPORTS-01 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reports
- **Adım:** "PDF" öğesine dokun (kaynak satırı 37)
- **Beklenen (okuma):** `GET /finance/reports/debtors` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-REPORTS-01`

#### Y-REPORTS-02 · Düğme: Excel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reports
- **Adım:** "Excel" öğesine dokun (kaynak satırı 38)
- **Beklenen (okuma):** `GET /finance/reports/debtors` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-REPORTS-02`

#### Y-REPORTS-03 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reports
- **Adım:** "PDF" öğesine dokun (kaynak satırı 43)
- **Beklenen (okuma):** `GET /finance/reports/collections` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-REPORTS-03`

#### Y-REPORTS-04 · Düğme: Excel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reports
- **Adım:** "Excel" öğesine dokun (kaynak satırı 44)
- **Beklenen (okuma):** `GET /finance/reports/collections` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-REPORTS-04`

---

### request_detail_screen
- Dosya: `admin_app/lib/features/requests/presentation/screens/request_detail_screen.dart`

#### Y-REQUEST-DETAIL-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/requests/:id
- **Adım:** Ekranı aç: http://localhost:3003/#/requests/:id — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /requests` (community)
- **Adım:** Başlık (satır 40): Talep Detayı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-REQUEST-DETAIL-00`

#### Y-REQUEST-DETAIL-01 · Düğme: IN_PROGRESS / İşleme al / Çözüldü olarak işaretle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/requests/:id
- **Adım:** "IN_PROGRESS / İşleme al / Çözüldü olarak işaretle" öğesine dokun (kaynak satırı 69)
- **Beklenen (yazma):** `PATCH /requests/:id/status` (community, `services/community/main.go:85`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/requests/:id/status' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/requests`, Sakin `requests_screen`, Sakin `unit_residents_screen`, Yön.mobil `request_detail_screen`, Yön.mobil `requests_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-REQUEST-DETAIL-01`

---

### requests_screen
- Dosya: `admin_app/lib/features/requests/presentation/screens/requests_screen.dart`

#### Y-REQUESTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/requests
- **Adım:** Ekranı aç: http://localhost:3003/#/requests — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /requests` (community)
- **Adım:** Başlık (satır 91): Talepler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-REQUESTS-00`

#### Y-REQUESTS-01 · Düğme: simge düğmesi (satır 94)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/requests
- **Adım:** "simge düğmesi (satır 94)" öğesine dokun (kaynak satırı 94)
- **Beklenen (okuma):** `GET /requests` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-REQUESTS-01`

#### Y-REQUESTS-02 · Düğme: ${ticket.isEmpty ? 
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/requests
- **Adım:** "${ticket.isEmpty ? " öğesine dokun (kaynak satırı 159); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-REQUESTS-02`

---

### reservation_management_screen
- Dosya: `admin_app/lib/features/reservations/presentation/screens/reservation_management_screen.dart`

#### Y-RESERVATION-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** Ekranı aç: http://localhost:3003/#/reservations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /reservations` (reservation); `GET /facilities` (reservation)
- **Adım:** Başlık (satır 181): Rezervasyonlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Rezervasyonlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Tesisler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-00`

#### Y-RESERVATION-MANAGEMENT-01 · Düğme: Menü: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** "Menü: Onayla" öğesine dokun (kaynak satırı 240); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-01`

#### Y-RESERVATION-MANAGEMENT-02 · Düğme: Menü: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** "Menü: Reddet" öğesine dokun (kaynak satırı 243); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-02`

#### Y-RESERVATION-MANAGEMENT-03 · Düğme: Menü: İptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** "Menü: İptal et" öğesine dokun (kaynak satırı 245); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-03`

#### Y-RESERVATION-MANAGEMENT-04 · Düğme: Tesis ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** "Tesis ekle" öğesine dokun (kaynak satırı 264)
- **Beklenen (yazma):** `POST /facilities` (reservation, `services/reservation/main.go:280`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Beklenen (yazma):** `PATCH /facilities/:id` (reservation, `services/reservation/main.go:281`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-04`

#### Y-RESERVATION-MANAGEMENT-05 · Düğme: simge düğmesi (satır 296)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/reservations
- **Adım:** "simge düğmesi (satır 296)" öğesine dokun (kaynak satırı 296)
- **Beklenen (yazma):** `POST /facilities` (reservation, `services/reservation/main.go:280`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Beklenen (yazma):** `PATCH /facilities/:id` (reservation, `services/reservation/main.go:281`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESERVATION-MANAGEMENT-05`

---

### add_resident_screen
- Dosya: `admin_app/lib/features/residents/presentation/screens/add_resident_screen.dart`

#### Y-ADD-RESIDENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/add
- **Adım:** Ekranı aç: http://localhost:3003/#/residents/add — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Mesaj (satır 52): Birimler yüklenemedi, lütfen tekrar deneyin
- **Adım:** Başlık (satır 60): Yeni Sakin Ekle
- **Adım:** Alan (satır 70): Daire Seçin *
- **Adım:** Alan (satır 85): Ad *
- **Adım:** Alan (satır 92): Soyad *
- **Adım:** Alan (satır 99): Telefon *
- **Adım:** Alan (satır 99): +90 5XX XXX XX XX
- **Adım:** Alan (satır 107): E-posta
- **Adım:** Alan (satır 113): Oturum Tipi
- **Adım:** Pencere (satır 156): Davet gönderildi
- **Adım:** Mesaj (satır 178): Sakin eklenemedi: ${errorText(e)}
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-RESIDENT-00`

#### Y-ADD-RESIDENT-01 · Seçim: ${u[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/add
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-RESIDENT-01`

#### Y-ADD-RESIDENT-02 · Seçim: Oturum Tipi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/add
- **Adım:** "Oturum Tipi" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-RESIDENT-02`

#### Y-ADD-RESIDENT-03 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/add
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 122); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /residents` (identity, `services/identity/main.go:133`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.activation` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-RESIDENT-03`

#### Y-ADD-RESIDENT-04 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/add
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 159); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ADD-RESIDENT-04`

---

### resident_detail_screen
- Dosya: `admin_app/lib/features/residents/presentation/screens/resident_detail_screen.dart`

#### Y-RESIDENT-DETAIL-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** Ekranı aç: http://localhost:3003/#/residents/:id — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /residents/:id` (identity)
- **Adım:** Mesaj (satır 48): Sakin bilgileri yüklenemedi: ${errorText(e)}
- **Adım:** Mesaj (satır 63): Kod üretilemedi: ${errorText(e)}
- **Adım:** Mesaj (satır 111): İşlem gerçekleştirilemedi, lütfen tekrar deneyin
- **Adım:** Başlık (satır 130): Sakin Detayı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-00`

#### Y-RESIDENT-DETAIL-01 · Düğme: Menü: Etkinleştirme / şifre sıfırlama kodu üret
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** "Menü: Etkinleştirme / şifre sıfırlama kodu üret" öğesine dokun (kaynak satırı 146)
- **Beklenen (yazma):** `POST /residents/:id/activation-code` (identity, `services/identity/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id/activation-code' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.activation` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-01`

#### Y-RESIDENT-DETAIL-02 · Düğme: Menü: Telefon değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** "Menü: Telefon değiştir" öğesine dokun (kaynak satırı 147)
- **Beklenen (yazma):** `POST /residents/:id/phone` (identity, `services/identity/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id/phone' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.activation`, `identity.phone_changed` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' OR n.topic LIKE 'identity.phone_changed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-02`

#### Y-RESIDENT-DETAIL-03 · Düğme: Menü: Giriş kilidini aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** "Menü: Giriş kilidini aç" öğesine dokun (kaynak satırı 148)
- **Beklenen (yazma):** `POST /residents/:id/unlock` (identity, `services/identity/main.go:152`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id/unlock' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-03`

#### Y-RESIDENT-DETAIL-04 · Düğme: Menü: Sıfat / ayrılış
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** "Menü: Sıfat / ayrılış" öğesine dokun (kaynak satırı 149)
- **Beklenen (yazma):** `PATCH /residents/:id` (identity, `services/identity/main.go:147`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-04`

#### Y-RESIDENT-DETAIL-05 · Düğme: Menü: Pasifleştir / Aktifleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents/:id
- **Adım:** "Menü: Pasifleştir / Aktifleştir" öğesine dokun (kaynak satırı 150)
- **Beklenen (yazma):** `PATCH /residents/:id` (identity, `services/identity/main.go:147`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-DETAIL-05`

---

### resident_tools_screen
- Dosya: `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`

#### Y-RESIDENT-TOOLS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /units` (identity); `GET /residents/invitations` (identity); `GET /residents/tenancy-requests` (identity); `GET /residents/tenancy-requests/:id/documents/:docId` (identity)
- **Adım:** Mesaj (satır 60): ${r[
- **Adım:** Başlık (satır 108): ${data.where((d) => d[
- **Adım:** Başlık (satır 159): Davet ve kiracılık
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Davetler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Kiracılık bitişleri
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-00`

#### Y-RESIDENT-TOOLS-01 · Düğme: Toplu sakin ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Toplu sakin ekle" öğesine dokun (kaynak satırı 161); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /residents/bulk` (identity, `services/identity/main.go:134`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/bulk' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-01`

#### Y-RESIDENT-TOOLS-02 · Düğme: Davet et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Davet et" öğesine dokun (kaynak satırı 179); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /residents/invitations` (identity, `services/identity/main.go:136`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/invitations' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.invitation` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.invitation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-02`

#### Y-RESIDENT-TOOLS-03 · Düğme: Yönetim yolu başlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Yönetim yolu başlat" öğesine dokun (kaynak satırı 217); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /residents/tenancy-requests` (identity, `services/identity/main.go:140`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/documents` (identity, `services/identity/main.go:141`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/documents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-03`

#### Y-RESIDENT-TOOLS-04 · Düğme: ${_docKinds.firstWhere((k) => k.$1 == x[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "${_docKinds.firstWhere((k) => k.$1 == x[" öğesine dokun (kaynak satırı 234)
- **Beklenen (okuma):** `GET /residents/tenancy-requests/:id/documents/:docId` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-04`

#### Y-RESIDENT-TOOLS-05 · Düğme: Tamamla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Tamamla" öğesine dokun (kaynak satırı 246); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-05`

#### Y-RESIDENT-TOOLS-06 · Düğme: Yeni belge
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Yeni belge" öğesine dokun (kaynak satırı 254); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /residents/tenancy-requests` (identity, `services/identity/main.go:140`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/documents` (identity, `services/identity/main.go:141`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/documents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-06`

#### Y-RESIDENT-TOOLS-07 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "İptal" öğesine dokun (kaynak satırı 256)
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/cancel` (identity, `services/identity/main.go:143`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-07`

#### Y-RESIDENT-TOOLS-08 · Düğme: Geri al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`)
- **Adım:** "Geri al" öğesine dokun (kaynak satırı 263)
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/reverse` (identity, `services/identity/main.go:144`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/reverse' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENT-TOOLS-08`

---

### residents_screen
- Dosya: `admin_app/lib/features/residents/presentation/screens/residents_screen.dart`

#### Y-RESIDENTS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** Ekranı aç: http://localhost:3003/#/residents — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /residents` (identity)
- **Adım:** Mesaj (satır 48): Sakinler yüklenemedi, lütfen tekrar deneyin
- **Adım:** Başlık (satır 58): Sakinler
- **Adım:** Alan (satır 82): Sakin ara...
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-00`

#### Y-RESIDENTS-01 · Düğme: Davet, toplu ekleme, kiracılık bitişi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "Davet, toplu ekleme, kiracılık bitişi" öğesine dokun (kaynak satırı 61); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-01`

#### Y-RESIDENTS-02 · Düğme: simge düğmesi (satır 66)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "simge düğmesi (satır 66)" öğesine dokun (kaynak satırı 66); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (okuma):** `GET /residents` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-02`

#### Y-RESIDENTS-03 · Düğme: simge düğmesi (satır 85)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "simge düğmesi (satır 85)" öğesine dokun (kaynak satırı 85)
- **Beklenen (okuma):** `GET /residents` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-03`

#### Y-RESIDENTS-04 · Düğme: simge düğmesi (satır 127)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "simge düğmesi (satır 127)" öğesine dokun (kaynak satırı 127); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-04`

#### Y-RESIDENTS-05 · Düğme: Sakin Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "Sakin Ekle" öğesine dokun (kaynak satırı 137)
- **Beklenen (okuma):** `GET /residents` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-05`

#### Y-RESIDENTS-06 · Düğme: Uygula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "Uygula" öğesine dokun (kaynak satırı 174)
- **Beklenen (okuma):** `GET /residents` (identity) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-06`

#### Y-RESIDENTS-07 · Düğme: ${resident[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/residents
- **Adım:** "${resident[" öğesine dokun (kaynak satırı 231); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-RESIDENTS-07`

---

### activation_code_dialog
- Dosya: `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`

#### Y-ACTIVATION-CODE-DIALOG-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`)
- **Adım:** Ekranı aç: http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`) — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Pencere (satır 23): $who için kod:
- **Adım:** Mesaj (satır 45): Kod kopyalandı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATION-CODE-DIALOG-00`

#### Y-ACTIVATION-CODE-DIALOG-01 · Düğme: Kod kopyalandı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`)
- **Adım:** "Kod kopyalandı" öğesine dokun (kaynak satırı 39); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATION-CODE-DIALOG-01`

#### Y-ACTIVATION-CODE-DIALOG-02 · Düğme: Kodu ilettim, kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003 (başka bir ekrandan açılan bileşen/pencere; `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`)
- **Adım:** "Kodu ilettim, kapat" öğesine dokun (kaynak satırı 61); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ACTIVATION-CODE-DIALOG-02`

---

### roles_screen
- Dosya: `admin_app/lib/features/roles/presentation/screens/roles_screen.dart`

#### Y-ROLES-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/roles
- **Adım:** Ekranı aç: http://localhost:3003/#/roles — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /property-roles` (identity)
- **Adım:** Mesaj (satır 48): Bu görev için kurul kararı bilgisi zorunludur
- **Adım:** Başlık (satır 67): Görevlendirmeler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ROLES-00`

#### Y-ROLES-01 · Düğme: Görev ver
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/roles
- **Adım:** "Görev ver" öğesine dokun (kaynak satırı 68); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /property-roles` (identity, `services/identity/main.go:169`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `property_roles`, `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/property-roles' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-ROLES-01`

---

### sensors_screen
- Dosya: `admin_app/lib/features/sensors/presentation/screens/sensors_screen.dart`

#### Y-SENSORS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** Ekranı aç: http://localhost:3003/#/sensors — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /sensors/:id/data` (iot); `GET /iot/alerts` (iot); `GET /sensors` (iot)
- **Adım:** Pencere (satır 49): Cihaz anahtarı
- **Adım:** Başlık (satır 131): Sensörler
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Alarmlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Sensörler
- **Adım:** Alan (satır 246): Ad *
- **Adım:** Alan (satır 251): Tür *
- **Adım:** Alan (satır 255): Konum
- **Adım:** Alan (satır 257): Birim (°C, %, cm)
- **Adım:** Alan (satır 261): Alt eşik
- **Adım:** Alan (satır 266): Üst eşik
- **Adım:** Alan (satır 273): Sinyal kesilme süresi (dk) *
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-00`

#### Y-SENSORS-01 · Düğme: Kopyala
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Kopyala" öğesine dokun (kaynak satırı 59); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-01`

#### Y-SENSORS-02 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 63); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-02`

#### Y-SENSORS-03 · Düğme: Sensör ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Sensör ekle" öğesine dokun (kaynak satırı 136); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /sensors` (iot, `services/iot/sensors.go:303`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Beklenen (yazma):** `PATCH /sensors/:id` (iot, `services/iot/sensors.go:332`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-03`

#### Y-SENSORS-04 · Düğme: Menü: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Menü: Onayla" öğesine dokun (kaynak satırı 166)
- **Beklenen (yazma):** `POST /iot/alerts/:id/acknowledge` (iot, `services/iot/sensors.go:263`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensor_alerts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/iot/alerts/:id/acknowledge' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-04`

#### Y-SENSORS-05 · Düğme: Menü: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Menü: Kapat" öğesine dokun (kaynak satırı 167)
- **Beklenen (yazma):** `POST /iot/alerts/:id/close` (iot, `services/iot/sensors.go:277`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensor_alerts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/iot/alerts/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-05`

#### Y-SENSORS-06 · Düğme: Menü: Geçmiş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Menü: Geçmiş" öğesine dokun (kaynak satırı 199)
- **Beklenen (okuma):** `GET /sensors/:id/data` (iot) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-06`

#### Y-SENSORS-07 · Düğme: Menü: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Menü: Düzenle" öğesine dokun (kaynak satırı 200)
- **Beklenen (yazma):** `POST /sensors` (iot, `services/iot/sensors.go:303`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Beklenen (yazma):** `PATCH /sensors/:id` (iot, `services/iot/sensors.go:332`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-07`

#### Y-SENSORS-08 · Düğme: Menü: Anahtarı yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Menü: Anahtarı yenile" öğesine dokun (kaynak satırı 201)
- **Beklenen (yazma):** `POST /sensors/:id/rotate-key` (iot, `services/iot/sensors.go:360`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors/:id/rotate-key' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-08`

#### Y-SENSORS-09 · Seçim: Tür *
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Tür *" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-09`

#### Y-SENSORS-10 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/sensors
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 282); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SENSORS-10`

---

### api_settings_screen
- Dosya: `admin_app/lib/features/settings/presentation/screens/api_settings_screen.dart`

#### Y-API-SETTINGS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/api-settings
- **Adım:** Ekranı aç: http://localhost:3003/#/api-settings — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /integrations/status` (karşılığı yok)
- **Adım:** Başlık (satır 19): Entegrasyon Durumu
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-API-SETTINGS-00`

---

### site_settings_screen
- Dosya: `admin_app/lib/features/settings/presentation/screens/site_settings_screen.dart`

#### Y-SITE-SETTINGS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** Ekranı aç: http://localhost:3003/#/site-settings — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /settings-history` (settings); `GET /settings` (settings); `GET /settings/definitions` (settings); `GET /retention-rules` (settings); `GET /retention-rules/log` (settings); `GET /privacy/cameras` (settings); `GET /privacy/biometrics` (settings); `GET /property` (identity); `GET /settings/owner-visibility` (settings)
- **Adım:** Başlık (satır 52): Ayarlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Ayarlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Saklama ve imha
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Kamera ve biyometrik
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Geçmiş
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Site durumu
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Malik görünürlüğü
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-00`

#### Y-SITE-SETTINGS-01 · Düğme: Şimdi imha et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "Şimdi imha et" öğesine dokun (kaynak satırı 150)
- **Beklenen (yazma):** `POST /retention-rules/run` (settings, `services/settings/main.go:152`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `client_error_reports` — satır silinmiş olmalı: `SELECT xmin, * FROM client_error_reports ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `data_destruction_log` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM data_destruction_log ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `storage_deletion_queue` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM storage_deletion_queue ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `parking_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/retention-rules/run' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/parking`, Panel `/dashboard/settings`, Panel `/dashboard/visitors`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `parking_management_screen`, Yön.mobil `site_settings_screen`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-01`

#### Y-SITE-SETTINGS-02 · Düğme: simge düğmesi (satır 168)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "simge düğmesi (satır 168)" öğesine dokun (kaynak satırı 168)
- **Beklenen (yazma):** `PUT /retention-rules/:category` (settings, `services/settings/main.go:143`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `client_error_reports` — satır silinmiş olmalı: `SELECT xmin, * FROM client_error_reports ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `data_retention_rules` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM data_retention_rules ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `storage_deletion_queue` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM storage_deletion_queue ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `parking_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/retention-rules/:category' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/parking`, Panel `/dashboard/settings`, Panel `/dashboard/visitors`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `parking_management_screen`, Yön.mobil `site_settings_screen`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-02`

#### Y-SITE-SETTINGS-03 · Düğme: simge düğmesi (satır 236)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "simge düğmesi (satır 236)" öğesine dokun (kaynak satırı 236)
- **Beklenen (yazma):** `PUT /privacy/cameras/:id` (settings, `services/settings/main.go:150`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `camera_devices` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM camera_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/cameras/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `kvkk_requests_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /privacy/cameras` (settings, `services/settings/main.go:149`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `camera_devices` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM camera_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/cameras' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `kvkk_requests_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-03`

#### Y-SITE-SETTINGS-04 · Düğme: simge düğmesi (satır 246)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "simge düğmesi (satır 246)" öğesine dokun (kaynak satırı 246)
- **Beklenen (yazma):** `PUT /privacy/cameras/:id` (settings, `services/settings/main.go:150`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `camera_devices` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM camera_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/cameras/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `kvkk_requests_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /privacy/cameras` (settings, `services/settings/main.go:149`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `camera_devices` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM camera_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/cameras' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `kvkk_requests_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-04`

#### Y-SITE-SETTINGS-05 · Düğme: simge düğmesi (satır 254)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "simge düğmesi (satır 254)" öğesine dokun (kaynak satırı 254)
- **Beklenen (yazma):** `POST /privacy/biometrics` (settings, `services/settings/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `biometric_systems` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM biometric_systems ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/biometrics' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-05`

#### Y-SITE-SETTINGS-06 · Düğme: Siteyi pasife al / Siteyi yeniden etkinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "Siteyi pasife al / Siteyi yeniden etkinleştir" öğesine dokun (kaynak satırı 299)
- **Beklenen (yazma):** `POST /property/deactivate` (identity, `services/identity/main.go:160`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `property_lifecycle_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM property_lifecycle_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `properties` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/property/deactivate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /property/reactivate` (identity, `services/identity/main.go:161`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `property_lifecycle_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM property_lifecycle_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `properties` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/property/reactivate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-06`

#### Y-SITE-SETTINGS-07 · Düğme: Değişiklik öner
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "Değişiklik öner" öğesine dokun (kaynak satırı 351)
- **Beklenen (yazma):** `POST /settings/owner-visibility` (settings, `services/settings/main.go:145`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-07`

#### Y-SITE-SETTINGS-08 · Düğme: Not
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "Not" öğesine dokun (kaynak satırı 372); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /settings/owner-visibility/:id/approve` (settings, `services/settings/main.go:146`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visibility.policy` → alıcı: sitenin kiracıları (`Tenants`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visibility.policy%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: KİRACI → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /settings/owner-visibility/:id/reject` (settings, `services/settings/main.go:147`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visibility.policy` → alıcı: sitenin kiracıları (`Tenants`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visibility.policy%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: KİRACI → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-08`

#### Y-SITE-SETTINGS-09 · Düğme: Geri çek
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/site-settings
- **Adım:** "Geri çek" öğesine dokun (kaynak satırı 386)
- **Beklenen (yazma):** `POST /settings/owner-visibility/:id/cancel` (settings, `services/settings/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SITE-SETTINGS-09`

---

### survey_management_screen
- Dosya: `admin_app/lib/features/surveys/presentation/screens/survey_management_screen.dart`

#### Y-SURVEY-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** Ekranı aç: http://localhost:3003/#/surveys — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /surveys` (survey); `GET /surveys/:id` (survey); `GET /surveys/:id/comments` (survey)
- **Adım:** Başlık (satır 73): Anketler
- **Adım:** Başlık (satır 153): Anket yorumları
- **Adım:** Alan (satır 287): Tür
- **Adım:** Alan (satır 293): Başlık *
- **Adım:** Alan (satır 296): Açıklama
- **Adım:** Alan (satır 303): Seçenek ${i + 1} *
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-00`

#### Y-SURVEY-MANAGEMENT-01 · Düğme: Anket
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Anket" öğesine dokun (kaynak satırı 75); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-01`

#### Y-SURVEY-MANAGEMENT-02 · Düğme: ${s[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "${s[" öğesine dokun (kaynak satırı 96); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-02`

#### Y-SURVEY-MANAGEMENT-03 · Düğme: Yorumlar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Yorumlar" öğesine dokun (kaynak satırı 148)
- **Beklenen (okuma):** `GET /surveys/:id/comments` (survey) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-03`

#### Y-SURVEY-MANAGEMENT-04 · Düğme: İptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "İptal et" öğesine dokun (kaynak satırı 197); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /surveys/:id/cancel` (survey, `services/survey/main.go:218`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/close` (survey, `services/survey/main.go:209`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/publish` (survey, `services/survey/main.go:195`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/publish' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `survey.published` → alıcı: sitenin bütün aktif sakinleri (`Residents`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'survey.published%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-04`

#### Y-SURVEY-MANAGEMENT-05 · Düğme: Oylamayı bitir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Oylamayı bitir" öğesine dokun (kaynak satırı 205); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /surveys/:id/cancel` (survey, `services/survey/main.go:218`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/close` (survey, `services/survey/main.go:209`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/publish` (survey, `services/survey/main.go:195`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/publish' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `survey.published` → alıcı: sitenin bütün aktif sakinleri (`Residents`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'survey.published%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-05`

#### Y-SURVEY-MANAGEMENT-06 · Düğme: Yayınla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Yayınla" öğesine dokun (kaynak satırı 212); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /surveys/:id/cancel` (survey, `services/survey/main.go:218`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/close` (survey, `services/survey/main.go:209`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Beklenen (yazma):** `POST /surveys/:id/publish` (survey, `services/survey/main.go:195`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/publish' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `survey.published` → alıcı: sitenin bütün aktif sakinleri (`Residents`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'survey.published%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-06`

#### Y-SURVEY-MANAGEMENT-07 · Seçim: Tür
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Tür" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-07`

#### Y-SURVEY-MANAGEMENT-08 · Düğme: simge düğmesi (satır 308)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "simge düğmesi (satır 308)" öğesine dokun (kaynak satırı 308); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-08`

#### Y-SURVEY-MANAGEMENT-09 · Düğme: Seçenek ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Seçenek ekle" öğesine dokun (kaynak satırı 315); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-09`

#### Y-SURVEY-MANAGEMENT-10 · Düğme: Bitiş tarihi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Bitiş tarihi" öğesine dokun (kaynak satırı 335); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-10`

#### Y-SURVEY-MANAGEMENT-11 · Düğme: simge düğmesi (satır 339)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "simge düğmesi (satır 339)" öğesine dokun (kaynak satırı 339); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-11`

#### Y-SURVEY-MANAGEMENT-12 · Düğme: Taslak olarak kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/surveys
- **Adım:** "Taslak olarak kaydet" öğesine dokun (kaynak satırı 347)
- **Beklenen (yazma):** `POST /surveys` (survey, `services/survey/main.go:168`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `survey_options` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM survey_options ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `surveys` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-SURVEY-MANAGEMENT-12`

---

### units_screen
- Dosya: `admin_app/lib/features/units/presentation/screens/units_screen.dart`

#### Y-UNITS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/units
- **Adım:** Ekranı aç: http://localhost:3003/#/units — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /finance/clearance-certificates/:id/pdf` (finance); `GET /units` (identity)
- **Adım:** Mesaj (satır 131): Borcu yoktur belgesi üretildi (geçerlilik ${formatDate(r[
- **Adım:** Başlık (satır 141): Bağımsız bölümler
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-UNITS-00`

#### Y-UNITS-01 · Düğme: Toplu ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/units
- **Adım:** "Toplu ekle" öğesine dokun (kaynak satırı 142); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /units` (identity, `services/identity/main.go:178`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-UNITS-01`

#### Y-UNITS-02 · Düğme: Bölüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/units
- **Adım:** "Bölüm" öğesine dokun (kaynak satırı 144)
- **Beklenen (yazma):** `POST /units` (identity, `services/identity/main.go:178`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Beklenen (yazma):** `PATCH /units/:id` (identity, `services/identity/main.go:179`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `Y-UNITS-02`

---

### violations_screen
- Dosya: `admin_app/lib/features/violations/presentation/screens/violations_screen.dart`

#### Y-VIOLATIONS-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** Ekranı aç: http://localhost:3003/#/violations — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /site-rules` (community); `GET /violations` (community); `GET /violations/:id` (community)
- **Adım:** Başlık (satır 80): Kural ihlalleri
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İhlaller
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Kural kataloğu
- **Adım:** Başlık (satır 181): İhlal kaydı
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-00`

#### Y-VIOLATIONS-01 · Düğme: İhlal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "İhlal" öğesine dokun (kaynak satırı 81); açılan pencere/formu gerçekçi değerlerle doldurup onayla
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
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-01`

#### Y-VIOLATIONS-02 · Düğme: ${v[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "${v[" öğesine dokun (kaynak satırı 95); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-02`

#### Y-VIOLATIONS-03 · Düğme: Kural ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "Kural ekle" öğesine dokun (kaynak satırı 114)
- **Beklenen (yazma):** `POST /site-rules` (community, `services/community/violation.go:66`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `site_rules` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM site_rules ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/site-rules' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-03`

#### Y-VIOLATIONS-04 · Düğme: Doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "Doğrula" öğesine dokun (kaynak satırı 201)
- **Beklenen (yazma):** `POST /violations/:id/verify` (community, `services/community/violation.go:210`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/verify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-04`

#### Y-VIOLATIONS-05 · Düğme: Doğrulanmadı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "Doğrulanmadı" öğesine dokun (kaynak satırı 207)
- **Beklenen (yazma):** `POST /violations/:id/escalate` (community, `services/community/violation.go:240`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/escalate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.{{{strings}.ToLower}(…)}` → alıcı: ilgili dairenin aktif sakinleri (`UnitResidents`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/resolve` (community, `services/community/violation.go:285`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/resolve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/dismiss` (community, `services/community/violation.go:221`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/dismiss' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.dismissed` → alıcı: işlemin muhatabı (v.ReportedBy) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.dismissed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-05`

#### Y-VIOLATIONS-06 · Düğme: simge düğmesi (satır 212)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "simge düğmesi (satır 212)" öğesine dokun (kaynak satırı 212)
- **Beklenen (yazma):** `POST /violations/:id/escalate` (community, `services/community/violation.go:240`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/escalate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.{{{strings}.ToLower}(…)}` → alıcı: ilgili dairenin aktif sakinleri (`UnitResidents`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/resolve` (community, `services/community/violation.go:285`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/resolve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/dismiss` (community, `services/community/violation.go:221`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/dismiss' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.dismissed` → alıcı: işlemin muhatabı (v.ReportedBy) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.dismissed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-06`

#### Y-VIOLATIONS-07 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "Kapat" öğesine dokun (kaynak satırı 218)
- **Beklenen (yazma):** `POST /violations/:id/escalate` (community, `services/community/violation.go:240`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/escalate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.{{{strings}.ToLower}(…)}` → alıcı: ilgili dairenin aktif sakinleri (`UnitResidents`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/resolve` (community, `services/community/violation.go:285`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/resolve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/dismiss` (community, `services/community/violation.go:221`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/dismiss' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.dismissed` → alıcı: işlemin muhatabı (v.ReportedBy) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.dismissed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-07`

#### Y-VIOLATIONS-08 · Düğme: Doğrulanmadı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/violations
- **Adım:** "Doğrulanmadı" öğesine dokun (kaynak satırı 219)
- **Beklenen (yazma):** `POST /violations/:id/escalate` (community, `services/community/violation.go:240`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/escalate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.{{{strings}.ToLower}(…)}` → alıcı: ilgili dairenin aktif sakinleri (`UnitResidents`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/resolve` (community, `services/community/violation.go:285`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/resolve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Beklenen (yazma):** `POST /violations/:id/dismiss` (community, `services/community/violation.go:221`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/dismiss' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `violation.dismissed` → alıcı: işlemin muhatabı (v.ReportedBy) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.dismissed%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VIOLATIONS-08`

---

### visitor_management_screen
- Dosya: `admin_app/lib/features/visitors/presentation/screens/visitor_management_screen.dart`

#### Y-VISITOR-MANAGEMENT-00 · Ekran açılışı ve görünüm
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** Ekranı aç: http://localhost:3003/#/visitors — yükleme göstergesi sonra içerik ya da boş durum mesajı; kırmızı hata/çökme olmamalı
- **Adım:** Veri yüklenir: `GET /visitors` (visitor); `GET /visitors/summary` (visitor); `GET /units` (identity)
- **Adım:** Pencere (satır 61): ${v[
- **Adım:** Başlık (satır 79): Ziyaretçiler
- **Adım:** Pencere (satır 165): Geçiş koduyla giriş
- **Adım:** Alan (satır 171): 6 haneli PIN ya da QR kodu
- **Adım:** Pencere (satır 204): Ziyaretçi kaydı
- **Adım:** Alan (satır 210): Ad soyad
- **Adım:** Alan (satır 214): Daire
- **Adım:** Alan (satır 222): Telefon
- **Adım:** Alan (satır 223): Plaka
- **Adım:** Alan (satır 224): Ziyaret nedeni
- **Adım:** Aşağı çekerek yenile (varsa) ya da ekrana yeniden gir: aynı veri gelir
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-00`

#### Y-VISITOR-MANAGEMENT-01 · Düğme: Tamam
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Tamam" öğesine dokun (kaynak satırı 68); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-01`

#### Y-VISITOR-MANAGEMENT-02 · Düğme: Geçiş koduyla giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Geçiş koduyla giriş" öğesine dokun (kaynak satırı 80); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /visitors/verify-pass` (visitor, `services/visitor/main.go:174`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/verify-pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visitor.checkin` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-02`

#### Y-VISITOR-MANAGEMENT-03 · Düğme: Kayıt
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Kayıt" öğesine dokun (kaynak satırı 87); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen (yazma):** `POST /visitors` (visitor, `services/visitor/main.go:100`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-03`

#### Y-VISITOR-MANAGEMENT-04 · Düğme: Menü: Giriş yaptı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Menü: Giriş yaptı" öğesine dokun (kaynak satırı 144)
- **Beklenen (yazma):** `POST /visitors/:id/check-in` (visitor, `services/visitor/main.go:175`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-in' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visitor.checkin` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/check-out` (visitor, `services/visitor/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-out' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-04`

#### Y-VISITOR-MANAGEMENT-05 · Düğme: Menü: Çıkış yaptı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Menü: Çıkış yaptı" öğesine dokun (kaynak satırı 145)
- **Beklenen (yazma):** `POST /visitors/:id/check-in` (visitor, `services/visitor/main.go:175`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-in' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visitor.checkin` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/check-out` (visitor, `services/visitor/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-out' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-05`

#### Y-VISITOR-MANAGEMENT-06 · Düğme: Menü: Kodu yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Menü: Kodu yenile" öğesine dokun (kaynak satırı 146)
- **Beklenen (yazma):** `POST /visitors/:id/check-in` (visitor, `services/visitor/main.go:175`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-in' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visitor.checkin` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/check-out` (visitor, `services/visitor/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-out' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-06`

#### Y-VISITOR-MANAGEMENT-07 · Düğme: Menü: İptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Menü: İptal et" öğesine dokun (kaynak satırı 147)
- **Beklenen (yazma):** `POST /visitors/:id/check-in` (visitor, `services/visitor/main.go:175`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-in' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `visitor.checkin` → alıcı: ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/check-out` (visitor, `services/visitor/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-out' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-07`

#### Y-VISITOR-MANAGEMENT-08 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 174); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-08`

#### Y-VISITOR-MANAGEMENT-09 · Düğme: Doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Doğrula" öğesine dokun (kaynak satırı 175); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-09`

#### Y-VISITOR-MANAGEMENT-10 · Seçim: ${u[
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "${u[" seçimini değiştir; her seçenekte içerik buna göre değişmeli
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-10`

#### Y-VISITOR-MANAGEMENT-11 · Düğme: Vazgeç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Vazgeç" öğesine dokun (kaynak satırı 229); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-11`

#### Y-VISITOR-MANAGEMENT-12 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3003/#/visitors
- **Adım:** "Kaydet" öğesine dokun (kaynak satırı 230); açılan pencere/formu gerçekçi değerlerle doldurup onayla
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `Y-VISITOR-MANAGEMENT-12`

---
