package service

import (
	"bytes"
	"testing"

	"github.com/xuri/excelize/v2"
)

func TestParseAmountKurus(t *testing.T) {
	cases := map[string]int64{
		"1.234,56": 123456, "1,234.56": 123456, "1234.56": 123456, "1234,56": 123456,
		"-150,00 TL": -15000, "₺ 75": 7500, "1.234": 123400, "12.500,00": 1250000,
		"(200,00)": -20000, "300,5": 30050, "1.234.567,89": 123456789, "750": 75000, "+1.250,00": 125000,
	}
	for in, want := range cases {
		got, err := ParseAmountKurus(in)
		if err != nil || got != want {
			t.Errorf("ParseAmountKurus(%q) = %d, %v; beklenen %d", in, got, err, want)
		}
	}
	for _, in := range []string{"", "abc", "1,2,3x"} {
		if _, err := ParseAmountKurus(in); err == nil {
			t.Errorf("ParseAmountKurus(%q) hata vermeliydi", in)
		}
	}
}

func TestParseStatementCSVTurkce(t *testing.T) {
	csv := "\ufeffHesap: TR12 0001\n\nİşlem Tarihi;Açıklama;Tutar;Bakiye;Dekont No\n" +
		"05.01.2026;A-3 OCAK AİDAT HAVALE;1.250,00;10.000,00;DK123\n" +
		"06.01.2026;ELEKTRİK FATURASI;-845,30;9.154,70;DK124\n" +
		";DÖNEM TOPLAMI;404,70;;\n"
	rows, err := ParseStatement("ekstre.csv", []byte(csv))
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 2 {
		t.Fatalf("2 hareket beklenirdi: %+v", rows)
	}
	if rows[0].AmountKurus != 125000 || rows[0].Reference != "DK123" || rows[0].Date.Format("2006-01-02") != "2026-01-05" || rows[0].LineNo != 4 {
		t.Errorf("ilk satır: %+v", rows[0])
	}
	if rows[1].AmountKurus != -84530 {
		t.Errorf("giden hareket negatif olmalı: %+v", rows[1])
	}
}

func TestParseStatementBorcAlacakSutunlari(t *testing.T) {
	csv := "Tarih,Description,Borç,Alacak\n2026-02-01,EFT GELEN,,500.00\n2026-02-02,KOMISYON,12.50,\n"
	rows, err := ParseStatement("x.csv", []byte(csv))
	if err != nil {
		t.Fatal(err)
	}
	if rows[0].AmountKurus != 50000 || rows[1].AmountKurus != -1250 {
		t.Errorf("alacak/borç: %+v", rows)
	}
}

func TestParseStatementXLSX(t *testing.T) {
	f := excelize.NewFile()
	_ = f.SetSheetRow("Sheet1", "A1", &[]any{"Tarih", "Açıklama", "Tutar", "Referans"})
	_ = f.SetSheetRow("Sheet1", "A2", &[]any{"10.03.2026", "Aidat Mart", "980,00", "R-77"})
	var buf bytes.Buffer
	if err := f.Write(&buf); err != nil {
		t.Fatal(err)
	}
	rows, err := ParseStatement("ekstre.xlsx", buf.Bytes())
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 1 || rows[0].AmountKurus != 98000 || rows[0].Reference != "R-77" {
		t.Errorf("xlsx: %+v", rows)
	}
}

func TestParseStatementHatalar(t *testing.T) {
	if _, err := ParseStatement("x.csv", []byte("a;b\n1;2\n")); err == nil {
		t.Error("başlıksız dosya reddedilmeliydi")
	}
	if _, err := ParseStatement("x.csv", []byte("Tarih;Tutar\n32.13.2026;100\n")); err == nil {
		t.Error("geçersiz tarih satır numarasıyla reddedilmeliydi")
	}
	if _, err := ParseStatement("x.xlsx", []byte("bozuk")); err == nil {
		t.Error("bozuk xlsx reddedilmeliydi")
	}
}
