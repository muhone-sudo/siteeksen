# Todo — Aktif İş Kuyruğu

**Bu dosya 2026-09-09'da sıfırdan yeniden yazıldı.** Önceki sürüm, doğrulanmamış "✅" işaretleri içerdiği
için geçersiz kabul edildi (bkz. `tasks/audit-raporu.md`). Eski sürüm git geçmişinde durmaktadır.

> Önceki sürümdeki **"Oturum Talimatları (Otonom — Kullanıcı Uyuyor)"** bölümü o oturuma özeldi ve
> **artık geçerli değildir.** Commit/push politikası: `tasks/questions.md` S-17 (varsayılan: commit edilmez).

Kanıt seviyeleri: `tasks/dogrulama-politikasi.md` §1. Kanıtsız madde `[D1]`'den yükseğe çıkarılamaz.

---

## Bu oturumun kapsamı

| Aşama | Durum |
|---|---|
| A. Denetim (iddia vs gerçek) | **Bitti** — `tasks/audit-raporu.md` + `tasks/audit/` (5 kanıt dosyası) |
| B. Olması gereken modüllerin tanımlanması | **Bitti** — `tasks/modul-envanteri.md` (60 modül) |
| C. Gap analizi (eksikler + mantık hataları) | **Bitti** — `tasks/gap-analizi.md` (B01-B97 + özellik bazlı eksikler) |
| D. Doğrulama politikası | **Bitti** — `tasks/dogrulama-politikasi.md` |
| E. Yol haritası + ustalık planı | **Bitti** — `tasks/roadmap.md` |
| F. Kullanıcıya sorular | **Bitti** — `tasks/questions.md` (S-01…S-18) |
| G. Geliştirme: FAZ 0 (dürüstlük onarımı) | **sürüyor** |

## Doğrulama ortamı — ÇÖZÜLDÜ (2026-09-12)

Kullanıcı talimatıyla local iş **WSL (Ubuntu 24.04)** üzerinden yürütülüyor; Windows'taki AppLocker
kısıtı orada yok (`questions.md` S-01).

