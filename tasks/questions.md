# Sorular ve Karar Bekleyen Konular

Bu dosya, ilerlemek için **kullanıcı kararı** gereken veya **dışarıdan bilgi/erişim** bekleyen konuları toplar.

Kural: Her soru için bir **"Cevap gelmezse uygulanacak varsayılan"** yazılıdır. Böylece cevap beklenirken iş durmaz;
cevap geldiğinde varsayılan gözden geçirilir. Cevaplanan sorular `> **CEVAP (tarih):**` satırıyla işaretlenir.

Son güncelleme: 2026-09-13

---

## DURUM: 18 sorunun tamamı yanıtlandı ve uygulandı (2026-09-13)

Kullanıcı S-01…S-18'in tamamını yanıtladı. **Bloklayıcı kalmadı.** Uygulanma özeti:

| # | Karar | Uygulanma durumu |
|---|---|---|
| S-01 / S-01b | WSL kullan, ne gerekiyorsa kur | ✔ Go 1.24.7 + Flutter 3.47.4 kuruldu; `verify-stack.sh` 102/102, `verify-mobile.sh` 8/8 |
| S-02 | Finans şeması dondurması **iptal**, ne gerekiyorsa yap | ✔ `012` (mevzuat parametreleri), `013` (site bazlı roller), `014` (yönetişim) yazıldı |
| S-03 | 22 mock servisin **hepsini tamamla** | ◐ Ara adım tamam: hepsi dürüstçe **501** döndürüyor. Gerçeğe çevirme FAZ 5'te sürecek |
| S-04 | Her iki KVKK modelini de destekle | ◐ Veri modeli site bazlı ve tenant'a hazır; hukuki metinler "taslak" işaretli (hukuk onayı bekliyor) |
| S-05 | Mevzuatı araştır, parametre yap, değiştirilebilir bırak | ✔ 26 parametre yürürlük tarihli ve dayanağıyla `legal_parameters`'ta; `pkg/legalparams` |
| S-06 | Ödeme: sağlayıcı bağımsız arayüz, test modu görünsün | ✔ `payment_gateway_ready:false` + arayüzlerde açık uyarı + yönetici onay akışı |
| S-07 | Banka entegrasyonu **sonraki sürüme** | ✔ Yapılmadı (karar gereği) |
| S-08 | e-Fatura **sonraki sürüme** | ✔ Yapılmadı (karar gereği) |
| S-09 | Oracle / Cloudflare / AWS uyumlu depolama | ✗ **Sıradaki iş** |
| S-10 | Sağlayıcı bağımsız bildirim + `log` adaptörü | ✗ **Sıradaki iş** |
| S-11 | AI yalnızca backend'den, anahtar yokken kapalı | ◐ AI kodu hiçbir yerden import edilmiyor; uydurma AI yanıtları kaldırıldı |
| S-12 | Çok siteli yönetim şirketini destekle | ✔ Veri modeli hazır (`property_roles` site bazlı); portföy ekranları P2 |
| S-13 | Blok bazlı gider ayrımını destekle | ✔ Şema destekliyor (`blocks`, birim bazlı dağıtım) |
| S-14 | SaaS abonelik P2 | ✔ Uydurma "Pro Plan" ekranı kaldırıldı |
| S-15 | Çok dile hazır altyapı | ◐ Mobilde `intl` + `flutter_localizations` devrede; metinler hâlâ koda gömülü |
| S-16 | Önce Android iç test | ✔ CI'da iki uygulama da `analyze` + `test` çalıştırıyor |
| S-17 | Madde başına commit, bölüm sonunda push | ◐ Commit'ler atılıyor; **push için kimlik bilgisi gerekiyor** (aşağıya bakın) |
| S-18 | `tasks/` tek kaynak | ✔ Kök dosyalar işaretçi |

## AÇIK SORULAR (2026-10-03)

### S-19. Anahtar deposu (vault / KMS) — hangisi?

`PII_ENCRYPTION_KEY`, `JWT_SECRET` ve veritabanı rol parolaları bugün ortam
değişkeni / k8s Secret ile veriliyor. Anahtar **döndürme** artık var
(`docs/runbook-anahtar-dondurme.md`); eksik olan anahtarın nerede tutulacağı.
Hedef bulut ve bütçe bilinmeden seçilemez:

| Seçenek | Not |
|---|---|
| a) k8s Secret + etcd şifreleme (bugünkü hâl) | Ek maliyet yok; anahtar küme yöneticisine açık |
| b) HashiCorp Vault / OpenBao | Bulut bağımsız; işletmesi ayrı iş |
| c) Bulut KMS (Oracle Cloud Vault, AWS KMS) | S-09'daki depolama sağlayıcısıyla aynı bulut seçilirse doğal |

