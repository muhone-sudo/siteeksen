# 2. Sakin mobil uygulaması — ekran ekran

Kaynak: `mobile/lib/`. Rotalar: `mobile/lib/core/router/app_router.dart`. API istemcisi: `mobile/lib/core/network/api_client.dart`.

### apple_widgets
- **Dosya:** `mobile/lib/core/widgets/apple_widgets.dart`

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 35) | — | | | | |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 165) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 215) | — | | | | |
| 4 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 239) | — | | | | |
| 5 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 292) | — | | | | |

### data_state
- **Dosya:** `mobile/lib/core/widgets/data_state.dart`

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yeniden dene — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 69) | — | | | | |

### future_list
- **Dosya:** `mobile/lib/core/widgets/future_list.dart`
- **Ekranda:**
  - Pencere (satır 90): Vazgeç
  - Pencere (satır 107): Vazgeç

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 94) | — | | | | |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 95) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 121) | — | | | | |
| 4 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 122) | — | | | | |

### announcements_screen
- **Dosya:** `mobile/lib/features/announcements/presentation/screens/announcements_screen.dart`
- **Rota:** `/announcements`
- **Ekranda:**
  - Veri (satır 1): `GET /announcements` (community)
  - Başlık (satır 80): Duyurular

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${a[ (pencere açar)** (satır 99) | `POST /announcements/:id/read` · community · `services/community/main.go:124` | oturum açmış herkes (site kapsamı) | announcement_reads(+) | yok | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |

### activate_screen
- **Dosya:** `mobile/lib/features/auth/presentation/screens/activate_screen.dart`
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
- **Dosya:** `mobile/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`
- **Rota:** `/kvkk-consent`
- **Ekranda:**
  - Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
  - Başlık (satır 40): Kişisel Verilerin Korunması

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onaylıyorum ve Devam Ediyorum (gider: /)** (satır 84) | `POST /users/me/kvkk-consent` · identity · `services/identity/main.go:103` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |

### login_screen
- **Dosya:** `mobile/lib/features/auth/presentation/screens/login_screen.dart`
- **Rota:** `/login`
- **Ekranda:**
  - Alan (satır 107): Telefon Numarası
  - Alan (satır 109): 0555 123 45 67 · yurt dışı: +49 …
  - Alan (satır 128): Şifre
  - Mesaj (satır 236): Giriş başarısız: telefon veya şifre hatalı
  - Pencere (satır 255): Biyometrik Giriş
  - Mesaj (satır 293): Oturum yenilenemedi, lütfen şifrenizle giriş yapın
  - Mesaj (satır 299): Biyometrik doğrulama başarısız

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 130) | — | | | | |
| 2 | Düğme **Şifremi Unuttum (gider: /activate) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 155) | — | | | | |
| 3 | Düğme **Giriş Yap (gider: /kvkk-consent, /; pencere açar)** (satır 163) | `POST /auth/login` · identity · `services/identity/main.go:78` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 4 | Düğme **Biyometrik Giriş (gider: /) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 180) | — | | | | |
| 5 | Düğme **Hesabı Etkinleştir (gider: /activate) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 200) | — | | | | |
| 6 | Düğme **Hayır — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 261) | — | | | | |
| 7 | Düğme **Etkinleştir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 265) | — | | | | |

### bulletin_board_mobile_screen
- **Dosya:** `mobile/lib/features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart`
- **Rota:** `/bulletin`
- **Ekranda:**
  - Veri (satır 1): `GET /bulletins/:id/comments` (bulletin); `GET /bulletins` (bulletin)
  - Başlık (satır 70): İlan Panosu
  - Alan (satır 202): Kategori
  - Alan (satır 208): Başlık
  - Alan (satır 214): Açıklama
  - Alan (satır 221): Fiyat (₺, isteğe bağlı)
  - Alan (satır 343): Yorum yazın

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İlan Ver (pencere açar)** (satır 71) | `POST /bulletins` · bulletin · `services/bulletin/main.go:85` | oturum açmış herkes (site kapsamı) | bulletin_posts(+) | `bulletin.pending` → Approvers | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 2 | Düğme **${b[ (pencere açar)** (satır 128) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 3 | Düğme **Kapat** (satır 150) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 4 | Seçim **Kategori — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 200) | — | | | | |
| 5 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 230) | — | | | | |
| 6 | Düğme **?** (satır 344) | `POST /bulletins/:id/comments` · bulletin · `services/bulletin/main.go:136` | oturum açmış herkes (site kapsamı) | bulletin_comments(+) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |

### common_income_screen
- **Dosya:** `mobile/lib/features/common_income/presentation/screens/common_income_screen.dart`
- **Rota:** `/common-income`
- **Ekranda:**
  - Veri (satır 1): `GET /governance/common-area/my-share` (governance)
  - Başlık (satır 34): Ortak alan geliri payım

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 44) | — | | | | |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 46) | — | | | | |

### dask_screen
- **Dosya:** `mobile/lib/features/dask/presentation/screens/dask_screen.dart`
- **Rota:** `/dask`
- **Ekranda:**
  - Veri (satır 1): `GET /insurance/dask` (contract)
  - Pencere (satır 45): ${r[
  - Alan (satır 48): Poliçe no
  - Alan (satır 49): Sigorta şirketi
  - Mesaj (satır 87): Poliçe kaydedildi
  - Başlık (satır 97): DASK poliçem

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${formatDate(apiDate(start))} – ${formatDate(apiDate(end))} — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 50) | — | | | | |
| 2 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 71) | — | | | | |
| 3 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 72) | — | | | | |
| 4 | Düğme **Poliçe gir (pencere açar)** (satır 113) | `POST /insurance/dask` · contract · `services/contract/main.go:71` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | unit_insurance_policies(+) | yok | Panel/insurance, Sakin dask, Yön.mobil insurance |

