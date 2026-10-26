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

### forms
- **Dosya:** `admin_app/lib/core/widgets/forms.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /units` (identity)
  - Dosya seçme (satır 9)
  - Dosya seçme (satır 9)
  - Dosya seçme (satır 139)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 184) | — | | | | |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 208) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 250) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 270) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 341) | — | | | | |

### signature_pad
- **Dosya:** `admin_app/lib/core/widgets/signature_pad.dart`
- **Ekranda:**
  - Pencere (satır 98): Temizle

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Temizle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 102) | — | | | | |
| 2 | Düğme **İmzasız teslim — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 3 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 104) | — | | | | |

### account_screen
- **Dosya:** `admin_app/lib/features/account/presentation/screens/account_screen.dart`
- **Rota:** `/account`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity)
  - Mesaj (satır 39): Site değiştirildi
  - Başlık (satır 50): Hesabım

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Şifre değiştir (gider: /login; pencere açar)** (satır 52) | `POST /users/me/password` · identity · `services/identity/main.go:102` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 2 | Düğme **Telefon numarası değiştir** (satır 53) | `POST /users/me/phone/request` · identity · `services/identity/main.go:104` | oturum açmış herkes (site kapsamı) | phone_change_requests(+), phone_change_requests(±) | `identity.phone_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/phone/confirm` · identity · `services/identity/main.go:105` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), phone_change_requests(±), users(±) | `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 3 | Düğme **E-posta değiştir** (satır 59) | `POST /users/me/email` · identity · `services/identity/main.go:106` | oturum açmış herkes (site kapsamı) | email_change_requests(+), email_change_requests(±) | `identity.email_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/email/confirm` · identity · `services/identity/main.go:107` | oturum açmış herkes (site kapsamı) | email_change_requests(±), users(±) | `identity.email_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 4 | Düğme **Çıkış yap (gider: /login; pencere açar)** (satır 65) | `POST /auth/logout` · identity · `services/identity/main.go:87` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 5 | Düğme **Yeni site (gider: /, /; pencere açar)** (satır 69) | `POST /users/me/properties` · identity · `services/identity/main.go:97` | MANAGER/OWNER | properties(+), property_roles(+) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/roles, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil roles, Yön.mobil site_settings, Yön.mobil units |
|  | ↳ | `POST /users/me/active-property` · identity · `services/identity/main.go:98` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 6 | Düğme **${p[ (gider: /, /)** (satır 99) | `POST /users/me/active-property` · identity · `services/identity/main.go:98` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |

### announcements_screen
- **Dosya:** `admin_app/lib/features/announcements/presentation/screens/announcements_screen.dart`
- **Rota:** `/announcements`
- **Ekranda:**
  - Veri (satır 1): `GET /announcements` (community); `GET /announcements/:id/read-stats` (community)
  - Mesaj (satır 88): İşlem yapılamadı: ${toUserMessage(e)}
  - Pencere (satır 103): Okunma durumu
  - Başlık (satır 117): Duyurular

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 106) | — | | | | |
| 2 | Düğme **?** (satır 120) | `GET /announcements` · community · `services/community/main.go:101` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |
| 3 | Düğme **Duyuru Yayınla (gider: /announcements/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 127) | — | | | | |
| 4 | Düğme **Menü: Sabitlemeyi kaldır / Sabitle** (satır 200) | `POST /announcements/:id/pin` · community · `services/community/main.go:173` | BOARD_MEMBER/MANAGER | announcements(±) | yok | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |
| 5 | Düğme **Menü: Okunma durumu** (satır 206) | `POST /announcements/:id/pin` · community · `services/community/main.go:173` | BOARD_MEMBER/MANAGER | announcements(±) | yok | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |

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
  - Veri (satır 1): `GET /asset-categories` (asset); `GET /assets` (asset); `GET /assets-summary` (asset); `GET /assets/:id/maintenance` (asset); `GET /assets/:id` (asset)
  - Başlık (satır 80): Demirbaşlar
  - Başlık (satır 152): ${a[

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kategori ekle** (satır 84) | `POST /asset-categories` · asset · `services/asset/main.go:183` | BOARD_MEMBER/MANAGER | asset_categories(+) | yok | Panel/assets, Yön.mobil asset_management |
| 2 | Düğme **Demirbaş** (satır 87) | `POST /assets` · asset · `services/asset/main.go:202` | BOARD_MEMBER/MANAGER | assets(+) | yok | Panel/assets, Yön.mobil asset_management |
| 3 | Düğme **${a[ (gider: _AssetDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 107) | — | | | | |

### audit_screen
- **Dosya:** `admin_app/lib/features/audit/presentation/screens/audit_screen.dart`
- **Rota:** `/audit`
- **Ekranda:**
  - Veri (satır 1): `GET /audit-logs` (settings); `GET /audit-logs/stats` (settings)
  - Başlık (satır 79): İşlem Kayıtları
  - Başlık (satır 88): Kayıt istatistiği
  - Alan (satır 114): İşlem
  - Alan (satır 126): Kaynak

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Ara (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 82) | — | | | | |
| 2 | Düğme **Kayıt istatistiği (gider: Scaffold)** (satır 83) | `GET /audit-logs/stats` · settings · `services/settings/activity.go:154` | AUDITOR/MANAGER | — | yok | — |
| 3 | Seçim **Tümü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 112) | — | | | | |
| 4 | Seçim **Tümü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 124) | — | | | | |
| 5 | Düğme **${_actions[r[ (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 148) | — | | | | |

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
| 1 | Düğme **Yeniden gönder (${_cooldown}s) / Kodu SMS ile gönder** (satır 165) | `POST /auth/password-reset/request` · identity · `services/identity/main.go:83` | oturum açmış herkes (site kapsamı) | user_activation_codes(+), user_activation_codes(±) | `identity.self_reset` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 2 | Düğme **Şifremi Belirle (gider: /login)** (satır 196) | `POST /auth/activate` · identity · `services/identity/main.go:81` | serviste rol karşılaştırması: OWNER/TENANT | resident_units(+), user_token_invalidation(+), resident_invitations(±), user_activation_codes(±), users(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### kvkk_consent_screen
- **Dosya:** `admin_app/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`
- **Rota:** `/kvkk-consent`
- **Ekranda:**
  - Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
  - Başlık (satır 40): Kişisel Verilerin Korunması

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onaylıyorum ve Devam Ediyorum (gider: /)** (satır 84) | `POST /users/me/kvkk-consent` · identity · `services/identity/main.go:99` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |

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
| 4 | Düğme **Giriş Yap (gider: /kvkk-consent, /; pencere açar)** (satır 261) | `POST /auth/login` · identity · `services/identity/main.go:78` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
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
  - Sekmeler (satır 189): Onay bekleyen
  - Sekmeler (satır 189): Yayında
  - Sekmeler (satır 189): Tümü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gizle (pencere açar)** (satır 104) | `DELETE /bulletin-comments/:id` · bulletin · `services/bulletin/main.go:154` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_comments(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 2 | Düğme **${b[ (pencere açar)** (satır 149) | `DELETE /bulletin-comments/:id` · bulletin · `services/bulletin/main.go:154` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_comments(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 3 | Düğme **Reddet (pencere açar)** (satır 155) | `POST /bulletins/:id/reject` · bulletin · `services/bulletin/main.go:183` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 4 | Düğme **Onayla** (satır 156) | `POST /bulletins/:id/approve` · bulletin · `services/bulletin/main.go:170` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 5 | Düğme **Kapat (pencere açar)** (satır 158) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 6 | Düğme **Süresi dolanları kapat (pencere açar)** (satır 174) | `POST /bulletins/expire-due` · bulletin · `services/bulletin/main.go:205` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |

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
  - Sekmeler (satır 148): Yürürlükte
  - Sekmeler (satır 148): 60 günde bitenler
  - Sekmeler (satır 148): Tümü
  - Mesaj (satır 245): Bitiş tarihi başlangıçtan önce olamaz
  - Alan (satır 286): Tür
  - Alan (satır 292): Başlık *
  - Alan (satır 297): Karşı taraf (firma / kişi) *
  - Alan (satır 321): Ödeme
  - Alan (satır 332): Tutar (₺)
  - Alan (satır 338): Yenileme süresi (ay)
  - Alan (satır 344): İhbar süresi (gün)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Feshet (pencere açar)** (satır 115) | `POST /contracts/:id/terminate` · contract · `services/contract/main.go:151` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 2 | Düğme **Yenile (pencere açar)** (satır 117) | `POST /contracts/:id/renew` · contract · `services/contract/main.go:138` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 3 | Düğme **Süresi dolanları kapat (pencere açar)** (satır 133) | `POST /contracts/expire-due` · contract · `services/contract/main.go:172` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 4 | Düğme **Sözleşme (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 151) | — | | | | |
| 5 | Seçim **Tür — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 284) | — | | | | |
| 6 | Düğme **Başlangıç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 300) | — | | | | |
| 7 | Düğme **Bitiş — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 309) | — | | | | |
| 8 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 313) | — | | | | |
| 9 | Seçim **Aylık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 319) | — | | | | |
| 10 | Düğme **Kaydet** (satır 348) | `POST /contracts` · contract · `services/contract/main.go:117` | BOARD_MEMBER/MANAGER | contracts(+) | yok | Panel/contracts, Yön.mobil contract_management |

### dashboard_screen
- **Dosya:** `admin_app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Rota:** `/`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/payments` (finance); `GET /dashboard/stats` (gateway)
  - Başlık (satır 108): Dashboard

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **?** (satır 111) | `GET /finance/payments` · finance · `services/finance/main.go:117` | AUDITOR/BOARD_MEMBER/MANAGER; `assessment_visible_to` | — | yok | — |
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

### documents_screen
- **Dosya:** `admin_app/lib/features/documents/presentation/screens/documents_screen.dart`
- **Rota:** `/documents`
- **Ekranda:**
  - Veri (satır 1): `GET /documents` (document); `GET /documents-summary` (document); `GET /documents/:id/download` (document); `GET /documents/:id/access-log` (document)
  - Başlık (satır 71): Belge arşivi
  - Başlık (satır 110): Erişim — ${x[

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yükle (pencere açar)** (satır 80) | `POST /documents` · document · `services/document/main.go:171` | BOARD_MEMBER/MANAGER | documents(+) · tetikleyici: documents_supersede · dosya deposu | yok | Panel/documents, Sakin documents, Yön.mobil documents |

### emergency_screen
- **Dosya:** `admin_app/lib/features/emergency/presentation/screens/emergency_screen.dart`
- **Rota:** `/emergency`
- **Ekranda:**
  - Veri (satır 1): `GET /emergency/cards` (community); `GET /emergency/checks` (community); `GET /emergency/info` (community); `GET /emergency/drills` (community); `GET /emergency/checks/:id/responses` (community)
  - Mesaj (satır 66): Çağrı açıldı. ${(r[
  - Başlık (satır 87): Sakin acil bilgi kartları
  - Başlık (satır 110): Acil durum ve afet
  - Sekmeler (satır 113): Durum bildirimi
  - Sekmeler (satır 113): Noktalar
  - Sekmeler (satır 113): İletişim
  - Sekmeler (satır 113): Tatbikatlar
  - Başlık (satır 254): Durum yanıtları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 52) | — | | | | |
| 2 | Düğme **Acil bilgi kartları (kayda geçer) (gider: Scaffold)** (satır 112) | `GET /emergency/cards` · community · `services/community/emergency.go:250` | BOARD_MEMBER/MANAGER | — | yok | — |
| 3 | Düğme **${s[ (gider: _Responses, _Responses) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 127) | — | | | | |
| 4 | Düğme **?** (satır 159) | `DELETE /emergency/points/:id` · community · `services/community/emergency.go:91` | BOARD_MEMBER/MANAGER | — | yok |  |
| 5 | Düğme **Ulusal acil: ${d[ (dış bağlantı/arama) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 189) | — | | | | |
| 6 | Düğme **${c[ (dış bağlantı/arama) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 195) | — | | | | |
| 7 | Düğme **?** (satır 200) | `DELETE /emergency/contacts/:id` · community · `services/community/emergency.go:117` | BOARD_MEMBER/MANAGER | — | yok |  |
| 8 | Düğme **Çağrıyı kapat** (satır 277) | `POST /emergency/checks/:id/close` · community · `services/community/emergency.go:383` | BOARD_MEMBER/MANAGER | safety_checks(±) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |

### energy_dashboard_screen
- **Dosya:** `admin_app/lib/features/energy/presentation/screens/energy_dashboard_screen.dart`
- **Rota:** `/energy`
- **Ekranda:**
  - Veri (satır 1): `GET /energy/trends` (energy_analytics); `GET /energy/anomalies` (energy_analytics)
  - Başlık (satır 51): Tüketim Analizi
  - Sekmeler (satır 53): Eğilim
  - Sekmeler (satır 53): Olağandışı

### esg_screen
- **Dosya:** `admin_app/lib/features/esg/presentation/screens/esg_screen.dart`
- **Rota:** `/esg`
- **Ekranda:**
  - Veri (satır 1): `GET /esg/consumption` (esg)
  - Başlık (satır 52): Karbon ayak izi

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Başlangıç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 61) | — | | | | |
| 2 | Düğme **Bitiş — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 62) | — | | | | |
| 3 | Düğme **Hesapla (pencere açar)** (satır 75) | `POST /esg/carbon-footprint` · esg · `services/esg/main.go:97` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |  |

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
  - Veri (satır 1): `GET /expenses` (expense); `GET /expenses/summary` (expense)
  - Başlık (satır 92): Gider Yönetimi
  - Başlık (satır 100): ${DateTime.now().year} gider özeti

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${DateTime.now().year} gider özeti (gider: Scaffold)** (satır 95) | `GET /expenses/summary` · expense · `services/expense/main.go:63` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 2 | Düğme **${_monthName(_month)} $_year (pencere açar)** (satır 126) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 3 | Düğme **Tümü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 158) | — | | | | |
| 4 | Düğme **Aidata Yansıyan — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 162) | — | | | | |
| 5 | Düğme **Faturasız — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 166) | — | | | | |
| 6 | Düğme **Onay Bekleyen — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 170) | — | | | | |
| 7 | Düğme **Gider Ekle (gider: /expenses/add)** (satır 181) | `GET /expenses` · expense · `services/expense/main.go:62` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 8 | Düğme **? (gider: /expenses/$id) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 268) | — | | | | |
| 9 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 308) | — | | | | |
| 10 | Düğme **Faturasız — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 437) | — | | | | |

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
  - Başlık (satır 103): (dinamik)
  - Alan (satır 117): Daire
  - Alan (satır 162): Açıklama / makbuz no

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${u[** (satır 115) | `GET /finance/units/:id/open-assessments` · finance · `services/finance/main.go:126` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 2 | Düğme **Ödeme günü — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 152) | — | | | | |
| 3 | Düğme **Kaydediliyor… / Kaydet ve borçtan düş** (satır 166) | `POST /finance/bank-statements/lines/:id/collect` · finance · `services/finance/main.go:156` | BOARD_MEMBER/MANAGER; `assessment_visible_to` | finance_ledger(+), late_fee_accruals(+), payment_assessments(+), payments(+), bank_statement_lines(±), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `payment.recorded` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
|  | ↳ | `POST /finance/collections` · finance · `services/finance/main.go:155` | BOARD_MEMBER/MANAGER; `assessment_visible_to` | finance_ledger(+), late_fee_accruals(+), payment_assessments(+), payments(+), bank_statement_lines(±), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `payment.recorded` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |

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
| 5 | Düğme **Tahakkuk Oluştur** (satır 272) | `POST /finance/assessments` · finance · `services/finance/main.go:135` | BOARD_MEMBER/MANAGER | assessment_details(+), monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 6 | Seçim **name / category_name / — — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 392) | — | | | | |
| 7 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 426) | — | | | | |

### finance_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/finance_screen.dart`
- **Rota:** `/finance`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/assessments/:id` (finance); `GET /finance/debtors` (finance)
  - Başlık (satır 40): Finans
  - Sekmeler (satır 50): Dönemler
  - Sekmeler (satır 50): Borçlular
  - Sekmeler (satır 50): Devir bakiyeleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gecikme tazminatı işlet** (satır 43) | `POST /finance/late-fees/accrue` · finance · `services/finance/main.go:143` | BOARD_MEMBER/MANAGER | late_fee_accruals(+), late_fee_accruals(±), monthly_assessments(±) · tetikleyici: late_fee_accruals_active_property, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 2 | Düğme **Ödemeler (gider: /finance/payments) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 44) | — | | | | |
| 3 | Düğme **Tahakkuk (gider: /finance/assessments/create) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 53) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 62) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 64) | — | | | | |

### finance_tools_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/finance_tools_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/ledger/verify` (finance); `GET /finance/ledger` (finance); `GET /finance/units/:id/open-assessments` (finance); `GET /finance/credit-notes` (finance); `GET /finance/credit-notes/:id/pdf` (finance); `GET /finance/bank-statements` (finance); `GET /finance/payments/pending` (finance); `GET /finance/bank-statements/:id` (finance); `GET /units` (identity); `GET /finance/opening-balances` (finance)
  - Başlık (satır 27): Tahsilat defteri
  - Mesaj (satır 96): Borcu kalan tahakkuk yok
  - Başlık (satır 118): Alacak dekontları
  - Başlık (satır 187): Banka ekstresi
  - Başlık (satır 237): Hareketler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Zinciri doğrula** (satır 28) | `GET /finance/ledger/verify` · finance · `services/finance/main.go:100` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **Dekont kes (pencere açar)** (satır 119) | `POST /finance/credit-notes` · finance · `services/finance/main.go:148` | BOARD_MEMBER/MANAGER | credit_notes(+), finance_ledger(+), monthly_assessments(±) · tetikleyici: credit_notes_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 3 | Düğme **Yükle (pencere açar)** (satır 188) | `POST /finance/bank-statements` · finance · `services/finance/main.go:150` | BOARD_MEMBER/MANAGER | bank_statement_imports(+), bank_statement_lines(+) | yok | Panel/accounting, Yön.mobil finance_tools |
| 4 | Düğme **${x[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 193) | — | | | | |
| 5 | Düğme **Devir gir (pencere açar)** (satır 352) | `POST /finance/credit-notes` · finance · `services/finance/main.go:148` | BOARD_MEMBER/MANAGER | credit_notes(+), finance_ledger(+), monthly_assessments(±) · tetikleyici: credit_notes_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |

### payments_screen
- **Dosya:** `admin_app/lib/features/finance/presentation/screens/payments_screen.dart`
- **Rota:** `payments`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/payments/:id/receipts` (finance); `GET /finance/payments/:id/receipts/:receiptId/download` (finance); `GET /finance/payments/pending` (finance); `GET /finance/payments` (finance)
  - Başlık (satır 94): Dekontlar — ${p[
  - Başlık (satır 150): Ödemeler
  - Sekmeler (satır 159): Onay bekleyen
  - Sekmeler (satır 159): Tümü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${r[** (satır 98) | `GET /finance/payments/:id/receipts/:receiptId/download` · finance · `services/finance/main.go:99` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | — · dosya deposu | yok | — |
| 2 | Düğme **${p[ (gider: Scaffold, Scaffold)** (satır 132) | `GET /finance/payments/:id/receipts` · finance · `services/finance/main.go:98` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | — | yok | — |
|  | ↳ | `GET /finance/payments/:id/receipts/:receiptId/download` · finance · `services/finance/main.go:99` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | — · dosya deposu | yok | — |
| 3 | Düğme **Ters kayıt** (satır 133) | `POST /finance/payments/:id/reverse` · finance · `services/finance/main.go:139` | BOARD_MEMBER/MANAGER | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 4 | Düğme **Reddet (pencere açar)** (satır 135) | `POST /finance/payments/:id/reject` · finance · `services/finance/main.go:140` | BOARD_MEMBER/MANAGER | payments(±) · tetikleyici: payments_guard | yok | Panel/accounting, Sakin dues_payment, Sakin payment_history, Yön.mobil dashboard, Yön.mobil finance_tools, Yön.mobil payments |
| 5 | Düğme **Onayla (pencere açar)** (satır 137) | `POST /finance/payments/:id/confirm` · finance · `services/finance/main.go:138` | BOARD_MEMBER/MANAGER | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 6 | Düğme **Tahsilat gir (gider: CollectionEntryScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 162) | — | | | | |

### governance_screen
- **Dosya:** `admin_app/lib/features/governance/presentation/screens/governance_screen.dart`
- **Rota:** `/governance`
- **Ekranda:**
  - Veri (satır 1): `GET /governance/assemblies` (governance); `GET /governance/assemblies/:id` (governance); `GET /governance/budgets` (governance); `GET /governance/budgets/:id/export` (governance); `GET /governance/budgets/:id/export` (governance); `GET /governance/budgets/:id` (governance); `GET /governance/budgets/:id/objections` (governance); `GET /units` (identity); `GET /residents` (identity); `GET /governance/assemblies/:id` (governance); `GET /governance/assemblies/:id/attendees` (governance); `GET /governance/assemblies/:id/quorum` (governance); `GET /governance/assemblies/:id/attendance-sheet` (governance); `GET /governance/assemblies/:id/attendance-sheet` (governance); `GET /governance/books/:id/entries` (governance); `GET /governance/books/:id/verify` (governance); `GET /governance/books/:id/export` (governance); `GET /governance/legal-cases` (governance); `GET /governance/common-area/leases` (governance); `GET /governance/common-area/report` (governance)
  - Başlık (satır 88): Yönetişim (KMK)
  - Sekmeler (satır 91): İşletme projesi
  - Sekmeler (satır 91): Genel kurul
  - Sekmeler (satır 91): Defterler
  - Sekmeler (satır 91): İcra ve dava
  - Sekmeler (satır 91): Ortak alan
  - Mesaj (satır 192): En az bir kalem ekleyin
  - Mesaj (satır 203): ${r[
  - Başlık (satır 223): İşletme projesi hazırla
  - Alan (satır 232): Not
  - Başlık (satır 311): İşletme projesi
  - Sekmeler (satır 319): Özet
  - Sekmeler (satır 319): Daire payları
  - Sekmeler (satır 319): İtirazlar
  - Mesaj (satır 475): Toplantı bilgisi ve en az bir gündem maddesi gerekli
  - Mesaj (satır 486): Toplantı planlandı
  - Başlık (satır 500): Toplantı planla
  - Pencere (satır 572): ${r[
  - Başlık (satır 588): Genel kurul

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 111) | — | | | | |
| 2 | Düğme **${b[ (gider: _BudgetDetail, _BudgetDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 148) | — | | | | |
| 3 | Düğme **Taslak kaydet** (satır 224) | `POST /governance/budgets` · governance · `services/governance/main.go:89` | BOARD_MEMBER/MANAGER | operating_budget_items(+), operating_budget_unit_shares(+), operating_budgets(+) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 228) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 230) | — | | | | |
| 6 | Düğme **${_items[i][ (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 236) | — | | | | |
| 7 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 240) | — | | | | |
| 8 | Düğme **Kalem (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 242) | — | | | | |
| 9 | Düğme **Geçici proje olarak bildir** (satır 342) | `POST /governance/budgets/:id/notify` · governance · `services/governance/main.go:90` | BOARD_MEMBER/MANAGER | operating_budgets(±) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 10 | Düğme **Genel kurul kararıyla kesinleştir** (satır 343) | `POST /governance/budgets/:id/finalize` · governance · `services/governance/main.go:91` | BOARD_MEMBER/MANAGER | operating_budgets(±) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 11 | Düğme **Aylık aidat tahakkuk et** (satır 344) | `POST /governance/budgets/:id/assessments` · governance · `services/governance/main.go:92` | BOARD_MEMBER/MANAGER | monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 12 | Düğme **${formatDateTime(a[ (gider: _BudgetDetail, _BudgetDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 427) | — | | | | |
| 13 | Düğme **Kaydet** (satır 501) | `POST /governance/budgets` · governance · `services/governance/main.go:89` | BOARD_MEMBER/MANAGER | operating_budget_items(+), operating_budget_unit_shares(+), operating_budgets(+) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 14 | Düğme **Toplantı bilgisi / ${h[ / ] ==  /  ?  /  :  / } · ${h[ / ]}. toplantı (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 503) | — | | | | |
| 15 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 515) | — | | | | |
| 16 | Düğme **Madde (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 517) | — | | | | |
| 17 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 576) | — | | | | |
| 18 | Düğme **Çağrıyı kaydet** (satır 619) | `POST /governance/assemblies/:id/notify` · governance · `services/governance/main.go:96` | BOARD_MEMBER/MANAGER | assemblies(±) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/reports, Yön.mobil governance |
| 19 | Düğme **Hazirune ekle** (satır 629) | `POST /governance/assemblies/:id/attendees` · governance · `services/governance/main.go:97` | BOARD_MEMBER/MANAGER | assembly_attendees(+) | yok | Panel/governance/assemblies, Panel/reports, Yön.mobil governance |
| 20 | Düğme **Toplantıyı yap** (satır 631) | `POST /governance/assemblies/:id/hold` · governance · `services/governance/main.go:98` | BOARD_MEMBER/MANAGER | assemblies(±) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/reports, Yön.mobil governance |
| 21 | Düğme **Cetvel PDF** (satır 659) | `GET /governance/assemblies/:id/attendance-sheet` · governance · `services/governance/main.go:74` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 22 | Düğme **Excel** (satır 660) | `GET /governance/assemblies/:id/attendance-sheet` · governance · `services/governance/main.go:74` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 23 | Seçim **Karar defteri — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 711) | — | | | | |
| 24 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 717) | — | | | | |
| 25 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 719) | — | | | | |
| 26 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 895) | — | | | | |
| 27 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 897) | — | | | | |

### insurance_screen
- **Dosya:** `admin_app/lib/features/insurance/presentation/screens/insurance_screen.dart`
- **Rota:** `/insurance`
- **Ekranda:**
  - Veri (satır 1): `GET /insurance/dask` (contract); `GET /insurance/claims` (contract)
  - Başlık (satır 39): Sigorta
  - Sekmeler (satır 39): DASK
  - Sekmeler (satır 39): Hasar kayıtları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Poliçe gir** (satır 62) | `POST /insurance/dask` · contract · `services/contract/main.go:71` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | unit_insurance_policies(+) | yok | Panel/insurance, Sakin dask, Yön.mobil insurance |
| 2 | Düğme **Hasar kaydet** (satır 94) | `POST /insurance/claims` · contract · `services/contract/main.go:114` | BOARD_MEMBER/MANAGER | insurance_claims(+) | yok | Panel/insurance, Yön.mobil insurance |
| 3 | Düğme **İlerlet** (satır 121) | `POST /insurance/claims/:id/status` · contract · `services/contract/main.go:115` | BOARD_MEMBER/MANAGER | insurance_claims(±) | yok | Panel/insurance, Yön.mobil insurance |

### inventory_management_screen
- **Dosya:** `admin_app/lib/features/inventory/presentation/screens/inventory_management_screen.dart`
- **Rota:** `/inventory`
- **Ekranda:**
  - Veri (satır 1): `GET /inventory-categories` (inventory); `GET /inventory-movements` (inventory); `GET /inventory` (inventory); `GET /inventory-summary` (inventory); `GET /inventory/:id/movements` (inventory)
  - Pencere (satır 67): ${item[
  - Alan (satır 74): Hareket
  - Alan (satır 85): Miktar (${item[
  - Başlık (satır 121): Stok
  - Başlık (satır 189): (dinamik)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **Giriş (alım) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 72) | — | | | | |
| 2 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 96) | — | | | | |
| 3 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 97) | — | | | | |
| 4 | Düğme **Son hareketler (gider: _Movements)** (satır 125) | `GET /inventory-movements` · inventory · `services/inventory/main.go:115` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 5 | Düğme **Kategori ekle** (satır 130) | `POST /inventory-categories` · inventory · `services/inventory/main.go:179` | BOARD_MEMBER/MANAGER | inventory_categories(+) | yok | Panel/inventory, Yön.mobil inventory_management |
| 6 | Düğme **Kalem** (satır 133) | `POST /inventory` · inventory · `services/inventory/main.go:197` | BOARD_MEMBER/MANAGER | inventory_items(+) | yok | Panel/inventory, Yön.mobil inventory_management |

### kvkk_requests_screen
- **Dosya:** `admin_app/lib/features/kvkk/presentation/screens/kvkk_requests_screen.dart`
- **Rota:** `/kvkk`
- **Ekranda:**
  - Veri (satır 1): `GET /kvkk-requests` (community)
  - Başlık (satır 37): KVKK başvuruları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yanıtla** (satır 54) | `POST /kvkk-requests/:id/respond` · community · `services/community/kvkk.go:99` | BOARD_MEMBER/MANAGER | kvkk_requests(±) | `kvkk.response` → işlemin muhatabı (k.UserID) | Panel/kvkk, Sakin kvkk_requests, Yön.mobil kvkk_requests |

### main_screen
- **Dosya:** `admin_app/lib/features/main/presentation/screens/main_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /notifications/unread-count` (notification); `GET /users/me/properties` (identity)
  - Pencere (satır 200): Uygulamadan çık

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 204) | — | | | | |
| 2 | Düğme **Çık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 205) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 266) | — | | | | |
| 4 | Düğme **Şifre Değiştir (gider: /login; pencere açar)** (satır 281) | `POST /users/me/password` · identity · `services/identity/main.go:102` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 5 | Düğme **Çıkış Yap (gider: /login; pencere açar)** (satır 289) | `POST /auth/logout` · identity · `services/identity/main.go:87` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 6 | Düğme **Çıkış yap (gider: /login; pencere açar)** (satır 328) | `POST /auth/logout` · identity · `services/identity/main.go:87` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |

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
| 2 | Düğme **Kaydediliyor… / Girilen okumaları kaydet** (satır 97) | `POST /meter-readings` · iot · `services/iot/main.go:161` | BOARD_MEMBER/MANAGER/STAFF | meter_readings(+) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |

### meters_screen
- **Dosya:** `admin_app/lib/features/meters/presentation/screens/meters_screen.dart`
- **Rota:** `/meters`
- **Ekranda:**
  - Veri (satır 1): `GET /meters` (iot); `GET /meter-readings` (iot); `GET /consumption/statements` (iot); `GET /consumption/statements/:id/pdf` (iot); `GET /consumption/objections` (iot); `GET /consumption/area-check` (iot)
  - Başlık (satır 85): Sayaçlar
  - Sekmeler (satır 88): Sayaçlar
  - Sekmeler (satır 88): Okumalar
  - Sekmeler (satır 88): Paylaştır
  - Sekmeler (satır 88): Pusulalar
  - Sekmeler (satır 88): İtirazlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Sayaç ekle** (satır 87) | `POST /meters` · iot · `services/iot/main.go:188` | BOARD_MEMBER/MANAGER | meters(+) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin energy_consumption_mobile, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |
| 2 | Düğme **Okuma gir (gider: /meters/reading) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 90) | — | | | | |
| 3 | Düğme **PDF** (satır 164) | `GET /consumption/statements/:id/pdf` · iot · `services/iot/main.go:469` | `resident_can_use` | — | yok | — |
| 4 | Düğme **Yanıtla** (satır 184) | `POST /consumption/objections/:id/respond` · iot · `services/iot/main.go:473` | BOARD_MEMBER/MANAGER | consumption_statement_objections(±) · tetikleyici: consumption_statement_objections_guard | `statement.objection.answer` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/meters, Sakin energy_consumption_mobile, Yön.mobil meters |
| 5 | Düğme **Hesapla / yayımla (pencere açar)** (satır 273) | `POST /consumption/allocate` · iot · `services/iot/main.go:239` | BOARD_MEMBER/MANAGER | consumption_allocation_units(+), consumption_allocations(+) | yok | Panel/meters, Sakin energy_consumption_mobile, Yön.mobil meters |

### inbox_screen
- **Dosya:** `admin_app/lib/features/notifications/presentation/screens/inbox_screen.dart`
- **Rota:** `/inbox`
- **Ekranda:**
  - Veri (satır 1): `GET /notifications` (notification)
  - Başlık (satır 27): Bildirimlerim

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tümünü okundu say** (satır 30) | `POST /notifications/read-all` · notification · `services/notification/main.go:97` | oturum açmış herkes (site kapsamı) | notification_reads(+) | yok | Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |
| 2 | Düğme **${n[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 62) | — | | | | |

### notification_center_screen
- **Dosya:** `admin_app/lib/features/notifications/presentation/screens/notification_center_screen.dart`
- **Rota:** `/notification-center`
- **Ekranda:**
  - Veri (satır 1): `GET /residents` (identity); `GET /notifications/outbox` (notification); `GET /notifications/summary` (notification); `GET /notification-preferences` (notification)
  - Başlık (satır 53): Bildirim merkezi
  - Sekmeler (satır 55): Giden kutusu
  - Sekmeler (satır 55): Tercihlerim

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gönder** (satır 57) | `POST /notifications` · notification · `services/notification/main.go:158` | BOARD_MEMBER/MANAGER | — | `{{in}.Topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |

### nps_screen
- **Dosya:** `admin_app/lib/features/nps/presentation/screens/nps_screen.dart`
- **Rota:** `/nps`
- **Ekranda:**
  - Veri (satır 1): `GET /nps` (nps); `GET /nps/:id/comments` (nps); `GET /nps/:id` (nps)
  - Başlık (satır 33): Memnuniyet (NPS)
  - Başlık (satır 80): (dinamik)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Ölçüm** (satır 35) | `POST /nps` · nps · `services/nps/main.go:159` | BOARD_MEMBER/MANAGER | survey_options(+), surveys(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 2 | Düğme **${s[ (gider: _NpsDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 52) | — | | | | |

### package_tracking_screen
- **Dosya:** `admin_app/lib/features/packages/presentation/screens/package_tracking_screen.dart`
- **Rota:** `/packages`
- **Ekranda:**
  - Veri (satır 1): `GET /packages-summary` (package); `GET /packages` (package); `GET /packages/:id/proof/:kind` (package); `GET /packages/:id/proof/:kind` (package); `GET /units` (identity)
  - Başlık (satır 37): Kargo
  - Pencere (satır 157): Kargo kabul
  - Alan (satır 165): Daire
  - Alan (satır 173): Alıcı adı
  - Alan (satır 175): Kargo firması
  - Alan (satır 176): Takip numarası
  - Alan (satır 179): Tür
  - Alan (satır 187): Saklama yeri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kargo kabul (pencere açar)** (satır 48) | `POST /packages` · package · `services/package/main.go:133` | BOARD_MEMBER/MANAGER/STAFF | packages(+), packages(±) | `package.received` → UnitUsers | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 2 | Düğme **Menü: Sakine haber verildi (kaydet)** (satır 124) | `POST /packages/:id/deliver` · package · `services/package/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | packages(±) · dosya deposu | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/return` · package · `services/package/main.go:214` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/notify` · package · `services/package/main.go:162` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 3 | Düğme **Menü: Teslim et** (satır 125) | `POST /packages/:id/deliver` · package · `services/package/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | packages(±) · dosya deposu | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/return` · package · `services/package/main.go:214` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/notify` · package · `services/package/main.go:162` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 4 | Düğme **Menü: İade et** (satır 126) | `POST /packages/:id/deliver` · package · `services/package/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | packages(±) · dosya deposu | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/return` · package · `services/package/main.go:214` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/notify` · package · `services/package/main.go:162` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 5 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 163) | — | | | | |
| 6 | Seçim **Paket — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 177) | — | | | | |
| 7 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 192) | — | | | | |
| 8 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 193) | — | | | | |

### parking_management_screen
- **Dosya:** `admin_app/lib/features/parking/presentation/screens/parking_management_screen.dart`
- **Rota:** `/parking`
- **Ekranda:**
  - Veri (satır 1): `GET /parking-logs` (parking); `GET /vehicles` (parking); `GET /parking-zones` (parking); `GET /access-devices` (parking); `GET /vehicles/plate/:plate` (parking); `GET /access-devices/incidents` (parking)
  - Başlık (satır 49): Otopark
  - Sekmeler (satır 52): İçeride
  - Sekmeler (satır 52): Araçlar
  - Sekmeler (satır 52): Bölgeler
  - Sekmeler (satır 52): Cihazlar
  - Pencere (satır 186): ${v[
  - Pencere (satır 234): Cihaz anahtarı
  - Başlık (satır 260): Çevrimdışı olayları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Plaka sorgula (pencere açar)** (satır 51) | `GET /vehicles/plate/:plate` · parking · `services/parking/main.go:106` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 2 | Düğme **Giriş (pencere açar)** (satır 54) | `POST /parking-logs/entry` · parking · `services/parking/main.go:145` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(+) | yok | Panel/parking, Yön.mobil parking_management |
| 3 | Düğme **Çıkış** (satır 68) | `POST /parking-logs/:id/exit` · parking · `services/parking/main.go:184` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(±) | yok | Panel/parking, Yön.mobil parking_management |
| 4 | Düğme **Araç kaydet** (satır 84) | `POST /vehicles` · parking · `services/parking/main.go:71` | `resident_can_use` | vehicles(+) | yok | Panel/parking, Yön.mobil parking_management |
| 5 | Düğme **Cihaz ekle (pencere açar)** (satır 129) | `POST /access-devices` · parking · `services/parking/devices.go:86` | BOARD_MEMBER/MANAGER | access_devices(+) | yok | Panel/parking, Yön.mobil parking_management |
| 6 | Düğme **Çevrimdışı olayları (gider: _Incidents) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 132) | — | | | | |
| 7 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 195) | — | | | | |
| 8 | Düğme **Kopyala — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 242) | — | | | | |
| 9 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 243) | — | | | | |

### checkpoint_setup_screen
- **Dosya:** `admin_app/lib/features/patrol/presentation/screens/checkpoint_setup_screen.dart`
- **Rota:** `/patrol/points`
- **Ekranda:**
  - Veri (satır 1): `GET /patrol-checkpoints` (patrol)
  - Mesaj (satır 25): Konum ölçülüyor…
  - Mesaj (satır 30): Sahte konum algılandı; kaydedilmedi.
  - Pencere (satır 83): Yeni QR değeri
  - Başlık (satır 133): Devriye noktaları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kopyala — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 87) | — | | | | |
| 2 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 88) | — | | | | |
| 3 | Düğme **Tur tanımla** (satır 134) | `POST /patrol-routes` · patrol · `services/patrol/main.go:236` | BOARD_MEMBER/MANAGER | patrol_routes(+) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 4 | Düğme **Nokta** (satır 136) | `POST /patrol-checkpoints` · patrol · `services/patrol/main.go:207` | BOARD_MEMBER/MANAGER | patrol_checkpoints(+) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 5 | Düğme **Menü: Konumu buradan al** (satır 162) | `POST /patrol-checkpoints/:id/location` · patrol · `services/patrol/gps.go:100` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `PATCH /patrol-checkpoints/:id` · patrol · `services/patrol/gps.go:99` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `POST /patrol-checkpoints/:id/rotate-qr` · patrol · `services/patrol/gps.go:101` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 6 | Düğme **Menü: Yarıçap** (satır 163) | `POST /patrol-checkpoints/:id/location` · patrol · `services/patrol/gps.go:100` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `PATCH /patrol-checkpoints/:id` · patrol · `services/patrol/gps.go:99` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `POST /patrol-checkpoints/:id/rotate-qr` · patrol · `services/patrol/gps.go:101` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 7 | Düğme **Menü: QR yenile** (satır 164) | `POST /patrol-checkpoints/:id/location` · patrol · `services/patrol/gps.go:100` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `PATCH /patrol-checkpoints/:id` · patrol · `services/patrol/gps.go:99` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `POST /patrol-checkpoints/:id/rotate-qr` · patrol · `services/patrol/gps.go:101` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 8 | Düğme **Menü: QR yenile** (satır 165) | `POST /patrol-checkpoints/:id/location` · patrol · `services/patrol/gps.go:100` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `PATCH /patrol-checkpoints/:id` · patrol · `services/patrol/gps.go:99` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `POST /patrol-checkpoints/:id/rotate-qr` · patrol · `services/patrol/gps.go:101` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |

### patrol_control_screen
- **Dosya:** `admin_app/lib/features/patrol/presentation/screens/patrol_control_screen.dart`
- **Rota:** `/patrol`
- **Ekranda:**
  - Veri (satır 1): `GET /patrols` (patrol); `GET /patrols-summary` (patrol); `GET /patrol-routes` (patrol)
  - Başlık (satır 29): Devriye
  - Sekmeler (satır 36): Turlar
  - Sekmeler (satır 36): Güzergâhlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Devriye yürüt (gider: /patrol/run) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 32) | — | | | | |
| 2 | Düğme **Raporlar (gider: /patrol/reports) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 33) | — | | | | |
| 3 | Düğme **Nokta kurulumu (gider: /patrol/points) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 34) | — | | | | |

### patrol_report_screen
- **Dosya:** `admin_app/lib/features/patrol/presentation/screens/patrol_report_screen.dart`
- **Rota:** `/patrol/reports`
- **Ekranda:**
  - Veri (satır 1): `GET /patrol-reports` (patrol); `GET /patrols/:id/report` (patrol)
  - Başlık (satır 35): Devriye raporları
  - Başlık (satır 88): Tur raporu

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${p[ (gider: PatrolDetailScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 66) | — | | | | |

### patrol_run_screen
- **Dosya:** `admin_app/lib/features/patrol/presentation/screens/patrol_run_screen.dart`
- **Rota:** `/patrol/run`
- **Ekranda:**
  - Veri (satır 1): `GET /patrol-routes` (patrol); `GET /patrol-checkpoints` (patrol); `GET /patrols` (patrol)
  - Mesaj (satır 134): $e
  - Mesaj (satır 151): $e
  - Başlık (satır 238): Devriye yürüt
  - Başlık (satır 332): Nokta QR kodunu okutun

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${_points[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 191) | — | | | | |
| 2 | Düğme **QR okut (gider: _QrScanPage)** (satır 253) | `POST /patrols/:id/scan` · patrol · `services/patrol/gps.go:89` | BOARD_MEMBER/MANAGER/STAFF | patrol_scan_attempts(+), patrol_logs(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 3 | Düğme **Listeden seç (pencere açar)** (satır 260) | `POST /patrols/:id/scan` · patrol · `services/patrol/gps.go:89` | BOARD_MEMBER/MANAGER/STAFF | patrol_scan_attempts(+), patrol_logs(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 4 | Düğme **Sorun bildir (pencere açar)** (satır 261) | `POST /patrols/:id/issues` · patrol · `services/patrol/main.go:155` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 5 | Düğme **Turu bitir (pencere açar)** (satır 262) | `POST /patrols/:id/complete` · patrol · `services/patrol/main.go:179` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(±) | `patrol.issue` → Managers | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |
|  | ↳ | `POST /patrols/:id/track` · patrol · `services/patrol/gps.go:90` | BOARD_MEMBER/MANAGER/STAFF | patrol_track_points(+) | yok | Panel/patrol/reports, Yön.mobil patrol_report |
| 6 | Düğme **Başlat** (satır 281) | `POST /patrols` · patrol · `services/patrol/main.go:133` | BOARD_MEMBER/MANAGER/STAFF | patrol_logs(+) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |

### personnel_management_screen
- **Dosya:** `admin_app/lib/features/personnel/presentation/screens/personnel_management_screen.dart`
- **Rota:** `/personnel`
- **Ekranda:**
  - Veri (satır 1): `GET /employees` (personnel); `GET /employees/summary` (personnel); `GET /leaves` (personnel); `GET /payroll` (personnel); `GET /payroll/costs` (personnel); `GET /compliance-calendar` (personnel); `GET /employees/:id` (personnel)
  - Başlık (satır 79): Personel
  - Sekmeler (satır 83): Personel
  - Sekmeler (satır 84): İzinler
  - Sekmeler (satır 85): Bordro
  - Sekmeler (satır 86): Yükümlülükler
  - Başlık (satır 407): (dinamik)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İzin gir** (satır 81) | `POST /leaves` · personnel · `services/personnel/main.go:83` | BOARD_MEMBER/MANAGER | employee_leaves(+) | yok | Panel/personnel, Yön.mobil personnel_management |
| 2 | Düğme **Personel** (satır 90) | `POST /employees` · personnel · `services/personnel/main.go:81` | BOARD_MEMBER/MANAGER | employees(+) | yok | Panel/personnel, Yön.mobil personnel_management |
| 3 | Düğme **? (gider: _EmployeeDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 113) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 245) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 247) | — | | | | |
| 6 | Düğme **Bordro gir** (satır 267) | `POST /payroll` · personnel · `services/personnel/main.go:97` | BOARD_MEMBER/MANAGER | payroll(+) · tetikleyici: payroll_guard | yok | Panel/personnel, Yön.mobil personnel_management |
| 7 | Seçim **${DateTime.now().year - i} — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 333) | — | | | | |
| 8 | Düğme **Verildi** (satır 374) | `POST /employees/:id/sgk` · personnel · `services/personnel/main.go:90` | BOARD_MEMBER/MANAGER | employees(±) | yok | Panel/personnel, Yön.mobil personnel_management |

### renovations_screen
- **Dosya:** `admin_app/lib/features/renovations/presentation/screens/renovations_screen.dart`
- **Rota:** `/renovations`
- **Ekranda:**
  - Veri (satır 1): `GET /renovations` (community); `GET /residents` (identity); `GET /renovations/:id` (community)
  - Mesaj (satır 66): Başvuru kaydedildi. ${r[
  - Başlık (satır 83): Tadilat izinleri
  - Başlık (satır 152): Tadilat izni

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Başvuru (gider: _PermitDetail; pencere açar)** (satır 84) | `POST /renovations` · community · `services/community/renovation.go:88` | işleyicide `isManagement` (backend/services/community/main.go:257) | renovation_permits(+) | `renovation.request` → Approvers | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 2 | Düğme **${p[ (gider: _PermitDetail, _PermitDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 91) | — | | | | |
| 3 | Düğme **Rıza kaydet** (satır 187) | `POST /renovations/:id/consents` · community · `services/community/renovation.go:161` | BOARD_MEMBER/MANAGER | renovation_consents(+) | yok | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 4 | Düğme **Onayla** (satır 192) | `POST /renovations/:id/approve` · community · `services/community/renovation.go:190` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.approved`, `renovation.neighbors` → BlockNeighbors, işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 5 | Düğme **Reddet** (satır 193) | `POST /renovations/:id/reject` · community · `services/community/renovation.go:284` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.rejected` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 6 | Düğme **Denetle ve kapat** (satır 202) | `POST /renovations/:id/complete` · community · `services/community/renovation.go:320` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.completed` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 7 | Düğme **Çalışmayı durdur** (satır 214) | `POST /renovations/:id/stop` · community · `services/community/renovation.go:302` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.stopped` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |

### reports_screen
- **Dosya:** `admin_app/lib/features/reports/presentation/screens/reports_screen.dart`
- **Rota:** `/reports`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/reports/debtors` (finance); `GET /finance/reports/debtors` (finance); `GET /finance/reports/collections` (finance); `GET /finance/reports/collections` (finance)
  - Başlık (satır 37): Raporlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **PDF** (satır 45) | `GET /finance/reports/debtors` · finance · `services/finance/main.go:123` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 2 | Düğme **Excel** (satır 46) | `GET /finance/reports/debtors` · finance · `services/finance/main.go:123` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 3 | Düğme **PDF** (satır 51) | `GET /finance/reports/collections` · finance · `services/finance/main.go:125` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |
| 4 | Düğme **Excel** (satır 52) | `GET /finance/reports/collections` · finance · `services/finance/main.go:125` | AUDITOR/BOARD_MEMBER/MANAGER; işleyicide `reportRoles` (backend/services/finance/reports.go:23) | — | yok | — |

### request_detail_screen
- **Dosya:** `admin_app/lib/features/requests/presentation/screens/request_detail_screen.dart`
- **Rota:** `:id`
- **Ekranda:**
  - Veri (satır 1): `GET /requests` (community)
  - Başlık (satır 40): Talep Detayı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **IN_PROGRESS / İşleme al / Çözüldü olarak işaretle** (satır 69) | `PATCH /requests/:id/status` · community · `services/community/main.go:85` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/STAFF | requests(±) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |

### requests_screen
- **Dosya:** `admin_app/lib/features/requests/presentation/screens/requests_screen.dart`
- **Rota:** `/requests`
- **Ekranda:**
  - Veri (satır 1): `GET /requests` (community)
  - Başlık (satır 91): Talepler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **?** (satır 94) | `GET /requests` · community · `services/community/main.go:81` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 2 | Düğme **${ticket.isEmpty ?  (gider: /requests/$id) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |

### reservation_management_screen
- **Dosya:** `admin_app/lib/features/reservations/presentation/screens/reservation_management_screen.dart`
- **Rota:** `/reservations`
- **Ekranda:**
  - Veri (satır 1): `GET /reservations` (reservation); `GET /facilities` (reservation)
  - Başlık (satır 181): Rezervasyonlar
  - Sekmeler (satır 184): Rezervasyonlar
  - Sekmeler (satır 184): Tesisler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Menü: Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 240) | — | | | | |
| 2 | Düğme **Menü: Reddet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 243) | — | | | | |
| 3 | Düğme **Menü: İptal et — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 245) | — | | | | |
| 4 | Düğme **Tesis ekle** (satır 264) | `POST /facilities` · reservation · `services/reservation/main.go:280` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
|  | ↳ | `PATCH /facilities/:id` · reservation · `services/reservation/main.go:281` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
| 5 | Düğme **?** (satır 296) | `POST /facilities` · reservation · `services/reservation/main.go:280` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
|  | ↳ | `PATCH /facilities/:id` · reservation · `services/reservation/main.go:281` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |

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
| 3 | Düğme **Kaydet (pencere açar)** (satır 122) | `POST /residents` · identity · `services/identity/main.go:133` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), resident_units(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 4 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |

### resident_detail_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/resident_detail_screen.dart`
- **Rota:** `:id`
- **Ekranda:**
  - Veri (satır 1): `GET /residents/:id` (identity)
  - Mesaj (satır 48): Sakin bilgileri yüklenemedi: ${errorText(e)}
  - Mesaj (satır 63): Kod üretilemedi: ${errorText(e)}
  - Mesaj (satır 111): İşlem gerçekleştirilemedi, lütfen tekrar deneyin
  - Başlık (satır 130): Sakin Detayı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Menü: Etkinleştirme / şifre sıfırlama kodu üret** (satır 146) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:152` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `POST /residents/:id/phone` · identity · `services/identity/main.go:151` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 2 | Düğme **Menü: Telefon değiştir (oturumlar kapanır)** (satır 147) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:152` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `POST /residents/:id/phone` · identity · `services/identity/main.go:151` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 3 | Düğme **Menü: Giriş kilidini aç** (satır 148) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:152` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `POST /residents/:id/phone` · identity · `services/identity/main.go:151` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 4 | Düğme **Menü: Sıfat / ayrılış** (satır 149) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:152` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `POST /residents/:id/phone` · identity · `services/identity/main.go:151` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 5 | Düğme **Menü: Pasifleştir / Aktifleştir** (satır 150) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:152` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `POST /residents/:id/phone` · identity · `services/identity/main.go:151` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /residents/:id` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |

### resident_tools_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/resident_tools_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /units` (identity); `GET /residents/invitations` (identity); `GET /residents/tenancy-requests` (identity); `GET /residents/tenancy-requests/:id/documents/:docId` (identity)
  - Mesaj (satır 60): ${r[
  - Başlık (satır 108): ${data.where((d) => d[
  - Başlık (satır 159): Davet ve kiracılık
  - Sekmeler (satır 162): Davetler
  - Sekmeler (satır 162): Kiracılık bitişleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Toplu sakin ekle (gider: Scaffold; pencere açar)** (satır 161) | `POST /residents/bulk` · identity · `services/identity/main.go:134` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), resident_units(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 2 | Düğme **Davet et (pencere açar)** (satır 179) | `POST /residents/invitations` · identity · `services/identity/main.go:136` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) | `identity.invitation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 3 | Düğme **Yönetim yolu başlat (pencere açar)** (satır 217) | `POST /residents/tenancy-requests` · identity · `services/identity/main.go:140` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY | tenancy_end_documents(+), tenancy_end_events(+), tenancy_end_requests(+) · dosya deposu | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
|  | ↳ | `POST /residents/tenancy-requests/:id/documents` · identity · `services/identity/main.go:141` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY | tenancy_end_documents(+), tenancy_end_events(+), tenancy_end_requests(±) · dosya deposu | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 4 | Düğme **${_docKinds.firstWhere((k) => k.$1 == x[** (satır 234) | `GET /residents/tenancy-requests/:id/documents/:docId` · identity · `services/identity/main.go:145` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — · dosya deposu | yok | — |
| 5 | Düğme **Tamamla (itiraz süresi dolunca) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 246) | — | | | | |
| 6 | Düğme **Yeni belge (pencere açar)** (satır 254) | `POST /residents/tenancy-requests` · identity · `services/identity/main.go:140` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY | tenancy_end_documents(+), tenancy_end_events(+), tenancy_end_requests(+) · dosya deposu | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
|  | ↳ | `POST /residents/tenancy-requests/:id/documents` · identity · `services/identity/main.go:141` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY | tenancy_end_documents(+), tenancy_end_events(+), tenancy_end_requests(±) · dosya deposu | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 7 | Düğme **İptal** (satır 256) | `POST /residents/tenancy-requests/:id/cancel` · identity · `services/identity/main.go:143` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 8 | Düğme **Geri al** (satır 263) | `POST /residents/tenancy-requests/:id/reverse` · identity · `services/identity/main.go:144` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### residents_screen
- **Dosya:** `admin_app/lib/features/residents/presentation/screens/residents_screen.dart`
- **Rota:** `/residents`
- **Ekranda:**
  - Veri (satır 1): `GET /residents` (identity)
  - Mesaj (satır 48): Sakinler yüklenemedi, lütfen tekrar deneyin
  - Başlık (satır 58): Sakinler
  - Alan (satır 82): Sakin ara...

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Davet, toplu ekleme, kiracılık bitişi (gider: ResidentToolsScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 61) | — | | | | |
| 2 | Düğme **? (pencere açar)** (satır 66) | `GET /residents` · identity · `services/identity/main.go:132` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 3 | Düğme **?** (satır 85) | `GET /residents` · identity · `services/identity/main.go:132` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 4 | Düğme **? (gider: /residents/${resident[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 127) | — | | | | |
| 5 | Düğme **Sakin Ekle (gider: /residents/add)** (satır 137) | `GET /residents` · identity · `services/identity/main.go:132` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 6 | Düğme **Uygula** (satır 174) | `GET /residents` · identity · `services/identity/main.go:132` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 7 | Düğme **${resident[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 231) | — | | | | |

### activation_code_dialog
- **Dosya:** `admin_app/lib/features/residents/presentation/widgets/activation_code_dialog.dart`
- **Ekranda:**
  - Pencere (satır 23): $who için kod:
  - Mesaj (satır 45): Kod kopyalandı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kod kopyalandı — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 39) | — | | | | |
| 2 | Düğme **Kodu ilettim, kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 61) | — | | | | |

### roles_screen
- **Dosya:** `admin_app/lib/features/roles/presentation/screens/roles_screen.dart`
- **Rota:** `/roles`
- **Ekranda:**
  - Veri (satır 1): `GET /property-roles` (identity)
  - Mesaj (satır 48): Bu görev için kurul kararı bilgisi zorunludur
  - Başlık (satır 67): Görevlendirmeler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Görev ver (pencere açar)** (satır 68) | `POST /property-roles` · identity · `services/identity/main.go:169` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | property_roles(+), user_activation_codes(+), users(+), user_activation_codes(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |

### sensors_screen
- **Dosya:** `admin_app/lib/features/sensors/presentation/screens/sensors_screen.dart`
- **Rota:** `/sensors`
- **Ekranda:**
  - Veri (satır 1): `GET /sensors/:id/data` (iot); `GET /iot/alerts` (iot); `GET /sensors` (iot)
  - Pencere (satır 49): Cihaz anahtarı
  - Başlık (satır 131): Sensörler
  - Sekmeler (satır 133): Alarmlar
  - Sekmeler (satır 133): Sensörler
  - Alan (satır 246): Ad *
  - Alan (satır 251): Tür *
  - Alan (satır 255): Konum
  - Alan (satır 257): Birim (°C, %, cm)
  - Alan (satır 261): Alt eşik
  - Alan (satır 266): Üst eşik
  - Alan (satır 273): Sinyal kesilme süresi (dk) *

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kopyala — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 59) | — | | | | |
| 2 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 63) | — | | | | |
| 3 | Düğme **Sensör ekle (pencere açar)** (satır 136) | `POST /sensors` · iot · `services/iot/sensors.go:303` | BOARD_MEMBER/MANAGER | sensors(+) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `PATCH /sensors/:id` · iot · `services/iot/sensors.go:332` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
| 4 | Düğme **Menü: Onayla** (satır 166) | `POST /iot/alerts/:id/acknowledge` · iot · `services/iot/sensors.go:263` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /iot/alerts/:id/close` · iot · `services/iot/sensors.go:277` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |
| 5 | Düğme **Menü: Kapat** (satır 167) | `POST /iot/alerts/:id/acknowledge` · iot · `services/iot/sensors.go:263` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /iot/alerts/:id/close` · iot · `services/iot/sensors.go:277` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |
| 6 | Düğme **Menü: Geçmiş** (satır 199) | `POST /sensors/:id/rotate-key` · iot · `services/iot/sensors.go:360` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /sensors` · iot · `services/iot/sensors.go:303` | BOARD_MEMBER/MANAGER | sensors(+) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `PATCH /sensors/:id` · iot · `services/iot/sensors.go:332` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
| 7 | Düğme **Menü: Düzenle** (satır 200) | `POST /sensors/:id/rotate-key` · iot · `services/iot/sensors.go:360` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /sensors` · iot · `services/iot/sensors.go:303` | BOARD_MEMBER/MANAGER | sensors(+) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `PATCH /sensors/:id` · iot · `services/iot/sensors.go:332` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
| 8 | Düğme **Menü: Anahtarı yenile** (satır 201) | `POST /sensors/:id/rotate-key` · iot · `services/iot/sensors.go:360` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /sensors` · iot · `services/iot/sensors.go:303` | BOARD_MEMBER/MANAGER | sensors(+) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `PATCH /sensors/:id` · iot · `services/iot/sensors.go:332` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
| 9 | Seçim **Tür * — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 249) | — | | | | |
| 10 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 282) | — | | | | |

### api_settings_screen
- **Dosya:** `admin_app/lib/features/settings/presentation/screens/api_settings_screen.dart`
- **Rota:** `/api-settings`
- **Ekranda:**
  - Veri (satır 1): `GET /integrations/status` (karşılığı yok)
  - Başlık (satır 19): Entegrasyon Durumu

### site_settings_screen
- **Dosya:** `admin_app/lib/features/settings/presentation/screens/site_settings_screen.dart`
- **Rota:** `/site-settings`
- **Ekranda:**
  - Veri (satır 1): `GET /settings-history` (settings); `GET /settings` (settings); `GET /settings/definitions` (settings); `GET /retention-rules` (settings); `GET /retention-rules/log` (settings); `GET /privacy/cameras` (settings); `GET /privacy/biometrics` (settings); `GET /property` (identity); `GET /settings/owner-visibility` (settings)
  - Başlık (satır 52): Ayarlar
  - Sekmeler (satır 55): Ayarlar
  - Sekmeler (satır 55): Saklama ve imha
  - Sekmeler (satır 55): Kamera ve biyometrik
  - Sekmeler (satır 55): Geçmiş
  - Sekmeler (satır 55): Site durumu
  - Sekmeler (satır 55): Malik görünürlüğü

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Şimdi imha et** (satır 150) | `POST /retention-rules/run` · settings · `services/settings/main.go:152` | BOARD_MEMBER/MANAGER | client_error_reports(−), data_destruction_log(+), storage_deletion_queue(+), packages(±), parking_logs(±), visitors(±) | yok | Panel/packages, Panel/parking, Panel/settings, Panel/visitors, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil site_settings, Yön.mobil visitor_management |
| 2 | Düğme **?** (satır 168) | `PUT /retention-rules/:category` · settings · `services/settings/main.go:143` | BOARD_MEMBER/MANAGER | client_error_reports(−), data_retention_rules(+), storage_deletion_queue(+), packages(±), parking_logs(±), visitors(±) | yok | Panel/packages, Panel/parking, Panel/settings, Panel/visitors, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil site_settings, Yön.mobil visitor_management |
| 3 | Düğme **?** (satır 236) | `PUT /privacy/cameras/:id` · settings · `services/settings/main.go:150` | BOARD_MEMBER/MANAGER | camera_devices(±) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
|  | ↳ | `POST /privacy/cameras` · settings · `services/settings/main.go:149` | BOARD_MEMBER/MANAGER | camera_devices(+) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
| 4 | Düğme **?** (satır 246) | `PUT /privacy/cameras/:id` · settings · `services/settings/main.go:150` | BOARD_MEMBER/MANAGER | camera_devices(±) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
|  | ↳ | `POST /privacy/cameras` · settings · `services/settings/main.go:149` | BOARD_MEMBER/MANAGER | camera_devices(+) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
| 5 | Düğme **?** (satır 254) | `POST /privacy/biometrics` · settings · `services/settings/main.go:151` | BOARD_MEMBER/MANAGER | biometric_systems(+) | yok | Panel/settings, Yön.mobil site_settings |
| 6 | Düğme **Siteyi pasife al / Siteyi yeniden etkinleştir** (satır 299) | `POST /property/deactivate` · identity · `services/identity/main.go:160` | MANAGER | property_lifecycle_events(+), properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |
|  | ↳ | `POST /property/reactivate` · identity · `services/identity/main.go:161` | MANAGER | property_lifecycle_events(+), properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |
| 7 | Düğme **Değişiklik öner** (satır 351) | `POST /settings/owner-visibility` · settings · `services/settings/main.go:145` | BOARD_MEMBER/MANAGER | owner_visibility_policies(+) · tetikleyici: trg_owner_visibility_guard | yok | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
| 8 | Düğme **Not (pencere açar)** (satır 372) | `POST /settings/owner-visibility/:id/approve` · settings · `services/settings/main.go:146` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | `visibility.policy` → Tenants | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
|  | ↳ | `POST /settings/owner-visibility/:id/reject` · settings · `services/settings/main.go:147` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | `visibility.policy` → Tenants | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
| 9 | Düğme **Geri çek** (satır 386) | `POST /settings/owner-visibility/:id/cancel` · settings · `services/settings/main.go:148` | BOARD_MEMBER/MANAGER | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | yok | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |

### survey_management_screen
- **Dosya:** `admin_app/lib/features/surveys/presentation/screens/survey_management_screen.dart`
- **Rota:** `/surveys`
- **Ekranda:**
  - Veri (satır 1): `GET /surveys` (survey); `GET /surveys/:id` (survey); `GET /surveys/:id/comments` (survey)
  - Başlık (satır 73): Anketler
  - Başlık (satır 153): Anket yorumları
  - Alan (satır 287): Tür
  - Alan (satır 293): Başlık *
  - Alan (satır 296): Açıklama
  - Alan (satır 303): Seçenek ${i + 1} *

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Anket (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 75) | — | | | | |
| 2 | Düğme **${s[ (pencere açar) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 96) | — | | | | |
| 3 | Düğme **Yorumlar (gider: Scaffold)** (satır 148) | `GET /surveys/:id/comments` · survey · `services/survey/main.go:119` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |
| 4 | Düğme **İptal et (pencere açar)** (satır 197) | `POST /surveys/:id/cancel` · survey · `services/survey/main.go:218` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/close` · survey · `services/survey/main.go:209` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/publish` · survey · `services/survey/main.go:195` | BOARD_MEMBER/MANAGER | surveys(±) | `survey.published` → Residents | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 5 | Düğme **Oylamayı bitir (pencere açar)** (satır 205) | `POST /surveys/:id/cancel` · survey · `services/survey/main.go:218` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/close` · survey · `services/survey/main.go:209` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/publish` · survey · `services/survey/main.go:195` | BOARD_MEMBER/MANAGER | surveys(±) | `survey.published` → Residents | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 6 | Düğme **Yayınla (pencere açar)** (satır 212) | `POST /surveys/:id/cancel` · survey · `services/survey/main.go:218` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/close` · survey · `services/survey/main.go:209` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
|  | ↳ | `POST /surveys/:id/publish` · survey · `services/survey/main.go:195` | BOARD_MEMBER/MANAGER | surveys(±) | `survey.published` → Residents | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 7 | Seçim **Tür — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 285) | — | | | | |
| 8 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 308) | — | | | | |
| 9 | Düğme **Seçenek ekle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 315) | — | | | | |
| 10 | Düğme **Bitiş tarihi — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 335) | — | | | | |
| 11 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 339) | — | | | | |
| 12 | Düğme **Taslak olarak kaydet** (satır 347) | `POST /surveys` · survey · `services/survey/main.go:168` | BOARD_MEMBER/MANAGER | survey_options(+), surveys(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |

### units_screen
- **Dosya:** `admin_app/lib/features/units/presentation/screens/units_screen.dart`
- **Rota:** `/units`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/clearance-certificates/:id/pdf` (finance); `GET /units` (identity)
  - Mesaj (satır 131): Borcu yoktur belgesi üretildi (geçerlilik ${formatDate(r[
  - Başlık (satır 141): Bağımsız bölümler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Toplu ekle (pencere açar)** (satır 142) | `POST /units` · identity · `services/identity/main.go:178` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(+) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 2 | Düğme **Bölüm** (satır 144) | `POST /units` · identity · `services/identity/main.go:178` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(+) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `PATCH /units/:id` · identity · `services/identity/main.go:179` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(±) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### violations_screen
- **Dosya:** `admin_app/lib/features/violations/presentation/screens/violations_screen.dart`
- **Rota:** `/violations`
- **Ekranda:**
  - Veri (satır 1): `GET /site-rules` (community); `GET /violations` (community); `GET /violations/:id` (community)
  - Başlık (satır 80): Kural ihlalleri
  - Sekmeler (satır 80): İhlaller
  - Sekmeler (satır 80): Kural kataloğu
  - Başlık (satır 181): İhlal kaydı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İhlal (gider: _ViolationDetail; pencere açar)** (satır 81) | `POST /violations` · community · `services/community/violation.go:131` | işleyicide `isManagement` (backend/services/community/main.go:257) | rule_violation_events(+), rule_violations(+) | `violation.reported` → Approvers | Panel/violations, Sakin violations, Yön.mobil violations |
| 2 | Düğme **${v[ (gider: _ViolationDetail, _ViolationDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 95) | — | | | | |
| 3 | Düğme **Kural ekle** (satır 114) | `POST /site-rules` · community · `services/community/violation.go:66` | BOARD_MEMBER/MANAGER | site_rules(+) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
| 4 | Düğme **Doğrula** (satır 201) | `POST /violations/:id/verify` · community · `services/community/violation.go:210` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
| 5 | Düğme **Doğrulanmadı** (satır 207) | `POST /violations/:id/escalate` · community · `services/community/violation.go:240` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.{…}` → UnitResidents | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/resolve` · community · `services/community/violation.go:285` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/dismiss` · community · `services/community/violation.go:221` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.dismissed` → işlemin muhatabı (v.ReportedBy) | Panel/violations, Sakin violations, Yön.mobil violations |
| 6 | Düğme **?** (satır 212) | `POST /violations/:id/escalate` · community · `services/community/violation.go:240` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.{…}` → UnitResidents | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/resolve` · community · `services/community/violation.go:285` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/dismiss` · community · `services/community/violation.go:221` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.dismissed` → işlemin muhatabı (v.ReportedBy) | Panel/violations, Sakin violations, Yön.mobil violations |
| 7 | Düğme **Kapat** (satır 218) | `POST /violations/:id/escalate` · community · `services/community/violation.go:240` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.{…}` → UnitResidents | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/resolve` · community · `services/community/violation.go:285` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/dismiss` · community · `services/community/violation.go:221` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.dismissed` → işlemin muhatabı (v.ReportedBy) | Panel/violations, Sakin violations, Yön.mobil violations |
| 8 | Düğme **Doğrulanmadı** (satır 219) | `POST /violations/:id/escalate` · community · `services/community/violation.go:240` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.{…}` → UnitResidents | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/resolve` · community · `services/community/violation.go:285` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/dismiss` · community · `services/community/violation.go:221` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.dismissed` → işlemin muhatabı (v.ReportedBy) | Panel/violations, Sakin violations, Yön.mobil violations |

### visitor_management_screen
- **Dosya:** `admin_app/lib/features/visitors/presentation/screens/visitor_management_screen.dart`
- **Rota:** `/visitors`
- **Ekranda:**
  - Veri (satır 1): `GET /visitors` (visitor); `GET /visitors/summary` (visitor); `GET /units` (identity)
  - Pencere (satır 61): ${v[
  - Başlık (satır 79): Ziyaretçiler
  - Pencere (satır 165): Geçiş koduyla giriş
  - Alan (satır 171): 6 haneli PIN ya da QR kodu
  - Pencere (satır 204): Ziyaretçi kaydı
  - Alan (satır 210): Ad soyad
  - Alan (satır 214): Daire
  - Alan (satır 222): Telefon
  - Alan (satır 223): Plaka
  - Alan (satır 224): Ziyaret nedeni

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 68) | — | | | | |
| 2 | Düğme **Geçiş koduyla giriş (pencere açar)** (satır 80) | `POST /visitors/verify-pass` · visitor · `services/visitor/main.go:174` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
| 3 | Düğme **Kayıt (pencere açar)** (satır 87) | `POST /visitors` · visitor · `services/visitor/main.go:100` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(+), visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 4 | Düğme **Menü: Giriş yaptı** (satır 144) | `POST /visitors/:id/check-in` · visitor · `services/visitor/main.go:175` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/check-out` · visitor · `services/visitor/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 5 | Düğme **Menü: Çıkış yaptı** (satır 145) | `POST /visitors/:id/check-in` · visitor · `services/visitor/main.go:175` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/check-out` · visitor · `services/visitor/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 6 | Düğme **Menü: Kodu yenile** (satır 146) | `POST /visitors/:id/check-in` · visitor · `services/visitor/main.go:175` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/check-out` · visitor · `services/visitor/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 7 | Düğme **Menü: İptal et** (satır 147) | `POST /visitors/:id/check-in` · visitor · `services/visitor/main.go:175` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/check-out` · visitor · `services/visitor/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
|  | ↳ | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 8 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 174) | — | | | | |
| 9 | Düğme **Doğrula — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 175) | — | | | | |
| 10 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 212) | — | | | | |
| 11 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 229) | — | | | | |
| 12 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 230) | — | | | | |
