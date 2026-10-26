# 3. Yönetici mobil uygulaması — ekran ekran

Kaynak: `admin_app/lib/`. Rotalar: `admin_app/lib/core/router/app_router.dart`. API istemcisi: `admin_app/lib/core/network/api_client.dart`.

### api_views
- **Dosya:** `admin_app/lib/core/widgets/api_views.dart`
- **Ekranda:**
  - Pencere (satır 61): Vazgeç
  - Pencere (satır 93): Vazgeç

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 75) | — | | | | |
| 2 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 76) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 97) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 98) | — | | | | |

### apple_widgets
- **Dosya:** `admin_app/lib/core/widgets/apple_widgets.dart`

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 79) | — | | | | |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 147) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 259) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 359) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 407) | — | | | | |
| 6 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 579) | — | | | | |

### data_state
- **Dosya:** `admin_app/lib/core/widgets/data_state.dart`

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yeniden dene — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 69) | — | | | | |

### signature_pad
- **Dosya:** `admin_app/lib/core/widgets/signature_pad.dart`
- **Ekranda:**
  - Pencere (satır 98): Temizle

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Temizle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 102) | — | | | | |
| 2 | Düğme **İmzasız teslim — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 3 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 104) | — | | | | |

### announcements_screen
- **Dosya:** `admin_app/lib/features/announcements/presentation/screens/announcements_screen.dart`
- **Rota:** `/announcements`
- **Ekranda:**
  - Veri (satır 1): `GET /announcements` (community)
  - Mesaj (satır 88): İşlem yapılamadı: ${toUserMessage(e)}
  - Başlık (satır 99): Duyurular

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **?** (satır 102) | `GET /announcements` · community · `services/community/main.go:101` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |
| 2 | Düğme **Duyuru Yayınla (gider: /announcements/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 109) | — | | | | |

### create_announcement_screen
- **Dosya:** `admin_app/lib/features/announcements/presentation/screens/create_announcement_screen.dart`
- **Rota:** `create`
- **Ekranda:**
  - Başlık (satır 56): Duyuru Yayınla
  - Alan (satır 87): Başlık *
  - Alan (satır 98): İçerik *
  - Alan (satır 110): Kategori
  - Mesaj (satır 221): Duyuru yayınlanamadı: ${toUserMessage(e)}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yayınla** (satır 59) | `POST /announcements` · community · `services/community/main.go:138` | BOARD_MEMBER/MANAGER | announcements(+) | `announcement`, `announcement.urgent` → Residents | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |
| 2 | Seçim **Genel — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 109) | — | | | | |

### asset_management_screen
- **Dosya:** `admin_app/lib/features/assets/presentation/screens/asset_management_screen.dart`
- **Rota:** `/assets`
- **Ekranda:**
  - Veri (satır 1): `GET /assets` (asset)
  - Başlık (satır 62): Demirbaşlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yenile** (satır 67) | `GET /assets` · asset · `services/asset/main.go:74` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |

### activate_screen
- **Dosya:** `admin_app/lib/features/auth/presentation/screens/activate_screen.dart`
- **Rota:** `/activate`
- **Ekranda:**
  - Mesaj (satır 118): Şifreniz belirlendi. Şimdi giriş yapabilirsiniz.
  - Başlık (satır 131): Şifre Belirle
  - Alan (satır 160): Telefon Numarası
  - Alan (satır 160): 0555 123 45 67 · yurt dışı: +49 …
  - Alan (satır 178): Kod
  - Alan (satır 185): Yeni Şifre
  - Alan (satır 192): Yeni Şifre (tekrar)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yeniden gönder (${_cooldown}s) / Kodu SMS ile gönder** (satır 165) | `POST /auth/password-reset/request` · identity · `services/identity/main.go:81` | oturum açmış herkes (site kapsamı) | user_activation_codes(+), user_activation_codes(±) | `identity.self_reset` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 2 | Düğme **Şifremi Belirle (gider: /login)** (satır 196) | `POST /auth/activate` · identity · `services/identity/main.go:79` | oturum açmış herkes (site kapsamı) | resident_units(+), user_token_invalidation(+), resident_invitations(±), user_activation_codes(±), users(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management, Yön.mobil visitor_management |

### kvkk_consent_screen
- **Dosya:** `admin_app/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`
- **Rota:** `/kvkk-consent`
- **Ekranda:**
  - Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
  - Başlık (satır 40): Kişisel Verilerin Korunması

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onaylıyorum ve Devam Ediyorum (gider: /)** (satır 84) | `POST /users/me/kvkk-consent` · identity · `services/identity/main.go:97` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |

### login_screen
- **Dosya:** `admin_app/lib/features/auth/presentation/screens/login_screen.dart`
- **Rota:** `/login`
- **Ekranda:**
  - Pencere (satır 92): Biyometrik Giriş
  - Alan (satır 222): Telefon Numarası
  - Alan (satır 223): +90 555 123 4567
  - Alan (satır 240): Şifre

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Hayır — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 98) | — | | | | |
| 2 | Düğme **Etkinleştir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 102) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 242) | — | | | | |
| 4 | Düğme **Giriş Yap (gider: /kvkk-consent, /; pencere açar)** (satır 261) | `POST /auth/login` · identity · `services/identity/main.go:76` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 5 | Düğme **Biyometrik Giriş (gider: /) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 275) | — | | | | |
| 6 | Düğme **Şifremi Unuttum / Hesabı Etkinleştir (gider: /activate) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 287) | — | | | | |

