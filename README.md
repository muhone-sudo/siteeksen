# SiteEksen

Türkiye'deki kat mülkiyeti kapsamındaki siteler için çok kiracılı site yönetim platformu. Proje; Go mikroservis backend'i, Next.js yönetim paneli, sakin mobil uygulaması ve yönetici mobil uygulamasından oluşur.

> **Özellik envanteri:** Bu README, 2026-10-31 tarihindeki kod ve [özellik/yetenek haritasına](docs/ozellik-haritasi/README.md) göre düzenlenmiştir. Ekran, düğme, API ucu, bildirim ve veritabanı etkilerinin satır kanıtları için özellik haritasına bakın.

## Platformlar

| Platform | Konum | Kapsam |
|---|---|---|
| Yönetim web paneli | `admin/` | Next.js 14, 52 sayfa; yönetim, finans, KMK yönetişimi, operasyon, analiz ve sistem |
| Sakin uygulaması | `mobile/` | Flutter; 40 ekran/bileşen, sakin hesabı ve daire işlemleri |
| Yönetici uygulaması | `admin_app/` | Flutter; 66 ekran/bileşen, paneldeki API işlemlerinin mobil karşılığı |
| Backend/API | `backend/` | Go servisleri, PostgreSQL, gateway, scheduler ve OpenAPI sözleşmesi |

## Yönetim web paneli

Panelde site bazlı rol ve yetki kontrolü vardır. Sayfalar yükleniyor, boş ve hata durumlarını gösterir; yazma işlemleri gerçek API yanıtından sonra sonuçlandırılır.

### Üst ve sakin iletişimi

- **Dashboard:** borç, tahsilat, gider, sakin, duyuru ve operasyon özetleri.
- **Duyurular:** duyuru oluşturma, yayınlama, durum takibi.
- **İlan panosu:** sakin ilanları, onay/ret, yorumları listeleme ve gizleme.
- **Acil durum:** toplanma noktaları, iletişim bilgileri, tatbikatlar, durum kontrolleri ve yardım yanıtları.
- **Sigorta/DASK:** poliçe takibi, yenileme uyarıları, hasar kaydı ve durum yönetimi.
- **KVKK:** ilgili kişi başvuruları, yanıt, saklama süreleri ve imha.
- **Toplu bildirim:** sakin gruplarına uygulama içi, SMS ve e-posta bildirimi.
- **Tadilat izinleri:** başvuru, kurul onayı/ret, durdurma, tamamlama ve komşu bilgilendirmesi.
- **Talepler:** sakin/yönetim talepleri, durum ve sorumlu takibi.
- **Sakinler:** sakin ekleme, davet, aktivasyon, telefon ve kiracılık işlemleri.
- **Görevlendirmeler:** yönetici, kurul, denetçi ve görevli rolleri ile çalışma saatleri.
- **Anketler:** anket oluşturma, yayınlama, kapatma, oy ve yorum sonuçları.
- **Bağımsız bölümler:** blok/daire, net alan, kullanım ve sakin ilişkileri.
- **Kural ihlalleri:** kural tanımı, ihlal bildirimi, doğrulama, kademe ve sonuçlandırma.

### Mali modüller

- **Tahsilat ve borçlar:** yönetim tahsilatı, elden/havale ödeme, ödeme-tahakkuk eşleştirme ve borç özeti.
- **Aidat tahakkuku:** aylık tahakkuk, kullanım/malik sorumluluk sınıfı, gecikme tazminatı ve kuruş doğruluğu.
- **Tahsilat riski:** açıklanabilir ödeme riski ve takip listeleri; yapay zekâ kullanılmaz.
- **Giderler:** gider kaydı, onay, gider kalemi ve bağımsız bölümlere dağıtım.
- **Sayaç ve ısı payı:** sayaç, okuma, değişim protokolü, tüketim sapması, paylaştırma ve itiraz.
- **Finans araçları:** açılış bakiyesi, alacak dekontu, banka ekstresi, ödeme makbuzu, borcu yoktur belgesi ve iyzico kart ödemesi.

### KMK yönetişimi

