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
| 1 | Düğme **Yeniden gönder (${_cooldown}s) / Kodu SMS ile gönder** (satır 165) | `POST /auth/password-reset/request` · identity · `services/identity/main.go:81` | oturum açmış herkes (site kapsamı) | user_activation_codes(+), user_activation_codes(±) | `identity.self_reset` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 2 | Düğme **Şifremi Belirle (gider: /login)** (satır 196) | `POST /auth/activate` · identity · `services/identity/main.go:79` | oturum açmış herkes (site kapsamı) | resident_units(+), user_token_invalidation(+), resident_invitations(±), user_activation_codes(±), users(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management, Yön.mobil visitor_management |

### kvkk_consent_screen
- **Dosya:** `mobile/lib/features/auth/presentation/screens/kvkk_consent_screen.dart`
- **Rota:** `/kvkk-consent`
- **Ekranda:**
  - Mesaj (satır 27): Onay kaydedilemedi, lütfen tekrar deneyin
  - Başlık (satır 40): Kişisel Verilerin Korunması

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onaylıyorum ve Devam Ediyorum (gider: /)** (satır 84) | `POST /users/me/kvkk-consent` · identity · `services/identity/main.go:97` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |

### login_screen
- **Dosya:** `mobile/lib/features/auth/presentation/screens/login_screen.dart`
- **Rota:** `/login`
- **Ekranda:**
  - Alan (satır 105): Telefon Numarası
  - Alan (satır 107): 0555 123 45 67 · yurt dışı: +49 …
  - Alan (satır 126): Şifre
  - Mesaj (satır 234): Giriş başarısız: telefon veya şifre hatalı
  - Pencere (satır 252): Biyometrik Giriş
  - Mesaj (satır 290): Oturum yenilenemedi, lütfen şifrenizle giriş yapın
  - Mesaj (satır 296): Biyometrik doğrulama başarısız

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 128) | — | | | | |
| 2 | Düğme **Şifremi Unuttum (gider: /activate) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 153) | — | | | | |
| 3 | Düğme **Giriş Yap (gider: /kvkk-consent, /; pencere açar)** (satır 161) | `POST /auth/login` · identity · `services/identity/main.go:76` | oturum açmış herkes (site kapsamı) | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 4 | Düğme **Biyometrik Giriş (gider: /) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 178) | — | | | | |
| 5 | Düğme **Hesabı Etkinleştir (gider: /activate) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 198) | — | | | | |
| 6 | Düğme **Hayır — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 258) | — | | | | |
| 7 | Düğme **Etkinleştir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 262) | — | | | | |

### bulletin_board_mobile_screen
- **Dosya:** `mobile/lib/features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart`
- **Rota:** `/bulletin`
- **Ekranda:**
  - Veri (satır 1): `GET /bulletins` (bulletin)
  - Başlık (satır 70): İlan Panosu
  - Alan (satır 192): Kategori
  - Alan (satır 198): Başlık
  - Alan (satır 204): Açıklama
  - Alan (satır 211): Fiyat (₺, isteğe bağlı)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İlan Ver (pencere açar)** (satır 71) | `POST /bulletins` · bulletin · `services/bulletin/main.go:85` | oturum açmış herkes (site kapsamı) | bulletin_posts(+) | `bulletin.pending` → Approvers | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 2 | Düğme **Kapat** (satır 148) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | oturum açmış herkes (site kapsamı) | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 3 | Seçim **Kategori — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 190) | — | | | | |
| 4 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 220) | — | | | | |

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
| 4 | Düğme **Poliçe gir (pencere açar)** (satır 113) | `POST /insurance/dask` · contract · `services/contract/main.go:71` | oturum açmış herkes (site kapsamı) | unit_insurance_policies(+) | yok | Panel/insurance, Sakin dask |

