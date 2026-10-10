// Package reports, tablo ağırlıklı resmi dökümleri PDF ve Excel (xlsx) olarak üretir
// (TEST_RAPORU 2.6).
//
// Tek veri modeli (Document) iki biçime de dönüşür; böylece PDF'te görünen ile Excel'e
// inen aynı içeriktir. PDF'te Türkçe karakterler (ğ, ş, ı, İ) için DejaVu Sans gömülüdür
// (gofpdf'in çekirdek Arial fontu cp1252'dir ve bu harfleri basamaz).
//
// Doğrulama kodu: belge içeriğinin (başlık + tüm tablo hücreleri) SHA-256 özetidir;
// PDF'in her sayfasında ve Excel'in özet sayfasında yazar. Aynı veriden üretilen belge
// aynı kodu taşır; içerik değiştirilirse kod tutmaz.
package reports

import (
	"bytes"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"fmt"
	"strings"
	"time"

	"github.com/jung-kurt/gofpdf"
	"github.com/xuri/excelize/v2"
	"rsc.io/qr"
)

//go:embed fonts/DejaVuSans.ttf
var fontRegular []byte

//go:embed fonts/DejaVuSans-Bold.ttf
var fontBold []byte

// Table, başlıklı bir tablodur. Widths PDF sütun genişlikleridir (mm; toplam ≤ 180 dikey,
// ≤ 267 yatay). Boşsa eşit bölünür. RightAlign sağa yaslanacak (tutar) sütunlarıdır.
type Table struct {
	Title      string
	Headers    []string
	Rows       [][]string
	Widths     []float64
	RightAlign []int
	// Footer, tablonun altına yazılan toplam satırıdır (isteğe bağlı).
	Footer []string
}

// Document, PDF/Excel'e dönüşecek belgedir.
type Document struct {
	PropertyName string
	Title        string
	Subtitle     string
	GeneratedAt  time.Time
	Landscape    bool
	// Facts, başlık altında "Alan: değer" satırlarıdır (dönem, toplamlar…).
	Facts [][2]string
	// Notes, tablolardan sonra yazılan açıklama/hukuki dayanak paragraflarıdır.
	Notes  []string
	Tables []Table
	// SignatureLines, belgenin sonunda imza için bırakılan satırlardır (ör. "Yönetici").
	SignatureLines []string
	// QRText doluysa sağ üst köşeye karekod basılır (ör. doğrulama adresi).
	QRText string
}

// VerificationCode, belge içeriğinin SHA-256 özetidir (üretim zamanı hariç).
func (d *Document) VerificationCode() string {
	h := sha256.New()
	w := func(s string) { h.Write([]byte(s)); h.Write([]byte{0x1f}) }
	w(d.PropertyName)
	w(d.Title)
	w(d.Subtitle)
	for _, f := range d.Facts {
		w(f[0])
		w(f[1])
	}
	for _, t := range d.Tables {
		w(t.Title)
		w(strings.Join(t.Headers, "\x1e"))
		for _, r := range t.Rows {
			w(strings.Join(r, "\x1e"))
		}
		w(strings.Join(t.Footer, "\x1e"))
	}
	for _, n := range d.Notes {
		w(n)
	}
	return hex.EncodeToString(h.Sum(nil))
}

