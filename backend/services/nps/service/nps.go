// Package service, NPS (Net Tavsiye Skoru) hesabını içerir.
//
// NPS, uluslararası kabul görmüş ve TANIMI SABİT bir ölçüdür:
//
//	0-6  → Kötüleyen (detractor)
//	7-8  → Kararsız  (passive)
//	9-10 → Tavsiye eden (promoter)
//	NPS  = %tavsiye eden − %kötüleyen        (sonuç -100 ile +100 arası)
//
// Kararsızlar skora GİRMEZ ama paydada sayılır; bu, tanımın bir parçasıdır ve
// değiştirilirse çıkan sayı "NPS" olmaz.
package service

import (
	"errors"

	"github.com/shopspring/decimal"
)

// ErrNoResponses, hiç yanıt yoksa döner.
var ErrNoResponses = errors.New("hiç yanıt yok")

// MinResponsesForReliable, skorun yönlendirici sayılması için gereken en az
// yanıt sayısı. 3 kişilik bir örneklemle "site memnuniyeti -33" demek,
// yönetimi yanlış karara sürükler.
const MinResponsesForReliable = 10

// Result, NPS hesabının sonucudur.
type Result struct {
	Score      int `json:"nps_score"`
	Responses  int `json:"responses"`
	Promoters  int `json:"promoters"`
	Passives   int `json:"passives"`
	Detractors int `json:"detractors"`

	PromoterPct  string `json:"promoter_pct"`
	PassivePct   string `json:"passive_pct"`
	DetractorPct string `json:"detractor_pct"`

	// Reliable false ise örneklem skoru yönlendirici kılacak kadar büyük değil.
	Reliable bool   `json:"reliable"`
	Note     string `json:"note,omitempty"`
	// Interpretation, skorun ne anlama geldiğini insan diliyle söyler.
	Interpretation string `json:"interpretation"`
}

// Calculate, 0-10 arası puanlardan NPS hesaplar.
//
// Aralık dışındaki puanlar SESSİZCE ATILMAZ; çağıran tarafın bunları hiç
// göndermemesi beklenir. Yine de gelirse hesaba katılmaz ve sayım farkı
// Responses alanından görülebilir.
func Calculate(scores []int) (*Result, error) {
	r := &Result{}
	for _, s := range scores {
		if s < 0 || s > 10 {
			continue
		}
		r.Responses++
		switch {
		case s >= 9:
			r.Promoters++
		case s >= 7:
			r.Passives++
		default:
			r.Detractors++
		}
	}
	if r.Responses == 0 {
		return nil, ErrNoResponses
	}

	total := decimal.NewFromInt(int64(r.Responses))
	hundred := decimal.NewFromInt(100)
	promoterPct := decimal.NewFromInt(int64(r.Promoters)).Div(total).Mul(hundred)
	passivePct := decimal.NewFromInt(int64(r.Passives)).Div(total).Mul(hundred)
	detractorPct := decimal.NewFromInt(int64(r.Detractors)).Div(total).Mul(hundred)

	r.PromoterPct = promoterPct.Round(1).String()
	r.PassivePct = passivePct.Round(1).String()
	r.DetractorPct = detractorPct.Round(1).String()
	r.Score = int(promoterPct.Sub(detractorPct).Round(0).IntPart())

	r.Reliable = r.Responses >= MinResponsesForReliable
	if !r.Reliable {
		r.Note = "Yanıt sayısı " + decimal.NewFromInt(int64(r.Responses)).String() +
			"; skor yönlendirici sayılmamalıdır. Küçük örneklemde tek bir kişinin " +
			"puanı sonucu büyük ölçüde değiştirir."
	}
	r.Interpretation = interpret(r.Score)
	return r, nil
}

// interpret, skoru yorumlar.
//
// Eşikler sektör pratiğinden gelen KABA yorumlardır; bir ölçüt ya da hedef
// değildir. Bu yüzden metin "genel kabul" diyerek kaynağını belirtir.
func interpret(score int) string {
	switch {
	case score >= 50:
		return "Genel kabul gören yoruma göre yüksek memnuniyet: tavsiye edenler " +
			"kötüleyenlerden belirgin biçimde fazla."
	case score >= 0:
		return "Tavsiye edenler kötüleyenlerden fazla ya da eşit; iyileştirmeye açık alan var."
	default:
		return "Kötüleyenler tavsiye edenlerden fazla. Açık uçlu yorumlar okunarak " +
			"somut şikâyet başlıkları çıkarılmalıdır."
	}
}