**KARAR (kullanıcı, 2026-10-03; teyit 2026-10-05):** a) olduğu gibi kalır. Kod tarafında değişiklik gerekmiyor;
servisler anahtarı ortamdan okumaya devam eder.

### S-20. Başka sitede kayıtlı kişiyi sakin olarak ekleme — davet akışı gerekli mi?

Önceden yönetici, başka bir sitede kayıtlı kişinin telefonunu girince o hesap
SESSİZCE kendi dairesine bağlanıyor ve kişinin adı/e-postası yöneticiye
gösteriliyordu (B25, KVKK). 2026-10-03'ten beri bu durumda **409** dönüyor; aynı
sitede zaten kayıtlı kişinin ikinci daireye bağlanması çalışıyor.

**Sonuç:** iki farklı sitede dairesi olan kişi (yönetim şirketi müşterileri için
yaygın) ikinci siteye bugün eklenemez. Seçenekler:

| Seçenek | Not |
|---|---|
| a) Uygulama içi davet: kişi kendi uygulamasında onaylar | En doğru; mobil + backend işi |
| b) SMS ile tek kullanımlık onay kodu | SMS sağlayıcısı gerekir (S-10) |
| c) Bugünkü hâl (409) | Güvenli ama işlevsel boşluk |

**KARAR (2026-10-03):** kullanıcı kararı bana bıraktı → **a) uygulama içi davet** uygulandı (migration 032).
Gerekçe: (1) KVKK — kişi kendi uygulamasında onay vermeden başka bir siteye bağlanmaz,
yöneticiye adı/e-postası gösterilmez; (2) SMS sağlayıcısı (S-10) ve maliyeti gerekmez;
(3) iki sitede dairesi olan kişinin işini bugün çözer; (4) davet 14 gün geçerli, iptal
edilebilir, kim-kimi-ne zaman izi silinmez. Bilinen sınır: yönetici, telefonun sistemde
kayıtlı olduğunu öğrenir (kişisel veri değil, 409 döneminde de böyleydi). Kişiye anlık
bildirim yok; davet sakin uygulamasının ana sayfasında görünür.
### ⚠ Kullanıcıdan gereken tek şey: git push yetkisi

`git push origin main` şu hatayı veriyor:

```
fatal: could not read Username for 'https://github.com': terminal prompts disabled
```

Bu ortamda kayıtlı bir GitHub kimlik bilgisi yok ve `gh` CLI kurulu değil. Commit'ler
**yerel olarak atıldı ve kaybolmadı**; yalnızca uzak depoya gönderilemedi.

Çözüm seçenekleri (biri yeterli):

1. `gh auth login` ile GitHub CLI oturumu açmak
2. Git credential manager'a kişisel erişim jetonu (PAT) kaydetmek
3. Uzak adresi SSH'a çevirmek: `git remote set-url origin git@github.com:muhone-sudo/siteeksen.git`

---

## A. BLOKLAYICI — Acil karar gerekli

### S-01. Geliştirme araç zinciri — ✅ ÇÖZÜLDÜ (WSL)

> **CEVAP (2026-09-12):** Kullanıcı: *"bu makinede yani localde çalışma yapacaksan wsl kullan.
> wsl'de kısıtlama yok."* → Local iş ve doğrulama artık **WSL (Ubuntu 24.04)** üzerinden yapılıyor.
>
> **Kurulan/mevcut durum:**
>
> | Araç | Durum |
> |---|---|
> | Go 1.24.7 | WSL'e kuruldu (`/usr/local/go`) |
> | Docker 27.5.1 | WSL'de zaten çalışıyor |
> | PostgreSQL istemcisi 16 | WSL'de zaten kurulu |
> | Node 22 / npm | Hem Windows hem WSL |
> | **Flutter** | **Hâlâ yok** — mobil doğrulaması için kurulmalı (bkz. S-01b) |
>
> **Sonuç:** Backend, migration ve veritabanı işleri artık **gerçekten doğrulanabiliyor.**
> Kalıcı doğrulama betiği eklendi: `backend/scripts/verify-stack.sh` (42 kontrol).
> İlk çalıştırmada 42/42 geçti.