### documents_screen
- **Dosya:** `mobile/lib/features/documents/presentation/screens/documents_screen.dart`
- **Rota:** `/documents`
- **Ekranda:**
  - Veri (satır 1): `GET /documents` (document); `GET /documents/:id/download` (document)
  - Başlık (satır 113): Belgeler

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${d[** (satır 130) | `GET /documents/:id/download` · document · `services/document/main.go:135` | işleyicide `hasRole` (backend/services/settings/visibility.go:74); işleyicide `isManagement` (backend/services/community/main.go:257) | document_access_logs(+) · tetikleyici: document_access_logs_no_update · dosya deposu | yok | — |

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
| 1 | Düğme **Güvendeyim** (satır 140) | `POST /emergency/checks/:id/respond` · community · `services/community/emergency.go:326` | `resident_can_use` | safety_check_responses(+) | `safety.need_help` → Approvers | Panel/emergency, Sakin emergency |
| 2 | Düğme **Yardım gerekiyor** (satır 143) | `POST /emergency/checks/:id/respond` · community · `services/community/emergency.go:326` | `resident_can_use` | safety_check_responses(+) | `safety.need_help` → Approvers | Panel/emergency, Sakin emergency |
| 3 | Düğme **Acil bilgi kartım (gider: EmergencyCardScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 174) | — | | | | |
| 4 | Düğme **Açık rızamla kaydet** (satır 290) | `PUT /emergency/cards/me` · community · `services/community/emergency.go:202` | `resident_can_use` | resident_emergency_cards(+) | yok | Panel/emergency, Sakin emergency |
| 5 | Düğme **Kartımı ve rızamı sil** (satır 294) | `DELETE /emergency/cards/me` · community · `services/community/emergency.go:242` | oturum açmış herkes (site kapsamı) | resident_emergency_cards(−) | yok | Panel/emergency, Sakin emergency |

### energy_consumption_mobile_screen
- **Dosya:** `mobile/lib/features/energy/presentation/screens/energy_consumption_mobile_screen.dart`
- **Rota:** `/energy`
- **Ekranda:**
  - Veri (satır 1): `GET /consumption/statements` (iot); `GET /consumption/objections` (iot); `GET /consumption/statements/:id/pdf` (iot); `GET /finance/consumption/summary` (finance)
  - Pencere (satır 398): Pusulaya itiraz
  - Alan (satır 405): Gerekçe
  - Alan (satır 406): Ör. sayaçta okunan değer, okuma tarihi, fotoğrafınızın tarihi

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 234) | — | | | | |
| 2 | Düğme **PDF** (satır 343) | `GET /consumption/statements/:id/pdf` · iot · `services/iot/main.go:470` | `resident_can_use` | — | yok | — |
| 3 | Düğme **İtiraz et (pencere açar)** (satır 370) | `POST /consumption/statements/:id/objections` · iot · `services/iot/main.go:472` | `resident_can_use` | consumption_statement_objections(+) · tetikleyici: consumption_statement_objections_guard | `statement.objection` → Approvers | Panel/meters, Sakin energy_consumption_mobile |
| 4 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 409) | — | | | | |
| 5 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 410) | — | | | | |

### dues_payment_screen
- **Dosya:** `mobile/lib/features/finance/presentation/screens/dues_payment_screen.dart`
- **Rota:** `payment`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/properties` (identity); `GET /finance/clearance-certificates/:id/pdf` (finance); `GET /finance/credit-notes` (finance); `GET /finance/credit-notes/:id/pdf` (finance); `GET /finance/ledger/verify` (finance); `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance); `GET /finance/payments/:id/status` (finance)
  - Dosya seçme (satır 20)
  - Dosya seçme (satır 20)
  - Başlık (satır 98): Aidat Ödeme
  - Pencere (satır 373): Borcu yoktur belgesi
  - Pencere (satır 394): Alacak dekontlarım
  - Pencere (satır 453): Tahsilat kayıtları
  - Pencere (satır 470): Ödeme Onayı
  - Alan (satır 498): Havale açıklaması / dekont no (isteğe bağlı)
  - Pencere (satır 539): Ödeme oluşturulamadı
  - Pencere (satır 566): Ödeme işlemde
  - Pencere (satır 616): Tamam
  - Dosya seçme (satır 640)
  - Pencere (satır 668): Tutar: ${formatTry(amount)}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Borcu yoktur belgesi (pencere açar)** (satır 103) | `POST /finance/clearance-certificates` · finance · `services/finance/main.go:103` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | clearance_certificates(+) | yok | Panel/units, Sakin dues_payment |
