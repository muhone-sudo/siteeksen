# ROADMAP

**Bu dosya 2026-09-09'da sıfırdan yeniden yazıldı.** Önceki sürüm, denetimde iddialarının %49'u yanlış
çıktığı için geçersiz kabul edildi (bkz. `tasks/audit-raporu.md`). Eski sürüm git geçmişinde durmaktadır.

Tek doğruluk kaynağı: **bu dosya**. Kökteki `ROADMAP.md` yalnızca buraya işaret eder.

---

## Nasıl okunur

Durum göstergesi olarak `✅` **kullanılmaz**. Yerine kanıt seviyesi yazılır
(tanımlar: `tasks/dogrulama-politikasi.md` §1 ve §5):

| Etiket | Anlam |
|---|---|
| `[D4]` | Canlı doğrulandı — kanıt satırı zorunlu |
| `[D3]` | Otomatik test geçiyor |
| `[D2]` | Derleniyor / statik denetim temiz |
| `[D1]` | Kod var, doğrulanmadı |
| `[D0]` | Planlandı |
| `[MOCK]` | Arayüz/uç nokta var, veri **kalıcı değil** |
| `[ÖLÜ]` | Kod var, hiçbir yere bağlı değil |
| `[KIRIK]` | Yazılmış ama çalışmıyor |
| `[BLOKE]` | Dış karara bağlı — `questions.md` soru numarası yazılır |

**Kural:** Kanıt satırı olmayan madde `[D1]`'den yükseğe çıkamaz.

---

## Bugünkü gerçek durum (2026-09-09)

| Ölçüt | Değer |
|---|---|
| Gerçek veritabanına bağlı servis | **3 / 25** (identity, finance, community) |
| Temiz makinede veritabanı kurulabiliyor mu | **HAYIR** (migration 004 ve 005 çöküyor) |
| `go build ./...` | **BAŞARISIZ** (kırık import) |
| Denetim izi (audit log) çalışıyor mu | **HAYIR** (kolon uyuşmazlığı, tablo boş) |
| Sıfırdan kurulumda demo giriş | **ÇALIŞMIYOR** (bozuk bcrypt hash) |
| Gateway/Kong'da kimlik doğrulama | **YOK** |
| Gerçek test kapsamı | **~%0,5** |
| P0 modüllerin ortalama kapsamı | **~%12** |
| Uçtan uca gerçekten çalışan modül | **2** (Sakinler/Birimler, Talepler) |
| Admin panel derleniyor mu | **EVET** — `npm run build` → 21 sayfa, çıkış kodu 0 *(fiilen çalıştırıldı)* |

Ayrıntı: `tasks/audit-raporu.md` · Modül matrisi: `tasks/gap-analizi.md` Bölüm A

---

## Çalışma ilkesi: dikey dilim

Denetimin **KN-5** kök nedeni: 25 servis / 61 tablo / 37 ekran açıldı, hiçbiri bitmedi (%77 ölü şema).
Bu yüzden bundan sonra iş **dikey dilim** halinde yapılır:

> Bir dilim, **şema → servis → API → gateway → panel → mobil → test → doküman** hattının
> tamamında bitmeden yeni dilim açılmaz.

Yeni modül açmak yerine, mevcut `[MOCK]` modülleri sırayla gerçek hale getirmek tercih edilir.
Gerçek hale getirilmeyecek modüller **arayüzden kaldırılır** ya da açık `DEMO VERİ` etiketiyle işaretlenir
(karar: `questions.md` S-03, varsayılan: daralt ve derinleştir).

---

# FAZLAR

## FAZ 0 — Dürüstlük Onarımı `[TAMAMLANDI — 2026-09-13]`

> Uydurma veri ve sahte başarı mesajı kalmadı. Kalıcı olmayan hiçbir uç 2xx dönmüyor.
> **Kanıt:** `verify-stack.sh` §7, `verify-mobile.sh` dürüstlük kontrolleri.

**Amaç:** Sistemin kullanıcıya yalan söylemesini durdurmak. Hiçbir yeni özellik yok; yalnızca
"yapıldı" diyen ama yapmayan davranışların kaldırılması. Bu faz, güvenin ön koşulu.

| # | İş | Durum | Kanıt / not |
|---|---|---|---|
| 0.1 | Giriş şifresinin sunucu log'una yazılmasını kaldır | `[D0]` | `route.ts:17` — KVKK ihlali, en acil madde |
| 0.2 | Admin panelde 9 sessiz mock fallback'i kaldır → hata durumu göster | `[D0]` | B79; `npm run build` ile doğrulanabilir |
| 0.3 | Sahte "kaydedildi/gönderildi" mesajlarını kaldır (admin panel 3, yönetici mobil 11, sakin mobil 4) | `[D0]` | B81 |
| 0.4 | Credentials sayfasındaki uydurma şifre gösterimini kaldır | `[D0]` | B80 |
| 0.5 | Sahte soft-delete'i kaldır: backend'de silme yoksa buton da olmayacak | `[D0]` | B83, B60 |
| 0.6 | Kaydetmeyen 22 servis ucunu `501 Not Implemented`'a çevir | `[D0]` | B78; politika §3.5 |
| 0.7 | `ai_enabled: true` gibi yanlış sağlık bilgilerini gerçek yapılandırmadan türet | `[D0]` | B84 |
| 0.8 | "API Ayarları" ekranındaki yanlış güvence metnini kaldır | `[D0]` | B85 |
| 0.9 | Mobilde sessiz boş-listeye düşmeyi kaldır → hata + yeniden dene | `[D0]` | B82 |
| 0.10 | Erişilemeyen ekranları menüye bağla **ya da** router'dan kaldır | `[D0]` | B89, B90, B91 (admin panelde çıkış butonu yok) |
| 0.11 | Hukuki metinlerdeki doğrulanamayan taahhütleri düzelt | `[D0]` | B86 |