// PDF, belgeyi A4 PDF olarak üretir.
func (d *Document) PDF() ([]byte, error) {
	orient, pageW := "P", 210.0
	if d.Landscape {
		orient, pageW = "L", 297.0
	}
	pdf := gofpdf.New(orient, "mm", "A4", "")
	pdf.AddUTF8FontFromBytes("DejaVu", "", fontRegular)
	pdf.AddUTF8FontFromBytes("DejaVu", "B", fontBold)
	if err := pdf.Error(); err != nil {
		return nil, fmt.Errorf("font yüklenemedi: %w", err)
	}
	pdf.SetMargins(15, 15, 15)
	pdf.SetAutoPageBreak(true, 18)
	code := d.VerificationCode()
	gen := d.GeneratedAt
	if gen.IsZero() {
		gen = time.Now()
	}
	pdf.SetFooterFunc(func() {
		pdf.SetY(-12)
		pdf.SetFont("DejaVu", "", 7)
		pdf.SetTextColor(110, 110, 110)
		pdf.CellFormat(0, 4, fmt.Sprintf("SiteEksen · %s · Doğrulama kodu (SHA-256): %s · Sayfa %d/{nb}",
			gen.In(trLoc()).Format("02.01.2006 15:04"), code, pdf.PageNo()), "", 0, "C", false, 0, "")
	})
	pdf.AliasNbPages("")
	pdf.AddPage()
	usable := pageW - 30

	pdf.SetTextColor(0, 0, 0)
	if d.QRText != "" {
		code, err := qr.Encode(d.QRText, qr.M)
		if err != nil {
			return nil, fmt.Errorf("karekod üretilemedi: %w", err)
		}
		code.Scale = 4
		pdf.RegisterImageOptionsReader("qr", gofpdf.ImageOptions{ImageType: "PNG"}, bytes.NewReader(code.PNG()))
		pdf.ImageOptions("qr", pageW-15-32, 12, 32, 32, false, gofpdf.ImageOptions{ImageType: "PNG"}, 0, "")
		usable -= 36 // başlık metni karekodun altına taşmasın
	}
	pdf.SetFont("DejaVu", "B", 9)
	pdf.CellFormat(usable, 5, d.PropertyName, "", 1, "L", false, 0, "")
	pdf.SetFont("DejaVu", "B", 14)
	pdf.MultiCell(usable, 7, d.Title, "", "L", false)
	if d.Subtitle != "" {
		pdf.SetFont("DejaVu", "", 9)
		pdf.MultiCell(usable, 5, d.Subtitle, "", "L", false)
	}
	pdf.Ln(2)
	if len(d.Facts) > 0 {
		pdf.SetFont("DejaVu", "", 9)
		for _, f := range d.Facts {
			pdf.SetFont("DejaVu", "B", 9)
			pdf.CellFormat(55, 5, f[0], "", 0, "L", false, 0, "")
			pdf.SetFont("DejaVu", "", 9)
			pdf.MultiCell(usable-55, 5, f[1], "", "L", false)
		}
		pdf.Ln(2)
	}

	usable = pageW - 30
	if d.QRText != "" && pdf.GetY() < 48 {
		pdf.SetY(48) // tablolar karekodun altından başlasın
	}
	for _, t := range d.Tables {
		widths := t.Widths
		if len(widths) != len(t.Headers) {
			widths = make([]float64, len(t.Headers))
			for i := range widths {
				widths[i] = usable / float64(len(t.Headers))
			}
		}
		right := map[int]bool{}
		for _, i := range t.RightAlign {
			right[i] = true
		}
		if t.Title != "" {
			pdf.SetFont("DejaVu", "B", 10)
			pdf.CellFormat(usable, 7, t.Title, "", 1, "L", false, 0, "")
		}
		header := func() {
			pdf.SetFont("DejaVu", "B", 8)
			pdf.SetFillColor(230, 236, 245)
			for i, h := range t.Headers {
				pdf.CellFormat(widths[i], 6, h, "1", 0, "C", true, 0, "")
			}
			pdf.Ln(-1)
		}
		header()
		pdf.SetFont("DejaVu", "", 8)
		row := func(cells []string, bold bool) {
			if bold {
				pdf.SetFont("DejaVu", "B", 8)
			}
			// Satır yüksekliği en uzun hücreye göre (sarma).
			lines := 1
			for i, c := range cells {
				if i < len(widths) {
					if n := len(pdf.SplitText(c, widths[i]-2)); n > lines {
						lines = n
					}
				}
			}
			h := float64(lines) * 4.5
			_, pageH := pdf.GetPageSize()
			if pdf.GetY()+h > pageH-20 {
				pdf.AddPage()
				header()
				pdf.SetFont("DejaVu", "", 8)
			}
			x, y := pdf.GetX(), pdf.GetY()
			for i, c := range cells {
				if i >= len(widths) {
					break
				}
				align := "L"
				if right[i] {
					align = "R"
				}
				pdf.Rect(x, y, widths[i], h, "D")
				pdf.SetXY(x, y)
				pdf.MultiCell(widths[i], 4.5, c, "", align, false)
				x += widths[i]
			}
			pdf.SetXY(15, y+h)
			if bold {
				pdf.SetFont("DejaVu", "", 8)
			}
		}
		for _, r := range t.Rows {
			row(r, false)
		}
		if len(t.Footer) > 0 {
			row(t.Footer, true)
		}
		if len(t.Rows) == 0 {
			pdf.CellFormat(usable, 6, "Kayıt yok", "1", 1, "C", false, 0, "")
		}
		pdf.Ln(4)
	}

	if len(d.Notes) > 0 {
		pdf.SetFont("DejaVu", "", 8)
		for _, n := range d.Notes {
			pdf.MultiCell(usable, 4.5, n, "", "L", false)
			pdf.Ln(1)
		}
	}
	if len(d.SignatureLines) > 0 {
		pdf.Ln(8)
		pdf.SetFont("DejaVu", "", 9)
		w := usable / float64(len(d.SignatureLines))
		for _, s := range d.SignatureLines {
			pdf.CellFormat(w, 5, s, "", 0, "C", false, 0, "")
		}
		pdf.Ln(14)
		for range d.SignatureLines {
			pdf.CellFormat(w, 5, "İmza", "T", 0, "C", false, 0, "")
		}
		pdf.Ln(-1)
	}
	if err := pdf.Error(); err != nil {
		return nil, err
	}
	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// XLSX, belgeyi Excel çalışma kitabı olarak üretir: "Özet" sayfası + her tablo için bir sayfa.
func (d *Document) XLSX() ([]byte, error) {
	f := excelize.NewFile()
	defer f.Close()
	bold, _ := f.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true}})
	head, _ := f.NewStyle(&excelize.Style{Font: &excelize.Font{Bold: true, Color: "FFFFFF"},
		Fill: excelize.Fill{Type: "pattern", Color: []string{"2563EB"}, Pattern: 1}})
	sum := "Özet"
	f.SetSheetName("Sheet1", sum)
	set := func(sheet string, col, row int, v any) {
		cell, _ := excelize.CoordinatesToCellName(col, row)
		_ = f.SetCellValue(sheet, cell, v)
	}
	r := 1
	set(sum, 1, r, d.PropertyName)
	r++
	set(sum, 1, r, d.Title)
	_ = f.SetCellStyle(sum, "A2", "A2", bold)
	r++
	if d.Subtitle != "" {
		set(sum, 1, r, d.Subtitle)
		r++
	}
	for _, fact := range d.Facts {
		set(sum, 1, r, fact[0])
		set(sum, 2, r, fact[1])
		r++
	}
	r++
	for _, n := range d.Notes {
		set(sum, 1, r, n)
		r++
	}
	gen := d.GeneratedAt
	if gen.IsZero() {
		gen = time.Now()
	}
	set(sum, 1, r+1, "Üretim zamanı")
	set(sum, 2, r+1, gen.In(trLoc()).Format("02.01.2006 15:04"))
	set(sum, 1, r+2, "Doğrulama kodu (SHA-256)")
	set(sum, 2, r+2, d.VerificationCode())
	_ = f.SetColWidth(sum, "A", "A", 32)
	_ = f.SetColWidth(sum, "B", "B", 70)

	used := map[string]bool{sum: true}
	for i, t := range d.Tables {
		name := sheetName(t.Title, i+1, used)
		if _, err := f.NewSheet(name); err != nil {
			return nil, err
		}
		for c, h := range t.Headers {
			set(name, c+1, 1, h)
		}
		last, _ := excelize.CoordinatesToCellName(len(t.Headers), 1)
		_ = f.SetCellStyle(name, "A1", last, head)
		right := map[int]bool{}
		for _, c := range t.RightAlign {
			right[c] = true
		}
		for ri, row := range t.Rows {
			for c, v := range row {
				set(name, c+1, ri+2, cellValue(v, right[c]))
			}
		}
		if len(t.Footer) > 0 {
			fr := len(t.Rows) + 2
			for c, v := range t.Footer {
				set(name, c+1, fr, cellValue(v, right[c]))
			}
			a, _ := excelize.CoordinatesToCellName(1, fr)
			b, _ := excelize.CoordinatesToCellName(len(t.Footer), fr)
			_ = f.SetCellStyle(name, a, b, bold)
		}
		for c := range t.Headers {
			col, _ := excelize.ColumnNumberToName(c + 1)
			_ = f.SetColWidth(name, col, col, 22)
		}
	}
	var buf bytes.Buffer
	if err := f.Write(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// cellValue, tutar sütunundaki "1.234,56" biçimli metni sayıya çevirir (Excel'de toplanabilsin).
func cellValue(v string, numeric bool) any {
	if !numeric {
		return v
	}
	s := strings.TrimSpace(strings.TrimSuffix(strings.TrimSpace(v), "TL"))
	s = strings.ReplaceAll(strings.ReplaceAll(s, ".", ""), ",", ".")
	var f float64
	if _, err := fmt.Sscanf(s, "%f", &f); err == nil && s != "" {
		return f
	}
	return v
}

// sheetName, Excel'in 31 karakter ve yasak karakter kuralına uyan tekil sayfa adı üretir.
func sheetName(title string, i int, used map[string]bool) string {
	name := strings.Map(func(r rune) rune {
		if strings.ContainsRune(`:\/?*[]`, r) {
			return ' '
		}
		return r
	}, title)
	if name == "" {
		name = fmt.Sprintf("Tablo %d", i)
	}
	if r := []rune(name); len(r) > 28 {
		name = string(r[:28])
	}
	base := name
	for n := 2; used[name]; n++ {
		name = fmt.Sprintf("%s %d", base, n)
	}
	used[name] = true
	return name
}

func trLoc() *time.Location {
	if l, err := time.LoadLocation("Europe/Istanbul"); err == nil {
		return l
	}
	return time.FixedZone("+03", 3*3600)
}

// Money, kuruşu "1.234,56 TL" biçiminde yazar.
func Money(kurus int64) string {
	neg := kurus < 0
	if neg {
		kurus = -kurus
	}
	lira, kr := kurus/100, kurus%100
	s := fmt.Sprintf("%d", lira)
	var b strings.Builder
	for i, ch := range s {
		if i > 0 && (len(s)-i)%3 == 0 {
			b.WriteByte('.')
		}
		b.WriteRune(ch)
	}
	out := fmt.Sprintf("%s,%02d TL", b.String(), kr)
	if neg {
		out = "-" + out
	}
	return out
}
