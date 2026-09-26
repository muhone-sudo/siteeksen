package money

import (
	"fmt"
	"math/rand"
	"testing"

	"github.com/shopspring/decimal"
)

func dec(s string) decimal.Decimal {
	d, err := decimal.NewFromString(s)
	if err != nil {
		panic(err)
	}
	return d
}

// Dağıtımın DEĞİŞMEZ KURALI: payların toplamı daima dağıtılan tutara eşittir.
// Bu test, denetimde tespit edilen "her payı ayrı yuvarla" hatasının geri
// gelmesini engeller.
func TestDistribute_ToplamHepDagitilanTutaraEsit(t *testing.T) {
	cases := []struct {
		total   Kurus
		weights []string
	}{
		{100, []string{"1", "1", "1"}},                       // 3'e bölünmez
		{10000, []string{"400", "400", "420", "420", "420"}}, // gerçek arsa payları
		{1, []string{"1", "1", "1", "1", "1"}},               // 1 kuruş, 5 daire
		{99999, []string{"7", "11", "13"}},
		{0, []string{"1", "2", "3"}},
		{123457, []string{"380", "380", "410", "410", "415", "415", "415", "415", "420", "420", "460", "460"}},
	}

	for _, tc := range cases {
		shares := make([]Share, len(tc.weights))
		for i, w := range tc.weights {
			shares[i] = Share{Key: fmt.Sprintf("unit-%02d", i), Weight: dec(w)}
		}
		out, err := Distribute(tc.total, shares)
		if err != nil {
			t.Fatalf("dağıtım hatası: %v", err)
		}
		if got := Sum(out); got != tc.total {
			t.Errorf("toplam %d, beklenen %d (ağırlıklar=%v)", got, tc.total, tc.weights)
		}
	}
}

// Rastgele girdilerle de aynı değişmez kural geçerli olmalı.
func TestDistribute_RastgeleGirdilerdeKurusKaybiYok(t *testing.T) {
	rng := rand.New(rand.NewSource(20260913))
	for i := 0; i < 2000; i++ {
		n := 1 + rng.Intn(60)
		total := Kurus(rng.Int63n(50_000_000))
		shares := make([]Share, n)
		for j := 0; j < n; j++ {
			shares[j] = Share{
				Key:    fmt.Sprintf("u%03d", j),
				Weight: decimal.NewFromInt(rng.Int63n(1000) + 1),
			}
		}
		out, err := Distribute(total, shares)
		if err != nil {
			t.Fatalf("dağıtım hatası: %v", err)
		}
		if got := Sum(out); got != total {
			t.Fatalf("tur %d: toplam %d, beklenen %d", i, got, total)
		}
		for _, s := range out {
			if s.Amount < 0 {
				t.Fatalf("negatif pay: %s = %d", s.Key, s.Amount)
			}
		}
	}
}

// Aynı girdi daima aynı çıktıyı vermeli: tahakkuk yeniden hesaplandığında
// daireler arasında kuruş yer değiştirmemeli.
func TestDistribute_Belirlenimci(t *testing.T) {
	shares := []Share{
		{Key: "b", Weight: dec("1")},
		{Key: "a", Weight: dec("1")},
		{Key: "c", Weight: dec("1")},
	}
	first, err := Distribute(100, shares)
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 50; i++ {
		again, err := Distribute(100, shares)
		if err != nil {
			t.Fatal(err)
		}
		for j := range first {
			if first[j].Amount != again[j].Amount {
				t.Fatalf("belirlenimci değil: %s %d != %d", first[j].Key, first[j].Amount, again[j].Amount)
			}
		}
	}
}

// Artan kuruş, kesirli kalanı en büyük olan paya gitmeli.
func TestDistribute_ArtanKurusEnBuyukKalanaGider(t *testing.T) {
	// 100 kuruş, ağırlıklar 1:1:1 → her biri 33,33; 1 kuruş artar.
	out, err := Distribute(100, []Share{
		{Key: "a", Weight: dec("1")},
		{Key: "b", Weight: dec("1")},
		{Key: "c", Weight: dec("1")},
	})
	if err != nil {
		t.Fatal(err)
	}
	var thirtyFour, thirtyThree int
	for _, s := range out {
		switch s.Amount {
		case 34:
			thirtyFour++
		case 33:
			thirtyThree++
		default:
			t.Fatalf("beklenmeyen pay: %s = %d", s.Key, s.Amount)
		}
	}
	if thirtyFour != 1 || thirtyThree != 2 {
		t.Fatalf("dağılım yanlış: 34 alan %d, 33 alan %d", thirtyFour, thirtyThree)
	}
}

