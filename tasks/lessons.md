# Lessons — Öğrenilen Dersler

Tekrar eden hataları önlemek için her oturum başında bu dosya okunur.
Bir hata düzeltildiğinde veya önemli bir şey öğrenildiğinde buraya eklenir.

Format:
- **Ne oldu:** Kısa açıklama
- **Neden oldu:** Kök neden
- **Kural:** Bir daha olmaması için ne yapılmalı

---

## 2026-09-09 — En pahalı ders: kanıtsız "tamamlandı" işaretlemek

- **Ne oldu:** Kullanıcı, "yapıldığı iddia edilen ve işaretlenen işlerin yapılmamış çıktığını" bildirdi.
  Yapılan denetimde `ROADMAP.md`, `tasks/todo.md` ve `CHANGELOG.md`'deki **78 iddianın 38'i (%49) yanlış**,
  22'si kısmen doğru çıktı. Örnekler: "iot ✅ MongoDB bağlı" (MongoDB sürücüsü `go.mod`'da bile yok),
  "notification ✅ Firebase + Kafka" (ikisi de yok), "iyzico ✅ sandbox kurulu" (hiç entegrasyon yok),
  "Faz 3/4/5 tamamlandı" (üçü de çalışmıyor), "audit log tamamlandı" (INSERT her seferinde hata veriyor).
- **Neden oldu:** `✅` işareti **"dosya yazıldı"** anlamında kullanıldı. Hiçbir satırda "nasıl doğrulandı"
  bilgisi yoktu. Derlenmeyen kod, çalışmayan sorgu, boş kalan tablo hep "tamamlandı" göründü.
  İkincil neden: hatalar sessizce yutulduğu için (`_ = err`, boş `catch`) sistem çalışmadığını hiç söylemedi.
- **Kural:**
  1. `tasks/dogrulama-politikasi.md` yürürlüktedir. `✅` **kullanılmaz**; kanıt seviyesi (`[D0]`…`[D4]`) yazılır.
  2. Kanıt satırı olmayan madde `[D1]`'den yükseğe çıkarılamaz. "Canlı doğrulandı" demek için
     istek/yanıt örneği veya veritabanı satırı gösterilmelidir.
  3. Bir iş "bitti" sayılmadan önce politikanın §2 "Bitti tanımı" kontrol listesi işlenir.
  4. Doğrulama aracı yoksa (bu makinede Go/Flutter/Docker yok) bu **açıkça yazılır**, iş `[D1]` bırakılır.

## 2026-09-09 — Hatayı yutan kod, gelecekteki kendine kurulan tuzaktır

- **Ne oldu:** Denetim izi (audit log) mekanizması aylardır **hiç çalışmıyordu**. `pkg/audit/audit.go:28`
  şemada bulunmayan kolon adlarına (`user_ip`, `resource_type`, `resource_id`) yazıyor; şema ise
  `ip_address`, `entity_type`, `entity_id` kullanıyor. INSERT her çağrıda hata veriyor, ama
  `pkg/middleware/auth.go:115`'te `_ = audit.LogAction(...)` ile hata atıldığı için kimse fark etmedi.
  `audit_logs` tablosu kalıcı olarak boş kaldı — üstelik `legal/kvkk-aydinlatma.md` "log tutuyoruz,
  2 yıl saklıyoruz" diye taahhüt veriyor.
- **Neden oldu:** Hata dönüş değerinin bilinçli olarak atılması. Aynı desen 5 ayrı yerde daha var
  (ödeme-tahakkuk bağlantısı, esg, nps, banking, parking).
- **Kural:**
  1. `_ = err` ve boş `catch` **yasak**. En kötü durumda log'la, ama asla sessizce yutma.
  2. `golangci-lint`'te `errcheck` açık olacak ve CI'da kapı olacak — bu hata linter'la otomatik yakalanırdı.
  3. Şema ile kod arasındaki kolon uyumu için `sqlc` gibi derleme zamanı doğrulaması tercih edilir.

## 2026-09-09 — Kullanıcıya sahte başarı göstermek, hata göstermekten daha zararlıdır

- **Ne oldu:** Sistemde 30'dan fazla noktada kullanıcı işlemin başarılı olduğunu görüyor ama hiçbir şey
  kaydedilmiyor: mobil ödeme ekranı hiç ağ çağrısı yapmadan "Ödeme Başarılı!" gösteriyor
  (`dues_payment_screen.dart:315-318`); admin panel ayarları hiçbir şey kaydetmeden "Kaydedildi" yazıyor;
  bildirim gönderilmemişken "124 kişiye gitti" diyor; 22 servis yazma isteklerine `201 Created` dönüp
  veriyi hiçbir yere yazmıyor; admin panelde 9 noktada sunucu hatası alınca **uydurma mali veri** gösteriliyor.
- **Neden oldu:** "Demo görünsün" ihtiyacıyla yazılan mock kodun üretim yoluna karışması ve
  hata yolunun "boş liste / mock veri" ile kapatılması.
- **Kural:**
  1. Kalıcı olmayan uç nokta `200/201` **dönmez** → `501 Not Implemented`.
  2. Sessiz mock fallback yasak. Demo veri gösterilecekse arayüzde açık `DEMO VERİ` etiketi zorunlu.
  3. Başarı mesajı **yanıt geldikten sonra** gösterilir; önce göstermek yasak.
  4. Hata durumu her ekranda görünür olacak ("yeniden dene" ile) — boş listeye düşmek yasak.

## 2026-09-09 — Genişlik derinliğe tercih edilirse hiçbir şey bitmez

- **Ne oldu:** 25 servis, 61 tablo, 37 ekran açılmış; hiçbiri uçtan uca bitmemiş. Şemanın **%77'si
  (47 tablo) ölü**; `005_new_modules.sql`'in 45 KB'ının tamamı kullanılmıyor; ~3.900 satır Go kodu
  hiçbir yere bağlı değil. Arayüzler dolu göründüğü için ilerleme hissi oluşmuş, oysa veri kalıcı değil.
- **Neden oldu:** Yeni modül açmak, mevcut modülü bitirmekten daha hızlı ilerleme hissi veriyor.
- **Kural:** **Dikey dilim** disiplini. Bir modül `şema → servis → API → gateway → panel → mobil → test →
  doküman` hattının tamamında bitmeden yeni modül açılmaz. Bitirilmeyecek modül arayüzden kaldırılır.

## 2026-09-09 — "Bende çalışıyor" ile "kurulabilir" aynı şey değil

- **Ne oldu:** Veritabanı temiz bir makinede **kurulamıyor**. `004_expense_management.sql` ve
  `005_new_modules.sql`, `001`'de zaten farklı kolonlarla var olan tabloları `CREATE TABLE IF NOT EXISTS`
  ile yeniden tanımlıyor; ifade sessizce atlanıyor, ardından gelen `INSERT`/`CREATE INDEX` var olmayan
  kolonlara dokunup hata veriyor. Postgres entrypoint `ON_ERROR_STOP=1` ile çalıştığı için kurulum orada
  duruyor — 005 sonrası **29 tablo hiç oluşmuyor**. Ayrıca seed'deki bcrypt hash hiçbir şifreyle eşleşmiyor
  (fiilen test edildi) ve iki kullanıcıda aynı hash var (kopyala-yapıştır placeholder).
- **Neden oldu:** `CREATE TABLE IF NOT EXISTS` **kolonları karşılaştırmaz** — farklı şemalı bir tablo varsa
  uyarı vermeden atlar. Bu, "idempotent yazdım, güvenli" yanılgısını üretti. CHANGELOG'daki
  "migration'ları üç kez elle uygulamak zorunda kaldım" gözleminin kök nedeni migration-runner eksikliği
  değil, **çakışan şema**. Düzeltmeler çalışan container'a uygulandı, dosyalara yansıtılmadı.