### bank_integration_screen
- **Dosya:** `admin_app/lib/features/banking/presentation/screens/bank_integration_screen.dart`
- **Rota:** `/banking`
- **Ekranda:**
  - Başlık (satır 16): Banka

### bulletin_board_screen
- **Dosya:** `admin_app/lib/features/bulletin/presentation/screens/bulletin_board_screen.dart`
- **Rota:** `/bulletin`
- **Ekranda:**
  - Veri (satır 1): `GET /bulletins/:id/comments` (bulletin); `GET /bulletins` (bulletin); `GET /bulletins-summary` (bulletin)
  - Başlık (satır 170): İlan Panosu
  - Sekmeler (satır 172): Onay bekleyen
  - Sekmeler (satır 172): Yayında
  - Sekmeler (satır 172): Tümü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gizle (pencere açar)** (satır 104) | `DELETE /bulletin-comments/:id` · bulletin · `services/bulletin/main.go:154` | oturum açmış herkes (site kapsamı) | bulletin_comments(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 2 | Düğme **${b[ (pencere açar)** (satır 149) | `DELETE /bulletin-comments/:id` · bulletin · `services/bulletin/main.go:154` | oturum açmış herkes (site kapsamı) | bulletin_comments(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 3 | Düğme **Reddet (pencere açar)** (satır 155) | `POST /bulletins/:id/reject` · bulletin · `services/bulletin/main.go:183` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 4 | Düğme **Onayla** (satır 156) | `POST /bulletins/:id/approve` · bulletin · `services/bulletin/main.go:170` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 5 | Düğme **Kapat (pencere açar)** (satır 158) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | oturum açmış herkes (site kapsamı) | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |

### smart_collection_screen
- **Dosya:** `admin_app/lib/features/collection/presentation/screens/smart_collection_screen.dart`
- **Rota:** `/collection`
- **Ekranda:**
  - Veri (satır 1): `GET /collection/risk` (smart_collection)
  - Başlık (satır 68): Tahsilat Riski

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Skorları kaydet (pencere açar)** (satır 72) | `POST /collection/risk/snapshot` · smart_collection · `services/smart_collection/main.go:120` | BOARD_MEMBER/MANAGER | payment_risk_scores(−), payment_risk_scores(+) | yok |  |

### contract_management_screen
- **Dosya:** `admin_app/lib/features/contracts/presentation/screens/contract_management_screen.dart`
- **Rota:** `/contracts`
- **Ekranda:**
  - Veri (satır 1): `GET /contracts` (contract); `GET /contracts-summary` (contract)
  - Başlık (satır 129): Sözleşmeler
  - Sekmeler (satır 131): Yürürlükte
  - Sekmeler (satır 131): 60 günde bitenler
  - Sekmeler (satır 131): Tümü
  - Mesaj (satır 228): Bitiş tarihi başlangıçtan önce olamaz
  - Alan (satır 269): Tür
  - Alan (satır 275): Başlık *
  - Alan (satır 280): Karşı taraf (firma / kişi) *
  - Alan (satır 304): Ödeme
  - Alan (satır 315): Tutar (₺)
  - Alan (satır 321): Yenileme süresi (ay)
  - Alan (satır 327): İhbar süresi (gün)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Feshet (pencere açar)** (satır 115) | `POST /contracts/:id/terminate` · contract · `services/contract/main.go:151` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 2 | Düğme **Yenile (pencere açar)** (satır 117) | `POST /contracts/:id/renew` · contract · `services/contract/main.go:138` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 3 | Düğme **Sözleşme (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 134) | — | | | | |
| 4 | Seçim **Tür — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 267) | — | | | | |
| 5 | Düğme **Başlangıç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 283) | — | | | | |
| 6 | Düğme **Bitiş — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 292) | — | | | | |
| 7 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 296) | — | | | | |
| 8 | Seçim **Aylık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 302) | — | | | | |
| 9 | Düğme **Kaydet** (satır 331) | `POST /contracts` · contract · `services/contract/main.go:117` | BOARD_MEMBER/MANAGER | contracts(+) | yok | Panel/contracts, Yön.mobil contract_management |

