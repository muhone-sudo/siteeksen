package store

import (
	"testing"
	"time"
)

// "Bugün" iş saat dilimindeki gündür: İstanbul'da 2 Kasım 01:00 (UTC'de hâlâ 1 Kasım) iken 1 Kasım geçmiş gündür.
func TestTodayUsesLocalDate(t *testing.T) {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		t.Skip("saat dilimi verisi yok")
	}
	old := time.Local
	time.Local = loc
	defer func() { time.Local = old }()
	yesterday, _ := time.Parse("2006-01-02", "2026-11-01")
	got := today(time.Date(2026, 11, 2, 1, 0, 0, 0, loc))
	if !yesterday.Before(got) {
		t.Fatalf("today = %s; 2026-11-01 geçmiş gün sayılmalı", got)
	}
	if want, _ := time.Parse("2006-01-02", "2026-11-02"); !got.Equal(want) {
		t.Fatalf("today = %s, beklenen %s", got, want)
	}
}