- **Sözleşmeler:** sözleşme, ihbar penceresi, süre dolumu ve durum takibi.
- **Belge arşivi:** dosya yükleme, sürümleme, arşivleme, indirme ve erişim kaydı.
- **Genel kurul:** çağrı, gündem, hazirun, toplantı ve oy akışı.
- **Defterler:** karar/işletme defteri kayıtları; kayıtlar değiştirilemez veya silinemez.
- **İşletme projesi:** proje, bildirim, kesinleştirme, bölüm payı, görüş/itiraz ve tahakkuk.
- **Ortak alan geliri:** ortak alan kira ve gelir kayıtları.
- **İcra ve dava:** hukuki takip kayıtları.

### Operasyon

- **Demirbaş:** demirbaş, kategori, zimmet, bakım, periyodik kontrol ve elden çıkarma.
- **Stok:** kategori, stok kalemi, giriş/çıkış hareketleri, düşük stok uyarısı ve pasife alma.
- **Kargo:** paket kaydı, teslim/çıkış, imza ve fotoğraf kanıtı.
- **Otopark:** araçlar, plaka sorgulama, geçiş cihazları ve cihaz canlılığı.
- **Devriye:** rota ve nokta tanımı, QR okutma, GPS doğrulama, sorun bildirimi, rapor ve harita.
- **Personel:** personel, görev/izin, bordro, SGK takvimi ve yıllık maliyet.
- **Rezervasyon:** ortak alan/tesis, uygunluk, çakışma denetimi ve onay/ret.
- **Sensörler:** IoT sensörleri, okumalar, alarm ve çevrimdışı bekçisi.
- **Ziyaretçi:** ziyaretçi ön kaydı, PIN/QR, giriş-çıkış, iptal ve kod yenileme.

### Analiz ve sistem

- **Enerji:** tüketim eğilimleri ve olağandışı tüketim analizi.
- **Karbon ayak izi:** kullanıcı katsayılarıyla açıklanabilir karbon hesabı.
- **Memnuniyet/NPS:** ölçüm oluşturma, yayınlama, yanıt ve skor.
- **Raporlar:** finans, operasyon ve yönetim raporları; PDF/Excel çıktıları.
- **İşlem kayıtları:** API, istemci ve sistem etkinlikleri; erişim ve reddedilen işlem kayıtları.
- **Bildirimlerim:** kişisel bildirim kutusu, okunmamış sayısı, okundu ve tümünü okundu işaretleme.
- **Entegrasyon durumu:** iyzico, SMS, e-posta, dosya depolama ve diğer sağlayıcıların gerçek bağlantı durumu.
- **Ayarlar:** site bilgileri, çalışma parametreleri, görünürlük politikaları, kamera/biyometrik envanter, saklama ve yaşam döngüsü.
- **Hesabım ve aktivasyon:** giriş, aktivasyon, şifre/oturum yönetimi ve ödeme dönüşü.

### Platform ve tedarikçi web alanı

`/tedarikci` altında tedarikçi kaydı/girişi, profil ve belge inceleme, işletmeler, hizmet kalemleri, fotoğraf, bakiye, paket, bildirim, talepler ve puanlar bulunur. `/platform` altında platform yöneticisi tedarikçi hesabı/belge onayı, işletme yayını, kategori, paket, fiyat ve platform ayarlarını yönetir.

## Sakin mobil uygulaması

- **Kimlik ve hesap:** giriş, aktivasyon, KVKK onayı, profil, telefon/e-posta değişikliği, şifre kurtarma, tüm cihazlardan çıkış.
- **Ana ekran:** borç özeti, duyurular, ilanlar, bildirim sayısı ve hızlı işlemler.
- **Finans:** aidat/borç ayrıntısı, iyzico ödeme, ödeme sonucu, ödeme geçmişi ve borcu yoktur belgesi.
- **Daire ve kişiler:** bağımsız bölüm sakinleri, malik/kiracı ilişkisi, davetler, kiracılık talebi ve malik görünürlük politikası.
- **İletişim:** duyurular, ilan panosu ve yorumlar, bildirim kutusu, KVKK başvuruları ve talepler.
- **Ortak alanlar:** tesis rezervasyonu, rezervasyonlarım.
- **Operasyon:** ziyaretçi ön kaydı/liste/iptal/PIN-QR yenileme, araçlarım, kargo/paket takibi ve teslim kanıtı.
- **Enerji ve tüketim:** sayaçlarım, tüketim ve ısı payı ekranı, pusula itirazı.
- **Yönetişim:** işletme projesi, bölüm payı, görüş/itiraz, belgeler, DASK ve ortak alan geliri.
- **Katılım:** anketler, NPS/memnuniyet ve ihlal bildirimleri.
- **Tadilat:** tadilat başvurusu, durum takibi ve geri çekme.