### dashboard_screen
- **Dosya:** `admin_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Rota:** `/`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/payments` (finance); `GET /dashboard/stats` (gateway)
  - Başlık (satır 108): Dashboard

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **?** (satır 111) | `GET /finance/payments` · finance · `services/finance/main.go:116` | AUDITOR/BOARD_MEMBER/MANAGER; `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /dashboard/stats` · gateway · `backend/cmd/gateway/main.go` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **Tahakkuk Oluştur (gider: /finance/assessments/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 146) | — | | | | |
| 3 | Düğme **Duyuru Yayınla (gider: /announcements/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 154) | — | | | | |
| 4 | Düğme **Sayaç Oku (gider: /meters/reading) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 166) | — | | | | |
| 5 | Düğme **Rapor Oluştur (gider: /reports) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 174) | — | | | | |
| 6 | Düğme **Tümünü Gör (gider: /finance/payments) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 193) | — | | | | |
| 7 | Düğme **Toplam Sakin (gider: /residents) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 231) | — | | | | |
| 8 | Düğme **Dönem Tahsilatı (gider: /finance) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 238) | — | | | | |
| 9 | Düğme **Tahsilat Oranı (gider: /finance) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 245) | — | | | | |
| 10 | Düğme **Açık Talep (gider: /requests) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 253) | — | | | | |
| 11 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 320) | — | | | | |
| 12 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 379) | — | | | | |

### energy_dashboard_screen
- **Dosya:** `admin_app/lib/features/energy/presentation/screens/energy_dashboard_screen.dart`
- **Rota:** `/energy`
- **Ekranda:**
  - Veri (satır 1): `GET /energy/trends` (energy_analytics); `GET /energy/anomalies` (energy_analytics)
  - Başlık (satır 51): Tüketim Analizi
  - Sekmeler (satır 53): Eğilim
  - Sekmeler (satır 53): Olağandışı

### add_expense_screen
- **Dosya:** `admin_app/lib/features/expenses/presentation/screens/add_expense_screen.dart`
- **Rota:** `add`
- **Ekranda:**
  - Veri (satır 1): `GET /expense-categories` (expense)
  - Başlık (satır 95): Gider Ekle
  - Alan (satır 154): Kategori *
  - Alan (satır 198): Açıklama *
  - Alan (satır 209): Tutar (₺) *
  - Alan (satır 224): Tarih *
  - Alan (satır 271): Faturasız olma nedeni *
  - Alan (satır 331): Firma Adı
  - Alan (satır 336): Fatura No
  - Mesaj (satır 386): Kategori seçin.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kaydet** (satır 98) | `POST /expenses` · expense · `services/expense/main.go:71` | BOARD_MEMBER/MANAGER | expense_distributions(+), expenses(+) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |
| 2 | Seçim **name / category_name / — — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 151) | — | | | | |
| 3 | Düğme **Tarih * — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 220) | — | | | | |

### expense_detail_screen
- **Dosya:** `admin_app/lib/features/expenses/presentation/screens/expense_detail_screen.dart`
- **Rota:** `:id`
- **Ekranda:**
  - Veri (satır 1): `GET /expenses/:id` (expense)
  - Başlık (satır 89): Gider Detayı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Reddet (pencere açar)** (satır 96) | `POST /expenses/:id/reject` · expense · `services/expense/main.go:73` | BOARD_MEMBER/MANAGER | expenses(±) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |
