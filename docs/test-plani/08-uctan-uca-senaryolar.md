# 8. Uçtan uca senaryolar (birden çok hesap)

> Elle yazılır. Her senaryo baştan sona tek test ID'sidir; içindeki adımlar `.a`, `.b` … diye ayrı da kaydedilebilir
> (ör. `E-AIDAT-01.c`). Bir adım başarısız olursa senaryonun kalanını yine dene ve hangi adımdan sonra neyin bozulduğunu yaz.
> Hesap kodları ve sorgular: [00-baslangic.md](00-baslangic.md). Düğme adları ekranlardaki gerçek etiketlerdir.

Senaryoları iki pencereyle yürütmek kolaylaştırır: bir pencerede panel/yönetici uygulaması (yönetim), ötekinde (gizli pencere) sakin uygulaması.

---

## E-AIDAT-01 · Aidat döngüsü: tahakkuk → bildirim → havale + dekont → onay → defter
1. **a — Tahakkuk (YÖNETİCİ, panel `/dashboard/assessments`):** **Tahakkuk oluştur** ile bu ay için aidat oluştur (tutar ör. 1.250,00 ₺, son ödeme tarihi 10 gün sonra).
   Beklenen: 24 bölüme borç yazılır; Q-BORC'ta bu dönemin satırları `PENDING`; dağıtım yöntemine göre tutarlar doğru (eşit dağıtımda hepsi aynı, arsa payında paya orantılı ve **toplam girilen tutara birebir eşit**).
