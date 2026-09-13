// Package service, ödeme riski değerlendirmesini içerir.
//
// BU PAKETTE YAPAY ZEKÂ YOKTUR. Skor, ağırlıkları burada açıkça yazılı bir
// KURAL TOPLAMIDIR ve her bileşeni gerekçesiyle birlikte döner. Şemadaki
// `ai_model_version` ve `predicted_payment_probability` alanları doldurulmaz:
// bir model olmadan "ödeme olasılığı %62" demek uydurmadır.
//
// Neden açıklanabilirlik şart: skor, sakine karşı icra takibi başlatma gibi
// sonuçlar doğurabilecek bir yönetim kararını besler (KMK m.20/2, m.22).
// Gerekçesi gösterilemeyen bir skor, yönetimin hesap veremeyeceği bir karardır.
package service

import (
	"github.com/shopspring/decimal"
)

// Factor, skoru oluşturan tek bir bileşendir.
type Factor struct {
	Code   string `json:"code"`
	Points int    `json:"points"`
	Detail string `json:"detail"`
}

// History, bir bağımsız bölümün ödeme geçmişi özetidir.
type History struct {
	UnitID   string
	UnitName string
	// TotalAssessments, değerlendirmeye giren tahakkuk sayısı.
	TotalAssessments int
	PaidOnTime       int
	PaidLate         int
	Unpaid           int
	// AverageDelayDays, geç ödenen tahakkuklardaki ortalama gecikme.
	AverageDelayDays decimal.Decimal
	// CurrentDebt, güncel borç (TL).
	CurrentDebt decimal.Decimal
	// OverdueCount, vadesi geçmiş ödenmemiş tahakkuk sayısı.
	OverdueCount int
	// LongestOverdueDays, en eski ödenmemiş tahakkuğun gecikme günü.
	LongestOverdueDays int
}

// Assessment, bir bağımsız bölümün risk değerlendirmesidir.
type Assessment struct {
	UnitID   string `json:"unit_id"`
	UnitName string `json:"unit_name"`
	Score    int    `json:"risk_score"`
	Category string `json:"risk_category"`

	TotalAssessments   int    `json:"total_assessments"`
	PaidOnTime         int    `json:"paid_on_time"`
	PaidLate           int    `json:"paid_late"`
	Unpaid             int    `json:"unpaid"`
	AverageDelayDays   string `json:"average_delay_days"`
	CurrentDebt        string `json:"current_debt"`
	LongestOverdueDays int    `json:"longest_overdue_days"`

	Factors []Factor `json:"factors"`
	// Action, yönetime önerilen ilk adımdır — otomatik uygulanmaz.
	Action       string `json:"suggested_action"`
	ActionReason string `json:"suggested_action_reason"`
	// Reliable false ise geçmiş verisi skoru anlamlı kılacak kadar uzun değildir.
	Reliable bool   `json:"reliable"`
	Note     string `json:"note,omitempty"`
}

// MinHistoryForScore, skorun anlamlı sayılması için gereken en az tahakkuk sayısı.
// Tek bir aylık gecikmeye bakıp "yüksek riskli" demek, yeni taşınan bir sakini
// haksız yere damgalar.
const MinHistoryForScore = 3

