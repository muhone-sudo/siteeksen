# Doğrulama Politikası — "Tamamlandı" Ne Zaman Yazılabilir?

Bu dosya, `tasks/audit-raporu.md`'de tespit edilen **KN-1 (kanıt zorunluluğu yok)** ve
**KN-2 (hataların sessizce yutulması)** kök nedenlerinin kalıcı çözümüdür.

Denetim sonucu: dokümanlardaki iddiaların **%49'u yanlış**. Tek nedeni dikkatsizlik değil —
`✅` işaretinin "dosya yazıldı" anlamında kullanılmasıydı. Bu politika o boşluğu kapatır.

Yürürlük: 2026-09-09'dan itibaren tüm `tasks/*.md` dosyaları ve tüm commit'ler.

---

## 1. Kanıt seviyeleri (D0–D4)

Artık `✅` tek başına kullanılmaz. Her iş maddesi bir **kanıt seviyesi** taşır:

| Seviye | Etiket | Anlamı | Ne yazılmalı |
|---|---|---|---|
| **D0** | `PLAN` | Yalnızca planlandı, kod yok | — |
| **D1** | `YAZILDI` | Kod yazıldı, **derlendiği doğrulanmadı** | dosya yolları |
| **D2** | `DERLENDİ` | Derleme/statik denetim geçti | çalıştırılan komut + çıkış kodu |
| **D3** | `TEST EDİLDİ` | Otomatik test kapsıyor ve geçiyor | test dosyası:satır + komut çıktısı |
| **D4** | `CANLI DOĞRULANDI` | Gerçek ortamda uçtan uca çalıştı | istek/yanıt örneği veya veritabanı satırı + tarih |

**Kural:** Bir maddenin yanında kanıt yoksa seviyesi **D1'den yüksek olamaz.**

### Nasıl yazılır (zorunlu biçim)

```markdown
- [D3] Aidat tahakkuku dağıtım matematiği — `finance/repository/finance.go:399-545`
  **Kanıt:** `go test ./services/finance/... -run TestDistribution` → ok, 4 test geçti (2026-09-09)
```

```markdown
- [D1] Gecikme tazminatı hesabı — `finance/service/late_fee.go`
  **Kanıt:** yok — Go bu makinede kurulu değil (bkz. questions.md S-01). CI doğrulaması bekliyor.
```

### Yasak ifadeler

Aşağıdakiler kanıt sayılmaz ve yazılmaz:

- ❌ "tamamlandı", "çalışıyor", "entegre edildi" — kanıt satırı olmadan
- ❌ "canlı doğrulandı" — istek/yanıt veya veritabanı satırı gösterilmeden
- ❌ "hepsi çalışıyor" — hangi komutun ne döndürdüğü yazılmadan
- ❌ Bir servis için "✅" — o servis veritabanına bağlı değilken

---

## 2. "Bitti" tanımı (Definition of Done)

Bir **dikey dilim** (uçtan uca özellik) ancak aşağıdakilerin tamamı sağlandığında `D4` sayılır:

### 2.1 Veri katmanı
- [ ] Migration yazıldı, **idempotent** (`IF NOT EXISTS` / `ON CONFLICT`)
- [ ] Migration **temiz bir veritabanında** baştan sona çalıştı (`docker compose down -v && up`)
- [ ] Geri alma (down) betiği var
- [ ] Gerekli index'ler var; FK `ON DELETE` davranışı **bilinçli** olarak yazıldı
- [ ] Para alanları `DECIMAL`/`NUMERIC` (şema) ve `int64` kuruş veya `decimal` (Go) — **`float64` yasak**

### 2.2 Servis katmanı
- [ ] `AuthMiddleware` bağlı (kimliksiz erişilebilir uç nokta bırakılmaz)
- [ ] Yetki kontrolü **sunucuda** (arayüzde gizlemek yetmez)
- [ ] Tenant filtresi her sorguda; `property_id` **istemciden değil token'dan**
- [ ] Kaynak sahipliği doğrulanıyor (IDOR yok)
- [ ] Çok adımlı yazma **tek transaction** içinde
- [ ] Yazma uçları **idempotent** (ödeme/tahakkuk gibi mali işlemlerde `Idempotency-Key` zorunlu)
- [ ] Soft-delete filtresi (`deleted = 0`) her sorguda
- [ ] Sayfalama var (limit + cursor); sınırsız liste dönmüyor
- [ ] **Hiçbir hata yutulmuyor** (`_ =` ve boş `catch` yasak — §3)
- [ ] Hata mesajı istemciye ham veritabanı metni sızdırmıyor
- [ ] Hassas veri (TCKN, telefon, IBAN, maaş) şifreli ve maskeli; erişimi denetim izine yazılıyor

