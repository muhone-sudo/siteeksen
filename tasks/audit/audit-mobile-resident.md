# Sakin Mobil Uygulama Denetimi (mobile/)

Denetim tarihi: 2026-09-08
Kapsam: `C:\Users\md064615\Documents\Projeler\proje99\mobile\`
Yöntem: Statik kod okuma (Read/Grep/Glob + PowerShell). `flutter analyze` / `flutter test` ÇALIŞTIRILMADI (Flutter kurulu değil). Hiçbir dosya değiştirilmedi.

Denetlenen kod hacmi: 26 Dart dosyası, ~7.000 satır (`mobile/lib`), + `mobile/android`, `mobile/pubspec.yaml`, `mobile/test`.

---

## 0. Özet Skor Tablosu

| Ölçüt | Sonuç |
|---|---|
| ROADMAP'te "✅" işaretli sakin ekranı | 13 |
| Dosyası GERÇEKTEN var olan ekran | 13/13 (dosya var) |
| İçinde HİÇ API çağrısı olmayan (%100 hardcoded mock) ekran | **8/13** |
| Gerçek API okuması yapan ekran | 5/13 (Duyurular, Koli, Rezervasyon, Anketler, İlan Panosu) |
| Bu 5 ekrandan backend'de yolu OLMAYAN (404) | 2 (İlan Panosu okuma+yazma, Anket oylama) |
| Router'da tanımlı ama UI'dan ULAŞILAMAYAN route | **12/18** |
| `api_client.dart` metot sayısı | 24 (public), bunların **15'i hiç çağrılmıyor** |
| Backend'de karşılığı olmayan api_client yolu | 3 (`GET/POST /bulletins`, `POST /surveys/{id}/responses`) |
| Test | 1 dosya, ve o dosya **derlenmez** (`MyApp` yok) |
| `ios/` klasörü | **YOK** |
| Release APK'da INTERNET izni | **YOK** |

---

## 1. Ekran Gerçeklik Tablosu

| Ekran | Dosya | Veri kaynağı | Mock fallback? | Yazma gerçek? | GERÇEK DURUM |
|---|---|---|---|---|---|
| Ana Sayfa | `lib/features/home/presentation/screens/resident_home_screen.dart` | **%100 hardcoded** (`_userData` L14-19, `_notifications` L21-36) | — (API yok) | ❌ yazma yok | **MOCK.** "Ahmet Yılmaz / D.105 / -1250.00 TL" sabit. `Aidat Öde` butonu `onPressed: () {}` (L125). 11 adet boş `onTap: () {}` — hiçbir hızlı işlem/servis kartı çalışmıyor. |
| Aidat/Ödeme (liste) | `lib/features/finance/presentation/screens/finance_screen.dart` | **%100 hardcoded** (`₺1.200,00` L27, 4 sabit `_AssessmentItem` L60-79) | — | ❌ | **MOCK.** `Öde` butonu `onPressed: () {}` (L38) — ödeme ekranına bile gitmiyor. |
| Aidat/Ödeme (ödeme) | `lib/features/finance/presentation/screens/dues_payment_screen.dart` | **%100 hardcoded** (`_duesInfo` L16-20, `_pendingDues` L22-26) | — | ❌ **SAHTE ÖDEME** | **KRİTİK MOCK.** Bkz. §2 İddia 8. |
| Talepler (liste) | `lib/features/requests/presentation/screens/requests_screen.dart` | **hardcoded** (aktif sekme her zaman boş L152-179; tamamlanan sekmede 1 sabit kayıt `id: 'mock-request-0089'` L140) | — | ⚠️ kısmen (`confirmRequestResolution` gerçek ama mock ID ile) | **MOCK.** `apiClient.getRequests()` HİÇ çağrılmıyor. Alt sayfadaki "Yeni Talep" formu sadece `Navigator.pop` yapıyor (L114-117); `TextFormField`'lara controller bağlı değil (L88-102) → girilen veri tamamen kayboluyor. |
| Talep oluşturma | `lib/features/requests/presentation/screens/create_request_screen.dart` | — | — | ❌ **SAHTE** | **MOCK.** `_submitRequest` (L273-313) hiç ağ çağrısı yapmadan "Talep Oluşturuldu! Takip numaranız: TLP-2026-042" (sabit) gösteriyor. `apiClient.createRequest()` hiç çağrılmıyor. Fotoğraf/Galeri/Dosya butonları `() {}` (L204-208); `_attachments` alanı (L18) hiç kullanılmıyor. |
| Duyurular | `lib/features/announcements/presentation/screens/announcements_screen.dart` | **GERÇEK API** `apiClient.getAnnouncements()` (L26) | ⚠️ mock değil ama **hata sessizce yutuluyor** → boş liste (L42-44) | ❌ okundu bilgisi yazılmıyor | **HİBRİT-OKUMA.** `Okundu` (L309-312) ve `Tümünü Oku` (L94) butonları sadece pop/no-op. Backend'de `POST /announcements/:id/read` VAR ama api_client'ta yok. |
| İlan Panosu | `lib/features/bulletin/presentation/screens/bulletin_board_mobile_screen.dart` | **GERÇEK API çağrısı** `getBulletins()` (L36) / `createBulletin()` (L350) | hata yutuluyor → boş (L54-56) | ⚠️ kod gerçek ama **yol 404** | **KIRIK.** Çağrılan `/bulletins` yolu gateway'de yok (§3). Ekran daima boş; "Paylaş" daima `Hata: ...`. |
| Enerji Tüketimi | `lib/features/energy/presentation/screens/energy_consumption_mobile_screen.dart` | **%100 hardcoded** (`_currentUsage` L16-20, `_monthlyTrend` L22-29) | — | ❌ | **MOCK.** `apiClient.getConsumptionSummary()` mevcut ama HİÇ çağrılmıyor. "%12 tasarruf" (L90) ve "Geçen aya göre ₺156.50 daha az" (L99) sabit metin. Hafta/Ay/Yıl seçicisi (L112-114) state değiştiriyor ama veriyi değiştirmiyor — ölü UI. |
| Koli Takibi | `lib/features/packages/presentation/screens/package_tracking_mobile_screen.dart` | **GERÇEK API** `getPackages()` (L26) | hata yutuluyor → boş (L45-47) | ❌ | **HİBRİT-OKUMA.** "Güvenliğe Haber Ver" (L377-382) sadece SnackBar — backend'de `POST /packages/:id/notify` VAR, çağrılmıyor. Takip no kopyalama butonu `() {}` (L409). Zaman çizelgesi ilk adımı ("Kargo yola çıktı") sabit uydurma (L364). |
| Rezervasyon | `lib/features/reservations/presentation/screens/create_reservation_screen.dart` | **GERÇEK API** `getFacilities()` (L41) + `createReservation()` (L345) | hata yutuluyor → "tesis bulunamadı" (L58-60) | ✅ **GERÇEK** | **GERÇEK (kısmi).** Ancak `_timeSlots` (L22-31) **hardcoded**: 11:00-12:00 ve 15:00-16:00 her tesis/her tarih için "dolu" görünür. Backend'de `GET /facilities/:id/availability` ve `/facilities/:id/slots` VAR, kullanılmıyor. `getReservations()` hiç çağrılmıyor → sakin kendi rezervasyonlarını göremiyor, iptal edemiyor. |
| Ziyaretçi Ön Kayıt | `lib/features/visitors/presentation/screens/visitor_preregister_screen.dart` | **API çağrısı YOK** | — | ❌ **SAHTE** | **MOCK.** `_submitPreRegister` (L261-301) hiç ağ çağrısı yapmadan "Ön Kayıt Oluşturuldu! ... QR kodlu giriş linki SMS olarak gönderildi" diyor. `apiClient.createVisitorPreRegistration()` mevcut, çağrılmıyor. |
| Anketler | `lib/features/surveys/presentation/screens/surveys_mobile_screen.dart` | **GERÇEK API** `getSurveys()` (L26) + `submitSurveyResponse()` (L421) | hata yutuluyor (L55-57) | ⚠️ kod gerçek ama **yol 404** | **KIRIK + ÇÖKÜYOR.** `survey['totalResidents']` (L163, L256) map'lemede (L39-51) hiç set edilmiyor → **API veri döndürdüğü an runtime çökme** (bkz. §4). Oylama yolu backend'de yok (§3). |
| Belgeler | `lib/features/documents/presentation/screens/documents_screen.dart` | **%100 hardcoded** (`_generalDocuments` L16-57, `_myDocuments` L60-81, `_uploadedDocuments` L84-118) | — | ❌ **SAHTE** | **MOCK (986 satır).** `api_client` import'u bile yok. "Belge Yükle" (L667-695) dosya seçici olmadan bellek içi map ekliyor, `fileType:'pdf'`/`fileSize:'1.2 MB'` sabit yazıyor; ekrandan çıkınca kaybolur. İndirme sadece "Belge indiriliyor..." SnackBar'ı (L593, L893). Backend'de `/api/v1/documents` servisi VAR ve gateway'de proxy'li — hiç kullanılmıyor. |
| Varlıklar (Demirbaş) | `lib/features/assets/presentation/screens/assets_screen.dart` | **%100 hardcoded** (`_assets` L14-80: Kombi/Klima/Bosch...) | — | ❌ **SAHTE** | **MOCK.** `api_client` import'u yok. "Arıza bildirimi oluşturuldu" (L415-419) sadece SnackBar — talep yaratılmıyor. Backend `/api/v1/assets` proxy'li, kullanılmıyor. |
| Profil/Ayarlar | `lib/features/profile/presentation/screens/profile_settings_screen.dart` | **%100 hardcoded** (`_userData` L18-24) | — | ❌ | **MOCK.** `getCurrentUser()` çağrılmıyor. Biyometrik anahtarı yalnızca yerel `setState` (L154) — `apiClient.setBiometricEnabled()` çağırmıyor, yani ayar kalıcı DEĞİL. Bildirim anahtarları hiçbir yere yazmıyor. **Çıkış Yap yalnızca dialog kapatıyor** (L232). 7 adet `onTap: () {}`. |
| (Ek) Daha Fazla | `lib/features/more/presentation/screens/more_screen.dart` | hardcoded ("Ahmet Yılmaz", "Güneş Sitesi • A-3") | — | ❌ | **MOCK + NAVİGASYON ÖLÜ.** 10 menü öğesinin **TAMAMI** `onTap: () {}` (L64,69,74,79,98,103,111,116,121). Çıkış `// TODO: Logout işlemi` (L168). |
| (Ölü kod) Eski Ana Sayfa | `lib/features/home/presentation/screens/home_screen.dart` | hardcoded, `final hasDebt = false; // TODO` (L87-88) | — | ❌ | **ÖLÜ KOD.** `app_router.dart:7`'de import ediliyor ama hiçbir route kullanmıyor → kullanılmayan import uyarısı. |

**Sonuç:** ROADMAP'in "Ekran | Durum: ✅" tablosu (`ROADMAP.md:108-120`) dosya varlığını ölçüyor, işlevselliği ölçmüyor. 13 ekranın 8'i hiç ağ çağrısı içermiyor, 2'si backend'de olmayan yola çağrı yapıyor.

### 1.1 Router'da tanımlı, UI'dan ULAŞILAMAYAN ekranlar

Kanıt: `Grep "context\.(go|push|...)"` tüm `mobile/lib` içinde yalnızca şu hedefleri buldu:
`/login`, `/kvkk-consent`, `/`, `/finance`, `/requests`, `/more` (`login_screen.dart:226,232,289`; `kvkk_consent_screen.dart:23`; `main_screen.dart:48,61,64,67,70`).

Dolayısıyla `app_router.dart`'ta tanımlı olup **hiçbir kod yolundan erişilemeyen 12 route**:

