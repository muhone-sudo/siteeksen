# Veritabanı değişikliğini geri alma (runbook)

Kimin için: sistemi işleten (dağıtımı yapan) kişi. Ne zaman: bir migration
başarısız olduğunda ya da uygulandıktan sonra hatalı çıktığında.

## Karar: migration'lar ileri yönlüdür, "down" betiği yazılmaz

Bu veritabanında hukuken saklanması gereken kayıtlar vardır: denetim izi
(`audit_logs`, KVKK m.12), belge erişim kaydı, karar defteri ve yönetim defteri
(KMK m.32-33), ödemeler. Bir tabloyu geri almak için yazılan "down" betiği
tabloyu ve içindeki bu kayıtları siler. Ayrıca "down" betikleri hiç
çalıştırılmadıkları için sessizce bozulur; ihtiyaç anında çalışmazlar.

Bunun yerine iki yol vardır:

| Durum | Yol |
|---|---|
| Migration **başarısız** oldu | Hiçbir şey yapmayın: `cmd/migrate` her migration'ı tek transaction'da uygular; başarısız olan hiç uygulanmamış sayılır. Dosyayı düzeltip yeniden çalıştırın. |
| Migration **uygulandı ama hatalı** | Veri kaybı yoksa: düzeltmeyi **yeni numaralı** bir migration olarak yazın (uygulanmış dosya düzenlenmez; `cmd/migrate` sağlama uyuşmazlığında durur). Veri bozulduysa: aşağıdaki yedekten geri yükleme. |

## Her dağıtımdan önce: yedek

```bash
DATABASE_URL=postgres://<tablo sahibi>@<host>/<db> \
  bash backend/scripts/db-backup.sh yedek-$(date +%F-%H%M).dump
```

Tablo sahibi (ya da süper kullanıcı) bağlantısı gerekir; uygulama rolü RLS
nedeniyle eksik yedek alır. Betik yedeğin okunabildiğini doğrular ve şema
sürümünü yazar.

## Yedekten geri yükleme

1. Yazmaları durdurun (servisleri kapatın). Yedekten sonra yazılan kayıtlar
   geri yüklemede kaybolur; hangi kayıtların kaybolacağını önceden not edin.
2. Geri yükleyin (veritabanı adını açıkça onaylayarak):

   ```bash
   DATABASE_URL=... CONFIRM_RESTORE=<veritabanı adı> \
     bash backend/scripts/db-restore.sh yedek.dump
   ```

   Geri yükleme tek transaction'dır: yarıda kalırsa veritabanı eski hâlinde kalır.
3. Çıkış kodu **3** ise: yedekte olmayan tablolar kalmıştır (yedekten sonra
   oluşturulmuş, çoğunlukla hatalı migration'dan). Betik bunları bilerek
   silmez; listeyi inceleyip elle kaldırın.
4. `go run ./cmd/migrate -status` ile sürümü doğrulayın, düzeltilmiş migration'ı
   yeni numarayla ekleyip servisleri başlatın.

Roller (`siteeksen_app`, `siteeksen_identity`) küme düzeyindedir, yedekte yer
almaz; aynı kümeye geri yüklemede zaten vardır. Yeni bir kümeye geri
yüklemeden önce `cmd/migrate` bir kez çalıştırılarak roller oluşturulmalıdır.

## Kanıt

`bash backend/scripts/verify-stack.sh` adım 41 bu yordamı her çalıştırmada
sınar: yedek alınır, bir tablo silinip ödemeler silinerek ve sahte sürüm
eklenerek yıkıcı bir migration taklit edilir, geri yüklenir. Şema, sürüm
tablosu, RLS, politikalar, ödemeler ve denetim izi yedekle birebir karşılaştırılır.
