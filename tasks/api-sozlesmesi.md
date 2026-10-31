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
| `POST /auth/activate` | açık | `phone`*,`code`*,`new_password`* | 200 `{message,invitations:{accepted,waiting?}}` · 400 kod/telefon hatalı, kullanılmış ya da süresi dolmuş · 422 zayıf şifre · 429 kod 5 hatalı denemede kilitlendi. Başarılıysa kullanıcının açık bütün oturumları kapanır. Hesabın İLK etkinleştirmesinde bekleyen daire davetleri kabul edilir (kabul edilemeyen bekler, neden `waiting`) — D3 |
| `POST /auth/password-reset/request` | herkes (oturumsuz) | `phone`* | 200 `{message,retry_after_sec,expires_in_sec}` — numaranın kayıtlı olup olmadığından bağımsız AYNI yanıt; kayıtlı ve etkinse kod SMS + (kayıtlıysa) e-postayla gider (15 dk); aynı hesap için 60 sn / saatte 3 kod; SMS ve e-posta yapılandırılmamışsa 503 `NO_DELIVERY_CHANNEL`; geçersiz numara 422 (B3) |
| `POST /auth/supplier-signup/request` | herkes (oturumsuz) | `phone`* | 200 `{message,retry_after_sec,expires_in_sec}` — kayıtlı/kayıtsız AYNI yanıt; kod her numaraya SMS ile (15 dk); numara 60 sn / saatte 3, IP saatte 10 → 429; SMS yoksa 503 `NO_DELIVERY_CHANNEL`; geçersiz numara 422 (076, FAZ M1) |
| `POST /auth/supplier-signup/verify` | herkes | `phone`*,`code`* | 200 `{state(NEW/EXISTING/INACTIVE),signup_token,expires_in_sec,next}` · 400 yanlış kod · 429 5 yanlışta kilit · 403 `BLOCKED` (kapatılmış hesap) |
| `POST /auth/supplier-signup/complete` | herkes | `phone`*,`signup_token`*,`password`*,`terms_accepted`*(true), NEW'de `first_name`*,`last_name`*,`email` | 200 girişle aynı `{access_token,refresh_token,expires_in,user,state}` — NEW hesap açar (rol yalnız SUPPLIER), EXISTING mevcut şifreyle SUPPLIER ekler (401 yanlış şifre, giriş kilidine sayılır; jeton tüketilmez), INACTIVE şifre belirler · 400 jeton geçersiz/kullanılmış · 422 alan/sözleşme/şifre · gövdedeki `roles` yok sayılır |
| `PUT /property/location` | M | `latitude`,`longitude` (ikisi birlikte; ikisi null → sil) | 200 `{message,latitude,longitude}` · 400 tek alan · 422 aralık dışı — Usta & Hizmet eşleşmesi için (077). `GET /property` yanıtında `latitude`,`longitude` |
| `POST /users/me/password` | herkes | `current_password`*,`new_password`* | 200 `{message,note}` · 400 mevcut şifre yanlış · 422 zayıf. Bütün oturumlar kapanır |
| `POST /users/me/phone/request` | oturum | `password`*,`phone`* | 200 `{message,expires_in_sec,retry_after_sec}` — kod YENİ numaraya SMS (15 dk); yanlış şifre 400, aynı numara 422, başkasının numarası 409, 60 sn / saatte 3 aşımı 429, SMS yapılandırılmamışsa 503 `NO_SMS_CHANNEL` (B4) |
| `POST /users/me/phone/confirm` | oturum | `code`* | 200 `{message,phone,sessions_revoked,old_phone_notice}` — numara değişir, BÜTÜN oturumlar kapanır, eski numaraya uyarı SMS'i; yanlış kod 400, 5 hatada 429 (B4) |
| `POST /users/me/email` | oturum | `password`*,`email`* | 200 `{message,expires_in_sec,retry_after_sec}` — kod YENİ adrese gider (065, 15 dk), adres henüz değişmez; yanlış şifre 400, geçersiz/aynı adres 422, başka hesapta kayıtlı 409, 60 sn / saatte 3 aşımı 429, e-posta yapılandırılmamışsa 503 `NO_EMAIL_CHANNEL` (B4) |
| `POST /users/me/email/confirm` | oturum | `code`* | 200 `{message,email,old_email_notice}` — adres değişir, eski adrese bilgi; yanlış kod 400, 5 hatada 429 (065) |
| `GET /residents` | M,B,A,S | `search`,`block`,`role` | `{data:[{id,user_id,first_name,last_name,phone,email,unit_id,unit,role,is_active,created_at,end_date,is_occupant}]}` (`id`=resident_units.id) — `is_occupant`: dairede oturan tarafta mı (kiracı, hane üyesi, kiracısız ve malik oturan dairede malik; vekil hiç) (067) |
| `GET /users/me/units/:id/residents` | dairenin AKTİF maliki ya da kiracısı | — | `{data:[{id,first_name,last_name,role,phone_masked,is_active,is_self,created_at,end_date}]}` — telefon maskeli, e-posta yok; dairenin maliki/kiracısı değilse 403 (B5, D3) |
| `POST /users/me/units/:id/invitations` | dairenin AKTİF maliki ya da kiracısı | `phone`*,`role`*,`first_name`,`last_name` (hesabı olmayan kişi için zorunlu),`email` — malik: TENANT/PROXY, dairede oturuyorsa HOUSEHOLD; kiracı: HOUSEHOLD | 201 `{invitation,new_account,delivery:{sms,email},note}` — etkinleştirme kodu davet edene **gösterilmez**, kişiye SMS + e-posta gider; aktif kiracı varken TENANT 409, bekleyen kiracı daveti varken 409, rol uygun değilse 422, daire üyesi değilse 403 (068, D3) |
| `POST /users/me/units/:id/residents/:residentId/end` | dairenin AKTİF maliki ya da kiracısı | — | 200 `{resident,message}` — malik vekilliği, oturan hane üyeliğini bitirir; kiracılık bu yoldan bitmez 409; kendisi/malik 422, başka dairenin sakini 404 (B5, D3) |
| `POST /users/me/units/:id/tenancy-end` | dairenin AKTİF maliki | `reason`* (≥5) | 201 `{id,status:PENDING_TENANT,delivery,message}` — kiracı onaylamadan kiracılık bitmez; açık istek varsa 409, aktif kiracı yoksa 409, malik değilse 403 (069, D4) |
| `POST /users/me/units/:id/tenancy-exit` | dairenin AKTİF kiracısı | `reason` | 200 `{id,status:COMPLETED,delivery,message}` — kiracılık hemen biter (V1), açık istekler kapanır, maliklere SMS/e-posta; kiracı değilse 403 |
| `GET /users/me/tenancy-requests` | oturum | — | `{data:[{id,unit_id,unit,tenant_link_id,tenant_name,kind(OWNER_REQUEST/TENANT_EXIT/MANAGEMENT),status(PENDING_TENANT/OBJECTION_WINDOW/SUSPENDED/COMPLETED/REJECTED/CANCELLED/REVERSED),reason,objection_deadline?,end_date?,created_at,closed_at?,requested_by_self,is_tenant,documents:[{id,document_kind,uyap_code?,file_name,content_type,size_bytes,sha256,created_at}],events:[{event,note,created_at,by}]}]}` — kişinin kiracısı ya da maliki/vekili olduğu dairelerin istekleri |
| `POST /users/me/tenancy-requests/:id/approve` · `/decline` | isteğin kiracısı | `note` | 200 — onay kiracılığı bugün bitirir (hanesi biter, daire boş — V8); ret yalnız malik isteğinde; durum uygun değilse 409 |
| `POST /users/me/tenancy-requests/:id/object` | isteğin kiracısı | `reason`* | 200 `{status:SUSPENDED}` — yalnız yönetim yolunda, 7 gün içinde; süre geçtiyse 409 |
| `POST /users/me/tenancy-requests/:id/cancel` | isteği açan malik | — | 200 · başkası 404 · durum uygun değilse 409 |
| `GET /users/me/tenancy-requests/:id/documents/:docId` | isteğin kiracısı | — | dosya (`X-Content-SHA256`) · başkası 404 · depo yoksa 503 |
| `GET /residents/tenancy-requests` | M,B,A,S | — | `{data:[…aynı biçim],attestation_text}` |
| `POST /residents/tenancy-requests` | M,B (dairenin maliki/vekili DEĞİLSE) | multipart: `unit_id`*,`reason`*(≥10),`document_kind`*(TAHLIYE_KARARI/ICRA_TAHLIYE/TASINMA_TUTANAGI/DIGER),`uyap_code`(isteğe bağlı),`password`*,`attest`*=true,`file`*(PDF/PNG/JPEG/WEBP ≤10 MB) | 201 `{id,status:OBJECTION_WINDOW,objection_deadline,delivery}` — beyan metni, IP ve özet saklanır; yanlış şifre 400, beyansız/tür dışı 422, çıkar çatışması 403, açık istek 409, depo yoksa 503 (V2, V7) |
| `POST /residents/tenancy-requests/:id/documents` | M,B | multipart: `document_kind`*,`uyap_code`,`password`*,`attest`*,`file`* | 200 — askıdaki/penceredeki yola yeni belge; yeni 7 günlük pencere |
| `POST /residents/tenancy-requests/:id/complete` | M,B | — | 200 — yalnız pencere itirazsız dolunca; aksi 409 |
| `POST /residents/tenancy-requests/:id/cancel` | M,B | `note` | 200 — açık yönetim yolunu iptal eder |
| `POST /residents/tenancy-requests/:id/reverse` | M,B | `reason`*(≥10),`password`* | 200 `{status:REVERSED}` — tamamlanmış yönetim yolunu geri alır, kiracı bağı aynı kayıtla açılır; dairede başka kiracı varsa 409 |
| `GET /residents/tenancy-requests/:id/documents/:docId` | M,B,A,S | — | dosya || `POST /residents` | M,B | `first_name`*,`last_name`*,`phone`* (boşluk/tire atılır, +90'a çevrilir),`email`,`unit_id`*,`role`* (OWNER/TENANT/PROXY/HOUSEHOLD; diğeri 422) | 201 sakin + yeni hesapsa `activation:{activation_code,purpose,expires_at,note}` (kod **bir kez** döner); telefon bu sitede kayıtlıysa kod yok, `note`; telefon bu siteyle bağı olmayan hesaba aitse **202** `{invitation:{id,unit_id,unit,phone,role,status,created_at,expires_at},note}` (bağ kurulmaz; bekleyen davet varsa 409) · dairede aktif kiracı varken TENANT 409 · oturanı olmayan daireye HOUSEHOLD 422 (068) |
| `POST /residents/invitations` | M,B | `unit_id`*,`phone`*,`role`*(OWNER/TENANT/PROXY/HOUSEHOLD),`first_name`,`last_name`,`email` | 201 `{invitation,new_account,activation?,delivery,note}` — hesabı yoksa hesap açılır, kod yönetime bir kez döner ve kişiye SMS + e-posta gider; kişi kodla hesabını etkinleştirince davet kabul edilir. OWNER yalnız maliki kayıtlı olmayan daireye (aksi 409); aktif kiracı ya da bekleyen kiracı daveti varken TENANT 409; oturanı olmayan daireye HOUSEHOLD 422 (068, D3) |
| `POST /residents/bulk` | M,B | `{residents:[…POST /residents gövdesi]}` (en çok 500) | 200 `{data:[{row,status(created/linked/invited/error),phone,resident_id?,invitation_id?,activation?,error?}],summary,note}` — satırlar bağımsız; kodlar yalnızca bu yanıtta |
| `GET /residents/invitations` | M,B,A | — | `{data:[{id,unit_id,unit,phone,role,status(PENDING/ACCEPTED/DECLINED/CANCELLED/EXPIRED),created_at,expires_at,responded_at?}]}` — kişinin adı yok |
| `POST /residents/invitations/:id/cancel` | M,B | — | 200 davet (CANCELLED) · yanıtlanmış/süresi dolmuş 409 |
| `GET /users/me/invitations` | herkes | — | `{data:[{id,property_id,property_name,unit,role,created_at,expires_at}]}` yanıt bekleyen, süresi dolmamış |
| `POST /users/me/invitations/:id/accept` · `/decline` | davet edilen | — | 200 `{property_id,accepted,message}`; kabulde daire bağı kurulur · başkasının daveti 404 · yanıtlanmış/iptal/süresi dolmuş 409 |
| `POST /residents/:id/activation-code` | M,B | — | 201 `{activation_code,purpose:ACTIVATION\|RESET,expires_at,note}` · eski açık kod geçersizleşir · 404 |
| `GET/PATCH /residents/:id` | GET M,B,A,S · PATCH M,B | PATCH: `role`,`is_active`,`end_date` (YYYY-AA-GG; yalnız `is_active:false` ile, boşsa bugün; ileri tarih / başlangıçtan önce 422 — B7) | sakin (`end_date` ayrılış tarihi; yeniden etkinleştirmede temizlenir) · aktif kiracıyı pasifleştirme ya da kiracı rolünü değiştirme 409 → kiracılık bitiş akışı (069) |

Şifre politikası: en az 8 karakter, en az bir harf ve bir rakam, telefon numarasını içeremez.
Giriş kilidi: art arda 5 hatalı girişte hesap 15 dk kilitlenir (kilitliyken doğru şifre de 401).
| `GET /units` | M,B,A,S | — | `{data:[{id,property_id,block,floor,door_number,share_ratio,gross_area_m2,unit_type,is_commercial,is_ground_floor,owner_occupied,occupancy,owner_count,tenant_count,owner_missing}]}` (silinmişler hariç) — `occupancy`: TENANT_OCCUPIED / OWNER_OCCUPIED / VACANT / UNREGISTERED, kayıtlardan hesaplanır; `owner_missing`: kiracı var, malik kayıtlı değil (067) |
| `POST /units` | M,B | tek bölüm nesnesi ya da `{units:[…]}` (en çok 2000): `door_number`*,`share_ratio`* (>0),`block`,`floor`(vars. 0),`gross_area_m2`,`unit_type`(APARTMENT/SHOP/OFFICE/PARKING/STORAGE),`is_commercial`,`is_ground_floor`(vars. kat 0) | 201 `{data:[…],created}` — hepsi tek işlemde; aynı blok/kapı (harf duyarsız) 409, doğrulama 422 (satır numarasıyla) |
| `PATCH /units/:id` | M,B | aynı alanlar, hepsi isteğe bağlı; `owner_occupied` (kiracısız dairede malik oturuyor / boş) | 200 bölüm (güncel `occupancy` ile); verilmeyen alan değişmez |
| `GET /property-roles` | M,B,A,S | — | `{data:[{id,user_id,first_name,last_name,phone,role,valid_from,valid_to?,decision_ref,active,granted_by_name,granted_at}]}` (geçmiş dahil) |
| `GET /property` | herkes | — | `{id,name,is_active,deactivated_at,deactivation_reason,events:[{action,reason,at}]}` |
| `POST /property/deactivate` | **M** | `reason`*(≥5),`confirm_name`*(site adı) | `{is_active:false,message,note}` · 422 ad uyuşmuyor · 409 zaten pasif. Pasif sitede tahakkuk/gecikme/bildirim yazımı 409 `{code:"PROPERTY_INACTIVE"}` |
| `POST /property/reactivate` | **M** | `reason`* | `{is_active:true,message,note}` (geriye dönük tahakkuk yok) |
| `POST /property-roles` | **M** | `phone`*,`role`*(MANAGER/BOARD_MEMBER/AUDITOR/STAFF),`decision_ref` (M/B/A için zorunlu — KMK m.34/41),`valid_from`,`valid_to`,`first_name`/`last_name` (hesap yoksa) | 201 `{role,activation?,note}` · bağsız hesap 409 · aynı etkin görev 409 · eksik karar 422. Yetki bir sonraki girişte geçerli |
| `POST /property-roles/:id/end` | **M** | — | 200 `{role,note}`; kişinin bütün oturumları kapatılır · sitenin tek yöneticisi 409 |

## finance (8082) — önek `/finance`

| Uç | Rol | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /finance/debt-status` | herkes | — | `{has_debt,current_balance,overdue_amount,overdue_months,next_due_date,next_due_amount}` — yalnız kişinin sorumlusu olduğu borç (070) |
| `GET /finance/assessments` | herkes (kendi daireleri) | `year` | `{data:[{id,period,base_amount,late_fee,total_amount,paid_amount,status,liability,responsible}]}` — `liability`: USAGE (kullanım/oturan) · OWNER (malik) (066). Yalnız kişinin sorumlusu olduğu borç döner (070): kiracı kendi kiracılığının kullanım borcunu; malik/vekil malik sınıfını, kiracısız dönemi ve kiracılığı bitmiş borcu; hane üyesi hiçbirini. `responsible`: TENANT/OWNER |
| `GET /finance/assessments/:id` | sakin: yalnız kendi dairesi; M/B/A: tümü | — | `{id,property_id,unit_id,period_year,period_month,base_amount,late_fee,total_amount,paid_amount,due_date,status,created_at,details:[{category,amount,calculation_basis}]}` |
| `POST /finance/payments` | herkes | `assessment_ids`*[],`payment_method`*,`card_token`,`save_card` | `{payment_id,amount,status:"PENDING",payment_gateway_ready:false}` (tahsilat YAPILMAZ) |
 · yalnız kişinin sorumlusu olduğu tahakkuk ödenir (070; aksi 400) |
| `GET /finance/my-payments` | herkes | `limit`(≤500, vars. 50),`offset` | `{data:[…kendi ödemeleri],total,limit,offset}` |
| `GET /finance/consumption/summary` | herkes | `meter_type` | `{meter_type,unit,data:[{period,consumption,amount,status}]}` |
| `GET /finance/debtors` | M,B,A | — | `{data:[{unit_id,resident_id,name,unit,amount,responsible,owner_missing}]}` — borcun sorumlusuna göre satır (070): aktif kiracılığa bağlı kullanım borcu kiracının (`responsible:TENANT`, ad "(kiracı)"), kalanı malik(ler)in; maliksiz dairenin malik borcu "Malik kaydı yok" (`owner_missing`, V3) |
| `GET /finance/tenant-debt-summary` | dairenin aktif maliki/vekili | — | `{data:[{unit_id,unit,total_kurus?,overdue_kurus?}],policy,note}` — kiracılı dairelerde kiracı sorumluluğundaki açık borç; alanlar yalnız site görünürlük politikası açıksa (071, D6); dönem/kalem ayrıntısı dönmez || `POST /finance/clearance-certificates` | yönetim ya da bölümün sakini | `unit_id`* | 201 `{id,verification_code,verify_url,as_of_date,expires_at,not_due_kurus,scope,note}` · vadesi geçmiş borç varsa 422 `{overdue:[{period,due_date,remaining_kurus,payment_pending_approval,responsible}],overdue_kurus}` — `scope` (070): yönetim ve malik/vekil UNIT (bütün daire; malik kiracı sorumluluğundaki borcun tutarını görmez, kalem "Kiracı sorumluluğundaki borç"), kiracı TENANCY (yalnız kendi kiracılığının kullanım borcu; malikin borcu engel değil) |
| `GET /finance/clearance-certificates/:id/pdf` | yönetim ya da bölümün sakini | — | PDF; TENANCY belgesinde kapsam ve kiracı adı yazar |
| `GET /public/clearance/:code` | açık (kimliksiz) | — | `{valid,expired,property_name,unit,as_of_date,issued_at,expires_at,scope,statement}` — kişi adı/tutar dönmez || `GET /finance/payments` | M,B,A | `limit`(≤500, vars. 50),`offset` | `{data:[{id,user_id,amount,payment_method,status,transaction_id?,created_at,completed_at,name,unit}],total,limit,offset}` |
| `GET /finance/payments/pending` | M,B,A | — | aynı biçim |
| `GET /finance/assessments/overview` | M,B,A | `year` | `{data:[{period,due_date,total_amount,collected_amount,rate,status}]}` — `rate` yüzde, tek ondalık, aşağı yuvarlanmış (2026-10-03) |
| `GET /finance/opening-balances` | M,B,A | — | `{data:[{id,unit_id,unit,amount,paid_amount,due_date,description,status,created_at,liability}]}` |
| `POST /finance/opening-balances` | M,B | `due_date`*,`liability`(USAGE/OWNER, satır varsayılanı),`items`*:[{`unit_id`*,`amount`*>0,`description`,`liability`}] (en çok 2000) | 201 `{data,created,note,notification}` — tek işlem; bölüm başına sınıf başına tek devir (409); daire sakinlerine yeni borç bildirimi (B1); devire otomatik gecikme tazminatı işletilmez, dönem özetine girmez |
| `POST /finance/opening-balances/:id/cancel` | M,B | — | 200 · ödemesi/bekleyen ödemesi varsa 409 |
| `GET /finance/expense-categories` | M,B,A | — | `{data:[{id,property_id,name,distribution_type,applies_to_commercial,applies_to_ground_floor,custom_formula,is_active,default_liability}]}` — `default_liability`: girişte önerilen sınıf (066) |
| `POST /finance/assessments` | M,B | `period_year`*,`period_month`*(1-12),`due_date`*,`expense_items`*[{`category_id`*,`amount`*>0,`liability`(USAGE/OWNER; boşsa kalemin varsayılanı)}] | 201 `{data:[özet],notification}` — bölüme sınıf başına ayrı tahakkuk (aynı ay kullanım + malik iki kayıt) · 409 dönem + sınıf var · 400 tanınmayan sınıf · `notification`: daire sakinlerine yeni borç bildiriminin sayaçları (B1) |
| `POST /finance/payments/:id/confirm` | M,B | `reference` | `{message}` · 404/409/403 |
| `POST /finance/payments/:id/reject` | M,B | — | `{message}` · 404/409 |
| `POST /finance/late-fees/accrue` | M,B | `as_of` | `{as_of,monthly_rate,legal_basis,processed_count,total_fee_kurus,total_fee_try,skipped_not_due}` |
| `POST /finance/payments` (`payment_method:"CREDIT_CARD"`, iyzico yapılandırılmışsa) | sakin | `assessment_ids`* | `{payment_id,amount,status:"PENDING",payment_gateway_ready:true,checkout_url,gateway_status:"INITIATED",value_date,note}` · 502 `{code:"CARD_GATEWAY"}` ödeme sayfası açılamadı |
| `GET /finance/payments/:id/status` | sahibi ya da M,B,A | — | `{payment_id,status,gateway_status,amount_kurus,error_code?,error_message?,failure_kind?(CARD/SYSTEM),value_date,created_at,completed_at?}` |
| `POST /public/payments/iyzico/callback` | **kimliksiz** (iyzico) | form `token` | `PAYMENT_RESULT_URL` varsa 303, yoksa `{payment_id,status,message}` · 404 jeton tanınmadı |
| `GET /finance/credit-notes` · `/:id/pdf` | herkes (sakin: kendi aktif daireleri) | — | `{data:[{id,document_no,assessment_id,unit_id,unit,period,amount_kurus,reason,created_by_name,created_at,reversed_at?,reversal_reason?}]}` · PDF |
| `POST /finance/credit-notes` | M,B | `assessment_id`*,`amount_try`*,`reason`*(≥5) | 201 `{credit_note,note}` · 422 kalan borç/anaparayı aşıyor |
| `POST /finance/credit-notes/:id/reverse` | M,B | `reason`*(≥5) | `{message,note}` · 409 zaten ters kaydı yapılmış |
| `GET /finance/units/:id/open-assessments` | M,B,A | — | `{data:[{id,period,due_date,total_kurus,paid_kurus,credited_kurus,outstanding_kurus,max_credit_kurus}]}` |
| `POST /finance/payments/:id/receipts` | ödemeyi bildiren sakin (ödeme PENDING, havale/nakit) | multipart `file` (PDF/PNG/JPEG/WEBP, ≤5 MB; içerik baytlardan tanınır) | 201 `{receipt:{id,payment_id,file_name,content_type,size_bytes,sha256,created_at},message}` — başkasının/sonuçlanmış ödemesi 403, 4. dosya 409, desteklenmeyen tür 422, depo yoksa 503 (B9) |
| `GET /finance/payments/:id/receipts` | ödemeyi bildiren sakin ya da M,B,A | — | `{data:[receipt]}` (B9) |
| `GET /finance/payments/:id/receipts/:receiptId/download` | ödemeyi bildiren sakin ya da M,B,A | — | dosya (`Content-Disposition: attachment`, `X-Content-SHA256`) (B9) || `POST /finance/collections` | M,B | `unit_id`*,`assessment_ids`*(1-60, aynı bölüm),`payment_method`*(BANK_TRANSFER\|CASH),`value_date`*(ileri olamaz),`reference` | 201 `{collection:{payment_id,amount_kurus,value_date,payment_method,status},message,notification}` — yönetimin tahsilat girişi (061): ödeme açılır ve aynı işlemde onaylanır, defter zincirine yazılır, bölüm sakinine bildirim; sakinin bekleyen bildirimi varsa 409; başka bölümün/kapanmış borç 422 |
| `POST /finance/bank-statements/lines/:id/collect` | M,B | `unit_id`*,`assessment_ids`* | 200 `{collection,payment_id,message,notification}` — eşleşmeyen ekstre satırını bölümün borçlarına işler; ödeme günü hareket günü; seçilen kalan toplam ≠ hareket tutarı 422; sonuçlanmış satır 409 || `POST /finance/bank-statements` | M,B | multipart `file` (.csv/.xlsx, ≤5 MB) | 201 `{import:{id,file_name,row_count,counts,lines:[{id,line_no,date,amount_kurus,description,reference,status(SUGGESTED/AMBIGUOUS/UNMATCHED/OUTGOING/DUPLICATE/CONFIRMED/IGNORED),suggested_payment_id,note,payer,unit}]},note}` · 400 okunamayan dosya |
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
| `GET /expense-categories` | M,B,A | — | `{data:[{id,property_id,name,description,type,distribution_type,reflects_to_assessment,applies_to_ground_floor,is_default,display_order,is_active,legal_basis,default_liability}]}` |
| `GET /expenses` | M,B,A | `year`,`month`,`status`,`category_id` | `{data:[Gider]}` |
| `GET /expenses/summary` | M,B,A | `year`,`month` | `{period_year,period_month,total_amount,invoiced_amount,non_invoiced_amount,pending_count,by_category:[{category_id,category_name,amount,count}]}` |
| `GET /expenses/:id` | M,B,A | — | Gider (+dağıtım) |
| `POST /expenses` | M,B | `category_id`*,`description`*,`amount`*>0,`expense_date`*,`is_invoiced`(true),`invoice_reason`(faturasızsa zorunlu),`reflects_to_assessment`,`assessment_period`(YYYY-MM),`distribution_type`(EQUAL/SHARE_RATIO/AREA_M2),`vendor_name`,`vendor_tax_id`,`invoice_number`,`invoice_date`,`notes`,`liability`(USAGE/OWNER; boşsa kalemin varsayılanı) | 201 `{expense, note?}` · 422 tanınmayan sınıf (066) |
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
 · B8: yanıtta `outliers[]` (kullanım alanı başına tüketimi site medyanının 3 katını aşan bölümler) ve `outlier_warning`; sapma varken `publish` için `confirm_outliers:true` zorunlu, yoksa 422 `OUTLIERS_UNCONFIRMED`
| `POST /consumption/statements/:id/objections` | bölümün aktif sakini | `unit_id`*,`reason`*(10-2000) | 201 `{objection,message,notification}` — yönetime bildirim; açık itiraz varken 409, sakin değilse 403 (B8) |
| `GET /consumption/objections` | herkes (yönetim tümü, sakin kendi bölümleri) | `status` (OPEN\|ACCEPTED\|REJECTED) | `{data:[{id,allocation_id,meter_type,period_from,period_to,unit_id,unit,user_name,total_kurus,reason,status,response,responded_at,responded_by_name,created_at}]}` (B8) |
| `POST /consumption/objections/:id/respond` | M,B | `decision`*(ACCEPTED\|REJECTED),`response`*(≥5) | 200 `{objection,message,notification}` — itiraz edene bildirim; yanıtlanmış itiraz 409; pusula değişmez (B8) || `/sensors/*`, `/iot/alerts/*` | — | — | **501** (sensör altyapısı yok) |

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
| `GET /governance/budgets` · `/budgets/:id` | — | `{data:[{id,period_year,status(DRAFT/NOTIFIED/FINAL),total_amount,notified_at,objection_deadline,approval_deadline,finalized_at}]}` · tam bütçe `{…,items:[{id,category_id,name,amount,distribution_type,kind,note,sort_order,liability}],unit_shares:[{unit_id,unit_name,annual_kurus,annual_usage_kurus,annual_owner_kurus,monthly_kurus,breakdown}],open_objections,approval_deadline,approved_agenda_item_id,cap_base_budget_id,cap_rate,cap_amount,decision_ref}` |
| `POST /governance/budgets` | `period_year`*(2000-2200),`items`*[{`name`*,`amount`*>0,`distribution_type`*(EQUAL/SHARE_RATIO/AREA_M2),`kind`(EXPENSE/INCOME),`category_id`,`note`,`liability`(USAGE/OWNER; boşsa kategorinin varsayılanı, o da yoksa USAGE)}],`note` | 201 bütçe — bölüm payı `annual_usage_kurus` + `annual_owner_kurus` = `annual_kurus` (066) · 422 tanınmayan sınıf |
| `POST /budgets/:id/notify` | `method`*(IMZA_KARSILIGI/TAAHHUTLU_MEKTUP/ELEKTRONIK) | bütçe — geçici proje; `approval_deadline` = +3 ay (KMK m.37, 7579). 422: yeniden değerleme tavanı aşıldı ya da oran tanımsız |
| `POST /budgets/:id/finalize` | `agenda_item_id`* (yapılmış genel kurulda kabul edilmiş madde), `decision_ref` | `{budget,note}` (İİK m.68 belgesi) · 422 madde kabul edilmemiş · 409 madde başka projede / proje kesinleşmiş |
| `POST /budgets/:id/assessments` | `period_month`*(1-12),`due_date`* | 201 `{period,created,created_by_class:{USAGE,OWNER},total_kurus,budget_status,note,notification}` — bildirilmiş/kesinleşmiş projeden aylık tahakkuk; bölüme sınıf başına ayrı kayıt (066) · 409 aynı ay + sınıf var · 422 taslak proje / vade aydan önce |
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

`banking` (S-07), `iot` sensör uçları (FAZ H.4'te tamamlanacak), `reports`.
2026-10-26'da kaldırıldı (FAZ H.1): `meeting_wizard` (governance ile tekrar), `settings.credentials`
(yerine gateway `GET /integrations/status`), `esg/sustainability-score`.

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

## Malikin görünürlük politikası (settings, 071 — altıncı tur D6)

| Uç | Kim | Gövde | Yanıt |
|---|---|---|---|
| `GET /settings/owner-visibility` | sitedeki herkes | — | `{active:{status(DEFAULT/ACTIVE),show_tenant_contact,show_tenant_debt_total,show_tenant_overdue,show_unit_requests,decided_at?,decided_by_name?},options:[{key,label}],always_visible[],never_visible[],note}` · yönetimde ek olarak `pending`, `history` — kayıt yoksa en dar (hepsi kapalı) |
| `POST /settings/owner-visibility` | M,B | `show_*` (bool),`note`*(≥10) | 201 `{id,status:PENDING}` · bekleyen öneri varsa 409 · gerekçesiz 422 |
| `POST /settings/owner-visibility/:id/approve` · `/reject` | BOARD_MEMBER, öneren DIŞINDA | `note` | 200 — onayda önceki sürüm SUPERSEDED, kiracılara `visibility.policy` bildirimi; kurul üyesi değilse ya da öneren ise 403 |
| `POST /settings/owner-visibility/:id/cancel` | öneren | — | 200 · başkası 404 |
| `GET /requests/units/:unitId` (community) | dairenin aktif maliki/vekili | — | `{data:[{id,ticket_number,title,category,status,priority,created_at,resolved_at?}]}` — kiracılı dairede yalnız `show_unit_requests` açıksa (aksi 403); talep edenin kimliği ve açıklaması dönmez |

## Kullanım hakkı (072 — altıncı tur D7)

Kullanım işlemleri (`POST /requests` daireli talep, `POST /visitors` sakin ön kaydı, `POST /vehicles`, rezervasyon, kargo
listesi, acil durum kartı/yanıtı, sayaç/pusula/itiraz, tüketim verisi) `resident_can_use` kuralına bağlıdır: kiracı ve hane
üyesi; malik/vekil yalnız dairede aktif kiracı yokken. Kiracılı dairede malik: talep 422, ziyaretçi/araç 403 — yanıt nedeni söyler.
`POST /visitors` sakin için artık daire ilişkisini denetler (başka dairenin ziyaretçisi 403); yönetim ve görevli her daireye kaydeder.
## marketplace (8111) — Usta & Hizmet pazaryeri (FAZ M, 076–079) — önek `/market`

Roller: **SUP** tedarikçi (`SUPPLIER`, platform rolü, sitesiz), **PA** platform yöneticisi (`PLATFORM_ADMIN`, yalnız
`cmd/platform-admin` ile verilir), **SAKİN** aktif sitede bölümü olan kişi (kendi dairesi için), **YÖN** site yöneticisi
(`MANAGER`, site adına), **GÖZ** yönetici/kurul üyesi/denetçi (site taleplerini okur). Platform rolleri site verisine yetki
vermez. Tutarlar kuruş tam sayı (`*_kurus`).

| Uç | Kim | Gövde / Sorgu | Yanıt |
|---|---|---|---|
| `GET /market/meta` | oturum açmış herkes | — | `{settings:[{key,value,description}],categories:[{id,parent_id,name,request_fee_kurus,buyer_scope,is_active,sort_order}],packages:[{id,name,monthly_fee_kurus,fee_discount_pct,included_requests,monthly_sms,priority_access,phone_in_showcase,rank_weight,is_default,is_active,sort_order}]}` — yalnız etkin kategori/paketler |
| `GET /market/supplier/me` | SUP | — | hesap `{id,user_id,trade_name,tax_number,tax_office,status,status_reason,reviewed_at,package:{…},next_package_id,package_renews_at,period_included_left,period_sms_left,balance_kurus,terms_accepted_at,created_at}` · hesap yoksa 404 `NO_ACCOUNT` · SUP değilse 403 |
| `POST /market/supplier/account` | SUP | `trade_name`,`tax_number`(10/11 hane),`tax_office`,`terms_accepted`*(true) | 201 hesap (DRAFT, varsayılan ücretsiz paket) · 422 sözleşme/vergi no · 409 `ACCOUNT_EXISTS` (FAZ M3) |
| `PUT /market/supplier/account` | SUP | `trade_name`,`tax_number`,`tax_office` | 200 hesap · 409 `NOT_DRAFT` (yalnız taslakta) |
| `POST /market/supplier/account/submit` | SUP | — | 200 hesap (REVIEW) · 422 `INCOMPLETE` eksikler tek mesajda (unvan, vergi no, vergi dairesi, vergi levhası ya da oda kaydı, kimlik belgesi) · 409 taslak değil |
| `GET /market/supplier/documents` | SUP | — | `{data:[{id,account_id,doc_type,file_name,content_type,size_bytes,sha256,status,review_note,reviewed_at,uploaded_at}]}` |
| `POST /market/supplier/documents` | SUP | çok parçalı: `doc_type`*(TAX_PLATE/ID_CARD/CHAMBER_RECORD/OTHER),`file`*(PDF/JPEG/PNG ≤10 MB; tür dosyanın kendisinden) | 201 belge · 422 tür (`valid_types`) · 415 dosya türü · 413 boyut · 409 taslak/inceleme dışı · 503 `NO_STORAGE` |
| `GET /market/supplier/documents/:id/file` | SUP (sahibi) | — | dosya (indirme); erişim `mp_document_access_logs`'a yazılır · başkasının belgesi 404 |
| `DELETE /market/supplier/documents/:id` | SUP (sahibi) | — | 200 · 409 `NOT_DELETABLE` (taslak değil, incelenmiş ya da açılmış belge) |
| `GET /market/supplier/businesses` | SUP | — | `{data:[işletme]}` işletme: `{id,account_id,name,description,phone,address,city,district,latitude,longitude,service_area(KM/CITY/COUNTRY),radius_km,status(DRAFT/REVIEW/PUBLISHED/REJECTED/CLOSED),review_note,reviewed_at,rating_count,rating_sum,completed_jobs,category_ids[],created_at}` |
| `POST /market/supplier/businesses` · `PUT /market/supplier/businesses/:id` | SUP | `name`*,`phone`*,`address`*,`city`*,`district`*,`latitude`*,`longitude`*,`service_area`*,`radius_km`(KM'de 1–500),`category_ids`*(etkin),`description` (telefon/e-posta gizlenir) | 201/200 işletme · 422 alan/konum/yarıçap/kategori · başkasının işletmesi 404 · kapalı işletme 409 |
| `GET /market/supplier/businesses/:id` | SUP (sahibi) | — | işletme · 404 |
| `POST /market/supplier/businesses/:id/submit` · `POST /market/supplier/businesses/:id/close` | SUP (sahibi) | — | 200 işletme (REVIEW / CLOSED) · 409 uygun durumda değil |
| `GET /market/supplier/businesses/:id/services` | SUP (sahibi) | — | `{data:[{id,business_id,name,description,price_min_kurus,price_max_kurus,unit,has_photo,is_active,sort_order}]}` |
| `POST /market/supplier/businesses/:id/services` · `PUT /market/supplier/services/:id` | SUP (sahibi) | `name`*,`description`,`price_min_kurus`+`price_max_kurus` (ikisi birlikte; boşsa "teklifle"),`unit`,`is_active`,`sort_order` | 201/200 kalem · 422 fiyat · 404 |
| `DELETE /market/supplier/services/:id` | SUP (sahibi) | — | 200 · 404 |
| `POST /market/supplier/services/:id/photo` | SUP (sahibi) | çok parçalı `file`*(JPEG/PNG/WebP ≤5 MB) | 200 · 415 · 404 |
| `GET /market/services/:id/photo` | oturum açmış herkes | — | görsel — yalnız vitrindeki (onaylı hesap, yayındaki işletme, etkin kalem) ya da tedarikçinin kendi kalemi; aksi 404 |
| `GET /market/supplier/notifications` | SUP | — | `{data:[{id,topic,subject,body,payload,created_at,read_at}],unread}` — tedarikçinin uygulama içi bildirimleri (sitesiz kayıt, 077) |
| `POST /market/supplier/notifications/read` | SUP | `ids` (boşsa hepsi) | `{marked}` |
| `GET /market/platform/accounts` | PA | `status` (DRAFT/REVIEW/APPROVED/SUSPENDED/CLOSED; boşsa hepsi) | `{data:[hesap + owner_name,owner_phone,owner_email,document_count,business_count,updated_at]}` (FAZ M4) |
| `GET /market/platform/accounts/:id` | PA | — | `{account,documents[],businesses[]}` |
| `POST /market/platform/accounts/:id/approve` · `POST /market/platform/accounts/:id/reject` · `POST /market/platform/accounts/:id/suspend` · `POST /market/platform/accounts/:id/reinstate` | PA | reject/suspend: `reason`*(≥5), reject: `reject_document_ids` | 200 `{account,notification:{in_app,email?}}` — onayda bekleyen belgeler onaylanır; retde hesap taslağa döner, seçilen belgeler reddedilir; tedarikçiye `market.supplier.*` bildirimi · 422 gerekçe · 409 durum |
| `GET /market/platform/documents/:id/file` | PA | — | dosya; erişim `PLATFORM` olarak kaydedilir |
| `GET /market/platform/businesses` | PA | `status` | `{data:[işletme]}` |
| `POST /market/platform/businesses/:id/approve` · `POST /market/platform/businesses/:id/reject` | PA | reject: `reason`*(≥5) | 200 `{business,notification}` — onayda PUBLISHED (vitrine çıkar); hesap onaylı değilse 409 `ACCOUNT_NOT_APPROVED` · incelemede değilse 409 |
| `GET /market/platform/categories` | PA | — | `{data:[kategori]}` pasifler dahil |
| `POST /market/platform/categories` · `PUT /market/platform/categories/:id` | PA | `name`*,`request_fee_kurus`*(≥0),`buyer_scope`*(RESIDENT/MANAGEMENT/BOTH),`parent_id`,`is_active`,`sort_order` | 201/200 kategori — değişiklik işlem kaydına (`details`) · 422 |
| `GET /market/platform/packages` | PA | — | `{data:[paket]}` |
| `POST /market/platform/packages` · `PUT /market/platform/packages/:id` | PA | `name`*,`monthly_fee_kurus`,`fee_discount_pct`(0–100),`included_requests`,`monthly_sms`,`priority_access`,`phone_in_showcase`,`rank_weight`,`is_active`,`sort_order` | 201/200 paket · 422 (varsayılan pakete aidat/öncelik/telefon konamaz) |
| `PUT /market/platform/settings/:key` | PA | `value`*(tam sayı ≥0) | 200 `{key,value,description}` · bilinmeyen anahtar 404 · 422 |
| `GET /market/supplier/wallet` | SUP | `limit`(1–200),`offset` | `{balance_kurus,package,next_package_id,package_renews_at,period_included_left,period_sms_left,data:[{id,kind(TOPUP/PACKAGE_FEE/REQUEST_FEE/INCLUDED_REQUEST/REFUND/CLOSURE_REFUND),amount_kurus,balance_after,topup_id,dispatch_id,package_id,note,created_at}],total,limit,offset,card_ready}` — bakiye = defter toplamı (FAZ M5) |
| `POST /market/supplier/topups` | SUP | başlık `Idempotency-Key`*; `amount_kurus`*(>0) | 201 `{topup:{id,amount_kurus,status:PENDING,…},checkout_url,note}` — iyzico ödeme sayfası; aynı anahtarla 200 aynı kayıt · farklı tutar 409 · anahtarsız 400 · iyzico yoksa 503 `NO_PAYMENT` · kapalı hesap 409 · sağlayıcı reddi 502 |
| `GET /market/supplier/topups/:id` | SUP (sahibi) | — | `{id,amount_kurus,status(PENDING/SUCCEEDED/FAILED),error_message,created_at,completed_at}` |
| `POST /public/market/topups/iyzico/callback` | iyzico (kimliksiz) | form `token` | sonuç sağlayıcıdan yeniden sorgulanır; tutar ve sepet doğrulanır; tek kez işlenir · tarayıcıya 303 `MARKET_TOPUP_RESULT_URL?topup_id&status&message` (JSON isteyene `{topup_id,status,message}`) · bilinmeyen jeton 404 |
| `POST /market/supplier/package` | SUP | `package_id`* | 200 `{account,message}` — daha pahalı/eşit pakete hemen geçilir (ilk ay aidatı bakiyeden, haklar tanımlanır); ucuza geçiş dönem sonunda; mevcut paketi seçmek bekleyen değişikliği iptal eder · 409 bakiye yetersiz / askı-kapalı hesap · 422 paket yok/satışta değil |
| `POST /market/platform/accounts/:id/close` | PA | `reason`*(≥5); bakiye varsa `refund_reference`*,`refund_date`*(YYYY-AA-GG) | 200 `{account,notification}` — kalan bakiye havaleyle iade edildi kaydı (`CLOSURE_REFUND`), bakiye 0, işletmeler kapanır · 422 dekont/gerekçe · 409 zaten kapalı |
| `GET /market/requests/match-count` | SAKİN · YÖN | `category_id`*,`buyer_type`(RESIDENT/MANAGEMENT),`target_business_id` | `{count}` — talebi alacak onaylı hesap sayısı (hizmet alanı siteyi kapsayan; yönetim talebinde sitede görevli kişinin hesabı hariç) · 422 kategori |
| `POST /market/requests` | SAKİN · YÖN | `category_id`*,`buyer_type`*,`description`*(≤2000; telefon/e-posta gizlenir),`preferred_time`,`phone_hidden`,`unit_id`(birden çok bölümde zorunlu),`target_business_id`(doğrudan talep),`consent`*(sakinde true) | 201 `{request,dispatched}` · 422 `CONSENT`/`CATEGORY`/`CATEGORY_SCOPE`/`UNIT`/`NO_SUPPLIER`/`TARGET` · 403 `ROLE`/`NOT_RESIDENT`/`NO_PROPERTY` · 429 `DAILY_LIMIT` · 409 `PROPERTY_INACTIVE` |
| `GET /market/requests` | SAKİN · GÖZ | `scope=management` (site adına açılanlar; yalnız GÖZ) | `{data:[talep]}` talep: `{id,buyer_type,unit_id,category_id,category_name,target_business_id,description,preferred_time,phone_hidden,photo_count,status(OPEN/FULL/EXPIRED/CLOSED/CANCELLED),accepted_count,max_accepts,dispatch_count,expires_at,closed_at,created_at,masked}` — sakin yalnız kendi talepleri |
| `GET /market/requests/:id` | SAKİN (sahibi) · GÖZ (site talebi) | — | talep + `accepted:[{business_id,business_name,accepted_at}]` · başkasının talebi 404 |
| `POST /market/requests/:id/photos` | SAKİN (sahibi) | çok parçalı `file`*(JPEG/PNG/WebP ≤5 MB) | 200 · 409 `PHOTOS` (en çok 3; kapanmış talep) · 404 |
| `GET /market/requests/:id/photos/:n` | SAKİN (sahibi) · GÖZ | — | görsel · 404 |
| `GET /market/supplier/requests` | SUP | — | `{data:[önizleme],balance_kurus,period_included_left,account_status}` önizleme: `{id,buyer_type,category_name,city,district,distance_m,business_id,business_name,description,preferred_time,phone_hidden,photo_count,direct,status,accepted_count,max_accepts,expires_at,visible_at,accepted_at,fee_kurus,uses_included,can_afford,created_at}` — ad, telefon, adres YOK; öncelik penceresindeki talep görünmez |
| `GET /market/supplier/requests/:id` | SUP (gönderilen) | — | önizleme; kabul ettiyse `contact:{name,phone(gizliyse null),site_name,site_address}` · 404 |
| `POST /market/supplier/requests/:id/accept` | SUP (gönderilen) | — | 200 `{request,message}` — dahil talep hakkı varsa o, yoksa kabul ücreti (paket indirimiyle) bakiyeden aynı işlemde düşer; iletişim açılır; işlem kaydı `market.request.accepted` · 409 `ALREADY_ACCEPTED`/`FULL`/`CLOSED`/`INSUFFICIENT_BALANCE`/`ACCOUNT_STATE` · 404 |
| `GET /market/supplier/requests/:id/photos/:n` | SUP (gönderilen) | — | görsel · 404 |
| `GET /market/supplier/requests/:id/deal` | SUP (kabul eden) | — | `{offers:[teklif],job,dispute}` teklif: `{id,request_id,dispatch_id,business_id,business_name,amount_kurus,description,valid_until,status(ACTIVE/WITHDRAWN/ACCEPTED/DECLINED),created_at,updated_at}` |
| `POST /market/supplier/requests/:id/offers` | SUP (kabul eden) | `amount_kurus`*(>0),`description`*(≤2000),`valid_until`*(YYYY-AA-GG, bugün ya da sonrası) | 200 teklif — etkin teklif varsa güncellenir; alıcıya `market.offer.new` · 403 `NOT_ACCEPTED` · 409 `REQUEST_CLOSED` · 422 |
| `POST /market/supplier/offers/:id/withdraw` | SUP (sahibi) | — | 200 · 409 `OFFER_STATE` |
| `GET /market/supplier/requests/:id/messages` · `POST /market/supplier/requests/:id/messages` | SUP (kabul eden) | GET: `before`(RFC3339),`limit`(≤200); POST: `body`*(≤2000) | `{data:[{id,sender_side(BUYER/SUPPLIER),body,created_at,anonymized}]}` yeni→eski · 201 mesaj, alıcıya `market.message` · 403 `NOT_ACCEPTED` · 404 |
| `POST /market/supplier/jobs/:id/done` | SUP (işin sahibi) | — | 200 iş (DONE_CLAIMED); alıcıya `market.job.completed` · 409 `JOB_STATE` · 404 |
| `POST /market/supplier/requests/:id/dispute` | SUP (kabul eden) | `reason_code`*(FAKE/WRONG_CATEGORY/UNREACHABLE/OTHER),`note`*(10–2000) | 201 bildirim · 409 `ALREADY_DISPUTED` · 403 · 422 |
| `GET /market/supplier/reviews` | SUP | — | `{data:[{id,business_id,business_name,rating,comment,reply,replied_at,hidden_at,hidden_reason,created_at}]}` |
| `POST /market/supplier/reviews/:id/reply` | SUP (işletmenin sahibi) | `reply`*(≤1000) | 200 · 409 `ALREADY_REPLIED` (bir kez) · 404 |
| `GET /market/requests/:id/offers` | SAKİN (sahibi) · GÖZ | — | `{data:[teklif + business_phone,rating_sum,rating_count,completed_jobs]}` — geri çekilenler hariç, tutara göre |
| `POST /market/requests/:id/offers/:offerId/select` | SAKİN (sahibi) · YÖN | — | 200 `{job,declined}` — iş oluşur, talep CLOSED, diğer etkin teklifler DECLINED (`market.offer.accepted`/`declined`) · 409 `REQUEST_CLOSED`/`OFFER_STATE`/`OFFER_EXPIRED` · 404 |
| `POST /market/requests/:id/close` | SAKİN (sahibi) · YÖN | — | 200 — teklif seçmeden kapatma (CANCELLED); kabul ücretleri iade edilmez · 409 |
| `GET /market/requests/:id/messages/:dispatchId` · `POST /market/requests/:id/messages/:dispatchId` | SAKİN (sahibi) · YÖN (yazma) · GÖZ (okuma) | tedarikçi tarafıyla aynı | yalnız kabul edilmiş gönderimde; tedarikçiye `market.message` · 404 |
| `GET /market/requests/:id/job` | SAKİN (sahibi) · GÖZ | — | iş `{id,request_id,offer_id,business_id,business_name,amount_kurus,status(ACTIVE/DONE_CLAIMED/COMPLETED/DISPUTED),supplier_done_at,completed_at,completion_source(BUYER/AUTO),dispute_note,created_at,review}` · 404 |
| `POST /market/requests/:id/job/confirm` · `POST /market/requests/:id/job/dispute` | SAKİN (sahibi) · YÖN | dispute: `note`*(≥5) | 200 iş — onay DONE_CLAIMED ya da DISPUTED → COMPLETED (BUYER); itiraz DONE_CLAIMED → DISPUTED (otomatik tamamlanmaz) · 409 `JOB_STATE` · 422 |
| `POST /market/requests/:id/review` | SAKİN (sahibi) · YÖN | `rating`*(1–5),`comment`(≤1000) | 201 puan (işletmeye; özet tetikleyiciyle) · 409 `JOB_NOT_COMPLETED`/`ALREADY_REVIEWED` |
| `GET /market/platform/disputes` | PA | `status`(OPEN/APPROVED/REJECTED) | `{data:[{id,request_id,account_id,trade_name,category,reason_code,note,status,fee_kurus,used_included,decided_at,decision_note,created_at}]}` |
| `POST /market/platform/disputes/:id/approve` · `POST /market/platform/disputes/:id/reject` | PA | `note`*(≥5) | 200 `{dispute,notification}` — onayda ücret bakiyeye REFUND (dahil hakla kabulde hak geri), tek kez; `market.dispute.resolved` · 409 `DECIDED`/`ALREADY_REFUNDED` |
| `GET /market/platform/reviews` | PA | `hidden`(1/0) | `{data:[yorum]}` |
| `POST /market/platform/reviews/:id/hide` | PA | `reason`*(≥5) | 200 — silinmez, gizlenir, puan özetinden çıkar; işlem kaydı `market.review.hidden` · 409 `ALREADY_HIDDEN` |
| `GET /market/platform/revenue` | PA | `from`*,`to`*(YYYY-AA-GG) | `{from,to,package_fees_kurus,request_fees_kurus,refunds_kurus,net_kurus,topups_kurus,closure_refunds_kurus,included_requests,ledger_total_kurus,balance_liability_kurus}` · 422 `PERIOD` |
