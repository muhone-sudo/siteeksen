# SiteEksen tarayıcı test planı

Panelin, sakin uygulamasının ve yönetici uygulamasının **her sayfası, her düğmesi**; bildirimleri, yetkileri,
site izolasyonu ve veritabanı etkileri için tarayıcıdan yürütülecek test planı. Bir tarayıcı yapay zekâ ajanının
(ör. Claude in Chrome) bölüm bölüm yürütmesi için yazıldı; insan test eden de aynı adımları izleyebilir.

- **Tek dosya:** [TEST-PLANI-TAMAMI.md](TEST-PLANI-TAMAMI.md) (bütün bölümler birleşik).
- **Bölüm bölüm:** aşağıdaki tablo. Ajanın bağlamı sınırlıysa her oturumda `00-baslangic.md` + tek bir bölüm verin.

## 1. Ortamı başlat

```bash
bash backend/scripts/test-ortami.sh          # "TEST ORTAMI HAZIR" yazınca başlanır; Ctrl+C durdurur
bash backend/scripts/test-ortami.sh --stop   # başka terminalden durdurma
```

Betik şunları açar: PostgreSQL + 24 servis + gateway + zamanlayıcı (1 dk), panel (:3001), sakin (:3002) ve yönetici (:3003)
uygulamalarının web derlemesi, Adminer (:18080, salt okunur), Mailpit (:18025), test araçları (:18000: SMS kutusu, sahte iyzico
ödeme sayfası, cihaz simülatörü, günlükler, **sonuç kaydı**). Test hesaplarını gerçek kayıt akışıyla oluşturur (9 hesap, 2 site).
Hiçbir şey dışarı gitmez: SMS, e-posta ve kart ödemesi yerel sahte sağlayıcılara gider.

## 2. Bölümler ve sıra

| Sıra | Dosya | Kapsam | Nasıl üretildi |
|---|---|---|---|
| 0 | [00-baslangic.md](00-baslangic.md) | Ajan talimatı, adresler, hesaplar, sorgu kalıpları, ortak beklentiler | elle |
| 1 | [01-oturum-ve-hesap.md](01-oturum-ve-hesap.md) | Giriş, kilit, etkinleştirme, şifremi unuttum, telefon/e-posta, çıkış, jeton, site seçimi | elle |
| 2 | [02-rol-ve-izolasyon.md](02-rol-ve-izolasyon.md) | Panel sayfa × rol matrisi, denetçi/görevli sınırları, iki site izolasyonu | üretilir |
| 3 | [03-01 … 03-09](03-01-panel-ust.md) | Panel: her sayfa, her düğme/form/seçim (kenar çubuğu gruplarına göre 9 dosya) | üretilir |
| 4 | [04-sakin-uygulamasi.md](04-sakin-uygulamasi.md) | Sakin uygulaması: her ekran, her düğme | üretilir |
| 5 | [05-yonetici-uygulamasi.md](05-yonetici-uygulamasi.md) | Yönetici uygulaması: her ekran, her düğme | üretilir |
| 6 | [06-bildirimler.md](06-bildirimler.md) | Bildirim üreten her uç (alıcı, kanal, görmemesi gerekenler), zamanlanmış işler, bekçiler | üretilir |
| 7 | [07-veritabani.md](07-veritabani.md) | Tetikleyiciler, bütünlük sorguları | üretilir |
| 8 | [08-uctan-uca-senaryolar.md](08-uctan-uca-senaryolar.md) | Çok hesaplı iş akışları (aidat, kart ödemesi, kiracılık, genel kurul, devriye, sensör…) | elle |
| 9 | [09-arayuzsuz-ve-sinirlar.md](09-arayuzsuz-ve-sinirlar.md) | Arayüzü olmayan uçlar, bilinen sınırlar | üretilir |

Sayfa/ekran bölümlerindeki her test şunları içerir: hangi hesapla, nerede, adımlar, beklenen ekran sonucu, çağrılan uç ve sunucu yetkisi,
**Adminer'de çalıştırılacak sorgu** (değişen her tablo için), işlem kaydı sorgusu, **bildirim konusu ve alıcıları** (hangi hesabın hangi kutuda görmesi gerektiği),
etkisinin görülmesi gereken diğer ekranlar ve yetkisiz hesapla olumsuz deneme.

## 3. Ajana verilecek komut

**Kendi kendine ilerleyen yol:** ajana her oturumda yalnız *"docs/test-plani/AJAN-GOREVI.md dosyasını oku ve uygula."* yazın.
Ajan sırayı ve kaldığı yeri [ilerleme.md](ilerleme.md)'den bulur, bölüm bitince sonrakine kendisi geçer.

Tek bölüm vermek için örnek:

> Sen bir test uzmanısın. Ekteki `00-baslangic.md` dosyasındaki kuralları uygula ve `<bölüm dosyası>` içindeki testleri sırayla yürüt.
> Her testin sonucunu http://localhost:18000/sonuc sayfasına ID, durum (GEÇTİ/KALDI/KISMEN/ATLANDI/ENGELLENDİ), kullandığın hesap ve
> somut gözlemle kaydet. Yazma işlemlerinden sonra Adminer'deki sorguyla veritabanını, bildirim kutularıyla bildirimi doğrula.
> Hata bulursan hata metnini ve http://localhost:18000/gunluk'taki ilgili servis satırını gözleme yaz ve devam et. Bölüm bitince
> KALDI ve KISMEN olanları özetle.

## 4. Sonuçları almak

- Canlı: http://localhost:18000/sonuc (bölüm önekiyle süzülür: `?bolum=P`, `?bolum=S`, `?bolum=E` …)
- Dışa aktarım: http://localhost:18000/sonuc.md (Markdown tablo), http://localhost:18000/sonuc.json
- Dosya: `~/.siteeksen-test/sonuclar.jsonl` — ortam yeniden başlatılsa da kalır. Hataları düzelttirmek için bu dosyayı verin.

## 5. Yeniden başlatınca

Veritabanı sıfırlanır, hesaplar yeniden oluşur (aynı telefon ve şifrelerle). Önceki testlerde oluşturulan kayıtlar (duyuru, borç, kargo…)
kalmaz: senaryoların ön koşullarını yeniden yapın. Sonuç kayıtları silinmez.

## 6. Planı yenilemek

Kod değişince plan haritayla birlikte yeniden üretilir; elle yazılan 00, 01, 08 ve bu README korunur:

```bash
bash docs/ozellik-haritasi/arac/uret.sh     # haritanın 1-5. bölümleri + test planının üretilen bölümleri + TAMAMI
```

Kaynaklar: `docs/ozellik-haritasi/arac/test_plani.py` (üretici), `backend/scripts/test-ortami.sh`, `backend/scripts/test-hesaplari.sh`,
`backend/scripts/test-araclari/` (araç sunucusu ve hesap betiği).
