# Güvenlik: beyan ile gerçek durum

> `CLAUDE.md`'den taşındı (2026-10-29). İçerik değiştirilmedi.

### Security — **beyan ile gerçek arasındaki fark**
| Konu | Durum (2026-09-13) |
|---|---|
| JWT 15 dk / 7 gün | **Doğru** |
| `JWT_SECRET` boşsa davranış | **Fail-closed** — istek reddedilir; boş anahtarla doğrulama yapılmaz |
| Gateway / Kong kimlik doğrulama | **Var** — gateway'de `/auth/*` dışı her yol JWT ister (iptal kontrolüyle). Kong yalnızca gateway'in önünde kenar katmanı (IP hız sınırı, gövde sınırı); servislere doğrudan rotası yok (2026-09-27) |
| CORS | **Allowlist** (`CORS_ALLOWED_ORIGINS`); joker `*` kalmadı |
| KVKK denetim izi | **Çalışıyor** — kullanıcı, IP, işlem, kaynak, durum kodu yazılıyor; 403'ler `DENIED` |
| Rol bazlı yetkilendirme | **Site bazlı roller** + gerçek servislerin hepsinde `RequireRole` + panelde `middleware.ts` ve menü süzme. Roller giriş yanıtında da döner (2026-09-13 düzeltmesi; yoksa panel herkesi yetkisiz sayıyordu). |
| Belge erişim kaydı | **Var** — `document_access_logs`, salt-ekleme (tetikleyici korumalı), KVKK m.12 |
| Ticari elektronik ileti | **Onaysız gönderilmez** — 6563 s. Kanun m.6; onay zamanı ve kaynağı saklanır |
| Modül bildirimleri | **Bağlı (2026-09-14)** — duyuru, rezervasyon kararı, kargo, anket, ziyaretçi girişi ve düşük stok uygulama içi bildirim üretir. Alıcı kümesi `pkg/notify/audience.go`'da TEK yerde. Kargo bildirimi takip numarası taşımaz; stok uyarısı sakinlere gitmez; anket bildirimi genel kurul çağrısı olarak işaretlenmez (KMK m.29) |
| Ayarların mevzuatı ezmesi | **Engellendi** — uygulama + veritabanı CHECK kısıtı (migration 017) |
| Aktif site seçimi | **Sahiplik doğrulanıyor** — başkasının sitesine geçiş 403 |
| Giriş şifresi loglanması | **Kaldırıldı** — yalnızca maskelenmiş telefon ve HTTP durumu loglanıyor |
| İstemci kimlik başlıkları | Gateway `X-User-*` / `X-Property-Id` / `X-Tenant-Id` başlıklarını **siler** |
| TCKN/IBAN şifreleme | **VAR** — AES-256-GCM; arama için HMAC blind index (düz SHA-256 değil). Anahtar yoksa personel servisi açılmaz. Anahtar halkası + döndürme (`cmd/rotate-pii`, `docs/runbook-anahtar-dondurme.md`); şifreleme ve arama anahtarı HKDF ile ayrı. Varsayılan MASKELİ; maskesiz erişim ayrı `PII_REVEAL` denetim kaydı üretir |
| Tenant izolasyonu (RLS) | **129 TABLODA AÇIK** (migration 020-026, 029 ve sonraki modül göçleri). 25 servisin tamamı `pkg/dbscope` kullanır. RLS dışında kalan 10 tablo gerekçeli: `audit_logs` (yalnızca ekleme), `revoked_tokens`/`user_token_invalidation` (salt-okur), `tenants`/`invoices`/`usage_metrics`/`schema_migrations`/`user_activation_codes`/`phone_change_requests`/`email_change_requests` (uygulama rolüne kapalı; son üçü yalnızca kimlik servisi) |
| Hesap etkinleştirme / şifre | **VAR (027)** — yönetici sakin ekleyince tek kullanımlık kod bir kez gösterilir (SMS yapılandırılmışsa sakine de gider); kod özeti saklanır, 7 gün, 5 denemede kilit. Şifre değiştirme/sıfırlama bütün oturumları kapatır. Girişte kademeli kilit: 5. hata 30 sn, 6. hata 2 dk, 7.+ 15 dk (B6). Sakin kodu kendisi de isteyebilir (`/auth/password-reset/request`, SMS/e-posta, 15 dk; yanıt numara ifşa etmez — B3). Jeton `iat` milisaniye hassasiyetinde (`pkg/revocation.Precision`) |
| Veritabanı rolleri | **En az yetki** — kimlik servisi ayrı rol (site verisine erişemez); uygulama rolü parola özetini/TCKN'yi göremez, dizin tablolarına yazamaz, denetim izini ve jeton iptalini silemez |
| Dağıtım | compose/k8s/CI tek kaynaktan; kaplar root değil; compose varsayılan parolayla açılmaz; k8s'te tek giriş kapısı gateway |
| Çıkışta jeton iptali | **VAR** — `revoked_tokens` + toplu iptal. Çıkışta erişim VE yenileme jetonu iptal edilir; iptal tüm servislerde geçerlidir. Yenileme jetonu **tek kullanımlık**; tükenmiş jetonun 30 sn sonra yeniden kullanımı bütün oturumları kapatır |

`legal/kvkk-aydinlatma.md` 2026-09-13'te **gerçek duruma göre** düzeltildi: uygulanan ve
uygulanmayan tedbirler ayrı listelenmiştir; karşılığı olmayan taahhüt kalmamıştır.

