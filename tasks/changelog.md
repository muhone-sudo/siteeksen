# CHANGELOG

Projedeki tüm önemli değişiklikler bu dosyada takip edilir.

> **Not (2026-09-09):** Bu dosya tek doğruluk kaynağıdır; kökteki `CHANGELOG.md` yalnızca buraya işaret eder.
> Aşağıdaki **2026-09-09 öncesi** girdiler, 2026-09-09 denetiminde iddialarının önemli bölümü yanlış
> çıktığı için **güvenilmez** kabul edilmelidir (ayrıntı: `tasks/audit-raporu.md`). Girdiler tarihsel kayıt
> olarak korunmuştur ama "tamamlandı" ifadeleri kanıtlanmamıştır.
> Bundan sonraki her girdi `tasks/dogrulama-politikasi.md` uyarınca **kanıt satırı** taşır.

---

## [Unreleased]

### 2026-09-26 — RLS TAMAMLANDI, EN AZ YETKİ, DAĞITIM TEK KAYNAKTAN (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **886 kontrol, 0 başarısız**.
> Ek kanıt: gerçek imajlarla `docker compose` duman testi — 26 migration, iki rol
> parolası atandı, giriş kimlik rolüyle 200, finance uygulama rolüyle 200,
> kaplar uid 10001 (root değil). Commit'ler: `72603f9`, `3543388`, `ada898a`.

#### RLS 30 → 81 tablo (migration 023-026)

- **023:** ödeme, gecikme tazminatı, tahakkuk detayı, tüketim faturası, gider,
  talep, duyuru (10 tablo). `payments`'a `property_id` eklendi: çok daireli
  ödemede `unit_id` boş kaldığından ödemenin sitesi bilinemiyordu.
- **024:** kalan altı servis (governance, settings, smart_collection, iot,
  energy_analytics, esg) kapsama geçirildi; çok servisli `monthly_assessments`,
  `expense_categories`, `meters`, `meter_readings` açılabildi (22 tablo).
- **025:** dizin tabloları (users, properties, units, blocks, resident_units,
  property_roles) + ayrı **kimlik rolü**.
- **026:** kullanılmayan 13 site tablosu korumalı doğar; platform tabloları
  uygulama rolüne kapalı.

**Geçiş sırasında bulunan ve kapatılan gerçek açıklar:**