### 2.3 API sözleşmesi
- [ ] `api/openapi.yaml` güncellendi
- [ ] Yanıt zarfı standarda uygun (tek biçim — bkz. §4)
- [ ] Gateway/Kong route'u eklendi ve **yolun servise ulaştığı doğrulandı**

### 2.4 Arayüz (panel ve mobil)
- [ ] Veri **gerçek API'den** geliyor
- [ ] **Sessiz mock fallback yok** (§3)
- [ ] Yükleniyor / boş / **hata** durumlarının üçü de var; hata kullanıcıya görünüyor ve yeniden denenebiliyor
- [ ] Yazma işlemi gerçekten API'ye gidiyor; başarı mesajı **yanıt geldikten sonra** gösteriliyor
- [ ] Rol bazlı görünürlük **ve** sunucu tarafı yetki birlikte
- [ ] Ekran menüden/router'dan **gerçekten ulaşılabilir** (ölü route bırakılmaz)
- [ ] Para ve tarih TR biçiminde (`intl` / `Intl.NumberFormat`)

### 2.5 Doğrulama
- [ ] Mutlu yol testi + en az bir hata yolu testi
- [ ] Test **üretim kodunu** çalıştırıyor (test dosyasının kendi içinde yazdığı sahte fonksiyonu değil — §3.4)
- [ ] Uçtan uca en az bir kez elle denendi ve kanıtı (istek/yanıt, ekran görüntüsü veya veritabanı satırı) kaydedildi

### 2.6 Kayıt
- [ ] `tasks/changelog.md`'ye kanıtla birlikte eklendi
- [ ] `tasks/roadmap.md`'deki satır kanıt seviyesiyle güncellendi
- [ ] Öğrenilen bir şey varsa `tasks/lessons.md`'ye yazıldı

---

## 3. Sessiz başarısızlık yasağı

Denetimin en yıkıcı bulgusu: sistem hata durumunda **yalan söylüyor**. Aşağıdakiler kesin yasaktır.

### 3.1 Hata yutma yasak
```go
// YASAK
_ = audit.LogAction(ctx, pool, entry)        // denetim izi hiç yazılmadı, kimse fark etmedi
r.pool.Exec(ctx, linkQuery, paymentID, aID)  // ödeme-tahakkuk bağı sessizce kayboldu

// DOĞRU
if err := audit.LogAction(ctx, pool, entry); err != nil {
    log.Error("audit yazılamadı", "err", err, "request_id", reqID)  // en azından görünür
}
```

### 3.2 Sessiz mock fallback yasak
```typescript
// YASAK — kullanıcı sunucunun çöktüğünü asla anlamaz
try { data = await apiClient.getExpenses() }
catch { data = mockExpenses }          // uydurma ₺45.750 mali özet gösterildi

// DOĞRU
try { data = await apiClient.getExpenses() }
catch (e) { setError(e); return }      // ekranda hata + "Yeniden dene"
```

Demo veri gösterilmesi **gerekiyorsa** arayüzde açıkça `DEMO VERİ` etiketi zorunludur.

### 3.3 Sahte başarı yasak
```dart
// YASAK
onPressed: () { Navigator.pop(context); _showPaymentSuccess(context); }  // hiç ağ çağrısı yok

// DOĞRU
onPressed: () async {
  final res = await apiClient.createPayment(...);   // önce gerçekten yap
  if (res.ok) _showPaymentSuccess(context); else _showError(res.error);
}
```

### 3.4 Kendi kendini test eden test yasak
```go
// YASAK — test dosyası kendi yazdığı fonksiyonu test ediyor, üretim kodunu hiç çağırmıyor
func calculateLateFee(a float64, d int) float64 { return a * 0.05 * float64(d) / 30 }
func TestLateFee(t *testing.T) { assert.Equal(t, 50.0, calculateLateFee(1000, 30)) }
```
Test, **üretimde çalışan** fonksiyonu/handler'ı çağırmalıdır.