| 2 | Düğme **Alacak dekontlarım (pencere açar)** (satır 109) | `GET /finance/credit-notes` · finance · `services/finance/main.go:107` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/credit-notes/:id/pdf` · finance · `services/finance/main.go:108` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
| 3 | Düğme **Tahsilat kayıtlarını doğrula (pencere açar)** (satır 115) | `GET /finance/ledger/verify` · finance · `services/finance/main.go:99` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 4 | Düğme **Ödenecek tahakkuk yok / ${formatTry(_currentBalance)} Öde (pencere açar; dış bağlantı/arama)** (satır 333) | `POST /finance/payments/:id/receipts` · finance · `services/finance/main.go:96` | oturum açmış herkes (site kapsamı) | payment_receipts(+) · dosya deposu | yok | Panel/accounting, Yön.mobil payments |
|  | ↳ | `POST /finance/payments` · finance · `services/finance/main.go:92` | `assessment_visible_to` | late_fee_accruals(+), payment_assessments(+), payments(+), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil payments, Yön.mobil smart_collection |
| 5 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 376) | — | | | | |
| 6 | Düğme **PDF** (satır 412) | `GET /finance/credit-notes/:id/pdf` · finance · `services/finance/main.go:108` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
| 7 | Düğme **Kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 421) | — | | | | |
| 8 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 456) | — | | | | |
| 9 | Düğme **Havaleyi yaptığınız gün — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 479) | — | | | | |
| 10 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 505) | — | | | | |
| 11 | Düğme **Devam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 508) | — | | | | |
| 12 | Düğme **Tamam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 543) | — | | | | |
| 13 | Düğme **Arka planda bekle** (satır 581) | `GET /finance/debt-status` · finance · `services/finance/main.go:89` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
| 14 | Düğme **Tamam** (satır 620) | `GET /finance/debt-status` · finance · `services/finance/main.go:89` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |
| 15 | Düğme **Dekont ekle** (satır 696) | `POST /finance/payments/:id/receipts` · finance · `services/finance/main.go:96` | oturum açmış herkes (site kapsamı) | payment_receipts(+) · dosya deposu | yok | Panel/accounting, Yön.mobil payments |
| 16 | Düğme **Tamam** (satır 704) | `GET /finance/debt-status` · finance · `services/finance/main.go:89` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |

### finance_screen
- **Dosya:** `mobile/lib/features/finance/presentation/screens/finance_screen.dart`
- **Rota:** `/finance`
- **Ekranda:**
  - Veri (satır 1): `GET /finance/debt-status` (finance); `GET /finance/assessments` (finance)
  - Başlık (satır 76): Finansal Durumum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Öde (gider: duesPayment)** (satır 161) | `GET /finance/debt-status` · finance · `services/finance/main.go:89` | `assessment_visible_to` | — | yok | — |
|  | ↳ | `GET /finance/assessments` · finance · `services/finance/main.go:90` | `assessment_visible_to` | — | yok | — |

### main_screen
- **Dosya:** `mobile/lib/features/home/presentation/screens/main_screen.dart`
- **Ekranda:**
  - Pencere (satır 20): Uygulamadan çık

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 24) | — | | | | |
| 2 | Düğme **Çık — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 28) | — | | | | |

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
| 1 | Düğme **Yeniden dene** (satır 82) | `GET /users/me/invitations` · identity · `services/identity/main.go:121` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 2 | Düğme **Reddet** (satır 109) | `POST /users/me/invitations/:id/accept` · identity · `services/identity/main.go:122` | oturum açmış herkes (site kapsamı) | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil visitor_management |
| 3 | Düğme **Kabul et** (satır 114) | `POST /users/me/invitations/:id/accept` · identity · `services/identity/main.go:122` | oturum açmış herkes (site kapsamı) | resident_units(+), resident_invitations(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil visitor_management |

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
| 4 | Düğme **Başvuru yap (pencere açar)** (satır 104) | `POST /kvkk-requests` · community · `services/community/kvkk.go:52` | oturum açmış herkes (site kapsamı) | kvkk_requests(+) | `kvkk.request` → Managers | Panel/kvkk, Sakin kvkk_requests |
| 5 | Düğme **Ortak alan kameraları (gider: CamerasScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 127) | — | | | | |

### more_screen
- **Dosya:** `mobile/lib/features/more/presentation/screens/more_screen.dart`
- **Rota:** `/more`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me` (identity)
  - Başlık (satır 73): Daha Fazla
  - Pencere (satır 253): Çıkış Yap

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Bildirimlerim (gider: notifications) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 78) | — | | | | |
| 2 | Düğme **Duyurular (gider: announcements) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 83) | — | | | | |
| 3 | Düğme **Anketler (gider: surveys) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 88) | — | | | | |
| 4 | Düğme **İlan Panosu (gider: bulletin) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 93) | — | | | | |
| 5 | Düğme **Kargo Takibi (gider: packages) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 98) | — | | | | |
| 6 | Düğme **Rezervasyonlarım (gider: myReservations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 7 | Düğme **Ziyaretçi Ön Kaydı (gider: visitorPreregister) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 108) | — | | | | |
| 8 | Düğme **Tüketim (gider: energy) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 113) | — | | | | |
| 9 | Düğme **Belgeler (gider: documents) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 118) | — | | | | |
| 10 | Düğme **DASK poliçem (gider: dask) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 123) | — | | | | |
| 11 | Düğme **Ortak alan geliri payım (gider: commonIncome) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 128) | — | | | | |
| 12 | Düğme **Acil durum (gider: emergency) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 133) | — | | | | |
| 13 | Düğme **Kural ihlali bildir (gider: violations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 138) | — | | | | |
| 14 | Düğme **Tadilat izni (gider: renovations) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 143) | — | | | | |
| 15 | Düğme **KVKK başvurusu (gider: kvkk) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 148) | — | | | | |
| 16 | Düğme **Profil ve Ayarlar (gider: profile) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 154) | — | | | | |
| 17 | Düğme **Hakkında — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 159) | — | | | | |
| 18 | Düğme **Çıkış Yap (gider: /login; pencere açar)** (satır 165) | `POST /auth/logout` · identity · `services/identity/main.go:85` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 19 | Düğme **Profili düzenle (gider: profile) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 229) | — | | | | |
| 20 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 257) | — | | | | |
| 21 | Düğme **Çıkış Yap — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 260) | — | | | | |
| 22 | Düğme **? — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 291) | — | | | | |