### S-01b. Flutter WSL'e kurulsun mu?
Mobil uygulamalardaki bulgular (release APK'da INTERNET izni yok, biyometrik `FlutterActivity`
nedeniyle çalışmıyor, yönetici uygulamasında taban adres `/v1` hatası, `flutter test` derlenmiyor)
ancak Flutter kurulu olursa doğrulanabilir.
**Cevap:** flutter kur.
**Cevap gelmezse uygulanacak varsayılan:** Mobil işlere sıra geldiğinde Flutter SDK WSL'e kurulur
(`git clone` + PATH; Android SDK gerekirse ayrıca). Şimdilik mobil değişiklikler `[D1]` kalır.

<details>
<summary>Sorunun ilk hâli (tarihsel kayıt)</summary>

**Durum:** Bu makinede yalnızca Node.js/npm çalışıyor. `go`, `flutter`, `docker`, `psql` yok.
Portable Go indirilip çalıştırılmak istendi; **kurumsal AppLocker politikası** kullanıcı yazılabilir dizinlerden
(`%TEMP%`, `Documents`) `.exe` çalıştırmayı engelliyor ("Access is denied"). `winget` da mevcut değil.
</details>

**Sonucu (önemli):**
- Backend (Go) ve mobil (Flutter) kodu bu makinede **derlenemez, test edilemez, çalıştırılamaz**.
- Yani bu ortamda Go/Flutter işleri için "canlı doğrulandı" denemez — yalnızca statik inceleme yapılabilir.
- Admin panel (Next.js) **doğrulanabilir**: `npm install` ve `npm run build` çalışıyor.
- Geçmiş oturumlardaki "canlı doğrulandı" ifadeleri başka bir makinede yapılmış olabilir; bu repoda kanıtı yok.

**Soru:** IT'den Go 1.24+, Flutter 3.16+, Docker Desktop ve PostgreSQL client kurulumu için izin alınabilir mi?
Alternatif olarak geliştirme için WSL2, bir geliştirme sunucusu/VM ya da GitHub Codespaces kullanılabilir mi?

**Cevap:** Ne gerekiyorsa kur. İzin almana gerek yok.

**Cevap gelmezse uygulanacak varsayılan:**
1. Doğrulanabilir işlere öncelik verilir (admin panel: build + lint; SQL: statik gözden geçirme; dokümantasyon/planlama).
2. Go/Flutter kodu yazılırken her değişiklik ikinci bir denetim turundan geçirilir ve **"derlenmedi — CI doğrulaması bekliyor"**
   olarak işaretlenir; asla "tamamlandı ✅" denmez.
3. GitHub Actions (`.github/workflows/ci-cd.yaml`) derleme/test kapısı olarak kullanılır — push sonrası CI sonucu kanıt kabul edilir.

---

### S-02. Finans/muhasebe şema dondurması hâlâ geçerli mi?
**Durum:** `tasks/lessons.md` içinde kullanıcı talimatı (2026-06-07):
> "Muhasebe ile ilgili, aidat, gelir-gider, tahakkuk vs. ile ilgili HİÇ migration yazma. Ben para ile ilgili bölümleri
> test ediyorum, henüz tamamlamadım, çok eksik var. Bu eksikler için de ayrı migration gerekecek — hepsini birlikte yaparız."

**Cevap:** Yukarıdaki durumdaki süreç iptal. Yapılması gereken ne varsa yap.

