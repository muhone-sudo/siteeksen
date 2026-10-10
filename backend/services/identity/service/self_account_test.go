package service

import "testing"

func TestValidEmail(t *testing.T) {
	for _, ok := range []string{"a@b.co", "ahmet.yilmaz@ornek.com.tr", "x+site@mail.org"} {
		if !ValidEmail(ok) {
			t.Fatalf("geçerli sayılmalı: %q", ok)
		}
	}
	for _, bad := range []string{"", "a@b", "ad soyad@x.com", "Ahmet <a@b.com>", "@b.com", "a@", "a@b.com,c@d.com"} {
		if ValidEmail(bad) {
			t.Fatalf("geçersiz sayılmalı: %q", bad)
		}
	}
}
