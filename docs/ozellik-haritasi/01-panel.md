# 1. Yönetim paneli (Next.js) — sayfa sayfa

Kaynak: `admin/src/app/**/page.tsx` ve içe aktardığı `admin/src/components/**`. Sayfa yetkisi `admin/src/lib/rbac.ts` (panel) — asıl denetim backend'dedir (tablodaki *Yetki* sütunu). `canWrite` = MANAGER veya BOARD_MEMBER (`admin/src/lib/use-api.ts:78`); AUDITOR yalnız okur.


## Üst

### Panel — `/dashboard`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Veri (satır 17): `GET /dashboard/stats` (gateway)
  - Veri (satır 18): `GET /dashboard/recent-payments` (gateway)
  - Veri (satır 19): `GET /dashboard/recent-requests` (gateway)
  - Bilgi notu (satır 27): Bazı özet veriler alınamadı: {missing.map((u) => ( {u.source}: {u.reason} ))} Eksik kartlarda uydurma değer gösterilmez
  - Kart (satır 52): Son ödemeler
  - Bağlantı (satır 52): Tümü → /dashboard/accounting
  - Tablo (satır 55): Kişi \| Daire \| Tutar \| Durum \| Tarih
  - Kart (satır 69): Son talepler
  - Bağlantı (satır 69): Tümü → /dashboard/requests
  - Tablo (satır 72): No \| Başlık \| Durum \| Tarih
- **Eylem:** yok (salt bilgi / yönlendirme)


## Sakinler ve İletişim

### Duyurular — `/dashboard/announcements`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/announcements/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Duyuru yönetimi
- **Ekranda:**
  - Veri (satır 21): `GET /announcements` (community)
  - Veri (satır 27): `GET /announcements/:id/read-stats` (community)
  - Tablo (satır 39): Başlık \| Kategori \| Öncelik \| Yayım \| Okunma
  - Bilgi notu (satır 109): Genel kurul çağrısı KMK m.29 gereği imza karşılığı ya da taahhütlü mektupla yapılır. Bu du
  - Pencere (satır 115): Okunma istatistiği
  - Bilgi notu (satır 120): {s.note}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Duyuru yayımla (yalnız yazma yetkisi; pencere/form açar)** (satır 33) | — | | | | |
| 2 | Düğme **İstatistik (pencere/form açar)** (satır 52) | — | | | | |
| 3 | Düğme **Sabitlemeyi kaldır (yalnız yazma yetkisi)** (satır 54) | `POST /announcements/:id/pin` · community · `services/community/main.go:173` | BOARD_MEMBER/MANAGER | announcements(±) | yok | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |
| 4 | Form **Duyuru yayımla — alanlar: Başlık*, İçerik*, Kategori, Öncelik, Yayından kalkış, Sabitle — başarı: ** (satır 68) | `POST /announcements` · community · `services/community/main.go:138` | BOARD_MEMBER/MANAGER | announcements(+) | `announcement`, `announcement.urgent` → Residents | Panel/announcements, Sakin announcements, Sakin resident_home, Yön.mobil announcements |

### İlan Panosu — `/dashboard/bulletins`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/bulletins/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — İlan panosu onayı
- **Ekranda:**
  - Veri (satır 19): `GET /bulletins` (bulletin)
  - Veri (satır 20): `GET /bulletins-summary` (bulletin)
  - Veri (satır 25): `GET /bulletins/:id/comments` (bulletin)
  - Kart (satır 38): İlanlar
  - Tablo (satır 41): İlan \| Kategori \| Fiyat \| Sahibi \| Tarih \| Durum
  - Tablo (satır 75): Zaman \| Yazan \| Yorum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Süresi dolanları işle** (satır 30) | `POST /bulletins/expire-due` · bulletin · `services/bulletin/main.go:205` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 2 | Düğme **Yorumlar (pencere/form açar)** (satır 50) | — | | | | |
