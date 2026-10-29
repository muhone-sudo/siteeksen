# 9. Arayüzü olmayan uçlar ve bilinen sınırlar

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Bunlar tarayıcıdan denenemez; burada yalnız beklenen durumları listelenir. Ekranlarda bunlara bağlı düğme GÖRÜNMEMELİ.

| Uç | Servis | Not |
|---|---|---|
| `GET /announcements/:id` | community | arayüzde karşılığı yok |
| `GET /bulletins/:id` | bulletin | arayüzde karşılığı yok |
| `GET /consumption/statements/:id` | iot | arayüzde karşılığı yok |
| `GET /contracts/:id` | contract | arayüzde karşılığı yok |
| `GET /documents/:id` | document | arayüzde karşılığı yok |
| `GET /facilities/:id` | reservation | arayüzde karşılığı yok |
| `GET /finance/assessments/:id` | finance | arayüzde karşılığı yok |
| `GET /inventory/:id` | inventory | arayüzde karşılığı yok |
| `GET /packages/:id` | package | arayüzde karşılığı yok |
| `GET /public/clearance/:code` | finance | borcu yoktur belgesindeki karekod → `http://localhost:3001/dogrula/<kod>` (01 bölümünde test edilir) |
| `GET /sensors/:id` | iot | arayüzde karşılığı yok |
| `POST /auth/refresh` | identity | jeton yenileme; oturum 15 dk sonra da sürüyorsa çalışıyor demektir (01 bölümü) |
| `POST /public/devices/heartbeat` | parking | cihaz simülatörü (http://localhost:18000/cihaz) |
| `POST /public/payments/iyzico/callback` | finance | sahte iyzico sayfası çağırır (kart ödemesi senaryosu) |
| `POST /public/sensors/data` | iot | cihaz simülatörü (http://localhost:18000/cihaz) |

**Yazılmamış modül (S-07):** `banking` — 16 uç, hepsi 501 döner. Panelde banka entegrasyonu menüsü varsa "henüz hazır değil" demeli.

**Bilinen sınırlar:** push bildirimi yok (PUSH kanalı PENDING kalır); iOS derlemesi yok; web derlemesinde biyometrik giriş yok; QR okutma ve konum web'de tarayıcı iznine bağlıdır.