| 2 | Düğme **Onayla (pencere açar)** (satır 98) | `POST /expenses/:id/approve` · expense · `services/expense/main.go:72` | BOARD_MEMBER/MANAGER | expenses(±) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |

### expenses_screen
- **Dosya:** `admin_app/lib/features/expenses/presentation/screens/expenses_screen.dart`
- **Rota:** `/expenses`
- **Ekranda:**
  - Veri (satır 1): `GET /expenses` (expense)
  - Başlık (satır 91): Gider Yönetimi
  - Mesaj (satır 99): Dışa aktarma henüz hazır değil.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Dışa aktarma henüz hazır değil. — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 94) | — | | | | |
| 2 | Düğme **${_monthName(_month)} $_year (pencere açar)** (satır 111) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 3 | Düğme **Tümü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 4 | Düğme **Aidata Yansıyan — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 147) | — | | | | |
| 5 | Düğme **Faturasız — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 151) | — | | | | |
| 6 | Düğme **Onay Bekleyen — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 155) | — | | | | |
| 7 | Düğme **Gider Ekle (gider: /expenses/add)** (satır 166) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 8 | Düğme **? (gider: /expenses/$id) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 253) | — | | | | |
| 9 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 293) | — | | | | |
| 10 | Düğme **Faturasız — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 422) | — | | | | |

### resident_expenses_screen
- **Dosya:** `admin_app/lib/features/expenses/presentation/screens/resident_expenses_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /expenses` (expense)
  - Başlık (satır 70): Site Giderleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Dönem seç (pencere açar)** (satır 73) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 2 | Düğme **${_monthName(_month)} $_year (pencere açar)** (satır 189) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 230) | — | | | | |
| 4 | Düğme **Faturayı Görüntüle (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 375) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 413) | — | | | | |