**Çıkış ölçütü:** Arayüzde, gerçekten yapılmayan hiçbir işlem için başarı mesajı gösterilmiyor.

## FAZ 1 — Kurulabilirlik `[TAMAMLANDI — 2026-09-13]`

> Sürüm takipli migration çalıştırıcı, tam idempotency, port/CI/compose düzeltmeleri.
> 1.6 (2026-09-27): geri alma yedekten geri yükleme ile; verify-stack adım 41.
> **Kanıt:** `verify-stack.sh` §2 ve §4.

**Amaç:** Temiz bir makinede `docker compose down -v && up` ile sistemin ayağa kalkması.
Bugün bu mümkün değil; mevcut ortam elle müdahalelerin toplamı ve kaybolursa geri getirilemez.

| # | İş | Durum | Kanıt / not |
|---|---|---|---|
| 1.1 | Migration 004 `expense_categories` çakışmasını gider | `[BLOKE]` S-02 | B01 — finans şeması, dondurma kapsamında olabilir |
| 1.2 | Migration 005 `vehicles` çakışmasını gider | `[D0]` | B02 — 29 tablonun oluşmasını engelliyor |
| 1.3 | Migration 006'nın var olmayan tabloları ALTER etmesini düzelt | `[D0]` | B03 |
| 1.4 | Migration'ları idempotent yap (`IF NOT EXISTS`, `ON CONFLICT`) + transaction sarmalaması | `[D0]` | B08 |
| 1.5 | **Migration çalıştırıcı** ekle (sürüm tablosu + kilit + eksikleri uygula) | `[D0]` | B05 — üç kez elle uygulama acısının kalıcı çözümü |
| 1.6 | Geri alma — karar: ileri yönlü migration + yedekten geri yükleme (`db-backup.sh`/`db-restore.sh`, runbook) | `[D2]` | — |
| 1.7 | Seed'i `initdb.d` dışına taşı; demo şifre hash'ini bilinen bir şifreyle yeniden üret | `[D0]` | B06 — sıfırdan kurulumda giriş çalışmıyor |
| 1.8 | Seed verisi tutarsızlığını düzelt (arsa payı toplamı, birim sayısı) | `[D0]` | B15 |
| 1.9 | `go build ./...` çalışacak hale getir (`backend/api/` ölü dizinini kaldır) | `[D0]` | B04 |
| 1.10 | 13 servisin `main.go` default portunu compose ile eşitle; çakışmaları gider | `[D0]` | B13 |
| 1.11 | `firebase-credentials.json` mount'unu koşullu yap | `[D0]` | B07 |
| 1.12 | CI: Go sürümünü `go.mod` ile eşitle; `\|\| true` kaldır; Trivy kapısı; `go build ./... && go vet ./...` | `[D0]` | B09, B10, B11 |
| 1.13 | `003`'ün `audit_logs` DROP'unu ALTER'a çevir | `[D0]` | B14 |

**Çıkış ölçütü:** Temiz makinede `docker compose up` → tüm migration'lar uygulanır, demo kullanıcıyla giriş yapılır.
**Kanıt gereksinimi:** `[D4]` için Docker gerekli → `questions.md` S-01.

## FAZ 2 — Kimlik, Yetki ve İzolasyon `[ÇEKİRDEK TAMAM — 2026-09-13]`

> Gateway/Kong kimlik doğrulaması, site bazlı roller, aktif site sahiplik doğrulaması,
> sunucu ve panel RBAC tamamlandı. **Kalan:** PostgreSQL RLS (2.6), çıkışta jeton
> iptali (2.7), alan düzeyi şifreleme (2.8).
> **Kanıt:** `verify-stack.sh` §8 ve §9.

**Amaç:** Hassas verinin internete açık olmaması ve bir sitenin verisinin diğerine sızmaması.

