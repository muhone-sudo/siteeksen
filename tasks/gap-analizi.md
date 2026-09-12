# Gap Analizi — Eksiklikler ve Mantık Hataları

Bu dosya iki soruyu birlikte cevaplar:

1. **"Olması gereken"** (`tasks/modul-envanteri.md`, 60 modül) ile **"olan"** (`tasks/audit-raporu.md`) arasındaki fark nedir?
2. Mevcut her özellikte **düşünülmemiş, olması gereken tamamlayıcı parçalar** nelerdir?

Kanıt gösterimi: `dosya:satır`. Ayrıntılı kanıt `tasks/audit/` altındadır.
Durum sözlüğü: `tasks/dogrulama-politikasi.md` §5.

Son güncelleme: 2026-09-09

---

# BÖLÜM A — Modül Durum Matrisi

60 referans modülün bugünkü karşılığı. `Kapsam` = referans modülün bugün karşılanan yüzdesi (kaba tahmin).

## Katman 0 — Platform

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-01 Kimlik ve Erişim (IAM) | P0 | `[D1]` JWT + refresh var (15dk/7gün doğru). **Yok:** OTP, şifre sıfırlama, şifre politikası, 2FA, cihaz listesi, brute-force koruması, gerçek çıkış (logout no-op), token türü ayrımı, davet akışı. Biyometrik mobilde `[KIRIK]` | ~20% |
| M-02 Çok kiracılılık / izolasyon | P0 | `[KIRIK]` `pkg/tenant` 294 satır `[ÖLÜ]`. `property_id` istemciden değiştirilebiliyor (`user.go:87-91`); roller global → bir sitede yönetici olan her sitede yönetici | ~10% |
| M-03 Denetim izi | P0 | `[KIRIK]` INSERT kolon adları şemayla uyuşmuyor → tablo kalıcı boş; `old/new_values` hep `nil`; hata yutuluyor | ~5% |
| M-04 Dosya/doküman depolama | P0 | `[KIRIK]` `Upload()` yazılmış ama hiçbir route'a bağlı değil; depolama `/tmp` (volume yok) → yeniden başlatmada kayıp; indirme uç noktası yok; nesne depolama yok | ~5% |
| M-05 Bildirim altyapısı | P0 | `[MOCK]` `log.Printf`. Firebase/SMS/WhatsApp kodu var ama `[ÖLÜ]`. Kuyruk, şablon, tercih, teslim raporu yok. Mobilde push **hiç yok** | ~5% |
| M-06 Entegrasyon katmanı | P0 | `[ÖLÜ]` Adaptör deseni yok; idempotency yok; webhook yok; devre kesici/yeniden deneme yok. Aynı entegrasyon 2 kez yazılmış (iyzico, FCM, OpenAI) | ~5% |
| M-07 İş akışı / onay motoru | P1 | **Yok.** Tek iş kuralı (faturasız gider onayı) istemci girdisine bakıyor ve kalıcı değil | 0% |
| M-08 Raporlama motoru | P0 | `[KIRIK]` PDF/Excel motoru gerçek; veri **hardcoded**; auth yok; raporlar RAM'de (TTL yok) | ~15% |
| M-09 Parametre yönetimi | P0 | **Yok.** Oranlar/kurallar koda gömülü; yürürlük tarihi kavramı yok | 0% |
| M-10 Gözlemlenebilirlik | P0 | `[D1]` Sadece `log.Printf` metot+yol. Status/süre/istek kimliği, metrik, izleme, uyarı, çökme raporu yok | ~5% |
| M-11 Güvenlik | P0 | `[KIRIK]` Gateway ve Kong'da auth yok; CORS `*`; `JWT_SECRET` boşsa boş anahtarla doğrulama; sabit şifreleme anahtarı; şifre düz metin log'a yazılıyor; `DB_SSLMODE` tanımsız | ~10% |
| M-12 Şema/migration yönetimi | P0 | `[KIRIK]` Migration çalıştırıcı yok; sürüm tablosu yok; 004 ve 005 temiz kurulumda çöküyor; down betiği yok; transaction sarmalaması yok | ~15% |

## Katman 1 — Ana veri

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-13 Taşınmaz yapısı | P0 | `[D1]` `properties`/`blocks`/`units` şeması iyi (arsa payı, alan, işyeri/zemin kat bayrakları var). **Yok:** toplu yapı/ada hiyerarşisi, blok bazlı gider ayrımı, ortak yer envanteri, eklenti modeli, arsa payı toplam denetimi, birleştirme/ayırma geçmişi. Yeni site açılınca birim `share_ratio = 0` ile açılıyor → tahakkuka giremiyor (`user.go:123`) | ~35% |
| M-14 Kişi ve ilişki yönetimi | P0 | `[D4]` `residents` modülü gerçek ve çalışıyor (tek gerçek uçtan uca modül). **Yok:** tarihli ilişki (başlangıç/bitiş), paylı malik pay oranı, kiracı sözleşmesi, malik↔kiracı sorumluluk ayrımı, mirasçı/vekil, aile üyesi, TCKN şifreleme (kolon var, hiç şifrelenmiyor), mükerrer kişi birleştirme | ~40% |
| M-15 Devir / borcu yoktur | P1 | **Yok.** Tapu devri, borç dondurma, "borcu yoktur" belgesi, müteselsil sorumluluk kaydı, sayaç/demirbaş teslim yok | 0% |

## Katman 2 — Yönetişim (KMK) — **en büyük boşluk**

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-16 Yönetim planı | P0 | **Yok** | 0% |
| M-17 Kat malikleri kurulu (genel kurul) | P0 | `[MOCK]` `meeting_wizard` servisi sabit JSON; `meetings` tablosu oluşmuyor (005 çöküyor). Çağrı usulü, yeter sayı, vekâlet sınırı, karar nisapları, karar defteri, tebliğ, iptal davası takibi — **hiçbiri yok** | ~2% |
| M-18 Yönetim organları | P0 | `[D1]` `management_staff` tablosu var, kod yok. Yönetici/denetçi seçimi, görev süresi, imza yetkisi, devir teslim yok | ~5% |
| M-19 Yasal defterler | P0 | **Yok.** Karar defteri, işletme defteri, noter kapatma takibi yok | 0% |
| M-20 Denetim ve hesap verme | P0 | **Yok.** `AUDITOR` rolü tanımlı ama denetçi bugün her şeyi görebiliyor/değiştirebiliyor (fail-open RBAC). 3 aylık denetim, yıllık hesap özeti, ibra yok | ~3% |