## Yönetici mobil uygulaması

Yönetici uygulaması, web panelinin gerçek API işlemleriyle eşit mobil yüzüdür; panelde kullanılan API uçlarının tamamı mobilde de çağrılır. Modüller:

- dashboard, hesap/site değiştirme ve yeni site oluşturma;
- duyurular, ilan panosu, bildirim kutusu, toplu bildirim ve işlem kayıtları;
- sakinler, bağımsız bölümler, roller/görevlendirmeler ve aktivasyon kodları;
- finans, tahsilat, aidat tahakkuku, ödemeler, finans araçları, borç/tahsilat riski;
- gider, gider ayrıntısı ve sakin bazlı gider görünümü;
- işletme projesi, genel kurul, defter, icra/dava ve ortak alan geliri;
- sözleşmeler, belgeler, KVKK, sigorta/DASK ve tadilat;
- demirbaş, stok, kargo, otopark, sensör, sayaç, rezervasyon, ziyaretçi ve devriye;
- personel, bordro ve SGK takvimi;
- enerji, karbon, NPS, anket ve raporlar;
- site ayarları, API/entegrasyon durumu, gizlilik ve hesap ayarları.

Mobilde personel TCKN/IBAN bilgileri yalnız maskeli gösterilir. QR tarama, GPS, dosya seçme ve belge açma Android/web ortamına uyarlanmıştır.

## Backend ve API yetenekleri

### Servisler

| Servis | Sorumluluk |
|---|---|
| `identity` | kullanıcı, JWT, aktivasyon, site/sakin/rol, kiracılık ve hesap kurtarma |
| `finance` | aidat, tahakkuk, tahsilat, ödeme, gecikme, makbuz, iyzico ve borcu yoktur |
| `community` | duyuru, talep, KVKK, acil durum, tadilat ve ihlal |
| `governance` | işletme projesi, genel kurul, defterler, ortak alan geliri, icra/dava |
| `iot` | sayaç, okuma, ısı payı, tüketim pusulası, sensör ve alarm |
| `notification` | kişisel/toplu bildirim, tercihler, okundu bilgisi ve giden kutusu |
| `expense` | gider ve dağıtım |
| `asset` | demirbaş ve bakım |
| `bulletin` | ilan panosu, onay ve yorum |
| `contract` | sözleşme ve ihbar/süre takibi |
| `document` | belge arşivi ve dosya depolama |
| `energy_analytics` | enerji eğilimi ve anomali hesabı |
| `esg` | karbon hesabı |
| `inventory` | stok ve hareket |
| `nps` | memnuniyet ölçümü |
| `package` | kargo/paket ve teslim kanıtı |
| `parking` | araç, otopark ve geçiş cihazı |
| `patrol` | devriye, QR/GPS ve saha raporu |
| `personnel` | personel, izin, bordro ve uyum takvimi |
| `reservation` | tesis ve rezervasyon |
| `settings` | site ayarları, gizlilik, yaşam döngüsü |
| `smart_collection` | açıklanabilir tahsilat riski |
| `survey` | anket ve oylama |
| `visitor` | ziyaretçi ve geçiş kodu |
| `gateway` | tek giriş, JWT/revocation, CORS, yönlendirme |
| `scheduler` | zamanlanmış bildirim ve saklama/imha işleri |

`banking` bilinçli olarak uygulanmamıştır ve uçları 501 döner. Firebase push, MongoDB, Kafka ve yapay zekâ entegrasyonu yoktur; olmayan sağlayıcılar varmış gibi gösterilmez.

### Ortak davranışlar

