# Backend Servis Denetimi

**Denetim kapsamı:** `backend/services/` (25 servis), `backend/pkg/` (13 paket), `backend/cmd/gateway`, `backend/api`, `backend/tests`, `backend/migrations`, `backend/go.mod`, `docker-compose.yml`, `kong/kong.yml`
**Yöntem:** Yalnızca statik kod okuma (Read/Grep/Glob/PowerShell). Go kurulu değil, `go build`/`go test` ÇALIŞTIRILMADI — derleme/çalışma zamanı iddiaları "statik olarak" işaretlendi.
**Hiçbir dosya değiştirilmedi.**

---

## Özet Sayılar

| Ölçüt | Değer | Kanıt |
|---|---|---|
| Servis sayısı | 25 (+gateway) | `backend/services/*` dizin listesi |
| Gerçek PostgreSQL bağlantısı olan servis | **3** (identity, finance, community) | `database.Connect` çağrısı yalnızca bu 3 `main.go`'da |
| JWT auth middleware bağlı servis | **3** (identity, finance, community) | `AuthMiddleware` yalnızca bu 3 `main.go`'da |
| Tamamen mock / in-memory servis | **22** | aşağıdaki tablo |
| Hiçbir yerden import edilmeyen ("ölü") pkg | **9/13** | import taraması (aşağıda) |
| MongoDB sürücüsü | **YOK** | `go.mod`'da `go.mongodb.org/*` yok, hiçbir dosyada import yok |
| Kafka kütüphanesi | **YOK** | `go.mod`'da `segmentio/kafka-go`/`confluent*` yok, import yok |
| Redis client | **YOK** | `go.mod`'da yok |
| Prod kodunu gerçekten test eden test dosyası | **1/4** (`pkg/reports/reports_test.go`) | aşağıda |
| `go build ./...` derlenir mi? | **HAYIR** — kırık import | `backend/api/handlers/api_credentials_handler.go:8` |

---

## Servis Bazlı Gerçeklik Tablosu