## Katman 3 — Finans

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-21 İşletme projesi (bütçe) | P0 | **Yok.** Aidatın yasal dayanağı ve icra takibinin belgesi üretilemiyor | 0% |
| M-22 Aidat tahakkuku | P0 | `[D2]` Dağıtım motoru **gerçek ve matematiği doğru** (EQUAL/AREA_M2/SHARE_RATIO, sıfıra bölme korumalı, mükerrer dönem engelli). **Kusurlar:** kuruş yuvarlaması yok → toplam tutmuyor; `float64`; ön izleme/geri alma yok; tebliğ yok; gün bazlı bölüşüm yok; `late_fee` hep 0 | ~45% |
| M-23 Isı/su gider paylaşımı (pay ölçer) | P0 | `[MOCK]` `submitReading` sabit `12.5` döndürüyor; `meters`/`meter_readings` tablolarına hiç dokunulmuyor. Yönetmelik oranları, okuma doğrulama, tüketim detay faturası yok | ~3% |
| M-24 Borç / gecikme tazminatı / cari hesap | P0 | `[KIRIK]` Bakiye sorgusu **kullanıcı sayısıyla çarpıyor** (kartezyen join) → 1.200 TL borç 187.200 TL görünüyor. Gecikme tazminatı (KMK m.20, aylık %5) hiç hesaplanmıyor. Kalem bazlı borç, mahsup sırası, yaşlandırma, ekstre yok | ~15% |
| M-25 Tahsilat ve banka mutabakatı | P0 | `[KIRIK]` Ödeme `PENDING`'de kalıyor, `paid_amount` **hiç güncellenmiyor** → ödeyen sakin sonsuza dek borçlu. Transaction yok, hata yutuluyor, idempotency yok, sahiplik doğrulanmıyor. Ödeme sağlayıcısı yok. Mobilde ödeme **tamamen sahte**. Banka ekstresi/eşleştirme yok | ~10% |
| M-26 Gider ve satın alma | P0 | `[MOCK]` `expense` servisi kalıcı değil; onay istemci girdisine bakıyor. Bütçe kontrolü, teklif toplama, tekrarlayan gider, mobilden gider girme yok. Fatura OCR sahte | ~8% |
| M-27 Kasa, banka, muhasebe | P0 | `[MOCK]` `banking` servisi kalıcı değil; IBAN doğrulaması yok. Kasa/banka bakiyesi, dönem kapanışı, mutabakat, gelir-gider defteri yok. `dues_decisions` ve `incomes` tabloları hiç yok | ~5% |
| M-28 Hukuk ve icra takibi | P0 | **Yok.** İhtar, icra takibi, kanuni ipotek, dava takibi, masraf/faiz mahsubu — hiçbiri yok | 0% |
| M-29 Vergi ve SGK uyumu | P1 | **Yok** | 0% |

