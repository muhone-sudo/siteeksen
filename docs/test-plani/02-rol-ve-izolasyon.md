# 2. Rol, erişim ve site izolasyonu

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Her hesapla panele girip aşağıdaki her adresi adres çubuğuna yazarak açın. **Erişir** = sayfa açılır ve kenar çubuğunda menüsü görünür; **Yönlenir** = `/dashboard/forbidden` sayfası açılır (kendi rollerini ve gereken rolleri yazar), menüde görünmez. KİRACI (yalnız sakin) panelin hiçbir sayfasına giremez. Panel denetimi kolaylıktır; asıl yetki sunucudadır (sayfa bölümlerindeki 'Yetki (olumsuz)' satırları).

| ID | Adres | Gereken rol | YÖNETİCİ | KURUL | DENETÇİ | GÖREVLİ | KİRACI |
|---|---|---|---|---|---|---|---|
| R-ANA | `/dashboard` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-ANNOUNCEMENTS | `/dashboard/announcements` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-BULLETINS | `/dashboard/bulletins` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R-EMERGENCY | `/dashboard/emergency` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-INSURANCE | `/dashboard/insurance` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-KVKK | `/dashboard/kvkk` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-NOTIFICATIONS | `/dashboard/notifications` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R-RENOVATIONS | `/dashboard/renovations` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-REQUESTS | `/dashboard/requests` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-RESIDENTS | `/dashboard/residents` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-ROLES | `/dashboard/roles` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-SURVEYS | `/dashboard/surveys` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R-UNITS | `/dashboard/units` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-VIOLATIONS | `/dashboard/violations` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-ACCOUNTING | `/dashboard/accounting` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-ASSESSMENTS | `/dashboard/assessments` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-COLLECTION | `/dashboard/collection` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-EXPENSES | `/dashboard/expenses` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-METERS | `/dashboard/meters` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-CONTRACTS | `/dashboard/contracts` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-DOCUMENTS | `/dashboard/documents` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-GOVERNANCE-ASSEMBLIES | `/dashboard/governance/assemblies` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-GOVERNANCE-BOOKS | `/dashboard/governance/books` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-GOVERNANCE-BUDGETS | `/dashboard/governance/budgets` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-GOVERNANCE-COMMON-AREA | `/dashboard/governance/common-area` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-GOVERNANCE-LEGAL | `/dashboard/governance/legal` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-ASSETS | `/dashboard/assets` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-INVENTORY | `/dashboard/inventory` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-PACKAGES | `/dashboard/packages` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-PARKING | `/dashboard/parking` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-PATROL | `/dashboard/patrol` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-PERSONNEL | `/dashboard/personnel` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R-RESERVATIONS | `/dashboard/reservations` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-SENSORS | `/dashboard/sensors` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-VISITORS | `/dashboard/visitors` | MANAGER/BOARD_MEMBER/STAFF | Erişir | Erişir | Yönlenir | Erişir | Yönlenir |
| R-ENERGY | `/dashboard/energy` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-ESG | `/dashboard/esg` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-NPS | `/dashboard/nps` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-REPORTS | `/dashboard/reports` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-AUDIT | `/dashboard/audit` | MANAGER/AUDITOR | Erişir | Yönlenir | Erişir | Yönlenir | Yönlenir |
| R-INBOX | `/dashboard/inbox` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-INTEGRATIONS | `/dashboard/integrations` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R-SETTINGS | `/dashboard/settings` | MANAGER/BOARD_MEMBER | Erişir | Erişir | Yönlenir | Yönlenir | Yönlenir |
| R- | `/` | — | Erişir | Erişir | Erişir | Erişir | Erişir |
| R-ACTIVATE | `/activate` | — | Erişir | Erişir | Erişir | Erişir | Erişir |
| R-ACCOUNT | `/dashboard/account` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-FORBIDDEN | `/dashboard/forbidden` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-GOVERNANCE | `/dashboard/governance` | MANAGER/BOARD_MEMBER/AUDITOR | Erişir | Erişir | Erişir | Yönlenir | Yönlenir |
| R-PATROL-REPORTS | `/dashboard/patrol/reports` | MANAGER/BOARD_MEMBER/AUDITOR/STAFF | Erişir | Erişir | Erişir | Erişir | Yönlenir |
| R-LOGIN | `/login` | — | Erişir | Erişir | Erişir | Erişir | Erişir |
| R-ODEME-SONUC | `/odeme-sonuc` | — | Erişir | Erişir | Erişir | Erişir | Erişir |

Her satır bir test ID'sidir; satırdaki beş hesabın hepsi beklendiği gibiyse GEÇTİ, biri farklıysa KALDI (gözleme hangi hesap).

## 2.2 Denetçi (AUDITOR) yazamaz