| Route | Dosya:satır | Erişim |
|---|---|---|
| `/finance/payment` (duesPayment) | `app_router.dart:57-61` | ❌ ulaşılamaz |
| `/requests/create` (createRequest) | `app_router.dart:69-73` | ❌ ulaşılamaz |
| `/announcements` | `app_router.dart:85-89` | ❌ ulaşılamaz |
| `/visitor-preregister` | `app_router.dart:90-94` | ❌ ulaşılamaz |
| `/reservation` | `app_router.dart:95-99` | ❌ ulaşılamaz |
| `/profile` | `app_router.dart:100-104` | ❌ ulaşılamaz |
| `/bulletin` | `app_router.dart:107-111` | ❌ ulaşılamaz |
| `/surveys` | `app_router.dart:114-118` | ❌ ulaşılamaz |
| `/packages` | `app_router.dart:121-125` | ❌ ulaşılamaz |
| `/energy` | `app_router.dart:128-132` | ❌ ulaşılamaz |
| `/documents` | `app_router.dart:135-139` | ❌ ulaşılamaz |
| `/assets` | `app_router.dart:142-146` | ❌ ulaşılamaz |

Yani gerçek bir kullanıcı, uygulamayı derleyip çalıştırdığında yalnızca **4 sekme** görebilir: Ana Sayfa (mock), Finans (mock), Talepler (mock), Daha Fazla (tüm menüsü ölü). Ekranların 12'si kullanıcıya asla gösterilemez. Ayrıca bu 12 ekranın çoğu `Navigator.pop(context)` ile geri gitmeye çalışıyor (ör. `bulletin_board_mobile_screen.dart:80`, `surveys_mobile_screen.dart:84`, `energy_consumption_mobile_screen.dart:54`) — `context.go()` ile açılsalar bile pop edilecek bir sayfa olmayacağı için geri butonu da bozuk olurdu.

---

## 2. İddia Doğrulama

### İddia 1 — "Tüm sakin ekranları ✅" (`ROADMAP.md:108-120`)
**Verdict: YANLIŞ (aşırı iddia).**
Kanıt: §1 tablosu. Dosyalar var, ancak 8/13 ekran hiç ağ çağrısı içermiyor ve 12/18 route ulaşılamaz (§1.1).

---

### İddia 2 — ÇELİŞKİ: ROADMAP "📋 Gerçek API entegrasyonu (çoğu ekranda mock data var)" (`ROADMAP.md:125`) vs `tasks/todo.md:91-96` "Faz 1 ... (Tamamlandı) — Rezervasyon/Duyuru/Anket/Kargo/İlan Panosu ekranlarını gerçek API'ye bağlamak ✅"

**Verdict: ROADMAP:125 DOĞRU. `todo.md` KISMEN YANLIŞ.**

`todo.md`'nin listelediği 5 ekranda gerçekten kod yazılmış; ama 5'inin 2'si backend'de olmayan yola gidiyor ve hiçbiri hata durumunu göstermiyor. `todo.md` "Faz 1 tamamlandı" derken bu 5 ekranı kastediyor; ROADMAP:125 ise geri kalan 8 ekranı kastediyor. İki ifade çelişmiyor — **ROADMAP:125 hâlâ geçerli ve doğru**; `todo.md` ise "tamamlandı" derken doğrulama yapmamış.

Ekran ekran teşhis (soru: "gerçek API mi / hardcoded mock mu / API var ama hata durumunda sessizce mock'a mı düşüyor?"):

| Ekran | Teşhis |
|---|---|
| Rezervasyon | **Gerçek API** (okuma+yazma). Mock fallback YOK. Ama saat slotları hardcoded (`create_reservation_screen.dart:22-31`). |
| Duyurular | **Gerçek API** (okuma). Mock fallback YOK; hata → **sessizce BOŞ liste** (`announcements_screen.dart:42-44`) → kullanıcı "Henüz duyuru yok" görür (L79). |
| Anketler | **Gerçek API** (okuma) + yazma yolu 404. Hata → sessizce boş (`surveys_mobile_screen.dart:55-57`). Veri gelirse **çöküyor** (L163). |
| Kargo | **Gerçek API** (okuma). Hata → sessizce boş (`package_tracking_mobile_screen.dart:45-47`). |
| İlan Panosu | **Gerçek API kodu** ama yol 404 → pratikte daima boş (`bulletin_board_mobile_screen.dart:54-56`). |

**Önemli nüans:** Hiçbir ekran "hata durumunda mock'a düşmüyor". Bunun yerine **hata durumunda sessizce boş listeye düşüyor** ve kullanıcıya "veri yok" diye yanlış bilgi veriyor. Tek bir `catch` bloğunda dahi hata mesajı/yeniden dene yok. Bu, mock'a düşmekten daha kötü bir kalıp: kullanıcı sunucunun çöktüğünü asla anlamıyor.

---

### İddia 3 — `api_client.dart` metotlarının backend karşılıkları
**Verdict: 3 UYUŞMAZLIK var + 15 metot ölü.** Ayrıntı §3.

---

### İddia 4 — "Biyometrik giriş (`local_auth`) tam entegrasyonu — `flutter_secure_storage` tabanlı kalıcı oturum + gerçek `apiClient.login()` + parmak izi ile oturum yenileme" (`ROADMAP.md:129`, `CHANGELOG.md:20`)

**Verdict: KISMEN DOĞRU — ama Android'de RUNTIME'DA ÇALIŞMAZ ve "kalıcı oturum" iddiası YANLIŞ.**

Doğru olan kısımlar (kanıtlı):
- `login_screen.dart:220` → `await apiClient.login(...)` **gerçek çağrı**. CHANGELOG'un "önceden `Future.delayed` ile sahte gecikme atıyordu" tespiti doğru; artık `Future.delayed` kodda yok (grep: 0 sonuç). ✅
- `flutter_secure_storage` gerçekten kullanılıyor: `api_client.dart:12` (`FlutterSecureStorage`), `_persistTokens` L72-77, token'lar L73/L75'te yazılıyor. ✅
- 401'de otomatik refresh interceptor'ı var: `api_client.dart:33-51`. ✅
- İlk girişte "Biyometrik girişi etkinleştir?" diyaloğu: `login_screen.dart:246-275`. ✅

**YANLIŞ / KIRIK olan kısımlar:**

1. **KRİTİK — Android'de biyometrik doğrulama ÇALIŞMAZ.**
   `mobile/android/app/src/main/kotlin/com/example/siteeksen_mobile/MainActivity.kt:5`
   ```kotlin
   class MainActivity : FlutterActivity()
   ```
   `local_auth` Android eklentisi `FlutterFragmentActivity` gerektirir. `FlutterActivity` ile `authenticate()` çağrısı `no_fragment_activity` PlatformException atar. `login_screen.dart:295-300` bu hatayı yakalayıp "Biyometrik doğrulama başarısız" gösterir. Yani buton görünse bile **hiçbir zaman giriş yapmaz**.

2. **KRİTİK — "Kalıcı oturum" YOK.** `api_client.hasStoredSession()` (L90-92) yazılmış ama uygulama açılışında kullanılmıyor:
   - `main.dart` (35 satır, tamamı okundu) oturum kontrolü içermiyor.
   - `app_router.dart:28` → `initialLocation: '/login'` sabit.
   - `app_router.dart:148-151` → `redirect: (context, state) { /* TODO: Auth durumuna göre yönlendirme */ return null; }`
   Sonuç: geçerli token'a sahip kullanıcı uygulamayı her açtığında giriş ekranı görür. Token secure storage'da duruyor ama otomatik giriş yok. "Kalıcı oturum" iddiası gerçekleşmemiş.

3. Biyometrik ayar **Profil ekranından yönetilemiyor**: `profile_settings_screen.dart:150-164` anahtarı yalnızca yerel `_biometricEnabled` state'ini değiştiriyor; `apiClient.setBiometricEnabled()` çağrılmıyor ve `initState`'te `isBiometricEnabled()` okunmuyor → anahtar her açılışta `false` (L16) görünür ve değişiklik hiçbir yere yazılmaz.

4. **Güvenlik — biyometrik doğrulama atlanabilir mi?** Refresh token secure storage'da (`api_client.dart:75`) — bu iyi. Ancak:
   - `loginWithStoredSession()` (L107) yalnızca `_tryRefreshToken()`; **biyometrik doğrulamayı kendisi kontrol etmiyor.** Kapı tamamen UI tarafında (`login_screen.dart:280-286`). Başka bir çağrı noktası eklenirse (ör. bir splash/auto-login) biyometrik tamamen atlanır. Kriptografik bağ yok (`AndroidPrompt`/`StrongBox`/`useErrorDialogs` yok, token biyometrikle şifrelenmemiş).
   - `FlutterSecureStorage` **varsayılan ayarlarla** (L12) — Android'de `EncryptedSharedPreferences` etkin değil (`AndroidOptions(encryptedSharedPreferences: true)` yok) → root'lu cihazda daha zayıf.
   - `_biometricEnabledKey` (L9) da aynı depoya `'true'` string'i olarak yazılıyor — sunucu tarafı bir kontrol yok.
   - `AuthenticationOptions(biometricOnly: true)` (L282): parmak izi kayıtlı olmayan cihazda istisna atar, PIN/desen'e düşmez → fallback yok.
   - `canCheckBiometrics` kullanılıyor (L31) ama `isDeviceSupported()` kontrol edilmiyor.
   - `AndroidManifest.xml`'de `USE_BIOMETRIC`/`USE_FINGERPRINT` izni **yok** (dosyanın tamamı okundu, 45 satır).

---

### İddia 5 — "KVKK açık rıza ekranı — ilk girişte zorunlu, geçilemez `PopScope(canPop: false)`" (`ROADMAP.md:132`, `CHANGELOG.md:19`)

**Verdict: KISMEN DOĞRU — `PopScope` var ama ekran ATLANABİLİR.**

Doğru: `kvkk_consent_screen.dart:37-38` → `PopScope(canPop: false, child: Scaffold(...))`, `automaticallyImplyLeading: false` (L42), onay kutusu işaretlenmeden buton `null` (L85), onay `apiClient.acceptKvkkConsent()` ile gerçekten yazılıyor (L21). ✅

**Atlama yolları (kanıtlı):**
1. **Biyometrik giriş yolu KVKK'yı hiç kontrol etmiyor.** `login_screen.dart:286-289`:
   ```dart
   final restored = await apiClient.loginWithStoredSession();
   if (restored) { context.go('/'); }
   ```
   `/auth/refresh` yanıtında `kvkk_consent_required` bakılmıyor, `getCurrentUser()` çağrılmıyor. Onay vermemiş kullanıcı biyometrikle doğrudan ana ekrana girer.