- **Kural:**
  1. Aynı tablo iki migration'da tanımlanmaz; sonraki migration `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` kullanır.
  2. Her migration turundan sonra `docker compose down -v && up` ile **sıfırdan** doğrulama yapılır.
  3. Çalışan ortama elle uygulanan her düzeltme **aynı oturumda dosyaya** da yazılır.
  4. Migration sürüm takibi ve çalıştırıcı zorunludur (`schema_migrations` tablosu + kilit).

## 2026-09-09 — Doküman kendi içinde çelişiyorsa hiçbir dokümana güvenilemez

- **Ne oldu:** `ROADMAP.md` satır 51'de "tüm 19 yeni servis docker-compose'a eklendi" derken satır 24-43'te
  aynı servisler için "docker-compose'a eklenmedi" yazıyordu. Satır 52 "Kong 24 servis yönlendiriliyor"
  derken satır 183 "20+ servis kong.yml'e eklenmeli" diyordu. `ROADMAP.md` "iyzico ✅" derken
  `tasks/todo.md` "iyzico ertelendi" diyordu. Kök `ROADMAP.md` ile `tasks/roadmap.md` birebir ikiz kopyaydı.
  Aynı entegrasyon 2-3 kez yazılmıştı (iyzico ×2, FCM ×2, OpenAI ×2, karbon hesabı ×2 — **farklı sonuçlarla**).
- **Neden oldu:** Tek doğruluk kaynağı ilkesinin olmaması; ikiz dosyaların elle senkron tutulmaya çalışılması.
- **Kural:**
  1. `tasks/` altındaki dosyalar tek kaynaktır; kökteki `ROADMAP.md`/`CHANGELOG.md` yalnızca işaretçidir.
  2. Bir çelişki fark edilirse **düzeltilmeden** başka işe geçilmez.
  3. Bir iş için ikinci bir uygulama yazılmaz; mevcut olan düzeltilir.

## 2026-09-09 — Yazılmış ama hiç çalıştırılmamış kod

- **Ne oldu:** Çok sayıda özellik "yazıldı" ama bir kez bile çalıştırılmadığı için temel bir hata
  yüzünden hiç işlemiyor: sakin mobil uygulamasının **release APK'sında INTERNET izni yok** (izin yalnızca
  `debug/AndroidManifest.xml`'de) → release build'de tüm API çağrıları başarısız; biyometrik giriş
  `MainActivity : FlutterActivity` olduğu için `local_auth`'un gerektirdiği `FlutterFragmentActivity`
  olmadığından **hiçbir zaman** çalışmıyor; yönetici uygulamasının taban adresi `/v1` ama backend
  `/api/v1` bekliyor → üretimde her çağrı 404; k8s ingress'te de aynı yol hatası var.
- **Neden oldu:** Kod yazımının doğrulama olmadan "tamam" sayılması; release/üretim yapılandırmasının
  hiç denenmemesi (yalnızca debug ortamında bakılmış olması).
- **Kural:**
  1. Bir özellik, **hedef ortamda** (release build, üretim yolu) en az bir kez çalıştırılmadan `[D4]` olmaz.
  2. Platform yapılandırması (izinler, imzalama, taban adres) ayrı bir kontrol listesiyle denetlenir.
  3. `debug` ve `main` manifest ayrımı gibi ortam bazlı yapılandırmalar özellikle gözden geçirilir.

---

## Faz 2 (Finans) — Kullanıcı talimatı: Muhasebe/Aidat/Gelir-Gider migration'larını ERTELE

- **Ne oldu:** Faz 2 (Aidat & Ödemeler) planlanırken `accounting/page.tsx`'teki "Aidat Kararları" (dues_decisions) ve "Gelirler" (incomes) sekmeleri için DB'de hiç tablo olmadığı tespit edildi (yeni migration gerektiriyor).
- **Kullanıcı talimatı (2026-06-07, verbatim çeviri):** "Muhasebe ile ilgili, aidat, gelir-gider, tahakkuk vs. ile ilgili HİÇ migration yazma. Ben para ile ilgili bölümleri test ediyorum, henüz tamamlamadım, çok eksik var. Bu eksikler için de ayrı migration gerekecek — hepsini birlikte (tek seferde, toplu) yaparız."
- **Kural:** Finans/muhasebe/aidat/gelir-gider/tahakkuk alanlarında YENİ TABLO/MİGRATION yazma — kullanıcı bu alanı aktif olarak test ediyor ve eksikleri topluca tek bir migration'da ele alacak. Bu alanda şema değişikliği gerektiren bir ihtiyaç fark edilirse SADECE not al (aşağıdaki "Eksik/Ertelenmiş Finans Şeması" listesine ekle), migration YAZMA, kullanıcıya sor.

### Eksik/Ertelenmiş Finans Şeması (gelecekteki toplu migration için biriktirme listesi)
- `dues_decisions` tablosu yok — "Aidat Kararları" sekmesi (yönetim kurulu kararıyla aidat tutarı/dağıtım yöntemi belirleme: tutar, karar no, sayfa no, karar tarihi, yürürlük tarihi, özet) için gerekli
- `incomes` tablosu yok — "Gelirler" sekmesi (kira/hizmet/satış/diğer gelir kalemleri: tip, açıklama, tutar, tarih, ödeyen) için gerekli
- (Faz 2 ilerledikçe burada yeni eksikler bulunursa ekle)

---

<!-- Dersler buraya eklenir -->

## Model Varsayımları ve Gerçekçilik

- **Ne oldu:** Antigravity IDE model seçeneklerinde olmayan "Gemini 3.5 Pro" modelinin varlığını varsayıp önerdim.
- **Neden oldu:** Sistem ayarlarını ve metadata'yı tam kontrol etmeden varsayımda bulundum.
- **Kural:** Asla model isimleri, sistem ayarları veya teknik metotlar hakkında varsayım yapma. Sadece doğrulanmış verileri kullan, emin değilsen varsaymak yerine kullanıcıya sor.


---

# 2026-09-13 turunda öğrenilenler

## 1. Finans şeması dondurması KALDIRILDI

- **Ne oldu:** Yukarıdaki "Faz 2 (Finans) — migration ERTELE" talimatı, kullanıcı
  tarafından 2026-09-13'te **açıkça iptal edildi**: *"Yukarıdaki durumdaki süreç iptal.
  Yapılması gereken ne varsa yap."* (questions.md S-02)
- **Kural:** Finans/muhasebe alanında migration yazmak artık serbesttir. Ancak her şema
  değişikliği idempotent olmalı ve `verify-stack.sh` ile doğrulanmalıdır.
- **Sonuç:** `012` (mevzuat parametreleri), `013` (site bazlı roller), `014` (yönetişim)
  migration'ları bu izinle yazıldı. Biriktirme listesindeki `dues_decisions` ve `incomes`
  ihtiyacı, `operating_budgets` + `operating_budget_items` ile büyük ölçüde karşılandı.

## 2. Doğrulama betiği her genişletildiğinde yeni hata buluyor

- **Ne oldu:** `verify-stack.sh` 42 → 102 kontrole çıkarıldı. Eklenen her yeni kontrol
  ortalama bir hata buldu: 002'nin idempotent olmaması, 004'teki trigger, 003'ten DROP
  kaldırılınca ortaya çıkan eski kolonlar, finans uçlarının iki farklı yanıt biçimi…
