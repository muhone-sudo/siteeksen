package service

import (
	"errors"
	"testing"
	"time"

	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
)

func TestValidateEndDate(t *testing.T) {
	now := time.Date(2026, 10, 11, 12, 0, 0, 0, time.Local)
	f, tr := false, true
	s := func(v string) *string { return &v }

	in := models.UpdateResidentInput{IsActive: &f, EndDate: s("2026-10-01")}
	if err := validateEndDate(&in, now); err != nil || *in.EndDate != "2026-10-01" {
		t.Fatalf("geçmiş tarih kabul edilmeli: %v", err)
	}
	in = models.UpdateResidentInput{IsActive: &f, EndDate: s("  ")}
	if err := validateEndDate(&in, now); err != nil || in.EndDate != nil {
		t.Fatalf("boş tarih 'verilmedi' sayılmalı: %v", err)
	}
	for name, bad := range map[string]models.UpdateResidentInput{
		"ileri tarih":        {IsActive: &f, EndDate: s("2026-10-12")},
		"biçim":              {IsActive: &f, EndDate: s("11.10.2026")},
		"aktif kayıt":        {IsActive: &tr, EndDate: s("2026-10-01")},
		"aktiflik verilmedi": {EndDate: s("2026-10-01")},
	} {
		b := bad
		if err := validateEndDate(&b, now); !errors.Is(err, repository.ErrInvalidEndDate) {
			t.Fatalf("%s reddedilmeli, hata: %v", name, err)
		}
	}
}