### notifications_screen
- **Dosya:** `mobile/lib/features/notifications/presentation/screens/notifications_screen.dart`
- **Rota:** `/notifications`
- **Ekranda:**
  - Veri (satır 1): `GET /notifications` (notification)
  - Başlık (satır 47): Bildirimlerim

### package_tracking_mobile_screen
- **Dosya:** `mobile/lib/features/packages/presentation/screens/package_tracking_mobile_screen.dart`
- **Rota:** `/packages`
- **Ekranda:**
  - Veri (satır 1): `GET /packages` (package)
  - Başlık (satır 50): Kargolarım

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
  - Mesaj (satır 329): Tercih kaydedilemedi: ${toUserMessage(e)}
  - Pencere (satır 373): Çıkış Yap

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${units[i][ (gider: UnitResidentsScreen) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 190) | — | | | | |
| 2 | Düğme **E-posta (pencere açar)** (satır 211) | `POST /users/me/email` · identity · `services/identity/main.go:104` | oturum açmış herkes (site kapsamı) | email_change_requests(+), email_change_requests(±) | `identity.email_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/email/confirm` · identity · `services/identity/main.go:105` | oturum açmış herkes (site kapsamı) | email_change_requests(±), users(±) | `identity.email_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 3 | Düğme **Telefon (gider: /login; pencere açar)** (satır 220) | `POST /users/me/phone/request` · identity · `services/identity/main.go:102` | oturum açmış herkes (site kapsamı) | phone_change_requests(+), phone_change_requests(±) | `identity.phone_change` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
|  | ↳ | `POST /users/me/phone/confirm` · identity · `services/identity/main.go:103` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), phone_change_requests(±), users(±) | `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 4 | Düğme **Şifre Değiştir (gider: /login; pencere açar)** (satır 263) | `POST /users/me/password` · identity · `services/identity/main.go:100` | oturum açmış herkes (site kapsamı) | user_token_invalidation(+), users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 5 | Düğme **KVKK Aydınlatma Metni (gider: kvkkConsent) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 281) | — | | | | |
| 6 | Düğme **Çıkış Yap (gider: /login; pencere açar)** (satır 298) | `POST /auth/logout` · identity · `services/identity/main.go:85` | oturum açmış herkes (site kapsamı) | revoked_tokens(+) | yok |  |
| 7 | Düğme **İptal — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 378) | — | | | | |
| 8 | Düğme **Çıkış Yap — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 381) | — | | | | |