- **Neden önemli:** Bu hataların hiçbiri **kod okuyarak** bulunamazdı. Statik denetim
  (2026-09-09) 97 mantık hatası buldu ama bunların hiçbirini yakalayamamıştı.
- **Kural:** Bir davranış hakkında iddia varsa, o iddiayı sınayan bir kontrol yazılır.
  "Şuna dikkat ettim" yeterli değildir; betiğe eklenmeyen kontrol yok sayılır.

## 3. Bir yalanı kaldırmak, başka bir yalanı açığa çıkarabilir

- **Ne oldu:** `003`'teki `DROP TABLE audit_logs` kaldırıldı (denetim izini siliyordu).
  Bunun üzerine `001`'in eski tablosu hayatta kaldı ve `resource_type NOT NULL` kısıtı
  `pkg/audit`'in INSERT'ünü kırdı — yani denetim izi yine yazmaz hâle geldi.
- **Kural:** Bir düzeltmenin yan etkisi, düzeltmeyi anlamsız kılabilir. Düzeltmeden
  sonra **aynı davranışı** sınayan kontrol yeniden çalıştırılmalıdır; "düzelttim"
  demek yetmez.

## 4. "Bağlı" yazan bir rozet, olmayan bir entegrasyonu var gösterir

- **Ne oldu:** Panel ayarlarında iyzico, Firebase ve SMTP "Bağlı" görünüyordu; üçü de
  koda hiç bağlanmamıştı. Yönetici tahsilatın çalıştığını sanabilirdi.
- **Kural:** Durum rozetleri (bağlı/aktif/başarılı) **yalnızca** gerçek bir kontrolün
  sonucundan üretilir. Sabit değerden rozet basmak, sahte başarı mesajıyla aynı şeydir.

## 5. Mevzuat oranları koda gömülmez

- **Ne oldu:** Gecikme tazminatı (%5), ısıtma paylaşımı (%70/%30), nisaplar ve vekâlet
  sınırları hiçbir yerde tanımlı değildi; kodlansalardı mevzuat değişiminde yeniden
  dağıtım gerekirdi ve geçmiş dönemlerin hangi oranla hesaplandığı kaybolurdu.
- **Kural:** Hukuki sonuç doğuran her sayısal değer, **yürürlük tarihli** ve **hukuki
  dayanaklı** olarak veritabanında tutulur. Kanunla sabit olanlar (gecikme tazminatı,
  nisaplar) site bazında değiştirilemez — bu, veritabanı tetikleyicisiyle garanti altına
  alınır, arayüz kontrolüne bırakılmaz.

## 6. Para dağıtımında "her payı ayrı yuvarla" sessiz bir hatadır

- **Ne oldu:** Bir gideri dairelere paylaştırırken her payı ayrı yuvarlamak, payların
  toplamının gidere eşit olmamasına yol açar. Kat mülkiyetinde toplanan avans ile gider
  **birebir** örtüşmelidir.
- **Kural:** Dağıtım **en büyük kalan** (largest remainder) yöntemiyle ve tam sayı kuruş
  üzerinden yapılır. Dağıtım ayrıca **belirlenimci** olmalıdır: aynı dönem yeniden
  hesaplandığında daireler arasında kuruş yer değiştirmemelidir.

## 7. Gecikme tazminatı artımlı toplanmaz

- **Ne oldu:** Tazminatı her çalıştırmada mevcut değere **eklemek**, işi iki kez
  çalıştırınca borcu ikiye katlar.
- **Kural:** Tazminat (anapara, gün, oran) fonksiyonudur; her seferinde baştan hesaplanır
  ve **yazılır**. Ayrıca tazminat üzerinden tazminat işlenmez (bileşik faiz; KMK m.20/2
  buna dayanak vermez).

## 8. Alt görev (subagent) kullanırken yarım iş riski

- **Ne oldu:** Beş alt görevden ikisi kota sınırına takılıp yarıda kesildi. Şans eseri
  yazdıkları kod derleniyordu; aksi hâlde depo kırık kalırdı.
- **Kural:** Alt göreve verilen iş, **dosya bazında bölünür** ve her alt göreve
  "bitirme şartı: `analyze`/`build` temiz" denir. Alt görev bittikten sonra ana ajan
  **kendi** doğrulamasını çalıştırır; alt görevin raporuna güvenilmez.

## 9. Panel/mobil ile sunucu arasındaki sözleşme farkı sessiz hataya yol açar

- **Ne oldu:** Finance servisi bazı liste uçlarında düz dizi, bazılarında
  `{"data": [...]}` döndürüyordu. İstemciler tek biçim bekliyordu; sunucu çalışsa bile
  ekran "beklenmeyen hata" gösteriyordu.
- **Kural:** Liste uçları **tek sözleşme** kullanır (`{"data": [...]}`). İstemci tarafında
  ayrıca toleranslı bir yardımcı bulunur; böylece sürüm farkında ekran kırılmaz.

---

## 2026-09-13 (ikinci tur) — FAZ 5 dersleri

### Ders 10 — Kararsız doğrulama betiğinin kanıt değeri yoktur

**Ne oldu:** `verify-stack.sh` aynı kodda bir tur 279/279, bir tur 257/279 verdi.

**Kök neden:** `go run ./services/x &` **iki** süreç yaratır: `go run` sarmalayıcısı
ve derlenmiş ikili. Betik yalnızca sarmalayıcıyı öldürüyordu; ikili ayakta kalıp
portu tutmaya devam ediyordu. Bir sonraki çalıştırmada yeni servis porta bağlanamıyor,
ama sağlık kontrolü **eski sürece** cevap verdiği için "ayağa kalktı" deniyor ve
testler eski veritabanına karşı koşuyordu.

**Kural:** Arka planda süreç başlatan her betik, süreç **ağacını** öldürmek
zorundadır (`pgrep -P` ile özyinelemeli). Ayrıca başlangıçta kullanılacak portlar
süpürülmelidir. Sağlık kontrolünün 200 dönmesi, **senin** başlattığın sürecin
cevap verdiği anlamına gelmez.

**Daha genel kural:** Bir doğrulama iki kez üst üste aynı sonucu vermiyorsa, önce
betiği düzelt — sonuçları yorumlama. Kararsız test, testsizlikten daha kötüdür:
yanlış güven verir.

### Ders 11 — Bir sözleşmenin iki tüketicisi varsa ikisini de sına

**Ne oldu:** Roller JWT claim'ine yazılıyor ama API yanıtına yazılmıyordu. Backend
testleri jetona baktığı için **geçiyordu**; panel ise yanıta baktığı için giriş
yapan herkesi yetkisiz sayıyor ve sonsuz yönlendirme döngüsüne giriyordu.

**Kural:** Aynı bilginin iki taşıyıcısı varsa (jeton claim'i ↔ API yanıt gövdesi,
veritabanı kolonu ↔ önbellek, şema CHECK ↔ koddaki sabit liste), **ikisi de** ayrı
ayrı sınanmalıdır. Birinin doğru olması diğerini kanıtlamaz.

**Uygulama:** `verify-stack.sh` §9'a artık hem jeton hem yanıt kontrol ediliyor.
Aynı ilke `repository.ValidTypes` ↔ migration `CHECK` kısıtı için de geçerli —
bu yüzden kod tarafındaki listeler şemadaki kısıtla birebir aynı tutuluyor.

### Ders 12 — "Kaydediyor" ile "sakladığını söylüyor" farkı diskten doğrulanır

**Ne oldu:** Belge servisi mock'ken "yüklendi" diyip hiçbir şey yazmıyordu. Bunu
yakalayan şey bir HTTP durum kodu değil, **diskte dosyayı arayan** bir kontrol oldu.

