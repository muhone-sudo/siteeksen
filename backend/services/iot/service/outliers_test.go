package service

import (
	"testing"

	"github.com/shopspring/decimal"
)

func ub(id string, cons, area int64) UnitBasis {
	return UnitBasis{UnitID: id, UnitName: id, Consumption: decimal.NewFromInt(cons), UsableArea: decimal.NewFromInt(area)}
}

func TestFindOutliersMedyanin3Kati(t *testing.T) {
	// m² başına: 1, 1, 1.2, 0.9, 5 → medyan 1; 5 > 3 → tek sapma
	got := FindOutliers([]UnitBasis{ub("A", 100, 100), ub("B", 80, 80), ub("C", 120, 100), ub("D", 90, 100), ub("E", 500, 100)})
	if len(got) != 1 || got[0].UnitID != "E" || got[0].Ratio != "5.00" || got[0].Basis != "AREA" {
		t.Fatalf("yalnız E sapmalı (5.00): %+v", got)
	}
}

func TestFindOutliersAzBolumdeVeSifirTuketimde(t *testing.T) {
	if got := FindOutliers([]UnitBasis{ub("A", 100, 100), ub("B", 900, 100)}); got != nil {
		t.Fatalf("2 bölümle medyan anlamsız: %+v", got)
	}
	// Sıfır tüketimli bölümler medyana girmez (okuması olmayan daire medyanı düşürmesin)
	got := FindOutliers([]UnitBasis{ub("A", 0, 100), ub("B", 0, 100), ub("C", 100, 100), ub("D", 110, 100), ub("E", 105, 100)})
	if len(got) != 0 {
		t.Fatalf("sapma olmamalı: %+v", got)
	}
}

func TestFindOutliersAlanYoksaTuketim(t *testing.T) {
	got := FindOutliers([]UnitBasis{ub("A", 10, 0), ub("B", 12, 0), ub("C", 11, 0), ub("D", 40, 0)})
	if len(got) != 1 || got[0].UnitID != "D" || got[0].Basis != "CONSUMPTION" {
		t.Fatalf("alan yoksa doğrudan tüketim kullanılmalı: %+v", got)
	}
}