### tenancy_requests_screen
- **Dosya:** `mobile/lib/features/profile/presentation/screens/tenancy_requests_screen.dart`
- **Ekranda:**
  - Veri (satır 1): `GET /users/me/tenancy-requests` (identity); `GET /users/me/tenancy-requests/:id/documents/:docId` (identity)
  - Mesaj (satır 87): ${res[
  - Pencere (satır 98): Vazgeç
  - Pencere (satır 120): Vazgeç
  - Mesaj (satır 138): Belge indirildi ama açılamadı: ${r.message}
  - Başlık (satır 216): Kiracılık işlemleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 102) | — | | | | |
| 2 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 3 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 124) | — | | | | |
| 4 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 125) | — | | | | |
| 5 | Düğme **Reddet (pencere açar)** (satır 152) | `POST /users/me/tenancy-requests/:id/approve` · identity · `services/identity/main.go:115` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil energy_dashboard, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil governance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil visitor_management |
| 6 | Düğme **Onayla** (satır 161) | `POST /users/me/tenancy-requests/:id/approve` · identity · `services/identity/main.go:115` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil energy_dashboard, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil governance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil visitor_management |
| 7 | Düğme **İtiraz et (pencere açar)** (satır 171) | `POST /users/me/tenancy-requests/:id/object` · identity · `services/identity/main.go:117` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests |
| 8 | Düğme **Geri çek** (satır 180) | `POST /users/me/tenancy-requests/:id/cancel` · identity · `services/identity/main.go:118` | oturum açmış herkes (site kapsamı) | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests |
| 9 | Düğme **${_docKind[** (satır 202) | `GET /users/me/tenancy-requests/:id/documents/:docId` · identity · `services/identity/main.go:119` | oturum açmış herkes (site kapsamı) | — · dosya deposu | yok | — |

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
| 13 | Düğme **Davet gönder (pencere açar)** (satır 313) | `POST /users/me/units/:id/invitations` · identity · `services/identity/main.go:109` | oturum açmış herkes (site kapsamı) | resident_invitations(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) | `identity.invitation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_reservations, Sakin notifications, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil payments, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil survey_management |
| 14 | Düğme **Bitir (pencere açar)** (satır 351) | `POST /users/me/units/:id/residents/:residentId/end` · identity · `services/identity/main.go:110` | oturum açmış herkes (site kapsamı) | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Sakin visitor_preregister, Yön.mobil add_resident, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil finance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil resident_detail, Yön.mobil residents, Yön.mobil visitor_management |

### renovations_screen
- **Dosya:** `mobile/lib/features/renovation/presentation/screens/renovations_screen.dart`
- **Rota:** `/renovations`
- **Ekranda:**
  - Veri (satır 1): `GET /renovations` (community); `GET /users/me/properties` (identity)
  - Mesaj (satır 82): Tadilat başvurusunu dairenin maliki ya da vekili yapabilir.
  - Pencere (satır 96): Tadilat başvurusu
  - Alan (satır 104): Daire
  - Alan (satır 114): Kapsam
  - Alan (satır 128): Yapılacak iş
  - Alan (satır 128): En az 10 karakter
  - Alan (satır 130): Usta / firma (isteğe bağlı)
  - Mesaj (satır 170): Başvurunuz alındı. ${res[
  - Başlık (satır 180): Tadilat izinleri

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Seçim **${u[ — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 101) | — | | | | |
| 2 | Seçim **Kapsam — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 111) | — | | | | |
| 3 | Düğme **Tarih: ${formatDate(apiDate(start))} – ${formatDate(apiDate(end))} — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 131) | — | | | | |
| 4 | Düğme **Vazgeç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 153) | — | | | | |
| 5 | Düğme **Gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 154) | — | | | | |
| 6 | Düğme **Başvuru yap (pencere açar)** (satır 181) | `POST /renovations` · community · `services/community/renovation.go:88` | işleyicide `isManagement` (backend/services/community/main.go:257) | renovation_permits(+) | `renovation.request` → Approvers | Panel/renovations, Sakin renovations |

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
| 1 | Düğme **Yeni Talep (gider: createRequest)** (satır 72) | `GET /requests` · community · `services/community/main.go:81` | oturum açmış herkes (site kapsamı) | — | yok | — |
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
| 3 | Düğme **Yeni (gider: createReservation)** (satır 71) | `GET /reservations` · reservation · `services/reservation/main.go:132` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 4 | Düğme **İptal (pencere açar)** (satır 106) | `POST /reservations/:id/cancel` · reservation · `services/reservation/main.go:238` | işleyicide `canManage` (backend/services/reservation/main.go:441) | reservations(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |

### surveys_mobile_screen
- **Dosya:** `mobile/lib/features/surveys/presentation/screens/surveys_mobile_screen.dart`
- **Rota:** `/surveys`
- **Ekranda:**
  - Veri (satır 1): `GET /surveys` (survey); `GET /surveys/:id` (survey)
  - Başlık (satır 58): Anketler
  - Mesaj (satır 134): ${res[
  - Başlık (satır 154): Anket
  - Alan (satır 209): Yorum (isteğe bağlı)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **${s[ (gider: SurveyDetailScreen)** (satır 75) | `GET /surveys` · survey · `services/survey/main.go:70` | işleyicide `isManagement` (backend/services/community/main.go:257) | — | yok | — |
| 2 | Düğme **Oy Ver** (satır 214) | `POST /surveys/:id/vote` · survey · `services/survey/main.go:143` | oturum açmış herkes (site kapsamı) | survey_votes(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil survey_management |

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
| 7 | Düğme **Bildir (pencere açar)** (satır 152) | `POST /violations` · community · `services/community/violation.go:131` | işleyicide `isManagement` (backend/services/community/main.go:257) | rule_violation_events(+), rule_violations(+) | `violation.reported` → Approvers | Panel/violations, Sakin violations |
| 8 | Düğme **Savunma (pencere açar)** (satır 176) | `POST /violations/:id/respond` · community · `services/community/violation.go:173` | oturum açmış herkes (site kapsamı) | rule_violation_events(+), rule_violations(±) | `violation.response` → Approvers | Panel/violations, Sakin violations |

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
