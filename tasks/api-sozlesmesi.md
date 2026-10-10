# API Sözleşmesi — 26 servis (koddan çıkarıldı, 2026-09-26)

> **Kaynak:** servislerin `main.go` / handler / model kodu satır satır okunarak çıkarıldı;
> ardından sertleştirme turunda (commit `ae4678a`) düzeltilen durum kodları işlendi.
> **Gateway:** tüm yollar `http(s)://<gateway>/api/v1/...`; gateway her rotayı doğru
> servise iletir (`check-gateway-routes.py` statik, `gateway-routing-probe.py` çalışma
> anında doğrular). Yeni rota eklendiğinde bu belge ve gateway tablosu güncellenir.

## Ortak kurallar

- **Kimlik:** `/auth/*` dışında her uç `Authorization: Bearer <erişim jetonu>` ister.
  401: jeton yok/geçersiz/iptal. 503: iptal denetimi yapılamadı (fail-closed).
- **Roller:** `MANAGER`, `BOARD_MEMBER`, `AUDITOR`, `STAFF` (site rolleri, `property_roles`);
  `OWNER`, `TENANT`, `PROXY`/`RESIDENT` (sakinlik). Kısaltmalar: **M** yönetici, **B** kurul
  üyesi, **A** denetçi (okur, yazamaz — KMK m.41), **S** görevli. `RequireRole` 403 döner.
- **Liste sözleşmesi:** `{"data": [...]}` — boşsa `[]`, asla `null`.
- **Hata gövdesi:** `{"error": "..."}` (+ bazen `note`, `valid`/`valid_types`).
- **Durum kodları (sertleştirme sonrası):**
  - 400: biçim hatası (zorunlu alan yok, gövdede UUID olmayan kimlik, uzunluk aşımı)
  - 403: yetki yok / başkasının kaydı (bazı yerlerde varlık gizlemek için 404)
  - 404: kayıt yok, başka siteye ait ya da yol kimliği UUID değil
  - 409: kayıt var ama durumu uygun değil (zaten onaylanmış, kapalı…) / benzersizlik
  - 422: iş kuralı ya da izin verilmeyen değer (yanıtta geçerli liste bulunur)
  - 500: yalnızca gerçek sunucu arızası
- **Tarih:** `YYYY-MM-DD`; zaman damgası RFC3339. **Para:** TL float (yeni kod kuruş int).

---

