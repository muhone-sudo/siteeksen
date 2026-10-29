# 3.1 Panel — Üst

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Panel: http://localhost:3001. Her sayfa için önce **sayfa açılışı** (…-00), sonra sayfadaki her düğme/form/seçim sırayla denenir. Formlarda önce zorunlu alanları boş bırakıp gönder (doğrulama hatası beklenir, kayıt OLUŞMAMALI), sonra gerçekçi değerlerle doldur. Girilen değerleri gözleme yaz; sonraki adımlar ve senaryolar bu kayıtları kullanır.

### Panel — `/dashboard`
- Dosya: `admin/src/app/(dashboard)/dashboard/page.tsx`
- Panel erişimi: MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli

#### P-ANA-00 · Sayfa açılışı ve ekran kontrolleri
- **Hesap:** YÖNETİCİ (sonra KURUL, DENETÇİ, GÖREVLİ ile yalnız görüntüleme) · **Nerede:** http://localhost:3001/dashboard
- **Adım:** http://localhost:3001/dashboard adresini aç (ya da kenar çubuğundan seç); sayfa 5 sn içinde yüklenmeli, tarayıcı konsolunda kırmızı hata olmamalı
- **Adım:** Veri yüklenir: `GET /dashboard/stats` (gateway)
- **Adım:** Veri yüklenir: `GET /dashboard/recent-payments` (gateway)
- **Adım:** Veri yüklenir: `GET /dashboard/recent-requests` (gateway)
- **Adım:** Bilgi notu (satır 27): Bazı özet veriler alınamadı: {missing.map((u) => ( {u.source}: {u.reason} ))} Eksik kartlarda uydurma değer gösterilmez
- **Adım:** Kart (satır 52): Son ödemeler
- **Adım:** Bağlantı (satır 52): Tümü → /dashboard/accounting
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: Kişi \| Daire \| Tutar \| Durum \| Tarih
- **Adım:** Kart (satır 69): Son talepler
- **Adım:** Bağlantı (satır 69): Tümü → /dashboard/requests
- **Adım:** Tablo sütunları görünür ve dolu/boş durumu doğru: No \| Başlık \| Durum \| Tarih
- **Adım:** Sayfayı yenile (F5): aynı içerik gelir, oturum düşmez
- **Adım:** Erişimi olmayan hesapla (KİRACI) aynı adresi aç → `/dashboard/forbidden` sayfasına yönlenmeli, kenar çubuğunda bu menü görünmemeli
- **Beklenen:** her veri bölümü yüklenir (boşsa anlamlı boş durum mesajı; "undefined", "NaN", "null", ham JSON ya da İngilizce hata metni YOK); sayılar ve tarihler Türkçe biçimde (1.234,56 ₺ · gg.aa.yyyy); uydurma/örnek veri yok; dar ekranda (400 px) yatay kaydırma olmadan okunur.
- **Sonuç:** http://localhost:18000/sonuc → `P-ANA-00`

---