**Neden bloklayıcı:** Domain analizinde çıkan **P0 (yasal zorunlu)** modüllerin büyük kısmı finans şeması gerektiriyor:
- İşletme projesi / yıllık bütçe (KMK m.37) — tablo yok
- Gecikme tazminatı (KMK m.20, aylık %5) — alan/tablo yok
- Isı-su gider paylaşımı (pay ölçer yönetmeliği, %70/%30) — tablo yok
- Borç kalemi bazlı seçmeli/kısmi ödeme ve mahsup sırası — model yok
- Hukuk/icra takibi, kanuni ipotek (KMK m.22) — tablo yok
- `dues_decisions` ve `incomes` tabloları (lessons.md'de zaten biriktirme listesinde)

**Soru:** Finans şeması için (a) şu an tek bir **toplu migration** tasarlayıp onayına sunayım mı, (b) yoksa dondurma
devam edip finans dışı modüllerle mi ilerleyeyim?

**Cevap:** Ne gerekiyorsa yap. Onayıma sunmana gerek yok. Ölç, tart ve uygula.

**Cevap gelmezse uygulanacak varsayılan:** Dondurmaya **uyulur**. Finans şeması için migration YAZILMAZ; bunun yerine
gereken tüm şema değişiklikleri tek bir **onay bekleyen tasarım dosyasında** (`tasks/finans-sema-tasarimi.md`) biriktirilir
ve uygulanmadan bekletilir. Bu arada finans dışı P0 işler (platform, yönetişim, operasyon, uyum takvimi) geliştirilir.

---

### S-03. Ürün kapsamı: 25 mock servisi mi tamamlayalım, yoksa daraltıp derinleştirelim mi?
**Durum:** Denetim, 25 backend servisinden yalnızca 3'ünün (identity, finance, community) gerçek veritabanına bağlı
olduğunu gösteriyor. Kalan 22 servis hardcoded veri döndürüyor ve yazma işlemlerini hiçbir yere kaydetmiyor.
Buna karşın hem admin panel hem iki mobil uygulama bu servislere "bağlanmış" durumda — yani arayüzler dolu görünüyor
ama veri kalıcı değil.

**Soru:** Hangi strateji?
- **(A) Daralt ve derinleştir (önerilen):** 8-10 çekirdek modül seçilir, uçtan uca gerçek yapılır (şema → servis → API → panel → mobil → test).
  Geri kalan modüller ürün dışına alınır ve arayüzden **kaldırılır** ya da açıkça "yakında" olarak işaretlenir.
- **(B) Hepsini tamamla:** 22 servis tek tek gerçeğe çevrilir. Çok daha uzun sürer; yarısı yarım kalırsa bugünkü tabloya geri dönülür.
- **(C) Mevcut hâli koru:** Demo/yatırımcı sunumu amaçlıysa mock kalır, ama o zaman dokümanlar "mock" olarak dürüst işaretlenir.

**Neden önemli:** Bugünkü en büyük risk, kullanıcıya **sahte veri gerçek gibi gösterilmesi**. Özellikle para ile ilgili
ekranlarda bu kabul edilemez.

**Cevap:** Hepsini tamamla.

**Cevap gelmezse uygulanacak varsayılan:** **(A)** uygulanır. Ek olarak, gerçek veriye bağlanmamış her ekran için
arayüzde açık bir **"DEMO VERİ"** işareti zorunlu tutulur (sessiz mock fallback kaldırılır) — böylece hiç kimse sahte
veriyi gerçek sanmaz.

---

### S-04. KVKK: Veri sorumlusu kim — SiteEksen mi, her site yönetimi mi?
**Durum:** Çok kiracılı (multi-tenant) bir SaaS'ta bu ayrım hukuki olarak belirleyici:
- Her site yönetimi **veri sorumlusu**, SiteEksen **veri işleyen** ise → aralarında KVKK m.12 uyarınca **veri işleyen sözleşmesi**
  şart; aydınlatma metinlerini site yönetimi yapar; VERBİS yükümlülüğü site yönetimine ait olabilir.
- SiteEksen veri sorumlusu ise → tüm aydınlatma/rıza/başvuru yükümlülüğü SiteEksen'de.

**Ayrıca:** Parmak izi/yüz tanıma ile geçiş sistemi kullanılacaksa bu **özel nitelikli kişisel veri**dir (KVKK m.6);
açık rıza ve ek güvenlik tedbirleri gerekir. Güvenlik kamerası için aydınlatma levhası ve saklama süresi politikası gerekir.

**Soru:** Hukuki model hangisi? Bir hukuk danışmanı görüşü var mı?
**Cevap:** Her iki modeli de desteklesin. Planlamasını yap ve uygula.
**Cevap gelmezse uygulanacak varsayılan:** Teknik mimari **her iki modeli de destekleyecek** şekilde kurulur:
tenant bazlı aydınlatma metni sürümleme, tenant bazlı rıza kaydı, tenant bazlı saklama süresi ve veri ihracı/silme yeteneği.
Hukuki metinler "hukuk onayı bekliyor" işaretiyle taslak bırakılır.

---

### S-05. Mevzuata bağlı oranların hukuki teyidi
**Durum:** Aşağıdaki değerler doğrudan **para hesabına** giriyor; yanlış olursa hatalı tahakkuk/faiz üretir.
Bilgim dahilindeki değerler ve dayanakları:

| Konu | Uygulanacak değer | Dayanak (teyit gerekli) |
|------|-------------------|--------------------------|
| Gecikme tazminatı | Aylık **%5** | KMK m.20/2 |
| Kapıcı/kaloriferci/bahçıvan/bekçi + yönetim gideri | **Eşit** paylaşım | KMK m.20/1-a |
| Sigorta primi, ortak yer bakım/onarım/güçlendirme, ortak tesis işletme | **Arsa payı** oranında | KMK m.20/1-b |
| Merkezi ısıtma gider paylaşımı | **%70 ölçülen tüketim + %30 kullanım alanı** | Isı/sıhhi sıcak su paylaşım yönetmeliği |
| Genel kurul çağrı süresi | **15 gün** önce, imza karşılığı/taahhütlü mektup | KMK m.29 |
| Toplantı/karar yeter sayısı | Sayı **ve** arsa payı bakımından yarıdan fazla; ikinci toplantıda katılanların salt çoğunluğu | KMK m.30 |
| Oy hakkı ve vekâlet sınırı | Her bağımsız bölüm 1 oy; çok BB'li malikin oyu tüm oyların 1/3'ünü geçemez; vekâlet sınırı (%5 / 40 daire kuralı) | KMK m.31 |
| Ortak yerlerde inşaat/onarım/renk değişikliği | **4/5** yazılı rıza | KMK m.19/2 |
| Yenilik ve ilaveler | Sayı **ve** arsa payı çoğunluğu | KMK m.42 |
| Çatı/dış duvar reklam kiralaması, temliki tasarruflar | **Oybirliği** | KMK m.45 |
| Yönetim planı değişikliği | **4/5** | KMK m.28 |
| Yönetici atama zorunluluğu | **8 ve daha fazla** bağımsız bölüm | KMK m.34 |
| İşletme projesine itiraz süresi | Tebliğden **7 gün** | KMK m.37 |
| Kesinleşen işletme projesi / kurul kararı | İcra takibinde **İİK m.68** belgesi | KMK m.37/son |
| Karar defterinin notere kapatılması | Takvim yılı bitiminden itibaren **1 ay** | KMK m.36 |
| Yıllık hesap verme | Takvim yılının **birinci ayı** içinde | KMK m.39 |
| Denetim sıklığı | En az **3 ayda bir** | KMK m.41 |
| Yeni malikin sorumluluğu | Önceki malikin ortak gider borcundan **müteselsil** | KMK m.22 |
| Kiracının sorumluluğu | Ortak giderden malikle müteselsil, **kira bedeli kadar** | KMK m.22 |

**Soru:** Bu tablo hukuk danışmanınca teyit edilebilir mi? Özellikle merkezi ısıtma %70/%30 oranı, vekâlet sınırları ve
merkezi sistemden ferdi ısıtmaya geçiş nisabı güncel mevzuata göre kontrol edilmeli.

**Cevap:** Bu konuda internette araştırma yap, mevzuatı oku ve durumu netleştir. Çıkan sonuca göre uygulamanı yap. Ama ilerde mevzuat değişirse diye bu kısmı değiştirilebilir yap. Cevap gelmezse uygulanacak varsayılan'da yazanı da uygula.

**Cevap gelmezse uygulanacak varsayılan:** Hiçbir oran **koda gömülmez**. Tümü site bazlı, **yürürlük tarihli
parametre** olarak veritabanında tutulur (varsayılan değerler yukarıdaki tablodan gelir, yönetim planı farklı öngörürse
site bazında değiştirilebilir). Böylece hukuki düzeltme kod değişikliği gerektirmez. Her parametreye mevzuat dayanağı
alanı eklenir. Kod içine `// HUKUK TEYİDİ BEKLİYOR` yorumu düşülür.

---

## B. ENTEGRASYON / HESAP ERİŞİMİ GEREKEN KONULAR

### S-06. Ödeme sağlayıcısı
`tasks/todo.md` "iyzico Entegrasyonu (Sonradan yazılacak - Ertelendi)" diyor, ama `ROADMAP.md` "iyzico ✅ sandbox
bağlantısı kurulu" diyor — çelişki. Gerçek tahsilat olmadan finans modülü uçtan uca test edilemez.
**Soru:** Hangi sağlayıcı (iyzico / PayTR / Param / banka sanal POS)? Sandbox anahtarları verilebilir mi?
**Varsayılan:** Sağlayıcıdan bağımsız bir **ödeme sağlayıcı arayüzü (port/adapter)** yazılır; iyzico adaptörü ilk
uygulama olur, anahtar yokken `sandbox-stub` adaptörü çalışır ve arayüzde "TEST MODU" açıkça gösterilir.

**Cevap:** Varsayılanı uygula.

### S-07. Banka / açık bankacılık entegrasyonu
Hesap hareketlerinin otomatik çekilmesi ve ödeme eşleştirmesi (Apsiyon'un en çok şikayet edilen noktalarından biri).
**Soru:** Hangi bankalar? Kurumsal API sözleşmesi var mı, yoksa bir aracı (açık bankacılık servis sağlayıcısı) mı?
**Varsayılan:** Önce **MT940/CSV ekstre içe aktarma + otomatik eşleştirme** yazılır (API gerektirmez, hemen değer üretir).
Canlı API adaptörü sonraya bırakılır.

**Cevap:** Banka entegrasyonu kısmını bir diğer versiyona geçerken yapalım. İçe aktarma kısmı biraz zor olacak gibi. Çünkü her bankanın ekstresi farklı. Bu kısım bizi çok yorar gibi. Bunu diğer versiyonda yapalım.

### S-08. e-Fatura / e-Arşiv entegratörü
**Soru:** Hangi entegratör (Logo, Paraşüt, Nes, Foriba...)? Mali mühür/portal erişimi olacak mı?
**Varsayılan:** Gelen fatura tarafı **OCR + manuel doğrulama** ile çalışır; e-Fatura adaptörü arayüz olarak tanımlanır, uygulanmaz.

**Cevap:** Banka entegrasyonu kısmını bir diğer versiyona geçerken yapalım. 

### S-09. Dosya/doküman depolama
Belge, fatura görüntüsü, talep fotoğrafı, tutanak gibi dosyalar için kalıcı depolama altyapısı bugün yok.
**Soru:** S3 uyumlu (AWS/MinIO/Azure/GCS) hangisi kullanılacak? Verinin Türkiye'de tutulması gerekiyor mu (KVKK aktarım)?
**Varsayılan:** **S3 uyumlu arayüz** yazılır; geliştirmede MinIO (docker-compose'a eklenir), üretimde sağlayıcı seçimi ertelenir.
KVKK gereği veri yerleşimi (data residency) yapılandırılabilir bırakılır.

**Cevap:** Bu program şu an gerçek kullanıcılara açılmadı. Sen oracle, claudflare ve aws depolamalarına göre yaz.

### S-10. Bildirim sağlayıcıları
**Soru:** Firebase projesi (`firebase-credentials.json`, `google-services.json`) var mı? SMS sağlayıcısı ve
WhatsApp Business hesabı var mı? SMS maliyet bütçesi nedir (kademeli hatırlatma otomasyonu maliyeti etkiler)?
**Varsayılan:** Sağlayıcı bağımsız bildirim arayüzü + kuyruk yazılır; anahtar yokken `log` adaptörü çalışır (gönderim
veritabanına yazılır, dışarıya çıkmaz). Böylece akış test edilebilir, gerçek gönderim maliyeti oluşmaz.

**Cevap:** Varsayılanı uygula

### S-11. Yapay zekâ kullanımı ve gizlilik
Fatura OCR, plaka tanıma, talep sınıflandırma için AI planlanmış (`pkg/integrations/ai/`, OpenAI Vision).
**Soru:** (a) Hangi sağlayıcı ve bütçe? (b) Kişisel veri içeren görüntülerin (plaka, fatura, kimlik) yurt dışına
aktarılması KVKK açısından değerlendirildi mi? (c) API anahtarı **kesinlikle** mobil uygulamaya gömülmemeli —
tüm AI çağrıları backend üzerinden mi geçecek?
**Varsayılan:** Tüm AI çağrıları **yalnızca backend'den** yapılır; mobil/panel doğrudan AI sağlayıcısına gitmez.
Anahtar yokken yetenek kapalı kalır ve arayüzde "yapılandırılmadı" gösterilir. Yurt dışı aktarım için açık rıza/aydınlatma
gerekliliği hukuk sorusu olarak açık bırakılır.

**Cevap:** Varsayılanı uygula
---

## C. ÜRÜN / STRATEJİ SORULARI

### S-12. Hedef müşteri: tek site mi, profesyonel yönetim şirketi mi?
Bu, "yönetim şirketi (portföy) katmanı" ve fiyatlandırmanın gerekip gerekmediğini belirler.
`yorum_analizleri.txt` çıkarımı, hedefin **memnuniyetsiz Apsiyon kullanıcıları** olduğunu söylüyor — bunlar hem
bağımsız site yöneticileri hem profesyonel şirketler olabilir.
**Varsayılan:** Veri modeli **çok siteli yönetim şirketini destekleyecek** şekilde kurulur (site üstü bir "yönetim
organizasyonu" kavramı), ama arayüzde portföy ekranları P2'ye bırakılır.

**Cevap:** Varsayılanı uygula

### S-13. Toplu yapı (site) yönetişim hiyerarşisi kapsama alınacak mı?
KMK m.66-73 toplu yapılar için **blok kat malikleri kurulu**, **ada temsilciler kurulu** ve **toplu yapı temsilciler
kurulu** gibi ayrı organlar ve blok bazlı ortak gider ayrımı öngörüyor. Bugünkü veri modelinde `blocks` tablosu var
ama bu yönetişim katmanı yok. Gerçek sitelerde "blok gideri" ile "site gideri" ayrımı çok yaygın bir ihtiyaç.
**Varsayılan:** Veri modeli blok bazlı gider ayrımını **destekleyecek** şekilde tasarlanır; temsilciler kurulu
süreçleri P1 olarak planlanır.

**Cevap:** Varsayılanı uygula

### S-14. SaaS abonelik/faturalama modülü şimdi mi gerekli?
**Varsayılan:** P2. Önce ürünün kendisi gerçek olmalı.

**Cevap:** Varsayılanı uygula

### S-15. Çoklu dil gerekli mi?
Bugün tüm metinler Türkçe ve koda gömülü.
**Varsayılan:** Altyapı çok dilliliğe hazır yapılır (metinler kaynak dosyalara taşınır), ikinci dil eklenmez.

**Cevap:** Varsayılanı uygula

### S-16. Mobil yayın hedefi
`docs/store-publishing-guide.md` hazır ama yayın yapılmamış. iOS için Apple Developer hesabı var mı?
**Varsayılan:** Önce Android iç test kanalı hedeflenir; iOS ertelenir.

**Cevap:** Varsayılanı uygula

---

## D. SÜREÇ SORULARI

### S-17. Git akışı ve commit yetkisi
`tasks/todo.md` içinde eski bir oturum talimatı var: "Kullanıcı bu oturumda uyuyor. Onay gelmeyecek. Her tamamlanan
adımı direkt commit et." Bu talimat **o oturuma özeldi** ve bugün geçerli sayılmamalı.
**Soru:** Bu oturumda commit/push yapmamı istiyor musunuz? Doğrudan `main`'e mi, yoksa özellik dalı + PR mı?
**Varsayılan:** Kod değişiklikleri **çalışma ağacında bırakılır**, commit edilmez; kullanıcı açıkça isteyene kadar
push yapılmaz. (`main` üzerinde çalışıldığı için önce bir dal açılması önerilir.)

**Cevap:** Her madde tamamlandıktan sonra commit, bölüm tamamlandıktan (kantılı doğrulama sonrası) sonra da tüm commitler pushlanır. 

### S-18. `ROADMAP.md` / `CHANGELOG.md` ikizliği
Kökteki `ROADMAP.md` ile `tasks/roadmap.md` **birebir aynı içeriğe** sahip; aynı durum `CHANGELOG.md` ↔
`tasks/changelog.md` için de geçerli. İki kopya kaçınılmaz olarak birbirinden ayrışıyor.
**Varsayılan:** `tasks/` altındakiler **tek kaynak** kabul edilir (CLAUDE.md bunlara atıf yapıyor); kökteki dosyalar
kısa birer işaretçiye dönüştürülür.
**Cevap:** Varsayılanı uygula, tek dosyaya düşerken, diğer dosyaları da son bir kez tekrar oku ve alınması gereken bilgiler varsa kalacak dosyanın içine al.
### S-21. VERBİS kaydı — site yönetimleri yükümlü mü?

KVKK m.16 VERBİS kaydını ister; Kurul muafiyet kararlarıyla (çalışan sayısı ve bilanço eşiği, ana faaliyetin özel
nitelikli veri işleme olmaması) birçok veri sorumlusu muaftır. Site/apartman yönetimlerine özel bir muafiyet
kararı araştırmada **bulunamadı** (2026-10-04). Sistem artık sakin acil bilgi kartında özel nitelikli veri (sağlık)
işliyor (açık rızayla, şifreli). Saklama ve imha politikası (İmha Yönetmeliği m.5) VERBİS'e kayıtlı olanlar için
zorunludur; sistem politikayı uygular ama kayıt yükümlülüğünü belirleyemez.
**Varsayılan:** sistemde VERBİS ile ilgili bir iddia yapılmaz; yönetime "hukuk danışmanıyla teyit edin" notu.
**KARAR (kullanıcı, 2026-10-05):** VERBİS sistemde **opsiyoneldir**; kayıt yükümlülüğü veri sorumlusu olan site
yönetimine aittir. Kayıt bilgisi girilmemiş site programı kullanmaya devam eder (engelleme yok). Sistem yönetime
yalnızca beyan alanı (kayıtlı / muaf / bilinmiyor + sicil no) ve sorumluluğun kendisinde olduğunu söyleyen not sunar.

### S-22. Bordro hesabı (FAZ 7.4) — kapsam

Bordro (brüt→net, SGK işçi/işveren payları, gelir vergisi dilimleri, damga vergisi, asgari ücret istisnası) her yıl
değişen oranlara bağlıdır ve hata doğrudan çalışan ücretine yansır. Sistem bugün SGK/MUHSGK sürelerini takip ediyor
(041) ama ücret hesaplamıyor.
**Seçenekler:** a) oranlar `legal_parameters`'a girilip tam bordro hesaplanır (her yıl Ocak'ta oran güncellemesi şart);
b) bordro mali müşavirden gelir, sistem yalnızca net ödemeyi ve maliyeti kaydeder.
**KARAR (kullanıcı, 2026-10-05):** b) — bordro mali müşavirden gelir; sistem dönem bazında net ödemeyi ve
işveren maliyetini kaydeder, ücret/vergi/SGK HESAPLAMAZ. iOS paket kimliği de olduğu gibi kalır (ios/ yok).
### S-23. Altıncı tur (malik / kiracı / oturan, gider sınıfı) — kararlar ve varsayılanlar (2026-10-11)

