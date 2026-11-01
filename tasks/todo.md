# Todo — Aktif İş Kuyruğu

**Bu dosya 2026-09-09'da sıfırdan yeniden yazıldı.** Önceki sürüm, doğrulanmamış "✅" işaretleri içerdiği
için geçersiz kabul edildi (bkz. `tasks/audit-raporu.md`). Eski sürüm git geçmişinde durmaktadır.

> Önceki sürümdeki **"Oturum Talimatları (Otonom — Kullanıcı Uyuyor)"** bölümü o oturuma özeldi ve
> **artık geçerli değildir.** Commit/push politikası: `tasks/questions.md` S-17 (varsayılan: commit edilmez).

Kanıt seviyeleri: `tasks/dogrulama-politikasi.md` §1. Kanıtsız madde `[D1]`'den yükseğe çıkarılamaz.

---

## Geliştirme ortamını açma (hızlı)

```bash
# Backend (PostgreSQL + gerçek veriye bağlı servisler + gateway)
bash backend/scripts/dev-up.sh

# Panel (ayrı terminal)
cd admin && npm run dev      # http://localhost:3001
```

Demo giriş: `5551234567` / `Demo123!` (yönetici) · `5559876543` / `Demo123!` (kiracı)

---

## Bu oturumun kapsamı

### README özellik envanteri — `[D1]`

- [x] Backend servisleri, API sözleşmesi ve mevcut özellik haritalarını karşılaştırarak kanonik özellik listesini çıkarmak
- [x] Sakin mobil, yönetici mobil ve yönetim web panelini ayrı başlıklarda; platform, modül, temel akış ve bilinen sınırlarıyla README'ye yazmak
- [x] Mimari, kurulum, güvenlik, bildirim, doğrulama durumu ve bilinçli olarak uygulanmayan modülleri README'de doğru statüyle belirtmek
- [x] README bağlantılarını ve Markdown yapısını kontrol etmek; ilgili takip dosyalarına kanıtlı kayıt eklemek

**Kanıt:** `README.md` yeniden yazıldı; kaynaklar `docs/ozellik-haritasi/README.md`, `docs/ozellik-haritasi/01-panel.md`, `02-sakin-mobil.md`, `03-yonetici-mobil.md`, `04-bildirim-zamanlayici-tetikleyici.md`, `05-arayuzsuz-uclar.md`, `docs/claude/servisler.md` ve `docs/claude/mimari-durum.md` olarak karşılaştırıldı (2026-10-31). Otomatik derleme çalıştırılmadı; değişiklik dokümantasyondur.

| Aşama | Durum |
|---|---|
| A. Denetim (iddia vs gerçek) | **Bitti** — `tasks/audit-raporu.md` + `tasks/audit/` (5 kanıt dosyası) |
| B. Olması gereken modüllerin tanımlanması | **Bitti** — `tasks/modul-envanteri.md` (60 modül) |
| C. Gap analizi (eksikler + mantık hataları) | **Bitti** — `tasks/gap-analizi.md` (B01-B97 + özellik bazlı eksikler) |
| D. Doğrulama politikası | **Bitti** — `tasks/dogrulama-politikasi.md` |
| E. Yol haritası + ustalık planı | **Bitti** — `tasks/roadmap.md` |
| F. Kullanıcıya sorular | **Bitti** — `tasks/questions.md` (S-01…S-18) |
| G. Geliştirme: FAZ 0 (dürüstlük onarımı) | **sürüyor** |

## Doğrulama ortamı — ÇÖZÜLDÜ (2026-09-12)

Kullanıcı talimatıyla local iş **WSL (Ubuntu 24.04)** üzerinden yürütülüyor; Windows'taki AppLocker
kısıtı orada yok (`questions.md` S-01).