### 3.5 Kaydetmeyen uç nokta 2xx dönmez
Bir uç nokta veriyi henüz kalıcı hale getirmiyorsa `200`/`201` **dönmez**:
```go
c.JSON(http.StatusNotImplemented, gin.H{"error": "bu uç nokta henüz veritabanına bağlı değil"})
```
Bu kural tek başına, 22 mock servisin yol açtığı "kaydettim sandım" sınıfı hataları bitirir.

---

## 4. Tek doğruluk kaynağı kuralları (KN-4)

1. **Takip dosyaları:** `tasks/` altındakiler tek kaynaktır. Kökteki `ROADMAP.md` ve `CHANGELOG.md`
   yalnızca işaretçidir; içerik kopyalanmaz.
2. **Doküman kendi içinde çelişmez.** Bir servis hem "eklendi" hem "eklenmedi" olamaz; çelişki fark
   edilirse **düzeltilmeden** başka işe geçilmez.
3. **Entegrasyon başına tek paket.** Aynı iş için ikinci bir uygulama yazılmaz; mevcut olan düzeltilir
   (denetim: iyzico ×2, FCM ×2, OpenAI ×2, banka listesi ×2, karbon hesabı ×2 — farklı sonuçlarla).
4. **Tek giriş kapısı.** Kong ve özel gateway birbirinden farklı route kümesi taşımaz; hangisi
   kanonikse diğeri onun arkasına alınır.
5. **Yanıt zarfı standardı:** tüm servisler aynı biçimi döndürür. Karar: `{"success": bool, "data": ..., "error": ...}`.
   *(Denetim, bu standardın olmamasının dashboard aggregator'ını tamamen çalışmaz hale getirdiğini gösterdi.)*
6. **Parametre koda gömülmez.** Mevzuata bağlı oran/süre (gecikme tazminatı, ısı paylaşım oranı, nisaplar)
   yürürlük tarihli veritabanı parametresi olarak tutulur (bkz. `questions.md` S-05).

---

## 5. Durum göstergeleri (yeni sözlük)

Eski `✅ / 🔄 / 📋 / ❌` yerine:

| Gösterge | Anlam |
|---|---|
| `[D4]` | Canlı doğrulandı — kanıt satırı zorunlu |
| `[D3]` | Otomatik test geçiyor |
| `[D2]` | Derleniyor / statik denetim temiz |
| `[D1]` | Kod var, doğrulanmadı |
| `[D0]` | Planlandı |
| `[MOCK]` | Arayüz/uç nokta var ama **veri kalıcı değil** — kullanıcıya bu şekilde gösterilmeli |
| `[ÖLÜ]` | Kod var ama hiçbir yere bağlı değil (silinecek ya da bağlanacak) |
| `[KIRIK]` | Yazılmış ama çalışmıyor (kanıtla) |
| `[BLOKE]` | Dış bir karara/erişime bağlı — `questions.md`'deki soru numarası yazılır |

---

## 6. Oturum başı ve sonu kontrol listesi

**Oturum başında:**
1. `tasks/roadmap.md`, `tasks/todo.md`, `tasks/lessons.md`, `tasks/changelog.md` okunur
2. `tasks/questions.md`'de cevaplanmış soru var mı bakılır (varsa varsayılan kararlar gözden geçirilir)
3. Doğrulama araçlarının durumu kontrol edilir (Go/Flutter/Docker var mı — S-01)

**Oturum sonunda:**
1. Her dokunulan madde kanıt seviyesiyle güncellenir
2. Doğrulanamayan hiçbir şey yükseltilmez — `[D1]` olarak bırakılır ve nedeni yazılır
3. `tasks/changelog.md`'ye kanıtla eklenir
4. Yeni bir engel/soru çıktıysa `tasks/questions.md`'ye yazılır

---

## 7. Bu politikanın kendi kanıtı

Politikanın işe yarayıp yaramadığı şu ölçütle izlenir:

- **Ölçüt:** `tasks/roadmap.md`'de `[D3]`/`[D4]` etiketli madde sayısı / toplam madde sayısı
- **Bugünkü değer (2026-09-09):** 78 denetlenen iddiadan gerçekten doğrulanabilir olan **18** → **%23**
- **Hedef:** Her dikey dilim bittiğinde bu oran artar; oran düşerse yeni iş açılmaz, mevcut işler doğrulanır.
