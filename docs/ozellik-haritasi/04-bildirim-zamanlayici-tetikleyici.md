# 4. Bildirimler, zamanlanmış işler, bekçiler, tetikleyiciler

## 4.1 Bildirim kanalları ve nerede görüldükleri

- Kanallar: `IN_APP`, `PUSH`, `SMS` (Netgsm), `EMAIL` (SMTP) — `backend/pkg/notify/notify.go`. Sağlayıcısı yapılandırılmamış kanal "kuyrukta bekliyor" kalır; PUSH için sağlayıcı yok.
- Kategori: `TRANSACTIONAL` (onay gerekmez) / `COMMERCIAL` (6563 m.6 — önceden onay şart).
- **Kişinin kendi bildirim kutusu yalnız sakin uygulamasında var:** `GET /notifications` → Sakin `notifications_screen`. Panelde ve yönetici mobil uygulamasında kişisel kutu YOK; yönetime giden bildirimler panelde yalnız *Bildirimler* sayfasındaki giden kutusunda (`GET /notifications/outbox`, sitenin tüm bildirimleri) görülür.
- Gönderilmiş bildirim silinemez/değiştirilemez (tetikleyici `notifications_sent_final`); pasif sitede yeni bildirim yazılamaz (`notifications_active_property`).
- Alıcı kümeleri (`backend/pkg/notify/audience.go`): Residents (aktif sakinler, kişi başı tek), UnitResidents (dairenin aktif sakinleri), UnitUsers (daireyi kullananlar), AssessmentPayers (tahakkukun sorumlusu), BlockNeighbors (aynı blok), Tenants (kiracılar), UnitOwners (malikler), Managers (MANAGER/BOARD_MEMBER/AUDITOR), Approvers (MANAGER/BOARD_MEMBER), Operations (MANAGER/BOARD_MEMBER/STAFF).

## 4.2 İstek üzerine üretilen bildirimler (uç → konu → alıcı)