### collection_entry_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/collection_entry_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/units/:id/open-assessments` (finance); `GET /units` (identity)
  - Başlık (satır 95): Tahsilat gir
  - Alan (satır 107): Daire
  - Alan (satır 151): Açıklama / makbuz no

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${u[** (satır 105) | `GET /finance/units/:id/open-assessments` · finance · `services/finance/main.go:125` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 2 | Düğme **Ödeme günü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 141) | — | | | | |
| 3 | Düğme **Kaydediliyor… / Kaydet ve borçtan düş** (satır 154) | `POST /finance/collections` · finance · `services/finance/main.go:154` | BOARD_MEMBER/MANAGER; `assessment_visible_to` | finance_ledger(+), late_fee_accruals(+), payment_assessments(+), payments(+), bank_statement_lines(±), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `payment.recorded` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil payments, Yön.mobil smart_collection |

### create_assessment_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/create_assessment_screen.dart`
- **Rota:** `assessments/create`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/expense-categories` (finance); `GET /units` (identity)
  - Başlık (satır 112): Tahakkuk Oluştur
  - Alan (satır 152): Yıl
  - Alan (satır 163): Ay
  - Mesaj (satır 309): En az bir gider kalemi ekleyin.
  - Mesaj (satır 313): Her kalem için kategori ve sıfırdan büyük tutar girin.
  - Alan (satır 395): Kalem
  - Alan (satır 416): Tutar (₺)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **$y — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 150) | — | | | | |
| 2 | Seçim **Ay — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 161) | — | | | | |
| 3 | Düğme **Son Ödeme Tarihi — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 174) | — | | | | |
| 4 | Düğme **Ekle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 193) | — | | | | |
| 5 | Düğme **Tahakkuk Oluştur** (satır 272) | `POST /finance/assessments` · finance · `services/finance/main.go:134` | BOARD_MEMBER/MANAGER | assessment_details(+), monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil payments, Yön.mobil smart_collection |
| 6 | Seçim **name / category_name / — — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 392) | — | | | | |
| 7 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 426) | — | | | | |

### finance_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/finance_screen.dart`
- **Rota:** `/finance`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/assessments/:id` (finance); `GET /finance/debtors` (finance)
  - Başlık (satır 39): Finans
  - Sekmeler (satır 48): Dönemler
  - Sekmeler (satır 48): Borçlular

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Ödemeler (gider: /finance/payments) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 42) | — | | | | |
| 2 | Düğme **Tahakkuk (gider: /finance/assessments/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 51) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 60) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 62) | — | | | | |

### payments_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/payments_screen.dart`
- **Rota:** `payments`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/payments/pending` (finance); `GET /finance/payments` (finance)
  - Başlık (satır 121): Ödemeler
  - Sekmeler (satır 123): Onay bekleyen
  - Sekmeler (satır 123): Tümü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Reddet (pencere açar)** (satır 107) | `POST /finance/payments/:id/reject` · finance · `services/finance/main.go:139` | BOARD_MEMBER/MANAGER | payments(±) · tetikleyici: payments_guard | yok | Panel/accounting, Sakin dues_payment, Yön.mobil dashboard, Yön.mobil payments |
| 2 | Düğme **Onayla (pencere açar)** (satır 109) | `POST /finance/payments/:id/confirm` · finance · `services/finance/main.go:137` | BOARD_MEMBER/MANAGER | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil payments, Yön.mobil smart_collection |
| 3 | Düğme **Tahsilat gir (gider: CollectionEntryScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 126) | — | | | | |

### governance_screen
- **Dosya:** `admin_app/lib/features/governance/presentation/screens/governance_screen.dart`
- **Rota:** `/governance`
- **Ekranda:**
  - Veri (satır 1): `GET /governance/budgets` (governance); `GET /governance/budgets/:id` (governance); `GET /governance/assemblies` (governance); `GET /governance/assemblies/:id` (governance); `GET /governance/books/:id/entries` (governance); `GET /governance/books/:id/verify` (governance)
  - Başlık (satır 33): Yönetişim
  - Sekmeler (satır 35): İşletme projesi
  - Sekmeler (satır 35): Genel kurul
  - Sekmeler (satır 35): Karar defteri
  - Başlık (satır 73): İşletme projesi
  - Başlık (satır 141): Genel kurul

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${b[ (gider: _BudgetDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 51) | — | | | | |
| 2 | Düğme **${a[ (gider: _AssemblyDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 120) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 204) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 206) | — | | | | |

### inventory_management_screen
- **Dosya:** `admin_app/lib/features/inventory/presentation/screens/inventory_management_screen.dart`
- **Rota:** `/inventory`
- **Ekranda:**
  - Veri (satır 1): `GET /inventory` (inventory); `GET /inventory-summary` (inventory)
  - Pencere (satır 40): ${item[
  - Alan (satır 47): Hareket
  - Alan (satır 58): Miktar (${item[
  - Başlık (satır 94): Stok

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **Giriş (alım) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 45) | — | | | | |
| 2 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 69) | — | | | | |
| 3 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 70) | — | | | | |
| 4 | Düğme **Hareket — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 128) | — | | | | |

### main_screen
- **Dosya:** `admin_app/lib/features/main/presentation/screens/main_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity)
  - Pencere (satır 139): Uygulamadan çık

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 2 | Düğme **Çık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 144) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 205) | — | | | | |
| 4 | Düğme **Şifre Değiştir (gider: /login; pencere açar)** (satır 216) | `POST /users/me/password` · identity · `services/identity/main.go:100` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 5 | Düğme **Çıkış Yap (gider: /login; pencere açar)** (satır 224) | `POST /auth/logout` · identity · `services/identity/main.go:85` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 6 | Düğme **Çıkış yap (gider: /login; pencere açar)** (satır 263) | `POST /auth/logout` · identity · `services/identity/main.go:85` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |

### meeting_wizard_screen
- **Dosya:** `admin_app/lib/features/meetings/presentation/screens/meeting_wizard_screen.dart`
- **Rota:** `/meetings`
- **Ekranda:**
  - Başlık (satır 16): Toplantılar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yönetişime git (gider: /governance) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 25) | — | | | | |

