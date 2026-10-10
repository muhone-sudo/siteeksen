package service

// Fatura sapma uyarısı (beşinci tur B8, Şikayetvar "payölçer hatalı katsayı / absürt fatura").
//
// Paylaştırma yayımlanmadan önce, kullanım alanı başına tüketimi (alan yoksa doğrudan tüketimi)
// sitenin MEDYANININ OutlierFactor katını aşan bölümler bulunur. Medyan kullanılır, ortalama
// değil: tek bir arızalı sayaç ortalamayı yukarı çeker ve kendini normal gösterir (enerji
// analizindeki gerekçeyle aynı). Ölçülebilir bölüm 3'ten azsa medyan anlamsızdır; hiçbir şey
// işaretlenmez. Bu bir YAYIM ÖNCESİ uyarıdır: yönetici okumayı kontrol eder ya da teyit eder.

import (
	"sort"

	"github.com/shopspring/decimal"
)

// OutlierFactor, medyanın kaç katının "sapma" sayılacağıdır. Mevzuat oranı değildir (kontrol
// eşiğidir); bu yüzden legal_parameters'ta değil burada durur.
var OutlierFactor = decimal.NewFromInt(3)

// Outlier, medyandan sapan bölümdür.
type Outlier struct {
	UnitID    string `json:"unit_id"`
	UnitName  string `json:"unit_name"`
	Intensity string `json:"intensity"`
	Median    string `json:"median"`
	Ratio     string `json:"ratio"`
	// Basis: AREA (m² başına tüketim) ya da CONSUMPTION (alan yoksa doğrudan tüketim).
	Basis string `json:"basis"`
}

// FindOutliers, medyanın OutlierFactor katını aşan bölümleri döner (büyükten küçüğe).
func FindOutliers(units []UnitBasis) []Outlier {
	type m struct {
		u     UnitBasis
		v     decimal.Decimal
		basis string
	}
	useArea := true
	for _, u := range units {
		if u.Consumption.IsPositive() && !u.UsableArea.IsPositive() {
			useArea = false
			break
		}
	}
	vals := []m{}
	for _, u := range units {
		if !u.Consumption.IsPositive() {
			continue
		}
		if useArea {
			vals = append(vals, m{u, u.Consumption.Div(u.UsableArea), "AREA"})
		} else {
			vals = append(vals, m{u, u.Consumption, "CONSUMPTION"})
		}
	}
	if len(vals) < 3 {
		return nil
	}
	sorted := make([]decimal.Decimal, len(vals))
	for i, x := range vals {
		sorted[i] = x.v
	}
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].LessThan(sorted[j]) })
	median := sorted[len(sorted)/2]
	if len(sorted)%2 == 0 {
		median = sorted[len(sorted)/2-1].Add(sorted[len(sorted)/2]).Div(decimal.NewFromInt(2))
	}
	if !median.IsPositive() {
		return nil
	}
	limit := median.Mul(OutlierFactor)
	out := []Outlier{}
	for _, x := range vals {
		if x.v.GreaterThan(limit) {
			out = append(out, Outlier{UnitID: x.u.UnitID, UnitName: x.u.UnitName, Intensity: x.v.Round(3).String(),
				Median: median.Round(3).String(), Ratio: x.v.Div(median).Round(2).StringFixed(2), Basis: x.basis})
		}
	}
	sort.Slice(out, func(i, j int) bool {
		a, _ := decimal.NewFromString(out[i].Ratio)
		b, _ := decimal.NewFromString(out[j].Ratio)
		return a.GreaterThan(b)
	})
	return out
}