### documents_screen
- **Dosya:** `mobile/lib/features/documents/presentation/screens/documents_screen.dart`
- **Rota:** `/documents`
- **Ekranda:**
  - Veri (satır 1): `GET /documents` (document); `GET /documents/:id/download` (document)
  - Başlık (satır 96): Belgeler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${d[** (satır 113) | `GET /documents/:id/download` · document · `services/document/main.go:135` | işleyicide `hasRole` (backend/services/settings/visibility.go:74); işleyicide `isManagement` (backend/services/community/main.go:257) | document_access_logs(+) · tetikleyici: document_access_logs_no_update · dosya deposu | yok | — |

### emergency_screen
- **Dosya:** `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart`
- **Rota:** `/emergency`
- **Ekranda:**
  - Veri (satır 1): `GET /emergency/info` (community); `GET /emergency/checks` (community); `GET /emergency/cards/me` (community); `GET /users/me/properties` (identity)
  - Mesaj (satır 99): ${res[
  - Başlık (satır 110): Acil durum
  - Mesaj (satır 230): Kayıtlı daireniz bulunamadı
  - Mesaj (satır 242): ${res[
  - Mesaj (satır 258): Kartınız ve rızanız silindi
  - Başlık (satır 267): Acil bilgi kartım
  - Alan (satır 279): Tahliyede yardım ihtiyacı
  - Alan (satır 279): ör. tekerlekli sandalye, yatağa bağlı yakın, bebek
  - Alan (satır 281): Ulaşılacak yakın (isteğe bağlı)
  - Alan (satır 282): Yakının telefonu (isteğe bağlı)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Güvendeyim** (satır 140) | `POST /emergency/checks/:id/respond` · community · `services/community/emergency.go:326` | `resident_can_use` | safety_check_responses(+) | `safety.need_help` → Approvers | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 2 | Düğme **Yardım gerekiyor** (satır 143) | `POST /emergency/checks/:id/respond` · community · `services/community/emergency.go:326` | `resident_can_use` | safety_check_responses(+) | `safety.need_help` → Approvers | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 3 | Düğme **Acil bilgi kartım (gider: EmergencyCardScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 174) | — | | | | |
| 4 | Düğme **Açık rızamla kaydet** (satır 290) | `PUT /emergency/cards/me` · community · `services/community/emergency.go:202` | `resident_can_use` | resident_emergency_cards(+) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 5 | Düğme **Kartımı ve rızamı sil** (satır 294) | `DELETE /emergency/cards/me` · community · `services/community/emergency.go:242` | oturum açmış herkes (site kapsamı) | resident_emergency_cards(−) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |

### energy_consumption_mobile_screen
- **Dosya:** `mobile/lib/features/energy/presentation/screens/energy_consumption_mobile_screen.dart`
- **Rota:** `/energy`
- **Ekranda:**
  - Veri (satır 1): `GET /consumption/statements` (iot); `GET /consumption/objections` (iot); `GET /consumption/statements/:id/pdf` (iot); `GET /finance/consumption/summary` (finance)
  - Pencere (satır 395): Pusulaya itiraz
  - Alan (satır 402): Gerekçe
  - Alan (satır 403): Ör. sayaçta okunan değer, okuma tarihi, fotoğrafınızın tarihi

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 231) | — | | | | |
| 2 | Düğme **PDF** (satır 340) | `GET /consumption/statements/:id/pdf` · iot · `services/iot/main.go:469` | `resident_can_use` | — | yok | — |
| 3 | Düğme **İtiraz et (pencere açar)** (satır 367) | `POST /consumption/statements/:id/objections` · iot · `services/iot/main.go:471` | `resident_can_use` | consumption_statement_objections(+) · tetikleyici: consumption_statement_objections_guard | `statement.objection` → Approvers | Panel/meters, Sakin energy_consumption_mobile, Yön.mobil meters |
| 4 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 406) | — | | | | |
| 5 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 407) | — | | | | |

### dues_payment_screen
- **Dosya:** `mobile/lib/features/finance/presentation/screens/dues_payment_screen.dart`
- **Rota:** `payment`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity); `GET /finance/clearance-certificates/:id/pdf` (finance); `GET /finance/credit-notes` (finance); `GET /finance/credit-notes/:id/pdf` (finance); `GET /finance/ledger/verify` (finance); `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance); `GET /finance/payments/:id/status` (finance)
  - Dosya seçme (satır 18)
  - Dosya seçme (satır 18)
  - Başlık (satır 95): Aidat Ödeme
  - Pencere (satır 367): Borcu yoktur belgesi
  - Pencere (satır 388): Alacak dekontlarım
  - Pencere (satır 446): Tahsilat kayıtları
  - Pencere (satır 463): Ödeme Onayı
  - Alan (satır 491): Havale açıklaması / dekont no (isteğe bağlı)
  - Pencere (satır 532): Ödeme oluşturulamadı
  - Pencere (satır 559): Ödeme işlemde
  - Pencere (satır 609): Tamam
  - Dosya seçme (satır 633)
  - Pencere (satır 661): Tutar: ${formatTry(amount)}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Borcu yoktur belgesi (pencere açar)** (satır 100) | `POST /finance/clearance-certificates` · finance · `services/finance/main.go:104` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | clearance_certificates(+) | yok | Panel/units, Sakin dues_payment, Yön.mobil units |
| 2 | Düğme **Alacak dekontlarım (pencere açar)** (satır 106) | `GET /finance/credit-notes` · finance · `services/finance/main.go:108` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/credit-notes/:id/pdf` · finance · `services/finance/main.go:109` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
| 3 | Düğme **Tahsilat kayıtlarını doğrula (pencere açar)** (satır 112) | `GET /finance/ledger/verify` · finance · `services/finance/main.go:100` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 4 | Düğme **Ödenecek tahakkuk yok / ${formatTry(_currentBalance)} Öde (pencere açar; dış bağlantı/arama)** (satır 330) | `POST /finance/payments/:id/receipts` · finance · `services/finance/main.go:97` | oturum açmış herkes (site kapsamı) | payment_receipts(+) · dosya deposu | yok | Panel/accounting, Yön.mobil finance_tools, Yön.mobil payments |
|  | ↳ | `POST /finance/payments` · finance · `services/finance/main.go:93` | `assessment_visible_to` | late_fee_accruals(+), payment_assessments(+), payments(+), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 5 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 370) | — | | | | |
| 6 | Düğme **PDF** (satır 406) | `GET /finance/credit-notes/:id/pdf` · finance · `services/finance/main.go:109` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
| 7 | Düğme **Kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 415) | — | | | | |
| 8 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 449) | — | | | | |
| 9 | Düğme **Havaleyi yaptığınız gün — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 472) | — | | | | |
| 10 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 498) | — | | | | |
| 11 | Düğme **Devam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 501) | — | | | | |
| 12 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 536) | — | | | | |
| 13 | Düğme **Arka planda bekle** (satır 574) | `GET /finance/debt-status` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:91` | `assessment_visible_to` | — | yok | — |
| 14 | Düğme **Tamam** (satır 613) | `GET /finance/debt-status` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:91` | `assessment_visible_to` | — | yok | — |
| 15 | Düğme **Dekont ekle** (satır 689) | `POST /finance/payments/:id/receipts` · finance · `services/finance/main.go:97` | oturum açmış herkes (site kapsamı) | payment_receipts(+) · dosya deposu | yok | Panel/accounting, Yön.mobil finance_tools, Yön.mobil payments |
| 16 | Düğme **Tamam** (satır 697) | `GET /finance/debt-status` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:91` | `assessment_visible_to` | — | yok | — |

### finance_screen
- **Dosya:** `mobile/lib/features/finance/presentation/screens/finance_screen.dart`
- **Rota:** `/finance`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance)
  - Başlık (satır 76): Finansal Durumum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Öde (gider: duesPayment)** (satır 161) | `GET /finance/debt-status` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:91` | `assessment_visible_to` | — | yok | — |

