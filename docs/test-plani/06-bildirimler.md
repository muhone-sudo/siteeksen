# 6. Bildirimler — kim, ne zaman, hangi kanaldan

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Bu bölüm bildirimleri **alıcı tarafından** doğrular: sayfa bölümlerinde işlemi yaptıktan sonra burada o konunun gerçekten doğru kişilere, doğru kanaldan gittiğini ve yanlış kişilere gitmediğini kontrol edin. Kutular: panel zil simgesi + `/dashboard/inbox` (yönetim), Sakin uygulaması Bildirimler, Yön.mobil Bildirimler; SMS kutusu http://localhost:18000/sms; e-posta Mailpit http://localhost:18025. PUSH sağlayıcısı yoktur: `channel = 'PUSH'` satırları `PENDING` kalmalı (bu doğru davranıştır).

## 6.1 Genel bildirim kuralları

#### B-GENEL-01 · Okundu bilgisi
- **Hesap:** YÖNETİCİ (panel) ve KİRACI (sakin uygulaması)
- **Adım:** Okunmamış bildirimi olan hesapla zil simgesindeki sayıyı not et; bir bildirime tıkla; "Tümünü okundu say"
- **Beklenen:** sayı bir azalır, bildirim soluklaşır; tümü okununca sayı kaybolur; sayfa yenilenince durum korunur
- **Veritabanı:** `SELECT r.read_at, n.topic FROM notification_reads r JOIN notifications n ON n.id = r.notification_id ORDER BY r.read_at DESC LIMIT 10;`
- **Sonuç:** `B-GENEL-01`

#### B-GENEL-02 · Gönderilmiş bildirim değiştirilemez
- **Hesap:** — (veritabanı kuralı)
- **Adım:** Adminer'de `SELECT tgname FROM pg_trigger WHERE tgrelid = 'notifications'::regclass AND NOT tgisinternal;`
- **Beklenen:** `notifications_sent_final` ve `notifications_active_property` listede
- **Sonuç:** `B-GENEL-02`

#### B-GENEL-03 · Kanal durumları dürüst
- **Hesap:** —
- **Adım:** `SELECT channel, status, provider, count(*) FROM notifications GROUP BY 1,2,3 ORDER BY 1,2;`
- **Beklenen:** IN_APP → SENT/in_app; SMS → SENT/netgsm (SMS kutusunda karşılığı var); EMAIL → SENT/smtp (Mailpit'te karşılığı var) ya da e-postası olmayanlar için SUPPRESSED/FAILED gerekçeli; PUSH → PENDING (sağlayıcı yok). `SENT` olup sağlayıcısı boş satır OLMAMALI
- **Sonuç:** `B-GENEL-03`

#### B-GENEL-04 · Bildirim tercihleri
- **Hesap:** KİRACI
- **Adım:** Sakin uygulamasında bildirim tercihlerinden bir kanalı/konuyu kapat; o konuda bildirim üreten bir işlem yaptır (ör. yöneticinin duyurusu)
- **Beklenen:** kapatılan kanal için satır `SUPPRESSED` ve gerekçeli; açık kanallar normal
- **Sonuç:** `B-GENEL-04`

## 6.2 İşlemle üretilen bildirimler (uç bazında)

Her satır bir test ID'sidir. Önce **Tetikleyen** sütunundaki işlemi ilgili sayfadan yapın (sayfa bölümündeki test ID'si de geçer), sonra alıcıları doğrulayın.

