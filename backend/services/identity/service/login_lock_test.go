package service

import (
	"testing"
	"time"
)

func TestLoginLockForKademeli(t *testing.T) {
	cases := map[int]time.Duration{
		1: 0, 4: 0,
		5: 30 * time.Second,
		6: 2 * time.Minute,
		7: 15 * time.Minute, 20: 15 * time.Minute,
	}
	for n, want := range cases {
		if got := LoginLockFor(n); got != want {
			t.Fatalf("%d. hata: %v beklenirken %v", n, want, got)
		}
	}
}