- **Kurulu:** Go 1.24.7 (WSL'e kuruldu), Docker 27.5.1, psql 16, Node 22
- **Eksik:** Flutter → mobil işler hâlâ `[D1]` kalır (`questions.md` S-01b)

**Kalıcı doğrulama betiği:** `bash backend/scripts/verify-stack.sh`
Sıfırdan PostgreSQL → 11 migration → şema denetimi → idempotency → `pkg/audit` testi →
identity-service'i ayağa kaldırıp gerçek HTTP istekleri. **42 kontrol.**
Backend'e dokunan her değişiklikten sonra çalıştırılır.

---

# FAZ M — Usta & Hizmet (tedarikçi pazaryeri) (2026-10-31) — PLAN `[D0]`

Tasarım ve kararlar (K1–K17): [docs/usta-hizmet/plan.md](../docs/usta-hizmet/plan.md). Kullanıcı onayı 2026-10-31.
Koda başlanmadı. Sıra: M1 → M12; M0 kullanıcıda (kodu bekletmez, yayını bekletir).

**Kapatma kuralı (her madde için):**
- `[ ]` → `[x]` ancak altındaki **Kanıt** satırı gerçek sonuçla doldurulunca yapılır: çalıştırılan komut + sonucu (ör. `verify-stack 1460/1460`),
  istek/yanıt örneği, veritabanı satırı ya da gözlenen ekran metni + tarih. Kanıt seviyesi `tasks/dogrulama-politikasi.md` D0–D4 ile yazılır.
- Arayüz maddeleri D4 olmadan kapanmaz: test ortamında headless tarayıcıyla tıklanır; ekran görüntüleri `~/.siteeksen-test/kanit/<madde>/`
  altına konur (depo dışı, ortam yeniden başlasa da kalır).
- Kısmen çalışan madde kapanmaz, altına "Kalan:" yazılır.
- Bir doğrulama kontrolü eklenince önce kodu **geçici olarak bozup** kontrolün kırmızıya döndüğü gösterilir, bozma geri alınır (commit'e girmez), sonra yeşil.
- Her aşamanın **kapısı** geçmeden sonraki aşamaya başlanmaz. Kapı: verify-stack tamamı yeşil + (değiştiyse) verify-mobile ve panel
  tsc/lint/build temiz + `tasks/changelog.md` kanıtlı satır + `tasks/roadmap.md` FAZ M satırı güncel.
- Para ile ilgili her aşamada tutarlılık sorgusu: her hesap için ekranda/API'de görünen bakiye = `mp_wallet_ledger` toplamı (fark 0).

### M0 — İşletme ve hukuk (kullanıcı; kodu bekletmez, yayını bekletir)
- [ ] M0.1 Şirket/vergi bilgileri ve ETBİS kaydı (6563 aracı hizmet sağlayıcı) — **Kanıt:** ETBİS kayıt no `tasks/questions.md`'de
- [ ] M0.2 E-fatura/e-arşiv entegratörü; bakiye yükleme faturasının yüklemede mi kullanımda mı kesileceği (mali müşavir) — **Kanıt:** karar `questions.md`'de
- [ ] M0.3 iyzico: bakiye yükleme tahsilatının mevcut üye işyeri sözleşmesine uygunluğu — **Kanıt:** iyzico'nun yazılı yanıtı
- [ ] M0.4 Tedarikçi üyelik sözleşmesi, sakin KVKK aydınlatma + açık rıza metni, tedarikçi KVKK metni — **Kanıt:** metinler `docs/hukuk/` altında
- [ ] M0.5 Paket fiyatları, kategori listesi (sakin ve site kategorileri ayrı) ve kategori talep ücretleri — **Kanıt:** tablo `docs/usta-hizmet/fiyatlar.md`
- [ ] M0.6 Yayın için harita karo sağlayıcısı — **Kanıt:** seçilen sağlayıcı ve anahtar ortam değişkeni adı `questions.md`'de
- [ ] M0.7 (İsteğe bağlı) Apple geliştirici hesabı (iOS), Firebase projesi (push, B11) — **Kanıt:** kullanıcıdan hesap/proje bilgisi

### M1 — Kimlik ve roller
- [x] M1.0 `tasks/roadmap.md`'ye FAZ M bölümü — **Kanıt:** dosya farkı
  → **Sonuç:** `[D1]` 2026-10-31: `tasks/roadmap.md` "FAZ M — Usta & Hizmet" bölümü (M0–M12 satırları).
- [x] M1.1 Site rolü olmayan kullanıcı girişi: yalnız platform rolü olan hesap giriş yapar, jetonda site kapsamı yok, `/users/me` çalışır; site gerektiren uçlar
  açık bir hata verir (çökmez). Önce bugünkü davranış ölçülür — **Kanıt:** verify-stack: sitesiz hesapla `/auth/login` 200, `/users/me` 200, `/residents` 403 (500 değil)
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: sitesiz tedarikçi giriş yaptı, `/users/me` 200 (roller [SUPPLIER], aktif site yok); site uçları 403 (500 değil).
- [x] M1.2 `SUPPLIER` ve `PLATFORM_ADMIN` platform rolleri; site rolleriyle birlikte var olabilir
  — **Kanıt:** verify-stack: hem sakin hem tedarikçi olan hesabın jetonunda iki tür rol; bu hesapla sakin uçları eskisi gibi 200
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: kayıtlı sakin hesabına SUPPLIER eklendi; jetonda TENANT, RESIDENT ve SUPPLIER birlikte; yeni kullanıcı satırı yok.
- [x] M1.3 Tedarikçi kaydı 1. adım: telefon → SMS kodu; kayıtlı/kayıtsız her numaraya aynı yanıt; numara + IP başına hız sınırı
  — **Kanıt:** verify-stack: iki yanıt gövdesi birebir aynı; kod sahte Netgsm kutusuna düşer; sınır aşımında 429
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: kayıtlı/kayıtsız numaraya yanıt birebir aynı, ikisine de kod sahte Netgsm'e düştü; 60 sn içinde ikinci istek 429; `go test` sıklık sınırı (60 sn, numara saatte 3, IP saatte 10).
- [x] M1.4 2. adım (kod doğrulandıktan sonra): yeni numara → şifre, hesap + SUPPLIER; kayıtlı etkin hesap → mevcut şifreyle SUPPLIER eklenir (yeni satır yok);
  kayıtlı ama etkinleştirilmemiş hesap → şifre + SUPPLIER; yanlış kod 400, 5 yanlışta kod kilitlenir
  — **Kanıt:** verify-stack: üç durum ayrı ayrı (`users` satır sayısı, `roles`); yanlış mevcut şifrede SUPPLIER eklenmez
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: NEW (ad/sözleşme eksik 422; jeton ikinci kez 400), EXISTING (yanlış şifre 401, rol eklenmedi; doğru şifreyle SUPPLIER, yeni satır yok), INACTIVE (şifre belirlendi, SUPPLIER); yanlış kod 400; 5 yanlışta kilit (doğru kod da 429).
- [x] M1.5 `PLATFORM_ADMIN` yalnız komut aracıyla atanır (`cmd/` altında); istek gövdesindeki `roles` alanı yok sayılır
  — **Kanıt:** verify-stack: `roles:["PLATFORM_ADMIN"]` gönderilen kayıtta rol yok; araç çıktısı ve `users.roles`
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: gövdedeki `roles` yok sayıldı (rol yalnız SUPPLIER); `cmd/platform-admin` PLATFORM_ADMIN verdi, eski oturum 401, yeni jetonda rol; `-revoke` geri aldı.
- [x] M1.6 `pkg/dbscope` tedarikçi kapsamı (`app.supplier_account_id`) ve platform kapsamı; boş kimlikte iş çalışmaz; değişken transaction dışına taşmaz
  — **Kanıt:** verify-stack: boş kimlik hatası; aynı bağlantıda sonraki sorguda değişken boş
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §68: `pkg/dbscope/scope_db_test.go` gerçek veritabanında: boş kimlikte iş çalışmıyor, değişken transaction dışına sızmıyor.
- [x] M1.7 Panel: `rbac.ts` + `middleware.ts`: `/tedarikci/*` SUPPLIER, `/platform/*` PLATFORM_ADMIN; `/tedarikci/giris` ve `/tedarikci/kayit` açık
  — **Kanıt:** panel tsc/lint/build; tarayıcı D4: KİRACI `/tedarikci` → yönlendirme, SUPPLIER `/platform` → yönlendirme, YÖNETİCİ `/dashboard` eskisi gibi
  → **Sonuç:** `[D4]` panel tsc/lint/build temiz (ayrı kopya, Ders 63/64); tarayıcı 6/6 — `~/.siteeksen-test/kanit/M1.7/`: KİRACI `/tedarikci` → yasak sayfası, SUPPLIER `/platform` → yönlendirme, SUPPLIER `/tedarikci` açılır, YÖNETİCİ `/dashboard` eskisi gibi.
- [ ] M1.8 Test ortamı: `test-hesaplari.sh`'a gerçek kayıt akışıyla bir PLATFORM_ADMIN ve iki tedarikçi hesabı — **Kanıt:** betik çıktısı; üç hesapla giriş 200
  → **Sonuç:** `[D3]` 2026-10-31: `test-araclari/hesaplar.py` tedarikçileri gerçek kayıt akışıyla açar, `test-ortami.sh` platform yöneticisini `cmd/platform-admin -create` + `/auth/activate` ile kurar; geliştirme yığınında (55450/19888) aynı akış çalıştı, üç hesapla giriş 200. **Kalan:** çalışan test ortamı yeniden başlatılmadığı için betiğin test ortamındaki çıktısı bir sonraki açılışta.
- [ ] **M1 kapısı**
  → **Kapı (2026-10-31):** verify-stack 1495/1495 (son çalıştırma, CORS düzeltmesi dahil), panel tsc/lint/build temiz, changelog + roadmap güncel. **Kalan:** M1.8 test ortamı açılış çıktısı.

### M2 — Veri modeli ve servis iskeleti
- [x] M2.1 `services/marketplace` (8111): sağlık ucu, `AuthMiddleware`, yapılandırma, `siteeksen_app` rolüyle bağlantı
  — **Kanıt:** gateway üzerinden sağlık 200; kimliksiz uç 401; servis bağlantısında `current_user` = siteeksen_app
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §69: gateway → pazaryeri kimliksiz `/market/meta` 401, oturumla 200 (6 ayar, varsayılan ücretsiz paket); `/market/supplier/me` uygulama rolüyle RLS altında; yönetici 403.
- [ ] M2.2 Gateway yönlendirmesi + `gen-deploy.py` ile üretilen dosyalar + `dev-up.sh` + `test-ortami.sh` port listesi
  — **Kanıt:** verify-stack'in üretilen dosyalar kontrolü yeşil; `dev-up.sh --stop` 8111'i de kapatır
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §0: `gen-deploy --check` tutarlı, gateway yönlendirmesi tutarlı (460 rota, 79 ön ek); `dev-up.sh` 8111'i başlatır ve durdurma listesinde. **Kalan:** `dev-up.sh --stop` canlı denenmedi (test ortamını durdururdu).
- [x] M2.3 Migration `076_marketplace.sql` (bütün tablolar, görünüm, kuruş tam sayı tutarlar, indeksler, bilinçli `ON DELETE`)
  — **Kanıt:** verify-stack adım 4: çalıştırıcı ikinci çağrıda bir şey uygulamaz ve 076 ham olarak tekrar uygulanır; temiz veritabanında açılış
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §4: `cmd/migrate` ikinci çağrıda bir şey uygulamıyor; `076_supplier_signup.sql` ve `077_marketplace.sql` ham olarak tekrar uygulandı; temiz PostgreSQL 16'da açıldı. Not: kimlik tablosu ayrı migration (076), pazaryeri 077.
- [x] M2.4 `properties.latitude/longitude` (boş kabul eder) + panel site ayarlarında harita ile giriş
  — **Kanıt:** mevcut verify-stack kontrolleri değişmeden yeşil; tarayıcı D4: koordinat kaydedilir, geçersiz değer 422
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §69: yönetici konumu kaydetti (GET /property'de), aralık dışı 422, tek alan 400, sakin 403; tarayıcı `~/.siteeksen-test/kanit/M2.4/`: 40.991075 / 29.0309 haritadan kaydedildi.
- [x] M2.5 RLS: her yeni tabloda RLS + FORCE + politika (hesap kendi satırları; dispatch + görünürlük zamanı; iletişim yalnız kabulde; vitrin yalnız onaylı/yayında)
  — **Kanıt:** verify-stack: RLS sayımı ve RLS dışı liste birebir güncel; doğrudan SQL'de kapsam = A iken B'nin satırları 0
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31): RLS toplam 148 tablo (077: 19 tablo), RLS dışı 11 tablo birebir (`phone_verifications` eklendi); §69: kapsam A iken B'nin satırları 0, platform hepsini görür, iletişim yalnız kabul edende (platform bile göremez), öncelik penceresinde talep görünmez.
- [x] M2.6 `mp_wallet_ledger` ve `mp_reviews` değiştirilemezlik tetikleyicileri — **Kanıt:** verify-stack: UPDATE ve DELETE hata verir
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §69: defterde UPDATE ve (süper kullanıcıyla bile) DELETE reddedildi; yorum puanı değiştirilemiyor, silinemiyor; yanıt bir kez.
- [x] M2.7 Sitesiz bildirim: tedarikçi alıcılı sitesiz kayıt + RLS + sitesiz tekilleştirme indeksi; `pkg/notify` sitesiz gönderim; site tetikleyicisi yalnız site kayıtlarında
  — **Kanıt:** verify-stack: sitesiz kayıt yazılır, yalnız alıcısı okur; aynı dedupe anahtarıyla ikinci kayıt atlanır; pasif site koruması (mevcut kontrol) yeşil; `go test ./pkg/notify/...`
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §69: sitesiz bildirim tedarikçi kapsamında yazıldı, aynı dedupe anahtarı reddedildi, sahipsiz/başkası adına kayıt reddedildi, B ve site göremiyor; `go test ./pkg/notify/...` (iki kapsam birden reddedilir); pasif site korumaları yeşil.
- [x] M2.8 `api/openapi.yaml`'a marketplace uçları + verify-stack'e kontrol: gateway'de kayıtlı her marketplace yolu belgede var
  — **Kanıt:** kontrol önce eksik bir yolla kırmızı, sonra yeşil
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §69: `check-market-contract.py` → "pazaryeri sözleşmesi tam: 50 uç". **Değişiklik:** `api/openapi.yaml` bayat (roadmap 8.5) olduğundan belge `tasks/api-sozlesmesi.md`; denetim önce eksik/kısa yollarla kırmızıydı (2026-10-31 ara çalıştırma), sonra yeşil.
- [ ] **M2 kapısı**
  → **Kapı (2026-10-31):** verify-stack 1495/1495 (son çalıştırma, CORS düzeltmesi dahil), panel tsc/lint/build temiz, changelog + roadmap güncel. **Kalan:** M2.2 `dev-up.sh --stop` canlı denemesi.

### M3 — Tedarikçi hesabı, belgeler, işletmeler (API + `/tedarikci` web)
- [x] M3.1 Kayıt ve giriş sayfaları (M1.3–M1.4 akışı arayüzde); yükleniyor/boş/hata durumları — **Kanıt:** tarayıcı D4: yeni, kayıtlı ve etkinleştirilmemiş numara akışları
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M3.1/`: yeni numara (D1–D3), kayıtlı etkin hesap (EXISTING: yanlış şifre "Mevcut şifre hatalı", doğru şifreyle panel), etkinleştirilmemiş hesap (INACTIVE: şifre belirleyip panel); veritabanında aynı telefonla tek satır, roller `{PLATFORM_ADMIN,SUPPLIER}`. Bulunan hata: jetonsuz istekteki 401 panelin oturum yakalayıcısıyla /login'e atıyordu → `admin/src/lib/api-client.ts` düzeltildi.
- [x] M3.2 Hesap bilgileri (unvan, vergi no) ve belge yükleme (`pkg/storage`); "incelemeye gönder" (TASLAK → İNCELEMEDE); eksik bilgi/belgede gönderilemez;
  belgeleri yalnız sahibi ve platform indirir, indirme erişim kaydına yazılır
  — **Kanıt:** verify-stack: SHA-256 kayıtlı; eksikte 422 ve eksik alan adı; başka tedarikçi indirme 403; erişim kaydı satırı; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §70: eksikte 422 ve eksikler tek tek; metin 415, bilinmeyen tür 422; SHA-256 dosyayla birebir; sahibi indirdi + erişim kaydı; başka tedarikçi 404, yönetici 403; açılmış belge silinemiyor 409; REVIEW'da bilgi değiştirilemez 409. Tarayıcı `~/.siteeksen-test/kanit/M3/` 1–2.
- [x] M3.3 İşletmelerim: birden çok işletme ekle/düzenle/kapat; her birinde ad, telefon, adres, harita iğnesi, hizmet alanı (km / il / Türkiye geneli), kategoriler
  — **Kanıt:** verify-stack: iki işletmeli hesap; geçersiz koordinat/yarıçap 422; başka hesabın işletmesini değiştirme 403/404; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §70: iki şube (yarıçap + tüm il); adsız/konum/yarıçap 0/kategorisiz/kapalı kategori 422; başka tedarikçi 404; kapatılan işletme değiştirilemez 409. Tarayıcı `~/.siteeksen-test/kanit/M3/` 3–4 (harita iğnesi, kategoriler).
- [x] M3.4 Hizmet/ürün kalemleri (ad, açıklama, fiyat aralığı ya da "teklifle", birim, fotoğraf); açıklamada telefon/e-posta kalıbı gizlenir
  — **Kanıt:** verify-stack: alt fiyat > üst fiyat 422; "0532 ..." içeren açıklama maskeli kaydolur; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §70: alt>üst 422, tek uçlu fiyat 422, 'teklifle' kalem; e-posta ve telefon gizlendi; fotoğraf yüklendi, yayında olmayan işletmenin fotoğrafı başkasına 404. Tarayıcı `~/.siteeksen-test/kanit/M3/5-hizmet-fotografi.png`.
- [ ] M3.5 Test ortamı: iki test tedarikçisi (biri iki şubeli) hesap, belge, işletme ve hizmet kalemleriyle betikle doldurulur — **Kanıt:** betik çıktısı; hesaplar İNCELEMEDE
  → **Sonuç:** `[D3]` 2026-10-31: `test-araclari/pazaryeri.py` (test-ortami.sh platform yöneticisinden sonra çağırır) iki tedarikçiyi hesap, iki belge, 3 işletme (biri iki şubeli), 6 hizmet kalemiyle doldurup incelemeye gönderir; geliştirme yığınında çalıştı. **Kalan:** test ortamının bir sonraki açılışındaki çıktı. Not: M4.6 aynı betikte onayladığı için hesaplar son durumda ONAYLI.
- [ ] **M3 kapısı**
  → **Kapı (2026-10-31):** verify-stack 1495/1495 (son çalıştırma, CORS düzeltmesi dahil), panel tsc/lint/build temiz, changelog + roadmap güncel. **Kalan:** M3.5 test ortamı açılış çıktısı.

### M4 — Platform paneli (`/platform`)
- [x] M4.1 Hesap belge onay/ret kuyruğu (ret gerekçesi zorunlu), askıya alma; `market.supplier.approved/rejected` (sitesiz bildirim)
  — **Kanıt:** verify-stack: ret → TASLAK + bildirim; onay → ONAYLI + bildirim; askıya alınan hesabın işletmeleri vitrinden düşer; PLATFORM_ADMIN dışı 403; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §71: tedarikçi/yönetici 403; ret gerekçesiz 422, taslağa döndü, seçilen belge reddedildi, sitesiz bildirim; onay, ikinci onay 409; askıya alınanın işletmesi vitrinden düştü, geri dönünce geldi. Tarayıcı `~/.siteeksen-test/kanit/M4/` 1–2, 7.
- [x] M4.2 İşletme yayın onayı: onaylı hesabın yeni işletmesi platform kontrolünden sonra YAYINDA; `market.business.approved/rejected`
  — **Kanıt:** verify-stack: onaysız işletme vitrinde ve eşleşmede yok, onay sonrası var; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §71: yayına alınan işletme vitrinde (site kapsamında 2 hizmet), ücretsizde telefon gizli; ret gerekçesiz 422, gerekçe tedarikçi sayfasında; onaysız hesabın işletmesi yayına alınamıyor 409. Tarayıcı `~/.siteeksen-test/kanit/M4/3-isletme-yayinda.png`.
- [x] M4.3 Kategori yönetimi: ekle/düzenle/pasifleştir; talep ücreti; kim açabilir (sakin/yönetim/ikisi); ücret değişikliği işlem kaydına
  — **Kanıt:** verify-stack: `audit_logs` satırı; pasif kategoride talep açılamaz; sakin "yalnız yönetim" kategorisinde talep açamaz; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §71: geçersiz alıcı türü 422; ücret değişikliği işlem kaydında; tedarikçi 403; pasif kategori meta'da yok. Tarayıcı `~/.siteeksen-test/kanit/M4/4-kategori.png`. Pasif/kapalı kategoride talep açılamaması M6.1'de.
- [x] M4.4 Paket yönetimi (aylık ücret, indirim %, dahil talep, aylık SMS hakkı, öncelik penceresi, vitrinde telefon, sıralama ağırlığı)
  — **Kanıt:** verify-stack: kayıt/değişiklik ve işlem kaydı; tarayıcı D4 (mevcut abonelere uygulanması M5.4'te doğrulanır)
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §71: 'Usta Pro' eklendi; varsayılan pakete aidat konamıyor (422); indirim %150 → 422; mevcut aboneye yeni fiyat §72'de yenilemede uygulandı. Tarayıcı `~/.siteeksen-test/kanit/M4/5-paketler.png`.
- [x] M4.5 `mp_settings` ekranı (öncelik penceresi, talep süresi, otomatik tamamlama, günlük sınır); serviste bu değerler sabit yazılmaz
  — **Kanıt:** kaynakta sabit değer araması boş; ayar değişince davranışın değiştiği kontrol M6.4'te
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §71: öncelik penceresi 45 dk yapıldı, meta'da görünüyor; bilinmeyen anahtar 404, eksi 422. Kaynakta sabit değer yok: `grep` → ayarlar yalnız `store.SettingValue` ile okunuyor (`low_balance_threshold_kurus`); diğerleri M6/M7'de okunacak. Tarayıcı `~/.siteeksen-test/kanit/M4/6-ayarlar.png`.
- [ ] M4.6 Test ortamı: test tedarikçileri ve işletmeleri betikle onaylanır; test kategorileri (sakin + site) ve paketleri (ücretsiz + ücretli) yüklenir
  — **Kanıt:** betik çıktısı; vitrin görünümünde yayındaki işletmeler
  → **Sonuç:** `[D3]` 2026-10-31: `pazaryeri.py` kategorileri (sakin, yönetim, ikisi), Usta Pro paketini açar, hesapları ve işletmeleri onaylar; geliştirme yığınında 3 işletme PUBLISHED. **Kalan:** test ortamı açılışındaki çıktı.
- [ ] **M4 kapısı**
  → **Kapı (2026-10-31):** verify-stack 1495/1495 (son çalıştırma, CORS düzeltmesi dahil), panel tsc/lint/build temiz, changelog + roadmap güncel. **Kalan:** M4.6 test ortamı açılış çıktısı.

### M5 — Bakiye ve paket
- [x] M5.1 Bakiye yükleme: `pkg/iyzico` Initialize → ödeme sayfası → kimliksiz dönüş ucu → `Retrieve` ile sunucuda doğrulama → ledger; `Idempotency-Key`
  — **Kanıt:** sahte iyzico ile başarılı, başarısız ve yarıda kalan ödeme; aynı dönüş iki kez gelince tek ledger satırı; tutar istemciden değiştirilemez
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: Idempotency-Key yoksa 400, aynı anahtar aynı yükleme, farklı tutar 409; dönüşte sonuç sağlayıcıdan imzalı sorgulandı; aynı dönüş iki kez → tek defter satırı; başarısız ve tutarı uyuşmayan ödeme işlenmedi. Tarayıcı `~/.siteeksen-test/kanit/M5/` 3–5, 10: başarılı (500 TL), reddedildi (bakiye değişmedi), yarıda bırakıldı ("3D Secure doğrulaması bekleniyor", bakiye değişmedi). Bulunan hatalar: gateway CORS `Idempotency-Key`'e izin vermiyordu (düzeltildi + `go test` önce kırmızı); sahte iyzico isteğin `callbackUrl`'ini yok sayıyordu (düzeltildi).
- [x] M5.2 Uzlaştırma: yarıda kalan yüklemeler zamanlayıcıyla sorgulanır (kart ödemesi bekçisi kalıbı)
  — **Kanıt:** verify-stack: dönüşü hiç gelmeyen başarılı ödeme sonradan bakiyeye yansır, tek kez
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: dönüşü gelmeyen başarılı ödeme uzlaştırmayla bakiyeye yansıdı, tek kez. Not: iş `cmd/scheduler` yerine servis içinde zamanlayıcıyla, `pg_try_advisory_lock` ile tek kopyada çalışır. Geliştirme yığınında yarıda bırakılan (INIT) yükleme 20 dk sonra FAILED ("3D Secure doğrulaması süresinde tamamlanmadı; tutar kartınızdan çekilmedi."), bakiye değişmedi.
- [x] M5.3 Bakiye ve hareketler ekranı (sayfalı ledger) — **Kanıt:** tarayıcı D4; ekrandaki bakiye = ledger toplamı (SQL)
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: ekrandaki bakiye = defter toplamı; tarayıcı `~/.siteeksen-test/kanit/M5/` 1, 4, 9 (hareketler, sayfalı). Bulunan hata: hareketi olmayan hesapta sayfa "Kayıt yok" gösterip yükleme formunu gizliyordu → düzeltildi.
- [x] M5.4 Paket seçimi: yükseltme hemen (aidat bakiyeden, haklar yenilenir), düşürme dönem sonunda; bakiye yetmezse 409 ve açık mesaj;
  paket fiyatı değişirse mevcut aboneye bir sonraki yenilemede uygulanır — **Kanıt:** verify-stack: üç durum + fiyat değişikliği (tarih ileri alınarak)
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: yükseltme hemen (aidat düştü, 5 talep + 50 SMS, yenileme ~1 ay), yetmezse 409; düşürme dönem sonuna; mevcut paketi seçmek bekleyeni iptal etti; yeni fiyat bir sonraki yenilemede. Tarayıcı `~/.siteeksen-test/kanit/M5/` 2, 6.
- [x] M5.5 Aidat zamanlayıcısı: yenileme günü bakiyeden düşer, haklar yenilenir; yetmezse ücretsize iner + `market.package.downgraded`; eşik altında `market.wallet.low`
  — **Kanıt:** verify-stack: iki yol, ledger ve bildirim satırları; aynı gün ikinci çalıştırmada çift aidat yok
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: aidat yenilendi, haklar yenilendi, tekrar turunda ikinci aidat yok; bakiye yetmeyince ücretsize inildi + bildirim; eşik altında uyarı (borç yok).
- [x] M5.6 Üyelik kapanışı: platform kalan bakiyeyi elle (havale) iade eder ve kaydeder (tarih, dekont no, gerekçe); kapanış kaydı bakiyeyi sıfırlar
  — **Kanıt:** verify-stack: dekont bilgisi olmadan 422; kayıttan sonra bakiye 0, hesap KAPALI; işlem kaydı
  → **Sonuç:** `[D4]` verify-stack 1495/1495 (2026-10-31) §72: dekontsuz 422; dekontla kapandı, kapanış satırıyla bakiye 0, işletmeler kapandı; kapalı hesaba yükleme 409. Tarayıcı `~/.siteeksen-test/kanit/M5/` 7–9: dekontsuz kapanış reddedildi, kapanış tamam, tedarikçi kapanış iadesini görüyor; kapalı hesapta yükleme/paket düğmeleri gizlendi.
- [ ] M5.7 Test ortamı: test hesaplarına sahte iyzico ile bakiye; biri ücretli pakete geçer — **Kanıt:** betik çıktısı; para tutarlılık sorgusu fark 0
  → **Sonuç:** `[D3]` 2026-10-31: `pazaryeri.py` sahte iyzico ile Kemal'e 1000 TL, Selin'e 200 TL yükler, Kemal Usta Pro'ya geçer (bakiye 650 TL); betik sonunda bakiye = defter toplamı denetlenir (geliştirme yığınında fark 0). **Kalan:** test ortamı açılışındaki çıktı.
- [ ] **M5 kapısı** (+ para tutarlılık sorgusu)
  → **Kapı (2026-10-31):** verify-stack 1495/1495 (son çalıştırma, CORS düzeltmesi dahil), panel tsc/lint/build temiz, changelog + roadmap güncel. **Kalan:** M5.7 test ortamı açılış çıktısı.

### M6 — Talep, eşleşme, kabul (çekirdek)
- [x] M6.1 Talep açma (sakin ve yönetim): sakin için KVKK açık rıza; günlük sınır; metindeki telefon/e-posta maskelenir; fotoğraf `pkg/storage`;
  pasif kategoride, alıcı tipine kapalı kategoride ve pasif sitede açılamaz
  — **Kanıt:** verify-stack: rızasız 422; sınır aşımı 429; maskeli kayıt; pasif site 409
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: rızasız 422 `CONSENT`, yönetim kategorisinde sakin 422, sakin site adına 403, kapalı kategori 422; açıklamadaki telefon kayıtta gizli; günlük sınırda dördüncü 429; pasif site 409 `PROPERTY_INACTIVE`; fotoğraf `pkg/storage` (sahibi ekler, en çok 3). Not: yönetim talebinde rıza alanı istenmez (plan: rıza sakin için).
- [x] M6.2 Sakin yalnız kendi taleplerini görür; yönetim talepleri yalnız yönetim rollerine — **Kanıt:** verify-stack: aynı sitedeki başka sakin talebi kimlikle istese 404
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: aynı sitedeki komşu talebi kimlikle isteyince 404, listesinde yok; site talepleri (`scope=management`) yönetici/kurul/denetçide, sakine 403.
- [x] M6.3 "Yakındaki uygun işletme sayısı" ucu; 0 ise talep açılmaz — **Kanıt:** verify-stack: alan dışı işletmeyle 0 ve talep 422; "Türkiye geneli" işletmeyle 1
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: `GET /market/requests/match-count` — 8 uygun hesap (alan dışı hariç); yalnız alan dışı işletmeyle 0 ve talep 422 `NO_SUPPLIER` (kayıt yok); Türkiye geneli işletme eklenince 1.
- [x] M6.4 Eşleşme ve dispatch: hesap başına en yakın uygun işletme; kategori + hesap ONAYLI + işletme YAYINDA + hizmet alanı (km/il/Türkiye; site koordinatı yoksa ilçe)
  + çıkar çatışması yok; ücretli paket hemen, ücretsiz pencere sonunda görünür
  — **Kanıt:** `go test` eşleşme birim testleri (yarıçap sınırı, il, Türkiye geneli, ilçe yedeği, iki şubeden en yakını); verify-stack: ücretsiz tedarikçi pencerede
  listede yok ve doğrudan kimlikle 404, pencere sonrası görür; ayarda pencere değişince görünürlük zamanı değişir; yönetici-tedarikçi kendi sitesinin yönetim talebini görmez
  → **Sonuç:** `[D4]` `go test ./services/marketplace/...` (rules.Match: yarıçap sınırı, il, Türkiye geneli, ilçe yedeği, iki şubeden en yakını, koordinatsız sitede aynı ilçedeki şube, çatışma, doğrudan talep) — verify §73'te çalışır (önceden pazaryeri birim testleri verify'da hiç çalışmıyordu); verify-stack 1517/1517 (2026-10-31) §73: iki şubeli hesaba tek gönderim en yakın şubeyle; ücretsiz hesap pencerede listede yok/kimlikle 404/kabul 404, ücretli hemen görür; pencere 30→45 dk yapılınca görünürlük +45 dk; yönetim talebi sitede görevli kişinin hesabına gitmedi (078 `mp_conflicted_accounts`), sakin talebine gitti.
- [x] M6.5 Maskeli önizleme: kategori, ilçe, mesafe, açıklama, fotoğraf, telefon gizli mi, kabul ücreti (paket indirimi uygulanmış); bakiyesi yetmeyen de görür
  — **Kanıt:** verify-stack: önizleme JSON'unda ad/telefon/adres anahtarı yok; bakiyesi 0 olan hesap talebi listede görür
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: önizlemede `contact`/ad/telefon/adres yok; ilçe ve paket indirimli ücret (100→50 TL), dahil hak kullanılacağı belli; bakiyesi 0 hesap talebi görüyor (`can_afford:false`). Tarayıcı `~/.siteeksen-test/kanit/M6/` 1, 4: Kemal önizlemede ad/telefon görmüyor; Selin "Bakiye yetersiz — bakiye yükle".
- [x] M6.6 Kabul: tek transaction'da dahil talep hakkı ya da bakiye düşer + kabul sayısı artar + iletişim açılır + işlem kaydı (iletişim görüntüleme);
  4 sınırı satır kilidiyle; hesap başına bir kabul
  — **Kanıt:** verify-stack: 5 hesap paralel kabul → tam 4 başarı, 1 red (409); ledger'da tam 4 kayıt; aynı hesap ikinci kez 409; bakiyesi yetmeyen 409 ve bakiye değişmez;
  dahil talep hakkı olan hesapta bakiye değişmez, hak 1 azalır; para tutarlılık sorgusu fark 0
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: 5 hesap eşzamanlı kabul → tam 4 × 200, 1 × 409; defterde tam 4 ücret satırı; talep DOLU, sonra gelen 409 `FULL`; aynı hesap ikinci kez 409 `ALREADY_ACCEPTED`; bakiyesiz 409 ve bakiye/defter değişmedi; dahil hakla kabulde bakiye değişmedi, hak 1→0, 0 TL defter satırı; kabul işlem kaydında `market.request.accepted`; para tutarlılığı fark 0. Tarayıcı `~/.siteeksen-test/kanit/M6/` 2–3: kabul onayı → ayrıntıda alıcının adı, telefonu, site adresi.
- [x] M6.7 Doğrudan talep ("bu işletmeye gönder"): yalnız o işletmeye gider, öncelik penceresi ve 4 kotası yok, kabul ücreti aynı
  — **Kanıt:** verify-stack: başka hesaplara dispatch yok; hedef işletme kabul eder, ücret düşer
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: doğrudan talep yalnız hedef hesaba (1 gönderim), ücretsiz pakette de hemen görünür ve bildirildi, `max_accepts` 1; kabulde 100 TL düştü, talep DOLU.
- [x] M6.8 Bildirim: `market.request.new` — ücretliye anında (uygulama içi + e-posta + SMS hakkı varsa), ücretsize pencere bitince zamanlayıcıyla (uygulama içi + e-posta); alıcı kümeleri `audience.go`'da
  — **Kanıt:** verify-stack: ücretsiz hesaba pencere içinde kayıt yok, sonra var ve SMS yok; SMS hakkı biten ücretliye SMS yok; uygun olmayan hesaba kayıt yok
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: ücretli hesaba hemen uygulama içi + SMS (sahte Netgsm, hak 1→0); ücretsize pencere içinde kayıt yok, pencere bitince zamanlayıcı uygulama içi (SMS yok); SMS hakkı biten ücretliye ikinci SMS yok; gönderilmeyen (alan dışı) hesaba gönderim ve bildirim yok. E-posta, hesabın e-postası varsa aynı yoldan (`notifySupplier`). **Not:** alıcı kümesi eşleşmenin (gönderim tablosunun) sonucudur, `audience.go`'da tanımlı bir küme değildir; tedarikçi alıcısı M4'ten beri `store.AccountContact`.
- [x] M6.9 Talep süresi dolumu → KAPANDI + `market.request.expired` — **Kanıt:** verify-stack: süre ileri alınınca durum ve bildirim; kapanan talep kabul edilemez (409)
  → **Sonuç:** `[D4]` verify-stack 1517/1517 (2026-10-31) §73: süresi geçen açık talep zamanlayıcıyla EXPIRED, sahibine `market.request.expired`; kapanan talebe kabul 409 `CLOSED`. Not: plandaki "KAPANDI" durum adı şemada `EXPIRED`.
- [x] **M6 kapısı** (+ para tutarlılık sorgusu)
  → **Kapı (2026-10-31):** verify-stack 1517/1517 (2026-10-31); panel tsc/lint/build temiz; tarayıcı `~/.siteeksen-test/kanit/M6/` 4/4; changelog + roadmap güncel; para tutarlılığı fark 0. Yeni kontroller önce bozuk kodla kırmızı gösterildi (iki çalıştırma). Ek: tedarikçi web "Talepler" ekranı (liste, kabul, ayrıntı/iletişim); verify adım 1'deki pg_isready yarışı düzeltildi.

### M7 — Teklif, mesaj, iş, puan, iade, denetim
- [x] M7.1 Teklif ver/düzenle/geri çek (kuruş, geçerlilik); yalnız kabul etmiş hesap — **Kanıt:** verify-stack: kabul etmemiş hesap 403
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: kabul etmemiş hesap teklif 403 `NOT_ACCEPTED`; tutarsız 422; etkin teklif güncellenir (aynı kayıt); geri çekilen alıcıya görünmez; alıcıya `market.offer.new`. Tarayıcı `~/.siteeksen-test/kanit/M7/` 1.
- [x] M7.2 Alıcı teklif seçer → iş oluşur, diğerlerine `market.offer.declined`; ya da talebi teklif seçmeden kapatır (ücret iadesi yok)
  — **Kanıt:** verify-stack: tek iş satırı; diğer hesaplara bildirim; kapatmada ledger değişmez
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: seçimde tek iş satırı, talep CLOSED, diğer teklif DECLINED + `market.offer.declined`, sonra teklif 409; komşu seçemez 404; teklif seçmeden kapatmada (CANCELLED) etkin teklif reddedildi, defter değişmedi. Alıcı teklifleri işletme telefonu ve puanıyla yan yana görür (`GET /market/requests/:id/offers`). Tarayıcı `~/.siteeksen-test/kanit/M7/` 2 (seçim API'den; alıcı arayüzü M8/M10).
- [x] M7.3 Mesajlaşma yalnız taraflar arasında; sayfalı; `market.message` — **Kanıt:** verify-stack: üçüncü kişi okuyamaz/yazamaz (403/404)
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: alıcı ile kabul eden tedarikçi yazışır (sayfalı, iki yöne `market.message`); komşu 404, kabul etmemiş tedarikçi okuyamaz/yazamaz 403, gönderilmemiş 404. Tarayıcı `~/.siteeksen-test/kanit/M7/` 1–2.
- [x] M7.4 Tamamlama: tedarikçi bildirir → alıcı onaylar ya da itiraz eder; yanıtsızsa 7 gün sonra otomatik; itirazdaki iş otomatik tamamlanmaz
  — **Kanıt:** verify-stack: onay, itiraz ve otomatik yollar (tarih ileri alınarak)
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: bildirim öncesi onay 409, başkasının işi 404; tedarikçi "tamamlandı" (alıcıya bildirim); gerekçesiz itiraz 422; itirazdaki iş süresi geçse de kendiliğinden tamamlanmadı; alıcı onayıyla COMPLETED (BUYER); yanıtsız iş ayardaki gün sonunda COMPLETED (AUTO), iki tarafa bildirildi. Tarayıcı `~/.siteeksen-test/kanit/M7/` 3.
- [x] M7.5 Puan/yorum işletmeye, yalnız tamamlanan işe, işe bir kez; tedarikçi yanıtı; işletme puan özeti güncellenir
  — **Kanıt:** verify-stack: tamamlanmamışa 409, ikinciye 409, özet doğru
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: tamamlanmamışa 409, ikinciye 409, komşu 404; işletme özeti 4/1 ve 1 tamamlanan iş; tedarikçi bir kez yanıtlar (ikinci 409, başkası 404). Tarayıcı `~/.siteeksen-test/kanit/M7/` 4 (Puanlar ekranından yanıt).
- [x] M7.6 Geçersiz talep / şikâyet bildirimi → platform kuyruğu (`/platform`) → onayda bakiyeye iade (dahil talepse hak geri), retde gerekçe; `market.dispute.resolved`
  — **Kanıt:** verify-stack: onay/ret yolları, ledger tutarlı, aynı kabul için ikinci iade yok; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: kabul etmeyen bildiremez 403, ikinci bildirim 409, kuyruk yalnız platformda; gerekçesiz karar 422; onayda 100 TL tek REFUND, ikinci onay 409; dahil hakla kabulde hak geri (defter satırı yok); ret iade etmez; `market.dispute.resolved`; para tutarlılığı fark 0. Tarayıcı `~/.siteeksen-test/kanit/M7/` 5–8: tedarikçi bildirir, platform onaylar, tedarikçi kararı görür.
- [x] M7.7 Yorum denetimi: platform gerekçeyle gizler (silinmez) — **Kanıt:** gizlenen yorum vitrinde yok, veritabanında var; işlem kaydı
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: gerekçesiz 422, tedarikçi 403; gizlenen yorum vitrin görünümünde yok, veritabanında gerekçesiyle var, puan özetinden çıktı; işlem kaydı `market.review.hidden`. Tarayıcı `~/.siteeksen-test/kanit/M7/` 9.
- [x] M7.8 Gelir raporu (dönem: aidat, talep ücreti, iade, net) ledger'dan — **Kanıt:** verify-stack: bilinen işlemlerden sonra rapor toplamı = ledger toplamı
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: rapor (aidat + talep ücreti − iade) ve dönem defter toplamı doğrudan SQL ile birebir; ters dönem 422; tedarikçi 403. Tarayıcı `~/.siteeksen-test/kanit/M7/` 10. Yüklemeler gelir değil, ayrı gösterilir.
- [x] M7.9 Saklama: kapanan taleplerin iletişim satırları ve mesajları saklama süresi sonunda anonimleştirilir (mevcut `kvkk.destruction` işine eklenir)
  — **Kanıt:** verify-stack: süre ileri alınınca telefon/ad boş, talep ve ledger kayıtları duruyor
  → **Sonuç:** `[D4]` verify-stack 1530/1530 (2026-10-31) §74: site `MARKET_REQUEST` saklama süresi tanımladı (079 kategori); süresi dolan kapanmış (seçilmiş/iptal) taleplerin ad/telefonu ve mesajları anonimleşti, yeni talep korundu, talep ve defter kayıtları duruyor, imha kaydı yazıldı (pkg/retention). Not: plandaki "saklama süresi" sitenin KVKK saklama kuralıdır (koda gömülü süre yok); site adresi kişisel veri olmadığından korunur.
- [x] **M7 kapısı** (+ para tutarlılık sorgusu)
  → **Kapı (2026-10-31):** verify-stack 1530/1530 (2026-10-31); panel tsc/lint/build temiz; tarayıcı `~/.siteeksen-test/kanit/M7/` 10/10; changelog + roadmap güncel; para tutarlılığı fark 0. Yeni 12 kontrol önce bozuk kodla kırmızı gösterildi. Ek: verify adım 1'e port serbest kalma yeniden denemesi.

### M8 — Sakin uygulaması "Usta & Hizmet"
- [x] M8.1 Sekme; havuz: yakındaki yayındaki işletmeler, hizmet kalemleri ve fiyat aralıkları, mesafe, puan; telefon yalnız ücretli pakette
  — **Kanıt:** verify-mobile; ücretsiz işletmenin telefonu API yanıtında ve ekranda yok; tarayıcı D4 (web derlemesi)
  → **Sonuç:** `[D4]` `bash backend/scripts/verify-mobile.sh` 10/10; verify-stack 1533/1533 (2026-10-31) §75: `GET /market/showcase` siteyi kapsayan işletmeler (alan dışı yok), ücretli paket başta, telefon yalnız vitrinde telefon hakkı olan pakette, vergi no/bakiye/hesap kimliği yok; kategori süzgeci; sitesiz tedarikçi 403; işletme sayfasında gizlenen yorum yok, yayında olmayan 404. Sakin web derlemesinde tarayıcı `~/.siteeksen-test/kanit/M8/` 1–3: vitrin (mesafe, fiyat), ücretsiz işletmede telefon yok, ücretli işletmede telefon ve fiyatlar.
- [x] M8.2 Talep formu (kategori, açıklama, fotoğraf, zaman, telefon gizli, KVKK onayı), uygun işletme sayısı; "bu işletmeye gönder" — **Kanıt:** tarayıcı D4 + veritabanı satırları
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M8/` 4–5, 11–12: kategori seçince "yakınınızda 1 onaylı işletme"; açıklamadaki telefon kayıtta gizli; rıza işaretlenmeden gönderilemez; "Bu işletmeye talep gönder" → yalnız o işletmeye (1 gönderim, en çok 1 kabul); dosya seçiciyle fotoğraf eklendi ve yüklendi (photo_count 1).
- [x] M8.3 Taleplerim → teklifler yan yana → seç / talebi kapat; mesajlar; tamamlandı onayı / itiraz; puanlama — **Kanıt:** tarayıcı D4 uçtan uca (KİRACI)
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M8/` 6–9, 13–14 (KİRACI ve sakin olarak yönetici): teklif işletme telefonu ve tutarla; yazışma iki yönlü; teklif seçimi → iş sürüyor; tamamlandı onayı ve 5/5 puan; teklif seçmeden kapatma (CANCELLED, teklif reddedildi); işe gerekçeli itiraz (DISPUTED).
- [x] M8.4 Bildirimler zilde ve listede (mevcut bildirim ekranı) — **Kanıt:** tarayıcı D4: yeni teklif bildirimi KİRACI'da görünür, komşusunda görünmez
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M8/` 10: sakinin Bildirimlerim ekranında "Talebinize teklif" ve "İş tamamlandı"; aynı sitedeki komşunun bildirim listesinde yok, sahibinde var (API 200/200).
- [x] **M8 kapısı** (+ debug APK derlenir)
  → **Kapı (2026-10-31):** verify-stack 1533/1533 (2026-10-31); verify-mobile 10/10; `flutter build apk --debug` → app-debug.apk; tarayıcı `~/.siteeksen-test/kanit/M8/` 17/17; changelog + roadmap güncel. Adım 75'in 3 kontrolü önce bozuk kodla kırmızı gösterildi.

### M9 — SiteEksen Tedarikçi uygulaması (`supplier_app/`, Android + web)
- [x] M9.1 İskelet (`mobile/`/`admin_app/` yapısı, tema, API istemcisi, oturum, `file_opener`, web derlemesi) — **Kanıt:** `flutter analyze` 0, `flutter test` geçer; verify-mobile'a eklendi
  → **Sonuç:** `[D4]` `supplier_app/` (Flutter; paket `siteeksen_supplier`): dio istemcisi (jeton güvenli depoda, 401'de tek yenileme), go_router, `file_opener`, web derlemesi; Android yapılandırması sakin uygulamasıyla aynı sürümlerde (AGP 8.11, Kotlin 2.2, Gradle 8.14 — yeni şablonla `file_picker` derlenmiyordu). `bash backend/scripts/verify-mobile.sh` 14/14 (supplier_app: pub get, analyze 0, test +1, release manifestinde INTERNET); yeni kontroller önce bozuk kodla kırmızı (analyze, INTERNET; test ayrıca `flutter test` ile).
- [x] M9.2 Kayıt/giriş, hesap ve belgeler, işletmelerim (konum `flutter_map`, hizmet kalemleri), paket, bakiye (ödeme sayfası tarayıcıda açılır, dönüşte uygulama yenilenir)
  — **Kanıt:** web derlemesinde tarayıcı D4; Android debug APK
  → **Sonuç:** `[D4]` web derlemesinde tarayıcı `~/.siteeksen-test/kanit/M9/` 1–4: SMS koduyla kayıt (yeni hesap), hesap açma, iki belge yükleme (dosya seçici) ve incelemeye gönderme; haritaya dokunarak konum, kategori, hizmet kalemi, işletmeyi incelemeye gönderme; kartla bakiye yükleme (sahte iyzico sayfası) → uygulamaya dönüşte bakiye 300 TL. `flutter build apk --debug` → app-debug.apk. **Bulgu (karar gerekir):** ödemeden sonra tarayıcı `MARKET_TOPUP_RESULT_URL`'e (panelin bakiye sayfası) döner; uygulamaya geri dönüş adresi (deep link) yok — bakiye uygulamaya dönünce yenilenir.
- [x] M9.3 Gelen talepler (maskeli önizleme), kabul, teklif, mesaj, işler, puanlar; açılışta ve ekrana dönüşte yenileme — **Kanıt:** tarayıcı D4 uçtan uca (M6–M7 akışı uygulamadan)
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M9/` 5–10: maskeli önizleme ve kabul ücreti; kabulde alıcının adı/telefonu açıldı; teklif ve mesaj; teklif seçilince "İş tamamlandı"; puan ve tek seferlik yanıt; bildirimler (hesap onayı, yeni talep, teklif seçimi). Ekrana dönüldüğünde liste ve bakiye yenilenir (bakiye: uygulama yaşam döngüsü).
- [ ] M9.4 Test ortamı: `test-ortami.sh`'a tedarikçi uygulamasının web derlemesi (:3004) — **Kanıt:** "TEST ORTAMI HAZIR" çıktısında yeni adres
  → **Sonuç:** `[D1]` `backend/scripts/test-ortami.sh`: supplier_app web derlemesi :3004'te sunulur, CORS ve port denetimi listesine eklendi, "TEST ORTAMI HAZIR" çıktısında "Tedarikçi uygulaması http://localhost:3004". **Kalan:** çalışan test ortamı yeniden başlatılmadığı için çıktı bir sonraki açılışta görülecek.
- [ ] **M9 kapısı** (+ APK)
  → **Kapı (2026-11-01):** verify-stack 1533/1533 (2026-11-01); verify-mobile 14/14; iki APK (sakin, tedarikçi) derlendi; tarayıcı `~/.siteeksen-test/kanit/M9/` 11/11; changelog + roadmap güncel. **Kalan:** M9.4 test ortamı açılış çıktısı.

- [ ] **Bulgu (2026-11-01): verify-stack gece yarısı yanlış kırmızı** — 00:00–03:00 arasında 13 kontrol kırmızıya döndü (KVKK son gün, işletme projesi
  süreleri, hatırlatmalar, valör…). Neden: servis tarihleri İstanbul saatine göre yazıyor, kontroller `$PSQL` oturumunda UTC `CURRENT_DATE` ile
  karşılaştırıyor. İlk teşhis ("verify-stack `PGTZ` ayarlamıyor") yanlıştı: `export PGTZ` zaten var; ana makinede psql olmadığı için kullanılan
  Docker sarmalayıcısı (`scripts/tools/pg-docker/_pgrun`) `docker exec`'e `PGTZ`'yi geçirmiyordu, kaptaki psql UTC kalıyordu.
  → **Sonuç (2026-11-01, kullanıcı onayı):** `_pgrun` `-e PGTZ` geçirir; verify-stack adım 1'e "psql oturumu iş saat diliminde" kontrolü.
  Kırmızı gösterildi (eski sarmalayıcıyla `SHOW TimeZone` = UTC → BAŞARISIZ), düzeltmeyle Europe/Istanbul → GEÇTİ.

### M10 — Yönetim alımı
- [x] M10.1 Panel `/dashboard/usta-hizmet` + yönetici uygulaması: site talebi açma (MANAGER, yalnız site kategorileri), kurul/denetçi okur
  — **Kanıt:** verify-stack: DENETÇİ açamaz 403, okur 200; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1537/1537 (2026-11-01) §76: yönetici site adına talep açar; denetçi ve kurul üyesi açamaz 403 ama site taleplerini okur 200; sakin site taleplerini göremez 403. Panel `/dashboard/usta-hizmet` (menü: Yönetişim → Usta & Hizmet; yönetim + denetçi) ve yönetici uygulaması "Usta & Hizmet" ekranı. Tarayıcı `~/.siteeksen-test/kanit/M10/` 1–2 (panel: uygun işletme sayısı, talep), 8 (denetçi salt okuma), 9–10 (yönetici uygulaması web derlemesi). `verify-mobile.sh` 14/14.
- [x] M10.2 Teklif karşılaştırma tablosu — **Kanıt:** tarayıcı D4
  → **Sonuç:** `[D4]` tarayıcı `~/.siteeksen-test/kanit/M10/` 3: teklif karşılaştırma tablosu (işletme, tutar, kapsam, geçerlilik, puan, tamamlanan iş, telefon); denetçi aynı tabloyu salt okur.
- [x] M10.3 Seçilen teklif → `services/expense`'te onay bekleyen gider (`PENDING`, `vendor_tax_id` dolu, tedarikçi bağlı); ya da sözleşme formu önceden doldurulmuş açılır
  — **Kanıt:** verify-stack: gider satırı doğru tutar/vergi no/durumla; mevcut gider onay akışı ve sözleşme kontrolleri değişmeden yeşil; tarayıcı D4
  → **Sonuç:** `[D4]` verify-stack 1537/1537 (2026-11-01) §76: teklifi yönetici seçer (denetçi 403); site alımının işinde tedarikçinin fatura bilgisi (080 `mp_job_vendor`: unvan, VKN, vergi dairesi), sakin alımında yok; mevcut gider ucuyla onay bekleyen gider (PENDING, tutar, VKN, unvan). Tarayıcı `~/.siteeksen-test/kanit/M10/` 4–7: seçim → "Onay bekleyen gider oluştur" → `expenses` satırı `PENDING|14500.00|1234567890|Kemal Tesisat Ltd. Şti.`; "Sözleşme formunu doldur" → sözleşme formu başlık ve karşı tarafla dolu açılır (şema değişmedi). Mevcut gider ve sözleşme kontrolleri tam doğrulamada yeşil.
- [x] **M10 kapısı**
  → **Kapı (2026-11-01):** verify-stack 1537/1537 (2026-11-01); panel tsc/lint/build temiz; verify-mobile 14/14; tarayıcı `~/.siteeksen-test/kanit/M10/` 11/11; changelog + roadmap güncel. Adım 76'nın 3 kontrolü önce bozuk kodla kırmızı gösterildi.

### M11 — Tarayıcı test planı
- [x] M11.1 Test planı üreticisine (`docs/ozellik-haritasi/arac/test_plani.py`) yeni ekranlar/uçlar; elle yazılan uçtan uca senaryolar (talep → 4 kabul → teklif → iş → puan;
  öncelik penceresi; doğrudan talep; iki şube; platform iadesi; yönetim alımı) — **Kanıt:** `uret.sh` çıktısı; yeni bölüm `docs/test-plani/ilerleme.md` sırasına eklendi
  → **Sonuç:** `[D1]` 2026-11-01: `docs/test-plani/10-usta-hizmet.md` (8 uçtan uca senaryo: U-KAYIT-01, U-TALEP-01, U-KOTA-01, U-DOGRUDAN-01, U-SUBE-01, U-IADE-01, U-BAKIYE-01, U-YONETIM-01); `00-baslangic.md`'ye adresler (:3004, `/tedarikci`, `/platform`), hesaplar (PLATFORM, TEDARİKÇİ1/2) ve sorgular (Q-TALEP, Q-GONDERIM, Q-DEFTER); üretici sırasına eklendi (`test_plani.py`). `bash docs/ozellik-haritasi/arac/uret.sh` → 1284 test başlığı; üretilen bölümler yeni panel ekranlarını (`/dashboard/usta-hizmet`, `/tedarikci/*`, `/platform/*`) ve sakin/yönetici uygulaması ekranlarını içeriyor. `ilerleme.md` sırasına 17. satır (U, 8) eklendi.
- [ ] M11.2 Test ajanı bölümü yürütür; KALDI/KISMEN kalmayana kadar düzeltilir — **Kanıt:** `~/.siteeksen-test/sonuclar.jsonl` özeti; her GEÇTİ ekran görüntüsü ve işlem kaydıyla karşılaştırıldı
  → **Sonuç:** **Kalan:** test ajanı bölümü yürütecek. Not: 2026-11-01'de disk dolup Docker çökünce test ortamının veritabanı konteyneri silindi; test ortamı yeniden açılmalı (`test-ortami.sh`, bu sürümle :3004 ve pazaryeri verisi de kurulur).
- [ ] **M11 kapısı**

### M12 — Yayın öncesi
- [ ] M12.1 Güvenlik gözden geçirmesi (IDOR, maskeleme, ödeme dönüşü, hız sınırları, belge erişimi) — **Kanıt:** bulgular ve kapanış kanıtları `docs/claude/guvenlik-durumu.md`'de
  → **Sonuç:** `[D1]` 2026-11-01: `docs/claude/guvenlik-durumu.md` "Usta & Hizmet pazaryeri — güvenlik gözden geçirmesi": kapsam/IDOR, iletişim açılması, maskeleme, vitrin, ödeme dönüşü, bakiye, hız sınırları, belge erişimi, çıkar çatışması, saklama — her satır verify adımına bağlı. **Kalan (karar bekleyen 4 açık bulgu):** kapanış sonrası tamamlanan yükleme, mesaj/teklif hız sınırı, uygulamaya ödeme dönüşü, fotoğraf içeriği.
  → **Güncelleme (2026-11-01):** 4 açık bulgu M13'te kapandı (`guvenlik-durumu.md` kapanış satırları, verify-stack 1557/1557). Madde M0'a bağlı olduğu için açık kalır.
- [ ] M12.2 M0 maddelerinin hepsi kapalı — **Kanıt:** M0 kanıt satırları
- [x] M12.3 `docs/claude/servisler.md`, `docs/ozellik-haritasi/` ve `tasks/roadmap.md` güncel — **Kanıt:** `uret.sh` sonrası fark yok
  → **Sonuç:** `[D1]` 2026-11-01: `docs/claude/servisler.md`'ye marketplace (8111) satırı; `uret.sh` ile `docs/ozellik-haritasi/` ve `docs/test-plani/` yeniden üretildi (commit sonrası ikinci çalıştırmada fark yok); `tasks/roadmap.md` FAZ M satırları güncel.

### M13 — M12.1'in 4 açık bulgusu (kullanıcı kararları 2026-11-01) — uygulandı (2026-11-01)
Kararlar: (1) ödeme sayfası tedarikçi uygulamasının İÇİNDE açılır; (2) mesaj dk 20 / gün 300, teklif saatte 20, talep başına 5 düzenleme;
(3) kalan bakiye son 365 gündeki yüklemelerden karşılanan kısmıyla karta otomatik iade, 365 günü geçen kısım iade edilmez — sözleşmeye madde,
ayrıca kabul ettirilir (TBK m.21); (4) fotoğraflar platform onayından geçer: önce OCR, sonra (açılıp kapanan) yapay zekâ denetimi, ayrıca
platformda elle onay/ret ekranı.

**M13.1 Uygulama içi ödeme (`supplier_app`)**
- [ ] M13.1a Android: ödeme sayfası uygulama içi WebView'de (`webview_flutter`, yeni bağımlılık); dönüş adresine gidiş yakalanır, WebView kapanır,
  bakiye sunucudan yeniden okunur (sonuç istemciye güvenilmez, `Retrieve` sunucuda kalır); kullanıcı yarıda kapatırsa yükleme PENDING kalır,
  uzlaştırma işi sonuçlandırır — **Kanıt:** APK + emülatörde/cihazda sahte iyzico ile başarılı, reddedilen, yarıda kapatılan yol (ekran görüntüsü)
  → **Sonuç:** `[D4]` Android emülatörü (Pixel 8 API 34, debug APK, `adb reverse` ile geçici yığın): ödeme sayfası uygulamanın içinde açıldı (`~/.siteeksen-test/kanit/M13/`30), "Ödeme başarılı" → sayfa kapandı, "Ödeme alındı; bakiye güncellendi", bakiye 970 → 1.120 TL (33); X → "Ödemeden çıkılsın mı?" → Çık: bakiye değişmedi, hata yok (34–35). Bu sınamada M9'dan kalan hata bulundu: `setState(() => _future = …)` Future döndürdüğü için debug derlemede yenileme hiç çalışmıyordu (3 uygulamada 29 yer düzeltildi). Debug manifestine yalnız hata ayıklama için `usesCleartextTraffic` (sahte iyzico http). **Kalan:** reddedilen ödeme yolu emülatörde sınanmadı (web D4 ve verify-stack'te sınandı).
- [x] M13.1b Web derlemesi (WebView yok): aynı sekmede açılır, dönüş adresi uygulamanın bakiye rotasına yönlenir — **Kanıt:** tarayıcı D4
  → **Sonuç:** `[D4]` web derlemesi (:3013): ödeme aynı sekmede → dönüş `http://localhost:3013/#/bakiye?…status=SUCCEEDED` (panele değil), bakiye +100 TL, sonuç mesajı (`~/.siteeksen-test/kanit/M13/`20–22); verify-stack 1557/1557 (2026-11-01, `verify-m13c`): dönüş hedefi `APP` → uygulama adresine 303, istemcinin verdiği adres yok sayılır.
- [x] M13.1c `verify-mobile` (analyze/test) yeşil — **Kanıt:** çıktı
  → **Sonuç:** `[D2]` `verify-mobile.sh` 14/14 (2026-11-01, setState düzeltmesinden sonra).

**M13.2 Hız sınırı**
- [x] M13.2a Mesaj: kullanıcı başına dakikada 20, günde 300; teklif: hesap başına saatte 20, teklif başına 5 düzenleme; aşımda 429 + açık mesaj;
  sınırlar `mp_settings`'te (koda gömülmez), platform ayar ekranında — **Kanıt:** verify-stack: 21. mesaj 429, 21. teklif 429, 6. düzenleme 429; önce kırmızı
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §74: dakikalık sınırda 429 ("dakikada en çok 3"), günlük 429, düzenleme sınırında 429, saatlik yeni teklif 429; sınırlar platform ayarından. Bozuk kodla (sınır kapalı) kırmızı gösterildi (`harness-m13-kirmizi`).

**M13.3 Bakiyenin karta otomatik iadesi**
- [x] M13.3a `pkg/iyzico` iade (paymentId ile, kısmi tutar) + sahte iyzico'ya iade ucu — **Kanıt:** `go test ./pkg/iyzico/...`; imza testi
  → **Sonuç:** `[D2]` `go test ./pkg/iyzico` (TestRefundSignsAndChecksAmount: v2 yol, imza, kuruş tutarı, farklı tutar ve failure hata); sahte iyzico'lara `/v2/payment/refund` (verify + test ortamı).
- [x] M13.3b Defter: `CARD_REFUND` hareket türü; `mp_card_refunds` (yükleme, tutar, durum, iyzico yanıtı, deneme sayısı) + RLS — **Kanıt:** verify-stack RLS listesi
  → **Sonuç:** `[D2]` migration 081; verify-stack 1557/1557 (2026-11-01, `verify-m13c`): RLS 152 tablo, RLS dışı liste değişmedi; para tutarlılığı fark 0.
- [x] M13.3c Üyelik kapanışı: kalan bakiye en yeni yüklemeden başlayarak (LIFO) son 365 gündeki yüklemelerin iade edilmemiş kısmından karşılanır,
  her yükleme için karta kısmi iade; 365 günü aşan kısım `EXPIRED_BALANCE` satırıyla kapanır; elle havale kaydı yalnız iyzico hatasında yedek
  — **Kanıt:** verify-stack: üç yükleme (10, 200, 400 gün önce) ile kapanış → iki iade, bir sona erme satırı, bakiye 0, para tutarlılığı fark 0
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §72: 10/200/400 günlük yüklemelerle kapanış → iki karta iade + `EXPIRED_BALANCE`, bakiye 0; ikinci hesapta kalan 150 TL yalnız EN YENİ yüklemeye iade (sıra kontrolü: eskiden başlayınca kırmızı gösterildi); iyzico'ya iki imzalı kısmi iade, SUCCEEDED. D4 panel: kapanış penceresi ve sonuç, `/platform/iadeler` "Karta iletildi", tedarikçi bakiyesinde karta iade (`~/.siteeksen-test/kanit/M13/`11–14).
- [x] M13.3d Kapanıştan sonra tamamlanan yükleme hesaba yazılmaz, aynı işte karta iade edilir — **Kanıt:** verify-stack (bulgu 3)
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §72: kapanış sonrası sonuçlanan yükleme bakiyeye yazılmadı (defter satırı yok), `LATE_TOPUP` iadesi; bozuk kodla kırmızı.
- [x] M13.3e İade başarısızsa yeniden deneme (zamanlayıcı), tükenince platforma bildirim + elle işlem kuyruğu — **Kanıt:** sahte iyzico hata modu ile
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §72: iyzico reddi → FAILED + tedarikçiye gecikme bildirimi → platform yeniden dene → SUCCEEDED; HTTP 500 (sonuç bilinmiyor) yeniden denenmedi, platform kuyruğunda, dekontsuz kapanış 422, dekontla MANUAL.
- [x] M13.3f Sözleşme maddesi taslağı `docs/hukuk/tedarikci-bakiye-kosullari.md` (TASLAK, avukat onayı M0.4): bakiye yalnız platform hizmetinde
  kullanılır, çekilemez; üyelik sona erince son 365 günde yapılan yüklemelerden karşılanan kalan bakiye karta iade edilir; 365 günü geçen kısım
  iade edilmez; hesaplama sırası (en yeni yükleme önce) — **Kanıt:** dosya
  → **Sonuç:** `[D1]` `docs/hukuk/tedarikci-bakiye-kosullari.md` (TASLAK, avukat onayı M0.4; m.25 riski ve seçenekler yazılı); verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §72: belgedeki metin ve sürüm uygulamadaki metinle birebir (bozulunca kırmızı).
- [x] M13.3g Ayrıca kabul (TBK m.21): ilk yüklemeden önce madde ayrı kutuyla gösterilir, kabul sürümü ve zamanı kaydedilir; kabulsüz yükleme 409
  — **Kanıt:** verify-stack; tarayıcı D4 (panel + uygulama)
  → **Sonuç:** `[D4]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §72: kabulsüz yükleme 409 `TERMS_REQUIRED`, eski sürüm 409, kabul sürüm + SHA-256 + IP; panel (`~/.siteeksen-test/kanit/M13/`1–2) ve uygulama (20) kabul kartı/sürüm-tarih satırı.

**M13.4 Fotoğraf denetimi** — kararlar (2026-11-01): hizmet fotoğrafları VE talep fotoğrafları denetlenir (talep beklemeden gider,
fotoğraf onaylanınca tedarikçiye görünür); OCR'da iletişim bilgisi → otomatik ret, gerekçe yükleyene gösterilir; yapay zekâ açılıp
kapanır, sağlayıcı platformdan seçilir (yerel ya da SaaS; API anahtarı ya da kullanıcı adı/parola ile); OCR ayrı mikroservis.
- [x] M13.4a `services/moderation` (8112): `photo_moderation` kuyruğu (081 sonrası migration), RLS; pazaryeri fotoğraf yüklenince kuyruğa
  yazar; vitrin/tedarikçi yalnız `APPROVED` fotoğrafı görür; yükleyen durumu ve ret gerekçesini görür — **Kanıt:** verify-stack
  → **Sonuç:** `[D2]` migration 082, `services/moderation` (8112, gen-deploy/gateway/dev-up/test-ortami); verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §71/§73/§77: onaysız fotoğraf vitrinde ve tedarikçide 404 (sayıda yok), onaydan sonra açık; sahibi durumu görür.
- [x] M13.4b OCR: Tesseract (`tur+eng`) servis kabında (gen-deploy ek paket); metinde telefon/e-posta/web adresi → `REJECTED` (yapay zekâya
  gitmez) — **Kanıt:** üretilen test görselleriyle verify-stack (numaralı görsel ret, numarasız görsel geçer)
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §77 (gerçek Tesseract, Alpine paketleriyle Docker'da): telefonlu görsel → REJECTED, gerekçe + bildirim, yapay zekâya gitmedi; temiz görsel OCR'dan geçti; `go test ./services/moderation` (TestFindContacts).
- [x] M13.4c Yapay zekâ: platform ayarı (aç/kapa, sağlayıcı türü Anthropic / OpenAI uyumlu (Ollama, LM Studio, vLLM, OpenAI…), adres, model,
  kimlik: API anahtarı / kullanıcı adı-parola / yok; gizli değerler şifreli, geri okunmaz; "bağlantıyı sına"). Temiz → otomatik onay;
  sakıncalı (çıplaklık, şiddet, nefret, silah/uyuşturucu, QR/iletişim…) ya da hata → elle onay kuyruğu; kapalıyken hepsi kuyruğa
  — **Kanıt:** sahte sağlayıcıyla (iki API biçimi) temiz/sakıncalı/hata yolları verify-stack; KVKK yurt dışı aktarım notu `questions.md`
  → **Sonuç:** `[D2]` verify-stack 1557/1557 (2026-11-01, `verify-m13c`) §77: Anthropic Messages (API anahtarı, `anthropic-version 2026-10-21`, görsel + JSON şeması) temiz → onay; sakıncalı, sağlayıcı reddi, HTTP 500 → elle onay; OpenAI uyumlu + Basic kimlik → onay; anahtar şifreli, yanıtta ve işlem kaydında yok; 'bağlantıyı sına'. KVKK notu `questions.md` S-24.
- [x] M13.4d Platform ekranları `/platform/fotograflar` (görsel, OCR metni, yapay zekâ sonucu, onayla/reddet gerekçeli, otomatik
  onaylananları kaldır) ve `/platform/yapay-zeka` (sağlayıcı ayarı) — **Kanıt:** tarayıcı D4
  → **Sonuç:** `[D4]` panel (`~/.siteeksen-test/kanit/M13/`3–10): tedarikçi kaleminde Reddedildi + gerekçe / İncelemede; platform `/platform/fotograflar` görsel + OCR metni + Onayla + reddedilenlerde OCR bulgusu; `/platform/yapay-zeka` anahtarsız açma reddi, anahtar "Tanımlı" (geri gösterilmez), bağlantı sınaması, açıkken temiz fotoğraf otomatik Yayında; uygulamada hizmet fotoğrafı durumu (23), sakin uygulamasında talep fotoğrafı "tedarikçilere gösterilmedi" (24).
- [ ] **M13 kapısı** (verify-stack + verify-mobile + panel tsc/lint/build + para tutarlılığı + changelog + roadmap; `guvenlik-durumu.md` 4 bulgu kapanış kanıtı)
  → **Kapı (2026-11-01):** verify-stack 1557/1557; verify-mobile 14/14; panel tsc/lint/build temiz (kopyada); para tutarlılığı fark 0; changelog + roadmap + `guvenlik-durumu.md` güncel; yeni kontroller bozuk kodla kırmızı gösterildi (19 kırmızı + sıra kontrolü). **Kalan:** M13.1a reddedilen ödeme yolu Android'de; test ortamı yeniden açılınca (`test-ortami.sh`) yeni test planı bölümleri (U-KOSUL/ODEME/IADE-02/SINIR/FOTO) test ajanınca yürütülecek.

### Yurt dışı hazırlığı (kullanıcı kararı 2026-11-01: sonra)
- [ ] **YD.1 Site başına saat dilimi** — bugün tek `APP_TIMEZONE` (Europe/Istanbul). Tasarım: `properties.timezone` (varsayılan Europe/Istanbul);
  `dbscope.For` kapsamı açarken `SET LOCAL TimeZone` → veritabanındaki `CURRENT_DATE`/`now()::date` (30 dosya) sorgu değişmeden site gününü verir;
  Go tarafında `time.Now()` kullanan 132 yer site konumuna geçirilir; zamanlayıcı işleri site saatine göre; tedarikçi hesabına da saat dilimi.
  Ön koşul: yurt dışı mevzuat modülü (KMK, TL, KDV, `legal_parameters` ülkeye bağlı) — saat dilimi tek başına yetmez.


---

# FAZ H — Harita bulgularının giderilmesi (2026-10-26) — PLAN `[D0]`, sürüm 2

Kaynak: `docs/ozellik-haritasi/06-bulgular-ve-eksikler.md`, `05-arayuzsuz-uclar.md`.

Kullanıcı kararları (2026-10-26):
- **K1:** IoT sensör kaldırılmaz, tamamlanır.
- **K2:** QR + GPS zorunluluğu + devriye raporu.
- **K3:** sakin uygulamasına işletme projesi görüntüleme + görüş/itiraz eklenir; **seçenekli** — site ayarı `OWNER_PLAN_OBJECTIONS` (varsayılan açık) kapatılırsa proje görünür, yeni itiraz alınmaz.
- **K4:** yönetici mobil uygulaması paneldeki her işi yapar.
- **K5:** okundu bilgisi + tüm işlemlerin kaydı + ayarlardan aç/kapa ve düzey.

## T. Tarayıcı testi (2026-10-29) — HAZIR, YÜRÜTÜLMEDİ

- [x] Test ortamı (`backend/scripts/test-ortami.sh`), hesaplar, sahte sağlayıcılar, Adminer, sonuç sayfası
- [x] İki uygulamanın web derlemesi; headless gezintide hata yok
- [x] Test planı `docs/test-plani/` (1152 test; üretici `arac/test_plani.py`)
- [ ] Planın tarayıcı ajanıyla yürütülmesi (kullanıcı) → sonuçlar `~/.siteeksen-test/sonuclar.jsonl`
- [ ] KALDI/KISMEN sonuçlarının düzeltilmesi
- [ ] **Kullanıcı kararı (2026-10-29): yapılacak** — bildirim üretmeyen akışlara bildirim eklenecek (06 E7: talep açma/durum, havale onay/ret, yeni rezervasyon talebi, işletme projesi bildirimi, genel kurul çağrısı, NPS ölçümü)
- [ ] Yönetici uygulaması küçük arayüz (06 E8)
- [ ] Panel ana sayfa, mali yetkisi olmayan rol (GÖREVLİ): "Son ödemeler" kartı 502 "Ödeme verisi alınamadı… (403)" ve tahsilat uyarısı gösteriyor; yetkisi olmayana bu kartlar gizlenmeli (2026-10-29 test günlüğü)
- [ ] Belge servisi: var olmayan belgeye reddedilen erişim, `document_access_logs` yabancı anahtarına takılıp kaydedilemiyor (yalnız günlük)

## H.0 Sınıflandırma — 51 arayüzsüz uç (inceleme sonucu)

| Sınıf | Uçlar | Karar |
|---|---|---|
| Yanlış alarm (kullanılıyor) | `/auth/refresh`, iyzico dönüşü, cihaz canlılık sinyali, `/public/clearance/:code`, davet/kiracılık `decline` (değişken yol), `/finance/assessments/overview` (gateway göstergesi) | Dokunulmaz; harita aracı tanıyacak (H.9) |
| Detay uçları (8) | `GET /x/:id` | Dokunulmaz; yeni ekranlarda kullanılacak |
| Bilerek 501, özellik başka yerde var | `meeting_wizard` (17), `/credentials*` (7), `/esg/sustainability-score` | **Kontrollü kaldırma (H.1)** |
| Bilerek 501, özellik yok | IoT sensör/alarm (6), banka (16) | Sensör **tamamlanır (H.4)**; banka kalır (S-07) |
| Arka plan hazır, ön yüz yok | 21 uç + yönetici mobilde olmayan 117 yazma işlemi | **Tamamlanır (H.5–H.7)** |

## H.1 Kontrollü kaldırma (etki taraması → kaldırma → sıfır referans → bütün doğrulamalar)

- [x] `[D3]` **H.1.1 `meeting_wizard`** (governance'ta var). Etkilenenler: servis dizini ve Dockerfile, gateway önekleri, `gen-deploy.py` (compose/k8s/CI yeniden üretilir), `.gitignore`, verify-stack 501 kontrolleri, `check-gateway-routes.py`, yönetici mobil `meeting_wizard_screen` + `/meetings` rotası, CLAUDE.md, `api-sozlesmesi.md`.
- [x] `[D3]` **H.1.2 `/credentials*` 8 uç.** Panel sayfası yanlış bilgi veriyor: "iyzico/SMS/e-posta bağlı değil" yazıyor, üçü de ortam değişkeniyle bağlı. Sayfa "Entegrasyon durumu"na dönüşür ve gerçek durumu gösterir:
  - bildirim kanalları (`/notifications/summary` → `delivery`),
  - kart sağlayıcısı (finans `/health`'e `card_provider_ready`),
  - dosya deposu (`document /health` → `storage`).

  Yönetici mobil `api_settings_screen` de aynı içeriğe döner.
- [x] `[D3]` **H.1.3 `GET /esg/sustainability-score`** kaldırılır.

## H.2 Bildirim kutusu ve okundu bilgisi (K5 — birinci kısım)

- [x] `[D3]` **Migration 073 `notification_reads`:** `(notification_id, user_id, read_at)`. RLS'li, yalnız ekleme yapılır, ebeveyn anahtarına indeks var. `notifications` tablosu değişmez; gönderilmiş kayıt zaten güncellenemiyor.
- [ ] **Uçlar:** `GET /notifications` (her kayıtta `read_at`; `?unread=1`), `GET /notifications/unread-count`, `POST /notifications/:id/read`, `POST /notifications/read-all`. Başkasının bildirimi okundu sayılamaz.
- [ ] **Ekranlar:**
  - Panel: zil rozeti, açılır son 10 bildirim, `/dashboard/inbox` sayfası. Mevcut `/dashboard/notifications` sayfasının adı "Toplu bildirim ve giden kutusu" olur.
  - Yönetici mobil: bildirim kutusu.
  - Sakin: okunmamış rozeti ve okundu işareti.
- [ ] Her okuma işlem kaydına da düşer (H.3).

## H.3 İşlem kaydı (K5 — ikinci kısım): "her şey tek yerde"

**Tasarım:** Mevcut `audit_logs` genişletilir; ikinci bir log tablosu açılmaz.
- Migration 073'e eklenecek sütunlar:
  - `source`: `API` / `CLIENT` / `SYSTEM`
  - `event`: ör. `auth.login`, `menu.open`, `notification.read`
  - `details JSONB`
  - `screen`
- Uygulama rolü bugün `audit_logs`'u okuyamıyor (`025:88`). Bu korunur. Okuma, yalnız aktif sitenin kayıtlarını döndüren `SECURITY DEFINER` işlevlerle yapılır:
  - `audit_log_list(filtreler)`
  - `audit_log_stats()`

**Kaydedilenler:**

| Olay | Kaynak | Düzey |
|---|---|---|
| Her yazma isteği, 403 (`DENIED`), kişisel veri içeren okumalar (sakin, personel, KVKK, belge, acil kart, kişi bazlı finans) | sunucu ara katmanı | **Zorunlu** |
| Giriş başarılı/başarısız (maskeli telefon), çıkış, şifre/telefon/e-posta değişikliği, kilit | kimlik servisi | **Zorunlu** |
| Diğer bütün okuma istekleri (bugünkü davranış) | sunucu ara katmanı | Standart |
| Bildirim/duyuru okundu | ilgili servis | Standart |
| Ekran açma, menü tıklama, sekme değişimi, arama, filtre, dışa aktarma, oturum süresi | istemciler (panel, sakin, yönetici mobil) → toplu `POST /activity` | Tam |

**Ayar:** Ayarlar → "İşlem kaydı". Seçenek: `KAPALI / STANDART / TAM`. Varsayılan STANDART (bugünkü davranış). Yalnız MANAGER değiştirebilir; değişiklik ayar geçmişine yazılır.
- Sunucu ara katmanı düzeyi site başına 60 sn önbellekle okur.
- İstemciler düzeyi girişte alır; TAM değilse etkinlik göndermez.

**Ekran:** Panel `/dashboard/audit` ve yönetici mobil "İşlem kayıtları".
- Görebilen: MANAGER ve AUDITOR.
- Filtre: kullanıcı, tarih, olay, modül, sonuç.
- Satır detayı gösterilir; CSV dışa aktarılır (dışa aktarma da kayda düşer).

**Saklama:** TAM düzey istemci etkinliği varsayılan 180 gün. Saklama kurallarına "işlem kaydı (istemci etkinliği)" kategorisi eklenir; mevcut periyodik imha işi uygular. Zorunlu kayıtlar imha kapsamı dışındadır.

## H.4 IoT sensörleri — tamamlanır (K1)

**Neden yarım kaldı:** İlk commit (2026-02-01) sensörleri MongoDB varsayımıyla mock olarak yazdı. MongoDB hiç kurulmadığı için 2026-09-14'te dürüstçe 501'e çevrildi (`tasks/todo.md:570`). Özellik faydalı, PostgreSQL ile yapılabilir.

- [x] `[D3]` **Migration 074:**
  - `sensors`: tür (SU_KACAGI, SICAKLIK, NEM, DUMAN, GAZ, ELEKTRIK_KESINTISI, DEPO_SEVIYESI, ASANSOR_ARIZA, KAPI_ACIK, DIGER), konum, birim, alt/üst eşik, cihaz anahtar özeti, son değer ve zaman.
  - `sensor_readings`: zaman serisi; `(sensor_id, recorded_at)` indeksi; saklama kuralı.
  - `sensor_alerts`: AÇIK / ONAYLANDI / KAPANDI.

  Hepsi RLS'li.
- [ ] **Uçlar:** mevcut stub yollar gerçeğe döner (`/sensors`, `/sensors/:id`, `/sensors/:id/data`, `/iot/alerts`, `/iot/alerts/:id/acknowledge`). Bunlara ek olarak:
  - `POST /sensors` (yönetim tanımlar, anahtar bir kez gösterilir),
  - `PATCH /sensors/:id`,
  - `POST /iot/alerts/:id/close`,
  - cihazın veri gönderdiği kimliksiz uç `POST /public/sensors/data` (`X-Device-Key`, 057 geçiş cihazı modeli).
- [ ] **Kurallar:**
  - Eşik aşımında alarm açılır ve `iot.alert` bildirimi Operations kümesine gider.
  - Aynı sensörde açık alarm varken yeni alarm açılmaz (`DedupeKey`).
  - Değer normale dönünce "düzeldi" kaydı yazılır.
  - Sinyali kesilen sensör için bekçi `iot.offline` olayı açar (parking cihaz bekçisi deseni).
- [ ] **Ekranlar:**
  - Panel "Sensörler": liste, son değer, grafik yerine son 24 saat tablosu, tanımlama, anahtar yenileme, alarmlar (onayla/kapat).
  - Yönetici mobil: aynısı.
- [ ] **Doğrulama:** sahte cihaz `curl` ile veri gönderir → alarm → bildirim → onay → kapanış.

## H.5 Devriye — QR + GPS + rapor (K2)

**Mevcut şema:** `patrol_checkpoints.latitude/longitude` ve `qr_code` var ama kullanılmıyor. `patrol_logs.gps_track` JSONB var.

- [x] `[D3]` **Migration 075:**
  - `patrol_checkpoints`'e eklenecekler:
    - `radius_m` (varsayılan 30),
    - `location_accuracy_m` (konum kaydedilirken ölçülen doğruluk),
    - `location_check` (`REQUIRED` / `EXEMPT`; muafiyet gerekçesi ve muafiyeti veren kişi zorunlu),
    - `qr_token` (rastgele; yeniden üretilince eski baskı geçersiz olur).
  - `patrol_track_points`: tur başına konum noktaları (zaman, enlem, boylam, doğruluk, hız, `is_mocked`).
  - `patrol_scan_attempts`: kabul ve **red** dahil her okutma denemesi; mesafe, doğruluk ve red nedeniyle kanıt olarak saklanır.

  Hepsi RLS'li.
- [ ] **Nokta kurulumu:**
  - Yönetici mobilde noktanın yanında "Konumu buradan al": ölçülen doğruluk ≤ 20 m olmalı, değilse kaydetmez.
  - Panelde konum haritadan değil sayısal girilir.
  - Panelde ve mobilde "QR yazdır / yenile" (A4 baskı, nokta adı + QR).
- [ ] **Okutma kuralları (sunucuda — istemciye güvenilmez):**
  1. Tur açık ve görevliye ait olmalı.
  2. QR, turun rotasındaki aktif noktanın güncel `qr_token`'ı olmalı.
  3. İstek konum taşımalı. `is_mocked` → **red** (sahte konum).
  4. Doğruluk > 50 m → **red** ("konum yeterince hassas değil, açık alana çıkın").
  5. Mesafe > `radius_m` + doğruluk → **red** ("noktanın yanında değilsiniz: 84 m"). Noktada `EXEMPT` varsa yalnız 1-2-3 uygulanır ve okutma raporda "konum muaf" olarak işaretlenir.
  6. Aynı nokta aynı turda bir kez sayılır. Zaman sunucudan alınır. Önceki okutmaya göre fiziksel olarak imkânsız hız (> 15 m/s) varsa "şüpheli" işaretlenir.
- [ ] **Takip:**
  - Devriye ekranı açıkken 30 sn ya da 20 m'de bir konum `POST /patrols/:id/track`'e gönderilir.
  - Uygulama arka plana düşerse takip durur. Boşluk raporda "takip kesintisi (hh:mm–hh:mm)" diye görünür.
  - Arka plan servisi kullanılmaz; ek izin ve pil yükü yaratırdı.
  - Konum yalnız açık tur boyunca toplanır (KVKK m.4 ölçülülük). Saklama kuralı 1 yıl. Aydınlatma metnine personel konum maddesi eklenir.
- [ ] **Yönetici mobil (STAFF ve yönetim) "Devriye yürüt" akışı:**
  1. Rota seç → konum izni → "Turu başlat".
  2. Nokta listesi (okutulan/bekleyen, mesafe göstergesi).
  3. "QR okut" → kamera açılır; okuma anındaki konumla gönderilir; red nedeni ekranda gösterilir.
  4. "Sorun bildir" (nokta, önem, açıklama).
  5. "Turu bitir" (not).
- [ ] **Devriye raporu** (panel `/dashboard/patrol/reports` + yönetici mobil):
  - Dönem/görevli/rota filtresi.
  - Her tur: başlangıç–bitiş, süre/beklenen, okutulan/beklenen nokta, reddedilen denemeler ve nedenleri, muaf okutmalar, şüpheli hızlar, takip kesintileri, sorunlar.
  - Konum izi: harita (bağımlılık kararı **B-3**) ya da onaylanmazsa nokta tablosu + her satırda harita bağlantısı.
  - Dönem özeti: planlanan/yapılan/kaçırılan tur, ortalama süre, en çok reddedilen nokta.
- [ ] **Etki:** `patrol.issue` bildirimi ve zamanlayıcının `patrol.overdue` hatırlatması gerçek turlarla tetiklenir. verify-stack senaryosu: yanında olmadan okutma reddedilir, yanında kabul edilir, sahte konum reddedilir.

## H.6 Sakin uygulaması (önceki S1–S11; S12 K3'e bağlı) — TAMAMLANDI (2026-10-26; verify-stack adım 67, verify-mobile 10/10, APK)

| # | Ekran | Uçlar |
|---|---|---|
| S1 | Ödeme geçmişi | `GET /finance/my-payments` |
| S2 | Araçlarım | `GET/POST /vehicles`, `DELETE /vehicles/:id` |
| S3 | Ziyaretçilerim (iptal, kod yenile) | `GET /visitors`, `/visitors/:id/cancel`, `/visitors/:id/pass` |
| S4 | Sayaçlarım | `GET /meters`, `/meter-readings` |
| S5 | Kargo teslim kanıtı | `GET /packages/:id/proof/:kind` |
| S6 | Tadilat başvurusunu geri çek | `POST /renovations/:id/cancel` |
| S7 | NPS yanıtı | `GET /nps`, `POST /nps/:id/respond` |
| S8 | İlan yorumları | `GET/POST /bulletins/:id/comments` |
| S9 | Anket yorumları | `GET /surveys/:id/comments` |
| S10 | Tüm cihazlardan çıkış | `POST /users/me/logout-all` |
| S11 | Bildirim okundu | H.2 |
| S12 | (K3) İşletme projesi görüşü | yeni okuma ucu + `POST /governance/budgets/:id/objections` |

Ek olarak sakin uygulaması TAM düzeyde ekran/menü olaylarını gönderir (H.3).

## H.7 Yönetici mobil — panelle tam eşitlik (K4) — TAMAMLANDI (2026-10-26; harita aracı: panelin çağırdığı her uç yönetici uygulamasında da var, fark 0; analyze temiz, 35 test, APK)

**İlke:** Paneldeki her sayfa ve her işlem yönetici uygulamasında da olur. Rol kuralları paneldeki `rbac.ts` ile birebir aynıdır: STAFF yalnız operasyonu görür, AUDITOR salt okur.

**Ortak altyapı (önce yapılır, ekran başına iş azalır):**
- `api_views.dart` genişletilir: form alanı tanımından form üretme, satır eylemi menüsü, onay/gerekçe penceresi, dosya seçme ve yükleme, PDF/Excel indirme ve açma.
- `rbac.dart`: paneldeki rota-rol tablosunun karşılığı. Menü gruplanır: Sakinler ve İletişim / Mali / Yönetişim / Operasyon / Analiz / Sistem.

**Modül → ekran planı** (her satırdaki bütün işlemler 1. bölümdeki panel tablolarıyla birebir):

| Grup | Ekranlar (yeni = ★) | Eklenecek işlemler |
|---|---|---|
| Sakinler ve iletişim | Sakinler, ★Bağımsız bölümler, ★Görevlendirmeler, ★KVKK, Talepler, ★Tadilat, ★Kural ihlali, ★Acil durum, ★Sigorta (DASK), Duyurular, İlan panosu, Anketler, Bildirimler | Toplu aktarım (CSV), davet, kiracılık yönetim yolu (belge+şifre), telefon değiştirme, kilit açma; bölüm ekle/düzenle; görevlendir/bitir; KVKK yanıt; tadilat onay/ret/durdur/tamamla/rıza; kural ve ihlal süreci; nokta/iletişim/tatbikat, durum çağrısı ve yanıtları, acil kartlar; DASK ve hasar; anket yayınla/kapat/iptal; toplu bildirim, tercih, giden kutusu |
| Mali | Tahakkuk, Tahsilat ve borçlar, Giderler, Sayaç ve ısı payı, Tahsilat riski | Borcu yoktur belgesi; ödeme ters kaydı; gecikme tazminatı işletme; açılış bakiyesi; alacak dekontu ve ters kaydı; banka ekstresi yükleme/eşleştirme/yok sayma/daireye işleme; dekont indirme; defter doğrulama; sayaç ekle/değiştir/sil; paylaştırma; pusula itirazı yanıtı |
| Yönetişim | ★İşletme projesi, ★Genel kurul, ★Defterler, ★İcra ve dava, ★Ortak alan geliri, Sözleşmeler, ★Belge arşivi | Proje oluştur/bildir/kesinleştir/tahakkuk; itiraz sonuçlandırma; toplantı oluştur/çağrı/hazirun/toplantı yap/oy/gündem kapat; defter kaydı/kapat/doğrula/dışa aktar; dava; kira ve gelir; sözleşme süresi dolanları kapat; belge yükle/arşivle/erişim kaydı |
| Operasyon | Ziyaretçi, Kargo, Otopark, Rezervasyon, Devriye (H.5), Personel, Demirbaş, Stok, ★Sensörler (H.4) | Kod yenile; kanıt görüntüle; araç ekle/sil, plaka sorgu, cihaz ekle/sil ve olaylar; tesis ekle/düzenle, onay/ret; personel işten çıkış, SGK, izin gir/ret, uyum takvimi, bordro oluştur/öde/iptal, maliyet özeti; demirbaş ekle/bakım/elden çıkar/zimmet/kategori; stok kalem/kategori/sil/hareket geçmişi |
| Analiz | Enerji, ★NPS, ★ESG, Raporlar | NPS aç/kapat/detay/yorumlar; karbon ayak izi hesabı |
| Sistem | ★Ayarlar, ★Entegrasyon durumu, ★İşlem kayıtları (H.3), ★Hesabım | Site ayarları, işlem kaydı düzeyi, saklama kuralları ve imha, malik görünürlük politikası, kamera/biyometrik envanteri, site pasifleştirme; kendi telefon/e-posta değişikliği; site değiştirme / yeni site |

## H.8 Panel eklemeleri — TAMAMLANDI (2026-10-26; P1–P15 hepsi; tsc/lint/build temiz)

| # | Eklenecek |
|---|---|
| P1 | Bildirim kutusu (H.2) |
| P2 | Demirbaş kategorisi ve zimmet |
| P3 | Stok kategorisi, kalem silme, hareket geçmişi |
| P4 | Sayaç silme |
| P5 | Kamera kaydı düzenleme |
| P6 | Bordro maliyet özeti |
| P7 | Plaka sorgu |
| P8 | Kargo teslim kanıtı |
| P9 | İlan ve anket yorumları (görme/gizleme) |
| P10 | Ziyaretçi kodu yenileme |
| P11 | Entegrasyon durumu (H.1.2) |
| P12 | Giriş sayfası ölü bağlantı |
| P13 | İşlem kayıtları sayfası ve ayarı (H.3) |
| P14 | Sensörler (H.4) |
| P15 | Devriye QR yazdırma, nokta konumu/yarıçap/muafiyet, rapor sayfası (H.5) |

**Silme davranışı (H.2.4) önce incelenir:** hareketi/okuması olan kayıtta geçmişi silen bir davranış varsa düğme yazılmaz, raporlanır.

## H.9 Harita aracı ve belgeler

- [x] Yanlış alarmlar tanınır (dinamik yollar açık yazıldı; `openDownload`/`optionsFrom` araca öğretildi — Ders 58).
- [x] Her aşama sonunda harita yeniden üretilir ve 06 güncellenir.
- [x] Changelog kanıtla yazılır.
- [x] CLAUDE.md gerçek duruma göre güncellenir.
- [x] `legal/kvkk-aydinlatma.md`'ye işlem kaydı ve personel konum maddeleri eklenir (H.5'te).

## H.10 Planın zihinde çalıştırılması — bulunan sorunlar ve çözümleri

| # | Sorun | Çözüm (plana işlendi) |
|---|---|---|
| Z1 | "Loglamayı kapat" seçeneği KVKK m.12 (veri güvenliği) ve mali kayıt değiştirilemezliğiyle çelişiyor: giriş, yetki reddi, kişisel veri erişimi ve yazma işlemleri kaydı kapatılırsa ihlal tespit edilemez | KAPALI = yalnız **zorunlu çekirdek**. Ayar ekranı bunu açıkça yazar. Zorunlu kayıt hiçbir düzeyde kapanmaz. |
| Z2 | Uygulama rolü `audit_logs`'u okuyamıyor (bilinçli: kayıtlar değiştirilemesin, toplu okunamasın) | Okuma yalnız site kapsamlı `SECURITY DEFINER` işlevlerle; doğrudan `SELECT` yetkisi verilmez |
| Z3 | TAM düzeyde her tıklama veritabanını şişirir; istemci sahte olay basabilir | İstemci 20 olaylık ya da 15 sn'lik toplu gönderim; sunucu tarafında kişi başı dakikada en çok 300 olay, bilinmeyen olay türü reddi, zamanı ve kullanıcıyı sunucu yazar; 180 gün saklama; `(property_id, created_at)` indeksi |
| Z4 | Her istekte düzey için veritabanı sorgusu yavaşlatır | Site başına 60 sn önbellek; ayar değişince önbellek geçersizleşir (en geç 60 sn) |
| Z5 | GPS kapalı alanda (otopark, kazan dairesi) zayıf → görevli okutamaz | Nokta başına yarıçap; konum sahada ölçülerek kaydedilir; doğruluk sınırı; zorunlu hâllerde gerekçeli `EXEMPT` ve raporda ayrı gösterim |
| Z6 | Sahte konum uygulaması | Android `isMocked` reddi; imkânsız hız tespiti; red denemeleri kanıt olarak saklanır |
| Z7 | QR fotoğrafla okutma | Konum zorunluluğu; ayrıca QR yeniden üretilebilir (eski baskı geçersiz) |
| Z8 | Arka planda konum takibi ek izin ve pil yükü getirir; personel konumu kişisel veridir | Yalnız ekran açıkken ve yalnız açık tur boyunca; kesintiler raporda; 1 yıl saklama; aydınlatma metni |
| Z9 | Sensör donanımı yok, gerçek sınama yapılamaz | Sahte cihaz ile uçtan uca sınama; bu açıkça "gerçek donanımla denenmedi" diye yazılır (iyzico ile aynı ilke) |
| Z10 | Yönetici mobilde 117 işlemi tek tek yazmak tutarsızlık doğurur | Önce ortak form/eylem/dosya altyapısı, sonra modüller; panel tablosu kontrol listesi olarak kullanılır; harita aracı mobil kapsamı ölçer (hedef: panelde olup mobilde olmayan yazma işlemi = 0) |
| Z11 | Mobil QR okuma, konum ve panel QR üretimi için paket yok | Yeni bağımlılık kararı **B-1, B-2** (aşağıda) |
| Z12 | Finans migration dondurması | Bu planın hiçbir migration'ı finans tablosuna dokunmaz (073 bildirim+denetim, 074 sensör, 075 devriye) |

## H.11 Uygulama sırası (her aşama ayrı commit; mesaj onaya sunulur)

| Aşama | Kapsam |
|---|---|
| 1 | H.1 kaldırmalar |
| 2 | H.2 + H.3 (073, okundu, işlem kaydı, ayar, ekranlar) |
| 3 | H.4 sensörler (074) |
| 4 | H.5 devriye (075) — B-1/B-2/B-3 kararından sonra |
| 5 | H.6 sakin uygulaması |
| 6 | H.8 panel eklemeleri |
| 7 | H.7 yönetici mobil eşitliği (ortak altyapı → modüller) |
| 8 | Harita + 06 + CLAUDE.md + aydınlatma metni |

Her aşamanın doğrulaması: `go build/vet`, verify-stack (yeni kontrollerle), verify-mobile (yeni widget testleriyle), panel `tsc`/`lint`/`build`/`verify-endpoints`, `dev-up` ile D4 senaryoları.

## Kararlar (2026-10-26, kullanıcı)

- K3 evet (seçenekli), B-1 `mobile_scanner` + `geolocator` evet, B-2 `qrcode` evet, B-3 harita (leaflet / flutter_map, OpenStreetMap) evet.

## Önceki onay listesi (kapandı)

- **K3:** İşletme projesi görüşü (açıklama kullanıcıya verildi).
- **B-1:** Yönetici mobil `mobile_scanner` (QR okuma) + `geolocator` (konum, `isMocked`).
- **B-2:** Panel `qrcode` (yazdırılabilir QR üretimi).
- **B-3 (isteğe bağlı):** Harita gösterimi. Panel `leaflet` + `react-leaflet`, mobil `flutter_map` + `latlong2` (OpenStreetMap). Onaylanmazsa rapor tablo + harita bağlantısıyla yapılır.

---

# FAZ 0 — Dürüstlük Onarımı (aktif)

**İlke:** Sistemin kullanıcıya yalan söylemesini durdur. Yeni özellik yok.
**Neden ilk:** Yanlış rakam gösteren bir mali ekran, hiç göstermeyenden daha zararlıdır.

## 0.A — Admin panel

- [x] **[D2] 0.A.1 🔴 Giriş şifresinin log'a yazılması kaldırıldı**
      `admin/src/app/api/auth/[...nextauth]/route.ts` — `console.log(credentials)` silindi;
      hata ayıklama için yalnızca **maskelenmiş** telefon (`maskPhone`) ve HTTP durumu loglanıyor. *(B16)*
      **Kanıt:** `npm run build` → çıkış kodu 0
- [x] **[D2] 0.A.2 🔴 Sessiz mock fallback'ler kaldırıldı**
      expenses, personnel, parking, reservations, visitors, accounting, notifications, credentials —
      hardcoded veri dizileri silindi; `loadError` + `<ErrorState onRetry>` kalıbına geçildi.
      Özet/istatistik kartları hata durumunda uydurma sayı yerine `—` gösteriyor. *(B79)*
      Ortak bileşen eklendi: `admin/src/components/ui/data-state.tsx`
- [x] **[D2] 0.A.3 🔴 Credentials sayfasındaki uydurma şifre kaldırıldı**
      `"demo-sifre-2026"` silindi; backend'de şifre gösterme ucu olmadığı için özellik dürüstçe
      devre dışı ve nedeni ekranda açıklanıyor. Erişim kaydının yalnızca yerel olduğu belirtiliyor. *(B80)*
- [x] **[D2] 0.A.4 🔴 Sahte "kaydedildi/gönderildi" mesajları kaldırıldı**
      `settings` (kaydetmeden "Kaydedildi"), `notifications` (`catch{}` → gönderilmemişken başarı),
      `reports` (`alert("e-posta gönderildi")`), `accounting` (sahte toplu "hızlı işlem" modalı). *(B81)*
      Bildirim gönderimi artık yalnızca sunucu onayladığında başarı gösteriyor; hata görünür.
- [x] **[D2] 0.A.5 🟠 Sahte soft-delete kaldırıldı**
      Gerçek silme ucu olanlar API'ye bağlandı (`deleteEmployee`, `deleteVehicle`, `cancelReservation`);
      olmayanlar sahte başarı yerine dürüst hata mesajı veriyor. *(B83, B60)*
- [x] **[D2] 0.A.6 🟠 Çıkış (logout) düğmesi eklendi**
      `components/layout/header.tsx` — `signOut({callbackUrl:"/login"})` ile profil menüsünde.
      Ayrıca hardcoded "Ahmet Yılmaz / Yönetim Kurulu Başkanı" kaldırılıp gerçek oturum bilgisi
      (`useSession`) gösteriliyor; çalışmayan arama kutusu ve sahte bildirim rozeti kaldırıldı. *(B91)*
- [x] **[D2] 0.A.9 Doğrulama:** `npm run build` → **çıkış kodu 0** (21 sayfa)
- [x] **[D2] 0.A.7 🟠 Var olmayan uçlar düzeltildi** *(B95)*
      `getFinanceOverview` yayında olmayan `/finance/overview`'a gidiyordu (mobilde);
      gerçek uca (`/finance/assessments/overview`) yönlendirildi. Liste uçlarının yanıt
      biçimi tek sözleşmeye (`{"data": [...]}`) çekildi ve istemciler iki biçime de
      toleranslı hâle getirildi.
- [x] **[D2] 0.A.8 🟡 Ölü kod temizlendi** *(B93)* — `hooks.ts`'teki 17 kancanın
      kullanılmayan **13'ü** silindi. Ölü kod, olmayan bir veri katmanı izlenimi veriyordu.
- [x] **[D2] 0.A.10 🟠 Rol bazlı erişim kontrolü eklendi** *(B28)*
      Panelde HİÇBİR kontrol yoktu; giriş yapan herkes adres çubuğuna yazarak maaş
      bordrosuna ve sistem API anahtarlarına erişebiliyordu.
      `src/lib/rbac.ts` (yol → rol eşlemesi, hukuki gerekçeleriyle) + `middleware.ts`
      sunucu tarafı kontrolü + menü süzme + `/dashboard/forbidden` açıklama sayfası.
      Denetçi mali ekranları okur ama yazamaz (KMK m.41, görevler ayrılığı).
      **Kanıt:** `npx tsc --noEmit`, `npm run lint`, `npm run build` → hepsi temiz.
- [x] **[D2] 0.A.11 Admin panelde kalan uydurma veriler temizlendi**
      Ana sayfa (sabit "124 sakin / ₺45.600 / %87", uydurma 12 aylık grafik, var olmayan
      kişilere ait "son ödemeler"), talepler (yalnızca yerel state'i değiştiren durum
      güncellemesi), sayaçlar (sunucuya hiç istek göndermeyen "Okumaları Kaydet"),
      ayarlar (sahte yöneticiler, iyzico/Firebase/SMTP için yanlış "Bağlı" rozetleri,
      uydurma "Pro Plan ₺299/ay" ve 3 ödenmiş fatura).

## 0.B — Backend (Go)

- [x] **[D2] 0.B.3 🟠 Yutulan hatalar görünür kılındı (kısmi)**
      `pkg/middleware/auth.go` — `_ = audit.LogAction(...)` kaldırıldı, hata loglanıyor;
      `finance/repository/finance.go` — ödeme-tahakkuk bağlantısındaki yok sayılan `err` düzeltildi
      ve tüm akış tek transaction'a alındı. *(KN-2, B59, B47)*
      **Kanıt:** `go build ./...` + `go vet ./...` → 0
- [x] **[D4] 0.B.1 🔴 Kaydetmeyen uçlar `501`'e çevrildi** *(B78, B79, B84)*
      22 mock servisin **tüm** uçları (yalnızca yazma değil — okuma uçları da uydurma veri
      döndürüyordu) artık `501 Not Implemented` döndürüyor. Ortak sözleşme: `pkg/stub`.
      Yanıt gövdesi modül adını, "istek İŞLENMEDİ" uyarısını ve doküman referansını içerir;
      `X-SiteEksen-Not-Implemented: true` başlığı eklenir. Sağlık ucu artık `"healthy"` değil
      `"not_implemented"` der (servis ayakta ama işlevsiz).
      Etkilenen servisler: asset, banking, bulletin, contract, document, energy_analytics, esg,
      expense, inventory, iot, meeting_wizard, notification, nps, package, parking, patrol,
      personnel, reservation, settings, smart_collection, survey, visitor.
      **Kanıt:** `verify-stack.sh` §7 — çalışan servise `GET /api/v1/vehicles` → **501**,
      `POST /api/v1/vehicles` → **501**, başlık mevcut; kaynaklarda uydurma isim taraması → 0 satır.
- [x] **[D4] 0.B.2 🟠 Yanlış sağlık bilgileri (`ai_enabled` vb.) kaldırıldı** *(B84)*
      `energy_analytics`, `smart_collection`, `meeting_wizard` sağlık uçları yapılandırmaya
      bakmadan `ai_enabled: true` diyordu. Bu gövdeler `stub.Health()` ile değiştirildi.
      **Kanıt:** `grep -rn "ai_enabled" services/` → 0 sonuç.
- [x] **[D4] 0.B.4 🟡 Community'nin 4 auth'suz modülü `AuthMiddleware` + `501` arkasına alındı** *(C-1, B78)*
      Duyuru/anket/ilan/rezervasyon uçları **token'sız** POST/PUT/DELETE kabul ediyordu
      (herkes duyuru oluşturup silebilirdi). Tümü `AuthMiddleware` arkasına alındı ve `501` döndürüyor.
      Gerçek DB'ye bağlı `requests` modülü değişmedi. Sağlık ucu hangi modülün kalıcı olduğunu bildiriyor.
      **Kanıt:** `go build`/`go vet` → 0; `verify-stack.sh` 47/47.
- [x] **[D4] 0.B.5 🟠 Kalan yok sayılan `err`'ler giderildi** *(M-2)*
      `esg`/`nps`/`banking`/`parking`/`visitor`'daki yutulan hatalar, ilgili gövdeler
      tamamen kaldırıldığı için ortadan kalktı.
      **Kanıt:** `grep -rn "_ = .*err\|ShouldBindJSON(&req)$" services/ pkg/` → 0 sonuç.

---

# FAZ 1 — Kurulabilirlik (büyük kısmı tamamlandı ve doğrulandı)

**Çıkış ölçütü sağlandı:** Temiz bir makinede veritabanı sıfırdan kurulabiliyor ve demo giriş çalışıyor.
**Toplu kanıt:** `bash backend/scripts/verify-stack.sh` → **42/42 kontrol geçti** (2026-09-12)

- [x] **[D4] 1.1 Migration 004 `expense_categories` çakışması giderildi** *(B01)*
      Tablo yeniden tanımlanmak yerine 001'in tablosuna eksik kolonlar eklendi; böylece finance (001)
      ve expense (004) sözleşmeleri tek tabloda birleşti. Varsayılan kategorilere KMK m.20'ye göre
      `distribution_type` atandı (eşit / arsa payı), hukuki teyit notu düşüldü.
      **Kanıt:** temiz DB'de `004` → OK
- [x] **[D4] 1.2 Migration 005 `vehicles` çakışması giderildi** *(B02)*
      `CREATE TABLE IF NOT EXISTS` yerine idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`;
      `plate_number` NOT NULL kısıtı kaldırıldı, veri `plate` kolonuna taşındı, `property_id`
      birimden türetildi; `idx_vehicles_unit` çakışması `IF NOT EXISTS` ile giderildi.
      **Kanıt:** `005` → OK; **005 sonrası 29 tablo artık oluşuyor** (toplam 61 tablo)
- [x] **[D4] 1.2b Migration 005'teki geçersiz UUID düzeltildi** *(denetimde yakalanmamıştı)*
      `inventory_categories` seed'inde `ic0000...` kimlikleri kullanılıyordu; `i` hex olmadığı için
      `invalid input syntax for type uuid` hatası veriyordu. `1c` prefix'ine çevrildi.
- [x] **[D4] 1.3 006'nın zincir çöküşü giderildi** *(B03)* — 005 tamamlandığı için `reservations` vb.
      tablolar artık mevcut; 006 sorunsuz uygulanıyor.
- [x] **[D4] 1.7 Demo giriş onarıldı** *(B06)*
      Seed'deki bcrypt hash hiçbir şifreyle eşleşmiyordu (fiilen doğrulandı) ve iki kullanıcıda
      aynıydı. Yeni hash'ler `cost=12` ile üretilip doğrulandı. **Giriş: `5551234567` / `Demo123!`**
      **Kanıt:** gerçek identity-service'e `POST /auth/login` → **HTTP 200 + JWT**; yanlış şifre → **401**
- [x] **[D4] 1.9 `go build ./...` onarıldı** *(B04)*
      Ölü `backend/api/` dizini kaldırıldı (kırık import + `X-User-Role` başlığına güvenen sahte
      süper-admin kontrolü). Ayrıca gizli kalmış iki derleme hatası giderildi:
      `pkg/integrations/sms` (kullanılmayan `body`, bakiye hiç parse edilmiyordu) ve
      `pkg/integrations/whatsapp` (tanımsız `MediaContent` tipi).
      **Kanıt:** `go build ./...` → 0, `go vet ./...` → 0
- [x] **[D3] 1.14 Kalıcı doğrulama betiği eklendi** — `backend/scripts/verify-stack.sh` (42 kontrol)

### FAZ 1 — kalanlar
- [x] **[D4] 1.4 Migration'lar tam idempotent yapıldı** *(B08)*
      001'deki 25 `CREATE TABLE` ve 24 `CREATE INDEX`, 003/005'teki 91 index ifadesi
      `IF NOT EXISTS` aldı; 004'teki `CREATE TRIGGER` öncesine `DROP TRIGGER IF EXISTS`
      eklendi; `002` tümüyle koruma altına alındı. Her migration artık transaction içinde
      uygulanıyor (çalıştırıcı sarmalıyor).
      **Kanıt:** `verify-stack.sh` §4b — **11 migration dosyasının tamamı** temiz kurulumdan
      sonra yeniden uygulandığında hatasız geçiyor.
- [x] **[D4] 1.5 🔴 Migration çalıştırıcı eklendi** *(B05)* — `backend/cmd/migrate`
      `schema_migrations` sürüm tablosu, PostgreSQL **advisory lock** (eşzamanlı çalıştırma
      koruması), **SHA-256 sağlama denetimi** (uygulanmış bir migration sonradan
      değiştirilmişse durur) ve migration başına transaction. `-status`, `-dry-run` bayrakları.
      Docker imajı: `backend/cmd/migrate/Dockerfile`.
      **Kanıt:** `verify-stack.sh` §2 (11 migration uygulandı, `schema_migrations` 11 kayıt) ve
      §4a (ikinci çağrıda hiçbir şey uygulamıyor). Sağlama koruması fiilen sınandı: kayıtlı
      sağlama bozulduğunda çalıştırıcı hata verip **çıkış kodu 1** döndürdü.
- [x] **[D4] 1.7b Seed `initdb.d` dışına taşındı** — `docker-compose.yml`'deki
      `./backend/migrations:/docker-entrypoint-initdb.d` mount'u kaldırıldı; migration'ları
      artık tek seferlik `migrate` servisi uyguluyor ve tüm servisler onun **başarıyla
      tamamlanmasını** bekliyor (`service_completed_successfully`).
      Demo veri `SEED_DEMO_DATA` ile kontrol ediliyor: üretimde `false` verildiğinde
      migration uygulanmış sayılır (sürüm zinciri kırılmaz) ama **bilinen şifreli demo
      hesaplar açılmaz**.
- [x] **[D4] 1.8 Seed verisi tutarlı hâle getirildi** *(B15)*
      `total_units=24` deniyordu ama 6 birim vardı; `total_share_ratio=10000` iken birimlerin
      arsa payı toplamı 2480'di. Bu tutarsızlık **arsa payına göre dağıtımı (KMK m.20/1-b)
      test edilemez** kılıyordu: payda yanlış olduğu için her tahakkuk hatalı çıkardı.
      Artık 2 blok × 12 = **24 bağımsız bölüm** var ve arsa payları **tam 10000** ediyor.
      Gider kalemlerinin dağıtım türleri de KMK m.20'ye göre düzeltildi.
      **Kanıt:** `verify-stack.sh` §4d — SQL ile `total_units` ve arsa payı toplamı doğrulanıyor.
- [x] **[D4] 1.10 Servis varsayılan portları eşitlendi** *(B13)*
      13 servisin `main.go` varsayılanı compose/gateway tablosundan farklıydı ve 4 çift aynı
      varsayılan porta sahipti (document/parking, banking/esg, nps/package,
      energy_analytics/settings) → local'de ikisi birden çalıştırılamıyordu.
      Kanonik tablo: gateway yönlendirmesi + docker-compose. Fark **0**.
- [x] **[D4] 1.11 `firebase-credentials.json` mount'u kaldırıldı** *(B07)*
      Dosya depoda yok; Docker eksik yolu **dizin** olarak yaratıp `docker-compose up`'ı
      kırıyordu. Firebase zaten koda hiç bağlı değil (denetim bulgusu).
      **Kanıt:** `docker compose config` → çıkış kodu 0.
- [x] **[D4] 1.12 CI gerçek kapı hâline getirildi** *(B09, B10, B11)*
      Go sürümü `1.21` → **1.24** (`go.mod` ile aynı); `go build ./...`, `go vet ./...`,
      `gofmt` denetimi ve `go test -race ./...` eklendi; admin'de `|| true` kaldırıldı
      (`npm run lint`, `tsc --noEmit`, `npm run build`); Trivy artık `exit-code: 1` ile **kapı**
      ve ayrıca **sır taraması** yapıyor; mobil için iki uygulama da matris olarak
      `flutter analyze`/`flutter test` çalıştırıyor; yeni **verify-stack** işi tüm uçtan uca
      doğrulamayı CI'da koşuyor. Dağıtım işi secret yoksa sessizce "başarılı" görünmüyor.
      **Kanıt:** aynı komutlar local'de çalıştırıldı — `gofmt -l` boş, `go test ./...` 6/6 paket
      geçti, `npm run build` 0, `flutter analyze`/`flutter test` her iki uygulamada 0.
- [x] **[D4] 1.13 `003`'ün `audit_logs` DROP'u kaldırıldı** *(B14)*
      `DROP TABLE IF EXISTS audit_logs;` migration her tekrarlandığında **KVKK kapsamındaki
      tüm denetim izini siliyordu**. Artık tablo düşürülmüyor; eksik kolonlar idempotent
      `ALTER` ile ekleniyor. `011` ayrıca 001'den kalan eski kolonları (`user_ip`,
      `resource_type NOT NULL`, `resource_id`) veriyi taşıyarak tasfiye ediyor ve
      `created_at`'i `TIMESTAMPTZ`'ye çeviriyor.
      **Kanıt:** `verify-stack.sh` §4c — tabloya kayıt atılıp 003 yeniden uygulanıyor, kayıt
      hâlâ orada.
- [x] **[D2] 1.6 Geri alma (2026-09-27)** — `down` betiği BİLEREK yazılmadı (denetim izi/defterleri silerdi); geri alma = yedekten geri yükleme: `backend/scripts/db-backup.sh` / `db-restore.sh`, yordam `docs/runbook-veritabani-geri-alma.md`. **Kanıt:** `verify-stack.sh` adım 41 (yıkıcı migration taklidi → geri yükleme → birebir).

### Flutter doğrulaması — AÇILDI (2026-09-13)
- [x] **[D4] Flutter 3.47.4 WSL'e kuruldu** *(S-01b)* → mobil işler artık `[D1]` değil,
      çalıştırılarak doğrulanabiliyor.
- [x] **[D4] İki uygulamanın da derlenmeyen `widget_test.dart`'ı düzeltildi**
      Her ikisi de `flutter create` şablonundan kalan, var olmayan `MyApp` sınıfını çağıran
      sayaç testiydi → `flutter analyze` **hata** veriyordu ve çalıştırılabilir tek test yoktu.
      Gerçek duman testleriyle değiştirildi (2+2 test).
- [x] **[D4] Mobilde ölü kod ve kullanılmayan import'lar temizlendi**
      Rotaya hiç bağlı olmayan `home_screen.dart` silindi: sabit "Ahmet Yılmaz", sabit
      **"Borcunuz Bulunmamaktadır"** kartı, uydurma tüketim grafiği ve uydurma kampanyalar
      içeriyordu. 13 kullanılmayan import/alan kaldırıldı.
      **Kanıt:** `bash backend/scripts/verify-mobile.sh` → her iki uygulamada
      `flutter analyze` **hata/uyarı yok**, `flutter test` geçiyor.
- [x] **[D3] Mobil doğrulama betiği eklendi** — `backend/scripts/verify-mobile.sh`

---

# FAZ 2 — Kimlik, yetki, izolasyon (başladı)

- [x] **[D4] 2.1 🔴 Gateway'e kimlik doğrulaması eklendi** *(B17, B18)*
      **Sorun:** `cmd/gateway` 25 servise yönlendiriyor ama **hiçbir jeton doğrulaması
      yapmıyordu**; Kong'da da kimlik eklentisi yoktu. Maaş, TCKN, IBAN ve **API anahtarları**
      token'sız erişilebiliyordu.
      **Çözüm:**
      - `pkg/authtoken` — jeton doğrulamanın tek kaynağı (çatıdan bağımsız). `pkg/middleware`
        de artık bunu kullanıyor; mantık iki yerde çoğaltılmıyor.
      - Gateway: `/api/v1/auth/*` ve `/health` dışındaki her yol geçerli JWT ister; `JWT_SECRET`
        yoksa **fail-closed** (500).
      - Gateway istemciden gelen `X-User-Id`, `X-User-Role`, `X-Property-Id`, `X-Tenant-Id`
        gibi kimlik başlıklarını **siliyor** (aşağı akışta kimlik sahteciliği engellendi).
      - CORS artık joker `*` değil, `CORS_ALLOWED_ORIGINS` allowlist'i.
      - Her isteğe `X-Request-Id` veriliyor (denetim izi ilişkilendirmesi — FAZ 3.5).
      - `kong/kong.yml`: `/api/v1/auth` dışındaki **24 rotada** `jwt` eklentisi; consumer anahtarı
        Kong env vault'tan (`{vault://env/jwt-secret}`) okunuyor; CORS joker kökenleri kaldırıldı.
      - `identity`: jetonlara Kong'un beklediği `iss: "siteeksen"` claim'i eklendi.
      **Kanıt:** `go test ./pkg/authtoken/...` → 6/6 geçti (alg=none, yanlış anahtar, süresi dolmuş,
      anahtar yok senaryoları dahil). `verify-stack.sh` §8: gateway üzerinden token'sız `/users/me`
      → **401**, geçersiz jeton → **401**, `/auth/login` → **200**, geçerli jetonla `/users/me` → **200**.
- [x] **[D4] 2.2 🔴 Gateway'deki uydurma mali rapor üretimi kaldırıldı** *(B87)*
      `/api/v1/reports/generate` içi tamamen sabit (uydurma daire, sakin adı ve tutarlar) olan
      **indirilebilir PDF/Excel** üretiyordu. Gerçek mali veriye bağlanana kadar `501` döner.
      Gerçek rapor üretimi finance-service içinde yapılacaktır (FAZ 4/6).
      **Kanıt:** `verify-stack.sh` §8 → `POST /api/v1/reports/generate` → **501**.
- [x] **[D4] 2.3 🟠 Dashboard özetindeki uydurma sayılar kaldırıldı** *(B79)*
      `/dashboard/stats` kaynaklara ulaşamazsa `156 sakin / 245.000 TL gelir / %94 tahsilat`
      sabitlerini döndürüyordu. Artık ulaşılamayan kaynak için **alan hiç dönmez** ve
      `unavailable[]` listesinde nedeniyle bildirilir (`partial: true`).
      `recent-payments` sessizce boş liste döndürmek yerine `502` veriyor (boş liste "ödeme yok"
      anlamına gelir — bu yanlış bilgidir).
- [x] **[D4] 2.4 🔴 `POST /users/me/active-property` sahiplik doğrulaması** *(B21)*
      Gelen `property_id` HİÇ doğrulanmıyordu. JWT'deki `property_id` tüm izolasyonun tek
      dayanağı olduğu için, herhangi bir kullanıcı tek istekle **başka bir sitenin verisine**
      geçebiliyordu. Artık `resident_units` üzerinden aktif bağ aranıyor; yoksa **403**
      (400 değil — bu bir yetki ihlalidir ve denetim izinde `DENIED` olarak ayrışır).
      **Kanıt:** yabancı siteye geçiş → **403**, kendi sitesine → **200**.
- [x] **[D4] 2.5 🔴 Roller siteye göre kapsamlandı** *(B22)*
      `users.roles` global olduğu için bir sitede MANAGER olan kişi **tüm sitelerde**
      yöneticiydi — çok kiracılı bir SaaS'ta doğrudan izolasyon ihlali.
      `migrations/013` ile `property_roles` tablosu (atama izi, geçerlilik dönemi, karar
      referansı — KMK m.34 yönetici genel kurul kararıyla atanır).
      Jeton rolleri aktif siteye göre üç kaynaktan birleştiriliyor: `property_roles`
      (yönetim) + `resident_units` (sakinlik) + `users.roles` (yalnız platform rolleri).
      Rol çözümlemesi başarısızsa jeton **üretilmiyor** (boş rolle devam etmek, yetki
      kontrollerini sessizce atlatan bir jeton üretmek demektir).
      **Kanıt:** kiracı jetonunda MANAGER **yok**, TENANT var; yönetici jetonunda MANAGER var.
- [x] **[D4] 2.9 🟠 Rol bazlı erişim kontrolü — sunucu ve panel** *(B28)*
      Sunucu: finance ve governance servislerinde `RequireRole`. Site geneli borçlu/ödeme
      listeleri ve tahakkuk oluşturma yalnızca yönetime açık; **denetçi okur, yazamaz**
      (KMK m.41 görevler ayrılığı).
      Panel: `src/lib/rbac.ts` + `middleware.ts` + menü süzme (bkz. 0.A.10).
      **Kanıt:** yönetici `/finance/debtors` → 200, kiracı → **403**; yetkisiz deneme
      denetim izine `DENIED` olarak yazıldı.
- [x] **[D4] 2.6 🔴 Tenant izolasyonu (PostgreSQL RLS)** — **TAMAMLANDI (2026-09-26).**
      81 tabloda RLS (migration 020-026); 26 servisin tamamı `pkg/dbscope` kullanıyor.
      Kimlik servisi ayrı rol (`siteeksen_identity`), uygulama rolü en az yetkiyle.
      RLS dışında kalan 8 tablo gerekçeli ve doğrulama listeyi birebir denetliyor.
      Geçiş sırasında bulunan ve kapatılan açıklar: talep durumu (başka sitenin talebi
      ilerletilebiliyordu), ödeme (başka sitenin tahakkuku bağlanabiliyordu), bütçe
      itirazı (başka site sonuçlandırabiliyordu; kiracı/başkasının dairesi adına itiraz),
      karar defteri (başka site yazabiliyordu), görünümler (RLS'i atlıyordu).
      **Kanıt:** `verify-stack.sh` §32-36 — uçtan uca çapraz site testleri dahil.
- [x] **[D4] 2.7 🟠 Çıkışta jeton iptali** — `revoked_tokens` + toplu iptal (§30).
      Uygulama rolü iptal kaydını artık silemez (migration 025).
- [x] **[D4] 2.8 🟠 Hassas alanların şifrelenmesi** — TCKN/IBAN AES-256-GCM + blind index (§31).

---

# FAZ 3 — Denetim izi (ilk madde tamamlandı)

- [x] **[D4] 3.1 🔴 Denetim izi çalışır hale getirildi** *(B59)*
      **Sorun:** `pkg/audit` şemada olmayan kolonlara (`user_ip`, `resource_type`, `resource_id`)
      yazıyordu; INSERT her çağrıda `42703` hatası veriyor, hata `_ =` ile yutuluyor ve
      `audit_logs` tablosu kalıcı olarak boş kalıyordu — `legal/kvkk-aydinlatma.md`'deki
      "log tutuyoruz" taahhüdü karşılıksızdı.
      **Çözüm:** Migration `011` (şema ↔ kod uyumu, `property_id`/`request_id`/`status_code` eklendi,
      `tenant_id` zorunluluğu kaldırıldı) + `pkg/audit` yeniden yazıldı (tipli `Entry`) +
      `pkg/middleware` hatayı loglar hale getirildi, 403'ler `DENIED` olarak ayrıştırıldı,
      401'ler gürültü olmasın diye yazılmıyor.
      **Kanıt:** `go test ./pkg/audit/...` gerçek veritabanına karşı **2/2 geçti**;
      uçtan uca istekte `audit_logs`'a kayıt yazıldığı doğrulandı.
- [x] **[D3] 3.2 `old_values`/`new_values` alanları yazılabilir hale geldi** (tipli `Entry` ile)
- [x] **[D4] 3.4 Hassas veri okuma logu (2026-10-03)** — her korumalı GET `VIEW` olarak
      (kullanıcı, site, kayıt kimliği, durum kodu) yazılıyordu ama hiç sınanmamıştı; reddedilen
      okuma `DENIED`, maskesiz TCKN/IBAN ayrıca `PII_REVEAL`, belge `document_access_logs`.
      Sır gösterme ucu yok (kimlik bilgisi modülü 501). **Sınır:** liste okumalarında tek tek
      kayıt kimlikleri yazılmaz (kim, ne zaman, hangi liste yazılır).
      **Kanıt:** `verify-stack.sh` §31 → personel kaydı okuması (maaş), sakin listesi (telefon/e-posta)
      ve sakinin reddedilen denemesi denetim izinde; 1019/1019.
- [x] **[D4] 3.5 Yapılandırılmış log + istek kimliği (2026-09-26)** — 26 servis + gateway JSON günlük
      (`middleware.NewRouter`: request_id, route şablonu, status, süre, kullanıcı, site; ham yol/sorgu
      YAZILMAZ). İstemci `X-Request-Id`'si doğrulanır: 64 karakteri aşan değer denetim kaydını
      düşürüyordu (denetimden kaçma) — kapatıldı. **Kanıt:** `verify-stack.sh` §37-D3.

---

# FAZ 4 — Para doğruluğu (ilk düzeltmeler yapıldı)

- [x] **[D2] 4.1 🔴 `GetUnitBalance` kartezyen join'i düzeltildi** *(B45)*
      `JOIN users u ON ll.unit_id = (...)` koşulu `u`'ya referans vermediği için CROSS JOIN'di;
      bakiye **kullanıcı sayısıyla çarpılıyordu** (156 sakinli sitede 1.200 TL borç → 187.200 TL).
      Hesap artık 001'de tanımlı ve doğru yazılmış `unit_balances` view'ı üzerinden, sakinin
      **tüm** aktif bağımsız bölümlerini kapsayacak şekilde yapılıyor.
      **Kanıt:** `go build`/`go vet` → 0. *(Sayısal doğruluk testi FAZ 4.12'de yazılacak.)*
- [x] **[D2] 4.2b Ödeme kaydı tek transaction'a alındı + IDOR kapatıldı** *(B47, B24, B53)*
      Sahiplik doğrulaması (`resident_units` join + `FOR UPDATE`), `deleted = 0` filtresi,
      `payment_assessments.amount` yazımı, `payments.unit_id` doldurulması, hata yutmanın
      kaldırılması. Sahte `checkout.siteeksen.com` adresi kaldırıldı; yanıta
      `payment_gateway_ready: false` eklendi.
- [x] **[D2] 4.6b Ham veritabanı hatalarının istemciye sızması engellendi** (ödeme ucu) *(B37)*
- [x] **[D4] 4.2 `paid_amount` güncellemesi — ödeme onay akışı** *(B46)*
      Ödeme kaydı oluşuyor ama `paid_amount` HİÇ güncellenmiyordu; ödemesini yapan sakin
      **sonsuza dek borçlu** kalıyor, borçlu listesinden düşmüyordu.
      Ödeme sağlayıcısı yok (S-06) ama Türkiye'de aidatların büyük kısmı havale/EFT ile
      tahsil ediliyor; **yönetici onayı** gerçek bir iş akışıdır ve sağlayıcı geldiğinde
      aynı repository çağrısı webhook'tan kullanılabilir.
      Tek transaction, `FOR UPDATE`, yalnızca `PENDING` onaylanabilir, başka siteye ait
      ödeme 403, `RejectPayment` ile borç değişmeden reddetme.
      **Kanıt:** onay öncesi borç değişmiyor; sonrasında `0,00 → 1.200,00` ve `PAID`;
      çift onay → **409**; `has_debt:false`.
- [x] **[D4] 4.3 Para tipi kuruşa çevrildi** *(B50)* — `pkg/money`: `Kurus` (int64),
      `FromTRY`/`TRY`, decimal tabanlı dönüşüm. Yeni yazılan tüm para kodu (işletme projesi
      dağıtımı, gecikme tazminatı, icra takibi tutarları) kuruş kullanıyor.
      **Kanıt:** `go test ./pkg/money/...` — float sapması testi dahil 9 test.
- [x] **[D4] 4.4 Kuruş yuvarlama + kalan dağıtımı** *(B51)* — **en büyük kalan**
      (largest remainder) yöntemi: tüm paylar aşağı yuvarlanır, artan kuruşlar en büyük
      kesirli kalana sahip paylara birer birer dağıtılır. Payların toplamı tutara
      **birebir** eşittir ve dağıtım **belirlenimcidir** (aynı girdi → aynı çıktı; yeniden
      hesaplamada daireler arasında kuruş yer değiştirmez).
      **Kanıt:** 2000 rastgele senaryoda kuruş kaybı yok; `verify-stack.sh` §11'de gerçek
      işletme projesinde 33.600.000 kuruş birebir tutuyor.
- [x] **[D4] 4.5 Gecikme tazminatı tahakkuku (KMK m.20/2)** — hiç hesaplanmıyordu.
      `POST /finance/late-fees/accrue`; oran mevzuat tablosundan; anapara = ödenmemiş
      **asıl** borç (tazminat üzerinden tazminat işlenmez); **idempotent** (yeniden yazılır,
      eklenmez); `late_fee_accruals` tablosuna gün/oran/anapara izi.
      **Kanıt:** 30 gün → **60,00 TL**, toplam **1.260,00 TL**, ikinci çalıştırmada değişmiyor.
- [x] **[D4] 4.12 Bakiye için sayısal doğruluk testi (2026-10-03)** — test yazılınca asıl hata
      çıktı: `unit_balances` hiç yazılmayan `ledger_lines`'tan okuyordu; sakinin
      `/finance/debt-status`'u borcu ne olursa olsun **0 / has_debt:false** diyordu (mobil "borç yok").
      Eski "ödeme sonrası has_debt:false" kontrolü ödemeden önce de geçerdi. Migration 030 görünümü
      tahakkuklara bağladı (panel borçlu listesiyle aynı kaynak).
      **Kanıt:** `verify-stack.sh` §10 → API bakiyesi bağımsız SQL toplamına birebir eşit (1200.00),
      onaydan sonra tam 1.200,00 düşüyor (→ 0.00); 1016/1016.
- [x] **[D4] B69 (2026-10-04):** ödeme listeleri sayfalı; yoğun 6 listede kesilme `truncated` ile bildiriliyor. Duyuru, anket, anket yorumu, sayaç ve sayaç okuması da aynı kalıpta.
- [x] **[D4] 4.13 (2026-10-04, kapsam kararı):** Go içindeki son kayan nokta para toplamı (ödeme oluşturma: tahakkuk kalanlarının float64 toplamı) decimal'e çevrildi; gider ortalaması kuruşa yuvarlanıyor. Şema `DECIMAL` kalır (kesin); JSON taşıma `number` olarak kalır — iki ondalıklı değer taşınırken bozulmaz, aritmetik yalnızca `pkg/money`/decimal ile yapılır. Kanıt: verify-stack "ödeme tutarı = bağlı tahakkukların toplamı". Eski not:
      **4.13 Mevcut `float64` para alanlarının kuruşa göçü** (not 2026-10-03: tahakkuk dağıtımı kuruşa geçti; kalan float alanlar yalnızca DECIMAL değerlerin taşınması/gösterimi) — yeni kod kuruş kullanıyor,
      `monthly_assessments`/`payments` tablolarındaki `DECIMAL` alanlar korunuyor.
      Tam göç ayrı bir migration ve istemci uyumu gerektirir.

## 0.C — Mobil (Flutter) — tamamlandı

> Flutter 3.47.4 WSL'e kuruldu; bu bölümdeki maddeler artık `[D1]` değil, çalıştırılarak
> doğrulanmıştır. **Toplu kanıt:** `bash backend/scripts/verify-mobile.sh` → 8/8.

- [x] **[D4] 0.C.1 🔴 Sahte ödeme ekranı gerçek API'ye bağlandı** *(B49)*
      Borç koda gömülüydü (₺1.250) ve "Öde → Onayla" **hiç ağ çağrısı yapmadan**
      "Ödeme Başarılı!" diyordu. Artık `/finance/debt-status` + `/finance/assessments`;
      ödeme isteği gerçekten gönderiliyor; `payment_gateway_ready:false` iken tahsilatın
      YAPILMADIĞI açıkça söyleniyor.
- [x] **[D4] 0.C.2 🔴 Sahte başarı mesajları kaldırıldı** *(B81)*
      Sakin: talep oluşturma (gerçek `createRequest`'e bağlandı, uydurma takip numarası
      kaldırıldı), ziyaretçi ön kaydı ("SMS gönderildi" yalanı kaldırıldı), belge yükleme.
      Yönetici: tahakkuk, sayaç, duyuru, gider, rapor ekranları.
- [x] **[D4] 0.C.3 🟠 Sessiz boş-listeye düşme kaldırıldı** *(B82)*
      Ortak bileşenler: `core/widgets/data_state.dart` — `LoadingView`, `ErrorStateView`
      (yeniden dene), `EmptyStateView`, `NotImplementedNotice`, `toUserMessage`.
      "Veri yok" ile "veri alınamadı" artık ayrı gösteriliyor.
- [x] **[D4] 0.C.4 🟠 Ölü rotalar ve boş `onTap`'lar giderildi** *(B89, B90)*
      Sakin uygulamasında rotaya bağlı olmayan `home_screen.dart` silindi (sabit
      "Borcunuz Bulunmamaktadır" kartı içeriyordu); "Daha Fazla" menüsündeki 10 boş
      `onTap` gerçek rotalara bağlandı; çalışmayan "Çıkış Yap" düzeltildi.
- [x] **[D4] 0.C.5 🟠 Yanlış güvence metni kaldırıldı** *(B85)*
      `api_settings_screen` "şifrelenmiş saklanır, her değişiklik kayıt altındadır" derken
      ekranın tamamı mock'tu ve 7 entegrasyon "aktif" görünüyordu. Gerçek duruma çevrildi.
- [x] **[D4] 0.C.6 `flutter analyze` bilgi (info) uyarıları sıfırlandı (2026-10-03)** — kalan 63
      uyarı (`prefer_const`, `withOpacity`, `Matrix4.scale`, `Radio.groupValue` → `RadioGroup`)
      giderildi; info düzeyi artık verify-mobile ve CI'da KAPI (`--no-fatal-infos` kaldırıldı).
      **Kanıt:** `verify-mobile.sh` → 8/8, iki uygulamada "hata/uyarı/bilgi yok".

## 0.D — Hukuki metinler — tamamlandı

- [x] **[D2] 0.D.1 🟡 Doğrulanamayan taahhütler düzeltildi** *(B86)*
      Güvenlik bölümü yeniden yazıldı: "AES-256", "TLS 1.3", "günlük yedekleme",
      "periyodik sızma testi" sağlanıyormuş gibi sayılıyordu; hiçbiri uygulanmıyordu.
      Artık **uygulanan** ve **uygulanmayan** tedbirler ayrı listelendi.
      Eksik zorunlu unsur **"toplama yöntemi ve hukuki sebep"** (KVKK m.10) eklendi;
      her işleme konusu için hukuki sebep (m.5/m.6) ve KMK/İİK dayanağı tabloya işlendi.
- [x] **[D2] 0.D.2 🟡 Placeholder alanlar işaretlendi** — üç metnin başına
      "TASLAK — yayına hazır değil" uyarısı kondu; doldurulmamış alanlar ve hukuk onayı
      eksikliği açıkça belirtildi.

## FAZ 0 çıkış ölçütü

Arayüzde gerçekten yapılmayan hiçbir işlem için başarı mesajı yok; hiçbir ekran uydurma veri göstermiyor;
kalıcı olmayan hiçbir uç nokta `2xx` dönmüyor.

---

# FAZ 6 — Yönetişim katmanı (KMK) — çekirdek tamamlandı

Yeni servis: `backend/services/governance` (port 8107). 22 mock servisin aksine **baştan**
gerçek veri katmanına bağlı yazıldı. Şema: `migrations/014`.

- [x] **[D4] 6.1 İşletme projesi / yıllık bütçe (KMK m.37)**
      Kalem bazlı bütçe; her bağımsız bölüme düşen pay `pkg/money` ile **kuruş** üzerinden
      ve en büyük kalan yöntemiyle, kalem dökümüyle birlikte hesaplanıyor.
      Tebliğ → **7 günlük** itiraz süresi (mevzuat tablosundan) → kesinleşme.
      Kesinleşen proje **İİK m.68** anlamında belge olarak işaretleniyor.
      Tebliğ edilmeden ya da süre dolmadan kesinleştirme **409** ile reddediliyor;
      açık itiraz varsa kesinleşme engelleniyor.
      **Kanıt:** 336.000 TL'lik projede payların toplamı **33.600.000 kuruş** (birebir);
      eşit dağıtılan kalemde daireler arası fark ≤ 1 kuruş.
- [x] **[D4] 6.2 Kat malikleri kurulu / genel kurul (KMK m.29-33)**
      Çağrı **15 günden** geç yapılırsa işlem reddediliyor (geç çağrı, kararı iptal
      edilebilir kılar). Nisap **sayı VE arsa payı** bakımından ayrı ayrı; "yarıdan fazla"
      tam yarıyı kapsamıyor. İkinci toplantıda yeter sayı aranmıyor (m.30/3).
      Vekâlet sınırları uygulanıyor (m.31: toplam oyun %5'i; 40 ve altı BB'de kişi başı 2).
      Özel nisaplarda payda **tüm kat malikleri**, olağan kararda ikinci toplantıda
      **katılanlar**. 4/5, oybirliği ve salt çoğunluk ayrı ayrı hesaplanıyor.
      **Kanıt:** 14 birim testi + `verify-stack.sh` §11 (12/24 katılımda nisap yok,
      13/24'te var).
- [x] **[D4] 6.3 Defterler (KMK m.32, m.36)**
      Karar ve işletme defteri; kayıtlar **ekle-only** ve **SHA-256 hash zincirli**.
      UPDATE/DELETE veritabanı tetikleyicisiyle engelli; `/verify` ucu zinciri baştan sona
      doğruluyor. Notere kapatma süresi (1 ay) aşılırsa uyarı döndürülüyor.
      **Kanıt:** zincir doğrulaması geçti; doğrudan SQL ile `UPDATE` denemesi reddedildi.
- [x] **[D3] 6.4 İcra / dava / kanuni ipotek (KMK m.22, İİK m.68)**
      Takip kaydı, olay geçmişi; borç tutarı tahakkuklardan hesaplanıyor (elle girilmiyor);
      dayanak belge belirtilmezse uyarı veriliyor.
- [x] **[D3] 6.5 Yönetici/denetçi görev dönemleri, yıllık hesap verme (m.39), denetim
      tutanakları (m.41)** — şema hazır (`governing_terms`, `accountability_reports`,
      `audit_reports`); uçlar sonraki turda.
- [x] **[D4] 6.6 Genel kurul kararı → karar defteri otomatik bağlantısı (2026-09-26)**
      Gündem maddesi sonuçlandığında karar (kabul ya da red) AYNI TRANSACTION'da toplantı
      yılının karar defterine yazılır: oy dağılımı, nisap gerekçesi, kaynak = gündem maddesi.
      Defter kapalıysa karar da yazılmaz (madde PENDING kalır; yarım işlem yok).
      **Kanıt:** `verify-stack.sh` §37-G — tek kayıt, zincir geçerli, kapalı defterde 409.
- [x] **6.7 Panel arayüzleri** — işletme projesi, genel kurul, defterler, icra ekranları
      (2026-09-26, `8d9528d`). Mobil kaldı.

---

# Sıradaki fazlar (özet)

Ayrıntı: `tasks/roadmap.md`

| Faz | Kapsam | Durum (2026-09-13) |
|---|---|---|
| FAZ 0 | Dürüstlük onarımı | **Tamamlandı** — uydurma veri ve sahte başarı mesajı kalmadı |
| FAZ 1 | Kurulabilirlik — migration çalıştırıcı, idempotency, portlar, CI | **Tamamlandı** (1.6: geri alma yedekten geri yükleme ile, 2026-09-27) |
| FAZ 2 | Kimlik/yetki/izolasyon | **Tamamlandı (2026-09-14)** — gateway auth, site bazlı roller, sahiplik doğrulaması, RBAC, **jeton iptali (2.7)**, **TCKN/IBAN şifrelemesi (2.8)**, **RLS birinci dilimi (2.6)**. RLS kalan tablolara servis servis genişletilecek |
| FAZ 3 | Denetim izi + gözlemlenebilirlik | **Tamamlandı (2026-10-03).** Okuma kaydı (3.4) ve yapılandırılmış log (3.5) uçtan uca sınanıyor |
| FAZ 4 | Para doğruluğu | **Çekirdek tamam** — ödeme borçtan düşüyor, kuruş dağıtımı, gecikme tazminatı. Kalan: bakiye testi (4.12), tam kuruş göçü (4.13) |
| FAZ 5 | 22 mock servisi gerçeğe çevirme | **TAMAMLANDI (2026-09-14)** — 20 servis gerçek veri katmanında; 2 servis (banka, toplantı sihirbazı) gerekçeli kapsam kararıyla 501 |
| FAZ 6 | Yönetişim katmanı (KMK) | **Çekirdek tamam** — işletme projesi, genel kurul, defterler, icra. Kalan: arayüzler (6.7) |
| FAZ 7 | Uyum ve operasyonel derinlik | Başlamadı |
| FAZ 8 | Ölçek ve ticarileşme | Başlamadı |

---

# Karar bekleyen bloklayıcılar — KALMADI

`tasks/questions.md`'deki **18 sorunun tamamı 2026-09-13'te yanıtlandı** ve yanıtlar
uygulandı. Bloklayıcı yok; kalan işler yalnızca iş gücü meselesi.

Uygulanan kararların özeti:

| # | Karar | Uygulanma |
|---|---|---|
| S-01 / S-01b | WSL kullan, ne gerekiyorsa kur | Go 1.24.7 + Flutter 3.47.4 kuruldu |
| S-02 | Finans şeması dondurması **iptal** | 012/013/014 migration'ları yazıldı |
| S-03 | 22 mock servisin **hepsini tamamla** | **8/22 tamamlandı** (2026-09-13); kalan 14'ü dürüstçe 501 |
| S-04 | Her iki KVKK modelini de destekle | Veri modeli site bazlı; hukuki metin taslak işaretli |
| S-05 | Mevzuatı araştır, parametre yap | `legal_parameters` + `pkg/legalparams` (26 parametre) |
| S-06 | Sağlayıcıdan bağımsız ödeme arayüzü | `payment_gateway_ready:false` + yönetici onay akışı |
| S-07 / S-08 | Banka ve e-fatura **sonraki sürüme** | Yapılmadı (karar gereği) |
| S-09 | Oracle/Cloudflare/AWS uyumlu depolama | **Tamamlandı** — `pkg/storage` (local + S3/SigV4, harici bağımlılık yok) |
| S-10 / S-11 | Sağlayıcı bağımsız bildirim + AI yalnız backend | **Yapılmadı** — sıradaki iş |
| S-12…S-16 | Varsayılanları uygula | Veri modeli çok siteli; blok bazlı gider destekli |
| S-17 | Her madde sonrası commit, bölüm sonunda push | Uygulanıyor — **push kimlik bilgisi gerekiyor** |
| S-18 | Kök `ROADMAP.md`/`CHANGELOG.md` işaretçi olsun | Uygulandı |

---

# FAZ 5 — modül dönüşüm durumu (S-03: "hepsini tamamla")

Her modül için ölçüt: gerçek veri katmanı + RBAC + KVKK sınırı + `verify-stack.sh`
içinde kendi adımı. Bir modül baştan sona bitmeden diğerine geçilmez (dikey dilim).

| # | Modül | Durum | Doğrulama adımı |
|---|---|---|---|
| 1 | gider (expense) | **Tamamlandı** | §12 |
| 2 | personel | **Tamamlandı** | §13 |
| 3 | ziyaretçi | **Tamamlandı** | §14 |
| 4 | otopark | **Tamamlandı** | §15 |
| 5 | rezervasyon | **Tamamlandı** | §16 |
| 6 | kargo (package) | **Tamamlandı** | §17 |
| 7 | sözleşme | **Tamamlandı** | §18 |
| 8 | belge arşivi | **Tamamlandı** | §19 |
| 9 | demirbaş (asset) | **Tamamlandı** | §20 |
| 10 | stok (inventory) | **Tamamlandı** | §21 |
| 11 | anket (survey) | **Tamamlandı** | §22 |
| 12 | sayaç/IoT + ısı payı | **Tamamlandı** | §23 |
| 13 | bildirim (notification) | **Tamamlandı** (S-10) | §24 |
| 14 | devriye (patrol) | **Tamamlandı** | §25 |
| 15 | duyuru + ilan panosu | **Tamamlandı** | §26 |
| 16 | ayarlar (settings) | **Tamamlandı** | §27 |
| 17 | enerji analitiği | **Tamamlandı** (YZ yok) | §28 |
| 18 | akıllı tahsilat | **Tamamlandı** (YZ yok) | §28 |
| 19 | NPS | **Tamamlandı** | §29 |
| 20 | ESG / karbon | **Tamamlandı** (katsayı kullanıcıdan) | §29 |
| 21 | banka (banking) | **Yazılmadı — S-07 kullanıcı kararı**; 501 + gerekçe | §29 |
| 22 | toplantı sihirbazı | **Yazılmadı — governance ile tekrar**; yönlendirir | §29 |

### Bu fazda bilerek YAPILMAYANLAR (gerekçeli)

| Konu | Neden |
|---|---|
| Banka entegrasyonu | S-07: kullanıcı sonraki sürüme bıraktı. Ayrıca API sözleşmesi ve alan şifrelemesi (2.8) yok; yanlış eşleştirme sakinin borcunu siler |
| Toplantı sihirbazı | Governance'ta zaten var; ikinci tablo karar defterinin tekliğini (KMK m.32) bozar |
| Ses kaydı / transkript / AI özet | Altyapı yok; ayrıca genel kurul ses kaydı KVKK m.5-6 kapsamında ayrı dayanak ve açık rıza sorunu doğurur |
| IoT sensör uçları | Zaman serisi deposu (MongoDB) kurulu değil, `go.mod`'da bile yok |
| Entegrasyon kimlik bilgisi kasası | Alan düzeyinde şifreleme (2.8) olmadan sağlayıcı anahtarı saklanmaz |
| Bileşik "sürdürülebilirlik skoru" | Kabul görmüş formülü yok; uydurma ağırlıkla üretilen sayı bir şey ölçmez |

---

# Fikir havuzu — üzerinde düşünülecek (kullanıcı, 2026-10-26) `[D0]`

Henüz tasarlanmadı; geliştirmeden önce kapsam ve kararlar birlikte belirlenecek.

| # | Fikir | Bugün koddaki ilgili parça | Düşünülecek sorular |
|---|---|---|---|
| F1 | **Tedarik talebi** (malzeme/hizmet ihtiyacının talep → onay → sipariş akışı) | Stok hareketinde serbest metin `vendor` alanı (`inventory/repository/inventory.go:83`); gider onay akışı (`expense`); ayrı talep/sipariş tablosu yok | Kim talep açar (görevli, yönetim)? Onay kademesi ve tutar sınırı? Gidere ve stok girişine nasıl bağlanır? |
| F2 | **Taşınma bildirimi** (sakinin taşınma/giriş-çıkış bildirmesi) | İlişik kesme tarihi `resident_units.end_date` (B7), kiracılık bitiş akışı (069), davet ve kayıt (068), daire oturum durumu (`unit_occupancy`) | Sakinin kendisi mi bildirir? Tarih, asansör/eşya taşıma rezervasyonu, borç kontrolü (borcu yoktur belgesi) ve yönetim onayı nasıl bağlanır? |
| F3 | **Tedarikçi başvuru ve kayıt ekranı** | Tedarikçi varlığı yok; sözleşmelerde karşı taraf alanı (`contract`) | Herkese açık başvuru formu mu? Doğrulama (vergi no, belge), site bazlı mı platform genelinde mi, onay ve puanlama? |
| F4 | **SiteSen üzerinden ödeme ve komisyon alma** | Kartla ödeme var (iyzico Ödeme Formu, 060); komisyon kodu yok (ölü `pkg/integrations/bank` hariç) | Pazaryeri/alt üye işyeri modeli (iyzico pazaryeri) mi? Komisyonu kim öder, nasıl gösterilir? Aidat tahsilatında komisyon hukuken ve muhasebe açısından nasıl kaydedilir? Finans migration dondurmasıyla birlikte ele alınmalı. |

---

# Sıradaki işler (öncelik sırasıyla)

FAZ 5 ve FAZ 2'nin çekirdeği bittiği için öncelik arayüzlere ve RLS'in
yaygınlaştırılmasına kayıyor.

1. ~~**RLS'i kalan tablolara yay (2.6 devamı).**~~ **TAMAMLANDI (2026-09-26).**
   81 tablo; kimlik rolü; dağıtım dosyaları (`gen-deploy.py`) tek kaynaktan.
   **Kalan küçük işler:**
   - **TAMAMLANDI (2026-09-27):** Kong tek yukarı akış (gateway) + kenar sınırları. Eski not: `kong/kong.yml` artık isteğe bağlı profil; rotaları gateway'le birebir
     değil. Ya gateway'e yönlendiren tek rotaya indirilmeli ya da kaldırılmalı.
   - ~~`legal_parameters` site bazlı istisna satırları RLS dışında (salt-okur).~~ **TAMAMLANDI (2026-09-27, 029)** — çözümleyici kapsamlı; RLS 82 tablo.
     `pkg/legalparams` çözümleyicisi kapsamsız havuz kullanıyor; RLS açılırsa
     site istisnaları SESSİZCE yok sayılırdı. Önce çözümleyici kapsamlı olmalı.
2. ~~**FAZ 6.7 — yönetişim arayüzleri.**~~ **TAMAMLANDI** (`8d9528d`: işletme projesi, genel kurul, defterler, mevzuat ekranları; 2026-10-03 tsc/lint/build temiz). Eski not: Governance servisi API olarak hazır ama
   panelde ekranı yok: işletme projesi, genel kurul, karar defteri.
3. ~~**Modülleri bildirim altyapısına bağlama.**~~ **TAMAMLANDI (2026-09-14).**
   Duyuru, rezervasyon onay/red, kargo, anket yayını, ziyaretçi girişi ve
   düşük stok uyarısı uygulama içi bildirim üretiyor. Alıcı kümesi
   `pkg/notify/audience.go`'da tek yerde.
   **Kalan:** devriye aksaması, sözleşme ihbar penceresi ve gecikmiş aidat
   için bildirim yok. Bunlar bir olay anına değil ZAMAN geçmesine bağlı
   olduğu için zamanlanmış bir iş (scheduler) gerektiriyor.
   **TAMAMLANDI (2026-09-26) — `cmd/scheduler` (migration 028).** Gecikmiş aidat
   (daireye ayda en fazla bir), sözleşme ihbar son günü / süresi dolmuş ACTIVE
   sözleşme, süresini aşan açık devriye; eksik/çok hızlı tur olay bildirimi.
   Tekrar yok (`dedupe_key`), çok kopyada advisory lock, `-once` kipi, `/health`.
   **Kanıt:** `verify-stack.sh` adım 40 (15 kontrol) — iki site yalıtımı, ikinci
   turda sıfır yeni kayıt. **Bilinçli sınır:** planlı tur saatleri
   (`patrol_routes.schedule_times`) API'de tanımlanamıyor; "hiç başlatılmamış
   planlı tur" ölçülemez ve uydurulmaz.
4. ~~**Panel ve mobil arayüzler.**~~ **TAMAMLANDI** — panel: 34 ekran gerçek API sözleşmesine bağlı (`8d9528d`). Eski not: 20 gerçek modülün çoğunun panelde karşılığı yok.
   **Mobil TAMAMLANDI (2026-09-27):** iki uygulama da gerçek API sözleşmesine bağlı
   (sakin 24, yönetici 21 test; `verify-mobile.sh` 10/10). **Belge açma TAMAMLANDI (2026-10-03, D3):**
   indir → SHA-256 doğrula → geçici dizin → cihaz uygulaması. Cihazda elle denenmedi (emülatör yok).
   **Release manifestlerinde INTERNET izni yoktu** → eklendi, verify-mobile denetliyor.
5. **FAZ 3 kalanı** — **3.4 TAMAMLANDI (2026-10-03).** Eski not: hassas veri okuma logu belge ve personel için yapıldı
   (`document_access_logs`, `PII_REVEAL`); sakin uçlarına da genişletilecek.
   Yapılandırılmış log (3.5).
6. ~~**Panelde çıkış (logout) düğmesi yok**~~ **TAMAMLANDI** — başlık menüsünde
   çıkış düğmesi erişim ve yenileme jetonunu iptal eder; şifre değiştirme de var.
7. ~~**1.6 migration geri alma (down) betikleri.**~~ **TAMAMLANDI (2026-09-27)** — yedek/geri yükleme yordamı, adım 41.
8. **Anahtar yönetimi.** **Döndürme TAMAMLANDI (2026-10-03)** — anahtar halkası,
   `cmd/rotate-pii`, `docs/runbook-anahtar-dondurme.md`, verify adım 42 (1012/1012).
   **Kalan:** anahtar deposu (vault/KMS) seçimi kullanıcı kararı bekliyor (questions S-19).
   Eski not: `PII_ENCRYPTION_KEY` ve `siteeksen_app` parolası bugün
   ortam değişkeniyle veriliyor. Üretim için anahtar deposu (vault) ve anahtar
   döndürme (rotation) yordamı yazılmalı — şifreli veriyi yeniden şifrelemek
   gerekeceği için bu, planlanması gereken bir iştir.
9. ~~**İlan panosu bildirimleri.**~~ **TAMAMLANDI (2026-09-27)** — ayrıca denetçinin ilan kapatma/yorum gizleme açığı kapatıldı. Yeni ilan yönetime, onay/ret ilan sahibine bildirim
   üretmiyor (yanıt "BİLDİRİM GÖNDERİLMEDİ" diyor). `pkg/notify` ile bağlanmalı.
10. ~~**Eskimiş sunucu notları.**~~ **TAMAMLANDI (2026-09-27)** — süre dolumu bilerek elle; zamanlayıcı bildirim üretir. `contract`/`bulletin` `expire-due` yanıtları "zamanlanmış görev
    altyapısı yoktur" diyor; `cmd/scheduler` artık var. Zamanlayıcı süre dolumunu yapıyorsa not
    düzeltilmeli, yapmıyorsa iş zamanlayıcıya eklenmeli.
11. ~~**`/dashboard/stats` yalnızca geliştirme gateway'inde.**~~ **ÇÖZÜLDÜ (2026-09-27)** — gateway her ortamda tek giriş; Kong ona yönlendirir. Üretim yolu (Kong) bu toplamayı
    yapmaz; Kong temizliği (madde 1) ile birlikte karara bağlanmalı.

---

# İnceleme notları

## 2026-10-11 — Altıncı tur: malik / kiracı / oturan ve gider sınıfı (KMK m.20, m.22, m.42-43; TBK m.302, 317, 341)

Kullanıcı kararları (2026-10-11):
- Her mali kalemde sınıf girişte seçilir: **KULLANIM** (oturan öder: kapıcı, temizlik, ısınma, ortak elektrik/su…) ya da
  **MALİK** (demirbaş, yenilik, havuz gibi yeni tesis, ana yapı onarımı). Uygulamadaki TÜM mali işler bu sınıfa uyar.
- Sakin kendi başına üye olamaz. Maliki yönetim kaydeder; yönetim malik olmadan kiracıyı da kaydedebilir; yalnız kiracıyla
  kayıtlı daireye malik sonradan davet edilir. Daire boş olabilir ama malik kayıtlı olmalı; boş dairede her şey malike düşer.
- Kiracıyı malik ya da yönetim SMS + e-postayla davet eder. Dairede aktif kiracı varken davet gönderilemez (yönetim dahil).
- Hane üyesi olur (oturanın hanesi). Devirden sonra malik o dairede kullanım işlemi (talep, rezervasyon, ziyaretçi…) yapmaz.
- Devirden sonra malikin göreceği seçenekli alanları malik DEĞİL yönetim belirler; site bazında tek politika, varsayılan en dar,
  değişiklik kurul üyesi onayı ister; kiracı malikin neyi gördüğünü görür.
- Kiracılık bitişi: malik isterse kiracı onayı şart. Yönetim yolu: belge (UYAP kodu isteğe bağlı), kimlik bilgisiyle onay,
  1 hafta itiraz.

Varsayılan kararlar (kullanıcı aksini söyleyene kadar; `questions.md`'ye işlenecek):
- V1 Kiracı kendi çıkışını malik onayı olmadan yapar (oturanın hakkı); malike bilgi gider.
- V2 Yönetim yolunda itiraz edilirse işlem askıda kalır; yalnız kiracının onayıyla ya da yeni bir belgeyle (yeni 7 gün) ilerler.
  İşlemi başlatan, o dairenin maliki olamaz. Sahte çıkarsa kiracılık geçmişiyle geri açılır.
- V3 Malik kaydı olmayan dairede MALİK sınıfı borç "malik kaydı yok" uyarısıyla yönetimde bekler; kiracıya yansımaz.
- V4 Hane üyesi kullanım özelliklerini kullanır, mali ekranları görmez; oturanın kaydı bitince düşer.
- V5 Mevcut veride aktif kiracısı olan dairede kiracı, olmayanda malik "oturan" sayılır; yönetim düzeltebilir.
- V6 Borcun sorumlusu tahakkuk anında saptanır (sınıf + o günkü oturan); kiracılık bitince açık KULLANIM borcu malike de görünür
  (KMK m.20 asıl sorumlu malik).

Aşamalar (her biri ayrı commit, verify-stack + gerekirse verify-mobile + panel):
- [x] **D1 Gider sınıfı** (verify 1320/1320, panel tsc/lint) — 066: `expense_categories.default_liability`, `expenses.liability`, `operating_budget_items.liability`,
  `assessment_details.liability`, `monthly_assessments.liability`; dönem benzersizliği (bölüm, dönem, sınıf). Elle tahakkuk,
  işletme projesinden tahakkuk, devir bakiyesi ve gider kaydı sınıfı alır; bir bölüme dönem başına sınıf başına bir tahakkuk.
- [x] **D2 Daire oturum modeli** (verify 1325/1325, panel tsc/lint) — 067: `units.owner_occupied`, HOUSEHOLD rolü (şemada;
  ekleme D3), `unit_occupancy()` / `resident_is_occupant()` (durum saklanmaz, kayıtlardan hesaplanır: KİRACI OTURUYOR /
  MALİK OTURUYOR / BOŞ / KAYITSIZ; boş daire tanım gereği malikli). Panel: Oturum sütunu, "kiracı yokken" seçimi, malik
  kaydı yok uyarısı, sakinlerde "Oturan". **D3'e taşındı:** daire başına tek aktif kiracı kısıtı — mevcut kiracı ekleme
  akışları (ve verify'daki çoklu kiracılı fixture'lar) davet akışıyla birlikte değişecek.
D3 kullanıcı kararları (2026-10-11): (1) Davet edilen kişinin hesabı yoksa hesap HEMEN açılır, etkinleştirme kodu SMS +
e-postayla gider; kişi kodu girince (hesabını etkinleştirince) davet kabul edilmiş olur ve devir gerçekleşir. Hesabı olan kişi
uygulamada kabul eder. (2) Hane üyesini dairede oturan ve yönetim ekler; kiracılı dairede malik ekleyemez. (3) Yönetim kiracıyı
doğrudan da kaydeder, davet de gönderir; ikisinde de aktif kiracı varken engel. (4) Kiracı gelince malikin o dairedeki hane
üyelerinin kaydı biter (pasif, iz kalır).
- [x] **D3 Kayıt ve davet** (verify 1331/1331, mobil 10/10, panel tsc/lint) — yönetim maliki/kiracıyı kaydeder; malik ya da
  yönetim kiracıyı SMS + e-postayla davet eder (dolu dairede engel); kiracı kodla katılır, kabulde devir; kiracılı daireye malik
  daveti; hane üyesi daveti. B5'in doğrudan ekleme/bitirme uçları kaldırıldı.

### Kalan plan (2026-10-11, kullanıcı: "önce planla sonra uygula")

İlke: her madde kendi arayüzüyle (panel + sakin uygulaması) birlikte biter; ayrı commit; verify-stack + verify-mobile + panel
tsc/lint. Sıra: D4 → D5 → D6 → D7 → D8. Kararlar: V1–V6 (yukarıda) ve aşağıdaki V7–V9 (varsayılan; kullanıcı aksini
söyleyene kadar). Kullanıcı cevabı (2026-10-11, 5. soru): UYAP doğrulama kodu olmayan belgeler de var → kod isteğe bağlı;
1 hafta itiraz yolu ve kimlik bilgisiyle onay kalır.

- V7 Yönetim yolunda ikinci onaycı ZORUNLU DEĞİL (kullanıcı yalnız itiraz + kimlik onayını tuttu). Koruma: başlatan o dairenin
  maliki/vekili olamaz, şifre yeniden girilerek beyan, belge kiracıya açık, itirazla askı, geri alma.
- V8 Kiracılık bitince daire "boş" olur (`owner_occupied=false`); malik oturuyorsa yönetim ya da malik değiştirir. Kiracının
  hanesinin kaydı da biter.
- V9 Görünürlük politikasının seçenekli alanları (hepsi varsayılan KAPALI): kiracının adı ve maskeli telefonu; kiracı
  sorumluluğundaki kullanım borcunun toplamı; vadesi geçen kullanım borcu ve malike uyarısı; dairenin arıza/talep kayıtları.
  Her zaman görünür (seçenek değil): malik sınıfı borçlar, genel kurul/oy, dairenin oturum durumu, kiracılık bitiş süreçleri,
  kiracılık bitmişse açık kullanım borcu (V6). Hiç görünmez: ziyaretçi, kargo, sayaç/pusula ayrıntısı, hane üyeleri.

- [x] **D4 Kiracılık bitişi** (verify 1341/1341, mobil 10/10, panel tsc/lint) — 069 `tenancy_end_requests` (yalnız kimlik servisi, RLS, silme yok):
  tür OWNER_REQUEST / TENANT_EXIT / MANAGEMENT; durum PENDING_TENANT / OBJECTION_WINDOW / SUSPENDED / COMPLETED / REJECTED /
  CANCELLED / REVERSED; kiracı bağı başına tek açık istek.
  - Malik isteği → kiracı onaylar (biter) ya da reddeder (kalır); malik bekleyen isteğini iptal eder.
  - Kiracının kendi çıkışı (V1) → hemen biter; maliklere SMS/e-posta bilgisi.
  - Yönetim yolu: yönetici/kurul üyesi, o dairenin maliki/vekili DEĞİLSE; belge (PDF/görsel, `pkg/storage`; depo yoksa 503),
    belge türü, UYAP kodu isteğe bağlı, gerekçe, şifre yeniden girilerek beyan (TCK m.204–207 uyarısı, IP ve zaman kaydı).
    7 gün itiraz penceresi; kiracı belgeyi görür, itiraz ederse SUSPENDED; askıdaki istek yalnız kiracı onayıyla ya da yeni
    belgeyle (yeni 7 gün) ilerler; süre itirazsız dolunca yönetim "tamamla" der; sahte çıkarsa "geri al" kiracılığı açar.
  - Bitişte: kiracı bağı pasif + bitiş tarihi, hanesi biter (tetikleyici), daire boş (V8).
  - Yönetimin PATCH ile aktif kiracıyı pasifleştirmesi / kiracı rolünü değiştirmesi kapanır (409 → bitiş akışı).
  - Kimlik servisi bildirim tablosuna yazamaz: tarafa SMS/e-posta doğrudan + uygulamada istek listesi; işlemler denetim izinde.
  - Arayüz: panel "Kiracılık bitişleri" (yönetim yolu, tamamla, geri al, belge); sakin uygulaması istekler ekranı (onay/ret/
    itiraz, belgeyi görme), kiracının "çıkışımı bildir", malikin "kiracılığın bitmesini iste".
- [x] **D5 Mali yönlendirme** (verify 1348/1348, mobil 10/10, panel tsc/lint) — 070: `monthly_assessments.tenant_link_id` (KULLANIM borcu kiracılıkta tahakkuk ettiyse o kiracı
  bağı; V6 anlık görüntü). Eski veride: dairenin şu anki aktif kiracısı, dönemi kiracılık başlangıcından sonraysa (V5).
  - Görünürlük kuralı tek SQL işlevinde (`assessment_visible_to(assessment, user)`): kiracı yalnız kendi kiracılığının kullanım
    borcu; malik/vekil malik sınıfı + kendisine düşen kullanım borcu + kiracılığı bitmiş açık kullanım borcu; hane üyesi hiç.
  - Sakin borç listesi/özet, ödeme ve kart ödemesi yetkisi, alacak dekontları, borcu yoktur belgesi (malik tam; kiracı yalnız
    kendi kullanım borcu) bu işlevle; yeni borç / tahsilat / gecikme bildirimleri borcun sorumlusuna.
  - V3: maliksiz dairede malik sınıfı borç yönetim listesinde "malik kaydı yok" ile; kimseye bildirim gitmez.
  - Yönetim: borçlu listesi, tahakkuk özeti ve PDF/Excel dökümleri sınıf + sorumlu sütunuyla.
  - Arayüz: panel tahakkuk/borçlu sütunları; sakin uygulamasında borçlarda sınıf etiketi.
- [x] **D6 Görünürlük politikası** (verify 1353/1353, mobil 10/10, panel tsc/lint) — 071 `owner_visibility_policies` (site başına tek etkin sürüm + değiştirilemez geçmiş):
  V9 seçenekleri, varsayılan hepsi kapalı. Yönetim önerir, öneren dışında bir KURUL ÜYESİ onaylayınca yürürlüğe girer; etkilenen
  kiracılara bildirim. Uygulama: kimlik servisi (kiracı adı/telefonu), finans (kiracı borç toplamı, vadesi geçen uyarısı),
  topluluk (daire talepleri), zamanlayıcı (malike vadesi geçen uyarısı). Kiracı ve malik politikayı uygulamada görür.
  - Arayüz: panel politika sayfası (öner/onayla/geçmiş); sakin uygulamasında "Malikim neyi görüyor".
- [x] **D7 Kullanım hakkı** (verify 1359/1359, mobil 10/10) — 072 `resident_can_use()`: kiracı ve hane üyesi kullanır; malik/vekil
  yalnız dairede aktif kiracı yokken (malik oturuyor ya da boş — boş dairede her şey malike düşer). Bağlananlar: talep, ziyaretçi
  ön kaydı (önceden daireyle ilişki HİÇ denetlenmiyordu), araç, kargo listesi, rezervasyon, acil durum kartı/yanıtı, sayaç,
  pusula ve itiraz, tüketim verisi (para içerenlerde hane üyesi hariç — V4); kargo ve ziyaretçi bildirimleri
  `notify.UnitUsers`. **Bilerek kapsam dışı:** ilan panosu (malik satılık/kiralık ilanı verebilir), anket/NPS (anket servisi
  malik oyunu ayrıca sayar), tadilat izni (malik/vekil başvurur — kiracının tadilatı malik iznine bağlı, TBK m.321), kural
  ihlali bildirimi (malik de muhatap). Mobil: sunucunun 403 nedeni artık kullanıcıya gösteriliyor.- [x] **D8 Kapanış** (panel tsc/lint/build temiz; verify 1359/1359; mobil 10/10) — `questions.md`'ye V1–V9; `legal/kvkk-aydinlatma.md` (bitiş belgeleri, görünürlük politikası, davet
  verisi); CLAUDE.md ve changelog; uçtan uca gözden geçirme (panel build dahil).
**Altıncı tur sonucu (2026-10-11):** D1–D8 tamamlandı — migration 066-072, verify-stack **1359/1359**, verify-mobile
**10/10**, panel tsc/lint/build temiz, RLS 123 tablo. Kararlar ve varsayılanlar `questions.md` S-23. Kullanıcı girdisi
bekleyenler değişmedi: B10 (destek kanalı), B11 (Firebase), iyzico sandbox anahtarı, Netgsm/SMTP gerçek hesap, PTS protokolü,
defter baş özetinin dış çapası.
## 2026-10-10 — Beşinci tur (Şikayetvar raporu: uygulama aksaklıkları)

Kaynak: `apsiyon_urun_gelistirme_raporu.md` §6.6 (koddan doğrulanmış eksikler). Kapsam kararı (kullanıcı,
2026-10-10): yalnızca uygulama aksaklıkları ve olsa iyi olacaklar; komisyon, fiyat, faiz/gecikme tazminatı,
sözleşme politikasına dokunulmaz. Her madde ayrı commit; her backend maddesinden sonra verify-stack,
mobil maddelerden sonra verify-mobile, panel maddelerinden sonra tsc+lint+build.

- [x] **B1 Yeni borçta sakine bildirim** (verify 1274/1274) — `pkg/notify/charges.go`: verilen tahakkuk kimliklerinden daire
  bazında bildirim (dönem/devir, tutar, son ödeme; uygulama içi + SMTP varsa e-posta; dedupe `charge:<id>`).
  Üç tahakkuk noktası: finance `POST /assessments`, finance `POST /opening-balances`, governance
  `POST /budgets/:id/assessments`. Yanıta `notification` sayaçları. verify: bildirim kaydı, taşınmış sakine
  gitmemesi, ikinci çağrıda çift kayıt olmaması.
- [x] **B2 Yöneticinin tahsilat girişi** (verify 1280/1280, mobil 10/10) — migration 061 (`payments.recorded_by`, korumaya eklenir).
  `POST /finance/collections` {unit_id, assessment_ids, payment_method BANK_TRANSFER|CASH, value_date,
  reference}: ödeme açılır ve aynı işlemde onaylanır (defter zinciri). Ekstrede eşleşmeyen satır
  `assessment_ids` ile doğrudan daireye işlenir. Daire sakinine "ödemeniz kaydedildi" bildirimi.
  Panel: muhasebede "Tahsilat gir" + ekstre satırında "Daireye işle"; yönetici uygulaması: tahsilat formu.
- [x] **B3 Şifremi unuttum (self-servis)** (verify 1284/1284, mobil 10/10) — `POST /auth/password-reset/request` {phone}: hesap var mı
  söylenmez; kod SMS + e-postayla gider; sıklık sınırı (60 sn, saatte 3). Kod mevcut etkinleştirme
  ekranında girilir. SMS/e-posta yapılandırılmamışsa bunu açıkça söyler. Üç istemcide "Şifremi unuttum" →
  numara ekranı.
- [x] **B4 Sakinin kendi telefon/e-posta değişikliği** (verify 1291/1291, mobil 10/10) — e-posta: mevcut şifreyle; telefon: şifre + yeni
  numaraya SMS kodu (sahiplik kanıtı), onayda diğer oturumlar kapanır, eski numaraya uyarı. Çok siteli kişi
  çıkmazının mesajı bu akışa yönlendirir. Mobil profildeki "henüz hazır değil" satırları çalışır.
- [x] **B5 Malikin kiracı yönetimi** (verify 1294/1294, mobil 10/10) — malik kendi dairesine kiracı/vekil ekler ve
  kiracılığı bitirir; yönetime ayrı bildirim yok (kimlik servisi bildirim tablosuna erişemez), işlem denetim izinde. Sakin uygulamasında "Dairem" bölümü.
- [x] **B6 Kademeli giriş kilidi** (verify 1296/1296) — 5. hata 30 sn, 6. hata 2 dk, 7.+ hata 15 dk; yanıt kalan süreyi
  SÖYLEMEZ (hesap/kilit varlığı sızardı), kademeleri sabit metinle anlatır.
- [x] **B7 İlişik kesme tarihi** (verify 1300/1300) — pasifleştirmede `resident_units.end_date` (isteğe bağlı tarih, varsayılan
  bugün), yeniden etkinleştirmede temizlenir; panel listesinde görünür. Changelog satır 231 düzeltilir.
- [x] **B8 Fatura sapma uyarısı + itiraz** (verify 1305/1305, mobil 10/10) — paylaştırmada kullanım alanı başına tüketim site medyanının
  3 katını aşan bölümler listelenir, yayım yönetici teyidi ister. Sakin tüketim pusulasına itiraz eder,
  yönetim yanıtlar, iki tarafa bildirim (063). Panel sayaç sayfası + sakin enerji ekranı.
- [x] **B9 Havale bildirimine dekont dosyası** (verify 1309/1309, mobil 10/10) — sakin bekleyen ödemesine PDF/görsel ekler (`pkg/storage`),
  yönetim indirir. Mobil dosya seçici (yeni paket: `file_picker`).
- [ ] **B10 Yönetim → SiteEksen destek talebi** — KARAR BEKLİYOR (kullanıcı): talepleri SiteEksen tarafında kim, hangi
  kanaldan yanıtlayacak? Sistemde platform hesabı (SUPER_ADMIN) hiç tanımlı değil (seed/panel yok); bu bir işletme kararı.
- [ ] **B11 Push bildirim** — BAŞLANMAZ: Firebase projesi ve `google-services.json` kullanıcıdan (S-10).

**Tur sonucu (2026-10-11):** B1-B9 tamam; verify-stack **1309/1309** (yeni `gofmt` denetimi dahil), verify-mobile **10/10**,
panel tsc/lint/build temiz. 64 migration, RLS 119 tablo, RLS dışı 9 tablo. Açık: B10 (destek talebini kim/hangi kanaldan
yanıtlayacak — kullanıcı kararı), B11 (Firebase).

## 2026-10-05 — Dördüncü tur (kullanıcı kararları + TEST_RAPORU + Apsiyon şikâyetleri)

Kararlar (kullanıcı, 2026-10-05): S-22 → bordro mali müşavirden gelir, sistem ödeme ve maliyeti kaydeder;
S-21 → VERBİS opsiyonel, yükümlülük site yönetiminde; S-19 ve iOS → olduğu gibi kalır.

- [x] K1 kararları `questions.md`'ye işle
- [x] K2 bordro kaydı (S-22, FAZ 7.4) — 047, verify 1169/1169
- [x] K3 VERBİS beyanı (S-21) — opsiyonel, engellemez; verify 1170/1170
- [x] T1 tesis ekleme/düzenleme ucu + panel formu + demo tesis (TEST 2.1) — 048, verify 1174/1174
- [x] T2 m² zorunlu + paylaştırma öncesi eksik alan listesi (TEST 2.2) — 049, verify 1177/1177
- [x] T3 kargo teslim imzası/fotoğrafı depolamaya (TEST 2.3) — 052, verify 1188/1188, mobil 10/10
- [x] T4 SMS (Netgsm) + SMTP adaptörü (TEST 2.4) — sahte sağlayıcıyla uçtan uca (verify 1192/1192); gerçek gönderim için kullanıcı hesap bilgisi girecek
- [x] T5 sanal POS (iyzico) + 3D Secure dönüşü + ödeme durumu (TEST 2.5, BUG-09) — 060, sahte iyzico ile verify 1269/1269, mobil 10/10
- [ ] T5b iyzico sandbox anahtarıyla gerçek uçtan uca deneme — KULLANICI anahtarı bekliyor (kod hazır)
- [x] T6 PDF/Excel rapor motoru (TEST 2.6) — verify 1197/1197, mobil 10/10
- [x] T7 bütçe kesinleştirme — 7579 sonrası durum kanıtı (TEST 2.7) + projeden tahakkuk (050), verify 1182/1182
- [x] T8 ziyaretçi PIN/QR + hızlı doğrulama (TEST 2.8) — 051, verify 1182/1182, mobil 10/10
- [x] T9 panel mobil menü (TEST 6.2) — tarayıcı testi 412×915
- [x] A1 taşınan sakin (BUG-01) — mevcut koruma kanıtı + bildirim metni şeffaflığı; verify 1198/1198
- [x] A2 havale beyanında valör, gecikme tazminatı dondurma ve iz (BUG-02) — 053, verify 1201/1201
- [x] A3 finansal silinemezlik + ters kayıt (BUG-03) — 054, verify 1205/1205
- [x] A4 borcu yoktur belgesi + doğrulama (BUG-04) — 055, verify 1209/1209
- [x] A5 telefon değişimi / kod yeniden üretimi (BUG-05) — verify 1211/1211
- [x] A6 yönetici giriş kilidi kaldırma (BUG-06) — verify 1211/1211
- [x] A7 tüketim pusulası, sayaç değişimi, sapma uyarısı (BUG-07) — 056, verify 1229/1229, mobil 10/10
- [x] A8 cihaz canlılık izleme (BUG-08) — 057, verify 1240/1240 · bariyer uzaktan açma donanım protokolü bekliyor (kullanıcı)
- [x] A10 uluslararası telefon / geo-blok yok (BUG-10) — pkg/phone, verify 1243/1243, mobil 10/10 · Netgsm yurt dışı SMS paketi (kullanıcı)
- [x] A11 site pasifleştirme (BUG-11) — 058, verify 1248/1248
- [x] A12 alacak dekontu + banka ekstresi mutabakatı (BUG-12) — 059, verify 1258/1258, mobil 10/10

**Tur sonucu (2026-10-10):** verify-stack **1269/1269**, verify-mobile **10/10**, panel tsc/lint/build temiz;
60 migration, RLS 117 tablo. Açık kalan yalnızca kullanıcı girdisi bekleyenler: T5b (iyzico sandbox anahtarı),
PTS bariyer komut protokolü (A8 uzaktan açma), Netgsm/SMTP hesapları, defter baş özetinin dış çapası.

## 2026-10-04 — Üçüncü tur (tamamlandı)

**Bitti (commit d71a4ea):** İşletme projesi 7579 s. Kanuna uyumlu (036): genel kurul onayı, geçici proje
3 ay, yeniden değerleme tavanı, zamanlayıcı hatırlatması. verify-stack 1098/1098, verify-mobile 10/10.

**Bitti:** FAZ 7.5 tadilat izni (037), ayar koruması (038), kural ihlali (039), acil durum ve afet (040), vergi/SGK takvimi (041), ortak alan geliri (042), KVKK saklama/imha (043), 4.13 para aritmetiği, 3.6 metrik/hata takibi (044), 7.2 DASK/hasar (045), kamera/biyometrik envanteri (046) — verify-stack 1165/1165, verify-mobile 10/10.
- Kalan: 7.4 bordro (S-22 kararı bekliyor). Kullanıcı kararı bekleyen: S-19, S-21, S-22, iOS paket kimliği.

**Not:** dev-up ve panel (`npm run dev`) arka planda çalışıyor; dev DB 036/037'yi içermiyor (yeniden başlatınca uygulanır).
## 2026-10-04 — Kurulum, görevlendirme, devir, KVKK, saat dilimi (otonom, ikinci tur)

**Doğrulama:** `verify-stack.sh` **1090/1090**, `verify-mobile.sh` **10/10** (sakin 27, yönetici 27),
panel `tsc`/`lint`/`build` temiz, panel sözleşmesi 65 uç.

**Yapılan:** sakin daveti (S-20 kararı, 032); site kurulumu — kurucu yönetici, bölüm toplu ekleme (033);
görevlendirme API'si + oturum iptali; iş saat dilimi sabitlendi (gece yarısı gün kayması); toplu sakin
içe aktarma; devir bakiyesi (034); demirbaş bakım hatırlatması (7.1); liste kesilmesi bildirimi (B69);
yönetişimde kişi–daire bağı; KVKK ilgili kişi başvuruları + süre hatırlatması (035); paneller ve mobil ekranlar.

**Sıradaki (büyük):** 7.3 acil durum, 7.4 bordro/SGK (mevzuat oranları), 7.5 ihlal/tadilat izni,
7.6 ortak alan geliri, 7.7 vergi takvimi, 7.8 saklama/imha; 4.13 tam kuruş göçü; 3.6 metrik.
**Kullanıcı kararı bekleyen:** S-19 (sonra), iOS paket kimliği (sonra).

## 2026-10-03 — Anahtar döndürme, para doğruluğu ve güvenlik turu (otonom)

**Doğrulama (son durum):** `verify-stack.sh` **1042/1042**, `verify-mobile.sh` **10/10**
(sakin 24, yönetici 26 test), panel `tsc` + `lint` + `build` temiz. Her madde ayrı commit.

**Yapılan:** PII anahtar halkası + `cmd/rotate-pii` (todo 8); sakin bakiyesi herkes için 0'dı
(030); borçlu listesi daire bazlı (B55); çift bekleyen ödeme (4.5); tahsilat oranı kayan nokta
(B54); ödeme listesi ödemenin sitesine bağlı (B56) ve sayfalı (B69); tahakkuk dağıtımı kuruş +
sayaç kalemi sessiz dağıtımı (4.4/B70); **yetki yükseltme: daire bağı rolü jetona doğrulanmadan
giriyordu (031)**; başka sitenin hesabını sessizce bağlama (B25); talep `unit_id` (B63), talep/sakin
yarışları (B65), talep numarası çakışması (B71), tip dönüşümü panic (B75); okuma kaydı kanıtı (3.4);
mobil: release manifestinde INTERNET izni yoktu, belge açma, analiz uyarıları sıfır (0.C.6),
yönetici menüsü fail-closed (B26); sahte testler kaldırıldı (B96); 37 MB ikili depodan çıkarıldı.

**Kullanıcı kararı bekleyen:** S-19 (vault/KMS), S-20 (başka sitedeki kişiyi davetle ekleme),
`servicecore-api-doc/` klasörünün amacı, `ios/` için paket kimliği, git push kimlik bilgisi.

## 2026-09-13 — Dürüstlük tamamlandı, güvenlik ve yönetişim turu

**Yapılan:** `questions.md`'deki 18 sorunun tamamı yanıtlandıktan sonra kararlar
uygulandı. FAZ 0 (dürüstlük) ve FAZ 1 (kurulabilirlik) tamamlandı; FAZ 2 (güvenlik),
FAZ 4 (para doğruluğu) ve FAZ 6 (yönetişim) çekirdeği yazıldı.

**Doğrulama:** `verify-stack.sh` **102/102**, `verify-mobile.sh` **8/8**,
admin panel `tsc` + `lint` + `build` temiz.

**Bu turda bulunan ve denetimde yakalanmamış hatalar:**

1. `002_seed_data.sql` tekrar uygulanamıyordu (PK çakışması) — idempotency testi olmadığı
   için görülmemişti.
2. 004'teki `CREATE TRIGGER` idempotent değildi.
3. 003'ten `DROP TABLE audit_logs` kaldırılınca 001'in eski kolonları (`resource_type NOT NULL`)
   ortaya çıktı ve `pkg/audit` INSERT'ü kırıldı — 011'de tasfiye edildi.
4. Finance liste uçları iki farklı yanıt biçimi kullanıyordu (`[...]` ve `{"data": [...]}`);
   istemciler bu farkı bilmediği için **çalışan bir sunucuda bile** hata gösteriyordu.
5. `admin_app` API taban adresi yayında olmayan bir alan adına ve yanlış yola
   (`/v1` yerine `/api/v1`) gidiyordu → uygulama hiçbir ortamda çalışmıyordu.
6. Admin panelde ESLint yapılandırması yoktu; `npm run lint` etkileşimli soru sorup
   CI'da takılıyordu.

**Ders:** Bu altı hatanın hiçbiri kod okuyarak bulunamazdı; hepsi **çalıştırınca** ortaya
çıktı. Doğrulama betiği her tur genişletildiği için her yeni kontrol yeni bir hata buldu.

## 2026-09-09 — Denetim ve planlama turu

**Yapılan:** Tüm repo 5 paralel denetim ekseninde incelendi (backend servisleri, veri katmanı/altyapı,
admin panel, sakin mobil, yönetici mobil). 78 doküman iddiası kod kanıtına karşı test edildi.

**Sonuç:** İddiaların **%49'u yanlış**, %28'i kısmen doğru, %23'ü doğru.
25 servisin yalnızca 3'ü veritabanına bağlı; veritabanı temiz makinede kurulamıyor; denetim izi hiç
çalışmıyor; gateway'de kimlik doğrulama yok; para hesaplarında kritik hatalar var (bakiye kullanıcı
sayısıyla çarpılıyor, ödeme hiç tamamlanmıyor).

**Kök nedenler (asıl çözülen):**
1. "Tamamlandı" için kanıt zorunluluğu yoktu → `dogrulama-politikasi.md` ile kanıt seviyeleri (D0-D4) getirildi
2. Hatalar sessizce yutuluyordu → sessiz başarısızlık yasağı kuralı yazıldı
3. Kurulum tekrar üretilemezdi → FAZ 1'in tamamı buna ayrıldı
4. Tek doğruluk kaynağı yoktu (dokümanlar kendi içinde çelişiyordu) → `tasks/` tek kaynak, kök dosyalar işaretçi
5. Genişlik derinliğe tercih edilmişti (%77 ölü şema) → dikey dilim ilkesi getirildi

**Doğru yapılmış işler korundu:** identity `residents` modülü, `POST /users/me/properties` transaction'ı,
KVKK rıza akışı (backend), tahakkuk dağıtım matematiği, community talep durum makinesi ve sakin onayı,
PDF/Excel motoru, SMS/WhatsApp entegrasyon kodu, `unit_balances` view'ı, şema para tipleri (`DECIMAL`),
`.gitignore` hijyeni. Ayrıntı: `audit-raporu.md` §4.

**Not:** Bu turda hiçbir kaynak kod dosyası değiştirilmedi — yalnızca `tasks/` altındaki planlama
dosyaları yazıldı ve `.agents/AGENTS.md` silinmesi (kullanıcı tarafından) doğrulandı.
