package service

import (
	"strings"
	"testing"

	"github.com/shopspring/decimal"
)

func d(s string) decimal.Decimal {
	v, err := decimal.NewFromString(s)
	if err != nil {
		panic(err)
	}
	return v
}

func TestEvaluateGecmisYoksaSkorUretilmez(t *testing.T) {
	a := Evaluate(History{UnitID: "a"})
	if a.Reliable {
		t.Fatal("geçmiş yokken skor güvenilir sayıldı")
	}
	if a.Score != 0 || a.Category != "LOW" {
		t.Fatalf("geçmişsiz skor: %d/%s", a.Score, a.Category)
	}
	if a.Note == "" {
		t.Fatal("neden değerlendirme yapılamadığı açıklanmadı")
	}
}

func TestEvaluateDuzenliOdeyenDusukRisk(t *testing.T) {
	a := Evaluate(History{
		UnitID: "a", TotalAssessments: 12, PaidOnTime: 12,
		AverageDelayDays: decimal.Zero, CurrentDebt: decimal.Zero,
	})
	if a.Category != "LOW" {
		t.Fatalf("düzenli ödeyen: %s (LOW bekleniyordu)", a.Category)
	}
	if a.Score != 0 {
		t.Fatalf("düzenli ödeyenin skoru sıfır değil: %d", a.Score)
	}
	if a.Action != "NONE" {
		t.Fatalf("borcu olmayana işlem önerildi: %s", a.Action)
	}
}

func TestEvaluateHicOdemeyenKritik(t *testing.T) {
	a := Evaluate(History{
		UnitID: "a", TotalAssessments: 12, Unpaid: 12, OverdueCount: 12,
		AverageDelayDays: d("120"), CurrentDebt: d("14400"), LongestOverdueDays: 365,
	})
	if a.Category != "CRITICAL" {
		t.Fatalf("hiç ödemeyen: %s (CRITICAL bekleniyordu, skor %d)", a.Category, a.Score)
	}
	if a.Action != "LEGAL_REVIEW" {
		t.Fatalf("önerilen işlem: %s", a.Action)
	}
	// Hukuki adımın OTOMATİK olmadığı açıkça söylenmeli.
	if !strings.Contains(a.ActionReason, "öneridir") {
		t.Fatalf("hukuki adımın öneri olduğu belirtilmemiş: %s", a.ActionReason)
	}
	if !strings.Contains(a.ActionReason, "m.22") {
		t.Fatal("hukuki dayanak belirtilmemiş")
	}
}

func TestEvaluateOdenmeyenGecOdemedenAgirBasar(t *testing.T) {
	// Aynı sayıda tahakkukta: hiç ödememek, geç ödemekten daha yüksek risk.
	late := Evaluate(History{
		UnitID: "a", TotalAssessments: 10, PaidLate: 10,
		AverageDelayDays: d("10"), CurrentDebt: decimal.Zero,
	})
	unpaid := Evaluate(History{
		UnitID: "b", TotalAssessments: 10, Unpaid: 10,
		AverageDelayDays: d("10"), CurrentDebt: d("1000"), LongestOverdueDays: 30,
	})
	if unpaid.Score <= late.Score {
		t.Fatalf("hiç ödemeyen (%d) geç ödeyenden (%d) daha riskli çıkmadı",
			unpaid.Score, late.Score)
	}
}

func TestEvaluateKisaGecmisGuvenilirSayilmaz(t *testing.T) {
	// Yeni taşınan bir sakin tek bir gecikmeyle damgalanmamalı.
	a := Evaluate(History{
		UnitID: "a", TotalAssessments: 1, Unpaid: 1,
		CurrentDebt: d("1200"), LongestOverdueDays: 40, AverageDelayDays: d("40"),
	})
	if a.Reliable {
		t.Fatal("tek tahakkukluk geçmişle skor güvenilir sayıldı")
	}
	if a.Action != "EARLY_REMINDER" {
		t.Fatalf("kısa geçmişte sert işlem önerildi: %s", a.Action)
	}
	if !strings.Contains(a.Note, "haksızlık") {
		t.Fatalf("kısa geçmiş uyarısı yetersiz: %s", a.Note)
	}
}

func TestEvaluateHerBilesenGerekceliDoner(t *testing.T) {
	a := Evaluate(History{
		UnitID: "a", TotalAssessments: 10, PaidOnTime: 4, PaidLate: 3, Unpaid: 3,
		AverageDelayDays: d("25"), CurrentDebt: d("3600"), LongestOverdueDays: 90,
	})
	if len(a.Factors) == 0 {
		t.Fatal("skorun bileşenleri dönmedi (açıklanabilirlik yok)")
	}
	sum := 0
	for _, f := range a.Factors {
		if f.Detail == "" {
			t.Fatalf("%s bileşeninin açıklaması yok", f.Code)
		}
		sum += f.Points
	}
	if sum != a.Score {
		t.Fatalf("bileşenlerin toplamı (%d) skoru (%d) vermiyor", sum, a.Score)
	}
}

func TestEvaluateSkorSinirlari(t *testing.T) {
	// En kötü durumda bile skor 100'ü aşmamalı.
	a := Evaluate(History{
		UnitID: "a", TotalAssessments: 50, Unpaid: 50,
		AverageDelayDays: d("9999"), CurrentDebt: d("999999"), LongestOverdueDays: 3650,
	})
	if a.Score > 100 || a.Score < 0 {
		t.Fatalf("skor aralık dışında: %d", a.Score)
	}
}
