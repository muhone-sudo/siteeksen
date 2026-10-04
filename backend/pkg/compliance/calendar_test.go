package compliance

import (
	"testing"
	"time"
)

func d(s string) time.Time { t, _ := time.Parse("2006-01-02", s); return t }

func TestNextWorkday(t *testing.T) {
	cases := map[string]string{
		"2026-09-26": "2026-09-28", // cumartesi → pazartesi
		"2026-07-26": "2026-07-27", // pazar → pazartesi
		"2026-10-26": "2026-10-26", // pazartesi
	}
	for in, want := range cases {
		if got := NextWorkday(d(in)).Format("2006-01-02"); got != want {
			t.Errorf("NextWorkday(%s) = %s, want %s", in, got, want)
		}
	}
}

func TestMonthlyDue(t *testing.T) {
	// 4 Ekim 2026: Eylül dönemi 26 Ekim (pazartesi)
	due, period := MonthlyDue(d("2026-10-04"), 26)
	if due.Format("2006-01-02") != "2026-10-26" || period != "2026-09" {
		t.Fatalf("got %s %s", due.Format("2006-01-02"), period)
	}
	// Son gün bugünse bugün
	if due, _ := MonthlyDue(d("2026-10-26"), 26); due.Format("2006-01-02") != "2026-10-26" {
		t.Fatalf("aynı gün: %s", due.Format("2006-01-02"))
	}
	// 27 Ekim: Ekim dönemi 26 Kasım (perşembe)
	due, period = MonthlyDue(d("2026-10-27"), 26)
	if due.Format("2006-01-02") != "2026-11-26" || period != "2026-10" {
		t.Fatalf("got %s %s", due.Format("2006-01-02"), period)
	}
	// 26 Eylül 2026 cumartesi → 28 Eylül; 27 Eylül'de hâlâ ağustos dönemi geçerli
	due, period = MonthlyDue(d("2026-09-27"), 26)
	if due.Format("2006-01-02") != "2026-09-28" || period != "2026-08" {
		t.Fatalf("hafta sonu kayması: %s %s", due.Format("2006-01-02"), period)
	}
}

func TestMonthEndDue(t *testing.T) {
	// Ekim 2026 sonu cumartesi (31) → 2 Kasım pazartesi
	due, period := MonthEndDue(d("2026-10-04"))
	if due.Format("2006-01-02") != "2026-11-02" || period != "2026-09" {
		t.Fatalf("got %s %s", due.Format("2006-01-02"), period)
	}
	// 1 Kasım: 31 Ekim cumartesi olduğu için eylül primi hâlâ 2 Kasım'da
	due, period = MonthEndDue(d("2026-11-01"))
	if due.Format("2006-01-02") != "2026-11-02" || period != "2026-09" {
		t.Fatalf("ay başına kayan son gün: %s %s", due.Format("2006-01-02"), period)
	}
	due, _ = MonthEndDue(d("2026-02-10"))
	if due.Format("2006-01-02") != "2026-03-02" { // 28 Şubat 2026 cumartesi
		t.Fatalf("şubat: %s", due.Format("2006-01-02"))
	}
}
