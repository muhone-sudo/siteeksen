# Veri Katmanı & Altyapı Denetimi — SiteEksen

Denetim tarihi: 2026-09-08
Repo: `C:\Users\md064615\Documents\Projeler\proje99`
Yöntem: statik analiz (Read/Grep/Glob + PowerShell). Docker/psql/Go bu makinede yok — hiçbir migration/servis **çalıştırılarak** doğrulanmadı; tüm bulgular dosya:satır kanıtına dayanıyor. `bash` bozuk (exit 66), tüm komutlar PowerShell ile çalıştırıldı.

**Tek istisna:** demo şifre hash'i, scratchpad'de kurulan `bcryptjs` ile **gerçekten test edildi** (bkz. §3, İddia 6). Repoda hiçbir dosya değiştirilmedi.

---

## 1. Tablo Envanteri (migration bazlı)

### 001_initial_schema.sql — 25 tablo, 2 view (idempotent DEĞİL, `IF NOT EXISTS` yok)

| # | Tablo | satır | Notlar |
|---|-------|-------|--------|
| 1 | `properties` | 12 | `total_share_ratio DECIMAL(12,4)`, `settings JSONB` |
| 2 | `blocks` | 28 | FK→properties CASCADE |
| 3 | `units` | 37 | `UNIQUE(property_id, block, door_number)`, `share_ratio DECIMAL(10,4)` |
| 4 | `users` | 62 | `phone UNIQUE`, `roles TEXT[]`, `tc_encrypted`, `tc_hash` |
| 5 | `resident_units` | 84 | `UNIQUE(resident_id, unit_id, role)` |
| 6 | `management_staff` | 100 | |
| 7 | `chart_of_accounts` | 118 | `UNIQUE(property_id, account_code)`, self-FK |
| 8 | `expense_categories` | 130 | `distribution_type`, `applies_to_*`, `sort_order` — **004'te ÇAKIŞIYOR** |
| 9 | `monthly_assessments` | 144 | **`UNIQUE(unit_id, period_year, period_month)` VAR** (satır 158) |
| 10 | `assessment_details` | 166 | |
| 11 | `ledger_entries` | 176 | |
| 12 | `ledger_lines` | 191 | `CHECK` debit XOR credit (satır 198) |
| 13 | `payments` | 205 | `gateway_response JSONB` |
| 14 | `payment_assessments` | 222 | composite PK |
| 15 | `meters` | 234 | `serial_number UNIQUE` |
| 16 | `meter_readings` | 250 | `consumption` GENERATED ALWAYS STORED (satır 256) |
| 17 | `consumption_tariffs` | 267 | |
| 18 | `consumption_invoices` | 280 | |
| 19 | `vehicles` | 303 | `plate_number`, `unit_id` — **005'te ÇAKIŞIYOR** |
| 20 | `announcements` | 326 | `attachment_urls TEXT[]` |
| 21 | `announcement_reads` | 344 | composite PK |
| 22 | `request_categories` | 352 | |
| 23 | `requests` | 362 | `ticket_number UNIQUE`, `photo_urls TEXT[]` |
| 24 | `request_comments` | 387 | |
| 25 | `audit_logs` | 400 | `user_ip INET`, `resource_type`, `resource_id` — **003'te DROP edilip yeniden yaratılıyor** |
| V1 | `unit_balances` (VIEW) | 422 | kodda hiç kullanılmıyor |
| V2 | `monthly_collection_summary` (VIEW) | 435 | kodda hiç kullanılmıyor |

### 002_seed_data.sql — tablo yok, sadece seed
`properties`(1), `blocks`(2), `units`(6), `users`(2), `resident_units`(2), `expense_categories`(6), `monthly_assessments`(3), `meters`(2), `meter_readings`(6), `consumption_tariffs`(2), `request_categories`(5), `announcements`(1), `management_staff`(1).

### 003_multi_tenant.sql — 3 yeni tablo + 1 tablo yeniden yaratımı + 1 ALTER
| Tablo | satır | Notlar |
|-------|-------|--------|
| `tenants` | 5 | `slug UNIQUE`, `custom_domain UNIQUE`, `features/settings/branding JSONB` |
| `invoices` | 33 | **`amount_total INTEGER` (kuruş)** — tek tamsayı-para kolonu |
| `usage_metrics` | 51 | `UNIQUE(tenant_id, metric_type, recorded_at)` |
| `audit_logs` | 63-64 | **`DROP TABLE IF EXISTS audit_logs;` sonra yeni şema:** `tenant_id NOT NULL`, `entity_type`, `entity_id`, `ip_address` |
| ALTER | 30 | `properties.tenant_id UUID REFERENCES tenants(id)` |

### 004_expense_management.sql — 3 yeni tablo (+1 çakışan), 7 index, 1 trigger, 1 view
| Tablo | satır | Notlar |
|-------|-------|--------|
| `expense_categories` | 5 | **ÇAKIŞMA** — 001'de zaten var, `IF NOT EXISTS` yüzünden sessizce atlanır |
| `expenses` | 33 | `amount DECIMAL(12,2)`, `status CHECK`, `assessment_period VARCHAR(7)` |
| `expense_invoices` | 73 | `ai_extracted_data JSONB`, `ai_confidence_score DECIMAL(3,2)` |
| `expense_distributions` | 109 | |
| VIEW | 142 | `monthly_expense_summary` — kodda kullanılmıyor |

### 005_new_modules.sql — 31 CREATE (30 yeni + 1 çakışan), 45KB
`visitors`(10), **`vehicles`(65 — ÇAKIŞMA)**, `parking_zones`(107), `parking_logs`(132), `facilities`(174), `reservations`(227), `bank_accounts`(289), `bank_transactions`(330), `bulletin_posts`(381), `bulletin_comments`(427), `bulletin_messages`(447), `surveys`(467), `survey_options`(511), `survey_votes`(530), `packages`(557), `asset_categories`(613), `assets`(624), `asset_maintenance`(697), `contracts`(735), `patrol_checkpoints`(809), `patrol_routes`(844), `patrol_logs`(879), `employees`(920), `payroll`(996), `employee_leaves`(1049), `inventory_categories`(1087), `inventory_items`(1097), `inventory_movements`(1140), `energy_analytics`(1178), `meetings`(1221), `payment_risk_scores`(1283).
Sonda (1325-1350) tüm `updated_at` kolonlu tablolara dinamik `DO $$` bloğuyla trigger kurulumu.

### 006-010 — sadece ALTER/UPDATE
| Dosya | İçerik |
|-------|--------|
| `006_soft_delete.sql` | **21 tabloya** `deleted INTEGER NOT NULL DEFAULT 0` (satır 6-13 = 8 core, 16-28 = 13 modül) + **8 index** (31-38) |
| `007_property_type.sql` | `properties.type VARCHAR(20) NOT NULL DEFAULT 'SITE'` (satır 4) |
| `008_manager_roles.sql` | Şema değişikliği yok — `UPDATE users SET roles = array_append(...,'MANAGER') WHERE phone='+905551234567'` (7-10) |
| `009_kvkk_consent.sql` | `users.kvkk_consent_at TIMESTAMP NULL` (satır 5) |
| `010_request_confirmation.sql` | `requests.user_confirmed_at TIMESTAMP NULL` (satır 6) |

