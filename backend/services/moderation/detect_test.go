package main

import "testing"

func TestFindContacts(t *testing.T) {
	cases := []struct {
		text string
		want []string
	}{
		{"Usta Ali Tesisat\n0532 123 45 67", []string{"PHONE"}},
		{"Ara: +90 (532) 123-45-67 hemen", []string{"PHONE"}},
		{"iletisim: ali@ornek.com", []string{"EMAIL"}},
		{"www.ustaali.com.tr", []string{"WEB"}},
		{"ustaali.com", []string{"WEB"}},
		{"Kombi bakımı 1500 TL, 2 yıl garanti", nil},
		{"Ölçü 120x60 cm, model 2024", nil},
		{"Kod 12345 6789", nil},
	}
	for _, c := range cases {
		got := findContacts(c.text)
		if len(got) != len(c.want) {
			t.Errorf("%q: %v, beklenen %v", c.text, got, c.want)
			continue
		}
		for i := range got {
			if got[i].Kind != c.want[i] {
				t.Errorf("%q: %v, beklenen %v", c.text, got, c.want)
			}
		}
	}
}
