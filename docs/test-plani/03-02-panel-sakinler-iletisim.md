# 3.2 Panel — Sakinler ve İletişim

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Duyurular — `/dashboard/announcements`
- Dosya: `admin/src/app/(dashboard)/dashboard/announcements/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Duyuru yönetimi

#### P-ANNOUNCEMENTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/announcements
- **Adım:** http://localhost:3001/dashboard/announcements adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /announcements` (community)
- **Adım:** Veri yüklenir: `GET /announcements/:id/read-stats` (community)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başlık \| Kategori \| Öncelik \| Yayım \| Okunma
- **Adım:** Bilgi notu (satır 109): Genel kurul çağrısı KMK m.29 gereği imza karşılığı ya da taahhütlü mektupla yapılır. Bu du
- **Adım:** Pencere (satır 115): Okunma istatistiği
- **Adım:** Bilgi notu (satır 120): {s.note}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ANNOUNCEMENTS-00`

#### P-ANNOUNCEMENTS-01 · Düğme: Duyuru yayımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/announcements
- **Adım:** "Duyuru yayımla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ANNOUNCEMENTS-01`

#### P-ANNOUNCEMENTS-02 · Düğme: İstatistik
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/announcements
- **Adım:** "İstatistik" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ANNOUNCEMENTS-02`

#### P-ANNOUNCEMENTS-03 · Düğme: Sabitlemeyi kaldır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/announcements
- **Adım:** "Sabitlemeyi kaldır" düğme öğesine bas
- **Beklenen (yazma):** `POST /announcements/:id/pin` (community, `services/community/main.go:173`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `announcements` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM announcements ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/announcements/:id/pin' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/announcements`, Sakin `announcements_screen`, Sakin `resident_home_screen`, Yön.mobil `announcements_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /announcements/:id/pin` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ANNOUNCEMENTS-03`

#### P-ANNOUNCEMENTS-04 · Form: Duyuru yayımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/announcements
- **Adım:** Formu aç; alanlar: Başlık*, İçerik*, Kategori, Öncelik, Yayından kalkış, Sabitle (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /announcements` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ANNOUNCEMENTS-04`

---

### İlan Panosu — `/dashboard/bulletins`
- Dosya: `admin/src/app/(dashboard)/dashboard/bulletins/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — İlan panosu onayı

#### P-BULLETINS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** http://localhost:3001/dashboard/bulletins adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /bulletins` (bulletin)
- **Adım:** Veri yüklenir: `GET /bulletins-summary` (bulletin)
- **Adım:** Veri yüklenir: `GET /bulletins/:id/comments` (bulletin)
- **Adım:** Kart (satır 38): İlanlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: İlan \| Kategori \| Fiyat \| Sahibi \| Tarih \| Durum
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Yazan \| Yorum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-00`

#### P-BULLETINS-01 · Düğme: Süresi dolanları işle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Süresi dolanları işle" düğme öğesine bas
- **Beklenen (yazma):** `POST /bulletins/expire-due` (bulletin, `services/bulletin/main.go:205`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/expire-due' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-01`

#### P-BULLETINS-02 · Düğme: Yorumlar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Yorumlar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-02`

#### P-BULLETINS-03 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen (yazma):** `POST /bulletins/:id/approve` (bulletin, `services/bulletin/main.go:170`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `bulletin.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-03`

#### P-BULLETINS-04 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-04`

#### P-BULLETINS-05 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen (yazma):** `POST /bulletins/:id/close` (bulletin, `services/bulletin/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-05`

