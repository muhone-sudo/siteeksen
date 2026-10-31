package service

import (
	"testing"
	"time"
)

func TestSupplierSignupAllowed(t *testing.T) {
	now := time.Now()
	recent := now.Add(-30 * time.Second)
	old := now.Add(-2 * time.Minute)
	cases := []struct {
		name      string
		last      *time.Time
		ph, iph   int
		wantAllow bool
	}{
		{"ilk istek", nil, 0, 0, true},
		{"60 sn dolmadı", &recent, 1, 1, false},
		{"60 sn doldu", &old, 1, 1, true},
		{"numara saatte 3", &old, SupplierSignupPerPhoneHour, 3, false},
		{"IP saatte 10", nil, 0, SupplierSignupPerIPHour, false},
	}
	for _, c := range cases {
		if got := SupplierSignupAllowed(c.last, c.ph, c.iph, now); got != c.wantAllow {
			t.Errorf("%s: %v, beklenen %v", c.name, got, c.wantAllow)
		}
	}
}