**Kural:** Bir modül "sakladım" diyorsa, doğrulama o veriyi **bağımsız bir yoldan**
okumalıdır: HTTP yanıtına değil, doğrudan veritabanına/diske bakarak. Ayrıca
saklananın **bozulmadığı** (SHA-256) ve geri okunduğunda **aynı** geldiği sınanmalı.

### Ders 13 — Fail-closed varsayılanı, alan unutulduğunda da korumalıdır

Belge görünürlüğü belirtilmediğinde **en dar** kademe (`MANAGEMENT`) uygulanır.
Geniş bir varsayılan seçilseydi, `visibility` alanını göndermeyi unutan tek bir
istemci özlük dosyasını tüm sakinlere açardı. Aynı ilke: rol listesi çözülemezse
jeton üretilmez, `AllowedVisibilities` boşsa hiçbir kayıt dönmez.

---

## 2026-09-14 — FAZ 5 tamamlanma dersleri

### Ders 14 — "Yapılmadı" da bir sonuçtur; gerekçesiyle yazılırsa

22 mock servisin ikisi (banka, toplantı sihirbazı) bilerek yazılmadı. Bunları
yarım yamalak yazmak, "tamamlandı" listesine eklemek için kendimizi kandırmak
olurdu. Bunun yerine 501 döndürüp **neden** yazılmadığını, **neyin eksik**
olduğunu ve **nereye gidileceğini** söylüyorlar.

**Kural:** Bir modül yazılmayacaksa, kararın gerekçesi koda ve API yanıtına
yazılır. "Yapılmadı" ile "unutuldu" arasındaki fark, yazılı gerekçedir.

### Ders 15 — Uydurma sayı üretmektense hiç üretme

Üç modül "yapay zekâ" iddiasıyla sayı üretiyordu: enerji tahmini, ödeme
olasılığı, sürdürülebilirlik skoru. Model yok. Bu sayıların hepsi kaldırıldı;
yerlerine formülü kodda yazılı, her sonucu gerekçeli hesaplar kondu.

**Kural:** Bir sayının dayanağını gösteremiyorsan onu üretme. Özellikle:
- Katsayısı dışarıdan gelmesi gereken hesapta (emisyon faktörü) katsayıyı
  **kullanıcıdan iste**, koda gömme.
- Kabul görmüş formülü olmayan bileşik skoru (sürdürülebilirlik) **üretme**.
- Yetersiz veriyle (3 yanıtlık NPS, 1 tahakkukluk risk skoru) üretilen sonucu
  **güvenilmez işaretle**.

### Ders 16 — Aynı kuralı iki katmanda birden uygula

Site ayarlarının mevzuat parametrelerini ezmesi hem uygulamada hem de
veritabanı `CHECK` kısıtında engellendi. Uygulama kontrolü tek başına yetmez:
doğrudan SQL yazan bir betiği ya da ileride yazılacak başka bir servisi bağlamaz.

**Kural:** Bir kural ihlâli geri alınamaz sonuç doğuruyorsa (kanuna aykırı
tahakkuk, silinen borç, kaybolan denetim izi), kuralı veritabanına da yaz.
Salt-ekleme tetikleyicileri, `CHECK` kısıtları ve kısmi tekil indeksler bunun
için vardır.

### Ders 17 — Saklanan türetilmiş değer bayatlar

Amortisman, anket sonucu ve dönem toplamı için şemada saklama kolonları vardı.
Hiçbiri kullanılmadı; hepsi her okumada hesaplanıyor. Doğrulamada kolonlar
**elle bozulup** okumanın değişmediği gösteriliyor.

**Kural:** Türetilmiş değeri saklıyorsan, onu güncelleyen tek bir yol olduğundan
emin ol. Emin olamıyorsan saklama — hesapla. Bayat bir defter değeri, yönetici
devrini ve bütçeyi yanlış temele oturtur.

### Ders 18 — İstemcinin gönderdiği "sonuç"a güvenme, girdisine güven

Tekrar eden kalıp: istemci "tur tamamlandı", "toplam 4.000 TL", "önceki endeks
1000" diyordu. Üçü de sunucuda yeniden hesaplanıyor artık.

**Kural:** İstemci NE YAPTIĞINI söyler, NE OLDUĞUNU değil. Durum, süre, toplam
ve önceki değer sunucudan gelir. Bu bir güvenlik meselesi olmadan önce bir
doğruluk meselesidir: istemcinin saati yanlış olabilir, hesabı eksik olabilir.

### Ders 19 — Yanlış alarm veren kontrol, kontrolsüzlükten kötüdür

Eşzamanlılık testindeki "hareket zinciri" kontrolü, kod doğruyken bile
kopukluk raporluyordu: eşzamanlı kayıtlar aynı zaman damgasına düşünce gerçek
sıra kurulamıyordu. Kontrol, ölçmek istediği şeyi (kayıp güncelleme) doğrudan
ölçecek biçimde yeniden yazıldı.

**Kural:** Bir kontrol başarısız olduğunda önce "bu kontrol doğru şeyi mi
ölçüyor?" diye sor. Yanlış alarm veren kontrol, zamanla görmezden gelinir ve
gerçek hatayı da gizler.

---

## 2026-09-14 — FAZ 2 güvenlik dersleri

### Ders 20 — Güvenlik özelliğinin ÇALIŞTIĞINI görmeden "eklendi" deme

RLS politikaları yazıldı, `FORCE ROW LEVEL SECURITY` açıldı, migration temiz
uygulandı. Her şey "yapılmış" görünüyordu. Doğrulama çalıştırıldığında
kapsamsız sorgu hâlâ satır döndürdü: PostgreSQL'de RLS **süper kullanıcıyı
hiç bağlamaz** ve uygulama süper kullanıcıyla bağlanıyordu.

Kod incelemesiyle bulunamayacak bir şeydi; yalnızca "koruma gerçekten
çalışıyor mu?" diye SORAN bir kontrol buldu.

**Kural:** Bir güvenlik önleminin doğrulaması, önlemin VAR OLDUĞUNU değil
KORUDUĞUNU sınamalıdır. "Politika tanımlı mı?" yanlış soru; "kapsamsız sorgu
sıfır satır mı döndürüyor?" doğru soru.

### Ders 21 — İmza değiştir, genel değişken kullanma

Jeton iptali denetimini `AuthMiddleware`'e eklerken iki yol vardı: paket
düzeyinde bir "kurulmuşsa denetle" değişkeni (çağrı yerleri değişmez) ya da
imzaya parametre eklemek (26 dosya değişir).

Genel değişken seçilseydi, kurulumu unutulan bir servis iptal edilmiş jetonu
SESSİZCE kabul ederdi — ve bu, ancak bir güvenlik olayında fark edilirdi.

**Kural:** Unutulduğunda sessizce güvensiz hâle gelen bir bağımlılık, imzada
yer almalıdır. Derleyicinin yakalayabileceği hatayı çalışma zamanına bırakma.

### Ders 22 — Yarım açılmış koruma, kapalı korumadan kötüdür

RLS'i tüm tablolara açmak cazipti ("2.6 tamamlandı" yazabilmek için). Ama
`units` ve `properties` tablolarını on servis okuyor; hepsi kapsamlı sorguya
geçmeden RLS açmak uygulamayı çalışmaz hâle getirirdi.

Seçilen yol: yalnızca TEK servisin kullandığı tablolarda açmak ve kalan 82
tablonun kapalı olduğunu doğrulamada SAYARAK raporlamak.

