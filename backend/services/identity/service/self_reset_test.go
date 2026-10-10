package service

import (
	"testing"
	"time"
)

func TestSelfResetAllowedSiklikSiniri(t *testing.T) {
	now := time.Date(2026, 10, 10, 12, 0, 0, 0, time.UTC)
	ago := func(d time.Duration) *time.Time { x := now.Add(-d); return &x }
	cases := []struct {
		name     string
		last     *time.Time
		lastHour int
		want     bool
	}{
		{"hiç istek yok", nil, 0, true},
		{"60 sn dolmadı", ago(30 * time.Second), 1, false},
		{"60 sn doldu", ago(61 * time.Second), 1, true},
		{"saatte 3 doldu", ago(10 * time.Minute), 3, false},
		{"saatte 2", ago(10 * time.Minute), 2, true},
	}
	for _, c := range cases {
		if got := SelfResetAllowed(c.last, c.lastHour, now); got != c.want {
			t.Fatalf("%s: %v beklenirken %v", c.name, c.want, got)
		}
	}
}