| Uç | Servis · kayıt | Konu | Alıcı |
|---|---|---|---|
| `POST /bulletins` | bulletin · `services/bulletin/main.go:85` | `bulletin.pending` | Approvers |
| `POST /bulletins/:id/approve` | bulletin · `services/bulletin/main.go:170` | `bulletin.decision` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /bulletins/:id/reject` | bulletin · `services/bulletin/main.go:183` | `bulletin.decision` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /emergency/checks` | community · `services/community/emergency.go:286` | `safety.check` | Residents |
| `POST /emergency/checks/:id/respond` | community · `services/community/emergency.go:326` | `safety.need_help` | Approvers |
| `POST /kvkk-requests` | community · `services/community/kvkk.go:52` | `kvkk.request` | Managers |
| `POST /kvkk-requests/:id/respond` | community · `services/community/kvkk.go:99` | `kvkk.response` | işlemin muhatabı (k.UserID) |
| `POST /announcements` | community · `services/community/main.go:138` | `announcement`, `announcement.urgent` | Residents |
| `POST /renovations` | community · `services/community/renovation.go:88` | `renovation.request` | Approvers |
| `POST /renovations/:id/approve` | community · `services/community/renovation.go:190` | `renovation.approved`, `renovation.neighbors` | BlockNeighbors, işlemin muhatabı (p.ApplicantID) |
| `POST /renovations/:id/reject` | community · `services/community/renovation.go:284` | `renovation.rejected` | işlemin muhatabı (p.ApplicantID) |
| `POST /renovations/:id/stop` | community · `services/community/renovation.go:302` | `renovation.stopped` | işlemin muhatabı (p.ApplicantID) |
| `POST /renovations/:id/complete` | community · `services/community/renovation.go:320` | `renovation.completed` | işlemin muhatabı (p.ApplicantID) |
| `POST /violations` | community · `services/community/violation.go:131` | `violation.reported` | Approvers |
| `POST /violations/:id/respond` | community · `services/community/violation.go:173` | `violation.response` | Approvers |
| `POST /violations/:id/dismiss` | community · `services/community/violation.go:221` | `violation.dismissed` | işlemin muhatabı (v.ReportedBy) |
| `POST /violations/:id/escalate` | community · `services/community/violation.go:240` | `violation.{{{strings}.ToLower}(…)}` | UnitResidents |
| `POST /finance/assessments` | finance · `services/finance/main.go:135` | `dues.created` | AssessmentPayers, NotifyCharges |
| `POST /finance/opening-balances` | finance · `services/finance/main.go:145` | `dues.created` | AssessmentPayers, NotifyCharges |
| `POST /finance/collections` | finance · `services/finance/main.go:155` | `payment.recorded` | AssessmentPayers |
| `POST /finance/bank-statements/lines/:id/collect` | finance · `services/finance/main.go:156` | `payment.recorded` | AssessmentPayers |
| `POST /governance/budgets/:id/assessments` | governance · `services/governance/main.go:92` | `dues.created` | AssessmentPayers, NotifyCharges |
| `POST /auth/password-reset/request` | identity · `services/identity/main.go:83` | `identity.self_reset` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/phone/request` | identity · `services/identity/main.go:104` | `identity.phone_change` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/phone/confirm` | identity · `services/identity/main.go:105` | `identity.phone_changed` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/email` | identity · `services/identity/main.go:106` | `identity.email_change` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/email/confirm` | identity · `services/identity/main.go:107` | `identity.email_changed` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/units/:id/invitations` | identity · `services/identity/main.go:111` | `identity.invitation` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/units/:id/tenancy-end` | identity · `services/identity/main.go:114` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/units/:id/tenancy-exit` | identity · `services/identity/main.go:115` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/tenancy-requests/:id/approve` | identity · `services/identity/main.go:117` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /users/me/tenancy-requests/:id/decline` | identity · `services/identity/main.go:118` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents` | identity · `services/identity/main.go:133` | `identity.activation` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/invitations` | identity · `services/identity/main.go:136` | `identity.invitation` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/tenancy-requests` | identity · `services/identity/main.go:140` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/tenancy-requests/:id/documents` | identity · `services/identity/main.go:141` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/tenancy-requests/:id/complete` | identity · `services/identity/main.go:142` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/tenancy-requests/:id/reverse` | identity · `services/identity/main.go:144` | `identity.tenancy` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/:id/activation-code` | identity · `services/identity/main.go:148` | `identity.activation` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /residents/:id/phone` | identity · `services/identity/main.go:151` | `identity.activation`, `identity.phone_changed` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /inventory/:id/movements` | inventory · `services/inventory/main.go:142` | `inventory.low_stock` | Managers |
| `POST /consumption/statements/:id/objections` | iot · `services/iot/main.go:472` | `statement.objection` | Approvers |
| `POST /consumption/objections/:id/respond` | iot · `services/iot/main.go:474` | `statement.objection.answer` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /notifications` | notification · `services/notification/main.go:158` | `{{in}.Topic}` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /packages` | package · `services/package/main.go:133` | `package.received` | UnitUsers |
| `POST /public/devices/heartbeat` | parking · `services/parking/devices.go:37` | — | Operations |
| `POST /patrols/:id/complete` | patrol · `services/patrol/main.go:187` | `patrol.issue` | Managers |
| `POST /reservations/:id/approve` | reservation · `services/reservation/main.go:283` | `reservation.decision` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /reservations/:id/reject` | reservation · `services/reservation/main.go:296` | `reservation.decision` | işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |
| `POST /settings/owner-visibility/:id/approve` | settings · `services/settings/main.go:146` | `visibility.policy` | Tenants |
| `POST /settings/owner-visibility/:id/reject` | settings · `services/settings/main.go:147` | `visibility.policy` | Tenants |
| `POST /surveys/:id/publish` | survey · `services/survey/main.go:195` | `survey.published` | Residents |
| `POST /visitors/verify-pass` | visitor · `services/visitor/main.go:174` | `visitor.checkin` | UnitUsers |
| `POST /visitors/:id/check-in` | visitor · `services/visitor/main.go:175` | `visitor.checkin` | UnitUsers |

## 4.3 Zamanlanmış işler (`backend/cmd/scheduler`, varsayılan 15 dk'da bir, `SCHEDULER_INTERVAL`)

| İş | Ne yapar | Konu | Alıcı | Kod |
|---|---|---|---|---|
| dues.overdue | Vadesi geçmiş aidat: daireye ayda en fazla bir hatırlatma; kiracı sorumluluğundaysa malike de | `dues.overdue`, `dues.overdue.tenant` | AssessmentPayers; UnitOwners | `backend/cmd/scheduler/jobs.go:93` |
| contract.notice | İhbar son günü yaklaşan/geçen sözleşme | `contract.notice` | Managers | `jobs.go:221` |
| contract.expired | Süresi dolduğu hâlde ACTIVE sözleşme | `contract.expired` | Managers | `jobs.go:302` |
| patrol.overdue | Beklenen süre + tolerans aşılmış açık devriye | `patrol.overdue` | Managers | `jobs.go:361` |
| asset.maintenance | Bakım/periyodik kontrol tarihi yaklaşan/geçen demirbaş | `asset.maintenance.*` | Managers | `jobs.go:431` |
| kvkk.due | KVKK m.13 yanıt süresi dolmak üzere/dolmuş başvuru | `kvkk.due.*` | Managers | `jobs.go:495` |
| budget.approval | Geçici işletme projesinin genel kurul süresi (KMK m.37, 3 ay) | `budget.approval.*` | Managers | `jobs.go:555` |
| emergency.drill | Yıllık tatbikat süresi geçmiş / hiç tatbikat yok | `emergency.drill` | Managers | `jobs.go:618` |
| compliance.employer | SGK işe giriş/çıkış, MUHSGK/prim son günü | `compliance.*` | Managers | `jobs.go:670` |
| kvkk.destruction | Saklama süresi dolan ziyaretçi/otopark/kargo kayıtlarını anonimleştirir (≤6 ayda bir); süre tanımsızsa hatırlatır | `kvkk.destruction.done`, `kvkk.destruction.undefined` | Managers | `jobs.go:721` |
| dask.renewal | 30 gün içinde biten/bitmiş DASK poliçesi | `dask.*` | UnitResidents (malik) | `jobs.go:775` |

Mükerrer gönderim `DedupeKey` ile engellenir (ör. `dues.overdue:<daire>:<ay>`, `jobs.go:209`).

## 4.4 Servis içi bekçiler

| Bekçi | Aralık | Ne yapar | Kod |
|---|---|---|---|
| Kart ödemesi uzlaştırma | 1 dk (`CARD_RECONCILE_INTERVAL`), 20 dk'dan eski askıdaki ödemeler (`CARD_RECONCILE_AGE`) | Sonucu iyzico'dan yeniden sorgular, askıda ödeme bırakmaz | `backend/services/finance/card.go:85` |
| Geçiş cihazı canlılığı | 30 sn (`DEVICE_WATCH_INTERVAL`) | Sinyal kesilen cihaz için olay açar; `device.offline`/`device.recovered` bildirimi → Operations | `backend/services/parking/devices.go:144` |
| Kargo teslim kanıtı imhası | 15 dk (`PACKAGE_PURGE_INTERVAL`) | Silme kuyruğundaki kanıt dosyalarını depodan siler | `backend/services/package/proof.go:296` |

## 4.5 Veritabanı tetikleyicileri (son tanım geçerli)

| Tablo | Tetikleyici | Ne zaman | Etki / engel | Migration |
|---|---|---|---|---|
| book_entries | book_entries_no_update | BEFORE UPDATE OR DELETE | engeller: Defter kaydı değiştirilemez veya silinemez (KMK m.32/36). Düzeltme için yeni kayıt açın. | 014_governance.sql |
| consumption_statement_objections | consumption_statement_objections_guard | BEFORE UPDATE | engeller: Yanıtlanmış itiraz değiştirilemez | 063_statement_objections.sql |
| credit_notes | credit_notes_guard | BEFORE UPDATE | engeller: Alacak dekontu değiştirilemez; yalnızca bir kez gerekçeli ters kaydı yapılabilir | 059_credit_notes_bank_statements.sql |
| document_access_logs | document_access_logs_no_update | BEFORE UPDATE OR DELETE | engeller: document_access_logs yalnızca eklenebilir; güncelleme/silme yasaktır (KVKK m.12) | 015_documents.sql |
| documents | documents_supersede | AFTER INSERT | UPDATE documents | 015_documents.sql |
| expenses | expense_updated_at | BEFORE UPDATE | satırı düzenler (NEW) | 004_expense_management.sql |
| late_fee_accruals | late_fee_accruals_active_property | BEFORE INSERT | engeller: site pasif: gecikme tazminatı işletilemez | 058_property_lifecycle.sql |
| legal_parameters | legal_parameters_guard | BEFORE INSERT OR UPDATE | engeller: Parametre "%" kanunla sabittir; site bazında değiştirilemez (KMK). | 012_legal_parameters.sql |
| monthly_assessments | monthly_assessments_active_property | BEFORE INSERT | engeller: site pasif: % tablosuna yeni kayıt yazılamaz | 058_property_lifecycle.sql |
| monthly_assessments | monthly_assessments_active_property_increase | BEFORE UPDATE OF total_amount, late_fee | engeller: site pasif: tahakkuk tutarı artırılamaz | 058_property_lifecycle.sql |
| monthly_assessments | monthly_assessments_guard | BEFORE UPDATE | engeller: Tahakkukun sınıfı (kullanım/malik) değiştirilemez; düzeltme alacak dekontu ve yeni tahakkukla yapılır | 070_debt_responsibility.sql |
| monthly_assessments | trg_monthly_assessments_tenant_link | BEFORE INSERT | satırı düzenler (NEW) | 070_debt_responsibility.sql |
| notifications | notifications_active_property | BEFORE INSERT | engeller: site pasif: % tablosuna yeni kayıt yazılamaz | 058_property_lifecycle.sql |
| notifications | notifications_sent_final | BEFORE UPDATE OR DELETE | engeller: Gönderilmiş bildirim silinemez (haber verildiğinin kanıtıdır) | 016_notifications.sql |
| owner_visibility_policies | trg_owner_visibility_guard | BEFORE UPDATE | engeller: Görünürlük önerisi değiştirilemez; yeni öneri açılmalı | 071_owner_visibility.sql |
| payment_assessments | payment_assessments_guard | BEFORE UPDATE | engeller: Ödeme-tahakkuk bağı değiştirilemez | 054_financial_immutability.sql |
| payments | payments_guard | BEFORE UPDATE | engeller: Sonuçlanmış ödeme silinemez | 061_management_collections.sql |
| payroll | payroll_guard | BEFORE UPDATE | engeller: Sonuçlanmış bordro kaydı değiştirilemez (durum: %) | 047_payroll_records.sql |
| property_setting_history | property_setting_history_no_change | BEFORE UPDATE OR DELETE | engeller: property_setting_history yalnızca eklenebilir; değiştirilemez ve silinemez | 017_property_settings.sql |
| property_settings | property_settings_guard_legal_key | BEFORE INSERT OR UPDATE OF setting_key | engeller: Mevzuat parametresi (%) site ayarı olarak yazılamaz; legal_parameters tablosundadır | 038_settings_legal_key_guard.sql |
| resident_units | trg_resident_units_tenancy_guard | BEFORE UPDATE OF is_active, role | engeller: Kiracılık yalnız bitiş akışıyla biter (kiracının onayı, kendi çıkışı ya da yönetim yolu) | 069_tenancy_endings.sql |
| resident_units | trg_resident_units_tenant_arrival | AFTER INSERT OR UPDATE OF is_active, role | UPDATE resident_units | 068_tenancy_invitations.sql |
| resident_units | trg_resident_units_tenant_departure | AFTER UPDATE OF is_active | UPDATE resident_units | 069_tenancy_endings.sql |

## 4.6 Denetim izi

Her serviste API grubu `middleware.AuditLog` ile sarılı (`backend/pkg/middleware/auth.go:162`): GET dahil her istek `audit_logs`'a `VIEW/CREATE/UPDATE/DELETE` olarak, 403'ler `DENIED` olarak yazılır; 401'ler yazılmaz. Ek olarak: `document_access_logs` (belge erişimi, salt-ekleme), personel kişisel verisinin maskesiz görüntülenmesi `PII_REVEAL`. Panelde denetim izini listeleyen bir sayfa yoktur.
