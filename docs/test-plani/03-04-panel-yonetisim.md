# 3.4 Panel — Yönetişim (KMK)

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Sözleşmeler — `/dashboard/contracts`
- Dosya: `admin/src/app/(dashboard)/dashboard/contracts/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Sözleşmeler

#### P-CONTRACTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** http://localhost:3001/dashboard/contracts adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /contracts` (contract)
- **Adım:** Veri yüklenir: `GET /contracts-summary` (contract)
- **Adım:** Kart (satır 47): Sözleşmeler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Sözleşme \| Dönem \| Kalan \| Yenileme \| Tutar \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-00`

#### P-CONTRACTS-01 · Düğme: Süresi dolanları işle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** "Süresi dolanları işle" düğme öğesine bas
- **Beklenen (yazma):** `POST /contracts/expire-due` (contract, `services/contract/main.go:172`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/expire-due' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /contracts/expire-due` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-01`

#### P-CONTRACTS-02 · Düğme: Sözleşme ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** "Sözleşme ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-02`

#### P-CONTRACTS-03 · Düğme: Yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** "Yenile" düğme öğesine bas
- **Beklenen (yazma):** `POST /contracts/:id/renew` (contract, `services/contract/main.go:138`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/:id/renew' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /contracts/:id/renew` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-03`

#### P-CONTRACTS-04 · Düğme: Feshet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** "Feshet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-04`

#### P-CONTRACTS-05 · Form: Sözleşme ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** Formu aç; alanlar: Tür*, Başlık*, Karşı taraf*, Başlangıç*, Bitiş, İhbar süresi (gün), Otomatik yenileme, Yenileme süresi (ay), Ödeme, Aylık tutar (TL), Yıllık tutar (TL), Telefon, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Sözleşme kaydedildi"
- **Beklenen (yazma):** `POST /contracts` (contract, `services/contract/main.go:117`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /contracts` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-05`

#### P-CONTRACTS-06 · Form: Sözleşmeyi feshet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/contracts
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Fesih kaydedildi"
- **Beklenen (yazma):** `POST /contracts/:id/terminate` (contract, `services/contract/main.go:151`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `contracts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM contracts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/contracts/:id/terminate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/contracts`, Yön.mobil `contract_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /contracts/:id/terminate` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-CONTRACTS-06`

---

### Belge Arşivi — `/dashboard/documents`
- Dosya: `admin/src/app/(dashboard)/dashboard/documents/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Belge arşivi

#### P-DOCUMENTS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** http://localhost:3001/dashboard/documents adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /documents` (document)
- **Adım:** Veri yüklenir: `GET /documents-summary` (document)
- **Adım:** Veri yüklenir: `GET /documents/:id/access-log` (document)
- **Adım:** Kart (satır 54): Belgeler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Belge \| Kategori \| Görünürlük \| Yükleme
- **Adım:** Dosya seçme (satır 89)
- **Adım:** Pencere (satır 106): Erişim kaydı — ${logFor?.title ?? ""}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Kişi \| İşlem \| IP
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-00`

#### P-DOCUMENTS-01 · Düğme: Belge yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** "Belge yükle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-01`

#### P-DOCUMENTS-02 · Düğme: ?
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** "?" düğme öğesine bas
- **Beklenen (okuma):** `GET /documents/:id/download` (document) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-02`

#### P-DOCUMENTS-03 · Düğme: Erişim
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** "Erişim" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-03`

#### P-DOCUMENTS-04 · Düğme: Arşivle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** "Arşivle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-04`

#### P-DOCUMENTS-05 · Form: Belge yükle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** Formu aç; alanlar: Dosya*, Kategori*, Görünürlük, Başlık, Saklama bitişi, Açıklama [dosya] (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /documents` (document, `services/document/main.go:171`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `documents_supersede` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `documents` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/documents' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/documents`, Sakin `documents_screen`, Yön.mobil `documents_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /documents` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-05`

#### P-DOCUMENTS-06 · Form: Belgeyi arşivle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/documents
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Arşivlendi (silinmedi)"
- **Beklenen (yazma):** `POST /documents/:id/archive` (document, `services/document/main.go:266`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `documents_supersede` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `documents` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM documents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/documents/:id/archive' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/documents`, Sakin `documents_screen`, Yön.mobil `documents_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /documents/:id/archive` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-DOCUMENTS-06`

---

### Genel Kurul — `/dashboard/governance/assemblies`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/assemblies/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-ASSEMBLIES-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** http://localhost:3001/dashboard/governance/assemblies adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/assemblies` (governance)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tür \| Yer \| Çağrı \| Durum \| Nisap
- **Adım:** Veri yüklenir: `GET /governance/assemblies/:id` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies/:id/attendees` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies/:id/quorum` (governance)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Veri yüklenir: `GET /residents` (identity)
- **Adım:** Pencere (satır 112): Genel kurul
- **Adım:** Bilgi notu (satır 127): Nisap: ${quorum.data.met ? "sağlanıyor" : "sağlanmıyor"}: Katılım {quorum.data.attended_units}/{quorum.data.total_units} daire, arsa payı {num(quoru
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Gündem ve kararlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: # \| Madde \| Nisap \| Oylar (lehte/aleyhte/çekimser) \| Karar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Katılan \| Katılım \| Arsa payı
- **Adım:** Pencere (satır 214): Karar
- **Adım:** Bilgi notu (satır 217): {result.explanation}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-00`

#### P-GOVERNANCE-ASSEMBLIES-01 · Düğme: Toplantı planla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Toplantı planla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-01`

#### P-GOVERNANCE-ASSEMBLIES-02 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-02`

#### P-GOVERNANCE-ASSEMBLIES-03 · Form: Toplantı planla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** Formu aç; alanlar: Tür, Toplantı, Tarih ve saat*, Yer (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Toplantı planlandı"
- **Beklenen (yazma):** `POST /governance/assemblies` (governance, `services/governance/main.go:95`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assemblies` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assemblies ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `assembly_agenda_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assembly_agenda_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/assemblies` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-03`

#### P-GOVERNANCE-ASSEMBLIES-04 · Düğme: Maddeyi çıkar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Maddeyi çıkar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-04`

#### P-GOVERNANCE-ASSEMBLIES-05 · Düğme: + Madde
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "+ Madde" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-05`

#### P-GOVERNANCE-ASSEMBLIES-06 · Düğme: Çağrıyı kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Çağrıyı kaydet" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/assemblies/:id/notify` (governance, `services/governance/main.go:96`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assemblies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assemblies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/assemblies/:id/notify` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-06`

#### P-GOVERNANCE-ASSEMBLIES-07 · Düğme: Toplantıyı yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Toplantıyı yap" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/assemblies/:id/hold` (governance, `services/governance/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assemblies` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assemblies ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/hold' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/assemblies/:id/hold` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-07`

#### P-GOVERNANCE-ASSEMBLIES-08 · Düğme: Oy gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Oy gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-08`

#### P-GOVERNANCE-ASSEMBLIES-09 · Düğme: Kararı hesapla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Kararı hesapla" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/agenda-items/:itemId/close` (governance, `services/governance/main.go:100`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `book_entries_no_update` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `book_entries` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM book_entries ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `books` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM books ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `assembly_agenda_items` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assembly_agenda_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/agenda-items/:itemId/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/books`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/agenda-items/:itemId/close` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-09`

#### P-GOVERNANCE-ASSEMBLIES-10 · Düğme: Ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** "Ekle" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/assemblies/:id/attendees` (governance, `services/governance/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assembly_attendees` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assembly_attendees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/assemblies/:id/attendees' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/reports`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/assemblies/:id/attendees` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-10`

#### P-GOVERNANCE-ASSEMBLIES-11 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/assemblies
- **Adım:** Formu aç; alanlar: Daire (hazirundan)*, Oy (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Oy kaydedildi"
- **Beklenen (yazma):** `POST /governance/agenda-items/:itemId/votes` (governance, `services/governance/main.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assembly_votes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assembly_votes ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `assembly_agenda_items` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assembly_agenda_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/agenda-items/:itemId/votes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/assemblies`, Panel `/dashboard/governance/budgets`, Panel `/dashboard/governance/common-area`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/agenda-items/:itemId/votes` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-ASSEMBLIES-11`

---

### Defterler — `/dashboard/governance/books`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/books/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-BOOKS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** http://localhost:3001/dashboard/governance/books adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/books/:id/entries` (governance)
- **Adım:** Kart (satır 51): ${book.kind === "DECISION" ? "Karar defteri" : "İşletme defteri"} ${book.period_year}
- **Adım:** Bilgi notu (satır 68): {integrity.message}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: No \| Tarih \| Kayıt \| Hash \| Oluşturma
- **Adım:** Bilgi notu (satır 89): Kayıt eklendikten sonra DEĞİŞTİRİLEMEZ ve SİLİNEMEZ. Düzeltme gerekirse yeni bir kayıtla y
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-00`

#### P-GOVERNANCE-BOOKS-01 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-01`

#### P-GOVERNANCE-BOOKS-02 · Düğme: Bütünlüğü doğrula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** "Bütünlüğü doğrula" düğme öğesine bas
- **Beklenen (okuma):** `GET /governance/books/:id/verify` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-02`

#### P-GOVERNANCE-BOOKS-03 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** "PDF" düğme öğesine bas
- **Beklenen (okuma):** `GET /governance/books/:id/export` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-03`

#### P-GOVERNANCE-BOOKS-04 · Düğme: Kayıt ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** "Kayıt ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-04`

#### P-GOVERNANCE-BOOKS-05 · Düğme: Notere kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** "Notere kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-05`

#### P-GOVERNANCE-BOOKS-06 · Form: Deftere kayıt ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** Formu aç; alanlar: Başlık*, Metin*, Tarih (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /governance/books/:id/entries` (governance, `services/governance/main.go:103`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `book_entries_no_update` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `book_entries` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM book_entries ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/books/:id/entries' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/books`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/books/:id/entries` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-06`

#### P-GOVERNANCE-BOOKS-07 · Form: Defteri notere kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/books
- **Adım:** Formu aç; alanlar: Noter kapanış no, Kapanış tarihi (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /governance/books/:id/close` (governance, `services/governance/main.go:104`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `books` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM books ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/books/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/books`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/books/:id/close` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BOOKS-07`

---

### İşletme Projesi — `/dashboard/governance/budgets`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/budgets/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-BUDGETS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** http://localhost:3001/dashboard/governance/budgets adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/budgets` (governance)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Yıl \| Toplam \| Durum \| Bildirim \| Genel kurul son gün \| Kesinleşme
- **Adım:** Bilgi notu (satır 88): Kapıcı, kaloriferci, bahçıvan ve bekçi giderleri eşit; sigorta ve ortak yer bakım/onarım g
- **Adım:** Veri yüklenir: `GET /governance/budgets/:id` (governance)
- **Adım:** Veri yüklenir: `GET /governance/budgets/:id/objections` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies/:id` (governance)
- **Adım:** Pencere (satır 113): İşletme projesi
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Kalemler, Daire payları, İtirazlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kalem \| Tutar \| Dağıtım \| Tür \| Sınıf
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Yıllık \| Aylık \| Döküm
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Gerekçe \| Süre \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-00`

#### P-GOVERNANCE-BUDGETS-01 · Düğme: Proje hazırla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Proje hazırla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-01`

#### P-GOVERNANCE-BUDGETS-02 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-02`

#### P-GOVERNANCE-BUDGETS-03 · Form: İşletme projesi hazırla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** Formu aç; alanlar: Dönem yılı*, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /governance/budgets` (governance, `services/governance/main.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budget_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budget_unit_shares` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budget_unit_shares ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `operating_budgets` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/budgets` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-03`

#### P-GOVERNANCE-BUDGETS-04 · Düğme: Kalemi çıkar
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Kalemi çıkar" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-04`

#### P-GOVERNANCE-BUDGETS-05 · Düğme: + Kalem
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "+ Kalem" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-05`

#### P-GOVERNANCE-BUDGETS-06 · Düğme: PDF
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "PDF" düğme öğesine bas
- **Beklenen (okuma):** `GET /governance/budgets/:id/export` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-06`

#### P-GOVERNANCE-BUDGETS-07 · Düğme: Excel
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Excel" düğme öğesine bas
- **Beklenen (okuma):** `GET /governance/budgets/:id/export` (governance) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-07`

#### P-GOVERNANCE-BUDGETS-08 · Düğme: Geçici proje olarak bildir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Geçici proje olarak bildir" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/budgets/:id/notify` (governance, `services/governance/main.go:90`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budgets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/budgets/:id/notify` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-08`

#### P-GOVERNANCE-BUDGETS-09 · Düğme: Genel kurul kararıyla kesinleştir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Genel kurul kararıyla kesinleştir" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/budgets/:id/finalize` (governance, `services/governance/main.go:91`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `operating_budgets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM operating_budgets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/finalize' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Panel `/dashboard/reports`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/budgets/:id/finalize` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-09`

#### P-GOVERNANCE-BUDGETS-10 · Düğme: Projeden aylık aidat tahakkuk et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Projeden aylık aidat tahakkuk et" düğme öğesine bas
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
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/budgets/:id/assessments` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-10`

#### P-GOVERNANCE-BUDGETS-11 · Düğme: Kabul
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Kabul" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-11`

#### P-GOVERNANCE-BUDGETS-12 · Düğme: Ret
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** "Ret" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-12`

#### P-GOVERNANCE-BUDGETS-13 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/budgets
- **Adım:** Formu aç; alanlar: Karar açıklaması (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İtiraz sonuçlandırıldı"
- **Beklenen (yazma):** `PATCH /governance/budgets/:id/objections/:objectionId` (governance, `services/governance/main.go:93`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `budget_objections` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM budget_objections ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/budgets/:id/objections/:objectionId' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/budgets`, Sakin `my_budgets_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`PATCH /governance/budgets/:id/objections/:objectionId` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-BUDGETS-13`

---

### Ortak Alan Geliri — `/dashboard/governance/common-area`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/common-area/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-COMMON-AREA-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** http://localhost:3001/dashboard/governance/common-area adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/common-area/leases` (governance)
- **Adım:** Veri yüklenir: `GET /governance/common-area/report` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies` (governance)
- **Adım:** Veri yüklenir: `GET /governance/assemblies/:id` (governance)
- **Adım:** Bilgi notu (satır 37): Ortak yerin kiraya verilmesi bütün kat maliklerinin oybirliğini ister (KMK m.45). Sığınak 
- **Adım:** Kart (satır 38): Kiralamalar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Alan \| Kiracı \| Başlangıç \| Aylık kira \| Karar \| Toplam gelir \| Durum
- **Adım:** Kart (satır 62): Kat maliki payları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Malik(ler) \| Brüt pay \| Stopaj \| Net
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-00`

#### P-GOVERNANCE-COMMON-AREA-01 · Düğme: Kiralama kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** "Kiralama kaydet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-01`

#### P-GOVERNANCE-COMMON-AREA-02 · Düğme: Tahsilat gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** "Tahsilat gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-02`

#### P-GOVERNANCE-COMMON-AREA-03 · Düğme: Sonlandır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** "Sonlandır" düğme öğesine bas
- **Beklenen (yazma):** `POST /governance/common-area/leases/:id/end` (governance, `services/governance/main.go:109`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `common_area_leases` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM common_area_leases ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/common-area/leases/:id/end' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/common-area`, Sakin `common_income_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/common-area/leases/:id/end` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-03`

#### P-GOVERNANCE-COMMON-AREA-04 · Form: Ortak yer kiralaması
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** Formu aç; alanlar: Alan türü, Alan adı*, Kiracı*, Aylık kira (TL)*, Başlangıç*, Kiracı işyeri mi?, Genel kurul, Oybirliğiyle kabul edilen madde* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kiralama kaydedildi"
- **Beklenen (yazma):** `POST /governance/common-area/leases` (governance, `services/governance/main.go:108`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `common_area_leases` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM common_area_leases ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/common-area/leases' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/common-area`, Sakin `common_income_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/common-area/leases` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-04`

#### P-GOVERNANCE-COMMON-AREA-05 · Form: Kira tahsilatı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/common-area
- **Adım:** Formu aç; alanlar: Dönem*, Tahsilat tarihi*, Brüt kira (TL)*, Kiracının kestiği stopaj (TL) (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /governance/common-area/leases/:id/incomes` (governance, `services/governance/main.go:110`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `common_area_income_shares` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM common_area_income_shares ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `common_area_incomes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM common_area_incomes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/common-area/leases/:id/incomes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/common-area`, Sakin `common_income_screen`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/common-area/leases/:id/incomes` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-COMMON-AREA-05`

---

### İcra ve Dava — `/dashboard/governance/legal`
- Dosya: `admin/src/app/(dashboard)/dashboard/governance/legal/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)

#### P-GOVERNANCE-LEGAL-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/governance/legal
- **Adım:** http://localhost:3001/dashboard/governance/legal adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /governance/legal-cases` (governance)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tür \| Daire \| Anapara \| Gecikme tazminatı \| Dayanak \| Daire / mahkeme \| Durum \| Açılış
- **Adım:** Bilgi notu (satır 82): Anapara ve gecikme tazminatı, dairenin ödenmemiş tahakkuklarından otomatik hesaplanır.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-LEGAL-00`

#### P-GOVERNANCE-LEGAL-01 · Düğme: Takip aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/legal
- **Adım:** "Takip aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-LEGAL-01`

#### P-GOVERNANCE-LEGAL-02 · Form: Hukuki takip aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/governance/legal
- **Adım:** Formu aç; alanlar: Daire*, Tür, Dayanak belge, İcra dairesi / mahkeme, Dosya no, Avukat, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /governance/legal-cases` (governance, `services/governance/main.go:106`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `legal_cases` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM legal_cases ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/governance/legal-cases' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/governance/legal`, Yön.mobil `governance_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /governance/legal-cases` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-GOVERNANCE-LEGAL-02`

---
