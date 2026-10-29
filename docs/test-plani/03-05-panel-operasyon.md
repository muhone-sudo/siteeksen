# 3.5 Panel — Operasyon

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Demirbaş — `/dashboard/assets`
- Dosya: `admin/src/app/(dashboard)/dashboard/assets/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Demirbaş ve bakım

#### P-ASSETS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** http://localhost:3001/dashboard/assets adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /assets` (asset)
- **Adım:** Veri yüklenir: `GET /assets-summary` (asset)
- **Adım:** Veri yüklenir: `GET /asset-categories` (asset)
- **Adım:** Veri yüklenir: `GET /assets/:id` (asset)
- **Adım:** Veri yüklenir: `GET /assets/:id/maintenance` (asset)
- **Adım:** Kart (satır 58): Demirbaşlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Demirbaş \| Alış \| Defter değeri \| Sonraki bakım \| Durum
- **Adım:** Bilgi notu (satır 104): Amortisman hesaplanamadı (alış tarihi/bedeli yok).
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tarih \| Tür \| Açıklama \| Yapan \| Maliyet
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-00`

#### P-ASSETS-01 · Düğme: Kategori
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "Kategori" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-01`

#### P-ASSETS-02 · Düğme: Demirbaş ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "Demirbaş ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-02`

#### P-ASSETS-03 · Düğme: Aç
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "Aç" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-03`

#### P-ASSETS-04 · Form: Demirbaş ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** Formu aç; alanlar: Ad*, Kategori, Demirbaş kodu, Seri no, Konum, Durum, Alış tarihi, Alış bedeli (TL), Tedarikçi, Garanti bitişi, Amortisman (yıl), Bakım aralığı (gün) (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Demirbaş kaydedildi"
- **Beklenen (yazma):** `POST /assets` (asset, `services/asset/main.go:202`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assets` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM assets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/assets' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /assets` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-04`

#### P-ASSETS-05 · Düğme: Bakım kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "Bakım kaydı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-05`

#### P-ASSETS-06 · Düğme: {detail.assigned_to ? `Zimmet: ${detail.assigned_to}` : "Zimmetle"}
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "{detail.assigned_to ? `Zimmet: ${detail.assigned_to}` : "Zimmetle"}" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-06`

#### P-ASSETS-07 · Düğme: Hurdaya ayır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** "Hurdaya ayır" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-07`

#### P-ASSETS-08 · Form: Bakım kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** Formu aç; alanlar: Tür, Tarih, İşçilik (TL), Parça (TL), Yapan, Yeni durum, Açıklama* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /assets/:id/maintenance` (asset, `services/asset/main.go:155`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `asset_maintenance` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM asset_maintenance ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `assets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/assets/:id/maintenance' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /assets/:id/maintenance` yalnız BOARD_MEMBER/MANAGER/STAFF).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-08`

