# Modül Envanteri — Olması Gereken Referans Model

Bu dosya **"ne olmalı"yı** tanımlar; **"ne var"** ile karşılaştırma `tasks/gap-analizi.md` dosyasındadır.
Amaç: bir Türkiye site/apartman yönetim platformunun eksiksiz modül haritasını çıkarmak, böylece
"her özellikte düşünülmemiş tamamlayıcı parçalar" sistematik olarak görünür hale gelsin.

Son güncelleme: 2026-09-08

## Yöntem ve kaynaklar

1. **Mevzuat türevli zorunluluklar** — 634 sayılı Kat Mülkiyeti Kanunu (KMK) ve ilgili ikincil mevzuat.
   Madde atıfları `tasks/questions.md` → S-05 tablosunda toplanmıştır ve **hukuki teyit beklemektedir**.
   Kural: hiçbir oran/süre koda gömülmez, tümü yürürlük tarihli parametre olarak tutulur.
2. **Operasyonel gerçeklik** — bir sitenin/apartmanın yıl içinde fiilen yürüttüğü işler
   (bütçe, tahakkuk, tahsilat, bakım, personel, toplantı, denetim, hukuk).
3. **Rakip zayıflıkları** — `yorum_analizleri.txt` (Apsiyon sakin + yönetici uygulaması yorum analizi).
   Bu dosyadan çıkan somut ürün gereksinimleri modüllere `[APS-n]` etiketiyle işlenmiştir.
4. **Platform mühendisliği** — çok kiracılı SaaS'ın kesişen yetenekleri (kimlik, izolasyon, denetim izi,
   dosya, bildirim, entegrasyon, gözlemlenebilirlik).

## Öncelik tanımları

| Kod | Anlam |
|-----|-------|
| **P0** | Olmazsa ürün ya yasal olarak eksik ya da temel işleyişi kuramaz. MVP zorunlu. |
| **P1** | Rekabet paritesi. Olmadan ürün "yarım" görünür, müşteri kaybeder. |
| **P2** | Farklılaştırıcı. Rakipten ayrışmayı sağlar. |
| **P3** | İleri seviye / opsiyonel / ölçek büyüdüğünde. |

## Apsiyon yorumlarından çıkan somut gereksinimler (etiket sözlüğü)

| Etiket | Gereksinim | İlgili modül |
|--------|-----------|--------------|
| APS-1 | Oturum sürekli düşmemeli; biyometrik ile hızlı giriş | M-01 |
| APS-2 | OTP (SMS/e-posta) gerçekten teslim edilmeli, kuyruk mimarisi | M-01, M-05 |
| APS-3 | Şifre sıfırlama çökmemeli, uçtan uca çalışmalı | M-01 |
| APS-4 | Ödeme ekranı native olmalı, WebView değil; çökmemeli | M-25, M-50 |
| APS-5 | Tüketim faturası **detayı** gösterilmeli (m³, gün sayısı, birim fiyat, PDF) | M-23, M-50 |
| APS-6 | Borç kalemi seçerek/kısmi ödeme; yatan para **doğru kalemden** düşmeli | M-24, M-25 |
| APS-7 | Banka hareketi anında borçtan düşmeli (webhook/asenkron), boşuna faiz işlememeli | M-25 |
| APS-8 | Android donanımsal geri tuşu uygulamayı kapatmamalı | M-50, M-51 |
| APS-9 | Uygulama hızlı olmalı; her geçişte 2-3 sn beklememeli | M-50, M-51 |
| APS-10 | Yeni borç/duyuruda **push bildirim** gelmeli | M-05, M-47 |
| APS-11 | Bildirim kategorileri gerçekten kapatılabilmeli (kampanya vs finansal) | M-05 |
| APS-12 | Talep, sakin onayı olmadan tek taraflı kapatılamamalı | M-30 |
| APS-13 | Tenant veri izolasyonu kesin olmalı; veri karışmamalı | M-02 |
| APS-14 | Yönetici **mobilden gider/tahsilat işleyebilmeli** (en büyük şikayet) | M-51, M-26, M-25 |
| APS-15 | Kasa durumu / IBAN / banka hesapları mobilde görünmeli | M-27, M-51 |
| APS-16 | Ödemeyi daire sakiniyle **eşleştirme** mobilden yapılabilmeli | M-25, M-51 |
| APS-17 | Özelleştirilebilir yönetici dashboard'u (widget) | M-51 |
| APS-18 | Rol bazlı yetki gerçekten çalışmalı (denetçi harcama girmemeli, tabloları görmeli) | M-01, M-60 |
| APS-19 | Uygulama içi destek/bilet + log ekli hata bildirimi | M-52 |
| APS-20 | Açık bankacılık entegrasyonu stabil olmalı | M-25 |

---

# KATMAN 0 — Platform ve Kesişen Yetenekler

Bu katman iş modüllerinden önce gelir: üzerine inşa edilecek zemin. Zayıf kalırsa her iş modülü zayıf kalır.

### M-01 · Kimlik ve Erişim Yönetimi (IAM) — P0
**Amaç:** Kim olduğunu kanıtlayabilen, yetkisi kadar iş yapabilen kullanıcı.
**Alt yetenekler:**
- Kayıt/davet akışı: yönetici sakini davet eder → sakin telefon/e-posta ile hesabını aktive eder (self-servis kayıt tek başına olmamalı; bir bağımsız bölüme bağlanma doğrulaması gerekir)
- Telefon ve e-posta doğrulama (OTP): kod üretimi, süre, deneme sınırı, yeniden gönderme bekleme süresi, teslim güvencesi `[APS-2]`
- Şifre politikası, şifre sıfırlama (uçtan uca çalışan, token süreli) `[APS-3]`
- Oturum: kısa ömürlü access + rotasyonlu refresh token, refresh token yeniden kullanım tespiti, cihaz listesi, uzaktan oturum kapatma `[APS-1]`
- Biyometrik giriş (yerel doğrulama + güvenli saklanan refresh token) `[APS-1]`
- İki adımlı doğrulama (yönetici/muhasebe rolleri için zorunlu tutulabilir)
- Hesap kilitleme, brute-force ve kimlik bilgisi doldurma (credential stuffing) koruması, IP/oran sınırı
- Yetki modeli: rol + **kapsam** (hangi yönetim organizasyonu / hangi site / hangi blok / hangi bağımsız bölüm)
- Yetki devri (yönetici izne çıkarken vekil ataması), geçici yetki (süreli)
- Servis hesapları / API anahtarı (turnike, sayaç okuma cihazı, muhasebe yazılımı için)
- Kimlik olaylarının denetim izi (giriş, başarısız giriş, yetki değişimi, rol ataması)
**Bağımlılık:** M-02, M-03, M-05
**Sık atlanan tamamlayıcılar:** refresh token rotasyonu ve yeniden kullanım tespiti; oturum kapatınca token'ın gerçekten geçersizleşmesi (kara liste); rol değişince mevcut token'ın yetkisinin güncellenmesi; kullanıcı bir siteden ayrıldığında erişimin otomatik kesilmesi.

