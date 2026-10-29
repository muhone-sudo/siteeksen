# 1. Oturum, hesap ve kimlik

> Elle yazılır. Giriş, etkinleştirme, şifre/telefon/e-posta değişikliği, çıkış, jeton yenileme, site değiştirme.
> Bu akışlar istemcilerde ortak koddan geçtiği için sayfa bölümlerinde ayrıca yer almaz. Hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

## 1.1 Giriş

#### O-GIRIS-01 · Panele doğru bilgilerle giriş
- **Hesap:** YÖNETİCİ · **Nerede:** http://localhost:3001/login
- **Adım:** Telefona `5551234567`, şifreye `Demo123!` yaz, giriş yap
- **Beklenen:** `/dashboard` açılır; üst barda kişi adı; kenar çubuğunda site seçici "Güneş Sitesi"; zil simgesi görünür
- **Veritabanı:** Q-AUDIT → `source = API`, `entity_type = auth`, giriş satırı 200
- **Sonuç:** `O-GIRIS-01`

#### O-GIRIS-02 · Telefon biçimleri
- **Hesap:** YÖNETİCİ · **Nerede:** panel giriş, sakin uygulaması giriş (http://localhost:3002)
- **Adım:** Sırayla `05551234567`, `+905551234567`, `0555 123 45 67` ile giriş dene (her denemeden sonra çıkış yap)
- **Beklenen:** üçü de aynı hesaba girer
- **Sonuç:** `O-GIRIS-02`

#### O-GIRIS-03 · Yanlış şifre
- **Hesap:** KURUL · **Nerede:** panel giriş
- **Adım:** `5550000001` / `YanlisSifre1` ile giriş dene
- **Beklenen:** "Telefon numarası veya şifre hatalı" anlamında mesaj; hangi alanın yanlış olduğu söylenmez; oturum açılmaz
- **Veritabanı:** Q-AUDIT → giriş satırı 401
- **Sonuç:** `O-GIRIS-03`

#### O-GIRIS-04 · Kayıtlı olmayan numara
- **Hesap:** — · **Nerede:** panel giriş
- **Adım:** `5329998877` / `Demo123!`
- **Beklenen:** O-GIRIS-03 ile **aynı** mesaj (numaranın kayıtlı olup olmadığı belli edilmez)
- **Sonuç:** `O-GIRIS-04`

#### O-GIRIS-05 · Kademeli giriş kilidi
- **Hesap:** VEKİL_B1 (5550000012) · **Nerede:** sakin uygulaması giriş
- **Adım:** 4 kez yanlış şifre gir; 5. yanlış denemeyi yap; hemen doğru şifreyle dene; 30 sn bekleyip doğru şifreyle gir
- **Beklenen:** 5. hatadan sonra "… saniye sonra yeniden deneyin" türü bekleme mesajı ve doğru şifre de reddedilir; 30 sn sonra giriş olur. (6. hata 2 dk, 7. ve sonrası 15 dk)
- **Sonuç:** `O-GIRIS-05`

#### O-GIRIS-06 · Yönetimin giriş kilidini kaldırması
- **Hesap:** VEKİL_B1, sonra YÖNETİCİ · **Nerede:** sakin uygulaması; panel `/dashboard/residents`
- **Adım:** VEKİL_B1 ile 7 kez yanlış şifre gir (15 dk kilit); YÖNETİCİ panelde Ali Çelik satırında **Kilidi aç**; VEKİL_B1 doğru şifreyle gir
- **Beklenen:** kilit hemen kalkar, giriş olur
- **Veritabanı:** Q-AUDIT → `POST /residents/:id/unlock` 200
- **Sonuç:** `O-GIRIS-06`

#### O-GIRIS-07 · Sakin panele giremez
- **Hesap:** KİRACI · **Nerede:** http://localhost:3001/login
- **Adım:** KİRACI bilgileriyle panele giriş yap
- **Beklenen:** panel sayfaları açılmaz (`/dashboard/forbidden` ya da girişte yönetim yetkisi olmadığı mesajı); hiçbir yönetim verisi görünmez
- **Sonuç:** `O-GIRIS-07`

#### O-GIRIS-08 · Yönetici uygulamasına sakin girişi
- **Hesap:** KİRACI · **Nerede:** http://localhost:3003
- **Adım:** Giriş yap
- **Beklenen:** yönetim yetkisi olmadığı anlaşılır şekilde söylenir; yönetim menüleri görünmez
- **Sonuç:** `O-GIRIS-08`

#### O-GIRIS-09 · KVKK aydınlatma/onay (ilk giriş)
- **Hesap:** MALİK_B1 · **Nerede:** sakin uygulaması
- **Adım:** İlk girişte KVKK ekranı çıkarsa metni oku, onayla; çıkış yapıp yeniden gir
- **Beklenen:** onaydan sonra ana ekran; ikinci girişte KVKK ekranı yeniden çıkmaz
- **Veritabanı:** `SELECT phone, kvkk_consent_at FROM users WHERE phone = '+905550000011';` → dolu
- **Sonuç:** `O-GIRIS-09`

#### O-GIRIS-10 · Biyometrik giriş web'de yok
- **Hesap:** KİRACI · **Nerede:** sakin ve yönetici uygulaması giriş ekranı
- **Beklenen:** biyometrik giriş düğmesi/önerisi görünmez, hata da çıkmaz (web derlemesi)
- **Sonuç:** `O-GIRIS-10`

## 1.2 Hesap etkinleştirme (yeni sakin)

#### O-ETKIN-01 · Yönetimin eklediği sakin kodu SMS ve e-postayla alır
- **Hesap:** YÖNETİCİ · **Nerede:** panel `/dashboard/residents` → Sakin ekle
- **Adım:** Ad `TEST`, soyad `Sakin Bir`, telefon `5550000031`, e-posta `5550000031@siteeksen.test`, daire **B-3**, sıfat **OWNER** ile ekle
- **Beklenen:** pencerede tek kullanımlık **etkinleştirme kodu** bir kez gösterilir; "SMS ile gönderildi" ve "e-postayla gönderildi" durumları yazar; not metni kodun SMS/e-postayla ulaşmazsa elden iletilmesini söyler (SMS bağlı değil DEMEZ)
- **Bildirim:** SMS kutusunda 5550000031'e kodlu mesaj; Mailpit'te 5550000031@siteeksen.test'e e-posta; ikisindeki kod pencereyle aynı
- **Veritabanı:** Q-KISI → B-3 satırı; `SELECT purpose, expires_at, used_at, failed_attempts FROM user_activation_codes ORDER BY created_at DESC LIMIT 3;` (kodun kendisi DEĞİL, özeti saklanır)
- **Sonuç:** `O-ETKIN-01`

#### O-ETKIN-02 · Kodu yanlış girme
- **Hesap:** yeni sakin · **Nerede:** http://localhost:3001/activate (ve sakin uygulamasında "Hesabımı etkinleştir")
- **Adım:** Telefon 5550000031, kod `AAAAAAAA`, şifre `Yeni1234`
- **Beklenen:** kod geçersiz mesajı; 5 hatalı denemede kodun kilitlendiği söylenir (5. denemeyi yapmadan bırak)
- **Sonuç:** `O-ETKIN-02`

#### O-ETKIN-03 · Şifre kuralları
- **Adım:** Doğru kodla şifre olarak `kisa`, `sadeceharf`, `12345678`, `5550000031a` dene
- **Beklenen:** her biri reddedilir: en az 8 karakter, en az bir harf ve bir rakam, telefon numarasını içeremez; şifreler aynı değilse "Şifreler aynı değil"
- **Sonuç:** `O-ETKIN-03`

#### O-ETKIN-04 · Doğru kodla etkinleştirme ve giriş
- **Adım:** Doğru kod + `Deneme123` ile şifre belirle; sakin uygulamasında 5550000031 / `Deneme123` ile gir
- **Beklenen:** "Şifreniz belirlendi" mesajı; giriş olur, B-3 sakini olarak ana ekran; aynı kod ikinci kez kullanılamaz
- **Sonuç:** `O-ETKIN-04`

#### O-ETKIN-05 · Kod yeniden üretme
- **Hesap:** YÖNETİCİ · **Nerede:** panel sakinler → TEST Sakin Bir → **Kod üret**
- **Beklenen:** yeni kod gösterilir ve SMS/e-posta gider; eski kod artık geçersizdir (denersen reddedilir)
- **Sonuç:** `O-ETKIN-05`

## 1.3 Şifremi unuttum

#### O-SIFRE-01 · Sakinin kendi kod isteği
- **Hesap:** MALİK_B1 · **Nerede:** sakin uygulaması giriş → şifremi unuttum (ya da http://localhost:3001/activate → kodu SMS ile gönder)
- **Adım:** 5550000011 için kod iste; SMS kutusundan kodu al; yeni şifre `Fatma1234` belirle; yeni şifreyle gir; sonra şifreyi yine `Demo123!` yap (O-SIFRE-03 ile)
- **Beklenen:** yanıt numaranın kayıtlı olup olmadığını söylemez; SMS (ve e-posta) gelir; kod 15 dk geçerli; şifre değişince **açık bütün oturumlar kapanır** (başka sekmede açık oturum giriş ekranına düşer)
- **Sonuç:** `O-SIFRE-01`

#### O-SIFRE-02 · Kayıtsız numaraya kod isteği
- **Adım:** 5329998877 için kod iste
- **Beklenen:** O-SIFRE-01 ile aynı genel yanıt; SMS kutusuna mesaj DÜŞMEZ
- **Sonuç:** `O-SIFRE-02`

#### O-SIFRE-03 · Oturum içinden şifre değiştirme
- **Hesap:** KURUL (panel `/dashboard/account`), MALİK_B1 (sakin profil)
- **Adım:** Yanlış mevcut şifreyle dene; sonra doğru mevcut şifre + yeni şifre; sonra eski şifreye geri dön
- **Beklenen:** yanlış mevcut şifre reddedilir; başarıda "bütün cihazlardaki oturumlarınız kapatılır" uyarısı ve giriş ekranına yönlendirme; yeni şifreyle giriş olur
- **Sonuç:** `O-SIFRE-03`

## 1.4 Telefon ve e-posta değişikliği

#### O-TEL-01 · Kendi telefonunu değiştirme
- **Hesap:** KURUL · **Nerede:** panel `/dashboard/account` → Telefon numarası
- **Adım:** Mevcut şifre + yeni numara `5550000041` → "Yeni numaraya kod gönder"; SMS kutusunda 5550000041'e gelen kodu gir → Onayla; yeni numarayla giriş yap; aynı yolla `5550000001`'e geri dön
- **Beklenen:** kod yalnız yeni numaraya gider; onayla numara değişir, oturumlar kapanır, eski numaraya bilgilendirme gider; eski numarayla giriş olmaz
- **Veritabanı:** `SELECT phone FROM users WHERE first_name = 'Zeynep';`
- **Sonuç:** `O-TEL-01`

#### O-TEL-02 · Yönetimin sakin telefonunu değiştirmesi
- **Hesap:** YÖNETİCİ · **Nerede:** panel sakinler → TEST Sakin Bir → **Telefon**
- **Adım:** Numarayı `5550000032` yap
- **Beklenen:** kişinin oturumları kapanır; yeni numaraya bilgi/kod gider; kişi yeni numarayla girer
- **Sonuç:** `O-TEL-02`

#### O-EPOSTA-01 · E-posta değişikliği
- **Hesap:** KURUL · **Nerede:** panel `/dashboard/account` → E-posta adresi (sakin uygulamasında da profil)
- **Adım:** Mevcut şifre + `zeynep.yeni@siteeksen.test` → kod gönder; Mailpit'teki kodu gir → Onayla
- **Beklenen:** kod yalnız yeni adrese gider; onayla adres değişir
- **Sonuç:** `O-EPOSTA-01`

## 1.5 Çıkış ve oturum

#### O-CIKIS-01 · Panelden çıkış jetonu iptal eder
- **Hesap:** YÖNETİCİ · **Nerede:** üst bar kullanıcı menüsü → Çıkış Yap
- **Adım:** Çıkış yap; tarayıcının geri düğmesiyle `/dashboard`'a dönmeyi dene
- **Beklenen:** giriş ekranı; geri gelince veri yüklenmez, girişe yönlenir
- **Veritabanı:** `SELECT count(*) FROM revoked_tokens;` çıkıştan sonra artmış
- **Sonuç:** `O-CIKIS-01`

#### O-CIKIS-02 · Sakin uygulamasından çıkış
- **Hesap:** KİRACI · **Nerede:** sakin uygulaması → Profil → Çıkış Yap
- **Beklenen:** onay penceresi ("emin misiniz"); İptal → bir şey olmaz; onayla → giriş ekranı; geri tuşu oturumu geri getirmez
- **Sonuç:** `O-CIKIS-02`

#### O-CIKIS-03 · Tüm cihazlardan çıkış
- **Hesap:** KİRACI · **Nerede:** iki ayrı pencerede sakin uygulaması (biri gizli pencere)
- **Adım:** İki pencerede de gir; birinde Profil → **Tüm cihazlardan çıkış** → Hepsini kapat; öteki pencerede bir ekrana geç/yenile
- **Beklenen:** iki pencere de girişe düşer (öteki en geç bir sonraki istekte)
- **Sonuç:** `O-CIKIS-03`

#### O-OTURUM-01 · Jeton yenileme (15 dk)
- **Hesap:** YÖNETİCİ · **Nerede:** panel
- **Adım:** Giriş yap; 16+ dk bekle (başka testlere devam edebilirsin); sonra panelde bir sayfa aç
- **Beklenen:** oturum düşmeden veri yüklenir (yenileme jetonuyla sessizce yenilendi)
- **Sonuç:** `O-OTURUM-01`

#### O-OTURUM-02 · Görevi biten kişinin oturumu kapanır
- **Hesap:** YÖNETİCİ, GÖREVLİ · **Nerede:** panel `/dashboard/roles`
- **Adım:** GÖREVLİ başka pencerede panelde açıkken YÖNETİCİ Murat Öz'ün görevini sonlandırır; GÖREVLİ sayfayı yeniler; sonra YÖNETİCİ görevi yeniden verir (yeni görev kaydı)
- **Beklenen:** GÖREVLİ girişe düşer ve panel sayfalarına giremez; yeniden görev verilince tekrar girer
- **Sonuç:** `O-OTURUM-02`

## 1.6 Site seçimi ve yeni site

#### O-SITE-01 · Site değiştirme
- **Hesap:** YÖNETİCİ · **Nerede:** kenar çubuğu site seçici
- **Adım:** Deniz Apartmanı (Test B)'ye geç; Sakinler'e bak; Güneş Sitesi'ne dön
- **Beklenen:** geçişte `/dashboard`'a döner; Deniz Apartmanı'nda yalnız Elif Yurt ve 2 bölüm; dönüşte Güneş Sitesi verisi
- **Sonuç:** `O-SITE-01`

#### O-SITE-02 · Yeni taşınmaz ekleme
- **Hesap:** YÖNETİCİ · **Nerede:** kenar çubuğu → + Yeni Taşınmaz Ekle
- **Adım:** Önce boş gönder; sonra Ad `TEST Kule`, Adres `Deneme Sok. 1`, Şehir `Ankara`, Tür `Bina` ile ekle; sonra Güneş Sitesi'ne dön
- **Beklenen:** zorunlu alan uyarıları; eklenince yeni siteye geçer, boş site (bölüm yok) uyarıları anlamlı; site seçicide üç site
- **Veritabanı:** `SELECT id, name, city FROM properties ORDER BY created_at DESC LIMIT 3;` ve Q-ROL (kurucu MANAGER olarak yazılmış)
- **Sonuç:** `O-SITE-02`

#### O-SITE-03 · Başkasının sitesine geçilemez
- **Hesap:** SİTE_B · **Nerede:** sakin uygulaması
- **Beklenen:** site seçicide yalnız Deniz Apartmanı; Güneş Sitesi seçeneği yok (izolasyon bölüm 2.4'te ayrıntılı)
- **Sonuç:** `O-SITE-03`

## 1.7 Herkese açık sayfalar

#### O-ACIK-01 · Borcu yoktur belgesinin doğrulanması
- **Hesap:** MALİK_B1 (sakin uygulaması), sonra oturumsuz tarayıcı
- **Adım:** Aidat ekranında **Borcu yoktur belgesi** al (borç varsa önce 08 senaryosunda ödeme yap ya da belgenin neden verilmediğini not et); PDF'teki doğrulama kodunu/karekod adresini oturumsuz pencerede `http://localhost:3001/dogrula/<kod>` olarak aç
- **Beklenen:** sayfa yalnız site adı, bölüm ve tarihi gösterir (kişisel veri yok); uydurma kodla açınca "geçersiz/bulunamadı"
- **Sonuç:** `O-ACIK-01`

#### O-ACIK-02 · Yetkisiz sayfa
- **Hesap:** GÖREVLİ · **Nerede:** http://localhost:3001/dashboard/personnel
- **Beklenen:** `/dashboard/forbidden`: kişinin rolleri ve sayfanın gerektirdiği roller yazar; "Panele dön" bağlantısı çalışır; sonsuz yönlendirme yok
- **Sonuç:** `O-ACIK-02`
