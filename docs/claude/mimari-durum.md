# Mimari durum ve tarihçe

> `CLAUDE.md`'den taşındı (2026-10-29). İçerik değiştirilmedi.

## Project Overview

**SiteEksen** — Türkiye kat mülkiyeti kanununa uyumlu site yönetim platformu. Go mikroservis backend,
Next.js admin paneli, iki Flutter mobil uygulaması (sakin + yönetici) içerir.

### Kritik Mimari Notlar — GERÇEK DURUM (2026-10-10 itibarıyla)

> Aşağıdaki notlar **çalıştırılarak** doğrulanmıştır. Bu bölümdeki hiçbir ifade "olması gerekeni"
> değil, **bugün gerçekte olanı** anlatır.
> Toplu kanıt: `bash backend/scripts/verify-stack.sh` → **1423/1423** (2026-10-26),
> `bash backend/scripts/verify-mobile.sh` → **10/10**.
> Tarihçe ve `dosya:satır` kanıtı: `tasks/audit-raporu.md`, `tasks/changelog.md`.

**Hızlı başlangıç**

```bash
bash backend/scripts/dev-up.sh     # PostgreSQL + 24 servis + gateway (RLS'li app rolüyle)
cd admin && npm run dev            # http://localhost:3001
# Demo: 5551234567 / Demo123! (yönetici) · 5559876543 / Demo123! (kiracı)
# Giriş bilgileri, admin/.env.local içeriği ve sorun giderme: docs/yerel-calistirma.md
# Özellik/yetenek haritası (her sayfa, düğme, uç, bildirim, etki): docs/ozellik-haritasi/README.md
```

- **FAZ 5 TAMAMLANDI (2026-09-14): 22 mock servisin tamamı ele alındı.**
  **20 servis gerçek veri katmanına bağlıdır:** `identity`, `finance`,
  `community` (talep + duyuru), `governance` (KMK yönetişim), `expense`,
  `personnel`, `visitor`, `parking`, `reservation`, `package` (kargo),
  `contract`, `document` (belge arşivi), `asset` (demirbaş), `inventory` (stok),
  `survey` (anket), `iot` (sayaç + ısı payı), `notification` (bildirim),
  `patrol` (devriye), `bulletin` (ilan panosu), `settings`,
  `energy_analytics`, `smart_collection`, `nps`, `esg`.
  **Bir modül bilinçli olarak yazılmadı ve nedenini söyleyerek 501 döner:**
  `banking` (S-07 kullanıcı kararıyla sonraki sürüme bırakıldı).
  `meeting_wizard` servisi, `settings` kimlik bilgisi uçları ve ESG sürdürülebilirlik
  skoru 2026-10-26'da kaldırıldı (FAZ H.1; özellikleri başka yerde var). `iot`
  sensörleri 074 ile gerçek (FAZ H.4). Sağlayıcı durumu:
  `GET /api/v1/integrations/status` (gateway).