**Kural:** Bir korumayı kısmen açacaksan, hangi kısmın korunduğunu ve hangisinin
korunmadığını ölçülebilir biçimde raporla. "Kısmen yapıldı" ancak sınırı
yazılıysa dürüst bir cevaptır.

### Ders 23 — Şifreli alan, doğrulamayı ZORUNLU kılar

Düz metin bir TCKN kolonundaki yazım hatası gözle görülür. Şifreli bir
kolondaki hata görünmez: veri çözülene kadar kimse fark etmez, çözüldüğünde de
"acaba baştan mı yanlıştı?" sorusunun cevabı yoktur.

Bu yüzden TCKN algoritmik sağlaması ve IBAN mod-97 doğrulaması, şifrelemenin
ÖN KOŞULU olarak eklendi — şifrelemenin kendisi kadar önemli.

**Kural:** Bir alanı şifrelemeden önce, o alana yanlış değer yazılmasını
engelleyecek doğrulamayı ekle.

---

## 2026-09-14 — RLS yaygınlaştırma ve bildirim bağlantısı dersleri

### Ders 24 — Korumayı açmadan önce, korunacak verinin ŞEKLİNE bak

`asset_categories` ve `inventory_categories` tablolarına "site kimliği eşitse
gör" politikası yazıldı. Mantıklı görünüyordu ve migration temiz uygulandı.
Ama bu tablolarda `property_id IS NULL` olan ORTAK satırlar vardı (tohum
verisi) ve depo katmanı onları bilerek okuyordu.

Sonuç: politika, her siteden 14 kategoriyi sessizce sildi. Hiç kimse hata
almazdı; kategoriler bir gün "kaybolmuş" olurdu ve sebebi aylar sonra
aranırdı.

**Kural:** Bir tabloya RLS açmadan önce o tablonun satırlarının TÜMÜNÜN aynı
şekilde sahiplendiğini doğrula. Ortak/global satır varsa politika bunu ayrıca
karşılamalı — ve YAZMA tarafı ortak satır üretmeye izin VERMEMELİ.

### Ders 25 — Yanlış ölçü, doğru koruma üzerinde de alarm verir

Doğrulama "kapsamsız sorgu sıfır satır döndürmeli" diyordu. Kategori
tablolarında koruma doğru çalışıyordu ama ortak satırlar döndüğü için kontrol
başarısız oldu. İlk refleks korumayı gevşetmekti; doğrusu ÖLÇÜYÜ düzeltmekti:
"hiç satır dönmesin" değil, **"hiçbir SİTE VERİSİ dönmesin."**

Muafiyet eklerken ikinci bir kontrol de eklendi: ortak satır sayısı tohum
verisine sabitlendi. Böylece muafiyet sessizce genişleyemez.

**Kural:** Bir kontrol beklenmedik şekilde başarısız olduğunda, önce kontrolün
DOĞRU ŞEYİ ölçüp ölçmediğine bak. Ölçüyü gevşeterek geçirmek yerine
keskinleştir; muafiyet açtıysan, muafiyetin sınırını da ölç.

### Ders 26 — Paylaşılan tabloyu kullanan HER servis aynı anda geçmelidir

RLS'i anket tablolarına açarken survey-service `pkg/dbscope`'a geçirildi.
nps-service ayrı tablo açmaz; aynı anket tablolarını kullanır. Yalnızca survey
geçirilseydi, migration uygulandığı an NPS sessizce boş liste döndürmeye
başlardı — çökme yok, hata yok, sadece "veri yok".

Bu, koddan değil, "bu tabloya kim dokunuyor?" sorusunu tabloya göre taramaktan
çıktı.

**Kural:** Bir tabloya RLS açmadan önce o tablonun adını TÜM serviste ara.
Tüketici sayısı birden fazlaysa hepsi aynı dilimde geçirilmeli ya da tablo
sonraki dilime bırakılmalı.

### Ders 27 — "Altyapı hazır" ile "modül kullanıyor" aynı şey değildir

`pkg/notify` günler önce yazıldı, testleri geçti, sağlık ucunda göründü.
Ama hiçbir modül onu ÇAĞIRMIYORDU: altı modül hâlâ "bildirim gönderilmedi"
notu düşüyordu. Altyapı "tamamlandı" sayılmıştı çünkü kendi başına çalışıyordu.

Bir altyapı paketinin bitmiş sayılması için en az bir gerçek çağıranı olmalı;
yoksa yazılanın işe yarayıp yaramadığı bilinmez. Nitekim bağlanırken üç şey
eksik çıktı: alıcı çözümleme yardımcısı yoktu, `Decide`/`Publish`/`CheckIn`
bildirimin ihtiyacı olan bilgiyi döndürmüyordu ve toplu gönderimde dedupe
anahtarı ikinci alıcıyı sessizce düşürüyordu.

**Kural:** Paylaşılan bir paketi "tamamlandı" işaretleme; onu KULLANAN ilk
gerçek akış çalışana kadar bekle. Kullanım, tasarımdaki boşlukları tek başına
tasarımdan daha hızlı gösterir.

### Ders 28 — Durum alanını, olay GERÇEKLEŞTİĞİNDE değiştir

Kargo kaydının durumunu bildirim denenir denenmez `NOTIFIED` yapmak kolaydı.
Ama bildirim oluşmadıysa bu kayıt, kargo kaybolduğunda "sakinin haberi vardı"
diyen yanıltıcı bir delile dönüşürdü — ve bu, sorumluluğun tartışıldığı yerde
gerçeği tersine çevirirdi.

Aynısı ziyaretçi kaydındaki `resident_notified_at` için de geçerli.

**Kural:** Bir olayı belgeleyen alanı, olay GERÇEKTEN gerçekleştiğinde doldur.
Denemeyi belgelemek istiyorsan ayrı bir alan kullan; ikisini karıştırma.

---

## 2026-09-26 — RLS'in son dilimleri ve dağıtım

### Ders 29 — "Filtre var" sanılan yerde filtre yoktu; RLS bunu görünür yaptı

Her depoyu kapsamlı sorguya geçirirken, imzasında `propertyID` OLMAYAN her
fonksiyon bir soru işaretiydi. Beş yerde bu gerçek bir açıktı: talep, ödeme,
itiraz, karar defteri. Hepsinde çağıran taraf "rolü denetledim" diyordu;
kimse "bu kayıt benim sitemin mi?" diye sormamıştı.

**Kural:** Kimlikle kayıt getiren/değiştiren her fonksiyon site kimliğini de
alır ve sorguda kullanır. Rol denetimi YETKİ sorusudur, sahiplik sorusu değil;
ikisi ayrı ayrı yapılır. Yeni depo fonksiyonu yazarken imzada `propertyID`
yoksa bu bir tasarım hatasıdır.

### Ders 30 — Görünümler RLS'i sessizce atlar

PostgreSQL'de görünüm, alttaki tabloya varsayılan olarak SAHİBİNİN yetkisiyle
erişir. Sahip süper kullanıcıysa RLS hiç uygulanmaz. Tablo korunuyor sanılırken
görünüm üzerinden tüm siteler okunabiliyordu.

**Kural:** Her görünüm `security_invoker = true` ile yaratılır. Doğrulama,
bu seçeneği taşımayan görünüm kalırsa başarısız olur — yeni görünümler de.

### Ders 31 — Doğrulama ortamında çalışan güvenlik, dağıtımda çalışmıyor olabilir

RLS dev-up ve verify-stack'te uygulama rolüyle sınanıyordu ve geçiyordu. Ama
`docker-compose.yml` servisleri SÜPER KULLANICIYLA bağlıyordu ve 18 serviste
veritabanı ayarı hiç yoktu. "RLS çalışıyor" iddiası yalnızca test ortamında
doğruydu.