### Usta & Hizmet pazaryeri — güvenlik gözden geçirmesi (FAZ M12.1, 2026-11-01)

Kanıtlar: `bash backend/scripts/verify-stack.sh` §68–§76 (tedarikçi kimliği, veri modeli, hesap, platform, bakiye, talep, teklif/iş,
vitrin, yönetim alımı) ve tarayıcı D4 (`~/.siteeksen-test/kanit/M*`).

| Konu | Durum |
|---|---|
| Kapsam ve IDOR | **Üç kapsam** (`pkg/dbscope`): site, tedarikçi hesabı, platform; 19 pazaryeri tablosunda RLS + FORCE (077). Başka tedarikçinin hesabı/işletmesi/belgesi/talebi 404; aynı sitedeki komşunun talebi, teklifleri, yazışması ve işi 404; sakin site taleplerini göremez (403). Platform iletişim bilgisini ve yazışmaları **okuyamaz** (politika). §69, §70, §73, §74 |
| İletişim bilgisinin açılması | Alıcının adı/telefonu/adresi ayrı tabloda; yalnız talebi **kabul edip ödemiş** hesaba açılır (RLS). Kabul işlem kaydında adıyla (`market.request.accepted`). Önizleme JSON'unda ad/telefon/adres yok. §73 |
| Maskeleme | Talep açıklaması ve hizmet tanımlarında telefon/e-posta kalıbı gizlenir. Fotoğraflar (hizmet + talep) denetimden geçmeden vitrinde ve tedarikçide görünmez: OCR'da telefon/e-posta/web adresi → ret; açıksa yapay zekâ (sakıncalı/hata → elle onay); platform elle onay/ret/kaldır (082, `services/moderation`). Kabulden sonraki yazışmalar bilerek maskelenmez. §71, §73, §77 |
| Yapay zekâ sağlayıcı kimliği | API anahtarı/parola PII anahtarıyla şifreli; yanıtta ve işlem kaydında görünmez; ayar ve kararlar yalnız PLATFORM_ADMIN. Yurt dışı SaaS'a fotoğraf gönderimi KVKK m.9 aktarımı — karar `questions.md` S-24. §77 |
| Vitrin | Vergi no, belge, bakiye, hesap kimliği dönmez; telefon yalnız paketi izin veriyorsa; gizlenen yorumlar görünmez. §75 |
| Ödeme dönüşü | Dönüş adresi sunucu ayarıdır (panel ya da tedarikçi uygulaması; istemci yalnız hangisini ister, adres veremez — açık yönlendirme yok); tedarikçi uygulamasında ödeme sayfası uygulama içinde açılır. Kimliksiz uç yalnız jetonu alır; sonuç **sağlayıcıdan yeniden sorgulanır**, tutar ve sepet kimliği doğrulanır; aynı dönüş iki kez gelince tek defter satırı (benzersiz indeks); dönüşü gelmeyen ödeme uzlaştırılır. `Idempotency-Key` zorunlu. §72 |
| Bakiye | Hesap satırında CHECK ≥ 0 (borç oluşmaz); defter değiştirilemez/silinemez (süper kullanıcı dahil); kabul ücreti ve iade tek işlemde; her adımda bakiye = defter toplamı. §69, §72–§74 |
| Hız sınırları | Tedarikçi kaydı SMS kodu: 60 sn, numara saatte 3, IP saatte 10; 5 yanlışta kilit. Sakin günlük talep sınırı (ayar). Mesaj: kişi başına dakikada 20 / 24 saatte 300; teklif: hesap başına saatte 20 yeni, teklif başına 5 düzenleme (ayar, 429; eşzamanlı istekler işlem kilidiyle sıraya girer). §74 |
| Belge erişimi | Belgeyi yalnız sahibi ve platform indirir; her indirme erişim kaydına (sahibi/PLATFORM); açılmış belge silinemez; içerik türü dosyanın kendisinden, boyut sınırlı. §70, §71 |
| Çıkar çatışması | Sitede görevli kişinin tedarikçi hesabına o sitenin yönetim talepleri gitmez (078). §73 |
| Saklama | Kapanmış taleplerin iletişim bilgisi ve yazışmaları site saklama süresi sonunda anonimleşir (`MARKET_REQUEST`, 079). §74 |

**Açık bulgular — kapandı (FAZ M13, 2026-11-01, verify-stack 1557/1557):**
1. ~~Kapanış sonrası tamamlanan yükleme kapalı hesaba yazılıyordu~~ → bakiyeye yazılmaz, tamamı karta iade sırasına girer (`LATE_TOPUP`);
   kapanışta kalan bakiye son 365 gündeki yüklemelerden en yeniden eskiye karta iade edilir, kalanı bakiye koşulları m.3 gereği düşülür;
   sonucu bilinmeyen iade çift iade olmasın diye yeniden denenmez, platform kuyruğuna düşer. Koşullar ilk yüklemeden önce ayrıca kabul
   ettirilir (TBK m.21). §72
2. ~~Mesaj/teklif hız sınırı yok~~ → ayarlanabilir sınırlar, 429. §74
3. ~~Uygulamaya ödeme dönüşü yok~~ → Android'de uygulama içi ödeme sayfası, web'de uygulamanın bakiye sayfasına dönüş. §72; D4 (kanıt M13)
4. ~~Fotoğraf içeriği denetlenmiyor~~ → OCR + isteğe bağlı yapay zekâ + platform onayı. §77
