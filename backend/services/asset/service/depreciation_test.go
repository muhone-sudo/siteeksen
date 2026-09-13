package service

import (
	"testing"
	"time"
)

func d(s string) *time.Time {
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		panic(err)
	}
	return &t
}

func f(v float64) *float64 { return &v }
func i(v int) *int         { return &v }

func TestLinearDepreciationEksikVeridenUydurmaz(t *testing.T) {
	now := time.Date(2026, 9, 13, 0, 0, 0, 0, time.UTC)
	cases := []struct {
		ad    string
		price *float64
		years *int
		date  *time.Time
	}{
		{"fiyat yok", nil, i(5), d("2024-01-01")},
		{"ömür yok", f(10000), nil, d("2024-01-01")},
		{"ömür sıfır", f(10000), i(0), d("2024-01-01")},
		{"tarih yok", f(10000), i(5), nil},
	}
	for _, c := range cases {
		if got := LinearDepreciation(c.price, 0, c.years, c.date, now); got != nil {
			t.Errorf("%s: eksik veriyle hesap üretildi: %+v", c.ad, got)
		}
	}
}

func TestLinearDepreciationTamYil(t *testing.T) {
	// 10.000 TL, 5 yıl, kalıntı 0 → yıllık 2.000 TL.
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(10000), 0, i(5), d("2024-01-01"), now)
	if got == nil {
		t.Fatal("nil döndü")
	}
	if got.ElapsedMonths != 24 {
		t.Fatalf("geçen ay: %d (24 bekleniyordu)", got.ElapsedMonths)
	}
	if got.AnnualAmount != 2000 {
		t.Fatalf("yıllık pay: %v (2000 bekleniyordu)", got.AnnualAmount)
	}
	if got.Accumulated != 4000 {
		t.Fatalf("birikmiş: %v (4000 bekleniyordu)", got.Accumulated)
	}
	if got.BookValue != 6000 {
		t.Fatalf("defter değeri: %v (6000 bekleniyordu)", got.BookValue)
	}
	if got.FullyDepreciated {
		t.Fatal("5 yıllık ömrün 2. yılında 'tamamen itfa' dendi")
	}
}

func TestLinearDepreciationKalintiDeger(t *testing.T) {
	// 12.000 TL maliyet, 2.000 TL kalıntı, 5 yıl → amortismana tabi 10.000, yıllık 2.000.
	now := time.Date(2027, 1, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(12000), 2000, i(5), d("2024-01-01"), now)
	if got.Accumulated != 6000 {
		t.Fatalf("birikmiş: %v (6000 bekleniyordu)", got.Accumulated)
	}
	if got.BookValue != 6000 {
		t.Fatalf("defter değeri: %v (12000-6000=6000 bekleniyordu)", got.BookValue)
	}
}

func TestLinearDepreciationOmurDolunca(t *testing.T) {
	// Ömür dolduğunda defter değeri KALINTI DEĞERE eşit olmalı, sıfıra değil.
	now := time.Date(2031, 6, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(12000), 2000, i(5), d("2024-01-01"), now)
	if !got.FullyDepreciated {
		t.Fatal("ömür dolduğu hâlde 'tamamen itfa' denmedi")
	}
	if got.Accumulated != 10000 {
		t.Fatalf("birikmiş amortisman tutarı aştı: %v", got.Accumulated)
	}
	if got.BookValue != 2000 {
		t.Fatalf("defter değeri kalıntı değere inmedi: %v (2000 bekleniyordu)", got.BookValue)
	}
}

func TestLinearDepreciationAyOranlama(t *testing.T) {
	// 12.000 TL, 1 yıl → aylık 1.000 TL. 3 ay sonra 3.000 birikmiş olmalı.
	now := time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(12000), 0, i(1), d("2026-01-01"), now)
	if got.ElapsedMonths != 3 {
		t.Fatalf("geçen ay: %d", got.ElapsedMonths)
	}
	if got.Accumulated != 3000 {
		t.Fatalf("birikmiş: %v (3000 bekleniyordu)", got.Accumulated)
	}
}

func TestLinearDepreciationGelecekTarih(t *testing.T) {
	// Gelecek tarihli satın almada amortisman başlamaz (negatif birikme olmaz).
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(10000), 0, i(5), d("2026-06-01"), now)
	if got.Accumulated != 0 {
		t.Fatalf("gelecek tarihli alımda amortisman işledi: %v", got.Accumulated)
	}
	if got.BookValue != 10000 {
		t.Fatalf("defter değeri maliyetten farklı: %v", got.BookValue)
	}
}

func TestLinearDepreciationKurusKaybiYok(t *testing.T) {
	// 10.000,00 TL / 3 yıl → yıllık 3.333,33 TL. Ömür dolduğunda birikmiş
	// amortisman tam olarak amortismana tabi tutara eşit olmalı (kuruş kaybı yok).
	now := time.Date(2030, 1, 1, 0, 0, 0, 0, time.UTC)
	got := LinearDepreciation(f(10000), 0, i(3), d("2026-01-01"), now)
	if got.Accumulated != 10000 {
		t.Fatalf("kuruş kaybı var: %v (10000 bekleniyordu)", got.Accumulated)
	}
	if got.BookValue != 0 {
		t.Fatalf("defter değeri sıfırlanmadı: %v", got.BookValue)
	}
}

func TestMonthsBetweenGunHassasiyeti(t *testing.T) {
	from := time.Date(2026, 1, 15, 0, 0, 0, 0, time.UTC)
	if got := monthsBetween(from, time.Date(2026, 2, 14, 0, 0, 0, 0, time.UTC)); got != 0 {
		t.Fatalf("14 Şubat: %d ay (0 bekleniyordu)", got)
	}
	if got := monthsBetween(from, time.Date(2026, 2, 15, 0, 0, 0, 0, time.UTC)); got != 1 {
		t.Fatalf("15 Şubat: %d ay (1 bekleniyordu)", got)
	}
	if got := monthsBetween(from, time.Date(2027, 1, 15, 0, 0, 0, 0, time.UTC)); got != 12 {
		t.Fatalf("bir yıl sonra: %d ay (12 bekleniyordu)", got)
	}
}
