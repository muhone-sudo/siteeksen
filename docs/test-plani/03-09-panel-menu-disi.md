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
- **Adım:** Bağlantı (satır 79): Panele dön → homeFor(myRoles)
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

### /dashboard/usta-hizmet/[id] — `/dashboard/usta-hizmet/[id]`
- Dosya: `admin/src/app/(dashboard)/dashboard/usta-hizmet/[id]/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli

#### P-USTA-HIZMET-ID-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Veri yüklenir: 
- **Adım:** Veri yüklenir: 
- **Adım:** Bağlantı (satır 32): ← Usta & Hizmet → /dashboard/usta-hizmet
- **Adım:** Kart (satır 34): Talep
- **Adım:** Kart (satır 41): Teklif karşılaştırma
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: İşletme \| Tutar \| Kapsam \| Geçerlilik \| Puan \| Tamamlanan iş \| Telefon
- **Adım:** Veri yüklenir: `GET /expense-categories` (expense)
- **Adım:** Kart (satır 95): İş
- **Adım:** Bağlantı (satır 103): Sözleşme formunu doldur → contractHref
- **Adım:** Bilgi notu (satır 117): İtiraz: {job.dispute_note}
- **Adım:** Bilgi notu (satır 139): Faturasız gider onay bekler; kurul onayından sonra hesap verme belgelerine girer. Fatura g
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-00`

#### P-USTA-HIZMET-ID-01 · Düğme: Seç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Seç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-01`

#### P-USTA-HIZMET-ID-02 · Düğme: Teklif seçmeden kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Teklif seçmeden kapat" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-02`

#### P-USTA-HIZMET-ID-03 · Form: Teklifi seç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** Formu aç; alanlar:  (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Teklif seçildi; işletmeye bildirildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-03`

#### P-USTA-HIZMET-ID-04 · Düğme: Onay bekleyen gider oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Onay bekleyen gider oluştur" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-04`

#### P-USTA-HIZMET-ID-05 · Düğme: Sözleşme formunu doldur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Sözleşme formunu doldur" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-05`

#### P-USTA-HIZMET-ID-06 · Düğme: İş tamamlandı, onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "İş tamamlandı, onayla" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-06`

#### P-USTA-HIZMET-ID-07 · Düğme: İtiraz et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "İtiraz et" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-07`

#### P-USTA-HIZMET-ID-08 · Düğme: Puanı gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Puanı gönder" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-08`

#### P-USTA-HIZMET-ID-09 · Form: Onay bekleyen gider
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/usta-hizmet/… (listeden bir kayda tıklanarak açılır)
- **Adım:** Formu aç; alanlar: Gider kalemi*, Gider tarihi* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /expenses` (expense, `services/expense/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expense_distributions` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expense_distributions ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `expenses` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /expenses` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-USTA-HIZMET-ID-09`

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
- **Adım:** Bağlantı (satır 15): Etkinleştirme kodum var → /activate
- **Adım:** Bağlantı (satır 21): Usta &amp; Hizmet&apos;e kaydolun → /tedarikci/kayit
- **Adım:** Bağlantı (satır 122): Şifremi unuttum / hesabımı etkinleştir → /activate
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

### /platform — `/platform`
- Dosya: `admin/src/app/platform/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform
- **Adım:** http://localhost:3001/platform adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Veri yüklenir: 
- **Adım:** Kart (satır 19): Kuyruklar
- **Adım:** Bağlantı (satır 21): Tedarikçi hesapları ve belgeler → /platform/hesaplar
- **Adım:** Bağlantı (satır 22): İşletme yayın onayı → /platform/isletmeler
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-00`

---

### /platform/ayarlar — `/platform/ayarlar`
- Dosya: `admin/src/app/platform/ayarlar/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-AYARLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/ayarlar
- **Adım:** http://localhost:3001/platform/ayarlar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ayar \| Değer
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-AYARLAR-00`

#### P-PLATFORM-AYARLAR-01 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/ayarlar
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-AYARLAR-01`