2. **b — Yeni borç bildirimi (`dues.created`):** Q-BILDIRIM → borcun sorumlusuna bildirim. A-4 kullanım borcu **KİRACI**'ya gider (MALİK_A4'e DEĞİL); B-1 borcu MALİK_B1 ve VEKİL_B1'e. SİTE_B'ye hiçbir şey yok.
   Sakin uygulamasında KİRACI'nın zilinde yeni borç; MALİK_A4'ün ana ekranında A-4 kullanım borcu görünüyor mu? (Görünürlük politikasına bağlı — Ayarlar'daki malik görünürlüğü; gözleme yaz.)
3. **c — Havale bildirimi (KİRACI, sakin `/finance/payment`):** borcu seç → havale/EFT ile öde → açıklamaya `TEST-HAVALE-01` → **Dekont ekle** ile küçük bir PDF/JPG yükle.
   Beklenen: ödeme `PENDING` (onay bekliyor); borç henüz kapanmaz; Q-ODEME'de satır; `payment_receipts` tablosunda dekont (Q-SON(payment_receipts)).
4. **d — Onay (YÖNETİCİ, panel `/dashboard/accounting`):** bekleyen ödemede dekontu aç (indir), **Ödemeyi onayla**.
   Beklenen: ödeme `COMPLETED`; Q-BORC'ta A-4'ün `paid_amount` = tutar, durum `PAID`; `finance_ledger`'a yeni satır (zincir: `prev_hash` bir önceki `entry_hash`). **Not:** ödeme onayı/reddi şu an bildirim üretmez (kodda konu yok); KİRACI sonucu ödeme ekranından görür. Bildirim gelmemesi beklenen durumdur; gözleme "onay bildirimi yok" yaz.
5. **e — Sakin tarafı:** KİRACI ödeme geçmişinde (`/payment-history`) ödeme ve onay tarihi; borç listesi boş; **Tahsilat kayıtlarını doğrula** → zincir sağlam.
6. **f — Ret yolu:** MALİK_B1 B-1 borcu için havale bildirsin; YÖNETİCİ **Reddet** (gerekçe yaz). Beklenen: borç açık kalır; ödeme `REJECTED`/reddedildi; gerekçe MALİK_B1'in ödeme ekranında/geçmişinde görünüyor mu gözle (görünmüyorsa KISMEN). Bildirim üretilmez.
7. **g — Yönetimin tahsilat girişi (Yön.mobil `/finance` → tahsilat girişi, "Kaydet ve borçtan düş"):** YÖNETİCİ B-2 borcunu elden tahsil etmiş gibi girer.
   Beklenen: `payments.recorded_by` = YÖNETİCİ; KURUL'a (B-2) `payment.recorded` bildirimi; ödeme geçmişinde "yönetim tarafından girildi" anlamında kayıt.
8. **h — Ters kayıt:** YÖNETİCİ panelde B-2 ödemesine **Ödemenin ters kaydı** (gerekçe). Beklenen: borç yeniden açılır; ödeme silinmez, `reversed_at` dolu; deftere ters kayıt satırı.
- **Sonuç:** `E-AIDAT-01`

## E-KART-01 · Kartla ödeme (sahte iyzico)
1. **a (KİRACI, sakin `/finance/payment`):** açık bir borcu kartla öde. Yeni sekmede **Sahte iyzico ödeme sayfası** açılır (tutar doğru).
2. **b:** **Reddedildi: limit yetersiz** seç. Tarayıcı `http://localhost:3001/odeme-sonuc` sayfasına gelir: "Ödeme tamamlanamadı", kartın çekilmediği söylenir. Borç açık; Q-ODEME'de `FAILED`, hata nedeni yazılı.
3. **c:** Yeniden kartla öde → **Ödeme başarılı**. Sonuç sayfası "Ödemeniz alındı"; uygulamada borç kapanmış; Q-ODEME `COMPLETED`, `gateway = iyzico`, `gateway_payment_id` dolu; http://localhost:18000/iyzico'da her çağrının imzası "geçerli".
4. **d:** Yeniden kartla öde → **Yarıda bırak**. Ödeme `PENDING`; uzlaştırma bekçisi sonradan sorgular (B-BEKCI-KART). Aynı borç için ikinci ödeme başlatılabiliyor mu, çift tahsilat riski var mı gözle.
- **Sonuç:** `E-KART-01`

## E-GECIKME-01 · Gecikme tazminatı
1. YÖNETİCİ panel `/dashboard/assessments` → **Tazminatı işlet** (son ödeme tarihi geçmiş borçlar için; seed'de geçmiş aylar var).
2. Beklenen: oran `legal_parameters`'tan (KMK m.20: aylık %5) — `SELECT code, value, effective_from FROM legal_parameters WHERE code ILIKE '%LATE%';`; Q-BORC'ta `late_fee` doldu; aynı ay için ikinci kez işletince tazminat ikiye katlanmaz.
- **Sonuç:** `E-GECIKME-01`

## E-BORCYOK-01 · Borcu yoktur belgesi
1. MALİK_B1 tüm borcunu ödedikten sonra sakin aidat ekranında **Borcu yoktur belgesi** → PDF iner/açılır.
2. Borcu olan KİRACI aynı işlemi dener → belge verilmez, nedeni yazılır.
3. Belgedeki kodla `http://localhost:3001/dogrula/<kod>` (oturumsuz) → geçerli; kişisel veri yok.
4. YÖNETİCİ panel `/dashboard/units` → B-1 → **Borcu yoktur** ile de üretebilir.
- **Sonuç:** `E-BORCYOK-01`

## E-GIDER-01 · Gider → dağıtım → tahakkuk
1. YÖNETİCİ `/dashboard/expenses` → **Gider ekle** (kategori "Asansör Bakım" — arsa payı dağıtımı, zemin kat hariç; tutar 2.400 ₺, fatura dosyası ekle) → **Onayla**.
2. Beklenen: dağıtım önizlemesinde zemin kat bölümleri (A-1, A-2, B-1, B-2) **yok**; payların toplamı 2.400,00 ₺'ye birebir eşit; onaydan sonra ilgili bölümlere borç ya da tahakkuk kalemi (ekranda nasıl yansıdığını yaz).
3. DENETÇİ aynı gideri görür, **Onayla/Reddet** göremez.
- **Sonuç:** `E-GIDER-01`

## E-DUYURU-01 · Duyuru → okundu istatistiği
1. YÖNETİCİ `/dashboard/announcements` → **Duyuru yayımla** (`TEST-Duyuru-01`, öncelik normal); bir tane de **acil** öncelikli (`TEST-Acil-01`).
2. Beklenen: bütün sakin hesaplarının zilinde bildirim; acil duyuru SMS kutusunda da (sakin numaralarına); normal duyuru SMS GÖNDERMEZ. DENETÇİ ve GÖREVLİ (sakin değil) bildirim almaz.
3. KİRACI ve MALİK_B1 sakin uygulamasında duyuruyu açar.
4. YÖNETİCİ duyuruda **İstatistik** → okuyan 2 kişi; okumayanlar sayısı doğru. Q-OKUNDU.
5. **Sabitle/Sabitlemeyi kaldır** → sakin ana ekranında sıra değişir.
- **Sonuç:** `E-DUYURU-01`

## E-TALEP-01 · Arıza/talep yaşam döngüsü
1. KİRACI sakin `/requests/create` → kategori, başlık `TEST-Talep-01`, açıklama, fotoğraf (varsa) → **Gönder**.
2. Beklenen: panel `/dashboard/requests` listesinde görünür. **Not:** talep açma ve durum değişikliği şu an bildirim üretmez (kodda konu yok) — yönetim talebi listeden, sakin durumu ekrandan görür. Q-BILDIRIM'de talep satırı yoksa bu beklenen durumdur; gözleme "talep bildirimi yok (ürün eksiği adayı)" yaz.
3. GÖREVLİ panelde durumu ilerletir (işleme al → devam ediyor); KİRACI uygulamada yenileyince yeni durumu görür.
4. KİRACI uygulamada **Sorunum çözüldü** → talep kapanır; yeniden açma/"Devam ediyor" denemesi.
5. MALİK_A4 A-4'ün taleplerini görebiliyor mu? (Malik görünürlüğü politikasına göre — gözleme yaz.)
- **Sonuç:** `E-TALEP-01`

## E-REZERV-01 · Ortak alan rezervasyonu
1. YÖNETİCİ `/dashboard/reservations` → tesis ekle (`TEST-Toplantı Salonu`, onay gerekir, saat aralığı 09:00–22:00).
2. KİRACI sakin `/reservation` → yarın 18:00–19:00 → **Rezervasyon Yap**. Beklenen: `PENDING` (onay bekliyor). Yeni rezervasyon yönetime bildirim üretmez; panel listesinde görünür.
3. MALİK_A4 A-4 adına rezervasyon dener → reddedilir (kullanım hakkı kiracıda).
4. MALİK_B1 aynı saate rezervasyon dener → çakışma uyarısı.
5. YÖNETİCİ **Onayla** → KİRACI'ya `reservation.decision` bildirimi; `/my-reservations` durumu onaylı. KİRACI **İptal**.
6. Bir başka rezervasyonu YÖNETİCİ **Rezervasyonu reddet** (gerekçe) → gerekçe sakine görünür.
- **Sonuç:** `E-REZERV-01`

## E-ZIYARET-01 · Ziyaretçi ön kaydı → kapıda giriş/çıkış
1. KİRACI sakin `/visitor-preregister` → ad `TEST Misafir`, yarın → **Ön Kayıt Oluştur**. Beklenen: PIN ve QR gösterilir (bir kez); Q-SON(visitors).
2. KİRACI `/my-visitors` → **Kodu yenile** → yeni kod; eskisi geçersiz.
3. GÖREVLİ Yön.mobil `/visitors` → **Geçiş koduyla giriş** (yeni PIN) → giriş yaptı. Beklenen: KİRACI'ya `visitor.checkin` bildirimi (MALİK_A4'e DEĞİL).
4. Eski PIN ile giriş denemesi reddedilir. **Çıkış yaptı** ile çıkış.
5. Başka bir ön kaydı KİRACI **İptal et**; görevli o kodla giriş yapamaz.
- **Sonuç:** `E-ZIYARET-01`

## E-KARGO-01 · Kargo kabul → bildirim → teslim kanıtı
1. GÖREVLİ panel `/dashboard/packages` → **Kargo kabul** (A-4, firma, takip no).
2. Beklenen: KİRACI'ya `package.received` bildirimi; metinde **takip numarası YOK**; MALİK_A4'e bildirim yok.
3. **Hatırlat** → kargo kaydında hatırlatıldı bilgisi (ayrı bildirim konusu yok; yeni bildirim satırı oluşup oluşmadığını gözleme yaz). **Teslim et** (imza/fotoğraf yüklenebiliyorsa yükle).
4. YÖNETİCİ teslim kanıtını indirir (imza/fotoğraf) → dosya açılır. KİRACI sakin `/packages` → teslim edildi ve kanıt.
5. Başka bir kargo için **Kargo firmasına iade**.
- **Sonuç:** `E-KARGO-01`

## E-ANKET-01 · Anket ve memnuniyet (NPS)
1. YÖNETİCİ `/dashboard/surveys` → **Anket oluştur** (`TEST-Anket-01`, 2 seçenek, yorum açık) → **Yayımla**. Sakinlere `survey.published` bildirimi (genel kurul çağrısı olarak İŞARETLENMEZ).
2. KİRACI ve MALİK_B1 sakin `/surveys` → **Oy Ver** (biri yorumlu). Aynı kişi ikinci kez oy veremez.
3. YÖNETİCİ sonuçları ve yorumları görür; **Kapat**.
4. YÖNETİCİ `/dashboard/nps` → **Memnuniyet ölçümü başlat**. Sakinler `/nps`'te 0–10 puan verir. Yanıt yokken skor "yok" der; yanıtlar gelince NPS hesaplanır (yanıtlar anonim — kimin ne verdiği görünmez).
- **Sonuç:** `E-ANKET-01`

## E-ILAN-01 · İlan panosu onay akışı
1. MALİK_B1 sakin `/bulletin` → **İlan Ver** (`TEST-İlan-01`). Beklenen: onay bekliyor; Approvers'a (YÖNETİCİ, KURUL) `bulletin.pending` bildirimi — DENETÇİ'ye değil.
2. YÖNETİCİ `/dashboard/bulletins` → **Onayla**; diğerini **İlanı reddet** (gerekçe sahibine görünür). İkisinde de sahibine `bulletin.decision`.
3. KİRACI onaylı ilana yorum yazar; MALİK_B1 yorumu görür; YÖNETİCİ yorumu **Gizle** → yorum silinmez, gizlenir.
4. **Süresi dolanları işle**.
- **Sonuç:** `E-ILAN-01`

## E-TADILAT-01 · Tadilat izni, komşu bildirimi, rıza
1. MALİK_B1 sakin `/renovations` → **Başvuru yap** (B-1, tarih aralığı, açıklama).
2. Beklenen: yönetime `renovation.request`; onaydan sonra aynı bloktaki komşulara (B blok: KURUL/B-2) `renovation.neighbors`; A blok sakinlerine GİTMEZ. Onay/ret/durdurma/tamamlanmada sahibine `renovation.approved/rejected/stopped/completed`.
3. YÖNETİCİ `/dashboard/renovations` → (gerekiyorsa) **Rızayı kaydet** → **Onayla** → **Denetle ve kapat**. Bir başkasını MALİK_B1 **Geri çek**.
- **Sonuç:** `E-TADILAT-01`

## E-IHLAL-01 · Kural ihlali ve savunma
1. YÖNETİCİ `/dashboard/violations` → **Kural ekle** (`TEST-Kural: gece gürültüsü`).
2. KİRACI sakin `/violations` → **Bildir** (A-3'e karşı) → yönetime `violation.reported`. Bildirenin kimliği ihlal sahibine gösterilmemeli.
3. YÖNETİCİ **Doğrula** → kademe; A-3 sakinlerine (YÖNETİCİ) `violation.*` bildirimi; sakin uygulamasında **Savunma** yazılır → yönetime `violation.response`. Doğrulanmayan ihlalde `violation.dismissed`.
- **Sonuç:** `E-IHLAL-01`

## E-KVKK-01 · KVKK başvurusu
1. MALİK_B1 sakin `/kvkk` → **Başvuru yap** (bilgi talebi). Yanıt son günü 30 gün sonrası.
2. Yönetime `kvkk.request`; YÖNETİCİ `/dashboard/kvkk` → **Başvuruyu sonuçlandır** (yanıt metni). MALİK_B1'e `kvkk.response`; uygulamada yanıt görünür.
- **Sonuç:** `E-KVKK-01`

## E-KIRACI-01 · Kiracılık bitişi (malik ister, kiracı onaylar)
1. MALİK_A4 sakin `/profile` → bölüm sakinleri → **Kiracılığın bitmesini iste** (tarih).
2. KİRACI'ya `identity.tenancy` bildirimi; tenancy_requests ekranında talebi görür → önce **İtiraz et** dene (gerekçe), sonra yeni bir talepte **Onayla**.
3. Beklenen: onaydan sonra A-4 kiracısız; KİRACI'nın A-4 kullanımı biter (borç/araç/ziyaretçi ekranları); daha önce tahakkuk etmiş kiracı borçları kiracının sorumluluğunda kalır (`assessment_visible_to`); yeni kullanım borçları malike düşer.
4. Q-KISI: Mehmet Demir A-4 `is_active = false`, `end_date` dolu.
5. **Geri alma:** YÖNETİCİ panel `/dashboard/residents` → kiracılık talepleri → **Kiracılığı geri aç** (varsa) ya da YÖNETİCİ KİRACI'yı yeniden A-4'e TENANT olarak ekler. Diğer senaryolar KİRACI'yı kullandığı için bu adımı mutlaka yap.
- **Sonuç:** `E-KIRACI-01`

## E-KIRACI-02 · Kiracılık bitişi — yönetim yolu (belge + 7 gün itiraz)
1. YÖNETİCİ panel sakinler → kiracılık talepleri → **Yönetim yolu başlat** (belge yükle, şifreyle beyan).
2. Beklenen: kiracıya ve malike `identity.tenancy` bildirimi (kimlik servisi bildirim tablosuna yazamıyorsa SMS/e-posta ya da işlem kaydı — gözleme yaz); 7 günlük itiraz süresi yazılı; süre dolmadan **Tamamla** reddedilmeli; **İptal** çalışır.
- **Sonuç:** `E-KIRACI-02`

## E-DAVET-01 · Malikin kiracı/hane üyesi daveti
1. MALİK_B1 sakin bölüm sakinleri → **Davet gönder** (telefon `5550000033`, sıfat TENANT).
2. Beklenen: SMS kutusunda 5550000033'e davet; YÖNETİCİ sakinler listesinde bekleyen davet. Daire başına tek aktif kiracı kuralı: A-4'e ikinci kiracı daveti reddedilmeli.
3. Davet edilen kişi kayıtlı değilse etkinleştirmeyle gelir; kayıtlıysa sakin uygulamasındaki davet bandında **Kabul et / Reddet**.
- **Sonuç:** `E-DAVET-01`

## E-GORUNUR-01 · Malik görünürlük politikası (kurul onayı)
1. YÖNETİCİ panel `/dashboard/settings` → **Görünürlük değişikliği öner** (ör. kiracılı dairede malik talepleri görsün).
2. Beklenen: öneri kurul üyesinin onayını bekler; aynı kişi kendi önerisini onaylayamaz; KURUL onaylar.
3. Onaydan sonra MALİK_A4 sakin uygulamasında A-4 ile ilgili seçilen bilgiyi görür; kiracılara (KİRACI) ve kiracılı dairelerin maliklerine `visibility.policy` bildirimi.
4. **Geri çek** ile eski hâline dön.
- **Sonuç:** `E-GORUNUR-01`

## E-BUTCE-01 · İşletme projesi → genel kurul → kesinleşme → aidat
1. YÖNETİCİ `/dashboard/governance/budgets` → **İşletme projesi hazırla** (kalemler) → **Geçici proje olarak bildir**.
2. Beklenen: geçici projenin bildirilmesi şu an uygulama içi bildirim üretmez (kodda konu yok) — maliklere bildirim beklenmez, gözleme yaz; MALİK_B1 sakin `/my-budgets`'te bölüm payını görür → **Görüş / itiraz bildir** (site ayarı kapalıysa ekran bunu açıkça söyler).
3. `/dashboard/governance/assemblies` → **Toplantı planla** → **Çağrıyı kaydet** (en az 15 gün kuralı) → hazirun ekle → **Toplantıyı yap** → **Kararı hesapla** (nisap ve çoğunluk mevzuata göre).
4. **Genel kurul kararıyla kesinleştir** → **Projeden aylık aidat tahakkuk et** (borç sorumlularına `dues.created`). Q-BORC'ta paylar projeye göre; karar defterine kayıt (`book_entries`) ve değiştirilemez.
- **Sonuç:** `E-BUTCE-01`

## E-DEFTER-01 · Karar defteri
1. `/dashboard/governance/books` → **Deftere kayıt ekle** ×2 → **Defteri notere kapat**.
2. Beklenen: kayıt sırası ve `prev_hash` zinciri; kapatılmış deftere kayıt eklenemez; kayıt düzenleme/silme yok (T-BOOK-ENTRIES-NO-UPDATE).
- **Sonuç:** `E-DEFTER-01`

## E-SAYAC-01 · Sayaç okuma → ısı payı → pusula → itiraz
1. YÖNETİCİ `/dashboard/meters` → **Sayaç ekle** (A-4 ısı pay ölçer); GÖREVLİ Yön.mobil sayaç okuma → **Girilen okumaları kaydet**.
2. YÖNETİCİ **Hesapla ve yayımla** (fatura tutarı): sabit pay net alana, değişken pay okumaya göre; medyandan çok sapan okuma uyarısı.
3. KİRACI sakin `/energy` → pusulayı PDF olarak açar → **İtiraz et** (yönetime `statement.objection`); YÖNETİCİ itirazı yanıtlar (KİRACI'ya `statement.objection.answer`); yanıtlanmış itiraz değiştirilemez.
4. KİRACI `/my-meters` → kendi sayacı ve okumaları; MALİK_A4 göremez (kullanım kiracıda).
- **Sonuç:** `E-SAYAC-01`

## E-DEVRIYE-01 · Devriye: rota, QR + konum, sorun, rapor
1. YÖNETİCİ Yön.mobil `/patrol/points` → **Tur tanımla** (süre 5 dk, tolerans 1 dk) → **Nokta** ×2 → bir noktada **Konumu buradan al** (tarayıcı konum izni), diğerini **Konumdan muaf tut** (gerekçe).
2. Panel `/dashboard/patrol` → noktanın QR'ını göster/yazdır; **QR yenile** → eski QR geçersiz.
3. GÖREVLİ Yön.mobil `/patrol/run` → **Başlat** → **QR okut** (kamera izni; web'de kamera yoksa **Listeden seç**) → **Sorun bildir** → **Turu bitir**.
4. Beklenen: konumu uzaktan okutma reddedilir ve kanıt olarak kaydedilir; muaf nokta kabul; sorun bildirimi yönetime gider (`patrol.issue`); panel `/dashboard/patrol/reports`'ta tur, okutmalar, reddedilenler, konum izi.
5. Bir turu bitirmeden bırak → 6+ dk sonra `patrol.overdue` (B-ZAMAN-PATROL-OVERDUE).
- **Sonuç:** `E-DEVRIYE-01`

## E-SENSOR-01 · Sensör: kayıt → okuma → alarm → onay → kapatma
1. YÖNETİCİ panel `/dashboard/sensors` → sensör ekle (su kaçağı, ikili) → **cihaz anahtarını kopyala** (bir kez gösterilir).
2. http://localhost:18000/cihaz → anahtar, değer `1` → Gönder. Beklenen: 2xx; TRIGGERED alarmı; Operations'a (YÖNETİCİ, KURUL, GÖREVLİ) bildirim; DENETÇİ'ye yok.
3. GÖREVLİ alarmı **Onayla**, YÖNETİCİ **Alarmı kapat** (not zorunlu).
4. **Anahtarı yenile** → eski anahtarla gönderim 401; yeni anahtarla 2xx.
- **Sonuç:** `E-SENSOR-01`

## E-OTOPARK-01 · Araç, geçiş cihazı, otopark hareketi
1. KİRACI sakin `/vehicles` → **Araç ekle** (34 TEST 01). MALİK_A4 A-4 için araç ekleyemez.
2. GÖREVLİ panel `/dashboard/parking` → plaka sorgu (34 TEST 01) → kayıtlı araç bulunur → **Araç girişi** → **Çıkış**.
3. **Geçiş cihazı ekle** → anahtar → cihaz simülatöründen sinyal → çevrimiçi; sinyal kesilince olay (B-BEKCI-CIHAZ).
- **Sonuç:** `E-OTOPARK-01`

## E-PERSONEL-01 · Personel, izin, bordro, SGK
1. YÖNETİCİ `/dashboard/personnel` → **Personel ekle** (TCKN `10000000146`, IBAN `TR330006100519786457841326`).
2. Beklenen: listede TCKN/IBAN maskeli; D-KISI sorgusunda düz sütunlar boş, şifreli dolu; Yön.mobil'de yalnız maskeli.
3. **İzin gir** → **Onayla**; başka izin **İzni reddet**. **Bordro gir** → **Ödeme** → bir bordroyu **Bordro kaydını iptal et**. **SGK bildirgesi verildi**.
4. KURUL görebilir; DENETÇİ ve GÖREVLİ personel sayfasına giremez.
- **Sonuç:** `E-PERSONEL-01`

## E-BELGE-01 · Belge arşivi ve erişim kaydı
1. YÖNETİCİ `/dashboard/documents` → **Belge yükle** (görünürlük: sakinler) ve bir tane (yalnız yönetim).
2. MALİK_B1 sakin `/documents` → yalnız "sakinler" belgesini görür, indirir (bütünlük doğrulaması geçer). Yönetim belgesi görünmez.
3. `SELECT action, created_at FROM document_access_logs ORDER BY created_at DESC LIMIT 5;` → `DOWNLOAD` satırı; bu tablo değiştirilemez.
4. **Belgeyi arşivle** → sakin listesinden kalkar.
- **Sonuç:** `E-BELGE-01`

## E-ACIL-01 · Acil durum çağrısı
1. YÖNETİCİ `/dashboard/emergency` → **Nokta ekle**, **Acil iletişim ekle**, **Tatbikat raporu** → **Durum bildirimi çağrısı**.
2. Çağrı sakinlere `safety.check` bildirimi olarak gider. KİRACI sakin `/emergency` → **Güvendeyim**; MALİK_B1 → **Yardım gerekiyor** (yönetime `safety.need_help`). Panelde yanıtlar canlı; **Çağrıyı kapat**.
3. MALİK_B1 acil bilgi kartını **Açık rızamla kaydet**, sonra **Kartımı ve rızamı sil** → kart silinir.
- **Sonuç:** `E-ACIL-01`

## E-SIGORTA-01 · DASK ve hasar
1. MALİK_B1 sakin `/dask` → **Poliçe gir** (bitiş 20 gün sonra) → zamanlayıcı DASK hatırlatması (B-ZAMAN-DASK-RENEWAL).
2. YÖNETİCİ `/dashboard/insurance` → **Hasar kaydı** → **Hasar durumunu ilerlet**.
- **Sonuç:** `E-SIGORTA-01`

## E-SOZLESME-01 · Sözleşme ve ihbar
1. YÖNETİCİ `/dashboard/contracts` → **Sözleşme ekle** (bitiş 30 gün sonra, ihbar 30 gün) → 1-2 dk içinde zamanlayıcıdan `contract.notice` bildirimi.
2. **Yenile**, **Sözleşmeyi feshet**, **Süresi dolanları işle**.
- **Sonuç:** `E-SOZLESME-01`

## E-DEMIRBAS-01 · Demirbaş, bakım, stok
1. YÖNETİCİ `/dashboard/assets` → **Demirbaş kategorisi** → **Demirbaş ekle** (sonraki bakım 7 gün sonra) → `asset.maintenance` bildirimi → **Bakım kaydı** → **Hurdaya ayır**.
2. `/dashboard/inventory` → **Stok kategorisi ekle** → **Stok kalemi ekle** (asgari 5) → stok hareketiyle 5'in altına indir → `inventory.low_stock` yönetime (sakinlere DEĞİL) → kalemi gerekçeyle pasife al; hareket geçmişi korunur.
- **Sonuç:** `E-DEMIRBAS-01`

## E-BILDIRIM-01 · Toplu bildirim ve ticari ileti onayı
1. YÖNETİCİ `/dashboard/notifications` → **Bildirim gönder**: kategori İŞLEMSEL, kanal SMS+uygulama içi, alıcı tüm sakinler.
2. Beklenen: yanıtta sayaçlar (gönderilen / kuyrukta / bastırılan); SMS kutusunda sakin numaraları; DENETÇİ/GÖREVLİ'ye gitmez.
3. Aynısını **TİCARİ** kategoride gönder: tanıtım iletisi onayı olmayan sakinlere **gönderilmez** (`SUPPRESSED`, gerekçe). MALİK_B1 sakin profilinde "Tanıtım ve kampanya iletileri"ni açar → tekrar gönderim → yalnız ona gider.
- **Sonuç:** `E-BILDIRIM-01`

## E-AYAR-01 · Site ayarları, saklama süresi, imha, işlem kaydı düzeyi
1. YÖNETİCİ `/dashboard/settings` → bir ayarı değiştir ve **Sıfırla**; mevzuat parametresini ezmeye çalış (ör. gecikme oranı) → reddedilir.
2. **Saklama süresi** tanımla (ziyaretçi 1 gün) → **Şimdi imha et** → eski ziyaretçi kayıtları anonimleşir.
3. İşlem kaydı düzeyini değiştir (`ACTIVITY_LOG_LEVEL`) → sakin uygulamasında birkaç ekran gez → Q-AUDIT'te `source = CLIENT` satırları düzeye göre var/yok; KAPALI'da bile zorunlu çekirdek (giriş, para) yazılır.
4. `/dashboard/audit` (YÖNETİCİ, DENETÇİ) → filtre, istatistik, CSV indir.
- **Sonuç:** `E-AYAR-01`

## E-PASIF-01 · Site pasifleştirme (EN SONA BIRAKIN)
1. YÖNETİCİ Yön.mobil site ayarları / panel → TEST Kule sitesini (O-SITE-02'de açılan) **Siteyi pasife al** (gerekçe + site adı onayı).
2. Beklenen: pasif sitede yeni kayıt/bildirim yazılamaz (tetikleyiciler), okuma sürer; **Siteyi yeniden etkinleştir**.
3. **Güneş Sitesi'ni pasife ALMAYIN** (diğer testleri bozar).
- **Sonuç:** `E-PASIF-01`
