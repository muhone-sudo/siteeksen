# 6. Bulgular ve eksikler

Tarih: 2026-10-26 · Son güncelleme: 2026-10-28 (FAZ H sonrası, `4254fff`). İki kaynak karşılaştırıldı:
- **Yapılan özellikler:** `tasks/changelog.md` (her girdi kanıtlı) ve CLAUDE.md'deki "gerçek durum" notları.
- **Harita:** bu klasördeki 1-5. bölümler (koddan üretildi, `arac/uret.sh`).

Bir özellik "eksik" sayıldıysa backend'de çalışıyor ama ilgili kullanıcının ekranında karşılığı yok demektir. Her maddede uç ve kanıt satırı var.

## A. Haritayı çıkarırken bulunanlar

| # | Bulgu | Kanıt |
|---|---|---|
| A1 | **ÇÖZÜLDÜ (H.8).** Eski bulgu: Giriş sayfasındaki "Yöneticinize başvurun" bağlantısı hiçbir yere gitmiyor (`href="#"`). | `admin/src/app/login/page.tsx:154` |
| A2 | **ÇÖZÜLDÜ (FAZ H.2, 073):** panelde üst bar zili + `/dashboard/inbox`, yönetici uygulamasında `inbox_screen` (ana ekranda okunmamış sayısı); okundu bilgisi `notification_reads`. Eski bulgu: **Yönetim için kişisel bildirim kutusu yok.** Kişinin kendi bildirimlerini okuyan uç (`GET /notifications`) yalnız sakin uygulamasında kullanılıyor. Yönetime giden bildirimler (KVKK başvurusu, tadilat, ihlal, düşük stok, devriye sorunu, 11 zamanlanmış işin 9'u) panelde sadece Bildirimler sayfasındaki giden kutusunda (sitenin tüm bildirimleri) görülebiliyor. Yönetici mobil uygulamasında ise hiç görünmüyor. Panel zil simgesi kişisel kutuya değil toplu gönderim sayfasına gidiyor. | `backend/services/notification/main.go:64`, `admin/src/components/layout/header.tsx:85`, 4.1 |
| A3 | **ÇÖZÜLDÜ (2026-10-26, FAZ H.1.2):** sayfa "Entegrasyon durumu" oldu, gerçek durumu gateway `GET /integrations/status`'tan okuyor; `/credentials*` stub uçları kaldırıldı. Eski bulgu: Panel *Entegrasyon Anahtarları* sayfası backend'i çağırmıyor, yalnız bilgi notu gösteriyor. `settings` servisindeki 7 `/credentials*` ucu hiçbir istemcide kullanılmıyor. | `admin/src/app/(dashboard)/dashboard/credentials/page.tsx` |
| A4 | **ÇÖZÜLDÜ (FAZ H.6):** `getVisitors` Ziyaretçilerim ekranında, `reportClientError` `main.dart`'taki hata bildiriminde kullanılıyor. Eski bulgu: Sakin uygulamasının API istemcisinde `getVisitors` (`GET /visitors`) ve `reportClientError` (`POST /client-errors`) yöntemleri tanımlı ama hiçbir ekrandan çağrılmıyor. | `mobile/lib/core/network/api_client.dart` |
| A5 | **ÇÖZÜLDÜ (FAZ H.4, 074):** sensörler PostgreSQL ile gerçek; panel ve yönetici uygulamasında ekranı var. Eski bulgu: IoT sensör ve alarm uçları (6 uç) hiçbir istemcide yok. Bu bilinçli: CLAUDE.md'de "gerçek değil" olarak geçiyor. | 5.1 |
| A6 | **KISMEN ÇÖZÜLDÜ (FAZ H.1.1):** `meeting_wizard` servisi kaldırıldı (governance tek kaynak); `banking` S-07 gereği duruyor. Eski bulgu: `banking` ve `meeting_wizard` servislerinin 33 ucu 501 döner (kullanıcı kararı S-07 / governance ile tekrar). | 5.2 |
| A7 | CLAUDE.md'de koda uymayan ifadeler vardı ve düzeltildi: panelde çıkış düğmesi ve rol denetimi "yok" deniyordu; `iot`/`notification` satırlarında MongoDB/Firebase/Kafka geçiyordu; bildirim üreten modül sayısı "altı" yazıyordu (o gün 14 servis, 54 uç; FAZ H sonrası 55 uç, 14 zamanlanmış iş, 4 bekçi); `intl` "kullanılmıyor" deniyordu; ortam tablosu WSL yolunu gösteriyordu. | CLAUDE.md |

## B. Yapılan özellik ↔ harita: eksikler

### B1. Sakin mobil uygulaması — **ÇÖZÜLDÜ (2026-10-26, FAZ H.6)**

> B1.1–B1.11'in hepsinin sakin uygulamasında ekranı var: Ödeme geçmişi, Araçlarım, Ziyaretçilerim (iptal, kod yenileme),
> Sayaçlarım, kargo kanıtı, tadilat geri çekme, Memnuniyet anketi, ilan yorumları (yazma/okuma/kendi yorumunu kaldırma),
> anket yorumları, tüm cihazlardan çıkış, okundu bilgisi, İşletme projesi (bölüm payı + görüş/itiraz; site ayarı
> `OWNER_PLAN_OBJECTIONS` kapalıysa gönderim 409 ve ekran bunu söyler). Aşağıdaki tablo eski bulgudur.

| # | Yapılan özellik (changelog) | Backend | Sakin uygulamasında | Etki |
|---|---|---|---|---|
| B1.1 | **Ödeme geçmişi** — "sakinin ödeme geçmişi bölümüne yönetimce girilmiş tahsilatları da gösterir" (2026-10-10, 061) | `GET /finance/my-payments` (`services/finance/main.go`) | **Yok.** Hiçbir ekran çağırmıyor. Ödeme ekranı yalnız açık borçları ve tek ödemenin durumunu gösteriyor. | Sakin geçmiş ödemelerini ve yönetimin girdiği tahsilatı göremiyor. |
| B1.2 | **Araç kaydı** — 072 "Bağlananlar: … araç" (kiracı 201, malik 403 sınandı) | `GET/POST /vehicles`, `DELETE /vehicles/:id` | **Yok** (yalnız panelde) | Sakin aracını kaydedemiyor; kural yalnız API testinde çalışıyor. |
| B1.3 | **Ziyaretçi** — 051 PIN+QR, "yeni kod: kaydı açan ya da güvenlik"; "sakin yalnızca kendi ziyaretçisini görür" | `GET /visitors`, `POST /visitors/:id/cancel`, `POST /visitors/:id/pass` | Yalnız ön kayıt (`POST /visitors`) var; **liste, iptal ve kod yenileme yok.** `getVisitors` tanımlı ama çağrılmıyor. | Sakin açtığı geçişi göremiyor, iptal edemiyor, kodu kaybederse yenileyemiyor. `POST /visitors/:id/pass` hiçbir istemcide yok. |
| B1.4 | **Sayaç** — 072 "Bağlananlar: … sayaç" | `GET /meters`, `GET /meter-readings` (`resident_can_use`) | **Yok** (pusula ve itiraz var) | Sakin kendi sayaçlarını ve okumalarını göremiyor. |
| B1.5 | **Kargo teslim kanıtı** — 052 imza ve fotoğraf, "`GET /packages/:id/proof/:kind` özeti doğrulayarak verir" | `GET /packages/:id/proof/:kind` | **Yok.** Panelde ve yönetici mobilde de yok. | Toplanan kanıt hiçbir ekranda görüntülenemiyor. |
| B1.6 | **Tadilat başvurusu** (037) | `POST /renovations/:id/cancel` | Başvuru var; **geri çekme yok** (hiçbir istemcide yok) | Sakin başvurusunu geri alamıyor. |
| B1.7 | **NPS / memnuniyet** — "yanıt yoksa skor yok; anonim" | `POST /nps/:id/respond` | **Yok.** Hiçbir istemcide yok. | Panelde ölçüm açılıyor ama kimse yanıt veremiyor; skor hiç oluşamaz. **Modül uçtan uca kullanılamıyor.** |
| B1.8 | **İlan panosu yorumları** — "yorum silinmez, gizlenir" | `POST /bulletins/:id/comments`, `GET /bulletins/:id/comments` | **Yorum yazma da okuma da yok.** Yönetici mobil yorumları listeleyip gizleyebiliyor. | Yorum özelliği sakin tarafında yok; gizlenecek yorum da oluşamaz. |
| B1.9 | **Anket yorumları** | `GET /surveys/:id/comments` | Oy verirken yorum gönderilebiliyor (`surveys_mobile_screen.dart:206`), yorumlar **hiçbir istemcide listelenmiyor** | Panel de anket yorumlarını göremiyor. |
| B1.10 | **Tüm cihazlardan çıkış** (`tasks/changelog.md:1503`) | `POST /users/me/logout-all` | **Yok** (hiçbir istemcide) | Telefonunu kaybeden kullanıcı diğer oturumları kapatamıyor; tek yol şifre değiştirmek. |
| B1.11 | İşletme projesine itiraz (KMK m.37/2; 7579 sonrası "genel kurulda görüşülecek görüş") | `POST /governance/budgets/:id/objections` | **Yok** (hiçbir istemcide). Panel itirazları listeleyip sonuçlandırıyor. | Malik itiraz/görüş giremiyor; panelde sonuçlandırılacak itiraz oluşamıyor. **Karar gerekir:** 7579 sonrası bu akış ekranda olmalı mı? |

### B2. Devriye — saha tarafı hiç yok — **ÇÖZÜLDÜ (FAZ H.5, 075): QR + GPS zorunluluğu, iz, rapor ve harita**

| Yapılan | Backend | İstemci | Etki |
|---|---|---|---|
| "Zaman sunucudan; durum okutmalardan hesaplanır; çok hızlı tur işaretlenir" | `POST /patrols` (başlat), `POST /patrols/:id/scan` (nokta okut), `POST /patrols/:id/issues` (sorun bildir), `POST /patrols/:id/complete` | **Dördü de hiçbir istemcide yok.** Panel ve yönetici mobil yalnız rota/nokta tanımlıyor ve listeliyor. | Devriye başlatılamıyor, okutulamıyor. Bu yüzden `patrol.issue` bildirimi ve zamanlayıcının `patrol.overdue` hatırlatması pratikte tetiklenemez. Güvenlik görevlisi için bir ekran gerekiyor. |

### B3. Panelde eksik yönetim işlemleri (backend var, ekran yok) — **ÇÖZÜLDÜ (2026-10-26, FAZ H.8)**

> Hepsinin panelde karşılığı var: demirbaş kategori ve zimmet, stok kategorisi / gerekçeli pasife alma / kalem hareket
> geçmişi, sayaç pasife alma (okuma geçmişi korunur), kamera kaydı düzenleme, yıllık personel maliyeti, plaka sorgu,
> kargo imza/fotoğraf indirme, ilan yorumlarını görme ve gizleme, anket yorumları. `GET /esg/sustainability-score`
> H.1'de kaldırıldı (dayanaksız puandı). Ziyaretçi kodu yenileme (P10) de eklendi (yönetim ve görevli; eski kod hemen geçersiz).

| Uç | İşlev | Kanıt |
|---|---|---|
| `POST /asset-categories` | Demirbaş kategorisi ekleme | 5.1 |
| `POST /assets/:id/assign` | Demirbaş zimmetleme | 5.1 |
| `POST /inventory-categories` | Stok kategorisi ekleme | 5.1 |
| `DELETE /inventory/:id` | Stok kalemi silme | 5.1 |
| `DELETE /meters/:id` | Sayaç silme | 5.1 |
| `PUT /privacy/cameras/:id` | Kamera kaydını düzenleme (yalnız ekleme var) | 5.1 |
| `GET /payroll/costs` | Bordro maliyet özeti | 5.1 |
| `GET /esg/sustainability-score` | Sürdürülebilirlik puanı | 5.1 |
| `GET /vehicles/plate/:plate` | Plakadan araç sorgulama (güvenlik girişi için) | 5.1 |
| `GET /packages/:id/proof/:kind` | Teslim kanıtını görüntüleme | B1.5 |
| `GET /surveys/:id/comments` | Anket yorumlarını görme | B1.9 |

### B4. Yönetici mobil uygulaması — panelde olup mobilde olmayan yazma işlemleri — **ÇÖZÜLDÜ (2026-10-26, FAZ H.7, kullanıcı kararı K4)**

> Harita aracıyla ölçüldü: panelin çağırdığı **her** uç (okuma ve yazma) yönetici uygulamasında da çağrılıyor — fark **0**.
> Yeni ekranlar: bağımsız bölümler, görevlendirmeler, KVKK, tadilat, kural ihlali, acil durum, sigorta, belge arşivi,
> bildirim merkezi, NPS, karbon ayak izi, site ayarları, hesabım (site değiştir / yeni site); yönetişim tam yetkili;
> finansa defter, alacak dekontu, banka ekstresi, devir bakiyesi, gecikme tazminatı; personele bordro ve SGK takvimi.
> Ortak altyapı `admin_app/lib/core/widgets/forms.dart` (alan tanımından form, dosya seçme, indirme/açma, satır menüsü).
> Bilinçli fark: personelin TCKN/IBAN'ı mobilde yalnız maskeli görünür (maskesiz görüntüleme `PII_REVEAL` kaydıyla panelde).
> Aşağıdaki tablo eski bulgudur.

Toplam 117 yazma ucu panelde kullanılıyor ama yönetici mobilde kullanılmıyor. Modül bazında:

| Modül | Mobilde olmayan işlemler |
|---|---|
| Acil durum, KVKK, tadilat, kural ihlali (community, 21) | Toplanma noktası/iletişim/tatbikat, durum bildirimi çağrısı açma/kapatma, KVKK başvurusu yanıtlama, tadilat onay/ret/durdurma/tamamlama/rıza, kural ekleme/pasifleştirme, ihlal kaydı ve doğrulama/kademe/sonuçlandırma |
| Yönetişim (17) | İşletme projesi oluşturma/bildirme/kesinleştirme/tahakkuk, genel kurul oluşturma/çağrı/hazirun/toplantı/oy/gündem kapatma, defter kaydı ve kapatma, icra/dava, ortak alan kirası ve geliri |
| Kimlik ve site (22) | Site oluşturma/değiştirme, kendi telefon/e-posta değişikliği, toplu sakin aktarma, davet, kiracılık bitişi (yönetim yolu), sakin telefonu değiştirme, giriş kilidi açma, site pasifleştirme, görevlendirme, bölüm ekleme/düzenleme |
| Finans (11) | Borcu yoktur belgesi, ödeme ters kaydı, gecikme tazminatı işletme, açılış bakiyesi, alacak dekontu ve ters kaydı, banka ekstresi yükleme/eşleştirme/yok sayma/daireye işleme |
| Ayarlar (10) | Site ayarları, saklama süreleri ve imha çalıştırma, malik görünürlük politikası (öneri/onay/ret/iptal), kamera ve biyometrik envanteri |
| Personel (6) | İşten çıkış, izin girişi, SGK bildirimi, bordro oluşturma/ödeme/iptal |
| Sayaç ve tüketim (4) | Sayaç ekleme ve değiştirme, paylaştırma, pusula itirazı yanıtlama |
| Otopark (4) | Geçiş cihazı ekleme/silme, araç ekleme/silme |
| Rezervasyon (4) | Tesis ekleme/düzenleme, rezervasyon onay/ret |
| Sözleşme ve sigorta (4) | DASK, hasar kaydı ve durumu, süresi dolanları kapatma |
| Demirbaş (3), belge (2), NPS (2), devriye (2), bildirim (2), stok (1), ilan (1), ESG (1) | Demirbaş ekleme/bakım/elden çıkarma; belge yükleme/arşivleme; NPS açma/kapatma; devriye rota/nokta tanımı; toplu bildirim ve tercih; stok kalemi ekleme; süresi dolan ilanları kapatma; karbon ayak izi hesabı |

Tam uç listesi 3. bölümde ekran ekran, 1. bölümde sayfa sayfa yer alıyor.

## C. Öneri sırası (etkiye göre)

> 2026-10-28: 1-6'nın hepsi FAZ H'de yapıldı (H.2, H.5, H.6, H.7, H.8). Sıradaki açık maddeler D bölümündedir.

1. ~~**B1.7 NPS yanıtı** ve **B2 devriye saha ekranı**~~ — **ÇÖZÜLDÜ (H.6, H.5).**
2. ~~**A2 yönetim bildirim kutusu**~~ — **ÇÖZÜLDÜ (H.2).**
3. ~~**B1.1 ödeme geçmişi, B1.3 ziyaretçi listesi/iptal/kod, B1.2 araç**~~ — **ÇÖZÜLDÜ (H.6).**
4. ~~**B1.5 kargo kanıtı**, **B1.10 tüm cihazlardan çıkış**, **B1.6 tadilat geri çekme**, **B1.8 ilan yorumları**~~ — **ÇÖZÜLDÜ (H.6, H.8).**
5. ~~B3 panel eksikleri; B4 yönetici mobil kapsamı~~ — **ÇÖZÜLDÜ (H.8, H.7; K4: tam eşitlik).**
6. ~~A1 ölü bağlantı~~ — **ÇÖZÜLDÜ (H.8):** giriş sayfası `/activate` bağlantısı verir.

## D. 2026-10-28 güncellemesinde bulunanlar

Harita FAZ H sonrası koda göre yeniden üretildi. Önce harita aracındaki üç eşleme hatası düzeltildi (README "Sınırlar"):
açılır menüde her seçeneğe menünün bütün çağrıları yazılıyordu (ör. devriye noktasında "Yarıçap" → QR yenileme de görünüyordu);
statik yol `:id` rotasına eşleniyordu (`/finance/assessments/overview` → `/finance/assessments/:id`); üçlü ifadeli yollar
(`…/${accept ? 'accept' : 'decline'}`) tek rotaya düşüyordu. Bu yüzden 5.1'de yanlışlıkla "kullanılmıyor" görünen
4 uç (`GET /finance/assessments/overview`, `GET /audit-logs/export`, davet ve kiracılık talebi reddi) artık doğru yerde.

| # | Bulgu | Kanıt |
|---|---|---|
| D1 | `GET /finance/assessments/:id` (tahakkuk ayrıntısı, `assessment_visible_to` kuralıyla) hiçbir istemcide çağrılmıyor; ekranlar borç ayrıntısını listeden gösteriyor. Ya bir ekrana bağlanmalı ya kaldırılmalı. | 5.1, `services/finance/main.go:92` |
| D2 | Tekil kayıt okuyan `GET /…/:id` uçları (ilan, duyuru, sözleşme, belge, stok, sensör, kargo, tesis, tüketim pusulası) istemcilerde kullanılmıyor; ekranlar listeden açıyor. Hata değil. Not: `GET /documents/:id` `VIEW` erişim kaydı yazar ama çağrılmadığı için belge bilgileri listeden görüldüğünde `VIEW` kaydı oluşmuyor; dosyanın kendisi yalnız indirmeyle açılır ve `DOWNLOAD` kaydı yazılır (`services/document/main.go:143`). | 5.1 |
| D3 | Sakin uygulamasında kiracılık talebini reddetme ve daveti reddetme düğmeleri var; önceki harita bunları "arayüzsüz" gösteriyordu (araç hatası, düzeltildi). | 2. bölüm, `mobile/lib/core/network/api_client.dart:254` |
| D4 | Açık kalan ve kullanıcı kararı bekleyenler: destek talebi (B10), push bildirimi (B11, `PUSH` kanalı kuyrukta kalır), `banking` (S-07), iOS klasörü yok; fikir havuzu F1-F4 (`tasks/todo.md`). | CLAUDE.md, `tasks/todo.md` |
