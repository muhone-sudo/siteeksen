package main

import (
	"testing"
	"time"
)

// Süzgeç günü iş saat diliminde başlamalı: UTC gece yarısı, İstanbul'da 00:00–03:00 arasındaki kayıtları dışarıda bırakır.
func TestParseDayStartsAtLocalMidnight(t *testing.T) {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		t.Skip("saat dilimi verisi yok")
	}
	old := time.Local
	time.Local = loc
	defer func() { time.Local = old }()
	got, err := parseDay("2026-11-02")
	if err != nil {
		t.Fatal(err)
	}
	if want := time.Date(2026, 11, 2, 0, 0, 0, 0, loc); !got.Equal(want) {
		t.Fatalf("parseDay = %s, beklenen %s", got, want)
	}
}