- **Kurulu:** Go 1.24.7 (WSL'e kuruldu), Docker 27.5.1, psql 16, Node 22
- **Eksik:** Flutter → mobil işler hâlâ `[D1]` kalır (`questions.md` S-01b)

**Kalıcı doğrulama betiği:** `bash backend/scripts/verify-stack.sh`
Sıfırdan PostgreSQL → 11 migration → şema denetimi → idempotency → `pkg/audit` testi →
identity-service'i ayağa kaldırıp gerçek HTTP istekleri. **42 kontrol.**
Backend'e dokunan her değişiklikten sonra çalıştırılır.

---

# FAZ 0 — Dürüstlük Onarımı (aktif)

**İlke:** Sistemin kullanıcıya yalan söylemesini durdur. Yeni özellik yok.
**Neden ilk:** Yanlış rakam gösteren bir mali ekran, hiç göstermeyenden daha zararlıdır.

## 0.A — Admin panel

- [x] **[D2] 0.A.1 🔴 Giriş şifresinin log'a yazılması kaldırıldı**
      `admin/src/app/api/auth/[...nextauth]/route.ts` — `console.log(credentials)` silindi;
      hata ayıklama için yalnızca **maskelenmiş** telefon (`maskPhone`) ve HTTP durumu loglanıyor. *(B16)*
      **Kanıt:** `npm run build` → çıkış kodu 0
- [x] **[D2] 0.A.2 🔴 Sessiz mock fallback'ler kaldırıldı**
      expenses, personnel, parking, reservations, visitors, accounting, notifications, credentials —
      hardcoded veri dizileri silindi; `loadError` + `<ErrorState onRetry>` kalıbına geçildi.
      Özet/istatistik kartları hata durumunda uydurma sayı yerine `—` gösteriyor. *(B79)*
      Ortak bileşen eklendi: `admin/src/components/ui/data-state.tsx`
- [x] **[D2] 0.A.3 🔴 Credentials sayfasındaki uydurma şifre kaldırıldı**
      `"demo-sifre-2026"` silindi; backend'de şifre gösterme ucu olmadığı için özellik dürüstçe
      devre dışı ve nedeni ekranda açıklanıyor. Erişim kaydının yalnızca yerel olduğu belirtiliyor. *(B80)*
- [x] **[D2] 0.A.4 🔴 Sahte "kaydedildi/gönderildi" mesajları kaldırıldı**
      `settings` (kaydetmeden "Kaydedildi"), `notifications` (`catch{}` → gönderilmemişken başarı),
      `reports` (`alert("e-posta gönderildi")`), `accounting` (sahte toplu "hızlı işlem" modalı). *(B81)*
      Bildirim gönderimi artık yalnızca sunucu onayladığında başarı gösteriyor; hata görünür.
- [x] **[D2] 0.A.5 🟠 Sahte soft-delete kaldırıldı**
      Gerçek silme ucu olanlar API'ye bağlandı (`deleteEmployee`, `deleteVehicle`, `cancelReservation`);
      olmayanlar sahte başarı yerine dürüst hata mesajı veriyor. *(B83, B60)*
- [x] **[D2] 0.A.6 🟠 Çıkış (logout) düğmesi eklendi**
      `components/layout/header.tsx` — `signOut({callbackUrl:"/login"})` ile profil menüsünde.
      Ayrıca hardcoded "Ahmet Yılmaz / Yönetim Kurulu Başkanı" kaldırılıp gerçek oturum bilgisi
      (`useSession`) gösteriliyor; çalışmayan arama kutusu ve sahte bildirim rozeti kaldırıldı. *(B91)*
- [x] **[D2] 0.A.9 Doğrulama:** `npm run build` → **çıkış kodu 0** (21 sayfa)
- [ ] **0.A.7 🟠 Var olmayan uçlara giden api-client metotlarını işaretle/kaldır**
      `/meters/readings`, `/notifications/history`, `/notifications`, `/requests/:id/assign` → 404. *(B95)*
- [ ] **0.A.8 🟡 Ölü kodu temizle** — `hooks.ts`'teki 17 hook'un 13'ü kullanılmıyor. *(B93)*
- [ ] **0.A.10 🟠 Rol bazlı erişim kontrolü** — `session.user.roles` hiçbir sayfada okunmuyor;
      AUDITOR/STAFF maaş ve kimlik bilgisi sayfalarına girebiliyor. *(B28)* → FAZ 2.9

## 0.B — Backend (Go)

- [x] **[D2] 0.B.3 🟠 Yutulan hatalar görünür kılındı (kısmi)**
      `pkg/middleware/auth.go` — `_ = audit.LogAction(...)` kaldırıldı, hata loglanıyor;
      `finance/repository/finance.go` — ödeme-tahakkuk bağlantısındaki yok sayılan `err` düzeltildi
      ve tüm akış tek transaction'a alındı. *(KN-2, B59, B47)*
      **Kanıt:** `go build ./...` + `go vet ./...` → 0
- [x] **[D4] 0.B.1 🔴 Kaydetmeyen uçlar `501`'e çevrildi** *(B78, B79, B84)*
      22 mock servisin **tüm** uçları (yalnızca yazma değil — okuma uçları da uydurma veri
      döndürüyordu) artık `501 Not Implemented` döndürüyor. Ortak sözleşme: `pkg/stub`.
      Yanıt gövdesi modül adını, "istek İŞLENMEDİ" uyarısını ve doküman referansını içerir;
      `X-SiteEksen-Not-Implemented: true` başlığı eklenir. Sağlık ucu artık `"healthy"` değil
      `"not_implemented"` der (servis ayakta ama işlevsiz).
      Etkilenen servisler: asset, banking, bulletin, contract, document, energy_analytics, esg,
      expense, inventory, iot, meeting_wizard, notification, nps, package, parking, patrol,
      personnel, reservation, settings, smart_collection, survey, visitor.
      **Kanıt:** `verify-stack.sh` §7 — çalışan servise `GET /api/v1/vehicles` → **501**,
      `POST /api/v1/vehicles` → **501**, başlık mevcut; kaynaklarda uydurma isim taraması → 0 satır.
- [x] **[D4] 0.B.2 🟠 Yanlış sağlık bilgileri (`ai_enabled` vb.) kaldırıldı** *(B84)*
      `energy_analytics`, `smart_collection`, `meeting_wizard` sağlık uçları yapılandırmaya
      bakmadan `ai_enabled: true` diyordu. Bu gövdeler `stub.Health()` ile değiştirildi.
      **Kanıt:** `grep -rn "ai_enabled" services/` → 0 sonuç.
- [x] **[D4] 0.B.4 🟡 Community'nin 4 auth'suz modülü `AuthMiddleware` + `501` arkasına alındı** *(C-1, B78)*
      Duyuru/anket/ilan/rezervasyon uçları **token'sız** POST/PUT/DELETE kabul ediyordu
      (herkes duyuru oluşturup silebilirdi). Tümü `AuthMiddleware` arkasına alındı ve `501` döndürüyor.
      Gerçek DB'ye bağlı `requests` modülü değişmedi. Sağlık ucu hangi modülün kalıcı olduğunu bildiriyor.
      **Kanıt:** `go build`/`go vet` → 0; `verify-stack.sh` 47/47.
- [x] **[D4] 0.B.5 🟠 Kalan yok sayılan `err`'ler giderildi** *(M-2)*
      `esg`/`nps`/`banking`/`parking`/`visitor`'daki yutulan hatalar, ilgili gövdeler
      tamamen kaldırıldığı için ortadan kalktı.
      **Kanıt:** `grep -rn "_ = .*err\|ShouldBindJSON(&req)$" services/ pkg/` → 0 sonuç.

---

# FAZ 1 — Kurulabilirlik (büyük kısmı tamamlandı ve doğrulandı)

**Çıkış ölçütü sağlandı:** Temiz bir makinede veritabanı sıfırdan kurulabiliyor ve demo giriş çalışıyor.
**Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **42/42 kontrol geçti** (2026-09-12)

- [x] **[D4] 1.1 Migration 004 `expense_categories` çakışması giderildi** *(B01)*
      Tablo yeniden tanımlanmak yerine 001'in tablosuna eksik kolonlar eklendi; böylece finance (001)
      ve expense (004) sözleşmeleri tek tabloda birleşti. Varsayılan kategorilere KMK m.20'ye göre
      `distribution_type` atandı (eşit / arsa payı), hukuki teyit notu düşüldü.
      **Kanıt:** temiz DB'de `004` → OK
- [x] **[D4] 1.2 Migration 005 `vehicles` çakışması giderildi** *(B02)*
      `CREATE TABLE IF NOT EXISTS` yerine idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`;
      `plate_number` NOT NULL kısıtı kaldırıldı, veri `plate` kolonuna taşındı, `property_id`
      birimden türetildi; `idx_vehicles_unit` çakışması `IF NOT EXISTS` ile giderildi.
      **Kanıt:** `005` → OK; **005 sonrası 29 tablo artık oluşuyor** (toplam 61 tablo)
- [x] **[D4] 1.2b Migration 005'teki geçersiz UUID düzeltildi** *(denetimde yakalanmamıştı)*
      `inventory_categories` seed'inde `ic0000...` kimlikleri kullanılıyordu; `i` hex olmadığı için
      `invalid input syntax for type uuid` hatası veriyordu. `1c` prefix'ine çevrildi.
- [x] **[D4] 1.3 006'nın zincir çöküşü giderildi** *(B03)* — 005 tamamlandığı için `reservations` vb.
      tablolar artık mevcut; 006 sorunsuz uygulanıyor.
- [x] **[D4] 1.7 Demo giriş onarıldı** *(B06)*
      Seed'deki bcrypt hash hiçbir şifreyle eşleşmiyordu (fiilen doğrulandı) ve iki kullanıcıda
      aynıydı. Yeni hash'ler `cost=12` ile üretilip doğrulandı. **Giriş: `5551234567` / `Demo123!`**
      **Kanıt:** gerçek identity-service'e `POST /auth/login` → **HTTP 200 + JWT**; yanlış şifre → **401**
- [x] **[D4] 1.9 `go build ./...` onarıldı** *(B04)*
      Ölü `backend/api/` dizini kaldırıldı (kırık import + `X-User-Role` başlığına güvenen sahte
      süper-admin kontrolü). Ayrıca gizli kalmış iki derleme hatası giderildi:
      `pkg/integrations/sms` (kullanılmayan `body`, bakiye hiç parse edilmiyordu) ve
      `pkg/integrations/whatsapp` (tanımsız `MediaContent` tipi).
      **Kanıt:** `go build ./...` → 0, `go vet ./...` → 0
- [x] **[D3] 1.14 Kalıcı doğrulama betiği eklendi** — `backend/scripts/verify-stack.sh` (42 kontrol)

### FAZ 1 — kalanlar
- [ ] **1.4 Migration'ları tam idempotent yap** — 001'de 25 `CREATE TABLE`, 119 `CREATE INDEX`
      `IF NOT EXISTS`'siz; transaction sarmalaması yok. *(B08)*
      *(006-011 zaten idempotent — doğrulandı.)*
- [ ] **1.5 🔴 Migration çalıştırıcı** — sürüm tablosu + kilit + eksikleri uygulama. *(B05)*
- [ ] **1.6 Down (geri alma) betikleri**
- [ ] **1.7b Seed'i `initdb.d` dışına taşı** — üretimde bilinen şifreli hesap açmasın
- [ ] **1.8 Seed verisi tutarsızlığı** — `total_units=24` ama 6 birim; arsa payı toplamı uyumsuz *(B15)*
- [ ] **1.10 13 servisin `main.go` default portu** compose ile eşitlenmeli; 4 çift çakışıyor *(B13)*
- [ ] **1.11 `firebase-credentials.json` mount'u koşullu yapılmalı** *(B07)*
- [ ] **1.12 CI düzeltmeleri** — Go sürümü `go.mod` ile eşitlensin; `|| true` kaldırılsın;
      Trivy kapı olsun; `go build ./... && go vet ./...` + `verify-stack.sh` eklensin *(B09, B10, B11)*
- [ ] **1.13 `003`'ün `audit_logs` DROP'u ALTER'a çevrilmeli** *(B14)*

---

# FAZ 3 — Denetim izi (ilk madde tamamlandı)

- [x] **[D4] 3.1 🔴 Denetim izi çalışır hale getirildi** *(B59)*
      **Sorun:** `pkg/audit` şemada olmayan kolonlara (`user_ip`, `resource_type`, `resource_id`)
      yazıyordu; INSERT her çağrıda `42703` hatası veriyor, hata `_ =` ile yutuluyor ve
      `audit_logs` tablosu kalıcı olarak boş kalıyordu — `legal/kvkk-aydinlatma.md`'deki
      "log tutuyoruz" taahhüdü karşılıksızdı.
      **Çözüm:** Migration `011` (şema ↔ kod uyumu, `property_id`/`request_id`/`status_code` eklendi,
      `tenant_id` zorunluluğu kaldırıldı) + `pkg/audit` yeniden yazıldı (tipli `Entry`) +
      `pkg/middleware` hatayı loglar hale getirildi, 403'ler `DENIED` olarak ayrıştırıldı,
      401'ler gürültü olmasın diye yazılmıyor.
      **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı **2/2 geçti**;
      uçtan uca istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- [x] **[D3] 3.2 `old_values`/`new_values` alanları yazılabilir hale geldi** (tipli `Entry` ile)
- [ ] **3.4 Hassas veri okuma logu** (TCKN, maaş, sır gösterme)
- [ ] **3.5 Yapılandırılmış log + istek kimliği** (`request_id` kolonu hazır, üretimi eksik)

---

# FAZ 4 — Para doğruluğu (ilk düzeltmeler yapıldı)

- [x] **[D2] 4.1 🔴 `GetUnitBalance` kartezyen join'i düzeltildi** *(B45)*
      `JOIN users u ON ll.unit_id = (...)` koşulu `u`'ya referans vermediği için CROSS JOIN'di;
      bakiye **kullanıcı sayısıyla çarpılıyordu** (156 sakinli sitede 1.200 TL borç → 187.200 TL).
      Hesap artık 001'de tanımlı ve doğru yazılmış `unit_balances` view'ı üzerinden, sakinin
      **tüm** aktif bağımsız bölümlerini kapsayacak şekilde yapılıyor.
      **Kanıt:** `go build`/`go vet` → 0. *(Sayısal doğruluk testi FAZ 4.12'de yazılacak.)*
- [x] **[D2] 4.2b Ödeme kaydı tek transaction'a alındı + IDOR kapatıldı** *(B47, B24, B53)*
      Sahiplik doğrulaması (`resident_units` join + `FOR UPDATE`), `deleted = 0` filtresi,
      `payment_assessments.amount` yazımı, `payments.unit_id` doldurulması, hata yutmanın
      kaldırılması. Sahte `checkout.siteeksen.com` adresi kaldırıldı; yanıta
      `payment_gateway_ready: false` eklendi.
- [x] **[D2] 4.6b Ham veritabanı hatalarının istemciye sızması engellendi** (ödeme ucu) *(B37)*
- [ ] **4.2 `paid_amount` güncellemesi** — ödeme onay akışı gerektirir *(B46)* `[BLOKE S-06]`
- [ ] **4.3 Para tipini `float64`'ten kuruş/decimal'e çevir** *(B50)*
- [ ] **4.4 Tahakkukta kuruş yuvarlama + kalan dağıtımı** *(B51)*
- [ ] **4.12 Dağıtım ve bakiye için sayısal doğruluk testleri**

## 0.C — Mobil (Flutter — `[D1]`, CI doğrulaması bekler)

- [ ] **0.C.1 🔴 Sahte ödeme ekranını devre dışı bırak**
      `mobile/.../dues_payment_screen.dart:315-318` — hiç ağ çağrısı yapmadan "Ödeme Başarılı!".
      Gerçek entegrasyon gelene kadar ekran ödeme başlatmamalı. *(B49)*
- [ ] **0.C.2 🔴 Diğer sahte başarı mesajlarını kaldır**
      Sakin: talep oluşturma, ziyaretçi ön kayıt, belge yükleme.
      Yönetici: 11 nokta (tahakkuk, sayaç, duyuru, gider, rapor). *(B81)*
- [ ] **0.C.3 🟠 Sessiz boş-listeye düşmeyi kaldır → hata + yeniden dene**
      5 ekran: duyuru, anket, kargo, ilan, rezervasyon. *(B82)*
- [ ] **0.C.4 🟠 Erişilemeyen ekranları menüye bağla ya da router'dan kaldır**
      Sakin: 12 route + "Daha Fazla"da 10 ölü `onTap`. Yönetici: 17 ekran. *(B89, B90)*
- [ ] **0.C.5 🟠 Yanlış güvence metnini kaldır**
      `admin_app/.../api_settings_screen.dart:191-192` — "şifrelenmiş saklanır, her değişiklik kayıt
      altında" derken tüm ekran mock. *(B85)*

## 0.D — Hukuki metinler

- [ ] **0.D.1 🟡 Doğrulanamayan taahhütleri düzelt**
      `legal/kvkk-aydinlatma.md:114-118` — AES-256 şifreleme (kullanılmıyor), rol bazlı yetki (tek uçta),
      TLS 1.3 (yalnızca ingress), günlük yedekleme (yok), periyodik sızma testi (yok).
      Ayrıca eksik zorunlu unsur: **"toplama yöntemi ve hukuki sebep"** bölümü. *(B86)*
- [ ] **0.D.2 🟡 Placeholder adres/telefon alanlarını işaretle** (3 dosya) — hukuk onayı bekliyor

## FAZ 0 çıkış ölçütü

Arayüzde gerçekten yapılmayan hiçbir işlem için başarı mesajı yok; hiçbir ekran uydurma veri göstermiyor;
kalıcı olmayan hiçbir uç nokta `2xx` dönmüyor.

---

# Sıradaki fazlar (özet)

Ayrıntı: `tasks/roadmap.md`

| Faz | Kapsam | Ön koşul |
|---|---|---|
| FAZ 1 | Kurulabilirlik — migration çakışmaları, migration çalıştırıcı, seed hash, `go build` | S-01 (Docker) doğrulama için |
| FAZ 2 | Kimlik/yetki/izolasyon — gateway auth, tenant izolasyonu, RBAC, logout, OTP | FAZ 1 |
| FAZ 3 | Denetim izi + gözlemlenebilirlik | FAZ 1 |
| FAZ 4 | Para doğruluğu — bakiye, ödeme tamamlama, decimal, gecikme tazminatı | S-02 (finans şeması) |
| FAZ 5 | Mevcut modülleri uçtan uca bitirme | S-03 (kapsam kararı) |
| FAZ 6 | Yönetişim katmanı (KMK) — işletme projesi, genel kurul, defterler, icra | S-02, S-05 |
| FAZ 7 | Uyum ve operasyonel derinlik — bakım takvimi, sigorta, acil durum, personel | — |
| FAZ 8 | Ölçek ve ticarileşme — onboarding, test altyapısı, temizlik, yayın | — |

---

# Karar bekleyen bloklayıcılar

`tasks/questions.md` içinde ayrıntılı. En kritik dördü:

| # | Konu | Etkilediği iş |
|---|---|---|
| S-01 | Go/Flutter/Docker bu makinede kurulamıyor (AppLocker) | Tüm backend/mobil doğrulaması |
| S-02 | Finans şeması dondurması hâlâ geçerli mi? | FAZ 4 ve FAZ 6'nın büyük kısmı |
| S-03 | 22 mock servisi tamamla mı, kapsamı daralt mı? | FAZ 5'in şekli |
| S-05 | Mevzuata bağlı oranların hukuki teyidi | Tahakkuk, gecikme tazminatı, nisaplar |

---

# İnceleme notları

## 2026-09-09 — Denetim ve planlama turu

**Yapılan:** Tüm repo 5 paralel denetim ekseninde incelendi (backend servisleri, veri katmanı/altyapı,
admin panel, sakin mobil, yönetici mobil). 78 doküman iddiası kod kanıtına karşı test edildi.

**Sonuç:** İddiaların **%49'u yanlış**, %28'i kısmen doğru, %23'ü doğru.
25 servisin yalnızca 3'ü veritabanına bağlı; veritabanı temiz makinede kurulamıyor; denetim izi hiç
çalışmıyor; gateway'de kimlik doğrulama yok; para hesaplarında kritik hatalar var (bakiye kullanıcı
sayısıyla çarpılıyor, ödeme hiç tamamlanmıyor).

**Kök nedenler (asıl çözülen):**
1. "Tamamlandı" için kanıt zorunluluğu yoktu → `dogrulama-politikasi.md` ile kanıt seviyeleri (D0-D4) getirildi
2. Hatalar sessizce yutuluyordu → sessiz başarısızlık yasağı kuralı yazıldı
3. Kurulum tekrar üretilemezdi → FAZ 1'in tamamı buna ayrıldı
4. Tek doğruluk kaynağı yoktu (dokümanlar kendi içinde çelişiyordu) → `tasks/` tek kaynak, kök dosyalar işaretçi
5. Genişlik derinliğe tercih edilmişti (%77 ölü şema) → dikey dilim ilkesi getirildi

**Doğru yapılmış işler korundu:** identity `residents` modülü, `POST /users/me/properties` transaction'ı,
KVKK rıza akışı (backend), tahakkuk dağıtım matematiği, community talep durum makinesi ve sakin onayı,
PDF/Excel motoru, SMS/WhatsApp entegrasyon kodu, `unit_balances` view'ı, şema para tipleri (`DECIMAL`),
`.gitignore` hijyeni. Ayrıntı: `audit-raporu.md` §4.

**Not:** Bu turda hiçbir kaynak kod dosyası değiştirilmedi — yalnızca `tasks/` altındaki planlama
dosyaları yazıldı ve `.agents/AGENTS.md` silinmesi (kullanıcı tarafından) doğrulandı.