## Katman 4 — Operasyon

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-30 Talep / arıza (helpdesk) | P0 | `[D4]` **Durum makinesi ve sakin onayı gerçek ve titiz** (`CLOSED`'a doğrudan geçiş engelli). **Kusurlar:** `unit_id` hiç yazılmıyor; site kontrolü yok (başka sitenin talebi güncellenebiliyor); `deleted` filtresi yok; ticket no çakışabilir; dosya eki, SLA, atama, maliyet, birleştirme yok. Mobilde liste API'den gelmiyor (hardcoded) → onay akışı pratikte çalışmıyor | ~35% |
| M-31 Periyodik bakım ve yasal uyum takvimi | P0 | **Yok.** Asansör/yangın/su deposu/paratoner/jeneratör yükümlülük takvimi hiç yok. Denetimde ilk sorulan şey | 0% |
| M-32 Varlık ve demirbaş | P1 | `[MOCK]` `asset` servisi kalıcı değil; amortisman raporu kendi içinde tutarsız (850.000 ⟷ 650.000) | ~5% |
| M-33 Stok ve sarf malzeme | P2 | `[MOCK]` Stok hareketi stok seviyesini değiştirmiyor | ~3% |
| M-34 Personel yönetimi | P0 | `[MOCK]` Maaş/TCKN **kimliksiz açık**; bordro sabit `125000`; izin onayı hiçbir iş kuralı içermiyor. SGK, İSG, kıdem karşılığı, puantaj yok | ~5% |
| M-35 Tedarikçi ve sözleşme | P1 | `[MOCK]` `contract` servisi kalıcı değil; süre hesabı sabit ve yanlış (süresi geçmiş sözleşme "334 gün kaldı") | ~4% |
| M-36 Sigorta yönetimi | P1 | **Yok.** DASK takibi, poliçe yenileme, hasar süreci yok | 0% |
| M-37 Acil durum ve afet | P1 | **Yok.** Türkiye için yüksek değerli boşluk | 0% |
| M-38 Ziyaretçi ve erişim kontrolü | P1 | `[MOCK]` TCKN kimliksiz açık; QR 8 hex (tahmin edilebilir), süre/kullanım kontrolü yok. Mobilde ön kayıt **sahte** | ~5% |
| M-39 Otopark | P1 | `[MOCK]` Ücret sabit `50.00`; giriş/çıkış eşleştirilmiyor; plaka tanıma sabit `ALLOW` (**bariyere bağlanırsa her araca izin**); plaka normalizasyonu yok. Elektrikli araç şarjı yok | ~5% |
| M-40 Kargo / koli | P2 | `[MOCK]` Mobilde okuma gerçek; "güvenliğe haber ver" no-op | ~10% |
| M-41 Ortak alan rezervasyonu | P2 | `[MOCK]` Çakışma/kapasite/süre/tarife kontrolü **hiç yok**; ücret sabit `100.00`. Mobilde yazma gerçek ama saat slotları hardcoded | ~12% |
| M-42 Güvenlik operasyonu | P2 | `[MOCK]` `patrol` servisi kalıcı değil | ~3% |
| M-43 Temizlik ve çevre | P2 | **Yok** | 0% |
| M-44 Kural ihlali ve yaptırım | P1 | **Yok** | 0% |
| M-45 Tadilat izni | P1 | **Yok** | 0% |
| M-46 Ortak alan gelir yönetimi | P1 | **Yok.** (KMK m.45: çatı/dış duvar reklam kirası **oybirliği** gerektirir — bu kural hiçbir yerde yok) | 0% |

## Katman 5 — İletişim ve deneyim

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-47 Duyuru | P0 | `[MOCK]` community'de 4 modül (duyuru, anket, ilan, rezervasyon) **auth'suz ve kalıcı değil** — `announcements` tablosu hazır, kod bağlanmamış. Mobilde okuma gerçek; okundu bilgisi yazılmıyor | ~15% |
| M-48 Anket | P1 | `[MOCK]` Anonim ankette **oy verenlerin kimliği sızdırılıyor**; mükerrer oy engeli yok; ağırlıklı oy sabit değerlerden | ~8% |
| M-49 İlan panosu / komşuluk | P2 | `[KIRIK]` Mobil `/bulletins` çağırıyor, gateway `/bulletin` → 404. Moderasyon yok | ~8% |
| M-50 Sakin deneyimi | P0 | `[MOCK]` 13 ekranın 8'i hiç ağ çağrısı içermiyor; 12/18 route ulaşılamaz; **release APK'da INTERNET izni yok**; `ios/` yok; push yok; kalıcı oturum yok; ödeme sahte | ~15% |
| M-51 Yönetici deneyimi | P0 | `[MOCK]` 16 modül ağ kodu içermiyor; 17 ekran menüden erişilemez; taban adres yanlış (`/v1`) → üretimde her çağrı 404; RBAC fail-open; logout token silmiyor; **rakibin en büyük boşluğu olan "mobilden gider/tahsilat girme" hâlâ yok** | ~12% |
| M-52 Destek ve geri bildirim | P1 | **Yok.** `nps` servisi `[MOCK]`, ekran yok | ~2% |

## Katman 6 — Analitik

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-53 Yönetim ve denetim raporları | P0 | `[KIRIK]` Rapor içeriği hardcoded. Dashboard istatistikleri **hiçbir zaman gerçek veri döndürmüyor** (zarf uyuşmazlığı) → sabit 156/180/12/3/2 | ~8% |
| M-54 Akıllı tahsilat / risk | P2 | `[MOCK]` "AI risk analizi" sabit yanıt | ~3% |
| M-55 Enerji ve ESG | P2 | `[MOCK]` İki servis aynı metrik için **çelişkili** karbon değeri üretiyor (25.000 kg ⟷ 84,4 ton) | ~3% |
| M-56 Yapay zekâ yetenekleri | P2 | `[ÖLÜ]` Gerçek OpenAI kodu 2 kopya halinde var, ikisi de bağlanmamış; `OPENAI_API_KEY` hiçbir yerde tanımlı değil; kullanıcıya dönen her tarama sabit "AYEDAŞ 2.450,75 TL" | ~3% |

## Katman 7 — Ticari

| Modül | Öncelik | Bugünkü durum | Kapsam |
|---|---|---|---|
| M-57 Yönetim organizasyonu (portföy) | P2 | **Yok.** `tenants` tablosu var ama `[ÖLÜ]` | ~2% |
| M-58 Abonelik / faturalama | P3 | **Yok.** `invoices` tablosu `[ÖLÜ]` | ~2% |
| M-59 Onboarding ve veri aktarımı | P1 | `[D1]` Admin panelde CSV yükleme var (residents gerçek, diğerleri state'e yazıyor). Kurulum sihirbazı, doğrulama/ön izleme, açılış bakiyesi, geri alma yok. **Rakipten geçiş** yolu yok | ~10% |
| M-60 Rol ve yetki şablonları | P0 | `[KIRIK]` `RequireRole` **tek** endpoint'te; roller global; admin panelde rol kontrolü **hiç yok**; yönetici mobilde fail-open; denetçi kısıtlanmıyor | ~8% |

## Özet

| Durum | Modül sayısı |
|---|---|
| Gerçekten çalışan (kısmen de olsa) — `[D2]`+ | **4** (M-14, M-22, M-30, ve M-13 şeması) |
| Yazılmış ama kırık/çalışmıyor — `[KIRIK]`/`[ÖLÜ]` | **16** |
| Arayüz var, veri kalıcı değil — `[MOCK]` | **21** |
| Hiç yok | **19** |

**P0 modüllerin ortalama kapsamı ≈ %12.**

---

# BÖLÜM B — Mevcut Özelliklerdeki Mantık Hataları

Denetimden çıkan, **bugün var olan kodu bozan** hatalar. Öncelik: 🔴 kritik · 🟠 yüksek · 🟡 orta.
Bu liste `tasks/todo.md`'deki düzeltme kuyruğunun kaynağıdır.

## B.1 Kurulabilirlik ve derleme

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🔴 B01 | Migration 004 temiz kurulumda çöküyor (`expense_categories` 001 ile çakışıyor) | `004:5,19-30` ⟷ `001:130` | `expenses`/`expense_invoices`/`expense_distributions` hiç oluşmuyor |
| 🔴 B02 | Migration 005 temiz kurulumda çöküyor (`vehicles` 001 ile çakışıyor) | `005:65,102` ⟷ `001:303` | Satır 107'den sonraki **29 tablo** oluşmuyor |
| 🔴 B03 | Zincir: 006 var olmayan `reservations`'ı ALTER ediyor | `006:18` | Soft-delete migration'ı da çöküyor |
| 🔴 B04 | `go build ./...` başarısız — kırık import | `api/handlers/api_credentials_handler.go:8` (`sitesen/...` modülü yok, hedef `package main`) | CI'da derleme/vet/test hiç çalışamıyor |
| 🔴 B05 | Migration sürüm takibi ve çalıştırıcı yok | `backend/cmd/` yalnızca `gateway` | Hangi migration uygulandı bilinmiyor; elle müdahale zorunlu |
| 🔴 B06 | Demo kullanıcı bcrypt hash'i hiçbir şifreyle eşleşmiyor (fiilen test edildi); iki kullanıcıda **aynı** hash | `002:29,32` | Sıfırdan kurulumda giriş yapılamıyor |
| 🟠 B07 | `firebase-credentials.json` mount ediliyor ama dosya diskte yok | `docker-compose.yml:184` | Docker dizin olarak yaratır, notification servisi patlar |
| 🟠 B08 | 001'de 25 `CREATE TABLE`'ın hiçbiri `IF NOT EXISTS` değil; 119/134 index de değil; hiç transaction sarmalaması yok | migration'lar | Migration seti tekrar çalıştırılabilir değil; yarı uygulanmış şema riski |
| 🟠 B09 | CI Go sürümü uyuşmazlığı (`1.21` ⟷ `go.mod 1.24`) | `ci-cd.yaml:38` | Pipeline ilk adımda çöküyor |
| 🟠 B10 | CI'da lint/type-check/flutter adımları `\|\| true`; Trivy `exit-code` yok; smoke test'ler yorum satırı | `ci-cd.yaml:150,154,194,198,206-211,250-254` | Kalite kapısı yok |
| 🟠 B11 | CI var olmayan Deployment'lara `rollout restart` | `ci-cd.yaml:237-241` | Deploy job'u hata veriyor |
| 🟠 B12 | k8s ingress yolu `/v1/...`, servisler `/api/v1/...` sunuyor; `rewrite-target` yok | `ingress.yaml:23-44` | Üretimde tüm istekler 404 |
| 🟡 B13 | 13 servisin `main.go` default portu compose/gateway ile uyuşmuyor; 4 çift çakışıyor | `audit-data-infra.md §4.1` | `PORT` env'i olmayan her ortamda kırık |
| 🟡 B14 | `003` `audit_logs` tablosunu `DROP` ediyor | `003:63` | Denetim izi migration ile silinebiliyor |
| 🟡 B15 | Seed verisi tutarsız (`total_units=24` ama 6 birim; arsa payı toplamı 2480 ⟷ `total_share_ratio=10000`) | `002:10,18-24` | Dağıtım testleri yanlış sonuç üretiyor |

## B.2 Güvenlik ve yetkilendirme

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🔴 B16 | Giriş şifresi düz metin sunucu log'una yazılıyor | `admin/src/app/api/auth/[...nextauth]/route.ts:17` | KVKK ihlali |
| 🔴 B17 | Gateway'de auth yok; Kong'da JWT plugin'i 0; 22 servis auth'suz | `cmd/gateway/main.go:422`, `kong.yml` | Maaş, TCKN, IBAN, **API anahtarları** token'sız erişilebilir |
| 🔴 B18 | `POST /users/me/active-property` sahiplik doğrulamıyor | `identity/repository/user.go:87-91` | Herkes başka sitenin `property_id`'sini alıp o siteye erişebiliyor |
| 🔴 B19 | Roller siteye göre değil global | `users.roles TEXT[]`, `service/auth.go:146` | Bir sitede yönetici olan **tüm sitelerde** yönetici |
| 🔴 B20 | `JWT_SECRET` boşsa boş anahtarla imza doğrulanıyor; `WithValidMethods` yok; compose'da bilinen default | `pkg/middleware/auth.go:54-56`, `docker-compose.yml:82` | Saldırgan istediği rolde token üretebilir |
| 🔴 B21 | Sabit şifreleme anahtarı kaynak kodda + KDF yok | `settings/api_credentials_service.go:138-149` | Tüm saklanan API sırları çözülebilir |
| 🔴 B22 | `RequireSuperAdmin` istemci başlığına güveniyor | `api/handlers/api_credentials_handler.go:26-38` | `curl -H "X-User-Role: super_admin"` ile tam yetki (şu an derlenmiyor) |
| 🔴 B23 | `GET /assessments/:id` yetki/tenant kontrolü yok (IDOR) | `finance/handlers/finance.go:84-95` | Her sitedeki her dairenin tahakkuk detayı okunabiliyor |
| 🔴 B24 | Ödemede tahakkuk sahipliği doğrulanmıyor | `finance/repository/finance.go:194-199` | Başka birinin tahakkukuna ödeme bağlanabiliyor |
| 🔴 B25 | `CreateResident` başka siteye ait kullanıcıyı sessizce kendi birimine bağlıyor | `identity/repository/resident.go:115-136` | Tenant sızıntısı + kurbanın adı/e-postası açığa çıkıyor |
| 🔴 B26 | Yönetici mobilde RBAC fail-open (`_roles.isEmpty → true`); `AUDITOR` kısıtlanmıyor | `admin_app/.../main_screen.dart:55,233` | Token bozuksa tam menü; denetçi harcama girebilir |
| 🔴 B27 | Yönetici mobilde router auth guard yok | `admin_app/.../app_router.dart:296-303` | Giriş yapmadan her ekran açılabiliyor; KVKK atlanabiliyor |
| 🟠 B28 | Admin panelde rol bazlı erişim kontrolü **hiç yok** | `session.user.roles` hiçbir sayfada okunmuyor | AUDITOR/STAFF maaş ve API anahtarı sayfalarına girebiliyor |
| 🟠 B29 | Çıkış işlemi token'ı geçersizleştirmiyor (backend no-op, mobilde silinmiyor) | `identity/handlers/auth.go:78-83`, `admin_app/.../main_screen.dart:209-216` | Çalınan token 7 gün geçerli |
| 🟠 B30 | Refresh token access token'dan ayırt edilmiyor | `identity/service/auth.go:143-163` | Access token ile refresh alınabiliyor |
| 🟠 B31 | CORS `*` + `Authorization` her yerde | `gateway/main.go:59-61`, `kong.yml` (24 servis) | Herhangi bir site tarayıcıdan API'ye istek atabiliyor |
| 🟠 B32 | Ziyaretçi QR'ı 8 hex ve süre/kullanım kontrolü yok | `visitor/main.go:270,332-348` | Site girişi kaba kuvvetle denenebilir |
| 🟠 B33 | Plaka tanıma sabit `ALLOW` döndürüyor, auth'suz | `parking/main.go:466-478` | Bariyere bağlanırsa her araca geçiş izni |
| 🟠 B34 | Kimliksiz sensör veri yutma uç noktası | `iot/main.go:36,191-204` | İnternetten sahte veri gönderilebilir |
| 🟠 B35 | Bildirim uç noktaları auth'suz ve `user_id` istemciden | `notification/main.go:44-60,214-227` | Herkes tüm sakinlere bildirim/SMS gönderebilir; başkasının bildirimlerini alabilir |
| 🟠 B36 | TCKN hiç şifrelenmiyor (kolon var, `pkg/encryption` `[ÖLÜ]`) | `identity/repository/user.go:148`, `personnel/main.go:19`, `visitor/main.go:23` | KVKK; hukuki metindeki "AES-256 ile şifrelenir" beyanı yanlış |
| 🟠 B37 | Ham veritabanı hata metinleri istemciye dönüyor | `finance/handlers/finance.go:33-35` + 5 servis | Bilgi toplama |
| 🟡 B38 | `MaskTCKN` belirli uzunlukta panic ediyor | `pkg/encryption/aes.go:89-94` | Negatif indeks |
| 🟡 B39 | Admin panelde token `localStorage`'da; köprü tek yerde (`Sidebar`) | `sidebar.tsx:68` | XSS'te token çalınır; Sidebar yüklenmeden istekler token'sız |
| 🟡 B40 | Paralel 401'lerde N eşzamanlı refresh | `api-client.ts` | Rotasyon nedeniyle oturum düşmesi |
| 🟡 B41 | Anonim ankette oy verenlerin kimliği dönüyor | `survey/main.go:290-315` | Gizlilik ihlali |
| 🟡 B42 | Banka kullanıcı adı/şifresi XML'e kaçışsız gömülüyor | `banking/provider/turkish_banks.go:155-174` | XML injection |
| 🟡 B43 | Audit kaydına sırrın son 6 karakteri düz metin yazılıyor | `settings/api_credentials_service.go:227-228` | Sır sızıntısı |
| 🟡 B44 | `DB_SSLMODE` hiçbir yerde tanımlı değil → `disable` | `pkg/database/postgres.go:32` | Veritabanı bağlantısı şifresiz |

## B.3 Para doğruluğu

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🔴 B45 | `GetUnitBalance` kartezyen join → bakiye kullanıcı sayısıyla çarpılıyor | `finance/repository/finance.go:35-43` | 1.200 TL borç 187.200 TL görünüyor. Doğru hesap `unit_balances` view'ında (`001:422`) hazır |
| 🔴 B46 | Ödeme hiç tamamlanmıyor: `paid_amount` güncellenmiyor, `UPDATE monthly_assessments` repoda yok | `finance/repository/finance.go:206-224` | Ödeyen sakin sonsuza dek borçlu; `ListDebtors` onu borçlu gösteriyor |
| 🔴 B47 | Ödeme transaction'sız + `payment_assessments` hatası yutuluyor + `amount` yazılmıyor | `finance/repository/finance.go:219-220` | Yarım ödeme kaydı; mutabakat imkânsız |
| 🔴 B48 | Ödeme idempotent değil | `finance/service/finance.go` | Çift tıklama/ağ kopması → mükerrer ödeme |
| 🔴 B49 | Mobilde ödeme tamamen sahte ("Ödeme Başarılı!", hiç ağ çağrısı yok) | `dues_payment_screen.dart:315-318` | Kullanıcı borcunu ödediğini sanıyor |
| 🟠 B50 | Para her yerde `float64` (şema `DECIMAL`) | `finance/models`, `repository`, `pkg/payment`, `pkg/reports` | Kuruş kaçağı; `Σ details ≠ total` |
| 🟠 B51 | Tahakkuk dağıtımında kuruş yuvarlaması/kalan dağıtımı yok | `finance/repository/finance.go:465,481,495` | Tahakkuk toplamı gider toplamına eşit olmuyor (yasal sorun) |
| 🟠 B52 | Gecikme tazminatı hiç hesaplanmıyor (`late_fee` hep 0) | şema var, kod yok | KMK m.20/2 (aylık %5) uygulanmıyor → alacak eksik |
| 🟠 B53 | `CalculateTotalAmount`'ta `deleted = 0` yok | `finance/repository/finance.go:197` | Silinmiş tahakkuk için ödeme alınabiliyor |
| 🟠 B54 | Tahsilat oranı `int()` ile kesiliyor | `finance/repository/finance.go:140` | %99,9 → %99 |
| 🟡 B55 | `ListDebtors` yalnızca `OWNER` sakinleri sayıyor | `finance/repository/finance.go:267` | Kiracılı/boş daireler borç listesinde görünmüyor → toplam borç eksik |
| 🟡 B56 | `ListPropertyPayments` tenant filtresi ödemenin değil kullanıcının üyeliğine bakıyor | `finance/repository/finance.go:301-310` | İki sitede dairesi olan sakinin B sitesi ödemesi A yöneticisine görünüyor |
| 🟡 B57 | Otopark ücreti sabit `50.00`; rezervasyon ücreti sabit `100.00`; bordro sabit `125000` | `parking/main.go:451`, `reservation/main.go:423`, `personnel/main.go:150` | Mali hesaplar keyfi |
| 🟡 B58 | IBAN doğrulaması/normalizasyonu yok | `banking/main.go:78` | Unique index etkisiz (`TR12 0001` ≠ `TR120001`) |

## B.4 Veri tutarlılığı

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🔴 B59 | Denetim izi INSERT'i kolon adı uyuşmazlığından her seferinde hata veriyor, hata yutuluyor | `pkg/audit/audit.go:28` ⟷ `003:63-76`; `pkg/middleware/auth.go:115` | `audit_logs` kalıcı boş — KVKK taahhüdü karşılanmıyor |
| 🔴 B60 | Soft-delete: hiçbir yerde `SET deleted = 1` yok | grep | Silme özelliği tamamen işlevsiz; frontend'in "sildim"i yalnızca kendi state'i |
| 🟠 B61 | `deleted = 0` filtresi 11 sorguda eksik; community'de **hiç yok** | `audit-data-infra.md §2.5` | Silinmiş kayıtlar listelerde görünüyor |
| 🟠 B62 | İki farklı soft-delete konvansiyonu (`is_deleted BOOLEAN` ⟷ `deleted INTEGER`) | `005:437-439` ⟷ `006:6` | Belirsizlik |
| 🟠 B63 | Talep kaydında `unit_id` hiç yazılmıyor | `community/repository/request.go:105-106` | Daire bazlı talep raporu imkânsız |
| 🟠 B64 | Talep durum güncellemesinde site kontrolü yok | `community/service/request.go:63-78` | Başka sitenin talebi güncellenebiliyor |
| 🟠 B65 | Read-modify-write, transaction yok (kayıp güncelleme / TOCTOU) | `identity/repository/resident.go:149-169`, `community/service/request.go:68-77` | Eşzamanlı düzenlemede biri diğerini eziyor; durum makinesi atlatılabiliyor |
| 🟠 B66 | Dashboard aggregator yanıt zarfı uyuşmazlığından hiç çalışmıyor | `gateway/main.go:459-463` | Her koşulda sabit 156/180/12/3/2 |
| 🟠 B67 | `/api/v1/assessments` ve `/api/v1/payments` gateway'den 404 (finance yalnızca `/api/v1/finance/*` sunuyor) | `gateway/main.go:148` ⟷ `finance/main.go:37` | Aidat listesi ve son ödemeler hiç gelmiyor |
| 🟠 B68 | `expense_categories` iki çelişkili sözleşmeyle okunuyor; gateway yanlış servise yönlendiriyor | `expense/main.go:131-144` ⟷ `finance/repository/finance.go:549` | Tahakkuk formu yanlış kategori kimlikleri gönderiyor → UUID cast hatası |
| 🟡 B69 | Sayfalama hiçbir listede yok; bazı yerlerde sabit `LIMIT 50` (sayfa 2 yok) | `finance/repository/finance.go:232,312` vb. | 500 daireli sitede tüm satırlar çekiliyor; ödeme geçmişi 50'de kesiliyor |
| 🟡 B70 | Tahakkukta map iterasyonu → nondeterministik INSERT sırası | `finance/repository/finance.go:504` | Deadlock riski, tekrarlanamayan testler |
| 🟡 B71 | Ticket numarası 8 hex, retry yok | `community/service/request.go:51` | ~77k kayıtta çakışma → 500 |
| 🟡 B72 | Boş `property_id` ile UUID cast hatası → yanıltıcı 500 | `identity/handlers/resident.go:40` | "Sakinler alınamadı" |
| 🟡 B73 | Rezervasyon çakışma engeli yalnızca aynı başlangıç saatini kapsıyor | `005:282-283` | 10:00-12:00 ile 11:00-13:00 çakışabiliyor (`EXCLUDE USING gist` gerekli) |
| 🟡 B74 | `context.Background()` kullanımı (istek iptali yayılmıyor) | 4 servis, 18 yer | Sızan sorgular |
| 🟡 B75 | Kontrolsüz tip dönüşümü (panic riski) | `finance/repository/finance.go:244-253` | Sürücü tipi değişirse 500 |
| 🟡 B76 | 105 FK'da `ON DELETE` davranışı belirtilmemiş | migration'lar | Silme hiçbir şekilde yapılamıyor |
| 🟡 B77 | Kritik sorgu kolonlarında index yok (`monthly_assessments(property_id)`, `(due_date)`; isim aramada leading-wildcard) | `audit-data-infra.md §A5` | Full scan |

## B.5 Dürüstlük (kullanıcıya yalan söyleyen davranışlar)

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🔴 B78 | 22 servis yazma işleminde `2xx` dönüyor ama hiçbir yere kaydetmiyor | `audit-backend-services.md M-1` | Sessiz veri kaybı |
| 🔴 B79 | Admin panelde 9 noktada sessiz mock fallback (uydurma mali özet) | `expenses/page.tsx:75-81` vb. | Sunucu çökse bile kullanıcı uydurma rakam görüyor |
| 🔴 B80 | Credentials sayfası hata alınca **uydurma şifre** gösteriyor; audit log yalnızca React state'inde | `credentials/page.tsx:92-95,107-108` | Yanlış sır gösterimi + denetim izi yok |
| 🔴 B81 | Sahte başarı mesajları: mobil ödeme/talep/ziyaretçi/belge, yönetici mobil 11 yer, admin panel ayarlar/bildirim/rapor | Bölüm 3.6, `audit-raporu.md` | Kullanıcı işlemin yapıldığını sanıyor |
| 🟠 B82 | Mobilde her `catch` sessizce boş listeye düşüyor | `announcements_screen.dart:42-44` + 4 ekran | Kullanıcı "veri yok" sanıyor, sunucu hatasını hiç görmüyor |
| 🟠 B83 | Soft-delete 13/14 admin panel sayfasında yalnızca state'e yazılıyor | `audit-admin-panel.md` | F5'te silinen kayıt geri geliyor |
| 🟠 B84 | Sağlık kontrolleri `ai_enabled: true` diyor, AI yok | `energy_analytics/main.go:86` + 2 servis | İzleme sistemi ve ekip yanıltılıyor |
| 🟠 B85 | "API Ayarları" ekranı "şifrelenmiş saklanır, her değişiklik kayıt altında" diyor — tüm ekran mock | `admin_app/.../api_settings_screen.dart:191-192` | Yanlış güvence |
| 🟡 B86 | Hukuki metinde doğrulanamayan taahhütler (AES-256 şifreleme, rol bazlı yetki, TLS 1.3, günlük yedekleme, periyodik sızma testi) | `legal/kvkk-aydinlatma.md:114-118` | Yanlış beyan riski |

## B.6 Ölü kod ve arayüz erişilebilirliği

| # | Bulgu | Kanıt | Etki |
|---|---|---|---|
| 🟠 B87 | ~3.900 satır bağlanmamış Go kodu (`pkg/tenant`, `encryption`, `payment`, `notification`, `ai`, `integrations/*`, `banking/provider`, `api/`) | `audit-backend-services.md` | Bakım yükü; "var" sanılan özellikler |
| 🟠 B88 | 61 tablonun 47'si (%77) hiç kullanılmıyor | `audit-data-infra.md §1` | Ölü şema |
| 🟠 B89 | Sakin mobilde 12/18 route arayüzden ulaşılamıyor; "Daha Fazla" menüsündeki 10 öğenin tamamı `onTap: () {}` | `more_screen.dart:64-121` | Kullanıcı 4 sekme görüyor, kalan ekranlar erişilemez |
| 🟠 B90 | Yönetici mobilde 17 ekran menüden erişilemiyor | `audit-mobile-manager.md` | Aynı |
| 🟠 B91 | Admin panelde çıkış (logout) butonu **hiç yok**; mobil navigasyon erişilemez | `audit-admin-panel.md` | Kullanıcı oturumunu kapatamıyor |
| 🟡 B92 | Community'de 13 endpoint gateway'den asla çağrılmıyor (survey/reservation/bulletin başka servise yönlendirilmiş) | `community/main.go:58-83` | Ölü route + sahiplik belirsizliği |
| 🟡 B93 | Admin panelde `zod`/`react-hook-form`/`recharts`/`date-fns`/7 Radix paketi kurulu, hiç kullanılmıyor; 17 hook'un 13'ü ölü | `audit-admin-panel.md` | CLAUDE.md'deki "zod + react-hook-form + Recharts" mimari beyanı gerçek değil |
| 🟡 B94 | Mobilde 13/22, yönetici mobilde 16 bağımlılık hiç kullanılmıyor (`intl`, `fl_chart`, `firebase_*`, `freezed`, `retrofit`...) | `audit-mobile-*.md` | Riverpod pratikte kullanılmıyor (43 ekran `setState`); para/tarih biçimlendirme elle ve bozuk |
| 🟡 B95 | `api_client`/`api-client` metotları var olmayan uçlara gidiyor (admin 5, sakin 3) | `audit-admin-panel.md §3`, `audit-mobile-resident.md §3` | Sessiz 404 |
| 🟡 B96 | Testler kendi yazdıkları sahte fonksiyonları test ediyor (3/4 dosya); yönetici mobilde `flutter test` derlenmiyor | `finance_test.go:281`, `auth_test.go:247`, `admin_app/test/widget_test.dart:16` | Test güvencesi yanılsaması |
| 🟡 B97 | OpenAPI bayat: 2 dokümante uç kodda yok, sonradan eklenen ~15 uç dokümante değil | `api/openapi.yaml` | Sözleşme güvenilmez |

---

# BÖLÜM C — Mevcut Özelliklerde Düşünülmemiş Tamamlayıcılar

Kullanıcının asıl sorusu: *"her bir özellikte düşünülememiş ve olması gereken tamamlayıcı şeyler."*
Aşağıda **bugün var olan** her özellik için, o özelliği gerçekten kullanılabilir kılacak eksik parçalar.

## C.1 Giriş / oturum
Var: telefon+şifre girişi, JWT, refresh, KVKK onayı (backend).
Eksik tamamlayıcılar:
- Şifremi unuttum akışı (SMS/e-posta OTP ile sıfırlama) — **hiç yok**, rakibin en çok şikayet edilen noktası
- Telefon doğrulama (OTP) — kayıt/değişiklik sırasında
- Şifre politikası ve şifre değiştirme ekranı
- Hesap kilitleme / deneme sınırı / oran sınırı
- Gerçek çıkış (token geçersizleştirme, cihazdan silme)
- Oturum açık cihaz listesi ve uzaktan çıkış
- 2FA (yönetici/muhasebe için)
- Davet akışı: yönetici sakini davet eder → sakin kendini aktive eder (bugün yönetici sakin adına hesap açıyor, şifre nasıl iletiliyor belirsiz)
- Birden fazla dairesi/sitesi olan kullanıcı için site değiştirici (backend var, mobilde yok)
- Kalıcı oturum + biyometrik ile hızlı giriş (mobilde `[KIRIK]`)
- Rol değişince mevcut token'ın yetkisinin güncellenmesi
- Kullanıcı siteden ayrıldığında erişimin otomatik kesilmesi

## C.2 Sakinler / birimler *(en olgun modül)*
Var: liste, arama, ekleme, güncelleme, pasifleştirme, birim listesi, CSV yükleme.
Eksik tamamlayıcılar:
- **Tarihli ilişki:** malik/kiracı ne zaman girdi, ne zaman çıktı → borcun hangi döneme kimin sorumluluğunda olduğu bugün hesaplanamıyor
- **Malik ↔ kiracı ayrımı ve müteselsil sorumluluk** (KMK m.22: kiracı kira bedeli kadar sorumlu)
- Paylı malikiyet (pay oranı), mirasçı, vekil, intifa hakkı
- Aile üyesi / ek kullanıcı (eşin de uygulamayı kullanması)
- Kiracı sözleşmesi (süre, kira, depozito, artış) ve çıkış işlemleri
- **Devir / "borcu yoktur" belgesi** (daire satışında zorunlu operasyon)
- Sakin detayında **borç/ödeme görünümü** (finance entegrasyonu — bugün bilinçli olarak kaldırılmış)
- TCKN şifreleme + maskeleme + erişim denetimi (kolonlar var, hiç kullanılmıyor)
- Mükerrer kişi kaydı tespiti ve birleştirme
- Yabancı uyruklu malik (TCKN yok), iletişim bilgisi olmayan malike tebligat
- Sayfalama + sunucu tarafı arama (bugün tüm liste çekiliyor, isim aramasında full scan)
- Toplu içe aktarma: **doğrulama + ön izleme + tümü-veya-hiç + geri alma** (bugün satır satır API çağrısı, hatalı satır raporu yok)
- Boş daire yönetimi (gider yükümlülüğü devam eder)
- Sakin arşivi (ayrılanların geçmişi)

## C.3 Aidat / tahakkuk
Var: gider kalemlerinden dönemsel tahakkuk üretme (dağıtım matematiği doğru), dönem özeti, borçlu listesi.
Eksik tamamlayıcılar:
- **İşletme projesi (yıllık bütçe)** — tahakkukun yasal dayanağı (KMK m.37); bugün aidat "elle girilen tutar"
- **Tebliğ ve itiraz süreci** (7 gün) — tebliğ edilmemiş tahakkuk icraya konulamaz
- **Ön izleme ve onay**: tahakkuk oluşturmadan önce daire bazlı sonuç tablosu
- **Geri alma / ters kayıt** (yanlış tahakkuk için; silme değil)
- Kuruş yuvarlama ve kalan dağıtımı (toplam tutmalı)
- **Gecikme tazminatı** (aylık %5, parametrik), faiz dondurma, af/indirim yetkisi ve denetim izi
- Gün bazlı bölüşüm (ayın ortasında el değiştiren daire)
- Sayaç bazlı kalemler için okuma eksikse tahakkuku bekletme
- Tek seferlik/olağanüstü tahakkuk (demirbaş, büyük onarım) ve taksitlendirme
- Blok gideri ↔ site gideri ayrımı
- Zemin kat asansör muafiyeti, işyeri katsayısı gibi kuralların **parametreye** bağlanması (bugün bayraklar var ama kural yönetim planına bağlı değil)
- Arsa payı toplamı beklenen değilse **hata verip durma**
- Geçmiş dönem düzeltmesi ve fark tahakkuku
- Tahakkuk tebliği bildirimi (push/SMS/e-posta)

## C.4 Ödeme / tahsilat
Var: `payments` tablosuna `PENDING` kayıt; rol duyarlı ödeme listesi.
Eksik tamamlayıcılar (bu modül bugün **fiilen çalışmıyor**):
- Ödemenin **tamamlanması**: `paid_amount` güncelleme, tahakkuk durumunun kapanması
- **Kalem seçerek / kısmi ödeme** (sepet) — rakibin en büyük şikayeti: "para yanlış kalemden düşüyor"
- **Mahsup sırası kuralı** (en eski borç / faiz-anapara sırası) — yapılandırılabilir
- Ödeme sağlayıcısı (kart, 3D Secure, taksit) — **native**, WebView değil
- **Idempotency** (çift tıklama, ağ kopması, sağlayıcı tekrarı)
- Beklemede kalan ödeme durumu + otomatik sorgulama
- **Banka ekstresi içe aktarma + otomatik eşleştirme + eşleşmeyenler kuyruğu** (yöneticinin en çok istediği)
- Webhook ile anında borç düşümü (gereksiz faiz oluşmaması)
- Otomatik ödeme talimatı / düzenli ödeme
- Mükerrer/fazla ödeme → iade veya alacak olarak bekletme
- **Makbuz/dekont üretimi** ve sakine iletilmesi
- Kasa (elden nakit) tahsilatı ve kasa sorumluluğu
- Komisyon muhasebesi (sakine mi yönetime mi)
- Üçlü mutabakat: sağlayıcı raporu ↔ banka hesabı ↔ sistem kaydı
- Farklı kalemler için farklı hesap kullanımı (rakip şikayeti: hepsi tek hesaba gidiyor, karışıyor)

## C.5 Gider / muhasebe
Var: gider listesi ve ekleme ekranları (kalıcı değil), kategori yönetimi (iki çelişkili sözleşme).
Eksik tamamlayıcılar:
- Kalıcılık (bugün hiçbir gider kaydedilmiyor)
- Fatura görüntüsü eki + OCR + **manuel doğrulama** (bugün sabit AYEDAŞ yanıtı)
- Mükerrer fatura engeli (fatura no + tedarikçi tekilliği)
- **Bütçe kontrolü**: kalem bazlı aşımda uyarı/onay eskalasyonu
- Onay akışı (tutar eşiğine göre), faturasız gider için gerekçe ve özel onay — **sunucuda** zorlanan
- Tekrarlayan giderler (abonelik, bakım sözleşmesi)
- Satın alma: teklif toplama (en az 3), karşılaştırma, sipariş, teslim, hakediş
- Gider iptal/iade (tedarikçi iadesi), geç gelen fatura politikası
- **Giderin aidata yansıtılması** kuralının gider kaydında tanımlanması
- KDV/stopaj, e-fatura arşivi
- Giderin bir talebe/varlığa bağlanması (maliyet takibi)
- **Kasa/banka bakiyesi ve nakit akışı** (yöneticinin ilk baktığı şey — bugün hiç yok)
- Dönem kapanışı ve **kilitleme**, devir bakiyesi, mutabakat
- Gelir kalemleri (`incomes` tablosu yok), aidat kararları (`dues_decisions` tablosu yok)
- Gelir-gider defteri (KMK m.36) resmî çıktısı

## C.6 Talepler *(ikinci olgun modül)*
Var: gerçek DB, durum makinesi, sakin onayı ile kapanış, kategori.
Eksik tamamlayıcılar:
- **Dosya/fotoğraf eki** (butonlar var, `() {}`)
- `unit_id` kaydı (bugün hiç yazılmıyor) → daire bazlı rapor
- **Atama** (personel/tedarikçi) ve iş emri çıktısı
- **SLA** (ilk yanıt / çözüm süresi) ve süre aşımı eskalasyonu
- Ortak alan ↔ bağımsız bölüm içi ayrımı (masraf kime ait)
- Yorum/mesajlaşma (`request_comments` tablosu var, kod yok; OpenAPI'de dokümante ama endpoint yok)
- Aynı arızayı bildiren taleplerin **birleştirilmesi**
- Maliyet ilişkilendirme, garanti kapsamı kontrolü
- Memnuniyet puanı, tekrarlayan arıza analizi
- Gizlilik seçeneği (komşu şikayetinde bildiren kimliğinin gizlenmesi)
- Belirli süre tepkisiz kalırsa otomatik kapanış kuralı
- Silme uç noktası (bugün yok — soft-delete kolonu boşta)
- Mobilde listenin gerçekten API'den gelmesi (bugün hardcoded → onay akışı çalışmıyor)

## C.7 Duyurular
Var: mobilde okuma (gerçek), admin panelde sayfa (mock), `announcements` + `announcement_reads` tabloları hazır.
Eksik tamamlayıcılar:
- Kalıcılık ve auth (bugün auth'suz mock)
- **Hedefleme** (site/blok/kat/rol/borçlular/belirli kişiler)
- **Okundu bilgisi** ve okumayanlara hatırlatma (tablo var, kod yok)
- Dosya eki, zengin içerik
- Planlı yayın + son geçerlilik tarihi, sabitleme
- Çok kanallı yayın (push + SMS + e-posta) ve panoya asma çıktısı
- Kiracı mı malik mi hedeflenecek ayrımı
- Kesinti duyurularının takvime düşmesi
- Arşiv ve arama
- **Resmî tebligat ile karıştırılmaması** (tebligat M-17/M-21'de ayrı ele alınmalı)

## C.8 Sayaçlar / tüketim
Var: mock sayaç listesi; `meters`, `meter_readings` (hesaplanan `consumption` kolonu ile), `consumption_tariffs`, `consumption_invoices` tabloları hazır.
Eksik tamamlayıcılar:
- Kalıcılık (bugün `submitReading` sabit `12.5` döndürüyor)
- Okuma doğrulama: geriye giden sayaç, aşırı sapma, sıfır tüketim, mükerrer dönem
- **Yönetmeliğe uygun ısı paylaşımı** (ölçülen + ortak alan payı), sıhhi sıcak su, kayıp-kaçak
- Arızalı/okunamayan sayaç için ortalama tüketim kuralı
- **Tüketim detay faturası** (dönem, ilk-son okuma, miktar, birim fiyat, ortak alan payı, PDF) — rakibin somut şikayeti
- Mobil ile fotoğraflı okuma girişi, toplu (CSV) içe aktarma, uzaktan okuma
- Sayaç değişiminde iki okumanın birleştirilmesi, çarpan/kalibrasyon
- Tüketim itirazı süreci
- Anormal tüketim / kaçak uyarısı, komşu-dönem karşılaştırma
- Yakıt alım maliyetinin dönemlere yayılması, ısıtma sezonu tanımı
- Boş dairenin asgari ısınma payı

## C.9 Raporlar
Var: gerçek PDF/Excel motoru, indirme akışı.
Eksik tamamlayıcılar:
- **Gerçek veriyle beslenme** (bugün içerik hardcoded)
- İstenen rapor türü/dönem/site parametrelerinin dikkate alınması (bugün yok sayılıyor)
- Auth + sahiplik kontrolü (bugün kimliksiz, rapor kimliğini bilen indirebiliyor)
- Raporların kalıcı saklanması + TTL (bugün RAM'de, sınırsız → DoS)
- Rapor kataloğu: bütçe-gerçekleşme, alacak yaşlandırma, kasa/banka mutabakat, gecikme tazminatı, personel maliyeti, SLA, tüketim, **yıllık hesap özeti (KMK m.39)**, **denetçi paketi (m.41)**
- Zamanlanmış rapor + e-posta gönderimi
- Raporun üretildiği andaki veriyi dondurma (aynı rapor sonradan farklı sayı vermemeli)
- Ekran ile rapor arasında sayı tutarlılığı
- Resmî çıktı biçimi (logo, imza alanı, üretim zamanı ve üreten kullanıcı)
- Büyük rapor için asenkron üretim + hazır olunca bildirim

## C.10 Ayarlar / API kimlik bilgileri
Var: ayarlar sayfası (kaydetmiyor), credentials sayfası (mock, sahte şifre gösteriyor).
Eksik tamamlayıcılar:
- Kalıcılık + auth + rol kısıtı (bugün kimliksiz, kullanıcı "admin" sabit)
- **Sağlam anahtar yönetimi** (env zorunlu, KDF, anahtar rotasyonu — bugün sabit anahtar kodda)
- Sır gösterme uç noktası (bugün hiç yok; sayfa yanlış endpoint'i çağırıyor) + her erişimin **backend'e** loglanması
- Site parametreleri: gecikme oranı, mahsup sırası, dağıtım kuralları, ısı paylaşım oranları, ödeme günü, çalışma saatleri — **yürürlük tarihli**
- Yönetici kullanıcı yönetimi (rol atama, davet, yetki matrisi)
- Bildirim şablonları ve kanal ayarları
- Site profili (logo, iletişim, banka hesapları, IBAN)
- Yedekleme/veri ihracı, KVKW veri talebi karşılama

## C.11 Otopark, ziyaretçi, kargo, rezervasyon, personel, varlık, sözleşme, envanter, anket, ilan, belge, banka, devriye, toplantı, akıllı tahsilat, ESG/NPS/enerji
Bu 19 alanın tamamı `[MOCK]`: ekranlar var, veri kalıcı değil, auth yok, iş kuralları yok.
**Her biri için ortak eksik tamamlayıcılar:**
- Kalıcılık (DB'ye bağlanma) ve `2xx` yerine `501` dönme (bağlanana kadar)
- `AuthMiddleware` + rol kısıtı + tenant filtresi
- Temel iş kuralları (rezervasyonda çakışma, otoparkta süre/tarife, personelde izin bakiyesi, ankette mükerrer oy engeli...)
- İlgili tabloların migration'da gerçekten oluşması (bugün 005 çöktüğü için çoğu tablo yok)
- Menüden erişilebilirlik (bugün 17 + 12 ekran ulaşılamaz)
- Denetim izi ve soft-delete
Alan bazlı ayrıntılar `tasks/modul-envanteri.md` M-32…M-49'daki "Sık atlanan tamamlayıcılar" satırlarındadır.

## C.12 Platform genelinde eksik tamamlayıcılar
- **Dosya depolama** altyapısı (bugün `/tmp`, volume yok, indirme yok) → tüm belge/fotoğraf özellikleri buna bağlı
- **Bildirim altyapısı** (kuyruk, şablon, tercih, teslim raporu) → tüm bildirim özellikleri buna bağlı
- **Parametre yönetimi** → tüm mevzuat kuralları buna bağlı
- **Onay motoru** → gider, tadilat, izin, tahakkuk onayları buna bağlı
- Sayfalama, arama, sıralama standardı
- Hata/boş/yükleniyor durum standardı (tüm arayüzlerde)
- Para ve tarih biçimlendirme standardı (TR locale)
- Gözlemlenebilirlik (istek kimliği, metrik, çökme raporu)
- Yedekleme ve **geri yükleme provası**
- Çok dillilik altyapısı (metinler koda gömülü)
- Erişilebilirlik (yaşlı kullanıcı: büyük font, yüksek kontrast)
- Offline davranış (mobil, saha çalışması)
- Test altyapısı (bugün gerçek kapsam ~%0,5)

---

# Sonraki adım

Bu analiz `tasks/roadmap.md`'deki **dikey dilimlere** ve `tasks/todo.md`'deki düzeltme kuyruğuna dönüştürülmüştür.
Sıralama ilkesi: **önce dürüstlük (yalan söylemeyi durdur) → sonra kurulabilirlik → sonra güvenlik/izolasyon →
sonra para doğruluğu → sonra yönetişim katmanı → sonra genişlik.**