| # | İş | Durum | Kanıt / not |
|---|---|---|---|
| 2.1 | Gateway'e zorunlu JWT doğrulama (allowlist: `/health`, `/auth/*`) | `[D0]` | B17 — en kritik güvenlik açığı |
| 2.2 | Kong'a `jwt` plugin'i; rate-limiting'i 24 servise yay | `[D0]` | B17, B31 |
| 2.3 | 22 servise `AuthMiddleware` (savunma derinliği) | `[D0]` | B17 |
| 2.4 | CORS'u origin allowlist'e çevir | `[D0]` | B31 |
| 2.5 | `JWT_SECRET` boşsa başlatmayı durdur; `WithValidMethods`; compose default'unu kaldır | `[D0]` | B20 |
| 2.6 | `POST /users/me/active-property` sahiplik doğrulaması | `[D0]` | B18 — tenant izolasyonunun tek dayanağı |
| 2.7 | Rolleri `(user_id, property_id)` çiftine bağla; JWT'ye aktif site rolleri | `[D0]` | B19 |
| 2.8 | `RequireRole`'ü tüm yönetim uçlarına uygula; rol/yetki matrisi | `[D0]` | B28, M-60 |
| 2.9 | Admin panelde rol bazlı görünürlük + sunucu tarafı zorlama | `[D0]` | B28 |
| 2.10 | Yönetici mobilde RBAC fail-open'ı düzelt; `AUDITOR` kısıtı | `[D3]` 2026-10-03 — menü fail-closed, rolsüz kullanıcıya açıklama ekranı; 4 birim testi (cihazda denenmedi) | B26 |
| 2.11 | Yönetici mobilde router auth guard | `[D3]` 2026-09-27 — `app_router.dart` redirect | B27 |
| 2.12 | Gerçek çıkış: token denylist (Redis) + mobilde token silme | `[D0]` | B29 |
| 2.13 | Refresh/access token türü ayrımı (`typ` claim) + rotasyon + yeniden kullanım tespiti | `[D0]` | B30 |
| 2.14 | IDOR kapatma: `GET /assessments/:id`, ödeme sahipliği, talep site kontrolü | `[D0]` | B23, B24, B64 |
| 2.15 | `CreateResident`'ın başka siteye ait kullanıcıyı sessizce bağlamasını engelle | `[D4]` 2026-10-03 — bu siteyle bağı olmayan hesap 409, ad/e-posta sızmıyor; aynı sitede ikinci daire çalışıyor; başka sitedeki kişi uygulama içi davetle eklenir (032, S-20) — verify §39 | B25 |
| 2.16 | TCKN/telefon şifreleme (`pkg/encryption`'ı bağla) + maskeleme + erişim denetimi | `[D4]` personel TCKN/IBAN (`pkg/pii`, verify §31); kullanıcı telefonu düz metin (giriş anahtarı) | B36 |
| 2.17 | Ham veritabanı hatalarının istemciye dönmesini engelle | `[D0]` | B37 |
| 2.18 | `DB_SSLMODE` tanımla; sabit şifreleme anahtarını kaldır (KDF + rotasyon) | `[D4]` 2026-10-03 — HKDF ile ayrı alt anahtarlar, kimlikli anahtar halkası, `cmd/rotate-pii` (verify adım 42); k8s `DB_SSLMODE=require`; sabit anahtarlı kimlik bilgisi kodu kaldırıldı (modül 501). Kalan: vault/KMS seçimi (S-19) | B21, B44 |
| 2.19 | Şifremi unuttum + OTP + şifre politikası + hesap kilitleme | `[D0]` | C.1 — rakibin en çok şikayet edilen noktası |

**Çıkış ölçütü:** Kimliksiz hiçbir uç nokta kalmaz; bir tenant'ın token'ıyla diğerinin verisine erişim
denemesi otomatik testte başarısız olur.

## FAZ 3 — Denetim İzi ve Gözlemlenebilirlik `[TAMAMLANDI — 2026-10-03, 3.6 hariç]`

> Denetim izi, okuma kaydı, yapılandırılmış log ve geri yükleme provası çalışıyor ve
> `verify-stack.sh` ile sınanıyor (ayrıntı: `tasks/todo.md` FAZ 3). **Kalan:** 3.6 (metrik, hata takibi).

| # | İş | Durum | Kanıt / not |
|---|---|---|---|
| 3.1 | `audit_logs` kolon uyuşmazlığını gider (kod ⟷ şema) | `[D4]` migration 011 | B59 — KVKK taahhüdü bugün karşılanmıyor |
| 3.2 | `old_values`/`new_values` gerçekten yaz | `[D3]` tipli `audit.Entry` | — |
| 3.3 | Audit hatasının yutulmasını durdur (log + uyarı) | `[D4]` `pkg/middleware` | KN-2 |
| 3.4 | Hassas veri **okuma** logu (TCKN, maaş, sır gösterme) | `[D4]` 2026-10-03, verify §31 | M-03 |
| 3.5 | Yapılandırılmış log + istek kimliği + status/süre | `[D4]` 2026-09-26, verify §37 | M-10 |
| 3.6 | Sağlık kontrolü, metrik, hata takibi (mobil çökme raporu dahil) | `[D0]` | M-10 |
| 3.7 | Yedekleme + **geri yükleme provası** | `[D4]` 2026-09-27, verify §41 | M-12 |

## FAZ 4 — Para Doğruluğu `[ÇEKİRDEK TAMAM — 2026-09-13]`

> S-02 dondurması kullanıcı tarafından kaldırıldı. Bakiye düzeltildi, ödeme borçtan
> düşüyor, para kuruş cinsinden ve dağıtımda kuruş kaybı yok, gecikme tazminatı
> (KMK m.20/2) hesaplanıyor. Bakiye sayısal testi yazıldı ve asıl hatayı buldu (migration 030,
> 2026-10-03). **Kalan:** tam kuruş göçü (todo 4.13), sağlayıcı (4.11, S-06).
> **Kanıt:** `verify-stack.sh` §5b, §10, §11.

**Amaç:** Gösterilen her tutarın doğru olması. Bugün bakiye kullanıcı sayısıyla çarpılıyor ve
ödeme hiçbir zaman tamamlanmıyor.

| # | İş | Durum | Kanıt / not |
|---|---|---|---|
| 4.1 | `GetUnitBalance` kartezyen join'ini düzelt (hazır `unit_balances` view'ını kullan) | `[D4]` + 030 (görünüm boş defterden okuyordu), verify §10 | B45 — şema değişikliği gerektirmez |
| 4.2 | Ödemeyi tamamla: `paid_amount` + tahakkuk durumu, tek transaction, `FOR UPDATE` | `[D4]` yönetici onay akışı, verify §10 | B46, B47 |
| 4.3 | Para tipini `float64`'ten kuruş (`int64`) veya `decimal`'e çevir | `[D4]` yeni kod `pkg/money`; eski alanların göçü kaldı (todo 4.13) | B50 — şema zaten `DECIMAL` |
| 4.4 | Tahakkukta kuruş yuvarlama + kalan dağıtımı (largest remainder) | `[D4]` | B51 |
| 4.5 | Ödeme idempotency (`Idempotency-Key`) | `[D4]` 2026-10-03 — aynı tahakkuk için ikinci PENDING ödeme 409 (kilit altında denetim), verify §10. `Idempotency-Key` başlığı yok; sağlayıcı (S-06) gelince webhook için gerekir | B48 |
| 4.6 | `CalculateTotalAmount`'a `deleted = 0`; tahsilat oranı kesme hatası | `[D4]` 2026-10-03 — oran SQL numeric, tek ondalık aşağı; 348/1200 → %29,0 (eski %28), 1199,99/1200 → %99,9 active; verify §10 | B53, B54 |
| 4.7 | `ListDebtors`'ı daire bazlı yap (kiracılı/boş daireler de görünsün) | `[D4]` 2026-10-03, verify §10 (hisseli daire tek satır, maliksiz daire görünür) | B55 |
| 4.8 | `ListPropertyPayments` tenant filtresini ödeme üzerinden kur | `[D4]` 2026-10-03 — `payments.property_id`/`unit_id`; ayrılan sakinin ödemesi listede kalıyor, verify §10 | B56 |
| 4.9 | Gecikme tazminatı (KMK m.20/2, aylık %5 — **parametrik**) | `[D4]` `legal_parameters`, verify §10 | B52, S-05 |
| 4.10 | Mobil ödeme ekranını gerçek API'ye bağla ya da kaldır | `[D4]` todo 0.C.1 | B49 |
| 4.11 | Ödeme sağlayıcısı adaptörü (port/adapter, sandbox-stub ile) | `[BLOKE]` S-06 | C.4 |

