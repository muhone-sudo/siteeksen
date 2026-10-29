# 3.3 Panel — Mali

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Tahsilat ve Borçlar — `/dashboard/accounting`
- Dosya: `admin/src/app/(dashboard)/dashboard/accounting/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Mali kayıtlar

#### P-ACCOUNTING-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** http://localhost:3001/dashboard/accounting adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /finance/ledger` (finance)
- **Adım:** Veri yüklenir: `GET /finance/payments/pending` (finance)
- **Adım:** Veri yüklenir: `GET /finance/payments` (finance)
- **Adım:** Veri yüklenir: `GET /finance/debtors` (finance)
- **Adım:** Veri yüklenir: `GET /finance/payments/:id/receipts` (finance)
- **Adım:** Bilgi notu (satır 66): Havale/EFT ödemesi, yönetici banka hareketini gördükten sonra onayladığında borçtan düşer;
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Onay bekleyen, Tüm ödemeler, Borçlular, Tahsilat defteri, Alacak dekontları, Banka ekstresi
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: (sütunlar dinamik)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: (sütunlar dinamik)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Sıra \| İşlem \| Tutar \| Açıklama \| Kaydeden / zaman \| Özet
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kişi \| Daire \| Sorumlu \| Borç
- **Adım:** Bilgi notu (satır 182): Ödeme SİLİNMEZ: durumu &quot;ters kayıt&quot; olur, borç yeniden açılır ve işlem gerekçesi
- **Adım:** Veri yüklenir: `GET /finance/credit-notes` (finance)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Veri yüklenir: `GET /finance/units/:id/open-assessments` (finance)
- **Adım:** Kart (satır 26): Alacak dekontları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: No \| Daire / dönem \| Tutar \| Gerekçe \| Düzenleyen \| Durum
- **Adım:** Bilgi notu (satır 57): Dekont borcu düşürür, tahsilat sayılmaz ve tahsilat defterine yazılır. Silinemez; hata anc
- **Adım:** Veri yüklenir: `GET /finance/bank-statements` (finance)
- **Adım:** Veri yüklenir: `GET /finance/bank-statements/:id` (finance)
- **Adım:** Veri yüklenir: `GET /finance/payments/pending` (finance)
- **Adım:** Kart (satır 41): Ekstre yükle
- **Adım:** Dosya seçme (satır 44)
- **Adım:** Kart (satır 55): Yüklenen ekstreler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Dosya \| Yükleme \| Hareket \| Durum
- **Adım:** Kart (satır 69): Hareketler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Satır \| Tarih \| Tutar \| Açıklama \| Durum \| Ödeyen
- **Adım:** Bilgi notu (satır 102): Hareket: {date(pick.line.date)} · {kurus(pick.line.amount_kurus)} · {pick.line.description
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Veri yüklenir: `GET /finance/units/:id/open-assessments` (finance)
- **Adım:** Bilgi notu (satır 44): Hareket: {date(line.date)} · {kurus(line.amount_kurus)} · {line.description}. Seçtiğiniz b
- **Adım:** Bilgi notu (satır 45): Sakinin bildirim yapmadığı havale/EFT ya da elden ödeme içindir. Kayıt silinemez; hata anc
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-00`

#### P-ACCOUNTING-01 · Düğme: {p.receipt_count} dosya
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "{p.receipt_count} dosya" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-01`

#### P-ACCOUNTING-02 · Düğme: Ters kayıt
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Ters kayıt" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-02`

#### P-ACCOUNTING-03 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-03`

#### P-ACCOUNTING-04 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen (yazma):** `POST /finance/payments/:id/reject` (finance, `services/finance/main.go:140`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payments_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/payments/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Sakin `dues_payment_screen`, Sakin `payment_history_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/payments/:id/reject` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-04`

#### P-ACCOUNTING-05 · Düğme: Tahsilat gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Tahsilat gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-05`

#### P-ACCOUNTING-06 · Düğme: Daha eskileri göster
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Daha eskileri göster" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-06`

#### P-ACCOUNTING-07 · Düğme: Zinciri doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Zinciri doğrula" düğme öğesine bas
- **Beklenen (okuma):** `GET /finance/ledger/verify` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-07`

#### P-ACCOUNTING-08 · Düğme: İndir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "İndir" düğme öğesine bas
- **Beklenen (okuma):** `GET /finance/payments/:id/receipts/:receiptId/download` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-08`

#### P-ACCOUNTING-09 · Form: Ödemeyi onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Dekont / işlem numarası (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "${tl(confirming.amount)} tahsilat onaylandı"
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/payments/:id/confirm` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-09`

#### P-ACCOUNTING-10 · Form: Ödemenin ters kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/payments/:id/reverse` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-10`

#### P-ACCOUNTING-11 · Düğme: Dekont kes
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Dekont kes" düğme öğesine bas
- **Adım:** Öğe `credit-notes-card` bileşenindedir (satır 27)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-11`

#### P-ACCOUNTING-12 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "PDF" düğme öğesine bas
- **Adım:** Öğe `credit-notes-card` bileşenindedir (satır 39)
- **Beklenen (okuma):** `GET /finance/credit-notes/:id/pdf` (finance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-12`

#### P-ACCOUNTING-13 · Düğme: Ters kayıt
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Ters kayıt" düğme öğesine bas
- **Adım:** Öğe `credit-notes-card` bileşenindedir (satır 40)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-13`

#### P-ACCOUNTING-14 · Form: Alacak dekontu kes
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Daire*, Tahakkuk*, Tutar (TL)*, Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `credit-notes-card` bileşenindedir (satır 48)
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/credit-notes` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-14`

#### P-ACCOUNTING-15 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Dekontun ters kaydı yapıldı; borç geri yüklendi"
- **Adım:** Öğe `credit-notes-card` bileşenindedir (satır 79)
- **Beklenen (yazma):** `POST /finance/credit-notes/:id/reverse` (finance, `services/finance/main.go:149`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `credit_notes_guard`, `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `credit_notes` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM credit_notes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/credit-notes/:id/reverse' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/credit-notes/:id/reverse` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-15`

#### P-ACCOUNTING-16 · Düğme: Yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Yükle" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 45)
- **Beklenen (yazma):** `POST /finance/bank-statements` (finance, `services/finance/main.go:150`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bank_statement_imports` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bank_statement_imports ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Yön.mobil `finance_tools_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/bank-statements` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-16`

#### P-ACCOUNTING-17 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Aç" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 63)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-17`

#### P-ACCOUNTING-18 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Onayla" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 82)
- **Beklenen (yazma):** `POST /finance/bank-statements/lines/:id/confirm` (finance, `services/finance/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements/lines/:id/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/bank-statements/lines/:id/confirm` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-18`

#### P-ACCOUNTING-19 · Düğme: Ödeme seç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Ödeme seç" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 83)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-19`

#### P-ACCOUNTING-20 · Düğme: Daireye işle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Daireye işle" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 84)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-20`

#### P-ACCOUNTING-21 · Düğme: Yok say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** "Yok say" düğme öğesine bas
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 85)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-21`

#### P-ACCOUNTING-22 · Form: Ödeme bildirimiyle eşleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Onay bekleyen ödeme* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ödeme onaylandı ve borçtan düşüldü"
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 94)
- **Beklenen (yazma):** `POST /finance/bank-statements/lines/:id/confirm` (finance, `services/finance/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `payments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `finance_ledger` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM finance_ledger ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `bank_statement_lines` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements/lines/:id/confirm' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `payment_history_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `dashboard_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/bank-statements/lines/:id/confirm` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-22`

#### P-ACCOUNTING-23 · Form: Hareketi yok say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Satır yok sayıldı"
- **Adım:** Öğe `bank-statement-card` bileşenindedir (satır 113)
- **Beklenen (yazma):** `POST /finance/bank-statements/lines/:id/ignore` (finance, `services/finance/main.go:152`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `bank_statement_lines` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM bank_statement_lines ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/bank-statements/lines/:id/ignore' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Yön.mobil `finance_tools_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/bank-statements/lines/:id/ignore` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-23`

#### P-ACCOUNTING-24 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/accounting
- **Adım:** Formu aç; alanlar: Daire*, Ödeme yöntemi*, Ödeme günü*, Açıklama / makbuz no (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `collection-modal` bileşenindedir (satır 31)
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/bank-statements/lines/:id/collect` yalnız BOARD_MEMBER/MANAGER). DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/collections` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ACCOUNTING-24`

---

### Aidat Tahakkuku — `/dashboard/assessments`
- Dosya: `admin/src/app/(dashboard)/dashboard/assessments/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Tahakkuk kayıtları

#### P-ASSESSMENTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** http://localhost:3001/dashboard/assessments adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /finance/assessments/overview` (finance)
- **Adım:** Veri yüklenir: `GET /finance/expense-categories` (finance)
- **Adım:** Kart (satır 48): Dönemler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Dönem \| Vade \| Tahakkuk \| Tahsil edilen \| Oran \| Durum
- **Adım:** Kart (satır 70): Gecikme tazminatı (KMK m.20/2)
- **Adım:** Bilgi notu (satır 135): Her kalemde sınıf seçin: kullanım giderini daireyi kullanan (kiracı ya da oturan malik), m
- **Adım:** Veri yüklenir: `GET /finance/opening-balances` (finance)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Kart (satır 40): Devir bakiyeleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Tutar \| Ödenen \| Vade \| Açıklama \| Sınıf
- **Adım:** Bilgi notu (satır 87): Devir tutarına önceki yönetimin işlettiği gecikme tazminatı dahil edilmelidir; sistem devr
- **Adım:** Bilgi notu (satır 98): Düzeltilmesi gereken satırlar: {errors.slice(0, 10).join(" · "}
- **Adım:** Bilgi notu (satır 99): {items.length} daire, toplam {tl(items.reduce((a, x) => a + }.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-00`

#### P-ASSESSMENTS-01 · Düğme: Tahakkuk oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "Tahakkuk oluştur" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-01`

#### P-ASSESSMENTS-02 · Düğme: Tazminatı işlet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "Tazminatı işlet" düğme öğesine bas
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/late-fees/accrue` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-02`

#### P-ASSESSMENTS-03 · Form: Tahakkuk oluştur
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** Formu aç; alanlar: Yıl*, Ay*, Son ödeme* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/assessments` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-03`

#### P-ASSESSMENTS-04 · Düğme: Kalemi çıkar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "Kalemi çıkar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-04`

#### P-ASSESSMENTS-05 · Düğme: + Kalem
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "+ Kalem" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-05`

#### P-ASSESSMENTS-06 · Düğme: Devir gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "Devir gir" düğme öğesine bas
- **Adım:** Öğe `opening-balances` bileşenindedir (satır 42)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-06`

#### P-ASSESSMENTS-07 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** "İptal" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Adım:** Öğe `opening-balances` bileşenindedir (satır 61)
- **Beklenen (yazma):** `POST /finance/opening-balances/:id/cancel` (finance, `services/finance/main.go:146`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `monthly_assessments` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/opening-balances/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/opening-balances/:id/cancel` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-07`

#### P-ASSESSMENTS-08 · Form: Devir bakiyesi gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assessments
- **Adım:** Formu aç; alanlar: Vade tarihi*, Gider sınıfı* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `opening-balances` bileşenindedir (satır 72)
- **Beklenen (yazma):** `POST /finance/opening-balances` (finance, `services/finance/main.go:145`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `monthly_assessments_active_property`, `monthly_assessments_active_property_increase`, `monthly_assessments_guard`, `trg_monthly_assessments_tenant_link` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `monthly_assessments` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM monthly_assessments ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/finance/opening-balances' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `dues.created` → alıcı: borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/accounting`, Panel `/dashboard/assessments`, Panel `/dashboard/collection`, Panel `/dashboard/reports`, Sakin `dues_payment_screen`, Sakin `finance_screen`, Sakin `resident_home_screen`, Sakin `unit_residents_screen`, Yön.mobil `collection_entry_screen`, Yön.mobil `finance_screen`, Yön.mobil `finance_tools_screen`, Yön.mobil `payments_screen`, Yön.mobil `reports_screen`, Yön.mobil `smart_collection_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /finance/opening-balances` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSESSMENTS-08`

---

### Tahsilat Riski — `/dashboard/collection`
- Dosya: `admin/src/app/(dashboard)/dashboard/collection/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Tahsilat riski (kişisel mali veri)

#### P-COLLECTION-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/collection
- **Adım:** http://localhost:3001/dashboard/collection adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /collection/risk` (smart_collection)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Puan \| Risk \| Borç \| Ödenmemiş \| En uzun gecikme \| Öneri \| Etkenler
- **Adım:** Bilgi notu (satır 51): {d.method}
- **Adım:** Bilgi notu (satır 52): {d.action_note}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-COLLECTION-00`

#### P-COLLECTION-01 · Düğme: Bugünü kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/collection
- **Adım:** "Bugünü kaydet" düğme öğesine bas
- **Beklenen (yazma):** `POST /collection/risk/snapshot` (smart_collection, `services/smart_collection/main.go:120`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `payment_risk_scores` — satır silinmiş olmalı: `SELECT xmin, * FROM payment_risk_scores ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `payment_risk_scores` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payment_risk_scores ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/collection/risk/snapshot' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /collection/risk/snapshot` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-COLLECTION-01`

---

### Giderler — `/dashboard/expenses`
- Dosya: `admin/src/app/(dashboard)/dashboard/expenses/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Gider kayıtları

#### P-EXPENSES-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** http://localhost:3001/dashboard/expenses adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /expenses` (expense)
- **Adım:** Veri yüklenir: `GET /expenses/summary` (expense)
- **Adım:** Veri yüklenir: `GET /expense-categories` (expense)
- **Adım:** Veri yüklenir: `GET /expenses/:id` (expense)
- **Adım:** Kart (satır 44): Gider kayıtları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Açıklama \| Tutar \| Sınıf \| Fatura \| Durum
- **Adım:** Pencere (satır 118): Dağıtım
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Pay \| Ödendi
- **Adım:** Bilgi notu (satır 130): Dağıtım, gider onaylandığında oluşturulur.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-00`

#### P-EXPENSES-01 · Düğme: Gider ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** "Gider ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-01`

#### P-EXPENSES-02 · Düğme: Dağıtım
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** "Dağıtım" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-02`

#### P-EXPENSES-03 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen (yazma):** `POST /expenses/:id/approve` (expense, `services/expense/main.go:72`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expenses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /expenses/:id/approve` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-03`

#### P-EXPENSES-04 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-04`

#### P-EXPENSES-05 · Form: Gider ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** Formu aç; alanlar: Gider kalemi*, Tutar (TL)*, Gider tarihi*, Gider sınıfı*, Dağıtım, Tedarikçi, Fatura, Fatura no, Faturasız gider gerekçesi*, Açıklama* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Gider kaydedildi"
- **Beklenen (yazma):** `POST /expenses` (expense, `services/expense/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expense_distributions` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expense_distributions ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `expenses` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /expenses` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-05`

#### P-EXPENSES-06 · Form: Gideri reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/expenses
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Gider reddedildi"
- **Beklenen (yazma):** `POST /expenses/:id/reject` (expense, `services/expense/main.go:73`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `expense_updated_at` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `expenses` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM expenses ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/expenses/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/expenses`, Yön.mobil `expense_detail_screen`, Yön.mobil `expenses_screen`, Yön.mobil `resident_expenses_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /expenses/:id/reject` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-EXPENSES-06`

---

### Sayaç ve Isı Payı — `/dashboard/meters`
- Dosya: `admin/src/app/(dashboard)/dashboard/meters/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Sayaç okuma

#### P-METERS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** http://localhost:3001/dashboard/meters adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /meters` (iot)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Veri yüklenir: `GET /meter-readings` (iot)
- **Adım:** Veri yüklenir: `GET /consumption/statements` (iot)
- **Adım:** Veri yüklenir: `GET /consumption/objections` (iot)
- **Adım:** Veri yüklenir: `GET /consumption/area-check` (iot)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Sayaçlar, Okumalar, Gider paylaştırma, Tüketim pusulaları, Pusula itirazları
- **Adım:** Kart (satır 51): Sayaçlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Tür \| Seri no \| Son okuma \| Durum
- **Adım:** Kart (satır 77): Son okumalar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Daire \| Seri no \| Önceki \| Güncel \| Tüketim \| Tür \| Okuyan
- **Adım:** Kart (satır 96): Dönem giderini paylaştır
- **Adım:** Bilgi notu (satır 101): ${areaCheck.data.missing.length} bölümün net kullanım alanı eksik: {areaCheck.data.missing.slice(0} …. {areaCheck.data.note}{" "} Bağımsız Bölümler ekranında
- **Adım:** Bağlantı (satır 103): Bağımsız Bölümler ekranında tamamlayın. → /dashboard/units
- **Adım:** Bilgi notu (satır 134): {allocResult.warning}
- **Adım:** Bilgi notu (satır 136): Olağandışı tüketim — site medyanının 3 katından fazla: {allocResult.outliers.map((o) => `${o.unit_name}: ${num(o.intensity)}$/m² (medyan ${num(o.
- **Adım:** Bilgi notu (satır 140): {allocResult.basis_note} {allocResult.note}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| İlk okuma \| Son okuma \| Tüketim \| Alan (m²) \| Pay
- **Adım:** Kart (satır 156): Yayımlanmış tüketim pusulaları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Dönem \| Toplam gider \| Paylaşım \| Yayım
- **Adım:** Kart (satır 173): Tüketim pusulasına itirazlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire / pusula \| İtiraz eden \| Gerekçe \| Durum
- **Adım:** Bilgi notu (satır 197): Gerekçe: {answer.o.reason}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-00`

#### P-METERS-01 · Düğme: Sayaç ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Sayaç ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-01`

#### P-METERS-02 · Düğme: Okuma gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Okuma gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-02`

#### P-METERS-03 · Düğme: Sayaç değiştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Sayaç değiştir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-03`

#### P-METERS-04 · Düğme: Pasife al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Pasife al" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /meters/:id` (iot, `services/iot/main.go:212`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `meters` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM meters ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meters/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`DELETE /meters/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-04`

#### P-METERS-05 · Düğme: Hesapla ve yayımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Hesapla ve yayımla" düğme öğesine bas
- **Beklenen (yazma):** `POST /consumption/allocate` (iot, `services/iot/main.go:239`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `consumption_allocation_units` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM consumption_allocation_units ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `consumption_allocations` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM consumption_allocations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/consumption/allocate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Yön.mobil `meters_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /consumption/allocate` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-05`

#### P-METERS-06 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "PDF" düğme öğesine bas
- **Beklenen (okuma):** `GET /consumption/statements/:id/pdf` (iot) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-06`

#### P-METERS-07 · Düğme: Yanıtla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** "Yanıtla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-07`

#### P-METERS-08 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** Formu aç; alanlar: Karar*, Açıklama* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /consumption/objections/:id/respond` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-08`

#### P-METERS-09 · Form: Sayaç ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** Formu aç; alanlar: Daire*, Tür*, Seri no*, Marka (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Sayaç kaydedildi"
- **Beklenen (yazma):** `POST /meters` (iot, `services/iot/main.go:188`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `meters` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meters ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meters' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /meters` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-09`

#### P-METERS-10 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** Formu aç; alanlar: Endeks*, Okuma tarihi, Okuma türü (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /meter-readings` (iot, `services/iot/main.go:161`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `meter_readings` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meter_readings ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meter-readings' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-10`

#### P-METERS-11 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/meters
- **Adım:** Formu aç; alanlar: Eski sayacın söküm endeksi*, Değişim tarihi*, Yeni sayacın seri no*, Yeni sayacın montaj endeksi*, Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Sayaç değiştirildi"
- **Beklenen (yazma):** `POST /meters/:id/replace` (iot, `services/iot/main.go:142`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `meter_readings` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meter_readings ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `meter_replacements` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meter_replacements ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `meters` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM meters ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `meters` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM meters ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/meters/:id/replace' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/energy`, Panel `/dashboard/esg`, Panel `/dashboard/meters`, Sakin `energy_consumption_mobile_screen`, Sakin `my_meters_screen`, Yön.mobil `energy_dashboard_screen`, Yön.mobil `esg_screen`, Yön.mobil `meter_reading_screen`, Yön.mobil `meters_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-METERS-11`

---
