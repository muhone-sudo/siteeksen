// Package service, tüketim analizi hesaplarını içerir.
//
// BU PAKETTE YAPAY ZEKÂ YOKTUR. Tüm sonuçlar, formülü burada yazılı olan
// açıklanabilir istatistiklerdir. Şemadaki `ai_model_version`, `predictions`
// gibi alanlar doldurulmaz: model yoksa sürüm numarası yazmak, olmayan bir
// yeteneği var göstermektir.
package service

import (
	"sort"

	"github.com/shopspring/decimal"
)

// Trend, iki dönem arasındaki değişimdir.
type Trend struct {
	Previous string `json:"previous"`
	Current  string `json:"current"`
	// ChangePct, yüzde değişimdir. Önceki dönem sıfırsa hesaplanamaz ve null kalır
	// — sıfırdan artışa "%100 arttı" demek yanıltıcıdır.
	ChangePct *string `json:"change_pct"`
	Direction string  `json:"direction"` // UP, DOWN, FLAT, UNKNOWN
}

// CalcTrend, iki dönem arasındaki değişimi hesaplar.
func CalcTrend(previous, current decimal.Decimal) Trend {
	t := Trend{Previous: previous.String(), Current: current.String(), Direction: "UNKNOWN"}
	if previous.LessThanOrEqual(decimal.Zero) {
		// Önceki dönem sıfır ya da yoksa yüzde değişim tanımsızdır.
		if current.GreaterThan(decimal.Zero) {
			t.Direction = "UP"
		} else {
			t.Direction = "FLAT"
		}
		return t
	}
	diff := current.Sub(previous)
	pct := diff.Div(previous).Mul(decimal.NewFromInt(100)).Round(2).String()
	t.ChangePct = &pct
	switch {
	case diff.IsPositive():
		t.Direction = "UP"
	case diff.IsNegative():
		t.Direction = "DOWN"
	default:
		t.Direction = "FLAT"
	}
	return t
}

// Anomaly, olağandışı tüketim bulgusudur.
type Anomaly struct {
	UnitID   string `json:"unit_id"`
	UnitName string `json:"unit_name"`
	Value    string `json:"value"`
	Median   string `json:"median"`
	// DeviationPct, medyandan sapmadır.
	DeviationPct string `json:"deviation_pct"`
	Severity     string `json:"severity"`
	// Reason, bulgunun NEDEN işaretlendiğini insan diliyle açıklar.
	Reason string `json:"reason"`
}

// AnomalyInput, tek bir bağımsız bölümün karşılaştırma değeridir.
type AnomalyInput struct {
	UnitID   string
	UnitName string
	// Value, karşılaştırılacak ölçüdür — alan başına tüketim kullanılmalıdır;
	// ham tüketim, büyük daireyi haksız yere "anormal" gösterir.
	Value decimal.Decimal
	// HasValue false ise bölümün ölçülebilir verisi yoktur.
	HasValue bool
}

// DetectAnomalies, medyandan belirgin sapan bölümleri işaretler.
//
// Yöntem: MEDYAN kullanılır, ortalama değil. Tek bir kaçak (örneğin patlak
// tesisat) ortalamayı yukarı çeker ve kendisini normal gösterir; medyan bundan
// etkilenmez.
//
// Eşikler:
//   - %100 üzeri sapma → HIGH  (iki katından fazla: kaçak/arıza şüphesi)
//   - %50-100 sapma   → MEDIUM
//   - -%80'den düşük  → LOW    (neredeyse hiç tüketim: sayaç arızası ya da boş daire)
//
// Bu eşikler istatistiksel bir model değil, yönetimin bakması gereken durumları
// işaretleyen KURALLARDIR ve her bulgu gerekçesiyle birlikte döner. En az 3
// ölçülebilir bölüm yoksa hiçbir şey işaretlenmez: iki daireyle medyan anlamsızdır.
func DetectAnomalies(inputs []AnomalyInput) []Anomaly {
	values := make([]decimal.Decimal, 0, len(inputs))
	for _, in := range inputs {
		if in.HasValue {
			values = append(values, in.Value)
		}
	}
	if len(values) < 3 {
		return []Anomaly{}
	}

	sort.Slice(values, func(i, j int) bool { return values[i].LessThan(values[j]) })
	median := values[len(values)/2]
	if len(values)%2 == 0 {
		median = values[len(values)/2-1].Add(values[len(values)/2]).
			Div(decimal.NewFromInt(2))
	}
	if median.LessThanOrEqual(decimal.Zero) {
		// Medyan sıfırsa sapma oranı hesaplanamaz.
		return []Anomaly{}
	}

	out := []Anomaly{}
	hundred := decimal.NewFromInt(100)
	for _, in := range inputs {
		if !in.HasValue {
			continue
		}
		dev := in.Value.Sub(median).Div(median).Mul(hundred).Round(2)
		devF, _ := dev.Float64()

		var severity, reason string
		switch {
		case devF >= 100:
			severity = "HIGH"
			reason = "Tüketim, site medyanının iki katından fazla. Kaçak, arıza ya da " +
				"hatalı okuma olabilir; sayaç ve tesisat kontrol edilmeli."
		case devF >= 50:
			severity = "MEDIUM"
			reason = "Tüketim site medyanının belirgin biçimde üzerinde. Olağan bir " +
				"kullanım farkı olabilir; bir sonraki dönemde de sürerse incelenmeli."
		case devF <= -80:
			severity = "LOW"
			reason = "Tüketim neredeyse yok. Bölüm boş olabilir ya da sayaç ölçmüyor " +
				"olabilir; sayaç kontrol edilmeli."
		default:
			continue
		}

		out = append(out, Anomaly{
			UnitID: in.UnitID, UnitName: in.UnitName,
			Value: in.Value.String(), Median: median.String(),
			DeviationPct: dev.String(), Severity: severity, Reason: reason,
		})
	}

	// En büyük sapma önce.
	sort.Slice(out, func(i, j int) bool {
		a, _ := decimal.NewFromString(out[i].DeviationPct)
		b, _ := decimal.NewFromString(out[j].DeviationPct)
		return a.Abs().GreaterThan(b.Abs())
	})
	return out
}

// Median, bir dizi değerin medyanını döner (dışarıya açık yardımcı).
func Median(values []decimal.Decimal) decimal.Decimal {
	if len(values) == 0 {
		return decimal.Zero
	}
	sorted := make([]decimal.Decimal, len(values))
	copy(sorted, values)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].LessThan(sorted[j]) })
	mid := len(sorted) / 2
	if len(sorted)%2 == 1 {
		return sorted[mid]
	}
	return sorted[mid-1].Add(sorted[mid]).Div(decimal.NewFromInt(2))
}