## identity (8081)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `POST /auth/login` | açık | `phone`*, `password`* (0xxx/10 hane → +90) | `{access_token, refresh_token, expires_in, user:{id,first_name,last_name,phone,email,active_property_id,roles[],properties[],kvkk_consent_required}}` · 401 yanlış/pasif hesap |
| `POST /auth/refresh` | açık | `refresh_token`* | `{access_token, refresh_token, expires_in}` · 401. **Jeton tek kullanımlık:** yanıttaki YENİ `refresh_token` saklanmalı. Aynı jeton 30 sn sonra yeniden sunulursa bütün oturumlar kapanır (401 + `note`) |
| `POST /auth/logout` | jeton | `refresh_token` (verin — yoksa 7 gün geçerli kalır) | `{message, access_token_revoked, refresh_token_revoked, warning?}` |
| `GET /users/me` | herkes | — | kullanıcı nesnesi |
| `GET /users/me/properties` | herkes | — | **düz dizi** `[{property_id,property_name,unit_id,unit_name,role}]` |
| `POST /users/me/properties` | M, OWNER | `name`*,`type`(SITE/APARTMENT/BUILDING),`address`*,`city`*,`district` | 201 site; kurucu `property_roles`'ta geçici **MANAGER** olur (2026-10-03; önceden sahte "YÖNETİM" dairesi açılıyordu). Yeni rol için siteye geçip jeton yenilenir |
| `POST /users/me/active-property` | herkes | `property_id`* | `{message}` · 403 bağlı değil |
| `POST /users/me/kvkk-consent` | herkes | — | `{message}` |
| `POST /users/me/logout-all` | herkes | — | `{message,note}` |
| `POST /auth/activate` | açık | `phone`*,`code`*,`new_password`* | 200 `{message}` · 400 kod/telefon hatalı, kullanılmış ya da süresi dolmuş · 422 zayıf şifre · 429 kod 5 hatalı denemede kilitlendi. Başarılıysa kullanıcının açık bütün oturumları kapanır |
| `POST /users/me/password` | herkes | `current_password`*,`new_password`* | 200 `{message,note}` · 400 mevcut şifre yanlış · 422 zayıf. Bütün oturumlar kapanır |
| `GET /residents` | M,B,A,S | `search`,`block`,`role` | `{data:[{id,user_id,first_name,last_name,phone,email,unit_id,unit,role,is_active,created_at}]}` (`id`=resident_units.id) |
| `POST /residents` | M,B | `first_name`*,`last_name`*,`phone`* (boşluk/tire atılır, +90'a çevrilir),`email`,`unit_id`*,`role`* (OWNER/TENANT/PROXY; diğeri 422) | 201 sakin + yeni hesapsa `activation:{activation_code,purpose,expires_at,note}` (kod **bir kez** döner); telefon bu sitede kayıtlıysa kod yok, `note`; telefon bu siteyle bağı olmayan hesaba aitse **202** `{invitation:{id,unit_id,unit,phone,role,status,created_at,expires_at},note}` (bağ kurulmaz; bekleyen davet varsa 409) |
| `POST /residents/bulk` | M,B | `{residents:[…POST /residents gövdesi]}` (en çok 500) | 200 `{data:[{row,status(created/linked/invited/error),phone,resident_id?,invitation_id?,activation?,error?}],summary,note}` — satırlar bağımsız; kodlar yalnızca bu yanıtta |
| `GET /residents/invitations` | M,B,A | — | `{data:[{id,unit_id,unit,phone,role,status(PENDING/ACCEPTED/DECLINED/CANCELLED/EXPIRED),created_at,expires_at,responded_at?}]}` — kişinin adı yok |
| `POST /residents/invitations/:id/cancel` | M,B | — | 200 davet (CANCELLED) · yanıtlanmış/süresi dolmuş 409 |
| `GET /users/me/invitations` | herkes | — | `{data:[{id,property_id,property_name,unit,role,created_at,expires_at}]}` yanıt bekleyen, süresi dolmamış |
| `POST /users/me/invitations/:id/accept` · `/decline` | davet edilen | — | 200 `{property_id,accepted,message}`; kabulde daire bağı kurulur · başkasının daveti 404 · yanıtlanmış/iptal/süresi dolmuş 409 |
| `POST /residents/:id/activation-code` | M,B | — | 201 `{activation_code,purpose:ACTIVATION\|RESET,expires_at,note}` · eski açık kod geçersizleşir · 404 |
| `GET/PATCH /residents/:id` | GET M,B,A,S · PATCH M,B | PATCH: `role`,`is_active` | sakin |

Şifre politikası: en az 8 karakter, en az bir harf ve bir rakam, telefon numarasını içeremez.
Giriş kilidi: art arda 5 hatalı girişte hesap 15 dk kilitlenir (kilitliyken doğru şifre de 401).
| `GET /units` | M,B,A,S | — | `{data:[{id,property_id,block,floor,door_number,share_ratio,gross_area_m2,unit_type,is_commercial,is_ground_floor}]}` (silinmişler hariç) |
| `POST /units` | M,B | tek bölüm nesnesi ya da `{units:[…]}` (en çok 2000): `door_number`*,`share_ratio`* (>0),`block`,`floor`(vars. 0),`gross_area_m2`,`unit_type`(APARTMENT/SHOP/OFFICE/PARKING/STORAGE),`is_commercial`,`is_ground_floor`(vars. kat 0) | 201 `{data:[…],created}` — hepsi tek işlemde; aynı blok/kapı (harf duyarsız) 409, doğrulama 422 (satır numarasıyla) |
| `PATCH /units/:id` | M,B | aynı alanlar, hepsi isteğe bağlı | 200 bölüm; verilmeyen alan değişmez |
| `GET /property-roles` | M,B,A,S | — | `{data:[{id,user_id,first_name,last_name,phone,role,valid_from,valid_to?,decision_ref,active,granted_by_name,granted_at}]}` (geçmiş dahil) |
| `GET /property` | herkes | — | `{id,name,is_active,deactivated_at,deactivation_reason,events:[{action,reason,at}]}` |
| `POST /property/deactivate` | **M** | `reason`*(≥5),`confirm_name`*(site adı) | `{is_active:false,message,note}` · 422 ad uyuşmuyor · 409 zaten pasif. Pasif sitede tahakkuk/gecikme/bildirim yazımı 409 `{code:"PROPERTY_INACTIVE"}` |
| `POST /property/reactivate` | **M** | `reason`* | `{is_active:true,message,note}` (geriye dönük tahakkuk yok) |
| `POST /property-roles` | **M** | `phone`*,`role`*(MANAGER/BOARD_MEMBER/AUDITOR/STAFF),`decision_ref` (M/B/A için zorunlu — KMK m.34/41),`valid_from`,`valid_to`,`first_name`/`last_name` (hesap yoksa) | 201 `{role,activation?,note}` · bağsız hesap 409 · aynı etkin görev 409 · eksik karar 422. Yetki bir sonraki girişte geçerli |
| `POST /property-roles/:id/end` | **M** | — | 200 `{role,note}`; kişinin bütün oturumları kapatılır · sitenin tek yöneticisi 409 |

## finance (8082) — önek `/finance`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /finance/debt-status` | herkes | — | `{has_debt,current_balance,overdue_amount,overdue_months,next_due_date,next_due_amount}` |
| `GET /finance/assessments` | herkes (kendi daireleri) | `year` | `{data:[{id,period,base_amount,late_fee,total_amount,paid_amount,status}]}` |
| `GET /finance/assessments/:id` | sakin: yalnız kendi dairesi; M/B/A: tümü | — | `{id,property_id,unit_id,period_year,period_month,base_amount,late_fee,total_amount,paid_amount,due_date,status,created_at,details:[{category,amount,calculation_basis}]}` |
| `POST /finance/payments` | herkes | `assessment_ids`*[],`payment_method`*,`card_token`,`save_card` | `{payment_id,amount,status:"PENDING",payment_gateway_ready:false}` (tahsilat YAPILMAZ) |
| `GET /finance/my-payments` | herkes | `limit`(≤500, vars. 50),`offset` | `{data:[…kendi ödemeleri],total,limit,offset}` |
| `GET /finance/consumption/summary` | herkes | `meter_type` | `{meter_type,unit,data:[{period,consumption,amount,status}]}` |
| `GET /finance/debtors` | M,B,A | — | `{data:[{unit_id,resident_id,name,unit,amount}]}` — daire başına tek satır (2026-10-03); `resident_id` malik/sakin yoksa boş |
| `GET /finance/payments` | M,B,A | `limit`(≤500, vars. 50),`offset` | `{data:[{id,user_id,amount,payment_method,status,transaction_id?,created_at,completed_at,name,unit}],total,limit,offset}` |
| `GET /finance/payments/pending` | M,B,A | — | aynı biçim |
| `GET /finance/assessments/overview` | M,B,A | `year` | `{data:[{period,due_date,total_amount,collected_amount,rate,status}]}` — `rate` yüzde, tek ondalık, aşağı yuvarlanmış (2026-10-03) |
| `GET /finance/opening-balances` | M,B,A | — | `{data:[{id,unit_id,unit,amount,paid_amount,due_date,description,status,created_at}]}` |
| `POST /finance/opening-balances` | M,B | `due_date`*,`items`*:[{`unit_id`*,`amount`*>0,`description`}] (en çok 2000) | 201 `{data,created,note}` — tek işlem; bölüm başına tek devir (409); devire otomatik gecikme tazminatı işletilmez, dönem özetine girmez |
| `POST /finance/opening-balances/:id/cancel` | M,B | — | 200 · ödemesi/bekleyen ödemesi varsa 409 |
| `GET /finance/expense-categories` | M,B,A | — | `{data:[{id,property_id,name,distribution_type,applies_to_commercial,applies_to_ground_floor,custom_formula,is_active}]}` |
| `POST /finance/assessments` | M,B | `period_year`*,`period_month`*(1-12),`due_date`*,`expense_items`*[{`category_id`*,`amount`*>0}] | 201 `{data:[özet]}` · 409 dönem var |
| `POST /finance/payments/:id/confirm` | M,B | `reference` | `{message}` · 404/409/403 |
| `POST /finance/payments/:id/reject` | M,B | — | `{message}` · 404/409 |
| `POST /finance/late-fees/accrue` | M,B | `as_of` | `{as_of,monthly_rate,legal_basis,processed_count,total_fee_kurus,total_fee_try,skipped_not_due}` |
| `GET /finance/credit-notes` · `/:id/pdf` | herkes (sakin: kendi aktif daireleri) | — | `{data:[{id,document_no,assessment_id,unit_id,unit,period,amount_kurus,reason,created_by_name,created_at,reversed_at?,reversal_reason?}]}` · PDF |
| `POST /finance/credit-notes` | M,B | `assessment_id`*,`amount_try`*,`reason`*(≥5) | 201 `{credit_note,note}` · 422 kalan borç/anaparayı aşıyor |
| `POST /finance/credit-notes/:id/reverse` | M,B | `reason`*(≥5) | `{message,note}` · 409 zaten ters kaydı yapılmış |
| `GET /finance/units/:id/open-assessments` | M,B,A | — | `{data:[{id,period,due_date,total_kurus,paid_kurus,credited_kurus,outstanding_kurus,max_credit_kurus}]}` |
| `POST /finance/bank-statements` | M,B | multipart `file` (.csv/.xlsx, ≤5 MB) | 201 `{import:{id,file_name,row_count,counts,lines:[{id,line_no,date,amount_kurus,description,reference,status(SUGGESTED/AMBIGUOUS/UNMATCHED/OUTGOING/DUPLICATE/CONFIRMED/IGNORED),suggested_payment_id,note,payer,unit}]},note}` · 400 okunamayan dosya |
| `GET /finance/bank-statements` · `/:id` | M,B,A | — | ekstre listesi / satırlarıyla ekstre |
| `POST /finance/bank-statements/lines/:id/confirm` | M,B | `payment_id` (boşsa öneri) | `{payment_id,message}` (ödeme aynı işlemde onaylanır) · 409 sonuçlanmış · 422 tutar uyuşmuyor |
| `POST /finance/bank-statements/lines/:id/ignore` | M,B | `note`* | `{message}` |

## community (8083)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /requests` | herkes (M/A/S tüm site, diğer: kendi) | `status` | `{data:[{id,property_id,unit_id,resident_id,category_id,ticket_number,title,description,location,priority,status,photo_urls,resolved_at,closed_at,user_confirmed_at,created_at,updated_at}]}` |
| `POST /requests` | herkes | `title`*,`description`*,`category_id`,`location`,`photos`[],`priority`(LOW/NORMAL/HIGH/URGENT),`unit_id` (çağıranın aktif dairesi; yoksa tek dairesi) | 201 talep (`TLP-XXXXXXXX`, OPEN) · başkasının dairesi 422 |
| `PATCH /requests/:id/status` | M,A,S | `status`* (OPEN→IN_PROGRESS→RESOLVED) | talep · 400 geçersiz geçiş |
| `POST /requests/:id/confirm-resolution` | talep sahibi | `approved` | talep (CLOSED / IN_PROGRESS) |
| `GET /announcements` | herkes | `category`,`include_expired`(yönetim) | `{data:[{id,title,content,category,priority,is_pinned,published_at,expires_at,created_by_name,created_at,is_read,read_count?}]}` |
| `GET /announcements/:id` · `POST /announcements/:id/read` | herkes | — | duyuru · `{message}` |
| `POST /announcements` | M,B | `title`*,`content`*,`category`(GENERAL/MAINTENANCE/FINANCIAL/EMERGENCY/ASSEMBLY),`priority`,`is_pinned`,`expires_at` | 201 `{id, notification:{recipients,sent,pending,suppressed,failed,duplicate,note}}` |
| `POST /announcements/:id/pin` | M,B | `pinned` | `{is_pinned}` |
| `GET /announcements/:id/read-stats` | M,B | — | `{stats:{total_residents,read_count,unread_count},note}` |

## notification (8085)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /notifications` | herkes (kendi) | `status`,`limit` | `{data:[{id,recipient_name?,recipient_masked,channel,category,topic,subject?,body,status,suppress_reason?,provider?,attempts,last_error?,created_at,sent_at?}]}` |
| `GET/PUT /notification-preferences` | herkes | PUT: `channel`*(IN_APP/PUSH/SMS/EMAIL),`category`*(TRANSACTIONAL/COMMERCIAL),`enabled`,`consent_source` | `{data:[{channel,category,enabled,consent_at?,consent_source?}],note}` |
| `POST /notifications` | M,B | `recipient_user_id`/`recipient`,`channel`*,`category`,`topic`,`subject`,`body`*,`payload`,`dedupe_key` | 201 SENT / 202 PENDING-SUPPRESSED / 502 FAILED |
| `GET /notifications/outbox` · `GET /notifications/summary` | M,B | `status`,`channel`,`limit` | liste · `{summary:{total,pending,sent,failed,suppressed,by_channel}}` |

## expense (8086)

Gider nesnesi: `{id,category_id,category_name,description,amount,currency,expense_date,is_invoiced,invoice_reason,reflects_to_assessment,assessment_period,distribution_type,status(PENDING/APPROVED/REJECTED),approved_by,approved_at,rejection_reason,vendor_name,vendor_tax_id,invoice_number,invoice_date,notes,created_by,created_at,per_unit_amount?,distributions?[{unit_id,unit_name,amount,is_paid}]}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /expense-categories` | M,B,A | — | `{data:[{id,property_id,name,description,type,distribution_type,reflects_to_assessment,applies_to_ground_floor,is_default,display_order,is_active,legal_basis}]}` |
| `GET /expenses` | M,B,A | `year`,`month`,`status`,`category_id` | `{data:[Gider]}` |
| `GET /expenses/summary` | M,B,A | `year`,`month` | `{period_year,period_month,total_amount,invoiced_amount,non_invoiced_amount,pending_count,by_category:[{category_id,category_name,amount,count}]}` |
| `GET /expenses/:id` | M,B,A | — | Gider (+dağıtım) |
| `POST /expenses` | M,B | `category_id`*,`description`*,`amount`*>0,`expense_date`*,`is_invoiced`(true),`invoice_reason`(faturasızsa zorunlu),`reflects_to_assessment`,`assessment_period`(YYYY-MM),`distribution_type`(EQUAL/SHARE_RATIO/AREA_M2),`vendor_name`,`vendor_tax_id`,`invoice_number`,`invoice_date`,`notes` | 201 `{expense, note?}` |
| `POST /expenses/:id/approve` · `/reject` | M,B | reject: `reason`* | `{message}` · 404/409 |

## personnel (8100)

Personel: `{id,employee_number,first_name,last_name,tc_number(maskeli),bank_iban(maskeli),bank_name,phone,email,position,department,hire_date,end_date,contract_type,gross_salary,net_salary,sgk_number,annual_leave_days,used_leave_days,remaining_leave_days,is_active,notes,created_at,salary_visible}` — S rolü maaş/IBAN/SGK/TCKN göremez.

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /employees` | M,B,A,S | `all=true` | `{data:[Personel]}` |
| `GET /employees/summary` | M,B,A,S | — | `{total_active,total_inactive,pending_leaves,monthly_salary_cost?,by_position:[{position,count}]}` |
| `GET /employees/:id` | M,B,A,S | `reveal=true` (yalnız M; PII_REVEAL denetim kaydı) | Personel |
| `POST /employees` | M,B | `first_name`*,`last_name`*,`position`*,`hire_date`*,`contract_type`(FULL_TIME/PART_TIME/CONTRACT/INTERN),`tc_number`,`bank_iban`,… | 201 · 422 TCKN/IBAN/tür |
| `POST /employees/:id/terminate` | M,B | `reason`*,`end_date` | `{message,note}` |
| `GET /leaves` | M,B,A,S | `status` | `{data:[{id,employee_id,employee_name,leave_type,start_date,end_date,days,reason,status,…}]}` |
| `POST /leaves` | M,B | `employee_id`*,`leave_type`*(ANNUAL/SICK/UNPAID/MATERNITY/PATERNITY/MARRIAGE/BEREAVEMENT/OTHER),`start_date`*,`end_date`*,`reason` | 201 `{id,status:"PENDING"}` · 409 çakışma |
| `POST /leaves/:id/approve` · `/reject` | M,B | reject: `reason`* | `{message}` · 404/409 |

## visitor (8105)

Ziyaretçi: `{id,unit_id,unit_name,visitor_name,visitor_phone,visitor_company,visitor_id_number(maskeli),vehicle_plate,purpose,visit_reason,expected_at,checked_in_at,checked_out_at,status(EXPECTED/CHECKED_IN/CHECKED_OUT/CANCELLED/NO_SHOW),duration_minutes,notes,created_at}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /visitors` | herkes (M/B/S tüm site, diğer: kendi daireleri) | `status`,`inside=true` | `{data:[Ziyaretçi]}` |
| `GET /visitors/summary` | M,B,S | — | `{currently_inside,today_expected,today_checked_in,today_checked_out}` |
| `POST /visitors` | herkes | `visitor_name`*,`unit_id`,`visitor_phone`,`visitor_id_number`,`visitor_company`,`vehicle_plate`,`purpose`,`visit_reason`,`expected_at`,`notes` | 201 `{id,status:"EXPECTED",note}` |
| `POST /visitors/:id/check-in` · `/check-out` | M,B,S | — | `{message, notification?}` |
| `POST /visitors/:id/cancel` | M,B,S tümü; sakin yalnız kendi oluşturduğu/dairesine gelen | — | `{message}` · 404 |

## parking (8098)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /vehicles` | herkes (sakin: kendi daireleri) | — | `{data:[{id,unit_id,unit_name,owner_type,owner_name,plate,brand,model,color,vehicle_type,parking_spot,is_active,created_at}]}` |
| `POST /vehicles` | herkes (sakin yalnız KENDİ dairesine, `unit_id` zorunlu) | `plate`*,`unit_id`,`owner_type`(RESIDENT/VISITOR/STAFF/SERVICE),`owner_name`,`brand`,`model`,`color`,`vehicle_type`(CAR/MOTORCYCLE/TRUCK),`parking_spot` | 201 `{id,plate}` · 403/409/422 |
| `DELETE /vehicles/:id` | M,B,S tümü; sakin yalnız kendi | — | `{message,note}` (pasife alır) |
| `GET /vehicles/plate/:plate` | M,B,S | — | araç |
| `GET /parking-zones` | herkes | — | `{data:[{id,name,location,capacity,occupied_count,available_spots,is_paid,hourly_fee,daily_fee,is_visitor_allowed,is_active}]}` |
| `GET /parking-logs` | M,B,S | `inside=true` | `{data:[{id,parking_zone_id,zone_name,vehicle_id,plate,entry_at,entry_gate,entry_method,exit_at,duration_minutes,calculated_fee,paid_fee,payment_status,is_resident}]}` |
| `POST /parking-logs/entry` | M,B,S | `plate`*,`parking_zone_id`,`entry_gate`,`entry_method` | 201 `{id,plate,is_resident_vehicle}` · 409 dolu/içeride |
| `POST /parking-logs/:id/exit` | M,B,S | `exit_gate` | `{duration_minutes,calculated_fee,is_resident_vehicle,note?}` (ücret TAHSİL EDİLMEZ) |
| `GET /access-devices` | M,B,S,A | — | `{data:[{id,name,kind,location,heartbeat_interval_sec,offline_after_sec,last_seen_at,last_status,is_active,online,open_incident_id?,open_incident_since?}],valid_kinds}` |
| `GET /access-devices/incidents` | M,B,S,A | — | `{data:[{id,device_id,device_name,kind,last_seen_at,detected_at,recovered_at?}]}` |
| `POST /access-devices` | M,B | `name`*,`kind`*(PTS_CAMERA/BARRIER/TURNSTILE/INTERCOM/OTHER),`location`,`heartbeat_interval_sec`(10–3600, vars. 60),`offline_after_sec`(≥2×aralık, vars. 3×) | 201 `{id,device_key,note}` (anahtar bir kez) |
| `DELETE /access-devices/:id` | M,B | — | `{message,note}` (pasife alır) |
| `POST /public/devices/heartbeat` | **kimliksiz**, `X-Device-Key` | `status` | `{status:"ok",recovered}` · 401 anahtar tanınmadı/pasif |

## reservation (8101)

Tesis: `{id,name,description,category,capacity,is_paid,hourly_fee,daily_fee,deposit_amount,available_from,available_to,available_days[0=Pz],min_duration_minutes,max_duration_minutes,advance_booking_days,max_reservations_per_unit,buffer_minutes,requires_approval,auto_approve_residents,rules,is_active,maintenance_mode,maintenance_note}` · Rezervasyon: `{id,facility_id,facility_name,unit_id,unit_name,resident_id,resident_name,start_time,end_time,duration_minutes,guest_count,purpose,status,total_fee,payment_status,rejection_reason,cancelled_at,created_at}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /facilities` · `/facilities/:id` | herkes | — | `{data:[Tesis]}` · Tesis |
| `POST /facilities` · `PATCH /facilities/:id` | M,B | `{name,category?,capacity?,is_paid,hourly_fee?,daily_fee?,deposit_amount?,available_from,available_to,available_days[],min/max_duration_minutes,advance_booking_days,max_reservations_per_unit,buffer_minutes,cancellation_deadline_hours,requires_approval,auto_approve_residents,rules?,is_active,maintenance_mode,maintenance_note?}` (PATCH kısmi) | `201 Facility` · `200 {facility,note}`; 422 kural ihlali |
| `GET /facilities/:id/slots` | herkes | `date`* | `{date,open,available_from,available_to,buffer_minutes,busy:[Rezervasyon],note}` |
| `GET /reservations` | herkes (M/B/A tümü) | `status`,`facility_id` | `{data:[Rezervasyon]}` |
| `POST /reservations` | dairesi olan herkes | `facility_id`*,`start_time`*,`end_time`*,`guest_count`,`purpose` | 201 `{id,status,total_fee,note?,deposit_note?}` · 409 çakışma · 422 kural |
| `POST /reservations/:id/cancel` | sahibi; M/B herkesinkini (A iptal EDEMEZ) | `reason` | `{message,note}` |
| `POST /reservations/:id/approve` · `/reject` | M,B | reject: `reason`* | `{message, notification}` |

## package (8097)

Paket: `{id,unit_id,unit_name,recipient_name,recipient_phone,carrier,tracking_number,package_type,description,received_at,received_by_name,storage_location,notification_sent,reminder_count,delivered_at,delivered_by_name,delivered_to_name,status(RECEIVED/NOTIFIED/DELIVERED/RETURNED),notes,waiting_days}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /packages` · `/packages/:id` | herkes (sakin: kendi dairesi) | `unit_id`,`status`,`pending=true` | `{data:[Paket]}` · Paket |
| `GET /packages-summary` | M,B,S | — | `{pending,delivered,returned,not_notified,waiting_over_7_days,oldest_waiting_days}` |
| `POST /packages` | M,B,S | `unit_id`*,`recipient_name`*,`recipient_phone`,`carrier`,`tracking_number`,`package_type`(PACKAGE/ENVELOPE/LARGE),`description`,`storage_location`,`notes` | 201 `{id,status,notification_sent,notification,note}` |
| `POST /packages/:id/notify` | M,B,S | `method` | `{status,reminder_count,note}` |
| `POST /packages/:id/deliver` | M,B,S | `delivered_to_name`* | `{status:"DELIVERED",note}` |
| `POST /packages/:id/return` | M,B,S | `reason`* | `{status:"RETURNED"}` |

## contract (8090)

Sözleşme: `{id,contract_type,title,description,contract_number,party_name,party_type,party_tax_id,party_phone,party_email,party_contact_person,start_date,end_date,signed_date,auto_renew,renewal_period_months,renewal_notice_days,max_renewals,current_renewal,payment_type,monthly_amount,yearly_amount,total_amount,currency,status,termination_reason,terminated_at,notes,created_at,days_remaining,notice_due}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /contracts-summary` | herkes | — | `{summary:{active,expired,terminated,notice_due,expiring_in_30_days,monthly_commitment_try,yearly_commitment_try},note}` |
| `GET /contracts` · `/contracts/:id` | M,B,A | `type`,`status`,`expiring_days` | `{data:[Sözleşme]}` |
| `POST /contracts` | M,B | `contract_type`*(RENTAL/SERVICE/MAINTENANCE/EMPLOYMENT/INSURANCE/OTHER),`title`*,`party_name`*,`start_date`*,`end_date`,`auto_renew`,`renewal_period_months`,`renewal_notice_days`(30),`payment_type`(MONTHLY/YEARLY),`monthly_amount`,`yearly_amount`,`total_amount`,… | 201 `{id,status:"ACTIVE",note}` |
| `POST /contracts/:id/renew` | M,B | — | `{contract,note}` |
| `POST /contracts/:id/terminate` | M,B | `reason`* | `{status:"TERMINATED"}` |
| `POST /contracts/expire-due` | M,B | — | `{expired_count,note}` |

## document (8091)

Belge: `{id,category,title,description,storage_backend,file_name,content_type,size_bytes,sha256,visibility(RESIDENTS/OWNERS/MANAGEMENT),related_type,related_id,version,replaces_id,is_current,retention_until,uploaded_by_name,uploaded_at,archived_at,archive_reason,notes}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /documents` | herkes (görünürlüğe göre) | `category`,`related_type`,`related_id`,`include_versions`,`include_archived` | `{data:[Belge],visible_levels}` |
| `GET /documents-summary` | herkes | — | `{total,archived,by_category,total_size_bytes,retention_due}` |
| `GET /documents/:id` · `/download` | görünürlüğe göre | — | Belge · ikili akış (`X-Document-SHA256`) — her erişim kaydedilir |
| `POST /documents` (multipart) | M,B | `file`*,`category`*(MANAGEMENT_PLAN/DECISION/BUDGET/ACCOUNTING/CONTRACT/INVOICE/INSURANCE/REPORT/LEGAL/PERSONNEL/TECHNICAL/OTHER),`title`,`description`,`visibility`,`related_type`,`related_id`,`replaces_id`,`retention_until`,`notes` | 201 `{id,sha256,size_bytes,storage_backend,note}` · 413 |
| `POST /documents/:id/archive` | M,B | `reason`* | `{message,note}` |
| `GET /documents/:id/access-log` | M,B,A | — | `{data:[{user_name,action,ip_address,accessed_at}]}` |

## asset (8087)

Demirbaş: `{id,category_id,category_name,name,description,asset_code,serial_number,location,building,floor,room,purchase_date,purchase_price,vendor,warranty_end,warranty_days_left,depreciation_method,depreciation_years,residual_value,accumulated_depreciation,book_value,condition,status,assigned_to,assigned_at,last_maintenance_date,next_maintenance_date,maintenance_interval_days,maintenance_overdue_days,notes,created_at}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /asset-categories` | M,B,A,S | — | `{data:[{id,name,description,depreciation_years,is_global,asset_count}]}` |
| `GET /assets` | M,B,A,S | `category_id`,`status`,`condition`,`location`,`maintenance_due`,`warranty_expires_days`,`include_disposed` | `{data:[Demirbaş]}` |
| `GET /assets/:id` | M,B,A,S | — | `{asset, depreciation:{accumulated,book_value,annual_amount,elapsed_months,fully_depreciated}}` |
| `GET /assets/:id/maintenance` | M,B,A,S | — | `{data:[{id,maintenance_type,description,labor_cost,parts_cost,total_cost,performed_by,vendor,performed_at,next_due,status,notes}]}` |
| `GET /assets-summary` | M,B,A,S | — | `{total,active,disposed,by_condition,maintenance_overdue,warranty_expiring_30_days,purchase_total_try,maintenance_cost_ytd_try}` |
| `POST /assets/:id/maintenance` | M,B,S | `maintenance_type`*(PREVENTIVE/CORRECTIVE/INSPECTION),`description`*,`labor_cost`,`parts_cost`,`performed_by`,`vendor`,`performed_at`,`notes`,`new_condition` | 201 `{id,total_cost,note}` |
| `POST /asset-categories` | M,B | `name`*,`description`,`depreciation_years` | 201 `{id}` |
| `POST /assets` | M,B | `name`*,`category_id`,`asset_code`,`serial_number`,`location`,`building`,`floor`,`room`,`purchase_date`,`purchase_price`,`vendor`,`warranty_start`,`warranty_end`,`depreciation_years`,`residual_value`,`condition`(NEW/GOOD/FAIR/POOR/DISPOSED/LOST),`maintenance_interval_days`,`notes` | 201 `{id,status,note}` |
| `POST /assets/:id/assign` | M,B | `assigned_to` | `{message}` |
| `POST /assets/:id/dispose` | M,B | `reason`*,`decision_ref`*,`new_condition` | `{status:"DISPOSED",note}` |

## inventory (8094)

Kalem: `{id,category_id,category_name,name,description,sku,unit,current_stock(str),minimum_stock(str),reorder_point,unit_price,last_purchase_price,stock_value,warehouse,location,is_active,below_minimum,notes,created_at}` · Hareket: `{id,item_id,item_name,unit,movement_type,quantity,previous_stock,new_stock,unit_price,total_price,reference_type,reference_number,vendor,notes,created_by_name,created_at}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /inventory-categories` | M,B,A,S | — | `{data:[{id,name,item_count}]}` |
| `GET /inventory` · `/inventory/:id` | M,B,A,S | `category_id`,`q`,`below_minimum`,`include_inactive` | `{data:[Kalem]}` |
| `GET /inventory/:id/movements` · `/inventory-movements` | M,B,A,S | `limit` | `{data:[Hareket]}` |
| `GET /inventory-summary` | M,B,A,S | — | `{item_count,below_minimum,out_of_stock,total_value_try,purchase_cost_ytd_try,consumption_cost_ytd_try,movements_last_30_days}` |
| `POST /inventory/:id/movements` | M,B,S (ADJUST yalnız M/B) | `movement_type`*(IN/OUT/ADJUST),`quantity`* **metin** ("5","2,5"),`unit_price`,`reference_type`(PURCHASE/USAGE/ADJUSTMENT/RETURN/WASTE),`reference_number`,`vendor`,`notes`(ADJUST'ta zorunlu) | 201 `{movement:{…,below_minimum}, warning?, notification?}` · 409 stok yetersiz |
| `POST /inventory-categories` · `POST /inventory` | M,B | kalem: `name`*,`unit`*(ADET/KG/LT/METRE/M2/M3/PAKET/KUTU),`category_id`,`sku`,`minimum_stock`(metin),`reorder_point`,`warehouse`,`location`,`notes` | 201 `{id,current_stock:"0",note}` |
| `DELETE /inventory/:id` | M,B | `reason`* | `{message,note}` |

## survey (8104)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /surveys` | herkes (taslaklar yalnız yönetime) | `status` | `{data:[{id,title,description,survey_type,is_anonymous,is_weighted,allow_comments,show_results_before_end,starts_at,ends_at,status,eligible_voters,total_votes,participation_rate,created_by_name,created_at,has_voted}],legal_notice}` |
| `GET /surveys/:id` | herkes | — | `{survey:{…,options:[{id,option_text,description,display_order,vote_count?,weighted_share?,percentage?}]},results_visible,legal_notice,results_note?,anonymity_note?}` |
| `GET /surveys/:id/comments` | herkes | — | `{data:[{voter_name?,comment,voted_at}]}` |
| `POST /surveys/:id/vote` | herkes (VOTE türünde yalnız malik) | `option_id`*,`comment` | 201 `{message,weight,unit,legal_notice}` |
| `POST /surveys` | M,B | `title`*,`options`*[≥2 metin],`description`,`survey_type`(POLL/SURVEY/VOTE),`is_anonymous`,`is_weighted`,`allow_comments`,`show_results_before_end`,`starts_at`,`ends_at` | 201 `{id,status:"DRAFT",note,legal_notice}` |
| `POST /surveys/:id/publish` · `/close` · `/cancel` | M,B | cancel: `reason`* | durum + `notification` (publish) |

> Anket genel kurul kararı ÜRETMEZ (KMK m.29-32); `GENERAL_ASSEMBLY` türü reddedilir.

## iot (8084)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /meters` | herkes (sakin: kendi dairesi) | `unit_id`,`meter_type`,`include_inactive` | `{data:[{id,unit_id,unit_name,meter_type,serial_number,brand,model,installation_date,last_calibration_date,is_active,last_reading_date,last_reading_value}],valid_types:[HEAT,WATER_COLD,WATER_HOT,GAS,ELECTRIC]}` |
| `GET /meter-readings` | herkes (sakin: `meter_id` zorunlu, kendi sayacı) | `meter_id`,`from`,`to` | `{data:[{id,meter_id,serial_number,unit_name,reading_date,previous_value,current_value,consumption,reading_type,reader_name,created_at}]}` |
| `POST /meter-readings` | M,B,S | `meter_id`*,`current_value`*(metin),`reading_date`,`reading_type`(MANUAL/AUTOMATIC/ESTIMATED),`confirm_anomaly` | 201 `{reading,note?}` · 409/422 zincir · 409 `{code:"ANOMALY",ratio}` (önceki tüketimin 2,5 katı) · `meter_replaced:true` → 422 (değişim ucunu kullanın) |
| `POST /meters/:id/replace` | M,B,S | `removal_value`*,`replaced_on`*,`new_serial_number`*,`new_initial_value`*,`reason`* | 201 `{new_meter_id,note}` · 422 söküm < son okuma |
| `GET /consumption/statements` | herkes (sakin: yalnızca kendi satırı) | — | `{data:[{id,meter_type,period_from,period_to,total_kurus,consumption_share_pct,area_share_pct,basis_note,published_at,lines?}]}` |
| `GET /consumption/statements/:id` · `/:id/pdf` | herkes (sakin: kendi satırı) | — | `{…,lines:[{unit_id,unit_name,first_date,first_value,last_date,last_value,meter_replaced,consumption,usable_area,consumption_kurus,area_kurus,total_kurus}]}` · PDF |
| `POST /meters` | M,B | `unit_id`*,`meter_type`*,`serial_number`*,`brand`,`model`,`installation_date` | 201 `{id}` |
| `DELETE /meters/:id` | M,B | — | `{message,note}` |
| `POST /consumption/allocate` | M,B | `meter_type`*,`from`*,`to`*,`total_amount_try`*>0,`publish` | `{allocation:{total_kurus,consumption_part_kurus,area_part_kurus,…,units:[{unit_id,unit_name,consumption,usable_area,consumption_share_kurus,area_share_kurus,total_kurus,total_try,first_date,first_value,last_date,last_value,meter_replaced}]},basis_note,note,allocation_id?,…}` · yayımda 422 okuma eksik, 409 dönem zaten yayımlanmış |
| `/sensors/*`, `/iot/alerts/*` | — | — | **501** (sensör altyapısı yok) |

## patrol (8099)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /patrol-checkpoints` | M,B,A,S | `include_inactive` | `{data:[{id,name,description,location,building,floor,nfc_tag_id,qr_code,is_active,display_order}]}` |
| `GET /patrol-routes` | M,B,A,S | `include_inactive` | `{data:[{id,name,description,checkpoints:[{checkpoint_id,name,order,optional}],expected_duration_minutes,tolerance_minutes,is_active}]}` |
| `GET /patrols` | M,B,A,S (S: yalnız kendi) | `guard_id`,`status`,`limit` | `{data:[{id,route_id,route_name,guard_id,guard_name,started_at,completed_at,expected_duration_minutes,actual_duration_minutes,status,checkpoints_expected,checkpoints_visited,issues_reported,scans?,issues?,notes,too_fast}]}` |
| `GET /patrols-summary` | M,B,A,S | — | `{summary:{patrols_last_7_days,completed,incomplete,in_progress,issues_reported,suspiciously_fast},warning?}` |
| `POST /patrols` | M,B,S | `route_id`* | 201 `{patrol,note}` |
| `POST /patrols/:id/scan` | devriyenin sahibi | `checkpoint_id`*,`note` | `{scan:{checkpoint_name,checkpoints_visited,checkpoints_expected,checkpoints_remaining}}` |
| `POST /patrols/:id/issues` | devriyenin sahibi | `description`*,`checkpoint_id`,`severity`(LOW/MEDIUM/HIGH/CRITICAL) | 201 |
| `POST /patrols/:id/complete` | devriyenin sahibi | `notes` | `{result:{status,actual_duration_minutes,…,missed_checkpoints?,too_fast,warning?}}` |
| `POST /patrol-checkpoints` · `POST /patrol-routes` | M,B | nokta: `name`*,…; tur: `name`*,`checkpoints`*[{checkpoint_id,order,optional}],`expected_duration_minutes`,`tolerance_minutes` | 201 |

## bulletin (8089)

İlan: `{id,category(SALE/RENT/LOST_FOUND/HELP/SUGGESTION/CARPOOL/SERVICE/EVENT/OTHER),title,content,author_name,unit_name,price,price_negotiable,is_anonymous,status(PENDING/APPROVED/REJECTED/EXPIRED/CLOSED),rejection_reason,expires_at,is_pinned,view_count,created_at,comment_count,is_mine}`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /bulletins` · `/bulletins/:id` | herkes (onaylanmamışı yalnız sahibi/yönetim) | `category`,`status`,`mine` | `{data:[İlan],categories}` · `{post,anonymity_note?}` |
| `POST /bulletins` | dairesi olan herkes | `category`*,`title`*,`content`*,`price`,`price_negotiable`,`is_anonymous`,`expires_at` | 201 `{id,status:"PENDING",note}` |
| `POST /bulletins/:id/close` | sahibi / yönetim | — | `{status:"CLOSED"}` |
| `GET/POST /bulletins/:id/comments` | herkes (görünürlüğe göre) | `content`*,`is_anonymous` | `{data:[{id,author_name,content,is_mine,created_at}]}` · 201 |
| `DELETE /bulletin-comments/:id` | sahibi / yönetim | — | `{message,note}` |
| `POST /bulletins/:id/approve` · `/reject` | M,B | reject: `reason`* | durum |
| `POST /bulletins/expire-due` · `GET /bulletins-summary` | M,B | — | `{expired_count}` · `{pending_review,approved,rejected,expired,closed,by_category}` |

## settings (8102)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /settings` · `/settings/definitions` | herkes | — | `{data:[{key,type(TEXT/INT/BOOL),description,value,is_default,updated_by_name,updated_at}],note}` |
| `PUT /settings/:key` | M,B | `value`* | `{setting}` · 422 mevzuat anahtarı/tür/aralık |
| `DELETE /settings/:key` | M,B | — | varsayılana döner |
| `GET /settings-history` | M,B | `key`,`limit` | `{data:[{key,old_value,new_value,changed_by_name,changed_at}]}` |
| `/credentials*` | — | — | **501** (kimlik bilgisi kasası yok) |

Anahtarlar: `CONTACT_PHONE, CONTACT_EMAIL, OFFICE_HOURS, EMERGENCY_PHONE, DUE_DAY_OF_MONTH(1-28), REMINDER_DAYS_BEFORE(0-30), IBAN_DISPLAY, BULLETIN_REQUIRES_APPROVAL, VISITOR_REGISTRATION_REQUIRED, RESERVATION_ENABLED, BULLETIN_ENABLED, PACKAGE_REMINDER_DAYS(1-90), PATROL_REQUIRED_PER_DAY(0-24), QUIET_HOURS`.

## governance (8107) — önek `/governance`

Roller: okuma M,B,A · yazma M,B. İtiraz: kat maliki/vekil ya da yönetim.

| Uç | Gövde / Sorgu | Yanıt |
|---|---|---|
| `GET /governance/budgets` · `/budgets/:id` | — | `{data:[{id,period_year,status(DRAFT/NOTIFIED/FINAL),total_amount,notified_at,objection_deadline,approval_deadline,finalized_at}]}` · tam bütçe `{…,items:[{id,category_id,name,amount,distribution_type,kind,note,sort_order}],unit_shares:[{unit_id,unit_name,annual_kurus,monthly_kurus,breakdown}],open_objections,approval_deadline,approved_agenda_item_id,cap_base_budget_id,cap_rate,cap_amount,decision_ref}` |
| `POST /governance/budgets` | `period_year`*(2000-2200),`items`*[{`name`*,`amount`*>0,`distribution_type`*(EQUAL/SHARE_RATIO/AREA_M2),`kind`(EXPENSE/INCOME),`category_id`,`note`}],`note` | 201 bütçe |
| `POST /budgets/:id/notify` | `method`*(IMZA_KARSILIGI/TAAHHUTLU_MEKTUP/ELEKTRONIK) | bütçe — geçici proje; `approval_deadline` = +3 ay (KMK m.37, 7579). 422: yeniden değerleme tavanı aşıldı ya da oran tanımsız |
| `POST /budgets/:id/finalize` | `agenda_item_id`* (yapılmış genel kurulda kabul edilmiş madde), `decision_ref` | `{budget,note}` (İİK m.68 belgesi) · 422 madde kabul edilmemiş · 409 madde başka projede / proje kesinleşmiş |
| `GET/POST /budgets/:id/objections` | POST: `unit_id`*,`reason`* | `{data:[{id,unit_id,user_id,reason,submitted_at,status,resolution,resolved_at,in_time}]}` · 201 `{objection,warning?}` |
| `PATCH /budgets/:id/objections/:objectionId` | `status`*(ACCEPTED/REJECTED/WITHDRAWN),`resolution` | `{message}` · 409 zaten sonuçlanmış |
| `GET /governance/assemblies` · `/assemblies/:id` | — | `{data:[…]}` · `{id,kind,call_number,scheduled_at,location,notice_sent_at,notice_method,status(PLANNED/NOTIFIED/HELD),held_at,total_units,total_share_ratio,attended_units,attended_share_ratio,quorum_met,agenda_items:[{id,order_no,title,description,required_majority_code,decision_text,decision_status,votes_for,votes_against,votes_abstain,share_for,share_against,share_abstain}]}` |
| `GET /assemblies/:id/quorum` | — | `{total_units,total_share_ratio,attended_units,attended_share_ratio,required_ratio,by_count_met,by_share_met,met,call_number,explanation,legal_basis}` |
| `POST /governance/assemblies` | `kind`(ORDINARY/EXTRAORDINARY),`call_number`(1/2),`scheduled_at`*,`location`,`agenda_items`*[{`title`*,`description`,`required_majority_code`,`order_no`}] | 201 toplantı |
| `POST /assemblies/:id/notify` | `method`* | 422 15 günden geç (KMK m.29) |
| `POST /assemblies/:id/attendees` | `unit_id`*,`user_id`,`attendance_type`(SELF/PROXY),`proxy_holder_id`(PROXY'de zorunlu) | 201 · 409 toplantı yapılmış · 422 daire yok/vekâlet sınırı (m.31) |
| `POST /assemblies/:id/hold` | — | nisap sonucu (toplantı HELD) |
| `POST /agenda-items/:itemId/votes` | `unit_id`*,`vote`*(FOR/AGAINST/ABSTAIN) | 201 · 409 toplantı yapılmamış/madde karara bağlanmış |
| `POST /agenda-items/:itemId/close` | `decision_text` | `{required_code,required_ratio,by_count_ratio,by_share_ratio,accepted,explanation,legal_basis}` |
| `POST /governance/books?kind=DECISION\|OPERATING&year=` | — | defter `{id,kind,period_year,status,entry_count,…}` |
| `GET/POST /books/:id/entries` · `GET /books/:id/verify` · `POST /books/:id/close` | kayıt: `title`*,`body`*,`source_type`,`source_id`,`entry_date`; kapama: `notary_ref`,`closed_at`,`period_year` | `{data:[{id,entry_no,entry_date,title,body,prev_hash,entry_hash,…}]}` · `{valid,broken_at_entry_no?,message}` |
| `GET/POST /governance/legal-cases` | `unit_id`*,`case_type`*(EXECUTION/LAWSUIT/MORTGAGE),`basis_document_type`(OPERATING_BUDGET/ASSEMBLY_DECISION/COURT_ORDER),`basis_document_id`,`office_or_court`,`file_no`,`lawyer_name`,`note` | `{data:[{id,unit_id,case_type,status,principal_kurus,late_fee_kurus,…}]}` · 201 `{case,warning?}` |

## energy_analytics (8092) · smart_collection (8103) · nps (8096) · esg (8093)

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /energy/trends` | M,B,A,S | `meter_type`*,`months`(1-36) | `{periods:[{period,meter_type,total_consumption,units_with_reading,reading_count}],month_over_month?,year_over_year?,note}` |
| `GET /energy/anomalies` | M,B,A,S | `meter_type`*,`from`,`to` | `{usages:[…],anomalies:[{unit_id,unit_name,value,median,deviation_pct,severity,reason}],basis,note}` |
| `GET /collection/risk` | M,B,A | — | `{data:[{unit_id,unit_name,risk_score,risk_category,total_assessments,paid_on_time,paid_late,unpaid,average_delay_days,current_debt,longest_overdue_days,factors:[{code,points,detail}],suggested_action,suggested_action_reason,reliable}],totals,method,note}` (YZ YOK, formül açık) |
| `POST /collection/risk/snapshot` | M,B | — | 201 `{saved,skipped,note}` |
| `GET /nps` · `POST /nps/:id/respond` | herkes | `score`*(0-10),`comment` | `{data:[{id,title,description,status,starts_at,ends_at,eligible_respondents,responses,has_answered}]}` |
| `GET /nps/:id` · `/nps/:id/comments` | M,B,A | — | `{survey,result?:{nps_score,responses,promoters,passives,detractors,…,reliable,interpretation},method}` |
| `POST /nps` · `/nps/:id/close` | M,B | `title`*,`description`,`ends_at` | 201 |
| `GET /esg/consumption` | M,B,A | `from`,`to` | `{from,to,consumption:[{meter_type,total_consumption,meter_count,reading_count}],note}` |
| `POST /esg/carbon-footprint` | M,B,A | `from`,`to`,`emission_factors`*{METER_TYPE: kgCO2e/birim},`emission_factor_source`* | `{lines:[{meter_type,consumption,emission_factor,co2e_kg}],total_co2e_kg,method,note}` (katsayı kullanıcıdan) |
| `GET /esg/sustainability-score` | — | — | **501** (kabul görmüş formül yok) |

## Gateway kendi uçları

| Uç | Yanıt |
|---|---|
| `GET /health` | `{success,message,data:{version,time,auth_configured}}` |
| `GET /dashboard/stats` | `{success, data:{totalResidents?,totalUnits?,pendingRequests?,period?,monthlyIncome?,monthlyAssessed?,collectionRate?}, unavailable:[{source,reason}], partial}` — erişilemeyen alan yazılmaz, nedeni `unavailable`'da |
| `GET /dashboard/recent-payments` · `/recent-requests` | `{success, data:[… en fazla limit(5)]}` · 502 kaynak yok |
| `/reports/*` | **501** |

## Bilerek yazılmamış (501)

`banking` (S-07), `meeting_wizard` (governance ile tekrar), `iot` sensör uçları, `settings.credentials`,
`esg/sustainability-score`, `reports`.

### KVKK ilgili kişi başvuruları (community, 2026-10-04, migration 035)

| Uç | Rol | Gövde | Yanıt |
|---|---|---|---|
| `GET /kvkk-requests` | herkes (kendi) · M,B,A (site geneli) | — | `{data:[{id,user_id,applicant_name,request_type,description,status,due_date,days_left,response?,responded_at?,created_at}]}` |
| `POST /kvkk-requests` | herkes | `request_type`*(INFO/CORRECTION/ERASURE/OBJECTION/COMPENSATION/OTHER),`description`*(≥10) | 201 `{request,notification,note}`; son gün = bugün + KVKK_RESPONSE_DAYS (30, m.13/2) |
| `POST /kvkk-requests/:id/respond` | M,B | `status`*(ANSWERED/REJECTED),`response`* | 200; sahibine bildirim · sonuçlanmış 409 |
| `GET /renovations` | herkes (başvurduğu / sakini olduğu daire) · M,B,A (site geneli) | — | `{data:[{id,unit_id,unit,applicant_id,applicant_name,scope,description,contractor_name,contractor_phone,start_date,end_date,status,work_hours,conditions,deposit_amount,deposit_refunded,permit_ref,agenda_item_id,consent_required,consent_count,decision_note,stop_reason,completion_note,created_at}],truncated,limit}` |
| `GET /renovations/:id` | M,B,A · başvuran · dairenin sakini (diğerlerine 404) | — | `{permit,consents:[{owner_user_id,owner_name,consented_on,document_ref}]}` |
| `POST /renovations` | malik/vekil (kendi dairesi) · M,B (her daire) | `unit_id`*,`scope`*(INTERIOR/STRUCTURAL/COMMON_AREA/FACADE),`description`*(≥10),`start_date`*(≥bugün),`end_date`*(≤1 yıl),`contractor_name`,`contractor_phone` | 201 `{permit,requirement,notification}` · kiracı 403 |
| `POST /renovations/:id/cancel` | başvuran | — | bekleyen başvuru geri çekilir · 409 |
| `POST /renovations/:id/consents` | M,B | `owner_user_id`*,`consented_on`,`document_ref` | 201 `{consent_count,consent_required,owner_count}` · malik değil 422 · tekrar 409 (KMK m.19/2) |
| `POST /renovations/:id/approve` | M,B | `conditions`,`deposit_amount`,`permit_ref`(STRUCTURAL zorunlu),`agenda_item_id`(COMMON_AREA/FACADE, rıza yerine) | 200 `{permit,notification,neighbors}` · 422 ön koşul (ruhsat / 4/5 rıza) |
| `POST /renovations/:id/reject` · `/stop` | M,B | `reason`* | 200 · gerekçesiz 422 · uygun olmayan durum 409 |
| `POST /renovations/:id/complete` | M,B | `deposit_refunded`(≤ teminat),`note`(kesintide zorunlu) | 200 |
| `GET /site-rules` | herkes (etkin olanlar) · M,B,A (tümü) | — | `{data:[{id,category,title,description,management_plan_ref,is_active,created_at}]}` |
| `POST /site-rules` · `/:id/deactivate` | M,B | `title`*,`management_plan_ref`*(KMK m.28),`category`(NOISE/PET/PARKING/WASTE/COMMON_AREA/RENOVATION/OTHER),`description` | 201 kural · dayanaksız 422 |
| `GET /violations` · `/:id` | herkes (kendi bildirdiği / dairesine ait) · M,B,A (tümü) | — | `{data:[{id,rule_id,rule_title,management_plan_ref,unit_id,unit,reported_by?,reporter_name?,description,occurred_at,status(OPEN/VERIFIED/DISMISSED/RESOLVED),stage(NONE/VERBAL_WARNING/WRITTEN_WARNING/FORMAL_NOTICE/LEGAL),unit_repeat_count,created_at,events?}],truncated,limit}` · bildiren yalnızca yönetime ve bildirene |
| `POST /violations` | herkes | `rule_id`*,`unit_id`*,`description`*(≥10),`occurred_at`(RFC3339) | 201 `{violation,notification,note}` |
| `POST /violations/:id/respond` | dairenin aktif sakini | `note`* | 201 savunma · başka daire 403 |
| `POST /violations/:id/verify` · `/dismiss` · `/resolve` | M,B | `note` (dismiss/resolve zorunlu) | 200 · durum uygun değil 409 |
| `POST /violations/:id/escalate` | M,B | `stage`*(ileri yönde),`note`(sözlü uyarı dışında zorunlu) | 200; dairenin bütün aktif sakinlerine bildirim (KMK m.18) · 409 geri/aynı kademe ya da doğrulanmamış |
| `GET /emergency/info` | herkes | — | `{points:[{id,kind,name,location,note}],contacts:[{id,category,name,phone,note,sort_order}],national_emergency:"112",note}` (mobil çevrimdışı saklar) |
| `POST /emergency/points` · `/contacts` · `DELETE …/:id` | M,B | nokta: `kind`*,`name`*,`location`*,`note` · kişi: `category`*,`name`*,`phone`*,`note`,`sort_order` | 201 / 200 |
| `GET /emergency/drills` · `POST` | GET M,B,A · POST M,B | `kind`*,`drill_date`*(≤bugün),`findings`*,`participants`,`corrective_actions` | `{data:[{id,kind,drill_date,participants,findings,corrective_actions,created_at}]}` · 201 |
| `GET/PUT/DELETE /emergency/cards/me` | herkes (kendi) | PUT: `unit_id`*,`needs`*(≤1000),`household_count`,`contact_name`,`contact_phone`,`consent`*=true,`consent_version`*; DELETE `?unit_id=` | GET `{data,consent_text,consent_version}` · rızasız 422 · anahtar yoksa 503 (KVKK m.6) |
| `GET /emergency/cards` | M,B | — | `{data:[{id,user_id,resident_name,unit_id,unit,needs,household_count,contact_name,contact_phone,consent_at,consent_version}],note}`; her çağrı `SENSITIVE_REVEAL` denetim kaydı |
| `GET /emergency/checks` · `POST` | GET herkes · POST M,B | `kind`*,`title`* | `{data:[{id,kind,title,status,opened_at,closed_at,safe,need_help,units,responded,my_status}]}` · 201 `{check,notification}` · ikinci açık 409 |
| `POST /emergency/checks/:id/respond` | herkes | `status`*(SAFE/NEED_HELP),`note` | 200; NEED_HELP yönetime anında bildirim · kapalı 409 |
| `GET /emergency/checks/:id/responses` · `POST …/close` | M,B | — | `{check,data:[{user_id,name,unit,status,note,responded_at}],silent_units}` |
| `GET /compliance-calendar` | M,B,A | — | `{data:[{kind(MUHSGK/SGK_PREMIUM/SGK_ENTRY/SGK_EXIT),title,due_date,days_left,employee_id?,period?,legal_basis}],muhsgk_enabled,note}` (personel servisi) |
| `GET /payroll?period=YYYY-AA` | M,B,A | — | `{period,data:[{id,employee_id,employee_name,position,period,net_salary,employer_cost,gross_salary?,sgk_employee?,sgk_employer?,income_tax?,stamp_tax?,source_ref,payment_status,payment_date?,payment_reference?,cancel_reason?}],totals:{net,employer_cost,unpaid_net,paid_count,pending_count},missing:[ad],note}` |
| `GET /payroll/costs?year=` | M,B,A | — | `{year,data:[{period,employees,net,employer_cost}],employer_cost_total,note}` |
| `POST /payroll` | M,B | `{employee_id,period,net_salary,employer_cost,source_ref,gross_salary?,sgk_*?,income_tax?,stamp_tax?,payment_date?,payment_reference?,notes?}` | `201 {id,payment_status,note}`; 409 mükerrer, 422 dönem/tutar |
| `POST /payroll/:id/pay` · `/cancel` | M,B | `{payment_date,payment_reference?}` · `{reason}` | 200; 409 sonuçlanmış kayıt |
| `POST /employees/:id/sgk` | M,B | `entry_date` ya da `exit_date` (≤bugün) | 200 · ayrılmamış personele ayrılış ya da gelecek tarih 422 |
| `GET /governance/common-area/leases` · `POST` · `POST …/:id/end` | GET M,B,A · yazma M,B | `area_kind`*(ROOF_FACADE_AD/ANTENNA/CARETAKER_FLAT/PARKING/STORAGE/SHOP/OTHER),`area_name`*,`tenant_name`*,`tenant_is_business`,`start_date`*,`end_date`,`monthly_rent`*,`agenda_item_id`*(UNANIMITY_TRANSFER_ACTS ile kabul, KMK m.45) | `{data:[{id,area_kind,area_name,tenant_name,tenant_is_business,start_date,end_date,monthly_rent,agenda_item_id,decision_ref,status,note,income_total}]}` · oybirliği yok/sığınak 422 |
| `POST /governance/common-area/leases/:id/incomes` | M,B | `period`*(YYYY-AA),`gross_amount`*,`withholding_amount`(≤brüt; yalnızca işyeri kiracı),`received_on`* | 201 `{id,units,note}` (arsa payı oranında kuruş paylaştırma) · aynı dönem 409 |
| `GET /governance/common-area/report?year=` · `/my-share?year=` | report M,B,A · my-share herkes (malik olduğu bölümler) | — | `{year,data:[{unit_id,unit,owners,gross_kurus,withholding_kurus,share_ratio}],total_gross_kurus,total_withholding_kurus,note}` |
| `GET /retention-rules` · `/retention-rules/log` | M,B,A | — | `{data:[{category(VISITOR/PARKING_LOG/PACKAGE),title,fields,condition,retention_months?,justification?,last_run_at?,last_run_count?}],periodic_months,note}` · log `{data:[{category,method,cutoff,record_count,executed_at,executed_by}]}` |
| `PUT /retention-rules/:category` · `POST /retention-rules/run` | M,B | `retention_months`*(1-120),`justification`* | 200 · run `{data:[{category,cutoff,count,skipped?}],note}` (KVKK m.7; İmha Yön. m.7/3, m.11/2) |
| `GET /privacy/cameras` · `POST` · `PUT /:id` | GET herkes (sakin: konum/amaç/süre — aydınlatma) · M,B,A ek olarak `issues`,`open_issues` · yazma M,B | `location`*,`area_type`*,`purpose`*,`retention_days`*(1-365),`notice_posted`,`masked`,`audio_recording`,`face_recognition`,`intensive_justification`(ses/yüz/asansör zorunlu),`decision_ref`,`access_note` | mahremiyet alanı 422 (KVK Kurumu duyurusu 08/06/2026) |
| `GET /privacy/biometrics` · `POST` | GET M,B,A · POST M,B | `name`*,`method`*,`purpose`*,`alternative_method`*,`consent_based`*=true | alternatifsiz/rızasız 422 (KVKK m.6) |
| `POST /client-errors` | herkes (oturumlu) | `app`*(mobile/admin_app/admin_panel),`message`*(→2000),`stack`(→8000),`app_version`,`platform`,`fatal` | 201 `{id,accepted}` · kişi başı saatte 30 üstü 429 |
| `GET /insurance/dask` · `POST` | GET herkes (malik/vekil: kendi bölümleri; M,B,A: tümü) · POST malik/vekil (kendi) ya da M,B | `unit_id`*,`policy_no`*,`start_date`*,`end_date`*,`insurer`,`kind`(DASK/HOME) | `{data:[{unit_id,unit,policy_no,insurer,start_date,end_date,state(VALID/EXPIRING/EXPIRED/MISSING),days_left}],summary,note}` · kiracı 403 · tekrar 409 |
| `GET /insurance/claims` · `POST` · `POST …/:id/status` | GET M,B,A · yazma M,B | `occurred_on`*(≤bugün),`description`*(≥10),`claimed_amount`,`insurer_ref`,`contract_id`(INSURANCE) · durum: `status`*,`paid_amount`+`paid_on`(PAID),`note`(REJECTED) | `{data:[{id,contract_id,occurred_on,description,claimed_amount,status,insurer_ref,paid_amount,paid_on,note,created_at}]}` · geçersiz geçiş 409 |
| `GET /metrics` (her servis, gateway dışı) | küme içi | — | Prometheus metin biçimi: `siteeksen_http_requests_total`, `siteeksen_http_request_duration_seconds` (rota şablonu), `siteeksen_uptime_seconds` |
| `POST /kvkk-requests/:id/respond` | M,B | `status`*(ANSWERED/REJECTED),`response`* | 200; sahibine bildirim · sonuçlanmış 409 |