#### P-ASSETS-09 · Form: Hurdaya ayır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** Formu aç; alanlar: Gerekçe*, Karar referansı* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Demirbaş hurdaya ayrıldı"
- **Beklenen (yazma):** `POST /assets/:id/dispose` (asset, `services/asset/main.go:237`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/assets/:id/dispose' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /assets/:id/dispose` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-09`

#### P-ASSETS-10 · Form: Demirbaş kategorisi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** Formu aç; alanlar: Ad*, Amortisman süresi (yıl), Açıklama (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kategori eklendi"
- **Beklenen (yazma):** `POST /asset-categories` (asset, `services/asset/main.go:183`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `asset_categories` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM asset_categories ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/asset-categories' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /asset-categories` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-10`

#### P-ASSETS-11 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/assets
- **Adım:** Formu aç; alanlar: Zimmetlenen kişi / birim (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /assets/:id/assign` (asset, `services/asset/main.go:220`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `assets` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM assets ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/assets/:id/assign' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/assets`, Yön.mobil `asset_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /assets/:id/assign` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-ASSETS-11`

---

### Stok — `/dashboard/inventory`
- Dosya: `admin/src/app/(dashboard)/dashboard/inventory/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Stok

#### P-INVENTORY-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** http://localhost:3001/dashboard/inventory adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /inventory` (inventory)
- **Adım:** Veri yüklenir: `GET /inventory-summary` (inventory)
- **Adım:** Veri yüklenir: `GET /inventory-movements` (inventory)
- **Adım:** Veri yüklenir: `GET /inventory-categories` (inventory)
- **Adım:** Veri yüklenir: `GET /inventory/:id/movements` (inventory)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Kalemler, Hareketler
- **Adım:** Kart (satır 63): Kalemler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kalem \| Stok \| Asgari \| Birim maliyet \| Değer
- **Adım:** Kart (satır 91): Son hareketler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Kalem \| Tür \| Miktar \| Stok \| Giren \| Not
- **Adım:** Bilgi notu (satır 147): Sayım düzeltmesi stoğu tek kalemde değiştirir; gerekçesi denetim için saklanır.
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Tür \| Miktar \| Stok \| Giren \| Not
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-00`

#### P-INVENTORY-01 · Düğme: Kategori
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** "Kategori" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-01`

#### P-INVENTORY-02 · Düğme: Kalem ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** "Kalem ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-02`

#### P-INVENTORY-03 · Düğme: Hareket
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** "Hareket" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-03`

#### P-INVENTORY-04 · Düğme: Geçmiş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** "Geçmiş" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-04`

#### P-INVENTORY-05 · Düğme: Pasife al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** "Pasife al" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-05`

#### P-INVENTORY-06 · Form: Stok kalemi ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** Formu aç; alanlar: Ad*, Birim*, Kategori, Stok kodu, Asgari stok, Konum (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kalem eklendi (açılış stoğu 0 — mevcut stoğu sayım düzeltmesiyle girin)"
- **Beklenen (yazma):** `POST /inventory` (inventory, `services/inventory/main.go:197`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_items` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM inventory_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /inventory` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-06`

#### P-INVENTORY-07 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** Formu aç; alanlar: Tür, Birim fiyat (TL), Dayanak (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /inventory/:id/movements` (inventory, `services/inventory/main.go:142`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF; işleyicide `isManagement` (backend/services/community/main.go:257)
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_movements` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM inventory_movements ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `inventory_items` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM inventory_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory/:id/movements' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `inventory.low_stock` → alıcı: yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'inventory.low_stock%' ORDER BY n.created_at DESC LIMIT 30;`
    - Şu hesaplarla bildirim kutusunda görünmeli: YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /inventory/:id/movements` yalnız BOARD_MEMBER/MANAGER/STAFF).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-07`

#### P-INVENTORY-08 · Form: Stok kategorisi ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** Formu aç; alanlar: Ad*, Açıklama (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kategori eklendi"
- **Beklenen (yazma):** `POST /inventory-categories` (inventory, `services/inventory/main.go:179`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_categories` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM inventory_categories ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory-categories' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /inventory-categories` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-08`

#### P-INVENTORY-09 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inventory
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kalem pasife alındı; hareket geçmişi korunur"
- **Beklenen (yazma):** `DELETE /inventory/:id` (inventory, `services/inventory/main.go:216`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `inventory_items` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM inventory_items ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/inventory/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`DELETE /inventory/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-INVENTORY-09`

---

### Kargo — `/dashboard/packages`
- Dosya: `admin/src/app/(dashboard)/dashboard/packages/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Kargo kabul ve teslim

#### P-PACKAGES-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** http://localhost:3001/dashboard/packages adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /packages` (package)
- **Adım:** Veri yüklenir: `GET /packages-summary` (package)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Kart (satır 46): Kargolar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Daire \| Alıcı \| Firma / takip \| Kabul \| Bekleme \| Durum
- **Adım:** Dosya seçme (satır 119)
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-00`

#### P-PACKAGES-01 · Düğme: Kargo kabul
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "Kargo kabul" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-01`

#### P-PACKAGES-02 · Düğme: Hatırlat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "Hatırlat" düğme öğesine bas
- **Beklenen (yazma):** `POST /packages/:id/notify` (package, `services/package/main.go:162`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/notify' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-02`

#### P-PACKAGES-03 · Düğme: Teslim et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "Teslim et" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-03`

#### P-PACKAGES-04 · Düğme: İade
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "İade" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-04`

#### P-PACKAGES-05 · Düğme: İmza
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "İmza" düğme öğesine bas
- **Beklenen (okuma):** `GET /packages/:id/proof/:kind` (package) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-05`

#### P-PACKAGES-06 · Düğme: Fotoğraf
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** "Fotoğraf" düğme öğesine bas
- **Beklenen (okuma):** `GET /packages/:id/proof/:kind` (package) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Beklenen (dosya):** dosya iner/açılır; boş ya da bozuk değildir (PDF ise sayfalar okunur).
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-06`

#### P-PACKAGES-07 · Form: Kargo kabul
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** Formu aç; alanlar: Daire*, Alıcı adı*, Kargo firması, Takip no, Tür, Konulduğu yer (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
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
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-07`

#### P-PACKAGES-08 · Form: Teslim et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** Formu aç; alanlar: Teslim alan kişi*, İmza, Paket fotoğrafı [dosya] (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Teslim kaydedildi (imza/fotoğraf yok)"
- **Beklenen (yazma):** `POST /packages/:id/deliver` (package, `services/package/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/deliver' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Beklenen (yazma):** `POST /packages/:id/deliver` (package, `services/package/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - Dosya depoya yazılır; ilgili ekranda indirilebilir olmalı
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/deliver' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-08`

#### P-PACKAGES-09 · Form: Kargo firmasına iade
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/packages
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İade kaydedildi"
- **Beklenen (yazma):** `POST /packages/:id/return` (package, `services/package/main.go:214`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `packages` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM packages ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/packages/:id/return' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/packages`, Panel `/dashboard/settings`, Sakin `package_tracking_mobile_screen`, Yön.mobil `package_tracking_screen`, Yön.mobil `site_settings_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PACKAGES-09`

---

### Otopark — `/dashboard/parking`
- Dosya: `admin/src/app/(dashboard)/dashboard/parking/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Otopark yönetimi

#### P-PARKING-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** http://localhost:3001/dashboard/parking adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /parking-logs` (parking)
- **Adım:** Veri yüklenir: `GET /vehicles` (parking)
- **Adım:** Veri yüklenir: `GET /parking-zones` (parking)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Kart (satır 57): Plaka sorgula
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: İçeridekiler, Kayıtlı araçlar, Bölgeler, Cihazlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Plaka \| Bölge \| Giriş \| Tür
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Plaka \| Daire \| Sahip \| Araç \| Durum
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Bölge \| Konum \| Doluluk \| Ücret
- **Adım:** Veri yüklenir: `GET /access-devices` (parking)
- **Adım:** Veri yüklenir: `GET /access-devices/incidents` (parking)
- **Adım:** Bilgi notu (satır 34): ${offline.length} cihaz çevrimdışı: {offline.map((d) => d.name).joi}. Geçişleri görevli elle kaydetmelidir; cihazı ve bağlantı
- **Adım:** Kart (satır 38): Geçiş cihazları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Cihaz \| Durum \| Son sinyal \| Eşik \| Bildirdiği durum
- **Adım:** Kart (satır 56): Çevrimdışı olayları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Cihaz \| Son sinyal \| Fark edildi \| Düzeldi
- **Adım:** Bilgi notu (satır 92): {issued.note}
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-00`

#### P-PARKING-01 · Düğme: Araç kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Araç kaydet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-01`

#### P-PARKING-02 · Düğme: Giriş kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Giriş kaydı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-02`

#### P-PARKING-03 · Düğme: Sorgula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Sorgula" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-03`

#### P-PARKING-04 · Düğme: Çıkış
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Çıkış" düğme öğesine bas
- **Beklenen (yazma):** `POST /parking-logs/:id/exit` (parking, `services/parking/main.go:184`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `parking_logs` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/parking-logs/:id/exit' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-04`

#### P-PARKING-05 · Düğme: Pasife al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Pasife al" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `DELETE /vehicles/:id` (parking, `services/parking/main.go:89`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `vehicles` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM vehicles ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/vehicles/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-05`

#### P-PARKING-06 · Form: Araç girişi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** Formu aç; alanlar: Plaka*, Bölge, Kapı (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Beklenen (yazma):** `POST /parking-logs/entry` (parking, `services/parking/main.go:145`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `parking_logs` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM parking_logs ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/parking-logs/entry' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-06`

#### P-PARKING-07 · Form: Araç kaydet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** Formu aç; alanlar: Plaka*, Daire, Sahip türü, Sahip adı, Araç türü, Park yeri, Marka, Model / renk (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Araç kaydedildi"
- **Beklenen (yazma):** `POST /vehicles` (parking, `services/parking/main.go:71`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `vehicles` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM vehicles ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/vehicles' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-07`

#### P-PARKING-08 · Düğme: Cihaz ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Cihaz ekle" düğme öğesine bas
- **Adım:** Öğe `devices-card` bileşenindedir (satır 39)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-08`

#### P-PARKING-09 · Düğme: Pasife al
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** "Pasife al" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Adım:** Öğe `devices-card` bileşenindedir (satır 49)
- **Beklenen (yazma):** `DELETE /access-devices/:id` (parking, `services/parking/devices.go:101`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `access_devices` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM access_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `device_incidents` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM device_incidents ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/access-devices/:id' ORDER BY created_at DESC LIMIT 5;` → `DELETE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`DELETE /access-devices/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-09`

#### P-PARKING-10 · Form: Geçiş cihazı ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/parking
- **Adım:** Formu aç; alanlar: Ad*, Tür, Konum, Sinyal aralığı (sn) (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Cihaz kaydedildi"
- **Adım:** Öğe `devices-card` bileşenindedir (satır 69)
- **Beklenen (yazma):** `POST /access-devices` (parking, `services/parking/devices.go:86`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `access_devices` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM access_devices ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/access-devices' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/parking`, Yön.mobil `parking_management_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /access-devices` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PARKING-10`

---

### Devriye — `/dashboard/patrol`
- Dosya: `admin/src/app/(dashboard)/dashboard/patrol/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Devriye

#### P-PATROL-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** http://localhost:3001/dashboard/patrol adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /patrols-summary` (patrol)
- **Adım:** Veri yüklenir: `GET /patrols` (patrol)
- **Adım:** Veri yüklenir: `GET /patrol-routes` (patrol)
- **Adım:** Veri yüklenir: `GET /patrol-checkpoints` (patrol)
- **Adım:** Bağlantı (satır 37): Raporlar ve harita → /dashboard/patrol/reports
- **Adım:** Bilgi notu (satır 44): {summary.data.warning}
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Turlar, Tur tanımları, Kontrol noktaları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Başlangıç \| Tur \| Görevli \| Nokta \| Süre \| Sorun \| Durum
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tur \| Noktalar \| Beklenen \| Durum
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Nokta \| Konum \| GPS
- **Adım:** Bilgi notu (satır 123): En doğru yöntem: yönetici uygulamasında Devriye → Nokta kurulumu → &quot;Konumu buradan al
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-00`

#### P-PATROL-01 · Düğme: Tüm QR&apos;ları yazdır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "Tüm QR&apos;ları yazdır" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-01`

#### P-PATROL-02 · Düğme: Kontrol noktası
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "Kontrol noktası" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-02`

#### P-PATROL-03 · Düğme: Tur tanımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "Tur tanımla" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-03`

#### P-PATROL-04 · Düğme: Konum / yarıçap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "Konum / yarıçap" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-04`

#### P-PATROL-05 · Düğme: QR yazdır
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "QR yazdır" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-05`

#### P-PATROL-06 · Düğme: QR yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** "QR yenile" düğme öğesine bas
- **Beklenen (yazma):** `POST /patrol-checkpoints/:id/rotate-qr` (patrol, `services/patrol/gps.go:101`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id/rotate-qr' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /patrol-checkpoints/:id/rotate-qr` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-06`

#### P-PATROL-07 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** Formu aç; alanlar: Enlem, Boylam, Yarıçap (m)*, Konum denetimi, Muafiyet gerekçesi* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Nokta güncellendi"
- **Beklenen (yazma):** `PATCH /patrol-checkpoints/:id` (patrol, `services/patrol/gps.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`PATCH /patrol-checkpoints/:id` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-07`

#### P-PATROL-08 · Form: Kontrol noktası
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** Formu aç; alanlar:  (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kontrol noktası eklendi"
- **Beklenen (yazma):** `POST /patrol-checkpoints` (patrol, `services/patrol/main.go:207`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_checkpoints` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_checkpoints ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-checkpoints' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `checkpoint_setup_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /patrol-checkpoints` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-08`

#### P-PATROL-09 · Form: Tur tanımla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/patrol
- **Adım:** Formu aç; alanlar: Ad*, Beklenen süre (dk), Tolerans (dk), Noktalar (sırasıyla) (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Tur tanımlandı"
- **Beklenen (yazma):** `POST /patrol-routes` (patrol, `services/patrol/main.go:236`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `patrol_routes` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM patrol_routes ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/patrol-routes' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/patrol/reports`, Panel `/dashboard/patrol`, Yön.mobil `patrol_control_screen`, Yön.mobil `patrol_report_screen`, Yön.mobil `patrol_run_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /patrol-routes` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-PATROL-09`

---

### Personel — `/dashboard/personnel`
- Dosya: `admin/src/app/(dashboard)/dashboard/personnel/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — Personel özlük ve maaş bilgileri

#### P-PERSONNEL-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** http://localhost:3001/dashboard/personnel adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /employees` (personnel)
- **Adım:** Veri yüklenir: `GET /employees/summary` (personnel)
- **Adım:** Veri yüklenir: `GET /leaves` (personnel)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Personel, İzinler, Bordro
- **Adım:** Kart (satır 69): Personel listesi
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ad Soyad \| TCKN \| İşe giriş \| Brüt maaş \| İzin (kalan) \| Durum
- **Adım:** Kart (satır 97): İzin talepleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Personel \| Tür \| Tarih \| Gün \| Durum
- **Adım:** Bilgi notu (satır 150): Kayıt silinmez; özlük dosyası yasal saklama süresince korunur.
- **Adım:** Pencere (satır 183): Maskesiz bilgiler
- **Adım:** Bilgi notu (satır 186): Bu görüntüleme denetim kaydına yazıldı (PII_REVEAL, KVKK m.12).
- **Adım:** Veri yüklenir: `GET /compliance-calendar` (personnel)
- **Adım:** Kart (satır 20): Vergi ve SGK yükümlülükleri
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Yükümlülük \| Son gün \| Durum \| Dayanak
- **Adım:** Veri yüklenir: `GET /payroll` (personnel)
- **Adım:** Kart (satır 31): Bordro kayıtları
- **Adım:** Bilgi notu (satır 45): Bu dönemde çalışıp bordrosu girilmemiş: {d.missing.join(", ")}
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Personel \| Net \| İşveren maliyeti \| Kaynak \| Durum
- **Adım:** Bilgi notu (satır 73): Tutarları mali müşavirin bordrosundan girin; sistem hesaplama ya da doğrulama yapmaz.
- **Adım:** Bilgi notu (satır 108): Kayıt silinmez; gerekçesiyle iptal edilmiş olarak kalır.
- **Adım:** Veri yüklenir: `GET /payroll/costs` (personnel)
- **Adım:** Kart (satır 119): Yıllık personel maliyeti
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Dönem \| Personel \| Net \| İşveren maliyeti
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-00`

#### P-PERSONNEL-01 · Düğme: İzin gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "İzin gir" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-01`

#### P-PERSONNEL-02 · Düğme: Personel ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Personel ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-02`

#### P-PERSONNEL-03 · Düğme: ?
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "?" düğme öğesine bas
- **Beklenen (okuma):** `GET /employees/:id` (personnel) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-03`

#### P-PERSONNEL-04 · Düğme: İlişik kes
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "İlişik kes" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-04`

#### P-PERSONNEL-05 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen (yazma):** `POST /leaves/:id/approve` (personnel, `services/personnel/main.go:84`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employee_leaves` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employee_leaves ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `employees` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/leaves/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-05`

#### P-PERSONNEL-06 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-06`

#### P-PERSONNEL-07 · Form: Personel ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Ad*, Soyad*, Görev*, Bölüm, İşe giriş*, Sözleşme, TCKN, Telefon, E-posta, Brüt maaş (TL), Net maaş (TL), Yıllık izin (gün), Banka, IBAN, SGK no (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Personel kaydedildi"
- **Beklenen (yazma):** `POST /employees` (personnel, `services/personnel/main.go:81`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employees` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/employees' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-07`

#### P-PERSONNEL-08 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Gerekçe*, Ayrılış tarihi (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ayrılış işlendi"
- **Beklenen (yazma):** `POST /employees/:id/terminate` (personnel, `services/personnel/main.go:82`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employees` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/employees/:id/terminate' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-08`

#### P-PERSONNEL-09 · Form: İzin gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Personel*, Tür, Başlangıç*, Bitiş* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İzin talebi oluşturuldu (onay bekliyor)"
- **Beklenen (yazma):** `POST /leaves` (personnel, `services/personnel/main.go:83`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employee_leaves` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM employee_leaves ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/leaves' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-09`

#### P-PERSONNEL-10 · Form: İzni reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "İzin reddedildi"
- **Beklenen (yazma):** `POST /leaves/:id/reject` (personnel, `services/personnel/main.go:85`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employee_leaves` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employee_leaves ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `employees` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/leaves/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-10`

#### P-PERSONNEL-11 · Düğme: Bildirge verildi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Bildirge verildi" düğme öğesine bas
- **Adım:** Öğe `compliance-card` bileşenindedir (satır 33)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-11`

#### P-PERSONNEL-12 · Form: SGK bildirgesi verildi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Bildirgenin verildiği tarih* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Bildirge tarihi kaydedildi"
- **Adım:** Öğe `compliance-card` bileşenindedir (satır 40)
- **Beklenen (yazma):** `POST /employees/:id/sgk` (personnel, `services/personnel/main.go:90`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `employees` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM employees ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/employees/:id/sgk' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-12`

#### P-PERSONNEL-13 · Düğme: Bordro gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Bordro gir" düğme öğesine bas
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 34)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-13`

#### P-PERSONNEL-14 · Düğme: Ödendi
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "Ödendi" düğme öğesine bas
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 54)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-14`

#### P-PERSONNEL-15 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** "İptal" düğme öğesine bas
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 55)
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-15`

#### P-PERSONNEL-16 · Form: Bordro gir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Personel*, Net ödenen (TL)*, İşveren maliyeti (TL)*, Ödeme tarihi, Bordronun kaynağı*, Ödeme referansı, Not (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 64)
- **Beklenen (yazma):** `POST /payroll` (personnel, `services/personnel/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payroll_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payroll` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM payroll ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/payroll' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-16`

#### P-PERSONNEL-17 · Form: Ödeme
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Ödeme tarihi*, Referans (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ödeme kaydedildi"
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 91)
- **Beklenen (yazma):** `POST /payroll/:id/pay` (personnel, `services/personnel/main.go:98`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payroll_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payroll` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payroll ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/payroll/:id/pay' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-17`

#### P-PERSONNEL-18 · Form: Bordro kaydını iptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Kayıt iptal edildi"
- **Adım:** Öğe `payroll-card` bileşenindedir (satır 102)
- **Beklenen (yazma):** `POST /payroll/:id/cancel` (personnel, `services/personnel/main.go:99`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - Veritabanı tetikleyicileri çalışır: `payroll_guard` (kısıtı ihlal eden deneme anlaşılır bir hata mesajıyla reddedilmeli)
  - **Veritabanı (Adminer → SQL komutu):**
    - `payroll` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM payroll ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/payroll/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/personnel`, Yön.mobil `personnel_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-PERSONNEL-18`

---

### Rezervasyon — `/dashboard/reservations`
- Dosya: `admin/src/app/(dashboard)/dashboard/reservations/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Rezervasyon yönetimi

#### P-RESERVATIONS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** http://localhost:3001/dashboard/reservations adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /reservations` (reservation)
- **Adım:** Veri yüklenir: `GET /facilities` (reservation)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Rezervasyonlar, Tesisler
- **Adım:** Kart (satır 30): Rezervasyonlar
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tesis \| Sakin \| Zaman \| Kişi \| Ücret \| Durum
- **Adım:** Kart (satır 62): Tesisler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Tesis \| Saat \| Kapasite \| Ücret \| Onay \| İptal \| Durum
- **Adım:** Bilgi notu (satır 66): Değişiklikler yalnızca bundan sonraki rezervasyonlara uygulanır.
- **Adım:** Bilgi notu (satır 104): Ücret hesaplanır ancak tahsil edilmez; çevrimiçi tahsilat bağlı değilse sakin ödemeyi yöne
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-00`

#### P-RESERVATIONS-01 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen (yazma):** `POST /reservations/:id/approve` (reservation, `services/reservation/main.go:283`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `reservations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM reservations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/reservations/:id/approve' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `reservation.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'reservation.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /reservations/:id/approve` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-01`

#### P-RESERVATIONS-02 · Düğme: Reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** "Reddet" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-02`

#### P-RESERVATIONS-03 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** "İptal" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-03`

#### P-RESERVATIONS-04 · Düğme: + Yeni tesis
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** "+ Yeni tesis" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-04`

#### P-RESERVATIONS-05 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-05`

#### P-RESERVATIONS-06 · Form: Rezervasyonu reddet
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** Formu aç; alanlar: Gerekçe* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Reddedildi; sakine gerekçeyle bildirim düştü"
- **Beklenen (yazma):** `POST /reservations/:id/reject` (reservation, `services/reservation/main.go:296`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `reservations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM reservations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/reservations/:id/reject' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** konu `reservation.decision` → alıcı: işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
    - Sorgu: `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'reservation.decision%' ORDER BY n.created_at DESC LIMIT 30;`
    - SMS/EMAIL kanalı satırı varsa: SMS kutusu (http://localhost:18000/sms) / Mailpit (http://localhost:18025) içinde metin doğru kişiye gitmiş olmalı. **SİTE_B hesabı bu bildirimi hiçbir yerde görmemeli.**
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /reservations/:id/reject` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-06`

#### P-RESERVATIONS-07 · Form: Rezervasyonu iptal et
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** Formu aç; alanlar: Gerekçe (* zorunlu)
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Rezervasyon iptal edildi"
- **Beklenen (yazma):** `POST /reservations/:id/cancel` (reservation, `services/reservation/main.go:238`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `canManage` (backend/services/reservation/main.go:441)
  - **Veritabanı (Adminer → SQL komutu):**
    - `reservations` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM reservations ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/reservations/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-07`

#### P-RESERVATIONS-08 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/reservations
- **Adım:** Formu aç; alanlar: Ad*, Kategori, Açılış*, Kapanış*, Bakım notu (sakinlere gösterilir)*, Açıklama, Kullanım kuralları (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Tesis eklendi; sakinler rezervasyon yapabilir"
- **Adım:** Öğe `facility-form` bileşenindedir (satır 58)
- **Beklenen (yazma):** `PATCH /facilities/:id` (reservation, `services/reservation/main.go:281`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Beklenen (yazma):** `POST /facilities` (reservation, `services/reservation/main.go:280`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `facilities` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `facilities` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM facilities ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/facilities' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/reservations`, Sakin `create_reservation_screen`, Sakin `my_reservations_screen`, Yön.mobil `reservation_management_screen`
- **Yetki (olumsuz):** GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`PATCH /facilities/:id` yalnız BOARD_MEMBER/MANAGER). GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /facilities` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-RESERVATIONS-08`

---

### Sensörler — `/dashboard/sensors`
- Dosya: `admin/src/app/(dashboard)/dashboard/sensors/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Sensörler ve alarmlar

#### P-SENSORS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** http://localhost:3001/dashboard/sensors adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /sensors` (iot)
- **Adım:** Veri yüklenir: `GET /iot/alerts` (iot)
- **Adım:** Veri yüklenir: `GET /sensors/:id/data` (iot)
- **Adım:** Kart (satır 46): Alarmlar
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Açık, Kapatılmış
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Açılış \| Sensör \| Olay \| Değer \| Durum \| Kapatma
- **Adım:** Kart (satır 68): Sensörler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ad \| Tür \| Konum \| Son değer \| Eşik \| Son sinyal \| Durum
- **Adım:** Bilgi notu (satır 94): Cihaz okumayı POST /api/v1/public/sensors/data ucuna X-Device-Key başlığı ve {"{\"value\":
- **Adım:** Pencere (satır 132): Cihaz anahtarı
- **Adım:** Bilgi notu (satır 135): Bu anahtar bir daha gösterilmez. Şimdi cihaza girin.
- **Adım:** Bilgi notu (satır 146): Liste 2000 okumayla sınırlandı.
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Değer
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-00`

#### P-SENSORS-01 · Düğme: Sensör ekle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Sensör ekle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-01`

#### P-SENSORS-02 · Düğme: Onayla
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Onayla" düğme öğesine bas
- **Beklenen (yazma):** `POST /iot/alerts/:id/acknowledge` (iot, `services/iot/sensors.go:263`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensor_alerts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/iot/alerts/:id/acknowledge' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /iot/alerts/:id/acknowledge` yalnız BOARD_MEMBER/MANAGER/STAFF).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-02`

#### P-SENSORS-03 · Düğme: Kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Kapat" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-03`

#### P-SENSORS-04 · Düğme: Geçmiş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Geçmiş" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-04`

#### P-SENSORS-05 · Düğme: Düzenle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Düzenle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile bu düğme GÖRÜNMEMELİ (yazma yalnız MANAGER/BOARD_MEMBER).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-05`

#### P-SENSORS-06 · Düğme: Anahtarı yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** "Anahtarı yenile" düğme öğesine bas
- **Beklenen (yazma):** `POST /sensors/:id/rotate-key` (iot, `services/iot/sensors.go:360`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors/:id/rotate-key' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /sensors/:id/rotate-key` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-06`

#### P-SENSORS-07 · Form: (başlık dinamik)
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** Formu aç; alanlar: Ad*, Tür*, Konum, Birim, Alt eşik, Üst eşik, Sinyal kesilme süresi (dk)*, Durum (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Sensör güncellendi; Sensör eklendi"
- **Beklenen (yazma):** `PATCH /sensors/:id` (iot, `services/iot/sensors.go:332`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors/:id' ORDER BY created_at DESC LIMIT 5;` → `UPDATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Beklenen (yazma):** `POST /sensors` (iot, `services/iot/sensors.go:303`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM sensors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/sensors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Yetki (olumsuz):** DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`PATCH /sensors/:id` yalnız BOARD_MEMBER/MANAGER). DENETÇİ, GÖREVLİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /sensors` yalnız BOARD_MEMBER/MANAGER).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-07`

#### P-SENSORS-08 · Form: Alarmı kapat
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/sensors
- **Adım:** Formu aç; alanlar: Ne yapıldı?* (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Alarm kapatıldı"
- **Beklenen (yazma):** `POST /iot/alerts/:id/close` (iot, `services/iot/sensors.go:277`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `sensor_alerts` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/iot/alerts/:id/close' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/sensors`, Yön.mobil `sensors_screen`
- **Yetki (olumsuz):** DENETÇİ ile aynı ekranda bu işlem yapılamamalı: düğme gizli/pasif olmalı ya da sunucu **403** dönmeli ve ekranda "yetkiniz yok" anlamında mesaj görünmeli; veritabanında değişiklik OLMAMALI (`POST /iot/alerts/:id/close` yalnız BOARD_MEMBER/MANAGER/STAFF).
- **Sonuç:** http://localhost:18000/sonuc → `P-SENSORS-08`

---

### Ziyaretçi — `/dashboard/visitors`
- Dosya: `admin/src/app/(dashboard)/dashboard/visitors/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/STAFF — Ziyaretçi kayıtları

#### P-VISITORS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** http://localhost:3001/dashboard/visitors adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /visitors` (visitor)
- **Adım:** Veri yüklenir: `GET /visitors/summary` (visitor)
- **Adım:** Veri yüklenir: `GET /units` (identity)
- **Adım:** Kart (satır 35): Geçiş kodu ile giriş
- **Adım:** Kart (satır 49): Ziyaretçiler
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Ziyaretçi \| Daire \| Beklenen \| Giriş / Çıkış \| Durum
- **Adım:** Pencere (satır 103): Geçiş kodu — ${pass?.name ?? ""}
- **Adım:** Bilgi notu (satır 109): Kod yalnızca şimdi gösterilir; ziyaretçiye siz iletin. Sistem ziyaretçiye SMS göndermez.
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-00`

#### P-VISITORS-01 · Düğme: Ziyaretçi kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "Ziyaretçi kaydı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-01`

#### P-VISITORS-02 · Düğme: Doğrula ve giriş yap
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "Doğrula ve giriş yap" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-02`

#### P-VISITORS-03 · Düğme: Giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "Giriş" düğme öğesine bas
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
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-03`

#### P-VISITORS-04 · Düğme: İptal
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "İptal" düğme öğesine bas (onay penceresi çıkarsa önce Vazgeç → hiçbir şey değişmemeli; sonra tekrar bas ve onayla)
- **Beklenen (yazma):** `POST /visitors/:id/cancel` (visitor, `services/visitor/main.go:200`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/cancel' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-04`

#### P-VISITORS-05 · Düğme: Kodu yenile
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "Kodu yenile" düğme öğesine bas
- **Beklenen (yazma):** `POST /visitors/:id/pass` (visitor, `services/visitor/main.go:198`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239)
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/pass' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-05`

#### P-VISITORS-06 · Düğme: Çıkış
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** "Çıkış" düğme öğesine bas
- **Beklenen (yazma):** `POST /visitors/:id/check-out` (visitor, `services/visitor/main.go:187`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: BOARD_MEMBER/MANAGER/STAFF
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors/:id/check-out' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-06`

#### P-VISITORS-07 · Form: Ziyaretçi kaydı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/visitors
- **Adım:** Formu aç; alanlar: Ad soyad*, Telefon, Ziyaret edilen daire, Firma, Araç plakası, Beklenen zaman, Amaç (* zorunlu)
- **Adım:** Zorunlu alanları boş bırakıp gönder → alan hatası/uyarı görünmeli, istek gitmemeli ya da 400/422 anlaşılır mesajla dönmeli; kayıt OLUŞMAMALI
- **Adım:** Gerçekçi değerlerle doldur ve gönder; kullanılan değerleri gözleme yaz
- **Adım:** Başarı mesajı tam olarak şu anlamda olmalı: "Ziyaretçi kaydedildi"
- **Beklenen (yazma):** `POST /visitors` (visitor, `services/visitor/main.go:100`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use`
  - **Veritabanı (Adminer → SQL komutu):**
    - `visitors` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
    - `visitors` — ilgili satır güncellenmiş olmalı: `SELECT xmin, * FROM visitors ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/visitors' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Yetki (olumsuz):** Kullanım kuralı (`resident_can_use`): kiracılı dairede (A-4) işlemi KİRACI yapar; MALİK_A4 ile denenince reddedilmeli.
- **Sonuç:** http://localhost:18000/sonuc → `P-VISITORS-07`

---
