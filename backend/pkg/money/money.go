// Package money, para tutarlarını KURUŞ (tam sayı) olarak temsil eder ve
// ortak gider dağıtımını kayıpsız yapar.
//
// NEDEN VAR (tasks/gap-analizi.md B50, B51):
//
//  1. Kod bugüne kadar parayı `float64` ile taşıyordu. İkili kayan nokta ondalık
//     kesirleri tam temsil edemez: `0.1 + 0.2 != 0.3`. Aidat, gecikme tazminatı ve
//     tahsilat toplamlarında bu, zamanla birikerek kuruş farkları üretir ve
//     "defter tutmuyor" şikâyetine dönüşür. Para tam sayı kuruş olarak tutulur.
//
//  2. Bir gideri bağımsız bölümlere paylaştırırken bölme neredeyse hiçbir zaman
//     tam bölünmez. Her payı ayrı ayrı yuvarlamak, payların toplamının gidere
//     EŞİT OLMAMASINA yol açar (birkaç kuruş eksik ya da fazla). Kat mülkiyetinde
//     bu kabul edilemez: toplanan avans ile gider birebir örtüşmelidir.
//     Bu paket EN BÜYÜK KALAN (largest remainder / Hare) yöntemini kullanır:
//     tüm paylar aşağı yuvarlanır, artan kuruşlar en büyük kesirli kalana sahip
//     paylara birer birer dağıtılır. Böylece payların toplamı DAİMA tutara eşittir.
package money

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/shopspring/decimal"
)

// Kurus, tam sayı kuruş cinsinden para tutarıdır. 1 TL = 100 Kurus.
type Kurus int64

var (
	// ErrNegativeAmount, negatif tutar dağıtılmaya çalışıldığında döner.
	ErrNegativeAmount = errors.New("dağıtılacak tutar negatif olamaz")
	// ErrNoWeights, ağırlık listesi boş ya da toplamı sıfır olduğunda döner.
	ErrNoWeights = errors.New("dağıtım için geçerli ağırlık yok (liste boş ya da toplam sıfır)")
	// ErrNegativeWeight, negatif ağırlık verildiğinde döner.
	ErrNegativeWeight = errors.New("ağırlık negatif olamaz")
)

// FromTRY, decimal TL tutarını kuruşa çevirir (yarıyı yukarı yuvarlar).
func FromTRY(d decimal.Decimal) Kurus {
	return Kurus(d.Mul(decimal.NewFromInt(100)).Round(0).IntPart())
}

// FromFloatTRY, yalnızca DIŞ SİSTEM SINIRINDA kullanılmalıdır (örn. JSON'dan gelen
// eski alanlar). İç hesaplarda float kullanılmaz.
func FromFloatTRY(f float64) Kurus {
	return FromTRY(decimal.NewFromFloat(f))
}

// TRY, kuruşu TL cinsinden decimal'e çevirir.
func (k Kurus) TRY() decimal.Decimal {
	return decimal.NewFromInt(int64(k)).Div(decimal.NewFromInt(100))
}

// String, "1.234,56" değil, makine okunur "1234.56" üretir (JSON/loglar için).
func (k Kurus) String() string {
	return k.TRY().StringFixed(2)
}

// Display, insana gösterilecek biçimdir: "1.234,56 TL" (binlik nokta, ondalık
// virgül). Bildirim metinlerinde kullanılır; hesapta ya da JSON'da kullanılmaz.
func (k Kurus) Display() string {
	neg := k < 0
	if neg {
		k = -k
	}
	whole := strconv.FormatInt(int64(k)/100, 10)
	var b strings.Builder
	for i, r := range whole {
		if i > 0 && (len(whole)-i)%3 == 0 {
			b.WriteByte('.')
		}
		b.WriteRune(r)
	}
	s := fmt.Sprintf("%s,%02d TL", b.String(), int64(k)%100)
	if neg {
		return "-" + s
	}
	return s
}

// Share, bir dağıtım payıdır.
type Share struct {
	// Key, payın kime ait olduğunu belirtir (genellikle unit_id).
	Key string
	// Weight, paylaşım ağırlığıdır (arsa payı, m², eşit dağıtımda 1).
	Weight decimal.Decimal
	// Amount, hesaplanan pay (kuruş).
	Amount Kurus
}