**Kural:** Bir güvenlik özelliği, dağıtım yapılandırması da aynı kaynaktan
üretilip doğrulanmadıkça "tamamlandı" sayılmaz. Servis listesi tek yerde
(`gen-deploy.py`) tutulur; compose/k8s/CI ondan üretilir ve doğrulama sapmayı
yakalar. Tercihen gerçek imajlarla bir duman testi de yapılır.

### Ders 32 — `cmd | grep -q` + `pipefail` = yanlış başarısızlık

`grep -q` ilk eşleşmede boruyu kapatır; yazmaya devam eden komut SIGPIPE ile
düşer ve `pipefail` altında boru hattı başarısız görünür. Komutun çıktısına
yeni bir satır eklenmesi (rol ataması), dokunulmamış bir kontrolü bozdu.

**Kural:** Doğrulama betiklerinde çıktıyı önce dosyaya al, sonra grep'le.


### Ders 33 — Bakım aracının "iş kalmadı" demesi, hiçbir şey görmediği anlamına gelebilir

`cmd/encrypt-pii` site listesini `properties`'ten okuyordu. `properties` RLS
altında olduğu için uygulama rolüyle çalıştırılan araç SIFIR site görüyor ve
"şifrelenecek düz metin kayıt yok" diyordu. Aynı kalıbı kopyalayan anahtar
döndürme aracı "eski anahtarla kayıt kalmadı" diyecek, operatör eski anahtarı
silecek ve veri okunamaz kalacaktı.

**Kural:** Tüm siteleri dolaşan araç, başlamadan önce rolünün bütün siteleri
görebildiğini doğrular (`dbscope.RequireAllSitesRole`); göremiyorsa çalışmaz.
"Sıfır sonuç" raporu ancak taramanın kapsamı kanıtlandıysa anlamlıdır.

### Ders 34 — Anahtar türetmesini değiştirmek, anahtarı değiştirmek demektir

Arama anahtarını (blind index) HKDF ile ayrı türetmek doğru bir düzeltmeydi ama
anahtar aynı kalsa bile mevcut kayıtların arama anahtarı yeni koddan farklı
çıkıyordu. Benzersiz indeks yalnızca aynı anahtarla üretilmiş değerleri
karşılaştırdığı için, aynı TCKN'li ikinci aktif personel SESSİZCE açılabilirdi.

**Kural:** Şifreleme/özet biçimi değişen her alanda eşitlik denetimi, halkadaki
bütün anahtarların (eski biçim dahil) aday değerleriyle yapılır
(`BlindIndexCandidates`); indeks yalnızca aynı anahtarlı eşzamanlı yazımları yakalar.

### Ders 35 — WSL'e komut geçirirken `$` dış kabukta açılır

`wsl -- bash script 'cmd; echo $?'` biçiminde `$?` ve `$PATH` WSL'in varsayılan
kabuğunda, komut ÇALIŞMADAN önce açıldı: doğrulama başarısızken "EXIT=0" yazdı.

**Kural:** WSL'de `wsl -e bash <betik>` kullan; komutu argüman olarak değil
betik dosyası olarak ver. Ayrıca servis günlükleri JSON'dur: tırnaklı metin
günlükte `\"` olarak geçer, grep deseni bunu kapsamalıdır.

### Ders 36 — Durum değişmeden de geçen kontrol, kontrol değildir

"Ödeme sonrası has_debt:false" kontrolü haftalarca geçti; çünkü bakiye hiç
yazılmayan bir tablodan okunuyordu ve ödemeden ÖNCE de false'tu. Kontrol
çıktıyı sınadı ama değişimi sınamadı.

**Kural:** Bir durum değişikliği sınanırken hem ÖNCEKİ hem SONRAKİ değer
ölçülür ve fark beklenen tutara eşit olmalıdır. Hesaplanan değer, sistemden
BAĞIMSIZ bir hesapla (doğrudan SQL) karşılaştırılır. Bir görünüm/tablo
okunuyorsa, ona gerçekten yazan bir kod yolu olduğu `git grep` ile doğrulanır.

### Ders 37 — Yetkiye dönüşen her değer, yazıldığı yerde kısıtlanır

`resident_units.role` "sakinlik bilgisi" gibi görünüyordu, ama jeton rollerine
olduğu gibi giriyordu. Değer serbest metin olduğu için sakin ekleme formu fiilen
bir "rol verme" ucuna dönüşmüştü. Kimse fark etmedi; çünkü yetki denetimi rolü
OKUYAN tarafta yapılıyordu, rolü YAZAN tarafta değil.

**Kural:** Yetki kararına giren her kolon için (rol, kapsam, sahiplik) hem
uygulamada izin listesi hem veritabanında CHECK/FK olur. Rolü türeten sorgu da
yalnızca beklenen değerleri alır — eski bir hatalı satır yetki vermesin.
Yeni bir rol kaynağı eklerken "bu kolona kim yazabiliyor?" sorusu sorulur.

### Ders 38 — "Yeni kod doğru" demek, eski yolun da doğru olduğu anlamına gelmez

Kuruş dağıtımı (`pkg/money`) yazıldığında madde "tamamlandı" işaretlendi; not
"yeni yazılan tüm para kodu kuruş kullanıyor" diyordu. Aynı işi yapan ESKİ yol
(finans servisinin tahakkuk oluşturması) float64 ile çalışmaya devam etti ve
hiçbir doğrulama onu çağırmıyordu.

**Kural:** Bir hesap kuralı (kuruş, nisap, oran) merkezîleştirildiğinde aynı
hesabı yapan BÜTÜN yollar `git grep` ile bulunur ve ya merkeze bağlanır ya da
silinir. Doğrulama, ucu çağırmayan bir kontrolle "geçti" sayılamaz.

### Ders 39 — "Bugün" iki ayrı saatle hesaplanıyorsa, gece yarısı hata çıkar

Görev başlangıcı Go'da `time.Now()` ile (UTC+3), geçerlilik denetimi veritabanında
`CURRENT_DATE` ile (UTC) yapılıyordu. Gündüz koşan doğrulama hep geçti; gece 01:00'de
koşunca bugün verilen rol "yarın başlıyor" sayıldı. Saat dilimi hiçbir yerde
ayarlanmamıştı.

**Kural:** İş günü TEK saat diliminden gelir (`APP_TIMEZONE`); Go süreci ve her
veritabanı oturumu ona sabitlenir. Tarih varsayılanı mümkünse veritabanında verilir
(`COALESCE($1, CURRENT_DATE)`). Tarihe bağlı doğrulamalar gece yarısı civarında da
koşulur.

### Ders 40 — Desene göre satır silmeden önce eşleşme sayısına bak

Betikten kendi eklediğim bir satırı "ilk eşleşen satırı sil" ile kaldırdım; o
satır zaten önceki adımda gitmişti ve ilk eşleşme 19. adımdaki ESKİ bir satırdı.
Doğrulama bozuldu, `git diff` ile fark edip geri aldım.

**Kural:** Düzenlemeden sonra `git diff --stat` / diff hunk'larına bakılır; desene
göre silme yapılacaksa önce eşleşme sayısı ve konumu doğrulanır.

### Ders 41 — Mevzuat koda girdiyse, yürürlükteki metin periyodik kontrol edilir

İşletme projesinin "7 günde kesinleşmesi" kuralı 2026-09'da doğru yazılmıştı; 7579 s. Kanun
22/5/2026'da bunu kaldırdı ve sistem dört ay boyunca mülga kuralla "İİK m.68 belgesi" üretti.
`legal_parameters` yürürlük tarihli olduğu için oran değişikliği kolaydı; ama kural (akış) koddaydı.