2. **Route guard yok.** `app_router.dart:148-151` `redirect` bir `TODO` ve `null` dönüyor. `/` route'u hiçbir koşula bağlı değil → deep link / `context.go('/')` ile ekran atlanır.
3. Onay yalnızca `login()` yanıtındaki `user['kvkk_consent_required'] == true` ile tetikleniyor (`login_screen.dart:223-228`); `user` beklenmeyen bir tipte gelirse (`user is Map` kontrolü var, iyi) sessizce atlanır.
4. `PopScope(canPop: false)` yalnızca Android geri hareketini/tuşunu engeller — uygulamayı kapatıp yeniden açmayı engellemez (bu tasarımda kabul edilebilir, çünkü tekrar `/login`'e düşer ve sunucu tekrar `required` döner).

---

### İddia 6 — "Android geri tuşu düzeltmesi — `main_screen.dart`'a `PopScope` eklendi" (`ROADMAP.md:131`, `CHANGELOG.md:22`)

**Verdict: DOĞRU.**
Kanıt: `main_screen.dart:42-52`:
```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    if (_currentIndex != 0) { setState(() => _currentIndex = 0); context.go('/'); }
    else { _confirmExit(); }
  },
```
`_confirmExit()` (L17-38) onay diyaloğu + `SystemNavigator.pop()` (L36) içeriyor. CHANGELOG'daki tarif kodla birebir örtüşüyor.

Küçük kusurlar: (a) `_currentIndex` yalnızca sekme dokunuşuyla güncelleniyor (L57-58), route'tan türetilmiyor → dış bir `context.go('/finance')` sonrasında geri tuşu davranışı yanlış olur; (b) `onPopInvokedWithResult` yalnızca Flutter ≥3.24 API'si — `pubspec.lock:1234` `flutter: ">=3.38.4"` olduğu için sorun yok, ancak `pubspec.yaml:9` `sdk: '>=3.2.0'` diyor → tutarsız beyan (lock ile pubspec çelişiyor).

---

### İddia 7 — "Talep onay mekanizması — sakin 'sorunum çözüldü' diyerek onaylayabiliyor (`apiClient.confirmRequestResolution`)" (`ROADMAP.md:128`, `CHANGELOG.md:18`)

**Verdict: KISMEN DOĞRU — kod ve backend gerçek, ama pratikte ÇALIŞMAZ.**

Doğru olan:
- `api_client.dart:211-216` gerçek `POST /requests/$requestId/confirm-resolution`. ✅
- Backend gerçekten var: `backend/services/community/main.go:42` → `requests.POST("/:id/confirm-resolution", handlers.ConfirmRequestResolution(requestService))`; gateway proxy'li (`backend/cmd/gateway/main.go:151`). ✅
- UI var: `requests_screen.dart:252-282` — `RESOLVED` durumunda "Sorunum çözüldü" / "Devam ediyor" butonları, `_confirmResolution(bool)` (L214-236) gerçek çağrı, loading/hata yönetimi mevcut. ✅

**Neden pratikte çalışmaz:**
1. Talep listesi API'den gelmiyor. `requests_screen.dart:139-146`'daki tek `RESOLVED` kayıt **hardcoded** ve `id: 'mock-request-0089'` (L140). Bu ID veritabanında yok → çağrı 404 alır ve "İşlem gerçekleştirilemedi" gösterir.
2. `apiClient.getRequests()` (`api_client.dart:183`) hiçbir yerden çağrılmıyor → gerçek `RESOLVED` talep hiç ekrana gelmez.
3. `/requests` sekmesine (`main_screen.dart:67`) ulaşılabiliyor — yani ekran görünür, ama içeriği sahte.

Yani "sakin onaylayabiliyor" iddiası backend + UI iskeleti için doğru, **uçtan uca akış için yanlış**.

---

### İddia 8 — Ödeme akışı: gerçek sağlayıcı (iyzico) mı, sahte "ödeme başarılı" mı? **(KRİTİK — para)**

**Verdict: TAMAMEN SAHTE. Hiçbir ağ çağrısı yok.**

`dues_payment_screen.dart` (358 satır, tamamı okundu):
- `L253` — "₺1250.00 Öde" butonu → `_showPaymentConfirmation(context)`
- `L262-332` — onay bottom sheet'i; "Onayla" butonu (`L315-318`):
  ```dart
  onPressed: () {
    Navigator.pop(context);
    _showPaymentSuccess(context);
  },
  ```
- `L334-371` — `_showPaymentSuccess`: yeşil tik + **"Ödeme Başarılı!"** + "Ödemeniz başarıyla gerçekleştirildi."

**Bu fonksiyon zincirinde tek bir `await`, `apiClient`, `dio` ya da HTTP çağrısı YOK.** Grep kanıtı: `apiClient.*` taramasında `dues_payment_screen.dart` hiç geçmiyor.

- `apiClient.createPayment(...)` (`api_client.dart:159-172`) yazılmış, **hiçbir yerden çağrılmıyor**.
- Backend hazır: `backend/services/finance/main.go:52` → `api.POST("/payments", handlers.CreatePayment(financeService))`, gateway proxy'li (`main.go:148`).
- Ödeme yöntemi seçimi (`L172-224`) yalnızca `_selectedPaymentMethod` int'ini değiştiriyor; hiçbir yere gönderilmiyor. Kart numarası/CVV/3D Secure alanı **yok** — yani "Kredi/Banka Kartı" seçilse bile toplanacak veri yok.
- Tutar `_duesInfo['currentDebt'] = 1250.00` **hardcoded** (L18).
- iyzico: `mobile/` içinde `iyzico`/`iyzipay` geçen tek satır yok. `ROADMAP.md:195` "iyzico (ödeme) ✅ Sandbox bağlantısı kurulu" backend içindir; `tasks/todo.md:117` ise **"📌 Iyzico Entegrasyonu (Sonradan yazılacak - Ertelendi)"** diyor — mobil taraf için `todo.md` doğru, `ROADMAP` yanıltıcı.

**Risk:** Kullanıcı "Ödeme Başarılı" ekranını görür, borcu ödenmiş sanır, hiçbir para hareketi olmaz, hiçbir kayıt oluşmaz. Bu ekran ulaşılamaz durumda (§1.1) olduğu için şu an canlı zarar vermez — ama menü bağlantısı eklenir eklenmez doğrudan finansal yanlış bilgilendirme üretir.

Aynı sahte-başarı kalıbı 3 yerde daha:
- `create_request_screen.dart:273-313` — "Talep Oluşturuldu! Takip numaranız: TLP-2026-042"
- `visitor_preregister_screen.dart:261-301` — "Ön Kayıt Oluşturuldu! QR kodlu giriş linki SMS olarak gönderildi"
- `documents_screen.dart:667-695` — "Belge yönetimle paylaşıldı"

---

### İddia 9 — Push notification (Firebase Messaging): kurulum / token kaydı / handler / yönlendirme

**Verdict: TAMAMEN YOK. Sadece `pubspec.yaml` satırı var.**

| Gereksinim | Durum | Kanıt |
|---|---|---|
| `firebase_core` / `firebase_messaging` bağımlılığı | ✅ beyan edilmiş | `pubspec.yaml:43-44` |
| Kodda import | ❌ **HİÇ YOK** | Grep `firebase` → `mobile/lib` içinde 0 sonuç |
| `Firebase.initializeApp()` | ❌ **YOK** | `main.dart` tamamı (35 satır) okundu — yalnızca `WidgetsFlutterBinding.ensureInitialized()` (L7) |
| `google-services.json` | ❌ **YOK** | `mobile/android` tam dosya listesi alındı (19 dosya) — yok |
| `GoogleService-Info.plist` | ❌ **YOK** | `mobile/ios` klasörü hiç yok |
| Gradle `com.google.gms.google-services` eklentisi | ❌ **YOK** | `android/app/build.gradle.kts:1-6` yalnızca 3 eklenti |
| `POST_NOTIFICATIONS` izni (Android 13+) | ❌ **YOK** | `AndroidManifest.xml` tamamı okundu |
| `requestPermission()` | ❌ YOK | — |
| `getToken()` + backend'e kayıt | ❌ YOK | `api_client.dart`'ta cihaz/token metodu yok |
| Foreground handler (`onMessage`) | ❌ YOK | — |
| Background handler (`onBackgroundMessage`) | ❌ YOK | — |
| Bildirime tıklayınca yönlendirme (`onMessageOpenedApp`/`getInitialMessage`) | ❌ YOK | — |
| Yerel bildirim gösterimi (`flutter_local_notifications`) | ❌ paket bile yok | `pubspec.yaml` |

Backend hazır ama boşa: `backend/services/notification/main.go:59` → `POST /api/v1/devices/register` (FCM token), `L60` → `DELETE /api/v1/devices/:token`. **Ayrıca gateway bu yolu proxy etmiyor** — `backend/cmd/gateway/main.go:157` yalnızca `/api/v1/notifications`. Yani mobil bu metodu yazsaydı da gateway'den 404 alırdı.

`ROADMAP.md:127` "📋 Push notification alma ve gösterme akışını test et" — "test et" ifadesi kurulumun bittiğini ima ediyor; **kurulum hiç yapılmamış**. `ROADMAP.md:196` "Firebase (push) ✅" beyanı mobil için yanlış.

Not: `resident_home_screen.dart:85`'te bildirim ikonunun üzerinde sabit "2" badge'i var ve `onPressed: () {}` (L90) — sahte bildirim göstergesi.

---

### İddia 10 — `pubspec.yaml` bağımlılıkları gerçekten kullanılıyor mu? Üretilmiş dosyalar commit'li mi?

**Verdict A (üretilmiş dosya): DERLEME RİSKİ YOK — çünkü kod üretimi hiç kullanılmıyor.**

- `Get-ChildItem -Include *.g.dart,*.freezed.dart,*.config.dart -Recurse` → **0 dosya**.
- ANCAK Grep `@freezed|@JsonSerializable|@RestApi|@riverpod|part '` → `mobile/lib` içinde **0 sonuç**. `mobile/lib` altında hiç model/DTO dosyası yok (`lib/` yalnızca `core/{network,router,theme,widgets}` + `features/*/presentation/screens`).
- Sonuç: `build_runner` çalıştırılmadığı için derleme kırılmaz; ama **freezed/json_serializable/retrofit/riverpod_generator mimarisi hiç kurulmamış**. Tüm API yanıtları `Map<String, dynamic>` / `List<dynamic>` olarak ham işleniyor (`api_client.dart` tamamı) ve ekranlarda elle map'leniyor (ör. `surveys_mobile_screen.dart:28-52`) — tip güvenliği sıfır. `surveys` çökmesi (§4) tam olarak bunun sonucu.

**Verdict B (kullanılmayan bağımlılıklar): 13/22 bağımlılık ÖLÜ.**

Grep kanıtı (`mobile/lib` içinde tek eşleşme: `login_screen.dart:3 import 'package:local_auth/local_auth.dart';`)

| Bağımlılık | pubspec | Kullanım | Durum |
|---|---|---|---|
| `flutter_riverpod` | :16 | `main.dart:2,9`, `app_router.dart:2,26` | ⚠️ **isim düzeyinde kullanılıyor** — bkz. İddia 12 |
| `riverpod_annotation` | :17 | 0 | ❌ ÖLÜ |
| `dio` | :20 | `api_client.dart:1` | ✅ |
| `retrofit` + `retrofit_generator` | :21, :57 | 0 | ❌ **ÖLÜ** — ROADMAP:126 "Retrofit/Dio ile API client'ları tamamla 📋" doğru |
| `shared_preferences` | :24 | 0 | ❌ ÖLÜ |
| `flutter_secure_storage` | :25 | `api_client.dart:2,12` | ✅ |
| `go_router` | :28 | `app_router.dart:3` + 3 ekran | ✅ |
| `flutter_svg` | :31 | 0 | ❌ ÖLÜ |
| `cached_network_image` | :32 | 0 | ❌ ÖLÜ (uygulamada hiç uzak görsel yok) |
| `shimmer` | :33 | 0 | ❌ ÖLÜ (tüm loading `CircularProgressIndicator`) |
| `fl_chart` | :34 | 0 | ❌ **ÖLÜ** — grafikler elle `Container(height: 80*value)` ile çiziliyor (`energy_...:158-165`, `home_screen.dart:261-270`) |
| `intl` | :37 | 0 | ❌ **ÖLÜ** — bkz. §5 para/tarih formatlama |
| `equatable` | :38 | 0 | ❌ ÖLÜ |
| `freezed_annotation` + `freezed` | :39, :55 | 0 | ❌ ÖLÜ |
| `json_annotation` + `json_serializable` | :40, :56 | 0 | ❌ ÖLÜ |
| `firebase_core` | :43 | 0 | ❌ **ÖLÜ** (İddia 9) |
| `firebase_messaging` | :44 | 0 | ❌ **ÖLÜ** (İddia 9) |
| `local_auth` | :47 | `login_screen.dart:3,18,31,249,280` | ⚠️ kullanılıyor ama Android'de kırık (İddia 4) |
| `build_runner` | :54 | 0 kullanım | ❌ ÖLÜ |
| `riverpod_generator` | :58 | 0 | ❌ ÖLÜ |

Ayrıca `pubspec.yaml` `assets:` bölümü tanımlamamış, ama `mobile/assets/icons/.gitkeep` ve `assets/images/.gitkeep` var — boş, kullanılmıyor. Dosya adı/paket adı `siteeksen_mobile`, `description: SiteEksen Site Yönetim Mobil Uygulaması` — görev tanımındaki "SAKİN" markası ile ROADMAP'in "SiteEksen" adı tutarlı; sorun yok.

---

### İddia 11 — Platform yapılandırması

| Kontrol | Sonuç | Kanıt |
|---|---|---|
| `android/` klasörü | ✅ var | `mobile/android/...` (19 dosya) |
| **`ios/` klasörü** | ❌ **YOK** | `Test-Path mobile/ios` → `False`. iOS build **imkânsız**. `ROADMAP.md:130` "App Store / Google Play yayınlama 📋" — App Store için hiçbir altyapı yok. |
| `INTERNET` izni (release) | ❌ **YOK — KRİTİK** | `android/app/src/main/AndroidManifest.xml` tamamı (45 satır) okundu: hiç `<uses-permission>` yok. İzin yalnızca `android/app/src/debug/AndroidManifest.xml:6`'da. Flutter bu dosyayı yalnızca debug/profile build'lerde merge eder → **release APK'da ağ erişimi yok, tüm API çağrıları `SocketException` ile başarısız olur** (ve §2-İddia2 gereği sessizce boş ekran gösterilir). |
| `POST_NOTIFICATIONS` | ❌ YOK | aynı dosya |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | ❌ YOK | aynı dosya |
| `CAMERA` / `READ_MEDIA_IMAGES` | ❌ YOK | aynı dosya (fotoğraf ekleme butonları da no-op) |
| `google-services.json` | ❌ YOK | tam dosya listesi |
| `GoogleService-Info.plist` | ❌ YOK | `ios/` yok |
| `applicationId` | ⚠️ `com.example.siteeksen_mobile` | `android/app/build.gradle.kts:24` + `// TODO: Specify your own unique Application ID` (L23) — Play Store'a yüklenemez |
| Release imzalama | ⚠️ **debug anahtarıyla** | `build.gradle.kts:35-37`: `// TODO: Add your own signing config` + `signingConfig = signingConfigs.getByName("debug")` — Play Store reddeder |
| `android:label` | ⚠️ `siteeksen_mobile` | `AndroidManifest.xml:3` — kullanıcıya teknik paket adı görünür |
| Deep link / App Link | ❌ YOK | `AndroidManifest.xml`'de yalnızca `MAIN`/`LAUNCHER` intent-filter (L23-26); `<data android:scheme=...>` yok. go_router'ın deep link yeteneği kullanılamaz. |
| ProGuard/R8 kuralları | ❌ YOK | `build.gradle.kts`'de `minifyEnabled`/proguard yok |
| `README.md` | ⚠️ **varsayılan Flutter şablonu** | `mobile/README.md` tamamı: "A new Flutter project." |

**API base URL:**
`api_client.dart:5`
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```
- **`localhost` gerçek cihazda ÇALIŞMAZ** (cihazın kendisine bakar). Android emülatöründe de çalışmaz — `10.0.2.2` gerekir.
- `--dart-define`, `String.fromEnvironment`, `.env`, build flavor **yok** → ortam bazlı yapılandırma imkânsız, adres değiştirmek için kod düzenlemek gerekiyor.
- **`http://` (TLS yok)** → Android 9+ varsayılan olarak cleartext trafiği engeller (`usesCleartextTraffic` false). `AndroidManifest.xml`'de `android:usesCleartextTraffic="true"` veya network-security-config **yok** → izin sorunu aşılsa bile HTTP çağrıları bloklanır. Ve JWT token'ı düz metin taşımak güvenlik açığı.
- `apiClient` global bir singleton (`api_client.dart:294` → `final apiClient = ApiClient();`) — DI/Riverpod dışı, testte mock'lanamaz.

---

### İddia 12 — Mimari tutarlılık (Riverpod gerçekten kullanılıyor mu? go_router eksiksiz mi?)

**Verdict: Riverpod ADI kullanılıyor, MİMARİSİ kullanılmıyor. go_router route'ları var ama yarısı ölü.**

Riverpod kanıtı:
- `main.dart:9` `ProviderScope`, `main.dart:15` `ConsumerWidget`, `main.dart:20` `ref.watch(appRouterProvider)`
- `app_router.dart:26` `final appRouterProvider = Provider<GoRouter>((ref) {...})`
- **Bu, tüm uygulamadaki TEK provider.** Grep `Provider<`/`StateNotifier`/`AsyncNotifier`/`FutureProvider`/`ConsumerWidget`/`ConsumerStatefulWidget` → başka eşleşme yok.
- 13 ekranın **hiçbiri** `ConsumerWidget`/`ConsumerStatefulWidget` değil. Hepsi `StatefulWidget` + `setState` ya da `StatelessWidget`.
- Sonuç: state yönetimi yok, cache yok, ekranlar arası paylaşılan durum yok (aynı kullanıcı bilgisi 4 ayrı dosyada hardcoded tekrarlanmış: `resident_home_screen.dart:15`, `home_screen.dart:14`, `more_screen.dart:38`, `profile_settings_screen.dart:19` — hepsi "Ahmet Yılmaz", ama daire bilgisi tutarsız: "D.105 / A Blok" vs "A-3 / Güneş Sitesi").
- `data/` ve `domain/` katmanları hiç yok — `features/*/presentation/screens/` dışında klasör yok. "Clean architecture" klasör iskeleti yarım.

go_router:
- 18 route tanımlı, sözdizimsel olarak eksiksiz. **Tanımsız route'a gidiş yok** (tüm `context.go` hedefleri tanımlı) ✅
- `errorBuilder` / `onException` **yok** → hatalı URL'de varsayılan gri hata ekranı.
- `redirect` bir `TODO` (`app_router.dart:148-151`) → auth guard yok (§İddia 5).
- 12 route UI'dan ulaşılamaz (§1.1).
- `ShellRoute` içindeki `/finance/payment` ve `/requests/create` alt route'ları shell'in içinde açılacak (alt navigasyon çubuğu görünür kalır) — tam ekran form için yanlış yapı, ama ulaşılamadıkları için görünmez.

---

## 3. `api_client.dart` ↔ Backend Uyuşmazlıkları

Referanslar: `mobile/lib/core/network/api_client.dart`; `backend/cmd/gateway/main.go`; `backend/services/*/main.go`.

Gateway yönlendirme kuralı: `proxyPaths` (`gateway/main.go:84-91`) her yolu `mux.Handle(p, proxy)` + `mux.Handle(p+"/", proxy)` olarak kaydeder. Go `ServeMux`'ta `/api/v1/bulletin/` deseni `/api/v1/bulletins`'i **eşlemez** ve gateway'de catch-all (`mux.Handle("/", ...)`) handler'ı **yok** → eşleşmeyen yol 404.

### 3.1 Tam metot envanteri (24 public metot)

| # | Metot | HTTP yol | Gateway | Servis route | Uyum | Çağrılıyor mu? |
|---|---|---|---|---|---|---|
| 1 | `login` | `POST /auth/login` | `main.go:133` → identity | `identity/main.go:43` | ✅ | ✅ `login_screen.dart:220` |
| 2 | `refreshToken` (public) | `POST /auth/refresh` | :133 | `identity:44` | ✅ | ❌ **ölü** (özel `_tryRefreshToken` kullanılıyor) |
| 3 | `_tryRefreshToken` | `POST /auth/refresh` | :133 | `identity:44` | ✅ | ✅ `api_client.dart:37,107` |
| 4 | `setToken` | — (yerel) | — | — | ⚠️ `await` edilmeyen `_storage.write` (L80) — fire-and-forget | ❌ ölü |
| 5 | `clearToken` | — (yerel) | — | — | ✅ | ❌ **ölü — logout hiç çağırmıyor** |
| 6 | `hasStoredSession` | — (yerel) | — | — | ✅ | ✅ `login_screen.dart:32` (ama açılışta değil) |
| 7 | `isBiometricEnabled` | — (yerel) | — | — | ✅ | ✅ `login_screen.dart:33,247` |
| 8 | `setBiometricEnabled` | — (yerel) | — | — | ✅ | ⚠️ yalnızca `login_screen.dart:273` — Profil ekranı çağırmıyor |
| 9 | `loginWithStoredSession` | `POST /auth/refresh` | :133 | `identity:44` | ✅ | ✅ `login_screen.dart:286` |
| 10 | `getCurrentUser` | `GET /users/me` | :133 | `identity:53` | ✅ | ❌ **ölü** — Profil ekranı mock kullanıyor |
| 11 | `acceptKvkkConsent` | `POST /users/me/kvkk-consent` | :133 | `identity:57` | ✅ | ✅ `kvkk_consent_screen.dart:21` |
| 12 | `getUserProperties` | `GET /users/me/properties` | :133 | `identity:54` | ✅ | ❌ ölü — çoklu taşınmaz seçimi UI'da yok |
| 13 | `getDebtStatus` | `GET /finance/debt-status` | :148 → finance | `finance/main.go:41` | ✅ | ❌ **ölü** — Ana Sayfa/Finans mock bakiye gösteriyor |
| 14 | `getAssessments` | `GET /finance/assessments` | :148 | `finance:45` | ✅ | ❌ **ölü** |
| 15 | `createPayment` | `POST /finance/payments` | :148 | `finance:52` | ✅ | ❌ **ölü — KRİTİK** (§İddia 8) |
| 16 | `getConsumptionSummary` | `GET /finance/consumption/summary` | :148 | `finance:56` | ✅ | ❌ **ölü** — Enerji ekranı %100 mock |
| 17 | `getRequests` | `GET /requests` | :151 → community | `community/main.go:39` | ✅ | ❌ **ölü** — Talepler listesi mock |
| 18 | `createRequest` | `POST /requests` | :151 | `community:40` | ✅ | ❌ **ölü** — talep oluşturma sahte |
| 19 | `confirmRequestResolution` | `POST /requests/{id}/confirm-resolution` | :151 | `community:42` | ✅ | ⚠️ çağrılıyor ama **mock ID** ile (`requests_screen.dart:140,217`) |
| 20 | `getReservations` | `GET /reservations` | :202 → reservation | `reservation/main.go:123` | ✅ | ❌ ölü — sakin rezervasyonlarını göremiyor |
| 21 | `getFacilities` | `GET /facilities` | :202 | `reservation:110` | ✅ | ✅ `create_reservation_screen.dart:41` |
| 22 | `createReservation` | `POST /reservations` | :202 | `reservation:128` | ✅ yol; ⚠️ gövde şeması doğrulanamadı | ✅ `create_reservation_screen.dart:345` |
| 23 | `cancelReservation` | `DELETE /reservations/{id}` | :202 | `reservation:130` | ✅ | ❌ ölü — iptal UI'ı yok |
| 24 | `getAnnouncements` | `GET /announcements` | :151 | `community:48` | ✅ | ✅ `announcements_screen.dart:26` |
| 25 | `getSurveys` | `GET /surveys` | :211 → survey | `survey/main.go:109` | ✅ | ✅ `surveys_mobile_screen.dart:26` |
| 26 | `submitSurveyResponse` | `POST /surveys/{id}/responses` | :211 (prefix eşleşir) | **YOK** | ❌ **UYUŞMAZLIK** | ✅ çağrılıyor → 404 |
| 27 | `getPackages` | `GET /packages` | :190 → package | `package/main.go:107` | ✅ | ✅ `package_tracking_mobile_screen.dart:26` |
| 28 | `getVisitors` | `GET /visitors` | :214 → visitor | `visitor/main.go:95` | ✅ | ❌ ölü |
| 29 | `createVisitorPreRegistration` | `POST /visitors` | :214 | `visitor/main.go:101` | ✅ | ❌ **ölü** — ön kayıt sahte |
| 30 | `getBulletins` | `GET /bulletins` | **YOK** | (community:70 var ama proxy'siz) | ❌ **UYUŞMAZLIK** | ✅ çağrılıyor → 404 |
| 31 | `createBulletin` | `POST /bulletins` | **YOK** | (community:71 var ama proxy'siz) | ❌ **UYUŞMAZLIK** | ✅ çağrılıyor → 404 |

Özet: 24 public metot + 1 özel; **15'i hiç çağrılmıyor**; 3'ü backend'de karşılıksız.

### 3.2 UYUŞMAZLIK #1 — `POST /surveys/{id}/responses` → 404 (Anket oyu KAYBEDİLİYOR)

- Mobil: `api_client.dart:260-263` → `_dio.post('/surveys/$surveyId/responses', ...)`, gövde `{'option_id': selectedOption}` (`surveys_mobile_screen.dart:421`)
- Gateway: `gateway/main.go:211` → `proxyPaths(..., "/api/v1/surveys", "/api/v1/my-surveys")` → **survey-service**'e gider
- survey-service (`backend/services/survey/main.go:107-121`) yolları: `""`, `/active`, `/stats`, `/:id`, `/:id/results`, `/:id/votes`, `POST ""`, `PUT /:id`, `DELETE /:id`, `POST /:id/publish`, `POST /:id/end`, **`POST /:id/vote`** (L120), `GET /:id/my-vote`
- **`/:id/responses` YOK.** Doğru yol `POST /surveys/:id/vote`.
- Not: community-service'te de `surveys.POST("/:id/vote", submitVote)` var (`community/main.go:63`) — ikisi de `vote`, hiçbiri `responses`.
- Etki: "Oyu Gönder" butonu her zaman `Hata: DioException ... 404` gösterir (`surveys_mobile_screen.dart:434-439`). Anket oylama tamamen çalışmaz.
- Ek: Gönderilen alan adı `option_id`; backend `submitVote`/`voteSurvey` gövde şeması doğrulanamadı (handler gövdesi okunmadı) — yol düzeltilse bile alan adı uyuşmazlığı riski var.

### 3.3 UYUŞMAZLIK #2 ve #3 — `GET/POST /bulletins` → 404 (İlan Panosu tamamen kırık)

- Mobil: `api_client.dart:283-291` → `GET /bulletins`, `POST /bulletins`
- Gateway'de kayıtlı ilan yolları: `gateway/main.go:166` → `proxyPaths(mux, newProxy(bulletinURL), "/api/v1/bulletin")` → yalnızca `/api/v1/bulletin` ve `/api/v1/bulletin/`
- **`/api/v1/bulletins` hiçbir desene eşleşmiyor** ve gateway'de catch-all yok → Go `ServeMux` 404 ("404 page not found")
- Ayrıca **iki farklı servis çakışan ilan API'si tanımlamış**:
  - `backend/services/bulletin/main.go:123` → `/api/v1/bulletin/posts` (gateway'in yönlendirdiği yer; mobilin beklediği şema DEĞİL)
  - `backend/services/community/main.go:68-72` → `/api/v1/bulletins` (mobilin beklediği yol, ama gateway community'ye yalnızca `/announcements` ve `/requests` yönlendiriyor — `gateway/main.go:151`)
- Yani mobilin çağırdığı sözleşme backend'de **var ama erişilemez**; erişilebilen backend ise farklı bir yol/şema kullanıyor. Bu, "İlan Panosu ekranını gerçek API'ye bağlamak ✅" (`todo.md:96`) iddiasının hiç uçtan uca test edilmediğinin kanıtı.
- Etki: Ekran daima boş (hata `bulletin_board_mobile_screen.dart:54-56`'da yutuluyor); "Paylaş" daima `Hata: ...` (L369).

### 3.4 api_client'ta EKSİK olan, backend'de HAZIR olan uç noktalar

| Backend uç noktası | Kanıt | Mobil karşılığı | Etkilenen ekran |
|---|---|---|---|
| `POST /auth/logout` | `identity/main.go:45` | ❌ yok | Çıkış Yap (hiçbir şey yapmıyor) |
| `POST /announcements/:id/read` | `community/main.go:54` | ❌ yok | Duyurular "Okundu" butonu sahte |
| `POST /packages/:id/notify` | `package/main.go:114` | ❌ yok | "Güvenliğe Haber Ver" sahte |
| `GET /facilities/:id/availability` | `reservation/main.go:115` | ❌ yok | Rezervasyon saat slotları hardcoded |
| `GET /facilities/:id/slots` | `community/main.go:79` | ❌ yok | aynı |
| `GET /finance/payments` (geçmiş) | `finance/main.go:53` | ❌ yok | "Ödeme Geçmişini Görüntüle" `() {}` (`dues_payment_screen.dart:234`) |
| `GET /finance/assessments/:id` | `finance/main.go:48` | ❌ yok | Aidat detayı/makbuz yok |
| `POST /devices/register` (FCM) | `notification/main.go:59` | ❌ yok **+ gateway proxy'si de yok** | Push bildirim |
| `/api/v1/documents` (servis) | `gateway/main.go:172` | ❌ yok | Belgeler %100 mock |
| `/api/v1/assets` (servis) | `gateway/main.go:163` | ❌ yok | Varlıklar %100 mock |
| `/api/v1/energy` (servis) | `gateway/main.go:175` | ❌ yok | Enerji %100 mock |
| `/api/v1/vehicles` (parking) | `gateway/main.go:193` | ❌ yok | "Araçlarım" menü/kart öğeleri ölü |
| `GET /visitors/qr/:code` | `visitor/main.go:110` | ❌ yok | Ziyaretçi QR akışı yok |

---

## 4. DERLENEBİLİRLİK RİSKLERİ

### 4.1 `mobile/lib` — derlenir (kritik engel bulunamadı)

- Üretilmiş dosya (`*.g.dart` / `*.freezed.dart`) **gerekmiyor**: kodda hiç `@freezed`/`@JsonSerializable`/`@RestApi`/`@riverpod`/`part '...'` yok (Grep, 0 sonuç). Yani "build_runner çalıştırılmadığı için derlenmez" senaryosu **gerçekleşmemiş**.
- Tüm relative import'lar (`app_router.dart:5-24`, ekranlardaki `../../../../core/...`) mevcut dosyalara işaret ediyor; `AppleTheme`'in kullanılan tüm üyeleri doğrulandı (`apple_theme.dart:14,15,16,42,57,70` → `systemTeal`, `systemPink`, `systemYellow`, `fastAnimation`, `cardDecoration`, `inputDecoration`) ve `apple_widgets.dart`'ta kullanılan tüm sınıflar var (`ServiceCard:10`, `BalanceCard:86`, `NotificationCard:144`, `SectionTitle:198`, `QuickActionButton:222`, `ListItem:267`).
- `PopScope.onPopInvokedWithResult` (`main_screen.dart:44`) Flutter ≥3.24 API'si; `pubspec.lock:1234` `flutter: ">=3.38.4"` → **sorun yok**. (Ancak `pubspec.yaml:9` `sdk: '>=3.2.0 <4.0.0'` beyanı lock ile çelişiyor; Dart 3.2 ile pub get yapılırsa bu satır derlenmez.)

**Uyarı seviyesinde bulgular (`flutter analyze` çıktısı — çalıştırılamadı, statik tespit):**
- `app_router.dart:7` `home_screen.dart` import ediliyor, hiç kullanılmıyor → `unused_import`.
- `create_request_screen.dart:18` `_attachments` alanı okunmuyor/yazılmıyor → `unused_field`.
- `create_reservation_screen.dart:15` yerine `energy_..._screen.dart:14` `_selectedPeriod` ve `create_request_screen.dart:14` `_selectedCategory` gibi alanlar okunuyor, sorun yok.
- `create_request_screen.dart:59` `Container(height: 100, child: ...)` → `sized_box_for_whitespace` lint.
- `Colors.black.withOpacity(...)` / `Color.withOpacity` çok sayıda kullanım → Flutter 3.27+ `deprecated_member_use` (`withValues` önerilir). Örn. `dues_payment_screen.dart:52,57,69`, `apple_theme.dart` vb. — CHANGELOG:14 bunu "kod tabanı genelinde var olan deprecation info'ları" olarak zaten kabul ediyor.
- `announcements_screen.dart:24`, `bulletin_...:34`, `packages_...:24`, `surveys_...:24` → `void _loadX() async` (`async` dönüşü `void`) → `avoid_void_async` / hata yakalanmayan future riski.
- `create_reservation_screen.dart:334` `slot['time'].split(...)` → `dynamic` üzerinde çağrı, analyzer geçer ama tip güvensiz.

### 4.2 `mobile/test` — **DERLENMEZ (kesin)**

`mobile/test/widget_test.dart` (31 satır, tamamı okundu):
```dart
import 'package:siteeksen_mobile/main.dart';   // L11
...
await tester.pumpWidget(const MyApp());        // L16
```
`main.dart`'ta tanımlı sınıf **`SiteEksenApp`** (`main.dart:15`), `MyApp` diye bir sınıf **yok**.
→ `flutter test` **derleme hatası** verir: `Undefined class 'MyApp'`. Test ayrıca varsayılan "Counter increments" şablonu (L14-29) — uygulamada sayaç yok, `find.byIcon(Icons.add)` de bulunamaz.

**Sonuç: Test altyapısı çalışmıyor. Sakin uygulaması için 0 gerçek test var.**

### 4.3 Platform yapılandırması kaynaklı ÇALIŞMA ZAMANI engelleri

| # | Engel | Kanıt | Etki |
|---|---|---|---|
| 1 | Release build'de `INTERNET` izni yok | `android/app/src/main/AndroidManifest.xml` (izin satırı yok) vs `.../debug/AndroidManifest.xml:6` | **Release APK'da tüm API çağrıları başarısız**; ekranlar sessizce boş |
| 2 | `baseUrl = http://localhost:8000` | `api_client.dart:5` | Gerçek cihaz/emülatörde bağlantı yok |
| 3 | Cleartext HTTP + `usesCleartextTraffic` ayarı yok | `api_client.dart:5` + `AndroidManifest.xml` | Android 9+ HTTP'yi bloklar |
| 4 | `MainActivity : FlutterActivity` | `MainActivity.kt:5` | `local_auth` runtime exception (`no_fragment_activity`) |
| 5 | `ios/` klasörü yok | `Test-Path` → False | iOS derlemesi imkânsız |
| 6 | `google-services.json` yok + `Firebase.initializeApp()` yok | dosya listesi + `main.dart` | Firebase kullanılamaz (ama zaten hiç kullanılmıyor) |
| 7 | Release, debug anahtarıyla imzalanıyor | `android/app/build.gradle.kts:36-37` | Play Store yüklemesi reddedilir |
| 8 | `applicationId = com.example.*` | `build.gradle.kts:24` | Play Store paket adı geçersiz |

### 4.4 KESİN RUNTIME ÇÖKMESİ — Anketler ekranı

`surveys_mobile_screen.dart:163`:
```dart
final participation = (survey['totalVotes'] / survey['totalResidents'] * 100).toInt();
```
ve `L256`:
```dart
Text('${survey['totalVotes']}/${survey['totalResidents']}', ...)
```

Ancak `_loadSurveys()`'in oluşturduğu map (L39-51) şu anahtarları set ediyor: `id, title, description, endDate, daysLeft, totalVotes, hasVoted, votedOption, isActive, isUrgent, options`. **`totalResidents` anahtarı HİÇ set edilmiyor** ve backend alanı da map'lenmiyor.

→ `survey['totalResidents']` = `null` → `int / null` → **`NoSuchMethodError: The method '/' was called on null`** (veya sağlam mod tip hatası) → `_buildSurveyCard` her anket kartında çöker → kırmızı hata ekranı.

Yani: API tek bir anket döndürdüğü an ekran çöker. Bu hata **yalnızca boş liste döndüğünde gizlenir** — ve şu anda (`localhost` + INTERNET izni yok + ekran ulaşılamaz) her zaman boş dönüyor, bu yüzden fark edilmemiş. `todo.md:94` "Anket ekranlarını gerçek API'ye bağlamak ✅" iddiası gerçek veriyle bir kez bile test edilmemiş.

Ayrıca `L345` `option['winner']` ve `L395` `option['percentage'].toStringAsFixed(1)` — `winner` da map'lemede (L30-37) set edilmiyor (`null` → karşılaştırma güvenli, çökmez); `percentage` `.toDouble()` ile korunmuş (L35), iyi.

---

## 5. Mantık Hataları ve Eksiklikler

### 5.1 Sahte başarı bildirimleri (kullanıcıyı YANILTAN — en yüksek önem)

| Yer | Gösterilen | Gerçekte olan |
|---|---|---|
| `dues_payment_screen.dart:351` | "**Ödeme Başarılı!**" | Hiçbir ağ çağrısı yok. Para hareketi yok. |
| `create_request_screen.dart:290,293` | "Talep Oluşturuldu! Takip numaranız: TLP-2026-042" | Sabit metin, kayıt yok |
| `visitor_preregister_screen.dart:278,281` | "Ön Kayıt Oluşturuldu! ... QR ... SMS olarak gönderildi" | SMS gönderilmiyor, kayıt yok |
| `documents_screen.dart:691` | "Belge yönetimle paylaşıldı" | Bellek içi map; dosya seçilmemiş, yüklenmemiş |
| `documents_screen.dart:593,893` | "Belge indiriliyor..." | İndirme yok |
| `documents_screen.dart:624` | "Belge silindi" | Yalnızca yerel listeden çıkarıldı |
| `package_tracking_...:380` | "Güvenlik bilgilendirildi" | Bildirim gönderilmiyor |
| `assets_screen.dart:418` | "Arıza bildirimi oluşturuldu" | Talep oluşturulmuyor |
| `announcements_screen.dart:311` | "Okundu" | Okundu bilgisi yazılmıyor |

### 5.2 Hata / loading / empty state

- **Loading:** 5 ekranda `_isLoading` + `CircularProgressIndicator` var (`announcements_screen.dart:67-72`, `bulletin:61-66`, `packages:52-57`, `surveys:62-67`, `reservation:85-95`). `shimmer` paketi kurulu ama kullanılmıyor.
- **Hata state'i: HİÇBİR EKRANDA YOK.** 5 gerçek-API ekranının tamamında `catch` bloğu yalnızca `_isLoading = false` yapıyor:
  - `announcements_screen.dart:42-44` — `catch (_) { setState(() => _isLoading = false); }`
  - `bulletin_board_mobile_screen.dart:54-56`
  - `package_tracking_mobile_screen.dart:45-47`
  - `surveys_mobile_screen.dart:55-57`
  - `create_reservation_screen.dart:58-60`
  Hata mesajı yok, "Tekrar Dene" yok, loglama yok. Ağ kesintisi, 401, 500, 404 — hepsi "veri yok" olarak görünüyor. Bu, uygulamanın en yaygın ve en aldatıcı hata kalıbı.
- **Boş durum:** Duyurular (L79), Kargo (L63), Rezervasyon (L105) için metin var ✅. İlan Panosu için **boş durum yok** — liste 0 elemanlıysa tamamen boş beyaz alan (`bulletin_...:150-164`). Anketler için de boş durum yok (L111-136 koşullu, hiçbiri eşleşmezse yalnızca istatistik kartları görünür).
- **Pull-to-refresh: HİÇBİR EKRANDA YOK.** `RefreshIndicator` grep → 0 sonuç. Yenilemenin tek yolu ekrandan çıkıp geri girmek (ve o da 12 ekran için mümkün değil).
- **Sayfalama yok:** Tüm listeler tek seferde çekiliyor; `limit`/`offset`/`cursor` parametresi yok.

### 5.3 Offline davranış

- `connectivity_plus` benzeri paket **yok** (`pubspec.yaml`).
- Yerel önbellek yok (`shared_preferences` kurulu ama kullanılmıyor; Hive/Isar/sqflite yok).
- Dio'da retry interceptor yok; yalnızca 401 için tek deneme (`api_client.dart:35-48`).
- `connectTimeout: 10s`, `receiveTimeout: 30s` (`api_client.dart:17-18`) — makul; ama zaman aşımı da sessizce boş listeye düşüyor.
- Sonuç: **uçakta/tünelde uygulama boş bir kabuk gibi görünür, hiçbir açıklama vermez.**

### 5.4 Oturum güvenliği ve token yaşam döngüsü

| Konu | Durum | Kanıt |
|---|---|---|
| Token depolama | ✅ `flutter_secure_storage` | `api_client.dart:12,73,75` |
| Secure storage sertleştirme | ❌ `AndroidOptions(encryptedSharedPreferences: true)` yok | `api_client.dart:12` (`const FlutterSecureStorage()`) |
| Access token isteğe ekleniyor | ✅ | `api_client.dart:26-31` |
| 401'de otomatik refresh | ✅ tek denemeli (`_retried` guard, L35) | `api_client.dart:33-51` |
| Refresh başarısız olursa | ⚠️ **hiçbir şey** — hata ekrana gider, `/login`'e yönlendirme YOK | `api_client.dart:49` `handler.next(error)`; router `redirect` TODO (`app_router.dart:149`) |
| Token süresi bitince ne olur | **Sessizce boş ekranlar.** Refresh de dolmuşsa (7 gün) tüm ekranlar "veri yok" gösterir; kullanıcı yeniden giriş yapması gerektiğini asla anlamaz. Çıkış da çalışmadığı için sıkışır. | §5.2 + aşağıdaki logout satırı |
| **Logout token'ı temizliyor mu?** | ❌ **HAYIR — İKİ AYRI EKRANDA DA** | `more_screen.dart:166-169` → `Navigator.pop(context); // TODO: Logout işlemi`. `profile_settings_screen.dart:231-234` → `onPressed: () => Navigator.pop(context)` |
| `POST /auth/logout` çağrısı | ❌ yok (backend'de var: `identity/main.go:45`) | api_client'ta metot yok |
| `clearToken()` çağrısı | ❌ **hiçbir yerden** | Grep `clearToken` → yalnızca tanım (`api_client.dart:83`) |
| Refresh token rotasyonu | ✅ yeni refresh token yazılıyor | `api_client.dart:63,74-76` |
| Token JWT içeriği doğrulanıyor mu | ❌ süre/claim kontrolü yok (admin_app'te `getCurrentUserRoles()` varmış — `CHANGELOG:21`; mobilde yok) | — |
| Ekran kilidi / arka planda maskeleme | ❌ yok (`FLAG_SECURE`, `secureApplicationSwitcher` yok) | — |

**Sonuç: Kullanıcı çıkış yapamıyor. Token cihazda süresiz kalıyor. Cihaz el değiştirse veya birden fazla kişi kullansa oturum devam eder** (ve `hasStoredSession` sadece biyometrik butonunu gösterir).

### 5.5 Para / tarih / locale formatlama

- `intl` paketi kurulu (`pubspec.yaml:37`) ama **hiç import edilmiyor** → `NumberFormat`/`DateFormat` yok.
- **Para birimi TR formatında değil.** Tüm tutarlar `'₺${x.toStringAsFixed(2)}'` ile üretiliyor → **`₺1250.00`** (ABD ayırıcıları). TR doğru biçim `₺1.250,00`.
  Kanıt: `resident_home_screen.dart:103`, `dues_payment_screen.dart:78,139,255,300`, `energy_...:97,291`, `create_reservation_screen.dart:304`, `bulletin_...:260,499`.
  Tutarsızlık: `finance_screen.dart:27,62,66,71,77` ve `home_screen.dart:135` ise TR biçimini **elle yazmış** (`₺1.200,00`) → aynı uygulamada iki farklı para formatı.
- **`MaterialApp`'te `locale` ve `localizationsDelegates` YOK** (`main.dart:22-37`) → `showDatePicker` (`visitor_preregister_screen.dart:247`) ve `showTimePicker` (L257) **İngilizce** açılır ("Select date", "OK", "CANCEL"), hafta günleri İngilizce. `flutter_localizations` bağımlılığı da yok.
- Ay/gün adları **elle Türkçe dizilerle** kodlanmış (3 farklı yerde, 3 farklı formatta):
  - `visitor_preregister_screen.dart:242` — `['Oca','Şub',...]`
  - `create_reservation_screen.dart:189` — `['Pzt','Sal',...]` (hafta günü)
  - `create_reservation_screen.dart:405-406` — `['Ocak','Şubat',...]`
  - `energy_..._screen.dart:23-28` — `'Ağu','Eyl',...` (veri içine gömülü)
- **Timezone:** `DateTime.now()` her yerde yerel saat; UTC dönüşümü yok. `create_reservation_screen.dart:347` `_selectedDate.toIso8601String().split('T')[0]` — yerel tarihi tarih-string'e çeviriyor; sunucu UTC bekliyorsa gece yarısına yakın saatlerde **bir gün kayma** olur. `startTime`/`endTime` (`L335-336`) saat dilimi bilgisi olmadan `"09:00"` string'i olarak gönderiliyor.
- `create_reservation_screen.dart:188` `_selectedDate.day == date.day && _selectedDate.month == date.month` — **yıl karşılaştırılmıyor**; 14 günlük pencere yıl sınırını aşarsa (31 Aralık civarı) yanlış gün seçili görünür.
- Tarih alanlarının çoğu backend'den geldiği gibi string olarak basılıyor, hiç parse edilmiyor: `announcements_screen.dart:33-34` (`a['date'] ?? 'Belirtilmemiş'`, `a['time'] ?? ''`), `package_...:34-36` (`'12:00'`, `'Bugün'`, `'Yakında'` gibi **uydurma varsayılanlar**), `bulletin_...:47` (`b['date'] ?? 'Yeni'`). Sunucu ISO-8601 dönerse ekranda ham `2026-02-15T10:00:00Z` görünür.

### 5.6 Erişilebilirlik

- **`textScaler: TextScaler.noScaling`** (`main.dart:33`) — kullanıcının sistem yazı tipi boyutu ayarını **tamamen devre dışı bırakıyor.** Görme güçlüğü olan kullanıcılar metni büyütemez. WCAG/Play Store erişilebilirlik ihlali.
- `Semantics` / `semanticLabel` / `excludeSemantics` kullanımı **yok** (Grep → 0). Onlarca `IconButton` ve `GestureDetector` etiketsiz:
  - `resident_home_screen.dart:75-91` bildirim ikonu (`tooltip` yok)
  - `bulletin_...:79-82`, `surveys_...:83-86`, `energy_...:54`, `packages_...:82` geri ikonları
  - `assets_screen.dart:102-112` `GestureDetector` ile yapılmış geri butonu (dokunma hedefi 36x36 → **48x48 minimumun altında**)
- Renk-tek-başına anlam: durum yalnızca renkle ayırt ediliyor (yeşil/turuncu/kırmızı) — ancak metin etiketleri de var, kısmen kabul edilebilir.
- `dues_payment_screen.dart:40,247`, `create_request_screen.dart:41`, `visitor_...:33` → `backgroundColor: Colors.white` **sabit**; `AppleTheme.background` da sabit açık renk. `main.dart:26-27` `darkTheme` + `ThemeMode.system` tanımlı ama Apple-tarzı 20 ekran koyu temayı görmezden geliyor → **karanlık modda beyaz üstüne beyaz / okunamaz metin.**

### 5.7 i18n

- **Tüm metinler hardcoded Türkçe.** `AppLocalizations`, `.arb` dosyası, `flutter_localizations`, `l10n.yaml` — hiçbiri yok.
- `pubspec.yaml`'da `flutter: generate: true` yok.
- Tek dil hedefleniyorsa kabul edilebilir bir seçim; ancak `MaterialApp`'te `locale: Locale('tr','TR')` bile ayarlanmadığı için **Flutter'ın kendi widget metinleri (date/time picker, "Cancel", metin seçim menüsü) İngilizce** kalıyor → karışık dilli arayüz (§5.5).

### 5.8 Deep link

- `AndroidManifest.xml`'de yalnızca `MAIN`/`LAUNCHER` intent-filter (L23-26). `android.intent.action.VIEW` + `<data android:scheme="https" android:host="..."/>` **yok**.
- `ios/` yok → Universal Links imkânsız.
- go_router yol tabanlı olduğu için deep link'e hazır, ama platform yapılandırması olmadığı için kullanılamaz.
- Push bildirimden ekrana yönlendirme (İddia 9) da bu yüzden mümkün değil.

### 5.9 Bellek sızıntıları ve yaşam döngüsü hataları

| Sorun | Kanıt |
|---|---|
| `TextEditingController` `dispose()` edilmiyor | `visitor_preregister_screen.dart:13-15` (3 controller, `dispose` override'ı yok); `create_request_screen.dart:16-17` (2 controller, `dispose` yok); `bulletin_...:303-305` (bottom sheet içinde 3 controller, hiç dispose edilmiyor — her sheet açılışında sızıyor); `documents_screen.dart` upload sheet'i benzer |
| `TabController` | `documents_screen.dart:13` `late TabController _tabController` — `dispose` kontrolü doğrulanamadı (dosyanın 120-580 arası okunmadı) |
| Controller doğru dispose ediliyor | ✅ `login_screen.dart:42-47` |
| **Pop sonrası `context` kullanımı** | `bulletin_...:356-365` (iki `Navigator.pop` sonrası `ScaffoldMessenger.of(context)`), `surveys_...:422-431` (aynı kalıp), `packages_...:378-381` (`Navigator.pop` sonra `ScaffoldMessenger.of(context)`), `create_reservation_screen.dart:394-400`, `documents_screen.dart:893` → deaktif olmuş `context`; SnackBar hiç görünmez veya `FlutterError` atar |
| `async` sonrası `mounted` kontrolü yok | `bulletin_...:350-371`, `surveys_...:421-440`, `create_reservation_screen.dart:345-401` → `use_build_context_synchronously` lint + kullanıcı ekrandan çıkarsa exception |
| `mounted` kontrolü doğru yapılmış | ✅ `login_screen.dart:221,234,240,250,287,296,302`, `kvkk_consent_screen.dart:22,25,31`, `requests_screen.dart:218,228,234` |
| Her frame'de O(n) filtreleme | `bulletin_...:155,161` — `_getFilteredListings()` her eleman için **iki kez** çağrılıyor → O(n²) |
| `_isSubmitting` yarış durumu | `requests_screen.dart:206,215` — `_RequestItemState` içinde; iyi. Ama `_status` yerel state'te tutuluyor (L205,219), listeye yansımıyor → geri gelince eski durum |

### 5.10 Diğer mantık hataları

1. **`visitor_preregister_screen.dart` — buton kalıcı devre dışı.** `_canSubmit` (L239) `_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty` döndürüyor, ama `TextField`'larda (L98-114) `onChanged` **yok** → yazı yazmak `setState` tetiklemiyor → buton devre dışı kalır. Yalnızca tarih/saat/ziyaretçi türü değiştirilirse (L52,253,258) rebuild olup buton aktifleşir. Kullanıcı "neden gönderemiyorum?" sıkışması. (Karşılaştırma: `create_request_screen.dart:115,132` `onChanged: (_) => setState(() {})` ile bunu doğru yapmış.)
2. **`requests_screen.dart` — form verisi kayboluyor.** Bottom sheet'teki `TextFormField`'lara (L88-102) controller/`onChanged` bağlı değil; "Gönder" (L114-117) yalnızca `Navigator.pop`. Kategori `_CategoryChip`'lerinin `onSelected: (selected) {}` (L307) → seçim hiç görünmez.
3. **`requests_screen.dart:18` — "Tamamlanmış" sekmesi yanıltıcı.** Aktif sekme her zaman "Aktif talebiniz bulunmamaktadır" (L163) — gerçek durumu yansıtmıyor.
4. **`energy_..._screen.dart` — sabit iddialar.** "%12 tasarruf" (L90) ve "Geçen aya göre ₺156.50 daha az" (L99) veriden hesaplanmıyor; `_currentUsage` değişse bile aynı kalır. `_monthlyTrend` çubukları `/320` ile normalize ediliyor (L154) — sabit ölçek, veri 320'yi aşarsa çubuk taşar.
5. **`create_reservation_screen.dart` — ücret hesabı yok.** `₺{price}/saat` gösteriliyor (L304) ama rezervasyon oluşturulurken toplam ücret hesaplanmıyor, kullanıcıya onaylatılmıyor, ödeme akışına bağlanmıyor. `'price': (item['hourly_fee'] ?? item['price'] ?? 0).toInt()` (L54) — sunucu `"150.00"` string dönerse `.toInt()` **NoSuchMethodError** atar.
6. **`create_reservation_screen.dart:109` — indeks taşması riski.** `_facilities[_selectedFacility]`; `_selectedFacility` bir kez seçildikten sonra liste yenilenip kısalırsa `RangeError`. (Şu an `_loadFacilities` bir kez çağrılıyor, risk düşük.)
7. **`package_tracking_...:67` — sınıflandırma boşluğu.** `status == 'arrived' && isPickedUp == false` / `'in_transit'` / `isPickedUp == true`. Bu üçüne girmeyen bir status (`returned`, `pending`) hiçbir bölümde görünmez — paket **sessizce kaybolur**. Toplam sayaç da (`L98-100`) eksik gösterir.
8. **`announcements_screen.dart:36` — okundu varsayılanı ters.** `'isRead': a['is_read'] ?? true` — sunucu alanı göndermezse duyuru **okunmuş** sayılır → okunmamış rozeti (L205-215) hiç görünmez. Güvenli varsayılan `false` olmalıydı.
9. **`package_tracking_...:34-36`, `bulletin_...:45-47`, `surveys_...:43` — uydurma varsayılanlar.** `p['arrived_at'] ?? '12:00'`, `p['arrived_date'] ?? 'Bugün'`, `p['estimated_date'] ?? 'Yakında'`, `b['author'] ?? 'Komşu'`, `b['unit'] ?? 'Blok'`, `s['end_date'] ?? 'Belirtilmemiş'`. Sunucu alanı göndermediğinde **kullanıcıya yanlış bilgi (uydurma saat/tarih) gösteriliyor** — "-" veya "bilinmiyor" yerine somut ama yalan veri.
10. **`main_screen.dart:15,57` — sekme indeksi route ile senkron değil.** Bkz. §İddia 6.
11. **`api_client.dart:79-81` `setToken`** — `await` edilmemiş `_storage.write`; hata sessizce yutulur (yine de hiç çağrılmıyor).
12. **`api_client.dart:58` — refresh için yeni `Dio` örneği** interceptor'sız oluşturuluyor; doğru (sonsuz döngüyü önler) ✅ ama timeout ayarları da yok → varsayılan sonsuz bekleme riski.
13. **Kullanıcı bilgisi 4 yerde tutarsız kopyalanmış:** "D.105 / A Blok" (`resident_home_screen.dart:16-17`, `profile_settings_screen.dart:22-23`) vs "Güneş Sitesi / A-3" (`more_screen.dart:44`) vs "Güneş Sitesi - A Blok No:3" (`home_screen.dart:20`).
14. **Çift/çelişkili ekranlar:** Aidat için `finance_screen.dart` + `dues_payment_screen.dart`; ayarlar için `more_screen.dart` + `profile_settings_screen.dart`; ana sayfa için `home_screen.dart` (ölü) + `resident_home_screen.dart`. Her çiftte iki farklı tasarım dili (Material vs Apple) ve iki ayrı bozuk logout.
15. **İki tema sistemi paralel:** `app_theme.dart` (Material 3, `main.dart`'ta kullanılıyor) ve `apple_theme.dart` (20 ekranda kullanılıyor, sabit açık renkler). Sonuç: tutarsız görünüm + karanlık mod bozukluğu (§5.6).
16. **Girdi doğrulama yok.** Telefon: yalnızca uzunluk ≥10 (`login_screen.dart:112-115`), maske/`inputFormatters` yok. Ziyaretçi telefonu (`visitor_...:104-108`) hiç doğrulanmıyor. Plaka (L110-114) doğrulanmıyor. Fiyat (`bulletin_...:432-440`) `keyboardType: number` ama negatif/çok büyük değer engellenmiyor ve **string olarak gönderiliyor** (`bulletin_...:354` `priceController.text`) — sunucu sayı bekliyorsa tip hatası.
17. **Şifremi Unuttum işlevsiz:** `login_screen.dart:156` `onPressed: () {}`. "Yöneticinize Başvurun" de aynı (L201).
18. **`api_client.dart`'ta hiç `debugPrint`/log yok** — üretimde hata teşhisi imkânsız. Crashlytics/Sentry de yok.

---

## 6. Ekran Bazlı Eksik Tamamlayıcı Özellikler

### Ana Sayfa (`resident_home_screen.dart`)
- ❌ Gerçek bakiye (`getDebtStatus` var, çağrılmıyor)
- ❌ "Aidat Öde" butonu çalışmıyor (L125) — `/finance/payment`'a gitmiyor
- ❌ 4 hızlı işlem + 4 servis kartı + bildirim ikonu + "Tümü" bağlantıları: 11 ölü `onTap`
- ❌ Pull-to-refresh
- ❌ Çoklu taşınmaz/daire seçici (`getUserProperties` var, çağrılmıyor)
- ❌ Yaklaşan rezervasyon/toplantı özeti
- ❌ Acil durum/güvenlik hızlı arama butonu

### Aidat/Ödeme (`finance_screen.dart` + `dues_payment_screen.dart`)
- ❌ **Gerçek ödeme (iyzico/3D Secure)** — en kritik eksik
- ❌ **Makbuz/dekont indirme veya paylaşma** (backend `GET /finance/assessments/:id` var)
- ❌ **Kısmi ödeme** — tutar hep tam borç, düzenlenebilir alan yok
- ❌ **Ödenecek kalem seçimi** — `createPayment` `assessmentIds` listesi alıyor (`api_client.dart:160`) ama UI'da checkbox yok
- ⚠️ **Gecikme faizi**: yalnızca hardcoded satır olarak gösteriliyor (`dues_payment_screen.dart:25`) — hesaplanmıyor, oran/gün bilgisi yok, yasal dayanak gösterilmiyor
- ❌ **Ödeme geçmişi** — buton `() {}` (L234); backend `GET /finance/payments` hazır
- ❌ Aidat detayı (hangi gider kalemi ne kadar) — `assessment_details` backend'de var
- ❌ Kayıtlı kart yönetimi (`saveCard` parametresi `api_client.dart:163`'te var, UI yok)
- ❌ Otomatik ödeme talimatı
- ❌ Yıl filtresi (`getAssessments({year})` var, UI yok)
- ❌ Kart girişi formu (kart no/SKT/CVV) — "Kredi Kartı" seçilse bile veri toplanmıyor

### Talepler (`requests_screen.dart` + `create_request_screen.dart`)
- ❌ **Gerçek liste** (`getRequests` çağrılmıyor)
- ❌ **Gerçek gönderim** (`createRequest` çağrılmıyor)
- ❌ **Fotoğraf eki** — 3 buton no-op (`create_request_screen.dart:204-206`), `image_picker` paketi yok, `CAMERA` izni yok. `createRequest` `photos` parametresi (`api_client.dart:194`) hazır ama besleyen kod yok
- ❌ Talep detay ekranı / durum geçmişi zaman çizelgesi (`onTap: () {}` `requests_screen.dart:250`)
- ❌ Yönetici yanıtları / mesajlaşma
- ❌ Durum filtresi (`getRequests({status})` var, UI yok)
- ❌ Talep numarası ile arama
- ❌ Talebi iptal etme / yeniden açma
- ❌ Konum alanı (`createRequest` `location` parametresi var, UI yok)
- ❌ Kategori listesi backend'den gelmiyor — hardcoded (2 ayrı dosyada 2 farklı liste: `requests_screen.dart:80-84` 5 kategori vs `create_request_screen.dart:20-27` 6 kategori) ve `categoryId` olarak gönderilecek gerçek UUID yok

### Duyurular (`announcements_screen.dart`)
- ❌ **Okundu bilgisi işaretleme** (backend `POST /announcements/:id/read` var)
- ❌ "Tümünü Oku" (L94 no-op)
- ❌ Paylaş butonu gerçek paylaşım yapmıyor (L300-304, `share_plus` yok)
- ❌ Ek dosya / görsel desteği
- ❌ Arama / kategori filtresi
- ❌ Pull-to-refresh, sayfalama
- ❌ Detay ekranında geri bildirim/yorum

### İlan Panosu (`bulletin_board_mobile_screen.dart`)
- ❌ **Çalışan API yolu** (404, §3.3)
- ❌ **Görsel/fotoğraf yükleme** — ilan formunda sadece başlık/açıklama/fiyat
- ❌ İlan sahibiyle iletişim — mesaj ikonu tıklanabilir değil (L524-528, `Container` içinde, `onTap` yok)
- ❌ Kendi ilanını düzenleme/silme (backend `DELETE /bulletins/:id` var)
- ❌ Görüntüleme sayacı artırımı (sadece okunuyor, L544)
- ❌ Arama, sıralama, boş durum
- ❌ Uygunsuz içerik şikayeti / moderasyon

### Enerji Tüketimi (`energy_consumption_mobile_screen.dart`)
- ❌ **Tüm veri gerçek API'den** (`getConsumptionSummary` çağrılmıyor)
- ❌ Dönem seçicisinin veriyi değiştirmesi (L112-114 ölü)
- ❌ Sayaç okuma geçmişi / fatura karşılaştırması
- ❌ `fl_chart` ile gerçek grafik (elle çizim, `/320` sabit ölçek)
- ❌ Site ortalamasıyla karşılaştırma
- ❌ Yüksek tüketim uyarısı
- ❌ Sayaç türü filtresi (`meterType` parametresi var, UI yok)

### Koli Takibi (`package_tracking_mobile_screen.dart`)
- ❌ **"Güvenliğe Haber Ver" gerçek çağrı** (backend `POST /packages/:id/notify` var)
- ❌ Takip no kopyalama (L409 no-op, `Clipboard.setData` yok)
- ❌ Kargo firması takip linkine yönlendirme
- ❌ Teslim aldım onayı (backend `POST /packages/:id/deliver` var)
- ❌ Vekil teslim yetkisi
- ❌ Bildirim (paket geldiğinde push — İddia 9)
- ❌ Gerçek zaman çizelgesi (ilk adım uydurma, L364)

### Rezervasyon (`create_reservation_screen.dart`)
- ❌ **Gerçek müsaitlik/saat slotları** (backend `/facilities/:id/availability` ve `/facilities/:id/slots` var; şu an hardcoded)
- ❌ **Mevcut rezervasyonlarımı listeleme** (`getReservations` çağrılmıyor)
- ❌ **Rezervasyon iptali** (`cancelReservation` çağrılmıyor)
- ❌ Ücretli tesis için ödeme akışı / toplam tutar onayı
- ❌ Kural/kapasite/kişi sayısı bilgisi
- ❌ Tekrarlayan rezervasyon
- ❌ Takvim görünümü (backend `GET /reservations/calendar` var)
- ❌ Onay bekleyen rezervasyon durumu gösterimi (backend `/pending`, `/:id/review` var)

### Ziyaretçi Ön Kayıt (`visitor_preregister_screen.dart`)
- ❌ **Gerçek kayıt** (`createVisitorPreRegistration` çağrılmıyor)
- ❌ **QR kod üretimi/gösterimi** — "QR kodlu link SMS ile gönderilecek" deniyor (L208) ama hiçbir QR yok; `qr_flutter` paketi yok; backend `GET /visitors/qr/:code` var
- ❌ Ziyaretçi listesi / geçmiş (`getVisitors` çağrılmıyor)
- ❌ Ön kaydı iptal etme
- ❌ Rehberden kişi seçme
- ❌ Telefon doğrulama/maske
- ❌ Tekrar eden ziyaretçi (temizlikçi vb.) kaydetme
- ❌ Giriş/çıkış bildirimi
- ⚠️ Buton kalıcı devre dışı hatası (§5.10-1)

### Anketler (`surveys_mobile_screen.dart`)
- ❌ **Çalışan oylama yolu** (404, §3.2)
- ❌ **`totalResidents` çökmesi giderilmeli** (§4.4)
- ❌ Çok soruluk anket / açık uçlu soru — yalnızca tek seçimli
- ❌ Oyu değiştirme / geri çekme (backend `GET /:id/my-vote` var)
- ❌ Anket sonuç detayı (backend `GET /:id/results` var)
- ❌ Anket ek dosyası (karar metni, teklif PDF'i)
- ❌ Bitiş tarihine kalan sürenin canlı hesabı (`daysLeft` sunucudan geliyor, yerel hesap yok)
- ❌ Kanun gereği oy ağırlığı (arsa payı) gösterimi
- ❌ Boş durum

### Belgeler (`documents_screen.dart`)
- ❌ **Tüm ekran gerçek API'ye bağlanmalı** (`/api/v1/documents` gateway'de proxy'li, hiç kullanılmıyor)
- ❌ **Gerçek dosya seçici** (`file_picker`/`image_picker` yok)
- ❌ **Gerçek indirme + PDF görüntüleme** (`dio.download`, `open_filex`, `flutter_pdfview` yok)
- ❌ Paylaşım (`share_plus` yok)
- ❌ Arama / kategori filtresi
- ❌ Yönetim onay durumu takibi (`status: 'pending'` yazılıyor ama sunucuya gitmiyor)
- ❌ Dosya boyutu/tipi doğrulama (sabit `'pdf'`, `'1.2 MB'` yazılıyor)
- ❌ Yükleme ilerleme çubuğu

### Varlıklar / Demirbaş (`assets_screen.dart`)
- ❌ **Tüm ekran gerçek API'ye bağlanmalı** (`/api/v1/assets` proxy'li, kullanılmıyor)
- ❌ **"Arıza bildir" → gerçek talep oluşturma** (`createRequest` ile bağlanmalı)
- ❌ Garanti bitiş uyarısı/bildirimi
- ❌ Bakım geçmişi ve sonraki bakım tarihi (`lastMaintenance: null` olan kayıtlar var, UI'da yok)
- ❌ Fatura/garanti belgesi eki
- ❌ Servis çağırma / yetkili servis bilgisi
- ❌ Yeni demirbaş ekleme
- ❌ QR/barkod ile demirbaş tanıma

### Profil/Ayarlar (`profile_settings_screen.dart` + `more_screen.dart`)
- ❌ **Gerçek kullanıcı bilgisi** (`getCurrentUser` çağrılmıyor)
- ❌ **Çalışan Çıkış Yap** — iki ekranda da no-op; `clearToken()` + `POST /auth/logout` gerekli
- ❌ **Profili Düzenle** (L62 no-op)
- ❌ **Şifre Değiştir** (L148 no-op) — backend uç noktası da yok
- ❌ Biyometrik anahtarının kalıcı olması (`setBiometricEnabled` çağrılmıyor)
- ❌ Bildirim tercihlerinin sunucuya yazılması
- ❌ Kullanım Koşulları / Gizlilik Politikası bağlantıları (L182-183 no-op) — `legal/` klasöründe belgeler var
- ❌ **KVKK hakları:** verilerimi indir / hesabımı sil (KVKK m.11 gereği) — hiç yok
- ❌ Verilen KVKK rızasını görüntüleme/geri çekme
- ❌ Dil/tema seçimi
- ❌ Yardım ve Destek (L181 no-op)
- ❌ Çoklu taşınmaz/daire değiştirme
- ❌ `more_screen.dart`'ın 10 menü öğesinin tamamı (§1)
- ❌ Uygulama sürümü sabit yazılmış (`'SiteEksen v1.0.0'` L213 ve `more_screen.dart:141`) — `package_info_plus` yok

---

## 7. Doğrulanamayanlar

Dürüstlük gereği, kanıtlayamadığım noktalar:

1. **`flutter analyze` / `flutter test` çıktısı** — doğrulanamadı: Flutter bu makinede kurulu değil (görev kısıtı). §4'teki uyarılar statik okuma ile tespit edildi, tam analyzer çıktısı değil.
2. **İstek/yanıt gövde şemalarının uyumu** — doğrulanamadı: yalnızca route yolları karşılaştırıldı. Handler gövdeleri (`handlers.*`) okunmadığı için `createReservation` (`facility_id`/`date`/`start_time`/`end_time`), `createBulletin` (`category`/`title`/`description`/`price`), `submitSurveyResponse` (`option_id`), `createPayment` (`assessment_ids`/`payment_method`/`card_token`/`save_card`) alan adlarının backend modelleriyle örtüştüğü doğrulanmadı. Yol düzeltilse bile alan uyuşmazlığı çıkabilir.
3. **`documents_screen.dart` 120-580 ve 720-986 aralıkları** — kısmen okundu (Grep ile tüm `onPressed`/`onTap`/`SnackBar`/`http` eşleşmeleri tarandı; ağ çağrısı yok olduğu kesin). `TabController.dispose()` varlığı doğrulanamadı.
4. **`assets_screen.dart` 120-436 aralığı** — kısmen okundu (Grep ile tüm etkileşim noktaları tarandı; ağ çağrısı yok olduğu kesin).
5. **`apple_widgets.dart` içerik detayı** — sınıf isimleri doğrulandı, gövdeleri okunmadı; kullanılan parametrelerin varlığı derleme açısından doğrulanmadı (ancak tutarlı kullanım gözlendi).
6. **Gateway'in kimlik doğrulama/CORS davranışı** ve `identityURL` vb. ortam değişkenlerinin gerçek dağıtımdaki değerleri — bu denetimin kapsamı dışında.
7. **`admin_app/`** — görev kapsamı `mobile/` olduğu için denetlenmedi; CHANGELOG'un admin_app iddiaları doğrulanmadı.
8. **Gerçek cihazda çalıştırma** — yapılmadı; §4.3 ve §4.4'teki runtime tespitleri kod analizine dayanıyor.

---

## 8. Öncelik Sıralı Düzeltme Listesi (öneri)

**P0 — Derlenmez / çalışmaz / yanıltır:**
1. `AndroidManifest.xml` (main) → `<uses-permission android:name="android.permission.INTERNET"/>` ekle. Release'de ağ yok.
2. `dues_payment_screen.dart:315-318` → sahte "Ödeme Başarılı" akışını kaldır; `apiClient.createPayment` + iyzico/3DS akışına bağla. Bağlanana kadar ekranı devre dışı bırak.
3. `surveys_mobile_screen.dart:163,256` → `totalResidents` map'lemesini ekle (veya `?? 0` + sıfıra bölme koruması). Şu an gerçek veri gelirse çöküyor.
4. `api_client.dart:5` → `baseUrl`'ü `String.fromEnvironment` / flavor ile yapılandırılabilir yap; `https` kullan.
5. `MainActivity.kt:5` → `FlutterFragmentActivity`'ye çevir; `USE_BIOMETRIC` izni ekle. Yoksa biyometrik hiç çalışmaz.
6. `api_client.dart:283-291` → `/bulletins` yerine gateway'de gerçekten yayınlanan yolu kullan (veya gateway'e `/api/v1/bulletins` proxy'si ekle).
7. `api_client.dart:260-263` → `/surveys/{id}/responses` → `/surveys/{id}/vote`.
8. `more_screen.dart:166-169` + `profile_settings_screen.dart:231-234` → `apiClient.clearToken()` + `POST /auth/logout` + `context.go('/login')`.
9. `test/widget_test.dart:16` → `MyApp` → `SiteEksenApp` (ve gerçek bir smoke test yaz). Şu an test hedefi derlenmiyor.

**P1 — Yaygın yanıltma / erişilemezlik:**
10. `more_screen.dart` 10 ölü `onTap` → `context.go(...)`; 12 ulaşılamaz route'u UI'a bağla (§1.1).
11. 5 gerçek-API ekranındaki `catch (_)` bloklarına hata state'i + "Tekrar Dene" ekle; `RefreshIndicator` ekle.
12. `app_router.dart:148-151` → auth + KVKK guard'ı yaz (`redirect`); `login_screen.dart:286-289` biyometrik yolunda KVKK kontrolü ekle.
13. `main.dart` → `hasStoredSession()` ile otomatik giriş (kalıcı oturum iddiasını gerçekleştir).
14. `create_request_screen.dart` + `visitor_preregister_screen.dart` + `documents_screen.dart` → sahte başarı diyaloglarını gerçek çağrılara bağla.
15. Ölü ekranları (`resident_home_screen`, `finance_screen`, `requests_screen`, `energy`, `documents`, `assets`, `profile`) mevcut `api_client` metotlarına bağla — 15 metot hazır bekliyor.

**P2 — Kalite / uyum:**
16. `main.dart` → `locale: Locale('tr','TR')` + `flutter_localizations` + `localizationsDelegates`; `intl` ile `NumberFormat.currency(locale:'tr_TR', symbol:'₺')`.
17. `main.dart:33` → `TextScaler.noScaling` kaldır (erişilebilirlik); `TextScaler.linear(...clamp)` kullan.
18. Tüm `TextEditingController`'lara `dispose`; pop-sonrası `context` kullanımlarını düzelt (§5.9).
19. Firebase Messaging'i gerçekten kur (init + `google-services.json` + `POST /devices/register` + gateway proxy'si + handler'lar + deep link).
20. `pubspec.yaml`'dan 13 ölü bağımlılığı kaldır **ya da** kullan (özellikle `intl`, `fl_chart`, `shimmer`, `retrofit`, `freezed`).
21. `ios/` klasörünü oluştur; `applicationId` ve release imzalama yapılandırmasını düzelt.
22. Riverpod mimarisini gerçekten kur (repository + `AsyncNotifier` provider'ları) veya bağımlılığı beyandan düşür.
