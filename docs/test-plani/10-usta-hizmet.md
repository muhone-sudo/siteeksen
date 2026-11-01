# 10. Usta & Hizmet — tedarikçi pazaryeri (uçtan uca)

> Elle yazılır. Her senaryo tek test ID'sidir; adımlar `.a`, `.b` … diye ayrı da kaydedilebilir (ör. `U-TALEP-01.c`).
> Hesaplar (PLATFORM, TEDARİKÇİ1, TEDARİKÇİ2) ve sorgular (Q-TALEP, Q-GONDERIM, Q-DEFTER, Q-BILDIRIM): [00-baslangic.md](00-baslangic.md).
> Tedarikçi tarafı panelde (`http://localhost:3001/tedarikci`) ya da tedarikçi uygulamasında (`http://localhost:3004`) yürütülebilir;
> ikisi aynı uçları kullanır. Senaryo içinde hangisinin kullanıldığını sonuç notuna yazın.
>
> Gelir kuralı: tedarikçi talebi **kabul ettiği anda** ücret bakiyesinden (ya da paketinin dahil talep hakkından) düşer; alıcının adı ve
> telefonu ancak o zaman açılır. Her para adımından sonra Q-DEFTER ile bakiye = defter toplamı olmalı.

Başlangıç verisi (test ortamı kurulumu): kategoriler Tesisat, Elektrik, Boya badana (sakin + yönetim), Daire temizliği (sakin),
Site temizliği, Asansör bakımı (yönetim); paketler Ücretsiz ve Usta Pro (350 TL/ay, %25 indirim, ayda 5 talep, 50 SMS, öncelik,
vitrinde telefon). Güneş Sitesi'nin konumu yoksa YÖNETİCİ önce panel **Ayarlar → Site konumu**'ndan haritada işaretlesin
(konumsuz sitede yarıçaplı işletmeler yalnız aynı ilçeyle eşleşir).

---

## U-KAYIT-01 · Tedarikçi kaydı → belge → platform onayı → işletme yayını
1. **a (yeni numara, tedarikçi uygulaması ya da `/tedarikci/kayit`):** 5550007001 ile **Kod gönder** → SMS kutusundaki 8 karakterlik kod → **Kodu doğrula** → ad, soyad, şifre, koşullar → **Hesabımı aç**.
   Beklenen: tedarikçi paneli açılır; `users.roles` içinde `SUPPLIER`.
2. **b:** Hesabım'da unvan, vergi no (10 hane), vergi dairesi → **Hesabı oluştur**; vergi levhası (PDF) ve kimlik (JPG) yükle → **İncelemeye gönder**. Beklenen: durum İncelemede; belge olmadan gönderilince eksikler tek tek söylenir.
3. **c (PLATFORM, `/platform/hesaplar`):** hesabı aç, belgeyi indir (erişim kaydı) → gerekçesiz **Reddet** denenir (engellenir) → **Onayla**. Beklenen: tedarikçinin Bildirimler'inde "hesabınız onaylandı".
4. **d (tedarikçi):** İşletmelerim → işletme ekle (ad, telefon, adres, il/ilçe, haritadan konum, yarıçap 10 km, kategori Elektrik), bir hizmet kalemi (fiyat aralığıyla) → **İncelemeye gönder**.
5. **e (PLATFORM, `/platform/isletmeler`):** **Yayına al**. Beklenen: KİRACI'nın sakin uygulamasında **Usta & Hizmet → Yakınımdakiler**'de işletme görünür; ücretsiz pakette telefonu görünmez.
- **Sonuç:** `U-KAYIT-01`