## FAZ 5 — Mevcut Modülleri Uçtan Uca Bitirme `[SIRADAKİ ANA İŞ]`

> S-03 kararı: **hepsini tamamla**. Ara adım tamam — 22 servisin tamamı dürüstçe 501
> döndürüyor ve arayüzler bunu açıkça gösteriyor. Şimdi modül modül gerçeğe çevrilecek.
> Öncelik: gider, personel, ziyaretçi, otopark, rezervasyon, kargo.
> Dikey dilim ilkesi: şema → repository → service → handler → RBAC → panel/mobil → test.

Sıra, değer/çaba oranına göre. Her dilim `tasks/dogrulama-politikasi.md` §2 "Bitti" tanımına uyar.

| # | Dilim | Durum | Not |
|---|---|---|---|
| 5.1 | **Duyurular** — community'deki auth'suz mock'u gerçeğe çevir (tablolar hazır) | `[D0]` | Hedefleme + okundu bilgisi + çok kanallı yayın; en hızlı kazanım |
| 5.2 | **Talepler** tamamlama — dosya eki, `unit_id`, atama, SLA, yorum | `[D0]` | Zaten en olgun modül; C.6 |
| 5.3 | **Sakinler** tamamlama — tarihli ilişki, malik/kiracı, devir + borcu yoktur | `[D0]` | C.2 |
| 5.4 | **Sayaç ve tüketim** — iot'u DB'ye bağla, yönetmelik paylaşımı, tüketim detay faturası | `[D0]` | C.8; rakibin somut şikayeti |
| 5.5 | **Gider yönetimi** — kalıcılık, onay akışı, bütçe kontrolü, mobilden gider girme | `[BLOKE]` S-02 | C.5; rakibin en büyük boşluğu |
| 5.6 | **Kasa/banka** — bakiye, IBAN listesi, ekstre içe aktarma + otomatik eşleştirme | `[BLOKE]` S-02 | C.4; yöneticinin ilk baktığı ekran |
| 5.7 | **Sakin uygulaması** gerçek hale getirme | `[D0]` | INTERNET izni, base URL, kalıcı oturum, route erişimi, gerçek veri (B/C bölümleri) |
| 5.8 | **Yönetici uygulaması** gerçek hale getirme | `[D0]` | base URL (`/v1` hatası), auth guard, logout, gerçek veri |
| 5.9 | **Raporlar** — gerçek veriyle besleme, parametre, auth, kalıcı saklama | `[D0]` | C.9 |
| 5.10 | **Dashboard** — aggregator zarf hatasını düzelt, gerçek sayılar | `[D0]` | B66 |
| 5.11 | **Bildirim altyapısı** — kuyruk, şablon, kategori/tercih, teslim raporu, push kurulumu | `[BLOKE]` S-10 | M-05; mobilde push hiç yok |
| 5.12 | **Dosya depolama** — S3 uyumlu, imzalı indirme, belge modülünü bağla | `[BLOKE]` S-09 | M-04; tüm belge/fotoğraf özellikleri buna bağlı |
| 5.13 | Kalan `[MOCK]` modüller: ziyaretçi, otopark, rezervasyon, personel, kargo, varlık, sözleşme, envanter, anket, ilan | `[D0]` | S-03 kararına göre: gerçekleştir ya da arayüzden kaldır |