### TOPLAM
- **61 distinct tablo**, **3 view**
- Kodda gerçekten SQL ile sorgulanan: **14 tablo** → **47 tablo (%77) ölü şema**
- FK: 134 `REFERENCES`, bunlardan sadece **29'u `ON DELETE CASCADE`**; `ON DELETE SET NULL`/`RESTRICT` hiç yok
- Index: 134 `CREATE INDEX`, **119'u `IF NOT EXISTS`'siz**
- `CREATE TABLE`: 64 ifade, **25'i `IF NOT EXISTS`'siz** (tümü 001'de)
- Rollback/down migration: **HİÇ YOK** (grep: `-- Down`, `DROP COLUMN` → 0 sonuç; tek `DROP TABLE` 003:63 ve o bir yıkım, rollback değil)
- Transaction sarmalama: **HİÇ YOK** (`BEGIN;`/`COMMIT;` → 0 sonuç) → hata halinde yarı-uygulanmış şema

---

## 2. KOD↔ŞEMA UYUŞMAZLIKLARI (EN KRİTİK BÖLÜM)

Kodda SQL kullanan **sadece 4 yer** var: `services/identity`, `services/finance`, `services/community` ve `pkg/audit`. Diğer 22 servis tamamen mock (bkz. §5-B4).

### 2.1 🔴 KRİTİK — `pkg/audit`: audit_logs kolonları ŞEMADA YOK

**Kod:** `backend/pkg/audit/audit.go:28`
```sql
INSERT INTO audit_logs (user_id, user_ip, user_agent, action, resource_type, resource_id, old_values, new_values)
VALUES (NULLIF($1,'')::uuid, NULLIF($2,'')::inet, NULLIF($3,''), $4, $5, NULLIF($6,'')::uuid, $7, $8)
```

**Şema (geçerli olan):** `backend/migrations/003_multi_tenant.sql:63-76`
```sql
DROP TABLE IF EXISTS audit_logs;          -- 001'deki tablo YOK EDİLİYOR
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY ...,
    tenant_id UUID NOT NULL REFERENCES tenants(id),   -- ← NOT NULL, kod hiç vermiyor
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),   -- kod "resource_type" yazıyor
    entity_id UUID,             -- kod "resource_id" yazıyor
    old_values JSONB, new_values JSONB,
    ip_address INET,            -- kod "user_ip" yazıyor
    user_agent TEXT, created_at ...
);
```

**Uyuşmazlık:** 3 kolon adı yanlış (`user_ip`≠`ip_address`, `resource_type`≠`entity_type`, `resource_id`≠`entity_id`) + `tenant_id NOT NULL` hiç doldurulmuyor. INSERT **her seferinde** `42703 undefined_column` ile patlar.

**Neden fark edilmedi:** `backend/pkg/middleware/auth.go:115` hatayı yutuyor:
```go
_ = audit.LogAction(...)   // dönüş değeri atılıyor
```
Middleware `identity`(`main.go:51,62`), `finance`(`main.go:38`), `community`(`main.go:37`) route gruplarına bağlı → **her korumalı istekte sessiz hata**. `audit_logs` tablosu kalıcı olarak BOŞ kalır.

**Etki:** KVKK/5651 denetim izi diye satılan mekanizma hiç çalışmıyor. ROADMAP:54 ve CHANGELOG:19 "gerçek `INSERT INTO audit_logs` ile tamamlandı" diyor → YANLIŞ.

### 2.2 🔴 KRİTİK — Migration 004, `expense_categories` çakışması yüzünden ÇÖKER

`001_initial_schema.sql:130` `expense_categories`'ı yaratır (kolonlar: `distribution_type, applies_to_commercial, applies_to_ground_floor, custom_formula, sort_order, is_active`).
`004_expense_management.sql:5` **aynı tabloyu** `CREATE TABLE IF NOT EXISTS` ile bambaşka kolonlarla (`description, type, reflects_to_assessment, is_default, display_order`) tanımlar → **sessizce atlanır**.
Ardından `004:19-30`:
```sql
INSERT INTO expense_categories (id, property_id, name, description, type, reflects_to_assessment, is_default, display_order) VALUES ...
```
→ `ERROR: column "description" of relation "expense_categories" does not exist`. Ayrıca 001'deki `distribution_type NOT NULL` (default'suz) da doldurulmuyor.

**Sonuç:** Postgres resmi entrypoint `psql -v ON_ERROR_STOP=1` ile çalıştığı için **004 burada durur** → `expenses`, `expense_invoices`, `expense_distributions` (satır 33/73/109) **hiç yaratılmaz** ve init süreci komple başarısız olur.

### 2.3 🔴 KRİTİK — Migration 005, `vehicles` çakışması yüzünden ÇÖKER

`001:303` `vehicles(id, unit_id, resident_id, plate_number, ...)` — **`property_id` ve `plate` kolonu YOK**.
`005:65` aynı tabloyu `IF NOT EXISTS` ile `property_id`, `plate`, `owner_type`, `parking_zone_id`, `rfid_tag`... ile tanımlar → **sessizce atlanır**.
Ardından `005:102`:
```sql
CREATE UNIQUE INDEX idx_vehicles_plate_property ON vehicles(property_id, plate) WHERE is_active = true;
```
→ `ERROR: column "property_id" does not exist`.

**Sonuç:** 005 satır 102'de durur. `visitors` (satır 10) yaratılmış olur, ama **satır 107'den sonraki 29 tablonun hiçbiri yaratılmaz** (`parking_zones`, `facilities`, `reservations`, `bank_accounts`, `bulletin_*`, `surveys`, `packages`, `assets`, `contracts`, `patrol_*`, `employees`, `payroll`, `inventory_*`, `energy_analytics`, `meetings`, `payment_risk_scores`).

Zincir etkisi: `006_soft_delete.sql:18` `ALTER TABLE reservations ...` → tablo yok → 006 da çöker.

**Net sonuç: sıfırdan `docker compose up` ile bu şema KURULAMAZ.** Migration'lar 001→010 sırasıyla temiz bir Postgres'te çalışmaz.

### 2.4 🟠 `requests` — soft-delete filtresi TAMAMEN EKSİK (community)

`006_soft_delete.sql:9` `requests` tablosuna `deleted` ekliyor, `:33` index kuruyor. Ama community repository'sindeki **4 sorgunun hiçbirinde** `deleted = 0` yok:

| Dosya:satır | Sorgu | `deleted = 0`? |
|---|---|---|
| `services/community/repository/request.go:49` | `SELECT ... FROM requests WHERE resident_id = $1` | ❌ |
| `services/community/repository/request.go:61` | `SELECT ... FROM requests WHERE property_id = $1` | ❌ |
| `services/community/repository/request.go:91` | `SELECT ... FROM requests WHERE id = $1` | ❌ |
| `services/community/repository/request.go:122,124,140,146` | `UPDATE requests SET status = ...` | ❌ (silinmiş kaydın durumu değiştirilebilir) |

**Etki:** Admin panel/mobil "sildim" dediği talebi listede görmeye devam eder (ROADMAP:93, CHANGELOG:43 "display `deleted === 0` filtreliyor" iddiası sadece frontend'de geçerli — backend tümünü döndürüyor).

### 2.5 🟠 identity/finance içinde de soft-delete filtresi TUTARSIZ

`deleted` kolonu olan tablolara yapılan sorguların tam dökümü:

| Tablo | Sorgu (dosya:satır) | Filtre |
|---|---|---|
| `users` | `identity/repository/user.go:26` | ✅ `deleted = 0` |
| `users` | `identity/repository/user.go:46` | ✅ |
| `users` | `identity/repository/resident.go:56` | ✅ `u.deleted = 0` |
| `users` | `identity/repository/resident.go:86` | ✅ |
| `users` | `identity/repository/resident.go:116` | ✅ |
| `users` | `finance/repository/finance.go:268` (`JOIN users u`) | ❌ |
| `users` | `finance/repository/finance.go:300` (`JOIN users u`) | ❌ |
| `units` | `finance/repository/finance.go:413` | ✅ |
| `units` | `identity/repository/resident.go:176` (`ListUnits`) | ❌ |
| `units` | `identity/repository/resident.go:108` (`EXISTS`) | ❌ |
| `units` | `identity/repository/user.go:65` (`JOIN units u`) | ❌ |
| `units` | `finance/repository/finance.go:266,301,308` | ❌ |
| `payments` | `finance/repository/finance.go:230` (`GetPaymentHistory`) | ❌ |
| `payments` | `finance/repository/finance.go:306` (`ListPropertyPayments`) | ✅ |
| `monthly_assessments` | `finance.go:59,76,97,123,158,269` | ✅ (6/7) |
| `monthly_assessments` | `finance.go:197` (`CalculateTotalAmount`) | ❌ **silinmiş aidat için ödeme alınabilir** |
| `meters` | `finance.go:346` (`JOIN meters m`) | ❌ |
| `meter_readings` | — | kodda hiç sorgulanmıyor |
| `announcements` | — | kodda hiç sorgulanmıyor (mock) |

**Aynı kullanıcı** `GetByPhone` ile "silinmiş" sayılırken `ListDebtors`/`ListPropertyPayments` sonuçlarında görünmeye devam eder → tutarsız veri.

### 2.6 🟠 Gateway → finance rota uyuşmazlığı (404)

`backend/cmd/gateway/main.go:148`:
```go
proxyPaths(mux, newProxy(financeURL), "/api/v1/finance", "/api/v1/assessments", "/api/v1/payments")
```
`backend/services/finance/main.go:37` ise **sadece** `/api/v1/finance` grubunu tanımlıyor:
```go
api := r.Group("/api/v1/finance")
```
→ `/api/v1/assessments` ve `/api/v1/payments` gateway'den geçer ama finance-service'te **404**.
Aynı hata Kong'da da var: `kong/kong.yml:40-41` `/api/v1/assessments`, `/api/v1/payments`.
Bu yüzden gateway'in kendi dashboard'u da bozuk: `main.go:282` `fetchJSON(financeURL+"/api/v1/payments")` → 404 → sessizce boş dizi döner (`main.go:285`).

### 2.7 🟠 `pkg/tenant` hiçbir servise bağlı DEĞİL → multi-tenant şema tamamen ölü

grep `pkg/tenant` → **hiçbir servis import etmiyor** (yalnızca paketin kendi içindeki referanslar). `pkg/tenant/manager.go:160` verileri `m.tenants[...]` map'inde in-memory tutuyor, `tenants` tablosunu hiç okumuyor.
→ `tenants`, `invoices`, `usage_metrics`, `properties.tenant_id` = ölü şema. Ve `audit_logs.tenant_id NOT NULL`'u dolduracak kaynak yok (§2.1'in ikinci nedeni).
CHANGELOG:27 de bunu itiraf ediyor: *"eklenen `X-Tenant-ID` header yaklaşımı, backend'de o middleware hiç bağlı olmadığı için geri alındı"*.