### meter_reading_screen
- **Dosya:** `admin_app/lib/features/meters/presentation/screens/meter_reading_screen.dart`
- **Rota:** `reading`
- **Ekranda:**
  - Veri (satır 1): `GET /meters` (iot)
  - Mesaj (satır 75): $ok / ${entries.length} okuma kaydedildi
  - Başlık (satır 81): Sayaç Okuma
  - Alan (satır 118): Yeni değer

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 84) | — | | | | |
| 2 | Düğme **Kaydediliyor… / Girilen okumaları kaydet** (satır 97) | `POST /meter-readings` · iot · `services/iot/main.go:162` | BOARD_MEMBER/MANAGER/STAFF | meter_readings(+) | yok | Panel/energy, Panel/esg, Panel/meters, Yön.mobil energy_dashboard, Yön.mobil meter_reading, Yön.mobil meters |

### meters_screen
- **Dosya:** `admin_app/lib/features/meters/presentation/screens/meters_screen.dart`
- **Rota:** `/meters`
- **Ekranda:**
  - Veri (satır 1): `GET /meters` (iot)
  - Başlık (satır 35): Sayaçlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Okuma gir (gider: /meters/reading) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 36) | — | | | | |

### package_tracking_screen
- **Dosya:** `admin_app/lib/features/packages/presentation/screens/package_tracking_screen.dart`
- **Rota:** `/packages`
- **Ekranda:**
  - Veri (satır 1): `GET /packages-summary` (package); `GET /packages` (package); `GET /units` (identity)
  - Başlık (satır 36): Kargo
  - Pencere (satır 143): Kargo kabul
  - Alan (satır 151): Daire
  - Alan (satır 159): Alıcı adı
  - Alan (satır 161): Kargo firması
  - Alan (satır 162): Takip numarası
  - Alan (satır 165): Tür
  - Alan (satır 173): Saklama yeri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kargo kabul (pencere açar)** (satır 47) | `POST /packages` · package · `services/package/main.go:133` | BOARD_MEMBER/MANAGER/STAFF | packages(+), packages(±) | `package.received` → UnitUsers | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking |
| 2 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 149) | — | | | | |
| 3 | Seçim **Paket — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 163) | — | | | | |
| 4 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 178) | — | | | | |
| 5 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 179) | — | | | | |

### parking_management_screen
- **Dosya:** `admin_app/lib/features/parking/presentation/screens/parking_management_screen.dart`
- **Rota:** `/parking`
- **Ekranda:**
  - Veri (satır 1): `GET /parking-logs` (parking); `GET /vehicles` (parking); `GET /parking-zones` (parking)
  - Başlık (satır 29): Otopark
  - Sekmeler (satır 31): İçeride
  - Sekmeler (satır 31): Araçlar
  - Sekmeler (satır 31): Bölgeler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Giriş (pencere açar)** (satır 33) | `POST /parking-logs/entry` · parking · `services/parking/main.go:145` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(+) | yok | Panel/parking, Yön.mobil parking_management |
| 2 | Düğme **Çıkış** (satır 47) | `POST /parking-logs/:id/exit` · parking · `services/parking/main.go:184` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(±) | yok | Panel/parking, Yön.mobil parking_management |

### patrol_control_screen
- **Dosya:** `admin_app/lib/features/patrol/presentation/screens/patrol_control_screen.dart`
- **Rota:** `/patrol`
- **Ekranda:**
  - Veri (satır 1): `GET /patrols` (patrol); `GET /patrols-summary` (patrol); `GET /patrol-routes` (patrol)
  - Başlık (satır 28): Devriye
  - Sekmeler (satır 30): Turlar
  - Sekmeler (satır 30): Güzergâhlar

### personnel_management_screen
- **Dosya:** `admin_app/lib/features/personnel/presentation/screens/personnel_management_screen.dart`
- **Rota:** `/personnel`
- **Ekranda:**
  - Veri (satır 1): `GET /employees` (personnel); `GET /leaves` (personnel)
  - Başlık (satır 49): Personel
  - Sekmeler (satır 51): Personel
  - Sekmeler (satır 51): İzinler
  - Pencere (satır 125): Yeni personel
  - Alan (satır 131): Ad
  - Alan (satır 133): Soyad
  - Alan (satır 135): Görev
  - Alan (satır 139): Sözleşme türü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Personel (pencere açar)** (satır 54) | `POST /employees` · personnel · `services/personnel/main.go:81` | BOARD_MEMBER/MANAGER | employees(+) | yok | Panel/personnel, Yön.mobil personnel_management |