| 3 | Düğme **Onayla (başarı: İlan yayımlandı)** (satır 53) | `POST /bulletins/:id/approve` · bulletin · `services/bulletin/main.go:170` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 4 | Düğme **Reddet (pencere/form açar)** (satır 54) | — | | | | |
| 5 | Düğme **Kapat (başarı: İlan kapatıldı)** (satır 57) | `POST /bulletins/:id/close` · bulletin · `services/bulletin/main.go:106` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_posts(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 6 | Form **İlanı reddet — alanlar: Gerekçe* — başarı: İlan reddedildi; gerekçe sahibine gösterilir** (satır 64) | `POST /bulletins/:id/reject` · bulletin · `services/bulletin/main.go:183` | BOARD_MEMBER/MANAGER | bulletin_posts(±) | `bulletin.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |
| 7 | Düğme **Gizle (başarı: Yorum gizlendi; onay sorar)** (satır 79) | `DELETE /bulletin-comments/:id` · bulletin · `services/bulletin/main.go:154` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | bulletin_comments(±) | yok | Panel/bulletins, Sakin bulletin_board_mobile, Yön.mobil bulletin_board |

### Acil Durum — `/dashboard/emergency`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/emergency/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Acil durum planı ve sakin acil bilgi kartları (özel nitelikli veri)
- **Ekranda:**
  - Veri (satır 27): `GET /emergency/info` (community)
  - Veri (satır 28): `GET /emergency/drills` (community)
  - Veri (satır 29): `GET /emergency/checks` (community)
  - Bilgi notu (satır 42): Her türlü acil durumda 112 aranır. Bu sayfadaki bilgi kartı sakin uygulamasında çevrimdışı
  - Kart (satır 44): Durum bildirimi (afet sonrası)
  - Tablo (satır 47): Çağrı \| Tür \| Açılış \| Durum \| Yanıt \| Yardım
  - Kart (satır 61): Toplanma alanı ve kritik altyapı
  - Tablo (satır 64): Tür \| Ad \| Konum
  - Kart (satır 75): Acil iletişim
  - Tablo (satır 78): Kategori \| Ad \| Telefon
  - Kart (satır 91): Tatbikatlar
  - Tablo (satır 95): Tarih \| Tür \| Katılım \| Görülen eksiklikler \| Düzeltici faaliyet
  - Kart (satır 107): Sakin acil bilgi kartları
  - Tablo (satır 114): Daire \| Sakin \| Yardım ihtiyacı \| Hane \| Yakını
  - Bilgi notu (satır 166): Bütün sakinlere &ldquo;Güvendeyim / Yardım gerekiyor&rdquo; yanıtı istenen bildirim gider.
  - Veri (satır 177): `GET /emergency/checks/:id/responses` (community)
  - Pencere (satır 180): Durum yanıtları
  - Tablo (satır 191): Durum \| Daire \| Sakin \| Not \| Zaman
  - Bilgi notu (satır 198): Henüz yanıt vermeyen daireler: {d.silent_units.join(", ")}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Çağrı başlat (yalnız yazma yetkisi; pencere/form açar)** (satır 44) | — | | | | |
| 2 | Düğme **Yanıtlar (pencere/form açar)** (satır 54) | — | | | | |
| 3 | Düğme **Ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 61) | — | | | | |
| 4 | Düğme **Sil (yalnız yazma yetkisi; başarı: Silindi)** (satır 69) | `DELETE /emergency/points/:id` · community · `services/community/emergency.go:91` | BOARD_MEMBER/MANAGER | — | yok |  |
| 5 | Düğme **Ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 75) | — | | | | |
| 6 | Düğme **Sil (yalnız yazma yetkisi; başarı: Silindi)** (satır 83) | `DELETE /emergency/contacts/:id` · community · `services/community/emergency.go:117` | BOARD_MEMBER/MANAGER | — | yok |  |
| 7 | Düğme **Tatbikat kaydet (yalnız yazma yetkisi; pencere/form açar)** (satır 91) | — | | | | |
| 8 | Düğme **Kartları görüntüle (kayda geçer) (yalnız yazma yetkisi)** (satır 109) | `GET /emergency/cards` · community · `services/community/emergency.go:250` | BOARD_MEMBER/MANAGER | — | yok | — |
| 9 | Form **Nokta ekle — alanlar: Tür, Ad*, Konum*, Not — başarı: Eklendi** (satır 125) | `POST /emergency/points` · community · `services/community/emergency.go:72` | BOARD_MEMBER/MANAGER | emergency_points(+) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 10 | Form **Acil iletişim ekle — alanlar: Kategori, Ad*, Telefon*, Not — başarı: Eklendi** (satır 134) | `POST /emergency/contacts` · community · `services/community/emergency.go:98` | BOARD_MEMBER/MANAGER | emergency_contacts(+) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 11 | Form **Tatbikat raporu — alanlar: Tür, Tarih*, Katılımcı sayısı, Görülen eksiklikler*, Düzeltici ve önleyici faaliyetler — başarı: Tatbikat kaydedildi** (satır 143) | `POST /emergency/drills` · community · `services/community/emergency.go:134` | BOARD_MEMBER/MANAGER | emergency_drills(+) | yok | Panel/emergency, Yön.mobil emergency |
| 12 | Form **Durum bildirimi çağrısı — alanlar: Tür, Başlık* — başarı: ** (satır 159) | `POST /emergency/checks` · community · `services/community/emergency.go:286` | BOARD_MEMBER/MANAGER | safety_checks(+) | `safety.check` → Residents | Panel/emergency, Sakin emergency, Yön.mobil emergency |
| 13 | Düğme **Çağrıyı kapat (başarı: Çağrı kapatıldı)** (satır 200) | `POST /emergency/checks/:id/close` · community · `services/community/emergency.go:383` | BOARD_MEMBER/MANAGER | safety_checks(±) | yok | Panel/emergency, Sakin emergency, Yön.mobil emergency |

### Sigorta (DASK) — `/dashboard/insurance`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/insurance/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — DASK poliçeleri ve hasar kayıtları
- **Ekranda:**
  - Veri (satır 21): `GET /insurance/dask` (contract)
  - Veri (satır 22): `GET /insurance/claims` (contract)
  - Kart (satır 39): Bağımsız bölüm DASK poliçeleri
  - Tablo (satır 43): Daire \| Poliçe \| Bitiş \| Durum
  - Kart (satır 55): Hasar / tazminat kayıtları
  - Tablo (satır 58): Olay \| Açıklama \| Talep \| Durum \| Ödenen
  - Bilgi notu (satır 111): Sigortacının ret gerekçesini yazın.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Poliçe gir (yalnız yazma yetkisi; pencere/form açar)** (satır 48) | — | | | | |
| 2 | Düğme **Hasar kaydet (yalnız yazma yetkisi; pencere/form açar)** (satır 55) | — | | | | |
| 3 | Düğme **İlerlet (pencere/form açar)** (satır 64) | — | | | | |
| 4 | Form **DASK poliçesi — ${policy?.row.unit ?? ""} — alanlar: Poliçe no*, Sigorta şirketi, Başlangıç*, Bitiş* — başarı: Poliçe kaydedildi** (satır 70) | `POST /insurance/dask` · contract · `services/contract/main.go:71` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | unit_insurance_policies(+) | yok | Panel/insurance, Sakin dask, Yön.mobil insurance |
| 5 | Form **Hasar kaydı — alanlar: Olay tarihi*, Talep edilen (TL), Sigortacı dosya no, Açıklama* — başarı: Hasar kaydedildi** (satır 83) | `POST /insurance/claims` · contract · `services/contract/main.go:114` | BOARD_MEMBER/MANAGER | insurance_claims(+) | yok | Panel/insurance, Yön.mobil insurance |
| 6 | Form **Hasar durumunu ilerlet — alanlar: Yeni durum, Ödenen tazminat (TL)*, Ödeme tarihi*, Not* — başarı: Güncellendi** (satır 98) | `POST /insurance/claims/:id/status` · contract · `services/contract/main.go:115` | BOARD_MEMBER/MANAGER | insurance_claims(±) | yok | Panel/insurance, Yön.mobil insurance |

### KVKK Başvuruları — `/dashboard/kvkk`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/kvkk/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — KVKK ilgili kişi başvuruları (kişisel veri)
- **Ekranda:**
  - Veri (satır 20): `GET /kvkk-requests` (community)
  - Tablo (satır 31): Başvuran \| Tür \| Talep \| Başvuru \| Son gün \| Durum
  - Bilgi notu (satır 75): {answer.r.applicant_name} — {TYPE_LABEL[answer.r.request_ty}: {answer.r.description}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yanıtla (pencere/form açar)** (satır 50) | — | | | | |
| 2 | Form **Başvuruyu sonuçlandır — alanlar: Sonuç, Yanıt* — başarı: Başvuru sonuçlandırıldı; başvurana bildirildi** (satır 59) | `POST /kvkk-requests/:id/respond` · community · `services/community/kvkk.go:99` | BOARD_MEMBER/MANAGER | kvkk_requests(±) | `kvkk.response` → işlemin muhatabı (k.UserID) | Panel/kvkk, Sakin kvkk_requests, Yön.mobil kvkk_requests |

### Toplu Bildirim — `/dashboard/notifications`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/notifications/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — Toplu bildirim gönderimi
- **Ekranda:**
  - Veri (satır 28): `GET /notifications/outbox` (notification)
  - Veri (satır 29): `GET /notifications/summary` (notification)
  - Veri (satır 30): `GET /notification-preferences` (notification)
  - Veri (satır 31): `GET /residents` (identity)
  - Sekmeler (satır 47): Giden kutusu, Kendi tercihlerim
  - Kart (satır 49): Kuyruk
  - Tablo (satır 57): Zaman \| Alıcı \| Kanal \| Konu \| Durum
  - Kart (satır 69): Kanal tercihlerim
  - Bilgi notu (satır 73): {d.note}
  - Tablo (satır 74): Kanal \| Tür \| Durum \| Onay

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Bildirim gönder (pencere/form açar)** (satır 39) | — | | | | |
| 2 | Düğme **Kapat (başarı: Tercih güncellendi)** (satır 80) | `PUT /notification-preferences` · notification · `services/notification/main.go:124` | oturum açmış herkes (site kapsamı) | notification_preferences(+) | yok | Panel/notifications, Sakin profile_settings, Yön.mobil notification_center |
| 3 | Form **Bildirim gönder — alanlar: Alıcı*, Kanal, Tür, Konu, İleti* — başarı: ** (satır 93) | `POST /notifications` · notification · `services/notification/main.go:158` | BOARD_MEMBER/MANAGER | — | `{{in}.Topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |

### Tadilat İzinleri — `/dashboard/renovations`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/renovations/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Tadilat izinleri ve kat maliki rızaları
- **Ekranda:**
  - Veri (satır 29): `GET /renovations` (community)
  - Veri (satır 30): `GET /units` (identity)
  - Tablo (satır 44): Daire \| Kapsam \| Başvuran \| Tarih \| Durum \| Teminat
  - Bilgi notu (satır 76): {SCOPE.find((s) => s.value === }
  - Veri (satır 85): `GET /renovations/:id` (community)
  - Veri (satır 86): `GET /residents` (identity)
  - Pencere (satır 96): Tadilat izni
  - Tablo (satır 121): Kat maliki \| Belge tarihi \| Belge

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Başvuru gir (yalnız yazma yetkisi; pencere/form açar)** (satır 39) | — | | | | |
| 2 | Düğme **Aç (pencere/form açar)** (satır 51) | — | | | | |
| 3 | Form **Tadilat başvurusu — alanlar: Daire*, Kapsam*, Başlangıç*, Bitiş*, Müteahhit / usta, Müteahhit telefonu, Yapılacak iş* — başarı: ** (satır 57) | `POST /renovations` · community · `services/community/renovation.go:88` | işleyicide `isManagement` (backend/services/community/main.go:257) | renovation_permits(+) | `renovation.request` → Approvers | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 4 | Düğme **Rızayı kaydet** (satır 134) | `POST /renovations/:id/consents` · community · `services/community/renovation.go:161` | BOARD_MEMBER/MANAGER | renovation_consents(+) | yok | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 5 | Düğme **Onayla** (satır 155) | `POST /renovations/:id/approve` · community · `services/community/renovation.go:190` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.approved`, `renovation.neighbors` → BlockNeighbors, işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 6 | Düğme **Reddet (pencere/form açar)** (satır 158) | — | | | | |
| 7 | Düğme **Denetle ve kapat (pencere/form açar)** (satır 164) | — | | | | |
| 8 | Düğme **Çalışmayı durdur (pencere/form açar)** (satır 165) | — | | | | |
| 9 | Form **(başlık dinamik) — alanlar: Gerekçe* — başarı: Kaydedildi; başvurana bildirildi** (satır 170) | `POST /renovations/:id/stop` · community · `services/community/renovation.go:302` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.stopped` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
|  | ↳ | `POST /renovations/:id/reject` · community · `services/community/renovation.go:284` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.rejected` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |
| 10 | Form **Denetle ve kapat — alanlar: Denetim notu — başarı: İzin kapatıldı** (satır 178) | `POST /renovations/:id/complete` · community · `services/community/renovation.go:320` | BOARD_MEMBER/MANAGER | renovation_permits(±) | `renovation.completed` → işlemin muhatabı (p.ApplicantID) | Panel/renovations, Sakin renovations, Yön.mobil renovations |

### Talepler — `/dashboard/requests`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/requests/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Talep yönetimi
- **Ekranda:**
  - Veri (satır 18): `GET /requests` (community)
  - Tablo (satır 36): No \| Başlık \| Öncelik \| Durum \| Açılış

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **{NEXT[r.status].label} (yalnız yazma yetkisi; başarı: ${r.ticket_number}: durum güncellendi)** (satır 49) | `PATCH /requests/:id/status` · community · `services/community/main.go:85` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/STAFF | requests(±) | yok | Panel/requests, Sakin requests, Sakin unit_residents, Yön.mobil request_detail, Yön.mobil requests |

### Sakinler — `/dashboard/residents`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/residents/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Sakin kimlik bilgileri
- **Ekranda:**
  - Bilgi notu (satır 79): {act.sms.note}
  - Bilgi notu (satır 80): E-posta gönderildi: {act.email.note}
  - Bilgi notu (satır 81): Bu kod bir daha gösterilmez: {act.note}
  - Veri (satır 93): `GET /residents` (identity)
  - Veri (satır 94): `GET /units` (identity)
  - Veri (satır 95): `GET /residents/invitations` (identity)
  - Tablo (satır 133): Ad Soyad \| Telefon \| Daire \| Sıfat \| Durum
  - Kart (satır 178): Sakin davetleri
  - Tablo (satır 186): Telefon \| Daire \| Sıfat \| Durum \| Gönderildi
  - Bilgi notu (satır 261): Malik daveti yalnız maliki kayıtlı olmayan daireye; hane üyesi daveti yalnız dairede otura
  - Bilgi notu (satır 287): Kişinin kimliğini doğrulayın. Eski numarayla açık oturumlar kapanır; eski numaraya (SMS sa
  - Bilgi notu (satır 312): Düzeltilmesi gereken satırlar: {bulk.errors.slice(0, 10).join(}
  - Bilgi notu (satır 313): {bulk.rows.length} satır gönderilecek.
  - Pencere (satır 317): Toplu ekleme sonucu
  - Bilgi notu (satır 319): Kodlar bir daha gösterilmez: Etkinleştirme kodlarını sakinlere iletin; bu pencere kapanınca kodlar görüntülenemez (gere
  - Tablo (satır 320): Satır \| Telefon \| Sonuç \| Kod / neden
  - **Bileşen `admin/src/components/residents/tenancy-ends.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 41): `GET /residents/tenancy-requests` (identity)
  - Veri (satır 42): `GET /units` (identity)
  - Kart (satır 71): Kiracılık bitişleri
  - Tablo (satır 82): Daire \| Kiracı \| Yol \| Durum \| Süre / bitiş \| Belgeler ve kayıt
  - Bilgi notu (satır 134): Beyan: {attestation}
  - Dosya seçme (satır 144)
  - Bilgi notu (satır 167): Belge sahte ya da hatalı çıktıysa kiracılık aynı kayıtla, geçmişiyle geri açılır. Dairede 

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kopyalandı (pencere/form açar)** (satır 63) | — | | | | |
| 2 | Düğme **Kodu ilettim, kapat — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 83) | — | | | | |
| 3 | Düğme **Toplu ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 119) | — | | | | |
| 4 | Düğme **Davet gönder (yalnız yazma yetkisi; pencere/form açar)** (satır 120) | — | | | | |
| 5 | Düğme **Sakin ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 121) | — | | | | |
| 6 | Düğme **Kod üret (yalnız yazma yetkisi)** (satır 147) | `POST /residents/:id/activation-code` · identity · `services/identity/main.go:152` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | user_activation_codes(+), user_activation_codes(±) | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta |  |
| 7 | Düğme **Telefon (pencere/form açar)** (satır 162) | — | | | | |
| 8 | Düğme **Kilidi aç** (satır 163) | `POST /residents/:id/unlock` · identity · `services/identity/main.go:156` | BOARD_MEMBER/MANAGER | users(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 9 | Düğme **Düzenle (pencere/form açar)** (satır 165) | — | | | | |
| 10 | Düğme **İptal et (başarı: Davet iptal edildi)** (satır 201) | `POST /residents/invitations/:id/cancel` · identity · `services/identity/main.go:141` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | resident_invitations(±) | yok | Panel/residents, Sakin invitations_banner, Yön.mobil resident_tools |
| 11 | Form **Sakin ekle — alanlar: Ad*, Soyad*, Telefon*, E-posta, Bağımsız bölüm*, Sıfat* — başarı: ** (satır 215) | `POST /residents` · identity · `services/identity/main.go:137` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), resident_units(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.activation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 12 | Form **Daire daveti gönder — alanlar: Ad, Soyad, Telefon*, E-posta, Bağımsız bölüm*, Sıfat* — başarı: ** (satır 246) | `POST /residents/invitations` · identity · `services/identity/main.go:140` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) | `identity.invitation` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 13 | Form **Telefon değiştir — ${phoneEdit?.r.first_name ?? ""} ${phoneEdit?.r.last_name ?? ""} — alanlar: Yeni telefon* — başarı: ** (satır 277) | `POST /residents/:id/phone` · identity · `services/identity/main.go:155` | BOARD_MEMBER/MANAGER | user_activation_codes(+), user_token_invalidation(+), user_activation_codes(±), users(±) | `identity.activation`, `identity.phone_changed` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin violations, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 14 | Form **Toplu sakin ekle — alanlar:  — başarı: ** (satır 291) | `POST /residents/bulk` · identity · `services/identity/main.go:138` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_invitations(+), resident_units(+), user_activation_codes(+), users(+), resident_invitations(±), user_activation_codes(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Panel/visitors, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin kvkk_requests, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 15 | Düğme **Kodları ilettim, kapat (pencere/form açar)** (satır 330) | — | | | | |
| 16 | Form **(başlık dinamik) — alanlar: Sıfat, Durum, Ayrılış (ilişik kesme) tarihi — başarı: Sakin kaydı güncellendi** (satır 335) | `PATCH /residents/:id` · identity · `services/identity/main.go:151` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY/TENANT | resident_units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 17 | Düğme **Yönetim yolu başlat (yalnız yazma yetkisi; pencere/form açar)** (tenancy-ends satır 72) | — | | | | |
| 18 | Düğme **Tamamla** (tenancy-ends satır 108) | `POST /residents/tenancy-requests/:id/complete` · identity · `services/identity/main.go:146` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER/OWNER/PROXY | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±), units(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 19 | Düğme **Yeni belge (pencere/form açar)** (tenancy-ends satır 113) | — | | | | |
| 20 | Düğme **İptal** (tenancy-ends satır 116) | `POST /residents/tenancy-requests/:id/cancel` · identity · `services/identity/main.go:147` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | tenancy_end_events(+), tenancy_end_requests(±) | yok | Panel/residents, Sakin tenancy_requests, Yön.mobil resident_tools |
| 21 | Düğme **Geri al (pencere/form açar)** (tenancy-ends satır 120) | — | | | | |
| 22 | Form **Kiracılığı geri aç — alanlar: Gerekçe*, Şifreniz* — başarı: ** (tenancy-ends satır 161) | `POST /residents/tenancy-requests/:id/reverse` · identity · `services/identity/main.go:148` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | tenancy_end_events(+), resident_units(±), tenancy_end_requests(±) · tetikleyici: trg_resident_units_tenancy_guard, trg_resident_units_tenant_arrival, trg_resident_units_tenant_departure | `identity.tenancy` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/accounting, Panel/announcements, Panel/assessments, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin common_income, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil renovations, Yön.mobil reports, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### Görevlendirmeler — `/dashboard/roles`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/roles/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetim görevlendirmeleri
- **Ekranda:**
  - Veri (satır 26): `GET /property-roles` (identity)
  - Bilgi notu (satır 41): Görev verme ve sonlandırma yalnızca yöneticinin yetkisindedir.
  - Tablo (satır 45): Kişi \| Telefon \| Görev \| Dönem \| Karar \| Durum \| Atayan
  - Pencere (satır 116): Hesap etkinleştirme kodu
  - Bilgi notu (satır 121): Bu kod bir daha gösterilmez: {shown.act.note}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Görev ver (pencere/form açar)** (satır 38) | — | | | | |
| 2 | Düğme **Sonlandır (başarı: Görev sonlandırıldı; onay sorar)** (satır 61) | `POST /property-roles/:id/end` · identity · `services/identity/main.go:176` | serviste rol karşılaştırması: MANAGER | user_token_invalidation(+), property_roles(±) | yok | Panel/roles, Sakin dues_payment, Sakin emergency, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil main, Yön.mobil roles |
| 3 | Form **Görev ver — alanlar: Telefon*, Görev*, Kurul kararı*, Bitiş tarihi, Ad, Soyad — başarı: Görev verildi** (satır 78) | `POST /property-roles` · identity · `services/identity/main.go:175` | serviste rol karşılaştırması: AUDITOR/BOARD_MEMBER/MANAGER/STAFF | property_roles(+), user_activation_codes(+), users(+), user_activation_codes(±) | yok | Panel/accounting, Panel/announcements, Panel/bulletins, Panel/documents, Panel/emergency, Panel/governance/assemblies, Panel/governance/common-area, Panel/inventory, Panel/kvkk, Panel/meters, Panel/notifications, Panel/packages, Panel/patrol, Panel/patrol/reports, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/roles, Panel/sensors, Panel/settings, Panel/surveys, Panel/units, Panel/violations, Sakin announcements, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin documents, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin kvkk_requests, Sakin more, Sakin my_meters, Sakin my_reservations, Sakin owner_visibility, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin surveys_mobile, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil dashboard, Yön.mobil documents, Yön.mobil emergency, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil inventory_management, Yön.mobil kvkk_requests, Yön.mobil main, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil roles, Yön.mobil sensors, Yön.mobil site_settings, Yön.mobil survey_management, Yön.mobil units, Yön.mobil violations |
| 4 | Düğme **Kodu ilettim, kapat (pencere/form açar)** (satır 122) | — | | | | |

### Anketler — `/dashboard/surveys`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/surveys/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — Anket yönetimi
- **Ekranda:**
  - Veri (satır 23): `GET /surveys` (survey)
  - Veri (satır 30): `GET /surveys/:id/comments` (survey)
  - Veri (satır 31): `GET /surveys/:id` (survey)
  - Bilgi notu (satır 38): Anket sonuçları genel kurul kararı yerine geçmez. Bağlayıcı kararlar Genel Kurul ekranında
  - Kart (satır 40): Anketler
  - Tablo (satır 43): Başlık \| Bitiş \| Katılım \| Durum
  - Pencere (satır 90): Anket sonucu
  - Bilgi notu (satır 95): {d.results_note}
  - Tablo (satır 96): Seçenek \| Oy \| Oran \| Arsa payı
  - Pencere (satır 116): Anket yorumları
  - Tablo (satır 120): Zaman \| Yazan \| Yorum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Anket oluştur (pencere/form açar)** (satır 37) | — | | | | |
| 2 | Düğme **Sonuç (pencere/form açar)** (satır 50) | — | | | | |
| 3 | Düğme **Yorumlar (pencere/form açar)** (satır 51) | — | | | | |
| 4 | Düğme **Yayımla** (satır 52) | `POST /surveys/:id/publish` · survey · `services/survey/main.go:195` | BOARD_MEMBER/MANAGER | surveys(±) | `survey.published` → Residents | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 5 | Düğme **Kapat (başarı: Anket kapatıldı)** (satır 53) | `POST /surveys/:id/close` · survey · `services/survey/main.go:209` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 6 | Düğme **İptal (pencere/form açar)** (satır 54) | — | | | | |
| 7 | Form **Anket oluştur — alanlar: Başlık*, Açıklama, Tür, Bitiş, Anonim, Arsa payı ağırlıklı, Yorum, Sonuç bitmeden görünsün — başarı: Anket taslak olarak oluşturuldu; yayımlayınca oylama başlar** (satır 62) | `POST /surveys` · survey · `services/survey/main.go:168` | BOARD_MEMBER/MANAGER | survey_options(+), surveys(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 8 | Düğme **Seçeneği çıkar (pencere/form açar)** (satır 83) | — | | | | |
| 9 | Düğme **+ Seçenek (pencere/form açar)** (satır 86) | — | | | | |
| 10 | Form **Anketi iptal et — alanlar: Gerekçe* — başarı: Anket iptal edildi** (satır 108) | `POST /surveys/:id/cancel` · survey · `services/survey/main.go:218` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |

### Bağımsız Bölümler — `/dashboard/units`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/units/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Bağımsız bölüm ve arsa payı kayıtları
- **Ekranda:**
  - Veri (satır 67): `GET /units` (identity)
  - Bilgi notu (satır 109): Maliki kayıtlı olmayan daireler: {d.data.filter((u) => u.owner_missing).map((u) => `$u.block + "-${u.door_number}`).join(",
  - Tablo (satır 114): Blok \| Kapı \| Kat \| Tür \| Arsa payı \| Net m² \| Brüt m² \| Oturum
  - Bilgi notu (satır 205): Düzeltilmesi gereken satırlar: {parsed.errors.slice(0, 10).joi}
  - Bilgi notu (satır 206): {parsed.units.length} bölüm eklenecek, toplam arsa payı {num(parsed.units.reduce((a, u)}.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Toplu ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 92) | — | | | | |
| 2 | Düğme **Bölüm ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 93) | — | | | | |
| 3 | Düğme **Düzenle (yalnız yazma yetkisi) — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 129) | — | | | | |
| 4 | Düğme **Borcu yoktur (yalnız yazma yetkisi)** (satır 130) | `POST /finance/clearance-certificates` · finance · `services/finance/main.go:104` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | clearance_certificates(+) | yok | Panel/units, Sakin dues_payment, Yön.mobil units |
|  | ↳ | `GET /finance/clearance-certificates/:id/pdf` · finance · `services/finance/main.go:105` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | — | yok | — |
| 5 | Form **(başlık dinamik) — alanlar: Blok, Kapı no*, Kat, Arsa payı*, Net kullanım alanı (m²)*, Brüt m², Tür, Ticari mi?, Kiracı yokken — başarı: Bölüm güncellendi; Bölüm eklendi** (satır 144) | `PATCH /units/:id` · identity · `services/identity/main.go:185` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(±) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
|  | ↳ | `POST /units` · identity · `services/identity/main.go:184` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(+) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |
| 6 | Form **Toplu bölüm ekle — alanlar:  — başarı: ** (satır 184) | `POST /units` · identity · `services/identity/main.go:184` | serviste rol karşılaştırması: BOARD_MEMBER/MANAGER | units(+) | yok | Panel/accounting, Panel/announcements, Panel/assessments, Panel/bulletins, Panel/collection, Panel/emergency, Panel/energy, Panel/esg, Panel/expenses, Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/governance/legal, Panel/insurance, Panel/meters, Panel/notifications, Panel/packages, Panel/parking, Panel/renovations, Panel/reports, Panel/reservations, Panel/residents, Panel/units, Panel/violations, Panel/visitors, Sakin bulletin_board_mobile, Sakin common_income, Sakin create_reservation, Sakin dask, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin more, Sakin my_budgets, Sakin my_meters, Sakin my_reservations, Sakin package_tracking_mobile, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin tenancy_requests, Sakin unit_residents, Sakin vehicles, Sakin violations, Sakin visitor_preregister, Yön.mobil account, Yön.mobil add_resident, Yön.mobil announcements, Yön.mobil bulletin_board, Yön.mobil collection_entry, Yön.mobil create_assessment, Yön.mobil dashboard, Yön.mobil emergency, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil expense_detail, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil forms, Yön.mobil governance, Yön.mobil insurance, Yön.mobil main, Yön.mobil meter_reading, Yön.mobil meters, Yön.mobil notification_center, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil payments, Yön.mobil renovations, Yön.mobil reports, Yön.mobil reservation_management, Yön.mobil resident_detail, Yön.mobil resident_tools, Yön.mobil residents, Yön.mobil smart_collection, Yön.mobil units, Yön.mobil violations, Yön.mobil visitor_management |

### Kural İhlalleri — `/dashboard/violations`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/violations/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Kural ihlalleri ve bildiren kimliği
- **Ekranda:**
  - Veri (satır 31): `GET /site-rules` (community)
  - Veri (satır 32): `GET /violations` (community)
  - Veri (satır 33): `GET /units` (identity)
  - Bilgi notu (satır 44): Site yönetimi para cezası veremez; idari yaptırım yetkisi kanunda gösterilen kamu merciler
  - Tablo (satır 48): Daire \| Kural \| Olay \| Bildiren \| Durum \| Kademe \| Son 24 ay
  - Kart (satır 62): Kural kataloğu
  - Tablo (satır 65): Kural \| Kategori \| Yönetim planı dayanağı \| Durum
  - Veri (satır 130): `GET /violations/:id` (community)
  - Pencere (satır 136): İhlal kaydı
  - Kart (satır 163): Olay geçmişi
  - Tablo (satır 164): Zaman \| Olay \| Kişi \| Açıklama
  - Bilgi notu (satır 182): Bildirim dairenin bütün aktif sakinlerine (malik ve kiracı) gider; kiracı malikle mütesels

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İhlal kaydet (yalnız yazma yetkisi; pencere/form açar)** (satır 42) | — | | | | |
| 2 | Düğme **Aç (pencere/form açar)** (satır 56) | — | | | | |
| 3 | Düğme **Kural ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 62) | — | | | | |
| 4 | Düğme **Pasifleştir (başarı: Kural pasifleştirildi)** (satır 72) | `POST /site-rules/:id/deactivate` · community · `services/community/violation.go:94` | BOARD_MEMBER/MANAGER | site_rules(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
| 5 | Form **Kural ekle — alanlar: Kural*, Kategori, Yönetim planı dayanağı*, Açıklama — başarı: Kural eklendi** (satır 81) | `POST /site-rules` · community · `services/community/violation.go:66` | BOARD_MEMBER/MANAGER | site_rules(+) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
| 6 | Form **İhlal kaydet — alanlar: Kural*, Daire*, Ne oldu?* — başarı: İhlal kaydedildi** (satır 101) | `POST /violations` · community · `services/community/violation.go:131` | işleyicide `isManagement` (backend/services/community/main.go:257) | rule_violation_events(+), rule_violations(+) | `violation.reported` → Approvers | Panel/violations, Sakin violations, Yön.mobil violations |
| 7 | Düğme **Doğrula (başarı: Doğrulandı)** (satır 150) | `POST /violations/:id/verify` · community · `services/community/violation.go:210` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
| 8 | Düğme **Doğrulanmadı (pencere/form açar)** (satır 151) | — | | | | |
| 9 | Düğme **{STAGE[s]} (pencere/form açar)** (satır 157) | — | | | | |
| 10 | Düğme **Kapat (pencere/form açar)** (satır 159) | — | | | | |
| 11 | Düğme **Doğrulanmadı (pencere/form açar)** (satır 160) | — | | | | |
| 12 | Form **(başlık dinamik) — alanlar: Açıklama* — başarı: Kaydedildi** (satır 173) | `POST /violations/:id/escalate` · community · `services/community/violation.go:240` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.{…}` → UnitResidents | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/resolve` · community · `services/community/violation.go:285` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | yok | Panel/violations, Sakin violations, Yön.mobil violations |
|  | ↳ | `POST /violations/:id/dismiss` · community · `services/community/violation.go:221` | BOARD_MEMBER/MANAGER | rule_violation_events(+), rule_violations(±) | `violation.dismissed` → işlemin muhatabı (v.ReportedBy) | Panel/violations, Sakin violations, Yön.mobil violations |


## Mali

### Tahsilat ve Borçlar — `/dashboard/accounting`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/accounting/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Mali kayıtlar
- **Ekranda:**
  - Veri (satır 23): `GET /finance/ledger` (finance)
  - Veri (satır 26): `GET /finance/payments/pending` (finance)
  - Veri (satır 28): `GET /finance/payments` (finance)
  - Veri (satır 29): `GET /finance/debtors` (finance)
  - Veri (satır 36): `GET /finance/payments/:id/receipts` (finance)
  - Bilgi notu (satır 66): Havale/EFT ödemesi, yönetici banka hareketini gördükten sonra onayladığında borçtan düşer;
  - Sekmeler (satır 70): Onay bekleyen, Tüm ödemeler, Borçlular, Tahsilat defteri, Alacak dekontları, Banka ekstresi
  - Tablo (satır 76): (sütunlar dinamik)
  - Tablo (satır 83): (sütunlar dinamik)
  - Tablo (satır 108): Sıra \| İşlem \| Tutar \| Açıklama \| Kaydeden / zaman \| Özet
  - Tablo (satır 123): Kişi \| Daire \| Sorumlu \| Borç
  - Bilgi notu (satır 182): Ödeme SİLİNMEZ: durumu &quot;ters kayıt&quot; olur, borç yeniden açılır ve işlem gerekçesi
  - **Bileşen `admin/src/components/finance/credit-notes-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 14): `GET /finance/credit-notes` (finance)
  - Veri (satır 15): `GET /units` (identity)
  - Veri (satır 19): `GET /finance/units/:id/open-assessments` (finance)
  - Kart (satır 26): Alacak dekontları
  - Tablo (satır 30): No \| Daire / dönem \| Tutar \| Gerekçe \| Düzenleyen \| Durum
  - Bilgi notu (satır 57): Dekont borcu düşürür, tahsilat sayılmaz ve tahsilat defterine yazılır. Silinemez; hata anc
  - **Bileşen `admin/src/components/finance/bank-statement-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 26): `GET /finance/bank-statements` (finance)
  - Veri (satır 28): `GET /finance/bank-statements/:id` (finance)
  - Veri (satır 29): `GET /finance/payments/pending` (finance)
  - Kart (satır 41): Ekstre yükle
  - Dosya seçme (satır 44)
  - Kart (satır 55): Yüklenen ekstreler
  - Tablo (satır 58): Dosya \| Yükleme \| Hareket \| Durum
  - Kart (satır 69): Hareketler
  - Tablo (satır 72): Satır \| Tarih \| Tutar \| Açıklama \| Durum \| Ödeyen
  - Bilgi notu (satır 102): Hareket: {date(pick.line.date)} · {kurus(pick.line.amount_kurus)} · {pick.line.description
  - **Bileşen `admin/src/components/finance/collection-modal.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 21): `GET /units` (identity)
  - Veri (satır 23): `GET /finance/units/:id/open-assessments` (finance)
  - Bilgi notu (satır 44): Hareket: {date(line.date)} · {kurus(line.amount_kurus)} · {line.description}. Seçtiğiniz b
  - Bilgi notu (satır 45): Sakinin bildirim yapmadığı havale/EFT ya da elden ödeme içindir. Kayıt silinemez; hata anc

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **{p.receipt_count} dosya (pencere/form açar)** (satır 45) | — | | | | |
| 2 | Düğme **Ters kayıt (yalnız yazma yetkisi; pencere/form açar)** (satır 51) | — | | | | |
| 3 | Düğme **Onayla (yalnız yazma yetkisi; pencere/form açar)** (satır 52) | — | | | | |
| 4 | Düğme **Reddet (başarı: Ödeme reddedildi; borç değişmedi)** (satır 53) | `POST /finance/payments/:id/reject` · finance · `services/finance/main.go:140` | BOARD_MEMBER/MANAGER | payments(±) · tetikleyici: payments_guard | yok | Panel/accounting, Sakin dues_payment, Sakin payment_history, Yön.mobil dashboard, Yön.mobil finance_tools, Yön.mobil payments |
| 5 | Düğme **Tahsilat gir (yalnız yazma yetkisi; pencere/form açar)** (satır 65) | — | | | | |
| 6 | Düğme **Daha eskileri göster (pencere/form açar)** (satır 88) | — | | | | |
| 7 | Düğme **Zinciri doğrula** (satır 102) | `GET /finance/ledger/verify` · finance · `services/finance/main.go:100` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 8 | Düğme **İndir** (satır 146) | `GET /finance/payments/:id/receipts/:receiptId/download` · finance · `services/finance/main.go:99` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41) | — · dosya deposu | yok | — |
| 9 | Form **Ödemeyi onayla — alanlar: Dekont / işlem numarası — başarı: ${tl(confirming.amount)} tahsilat onaylandı** (satır 154) | `POST /finance/payments/:id/confirm` · finance · `services/finance/main.go:138` | BOARD_MEMBER/MANAGER | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 10 | Form **Ödemenin ters kaydı — alanlar: Gerekçe* — başarı: ** (satır 175) | `POST /finance/payments/:id/reverse` · finance · `services/finance/main.go:139` | BOARD_MEMBER/MANAGER | finance_ledger(+), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 11 | Düğme **Dekont kes (yalnız yazma yetkisi; pencere/form açar)** (credit-notes-card satır 27) | — | | | | |
| 12 | Düğme **PDF** (credit-notes-card satır 39) | `GET /finance/credit-notes/:id/pdf` · finance · `services/finance/main.go:109` | işleyicide `isFinanceManager` (backend/services/finance/clearance.go:41); işleyicide `residentScope` (backend/services/finance/adjustments.go:94); `assessment_visible_to` | — | yok | — |
| 13 | Düğme **Ters kayıt (pencere/form açar)** (credit-notes-card satır 40) | — | | | | |
| 14 | Form **Alacak dekontu kes — alanlar: Daire*, Tahakkuk*, Tutar (TL)*, Gerekçe* — başarı: ** (credit-notes-card satır 48) | `POST /finance/credit-notes` · finance · `services/finance/main.go:148` | BOARD_MEMBER/MANAGER | credit_notes(+), finance_ledger(+), monthly_assessments(±) · tetikleyici: credit_notes_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 15 | Form **(başlık dinamik) — alanlar: Gerekçe* — başarı: Dekontun ters kaydı yapıldı; borç geri yüklendi** (credit-notes-card satır 79) | `POST /finance/credit-notes/:id/reverse` · finance · `services/finance/main.go:149` | BOARD_MEMBER/MANAGER | finance_ledger(+), credit_notes(±), monthly_assessments(±) · tetikleyici: credit_notes_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 16 | Düğme **Yükle (başarı: Ekstre yüklendi)** (bank-statement-card satır 45) | `POST /finance/bank-statements` · finance · `services/finance/main.go:150` | BOARD_MEMBER/MANAGER | bank_statement_imports(+), bank_statement_lines(+) | yok | Panel/accounting, Yön.mobil finance_tools |
| 17 | Düğme **Aç (pencere/form açar)** (bank-statement-card satır 63) | — | | | | |
| 18 | Düğme **Onayla (yalnız yazma yetkisi; başarı: Ödeme onaylandı ve borçtan düşüldü)** (bank-statement-card satır 82) | `POST /finance/bank-statements/lines/:id/confirm` · finance · `services/finance/main.go:151` | BOARD_MEMBER/MANAGER | finance_ledger(+), bank_statement_lines(±), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 19 | Düğme **Ödeme seç (pencere/form açar)** (bank-statement-card satır 83) | — | | | | |
| 20 | Düğme **Daireye işle (pencere/form açar)** (bank-statement-card satır 84) | — | | | | |
| 21 | Düğme **Yok say (pencere/form açar)** (bank-statement-card satır 85) | — | | | | |
| 22 | Form **Ödeme bildirimiyle eşleştir — alanlar: Onay bekleyen ödeme* — başarı: Ödeme onaylandı ve borçtan düşüldü** (bank-statement-card satır 94) | `POST /finance/bank-statements/lines/:id/confirm` · finance · `services/finance/main.go:151` | BOARD_MEMBER/MANAGER | finance_ledger(+), bank_statement_lines(±), monthly_assessments(±), payments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link, payments_guard | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 23 | Form **Hareketi yok say — alanlar: Gerekçe* — başarı: Satır yok sayıldı** (bank-statement-card satır 113) | `POST /finance/bank-statements/lines/:id/ignore` · finance · `services/finance/main.go:152` | BOARD_MEMBER/MANAGER | bank_statement_lines(±) | yok | Panel/accounting, Yön.mobil finance_tools |
| 24 | Form **(başlık dinamik) — alanlar: Daire*, Ödeme yöntemi*, Ödeme günü*, Açıklama / makbuz no — başarı: ** (collection-modal satır 31) | `POST /finance/bank-statements/lines/:id/collect` · finance · `services/finance/main.go:156` | BOARD_MEMBER/MANAGER; `assessment_visible_to` | finance_ledger(+), late_fee_accruals(+), payment_assessments(+), payments(+), bank_statement_lines(±), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `payment.recorded` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
|  | ↳ | `POST /finance/collections` · finance · `services/finance/main.go:155` | BOARD_MEMBER/MANAGER; `assessment_visible_to` | finance_ledger(+), late_fee_accruals(+), payment_assessments(+), payments(+), bank_statement_lines(±), late_fee_accruals(±), monthly_assessments(±), payments(±) · tetikleyici: late_fee_accruals_active_property, payment_assessments_guard, payments_guard, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `payment.recorded` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin payment_history, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil dashboard, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |

### Aidat Tahakkuku — `/dashboard/assessments`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/assessments/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Tahakkuk kayıtları
- **Ekranda:**
  - Veri (satır 20): `GET /finance/assessments/overview` (finance)
  - Veri (satır 21): `GET /finance/expense-categories` (finance)
  - Kart (satır 48): Dönemler
  - Tablo (satır 51): Dönem \| Vade \| Tahakkuk \| Tahsil edilen \| Oran \| Durum
  - Kart (satır 70): Gecikme tazminatı (KMK m.20/2)
  - Bilgi notu (satır 135): Her kalemde sınıf seçin: kullanım giderini daireyi kullanan (kiracı ya da oturan malik), m
  - **Bileşen `admin/src/components/finance/opening-balances.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 17): `GET /finance/opening-balances` (finance)
  - Veri (satır 18): `GET /units` (identity)
  - Kart (satır 40): Devir bakiyeleri
  - Tablo (satır 48): Daire \| Tutar \| Ödenen \| Vade \| Açıklama \| Sınıf
  - Bilgi notu (satır 87): Devir tutarına önceki yönetimin işlettiği gecikme tazminatı dahil edilmelidir; sistem devr
  - Bilgi notu (satır 98): Düzeltilmesi gereken satırlar: {errors.slice(0, 10).join(" · "}
  - Bilgi notu (satır 99): {items.length} daire, toplam {tl(items.reduce((a, x) => a + }.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tahakkuk oluştur (yalnız yazma yetkisi; pencere/form açar)** (satır 44) | — | | | | |
| 2 | Düğme **Tazminatı işlet** (satır 76) | `POST /finance/late-fees/accrue` · finance · `services/finance/main.go:143` | BOARD_MEMBER/MANAGER | late_fee_accruals(+), late_fee_accruals(±), monthly_assessments(±) · tetikleyici: late_fee_accruals_active_property, monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 3 | Form **Tahakkuk oluştur — alanlar: Yıl*, Ay*, Son ödeme* — başarı: ** (satır 91) | `POST /finance/assessments` · finance · `services/finance/main.go:135` | BOARD_MEMBER/MANAGER | assessment_details(+), monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 4 | Düğme **Kalemi çıkar (pencere/form açar)** (satır 130) | — | | | | |
| 5 | Düğme **+ Kalem (pencere/form açar)** (satır 133) | — | | | | |
| 6 | Düğme **Devir gir (yalnız yazma yetkisi; pencere/form açar)** (opening-balances satır 42) | — | | | | |
| 7 | Düğme **İptal (başarı: Devir kaydı iptal edildi)** (opening-balances satır 61) | `POST /finance/opening-balances/:id/cancel` · finance · `services/finance/main.go:146` | BOARD_MEMBER/MANAGER | monthly_assessments(±) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | yok | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 8 | Form **Devir bakiyesi gir — alanlar: Vade tarihi*, Gider sınıfı* — başarı: ** (opening-balances satır 72) | `POST /finance/opening-balances` · finance · `services/finance/main.go:145` | BOARD_MEMBER/MANAGER | monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |

### Tahsilat Riski — `/dashboard/collection`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/collection/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Tahsilat riski (kişisel mali veri)
- **Ekranda:**
  - Veri (satır 21): `GET /collection/risk` (smart_collection)
  - Tablo (satır 40): Daire \| Puan \| Risk \| Borç \| Ödenmemiş \| En uzun gecikme \| Öneri \| Etkenler
  - Bilgi notu (satır 51): {d.method}
  - Bilgi notu (satır 52): {d.action_note}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Bugünü kaydet (yalnız yazma yetkisi)** (satır 28) | `POST /collection/risk/snapshot` · smart_collection · `services/smart_collection/main.go:120` | BOARD_MEMBER/MANAGER | payment_risk_scores(−), payment_risk_scores(+) | yok |  |

### Giderler — `/dashboard/expenses`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/expenses/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Gider kayıtları
- **Ekranda:**
  - Veri (satır 16): `GET /expenses` (expense)
  - Veri (satır 17): `GET /expenses/summary` (expense)
  - Veri (satır 18): `GET /expense-categories` (expense)
  - Veri (satır 23): `GET /expenses/:id` (expense)
  - Kart (satır 44): Gider kayıtları
  - Tablo (satır 52): Tarih \| Açıklama \| Tutar \| Sınıf \| Fatura \| Durum
  - Pencere (satır 118): Dağıtım
  - Tablo (satır 124): Daire \| Pay \| Ödendi
  - Bilgi notu (satır 130): Dağıtım, gider onaylandığında oluşturulur.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gider ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 34) | — | | | | |
| 2 | Düğme **Dağıtım (pencere/form açar)** (satır 61) | — | | | | |
| 3 | Düğme **Onayla (başarı: Gider onaylandı)** (satır 64) | `POST /expenses/:id/approve` · expense · `services/expense/main.go:72` | BOARD_MEMBER/MANAGER | expenses(±) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |
| 4 | Düğme **Reddet (pencere/form açar)** (satır 65) | — | | | | |
| 5 | Form **Gider ekle — alanlar: Gider kalemi*, Tutar (TL)*, Gider tarihi*, Gider sınıfı*, Dağıtım, Tedarikçi, Fatura, Fatura no, Faturasız gider gerekçesi*, Açıklama* — başarı: Gider kaydedildi** (satır 75) | `POST /expenses` · expense · `services/expense/main.go:71` | BOARD_MEMBER/MANAGER | expense_distributions(+), expenses(+) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |
| 6 | Form **Gideri reddet — alanlar: Gerekçe* — başarı: Gider reddedildi** (satır 109) | `POST /expenses/:id/reject` · expense · `services/expense/main.go:73` | BOARD_MEMBER/MANAGER | expenses(±) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |

### Sayaç ve Isı Payı — `/dashboard/meters`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/meters/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Sayaç okuma
- **Ekranda:**
  - Veri (satır 23): `GET /meters` (iot)
  - Veri (satır 24): `GET /units` (identity)
  - Veri (satır 25): `GET /meter-readings` (iot)
  - Veri (satır 26): `GET /consumption/statements` (iot)
  - Veri (satır 27): `GET /consumption/objections` (iot)
  - Veri (satır 36): `GET /consumption/area-check` (iot)
  - Sekmeler (satır 48): Sayaçlar, Okumalar, Gider paylaştırma, Tüketim pusulaları, Pusula itirazları
  - Kart (satır 51): Sayaçlar
  - Tablo (satır 54): Daire \| Tür \| Seri no \| Son okuma \| Durum
  - Kart (satır 77): Son okumalar
  - Tablo (satır 80): Tarih \| Daire \| Seri no \| Önceki \| Güncel \| Tüketim \| Tür \| Okuyan
  - Kart (satır 96): Dönem giderini paylaştır
  - Bilgi notu (satır 101): ${areaCheck.data.missing.length} bölümün net kullanım alanı eksik: {areaCheck.data.missing.slice(0} …. {areaCheck.data.note}{" "} Bağımsız Bölümler ekranında
  - Bağlantı (satır 103): Bağımsız Bölümler ekranında tamamlayın. → /dashboard/units
  - Bilgi notu (satır 134): {allocResult.warning}
  - Bilgi notu (satır 136): Olağandışı tüketim — site medyanının 3 katından fazla: {allocResult.outliers.map((o) => `${o.unit_name}: ${num(o.intensity)}$/m² (medyan ${num(o.
  - Bilgi notu (satır 140): {allocResult.basis_note} {allocResult.note}
  - Tablo (satır 142): Daire \| İlk okuma \| Son okuma \| Tüketim \| Alan (m²) \| Pay
  - Kart (satır 156): Yayımlanmış tüketim pusulaları
  - Tablo (satır 159): Tür \| Dönem \| Toplam gider \| Paylaşım \| Yayım
  - Kart (satır 173): Tüketim pusulasına itirazlar
  - Tablo (satır 176): Daire / pusula \| İtiraz eden \| Gerekçe \| Durum
  - Bilgi notu (satır 197): Gerekçe: {answer.o.reason}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Sayaç ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 45) | — | | | | |
| 2 | Düğme **Okuma gir (yalnız yazma yetkisi; pencere/form açar)** (satır 62) | — | | | | |
| 3 | Düğme **Sayaç değiştir (yalnız yazma yetkisi; pencere/form açar)** (satır 63) | — | | | | |
| 4 | Düğme **Pasife al (yalnız yazma yetkisi; başarı: Sayaç pasife alındı; okuma geçmişi korunur; onay sorar)** (satır 64) | `DELETE /meters/:id` · iot · `services/iot/main.go:212` | BOARD_MEMBER/MANAGER | meters(±) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin energy_consumption_mobile, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |
| 5 | Düğme **Hesapla ve yayımla** (satır 123) | `POST /consumption/allocate` · iot · `services/iot/main.go:239` | BOARD_MEMBER/MANAGER | consumption_allocation_units(+), consumption_allocations(+) | yok | Panel/meters, Sakin energy_consumption_mobile, Yön.mobil meters |
| 6 | Düğme **PDF** (satır 165) | `GET /consumption/statements/:id/pdf` · iot · `services/iot/main.go:469` | `resident_can_use` | — | yok | — |
| 7 | Düğme **Yanıtla (yalnız yazma yetkisi; pencere/form açar)** (satır 182) | — | | | | |
| 8 | Form **(başlık dinamik) — alanlar: Karar*, Açıklama* — başarı: ** (satır 189) | `POST /consumption/objections/:id/respond` · iot · `services/iot/main.go:473` | BOARD_MEMBER/MANAGER | consumption_statement_objections(±) · tetikleyici: consumption_statement_objections_guard | `statement.objection.answer` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/meters, Sakin energy_consumption_mobile, Yön.mobil meters |
| 9 | Form **Sayaç ekle — alanlar: Daire*, Tür*, Seri no*, Marka — başarı: Sayaç kaydedildi** (satır 209) | `POST /meters` · iot · `services/iot/main.go:188` | BOARD_MEMBER/MANAGER | meters(+) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin energy_consumption_mobile, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |
| 10 | Form **(başlık dinamik) — alanlar: Endeks*, Okuma tarihi, Okuma türü — başarı: ** (satır 228) | `POST /meter-readings` · iot · `services/iot/main.go:161` | BOARD_MEMBER/MANAGER/STAFF | meter_readings(+) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |
| 11 | Form **(başlık dinamik) — alanlar: Eski sayacın söküm endeksi*, Değişim tarihi*, Yeni sayacın seri no*, Yeni sayacın montaj endeksi*, Gerekçe* — başarı: Sayaç değiştirildi** (satır 258) | `POST /meters/:id/replace` · iot · `services/iot/main.go:142` | BOARD_MEMBER/MANAGER/STAFF | meter_readings(+), meter_replacements(+), meters(+), meters(±) | yok | Panel/energy, Panel/esg, Panel/meters, Sakin energy_consumption_mobile, Sakin my_meters, Yön.mobil energy_dashboard, Yön.mobil esg, Yön.mobil meter_reading, Yön.mobil meters |


## Yönetişim (KMK)

### Sözleşmeler — `/dashboard/contracts`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/contracts/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Sözleşmeler
- **Ekranda:**
  - Veri (satır 20): `GET /contracts` (contract)
  - Veri (satır 21): `GET /contracts-summary` (contract)
  - Kart (satır 55): Sözleşmeler
  - Tablo (satır 58): Sözleşme \| Dönem \| Kalan \| Yenileme \| Tutar \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Süresi dolanları işle (yalnız yazma yetkisi)** (satır 43) | `POST /contracts/expire-due` · contract · `services/contract/main.go:172` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 2 | Düğme **Sözleşme ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 44) | — | | | | |
| 3 | Düğme **Yenile (yalnız yazma yetkisi; başarı: Sözleşme yenilendi)** (satır 67) | `POST /contracts/:id/renew` · contract · `services/contract/main.go:138` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |
| 4 | Düğme **Feshet (pencere/form açar)** (satır 68) | — | | | | |
| 5 | Form **Sözleşme ekle — alanlar: Tür*, Başlık*, Karşı taraf*, Başlangıç*, Bitiş, İhbar süresi (gün), Otomatik yenileme, Yenileme süresi (ay), Ödeme, Aylık tutar (TL), Yıllık tutar (TL), Telefon, Not — başarı: Sözleşme kaydedildi** (satır 76) | `POST /contracts` · contract · `services/contract/main.go:117` | BOARD_MEMBER/MANAGER | contracts(+) | yok | Panel/contracts, Yön.mobil contract_management |
| 6 | Form **Sözleşmeyi feshet — alanlar: Gerekçe* — başarı: Fesih kaydedildi** (satır 101) | `POST /contracts/:id/terminate` · contract · `services/contract/main.go:151` | BOARD_MEMBER/MANAGER | contracts(±) | yok | Panel/contracts, Yön.mobil contract_management |

### Belge Arşivi — `/dashboard/documents`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/documents/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Belge arşivi
- **Ekranda:**
  - Veri (satır 31): `GET /documents` (document)
  - Veri (satır 32): `GET /documents-summary` (document)
  - Veri (satır 41): `GET /documents/:id/access-log` (document)
  - Kart (satır 54): Belgeler
  - Tablo (satır 62): Belge \| Kategori \| Görünürlük \| Yükleme
  - Dosya seçme (satır 89)
  - Pencere (satır 106): Erişim kaydı — ${logFor?.title ?? ""}
  - Tablo (satır 109): Zaman \| Kişi \| İşlem \| IP

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Belge yükle (yalnız yazma yetkisi; pencere/form açar)** (satır 45) | — | | | | |
| 2 | Düğme **? (indirir)** (satır 69) | `GET /documents/:id/download` · document · `services/document/main.go:135` | işleyicide `hasRole` (backend/services/settings/visibility.go:74); işleyicide `isManagement` (backend/services/community/main.go:257) | document_access_logs(+) · tetikleyici: document_access_logs_no_update · dosya deposu | yok | — |
| 3 | Düğme **Erişim (pencere/form açar)** (satır 70) | — | | | | |
| 4 | Düğme **Arşivle (pencere/form açar)** (satır 71) | — | | | | |
| 5 | Form **Belge yükle — alanlar: Dosya*, Kategori*, Görünürlük, Başlık, Saklama bitişi, Açıklama [dosya] — başarı: ** (satır 79) | `POST /documents` · document · `services/document/main.go:171` | BOARD_MEMBER/MANAGER | documents(+) · tetikleyici: documents_supersede · dosya deposu | yok | Panel/documents, Sakin documents, Yön.mobil documents |
| 6 | Form **Belgeyi arşivle — alanlar: Gerekçe* — başarı: Arşivlendi (silinmedi)** (satır 98) | `POST /documents/:id/archive` · document · `services/document/main.go:266` | BOARD_MEMBER/MANAGER | documents(±) · tetikleyici: documents_supersede | yok | Panel/documents, Sakin documents, Yön.mobil documents |

### Genel Kurul — `/dashboard/governance/assemblies`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/assemblies/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Ekranda:**
  - Veri (satır 32): `GET /governance/assemblies` (governance)
  - Tablo (satır 47): Tarih \| Tür \| Yer \| Çağrı \| Durum \| Nisap
  - Veri (satır 97): `GET /governance/assemblies/:id` (governance)
  - Veri (satır 98): `GET /governance/assemblies/:id/attendees` (governance)
  - Veri (satır 99): `GET /governance/assemblies/:id/quorum` (governance)
  - Veri (satır 100): `GET /units` (identity)
  - Veri (satır 101): `GET /residents` (identity)
  - Pencere (satır 112): Genel kurul
  - Bilgi notu (satır 127): Nisap: ${quorum.data.met ? "sağlanıyor" : "sağlanmıyor"}: Katılım {quorum.data.attended_units}/{quorum.data.total_units} daire, arsa payı {num(quoru
  - Sekmeler (satır 148): Gündem ve kararlar
  - Tablo (satır 150): # \| Madde \| Nisap \| Oylar (lehte/aleyhte/çekimser) \| Karar
  - Tablo (satır 189): Daire \| Katılan \| Katılım \| Arsa payı
  - Pencere (satır 214): Karar
  - Bilgi notu (satır 217): {result.explanation}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Toplantı planla (yalnız yazma yetkisi; pencere/form açar)** (satır 41) | — | | | | |
| 2 | Düğme **Aç (pencere/form açar)** (satır 54) | — | | | | |
| 3 | Form **Toplantı planla — alanlar: Tür, Toplantı, Tarih ve saat*, Yer — başarı: Toplantı planlandı** (satır 60) | `POST /governance/assemblies` · governance · `services/governance/main.go:95` | BOARD_MEMBER/MANAGER | assemblies(+), assembly_agenda_items(+) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/reports, Yön.mobil governance |
| 4 | Düğme **Maddeyi çıkar (pencere/form açar)** (satır 84) | — | | | | |
| 5 | Düğme **+ Madde (pencere/form açar)** (satır 87) | — | | | | |
| 6 | Düğme **Çağrıyı kaydet (başarı: Çağrı kaydedildi)** (satır 137) | `POST /governance/assemblies/:id/notify` · governance · `services/governance/main.go:96` | BOARD_MEMBER/MANAGER | assemblies(±) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/reports, Yön.mobil governance |
| 7 | Düğme **Toplantıyı yap (nisap fotoğrafı)** (satır 141) | `POST /governance/assemblies/:id/hold` · governance · `services/governance/main.go:98` | BOARD_MEMBER/MANAGER | assemblies(±) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Panel/reports, Yön.mobil governance |
| 8 | Düğme **Oy gir (pencere/form açar)** (satır 158) | — | | | | |
| 9 | Düğme **Kararı hesapla** (satır 159) | `POST /governance/agenda-items/:itemId/close` · governance · `services/governance/main.go:100` | BOARD_MEMBER/MANAGER | book_entries(+), books(+), assembly_agenda_items(±) · tetikleyici: book_entries_no_update | yok | Panel/governance/assemblies, Panel/governance/books, Panel/governance/budgets, Panel/governance/common-area, Yön.mobil governance |
| 10 | Düğme **Ekle (başarı: Hazirune eklendi)** (satır 182) | `POST /governance/assemblies/:id/attendees` · governance · `services/governance/main.go:97` | BOARD_MEMBER/MANAGER | assembly_attendees(+) | yok | Panel/governance/assemblies, Panel/reports, Yön.mobil governance |
| 11 | Form **(başlık dinamik) — alanlar: Daire (hazirundan)*, Oy — başarı: Oy kaydedildi** (satır 199) | `POST /governance/agenda-items/:itemId/votes` · governance · `services/governance/main.go:99` | BOARD_MEMBER/MANAGER | assembly_votes(+), assembly_agenda_items(±) | yok | Panel/governance/assemblies, Panel/governance/budgets, Panel/governance/common-area, Yön.mobil governance |

### Defterler — `/dashboard/governance/books`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/books/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Ekranda:**
  - Veri (satır 24): `GET /governance/books/:id/entries` (governance)
  - Kart (satır 51): ${book.kind === "DECISION" ? "Karar defteri" : "İşletme defteri"} ${book.period_year}
  - Bilgi notu (satır 68): {integrity.message}
  - Tablo (satır 71): No \| Tarih \| Kayıt \| Hash \| Oluşturma
  - Bilgi notu (satır 89): Kayıt eklendikten sonra DEĞİŞTİRİLEMEZ ve SİLİNEMEZ. Düzeltme gerekirse yeni bir kayıtla y

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Aç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 46) | — | | | | |
| 2 | Düğme **Bütünlüğü doğrula** (satır 55) | `GET /governance/books/:id/verify` · governance · `services/governance/main.go:71` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 3 | Düğme **PDF** (satır 59) | `GET /governance/books/:id/export` · governance · `services/governance/main.go:73` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 4 | Düğme **Kayıt ekle (pencere/form açar)** (satır 62) | — | | | | |
| 5 | Düğme **Notere kapat (pencere/form açar)** (satır 63) | — | | | | |
| 6 | Form **Deftere kayıt ekle — alanlar: Başlık*, Metin*, Tarih — başarı: ** (satır 83) | `POST /governance/books/:id/entries` · governance · `services/governance/main.go:103` | BOARD_MEMBER/MANAGER | book_entries(+) · tetikleyici: book_entries_no_update | yok | Panel/governance/books, Yön.mobil governance |
| 7 | Form **Defteri notere kapat — alanlar: Noter kapanış no, Kapanış tarihi — başarı: ** (satır 95) | `POST /governance/books/:id/close` · governance · `services/governance/main.go:104` | BOARD_MEMBER/MANAGER | books(±) | yok | Panel/governance/books, Yön.mobil governance |

### İşletme Projesi — `/dashboard/governance/budgets`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/budgets/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Ekranda:**
  - Veri (satır 26): `GET /governance/budgets` (governance)
  - Tablo (satır 43): Yıl \| Toplam \| Durum \| Bildirim \| Genel kurul son gün \| Kesinleşme
  - Bilgi notu (satır 88): Kapıcı, kaloriferci, bahçıvan ve bekçi giderleri eşit; sigorta ve ortak yer bakım/onarım g
  - Veri (satır 97): `GET /governance/budgets/:id` (governance)
  - Veri (satır 98): `GET /governance/budgets/:id/objections` (governance)
  - Veri (satır 105): `GET /governance/assemblies` (governance)
  - Veri (satır 106): `GET /governance/assemblies/:id` (governance)
  - Pencere (satır 113): İşletme projesi
  - Sekmeler (satır 170): Kalemler, Daire payları, İtirazlar
  - Tablo (satır 172): Kalem \| Tutar \| Dağıtım \| Tür \| Sınıf
  - Tablo (satır 181): Daire \| Yıllık \| Aylık \| Döküm
  - Tablo (satır 191): Tarih \| Gerekçe \| Süre \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Proje hazırla (yalnız yazma yetkisi; pencere/form açar)** (satır 37) | — | | | | |
| 2 | Düğme **Aç (pencere/form açar)** (satır 50) | — | | | | |
| 3 | Form **İşletme projesi hazırla — alanlar: Dönem yılı*, Not — başarı: ** (satır 56) | `POST /governance/budgets` · governance · `services/governance/main.go:89` | BOARD_MEMBER/MANAGER | operating_budget_items(+), operating_budget_unit_shares(+), operating_budgets(+) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 4 | Düğme **Kalemi çıkar (pencere/form açar)** (satır 83) | — | | | | |
| 5 | Düğme **+ Kalem (pencere/form açar)** (satır 86) | — | | | | |
| 6 | Düğme **PDF** (satır 126) | `GET /governance/budgets/:id/export` · governance · `services/governance/main.go:75` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 7 | Düğme **Excel** (satır 127) | `GET /governance/budgets/:id/export` · governance · `services/governance/main.go:75` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok | — |
| 8 | Düğme **Geçici proje olarak bildir** (satır 133) | `POST /governance/budgets/:id/notify` · governance · `services/governance/main.go:90` | BOARD_MEMBER/MANAGER | operating_budgets(±) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 9 | Düğme **Genel kurul kararıyla kesinleştir (başarı: Proje genel kurul kararına bağlandı ve kesinleşti)** (satır 153) | `POST /governance/budgets/:id/finalize` · governance · `services/governance/main.go:91` | BOARD_MEMBER/MANAGER | operating_budgets(±) | yok | Panel/governance/budgets, Panel/reports, Sakin my_budgets, Yön.mobil governance |
| 10 | Düğme **Projeden aylık aidat tahakkuk et** (satır 164) | `POST /governance/budgets/:id/assessments` · governance · `services/governance/main.go:92` | BOARD_MEMBER/MANAGER | monthly_assessments(+) · tetikleyici: monthly_assessments_active_property, monthly_assessments_active_property_increase, monthly_assessments_guard, trg_monthly_assessments_tenant_link | `dues.created` → AssessmentPayers | Panel/accounting, Panel/assessments, Panel/collection, Panel/reports, Sakin dues_payment, Sakin finance, Sakin resident_home, Sakin unit_residents, Yön.mobil collection_entry, Yön.mobil finance, Yön.mobil finance_tools, Yön.mobil payments, Yön.mobil reports, Yön.mobil smart_collection |
| 11 | Düğme **Kabul (yalnız yazma yetkisi; pencere/form açar)** (satır 198) | — | | | | |
| 12 | Düğme **Ret (yalnız yazma yetkisi; pencere/form açar)** (satır 199) | — | | | | |
| 13 | Form **(başlık dinamik) — alanlar: Karar açıklaması — başarı: İtiraz sonuçlandırıldı** (satır 206) | `PATCH /governance/budgets/:id/objections/:objectionId` · governance · `services/governance/main.go:93` | BOARD_MEMBER/MANAGER | budget_objections(±) | yok | Panel/governance/budgets, Sakin my_budgets, Yön.mobil governance |

### Ortak Alan Geliri — `/dashboard/governance/common-area`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/common-area/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Ekranda:**
  - Veri (satır 21): `GET /governance/common-area/leases` (governance)
  - Veri (satır 23): `GET /governance/common-area/report` (governance)
  - Veri (satır 24): `GET /governance/assemblies` (governance)
  - Veri (satır 28): `GET /governance/assemblies/:id` (governance)
  - Bilgi notu (satır 37): Ortak yerin kiraya verilmesi bütün kat maliklerinin oybirliğini ister (KMK m.45). Sığınak 
  - Kart (satır 38): Kiralamalar
  - Tablo (satır 41): Alan \| Kiracı \| Başlangıç \| Aylık kira \| Karar \| Toplam gelir \| Durum
  - Kart (satır 62): Kat maliki payları
  - Tablo (satır 66): Daire \| Malik(ler) \| Brüt pay \| Stopaj \| Net

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kiralama kaydet (yalnız yazma yetkisi; pencere/form açar)** (satır 35) | — | | | | |
| 2 | Düğme **Tahsilat gir (pencere/form açar)** (satır 52) | — | | | | |
| 3 | Düğme **Sonlandır (başarı: Kiralama sona erdirildi)** (satır 53) | `POST /governance/common-area/leases/:id/end` · governance · `services/governance/main.go:109` | BOARD_MEMBER/MANAGER | common_area_leases(±) | yok | Panel/governance/common-area, Sakin common_income, Yön.mobil governance |
| 4 | Form **Ortak yer kiralaması — alanlar: Alan türü, Alan adı*, Kiracı*, Aylık kira (TL)*, Başlangıç*, Kiracı işyeri mi?, Genel kurul, Oybirliğiyle kabul edilen madde* — başarı: Kiralama kaydedildi** (satır 79) | `POST /governance/common-area/leases` · governance · `services/governance/main.go:108` | BOARD_MEMBER/MANAGER | common_area_leases(+) | yok | Panel/governance/common-area, Sakin common_income, Yön.mobil governance |
| 5 | Form **Kira tahsilatı — ${income?.lease.area_name ?? ""} — alanlar: Dönem*, Tahsilat tarihi*, Brüt kira (TL)*, Kiracının kestiği stopaj (TL) — başarı: ** (satır 105) | `POST /governance/common-area/leases/:id/incomes` · governance · `services/governance/main.go:110` | BOARD_MEMBER/MANAGER | common_area_income_shares(+), common_area_incomes(+) | yok | Panel/governance/common-area, Sakin common_income, Yön.mobil governance |

### İcra ve Dava — `/dashboard/governance/legal`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/legal/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Ekranda:**
  - Veri (satır 28): `GET /governance/legal-cases` (governance)
  - Veri (satır 29): `GET /units` (identity)
  - Tablo (satır 48): Tür \| Daire \| Anapara \| Gecikme tazminatı \| Dayanak \| Daire / mahkeme \| Durum \| Açılış
  - Bilgi notu (satır 82): Anapara ve gecikme tazminatı, dairenin ödenmemiş tahakkuklarından otomatik hesaplanır.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Takip aç (yalnız yazma yetkisi; pencere/form açar)** (satır 42) | — | | | | |
| 2 | Form **Hukuki takip aç — alanlar: Daire*, Tür, Dayanak belge, İcra dairesi / mahkeme, Dosya no, Avukat, Not — başarı: ** (satır 62) | `POST /governance/legal-cases` · governance · `services/governance/main.go:106` | BOARD_MEMBER/MANAGER | legal_cases(+) | yok | Panel/governance/legal, Yön.mobil governance |

### Usta & Hizmet — `/dashboard/usta-hizmet`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/usta-hizmet/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Veri (satır 15): 
  - Veri (satır 16): `GET /market/meta` (marketplace)
  - Bilgi notu (satır 30): Site adına talebi yönetici açar ve teklif seçer; kurul üyeleri ve denetçi talepleri ve tek
  - Tablo (satır 34): Tarih \| Kategori \| Açıklama \| Kabul \| Durum
  - Bağlantı (satır 36): {r.category_name} → `/dashboard/usta-hizmet/${r.id

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Teklif topla (pencere/form açar)** (satır 28) | — | | | | |
| 2 | Form **Site adına teklif topla — alanlar: Kategori*, Ne yapılacak?*, Uygun zaman — başarı: ** (satır 45) | — | | | | |


## Operasyon

### Demirbaş — `/dashboard/assets`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/assets/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Demirbaş ve bakım
- **Ekranda:**
  - Veri (satır 24): `GET /assets` (asset)
  - Veri (satır 25): `GET /assets-summary` (asset)
  - Veri (satır 26): `GET /asset-categories` (asset)
  - Veri (satır 34): `GET /assets/:id` (asset)
  - Veri (satır 35): `GET /assets/:id/maintenance` (asset)
  - Kart (satır 58): Demirbaşlar
  - Tablo (satır 61): Demirbaş \| Alış \| Defter değeri \| Sonraki bakım \| Durum
  - Bilgi notu (satır 104): Amortisman hesaplanamadı (alış tarihi/bedeli yok).
  - Tablo (satır 119): Tarih \| Tür \| Açıklama \| Yapan \| Maliyet

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kategori (yalnız yazma yetkisi; pencere/form açar)** (satır 47) | — | | | | |
| 2 | Düğme **Demirbaş ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 48) | — | | | | |
| 3 | Düğme **Aç (pencere/form açar)** (satır 67) | — | | | | |
| 4 | Form **Demirbaş ekle — alanlar: Ad*, Kategori, Demirbaş kodu, Seri no, Konum, Durum, Alış tarihi, Alış bedeli (TL), Tedarikçi, Garanti bitişi, Amortisman (yıl), Bakım aralığı (gün) — başarı: Demirbaş kaydedildi** (satır 73) | `POST /assets` · asset · `services/asset/main.go:202` | BOARD_MEMBER/MANAGER | assets(+) | yok | Panel/assets, Yön.mobil asset_management |
| 5 | Düğme **Bakım kaydı (pencere/form açar)** (satır 108) | — | | | | |
| 6 | Düğme **{detail.assigned_to ? `Zimmet: ${detail.assigned_to}` : "Zimmetle"} (pencere/form açar)** (satır 111) | — | | | | |
| 7 | Düğme **Hurdaya ayır (pencere/form açar)** (satır 115) | — | | | | |
| 8 | Form **Bakım kaydı — alanlar: Tür, Tarih, İşçilik (TL), Parça (TL), Yapan, Yeni durum, Açıklama* — başarı: ** (satır 131) | `POST /assets/:id/maintenance` · asset · `services/asset/main.go:155` | BOARD_MEMBER/MANAGER/STAFF | asset_maintenance(+), assets(±) | yok | Panel/assets, Yön.mobil asset_management |
| 9 | Form **Hurdaya ayır — alanlar: Gerekçe*, Karar referansı* — başarı: Demirbaş hurdaya ayrıldı** (satır 151) | `POST /assets/:id/dispose` · asset · `services/asset/main.go:237` | BOARD_MEMBER/MANAGER | assets(±) | yok | Panel/assets, Yön.mobil asset_management |
| 10 | Form **Demirbaş kategorisi — alanlar: Ad*, Amortisman süresi (yıl), Açıklama — başarı: Kategori eklendi** (satır 160) | `POST /asset-categories` · asset · `services/asset/main.go:183` | BOARD_MEMBER/MANAGER | asset_categories(+) | yok | Panel/assets, Yön.mobil asset_management |
| 11 | Form **(başlık dinamik) — alanlar: Zimmetlenen kişi / birim — başarı: ** (satır 175) | `POST /assets/:id/assign` · asset · `services/asset/main.go:220` | BOARD_MEMBER/MANAGER | assets(±) | yok | Panel/assets, Yön.mobil asset_management |

### Stok — `/dashboard/inventory`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/inventory/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Stok
- **Ekranda:**
  - Veri (satır 26): `GET /inventory` (inventory)
  - Veri (satır 27): `GET /inventory-summary` (inventory)
  - Veri (satır 28): `GET /inventory-movements` (inventory)
  - Veri (satır 29): `GET /inventory-categories` (inventory)
  - Veri (satır 41): `GET /inventory/:id/movements` (inventory)
  - Sekmeler (satır 61): Kalemler, Hareketler
  - Kart (satır 63): Kalemler
  - Tablo (satır 71): Kalem \| Stok \| Asgari \| Birim maliyet \| Değer
  - Kart (satır 91): Son hareketler
  - Tablo (satır 94): Zaman \| Kalem \| Tür \| Miktar \| Stok \| Giren \| Not
  - Bilgi notu (satır 147): Sayım düzeltmesi stoğu tek kalemde değiştirir; gerekçesi denetim için saklanır.
  - Tablo (satır 169): Zaman \| Tür \| Miktar \| Stok \| Giren \| Not

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kategori (yalnız yazma yetkisi; pencere/form açar)** (satır 50) | — | | | | |
| 2 | Düğme **Kalem ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 51) | — | | | | |
| 3 | Düğme **Hareket (yalnız yazma yetkisi; pencere/form açar)** (satır 80) | — | | | | |
| 4 | Düğme **Geçmiş (yalnız yazma yetkisi; pencere/form açar)** (satır 81) | — | | | | |
| 5 | Düğme **Pasife al (yalnız yazma yetkisi; pencere/form açar)** (satır 82) | — | | | | |
| 6 | Form **Stok kalemi ekle — alanlar: Ad*, Birim*, Kategori, Stok kodu, Asgari stok, Konum — başarı: Kalem eklendi (açılış stoğu 0 — mevcut stoğu sayım düzeltmesiyle girin)** (satır 108) | `POST /inventory` · inventory · `services/inventory/main.go:197` | BOARD_MEMBER/MANAGER | inventory_items(+) | yok | Panel/inventory, Yön.mobil inventory_management |
| 7 | Form **(başlık dinamik) — alanlar: Tür, Birim fiyat (TL), Dayanak — başarı: ** (satır 125) | `POST /inventory/:id/movements` · inventory · `services/inventory/main.go:142` | BOARD_MEMBER/MANAGER/STAFF; işleyicide `isManagement` (backend/services/community/main.go:257) | inventory_movements(+), inventory_items(±) | `inventory.low_stock` → Managers | Panel/inventory, Yön.mobil inventory_management |
| 8 | Form **Stok kategorisi ekle — alanlar: Ad*, Açıklama — başarı: Kategori eklendi** (satır 149) | `POST /inventory-categories` · inventory · `services/inventory/main.go:179` | BOARD_MEMBER/MANAGER | inventory_categories(+) | yok | Panel/inventory, Yön.mobil inventory_management |
| 9 | Form **(başlık dinamik) — alanlar: Gerekçe* — başarı: Kalem pasife alındı; hareket geçmişi korunur** (satır 158) | `DELETE /inventory/:id` · inventory · `services/inventory/main.go:216` | BOARD_MEMBER/MANAGER | inventory_items(±) | yok | Panel/inventory, Yön.mobil inventory_management |

### Kargo — `/dashboard/packages`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/packages/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Kargo kabul ve teslim
- **Ekranda:**
  - Veri (satır 21): `GET /packages` (package)
  - Veri (satır 22): `GET /packages-summary` (package)
  - Veri (satır 23): `GET /units` (identity)
  - Kart (satır 46): Kargolar
  - Tablo (satır 54): Daire \| Alıcı \| Firma / takip \| Kabul \| Bekleme \| Durum
  - Dosya seçme (satır 119)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kargo kabul (pencere/form açar)** (satır 38) | — | | | | |
| 2 | Düğme **Hatırlat (başarı: Haber verildiği kaydedildi)** (satır 63) | `POST /packages/:id/notify` · package · `services/package/main.go:162` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 3 | Düğme **Teslim et (pencere/form açar)** (satır 66) | — | | | | |
| 4 | Düğme **İade (pencere/form açar)** (satır 67) | — | | | | |
| 5 | Düğme **İmza** (satır 72) | `GET /packages/:id/proof/:kind` · package · `services/package/main.go:185` | `resident_can_use` | — · dosya deposu | yok | — |
| 6 | Düğme **Fotoğraf** (satır 73) | `GET /packages/:id/proof/:kind` · package · `services/package/main.go:185` | `resident_can_use` | — · dosya deposu | yok | — |
| 7 | Form **Kargo kabul — alanlar: Daire*, Alıcı adı*, Kargo firması, Takip no, Tür, Konulduğu yer — başarı: ** (satır 81) | `POST /packages` · package · `services/package/main.go:133` | BOARD_MEMBER/MANAGER/STAFF | packages(+), packages(±) | `package.received` → UnitUsers | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 8 | Form **Teslim et — alanlar: Teslim alan kişi*, İmza, Paket fotoğrafı [dosya] — başarı: Teslim kaydedildi (imza/fotoğraf yok)** (satır 101) | `POST /packages/:id/deliver` · package · `services/package/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | packages(±) · dosya deposu | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
|  | ↳ | `POST /packages/:id/deliver` · package · `services/package/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | packages(±) · dosya deposu | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |
| 9 | Form **Kargo firmasına iade — alanlar: Gerekçe* — başarı: İade kaydedildi** (satır 122) | `POST /packages/:id/return` · package · `services/package/main.go:214` | BOARD_MEMBER/MANAGER/STAFF | packages(±) | yok | Panel/packages, Panel/settings, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil site_settings |

### Otopark — `/dashboard/parking`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/parking/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Otopark yönetimi
- **Ekranda:**
  - Veri (satır 26): `GET /parking-logs` (parking)
  - Veri (satır 27): `GET /vehicles` (parking)
  - Veri (satır 28): `GET /parking-zones` (parking)
  - Veri (satır 29): `GET /units` (identity)
  - Kart (satır 57): Plaka sorgula
  - Sekmeler (satır 74): İçeridekiler, Kayıtlı araçlar, Bölgeler, Cihazlar
  - Tablo (satır 80): Plaka \| Bölge \| Giriş \| Tür
  - Tablo (satır 98): Plaka \| Daire \| Sahip \| Araç \| Durum
  - Tablo (satır 115): Bölge \| Konum \| Doluluk \| Ücret
  - **Bileşen `admin/src/components/parking/devices-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 22): `GET /access-devices` (parking)
  - Veri (satır 23): `GET /access-devices/incidents` (parking)
  - Bilgi notu (satır 34): ${offline.length} cihaz çevrimdışı: {offline.map((d) => d.name).joi}. Geçişleri görevli elle kaydetmelidir; cihazı ve bağlantı
  - Kart (satır 38): Geçiş cihazları
  - Tablo (satır 42): Cihaz \| Durum \| Son sinyal \| Eşik \| Bildirdiği durum
  - Kart (satır 56): Çevrimdışı olayları
  - Tablo (satır 59): Cihaz \| Son sinyal \| Fark edildi \| Düzeldi
  - Bilgi notu (satır 92): {issued.note}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Araç kaydet (pencere/form açar)** (satır 44) | — | | | | |
| 2 | Düğme **Giriş kaydı (pencere/form açar)** (satır 47) | — | | | | |
| 3 | Düğme **Sorgula — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 65) | — | | | | |
| 4 | Düğme **Çıkış** (satır 86) | `POST /parking-logs/:id/exit` · parking · `services/parking/main.go:184` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(±) | yok | Panel/parking, Yön.mobil parking_management |
| 5 | Düğme **Pasife al (başarı: Araç pasife alındı)** (satır 105) | `DELETE /vehicles/:id` · parking · `services/parking/main.go:89` | `resident_can_use` | vehicles(±) | yok | Panel/parking, Yön.mobil parking_management |
| 6 | Form **Araç girişi — alanlar: Plaka*, Bölge, Kapı — başarı: ** (satır 126) | `POST /parking-logs/entry` · parking · `services/parking/main.go:145` | BOARD_MEMBER/MANAGER/STAFF | parking_logs(+) | yok | Panel/parking, Yön.mobil parking_management |
| 7 | Form **Araç kaydet — alanlar: Plaka*, Daire, Sahip türü, Sahip adı, Araç türü, Park yeri, Marka, Model / renk — başarı: Araç kaydedildi** (satır 144) | `POST /vehicles` · parking · `services/parking/main.go:71` | `resident_can_use` | vehicles(+) | yok | Panel/parking, Yön.mobil parking_management |
| 8 | Düğme **Cihaz ekle (yalnız yazma yetkisi; pencere/form açar)** (devices-card satır 39) | — | | | | |
| 9 | Düğme **Pasife al (yalnız yazma yetkisi; başarı: Cihaz pasife alındı)** (devices-card satır 49) | `DELETE /access-devices/:id` · parking · `services/parking/devices.go:101` | BOARD_MEMBER/MANAGER | access_devices(±), device_incidents(±) | yok | Panel/parking, Yön.mobil parking_management |
| 10 | Form **Geçiş cihazı ekle — alanlar: Ad*, Tür, Konum, Sinyal aralığı (sn) — başarı: Cihaz kaydedildi** (devices-card satır 69) | `POST /access-devices` · parking · `services/parking/devices.go:86` | BOARD_MEMBER/MANAGER | access_devices(+) | yok | Panel/parking, Yön.mobil parking_management |

### Devriye — `/dashboard/patrol`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/patrol/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Devriye
- **Ekranda:**
  - Veri (satır 22): `GET /patrols-summary` (patrol)
  - Veri (satır 23): `GET /patrols` (patrol)
  - Veri (satır 24): `GET /patrol-routes` (patrol)
  - Veri (satır 25): `GET /patrol-checkpoints` (patrol)
  - Bağlantı (satır 37): Raporlar ve harita → /dashboard/patrol/reports
  - Bilgi notu (satır 44): {summary.data.warning}
  - Sekmeler (satır 51): Turlar, Tur tanımları, Kontrol noktaları
  - Tablo (satır 58): Başlangıç \| Tur \| Görevli \| Nokta \| Süre \| Sorun \| Durum
  - Tablo (satır 74): Tur \| Noktalar \| Beklenen \| Durum
  - Tablo (satır 86): Nokta \| Konum \| GPS
  - Bilgi notu (satır 123): En doğru yöntem: yönetici uygulamasında Devriye → Nokta kurulumu → &quot;Konumu buradan al

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tüm QR&apos;ları yazdır — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 38) | — | | | | |
| 2 | Düğme **Kontrol noktası (pencere/form açar)** (satır 39) | — | | | | |
| 3 | Düğme **Tur tanımla (pencere/form açar)** (satır 40) | — | | | | |
| 4 | Düğme **Konum / yarıçap (yalnız yazma yetkisi; pencere/form açar)** (satır 94) | — | | | | |
| 5 | Düğme **QR yazdır — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 96) | — | | | | |
| 6 | Düğme **QR yenile (başarı: QR yenilendi; yenisini yazdırıp asın; onay sorar)** (satır 97) | `POST /patrol-checkpoints/:id/rotate-qr` · patrol · `services/patrol/gps.go:101` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 7 | Form **(başlık dinamik) — alanlar: Enlem, Boylam, Yarıçap (m)*, Konum denetimi, Muafiyet gerekçesi* — başarı: Nokta güncellendi** (satır 110) | `PATCH /patrol-checkpoints/:id` · patrol · `services/patrol/gps.go:99` | BOARD_MEMBER/MANAGER | patrol_checkpoints(±) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 8 | Form **Kontrol noktası — alanlar:  — başarı: Kontrol noktası eklendi** (satır 141) | `POST /patrol-checkpoints` · patrol · `services/patrol/main.go:207` | BOARD_MEMBER/MANAGER | patrol_checkpoints(+) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil checkpoint_setup, Yön.mobil patrol_report, Yön.mobil patrol_run |
| 9 | Form **Tur tanımla — alanlar: Ad*, Beklenen süre (dk), Tolerans (dk), Noktalar (sırasıyla) — başarı: Tur tanımlandı** (satır 157) | `POST /patrol-routes` · patrol · `services/patrol/main.go:236` | BOARD_MEMBER/MANAGER | patrol_routes(+) | yok | Panel/patrol, Panel/patrol/reports, Yön.mobil patrol_control, Yön.mobil patrol_report, Yön.mobil patrol_run |

### Personel — `/dashboard/personnel`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/personnel/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — Personel özlük ve maaş bilgileri
- **Ekranda:**
  - Veri (satır 33): `GET /employees` (personnel)
  - Veri (satır 34): `GET /employees/summary` (personnel)
  - Veri (satır 35): `GET /leaves` (personnel)
  - Sekmeler (satır 67): Personel, İzinler, Bordro
  - Kart (satır 69): Personel listesi
  - Tablo (satır 72): Ad Soyad \| TCKN \| İşe giriş \| Brüt maaş \| İzin (kalan) \| Durum
  - Kart (satır 97): İzin talepleri
  - Tablo (satır 100): Personel \| Tür \| Tarih \| Gün \| Durum
  - Bilgi notu (satır 150): Kayıt silinmez; özlük dosyası yasal saklama süresince korunur.
  - Pencere (satır 183): Maskesiz bilgiler
  - Bilgi notu (satır 186): Bu görüntüleme denetim kaydına yazıldı (PII_REVEAL, KVKK m.12).
  - **Bileşen `admin/src/components/personnel/compliance-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 15): `GET /compliance-calendar` (personnel)
  - Kart (satır 20): Vergi ve SGK yükümlülükleri
  - Tablo (satır 25): Yükümlülük \| Son gün \| Durum \| Dayanak
  - **Bileşen `admin/src/components/personnel/payroll-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 23): `GET /payroll` (personnel)
  - Kart (satır 31): Bordro kayıtları
  - Bilgi notu (satır 45): Bu dönemde çalışıp bordrosu girilmemiş: {d.missing.join(", ")}
  - Tablo (satır 46): Personel \| Net \| İşveren maliyeti \| Kaynak \| Durum
  - Bilgi notu (satır 73): Tutarları mali müşavirin bordrosundan girin; sistem hesaplama ya da doğrulama yapmaz.
  - Bilgi notu (satır 108): Kayıt silinmez; gerekçesiyle iptal edilmiş olarak kalır.
  - Veri (satır 117): `GET /payroll/costs` (personnel)
  - Kart (satır 119): Yıllık personel maliyeti
  - Tablo (satır 126): Dönem \| Personel \| Net \| İşveren maliyeti

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **İzin gir (yalnız yazma yetkisi; pencere/form açar)** (satır 54) | — | | | | |
| 2 | Düğme **Personel ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 55) | — | | | | |
| 3 | Düğme **?** (satır 82) | `GET /employees/:id` · personnel · `services/personnel/main.go:73` | AUDITOR/BOARD_MEMBER/MANAGER/STAFF; işleyicide `isManager` (backend/services/personnel/handlers/personnel.go:49) | — | yok | — |
| 4 | Düğme **İlişik kes (pencere/form açar)** (satır 87) | — | | | | |
| 5 | Düğme **Onayla (yalnız yazma yetkisi; başarı: İzin onaylandı)** (satır 108) | `POST /leaves/:id/approve` · personnel · `services/personnel/main.go:84` | BOARD_MEMBER/MANAGER | employee_leaves(±), employees(±) | yok | Panel/personnel, Yön.mobil personnel_management |
| 6 | Düğme **Reddet (yalnız yazma yetkisi; pencere/form açar)** (satır 109) | — | | | | |
| 7 | Form **Personel ekle — alanlar: Ad*, Soyad*, Görev*, Bölüm, İşe giriş*, Sözleşme, TCKN, Telefon, E-posta, Brüt maaş (TL), Net maaş (TL), Yıllık izin (gün), Banka, IBAN, SGK no — başarı: Personel kaydedildi** (satır 118) | `POST /employees` · personnel · `services/personnel/main.go:81` | BOARD_MEMBER/MANAGER | employees(+) | yok | Panel/personnel, Yön.mobil personnel_management |
| 8 | Form **(başlık dinamik) — alanlar: Gerekçe*, Ayrılış tarihi — başarı: Ayrılış işlendi** (satır 144) | `POST /employees/:id/terminate` · personnel · `services/personnel/main.go:82` | BOARD_MEMBER/MANAGER | employees(±) | yok | Panel/personnel, Yön.mobil personnel_management |
| 9 | Form **İzin gir — alanlar: Personel*, Tür, Başlangıç*, Bitiş* — başarı: İzin talebi oluşturuldu (onay bekliyor)** (satır 155) | `POST /leaves` · personnel · `services/personnel/main.go:83` | BOARD_MEMBER/MANAGER | employee_leaves(+) | yok | Panel/personnel, Yön.mobil personnel_management |
| 10 | Form **İzni reddet — alanlar: Gerekçe* — başarı: İzin reddedildi** (satır 174) | `POST /leaves/:id/reject` · personnel · `services/personnel/main.go:85` | BOARD_MEMBER/MANAGER | employee_leaves(±), employees(±) | yok | Panel/personnel, Yön.mobil personnel_management |
| 11 | Düğme **Bildirge verildi (pencere/form açar)** (compliance-card satır 33) | — | | | | |
| 12 | Form **SGK bildirgesi verildi — alanlar: Bildirgenin verildiği tarih* — başarı: Bildirge tarihi kaydedildi** (compliance-card satır 40) | `POST /employees/:id/sgk` · personnel · `services/personnel/main.go:90` | BOARD_MEMBER/MANAGER | employees(±) | yok | Panel/personnel, Yön.mobil personnel_management |
| 13 | Düğme **Bordro gir (yalnız yazma yetkisi; pencere/form açar)** (payroll-card satır 34) | — | | | | |
| 14 | Düğme **Ödendi (yalnız yazma yetkisi; pencere/form açar)** (payroll-card satır 54) | — | | | | |
| 15 | Düğme **İptal (yalnız yazma yetkisi; pencere/form açar)** (payroll-card satır 55) | — | | | | |
| 16 | Form **Bordro gir — ${period} — alanlar: Personel*, Net ödenen (TL)*, İşveren maliyeti (TL)*, Ödeme tarihi, Bordronun kaynağı*, Ödeme referansı, Not — başarı: ** (payroll-card satır 64) | `POST /payroll` · personnel · `services/personnel/main.go:97` | BOARD_MEMBER/MANAGER | payroll(+) · tetikleyici: payroll_guard | yok | Panel/personnel, Yön.mobil personnel_management |
| 17 | Form **Ödeme — ${pay?.row.employee_name ?? ""} — alanlar: Ödeme tarihi*, Referans — başarı: Ödeme kaydedildi** (payroll-card satır 91) | `POST /payroll/:id/pay` · personnel · `services/personnel/main.go:98` | BOARD_MEMBER/MANAGER | payroll(±) · tetikleyici: payroll_guard | yok | Panel/personnel, Yön.mobil personnel_management |
| 18 | Form **Bordro kaydını iptal et — alanlar: Gerekçe* — başarı: Kayıt iptal edildi** (payroll-card satır 102) | `POST /payroll/:id/cancel` · personnel · `services/personnel/main.go:99` | BOARD_MEMBER/MANAGER | payroll(±) · tetikleyici: payroll_guard | yok | Panel/personnel, Yön.mobil personnel_management |

### Rezervasyon — `/dashboard/reservations`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/reservations/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Rezervasyon yönetimi
- **Ekranda:**
  - Veri (satır 16): `GET /reservations` (reservation)
  - Veri (satır 17): `GET /facilities` (reservation)
  - Sekmeler (satır 28): Rezervasyonlar, Tesisler
  - Kart (satır 30): Rezervasyonlar
  - Tablo (satır 38): Tesis \| Sakin \| Zaman \| Kişi \| Ücret \| Durum
  - Kart (satır 62): Tesisler
  - Tablo (satır 65): Tesis \| Saat \| Kapasite \| Ücret \| Onay \| İptal \| Durum
  - **Bileşen `admin/src/components/reservations/facility-form.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Bilgi notu (satır 66): Değişiklikler yalnızca bundan sonraki rezervasyonlara uygulanır.
  - Bilgi notu (satır 104): Ücret hesaplanır ancak tahsil edilmez; çevrimiçi tahsilat bağlı değilse sakin ödemeyi yöne

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onayla (yalnız yazma yetkisi; başarı: Rezervasyon onaylandı; sakine bildirim düştü)** (satır 49) | `POST /reservations/:id/approve` · reservation · `services/reservation/main.go:283` | BOARD_MEMBER/MANAGER | reservations(±) | `reservation.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
| 2 | Düğme **Reddet (pencere/form açar)** (satır 50) | — | | | | |
| 3 | Düğme **İptal (pencere/form açar)** (satır 53) | — | | | | |
| 4 | Düğme **+ Yeni tesis (yalnız yazma yetkisi; pencere/form açar)** (satır 62) | — | | | | |
| 5 | Düğme **Düzenle (yalnız yazma yetkisi; pencere/form açar)** (satır 73) | — | | | | |
| 6 | Form **Rezervasyonu reddet — alanlar: Gerekçe* — başarı: Reddedildi; sakine gerekçeyle bildirim düştü** (satır 81) | `POST /reservations/:id/reject` · reservation · `services/reservation/main.go:296` | BOARD_MEMBER/MANAGER | reservations(±) | `reservation.decision` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
| 7 | Form **Rezervasyonu iptal et — alanlar: Gerekçe — başarı: Rezervasyon iptal edildi** (satır 89) | `POST /reservations/:id/cancel` · reservation · `services/reservation/main.go:238` | işleyicide `canManage` (backend/services/reservation/main.go:441) | reservations(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
| 8 | Form **(başlık dinamik) — alanlar: Ad*, Kategori, Açılış*, Kapanış*, Bakım notu (sakinlere gösterilir)*, Açıklama, Kullanım kuralları — başarı: Tesis eklendi; sakinler rezervasyon yapabilir** (facility-form satır 58) | `PATCH /facilities/:id` · reservation · `services/reservation/main.go:281` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |
|  | ↳ | `POST /facilities` · reservation · `services/reservation/main.go:280` | BOARD_MEMBER/MANAGER | facilities(+), facilities(±) | yok | Panel/reservations, Sakin create_reservation, Sakin my_reservations, Yön.mobil reservation_management |

### Sensörler — `/dashboard/sensors`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/sensors/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Sensörler ve alarmlar
- **Ekranda:**
  - Veri (satır 32): `GET /sensors` (iot)
  - Veri (satır 33): `GET /iot/alerts` (iot)
  - Veri (satır 38): `GET /sensors/:id/data` (iot)
  - Kart (satır 46): Alarmlar
  - Sekmeler (satır 47): Açık, Kapatılmış
  - Tablo (satır 50): Açılış \| Sensör \| Olay \| Değer \| Durum \| Kapatma
  - Kart (satır 68): Sensörler
  - Tablo (satır 71): Ad \| Tür \| Konum \| Son değer \| Eşik \| Son sinyal \| Durum
  - Bilgi notu (satır 94): Cihaz okumayı POST /api/v1/public/sensors/data ucuna X-Device-Key başlığı ve {"{\"value\":
  - Pencere (satır 132): Cihaz anahtarı
  - Bilgi notu (satır 135): Bu anahtar bir daha gösterilmez. Şimdi cihaza girin.
  - Bilgi notu (satır 146): Liste 2000 okumayla sınırlandı.
  - Tablo (satır 147): Zaman \| Değer

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Sensör ekle (yalnız yazma yetkisi; pencere/form açar)** (satır 44) | — | | | | |
| 2 | Düğme **Onayla (başarı: Alarm onaylandı)** (satır 59) | `POST /iot/alerts/:id/acknowledge` · iot · `services/iot/sensors.go:263` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |
| 3 | Düğme **Kapat (pencere/form açar)** (satır 61) | — | | | | |
| 4 | Düğme **Geçmiş (pencere/form açar)** (satır 81) | — | | | | |
| 5 | Düğme **Düzenle (yalnız yazma yetkisi; pencere/form açar)** (satır 82) | — | | | | |
| 6 | Düğme **Anahtarı yenile (yalnız yazma yetkisi; başarı: Anahtar yenilendi; onay sorar)** (satır 83) | `POST /sensors/:id/rotate-key` · iot · `services/iot/sensors.go:360` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
| 7 | Form **(başlık dinamik) — alanlar: Ad*, Tür*, Konum, Birim, Alt eşik, Üst eşik, Sinyal kesilme süresi (dk)*, Durum — başarı: Sensör güncellendi; Sensör eklendi** (satır 99) | `PATCH /sensors/:id` · iot · `services/iot/sensors.go:332` | BOARD_MEMBER/MANAGER | sensors(±) | yok | Panel/sensors, Yön.mobil sensors |
|  | ↳ | `POST /sensors` · iot · `services/iot/sensors.go:303` | BOARD_MEMBER/MANAGER | sensors(+) | yok | Panel/sensors, Yön.mobil sensors |
| 8 | Form **Alarmı kapat — alanlar: Ne yapıldı?* — başarı: Alarm kapatıldı** (satır 156) | `POST /iot/alerts/:id/close` · iot · `services/iot/sensors.go:277` | BOARD_MEMBER/MANAGER/STAFF | sensor_alerts(±) | yok | Panel/sensors, Yön.mobil sensors |

### Ziyaretçi — `/dashboard/visitors`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/visitors/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/STAFF — Ziyaretçi kayıtları
- **Ekranda:**
  - Veri (satır 14): `GET /visitors` (visitor)
  - Veri (satır 15): `GET /visitors/summary` (visitor)
  - Veri (satır 16): `GET /units` (identity)
  - Kart (satır 35): Geçiş kodu ile giriş
  - Kart (satır 49): Ziyaretçiler
  - Tablo (satır 52): Ziyaretçi \| Daire \| Beklenen \| Giriş / Çıkış \| Durum
  - Pencere (satır 103): Geçiş kodu — ${pass?.name ?? ""}
  - Bilgi notu (satır 109): Kod yalnızca şimdi gösterilir; ziyaretçiye siz iletin. Sistem ziyaretçiye SMS göndermez.

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Ziyaretçi kaydı (pencere/form açar)** (satır 27) | — | | | | |
| 2 | Düğme **Doğrula ve giriş yap — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 45) | — | | | | |
| 3 | Düğme **Giriş** (satır 62) | `POST /visitors/:id/check-in` · visitor · `services/visitor/main.go:175` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | `visitor.checkin` → UnitUsers | Panel/visitors, Yön.mobil visitor_management |
| 4 | Düğme **İptal (başarı: Kayıt iptal edildi)** (satır 66) | `POST /visitors/:id/cancel` · visitor · `services/visitor/main.go:200` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 5 | Düğme **Kodu yenile (başarı: Yeni geçiş kodu üretildi; onay sorar)** (satır 67) | `POST /visitors/:id/pass` · visitor · `services/visitor/main.go:198` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239) | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 6 | Düğme **Çıkış (başarı: Çıkış kaydedildi)** (satır 75) | `POST /visitors/:id/check-out` · visitor · `services/visitor/main.go:187` | BOARD_MEMBER/MANAGER/STAFF | visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |
| 7 | Form **Ziyaretçi kaydı — alanlar: Ad soyad*, Telefon, Ziyaret edilen daire, Firma, Araç plakası, Beklenen zaman, Amaç — başarı: Ziyaretçi kaydedildi** (satır 84) | `POST /visitors` · visitor · `services/visitor/main.go:100` | işleyicide `hasAnyRole` (backend/services/visitor/main.go:239); `resident_can_use` | visitors(+), visitors(±) | yok | Panel/visitors, Yön.mobil visitor_management |


## Analiz

### Enerji — `/dashboard/energy`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/energy/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Enerji analizi
- **Ekranda:**
  - Veri (satır 17): `GET /energy/trends` (energy_analytics)
  - Veri (satır 18): `GET /energy/anomalies` (energy_analytics)
  - Kart (satır 28): Dönemsel tüketim
  - Tablo (satır 37): Dönem \| Toplam tüketim \| Okunan daire \| Okuma
  - Bilgi notu (satır 43): {d.note}
  - Kart (satır 48): Olağandışı tüketim
  - Tablo (satır 53): Daire \| Değer \| Medyan \| Sapma \| Önem \| Gerekçe
  - Bilgi notu (satır 62): {d.basis} {d.note}
- **Eylem:** yok (salt bilgi / yönlendirme)

### Karbon Ayak İzi — `/dashboard/esg`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/esg/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Karbon ayak izi
- **Ekranda:**
  - Veri (satır 21): `GET /esg/consumption` (esg)
  - Kart (satır 29): Tüketim
  - Tablo (satır 38): Tür \| Toplam tüketim \| Sayaç \| Okuma \| Katsayı (kgCO₂e / birim)
  - Bilgi notu (satır 58): {d.note}
  - Kart (satır 66): Toplam ${num(result.total_co2e_kg)} kg CO₂e
  - Tablo (satır 67): Tür \| Tüketim \| Katsayı \| kg CO₂e

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Hesapla** (satır 50) | `POST /esg/carbon-footprint` · esg · `services/esg/main.go:97` | AUDITOR/BOARD_MEMBER/MANAGER | — | yok |  |

### Memnuniyet (NPS) — `/dashboard/nps`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/nps/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Memnuniyet sonuçları
- **Ekranda:**
  - Veri (satır 13): `GET /nps` (nps)
  - Veri (satır 19): `GET /nps/:id` (nps)
  - Veri (satır 20): `GET /nps/:id/comments` (nps)
  - Tablo (satır 29): Başlık \| Başlangıç \| Bitiş \| Yanıt \| Durum
  - Pencere (satır 54): Ölçüm sonucu
  - Bilgi notu (satır 62): {d.result.interpretation}
  - Bilgi notu (satır 64): Henüz yanıt yok.
  - Tablo (satır 68): Puan \| Yorum \| Tarih

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Ölçüm başlat (yalnız yazma yetkisi; pencere/form açar)** (satır 24) | — | | | | |
| 2 | Düğme **Sonuç (pencere/form açar)** (satır 37) | — | | | | |
| 3 | Düğme **Kapat (başarı: Ölçüm kapatıldı)** (satır 38) | `POST /nps/:id/close` · nps · `services/nps/main.go:192` | BOARD_MEMBER/MANAGER | surveys(±) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |
| 4 | Form **Memnuniyet ölçümü başlat — alanlar: Başlık*, Açıklama, Bitiş — başarı: Ölçüm başladı** (satır 45) | `POST /nps` · nps · `services/nps/main.go:159` | BOARD_MEMBER/MANAGER | survey_options(+), surveys(+) | yok | Panel/nps, Panel/surveys, Sakin surveys_mobile, Yön.mobil nps, Yön.mobil survey_management |

### Raporlar — `/dashboard/reports`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/reports/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Mali raporlar
- **Ekranda:**
  - Veri (satır 38): `GET /governance/assemblies` (governance)
  - Veri (satır 39): `GET /governance/budgets` (governance)
  - Kart (satır 47): Borçlu listesi
  - Bilgi notu (satır 49): Yalnızca yönetimin iç kullanımı içindir; ortak alanlara asılamaz, site gruplarında paylaşı
  - Kart (satır 52): Tahakkuk ve tahsilat özeti
  - Kart (satır 57): Hazirun cetveli
  - Kart (satır 65): İşletme projesi
  - Bağlantı (satır 76): {l.title} {l.desc} → l.href

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **PDF — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 28) | — | | | | |
| 2 | Düğme **Excel — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 29) | — | | | | |


## Sistem

### İşlem Kayıtları — `/dashboard/audit`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/audit/page.tsx`
- **Panel erişimi:** MANAGER/AUDITOR — İşlem kayıtları (kişisel veri içerir; KMK m.41 denetçi)
- **Ekranda:**
  - Veri (satır 27): `GET /audit-logs` (settings)
  - Veri (satır 28): `GET /audit-logs/stats` (settings)
  - Bilgi notu (satır 33): Kayıt düzeyi: list.data.level . Düzey Ayarlar &apos;dan (yalnız site yöneticisi) değiştiri
  - Bağlantı (satır 34): Ayarlar → /dashboard/settings
  - Kart (satır 39): Son ${d.period_days} gün
  - Kart (satır 46): Süzgeç
  - Tablo (satır 68): Zaman \| Kullanıcı \| Kaynak \| İşlem \| Olay \| Modül \| Ekran / yol \| Kod
  - Pencere (satır 88): Kayıt ayrıntısı

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **CSV indir (başarı: Dışa aktarıldı)** (satır 31) | `GET /audit-logs/export` · settings · `services/settings/activity.go:175` | AUDITOR/MANAGER | — | yok | — |
| 2 | Düğme **Uygula — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 59) | — | | | | |
| 3 | Düğme **Temizle (pencere/form açar)** (satır 60) | — | | | | |
| 4 | Düğme **Ayrıntı (pencere/form açar)** (satır 77) | — | | | | |
| 5 | Düğme **Önceki (pencere/form açar)** (satır 80) | — | | | | |
| 6 | Düğme **Sonraki (pencere/form açar)** (satır 82) | — | | | | |

### Bildirimlerim — `/dashboard/inbox`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/inbox/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Veri (satır 20): `GET /notifications` (notification)
  - Sekmeler (satır 28): Okunmamış, Tümü
  - Tablo (satır 32): Zaman \| Konu \| İçerik \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tümünü okundu say (başarı: Tümü okundu sayıldı)** (satır 24) | `POST /notifications/read-all` · notification · `services/notification/main.go:97` | oturum açmış herkes (site kapsamı) | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |
| 2 | Düğme **Okundu say (başarı: Okundu sayıldı)** (satır 38) | `POST /notifications/:id/read` · notification · `services/notification/main.go:84` | oturum açmış herkes (site kapsamı) | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |

### Entegrasyon Durumu — `/dashboard/integrations`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/integrations/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — Dış sağlayıcıların bağlantı durumu
- **Ekranda:**
  - Veri (satır 14): `GET /integrations/status` (karşılığı yok)
  - Bilgi notu (satır 17): Sağlayıcı anahtarları sunucu ortam değişkenleriyle verilir (iyzico: IYZICO_* , SMS: NETGSM
  - Bilgi notu (satır 29): Bazı servislerden durum alınamadı: {d.unavailable.map((u) => `${u.source}: ${u.reason}`).join(" · ")}
  - Kart (satır 33): Bildirim kanalları
  - Tablo (satır 34): Kanal \| Durum
  - Bilgi notu (satır 39): {delivery.note}
  - Kart (satır 40): Kartla ödeme
  - Kart (satır 47): Dosya deposu
- **Eylem:** yok (salt bilgi / yönlendirme)


## Kenar çubuğu altı

### Ayarlar — `/dashboard/settings`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/settings/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER — Site ayarları
- **Ekranda:**
  - Veri (satır 22): 
  - Veri (satır 23): `GET /settings/definitions` (settings)
  - Veri (satır 24): `GET /settings-history` (settings)
  - Bilgi notu (satır 33): Mevzuata bağlı değerler (gecikme tazminatı, ısıtma payları, genel kurul nisapları) burada 
  - Sekmeler (satır 35): Ayarlar, Saklama ve imha (KVKK), Kamera ve biyometrik envanter, Değişiklik geçmişi, Site durumu, Malik görünürlüğü, Site konumu
  - Tablo (satır 45): Ayar \| Değer \| Son değişiklik
  - Tablo (satır 65): Zaman \| Ayar \| Eski \| Yeni \| Değiştiren
  - **Bileşen `admin/src/components/settings/retention-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 16): `GET /retention-rules` (settings)
  - Veri (satır 17): `GET /retention-rules/log` (settings)
  - Kart (satır 25): Kişisel veri saklama süreleri
  - Tablo (satır 30): Kategori \| Saklama \| Gerekçe \| Son imha
  - Kart (satır 42): İmha kaydı
  - Tablo (satır 45): Zaman \| Kategori \| Yöntem \| Kesim \| Kayıt \| Yapan
  - **Bileşen `admin/src/components/settings/privacy-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 21): `GET /privacy/cameras` (settings)
  - Veri (satır 22): `GET /privacy/biometrics` (settings)
  - Kart (satır 34): Kamera envanteri
  - Tablo (satır 38): Konum \| Amaç \| Saklama \| Uygunluk
  - Kart (satır 53): Biyometrik sistemler
  - Tablo (satır 56): Sistem \| Yöntem \| Amaç \| Alternatif
  - Bilgi notu (satır 78): Bağımsız bölüm içini/kapı önünü, tuvalet, soyunma ve ibadet yerlerini gören kamera konulam
  - Bilgi notu (satır 101): Biyometrik veri özel nitelikli kişisel veridir: kullanıcının açık rızası gerekir ve rıza v
  - **Bileşen `admin/src/components/settings/lifecycle-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 13): `GET /property` (identity)
  - Kart (satır 23): Site durumu
  - Bilgi notu (satır 31): Yönetim hizmeti sonlandırıldığında siteyi pasife alın
  - Tablo (satır 42): Tarih \| İşlem \| Gerekçe
  - **Bileşen `admin/src/components/settings/visibility-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 21): `GET /settings/owner-visibility` (settings)
  - Kart (satır 34): Malikin kiracılı dairede gördükleri
  - Bilgi notu (satır 49): Her zaman görür: {d.always_visible.join(" · ")}
  - Bilgi notu (satır 50): Hiçbir zaman görmez: {d.never_visible.join(" · ")}
  - Kart (satır 55): Onay bekleyen öneri
  - Kart (satır 75): Geçmiş
  - Tablo (satır 76): Öneri \| Açılan alanlar \| Gerekçe \| Durum \| Karar
  - Bilgi notu (satır 94): Seçenekleri açmak kiracının kişisel verisini malike gösterir (KVKK m.4 ölçülülük). Değişik
  - **Bileşen `admin/src/components/settings/location-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 17): `GET /property` (identity)
  - Kart (satır 36): Site konumu
  - Bilgi notu (satır 40): Usta & Hizmet'te sakinlerin talepleri, hizmet alanı bu konumu kapsayan tedarikçilere gider

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Düzenle (pencere/form açar)** (satır 52) | — | | | | |
| 2 | Düğme **Sıfırla (başarı: Varsayılana döndü)** (satır 53) | `DELETE /settings/:key` · settings · `services/settings/main.go:126` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | property_settings(−), property_setting_history(+) · tetikleyici: property_settings_guard_legal_key, property_setting_history_no_change | yok | Panel/personnel, Panel/settings, Sakin my_budgets, Yön.mobil personnel_management, Yön.mobil site_settings |
| 3 | Form **(başlık dinamik) — alanlar: Değer — başarı: Ayar kaydedildi** (satır 77) | `PUT /settings/:key` · settings · `services/settings/main.go:105` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | property_setting_history(+), property_settings(+) · tetikleyici: property_setting_history_no_change, property_settings_guard_legal_key | yok | Panel/personnel, Panel/settings, Sakin my_budgets, Yön.mobil personnel_management, Yön.mobil site_settings |
| 4 | Düğme **Şimdi imha et** (retention-card satır 26) | `POST /retention-rules/run` · settings · `services/settings/main.go:152` | BOARD_MEMBER/MANAGER | client_error_reports(−), data_destruction_log(+), storage_deletion_queue(+), mp_messages(±), mp_request_contacts(±), packages(±), parking_logs(±), visitors(±) | yok | Panel tedarikci/(panel)/talepler/[id], Panel/packages, Panel/parking, Panel/settings, Panel/visitors, Sakin market_requests, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil site_settings, Yön.mobil visitor_management |
| 5 | Düğme **Düzenle (pencere/form açar)** (retention-card satır 35) | — | | | | |
| 6 | Form **Saklama süresi — ${edit?.rule.title ?? ""} — alanlar: Saklama süresi (ay)*, Gerekçe (işleme amacı / hukuki dayanak)* — başarı: Kaydedildi** (retention-card satır 56) | `PUT /retention-rules/:category` · settings · `services/settings/main.go:143` | BOARD_MEMBER/MANAGER | client_error_reports(−), data_retention_rules(+), storage_deletion_queue(+), mp_messages(±), mp_request_contacts(±), packages(±), parking_logs(±), visitors(±) | yok | Panel tedarikci/(panel)/talepler/[id], Panel/packages, Panel/parking, Panel/settings, Panel/visitors, Sakin market_requests, Sakin package_tracking_mobile, Yön.mobil package_tracking, Yön.mobil parking_management, Yön.mobil site_settings, Yön.mobil visitor_management |
| 7 | Düğme **Kamera ekle (pencere/form açar)** (privacy-card satır 34) | — | | | | |
| 8 | Düğme **Düzenle (pencere/form açar)** (privacy-card satır 42) | — | | | | |
| 9 | Düğme **Sistem ekle (pencere/form açar)** (privacy-card satır 53) | — | | | | |
| 10 | Form **(başlık dinamik) — alanlar: Konum*, Alan türü, Saklama (gün)*, Genel kurul kararı, Amaç*, Kayıtlara kimler erişir, Somut gerekçe* — başarı: Kamera kaydı güncellendi** (privacy-card satır 65) | `PUT /privacy/cameras/:id` · settings · `services/settings/main.go:150` | BOARD_MEMBER/MANAGER | camera_devices(±) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
|  | ↳ | `POST /privacy/cameras` · settings · `services/settings/main.go:149` | BOARD_MEMBER/MANAGER | camera_devices(+) | yok | Panel/settings, Sakin kvkk_requests, Yön.mobil site_settings |
| 11 | Form **Biyometrik sistem — alanlar: Sistem adı*, Yöntem, Amaç*, Alternatif yöntem*, Saklama notu — başarı: Kaydedildi** (privacy-card satır 94) | `POST /privacy/biometrics` · settings · `services/settings/main.go:151` | BOARD_MEMBER/MANAGER | biometric_systems(+) | yok | Panel/settings, Yön.mobil site_settings |
| 12 | Düğme **Siteyi pasife al (pencere/form açar)** (lifecycle-card satır 37) | — | | | | |
| 13 | Form **(başlık dinamik) — alanlar: Gerekçe* — başarı: ** (lifecycle-card satır 52) | `POST /property/deactivate` · identity · `services/identity/main.go:164` | MANAGER | property_lifecycle_events(+), properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin market_requests, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin usta, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |
|  | ↳ | `POST /property/reactivate` · identity · `services/identity/main.go:165` | MANAGER | property_lifecycle_events(+), properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin market_requests, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin usta, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |
| 14 | Düğme **Değişiklik öner (pencere/form açar)** (visibility-card satır 35) | — | | | | |
| 15 | Düğme **Onayla (pencere/form açar)** (visibility-card satır 61) | — | | | | |
| 16 | Düğme **Reddet (pencere/form açar)** (visibility-card satır 62) | — | | | | |
| 17 | Düğme **Geri çek** (visibility-card satır 66) | `POST /settings/owner-visibility/:id/cancel` · settings · `services/settings/main.go:148` | BOARD_MEMBER/MANAGER | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | yok | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
|  | ↳ | `GET /settings` · settings · `services/settings/main.go:71` | oturum açmış herkes (site kapsamı) | — | yok | — |
| 18 | Form **Görünürlük değişikliği öner — alanlar: Gerekçe* — başarı: ** (visibility-card satır 86) | `POST /settings/owner-visibility` · settings · `services/settings/main.go:145` | BOARD_MEMBER/MANAGER | owner_visibility_policies(+) · tetikleyici: trg_owner_visibility_guard | yok | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
| 19 | Form **(başlık dinamik) — alanlar: Not — başarı: ** (visibility-card satır 108) | `POST /settings/owner-visibility/:id/approve` · settings · `services/settings/main.go:146` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | `visibility.policy` → Tenants | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
|  | ↳ | `POST /settings/owner-visibility/:id/reject` · settings · `services/settings/main.go:147` | BOARD_MEMBER/MANAGER; işleyicide `hasRole` (backend/services/settings/visibility.go:74) | owner_visibility_policies(±) · tetikleyici: trg_owner_visibility_guard | `visibility.policy` → Tenants | Panel/settings, Sakin owner_visibility, Yön.mobil site_settings |
| 20 | Düğme **Konumu kaydet (başarı: Site konumu kaydedildi)** (location-card satır 54) | `PUT /property/location` · identity · `services/identity/main.go:167` | MANAGER | properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin market_requests, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin usta, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |
| 21 | Düğme **Konumu sil (başarı: Site konumu silindi)** (location-card satır 59) | `PUT /property/location` · identity · `services/identity/main.go:167` | MANAGER | properties(±) | yok | Panel/accounting, Panel/governance/books, Panel/governance/budgets, Panel/meters, Panel/reports, Panel/settings, Panel/units, Sakin dues_payment, Sakin emergency, Sakin energy_consumption_mobile, Sakin invitations_banner, Sakin market_requests, Sakin more, Sakin profile_settings, Sakin renovations, Sakin resident_home, Sakin usta, Sakin vehicles, Sakin visitor_preregister, Yön.mobil account, Yön.mobil finance_tools, Yön.mobil governance, Yön.mobil main, Yön.mobil meters, Yön.mobil reports, Yön.mobil site_settings, Yön.mobil units |


## Menü dışı

### / — `/`
- **Dosya:** `admin/src/app/page.tsx`
- **Panel erişimi:** herkese açık / oturum gerekmez (rbac kapsamı dışı)
- **Eylem:** yok (salt bilgi / yönlendirme)

### /activate — `/activate`
- **Dosya:** `admin/src/app/activate/page.tsx`
- **Panel erişimi:** herkese açık / oturum gerekmez (rbac kapsamı dışı)
- **Ekranda:**
  - Bağlantı (satır 61): Giriş yap → /login
  - Bağlantı (satır 115): Girişe dön → /login
- **Eylem:** yok (salt bilgi / yönlendirme)

### /dashboard/account — `/dashboard/account`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/account/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Kart (satır 23): Şifre değiştir
  - Bilgi notu (satır 36): {act.error}
  - Bilgi notu (satır 37): {act.message} Giriş ekranına yönlendiriliyorsunuz…
  - Bilgi notu (satır 48): Şifre değişince bu cihaz dahil bütün cihazlardaki oturumlarınız kapatılır.
  - Kart (satır 68): Telefon numarası
  - Bilgi notu (satır 79): {act.error}
  - Bilgi notu (satır 80): {act.message}
  - Bilgi notu (satır 96): Onaylayınca numaranız değişir, bütün cihazlardaki oturumlarınız kapanır ve eski numaranıza
  - Kart (satır 113): E-posta adresi
  - Bilgi notu (satır 124): {act.error}
  - Bilgi notu (satır 125): {act.message}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Değiştiriliyor… — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 49) | — | | | | |
| 2 | Düğme **Yeni numaraya kod gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 89) | — | | | | |
| 3 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 97) | — | | | | |
| 4 | Düğme **Yeni adrese kod gönder — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 134) | — | | | | |
| 5 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 141) | — | | | | |

### /dashboard/forbidden — `/dashboard/forbidden`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/forbidden/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Bağlantı (satır 79): Panele dön → homeFor(myRoles)
- **Eylem:** yok (salt bilgi / yönlendirme)

### /dashboard/governance — `/dashboard/governance`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/governance/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR — Yönetişim kayıtları (işletme projesi, genel kurul, defterler)
- **Eylem:** yok (salt bilgi / yönlendirme)

### /dashboard/patrol/reports — `/dashboard/patrol/reports`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/patrol/reports/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Devriye
- **Ekranda:**
  - Veri (satır 24): `GET /patrol-reports` (patrol)
  - Veri (satır 25): `GET /patrols/:id/report` (patrol)
  - Bağlantı (satır 29): Devriye → /dashboard/patrol
  - Kart (satır 30): Dönem
  - Kart (satır 46): En çok reddedilen okutmalar
  - Tablo (satır 55): Başlangıç \| Tur \| Görevli \| Nokta \| Süre \| Kanıt \| Durum
  - Pencere (satır 75): Tur raporu
  - Bilgi notu (satır 90): Takip kesintileri: {r.gaps.map((g) => `${dateTime(g.from)}–${dateTime(g.to)} (${g.minutes}
  - Tablo (satır 91): Zaman \| Nokta \| Yöntem \| Sonuç \| Uzaklık / doğruluk
  - Kart (satır 100): Bildirilen sorunlar

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Uygula — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 34) | — | | | | |
| 2 | Düğme **Ayrıntı (pencere/form açar)** (satır 70) | — | | | | |

### /dashboard/usta-hizmet/[id] — `/dashboard/usta-hizmet/[id]`
- **Dosya:** `admin/src/app/(dashboard)/dashboard/usta-hizmet/[id]/page.tsx`
- **Panel erişimi:** MANAGER/BOARD_MEMBER/AUDITOR/STAFF — Yönetim paneli
- **Ekranda:**
  - Veri (satır 20): 
  - Veri (satır 21): 
  - Veri (satır 22): 
  - Bağlantı (satır 32): ← Usta & Hizmet → /dashboard/usta-hizmet
  - Kart (satır 34): Talep
  - Kart (satır 41): Teklif karşılaştırma
  - Tablo (satır 44): İşletme \| Tutar \| Kapsam \| Geçerlilik \| Puan \| Tamamlanan iş \| Telefon
  - Veri (satır 86): `GET /expense-categories` (expense)
  - Kart (satır 95): İş
  - Bağlantı (satır 103): Sözleşme formunu doldur → contractHref
  - Bilgi notu (satır 117): İtiraz: {job.dispute_note}
  - Bilgi notu (satır 139): Faturasız gider onay bekler; kurul onayından sonra hesap verme belgelerine girer. Fatura g

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Seç (pencere/form açar)** (satır 53) | — | | | | |
| 2 | Düğme **Teklif seçmeden kapat (başarı: Talep kapatıldı; onay sorar)** (satır 61) | — | | | | |
| 3 | Form **Teklifi seç — alanlar:  — başarı: Teklif seçildi; işletmeye bildirildi** (satır 68) | — | | | | |
| 4 | Düğme **Onay bekleyen gider oluştur (pencere/form açar)** (satır 102) | — | | | | |
| 5 | Düğme **Sözleşme formunu doldur — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 103) | — | | | | |
| 6 | Düğme **İş tamamlandı, onayla (başarı: İş onaylandı; onay sorar)** (satır 108) | — | | | | |
| 7 | Düğme **İtiraz et (başarı: İtiraz iletildi)** (satır 110) | — | | | | |
| 8 | Düğme **Puanı gönder (başarı: Puan verildi)** (satır 122) | — | | | | |
| 9 | Form **Onay bekleyen gider — alanlar: Gider kalemi*, Gider tarihi* — başarı: ** (satır 128) | `POST /expenses` · expense · `services/expense/main.go:71` | BOARD_MEMBER/MANAGER | expense_distributions(+), expenses(+) · tetikleyici: expense_updated_at | yok | Panel/expenses, Yön.mobil expense_detail, Yön.mobil expenses, Yön.mobil resident_expenses |

### /dogrula/[code] — `/dogrula/[code]`
- **Dosya:** `admin/src/app/dogrula/[code]/page.tsx`
- **Panel erişimi:** herkese açık / oturum gerekmez (rbac kapsamı dışı)
- **Eylem:** yok (salt bilgi / yönlendirme)

### /login — `/login`
- **Dosya:** `admin/src/app/login/page.tsx`
- **Panel erişimi:** herkese açık / oturum gerekmez (rbac kapsamı dışı)
- **Ekranda:**
  - Bağlantı (satır 15): Etkinleştirme kodum var → /activate
  - Bağlantı (satır 21): Usta &amp; Hizmet&apos;e kaydolun → /tedarikci/kayit
  - **Bileşen `admin/src/components/auth/login-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Bağlantı (satır 122): Şifremi unuttum / hesabımı etkinleştir → /activate
- **Eylem:** yok (salt bilgi / yönlendirme)

### /odeme-sonuc — `/odeme-sonuc`
- **Dosya:** `admin/src/app/odeme-sonuc/page.tsx`
- **Panel erişimi:** herkese açık / oturum gerekmez (rbac kapsamı dışı)
- **Eylem:** yok (salt bilgi / yönlendirme)

### /platform — `/platform`
- **Dosya:** `admin/src/app/platform/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 10): 
  - Veri (satır 11): 
  - Kart (satır 19): Kuyruklar
  - Bağlantı (satır 21): Tedarikçi hesapları ve belgeler → /platform/hesaplar
  - Bağlantı (satır 22): İşletme yayın onayı → /platform/isletmeler
- **Eylem:** yok (salt bilgi / yönlendirme)

### /platform/ayarlar — `/platform/ayarlar`
- **Dosya:** `admin/src/app/platform/ayarlar/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 11): `GET /market/meta` (marketplace)
  - Tablo (satır 20): Ayar \| Değer

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Düzenle (pencere/form açar)** (satır 23) | — | | | | |
| 2 | Form **(başlık dinamik) — alanlar: Değer (tam sayı) — başarı: Ayar kaydedildi** (satır 29) | — | | | | |

### /platform/gelir — `/platform/gelir`
- **Dosya:** `admin/src/app/platform/gelir/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 15): 
  - Kart (satır 31): Bakiye hareketleri (gelir değil)
  - Bilgi notu (satır 39): Net gelir = aidat + talep ücreti − iade. Defterdeki dönem toplamı: {kurus(r.ledger_total_k
- **Eylem:** yok (salt bilgi / yönlendirme)

### /platform/hesaplar — `/platform/hesaplar`
- **Dosya:** `admin/src/app/platform/hesaplar/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 16): 
  - Sekmeler (satır 19): 
  - Tablo (satır 23): Unvan \| Sahibi \| Vergi no \| Belge / işletme \| Durum \| Son değişiklik
  - Bağlantı (satır 24): {a.trade_name \|\| "(unvan girilm} → `/platform/hesaplar/${a.id
- **Eylem:** yok (salt bilgi / yönlendirme)

### /platform/hesaplar/[id] — `/platform/hesaplar/[id]`
- **Dosya:** `admin/src/app/platform/hesaplar/[id]/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 18): 
  - Kart (satır 30): Hesap
  - Bilgi notu (satır 38): Son gerekçe: {a.status_reason}
  - Kart (satır 49): Belgeler
  - Tablo (satır 50): Tür \| Dosya \| Durum \| Yüklendi
  - Kart (satır 58): İşletmeler
  - Tablo (satır 59): İşletme \| Yer \| Durum
  - Bilgi notu (satır 77): Kalan bakiye {kurus(a.balance_kurus)}. Önce tedarikçiye havaleyle iade edin; dekont numara
  - **Bileşen `admin/src/components/market/field-group.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onayla — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 41) | — | | | | |
| 2 | Düğme **Reddet (pencere/form açar)** (satır 42) | — | | | | |
| 3 | Düğme **Askıya al (pencere/form açar)** (satır 44) | — | | | | |
| 4 | Düğme **Yeniden etkinleştir — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 45) | — | | | | |
| 5 | Düğme **Üyeliği kapat (pencere/form açar)** (satır 46) | — | | | | |
| 6 | Düğme **Aç (indirir)** (satır 55) | — | | | | |
| 7 | Form **(başlık dinamik) — alanlar: Havale dekont no*, İade tarihi*, Gerekçe (tedarikçiye gösterilir)* — başarı: Üyelik kapatıldı** (satır 66) | — | | | | |

### /platform/isletmeler — `/platform/isletmeler`
- **Dosya:** `admin/src/app/platform/isletmeler/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 19): 
  - Veri (satır 20): `GET /market/meta` (marketplace)
  - Sekmeler (satır 28): 
  - Tablo (satır 32): İşletme \| Hesap \| Yer \| Hizmet alanı \| Kategoriler \| Durum
  - Bağlantı (satır 34): hesaba git → `/platform/hesaplar/${b.account_id

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yayına al** (satır 41) | — | | | | |
| 2 | Düğme **Reddet (pencere/form açar)** (satır 43) | — | | | | |
| 3 | Form **Yayın onayını reddet — alanlar: Gerekçe (tedarikçiye gösterilir)* — başarı: Reddedildi** (satır 61) | — | | | | |

### /platform/itirazlar — `/platform/itirazlar`
- **Dosya:** `admin/src/app/platform/itirazlar/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 14): 
  - Tablo (satır 29): Tarih \| Tedarikçi \| Talep \| Neden \| İade \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Onayla ve iade et (pencere/form açar)** (satır 38) | — | | | | |
| 2 | Düğme **Reddet (pencere/form açar)** (satır 39) | — | | | | |
| 3 | Form **(başlık dinamik) — alanlar: Gerekçe (tedarikçiye gösterilir)* — başarı: ** (satır 47) | — | | | | |

### /platform/kategoriler — `/platform/kategoriler`
- **Dosya:** `admin/src/app/platform/kategoriler/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 15): 
  - Bilgi notu (satır 22): Site alımları kendi kategorilerindedir (ör. &quot;Site temizliği&quot; yalnız site yönetim
  - Tablo (satır 26): Kategori \| Üst \| Talep ücreti \| Kim açar \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kategori ekle (pencere/form açar)** (satır 20) | — | | | | |
| 2 | Düğme **Düzenle (pencere/form açar)** (satır 32) | — | | | | |
| 3 | Form **(başlık dinamik) — alanlar: Ad*, Talep ücreti (TL)*, Kim talep açabilir*, Üst kategori, Sıra — başarı: Kategori kaydedildi** (satır 38) | — | | | | |

### /platform/paketler — `/platform/paketler`
- **Dosya:** `admin/src/app/platform/paketler/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 14): 
  - Bilgi notu (satır 24): Fiyat değişikliği mevcut abonelere bir sonraki yenilemede uygulanır. Varsayılan (ücretsiz)
  - Tablo (satır 28): Paket \| Aylık \| Talep indirimi \| Dahil talep / SMS \| Öncelik \| Vitrinde telefon \| Ağırlık

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Paket ekle (pencere/form açar)** (satır 21) | — | | | | |
| 2 | Düğme **Düzenle (pencere/form açar)** (satır 37) | — | | | | |
| 3 | Form **(başlık dinamik) — alanlar: Ad*, Aylık ücret (TL), Talep indirimi (%), Sıralama ağırlığı, Ayda dahil talep, Aylık SMS hakkı, Sıra — başarı: Paket kaydedildi** (satır 43) | — | | | | |

### /platform/yorumlar — `/platform/yorumlar`
- **Dosya:** `admin/src/app/platform/yorumlar/page.tsx`
- **Panel erişimi:** PlatformAdmin — Platform yönetimi (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 13): 
  - Tablo (satır 27): Tarih \| İşletme \| Puan \| Yorum \| Durum

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Gizle (pencere/form açar)** (satır 33) | — | | | | |
| 2 | Form **Yorumu gizle — alanlar: Gerekçe* — başarı: Yorum gizlendi** (satır 39) | — | | | | |

### /tedarikci/(auth)/giris — `/tedarikci/(auth)/giris`
- **Dosya:** `admin/src/app/tedarikci/(auth)/giris/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Bağlantı (satır 14): Tedarikçi olarak kaydolun → /tedarikci/kayit
  - **Bileşen `admin/src/components/auth/login-card.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Bağlantı (satır 122): Şifremi unuttum / hesabımı etkinleştir → /activate
- **Eylem:** yok (salt bilgi / yönlendirme)

### /tedarikci/(auth)/kayit — `/tedarikci/(auth)/kayit`
- **Dosya:** `admin/src/app/tedarikci/(auth)/kayit/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Bağlantı (satır 191): Giriş yapın → /tedarikci/giris
- **Eylem:** yok (salt bilgi / yönlendirme)

### /tedarikci/(panel) — `/tedarikci/(panel)`
- **Dosya:** `admin/src/app/tedarikci/(panel)/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 13): `GET /market/supplier/me` (marketplace)
  - Kart (satır 43): Tedarikçi hesabınızı oluşturun
  - Bilgi notu (satır 46): Havuzda görünmek için hesap bilgilerinizi girip vergi levhası (ya da oda kaydı) ve kimlik 
  - Kart (satır 70): Hesap durumu
  - Bilgi notu (satır 73): İnceleme notu: {acc.status_reason}
  - Bilgi notu (satır 74): Bilgilerinizi ve belgelerinizi tamamlayıp incelemeye gönderin. İnceleme sürerken bilgiler 
  - Bilgi notu (satır 75): Hesabınız inceleniyor. Sonuç size bildirilecek.
  - Kart (satır 80): Hesap bilgileri
  - Veri (satır 98): `GET /market/supplier/documents` (marketplace)
  - Kart (satır 103): Belgeler
  - Dosya seçme (satır 111)
  - Tablo (satır 127): Tür \| Dosya \| Durum \| Yüklendi

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Hesabı oluştur (başarı: Tedarikçi hesabınız oluşturuldu)** (satır 55) | `POST /market/supplier/account` · marketplace · `services/marketplace/main.go:102` | Supplier | mp_supplier_accounts(+) | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id] |
| 2 | Düğme **Kaydet (başarı: Kaydedildi)** (satır 85) | `PUT /market/supplier/account` · marketplace · `services/marketplace/main.go:103` | Supplier | mp_supplier_accounts(±) | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id] |
| 3 | Düğme **Kaydet ve incelemeye gönder (başarı: Hesabınız incelemeye gönderildi)** (satır 86) | `PUT /market/supplier/account` · marketplace · `services/marketplace/main.go:103` | Supplier | mp_supplier_accounts(±) | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id] |
|  | ↳ | `POST /market/supplier/account/submit` · marketplace · `services/marketplace/main.go:104` | Supplier | mp_supplier_accounts(±) | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id] |
| 4 | Düğme **Yükle (başarı: Belge yüklendi)** (satır 112) | `POST /market/supplier/documents` · marketplace · `services/marketplace/main.go:106` | Supplier | mp_account_documents(+) · dosya deposu | yok | Panel tedarikci/(panel) |
| 5 | Düğme **İndir (indirir)** (satır 134) | `GET /market/supplier/documents/:id/file` · marketplace · `services/marketplace/main.go:107` | Supplier | mp_document_access_logs(+) · dosya deposu | yok | — |
| 6 | Düğme **Sil (başarı: Belge silindi)** (satır 136) | `DELETE /market/supplier/documents/:id` · marketplace · `services/marketplace/main.go:108` | Supplier | mp_account_documents(−) · dosya deposu | yok | Panel tedarikci/(panel) |

### /tedarikci/(panel)/bakiye — `/tedarikci/(panel)/bakiye`
- **Dosya:** `admin/src/app/tedarikci/(panel)/bakiye/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 24): `GET /market/supplier/wallet` (marketplace)
  - Veri (satır 25): `GET /market/meta` (marketplace)
  - Veri (satır 26): `GET /market/supplier/me` (marketplace)
  - Bilgi notu (satır 41): Ödeme sonucu: {params.get("message")}
  - Bilgi notu (satır 55): Üyeliğiniz kapatıldı; bakiye yüklenemez ve paket değiştirilemez.
  - Kart (satır 56): Bakiye yükle
  - Bilgi notu (satır 63): Kartla ödeme bu kurulumda yapılandırılmamış.
  - Kart (satır 65): Paket
  - Kart (satır 91): Hareketler
  - Tablo (satır 93): Tarih \| Tür \| Açıklama \| Tutar \| Sonraki bakiye

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kartla öde — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 60) | — | | | | |
| 2 | Düğme **Bu pakete geç — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 82) | — | | | | |
| 3 | Düğme **Değişikliği iptal et — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 83) | — | | | | |
| 4 | Düğme **Önceki (pencere/form açar)** (satır 102) | — | | | | |
| 5 | Düğme **Sonraki (pencere/form açar)** (satır 104) | — | | | | |

