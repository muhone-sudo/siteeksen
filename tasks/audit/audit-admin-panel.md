# Admin Panel Denetimi (`admin/` — Next.js 14, SiteEksen)

Denetim tarihi: 2026-09-08
Kapsam: `admin/src` altındaki **16 sayfa** + `api-client.ts`, `hooks.ts`, `sidebar.tsx`, `header.tsx`, `middleware.ts`, NextAuth route.
Yöntem: her dosya satır satır okundu; backend endpoint envanteri `backend/cmd/gateway/main.go` + `backend/services/*/main.go` route kayıtlarından çıkarıldı.
Hiçbir dosya değiştirilmedi. `npm install` / `npm run build` çalıştırılmadı.

**ÖZET HÜKÜM:** Dokümanların "gerçek API'ye bağlandı ✅" iddiası panelin büyük kısmı için YANLIŞ. 16 sayfanın **6'sı hiç API çağırmıyor** (tamamı hardcoded), **6'sı API başarısız olunca sessizce uydurma veriye düşüyor** (mock fallback), yalnızca **2 sayfa** (residents, assessments) dürüst şekilde API'ye bağlı. Yazma işlemlerinin (create/update/delete) ezici çoğunluğu sadece React state'ini değiştiriyor — sayfa yenilenince kayboluyor, ama kullanıcıya "kaydedildi" gösteriliyor.

---

## 1. Sayfa Gerçeklik Tablosu

Dosyaların tamamı `admin/src/app/(dashboard)/dashboard/` altında (login ve layout bileşenleri hariç).

