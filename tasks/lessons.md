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

