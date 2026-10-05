package reports

import (
	"bytes"
	"strings"
	"testing"
	"time"

	"github.com/xuri/excelize/v2"
)

func sample() *Document {
	return &Document{
		PropertyName: "Güneş Sitesi", Title: "Borçlu listesi — Şubat", Subtitle: "Vadesi geçmiş borçlar",
		GeneratedAt: time.Date(2026, 10, 5, 10, 0, 0, 0, time.UTC),
		Facts:       [][2]string{{"Dönem", "2026"}, {"Toplam", Money(12345678)}},
		Tables: []Table{{
			Title: "Daireler", Headers: []string{"Daire", "Malik", "Borç"}, RightAlign: []int{2},
			Rows:   [][]string{{"A-1", "Ayşe Işık", Money(150000)}, {"B-12", "Çağrı Öğüt", Money(99)}},
			Footer: []string{"Toplam", "", Money(150099)},
		}},
		Notes:          []string{"KMK m.20: gecikme tazminatı aylık %5."},
		SignatureLines: []string{"Yönetici", "Denetçi"},
	}
}

func TestMoney(t *testing.T) {
	for k, want := range map[int64]string{0: "0,00 TL", 99: "0,99 TL", 123456789: "1.234.567,89 TL", -150000: "-1.500,00 TL"} {
		if got := Money(k); got != want {
			t.Errorf("Money(%d)=%q, beklenen %q", k, got, want)
		}
	}
}

func TestVerificationCodeDependsOnContentOnly(t *testing.T) {
	a, b := sample(), sample()
	b.GeneratedAt = time.Now()
	if a.VerificationCode() != b.VerificationCode() {
		t.Fatal("üretim zamanı doğrulama kodunu değiştirmemeli")
	}
	b.Tables[0].Rows[0][2] = Money(150001)
	if a.VerificationCode() == b.VerificationCode() {
		t.Fatal("tek kuruşluk değişiklik doğrulama kodunu değiştirmeli")
	}
}

func TestPDFEmbedsUnicodeFont(t *testing.T) {
	out, err := sample().PDF()
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.HasPrefix(out, []byte("%PDF-")) {
		t.Fatal("PDF imzası yok")
	}
	// Türkçe harfler için TrueType font gömülü olmalı (çekirdek Arial ğ/ş/ı basamaz).
	if !bytes.Contains(out, []byte("/Type0")) || !bytes.Contains(out, []byte("utf8dejavu")) {
		t.Fatal("UTF-8 font gömülmemiş")
	}
}

func TestXLSXContent(t *testing.T) {
	d := sample()
	out, err := d.XLSX()
	if err != nil {
		t.Fatal(err)
	}
	f, err := excelize.OpenReader(bytes.NewReader(out))
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	if v, _ := f.GetCellValue("Daireler", "B2"); v != "Ayşe Işık" {
		t.Fatalf("hücre B2 = %q", v)
	}
	// Tutar sütunu sayıya çevrilir (Excel'de toplanabilsin).
	if v, _ := f.GetCellValue("Daireler", "C2"); v != "1500" {
		t.Fatalf("tutar sayı değil: %q", v)
	}
	rows, _ := f.GetRows("Özet")
	joined := ""
	for _, r := range rows {
		joined += strings.Join(r, "|") + "\n"
	}
	if !strings.Contains(joined, d.VerificationCode()) {
		t.Fatal("özet sayfasında doğrulama kodu yok")
	}
}
