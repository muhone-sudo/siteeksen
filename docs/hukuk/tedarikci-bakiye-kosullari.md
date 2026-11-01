# Usta & Hizmet — Tedarikçi Bakiye ve İade Koşulları

> **TASLAK — yayına hazır değil.** Avukat onayı gerekir (FAZ M0.4). Bu metin tedarikçiye ilk bakiye yüklemesinden önce
> **ayrıca** gösterilir ve kabul ettirilir; kabulün sürümü, metnin SHA-256 özeti, tarihi ve IP adresi kaydedilir
> (`mp_terms_acceptances`, migration 081). Uygulamadaki metin `backend/services/marketplace/store/terms.go` içindedir;
> iki metin **birebir aynı** olmalıdır (verify-stack, bu dosyadaki metni API'nin döndürdüğü metinle karşılaştırır). Metin değişirse sürüm
> değişir ve sonraki yüklemeden önce yeniden kabul istenir.

**Sürüm:** 2026-11-01

## Metin

1. Bakiye, yalnız SiteEksen Usta & Hizmet platformunun hizmet bedellerinde (paket aidatı ve talep kabul ücreti) kullanılır. Bakiye nakde çevrilemez, başka bir hesaba devredilemez, faiz ya da getiri işlemez.

2. Üyelik herhangi bir nedenle (tedarikçinin talebi ya da platformun üyeliği sona erdirmesi) sona erdiğinde kalan bakiye, sona erme tarihinden geriye doğru son 365 gün içinde kartla yapılmış yüklemelerden karşılanan kısmı kadar, yüklemenin yapıldığı karta ödeme kuruluşu aracılığıyla kendiliğinden iade edilir. Kalan bakiye, en yeni yüklemeden başlanarak eskiye doğru yüklemelerle eşleştirilir; bir yüklemeden en çok o yüklemenin tutarı kadar iade yapılır.

3. Sona erme tarihinde 365 günden eski yüklemelerden karşılanan kalan bakiye iade edilmez ve hesaptan düşülür. Bu sınır, ödeme kuruluşunun bir ödemeyi karta iade edebildiği en uzun süredir.

4. Üyelik sona erdikten sonra sonuçlanan bir kart yüklemesi hesaba yazılmaz; tutarın tamamı karta iade edilir.

5. Karta iade teknik bir nedenle yapılamazsa platform, tedarikçinin bildireceği kendi adına kayıtlı banka hesabına iade tutarını havaleyle öder.

6. İadenin karta yansıma süresi kartı veren bankaya bağlıdır. Platform, iade talimatını ödeme kuruluşuna ilettiği tarihi ve sonucunu tedarikçinin hesabında gösterir.

7. Bu koşullar ilk bakiye yüklemesinden önce ayrıca gösterilir ve kabul edilmeden bakiye yüklenemez. Kabul tarihi ve metnin sürümü kaydedilir. Koşullar değişirse sonraki yüklemeden önce yeniden kabul istenir.

## Hukuki dayanak ve avukatın bakması gereken noktalar

1. **Lisans gerekmemesi (6493 sayılı Kanun):** Bakiye yalnız SiteEksen'in kendi hizmet bedellerinde kullanılır, nakde çevrilemez,
   devredilemez. Bu nitelik, yalnız ihraç edenin kendi mal ve hizmetlerinde kullanılabilen ön ödemeli araçlar için öngörülen
   kapsam dışı durumuna (6493 m.18/5 ve Ödeme Hizmetleri Yönetmeliği) dayanır; elektronik para sayılmaz, kanuni fon iadesi
   yükümlülüğü doğmaz. Kapsam dışı işlem hacmi son 12 ayda 50 milyon TL'yi aşarsa her yıl Ocak ayında TCMB'ye rapor verilmesi
   gerekebilir (Yönetmelik m.82) — **doğrulanacak**.
2. **Tüketici hukuku:** Tedarikçiler mesleki/ticari amaçla işlem yaptığı için 6502 sayılı Kanun anlamında tüketici değildir.
   Tacir olmayan esnaf ve serbest meslek erbabı için bu nitelendirme **avukatça teyit edilmelidir**.
3. **Genel işlem koşulu (TBK m.20–25):** Madde önceden hazırlanmış ve tek taraflı belirlenmiş olduğundan genel işlem koşuludur.
   - m.21: karşı tarafa açıkça bildirilmesi ve içeriğini öğrenme imkânı verilmesi, ayrıca kabul edilmesi gerekir — bu yüzden
     ilk yüklemeden önce ayrı kutuyla kabul ettirilir ve kayıt tutulur.
   - m.25: dürüstlük kuralına aykırı olarak karşı taraf aleyhine hüküm konamaz. **Risk:** 365 günü geçen bakiyenin iade
     edilmemesi, özellikle üyeliği platformun (tedarikçinin kusuru olmadan) sona erdirdiği durumda m.25 ve sebepsiz
     zenginleşme (TBK m.77) açısından tartışılabilir. Seçenekler: (a) madde olduğu gibi kalır; (b) platformun kusursuz
     feshinde 365 gün sınırı uygulanmaz, kalan bakiye havaleyle ödenir. Karar kullanıcı ve avukatındır.
4. **365 günün gerekçesi:** Ödeme kuruluşu (iyzico) bir ödemeyi en çok 365 gün içinde karta iade edebilir. Daha eski
   yüklemeden kalan tutarın karta iadesi teknik olarak mümkün değildir; elle (havaleyle) ödeme operasyon yükü doğurur.
5. **İade faturası / e-arşiv:** Karta iadede düzenlenecek belge (iade faturası ya da gider pusulası) mali müşavirle
   netleştirilmelidir (M0.2).

## Uygulamadaki karşılığı (FAZ M13.3)

| Madde | Uygulama |
|---|---|
| 1 | Bakiye yalnız paket aidatı ve talep kabul ücretinde düşer; çekme ucu yoktur |
| 2 | Kapanışta kalan bakiye en yeni yüklemeden eskiye eşleştirilir; her eşleşme `mp_card_refunds` satırı + defterde `CARD_REFUND`; iyzico iade v2 ile kısmi iade |
| 3 | Eşleşmeyen kısım defterde `EXPIRED_BALANCE` ile düşülür; tedarikçiye bildirimde tutar ve madde numarası yazılır |
| 4 | Kapanış sonrası sonuçlanan yükleme bakiyeye yazılmaz, tamamı karta iade sırasına girer (`LATE_TOPUP`) |
| 5 | iyzico iadeyi reddederse yeniden denenir; deneme hakkı biterse ya da sonuç bilinmiyorsa platformun "Karta iadeler" ekranına düşer, havale dekontuyla kapatılır |
| 6 | Tedarikçi bakiye ekranında "Karta iadeler" listesi; sonuç bildirimi |
| 7 | Kabulsüz yükleme 409 `TERMS_REQUIRED`; sürüm değişince yeniden kabul |
