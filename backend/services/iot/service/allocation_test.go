package service

import (
	"math/rand"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/money"
)

func dec(s string) decimal.Decimal {
	d, err := decimal.NewFromString(s)
	if err != nil {
		panic(err)
	}
	return d
}

var (
	share70 = dec("0.70")
	share30 = dec("0.30")
)

func sumTotals(a *Allocation) int64 {
	var t int64
	for _, u := range a.Units {
		t += u.TotalKurus
	}
	return t
}

func TestAllocateHeatingPaylarToplamiTutariTamKarsilar(t *testing.T) {
	// 10.000,00 TL = 1.000.000 kuruş
	total := money.Kurus(1_000_000)
	units := []UnitBasis{
		{UnitID: "a", UnitName: "A-1", Consumption: dec("100"), UsableArea: dec("85")},
		{UnitID: "b", UnitName: "A-2", Consumption: dec("150"), UsableArea: dec("95")},
		{UnitID: "c", UnitName: "A-3", Consumption: dec("0"), UsableArea: dec("120")},
	}
	a, err := AllocateHeating(total, share70, share30, units)
	if err != nil {
		t.Fatal(err)
	}
	if got := sumTotals(a); got != int64(total) {
		t.Fatalf("payların toplamı tutarı karşılamıyor: %d != %d (kuruş kaybı)", got, total)
	}
	if a.ConsumptionPartKurus+a.AreaPartKurus != int64(total) {
		t.Fatalf("bileşenlerin toplamı yanlış: %d + %d",
			a.ConsumptionPartKurus, a.AreaPartKurus)
	}
	if a.ConsumptionPartKurus != 700_000 || a.AreaPartKurus != 300_000 {
		t.Fatalf("70/30 ayrımı yanlış: %d / %d", a.ConsumptionPartKurus, a.AreaPartKurus)
	}
}

func TestAllocateHeatingTuketmeyenSabitPayiOder(t *testing.T) {
	// Yönetmeliğin can alıcı kuralı: hiç tüketim yapmayan bağımsız bölüm de
	// SABİT PAYI öder (ısı komşu bölümlerden geçer).
	total := money.Kurus(1_000_000)
	units := []UnitBasis{
		{UnitID: "a", UnitName: "A-1", Consumption: dec("100"), UsableArea: dec("100")},
		{UnitID: "b", UnitName: "A-2", Consumption: dec("0"), UsableArea: dec("100")},
	}
	a, err := AllocateHeating(total, share70, share30, units)
	if err != nil {
		t.Fatal(err)
	}
	var b UnitAllocation
	for _, u := range a.Units {
		if u.UnitID == "b" {
			b = u
		}
	}
	if b.ConsumptionShare != 0 {
		t.Fatalf("tüketmeyen bölüme tüketim payı yazıldı: %d", b.ConsumptionShare)
	}
	if b.AreaShare != 150_000 {
		t.Fatalf("tüketmeyen bölümün sabit payı yanlış: %d (150000 bekleniyordu)", b.AreaShare)
	}
	if b.TotalKurus == 0 {
		t.Fatal("tüketmeyen bölüm hiç ödemiyor — yönetmeliğe aykırı")
	}
}

func TestAllocateHeatingHicTuketimYoksaTamamiAlanaGore(t *testing.T) {
	total := money.Kurus(900_000)
	units := []UnitBasis{
		{UnitID: "a", Consumption: decimal.Zero, UsableArea: dec("100")},
		{UnitID: "b", Consumption: decimal.Zero, UsableArea: dec("200")},
	}
	a, err := AllocateHeating(total, share70, share30, units)
	if err != nil {
		t.Fatal(err)
	}
	if got := sumTotals(a); got != int64(total) {
		t.Fatalf("tüketim yokken giderin bir kısmı dağıtılmadan kaldı: %d != %d", got, total)
	}
	// 100/300 ve 200/300 → 300.000 ve 600.000
	for _, u := range a.Units {
		if u.UnitID == "a" && u.TotalKurus != 300_000 {
			t.Fatalf("A payı: %d (300000 bekleniyordu)", u.TotalKurus)
		}
		if u.UnitID == "b" && u.TotalKurus != 600_000 {
			t.Fatalf("B payı: %d (600000 bekleniyordu)", u.TotalKurus)
		}
	}
}

