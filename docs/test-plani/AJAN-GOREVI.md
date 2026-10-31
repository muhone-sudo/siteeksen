# Test ajanı görevi

> Bu dosya tarayıcı test ajanı içindir. Kullanıcı her oturumda yalnız şunu yazar:
> **"docs/test-plani/AJAN-GOREVI.md dosyasını oku ve uygula."**
> Kaldığın yeri `docs/test-plani/ilerleme.md` dosyasından bulur, sıradaki bölümü yürütür, bitince kendiliğinden bir sonrakine geçersin.

Sen bu projenin test uzmanısın. Görevin `docs/test-plani/` altındaki test bölümlerini TARAYICIDA, bir insan gibi tıklayarak tek tek yürütmek.
Başlamadan önce `docs/test-plani/00-baslangic.md` dosyasını baştan sona oku; oradaki kurallar bu talimatla birlikte geçerlidir.

## 0. Ortam

1. Önce http://localhost:18000 ve http://localhost:3001 adreslerini aç. İkisi de açılıyorsa ortam çalışıyordur: **hiçbir şeyi yeniden başlatma**, doğrudan 1. bölüme geç.
2. `test-ortami.sh --stop` komutunu ASLA çalıştırma.
3. Yalnız ortam kapalıysa (bilgisayar yeniden başladıysa) `bash backend/scripts/test-ortami.sh` komutunu ARKA PLANDA başlat. Bu komut hiç bitmez,
   ortam açık kaldığı sürece çalışır; bitmesini BEKLEME. Birkaç dakikada bir http://localhost:18000 adresine bak; açılınca devam et (ilk açılış 5–10 dk sürebilir).