**Kural:** Yeni işe başlamadan önce ilgili kanunun mevzuat.gov.tr konsolide metni okunur ve son
değişiklik tablosuna (dipnotlar, "Değişik/Mülga … tarih") bakılır. Akışı değiştiren değişiklik varsa
önce o düzeltilir. Parametre kapatılırken satır silinmez, `effective_to` verilir (geçmiş hesap korunur).

### Ders 42 — Betiğe metin eklerken son satır sonunu da ekle

PowerShell here-string son satır sonunu taşımaz; verify-stack'e eklediğim blok bir sonraki
komutla aynı satıra yapıştı (`...head -1)N=$(qapp ...`) ve ilgisiz bir kontrol düştü.

**Kural:** Eklemeden sonra eklenen bloğun son ve sonraki satırı `git diff` ile gözle kontrol edilir.

### Ders 43 — `pipefail` altında `echo büyük | grep -q` yanlış negatif verir

`grep -q` eşleşmeyi bulunca erken çıkar; büyük girdide `echo` SIGPIPE (141) alır ve
`set -o pipefail` boru hattını başarısız sayar. Metrik çıktısı sınamasında doğru çıktı
"başarısız" göründü.

**Kural:** Doğrulama betiğinde büyük metinde arama `grep -q … <<<"$VAR"` ile yapılır.

### Ders 44 — Ters eğik çizgiyle devam eden komutun ortasına satır eklenmez

verify-stack'te `DB_HOST=… \` ile başlayan ortam önekli `go run` komutunun arasına dizin
hazırlama satırı eklendi; önek o satırdaki komuta bağlandı, servis varsayılan kullanıcıyla
açılmaya çalıştı ve "başlamadı" hatası verdi.

