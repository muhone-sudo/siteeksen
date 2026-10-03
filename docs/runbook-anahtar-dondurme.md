# Kişisel veri şifreleme anahtarını döndürme (runbook)

Kimin için: sistemi işleten (dağıtımı yapan) kişi. Ne zaman:

- Anahtarın sızdığından şüphelenildiğinde (eski bir yedek, kap imajı, günlük, ayrılan çalışan) — **hemen**.
- Düzenli olarak (öneri: yılda bir; KVKK m.12 "uygun güvenlik düzeyi").
- 2026-09-27 öncesinden kalan bir veritabanında, anahtar değişmese de **bir kez**
  (eski kimliksiz biçimi yeni biçime geçirmek için; aşağıda "Eski biçim").

Kapsam: `employees` tablosundaki TCKN ve IBAN (`*_encrypted`, `*_index`). Bugün
`PII_ENCRYPTION_KEY` ile şifrelenen başka veri yoktur.

## Nasıl çalışır

Şifreli metin hangi anahtarla yazıldığını taşır: `k2$<base64(nonce|şifreli)>`.
Anahtar kimliği şifrelemeye ek doğrulanmış veri olarak bağlıdır; kimliği
değiştirilmiş metin çözülmez. Şifreleme ve arama anahtarı (blind index) aynı ana
anahtardan HKDF ile **ayrı** türetilir.

| Ortam değişkeni | Anlamı |
|---|---|
| `PII_ENCRYPTION_KEY` | Birincil anahtar (32 bayt, base64). Yeni yazımlar bununla. |
| `PII_ENCRYPTION_KEY_ID` | Birincil anahtarın kimliği. Varsayılan `k1`. Küçük harf/rakam, en çok 16. |
| `PII_ENCRYPTION_PREVIOUS_KEYS` | Yalnızca ÇÖZMEK için eski anahtarlar: `k1:<base64>,k0:<base64>`. |

Kubernetes'te aynı değerler `app-secrets` içinde `pii-encryption-key`,
`pii-encryption-key-id`, `pii-encryption-previous-keys` anahtarlarıdır (son ikisi isteğe bağlı).

> **Kural:** Yeni anahtara her zaman **yeni bir kimlik** verin. Aynı kimliği farklı
> anahtarla kullanmak, o kimlikle yazılmış kayıtları okunamaz kılar (servis hata
> verir, veriyi boş göstermez).

## Yordam

Örnek: bugün birincil `k1`, yeni anahtar `k2` olacak.

1. **Yedek alın** (`docs/runbook-veritabani-geri-alma.md`). Eski anahtarı, döndürme
   bitip doğrulanana kadar gizli kasada **silmeden** saklayın: yedekteki kayıtlar
   onunla şifrelidir.

2. **Yeni anahtar üretin:**

   ```bash
   openssl rand -base64 32
   ```

3. **Halkayı güncelleyin ve personel servisini yeniden başlatın:**

   ```dotenv
   PII_ENCRYPTION_KEY=<yeni anahtar>
   PII_ENCRYPTION_KEY_ID=k2
   PII_ENCRYPTION_PREVIOUS_KEYS=k1:<eski anahtar>
   ```

   Bu andan itibaren yeni kayıtlar `k2` ile yazılır, eski kayıtlar `k1` ile okunur.
   Aynı TCKN'li ikinci aktif personel denetimi her iki anahtarın arama anahtarlarına
   bakar; döndürme sürerken yinelenen kayıt açılamaz.

4. **Önce deneyin, sonra taşıyın** — RLS'i aşan migration rolüyle (süper kullanıcı
   ya da `properties` tablosunun sahibi). Uygulama rolüyle araç **başlamaz**: siteleri
   göremez ve "kayıt kalmadı" diye yanlış rapor verirdi.

   ```bash
   cd backend
   export DATABASE_URL=postgres://<migration rolü>@<host>/<db>
   export PII_ENCRYPTION_KEY=<yeni> PII_ENCRYPTION_KEY_ID=k2 PII_ENCRYPTION_PREVIOUS_KEYS=k1:<eski>
   go run ./cmd/rotate-pii -dry-run   # kaç kaydın taşınacağını gösterir, yazmaz
   go run ./cmd/rotate-pii
   ```

   Araç her siteyi kendi işleminde taşır; çözülemeyen bir kayıt görürse o sitenin
   işlemini geri alır ve **hata verir** (kaydı atlamaz). Sonunda şifreli alanları
   anahtar kimliğine göre sayar. Beklenen son satır:

   ```text
   Eski anahtarla yazılmış kayıt kalmadı; PII_ENCRYPTION_PREVIOUS_KEYS artık boşaltılabilir.
   ```

   Araç tekrar çalıştırılabilir; ikinci çalıştırma `Toplam 0 kayıt` der.

5. **Eski anahtarı halkadan çıkarın** (`PII_ENCRYPTION_PREVIOUS_KEYS=`) ve servisi
   yeniden başlatın. Birkaç personel kaydını maskesiz (`GET /api/v1/employees/:id?reveal=true`, yönetici) açarak doğrulayın.

6. **Eski anahtarın imhası:** eski anahtarla şifreli **yedekler** saklama süresi
   dolana kadar duruyorsa, anahtarı o süre boyunca kasada tutun ve "yalnızca geri
   yükleme için" diye etiketleyin. Sızıntı nedeniyle döndürdüyseniz, sızan anahtarla
   şifreli yedeklerin de risk altında olduğunu unutmayın.

## Sorunlar

| Belirti | Neden | Çözüm |
|---|---|---|
| Personel ekranı 500, günlükte `veri "k1" anahtarıyla şifrelenmiş ama bu anahtar tanımlı değil` | Eski anahtar döndürme bitmeden halkadan çıkarıldı | `PII_ENCRYPTION_PREVIOUS_KEYS=k1:<eski>` geri ekleyin, `rotate-pii`'yi tamamlayın |
| `rotate-pii`: `bu rol bütün siteleri göremiyor (RLS)` | Uygulama rolüyle bağlanıldı | Migration rolüyle çalıştırın |
| `rotate-pii`: `aynı TCKN'li ikinci bir AKTİF kayıt var` | Döndürme öncesinde (bu düzeltmeden önce) farklı anahtarlarla aynı kişi iki kez açılmış | Kayıtlardan birini işten çıkış ile pasifleştirin, aracı yeniden çalıştırın |
| `şifreli veri çözülemedi (k2)` | Aynı kimlik farklı anahtarla tanımlanmış | Doğru anahtarı o kimliğe geri verin |

## Eski biçim (2026-09-27 öncesi kayıtlar)

Eski kayıtlar kimliksizdir ve arama anahtarları ham anahtarla üretilmiştir. Yeni
kod bunları halkadaki her anahtarla dener, okur ve yinelenen kayıt denetiminde
eski arama anahtarlarını da hesaba katar. Anahtar değiştirmeden yeni biçime
geçmek için yalnızca 4. adımı, mevcut anahtar ve `PII_ENCRYPTION_KEY_ID=k1` ile çalıştırın.

## Doğrulama

`bash backend/scripts/verify-stack.sh` adım 42 bu yordamı baştan sona yürütür:
k1 → k2+k1 (okuma, yinelenen kayıt 409) → uygulama rolüyle reddedilme → eksik
anahtarla hata ve sıfır değişiklik → `-dry-run` → döndürme → tekrar → yalnızca k2
→ tanımsız anahtarla 500 (veri boş gösterilmez).
