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
| `POST /auth/supplier-signup/verify` | identity · `services/identity/main.go:86` | oturum açmış herkes (site kapsamı) | phone_verifications(±) | yok |
| `GET /inventory/:id` | inventory · `services/inventory/main.go:88` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `GET /consumption/statements/:id` | iot · `services/iot/main.go:448` | `resident_can_use` | — | yok |
| `POST /public/sensors/data` — IoT sensörü (X-Device-Key, 074) | iot · `services/iot/sensors.go:127` | oturum açmış herkes (site kapsamı) | sensor_alerts(+), sensor_alerts(±) | `{topic}` → Operations |
| `GET /sensors/:id` | iot · `services/iot/sensors.go:191` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok |
| `POST /public/market/topups/iyzico/callback` | marketplace · `services/marketplace/main.go:70` | oturum açmış herkes (site kapsamı) | mp_card_refunds(+), mp_wallet_ledger(+), mp_supplier_accounts(±), mp_topups(±) · tetikleyici: mp_wallet_ledger_no_change | yok |
| `GET /market/services/:id/photo` | marketplace · `services/marketplace/main.go:77` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | — · dosya deposu | yok |
| `GET /market/requests/:id/photos/:n` | marketplace · `services/marketplace/main.go:88` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | — · dosya deposu | yok |
| `GET /market/supplier/requests/:id/photos/:n` | marketplace · `services/marketplace/main.go:126` | Supplier; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | — · dosya deposu | yok |
| `GET /market/supplier/topups/:id` | marketplace · `services/marketplace/main.go:138` | Supplier | — | yok |
| `GET /market/platform/accounts` | marketplace · `services/marketplace/main.go:145` | PlatformAdmin | — | yok |
| `GET /market/platform/accounts/:id` | marketplace · `services/marketplace/main.go:146` | PlatformAdmin | — | yok |
| `POST /market/platform/accounts/:id/approve` | marketplace · `services/marketplace/main.go:147` | PlatformAdmin | mp_account_documents(±), mp_supplier_accounts(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/accounts/:id/reject` | marketplace · `services/marketplace/main.go:148` | PlatformAdmin | mp_account_documents(±), mp_supplier_accounts(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/accounts/:id/suspend` | marketplace · `services/marketplace/main.go:149` | PlatformAdmin | mp_account_documents(±), mp_supplier_accounts(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/accounts/:id/reinstate` | marketplace · `services/marketplace/main.go:150` | PlatformAdmin | mp_account_documents(±), mp_supplier_accounts(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/accounts/:id/close` | marketplace · `services/marketplace/main.go:151` | PlatformAdmin | mp_card_refunds(+), mp_wallet_ledger(+), mp_businesses(±), mp_card_refunds(±), mp_supplier_accounts(±) · tetikleyici: mp_wallet_ledger_no_change | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `GET /market/platform/card-refunds` | marketplace · `services/marketplace/main.go:152` | PlatformAdmin | — | yok |
| `POST /market/platform/card-refunds/:id/manual` | marketplace · `services/marketplace/main.go:153` | PlatformAdmin | mp_card_refunds(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/card-refunds/:id/retry` | marketplace · `services/marketplace/main.go:154` | PlatformAdmin | mp_card_refunds(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `GET /market/platform/documents/:id/file` | marketplace · `services/marketplace/main.go:155` | PlatformAdmin | mp_document_access_logs(+) · dosya deposu | yok |
| `GET /market/platform/businesses` | marketplace · `services/marketplace/main.go:156` | PlatformAdmin | — | yok |
| `POST /market/platform/businesses/:id/approve` | marketplace · `services/marketplace/main.go:157` | PlatformAdmin | mp_businesses(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/businesses/:id/reject` | marketplace · `services/marketplace/main.go:158` | PlatformAdmin | mp_businesses(±) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `GET /market/platform/categories` | marketplace · `services/marketplace/main.go:159` | PlatformAdmin | — | yok |
| `POST /market/platform/categories` | marketplace · `services/marketplace/main.go:160` | PlatformAdmin | mp_categories(+), mp_categories(±) | yok |
| `PUT /market/platform/categories/:id` | marketplace · `services/marketplace/main.go:161` | PlatformAdmin | mp_categories(+), mp_categories(±) | yok |
| `GET /market/platform/packages` | marketplace · `services/marketplace/main.go:162` | PlatformAdmin | — | yok |
| `POST /market/platform/packages` | marketplace · `services/marketplace/main.go:163` | PlatformAdmin | mp_packages(+), mp_packages(±) | yok |
| `PUT /market/platform/packages/:id` | marketplace · `services/marketplace/main.go:164` | PlatformAdmin | mp_packages(+), mp_packages(±) | yok |
| `PUT /market/platform/settings/:key` | marketplace · `services/marketplace/main.go:165` | PlatformAdmin | mp_settings(±) | yok |
| `GET /market/platform/disputes` | marketplace · `services/marketplace/main.go:166` | PlatformAdmin | — | yok |
| `POST /market/platform/disputes/:id/approve` | marketplace · `services/marketplace/main.go:167` | PlatformAdmin | mp_card_refunds(+), mp_wallet_ledger(+), mp_disputes(±), mp_request_dispatch(±), mp_supplier_accounts(±) · tetikleyici: mp_wallet_ledger_no_change | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /market/platform/disputes/:id/reject` | marketplace · `services/marketplace/main.go:168` | PlatformAdmin | mp_card_refunds(+), mp_wallet_ledger(+), mp_disputes(±), mp_request_dispatch(±), mp_supplier_accounts(±) · tetikleyici: mp_wallet_ledger_no_change | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `GET /market/platform/reviews` | marketplace · `services/marketplace/main.go:169` | PlatformAdmin | — | yok |
| `POST /market/platform/reviews/:id/hide` | marketplace · `services/marketplace/main.go:170` | PlatformAdmin | mp_reviews(±) · tetikleyici: mp_reviews_guard, mp_reviews_rating_refresh | yok |
| `GET /market/platform/revenue` | marketplace · `services/marketplace/main.go:171` | PlatformAdmin | — | yok |
| `GET /moderation/photos` | moderation · `services/moderation/main.go:67` | PlatformAdmin | — | yok |
| `GET /moderation/photos/:id/image` | moderation · `services/moderation/main.go:68` | PlatformAdmin | — · dosya deposu | yok |
| `POST /moderation/photos/:id/approve` | moderation · `services/moderation/main.go:69` | PlatformAdmin | photo_moderation(±) | `market.photo.rejected` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /moderation/photos/:id/reject` | moderation · `services/moderation/main.go:70` | PlatformAdmin | photo_moderation(±) | `market.photo.rejected` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /moderation/photos/:id/recheck` | moderation · `services/moderation/main.go:71` | PlatformAdmin | photo_moderation(±) · dosya deposu | `market.photo.rejected` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `GET /moderation/ai-settings` | moderation · `services/moderation/main.go:72` | PlatformAdmin | — | yok |
| `PUT /moderation/ai-settings` | moderation · `services/moderation/main.go:73` | PlatformAdmin | moderation_ai_settings(±) | yok |
| `POST /moderation/ai-settings/test` | moderation · `services/moderation/main.go:74` | PlatformAdmin | — | yok |
| `GET /packages/:id` | package · `services/package/main.go:99` | `resident_can_use` | — | yok |
| `POST /public/devices/heartbeat` — geçiş cihazı (X-Device-Key) | parking · `services/parking/devices.go:37` | oturum açmış herkes (site kapsamı) | — | `?` → Operations |
| `GET /facilities/:id` | reservation · `services/reservation/main.go:91` | oturum açmış herkes (site kapsamı) | — | yok |

## 5.2 Yazılmamış modüller (501)

- **banking** — 16 uç, hepsi 501: `GET /bank-accounts`, `GET /bank-accounts/banks`, `GET /bank-accounts/stats`, `GET /bank-accounts/:id`, `POST /bank-accounts`, `POST /bank-accounts/:id/sync`, `GET /bank-accounts/:id/balance`, `GET /bank-accounts/:id/transactions`, `GET /bank-transactions`, `GET /bank-transactions/unmatched`, `GET /bank-transactions/suggestions`, `GET /bank-transactions/:id`, `POST /bank-transactions/:id/match`, `POST /bank-transactions/:id/unmatch`, `POST /bank-transactions/auto-match`, `GET /banking/report`

Bulunan tutarsızlıklar ve eksikler: [6. Bulgular ve eksikler](06-bulgular-ve-eksikler.md).