### /tedarikci/(panel)/bildirimler — `/tedarikci/(panel)/bildirimler`
- **Dosya:** `admin/src/app/tedarikci/(panel)/bildirimler/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 10): `GET /market/supplier/notifications` (marketplace)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Tümünü okundu say** (satır 15) | `POST /market/supplier/notifications/read` · marketplace · `services/marketplace/main.go:121` | Supplier | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |
| 2 | Düğme **Okundu** (satır 32) | `POST /market/supplier/notifications/read` · marketplace · `services/marketplace/main.go:121` | Supplier | notification_reads(+) | yok | Panel tedarikci/(panel)/bildirimler, Panel/inbox, Sakin main, Sakin notifications, Yön.mobil inbox, Yön.mobil main |

### /tedarikci/(panel)/isletmeler — `/tedarikci/(panel)/isletmeler`
- **Dosya:** `admin/src/app/tedarikci/(panel)/isletmeler/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 11): `GET /market/supplier/businesses` (marketplace)
  - Veri (satır 12): `GET /market/supplier/me` (marketplace)
  - Bağlantı (satır 15): Yeni işletme → /tedarikci/isletmeler/yeni
  - Bilgi notu (satır 16): Önce Hesabım sayfasından tedarikçi hesabınızı oluşturun.
  - Bilgi notu (satır 18): İşletmeleriniz, hesabınız ve işletme bilgileri SiteEksen tarafından onaylandıktan sonra ha
  - Tablo (satır 24): İşletme \| Yer \| Hizmet alanı \| Durum \| Puan
  - Bağlantı (satır 25): {b.name} → `/tedarikci/isletmeler/${b.id
- **Eylem:** yok (salt bilgi / yönlendirme)

### /tedarikci/(panel)/isletmeler/[id] — `/tedarikci/(panel)/isletmeler/[id]`
- **Dosya:** `admin/src/app/tedarikci/(panel)/isletmeler/[id]/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 28): `GET /market/supplier/businesses/:id` (marketplace)
  - Veri (satır 37): `GET /market/meta` (marketplace)
  - Bilgi notu (satır 56): İnceleme notu: {existing.review_note}
  - Bilgi notu (satır 57): İşletme taslakta; havuzda görünmesi için incelemeye gönderin.
  - Kart (satır 58): Bilgiler
  - Veri (satır 132): `GET /market/supplier/businesses/:id/services` (marketplace)
  - Kart (satır 141): Hizmet ve ürünler
  - Dosya seçme (satır 144)
  - Tablo (satır 154): Hizmet \| Fiyat \| Durum
  - **Bileşen `admin/src/components/market/service-photo.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - **Bileşen `admin/src/components/market/field-group.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kaydet — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 107) | — | | | | |