### payment_history_screen
- **Dosya:** `mobile/lib/features/finance/presentation/screens/payment_history_screen.dart`
- **Rota:** `/payment-history`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/my-payments` (finance)
  - Başlık (satır 39): Ödeme Geçmişi

### my_budgets_screen
- **Dosya:** `mobile/lib/features/governance/presentation/screens/my_budgets_screen.dart`
- **Rota:** `/my-budgets`
- **Ekranda:**
  - Veri (satır 1): `GET /governance/my-budgets` (governance); `GET /governance/my-budgets/:id` (governance)
  - Başlık (satır 37): İşletme Projesi
  - Başlık (satır 95): İşletme projesi

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${b[ (gider: _BudgetDetail) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 47) | — | | | | |
| 2 | Düğme **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 81) | — | | | | |
| 3 | Düğme **Görüş / itiraz bildir (pencere açar)** (satır 142) | `POST /governance/budgets/:id/objections` · governance · `services/governance/main.go:114` | oturum açmış herkes (site kapsamı) | budget_objections(+) | yok | Panel/governance/budgets, Sakin my_budgets, Yön.mobil governance |

### main_screen
- **Dosya:** `mobile/lib/features/home/presentation/screens/main_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /notifications/unread-count` (notification)
  - Pencere (satır 66): Uygulamadan çık

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 70) | — | | | | |
| 2 | Düğme **Çık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 74) | — | | | | |

### resident_home_screen
- **Dosya:** `mobile/lib/features/home/presentation/screens/resident_home_screen.dart`
- **Rota:** `/`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me` (identity); `GET /finance/debt-status` (finance); `GET /announcements` (community)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Duyurular (gider: announcements) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 179) | — | | | | |
| 2 | Düğme **Aidat Öde (gider: duesPayment) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 236) | — | | | | |
| 3 | Düğme **Ziyaretçi (gider: visitorPreregister) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 256) | — | | | | |
| 4 | Düğme **Rezervasyon (gider: createReservation) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 262) | — | | | | |
| 5 | Düğme **Talep (gider: createRequest) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 268) | — | | | | |
| 6 | Düğme **Anket (gider: surveys) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 274) | — | | | | |
| 7 | Düğme **Taleplerim (gider: requests) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 298) | — | | | | |
| 8 | Düğme **Kargolarım (gider: packages) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 305) | — | | | | |
| 9 | Düğme **Tüketim (gider: energy) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 312) | — | | | | |
| 10 | Düğme **Belgeler (gider: documents) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 319) | — | | | | |
| 11 | Düğme **? (gider: announcements) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 361) | — | | | | |

