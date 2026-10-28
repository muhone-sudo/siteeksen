# 5. Arayüzsüz uçlar ve tutarsızlıklar

## 5.1 Backend'de olup hiçbir istemcide (panel, sakin, yönetici mobil) çağrılmayan uçlar

| Uç | Servis · kayıt | Yetki | Değişen tablolar | Bildirim |
|---|---|---|---|---|
| `GET /bulletins/:id` | bulletin · `services/bulletin/main.go:69` | işleyicide `isManagement` (backend/services/community/main.go:257) | bulletin_posts(±) | yok |
| `GET /announcements/:id` | community · `services/community/main.go:113` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok |
| `GET /contracts/:id` | contract · `services/contract/main.go:100` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |
| `GET /documents/:id` | document · `services/document/main.go:110` | işleyicide `hasRole` (backend/services/settings/visibility.go:74); işleyicide `isManagement` (backend/services/community/main.go:257) | document_access_logs(+) · tetikleyici: document_access_logs_no_update | yok |
| `GET /public/clearance/:code` — Panel /dogrula/[code] (fetch) | finance · `services/finance/main.go:82` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /public/payments/iyzico/callback` — iyzico tarayıcı dönüşü | finance · `services/finance/main.go:84` | oturum açmış herkes (site kapsamı) | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok |
| `GET /finance/assessments/:id` | finance · `services/finance/main.go:92` | `assessment_visible_to` | — | yok |
| `POST /auth/refresh` — istemcilerin jeton yenilemesi | identity · `services/identity/main.go:79` | oturum açmış herkes (site kapsamı) | revoked_tokens(+), user_token_invalidation(+), users(±) | yok |
| `GET /inventory/:id` | inventory · `services/inventory/main.go:88` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `GET /consumption/statements/:id` | iot · `services/iot/main.go:448` | `resident_can_use` | — | yok |
| `POST /public/sensors/data` — IoT sensörü (X-Device-Key, 074) | iot · `services/iot/sensors.go:127` | oturum açmış herkes (site kapsamı) | sensor_alerts(+), sensor_alerts(±) | `{topic}` → Operations |
| `GET /sensors/:id` | iot · `services/iot/sensors.go:191` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `GET /packages/:id` | package · `services/package/main.go:99` | `resident_can_use` | — | yok |
| `POST /public/devices/heartbeat` — geçiş cihazı (X-Device-Key) | parking · `services/parking/devices.go:37` | oturum açmış herkes (site kapsamı) | — | `?` → Operations |
| `GET /facilities/:id` | reservation · `services/reservation/main.go:91` | oturum açmış herkes (site kapsamı) | — | yok |

## 5.2 Yazılmamış modüller (501)

- **banking** — 16 uç, hepsi 501: `GET /bank-accounts`, `GET /bank-accounts/banks`, `GET /bank-accounts/stats`, `GET /bank-accounts/:id`, `POST /bank-accounts`, `POST /bank-accounts/:id/sync`, `GET /bank-accounts/:id/balance`, `GET /bank-accounts/:id/transactions`, `GET /bank-transactions`, `GET /bank-transactions/unmatched`, `GET /bank-transactions/suggestions`, `GET /bank-transactions/:id`, `POST /bank-transactions/:id/match`, `POST /bank-transactions/:id/unmatch`, `POST /bank-transactions/auto-match`, `GET /banking/report`

Bulunan tutarsızlıklar ve eksikler: [6. Bulgular ve eksikler](06-bulgular-ve-eksikler.md).
