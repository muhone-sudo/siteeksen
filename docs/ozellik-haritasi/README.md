# SiteEksen özellik ve yetenek haritası

Üretim tarihi: 2026-10-26 · Kaynak: `main` (8e5e9a1). Her satır koddan çıkarıldı ve `dosya:satır` kanıtı taşır; elle tahmin yoktur.

| Bölüm | Kapsam |
|---|---|
| [1. Yönetim paneli](01-panel.md) | 50 sayfa, 297 eylem (düğme, form, seçim) — kenar çubuğu gruplarına göre |
| [2. Sakin mobil uygulaması](02-sakin-mobil.md) | 33 ekran/bileşen, 170 eylem |
| [3. Yönetici mobil uygulaması](03-yonetici-mobil.md) | 46 ekran/bileşen, 178 eylem |
| [4. Bildirimler, zamanlanmış işler, tetikleyiciler](04-bildirim-zamanlayici-tetikleyici.md) | 54 bildirim üreten uç, 11 zamanlanmış iş, 3 bekçi, 23 tetikleyici, denetim izi |
| [5. Arayüzsüz uçlar](05-arayuzsuz-uclar.md) | Backend'de olup hiçbir ekranda düğmesi olmayan uçlar, 501 modüller |
| [6. Bulgular ve eksikler](06-bulgular-ve-eksikler.md) | Haritadan çıkan hatalar; yapılan özellikler ile haritanın karşılaştırması, eksikler ve öncelik sırası |

## Tablolar nasıl okunur

| Sütun | Anlamı | Nasıl çıkarıldı |
|---|---|---|
| Öğe | Düğme/form/seçim, ekrandaki etiketi ve kaynak satırı. "yalnız arayüz" = sunucuya gitmez (pencere açar, gezinir) | Panel: `Button`/`FormModal` bileşenleri; mobil: her `onPressed`/`onTap` |
| Uç · servis · kayıt | Çağrılan API ucu, onu karşılayan servis ve rotanın kaydedildiği `dosya:satır` | `admin/src/lib/endpoints.ts`, `*/lib/core/network/api_client.dart`, servislerin rota kayıtları |
| Yetki | Ara katman rolü (`RequireRole`), işleyici içi denetim (`isManagement` vb., tanım yeri ile) ve SQL kuralı (`resident_can_use`: kiracılı dairede kullanım işlemini kiracı yapar; `assessment_visible_to`: borcu kim görür/öder) | Go tip denetleyicisiyle (`go/types`) çözülmüş çağrı grafiği |
| Değişen tablolar | `(+)` ekler, `(±)` günceller, `(−)` siler; tabloda tetikleyici varsa adı; dosya deposu kullanımı | Aynı çağrı grafiğinde erişilen SQL metinleri; tetikleyiciler migration'lardan (son tanım) |
| Bildirim | `konu → alıcı kümesi` (`backend/pkg/notify/audience.go`) | `notify.Message{Topic: …}` ve alıcı işlevleri |
| Etkisinin görüldüğü yerler | İşlemin yazdığı tabloyu okuyan GET uçlarını çağıran panel sayfaları ve mobil ekranlar | tablo → okuyan uç → onu çağıran istemci |

## Her eylem için ortak olanlar (tablolarda tekrar edilmez)

- **Denetim izi:** her istek (GET dahil) `audit_logs`'a yazılır; 403 → `DENIED` (`backend/pkg/middleware/auth.go:162`).
- **Site izolasyonu:** her sorgu `pkg/dbscope` ile aktif siteye bağlanır, RLS dışına çıkamaz.
- **Gateway:** `/api/v1/auth/*`, `/public/clearance/*`, `/public/devices/heartbeat`, `/public/payments/iyzico/callback` dışında her uç jeton ister (`backend/cmd/gateway/main.go:188`). `/dashboard/*` gösterge sayıları gateway'de dört servisten toplanır (`main.go:389`).
- **Panel sayfa erişimi** `admin/src/lib/rbac.ts`; düğmelerdeki "yalnız yazma yetkisi" = MANAGER veya BOARD_MEMBER (`admin/src/lib/use-api.ts:78`). Asıl yetki backend'dedir.

## Sınırlar

- Mobilde etiketi yalnız simge olan düğmeler `?` olarak görünür; satır numarasından bulunur.
- Bir düğme dinamik bir yol çağırıyorsa (ör. `/surveys/$id/$action`) çağıran sabit değerden çözülür; çözülemeyenler en yakın rotaya eşlenmiştir.
- Push bildirimi altyapısı yoktur; `PUSH` kanalı kuyrukta kalır.

## Yeniden üretme

```bash
bash docs/ozellik-haritasi/arac/uret.sh          # 1-5. bölümleri koddan yeniden yazar
HARITA_WORK=/tmp/harita bash docs/ozellik-haritasi/arac/uret.sh   # ara dosyaları saklar
```

Gereken: Go, Python 3. 6. bölüm (bulgular) elle yazılır; harita yenilenince gözden geçirilmelidir.