### invitations_banner
- **Dosya:** `mobile/lib/features/invitations/presentation/widgets/invitations_banner.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/invitations` (identity)
  - Mesaj (satır 62): ${res[

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yeniden dene** (satır 82) | `GET /users/me/invitations` · identity · `services/identity/main.go:127` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **Reddet** (satır 109) | `POST /users/me/invitations/:id/accept` · identity · `services/identity/main.go:128` | serviste rol karşılaştırması: OWNER/TENANT | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /users/me/invitations/:id/decline` · identity · `services/identity/main.go:129` | serviste rol karşılaştırması: OWNER/TENANT | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 3 | Düğme **Kabul et** (satır 114) | `POST /users/me/invitations/:id/accept` · identity · `services/identity/main.go:128` | serviste rol karşılaştırması: OWNER/TENANT | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /users/me/invitations/:id/decline` · identity · `services/identity/main.go:129` | serviste rol karşılaştırması: OWNER/TENANT | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### kvkk_requests_screen
- **Dosya:** `mobile/lib/features/kvkk/presentation/screens/kvkk_requests_screen.dart`
- **Rota:** `/kvkk`
- **Ekranda:**
  - Veri (satır 1): `GET /kvkk-requests` (community); `GET /privacy/cameras` (settings)
  - Pencere (satır 61): Yeni KVKK başvurusu
  - Alan (satır 78): Talebiniz
  - Alan (satır 78): Kısaca açıklayın (en az 10 karakter)
  - Mesaj (satır 93): ${res[
  - Başlık (satır 103): KVKK başvurularım
  - Başlık (satır 163): Ortak alan kameraları

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 65) | — | | | | |
| 2 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 83) | — | | | | |
| 3 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 84) | — | | | | |
| 4 | Düğme **Başvuru yap (pencere açar)** (satır 104) | `POST /kvkk-requests` · community · `services/community/kvkk.go:52` | oturum açmış herkes (site kapsamı) | kvkk_requests(+) | `kvkk.request` → Managers | Panel/kvkk, Sakin kvkk_requests, Yön.mobil kvkk_requests |
| 5 | Düğme **Ortak alan kameraları (gider: CamerasScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 127) | — | | | | |

### my_meters_screen
- **Dosya:** `mobile/lib/features/meters/presentation/screens/my_meters_screen.dart`
- **Rota:** `/my-meters`
- **Ekranda:**
  - Veri (satır 1): `GET /meter-readings` (iot)
  - Başlık (satır 18): Sayaçlarım
  - Başlık (satır 44): ${meter[

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${_types[ (gider: _Readings) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 23) | — | | | | |

### more_screen
- **Dosya:** `mobile/lib/features/more/presentation/screens/more_screen.dart`
- **Rota:** `/more`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me` (identity)
  - Başlık (satır 73): Daha Fazla
  - Pencere (satır 283): Çıkış Yap

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Bildirimlerim (gider: notifications) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 78) | — | | | | |
| 2 | Düğme **Duyurular (gider: announcements) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 83) | — | | | | |
| 3 | Düğme **Ödeme Geçmişi (gider: paymentHistory) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 88) | — | | | | |
| 4 | Düğme **Ziyaretçilerim (gider: myVisitors) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 93) | — | | | | |
| 5 | Düğme **Araçlarım (gider: vehicles) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 98) | — | | | | |
| 6 | Düğme **Sayaçlarım (gider: myMeters) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 7 | Düğme **Memnuniyet Anketi (gider: nps) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 108) | — | | | | |
| 8 | Düğme **İşletme Projesi (gider: myBudgets) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 113) | — | | | | |
| 9 | Düğme **Anketler (gider: surveys) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 118) | — | | | | |
| 10 | Düğme **İlan Panosu (gider: bulletin) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 123) | — | | | | |
| 11 | Düğme **Kargo Takibi (gider: packages) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 128) | — | | | | |
| 12 | Düğme **Rezervasyonlarım (gider: myReservations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 133) | — | | | | |
| 13 | Düğme **Ziyaretçi Ön Kaydı (gider: visitorPreregister) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 138) | — | | | | |
| 14 | Düğme **Tüketim (gider: energy) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 15 | Düğme **Belgeler (gider: documents) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 148) | — | | | | |
| 16 | Düğme **DASK poliçem (gider: dask) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 153) | — | | | | |
| 17 | Düğme **Ortak alan geliri payım (gider: commonIncome) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 158) | — | | | | |
| 18 | Düğme **Acil durum (gider: emergency) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 163) | — | | | | |
| 19 | Düğme **Kural ihlali bildir (gider: violations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 168) | — | | | | |
| 20 | Düğme **Tadilat izni (gider: renovations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 173) | — | | | | |
| 21 | Düğme **KVKK başvurusu (gider: kvkk) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 178) | — | | | | |
| 22 | Düğme **Profil ve Ayarlar (gider: profile) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 184) | — | | | | |
| 23 | Düğme **Hakkında — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 189) | — | | | | |
| 24 | Düğme **Çıkış Yap (gider: /login, /login; pencere açar)** (satır 195) | `POST /auth/logout` · identity · `services/identity/main.go:91` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 25 | Düğme **Profili düzenle (gider: profile) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 259) | — | | | | |
| 26 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 287) | — | | | | |
| 27 | Düğme **Çıkış Yap — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 290) | — | | | | |
| 28 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 321) | — | | | | |

### notifications_screen
- **Dosya:** `mobile/lib/features/notifications/presentation/screens/notifications_screen.dart`
- **Rota:** `/notifications`
- **Ekranda:**
  - Veri (satır 1): `GET /notifications` (notification)
  - Başlık (satır 67): Bildirimlerim

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tümünü okundu say** (satır 68) | `POST /notifications/read-all` · notification · `services/notification/main.go:97` | oturum açmış herkes (site kapsamı) | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |
| 2 | Düğme **${n[** (satır 88) | `POST /notifications/:id/read` · notification · `services/notification/main.go:84` | oturum açmış herkes (site kapsamı) | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |

### nps_screen
- **Dosya:** `mobile/lib/features/nps/presentation/screens/nps_screen.dart`
- **Rota:** `/nps`
- **Ekranda:**
  - Başlık (satır 33): Memnuniyet Anketi
  - Alan (satır 83): Yorum (isteğe bağlı)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yanıtla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 50) | — | | | | |
| 2 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 88) | — | | | | |

### package_tracking_mobile_screen
- **Dosya:** `mobile/lib/features/packages/presentation/screens/package_tracking_mobile_screen.dart`
- **Rota:** `/packages`
- **Ekranda:**
  - Veri (satır 1): `GET /packages` (package); `GET /packages/:id/proof/:kind` (package)
  - Başlık (satır 52): Kargolarım
  - Pencere (satır 128): Kapat

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Menü: İmzayı gör** (satır 114) | `GET /packages/:id/proof/:kind` · package · `services/package/main.go:185` | `resident_can_use` | — · dosya deposu | yok | — |
| 2 | Düğme **Menü: Fotoğrafı gör** (satır 115) | `GET /packages/:id/proof/:kind` · package · `services/package/main.go:185` | `resident_can_use` | — · dosya deposu | yok | — |
| 3 | Düğme **Kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 131) | — | | | | |

### owner_visibility_screen
- **Dosya:** `mobile/lib/features/profile/presentation/screens/owner_visibility_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /settings/owner-visibility` (settings)
  - Başlık (satır 68): Malikin görebildikleri

### profile_settings_screen
- **Dosya:** `mobile/lib/features/profile/presentation/screens/profile_settings_screen.dart`
- **Rota:** `/profile`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me` (identity); `GET /users/me/properties` (identity); `GET /notification-preferences` (notification)
  - Başlık (satır 103): Profil
  - Mesaj (satır 336): Tercih kaydedilemedi: ${toUserMessage(e)}
  - Pencere (satır 380): Tüm cihazlardan çıkış
  - Pencere (satır 403): Çıkış Yap

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${units[i][ (gider: UnitResidentsScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 190) | — | | | | |
| 2 | Düğme **E-posta (pencere açar)** (satır 211) | `POST /users/me/email` · identity · `services/identity/main.go:110` | oturum açmış herkes (site kapsamı) | email_change_requests(+), email_change_requests(±) | `identity.email_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/email/confirm` · identity · `services/identity/main.go:111` | oturum açmış herkes (site kapsamı) | email_change_requests(±), users(±) | `identity.email_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 3 | Düğme **Telefon (gider: /login; pencere açar)** (satır 220) | `POST /users/me/phone/request` · identity · `services/identity/main.go:108` | oturum açmış herkes (site kapsamı) | phone_change_requests(+), phone_change_requests(±) | `identity.phone_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/phone/confirm` · identity · `services/identity/main.go:109` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), phone_change_requests(±), users(±) | `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 4 | Düğme **Şifre Değiştir (gider: /login; pencere açar)** (satır 263) | `POST /users/me/password` · identity · `services/identity/main.go:106` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 5 | Düğme **Tüm Cihazlardan Çıkış (gider: /login; pencere açar)** (satır 270) | `POST /auth/logout` · identity · `services/identity/main.go:91` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
|  | ↳ | `POST /users/me/logout-all` · identity · `services/identity/main.go:105` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+) | yok |  |
| 6 | Düğme **KVKK Aydınlatma Metni (gider: kvkkConsent) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 288) | — | | | | |
| 7 | Düğme **Çıkış Yap (gider: /login; pencere açar)** (satır 305) | `POST /auth/logout` · identity · `services/identity/main.go:91` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 8 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 384) | — | | | | |
| 9 | Düğme **Hepsini kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 385) | — | | | | |
| 10 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 408) | — | | | | |
| 11 | Düğme **Çıkış Yap — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 411) | — | | | | |

