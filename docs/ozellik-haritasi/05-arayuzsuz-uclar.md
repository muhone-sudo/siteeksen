# 5. Arayüzsüz uçlar ve tutarsızlıklar

## 5.1 Backend'de olup hiçbir istemcide (panel, sakin, yönetici mobil) çağrılmayan uçlar

| Uç | Servis · kayıt | Yetki | Değişen tablolar | Bildirim |
|---|---|---|---|---|
| `POST /asset-categories` | asset · `services/asset/main.go:183` | BOARD_MEMBER/MANAGER | asset_categories(+) | yok |
| `POST /assets/:id/assign` | asset · `services/asset/main.go:220` | BOARD_MEMBER/MANAGER | assets(±) | yok |
| `GET /bulletins/:id` | bulletin · `services/bulletin/main.go:69` | işleyicide `isManagement` (backend/services/community/main.go:257) | bulletin_posts(±) | yok |
| `POST /bulletins/:id/comments` | bulletin · `services/bulletin/main.go:136` | oturum açmış herkes (site kapsamı) | bulletin_comments(+) | yok |
| `GET /announcements/:id` | community · `services/community/main.go:113` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok |
| `POST /renovations/:id/cancel` | community · `services/community/renovation.go:149` | oturum açmış herkes (site kapsamı) | renovation_permits(±) | yok |
| `GET /contracts/:id` | contract · `services/contract/main.go:100` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |
| `GET /documents/:id` | document · `services/document/main.go:110` | işleyicide `hasRole` (backend/services/settings/visibility.go:74); işleyicide `isManagement` (backend/services/community/main.go:257) | document_access_logs(+) · tetikleyici: document_access_logs_no_update | yok |
| `GET /esg/sustainability-score` | esg · `services/esg/main.go:201` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |
| `GET /public/clearance/:code` — Panel /dogrula/[code] (fetch) | finance · `services/finance/main.go:81` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /public/payments/iyzico/callback` — iyzico tarayıcı dönüşü | finance · `services/finance/main.go:83` | oturum açmış herkes (site kapsamı) | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok |
| `GET /finance/my-payments` | finance · `services/finance/main.go:93` | `assessment_visible_to` | — | yok |
| `GET /finance/assessments/overview` | finance · `services/finance/main.go:117` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |
| `POST /governance/budgets/:id/objections` | governance · `services/governance/main.go:114` | oturum açmış herkes (site kapsamı) | budget_objections(+) | yok |
| `POST /auth/refresh` — istemcilerin jeton yenilemesi | identity · `services/identity/main.go:77` | oturum açmış herkes (site kapsamı) | revoked_tokens(+), user_token_invalidation(+), users(±) | yok |
| `POST /users/me/logout-all` | identity · `services/identity/main.go:99` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+) | yok |
| `POST /users/me/tenancy-requests/:id/decline` | identity · `services/identity/main.go:116` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/invitations/:id/decline` | identity · `services/identity/main.go:123` | oturum açmış herkes (site kapsamı) | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok |
| `GET /inventory/:id` | inventory · `services/inventory/main.go:88` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `GET /inventory/:id/movements` | inventory · `services/inventory/main.go:97` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `POST /inventory-categories` | inventory · `services/inventory/main.go:179` | BOARD_MEMBER/MANAGER | inventory_categories(+) | yok |
| `DELETE /inventory/:id` | inventory · `services/inventory/main.go:216` | BOARD_MEMBER/MANAGER | inventory_items(±) | yok |
| `DELETE /meters/:id` | iot · `services/iot/main.go:213` | BOARD_MEMBER/MANAGER | meters(±) | yok |
| `GET /consumption/statements/:id` | iot · `services/iot/main.go:449` | `resident_can_use` | — | yok |
| `GET /sensors` | iot · `services/iot/main.go:482` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /sensors/:id` | iot · `services/iot/main.go:483` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /sensors/:id/data` | iot · `services/iot/main.go:484` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /sensors/:id/data` | iot · `services/iot/main.go:485` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /iot/alerts` | iot · `services/iot/main.go:489` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /iot/alerts/:id/acknowledge` | iot · `services/iot/main.go:490` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /nps/:id/respond` | nps · `services/nps/main.go:76` | oturum açmış herkes (site kapsamı) | survey_votes(+) | yok |
| `GET /packages/:id` | package · `services/package/main.go:99` | `resident_can_use` | — | yok |
| `GET /packages/:id/proof/:kind` | package · `services/package/main.go:185` | `resident_can_use` | — · dosya deposu | yok |
| `POST /public/devices/heartbeat` — geçiş cihazı (X-Device-Key) | parking · `services/parking/devices.go:37` | oturum açmış herkes (site kapsamı) | — | `?` → Operations |
| `GET /vehicles/plate/:plate` | parking · `services/parking/main.go:106` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /patrols` | patrol · `services/patrol/main.go:125` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(+) | yok |
| `POST /patrols/:id/scan` | patrol · `services/patrol/main.go:145` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(±) | yok |
| `POST /patrols/:id/issues` | patrol · `services/patrol/main.go:163` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(±) | yok |
| `POST /patrols/:id/complete` | patrol · `services/patrol/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(±) | `patrol.issue` → Managers |
| `GET /payroll/costs` | personnel · `services/personnel/main.go:96` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |
| `GET /facilities/:id` | reservation · `services/reservation/main.go:91` | oturum açmış herkes (site kapsamı) | — | yok |
| `PUT /privacy/cameras/:id` | settings · `services/settings/main.go:141` | BOARD_MEMBER/MANAGER | camera_devices(±) | yok |
| `GET /credentials` | settings · `services/settings/main.go:167` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /credentials` | settings · `services/settings/main.go:168` | oturum açmış herkes (site kapsamı) | — | yok |
| `PUT /credentials/:id` | settings · `services/settings/main.go:169` | oturum açmış herkes (site kapsamı) | — | yok |
| `DELETE /credentials/:id` | settings · `services/settings/main.go:170` | oturum açmış herkes (site kapsamı) | — | yok |
| `POST /credentials/:id/test` | settings · `services/settings/main.go:171` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /credentials/:id/audit-log` | settings · `services/settings/main.go:172` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /credentials-available-services` | settings · `services/settings/main.go:174` | oturum açmış herkes (site kapsamı) | — | yok |
| `GET /surveys/:id/comments` | survey · `services/survey/main.go:119` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok |
| `POST /visitors/:id/pass` | visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok |

## 5.2 Yazılmamış modüller (501)

- **banking** — 16 uç, hepsi 501: `GET /bank-accounts`, `GET /bank-accounts/banks`, `GET /bank-accounts/stats`, `GET /bank-accounts/:id`, `POST /bank-accounts`, `POST /bank-accounts/:id/sync`, `GET /bank-accounts/:id/balance`, `GET /bank-accounts/:id/transactions`, `GET /bank-transactions`, `GET /bank-transactions/unmatched`, `GET /bank-transactions/suggestions`, `GET /bank-transactions/:id`, `POST /bank-transactions/:id/match`, `POST /bank-transactions/:id/unmatch`, `POST /bank-transactions/auto-match`, `GET /banking/report`
- **meeting_wizard** — 17 uç, hepsi 501: `GET /meetings`, `GET /meetings/stats`, `GET /meetings/:id`, `POST /meetings`, `POST /meetings/:id/start`, `POST /meetings/:id/end`, `GET /meetings/:id/attendees`, `POST /meetings/:id/attendees`, `POST /meetings/:id/attendance`, `GET /meetings/:id/decisions`, `GET /meetings/:id/action-items`, `POST /meetings/:id/generate-minutes`, `POST /meetings/:id/transcribe`, `GET /meetings/:id/transcript`, `POST /meetings/:id/summarize`, `GET /meetings/:id/summary`, `GET /action-items`

## 5.3 Kodda bulunan tutarsızlıklar

- Giriş sayfası: "Yöneticinize başvurun" bağlantısı `href="#"` — hiçbir yere gitmiyor (`admin/src/app/login/page.tsx:154`).
- CLAUDE.md'deki "panelde çıkış (logout) düğmesi yok" ve "rol bazlı erişim kontrolü yok" ifadeleri eskimiş: çıkış `components/layout/header.tsx:148`, rol denetimi `admin/src/lib/rbac.ts` + `middleware.ts`.
- Yönetime giden uygulama içi bildirimler için panelde ve yönetici mobil uygulamasında kişisel bildirim kutusu yok (bkz. 4.1).
- Panel *Entegrasyon Anahtarları* sayfası backend'i çağırmaz, yalnız bilgi notu gösterir; `settings` servisindeki `/credentials*` uçları hiçbir istemcide kullanılmıyor.