| 2 | Seçim **Sözleşme türü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 137) | — | | | | |
| 3 | Düğme **İşe giriş — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 4 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 158) | — | | | | |
| 5 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |

### reports_screen
- **Dosya:** `admin_app/lib/features/reports/presentation/screens/reports_screen.dart`
- **Rota:** `/reports`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/reports/debtors` (finance); `GET /finance/reports/debtors` (finance); `GET /finance/reports/collections` (finance); `GET /finance/reports/collections` (finance)
  - Başlık (satır 37): Raporlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **PDF** (satır 45) | `GET /finance/reports/debtors` · finance · `services/finance/main.go:122` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 2 | Düğme **Excel** (satır 46) | `GET /finance/reports/debtors` · finance · `services/finance/main.go:122` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 3 | Düğme **PDF** (satır 51) | `GET /finance/reports/collections` · finance · `services/finance/main.go:124` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 4 | Düğme **Excel** (satır 52) | `GET /finance/reports/collections` · finance · `services/finance/main.go:124` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |

### request_detail_screen
- **Dosya:** `admin_app/lib/features/requests/presentation/screens/request_detail_screen.dart`
- **Rota:** `:id`
- **Ekranda:**
  - Veri (satır 1): `GET /requests` (community)
  - Başlık (satır 40): Talep Detayı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **IN_PROGRESS / İşleme al / Çözüldü olarak işaretle** (satır 69) | `PATCH /requests/:id/status` · community · `services/community/main.go:85` | oturum açmış herkes (site kapsamı) | requests(±) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |

### requests_screen
- **Dosya:** `admin_app/lib/features/requests/presentation/screens/requests_screen.dart`
- **Rota:** `/requests`
- **Ekranda:**
  - Veri (satır 1): `GET /requests` (community)
  - Başlık (satır 91): Talepler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **?** (satır 94) | `GET /requests` · community · `services/community/main.go:81` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **${ticket.isEmpty ?  (gider: /requests/$id) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |

### reservation_management_screen
- **Dosya:** `admin_app/lib/features/reservations/presentation/screens/reservation_management_screen.dart`
- **Rota:** `/reservations`
- **Ekranda:**
  - Veri (satır 1): `GET /reservations` (reservation)
  - Başlık (satır 54): Rezervasyonlar

### add_resident_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/add_resident_screen.dart`
- **Rota:** `add`
- **Ekranda:**
  - Veri (satır 1): `GET /units` (identity)
  - Mesaj (satır 52): Birimler yüklenemedi, lütfen tekrar deneyin
  - Başlık (satır 60): Yeni Sakin Ekle
  - Alan (satır 70): Daire Seçin *
  - Alan (satır 85): Ad *
  - Alan (satır 92): Soyad *
  - Alan (satır 99): Telefon *
  - Alan (satır 99): +90 5XX XXX XX XX
  - Alan (satır 107): E-posta
  - Alan (satır 113): Oturum Tipi
  - Pencere (satır 156): Davet gönderildi
  - Mesaj (satır 178): Sakin eklenemedi: ${errorText(e)}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 68) | — | | | | |