### 2.8 🟡 Kodda var olmayan tablo referansı YOK — ama ters yön dev
Aksi yönde iyi haber: kodun sorguladığı 14 tablonun **tamamı** şemada tanımlı (kolon adları da 001/006/007/009/010 ile uyumlu; `audit_logs` hariç). Yani "eksik tablo" sorunu yok; sorun **eksik kolon** (§2.1) ve **uygulanamayan migration** (§2.2-2.3).

Kodda kullanılan tablolar: `users`, `units`, `properties`, `resident_units`, `requests`, `monthly_assessments`, `assessment_details`, `expense_categories`, `payments`, `payment_assessments`, `ledger_lines`, `consumption_invoices`, `meters`, `audit_logs`.

### 2.9 🟡 `expense_categories` iki farklı sözleşmeyle okunuyor
`finance/repository/finance.go:439-440` ve `:550-554` **001 şemasını** varsayıyor (`distribution_type`, `applies_to_commercial`, `sort_order`, `custom_formula`).
`004:5-16` ise `type`/`reflects_to_assessment`/`display_order` bekliyor ve seed'i buna göre yazıyor.
Aynı tabloya iki uyumsuz sözleşme → 004'ün seed'i asla yazılamaz, finance ise 001'e bağımlı. Kalıcı belirsizlik.

---

## 3. İddia Doğrulama

### İddia 1 — "PostgreSQL + migrations ✅ 5 migration tamamlandı"
- **Kaynak:** `ROADMAP.md:179`
- **Verdict: YANLIŞ**
- **Kanıt:** `backend/migrations/` içinde **10** dosya var (001..010). ROADMAP'in kendisi 56, 97, 100. satırlarda 006/007/008/009/010'dan bahsediyor → doküman kendi kendisiyle çelişiyor.
- **Gerçek durum:** 10 migration dosyası; ama 004, 005 ve 006 temiz bir DB'de **çalışmıyor** (§2.2-2.3). "Tamamlandı" ibaresi hiçbir sayı için doğru değil.

### İddia 2 — "Migration 006: 23 tabloya `deleted` kolonu + index"
- **Kaynak:** `ROADMAP.md:97`, `CHANGELOG.md:46`
- **Verdict: YANLIŞ (sayı) + KISMEN (kapsam)**
- **Kanıt:** `006_soft_delete.sql` içinde `^ALTER TABLE` sayımı = **21** (satır 6-13: users, units, announcements, requests, payments, meters, meter_readings, monthly_assessments = 8; satır 16-28: visitors, vehicles, reservations, employees, employee_leaves, facilities, bulletin_posts, contracts, packages, assets, surveys, inventory_items, meetings = 13). Index sayısı **8** (satır 31-38), yani 21 tablonun 13'ünde index yok.
- **Gerçek durum:** 23 değil 21 tablo. Ayrıca bu 21 tablonun 13'ü (`reservations`, `facilities`, `employees`, `contracts`, `assets`...) 005 çöktüğü için hiç var olmaz → ALTER'lar da çöker.

### İddia 3 — "identity ve finance repository sorgularına `AND deleted = 0` filtresi eklendi", community eksik mi?
- **Kaynak:** `ROADMAP.md:97`, `CHANGELOG.md:46`
- **Verdict: DOĞRU (iddia doğru şekilde community'yi kapsam dışı bırakıyor) — ama sonuç bir HATA**
- **Kanıt:** community'nin 4 talep sorgusunda filtre yok (`community/repository/request.go:49,61,91,122`). Üstelik identity/finance içinde de 11 sorguda filtre eksik (§2.5 tablosu).
- **Gerçek durum:** Soft-delete backend'de **kısmî ve tutarsız**. `requests` tablosuna `deleted` kolonu eklenmiş ama kimse okumuyor → tamamen işlevsiz.

### İddia 4 — "docker-entrypoint-initdb.d sadece ilk volume oluşumunda çalışıyor, kalıcı çözüm için migration-runner gerekli"
- **Kaynak:** `CHANGELOG.md:29,30`, `ROADMAP.md:56`
- **Verdict: DOĞRU — ve sorun HÂLÂ AÇIK**
- **Kanıt:**
  - `docker-compose.yml:16` → `./backend/migrations:/docker-entrypoint-initdb.d` — tek uygulama mekanizması bu.
  - Repoda migration-runner **yok**: `golang-migrate`/`goose`/`atlas` go.mod'da yok; `backend/cmd/` altında yalnızca `gateway` var; `docker-compose.yml`'de migrate/init job servisi yok (33 servisin tam listesi §4'te); `.github/workflows/ci-cd.yaml`'de `kubectl apply` öncesi migration adımı yok (satır 230-233); `k8s/deployments.yaml`'de Job/initContainer yok.
- **Gerçek durum:** Açık yara. Üstelik CHANGELOG:30 "aynı sorunun üçüncü tekrarı" diyor ve hâlâ çözülmemiş. Migration versiyon tablosu (`schema_migrations` benzeri) da yok → hangi migration'ın uygulandığı **hiçbir yerde kayıtlı değil**.

### İddia 5 — "Migration 006 idempotent (`IF NOT EXISTS`) olduğu için güvenle uygulandı"
- **Kaynak:** `CHANGELOG.md:29`
- **Verdict: KISMEN DOĞRU (006 için doğru, bütün için YANLIŞ)**
- **Kanıt:** 006/007/009/010 gerçekten `ADD COLUMN IF NOT EXISTS` kullanıyor, 008 `WHERE NOT (...ANY(roles))` ile idempotent. AMA: `001`'deki **25 `CREATE TABLE`'ın hiçbirinde** `IF NOT EXISTS` yok; **119 / 134 `CREATE INDEX`** `IF NOT EXISTS`'siz. 002'deki `INSERT`'lerin çoğunda `ON CONFLICT` yok (sadece 003:93 ve 004:30'da var) → 002 iki kez çalışırsa `users.phone UNIQUE` ihlali.
- **Gerçek durum:** Migration seti bir bütün olarak **tekrar çalıştırılabilir DEĞİL**.

### İddia 6 — Demo kullanıcılar `5551234567`/`5559876543`, şifre `demo123`; bcrypt hash gerçekten eşleşiyor mu?
- **Kaynak:** `backend/migrations/002_seed_data.sql:27-33`; `CHANGELOG.md:74`
- **Verdict: YANLIŞ — hash HİÇBİR aday şifreyle eşleşmiyor**
- **Kanıt (fiilen test edildi):** Hash `002_seed_data.sql:29,32`:
  ```
  $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.VTtYV.Uoqy7mPy
  ```
  scratchpad'de `bcryptjs` ile `compareSync` sonuçları — **tümü `false`**:
  `Demo123!` → false, `demo123` → false, `Demo123` → false, `demo1234` → false, `password` → false, `secret` → false, `Test1234!` → false, `123456` → false, `siteeksen` → false, `Demo1234!` → false.
  Ek kanıt: **iki kullanıcı için aynı hash** (satır 29 ve 32) — gerçek bcrypt her çağrıda farklı salt üretir; bu, kopyala-yapıştır placeholder olduğunun işareti.
  Ek kanıt: `CHANGELOG.md:74` — *"Seed data'daki bcrypt hash `Demo123!` şifresiyle eşleşecek şekilde **DB'de güncellendi**"* → düzeltme **çalışan container'a** uygulandı, **dosyaya değil**. Dosya bozuk kaldı.
- **Telefon formatı:** Seed `+905551234567` yazıyor; `identity/handlers/auth.go:12-24` `normalizePhone()` 10 haneli girdiyi `+90`'la öne ekliyor → `5551234567` ile giriş **format olarak** çalışır. Sorun sadece şifre hash'i.
- **Gerçek durum:** Sıfırdan kurulan bir ortamda **demo kullanıcıların hiçbiriyle giriş yapılamaz**. Şifre bilinmiyor (kurtarılamaz). Ayrıca dokümanlardaki şifre bile tutarsız: 002:26 yorumu `Demo123!`, görev tanımı/başka dokümanlar `demo123`.

### İddia 7 — "Tüm 19 yeni servis docker-compose.yml'e eklendi — port atandı, Dockerfile yazıldı, hepsi çalışıyor"
- **Kaynak:** `ROADMAP.md:51`
- **Verdict: KISMEN DOĞRU (compose+Dockerfile evet, "hepsi çalışıyor" doğrulanamadı, ROADMAP kendisiyle çelişiyor)**
- **Kanıt:**
  - compose'da 33 servis var, 19 yeni servis gerçekten tanımlı (satır 202-429).
  - Referans edilen **27 Dockerfile'ın tamamı diskte var** (glob doğrulaması yapıldı; eksik yok).
  - AMA `ROADMAP.md:24-43` aynı dosyada 20 servis için **"docker-compose'a eklenmedi"** ve Port sütunu **"—"** diyor → doküman kendisiyle çelişiyor, tablo güncellenmemiş.
  - "hepsi çalışıyor": doğrulanamadı (Docker yok). Statik olarak 13 serviste PORT default uyuşmazlığı var (§4).
- **Gerçek durum:** Dosyalar var; ROADMAP tablosu bayat. Servislerin 22'si mock (§5-B4).

### İddia 8 — "Kong `kong.yml` güncellendi — 24 servis Kong üzerinden yönlendiriliyor, tüm servisler için CORS ve rate-limiting"
- **Kaynak:** `ROADMAP.md:52`, `CHANGELOG.md:61`
- **Verdict: KISMEN (servis sayısı) + YANLIŞ (rate-limiting) + YANLIŞ (kapsam)**
- **Kanıt:**
  - `kong/kong.yml`'de **24 servis**, **25 route**, **30 plugin** (`- name:` sayımı).
  - `cors` plugin: **24/24 servis** ✅
  - `rate-limiting` plugin: **6/24 servis** (identity 16, finance 45, community 73, iot 102, notification 129, expense 157) → **18 servis rate-limit'siz** ❌
  - `jwt` plugin: **0** — Kong'da JWT doğrulama YOK ❌
  - `banking-service` Kong'da **hiç yok** (compose:289'da var, gateway:118'de var) → 25 uygulama servisinden 24'ü
  - `gateway` servisi Kong'da yok → `/api/v1/dashboard/*`, `/api/v1/reports/*` (gateway'e özel, main.go:221-420) Kong (8000) üzerinden **erişilemez**
  - ROADMAP:176 "Kong API Gateway ✅ **Temel 5 servis** yönlendirmesi var" + ROADMAP:183 "Kong güncelleme (yeni servisler) 📋 **20+ servis kong.yml'e eklenmeli**" → aynı dosyada 52. satırla **doğrudan çelişki**