// Evaluate, ödeme geçmişinden risk skorunu hesaplar.
//
// Skor 0-100 arasıdır; yüksek skor yüksek risk demektir. Bileşenler:
//
//	ödenmemiş oranı            → en çok 40 puan
//	geç ödeme oranı            → en çok 20 puan
//	ortalama gecikme süresi    → en çok 15 puan
//	en uzun süren gecikme      → en çok 25 puan
//
// Ağırlıkların toplamı 100'dür. Ödenmemiş tahakkuk en ağır bileşendir: geç
// ödeyen sonunda ödemiştir, hiç ödemeyen ödememiştir.
func Evaluate(h History) Assessment {
	a := Assessment{
		UnitID: h.UnitID, UnitName: h.UnitName,
		TotalAssessments:   h.TotalAssessments,
		PaidOnTime:         h.PaidOnTime,
		PaidLate:           h.PaidLate,
		Unpaid:             h.Unpaid,
		AverageDelayDays:   h.AverageDelayDays.Round(1).String(),
		CurrentDebt:        h.CurrentDebt.Round(2).String(),
		LongestOverdueDays: h.LongestOverdueDays,
		Factors:            []Factor{},
	}

	if h.TotalAssessments == 0 {
		a.Category = "LOW"
		a.Reliable = false
		a.Note = "Bu bağımsız bölüm için hiç tahakkuk kaydı yok; risk değerlendirmesi yapılamaz."
		a.Action = "NONE"
		a.ActionReason = "Değerlendirilecek ödeme geçmişi yok."
		return a
	}

	total := decimal.NewFromInt(int64(h.TotalAssessments))
	score := 0

	// 1) Ödenmemiş oranı — en ağır bileşen.
	if h.Unpaid > 0 {
		ratio := decimal.NewFromInt(int64(h.Unpaid)).Div(total)
		pts := int(ratio.Mul(decimal.NewFromInt(40)).Round(0).IntPart())
		score += pts
		a.Factors = append(a.Factors, Factor{
			Code: "UNPAID_RATIO", Points: pts,
			Detail: pluralTR(h.Unpaid, "tahakkuk") + " hiç ödenmemiş (" +
				ratio.Mul(decimal.NewFromInt(100)).Round(0).String() + "%).",
		})
	}

	// 2) Geç ödeme oranı.
	if h.PaidLate > 0 {
		ratio := decimal.NewFromInt(int64(h.PaidLate)).Div(total)
		pts := int(ratio.Mul(decimal.NewFromInt(20)).Round(0).IntPart())
		score += pts
		a.Factors = append(a.Factors, Factor{
			Code: "LATE_RATIO", Points: pts,
			Detail: pluralTR(h.PaidLate, "tahakkuk") + " vadesinden sonra ödenmiş.",
		})
	}

	// 3) Ortalama gecikme süresi — 60 gün ve üzeri tam puan.
	if h.AverageDelayDays.GreaterThan(decimal.Zero) {
		capped := h.AverageDelayDays
		sixty := decimal.NewFromInt(60)
		if capped.GreaterThan(sixty) {
			capped = sixty
		}
		pts := int(capped.Div(sixty).Mul(decimal.NewFromInt(15)).Round(0).IntPart())
		score += pts
		a.Factors = append(a.Factors, Factor{
			Code: "AVG_DELAY", Points: pts,
			Detail: "Ortalama gecikme " + h.AverageDelayDays.Round(0).String() + " gün.",
		})
	}

	// 4) En uzun süren gecikme — 180 gün ve üzeri tam puan.
	// KMK m.22: gecikmede kat maliki aleyhine icra takibi ve kanuni ipotek
	// yolları açıktır; uzun süren borç, yönetimin hukuki adım atmayı
	// değerlendirmesi gereken eşiktir.
	if h.LongestOverdueDays > 0 {
		capped := h.LongestOverdueDays
		if capped > 180 {
			capped = 180
		}
		pts := int(decimal.NewFromInt(int64(capped)).
			Div(decimal.NewFromInt(180)).Mul(decimal.NewFromInt(25)).Round(0).IntPart())
		score += pts
		a.Factors = append(a.Factors, Factor{
			Code: "LONGEST_OVERDUE", Points: pts,
			Detail: "En eski ödenmemiş borç " + itoa(h.LongestOverdueDays) + " gündür bekliyor.",
		})
	}

	if score > 100 {
		score = 100
	}
	a.Score = score

	switch {
	case score >= 75:
		a.Category = "CRITICAL"
	case score >= 50:
		a.Category = "HIGH"
	case score >= 25:
		a.Category = "MEDIUM"
	default:
		a.Category = "LOW"
	}

	a.Reliable = h.TotalAssessments >= MinHistoryForScore
	if !a.Reliable {
		a.Note = "Ödeme geçmişi " + itoa(h.TotalAssessments) + " tahakkukla sınırlı; " +
			"skor yönlendirici sayılmamalıdır. Tek bir gecikmeye bakıp yeni taşınan " +
			"bir sakini riskli ilan etmek haksızlıktır."
	}

	a.Action, a.ActionReason = suggestAction(h, a.Category, a.Reliable)
	return a
}

// suggestAction, yönetime ilk adımı önerir. ÖNERİDİR; otomatik uygulanmaz.
//
// Sıralama bilinçli olarak yumuşaktan sertee doğrudur: icra takibi (KMK m.22)
// son adımdır ve önce hatırlatma/görüşme denenmelidir. Bir yazılımın kendiliğinden
// icra başlatması hem hukuken hem de komşuluk ilişkileri açısından yanlıştır.
func suggestAction(h History, category string, reliable bool) (string, string) {
	if h.CurrentDebt.LessThanOrEqual(decimal.Zero) && h.Unpaid == 0 {
		return "NONE", "Güncel borç yok; bir işlem gerekmiyor."
	}
	if !reliable {
		return "EARLY_REMINDER", "Ödeme geçmişi kısa; önce nazik bir hatırlatma uygundur."
	}

	switch category {
	case "CRITICAL":
		return "LEGAL_REVIEW", "Borç uzun süredir ödenmemiş. Yönetim, icra takibi ve " +
			"kanuni ipotek yollarını (634 s. KMK m.22) DEĞERLENDİRMELİDİR. Bu bir " +
			"öneridir; hukuki adım yönetim kararıyla ve gerekli hâllerde kat malikleri " +
			"kurulu kararıyla atılır."
	case "HIGH":
		return "PERSONAL_CONTACT", "Yazılı hatırlatmalar sonuç vermemiş görünüyor; " +
			"yüz yüze ya da telefonla görüşme önerilir."
	case "MEDIUM":
		return "INSTALLMENT", "Ödeme güçlüğü izlenimi var; taksitlendirme görüşmesi " +
			"tahsilatı hızlandırabilir."
	default:
		return "EARLY_REMINDER", "Erken hatırlatma çoğu gecikmeyi önler."
	}
}

func itoa(n int) string {
	return decimal.NewFromInt(int64(n)).String()
}

// pluralTR, Türkçede sayıdan sonra çokluk eki kullanılmadığı için sayıyı ve
// tekil ismi birleştirir ("3 tahakkuk").
func pluralTR(n int, noun string) string {
	return itoa(n) + " " + noun
}