| Sayfa | Dosya | Veri kaynağı | Mock fallback? | Yazma gerçek? | Edit/Delete | CSV | GERÇEK DURUM |
|---|---|---|---|---|---|---|---|
| **Login** | `app/login/page.tsx` | NextAuth `signIn` → backend `/auth/login` | — | ✅ gerçek | — | — | **ÇALIŞIYOR** (ama şifre sunucu log'una yazılıyor, bkz. B-01) |
| **Dashboard** | `dashboard/page.tsx` | **YOK** — tamamen hardcoded (`page.tsx:26-53` stat, `:64-76` grafik, `:145-162` ödemeler, `:177-194` talepler) | Yok (hep mock) | — hiç yazma yok | ✗ | ✗ | **%100 SAHTE VİTRİN.** `"use client"` bile yok; tek API çağrısı yok. "Güneş Sitesi" adı `:19`'da sabit. |
| **Sakinler** | `residents/page.tsx` | ✅ Gerçek API (`:71` getResidents+getUnits) | **YOK** (`:74-79` hata → boş liste) | ✅ gerçek (`:122` update, `:124` create, `:144` soft-delete) | ✅ gerçek API | ✅ satır satır gerçek API (`:169`) | **EN İYİ SAYFA.** Loading/error/empty state var. Eksikler: pagination yok, edit'te sadece rol değişebiliyor (`:316-350` tüm alanlar `disabled`), pasif sakini geri alma UI'ı yok. |
| **Muhasebe** | `accounting/page.tsx` | **Hibrit/çoğunlukla mock**: gelirler `:23-26` mock, aidat kararları `:20-22` mock; sadece giderler `:68` API'den | ✅ **VAR** (`:70` boşsa + `:76` catch → mock kalır) | ✗ (`:112-113` create hatası yutulur, yine local'e eklenir; gelir/aidat kararı hiç API'ye gitmez) | ✗ sadece local (`:100`, `:110`, `:121-127`) | ✗ | **KRİTİK.** "Net Bakiye" mock gelir + kısmen gerçek giderden hesaplanıyor. Toplu işlemler uydurma tutar yazıyor (`:133` ₺12.500, `:134` ₺18.000). |
| **Gider Yönetimi** | `expenses/page.tsx` | Gerçek API (`:71`) | ✅ **VAR — EN AĞIR** (`:75-81` catch → ₺45.750 uydurma özet + 3 uydurma gider) | ✗ kısmen (`:96` create var ama `:98-100` hata → local'e eklenir; edit `:93` local; delete `:107` local) | ✗ frontend-only | ✗ CSV hiç API'ye gitmiyor (`:118-132`) | **KRİTİK.** Fatura yükleme alanı (`:284-287`) tamamen işlevsiz dekor. |
| **Aidatlar** | `assessments/page.tsx` | ✅ Gerçek API (hooks: `:76-79`) | **YOK** | ✅ gerçek (`:119` createAssessment) | ✗ **HİÇ YOK** | ✗ **HİÇ YOK** | **API'ye dürüst bağlı** ama iddia edilen edit/delete ve CSV yok. `isError` kullanılmıyor → hata "kayıt yok" gibi görünüyor. |
| **Sayaç Okuma** | `meters/page.tsx` | **YOK** — `:18-23` `initialMeters` | Yok (hep mock) | ✗ **hiç API yok**; `saveReadings` (`:51-64`) sadece state | ✗ frontend-only (`:77` `deleted:1`) | ✗ sadece local parse (`:95-119`) | **%100 MOCK.** `apiClient.submitMeterReadings` hiç çağrılmıyor (ve zaten 404 — bkz. §3). |
| **Duyurular** | `announcements/page.tsx` | **YOK** — `:23-27` `mockAnnouncements` | Yok (hep mock) | ✗ (`:79-87` local) | ✗ frontend-only (`:90`) | ✗ sadece local (`:53-68`) | **%100 MOCK.** Backend'de `POST/DELETE /announcements` VAR ama kullanılmıyor. |
| **Bildirimler** | `notifications/page.tsx` | Hibrit: geçmiş `:132` API dener; kitle grupları `:61-69` mock; otomasyonlar `:71-98` mock | ✅ **VAR** (`:134` boşsa + `:147` `.catch(() => {})` → mock geçmiş) | ✗ (`:189` `catch {}` → hata yutulur, modal kapanır, form temizlenir = "gönderildi" yanılgısı) | ✗ local (`:216`, `:221`) | ✗ | **KRİTİK.** Çağırdığı `/notifications/history` backend'de YOK → her zaman mock. "Zamanla" seçeneği (`:407-421`) yok sayılıp hemen gönderiliyor. |
| **Talepler** | `requests/page.tsx` | **YOK** — `:27-32` `mockRequests` | Yok (hep mock) | ✗ (`:101-112` local) | ✅ UI var, ✗ API yok (`:115`) | ✗ sadece local (`:69-85`) | **%100 MOCK.** Backend'de `PATCH /requests/:id/status` VAR ama kullanılmıyor. Yeni talep oluşturma butonu hiç yok. |
| **Otopark** | `parking/page.tsx` | Gerçek API (`:72`) | ✅ **VAR** (`:76-86` catch → uydurma 142 araç / %58 doluluk) | ✗ (`:101` create var, `:103-105` hata → local; edit `:98` local; delete `:112` local) | ✗ frontend-only | ✗ local (`:128-142`) | **KRİTİK + YANLIŞ ENDPOINT:** `:117` araç çıkışı için `checkOutVisitor()` (ziyaretçi endpoint'i) çağırıyor. Giriş kaydı UI'ı hiç yok. |
| **Personel** | `personnel/page.tsx` | Gerçek API (`:68`) | ✅ **VAR** (`:71-81` catch → 4 uydurma personel + maaş) | ✗ (`:96` create var, `:98-100` hata → local; edit `:93` local; delete `:107` local) | ✗ frontend-only | ✗ local (`:127-141`) | **KRİTİK.** İzin onayı `:112` `catch {}` yutuyor; izin reddi (`:116`) hiç API'ye gitmiyor (backend'de `/leaves/:id/reject` VAR). |
| **Rezervasyon** | `reservations/page.tsx` | Gerçek API (`:64`) | ✅ **VAR** (`:67-78` catch → 4 tesis + 3 rezervasyon uydurma) | ✗ (`:98` create var, `:100-102` hata → local; edit `:95` local; iptal `:108` `catch {}`) | ✗ frontend-only | — (iddia edilmemiş) | **KRİTİK.** Çakışma/çift-rezervasyon kontrolü yok. |
| **Ziyaretçi** | `visitors/page.tsx` | Gerçek API (`:70`) | ✅ **VAR** (`:73-80` catch → 3 uydurma ziyaretçi + istatistik) | ✗ (`:99` create var, `:101-103` hata → local; checkin/checkout `:109`/`:114` `catch {}`) | ✗ frontend-only | ✗ local (`:131-145`) | **KRİTİK.** Giriş/çıkış hata alsa bile ekranda "içeride/çıktı" gösteriliyor. |
| **Raporlar** | `reports/page.tsx` | **YOK** — `:54-103` `reportData` sabit | Yok (hep mock) | ✗ | ✗ | kısmî (sadece 2 sütunlu özet CSV) | **%100 MOCK + YALAN UX.** "Rapor Oluştur" → `alert()` (`:116`). "PDF İndir" ve "Excel İndir" ikisi de aynı **CSV**'yi indiriyor (`:213`,`:216`). "E-posta Gönder" → `alert("gönderildi")` (`:134`) hiçbir şey göndermiyor. |
| **Sistem Şifreleri** | `credentials/page.tsx` | **YOK** — `:53-60` `mockCredentials`, `:62-66` `mockLogs` | ✅ **VAR — EN TEHLİKELİ** (`:107-108` hata → **sahte şifre `"demo-sifre-2026"`** gösteriliyor) | ✗ (`:133` create local; `:142` edit local; `:149` delete local) | ✗ frontend-only | — | **KRİTİK.** `getApiCredentials/createApiCredential/deleteApiCredential` hiç çağrılmıyor. Audit log sadece React state (`:92-95`). |
| **Ayarlar** | `settings/page.tsx` | **YOK** — `:17-39` hardcoded | Yok (hep mock) | ✗ **HİÇBİRİ** | ✗ frontend-only (`:77`) | ✗ | **%100 MOCK + YALAN UX.** `handleSaveGeneral` (`:41-44`) hiçbir şey kaydetmeden **"Kaydedildi"** yazıyor. Entegrasyon durumları (`:246-248`) sabit "Bağlı". Fatura/plan bilgisi (`:276-294`) uydurma. |
| **Header** (her sayfada) | `components/layout/header.tsx` | **YOK** | — | — | — | — | Kullanıcı adı/rolü `:37`,`:40`'ta **sabit "Ahmet Yılmaz / Yönetim Kurulu Başkanı"**. Arama input'u (`:17`) `value`/`onChange` yok. Mobil menü (`:9`), zil (`:28`), profil (`:43`) butonlarının `onClick`'i yok. **ÇIKIŞ (logout) BUTONU HİÇ YOK.** |
| **Sidebar** | `components/layout/sidebar.tsx` | ✅ Gerçek API (`:71` getUserProperties) | **YOK** (`:77` hata → boş) | ✅ gerçek (`:86` setActiveProperty, `:101` createProperty) | — | — | **ÇALIŞIYOR.** Tek gerçek istisna. `hidden lg:flex` (`:112`) → mobilde navigasyon tamamen yok. |

**Sayaç:** API'ye hiç dokunmayan sayfa: **6** (dashboard, meters, announcements, requests, reports, settings) + header.
Mock fallback'i olan sayfa: **6** (expenses, accounting, personnel, parking, reservations, visitors) + credentials (sahte şifre) + notifications (mock geçmiş) = **8**.
Yazma işlemi gerçekten backend'e giden sayfa: **3** (residents, assessments, sidebar).

---

## 2. İddia Doğrulama

### İddia 1 — Sayfa listesi ✅ / Muhasebe-Bildirimler-Credentials çelişkisi
**Kaynak:** `ROADMAP.md:68-79` (Login/Dashboard/Sakinler/Aidatlar/Sayaçlar/Talepler/Duyurular/Raporlar/Ayarlar = ✅; Muhasebe/Bildirimler/API Kimlik = 🔄) vs `ROADMAP.md:84-85` + `CHANGELOG.md:56-57` ("backend'e bağlandı ✅") + `tasks/todo.md:23-35`.
**Verdict: HER İKİ TARAF DA YANLIŞ — çelişki gerçek ama iki iddia da gerçeği yansıtmıyor.**
**Kanıt ve gerçek durum:**
- ROADMAP `:69` "Dashboard ✅" → `dashboard/page.tsx` içinde tek API çağrısı yok, `"use client"` yok, veriler `:26-53`/`:64-76`/`:145-194`'te literal. **✅ tamamen hatalı.**
- ROADMAP `:72` "Sayaçlar ✅" ve `:73` "Talepler ✅", `:74` "Duyurular ✅", `:75` "Raporlar ✅", `:76` "Ayarlar ✅" → beşi de `api-client`/`hooks` import etmiyor (grep: import listesinde yok). **Beş ✅ hatalı.**
- ROADMAP `:77` "Muhasebe 🔄 backend eksik" vs `ROADMAP.md:84` "Muhasebe backend'e bağlandı ✅" → **kısmen doğrusu 🔄'dur**: `accounting/page.tsx:68` yalnızca `getExpenses()` okuyor; gelirler ve aidat kararları hiç API görmüyor.
- ROADMAP `:78` "Bildirimler 🔄" vs `:85` "bağlandı ✅" → **doğrusu 🔄'dan da kötü**: `notifications/page.tsx:132` `getNotificationHistory()` çağırıyor ama bu endpoint **backend'de yok** (`/notifications/history` — §3), yani bağlantı hiç kurulamıyor.
- ROADMAP `:79` "API Kimlik Bilgileri 🔄" → **doğrusu 🔄**, `todo.md:39`'daki "✅ Göster butonuna basılınca API'den çek + audit log" yanlış.
**Sonuç:** ROADMAP'in 🔄 işaretleri (Muhasebe/Bildirimler/Credentials) daha dürüst; ✅ işaretlerinin 6'sı asılsız. todo.md/CHANGELOG'un "bağlandı" iddiaları asılsız.

### İddia 2a — "Veriyi gerçek API'den çekiyor"
**Verdict: KISMEN (16 sayfanın 8'i API'ye dokunuyor, 6'sı hiç dokunmuyor).**
**Kanıt:** `api-client`/`hooks` import eden dosyalar: accounting`:4`, parking`:5`, expenses`:5`, credentials`:4`, notifications`:4`, personnel`:5`, residents`:5`, reservations`:5`, visitors`:5`, assessments`:5`. Import ETMEYEN: `dashboard/page.tsx`, `meters/page.tsx`, `announcements/page.tsx`, `requests/page.tsx`, `reports/page.tsx`, `settings/page.tsx`, `header.tsx`.

### İddia 2b — Mock fallback (KRİTİK)
**Verdict: ONAYLANDI — 8 yerde sessiz mock fallback var. En kritik bulgu.**
**Kanıt (dosya:satır):**
| Yer | Kod | Kullanıcıya gösterilen sahte veri |
|---|---|---|
| `expenses/page.tsx:75-81` | `catch { setExpenses([...]); setSummary({total_expenses: 45750, ...}) }` | **₺45.750 toplam gider, ₺42.150 faturalı** — tamamen uydurma mali tablo |
| `expenses/page.tsx:98-100` | create hata → `setExpenses(prev => [{id: Date.now(), ...form}])` | Kaydedilmemiş gider "kaydedildi" gibi listede |
| `personnel/page.tsx:71-81` | `catch { setEmployees([4 kişi + maaşlar]) }` | Uydurma personel + ₺76.000 maaş toplamı |
| `parking/page.tsx:76-86` | `catch { ... setStats({total_vehicles:142, occupancy_rate:58}) }` | Uydurma 142 araç / %58 doluluk |
| `reservations/page.tsx:67-78` | `catch { setFacilities([4]); setReservations([3]) }` | Uydurma tesis ve rezervasyonlar |
| `visitors/page.tsx:73-80` | `catch { setVisitors([3]); setStats({total_today:8,...}) }` | Uydurma ziyaretçi kayıtları |
| `accounting/page.tsx:70,76` | `if (length > 0) {...} .catch(() => {})` | Mock gelir/gider korunur, Net Bakiye sahte |
| `notifications/page.tsx:134,147` | `if (length > 0)` + `.catch(() => {})` | Mock gönderim geçmişi (18/124 kişiye gönderilmiş gibi) |
| `credentials/page.tsx:107-108` | `catch { setRevealedPasswords({[id]: "demo-sifre-2026"}) }` | **Sahte ŞİFRE gerçek şifre gibi gösteriliyor** |
**Neden kritik:** Kullanıcı (site yöneticisi) mali kararları bu ekranlara bakarak alıyor. Backend kapalı/401 olduğunda hiçbir uyarı yok — ekran normal görünüyor. Tek bir `isError` göstergesi, retry butonu veya "veri alınamadı" uyarısı yok.

### İddia 2c — "Yazma işlemleri gerçek API'ye gidiyor"
**Verdict: YANLIŞ.** 16 sayfada yalnızca 4 gerçek yazma yolu var: `residents` (create/update/soft-delete), `assessments` (create), `sidebar` (createProperty/setActiveProperty), `notifications` (send — ama hatası yutuluyor).
**Kanıt:** Tüm `edit` yolları local: `expenses:93`, `accounting:100/110`, `parking:98`, `personnel:93`, `reservations:95`, `visitors:96`, `meters:71`, `announcements:82`, `requests:104`, `settings:66`, `credentials:142`. Tüm `delete` yolları local (§İddia 3).
**En sinsi kalıp** — `try { await api(...) } catch {}` sonra koşulsuz local güncelleme: `accounting:112-113`, `personnel:112-113`, `parking:117-118`, `visitors:109-110`/`114-115`, `reservations:108-109`, `notifications:189`. Hata olsa da olmasa da UI "başarılı" gösteriyor.

### İddia 3 — "Tüm sayfalara edit/delete + soft-delete (deleted=1)"
**Kaynak:** `CHANGELOG.md:42` ("tüm silmeler soft-delete (deleted=1)"), `tasks/todo.md:24-35`.
**Verdict: YANLIŞ — soft-delete yalnızca 1 sayfada backend'e gidiyor.**
| Sayfa | UI'da var? | Backend'e gidiyor mu? | Kanıt |
|---|---|---|---|
| residents | ✅ | ✅ `updateResident(id,{is_active:false})` | `residents:144` |
| assessments | ❌ **hiç yok** | — | dosyada delete/edit handler yok |
| meters | ✅ | ❌ | `meters:77` `setMeters(... deleted:1)` |
| announcements | ✅ | ❌ | `announcements:90` |
| requests | ✅ | ❌ | `requests:115` |
| accounting | ✅ | ❌ | `accounting:123-125` |
| expenses | ✅ | ❌ | `expenses:107` |
| notifications | ✅ | ❌ | `notifications:221` |
| parking | ✅ | ❌ | `parking:112` |
| personnel | ✅ | ❌ | `personnel:107` |
| reservations | ✅ | ❌ | `reservations:114` |
| visitors | ✅ | ❌ | `visitors:120` |
| settings | ✅ | ❌ | `settings:77` |
| credentials | ✅ | ❌ | `credentials:149` |
**Gerçek durum:** 13/14 sayfada silme **SAHTE**. `deleted: 1` yalnızca React state'inde; F5 sonrası kayıt geri geliyor. Kullanıcıya onay modalı gösterilip "silinecek" deniyor (örn. `credentials:410` "bu kayıt silinecek ve işlem loglanacak") — hiçbiri gerçekleşmiyor.
**Ek:** Backend'de bu DELETE endpoint'lerinin çoğu MEVCUT (`DELETE /expenses/:id`, `/vehicles/:id`, `/employees/:id`, `/reservations/:id`, `/visitors/:id`, `/announcements/:id`, `/credentials/:id`) ama `api-client` bunların bir kısmına metot tanımlamış olsa da sayfalar hiç çağırmıyor. Yani "backend yok" mazereti geçerli değil.

### İddia 4 — CSV upload/download (9 sayfa, "gerçek CSV işleme")
**Kaynak:** `CHANGELOG.md:44`, `tasks/todo.md:16`.
**Verdict: KISMEN YANLIŞ.** Örnek CSV indirme 9/9 var; **gerçek CSV yükleme yalnızca 1/9**.
| Sayfa | Örnek CSV indir | Yükleme API'ye gidiyor mu? | Kanıt |
|---|---|---|---|
| residents | ✅ `:37-42` | ✅ **satır satır** `createResident` | `residents:168-170` |
| expenses | ✅ `:111` | ❌ sadece local state | `expenses:128` |
| parking | ✅ `:121` | ❌ | `parking:138` |
| personnel | ✅ `:120` | ❌ | `personnel:137` |
| visitors | ✅ `:124` | ❌ | `visitors:141` |
| meters | ✅ `:88` | ❌ | `meters:115` |
| **assessments** | ❌ **hiç yok** | ❌ | dosyada CSV kodu yok |
| announcements | ✅ `:46` | ❌ | `announcements:64` |
| requests | ✅ `:62` | ❌ | `requests:81` |

**CSV parse sağlamlığı — 9 sayfanın tamamında aynı ilkel kod:**
| Kriter | Durum | Kanıt |
|---|---|---|
| Virgüllü/tırnaklı alan (`"Temizlik A.Ş., İstanbul"`) | ❌ **BOZULUR** — `line.split(",")` hiçbir yerde tırnak farkındalığı yok | `expenses:125`, `residents:162`, `parking:135`, `personnel:134`, `visitors:138`, `meters:102`, `announcements:61`, `requests:78` |
| Başlık doğrulama | ❌ **YOK** — `.slice(1)` ile ilk satır koşulsuz atılır; başlıksız dosyada ilk gerçek kayıt sessizce silinir; yanlış kolon sıralı dosya sessizce yanlış alanlara yazar | aynı satırlar |
| Encoding / Türkçe karakter | ⚠️ Kısmî — `readAsText(file)` çağrısı **encoding parametresiz** (`residents:177`, `expenses:130`, vb.) → UTF-8 varsayılır; Excel'in Türkiye'de ürettiği Windows-1254/ISO-8859-9 CSV'de "ı/ğ/ş/İ" bozulur. İndirilen örnek CSV'lerde BOM yok (`Blob([SAMPLE_CSV], {type:"text/csv;charset=utf-8;"})`) → Excel'de açıldığında Türkçe karakter bozuk görünür |
| Hatalı satır raporlama | ❌ **YOK** — hiçbir sayfada satır numarası/hata listesi yok. `residents:167` tek genel mesaj ("CSV boş veya hatalı format"), diğer 8 sayfada hiç hata mesajı yok |
| Kısmî başarı yönetimi | ❌ **YOK.** `residents:168-170` sıralı `await` döngüsü: 3. satır 400 dönerse `catch`'e atlar, 4+ satırlar hiç gönderilmez ama 1-2 **zaten oluşturulmuştur**. Kullanıcı kaç kaydın gittiğini bilemez. `residents:174` mesajı "içe aktarılamadı" diyor — halbuki kısmen aktarılmış. |
| CRLF (`\r\n`) | ❌ `split("\n")` sonrası son alanda `\r` kalır. `announcements:61`/`requests:78` `.map(s => s.trim())` ile kurtarır; `meters:102`, `expenses:125`, `parking:135`, `personnel:134`, `visitors:138` alan bazında `.trim()` yapar → çoğunda kurtarılıyor ama `residents:162` `role` alanı trim'li, tolere ediliyor |
| Kullanılabilirlik | ❌ `residents` örnek CSV'si (`:33-35`) **`<unit-uuid>` placeholder** istiyor — site yöneticisinin daire UUID'lerini elle yazması gerekiyor, pratikte kullanılamaz |

### İddia 5 — "Credentials güvenlik: şifreler açılışta yüklenmez, 'Göster' ile çekilir + audit log"
**Kaynak:** `tasks/todo.md:14`, `tasks/todo.md:39`.
**Verdict: YANLIŞ (yarısı doğru, kritik yarısı sahte).**
- ✅ **DOĞRU:** Şifreler sayfa açılışında yüklenmiyor — `mockCredentials` (`credentials:53-60`) içinde `password` alanı yok, `revealedPasswords` başlangıçta boş (`:83`).
- ❌ **YANLIŞ — "API'den çekilir":** `:104` `apiClient.testApiCredential(String(credential.id))` çağırıyor. Bu **POST `/credentials/:id/test`** = *bağlantı testi* endpoint'i, şifre döndürme endpoint'i değil. Backend'de **reveal endpoint'i hiç yok** (envanterde `/credentials/:id/reveal` yok). Ayrıca `credential.id` local bir sayı (1..6 veya `Date.now()`), backend UUID'si değil → istek zaten 404.
- ❌ **KRİTİK — sahte şifre:** `:107-108` `catch { setRevealedPasswords({[id]: "demo-sifre-2026"}) }` → istek her zaman başarısız olacağı için kullanıcı **her "Göster"de sabit sahte şifre** görüyor, hata uyarısı yok. Bu şifreyi gerçek sanıp sisteme girmeye çalışır.
- ❌ **YANLIŞ — audit log backend'e yazılmıyor:** `writeLog` (`:92-95`) yalnızca `setAccessLogs(prev => [log, ...prev])`. Hiçbir API çağrısı yok; `mockLogs` (`:62-66`) ile başlıyor; F5'te tüm log kaybolur. Backend'de yazma endpoint'i de yok (yalnızca okuma: `GET /credentials/:id/audit-log`).
- ❌ **Ek güvenlik açığı:** `:134` yeni kayıt eklenirken **düz metin şifre** `revealedPasswords` state'ine yazılıyor, backend'e hiç gönderilmiyor. Yani şifreler hiç saklanmıyor ama tarayıcı hafızasında açıkta.
- ❌ **Ek hata:** `copyToClipboard` (`:115-117`) şifre görünür değilse panoya literal `"••••••••"` kopyalıyor ve buna rağmen "copy" log'u yazıyor.
- ❌ **Rol kontrolü yok:** `accessLevel` (`:19`, `:271-276`) sadece etiket olarak gösteriliyor; hiçbir yerde kontrol edilmiyor. Giriş yapan herkes tüm kayıtları görüp "Göster"e basabilir.

### İddia 6 — api-client ↔ backend uyuşması
**Verdict: KISMEN.** 51 metodun 5'i var olmayan endpoint'e gidiyor, 13'ü hiç çağrılmıyor. Detay §3.

### İddia 7 — Token refresh ("401'de refresh, başarısızsa login'e")
**Kaynak:** `CHANGELOG.md:73`.
**Verdict: KISMEN — çalışır ama race condition ve döngü riski var.**
**Kanıt:** `api-client.ts:24-55`.
- ✅ Temel akış doğru: `:28` 401 + `!_retry` → `:36` refresh → `:39` setToken → `:43-44` isteği tekrarla; `:45-50` başarısızsa temizle + `/login`.
- ❌ **RACE CONDITION VAR (`:28-44`):** `_retry` bayrağı **istek bazında** (`originalRequest._retry`), global değil. Sayfa açılışında paralel `Promise.all` çağrıları var (`residents:71`, `expenses:71`, `personnel:68`, `parking:72`, `visitors:70`, `reservations:64`). Token süresi bittiğinde **hepsi aynı anda 401** alır → her biri ayrı `/auth/refresh` POST'u atar (N eşzamanlı refresh). Backend refresh-token rotasyonu yapıyorsa (`:37`'de yeni `refresh_token` dönüyor → rotasyon var) ilk refresh eskisini geçersiz kılar, kalan N-1 refresh **401 alır** → `:46-49` tüm oturumu temizleyip `/login`'e atar. **Kullanıcı rastgele oturum düşmeleri yaşar.** Çözüm: paylaşılan `refreshPromise` singleton'ı (mevcut değil).
- ❌ **SONSUZ DÖNGÜ RİSKİ (`:36`):** Refresh isteği `this.client.post(...)` ile — **aynı interceptor'a sahip instance** üzerinden atılıyor. `/auth/refresh` 401 dönerse o istek de interceptor'a girer; `_retry` bayrağı ilk kez tanımsız olduğu için bir kez daha refresh denenir (1 seviye özyineleme). `catch` blokla sınırlanıyor ama refresh çağrıları için ayrı, interceptor'sız bir axios instance kullanılmalı.
- ❌ **YÖNLENDİRME DÖNGÜSÜ:** `:49` `window.location.href = "/login"`. `middleware.ts:11-13` geçerli NextAuth cookie'si varsa `/login` → `/dashboard`'a geri atıyor. NextAuth cookie'si 7 gün geçerli (`route.ts:88`) ama backend access token'ı çok daha kısa ömürlü. Sonuç: backend token'ı ölmüş + NextAuth cookie'si canlı → `/dashboard` ⇄ `/login` **yönlendirme döngüsü**.
- ❌ **`_retry` sonrası yutma:** `:45-51` `catch` bloğu bir değer döndürmüyor → `undefined`'a düşer, ardından `:53` `Promise.reject(error)` çalışır. Kabul edilebilir, ama `originalRequest._retry` zaten `true` ise ikinci 401'de refresh denenmez ve hata sessizce sayfaların `catch`'ine düşer → mock fallback devreye girer. **401 → sahte veri** zinciri tam burada kapanıyor.

### İddia 8 — NextAuth ↔ apiClient token köprüsü "sadece Sidebar'da"
**Kaynak:** `CHANGELOG.md:28`.
**Verdict: DOĞRU — ve bu ciddi bir mimari kusur.**
**Kanıt:**
- Köprü tek yerde: `sidebar.tsx:65-78`, özellikle `:68` `apiClient.setToken(session.accessToken, session.refreshToken)`. Tüm kod tabanında `setToken` çağrısının başka yeri yok (`api-client.ts:94` içindeki `login()` metodu **hiç kullanılmıyor** — login NextAuth `route.ts:27` içinde ayrı `fetch` ile yapılıyor).
- ❌ **YARIŞ (race) — sayfa ilk yüklemesi token'sız gider:** `sidebar.tsx:66` `if (status !== "authenticated" || !session?.accessToken) return;`. İlk client render'da `useSession()` durumu `"loading"` → köprü kurulmaz. Aynı anda sayfaların mount effect'i çalışır (`residents:63-66`, `expenses:63-66`, `personnel:60-63`, `parking:64-67`, `visitors:62-65`, `reservations:56-59`, `accounting:66-77`, `notifications:130-148`) ve `apiClient.loadToken()` ile `localStorage`'dan okur. **Ancak `localStorage.access_token` NextAuth login akışında hiç yazılmaz** (yazan tek yer `setToken`). Temiz tarayıcıda ilk `/dashboard/...` ziyaretinde `accessToken = null` → `Authorization` header'ı yok (`:17-22`) → 401 → refresh token da yok (`:34`) → `clearToken()` + `/login`. `middleware` geri `/dashboard`'a atar. **İlk yükleme kırılgan.**
- ❌ **Assessments hiç `loadToken()` çağırmıyor:** `assessments/page.tsx` TanStack Query'yi mount'ta tetikliyor (`:76-79`) ama ne `loadToken()` ne `useSession()` var → tamamen Sidebar'ın önce çalışmasına bağlı.
- ❌ **Yenilenmiş token'ın geri ezilmesi:** `sidebar.tsx:78` bağımlılık dizisi `[status, session]`. NextAuth `session` nesnesi periyodik olarak yeniden getirildiğinde effect tekrar çalışır ve **JWT içindeki eski `accessToken`'ı** `setToken`'a yazar. NextAuth `jwt` callback'i (`route.ts:62-71`) access token'ı **hiç yenilemiyor** — sadece ilk login'de yazıyor. Yani interceptor'ın `:39`'da tazelediği token, Sidebar tarafından 7 gün boyunca eski token'la geri eziliyor. **Token yenileme kalıcı değil.**
- ❌ **XSS RİSKİ — token localStorage'da:** `api-client.ts:60-63` hem `access_token` hem `refresh_token`'ı `localStorage`'a yazıyor. `:31-33`, `:41`, `:48`, `:68-70`, `:76` da localStorage kullanıyor. Herhangi bir XSS 7 günlük refresh token'ı çalabilir. NextAuth zaten httpOnly cookie kullanıyor — bu ikinci, güvensiz kopya gereksiz.
- ⚠️ **Auth config:** `route.ts:90` `secret: process.env.NEXTAUTH_SECRET` — fallback yok (iyi). Ancak `docker-compose.yml:196` `NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:-your-nextauth-secret-change-in-production}` → **compose ile ayağa kalkan ortam varsayılan, herkese açık bir secret ile çalışır.** Bu secret'la JWT üretilebilir = kimlik taklidi.
- ❌ **`getActivePropertyId` doğrulamasız JWT decode:** `api-client.ts:80-88` `atob(token.split(".")[1])` ile imza doğrulamadan payload okuyor. Görüntüleme amaçlı olduğu için düşük risk, ama `atob` UTF-8 güvenli değil (Türkçe karakterli property adında bozulur).

### İddia 9 — "Sidebar site/apartman seçici gerçek backend'e bağlandı" + "Yeni site ekleme"
**Verdict: DOĞRU.** Panelde tam çalışan tek uçtan uca akış.
**Kanıt:** `sidebar.tsx:71` `getUserProperties()` → backend `GET /api/v1/users/me/properties` (identity/main.go:54) ✅. `:86` `setActiveProperty()` → `POST /users/me/active-property` (identity:56) ✅. `:101` `createProperty()` → `POST /users/me/properties` (identity:55, `RequireRole MANAGER|OWNER`) ✅. Hata durumunda `alert()` ile kullanıcı bilgilendiriliyor (`:90`, `:106`) — mock fallback YOK.
**Küçük kusurlar:** `:88`/`:104` `window.location.reload()` — TanStack Query cache invalidation yerine tam sayfa yenileme (kaba ama çalışır). `:128` liste boşken `"Yükleniyor..."` gösteriyor — hata durumunda (`:77` `setSites([])`) da sonsuza kadar "Yükleniyor..." yazar, hata mesajı yok. `alert()` kullanımı (`:90`,`:106`) tutarsız UX.

### İddia 10 — "Input/form denetimi turu yapıldı, başka eksik bulunamadı"
**Kaynak:** `CHANGELOG.md:36-37`, `tasks/todo.md:134-135`.
**Verdict: YANLIŞ — kendi taramamda 12+ işlevsiz eleman bulundu.**
| # | Eleman | Dosya:satır | Sorun |
|---|---|---|---|
| 1 | Mobil menü butonu | `header.tsx:9` | `onClick` yok. Sidebar `hidden lg:flex` (`sidebar.tsx:112`) → **mobil/tablette navigasyon tamamen erişilemez** |
| 2 | Global arama input'u | `header.tsx:17-21` | `value` ve `onChange` yok, controlled değil, hiçbir şey aramıyor |
| 3 | Bildirim zili | `header.tsx:28-31` | `onClick` yok; `:30` kırmızı okunmamış noktası **koşulsuz** gösteriliyor (sahte badge) |
| 4 | Profil avatarı | `header.tsx:43-45` | `onClick` yok — profil/çıkış menüsü yok |
| 5 | **Çıkış (logout)** | — | `signOut` tüm kod tabanında **hiç çağrılmıyor** (grep: yalnızca `api-client.ts:99` `logout()` metodu, o da kullanılmıyor). **Kullanıcı oturumu kapatamıyor.** |
| 6 | "Beni hatırla" checkbox | `login/page.tsx:116-119` | `checked`/`onChange` yok, state'e bağlı değil, hiçbir etkisi yok |
| 7 | "Şifremi unuttum" | `login/page.tsx:124-129` | `href="#"` — ölü link |
| 8 | "Yöneticinize başvurun" | `login/page.tsx:165-167` | `href="#"` — ölü link |
| 9 | Fatura yükleme alanı | `expenses/page.tsx:284-287` | `border-dashed` + `cursor-pointer` ile yükleme alanı gibi görünen `div`; **ne `<input type=file>` ne `onClick` ne `onDrop`** var. Tam dekor. |
| 10 | "Rapor Oluştur" | `reports/page.tsx:156-161` → `:115-117` | Sadece `alert("...oluşturuluyor")`. `apiClient.generateReport` var, çağrılmıyor. |
| 11 | "PDF İndir" / "Excel İndir" | `reports/page.tsx:213`, `:216` | İkisi de aynı `downloadReportCSV`'yi çağırıyor → **PDF butonuna basınca CSV iniyor** (`:127` `.csv` uzantısı). Etiket yalan. |
| 12 | "E-posta Gönder" | `reports/page.tsx:219` → `:132-135` | `alert("raporu yönetim e-posta adresine gönderildi")` — **hiçbir şey göndermiyor, olmuş gibi bildiriyor.** |
| 13 | "Değişiklikleri Kaydet" | `settings/page.tsx:177` → `:41-44` | Hiçbir şey kaydetmiyor, `setGeneralSaved(true)` ile **"Kaydedildi"** yazıyor |
| 14 | Bildirim ayarı checkbox'ları | `settings/page.tsx:193-198` → `:46-48` | Sadece local state, hiçbir yere kaydedilmiyor, kaydet butonu bile yok |
| 15 | Entegrasyon kartları | `settings/page.tsx:244-267` | Durumlar (`connected`/"Bağlı") **hardcoded**; test/bağlan butonu yok |
| 16 | Zaman dilimi select | `settings/page.tsx:166-172` | Tek seçenek var (`Europe/Istanbul`), `onChange` işe yaramıyor |
| 17 | Rapor kartı seçimi | `reports/page.tsx:168-175` | `<div onClick>` — klavye erişilemez (`role`/`tabIndex`/`onKeyDown` yok) |
| 18 | Ölü modül seviyesi kod | `credentials/page.tsx:452` | `actionLabels` hem `:180`'de (component içi) hem `:452`'de (modül) tanımlı; `:452` hiç kullanılmıyor |
`defaultValue`/`defaultChecked` ile uncontrolled kalmış input: **bulunmadı** (bu iddia doğru).

---

## 3. `api-client.ts` ↔ Backend Endpoint Uyuşmazlıkları

Backend gerçeği: gateway (`backend/cmd/gateway/main.go`) **yol yeniden yazımı yapmıyor**, `/api/v1` prefix'i olduğu gibi servise iletiliyor.

### 3a. VAR OLMAYAN ENDPOINT'E GİDEN METOTLAR (404/405 garantili)

| Metot | api-client:satır | Çağırdığı yol | Backend'de var mı | Sonuç |
|---|---|---|---|---|
| `submitMeterReadings` | `:213-220` | `POST /meters/readings` | ❌ Backend yalnızca `POST /api/v1/meters/:id/readings` (iot/main.go:25). 2-segment yol 3-segment route'a uymaz | **404.** Ayrıca `meters/page.tsx` bu metodu hiç çağırmıyor → ölü + bozuk. `ROADMAP.md:96` "meters gerçek save readings ✅" **YANLIŞ**. |
| `getNotificationHistory` | `:328-331` | `GET /notifications/history` | ❌ En yakını `GET /api/v1/notifications/logs` (notification:46) | **404 — VE ÇAĞRILIYOR** (`notifications/page.tsx:132`). Bu yüzden gönderim geçmişi **her zaman** mock kalıyor (`:147` `.catch(() => {})`). `CHANGELOG.md:57` iddiası bu tek satırla çürüyor. |
| `getNotifications` | `:313-316` | `GET /notifications` | ❌ Root list route yok (yalnızca `/logs`, `/stats`) | **404.** Hiç çağrılmıyor → ölü kod. |
| `assignRequest` | `:262-267` | `PATCH /requests/:id/assign` | ❌ community servisinde assign route'u yok | **404.** Hiç çağrılmıyor → ölü kod. Talep atama özelliği backend'de de yok. |
| `deleteApiCredential` | `:355-357` | `DELETE /credentials/:id` | ✅ VAR (settings:632) | Endpoint doğru ama **hiç çağrılmıyor** — `credentials:149` local silme yapıyor. |

### 3b. YANLIŞ ENDPOINT KULLANIMI (endpoint var, amaç yanlış)

| Yer | Ne yapıyor | Sorun |
|---|---|---|
| `credentials/page.tsx:104` | Şifre göstermek için `testApiCredential()` → `POST /credentials/:id/test` | Bu **bağlantı testi** endpoint'i; şifre döndürmez. Backend'de reveal endpoint'i **yok**. Üstelik `credential.id` local sayı, backend UUID değil → 404 → `:108` sahte şifre. |
| `parking/page.tsx:117` | Araç otopark çıkışı için `checkOutVisitor(id)` → `POST /visitors/:id/checkout` | **Tamamen farklı domain.** Doğrusu `POST /api/v1/parking-logs/exit/:id` (parking:154) — `api-client`'ta bu metot **hiç yok**. |

### 3c. BACKEND'DE VAR AMA `api-client`'TA METODU OLMAYAN (bu yüzden sayfalar local'e düşüyor)

| Backend endpoint | Kanıt | Eksik olduğu için |
|---|---|---|
| `PUT /api/v1/expenses/:id` | expense:100 | `expenses:93` ve `accounting:110` edit'i local yapıyor |
| `DELETE /api/v1/expenses/:id` | expense:101 | `expenses:107` silme local |
| `PATCH /api/v1/expenses/:id/status` | expense:102 | Gider onaylama/reddetme UI'ı hiç yok |
| `PUT /api/v1/vehicles/:id` | parking:130 | `parking:98` edit local |
| `POST /api/v1/parking-logs/exit/:id` | parking:154 | `parking:117` yanlış endpoint kullanıyor |
| `PUT /api/v1/employees/:id` | personnel:73 | `personnel:93` edit local |
| `POST /api/v1/leaves/:id/reject` | personnel:92 | `personnel:116` izin reddi hiç API'ye gitmiyor |
| `PUT /api/v1/announcements/:id` | community:51 | `announcements:82` edit local |
| `POST /api/v1/announcements/:id/pin` | community:53 | `announcements:94` sabitleme local |
| `PUT /api/v1/visitors/:id`, `DELETE /:id` | visitor:102,103 | `visitors:96`/`:120` local |
| `PUT /api/v1/reservations/:id`, `POST /:id/review` | reservation:129,131 | `reservations:95` local; onay/red UI yok |
| `PUT /api/v1/credentials/:id` | settings:619 | `credentials:142` edit local |
| `GET /api/v1/credentials/:id/audit-log` | settings:647 | Audit log okuma hiç yapılmıyor (`credentials:72` mock) |
| `POST /api/v1/requests` | community:40 | Talepler sayfasında "yeni talep" butonu yok |
| `POST /api/v1/requests/:id/confirm-resolution` | community:42 | Çözüm onayı akışı UI'da yok |

### 3d. ÖLÜ KOD — hiçbir sayfadan çağrılmayan `api-client` metotları (13)
`login` (`:91`, NextAuth kendi `fetch`'ini kullanıyor — `route.ts:27`), `logout` (`:99`), `getCurrentUser` (`:116`), `getDebtStatus` (`:167`), `getAssessments` (`:172`), `getPayments` (`:192`), `getMeters` (`:208`), `submitMeterReadings` (`:213`), `getConsumptionSummary` (`:222`), `getAnnouncements` (`:228`), `createAnnouncement` (`:233`), `deleteAnnouncement` (`:244`), `getRequests` (`:249`), `updateRequestStatus` (`:254`), `assignRequest` (`:262`), `getDashboardStats` (`:270`), `getRecentPayments` (`:275`), `getRecentRequests` (`:282`), `getNotifications` (`:313`), `getApiCredentials` (`:334`), `createApiCredential` (`:339`), `deleteApiCredential` (`:355`), `getParkingZones` (`:374`), `recordEntry` (`:389`), `getEmployeeStats` (`:400`), `deleteEmployee` (`:413`), `getVisitors` (`:456`), `getCurrentVisitors` (`:466`), `deleteVehicle` (`:370`), `getTodayReservations` (`:438`), `generateReport` (`:495`), `downloadReport` (`:503`).

### 3e. ÖLÜ KOD — `hooks.ts` (17 hook'un 13'ü kullanılmıyor)
Kullanılan yalnızca 4: `useAssessmentOverview`, `useCreateAssessment`, `useExpenseCategories`, `useDebtors` (hepsi `assessments/page.tsx:5`).
Kullanılmayan: `useDashboardStats` (`:5`), `useRecentPayments` (`:12`), `useRecentRequests` (`:19`), `useResidents` (`:27`), `useCreateResident` (`:34`), `useAssessments` (`:45`), `useMeters` (`:84`), `useSubmitMeterReadings` (`:91`), `useAnnouncements` (`:102`), `useCreateAnnouncement` (`:109`), `useRequests` (`:120`), `useUpdateRequestStatus` (`:127`), `useGenerateReport` (`:139`).
**Sonuç:** TanStack Query panelin %94'ünde kullanılmıyor; sayfalar ham `useEffect` + `useState` ile veri çekiyor → cache, retry, invalidation, `isError` yok.

### 3f. GATEWAY MOCK'LARI (backend'de "endpoint var" ama gerçek veri yok)
- `GET /api/v1/dashboard/stats` — gateway:221, agregat. Dashboard sayfası **hiç çağırmıyor**.
- `GET /api/v1/dashboard/recent-payments` — gateway:279, içeride `financeURL/api/v1/payments` çekiyor ama finance yalnızca `/api/v1/finance/payments` sunuyor → **her zaman boş dizi**.
- `POST /api/v1/reports/generate` — gateway:305, `type`/`params`'ı yok sayıp **sabit tahakkuk verisi** döndürüyor.
- `GET /api/v1/reports/:id/download` — gateway:400, bellek içi `generatedReports` map'i → **servis restart'ında raporlar kaybolur**.
- `/api/v1/dashboard/` catch-all — gateway:299, her şeye `{success:true,data:{}}`.
`tasks/todo.md:76,81,86` "Gateway mock handler'larını kaldır ✅" iddiası: dashboard ve reports mock'ları **hâlâ yerinde**.

---

## 4. Mantık Hataları ve Eksiklikler

### A. GÜVENLİK

**A-01 [KRİTİK] Login şifresi düz metin olarak sunucu log'una yazılıyor**
Kanıt: `app/api/auth/[...nextauth]/route.ts:17` → `console.log("Authorize called with credentials:", credentials)`. `credentials` nesnesi `{phone, password}` içerir. `:18`, `:26`, `:36` de gereksiz log.
Neden sorun: Her giriş denemesinde telefon + şifre Next.js sunucu log'una (Docker/stdout/log toplayıcı) düşer. KVKK ihlali ve doğrudan kimlik bilgisi sızıntısı.
Öneri: Bu 4 `console.log`'u tamamen kaldır.

**A-02 [KRİTİK] Backend'in %85'i kimlik doğrulamasız — panelin "güvenlik" iddiası geçersiz**
Kanıt: gateway'de hiç auth middleware'i yok (`gateway/main.go:422` yalnızca `logMiddleware(corsMiddleware(mux))`). JWT kontrolü yapan yalnızca 3 servis: identity (`main.go:51,62,71`), finance (`:38`), community sadece `/requests` (`:37`).
Kimlik doğrulamasız erişilebilen: `/credentials` (**API sırları!**), `/employees` + `/payroll` (**maaş bordroları**), `/expenses`, `/visitors`, `/vehicles`, `/reservations`, `/announcements`, `/meters`, `/notifications`, `/bank-accounts`, `/bank-transactions`.
Ek: CORS `Allow-Origin: *` (gateway:59-61).
Neden sorun: Gateway portu erişilebilir olan herkes maaş ve API şifrelerini okuyup değiştirebilir. Frontend'deki "erişim yetkisi" etiketleri tamamen kozmetik.
Öneri: Gateway'de zorunlu JWT middleware; `credentials`, `payroll`, `employees` için ek rol kontrolü.

**A-03 [KRİTİK] Compose varsayılan NEXTAUTH_SECRET'i**
Kanıt: `docker-compose.yml:196` `${NEXTAUTH_SECRET:-your-nextauth-secret-change-in-production}`.
Neden sorun: Ortam değişkeni verilmezse bilinen bir secret'la JWT imzalanır → herkes geçerli oturum token'ı üretip yönetici olabilir.
Öneri: Fallback'i kaldır, yokken konteyner başlamasın.

**A-04 [YÜKSEK] Token'lar localStorage'da (XSS)**
Kanıt: `api-client.ts:60-63` (`access_token` + `refresh_token` yazma), `:31-33`,`:41`,`:48`,`:68-70`,`:76` (okuma/silme).
Neden sorun: 7 gün ömürlü refresh token JS ile okunabilir. NextAuth zaten httpOnly cookie tutuyor — bu ikinci kopya gereksiz risk.
Öneri: Token'ı yalnızca bellekte tut; refresh'i NextAuth `jwt` callback'ine taşı.

**A-05 [YÜKSEK] Rol bazlı erişim kontrolü hiç yok**
Kanıt: `session.user.roles` tipte tanımlı (`types/next-auth.d.ts:9,23,33`), JWT'ye yazılıyor (`route.ts:66,76`) ama **hiçbir sayfa/bileşen okumuyor** (grep `roles`: yalnızca tip dosyası ve route.ts). `middleware.ts:5-21` sadece "token var mı" kontrol ediyor, rolü kontrol etmiyor. `sidebar.tsx:31-47` navigasyonu koşulsuz gösteriyor.
Neden sorun: **AUDITOR/STAFF/TENANT rolündeki bir kullanıcı `/dashboard/credentials` (sistem şifreleri), `/dashboard/personnel` (maaşlar), `/dashboard/accounting`'e girip her aksiyonu tetikleyebilir.** `credentials:271-276`'daki `accessLevel` etiketleri yalnızca dekor.
Öneri: `middleware.ts`'de yol→rol haritası; `sidebar` navigasyonunu role göre filtrele; hassas aksiyonları (`credentials` reveal, `personnel` maaş) rol kontrolüne bağla.

**A-06 [ORTA] Maaş gizleme sadece görsel**
Kanıt: `personnel/page.tsx:234` `showSalary.has(emp.id) ? ... : "••••••"`. Maaş verisi zaten client'a inmiş, DevTools'tan okunabilir; rol kontrolü de yok.

**A-07 [OLUMLU] XSS: `dangerouslySetInnerHTML` hiç kullanılmıyor** (grep: 0 sonuç). Duyuru/mesaj içerikleri JSX text olarak render ediliyor — güvenli.

### B. VERİ DÜRÜSTLÜĞÜ

**B-01 [KRİTİK] Sessiz mock fallback — kullanıcıya sahte mali veri**
Kanıt ve etki: §İddia 2b tablosu (9 nokta). En ağırı `expenses:75-81` (uydurma ₺45.750 mali özet) ve `credentials:107-108` (sahte şifre).
Neden sorun: Hata durumunda ekran normal görünüyor; site yöneticisi uydurma sayılarla karar veriyor / genel kurula yanlış rapor sunuyor.
Öneri: Tüm `catch` bloklarından mock verileri sil; `error` state'i + görünür uyarı bandı + "Yeniden dene" butonu ekle.

**B-02 [KRİTİK] "Kaydedildi" yalanları — hata yutan `catch {}`**
Kanıt: `accounting:112`, `personnel:112`, `parking:117`, `visitors:109`,`:114`, `reservations:108`, `notifications:189`, `settings:41-44`, `reports:132-135`.
En ağırı: `notifications:189` — `sendNotification` başarısız olsa bile modal kapanır, form temizlenir; kullanıcı **124 sakine bildirim gittiğini** sanır.
Öneri: Hataları kullanıcıya göster; başarısızlıkta local state'i güncelleme.

**B-03 [KRİTİK] Muhasebe uydurma tutar yazıyor**
Kanıt: `accounting/page.tsx:132-134` — "Toplu İşlemler" `mockPersonnel` toplamı (₺56.000, `:14-18`), bakım için sabit **₺12.500**, SGK için sabit **₺18.000** ile gider kaydı oluşturuyor.
Neden sorun: Yasal olarak anlamlı muhasebe kayıtlarına sihirli sayılar giriyor. `:156-159`'daki "Net Bakiye" mock gelir + kısmen gerçek giderin karışımı → hiçbir anlamı yok.

**B-04 [YÜKSEK] Aidat kararı (karar defteri) hiç saklanmıyor**
Kanıt: `accounting:90-95` `handleAddDues` yalnızca `setDuesDecisions`. Karar no/sayfa no/karar tarihi (`:10`) yasal kayıt niteliğinde; API'ye gitmiyor, F5'te kayboluyor.

**B-05 [YÜKSEK] Sayaç okuma geçmişi yok edilerek üzerine yazılıyor**
Kanıt: `meters/page.tsx:57` — `{...m, lastReading: newReading, currentReading: newReading}`. Önceki okuma **kalıcı olarak kaybedilir**; okuma tarihçesi tutulmuyor.
Ek: `:55` `if (newReading && newReading > m.lastReading)` — sayaç değişimi/devir (rollover) durumunda düşük okuma **sessizce yok sayılır**, kullanıcıya hata gösterilmez, `savedReadings` işareti de konmaz.

**B-06 [ORTA] Bildirim "Zamanla" seçeneği hemen gönderiyor**
Kanıt: `notifications:407-421` tarih/saat alanları var, `:181-192` `confirmSend` bunları **hiç kullanmıyor**; `sendNotification` (`api-client:318-326`) schedule parametresi almıyor. Kullanıcı "yarın 09:00" seçse bile şimdi gönderilir (veya gönderilmez).

**B-07 [ORTA] CSV import'ta ID çakışma riski**
Kanıt: `announcements:62`, `requests:79`, `meters:105` → `id: Date.now() + i`. `Date.now()` milisaniye; `i` küçük tam sayı → iki ayrı import 100+ satırlık dosyalarla çakışabilir (`Date.now()+150` vs sonraki `Date.now()`), React `key` çakışması ve yanlış satır silinmesi.

### C. HATA / YÜKLEME / BOŞ DURUM UX'İ

**C-01 [YÜKSEK] Hiçbir sayfada "hata" durumu yok**
| Sayfa | loading | empty | error |
|---|---|---|---|
| residents | ✅ `:227-230` | ✅ `:285-287` | ⚠️ sadece CSV/form hatası (`:202`,`:305`); liste yükleme hatası **sessiz boş tablo** (`:74-79`) |
| assessments | ✅ `:199`,`:240` | ✅ `:201`,`:242` | ❌ `isError` hiç kullanılmıyor → hata "kayıt yok" gibi görünür |
| expenses | ✅ `:182-183` | ✅ `:230-232` | ❌ hata → mock veri |
| personnel/parking/visitors/reservations | ✅ `Loader2` | ✅ | ❌ hata → mock veri |
| accounting/notifications | ❌ **loading yok** | ⚠️ | ❌ hata → mock |
| dashboard/meters/announcements/requests/reports/settings | — (mock) | kısmî | — |
Öneri: Ortak `<QueryState>` bileşeni (loading skeleton + hata bandı + retry + boş durum).

**C-02 [ORTA] Sidebar hata durumunda sonsuz "Yükleniyor..."**
Kanıt: `sidebar.tsx:77` `.catch(() => setSites([]))` + `:128` `{sites.length === 0 && <option>Yükleniyor...</option>}`. Hata alınca select sonsuza kadar "Yükleniyor..." + `disabled` (`:125`) kalır.

**C-03 [ORTA] `alert()` ile UX**
Kanıt: `sidebar.tsx:90`,`:106`; `reports:116`,`:134`. Panelin geri kalanı modal/inline mesaj kullanıyor — tutarsız.

**C-04 [ORTA] Error boundary yok** — `app/layout.tsx`'te `error.tsx` / `global-error.tsx` dosyası yok (dosya listesi: yalnızca `layout.tsx`, `page.tsx`, `globals.css`). C-05'teki crash tüm paneli beyaz ekrana çevirir.

**C-05 [YÜKSEK] Bilinmeyen `channel` değeri sayfayı çökertiyor**
Kanıt: `notifications/page.tsx:460` `channelConfig[automation.channel].icon`, `:537` `channelConfig[item.channel].icon`, `:548`, `:589` — optional chaining **yok**. Geçmiş verisi API'den geliyor (`:139` `channel: n.channel ?? "push"`) ve arbitrary değer geçebilir (örn. `"SMS"`, `"whatsapp"`). O anda `TypeError: Cannot read properties of undefined` → error boundary olmadığı için **tüm sayfa çöker**.
Karşılaştırma: diğer sayfalar bunu doğru yapıyor (`requests:176` `statusConfig[...]?.color ?? ...`).

### D. FORM VALİDASYONU

**D-01 [YÜKSEK] zod / react-hook-form kurulu ama HİÇ KULLANILMIYOR**
Kanıt: `package.json:20-22` (`react-hook-form`, `@hookform/resolvers`, `zod`). Grep `zod|useForm|zodResolver` → `src/` altında **0 sonuç**. Tüm formlar elle `useState` + HTML `required`.
Neden sorun: Client-side şema validasyonu yok; sadece tarayıcı `required`/`type` kontrolü var.
Örnek boşluklar: telefon formatı doğrulanmıyor (`residents:332` `type="tel"`, maske/regex yok — `login:77`'de `replace(/\D/g,"")` var ama residents'te yok); tutar negatif olabilir (`expenses:264` `type="number"`, `min` yok — `accounting` gelir/gider aynı); `assessments:334` vade tarihi geçmiş olabilir (`min` yok); `credentials:335` port aralığı kontrol edilmiyor; `reservations:87` bitiş < başlangıç kontrolü yok.

**D-02 [OLUMLU/KISMEN] Sunucu hatası kullanıcıya gösteriliyor mu?**
Yalnızca 2 yerde: `residents:135-137` (`err?.response?.data?.error` → `formError`) ve `assessments:55-61`+`:128` (`errorMessage()` helper). Diğer **tüm** sayfalarda sunucu hatası yutuluyor (B-02).

### E. PERFORMANS / VERİ YÖNETİMİ

**E-01 [YÜKSEK] Pagination hiç yok — her şey çekilip client'ta filtreleniyor**
Kanıt: `residents:71` `getResidents()` **parametresiz** (oysa `api-client:136` `search`/`block`/`role` destekliyor) → tüm sakinler çekilip `:92-98`'de client'ta filtreleniyor. Aynı kalıp: `expenses:71`, `personnel:68`, `parking:72` (`:145-148` client filtre), `visitors:70` (`:148-150`), `reservations:64`, `credentials:163-167`, `requests:89-93`, `announcements:70`, `meters:123`.
Neden sorun: 500 daireli bir sitede binlerce kayıt tek seferde inip DOM'a basılıyor. Sayfa boyutu / sonsuz kaydırma / sunucu tarafı arama yok.

**E-02 [ORTA] TanStack Query cache invalidation — kısmen doğru ama kapsam dışı**
Kanıt: `hooks.ts:38-40`, `:56-58`, `:95-97`, `:113-115`, `:132-134` — `invalidateQueries` doğru anahtarlarla yazılmış. **Ancak** bu hook'ların 13'ü hiç kullanılmıyor (§3e). Kullanılan `useCreateAssessment` (`:52-60`) `["assessments"]`'i invalidate ediyor ama sayfa `["assessment-overview"]` ve `["debtors"]` kullanıyor (`:69-74`, `:76-81`) → **yeni tahakkuk sonrası tablo ve borç kartı yenilenmiyor.** Gerçek bug.

**E-03 [ORTA] Optimistic update geri alma yok**
Kanıt: Hiçbir mutation'da `onMutate`/`onError` rollback yok. Sayfalar zaten "optimistic" değil, "koşulsuz" güncelleme yapıyor (B-02) — hata olsa da state güncel kalıyor, geri alma mekanizması yok.

**E-04 [DÜŞÜK] `staleTime: 60s` + `refetchOnWindowFocus: false`** (`providers.tsx:14-15`) — ziyaretçi giriş/çıkış gibi canlı ekranlar için uygun değil; `refetchInterval` hiç kullanılmıyor.

**E-05 [DÜŞÜK] `window.location.reload()` ile site değişimi** (`sidebar.tsx:88`,`:104`) — tüm uygulama yeniden yükleniyor; `queryClient.clear()` + router refresh daha doğru.

### F. FORMATLAMA / LOCALE / TIMEZONE

**F-01 [ORTA] Para formatlaması tutarsız — `Intl.NumberFormat` hiç kullanılmıyor**
3 farklı biçim var:
- `₺${x.toLocaleString("tr-TR")}` — doğru locale: `assessments:172,181,188,261,262,398`
- `₺${x.toLocaleString()}` — **locale parametresiz** (tarayıcı locale'ine göre `1,200` veya `1.200` değişir): `accounting:156-159,192,236,277,298`, `expenses:160-163,215`, `personnel:173,234`, `meters:195,201`
- `₺${x.toFixed(2)}` — binlik ayırıcı yok: `meters:166,204`
Ayrıca kuruş gösterimi tutarsız: `expenses`'te `2450.75` → `2.450,75` beklenirken `toLocaleString()` varsayılanı max 3 ondalık.
Öneri: Tek `formatCurrency()` helper (`Intl.NumberFormat("tr-TR",{style:"currency",currency:"TRY"})`). `lib/utils.ts` yalnızca 6 satır `cn()` içeriyor (`:1-7`), format helper'ı yok.

**F-02 [ORTA] Timezone yönetimi yok**
Kanıt: Her yerde `new Date(x).toLocaleDateString("tr-TR")` / `toLocaleString("tr-TR")` — **tarayıcı yerel saati** kullanılıyor. `settings:30` "Europe/Istanbul (UTC+3)" ayarı sadece dekoratif string, hiçbir formatlamayı etkilemiyor.
Somut hata: `expenses:209` `new Date("2026-05-28").toLocaleDateString("tr-TR")` — ISO date-only string **UTC** olarak parse edilir; UTC-3 gibi bir tarayıcı saat diliminde **27.05.2026** gösterir (bir gün kayması). Aynı risk `assessments:260` (vade tarihi!), `announcements:149`.
Öneri: `date-fns` (`package.json:18` kurulu, hiç kullanılmıyor) + `date-fns-tz` ile explicit TZ.

**F-03 [DÜŞÜK] `date-fns` ve `recharts` kurulu ama hiç kullanılmıyor**
Grep: `src/` altında `date-fns`/`recharts` importu yok. Dashboard grafikleri `recharts` yerine elle CSS ile çizilmiş (`dashboard/page.tsx:80-83` `div` + `style.height`, `:98-108` `conic-gradient`) → erişilebilir değil, tooltip/eksen yok, veri de sahte.

### G. ERİŞİLEBİLİRLİK / RESPONSIVE / i18n

**G-01 [YÜKSEK] Mobil/tablette navigasyon YOK**
Kanıt: `sidebar.tsx:112` `className="hidden lg:flex lg:w-64"` — 1024px altında sidebar tamamen gizli. `header.tsx:9` mobil menü butonunun `onClick`'i yok, drawer bileşeni de yok. Sonuç: telefon/tablette kullanıcı yalnızca URL yazarak gezebilir. Site yöneticisi/güvenlik personeli için ciddi kısıt.

**G-02 [ORTA] Modal erişilebilirliği yok (14 modal)**
Kanıt: Tüm modallar elle yazılmış `<div className="fixed inset-0 z-50 ...">` (örn. `residents:294-295`, `credentials:295`, `announcements:181`, `settings:302`). Eksikler: `role="dialog"`, `aria-modal`, `aria-labelledby`, focus trap, Escape ile kapatma, backdrop tıklaması ile kapatma, açılışta focus, kapanışta focus geri dönüşü, `document.body` scroll kilidi.
Ek ironi: `@radix-ui/react-dialog` (`package.json:27`) ve diğer 6 Radix paketi kurulu ama **hiçbiri import edilmiyor** (grep `@radix-ui` → `src/` altında 0).

**G-03 [ORTA] Tablolarda `overflow-x-auto` çoğunlukla yok**
Kanıt: 8 kolonlu tablolar `<table className="w-full">` ile sarmalayıcısız: `meters:171`, `expenses:185`, `personnel`, `visitors`, `notifications:523`. Tek doğru örnek `assessments:204` (`<div className="overflow-x-auto">`). Küçük ekranda yatay taşma.

**G-04 [ORTA] Dark mode iki sayfada tamamen kırık**
Kanıt: `reports/page.tsx` ve `settings/page.tsx` — `bg-white`, `text-gray-900`, `border` sınıfları **hiç `dark:` varyantı olmadan** (örn. `reports:142` `text-gray-900`, `:191` `bg-white rounded-xl border`; `settings:85`, `:108` `bg-white`, `:304` `bg-white`). Panelin geri kalanı `dark:` destekliyor → koyu temada bu iki sayfa beyaz/okunamaz.

**G-05 [DÜŞÜK] `<div onClick>` klavye erişilemez** — `reports:168-175` (rapor kartı seçimi). `role="button"`, `tabIndex`, `onKeyDown` yok.

**G-06 [DÜŞÜK] i18n altyapısı yok — tüm metinler Türkçe hardcoded**
Kanıt: `next-intl`/`react-i18next` bağımlılığı yok (`package.json`); tüm string'ler JSX içinde gömülü. Ayrıca `app/layout.tsx` `<html lang>` — dosya 672 byte, kontrol edilmeli; `SAMPLE_CSV` başlıkları da karışık (bazıları Türkçe: `announcements:6` `baslik,icerik,...`; bazıları İngilizce: `expenses:39` `category_name,description,...`) → tutarsız.

**G-07 [OLUMLU] Silme onayı** — 14 modalın hepsinde onay adımı var (`residents:379`, `expenses:298`, `meters:279`, `announcements:241`, `requests:317`, `settings:388`, `credentials:405`, `notifications:615`, vb.). ✅ Tek eksik: `notifications:216` otomasyon silme **onaysız** anında siliyor.

---

## 5. Sayfa Bazlı Eksik Tamamlayıcı Özellikler

| Sayfa | Olmalı ama YOK |
|---|---|
| **Dashboard** | Gerçek veri (öncelik 1); tarih aralığı seçici; borçlu sayısı/kritik uyarı kartı; hızlı aksiyon kısayolları; ay/ay karşılaştırma. |
| **Sakinler** | **Kiracı↔malik geçişi** (rol değiştirme var ama devir tarihi/geçmişi yok); **tapu/arsa payı bilgisi** (aidat dağıtımı `SHARE_RATIO` kullanıyor ama arsa payı hiçbir yerde girilmiyor); bakiye/borç sütunu (`ROADMAP.md:70` "finance entegrasyonu bekleniyor" — doğru itiraf); araç/ziyaretçi/otopark ilişkisi; ikinci telefon, acil durum kişisi, KVKK onay durumu (backend'de `POST /users/me/kvkk-consent` VAR, UI yok); pasifleştirilen sakini **geri alma** (onay metni `:388` "geri alınabilir" diyor ama UI yok); daire geçmişi/oturum süresi; toplu SMS/e-posta gönderme. |
| **Aidatlar** | **Gecikme faizi hesaplama** (mock duyuru `announcements:25` "gecikme faizi uygulanacaktır" diyor — hesaplama hiç yok); **kısmî ödeme** kaydı; ödeme kaydetme/makbuz UI'ı (`POST /finance/payments` backend'de VAR, kullanılmıyor); **borçlu listesi** (`useDebtors` verisi çekiliyor ama `:190`'da yalnızca sayı gösteriliyor, liste render edilmiyor); tahakkuk iptal/düzeltme; daire bazlı aidat detayı; ödeme planı/taksitlendirme; icra/ihtar takibi; mahsuplaşma. |
| **Sayaçlar** | Backend bağlantısı (öncelik 1); **okuma geçmişi/tarihçe** (B-05); anormal tüketim uyarısı; sayaç değişimi (rollover) yönetimi; birim fiyatın ayarlardan gelmesi (`meters:30` hardcoded `HEAT:0.85, WATER:12`); dönem kilitleme; fotoğraflı okuma; elektrik sayacı (yalnızca HEAT/WATER var, `dashboard:118` "Doğalgaz" ve "Elektrik"'ten bahsediyor); tahakkuka yansıtma. |
| **Talepler** | Backend bağlantısı (öncelik 1); **dosya/fotoğraf eki**; **gerçek atama** (`:265` serbest metin — personel listesine bağlanmalı, backend'de assign endpoint'i de yok); **SLA/süre takibi** (öncelik alanı var, hedef süre yok); yorum/işlem geçmişi (timeline); yeni talep oluşturma butonu; maliyet kaydı ve gidere bağlama; tekrarlayan arıza analizi; sakin memnuniyet puanı; `confirm-resolution` akışı (backend'de VAR). |
| **Duyurular** | Backend bağlantısı; hedef kitle seçimi (blok/rol bazlı); zamanlanmış yayın; **okundu bilgisinin gerçek olması** (`:150` `87/124` mock); dosya eki; zengin metin; süresi geçen duyuruların arşivi; push/SMS ile birleşik gönderim (notifications ile tamamen ayrık); onay/moderasyon. |
| **Muhasebe** | Gelir/aidat kararı için backend (öncelik 1); **banka mutabakatı** (backend'de `/bank-accounts`, `/bank-transactions`, `/auto-match` VAR — UI yok); kasa/banka ayrımı; mizan/bilanço; işletme defteri çıktısı; **karar defteri kaydı kalıcılığı** (B-04); dönem kapatma; e-fatura/e-arşiv; KDV; gider→tahakkuk yansıtma (`ExpenseSummary.assessment_reflecting` alanı var ama UI'da hiç gösterilmiyor). |
| **Gider Yönetimi** | **Fatura dosyası yükleme** (`:284-287` işlevsiz dekor; backend'de `POST /expenses/:id/invoices` VAR); **onay/red akışı** (`PATCH /expenses/:id/status` VAR, UI yok); tekrarlayan gider otomasyonu (`is_recurring` tipte var, `:99`'da hiç set edilmiyor); tedarikçi yönetimi; bütçe/gerçekleşen karşılaştırma; kategori bazlı grafik; fatura tarama (`POST /expenses/scan-invoice` VAR). |
| **Bildirimler** | Doğru endpoint (`/notifications/logs`); **gerçek kitle sayıları** (`:61-69` mock); **zamanlama** (B-06); otomasyonların backend'de saklanması + gerçek cron; şablon yönetimi (`/notifications/templates` VAR); teslim raporu (başarılı/başarısız/bounce); SMS bakiye/maliyet; kanal bazlı kullanıcı tercihi (`/users/:id/notification-preferences` backend'de var ama gateway'de erişilemez); test gönderimi. |
| **Otopark** | **Giriş kaydı UI'ı** (`recordEntry` metodu var, çağrılmıyor); doğru çıkış endpoint'i (§3b); park alanı/zone yönetimi (`getParkingZones` çağrılmıyor); **misafir aracı süre limiti/ücretlendirme**; plaka tanıma entegrasyonu (`POST /plate-recognition` VAR); ihlal/yanlış park kaydı; daire başına araç kotası; doluluk geçmişi grafiği. |
| **Personel** | **İzin reddi API'ye gitmiyor** (`/leaves/:id/reject` VAR); **bordro** (`/payroll`, `/payroll/generate`, `/payroll/:id/pay` backend'de VAR — UI yok); SGK/vergi kesintileri; puantaj/vardiya; kıdem/ihbar hesabı; iş sözleşmesi ve evrak arşivi (`/contracts`, `/documents` servisleri var); yıllık izin hakkı otomatik hesabı (`leave_balance` mock'ta sabit `14`); performans/devamsızlık; maaş için rol bazlı erişim (A-06). |
| **Rezervasyon** | **Çakışma/çift-rezervasyon kontrolü** (kritik — hiç yok); takvim görünümü (`/reservations/calendar` VAR); onay/red akışı (`POST /:id/review` VAR); ücretli tesis + depozito; kullanım kuralları/kapasite kontrolü; tesis bakım kapatma (`POST /facilities/:id/maintenance` VAR); müsaitlik gösterimi (`/facilities/:id/availability` VAR); daire başına kota. |
| **Ziyaretçi** | QR kod (`/visitors/qr/:code`, `/regenerate-qr` VAR — UI yok); sakine bildirim (`POST /:id/notify` VAR); kimlik/plaka kaydı; kara liste; kargo/teslimat ayrımı (`/packages` servisi VAR, UI yok); ziyaret süresi limiti + aşım uyarısı; geçmiş arama/rapor (`/units/:id/visitors/history` var ama gateway'de erişilemez). |
| **Raporlar** | Gerçek veri (öncelik 1); **gerçek PDF üretimi** (buton var, CSV indiriyor); **gerçek Excel** (aynı); **gerçek e-posta gönderimi** (alert); tarih aralığı seçimi (dönem select'i `:147` hiçbir şeyi etkilemiyor); rapor geçmişi/arşiv (`lastGenerated` `:15` mock); zamanlanmış otomatik rapor; genel kurul raporu; KDV/beyan çıktıları; grafik. |
| **Sistem Şifreleri** | Backend bağlantısı (öncelik 1: list/create/update/delete endpoint'lerinin hepsi VAR); **gerçek reveal endpoint'i** (backend'de yok — yazılması gerekiyor); **backend audit log yazımı** (okuma endpoint'i `/credentials/:id/audit-log` VAR); **rol bazlı erişim** (`accessLevel` dekoratif); şifre güçlülük göstergesi; şifre rotasyon/son geçerlilik uyarısı; şifre geçmişi; 2FA/TOTP alanı; şifre üretici; bağlantı testi (endpoint reveal için kötüye kullanılıyor, asıl amacı için UI yok); dışa aktarma kısıtı. |
| **Ayarlar** | **Her şey için backend** (öncelik 1: hiçbir sekme kaydetmiyor); genel ayarların `properties` tablosuna yazılması; **rol/yetki matrisi** (A-05'in çözüm yeri); kullanıcı davet/e-posta doğrulama; bildirim tercihlerinin kalıcılığı; **gerçek entegrasyon durumu** (`:246-248` sabit "Bağlı"); aidat/gecikme faizi oranı gibi iş kuralları; yedekleme/dışa aktarma; KVKK metni ve saklama süresi; audit log görüntüleme; blok/daire yönetimi (sakin eklerken birim gerekli ama birim oluşturma UI'ı hiç yok — `units` yalnızca okunuyor). |
| **Header/Global** | **Çıkış butonu** (kritik, hiç yok); gerçek kullanıcı adı/rolü; çalışan global arama; bildirim açılır menüsü; **mobil navigasyon drawer'ı** (G-01); tema değiştirici (dark mode sınıfları var, toggle yok); breadcrumb; klavye kısayolları. |

---

## Doğrulanamayanlar

- **Backend'in çalışma zamanı davranışı** — servisler ayağa kaldırılmadı (`npm`/docker çalıştırılmadı). Endpoint varlığı yalnızca route kayıtlarından statik olarak doğrulandı; gerçek yanıt gövdeleri/şema uyumu doğrulanamadı. Özellikle `expRes?.data ?? expRes` gibi çift-şema tahminleri (`expenses:72`, `residents:72`) backend'in gerçek zarf formatı bilinmediği için doğrulanamadı.
- **`app/layout.tsx` içindeki `<html lang>` değeri** — dosya okunmadı (672 byte); G-06'daki i18n tespiti bağımlılık ve string taramasına dayanıyor.
- **Migration 006/007'nin DB'ye uygulanmış olduğu** (`CHANGELOG.md:24`,`:29`) — canlı DB'ye erişim yok.
- **Tarayıcı çalışma zamanı hataları** (C-05 crash'i vb.) statik analizle tespit edildi, çalıştırılarak doğrulanmadı.