#### R-DENETCI-YAZAMAZ · Denetçi bütün sayfalarda yalnız okur
- **Hesap:** DENETÇİ · **Nerede:** erişebildiği her panel sayfası
- **Adım:** Erişebildiği her sayfada ekle/düzenle/sil/onayla düğmelerini ara
- **Beklenen:** yazma düğmeleri görünmez ya da pasiftir; görünen bir düğmeye basılırsa sunucu 403 döner, ekranda yetki mesajı çıkar, veritabanında değişiklik olmaz (Q-AUDIT'te `DENIED`)
- **Sonuç:** `R-DENETCI-YAZAMAZ`

## 2.3 Görevli (STAFF)

#### R-GOREVLI-SINIR · Görevli yalnız operasyon ekranlarını kullanır
- **Hesap:** GÖREVLİ · **Nerede:** panel ve yönetici uygulaması
- **Adım:** Ziyaretçi, kargo, otopark, devriye, sayaç, talep ekranlarında işlem yap; personel, mali, ayarlar sayfalarına gitmeyi dene
- **Beklenen:** operasyon işlemleri çalışır; personel/mali/ayarlar sayfaları yönlenir; Yön.mobil'de bu menüler görünmez
- **Sonuç:** `R-GOREVLI-SINIR`

## 2.4 Site izolasyonu (iki site)

Güneş Sitesi ve Deniz Apartmanı (Test B) ayrı sitelerdir. Veri hiçbir yoldan karşı siteye geçmemeli.

#### R-IZOLASYON-01 · Diğer sitenin sakini Güneş Sitesi verisini göremez
- **Hesap:** SİTE_B · **Nerede:** Sakin uygulaması (http://localhost:3002)
- **Adım:** Giriş yap; duyurular, ilanlar, anketler, belgeler, borçlar, bildirimler ekranlarını gez
- **Beklenen:** yalnız Deniz Apartmanı verisi; Güneş Sitesi'nin duyuru/ilan/anket/belgesi hiçbir ekranda yok; site seçicide yalnız Deniz Apartmanı
- **Sonuç:** `R-IZOLASYON-01`

#### R-IZOLASYON-02 · Yönetici site değiştirince bütün ekranlar diğer siteye geçer
- **Hesap:** YÖNETİCİ · **Nerede:** panel kenar çubuğundaki site seçici
- **Adım:** Güneş Sitesi'nde bir duyuru yayımla; site seçiciden Deniz Apartmanı'na geç; Sakinler, Duyurular, Aidat, Giderler sayfalarına bak; geri Güneş Sitesi'ne geç
- **Beklenen:** Deniz Apartmanı'nda Güneş Sitesi'nin duyurusu ve sakinleri yok (yalnız A-1/A-2 bölümleri ve Elif Yurt); geri dönünce Güneş Sitesi verisi eksiksiz
- **Veritabanı:** `SELECT property_id, count(*) FROM announcements GROUP BY 1;` — duyuru doğru site kimliğiyle yazılmış olmalı
- **Sonuç:** `R-IZOLASYON-02`

#### R-IZOLASYON-03 · Adres çubuğuyla başka sitenin kaydına erişilemez
- **Hesap:** SİTE_B ile panel de denenebilir (yönetici değildir → yönlenir); YÖNETİCİ Deniz Apartmanı'ndayken
- **Adım:** Güneş Sitesi'ndeki bir sakin/duyuru/belge kaydının ayrıntı adresini (Güneş Sitesi aktifken kopyala) Deniz Apartmanı aktifken aç
- **Beklenen:** kayıt bulunamadı / 404; Güneş Sitesi verisi görünmez
- **Sonuç:** `R-IZOLASYON-03`

#### R-IZOLASYON-04 · Bildirimler siteye bağlıdır
- **Hesap:** SİTE_B
- **Adım:** Güneş Sitesi'nde tüm sakinlere duyuru/bildirim gönderildikten sonra SİTE_B'nin bildirim kutusuna, SMS kutusuna (5550000020) ve Mailpit'e (5550000020@siteeksen.test) bak
- **Beklenen:** Güneş Sitesi'nin hiçbir bildirimi SİTE_B'ye gitmemiş
- **Veritabanı:** `SELECT count(*) FROM notifications n JOIN users u ON u.id = n.recipient_user_id WHERE u.phone = '+905550000020' AND n.property_id = '11111111-1111-1111-1111-111111111111';` → 0
- **Sonuç:** `R-IZOLASYON-04`

## 2.5 Yönetici uygulamasında rol

#### R-YONMOBIL-ROL · Yönetici uygulaması rol süzmesi
- **Hesap:** sırayla YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, KİRACI · **Nerede:** http://localhost:3003
- **Adım:** Her hesapla giriş yap, ana menüdeki grupları ve öğeleri listele
- **Beklenen:** YÖNETİCİ her şeyi görür; DENETÇİ yazma düğmelerini görmez; GÖREVLİ yalnız operasyon öğelerini görür; KİRACI girişte yönetim yetkisi olmadığı uyarısını alır
- **Sonuç:** `R-YONMOBIL-ROL`
