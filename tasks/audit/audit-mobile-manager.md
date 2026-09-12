# Yönetici Mobil Uygulama Denetimi (admin_app/)

**Denetim tarihi:** 2026-09-08
**Kapsam:** `C:\Users\md064615\Documents\Projeler\proje99\admin_app\`
**Yöntem:** Statik kod okuma (Read/Grep/Glob + PowerShell). `flutter analyze`/`flutter test` ÇALIŞTIRILMADI (Flutter kurulu değil) — derleme iddiaları bu nedenle "kod okumasına dayalı" olarak işaretlenmiştir.
**Değiştirilen dosya:** yok (yalnızca bu rapor yazıldı).

## 0. Envanter (ölçülen gerçek)

- `lib/` altında **43 .dart dosyası**, toplam **~14.900 satır**.
- ROADMAP.md `admin_app` tablosunda (`ROADMAP.md:138-167`) 25 satır "✅", 3 satır "📋 ekran yok" (Belge Yönetimi `:165`, NPS `:166`, ESG `:167`). Görev tanımındaki "24 ekran" ifadesi ROADMAP'teki listeyle birebir örtüşmüyor — listelenen ✅ ekran sayısı **25**.
- `apiClient` **yalnızca 10 dosyada** geçiyor (Grep, `lib/` tümü). Kalan 33 dosyada hiç ağ çağrısı yok.

### KÖK BULGU — tüm API çağrıları prod'da 404 döner
`lib/core/network/api_client.dart:7`:
```dart
static const String baseUrl = 'https://api.siteeksen.com/v1';
```
Backend'in tamamı `/api/v1` prefix'i bekliyor (Go gateway `backend/cmd/gateway/main.go:133,148,151,154,157,190,193,199,202,214,217`; Kong `kong/kong.yml:9,13,40-42`; her servisin route grubu, örn. `backend/services/identity/main.go:39`). `k8s/ingress.yaml:23,30,37,44` `/v1` prefix'ini tanıyor **ama `rewrite-target` annotation'ı yok** (`ingress.yaml:5-11`) → path `/v1/auth/login` olarak servise iletilir, servis `/api/v1/auth/login` sunar → **404**. Yorumdaki dev URL'i (`api_client.dart:8` → `http://10.0.2.2:8000/api/v1`) doğru formatta; aktif olan yanlış.

**Sonuç: "gerçek API'ye bağlı" işaretli her ekran dahi mevcut yapılandırmada veri çekemez.** Aşağıdaki tablolarda "gerçek API çağrısı" ifadesi *kodda çağrı var* demektir, *çalışıyor* demek değildir.

---

## 1. Ekran Gerçeklik Tablosu

Veri kaynağı kodları: **[M]** hardcoded mock liste · **[A]** gerçek `apiClient` çağrısı · **[A+M]** API okuma + hardcoded yardımcı bloklar · **[FAKE]** sahte başarı (API yok, yeşil snackbar var)