## FAZ 6 — Yönetişim Katmanı (KMK) `[ÇEKİRDEK TAMAM — 2026-09-13]`

> Yeni servis: `backend/services/governance` (port 8107), şema `migrations/014`.
> İşletme projesi (m.37), genel kurul (m.29-33), defterler (m.32/36) ve icra takibi
> (m.22, İİK m.68) çalışıyor. **Kalan:** panel/mobil arayüzleri (6.7), tutanak→defter
> otomatik bağlantısı (6.6).
> **Kanıt:** `verify-stack.sh` §11 + 14 nisap birim testi.
>
> **Ürünü rakipten ayıracak katman budur:** rakip ürünlerin çoğunda nisap hesabı,
> vekâlet sınırı denetimi ve değiştirilemez karar defteri yoktur.

Bugün tamamen yok. Aidatın yasal dayanağı ve icra gücü buradan doğar.

| # | Dilim | Durum | Dayanak |
|---|---|---|---|
| 6.1 | **İşletme projesi (yıllık bütçe)** + tebliğ + 7 gün itiraz + kesinleşme + resmî PDF | `[D0]` | KMK m.37; İİK m.68 belgesi |
| 6.2 | **Kat malikleri kurulu** — çağrı (15 gün), gündem, hazır bulunanlar, **yeter sayı motoru** (sayı+arsa payı), vekâlet sınırı, **karar nisabı motoru** (salt/çoğunluk/4-5/oybirliği) | `[D0]` | KMK m.29-31, 42, 45 |
| 6.3 | **Karar defteri ve işletme defteri** + noter kapatma hatırlatıcısı | `[D0]` | KMK m.32, m.36 |
| 6.4 | **Yönetim planı** + parametrelere bağlanması | `[D0]` | KMK m.28 |
| 6.5 | **Denetçi ve hesap verme** — 3 aylık denetim, yıllık hesap özeti, ibra, denetçi paketi | `[D0]` | KMK m.39, m.41 |
| 6.6 | **Yönetim organları** — seçim, görev süresi, imza yetkisi, devir teslim | `[D0]` | KMK m.34, m.40 |
| 6.7 | **Hukuk ve icra takibi** — ihtar, icra dosyası, kanuni ipotek, masraf/faiz mahsubu | `[D0]` | KMK m.20, m.22, m.25 |
| 6.8 | **Toplu yapı organları** — blok kurulu, temsilciler kurulu, blok bazlı gider ayrımı | `[D0]` | KMK m.66-73; S-13 |

## FAZ 7 — Uyum ve Operasyonel Derinlik

| # | Dilim | Durum | Not |
|---|---|---|---|
| 7.1 | **Periyodik bakım ve yasal uyum takvimi** — asansör, yangın, su deposu, paratoner, jeneratör, baca, havuz | `[D4]` ilk dilim 2026-10-04: demirbaş bakım aralığı + zamanlayıcı hatırlatması (verify §40). Kalan: mevzuat kaynaklı hazır şablonlar (hukuki teyit gerekir, S-05) | M-31; denetimde ilk sorulan; hiç yok |
| 7.2 | **Sigorta yönetimi** — DASK takibi, poliçe yenileme, hasar | `[D0]` | M-36 |
| 7.3 | **Acil durum ve afet** — plan, tahliye, kritik altyapı, tatbikat, deprem sonrası akış | `[D0]` | M-37; Türkiye için yüksek değer |
| 7.4 | **Personel** — bordro, SGK, izin bakiyesi, İSG, kıdem karşılığı | `[D0]` | M-34 |
| 7.5 | **Kural ihlali ve yaptırım** + **tadilat izni** | `[D0]` | M-44, M-45 |
| 7.6 | **Ortak alan gelir yönetimi** (m.45 oybirliği kuralıyla) | `[D0]` | M-46 |
| 7.7 | **Vergi/SGK beyan takvimi** | `[D0]` | M-29 |
| 7.8 | **KVKK uyum yönetimi** — saklama/imha, ilgili kişi başvurusu, kamera/biyometrik envanteri | `[D0]` | S-04 |

## FAZ 8 — Ölçek ve Ticarileşme

| # | Dilim | Durum |
|---|---|---|
| 8.1 | **Onboarding ve veri aktarımı** (rakipten geçiş) — kurulum sihirbazı, doğrulamalı toplu içe aktarma, açılış bakiyesi | `[D4]` 2026-10-03/04: kurucu yönetici rolü, bölüm ve sakin toplu içe aktarma, görevlendirme, açılış (devir) bakiyesi (033/034, verify §10/§39) — rakipten veri aktarım biçimleri (Excel şablonu) kalan |
| 8.2 | Test altyapısı: birim + entegrasyon (testcontainers) + sözleşme testi + mobil golden test | `[D0]` |
| 8.3 | Ölü kod ve ölü şema temizliği (~3.900 satır, 47 tablo) | `[D0]` |
| 8.4 | Tek giriş kapısı kararı (Kong ↔ gateway birleştirme) — **karar (2026-09-27):** tek giriş gateway; Kong isteğe bağlı kenar katmanı, tek yukarı akış gateway | `[D2]` |
| 8.5 | OpenAPI'yi gerçek uçlarla senkronize et + sözleşme testi | `[D1]` sözleşme `tasks/api-sozlesmesi.md` + panel sözleşme testi (verify §38); `api/openapi.yaml` bayat olarak işaretlendi (2026-10-03), senkron yapılmadı |
| 8.6 | Yönetim organizasyonu (portföy) katmanı | `[D0]` |
| 8.7 | Çok dillilik, erişilebilirlik, offline | `[D0]` |
| 8.8 | Akıllı tahsilat, ESG, AI yetenekleri (gerçek entegrasyonla) | `[D0]` |
| 8.9 | SaaS abonelik/faturalama | `[D0]` |
| 8.10 | Mobil yayın (Play Store iç test → üretim; iOS için `ios/` oluşturma) | `[D0]` |

