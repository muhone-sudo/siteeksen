# 0. Başlangıç — test ajanı için talimatlar, ortam, hesaplar, sorgular

> Elle yazılır. Bu bölümü her oturumun başında okuyun; diğer bölümler buradaki kurallara, hesap kodlarına ve sorgu kalıplarına dayanır.

## 0.1 Görev

Sen SiteEksen'i (Türkiye kat mülkiyeti kanununa uygun site yönetim sistemi) tarayıcıdan uçtan uca test eden bir test uzmanısın.
Amacın bir şeyin "çalışıyor görünmesi" değil, **söylenen etkinin gerçekten olduğunu** kanıtlamaktır:
düğmeye basınca doğru mesaj çıkıyor mu, kayıt veritabanına doğru yazıldı mı, doğru kişiye bildirim gitti mi,
yanlış kişiye gitmedi mi, etkisi başka ekranlarda görünüyor mu, yetkisi olmayan biri aynı şeyi yapabiliyor mu.

Çalışma kuralları:

1. **Sırayla ilerle.** README'deki sırayı izle. Bir bölümü bitirmeden ötekine geçme. Her test başlığı (`#### ID · …`) tek bir testtir.
2. **Her testin sonucunu hemen kaydet:** http://localhost:18000/sonuc sayfasında ID, durum, hesap ve gözlem.
   - **GEÇTİ** — beklenenlerin tamamı oldu.
   - **KALDI** — beklenen olmadı, hata çıktı, yanlış kişiye bildirim gitti, veri yanlış yazıldı, metin anlaşılmaz/İngilizce/ham JSON.
   - **KISMEN** — bir kısmı oldu (gözleme hangisinin olmadığını yaz).
   - **ATLANDI** — koşul sağlanamadı (ör. zaman gerektirir); nedenini yaz.
   - **ENGELLENDİ** — önceki bir hata yüzünden denenemedi; hangi ID'ye bağlı olduğunu yaz.
3. **Gözlem somut olsun:** ne girdin (değerler), ne gördün (mesajın tam metni), hangi sorgu ne döndü. "Çalışmadı" yeterli değildir.
4. **Kanıt sırası:** (a) ekrandaki sonuç → (b) Adminer sorgusu → (c) bildirim kutuları (zil, SMS kutusu, Mailpit) → (d) "Etkisi görülmeli" satırındaki diğer ekranlar.
   Bir test yalnız (a) ile GEÇTİ sayılmaz; yazma işlemlerinde (b) zorunludur.
5. **Hata bulduğunda dur ve belgele, sonra devam et.** Hata mesajını, adresi, hesabı ve adımı yaz; mümkünse http://localhost:18000/gunluk'ta ilgili servisin son satırlarına bak ve hata satırını gözleme kopyala.
6. **Veriyi bozmaktan korkma, ama kayıt tut.** Test ortamı yerel ve atılabilir. Oluşturduğun kayıtların adlarını "TEST-" ile başlat (ör. "TEST-Duyuru-01"); böylece sorgularda ve ekranlarda bulunur.
7. **Ortamı yeniden başlatma.** Yeniden başlatma veritabanını SIFIRLAR (sonuç kayıtları kalır). Mecbur kalırsan README'deki "Yeniden başlatınca" adımlarını izle.
8. **Veritabanına yazma.** Adminer salt okunurdur; yazmaya çalışma. Veri yalnız uygulamalardan değişir.
9. **Hesap değiştirirken** önce çıkış yap ya da ayrı bir gizli pencere/tarayıcı profili kullan. Panel, sakin uygulaması ve yönetici uygulaması farklı adreslerdedir; aynı anda farklı hesaplarla açık tutulabilir.
10. Bir adım belirsizse ekranda en makul yorumu uygula ve gözleme "yorum:" diye yaz.

## 0.2 Ortamı başlatma (testi başlatan kişi yapar)

```bash
bash backend/scripts/test-ortami.sh            # ilk açılış ~2-4 dk (Flutter web derlemesi varsa daha kısa)
bash backend/scripts/test-ortami.sh --stop     # durdurma
YENIDEN_DERLE=1 bash backend/scripts/test-ortami.sh   # mobil kod değiştiyse web derlemelerini yenile
```