// Distribute, `total` tutarını verilen ağırlıklara göre paylaştırır.
//
// Garantiler:
//   - Dönen payların TOPLAMI daima `total`'e eşittir (kuruş kaybı/fazlası yoktur).
//   - Ağırlığı sıfır olan kalemler sıfır pay alır.
//   - Aynı ağırlığa sahip kalemler arasında artan kuruş, `Key` sırasına göre
//     belirlenimci (deterministik) dağıtılır — aynı girdi daima aynı çıktıyı verir.
//     Bu, tahakkukun yeniden üretilebilir olması için gereklidir: aynı dönem
//     yeniden hesaplandığında daireler arasında kuruş yer değiştirmez.
func Distribute(total Kurus, shares []Share) ([]Share, error) {
	if total < 0 {
		return nil, ErrNegativeAmount
	}
	if len(shares) == 0 {
		return nil, ErrNoWeights
	}

	totalWeight := decimal.Zero
	for _, s := range shares {
		if s.Weight.IsNegative() {
			return nil, fmt.Errorf("%w: %s", ErrNegativeWeight, s.Key)
		}
		totalWeight = totalWeight.Add(s.Weight)
	}
	if totalWeight.IsZero() {
		return nil, ErrNoWeights
	}

	out := make([]Share, len(shares))
	copy(out, shares)

	type remainder struct {
		idx  int
		frac decimal.Decimal
		key  string
	}

	totalDec := decimal.NewFromInt(int64(total))
	assigned := Kurus(0)
	rems := make([]remainder, 0, len(out))

	for i := range out {
		exact := totalDec.Mul(out[i].Weight).Div(totalWeight)
		floor := exact.Floor()
		out[i].Amount = Kurus(floor.IntPart())
		assigned += out[i].Amount
		rems = append(rems, remainder{idx: i, frac: exact.Sub(floor), key: out[i].Key})
	}

	// Artan kuruşlar: en büyük kesirli kalandan başlayarak birer birer dağıtılır.
	leftover := int(total - assigned)
	if leftover > 0 {
		sort.SliceStable(rems, func(a, b int) bool {
			c := rems[b].frac.Cmp(rems[a].frac) // azalan
			if c != 0 {
				return c < 0
			}
			return rems[a].key < rems[b].key // eşitlikte belirlenimci sıra
		})
		for i := 0; i < leftover; i++ {
			out[rems[i%len(rems)].idx].Amount++
		}
	}

	return out, nil
}

// DistributeEqual, tutarı eşit paylaştırır (KMK m.20/1-a: kapıcı, kaloriferci,
// bahçıvan, bekçi giderleri ve yönetici aylığı).
func DistributeEqual(total Kurus, keys []string) ([]Share, error) {
	shares := make([]Share, len(keys))
	for i, k := range keys {
		shares[i] = Share{Key: k, Weight: decimal.NewFromInt(1)}
	}
	return Distribute(total, shares)
}

// LateFee, gecikme tazminatını hesaplar.
//
// KMK m.20/2: "ödemede geciktiği günler için aylık yüzde beş hesabıyla gecikme
// tazminatı". Oran koda gömülmez; `monthlyRate` çağıran tarafından
// `pkg/legalparams` üzerinden getirilir.
//
// Gün bazlı orantı uygulanır (aylık oran / 30 * gecikilen gün). Tam ay beklemek
// yerine güne oranlamak, kanunun "geciktiği günler için" ifadesine uygundur.
// Yuvarlama: sonuç kuruşa yarı-yukarı yuvarlanır.
func LateFee(principal Kurus, monthlyRate decimal.Decimal, overdueDays int) (Kurus, error) {
	if principal < 0 {
		return 0, ErrNegativeAmount
	}
	if monthlyRate.IsNegative() {
		return 0, errors.New("gecikme tazminatı oranı negatif olamaz")
	}
	if overdueDays <= 0 {
		return 0, nil
	}
	fee := decimal.NewFromInt(int64(principal)).
		Mul(monthlyRate).
		Mul(decimal.NewFromInt(int64(overdueDays))).
		Div(decimal.NewFromInt(30)).
		Round(0)
	return Kurus(fee.IntPart()), nil
}

// Sum, pay listesinin toplamını verir. Doğrulama testlerinde kullanılır.
func Sum(shares []Share) Kurus {
	var t Kurus
	for _, s := range shares {
		t += s.Amount
	}
	return t
}