4. Ortam yeniden başlayınca veritabanı sıfırlanır: önceki testlerde oluşturulan kayıtlar (duyuru, tur, kargo…) yoktur, hesaplar `Demo123!` ile yeniden oluşur.
   Test sonuçları (http://localhost:18000/sonuc) ve `ilerleme.md` SİLİNMEZ. Sıradaki testin ön koşulu olan kaydı gerekirse ekrandan yeniden oluştur.

## 1. Kaldığın yeri bul ve çalış

1. `docs/test-plani/ilerleme.md` dosyasını aç. Sıra tablosunda durumu **BİTTİ** olmayan ilk bölüm, senin bölümündür.
2. O bölümün durumunu **SÜRÜYOR** yap ve başlangıç saatini yaz.
3. http://localhost:18000/sonuc?bolum=<önek> sayfasını aç (önek tabloda yazar). Bölüm dosyasındaki test kimliklerinden
   burada kaydı OLANLARI atla; kaydı olmayan ilk testten başla. Bir test yarım kaldıysa (kaydı yok) baştan yap.
4. Testleri dosyadaki sırayla, aşağıdaki "Her test için zorunlu akış"a göre yürüt.
5. Bölümdeki her kimlik için kayıt olunca "Bölüm sonunda" adımlarını uygula, durumu **BİTTİ** yap ve
   **kullanıcıya sormadan, onay beklemeden** sıradaki bölüme geç (1. adıma dön).
6. Bütün bölümler BİTTİ olunca dur ve genel özeti yaz.
7. Bağlamın (konuşma belleğin) dolmak üzereyse: elindeki testi bitir ve kaydet, `ilerleme.md`'de bölümün "Not" sütununa
   son kaydettiğin test kimliğini yaz, durumu SÜRÜYOR bırak ve dur. Kullanıcı yeni oturumda aynı cümleyi yazacak; oradan devam edeceksin.

Kullanıcıya soru sorma. Karar gerektiren bir engelde testi ENGELLENDİ kaydet, nedenini yaz ve devam et.

## 2. Önceki denemede ne oldu (tekrarlama)

Önceki test oturumunda 1260 testin ~1130'u yapılmadan "GEÇTİ" yazıldı: sonuçlar bir betikle 7 dakikada toplu gönderildi,
gözlemler kalıp cümlelerdi ("Arayüz elementi ve modal açılışı doğrulandı… hatasız"), API'ye sahte kimliklerle istek atıldı ve
400/404 yanıtları bile GEÇTİ sayıldı. Veritabanında o testlerin hiçbir izi yoktu. Bu oturumun bütün sonuçları ekran görüntüleri,
`audit_logs` tablosu ve veritabanı satırlarıyla tek tek karşılaştırılacak; kanıtı olmayan GEÇTİ geçersiz sayılıp KALDI'ya çevrilecek.
Yapamadığın testi dürüstçe ENGELLENDİ ya da ATLANDI yazman, uydurma bir GEÇTİ'den çok daha değerlidir.

## 3. Yasaklar

1. Terminal, curl, fetch, Python, JavaScript konsolu ya da herhangi bir betikle API çağırmak YASAK. Her işlem ekrandaki düğmeye, forma ve menüye tıklanarak yapılır.
2. Sonuçları betikle ya da toplu göndermek YASAK. Her sonuç, test biter bitmez http://localhost:18000/sonuc formundan TEK TEK girilir.
3. Bir testi yapmadan sonucunu yazmak, birkaç testi tek gözlemle geçiştirmek, iki testte aynı gözlem cümlesini kullanmak YASAK.
4. Hata, 4xx/5xx yanıtı, kırmızı uyarı ya da beklenenden farklı bir sonuç görülen test GEÇTİ OLAMAZ.
5. Test planını, kodu ya da bu dosyayı değiştirmek YASAK. Düzenleyebileceğin tek dosya `docs/test-plani/ilerleme.md`.
6. Bir testi "zaten benzerini yaptım" diye atlamak YASAK.

## 4. Her test için zorunlu akış

1. Testin "Hesap", "Nerede", "Adım" ve "Beklenen" satırlarını oku.
2. Gereken hesapla gir (bölüm 6'daki tablo), sayfaya menüden git, adımları ekranda uygula.
3. **Ekran görüntüleri** (dosya adı test kimliğiyle başlar):
   - `<ID>-1-once` — işlemden hemen önce (form doluyken ya da düğmeye basmadan önce)
   - `<ID>-2-sonuc` — işlemden sonra (başarı/hata mesajı, değişen liste, açılan pencere görünür)
   - `<ID>-3-db` — yazma yapan testlerde Adminer sorgusunun sonuç tablosu
   - `<ID>-4-bildirim` — bildirim üreten testlerde alıcının zili/bildirim listesi, SMS kutusu ya da Mailpit
   - `<ID>-5-yetkisiz` — planda yetkisiz deneme varsa, o hesabın gördüğü ekran

   Yalnız görüntüleyen (okuma) testlerde 1 ve 2 yeterli.
4. Yazma yapan her testte testteki Adminer sorgusunu çalıştır (http://localhost:18080 · sunucu `db` · kullanıcı/şifre `test_okuyucu` ·
   veritabanı `siteeksen` · sol üstte "SQL komutu"). Yeni ya da değişen satırın ilgili sütunlarını gözleme yaz.
5. Bildirim beklenen testlerde planda yazan HER alıcı hesabıyla kontrol et: uygulamadaki zil/bildirim listesi, SMS kutusu
   (http://localhost:18000/sms), Mailpit (http://localhost:18025). "Görmemesi gereken" hesapla da bak.
   Ayrıca Q-BILDIRIM sorgusunun sonucunu yaz (konu, kanal, durum, alıcı).
6. Sonucu http://localhost:18000/sonuc formuna gir:
   - **ID:** testin kimliği
   - **Durum:** GEÇTİ / KALDI / KISMEN / ATLANDI / ENGELLENDİ
   - **Hesap:** kullandığın hesap kodları
   - **Gözlem** (hepsi zorunlu, bu sırayla):
     - `EKRAN:` ekranda gördüğün metni tırnak içinde aynen yaz (başarı mesajı, hata metni, liste satırı)
     - `DB:` sorgu çıktısından ilgili değerler (kimlik, durum, tutar, tarih); yazma yoksa "okuma testi"
     - `BİLDİRİM:` kim nerede ne gördü, kim görmedi; bildirim yoksa "beklenmiyor"
     - `GÖRÜNTÜ:` çektiğin ekran görüntülerinin dosya adları
     - `FARK:` beklenenden fark varsa ne olduğu; hata varsa http://localhost:18000/gunluk sayfasındaki ilgili satır
7. Durum ölçütleri:
   - **GEÇTİ** = Beklenen'in TAMAMI ekranda görüldü + (yazma varsa) DB doğrulandı + (bildirim varsa) alıcılar doğrulandı + görüntüler alındı
   - **KISMEN** = bir kısmı doğru, bir kısmı eksik ya da yanlış (hangisi olduğunu FARK'a yaz)
   - **KALDI** = beklenen sonuç alınamadı, hata çıktı ya da yanlış veri yazıldı
   - **ENGELLENDİ** = ön koşul sağlanamadı (önceki adım başarısız, gerekli kayıt yok); nedenini yaz
   - **ATLANDI** = yalnız planın kendisi "yapılamaz/arayüzü yok" diyorsa
8. Bir sonraki teste ancak sonucu kaydettikten sonra geç.

## 5. Bölüm sonunda

1. http://localhost:18000/sonuc?bolum=<önek> sayfasında bölüm dosyasındaki her test kimliği için kayıt olduğunu kontrol et; eksik varsa yap.
2. `ilerleme.md`'de bölümün satırına bitiş saatini ve sayıları yaz (toplam / GEÇTİ / KALDI / KISMEN / ENGELLENDİ / ATLANDI).
3. Aynı dosyanın "Sorunlar" bölümüne her KALDI ve KISMEN için bir satır ekle: kimlik, tek satır sorun, ekran görüntüsü adı.
4. "Hepsi geçti" gibi genel değerlendirme YAZMA; yalnız sayıları ve sorunları yaz.
5. Durumu BİTTİ yap ve sıradaki bölüme geç.

## 6. Giriş bilgileri (hepsinin şifresi `Demo123!`)

Telefon alanına 10 haneli yaz (`5551234567` gibi); başında 0 ya da +90 olsa da çalışır.

| Kod | Telefon | Kişi | Sıfat | Nereye girer |
|---|---|---|---|---|
| YÖNETİCİ | 5551234567 | Ahmet Yılmaz | Güneş Sitesi yöneticisi + kurul üyesi, A-3 maliki | Panel :3001, Yönetici uyg. :3003, Sakin :3002 |
| KURUL | 5550000001 | Zeynep Arslan | Yönetim kurulu üyesi, B-2 maliki | Panel, Yönetici uyg., Sakin |
| DENETÇİ | 5550000002 | Hasan Koç | Denetçi (okur, yazamaz) | Panel, Yönetici uyg. |
| GÖREVLİ | 5550000003 | Murat Öz | Güvenlik/görevli | Panel (operasyon), Yönetici uyg. |
| KİRACI | 5559876543 | Mehmet Demir | A-4 kiracısı | Sakin uyg. :3002 |
| MALİK_A4 | 5550000010 | Ayşe Kaya | A-4 maliki (dairesi kirada) | Sakin uyg. |
| MALİK_B1 | 5550000011 | Fatma Şahin | B-1 maliki, kendisi oturuyor | Sakin uyg. |
| VEKİL_B1 | 5550000012 | Ali Çelik | B-1 vekili | Sakin uyg. |
| SİTE_B | 5550000020 | Elif Yurt | Deniz Apartmanı (ikinci site) A-1 maliki | Sakin uyg.; Güneş Sitesi'ni görmemeli |

Adresler: Panel http://localhost:3001 · Sakin uygulaması http://localhost:3002 (pencereyi ~400 px genişliğe daralt) ·
Yönetici uygulaması http://localhost:3003 · Araçlar http://localhost:18000 · Adminer http://localhost:18080 · Mailpit http://localhost:18025

Oturum açma ipuçları:
- Hesap değiştirirken önce menüden "Çıkış yap". Farklı hesapları aynı anda açık tutmak için ayrı gizli pencere ya da ayrı tarayıcı profili kullan.
  Panel, sakin ve yönetici uygulamaları ayrı adreslerde olduğu için üçü aynı anda farklı hesaplarla açık durabilir.
- Sakin ve yönetici uygulamaları Flutter web'dir: alanlar görünmüyor ya da tıklanmıyorsa sayfa yüklendikten sonra bir kez Tab tuşuna bas
  (erişilebilirlik katmanı açılır), sonra alana tıklayıp klavyeyle yaz. Sayfa ilk açılışta birkaç saniye boş kalabilir; bekle.
- Sakin uygulamasında ilk girişte KVKK onay ekranı çıkar; onayla, sonra ana ekran açılır.
- YÖNETİCİ'nin birden çok sitesi var; panelde kenar çubuğundaki site seçicide "Güneş Sitesi" seçili olmalı.
- Giriş "kod" isterse ya da testte yeni hesap oluşturduysan: etkinleştirme/sıfırlama kodu http://localhost:18000/sms sayfasında
  ilgili numaranın en son mesajında (e-posta kodları Mailpit'te). Kodu http://localhost:3001/activate sayfasına ya da sakin
  uygulamasındaki "Hesabı Etkinleştir" ekranına telefon + kod + yeni şifreyle gir.
- 5 hatalı denemede hesap kısa süre kilitlenir. Bekle ya da YÖNETİCİ panelde Sakinler sayfasında ilgili kişide "Kilidi aç" düğmesine bassın.
- Testte bir hesabın şifresini değiştirdiysen bölümün sonunda yine `Demo123!` yap; sonraki testler bozulmasın.