- JWT erişim/yenileme, kademeli giriş kilidi ve jeton iptali.
- Site bazlı roller: `MANAGER`, `BOARD_MEMBER`, `AUDITOR`, `STAFF`, `RESIDENT`, `OWNER`, `TENANT`, `PROXY`.
- Uygulama katmanı `property_id` kapsamı ve PostgreSQL RLS ile fail-closed çok kiracılık.
- TCKN/IBAN için AES-256-GCM ve kör indeks; hassas veri erişim kaydı.
- Para işlemlerinde tam sayı kuruş ve en büyük kalan dağıtımı; `float64` kullanılmaz.
- Mevzuat oranları `legal_parameters` üzerinden yürürlük tarihi ve hukuki dayanakla yönetilir.
- İstek denetim izi, erişim kaydı, bildirim outbox'ı, idempotency ve değiştirilemez finansal kayıtlar.
- Yerel veya S3 uyumlu dosya depolama; yapılandırma yoksa yükleme başarılı gösterilmez.

## Bildirimler ve otomasyon

Bildirim kanalları `IN_APP`, `SMS` ve `EMAIL`'dir. `PUSH` sağlayıcısı bağlı olmadığı için kuyrukta kalır. Alıcı kümeleri sakinler, daire sakinleri, borç sorumluları, malik, kiracı, yönetim, onaylayıcı ve operasyon ekipleri olarak merkezi tanımlıdır.

Zamanlayıcı; vadesi geçen aidat, sözleşme ihbarı/süresi, devriye, demirbaş bakımı, KVKK süresi ve imhası, işletme projesi, acil durum tatbikatı, SGK/MUHSGK, DASK yenileme ile etkinlik/sensör/devriye izi saklama sürelerini yönetir. Kart ödeme uzlaştırma, cihaz canlılığı, sensör canlılığı ve kargo kanıtı imhası için servis bekçileri bulunur.

## Mimari ve güvenlik

- PostgreSQL 16 tek veri deposudur; migration'lar `cmd/migrate` ile transaction, advisory lock ve SHA-256 doğrulamasıyla uygulanır.
- Uygulama servisleri `siteeksen_app`, kimlik servisi `siteeksen_identity` rolüyle bağlanır; süper kullanıcı kullanılmaz.
- Gateway tek ingress'tir. Kong yalnızca opsiyonel edge rate-limit katmanı olarak gateway'in önünde durur.
- Dağıtım dosyaları `backend/scripts/gen-deploy.py` ile üretilir; elle düzenlenmez.
- Geri alma migration “down” ile değil, doğrulanmış veritabanı yedeğinden geri yüklemeyle yapılır.
- KVKK, RLS, rol denetimi, audit log, veri saklama ve erişim kanıtı birlikte uygulanır.

## Kurulum ve çalıştırma

### Gereksinimler

- Docker ve Docker Compose
- Go 1.24+
- Node.js 22+
- Flutter (mobil doğrulama/build için)
- PostgreSQL 16 (Docker ile sağlanır)

### Geliştirme

```bash
bash backend/scripts/dev-up.sh
cd admin && npm install && npm run dev
```

Panel: `http://localhost:3001` · Gateway: `http://localhost:8888`

Yerel demo hesapları ve sağlayıcı ayarları için [docs/yerel-calistirma.md](docs/yerel-calistirma.md) dosyasına bakın. Mobil uygulamalarda API adresi `--dart-define=API_BASE_URL=...` ile değiştirilebilir.

### Doğrulama

```bash
bash backend/scripts/verify-stack.sh
bash backend/scripts/verify-mobile.sh
cd admin && npx tsc --noEmit && npm run lint && npm run build
```

## Kaynak dokümantasyon

- [Özellik ve yetenek haritası](docs/ozellik-haritasi/README.md) — sayfa/ekran, eylem, API, yetki, tablo, bildirim ve etki kanıtları
- [Servisler ve mimari](docs/claude/servisler.md)
- [Gerçek mimari durum](docs/claude/mimari-durum.md)
- [API sözleşmesi](api/openapi.yaml)
- [Test planı](docs/test-plani/README.md)
- [Gizlilik ve hukuk](legal/)
- [İlerleme ve kanıt kayıtları](tasks/)

## Lisans

Tüm hakları saklıdır © 2026 SiteEksen.