## U-TALEP-01 · Talep → öncelik penceresi → kabul → teklif → seçim → iş → puan
1. **a (KİRACI, sakin uygulaması → Usta & Hizmet → Talep aç):** kategori Tesisat; "yakınınızda N onaylı işletme" yazısı; açıklamaya bir telefon numarası da yaz; rızayı işaretle → **Talebi gönder**.
   Beklenen: Q-TALEP'te açıklamadaki numara `[iletişim bilgisi gizlendi]`; Q-GONDERIM'de TEDARİKÇİ1 satırı `visible_at` = şimdi (ücretli paket), ücretsiz hesaplarınki 30 dk sonra.
2. **b (TEDARİKÇİ1):** Talepler'de talep görünür; ad/telefon/adres yok; "Paketinizdeki talep hakkından düşer". Q-BILDIRIM: `market.request.new` uygulama içi + SMS (SMS kutusunda TEDARİKÇİ1'in numarası).
3. **c (TEDARİKÇİ2, ücretsiz):** pencere içinde talebi **görmez** (liste boş). (Pencereyi beklemek yerine PLATFORM `/platform/ayarlar`'da öncelik penceresini 1 dk yapıp yeni bir talep açılabilir.)
4. **d (TEDARİKÇİ1):** **Kabul et** → onay. Beklenen: alıcının adı, telefonu, site adresi görünür; Q-DEFTER'de `INCLUDED_REQUEST` 0 TL satırı; dahil hak 1 azalır.
5. **e (TEDARİKÇİ1):** teklif (tutar, geçerlilik, açıklama) → **Teklif gönder**; yazışmaya bir mesaj. Beklenen: KİRACI'ya `market.offer.new`, `market.message`.
6. **f (KİRACI):** Taleplerim → talep → teklifler (işletme telefonu, puan) → **Mesaj** ile yanıt (daire no) → **Bu teklifi seç**. Beklenen: TEDARİKÇİ1'e `market.offer.accepted`; talep "Teklif seçildi".
7. **g (TEDARİKÇİ1):** **İş tamamlandı**. **(KİRACI):** **İş tamamlandı, onaylıyorum** → 5 yıldız + yorum → **Puanı gönder**.
   Beklenen: işletmenin vitrin puanı güncellenir; TEDARİKÇİ1 Puanlar'da yorumu görür ve **bir kez** yanıtlar.
- **Sonuç:** `U-TALEP-01`

## U-KOTA-01 · En çok 4 kabul ve bakiyesiz kabul
1. **a:** Elektrik kategorisinde en az 5 onaylı hesap yoksa bu senaryoyu ATLANDI işaretle (kota otomatik doğrulamada sınanıyor). Varsa 5 hesap sırayla kabul eder: 5. hesap "Talep doldu" (409) alır.
2. **b:** Bakiyesi talep ücretinden az bir ücretsiz hesapla kabul dene: "Bakiye yetersiz — bakiye yükle" görünür, kabul yapılamaz, Q-DEFTER değişmez.
- **Sonuç:** `U-KOTA-01`

## U-DOGRUDAN-01 · "Bu işletmeye talep gönder"
1. **a (MALİK_B1, sakin uygulaması):** Yakınımdakiler → TEDARİKÇİ2'nin işletmesi → **Bu işletmeye talep gönder** → Daire temizliği.
   Beklenen: "Talep yalnız bu işletmeye gönderilir"; Q-GONDERIM'de tek satır, ücretsiz pakette de `visible_at` = şimdi; `max_accepts` = 1.
2. **b (TEDARİKÇİ2):** talep hemen görünür; kabul edince kategori ücreti bakiyeden düşer (Q-DEFTER `REQUEST_FEE`).
- **Sonuç:** `U-DOGRUDAN-01`

## U-SUBE-01 · İki şubeli hesap
1. **a:** TEDARİKÇİ1'in iki şubesi Tesisat'ta uygun. KİRACI Tesisat talebi açar.
   Beklenen: Q-GONDERIM'de TEDARİKÇİ1 için **tek** satır; işletme olarak siteye en yakın şube (site konumu yoksa sitenin ilçesindeki şube).
- **Sonuç:** `U-SUBE-01`

## U-IADE-01 · Geçersiz talep bildirimi ve platform iadesi
1. **a (TEDARİKÇİ2):** kabul ettiği bir talepte **Talep geçersiz — platforma bildir** (Alıcıya ulaşılamıyor, açıklama).
2. **b (PLATFORM, `/platform/itirazlar`):** gerekçesiz karar engellenir; **Onayla ve iade et** (gerekçe).
   Beklenen: Q-DEFTER'de `REFUND` (kabul ücreti kadar, tek satır); ikinci onay engellenir; TEDARİKÇİ2'ye `market.dispute.resolved`. Dahil hakla kabul edilmişse defter satırı yerine hak geri gelir.
3. **c (PLATFORM, `/platform/yorumlar`):** bir yorumu gerekçeyle **Gizle**. Beklenen: vitrinden kalkar, veritabanında durur; puan özetinden çıkar.
4. **d (PLATFORM, `/platform/gelir`):** bugünün raporu: net = aidat + talep ücreti − iade; yüklemeler ayrı.
- **Sonuç:** `U-IADE-01`

## U-BAKIYE-01 · Bakiye yükleme ve paket
1. **a (TEDARİKÇİ2, `/tedarikci/bakiye` ya da uygulamada Bakiye):** 400 TL → **Kartla öde** → sahte iyzico **Ödeme başarılı**. Beklenen: bakiye 600 TL; Q-DEFTER `TOPUP`.
2. **b:** **Reddedildi: limit yetersiz** ve **Yarıda bırak** yolları: bakiye değişmez.
3. **c:** Usta Pro'ya geç: aidat (350 TL) düşer, 5 talep + 50 SMS hakkı tanımlanır.
- **Sonuç:** `U-BAKIYE-01`

## U-YONETIM-01 · Site adına alım → teklif karşılaştırma → onay bekleyen gider
1. **a (YÖNETİCİ, panel `/dashboard/usta-hizmet`):** **Teklif topla** → Site temizliği → açıklama → **Talebi gönder**.
2. **b (TEDARİKÇİ1, TEDARİKÇİ2):** kabul + teklif. (Ücretsiz hesap için öncelik penceresini bekleyin ya da ayarı kısaltın.)
3. **c (YÖNETİCİ):** talepte **Teklif karşılaştırma** tablosu (tutar, kapsam, puan, telefon) → **Seç**. İş kartında tedarikçinin fatura bilgisi (unvan, VKN).
4. **d:** **Onay bekleyen gider oluştur** → gider kalemi → **Gideri oluştur**. Beklenen: Giderler'de `PENDING` gider, tutar ve VKN doğru; kurul onay akışı aynı.
5. **e:** **Sözleşme formunu doldur** → sözleşme formu başlık ve karşı tarafla dolu açılır.
6. **f (DENETÇİ):** aynı talebi ve tabloyu görür; **Teklif topla**, **Seç**, **Gider oluştur** yok.
7. **g (Yön.mobil, YÖNETİCİ):** Menü → Usta & Hizmet → talep → teklifler ve fatura bilgisi görünür.
- **Sonuç:** `U-YONETIM-01`

---

## M13 — yayın öncesi düzeltmeler (2026-11-01)

## U-KOSUL-01 · Bakiye ve iade koşullarının ayrıca kabulü
1. **a (TEDARİKÇİ2, `/tedarikci/bakiye` ya da uygulamada Bakiye):** ilk yüklemeden önce "Usta & Hizmet Bakiye ve İade Koşulları" kartı görünür; kutu işaretlenmeden **Koşulları kabul et** pasif.
2. **b:** kabul et → kart kaybolur, yükleme formu açılır; altında koşul sürümü ve kabul tarihi yazar. Q: `SELECT version, text_sha256, accepted_at FROM mp_terms_acceptances` — tek satır.
- **Sonuç:** `U-KOSUL-01`

## U-ODEME-01 · Tedarikçi uygulamasında uygulama içi ödeme
1. **a (Android APK ya da `http://localhost:3004`):** Bakiye → 100 TL → **Kartla öde**. Android'de ödeme sayfası uygulamanın içinde açılır (tarayıcıya çıkılmaz); web derlemesinde aynı sekmede.
2. **b:** sahte iyzico'da **Ödeme başarılı** → sayfa kendiliğinden kapanır (web: uygulamanın Bakiye sayfasına döner), "Ödeme alındı; bakiye güncellendi" mesajı, bakiye +100 TL.
3. **c:** yeni ödeme başlatıp sayfayı **X** ile kapat → "Ödemeden çıkılsın mı?" → **Çık**: bakiye değişmez; yükleme birkaç dakika içinde uzlaştırmayla sonuçlanır.
- **Sonuç:** `U-ODEME-01`

## U-IADE-02 · Üyelik kapanışında kalan bakiyenin karta iadesi
1. **a (PLATFORM, `/platform/hesaplar` → bakiyesi olan tedarikçi):** **Üyeliği kapat** → bilgi kutusu: son 365 günde kartla yüklenen kısım karta iade edilir, eskisi edilmez → gerekçe → **Kapat**.
   Beklenen: mesajda karta iade edilen tutar (ve varsa iade edilmeyen kısım); Q-DEFTER'de `CARD_REFUND` (ve varsa `EXPIRED_BALANCE`) satırları, bakiye 0.
2. **b (`/platform/iadeler`, "Hepsi"):** iadeler "Karta iletildi"; iyzico referansı görünür. Tedarikçinin Bildirimler'inde "Kartınıza iade yapıldı".
3. **c:** başarısız bir iade varsa **Havaleyle ödendi** → dekont no + tarih → "Havaleyle ödendi".
- **Sonuç:** `U-IADE-02`

## U-SINIR-01 · Mesaj ve teklif hız sınırı
1. **a (PLATFORM, `/platform/ayarlar`):** `message_per_minute_limit` = 2 yap. **(KİRACI)** bir yazışmada art arda 3 mesaj: 3.'de "Çok hızlı mesaj gönderiyorsunuz…" (429).
2. **b:** `offer_edit_limit` = 1 yap. **(TEDARİKÇİ1)** bir teklifi iki kez düzenle: 2.'de "Bu teklif en çok 1 kez düzenlenebilir…". Ayarları geri al (20 / 5).
- **Sonuç:** `U-SINIR-01`

## U-FOTO-01 · Fotoğraf denetimi (OCR + yapay zekâ + elle onay)
1. **a (TEDARİKÇİ1, İşletmelerim → işletme → hizmet → Fotoğraf):** üzerinde telefon numarası yazan bir görsel yükle. Beklenen: birkaç saniye sonra kalemde "Reddedildi" ve gerekçe (iletişim bilgisi); Bildirimler'de "Hizmet fotoğrafınız yayınlanmadı".
2. **b:** numarasız bir iş fotoğrafı yükle (yapay zekâ kapalı). Beklenen: "İncelemede"; KİRACI vitrinde fotoğrafı görmez.
3. **c (PLATFORM, `/platform/fotograflar`):** fotoğraf, OCR metni ve bağlamıyla listede → **Onayla** → KİRACI vitrinde görür. Aynı fotoğrafı "Yayında" süzgecinden gerekçeyle **Kaldır** → vitrinden düşer.
4. **d (`/platform/yapay-zeka`):** sağlayıcı ayarı (anahtarsız açma engellenir); anahtar kaydedilince "Tanımlı" yazar, anahtarın kendisi görünmez. Gerçek sağlayıcı yoksa bu adımı ATLANDI işaretle.
5. **e (KİRACI, sakin uygulaması):** talebe telefonlu fotoğraf ekle → talep ekranında "Fotoğraf 1: tedarikçilere gösterilmedi — …".
- **Sonuç:** `U-FOTO-01`