- **Gerçek durum:** 24 servis/25 route var; CORS her yerde; rate-limiting %25'inde; JWT hiç yok. Route kapsamı gateway'in çok gerisinde (aşağıya bakın).

**Kong'da OLMAYAN, gateway'de olan rotalar** (gateway `main.go` vs `kong.yml`):
`/api/v1/residents`(133), `/api/v1/units`(138), `/api/v1/assessments`+`/payments`(148 — Kong'da var ama servis 404, §2.6), `/api/v1/asset-categories`(163), `/api/v1/stock-movements`(181), `/api/v1/carriers`(190), `/api/v1/vehicles`+`/parking-zones`+`/parking-logs`+`/plate-recognition`(193), `/api/v1/patrol-routes`+`/patrol-sessions`(196), `/api/v1/employees`+`/payroll`+`/leaves`(199), `/api/v1/facilities`(202), `/api/v1/collection`(208), `/api/v1/my-surveys`(211), `/api/v1/bank-accounts`+`/bank-transactions`+`/banking`(217), `/api/v1/dashboard/*`(221-301), `/api/v1/reports/*`(305-420).

### İddia 9 — "Kubernetes manifests ✅"
- **Kaynak:** `ROADMAP.md:177`
- **Verdict: KISMEN — 25 servisin 2'si + admin panel**
- **Kanıt:** `k8s/deployments.yaml` (5493 B) yalnızca **3 Deployment + 3 Service** içeriyor: `identity-service`(satır 4), `finance-service`(88), `admin-panel`(173). `k8s/ingress.yaml` 1 Ingress + 1 ClusterIssuer.
  - Eksik: community, iot, notification ve diğer 19 servis, **gateway**, kong, postgres, redis, mongo, kafka.
  - Image referansları: `ghcr.io/siteeksen/identity-service:latest` (satır 19) vs CI'nin push ettiği `ghcr.io/${{ github.repository_owner }}/identity-service` (`ci-cd.yaml:11,93`) → owner "siteeksen" değilse **image bulunamaz**.
  - Secret'lar: `db-credentials`, `app-secrets`, `iyzico-credentials`, **`redis-credentials`**(satır 50). `.env.example:65-76` yalnızca ilk üçünün oluşturulmasını dokümante ediyor → `redis-credentials` **belgelenmemiş**, identity pod'u `CreateContainerConfigError` alır.
  - ConfigMap: **hiç yok**. Namespace/HPA/PDB/NetworkPolicy: **hiç yok**.
  - Resource limit: 3/3 ✅. Probe: identity liveness+readiness ✅; finance yalnızca **liveness** (readiness yok, satır 150); **admin-panel'de hiç probe yok**.
  - **PORT env verilmiyor** → servisler `main.go` default'unu kullanır; identity 8081 ✅, finance 8082 ✅ (bu iki servis için şans eseri doğru).
- **🔴 Ingress path uyuşmazlığı:** `ingress.yaml:23,30,37,44` `/v1/auth`, `/v1/users`, `/v1/finance`, `/v1/payments` yolunu backend'e **rewrite olmadan** iletiyor; servisler ise `/api/v1/...` sunuyor (`identity/main.go:39`, `finance/main.go:37`) → **prod'da tüm istekler 404**. `nginx.ingress.kubernetes.io/rewrite-target` annotation'ı yok.
- **🟡** `ingress.yaml:6` `kubernetes.io/ingress.class` deprecated (`spec.ingressClassName` kullanılmalı); `:10-11` `nginx.ingress.kubernetes.io/rate-limit` **geçerli bir annotation değil** (doğrusu `limit-rps`/`limit-rpm`) → rate limit sessizce uygulanmaz.

### İddia 10 — "CI/CD (GitHub Actions) ✅"
- **Kaynak:** `ROADMAP.md:178`
- **Verdict: YANLIŞ — pipeline ilk adımda çöker**
- **Kanıt:**
  - 🔴 `ci-cd.yaml:38` `go-version: '1.21'` ⟷ `backend/go.mod:3` `go 1.24.0`. Go 1.21 toolchain `go.mod requires go >= 1.24.0` hatası verir → `go mod download`(48) ve sonrasındaki her adım başarısız. CHANGELOG:87 "Tüm backend servisleri Go 1.24'e güncellendi" derken CI güncellenmemiş.
  - 🔴 `ci-cd.yaml:237-241` `kubectl rollout restart deployment/community-service`, `iot-service`, `notification-service` → bu Deployment'lar `k8s/deployments.yaml`'de **YOK** → deploy job'u hata verir.
  - 🟠 `ci-cd.yaml:69-76` "Build all services" yalnızca **5** servisi derliyor (25'ten); image push de yalnızca aynı 5 servis (86-129). 20 servis CI'da hiç derlenmiyor/yayınlanmıyor.
  - 🟠 `ci-cd.yaml:59-67` "Run integration tests" için postgres service container ayağa kalkıyor ama **migration uygulanmıyor** → boş DB. (`tests/integration_test.go` gerçekte DB kullanmayan, `httptest` + mock router tabanlı bir suite olduğu için hata vermez ama DB env'i de tamamen dekoratif.)
  - 🟠 `ci-cd.yaml:206-211` Trivy'de `exit-code` verilmemiş → varsayılan `0`, bulgu ne olursa olsun **job asla başarısız olmaz**. `deploy` bu job'a `needs` ile bağlı (215) ama kapı işlevi görmüyor.
  - 🟠 `ci-cd.yaml:150,154,194,198` `|| true` → lint / type-check / flutter analyze / flutter test **hata yutuyor**.
  - 🟠 `ci-cd.yaml:250-254` smoke test'ler **yorum satırı**, sadece `echo`.
  - 🔴 **Testler kendi kopyalarını test ediyor:** `services/identity/handlers/auth_test.go:247` `func validatePassword(...)` ve `:271` `func validatePhone(...)` **test dosyasının içinde tanımlı** — üretim kodunda böyle fonksiyon yok (grep doğrulaması: yalnızca `_test.go` dosyalarında). Aynısı `services/finance/handlers/finance_test.go:281` `calculateLateFee` için geçerli; ayrıca `finance_test.go:256-278` gerçek handler'lar yerine kendi mock gin route'larını kuruyor. Yani birim testler üretim davranışını **hiç** doğrulamıyor.
  - Tetikleyici: `push` → `main`, `develop`; `pull_request` → `main` (satır 3-7). Deploy yalnızca `main`'e push'ta (217).
- **Gerçek durum:** Workflow dosyası var, adımların çoğu ya hata yutuyor ya hiç çalışmıyor. Fiilen çalışan tek şey `admin` job'undaki `npm run build` (satır 158, `|| true` yok).

### İddia 11 — "Gateway v1.2.0 — 24 servise proxy routing"
- **Kaynak:** `ROADMAP.md:53`
- **Verdict: DOĞRU (25 servis, sayı bile mütevazı)**
- **Kanıt:** `cmd/gateway/main.go:94-118` **25** servis URL'i okuyor; `:133-217` hepsine route bağlıyor. `docker-compose.yml:438-462` 25 `*_SERVICE_URL` env'inin hepsini veriyor. Portlar birebir uyumlu.
- **Uyarı:** Gateway'de **auth yok** — `corsMiddleware`+`logMiddleware` var (satır 422), JWT doğrulaması yok. Kong'da da JWT yok (İddia 8) → tek doğrulama noktası servislerin kendi `AuthMiddleware()`'i; ama 22 mock servisin hiçbirinde auth middleware yok.

### İddia 12 — `api/openapi.yaml` güncel mi?
- **Verdict: YANLIŞ — ciddi şekilde bayat/eksik**
- **Kanıt:** 14 path / 16 operasyon (`^  /` ve `^    (get|post|...)` sayımı):
  `/auth/login`(38), `/auth/refresh`(69), `/auth/logout`(94), `/users/me`(114), `/users/me/properties`(131), `/users/me/active-property`(148), `/finance/debt-status`(178), `/finance/assessments`(194), `/finance/assessments/{id}`(217), `/finance/payments`(241 get+258 post), `/finance/consumption/summary`(281), `/requests`(304 get+327 post), `/requests/{id}`(347), `/requests/{id}/comments`(369).
- **Dokümante ama KODDA YOK:**
  - `GET /requests/{id}` (openapi:348) — `community/main.go:39-42`'de böyle bir route yok
  - `POST /requests/{id}/comments` (openapi:370) — hiçbir serviste yok (`request_comments` tablosu var ama kod yok)
- **KODDA VAR ama dokümante DEĞİL:** `POST /users/me/properties`(identity:55), `POST /users/me/kvkk-consent`(identity:57), `GET/POST /residents`+`GET/PATCH /residents/:id`(identity:64-67), `GET /units`(identity:73), `GET /finance/debtors`(finance:42), `GET /finance/assessments/overview`(finance:46), `POST /finance/assessments`(finance:47), `GET /finance/expense-categories`(finance:49), `PATCH /requests/:id/status`(community:41), `POST /requests/:id/confirm-resolution`(community:42), gateway'in `/dashboard/*`+`/reports/*`, ve 22 mock servisin **tüm** endpoint'leri.
- **Versiyon tutarsızlığı:** openapi `version: 1.0.0` (satır 13) ⟷ gateway `"version": "1.2.0"` (`main.go:128`).
- **Server URL:** `http://localhost:8000/api/v1` (Kong) — ama compose admin paneli gateway'e (8888) yönlendiriyor.
- **Gerçek durum:** İlk commit'ten kalma; 006-010 migration'larından sonra eklenen hiçbir endpoint yansıtılmamış.

### İddia 13 — "Backend soft-delete altyapısı ✅ ... Soft-delete pattern (deleted=1)"
- **Kaynak:** `ROADMAP.md:93,97`, `CHANGELOG.md:42,43`
- **Verdict: YANLIŞ (backend tarafı işlevsiz)**
- **Kanıt:** Repoda **hiçbir yerde `SET deleted = 1` yazan bir SQL yok** (grep: `deleted` sadece `SELECT ... WHERE deleted = 0` filtrelerinde ve migration 006'da). Yani backend'de bir kaydı soft-delete edecek **UPDATE kodu yok**; `DELETE /residents/:id` endpoint'i de yok (CHANGELOG:15 bunu itiraf ediyor). Frontend'in "sildim" dediği şey ya `is_active=false` (CHANGELOG:15) ya da sadece kendi in-memory state'i.
- **Gerçek durum:** `deleted` kolonu 21 tabloya eklendi, 20 sorguda okundu, **hiçbir yerde yazılmıyor**. Yarım kalmış özellik.

---

## 4. Port & Env Tutarsızlıkları

### 4.1 Servis portları

| Servis | main.go default | docker-compose PORT | gateway bekliyor | kong bekliyor | k8s | SONUÇ |
|---|---|---|---|---|---|---|
| identity | 8081 (`identity/main.go:79`) | 8081 (84) | 8081 (94) | 8081 (5) | 8081 ✅ | ✅ |
| finance | 8082 (`finance/main.go:62`) | 8082 (107) | 8082 (95) | 8082 (36) | 8082 ✅ | ✅ (ama rota 404, §2.6) |
| community | 8083 (`community/main.go:87`) | 8083 (127) | 8083 (96) | 8083 (65) | — | ✅ |
| iot | 8084 (`iot/main.go:52`) | 8084 (148) | 8084 (97) | 8084 (93) | — | ✅ |
| notification | 8085 (`notification/main.go:64`) | 8085 (173) | 8085 (98) | 8085 (122) | — | ✅ |
| expense | 8086 (`expense/main.go:121`) | 8086 (215) | 8086 (99) | 8086 (149) | — | ✅ |
| asset | **8097** (`asset/main.go:185`) | 8087 (229) | 8087 (100) | 8087 (177) | — | ⚠️ default≠8087 |
| — | — | *(8088 hiç kullanılmıyor)* | — | — | — | boşluk |
| bulletin | **8094** (`bulletin/main.go:158`) | 8089 (240) | 8089 (101) | 8089 (200) | — | ⚠️ |
| contract | **8098** (`contract/main.go:56`) | 8090 (251) | 8090 (102) | 8090 (223) | — | ⚠️ |
| document | 8091 (`document_service.go:409`) | 8091 (262) | 8091 (103) | 8091 (246) | — | ✅ |
| energy_analytics | **8102** (`energy_analytics/main.go:115`) | 8092 (273) | 8092 (104) | 8092 (269) | — | ⚠️ |
| esg | 8093 (`esg_service.go:344`) | 8093 (284) | 8093 (105) | 8093 (292) | — | ✅ |
| inventory | **8101** (`inventory/main.go:80`) | 8094 (306) | 8094 (106) | 8094 (315) | — | ⚠️ |
| meeting_wizard | **8103** (`meeting_wizard/main.go:139`) | 8095 (317) | 8095 (107) | 8095 (338) | — | ⚠️ |
| nps | 8096 (`nps_service.go:302`) | 8096 (328) | 8096 (108) | 8096 (361) | — | ✅ |
| package | **8096** (`package/main.go:125`) | 8097 (339) | 8097 (109) | 8097 (384) | — | ⚠️ |
| parking | **8091** (`parking/main.go:164`) | 8098 (350) | 8098 (110) | 8098 (407) | — | ⚠️ |
| patrol | 8099 (`patrol/main.go:95`) | 8099 (361) | 8099 (111) | 8099 (430) | — | ✅ |
| personnel | 8100 (`personnel/main.go:98`) | 8100 (372) | 8100 (112) | 8100 (453) | — | ✅ |
| reservation | **8092** (`reservation/main.go:142`) | 8101 (383) | 8101 (113) | 8101 (476) | — | ⚠️ |
| settings | 8102 (`api_credentials_service.go:663`) | 8102 (394) | 8102 (114) | 8102 (499) | — | ✅ |
| smart_collection | **8104** (`smart_collection/main.go:102`) | 8103 (405) | 8103 (115) | 8103 (522) | — | ⚠️ |
| survey | **8095** (`survey/main.go:131`) | 8104 (416) | 8104 (117) | 8104 (545) | — | ⚠️ |
| visitor | **8090** (`visitor/main.go:124`) | 8105 (427) | 8105 (117) | 8105 (568) | — | ⚠️ |
| banking | **8093** (`banking/main.go:173`) | 8106 (295) | 8106 (118) | **YOK** | — | ⚠️ + Kong eksik |
| gateway | 8888 (`gateway/main.go:119`) | 8888 (463) | — | **YOK** | — | ⚠️ Kong eksik |

**Sonuç:** 25 servisin **13'ünde** `main.go` default'u compose/gateway/Kong'un beklediğinden farklı. compose PORT env'i verdiği için compose içinde çalışır — ama:
- **k8s'te PORT env verilmiyor** → o servisler k8s'e eklenirse default'la ayağa kalkar ve Service targetPort'la uyuşmaz.
- **Lokal `go run` ile PORT'suz çalıştırıldığında** default'lar birbirine çakışıyor:
  - **8091 ÇAKIŞMA:** parking (164) ↔ document (409)
  - **8093 ÇAKIŞMA:** esg (344) ↔ banking (173)
  - **8096 ÇAKIŞMA:** nps (302) ↔ package (125)
  - **8102 ÇAKIŞMA:** energy_analytics (115) ↔ settings (663)
  → İkinci process `bind: address already in use` ile ölür.
- Gateway ise PORT'suz lokal çalıştırmada **doğru** default'lara (8087/8089/8090...) gider → hiçbirini bulamaz.

### 4.2 Env değişkenleri

| Değişken | Kodda okunuyor | docker-compose | .env.example | k8s | Sonuç |
|---|---|---|---|---|---|
| `DB_HOST/PORT/USER/PASSWORD/NAME` | `pkg/database/postgres.go:27-31` | 6 serviste (identity, finance, community, iot, notification, expense) | ✅ | identity+finance | ⚠️ diğer 19 serviste yok (ama onlar DB kullanmıyor) |
| `DB_SSLMODE` | `postgres.go:32` | **YOK** | **YOK** | **YOK** | ⚠️ prod'da sessizce `disable` → şifresiz DB bağlantısı |
| `JWT_SECRET` | `pkg/middleware/auth.go:55`, `identity/main.go:26` | 6 serviste | ✅ | identity+finance | ⚠️ compose default `your-super-secret-jwt-key-change-in-production` (satır 82) |
| `PORT` | tüm servisler | 25 serviste ✅ | **YOK** | **YOK** | ⚠️ k8s'te eksik |
| `IYZICO_API_KEY/SECRET_KEY/BASE_URL` | `pkg/payment/iyzico.go:24,30,31` | finance (104-106) | ✅ | finance | ✅ |
| `FIREBASE_PROJECT_ID` | `pkg/notification/fcm.go:24` | notification (171) | ✅ | **YOK** | ⚠️ |
| `GOOGLE_APPLICATION_CREDENTIALS` | `pkg/notification/fcm.go:25` | **YOK** (sadece dosya mount, satır 184) | ✅ | **YOK** | 🔴 fcm.go path'i asla bulamaz |
| `OPENAI_API_KEY` | `pkg/ai/invoice_parser.go:60` | **YOK** | **YOK** | **YOK** | 🔴 hiçbir yerde tanımlı değil |
| `GOOGLE_AI_KEY` | `pkg/ai/invoice_parser.go:61` | **YOK** | **YOK** | **YOK** | 🔴 tanımsız |
| `PREFERRED_AI` | `pkg/ai/invoice_parser.go:62` | **YOK** | **YOK** | **YOK** | 🔴 tanımsız |
| `REDIS_URL` | kodda **okunmuyor** (grep: 0 sonuç) | identity(83), notification(169) | ✅ | identity (secret `redis-credentials`) | ⚠️ ölü env; k8s secret'ı belgelenmemiş |
| `KAFKA_BROKERS` | kodda **okunmuyor** | notification(170) | ✅ | **YOK** | ⚠️ ölü env |
| `MONGO_URL` | kodda **okunmuyor** | iot(146) | **YOK** | **YOK** | ⚠️ ölü env; `.env.example`'da hiç yok |
| `NEXT_PUBLIC_API_URL` | `admin/src/.../api-client.ts:3`, `route.ts:5` | 8888 (193) | **8000** (satır 40) | `https://api.siteeksen.com/v1` | 🔴 3 farklı değer |
| `SENTRY_DSN`, `LOG_LEVEL`, `SSL_*`, `JWT_EXPIRY`, `JWT_REFRESH_EXPIRY`, `API_BASE_URL` | kodda **okunmuyor** | — | ✅ | — | ⚠️ `.env.example`'da 6 ölü değişken |

### 4.3 Hardcoded secret / default'lar (docker-compose.yml)
Hepsi `${VAR:-default}` formunda, yani **`.env` yoksa bu değerlerle çalışır**:
- `DB_PASSWORD:-siteeksen_dev_123` — satır 11, 80, 101, 124, 144, 167, 212 (7 kez tekrar)
- `MONGO_PASSWORD:-siteeksen_dev_123` — satır 39, 146
- `JWT_SECRET:-your-super-secret-jwt-key-change-in-production` — satır 82, 103, 126, 147, 172, 214 (6 kez)
- `NEXTAUTH_SECRET:-your-nextauth-secret-change-in-production` — satır 196
- `IYZICO_API_KEY:-sandbox-key` / `IYZICO_SECRET_KEY:-sandbox-secret` — satır 104-105
→ Prod'da `.env` unutulursa **bilinen zayıf JWT secret'ıyla** ayağa kalkar; hiçbir "boşsa hata ver" kontrolü yok (`identity/main.go:26` `os.Getenv("JWT_SECRET")` boş string kabul ediyor → boş anahtarla imzalanan token).

### 4.4 docker-compose yapılandırma eksikleri
| Konu | Durum | Kanıt |
|---|---|---|
| `restart:` policy | **0 servis** | grep `restart:` → 0 |
| `networks:` | **hiç tanımlı değil** | grep `networks:` → 0 (default bridge'e güveniliyor) |
| `healthcheck:` | **1/33** (yalnızca postgres) | `docker-compose.yml:17-21` |
| `depends_on:` | 10 servis | 19 yeni servisin **hiçbirinde** yok (satır 222-429) |
| Named volume | 5 (postgres, redis, mongodb, zookeeper, kafka) | 495-500 |
| 🔴 Eksik dosya mount | `./firebase-credentials.json:/app/firebase-credentials.json:ro` (satır 184) — **dosya diskte YOK** (`Test-Path` → `False`, ayrıca `.gitignore:57` ile ignore edilmiş) → Docker bunu **dizin** olarak yaratır, `notification-service` başlangıçta patlar |
| 🟠 `version: '3.8'` | Compose v2'de obsolete uyarısı | satır 1 |
| 🟠 kong `depends_on` | 5 servisi bekliyor (488-493) ama 24'ünü proxy'liyor | — |
| 🟠 gateway `depends_on` | 3 servisi bekliyor (466-469) ama 25'ini proxy'liyor | — |
| 🟠 Migration/init job | **YOK** — tek mekanizma initdb.d mount'u (satır 16) | §3 İddia 4 |

---

## 5. Mantık Hataları ve Eksiklikler

### A. Veri katmanı

**A1 🔴 `GetUnitBalance` kartezyen çarpım — bakiye kullanıcı sayısıyla çarpılıyor**
- **Kanıt:** `backend/services/finance/repository/finance.go:35-43`
  ```sql
  SELECT COALESCE(SUM(ll.debit_amount) - SUM(ll.credit_amount), 0) as balance
  FROM ledger_lines ll
  JOIN users u ON ll.unit_id = (
      SELECT ru.unit_id FROM resident_units ru WHERE ru.resident_id = $1 AND ru.is_active = true LIMIT 1
  )
  ```
- **Neden sorun:** `JOIN users u` koşulu `u`'ya hiç referans vermiyor. Bu bir CROSS JOIN'dir: eşleşen her `ledger_lines` satırı **tablodaki kullanıcı sayısı kadar** tekrarlanır. `SUM` sonucu = gerçek bakiye × `COUNT(*) FROM users`. 156 sakinli bir sitede 1.200 TL borç **187.200 TL** görünür.
- **Öneri:** `users` join'ini tamamen kaldır: `FROM ledger_lines ll WHERE ll.unit_id = (SELECT ...)`. Ayrıca `unit_balances` view'ı (`001:422`) bu işi doğru yapıyor — onu kullan.

**A2 🔴 Para birimi: DB `DECIMAL` ✅ / Go `float64` ❌**
- **Kanıt:** Şema tarafı temiz — migration'larda `FLOAT`/`DOUBLE`/`REAL`/`MONEY` **hiç yok** (grep → 0); 101 `DECIMAL` kolonu var (001:25, 004:3, 005:73). Tek istisna `003:37` `invoices.amount_total INTEGER` (kuruş — aslında doğru yaklaşım).
- Go tarafı ise tamamen `float64`: `finance/repository/finance.go:34,44,194,200,206` (`amount float64`), `:264` `SUM(...)` → `d.Amount float64`, `finance/service/finance.go:40-44`, `pkg/payment/service.go:28`, `pkg/payment/iyzico.go:96-97,219`, `pkg/reports/pdf.go:235-275`, `banking/main.go:35,45,68-70`.
- **Neden sorun:** `pgx` `NUMERIC`'i `float64`'e dönüştürürken IEEE-754 yuvarlaması yapıyor. Tahakkuk dağıtımı bunu **çoğaltıyor**: `finance.go:465` `share := item.Amount / float64(len(eligible))`, `:481,495` `share := item.Amount * ratio` — 24 daireye bölünen 10.000 TL'nin parçaları toplamı 10.000 TL etmez (kuruş kaçağı). Ardından `:507-509` her parça `DECIMAL(12,2)`'ye yuvarlanarak yazılır → **site toplamı ile daire toplamları tutmaz**, muhasebe denkleşmez. `finance.go:140` `p.Rate = int(p.CollectedAmount / p.TotalAmount * 100)` de kesme yapıyor (%99.9 → %99).
- **Öneri:** `shopspring/decimal` veya `pgtype.Numeric` kullan; ya da tüm tutarları kuruş (`int64`) olarak taşı. Dağıtımda kalanı (remainder) son birime ekleyen bir algoritma uygula.

**A3 🟠 Migration versiyon takibi yok**
- **Kanıt:** `schema_migrations`/`goose_db_version` benzeri tablo hiçbir migration'da yok; `backend/cmd/` altında yalnızca `gateway`.
- **Neden sorun:** "Hangi migration uygulandı?" sorusunun cevabı hiçbir yerde yok. CHANGELOG:29,30 bunun sonucunu üç kez yaşadıklarını anlatıyor (006 uygulanmadığı için **tüm girişler** "Geçersiz telefon veya şifre"; 009 uygulanmadığı için **tüm girişler** "kullanıcı bulunamadı").
- **Öneri:** `golang-migrate` + compose'a `migrate` servisi (`depends_on: postgres: service_healthy`), CI'ya `migrate up` adımı, k8s'e `initContainer`/`Job`.

**A4 🟠 `IF NOT EXISTS` sessiz atlama = yanlış-pozitif idempotency**
- **Kanıt:** `004:5` (`expense_categories`) ve `005:65` (`vehicles`) — §2.2, §2.3.
- **Neden sorun:** `CREATE TABLE IF NOT EXISTS` **kolonları karşılaştırmaz**; farklı şemalı bir tablo varsa hiçbir uyarı vermeden atlar ve sonraki ifade patlar. Bu, "idempotent yazdım, güvenli" yanılgısının kaynağı.
- **Öneri:** Aynı tabloyu iki migration'da tanımlamayı bırak; 004'teki `expense_categories`'ı `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`'e, 005'teki `vehicles`'ı ayrı bir tablo adına (`parking_vehicles`) veya ALTER'a çevir.

**A5 🟠 Index eksikleri — sık sorgulanan kolonlar**
| Sorgu (dosya:satır) | Filtrelenen kolon | Index |
|---|---|---|
| `finance.go:53-59`, `:70-76`, `:92-98` | `monthly_assessments(due_date)` | ❌ yok (`status`, `unit_id`, `(period_year,period_month)` var — 001:161-163) |
| `finance.go:265-269` | `monthly_assessments(property_id)` | ❌ yok |
| `finance.go:123` | `monthly_assessments(property_id, period_year)` | ❌ yok |
| `request.go:49` | `requests(resident_id)` | ✅ 001:384 |
| `request.go:61` | `requests(property_id)` | ✅ 001:382 |
| `resident.go:57` | `users(first_name \|\| ' ' \|\| last_name) ILIKE '%..%'` | ❌ leading-wildcard, index kullanılamaz → **full scan**; `pg_trgm` GIN gerekli |
| `resident.go:58` | `units(block)` | ❌ yok |
| `finance.go:346-347` | `consumption_invoices(meter_id)` | ❌ yok |
| `user.go:26` | `users(phone)` | ✅ 001:80 |
| 006 sonrası | `units`, `payments`, `meters`, `meter_readings`, `contracts`, `packages`, `assets`, `surveys`, `inventory_items`, `meetings`, `facilities`, `bulletin_posts`, `employee_leaves` `(deleted)` | ❌ 21 tablonun 13'ünde deleted index'i yok |

**A6 🟠 FK `ON DELETE` davranışı belirsiz**
- **Kanıt:** 134 `REFERENCES`, 29'u `ON DELETE CASCADE`, **105'i davranış belirtmiyor** → Postgres default `NO ACTION`.
- **Neden sorun:** Örn. `payments.user_id REFERENCES users(id)` (001:207) ve `payments.unit_id REFERENCES units(id)` (208) — davranış yok. Bir kullanıcıyı gerçekten silmeye kalkarsan FK ihlali alırsın; soft-delete yazma kodu da olmadığı için (§3 İddia 13) silme işlemi **hiçbir şekilde** yapılamıyor. `assessment_details.expense_category_id` (001:169) da böyle → gider kalemi silinemez.
- **Öneri:** Denetim/finans kayıtları için `ON DELETE RESTRICT`, referans verisi için `ON DELETE SET NULL` bilinçli olarak belirtilmeli.

**A7 🟡 `payment_assessments.amount` hiç yazılmıyor**
- **Kanıt:** `001:225` `amount DECIMAL(12,2)`; `finance.go:219` `INSERT INTO payment_assessments (payment_id, assessment_id) VALUES ($1,$2)` — `amount` verilmiyor → NULL.
- **Neden sorun:** Bir ödeme birden fazla aidata dağıtılıyorsa hangi aidata ne kadar gittiği kayıtsız → mutabakat yapılamaz.

**A8 🟡 `finance.go:220` hata yutuyor**
```go
r.pool.Exec(ctx, linkQuery, paymentID, aID)   // err kontrol edilmiyor
```
- **Neden sorun:** `payments` satırı yazılır, ilişki satırları sessizce kaybolur. Ayrıca `CreatePayment` transaction içinde değil (satır 206-224) → yarım ödeme kaydı mümkün.

**A9 🟡 `reservations` çakışma engeli yetersiz**
- **Kanıt:** `005:282-283` `CREATE UNIQUE INDEX idx_reservations_no_overlap ON reservations(facility_id, start_time) WHERE status IN ('APPROVED','PENDING')`
- **Neden sorun:** Yalnızca **aynı başlangıç saatini** engelliyor. 10:00-12:00 ile 11:00-13:00 rezervasyonu serbest. Gerçek çözüm `tstzrange` + `EXCLUDE USING gist` constraint'i.

**A10 🟡 `002_seed_data.sql` mantık hatası: `total_share_ratio=10000, total_units=24` ama 6 birim ve 400+400+420×4 = 2480 arsa payı giriliyor** (satır 10, 18-24) → tutarsız demo veri; `AREA_M2`/`SHARE_RATIO` dağıtım testleri yanlış sonuç üretir.

**A11 🟡 `003` audit_logs'u DROP ediyor — veri kaybı**
- **Kanıt:** `003_multi_tenant.sql:63` `DROP TABLE IF EXISTS audit_logs;`
- **Neden sorun:** Migration bir kez daha çalıştırılırsa (veya 003 bir upgrade path'inde çalışırsa) **tüm denetim kayıtları silinir**. KVKK/5651 açısından denetim izinin migration ile yok edilmesi kabul edilemez. Doğrusu `ALTER TABLE ... RENAME COLUMN` + `ADD COLUMN`.

### B. Altyapı

**B1 🔴 Sıfırdan kurulum imkânsız** — §2.2 + §2.3 + `firebase-credentials.json` eksikliği + §3 İddia 6 birlikte: temiz makinede `docker compose up` sonucu postgres init hatasıyla ölür; düzeltilse bile demo giriş çalışmaz. Bu, projenin **tekrar üretilebilirliğinin sıfır** olduğu anlamına gelir; mevcut çalışan ortam elle yapılmış müdahalelerin (CHANGELOG:29,30,74) toplamı ve **kaybolursa geri getirilemez**.
- **Öneri (öncelik sırasıyla):** (1) 004:19-30 seed'ini 001 şemasına uyarla veya `expense_categories`'ı tek yerde tanımla; (2) 005:65-104 `vehicles` bloğunu ALTER'a çevir; (3) 002:29,32 hash'ini bilinen bir şifreyle yeniden üret; (4) migration-runner ekle; (5) `docker compose down -v && up` ile uçtan uca doğrula.

**B2 🔴 Gateway'de ve Kong'da auth yok**
- **Kanıt:** `cmd/gateway/main.go:422` `handler := logMiddleware(corsMiddleware(mux))` — JWT middleware yok. `kong.yml`'de `jwt` plugin sayısı **0**.
- **Neden sorun:** 22 mock servisin (`asset`, `visitor`, `parking`, `personnel`, `banking`, `settings`...) **hiçbirinde** `AuthMiddleware()` yok (grep: `middleware.` yalnızca identity/finance/community'de). Yani `http://localhost:8888/api/v1/employees`, `/api/v1/bank-accounts`, `/api/v1/credentials` **token'sız** erişilebilir. `settings-service` API kimlik bilgilerini yönetiyor (`api_credentials_service.go`) — kimlik doğrulamasız.
- **Öneri:** Kong'a `jwt` plugin'i (veya gateway'e merkezi JWT middleware) ekle; en azından `/api/v1/credentials`, `/api/v1/personnel`, `/api/v1/payroll`, `/api/v1/bank-*` rotalarını kapat.

**B3 🔴 CORS `origins: "*"` + `Authorization` header — her yerde**
- **Kanıt:** `kong.yml`'de 24 servisin hepsinde `origins: - "*"` (örn. satır 22-23, 51-52, ...). `cmd/gateway/main.go:59` `Access-Control-Allow-Origin: *` + `:61` `Allow-Headers: ..., Authorization`.
- **Neden sorun:** Herhangi bir web sitesi kullanıcının token'ıyla API'ye istek atabilir. `.env.example`'da bir `ALLOWED_ORIGINS` bile yok.
- **Öneri:** Ortam bazlı origin listesi (`admin.siteeksen.com`, `localhost:3001`).

**B4 🟠 25 servisin 22'si tamamen mock — "servis" değil, sabit JSON**
- **Kanıt:** Tüm `backend/**/*.go` içinde SQL yalnızca 4 dosyada: `identity/repository/{user,resident}.go`, `finance/repository/finance.go`, `community/repository/request.go`, `pkg/audit/audit.go`. Spot kontrol: `services/asset/main.go`, `services/visitor/main.go`, `services/parking/main.go`, `services/settings/api_credentials_service.go`, `api/handlers/api_credentials_handler.go` → hiçbiri `pkg/database` import etmiyor, `pgx` kullanmıyor. Örnek sabit yanıtlar: `expense/main.go:296-298`, `community/main.go:100-114,155-166,196-207,221-227`.
- **Neden sorun:** ROADMAP:24-43'te 20 servis "✅" işaretli ve ROADMAP:121-122,165-167 "servis hazır" diyor. Şema (61 tablo) bu servisler için yazılmış ama hiçbirine bağlı değil → **47 tablo ölü**. `005_new_modules.sql`'in 45KB'ının **tamamı** kullanılmıyor.
- **Öneri:** ROADMAP'te "✅" yerine "mock" durumu ayrı bir sütunla gösterilmeli; ölü şemayı ya bağla ya migration setinden çıkar.

**B5 🟠 Community servisinde yinelenen/ölü rotalar**
- **Kanıt:** `community/main.go:58-83` `/api/v1/surveys`, `/api/v1/bulletins`, `/api/v1/reservations` mock'ları tanımlı. Ama gateway `/api/v1/surveys`'i survey-service'e (`main.go:211`), `/api/v1/reservations`'ı reservation-service'e (`:202`), `/api/v1/bulletin`'i bulletin-service'e (`:166`) yönlendiriyor → community'nin bu 13 endpoint'i **hiçbir zaman çağrılmaz**. Ayrıca `bulletins` (çoğul) ile gateway'in `bulletin` (tekil) yolu farklı.

**B6 🟠 Kong ile gateway iki ayrı, uyumsuz giriş kapısı**
- Kong: 8000 portu, 25 route, banking+gateway yok, rate-limit %25, JWT yok, `/dashboard` ve `/reports` yok.
- Gateway: 8888 portu, 25 servis + dashboard aggregation + rapor üretimi, auth yok.
- `.env.example:40` admin'i 8000'e (Kong), `docker-compose.yml:193` 8888'e (gateway), `k8s/deployments.yaml:193` `api.siteeksen.com/v1`'e (ingress, ki o da 404 veriyor) yönlendiriyor.
- **Öneri:** Tek bir giriş kapısına karar ver. Kong'u tut ve gateway'i Kong'un arkasında bir "aggregation service" yap (`/api/v1/dashboard`, `/api/v1/reports` route'larını Kong'a ekle), auth'u Kong'da tek yerde çöz.

**B7 🟡 `.gitignore` — sızıntı yok, ama binary listesi eksik**
- **İyi:** Git'te **293 dosya** takip ediliyor; `.env|credential|secret|.pem|.key|node_modules|.exe` deseniyle **hiçbir eşleşme yok**. Diskteki `admin/node_modules` (117 MB) ve `admin/.next` (42 MB) doğru şekilde ignore'lu (`.gitignore:2,7`). `firebase-credentials.json` ignore'lu (satır 57). `.env.example` bilinçli olarak takipte ve içinde gerçek sır yok.
- **Eksik:** `.gitignore:75-94` yalnızca 20 binary adını sayıyor; **`/backend/identity`, `/backend/finance`, `/backend/community`, `/backend/iot`, `/backend/notification`, `/backend/banking` yok** → bu 6 servisin lokal build çıktısı yanlışlıkla commit edilebilir. Daha sağlamı: `/backend/*` altında uzantısız çalıştırılabilirleri kapsayan bir kural veya `go build -o bin/`.

**B8 🟡 `legal/` — içerik gerçek, ama zorunlu KVKK unsurları eksik**
- **Gerçek içerik ✅:** `kvkk-aydinlatma.md` 159 satır, gerçek metin. Mevcut zorunlu unsurlar: veri sorumlusu kimliği (§1, satır 9-16), işlenen veri kategorileri (§2, 20-50), işleme amaçları (§3, 54-76), aktarılan taraflar + amaç (§4, 80-92, yurt dışı dahil), **saklama süreleri tablosu** (§5, 96-106), KVKK m.11 hakları (§7, 122-134), başvuru yolu (§8, 138-148).
- **🔴 Eksik zorunlu unsur:** **"kişisel verilerin toplanma yöntemi ve hukuki sebebi"** (KVKK m.10 ve Aydınlatma Tebliği m.5) hiçbir yerde yok — hangi verinin m.5/2 hangi bendine (sözleşme, hukuki yükümlülük, meşru menfaat) veya açık rızaya dayandığı belirtilmemiş. Bu, aydınlatma metninin **en sık denetlenen** eksiğidir.
- **🟠 Placeholder'lar:** `kvkk-aydinlatma.md:14` `[Şirket Adresi]`, `:16` `[Telefon Numarası]`, `:144` `[Şirket Adresi]`; `gizlilik-politikasi.md:139` `[Şirket Adresi]`; `kullanim-kosullari.md:137` `[Şirket Adresi]`. Ayrıca VERBİS kayıt bilgisi ve varsa veri sorumlusu temsilcisi yok.
- **🟠 Doğrulanamayan/yanlış taahhütler:**
  - `kvkk-aydinlatma.md:114` "Hassas veriler AES-256 ile şifrelenmektedir" — `pkg/encryption/aes.go` var, `users.tc_encrypted/phone_encrypted` (001:64,69) ve `vehicles.plate_encrypted` (001:308) kolonları var; ama `identity/repository/user.go:148` INSERT'i `tc_encrypted`'ı yazsa da hiçbir yerde `encryption` paketi çağrılmıyor (grep `pkg/encryption` → 0 kullanım). **Şifreleme fiilen devrede değil.**
  - `:115` "Rol bazlı yetkilendirme sistemi" — `RequireRole()` yalnızca **1** endpoint'te (`identity/main.go:55`).
  - `:116` "TLS 1.3" — yalnızca ingress'te TLS (`ingress.yaml:13-17`); servisler arası ve DB bağlantısı düz metin (`DB_SSLMODE` default `disable`).
  - `:117` "Günlük yedekleme ve felaket kurtarma" — repoda yedekleme yapılandırması **yok**.
  - `:118` "Periyodik sızma testleri" — kanıt yok (Trivy taraması bile `exit-code` verilmediği için etkisiz).
  - `:146` "Uygulama içi: Ayarlar > Gizlilik > KVKK Başvurusu" — mobil tarafta yalnızca `kvkk_consent_screen.dart` (onay ekranı) var; **başvuru akışı doğrulanamadı** (böyle bir ekran bulunamadı).
  - `:100-104` Saklama süreleri (log 2 yıl vb.) ile **§2.1'deki gerçek durum** çelişiyor: `audit_logs` INSERT'i hiç çalışmadığı için log **hiç tutulmuyor**; ayrıca otomatik silme/anonimleştirme işi (`:106`) hiçbir yerde kodlanmamış.
- **Öneri:** (1) "Toplama yöntemi ve hukuki sebep" bölümünü ekle; (2) placeholder'ları doldur, VERBİS bilgisini ekle; (3) doğrulanamayan güvenlik taahhütlerini ya gerçekleştir ya metinden çıkar (yanlış beyan ayrı bir risk); (4) §2.1'deki audit hatasını düzelt — aksi halde metin "log tutuyoruz" derken hiç log yok.

---

## Ek: Rapor dışı not
`bcryptjs` doğrulaması için scratchpad altında `bcheck/` dizini oluşturuldu (`node_modules` + `t.js`). Repoda hiçbir dosya değiştirilmedi/eklenmedi.