**KARAR (kullanıcı):** her mali kalem girişte KULLANIM (oturan öder) ya da MALİK (demirbaş, yenilik, yeni tesis) sınıfı alır ve
bütün mali işler sınıfa uyar; sakin kendi başına üye olamaz; maliki yönetim kaydeder, yönetim malik olmadan kiracıyı da
kaydedebilir, yalnız kiracıyla kayıtlı daireye malik davet edilir; daire boş olabilir ama malik olmalı, boş dairede her şey
malike düşer; kiracıyı malik ya da yönetim SMS + e-postayla davet eder, aktif kiracı varken davet yok (yönetim dahil); hane
üyesi olur; devirden sonra malik kullanım işlemi yapmaz; malikin görünürlüğünü yönetim belirler (site bazında, en dar
varsayılan, kurul üyesi onayı, kiracıya şeffaf); kiracılık bitişi: malik isterse kiracı onayı şart; yönetim yolu belge (UYAP
kodu isteğe bağlı), kimlik bilgisiyle onay, 1 hafta itiraz. D3: davetli kişinin hesabı yoksa hemen açılır, kodu girince
bağlanır; hane üyesini oturan ve yönetim ekler; yönetim kiracıyı doğrudan da kaydeder; kiracı gelince malikin hanesi biter.

