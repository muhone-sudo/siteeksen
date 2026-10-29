# CLAUDE.md

SiteEksen — KMK uyumlu site yönetim platformu: Go mikroservis backend (`backend/`), Next.js panel (`admin/`), iki Flutter uygulaması (`mobile/` sakin, `admin_app/` yönetici). Ayrıntılı başvuru dosyaları: `docs/claude/` (en altta).

## Çalışma kuralları
- Ara açıklama yazma (kullanıcı talimatı 2026-10-26); iş bitince kısa rapor ver. Token tasarrufu: kısa ve net.
- Varsayım yapma; doğrulanmış yöntem kullan. Bilmediğini, bulamadığını kullanıcıya sor.
- Birkaç denemede çözülmeyen sorunda dur ve kullanıcıya bildir.
- Alt ajan kullanma (kullanıcı kararı 2026-10-26, Ders 56); yalnız kullanıcı açıkça isterse.
- 3+ adımlı ya da mimari işte: planı `tasks/todo.md`'ye işaretlenebilir maddelerle yaz, uygulamadan önce onay al, ilerledikçe işaretle, sonunda inceleme bölümü ekle. İş ters giderse dur, yeniden planla.
- Kullanıcı bir düzeltme yaptığında dersi `tasks/lessons.md`'ye yaz.
- İşi eksiksiz yap: kök nedeni bul, geçici yama yok, yalnız gerekeni değiştir. Hata raporunda günlüklere/testlere bakıp kendin düzelt.
- Basit işte aşırı mühendislik yok; önemsiz olmayan değişiklikte "daha sade bir yol var mı?" diye sor.
- Ustalık yol haritasını `tasks/roadmap.md`'de güncel tut; tamamlananları işaretle.

## Her görevin başında oku
1. `tasks/dogrulama-politikasi.md` — ÖNCE BUNU. "Tamamlandı" ne zaman yazılır (D0–D4), sessiz başarısızlık yasağı. `✅` kullanılmaz.
2. `tasks/todo.md`, `tasks/roadmap.md` — tamamlanmamış ve yapılacak maddeler (roadmap tek kaynak; kökteki `ROADMAP.md` yalnız işaret eder).
3. `tasks/lessons.md`, `tasks/changelog.md` (tek kaynak), `walkthrough.md` — son tamamlanan madde.
4. Gerektiğinde: `tasks/audit-raporu.md` (2026-09-09 öncesi dokümanlara güvenmeden önce), `tasks/gap-analizi.md` (B01–B97), `tasks/modul-envanteri.md`, `tasks/questions.md` (S-xx kararları).

Bu dosyalar yoksa ya da boşsa oluştur ve doldur.

## Doğrulama — kanıtsız "bitti" yok
| Değişiklik | Komut |
|---|---|
| Backend | `bash backend/scripts/verify-stack.sh` |
| Mobil | `bash backend/scripts/verify-mobile.sh` |
| Panel | `cd admin && npx tsc --noEmit && npm run lint && npm run build` |

Ortam doğrudan Linux (Ubuntu 24.04). Araçlar kurulu, "doğrulanamadı" mazereti yok. PATH ayarları (Go, Flutter, pg-docker, pypdf venv): `docs/claude/ortam-ve-komutlar.md`.

## Hızlı başlangıç
```bash
bash backend/scripts/dev-up.sh     # PostgreSQL + servisler + gateway
cd admin && npm run dev            # http://localhost:3001
```
Demo girişleri ve sorun giderme: `docs/yerel-calistirma.md`. Özellik haritası: `docs/ozellik-haritasi/README.md`.

## Değişmez kurallar
- Servisler veritabanına süper kullanıcıyla bağlanmaz: `siteeksen_app` (RLS'e tabi) ve `siteeksen_identity`. Parolalar depoya yazılmaz.
- Her repository sorgusu `dbscope.For(pool, propertyID)` üzerinden gider. Yeni tabloda: RLS + politika + (alt tabloysa) ebeveyn anahtarına indeks. Doğrulama, RLS dışı tablo listesini birebir denetler.
- Roller site bazlıdır: site rolleri `property_roles`, sakinlik rolleri `resident_units` (OWNER/TENANT/PROXY); `users.roles` yalnız platform rolleri.
- Para `pkg/money` ile tam sayı kuruş; yeni para kodu `float64` kullanmaz.
- Mevzuata bağlı oranlar koda gömülmez: `legal_parameters` / `pkg/legalparams`.
- Migration'lar `cmd/migrate` ile uygulanır; uygulanmış migration düzenlenmez. "Down" betiği yok; geri alma yedekten yapılır (`docs/runbook-veritabani-geri-alma.md`).
- Dağıtım dosyaları (Dockerfile'lar, `docker-compose.yml`, `k8s/`, CI matrisi) `python3 backend/scripts/gen-deploy.py` ile üretilir; elle düzenlenmez.
- Bildirim `pkg/notify` üzerinden gider; alıcı kümeleri yalnız `pkg/notify/audience.go`'da tanımlanır. "Gönderildi" yalnız gerçekten gönderildiyse yazılır.
- Sahte başarı ya da uydurma veri yok. Yazılmamış modül nedenini söyleyerek 501 döner (`banking`, S-07). "Yapay zekâ" iddiası yok.
- Ölü kod, import etme: `pkg/tenant`, `pkg/payment`, `pkg/notification`, `pkg/ai`, `pkg/integrations/*`.
- Gateway (`cmd/gateway`, 8888) tek giriş kapısıdır ve istemci kimlik başlıklarını siler. Kong yalnız önünde durur.

## Başvuru dosyaları
- `docs/claude/mimari-durum.md` — gerçek durum notları ve tarihçe (turlar, migration'lar, düzeltilen hatalar)
- `docs/claude/servisler.md` — servis/port tablosu, ortak paketler, gateway, panel, mobil, altyapı, çok kiracılık
- `docs/claude/guvenlik-durumu.md` — güvenlik beyanı ile gerçek durumun karşılaştırma tablosu
- `docs/claude/ortam-ve-komutlar.md` — araç sürümleri, PATH ayarları, doğrulama betiklerinin kapsamı, Docker/Go/Next/Flutter komutları