---

# USTALIK YOL HARİTASI

CLAUDE.md gereği: bu projede dünya çapında uzmanlığa götüren yol. Klişe tavsiye yok — **bu kod tabanında
karşılığı olan**, doğrulanabilir teknikler. Her madde "neden bu projede önemli" gerekçesiyle yazıldı.

## U.1 PostgreSQL — finansal veri modelleme

- **Çift taraflı kayıt (double-entry ledger).** Şemada `ledger_entries` + `ledger_lines` **zaten var**
  (`001:176,191`) ve `debit XOR credit` CHECK kısıtı bile yazılmış — ama hiç kullanılmıyor. En iyi %1'in
  yaklaşımı: bakiyeyi bir kolonda tutmak yerine **değiştirilemez hareketlerden türetmek**. Böylece
  "bakiye neden bu?" sorusu her zaman cevaplanabilir olur. `unit_balances` view'ı (`001:422`) bunu doğru yapıyor;
  bugün kullanılan kırık sorgu yerine bu benimsenmeli.
- **Para asla kayan nokta değil.** İki doğru seçenek: `NUMERIC` + `shopspring/decimal`, ya da tamsayı kuruş
  (`int64`). Şemadaki `invoices.amount_total INTEGER` (`003:37`) aslında doğru yaklaşımın izi.
- **Kuruş dağıtımı: largest remainder yöntemi.** 1000 TL'yi 3 daireye bölerken 333,33×3 = 999,99 → 1 kuruş
  kaybolur. Doğru yöntem: tam bölüm + kalanı belirli bir sıraya (en yüksek arsa payı, sonra birim numarası)
  göre dağıtmak. Toplamın gider tutarına **tam** eşit olması yasal bir gerekliliktir.
- **Zaman aralığı çakışmasını veritabanında engelle:**
  `EXCLUDE USING gist (facility_id WITH =, tstzrange(start_time, end_time) WITH &&)`.
  Mevcut `UNIQUE(facility_id, start_time)` (`005:282`) yalnızca aynı başlangıç saatini engelliyor —
  10:00-12:00 ile 11:00-13:00 çakışmasını kaçırıyor. Bu, uygulama katmanında yazılan çakışma
  kontrollerinin yarış koşullarına açık olmasının da çözümüdür.
- **Satır düzeyi güvenlik (RLS) ile tenant izolasyonu.** Bugün izolasyon "her sorguya filtre yazmayı
  hatırlamak"a bağlı ve 11 sorguda unutulmuş. RLS ile veritabanı bunu **zorlar**:
  `CREATE POLICY tenant_isolation ON units USING (property_id = current_setting('app.property_id')::uuid)`.
  Bağlantı başına `SET LOCAL app.property_id` yeterli. Bu, tek başına B18/B19/B61 sınıfı hataları imkânsız kılar.
- **Türkçe arama:** `pg_trgm` + GIN index. Bugün `ILIKE '%...%'` (`resident.go:57`) leading-wildcard
  olduğu için index kullanamıyor → full scan. Ek olarak `citext` veya `unaccent` ile "İ/ı" sorunu çözülür.
- **Keyset (cursor) sayfalama**, `OFFSET` değil: büyük tabloda `OFFSET 10000` giderek yavaşlar.
- **Kuyruk gerekiyorsa** `SELECT ... FOR UPDATE SKIP LOCKED` — ayrı bir kuyruk altyapısı kurmadan
  güvenilir iş dağıtımı (bildirim gönderimi, rapor üretimi için yeterli).
- **Kısmi index (partial index):** `WHERE deleted = 0` filtreli sorgular için
  `CREATE INDEX ... WHERE deleted = 0` — hem küçük hem hızlı.
- **`generated always as ... stored`**: `meter_readings.consumption` (`001:256`) bunu doğru kullanıyor —
  türetilmiş değeri uygulamada hesaplamak yerine veritabanına bırakmak tutarlılık garantisi verir.
- **Teşhis araçları:** `pg_stat_statements` (yavaş sorgu), `EXPLAIN (ANALYZE, BUFFERS)`,
  `auto_explain`. Az bilinen: `pg_stat_statements` ile "en çok toplam süre harcayan sorgu" listesi,
  optimizasyon için tek başına en verimli girdidir.

## U.2 Mimari — doğru soruyu sormak

- **25 mikroservis bu proje için yanlış karar.** Denetimin gösterdiği: 22'si mock, ortak paketler ölü,
  aynı entegrasyon 2-3 kez yazılmış, iki farklı giriş kapısı var. Küçük ekip için doğru desen
  **modüler monolit**: tek dağıtım birimi, modül sınırları paket düzeyinde net, tek veritabanı,
  tek transaction. Ölçek gerektiğinde modül sınırından servis çıkarılır (strangler fig).
  Bu, "en iyi %1"in dağıtık sistem *kurmaktan çok kaçındığı* alandır — dağıtık sistem bir maliyet,
  bir yetenek değil.
