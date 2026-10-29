# 3.6 Panel — Analiz

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Enerji — `/dashboard/energy`
- Dosya: `admin/src/app/(dashboard)/dashboard/energy/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Enerji analizi

#### P-ENERGY-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/energy
- **Adım:** http://localhost:3001/dashboard/energy adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /energy/trends` (energy_analytics)
- **Adım:** Veri yüklenir: `GET /energy/anomalies` (energy_analytics)
- **Adım:** Kart (satır 28): Dönemsel tüketim
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Dönem \| Toplam tüketim \| Okunan daire \| Okuma
- **Adım:** Bilgi notu (satır 43): {d.note}
- **Adım:** Kart (satır 48): Olağandışı tüketim
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Değer \| Medyan \| Sapma \| Önem \| Gerekçe
- **Adım:** Bilgi notu (satır 62): {d.basis} {d.note}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ENERGY-00`

---

### Karbon Ayak İzi — `/dashboard/esg`
- Dosya: `admin/src/app/(dashboard)/dashboard/esg/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Karbon ayak izi

#### P-ESG-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/esg
- **Adım:** http://localhost:3001/dashboard/esg adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /esg/consumption` (esg)
- **Adım:** Kart (satır 29): Tüketim
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Toplam tüketim \| Sayaç \| Okuma \| Katsayı (kgCO₂e / birim)
- **Adım:** Bilgi notu (satır 58): {d.note}
- **Adım:** Kart (satır 66): Toplam ${num(result.total_co2e_kg)} kg CO₂e
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Tüketim \| Katsayı \| kg CO₂e
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ESG-00`

#### P-ESG-01 · Düğme: Hesapla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/esg
- **Adım:** "Hesapla" düğme öğesine bas
- **Beklenen (yazma):** `POST /esg/carbon-footprint` (esg, `services/esg/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: AUDITOR/BOARD_MEMBER/MANAGER
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/esg/carbon-footprint' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Sonuç:** http://localhost:18000/sonuc → `P-ESG-01`

---

### Memnuniyet (NPS) — `/dashboard/nps`
- Dosya: `admin/src/app/(dashboard)/dashboard/nps/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Memnuniyet sonuçları

#### P-NPS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/nps
- **Adım:** http://localhost:3001/dashboard/nps adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /nps` (nps)
- **Adım:** Veri yüklenir: `GET /nps/:id` (nps)
- **Adım:** Veri yüklenir: `GET /nps/:id/comments` (nps)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başlık \| Başlangıç \| Bitiş \| Yanıt \| Durum
- **Adım:** Pencere (satır 54): Ölçüm sonucu
- **Adım:** Bilgi notu (satır 62): {d.result.interpretation}
- **Adım:** Bilgi notu (satır 64): Henüz yanıt yok.
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Puan \| Yorum \| Tarih
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-NPS-00`

#### P-NPS-01 · Düğme: Ölçüm başlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/nps
- **Adım:** "Ölçüm başlat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-NPS-01`

#### P-NPS-02 · Düğme: Sonuç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/nps
- **Adım:** "Sonuç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-NPS-02`

#### P-NPS-03 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/nps
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen (yazma):** `POST /nps/:id/close` (nps, `services/nps/main.go:192`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `surveys` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/nps/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /nps/:id/close` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-NPS-03`

#### P-NPS-04 · Form: Memnuniyet ölçümü başlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/nps
- **Adım:** Formu aç; alanlar: Başlık*, Açıklama, Bitiş (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ölçüm başladı"
- **Beklenen (yazma):** `POST /nps` (nps, `services/nps/main.go:159`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `survey_options` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM survey_options ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `surveys` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM surveys ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/nps' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/nps`, Panel `/dashboard/surveys`, Sakin `surveys_mobile_screen`, Yön.mobil `nps_screen`, Yön.mobil `survey_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /nps` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-NPS-04`

---

### Raporlar — `/dashboard/reports`
- Dosya: `admin/src/app/(dashboard)/dashboard/reports/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Mali raporlar

#### P-REPORTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/reports
- **Adım:** http://localhost:3001/dashboard/reports adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/assemblies` (governance)
- **Adım:** Veri yüklenir: `GET /governance/budgets` (governance)
- **Adım:** Kart (satır 47): Borçlu listesi
- **Adım:** Bilgi notu (satır 49): Yalnızca yönetimin iç kullanımı içindir; ortak alanlara asılamaz, site gruplarında paylaşı
- **Adım:** Kart (satır 52): Tahakkuk ve tahsilat özeti
- **Adım:** Kart (satır 57): Hazirun cetveli
- **Adım:** Kart (satır 65): İşletme projesi
- **Adım:** Bağlantı (satır 76): {l.title} {l.desc} → l.href
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-REPORTS-00`

#### P-REPORTS-01 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reports
- **Adım:** "PDF" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-REPORTS-01`

#### P-REPORTS-02 · Düğme: Excel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reports
- **Adım:** "Excel" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-REPORTS-02`

---