`DB?` = gerçek pgx/PostgreSQL bağlantısı · `Yazma kalıcı?` = POST/PUT/DELETE veriyi DB'ye yazıyor mu · `Auth?` = `middleware.AuthMiddleware()` bağlı mı · `Tenant?` = `property_id` JWT'den mi geliyor · `Port tutarlı?` = `main.go` default PORT'u gateway default'u ile aynı mı (docker-compose PORT env'i her serviste doğru veriyor)

| Servis | Dosya/Satır | DB? | Yazma kalıcı? | Auth? | Tenant? | Port tutarlı? | GERÇEK DURUM |
|---|---|---|---|---|---|---|---|
| identity | `services/identity/main.go:18,51-74` | ✅ pgx | ✅ (users, properties, units, resident_units, tx) | ✅ | ✅ JWT `property_id` | ✅ 8081 | **GERÇEK** — tek gerçek uçtan uca modül; yetki/tenant açıkları var (bkz. I-1..I-8) |
| finance | `services/finance/main.go:18,38` | ✅ pgx | ⚠️ tahakkuk ✅ / ödeme ❌ (PENDING'de kalıyor, `paid_amount` hiç güncellenmiyor) | ✅ | ✅ JWT `property_id` | ✅ 8082 | **KISMEN GERÇEK** — tahakkuk gerçek, ödeme yarım, bakiye sorgusu matematiksel olarak hatalı (F-1) |
| community | `services/community/main.go:19,37` | ✅ pgx (sadece `requests`) | ⚠️ `requests` ✅ / announcements+surveys+bulletins+reservations ❌ echo | ⚠️ sadece `/requests` grubunda | ⚠️ `requests` ✅, diğerleri yok | ✅ 8083 | **KISMEN GERÇEK** — 1 modül gerçek, 4 modül auth'suz açık mock (C-1) |
| iot | `services/iot/main.go:12-59` | ❌ | ❌ `submitReading` sabit `"consumption": 12.5` döner (`main.go:111-117`) | ❌ hiç yok | ❌ | ✅ 8084 | **TAMAMEN MOCK** — MongoDB yok, `models/iot.go` hiç import edilmiyor (ölü kod) |
| notification | `services/notification/main.go:73-97` | ❌ | ❌ `log.Printf` + "Bildirim gönderildi" | ❌ | ❌ | ✅ 8085 | **TAMAMEN MOCK** — Firebase yok, Kafka yok |
| expense | `services/expense/main.go:161-181,250-276` | ❌ | ❌ `expense.ID = "new-expense-id"` (`:203`) | ❌ | ❌ | ✅ 8086 | **TAMAMEN MOCK** — AI tarama `main.go:257` "TODO: Gerçek AI servisi entegrasyonu" |
| asset | `services/asset/main.go:234-284,395-403` | ❌ | ❌ | ❌ | ❌ `PropertyID: "prop-1"` (`:240,255,271,340,371`) | ❌ 8097 vs 8087 | **TAMAMEN MOCK** |
| banking | `services/banking/main.go:183-221` | ❌ | ❌ `createBankAccount` yanıtı geri echo eder (`:259-281`) | ❌ | ❌ `"prop-1"` (`:189,210,268`) | ❌ 8093 vs 8106 | **TAMAMEN MOCK** — `provider/turkish_banks.go` hiç import edilmiyor (B-1..B-5) |
| bulletin | `services/bulletin/main.go:106-130` | ❌ | ❌ | ❌ | ❌ | ❌ 8094 vs 8089 | **TAMAMEN MOCK** |
| contract | `services/contract/main.go:62-101` | ❌ | ❌ `createContract` → `{"id": uuid, "message": "..."}` (`:83-85`) | ❌ | ❌ | ❌ 8098 vs 8090 | **TAMAMEN MOCK** |
| document | `services/document/document_service.go:135-191` | ❌ | ❌ **gerçek `Upload()` fonksiyonu hiçbir route'a bağlı değil**; `POST /documents` (`:372-389`) sadece JSON echo | ❌ | ❌ | ✅ 8091 | **İSKELE** — `GetByID`/`List` `nil,nil` döner (`:196,208`), indirme endpoint'i yok (D-1..D-4) |
| energy_analytics | `services/energy_analytics/main.go:121-233` | ❌ | ❌ `createReading` → `{"message": "..."}` (`:131`) | ❌ | ❌ | ❌ 8102 vs 8092 | **TAMAMEN MOCK** — `health` `"ai_enabled": true` diyor, AI çağrısı yok |
| esg | `services/esg/esg_service.go:134-176,270-274` | ❌ | ❌ `RecordMetric` "// Save to database" + `return nil` (`:272-273`) ama HTTP 201 döner (`:338`) | ❌ | ❌ `site_id` query param'dan, doğrulanmıyor (`:292`) | ✅ 8093 | **TAMAMEN MOCK** — tüketim rakamları sabit (`:144-147`) |
| inventory | `services/inventory/main.go:86-160` | ❌ | ❌ `stockIn/stockOut/stockAdjust` sadece mesaj (`:139-149`) | ❌ | ❌ | ❌ 8101 vs 8094 | **TAMAMEN MOCK** — stok hareketi stok seviyesini değiştirmiyor |
| meeting_wizard | `services/meeting_wizard/main.go:145-286` | ❌ | ❌ | ❌ | ❌ | ❌ 8103 vs 8095 | **TAMAMEN MOCK** — "AI Whisper transkripsiyon" sabit metin (`:209-222`) |
| nps | `services/nps/nps_service.go:94-101,104-161` | ❌ | ❌ `SubmitResponse` "// Save to database" (`:99`) | ❌ | ❌ | ✅ 8096 | **TAMAMEN MOCK** — `CalculateNPS` sabit 12 yanıt üzerinden hesap yapar (`:106-110`) |
| package | `services/package/main.go:90-130` | ❌ | ❌ | ❌ | ❌ `"prop-1"` | ❌ 8096 vs 8097 | **TAMAMEN MOCK** |
| parking | `services/parking/main.go:174-478` | ❌ | ❌ `recordEntry` echo (`:424-440`), `recordExit` sabit `calculated_fee: 50.00` (`:451`) | ❌ | ❌ `"prop-1"` (`:179,220,245,309`) | ❌ 8091 vs 8098 | **TAMAMEN MOCK** — plaka tanıma sabit `"34 ABC 123"` (`:466-478`) |
| patrol | `services/patrol/main.go:101-165` | ❌ | ❌ | ❌ | ❌ | ✅ 8099 | **TAMAMEN MOCK** |
| personnel | `services/personnel/main.go:104-178` | ❌ | ❌ `generatePayroll` sabit `total_amount: 125000` (`:150`) | ❌ | ❌ | ✅ 8100 | **TAMAMEN MOCK** — maaş/TCKN alanları auth'suz açık (P-1) |
| reservation | `services/reservation/main.go:152-483` | ❌ | ❌ `createReservation` echo + sabit `TotalFee: 100.00` (`:423`) | ❌ | ❌ `"prop-1"` (`:157,177,194,214`) | ❌ 8092 vs 8101 | **TAMAMEN MOCK** — çakışma/kapasite/süre kontrolü hiç yok (R-1) |
| settings | `services/settings/api_credentials_service.go:157-440` | ❌ | ❌ tüm CRUD `// TODO: Veritabanına kaydet` (`:206,279,295,302,439`) | ❌ user "admin" hardcoded (`:612,625,633,640`) | ❌ | ✅ 8102 | **İSKELE** — sabit şifreleme anahtarı (`:141`), audit log no-op (S-1..S-5) |
| smart_collection | `services/smart_collection/main.go:108-245` | ❌ | ❌ | ❌ | ❌ | ❌ 8104 vs 8103 | **TAMAMEN MOCK** — "AI risk analizi" sabit yanıt (`:167-174`) |
| survey | `services/survey/main.go:141-430` | ❌ | ❌ `voteSurvey` echo (`:383-397`) | ❌ | ❌ `"prop-1"` (`:150,169,190,254,337`) | ❌ 8095 vs 8104 | **TAMAMEN MOCK** — anonim ankette oy veren adı sızdırılıyor (SV-1) |
| visitor | `services/visitor/main.go:134-419` | ❌ | ❌ `checkInVisitor`/`checkOutVisitor` sadece mesaj (`:305-329`) | ❌ | ❌ `"prop-1"` (`:141,153,237,264`) | ❌ 8090 vs 8105 | **TAMAMEN MOCK** — TCKN alanı (`VisitorIDNumber`) auth'suz (V-1) |
| gateway (dev) | `cmd/gateway/main.go:93-427` | — | ⚠️ raporlar RAM'de (`:26-33`) | ❌ **hiçbir auth yok** | ❌ | ✅ 8888 | **KISMEN GERÇEK** — reverse proxy gerçek, dashboard/rapor verisi uydurma (G-1..G-6) |

### Ölü (hiçbir yerden import edilmeyen) paketler
Tüm `.go` dosyalarındaki `github.com/siteeksen/backend/...` importları tarandı. Yalnızca şu 4 pkg import ediliyor: `pkg/audit`, `pkg/database`, `pkg/middleware`, `pkg/reports`.

| Paket | Satır | Durum |
|---|---|---|
| `pkg/tenant` | `manager.go`, `middleware.go` (294 satır) | **ÖLÜ** — hiç import edilmiyor |
| `pkg/encryption` | `aes.go` (94 satır) | **ÖLÜ** — hiç import edilmiyor |
| `pkg/payment` | `iyzico.go`, `service.go` (~470 satır) | **ÖLÜ** |
| `pkg/notification` | `fcm.go`, `service.go` (~365 satır) | **ÖLÜ** |
| `pkg/ai` | `invoice_parser.go` (226 satır) | **ÖLÜ** |
| `pkg/integrations/ai` | 352 satır | **ÖLÜ** |
| `pkg/integrations/bank` | 318 satır | **ÖLÜ** |
| `pkg/integrations/push` | 254 satır | **ÖLÜ** |
| `pkg/integrations/sms` | 291 satır | **ÖLÜ** |
| `pkg/integrations/whatsapp` | 446 satır | **ÖLÜ** |
| `services/iot/models` | `iot.go` (78 satır) | **ÖLÜ** |
| `services/banking/provider` | `turkish_banks.go` (483 satır) | **ÖLÜ** |
| `backend/api/handlers` | `api_credentials_handler.go` (247 satır) | **ÖLÜ + DERLENMİYOR** |

Toplam ≈ **3.900 satır** çalışmayan/bağlanmamış kod.

---

## İddia Doğrulama

Toplam 31 iddia denetlendi: **14 YANLIŞ**, **6 KISMEN DOĞRU**, **11 DOĞRU**.

---

### İddia: "25 servisin tamamı ✅ Servis yazıldı"
- **Kaynak:** `ROADMAP.md:19-43`
- **Verdict:** **KISMEN DOĞRU** (yanıltıcı)
- **Kanıt:** `database.Connect` çağrısı sadece `services/identity/main.go:18`, `services/finance/main.go:18`, `services/community/main.go:19`'da. Diğer 22 serviste ne pgx importu ne `pool.Query`/`pool.Exec` çağrısı var.
- **Gerçek durum:** 22 servis HTTP iskeleti + sabit JSON. "Servis yazıldı" ifadesi teknik olarak doğru (dosya var, derleniyor, ayağa kalkıyor) ama işlevsel olarak hiçbiri veri saklamıyor. `ROADMAP.md:22` "MongoDB bağlı", `:23` "Firebase + Kafka" gibi ek nitelemeler açıkça yanlış.

---

### İddia: "identity-service: Gerçek residents/units modülü — resident_units/users/units JOIN sorgularıyla DB'ye bağlandı"
- **Kaynak:** `ROADMAP.md:47`, `ROADMAP.md:19`
- **Verdict:** **DOĞRU**
- **Kanıt:** `services/identity/repository/resident.go:51-61` — `FROM resident_units ru JOIN users u ON ru.resident_id = u.id JOIN units un ON ru.unit_id = un.id WHERE un.property_id = $1 AND u.deleted = 0`; `:100-146` `Create` gerçek `tx` içinde users+resident_units yazıyor; `:172-179` `ListUnits` gerçek `units` sorgusu. Route'lar `services/identity/main.go:61-74`'te kayıtlı, `AuthMiddleware` bağlı.
- **Gerçek durum:** Gerçek. Fakat yetki/tenant açıkları var (bkz. I-3, I-4).

---

### İddia: "POST /users/me/properties (identity) ile site + varsayılan unit + resident_units(OWNER) tek transaction'da oluşturuluyor"
- **Kaynak:** `ROADMAP.md:99`
- **Verdict:** **DOĞRU**
- **Kanıt:** `services/identity/repository/user.go:101-143` — `tx, err := r.pool.Begin(ctx)` → `INSERT INTO properties` → `INSERT INTO units` → `INSERT INTO resident_units (... 'OWNER')` → `tx.Commit(ctx)`. `defer tx.Rollback(ctx)` mevcut.
- **Gerçek durum:** Doğru ve doğru yazılmış. Yan bulgu: `units` satırı `share_ratio = 0` ile açılıyor (`:123`) — o birim tahakkuka hiç katılamaz; ayrıca ilk kez site oluşturmak isteyen `RESIDENT` rollü kullanıcı `RequireRole`'e takılır (I-5).

---

### İddia: "KVKK açık rıza akışı — identity-service POST /users/me/kvkk-consent + login yanıtında kvkk_consent_required"
- **Kaynak:** `ROADMAP.md:54`
- **Verdict:** **DOĞRU**
- **Kanıt:** Route: `services/identity/main.go:57`. Handler: `handlers/auth.go:134-143`. Repo: `repository/user.go:94-98` — `UPDATE users SET kvkk_consent_at = NOW() ... WHERE id = $1 AND kvkk_consent_at IS NULL` (idempotent, doğru). Login yanıtı: `service/auth.go:62` `KVKKConsentRequired: user.KVKKConsentAt == nil`, JSON alanı `models/user.go:40`. Migration: `migrations/009_kvkk_consent.sql:5`.
- **Gerçek durum:** Doğru.

---

### İddia: "finance: gerçek POST /assessments (gider kalemlerini SHARE_RATIO/EQUAL/AREA_M2'ye göre dağıtım)"
- **Kaynak:** `ROADMAP.md:20`
- **Verdict:** **DOĞRU** (matematik doğru, para hassasiyeti hatalı)
- **Kanıt:** `services/finance/repository/finance.go:399-545`. Tek transaction (`:405-409`, `:530`). Dağıtım:
  - `EQUAL` (`:464-470`): `share := item.Amount / float64(len(eligible))`
  - `AREA_M2` (`:471-484`): `ratio := u.grossAreaM2 / totalArea` — `totalArea == 0` kontrolü `:476` ✅
  - `SHARE_RATIO`/default (`:485-499`): `ratio := u.shareRatio / totalRatio` — `totalRatio == 0` kontrolü `:490` ✅
- **share_ratio toplamı 100 değilse:** Sorun **yok**. Kod paydayı `totalRatio = Σ shareRatio(eligible)` olarak dinamik hesapladığı için (`:486-489`), toplam 100 olmasa da paylar oransal ve toplamı `item.Amount`'a eşit çıkar. `properties.total_share_ratio` sütunu hiç kullanılmıyor.
- **Sıfıra bölme:** Üç yolun hepsi korunmuş (`:459` `len(eligible)==0` → `continue`; `:476`; `:490`).
- **Kuruş yuvarlama:** **HATA VAR.** Hiçbir yerde yuvarlama yok, tüm hesap `float64`. `monthly_assessments.total_amount` `DECIMAL(12,2)` (`migrations/001_initial_schema.sql:151`) olduğundan PostgreSQL sessizce yuvarlar → birim paylarının toplamı `item.Amount`'tan sapabilir (ör. 1000 TL / 3 birim = 333.33+333.33+333.33 = 999.99, 1 kuruş kaybolur). Kalan kuruşu bir birime yükleyen düzeltme adımı yok. `assessment_details.amount` da aynı sorunu taşır ve `Σ assessment_details.amount ≠ monthly_assessments.total_amount` olabilir. (F-3)
- **Mükerrer dönem:** `:511-514` `pgErr.Code == "23505"` → `ErrAssessmentPeriodExists`. `23505` PostgreSQL `unique_violation` kodudur ✅ ve `migrations/001_initial_schema.sql:158` `UNIQUE(unit_id, period_year, period_month)` kısıtı gerçekten var ✅.

---

### İddia: "finance: GET /expense-categories, GET /debtors, rol-duyarlı GET /payments, GET /assessments/overview"
- **Kaynak:** `ROADMAP.md:20`
- **Verdict:** **DOĞRU**
- **Kanıt:** Route'lar `services/finance/main.go:42,46,49,53`. Gerçek sorgular: `repository/finance.go:548-571` (expense-categories), `:260-290` (debtors), `:293-339` (ListPropertyPayments), `:118-150` (ListAssessmentPeriods). Rol duyarlılığı: `service/finance.go:154-159` — `isFinanceManagement(roles)` → site geneli, aksi halde `GetPaymentHistory(userID)`.
- **Gerçek durum:** Doğru. Ancak hiçbirinde sayfalama yok, `ListPropertyPayments`/`GetPaymentHistory` sabit `LIMIT 50` (F-6), `ListDebtors` sadece `role='OWNER'` sakinleri sayar (F-7).

---

### İddia: "finance | ✅ | 8082 | Docker'da aktif, **iyzico entegre**" / "iyzico (ödeme) ✅ Sandbox bağlantısı kurulu"
- **Kaynak:** `ROADMAP.md:20`, `ROADMAP.md:195`
- **Verdict:** **YANLIŞ**
- **Kanıt:** `services/finance/service/finance.go:138-142`:
  ```go
  // TODO: Ödeme gateway entegrasyonu (iyzico, Param vb.)
  // Şimdilik mock checkout URL döndür
  checkoutURL := ""
  if method == "CREDIT_CARD" {
      checkoutURL = "https://checkout.siteeksen.com/pay/" + paymentID
  }
  ```
  `services/finance/` altında `pkg/payment` veya `pkg/integrations/bank` importu **yok** (import taraması). `docker-compose.yml:104-106` `IYZICO_API_KEY`/`IYZICO_SECRET_KEY`/`IYZICO_BASE_URL` env'lerini geçiyor ama hiçbir kod bunları okumuyor (`os.Getenv("IYZICO_*")` yalnızca ölü `pkg/payment/iyzico.go:24,30,31`'de).
- **Gerçek durum:** Ödeme yok. `POST /payments` sadece `payments` tablosuna `status='PENDING'` satır atar (`repository/finance.go:206-224`), hiç tamamlanmaz, `monthly_assessments.paid_amount` asla güncellenmez. `tasks/todo.md:117` de zaten "📌 Iyzico Entegrasyonu (Sonradan yazılacak - Ertelendi)" diyor → **ROADMAP.md ile todo.md birbiriyle çelişiyor.**

---

### İddia: "community-service mock'tan gerçek DB-bağlı requests modülüne geçirildi; sakin onaylayabiliyor (CLOSED + user_confirmed_at) ya da reddedip IN_PROGRESS'e geri gönderebiliyor"
- **Kaynak:** `ROADMAP.md:128`
- **Verdict:** **DOĞRU**
- **Kanıt:**
  - Gerçek DB: `services/community/repository/request.go:103-115` (`INSERT INTO requests ... RETURNING`), `:48-69` (liste), `:118-133` (UpdateStatus), `:136-158` (ConfirmResolution).
  - Durum makinesi: `services/community/service/request.go:57-60`
    ```go
    var allowedStatusTransitions = map[string]string{
        models.StatusOpen:       models.StatusInProgress,
        models.StatusInProgress: models.StatusResolved,
    }
    ```
    ve `:73-75` kontrolü. `CLOSED`'a doğrudan geçiş gerçekten mümkün değil.
  - `POST /requests/:id/confirm-resolution`: `main.go:42` → `handlers/request.go:85-108` → `service/request.go:82-96` (sahiplik kontrolü `:88`, durum kontrolü `:91`) → `repository/request.go:138-150` (`status='CLOSED', user_confirmed_at=NOW(), closed_at=NOW()`) / `:145-149` (red: `status='IN_PROGRESS', resolved_at=NULL`).
  - Migration: `migrations/010_request_confirmation.sql:6`.
- **Gerçek durum:** Doğru ve titiz yazılmış. Tek eksik: yönetici `UpdateStatus`'ta property kontrolü yok (C-2).

---

### İddia: "iot | ✅ | 8084 | Docker'da aktif, **MongoDB bağlı**"
- **Kaynak:** `ROADMAP.md:22`, `ROADMAP.md:181`
- **Verdict:** **YANLIŞ**
- **Kanıt:** `services/iot/main.go:1-10` importları: yalnızca `log`, `net/http`, `os`, `time`, `github.com/gin-gonic/gin`. `go.mod`'da hiç MongoDB sürücüsü yok (`go.mod:5-17` ve indirect blok tarandı). Tüm repoda `mongo` importu yok. `docker-compose.yml:146` `MONGO_URL` env'ini veriyor, hiç okunmuyor. `mongodb` container'ı ayakta ama hiçbir istemcisi yok.
- **Gerçek durum:** MongoDB bağlantısı yok. IoT servisinin tamamı sabit JSON (`main.go:63-266`).

---

### İddia: "Faz 4: Sayaç Yönetimi Servis Katmanı (Tamamlandı) — Sayaç listeleme, okuma ekleme ve bulk okuma işlemlerini iot-service üzerinden DB şemasına bağla ✅"
- **Kaynak:** `tasks/todo.md:80-83`
- **Verdict:** **YANLIŞ**
- **Kanıt:** `services/iot/main.go:63-89` `listMeters` — sabit iki sayaç (`"mtr-001"`, `"mtr-002"`), `meterType` query param sadece yanıta `"filter"` olarak geri yazılıyor (`:87`). `:100-118` `submitReading` — DB yazımı yok, `"consumption": 12.5` sabit döndürülüyor (`:115`). `:120-129` `getReadingHistory` — sabit üç dönem. `meters`/`meter_readings` tabloları `migrations/001_initial_schema.sql`'de var ama IoT servisi onlara hiç dokunmuyor. "Bulk okuma" endpoint'i hiç yok (`main.go:21-28` route listesi).
- **Gerçek durum:** Sayaç yönetimi tamamen mock. `services/iot/models/iot.go` (78 satır, `Meter`/`MeterReading` modelleri) hiçbir yerden import edilmiyor.

---

### İddia: "notification | ✅ | 8085 | Docker'da aktif, **Firebase + Kafka**" / "Kafka consumer'ları genişlet (şu an sadece notification servisi tüketiyor)"
- **Kaynak:** `ROADMAP.md:23`, `ROADMAP.md:60`
- **Verdict:** **YANLIŞ**
- **Kanıt:** `services/notification/main.go:1-10` importları: `log`, `net/http`, `os`, `time`, `gin`. Firebase importu yok, Kafka importu yok, consumer/goroutine yok. Gönderim mantığı `:81-91`:
  ```go
  case "PUSH":
      // Firebase FCM
      log.Printf("Sending push notification to %v", req.Recipients)
  ```
  `registerDevice` (`:214-227`) token'ı hiçbir yere yazmıyor. `docker-compose.yml:170` `KAFKA_BROKERS`, `:171` `FIREBASE_PROJECT_ID`, `:183-184` `firebase-credentials.json` mount'u var — hiçbiri okunmuyor.
- **Gerçek durum:** Ne Firebase ne Kafka. "Şu an sadece notification servisi tüketiyor" ifadesi tamamen asılsız — repoda hiçbir Kafka consumer'ı yok.

---

### İddia: "pkg/audit/ paketi ve gerçek INSERT INTO audit_logs ile tamamlanan AuditLog() middleware'i identity/finance route gruplarına bağlandı"
- **Kaynak:** `ROADMAP.md:54`
- **Verdict:** **KISMEN DOĞRU** (INSERT gerçek; bağlı gruplar dokümandan farklı)
- **Kanıt:**
  - Gerçek INSERT: `pkg/audit/audit.go:27-32` — `INSERT INTO audit_logs (user_id, user_ip, user_agent, action, resource_type, resource_id, old_values, new_values) VALUES (NULLIF($1,'')::uuid, NULLIF($2,'')::inet, ...)`. Tablo `migrations/001_initial_schema.sql`'de mevcut ve sütunlar birebir uyuyor. ✅
  - Middleware: `pkg/middleware/auth.go:108-128`.
  - **Bağlı route grupları (4 tane, dokümanda 2 yazıyor):**
    | Grup | Dosya:satır | resourceType |
    |---|---|---|
    | `/api/v1/users` | `services/identity/main.go:51` | `"user"` |
    | `/api/v1/residents` | `services/identity/main.go:62` | `"resident"` |
    | `/api/v1/finance` | `services/finance/main.go:38` | `"finance"` |
    | `/api/v1/requests` | `services/community/main.go:37` | `"request"` |
  - **Bağlı OLMAYAN:** `/api/v1/units` (`services/identity/main.go:71` — sadece `AuthMiddleware`, `AuditLog` yok), community'nin diğer 4 grubu, ve 22 mock servisin tamamı.
- **Gerçek durum:** INSERT gerçek. Ama: (a) `resourceType` sabit, `resource_id` hep `c.Param("id")` — POST/liste isteklerinde boş → `NULL` yazılıyor (`auth.go:123`); (b) `old_values`/`new_values` her zaman `nil` (`:124-125`) → "ne değişti" hiç kayıtlanmıyor; (c) hata yutuluyor: `_ = audit.LogAction(...)` (`:115`); (d) `c.Next()`'ten SONRA çalıştığı için 401/403 ile abort edilen istekler de loglanıyor; (e) her `GET /users/me` bir satır yazıyor → tablo şişmesi + istek başına senkron INSERT gecikmesi.

---

### İddia: "RBAC: RequireRole() middleware'i MANAGER/AUDITOR/STAFF rol sabitleriyle birlikte POST /users/me/properties endpoint'ine bağlandı"
- **Kaynak:** `ROADMAP.md:55`
- **Verdict:** **DOĞRU** (iddia edildiği kadar sınırlı — o da doğru)
- **Kanıt:** Tüm repoda `RequireRole` çağrısı **tek** yerde: `services/identity/main.go:55`
  ```go
  protected.POST("/me/properties", middleware.RequireRole(middleware.RoleManager, middleware.RoleOwner), handlers.CreateProperty(authService))
  ```
  Rol sabitleri `pkg/middleware/auth.go:15-22`. Migration `migrations/008_manager_roles.sql:7-10` demo yöneticiye `MANAGER` ekliyor.
- **Gerçek durum:** Doğru. Not: bağlanan roller `MANAGER` + **OWNER**, dokümandaki `MANAGER/AUDITOR/STAFF` üçlüsü değil. `AUDITOR`/`STAFF` kontrolü middleware yerine servis katmanındaki `isResidentManagement`/`isFinanceManagement`/`isManagement` fonksiyonlarında elle yapılıyor (`identity/service/resident.go:30-38`, `finance/service/finance.go:17-25`, `community/service/request.go:31-39`) — üç yerde birebir kopyalanmış (kod tekrarı).

---

### İddia: "AuthMiddleware() JWT süreleri 15dk / 7gün"
- **Kaynak:** Görev tanımı (dolaylı olarak `ROADMAP.md` erişim/oturum iddiaları)
- **Verdict:** **DOĞRU**
- **Kanıt:** `services/identity/service/auth.go:138-140`:
  ```go
  now := time.Now()
  accessExpiry := now.Add(15 * time.Minute)
  refreshExpiry := now.Add(7 * 24 * time.Hour)
  ```
- **Gerçek durum:** Doğru. Ancak `pkg/middleware/auth.go:54-56` doğrulamada `jwt.WithValidMethods([...])` kullanmıyor ve `JWT_SECRET` boşsa boş anahtarla imza doğruluyor (I-1).

---

### İddia: "X-Tenant-ID yaklaşımı geri alındı, o middleware hiç bağlı değil"
- **Kaynak:** `CHANGELOG.md` (kullanıcı tarafından aktarıldı)
- **Verdict:** **DOĞRU**
- **Kanıt:** `pkg/tenant/middleware.go:19-67` `TenantMiddleware()` tanımlı. Tüm repoda `pkg/tenant` importu **yok** (import taraması: yalnızca `pkg/audit`, `pkg/database`, `pkg/middleware`, `pkg/reports` import ediliyor). `.Use(tenant.` veya `TenantMiddleware()` çağrısı hiçbir dosyada yok.
- **Gerçek durum:** Doğrulandı. `pkg/tenant` (294 satır) tamamen ölü kod. Tek kalıntı: `cmd/gateway/main.go:61` CORS başlığında hâlâ `X-Tenant-ID` izin veriliyor (zararsız ama temizlenmeli). Ayrıca `pkg/tenant/middleware.go:141` `EnforceLimits` içi `// TODO` + `c.Next()` — hiç kontrol yapmıyor.

---

### İddia: "pkg/encryption: AES-256-GCM TCKN/telefon için kullanılıyor"
- **Kaynak:** Görev tanımı / şema tasarımı (`users.tc_encrypted`, `tc_hash`, `phone_encrypted`)
- **Verdict:** **YANLIŞ**
- **Kanıt:** `pkg/encryption/aes.go:31,52,83,89` — `Encrypt`, `Decrypt`, `Hash`, `MaskTCKN` fonksiyonları tanımlı. `pkg/encryption` importu tüm repoda **yok**. `encryption.NewService(` / `.Encrypt(` çağrısı hiçbir servis dosyasında yok.
- **Gerçek durum:** TCKN/telefon şifrelemesi hiç kullanılmıyor. `services/identity/repository/user.go:23,148` `tc_encrypted`/`tc_hash` sütunlarını okuyup yazıyor ama değerler hiçbir zaman şifrelenmiyor — `Create` (`:146-156`) `user.TCEncrypted`'i olduğu gibi yazıyor ve `CreateResident` akışı (`repository/resident.go:119-123`) bu sütunları hiç doldurmuyor. `services/personnel/main.go:19` (`TCNumber`) ve `services/visitor/main.go:23` (`VisitorIDNumber`) TCKN'yi düz metin JSON olarak, auth'suz endpoint'lerden servis ediyor.
- **Ek hata (E-1):** `pkg/encryption/aes.go:89-94` `MaskTCKN` — `len(tckn) >= 4 && len(tckn) < 8` durumunda `tckn[len(tckn)-8:]` negatif indeks → **panic**.

---

### İddia: "Faz 5: Raporlama Servis Katmanı (Tamamlandı) — Gerçek PDF/Excel rapor üretecek entegrasyonu pkg/reports ile gateway'e bağla ✅" / "Backend birim testleri (pkg/reports için PDF/Excel testleri yazıldı ve doğrulandı) ✅"
- **Kaynak:** `tasks/todo.md:85-88`, `tasks/todo.md:111`
- **Verdict:** **KISMEN DOĞRU**
- **Kanıt:**
  - Üretici gerçek: `cmd/gateway/main.go:16` `pkg/reports` importu; `:336` `reports.NewExcelGenerator()`, `:357` `reports.NewPDFGenerator()`; `pkg/reports/pdf.go` (`gofpdf`), `pkg/reports/excel.go` (`excelize/v2`) — `go.mod:11,13`'te bağımlılıklar mevcut.
  - Testler var: `pkg/reports/reports_test.go:7-38` (PDF), `:40-71` (Excel).
  - **AMA rapor verisi tamamen uydurma:** `cmd/gateway/main.go:338-354` ve `:358-374` — `PropertyName: "SiteEksen Yönetim"`, `Period: "Temmuz 2026"`, `UnitAssessments: [{UnitName: "A Blok Daire 1", ResidentName: "Ahmet Yılmaz", ...}]`. `req.Type` ve `req.Params` (`:312-314`) **yalnızca `format` için** okunuyor (`:328`), gerisi yok sayılıyor. Hangi siteyi/dönemi istediğinizden bağımsız aynı sahte PDF üretilir.
- **Gerçek durum:** PDF/Excel motoru gerçek ve test edilmiş; rapor içeriği sahte. Testler ise sadece "hata dönmedi + byte dizisi boş değil" kontrolü yapıyor (`reports_test.go:31-37`, `:64-70`) — hiçbir içerik/toplam/format doğrulaması yok. Auth da yok (G-4).

---

### İddia: "Faz 3: Dashboard Genel İstatistikleri (Aggregator) (Tamamlandı) — Gateway mock dashboard stats handler'larını kaldır ✅ / Backend stats aggregator uç noktasını geliştir ✅"
- **Kaynak:** `tasks/todo.md:75-78`
- **Verdict:** **YANLIŞ** (kod yazılmış ama çalışmıyor — her zaman mock döner)
- **Kanıt:** `cmd/gateway/main.go:221-277`. Sabit değerler hâlâ orada (`:223-232`: `totalResidents: 156, totalUnits: 180, pendingRequests: 12, activeVisitors: 3, upcomingMeetings: 2`) ve **hiç override edilemez**, çünkü `fetchJSON` zarf (envelope) uyumsuzluğu yüzünden her zaman hata döner:
  - `fetchJSON` (`:429-464`) yanıtı önce `{success, data, error}` zarfına açmayı dener; koşul `:459` `if err := json.Unmarshal(bodyBytes, &outer); err == nil && outer.Success`.
  - identity `GET /api/v1/residents` yanıtı: `services/identity/handlers/resident.go:47` → `gin.H{"data": residents}` — **`success` alanı YOK** → `outer.Success == false` → koşul başarısız.
  - Fallback `:463` `json.Unmarshal(bodyBytes, target)` — `target` `*[]interface{}`, gövde ise JSON **object** (`{"data":[...]}`) → tip hatası → `err != nil`.
  - Sonuç: `:236-238`, `:242-244`, `:248-259`, `:263-265`, `:269-271` bloklarının **hiçbiri** çalışmaz.
  - Aynı sorun tüm alt servislerde: community `handlers/request.go:34` `{"data": ...}`; visitor `main.go:164-167` `{"visitors": ..., "total": ...}`; meeting `main.go:152` `{"meetings": ...}`.
- **Gerçek durum:** Dashboard istatistikleri her koşulda sabit 156/180/12/3/2 döner. Ek: `:282` `financeURL+"/api/v1/payments"` çağrısı da **404** alır çünkü finance yalnızca `/api/v1/finance/payments`'ı kaydediyor (`services/finance/main.go:53`) → `recent-payments` hep boş dizi (`:285`).

---

### İddia: "AI fatura tarama ✅ OpenAI Vision / Google Document AI"
- **Kaynak:** `ROADMAP.md:199`, `ROADMAP.md:154` ("Gider Yönetimi ✅ AI fatura tarama dahil")
- **Verdict:** **YANLIŞ**
- **Kanıt:** Kullanıcının çağırdığı endpoint `POST /api/v1/expenses/scan-invoice` → `services/expense/main.go:250-276`:
  ```go
  // TODO: Gerçek AI servisi entegrasyonu
  // Bu mock response, gerçekte OpenAI GPT-4 Vision veya Google Document AI kullanılacak
  result := AIInvoiceScanResult{ Success: true, VendorName: "AYEDAŞ Elektrik Dağıtım A.Ş.", TotalAmount: 2450.75, Confidence: 0.94, ... }
  ```
  Gerçek OpenAI kodu `pkg/ai/invoice_parser.go:139-193`'te var ama **hiçbir yerden import edilmiyor**. `pkg/integrations/ai/ai_service.go` de (352 satır, OpenAI Vision + Gemini + Whisper) ölü. Google Document AI ise açıkça stub: `pkg/ai/invoice_parser.go:201-205` → `// TODO: Gerçek entegrasyon` + `Error: "Google Document AI henüz yapılandırılmamış"`.
- **API key yokken ne olur:** `pkg/ai/invoice_parser.go:60` `os.Getenv("OPENAI_API_KEY")` — boş olabilir, kontrol edilmiyor. `:145` `req.Header.Set("Authorization", "Bearer "+p.openAIKey)` → `"Bearer "` gönderilir, OpenAI 401 döner, HTTP status **kontrol edilmiyor** (`:148-154`), hata gövdesi `openAIResp`'e parse edilir, `Choices` boş kalır, `:170` **"AI yanıt vermedi"** hatası döner — yani yapılandırma hatası "AI cevap vermedi" olarak maskelenir. Model adı `:119` `"gpt-4-vision-preview"` — kullanımdan kaldırılmış model.
- **Gerçek durum:** Kullanıcıya dönen her fatura taraması sabit AYEDAŞ faturasıdır.

---

### İddia: "Banka entegrasyonu ✅ services/banking/turkish_banks.go"
- **Kaynak:** `ROADMAP.md:200`
- **Verdict:** **YANLIŞ** (yol da yanlış, içerik de stub, üstelik ölü kod)
- **Kanıt:**
  1. **Yol yanlış:** Dosya `services/banking/turkish_banks.go` değil, `services/banking/provider/turkish_banks.go` (`package provider`).
  2. **Hiç import edilmiyor:** `services/banking/main.go:1-11` importları: `log`, `net/http`, `os`, `time`, `gin`, `uuid`. `provider` paketi hiçbir yerden import edilmiyor → derlenir ama hiç çalışmaz.
  3. **5 bankanın 4'ü boş stub:** `provider/turkish_banks.go:245` (Garanti), `:339` (İş Bankası), `:385` (Yapı Kredi), `:292` (Akbank) → hepsi `return []BankTransaction{}, nil`.
  4. **Ziraat "gerçek" görünen tek sağlayıcı da yanıtı atıyor:** `:188-195`
     ```go
     body, _ := io.ReadAll(resp.Body)
     var transactions []BankTransaction
     // XML parsing logic...
     _ = body
     return transactions, nil
     ```
     → HTTP status kontrolü yok, XML parse yok, her zaman `nil` döner.
  5. **Otomatik eşleştirme motorunun 2 kuralı ölü:** `:540-548`
     ```go
     func containsName(text, name string) bool { return false }
     func containsUnitNo(text, unitNo string) bool { return false }
     ```
     → `MatchTransaction` (`:471-485` "İsim + Tutar" kuralı ve `:505-518` "Daire no" kuralı) asla tetiklenmez. Sadece IBAN eşleşmesi (`:457-468`) ve tam-tutar önerisi (`:489-502`) çalışır.
  6. **`ValidateCredentials` her banka için `return nil`** (`:205,255,302,348,394`) → geçersiz kimlik bilgisi "geçerli" kabul edilir.
- **Ek güvenlik (B-5):** `:155-174` banka kullanıcı adı/şifresi XML gövdesine `fmt.Sprintf` ile kaçış yapılmadan gömülüyor → **XML injection**.

---

### İddia: "SMS servisi ✅ pkg/integrations/sms/ hazır" / "WhatsApp ✅ pkg/integrations/whatsapp/ hazır"
- **Kaynak:** `ROADMAP.md:197-198`
- **Verdict:** **KISMEN DOĞRU** (kod gerçek, hiçbir yere bağlı değil)
- **Kanıt:** `pkg/integrations/sms/sms_service.go` — Netgsm (`:81-137`, gerçek `httpClient.Do`, Netgsm XML API, yanıt kodu kontrolü `:120`) ve İleti Merkezi (`:222-261`) sağlayıcıları gerçek. `pkg/integrations/whatsapp/whatsapp_service.go:302-357` gerçek WhatsApp Cloud API çağrısı + şablon yönetimi. **AMA:** her ikisi de hiçbir yerden import edilmiyor. `services/notification/main.go:86-87` SMS gönderimini `log.Printf("Sending SMS to %v", ...)` ile yapıyor.
- **Yarım kalan kısımlar:** `sms_service.go:158-161` `GetBalance` — `Balance: 0, // Parse from body` (parse edilmiyor); `:165-171` `GetDeliveryReport` ve `:264-277` (İleti Merkezi) muhtemelen stub.
- **Çelişki:** `tasks/todo.md:118` "📌 WhatsApp Entegrasyonu (Sonradan yapılacak - Ertelendi)" — `ROADMAP.md:198` ✅ diyor. İki doküman çelişiyor.

---

### İddia: "Firebase (push) ✅ firebase-credentials.json gerekli"
- **Kaynak:** `ROADMAP.md:196`
- **Verdict:** **YANLIŞ**
- **Kanıt:** İki ayrı gerçek FCM implementasyonu var, **ikisi de ölü**: `pkg/notification/fcm.go:161-194` (ham FCM v1 HTTP + OAuth2 JWT) ve `pkg/integrations/push/push_service.go:66-92` (resmi `firebase.google.com/go/v4` Admin SDK). Hiçbiri import edilmiyor. `services/notification/main.go` gin dışında hiçbir şey import etmiyor.
- **Ek:** `pkg/notification/fcm.go:25` `os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")` bekliyor; `docker-compose.yml:171-184` ise `FIREBASE_PROJECT_ID` verip dosyayı `/app/firebase-credentials.json`'a mount ediyor ama **`GOOGLE_APPLICATION_CREDENTIALS` env'ini set etmiyor** → bağlansaydı bile kimlik bilgisi yüklenmeyecekti. `:28-34` `credPath == ""` durumunda `credentials` nil kalır, `NewFCMClient` yine de başarı döner, hata ancak ilk gönderimde `google.JWTConfigFromJSON(nil, ...)` ile ortaya çıkar (N-1).

---

### İddia: "Backend birim testleri" / "Her servis için birim testleri yaz (şu an sadece tests/integration_test.go var) 📋"
- **Kaynak:** `tasks/todo.md:111`, `ROADMAP.md:57`
- **Verdict:** **YANLIŞ** (test dosyaları var ama 3'ü hiçbir şeyi doğrulamıyor; doküman ayrıca envanteri yanlış sayıyor)
- **Kanıt:** 4 test dosyası mevcut:

  | Dosya | Satır | Prod kodu çalıştırıyor mu? |
  |---|---|---|
  | `pkg/reports/reports_test.go` | 62 | ✅ EVET — `NewPDFGenerator()`, `GenerateAssessmentReport()` gerçek |
  | `services/identity/handlers/auth_test.go` | 237 | ❌ HAYIR |
  | `services/finance/handlers/finance_test.go` | 234 | ❌ HAYIR |
  | `tests/integration_test.go` | 238 | ❌ HAYIR |

  - `services/finance/handlers/finance_test.go:208-279` `setupFinanceRouter()` — test dosyasının **kendi içinde** yazılmış inline handler'ları test ediyor. `handlers.CreateAssessment` / `handlers.CreatePayment` gibi gerçek handler'lar **hiç çağrılmıyor**. Ör. `:224-241` test router'ı `POST /assessments`'ı `{"id":"assess-new","message":"Assessment created"}` döndüren bir kapanışa bağlıyor; `TestCreateAssessment_Success` (`:20-46`) bunu doğruluyor.
  - `finance_test.go:281-287` `calculateLateFee` — **prod kodunda böyle bir fonksiyon yok**, yalnızca test dosyasında tanımlı. `TestLateFeeCalculation` (`:151-171`) kendi yazdığı fonksiyonu test ediyor. Aynısı `identity/handlers/auth_test.go:247-294` `validatePassword`/`validatePhone` için geçerli — prod kodunda karşılıkları yok, gerçek şifre politikası hiçbir yerde uygulanmıyor.
  - `finance_test.go:174-205` `TestDistributionCalculation` — dağıtım hesabını test dosyasının içinde yeniden yazıp onu doğruluyor (`:188`, `:199`); `repository.CreateAssessment`'ın gerçek matematiği test edilmiyor.
  - `tests/integration_test.go:218-299` — 9 endpoint'in hepsi `mockLogin`, `mockCreateAssessment`, `mockCreatePayment` vb. sahte handler'lar (`:253-299`). `setupIntegrationRouter()` hiçbir gerçek servisi, DB'yi veya handler'ı devreye almıyor. `mockAuthMiddleware` (`:243-251`) yalnızca `Authorization` başlığının **var olup olmadığına** bakıyor, JWT doğrulamıyor.
  - `auth_test.go:124` ve `:138` — "testler" iki farklı sonucu birden kabul ediyor: `assert.Contains(t, []int{http.StatusOK, http.StatusUnauthorized}, w.Code)` → her durumda geçer.
- **Gerçek durum:** Gerçek kapsam ~ **%0,5** (yalnızca 2 PDF/Excel smoke testi, o da içerik doğrulamıyor). Ayrıca `ROADMAP.md:57` "şu an sadece tests/integration_test.go var" diyor ama 3 test dosyası daha var → envanter yanlış.

---

### İddia: "Kong kong.yml güncellendi — 24 servis (tüm mikroservisler) Kong üzerinden yönlendiriliyor" / "Gateway v1.2.0 — 24 servise proxy routing"
- **Kaynak:** `ROADMAP.md:52-53`, `tasks/todo.md:51`
- **Verdict:** **KISMEN DOĞRU**
- **Kanıt:** `kong/kong.yml` 24 farklı `url: http://<servis>:<port>` içeriyor — banking hariç tüm servisler (`banking-service:8106` **yok**). `cmd/gateway/main.go:94-118` ise banking dahil **25** servis URL'i tanımlıyor (`:118` `BANKING_SERVICE_URL`). `ROADMAP.md:183` de "Kong güncelleme (yeni servisler) 📋 20+ servis kong.yml'e eklenmeli" diyor → **aynı doküman içinde `:52` ile `:183` çelişiyor**.
- **Gerçek durum:** Kong 24/25 servisi kapsıyor, banking eksik. "Tüm mikroservisler" yanlış.

---

### İddia: "PostgreSQL + migrations ✅ 5 migration tamamlandı"
- **Kaynak:** `ROADMAP.md:179`
- **Verdict:** **YANLIŞ**
- **Kanıt:** `backend/migrations/` içinde **10** dosya var: `001_initial_schema.sql` … `010_request_confirmation.sql`. Dokümanın kendisi `ROADMAP.md:56`'da 006/008/009/010'dan bahsediyor → iç çelişki.

---

### İddia: "Backend soft-delete altyapısı — Migration 006 (23 tablo + index), identity ve finance repository sorgularına AND deleted = 0 filtresi"
- **Kaynak:** `ROADMAP.md:97`, `tasks/todo.md:42-45`
- **Verdict:** **KISMEN DOĞRU**
- **Kanıt:**
  - `migrations/006_soft_delete.sql:6-28` → **22** `ALTER TABLE` (23 değil): users, units, announcements, requests, payments, meters, meter_readings, monthly_assessments, +14 diğer. `resident_units`, `properties`, `expense_categories`, `assessment_details`, `payment_assessments`, `parking_logs`, `patrol_sessions` **kapsam dışı**.
  - `:31-38` → **8** index (22 tablo için).
  - Filtre uygulanan sorgular: `identity/repository/user.go:26,46`; `identity/repository/resident.go:56,86,116`; `finance/repository/finance.go:59,76,97,123,158,269,306`.
  - **Filtre UYGULANMAYAN sorgular:** `identity/repository/user.go:62-68` (`GetUserProperties` — `resident_units`/`units`/`properties` JOIN'i, hiç filtre yok); `identity/repository/resident.go:173-179` (`ListUnits` — `units.deleted` sütunu var ama filtrelenmiyor); `finance/repository/finance.go:194-199` (`CalculateTotalAmount`), `:227-234` (`GetPaymentHistory` — `payments.deleted` var, filtre yok), `:170-175` (`assessment_details`), `:343-353` (`consumption_invoices`); `community/repository/request.go:49,61,91` (`requests.deleted` sütunu **var**, hiçbir sorguda filtre **yok** → silinmiş talepler listelerde görünür).
  - **Şema çelişkisi:** `migrations/005_new_modules.sql:437-439` `is_deleted BOOLEAN` + `deleted_at` + `deleted_by` kullanıyor; 006 aynı projeye `deleted INTEGER` getiriyor → **iki farklı soft-delete konvansiyonu bir arada**.
- **Gerçek durum:** Altyapı kısmen var, uygulanması delik dolu.

---

### İddia: "Go modülü / bağımlılıklar tutarlı"
- **Kaynak:** Görev maddesi 14
- **Verdict:** **YANLIŞ — repo derlenmiyor (statik tespit)**
- **Kanıt (3 bağımsız kanıt, hepsi aynı dosyada):** `backend/api/handlers/api_credentials_handler.go:8`
  ```go
  import (
      ...
      "sitesen/backend/services/settings"
  )
  ```
  1. **Modül yolu yanlış:** `backend/go.mod:1` → `module github.com/siteeksen/backend`. `sitesen/backend/...` diye bir modül ne go.mod'da `require` edilmiş ne de yerel `replace` var → `go build ./...` "no required module provides package sitesen/backend/services/settings" ile başarısız olur.
  2. **Hedef paket `main`:** `services/settings/api_credentials_service.go:1` → `package main`. Doğru yol yazılsa bile bir `package main` başka paketten import **edilemez**.
  3. **`services/settings` içinde `main()` fonksiyonu var** (`:584`) — bu dizin bir kütüphane değil, çalıştırılabilir.
  Ayrıca aynı dosya `settings.Service`, `settings.CreateRequest` gibi tipleri referanslıyor; bunlar `package main` içinde tanımlı (`api_credentials_service.go:132,103`).
- **Gerçek durum:** `go build ./...` / `go vet ./...` / `go test ./...` bu repo kökünde **başarısız olur**. Tek tek servis derlemesi (`go build ./services/identity`) çalışır, bu yüzden Docker imajları sorunsuz üretilir ve hata gizli kalır. `backend/api/` dizini hiçbir Dockerfile'da build edilmiyor.
- **Diğer bağımlılık kontrolleri (temiz):** Kullanılan tüm dış importlar go.mod'da mevcut — `gin`, `jwt/v5`, `uuid`, `pgx/v5`(+`pgconn`,`pgxpool`), `gofpdf`, `excelize/v2`, `testify`, `bcrypt`, `oauth2/google`, `google.golang.org/api/option`, `firebase.google.com/go/v4`(+`messaging`). Aynı pakette çakışan tanım bulunamadı (`pkg/payment/iyzico.go` `PaymentRequest`/`PaymentResponse` vs `pkg/payment/service.go` `AssessmentPaymentInput`/`PaymentResult` — çakışma yok).

---

### İddia: "Tüm 19 yeni servis docker-compose.yml'e eklendi — port atandı, Dockerfile yazıldı, hepsi çalışıyor"
- **Kaynak:** `ROADMAP.md:51`
- **Verdict:** **KISMEN DOĞRU**
- **Kanıt:** `docker-compose.yml` 25 servis + gateway + kong + 5 altyapı tanımlıyor; her mock servise `PORT` env'i (`:229,240,251,262,273,284,295,306,317,328,339,350,361,372,383,394,405,416,427`) veriliyor ve **bu değerler gateway/kong ile birebir tutarlı** (aşağıdaki tablo).
- **AMA:** `ROADMAP.md:24-43` hâlâ "docker-compose'a eklenmedi" diyor (18 satırda) → **ROADMAP kendi kendisiyle çelişiyor** (`:51` vs `:24-43`).
- **AMA:** `main.go` içindeki **default** portlar 13 serviste yanlış (bkz. bulgu **X-1**).

---

## Mantık Hataları ve Eksiklikler

Öncelik: 🔴 kritik · 🟠 yüksek · 🟡 orta

---

### Çapraz kesen bulgular

#### 🔴 X-0 — Repo bir bütün olarak derlenmiyor
- **Bulgu:** `go build ./...` kırık import nedeniyle başarısız.
- **Kanıt:** `backend/api/handlers/api_credentials_handler.go:8` → `"sitesen/backend/services/settings"` (modül `github.com/siteeksen/backend`, hedef `package main`).
- **Neden sorun:** CI'da `go build ./...` / `go vet ./...` / `go test ./...` çalıştırılamaz; bu yüzden diğer tüm statik hatalar da yakalanmıyor. `.github/workflows/ci-cd.yaml`'ın gerçekten derleme yapıyorsa yeşil olması imkânsız (o dosya bu denetimin kapsamında incelenmedi — **doğrulanamadı: dosya okunmadı**).
- **Önerilen çözüm:** `backend/api/` dizinini sil (ölü kod, `RequireSuperAdmin` da güvensiz — bkz. A-1) veya settings servisini `package settings` kütüphanesi + ince `cmd/settings/main.go` şeklinde ayır ve importu `github.com/siteeksen/backend/services/settings` yap. CI'ya `go build ./... && go vet ./...` ekle.

#### 🔴 X-1 — 13 servisin main.go default PORT'u gateway/compose ile uyuşmuyor; 4 çift çakışıyor
- **Kanıt:**

  | Servis | `main.go` default | gateway default (`cmd/gateway/main.go`) | compose `PORT` | Durum |
  |---|---|---|---|---|
  | asset | 8097 (`asset/main.go:185`) | 8087 (`:100`) | 8087 (`:229`) | ✗ |
  | bulletin | 8094 (`bulletin/main.go`) | 8089 (`:101`) | 8089 (`:240`) | ✗ |
  | contract | 8098 (`contract/main.go:56`) | 8090 (`:102`) | 8090 (`:251`) | ✗ |
  | energy_analytics | 8102 (`main.go:115`) | 8092 (`:104`) | 8092 (`:273`) | ✗ |
  | inventory | 8101 (`main.go:80`) | 8094 (`:106`) | 8094 (`:306`) | ✗ |
  | meeting_wizard | 8103 (`main.go:139`) | 8095 (`:107`) | 8095 (`:317`) | ✗ |
  | package | 8096 (`main.go:125`) | 8097 (`:109`) | 8097 (`:339`) | ✗ |
  | parking | 8091 (`main.go:164`) | 8098 (`:110`) | 8098 (`:350`) | ✗ |
  | reservation | 8092 (`main.go:142`) | 8101 (`:113`) | 8101 (`:383`) | ✗ |
  | smart_collection | 8104 (`main.go:102`) | 8103 (`:115`) | 8103 (`:405`) | ✗ |
  | survey | 8095 (`main.go:131`) | 8104 (`:116`) | 8104 (`:416`) | ✗ |
  | visitor | 8090 (`main.go:124`) | 8105 (`:117`) | 8105 (`:427`) | ✗ |
  | banking | 8093 (`main.go:173`) | 8106 (`:118`) | 8106 (`:295`) | ✗ |

  **Default port çakışmaları (aynı porta iki servis):** 8091 = document + parking · 8093 = esg + banking · 8096 = nps + package · 8102 = energy_analytics + settings.
- **Neden sorun:** Docker'da `PORT` env'i verildiği için gizli kalıyor. `PORT` set edilmeyen her ortamda (yerel `go run`, k8s manifest'te env eksikse, tek konteyner testi) gateway 502 verir; çakışan çiftler yerelde aynı anda ayağa kalkamaz ("address already in use").
- **Önerilen çözüm:** Her `main.go` default'unu compose/gateway değeriyle eşitle; ya da default'u kaldırıp `PORT` yoksa `log.Fatal` at (fail-fast). Tek kaynak-doğruluk için port haritasını ortak bir sabit dosyasına taşı.

#### 🔴 X-2 — 22 servis tamamen kimlik doğrulamasız; gateway de auth uygulamıyor
- **Kanıt:** `AuthMiddleware` yalnızca `identity/main.go:51,62,71`, `finance/main.go:38`, `community/main.go:37`'de. `cmd/gateway/main.go:422` `handler := logMiddleware(corsMiddleware(mux))` — auth middleware yok; `proxyPaths` (`:84-91`) doğrudan `mux.Handle(p, proxy)`.
- **Sonuç:** `http://gateway:8888/api/v1/employees` (maaşlar), `/api/v1/payroll`, `/api/v1/visitors` (TCKN alanı), `/api/v1/credentials` (API anahtarı yazma/silme), `/api/v1/bank-accounts` (IBAN), `/api/v1/reports/generate`, `/api/v1/announcements` (POST/PUT/DELETE) → **token olmadan** erişilebilir. CORS `Access-Control-Allow-Origin: *` (`:59`) ile birlikte herhangi bir web sayfasından çağrılabilir.
- **Önerilen çözüm:** Gateway'e zorunlu JWT doğrulama katmanı ekle (allowlist: `/health`, `/api/v1/auth/*`); ayrıca her servise `AuthMiddleware` bağla (defense in depth). Kong'da `jwt` plugin'i tanımla.

#### 🟠 X-3 — Para birimi her yerde `float64`
- **Kanıt:** `finance/models/finance.go:12-15,26-28,84`; `finance/repository/finance.go:44,200,432,465,481,495`; `expense/main.go:20`; `banking/main.go:44,101`; `personnel/main.go:25,36-40`.
- **Neden sorun:** İkili kayan nokta ile kuruş toplamları birikimli hata verir (`0.1+0.2 != 0.3`); DB `DECIMAL(12,2)` ile gidiş-dönüşte sessiz yuvarlama; muhasebe mutabakatı bozulur.
- **Önerilen çözüm:** Para için `int64` kuruş veya `shopspring/decimal`; pgx tarafında `pgtype.Numeric`. En azından dağıtımda banker's rounding + kalan kuruşu deterministik bir birime yükleyen düzeltme.

#### 🟠 X-4 — `deleted` filtreleri tutarsız + iki farklı soft-delete konvansiyonu
- **Kanıt:** Yukarıdaki "soft-delete" iddia doğrulamasındaki filtre-uygulanmayan sorgu listesi; `migrations/005_new_modules.sql:437-439` `is_deleted BOOLEAN` vs `migrations/006_soft_delete.sql:6` `deleted INTEGER`.
- **Neden sorun:** `community` silinmiş talepleri listeler; `GetUserProperties` silinmiş birim/siteyi kullanıcının profiline koyar → JWT'ye silinmiş `property_id` yazılabilir.
- **Önerilen çözüm:** Tek konvansiyon (`deleted_at TIMESTAMPTZ NULL` önerilir); her tabloya `WHERE deleted_at IS NULL` filtreli VIEW ya da repository katmanında zorunlu helper; CI'da "filtre içermeyen SELECT" lint'i.

#### 🟠 X-5 — Sayfalama hiçbir listede yok
- **Kanıt:** `finance/repository/finance.go:232` `LIMIT 50` sabit (offset/cursor yok), `:312` sabit `LIMIT 50`; `:271` `ListDebtors` limitsiz; `identity/repository/resident.go:60` `ORDER BY u.first_name` limitsiz; `:178` `ListUnits` limitsiz; `community/repository/request.go:55,67` limitsiz.
- **Neden sorun:** 500 daireli bir sitede `GET /residents` tüm satırları çeker; ödeme geçmişi 50'de kesilir ve kullanıcı geri kalanına **hiç** erişemez (sayfa 2 yok).
- **Önerilen çözüm:** `limit`/`cursor` (keyset) parametreleri + `X-Total-Count`; maksimum sayfa boyutu sınırı.

#### 🟡 X-6 — Aynı entegrasyon 2-3 kez yazılmış (ölü kopya)
- **Kanıt:** iyzico: `pkg/payment/iyzico.go` **ve** `pkg/integrations/bank/payment_service.go:118-322`. FCM: `pkg/notification/fcm.go` (ham HTTP) **ve** `pkg/integrations/push/push_service.go` (Admin SDK). OpenAI Vision: `pkg/ai/invoice_parser.go` **ve** `pkg/integrations/ai/ai_service.go:56-129`. Türk banka listesi: `services/banking/main.go:108-121` **ve** `services/banking/provider/turkish_banks.go:16-27`. Karbon ayak izi: `services/esg/esg_service.go:134-176` **ve** `services/energy_analytics/main.go:215-219` (farklı sayılar!).
- **Neden sorun:** Hangisinin "doğru" olduğu belirsiz; bakım maliyeti; `ROADMAP.md:200`'ün yanlış dosyayı göstermesi bu karmaşanın sonucu.
- **Önerilen çözüm:** Her entegrasyon için bir kanonik paket seç, diğerlerini sil.

#### 🟡 X-7 — `context.Background()` kullanımı (istek iptali yayılmıyor)
- **Kanıt:** `services/esg/esg_service.go:296,308,324,337`; `services/nps/nps_service.go:265,275,282,291`; `services/document/document_service.go:350,361,391,398`; `services/settings/api_credentials_service.go:599,612,625,633,640,648`.
- **Neden sorun:** İstemci bağlantıyı kesince alt işlem devam eder; timeout/iptal yayılmaz; DB bağlandığında sızan sorgular.
- **Önerilen çözüm:** `c.Request.Context()` kullan.

---

### identity-service

#### 🔴 I-1 — `JWT_SECRET` boşsa boş anahtarla token doğrulanır + hardcoded default secret
- **Kanıt:** `pkg/middleware/auth.go:54-56`
  ```go
  token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
      return []byte(os.Getenv("JWT_SECRET")), nil
  })
  ```
  Boş/eksik kontrolü yok. `services/identity/main.go:26` `service.NewAuthService(userRepo, os.Getenv("JWT_SECRET"))` — aynı şekilde doğrulanmıyor. `docker-compose.yml:82,103,126,147,172` default: `${JWT_SECRET:-your-super-secret-jwt-key-change-in-production}`.
- **Neden sorun:** `JWT_SECRET` set edilmemiş bir ortamda HS256 boş anahtarla imzalanır → saldırgan istediği `user_id`/`property_id`/`roles` ile token üretip tüm siteleri yönetebilir. Compose default'u kaynak kodda göründüğü için de sır sayılmaz. Ayrıca `WithValidMethods` verilmediğinden imza algoritması allowlist'lenmiyor.
- **Önerilen çözüm:** Başlangıçta `JWT_SECRET` uzunluk kontrolü + yoksa `log.Fatal`; `jwt.ParseWithClaims(..., jwt.WithValidMethods([]string{"HS256"}), jwt.WithIssuer(...))`; compose'dan default'u kaldır (zorunlu env yap).

#### 🔴 I-2 — `POST /users/me/active-property` sahiplik doğrulamıyor → tam yatay yetki yükseltme
- **Kanıt:** `services/identity/repository/user.go:87-91`
  ```go
  func (r *UserRepository) SetActiveProperty(ctx context.Context, userID, propertyID string) error {
      query := `UPDATE users SET active_property_id = $1, updated_at = NOW() WHERE id = $2`
      _, err := r.pool.Exec(ctx, query, propertyID, userID)
      return err
  }
  ```
  Handler `handlers/auth.go:112-131` ve servis `service/auth.go:118-120` de kontrol eklemiyor — `resident_units`'te böyle bir bağ olup olmadığı **hiç** sorulmuyor.
- **Neden sorun:** Herhangi bir oturum açmış kullanıcı **başka bir sitenin** `property_id`'sini kendi aktif sitesi yapabilir; ardından `POST /auth/refresh` ile o `property_id`'yi taşıyan yeni access token alır (`service/auth.go:69-85` → `generateTokens` → `:145` `"property_id": user.ActivePropertyID`). Sonrasında `GET /residents`, `GET /finance/debtors`, `GET /finance/assessments/overview`, `GET /requests` o sitenin verisini döndürür. **Multi-tenant izolasyonunun tek dayanağı olan `property_id` istemci tarafından seçilebilir hale gelir.** (Rol kontrolü ayrı bir bariyer ama `MANAGER` rolü olan bir yönetici bu yolla tüm sitelere yönetici olur.)
- **Önerilen çözüm:**
  ```sql
  UPDATE users SET active_property_id = $1 WHERE id = $2
    AND EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON ru.unit_id = u.id
                WHERE ru.resident_id = $2 AND u.property_id = $1 AND ru.is_active = true)
  ```
  ve `RowsAffected() == 0` → 403.

#### 🟠 I-3 — Roller siteye göre değil global; `resident_units.role` ile `users.roles` ayrışmış
- **Kanıt:** `users.roles TEXT[]` global (`identity/repository/user.go:24`), JWT'ye olduğu gibi konuyor (`service/auth.go:146`). Yetki kararları bu global listeye bakıyor (`service/resident.go:30-38`, `finance/service/finance.go:17-25`, `community/service/request.go:31-39`). Site bazlı rol ise ayrı bir yerde: `resident_units.role` (`repository/resident.go:34,164`).
- **Neden sorun:** A sitesinde `MANAGER` olan biri, B sitesinde sadece `RESIDENT` olsa dahi B'de de yönetici sayılır (I-2 ile birleşince tam ihlal).
- **Önerilen çözüm:** Yetkiyi `(user_id, property_id)` çiftine bağla; JWT'ye aktif site için hesaplanmış rolleri koy; `users.roles`'u yalnızca platform-seviyesi roller (SUPERADMIN) için kullan.

#### 🟠 I-4 — `CreateResident` başka siteye ait mevcut kullanıcıyı sessizce kendi birimine bağlıyor (tenant sızıntısı + hesap ele geçirme)
- **Kanıt:** `services/identity/repository/resident.go:115-129`
  ```go
  err = tx.QueryRow(ctx, `SELECT id, first_name FROM users WHERE phone = $1 AND deleted = 0`, input.Phone).Scan(&userID, &existingName)
  switch {
  case errors.Is(err, pgx.ErrNoRows):
      // yeni kullanıcı oluştur
  case err != nil:
      return nil, err
  }
  // (mevcut kullanıcı bulunduysa hiçbir kontrol yapılmadan aşağıya devam ediliyor)
  ```
  Sonra `:132-136` `INSERT INTO resident_units (resident_id, unit_id, role)`. `ErrPhoneAlreadyExists` (`:19`) tanımlı ama **hiçbir yerde return edilmiyor** — sadece handler'da haritalanmış (`handlers/resident.go:30-31`) → ölü hata yolu.
- **Neden sorun:** A sitesinin yöneticisi, B sitesindeki bir sakinin telefon numarasıyla "sakin ekle" yaparsa: (a) o kullanıcı A sitesine bağlanır ve `GET /users/me/properties` sonucunda kurbanın uygulamasında A sitesi görünür; (b) yöneticinin `GET /residents` yanıtı kurbanın gerçek adı/soyadı/e-postasını döndürür (`residentColumns` `:31-35`) → KVKK ihlali; (c) `existingName` okunup hiç kullanılmıyor (kimlik teyidi yok).
- **Önerilen çözüm:** Mevcut kullanıcı bulunduğunda ya `ErrPhoneAlreadyExists` döndür ya da kullanıcıya OTP/onay isteyen bir davet akışı kur; asla sessizce bağlama.

#### 🟠 I-5 — `POST /users/me/properties` ilk site oluşturmayı imkânsız kılıyor (chicken-and-egg)
- **Kanıt:** `services/identity/main.go:55` `RequireRole(RoleManager, RoleOwner)`. Yeni sakin oluşturma yolu ise sadece `ARRAY['RESIDENT']` veriyor: `identity/repository/resident.go:121`. Kayıt (self-signup) endpoint'i hiç yok (`main.go:41-46` sadece login/refresh/logout).
- **Neden sorun:** Sıfırdan bir yönetici hesabı yalnızca `migrations/008_manager_roles.sql`'deki gibi elle SQL ile açılabilir. Onboarding akışı yok.
- **Önerilen çözüm:** İlk site oluşturmayı role bağlama (herkes kendi taşınmazını oluşturabilir, oluşturan OWNER olur) ya da ayrı bir davet/kayıt akışı.

#### 🟡 I-6 — `POST /auth/logout` hiçbir şey yapmıyor; access token iptal edilemiyor
- **Kanıt:** `services/identity/handlers/auth.go:78-83`
  ```go
  func Logout(svc *service.AuthService) gin.HandlerFunc {
      return func(c *gin.Context) {
          // Token'ı blacklist'e ekle
          c.JSON(http.StatusOK, gin.H{"message": "Çıkış başarılı"})
      }
  }
  ```
  `svc` parametresi hiç kullanılmıyor. Redis compose'da var (`docker-compose.yml:24-31`, `REDIS_URL` `:83`) ama hiçbir kod bağlanmıyor.
- **Neden sorun:** Çalınan token 15 dk, refresh token 7 gün boyunca geçerli kalır; şifre değişikliği/hesap pasifleştirme oturumu düşürmez (`Update` ile `is_active=false` yapılan sakin çalışmaya devam eder).
- **Önerilen çözüm:** `jti` bazlı Redis denylist (TTL = token exp) + refresh token rotasyonu ve reuse-detection.

#### 🟡 I-7 — Refresh token, access token'dan ayırt edilmiyor
- **Kanıt:** `service/auth.go:143-150` access token `jwt.MapClaims` ile `"sub"` içeriyor; `:158-163` refresh token `jwt.RegisteredClaims{Subject: user.ID}`. `RefreshToken` (`:70-77`) gelen token'ı `&jwt.RegisteredClaims{}`'e parse edip yalnızca imza+exp kontrol ediyor; `typ`/`token_use` claim'i yok.
- **Neden sorun:** Access token doğrudan refresh endpoint'ine verilerek yeni token çifti alınabilir; refresh token'lar da `Authorization: Bearer` ile korunan endpoint'lerde kabul edilir (`pkg/middleware/auth.go` de tür ayrımı yapmıyor) — sadece `roles` boş olur.
- **Önerilen çözüm:** Her iki token'a `"typ":"access"` / `"typ":"refresh"` claim'i ekle ve doğrulamada zorunlu tut.

#### 🟡 I-8 — `Update` read-modify-write, transaction yok (kayıp güncelleme)
- **Kanıt:** `identity/repository/resident.go:149-169` — `GetByID` (`:150`) ile mevcut değerler okunuyor, sonra ayrı bir `r.pool.Exec` (`:164`) ile yazılıyor; arada transaction/kilit yok. Aynı desen `community/service/request.go:68-77` (`GetByID` → `UpdateStatus`).
- **Neden sorun:** İki yönetici eşzamanlı düzenlerse biri diğerinin değişikliğini ezer; community'de durum makinesi TOCTOU ile atlanabilir (iki istek aynı anda `OPEN` görüp ikisi de geçiş yapar).
- **Önerilen çözüm:** Tek atomik `UPDATE ... WHERE id = $1 AND status = $2` (koşullu geçiş) ve `RowsAffected()==0` → 409.

#### 🟡 I-9 — Boş `property_id` ile DB tip hatası → 500
- **Kanıt:** `handlers/resident.go:40` `propertyID := c.GetString("property_id")`; JWT'de `active_property_id` NULL ise `''` gelir (`repository/user.go:24` `COALESCE(active_property_id::text, '')`). Sorgu `repository/resident.go:56` `WHERE un.property_id = $1` → PostgreSQL `22P02 invalid input syntax for type uuid`. Handler `mapResidentError` default dalına düşer → 500 "Sakinler alınamadı".
- **Neden sorun:** Aktif site seçmemiş kullanıcı anlamsız 500 alır; hata mesajı yanıltıcı.
- **Önerilen çözüm:** Handler'da boş `property_id` → 400 "Aktif site seçilmemiş".

---

### finance-service

#### 🔴 F-1 — `GetUnitBalance` bakiyeyi kullanıcı sayısıyla çarpıyor (kartezyen join)
- **Kanıt:** `services/finance/repository/finance.go:35-43`
  ```sql
  SELECT COALESCE(SUM(ll.debit_amount) - SUM(ll.credit_amount), 0) as balance
  FROM ledger_lines ll
  JOIN users u ON ll.unit_id = (
      SELECT ru.unit_id FROM resident_units ru
      WHERE ru.resident_id = $1 AND ru.is_active = true
      LIMIT 1
  )
  ```
- **Neden sorun:** `JOIN users u ON <sabit koşul>` — join koşulu `u` tablosuna hiç referans vermiyor, dolayısıyla `users` tablosuyla **kartezyen çarpım** oluşuyor. Koşul doğruysa her `ledger_lines` satırı `users` tablosundaki satır sayısı kadar tekrarlanır → `SUM` **kullanıcı sayısıyla çarpılır**. 200 kullanıcılı bir sistemde 500 TL borç 100.000 TL görünür. Bu değer doğrudan sakine gösterilen `current_balance` ve `has_debt` alanlarını besliyor (`service/finance.go:49,66-67`).
- **Ek:** `LIMIT 1` `ORDER BY` olmadan kullanılıyor → iki daireli bir sakinin hangi dairesi seçileceği belirsiz; `ledger_lines.deleted` filtresi yok; `ledger_lines` tablosunun varlığı `migrations/001_initial_schema.sql`'de doğrulanamadı (`ledger_entries` var — **doğrulanamadı: `ledger_lines` CREATE TABLE ifadesi grep'te görülmedi**, tablo yoksa sorgu tamamen hata verir).
- **Önerilen çözüm:**
  ```sql
  SELECT COALESCE(SUM(debit_amount - credit_amount), 0) FROM ledger_lines
  WHERE unit_id IN (SELECT unit_id FROM resident_units WHERE resident_id=$1 AND is_active) AND deleted = 0
  ```
  + birim testi.

#### 🔴 F-2 — Ödeme akışı yarım: kalıcı değil, transaction'sız, hata yutulmuş, doğrulamasız, idempotent değil
- **Kanıt:** `services/finance/repository/finance.go:206-224`
  ```go
  paymentID := uuid.New().String()
  query := `INSERT INTO payments (id, user_id, amount, payment_method, status, created_at) VALUES ($1,$2,$3,$4,'PENDING',NOW())`
  _, err := r.pool.Exec(ctx, query, paymentID, userID, amount, method)
  if err != nil { return "", err }
  for _, aID := range assessmentIDs {
      linkQuery := `INSERT INTO payment_assessments (payment_id, assessment_id) VALUES ($1, $2)`
      r.pool.Exec(ctx, linkQuery, paymentID, aID)   // <-- dönüş değeri ve hata TAMAMEN yok sayılıyor
  }
  ```
- Sorunların dökümü:
  1. **Transaction yok:** `payments` yazılıp `payment_assessments` yazılamazsa yarım kayıt kalır.
  2. **Hata yutuluyor (`:220`):** `r.pool.Exec(...)` sonucu hiç atanmıyor → foreign key hatası, mükerrer PK (`migrations/001` `PRIMARY KEY (payment_id, assessment_id)`) sessizce kaybolur.
  3. **`payment_assessments.amount` hiç yazılmıyor** (tablo sütunu var) → hangi tahakkuğa ne kadar düştüğü kayıtsız.
  4. **`monthly_assessments.paid_amount`/`status` hiç güncellenmiyor** — tüm repoda `UPDATE monthly_assessments` ifadesi yok. Yani ödeme yapan sakinin borcu asla düşmez; `ListDebtors` (`:269` `ma.total_amount > ma.paid_amount`) onu sonsuza dek borçlu gösterir.
  5. **Sahiplik doğrulaması yok:** `CalculateTotalAmount` (`:194-199`) `WHERE id = ANY($1)` — `assessmentIDs`'in çağıran kullanıcıya/siteye ait olup olmadığı **kontrol edilmiyor**. Kullanıcı başka birinin tahakkuk ID'lerini gönderip tutarını öğrenebilir ve o tahakkuklara kendi ödemesini bağlayabilir.
  6. **`CalculateTotalAmount`'ta `deleted = 0` yok** (`:198`) → silinmiş tahakkuklar da toplanır.
  7. **Idempotency yok:** Aynı `POST /payments` iki kez gönderilirse iki `PENDING` ödeme oluşur; `Idempotency-Key` desteği yok.
  8. **Tutar istemciden hiç doğrulanmıyor** ama istemci `amount` göndermiyor da — `handlers/finance.go:130-135` `CreatePaymentRequest`'te `amount` alanı **yok**, tutar sunucuda hesaplanıyor (`service/finance.go:127`) — bu kısım **doğru**. Ancak `tests/integration_test.go:124` ve `finance_test.go:76` `"amount"` gönderiyor → testler gerçek sözleşmeyle uyuşmuyor (ek kanıt: testler prod kodunu çalıştırmıyor).
  9. **Webhook/callback yok:** `service/finance.go:142` sahte checkout URL'i döndürülüyor, ödemeyi `COMPLETED`'a çeken hiçbir endpoint yok (`main.go:39-57` route listesi).
- **Önerilen çözüm:** Tüm akışı tek `tx` içine al; `payment_assessments.amount` yaz; `monthly_assessments`'ı `FOR UPDATE` ile kilitleyip `paid_amount`/`status` güncelle; `assessmentIDs`'i `JOIN resident_units/units` ile çağıranın sitesine/dairesine kısıtla; `Idempotency-Key` tablosu; gerçek gateway + imza doğrulamalı webhook.

#### 🟠 F-3 — Tahakkuk dağıtımında kuruş kaybı ve `assessment_details` toplamı tutmuyor
- **Kanıt:** `finance/repository/finance.go:465,481,495` — `share` hiç yuvarlanmıyor; `:509` `total`, `:524` `d.amount` `DECIMAL(12,2)` sütunlarına yazılıyor (`migrations/001_initial_schema.sql:151`, assessment_details `amount DECIMAL(12,2)`).
- **Neden sorun:** `Σ(birim payları) ≠ gider kalemi tutarı`; `Σ(assessment_details.amount) ≠ monthly_assessments.total_amount`. Yasal olarak tahakkuk toplamının gider toplamına eşit olması gerekir.
- **Önerilen çözüm:** Kuruş cinsinden `int64` ile hesapla, `largest remainder` yöntemiyle kalan kuruşları en yüksek paylı birimlere dağıt, sonra tek seferde yaz; commit öncesi `Σ details == total` assert'i.

#### 🟠 F-4 — `GET /assessments/:id` yetki ve tenant kontrolü yok (IDOR)
- **Kanıt:** Route `finance/main.go:48`; handler `handlers/finance.go:84-95` — yalnızca `c.Param("id")` alıyor, `user_id`/`property_id`/`roles` hiç kullanılmıyor; servis `service/finance.go:95-97` doğrudan repo'ya geçiyor; repo `repository/finance.go:153-191` sorgusu `WHERE id = $1 AND deleted = 0` — sahiplik/site kontrolü **yok**.
- **Neden sorun:** Oturum açmış herhangi bir kullanıcı, UUID'yi bildiği/tahmin ettiği **her sitedeki her dairenin** tahakkuk detayını (tutar, dönem, gider kalemi kırılımı) okuyabilir.
- **Önerilen çözüm:** Sorguya `AND property_id = $2` ve sakin ise `AND unit_id IN (kullanıcının birimleri)` ekle.

#### 🟠 F-5 — Hata mesajları istemciye sızıyor
- **Kanıt:** `finance/handlers/finance.go:33-35`
  ```go
  default:
      c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
  ```
  `mapAssessmentError` her eşleşmeyen hatayı — DB hataları dahil — ham metin olarak döndürüyor. Aynı desen `expense/main.go:149,200,227`, `esg/esg_service.go:298`, `settings/api_credentials_service.go:601,614,627`, `document/document_service.go:352,363,392`.
- **Neden sorun:** PostgreSQL hata metinleri tablo/sütun adlarını, kısıt adlarını, hatta değerleri açığa çıkarır (bilgi toplama).
- **Önerilen çözüm:** Beklenmeyen hatalarda genel mesaj + sunucu tarafında `log.Error` (correlation ID ile).

#### 🟡 F-6 — `ListPropertyPayments` N+1 benzeri korelasyonlu alt sorgu + çoklu-site sızıntısı
- **Kanıt:** `finance/repository/finance.go:301-310`
  ```sql
  LEFT JOIN units un ON un.id = ( SELECT ru.unit_id FROM resident_units ru
      WHERE ru.resident_id = u.id AND ru.is_active = true LIMIT 1 )
  WHERE p.deleted = 0 AND EXISTS ( SELECT 1 FROM resident_units ru2 JOIN units un2 ...
      WHERE ru2.resident_id = u.id AND un2.property_id = $1 )
  ```
- **Neden sorun:** (a) Satır başına korelasyonlu alt sorgu — index yoksa ağır. (b) `LIMIT 1` `ORDER BY`'sız → gösterilen daire rastgele. (c) `EXISTS` filtresi *kullanıcının* siteye üyeliğini kontrol ediyor, *ödemenin* hangi siteye ait olduğunu değil → iki sitede dairesi olan bir sakinin B sitesindeki aidat ödemesi, A sitesinin yöneticisine tutar+isim olarak görünür (**tenant sızıntısı**). `payments.unit_id` sütunu (`migrations/001`) mevcut ama hiç doldurulmuyor/kullanılmıyor.
- **Önerilen çözüm:** `payments.unit_id`'yi ödeme oluşturulurken doldur; filtreyi `payment_assessments → monthly_assessments.property_id = $1` üzerinden kur; JOIN'i tek geçişli hale getir.

#### 🟡 F-7 — `ListDebtors` yalnızca OWNER sakinleri gösteriyor, kiracılı daireler kayboluyor
- **Kanıt:** `finance/repository/finance.go:267` `JOIN resident_units ru ON ru.unit_id = un.id AND ru.is_active = true AND ru.role = 'OWNER'`.
- **Neden sorun:** Aktif OWNER kaydı olmayan (yalnızca TENANT'lı veya boş) daireler borç listesinde **hiç görünmez** → toplam borç eksik raporlanır. Ayrıca `JOIN users u` üzerinde `u.deleted = 0` filtresi yok.
- **Önerilen çözüm:** `LEFT JOIN` ile borcu daire bazında raporla, sorumlu kişiyi ayrı sütunda göster (yoksa NULL); `u.deleted = 0` ekle.

#### 🟡 F-8 — `GetPaymentHistory`'de kontrolsüz tip dönüşümü (panic riski)
- **Kanıt:** `finance/repository/finance.go:244-253`
  ```go
  var txID, completedAt interface{}
  ...
  if txID != nil { p.TransactionID = txID.(string) }
  if completedAt != nil { p.CompletedAt = completedAt.(time.Time) }
  ```
  Aynısı `:324,329-333`.
- **Neden sorun:** `, ok` formu kullanılmadığından beklenmedik bir sürücü tipi (ör. `pgtype.Text`, sürücü sürümü değişimi) doğrudan **panic** eder ve servis 500 verir.
- **Önerilen çözüm:** `*string` / `*time.Time` hedeflerine tara veya `COALESCE`/`NULLIF` ile SQL'de normalize et.

#### 🟡 F-9 — Tahakkuk oluşturmada eksik doğrulamalar + belirsiz sıralama
- **Kanıt:** `finance/repository/finance.go:400-403` `due_date` sadece format kontrolü — geçmiş tarih, dönemle tutarsız tarih kabul edilir. `:504` `for unitID, total := range unitTotals` — Go map iterasyonu **rastgele sıralı** → INSERT sırası nondeterministik (deadlock riski, tekrarlanamayan testler). `:436-447` her gider kalemi için ayrı `SELECT expense_categories` (kalem sayısı kadar sorgu — küçük N ama tek `WHERE id = ANY(...)` ile yapılabilir). `late_fee` hiç hesaplanmıyor (sütun var, hep 0). `PeriodYear` üst/alt sınırı yok (`models/finance.go:75` sadece `required`).
- **Önerilen çözüm:** `due_date >= MAKE_DATE(period_year, period_month, 1)` doğrulaması; birimleri `sort.Slice` ile deterministik sırala; kategorileri tek sorguda çek; `period_year` aralık kontrolü.

---

### community-service

#### 🔴 C-1 — 4 modül (announcements, surveys, bulletins, reservations) auth'suz ve kalıcı olmayan mock
- **Kanıt:** `services/community/main.go:46-83` — dört `r.Group` da `.Use(middleware.AuthMiddleware())` **içermiyor** (kıyasla `:37` requests grubunda var). Handler'lar: `:98-115` `listAnnouncements` sabit veri; `:121-134` `createAnnouncement` → `{"id": "ann-new", "message": "Duyuru oluşturuldu"}`; `:136-150` update/delete/pin/markAsRead sadece mesaj; `:154-191` surveys; `:195-216` bulletins; `:220-252` reservations.
- **Neden sorun:** Gateway `/api/v1/announcements`'ı buraya proxy'liyor (`cmd/gateway/main.go:151`) → **token olmadan** `POST/PUT/DELETE /api/v1/announcements` çağrılabilir. Kullanıcı duyuru oluşturunca 201 alır ama veri kaybolur (sessiz veri kaybı). `announcements` tablosu `migrations/001`'de mevcut ve `006`'da `deleted` sütunu bile eklenmiş — yani şema hazır, kod bağlanmamış.
- **Önerilen çözüm:** Bu 4 modülü `requests` modülüyle aynı repository/service/handler desenine taşı; ara adım olarak en azından `AuthMiddleware` + `501 Not Implemented` döndür (sahte 201 yerine).

#### 🟠 C-2 — Yönetici durum güncellemesinde site kontrolü yok (cross-tenant yazma)
- **Kanıt:** `community/service/request.go:63-78` — `isManagement(roles)` kontrolü var, ama `req.PropertyID` ile çağıranın `property_id`'si **karşılaştırılmıyor** (handler `handlers/request.go:68` `property_id`'yi servise hiç geçirmiyor). Repo `repository/request.go:118-133` `WHERE id = $1` — property filtresi yok. `GetByID` (`:90-100`) de filtresiz.
- **Neden sorun:** Herhangi bir sitenin yöneticisi, UUID'sini bildiği **başka bir sitedeki** talebi `IN_PROGRESS`/`RESOLVED` yapabilir. `ConfirmResolution` (`:82-96`) sahiplik kontrolü yapıyor (`:88`) — orada sorun yok.
- **Önerilen çözüm:** `UpdateStatus` imzasına `propertyID` ekle; sorguya `AND property_id = $3` koy.

#### 🟡 C-3 — `requests` sorgularında `deleted = 0` filtresi yok
- **Kanıt:** `community/repository/request.go:49,61,91` — üç sorguda da filtre yok. Oysa `migrations/006_soft_delete.sql:9` `requests.deleted` sütununu ekliyor ve `:33` index oluşturuyor.
- **Neden sorun:** Admin panelin sildiği talepler API'de görünmeye devam eder → "sildim ama geri geldi".
- **Önerilen çözüm:** `AND deleted = 0`; ayrıca silme endpoint'i hiç yok (`main.go:38-43`) — soft-delete kim yapıyor belirsiz (**doğrulanamadı: silme yalnızca frontend'de olabilir**).

#### 🟡 C-4 — `unit_id` hiç yazılmıyor; ticket numarası çakışabilir
- **Kanıt:** `community/repository/request.go:105-106` `INSERT INTO requests (property_id, resident_id, category_id, ticket_number, ...)` — `unit_id` kolonu listede yok, hep NULL. Model'de alan var (`models/request.go:17`). Ticket: `service/request.go:51` `fmt.Sprintf("TLP-%s", strings.ToUpper(uuid.New().String()[:8]))` — 8 hex karakter (32 bit); tablo `migrations/001_initial_schema.sql:368` `ticket_number VARCHAR(20) UNIQUE NOT NULL`.
- **Neden sorun:** Hangi daireden geldiği kaydedilmiyor → daire bazlı talep raporu imkânsız. UNIQUE çakışması (~77k kayıtta %50 olasılık, doğum günü paradoksu) retry mantığı olmadığı için 500 döner.
- **Önerilen çözüm:** `resident_units`'ten `unit_id`'yi çöz ve yaz; ticket numarası için DB sequence (`TLP-` + `nextval`) kullan.

#### 🟡 C-5 — Aynı serviste hem gerçek hem mock aynı yolu servis ediyor (ölü route)
- **Kanıt:** community `/api/v1/surveys` (`main.go:58-65`) ve `/api/v1/reservations` (`:76-83`) tanımlıyor. Gateway ise `/api/v1/surveys` → survey-service (`cmd/gateway/main.go:211`) ve `/api/v1/reservations` → reservation-service (`:202`) yönlendiriyor. Community'nin `/api/v1/bulletins` (`:68`) ise gateway'in `/api/v1/bulletin` (tekil, `:166`) rotasıyla hiç eşleşmiyor.
- **Neden sorun:** Bu route'lar gateway üzerinden **asla** erişilemez → ölü kod + hangi servisin sahibi olduğu belirsizliği.
- **Önerilen çözüm:** Community'den bu üç grubu kaldır.

---

### iot-service

#### 🔴 IO-1 — Kimliksiz `POST /api/v1/sensors/:id/data` veri yutma endpoint'i
- **Kanıt:** `services/iot/main.go:36` `sensors.POST("/:id/data", ingestSensorData)` — grup (`:31-37`) auth'suz; handler `:191-204` sadece bind edip `{"status":"ingested"}` döner, "Threshold kontrolü ve alert oluşturma" yorumu var, kod yok.
- **Neden sorun:** Gateway `/api/v1/sensors`'ı proxy'liyor (`cmd/gateway/main.go:154`) → internet'ten kimliksiz veri gönderilebilir; hiçbir cihaz kimlik doğrulaması (device token/mTLS) yok; veri de kaydedilmediği için gönderen sahte "başarılı" cevabı alır.
- **Önerilen çözüm:** Cihaz başına API anahtarı/mTLS + rate limit; gerçek `sensor_data` yazımı; eşik aşımında `alerts` kaydı.

#### 🟠 IO-2 — Sayaç okuma girişinde hiçbir iş kuralı yok
- **Kanıt:** `services/iot/main.go:100-118` — `input.Value` yalnızca `binding:"required"` (0 değeri "eksik" sayılır, negatif kabul edilir); önceki okumadan küçük olamaz kuralı yok; aynı dönem için mükerrer okuma kontrolü yok; `read_at` string olarak alınıp hiç parse edilmiyor (`:103`); `consumption` sabit 12.5 (`:115`).
- **Neden sorun:** Sayaç okuması aidata dönüşen bir finansal girdi; geri sayan/mükerrer okuma faturalandırmayı bozar.
- **Önerilen çözüm:** `meter_readings`'e yaz; `current_value >= previous_value` kontrolü; `UNIQUE(meter_id, period_year, period_month)`; `read_at` RFC3339 parse + gelecek tarih reddi.

#### 🟡 IO-3 — `models/iot.go` ölü kod
- **Kanıt:** `services/iot/models/iot.go` (78 satır, `Meter`, `MeterReading`, `Sensor`, `SensorData`, `Alert`, `ConsumptionSummary`) — `services/iot/main.go` bu paketi import etmiyor; import taramasında da geçmiyor.
- **Önerilen çözüm:** Sayaç modülü DB'ye bağlanırken kullan, aksi halde sil.

---

### notification-service

#### 🔴 N-1 — Kimliksiz bildirim gönderimi + istemciden gelen `user_id`
- **Kanıt:** `services/notification/main.go:44-60` — hiçbir route'ta auth yok. `:214-227` `registerDevice`:
  ```go
  var req struct {
      UserID   string `json:"user_id" binding:"required"`
      Token    string `json:"token" binding:"required"`
      ...
  }
  ```
  `user_id` **istemciden** alınıyor, JWT'den değil.
- **Neden sorun:** Gerçek FCM bağlandığında: (a) herkes tüm sakinlere push/SMS gönderebilir (spam/phishing, SMS maliyeti); (b) saldırgan kendi cihaz token'ını **başka bir kullanıcının** `user_id`'sine kaydedip o kullanıcının bildirimlerini alabilir. `:100-118` `sendBulkNotification` `property_id`'yi de istemciden alıyor → tüm siteye toplu bildirim.
- **Önerilen çözüm:** `AuthMiddleware` + `user_id`'yi yalnızca JWT'den al; gönderim endpoint'lerini `RequireRole(MANAGER)` ile koru + rate limit; iç servis çağrıları için ayrı service-to-service kimlik.

#### 🟠 N-2 — Bildirim tercihleri/sessiz saatler hiçbir yerde uygulanmıyor
- **Kanıt:** `main.go:188-206` `getPreferences` sabit tercihler (`quiet_hours` dahil) döndürüyor; `:208-210` `updatePreferences` sadece mesaj. `sendNotification` (`:73-97`) tercihleri hiç okumuyor.
- **Neden sorun:** KVKK/izin yönetimi açısından "pazarlama mesajı istemiyorum" tercihi teknik olarak uygulanamıyor.
- **Önerilen çözüm:** `notification_preferences` tablosu + gönderim öncesi filtre.

#### 🟡 N-3 — `pkg/notification` bağlansaydı bile kimlik bilgisi yüklenmezdi
- **Kanıt:** `pkg/notification/fcm.go:25` `credPath := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")`; `docker-compose.yml:171-184` bu env'i **set etmiyor** (yalnızca `FIREBASE_PROJECT_ID` ve `/app/firebase-credentials.json` mount'u var). `:28-40` `credPath == ""` → `credentials = nil` ama fonksiyon başarı döner; hata `:106` `google.JWTConfigFromJSON(nil, ...)` ile ilk gönderimde ortaya çıkar.
- **Önerilen çözüm:** `NewFCMClient`'ta `projectID`/`credentials` boşsa hemen hata; compose'a `GOOGLE_APPLICATION_CREDENTIALS: /app/firebase-credentials.json` ekle.

---

### expense-service

#### 🟠 EX-1 — Onay akışı istemci girdisine bakıyor, kalıcı değil
- **Kanıt:** `services/expense/main.go:197-210`
  ```go
  expense.Status = "APPROVED"
  if !expense.IsInvoiced { expense.Status = "PENDING" }
  ```
  `IsInvoiced` istemciden geliyor (`:205`), doğrulanmıyor; `:220-230` `updateExpenseStatus` yeni durumu hiç doğrulamadan geri echo ediyor (`APPROVED`'a geçiş için rol kontrolü yok); hiçbir şey saklanmıyor.
- **Neden sorun:** Faturasız giderin onay gerektirmesi bu servisin tek iş kuralı; istemci `is_invoiced: true` diyerek atlayabilir. Auth olmadığı için "kim onayladı" da kaydedilemez (`migrations/004` `approved_by`, `approved_at` sütunları var, kullanılmıyor).
- **Önerilen çözüm:** DB'ye bağla; `status` geçişlerini durum makinesiyle ve `RequireRole(MANAGER)` ile koru; `approved_by = JWT user_id`.

#### 🟠 EX-2 — `expense_categories` için iki çelişkili sözleşme
- **Kanıt:** `services/expense/main.go:131-144` kategorileri `{id, name, type: FIXED|VARIABLE|UNPLANNED, reflects_to_assessment, display_order}` şeklinde döndürüyor (migration 004 şeması). `services/finance/repository/finance.go:549-555` ise `{id, property_id, name, distribution_type, applies_to_commercial, applies_to_ground_floor, custom_formula, is_active}` okuyor (migration 001 şeması). Gateway `/api/v1/expense-categories` → **expense-service** (`cmd/gateway/main.go:160`), finance'in gerçeği ise `/api/v1/finance/expense-categories`.
- **Neden sorun:** Tahakkuk formu yanlış endpoint'i çağırırsa `category_id` olarak `"1"`..`"9"` gibi UUID olmayan değerler gönderir → `finance/repository/finance.go:441` `WHERE id = $1` UUID cast hatası → `ErrExpenseCategoryNotFound` yerine 400 + ham DB hatası.
- **Önerilen çözüm:** Tek kanonik kategori kaynağı seç (finance/001 şeması), expense servisinin kendi listesini kaldır, gateway rotasını finance'e yönlendir.

---

### settings-service (API credentials)

#### 🔴 S-1 — Sabit (hardcoded) şifreleme anahtarı + KDF'siz anahtar türetme
- **Kanıt:** `services/settings/api_credentials_service.go:138-149`
  ```go
  keyStr := os.Getenv("API_CREDENTIALS_ENCRYPTION_KEY")
  if keyStr == "" {
      keyStr = "sitesen-dev-credentials-key-2026"
  }
  key := make([]byte, 32)
  copy(key, []byte(keyStr))
  ```
- **Neden sorun:** (a) Anahtar kaynak kodda — repoya erişen herkes tüm banka/iyzico/OpenAI/WhatsApp API sırlarını çözebilir. (b) `copy` ile doldurma: `keyStr` 32 byte'tan kısaysa geri kalan **sıfır byte** kalır ("sitesen-dev-credentials-key-2026" 32 karakter ama örn. 16 karakterlik bir env'de anahtarın yarısı 0x00 olur) — entropi çöker. (c) KDF (PBKDF2/scrypt/HKDF) yok, salt yok. (d) Anahtar rotasyonu yok.
- **Önerilen çözüm:** Env'i zorunlu kıl (yoksa `log.Fatal`), base64 32-byte anahtar bekle (`pkg/encryption/aes.go:19-28` bunu doğru yapıyor — o kullanılmalı); KMS/Vault; anahtar sürümü alanı ile rotasyon.

#### 🔴 S-2 — Credentials CRUD kimliksiz; kullanıcı "admin" olarak sabitlenmiş
- **Kanıt:** `api_credentials_service.go:596-655` — `/api/v1/credentials` grubunda auth middleware yok. `:612,625,633,640`:
  ```go
  cred, err := svc.Create(context.Background(), &req, "admin", "admin", c.ClientIP())
  ```
  `userID`/`userName` parametreleri sabit `"admin"`. Gateway bu yolu proxy'liyor (`cmd/gateway/main.go:205`).
- **Neden sorun:** İnternet'ten kimliksiz `POST /api/v1/credentials` ile sahte kimlik bilgisi enjekte edilebilir, `DELETE /api/v1/credentials/:id` ile silinebilir. Audit'te herkes "admin" görünür → inkâr edilemezlik yok.
- **Önerilen çözüm:** `AuthMiddleware` + `RequireRole(MANAGER)` (ya da SUPERADMIN); `userID`/`userName`'i JWT'den al.

#### 🟠 S-3 — Tüm kalıcılık ve audit log TODO; API 2xx dönerek başarı yalanı söylüyor
- **Kanıt:** `:206` `// TODO: Veritabanına kaydet` (Create), `:213` `// TODO: Veritabanından mevcut kaydı al` + `:214` `existing := &APICredential{ID: id} // Placeholder`, `:279` (Update), `:295` (Delete), `:302` (GetAll → demo veri `:305-356`), `:361-362` `GetByID` → `nil, nil`, `:367-368` `GetDecrypted` → `nil, nil`, `:409-434` `GetAuditLog` → sabit demo kayıtlar (uydurma IP `192.168.1.100`), `:437-440` `logAudit` gövdesi tamamen no-op.
- **Neden sorun:** Kullanıcı bir API anahtarı kaydeder, 201 alır, veri yok olur. `ROADMAP.md:86,95` ve `tasks/todo.md:37-40`'daki "API Credentials sayfası backend'e bağlandı / Göster butonuyla çekiliyor + audit log" iddialarının backend karşılığı **hiç yok** — üstelik sırrı gösterecek endpoint (`GetDecrypted`) hiçbir route'a bağlı değil (`:596-659` route listesi).
- **Önerilen çözüm:** DB'ye bağla; `logAudit`'i `pkg/audit.LogAction` üzerinden gerçek INSERT'e çevir; `GetDecrypted`'i ayrı yetkili endpoint olarak açıp her erişimi logla.

#### 🟠 S-4 — Audit kaydına sırrın son 6 karakteri düz metin yazılıyor
- **Kanıt:** `:227-228`
  ```go
  OldValue: s.mask(existing.APIKey),
  NewValue: s.mask(*req.APIKey),
  ```
  `mask` (`:499-504`) `"••••••••" + value[len(value)-6:]` döndürüyor. `*req.APIKey` **düz metin** yeni anahtardır (şifreleme `:219`'da ayrı bir değişkene yapılıyor) → audit kaydına gerçek sırrın son 6 karakteri girer. `OldValue` ise **şifrelenmiş** değerin son 6 karakteri (anlamsız).
- **Neden sorun:** Audit logları genelde daha geniş bir kitleye açıktır; sır parçası sızar. Ayrıca eski/yeni maskeler farklı alan uzaylarından geldiği için karşılaştırma anlamsız.
- **Önerilen çözüm:** Audit'e hiç değer yazma; yalnızca "api_key değişti" + `sha256` özetinin ilk 8 karakteri.

#### 🟡 S-5 — Hata yutma ve doğrulanmayan girdiler
- **Kanıt:** `:510-514` `generateID`: `rand.Read(b)` dönüş değeri **hiç kontrol edilmiyor** → hata durumunda tüm-sıfır ID. `:104-108` `CreateRequest` etiketleri `validate:"required"` — `go-playground/validator` etiketi ama gin `binding:` etiketi bekliyor (`:608` `ShouldBindJSON`) → **hiçbir zorunlu alan doğrulaması çalışmıyor**, boş `service_name`/`api_key` kabul edilir. `:186` `getDisplayName(req.ServiceName)` bilinmeyen servis adını olduğu gibi geri döndürüyor (allowlist yok). `decrypt` (`:468`) tanımlı ama hiç çağrılmıyor.
- **Önerilen çözüm:** `binding:"required"` etiketleri; `ServiceName` allowlist kontrolü; `rand.Read` hatasını yay; `uuid.New()` kullan.

---

### document-service

#### 🔴 D-1 — Gerçek dosya yükleme kodu hiçbir route'a bağlı değil; API sahte 201 döndürüyor
- **Kanıt:** `services/document/document_service.go:135-191` `Upload()` — uzantı allowlist'i (`:143`), UUID'li güvenli dosya adı (`:150`), `io.Copy` ile disk yazımı (`:163`), hata halinde temizlik (`:165`) — hepsi doğru yazılmış. **Ama** `main()` içindeki `POST /api/v1/documents` (`:372-389`) `multipart` hiç okumuyor, sadece JSON bind edip `uuid.New()` ile sahte `Document` döndürüyor. `Upload` çağrısı tüm dosyada geçmiyor.
- **Neden sorun:** Kullanıcı belge yükler, 201 alır, dosya hiçbir yere yazılmaz. `GetByID` (`:194-197`) ve `List` (`:206-209`) `nil, nil` döndürdüğü için `GET /:id` her zaman 404 (`:366-369`), liste her zaman boş (`:355-357`).
- **Önerilen çözüm:** Route'u `c.FormFile` + `svc.Upload(...)`'a bağla; metadatayı DB'ye yaz.

#### 🔴 D-2 — İndirme endpoint'i yok; erişim kontrolü ölü kod
- **Kanıt:** `:216-241` `CanAccess` (genel/sakine özel/sözleşme ayrımı doğru yazılmış) ve `:268-283` `GetFilePath` — **ikisi de hiçbir route'tan çağrılmıyor** (`:341-405` route listesi). `:244-261` `GetForResident` de çağrılmıyor.
- **Neden sorun:** Belge yönetiminin çekirdek özelliği (indirme) yok; yazılmış erişim kontrolü hiç devreye girmiyor. Servis auth'suz olduğu için ileride bağlanırsa `residentID` da yok.
- **Önerilen çözüm:** `GET /api/v1/documents/:id/download` → `AuthMiddleware` → `CanAccess(docID, JWT user_id)` → `c.FileAttachment(path, name)`.

#### 🟠 D-3 — Depolama `/tmp/documents` (kalıcı olmayan) ve boyut sınırı yok
- **Kanıt:** `:325-328` `storagePath = "/tmp/documents"` default. `docker-compose.yml:256-264` document-service için **volume tanımı yok** → konteyner yeniden başlarsa tüm belgeler kaybolur. `Upload`'da `MaxMultipartMemory`/boyut sınırı/MIME sniff kontrolü yok (sadece uzantı `:143`).
- **Neden sorun:** Kalıcı veri kaybı; disk doldurma DoS; `.pdf` uzantılı çalıştırılabilir/zararlı içerik.
- **Önerilen çözüm:** Named volume veya S3/MinIO; `r.MaxMultipartMemory` + boyut sınırı; `mimetype` ile içerik doğrulama.

#### 🟡 D-4 — `ViewCount` bellekte artırılıyor
- **Kanıt:** `:278-280`
  ```go
  doc.ViewCount++
  // TODO: Veritabanına kaydet
  ```
- **Önerilen çözüm:** Atomik `UPDATE documents SET view_count = view_count + 1`.

---

### banking-service

Bkz. yukarıdaki "Banka entegrasyonu" iddia doğrulaması (B-1..B-5 kanıtları orada). Ek maddeler:

#### 🟠 B-6 — İşlem eşleştirme mali bir işlem ama kimliksiz ve kalıcı değil
- **Kanıt:** `services/banking/main.go:444-459` `matchTransaction` — `req.PaymentID`'yi echo ediyor; `:469-476` `autoMatchTransactions` sabit `{"processed":25,"matched":18}`; grup `:138-169` auth'suz.
- **Neden sorun:** Banka hareketi ↔ aidat eşleştirmesi doğrudan sakin bakiyesini etkiler; kimliksiz ve idempotent olmayan bir mutasyon olarak tasarlanmış.
- **Önerilen çözüm:** DB + transaction + `RequireRole(MANAGER)` + `Idempotency-Key` + eşleştirme geri alma (unmatch) için audit.

#### 🟡 B-7 — IBAN doğrulaması yok
- **Kanıt:** `main.go:78` `IBAN string json:"iban" binding:"required"` — sadece varlık kontrolü. `:193` örnek veri boşluklu format (`"TR12 0001 ..."`) — normalize edilmiyor. `migrations/005_new_modules.sql:327` `CREATE UNIQUE INDEX idx_bank_accounts_iban ON bank_accounts(iban) WHERE is_active = true` — normalize edilmemiş IBAN'lar bu kısıtı etkisiz kılar (`TR12 0001` ile `TR120001` farklı satır).
- **Önerilen çözüm:** IBAN mod-97 checksum + boşluk/büyük harf normalizasyonu, DB'ye normalize halde yaz.

---

### parking-service

#### 🟠 PK-1 — Park ücreti sabit; giriş/çıkış eşleştirilmiyor
- **Kanıt:** `services/parking/main.go:442-455` `recordExit` — `"calculated_fee": 50.00` sabit; `req.PaidFee` istemciden alınıp doğrulanmadan geri veriliyor; giriş kaydı bulunmuyor, süre hesaplanmıyor, `ParkingZone.HourlyFee` (`:47`) hiç kullanılmıyor.
- **Neden sorun:** Ücretli otoparkta tahakkuk keyfi; `paid_fee > calculated_fee` veya negatif değer kabul edilir.
- **Önerilen çözüm:** `parking_logs`'tan açık girişi bul, `EXTRACT(EPOCH ...)` ile süre, zone tarifesine göre ücret, `paid_fee <= calculated_fee` kontrolü.

#### 🟠 PK-2 — Plaka tanıma "ALLOW" kararını sabit veriyor (güvenlik kararı)
- **Kanıt:** `main.go:466-478` — `"plate": "34 ABC 123"`, `"confidence": 0.95`, `"action": "ALLOW"` — girdi hiç okunmuyor (görüntü parametresi bile alınmıyor).
- **Neden sorun:** Bariyer/kapı bu endpoint'e bağlanırsa her araca geçiş izni verir. Endpoint auth'suz ve gateway'den açık (`cmd/gateway/main.go:193`).
- **Önerilen çözüm:** Gerçek tanıma + `vehicles` tablosunda plaka sorgusu; karar `DENY` default; endpoint'i cihaz kimliğiyle koru.

#### 🟡 PK-3 — Plaka normalizasyonu yok
- **Kanıt:** `main.go:75` `Plate string binding:"required"`; örnekler boşluklu (`"34 ABC 123"`). `migrations/005_new_modules.sql:102` `CREATE UNIQUE INDEX idx_vehicles_plate_property ON vehicles(property_id, plate) WHERE is_active = true`.
- **Neden sorun:** `"34ABC123"`, `"34 abc 123"`, `"34 ABC 123"` farklı kayıtlar → UNIQUE kısıtı ve plaka aramaları çalışmaz.
- **Önerilen çözüm:** Yazma öncesi `upper + non-alnum strip` normalizasyonu; ayrıca `GET /vehicles/plate/:plate` yolunda plaka path parametresi olduğu için boşluk/URL-encoding sorunları — query param tercih edilmeli.

---

### visitor-service

#### 🔴 V-1 — TCKN dahil ziyaretçi kimlik verisi kimliksiz endpoint'lerden servis ediliyor
- **Kanıt:** `services/visitor/main.go:23` `VisitorIDNumber string json:"visitor_id_number,omitempty"`, `:47` `VisitorRequest.VisitorIDNumber`. Route grubu `:91-120` auth'suz; gateway `/api/v1/visitors`'ı proxy'liyor (`cmd/gateway/main.go:214`). `:232-249` `getVisitor` telefon numarası döndürüyor (`:240`).
- **Neden sorun:** KVKK özel nitelikli veri; kimliksiz okuma/yazma. `pkg/encryption` mevcut ama kullanılmıyor (bkz. iddia "pkg/encryption").
- **Önerilen çözüm:** Auth + `RequireRole(STAFF/MANAGER)`; TCKN'yi `pkg/encryption` ile şifrele, listelerde `MaskTCKN`; erişimleri audit'e yaz.

#### 🟠 V-2 — QR kodu tahmin edilebilir ve süre kontrolü yapılmıyor
- **Kanıt:** `:270` `QRCode: "VIS-" + uuid.New().String()[:8]` (32 bit), `:260,271` `QRExpiresAt: now.Add(24h)`. `:332-348` `getVisitorByQR` — `code`'u sadece yanıta koyuyor, `QRExpiresAt` **hiç kontrol edilmiyor**, status kontrolü yok. `:305-317` `checkInVisitor` de QR/expiry kontrolü yapmıyor.
- **Neden sorun:** Site girişi 8 hex karakterle kaba kuvvet denenebilir; süresi geçmiş/kullanılmış QR ile giriş yapılabilir.
- **Önerilen çözüm:** 128-bit `crypto/rand` token; `expires_at`/`status` kontrolü; tek kullanımlık; rate limit.

#### 🟡 V-3 — `/api/v1/units/:unit_id/visitors` gateway'den erişilemez
- **Kanıt:** `visitor/main.go:118-119` bu yolları kaydediyor. Gateway `:139-145` `/api/v1/units/` isteklerini yol içinde `/packages` varsa package'a, aksi halde **identity**'e yönlendiriyor → visitor'a hiç gelmez, identity'de böyle bir route yok → 404.
- **Aynı sorun:** `reservation/main.go:136-137` (`/units/:unit_id/reservations`, `/residents/:resident_id/reservations`) — `/api/v1/residents` gateway'de identity'ye gidiyor (`cmd/gateway/main.go:133`).
- **Önerilen çözüm:** Kaynak-merkezli yollar kullan (`/api/v1/visitors?unit_id=...`) veya gateway'de daha spesifik yol eşlemesi.

---

### personnel-service

#### 🔴 P-1 — Maaş/bordro/TCKN verisi kimliksiz
- **Kanıt:** `services/personnel/main.go:65-94` — hiçbir grupta auth yok. `:19` `TCNumber`, `:25` `BaseSalary`, `:31-43` `PayrollRecord` (brüt/net maaş). Gateway `/api/v1/employees`, `/api/v1/payroll`, `/api/v1/leaves`'i proxy'liyor (`cmd/gateway/main.go:199`).
- **Önerilen çözüm:** Auth + `RequireRole(MANAGER)`; TCKN şifreleme + maskeleme; bordro erişimlerini audit'e yaz.

#### 🟡 P-2 — İzin onayı iş kuralı içermiyor
- **Kanıt:** `:168-178` `createLeave`/`approveLeave`/`rejectLeave` — çakışan izin, kalan yıllık izin bakiyesi, `start_date <= end_date`, `days` doğrulaması, onaylayan kişi kaydı yok.
- **Önerilen çözüm:** DB + bakiye kontrolü + tarih doğrulaması + `approved_by`.

---

### reservation-service

#### 🟠 R-1 — Rezervasyonda çakışma/kapasite/süre/tarife kontrolü yok
- **Kanıt:** `services/reservation/main.go:408-428` `createReservation` — `StartTime`/`EndTime` string olarak alınıp (`:78-79`) **hiç parse edilmiyor**; çakışma sorgusu yok; `MinDurationMinutes`/`MaxDurationMinutes`/`AdvanceBookingDays`/`Capacity`/`AvailableDays`/`MaintenanceMode` (`:32-39`) alanlarının hiçbiri kontrol edilmiyor; `TotalFee: 100.00` sabit (`:423`), `HourlyFee`/`DailyFee`/`DepositAmount` yok sayılıyor. `:268-284` `getFacilityAvailability` sabit slot listesi. `:435-443` `cancelReservation` sabit `refund_amount: 100.00`, iptal politikası yok.
- **Kanıt (şema hazır):** `migrations/005_new_modules.sql:281-282` `-- Çakışma kontrolü için unique constraint` + `CREATE UNIQUE INDEX idx_reservations_no_overlap ON reservations(facility_id, start_time)` — kısıt var, kod kullanmıyor. (Not: bu index yalnızca **aynı başlangıç saatini** engeller, kısmi çakışmayı engellemez — `tstzrange` + `EXCLUDE USING gist` gerekir.)
- **Önerilen çözüm:** DB'ye bağla; `EXCLUDE USING gist (facility_id WITH =, tstzrange(start_time, end_time) WITH &&)` kısıtı; süre/kapasite/gün/ileri-rezervasyon doğrulaması; ücreti tesis tarifesinden hesapla.

---

### survey-service

#### 🟠 SV-1 — Anonim ankette oy verenlerin kimliği sızdırılıyor; ağırlıklı oy doğrulanmıyor
- **Kanıt:** `services/survey/main.go:290-315` `getSurveyVotes` — `VoterName: "Ali V."`, `UnitNumber: "D.101"`, `Weight: 95.5` döndürüyor; anketin `IsAnonymous` bayrağı (`:23`, `:173,222,258`) **hiç kontrol edilmiyor**. Endpoint auth'suz (`:104-127`).
- **Neden sorun:** Anonimlik sözü teknik olarak ihlal ediliyor (KVKK + kat malikleri oylama gizliliği). Ağırlıklı oyda (`IsWeighted`, `:24`) ağırlık `units.share_ratio`/`gross_area_m2` yerine sabit değerlerden geliyor.
- **Önerilen çözüm:** `is_anonymous` ise kimlik alanlarını hiç döndürme (mümkünse DB'ye de yazma); ağırlığı `units`'ten türet; endpoint'i `RequireRole(MANAGER)` ile koru.

#### 🟠 SV-2 — Oy verme idempotent değil, uygunluk/süre kontrolü yok
- **Kanıt:** `:383-397` `voteSurvey` — `option_ids`'in ankete ait olup olmadığı, kullanıcının oy hakkı, `AllowMultiple` (`:25`), `StartsAt`/`EndsAt` (`:28-29`), `Status == "ACTIVE"` kontrolleri yok; oy veren kimliği hiç alınmıyor (auth yok).
- **Kanıt (şema hazır):** `migrations/005_new_modules.sql:547` `UNIQUE(survey_id, voter_id)` — mükerrer oyu engelleyen kısıt var, kod kullanmıyor.
- **Önerilen çözüm:** DB + `UNIQUE(survey_id, voter_id)` kullanımı (`ON CONFLICT DO NOTHING` + 409); `voter_id` JWT'den; süre/status/option doğrulaması.

---

### nps / esg / energy_analytics / smart_collection / meeting_wizard / inventory / patrol / asset / contract / bulletin / package

Bu 11 servis aynı kalıbı paylaşıyor. Ortak bulgular:

#### 🟠 M-1 — Yazma işlemleri sessizce kayboluyor ama 2xx dönüyor
- **Kanıt:** `nps/nps_service.go:99` `// Save to database` + `return nil` → handler `:279` `c.JSON(http.StatusCreated, resp)`. `esg/esg_service.go:272-273` aynı desen → `:338` 201. `inventory/main.go:139-149` `stockIn`/`stockOut`/`stockAdjust` sadece mesaj — stok seviyesi değişmez. `asset/main.go:395-403,415-422` update/dispose sadece mesaj. `contract/main.go:83-101` create/update/delete/renew/terminate hepsi mesaj. `meeting_wizard/main.go:164-198`. `smart_collection/main.go:211-222`. `package/main.go` (aynı desen). `bulletin/main.go` (aynı desen).
- **Neden sorun:** İstemci "kaydedildi" cevabı alır; bir sonraki listelemede veri yoktur. Bu, mock olduğu bilinmeyen bir ekipte veri kaybı olarak yaşanır ve hata ayıklaması zordur.
- **Önerilen çözüm:** DB'ye bağlanana kadar `501 Not Implemented` + `{"error":"not implemented"}` döndür; asla 200/201 dönme.

#### 🟠 M-2 — Yok sayılan hata dönüşleri
- **Kanıt:** `esg/esg_service.go:337` `svc.RecordMetric(context.Background(), &metric)` — dönüş değeri atanmıyor; `:242-243` `carbon, _ := s.CalculateCarbonFootprint(...)`, `sustainability, _ := ...` sonra `:253-254` `*carbon`, `*sustainability` **nil dereference** riski (şu an fonksiyonlar hep nil-olmayan döndürdüğü için patlamıyor, DB bağlanınca patlar). `nps/nps_service.go:265` `svc.CreateSurvey(...)` dönüşü yok sayılıyor. `banking/main.go:296` `c.ShouldBindJSON(&req)` hata yok sayılıyor (aynısı `parking/main.go:445`, `visitor/main.go:308,368`).
- **Önerilen çözüm:** Hata dönüşlerini işle; `errcheck` linter'ı CI'ya ekle.

#### 🟡 M-3 — "AI" etiketli endpoint'lerde AI yok, ama sağlık kontrolü `ai_enabled: true` diyor
- **Kanıt:** `energy_analytics/main.go:86` `"ai_enabled": true`, `:202-213` `runAIAnalysis` sabit yanıt. `smart_collection/main.go:75` `"ai_enabled": true`, `:167-174` `runRiskAnalysis` sabit. `meeting_wizard/main.go:101` `"ai_enabled": true`, `:200-207` "Transkripsiyon işlemi başlatıldı (AI Whisper)" — Whisper çağrısı yok (gerçek Whisper kodu ölü `pkg/integrations/ai/ai_service.go:371`'de).
- **Neden sorun:** Sağlık kontrolü izleme sistemlerini ve ekibi yanıltıyor.
- **Önerilen çözüm:** `ai_enabled`'ı gerçek yapılandırmadan türet (`OPENAI_API_KEY != ""`).

#### 🟡 M-4 — `esg`/`nps`: `site_id` istemciden, doğrulanmıyor
- **Kanıt:** `esg/esg_service.go:292,304,316` `siteID := c.Query("site_id")`, boşsa `"default"`. `nps/nps_service.go:291` `c.Query("site_id")`, `:274` `resp.SurveyID = c.Param("id")` ama `resp.ResidentID` **istemci gövdesinden** (`:39`).
- **Neden sorun:** Tenant sınırı istemci kontrolünde; NPS'te oy veren kimliği istemci belirliyor → oy şişirme.
- **Önerilen çözüm:** `property_id`/`resident_id`'yi JWT'den al.

#### 🟡 M-5 — `esg`/`nps`: hesaplamalar sabit girdiye dayanıyor
- **Kanıt:** `esg/esg_service.go:143-147` `electricityUsage := 125000.0` vb. demo tüketim; `:158` `residents := 450.0` sabit — `PerCapita` (`:164`) anlamsız. `nps/nps_service.go:106-110` `CalculateNPS` gelen `surveyID`'ye bakmadan sabit 12 yanıtla hesap yapıyor; `:136` `result.PreviousScore = 45.0` sabit → `Trend` her zaman aynı. `energy_analytics/main.go:158-159` ESG'den farklı karbon rakamları (25000 kg vs 84.4 ton) → **iki servis aynı metrik için çelişkili değer üretiyor**.
- **Önerilen çözüm:** Tek kaynak (meters/meter_readings) üzerinden hesapla; iki servisten birini kaldır.

#### 🟡 M-6 — `contract`: sözleşme süresi hesabı sabit ve yanlış
- **Kanıt:** `contract/main.go:64-65` — `EndDate: "2025-12-31"` iken `DaysUntilExpiry: 334` (bugün 2026-09; süresi geçmiş bir sözleşme "334 gün kaldı" gösteriyor). `:74-76` `getExpiringContracts` her zaman boş liste → `:71` `"expiring_in_30_days": 2` ile çelişiyor.
- **Önerilen çözüm:** `DaysUntilExpiry`'yi `end_date - CURRENT_DATE` ile hesapla; sabit istatistikleri kaldır.

#### 🟡 M-7 — `asset`: amortisman raporu tutarsız ve hesaplanmıyor
- **Kanıt:** `asset/main.go:496-507` — `total_book_value: 850000` ve kategori kırılımı `150000+200000+300000 = 650000` (tutmuyor). `:361-393` `createAsset` `CurrentValue = req.PurchasePrice` atıyor, `DepreciationMethod`/`ResidualValue` (`:39,41`) hiç kullanılmıyor. `:287-298` `getAssetStats` sabit 114 varlık (liste `:234-283` 3 varlık döndürüyor).
- **Önerilen çözüm:** Amortismanı `purchase_date`, `depreciation_years`, `residual_value` üzerinden hesapla; istatistikleri gerçek veriden türet.

---

### gateway

#### 🔴 G-1 — Gateway'de hiç kimlik doğrulama yok (X-2 ile birlikte en kritik açık)
- **Kanıt:** `cmd/gateway/main.go:422` `handler := logMiddleware(corsMiddleware(mux))`. `Authorization` başlığı yalnızca aggregator'da alt servise iletiliyor (`:222,280,290,434-436`); proxy yollarında (`:84-91`) hiçbir kontrol yok.
- **Önerilen çözüm:** Zorunlu JWT middleware + allowlist; `X-User-Id`/`X-Property-Id` gibi doğrulanmış başlıkları alt servislere ilet.

#### 🔴 G-2 — Dashboard aggregator hiçbir zaman gerçek veri döndürmüyor (envelope hatası)
Bkz. yukarıdaki "Faz 3 Aggregator" iddia doğrulaması. Kod `:236-271`, hata `:459-463`.
- **Önerilen çözüm:** Tüm servislerde tek bir yanıt zarfı standardı belirle (`{"success":true,"data":...}` veya çıplak dizi) ve `fetchJSON`'u ona göre yaz; ayrıca parse hatalarını **logla** (şu an sessizce mock'a düşüyor).

#### 🔴 G-3 — `/api/v1/assessments` ve `/api/v1/payments` proxy'leri 404 üretiyor
- **Kanıt:** `cmd/gateway/main.go:148`
  ```go
  proxyPaths(mux, newProxy(financeURL), "/api/v1/finance", "/api/v1/assessments", "/api/v1/payments")
  ```
  `httputil.NewSingleHostReverseProxy` yolu **değiştirmez**. Finance ise yalnızca `/api/v1/finance/...` altında route kaydediyor (`services/finance/main.go:37-57`). Dolayısıyla `/api/v1/assessments` → finance'e olduğu gibi gider → gin 404.
- **Neden sorun:** İstemci `/api/v1/assessments` çağırıyorsa (admin panel/mobil) aidat listesi hiç gelmez. Aynı hata `/api/v1/dashboard/recent-payments`'ı da bozuyor (`:282`).
- **Önerilen çözüm:** Ya gateway'de yol yeniden yazımı (`proxy.Director` ile `/api/v1/assessments` → `/api/v1/finance/assessments`), ya finance'te ikinci route grubu.

#### 🟠 G-4 — Rapor üretme/indirme kimliksiz, veri sahte, bellek sızıntısı
- **Kanıt:** `:305-398` `/api/v1/reports/generate` — auth kontrolü yok, veri hardcoded (`:338-354`, `:358-374`), üretilen dosya `generatedReports` map'ine yazılıyor (`:383-389`) ve **hiç temizlenmiyor** (TTL/limit yok, `:26-33`). `:400-420` indirme — `reportID`'nin kime ait olduğu kontrol edilmiyor.
- **Neden sorun:** Kimliksiz istekle sınırsız rapor üretilerek RAM tüketilebilir (DoS); rapor ID'sini ele geçiren üçüncü kişi indirebilir; içerik zaten sahte olduğu için kullanıcı yanlış mali tabloya bakar.
- **Ek:** `:414` `Content-Disposition: attachment; filename=%s` — `filename` sabit olduğu için şu an güvenli, ama kullanıcı girdisiyle beslenirse header injection riski.
- **Önerilen çözüm:** Auth + `RequireRole`; raporu istemci parametrelerine göre finance/identity'den çekilen gerçek veriyle üret; sonuçları TTL'li store'a (Redis/disk) yaz ve sahiplik kontrolü ekle.

#### 🟠 G-5 — CORS `*` + `Authorization` başlığı
- **Kanıt:** `:59-61`
  ```go
  w.Header().Set("Access-Control-Allow-Origin", "*")
  w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Tenant-ID")
  ```
- **Neden sorun:** Herhangi bir web sitesi, ziyaretçinin tarayıcısından bu API'ye istek atabilir. `Allow-Credentials` set edilmediği için cookie tabanlı CSRF sınırlı; ancak auth'suz endpoint'ler (X-2) doğrudan sömürülebilir ve `Authorization` başlığı XSS ile çalınan token'la kullanılabilir.
- **Önerilen çözüm:** Origin allowlist (env'den); `Access-Control-Max-Age`; `X-Tenant-ID`'yi kaldır (ölü).

#### 🟡 G-6 — Aggregator zaman aşımı ve sayfalama farkındalığı yok
- **Kanıt:** `:437` `client := &http.Client{Timeout: 2 * time.Second}` — 5 alt servis **sıralı** çağrılıyor (`:236-271`) → en kötü 10 sn. Sayımlar `len(residents)` ile yapılıyor (`:237`) ama alt servisler sayfalı döndürebilir (finance `LIMIT 50`) → sayım yanlış olur. `logMiddleware` (`:70-75`) yalnızca metot+yol logluyor; status/süre yok.
- **Önerilen çözüm:** Paralel `errgroup` + tek toplam timeout; sayımlar için ayrı `COUNT` endpoint'leri; log'a status/latency/correlation-ID ekle.

---

### backend/api (ölü + güvensiz)

#### 🔴 A-1 — `RequireSuperAdmin` istemci başlığına güveniyor
- **Kanıt:** `backend/api/handlers/api_credentials_handler.go:26-38`
  ```go
  // TODO: JWT veya session'dan kullanıcı rolü al
  userRole := r.Header.Get("X-User-Role")
  if userRole != "super_admin" { ...403... }
  next(w, r)
  ```
- **Neden sorun:** `curl -H "X-User-Role: super_admin"` ile tam yetki. Şu an derlenmediği için sömürülemez ama düzeltilirken bu satır fark edilmezse doğrudan kritik açık olur.
- **Önerilen çözüm:** Dosyayı/dizini sil; ya da JWT'den rol oku.

---

### Migrations & altyapı

#### 🔴 MG-1 — Migration 004, 001 ile çatışıyor; `docker-entrypoint-initdb.d` ilk kurulumda HATA verir
- **Kanıt:**
  - `migrations/001_initial_schema.sql` `expense_categories` tablosunu şu sütunlarla kuruyor: `id, property_id, name, distribution_type (NOT NULL), applies_to_commercial, applies_to_ground_floor, custom_formula, sort_order, is_active, created_at`.
  - `migrations/004_expense_management.sql:5-16` **aynı ada** `CREATE TABLE IF NOT EXISTS expense_categories` yazıyor ama tamamen farklı sütunlarla: `description, type (NOT NULL CHECK), reflects_to_assessment, is_default, display_order, updated_at`. Tablo 001'den zaten var olduğu için bu ifade **no-op**.
  - Hemen ardından `004:19-30`:
    ```sql
    INSERT INTO expense_categories (id, property_id, name, description, type, reflects_to_assessment, is_default, display_order) VALUES ...
    ```
    `description`, `type`, `reflects_to_assessment`, `is_default`, `display_order` sütunları 001'in tablosunda **yok** → PostgreSQL `42703 column "description" of relation "expense_categories" does not exist`. Ayrıca `distribution_type NOT NULL` değeri verilmediği için o da ihlal.
  - `docker-compose.yml:16` `./backend/migrations:/docker-entrypoint-initdb.d` — postgres resmi entrypoint `.sql` dosyalarını **alfabetik** ve `psql -v ON_ERROR_STOP=1` ile çalıştırır → 004'teki hata **tüm başlatmayı durdurur**, 005-010 hiç uygulanmaz.
- **Neden sorun:** Temiz bir volume ile `docker compose up` çalıştırıldığında veritabanı yarım kurulur (`expenses`, `bulletin_posts`, `vehicles`, `visitors`, `deleted` sütunları, KVKK ve request-confirmation migration'ları yok). `ROADMAP.md:56`'daki "006/008/009/010 üç ayrı seferde elle uygulanmak zorunda kaldı" gözlemi büyük olasılıkla **bu hatanın** semptomu — kök neden migration-runner eksikliği değil, çatışan şema.
- **Önerilen çözüm:** 004'ün `expense_categories` bloğunu tamamen kaldır (001 kanonik olsun) ve `expenses.category_id` FK'sını 001'in tablosuna bağla; ya da 004'ün tablosunu `expense_types` gibi ayrı bir adla kur. Ardından `golang-migrate`/`goose` ile sürüm takipli runner ekle (`ROADMAP.md:56`'daki 📋 madde).

#### 🟠 MG-2 — Demo şifre hash'i ve JWT secret kaynak kodda
- **Kanıt:** `migrations/002_seed_data.sql:26` `-- Demo Kullanıcı (Şifre: Demo123!)`, `:29,32` `'$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYV.Uoqy7mPy'`. `docker-compose.yml:82` `JWT_SECRET: ${JWT_SECRET:-your-super-secret-jwt-key-change-in-production}`, `:11` `POSTGRES_PASSWORD: ${DB_PASSWORD:-siteeksen_dev_123}`, `:39` `MONGO_PASSWORD:-siteeksen_dev_123`, `:196` `NEXTAUTH_SECRET:-your-nextauth-secret-...`.
- **Neden sorun:** Seed dosyası production init'te de çalışırsa bilinen şifreli hesap açılır (`+905551234567 / Demo123!`) ve `migrations/008_manager_roles.sql:9` bu hesaba `MANAGER` verir → bilinen kimlik bilgileriyle yönetici erişimi.
- **Önerilen çözüm:** Seed'i ayrı bir `seed/` dizinine taşı (initdb.d dışına); production'da default secret'ları kaldır (env yoksa fail).

#### 🟡 MG-3 — Migration 006 dokümanla uyuşmuyor ve kritik tabloları atlıyor
- **Kanıt:** `006_soft_delete.sql:6-28` → 22 ALTER (doküman "23 tablo" diyor); `:31-38` → 8 index (22 tablo için). Kapsam dışı: `resident_units`, `properties`, `expense_categories`, `assessment_details`, `payment_assessments`, `parking_logs`, `patrol_sessions`, `bank_transactions`.
- **Önerilen çözüm:** Kapsamı tamamla veya soft-delete'i yalnızca gerçekten gereken tablolarla sınırla ve dokümanı düzelt.

---

## Doğrulanamayanlar (dürüstlük notu)

| Konu | Neden doğrulanamadı |
|---|---|
| `go build ./...` / `go test ./...` gerçek çıktısı | Go kurulu değil; **statik** analizle kırık import tespit edildi (`api/handlers/api_credentials_handler.go:8`) ama derleyici çıktısıyla teyit edilmedi |
| `ledger_lines` tablosunun varlığı | `migrations/001_initial_schema.sql` içinde `ledger_entries` görüldü, `ledger_lines` için `CREATE TABLE` grep'te bulunamadı → F-1'deki sorgu tablo yoksa tamamen hata verir; tüm 399 satır okunmadı |
| `.github/workflows/ci-cd.yaml`'ın gerçekten ne derlediği | Dosya bu denetimde okunmadı |
| Servislerin çalışma zamanı davranışı ("Docker'da aktif", "hepsi çalışıyor") | Konteyner çalıştırılmadı |
| Admin panel / Flutter tarafı iddiaları (`ROADMAP.md:64-167`) | Görev kapsamı `backend/` ile sınırlıydı; frontend dosyaları okunmadı |
| `pkg/reports/pdf.go` ve `excel.go` çıktı içeriğinin doğruluğu | Testler yalnızca `len(bytes) > 0` kontrol ediyor; PDF/Excel içeriği incelenmedi |
| `kong/kong.yml`'de route/plugin yapılandırmasının doğruluğu | Yalnızca `url:` satırları sayıldı (24 servis, banking yok); route path'leri ve plugin'ler incelenmedi |
| Kong'da JWT plugin'i olup olmadığı | `kong.yml` plugin bölümü okunmadı — gateway'de auth yok, Kong'da olabilir |
