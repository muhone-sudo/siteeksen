# 3.9 Panel — Menü dışı

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### / — `/`
- Dosya: `admin/src/app/page.tsx`
- Panel erişimi: herkese açık

#### P--00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ, KİRACI ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/
- **Adım:** http://localhost:3001/ adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P--00`

---

### /activate — `/activate`
- Dosya: `admin/src/app/activate/page.tsx`
- Panel erişimi: herkese açık

#### P-ACTIVATE-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ, KİRACI ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/activate
- **Adım:** http://localhost:3001/activate adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bağlantı (satır 61): Giriş yap → /login
- **Adım:** Bağlantı (satır 115): Girişe dön → /login
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACTIVATE-00`

---

### /dashboard/account — `/dashboard/account`
- Dosya: `admin/src/app/(dashboard)/dashboard/account/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli

#### P-ACCOUNT-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** http://localhost:3001/dashboard/account adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Kart (satır 23): Şifre değiştir
- **Adım:** Bilgi notu (satır 36): {act.error}
- **Adım:** Bilgi notu (satır 37): {act.message} Giriş ekranına yönlendiriliyorsunuz…
- **Adım:** Bilgi notu (satır 48): Şifre değişince bu cihaz dahil bütün cihazlardaki oturumlarınız kapatılır.
- **Adım:** Kart (satır 68): Telefon numarası
- **Adım:** Bilgi notu (satır 79): {act.error}
- **Adım:** Bilgi notu (satır 80): {act.message}
- **Adım:** Bilgi notu (satır 96): Onaylayınca numaranız değişir, bütün cihazlardaki oturumlarınız kapanır ve eski numaranıza
- **Adım:** Kart (satır 113): E-posta adresi
- **Adım:** Bilgi notu (satır 124): {act.error}
- **Adım:** Bilgi notu (satır 125): {act.message}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-00`

#### P-ACCOUNT-01 · Düğme: Değiştiriliyor…
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** "Değiştiriliyor…" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-01`

#### P-ACCOUNT-02 · Düğme: Yeni numaraya kod gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** "Yeni numaraya kod gönder" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-02`

#### P-ACCOUNT-03 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-03`

#### P-ACCOUNT-04 · Düğme: Yeni adrese kod gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** "Yeni adrese kod gönder" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-04`

#### P-ACCOUNT-05 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/account
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNT-05`

---

### /dashboard/forbidden — `/dashboard/forbidden`
- Dosya: `admin/src/app/(dashboard)/dashboard/forbidden/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli

#### P-FORBIDDEN-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/forbidden
- **Adım:** http://localhost:3001/dashboard/forbidden adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bağlantı (satır 76): Panele dön → /dashboard
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-FORBIDDEN-00`

---

### /dashboard/governance — `/dashboard/governance`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance
- **Adım:** http://localhost:3001/dashboard/governance adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-00`

---

### /dashboard/patrol/reports — `/dashboard/patrol/reports`
- Dosya: `admin/src/app/(dashboard)/dashboard/patrol/reports/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Devriye

#### P-PATROL-REPORTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/patrol/reports
- **Adım:** http://localhost:3001/dashboard/patrol/reports adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /patrol-reports` (patrol)
- **Adım:** Veri yüklenir: `GET /patrols/:id/report` (patrol)
- **Adım:** Bağlantı (satır 29): Devriye → /dashboard/patrol
- **Adım:** Kart (satır 30): Dönem
- **Adım:** Kart (satır 46): En çok reddedilen okutmalar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başlangıç \| Tur \| Görevli \| Nokta \| Süre \| Kanıt \| Durum
- **Adım:** Pencere (satır 75): Tur raporu
- **Adım:** Bilgi notu (satır 90): Takip kesintileri: {r.gaps.map((g) => `${dateTime(g.from)}–${dateTime(g.to)} (${g.minutes}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Nokta \| Yöntem \| Sonuç \| Uzaklık / doğruluk
- **Adım:** Kart (satır 100): Bildirilen sorunlar
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-REPORTS-00`

#### P-PATROL-REPORTS-01 · Düğme: Uygula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol/reports
- **Adım:** "Uygula" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-REPORTS-01`

#### P-PATROL-REPORTS-02 · Düğme: Ayrıntı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol/reports
- **Adım:** "Ayrıntı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-REPORTS-02`

---

### /dogrula/[code] — `/dogrula/[code]`
- Dosya: `admin/src/app/dogrula/[code]/page.tsx`
- Panel erişimi: herkese açık

#### P-DOGRULA-CODE-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ, KİRACI ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dogrula/… (listeden bir kayda tıklanarak açılır)
- **Adım:** http://localhost:3001/dogrula/… (listeden bir kayda tıklanarak açılır) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-DOGRULA-CODE-00`

---

### /login — `/login`
- Dosya: `admin/src/app/login/page.tsx`
- Panel erişimi: herkese açık

#### P-LOGIN-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ, KİRACI ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/login
- **Adım:** http://localhost:3001/login adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bağlantı (satır 116): Şifremi unuttum / hesabımı etkinleştir → /activate
- **Adım:** Bağlantı (satır 154): Etkinleştirme kodum var → /activate
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-LOGIN-00`

---

### /odeme-sonuc — `/odeme-sonuc`
- Dosya: `admin/src/app/odeme-sonuc/page.tsx`
- Panel erişimi: herkese açık

#### P-ODEME-SONUC-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ, KİRACI ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/odeme-sonuc
- **Adım:** http://localhost:3001/odeme-sonuc adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ODEME-SONUC-00`

---