Betik "TEST ORTAMI HAZIR" yazınca başlanır. Her açılış **taze veritabanı** ile başlar ve test hesaplarını gerçek kayıt akışıyla (yönetici ekler → kişi kendi koduyla şifresini belirler) yeniden oluşturur.

## 0.3 Adresler

| Ne | Adres | Not |
|---|---|---|
| Araçlar sayfası | http://localhost:18000 | Bütün bağlantılar burada |
| Yönetim paneli | http://localhost:3001 | Next.js |
| Sakin uygulaması (web) | http://localhost:3002 | Flutter web; pencereyi ~400 px genişliğe daraltın |
| Yönetici uygulaması (web) | http://localhost:3003 | Flutter web |
| Tedarikçi uygulaması (web) | http://localhost:3004 | SiteEksen Tedarikçi (Usta & Hizmet); ~400 px genişlik |
| Tedarikçi paneli / Platform paneli | http://localhost:3001/tedarikci · http://localhost:3001/platform | Usta & Hizmet; girişleri ayrı (`/tedarikci/giris`, `/login`) |
| Veritabanı — Adminer | http://localhost:18080 | Sistem **PostgreSQL**, sunucu **db**, kullanıcı **test_okuyucu**, şifre **test_okuyucu**, veritabanı **siteeksen**. Sorgu: sol üstte **SQL komutu** |
| E-posta — Mailpit | http://localhost:18025 | Servislerin gönderdiği bütün e-postalar |
| SMS kutusu | http://localhost:18000/sms | Sahte Netgsm; numara 5XXXXXXXXX biçiminde |
| Kart ödemesi | http://localhost:18000/iyzico | Sahte iyzico; ödeme sayfası ödeme başlatılınca kendiliğinden açılır |
| Cihaz simülatörü | http://localhost:18000/cihaz | Sensör okuması, geçiş cihazı sinyali |
| Servis günlükleri | http://localhost:18000/gunluk | Hata ayıklama |
| **Test sonuçları** | http://localhost:18000/sonuc | Her testin sonucu buraya |
| Borcu yoktur doğrulama | http://localhost:3001/dogrula/&lt;kod&gt; | Belgedeki karekodun açtığı herkese açık sayfa |
| Kart ödemesi dönüşü | http://localhost:3001/odeme-sonuc | Ödeme sayfasından sonra tarayıcı buraya gelir |

## 0.4 Hesaplar (hepsinin şifresi `Demo123!`)

| Kod | Telefon | Kişi | Ne | Nerede kullanılır |
|---|---|---|---|---|
| **YÖNETİCİ** | 5551234567 | Ahmet Yılmaz | Güneş Sitesi MANAGER + BOARD_MEMBER, A-3 maliki; Deniz Apt. kurucu yöneticisi | Panel, Yön.mobil (sakin uygulamasında A-3 maliki olarak da) |
| **KURUL** | 5550000001 | Zeynep Arslan | BOARD_MEMBER, B-2 maliki | Panel, Yön.mobil, sakin |
| **DENETÇİ** | 5550000002 | Hasan Koç | AUDITOR (okur, yazamaz) | Panel, Yön.mobil |
| **GÖREVLİ** | 5550000003 | Murat Öz | STAFF (güvenlik/görevli) | Panel (operasyon), Yön.mobil (devriye) |
| **KİRACI** | 5559876543 | Mehmet Demir | A-4 kiracısı | Sakin uygulaması |
| **MALİK_A4** | 5550000010 | Ayşe Kaya | A-4 maliki (dairesi kiracılı, kendisi oturmuyor) | Sakin uygulaması |
| **MALİK_B1** | 5550000011 | Fatma Şahin | B-1 maliki, kendisi oturuyor | Sakin uygulaması |
| **VEKİL_B1** | 5550000012 | Ali Çelik | B-1 vekili (PROXY) | Sakin uygulaması |
| **SİTE_B** | 5550000020 | Elif Yurt | Deniz Apartmanı (ikinci site) A-1 maliki | İzolasyon: Güneş Sitesi'nin hiçbir verisini görmemeli |
| **PLATFORM** | 5550000030 | Pelin Platform | PLATFORM_ADMIN (Usta & Hizmet platform yönetimi) | Panel `/platform` |
| **TEDARİKÇİ1** | 5550000040 | Kemal Usta | Kemal Tesisat — onaylı, Usta Pro paketi, 2 işletme (Kadıköy 15 km, Ataşehir tüm il), bakiye 650 TL | Panel `/tedarikci`, tedarikçi uygulaması |
| **TEDARİKÇİ2** | 5550000041 | Selin Temiz | Selin Temizlik — onaylı, ücretsiz paket, 1 işletme (Üsküdar 20 km), bakiye 200 TL | Panel `/tedarikci`, tedarikçi uygulaması |

