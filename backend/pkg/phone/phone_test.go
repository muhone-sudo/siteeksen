package phone

import "testing"

func TestNormalize(t *testing.T) {
	ok := map[string]string{
		"05551234567":        "+905551234567",
		"0 (555) 123-45-67":  "+905551234567",
		"5551234567":         "+905551234567",
		"905551234567":       "+905551234567",
		"+90 555 123 4567":   "+905551234567",
		"0090 555 123 45 67": "+905551234567",
		"+352 621 123 456":   "+352621123456", // Lüksemburg
		"00352621123456":     "+352621123456",
		"+49 151 23456789":   "+4915123456789", // Almanya
		"0049 151 2345 6789": "+4915123456789",
		"+1 (212) 555-0100":  "+12125550100",
		"+44 7700 900123":    "+447700900123",
		"0212 555 01 00":     "+902125550100", // sabit hat
	}
	for in, want := range ok {
		got, err := Normalize(in)
		if err != nil || got != want {
			t.Errorf("Normalize(%q) = %q, %v; beklenen %q", in, got, err, want)
		}
	}
	bad := []string{
		"", "abc", "555123", "+90 555 123", "+90 0555 123 4567", "+0123456789",
		"0000555123", "+1234567", "+1234567890123456", "555-ABC-1234", "5551234567+", "++905551234567",
	}
	for _, in := range bad {
		if got, err := Normalize(in); err == nil {
			t.Errorf("Normalize(%q) = %q; geçersiz olmalıydı", in, got)
		}
	}
}

func TestNational(t *testing.T) {
	if got := National("+905551234567"); got != "5551234567" {
		t.Errorf("TR: %q", got)
	}
	if got := National("+4915123456789"); got != "23456789" {
		t.Errorf("DE: %q", got)
	}
}