| Ekran | Dosya:satır | Veri kaynağı | Karşı servis gerçek mi | Yazma kalıcı mı | GERÇEK DURUM |
|---|---|---|---|---|---|
| Login | `lib/features/auth/presentation/screens/login_screen.dart` (300) | **[A]** `apiClient.login` `:59` | ✅ identity REAL DB (`identity/service/auth.go:38-43`) | ✅ token yazımı gerçek | İçi dolu. Prefix hatası nedeniyle prod'da 404. |
| KVKK Rıza | `.../auth/.../kvkk_consent_screen.dart` (101) | **[A]** `acceptKvkkConsent` `:21` | ✅ identity REAL DB (`identity/main.go:57`, `migrations/009_kvkk_consent.sql`) | ✅ | İçi dolu; ama **atlanabilir** (bkz. İddia 6). |
| Dashboard | `.../dashboard/.../dashboard_screen.dart` (305) | **[M]** `:52,59,66,73` (`'124'`,`'₺45,780'`), `:143-160` sahte ödemeler | — (`getDashboard()` **hiç çağrılmıyor**) | — | **Tamamen sahte.** `RefreshIndicator` boş: `:21-23` `// TODO: Refresh data`. |
| Sakinler (liste) | `.../residents/.../residents_screen.dart` (268) | **[A]** `getResidents` `:34` | ✅ identity REAL DB (`identity/repository/resident.go:50`) | — | Gerçek. Pagination yok. |
| Sakin Detay | `.../residents/.../resident_detail_screen.dart` (181) | **[A]** `getResident` `:34`, `updateResident` `:52` | ✅ REAL DB (`resident.go:80,149`) | ✅ PATCH gerçek | Gerçek; ama sadece aktif/pasif var, silme/düzenleme yok. |
| Sakin Ekle | `.../residents/.../add_resident_screen.dart` (159) | **[A]** `getUnits` `:39`, `createResident` `:136` | ✅ REAL DB (`resident.go:100,172`) | ✅ | Gerçek. |
| Finans | `.../finance/.../finance_screen.dart` (224) | **[M]** `:39-74` özet, `:104-108` gider dağılımı, `:119-121` borçlular | — (`getFinanceOverview()` hiç çağrılmıyor; ayrıca backend'de `/finance/overview` **route yok** → 404, `finance/main.go:37-57`) | — | **Tamamen sahte.** "Tümünü Gör" `:116` ölü. |
| Tahakkuk Oluştur | `.../finance/.../create_assessment_screen.dart` (223) | **[FAKE]** `:146-153` | — | ❌ **HİÇBİR YERE** | **KRİTİK:** `_createAssessment()` API çağırmadan "Tahakkuk oluşturuldu" yeşil snackbar gösterip `pop()` yapıyor. `createAssessment()` (`api_client.dart:183`) hiç çağrılmıyor. Gider kalemleri `:17-19` hardcoded, daire sayısı `:117` `'124'` sabit. |
| Ödemeler | `.../finance/.../payments_screen.dart` (112) | **[M]** `:35-39` | — (`getPayments()` hiç çağrılmıyor) | — | **Tamamen sahte.** Filtre/indir butonları `:13-14` ölü. |
| Sayaçlar | `.../meters/.../meters_screen.dart` (109) | **[M]** `:61-68` (`// Mock data`, `List.generate(10)`) | — (`getMeters()` hiç çağrılmıyor) | — | **Tamamen sahte.** |
| Sayaç Okuma | `.../meters/.../meter_reading_screen.dart` (156) | **[FAKE]** `:125-147` | — | ❌ | **KRİTİK:** onay diyaloğu var, `submitBulkReadings()` **çağrılmıyor**; "Okumalar kaydedildi" `:138`. Liste `:14-19` `List.generate(10)`. |
| Duyurular | `.../announcements/.../announcements_screen.dart` (91) | **[M]** `:10-14` | — (`getAnnouncements()` hiç çağrılmıyor) | — | **Tamamen sahte.** `PopupMenuButton` `:44-51` `onSelected` **yok** → Düzenle/Sabitle/Sil hiçbir şey yapmıyor. |
| Duyuru Yayınla | `.../announcements/.../create_announcement_screen.dart` (147) | **[FAKE]** `:139-146` | — | ❌ | **KRİTİK:** `createAnnouncement()` çağrılmıyor; "Duyuru yayınlandı" `:142`. Kategori dropdown `:68` `onChanged: (_) {}` → seçim kaybolur. "Dosya Ekle" `:96` ölü. Push switch'i `:79` hiçbir yere gitmiyor. |
| Talepler (liste) | `.../requests/.../requests_screen.dart` (142) | **[M]** `:15-20` | — (`getRequests()` hiç çağrılmıyor) | — | **Tamamen sahte.** Sekme sayıları `:36-38` metne gömülü (`'Açık (2)'`). |
| Talep Detay | `.../requests/.../request_detail_screen.dart` (244) | **[M]** gövde + **[A]** tek yazma `:22` | ⚠️ `PATCH /requests/:id/status` REAL DB (`community/repository/request.go:118`) ama `GET /requests/:id` **route yok** → 404 (`community/main.go:36-43`) | ⚠️ kısmen | `getRequest()` **hiç çağrılmıyor** — başlık/açıklama/talep eden/tarih/öncelik/yorumlar `:74,83,96-102,153-154` sabit ("Asansör Arızası"), hangi id açılırsa açılsın aynı. Yorum gönderme `:169-174` sahte. |
| Raporlar | `.../reports/.../reports_screen.dart` (224) | **[FAKE]** `:125-158` | — | ❌ | **KRİTİK:** `_downloadReport` = 2 sn `Future.delayed` + "Rapor indirildi". `generateReport()` (`api_client.dart:268`) hiç çağrılmıyor; dosya indirilmiyor, "Aç" `:152` ölü. (Backend `POST /reports/generate` de gateway içi hardcoded, auth'suz — `cmd/gateway/main.go:305-398`.) |
| Gider Yönetimi | `.../expenses/.../expenses_screen.dart` (353) | **[M]** `:16-37`, özetler `:83-87` | — | — | **Tamamen sahte.** Filtre chip'leri kozmetik: `itemCount: _expenses.length` `:112` — `_filterType` hiç uygulanmıyor. `_showMonthPicker` `:129-131` boş TODO. |
| Gider Ekle (AI) | `.../expenses/.../add_expense_screen.dart` (469) | **[FAKE]** `:395-413`, `:438-449` | — | ❌ | **KRİTİK:** bkz. İddia 9. AI tarama = 2 sn bekleme + sabit AYEDAŞ sonucu. `_saveExpense` `:440` `// TODO: API call`. `_pickFile` `:385-393` stub. `dart:io` `:1` kullanılmıyor. |
| Gider Detay | `.../expenses/.../expense_detail_screen.dart` (245) | **[M]** `:11-28` (`// Mock data`) | — | ❌ | Sahte; `expenseId` sadece `:13`'te echo. Düzenle `:34` ve `PopupMenuButton` `:35-40` (`onSelected` yok) ölü. |
| *(yönlendirmesiz)* Sakin Giderleri | `.../expenses/.../resident_expenses_screen.dart` (359) | **[M]** | — | — | **ÖLÜ KOD:** `app_router.dart`'ta import/route **yok** → hiçbir yerden erişilemez. |
| Ziyaretçi Yönetimi | `.../visitors/.../visitor_management_screen.dart` (762) | **[A+M]** `getVisitors` `:34`; filtre `:20` ve daire listesi `:729` sabit | ❌ **visitor-service MOCK** (`visitor/main.go:95,134-168`) | ❌ | **"Giriş Yaptır" `:583`, "Çıkış Yaptır" `:598`, "Sakine Bildir" `:613`, "Kaydet" `:690`, "Ziyaretçi Kaydet" `:746` → sadece `Navigator.pop`.** `recordVisitorEntry/Exit` hiç çağrılmıyor. Ayrıca backend'de `/entry`,`/exit` route'ları **yok** (gerçek adlar `/checkin`,`/checkout` — `visitor/main.go:106-107`) → çağrılsa 404. |
| Otopark Yönetimi | `.../parking/.../parking_management_screen.dart` (481) | **[A+M]** `getVehicles` `:37`; `_parkingZones` `:22-26` **hardcoded** | ❌ parking-service MOCK (`parking/main.go:174-212`) | ❌ | Tüm aksiyonlar ölü: `:100` (QR), `:133`, `:275` → `() {}`. `createVehicle`/`getParkingLogs`/`recognizePlate` hiç çağrılmıyor. |
| Rezervasyon Yönetimi | `.../reservations/.../reservation_management_screen.dart` (644) | **[A]** `getFacilities` `:30`, `getReservations` `:31` | ❌ reservation-service MOCK (`reservation/main.go:152-234,298-330`) | — hiç yazma aksiyonu yok | Salt-okunur. Onay/iptal/çakışma kontrolü yok. |
| Enerji Panosu | `.../energy/.../energy_dashboard_screen.dart` (570) | **[M]** `:21-25`, `:27-40`, `:42-...` | — hiç API yok | — | **Tamamen sahte** "AI" anomali + öneri listeleri. `:395` ölü buton. `fl_chart` bağımlı ama **import edilmemiş** → grafikler elle çizilmiş. |
| Personel Yönetimi | `.../personnel/.../personnel_management_screen.dart` (359) | **[A]** `getEmployees` `:31`, `getLeaves` `:32` | ❌ personnel-service MOCK; `/leaves` **her zaman boş** `{"leaves":[]}` (`personnel/main.go:157-159`) | ❌ | İzin onayla/reddet `:340,348` → `() {}`. `updateLeaveStatus` hiç çağrılmıyor; ayrıca backend'de `PATCH /leaves/:id` **yok** (gerçek: `POST /:id/approve|reject` — `personnel/main.go:86-93`). Maaş `:42` ekranda düz gösteriliyor. |
| Envanter Yönetimi | `.../inventory/.../inventory_management_screen.dart` (332) | **[M]** `:19-...` | — hiç API yok | — | **Tamamen sahte.** `:89,183,217` ölü. |
| Anket Yönetimi | `.../surveys/.../survey_management_screen.dart` (429) | **[M]** `:16-...` | — hiç API yok | — | **Tamamen sahte.** |
| Koli Takibi | `.../packages/.../package_tracking_screen.dart` (523) | **[A]** `getPackages` `:31` | ❌ package-service MOCK (`package/main.go:138-197`) | ❌ | `:86,181` ölü. `receivePackage`/`deliverPackage` hiç çağrılmıyor. (Çağrılsa: `POST /packages/:id/deliver` `delivered_to_name` zorunlu, `api_client.dart:350-352` gövdesiz → **400**.) |
| Varlık (Demirbaş) | `.../assets/.../asset_management_screen.dart` (373) | **[M]** `:19-...` | — hiç API yok | — | **Tamamen sahte.** `:89,178,334,342` ölü. |
| Sözleşme Yönetimi | `.../contracts/.../contract_management_screen.dart` (846) | **[M]** `:25,51,105` üç liste | — hiç API yok | ❌ | **Tamamen sahte.** `:676` `// TODO: Dosya seçici aç`. PDF İndir/Yenile/Görüntüle `:732,734,796,798` ölü. `:822` "Belge silindi" snackbar'ı **listeden bile silmiyor**. |
| Güvenlik Turu | `.../patrol/.../patrol_control_screen.dart` (395) | **[M]** `:16,25` | — hiç API yok | — | **Tamamen sahte.** `:82,187` ölü. NFC/QR checkpoint okuma yok. |
| Toplantı Sihirbazı | `.../meetings/.../meeting_wizard_screen.dart` (464) | **[M]** `:14` | — hiç API yok | — | **Tamamen sahte.** `:367,452` ölü. Yeter sayı/vekalet hesabı **yok** (Grep: `quorum|yeter|vekalet` → 0 sonuç). |
| Akıllı Tahsilat | `.../collection/.../smart_collection_screen.dart` (530) | **[M]** `:18` stats, `:25` borç listesi | — hiç API yok | — | **Tamamen sahte.** `:238,270,475,483,494` ölü. İhtar/icra takibi **yok** (Grep: `icra\|ihtar\|noter` → 0). |
| İlan Panosu | `.../bulletin/.../bulletin_board_screen.dart` (622) | **[M]** `:17,26,95` | — hiç API yok | — | **Tamamen sahte.** "Yayınla" `:403`, `:563,598,606` ölü. |
| Banka Entegrasyonu | `.../banking/.../bank_integration_screen.dart` (711) | **[A+M]** `getBankAccounts` `:32`, `getBankTransactions` `:33`; `_stats` `:72-77` **hardcoded** | ❌ banking-service MOCK (`banking/main.go:183-222,325-371`) | ❌ | `_syncTransactions` `:499-503` = 2 sn `Future.delayed`, API yok. `matchBankTransaction` hiç çağrılmıyor (çağrılsa alan adı uyuşmazlığı → **400**, `banking/main.go:87-91` vs `api_client.dart:365-367`). Banka ekleme `:532-541` sabit liste. |
| API Ayarları | `.../settings/.../api_settings_screen.dart` (854) | **[M]** `:26-118` | — hiç API yok | ❌ | **Tamamen sahte + yanıltıcı.** Bkz. İddia 9. `_save` `:838-853` API'siz "API başarıyla eklendi". `_testConnection` `:532-566` 2 sn bekleme + "Bağlantı başarılı (245ms)". Audit log `:594-598` hardcoded. |

### Özet sayım (25 "✅" ekran modülü)

| Kategori | Sayı | Ekranlar |
|---|---|---|
| (iii) Ekran gerçek API'ye bağlı **ve** servis gerçek DB | **3** | Login/KVKK, Sakinler (liste+detay+ekle), Talep durum güncelleme (kısmen) |
| (ii) Ekran gerçek API'ye bağlı **ama servis mock** | **6** | Ziyaretçi, Otopark, Rezervasyon, Personel, Koli Takibi, Banka Entegrasyonu |
| (i) Ekran hardcoded mock / sahte başarı — hiç API yok | **16** | Dashboard, Finans, Tahakkuk, Ödemeler, Sayaçlar, Sayaç Okuma, Duyurular, Duyuru Yayınla, Talepler(liste), Raporlar, Gider Yön.(3 ekran), Enerji, Envanter, Anket, Varlık, Sözleşme, Güvenlik Turu, Toplantı, Tahsilat, İlan Panosu, API Ayarları |
| "Yakında" placeholder | **0** | Hiçbir ekran boş placeholder değil — hepsi **görsel olarak dolu**, işlevsel olarak boş. |

**Ekran dosyası olarak 25/25 mevcut ve içi dolu görünüyor** — ROADMAP'in "ekran var" iddiası dosya düzeyinde doğru. Ancak **25 modülün 16'sı hiç ağ kodu içermiyor** ve **kalıcı yazma yapan yalnızca 5 aksiyon var** (login, kvkk-consent, createResident, updateResident, updateRequestStatus).

### KRİTİK: 19 ekran menüden erişilemez
`main_screen.dart` drawer'ı (`:114-220`) yalnızca Dashboard, Sakinler, Finans, Sayaçlar, Duyurular, Talepler, Raporlar içeriyor. `_allNavItems` (`:26-32`) 5 sekme. Yani **Gider Yönetimi, Otopark, Ziyaretçi, Rezervasyon, Enerji, Personel, Envanter, Anket, Koli, Varlık, Sözleşme, Güvenlik Turu, Toplantı, Tahsilat, İlan Panosu, Banka, API Ayarları (17 ekran)** route'u var ama **hiçbir UI öğesinden erişilemiyor** — sadece elle deep-link ile. (Karşılaştırma: `tasks/roadmap.md:92` web admin paneli için "Sidebar güncellendi — 5 yeni nav öğesi" diyor; admin_app'e bu yapılmamış.)

---

## 2. İddia Doğrulama

### İddia 4 — "Sakinler gerçek API'ye bağlandı, `/users?role=RESIDENT` → `/residents` birleştirmesi, `updateResident` artık PATCH"
**Kaynak:** `ROADMAP.md:142`, `tasks/roadmap.md:70,142`
**Verdict: ✅ DOĞRU (3/3)**
**Kanıt:**
- `api_client.dart:139-146` → `GET /residents` (`?search=&block=&role=`), `:148` `GET /residents/$id`, `:153` `POST /residents`, `:157-159` **`_dio.patch('/residents/$id')`** ✅
- Repoda `users?role=RESIDENT` kalıntısı yok (Grep: `role=RESIDENT` → 0 sonuç).
- Backend karşılığı gerçek: `identity/main.go:64-67`, `identity/repository/resident.go:50,80,100,149` (gerçek SQL). Gateway proxy: `backend/cmd/gateway/main.go:133`.
- Yanıt şekli uyumlu: `{"data":[...]}` (`identity/handlers/resident.go:47,111`) ↔ `api_client.dart:145,165`.
**Gerçek durum:** Bu, uygulamada **tam gerçek olan tek modül**. Eksikler: pagination yok (`getResidents`'ta `page` parametresi yok — 124+ sakinde tümü tek seferde), silme yok, CSV yok, bakiye/borç sütunu yok (ROADMAP `:70` da bunu kabul ediyor).

### İddia 5 — "Biyometrik giriş: `local_auth` + `flutter_secure_storage` kalıcı oturum + `loginWithStoredSession`"
**Kaynak:** `ROADMAP.md:129`
**Verdict: ⚠️ KISMEN DOĞRU — kod var, Android'de ÇALIŞMAZ, 3 güvenlik açığı var**
**Kanıt (kod var):** `pubspec.yaml:27,30`; `login_screen.dart:18` `LocalAuthentication()`, `:30-41` uygunluk kontrolü, `:114-142` `_handleBiometricLogin`, `:120-123` `authenticate(biometricOnly: true)`, `:126` `loginWithStoredSession()`; `api_client.dart:111-128` (`hasStoredSession`, `isBiometricEnabled`, `setBiometricEnabled`, `loginWithStoredSession` → `_refreshToken()`).

**Kanıt (çalışmaz):** `android/app/src/main/kotlin/com/example/siteeksen_admin/MainActivity.kt:3-5`:
```kotlin
import io.flutter.embedding.android.FlutterActivity
class MainActivity : FlutterActivity()
```
`local_auth` Android'de **`FlutterFragmentActivity` zorunlu kılar**; `FlutterActivity` ile `authenticate()` `no_fragment_activity` PlatformException atar. `login_screen.dart:133-137` bunu yakalayıp "Biyometrik doğrulama başarısız" gösterir → **buton görünür ama her zaman başarısız.**

**Güvenlik açıkları:**
1. **Logout token'ları silmiyor.** `main_screen.dart:209-216` "Çıkış Yap" yalnızca `context.go('/login')` yapıyor; `apiClient.logout()` (`api_client.dart:82-85`) **hiç çağrılmıyor** (Grep: `apiClient.logout` → 0 sonuç). Refresh token cihazda kalır → çıkış yapan yönetici sonrasında biyometrikle (veya interceptor'ın otomatik refresh'iyle) oturumu geri açar. Paylaşılan/kayıp cihazda **oturum devralma**.
2. **`FlutterSecureStorage` sertleştirilmemiş.** `api_client.dart:11` `const FlutterSecureStorage()` — Android için `encryptedSharedPreferences: true` verilmemiş; iOS için `accessibility`/`.unlocked_this_device` ayarı yok. Root'lu cihazda refresh token okunabilir.
3. **Biyometrik, sunucu tarafında hiçbir şey doğrulamıyor.** `loginWithStoredSession()` = `_refreshToken()` (`api_client.dart:128`), yani yalnızca cihazdaki refresh token'ı kullanır. `biometric_enabled` bayrağı da aynı depoda düz metin `'true'` (`:120-124`) — bayrağı silmek/eklemek erişimi etkilemez, çünkü refresh token'ı olan herkes zaten `_refreshToken()` yolunu kullanabilir. Biyometrik yalnızca **UI kapısı**dır.
4. Ek: `authenticate(...)` çağrısında `stickyAuth: true` yok → arka plana alma ile doğrulama iptal olur; `isDeviceSupported()`/kayıtlı parmak izi kontrolü yapılmamış (`canCheckBiometrics` donanım varlığını söyler, kayıtlı biyometri olduğunu söylemez).
5. Ek: `_refreshToken()` (`api_client.dart:42-60`) yalnızca `access_token`'ı yazıyor, dönen yeni `refresh_token`'ı **kaydetmiyor** → refresh token rotasyonu varsa 2. yenileme başarısız olur. Ayrıca 401 interceptor'ında (`:29-38`) **eşzamanlılık kilidi yok** → paralel 401'lerde çoklu refresh yarışı; refresh başarısızsa oturum sonlandırma/`/login`'e yönlendirme **yok** (sadece hata yayılır).

### İddia 6 — "KVKK açık rıza ekranı — geçilemez `PopScope(canPop: false)`"
**Kaynak:** `ROADMAP.md:132`
**Verdict: ⚠️ KISMEN DOĞRU — `PopScope` var, ekran ATLANAB İLİR**
**Kanıt (doğru kısım):** `kvkk_consent_screen.dart:37-38` `PopScope(canPop: false, ...)`; `:42` `automaticallyImplyLeading: false`; onay butonu `:85` yalnızca checkbox işaretli ve gönderim bitmemişse aktif; `:21` gerçek `acceptKvkkConsent()` çağrısı (backend gerçek: `identity/main.go:57`, `migrations/009_kvkk_consent.sql`).
**Kanıt (bypass'lar):**
1. **Biyometrik giriş KVKK'yı tamamen atlar.** `login_screen.dart:126-129`: `loginWithStoredSession()` başarılıysa doğrudan `context.go('/')`. `kvkk_consent_required` kontrolü **yalnızca** şifreli giriş yolunda var (`:62-67`).
2. **Router'da guard yok.** `app_router.dart:296-303` `redirect` her zaman `null` döner (`// TODO: Auth kontrolü`). Rıza vermemiş kullanıcı `/`, `/residents`, `/finance` gibi herhangi bir route'a deep-link ile girebilir; `/kvkk-consent` bir kapı değil, sadece bir sayfa.
3. **Rıza durumu client'ta hiç saklanmıyor** — uygulama yeniden açıldığında (login yapılmadıkça) hiç kontrol edilmiyor.
**Gerçek durum:** Ekran hukuki metin olarak iyi yazılmış (`:53-67`), teknik olarak zorlayıcı değil. KVKK "açık rıza" gereksinimi karşılanmıyor sayılır. Ayrıca **rıza geri alma (withdraw) yolu yok** ve metinde belirtilen "sistem yöneticisine başvurun" dışında KVKK m.11 hakları için uygulama içi mekanizma yok.

### İddia 7 — "Android geri tuşu düzeltmesi — `main_screen.dart`'a `PopScope`"
**Kaynak:** `ROADMAP.md:131`
**Verdict: ✅ DOĞRU**
**Kanıt:** `main_screen.dart:89-98`:
```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (_selectedIndex != 0) { _onItemTapped(0); } else { _confirmExit(); }
  },
```
`_confirmExit()` `:64-85` onay diyaloğu + `SystemNavigator.pop()` `:83`. `import 'package:flutter/services.dart'` `:2` mevcut.
**Küçük kusur:** `_selectedIndex` yalnızca `_onItemTapped` ile güncelleniyor (`:59-62`); drawer'dan veya `context.go` ile gidilen sayfalarda güncellenmez → drawer'dan Talepler'e gidip geri tuşuna basmak "çıkış onayı" gösterir, Dashboard'a dönmez. Ayrıca `onPopInvokedWithResult` yerleşik `pop` yığınını da bastırıyor; alt route'lardan (`/residents/:id`) geri dönüş ShellRoute içi olduğu için etkilenmez ama davranış route state'iyle senkron değil.

### İddia 8 — "RBAC: JWT `roles` claim'ini decode eden `getCurrentUserRoles()`; AUDITOR/STAFF Sakinler/Finans/Raporlar görmüyor"
**Kaynak:** `ROADMAP.md` admin_app bölümü / `tasks/roadmap.md:55`
**Verdict: ❌ İDDİANIN İKİNCİ YARISI YANLIŞ; birinci yarı doğru ama SADECE KOZMETİK DEĞİL — backend kısmen koruyor**

**a) `getCurrentUserRoles()` var ve claim adı doğru — ✅**
`api_client.dart:88-102`: token'ı `.` ile bölüp `base64Url.normalize(parts[1])` → `jsonDecode` → `payload['roles']` (List). Backend gerçekten `roles` (dizi) üretiyor: `backend/services/identity/service/auth.go:143-150`. **Eşleşiyor.** İmza **doğrulanmıyor** (client-side decode, beklenen).

**b) "AUDITOR/STAFF görmüyor" — ❌ YANLIŞ**
`main_screen.dart:28-29`:
```dart
_NavItem(..., 'Sakinler', path: '/residents', allowedRoles: [roleManager, roleAuditor]),
_NavItem(..., 'Finans',   path: '/finance',   allowedRoles: [roleManager, roleAuditor]),
```
ve drawer `:156,165,199` `_canSee([roleManager, roleAuditor])`.
**AUDITOR açıkça İZİNLİ.** Yalnızca **STAFF** gizlenir. İddia AUDITOR'ı yanlış tarafa koyuyor.

**c) Fail-open — ⚠️ KRİTİK MANTIK HATASI**
`main_screen.dart:54-57` ve `:231-235`:
```dart
if (_roles.isEmpty) return true; // rol bilgisi henüz yüklenmedi — flicker'ı önle
```
Token yoksa, süresi geçmişse, bozuksa veya `roles` claim'i boşsa `getCurrentUserRoles()` `[]` döner (`api_client.dart:90,93,98,100` — dört ayrı `return []`) → **her şey görünür**. "Flicker önleme" gerekçesi, kalıcı bir yetki atlatmasına dönüşmüş: rolsüz/token'sız bir kullanıcı tam menüyü görür.

**d) "Sadece kozmetik mi?" — HAYIR, ama koruma DELİK**
Backend'de `RequireRole` middleware'i **tüm repoda tek yerde** kullanılıyor: `backend/services/identity/main.go:55` (`POST /users/me/properties`). Sakinler/Finans/Raporlar route'larına **bağlanmamış**. Bunun yerine **servis katmanı** guard'ları var:
- residents: `identity/service/resident.go:30-38` `isResidentManagement`, guard'lar `:42,50,58,76,84` → MANAGER/AUDITOR/STAFF dışına 403 ✅
- finance: `finance/service/finance.go:17` `isFinanceManagement`, guard'lar `:85,102,111,163` ✅
- **AMA:** `GET /finance/assessments` (`finance/main.go:45` → `service/finance.go:76`) ve `GET /finance/debt-status` (`finance/main.go:48`) **hiç rol kontrolü içermiyor** → kimliği doğrulanmış **her** kullanıcı (sakin dahil) tüm tahakkuk verisini okur.
- **Raporlar:** `POST /api/v1/reports/generate` gateway içinde ve **hiç auth yok** — gateway zinciri `logMiddleware(corsMiddleware(mux))` (`cmd/gateway/main.go:422`), JWT doğrulaması yok → **kimliksiz herkes rapor üretir.**
- announcements, meters, notifications, vehicles/parking, employees/leaves, visitors, packages, banking, facilities/reservations servislerinin **hiçbirinde `AuthMiddleware` yok** (`community/main.go:46-55`, `iot/main.go:21`, `notification/main.go:44`, `parking/main.go:122`, `personnel/main.go:65`, `visitor/main.go:91`, `package/main.go:101`, `banking/main.go:138`, `reservation/main.go:105`) → **tamamen açık.**
**Gerçek durum:** Menü gizleme kozmetik + fail-open. Backend koruması residents/finance-yazma için gerçek, ancak raporlar ve 10 servis korumasız. **Aksiyon seviyesinde client kontrolü hiç yok** — hiçbir ekranda rol bazlı buton devre dışı bırakma/gizleme yok (Grep: `_roles`/`getCurrentUserRoles` yalnızca `main_screen.dart`'ta).

### İddia 9 — "Gider Yönetimi — AI fatura tarama dahil"
**Kaynak:** `ROADMAP.md:154`, `tasks/roadmap.md:199` ("OpenAI Vision / Google Document AI")
**Verdict: ❌ TAMAMEN YANLIŞ — gerçek AI çağrısı YOK**
**Kanıt:** `add_expense_screen.dart:395-413`:
```dart
Future<void> _scanWithAI(Map<String, dynamic> file) async {
  setState(() => _isScanning = true);
  // Simulate AI scan delay
  await Future.delayed(const Duration(seconds: 2));
  setState(() {
    _isScanning = false;
    _aiScanResult = {
      'vendor_name': 'AYEDAŞ Elektrik Dağıtım A.Ş.',
      'invoice_number': '2026-001234', 'invoice_date': '28.01.2026',
      'total_amount': 2450.75, 'tax_amount': 441.14,
      'category_suggestion': 'Ortak Elektrik', 'confidence': 0.94,
    };
  });
}
```
Hangi dosya verilirse verilsin **aynı sabit sonuç** ve sahte "%94 güven" (`:323`). Ağ çağrısı yok, `apiClient` import edilmemiş.
Dahası: **dosya seçilemiyor** — `_pickFile` `:385-393`:
```dart
// Stub: file_picker v1 embedding uyumsuzluğu nedeniyle devre dışı
final stubFile = <String, dynamic>{'name': 'belge.pdf', ...};
```
`pubspec.yaml`'da `file_picker`, `image_picker`, `camera` **hiç yok** → kameradan/galeriden fatura alma imkânı yok. AndroidManifest'te `CAMERA` izni de yok (`android/app/src/main/AndroidManifest.xml` — dosyada **hiç `uses-permission` yok**).
Kaydetme de sahte: `:438-449` `// TODO: API call` + "Gider eklendi".
Backend tarafında `POST /expenses` benzeri bir çağrı `api_client.dart`'ta **hiç tanımlı değil** (gider metodu yok).

**API key yönetimi — mobil uygulamada GERÇEK KEY GÖMÜLÜ DEĞİL (iyi haber), ama iki sorun var:**
1. `api_settings_screen.dart:492` ve `:498`:
```dart
'sk-1234567890abcdefghijklmnopqrstuvwxyz', // Demo key
Clipboard.setData(const ClipboardData(text: 'sk-1234567890abcdefghijklmnopqrstuvwxyz'));
```
Bu **sahte** bir placeholder (gerçek key sızıntısı YOK — `.env.example`'da `OPENAI` girdisi de yok, Grep → 0). Ancak "API Anahtarını Göster" işlevi **hangi servis seçilirse seçilsin aynı sabit dizeyi** gösteriyor ve panoya kopyalıyor → operatör bunu gerçek key sanıp yapılandırmaya girebilir. `_copyKey` `:525-529` ise **maskelenmiş** dizeyi (`'••••••••abc123'`) kopyalıyor.
2. **Yanıltıcı güvenlik beyanı.** `api_settings_screen.dart:191-192` kullanıcıya şunu söylüyor: *"Bu sayfadaki bilgiler şifrelenmiş olarak saklanır. Her değişiklik kayıt altındadır."* Gerçekte: `_save` `:838-853` hiçbir yere yazmıyor, `_credentials` `:26-118` hardcoded, audit log `:594-598` sahte 3 satır. Bu, denetim izi olduğuna dair **yalan bir güvence**.
**Gerçek durum:** ROADMAP'in "AI fatura tarama dahil ✅" iddiası desteklenemez. (`tasks/roadmap.md:58` ve `tasks/todo.md:112` dürüstçe "📋 OpenAI Vision gerçek API key ile test edilmeli" diyor — ROADMAP'in "✅" satırı bununla çelişiyor.)

### İddia 10 — "Talep detayında RESOLVED seçince 'sakin onayı bekleniyor' notu + `apiClient.updateRequestStatus()` gerçek çağrısı"
**Kaynak:** `ROADMAP.md:128`
**Verdict: ⚠️ KISMEN DOĞRU — banner ve çağrı var; "not" backend'e GİTMİYOR, ekranın geri kalanı sahte**
**Kanıt (doğru):**
- Banner: `request_detail_screen.dart:120-141`, metin `:134`: *"Talep 'Çözüldü' olarak işaretlendi. Talep, sakin onayladıktan sonra otomatik olarak kapatılacaktır."* — yalnızca `_status == 'RESOLVED'` iken.
- Çağrı gerçek: `:22` `await apiClient.updateRequestStatus(widget.requestId, _status)` → `api_client.dart:255-260` `PATCH /requests/$id/status`. Backend gerçek DB: `community/main.go:41`, `community/repository/request.go:118`. ✅
**Kanıt (yanlış/eksik):**
1. **"Not" gönderilmiyor.** `api_client.dart:255` imzası `{String? note}` alıyor ve gövdeye `'note': note` koyuyor, ama `:22`'deki çağrı `note` **vermiyor** → `note: null` gider. Banner tamamen client-side kozmetik; sakine/kayda hiçbir not düşmez.
2. **Ekranın tamamı sahte veri.** `getRequest()` (`api_client.dart:250`) **hiç çağrılmıyor**: başlık `:74` `'Asansör Arızası'`, açıklama `:83`, talep eden `:96`, tarih `:98`, kategori `:100`, öncelik `:102`, yorum sayısı `:149` `'2 yorum'`, yorumlar `:153-154` — hepsi sabit. `/requests/5` de `/requests/99` de aynı "Asansör Arızası"nı gösterir. Yönetici **yanlış talebi** RESOLVED işaretleyebilir.
3. `_status` `:15` her zaman `'OPEN'` başlar — talebin gerçek durumu okunmadığı için yönetici farkında olmadan durumu geri alabilir.
4. Yorum ekleme sahte: `:169-174` sadece `_commentController.clear()` + "Yorum eklendi". `addRequestComment` (`api_client.dart:262`) hiç çağrılmıyor — üstelik backend'de `POST /requests/:id/comments` route'u **yok** (`community/main.go:36-43`) → 404.
5. `PopupMenuButton` `:45-51` ("Görevli Ata", "Öncelik Değiştir") `onSelected` **yok** → ölü.
6. `_commentController` `dispose()` edilmiyor → leak.
7. Backend'de `GET /requests/:id` route'u yok (`community/main.go:36-43`) → çağrılsa da 404 olurdu.

### İddia 11 — "pubspec bağımlılıkları / üretilmiş dosyalar / DERLENİR Mİ"
**Verdict: ✅ Codegen ENGELİ YOK (iddia edilen kritik risk gerçekleşmemiş) — ANCAK `test/` DERLENMİYOR ve 16 bağımlılık ölü**

**a) `*.g.dart` / `*.freezed.dart` — YOK ve GEREKMİYOR**
PowerShell taraması: `admin_app` altında **0 adet** `.g.dart`/`.freezed.dart`. Ancak:
- `lib/` altında **hiç `part` direktifi yok** (Grep `^part ` → 0 sonuç).
- `pubspec.yaml`'da **`freezed`/`freezed_annotation`/`json_serializable`/`json_annotation` YOK** (`:62-67` dev_dependencies: yalnızca `flutter_test`, `flutter_lints`, `riverpod_generator`, `build_runner`).
- `@riverpod` annotation'ı hiç kullanılmıyor (Grep `riverpod_annotation` import → 0 sonuç).
→ **Üretilecek dosya olmadığı için `lib/` codegen eksikliğinden derlenmez durumda DEĞİL.** `riverpod_annotation` (`:17`), `riverpod_generator` (`:66`), `build_runner` (`:67`) tamamen gereksiz bağımlılıklar.

**b) `test/` KESİN DERLENMEZ — KRİTİK**
`test/widget_test.dart:16`:
```dart
await tester.pumpWidget(const MyApp());
```
`main.dart`'ta tanımlı sınıf **`SiteEksenAdminApp`** (`main.dart:21`). **`MyApp` diye bir sınıf yok** → `flutter test` **derleme hatasıyla başarısız olur**. Dosya Flutter'ın varsayılan sayaç şablonu; `:19-28` sayaç assertion'ları da uygulamayla ilgisiz. **Gerçek test sayısı: 0.**