- **Mimari kararları yazıya geçir (ADR).** Her önemli karar için: bağlam, seçenekler, karar, sonuçlar.
  Bu projede "neden Kong **ve** özel gateway?" sorusunun cevabı hiçbir yerde yok; ADR olsaydı olurdu.
- **Sözleşme önce (contract-first).** `api/openapi.yaml` bugün bayat ve 2 dokümante uç kodda yok.
  Doğrusu: OpenAPI'yi kaynak kabul et, sunucu iskeletini ve istemciyi ondan üret, CI'da sözleşme testi çalıştır.
- **Outbox deseni**: veritabanı yazımı ile dış olay yayınını (bildirim, webhook) atomik yapmak için.
  "Ödeme kaydedildi ama bildirim gitmedi" ya da tersi durumunu yapısal olarak engeller.
- **Idempotency her mali uçta zorunlu.** İstemciden `Idempotency-Key`, sunucuda anahtar tablosu.
  Ağ kopması ve çift tıklama gerçektir; bugün mükerrer ödeme mümkün.

## U.3 Go — üretim disiplini

- `golangci-lint` ile **`errcheck`** açık: denetimin en yıkıcı bulgusu (`_ = audit.LogAction`) bu linter'la
  otomatik yakalanırdı. Ayrıca `sqlclosecheck`, `rowserrcheck`, `bodyclose`, `contextcheck`.
- **`go test -race`** ve **fuzzing** (`go test -fuzz`): dağıtım matematiği ve IBAN/plaka/TCKN doğrulama gibi
  saf fonksiyonlar fuzzing için ideal.
- **testcontainers-go**: gerçek PostgreSQL'e karşı entegrasyon testi. Bugünkü testler mock router
  kullandığı için hiçbir şey doğrulamıyor; testcontainers ile migration'lar + gerçek sorgular test edilir
  (ve FAZ 1'deki migration çöküşü CI'da yakalanırdı).
- **`sqlc`** veya `pgx` + elle yazılmış sorgular: ORM yerine SQL'i açık tutmak, `sqlc` ile derleme
  zamanında tip güvenliği. `sqlc`, kolon adı uyuşmazlığını (B59) **derleme zamanında** yakalar.
- `context` yayılımı: `c.Request.Context()` kullan, `context.Background()` kullanma (bugün 18 yerde hata var).
- **Yapılandırma doğrulaması başlangıçta (fail-fast):** `JWT_SECRET` boşsa `log.Fatal`. Bugün boş anahtarla
  token doğrulanıyor — sessiz felaket.
- `errgroup` ile paralel çağrı + tek timeout: dashboard aggregator bugün 5 servisi sırayla çağırıyor (en kötü 10 sn).
- **Az bilinen:** `go build -gcflags="-m"` ile kaçış analizi; `pprof` ile alokasyon profili.
  Ama önce ölç: optimizasyon öncesi `pg_stat_statements` neredeyse her zaman daha büyük kazanç gösterir.

## U.4 Flutter — üretime hazırlık

- **Flavor + `--dart-define`**: taban adresi koda gömmek (bugün `http://localhost:8000`) gerçek cihazda
  çalışmaz. `--dart-define=API_URL=...` + `String.fromEnvironment` ile ortam ayrımı.
- **Kod üretimi gerçekten kullan:** `freezed` + `json_serializable` pubspec'te var ama 0 kullanım;
  tüm yanıtlar `Map<String, dynamic>` olarak elle işleniyor. Sonuç: anket ekranı API veri döndürdüğü an
  çöküyor (var olmayan alan okunuyor). Tipli modeller bu sınıf hatayı derleme zamanına taşır.
- **`local_auth` için `FlutterFragmentActivity`** zorunlu — bugün `FlutterActivity` olduğu için biyometrik
  hiçbir zaman çalışmıyor. Bu, "kod yazıldı ama çalıştırılmadı"nın ders niteliğinde örneği.
- **Release manifest'i ayrı denetle:** izinler yalnızca `debug/AndroidManifest.xml`'de olduğu için
  release APK'da internet erişimi yok. `flutter build apk --release` sonrası `aapt dump permissions` ile doğrula.
- **Golden test** (görsel regresyon) + `integration_test` paketi: kritik akışlar (giriş, ödeme) için.
- Offline-first: saha çalışan yönetici için yazma kuyruğu + çakışma çözümü. Rakibin en büyük boşluğu
  "mobilden işlem yapamama" — bunu offline destekle çözmek doğrudan farklılaşma sağlar.
- **Az bilinen:** `flutter build apk --analyze-size` ile boyut analizi; `--split-debug-info` ile
  sembol dosyalarını ayırıp çökme raporlarını okunur tutmak.

## U.5 Çok kiracılı SaaS

- İzolasyonu **mimariyle** garanti et (RLS), kod incelemesiyle değil. Bir tenant'ın token'ıyla diğerinin
  kaynağına erişim denemesi **otomatik testte** olmalı — bu test bir kez yazılırsa tüm sınıf kapanır.
- Tenant bağlamını arka plan işlerine ve kuyruk mesajlarına taşı; önbellek anahtarına tenant ekle.
- Tenant yaşam döngüsünü baştan tasarla: kurulum, askıya alma, **veri ihracı**, tam silme (KVKK).
- Gürültülü komşu (noisy neighbor): tenant bazlı hız sınırı ve kota.

## U.6 Türkiye alan bilgisi — asıl rekabet avantajı