| 2 | Düğme **İncelemeye gönder (başarı: İşletme incelemeye gönderildi)** (satır 109) | `POST /market/supplier/businesses/:id/submit` · marketplace · `services/marketplace/main.go:113` | Supplier | mp_businesses(±) | yok | Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/isletmeler/[id], Panel tedarikci/(panel)/puanlar, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Sakin market_requests, Yön.mobil site_markets |
| 3 | Düğme **İşletmeyi kapat (başarı: İşletme kapatıldı; onay sorar)** (satır 113) | `POST /market/supplier/businesses/:id/close` · marketplace · `services/marketplace/main.go:114` | Supplier | mp_businesses(±) | yok | Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/isletmeler/[id], Panel tedarikci/(panel)/puanlar, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Sakin market_requests, Yön.mobil site_markets |
| 4 | Düğme **Hizmet ekle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 142) | — | | | | |
| 5 | Seçim **—** (satır 144) | `POST /market/supplier/services/:id/photo` · marketplace · `services/marketplace/main.go:119` | Supplier | mp_business_services(±) · dosya deposu | yok | Panel tedarikci/(panel)/isletmeler/[id] |
| 6 | Düğme **Düzenle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (satır 162) | — | | | | |
| 7 | Düğme **Fotoğraf (pencere/form açar)** (satır 163) | — | | | | |
| 8 | Düğme **Sil (başarı: Hizmet silindi)** (satır 164) | `DELETE /market/supplier/services/:id` · marketplace · `services/marketplace/main.go:118` | Supplier | mp_business_services(−) · dosya deposu | yok | Panel tedarikci/(panel)/isletmeler/[id] |
| 9 | Form **(başlık dinamik) — alanlar: Hizmet / ürün adı*, Açıklama, En düşük (TL), En yüksek (TL), Birim — başarı: Hizmet kaydedildi** (satır 171) | `PUT /market/supplier/services/:id` · marketplace · `services/marketplace/main.go:117` | Supplier | mp_business_services(+), mp_business_services(±) | yok | Panel tedarikci/(panel)/isletmeler/[id] |
|  | ↳ | `POST /market/supplier/businesses/:id/services` · marketplace · `services/marketplace/main.go:116` | Supplier | mp_business_services(+), mp_business_services(±) | yok | Panel tedarikci/(panel)/isletmeler/[id] |