**Kural:** Devam satırlı (`\`) komuta ön hazırlık eklenecekse komutun TAMAMININ önüne yazılır.

### Ders 45 — Uygulama rolüyle çalışan arka plan işi `properties`'i göremez

Kargo servisinin silme kuyruğu işçisi siteleri `SELECT id FROM properties` ile buluyordu; RLS
yüzünden hiç satır dönmedi, hata da üretmedi (sessiz). Test "kuyruk boşalmadı" diye yakaladı.

**Kural:** Siteler arası tarama yapan iş yalnızca kimlik dönen `SECURITY DEFINER` fonksiyonla
(028 deseni) site listesini alır, her siteyi kendi kapsamıyla işler.

### Ders 46 — `ALTER DEFAULT PRIVILEGES` + `pg_restore`, göçlerin REVOKE'larını sessizce geri alır

Yedekten geri yüklemede tablolar yeniden oluşturulurken 020'deki varsayılan yetkiler uygulama rolüne
SELECT/INSERT/UPDATE/DELETE veriyordu; pg_dump ise tablo yetkilerini "yalnızca sahip" başlangıcına göre
yazdığı için bu fazlalığı geri almıyordu. Sonuç: göçlerin kaldırdığı UPDATE/DELETE geri yüklemeden sonra
geri geliyor, ödeme/defter korumaları düşüyordu. Doğrulamanın geri yükleme parmak izi ACL'i içermediği için
görülmedi; borcu yoktur belgesi testi geri yüklemeden SONRA çalıştığı için yakaladı.

**Kural:** Geri yükleme varsayılan yetkileri askıya alır (`db-restore.sh`); geri yükleme parmak izi tablo
ACL'lerini (NULL = `acldefault`) içerir. Yetki koruması sınanırken testin sırası (yedek/geri yükleme
öncesi mi sonrası mı) göz önüne alınır.

### Ders 47 — Hata yolundaki güncelleme bir kısıta takılırsa kayıt "ara durumda" kalır

Kart ödeme sayfası açılamadığında ödeme FAILED yapılıyordu; ama `gateway` sütunu henüz boştu ve
`gateway_status IS NULL OR gateway IS NOT NULL` kısıtı güncellemeyi reddetti. Hata yalnızca günlüğe
yazıldı, ödeme PENDING kaldı ve aynı tahakkuk için yeni denemeyi ("onay bekleyen ödeme var") engelleyecekti.
HTTP yanıtı doğruydu (502); kusuru yalnızca veritabanı durumunu soran test yakaladı.

**Kural:** Hata/geri alma yolunun testi HTTP kodunu değil kalıcı durumu denetler (satır son hâli +
"yeniden deneme açık mı"). Durum makinesine yeni kısıt eklerken her geçiş yolunun (başarısızlık dahil)
kısıtı sağladığı sınanır.

### Ders 48 — psql'de mantıksal değer birleştirilince "t" değil "true" yazar

`SELECT x || '|' || (a = b)` çıktısı `…|true` olur; yalın `SELECT (a = b)` ise `t`. Aynı turda iki kez
yanlış beklenti yazıldı (A7 ve A12). **Kural:** Birleştirilmiş mantıksal değerde `true/false`, yalın
sütunda `t/f` beklenir.

### Ders 49 — Şikayet raporundan iş çıkarırken işletme kararları kapsam dışıdır

Şikayetvar'dan türetilmiş rapor değerlendirilirken komisyon, ücret gösterimi ve gecikme tazminatının
başlangıç günü gibi konularda öneri yazıldı. Kullanıcı düzeltti: komisyonsuz işletme yaşayamaz; para,
faiz ve sözleşme kararları işletmenindir. **Kural:** Ürün/şikayet analizinde yalnızca uygulama
aksaklıkları ve olsa iyi olacak özellikler değerlendirilir; işletme kararı olan maddeler "kapsam dışı"
yazılıp geçilir, öneri üretilmez.

### Ders 50 — `grep -c … || echo 0` eşleşme yokken iki kez "0" yazar

`grep -c` eşleşme bulamayınca hem `0` yazar hem 1 ile çıkar; `|| echo 0` ikinci bir `0` ekler ve değişken
`"0\n0"` olur — karşılaştırma sessizce düşer. B3 doğrulamasında kod doğruyken kontrol iki tur kırmızı kaldı.
Aynı turda `(a IS NULL)||'|'||…` biçiminde MANTIKSAL değerle BAŞLAYAN birleştirmenin boş döndüğü sanıldı;
asıl neden buydu (Ders 48'in tersi değil). **Kural:** Sayaç için `n=$(grep -c … 2>/dev/null); echo "${n:-0}"`;
kırmızı kontrolde önce hata satırının TAMAMINI (`grep -A`) oku, tahminle düzeltme yapma.

### Ders 51 — Test beklentisini veriden hesapla, kafadan yazma

B8 doğrulamasında sapma oranı "8,70" diye sabit yazıldı; bölümlerin hepsinde kullanım alanı olduğu için hesap m² başına
yapıldı ve oran 8,63 çıktı. Kod doğruydu, test yanlış varsayımla kırmızı kaldı. **Kural:** Birden çok veri kaynağına bağlı
sayısal sonuçta testte ya kuralı (`> 3`) denetle ya da beklenen değeri aynı yanıttan oku; sonucu ezbere sabitleme.

### Ders 52 — Uygulanmış migration'daki işlevin dönüş tipini sonraki migration'da değiştirme

D5'te (070) 055'teki `verify_clearance_certificate` işlevi `DROP` + yeni dönüş tipiyle yeniden yazıldı. Doğrulamanın
"migration'lar yeniden uygulanabilir" adımı 055'i tekrar çalıştırınca `CREATE OR REPLACE` dönüş tipi uyuşmazlığıyla düştü.
**Kural:** Var olan bir SQL işlevinin imzası/dönüş tipi değişecekse yeni adla (`…_scoped`, `…_v2`) yeni işlev yaz; eskisine
dokunma. Aynı şey görünüm sütunları için de geçerli (`CREATE OR REPLACE VIEW` sütun silemez/yeniden sıralayamaz).

### Ders 53 — Yanıt kodunu varsayma, mevcut testten oku

D5 adım 61'de ödeme bildiriminin 201 döndüğü varsayıldı; uç 200 döner (B4'teki hane testi zaten `!= 201` ile yazılmıştı).
**Kural:** Var olan bir ucu yeni testte kullanırken önce o uç için yazılmış eski kontrolün beklediği kodu ara (`grep`).

### Ders 54 — AFTER ROW tetikleyicisi çok satırlı INSERT'in sonunda çalışır

D7 testinde malik, kiracı ve hane üyesi tek `INSERT … VALUES (…), (…), (…)` ile eklendi. Kiracı gelişi tetikleyicisi
(068, AFTER INSERT FOR EACH ROW) deyim SONUNDA çalıştığı için aynı deyimdeki hane kaydını "önceki hane" sanıp bitirdi.
Kod doğruydu; kurgu yanlıştı. **Kural:** Sırası anlam taşıyan kayıtları (kiracı → hanesi) ayrı deyimlerle ekle. Rol
içeren jetonlar girişte hesaplanır: test kurgusunu bitirdikten SONRA giriş yap.
### Ders 55 — "Çalışıyor" demeden önce kullanıcının gireceği yolu dene

2026-10-25'te proje çalıştırıldı ve giriş gateway'e doğrudan `curl` ile denenip "çalışıyor" denildi. Panel ise
`admin/.env.local`'daki `NEXT_PUBLIC_API_URL=…/api` (doğrusu `/api/v1`) yüzünden `/api/auth/login`'e gidiyordu;
gateway 401 döndü, kullanıcı "şifre hatalı" gördü. **Kural:** Paneli çalıştırdım demeden önce girişi panelin kendi
NextAuth akışından dene (`/api/auth/csrf` → `/api/auth/callback/credentials` → `/api/auth/session`). Giriş bilgileri
ve doğru env tek yerde: `docs/yerel-calistirma.md`; oradan oku, kafadan yazma.

### Ders 56 — Paralel alt ajan açma; oturum token limitini bir anda tüketir

2026-10-25'te özellik haritası için 7 alt ajan paralel başlatıldı; Claude'un 5 saatlik oturum limiti ~10 dakikada
bitti, hiçbir ajan çıktı yazamadı. **Kural:** Kullanıcı açıkça istemedikçe alt ajan açma. Büyük envanter işlerini
tek başına, parça parça yap: tüm dosyayı okumak yerine `grep` ile düğme/uç/bildirim satırlarını çıkar, her bölümü
bitirince diske yaz.

### Ders 57 — Yetki sınırını özetten değil, el yordamından değil, KODDAN oku

2026-10-26'da panelde ziyaretçi kodu yenileme (P10) "backend yalnız kaydı açana izin veriyor" diye yazılmadı ve
06 dosyasına bu gerekçe yazıldı. `services/visitor/pass.go:211` okununca `hasSecurityScope` (yönetim + görevli)
da yenileyebildiği görüldü; özellik eklendi. **Kural:** Bir işlemi "yetki yok" diye atlamadan önce ilgili handler'ı
ve kullandığı kapsam işlevini oku; bağlam özetindeki iddiaya dayanma.

### Ders 58 — Harita aracı dinamik yolu göremez; eşitlik ölçümünde yolu çağrıda açık yaz

`apiClient.post('/visitors/$id/$action')` gibi değişkenli yollar ve `openDownload(context, '/x')` gibi yardımcılar
çağrı grafiğinde görünmüyordu; "eksik" listesine 20 yanlış alarm düştü. **Kural:** İstemcide yol, çağrının içinde
düz metin olsun (`switch (action) { 'x' => apiClient.post('/a/x'), … }`); yeni bir indirme/yükleme yardımcısı
yazılırsa `docs/ozellik-haritasi/arac/{consumers,dart_outline}.py` içindeki `GEN` desenine eklenir.

### Ders 59 — "Çalışıyor" demeden önce gerçek tarayıcıda gez; birim testi ve analiz yerel veri hatasını görmez

Yönetici uygulamasında `DateFormat(..., 'tr_TR')` kullanılıyordu ama `initializeDateFormatting('tr_TR')` hiç
çağrılmıyordu: tarih gösteren her ekran `LocaleDataException` atıyordu. `flutter analyze` temiz, 35 test geçiyordu,
APK derleniyordu — hiçbiri yakalamadı. Web derlemesini headless Chrome ile her rotada gezince `client_error_reports`'ta
çıktı. **Kural:** Yeni ekran/biçimleyici eklendikten sonra uygulama gerçekten açılıp gezilir; istemci hata tablosu
(`client_error_reports`) boş olmalı.

### Ders 60 — Araç sürümü ve süreç adı varsayımları sessizce bozulur

(1) Go 1.24+ `go run` ikilisini önbellekte `<özet>-d/<ad>` olarak tutuyor; `dev-up.sh --stop`'taki `pkill -f exe/<ad>`
kalıpları hiçbir şeyi öldürmüyordu ve servisler arkada çalışmaya devam ediyordu. Süreç, tuttuğu portla
(`fuser -k`) durdurulur. (2) `verify-mobile.sh` PATH'te önce bulduğu Flutter'ı (snap 3.38) kullanıyordu: bağımlılıklar
çözülmüyor, eski sürümün yazdığı `build/unit_test_assets` sonraki doğru sürümdeki testi de bozuyordu. Projenin
Flutter'ı (`~/flutter`) PATH'in önüne alınır. (3) `pkill -f` kalıbı geniş olursa komut satırında o metni taşıyan
başka kabukları (araç çağrıları dahil) öldürür; kalıp `^bash \S*scripts/dev-up\.sh$` gibi çapalanır.

### Ders 61 — İstenen işin boyutunu aşma; önce en kısa yoldan istenen çıktıyı ver

Kullanıcı "mevcut haritayı test için birleştir, ajana vereceğim" dedi; ben test ortamı, sahte sağlayıcılar, web derlemesi,
otomatik tarama ve 1152 testlik üretici yazdım. Kullanıcı: "test etsen daha az token harcardın." **Kural:** İstenen çıktıyı
önce en sade hâliyle teslim et; kapsamı büyütecek ek işleri (altyapı, araç, otomasyon) yapmadan önce tek cümleyle sor.

### Ders 62 — Bir hatayı düzeltirken kullanıcının kararı olmayan yeni mekanizma ekleme

Pazaryeri planını gözden geçirirken bulduğum sorunları kendi icat ettiğim kurallarla "düzelttim": öncelik penceresi (kullanıcı
"SMS ücretli pakette" demişti), ücreti alıcı tipine göre bölme ("kategoriye göre sabit" denmişti), 72 saatte otomatik iade, kart iadesi
altyapısı. Kullanıcı "sırf bir yanlışı düzeltmek için istenmeyen bir şey yaptın mı" diye sordu; dördü de istenmemişti. **Kural:** Bulunan
sorunun düzeltmesi kullanıcının verdiği bir kararı değiştiriyor ya da yeni bir kural/mekanizma ekliyorsa uygulamadan önce sor; önce
kullanıcının kendi kararları içinde kalan en sade düzeltmeyi ara (ör. ayrı ücret boyutu yerine ayrı kategori).