**c) Kullanılmayan bağımlılıklar — 16/25 ÖLÜ**
Grep (tüm `lib/`) ile **hiç import edilmediği** doğrulanan (0 eşleşme):
`intl`, `fl_chart`, `shimmer`, `flutter_svg`, `cached_network_image`, `connectivity_plus`, `url_launcher`, `package_info_plus`, `open_file`, `path_provider`, `firebase_messaging`, `flutter_local_notifications`, `shared_preferences`, `flutter_form_builder`, `form_builder_validators`, `riverpod_annotation`.
Kullanılanlar: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `local_auth`, `firebase_core`, `cupertino_icons`, (`flutter/*`).
**Sonuçları:**
- `firebase_messaging` + `flutter_local_notifications` import edilmemiş → **FCM token kaydı, mesaj dinleme, bildirim gösterme kodu HİÇ YOK.** Push bildirim özelliği (ör. `create_announcement_screen.dart:79` "Push bildirim gönder" switch'i) tamamen sahte.
- `intl` yok → **para/tarih formatlama tamamen elle** (bkz. bölüm 5).
- `fl_chart` yok → grafikler elle `LinearProgressIndicator`/`Container` ile çizilmiş.
- `connectivity_plus` yok → **offline algılama yok**.
- `open_file`/`path_provider` yok → rapor "indirme" fiziksel olarak imkânsız (İddia: Raporlar).
- `intl` sürümü `any` (`:46`) — pin'siz, kırılgan.

**d) Diğer analiz uyarıları (kod okumasına dayalı, `flutter analyze` çalıştırılmadı)**
- `add_expense_screen.dart:1` `import 'dart:io';` — kullanılmıyor.
- `expenses_screen.dart:13` `_selectedMonth` atanıyor, hiç okunmuyor; `:14` `_filterType` okunuyor ama listeye uygulanmıyor.
- `meters_screen.dart` `_MetersScreenState` `dispose()`'da `_tabController.dispose()` **yok** (`:12-19`) → leak. Aynı sorun `requests_screen.dart:22-26`.
- `request_detail_screen.dart:17` `_commentController` dispose edilmiyor.
- `resident_expenses_screen.dart` (359 satır) router'a bağlı değil → ölü kod.