func TestAllocateHeatingOranlarKodaGomuluDegil(t *testing.T) {
	// Mevzuat değişir ya da yönetim planı farklı oran öngörebilir; hesap
	// verilen oranı kullanmalıdır.
	total := money.Kurus(1_000_000)
	units := []UnitBasis{
		{UnitID: "a", Consumption: dec("1"), UsableArea: dec("1")},
		{UnitID: "b", Consumption: dec("1"), UsableArea: dec("1")},
	}
	a, err := AllocateHeating(total, dec("0.60"), dec("0.40"), units)
	if err != nil {
		t.Fatal(err)
	}
	if a.ConsumptionPartKurus != 600_000 || a.AreaPartKurus != 400_000 {
		t.Fatalf("verilen oran kullanılmadı: %d / %d",
			a.ConsumptionPartKurus, a.AreaPartKurus)
	}
}

func TestAllocateHeatingGecersizOranReddedilir(t *testing.T) {
	units := []UnitBasis{{UnitID: "a", Consumption: dec("1"), UsableArea: dec("1")}}
	if _, err := AllocateHeating(money.Kurus(100), dec("0.70"), dec("0.40"), units); err == nil {
		t.Fatal("toplamı 1 olmayan oranlar kabul edildi")
	}
	if _, err := AllocateHeating(money.Kurus(100), dec("0.70"), dec("0.20"), units); err == nil {
		t.Fatal("toplamı 1 olmayan oranlar kabul edildi")
	}
}

func TestAllocateHeatingAlanYoksaDagitimYok(t *testing.T) {
	units := []UnitBasis{{UnitID: "a", Consumption: dec("10"), UsableArea: decimal.Zero}}
	if _, err := AllocateHeating(money.Kurus(100), share70, share30, units); err != ErrNoBasis {
		t.Fatalf("alan yokken dağıtım yapıldı: %v", err)
	}
}

func TestAllocateByConsumptionSabitPayYok(t *testing.T) {
	// Su/elektrikte sabit pay yoktur: tüketmeyen ödemez.
	total := money.Kurus(500_000)
	units := []UnitBasis{
		{UnitID: "a", Consumption: dec("30"), UsableArea: dec("100")},
		{UnitID: "b", Consumption: dec("20"), UsableArea: dec("500")},
		{UnitID: "c", Consumption: decimal.Zero, UsableArea: dec("900")},
	}
	a, err := AllocateByConsumption(total, units)
	if err != nil {
		t.Fatal(err)
	}
	if got := sumTotals(a); got != int64(total) {
		t.Fatalf("kuruş kaybı: %d != %d", got, total)
	}
	for _, u := range a.Units {
		if u.AreaShare != 0 {
			t.Fatalf("%s: tüketim bazlı dağıtımda alan payı çıktı", u.UnitID)
		}
		if u.UnitID == "c" && u.TotalKurus != 0 {
			t.Fatalf("hiç tüketmeyen bölüme su faturası çıktı: %d", u.TotalKurus)
		}
		if u.UnitID == "a" && u.TotalKurus != 300_000 {
			t.Fatalf("A payı: %d (30/50 → 300000 bekleniyordu)", u.TotalKurus)
		}
	}
}

func TestAllocateByConsumptionSifirTuketimdeFaturaUretilmez(t *testing.T) {
	units := []UnitBasis{
		{UnitID: "a", Consumption: decimal.Zero, UsableArea: dec("100")},
		{UnitID: "b", Consumption: decimal.Zero, UsableArea: dec("100")},
	}
	if _, err := AllocateByConsumption(money.Kurus(10_000), units); err != ErrNoBasis {
		t.Fatalf("sıfır tüketimde dağıtım yapıldı: %v", err)
	}
}

func TestAllocateHeatingRastgeleDurumlardaKurusKaybiYok(t *testing.T) {
	// Kuruş kaybı, ancak çok sayıda rastgele durumda yakalanır: tek bir örnek
	// "tesadüfen" bölünebilir olabilir.
	rng := rand.New(rand.NewSource(20260913))
	for i := 0; i < 2000; i++ {
		n := 2 + rng.Intn(30)
		units := make([]UnitBasis, 0, n)
		for j := 0; j < n; j++ {
			units = append(units, UnitBasis{
				UnitID:      string(rune('a'+j%26)) + string(rune('0'+j/26)),
				Consumption: decimal.NewFromInt(int64(rng.Intn(500))),
				UsableArea:  decimal.NewFromInt(int64(30 + rng.Intn(200))),
			})
		}
		total := money.Kurus(rng.Int63n(50_000_000) + 1)
		a, err := AllocateHeating(total, share70, share30, units)
		if err != nil {
			t.Fatalf("durum %d: %v", i, err)
		}
		if got := sumTotals(a); got != int64(total) {
			t.Fatalf("durum %d: kuruş kaybı %d != %d", i, got, total)
		}
	}
}