### tenancy_requests_screen
- **Dosya:** `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/tenancy-requests` (identity); `GET /users/me/tenancy-requests/:id/documents/:docId` (identity)
  - Mesaj (satır 84): ${res[
  - Pencere (satır 95): Vazgeç
  - Pencere (satır 117): Vazgeç
  - Başlık (satır 211): Kiracılık işlemleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 99) | — | | | | |
| 2 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 100) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 121) | — | | | | |
| 4 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 122) | — | | | | |
| 5 | Düğme **Reddet (pencere açar)** (satır 147) | `POST /users/me/tenancy-requests/:id/approve` · identity · `services/identity/main.go:121` | serviste rol karşılaştırması: OWNER/PROXY | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /users/me/tenancy-requests/:id/decline` · identity · `services/identity/main.go:122` | serviste rol karşılaştırması: OWNER/PROXY | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 6 | Düğme **Onayla** (satır 156) | `POST /users/me/tenancy-requests/:id/approve` · identity · `services/identity/main.go:121` | serviste rol karşılaştırması: OWNER/PROXY | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /users/me/tenancy-requests/:id/decline` · identity · `services/identity/main.go:122` | serviste rol karşılaştırması: OWNER/PROXY | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 7 | Düğme **İtiraz et (pencere açar)** (satır 166) | `POST /users/me/tenancy-requests/:id/object` · identity · `services/identity/main.go:123` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 8 | Düğme **Geri çek** (satır 175) | `POST /users/me/tenancy-requests/:id/cancel` · identity · `services/identity/main.go:124` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 9 | Düğme **${_docKind[** (satır 197) | `GET /users/me/tenancy-requests/:id/documents/:docId` · identity · `services/identity/main.go:125` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — · dosya deposu | yok | — |

### unit_residents_screen
- **Dosya:** `mobile/lib/features/profile/presentation/screens/unit_residents_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/units/:id/residents` (identity); `GET /finance/tenant-debt-summary` (finance); `GET /requests/units/:unitId` (community)
  - Pencere (satır 101): Kaydı bitir
  - Mesaj (satır 115): ${res[
  - Pencere (satır 128): Vazgeç
  - Mesaj (satır 153): ${res[
  - Pencere (satır 167): Daire talepleri
  - Pencere (satır 202): Davet gönder
  - Alan (satır 215): Sıfat
  - Alan (satır 223): Ad
  - Alan (satır 225): Soyad
  - Alan (satır 230): Telefon
  - Alan (satır 230): 0555 123 45 67 · yurt dışı: +49 …
  - Alan (satır 234): E-posta (isteğe bağlı)
  - Pencere (satır 279): Davet gönderildi
  - Başlık (satır 291): ${widget.unitName} sakinleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 106) | — | | | | |
| 2 | Düğme **Bitir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 107) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 137) | — | | | | |
| 4 | Düğme **İste / Bildir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 138) | — | | | | |
| 5 | Düğme **Kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 182) | — | | | | |
| 6 | Seçim **Kiracı — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 213) | — | | | | |
| 7 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 239) | — | | | | |
| 8 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 240) | — | | | | |
| 9 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 282) | — | | | | |
| 10 | Düğme **Malikin görebildikleri (gider: OwnerVisibilityScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 292) | — | | | | |
| 11 | Düğme **Daire talepleri (pencere açar)** (satır 298) | `GET /requests/units/:unitId` · community · `services/community/main.go:84` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 12 | Düğme **Kiracılık işlemleri (gider: TenancyRequestsScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 299) | — | | | | |
| 13 | Düğme **Menü: OWNER / Kiracılığın bitmesini iste / Çıkışımı bildir** (satır 309) | `POST /users/me/units/:id/tenancy-end` · identity · `services/identity/main.go:118` | serviste rol karşılaştırması: OWNER | tenancy_end_events(+), tenancy_end_requests(+) | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
|  | ↳ | `POST /users/me/units/:id/tenancy-exit` · identity · `services/identity/main.go:119` | serviste rol karşılaştırması: OWNER/PROXY | tenancy_end_events(+), tenancy_end_requests(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 14 | Düğme **Davet gönder (pencere açar)** (satır 313) | `POST /users/me/units/:id/invitations` · identity · `services/identity/main.go:115` | serviste rol karşılaştırması: OWNER/PROXY/TENANT | resident_invitations(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) | `identity.invitation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 15 | Düğme **Bitir (pencere açar)** (satır 351) | `POST /users/me/units/:id/residents/:residentId/end` · identity · `services/identity/main.go:116` | serviste rol karşılaştırması: PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### renovations_screen
- **Dosya:** `mobile/lib/features/renovation/presentation/screens/renovations_screen.dart`
- **Rota:** `/renovations`
- **Ekranda:**
  - Veri (satır 1): `GET /renovations` (community); `GET /users/me/properties` (identity)
  - Pencere (satır 71): Başvuruyu geri çek
  - Mesaj (satır 83): Başvuru geri çekildi
  - Mesaj (satır 104): Tadilat başvurusunu dairenin maliki ya da vekili yapabilir.
  - Pencere (satır 118): Tadilat başvurusu
  - Alan (satır 126): Daire
  - Alan (satır 136): Kapsam
  - Alan (satır 150): Yapılacak iş
  - Alan (satır 150): En az 10 karakter
  - Alan (satır 152): Usta / firma (isteğe bağlı)
  - Mesaj (satır 192): Başvurunuz alındı. ${res[
  - Başlık (satır 202): Tadilat izinleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 75) | — | | | | |
| 2 | Düğme **Geri çek — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 76) | — | | | | |
| 3 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 123) | — | | | | |
| 4 | Seçim **Kapsam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 133) | — | | | | |
| 5 | Düğme **Tarih: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))} — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 153) | — | | | | |
| 6 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 175) | — | | | | |
| 7 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 176) | — | | | | |
| 8 | Düğme **Başvuru yap (pencere açar)** (satır 203) | `POST /renovations` · community · `services/community/renovation.go:88` | işleyicide `isManagement` (backend/services/community/main.go:257) | renovation_permits(+) | `renovation.request` → Approvers | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 9 | Düğme **Geri çek (pencere açar)** (satır 228) | `POST /renovations/:id/cancel` · community · `services/community/renovation.go:149` | oturum açmış herkes (site kapsamı) | renovation_permits(±) | yok | Panel/renovations, Sakin renovations, Yön.mobil renovations |

### create_request_screen
- **Dosya:** `mobile/lib/features/requests/presentation/screens/create_request_screen.dart`
- **Rota:** `create`
- **Ekranda:**
  - Başlık (satır 82): Yeni Talep
  - Pencere (satır 354): Talep Oluşturuldu
  - Pencere (satır 402): Tamam

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gönder (pencere açar)** (satır 96) | `POST /requests` · community · `services/community/main.go:82` | `resident_can_use` | requests(+) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |
| 2 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 125) | — | | | | |
| 3 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 244) | — | | | | |
| 4 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 385) | — | | | | |
| 5 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 414) | — | | | | |

### requests_screen
- **Dosya:** `mobile/lib/features/requests/presentation/screens/requests_screen.dart`
- **Rota:** `/requests`
- **Ekranda:**
  - Veri (satır 1): `GET /requests` (community)
  - Başlık (satır 68): Taleplerim
  - Sekmeler (satır 70): Güncel
  - Sekmeler (satır 70): Tamamlanmış

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yeni Talep (gider: createRequest)** (satır 72) | `GET /requests` · community · `services/community/main.go:81` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | — | yok | — |
| 2 | Düğme **Devam ediyor** (satır 132) | `POST /requests/:id/confirm-resolution` · community · `services/community/main.go:86` | oturum açmış herkes (site kapsamı) | requests(±) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |
| 3 | Düğme **Sorunum çözüldü** (satır 136) | `POST /requests/:id/confirm-resolution` · community · `services/community/main.go:86` | oturum açmış herkes (site kapsamı) | requests(±) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |

### create_reservation_screen
- **Dosya:** `mobile/lib/features/reservations/presentation/screens/create_reservation_screen.dart`
- **Rota:** `/reservation`
- **Ekranda:**
  - Veri (satır 1): `GET /facilities` (reservation); `GET /facilities/:id/slots` (reservation)
  - Başlık (satır 115): Rezervasyon Yap
  - Pencere (satır 246): Tamam
  - Mesaj (satır 260): Rezervasyon oluşturulamadı: ${toUserMessage(e)}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Rezervasyon Yap (pencere açar)** (satır 216) | `POST /reservations` · reservation · `services/reservation/main.go:147` | `resident_can_use` | reservations(+) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
| 2 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 254) | — | | | | |

### my_reservations_screen
- **Dosya:** `mobile/lib/features/reservations/presentation/screens/my_reservations_screen.dart`
- **Rota:** `/my-reservations`
- **Ekranda:**
  - Veri (satır 1): `GET /reservations` (reservation)
  - Pencere (satır 44): Rezervasyonu iptal et
  - Alan (satır 46): Gerekçe (isteğe bağlı)
  - Mesaj (satır 59): ${res[
  - Başlık (satır 70): Rezervasyonlarım

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 48) | — | | | | |
| 2 | Düğme **İptal et — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 49) | — | | | | |
| 3 | Düğme **Yeni (gider: createReservation)** (satır 71) | `GET /reservations` · reservation · `services/reservation/main.go:132` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 4 | Düğme **İptal (pencere açar)** (satır 106) | `POST /reservations/:id/cancel` · reservation · `services/reservation/main.go:238` | işleyicide `canManage` (backend/services/reservation/main.go:441) | reservations(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |

### surveys_mobile_screen
- **Dosya:** `mobile/lib/features/surveys/presentation/screens/surveys_mobile_screen.dart`
- **Rota:** `/surveys`
- **Ekranda:**
  - Veri (satır 1): `GET /surveys` (survey); `GET /surveys/:id` (survey); `GET /surveys/:id/comments` (survey)
  - Başlık (satır 58): Anketler
  - Mesaj (satır 162): ${res[
  - Başlık (satır 182): Anket
  - Alan (satır 237): Yorum (isteğe bağlı)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${s[ (gider: SurveyDetailScreen)** (satır 75) | `GET /surveys` · survey · `services/survey/main.go:70` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |
| 2 | Düğme **Oy Ver** (satır 242) | `POST /surveys/:id/vote` · survey · `services/survey/main.go:143` | serviste rol karşılaştırması: OWNER | survey_votes(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 3 | Düğme **Yorumları gör (pencere açar)** (satır 255) | `GET /surveys/:id/comments` · survey · `services/survey/main.go:119` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |

### market_request_screens
- **Dosya:** `mobile/lib/features/usta_hizmet/presentation/screens/market_request_screens.dart`
- **Rota:** `mesaj/:dispatchId`, `talep`, `talepler/:id`
- **Ekranda:**
  - Veri (satır 1): `GET /market/meta` (marketplace); `GET /market/requests/match-count` (marketplace); `GET /market/requests/:id` (marketplace); `GET /market/requests/:id/offers` (marketplace); `GET /market/requests/:id/messages/:dispatchId` (marketplace); `GET /market/requests/:id/job` (marketplace)
  - Dosya seçme (satır 5)
  - Dosya seçme (satır 5)
  - Dosya seçme (satır 67)
  - Mesaj (satır 71): Fotoğraf 5 MB sınırını aşıyor.
  - Mesaj (satır 99): Talebiniz ${r[
  - Başlık (satır 113): (dinamik)
  - Alan (satır 126): Kategori
  - Alan (satır 149): Ne yapılmasını istiyorsunuz?
  - Alan (satır 152): Uygun zaman (isteğe bağlı)
  - Başlık (satır 223): Talebim
  - Alan (satır 372): Yorumunuz (isteğe bağlı)
  - Başlık (satır 418): (dinamik)
  - Alan (satır 460): Mesajınız

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${c[** (satır 124) | `GET /market/requests/match-count` · marketplace · `services/marketplace/main.go:83` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | — | yok | — |
| 2 | Düğme **Fotoğraf ekle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 162) | — | | | | |
| 3 | Düğme **Gönderiliyor… / Talebi gönder** (satır 172) | `POST /market/requests` · marketplace · `services/marketplace/main.go:85` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_request_contacts(+), mp_request_dispatch(+), mp_requests(+), mp_request_dispatch(±), mp_supplier_accounts(±) · tetikleyici: mp_requests_active_property | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
|  | ↳ | `POST /market/requests/:id/photos` · marketplace · `services/marketplace/main.go:87` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | photo_moderation(+), mp_requests(±) · tetikleyici: mp_requests_active_property · dosya deposu | yok | Panel tedarikci/(panel)/isletmeler/[id], Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 4 | Düğme **Bu teklifi seç (pencere açar)** (satır 274) | `POST /market/requests/:id/offers/:offerId/select` · marketplace · `services/marketplace/main.go:91` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_jobs(+), mp_offers(±), mp_requests(±) · tetikleyici: mp_jobs_completed_refresh, mp_requests_active_property | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 5 | Düğme **Mesaj (gider: /usta/talepler/${widget.id}/mesaj/${o[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 282) | — | | | | |
| 6 | Düğme **Teklif seçmeden talebi kapat (pencere açar)** (satır 297) | `POST /market/requests/:id/close` · marketplace · `services/marketplace/main.go:92` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_offers(±), mp_requests(±) · tetikleyici: mp_requests_active_property | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 7 | Düğme **İş tamamlandı, onaylıyorum** (satır 350) | `POST /market/requests/:id/job/confirm` · marketplace · `services/marketplace/main.go:96` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_jobs(±) · tetikleyici: mp_jobs_completed_refresh | yok | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 8 | Düğme **İtiraz et (pencere açar)** (satır 352) | `POST /market/requests/:id/job/dispute` · marketplace · `services/marketplace/main.go:97` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_jobs(±) · tetikleyici: mp_jobs_completed_refresh | yok | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 9 | Düğme **$i yıldız — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 366) | — | | | | |
| 10 | Düğme **Puanı gönder** (satır 373) | `POST /market/requests/:id/review` · marketplace · `services/marketplace/main.go:98` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_reviews(+) · tetikleyici: mp_reviews_guard, mp_reviews_rating_refresh | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/puanlar, Panel tedarikci/(panel)/talepler/[id], Sakin market_requests, Yön.mobil site_markets |
| 11 | Düğme **Gönder** (satır 461) | `POST /market/requests/:id/messages/:dispatchId` · marketplace · `services/marketplace/main.go:94` | işleyicide `hasRole` (backend/services/settings/visibility.go:74) | mp_messages(+) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/talepler/[id], Sakin market_requests |

### usta_screen
- **Dosya:** `mobile/lib/features/usta_hizmet/presentation/screens/usta_screen.dart`
- **Rota:** `/usta`, `isletme/:id`
- **Ekranda:**
  - Veri (satır 1): `GET /market/meta` (marketplace); `GET /market/showcase` (marketplace); `GET /market/showcase/:id` (marketplace)
  - Başlık (satır 59): Usta & Hizmet
  - Sekmeler (satır 61): Yakınımdakiler
  - Sekmeler (satır 61): Taleplerim
  - Başlık (satır 192): İşletme

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Talep aç (gider: /usta/talep) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 63) | — | | | | |
| 2 | Düğme **${r[ (gider: /usta/talepler/${r[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 129) | — | | | | |
| 3 | Düğme **${b[ (gider: /usta/isletme/${b[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 165) | — | | | | |
| 4 | Düğme **Bu işletmeye talep gönder (gider: /usta/talep?isletme=${b[) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 218) | — | | | | |

### vehicles_screen
- **Dosya:** `mobile/lib/features/vehicles/presentation/screens/vehicles_screen.dart`
- **Rota:** `/vehicles`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity)
  - Başlık (satır 53): Araçlarım
  - Alan (satır 106): Plaka *
  - Alan (satır 106): 34 ABC 123
  - Alan (satır 109): Marka
  - Alan (satır 110): Model
  - Alan (satır 111): Renk

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 30) | — | | | | |
| 2 | Düğme **Araç ekle (pencere açar)** (satır 54) | `POST /vehicles` · parking · `services/parking/main.go:71` | `resident_can_use` | vehicles(+) | yok | Panel/parking, Yön.mobil parking_management |
| 3 | Düğme **Kaldır (pencere açar)** (satır 66) | `DELETE /vehicles/:id` · parking · `services/parking/main.go:89` | `resident_can_use` | vehicles(±) | yok | Panel/parking, Yön.mobil parking_management |
| 4 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 113) | — | | | | |

### violations_screen
- **Dosya:** `mobile/lib/features/violations/presentation/screens/violations_screen.dart`
- **Rota:** `/violations`
- **Ekranda:**
  - Veri (satır 1): `GET /violations` (community); `GET /site-rules` (community); `GET /units` (identity)
  - Mesaj (satır 68): Yönetim henüz kural tanımlamamış.
  - Pencere (satır 76): Kural ihlali bildir
  - Alan (satır 82): Kural
  - Alan (satır 91): Daire
  - Alan (satır 101): Ne oldu?
  - Alan (satır 101): Tarih, saat ve olayı yazın (en az 10 karakter)
  - Mesaj (satır 117): ${res[
  - Pencere (satır 128): Savunma
  - Alan (satır 130): Açıklamanız
  - Mesaj (satır 141): Savunmanız yönetime iletildi
  - Başlık (satır 151): Kural ihlalleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${r[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 80) | — | | | | |
| 2 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 89) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 108) | — | | | | |
| 4 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 109) | — | | | | |
| 5 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 132) | — | | | | |
| 6 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 133) | — | | | | |
| 7 | Düğme **Bildir (pencere açar)** (satır 152) | `POST /violations` · community · `services/community/violation.go:131` | işleyicide `isManagement` (backend/services/community/main.go:257) | rule_violation_events(+), rule_violations(+) | `violation.reported` → Approvers | Panel/violations, Sakin violations, Yön.mobil violations |
| 8 | Düğme **Savunma (pencere açar)** (satır 176) | `POST /violations/:id/respond` · community · `services/community/violation.go:173` | oturum açmış herkes (site kapsamı) | rule_violation_events(+), rule_violations(±) | `violation.response` → Approvers | Panel/violations, Sakin violations, Yön.mobil violations |

### my_visitors_screen
- **Dosya:** `mobile/lib/features/visitors/presentation/screens/my_visitors_screen.dart`
- **Rota:** `/my-visitors`
- **Ekranda:**
  - Pencere (satır 37): $name için yeni kod
  - Başlık (satır 60): Ziyaretçilerim

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **PIN mesajını kopyala — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 47) | — | | | | |
| 2 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 51) | — | | | | |
| 3 | Düğme **Ön kayıt (gider: visitorPreregister) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 61) | — | | | | |
| 4 | Düğme **Menü: Kodu yenile** (satır 107) | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 5 | Düğme **Menü: İptal et** (satır 108) | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |

### visitor_preregister_screen
- **Dosya:** `mobile/lib/features/visitors/presentation/screens/visitor_preregister_screen.dart`
- **Rota:** `/visitor-preregister`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity)
  - Başlık (satır 73): Ziyaretçi Ön Kayıt
  - Pencere (satır 426): Ön Kayıt Oluşturuldu
  - Pencere (satır 500): Tamam

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 95) | — | | | | |
| 2 | Düğme **Tarih — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 199) | — | | | | |
| 3 | Düğme **Saat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 240) | — | | | | |
| 4 | Düğme **Gönderiliyor… / Ön Kayıt Oluştur (pencere açar)** (satır 313) | `POST /visitors` · visitor · `services/visitor/main.go:100` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(+), visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 5 | Düğme **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 363) | — | | | | |
| 6 | Düğme **PIN mesajını kopyala — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 465) | — | | | | |
| 7 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 483) | — | | | | |
| 8 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 512) | — | | | | |