#### B-POST-BULLETINS · `POST /bulletins`
- **Tetikleyen:** Sakin `bulletin_board_mobile_screen`
- **Konu:** `bulletin.pending` · **Servis:** bulletin (`services/bulletin/main.go:85`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.pending%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-BULLETINS`

#### B-POST-BULLETINS-ID-APPROVE · `POST /bulletins/:id/approve`
- **Tetikleyen:** Panel `/dashboard/bulletins`, Yön.mobil `bulletin_board_screen`
- **Konu:** `bulletin.decision` · **Servis:** bulletin (`services/bulletin/main.go:170`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-BULLETINS-ID-APPROVE`

#### B-POST-BULLETINS-ID-REJECT · `POST /bulletins/:id/reject`
- **Tetikleyen:** Panel `/dashboard/bulletins`, Yön.mobil `bulletin_board_screen`
- **Konu:** `bulletin.decision` · **Servis:** bulletin (`services/bulletin/main.go:183`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'bulletin.decision%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-BULLETINS-ID-REJECT`

#### B-POST-EMERGENCY-CHECKS · `POST /emergency/checks`
- **Tetikleyen:** Panel `/dashboard/emergency`, Yön.mobil `emergency_screen`
- **Konu:** `safety.check` · **Servis:** community (`services/community/emergency.go:286`)
- **Alıcı:** sitenin bütün aktif sakinleri (`Residents`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'safety.check%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-EMERGENCY-CHECKS`

#### B-POST-EMERGENCY-CHECKS-ID-RES · `POST /emergency/checks/:id/respond`
- **Tetikleyen:** Sakin `emergency_screen`
- **Konu:** `safety.need_help` · **Servis:** community (`services/community/emergency.go:326`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'safety.need_help%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-EMERGENCY-CHECKS-ID-RES`

#### B-POST-KVKK-REQUESTS · `POST /kvkk-requests`
- **Tetikleyen:** Sakin `kvkk_requests_screen`
- **Konu:** `kvkk.request` · **Servis:** community (`services/community/kvkk.go:52`)
- **Alıcı:** yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'kvkk.request%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-KVKK-REQUESTS`

#### B-POST-KVKK-REQUESTS-ID-RESPON · `POST /kvkk-requests/:id/respond`
- **Tetikleyen:** Panel `/dashboard/kvkk`, Yön.mobil `kvkk_requests_screen`
- **Konu:** `kvkk.response` · **Servis:** community (`services/community/kvkk.go:99`)
- **Alıcı:** işlemin muhatabı (k.UserID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'kvkk.response%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-KVKK-REQUESTS-ID-RESPON`

#### B-POST-ANNOUNCEMENTS · `POST /announcements`
- **Tetikleyen:** Panel `/dashboard/announcements`, Yön.mobil `create_announcement_screen`
- **Konu:** `announcement`, `announcement.urgent` · **Servis:** community (`services/community/main.go:138`)
- **Alıcı:** sitenin bütün aktif sakinleri (`Residents`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'announcement%' OR n.topic LIKE 'announcement.urgent%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-ANNOUNCEMENTS`

#### B-POST-RENOVATIONS · `POST /renovations`
- **Tetikleyen:** Panel `/dashboard/renovations`, Sakin `renovations_screen`, Yön.mobil `renovations_screen`
- **Konu:** `renovation.request` · **Servis:** community (`services/community/renovation.go:88`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.request%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RENOVATIONS`

#### B-POST-RENOVATIONS-ID-APPROVE · `POST /renovations/:id/approve`
- **Tetikleyen:** Panel `/dashboard/renovations`, Yön.mobil `renovations_screen`
- **Konu:** `renovation.approved`, `renovation.neighbors` · **Servis:** community (`services/community/renovation.go:190`)
- **Alıcı:** aynı bloktaki diğer dairelerin sakinleri (`BlockNeighbors`); işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.approved%' OR n.topic LIKE 'renovation.neighbors%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RENOVATIONS-ID-APPROVE`

#### B-POST-RENOVATIONS-ID-REJECT · `POST /renovations/:id/reject`
- **Tetikleyen:** Panel `/dashboard/renovations`, Yön.mobil `renovations_screen`
- **Konu:** `renovation.rejected` · **Servis:** community (`services/community/renovation.go:284`)
- **Alıcı:** işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.rejected%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RENOVATIONS-ID-REJECT`

#### B-POST-RENOVATIONS-ID-STOP · `POST /renovations/:id/stop`
- **Tetikleyen:** Panel `/dashboard/renovations`, Yön.mobil `renovations_screen`
- **Konu:** `renovation.stopped` · **Servis:** community (`services/community/renovation.go:302`)
- **Alıcı:** işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.stopped%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RENOVATIONS-ID-STOP`

#### B-POST-RENOVATIONS-ID-COMPLETE · `POST /renovations/:id/complete`
- **Tetikleyen:** Panel `/dashboard/renovations`, Yön.mobil `renovations_screen`
- **Konu:** `renovation.completed` · **Servis:** community (`services/community/renovation.go:320`)
- **Alıcı:** işlemin muhatabı (p.ApplicantID) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'renovation.completed%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RENOVATIONS-ID-COMPLETE`

#### B-POST-VIOLATIONS · `POST /violations`
- **Tetikleyen:** Panel `/dashboard/violations`, Sakin `violations_screen`, Yön.mobil `violations_screen`
- **Konu:** `violation.reported` · **Servis:** community (`services/community/violation.go:131`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.reported%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VIOLATIONS`

#### B-POST-VIOLATIONS-ID-RESPOND · `POST /violations/:id/respond`
- **Tetikleyen:** Sakin `violations_screen`
- **Konu:** `violation.response` · **Servis:** community (`services/community/violation.go:173`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.response%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VIOLATIONS-ID-RESPOND`

#### B-POST-VIOLATIONS-ID-DISMISS · `POST /violations/:id/dismiss`
- **Tetikleyen:** Panel `/dashboard/violations`, Yön.mobil `violations_screen`
- **Konu:** `violation.dismissed` · **Servis:** community (`services/community/violation.go:221`)
- **Alıcı:** işlemin muhatabı (v.ReportedBy) (`işlemin`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation.dismissed%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VIOLATIONS-ID-DISMISS`

#### B-POST-VIOLATIONS-ID-ESCALATE · `POST /violations/:id/escalate`
- **Tetikleyen:** Panel `/dashboard/violations`, Yön.mobil `violations_screen`
- **Konu:** `violation.{{{strings}.ToLower}(…)}` · **Servis:** community (`services/community/violation.go:240`)
- **Alıcı:** ilgili dairenin aktif sakinleri (`UnitResidents`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'violation%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VIOLATIONS-ID-ESCALATE`

#### B-POST-FINANCE-ASSESSMENTS · `POST /finance/assessments`
- **Tetikleyen:** Panel `/dashboard/assessments`, Yön.mobil `create_assessment_screen`
- **Konu:** `dues.created` · **Servis:** finance (`services/finance/main.go:135`)
- **Alıcı:** borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-FINANCE-ASSESSMENTS`

#### B-POST-FINANCE-OPENING-BALANCE · `POST /finance/opening-balances`
- **Tetikleyen:** Panel `/dashboard/assessments`, Yön.mobil `finance_tools_screen`
- **Konu:** `dues.created` · **Servis:** finance (`services/finance/main.go:145`)
- **Alıcı:** borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-FINANCE-OPENING-BALANCE`

#### B-POST-FINANCE-COLLECTIONS · `POST /finance/collections`
- **Tetikleyen:** Panel `/dashboard/accounting`, Yön.mobil `collection_entry_screen`
- **Konu:** `payment.recorded` · **Servis:** finance (`services/finance/main.go:155`)
- **Alıcı:** borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'payment.recorded%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-FINANCE-COLLECTIONS`

#### B-POST-FINANCE-BANK-STATEMENTS · `POST /finance/bank-statements/lines/:id/collect`
- **Tetikleyen:** Panel `/dashboard/accounting`, Yön.mobil `collection_entry_screen`
- **Konu:** `payment.recorded` · **Servis:** finance (`services/finance/main.go:156`)
- **Alıcı:** borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'payment.recorded%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-FINANCE-BANK-STATEMENTS`

#### B-POST-GOVERNANCE-BUDGETS-ID-A · `POST /governance/budgets/:id/assessments`
- **Tetikleyen:** Panel `/dashboard/governance/budgets`, Yön.mobil `governance_screen`
- **Konu:** `dues.created` · **Servis:** governance (`services/governance/main.go:92`)
- **Alıcı:** borcun sorumlusu (kullanım borcunda kiracı; malik borcunda malik ve vekil) (`AssessmentPayers`); borcun sorumlusu (`NotifyCharges`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'dues.created%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-GOVERNANCE-BUDGETS-ID-A`

#### B-POST-AUTH-PASSWORD-RESET-REQ · `POST /auth/password-reset/request`
- **Tetikleyen:** Panel `/activate`, Sakin `activate_screen`, Yön.mobil `activate_screen`
- **Konu:** `identity.self_reset` · **Servis:** identity (`services/identity/main.go:83`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.self_reset%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-AUTH-PASSWORD-RESET-REQ`

#### B-POST-AUTH-SUPPLIER-SIGNUP-RE · `POST /auth/supplier-signup/request`
- **Tetikleyen:** Panel `/tedarikci/(auth)/kayit`
- **Konu:** `identity.supplier_signup` · **Servis:** identity (`services/identity/main.go:85`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.supplier_signup%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-AUTH-SUPPLIER-SIGNUP-RE`

#### B-POST-USERS-ME-PHONE-REQUEST · `POST /users/me/phone/request`
- **Tetikleyen:** Panel `/dashboard/account`, Sakin `profile_settings_screen`, Sakin `session_actions`, Yön.mobil `account_screen`
- **Konu:** `identity.phone_change` · **Servis:** identity (`services/identity/main.go:108`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_change%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-PHONE-REQUEST`

#### B-POST-USERS-ME-PHONE-CONFIRM · `POST /users/me/phone/confirm`
- **Tetikleyen:** Panel `/dashboard/account`, Sakin `profile_settings_screen`, Sakin `session_actions`, Yön.mobil `account_screen`
- **Konu:** `identity.phone_changed` · **Servis:** identity (`services/identity/main.go:109`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.phone_changed%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-PHONE-CONFIRM`

#### B-POST-USERS-ME-EMAIL · `POST /users/me/email`
- **Tetikleyen:** Panel `/dashboard/account`, Sakin `profile_settings_screen`, Sakin `session_actions`, Yön.mobil `account_screen`
- **Konu:** `identity.email_change` · **Servis:** identity (`services/identity/main.go:110`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_change%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-EMAIL`

#### B-POST-USERS-ME-EMAIL-CONFIRM · `POST /users/me/email/confirm`
- **Tetikleyen:** Panel `/dashboard/account`, Sakin `profile_settings_screen`, Sakin `session_actions`, Yön.mobil `account_screen`
- **Konu:** `identity.email_changed` · **Servis:** identity (`services/identity/main.go:111`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.email_changed%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-EMAIL-CONFIRM`

#### B-POST-USERS-ME-UNITS-ID-INVIT · `POST /users/me/units/:id/invitations`
- **Tetikleyen:** Sakin `unit_residents_screen`
- **Konu:** `identity.invitation` · **Servis:** identity (`services/identity/main.go:115`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.invitation%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-UNITS-ID-INVIT`

#### B-POST-USERS-ME-UNITS-ID-TENAN · `POST /users/me/units/:id/tenancy-end`
- **Tetikleyen:** Sakin `unit_residents_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:118`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-UNITS-ID-TENAN`

#### B-POST-USERS-ME-UNITS-ID-TENAN-2 · `POST /users/me/units/:id/tenancy-exit`
- **Tetikleyen:** Sakin `unit_residents_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:119`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-UNITS-ID-TENAN-2`

#### B-POST-USERS-ME-TENANCY-REQUES · `POST /users/me/tenancy-requests/:id/approve`
- **Tetikleyen:** Sakin `tenancy_requests_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:121`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-TENANCY-REQUES`

#### B-POST-USERS-ME-TENANCY-REQUES-2 · `POST /users/me/tenancy-requests/:id/decline`
- **Tetikleyen:** Sakin `tenancy_requests_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:122`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-USERS-ME-TENANCY-REQUES-2`

#### B-POST-RESIDENTS · `POST /residents`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `add_resident_screen`
- **Konu:** `identity.activation` · **Servis:** identity (`services/identity/main.go:137`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS`

#### B-POST-RESIDENTS-INVITATIONS · `POST /residents/invitations`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_tools_screen`
- **Konu:** `identity.invitation` · **Servis:** identity (`services/identity/main.go:140`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.invitation%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-INVITATIONS`

#### B-POST-RESIDENTS-TENANCY-REQUE · `POST /residents/tenancy-requests`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_tools_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:144`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-TENANCY-REQUE`

#### B-POST-RESIDENTS-TENANCY-REQUE-2 · `POST /residents/tenancy-requests/:id/documents`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_tools_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:145`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-TENANCY-REQUE-2`

#### B-POST-RESIDENTS-TENANCY-REQUE-3 · `POST /residents/tenancy-requests/:id/complete`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_tools_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:146`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-TENANCY-REQUE-3`

#### B-POST-RESIDENTS-TENANCY-REQUE-4 · `POST /residents/tenancy-requests/:id/reverse`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_tools_screen`
- **Konu:** `identity.tenancy` · **Servis:** identity (`services/identity/main.go:148`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.tenancy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-TENANCY-REQUE-4`

#### B-POST-RESIDENTS-ID-ACTIVATION · `POST /residents/:id/activation-code`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_detail_screen`
- **Konu:** `identity.activation` · **Servis:** identity (`services/identity/main.go:152`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-ID-ACTIVATION`

#### B-POST-RESIDENTS-ID-PHONE · `POST /residents/:id/phone`
- **Tetikleyen:** Panel `/dashboard/residents`, Yön.mobil `resident_detail_screen`
- **Konu:** `identity.activation`, `identity.phone_changed` · **Servis:** identity (`services/identity/main.go:155`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'identity.activation%' OR n.topic LIKE 'identity.phone_changed%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESIDENTS-ID-PHONE`

#### B-POST-INVENTORY-ID-MOVEMENTS · `POST /inventory/:id/movements`
- **Tetikleyen:** Panel `/dashboard/inventory`, Yön.mobil `inventory_management_screen`
- **Konu:** `inventory.low_stock` · **Servis:** inventory (`services/inventory/main.go:142`)
- **Alıcı:** yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'inventory.low_stock%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-INVENTORY-ID-MOVEMENTS`

#### B-POST-CONSUMPTION-STATEMENTS- · `POST /consumption/statements/:id/objections`
- **Tetikleyen:** Sakin `energy_consumption_mobile_screen`
- **Konu:** `statement.objection` · **Servis:** iot (`services/iot/main.go:471`)
- **Alıcı:** onay yetkilileri (MANAGER, BOARD_MEMBER) (`Approvers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'statement.objection%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-CONSUMPTION-STATEMENTS-`

#### B-POST-CONSUMPTION-OBJECTIONS- · `POST /consumption/objections/:id/respond`
- **Tetikleyen:** Panel `/dashboard/meters`, Yön.mobil `meters_screen`
- **Konu:** `statement.objection.answer` · **Servis:** iot (`services/iot/main.go:473`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'statement.objection.answer%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-CONSUMPTION-OBJECTIONS-`

#### B-POST-PUBLIC-SENSORS-DATA · `POST /public/sensors/data`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** iot (`services/iot/sensors.go:127`)
- **Alıcı:** saha (MANAGER, BOARD_MEMBER, STAFF) (`Operations`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; GÖREVLİ → panel zil simgesi, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-PUBLIC-SENSORS-DATA`

#### B-POST-MARKET-REQUESTS · `POST /market/requests`
- **Tetikleyen:** Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:85`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-REQUESTS`

#### B-POST-MARKET-REQUESTS-ID-OFFE · `POST /market/requests/:id/offers/:offerId/select`
- **Tetikleyen:** Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:91`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-REQUESTS-ID-OFFE`

#### B-POST-MARKET-REQUESTS-ID-CLOS · `POST /market/requests/:id/close`
- **Tetikleyen:** Sakin `market_request_screens`, Yön.mobil `site_market_screens`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:92`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-REQUESTS-ID-CLOS`

#### B-POST-MARKET-REQUESTS-ID-MESS · `POST /market/requests/:id/messages/:dispatchId`
- **Tetikleyen:** Sakin `market_request_screens`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:94`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-REQUESTS-ID-MESS`

#### B-POST-MARKET-REQUESTS-ID-REVI · `POST /market/requests/:id/review`
- **Tetikleyen:** Sakin `market_request_screens`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:98`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-REQUESTS-ID-REVI`

#### B-POST-MARKET-SUPPLIER-REQUEST · `POST /market/supplier/requests/:id/offers`
- **Tetikleyen:** Panel `/tedarikci/(panel)/talepler/[id]`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:128`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-SUPPLIER-REQUEST`

#### B-POST-MARKET-SUPPLIER-REQUEST-2 · `POST /market/supplier/requests/:id/messages`
- **Tetikleyen:** Panel `/tedarikci/(panel)/talepler/[id]`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:131`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-SUPPLIER-REQUEST-2`

#### B-POST-MARKET-SUPPLIER-JOBS-ID · `POST /market/supplier/jobs/:id/done`
- **Tetikleyen:** Panel `/tedarikci/(panel)/talepler/[id]`
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:133`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-SUPPLIER-JOBS-ID`

#### B-POST-MARKET-SUPPLIER-PACKAGE · `POST /market/supplier/package`
- **Tetikleyen:** Panel `/tedarikci/(panel)/bakiye`
- **Konu:** `market.wallet.low` · **Servis:** marketplace (`services/marketplace/main.go:141`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'market.wallet.low%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-SUPPLIER-PACKAGE`

#### B-POST-MARKET-PLATFORM-ACCOUNT · `POST /market/platform/accounts/:id/approve`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:147`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-ACCOUNT`

#### B-POST-MARKET-PLATFORM-ACCOUNT-2 · `POST /market/platform/accounts/:id/reject`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:148`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-ACCOUNT-2`

#### B-POST-MARKET-PLATFORM-ACCOUNT-3 · `POST /market/platform/accounts/:id/suspend`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:149`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-ACCOUNT-3`

#### B-POST-MARKET-PLATFORM-ACCOUNT-4 · `POST /market/platform/accounts/:id/reinstate`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:150`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-ACCOUNT-4`

#### B-POST-MARKET-PLATFORM-ACCOUNT-5 · `POST /market/platform/accounts/:id/close`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:151`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-ACCOUNT-5`

#### B-POST-MARKET-PLATFORM-CARD-RE · `POST /market/platform/card-refunds/:id/manual`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:153`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-CARD-RE`

#### B-POST-MARKET-PLATFORM-CARD-RE-2 · `POST /market/platform/card-refunds/:id/retry`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:154`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-CARD-RE-2`

#### B-POST-MARKET-PLATFORM-BUSINES · `POST /market/platform/businesses/:id/approve`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:157`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-BUSINES`

#### B-POST-MARKET-PLATFORM-BUSINES-2 · `POST /market/platform/businesses/:id/reject`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:158`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-BUSINES-2`

#### B-POST-MARKET-PLATFORM-DISPUTE · `POST /market/platform/disputes/:id/approve`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:167`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-DISPUTE`

#### B-POST-MARKET-PLATFORM-DISPUTE-2 · `POST /market/platform/disputes/:id/reject`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `{topic}` · **Servis:** marketplace (`services/marketplace/main.go:168`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MARKET-PLATFORM-DISPUTE-2`

#### B-POST-MODERATION-PHOTOS-ID-AP · `POST /moderation/photos/:id/approve`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `market.photo.rejected` · **Servis:** moderation (`services/moderation/main.go:69`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'market.photo.rejected%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MODERATION-PHOTOS-ID-AP`

#### B-POST-MODERATION-PHOTOS-ID-RE · `POST /moderation/photos/:id/reject`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `market.photo.rejected` · **Servis:** moderation (`services/moderation/main.go:70`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'market.photo.rejected%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MODERATION-PHOTOS-ID-RE`

#### B-POST-MODERATION-PHOTOS-ID-RE-2 · `POST /moderation/photos/:id/recheck`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `market.photo.rejected` · **Servis:** moderation (`services/moderation/main.go:71`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'market.photo.rejected%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-MODERATION-PHOTOS-ID-RE-2`

#### B-POST-NOTIFICATIONS · `POST /notifications`
- **Tetikleyen:** Panel `/dashboard/notifications`, Yön.mobil `notification_center_screen`
- **Konu:** `{{in}.Topic}` · **Servis:** notification (`services/notification/main.go:158`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-NOTIFICATIONS`

#### B-POST-PACKAGES · `POST /packages`
- **Tetikleyen:** Panel `/dashboard/packages`, Yön.mobil `package_tracking_screen`
- **Konu:** `package.received` · **Servis:** package (`services/package/main.go:133`)
- **Alıcı:** ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'package.received%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-PACKAGES`

#### B-POST-PUBLIC-DEVICES-HEARTBEA · `POST /public/devices/heartbeat`
- **Tetikleyen:** arayüzde düğmesi yok (5. bölüm) — yalnız başka bir işlemin parçası olarak tetiklenir
- **Konu:** `?` · **Servis:** parking (`services/parking/devices.go:37`)
- **Alıcı:** saha (MANAGER, BOARD_MEMBER, STAFF) (`Operations`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; GÖREVLİ → panel zil simgesi, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** DENETÇİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE '%%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-PUBLIC-DEVICES-HEARTBEA`

#### B-POST-PATROLS-ID-COMPLETE · `POST /patrols/:id/complete`
- **Tetikleyen:** Yön.mobil `patrol_run_screen`
- **Konu:** `patrol.issue` · **Servis:** patrol (`services/patrol/main.go:179`)
- **Alıcı:** yönetim (MANAGER, BOARD_MEMBER, AUDITOR) (`Managers`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; DENETÇİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler
- **Görmemesi gerekenler:** GÖREVLİ, KİRACI, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'patrol.issue%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-PATROLS-ID-COMPLETE`

#### B-POST-RESERVATIONS-ID-APPROVE · `POST /reservations/:id/approve`
- **Tetikleyen:** Panel `/dashboard/reservations`, Yön.mobil `reservation_management_screen`
- **Konu:** `reservation.decision` · **Servis:** reservation (`services/reservation/main.go:283`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'reservation.decision%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESERVATIONS-ID-APPROVE`

#### B-POST-RESERVATIONS-ID-REJECT · `POST /reservations/:id/reject`
- **Tetikleyen:** Panel `/dashboard/reservations`, Yön.mobil `reservation_management_screen`
- **Konu:** `reservation.decision` · **Servis:** reservation (`services/reservation/main.go:296`)
- **Alıcı:** işlemin muhatabı olan kişi (tek kişi) ya da doğrudan girilen telefon/e-posta
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'reservation.decision%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-RESERVATIONS-ID-REJECT`

#### B-POST-SETTINGS-OWNER-VISIBILI · `POST /settings/owner-visibility/:id/approve`
- **Tetikleyen:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Konu:** `visibility.policy` · **Servis:** settings (`services/settings/main.go:146`)
- **Alıcı:** sitenin kiracıları (`Tenants`)
- **Görmesi gerekenler:** KİRACI → Sakin uygulaması Bildirimler (zil)
- **Görmemesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visibility.policy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-SETTINGS-OWNER-VISIBILI`

#### B-POST-SETTINGS-OWNER-VISIBILI-2 · `POST /settings/owner-visibility/:id/reject`
- **Tetikleyen:** Panel `/dashboard/settings`, Yön.mobil `site_settings_screen`
- **Konu:** `visibility.policy` · **Servis:** settings (`services/settings/main.go:147`)
- **Alıcı:** sitenin kiracıları (`Tenants`)
- **Görmesi gerekenler:** KİRACI → Sakin uygulaması Bildirimler (zil)
- **Görmemesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ, GÖREVLİ, MALİK_A4, MALİK_B1, VEKİL_B1 ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visibility.policy%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-SETTINGS-OWNER-VISIBILI-2`

#### B-POST-SURVEYS-ID-PUBLISH · `POST /surveys/:id/publish`
- **Tetikleyen:** Panel `/dashboard/surveys`, Yön.mobil `survey_management_screen`
- **Konu:** `survey.published` · **Servis:** survey (`services/survey/main.go:195`)
- **Alıcı:** sitenin bütün aktif sakinleri (`Residents`)
- **Görmesi gerekenler:** YÖNETİCİ → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KURUL → panel zil simgesi + `/dashboard/inbox`, Yön.mobil Bildirimler; KİRACI → Sakin uygulaması Bildirimler (zil); MALİK_A4 → Sakin uygulaması Bildirimler (zil); MALİK_B1 → Sakin uygulaması Bildirimler (zil); VEKİL_B1 → Sakin uygulaması Bildirimler (zil)
- **Görmemesi gerekenler:** DENETÇİ, GÖREVLİ ve her durumda SİTE_B
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'survey.published%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-SURVEYS-ID-PUBLISH`

#### B-POST-VISITORS-VERIFY-PASS · `POST /visitors/verify-pass`
- **Tetikleyen:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Konu:** `visitor.checkin` · **Servis:** visitor (`services/visitor/main.go:174`)
- **Alıcı:** ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VISITORS-VERIFY-PASS`

#### B-POST-VISITORS-ID-CHECK-IN · `POST /visitors/:id/check-in`
- **Tetikleyen:** Panel `/dashboard/visitors`, Yön.mobil `visitor_management_screen`
- **Konu:** `visitor.checkin` · **Servis:** visitor (`services/visitor/main.go:175`)
- **Alıcı:** ilgili dairenin kullanıcıları (kiracılı dairede yalnız kiracı; kiracısızda malik ve vekil) (`UnitUsers`)  
      Örnek: A-4 için kiracı KİRACI, malik MALİK_A4; B-1 için malik MALİK_B1 ve vekil VEKİL_B1; A-3 için YÖNETİCİ; B-2 için KURUL.
- **Sorgu:** `SELECT n.created_at, n.topic, n.channel, n.status, n.recipient_address, u.first_name || ' ' || u.last_name AS alici, n.subject FROM notifications n LEFT JOIN users u ON u.id = n.recipient_user_id WHERE n.topic LIKE 'visitor.checkin%' ORDER BY n.created_at DESC LIMIT 30;`
- **Beklenen:** alıcı başına kanal satırları (`IN_APP` her zaman; SMS/EMAIL konuya ve tercihe göre); metin Türkçe, kişisel veriyi gereğinden fazla taşımaz (ör. kargo bildiriminde takip numarası yok); aynı olay iki kez bildirilmez
- **Sonuç:** `B-POST-VISITORS-ID-CHECK-IN`

## 6.3 Zamanlanmış işler (`cmd/scheduler`, test ortamında dakikada bir)

Koşulu arayüzden oluşturun, **en az 1 dakika** bekleyin, sonra bildirimleri ve zamanlayıcı günlüğünü (http://localhost:18000/gunluk?s=scheduler) kontrol edin. Aynı koşul ikinci turda yeniden bildirim üretmemeli (DedupeKey).

#### B-ZAMAN-DUES-OVERDUE · `dues.overdue`
- **Koşulu oluştur:** Vadesi geçmiş, ödenmemiş aidat (seed'de geçmiş aylar var; yoksa Aidat sayfasından son ödeme tarihi geçmiş tahakkuk)
- **Alıcı:** borcun sorumlusu; kiracı sorumluysa malik de ayrıca (`dues.overdue.tenant`) · **Görmesi gerekenler:** KİRACI ve MALİK_A4 (A-4), YÖNETİCİ (A-3) — dairesine göre
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'dues.overdue%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-DUES-OVERDUE`

#### B-ZAMAN-CONTRACT-NOTICE · `contract.notice`
- **Koşulu oluştur:** Sözleşmeler: bitişi yakın sözleşme ekle — bitiş tarihi bugünden 30 gün sonra, ihbar süresi 30 gün (ihbar son günü 14 gün içinde kalmalı)
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'contract.notice%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-CONTRACT-NOTICE`

#### B-ZAMAN-CONTRACT-EXPIRED · `contract.expired`
- **Koşulu oluştur:** Sözleşmeler: bitiş tarihi dün olan ve durumu ACTIVE sözleşme ekle
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'contract.expired%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-CONTRACT-EXPIRED`

#### B-ZAMAN-PATROL-OVERDUE · `patrol.overdue`
- **Koşulu oluştur:** Devriye: bir tur başlat (Yön.mobil, GÖREVLİ) ve beklenen süre + toleransı aşacak kadar açık bırak (rota süresi 2 dk, tolerans 1 dk yapılabilir)
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'patrol.overdue%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-PATROL-OVERDUE`

#### B-ZAMAN-ASSET-MAINTENANCE · `asset.maintenance`
- **Koşulu oluştur:** Demirbaş: sonraki bakım tarihi 14 gün içinde ya da geçmiş demirbaş ekle
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'asset.maintenance%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-ASSET-MAINTENANCE`

#### B-ZAMAN-KVKK-DUE · `kvkk.due`
- **Koşulu oluştur:** KVKK başvurusu (sakin uygulaması) — yanıt süresi 5 gün içinde dolan açık başvuru gerekir; yeni başvuru 30 gün sürelidir, bu yüzden genelde ATLANDI (zaman gerektirir). Not düş.
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'kvkk.due%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-KVKK-DUE`

#### B-ZAMAN-BUDGET-APPROVAL · `budget.approval`
- **Koşulu oluştur:** Yönetişim: geçici işletme projesini bildir (NOTIFIED); genel kurul onay son günü yakınsa uyarır — tarih yakın değilse ATLANDI
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'budget.approval%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-BUDGET-APPROVAL`

#### B-ZAMAN-EMERGENCY-DRILL · `emergency.drill`
- **Koşulu oluştur:** Acil durum: hiç tatbikat kaydı yokken personel kaydı ekle (Personel sayfası)
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'emergency.drill%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-EMERGENCY-DRILL`

#### B-ZAMAN-COMPLIANCE-EMPLOYER · `compliance.employer`
- **Koşulu oluştur:** Ayarlar: MUHSGK takvimi açık; personel işe giriş/çıkış SGK süresi 5 gün içinde olan kayıt
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'compliance%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-COMPLIANCE-EMPLOYER`

#### B-ZAMAN-KVKK-DESTRUCTION · `kvkk.destruction`
- **Koşulu oluştur:** Ayarlar → saklama süreleri: süre tanımsızsa hatırlatma; süre tanımlı ve süresi dolmuş kayıt varsa anonimleştirme
- **Alıcı:** yönetim · **Görmesi gerekenler:** YÖNETİCİ, KURUL, DENETÇİ
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'kvkk.destruction%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-KVKK-DESTRUCTION`

#### B-ZAMAN-DASK-RENEWAL · `dask.renewal`
- **Koşulu oluştur:** Sigorta: bitişi 30 gün içinde olan DASK poliçesi gir (ör. B-1)
- **Alıcı:** dairenin malik/vekili · **Görmesi gerekenler:** MALİK_B1, VEKİL_B1
- **Sorgu:** `SELECT created_at, topic, channel, status, recipient_address, subject, dedupe_key FROM notifications WHERE topic LIKE 'dask%' ORDER BY created_at DESC LIMIT 30;`
- **Beklenen:** 1-2 dk içinde bildirim; aynı `dedupe_key` ile ikinci satır YOK; metin tarihleri gg.aa.yyyy biçiminde
- **Sonuç:** `B-ZAMAN-DASK-RENEWAL`

#### B-ZAMAN-ACTIVITY-PURGE · `activity.purge`
- **Koşulu oluştur:** Bildirim üretmez; saklama süresi dolan istemci etkinlik kayıtlarını siler
- **Alıcı:** — · **Görmesi gerekenler:** —
- **Beklenen:** zamanlayıcı günlüğünde iş hatasız çalışmış (`[scheduler]` satırları); silinmemesi gereken kayıtlar duruyor
- **Sonuç:** `B-ZAMAN-ACTIVITY-PURGE`

#### B-ZAMAN-SENSOR-PURGE · `sensor.purge`
- **Koşulu oluştur:** Bildirim üretmez; 365 günden eski sensör okumalarını siler (cihaz simülatöründe eski tarihli okuma gönderilerek denenebilir)
- **Alıcı:** — · **Görmesi gerekenler:** —
- **Beklenen:** zamanlayıcı günlüğünde iş hatasız çalışmış (`[scheduler]` satırları); silinmemesi gereken kayıtlar duruyor
- **Sonuç:** `B-ZAMAN-SENSOR-PURGE`

#### B-ZAMAN-PATROL-TRACK-PURGE · `patrol.track.purge`
- **Koşulu oluştur:** Bildirim üretmez; 1 yıldan eski devriye konum izini siler
- **Alıcı:** — · **Görmesi gerekenler:** —
- **Beklenen:** zamanlayıcı günlüğünde iş hatasız çalışmış (`[scheduler]` satırları); silinmemesi gereken kayıtlar duruyor
- **Sonuç:** `B-ZAMAN-PATROL-TRACK-PURGE`

## 6.4 Servis içi bekçiler

#### B-BEKCI-SENSOR · Sensör sinyal kesintisi
- **Hesap:** YÖNETİCİ (panel Sensörler) + cihaz simülatörü
- **Adım:** Panelde sensör ekle (çevrimdışı sayılma süresi 2 dk); gösterilen cihaz anahtarını kopyala; http://localhost:18000/cihaz ile bir okuma gönder; 3 dk bekle
- **Beklenen:** önce sensör ÇEVRİMİÇİ ve okuma listede; süre dolunca OFFLINE alarmı açılır, `iot.offline` bildirimi YÖNETİCİ, KURUL, GÖREVLİ'ye gider; yeni okuma gelince alarm kapanır/iyileşir
- **Sorgu:** `SELECT kind, status, opened_at, closed_at FROM sensor_alerts ORDER BY xmin::text::bigint DESC LIMIT 5;`
- **Sonuç:** `B-BEKCI-SENSOR`

#### B-BEKCI-ESIK · Sensör eşik aşımı
- **Adım:** Sıcaklık sensörüne üst eşik 30 ver; simülatörden 45 gönder; sonra 25 gönder
- **Beklenen:** HIGH alarmı açılır ve bildirim gider; normal değer alarmı kendiliğinden kapatmaz (yönetici onaylar/kapatır) — ekrandaki davranışı gözleme yaz
- **Sonuç:** `B-BEKCI-ESIK`

#### B-BEKCI-CIHAZ · Geçiş cihazı canlılığı
- **Hesap:** YÖNETİCİ (panel Otopark → geçiş cihazları) + cihaz simülatörü (tür: geçiş cihazı)
- **Adım:** Cihaz ekle; anahtarla bir sinyal gönder; sinyali kes ve bekle (30 sn aralıkla denetlenir, cihazın tolerans süresi kadar); sonra yeniden sinyal gönder
- **Beklenen:** sinyal kesilince olay açılır ve `device.offline` (YÖNETİCİ, KURUL, GÖREVLİ); sinyal gelince `device.recovered`
- **Sonuç:** `B-BEKCI-CIHAZ`

#### B-BEKCI-KART · Kart ödemesi uzlaştırma
- **Hesap:** KİRACI (sakin uygulaması)
- **Adım:** Kartla ödeme başlat; sahte iyzico sayfasında "Yarıda bırak" seç; 20+ dk sonra (ya da ödemeyi başarıyla tamamlamadan bırakıp) ödeme durumuna bak
- **Beklenen:** ödeme askıda sonsuza kadar kalmaz; uzlaştırma bekçisi sonucu sahte iyzico'dan yeniden sorgular (iyzico kayıtlarında `detail` çağrıları)
- **Sonuç:** `B-BEKCI-KART`

#### B-BEKCI-KARGO · Kargo kanıtı imhası
- **Adım:** Teslim kanıtı (imza/fotoğraf) olan kargo kaydının saklama süresi dolunca/silinince kanıt dosyası depodan silinir — 15 dk'da bir
- **Beklenen:** `SELECT count(*) FROM storage_deletion_queue;` işlendikten sonra azalır; genelde ATLANDI (süre gerektirir)
- **Sonuç:** `B-BEKCI-KARGO`