### İddia 12 — Platform yapılandırması
**Verdict: ❌ CİDDİ EKSİKLER**

| Konu | Durum | Kanıt |
|---|---|---|
| `android/` | ✅ var | `admin_app/android/...` |
| **`ios/`** | ❌ **HİÇ YOK** | `Test-Path admin_app\ios` → `False`. iOS derlemesi imkânsız; `local_auth`/`firebase` iOS yapılandırması yok. |
| `google-services.json` | ❌ **YOK** | Recursive tarama → 0 sonuç. `GoogleService-Info.plist` de yok. |
| `firebase_options.dart` | ❌ **YOK** | Recursive tarama → 0 sonuç. |
| `com.google.gms.google-services` gradle plugin | ❌ **YOK** | `android/app/build.gradle.kts:1-6` plugin listesinde yok. |
| **İzinler (main manifest)** | ❌ **HİÇ YOK** | `android/app/src/main/AndroidManifest.xml` — dosyada **tek bir `<uses-permission>` yok**. `INTERNET` yalnızca `src/debug/AndroidManifest.xml:6` ve `src/profile/`'da. |
| CAMERA izni | ❌ yok — fatura tarama için gerekli | yukarıdaki gibi; ayrıca kamera paketi de pubspec'te yok |
| POST_NOTIFICATIONS (Android 13+) | ❌ app manifest'te yok | FCM bildirimleri Android 13+'da gösterilemez |
| USE_BIOMETRIC | app manifest'te yok (local_auth eklentisi kendi manifest'inden merge eder) | asıl blokaj `FlutterActivity` (İddia 5) |
| Release imzalama | ❌ **DEBUG anahtarıyla** | `android/app/build.gradle.kts:35-37`: `// TODO: Add your own signing config` + `signingConfig = signingConfigs.getByName("debug")` → Play Store'a yüklenemez |
| applicationId | ⚠️ `com.example.siteeksen_admin` | `build.gradle.kts:23-24` — `// TODO: Specify your own unique Application ID`; `com.example.*` Play Store'da **reddedilir** |
| Base URL localhost mı? | ❌ localhost değil, ama **prefix yanlış** | `api_client.dart:7` `https://api.siteeksen.com/v1` — `/api/v1` olmalı (bkz. bölüm 0). Ayrıca build-time yapılandırma yok (`--dart-define` / flavor yok) → dev/staging/prod ayrımı imkânsız, URL değiştirmek için kod düzenlemek gerekiyor. |

**`Firebase.initializeApp()` sonucu:** `main.dart:12-16` try/catch içinde → uygulama çökmez ama `google-services.json` + gradle plugin olmadığı için **Firebase başlatılamaz** ve sadece `debugPrint` ile yutulur (`:15`). Zaten `firebase_messaging` import edilmediği için push akışı hiç kurulmamış.

**Sonuç: `INTERNET` izni release manifest'inde açıkça tanımlı değil.** Bu Flutter şablonunun standart davranışıdır ve eklenti AAR manifest'lerinden merge olması muhtemeldir; **`flutter build` çalıştırılamadığı için kesin doğrulanamadı: manifest merge çıktısı üretilemedi.** Yine de release APK'da internetin eklenti merge'ine bağlı olması kırılgan bir varsayımdır.

### İddia 13 — "Mimari: Riverpod gerçekten kullanılıyor mu? go_router route'ları eksiksiz mi?"
**Verdict: ❌ RIVERPOD PRATİKTE KULLANILMIYOR; ROUTE'LAR VAR AMA GUARD'SIZ ve MENÜSÜZ**

**a) Riverpod = 1 provider, 0 state yönetimi**
Grep (tüm `lib/`) sonucu Riverpod'un **tüm** kullanımı:
- `main.dart:2,21,26` (`ConsumerWidget`, `ref.watch(appRouterProvider)`)
- `app_router.dart:2,43` (`Provider<GoRouter>`), `:298` yorum satırı
**Bu kadar.** `lib/features/` altında **hiç** `ConsumerWidget`/`ConsumerStatefulWidget`/`ref.watch`/`ref.read`/`StateNotifier`/`FutureProvider` yok. 43 ekranın tamamı `StatefulWidget` + `setState` (veya `StatelessWidget`).
**Sonuç:** Riverpod yalnızca router'ı enjekte etmek için var. `authProvider` **yok** (`app_router.dart:298` yorumda geçiyor). Paylaşılan state, cache, invalidation, optimistic update yok — her ekran kendi `_isLoading`/`List` alanını `initState`'te dolduruyor. Ekranlar arası veri tutarlılığı yok (ör. sakin eklenince Dashboard sayısı güncellenmez — Dashboard zaten sabit `'124'`).
`api_client.dart:382` `final apiClient = ApiClient();` — **global singleton**, Riverpod dışı; test edilemez/mock'lanamaz.

**b) go_router**
- 27 route tanımlı (`app_router.dart:46-293`), 25 modül ekranı + login + kvkk. ROADMAP'in "📋 ekran yok" dediği Belge/NPS/ESG için route yok ✅ (tutarlı).
- ❌ **`redirect` boş** (`:296-303`): `// TODO: Auth kontrolü` — üç satır yorumlanmış. **Auth guard yok** → giriş yapılmadan `/`, `/finance`, `/residents` vs. açılabilir.
- ❌ `initialLocation: '/login'` (`:45`) tek koruma; kayıtlı oturum varken bile her açılışta login gösterir (kalıcı oturum "kalıcı" değil — UX kaybı).
- ❌ `errorBuilder` yok → tanımsız route'ta çirkin varsayılan hata ekranı.
- ⚠️ Alt route'larda `context.go` vs `context.push` karışık: `residents_screen.dart:123,133` `push` (dönüş değeri kullanılıyor ✅) ama `expenses_screen.dart:115,122`, `requests_screen.dart:66`, `meters_screen.dart:47` `go` kullanıyor → detay ekranından geri dönüş yığını bozuk.
- ❌ 17 route menüden erişilemez (bölüm 1 sonu).

---

## 3. api_client.dart ↔ Backend ↔ Servis Gerçekliği Tablosu

`api_client.dart` toplam **34 public metot**. Aşağıda hepsi. "Gateway" = `backend/cmd/gateway/main.go`. **Tüm satırlar için ek olarak: `/v1` vs `/api/v1` prefix hatası (bölüm 0) nedeniyle prod'da hiçbiri erişilemez.**