#### P-BULLETINS-06 · Form: İlanı reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İlan reddedildi; gerekçe sahibine gösterilir"
- **Beklenen (yazma):** `POST /bulletins/:id/reject` (bulletin, `services/bulletin/main.go:183`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_posts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_posts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletins/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `bulletin.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-06`

#### P-BULLETINS-07 · Düğme: Gizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/bulletins
- **Adım:** "Gizle" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /bulletin-comments/:id` (bulletin, `services/bulletin/main.go:154`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bulletin_comments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bulletin_comments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/bulletin-comments/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/bulletins`, Sakin `bulletin_board_mobile_screen`, Yön.mobil `bulletin_board_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-BULLETINS-07`

---

### Acil Durum — `/dashboard/emergency`
- Dosya: `admin/src/app/(dashboard)/dashboard/emergency/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Acil durum planı ve sakin acil bilgi kartları (özel nitelikli veri)

#### P-EMERGENCY-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** http://localhost:3001/dashboard/emergency adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /emergency/info` (community)
- **Adım:** Veri yüklenir: `GET /emergency/drills` (community)
- **Adım:** Veri yüklenir: `GET /emergency/checks` (community)
- **Adım:** Bilgi notu (satır 42): Her türlü acil durumda 112 aranır. Bu sayfadaki bilgi kartı sakin uygulamasında çevrimdışı
- **Adım:** Kart (satır 44): Durum bildirimi (afet sonrası)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Çağrı \| Tür \| Açılış \| Durum \| Yanıt \| Yardım
- **Adım:** Kart (satır 61): Toplanma alanı ve kritik altyapı
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Ad \| Konum
- **Adım:** Kart (satır 75): Acil iletişim
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kategori \| Ad \| Telefon
- **Adım:** Kart (satır 91): Tatbikatlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tür \| Katılım \| Görülen eksiklikler \| Düzeltici faaliyet
- **Adım:** Kart (satır 107): Sakin acil bilgi kartları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Sakin \| Yardım ihtiyacı \| Hane \| Yakını
- **Adım:** Bilgi notu (satır 166): Bütün sakinlere &ldquo;Güvendeyim / Yardım gerekiyor&rdquo; yanıtı istenen bildirim gider.
- **Adım:** Veri yüklenir: `GET /emergency/checks/:id/responses` (community)
- **Adım:** Pencere (satır 180): Durum yanıtları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Durum \| Daire \| Sakin \| Not \| Zaman
- **Adım:** Bilgi notu (satır 198): Henüz yanıt vermeyen daireler: {d.silent_units.join(", ")}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-00`

#### P-EMERGENCY-01 · Düğme: Çağrı başlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Çağrı başlat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-01`

#### P-EMERGENCY-02 · Düğme: Yanıtlar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Yanıtlar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-02`

#### P-EMERGENCY-03 · Düğme: Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-03`

#### P-EMERGENCY-04 · Düğme: Sil
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Sil" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /emergency/points/:id` (community, `services/community/emergency.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/points/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`DELETE /emergency/points/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-04`

#### P-EMERGENCY-05 · Düğme: Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-05`

#### P-EMERGENCY-06 · Düğme: Sil
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Sil" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /emergency/contacts/:id` (community, `services/community/emergency.go:117`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/contacts/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`DELETE /emergency/contacts/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-06`

#### P-EMERGENCY-07 · Düğme: Tatbikat kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Tatbikat kaydet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-07`

#### P-EMERGENCY-08 · Düğme: Kartları görüntüle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Kartları görüntüle" düğme öğesine bas
- **Beklenen (okuma):** `GET /emergency/cards` (community) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-08`

#### P-EMERGENCY-09 · Form: Nokta ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** Formu aç; alanlar: Tür, Ad*, Konum*, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Eklendi"
- **Beklenen (yazma):** `POST /emergency/points` (community, `services/community/emergency.go:72`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `emergency_points` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM emergency_points ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/points' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /emergency/points` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-09`

#### P-EMERGENCY-10 · Form: Acil iletişim ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** Formu aç; alanlar: Kategori, Ad*, Telefon*, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Eklendi"
- **Beklenen (yazma):** `POST /emergency/contacts` (community, `services/community/emergency.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `emergency_contacts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM emergency_contacts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/contacts' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /emergency/contacts` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-10`

#### P-EMERGENCY-11 · Form: Tatbikat raporu
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** Formu aç; alanlar: Tür, Tarih*, Katılımcı sayısı, Görülen eksiklikler*, Düzeltici ve önleyici faaliyetler (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Tatbikat kaydedildi"
- **Beklenen (yazma):** `POST /emergency/drills` (community, `services/community/emergency.go:134`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `emergency_drills` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM emergency_drills ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/drills' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /emergency/drills` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-11`

#### P-EMERGENCY-12 · Form: Durum bildirimi çağrısı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** Formu aç; alanlar: Tür, Başlık* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /emergency/checks` (community, `services/community/emergency.go:286`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `safety_checks` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM safety_checks ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/checks' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `safety.check` → alıcı: sitenin bütün aktif sakinleri (`Residents`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'safety.check%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /emergency/checks` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-12`

#### P-EMERGENCY-13 · Düğme: Çağrıyı kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/emergency
- **Adım:** "Çağrıyı kapat" düğme öğesine bas
- **Beklenen (yazma):** `POST /emergency/checks/:id/close` (community, `services/community/emergency.go:383`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `safety_checks` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM safety_checks ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/emergency/checks/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/emergency`, Sakin `emergency_screen`, Yön.mobil `emergency_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /emergency/checks/:id/close` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EMERGENCY-13`

---

### Sigorta (DASK) — `/dashboard/insurance`
- Dosya: `admin/src/app/(dashboard)/dashboard/insurance/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — DASK poliçeleri ve hasar kayıtları

#### P-INSURANCE-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** http://localhost:3001/dashboard/insurance adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /insurance/dask` (contract)
- **Adım:** Veri yüklenir: `GET /insurance/claims` (contract)
- **Adım:** Kart (satır 39): Bağımsız bölüm DASK poliçeleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Poliçe \| Bitiş \| Durum
- **Adım:** Kart (satır 55): Hasar / tazminat kayıtları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Olay \| Açıklama \| Talep \| Durum \| Ödenen
- **Adım:** Bilgi notu (satır 111): Sigortacının ret gerekçesini yazın.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-00`

#### P-INSURANCE-01 · Düğme: Poliçe gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** "Poliçe gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-01`

#### P-INSURANCE-02 · Düğme: Hasar kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** "Hasar kaydet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-02`

#### P-INSURANCE-03 · Düğme: İlerlet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** "İlerlet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-03`

#### P-INSURANCE-04 · Form: DASK poliçesi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** Formu aç; alanlar: Poliçe no*, Sigorta şirketi, Başlangıç*, Bitiş* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Poliçe kaydedildi"
- **Beklenen (yazma):** `POST /insurance/dask` (contract, `services/contract/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `unit_insurance_policies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM unit_insurance_policies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/dask' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Sakin `dask_screen`, Yön.mobil `insurance_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-04`

#### P-INSURANCE-05 · Form: Hasar kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** Formu aç; alanlar: Olay tarihi*, Talep edilen (TL), Sigortacı dosya no, Açıklama* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Hasar kaydedildi"
- **Beklenen (yazma):** `POST /insurance/claims` (contract, `services/contract/main.go:114`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `insurance_claims` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM insurance_claims ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/claims' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Yön.mobil `insurance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /insurance/claims` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-05`

#### P-INSURANCE-06 · Form: Hasar durumunu ilerlet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/insurance
- **Adım:** Formu aç; alanlar: Yeni durum, Ödenen tazminat (TL)*, Ödeme tarihi*, Not* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Güncellendi"
- **Beklenen (yazma):** `POST /insurance/claims/:id/status` (contract, `services/contract/main.go:115`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `insurance_claims` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM insurance_claims ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/insurance/claims/:id/status' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/insurance`, Yön.mobil `insurance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /insurance/claims/:id/status` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INSURANCE-06`

---

### KVKK Başvuruları — `/dashboard/kvkk`
- Dosya: `admin/src/app/(dashboard)/dashboard/kvkk/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — KVKK ilgili kişi başvuruları (kişisel veri)

#### P-KVKK-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/kvkk
- **Adım:** http://localhost:3001/dashboard/kvkk adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /kvkk-requests` (community)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başvuran \| Tür \| Talep \| Başvuru \| Son gün \| Durum
- **Adım:** Bilgi notu (satır 75): {answer.r.applicant_name} — {TYPE_LABEL[answer.r.request_ty}: {answer.r.description}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-KVKK-00`

#### P-KVKK-01 · Düğme: Yanıtla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/kvkk
- **Adım:** "Yanıtla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-KVKK-01`

#### P-KVKK-02 · Form: Başvuruyu sonuçlandır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/kvkk
- **Adım:** Formu aç; alanlar: Sonuç, Yanıt* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Başvuru sonuçlandırıldı; başvurana bildirildi"
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /kvkk-requests/:id/respond` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-KVKK-02`

---

### Toplu Bildirim — `/dashboard/notifications`
- Dosya: `admin/src/app/(dashboard)/dashboard/notifications/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — Toplu bildirim gönderimi

#### P-NOTIFICATIONS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/notifications
- **Adım:** http://localhost:3001/dashboard/notifications adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /notifications/outbox` (notification)
- **Adım:** Veri yüklenir: `GET /notifications/summary` (notification)
- **Adım:** Veri yüklenir: `GET /notification-preferences` (notification)
- **Adım:** Veri yüklenir: `GET /residents` (identity)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Giden kutusu, Kendi tercihlerim
- **Adım:** Kart (satır 49): Kuyruk
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Alıcı \| Kanal \| Konu \| Durum
- **Adım:** Kart (satır 69): Kanal tercihlerim
- **Adım:** Bilgi notu (satır 73): {d.note}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kanal \| Tür \| Durum \| Onay
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-NOTIFICATIONS-00`

#### P-NOTIFICATIONS-01 · Düğme: Bildirim gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/notifications
- **Adım:** "Bildirim gönder" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-NOTIFICATIONS-01`

#### P-NOTIFICATIONS-02 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/notifications
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen (yazma):** `PUT /notification-preferences` (notification, `services/notification/main.go:124`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_preferences` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_preferences ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notification-preferences' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/notifications`, Sakin `profile_settings_screen`, Yön.mobil `notification_center_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-NOTIFICATIONS-02`

#### P-NOTIFICATIONS-03 · Form: Bildirim gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/notifications
- **Adım:** Formu aç; alanlar: Alıcı*, Kanal, Tür, Konu, İleti* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /notifications` (notification, `services/notification/main.go:158`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{{in}.Topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Sonuç:** http://localhost:18000/sonuc → `P-NOTIFICATIONS-03`

---

### Tadilat İzinleri — `/dashboard/renovations`
- Dosya: `admin/src/app/(dashboard)/dashboard/renovations/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Tadilat izinleri ve kat maliki rızaları

#### P-RENOVATIONS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** http://localhost:3001/dashboard/renovations adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /renovations` (community)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Kapsam \| Başvuran \| Tarih \| Durum \| Teminat
- **Adım:** Bilgi notu (satır 76): {SCOPE.find((s) => s.value === }
- **Adım:** Veri yüklenir: `GET /renovations/:id` (community)
- **Adım:** Veri yüklenir: `GET /residents` (identity)
- **Adım:** Pencere (satır 96): Tadilat izni
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kat maliki \| Belge tarihi \| Belge
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-00`

#### P-RENOVATIONS-01 · Düğme: Başvuru gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Başvuru gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-01`

#### P-RENOVATIONS-02 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-02`

#### P-RENOVATIONS-03 · Form: Tadilat başvurusu
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** Formu aç; alanlar: Daire*, Kapsam*, Başlangıç*, Bitiş*, Müteahhit / usta, Müteahhit telefonu, Yapılacak iş* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-03`

#### P-RENOVATIONS-04 · Düğme: Rızayı kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Rızayı kaydet" düğme öğesine bas
- **Beklenen (yazma):** `POST /renovations/:id/consents` (community, `services/community/renovation.go:161`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `renovation_consents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM renovation_consents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/renovations/:id/consents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /renovations/:id/consents` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-04`

#### P-RENOVATIONS-05 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Onayla" düğme öğesine bas
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /renovations/:id/approve` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-05`

#### P-RENOVATIONS-06 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-06`

#### P-RENOVATIONS-07 · Düğme: Denetle ve kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Denetle ve kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-07`

#### P-RENOVATIONS-08 · Düğme: Çalışmayı durdur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** "Çalışmayı durdur" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-08`

#### P-RENOVATIONS-09 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kaydedildi; başvurana bildirildi"
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /renovations/:id/stop` yalnız BOARD_MEMBER/MANAGER). DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /renovations/:id/reject` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-09`

#### P-RENOVATIONS-10 · Form: Denetle ve kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/renovations
- **Adım:** Formu aç; alanlar: Denetim notu (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İzin kapatıldı"
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /renovations/:id/complete` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RENOVATIONS-10`

---

### Talepler — `/dashboard/requests`
- Dosya: `admin/src/app/(dashboard)/dashboard/requests/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Talep yönetimi

#### P-REQUESTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/requests
- **Adım:** http://localhost:3001/dashboard/requests adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /requests` (community)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: No \| Başlık \| Öncelik \| Durum \| Açılış
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-REQUESTS-00`

#### P-REQUESTS-01 · Düğme: {NEXT[r.status].label}
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/requests
- **Adım:** "{NEXT[r.status].label}" düğme öğesine bas
- **Beklenen (yazma):** `PATCH /requests/:id/status` (community, `services/community/main.go:85`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/requests/:id/status' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/requests`, Sakin `requests_screen`, Sakin `unit_residents_screen`, Yön.mobil `request_detail_screen`, Yön.mobil `requests_screen`
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-REQUESTS-01`

---

### Sakinler — `/dashboard/residents`
- Dosya: `admin/src/app/(dashboard)/dashboard/residents/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Sakin kimlik bilgileri

#### P-RESIDENTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** http://localhost:3001/dashboard/residents adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bilgi notu (satır 79): {act.sms.note}
- **Adım:** Bilgi notu (satır 80): E-posta gönderildi: {act.email.note}
- **Adım:** Bilgi notu (satır 81): Bu kod bir daha gösterilmez: {act.note}
- **Adım:** Veri yüklenir: `GET /residents` (identity)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Veri yüklenir: `GET /residents/invitations` (identity)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ad Soyad \| Telefon \| Daire \| Sıfat \| Durum
- **Adım:** Kart (satır 178): Sakin davetleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Telefon \| Daire \| Sıfat \| Durum \| Gönderildi
- **Adım:** Bilgi notu (satır 261): Malik daveti yalnız maliki kayıtlı olmayan daireye; hane üyesi daveti yalnız dairede otura
- **Adım:** Bilgi notu (satır 287): Kişinin kimliğini doğrulayın. Eski numarayla açık oturumlar kapanır; eski numaraya (SMS sa
- **Adım:** Bilgi notu (satır 312): Düzeltilmesi gereken satırlar: {bulk.errors.slice(0, 10).join(}
- **Adım:** Bilgi notu (satır 313): {bulk.rows.length} satır gönderilecek.
- **Adım:** Pencere (satır 317): Toplu ekleme sonucu
- **Adım:** Bilgi notu (satır 319): Kodlar bir daha gösterilmez: Etkinleştirme kodlarını sakinlere iletin; bu pencere kapanınca kodlar görüntülenemez (gere
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Satır \| Telefon \| Sonuç \| Kod / neden
- **Adım:** Veri yüklenir: `GET /residents/tenancy-requests` (identity)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Kart (satır 71): Kiracılık bitişleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Kiracı \| Yol \| Durum \| Süre / bitiş \| Belgeler ve kayıt
- **Adım:** Bilgi notu (satır 134): Beyan: {attestation}
- **Adım:** Dosya seçme (satır 144)
- **Adım:** Bilgi notu (satır 167): Belge sahte ya da hatalı çıktıysa kiracılık aynı kayıtla, geçmişiyle geri açılır. Dairede 
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-00`

#### P-RESIDENTS-01 · Düğme: Kopyalandı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Kopyalandı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-01`

#### P-RESIDENTS-02 · Düğme: Kodu ilettim, kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Kodu ilettim, kapat" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-02`

#### P-RESIDENTS-03 · Düğme: Toplu ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Toplu ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-03`

#### P-RESIDENTS-04 · Düğme: Davet gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Davet gönder" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-04`

#### P-RESIDENTS-05 · Düğme: Sakin ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Sakin ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-05`

#### P-RESIDENTS-06 · Düğme: Kod üret
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Kod üret" düğme öğesine bas
- **Beklenen (yazma):** `POST /residents/:id/activation-code` (identity, `services/identity/main.go:148`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id/activation-code' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.activation` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-06`

#### P-RESIDENTS-07 · Düğme: Telefon
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Telefon" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-07`

#### P-RESIDENTS-08 · Düğme: Kilidi aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Kilidi aç" düğme öğesine bas
- **Beklenen (yazma):** `POST /residents/:id/unlock` (identity, `services/identity/main.go:152`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id/unlock' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /residents/:id/unlock` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-08`

#### P-RESIDENTS-09 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-09`

#### P-RESIDENTS-10 · Düğme: İptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "İptal et" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `POST /residents/invitations/:id/cancel` (identity, `services/identity/main.go:137`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `resident_invitations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM resident_invitations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/invitations/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `invitations_banner`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-10`

#### P-RESIDENTS-11 · Form: Sakin ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar: Ad*, Soyad*, Telefon*, E-posta, Bağımsız bölüm*, Sıfat* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-11`

#### P-RESIDENTS-12 · Form: Daire daveti gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar: Ad, Soyad, Telefon*, E-posta, Bağımsız bölüm*, Sıfat* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-12`

#### P-RESIDENTS-13 · Form: Telefon değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar: Yeni telefon* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /residents/:id/phone` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-13`

#### P-RESIDENTS-14 · Form: Toplu sakin ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar:  (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-14`

#### P-RESIDENTS-15 · Düğme: Kodları ilettim, kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Kodları ilettim, kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-15`

#### P-RESIDENTS-16 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar: Sıfat, Durum, Ayrılış (ilişik kesme) tarihi (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Sakin kaydı güncellendi"
- **Beklenen (yazma):** `PATCH /residents/:id` (identity, `services/identity/main.go:147`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `resident_units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-16`

#### P-RESIDENTS-17 · Düğme: Yönetim yolu başlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Yönetim yolu başlat" düğme öğesine bas
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 72)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-17`

#### P-RESIDENTS-18 · Düğme: Tamamla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Tamamla" düğme öğesine bas
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 108)
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/complete` (identity, `services/identity/main.go:142`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY
  - Veritabanı tetikleyicileri çalışır: `trg_resident_units_tenancy_guard`, `trg_resident_units_tenant_arrival`, `trg_resident_units_tenant_departure` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `resident_units`, `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/complete' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `identity.tenancy` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-18`

#### P-RESIDENTS-19 · Düğme: Yeni belge
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Yeni belge" düğme öğesine bas
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 113)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-19`

#### P-RESIDENTS-20 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "İptal" düğme öğesine bas
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 116)
- **Beklenen (yazma):** `POST /residents/tenancy-requests/:id/cancel` (identity, `services/identity/main.go:143`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `tenancy_end_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM tenancy_end_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `tenancy_end_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM tenancy_end_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/residents/tenancy-requests/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/residents`, Sakin `tenancy_requests_screen`, Yön.mobil `resident_tools_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-20`

#### P-RESIDENTS-21 · Düğme: Geri al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** "Geri al" düğme öğesine bas
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 120)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-21`

#### P-RESIDENTS-22 · Form: Kiracılığı geri aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/residents
- **Adım:** Formu aç; alanlar: Gerekçe*, Şifreniz* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `tenancy-ends` bileşenindedir (satır 161)
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
- **Sonuç:** http://localhost:18000/sonuc → `P-RESIDENTS-22`

---

### Görevlendirmeler — `/dashboard/roles`
- Dosya: `admin/src/app/(dashboard)/dashboard/roles/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetim görevlendirmeleri

#### P-ROLES-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/roles
- **Adım:** http://localhost:3001/dashboard/roles adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /property-roles` (identity)
- **Adım:** Bilgi notu (satır 41): Görev verme ve sonlandırma yalnızca yöneticinin yetkisindedir.
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kişi \| Telefon \| Görev \| Dönem \| Karar \| Durum \| Atayan
- **Adım:** Pencere (satır 116): Hesap etkinleştirme kodu
- **Adım:** Bilgi notu (satır 121): Bu kod bir daha gösterilmez: {shown.act.note}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ROLES-00`

#### P-ROLES-01 · Düğme: Görev ver
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/roles
- **Adım:** "Görev ver" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ROLES-01`

#### P-ROLES-02 · Düğme: Sonlandır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/roles
- **Adım:** "Sonlandır" düğme öğesine bas
- **Beklenen (yazma):** `POST /property-roles/:id/end` (identity, `services/identity/main.go:170`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_token_invalidation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_token_invalidation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `property_roles` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/property-roles/:id/end' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-ROLES-02`

#### P-ROLES-03 · Form: Görev ver
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/roles
- **Adım:** Formu aç; alanlar: Telefon*, Görev*, Kurul kararı*, Bitiş tarihi, Ad, Soyad (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Görev verildi"
- **Beklenen (yazma):** `POST /property-roles` (identity, `services/identity/main.go:169`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `user_activation_codes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `user_activation_codes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM user_activation_codes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - Ortak tablolar da değişir: `property_roles`, `users` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/property-roles' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-ROLES-03`

#### P-ROLES-04 · Düğme: Kodu ilettim, kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/roles
- **Adım:** "Kodu ilettim, kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ROLES-04`

---

### Anketler — `/dashboard/surveys`
- Dosya: `admin/src/app/(dashboard)/dashboard/surveys/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — Anket yönetimi

#### P-SURVEYS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** http://localhost:3001/dashboard/surveys adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /surveys` (survey)
- **Adım:** Veri yüklenir: `GET /surveys/:id/comments` (survey)
- **Adım:** Veri yüklenir: `GET /surveys/:id` (survey)
- **Adım:** Bilgi notu (satır 38): Anket sonuçları genel kurul kararı yerine geçmez. Bağlayıcı kararlar Genel Kurul ekranında
- **Adım:** Kart (satır 40): Anketler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başlık \| Bitiş \| Katılım \| Durum
- **Adım:** Pencere (satır 90): Anket sonucu
- **Adım:** Bilgi notu (satır 95): {d.results_note}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Seçenek \| Oy \| Oran \| Arsa payı
- **Adım:** Pencere (satır 116): Anket yorumları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Yazan \| Yorum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-00`

#### P-SURVEYS-01 · Düğme: Anket oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Anket oluştur" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-01`

#### P-SURVEYS-02 · Düğme: Sonuç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Sonuç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-02`

#### P-SURVEYS-03 · Düğme: Yorumlar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Yorumlar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-03`

#### P-SURVEYS-04 · Düğme: Yayımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Yayımla" düğme öğesine bas
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
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-04`

#### P-SURVEYS-05 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen (yazma):** `POST /surveys/:id/close` (survey, `services/survey/main.go:209`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-05`

#### P-SURVEYS-06 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "İptal" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-06`

#### P-SURVEYS-07 · Form: Anket oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** Formu aç; alanlar: Başlık*, Açıklama, Tür, Bitiş, Anonim, Arsa payı ağırlıklı, Yorum, Sonuç bitmeden görünsün (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Anket taslak olarak oluşturuldu; yayımlayınca oylama başlar"
- **Beklenen (yazma):** `POST /surveys` (survey, `services/survey/main.go:168`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `survey_options` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM survey_options ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `surveys` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-07`

#### P-SURVEYS-08 · Düğme: Seçeneği çıkar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "Seçeneği çıkar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-08`

#### P-SURVEYS-09 · Düğme: + Seçenek
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** "+ Seçenek" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-09`

#### P-SURVEYS-10 · Form: Anketi iptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/surveys
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Anket iptal edildi"
- **Beklenen (yazma):** `POST /surveys/:id/cancel` (survey, `services/survey/main.go:218`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/surveys/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-SURVEYS-10`

---

### Bağımsız Bölümler — `/dashboard/units`
- Dosya: `admin/src/app/(dashboard)/dashboard/units/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Bağımsız bölüm ve arsa payı kayıtları

#### P-UNITS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** http://localhost:3001/dashboard/units adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Bilgi notu (satır 109): Maliki kayıtlı olmayan daireler: {d.data.filter((u) => u.owner_missing).map((u) => `$u.block + "-${u.door_number}`).join(",
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Blok \| Kapı \| Kat \| Tür \| Arsa payı \| Net m² \| Brüt m² \| Oturum
- **Adım:** Bilgi notu (satır 205): Düzeltilmesi gereken satırlar: {parsed.errors.slice(0, 10).joi}
- **Adım:** Bilgi notu (satır 206): {parsed.units.length} bölüm eklenecek, toplam arsa payı {num(parsed.units.reduce((a, u)}.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-00`

#### P-UNITS-01 · Düğme: Toplu ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** "Toplu ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-01`

#### P-UNITS-02 · Düğme: Bölüm ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** "Bölüm ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-02`

#### P-UNITS-03 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-03`

#### P-UNITS-04 · Düğme: Borcu yoktur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** "Borcu yoktur" düğme öğesine bas
- **Beklenen (okuma):** `GET /finance/clearance-certificates/:id/pdf` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (yazma):** `POST /finance/clearance-certificates` (finance, `services/finance/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41)
  - **Veritabanı (Adminer → SQL komutu):**
    - `clearance_certificates` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM clearance_certificates ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/clearance-certificates' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/units`, Sakin `dues_payment_screen`, Yön.mobil `units_screen`
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-04`

#### P-UNITS-05 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** Formu aç; alanlar: Blok, Kapı no*, Kat, Arsa payı*, Net kullanım alanı (m²)*, Brüt m², Tür, Ticari mi?, Kiracı yokken (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Bölüm güncellendi; Bölüm eklendi"
- **Beklenen (yazma):** `PATCH /units/:id` (identity, `services/identity/main.go:179`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Beklenen (yazma):** `POST /units` (identity, `services/identity/main.go:178`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-05`

#### P-UNITS-06 · Form: Toplu bölüm ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/units
- **Adım:** Formu aç; alanlar:  (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /units` (identity, `services/identity/main.go:178`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: serviste rol karşılaştırması: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - Ortak tablolar da değişir: `units` (aynı sorgu kalıbıyla bakılabilir)
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/units' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-UNITS-06`

---

### Kural İhlalleri — `/dashboard/violations`
- Dosya: `admin/src/app/(dashboard)/dashboard/violations/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Kural ihlalleri ve bildiren kimliği

#### P-VIOLATIONS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** http://localhost:3001/dashboard/violations adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /site-rules` (community)
- **Adım:** Veri yüklenir: `GET /violations` (community)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Bilgi notu (satır 44): Site yönetimi para cezası veremez; idari yaptırım yetkisi kanunda gösterilen kamu merciler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Kural \| Olay \| Bildiren \| Durum \| Kademe \| Son 24 ay
- **Adım:** Kart (satır 62): Kural kataloğu
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kural \| Kategori \| Yönetim planı dayanağı \| Durum
- **Adım:** Veri yüklenir: `GET /violations/:id` (community)
- **Adım:** Pencere (satır 136): İhlal kaydı
- **Adım:** Kart (satır 163): Olay geçmişi
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Olay \| Kişi \| Açıklama
- **Adım:** Bilgi notu (satır 182): Bildirim dairenin bütün aktif sakinlerine (malik ve kiracı) gider; kiracı malikle mütesels
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-00`

#### P-VIOLATIONS-01 · Düğme: İhlal kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "İhlal kaydet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-01`

#### P-VIOLATIONS-02 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-02`

#### P-VIOLATIONS-03 · Düğme: Kural ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Kural ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-03`

#### P-VIOLATIONS-04 · Düğme: Pasifleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Pasifleştir" düğme öğesine bas
- **Beklenen (yazma):** `POST /site-rules/:id/deactivate` (community, `services/community/violation.go:94`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `site_rules` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM site_rules ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/site-rules/:id/deactivate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /site-rules/:id/deactivate` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-04`

#### P-VIOLATIONS-05 · Form: Kural ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** Formu aç; alanlar: Kural*, Kategori, Yönetim planı dayanağı*, Açıklama (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kural eklendi"
- **Beklenen (yazma):** `POST /site-rules` (community, `services/community/violation.go:66`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `site_rules` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM site_rules ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/site-rules' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /site-rules` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-05`

#### P-VIOLATIONS-06 · Form: İhlal kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** Formu aç; alanlar: Kural*, Daire*, Ne oldu?* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İhlal kaydedildi"
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
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-06`

#### P-VIOLATIONS-07 · Düğme: Doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Doğrula" düğme öğesine bas
- **Beklenen (yazma):** `POST /violations/:id/verify` (community, `services/community/violation.go:210`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `rule_violation_events` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM rule_violation_events ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `rule_violations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM rule_violations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/violations/:id/verify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /violations/:id/verify` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-07`

#### P-VIOLATIONS-08 · Düğme: Doğrulanmadı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Doğrulanmadı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-08`

#### P-VIOLATIONS-09 · Düğme: {STAGE[s]}
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "{STAGE[s]}" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-09`

#### P-VIOLATIONS-10 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-10`

#### P-VIOLATIONS-11 · Düğme: Doğrulanmadı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** "Doğrulanmadı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-11`

#### P-VIOLATIONS-12 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/violations
- **Adım:** Formu aç; alanlar: Açıklama* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kaydedildi"
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /violations/:id/escalate` yalnız BOARD_MEMBER/MANAGER). DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /violations/:id/resolve` yalnız BOARD_MEMBER/MANAGER). DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /violations/:id/dismiss` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-VIOLATIONS-12`

---