### M-02 · Çok Kiracılılık ve Kapsam İzolasyonu — P0
**Amaç:** Bir sitenin verisi başka bir siteye asla sızmasın. `[APS-13]`
**Alt yetenekler:**
- Tenant çözümleme (alt alan adı, başlık veya token talebi) ve isteğin tamamına taşınması
- **Zorunlu** satır düzeyi izolasyon: ya veritabanı seviyesinde satır güvenliği (RLS) ya da her sorguda kaçınılmaz tenant filtresi (kod incelemesiyle değil, mimariyle garanti edilmeli)
- Kapsam sızıntısı testleri (bir tenant'ın token'ıyla diğerinin kaynağına erişim denemesi otomatik test edilmeli)
- Tenant bazlı yapılandırma, tema/logo, parametreler
- Tenant yaşam döngüsü: kurulum, askıya alma, veri ihracı, tam silme (KVKK)
- Çapraz tenant raporlama yalnızca yönetim organizasyonu kapsamında (M-57)
**Sık atlanan tamamlayıcılar:** dosya depolamada tenant ayrımı (imzalı URL'in başka tenant dosyasına erişmemesi); arka plan işlerinde ve kuyruk mesajlarında tenant bağlamının taşınması; önbellek anahtarlarına tenant eklenmesi; tenant bazlı hız sınırı.

### M-03 · Denetim İzi ve Değişiklik Geçmişi — P0
**Amaç:** "Bu tahakkuku kim değiştirdi?" sorusunun kanıtlı cevabı; KVKK ve KMK denetim gereği.
**Alt yetenekler:**
- Kim / ne zaman / hangi kaynak / hangi işlem / önceki değer → yeni değer
- Hassas veri **okuma** logu (TCKN görüntüleme, şifre/kimlik bilgisi gösterme, borç listesi ihracı)
- Ekle-yalnız (append-only) saklama; uygulama kullanıcısının silme yetkisi olmaması
- Saklama süresi ve arşivleme; arama, filtreleme, dışa aktarma
- Finansal işlemler için ayrı, daha ayrıntılı iz (tahakkuk, tahsilat, iade, faiz affı, silme)
- KVKK ilgili kişi başvurusuna yanıt üretebilme (bir kişinin verisinin nerede işlendiğini raporlama)
**Sık atlanan tamamlayıcılar:** denetim kaydının kendi başına anlamlı olması (ilişkili kaydın adı/etiketi de yazılmalı, sadece kimlik değil); toplu işlemlerin tek kayıt yerine etkilenen kayıt sayısıyla loglanması; arka plan işlerinin ve sistem kullanıcısının ayırt edilmesi.

### M-04 · Dosya ve Doküman Depolama — P0
**Amaç:** Fatura görüntüsü, tutanak, sözleşme, talep fotoğrafı, sayaç fotoğrafı gibi dosyaların güvenli, kalıcı saklanması.
**Alt yetenekler:**
- Nesne depolama (S3 uyumlu), tenant bazlı ayrım, sunucu tarafı şifreleme
- Yükleme: tür/boyut kısıtı, kötü amaçlı içerik taraması, görüntü küçültme/optimizasyon, EXIF temizleme (konum sızıntısı!)
- İndirme: kısa ömürlü imzalı bağlantı, yetki kontrolü (dosyaya erişim, kaydın yetkisine bağlı olmalı)
- Sürümleme, silme politikası, yasal saklama süresi, imha kaydı
- Metin çıkarma / OCR (fatura, tutanak arama için)
- Belge şablonları ve üretimi (PDF: makbuz, ihtar, tutanak, borcu yoktur yazısı)
**Sık atlanan tamamlayıcılar:** mobilde offline çekilen fotoğrafın kuyruğa alınıp bağlantı gelince yüklenmesi; yükleme yarıda kalırsa temizlik; aynı dosyanın tekrar yüklenmesinde tekilleştirme; dosya boyutunun tenant kotasına sayılması.

### M-05 · Bildirim Altyapısı — P0
**Amaç:** Doğru kişiye, doğru kanaldan, gerçekten ulaşan bildirim. `[APS-2] [APS-10] [APS-11]`
**Alt yetenekler:**
- Kanallar: mobil push, SMS, e-posta, uygulama içi, WhatsApp (opsiyonel)
- Şablon yönetimi (değişkenli, sürümlü, çok dilli), önizleme
- **Bildirim kategorileri:** finansal (zorunlu), operasyonel, sosyal, kampanya (kapatılabilir) `[APS-11]`
- Kullanıcı tercihleri: kanal × kategori matrisi, sessiz saatler
- Kuyruk, yeniden deneme, geri çekilme (backoff), ölü mektup kutusu; sağlayıcı arızasında kanal geçişi
- Teslim/okuma raporu, başarısız gönderim görünürlüğü, SMS maliyet takibi
- Toplu gönderim (hedefleme: site/blok/kat/rol/borçlu), gönderim planlama
- Cihaz token yönetimi (kayıt, yenileme, geçersiz token temizliği)
**Sık atlanan tamamlayıcılar:** bildirime tıklayınca ilgili ekrana derin bağlantı; okunmadı sayacı (badge) `[APS-10]`; aynı olayın birden çok kanaldan tekrarlanmaması; kullanıcı siteden ayrılınca gönderimin durması; bildirim geçmişinin kullanıcıya gösterilmesi.

### M-06 · Entegrasyon Katmanı — P0
**Amaç:** Dış sistemlerle dayanıklı, tekrarlanabilir, izlenebilir iletişim.
**Alt yetenekler:**
- Sağlayıcı bağımsız arayüz (port/adapter): ödeme, banka, SMS, e-posta, e-fatura, AI, IoT/sayaç, erişim kontrol donanımı
- Gelen webhook: imza doğrulama, tekrar saldırısı koruması, **idempotency**, sıra dışı gelen olaylar
- Giden çağrı: zaman aşımı, yeniden deneme, devre kesici (circuit breaker), oran sınırı
- Entegrasyon olay günlüğü (istek/yanıt, hassas alan maskeleme), yeniden oynatma (replay)
- Sandbox/üretim ayrımı, anahtar yönetimi, anahtar yokken güvenli devre dışı davranış
- Mutabakat işleri (banka ekstresi ↔ tahsilat kaydı)
**Sık atlanan tamamlayıcılar:** aynı webhook'un iki kez gelmesi (idempotency anahtarı zorunlu); sağlayıcı yanıtı geciktiğinde kullanıcıya "beklemede" durumu gösterme; entegrasyon kapalıyken arayüzde "yapılandırılmadı" gösterimi.

### M-07 · İş Akışı ve Onay Motoru — P1
**Amaç:** Harcama, tadilat izni, izin talebi gibi çok adımlı onayların tutarlı yürütülmesi.
**Alt yetenekler:** onay şablonu (tutar/kategori eşiğine göre), sıralı/paralel onay, vekâlet, hatırlatma, süre aşımı eskalasyonu, red gerekçesi, onay geçmişi, geri çekme.
**Sık atlanan tamamlayıcılar:** onaycı kendisi talep sahibiyse kilitlenme; onaycı siteden ayrılırsa akışın takılması; onay sonrası tutar değişirse yeniden onay gereği.

### M-08 · Raporlama Motoru — P0
**Amaç:** Resmî ve operasyonel raporların tek yerden, doğru veriyle üretilmesi.
**Alt yetenekler:**
- Standart rapor kataloğu (M-53), parametreli çalıştırma, dönem seçimi
- PDF/Excel/CSV çıktısı, kurum kimliği (logo, site adı), imza alanları, sayfa numarası, üretim zamanı ve üreten kullanıcı
- Zamanlanmış rapor ve e-posta ile gönderim (örn. her ayın 1'inde denetçiye)
- Rapor arşivi ve tekrar indirme; büyük raporlar için asenkron üretim ve hazır olunca bildirim
- Rapor verisinin **tek kaynaktan** gelmesi (ekranla rapor arasında sayı farkı olmamalı)
**Sık atlanan tamamlayıcılar:** raporun üretildiği andaki veriyi dondurma (aynı raporun sonradan farklı sayı vermemesi); dönem kapanmışsa "kesinleşmiş" damgası; Türkçe karakter ve para/tarih biçimlendirmesi; büyük veri kümesinde zaman aşımı.

### M-09 · Yapılandırma ve Parametre Yönetimi — P0
**Amaç:** Mevzuat ve yönetim planı farklılıklarının kod değişikliği olmadan karşılanması.
**Alt yetenekler:**
- Site bazlı parametreler: gecikme tazminatı oranı, mahsup sırası, dağıtım kuralları, ısı paylaşım oranları, hesap planı, çalışma saatleri, rezervasyon kuralları
- **Yürürlük tarihli** parametre (geçmişe dönük hesaplar eski oranla kalmalı)
- Parametre değişikliği denetim izi ve gerekçe alanı
- Her parametreye mevzuat/yönetim planı dayanağı alanı
- Varsayılan şablonlar (yeni site kurulunca makul varsayılanlarla başlama)
**Sık atlanan tamamlayıcılar:** parametre değiştiğinde geçmiş tahakkukların yeniden hesaplanmaması (dondurma); yönetim planı bir konuda sessizse kanuni varsayılana düşme; parametrenin hangi hesabı etkilediğinin arayüzde açıklanması.

### M-10 · Gözlemlenebilirlik ve Operasyon — P0
**Amaç:** Sorunu kullanıcı bildirmeden görmek; "uygulama çöküyor/yavaş" şikayetlerini ölçmek. `[APS-9]`
**Alt yetenekler:** yapılandırılmış log (istek kimliği, tenant, kullanıcı), metrik (gecikme, hata oranı, kuyruk boyu), dağıtık izleme, hata takibi (mobil çökme raporu dahil), sağlık kontrolü, uyarı kuralları, gösterge panosu, sürüm/dağıtım takibi.
**Sık atlanan tamamlayıcılar:** loglarda kişisel veri maskeleme (KVKK); mobil uygulamadan gelen çökme raporunun sürümle eşleştirilmesi; yavaş sorgu görünürlüğü; iş kuyruğu birikmesi uyarısı.

### M-11 · Güvenlik — P0
**Amaç:** Para ve kişisel veri tutan bir sistemin savunulabilir olması.
**Alt yetenekler:** aktarımda/durağanda şifreleme, sır yönetimi (kodda anahtar olmaması), WAF/oran sınırı, girdi doğrulama, yetki kontrolünün her uçta zorunlu olması, bağımlılık güvenlik taraması, güvenli dağıtım, sızma testi, güvenlik olayı müdahale planı, KVKK ihlal bildirimi süreci (72 saat), yedeklerin şifrelenmesi.
**Sık atlanan tamamlayıcılar:** API geçidinin (gateway) arkasındaki servislerin doğrudan erişime kapatılması; iç servisler arası kimlik doğrulama; hata mesajlarının bilgi sızdırmaması; mobil uygulamaya gömülü anahtar olmaması; yetkilendirmenin arayüzde gizlemeyle değil sunucuda zorlanması.

### M-12 · Veri Yaşam Döngüsü ve Şema Yönetimi — P0
**Amaç:** Şemanın her ortamda öngörülebilir biçimde ilerlemesi.
**Alt yetenekler:**
- **Migration çalıştırıcı** (uygulanmış sürümü izleyen, eksikleri açılışta uygulayan, kilitle yarış koşulunu engelleyen)
- İleri/geri (up/down) betikler, idempotent yazım, üretimde güvenli uygulama sırası
- Tohum (seed) verisi ile gerçek veri ayrımı; demo verisinin üretime karışmaması
- Yedekleme, geri yükleme **provası**, saklama/imha politikası, arşivleme
- Veri sözlüğü / şema dokümantasyonu
**Sık atlanan tamamlayıcılar:** birden çok servis aynı veritabanını paylaşıyorsa migration sahipliğinin belirsiz kalması; geri yükleme denenmediği için yedeğin işe yaramaması; büyük tabloda kilitleyen migration.

---

# KATMAN 1 — Taşınmaz ve Kişi Ana Verisi

### M-13 · Taşınmaz Yapısı (Portföy → Site → Blok → Bağımsız Bölüm) — P0
**Amaç:** Tüm hesapların ve yetkilerin dayandığı fiziksel gerçeğin doğru modellenmesi.
**Alt yetenekler:**
- Hiyerarşi: yönetim organizasyonu → toplu yapı (site) → ada → blok → kat → bağımsız bölüm; ayrıca eklentiler (depo, otopark, çatı katı) ve ortak yerler
- Bağımsız bölüm nitelikleri: **arsa payı**, brüt/net alan, oda sayısı, kullanım türü (mesken/işyeri/depo/otopark), kat (zemin/bodrum/normal), cephe, asansör ilişkisi, ısıtma tipi
- Tapu bilgisi: il/ilçe, ada/parsel, bağımsız bölüm numarası, kat irtifakı/kat mülkiyeti durumu
- Ortak yer envanteri ve hangi bağımsız bölümlerin hangi ortak yerden yararlandığı (gider dağıtımının temeli)
- **Blok bazlı gider ayrımı** desteği (toplu yapılarda blok gideri ≠ site gideri) `[S-13]`
- Arsa payı toplamının tutarlılık denetimi; arsa payı değişikliği (birleştirme/ayırma) geçmişi
- Konum/harita, kroki/mimari plan eki
**Sık atlanan tamamlayıcılar:** arsa payı toplamı 1'e/100'e tamamlanmıyorsa dağıtımın bozulması; bağımsız bölüm birleştirme/ayırma sonrası geçmiş tahakkukların bütünlüğü; boş/kullanılmayan bölümün gider yükümlülüğü; işyeri/dükkân için farklı katsayı; asansörsüz zemin kat muafiyeti kuralının yönetim planına bağlı olması.

### M-14 · Kişi ve İlişki Yönetimi — P0
**Amaç:** "Bu daireden kim sorumlu?" sorusunun her an ve **geçmişe dönük** doğru cevabı.
**Alt yetenekler:**
- Kişi kartı: ad, iletişim, TCKN/VKN (şifreli), doğum tarihi, adres, iletişim tercihi
- İlişki türleri: malik, paylı malik (pay oranıyla), kiracı, oturan aile üyesi, vekil, mirasçı, intifa hakkı sahibi
- **Tarihli ilişki:** başlangıç/bitiş tarihi (borcun hangi döneme kimin sorumluluğunda olduğu buradan çıkar)
- Kiracı sözleşmesi (süre, kira, depozito, artış), kiracı giriş/çıkış işlemleri
- Malik ↔ kiracı sorumluluk ayrımı (KMK m.22: kiracı ortak giderden kira bedeli kadar müteselsil sorumlu)
- KVKK rıza kaydı ve sürümü, aydınlatma metni onay geçmişi
- Aile üyesi/ek kullanıcı yönetimi (eşin de uygulamayı kullanması), yetki seviyesi
- Birleştirme (aynı kişinin mükerrer kaydı), arama
**Sık atlanan tamamlayıcılar:** daire el değiştirdiğinde eski malikin uygulama erişiminin kesilmesi ama geçmiş borç sorumluluğunun korunması; paylı malikiyette tahakkukun kime çıkacağı ve tebligatın kime yapılacağı; vefat/mirasçı durumu; yabancı uyruklu malik (TCKN yok); iletişim bilgisi olmayan malike tebligat.

### M-15 · Devir, Çıkış ve "Borcu Yoktur" — P1
**Amaç:** Daire satışı/kiracı değişiminde finansal ve fiziksel devrin eksiksiz yapılması.
**Alt yetenekler:**
- Devir başlatma, borç sorgusu ve dondurma, **borcu yoktur / borç durum belgesi** üretimi (resmî çıktı)
- Yeni malikin müteselsil sorumluluğunun kaydı (KMK m.22)
- Sayaç son okuma ve devir, demirbaş/anahtar teslim tutanağı, depozito iadesi/mahsubu
- Devir sonrası erişim yetkilerinin otomatik güncellenmesi
- Kiracı çıkışında hasar/eksik tespit ve depozito kesintisi
**Sık atlanan tamamlayıcılar:** devir tarihi ile tahakkuk dönemi çakışması (ayın ortasında satış → gün bazlı bölüşüm kuralı); devir sonrası eski malike gelen bildirimlerin kesilmesi; kanuni ipotek kaydı varsa uyarı.

---

# KATMAN 2 — Yönetişim (KMK Zorunlulukları)

> Bu katman bugünkü projede **neredeyse tamamen yok** ve bir Türkiye site yönetim yazılımının hukuki bel kemiğidir.
> Aidat toplamanın yasal dayanağı (işletme projesi) ve icra takibi yapabilme gücü bu katmandan doğar.

### M-16 · Yönetim Planı — P0
**Amaç:** Sitenin "anayasası"nın sistemde tanımlı olması; kural motorunun dayanağı.
**Alt yetenekler:**
- Yönetim planı metni, sürümü, tapuda tescil tarihi, dosya eki
- Değişiklik süreci: **4/5 çoğunluk** oylaması (KMK m.28) → yeni sürüm → maliklere dağıtım
- Plan maddelerinin **parametrelere bağlanması**: gider dağıtım kuralları, gecikme oranı, kural ihlali yaptırımları, evcil hayvan/otopark kuralları, çalışma saatleri, aidat ödeme günü
- Maliklere/kiracılara tebliğ kaydı (KMK m.32: kararlar kiracıları da bağlar)
**Sık atlanan tamamlayıcılar:** yönetim planı bir konuda sessizken kanuni varsayılana düşme mantığı; plan değişikliğinin geçmiş dönem hesaplarını etkilememesi; plan maddesine atıf yapan her ekranda kaynağın gösterilmesi.

### M-17 · Kat Malikleri Kurulu (Genel Kurul) — P0
**Amaç:** Yılın en önemli hukuki olayının uçtan uca yönetimi. Aidatın ve bütçenin meşruiyeti buradan gelir.
**Alt yetenekler:**
- Toplantı türü: olağan (yılda en az bir), olağanüstü (maliklerin 1/3 talebi)
- **Çağrı:** gündemle birlikte, toplantıdan en az **15 gün** önce, imza karşılığı veya taahhütlü mektup; çağrı kanıtının saklanması (KMK m.29)
- Gündem yönetimi, gündeme madde ekleme talebi, gündem dışı konuların karara bağlanamaması
- Hazır bulunanlar listesi (imza çizelgesi), katılım oranının **sayı ve arsa payı** olarak canlı hesabı
- **Vekâletname yönetimi:** vekil kaydı, vekâlet sınırı kontrolü (bir kişinin taşıyabileceği azami oy), çok bağımsız bölümlü malikin oy sınırı (KMK m.31)
- **Yeter sayı motoru:** toplantı yeter sayısı (sayı ve arsa payı bakımından yarıdan fazla), sağlanamazsa ikinci toplantı (en geç 15 gün sonra, katılanların salt çoğunluğu) (KMK m.30)
- **Karar nisabı motoru** — her gündem maddesi için gereken nisap türü seçilir ve sistem hesaplar:
  salt çoğunluk / sayı+arsa payı çoğunluğu / **4/5** (ortak yerde inşaat-onarım-renk, yönetim planı değişikliği) / **oybirliği** (çatı-dış duvar reklam kirası, temliki tasarruflar)
- Oylama: el kaldırma sonucunun girilmesi, elektronik/hibrit toplantıda uzaktan oy, oy gerekçesi/şerh
- **Tutanak ve karar defteri:** karar metni, imzalar, noter tasdikli deftere işlenme, sıra numarası (KMK m.32)
- Kararların tebliği; **1 ay içinde iptal davası** takibi (KMK m.33)
- Karar uygulama takibi: her karar bir göreve/bütçe kalemine dönüşür ve tamamlanana kadar izlenir
- Toplantı arşivi, geçmiş kararlarda arama (aynı konuda daha önce ne karar verildi?)
**Sık atlanan tamamlayıcılar:** yeter sayı sağlanamayınca ikinci toplantının otomatik planlanması; vekâlet sınırı aşıldığında oyun geçersiz sayılması; nisabı yanlış seçilen kararın hukuken sakat kalması (sistem uyarmalı); karar defterinin yıl sonunda notere kapattırılması hatırlatıcısı (KMK m.36); toplantıya katılmayan malike kararların tebliği; kiracıların bilgilendirilmesi.

### M-18 · Yönetim Organları ve Görev Devri — P0
**Amaç:** Yetkinin kimde olduğunun ve devrinin kayıtlı olması.
**Alt yetenekler:**
- Yönetici / yönetim kurulu (üç kişilik) seçimi, görev süresi, ücreti (KMK m.34, m.40); **8+ bağımsız bölümde yönetici atanması zorunlu**
- Denetçi / denetim kurulu seçimi (KMK m.41)
- Toplu yapıda blok yönetimi ve temsilciler kurulu `[S-13]`
- İmza/harcama yetkileri ve limitleri, banka hesabı yetkilileri
- Profesyonel yönetim şirketi ataması (sözleşme, ücret, kapsam)
- **Devir teslim tutanağı:** kasa, banka, defterler, belgeler, demirbaş, anahtar, dijital hesaplar; devir sonrası eski yöneticinin erişiminin kesilmesi
- Görev süresi bitiminde yeniden atama hatırlatıcısı (her yıl kanuni toplantıda)
**Sık atlanan tamamlayıcılar:** yönetici değiştiğinde bekleyen onayların/işlerin yeni yöneticiye devri; eski yöneticinin denetim izindeki işlemlerinin korunması; yönetici istifası/görevden alınması akışı; vekâletle yönetim.

### M-19 · Yasal Defterler ve Belge Arşivi — P0
**Amaç:** KMK'nın açıkça zorunlu tuttuğu kayıtların dijital karşılığı ve denetime hazır dosya.
**Alt yetenekler:**
- **Karar defteri** (noter tasdikli; kararlar, protokoller, ihtar/tebligat özetleri ve tarihleri) — KMK m.32, m.36
- **İşletme defteri** (gelir-gider kayıtları, belgeleriyle) — KMK m.36
- Yıl sonunda karar defterinin **notere kapattırılması** (yıl bitiminden itibaren 1 ay) hatırlatıcısı ve kaydı
- Belge dosyası: faturalar, sözleşmeler, tutanaklar, tebligatlar, sigorta poliçeleri, muayene raporları
- Saklama süreleri, arama, dışa aktarma; denetçi/yeni yönetici için **tek tuşla "denetim paketi"**
**Sık atlanan tamamlayıcılar:** dijital defterin resmî deftere uygun sıralı ve değiştirilemez olması; bir kaydın sonradan düzeltilmesinin iptal-yeniden kayıt olarak izlenmesi; belgelerin ilgili kayıtla (gider/karar/talep) bağlantısı.

### M-20 · Denetim ve Hesap Verme — P0
**Amaç:** Yöneticinin hesap verme yükümlülüğünün (KMK m.39) ve denetçinin işinin sistemleştirilmesi.
**Alt yetenekler:**
- Denetçi rolü: harcama girmez, tüm finansal tabloları ve belgeleri görür `[APS-18]`
- **En az 3 ayda bir** denetim (KMK m.41): denetim dönemi, kontrol listesi, bulgular, karar defterine işlenmesi
- **Yıllık hesap özeti** (takvim yılının ilk ayında kurula sunulur — KMK m.39): gelir-gider, bütçe-gerçekleşme, kasa/banka mutabakatı, alacaklar
- İbra oylaması ve sonucu
- Bulgu takibi: her bulgu bir görev, kapanana kadar izlenir
- Denetçi paketi: dönem belgeleri, ekstreler, fatura görüntüleri tek pakette
**Sık atlanan tamamlayıcılar:** denetçinin veri değiştiremeyeceğinin sunucuda zorlanması (arayüzde gizlemek yetmez); denetim sırasında dönemin kilitlenmesi; bulguya itiraz süreci.

---

# KATMAN 3 — Finans

> Uyarı: `tasks/questions.md` → S-02 uyarınca finans **şema dondurması** yürürlükte olabilir.
> Bu modüllerin şema ihtiyacı `tasks/finans-sema-tasarimi.md` içinde onay bekletilir.

### M-21 · İşletme Projesi (Yıllık Bütçe) — P0 · **YASAL DAYANAK MODÜLÜ**
**Amaç:** Aidatın hukuki temeli. KMK m.37: yönetici yıllık işletme projesi hazırlar; maliklere tebliğ edilir;
**7 gün** itiraz süresi geçince kesinleşir ve **İİK m.68 anlamında belge** niteliği kazanır — yani icra takibinin dayanağıdır.
Bugünkü sistemde bu kavram yok; aidat "elle girilen tutar" olarak üretiliyor. Bu, tahsilat gücünü hukuken zayıflatır.
**Alt yetenekler:**
- Yıllık tahmini **gider bütçesi**: kalem bazlı (personel, yakıt, elektrik, su, asansör bakım, temizlik, güvenlik, sigorta, yönetim ücreti, onarım karşılığı, demirbaş, beklenmeyen giderler karşılığı)
- Yıllık tahmini **gelir bütçesi**: aidat, ortak alan kira gelirleri, gecikme tazminatı, diğer
- Her giderin dağıtım kuralının bütçede tanımlanması (eşit / arsa payı / alan / sayaç) — KMK m.20
- Her bağımsız bölüme düşen **tahmini yıllık pay** ve **aylık avans (aidat)** hesabı
- Geçmiş yıl gerçekleşmesine göre öneri üretme (bir önceki yılın verisiyle taslak bütçe)
- Enflasyon/artış senaryoları, kasa devri ve nakit akış projeksiyonu, asgari kasa hedefi
- **Tebliğ:** her malike imza karşılığı/taahhütlü mektup/uygulama içi tebliğ; tebliğ kanıtı ve tarihi
- **İtiraz:** 7 gün içinde itiraz kaydı, kurulda yeniden inceleme, revizyon
- **Kesinleşme:** kesinleşme tarihi, sürüm dondurma, PDF resmî çıktı (icra dosyasına ek olacak nitelikte)
- Yıl içi bütçe revizyonu (ek bütçe) ve kurul kararına bağlanması
- **Bütçe-gerçekleşme karşılaştırması** (aylık sapma, kalem bazlı aşım uyarısı) → M-26 harcama kontrolüne bağlanır
**Sık atlanan tamamlayıcılar:** bütçe kesinleşmeden tahakkuk çıkarılmasının engellenmesi (ya da "geçici avans" olarak işaretlenmesi); bütçe kalemi ile muhasebe hesap planının eşlenmesi; yıl ortasında yeni bağımsız bölüm eklenirse payların yeniden hesabı; kesinleşmiş bütçenin değiştirilemezliği.

### M-22 · Aidat Tahakkuku ve Gider Paylaşımı — P0
**Amaç:** Her bağımsız bölümün borcunun **kanuna ve yönetim planına uygun**, açıklanabilir biçimde üretilmesi.
**Alt yetenekler:**
- Dağıtım tipleri: **eşit** (kapıcı/kaloriferci/bahçıvan/bekçi ve yönetim giderleri — KMK m.20/1-a), **arsa payı** (sigorta primi, ortak yer bakım-onarım-güçlendirme, ortak tesis işletme — KMK m.20/1-b), yönetim planı öngörürse **alan** veya **sayaç** bazlı
- Farklılaştırma: işyeri/dükkân katsayısı, zemin kat asansör muafiyeti (yönetim planına bağlı), boş daire, eklenti (depo/otopark) payı, blok gideri ↔ site gideri ayrımı
- Dönemsel tahakkuk (aylık avans) + tek seferlik tahakkuk (olağanüstü onarım, demirbaş, ek bütçe)
- **Ön izleme:** tahakkuk oluşturmadan önce bağımsız bölüm bazlı sonuç tablosu; onaydan sonra kesinleştirme
- **Geri alma:** yanlış tahakkukun iptali (silme değil, ters kayıt) ve nedeninin kaydı
- Mükerrer tahakkuk engeli (aynı dönem-aynı bölüm tekilliği veritabanı kısıtıyla)
- **Kuruş yuvarlama:** dağıtım sonrası artan/eksilen kuruşun kurala göre dağıtılması; toplamın bütçeyle **tam** eşleşmesi
- Arsa payı toplamı beklenen değere eşit değilse **hata verip durma** (sessizce yanlış dağıtım yapmama)
- Tahakkuk tebliği ve bildirim; borç detayının sakine kalem kalem gösterilmesi `[APS-5]`
- Geçmişe dönük düzeltme (önceki dönem hatası) ve fark tahakkuku
**Sık atlanan tamamlayıcılar:** ayın ortasında el değiştiren daire için gün bazlı bölüşüm; tahakkuk çıktıktan sonra arsa payı düzeltilirse ne olacağı; sayaç bazlı kalemde okuma eksikse tahakkukun bekletilmesi; tahakkuk edilen ama tebliğ edilmemiş borcun icraya konulamaması.

### M-23 · Isı ve Su Gider Paylaşımı (Pay Ölçer) — P0
**Amaç:** Merkezi ısıtma/sıcak su giderinin yönetmeliğe uygun paylaşımı ve sakinin tüketimini görebilmesi. `[APS-5]`
**Alt yetenekler:**
- Sayaç envanteri: pay ölçer / kalorimetre / su sayacı / doğalgaz sayacı; seri no, konum, çarpan, montaj-sökme tarihi, kalibrasyon
- Okuma: manuel giriş, mobil ile fotoğraflı giriş, uzaktan okuma (IoT), toplu (CSV) içe aktarma
- Okuma doğrulama: geriye giden sayaç, aşırı sapma, sıfır tüketim, çift okuma kontrolü
- **Paylaşım motoru:** merkezi ısıtmada ölçülen tüketim payı + ortak kullanım payı (yönetmelik oranları, parametrik); sıhhi sıcak su; kayıp-kaçak ve ortak alan tüketimi
- Arızalı/okunamayan sayaç için yönetmeliğe uygun **ortalama/varsayılan tüketim** kuralı
- **Tüketim detay faturası:** dönem, ilk-son okuma, tüketim miktarı, birim fiyat, ortak alan payı, toplam — PDF olarak `[APS-5]`
- Tüketim itirazı süreci; komşu/dönem karşılaştırma; anormal tüketim uyarısı (kaçak tespiti)
- Isı gider paylaşım firması ile veri alışverişi
**Sık atlanan tamamlayıcılar:** yakıt alım maliyetinin dönemlere doğru yayılması (stok/depo mantığı); ısıtma sezonu tanımı; boş dairenin asgari ısınma payı; sayaç değişiminde iki okumanın birleştirilmesi; birim fiyatın dönem içinde değişmesi.

### M-24 · Borç, Gecikme Tazminatı ve Cari Hesap — P0
**Amaç:** Her bağımsız bölümün borcunun kalem bazında izlenebilir, açıklanabilir ve doğru olması. `[APS-6]`
**Alt yetenekler:**
- **Kalem bazlı borç:** her borç kaleminin benzersiz kimliği, türü (aidat/ısınma/su/demirbaş/ceza/gecikme), dönemi, vade tarihi, tutarı, kalan bakiyesi `[APS-6]`
- Cari hesap (ekstre): tahakkuk, ödeme, iade, faiz, mahsup hareketlerinin kronolojik dökümü ve yürüyen bakiye
- **Gecikme tazminatı** (KMK m.20/2: aylık %5 — parametrik): hesap yöntemi (gün/ay bazlı), başlangıç tarihi, bileşik olmama, üst sınır, kurul kararıyla af/indirim yetkisi ve denetim izi
- **Mahsup sırası kuralı** (yapılandırılabilir): en eski borç önce mi, faiz mi anapara mı, kalem türü önceliği — ve sakinin **seçtiği kaleme** ödeme yapabilmesi `[APS-6]`
- Alacak yaşlandırma (0-30, 31-60, 61-90, 90+ gün), borçlu listesi ve risk sıralaması
- Ödeme planı / taksitlendirme protokolü, taksit takibi, bozulma durumu
- Hesap ekstresi ve mutabakat mektubu üretimi (PDF)
- Devir durumunda borcun sorumluluk geçmişi (KMK m.22 müteselsil sorumluluk)
**Sık atlanan tamamlayıcılar:** faizin faize işlememesi; ödeme tarihinin geriye dönük girilmesinde faizin yeniden hesabı; kısmi ödemenin faiz-anapara dağılımının ekstrede görünmesi; af verilince geçmiş faizin ters kaydı; para biriminin ondalık hassasiyeti (kuruş) — **float kullanılmaması**.

### M-25 · Tahsilat Kanalları ve Banka Mutabakatı — P0
**Amaç:** Paranın gerçekten girmesi, doğru kalemden düşmesi ve mutabık kalınması. `[APS-4] [APS-6] [APS-7] [APS-16] [APS-20]`
**Alt yetenekler:**
- **Kart ile ödeme:** sanal POS/ödeme sağlayıcısı, 3D Secure, taksit, komisyon, iade; mobilde **native** akış (WebView değil) `[APS-4]`
- **Sepet mantığı:** sakin hangi kalemleri ödeyeceğini seçer, tutar ona göre oluşur `[APS-6]`
- Havale/EFT: sanal IBAN veya referans kodu ile otomatik eşleştirme
- **Banka ekstresi içe aktarma** (MT940/CSV) ve **otomatik eşleştirme** (referans, IBAN, ad-soyad, tutar benzerliği); eşleşmeyenler kuyruğu ve elle eşleştirme ekranı `[APS-16]`
- Açık bankacılık / banka API ile hareket çekme; **webhook ile anında borç düşümü** (gereksiz faiz oluşmaması) `[APS-7] [APS-20]`
- **Idempotency:** aynı ödemenin iki kez işlenmemesi (sağlayıcı tekrarı, ağ kopması, kullanıcı çift tıklaması)
- Otomatik ödeme talimatı, düzenli ödeme
- Mükerrer/fazla ödeme: iade veya alacak olarak bekletme; iade süreci ve onayı
- Makbuz/dekont üretimi ve sakine iletilmesi; tahsilat komisyonunun muhasebeleştirilmesi
- Kasa tahsilatı (elden nakit) kaydı ve kasa sorumluluğu
- Tahsilat mutabakatı: sağlayıcı raporu ↔ banka hesabı ↔ sistem kaydı üçlü kontrolü
**Sık atlanan tamamlayıcılar:** ödeme başlatıldı ama sonuç gelmedi durumunun (beklemede) yönetimi ve otomatik sorgulama; sağlayıcı komisyonunun sakine mi yönetime mi yansıyacağı; iade edilen ödemenin borcu geri açması; ödemenin hangi kaleme gittiğinin sakine anında gösterilmesi; farklı kalemler için farklı hesap kullanımı (Apsiyon şikayeti: hepsi tek hesaba gidiyor, karışıyor).

### M-26 · Gider ve Satın Alma Yönetimi — P0
**Amaç:** Paranın nereye gittiğinin belgeli, onaylı ve bütçeye karşı kontrollü olması. `[APS-14]`
**Alt yetenekler:**
- Gider kaydı: kategori, tedarikçi, tutar, KDV, tarih, belge (fatura/fiş) eki, ödeme durumu
- **Mobilden gider girme** (sahadaki yönetici için) — fotoğraf çek, AI ile alanları doldur, onaya gönder `[APS-14]`
- Fatura okuma (OCR/AI): tutar, tarih, tedarikçi, KDV, kalem çıkarma + **manuel doğrulama zorunlu**
- Faturasız gider (belgesiz harcama) için özel onay akışı ve gerekçe
- **Bütçe kontrolü:** kalem bazlı bütçe aşımında uyarı/onay eskalasyonu (M-21 ile bağlantılı)
- Tekrarlayan giderler (abonelik, bakım sözleşmesi) otomatik oluşturma
- Satın alma: talep → teklif toplama (en az 3 teklif) → karşılaştırma → onay → sipariş → teslim → fatura → ödeme
- Hakediş/kısmi teslim, tedarikçi avansı, stopaj/KDV hesabı
- Giderin **aidata yansıtılması**: hangi gider hangi dağıtım kuralıyla tahakkuka girecek (M-22)
- Ödeme emri, banka ödeme dosyası (toplu ödeme), ödeme onay zinciri
**Sık atlanan tamamlayıcılar:** aynı faturanın iki kez girilmesinin engellenmesi (fatura no + tedarikçi tekilliği); gider iptal/iade (tedarikçi iadesi); dönem kapandıktan sonra gelen fatura (geç gelen fatura politikası); giderin bir talebe/arızaya bağlanması (maliyet takibi); tedarikçi belgelerinin geçerlilik kontrolü.

### M-27 · Kasa, Banka ve Muhasebe — P0
**Amaç:** "Sitenin kasasında ne kadar para var?" sorusunun her an doğru cevabı. `[APS-15]`
**Alt yetenekler:**
- Hesap tanımları: kasa (nakit), banka hesapları (IBAN, banka, şube, hesap türü, yetkililer) `[APS-15]`
- Hesap hareketleri, bakiye, virman (hesaplar arası aktarım)
- **Gelir-gider defteri** (KMK m.36 işletme defteri karşılığı), hesap planı (site yönetimine uygun basit plan)
- Dönem yönetimi: açılış bakiyesi, dönem kapanışı ve **kilitleme**, devir bakiyesi
- Banka mutabakatı (ekstre ↔ sistem), açık kalemler
- Demirbaş/duran varlık kaydı ve amortisman (bilgi amaçlı)
- Avans, depozito, teminat ve karşılık hesapları (onarım karşılığı, kıdem karşılığı)
- Nakit akış tablosu ve projeksiyon; asgari kasa uyarısı
- Muhasebe yazılımına aktarım (fiş formatı)
**Sık atlanan tamamlayıcılar:** kapanmış dönemin değiştirilemezliği ve düzeltmenin cari döneme ters kayıtla yapılması; birden çok bankada aynı işlemin çift kaydı; kasa sayımı ve fark kaydı; blok bazlı ayrı kasa/muhasebe takibi.

### M-28 · Hukuk ve İcra Takibi — P0
**Amaç:** Ödemeyen malikten alacağın yasal yollarla tahsili — projede tamamen yok.
**Alt yetenekler:**
- Kademeli hatırlatma: bildirim → uyarı yazısı → **noter ihtarnamesi** (şablon, gönderim, tebliğ kanıtı)
- **İcra takibi:** dayanak belge (kesinleşmiş işletme projesi / kurul kararı — KMK m.37, İİK m.68), takip açma, dosya no, icra dairesi, ödeme emri, itiraz, itirazın kaldırılması, haciz, satış
- Takip masrafları ve vekâlet ücretinin borca eklenmesi; tahsilatın anapara/faiz/masraf dağılımı
- **Kanuni ipotek hakkı** (KMK m.22) kaydı ve tapuya şerh takibi
- Kiracıya müteselsil sorumluluk bildirimi (kira bedeli kadar)
- Dava takibi: KMK m.25 (kat mülkiyetinin devri), m.33 (hâkimin müdahalesi), kurul kararının iptali davası
- Avukat ataması, dosya paylaşımı, duruşma takvimi, masraf takibi
- Uzlaşma/taksitlendirme protokolü ve bozulma yönetimi
- Hukuki süreç durumunun sakinin ekranında ve borç kaydında görünmesi
**Sık atlanan tamamlayıcılar:** icraya verilen borcun sistemde ayrı statüye geçmesi (normal tahsilattan ayrışması); icra dosyasına giden tutarın dondurulması; tahsil edilen icra tutarının doğru mahsubu; zamanaşımı takibi; icra sırasında yapılan ödemenin dosyaya bildirilmesi.

### M-29 · Vergi, SGK ve Beyan Uyumu — P1
**Amaç:** Site yönetiminin işveren ve stopaj yükümlülüklerinin kaçırılmaması.
**Alt yetenekler:**
- Potansiyel vergi kimlik numarası, mükellefiyet bilgileri
- Personel için gelir vergisi stopajı ve SGK; **muhtasar beyanname** ve SGK bildirim takvimi (M-34 ile bağlantılı)
- Kira ödemelerinde stopaj (ortak alan kiralaması, yönetici ücreti)
- Beyan/ödeme takvimi ve hatırlatıcılar; gecikme cezası riski uyarısı
- Asgari ücret/parametre güncellemelerinin bordroya yansıması
- e-Fatura/e-Arşiv alma ve arşivleme (S-08)
**Sık atlanan tamamlayıcılar:** yönetici ücretinin vergisel niteliği; kapıcının konut tahsisinin ayni yardım olarak bordroya etkisi; ortak alan kira gelirinin maliklere yansıtılması ve beyan sorumluluğu.

---

# KATMAN 4 — Operasyon ve Tesis Yönetimi

### M-30 · Talep / Arıza Yönetimi (Helpdesk) — P0
**Amaç:** Sakinin sesinin kaybolmaması, işin takip edilebilir olması. `[APS-12]`
**Alt yetenekler:**
- Kategori ağacı (elektrik, su, asansör, temizlik, güvenlik, gürültü, komşu şikayeti, öneri), **ortak alan mı bağımsız bölüm içi mi** ayrımı (masrafın kime ait olduğunu belirler)
- Öncelik ve **SLA** (ilk yanıt süresi, çözüm süresi), süre aşımı eskalasyonu
- Atama: personel, tedarikçi veya yönetici; iş emri çıktısı
- Durum makinesi: açık → atandı → devam ediyor → çözüldü → **sakin onayı** → kapandı; sakin onaylamazsa geri açılır `[APS-12]`
- Belirli süre tepkisiz kalırsa otomatik kapanış (yönetim planı/parametre ile)
- Fotoğraf/video/ses eki, konum, tekrar açma, birleştirme (aynı arızayı 10 kişi bildirdi)
- Maliyet ilişkilendirme (gidere bağlama), garanti kapsamı kontrolü
- Memnuniyet puanı, tekrarlayan arıza analizi (aynı ekipman kaç kez arızalandı → yenileme kararı)
- Genele açık/özel görünürlük (gürültü şikayeti gizli, asansör arızası herkese açık olabilir)
**Sık atlanan tamamlayıcılar:** talebi açanın kimliğinin gizlenmesi ihtiyacı (komşu şikayetinde); atanan personelin mobilden durum güncellemesi; kapanan talebin maliyetinin aidata yansıtılması; aynı ekipmana ait arıza geçmişinin varlık kartında görünmesi.

### M-31 · Periyodik Bakım ve Yasal Uyum Takvimi — P0 · **EN ÇOK ATLANAN MODÜL**
**Amaç:** Yasal periyodik yükümlülüklerin kaçırılmaması. Kaçırılması hem ceza hem can güvenliği riski;
denetimde ilk sorulan şeydir. Bugünkü projede bu kavram hiç yok.
**Alt yetenekler:**
- Yükümlülük kataloğu — her biri için: dayanak, periyot, sorumlu, gerekli belge/etiket, sonraki tarih, gecikme uyarısı:
  - **Asansör:** yıllık periyodik kontrol (yetkili muayene kuruluşu), etiket durumu (yeşil/mavi/sarı/kırmızı), zorunlu aylık bakım sözleşmesi, üçüncü şahıs mali sorumluluk sigortası
  - **Yangın:** söndürme cihazı yıllık kontrol / periyodik dolum-hidrostatik test, yangın dolabı ve tesisat kontrolü, algılama sistemi, tahliye planı ve **tatbikat** kaydı, acil aydınlatma
  - **Doğalgaz / baca:** iç tesisat kontrolü, baca temizliği, gaz dedektörü
  - **Elektrik:** topraklama ve **paratoner** ölçüm raporu, pano termal kontrolü, jeneratör bakım ve yük testi
  - **Su:** su deposu temizliği ve su analizi, hidrofor bakımı, pis su/kanalizasyon, havuz suyu ölçüm ve analiz
  - **Diğer:** klima/havalandırma bakımı, otomatik kapı-bariyer, kamera sistemi kontrolü, çatı-izolasyon kontrolü, haşere ilaçlama, çöp/atık
- Takvim görünümü, sorumlu ataması, hatırlatma kademeleri (30/15/7/1 gün), gecikmiş yükümlülük panosu
- Her tamamlanma için **belge eki zorunluluğu** (rapor, etiket fotoğrafı, fatura)
- Tedarikçi/sözleşme bağlantısı (M-35), maliyetin bütçeye bağlanması (M-21)
- **Uyum skoru** ve denetime hazır uyum dosyası (tek tuşla PDF)
- Yükümlülük şablonu: yeni site kurulunca bina özelliklerine göre (asansör var mı, merkezi ısıtma var mı, havuz var mı) otomatik takvim üretimi
**Sık atlanan tamamlayıcılar:** yükümlülüğün bina özelliğine göre koşullu olması; kontrolü yapan firmanın yetki belgesinin geçerliliği; kırmızı etiketli asansörün kullanımının durdurulması gerektiğinin uyarılması; yükümlülük gecikmesinin yönetici sorumluluğu doğurması ve bunun kayda geçmesi.

### M-32 · Varlık ve Demirbaş Yönetimi — P1
**Alt yetenekler:** envanter kartı (marka/model/seri no/kurulum tarihi/garanti), konum, QR/NFC etiket, bakım geçmişi, arıza geçmişi, ömür ve yenileme planı, değer ve amortisman, devir/hurda, ilgili sözleşme ve yükümlülükler (M-31), yedek parça.
**Sık atlanan tamamlayıcılar:** varlığın toplam sahip olma maliyeti (arıza + bakım + enerji) ve yenileme kararına veri sağlaması; garanti süresi bitmeden arıza olursa garanti talebi; kritik varlık için yedek/plan B.

### M-33 · Stok ve Sarf Malzeme — P2
**Alt yetenekler:** malzeme kartı, giriş/çıkış, kim aldı, kritik stok uyarısı, sayım ve fark, tedarikçi bağlantısı, maliyetin gidere yansıması.

### M-34 · Personel Yönetimi — P0
**Amaç:** Site yönetimi bir **işverendir**; İş Kanunu, SGK ve İSG yükümlülükleri vardır.
**Alt yetenekler:**
- Kadro ve sözleşme (belirli/belirsiz süreli), görev tanımı, ücret, **kapıcı konutu** tahsisi ve ayni yardım
- Vardiya planı, puantaj, devamsızlık, fazla mesai, resmî tatil/hafta tatili
- İzin yönetimi: yıllık izin hakkı hesabı (kıdeme göre), mazeret, ücretsiz, rapor/istirahat; izin bakiyesi
- **Bordro:** brüt/net, SGK işçi-işveren payı, işsizlik, gelir vergisi, damga vergisi, asgari ücret istisnası; bordro çıktısı ve ücret ödemesi
- Kıdem/ihbar tazminatı **karşılık** hesabı (siteye gelecek yük olarak görünmeli)
- SGK: işe giriş/çıkış bildirimi, aylık prim hizmet belgesi, e-bildirge takvimi (M-29)
- **İSG (6331):** risk değerlendirmesi, İSG eğitimi kaydı, periyodik sağlık muayenesi, kişisel koruyucu donanım teslim tutanağı, iş kazası bildirimi ve kaydı, acil durum ekipleri
- 5188 kapsamında özel güvenlik personeli: kimlik kartı ve sertifika geçerlilik takibi
- Personel dosyası (KVKK: özlük belgelerinin saklama süresi ve erişim kısıtı)
- Performans, disiplin, işten çıkış (ibraname, çıkış işlemleri)
**Sık atlanan tamamlayıcılar:** izin hakkının kıdemle otomatik artması; asgari ücret güncellemesinin tüm bordroları etkilemesi; kıdem karşılığının bütçeye yansıtılması; personelin birden çok sitede çalışması (yönetim şirketi senaryosu); İSG eğitim geçerlilik süresi.

### M-35 · Tedarikçi ve Sözleşme Yönetimi — P1
**Alt yetenekler:** tedarikçi kartı (vergi no, IBAN, yetkili, hizmet alanı), belge geçerliliği (yetki belgesi, SGK borcu yoktur, sigorta), sözleşme (başlangıç/bitiş, bedel, artış oranı/formülü, kapsam, ceza şartı), **yenileme/bitiş uyarısı**, hizmet seviyesi ve performans puanı, fatura-sözleşme tutarlılık kontrolü, teklif geçmişi, kara liste, sözleşme dosyası.
**Sık atlanan tamamlayıcılar:** sözleşme bitmeden yenileme kararının kurula sunulması; otomatik yenilenen sözleşmenin fark edilmemesi; sözleşmedeki artış oranının fatura kontrolünde kullanılması; tedarikçinin birden çok sitede performansının karşılaştırılması.

### M-36 · Sigorta Yönetimi — P1
**Alt yetenekler:** poliçe envanteri — **DASK** (her bağımsız bölüm için zorunlu; takip ve eksik uyarısı), ortak alan yangın/sel/hırsızlık, asansör üçüncü şahıs mali sorumluluk, işveren sorumluluk, cam kırılması; poliçe bitiş uyarısı, prim ödemesi ve gidere yansıma (arsa payı — KMK m.20/1-b), hasar/tazminat süreci (ihbar, eksper, tahsilat, gidere mahsup), sigorta kararının kurul onayına bağlanması (KMK m.14).
**Sık atlanan tamamlayıcılar:** DASK'ın malik yükümlülüğü olması ama sitenin takip etmesi gereği; hasar tazminatının kimin hesabına gireceği; eksik sigorta bedeli (eksik sigorta riski) uyarısı.

### M-37 · Acil Durum ve Afet Yönetimi — P1 · **Türkiye için yüksek değer**
**Alt yetenekler:**
- Acil durum planı (İSG 6331 m.11 kapsamında), tahliye planı, **toplanma alanı**, kroki
- Acil durum ekipleri (söndürme, kurtarma, koruma, ilk yardım) ve eğitim/tatbikat kaydı
- Kritik altyapı bilgi kartı: ana su vanası, gaz vanası, elektrik panosu, jeneratör, yangın pompası konumları
- Acil iletişim listesi (itfaiye, AFAD, en yakın hastane, teknik servisler, yönetici, güvenlik)
- Sakin acil bilgi kartı: engelli/yaşlı/kronik hasta/bebek bilgisi (**KVKK: özel nitelikli veri → açık rıza zorunlu**, erişim kısıtlı)
- Deprem sonrası akış: hasar tespit kontrol listesi, bina kullanılabilirlik durumu, sakin durum bildirimi ("iyiyim" toplu bildirimi), toplu duyuru
- Acil durum ekipman envanteri (yangın tüpü, ilk yardım dolabı, tahliye ekipmanı) → M-31 ile bağlantılı
**Sık atlanan tamamlayıcılar:** afet anında internetin/elektriğin olmaması (offline erişilebilir plan, indirilmiş PDF); acil bilgi kartına kimin erişebileceği; tatbikat kaydının denetim dosyasına girmesi.

### M-38 · Ziyaretçi ve Erişim Kontrolü — P1
**Alt yetenekler:** ziyaretçi ön kaydı (sakin davet eder), **QR/tek kullanımlık kod**, plaka bildirimi, güvenlik girişinde doğrulama, giriş-çıkış kaydı, refakat gereği, kargo/kurye/servis personeli erişimi, kara liste, tekrarlayan ziyaretçi (temizlikçi/bakıcı) için süreli izin; kart/RFID/**biyometrik** geçiş (biyometrik = özel nitelikli veri: açık rıza, alternatif yöntem sunma zorunluluğu), turnike/bariyer/interkom donanım entegrasyonu, kamera envanteri ve **aydınlatma levhası + saklama süresi** politikası.
**Sık atlanan tamamlayıcılar:** ziyaretçi kaydının KVKK saklama süresi sonunda otomatik silinmesi; sakin evde yokken gelen ziyaretçi bildirimi; acil durumda binada kim var listesi (tahliye için); biyometrik veriye rıza vermeyene kart alternatifi.

### M-39 · Otopark Yönetimi — P1
**Alt yetenekler:** otopark alanı/yer envanteri, bağımsız bölüme **tahsis** (eklenti mi ortak yer mi — hukuki fark), misafir otoparkı ve süre/ücret kuralı, araç kaydı (plaka, marka, RFID), plaka tanıma ile giriş-çıkış, ihlal takibi (başkasının yerine park) ve yaptırım (M-44), ücretli otopark tahsilatı (M-25), doluluk göstergesi, **elektrikli araç şarj istasyonu** (kurulum kararı, elektrik tüketiminin ilgili bölüme yansıtılması), motosiklet/bisiklet alanı.
**Sık atlanan tamamlayıcılar:** şarj istasyonu elektriğinin ortak sayaçtan ayrıştırılması ve kullanıcıya faturalanması; tahsisli yerin kiralanması/devri; misafir otoparkının kötüye kullanımının tespiti.

### M-40 · Kargo ve Koli Takibi — P2
**Alt yetenekler:** teslim alma (kurye, kargo firması, koli no, fotoğraf), sakine bildirim, teslim etme (imza/QR/kod), bekleyen koli listesi ve yaşlandırma, dolap/raf konumu, akıllı kargo dolabı entegrasyonu, sorumluluk sınırı (kıymetli eşya reddi).

### M-41 · Ortak Alan Rezervasyonu — P2
**Alt yetenekler:** tesis tanımı (toplantı salonu, spor salonu, havuz, kamelya, misafir dairesi), takvim ve slot, kural motoru (kişi limiti, süre, ileriye dönük gün limiti, aynı kişi haftada kaç kez, ücret, **iptal politikası**), çakışma kontrolü, ücretli rezervasyon tahsilatı, depozito, kullanım sonrası hasar/temizlik kaydı, borçlu sakinin rezervasyon yapamaması kuralı, katılımcı listesi.
**Sık atlanan tamamlayıcılar:** iptal/gelmeme (no-show) yaptırımı; bakım nedeniyle tesisin kapatılması ve mevcut rezervasyonların iptali/bilgilendirilmesi; ücretin aidata yansıtılması.

### M-42 · Güvenlik Operasyonu — P2
**Alt yetenekler:** güvenlik personeli vardiya ve devir tutanağı, **devriye rotası** ve QR/NFC kontrol noktası, tur kaydı ve kaçırılan nokta uyarısı, olay kaydı (fotoğraf/rapor), gece raporu, anons/duyuru, kamera sistemi envanteri, panik butonu/acil çağrı, 5188 belge takibi (M-34).

### M-43 · Temizlik, Çevre ve Peyzaj — P2
**Alt yetenekler:** temizlik programı ve kontrol listesi (imzalı/QR ile doğrulanan), kalite denetimi ve fotoğraf, atık/geri dönüşüm ve konteyner takibi, peyzaj/bahçe bakım takvimi, havuz işletme (günlük ölçüm kaydı, analiz), kar-buz mücadelesi, ilaçlama (M-31).

### M-44 · Kural İhlali ve Yaptırım — P1
**Amaç:** Yönetim planı kurallarının işletilebilir hale gelmesi — bugün tamamen yok.
**Alt yetenekler:** kural kataloğu (yönetim planına atıflı: gürültü, evcil hayvan, otopark, çöp, balkon kullanımı, ortak alan işgali, tadilat kuralları), ihlal bildirimi (sakin bildirir, isteğe bağlı gizli), doğrulama, **kademeli süreç: sözlü uyarı → yazılı uyarı → ihtar → yaptırım**, yönetim planı öngörüyorsa parasal yaptırımın borç kalemine dönüşmesi (M-24), itiraz süreci ve kurula taşıma, tekrar takibi, ağır/sürekli ihlalde hukuki yol (KMK m.25 çekilmezlik).
**Sık atlanan tamamlayıcılar:** yaptırımın yönetim planında dayanağı yoksa uygulanamayacağının sistemde zorlanması; ihlal bildiriminin komşuluk ilişkisini zedelememesi için gizlilik; kiracı ihlalinde malike bildirim.

### M-45 · Tadilat / Tamirat İzni — P1
**Amaç:** Yapısal ve komşuluk risklerinin yönetimi; KMK m.19 (taşıyıcı sisteme müdahale yasağı, ortak yerde değişiklik için 4/5 rıza) uyumu.
**Alt yetenekler:** başvuru (kapsam, süre, müteahhit bilgisi, proje/çizim eki), risk sınıflaması (**taşıyıcı sisteme müdahale → kurul kararı/oybirliği gereği uyarısı**), komşu bilgilendirme, çalışma saati ve gün kuralı, asansör/merdiven kullanım ve koruma şartı, **teminat/depozito** alınması ve iadesi, moloz/atık taahhüdü, denetim ve fotoğraf, tamamlama onayı, ihlalde durdurma ve yaptırım (M-44).
**Sık atlanan tamamlayıcılar:** izinsiz tadilatın tespiti ve durdurulması; tadilat sırasında ortak alanda oluşan hasarın teminattan karşılanması; komşu şikayetinin izin dosyasına bağlanması.

### M-46 · Ortak Alan Gelir Yönetimi — P1
**Alt yetenekler:** gelir kaynağı envanteri (**baz istasyonu, çatı/dış duvar reklam — KMK m.45: oybirliği gerekir**, otopark/depo kiralama, sosyal tesis işletme, çamaşırhane, otomat), kira sözleşmesi ve artış takibi, tahsilat, **stopaj** ve beyan (M-29), gelirin kullanımı: bütçeye gelir olarak yazılması ya da maliklere arsa payına göre dağıtılması (kurul kararına bağlı), sözleşme yenileme uyarısı.
**Sık atlanan tamamlayıcılar:** oybirliği gerektiren kararın çoğunlukla alınmasının hukuken sakat olması (sistem uyarmalı); kira gelirinin maliklerin kişisel beyan yükümlülüğü doğurması; sözleşmenin yönetici değişiminde devri.

---

# KATMAN 5 — İletişim, Katılım ve Deneyim

### M-47 · Duyuru ve Bilgilendirme — P0
**Alt yetenekler:** hedefleme (tüm site / blok / kat / rol / borçlular / belirli kişiler), zengin içerik ve dosya eki, planlı yayın ve son geçerlilik tarihi, **okundu bilgisi** ve okumayanlara hatırlatma, önemli/kritik duyuru işareti, çok kanallı yayın (push + SMS + e-posta + panoya asma çıktısı), arşiv ve arama, sabitleme, yorum/soru alma (opsiyonel, moderasyonlu). `[APS-10]`
**Sık atlanan tamamlayıcılar:** duyurunun kiracıya mı malike mi yoksa ikisine mi gideceği; asansör/su kesintisi gibi duyuruların takvime düşmesi; okundu bilgisinin hukuki tebligat yerine geçmediğinin ayırt edilmesi (resmî tebligat M-17/M-21'de).

### M-48 · Anket ve Ön Yoklama — P1
**Alt yetenekler:** anket türleri (tek/çok seçim, puan, açık uçlu), hedefleme, süre, anonimlik seçeneği, sonuç görselleştirme ve şeffaflık, **resmî oylamadan ayrımı** (genel kurul oylaması hukuki nisap gerektirir → M-17), katılım hatırlatıcısı, sonucun karara dönüşmesi.

### M-49 · İlan Panosu ve Komşuluk — P2
**Alt yetenekler:** ilan (satılık/kiralık/ikinci el/hizmet), kategori, süre, moderasyon ve şikayet, kayıp-buluntu, komşu yardım/ödünç, etkinlik duyurusu, mesajlaşma (KVKK: iletişim bilgisi paylaşmadan), yönetici moderasyon yetkisi ve kural ihlali kaldırma.

### M-50 · Sakin Deneyimi (Mobil + Web) — P0
**Amaç:** Sakinin ihtiyacını 3 dokunuşta çözmesi. Rakibin en çok şikayet edilen alanı. `[APS-4] [APS-5] [APS-8] [APS-9]`
**Alt yetenekler:**
- Ana ekran: güncel borç, son ödeme tarihi, ödenecek kalemler, açık talepler, yeni duyurular, yaklaşan rezervasyon
- **Borç detayı ve kalem seçerek ödeme** (sepet), ödeme geçmişi, **makbuz/dekont indirme** `[APS-6]`
- **Tüketim ekranı:** dönem bazlı ısınma/su tüketimi, birim fiyat, ortak alan payı, karşılaştırma, fatura PDF `[APS-5]`
- Hesap ekstresi (cari hesap) ve mutabakat
- Talep açma (fotoğraflı), takip, **çözüm onayı** `[APS-12]`
- Duyurular, anketler, ilan panosu, belgeler (yönetim planı, kararlar, raporlar)
- Rezervasyon, ziyaretçi daveti, kargo, araç bilgileri
- Profil: iletişim bilgileri, aile üyeleri, **bildirim tercihleri** `[APS-11]`, KVKK rıza yönetimi ve veri talebi
- Performans ve dayanıklılık: hızlı açılış, önbellek, offline görüntüleme, **native ödeme akışı** `[APS-4] [APS-9]`, donanımsal geri tuşu doğru davranışı `[APS-8]`
- Erişilebilirlik (yaşlı kullanıcı: büyük font, yüksek kontrast), çok dil
**Sık atlanan tamamlayıcılar:** oturumun kendiliğinden düşmemesi `[APS-1]`; birden fazla dairesi olan malikin daire değiştirebilmesi; kiracı ile malikin farklı görmesi gerekenler; bildirimden ilgili ekrana derin bağlantı; uygulama içi "yönetime ulaş" kanalı.

### M-51 · Yönetici Deneyimi (Mobil Öncelikli) — P0
**Amaç:** Rakipteki **en büyük boşluk**: yönetici sahada iş yapamıyor. `[APS-14] [APS-15] [APS-16] [APS-17]`
**Alt yetenekler:**
- **Özelleştirilebilir dashboard/widget:** kasa ve banka bakiyeleri, bu ay tahsilat/tahakkuk oranı, vadesi geçmiş alacaklar, açık talepler ve SLA riski, yaklaşan yasal yükümlülükler (M-31), onay bekleyenler `[APS-15] [APS-17]`
- **Mobilden gider girme** (fotoğraf + AI okuma + onaya gönderme) `[APS-14]`
- **Mobilden tahsilat girme ve ödeme-sakin eşleştirme** `[APS-14] [APS-16]`
- Banka hesapları ve IBAN listesi, hesap hareketleri, ekstre `[APS-15]`
- Borçlu listesi ve tek dokunuşla hatırlatma/ihtar başlatma
- Talep atama ve durum güncelleme, iş emri, personel yönlendirme
- Duyuru yayınlama, acil duyuru
- Tahakkuk **ön izleme ve onayı** (oluşturma yetkisi kritik → onay + geri alma + denetim izi)
- Sahada çalışma: fotoğraf, offline kuyruk, bağlantı gelince gönderme
- Biyometrik giriş, hızlı erişim, bildirim rozetleri `[APS-1] [APS-10]`
**Sık atlanan tamamlayıcılar:** yetkisi olmayan aksiyonun sunucuda engellenmesi (denetçi harcama girememeli) `[APS-18]`; yıkıcı işlemlerde ikinci onay; offline kuyruğun çakışma çözümü; mobil ile panel arasında **işlev paritesi** (rakibin çöktüğü nokta).

### M-52 · Destek ve Geri Bildirim — P1
**Alt yetenekler:** uygulama içi destek bileti, **log/ekran görüntüsü ekli hata bildirimi** `[APS-19]`, sürüm notları, yardım merkezi/SSS, NPS ölçümü ve kapanış döngüsü, özellik talebi ve oylama.

---

# KATMAN 6 — Analitik ve Zekâ

### M-53 · Yönetim ve Denetim Raporları — P0
**Rapor kataloğu:** gelir-gider tablosu (dönem/kalem), **bütçe-gerçekleşme sapma**, tahsilat oranı ve trendi, **alacak yaşlandırma**, borçlu listesi, kasa/banka mutabakat, aidat tahakkuk-tahsilat dökümü (bağımsız bölüm bazlı), gecikme tazminatı raporu, gider kategori trendi ve birim maliyet, personel maliyeti, talep/SLA performansı, tüketim ve enerji raporu, yasal uyum durumu (M-31), **yıllık hesap özeti** (KMK m.39), **denetçi paketi** (KMK m.41), yönetim faaliyet raporu, dönem karşılaştırma, blok bazlı raporlar.
**Sık atlanan tamamlayıcılar:** raporun kesinleşmiş dönem verisiyle dondurulması; ekran ile raporun aynı sayıyı vermesi; genel kurula sunulacak resmî formatta çıktı; raporun kim tarafından ne zaman üretildiğinin çıktıda yer alması.

### M-54 · Akıllı Tahsilat ve Risk Skoru — P2
**Alt yetenekler:** ödeme davranışı skoru, gecikme olasılığı tahmini, kademeli otomatik hatırlatma akışı (kanal ve zamanlama optimizasyonu), en etkili iletişim kanalı öğrenmesi, ödeme planı önerisi, tahsilat kampanyası (faiz affı senaryosu ve mali etkisi), icraya taşıma önerisi ve eşiği, nakit akış tahmini.
**Not:** Otomatik iletişimde SMS maliyeti ve rahatsız etme dengesi; KVKK açısından ticari ileti değil borç bildirimi olduğu ayrımı.

### M-55 · Enerji ve Sürdürülebilirlik (ESG) — P2
**Alt yetenekler:** tüketim izleme (elektrik/su/gaz/ısı), anomali ve **kaçak tespiti**, birim başına tüketim kıyaslama (blok/dönem/benzer siteler), tasarruf önerileri ve yatırım geri dönüş hesabı (yalıtım, LED, ısı pompası), yenilenebilir enerji (çatı GES) üretim takibi ve mahsuplaşma, karbon ayak izi, atık/geri dönüşüm oranı, su tasarrufu, ESG raporu.

### M-56 · Yapay Zekâ Destekli Yetenekler — P2
**Alt yetenekler:** fatura okuma (OCR + alan çıkarma + doğrulama), plaka tanıma, talep sınıflandırma ve otomatik yönlendirme/öncelik, benzer talep/çözüm önerisi, sözleşme risk analizi, toplantı tutanağı özeti ve karar çıkarma, doğal dilde rapor sorgulama, sakin için SSS asistanı, anormal harcama tespiti.
**Zorunlu kısıtlar:** tüm AI çağrıları **backend üzerinden** (anahtar istemciye gömülmez); kişisel veri içeren içerikte KVKK aktarım değerlendirmesi; AI çıktısının **insan doğrulaması** olmadan finansal kayda dönüşmemesi; maliyet sınırı ve devre dışı bırakılabilirlik.

---

# KATMAN 7 — Ticari ve SaaS İşletim

### M-57 · Yönetim Organizasyonu (Portföy) Katmanı — P2
**Alt yetenekler:** birden çok siteyi yöneten şirket/kişi hesabı, siteler arası geçiş, **konsolide gösterge panosu**, portföy raporları, personel ve tedarikçi havuzu, merkezî parametre şablonları, şirket bazlı yetki ve kullanıcı yönetimi, siteler arası maliyet kıyaslama. `[S-12]`

### M-58 · Abonelik ve Faturalama (SaaS) — P3
**Alt yetenekler:** paket ve fiyatlandırma (bağımsız bölüm başına), deneme süresi, sözleşme, otomatik faturalama ve tahsilat, kullanım limitleri (SMS kotası, depolama), ödeme gecikmesinde kademeli kısıtlama, iptal ve veri ihracı.

### M-59 · Onboarding ve Veri Aktarımı — P1
**Amaç:** Rakipten geçişin önündeki en büyük engelin kaldırılması — satış kolaylaştırıcı.
**Alt yetenekler:** yeni site kurulum sihirbazı (bina yapısı, bağımsız bölümler, arsa payları), **Excel/CSV toplu içe aktarma** (bağımsız bölüm, malik/kiracı, açılış bakiyesi, sayaç, demirbaş), şablon indirme, **doğrulama ve ön izleme** (hatalı satır raporu, kısmi aktarım yerine tümü-veya-hiç seçeneği), açılış bakiyesi ve mutabakat, mevcut sistemden veri göçü, kurulum kontrol listesi ve tamamlanma yüzdesi, örnek/demo veri ile deneme ve **demo verinin temizlenmesi**.
**Sık atlanan tamamlayıcılar:** arsa payı toplamının kontrolü; mükerrer kişi kaydının tespiti; Türkçe karakter ve tarih/sayı biçimi sorunları; içe aktarmanın geri alınabilmesi.

### M-60 · Rol ve Yetki Şablonları — P0
**Amaç:** "Herkes her şeyi görüyor" probleminin çözümü. `[APS-18]`
**Roller (öneri):** sistem yöneticisi, yönetim organizasyonu yöneticisi, site yöneticisi, yönetim kurulu üyesi, **denetçi** (okur, harcama giremez), muhasebe/mali işler, asistan/sekreter, teknik personel, güvenlik, kapıcı/görevli, **malik**, **kiracı**, oturan aile üyesi, tedarikçi (kısıtlı: kendi işleri), avukat (kısıtlı: kendi dosyaları).
**Alt yetenekler:** yetki matrisi (kaynak × işlem), kapsam sınırı (site/blok/bağımsız bölüm), özel yetki ekleme/çıkarma, yetki şablonu ve devralma, **sunucu tarafında zorlama** (arayüzde gizlemek yetmez), yetki değişikliği denetim izi, hassas alan maskeleme (maaş, TCKN, iletişim), geçici/süreli yetki.

---

# Modül Bağımlılık Sırası (İnşa Sırası)

Doğru sıra, sonradan yeniden yazmayı önler:

1. **Zemin:** M-12 (şema/migration yönetimi) → M-02 (tenant izolasyonu) → M-01 (kimlik) → M-60 (yetki) → M-03 (denetim izi) → M-11 (güvenlik) → M-09 (parametre) → M-10 (gözlemlenebilirlik)
2. **Ana veri:** M-13 (taşınmaz) → M-14 (kişi/ilişki) → M-04 (dosya) → M-05 (bildirim)
3. **Yönetişim:** M-16 (yönetim planı) → M-17 (genel kurul) → M-18 (organlar) → M-19 (defterler) → M-20 (denetim)
4. **Finans:** M-21 (işletme projesi) → M-22 (tahakkuk) → M-24 (borç/faiz) → M-25 (tahsilat) → M-26 (gider) → M-27 (kasa/muhasebe) → M-23 (ısı/su) → M-28 (icra) → M-29 (vergi/SGK)
5. **Operasyon:** M-30 (talep) → M-31 (uyum takvimi) → M-34 (personel) → M-35 (tedarikçi) → M-32 (varlık) → M-36 (sigorta) → M-37 (acil durum) → M-38/39 (erişim/otopark) → M-44/45 (ihlal/tadilat) → M-46 (ortak gelir) → M-41/40/42/43/33
6. **Deneyim:** M-47 (duyuru) → M-50 (sakin) → M-51 (yönetici) → M-48 (anket) → M-52 (destek) → M-49
7. **Analitik:** M-08 (rapor motoru) → M-53 (raporlar) → M-54/55/56
8. **Ticari:** M-59 (onboarding) → M-57 (portföy) → M-58 (abonelik)

## Öncelik özeti

| Öncelik | Modüller | Adet |
|---------|----------|------|
| **P0** | M-01, M-02, M-03, M-04, M-05, M-06, M-08, M-09, M-10, M-11, M-12, M-13, M-14, M-16, M-17, M-18, M-19, M-20, M-21, M-22, M-23, M-24, M-25, M-26, M-27, M-28, M-30, M-31, M-34, M-47, M-50, M-51, M-53, M-60 | 34 |
| **P1** | M-07, M-15, M-29, M-32, M-35, M-36, M-37, M-38, M-39, M-44, M-45, M-46, M-48, M-52, M-59 | 15 |
| **P2** | M-33, M-40, M-41, M-42, M-43, M-49, M-54, M-55, M-56, M-57 | 10 |
| **P3** | M-58 | 1 |

**Toplam: 60 modül.**

> Not: P0 sayısının yüksek olması, hedefin "gerçek bir site yönetim platformu" olmasından kaynaklanır.
> Bunların tamamı MVP'ye sığmaz; bu yüzden `tasks/roadmap.md` içinde **dikey dilimler** (uçtan uca çalışan
> ince şeritler) halinde sıralanmıştır — her dilim tek başına kullanılabilir değer üretir.