| # | Metot (`api_client.dart:satır`) | HTTP + yol | Gateway route ediyor? | Servis | Servis route'u var? | **Servis GERÇEK Mİ MOCK MU** | Ekranda çağrılıyor? |
|---|---|---|---|---|---|---|---|
| 1 | `login` `:70` | POST `/auth/login` | ✅ `main.go:133` | identity | ✅ `identity/main.go:43` | **GERÇEK DB** (`identity/service/auth.go:38-43`) | ✅ `login_screen.dart:59` |
| 2 | `logout` `:82` | (yalnızca yerel silme) | — | — | — | — | ❌ **hiç çağrılmıyor** |
| 3 | `_refreshToken` `:42` | POST `/auth/refresh` | ✅ `main.go:133` | identity | ✅ `identity/main.go:44` | **GERÇEK DB** | ✅ interceptor + biyometrik |
| 4 | `getCurrentUserRoles` `:88` | (yerel JWT decode) | — | — | — | claim `roles` ✅ eşleşiyor (`identity/service/auth.go:143-150`) | ✅ `main_screen.dart:44` |
| 5 | `acceptKvkkConsent` `:105` | POST `/users/me/kvkk-consent` | ✅ `main.go:133` | identity | ✅ `identity/main.go:57` | **GERÇEK DB** (`migrations/009_kvkk_consent.sql`) | ✅ `kvkk_consent_screen.dart:21` |
| 6 | `hasStoredSession` `:111` | (yerel) | — | — | — | — | ✅ `login_screen.dart:33` |
| 7 | `isBiometricEnabled` `:115` | (yerel) | — | — | — | — | ✅ `:34,84` |
| 8 | `setBiometricEnabled` `:119` | (yerel) | — | — | — | — | ✅ `:110` |
| 9 | `loginWithStoredSession` `:128` | POST `/auth/refresh` | ✅ | identity | ✅ | **GERÇEK DB** | ✅ `:126` |
| 10 | `getDashboard` `:132` | GET `/dashboard/stats` | ⚠️ gateway'in **kendi** handler'ı | (yok) | — | **HARDCODED** (`cmd/gateway/main.go:221-277`; fetchJSON zarf uyuşmazlığı nedeniyle gerçek servis değerleri hiç uygulanmaz — `main.go:447-463`) | ❌ **hiç çağrılmıyor** |
| 11 | `getResidents` `:139` | GET `/residents` | ✅ `main.go:133` | identity | ✅ `identity/main.go:64` | **GERÇEK DB** (`repository/resident.go:50`) | ✅ `residents_screen.dart:34` |
| 12 | `getResident` `:148` | GET `/residents/{id}` | ✅ | identity | ✅ `:66` | **GERÇEK DB** (`resident.go:80`) | ✅ `resident_detail_screen.dart:34` |
| 13 | `createResident` `:153` | POST `/residents` | ✅ | identity | ✅ `:65` | **GERÇEK DB** (`resident.go:100`) | ✅ `add_resident_screen.dart:136` |
| 14 | `updateResident` `:157` | **PATCH** `/residents/{id}` | ✅ | identity | ✅ `:67` | **GERÇEK DB** (`resident.go:149`) | ✅ `resident_detail_screen.dart:52` |
| 15 | `getUnits` `:163` | GET `/units` | ✅ `main.go:138` | identity | ✅ `:73` | **GERÇEK DB** (`resident.go:172`) | ✅ `add_resident_screen.dart:39` |
| 16 | `getFinanceOverview` `:170` | GET `/finance/overview` | ✅ `main.go:148` | finance | ❌ **ROUTE YOK → 404** (`finance/main.go:37-57`; gerçek: `/assessments/overview` `:46`) | — | ❌ hiç çağrılmıyor |
| 17 | `getAssessments` `:175` | GET `/finance/assessments` | ✅ | finance | ✅ `finance/main.go:45` | **GERÇEK DB** (`repository/finance.go:86`) ⚠️ **rol kontrolü yok** | ❌ hiç çağrılmıyor |
| 18 | `createAssessment` `:183` | POST `/finance/assessments` | ✅ | finance | ✅ `:47` | **GERÇEK DB** (`repository/finance.go:399`) | ❌ **hiç çağrılmıyor** (ekran sahte) |
| 19 | `getPayments` `:187` | GET `/finance/payments` | ✅ | finance | ✅ `:53` | **GERÇEK DB** (`repository/finance.go:227,293`) | ❌ hiç çağrılmıyor |
| 20 | `getExpenseCategories` `:195` | GET `/finance/expense-categories` | ✅ | finance | ✅ `:49` | **GERÇEK DB** (`repository/finance.go:548`) | ❌ hiç çağrılmıyor |
| 21 | `sendPaymentReminder` `:200` | POST `/notifications/send` | ✅ `main.go:157` | notification | ✅ `notification/main.go:44` | **MOCK** — yalnızca `log.Printf`, gönderim yok (`:73-98`) | ❌ hiç çağrılmıyor |
| 22 | `getMeters` `:211` | GET `/meters` | ✅ `main.go:154` | iot | ✅ `iot/main.go:23` | **MOCK** (2 literal sayaç, `:63-89`) | ❌ hiç çağrılmıyor |
| 23 | `submitMeterReading` `:216` | POST `/meters/{id}/readings` | ✅ | iot | ✅ `:25` | **MOCK** — yazımı atar, sabit `consumption:12.5` (`:100-118`) | ❌ hiç çağrılmıyor |
| 24 | `submitBulkReadings` `:220` | POST `/meters/bulk-readings` | ✅ | iot | ❌ **ROUTE YOK → 404** (`iot/main.go:21-28`) | — | ❌ hiç çağrılmıyor |
| 25 | `getAnnouncements` `:226` | GET `/announcements` | ✅ `main.go:151` | community | ✅ `community/main.go:48` | **MOCK** (1 literal, `:98-115`) | ❌ hiç çağrılmıyor |
| 26 | `createAnnouncement` `:231` | POST `/announcements` | ✅ | community | ✅ `:50` | **MOCK** — `{"id":"ann-new"}` döner, yazmaz (`:121-134`) | ❌ **hiç çağrılmıyor** (ekran sahte) |
| 27 | `updateAnnouncement` `:235` | PUT `/announcements/{id}` | ✅ | community | ✅ `:51` | **MOCK** (`:136-138`) | ❌ hiç çağrılmıyor |
| 28 | `deleteAnnouncement` `:239` | DELETE `/announcements/{id}` | ✅ | community | ✅ `:52` | **MOCK** (`:140-142`) | ❌ hiç çağrılmıyor |
| 29 | `getRequests` `:245` | GET `/requests` | ✅ `main.go:151` | community | ✅ `community/main.go:39` | **GERÇEK DB** (`repository/request.go:48,60`) | ❌ hiç çağrılmıyor |
| 30 | `getRequest` `:250` | GET `/requests/{id}` | ✅ | community | ❌ **ROUTE YOK → 404** (`community/main.go:36-43`; repo'da `GetByID` var `request.go:90` ama expose edilmemiş) | — | ❌ hiç çağrılmıyor |
| 31 | `updateRequestStatus` `:255` | PATCH `/requests/{id}/status` | ✅ | community | ✅ `:41` | **GERÇEK DB** (`repository/request.go:118`) | ✅ `request_detail_screen.dart:22` (`note` verilmeden) |
| 32 | `addRequestComment` `:262` | POST `/requests/{id}/comments` | ✅ | community | ❌ **ROUTE YOK → 404**; comment tablosu/repo'su yok | — | ❌ hiç çağrılmıyor |
| 33 | `generateReport` `:268` | POST `/reports/generate` | ⚠️ gateway'in **kendi** handler'ı, **AUTH YOK** | (yok) | — | **HARDCODED** (`cmd/gateway/main.go:305-398,338-374`). Yanıt `{"success":true,"data":{"report_id":...}}` → Flutter `data['download_url']` `:274` **her zaman null** | ❌ hiç çağrılmıyor |
| 34 | `getVehicles` `:278` | GET `/vehicles` | ✅ `main.go:193` | parking | ✅ `parking/main.go:127` | **MOCK** (`:174-212`) | ✅ `parking_management_screen.dart:37` |
| 35 | `createVehicle` `:283` | POST `/vehicles` | ✅ | parking | ✅ `:129` | **MOCK** — gövdeyi echo eder, yazmaz (`:236-262`) | ❌ hiç çağrılmıyor |
| 36 | `getParkingLogs` `:287` | GET `/parking-logs` | ✅ `main.go:193` | parking | ✅ `:150` | **MOCK** (`:367-392`) | ❌ hiç çağrılmıyor |
| 37 | `recognizePlate` `:292` | POST `/plate-recognition` | ✅ `main.go:193` | parking | ✅ `:159` | **MOCK** — gövdeyi **hiç okumaz**, sabit `"34 ABC 123"` (`:466-478`) | ❌ hiç çağrılmıyor |
| 38 | `getEmployees` `:298` | GET `/employees` | ✅ `main.go:199` | personnel | ✅ `personnel/main.go:69` | **MOCK** (3 literal, `:104-111`) | ✅ `personnel_management_screen.dart:31` |
| 39 | `createEmployee` `:303` | POST `/employees` | ✅ | personnel | ✅ `:72` | **MOCK** — gövdeyi hiç bind etmez (`:121-123`) | ❌ hiç çağrılmıyor |
| 40 | `getLeaves` `:307` | GET `/leaves` | ✅ `main.go:199` | personnel | ✅ `:88` | **MOCK** — **her zaman boş** `{"leaves":[]}` (`:157-159`) | ✅ `personnel_management_screen.dart:32` |
| 41 | `updateLeaveStatus` `:312` | PATCH `/leaves/{id}` | ✅ | personnel | ❌ **ROUTE YOK → 404/405** (gerçek: `POST /:id/approve\|/reject`, `personnel/main.go:86-93,172-178`) | — | ❌ hiç çağrılmıyor |
| 42 | `getVisitors` `:317` | GET `/visitors` | ✅ `main.go:214` | visitor | ✅ `visitor/main.go:95` | **MOCK** (`:134-168`) | ✅ `visitor_management_screen.dart:34` |
| 43 | `recordVisitorEntry` `:322` | POST `/visitors/{id}/entry` | ✅ | visitor | ❌ **ROUTE YOK → 404** (gerçek: `/checkin`, `visitor/main.go:106`) | — | ❌ hiç çağrılmıyor |
| 44 | `recordVisitorExit` `:326` | POST `/visitors/{id}/exit` | ✅ | visitor | ❌ **ROUTE YOK → 404** (gerçek: `/checkout`, `:107`) | — | ❌ hiç çağrılmıyor |
| 45 | `getPackages` `:331` | GET `/packages` | ✅ `main.go:190` | package | ✅ `package/main.go:107` | **MOCK** (3 literal, `:138-197`) | ✅ `package_tracking_screen.dart:31` |
| 46 | `getCarriers` `:336` | GET `/carriers` | ✅ `main.go:190` | package | ✅ `:103` | **MOCK** — sabit slice (`:72-84,134-136`) | ❌ hiç çağrılmıyor |
| 47 | `getUnitPackages` `:341` | GET `/units/{unitId}/packages` | ✅ özel dallanma `main.go:139-145` | package | ✅ `package/main.go:120` | **MOCK** — her zaman boş liste (`:337-344`) | ❌ hiç çağrılmıyor |
| 48 | `receivePackage` `:346` | POST `/packages` | ✅ | package | ✅ `:111` | **MOCK** — echo (`:259-285`) | ❌ hiç çağrılmıyor |
| 49 | `deliverPackage` `:350` | POST `/packages/{id}/deliver` | ✅ | package | ✅ `:115` | **MOCK** + `delivered_to_name` **zorunlu**, Flutter gövdesiz gönderiyor → **400** (`package/main.go:58,310-326`) | ❌ hiç çağrılmıyor |
| 50 | `getBankAccounts` `:355` | GET `/bank-accounts` | ✅ `main.go:217` | banking | ✅ `banking/main.go:143` | **MOCK** (`:183-222`) | ✅ `bank_integration_screen.dart:32` |
| 51 | `getBankTransactions` `:360` | GET `/bank-transactions` | ✅ `main.go:217` | banking | ✅ `:158` | **MOCK** (`:325-371`) | ✅ `:33` |
| 52 | `matchBankTransaction` `:365` | POST `/bank-transactions/{id}/match` | ✅ | banking | ✅ `:162` | **MOCK** + alan uyuşmazlığı: servis `transaction_id`+`payment_id` bekler, Flutter `assessment_id` yollar → **400** (`banking/main.go:87-91,444-459`) | ❌ hiç çağrılmıyor |
| 53 | `getFacilities` `:370` | GET `/facilities` | ✅ `main.go:202` | reservation | ✅ `reservation/main.go:110` | **MOCK** (4 literal, `:152-234`) | ✅ `reservation_management_screen.dart:30` |
| 54 | `getReservations` `:375` | GET `/reservations` | ✅ `main.go:202` | reservation | ✅ `:123` | **MOCK** (`:298-330`) | ✅ `:31` |

*(1–9 kimlik/yerel yardımcılar dahil 54 satır; bunlardan 34'ü public metot, 20'si yerel yardımcı/tekrarlı yol.)*

### Tablo özeti

| Ölçüt | Sayı |
|---|---|
| **Serviste ROUTE'U HİÇ OLMAYAN (→404)** | **8** — `/finance/overview`, `/meters/bulk-readings`, `/requests/{id}`, `/requests/{id}/comments`, `/leaves/{id}`, `/visitors/{id}/entry`, `/visitors/{id}/exit` *(+ `/reports/generate` auth'suz gateway mock)* |
| **Alan adı/zorunlu-alan uyuşmazlığından 400** | **2** — `deliverPackage`, `matchBankTransaction` |
| **Servisi HARDCODED MOCK** | **20** (parking×4, personnel×3, visitor×3, package×5, banking×3, reservation×2, iot×2, community-announcements×4, notification×1 — çakışanlar tekil sayıldı) |
| **Servisi GERÇEK DB** | **13** (auth×3, kvkk, residents×4, units, finance×4, requests×2 — bkz. tablo) |
| **Gateway'in kendi hardcoded handler'ı** | **2** — `/dashboard/stats`, `/reports/generate` |
| **`api_client.dart`'ta tanımlı ama ekranda HİÇ ÇAĞRILMAYAN** | **21/34 metot** (%62) |
| **Yanıt zarfı uyuşmazlığı (`data['data']` sert cast / `List` beklerken `Map` gelir)** | `getAssessments`, `getPayments`, `getDashboard`, `generateReport` sert hata; `getVehicles`, `getParkingLogs`, `getEmployees`, `getLeaves`, `getVisitors`, `getPackages`, `getCarriers`, `getUnitPackages`, `getBankAccounts`, `getBankTransactions`, `getReservations` → `?? response.data` fallback'i **Map** döndürür, `List<dynamic>` cast'i **runtime TypeError**. Yalnızca `getFacilities` (`api_client.dart:372`) `['facilities']`'i doğru okuyor. |