- **Uygulama veritabanına SÜPER KULLANICIYLA BAĞLANMIYOR — dev-up, doğrulama,
  docker compose ve k8s'in dördünde de.** İki rol vardır:
  `siteeksen_identity` (yalnızca kimlik servisi: dizin + jeton iptal tabloları,
  site verisine erişim YOK) ve `siteeksen_app` (diğer 24 servis ve zamanlayıcı: RLS'e tabi,
  dizin tablolarını yalnızca okur, `users.password_hash`/TCKN sütunlarını
  göremez, denetim izini ve jeton iptalini silemez). Parolaları `cmd/migrate`
  `APP_DB_PASSWORD` / `IDENTITY_DB_PASSWORD` ile atar; depoya yazılmaz.
  RLS **129 tabloda** açık; dışarıda kalan 10 tablonun her biri gerekçelidir ve
  doğrulama listeyi birebir denetler. Tüm görünümler `security_invoker`
  (aksi hâlde görünüm sahibinin yetkisiyle RLS'i atlıyordu).
- **Dağıtım dosyaları tek kaynaktan üretilir:** `backend/scripts/gen-deploy.py`
  → 28 Dockerfile (root değil, uid 10001), `docker-compose.yml`, `k8s/*.yaml`,
  CI imaj matrisi. Elle düzenlenmez; `--check` kipi doğrulamada sapmayı yakalar.
  Compose zorunlu gizli değerler (`.env`, şablon `.env.example`) yoksa açılmaz.
- **Modüller artık gerçekten bildirim gönderiyor.** 15 servis (55 uç) ve zamanlayıcı (14 iş; 11'i bildirim üretir) `pkg/notify`
  üzerinden bildirim üretir; tam katalog `docs/ozellik-haritasi/04-bildirim-zamanlayici-tetikleyici.md`.
  Kişisel bildirim kutusu (`GET /notifications`, okundu bilgisiyle — 073) panelde (zil + `/dashboard/inbox`) ve
  iki mobil uygulamada var. Alıcı kümesi (sakinler / daire
  sakinleri / yönetim) `pkg/notify/audience.go`'da tek yerde tanımlıdır:
  beş modül aynı sorguyu ayrı yazsaydı, birinde `is_active` filtresi
  unutulduğunda siteden taşınmış birine bildirim giderdi. Yanıtlar
  sayaçlarla döner; "gönderildi" sözcüğü yalnızca gerçekten gönderilen
  kayıt varsa geçer, sağlayıcısız kanallar "kuyrukta bekliyor" der.
- **"Yapay zekâ" iddiası kaldırıldı.** Enerji analizi, tahsilat riski ve karbon
  ayak izi GERÇEK hesaplar yapar ama YZ kullanmaz: formüller kodda yazılıdır,
  her sonuç gerekçesiyle döner. `ai_model_version`, `predictions`,
  `predicted_payment_probability` alanları bilerek boş bırakılır.
- **Dosya saklama artık var (S-09):** `pkg/storage`. Yerel dosya sistemi ya da S3
  uyumlu sağlayıcı (Oracle Object Storage / Cloudflare R2 / AWS S3). S3 imzalama
  (SigV4) harici bağımlılık olmadan, yalnızca stdlib ile yazıldı. Yapılandırma
  eksikse servis açılmaz — sessizce "yüklendi" demez.
- **Para hesapları `pkg/money` üzerinden, tam sayı KURUŞ ile yapılır.** Dağıtımda en büyük
  kalan yöntemi kullanılır; payların toplamı tutara birebir eşittir. Yeni para kodu
  `float64` kullanmaz.
- **Mevzuata bağlı hiçbir oran koda gömülmez.** Gecikme tazminatı, ısıtma paylaşımı,
  nisaplar ve vekâlet sınırları `legal_parameters` tablosundadır (`pkg/legalparams`);
  yürürlük tarihli ve hukuki dayanaklıdır. Kanunla sabit olanlar site bazında
  değiştirilemez (veritabanı tetikleyicisi).
- **Roller SİTE BAZLIDIR.** `users.roles` yalnızca platform rolleri içindir; site rolleri
  `property_roles`, sakinlik rolleri (yalnızca OWNER/TENANT/PROXY — CHECK, migration 031) `resident_units` tablosundadır. Jeton rolleri aktif
  siteye göre üretilir.
- **Geri alma = yedekten geri yükleme** (`backend/scripts/db-backup.sh` / `db-restore.sh`, `docs/runbook-veritabani-geri-alma.md`); "down" betiği bilerek yok — denetim izini ve defterleri silerdi. verify-stack adım 41 sınar.
- **İşlem kaydı ve bildirim kutusu (073, 2026-10-26):** `audit_logs` tek kayıt yeri (API/CLIENT/SYSTEM); düzey site ayarı
  `ACTIVITY_LOG_LEVEL` (KAPALI'da da zorunlu çekirdek yazılır), okuma yalnız `audit_log_list` işleviyle; kişisel kutu
  `notification_reads` ile panelde (zil + `/dashboard/inbox`), iki mobil uygulamada. Kayıt istekten bağımsız bağlamla yazılır.
- **Devriye QR + GPS (075, 2026-10-26):** okutma konumu sunucuda noktanın konumuyla karşılaştırılır; red denemeleri kanıt,
  şüpheli hız işaretli, konum izi yalnız açık turda (1 yıl). Yönetici uygulaması `mobile_scanner`/`geolocator`/`flutter_map`,
  panel `qrcode`/`leaflet`. İki mobil uygulamanın debug APK'sı derleniyor (2026-10-26; öncesinde yönetici uygulaması derlenmiyordu).
- **Migration'lar `cmd/migrate` ile uygulanır** (sürüm tablosu, advisory lock, SHA-256
  sağlama, transaction). `docker-entrypoint-initdb.d` kullanılmaz. Uygulanmış bir
  migration dosyası **düzenlenmez** — çalıştırıcı sağlama uyuşmazlığında durur.
- ~~**Veritabanı temiz makinede KURULAMIYOR**~~ → **DÜZELTİLDİ (2026-09-12).** `004`/`005`'teki tablo
  çakışmaları ve `005`'teki geçersiz UUID giderildi. Sıfırdan kurulum artık çalışıyor: 11 migration,
  61 tablo. **Kanıt:** `bash backend/scripts/verify-stack.sh` → 42/42 kontrol geçti.
- ~~**Demo kullanıcı girişi çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Seed'deki bozuk bcrypt hash
  yeniden üretildi. Demo giriş: **`5551234567` / `Demo123!`** (ikinci hesap: `5559876543`).
  **Kanıt:** gerçek identity-service'e `POST /auth/login` → HTTP 200 + JWT; yanlış şifre → 401.
- ~~**Gateway'de kimlik doğrulaması yok**~~ → **DÜZELTİLDİ (2026-09-13).** `/api/v1/auth/*` ve
  `/health` dışındaki her yol geçerli JWT ister; `JWT_SECRET` yoksa fail-closed.
  İstemciden gelen `X-User-*`/`X-Property-Id`/`X-Tenant-Id` başlıkları **silinir**.
  CORS allowlist'e alındı; her isteğe `X-Request-Id` verilir. Kong (isteğe bağlı)
  yalnızca gateway'in önünde durur (2026-09-27). Gateway'in uydurma `/dashboard/*` ve `/reports/*` yanıtları kaldırıldı.
  **Kanıt:** `verify-stack.sh` §8.
- ~~**`go build ./...` BAŞARISIZ**~~ → **DÜZELTİLDİ (2026-09-12).** Ölü `backend/api/` dizini kaldırıldı
  (kırık import + `X-User-Role` başlığına güvenen sahte yetki kontrolü içeriyordu); ayrıca
  `pkg/integrations/sms` ve `pkg/integrations/whatsapp` paketlerindeki derleme hataları giderildi.
  **Kanıt:** `go build ./...` ve `go vet ./...` → çıkış kodu 0.
- ~~**Denetim izi (audit log) çalışmıyor**~~ → **DÜZELTİLDİ (2026-09-12).** Migration `011` ile şema
  koda uyumlu hale getirildi (`property_id`, `request_id`, `status_code` eklendi, `tenant_id` zorunluluğu
  kaldırıldı); `pkg/audit` yeniden yazıldı; `pkg/middleware` artık hatayı yutmuyor ve 403'leri `DENIED`
  olarak ayırıyor. **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı geçiyor + uçtan uca
  istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- **İzolasyon hem uygulama hem veritabanı katmanındadır.** JWT'deki `property_id`
  istemci tarafından değiştirilemez (sahiplik doğrulaması); her servis `pkg/dbscope`
  ile sorguyu site kapsamına bağlar (`SET LOCAL app.property_id`); RLS unutulan
  filtreyi yakalar. RLS'e geçiş sırasında **beş çapraz site açığı** bulundu ve
  kapatıldı (talep, ödeme, itiraz, karar defteri, görünümler). `pkg/tenant` ölü koddur.
- ~~**Para hesaplarında kritik hatalar**~~ → **DÜZELTİLDİ.** Bakiye kartezyen join'i giderildi
  (2026-09-12); ödeme artık `paid_amount`'ı günceller ve borcu düşürür (yönetici onay akışı,
  2026-09-13); gecikme tazminatı KMK m.20/2'ye göre hesaplanır.
  **Kanıt:** `verify-stack.sh` §10.
- **Kartla ödeme VAR (2026-10-10, migration 060):** `pkg/iyzico` (Ödeme Formu, IYZWSv2, stdlib)
  finans servisine bağlıdır; `IYZICO_*` verilmezse kart ödemesi `payment_gateway_ready:false`
  döner ve bu açıkça söylenir. Geri dönüşte sonuç iyzico'dan yeniden sorgulanır; uzlaştırma
  bekçisi askıda ödeme bırakmaz. Doğrulama sahte iyzico iledir — gerçek anahtarla denenmedi.
  SMS (Netgsm) ve e-posta (SMTP) da `pkg/notify` üzerinden bağlıdır (yapılandırılırsa).
- **Beşinci tur (2026-10-11, Şikayetvar raporu, migration 061-065):** yeni borçta sakine bildirim
  (`pkg/notify/charges.go`), yönetimin tahsilat girişi (`payments.recorded_by`), sakinin kendi
  "şifremi unuttum"u ve telefon/e-posta değişikliği (yeni numaraya SMS / yeni adrese e-posta kodu; `phone_change_requests`, `email_change_requests`, yalnız kimlik servisi),
  malikin kiracı/vekil yönetimi, kademeli giriş kilidi, ilişik kesme tarihi (`resident_units.end_date`),
  paylaştırmada medyan sapma uyarısı + pusula itirazı, havale dekontu (`payment_receipts`, finans
  servisi artık `pkg/storage` kullanır). Kimlik servisi bildirim tablosuna erişemez: malik işlemleri
  yönetime bildirim değil denetim izi üretir. Destek talebi (B10) ve push (B11) kullanıcı kararı bekliyor.
- **Altıncı tur (2026-10-11, malik / kiracı / oturan, migration 066-072):** her mali kalem KULLANIM ya da MALİK sınıfı
  alır (066); dairenin oturum durumu kayıtlardan hesaplanır (`unit_occupancy`, 067); daire başına tek aktif kiracı, davetle
  kayıt, hane üyesi (068); kiracılık yalnız bitiş akışıyla biter — kiracı onayı, kendi çıkışı ya da belge + şifreyle beyan +
  7 gün itirazlı yönetim yolu (069, kimlik servisi artık `pkg/storage` kullanır); borcun sorumlusu tahakkuk anında saptanır,
  kim görür/öder tek kuralda (`assessment_visible_to`, 070); malikin kiracılı dairede gördüklerini yönetim belirler, kurul
  üyesi onaylar (071); kullanım işlemleri `resident_can_use` kuralına bağlı (072). Kararlar ve varsayılanlar: `tasks/questions.md` S-23.
- **Firebase, Kafka, MongoDB ve AI entegrasyonları hâlâ YOKTUR.** Eski `pkg/payment`,
  `pkg/notification` (FCM), `pkg/ai`, `pkg/integrations/*` **hiçbir yerden import edilmez**
  (ölü kod); var gibi gösterilmez, uydurma AI yanıtları kaldırıldı.
- **Ölü şema büyük ölçüde canlandı.** `005_new_modules.sql`'in tablolarının
  neredeyse tamamı artık kullanılıyor: gider, personel, ziyaretçi, otopark,
  tesis/rezervasyon, kargo, sözleşme, demirbaş+bakım, stok+hareket, anket,
  devriye, ilan panosu. Kullanılmayan kalanlar: `bank_accounts`/`bank_transactions`
  (S-07 kararı), `meetings` (governance ile tekrar), `energy_analytics` ve
  `payment_risk_scores`'un "AI" kolonları (bilerek doldurulmuyor).
  `012`–`017` tablolarının **tamamı kullanılıyor**.
- **Admin panel API hedefi:** `NEXT_PUBLIC_API_URL` (yerel geliştirme:
  `http://localhost:8888/api/v1`). `admin/.env.local` `dev-up.sh` ile birlikte kullanılır.
- **Mobil taban adresleri düzeltildi:** her iki uygulama da
  `--dart-define=API_BASE_URL` ile yapılandırılabilir; varsayılan Android emülatöründen
  local gateway'e gider. Release manifestlerinde INTERNET izni var (2026-10-03; verify-mobile denetler). **Kalan:** `ios/` klasörü yok (todo FAZ 8).