#### P-PLATFORM-AYARLAR-02 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/ayarlar
- **Adım:** Formu aç; alanlar: Değer (tam sayı) (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ayar kaydedildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-AYARLAR-02`

---

### /platform/fotograflar — `/platform/fotograflar`
- Dosya: `admin/src/app/platform/fotograflar/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-FOTOGRAFLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/fotograflar
- **Adım:** http://localhost:3001/platform/fotograflar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Bilgi notu (satır 45): OCR iletişim bilgisi buldu: {x.ocr_findings.join(", ")}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-FOTOGRAFLAR-00`

#### P-PLATFORM-FOTOGRAFLAR-01 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/fotograflar
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-FOTOGRAFLAR-01`

#### P-PLATFORM-FOTOGRAFLAR-02 · Düğme: Kaldır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/fotograflar
- **Adım:** "Kaldır" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-FOTOGRAFLAR-02`

#### P-PLATFORM-FOTOGRAFLAR-03 · Düğme: Yeniden denetle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/fotograflar
- **Adım:** "Yeniden denetle" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-FOTOGRAFLAR-03`

#### P-PLATFORM-FOTOGRAFLAR-04 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/fotograflar
- **Adım:** Formu aç; alanlar: Gerekçe (yükleyene gösterilir)* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Reddedildi; yükleyene bildirildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-FOTOGRAFLAR-04`

---

### /platform/gelir — `/platform/gelir`
- Dosya: `admin/src/app/platform/gelir/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-GELIR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/gelir
- **Adım:** http://localhost:3001/platform/gelir adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Kart (satır 31): Bakiye hareketleri (gelir değil)
- **Adım:** Bilgi notu (satır 39): Net gelir = aidat + talep ücreti − iade. Defterdeki dönem toplamı: {kurus(r.ledger_total_k
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-GELIR-00`

---

### /platform/hesaplar — `/platform/hesaplar`
- Dosya: `admin/src/app/platform/hesaplar/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-HESAPLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar
- **Adım:** http://localhost:3001/platform/hesaplar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: 
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Unvan \| Sahibi \| Vergi no \| Belge / işletme \| Durum \| Son değişiklik
- **Adım:** Bağlantı (satır 24): {a.trade_name \|\| "(unvan girilm} → `/platform/hesaplar/${a.id
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-00`

---

### /platform/hesaplar/[id] — `/platform/hesaplar/[id]`
- Dosya: `admin/src/app/platform/hesaplar/[id]/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-HESAPLAR-ID-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Kart (satır 30): Hesap
- **Adım:** Bilgi notu (satır 38): Son gerekçe: {a.status_reason}
- **Adım:** Kart (satır 49): Belgeler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Dosya \| Durum \| Yüklendi
- **Adım:** Kart (satır 58): İşletmeler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: İşletme \| Yer \| Durum
- **Adım:** Bilgi notu (satır 79): Kalan bakiye {kurus(a.balance_kurus)}. Son 365 günde kartla yüklenen kısmı en yeni yükleme
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-00`

#### P-PLATFORM-HESAPLAR-ID-01 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-01`

#### P-PLATFORM-HESAPLAR-ID-02 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-02`

#### P-PLATFORM-HESAPLAR-ID-03 · Düğme: Askıya al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Askıya al" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-03`

#### P-PLATFORM-HESAPLAR-ID-04 · Düğme: Yeniden etkinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Yeniden etkinleştir" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-04`

#### P-PLATFORM-HESAPLAR-ID-05 · Düğme: Üyeliği kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Üyeliği kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-05`

#### P-PLATFORM-HESAPLAR-ID-06 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-06`

#### P-PLATFORM-HESAPLAR-ID-07 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/hesaplar/… (listeden bir kayda tıklanarak açılır)
- **Adım:** Formu aç; alanlar: Gerekçe (tedarikçiye gösterilir)* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-HESAPLAR-ID-07`

---

### /platform/iadeler — `/platform/iadeler`
- Dosya: `admin/src/app/platform/iadeler/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-IADELER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/iadeler
- **Adım:** http://localhost:3001/platform/iadeler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Bilgi notu (satır 23): Sonucu bilinmeyen iadeler (sağlayıcıya ulaşılamadı) çift iade olmasın diye kendiliğinden y
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tedarikçi \| Tutar \| Neden \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-IADELER-00`

#### P-PLATFORM-IADELER-01 · Düğme: Yeniden dene
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/iadeler
- **Adım:** "Yeniden dene" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-IADELER-01`

#### P-PLATFORM-IADELER-02 · Düğme: Havaleyle ödendi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/iadeler
- **Adım:** "Havaleyle ödendi" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-IADELER-02`

#### P-PLATFORM-IADELER-03 · Form: Havaleyle ödendi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/iadeler
- **Adım:** Formu aç; alanlar: Havale dekont no*, Havale tarihi* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İade havaleyle kapatıldı; tedarikçiye bildirildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-IADELER-03`

---

### /platform/isletmeler — `/platform/isletmeler`
- Dosya: `admin/src/app/platform/isletmeler/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-ISLETMELER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/isletmeler
- **Adım:** http://localhost:3001/platform/isletmeler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: 
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: İşletme \| Hesap \| Yer \| Hizmet alanı \| Kategoriler \| Durum
- **Adım:** Bağlantı (satır 34): hesaba git → `/platform/hesaplar/${b.account_id
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ISLETMELER-00`

#### P-PLATFORM-ISLETMELER-01 · Düğme: Yayına al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/isletmeler
- **Adım:** "Yayına al" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ISLETMELER-01`

#### P-PLATFORM-ISLETMELER-02 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/isletmeler
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ISLETMELER-02`

#### P-PLATFORM-ISLETMELER-03 · Form: Yayın onayını reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/isletmeler
- **Adım:** Formu aç; alanlar: Gerekçe (tedarikçiye gösterilir)* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Reddedildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ISLETMELER-03`

---

### /platform/itirazlar — `/platform/itirazlar`
- Dosya: `admin/src/app/platform/itirazlar/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-ITIRAZLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/itirazlar
- **Adım:** http://localhost:3001/platform/itirazlar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tedarikçi \| Talep \| Neden \| İade \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ITIRAZLAR-00`

#### P-PLATFORM-ITIRAZLAR-01 · Düğme: Onayla ve iade et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/itirazlar
- **Adım:** "Onayla ve iade et" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ITIRAZLAR-01`

#### P-PLATFORM-ITIRAZLAR-02 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/itirazlar
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ITIRAZLAR-02`

#### P-PLATFORM-ITIRAZLAR-03 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/itirazlar
- **Adım:** Formu aç; alanlar: Gerekçe (tedarikçiye gösterilir)* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-ITIRAZLAR-03`

---

### /platform/kategoriler — `/platform/kategoriler`
- Dosya: `admin/src/app/platform/kategoriler/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-KATEGORILER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/kategoriler
- **Adım:** http://localhost:3001/platform/kategoriler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Bilgi notu (satır 22): Site alımları kendi kategorilerindedir (ör. &quot;Site temizliği&quot; yalnız site yönetim
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kategori \| Üst \| Talep ücreti \| Kim açar \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-KATEGORILER-00`

#### P-PLATFORM-KATEGORILER-01 · Düğme: Kategori ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/kategoriler
- **Adım:** "Kategori ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-KATEGORILER-01`

#### P-PLATFORM-KATEGORILER-02 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/kategoriler
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-KATEGORILER-02`

#### P-PLATFORM-KATEGORILER-03 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/kategoriler
- **Adım:** Formu aç; alanlar: Ad*, Talep ücreti (TL)*, Kim talep açabilir*, Üst kategori, Sıra (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kategori kaydedildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-KATEGORILER-03`

---

### /platform/paketler — `/platform/paketler`
- Dosya: `admin/src/app/platform/paketler/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-PAKETLER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/paketler
- **Adım:** http://localhost:3001/platform/paketler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Bilgi notu (satır 24): Fiyat değişikliği mevcut abonelere bir sonraki yenilemede uygulanır. Varsayılan (ücretsiz)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Paket \| Aylık \| Talep indirimi \| Dahil talep / SMS \| Öncelik \| Vitrinde telefon \| Ağırlık
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-PAKETLER-00`

#### P-PLATFORM-PAKETLER-01 · Düğme: Paket ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/paketler
- **Adım:** "Paket ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-PAKETLER-01`

#### P-PLATFORM-PAKETLER-02 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/paketler
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-PAKETLER-02`

#### P-PLATFORM-PAKETLER-03 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/paketler
- **Adım:** Formu aç; alanlar: Ad*, Aylık ücret (TL), Talep indirimi (%), Sıralama ağırlığı, Ayda dahil talep, Aylık SMS hakkı, Sıra (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Paket kaydedildi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-PAKETLER-03`

---

### /platform/yapay-zeka — `/platform/yapay-zeka`
- Dosya: `admin/src/app/platform/yapay-zeka/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-YAPAY-ZEKA-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yapay-zeka
- **Adım:** http://localhost:3001/platform/yapay-zeka adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Bilgi notu (satır 37): Kişisel veri (KVKK): Fotoğraflar yurt dışındaki bir sağlayıcıya gönderilirse bu, kişisel verinin yurt dışına ak
- **Adım:** Bilgi notu (satır 40): Şifreleme anahtarı (PII_ENCRYPTION_KEY) tanımlı değil: API anahtarı ve parola kaydedilemez
- **Adım:** Kart (satır 41): Sağlayıcı
- **Adım:** Kart (satır 88): Nasıl çalışır
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YAPAY-ZEKA-00`

#### P-PLATFORM-YAPAY-ZEKA-01 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yapay-zeka
- **Adım:** "Kaydet" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YAPAY-ZEKA-01`

#### P-PLATFORM-YAPAY-ZEKA-02 · Düğme: Bağlantıyı sına
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yapay-zeka
- **Adım:** "Bağlantıyı sına" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YAPAY-ZEKA-02`

#### P-PLATFORM-YAPAY-ZEKA-03 · Düğme: Anahtarı sil
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yapay-zeka
- **Adım:** "Anahtarı sil" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YAPAY-ZEKA-03`

---

### /platform/yorumlar — `/platform/yorumlar`
- Dosya: `admin/src/app/platform/yorumlar/page.tsx`
- Panel erişimi: PlatformAdmin — Platform yönetimi (Usta & Hizmet)

#### P-PLATFORM-YORUMLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yorumlar
- **Adım:** http://localhost:3001/platform/yorumlar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: 
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| İşletme \| Puan \| Yorum \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YORUMLAR-00`

#### P-PLATFORM-YORUMLAR-01 · Düğme: Gizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yorumlar
- **Adım:** "Gizle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YORUMLAR-01`

#### P-PLATFORM-YORUMLAR-02 · Form: Yorumu gizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/platform/yorumlar
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Yorum gizlendi"
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PLATFORM-YORUMLAR-02`

---

### /tedarikci/(auth)/giris — `/tedarikci/(auth)/giris`
- Dosya: `admin/src/app/tedarikci/(auth)/giris/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-AUTH-GIRIS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(auth)/giris
- **Adım:** http://localhost:3001/tedarikci/(auth)/giris adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bağlantı (satır 14): Tedarikçi olarak kaydolun → /tedarikci/kayit
- **Adım:** Bağlantı (satır 122): Şifremi unuttum / hesabımı etkinleştir → /activate
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-AUTH-GIRIS-00`

---

### /tedarikci/(auth)/kayit — `/tedarikci/(auth)/kayit`
- Dosya: `admin/src/app/tedarikci/(auth)/kayit/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-AUTH-KAYIT-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(auth)/kayit
- **Adım:** http://localhost:3001/tedarikci/(auth)/kayit adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Bağlantı (satır 191): Giriş yapın → /tedarikci/giris
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-AUTH-KAYIT-00`

---

### /tedarikci/(panel) — `/tedarikci/(panel)`
- Dosya: `admin/src/app/tedarikci/(panel)/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** http://localhost:3001/tedarikci/(panel) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/me` (marketplace)
- **Adım:** Kart (satır 43): Tedarikçi hesabınızı oluşturun
- **Adım:** Bilgi notu (satır 46): Havuzda görünmek için hesap bilgilerinizi girip vergi levhası (ya da oda kaydı) ve kimlik 
- **Adım:** Kart (satır 70): Hesap durumu
- **Adım:** Bilgi notu (satır 73): İnceleme notu: {acc.status_reason}
- **Adım:** Bilgi notu (satır 74): Bilgilerinizi ve belgelerinizi tamamlayıp incelemeye gönderin. İnceleme sürerken bilgiler 
- **Adım:** Bilgi notu (satır 75): Hesabınız inceleniyor. Sonuç size bildirilecek.
- **Adım:** Kart (satır 80): Hesap bilgileri
- **Adım:** Veri yüklenir: `GET /market/supplier/documents` (marketplace)
- **Adım:** Kart (satır 103): Belgeler
- **Adım:** Dosya seçme (satır 111)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Dosya \| Durum \| Yüklendi
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-00`

#### P-TEDARIKCI-PANEL-01 · Düğme: Hesabı oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "Hesabı oluştur" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/account` (marketplace, `services/marketplace/main.go:103`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_supplier_accounts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/account' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-01`

#### P-TEDARIKCI-PANEL-02 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "Kaydet" düğme öğesine bas
- **Beklenen (yazma):** `PUT /market/supplier/account` (marketplace, `services/marketplace/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/account' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-02`

#### P-TEDARIKCI-PANEL-03 · Düğme: Kaydet ve incelemeye gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "Kaydet ve incelemeye gönder" düğme öğesine bas
- **Beklenen (yazma):** `PUT /market/supplier/account` (marketplace, `services/marketplace/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/account' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`
- **Beklenen (yazma):** `POST /market/supplier/account/submit` (marketplace, `services/marketplace/main.go:105`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/account/submit' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-03`

#### P-TEDARIKCI-PANEL-04 · Düğme: Yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "Yükle" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/documents` (marketplace, `services/marketplace/main.go:107`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_account_documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_account_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/documents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-04`

#### P-TEDARIKCI-PANEL-05 · Düğme: İndir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "İndir" düğme öğesine bas
- **Beklenen (okuma):** `GET /market/supplier/documents/:id/file` (marketplace) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-05`

#### P-TEDARIKCI-PANEL-06 · Düğme: Sil
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)
- **Adım:** "Sil" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /market/supplier/documents/:id` (marketplace, `services/marketplace/main.go:109`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_account_documents` — satır silinmiş olmalı: `SELECT xmin, * FROM mp_account_documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/documents/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-06`

---

### /tedarikci/(panel)/bakiye — `/tedarikci/(panel)/bakiye`
- Dosya: `admin/src/app/tedarikci/(panel)/bakiye/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-BAKIYE-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** http://localhost:3001/tedarikci/(panel)/bakiye adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/wallet` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/supplier/me` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/terms/balance` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/supplier/card-refunds` (marketplace)
- **Adım:** Bilgi notu (satır 46): Ödeme sonucu: {params.get("message")}
- **Adım:** Bilgi notu (satır 60): Üyeliğiniz kapatıldı; bakiye yüklenemez ve paket değiştirilemez.
- **Adım:** Kart (satır 75): Bakiye yükle
- **Adım:** Bilgi notu (satır 84): Kartla ödeme bu kurulumda yapılandırılmamış.
- **Adım:** Kart (satır 86): Paket
- **Adım:** Kart (satır 113): Karta iadeler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tutar \| Yükleme \| Durum
- **Adım:** Kart (satır 122): Hareketler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tür \| Açıklama \| Tutar \| Sonraki bakiye
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-00`

#### P-TEDARIKCI-PANEL-BAKIYE-01 · Düğme: Koşulları kabul et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Koşulları kabul et" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/terms/balance/accept` (marketplace, `services/marketplace/main.go:139`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_terms_acceptances` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_terms_acceptances ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/terms/balance/accept' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/bakiye`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-01`

#### P-TEDARIKCI-PANEL-BAKIYE-02 · Düğme: Kartla öde
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Kartla öde" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-02`

#### P-TEDARIKCI-PANEL-BAKIYE-03 · Düğme: Bu pakete geç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Bu pakete geç" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-03`

#### P-TEDARIKCI-PANEL-BAKIYE-04 · Düğme: Değişikliği iptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Değişikliği iptal et" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-04`

#### P-TEDARIKCI-PANEL-BAKIYE-05 · Düğme: Önceki
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Önceki" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-05`

#### P-TEDARIKCI-PANEL-BAKIYE-06 · Düğme: Sonraki
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bakiye
- **Adım:** "Sonraki" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BAKIYE-06`

---

### /tedarikci/(panel)/bildirimler — `/tedarikci/(panel)/bildirimler`
- Dosya: `admin/src/app/tedarikci/(panel)/bildirimler/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-BILDIRIMLER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bildirimler
- **Adım:** http://localhost:3001/tedarikci/(panel)/bildirimler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/notifications` (marketplace)
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BILDIRIMLER-00`

#### P-TEDARIKCI-PANEL-BILDIRIMLER-01 · Düğme: Tümünü okundu say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bildirimler
- **Adım:** "Tümünü okundu say" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/notifications/read` (marketplace, `services/marketplace/main.go:122`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/notifications/read' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Panel `/tedarikci/(panel)/bildirimler`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BILDIRIMLER-01`

#### P-TEDARIKCI-PANEL-BILDIRIMLER-02 · Düğme: Okundu
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/bildirimler
- **Adım:** "Okundu" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/notifications/read` (marketplace, `services/marketplace/main.go:122`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/notifications/read' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Panel `/tedarikci/(panel)/bildirimler`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-BILDIRIMLER-02`

---

### /tedarikci/(panel)/isletmeler — `/tedarikci/(panel)/isletmeler`
- Dosya: `admin/src/app/tedarikci/(panel)/isletmeler/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-ISLETMELER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler
- **Adım:** http://localhost:3001/tedarikci/(panel)/isletmeler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/businesses` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/supplier/me` (marketplace)
- **Adım:** Bağlantı (satır 15): Yeni işletme → /tedarikci/isletmeler/yeni
- **Adım:** Bilgi notu (satır 16): Önce Hesabım sayfasından tedarikçi hesabınızı oluşturun.
- **Adım:** Bilgi notu (satır 18): İşletmeleriniz, hesabınız ve işletme bilgileri SiteEksen tarafından onaylandıktan sonra ha
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: İşletme \| Yer \| Hizmet alanı \| Durum \| Puan
- **Adım:** Bağlantı (satır 25): {b.name} → `/tedarikci/isletmeler/${b.id
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-00`

---

### /tedarikci/(panel)/isletmeler/[id] — `/tedarikci/(panel)/isletmeler/[id]`
- Dosya: `admin/src/app/tedarikci/(panel)/isletmeler/[id]/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-ISLETMELER-I-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/businesses/:id` (marketplace)
- **Adım:** Veri yüklenir: `GET /market/meta` (marketplace)
- **Adım:** Bilgi notu (satır 56): İnceleme notu: {existing.review_note}
- **Adım:** Bilgi notu (satır 57): İşletme taslakta; havuzda görünmesi için incelemeye gönderin.
- **Adım:** Kart (satır 58): Bilgiler
- **Adım:** Veri yüklenir: `GET /market/supplier/businesses/:id/services` (marketplace)
- **Adım:** Kart (satır 141): Hizmet ve ürünler
- **Adım:** Dosya seçme (satır 144)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Hizmet \| Fiyat \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-00`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-01 · Düğme: Kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Kaydet" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-01`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-02 · Düğme: İncelemeye gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "İncelemeye gönder" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/businesses/:id/submit` (marketplace, `services/marketplace/main.go:114`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_businesses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_businesses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/businesses/:id/submit' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/puanlar`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-02`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-03 · Düğme: İşletmeyi kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "İşletmeyi kapat" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/businesses/:id/close` (marketplace, `services/marketplace/main.go:115`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_businesses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_businesses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/businesses/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/puanlar`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-03`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-04 · Düğme: Hizmet ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Hizmet ekle" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-04`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-05 · Seçim: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** Seçimi değiştir (her seçeneği en az bir kez dene); liste/içerik seçime göre değişmeli
- **Beklenen (yazma):** `POST /market/supplier/services/:id/photo` (marketplace, `services/marketplace/main.go:120`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `photo_moderation` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM photo_moderation ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_business_services` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `photo_moderation` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM photo_moderation ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/services/:id/photo' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-05`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-06 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-06`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-07 · Düğme: Fotoğraf
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Fotoğraf" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-07`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-08 · Düğme: Sil
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Sil" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /market/supplier/services/:id` (marketplace, `services/marketplace/main.go:119`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_business_services` — satır silinmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/services/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-08`

#### P-TEDARIKCI-PANEL-ISLETMELER-I-09 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/isletmeler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** Formu aç; alanlar: Hizmet / ürün adı*, Açıklama, En düşük (TL), En yüksek (TL), Birim (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Hizmet kaydedildi"
- **Beklenen (yazma):** `PUT /market/supplier/services/:id` (marketplace, `services/marketplace/main.go:118`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_business_services` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_business_services` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/services/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`
- **Beklenen (yazma):** `POST /market/supplier/businesses/:id/services` (marketplace, `services/marketplace/main.go:117`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_business_services` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_business_services` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_business_services ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/businesses/:id/services' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/isletmeler/[id]`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-ISLETMELER-I-09`

---

### /tedarikci/(panel)/puanlar — `/tedarikci/(panel)/puanlar`
- Dosya: `admin/src/app/tedarikci/(panel)/puanlar/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-PUANLAR-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/puanlar
- **Adım:** http://localhost:3001/tedarikci/(panel)/puanlar adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/reviews` (marketplace)
- **Adım:** Kart (satır 26): ${r.business_name ?? ""} — ${"★".repeat(r.rating)}${"☆".repeat(5 - r.rating)}
- **Adım:** Bilgi notu (satır 31): Platform bu yorumu gizledi: {r.hidden_reason}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-PUANLAR-00`

#### P-TEDARIKCI-PANEL-PUANLAR-01 · Düğme: Yanıtla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/puanlar
- **Adım:** "Yanıtla" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/reviews/:id/reply` (marketplace, `services/marketplace/main.go:135`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Veritabanı tetikleyicileri çalışır: `mp_reviews_guard`, `mp_reviews_rating_refresh` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_reviews` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_reviews ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/reviews/:id/reply' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/puanlar`, Panel `/tedarikci/(panel)/talepler/[id]`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-PUANLAR-01`

---

### /tedarikci/(panel)/talepler — `/tedarikci/(panel)/talepler`
- Dosya: `admin/src/app/tedarikci/(panel)/talepler/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-TALEPLER-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler
- **Adım:** http://localhost:3001/tedarikci/(panel)/talepler adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/requests` (marketplace)
- **Adım:** Bilgi notu (satır 32): Hesabınız onaylanmadan talep kabul edemezsiniz.
- **Adım:** Kart (satır 35): Henüz talep yok
- **Adım:** Bağlantı (satır 65): Teklif, yazışma ve iletişim → → `/tedarikci/talepler/${r.id
- **Adım:** Bağlantı (satır 70): Bakiye yetersiz — bakiye yükle → → /tedarikci/bakiye
- **Adım:** Bağlantı (satır 73): Önizleme → → `/tedarikci/talepler/${r.id
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-00`

#### P-TEDARIKCI-PANEL-TALEPLER-01 · Düğme: Kabul et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler
- **Adım:** "Kabul et" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-01`

#### P-TEDARIKCI-PANEL-TALEPLER-02 · Form: Talebi kabul et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler
- **Adım:** Formu aç; alanlar:  (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /market/supplier/requests/:id/accept` (marketplace, `services/marketplace/main.go:125`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Veritabanı tetikleyicileri çalışır: `mp_requests_active_property`, `mp_wallet_ledger_no_change` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_wallet_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_wallet_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_request_dispatch` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_request_dispatch ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/requests/:id/accept' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-02`

---

### /tedarikci/(panel)/talepler/[id] — `/tedarikci/(panel)/talepler/[id]`
- Dosya: `admin/src/app/tedarikci/(panel)/talepler/[id]/page.tsx`
- Panel erişimi: Supplier — Tedarikçi paneli (Usta & Hizmet)

#### P-TEDARIKCI-PANEL-TALEPLER-ID-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır) adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /market/supplier/requests/:id` (marketplace)
- **Adım:** Bağlantı (satır 23): ← Talepler → /tedarikci/talepler
- **Adım:** Kart (satır 25): Talep
- **Adım:** Kart (satır 46): Alıcının iletişim bilgisi
- **Adım:** Bağlantı (satır 50): {r.contact.phone} → `tel:${r.contact.phone
- **Adım:** Bilgi notu (satır 58): Alıcının adı, telefonu ve adresi talebi kabul ettiğinizde açılır.{" "} {r.status === "OPEN
- **Adım:** Bağlantı (satır 66): Bakiye yetersiz — bakiye yükle → /tedarikci/bakiye
- **Adım:** Veri yüklenir: `GET /market/supplier/requests/:id/deal` (marketplace)
- **Adım:** Kart (satır 37): Teklifiniz
- **Adım:** Kart (satır 78): İş
- **Adım:** Bilgi notu (satır 87): Alıcının onayı bekleniyor; süresinde yanıt vermezse iş tamamlanmış sayılır.
- **Adım:** Bilgi notu (satır 88): Alıcının itirazı: {j.dispute_note}
- **Adım:** Veri yüklenir: `GET /market/supplier/requests/:id/messages` (marketplace)
- **Adım:** Kart (satır 102): Alıcıyla yazışma
- **Adım:** Kart (satır 132): Geçersiz talep bildiriminiz
- **Adım:** Kart (satır 142): Talep geçersiz mi?
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-00`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-01 · Düğme: Kabul et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Kabul et" düğme öğesine bas
- **Beklenen (yazma):** `POST /market/supplier/requests/:id/accept` (marketplace, `services/marketplace/main.go:125`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Veritabanı tetikleyicileri çalışır: `mp_requests_active_property`, `mp_wallet_ledger_no_change` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_wallet_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_wallet_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_request_dispatch` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_request_dispatch ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_requests` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_requests ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `mp_supplier_accounts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_supplier_accounts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/requests/:id/accept' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/bakiye`, Panel `/tedarikci/(panel)/isletmeler`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Panel `/tedarikci/(panel)`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-01`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-02 · Düğme: Geri çek
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Geri çek" düğme öğesine bas
- **Adım:** Öğe `deal-panel` bileşenindedir (satır 46)
- **Beklenen (yazma):** `POST /market/supplier/offers/:id/withdraw` (marketplace, `services/marketplace/main.go:129`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_offers` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_offers ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/offers/:id/withdraw' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-02`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-03 · Düğme: Teklifi güncelle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Teklifi güncelle" düğme öğesine bas
- **Adım:** Öğe `deal-panel` bileşenindedir (satır 62)
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-03`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-04 · Düğme: İş tamamlandı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "İş tamamlandı" düğme öğesine bas
- **Adım:** Öğe `deal-panel` bileşenindedir (satır 83)
- **Beklenen (yazma):** `POST /market/supplier/jobs/:id/done` (marketplace, `services/marketplace/main.go:133`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - Veritabanı tetikleyicileri çalışır: `mp_jobs_completed_refresh` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_jobs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM mp_jobs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/jobs/:id/done' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/settings`, Panel `/tedarikci/(panel)/talepler/[id]`, Panel `/tedarikci/(panel)/talepler`, Sakin `market_request_screens`, Yön.mobil `site_market_screens`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-04`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-05 · Düğme: Gönder
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Gönder" düğme öğesine bas
- **Adım:** Öğe `deal-panel` bileşenindedir (satır 119)
- **Beklenen (yazma):** `POST /market/supplier/requests/:id/messages` (marketplace, `services/marketplace/main.go:131`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_messages` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_messages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/requests/:id/messages' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `{topic}` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/talepler/[id]`, Sakin `market_request_screens`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-05`

#### P-TEDARIKCI-PANEL-TALEPLER-ID-06 · Düğme: Platforma bildir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/tedarikci/(panel)/talepler/… (listeden bir kayda tıklanarak açılır)
- **Adım:** "Platforma bildir" düğme öğesine bas
- **Adım:** Öğe `deal-panel` bileşenindedir (satır 158)
- **Beklenen (yazma):** `POST /market/supplier/requests/:id/dispute` (marketplace, `services/marketplace/main.go:132`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: Supplier
  - **Veritabanı (Adminer → SQL komutu):**
    - `mp_disputes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM mp_disputes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/market/supplier/requests/:id/dispute' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/tedarikci/(panel)/talepler/[id]`
- **Sonuç:** http://localhost:18000/sonuc → `P-TEDARIKCI-PANEL-TALEPLER-ID-06`

---
