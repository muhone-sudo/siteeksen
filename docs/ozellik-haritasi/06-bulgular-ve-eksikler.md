# 6. Bulgular ve eksikler

Tarih: 2026-10-26. İki kaynak karşılaştırıldı:
- **Yapılan özellikler:** `tasks/changelog.md` (her girdi kanıtlı) ve CLAUDE.md'deki "gerçek durum" notları.
- **Harita:** bu klasördeki 1-5. bölümler (koddan üretildi, `arac/uret.sh`).

Bir özellik "eksik" sayıldıysa backend'de çalışıyor ama ilgili kullanıcının ekranında karşılığı yok demektir. Her maddede uç ve kanıt satırı var.

## A. Haritayı çıkarırken bulunanlar

| # | Bulgu | Kanıt |
|---|---|---|
| A1 | Giriş sayfasındaki "Yöneticinize başvurun" bağlantısı hiçbir yere gitmiyor (`href="#"`). | `admin/src/app/login/page.tsx:154` |
| A2 | **Yönetim için kişisel bildirim kutusu yok.** Kişinin kendi bildirimlerini okuyan uç (`GET /notifications`) yalnız sakin uygulamasında kullanılıyor. Yönetime giden bildirimler (KVKK başvurusu, tadilat, ihlal, düşük stok, devriye sorunu, 11 zamanlanmış işin 9'u) panelde sadece Bildirimler sayfasındaki giden kutusunda (sitenin tüm bildirimleri) görülebiliyor. Yönetici mobil uygulamasında ise hiç görünmüyor. Panel zil simgesi kişisel kutuya değil toplu gönderim sayfasına gidiyor. | `backend/services/notification/main.go:64`, `admin/src/components/layout/header.tsx:85`, 4.1 |
| A3 | Panel *Entegrasyon Anahtarları* sayfası backend'i çağırmıyor, yalnız bilgi notu gösteriyor. `settings` servisindeki 7 `/credentials*` ucu hiçbir istemcide kullanılmıyor. | `admin/src/app/(dashboard)/dashboard/credentials/page.tsx` |
| A4 | Sakin uygulamasının API istemcisinde `getVisitors` (`GET /visitors`) ve `reportClientError` (`POST /client-errors`) yöntemleri tanımlı ama hiçbir ekrandan çağrılmıyor. | `mobile/lib/core/network/api_client.dart` |
| A5 | IoT sensör ve alarm uçları (6 uç) hiçbir istemcide yok. Bu bilinçli: CLAUDE.md'de "gerçek değil" olarak geçiyor. | 5.1 |
| A6 | `banking` ve `meeting_wizard` servislerinin 33 ucu 501 döner (kullanıcı kararı S-07 / governance ile tekrar). | 5.2 |
| A7 | CLAUDE.md'de koda uymayan ifadeler vardı ve düzeltildi: panelde çıkış düğmesi ve rol denetimi "yok" deniyordu; `iot`/`notification` satırlarında MongoDB/Firebase/Kafka geçiyordu; bildirim üreten modül sayısı "altı" yazıyordu (gerçekte 14 servis, 54 uç); `intl` "kullanılmıyor" deniyordu; ortam tablosu WSL yolunu gösteriyordu. | CLAUDE.md |

## B. Yapılan özellik ↔ harita: eksikler

### B1. Sakin mobil uygulaması

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

### B2. Devriye — saha tarafı hiç yok

| Yapılan | Backend | İstemci | Etki |
|---|---|---|---|
| "Zaman sunucudan; durum okutmalardan hesaplanır; çok hızlı tur işaretlenir" | `POST /patrols` (başlat), `POST /patrols/:id/scan` (nokta okut), `POST /patrols/:id/issues` (sorun bildir), `POST /patrols/:id/complete` | **Dördü de hiçbir istemcide yok.** Panel ve yönetici mobil yalnız rota/nokta tanımlıyor ve listeliyor. | Devriye başlatılamıyor, okutulamıyor. Bu yüzden `patrol.issue` bildirimi ve zamanlayıcının `patrol.overdue` hatırlatması pratikte tetiklenemez. Güvenlik görevlisi için bir ekran gerekiyor. |

### B3. Panelde eksik yönetim işlemleri (backend var, ekran yok)

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

### B4. Yönetici mobil uygulaması — panelde olup mobilde olmayan yazma işlemleri

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

1. **B1.7 NPS yanıtı** ve **B2 devriye saha ekranı:** iki modül uçtan uca kullanılamıyor.
2. **A2 yönetim bildirim kutusu:** yönetime giden bütün bildirimler ve hatırlatmalar fiilen görünmüyor.
3. **B1.1 ödeme geçmişi, B1.3 ziyaretçi listesi/iptal/kod, B1.2 araç:** changelog'da sakin için yapıldığı yazan ama ekranı olmayan işler.
4. **B1.5 kargo kanıtı görüntüleme**, **B1.10 tüm cihazlardan çıkış**, **B1.6 tadilat geri çekme**, **B1.8 ilan yorumları**.
5. B3 panel eksikleri; B4 yönetici mobil kapsamı (kullanıcı kararı: mobilde hangi modüller olmalı?).
6. A1 ölü bağlantı.
