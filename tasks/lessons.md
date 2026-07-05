# Lessons — Öğrenilen Dersler

Tekrar eden hataları önlemek için her oturum başında bu dosya okunur.
Bir hata düzeltildiğinde veya önemli bir şey öğrenildiğinde buraya eklenir.

Format:
- **Ne oldu:** Kısa açıklama
- **Neden oldu:** Kök neden
- **Kural:** Bir daha olmaması için ne yapılmalı

---

## Faz 2 (Finans) — Kullanıcı talimatı: Muhasebe/Aidat/Gelir-Gider migration'larını ERTELE

- **Ne oldu:** Faz 2 (Aidat & Ödemeler) planlanırken `accounting/page.tsx`'teki "Aidat Kararları" (dues_decisions) ve "Gelirler" (incomes) sekmeleri için DB'de hiç tablo olmadığı tespit edildi (yeni migration gerektiriyor).
- **Kullanıcı talimatı (2026-06-07, verbatim çeviri):** "Muhasebe ile ilgili, aidat, gelir-gider, tahakkuk vs. ile ilgili HİÇ migration yazma. Ben para ile ilgili bölümleri test ediyorum, henüz tamamlamadım, çok eksik var. Bu eksikler için de ayrı migration gerekecek — hepsini birlikte (tek seferde, toplu) yaparız."
- **Kural:** Finans/muhasebe/aidat/gelir-gider/tahakkuk alanlarında YENİ TABLO/MİGRATION yazma — kullanıcı bu alanı aktif olarak test ediyor ve eksikleri topluca tek bir migration'da ele alacak. Bu alanda şema değişikliği gerektiren bir ihtiyaç fark edilirse SADECE not al (aşağıdaki "Eksik/Ertelenmiş Finans Şeması" listesine ekle), migration YAZMA, kullanıcıya sor.

### Eksik/Ertelenmiş Finans Şeması (gelecekteki toplu migration için biriktirme listesi)
- `dues_decisions` tablosu yok — "Aidat Kararları" sekmesi (yönetim kurulu kararıyla aidat tutarı/dağıtım yöntemi belirleme: tutar, karar no, sayfa no, karar tarihi, yürürlük tarihi, özet) için gerekli
- `incomes` tablosu yok — "Gelirler" sekmesi (kira/hizmet/satış/diğer gelir kalemleri: tip, açıklama, tutar, tarih, ödeyen) için gerekli
- (Faz 2 ilerledikçe burada yeni eksikler bulunursa ekle)

---

<!-- Dersler buraya eklenir -->

## Model Varsayımları ve Gerçekçilik

- **Ne oldu:** Antigravity IDE model seçeneklerinde olmayan "Gemini 3.5 Pro" modelinin varlığını varsayıp önerdim.
- **Neden oldu:** Sistem ayarlarını ve metadata'yı tam kontrol etmeden varsayımda bulundum.
- **Kural:** Asla model isimleri, sistem ayarları veya teknik metotlar hakkında varsayım yapma. Sadece doğrulanmış verileri kullan, emin değilsen varsaymak yerine kullanıcıya sor.

