# 3.8 Panel — Kenar çubuğu altı

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Ayarlar — `/dashboard/settings`
- Dosya: `admin/src/app/(dashboard)/dashboard/settings/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — Site ayarları

#### P-SETTINGS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** http://localhost:3001/dashboard/settings adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Veri yüklenir: `GET /settings/definitions` (settings)
- **Adım:** Veri yüklenir: `GET /settings-history` (settings)
- **Adım:** Bilgi notu (satır 32): Mevzuata bağlı değerler (gecikme tazminatı, ısıtma payları, genel kurul nisapları) burada 
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Ayarlar, Saklama ve imha (KVKK), Kamera ve biyometrik envanter, Değişiklik geçmişi, Site durumu, Malik görünürlüğü
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ayar \| Değer \| Son değişiklik
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Ayar \| Eski \| Yeni \| Değiştiren
- **Adım:** Veri yüklenir: `GET /retention-rules` (settings)
- **Adım:** Veri yüklenir: `GET /retention-rules/log` (settings)
- **Adım:** Kart (satır 25): Kişisel veri saklama süreleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kategori \| Saklama \| Gerekçe \| Son imha
- **Adım:** Kart (satır 42): İmha kaydı
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Kategori \| Yöntem \| Kesim \| Kayıt \| Yapan
- **Adım:** Veri yüklenir: `GET /privacy/cameras` (settings)
- **Adım:** Veri yüklenir: `GET /privacy/biometrics` (settings)
- **Adım:** Kart (satır 34): Kamera envanteri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Konum \| Amaç \| Saklama \| Uygunluk
- **Adım:** Kart (satır 53): Biyometrik sistemler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Sistem \| Yöntem \| Amaç \| Alternatif
- **Adım:** Bilgi notu (satır 78): Bağımsız bölüm içini/kapı önünü, tuvalet, soyunma ve ibadet yerlerini gören kamera konulam
- **Adım:** Bilgi notu (satır 101): Biyometrik veri özel nitelikli kişisel veridir: kullanıcının açık rızası gerekir ve rıza v
- **Adım:** Veri yüklenir: `GET /property` (identity)
- **Adım:** Kart (satır 23): Site durumu
- **Adım:** Bilgi notu (satır 31): Yönetim hizmeti sonlandırıldığında siteyi pasife alın
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| İşlem \| Gerekçe
- **Adım:** Veri yüklenir: `GET /settings/owner-visibility` (settings)
- **Adım:** Kart (satır 34): Malikin kiracılı dairede gördükleri
- **Adım:** Bilgi notu (satır 49): Her zaman görür: {d.always_visible.join(" · ")}
- **Adım:** Bilgi notu (satır 50): Hiçbir zaman görmez: {d.never_visible.join(" · ")}
- **Adım:** Kart (satır 55): Onay bekleyen öneri
- **Adım:** Kart (satır 75): Geçmiş
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Öneri \| Açılan alanlar \| Gerekçe \| Durum \| Karar
- **Adım:** Bilgi notu (satır 94): Seçenekleri açmak kiracının kişisel verisini malike gösterir (KVKK m.4 ölçülülük). Değişik
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-00`

#### P-SETTINGS-01 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-01`

#### P-SETTINGS-02 · Düğme: Sıfırla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Sıfırla" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /settings/:key` (settings, `services/settings/main.go:126`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `property_setting_history_no_change`, `property_settings_guard_legal_key` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `property_setting_history` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM property_setting_history ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `property_settings` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/:key' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-02`

#### P-SETTINGS-03 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Değer (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ayar kaydedildi"
- **Beklenen (yazma):** `PUT /settings/:key` (settings, `services/settings/main.go:105`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74)
  - Veritabanı tetikleyicileri çalışır: `property_setting_history_no_change`, `property_settings_guard_legal_key` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `property_setting_history` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM property_setting_history ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `property_settings` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/:key' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-03`

#### P-SETTINGS-04 · Düğme: Şimdi imha et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Şimdi imha et" düğme öğesine bas
- **Adım:** Öğe `retention-card` bileşenindedir (satır 26)
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
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-04`

#### P-SETTINGS-05 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Düzenle" düğme öğesine bas
- **Adım:** Öğe `retention-card` bileşenindedir (satır 35)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-05`

#### P-SETTINGS-06 · Form: Saklama süresi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Saklama süresi (ay)*, Gerekçe (işleme amacı / hukuki dayanak)* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kaydedildi"
- **Adım:** Öğe `retention-card` bileşenindedir (satır 56)
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
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-06`

#### P-SETTINGS-07 · Düğme: Kamera ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Kamera ekle" düğme öğesine bas
- **Adım:** Öğe `privacy-card` bileşenindedir (satır 34)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-07`

#### P-SETTINGS-08 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Düzenle" düğme öğesine bas
- **Adım:** Öğe `privacy-card` bileşenindedir (satır 42)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-08`

#### P-SETTINGS-09 · Düğme: Sistem ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Sistem ekle" düğme öğesine bas
- **Adım:** Öğe `privacy-card` bileşenindedir (satır 53)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-09`

#### P-SETTINGS-10 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Konum*, Alan türü, Saklama (gün)*, Genel kurul kararı, Amaç*, Kayıtlara kimler erişir, Somut gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kamera kaydı güncellendi"
- **Adım:** Öğe `privacy-card` bileşenindedir (satır 65)
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
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-10`

#### P-SETTINGS-11 · Form: Biyometrik sistem
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Sistem adı*, Yöntem, Amaç*, Alternatif yöntem*, Saklama notu (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kaydedildi"
- **Adım:** Öğe `privacy-card` bileşenindedir (satır 94)
- **Beklenen (yazma):** `POST /privacy/biometrics` (settings, `services/settings/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `biometric_systems` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM biometric_systems ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/privacy/biometrics' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-11`

#### P-SETTINGS-12 · Düğme: Siteyi pasife al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Siteyi pasife al" düğme öğesine bas
- **Adım:** Öğe `lifecycle-card` bileşenindedir (satır 37)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-12`

#### P-SETTINGS-13 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `lifecycle-card` bileşenindedir (satır 52)
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
- **Yetki (olumsuz):** KURUL ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /property/deactivate` yalnız MANAGER). KURUL ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /property/reactivate` yalnız MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-13`

#### P-SETTINGS-14 · Düğme: Değişiklik öner
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Değişiklik öner" düğme öğesine bas
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 35)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-14`

#### P-SETTINGS-15 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Onayla" düğme öğesine bas
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 61)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-15`

#### P-SETTINGS-16 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Reddet" düğme öğesine bas
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 62)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-16`

#### P-SETTINGS-17 · Düğme: Geri çek
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** "Geri çek" düğme öğesine bas
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 66)
- **Beklenen (okuma):** `GET /settings` (settings) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (yazma):** `POST /settings/owner-visibility/:id/cancel` (settings, `services/settings/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-17`

#### P-SETTINGS-18 · Form: Görünürlük değişikliği öner
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 86)
- **Beklenen (yazma):** `POST /settings/owner-visibility` (settings, `services/settings/main.go:145`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `trg_owner_visibility_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `owner_visibility_policies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM owner_visibility_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/settings/owner-visibility' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Sakin `owner_visibility_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-18`

#### P-SETTINGS-19 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/settings
- **Adım:** Formu aç; alanlar: Not (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `visibility-card` bileşenindedir (satır 108)
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
- **Sonuç:** http://localhost:18000/sonuc → `P-SETTINGS-19`

---