| 2 | Seçim **Oturum Tipi — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 112) | — | | | | |
| 3 | Düğme **Kaydet (pencere açar)** (satır 122) | `POST /residents` · identity · `services/identity/main.go:131` | oturum açmış herkes (site kapsamı) | resident_invitations(+), resident_units(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management, Yön.mobil visitor_management |
| 4 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |

### resident_detail_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/resident_detail_screen.dart`
- **Rota:** `:id`
- **Ekranda:**
  - Veri (satır 1): `GET /residents/:id` (identity)
  - Mesaj (satır 46): Sakin bilgileri yüklenemedi: ${errorText(e)}
  - Mesaj (satır 61): Kod üretilemedi: ${errorText(e)}
  - Mesaj (satır 80): İşlem gerçekleştirilemedi, lütfen tekrar deneyin
  - Başlık (satır 99): Sakin Detayı

### residents_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/residents_screen.dart`
- **Rota:** `/residents`
- **Ekranda:**
  - Veri (satır 1): `GET /residents` (identity)
  - Mesaj (satır 47): Sakinler yüklenemedi, lütfen tekrar deneyin
  - Başlık (satır 57): Sakinler
  - Alan (satır 76): Sakin ara...

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? (pencere açar)** (satır 60) | `GET /residents` · identity · `services/identity/main.go:130` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **?** (satır 79) | `GET /residents` · identity · `services/identity/main.go:130` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 3 | Düğme **? (gider: /residents/${resident[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 121) | — | | | | |
| 4 | Düğme **Sakin Ekle (gider: /residents/add)** (satır 131) | `GET /residents` · identity · `services/identity/main.go:130` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 5 | Düğme **Uygula** (satır 168) | `GET /residents` · identity · `services/identity/main.go:130` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 6 | Düğme **${resident[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 225) | — | | | | |

### activation_code_dialog
- **Dosya:** `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`
- **Ekranda:**
  - Pencere (satır 23): $who için kod:
  - Mesaj (satır 45): Kod kopyalandı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kod kopyalandı — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 39) | — | | | | |
| 2 | Düğme **Kodu ilettim, kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 61) | — | | | | |

### api_settings_screen
- **Dosya:** `admin_app/lib/features/settings/presentation/screens/api_settings_screen.dart`
- **Rota:** `/api-settings`
- **Ekranda:**
  - Başlık (satır 16): API Anahtarları

### survey_management_screen
- **Dosya:** `admin_app/lib/features/surveys/presentation/screens/survey_management_screen.dart`
- **Rota:** `/surveys`
- **Ekranda:**
  - Veri (satır 1): `GET /surveys` (survey); `GET /surveys/:id` (survey)
  - Başlık (satır 73): Anketler
  - Alan (satır 259): Tür
  - Alan (satır 265): Başlık *
  - Alan (satır 268): Açıklama
  - Alan (satır 275): Seçenek ${i + 1} *

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Anket (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 75) | — | | | | |
| 2 | Düğme **${s[ (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 96) | — | | | | |
| 3 | Düğme **İptal et (pencere açar)** (satır 169) | `POST /surveys/:id/cancel` · survey · `services/survey/main.go:218` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil survey_management |
| 4 | Düğme **Oylamayı bitir (pencere açar)** (satır 177) | `POST /surveys/:id/close` · survey · `services/survey/main.go:209` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil survey_management |
| 5 | Düğme **Yayınla (pencere açar)** (satır 184) | `POST /surveys/:id/publish` · survey · `services/survey/main.go:195` | BOARD_MEMBER/MANAGER | surveys(±) | `survey.published` → Residents | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil survey_management |
| 6 | Seçim **Tür — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 257) | — | | | | |
| 7 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 280) | — | | | | |
| 8 | Düğme **Seçenek ekle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 287) | — | | | | |
| 9 | Düğme **Bitiş tarihi — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 307) | — | | | | |
| 10 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 311) | — | | | | |
| 11 | Düğme **Taslak olarak kaydet** (satır 319) | `POST /surveys` · survey · `services/survey/main.go:168` | BOARD_MEMBER/MANAGER | survey_options(+), surveys(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil survey_management |

### visitor_management_screen
- **Dosya:** `admin_app/lib/features/visitors/presentation/screens/visitor_management_screen.dart`
- **Rota:** `/visitors`
- **Ekranda:**
  - Veri (satır 1): `GET /visitors` (visitor); `GET /visitors/summary` (visitor); `GET /units` (identity)
  - Başlık (satır 49): Ziyaretçiler
  - Pencere (satır 134): Geçiş koduyla giriş
  - Alan (satır 140): 6 haneli PIN ya da QR kodu
  - Pencere (satır 173): Ziyaretçi kaydı
  - Alan (satır 179): Ad soyad
  - Alan (satır 183): Daire
  - Alan (satır 191): Telefon
  - Alan (satır 192): Plaka
  - Alan (satır 193): Ziyaret nedeni

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Geçiş koduyla giriş (pencere açar)** (satır 50) | `POST /visitors/verify-pass` · visitor · `services/visitor/main.go:174` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
| 2 | Düğme **Kayıt (pencere açar)** (satır 57) | `POST /visitors` · visitor · `services/visitor/main.go:100` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(+), visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 4 | Düğme **Doğrula — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 144) | — | | | | |
| 5 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 181) | — | | | | |
| 6 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 198) | — | | | | |
| 7 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 199) | — | | | | |
