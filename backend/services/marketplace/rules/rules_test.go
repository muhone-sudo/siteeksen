package rules

import "testing"

func f(v float64) *float64 { return &v }

func TestDistanceMeters(t *testing.T) {
	// Kadıköy iskelesi → Üsküdar iskelesi yaklaşık 4,2 km.
	d := DistanceMeters(40.9909, 29.0233, 41.0262, 29.0154)
	if d < 3800 || d > 4400 {
		t.Fatalf("uzaklık %.0f m", d)
	}
	if DistanceMeters(41, 29, 41, 29) != 0 {
		t.Fatal("aynı nokta 0 olmalı")
	}
}

func TestCovers(t *testing.T) {
	shop := Area{Kind: "KM", RadiusKm: 5, Lat: 40.9909, Lng: 29.0233, City: "İstanbul", District: "Kadıköy"}
	near := Site{Lat: f(41.0262), Lng: f(29.0154), City: "İstanbul", District: "Üsküdar"} // ~4,2 km
	far := Site{Lat: f(41.0766), Lng: f(29.0573), City: "İstanbul", District: "Sarıyer"}  // ~10 km
	if ok, d := Covers(shop, near); !ok || d == nil || *d > 5000 {
		t.Fatalf("5 km içi kapsanmalı: %v %v", ok, d)
	}
	if ok, _ := Covers(shop, far); ok {
		t.Fatal("5 km dışı kapsanmamalı")
	}
	shop.RadiusKm = 3
	if ok, _ := Covers(shop, near); ok {
		t.Fatal("yarıçap sınırı (3 km) aşılmamalı")
	}
	// Site koordinatı yoksa: KM için aynı il + ilçe yedeği
	noCoord := Site{City: "istanbul", District: " KADIKÖY "}
	if ok, d := Covers(shop, noCoord); !ok || d != nil {
		t.Fatalf("ilçe yedeği eşleşmeli (harf/boşluk farkı): %v %v", ok, d)
	}
	if ok, _ := Covers(shop, Site{City: "İstanbul", District: "Beşiktaş"}); ok {
		t.Fatal("başka ilçe yedekte eşleşmemeli")
	}
	city := Area{Kind: "CITY", City: "İzmir"}
	if ok, _ := Covers(city, Site{City: "izmir", District: "Karşıyaka"}); !ok {
		t.Fatal("tüm il: aynı il eşleşmeli")
	}
	if ok, _ := Covers(city, near); ok {
		t.Fatal("tüm il: başka il eşleşmemeli")
	}
	if ok, _ := Covers(Area{Kind: "COUNTRY"}, far); !ok {
		t.Fatal("Türkiye geneli her yeri kapsar")
	}
}

func TestRequestFee(t *testing.T) {
	cases := []struct {
		fee  int64
		pct  int
		want int64
	}{{4000, 0, 4000}, {4000, 25, 3000}, {3333, 50, 1667}, {999, 100, 0}, {12345, 10, 11111}}
	for _, c := range cases {
		if got := RequestFee(c.fee, c.pct); got != c.want {
			t.Errorf("RequestFee(%d,%d)=%d, beklenen %d", c.fee, c.pct, got, c.want)
		}
	}
}

func TestMaskContacts(t *testing.T) {
	cases := []struct{ in, want string }{
		{"Musluk akıtıyor, 0532 123 45 67 arayın", "Musluk akıtıyor, " + MaskedNotice + " arayın"},
		{"tel: +90 (555) 123-45-67.", "tel: " + MaskedNotice + "."},
		{"e-posta: usta.ali@ornek.com.tr", "e-posta: " + MaskedNotice},
		{"3 oda 2 salon, 120 m2, 2. kat", "3 oda 2 salon, 120 m2, 2. kat"},
		{"05551234567", MaskedNotice},
	}
	for _, c := range cases {
		got, _ := MaskContacts(c.in)
		if got != c.want {
			t.Errorf("MaskContacts(%q) = %q, beklenen %q", c.in, got, c.want)
		}
	}
}

func TestValidTaxNumber(t *testing.T) {
	for _, ok := range []string{"1234567890", "12345678901"} {
		if !ValidTaxNumber(ok) {
			t.Errorf("%s geçerli olmalı", ok)
		}
	}
	for _, bad := range []string{"", "123", "123456789a", "123456789012"} {
		if ValidTaxNumber(bad) {
			t.Errorf("%s geçersiz olmalı", bad)
		}
	}
}
