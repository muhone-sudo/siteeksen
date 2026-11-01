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