**Varsayılanlar (uygulandı; kullanıcı aksini söylerse değişir):**
- V1 Kiracı kendi çıkışını malik onayı olmadan bildirir; malike bilgi gider. *(kullanıcı D4 öncesi "tamam" dedi)*
- V2 Yönetim yolunda itiraz edilirse işlem askıda kalır; yalnız kiracının onayıyla ya da yeni belgeyle (yeni 7 gün) ilerler;
  başlatan o dairenin maliki/vekili olamaz; belge sahte çıkarsa geri alınır. *(kullanıcı D4 öncesi "tamam" dedi)*
- V3 Maliksiz dairede malik sınıfı borç yönetimde "malik kaydı yok" ile bekler; kiracıya yansımaz, kimseye bildirim gitmez.
- V4 Hane üyesi kullanım özelliklerini kullanır; borç, ödeme, pusula ve tüketim tutarlarını görmez.
- V5 Eski veride aktif kiracılı dairede kiracı, olmayanda malik oturan sayıldı; dönemi kiracılık başlangıcından sonra olan
  kullanım borcu kiracılığa bağlandı.
- V6 Borcun sorumlusu tahakkuk anında saptanır; kiracılık bitince açık kullanım borcu malike görünür ve malik öder.
- V7 Yönetim yolunda ikinci onaycı zorunlu değil (koruma: çıkar çatışması yasağı, şifreyle beyan, kiracıya açık belge, itiraz).
- V8 Kiracılık bitince daire "boş" işaretlenir; malik oturuyorsa yönetim değiştirir.
- V9 Görünürlük seçenekleri (hepsi varsayılan kapalı): kiracının adı/maskeli telefonu, kiracı borcu toplamı, vadesi geçen borç
  + malike aylık uyarı, daire talepleri. Hiç görünmeyenler: ziyaretçi, kargo, sayaç/pusula ayrıntısı, hane üyeleri.
- Kapsam dışı bırakılanlar (D7): ilan panosu, anket/NPS, tadilat izni, kural ihlali bildirimi — gerekçeler `todo.md` D7'de.
---

## E. CEVAPLANMIŞ SORULAR

_(henüz yok)_