**Not — sessiz mock fallback var mı?** Hayır, kodda "API başarısızsa mock listeye düş" deseni **yok**. Onun yerine daha kötüsü var: `catch (_) { setState(() => _isLoading = false); }` (`parking:53-55`, `personnel:57-59`, `visitors:48-50`, `packages`, `banking:67-69`, `reservations:54-56`) → hata **tamamen yutulur**, ekran **boş** kalır, kullanıcıya hiçbir açıklama/yeniden dene sunulmaz. Yukarıdaki cast hataları da bu bloğa düşer → 6 ekran her zaman boş görünür.

---

## 4. DERLENEBİLİRLİK RİSKLERİ

> `flutter analyze` / `flutter build` çalıştırılmadı (Flutter kurulu değil). Aşağıdakiler kod okumasına dayalıdır.

| # | Risk | Şiddet | Kanıt |
|---|---|---|---|
| 1 | **`test/` derlenmiyor** — `MyApp` sınıfı yok | 🔴 KESİN HATA | `test/widget_test.dart:16` `const MyApp()` ↔ `main.dart:21` `SiteEksenAdminApp`. `flutter test` başarısız. |
| 2 | **iOS derlemesi imkânsız** — `ios/` dizini yok | 🔴 KESİN | `Test-Path admin_app\ios` → `False` |
| 3 | **Release imzalama debug anahtarıyla** + `com.example.*` applicationId | 🔴 Yayınlanamaz | `android/app/build.gradle.kts:23-24,35-37` |
| 4 | Codegen (`*.g.dart`/`*.freezed.dart`) eksikliği | 🟢 **RİSK YOK** | 0 `part` direktifi, `freezed`/`json_serializable` pubspec'te yok. `lib/` bu nedenle derlenir. |
| 5 | `intl: any` — pin'siz sürüm | 🟡 | `pubspec.yaml:46` |
| 6 | 16 kullanılmayan bağımlılık (uyarı + APK şişmesi + gereksiz izin merge'i) | 🟡 | bkz. İddia 11c |
| 7 | Kullanılmayan import `dart:io` | 🟡 analyzer uyarısı | `add_expense_screen.dart:1` |
| 8 | Kullanılmayan alan `_selectedMonth` | 🟡 | `expenses_screen.dart:13` |
| 9 | Ölü dosya `resident_expenses_screen.dart` (359 satır, route'suz) | 🟡 | `app_router.dart:1-41` import listesinde yok |
| 10 | `dispose()` eksikleri (TabController/TextEditingController) | 🟡 runtime leak | `meters_screen.dart:12-19`, `requests_screen.dart:22-26`, `request_detail_screen.dart:17` |
| 11 | `setState` sonrası `mounted` kontrolü yok (async) | 🟡 "setState after dispose" çökme riski | `parking:38,54`, `personnel:33,58`, `visitors:35,49`, `packages:31+`, `banking:34,68`, `reservations:32,55`; `api_settings_screen.dart:550-552` (`Navigator.pop(context)` await sonrası, `mounted` yok) |
| 12 | Runtime tip hatası riski — `List<dynamic>` cast'i `Map` üzerinde | 🔴 runtime (derleme değil) | bkz. bölüm 3 zarf uyuşmazlığı tablosu |
| 13 | `Color(int.parse(a['color'].replaceAll('#','0xFF')))` — null/format hatası | 🟡 runtime, sessizce yutulur | `bank_integration_screen.dart:45` |
| 14 | `firebase_core` var, `google-services.json`/gradle plugin yok → Firebase init runtime'da başarısız (try/catch'te yutulur) | 🟡 | `main.dart:12-16`; `build.gradle.kts:1-6` |

**Genel derlenebilirlik verdict'i:** `lib/` **muhtemelen derlenir** (codegen engeli yok). `test/` **kesin derlenmez**. `ios` hedefi **yok**. Release Android **imzalanamaz/yayınlanamaz**.

---

## 5. Mantık Hataları ve Eksiklikler

### 5.1 Sahte başarı bildirimleri (en yıkıcı sınıf)
Yönetici bir işlem yaptığını sanıp yapmıyor. **8 ayrı yerde**:

| Ekran | Satır | Gösterilen mesaj | Gerçekte |
|---|---|---|---|
| Tahakkuk Oluştur | `create_assessment_screen.dart:148-150` | "Tahakkuk oluşturuldu" ✅yeşil | hiçbir yere yazılmadı |
| Sayaç Okuma | `meter_reading_screen.dart:137-139` | "Okumalar kaydedildi" | yazılmadı |
| Duyuru Yayınla | `create_announcement_screen.dart:141-143` | "Duyuru yayınlandı" | yazılmadı, push gitmedi |
| Gider Ekle | `add_expense_screen.dart:441-446` | "Gider eklendi" | `// TODO: API call` |
| Raporlar | `reports_screen.dart:145-155` | "Rapor indirildi" + "Aç" | dosya yok |
| Talep yorumu | `request_detail_screen.dart:171-173` | "Yorum eklendi" | yazılmadı |
| API Ayarları kaydet | `api_settings_screen.dart:847-852` | "API başarıyla eklendi" | yazılmadı |
| API bağlantı testi | `api_settings_screen.dart:554-565` | "Bağlantı başarılı (245ms)" | test yapılmadı |
| Sözleşme belge sil | `contract_management_screen.dart:822` | "Belge silindi" | listeden **bile** silinmedi |
| Banka senkron | `bank_integration_screen.dart:499-503` | (spinner 2 sn) | senkron yok |
| AI fatura tarama | `add_expense_screen.dart:395-413` | "%94 güven" sonuç | sabit metin |

**Bu, para ve hukuki sorumluluk taşıyan bir yönetici uygulamasında en kritik hata sınıfıdır**: yönetici "Şubat tahakkuku oluşturuldu" mesajını görüp işlemi tamamlanmış sayar; sakinlere borç yazılmaz, ay kapanır.

### 5.2 Yıkıcı işlemlerde onay / geri alma / audit
| Gereksinim | Durum |
|---|---|
| Sakin silme | ❌ **Ekran yok** — silme özelliği hiç yok (yalnızca aktif/pasif, `resident_detail_screen.dart:87`). `api_client.dart`'ta `deleteResident` yok. Web panelde soft-delete var (`tasks/changelog.md:54`), mobilde yok. |
| Sakin pasifleştirme onayı | ❌ **Onay diyaloğu YOK** — `PopupMenuButton` `:86-88` doğrudan `_setActive(!isActive)` çağırıyor. Yanlış dokunuşla sakin pasifleşir. |
| Tahakkuk oluşturma onayı | ❌ Onay yok, önizleme yok, **geri alma yok** (`create_assessment_screen.dart:125-128` doğrudan buton) |
| Tahakkuk geri alma | ❌ hiç yok (`api_client.dart`'ta `deleteAssessment`/`reverseAssessment` yok) |
| Ödeme kaydı | ❌ **Ekran yok** — `payments_screen.dart` salt görüntüleme; ödeme girme/iptal/iade akışı hiç yok, `api_client.dart`'ta `createPayment`/`refundPayment` yok |
| Sayaç okuma onayı | ✅ diyalog var (`meter_reading_screen.dart:127-146`) ama arkasında işlem yok |
| Duyuru silme onayı | ❌ `onSelected` bile yok (`announcements_screen.dart:44-51`) |
| Client-side audit/log | ❌ hiç yok. Backend'de `AuditLog()` middleware'i **yalnızca** identity + finance route gruplarına bağlı (`tasks/roadmap.md:54`); mobil uygulamanın çağırdığı diğer 10 servis auth'suz ve audit'siz. |
| Undo/rollback deseni | ❌ hiçbir ekranda yok (Grep: `Undo`/`Geri Al` → 0) |
| İki-adımlı doğrulama (yüksek riskli işlem) | ❌ hiç yok |

### 5.3 Yetkilendirme
- **Aksiyon seviyesinde client kontrolü: SIFIR.** `_roles`/`getCurrentUserRoles` yalnızca `main_screen.dart`'ta (menü). Hiçbir buton/form rol'e göre gizlenmiyor veya devre dışı bırakılmıyor.
- Menü gizleme **fail-open** (`main_screen.dart:55,233`) — token yok/bozuk = tam yetki görünümü.
- Menüde gizlenen ekranlar **route ile hâlâ erişilebilir** (`app_router.dart:296-303` guard yok) → STAFF `/finance` yazabilir mi? Yazma denemesi backend'de 403 alır (`finance/service/finance.go:85,102,111,163` ✅) ama **`GET /finance/assessments` ve `/finance/debt-status` rol kontrolü içermiyor** → STAFF/sakin tüm mali veriyi okur.
- **Raporlar tamamen açık:** `POST /api/v1/reports/generate` gateway içinde, JWT doğrulaması yok (`cmd/gateway/main.go:422`).
- Yönetici kimliği/rolü **UI'da hiç gösterilmiyor** — drawer header sabit "Yönetici Paneli / Mavi Kent Sitesi" (`main_screen.dart:134,142`). Kim olarak giriş yapıldığı belirsiz.
- Çoklu site (property) desteği yok — JWT'de `property_id` claim'i var (`identity/service/auth.go:145`) ama uygulama hiç okumuyor/değiştirmiyor.

### 5.4 Hata / loading / empty state
| Ekran grubu | Loading | Hata | Empty | Retry | Pull-to-refresh |
|---|---|---|---|---|---|
| Sakinler (3 ekran) | ✅ `residents_screen.dart:108` | ✅ SnackBar `:46-48` | ✅ `:113` | ⚠️ yalnızca pull-to-refresh | ✅ `:67` |
| Parking/Personnel/Visitors/Packages/Banking/Reservations | ✅ spinner | ❌ **sessizce yutulur** (`catch (_)`) | ⚠️ boş liste, mesaj yok | ❌ | ❌ |
| Talep Detay | ⚠️ yalnızca yazma sırasında | ✅ yazma hatası | — | ❌ | ❌ |
| 16 mock ekran | ❌ gereksiz | ❌ | ❌ | ❌ | ❌ |
| Dashboard | `RefreshIndicator` var ama **boş** (`:21-23`) | — | — | — | sahte |

- **Offline yok:** `connectivity_plus` bağımlı ama hiç import edilmemiş. Ağ yoksa Dio 30 sn timeout (`api_client.dart:16-17`), sonra sessiz boş ekran. Offline cache/kuyruk yok.
- **Token süresi:** access token 15 dk (`tasks/changelog.md:172`). Interceptor 401'de refresh deniyor (`api_client.dart:29-38`) ✅. Ancak: refresh başarısızsa **`/login`'e yönlendirme yok** (`:36-37` sadece hatayı yayar) → kullanıcı 7 gün sonra "yüklenemedi" hatalarıyla kilitli kalır, ne olduğunu anlamaz. Eşzamanlılık kilidi yok. Yeni refresh token kaydedilmiyor (`:53`).
- Oturum süresi/inaktivite kilidi yok. Ekran görüntüsü engelleme (`FLAG_SECURE`) yok — mali veri gösteren bir uygulamada beklenir.

### 5.5 Para / tarih / timezone / pagination
- **`intl` HİÇ KULLANILMIYOR** (bkz. İddia 11c). Sonuç:
  - Para: `'₺${amount.toInt()}'` (`finance_screen.dart:178,217`, `dashboard_screen.dart:60`), `'₺${expense.amount.toStringAsFixed(2)}'` (`expenses_screen.dart:248`) → **binlik ayırıcı yok** (`₺105400`), **locale yok**, kuruş tutarsız (bazen `toInt()` ile **kuruş kaybı**), sembol konumu TR standardına aykırı (`105.400,00 ₺` olmalı).
  - `bank_integration_screen.dart:492-497` elle regex ile binlik ayırıcı ekliyor ama **ondalık ayırıcıyı `.` bırakıyor** → `12.450.00` gibi bozuk çıktı (TR'de `12.450,00`).
  - Hardcoded metinlerde tutarsız: `'₺45,780'` (`dashboard_screen.dart:59`, virgüllü/US) vs `'₺105,400'` (`finance_screen.dart:39`) vs `₺${...toInt()}` (ayırıcısız).
  - `double` ile para hesabı (`create_assessment_screen.dart:22` `fold`, `:118` `/124`) → **kayan nokta yuvarlama hatası**; para `int` kuruş veya `Decimal` olmalı.
- **Tarih:** tüm tarihler ya hardcoded string (`'01.02.2026'`) ya elle birleştirme: `add_expense_screen.dart:122` `'${_expenseDate.day}.${_expenseDate.month}.${_expenseDate.year}'` → **sıfır dolgusu yok** (`1.2.2026`). `DateFormat` hiç yok.
- **Timezone:** hiç ele alınmamış. `DateTime.now()` (`add_expense_screen.dart:22`, `reservation_management_screen.dart:16`) yerel saat; UTC/TR dönüşümü, `toIso8601String()` kullanımı yok. Backend'e tarih gönderen tek yer yok (yazma yok), ama okunan tarihler ham string olarak gösteriliyor → parse/format edilmiyor.
- **Yerelleştirme:** `MaterialApp.router`'da `localizationsDelegates`/`supportedLocales` **yok** (`main.dart:28-35`) → `showDatePicker` (`add_expense_screen.dart:125`) **İngilizce** açılır, hafta başı Pazar olur.
- **Pagination:** `api_client.dart:187` `getPayments({int page = 1})` — tek metotta `page` var, **o metot hiç çağrılmıyor**. `getResidents` `:139`, `getRequests` `:245`, `getMeters` `:211`, `getVisitors`, `getVehicles`, `getPackages`, `getEmployees` → **hiçbirinde page/limit yok**. `residents_screen.dart:116-126` `ListView.builder` tüm listeyi tek seferde çeker. 124+ sakin, binlerce banka hareketi için ölçeklenemez; sonsuz kaydırma/sayfalama yok.
- **Arama/filtre sunucu tarafı mı?** Sakinler'de ✅ (`residents_screen.dart:34-37` → query param). Diğer tüm ekranlarda client-side ve çoğu **hiç uygulanmıyor** (`expenses_screen.dart:112`, `parking_management_screen.dart:163` `onChanged: (value) => setState(() {})` — arama metni hiçbir yerde kullanılmıyor).

### 5.6 Diğer mantık hataları
1. **Logout token silmiyor** (`main_screen.dart:209-216`) — 5.2/İddia 5.
2. **Biyometrik KVKK'yı atlar** (`login_screen.dart:126-129`) — İddia 6.
3. **`_selectedIndex` route ile senkron değil** — drawer'dan gidilince alt bar yanlış sekmeyi gösterir (`main_screen.dart:59-62` vs `:151-197` `context.go`).
4. **`_canSee`/`isVisibleFor` mükerrer mantık** (`main_screen.dart:54-57` ve `:231-235`) — biri drawer, biri alt bar için; ikisi de fail-open, ayrı ayrı bakım gerektirir.
5. **Şifremi Unuttum ölü** (`login_screen.dart:286-291` `// TODO`) — şifresini unutan yönetici kilitli kalır.
6. **`login_screen.dart:124`** `if (!authenticated) return;` — `finally` bloğu `_isLoading`'i sıfırlıyor ✅, ama kullanıcıya neden başarısız olduğu söylenmiyor.
7. **`api_settings_screen.dart:246,254`** `_tabController.index` doğrudan okunuyor ama `TabController`'a listener eklenmemiş → **sekme değiştirince liste güncellenmez** (yeniden çizim tetiklenmiyor).
8. **`api_settings_screen.dart:520-522`** 30 sn sonra `Navigator.of(context, rootNavigator: true).pop()` — kullanıcı diyaloğu kapatıp başka bir sayfaya gitmişse **yanlış route'u kapatır**.
9. **`expenses_screen.dart:64`** `color: Colors.white` sabit — karanlık tema (`main.dart:32-33` `darkTheme` + `ThemeMode.system`) altında okunamaz. Aynı sorun `apple_theme` kullanan 15 ekranda: `Colors.white` sabitleri (`parking:70,83`, `visitors:79`, `api_settings:217` vb.) → **karanlık modda kırılıyor**.
10. **`request_detail_screen.dart:15`** `_status = 'OPEN'` sabit başlangıç — gerçek durum okunmadığı için RESOLVED bir talep açılıp "Güncelle"ye basılırsa **OPEN'a geri düşürülür** (veri kaybı).
11. **`create_assessment_screen.dart:118`** `_totalAmount / 124` — daire sayısı **kod içinde sabit**; gerçek daire sayısı API'den alınmıyor (`getUnits` var ama çağrılmıyor). Yanlış aidat hesabı.
12. **`_ExpenseItemCard`** (`create_assessment_screen.dart:180,188`) `initialValue` kullanıyor ama `TextEditingController` yok → liste yeniden çizildiğinde girilen değerler **kaybolur/karışır** (`Key` de verilmemiş, `:86` `remove(item)` sonrası kalan alanlar yanlış değer gösterir).

### 5.7 Test
- `test/` klasöründe **tek dosya**: `test/widget_test.dart` (30 satır) — Flutter varsayılan **sayaç şablonu**, uygulamayla ilgisiz, **derlenmiyor** (`MyApp` yok).
- **Gerçek test sayısı: 0.** Widget testi, birim testi, `api_client` testi, altın (golden) test, integration test yok.
- CI: `.github/` repo kökünde var; `admin_app` için Flutter analyze/test adımı olup olmadığı **doğrulanmadı: bu denetimin kapsamı `admin_app/` ile sınırlıydı.**

---

## 6. Ekran Bazlı Eksik Tamamlayıcı Özellikler

| Ekran | Olması gerekip OLMAYAN |
|---|---|
| **Login** | Şifremi unuttum (`:288` TODO), hesap kilitleme/rate-limit geri bildirimi, telefon formatı maskesi/validasyonu (yalnızca `isEmpty` — `:225-230`), 2FA/OTP, "beni hatırla", cihaz kaydı, oturum listesi/uzaktan çıkış |
| **KVKK** | Rıza geri alma (withdraw), rıza sürüm/tarih gösterimi, PDF olarak indirme, aydınlatma metnini sunucudan sürümlü çekme, m.11 haklarına uygulama içi başvuru formu |
| **Dashboard** | Gerçek veri (`getDashboard()` çağrısı), dönem seçici, tahsilat oranı trendi, kritik uyarı merkezi (vadesi geçen/bekleyen onay), bildirim listesi (`:14-17` ölü zil ikonu), grafik (fl_chart bağımlı ama kullanılmıyor) |
| **Sakinler** | Pagination/sonsuz kaydırma, sakin silme/soft-delete, düzenleme formu (yalnızca aktif/pasif), **bakiye/borç sütunu** (ROADMAP `:70` kabul ediyor), blok/kat filtresi (API destekliyor `getResidents(block:)` ama UI'da yok), CSV içe/dışa aktarma (web panelde var — `tasks/changelog.md:56`), sakine doğrudan arama/SMS/WhatsApp, kiracı-malik ilişkisi ve vekalet kaydı, birden fazla daire sahipliği, TCKN/iletişim doğrulama, sakin bazlı talep/ödeme geçmişi sekmesi |
| **Finans** | Gerçek veri, dönem seçici (`:28` ölü), dışa aktarma (`:14` ölü), "Borçlular tümünü gör" (`:116` ölü), gelir-gider mizanı, kasa/banka bakiyesi mutabakatı, işletme projesi (bütçe) vs gerçekleşen, KDV/stopaj, gecikme faizi hesabı (KMK m.20 aylık %5), demirbaş/işletme fonu ayrımı |
| **Tahakkuk Oluştur** | **Önizleme** (daire başına dağıtım tablosu — hesap `:118` sabit 124 daireye bölme), **geri alma/iptal**, dağıtım şekli seçimi (arsa payı / m² / eşit — `add_expense_screen.dart:203-211`'de var ama tahakkukta yok), gider kalemlerini API'den çekme (`getExpenseCategories()` var, çağrılmıyor), mükerrer dönem kontrolü, taslak kaydetme, onay akışı, son ödeme tarihi, sakinlere bildirim, oluşturulmuş tahakkuk listesi/düzenleme |
| **Ödemeler** | Gerçek veri, **manuel ödemekaydı** (nakit/havale), kısmi ödeme, ödeme iptali/iadesi, makbuz üretme/paylaşma, tahakkukla eşleştirme, filtre (`:13` ölü), dışa aktarma (`:14` ölü), pagination |
| **Sayaçlar** | Gerçek veri, sayaç ekle/düzenle/sil, arıza/sıfırlama kaydı, **tüketim anomali uyarısı**, önceki okumadan küçük değer validasyonu, dönem kilidi, dışa aktarma (`:35` ölü), fotoğraflı okuma kanıtı, sayaç değişimi (endeks devri) |
| **Sayaç Okuma** | Gerçek kaydetme, **negatif/geriye tüketim validasyonu** (hiç yok), toplu içe aktarma (CSV), kaldığı yerden devam (taslak), okuma yapılmayan daire raporu, otomatik tahakkuka aktarma |
| **Duyurular** | Gerçek veri, **düzenle/sabitle/sil işlevi** (`:44-51` `onSelected` yok), hedef kitle (blok/kat/rol), zamanlanmış yayın, okundu bilgisi (`:65` "85 görüntüleme" sahte), ek dosya, arşiv, taslak |
| **Duyuru Yayınla** | Gerçek yayınlama, kategori seçiminin çalışması (`:68` `onChanged: (_) {}`), dosya ekleme (`:96` ölü), hedef kitle seçimi, zamanlama, taslak kaydetme, karakter sayacı, zengin metin |
| **Talepler** | Gerçek liste, **gerçek sekme sayıları** (`:36-38` metne gömülü), atanan kişiye göre filtre, öncelik/kategori filtresi, SLA/gecikme göstergesi, arama, pagination, "bana atanan" görünümü |
| **Talep Detay** | **Gerçek talep verisi** (`getRequest()` çağrılmıyor — en kritik), fotoğraf/ek görüntüleme, gerçek yorum ekleme, **görevli atama** (`:47` ölü), **öncelik değiştirme** (`:48` ölü), durum geçmişi/zaman çizelgesi, maliyet/iş emri kaydı, sakin onay durumu göstergesi, tekrar açma |
| **Raporlar** | **Gerçek rapor üretimi + indirme** (`open_file`/`path_provider` bağımlı ama kullanılmıyor), dönem aralığı seçimi (`:20` ölü), rapor geçmişi, e-posta ile gönderme, işletme defteri/kesin hesap, denetim raporu, KMK uyumlu yıllık faaliyet raporu |
| **Gider Yönetimi** | Gerçek veri, **filtrelerin çalışması** (`:112`), ay seçici (`:129` TODO), dışa aktarma (`:46` ölü), gider onay akışı (`PENDING` durumu var ama onaylama yok), bütçe karşılaştırması, tedarikçi bazlı özet, mükerrer fatura kontrolü |
| **Gider Ekle (AI)** | **Gerçek OpenAI Vision/Document AI çağrısı**, **dosya/kamera seçimi** (`:386` stub; pubspec'te kamera paketi yok), gerçek kaydetme (`:440` TODO), AI sonucu düzeltme/onaylama iş akışı, KDV ayrıştırma alanı (AI `tax_amount` üretiyor `:408` ama forma yansımıyor), tedarikçi VKN, çoklu dosya, taslak, mükerrer fatura no kontrolü |
| **Gider Detay** | Gerçek veri, düzenle (`:34` ölü), kopyala/sil (`:35-40` `onSelected` yok), fatura görüntüleyici, dağıtım detayı (hangi daireye ne kadar), onay/red butonları, değişiklik geçmişi |
| **Ziyaretçi** | **Gerçek giriş/çıkış kaydı** (`:583,598` ölü — API metotları da backend'de yok), ziyaretçi kaydetme (`:690,746` ölü), sakine bildirim (`:613` ölü), QR/barkod okuma (`:96` ölü), kimlik/plaka kaydı ve KVKK aydınlatması, kara liste, süre aşımı uyarısı, daire listesinin API'den gelmesi (`:729` hardcoded), fotoğraf |
| **Otopark** | Araç ekleme/düzenleme/silme (`:133,275` ölü), **plaka tanıma** (`recognizePlate` çağrılmıyor), QR okuma (`:100` ölü), giriş/çıkış logu (`getParkingLogs` çağrılmıyor), **park alanı doluluğunun gerçek olması** (`:22-26` hardcoded), misafir aracı süre/ücret, ihlal/çekici kaydı, yer atama |
| **Rezervasyon** | **Onay/red/iptal aksiyonları (hiç yok)**, çakışma kontrolü, kota/limit (kişi başı aylık), ücretli tesis + tahakkuka yansıtma, takvim görünümü, tekrarlayan rezervasyon, no-show kaydı, bakım/kapalı gün |
| **Enerji Panosu** | Gerçek veri (hiç API yok), gerçek anomali tespiti, sayaç verisiyle bağ (`getMeters` ile ilişki yok), fatura karşılaştırması, hedef/tasarruf takibi, grafik (fl_chart), dönem karşılaştırma, CO₂/ESG bağlantısı |
| **Personel** | **İzin onayla/reddet** (`:340,348` ölü; API yolu da backend'de yok), personel ekleme/düzenleme/silme (`:131,225` ölü), **SGK/bordro** (maaş `:42` sadece gösteriliyor; puantaj, prim, kesinti, tahakkuk, e-bildirge yok), vardiya/mesai takibi, işe giriş-çıkış (giriş/çıkış saati), yıllık izin bakiyesi hesabı, sözleşme/belge dosyası, performans, maaş görünürlüğünün role bağlı olması (şu anda herkese açık) |
| **Envanter** | Gerçek veri, stok giriş/çıkış (`:89,183,217` ölü), kritik seviye uyarısı, satın alma talebi, sayım, tedarikçi, birim maliyet ve gidere aktarma |
| **Anket Yönetimi** | Gerçek veri, anket oluşturma/yayınlama/kapatma, **oy sayımı ve arsa payı ağırlıklı sonuç** (KMK), gizli oy, katılım oranı, sonuç yayınlama, karar defterine aktarma |
| **Koli Takibi** | Kargo kabul (`receivePackage` çağrılmıyor), **teslim etme** (`deliverPackage` çağrılmıyor; ayrıca gövde uyuşmazlığı → 400), sakine bildirim, imza/fotoğraf ile teslim kanıtı, dolap/raf yeri, bekleme süresi uyarısı, kurye listesi (`getCarriers` çağrılmıyor) |
| **Varlık (Demirbaş)** | Gerçek veri, demirbaş ekleme/düzenleme/elden çıkarma (`:89,178,334,342` ölü), **amortisman hesabı**, bakım planı/geçmişi, garanti takibi, QR/etiket, zimmet, sigorta, envanter sayımı |
| **Sözleşme** | Gerçek veri, **dosya yükleme** (`:676` TODO), PDF görüntüleme/indirme (`:732,734,796,798` ölü), gerçek silme (`:822` sahte), **yenileme/bitiş tarihi uyarısı**, otomatik yenileme, teminat/kefalet, fesih bildirimi, sürüm/ek protokol takibi, KVKK saklama süresi |
| **Güvenlik Turu** | Gerçek veri, **NFC/QR checkpoint okuma** (`:82,187` ölü), tur planı/vardiya atama, kaçırılan checkpoint alarmı, olay/tutanak kaydı, fotoğraf, GPS doğrulama, tur raporu |
| **Toplantı Sihirbazı** | Gerçek veri, davet/tebligat gönderimi (`:367,452` ölü), **yeter sayı (nisap) hesabı** (KMK m.30: 1. toplantı salt çoğunluk, 2. toplantı 1/3 — kod yok), **vekalet (temsil) yönetimi** (KMK m.31 sınırı: yönetici en fazla ⅕ + 40 daireden fazlasında %5), arsa payı ağırlıklı oylama, gündem maddesi bazlı oylama, **karar defteri/tutanak üretimi ve imza**, hazirun cetveli, çağrı süresi (15 gün) kontrolü |
| **Akıllı Tahsilat** | Gerçek veri, gerçek hatırlatma gönderimi (`:238,270,475,483,494` ölü; `sendPaymentReminder` API'si var ama çağrılmıyor), **ihtarname (noter) takibi**, **icra takibi** (dosya no, durum, avukat, masraf), taksitlendirme/ödeme sözü, gecikme faizi hesabı, risk skorunun gerçek modele bağlanması, tahsilat kampanyası/otomasyon, iletişim geçmişi kaydı |
| **İlan Panosu** | Gerçek veri, yayınlama (`:403` ölü), moderasyon/onay-red (`:563,598,606` ölü), şikayet/kaldırma, süre bitimi, fotoğraf yükleme, iletişim maskeleme (KVKK) |
| **Banka Entegrasyonu** | Gerçek senkronizasyon (`:499-503` sahte), **mutabakat/eşleştirme** (`matchBankTransaction` çağrılmıyor; alan uyuşmazlığı → 400), gerçek istatistikler (`:72-77` hardcoded), banka hesabı ekleme (`:532-541` sabit liste), açıklama/IBAN'dan otomatik daire tespiti (backend `confidence` üretiyor, UI kullanmıyor), manuel eşleştirme düzeltme, ekstre içe aktarma (MT940/CSV), eşleşmeyen hareket raporu |
| **API Ayarları** | **Her şey** — gerçek CRUD (`:838` sahte), gerçek bağlantı testi (`:532` sahte), gerçek audit log (`:594-598` sahte), sunucu tarafı şifreli saklama (banner `:191-192` bunu **yanlış** iddia ediyor), rol kısıtı (API anahtarı yönetimi yalnızca en üst yetkiye açık olmalı — hiç kontrol yok), anahtar rotasyonu, sabit `sk-...` demo dizesinin kaldırılması (`:492,498`) |
| **Genel (tüm ekranlar)** | Rol bazlı buton kontrolü, offline mod, pagination, `intl` ile para/tarih, karanlık tema uyumu, boş/hata durumu, retry, arama, dışa aktarma, bildirim merkezi, çoklu site seçimi, profil/ayarlar ekranı (**yok** — ROADMAP `:120` "Profil/Ayarlar ✅" diyor ama `admin_app`'te profil ekranı **hiç yok**), Belge Yönetimi/NPS/ESG (ROADMAP dürüstçe 📋 diyor ✅) |

---

## 7. İddia Doğrulama Özeti

| # | İddia | Verdict |
|---|---|---|
| 1 | 24 (aslında 25) ekran gerçekten var, içi dolu | ⚠️ **KISMEN** — 25/25 dosya var, hiçbiri "yakında" placeholder değil; ama 16'sı hiç ağ kodu içermiyor ve 17'si menüden erişilemiyor |
| 2 | Veri kaynakları | ⚠️ 3 gerçek / 6 "bağlı ama servis mock" / 16 tamamen mock. Yazma kalıcı olan yalnızca **5 aksiyon** |
| 3 | `api_client.dart` ↔ backend eşleşmesi | ❌ **8 yol serviste yok (404), 2'si 400, 20'si mock servis, 21/34 metot hiç çağrılmıyor, tüm baseUrl prefix'i yanlış** |
| 4 | Sakinler gerçek API + `/residents` + PATCH | ✅ **DOĞRU** |
| 5 | Biyometrik giriş | ⚠️ **KISMEN** — kod var, `FlutterActivity` nedeniyle Android'de çalışmaz; logout token silmiyor; secure storage sertleştirilmemiş |
| 6 | KVKK geçilemez `PopScope` | ⚠️ **KISMEN** — `PopScope` var, biyometrik giriş ve router guard eksikliği nedeniyle **atlanabilir** |
| 7 | Android geri tuşu `PopScope` | ✅ **DOĞRU** (küçük senkron kusuru) |
| 8 | RBAC, AUDITOR/STAFF görmüyor | ❌ **YANLIŞ** — AUDITOR izinli (yalnızca STAFF gizli); fail-open; aksiyon kontrolü yok; raporlar auth'suz |
| 9 | AI fatura tarama | ❌ **YANLIŞ** — `Future.delayed` + sabit sonuç; dosya seçimi stub; gerçek API key gömülü değil ama yanıltıcı güvenlik beyanı ve sahte `sk-` dizesi var |
| 10 | Talep RESOLVED notu + gerçek çağrı | ⚠️ **KISMEN** — banner ve `PATCH` gerçek; **`note` gönderilmiyor**, ekranın geri kalanı sahte, yanlış talep güncellenebilir |
| 11 | Codegen eksik → derlenmez? | ❌ **HAYIR (iddia edilen risk yok)** — codegen kullanılmıyor, `lib/` derlenir. **AMA `test/` kesin derlenmez** (`MyApp` yok) ve 16 bağımlılık ölü |
| 12 | Platform yapılandırması | ❌ **CİDDİ EKSİK** — `ios/` yok, `google-services.json` yok, main manifest'te **hiç izin yok**, release debug anahtarıyla imzalı, `com.example.*` |
| 13 | Riverpod + go_router | ❌ **YANLIŞ** — Riverpod yalnızca router provider'ı için; 43 ekranın tamamı `setState`. Route'lar var ama **auth guard yok** |

**YANLIŞ/YANILTICI çıkan iddia: 6** (3, 8, 9, 11-premis, 12, 13) · **KISMEN doğru: 5** (1, 2, 5, 6, 10) · **DOĞRU: 2** (4, 7)