Siteler: **Güneş Sitesi** `11111111-1111-1111-1111-111111111111` (A ve B blok, 24 bölüm) · **Deniz Apartmanı (Test B)** (2 bölüm).
Kişilerin e-postası `<telefon>@siteeksen.test` (Mailpit'te bu adreslerle görünür). Kimlikler: `SELECT id, first_name, last_name, phone FROM users ORDER BY phone;`

Kural özetleri (beklenenleri anlamak için):
- **Kullanım işlemleri** (araç, ziyaretçi, rezervasyon, kargo, sayaç okuma görme) kiracılı dairede **kiracınındır**; MALİK_A4 A-4 için bunları yapamaz (`resident_can_use`).
- **Borç görünürlüğü:** kullanım borcu (aidat vb.) kiracılı dönemde kiracıya, malik sınıfı borçlar (ör. yatırım/demirbaş) malike görünür (`assessment_visible_to`). Hane üyesi borç görmez.
- **Denetçi** her şeyi okur, hiçbir şeyi değiştiremez. **Görevli** yalnız operasyon ekranlarındadır.
- **PUSH** bildirim sağlayıcısı yoktur: PUSH satırları `PENDING` kalır — bu doğrudur.
- **Banka entegrasyonu** bilerek yazılmadı: 501 / "henüz hazır değil" görmek doğrudur.

## 0.5 Sorgu kalıpları (Adminer → SQL komutu)

Aşağıdaki kısaltmalar test adımlarında geçer.

| Kısa ad | Sorgu | Ne için |
|---|---|---|
| **Q-SON(tablo)** | `SELECT xmin, * FROM <tablo> ORDER BY xmin::text::bigint DESC LIMIT 5;` | Tabloya en son eklenen/güncellenen satırlar (`xmin` son yazan işlemdir; en üstte az önceki işlem olmalı) |
| **Q-AUDIT** | `SELECT created_at, source, action, entity_type, screen, status_code, user_id FROM audit_logs ORDER BY created_at DESC LIMIT 20;` | Son işlem kayıtları; 403'ler `DENIED` |
| **Q-BILDIRIM** | `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name \|\| ' ' \|\| u.last_name AS alici, n.subject, n.suppress_reason FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id ORDER BY n.created_at DESC LIMIT 40;` | Son bildirimler, kime, hangi kanal, durum |
| **Q-TALEP** | `SELECT r.created_at, c.name AS kategori, r.buyer_type, r.status, r.accepted_count, r.max_accepts, r.description FROM mp_requests r JOIN mp_categories c ON c.id = r.category_id ORDER BY r.created_at DESC LIMIT 20;` | Usta & Hizmet talepleri |
| **Q-GONDERIM** | `SELECT d.request_id, a.trade_name, d.visible_at, d.notified_at, d.accepted_at, d.fee_kurus, d.used_included FROM mp_request_dispatch d JOIN mp_supplier_accounts a ON a.id = d.account_id ORDER BY d.created_at DESC LIMIT 30;` | Talebin gittiği hesaplar, görünürlük (öncelik penceresi), kabul |
| **Q-DEFTER** | `SELECT l.created_at, a.trade_name, l.kind, l.amount_kurus, l.balance_after, l.note FROM mp_wallet_ledger l JOIN mp_supplier_accounts a ON a.id = l.account_id ORDER BY l.created_at DESC LIMIT 30;` | Tedarikçi bakiye defteri (tutarlar kuruş) |
| **Q-OKUNDU** | `SELECT r.read_at, u.phone, n.topic FROM notification_reads r JOIN users u ON u.id = r.user_id JOIN notifications n ON n.id = r.notification_id ORDER BY r.read_at DESC LIMIT 20;` | Okundu bilgisi |
| **Q-KISI** | `SELECT u.phone, u.first_name, u.last_name, ru.role, un.block \|\| '-' \|\| un.door_number AS daire, ru.is_active, ru.end_date FROM resident_units ru JOIN users u ON u.id = ru.resident_id JOIN units un ON un.id = ru.unit_id ORDER BY un.block, un.door_number;` | Kim hangi dairede, hangi sıfatla |
| **Q-ROL** | `SELECT u.phone, pr.role, pr.valid_from, pr.valid_to, pr.property_id FROM property_roles pr JOIN users u ON u.id = pr.user_id ORDER BY u.phone;` | Site görevleri |
| **Q-BORC** | `SELECT un.block \|\| '-' \|\| un.door_number AS daire, ma.period_year, ma.period_month, ma.total_amount, ma.paid_amount, ma.status, ma.due_date FROM monthly_assessments ma JOIN units un ON un.id = ma.unit_id ORDER BY ma.period_year DESC, ma.period_month DESC, daire LIMIT 50;` | Tahakkuk/borç durumu |
| **Q-ODEME** | `SELECT p.created_at, p.amount, p.payment_method, p.status, p.recorded_by FROM payments p ORDER BY p.created_at DESC LIMIT 20;` | Ödemeler |

Sorgu hata verirse (sütun adı farklı olabilir): tabloyu Adminer'in solundaki listeden açıp yapısına bakın, sorguyu düzeltin ve gözleme yazın. Bu bir uygulama hatası değildir.

**Tutarlar:** veritabanında para kuruş ya da `numeric` olabilir; ekranda `1.234,56 ₺` biçiminde görünmeli. Ekrandaki tutar ile sorgudaki tutar aynı olmalı.

## 0.6 Her test için ortak beklentiler (testlerde tekrar yazılmaz)

- Türkçe, anlaşılır mesajlar; teknik hata metni, `undefined`, `NaN`, `null`, `[object Object]`, İngilizce yığın izi YOK.
- Uydurma/örnek veri YOK: veri yoksa "kayıt yok" türü boş durum mesajı.
- Tarih `gg.aa.yyyy`, saat 24 saat, para `₺` ve Türkçe ayraçlarla.
- Başarılı işlemden sonra liste kendiliğinden ya da yenilemeyle güncellenir; çift tıklama ikinci kayıt oluşturmaz (düğme işlem sırasında pasifleşir).
- Ağ/sunucu hatasında kullanıcıya anlamlı mesaj; sayfa çökmez.
- Yetkisiz işlemde sunucu 403 döner, ekranda yetki mesajı çıkar, veri değişmez, `audit_logs`'ta `DENIED` satırı oluşur.
- Sayfa 400 px genişlikte de kullanılabilir (yatay kaydırma yok, düğmeler erişilebilir).
- Tarayıcı geliştirici araçları açılabiliyorsa: konsolda kırmızı hata ve ağ sekmesinde beklenmeyen 4xx/5xx yok (beklenen 403/422 doğrulama testleri hariç).

## 0.7 Bölüm sırası

README.md'deki tabloya bakın. Kısaca: 01 oturum → 02 rol/izolasyon → 03 panel bölümleri → 04 sakin uygulaması → 05 yönetici uygulaması → 06 bildirimler → 07 veritabanı → 08 uçtan uca senaryolar → 09 sınırlar → 10 Usta & Hizmet.
Senaryolar (08) birden çok hesabın birlikte çalıştığı akışlardır; sayfa testlerinde oluşan veriyi kullanabilir ama kendi başına da yürütülebilir.
