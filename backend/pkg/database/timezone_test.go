package database

import (
	"testing"
	"time"
)

func TestApplyTimeZoneVarsayilanIstanbul(t *testing.T) {
	old := time.Local
	defer func() { time.Local = old }()

	loc, err := ApplyTimeZone("")
	if err != nil {
		t.Fatal(err)
	}
	if loc.String() != DefaultTimeZone || time.Local.String() != DefaultTimeZone {
		t.Fatalf("saat dilimi: %s / %s", loc, time.Local)
	}
	// 2026-10-03 22:30 UTC, İstanbul'da 4 Ekim'dir: iş günü yerel saate göre hesaplanmalı.
	utc := time.Date(2026, 10, 3, 22, 30, 0, 0, time.UTC)
	if d := utc.In(time.Local).Day(); d != 4 {
		t.Fatalf("iş günü %d (4 bekleniyordu)", d)
	}
}

func TestApplyTimeZoneGecersizAdReddedilir(t *testing.T) {
	old := time.Local
	defer func() { time.Local = old }()
	if _, err := ApplyTimeZone("Mars/Olympus"); err == nil {
		t.Fatal("geçersiz saat dilimi kabul edildi")
	}
	if time.Local != old {
		t.Fatal("hatalı ad yerel saati değiştirdi")
	}
}