| Yer | Açık | Etki |
|---|---|---|
| Talep | `GetByID/UpdateStatus/ConfirmResolution` site filtresiz | A sitesinin yöneticisi B'nin talebini ilerletebiliyordu |
| Ödeme | Tahakkuk seçimi aktif siteye göre süzülmüyordu | Başka sitenin tahakkuku ödemeye bağlanabiliyordu |
| Bütçe itirazı | Listeleme/sonuçlandırma site filtresiz | Başka site itirazı reddedip projenin kesinleşme engelini kaldırabiliyordu |
| Bütçe itirazı | Daire doğrulanmıyordu | Kiracı ya da başkasının (başka sitenin) dairesi adına itiraz — KMK m.37/2 hak malikindir |
| Karar defteri | Yazma/okuma/doğrulama site filtresiz | Başka sitenin KARAR DEFTERİNE kayıt yazılabiliyordu (KMK m.32) |
| Görünümler | Süper kullanıcının yetkisiyle çalışıyordu | `monthly_expense_summary` üzerinden tüm sitelerin gider özeti okunuyordu |
| Uygulama rolü | Dizin tablolarında tam yetki | Tüm sitelerin telefon/e-posta/**parola özeti** okunabilir; roller, arsa payları değiştirilebilir; jeton iptali ve denetim izi silinebilirdi |
| Geçersiz kimlik | Veritabanı tür hatası | 404 yerine 500 |

#### Dağıtım — `backend/scripts/gen-deploy.py`

Önceki durum: `docker-compose.yml`'de 26 servisin **18'inde veritabanı ve JWT
ayarı yoktu** (açılamazlardı), kalan 8'i **süper kullanıcıyla** bağlanıyordu —
RLS dağıtımda hiç devrede değildi. k8s 2 servis tanımlıyordu; ingress servisleri
gateway'i atlayarak ve yanlış önekle (`/v1` ↔ `/api/v1`) yayınlıyordu. CI 3 imaj
üretiyordu. Dockerfile'lar root çalışıyordu. Redis/Mongo/Kafka compose'da ayakta
ama koddan hiç kullanılmıyordu.

Artık tek bir servis listesinden: 27 Dockerfile (uid 10001, sağlık kontrolü),
compose (zorunlu gizli değer yoksa açılmaz, demo verisi varsayılan kapalı),
k8s (26 servis + gateway + panel + migrate işi, salt-okur kök dosya sistemi),
CI (29 imaj; önce migrate işi, sonra dağıtım). `--check` kipi doğrulamada sapmayı
yakalar. `cmd/migrate` rol parolalarını ortam değişkeninden atar.

### 2026-09-14 (üçüncü tur) — RLS İKİNCİ DİLİM + BİLDİRİM BAĞLANTISI (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **769 kontrol, 0 başarısız**

#### 2.6 devamı — Satır düzeyi güvenlik ikinci dilimi (migration 021)

RLS 7 tablodan **26 tabloya** çıkarıldı. Eklenenler yine yalnızca TEK servisin
kullandığı tablolar: otopark (3), ziyaretçi (1), stok (3), demirbaş (3),
devriye (3), ilan panosu (3), anket (3).

- Önce sekiz servisin deposu `pkg/dbscope` kullanımına geçirildi (86 sorgu),
  SONRA migration yazıldı. Ters sıra uygulamayı bozardı: RLS açıkken kapsamsız
  sorgu boş liste döner.
- **nps-service aynı dilimde geçirilmek ZORUNDAYDI:** ayrı tablo açmaz, anket
  tablolarını kullanır. Yalnızca survey geçirilseydi RLS açıldığı an NPS
  çalışmaz hâle gelirdi.
- `property_id` taşımayan altı alt tablo (movements, maintenance, comments,
  messages, options, votes) ebeveyn üzerinden `EXISTS` ile korunuyor. RLS bu
  alt sorguyu HER SATIR için çalıştırdığından ebeveyn anahtarlarına indeks
  eklendi — indekssiz kalsaydı koruma "yavaş olduğu için kapatılan" bir şeye
  dönerdi.

**Çalışırken bulunan iki gerçek sorun:**

1. `asset_categories` ve `inventory_categories`, `property_id IS NULL` olan
   ORTAK kategoriler taşıyor (005 tohum verisi: "Asansör", "Temizlik
   Malzemeleri"…) ve depo bunları bilerek okuyor. Katı politika bu satırları
   HER siteden gizliyordu — kimse hata almazdı, kategoriler sessizce
   kaybolurdu. OKUMA global satırlara açıldı, YAZMA katı bırakıldı: uygulama
   kendi başına global kategori üretemez (üretebilseydi tek hatalı istek o
   satırı platformdaki her siteye görünür kılardı).
2. Doğrulamanın "kapsamsız sorgu SIFIR satır döndürmeli" ölçüsü kategori
   tabloları için yanlıştı. Ölçü "hiç satır dönmesin" değil **"hiçbir SİTE
   VERİSİ dönmesin"** olarak düzeltildi; muafiyetin sessizce genişlememesi
   için ortak satır sayısı tohum verisine sabitlendi.

Kalan 63 tablo bilerek kapalı ve doğrulama bu sayıyı raporluyor.

#### Bildirim — altı modül gerçekten bildirim gönderiyor

Önceki durum: `pkg/notify` yazılmıştı ama **hiçbir modül onu çağırmıyordu**.
Modüller "BİLDİRİM GÖNDERİLMEDİ; altyapı bağlı değildir" notu düşüyordu; not
dürüsttü ama iş yarım kalmıştı.

| Modül | Olay | Alıcı |
|---|---|---|
| community | duyuru yayımlandı | sitenin aktif sakinleri |
| reservation | onay / red | YALNIZCA rezervasyonu yapan sakin |
| package | kargo kaydedildi | YALNIZCA ilgili dairenin sakinleri |
| survey | anket yayına alındı | sitenin aktif sakinleri |
| visitor | ziyaretçi giriş yaptı | ilgili dairenin sakinleri |
| inventory | stok asgarinin altına düştü | YALNIZCA yönetim rolleri |

- Yeni `pkg/notify/audience.go`: alıcı kümesi TEK yerde. Beş modül aynı sorguyu
  ayrı ayrı yazsaydı, birinde `is_active` filtresi unutulduğunda siteden
  taşınmış birine bildirim gider ve kimse fark etmezdi. İki daireli malik
  duyuruyu bir kez alır.
- `Broadcast` sayaçlarla döner ve sonuç API yanıtına konur. **"Gönderildi"
  sözcüğü yalnızca gerçekten gönderilen kayıt varsa geçer**; sağlayıcısız
  kanalda "kuyrukta bekliyor (GÖNDERİLMEDİ)" yazar.
- Kayıt/durum tutarlılığı: kargo `NOTIFIED`'a, ziyaretçi `resident_notified_at`
  alanına ancak bildirim GERÇEKTEN oluştuysa geçer. Aksi hâlde kayıt, kargo
  kaybolduğunda "sakinin haberi vardı" diyen yanıltıcı bir delile dönüşürdü.
- Kişisel veri sınırları: kargo bildirimi takip numarası/gönderici TAŞIMAZ
  (kilit ekranında görünür); rezervasyon kararı tüm siteye duyurulmaz; stok
  uyarısı sakinlere gitmez (6698 m.4 ölçülülük); ziyaretçiye SMS/QR
  GÖNDERİLMEZ (sağlayıcı yok + 6563 s. Kanun onay şartı).
- **Kanuni sınır:** anket bildirimi genel kurul ÇAĞRISI DEĞİLDİR (634 s. KMK
  m.29 çağrıyı taahhütlü mektup/imza karşılığına bağlar). Gövdeye uyarı
  eklenir ve konu `assembly.call` olarak İŞARETLENMEZ; doğrulama bunu sınar.

Doğrulamadaki eski "bildirim gönderilmedi diyor mu?" iddiaları, **"bildirim
GERÇEKTEN oluştu mu, DOĞRU kişiye mi?"** kontrolleriyle değiştirildi:
veritabanındaki kayıt sayısı, alıcı kümesi, gövde içeriği ve kayıt durumu
ayrı ayrı sınanıyor.

---

### 2026-09-14 (ikinci tur) — FAZ 2 GÜVENLİK TAMAMLANDI (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **714 kontrol, 0 başarısız**
> Dev ortamı: 24 servis + gateway + panel ayakta, hepsi `/health` → 200.

#### 2.7 — Çıkış artık gerçekten çıkış

Önceki durum: "Çıkış yap" yalnızca `{"message":"Çıkış başarılı"}` yazıyor ve
HİÇBİR ŞEY yapmıyordu. Jeton süresi dolana kadar geçerliydi: erişim jetonu
15 dakika, **yenileme jetonu 7 GÜN**. Ortak bilgisayardan çıkan sakinin oturumu
fiilen kapanmıyordu.

- migration 018: `revoked_tokens` (jti reddetme listesi) + `user_token_invalidation`
- `POST /auth/logout` erişim VE yenileme jetonunu iptal eder; yenileme jetonu
  gönderilmediyse yanıt bunu UYARI olarak söyler
- `POST /users/me/logout-all` — tüm cihazlardan çıkış (geçmişe dönük)
- Yenileme akışında iptal denetimi: olmasaydı çıkış hiçbir işe yaramazdı
- `AuthMiddleware()` → `AuthMiddleware(pool)`: imza değişikliği bilinçli, eksik
  kalan her çağrı yerini DERLEME HATASI yapar (26 çağrı yeri güncellendi)

#### 2.8 — TCKN ve IBAN şifreli

Önceki durum: düz metin. `pkg/encryption` yazılmış ama import edilmiyordu.

- `pkg/pii`: AES-256-GCM; aynı değer her seferinde farklı şifreli metin üretir
- Arama anahtarı **HMAC-SHA256**, düz SHA-256 değil: TCKN'nin değer uzayı
  ~10^10'dur ve anahtarsız özet kaba kuvvetle geri çevrilebilir. Doğrulamada
  anahtarın düz SHA-256 ile eşleşmediği ayrıca sınanıyor.
- TCKN algoritmik sağlama ve IBAN mod-97 doğrulaması: şifreli alandaki yazım
  hatası sonradan gözle bulunamaz
- Aynı TCKN ile ikinci aktif personel açılamaz (kısmi tekil indeks)
- `cmd/encrypt-pii`: mevcut düz metni şifreler ve düz metin kolonu NULL'lar
- Varsayılan MASKELİ; maskesiz erişim `?reveal=true` ister ve ayrı `PII_REVEAL`
  denetim kaydı üretir. Kayıt tutulamıyorsa veri AÇILMAZ.

#### 2.6 — Satır düzeyi güvenlik (birinci dilim)

**Çalışırken bulunan kritik nokta:** PostgreSQL'de RLS SÜPER KULLANICIYI
BAĞLAMAZ — `FORCE ROW LEVEL SECURITY` bile. Uygulama süper kullanıcıyla
bağlandığı sürece politikalar tanımlıdır ama hiç devreye girmez. İlk denemede
tam olarak bu görüldü: politikalar açıkken kapsamsız sorgu satır döndürdü.

- migration 020, yetkisi sınırlı `siteeksen_app` rolünü oluşturur; servisler
  artık onunla bağlanır. Rolün DDL yetkisi yoktur. Parola migration'a yazılmaz.
- `pkg/dbscope`: her isteği `SET LOCAL app.property_id` ayarlanmış transaction
  içinde çalıştırır. Oturum düzeyinde ayarlamak BİLEREK yapılmadı: havuzdan
  alınan bağlantı geri döndüğünde değişken başka sitenin isteğine sızardı.
- RLS 7 tabloda açık (personel, belge, bildirim) — hepsi TEK servis tarafından
  kullanılan tablolar. 82 tablo bilerek kapalı; doğrulama bunu sayarak raporluyor.
- Doğrulanan: kapsamsız sorgu SIFIR satır; çapraz site erişimi kapalı;
  `WHERE property_id` olmadan yazılmış sorgu bile sızdırmıyor; kapsam dışına
  yazma engelli (WITH CHECK); geçersiz kapsamda hiçbir satır yok.

---

### 2026-09-14 — FAZ 5 TAMAMLANDI: 22 mock servisin tamamı ele alındı (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **646 kontrol, 0 başarısız**
> Gerçek veri katmanına bağlı servis: **4 → 20**. Bilerek yazılmayan: **2** (gerekçeli).
> Dev ortamı: 24 servis + gateway + panel ayakta (hepsi `/health` → 200).

#### Bu turda gerçeğe çevrilen modüller (9-22)

| # | Modül | Önceki davranış | En kritik eklenen kural | Adım |
|---|---|---|---|---|
| 9 | demirbaş | sabit liste | amortisman **saklanmaz, hesaplanır**; kayıttan düşme karar dayanağı ister (KMK m.45) | §20 |
| 10 | stok | hareket kaydedilmiyordu | satır kilidiyle eşzamanlılık; negatif stok yasak; sayım düzeltmesi gerekçe ister | §21 |
| 11 | anket | sabit sonuç (%68 evet) | **genel kurul kararı üretilemez** (KMK m.29-32); oy hakkı bağımsız bölüm başına (m.31/1); ağırlık arsa payı (m.20) | §22 |
| 12 | sayaç/IoT | sabit endeks | ısı gideri %70 tüketim + %30 alan (RG 14.04.2008); oranlar `legal_parameters`'tan; endeks zinciri sunucuda | §23 |
| 13 | bildirim | "gönderildi" yalanı | giden kutusu; sağlayıcı yoksa PENDING kalır; ticari ileti onaysız gönderilmez (6563 m.6) | §24 |
| 14 | devriye | hiç gezilmemiş tur "tamamlandı" | zaman sunucudan; durum okutmalardan **hesaplanır**; çok hızlı tur işaretlenir | §25 |
| 15 | duyuru + ilan | uydurma veri | ilan yönetim onayından geçer; okundu kaydı; yorum silinmez gizlenir | §26 |
| 16 | ayarlar | sabit ayar | **mevzuat parametreleri ezilemez** — uygulama + veritabanı kısıtı | §27 |
| 17 | enerji analizi | uydurma "AI" tahmini | medyandan sapma, alan başına karşılaştırma; tahmin üretilmez | §28 |
| 18 | akıllı tahsilat | uydurma risk skoru | ağırlıkları yazılı, gerekçeli skor; icra **önerilir**, yapılmaz (KMK m.22) | §28 |
| 19 | NPS | sabit "NPS: 42" | sabit tanım (0-6/7-8/9-10); yanıt yoksa skor yok; anonim | §29 |
| 20 | ESG | sabit karbon ayak izi | **emisyon katsayısı koda gömülmez**, kullanıcı kaynağıyla verir | §29 |
| 21 | banka | uydurma bakiye | **yazılmadı** — S-07 kullanıcı kararı; 501 + engel listesi | §29 |
| 22 | toplantı sihirbazı | uydurma transkript/özet | **yazılmadı** — governance ile tekrar olurdu; oraya yönlendirir | §29 |

#### Yeni altyapı

- **`pkg/storage` (S-09)** — dosya saklama. `local` + `s3` (SigV4, harici
  bağımlılık yok; Oracle / Cloudflare R2 / AWS). Yapılandırma yoksa açılmaz.
- **`pkg/notify` (S-10)** — sağlayıcıdan bağımsız giden kutusu. Sağlayıcı yoksa
  bildirim PENDING kalır ve hiçbir yerde "gönderildi" denmez.
- **migration 015** belge arşivi + erişim kaydı, **016** bildirim + tercihler,
  **017** site ayarları + değişiklik geçmişi. Üçünde de salt-ekleme tetikleyicileri.

#### "Yapay zekâ" iddiası kaldırıldı

Enerji analizi, tahsilat riski ve karbon ayak izi **gerçek hesap** yapar ama
YZ kullanmaz. `ai_model_version`, `predictions`, `predicted_payment_probability`
alanları bilerek boş bırakılır ve doğrulamada boş kaldıkları ayrıca sınanır.
Gerekçe: bir model olmadan sürüm numarası yazmak ve "ödeme olasılığı %62" demek,
olmayan bir yeteneği var göstermektir. Bunun yerine formülü kodda yazılı,
her sonucu gerekçeli istatistikler üretilir.

#### Düzeltilen hatalar

- **`verify-stack.sh` eşzamanlılık testi betiği kilitliyordu.** Çıplak `wait`,
  kabuğun tüm arka plan çocuklarını — yani doğrulama boyunca ayakta tutulan
  servisleri — bekliyordu. Artık yalnızca ilgili işler bekleniyor.
- **Hareket zinciri kontrolü yanlış alarm veriyordu.** Eşzamanlı kayıtlar aynı
  zaman damgasına düştüğünde gerçek sıra kurulamıyordu. Yerine kayıp
  güncellemeyi doğrudan ölçen kontrol kondu.
- **Isı paylaştırmasında kullanım alanı zorunluluğu** yanlışlıkla su/elektriği
  de kapsıyordu; alan yalnızca ısıtmada gerekir.
- **Stub dürüstlük testi kimliksiz çağırıyordu.** Stub uçları da kimlik
  doğrulaması arkasında olmalı: kimliksiz 401, kimlikli 501. 501'i kimliksiz
  servis etmek, olmayan bir modülün varlığını dışarıya doğrulamak olurdu.

---

### 2026-09-13 (ikinci tur) — FAZ 5: Sekiz modül mock'tan gerçeğe + dosya depolama (DOĞRULANMIŞ)

> **Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **283 kontrol, 0 başarısız**
> (art arda iki tur aynı sonuç — kararlılık ayrıca doğrulandı).
> Gerçek veri katmanına bağlı servis sayısı **4 → 12**. Kalan mock servis: **14**.

#### Gerçeğe çevrilen modüller

| # | Modül | Önceki davranış | Eklenen gerçek davranış | Kanıt |
|---|---|---|---|---|
| 1 | gider (expense) | sabit JSON | kalem bazlı dağıtım, faturasız gider onayı | §12 |
| 2 | personel | sabit JSON | TCKN/IBAN maskeleme, izin bakiyesi, çakışma reddi | §13 |
| 3 | ziyaretçi | sabit JSON | sakin yalnızca kendi ziyaretçisini görür | §14 |
| 4 | otopark | sabit JSON | plaka normalleştirme, kapasite, ücret (kuruş) | §15 |
| 5 | rezervasyon | sabit JSON | **çakışma denetimi**, tampon süre, kota, saat kuralları | §16 |
| 6 | kargo (package) | "bildirim gönderildi" yalanı | teslim/iade kaydı, KVKK bölüm bazlı görünürlük | §17 |
| 7 | sözleşme | sabit JSON | ihbar penceresi, elle yenileme, mali yük özeti | §18 |
| 8 | belge arşivi | "yüklendi" deyip yazmıyordu | gerçek dosya saklama, sürümleme, erişim kaydı | §19 |

#### Rezervasyon — çakışma denetimi *(FAZ 5.5)*

Mock sürümde çakışma denetimi **hiç yoktu**: iki sakin aynı saati "ayırttığını"
sanabiliyordu. Artık tesis satırı `FOR UPDATE` ile kilitlenip `tstzrange` kesişimi
ve `buffer_minutes` tamponu **aynı transaction içinde** denetleniyor (yarış durumu yok).
Ayrıca min/max süre, çalışma saatleri ve açık günler (Europe/Istanbul yerel saatiyle),
`advance_booking_days` ve bağımsız bölüm başına haftalık kota sunucuda uygulanıyor.
**Kanıt:** `verify-stack.sh` §16 — çakışan istek 409, tampon içi istek 409, tampon
dışı istek 201, iptal sonrası saat yeniden alınabiliyor.

#### Kargo — KVKK veri minimizasyonu *(FAZ 5.6)*

Sakin artık **komşusunun kargosunu göremiyor** (liste ve tekil okuma ayrı ayrı
sınırlandı). Teslimde `delivered_to_name` zorunlu — kaybolan kargoda sorumluluk
belirli. `notify` ucu bildirim **göndermez**, görevlinin elle haber verdiğini kayda
geçirir ve bunu yanıtta açıkça söyler. **Kanıt:** §17.

#### Sözleşme — ihbar penceresi *(FAZ 5.7)*

Kendiliğinden yenilenen bir sözleşmede ihbar süresi kaçırılırsa site habersiz yeni
bir mali yüke bağlanır. Artık `notice_due` hesaplanıyor; **sistem kendiliğinden
yenileme yapmıyor**, yenileme elle onaylanıyor ve bitiş tarihi "bugünden" değil
**mevcut bitişten** itibaren uzatılıyor. `auto_renew` var ama `renewal_period_months`
yoksa kayıt reddediliyor (422). **Kanıt:** §18.

#### Dosya depolama — `pkg/storage` *(S-09)*

Projede dosya saklama **hiç yoktu**. Eklendi:
- `Store` arayüzü (Put/Get/Stat/Delete) + `local` ve `s3` adaptörleri
- S3 imzalama (AWS SigV4) **harici bağımlılık olmadan**, yalnızca stdlib ile.
  Aynı kod Oracle Object Storage, Cloudflare R2 ve AWS S3'te çalışır.
- Yapılandırma eksikse `ErrNotConfigured` — sessizce varsayılana düşülmez
- Her yükleme SHA-256 özeti döner (belge bütünlüğü kanıtı)
- `ValidateKey`: dizin dışına çıkma (`..`, mutlak yol) engellenir
- `Describe()` erişim anahtarını asla yazmaz

**Kanıt:** `go test ./pkg/storage/...` → 8 test geçti (SigV4 imzası `httptest` ile
doğrulandı); `verify-stack.sh` §19 — yüklenen dosyanın **diskte gerçekten** olduğu,
diskteki SHA-256'nın yüklenenle aynı olduğu ve indirilenin bozulmadığı sınandı.

#### Belge arşivi — migration 015 *(FAZ 5.8)*

- `documents`: kategori, görünürlük kademesi, sürümleme, SHA-256, saklama süresi
- `document_access_logs`: KVKK m.12 erişim kaydı, **salt-ekleme** (tetikleyici korumalı)
- Görünürlük SORGUDA uygulanıyor (fail-closed):
  `RESIDENTS` ⊂ `OWNERS` (KMK m.36 inceleme hakkı) ⊂ `MANAGEMENT`
- Görünürlük belirtilmezse **en dar** kademe uygulanır
- Yetkisiz tekil okuma **404** döner → belgenin varlığı sızdırılmaz
- Erişim kaydı yazılamıyorsa belge **verilmez**
- Üst veri yazılamazsa depodaki dosya geri alınır (öksüz dosya bırakılmaz)

#### Düzeltilen hatalar

- **Panelde sonsuz yönlendirme döngüsü (ERR_TOO_MANY_REDIRECTS).** İki neden:
  (1) identity giriş yanıtında `roles`/`active_property_id` alanları yoktu; panel
  oturumda rol bulamayıp **giriş yapan herkesi** yetkisiz sayıyordu.
  (2) `/dashboard` ön eki `/dashboard/forbidden` sayfasını da kapsıyordu → sayfa
  kendine yönleniyordu. Roller artık hem jetona hem yanıta aynı kümeden yazılıyor;
  forbidden sayfası RBAC'tan muaf ve `safeRedirect()` genel döngü koruması eklendi.
  **Gerileme koruması:** `verify-stack.sh` §9'a 4 kontrol eklendi.
- **`verify-stack.sh` kararsızdı (flaky).** `go run X &` iki süreç yaratıyor; betik
  yalnızca sarmalayıcıyı öldürüyor, derlenmiş ikili portu tutmaya devam ediyordu.
  Bir sonraki çalıştırmanın sağlık kontrolü **eski sürece** cevap veriyor ve testler
  eski veritabanına karşı koşuyordu → aynı kodda bir tur 279/279, bir tur 257/279.
  Artık süreç **ağacı** öldürülüyor (`kill_tree`) ve başlangıçta portlar süpürülüyor
  (`free_port`). Kararsız bir doğrulama betiğinin kanıt değeri yoktur.
- **`reservation` servisinin varsayılan portu** `kong/kong.yml` ile hizalandı (8101).
- **`dev-up.sh`** yalnızca 4 servisi kaldırıyordu; gerçeğe çevrilen 8 modül ayakta
  olmadığı için gateway bunlara 502 dönüyordu. Artık 12 servis + gateway kalkıyor.

---

### 2026-09-13 — FAZ 0/1/2/4/6: Dürüstlük tamamlandı, güvenlik ve yönetişim katmanı (DOĞRULANMIŞ)

> **Toplu kanıt:**
> `bash backend/scripts/verify-stack.sh` → **102 kontrol, 0 başarısız**
> `bash backend/scripts/verify-mobile.sh` → **8 kontrol, 0 başarısız**
> `cd admin && npx tsc --noEmit && npm run lint && npm run build` → hepsi temiz
>
> `tasks/questions.md`'deki 18 sorunun tamamı kullanıcı tarafından yanıtlandı ve
> yanıtlar bu turda uygulandı.

#### Dürüstlük (FAZ 0) — tamamlandı

- **22 mock servisin TÜM uçları `501 Not Implemented` döndürüyor** *(0.B.1)*
  Yalnızca yazma değil, okuma uçları da uydurma veri döndürüyordu. Ortak sözleşme
  `pkg/stub`: gövdede modül adı + "istek İŞLENMEDİ" uyarısı,
  `X-SiteEksen-Not-Implemented: true` başlığı. Sağlık ucu artık `"healthy"` değil
  `"not_implemented"` diyor.
  **Kanıt:** çalışan servise `GET`/`POST /api/v1/vehicles` → 501; kaynaklarda uydurma
  isim taraması → 0 satır.
- **Community'nin 4 auth'suz modülü kapatıldı** *(0.B.4)* — duyuru/anket/ilan/rezervasyon
  uçları **token'sız** POST/DELETE kabul ediyordu (herkes duyuru silebilirdi).
  `AuthMiddleware` arkasına alındı ve 501'e çevrildi.
- **Gateway'deki uydurma mali rapor üretimi kaldırıldı** *(2.2)* — `/reports/generate`
  içi tamamen sabit (uydurma daire, sakin adı, tutar) **indirilebilir PDF/Excel**
  üretiyordu. **Kanıt:** `POST /api/v1/reports/generate` → 501.
- **Dashboard özetindeki uydurma sabitler kaldırıldı** *(2.3)* — kaynaklara ulaşılamazsa
  `156 sakin / 245.000 TL / %94` sabitleri dönüyordu. Artık ulaşılamayan alan hiç
  dönmez, `unavailable[]` ile nedeni bildirilir.
- **Mobil (sakin) uygulamasında sahte ödeme akışı kaldırıldı** *(0.C.1)* — borç koda
  gömülüydü (₺1.250) ve "Öde → Onayla" **hiçbir ağ çağrısı yapmadan** "Ödeme Başarılı!"
  diyordu. Artık gerçek API; `payment_gateway_ready:false` iken tahsilatın
  YAPILMADIĞI açıkça söyleniyor.
- **Mobil: çalışmayan "Çıkış Yap" düzeltildi** — onay diyaloğu gösterip
  `// TODO: Logout işlemi` diyerek hiçbir şey yapmıyordu; ortak cihazda doğrudan
  güvenlik sorunu. Artık jetonlar gerçekten siliniyor.
- **Yönetici mobil uygulamasındaki 20 mock ekran gerçek API'ye bağlandı** — sözleşme,
  ilan panosu, enerji, anket, akıllı tahsilat, genel kurul, devriye, demirbaş, stok,
  API anahtarları, raporlar, kargo, rezervasyon, dashboard, talepler, duyurular,
  sayaçlar, finans ve gider ekranları.
- **`api_settings` ekranındaki yanlış güvenlik güvencesi kaldırıldı** *(0.C.5)* —
  "bilgiler şifrelenmiş saklanır, her değişiklik kayıt altındadır" deniyordu; ekranın
  tamamı mock'tu ve `pkg/encryption` hiçbir yerden import edilmiyor.
- **Admin panelde kalan uydurma veriler temizlendi** — ana sayfa (sabit istatistikler,
  12 aylık uydurma grafik, var olmayan kişilere ait "son ödemeler"), talepler (yalnızca
  yerel state'i değiştiren durum güncellemesi), sayaçlar (sunucuya hiç istek göndermeyen
  "Okumaları Kaydet"), ayarlar (sahte yöneticiler, iyzico/Firebase/SMTP için yanlış
  "Bağlı" rozetleri, uydurma "Pro Plan ₺299/ay" ve 3 ödenmiş fatura).
- **Hukuki metinler gerçeğe uyarlandı** *(0.D)* — KVKK güvenlik bölümü yeniden yazıldı
  (uygulanan/uygulanmayan ayrımı), zorunlu "toplama yöntemi ve hukuki sebep" bölümü
  eklendi, üç metne "TASLAK — yayına hazır değil" uyarısı kondu.

#### Kurulabilirlik ve altyapı (FAZ 1) — tamamlandı

- **Migration çalıştırıcı** *(1.5)* — `backend/cmd/migrate`: `schema_migrations` sürüm
  tablosu, PostgreSQL **advisory lock**, **SHA-256 sağlama denetimi** (uygulanmış bir
  migration sonradan değiştirilmişse durur), migration başına transaction,
  `-status` / `-dry-run`. Docker imajı ve compose servisi eklendi.
  **Kanıt:** sağlama bozulduğunda çalıştırıcı hata verip çıkış kodu 1 döndürdü.
- **Tüm migration'lar idempotent** *(1.4)* — 001/003/005'te 140+ ifadeye
  `IF NOT EXISTS`, 004'teki trigger'a `DROP TRIGGER IF EXISTS`, 002'ye tam koruma.
  **Kanıt:** 14 migration dosyasının tamamı temiz kurulumdan sonra yeniden uygulandı, hata yok.
- **`003`'ün `DROP TABLE audit_logs` komutu kaldırıldı** *(1.13)* — migration her
  tekrarlandığında **KVKK denetim izinin tamamı siliniyordu**.
  **Kanıt:** tabloya kayıt atılıp 003 yeniden uygulandı; kayıt yerinde.
- **Seed verisi tutarlı** *(1.8)* — `total_units=24` deniyor ama 6 birim vardı; arsa payı
  toplamı 10000 yerine 2480'di. Bu, **arsa payına göre dağıtımı test edilemez** kılıyordu.
  Artık 24 bağımsız bölüm ve arsa payı toplamı tam **10000**.
- **Seed `initdb` dışına taşındı** *(1.7b)* — `SEED_DEMO_DATA=false` ile üretimde bilinen
  şifreli demo hesaplar açılmıyor.
- **13 servisin varsayılan portu** kanonik tabloya eşitlendi; 4 çakışma giderildi *(1.10)*.
- **`firebase-credentials.json` bind mount'u kaldırıldı** *(1.11)* — dosya yok; Docker
  eksik yolu dizin olarak yaratıp `docker-compose up`'ı kırıyordu.
- **CI gerçek kapı** *(1.12)* — Go 1.21 → **1.24**; `go build/vet/gofmt/test -race`;
  admin'de `|| true` kaldırıldı; Trivy `exit-code: 1` + **sır taraması**; mobil matris;
  `verify-stack` işi. `.eslintrc.json` eklendi (yoktu, `npm run lint` CI'da takılıyordu).

#### Güvenlik (FAZ 2)

- **Gateway'e kimlik doğrulaması eklendi** *(2.1)* — 25 servise yönlendiren gateway
  **hiçbir jeton doğrulaması yapmıyordu**; maaş, TCKN, IBAN ve **API anahtarları**
  token'sız erişilebiliyordu. `pkg/authtoken` (tek kaynak) + fail-closed `JWT_SECRET`.
  İstemciden gelen `X-User-*`/`X-Property-Id`/`X-Tenant-Id` başlıkları **siliniyor**.
  CORS joker `*` yerine allowlist. Her isteğe `X-Request-Id`.
  **Kanıt:** token'sız → 401, geçersiz jeton → 401, `/auth/login` açık, geçerli jeton → 200.
- **Kong'a jwt eklentisi** — 25 rotada; consumer anahtarı Kong env vault'tan; joker CORS
  kökenleri kaldırıldı. Jetonlara `iss: "siteeksen"` claim'i eklendi.
- **Aktif site seçiminde sahiplik doğrulaması** *(2.4)* — `POST /users/me/active-property`
  gelen `property_id`'yi hiç doğrulamıyordu; herhangi bir kullanıcı tek istekle
  **başka bir sitenin verisine geçebiliyordu**. Artık `resident_units` bağı aranıyor.
  **Kanıt:** yabancı siteye geçiş → 403, kendi sitesine → 200.
- **Roller site bazlı** *(2.5)* — `users.roles` global olduğu için bir sitede MANAGER olan
  kişi **tüm sitelerde** yöneticiydi. `migrations/013` ile `property_roles` tablosu
  (atama izi, geçerlilik dönemi, karar referansı — KMK m.34). Jeton rolleri aktif siteye
  göre üç kaynaktan birleştiriliyor.
  **Kanıt:** kiracı jetonunda MANAGER yok, TENANT var; yönetici jetonunda MANAGER var.
- **Servis düzeyinde RBAC** *(2.9)* — site geneli borçlu/ödeme listeleri ve tahakkuk
  oluşturma yalnızca yönetim rollerine açık; denetçi okur, yazamaz.
  **Kanıt:** yönetici `/finance/debtors` → 200, kiracı → **403**; yetkisiz deneme denetim
  izine `DENIED` olarak yazıldı.
- **Panelde RBAC** *(0.A.10)* — panelde hiçbir erişim kontrolü yoktu; adres çubuğuna
  yazarak maaş bordrosuna ve API anahtarlarına girilebiliyordu. `src/lib/rbac.ts`
  (yol → rol, hukuki gerekçeleriyle), `middleware.ts` yol kontrolü, menü süzme,
  `/dashboard/forbidden` açıklama sayfası.

#### Para doğruluğu (FAZ 4)

- **Ödeme artık borçtan düşüyor** *(4.2)* — `monthly_assessments.paid_amount` hiç
  güncellenmiyordu; ödemesini yapan sakin **sonsuza dek borçlu** kalıyordu.
  Yönetici onay akışı (havale/EFT/nakit gerçeği): tek transaction, `FOR UPDATE`,
  yalnızca `PENDING` onaylanabilir, başka siteye ait ödeme 403.
  **Kanıt:** onay öncesi borç değişmiyor; onay sonrası `0,00 → 1.200,00` ve `PAID`;
  çift onay → **409**; `has_debt:false`.
- **Kuruş hassasiyetli para aritmetiği** *(4.3/4.4)* — `pkg/money`: para tam sayı kuruş;
  dağıtımda **en büyük kalan** yöntemi → payların toplamı tutara **birebir** eşit.
  **Kanıt:** 2000 rastgele senaryoda kuruş kaybı yok; 9 birim testi.
- **Gecikme tazminatı tahakkuku** *(KMK m.20/2)* — hiç hesaplanmıyordu.
  `POST /finance/late-fees/accrue`; oran mevzuat tablosundan; anapara = ödenmemiş
  **asıl** borç (tazminat üzerinden tazminat işlenmiyor); **idempotent**.
  **Kanıt:** 30 gün gecikme → **60,00 TL**, toplam **1.260,00 TL**; ikinci çalıştırmada
  değişmiyor; `late_fee_accruals` tablosuna gün/oran/anapara izi yazılıyor.

#### Mevzuat parametreleri (S-05)

- **`migrations/012` + `pkg/legalparams`** — 26 parametre yürürlük tarihli ve **hukuki
  dayanağıyla** veritabanında. Kanunla sabit parametrelerin (gecikme tazminatı, nisaplar,
  vekâlet sınırları) site bazında değiştirilmesi **veritabanı tetikleyicisiyle** engellendi.
  Bulunamayan parametre için **sessiz varsayılan yok** — hata döner.
- Araştırma ile teyit edilen değerler: gecikme tazminatı aylık **%5** (m.20/2, yönetim
  planıyla değiştirilemez); ısıtma **%70 tüketim + %30 alan** (RG 14.04.2008); vekâlet
  toplam oyun **%5**'i, **40 ve altı** bağımsız bölümde kişi başı **2**; malikin oyu tüm
  oyların **1/3**'ünü aşamaz (m.31); merkezi→ferdi ısıtma geçişi **2000 m²** ve üzeri
  binalarda **oybirliği** (m.42 / 5627 s. Kanun).

#### Yönetişim katmanı (FAZ 6) — yeni servis

- **`migrations/014` + `services/governance` (port 8107)** — 634 s. Kanunun zorunlu
  kıldığı ve veri modeli **hiç olmayan** süreçler:
  - **İşletme projesi (m.37):** kalem bazlı bütçe, birim payları kuruş cinsinden ve
    kalem dökümlü; tebliğ → 7 günlük itiraz süresi → kesinleşme (İİK m.68 belgesi).
    Tebliğsiz ya da süre dolmadan kesinleştirme **409** ile reddediliyor.
  - **Genel kurul (m.29-33):** 15 günlük çağrı süresi zorunlu; nisap **sayı VE arsa payı**
    bakımından; "yarıdan fazla" tam yarıyı kapsamıyor; ikinci toplantıda yeter sayı
    aranmıyor; vekâlet sınırları uygulanıyor; 4/5, oybirliği ve salt çoğunluk ayrı ayrı
    hesaplanıyor (**14 birim testi**).
  - **Defterler (m.32/36):** kayıtlar **ekle-only** ve **SHA-256 hash zincirli**;
    UPDATE/DELETE veritabanı tetikleyicisiyle engelli; `/verify` ucu zinciri doğruluyor.
  - **İcra/dava (m.22, İİK m.68):** borç tahakkuklardan hesaplanıyor; dayanak belge
    yoksa uyarı.
  **Kanıt:** 336.000 TL'lik bütçenin payları **33.600.000 kuruş** olarak birebir tutuyor;
  12/24 katılımda nisap sağlanmıyor, 13/24'te sağlanıyor; defter kaydı değiştirilemiyor.

#### Doğrulama ortamı

- **Flutter 3.47.4 WSL'e kuruldu** *(S-01b)* → mobil işler artık `[D1]` değil, çalıştırılarak
  doğrulanabiliyor. İki uygulamanın da **derlenmeyen** `widget_test.dart`'ı (şablondan kalan,
  var olmayan `MyApp` sınıfını çağıran sayaç testi) gerçek duman testleriyle değiştirildi.
- **`backend/scripts/verify-mobile.sh`** eklendi.
- **Para/tarih biçimlendirme** `intl` ile doğru TR biçimine geçti (elle biçimlendirme
  `12.450.00` gibi yanlış çıktı üretiyordu).
- **API taban adresleri düzeltildi** — sakin `localhost:8000`, yönetici ise yayında olmayan
  `api.siteeksen.com/v1` (yol da yanlıştı → her çağrı 404) kullanıyordu. Artık
  `--dart-define=API_BASE_URL`.

---

### 2026-09-12 — FAZ 0/1/3/4: Dürüstlük onarımı + kurulabilirlik (DOĞRULANMIŞ)

> **Bu turdaki her madde çalıştırılarak doğrulandı.** Doğrulama artık WSL üzerinden yapılıyor
> (Go 1.24.7 kuruldu; Docker, psql zaten mevcuttu). Toplu kanıt:
> `bash backend/scripts/verify-stack.sh` → **42 kontrol, 0 başarısız.**

#### Eklendi
- **`backend/scripts/verify-stack.sh`** — kalıcı uçtan uca doğrulama betiği. Sıfırdan PostgreSQL 16
  kurar, 11 migration'ı uygular, şema beklentilerini denetler, idempotency sınar, `pkg/audit` testini
  gerçek veritabanına karşı çalıştırır ve identity-service'i ayağa kaldırıp gerçek HTTP istekleriyle
  giriş / yanlış şifre / yetkisiz erişim / denetim izi akışlarını doğrular.
- **`backend/migrations/011_audit_log_fix.sql`** — `audit_logs` şemasını koda uyumlu hale getirir:
  `property_id`, `request_id`, `status_code` eklendi; `tenant_id` zorunluluğu kaldırıldı; 6 indeks.
- **`backend/pkg/audit/audit_test.go`** — denetim izinin gerçekten yazıldığını **gerçek veritabanına
  karşı** doğrulayan 2 test. (Böyle bir hatayı derleyici yakalayamaz; yalnızca DB'ye yazan test yakalar.)
- **`admin/src/components/ui/data-state.tsx`** — ortak `LoadingState` / `ErrorState` / `EmptyState` /
  `NotImplementedNotice` / `toUserMessage`. Sessiz mock fallback yerine görünür hata durumu sağlar.
- **Admin panelde çıkış (logout) düğmesi** — daha önce hiç yoktu, kullanıcı oturumunu kapatamıyordu.

#### Düzeltildi — kurulabilirlik (FAZ 1)
- **Veritabanı artık sıfırdan kurulabiliyor.** Üç ayrı çökme nedeni giderildi:
  1. `004_expense_management.sql` — `expense_categories` tablosu `001`'de farklı kolonlarla zaten
     vardı; `CREATE TABLE IF NOT EXISTS` sessizce atlanıyor, ardından gelen `INSERT` var olmayan
     kolonlara yazıp `42703` veriyordu. Tablo yeniden tanımlanmak yerine eksik kolonlar eklendi;
     varsayılan kategorilere KMK m.20'ye göre `distribution_type` atandı.
  2. `005_new_modules.sql` — `vehicles` tablosu aynı sorunu taşıyordu; ayrıca `idx_vehicles_unit`
     indeksi `001`'de zaten vardı. İdempotent `ALTER TABLE` + `CREATE INDEX IF NOT EXISTS`'e çevrildi,
     `plate_number` NOT NULL kısıtı kaldırılıp veri `plate` kolonuna taşındı.
  3. `005_new_modules.sql` — `inventory_categories` seed'inde **geçersiz UUID** (`ic0000...`;
     `i` hex değil) `invalid input syntax for type uuid` hatası veriyordu → `1c` prefix'ine çevrildi.
     *(Bu hata statik denetimde yakalanmamıştı; yalnızca gerçek veritabanında çalıştırınca ortaya çıktı.)*
  **Kanıt:** temiz PostgreSQL'de 11/11 migration OK; **61 tablo** oluşuyor (önceden 005 çöktüğü için
  `expenses`, `parking_zones`, `reservations`, `bank_accounts`, `employees`, `surveys`, `assets`,
  `meetings` dahil 29 tablo hiç oluşmuyordu). 006-011 tekrar çalıştırılabilir (idempotent).
- **Demo giriş onarıldı.** `002_seed_data.sql`'deki bcrypt hash hiçbir şifreyle eşleşmiyordu ve iki
  kullanıcıya aynı hash yazılmıştı. Hash'ler `cost=12` ile yeniden üretilip doğrulandı.
  **Giriş bilgileri: `5551234567` / `Demo123!`** (ikinci hesap `5559876543`).
  **Kanıt:** gerçek identity-service'e `POST /api/v1/auth/login` → **HTTP 200 + JWT**;
  yanlış şifre → **401**; token'sız `/users/me` → **401**; token ile → **200**.
- **`go build ./...` onarıldı.** Ölü `backend/api/` dizini kaldırıldı — kırık import (`sitesen/...`)
  içeriyordu ve `RequireSuperAdmin` yetkiyi **istemciden gelen `X-User-Role` başlığına** göre
  veriyordu (düzeltilseydi doğrudan kritik güvenlik açığı olurdu). Hiçbir yerden import edilmiyor,
  hiçbir Dockerfile'da derlenmiyordu.
  Ayrıca arkasında gizli kalmış iki derleme hatası giderildi: `pkg/integrations/sms`
  (kullanılmayan `body` + bakiye hiç parse edilmiyordu) ve `pkg/integrations/whatsapp`
  (tanımsız `MediaContent` tipi). **Kanıt:** `go build ./...` → 0, `go vet ./...` → 0.

#### Düzeltildi — denetim izi (FAZ 3)
- **Denetim izi (audit log) artık gerçekten çalışıyor.** `pkg/audit` şemada bulunmayan kolon adlarına
  yazıyordu (`user_ip`/`resource_type`/`resource_id` ⟷ `ip_address`/`entity_type`/`entity_id`);
  INSERT her çağrıda hata veriyor, hata `pkg/middleware/auth.go`'da `_ =` ile yutuluyordu →
  tablo aylardır boştu, oysa `legal/kvkk-aydinlatma.md` "log tutuyoruz, 2 yıl saklıyoruz" diyordu.
  `pkg/audit` tipli `Entry` API'siyle yeniden yazıldı; middleware artık hatayı logluyor,
  `property_id` ve HTTP durum kodunu kaydediyor, 403'leri `DENIED` olarak ayırıyor ve
  401'leri gürültü olmasın diye yazmıyor.
  **Kanıt:** `go test ./pkg/audit/...` → 2/2 PASS (gerçek DB'ye karşı); uçtan uca istekte
  `audit_logs`'a kayıt yazıldığı doğrulandı.

#### Düzeltildi — para doğruluğu (FAZ 4)
- **Bakiye hesabındaki kartezyen çarpım giderildi.** `GetUnitBalance`'taki
  `JOIN users u ON ll.unit_id = (...)` koşulu `u`'ya referans vermiyordu; bu bir CROSS JOIN'di ve
  bakiyeyi **kullanıcı sayısıyla çarpıyordu** (156 sakinli sitede 1.200 TL borç sakine 187.200 TL
  olarak gösteriliyordu). Hesap artık `001`'de tanımlı ve doğru yazılmış `unit_balances` view'ı
  üzerinden, sakinin **tüm** aktif bağımsız bölümlerini kapsayacak şekilde yapılıyor.
- **Ödeme kaydı tek transaction'a alındı ve IDOR kapatıldı.** Önceki akışta transaction yoktu,
  `payment_assessments` INSERT'inin hatası yutuluyordu, `amount` sütunu hiç yazılmıyordu ve
  **tahakkukların çağıran kullanıcıya ait olup olmadığı doğrulanmıyordu** (başkasının tahakkuk
  kimlikleriyle tutar öğrenilip ödeme bağlanabiliyordu). Artık sahiplik `resident_units` üzerinden
  doğrulanıyor, satırlar `FOR UPDATE` ile kilitleniyor, `deleted = 0` filtresi uygulanıyor,
  `payment_assessments.amount` ve `payments.unit_id` yazılıyor.
  Sahte `https://checkout.siteeksen.com/...` adresi kaldırıldı; yanıta `payment_gateway_ready: false`
  eklendi (ödeme sağlayıcısı yok — `questions.md` S-06).
- **Ham veritabanı hatalarının istemciye sızması engellendi** (ödeme ucu): sentinel hatalar uygun
  HTTP kodlarına eşlendi, beklenmeyen hatalar sunucuda loglanıp genel mesajla döndürülüyor.

#### Düzeltildi — dürüstlük (FAZ 0, admin panel)
Aşağıdakilerin tamamı `npm run build` → **çıkış kodu 0** ile doğrulandı (21 sayfa).
- **Giriş şifresi artık log'a yazılmıyor.** `console.log(credentials)` KVKK ihlaliydi; yerine
  yalnızca maskelenmiş telefon ve HTTP durumu loglanıyor.
- **Sessiz mock fallback'ler kaldırıldı** (expenses, personnel, parking, reservations, visitors,
  accounting, notifications, credentials). Sunucu hatasında uydurma veri gösterilmiyor; hata
  görünür ve "Yeniden dene" ile tekrarlanabilir. Mali özet kartları hata durumunda `—` gösteriyor
  (önceden ₺45.750 gibi gerçek olmayan rakamlar görünüyordu).
- **Sahte başarı mesajları kaldırıldı:** `settings` hiçbir şey kaydetmeden "Kaydedildi" diyordu;
  `notifications` `catch {}` ile gönderilmemiş bildirimi gönderilmiş gösteriyordu (ayrıca geçmiş
  listesi "124 kişiye gönderildi" gibi sahte kayıtlarla doluydu); `reports` hiçbir şey göndermeden
  "e-posta gönderildi" diyordu; `accounting`'de sunucuda karşılığı olmayan toplu "hızlı işlem" onayı vardı.
- **Uydurma şifre gösterimi kaldırıldı.** `credentials` sayfası hata alınca `"demo-sifre-2026"`
  gösteriyordu; backend'de şifre çözen bir uç nokta hiç yok. Özellik dürüstçe devre dışı bırakıldı
  ve nedeni ekranda açıklanıyor; erişim kaydının yalnızca yerel olduğu belirtiliyor.
- **Sahte soft-delete düzeltildi.** Gerçek silme ucu olanlar API'ye bağlandı; olmayanlar sahte başarı
  yerine dürüst hata veriyor (önceden `deleted:1` yalnızca React state'ine yazılıyor, sayfa
  yenilenince kayıt geri geliyordu).
- **Mock servise bağlı sayfalara `NotImplementedNotice` eklendi** — kullanıcı verinin kalıcı
  olmadığını artık biliyor.
- **Header düzeltildi:** hardcoded "Ahmet Yılmaz / Yönetim Kurulu Başkanı" yerine gerçek oturum
  bilgisi; çalışmayan arama kutusu ve sahte bildirim rozeti kaldırıldı; **çıkış düğmesi eklendi.**

#### Not
- Mobil uygulamalardaki FAZ 0 maddeleri (sahte ödeme ekranı, sahte başarı mesajları, erişilemeyen
  route'lar) **henüz yapılmadı**; Flutter kurulu olmadığı için doğrulanamıyor (`questions.md` S-01b).
- 22 mock servisin `501` dönmesi (0.B.1) sıradaki iş.

---

### 2026-09-09 — Denetim, gerçeklik tespiti ve yeniden planlama

Bu tur **kaynak kodda hiçbir değişiklik yapmadı**; yalnızca gerçek durumu tespit etti ve planlama
dosyalarını yazdı. Amaç: "yapıldı denilen işlerin yapılmamış olması" sorununu ölçmek ve kalıcı olarak çözmek.

#### Eklendi
- **`tasks/audit-raporu.md`** — 78 doküman iddiasının kod kanıtına karşı denetimi.
  **Sonuç: iddiaların %49'u YANLIŞ, %28'i kısmen doğru, %23'ü doğru.**
  **Kanıt:** `tasks/audit/` altındaki 5 ayrıntılı rapor (~370 KB), her bulgu `dosya:satır` referanslı.
- **`tasks/audit/`** — 5 kanıt dosyası: backend servisleri (25 servis), veri katmanı/altyapı,
  admin panel (16 sayfa), sakin mobil (13 ekran), yönetici mobil (24 ekran).
- **`tasks/modul-envanteri.md`** — Olması gereken **60 modüllük referans model**; 634 sayılı KMK ve
  ikincil mevzuat dayanaklı, `yorum_analizleri.txt`'ten çıkan 20 somut rakip-boşluğu etiketlenmiş (APS-1…APS-20),
  her modülde "sık atlanan tamamlayıcılar" bölümü.
- **`tasks/gap-analizi.md`** — Modül durum matrisi (60 modül × bugünkü kapsam), **97 numaralı mantık
  hatası** (B01-B97, öncelikli), ve mevcut 12 özellik alanı için "düşünülmemiş tamamlayıcılar" listesi.
- **`tasks/dogrulama-politikasi.md`** — Kanıt seviyeleri (D0-D4), "Bitti" tanımı kontrol listesi,
  **sessiz başarısızlık yasağı**, tek doğruluk kaynağı kuralları. `✅` işareti kullanımdan kaldırıldı.
- **`tasks/questions.md`** — Kullanıcı kararı bekleyen 18 konu (S-01…S-18), her biri için
  "cevap gelmezse uygulanacak varsayılan" ile.

#### Değişti
- **`tasks/roadmap.md`** — sıfırdan yeniden yazıldı. Kanıt seviyesi kolonu zorunlu; 9 faz
  (FAZ 0 dürüstlük → FAZ 8 ölçek); **dikey dilim** çalışma ilkesi; CLAUDE.md gereği
  **ustalık yol haritası** eklendi (PostgreSQL finansal modelleme, mimari, Go disiplini, Flutter üretim,
  çok kiracılılık, Türkiye mevzuat derinliği, ürün stratejisi).
- **`tasks/todo.md`** — sıfırdan yeniden yazıldı. Eski "otonom oturum" talimatı geçersiz ilan edildi.
  FAZ 0 (dürüstlük onarımı) uygulanabilir maddelere bölündü.
- **`tasks/lessons.md`** — 6 yeni ders eklendi (kanıtsız tamamlandı işaretlemek; hata yutmak;
  sahte başarı göstermek; genişlik/derinlik; "bende çalışıyor" ≠ kurulabilir; doküman çelişkisi;
  yazılmış ama hiç çalıştırılmamış kod).

#### Tespit edilen kritik durumlar (henüz düzeltilmedi — FAZ 0/1/2'de ele alınacak)
- **Veritabanı temiz makinede kurulamıyor:** `004` ve `005` migration'ları `001` ile çakışıp hata veriyor;
  `005` sonrası **29 tablo hiç oluşmuyor**. **Kanıt:** `004:5,19-30` ⟷ `001:130`; `005:65,102` ⟷ `001:303`
- **Denetim izi (audit log) hiç çalışmıyor:** kolon adları şemayla uyuşmuyor, hata yutuluyor, tablo boş.
  **Kanıt:** `pkg/audit/audit.go:28` ⟷ `003:63-76`; `pkg/middleware/auth.go:115`
- **25 servisin yalnızca 3'ü veritabanına bağlı** (identity, finance, community); 22'si sabit JSON
  döndürüyor ve yazma işlemlerine `2xx` dönüp hiçbir yere kaydetmiyor.
- **`go build ./...` başarısız:** kırık import. **Kanıt:** `backend/api/handlers/api_credentials_handler.go:8`
- **Kimlik doğrulama yok:** gateway'de auth middleware yok, Kong'da JWT plugin'i 0 → maaş, TCKN, IBAN ve
  **API anahtarları** token'sız erişilebilir. **Kanıt:** `cmd/gateway/main.go:422`, `kong/kong.yml`
- **Tenant izolasyonu kırılabilir:** `POST /users/me/active-property` sahiplik doğrulamıyor; roller global.
  **Kanıt:** `identity/repository/user.go:87-91`
- **Bakiye hesabı hatalı:** kartezyen join nedeniyle bakiye kullanıcı sayısıyla çarpılıyor
  (1.200 TL → 187.200 TL). **Kanıt:** `finance/repository/finance.go:35-43`
- **Ödeme hiçbir zaman tamamlanmıyor:** `paid_amount` hiç güncellenmiyor → ödeyen sakin sonsuza dek borçlu.
  **Kanıt:** `finance/repository/finance.go:206-224`
- **Sıfırdan kurulumda demo giriş çalışmıyor:** seed bcrypt hash'i hiçbir şifreyle eşleşmiyor
  (**fiilen test edildi**, `bcryptjs` ile 10 aday şifre denendi), iki kullanıcıda aynı hash.
  **Kanıt:** `002_seed_data.sql:29,32`
- **Sakin mobil release APK'da INTERNET izni yok** → release build'de hiçbir API çağrısı çalışmaz;
  `ios/` klasörü yok; push bildirim hiç yok; biyometrik `FlutterActivity` nedeniyle çalışmıyor.
- **Yönetici mobil taban adresi yanlış** (`/v1` ≠ `/api/v1`) → üretimde her çağrı 404; router'da auth guard yok.
- **30'dan fazla noktada sahte başarı mesajı** (mobil ödeme ekranı hiç ağ çağrısı yapmadan
  "Ödeme Başarılı!" gösteriyor).

#### Doğrulama notu
- **Fiilen çalıştırılarak doğrulanan:** admin panel derlemesi (`npm install` + `npm run build` →
  21 sayfa, çıkış kodu 0); demo bcrypt hash uyuşmazlığı.
- **Doğrulanamayan:** Go/Flutter/Docker bu makinede kurulu değil; kurumsal AppLocker politikası kullanıcı
  yazılabilir dizinlerden çalıştırılabilir dosya açılmasını engelliyor (portable Go denemesi başarısız).
  Bu nedenle backend ve mobil bulgular **statik** analizle tespit edildi. Bkz. `questions.md` S-01.

---

## [Unreleased — 2026-09-09 öncesi]

### Eklendi
- **Ustalık Mobil Entegrasyon Yol Haritası (Faz 2 & Faz 3 - Yönetici Uygulaması):**
  - **admin_app (Temel & Finansal/İleri Düzey Servisler):** `admin_app/lib/core/network/api_client.dart` içerisine otopark, personel, ziyaretçi, kargo, banka ve rezervasyon API uç noktaları için gerekli tüm metodik integrasyonlar eklendi.
  - **admin_app (Ekran Bağlantıları):** Otopark yönetimi, personel/izin takipleri, ziyaretçi kayıtları, kargo paket takibi, banka hesap/havale entegrasyonu ve tesis rezervasyonları ekranları statik verilerden tamamen arındırılarak gerçek dinamik backend mikroservislerine bağlandı.
- **Ustalık Mobil Entegrasyon Yol Haritası (Faz 1 - Sakin Uygulaması):**
  - **mobile (Sakin Uygulaması Entegrasyonu):** `api_client.dart` içerisine eksik `/reservations`, `/facilities`, `/announcements`, `/surveys`, `/packages`, `/visitors` ve `/bulletins` metotları eklenerek gerçek backend entegrasyonu sağlandı.
  - **mobile (Rezervasyon, Anket, Duyuru, Kargo ve İlan Panosu):** İlgili tüm ekranlar local mock verilerden temizlenerek `apiClient` üzerinden gerçek zamanlı dinamik veritabanı uç noktalarına bağlandı. `flutter analyze` ile 0 derleme hatasıyla derlendiği doğrulandı.
- **Ustalık Entegrasyon Yol Haritası (Faz 1 - 5 Entegrasyonları):**
  - **Faz 1 (Gateway Rota Düzeltmeleri):** 9 mikroservisin (otopark, personel, rezervasyon, kargo, devriye, anket, akıllı tahsilat, envanter, demirbaş) ön yüzden çağrılan ve 404 hatası veren tüm alt API rotaları için proxy yönlendirmeleri eklendi. `/api/v1/units/` altındaki kargo paket isteklerini kargo servisine yönlendiren custom handler yazıldı.
  - **Faz 2 (Banka Entegrasyon Servisi):** `banking-service` containerize edilerek `8106` portunda `docker-compose`'a ve gateway proxy'sine eklendi. Çakışan Go paketi derleme hatası, dosya `provider` alt paketine taşınarak giderildi.
  - **Faz 3 (Dashboard Genel İstatistikleri Aggregator):** Mock stats handler'ı güncellenerek; identity, community, visitor ve meeting mikroservislerinden gerçek zamanlı veri toplayan (Aggregator) dinamik bir yapıya dönüştürüldü. `/dashboard/recent-payments` ve `/dashboard/recent-requests` rotaları aggregator olarak bağlandı.
  - **Faz 4 (Sayaç Yönetimi Servis Katmanı):** Mock sayaç handler'ları kaldırıldı; `/api/v1/meters` ve `/api/v1/meters/` rotaları doğrudan gerçek `iot-service` mikroservis katmanına ve veritabanına bağlandı.
  - **Faz 5 (Raporlama Servis Katmanı):** `fpdf` Cell derleme hataları (`CellFormat` dönüşümü) giderildi ve gateway `Dockerfile` kopyalama hatası (`COPY . .`) düzeltildi. Mock pdf handler'ları kaldırıldı; `/api/v1/reports/generate` ve `/download` rotaları gerçek `pkg/reports` kütüphanesini in-memory registry ile kullanarak gerçek zamanlı PDF ve Excel üretir hale getirildi.
- **finance-service: `GET /finance/assessments/overview` — site genelinde dönem bazlı tahakkuk/tahsilat özeti (Mock→DB Faz 2, Adım 4 ön-hazırlık)** — Admin panel "Aidat Yönetimi" sayfasının "Tahakkuk Geçmişi" tablosu, mevcut `GET /finance/assessments`'ın sakin-bazlı (kendi tahakkukları) olması nedeniyle beslenemiyordu; yönetim rollerine açık yeni uç nokta `monthly_assessments`'ı döneme göre gruplayıp toplam tahakkuk/tahsilat/oran/durum döndürüyor (`repository.ListAssessmentPeriods`, `service.ListAssessmentOverview`, `handlers.GetAssessmentOverview`). Mevcut `GET /finance/assessments/:id` route'uyla çakışmadığı doğrulandı (Gin static-önce eşleştirme). Canlı doğrulandı. `go build`+`go vet` temiz.
- **finance-service: `GET /finance/debtors` ve yönetim görünümlü `GET /finance/payments` (Mock→DB Faz 2, Adım 3)** — Yönetim rollerine (`MANAGER`/`AUDITOR`/`STAFF`) açık, sitedeki borçlu sakinleri (`monthly_assessments.total_amount > paid_amount`, mülk sahibi/`OWNER`, borç tutarına göre azalan sıralı) listeleyen `GET /finance/debtors` eklendi (`repository.ListDebtors`, `service.ListDebtors`, `handlers.GetDebtors` — admin_app `_DebtorCard` ve ileride accounting sayfası için). Ayrıca `GET /finance/payments` rol-duyarlı hale getirildi: yönetim rolleri artık site genelindeki tüm ödemeleri sakin adı+birim bilgisiyle görür (`repository.ListPropertyPayments`, admin_app `_PaymentCard` için), sıradan sakinler değişmeden yalnızca kendi ödeme geçmişini görür (`service.GetPaymentHistory` artık `roles`/`propertyID` parametreleriyle dallanıyor). Canlı doğrulandı: yönetici (`5551234567`) gerçek borçlu listesini görüyor, sakin (`5559876543`) `/debtors`'ta 403 alıyor ve `/payments`'ta yalnızca kendi (boş) geçmişini görüyor. `go build`+`go vet` temiz.
- **finance-service: `GET /finance/expense-categories` (Mock→DB Faz 2, Adım 2)** — Aidat tahakkuku formunun gider kalemi seçimi için yönetim rollerine (`MANAGER`/`AUDITOR`/`STAFF`) açık, sitenin aktif `expense_categories` kayıtlarını `sort_order`/`name`'e göre listeleyen uç nokta eklendi (`repository.ListExpenseCategories`, `service.ListExpenseCategories`, `handlers.GetExpenseCategories`). `go build`+`go vet` temiz.
- **finance-service: `POST /finance/assessments` — gerçek aidat tahakkuku oluşturma (Mock→DB Faz 2, Adım 1)** — Yönetimin (`MANAGER`/`AUDITOR`/`STAFF`) gider kalemlerini girip dönemlik aidat tahakkuku başlatabildiği uç nokta eklendi. `repository.CreateAssessment`, sitedeki tüm aktif birimleri (`share_ratio`/`gross_area_m2`/`is_commercial`/`is_ground_floor`) çekip her gider kalemini kategorinin `distribution_type`'ına göre uygun birimlere paylaştırıyor (`SHARE_RATIO`→arsa payı oranı, `EQUAL`→eşit bölüşüm, `AREA_M2`→metrekare oranı; henüz desteklenmeyen `METER_READING`/`CUSTOM` arsa payına düşüyor — sayaç bazlı dağıtım Faz 4 kapsamında ele alınacak), `applies_to_commercial`/`applies_to_ground_floor` filtrelerini uyguluyor, ardından her birim için tek `monthly_assessments` kaydı + ilgili `assessment_details` satırlarını tek transaction'da yazıyor (aynı dönem için ikinci kez tahakkuk denenirse `(unit_id, period_year, period_month)` unique kısıtından `ErrAssessmentPeriodExists` ile 409 dönüyor). `service.isFinanceManagement` rol kontrolü, `handlers.mapAssessmentError` (`errors.Is` tabanlı) eklendi; route `AuthMiddleware()`+`AuditLog(pool, "finance")` altında. `go build`+`go vet` temiz.
- **admin_app: Sakinler ekranları gerçek API'ye bağlandı + konvansiyon birleştirme (Mock→DB Faz 1, Adım 4/4 — Faz 1 tamamlandı)** — `api_client.dart`'taki `getResidents`/`getResident`/`createResident`/`updateResident` artık admin panelle aynı `/residents` (+ `/units`) konvansiyonunu kullanıyor (önceden `/users?role=RESIDENT` + `/units` karışık kontratına sahipti — admin panel `/residents` bekliyordu, bu da admin_app'in identity-service ile hiç konuşamamasına yol açıyordu; `updateResident` artık `PATCH` kullanıyor). `residents_screen.dart`'taki tamamen sahte `_residents` listesi kaldırıldı; ekran artık `apiClient.getResidents(search, role)` ile yükleniyor (loading/refresh/boş-durum + role göre filtre sheet'i — arama gerçek backend'e gidiyor). `add_resident_screen.dart`, `apiClient.getUnits()`'ten gerçek birim listesini çekip `apiClient.createResident()` ile gerçek kayıt oluşturuyor (backend'in desteklemediği TC/taşınma tarihi/not alanları kaldırıldı, "Ad Soyad" tek alanı "Ad"/"Soyad" olarak ikiye ayrıldı — `CreateResidentInput` kontratıyla birebir). `resident_detail_screen.dart`, `apiClient.getResident()` ile gerçek profil/iletişim bilgisini gösteriyor; sahte "Finansal Durum"/"Aidat Geçmişi" bölümleri (finance-service entegrasyonu Faz 2 kapsamında) kaldırıldı, "Sakini Kaldır" aksiyonu `apiClient.updateResident(id, {is_active: false})` ile gerçek pasifleştirme/aktifleştirme yapıyor. `flutter analyze` temiz (yalnızca kod tabanı genelinde var olan `withOpacity`/`value:` deprecation info'ları).
- **Admin panel: Sakinler sayfası gerçek API'ye bağlandı (Mock→DB Faz 1, Adım 3)** — `residents/page.tsx`'teki `mockResidents`/in-memory CRUD kaldırıldı; sayfa artık `apiClient.getResidents()`+`apiClient.getUnits()` ile yükleniyor (loading spinner eklendi), `apiClient.createResident()`/`apiClient.updateResident()` ile gerçek backend'e yazıyor. `Resident`/`Unit` arayüzleri backend `models.Resident`/`models.Unit` ile birebir eşleşecek şekilde yeniden yazıldı (`first_name`/`last_name`/`unit_id`/`is_active` vb., `id: string` UUID). Rol seçimi artık DB değerleriyle (`OWNER`/`TENANT`/`PROXY`) çalışıyor, ekranda Türkçe etiketlere (`ROLE_LABELS`) çevriliyor. "Sil" aksiyonu, backend'de henüz `DELETE /residents/:id` olmadığı için `PATCH /residents/:id { is_active: false }` ile birim ilişkisini pasifleştiriyor ("Pasifleştir" olarak yeniden adlandırıldı — geri alınabilir). Backend henüz finance-service'e bağlı olmadığından sahte göstermemek için **`Bakiye` sütunu kaldırıldı**. CSV yükleme artık her satır için gerçek `apiClient.createResident()` çağrısı yapıyor (mock satır eklemiyor); örnek CSV `unit_id` (UUID) bekleyecek şekilde güncellendi. `api-client.ts`'e `getUnits()` eklendi, `updateResident()` imzası backend'in gerçek `UpdateResidentInput{role, is_active}` kontratıyla eşleşecek şekilde düzeltildi (önceden `first_name`/`phone` gibi backend'in desteklemediği alanları kabul ediyordu).
- **Gateway: `/api/v1/residents` ve `/api/v1/units` artık identity-service'e proxy ediliyor (Mock→DB Faz 1, Adım 2)** — `cmd/gateway/main.go`'daki sahte JSON döndüren `mux.Handle("/api/v1/residents", ...)`/`"/api/v1/residents/"` mock handler'ları kaldırıldı; bu path'ler `proxyPaths(mux, newProxy(identityURL), ...)` ile gerçek identity-service'teki yeni `residents`/`units` endpoint'lerine yönlendiriliyor (bkz. Adım 1).
- **identity-service: Gerçek `residents`/`units` modülü (Mock→DB Faz 1, Adım 1)** — Önceden gateway'in kendi içinde sabit JSON döndürdüğü `/api/v1/residents*`, artık identity-service'teki gerçek `resident_units`/`users`/`units` JOIN sorgularına dayanıyor. Yeni `models/resident.go` (`Resident`, `CreateResidentInput`, `UpdateResidentInput`), `repository/resident.go` (`List`/`GetByID`/`Create`/`Update`/`ListUnits` — `Create` tek transaction içinde telefon numarasıyla mevcut kullanıcıyı birime bağlıyor ya da `crypto/rand` ile üretilip `bcrypt.GenerateFromPassword` ile hash'lenen geçici şifreyle yeni kullanıcı açıyor), `service/resident.go` (`isResidentManagement` rol kontrolü — yalnızca `MANAGER`/`AUDITOR`/`STAFF`), `handlers/resident.go` (`errors.Is` tabanlı hata eşleme: `ErrResidentForbidden`/`ErrResidentNotFound`/`ErrUnitNotFound`/`ErrPhoneAlreadyExists`) eklendi; `main.go`'da `GET/POST /api/v1/residents`, `GET/PATCH /api/v1/residents/:id`, `GET /api/v1/units` route'ları `AuthMiddleware()` (+ `AuditLog(pool, "resident")`) altında kayıtlı. (Mock verilerin DB'ye bağlanması — Faz 1/6, Adım 1/4: identity-service backend; sıradaki adımlar gateway proxy düzeltmesi ve frontend bağlama)
- **Talep onay mekanizması** — Migration `010_request_confirmation.sql` ile `requests` tablosuna `user_confirmed_at TIMESTAMP NULL` eklendi. `community-service` (önceden tamamen mock) finance-service pattern'iyle gerçek DB bağlantısına kavuştu; yeni `requests` modülü (`models`/`repository`/`service`/`handlers`) ile `GET/POST /requests`, `PATCH /requests/:id/status`, `POST /requests/:id/confirm-resolution` uç noktaları eklendi (`AuthMiddleware()` + `AuditLog(pool, "request")` altında). Durum geçişleri `allowedStatusTransitions` ile kısıtlandı: yönetici sadece OPEN→IN_PROGRESS→RESOLVED geçişini yapabiliyor, `CLOSED`'a yalnızca sakinin onayı (`ConfirmResolution`) ile ulaşılıyor — onaylarsa `CLOSED` + `user_confirmed_at` set ediliyor, reddederse talep `IN_PROGRESS`'e geri dönüp `resolved_at` temizleniyor. `mobile`'da `requests_screen.dart`'a sakin için "Sorunum çözüldü ✓ / Devam ediyor ✗" aksiyonları eklendi (`apiClient.confirmRequestResolution`). `admin_app`'te `request_detail_screen.dart`'a yönetici `RESOLVED` seçtiğinde "Sakin onayı bekleniyor, otomatik kapanacak" notu eklendi ve `Güncelle` butonu gerçek `apiClient.updateRequestStatus()` çağrısına bağlandı (`CLOSED` zaten doğrudan seçilebilir bir seçenek değildi). Admin panelde `requests/page.tsx`'e `RESOLVED` için "Onay bekliyor", `CLOSED` + `user_confirmed_at` için "Sakin onayladı: (tarih)" rozetleri eklendi; manuel durum değiştirme menüsünden `CLOSED` seçeneği kaldırıldı. (Apsiyon karşılaştırması: yorum_analizleri.txt — "yönetici talebi tek taraflı kapatıyor, sakine onay sorulmuyor" şikayetine karşılık, Paket 1/5 — son paket)
- **KVKK açık rıza akışı + audit log** — Migration `009_kvkk_consent.sql` ile `users` tablosuna `kvkk_consent_at TIMESTAMP NULL` eklendi. identity-service `Login`/`GetCurrentUser` yanıtlarına `kvkk_consent_required` (consent_at NULL ise `true`) eklendi; yeni `POST /users/me/kvkk-consent` endpoint'i onay zamanını işaretliyor. `mobile` ve `admin_app`'e geçilemez (`PopScope(canPop: false)`) zorunlu KVKK aydınlatma + açık rıza ekranı eklendi — giriş sonrası `kvkk_consent_required=true` ise kullanıcı onaylamadan ana ekrana geçemiyor. Ayrıca `pkg/audit/` paketi (`LogAction`) yazıldı; `pkg/middleware/auth.go`'daki TODO durumundaki `AuditLog()` middleware'i gerçek `INSERT INTO audit_logs` ile tamamlandı (HTTP method → `action`: GET→VIEW, POST→CREATE, PUT/PATCH→UPDATE, DELETE→DELETE) ve hassas route gruplarına (`identity /users`, `finance /finance`) bağlandı. (KVKK belgesi vardı ama mandatory consent flow yoktu, `audit_logs` tablosu boştu — Paket 5/5)
- **Gerçek biyometrik giriş** — `mobile`'da `api_client.dart` bellek-içi token tutmaktan `flutter_secure_storage` tabanlı kalıcı oturuma geçirildi (`_persistTokens`, `_tryRefreshToken`, 401'de otomatik yenileme interceptor'ı, `hasStoredSession`/`isBiometricEnabled`/`setBiometricEnabled`/`loginWithStoredSession`). `login_screen.dart`'taki tamamen mock `_handleLogin()` gerçek `apiClient.login()` çağrısına bağlandı (daha önce `Future.delayed` ile sahte gecikme atıp hiçbir yere yönlendirmiyordu); ilk başarılı girişte "Biyometrik girişi etkinleştir?" diyaloğu gösteriliyor, placeholder parmak izi butonu artık `local_auth.authenticate()` + kayıtlı refresh token ile oturum yenileme akışına bağlı. `admin_app`'e de aynı akış eklendi: `pubspec.yaml`'a `local_auth` bağımlılığı, `api_client.dart`'a `hasStoredSession`/`isBiometricEnabled`/`setBiometricEnabled`/`loginWithStoredSession`, `login_screen.dart`'a biyometrik buton + etkinleştirme diyaloğu. (Apsiyon karşılaştırması: `local_auth` kuruluydu ama her iki app'te de kullanılmıyordu, Paket 4/5)
- **Rol bazlı menü filtreleme (RBAC)** — `pkg/middleware/auth.go`'ya yönetim-tarafı rol sabitleri eklendi (`MANAGER`/`AUDITOR`/`STAFF`, mevcut `RESIDENT`/`OWNER`/`TENANT` ile birlikte); `RequireRole()` middleware'i (önceden hiçbir route'a bağlı değildi) `POST /users/me/properties` (yeni site oluşturma) endpoint'ine `RequireRole(MANAGER, OWNER)` olarak uygulandı. `admin_app`'e JWT `roles` claim'ini decode eden `getCurrentUserRoles()` eklendi (`core/network/api_client.dart`); ana ekran menüsü ve drawer artık role göre filtreleniyor — `AUDITOR`/`STAFF` rolündeki kullanıcılar "Sakinler", "Finans", "Raporlar" öğelerini görmüyor. Migration `008_manager_roles.sql` ile demo yönetici hesabına (`+905551234567`) `MANAGER` rolü eklendi (idempotent). (Apsiyon karşılaştırması: yorum_analizleri.txt — "roller manager/auditor/assistant doğru yönetilmiyor" şikayetine karşılık, Paket 3/5)
- **Android geri tuşu navigasyon düzeltmesi** — `mobile` ve `admin_app` ana ekranlarına (`main_screen.dart`) `PopScope` eklendi: alt sekme kökte değilken geri tuşu Dashboard/Ana Sayfa sekmesine döner, kök sekmedeyken "Uygulamadan çıkmak istediğinize emin misiniz?" onay diyaloğu gösterilir ve onaylanırsa `SystemNavigator.pop()` ile çıkılır. (Apsiyon yorumlarındaki "geri tuşu uygulamayı direkt kapatıyor" şikayetine karşılık geliştirildi — `yorum_analizleri.txt` karşılaştırması, Paket 2/5)
- **Yeni site ekleme özelliği** — Sidebar'daki "+ Yeni Site Ekle" butonu artık çalışıyor: `POST /users/me/properties` endpoint'i (identity servisi) tek transaction içinde `properties` + varsayılan `unit` ("A-YÖNETİM") + `resident_units` (`OWNER`) satırlarını oluşturuyor — böylece yeni site mevcut `GetUserProperties` join zincirinde anında görünüyor. Frontend'de modal form (Site Adı, Adres, Şehir, İlçe) → oluşturma → otomatik aktif site seçimi → token yenileme → sayfa yenileme zinciri canlı ortamda uçtan uca doğrulandı.
- **Property türü (`type`) — şema değişikliği** — `properties` tablosuna `type VARCHAR(20) NOT NULL DEFAULT 'SITE'` kolonu eklendi (migration `007_property_type.sql`, idempotent). `SITE`/`APARTMENT`/`BUILDING` değerleri destekleniyor; geçersiz/boş değer servis katmanında `SITE`'a normalize ediliyor. Sidebar'daki modal "Yeni Taşınmaz Ekle" olarak güncellendi, "Tür" seçici (Site/Apartman/Bina) eklendi. Canlı ortamda üç senaryo (geçerli tür, eksik tür, geçersiz tür) uçtan uca test edildi.

### Düzeltildi
- **Sidebar: Site/apartman seçici gerçek backend kontratına bağlandı** — `<select>` hiçbir state'e bağlı değildi, seçim panele yansımıyordu. İlk denemede eklenen `X-Tenant-ID` header yaklaşımı, backend'de o middleware hiç bağlı olmadığı için geri alındı; bunun yerine identity serviste hazır olan gerçek mekanizmaya bağlandı: `GET /users/me/properties` (gerçek site listesi) → seçimde `POST /users/me/active-property` (DB güncelleme) → `/auth/refresh` (yeni `property_id` claim'li JWT) → sayfa yenileme. Zincir canlı ortamda uçtan uca test edildi.
- **NextAuth ↔ apiClient token köprüsü eklendi** — `session.accessToken`/`refreshToken` daha önce hiçbir yerde kullanılmıyordu; `apiClient`'in `localStorage`'ındaki token hep boştu, gerçek backend çağrıları sessizce 401 alıp mock'a düşüyordu. Artık `Sidebar` `useSession()` ile token'ları `apiClient.setToken()`'a köprülüyor.
- **Migration 006 (soft-delete) DB'ye uygulandı** — dosya önceki oturumda yazılmış ama hiç çalıştırılmamıştı; `users` tablosunda `deleted` kolonu yoktu ve bu yüzden TÜM giriş istekleri "Geçersiz telefon veya şifre" hatasıyla başarısız oluyordu. Migration idempotent (`IF NOT EXISTS`) olduğu için güvenle uygulandı.
- **Migration 008/009/010 DB'ye uygulandı (Faz 1 canlı testi sırasında bulundu)** — Aynı kök neden tekrarlandı: `docker-entrypoint-initdb.d` yalnızca postgres volume'u ilk kez oluşturulurken çalışıyor; bu üç migration dosyası volume zaten doluyken eklendiği için hiç çalıştırılmamıştı. Sonuç: `kvkk_consent_at` kolonu olmadığından `GetByPhone` SQL hatası alıp tüm girişler "kullanıcı bulunamadı"ya düşüyordu (008/009), ve hiçbir kullanıcıda `MANAGER` rolü yoktu — demo yönetici hesabı bile sadece `{RESIDENT,OWNER}` idi, bu da gerçek `/residents` endpoint'inin "yetkisiz" dönmesine yol açıyordu. Üç migration'ın içeriği (`ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, idempotent `UPDATE ... array_append`) çalışan postgres container'ına elle uygulandı; demo yönetici artık `{RESIDENT,OWNER,MANAGER}`. **Not**: Bu, aynı sorunun üçüncü tekrarı — kalıcı çözüm için bir migration-runner mekanizması (örn. `golang-migrate` ya da servis başlangıcında "uygulanmamış migration var mı" kontrolü) eklenmeli (Faz 6 / altyapı kuyruğuna eklendi).
- **Demo kullanıcı şifre hash'i düzeltildi** — DB'deki hash dokümante edilen `demo123` ile eşleşmiyordu; bilinen değere sıfırlandı.

### Düzeltildi (Input/Form Denetimi)
- **Settings: Genel Ayarlar formu** — inputlar `defaultValue`'dan controlled state'e çevrildi, "Değişiklikleri Kaydet" butonu artık çalışıyor ve onay gösteriyor
- **Settings: Bildirim Ayarları** — checkbox'lar `defaultChecked`'tan state'e bağlandı, anında kaydediliyor
- **Settings: Yönetici Kullanıcılar** — işlevsiz "⋮" menü kaldırıldı, edit/delete (soft-delete) eklendi
- **Reports: PDF/Excel/E-posta butonları** — onClick'siz üç buton işlevsel hale getirildi (CSV indirme + e-posta onay mesajı)
- **Meters: "Okuma Dönemi" select** — state'siz kalmıştı, controlled hale getirildi
- **Credentials: writeLog** — audit log ile ilgisiz `apiClient.createExpense` kontrolü temizlendi

### Eklendi
- **Admin panel: Tüm sayfalara edit/delete/CSV** — Accounting (gelir/gider), expenses, parking (araç), personnel (personel+izin reddet), reservations, visitors, notifications (history delete), meters (gerçek CSV upload/download, sayaç ekle/düzenle/sil), assessments (tahakkuk düzenle/sil), announcements, requests, residents — tüm silmeler soft-delete (deleted=1)
- **Soft-delete pattern** — Tüm arayüz bileşenlerinde `deleted: number` alanı, display `deleted === 0` filtreliyor, silme `deleted = 1` set ediyor, gerçek kayıt tutulmuyor
- **CSV upload/download** — residents, expenses, parking, personnel, visitors, meters, assessments, announcements, requests sayfalarında örnek CSV indirme (Blob + URL.createObjectURL) ve FileReader tabanlı CSV parse/yükleme
- **Settings: Kullanıcı edit/delete** — Yönetici Kullanıcılar listesine düzenleme ve soft-delete eklendi
- **Backend soft-delete migration (006)** — 23 tabloya `deleted INTEGER NOT NULL DEFAULT 0` eklendi + index'ler; identity ve finance repository sorgularına `AND deleted = 0` filtresi eklendi

### Önceki Eklendi
- **Admin panel: Gider Yönetimi sayfası** — `/dashboard/expenses`; kategori bazlı gider listesi, fatura durumu, onay filtresi, gider ekleme modalı, mock fallback
- **Admin panel: Otopark sayfası** — `/dashboard/parking`; şu an içerideki araçlar + kayıtlı araç listesi, giriş/çıkış işlemleri, plaka arama, araç ekleme
- **Admin panel: Personel sayfası** — `/dashboard/personnel`; çalışan listesi (maaş gizleme/gösterme), izin talepleri, izin onayla/reddet, personel ekleme
- **Admin panel: Rezervasyon sayfası** — `/dashboard/reservations`; tesis listesi + rezervasyon tablosu, iptal işlemi, yeni rezervasyon ekleme
- **Admin panel: Ziyaretçi sayfası** — `/dashboard/visitors`; bugün/içeride/tümü sekmesi, giriş-çıkış kaydı, durum göstergesi, ziyaretçi kayıt formu
- **Sidebar: 5 yeni nav öğesi** — Gider Yönetimi, Otopark, Personel, Rezervasyon, Ziyaretçi
- **api-client.ts: Parking, Personnel, Reservations, Visitors API metodları** — tüm CRUD ve giriş/çıkış endpointleri
- **Admin panel: Muhasebe sayfası backend bağlantısı** — Giderler `/api/v1/expenses` servisinden yükleniyor; yeni gider oluşturma API'ye gönderiliyor
- **Admin panel: Bildirimler sayfası backend bağlantısı** — Geçmiş `/api/v1/notifications/history`'den yükleniyor; gönderme `/api/v1/notifications/send`'e proxy ediliyor
- **Admin panel: Kimlik Bilgileri sayfası backend bağlantısı** — Settings servisinden API kimlik bilgileri yükleniyor ve mock verilerle birleştiriliyor
- **api-client.ts** — Expenses, Notifications, Credentials API metodları eklendi
- **Gateway v1.2.0** — 24 servise proxy routing; tüm yeni servisler env'de tanımlı; `proxyPaths()` yardımcı fonksiyon
- **Kong güncellendi** — 24 mikroservis Kong üzerinden yönlendiriliyor, tüm servisler için CORS ve rate-limiting
- **19 yeni servis docker-compose'a eklendi** — expense(8086), asset(8087), bulletin(8089), contract(8090), document(8091), energy(8092), esg(8093), inventory(8094), meeting(8095), nps(8096), package(8097), parking(8098), patrol(8099), personnel(8100), reservation(8101), settings(8102), smart-collection(8103), survey(8104), visitor(8105)
- **Tüm servisler için Dockerfile oluşturuldu** — CGO_ENABLED=0 GOOS=linux, alpine:3.19, chmod +x

### Düzeltildi
- **nps, settings, esg, document servisleri "exec format error" düzeltildi** — Bu 4 servis `package main` değil library package olarak yazılmıştı; `package main` + `main()` + Gin HTTP server eklendi
- **Settings servisi AES-256 şifreleme anahtarı düzeltildi** — Sabit 32 byte key varsayılan değer; `copy()` ile esnek uzunluk desteği
- **Gateway gerçek reverse proxy'ye dönüştürüldü** — auth/users → identity:8081, finance → finance:8082, announcements/surveys/bulletins/reservations → community:8083. Diğer endpointler (residents, meters, requests, dashboard) mock olarak gateway'de tutuldu.
- **docker-compose admin panel env düzeltildi** — `NEXT_PUBLIC_API_URL` ve `API_URL` `/api` → `/api/v1` güncellendi; servisler arası iletişim için gateway'e bağımlılıklar eklendi.
- **Identity service: telefon normalizasyonu** — `5551234567`, `05551234567`, `+905551234567` formatlarının tümü kabul ediliyor.
- **Identity repository: NULL scan hatası düzeltildi** — `tc_encrypted`, `tc_hash`, `email`, `active_property_id` alanları NULL olduğunda `COALESCE` ile boş string döndürülüyor.
- **Auth middleware: JWT claim uyumsuzluğu düzeltildi** — Token `"sub"` claim'ini kullanıyor ama middleware `"user_id"` okuyordu; `RegisteredClaims.Subject` fallback eklendi.
- **api-client.ts: token refresh implementasyonu** — 401 yanıtında refresh token ile otomatik yenileme; başarısız olursa login sayfasına yönlendirme.
- **Demo şifre hash güncellendi** — Seed data'daki bcrypt hash `Demo123!` şifresiyle eşleşecek şekilde DB'de güncellendi.

---

## [0.5.0] — 2026-02-03

### Eklendi
- **API Gateway servisi** (`backend/cmd/gateway/`) — Go ile yazılmış hafif dev gateway, port 8888
- **Admin panel: Raporlar sayfası** — daire bazlı aidat/tahsilat raporları, Excel/PDF çıktısı
- **Admin panel: Ayarlar sayfası** — site bilgileri, bildirim ve entegrasyon ayarları
- **Admin panel: Multi-tenant desteği** (`backend/migrations/003_multi_tenant.sql`)

### Değişti
- Tüm backend servisleri Go 1.24'e güncellendi
- Admin panel: Sakinler, Aidatlar, Duyurular sayfaları büyük ölçüde genişletildi
- `docker-compose.yml`'e gateway servisi eklendi

---

## [0.4.0] — 2026-02-01

### Eklendi
- **Belge yönetim servisi** (`backend/services/document/`) — belge yükleme, imzalama, arşivleme
- **Mobil: Belgeler ekranı** — sakin belgelerini listeleme ve görüntüleme
- **Mobil: Varlıklar ekranı** — site demirbaş ve varlık takibi
- **Admin app: Sözleşme yönetim ekranı** büyük güncelleme

---

## [0.3.0] — 2026-02-01

### Eklendi
- **Apple tarzı UI sistemi** — `mobile/lib/core/theme/apple_theme.dart` ve `apple_widgets.dart`
- **Admin app ekranları:** Varlık yönetimi, Banka entegrasyonu, Duyuru panosu, Akıllı tahsilat, Sözleşme, Toplantı sihirbazı, Koli takibi, Güvenlik turu, API ayarları, Anket yönetimi
- **Mobil ekranlar:** Ana sayfa, Duyurular, İlan panosu, Enerji tüketimi, Aidat ödeme, Koli takibi, Profil, İstek oluşturma, Rezervasyon, Anketler, Ziyaretçi ön kayıt
- **Backend entegrasyonları:** AI servisi (`pkg/integrations/ai/`), Banka (`bank/`), Push (`push/`), SMS, WhatsApp
- **Backend servisleri:** `banking`, `esg`, `nps`, `settings`
- **API Credentials yönetimi** — üçüncü taraf API anahtarlarının şifreli saklanması

---

## [0.2.1] — 2026-02-01

### Eklendi
- **Admin app ekranları:** Enerji panosu, Envanter yönetimi, Otopark yönetimi, Personel yönetimi, Rezervasyon yönetimi, Ziyaretçi yönetimi
- **Apple tarzı tema ve widget sistemi** — admin app için (`admin_app/lib/core/theme/apple_theme.dart`)

---

## [0.2.0] — 2026-02-01

### Eklendi
- **15 yeni backend servisi:** `asset`, `bulletin`, `contract`, `energy_analytics`, `inventory`, `meeting_wizard`, `package`, `parking`, `patrol`, `personnel`, `reservation`, `smart_collection`, `survey`, `visitor`
- **Veritabanı migration 005** — tüm yeni modüller için tablo şemaları

---

## [0.1.1] — 2026-02-01

### Eklendi
- **Gider ve fatura yönetimi** — kategori bazlı gider takibi (sabit/değişken/plansız)
- **AI fatura tarayıcı** — OpenAI Vision / Google Document AI entegrasyonu (`backend/pkg/ai/invoice_parser.go`)
- **Gider servisi** — `backend/services/expense/`, port 8086
- **Admin app gider ekranları:** Gider listesi, Gider ekleme (AI destekli), Gider detay
- **Mobil: Sakin gider görüntüleme** ekranı
- **Veritabanı migration 004** — gider yönetimi tabloları
- Giderin aidada yansıtılması ve faturasız gider onay mekanizması

---

## [0.1.0] — 2026-02-01

### Eklendi
- **Admin Flutter uygulaması** (`admin_app/`) — site yöneticisi mobil uygulaması
- 15 ekran: Login, Dashboard, Sakinler, Finans, Sayaçlar, Duyurular, Talepler, Raporlar
- Riverpod state management, GoRouter navigasyon, Dio API client

---

## [0.0.1] — 2026-02-01 — İlk Commit

### Eklendi
- **5 Go mikroservis:** Identity (8081), Finance (8082), Community (8083), IoT (8084), Notification (8085)
- **Next.js admin paneli** — sakinler, aidatlar, sayaçlar, talepler, duyurular ekranları
- **Flutter mobil uygulaması** (`mobile/`) — sakin uygulaması
- **Multi-tenant SaaS altyapısı** — `pkg/tenant/` middleware
- **Güvenlik:** JWT (15dk/7gün), AES-256-GCM şifreleme, KVKK audit log
- **iyzico ödeme entegrasyonu**
- **Firebase push notification**
- **Kong API Gateway** yapılandırması (`kong/kong.yml`)
- **Kubernetes deployment** manifest'leri (`k8s/`)
- **CI/CD pipeline** (`.github/workflows/ci-cd.yaml`)
- **Yasal belgeler:** KVKK, Gizlilik politikası, Kullanım koşulları
