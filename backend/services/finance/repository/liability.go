package repository

// Gider sınıfı (migration 066, altıncı tur D1).
//
// USAGE (KULLANIM): daireyi kullananın gideri (kapıcı, temizlik, ısınma, ortak elektrik/su, bakım).
// OWNER (MALİK)   : mülkiyetin gideri (demirbaş, yenilik, yeni tesis, ana yapı onarımı/yenilemesi).
// Siteye karşı kanuni borçlu malikdir; kiracı kira bedeliyle sınırlı müteselsil sorumludur (KMK m.20, m.22).
// Sınıf, borcun kimin ekranında görüneceğini ve kimin ödeyeceğini belirler.

import (
	"fmt"
	"strings"
)

const (
	// LiabilityUsage: oturanın (kiracı ya da oturan malik) gideri.
	LiabilityUsage = "USAGE"
	// LiabilityOwner: malikin gideri.
	LiabilityOwner = "OWNER"
)

// Liabilities, sınıfların belirlenimci sırasıdır.
var Liabilities = []string{LiabilityUsage, LiabilityOwner}

// NormalizeLiability, girişteki sınıfı doğrular; boşsa fallback (kategorinin varsayılanı) kullanılır.
func NormalizeLiability(v, fallback string) (string, error) {
	v = strings.ToUpper(strings.TrimSpace(v))
	if v == "" {
		v = strings.ToUpper(strings.TrimSpace(fallback))
	}
	if v == "" {
		v = LiabilityUsage
	}
	if v != LiabilityUsage && v != LiabilityOwner {
		return "", fmt.Errorf("%w: gider sınıfı USAGE (kullanım/oturan) ya da OWNER (malik) olmalı", ErrInvalidAssessmentInput)
	}
	return v, nil
}