func TestDistribute_SifirAgirlikSifirPayAlir(t *testing.T) {
	out, err := Distribute(1000, []Share{
		{Key: "bos", Weight: decimal.Zero},
		{Key: "dolu", Weight: dec("1")},
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, s := range out {
		if s.Key == "bos" && s.Amount != 0 {
			t.Errorf("sıfır ağırlıklı kalem pay aldı: %d", s.Amount)
		}
		if s.Key == "dolu" && s.Amount != 1000 {
			t.Errorf("tek ağırlıklı kalem tutarın tamamını almadı: %d", s.Amount)
		}
	}
}

func TestDistribute_HataDurumlari(t *testing.T) {
	if _, err := Distribute(-1, []Share{{Key: "a", Weight: dec("1")}}); err != ErrNegativeAmount {
		t.Errorf("negatif tutar kabul edildi")
	}
	if _, err := Distribute(100, nil); err != ErrNoWeights {
		t.Errorf("boş ağırlık listesi kabul edildi")
	}
	if _, err := Distribute(100, []Share{{Key: "a", Weight: decimal.Zero}}); err != ErrNoWeights {
		t.Errorf("toplamı sıfır ağırlık kabul edildi")
	}
	if _, err := Distribute(100, []Share{{Key: "a", Weight: dec("-1")}}); err == nil {
		t.Errorf("negatif ağırlık kabul edildi")
	}
}

func TestDistributeEqual(t *testing.T) {
	out, err := DistributeEqual(1000, []string{"a", "b", "c", "d", "e", "f", "g"})
	if err != nil {
		t.Fatal(err)
	}
	if Sum(out) != 1000 {
		t.Fatalf("eşit dağıtımda toplam tutmadı: %d", Sum(out))
	}
	// 1000/7 = 142,857… → 6 daire 143, 1 daire 142 olmalı (ya da tersi) ama fark en çok 1 kuruş.
	min, max := out[0].Amount, out[0].Amount
	for _, s := range out {
		if s.Amount < min {
			min = s.Amount
		}
		if s.Amount > max {
			max = s.Amount
		}
	}
	if max-min > 1 {
		t.Errorf("eşit dağıtımda paylar arasında 1 kuruştan fazla fark var: %d..%d", min, max)
	}
}

// KMK m.20/2 — aylık %5.
func TestLateFee(t *testing.T) {
	rate := dec("0.05")

	// 1000,00 TL (100000 kuruş) anapara, 30 gün gecikme → tam 1 aylık %5 = 50,00 TL
	fee, err := LateFee(100000, rate, 30)
	if err != nil {
		t.Fatal(err)
	}
	if fee != 5000 {
		t.Errorf("30 günlük gecikme tazminatı %d kuruş, beklenen 5000", fee)
	}

	// 15 gün → yarısı
	fee, _ = LateFee(100000, rate, 15)
	if fee != 2500 {
		t.Errorf("15 günlük gecikme tazminatı %d kuruş, beklenen 2500", fee)
	}

	// Gecikme yoksa tazminat yok
	fee, _ = LateFee(100000, rate, 0)
	if fee != 0 {
		t.Errorf("gecikme yokken tazminat hesaplandı: %d", fee)
	}
	fee, _ = LateFee(100000, rate, -5)
	if fee != 0 {
		t.Errorf("negatif gün için tazminat hesaplandı: %d", fee)
	}

	if _, err := LateFee(-1, rate, 10); err != ErrNegativeAmount {
		t.Errorf("negatif anapara kabul edildi")
	}
	if _, err := LateFee(100, dec("-0.1"), 10); err == nil {
		t.Errorf("negatif oran kabul edildi")
	}
}

func TestKurusDonusum(t *testing.T) {
	cases := []struct {
		try  string
		want Kurus
	}{
		{"0", 0},
		{"1", 100},
		{"1234.56", 123456},
		{"0.005", 1}, // yarı yukarı
		{"0.004", 0}, // yarı altı aşağı
		{"-12.34", -1234},
	}
	for _, c := range cases {
		if got := FromTRY(dec(c.try)); got != c.want {
			t.Errorf("FromTRY(%s) = %d, beklenen %d", c.try, got, c.want)
		}
	}

	if got := Kurus(123456).String(); got != "1234.56" {
		t.Errorf("String() = %q, beklenen \"1234.56\"", got)
	}
}

func TestKurusDisplay(t *testing.T) {
	cases := map[Kurus]string{
		0:          "0,00 TL",
		5:          "0,05 TL",
		100:        "1,00 TL",
		99999:      "999,99 TL",
		123456:     "1.234,56 TL",
		100000000:  "1.000.000,00 TL",
		-123456789: "-1.234.567,89 TL",
	}
	for k, want := range cases {
		if got := k.Display(); got != want {
			t.Errorf("Display(%d) = %q, beklenen %q", k, got, want)
		}
	}
}

// float64 ile kuruş aritmetiğinin neden bırakıldığını belgeleyen test.
// 0.1 + 0.2 != 0.3 olduğu için float toplamları kuruş hassasiyetinde sapar;
// Kurus (tam sayı) toplamları sapmaz.
func TestKurus_FloatSapmasiYok(t *testing.T) {
	var floatTotal float64
	var kurusTotal Kurus
	for i := 0; i < 10000; i++ {
		floatTotal += 0.1
		kurusTotal += FromTRY(dec("0.1"))
	}
	if kurusTotal != 100000 {
		t.Fatalf("kuruş toplamı sapmış: %d", kurusTotal)
	}
	if floatTotal == 1000.0 {
		t.Log("bu çalıştırmada float sapması görünmedi; kuruş yolu yine de tek doğru yöntemdir")
	}
}