Yazılım tarafı taklit edilebilir; **mevzuat derinliği** edilemez.

- **634 sayılı KMK'yı madde madde bil** ve her maddenin yazılımdaki karşılığını kur:
  m.20 (gider paylaşımı ve aylık %5 gecikme tazminatı), m.22 (kanuni ipotek, müteselsil sorumluluk),
  m.29-33 (çağrı, yeter sayı, oy, karar defteri, hâkimin müdahalesi), m.34-41 (yönetici, defterler,
  işletme projesi, hesap verme, denetçi), m.42/45 (nisaplar), m.66-73 (toplu yapı).
- **Yargıtay içtihadını izle.** Kanun metni her şeyi söylemez; "zemin kat asansör giderine katılır mı",
  "boş dairenin ısınma payı", "işyerine farklı katsayı" gibi sorular içtihatla netleşir.
  Bu bilgi, ürünün parametrelerini doğru tasarlamanın tek yolu.
- **İkincil mevzuat:** ısı/sıhhi sıcak su gider paylaşım yönetmeliği (pay ölçer), asansör işletme ve bakım
  yönetmeliği (periyodik kontrol + etiket), binaların yangından korunması yönetmeliği,
  6331 İSG (site işverendir), 5188 özel güvenlik, KVKK + VERBİS, İİK m.68.
- **Kural motoru yaz, kural gömme.** Yönetim planı siteye göre değişir; kanun zamanla değişir.
  Oranlar yürürlük tarihli parametre olmalı ve her parametrede **mevzuat dayanağı alanı** bulunmalı.
  Bu, hukuki bir düzeltmenin kod değişikliği gerektirmemesini sağlar — ölçekte kritik.
- **Doğrulama algoritmaları:** TCKN kontrol algoritması, IBAN mod-97, plaka normalizasyonu,
  UAVT adres kodu. Küçük ama güven veren detaylar.
- **Ekosistem entegrasyonları:** e-Fatura/e-Arşiv (GİB), e-Devlet, tapu, belediye, DASK,
  bankaların kurumsal tahsilat sistemleri, açık bankacılık.

## U.7 Ürün — rakibin bıraktığı boşluk

`yorum_analizleri.txt`'ten çıkan tek cümlelik strateji: **rakip, mobili web'in çok gerisinde bıraktı.**

- **Mobil-panel işlev paritesi**, özellikle yönetici tarafında: mobilden gider girme, tahsilat işleme,
  ödeme-sakin eşleştirme, kasa/IBAN görüntüleme. Bunlar bugün rakipte yok ve bu projede de yok →
  ilk gerçekleştiren kazanır.
- **Ödeme akışında dürüstlük:** kalem seçerek ödeme, paranın hangi borca gittiğinin anında gösterilmesi,
  banka hareketinin anında düşülmesi (gereksiz faiz oluşmaması).
- **Tüketim şeffaflığı:** m³, gün sayısı, birim fiyat, ortak alan payı ve PDF — rakipte "sadece toplam" var.
- **Talep kapanışında sakin onayı** — bu projede zaten doğru yapılmış, korunmalı.
- **Geçiş kolaylığı:** rakipten veri aktarımı, satışın önündeki en büyük engeldir.
- **Uyum takvimi** (asansör/yangın/su deposu) — yöneticinin gerçek kaygısı ve hiçbir rakipte
  düzgün yok; denetimde ilk sorulan şey.

## U.8 Kişisel çalışma disiplini

- **Kanıtsız "tamam" yazma.** Bu projedeki tek en büyük hasar bundan doğdu (%49 yanlış iddia).
- **Dikey dilim**: bir şeyi uçtan uca bitirmek, on şeyi yarım bırakmaktan kıyaslanamaz ölçüde değerlidir.
- **Hatayı görünür kıl.** Sessiz `catch`, `_ = err`, sahte başarı mesajı — hepsi gelecekteki kendine
  kurulan tuzaktır. `errcheck` ve "sessiz fallback yasak" kuralı bunu yapısal olarak engeller.
- **Kurulumu her zaman sıfırdan test et.** "Bende çalışıyor" ile "kurulabilir" arasındaki fark,
  bu projede tüm veritabanı şemasının yeniden üretilemez olması demek oldu.
- **Silmeyi öğren.** ~3.900 satır ölü kod ve 47 ölü tablo, bakım maliyeti ve yanlış "var" algısı üretiyor.
  Silinen kod git geçmişinde durur; ölü kod ise her okumada vergi alır.

---

## Bağlantılı dosyalar

| Dosya | İçerik |
|---|---|
| `tasks/audit-raporu.md` | İddia vs gerçek denetimi, kök nedenler, kritik bulgular |
| `tasks/audit/` | Ayrıntılı kanıt raporları (5 dosya) |
| `tasks/gap-analizi.md` | Modül durum matrisi, 97 mantık hatası (B01-B97), özellik bazlı eksik tamamlayıcılar |
| `tasks/modul-envanteri.md` | Olması gereken 60 modülün referans modeli |
| `tasks/dogrulama-politikasi.md` | "Bitti" tanımı, kanıt seviyeleri, sessiz başarısızlık yasağı |
| `tasks/todo.md` | Aktif iş kuyruğu |
| `tasks/questions.md` | Kullanıcı kararı bekleyen konular (S-01…S-18) |
| `tasks/lessons.md` | Öğrenilen dersler |
| `tasks/changelog.md` | Yapılan değişiklikler (kanıtla) |