### /tedarikci/(panel)/puanlar — `/tedarikci/(panel)/puanlar`
- **Dosya:** `admin/src/app/tedarikci/(panel)/puanlar/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 12): `GET /market/supplier/reviews` (marketplace)
  - Kart (satır 26): ${r.business_name ?? ""} — ${"★".repeat(r.rating)}${"☆".repeat(5 - r.rating)}
  - Bilgi notu (satır 31): Platform bu yorumu gizledi: {r.hidden_reason}

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Yanıtla (başarı: Yanıt yayımlandı)** (satır 37) | `POST /market/supplier/reviews/:id/reply` · marketplace · `services/marketplace/main.go:134` | Supplier | mp_reviews(±) · tetikleyici: mp_reviews_guard, mp_reviews_rating_refresh | yok | Panel tedarikci/(panel)/puanlar, Panel tedarikci/(panel)/talepler/[id], Sakin market_requests, Yön.mobil site_markets |

### /tedarikci/(panel)/talepler — `/tedarikci/(panel)/talepler`
- **Dosya:** `admin/src/app/tedarikci/(panel)/talepler/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 16): `GET /market/supplier/requests` (marketplace)
  - Bilgi notu (satır 32): Hesabınız onaylanmadan talep kabul edemezsiniz.
  - Kart (satır 35): Henüz talep yok
  - Bağlantı (satır 65): Teklif, yazışma ve iletişim → → `/tedarikci/talepler/${r.id
  - Bağlantı (satır 70): Bakiye yetersiz — bakiye yükle → → /tedarikci/bakiye
  - Bağlantı (satır 73): Önizleme → → `/tedarikci/talepler/${r.id

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kabul et (yalnız yazma yetkisi; pencere/form açar)** (satır 68) | — | | | | |
| 2 | Form **Talebi kabul et — alanlar:  — başarı: ** (satır 83) | `POST /market/supplier/requests/:id/accept` · marketplace · `services/marketplace/main.go:124` | Supplier | mp_wallet_ledger(+), mp_request_dispatch(±), mp_requests(±), mp_supplier_accounts(±) · tetikleyici: mp_wallet_ledger_no_change, mp_requests_active_property | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |

### /tedarikci/(panel)/talepler/[id] — `/tedarikci/(panel)/talepler/[id]`
- **Dosya:** `admin/src/app/tedarikci/(panel)/talepler/[id]/page.tsx`
- **Panel erişimi:** Supplier — Tedarikçi paneli (Usta & Hizmet)
- **Ekranda:**
  - Veri (satır 17): `GET /market/supplier/requests/:id` (marketplace)
  - Bağlantı (satır 23): ← Talepler → /tedarikci/talepler
  - Kart (satır 25): Talep
  - Kart (satır 46): Alıcının iletişim bilgisi
  - Bağlantı (satır 50): {r.contact.phone} → `tel:${r.contact.phone
  - Bilgi notu (satır 58): Alıcının adı, telefonu ve adresi talebi kabul ettiğinizde açılır.{" "} {r.status === "OPEN
  - Bağlantı (satır 66): Bakiye yetersiz — bakiye yükle → /tedarikci/bakiye
  - **Bileşen `admin/src/components/market/service-photo.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - **Bileşen `admin/src/components/market/deal-panel.tsx`** (aşağıdaki satır numaraları bu dosyaya aittir)
  - Veri (satır 13): `GET /market/supplier/requests/:id/deal` (marketplace)
  - Kart (satır 37): Teklifiniz
  - Kart (satır 78): İş
  - Bilgi notu (satır 87): Alıcının onayı bekleniyor; süresinde yanıt vermezse iş tamamlanmış sayılır.
  - Bilgi notu (satır 88): Alıcının itirazı: {j.dispute_note}
  - Veri (satır 98): `GET /market/supplier/requests/:id/messages` (marketplace)
  - Kart (satır 102): Alıcıyla yazışma
  - Kart (satır 132): Geçersiz talep bildiriminiz
  - Kart (satır 142): Talep geçersiz mi?

| # | Öğe | Uç · servis · kayıt | Yetki | Değişen tablolar | Bildirim (konu → alıcı) | Etkisinin görüldüğü yerler |
|---|---|---|---|---|---|---|
| 1 | Düğme **Kabul et** (satır 61) | `POST /market/supplier/requests/:id/accept` · marketplace · `services/marketplace/main.go:124` | Supplier | mp_wallet_ledger(+), mp_request_dispatch(±), mp_requests(±), mp_supplier_accounts(±) · tetikleyici: mp_wallet_ledger_no_change, mp_requests_active_property | yok | Panel tedarikci/(panel), Panel tedarikci/(panel)/bakiye, Panel tedarikci/(panel)/isletmeler, Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 2 | Düğme **Geri çek (başarı: Teklif geri çekildi)** (deal-panel satır 46) | `POST /market/supplier/offers/:id/withdraw` · marketplace · `services/marketplace/main.go:128` | Supplier | mp_offers(±) | yok | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Sakin market_requests, Yön.mobil site_markets |
| 3 | Düğme **Teklifi güncelle — yalnız arayüz (pencere/gezinme), sunucu çağrısı yok** (deal-panel satır 62) | — | | | | |
| 4 | Düğme **İş tamamlandı (başarı: Alıcıya iş tamamlandı bildirildi)** (deal-panel satır 83) | `POST /market/supplier/jobs/:id/done` · marketplace · `services/marketplace/main.go:132` | Supplier | mp_jobs(±) · tetikleyici: mp_jobs_completed_refresh | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/talepler, Panel tedarikci/(panel)/talepler/[id], Panel/settings, Sakin market_requests, Yön.mobil site_markets, Yön.mobil site_settings |
| 5 | Düğme **Gönder** (deal-panel satır 119) | `POST /market/supplier/requests/:id/messages` · marketplace · `services/marketplace/main.go:130` | Supplier | mp_messages(+) | `{topic}` → işlemin muhatabı (tek kişi) ya da doğrudan telefon/e-posta | Panel tedarikci/(panel)/talepler/[id], Sakin market_requests |
| 6 | Düğme **Platforma bildir (başarı: Bildiriminiz platforma iletildi)** (deal-panel satır 158) | `POST /market/supplier/requests/:id/dispute` · marketplace · `services/marketplace/main.go:131` | Supplier | mp_disputes(+) | yok | Panel tedarikci/(panel)/talepler/[id] |

## Her sayfada ortak: kenar çubuğu ve üst bar

| Öğe | Ne yapar | Uç |
|---|---|---|
| Aktif site seçici (`sidebar.tsx`) | Siteyi değiştirir, yeni siteye ait jeton alınır, `/dashboard`'a döner | `POST /users/me/active-property`, `POST /auth/refresh`; liste: `GET /users/me/properties` |
| + Yeni Taşınmaz Ekle (`sidebar.tsx`) | Form: Ad*, Adres*, Şehir*, İlçe, Tür (Site/Apartman/Bina) → oluşturur ve o siteye geçer | `POST /users/me/properties` |
| Menü öğeleri | Aktif sitedeki rollere göre süzülür (`canAccess`) | — |
| Ayarlar bağlantısı | Yalnız MANAGER/BOARD_MEMBER görür | — |
| Menü düğmesi (mobil genişlik) | Kenar çubuğunu çekmece olarak açar/kapatır | — |
| Zil simgesi (`notification-bell.tsx`) | Okunmamış sayısını gösterir (60 sn'de bir yenilenir); açılınca son 10 bildirim; bildirime tıklamak okundu sayar; "Tümünü okundu say"; "Tümünü gör" → `/dashboard/inbox` | `GET /notifications/unread-count`, `GET /notifications?channel=IN_APP&limit=10`, `POST /notifications/:id/read`, `POST /notifications/read-all` |
| Kullanıcı menüsü → Şifre değiştir | `/dashboard/account` | — |
| Kullanıcı menüsü → Çıkış Yap (`header.tsx:148`) | Sunucuda jetonları iptal eder, iptal edilemezse uyarır, oturumu kapatır | `POST /auth/logout` |
