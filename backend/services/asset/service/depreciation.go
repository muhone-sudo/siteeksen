// Package service, demirbaş modülünün hesaplamalarını içerir.
package service

import (
	"time"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/money"
)

// Depreciation, bir demirbaşın amortisman durumudur. Tutarlar TL'dir ve
// kuruşa yuvarlanmıştır (hesap `pkg/money` ile tam sayı kuruş üzerinden yapılır).
type Depreciation struct {
	// Accumulated, bugüne kadar birikmiş amortismandır.
	Accumulated float64 `json:"accumulated"`
	// BookValue, kayıtlı değerdir (maliyet − birikmiş amortisman).
	BookValue float64 `json:"book_value"`
	// AnnualAmount, yıllık amortisman payıdır.
	AnnualAmount float64 `json:"annual_amount"`
	// ElapsedMonths, satın almadan bugüne geçen tam ay sayısıdır.
	ElapsedMonths int `json:"elapsed_months"`
	// FullyDepreciated true ise faydalı ömür dolmuştur.
	FullyDepreciated bool `json:"fully_depreciated"`
}

// LinearDepreciation, doğrusal (normal) amortismanı hesaplar.
//
// Yöntem: amortismana tabi tutar = maliyet − kalıntı değer; yıllık pay bu tutarın
// faydalı ömre bölümüdür. Birikmiş amortisman, satın alma tarihinden bugüne geçen
// TAM AY sayısı üzerinden orantılanır ve amortismana tabi tutarı aşamaz.
//
// Neden ay bazlı: yıl bazlı hesap, yılın ortasında alınan bir demirbaşı ya hiç
// amortismana tabi tutmaz ya da tam yıl sayar; ikisi de defter değerini yanıltır.
// (Vergi mevzuatındaki "alındığı yıl tam yıl sayılır" kuralı MALİ kâr hesabı
// içindir; burada amaç yönetimin gerçek defter değerini görmesidir — işletme
// projesi ve demirbaş devri bunun üzerinden konuşulur.)
//
// Hesap tamamen tam sayı kuruş üzerinden yapılır; float birikmesi yoktur.
// Geçersiz girdide (maliyet yok, ömür yok/sıfır, tarih yok) nil döner —
// uydurma bir değer üretilmez.
func LinearDepreciation(purchasePrice *float64, residual float64, years *int, purchaseDate *time.Time, now time.Time) *Depreciation {
	if purchasePrice == nil || years == nil || *years <= 0 || purchaseDate == nil {
		return nil
	}

	cost := money.FromFloatTRY(*purchasePrice)
	res := money.FromFloatTRY(residual)
	if res < 0 {
		res = 0
	}
	if res > cost {
		// Kalıntı değer maliyeti aşamaz; aşıyorsa amortismana tabi tutar sıfırdır.
		res = cost
	}
	base := cost - res
	if base <= 0 {
		return &Depreciation{
			Accumulated: 0, BookValue: cost.TRY().InexactFloat64(),
			AnnualAmount: 0, ElapsedMonths: 0, FullyDepreciated: true,
		}
	}

	months := monthsBetween(*purchaseDate, now)
	if months < 0 {
		months = 0 // gelecek tarihli satın alma: henüz amortisman yok
	}
	totalMonths := *years * 12

	annual := decimal.NewFromInt(int64(base)).Div(decimal.NewFromInt(int64(*years)))

	var accumulated money.Kurus
	full := false
	if months >= totalMonths {
		accumulated = base
		full = true
	} else {
		// base * months / totalMonths — bölme en sonda yapılır ki kuruş kaybı olmasın.
		acc := decimal.NewFromInt(int64(base)).
			Mul(decimal.NewFromInt(int64(months))).
			Div(decimal.NewFromInt(int64(totalMonths))).
			Round(0)
		accumulated = money.Kurus(acc.IntPart())
	}

	return &Depreciation{
		Accumulated:      money.Kurus(accumulated).TRY().InexactFloat64(),
		BookValue:        money.Kurus(cost - accumulated).TRY().InexactFloat64(),
		AnnualAmount:     money.Kurus(annual.Round(0).IntPart()).TRY().InexactFloat64(),
		ElapsedMonths:    months,
		FullyDepreciated: full,
	}
}

// monthsBetween, iki tarih arasındaki TAM ay sayısını verir.
// 15 Ocak → 14 Şubat arası 0 ay, 15 Şubat 1 aydır.
func monthsBetween(from, to time.Time) int {
	months := (to.Year()-from.Year())*12 + int(to.Month()) - int(from.Month())
	if to.Day() < from.Day() {
		months--
	}
	return months
}
