# 3.7 Panel — Sistem

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### İşlem Kayıtları — `/dashboard/audit`
- Dosya: `admin/src/app/(dashboard)/dashboard/audit/page.tsx`
- Panel erişimi: MANAGER/AUDITOR — İşlem kayıtları (kişisel veri içerir; KMK m.41 denetçi)

#### P-AUDIT-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra DENETÇİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** http://localhost:3001/dashboard/audit adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /audit-logs` (settings)
- **Adım:** Veri yüklenir: `GET /audit-logs/stats` (settings)
- **Adım:** Bilgi notu (satır 33): Kayıt düzeyi: list.data.level . Düzey Ayarlar &apos;dan (yalnız site yöneticisi) değiştiri
- **Adım:** Bağlantı (satır 34): Ayarlar → /dashboard/settings
- **Adım:** Kart (satır 39): Son ${d.period_days} gün
- **Adım:** Kart (satır 46): Süzgeç
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Kullanıcı \| Kaynak \| İşlem \| Olay \| Modül \| Ekran / yol \| Kod
- **Adım:** Pencere (satır 88): Kayıt ayrıntısı
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KURUL, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-00`

#### P-AUDIT-01 · Düğme: CSV indir
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "CSV indir" düğme öğesine bas
- **Beklenen (okuma):** `GET /audit-logs/export` (settings) — veri yüklenir; boşsa "kayıt yok" türü boş durum mesajı; hata varsa anlaşılır Türkçe mesaj (ham JSON/stack değil).
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-01`

#### P-AUDIT-02 · Düğme: Uygula
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "Uygula" düğme öğesine bas
- **Beklenen:** sunucuya istek gitmez; pencere/ekran/sekme hatasız açılır, içeriği doğru başlık ve alanlarla görünür, kapatma/geri dönme çalışır.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-02`

#### P-AUDIT-03 · Düğme: Temizle
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "Temizle" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-03`

#### P-AUDIT-04 · Düğme: Ayrıntı
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "Ayrıntı" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-04`

#### P-AUDIT-05 · Düğme: Önceki
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "Önceki" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-05`

#### P-AUDIT-06 · Düğme: Sonraki
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/audit
- **Adım:** "Sonraki" düğme öğesine bas
- **Beklenen:** pencere/form hatasız açılır, alan adları ve açıklamaları anlaşılır; Vazgeç/kapat ile hiçbir kayıt oluşmadan kapanır. Formun gönderimi aynı ekrandaki "Form: …" testindedir.
- **Sonuç:** http://localhost:18000/sonuc → `P-AUDIT-06`

---

### Bildirimlerim — `/dashboard/inbox`
- Dosya: `admin/src/app/(dashboard)/dashboard/inbox/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli

#### P-INBOX-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/inbox
- **Adım:** http://localhost:3001/dashboard/inbox adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /notifications` (notification)
- **Adım:** Her sekmeye tıkla, içerik hatasız yüklenir: Okunmamış, Tümü
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Zaman \| Konu \| İçerik \| Durum
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-INBOX-00`

#### P-INBOX-01 · Düğme: Tümünü okundu say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inbox
- **Adım:** "Tümünü okundu say" düğme öğesine bas
- **Beklenen (yazma):** `POST /notifications/read-all` (notification, `services/notification/main.go:97`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications/read-all' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-INBOX-01`

#### P-INBOX-02 · Düğme: Okundu say
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/dashboard/inbox
- **Adım:** "Okundu say" düğme öğesine bas
- **Beklenen (yazma):** `POST /notifications/:id/read` (notification, `services/notification/main.go:84`) başarılı olur; başarı mesajı görünür; liste/ekran yenilenince değişiklik görünür.
  - Sunucu yetkisi: oturum açmış herkes (site kapsamı)
  - **Veritabanı (Adminer → SQL komutu):**
    - `notification_reads` — yeni satır eklenmiş olmalı: `SELECT xmin, * FROM notification_reads ORDER BY xmin::text::bigint DESC LIMIT 5;`
  - **İşlem kaydı:** `SELECT created_at, action, entity_type, status_code, user_id FROM audit_logs WHERE screen = '/api/v1/notifications/:id/read' ORDER BY created_at DESC LIMIT 5;` → `CREATE`, 2xx (yetkisiz denemede `DENIED`, 403)
  - **Bildirim:** üretmez — `notifications` tablosuna bu işlemle yeni satır EKLENMEMELİ.
  - **Etkisi görülmeli:** Panel `/dashboard/inbox`, Sakin `main_screen`, Sakin `notifications_screen`, Yön.mobil `inbox_screen`, Yön.mobil `main_screen`
- **Sonuç:** http://localhost:18000/sonuc → `P-INBOX-02`

---

### Entegrasyon Durumu — `/dashboard/integrations`
- Dosya: `admin/src/app/(dashboard)/dashboard/integrations/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER — Dış sağlayıcıların bağlantı durumu

#### P-INTEGRATIONS-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard/integrations
- **Adım:** http://localhost:3001/dashboard/integrations adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /integrations/status` (karşılığı yok)
- **Adım:** Bilgi notu (satır 17): Sağlayıcı anahtarları sunucu ortam değişkenleriyle verilir (iyzico: IYZICO_* , SMS: NETGSM
- **Adım:** Bilgi notu (satır 29): Bazı servislerden durum alınamadı: {d.unavailable.map((u) => `${u.source}: ${u.reason}`).join(" · ")}
- **Adım:** Kart (satır 33): Bildirim kanalları
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kanal \| Durum
- **Adım:** Bilgi notu (satır 39): {delivery.note}
- **Adım:** Kart (satır 40): Kartla ödeme
- **Adım:** Kart (satır 47): Dosya deposu
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (DENETÇİ, GÖREVLİ, KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-INTEGRATIONS-00`

---
