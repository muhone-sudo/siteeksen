package service

import (
	"testing"

	"github.com/shopspring/decimal"
)

func d(s string) decimal.Decimal {
	v, err := decimal.NewFromString(s)
	if err != nil {
		panic(err)
	}
	return v
}

func TestCalcTrendYuzdeDegisim(t *testing.T) {
	tr := CalcTrend(d("100"), d("150"))
	if tr.ChangePct == nil || *tr.ChangePct != "50" {
		t.Fatalf("değişim yüzdesi: %v (50 bekleniyordu)", tr.ChangePct)
	}
	if tr.Direction != "UP" {
		t.Fatalf("yön: %s", tr.Direction)
	}

	tr = CalcTrend(d("200"), d("150"))
	if tr.ChangePct == nil || *tr.ChangePct != "-25" {
		t.Fatalf("azalış yüzdesi: %v (-25 bekleniyordu)", tr.ChangePct)
	}
	if tr.Direction != "DOWN" {
		t.Fatalf("yön: %s", tr.Direction)
	}
}

func TestCalcTrendSifirdanArtisYuzdeVermez(t *testing.T) {
	// Sıfırdan artışa "%100 arttı" demek yanıltıcıdır; oran tanımsızdır.
	tr := CalcTrend(decimal.Zero, d("120"))
	if tr.ChangePct != nil {
		t.Fatalf("sıfır tabandan yüzde üretildi: %v", *tr.ChangePct)
	}
	if tr.Direction != "UP" {
		t.Fatalf("yön: %s (UP bekleniyordu)", tr.Direction)
	}

	tr = CalcTrend(decimal.Zero, decimal.Zero)
	if tr.ChangePct != nil || tr.Direction != "FLAT" {
		t.Fatalf("iki dönem de sıfırken: %+v", tr)
	}
}

func TestDetectAnomaliesMedyanKullanir(t *testing.T) {
	// Ortalama kullanılsaydı 1000'lik kaçak ortalamayı yukarı çeker ve
	// kendisini normal gösterirdi. Medyan bundan etkilenmez.
	inputs := []AnomalyInput{
		{UnitID: "a", UnitName: "A-1", Value: d("100"), HasValue: true},
		{UnitID: "b", UnitName: "A-2", Value: d("110"), HasValue: true},
		{UnitID: "c", UnitName: "A-3", Value: d("90"), HasValue: true},
		{UnitID: "d", UnitName: "A-4", Value: d("1000"), HasValue: true},
	}
	got := DetectAnomalies(inputs)
	if len(got) == 0 {
		t.Fatal("bariz kaçak işaretlenmedi")
	}
	if got[0].UnitID != "d" {
		t.Fatalf("en büyük sapma ilk sırada değil: %s", got[0].UnitID)
	}
	if got[0].Severity != "HIGH" {
		t.Fatalf("kaçak ciddiyeti: %s (HIGH bekleniyordu)", got[0].Severity)
	}
	if got[0].Reason == "" {
		t.Fatal("bulgunun gerekçesi yok")
	}
}

func TestDetectAnomaliesSifirTuketimIsaretlenir(t *testing.T) {
	inputs := []AnomalyInput{
		{UnitID: "a", Value: d("100"), HasValue: true},
		{UnitID: "b", Value: d("100"), HasValue: true},
		{UnitID: "c", Value: d("100"), HasValue: true},
		{UnitID: "d", Value: d("0"), HasValue: true},
	}
	got := DetectAnomalies(inputs)
	found := false
	for _, a := range got {
		if a.UnitID == "d" {
			found = true
			if a.Severity != "LOW" {
				t.Fatalf("sıfır tüketim ciddiyeti: %s", a.Severity)
			}
		}
	}
	if !found {
		t.Fatal("hiç tüketmeyen bölüm işaretlenmedi (sayaç arızası olabilir)")
	}
}

func TestDetectAnomaliesAzVeriyleCalismaz(t *testing.T) {
	// İki daireyle medyan anlamsızdır; uydurma bulgu üretilmemelidir.
	inputs := []AnomalyInput{
		{UnitID: "a", Value: d("10"), HasValue: true},
		{UnitID: "b", Value: d("1000"), HasValue: true},
	}
	if got := DetectAnomalies(inputs); len(got) != 0 {
		t.Fatalf("yetersiz veriyle bulgu üretildi: %+v", got)
	}
}

func TestDetectAnomaliesOlcumsuzBolumIsaretlenmez(t *testing.T) {
	inputs := []AnomalyInput{
		{UnitID: "a", Value: d("100"), HasValue: true},
		{UnitID: "b", Value: d("100"), HasValue: true},
		{UnitID: "c", Value: d("100"), HasValue: true},
		{UnitID: "d", HasValue: false},
	}
	for _, a := range DetectAnomalies(inputs) {
		if a.UnitID == "d" {
			t.Fatal("ölçülebilir verisi olmayan bölüm için bulgu üretildi")
		}
	}
}

func TestDetectAnomaliesNormalDagilimdaBulguYok(t *testing.T) {
	inputs := []AnomalyInput{
		{UnitID: "a", Value: d("100"), HasValue: true},
		{UnitID: "b", Value: d("105"), HasValue: true},
		{UnitID: "c", Value: d("95"), HasValue: true},
		{UnitID: "d", Value: d("110"), HasValue: true},
	}
	if got := DetectAnomalies(inputs); len(got) != 0 {
		t.Fatalf("olağan dağılımda bulgu üretildi: %+v", got)
	}
}

func TestMedianCiftVeTekSayida(t *testing.T) {
	if got := Median([]decimal.Decimal{d("1"), d("3"), d("2")}); !got.Equal(d("2")) {
		t.Fatalf("tek sayıda medyan: %s", got)
	}
	if got := Median([]decimal.Decimal{d("1"), d("2"), d("3"), d("4")}); !got.Equal(d("2.5")) {
		t.Fatalf("çift sayıda medyan: %s", got)
	}
	if got := Median(nil); !got.Equal(decimal.Zero) {
		t.Fatalf("boş dizide medyan: %s", got)
	}
}
