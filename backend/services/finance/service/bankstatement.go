package service

// Banka ekstresi ayrıştırma (migration 059, Apsiyon BUG-12).
//
// Yönetici bankanın internet şubesinden indirdiği hesap hareketlerini CSV ya da Excel (.xlsx)
// olarak yükler. Bankalar arasında sütun adları ve sayı biçimi farklıdır; başlık satırı
// Türkçe/İngilizce yaygın adlarla tanınır, tutar Türkçe ("1.234,56") ve noktalı ("1234.56")
// biçimde okunur. Ayrı "Borç"/"Alacak" sütunları varsa alacak gelen, borç giden harekettir.
// Okunamayan satır sessizce atlanmaz: satır numarasıyla hata döner.

import (
	"bytes"
	"encoding/csv"
	"errors"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"

	"github.com/shopspring/decimal"
	"github.com/xuri/excelize/v2"
)

// StatementRow, ekstrenin tek hareketidir. Giden hareketin tutarı negatiftir.
type StatementRow struct {
	LineNo      int       `json:"line_no"`
	Date        time.Time `json:"date"`
	AmountKurus int64     `json:"amount_kurus"`
	Description string    `json:"description"`
	Reference   string    `json:"reference"`
}

// ErrStatementFormat, dosyanın ekstre olarak okunamadığını bildirir.
var ErrStatementFormat = errors.New("ekstre okunamadı")

// MaxStatementRows, tek yüklemedeki en fazla hareket sayısıdır.
const MaxStatementRows = 5000

// ParseStatement, CSV ya da XLSX içeriğini hareketlere çevirir.
func ParseStatement(fileName string, data []byte) ([]StatementRow, error) {
	var table [][]string
	var lineNos []int // dosyadaki gerçek satır numarası (CSV okuyucu boş satırları atlar)
	if strings.HasSuffix(strings.ToLower(fileName), ".xlsx") {
		f, err := excelize.OpenReader(bytes.NewReader(data))
		if err != nil {
			return nil, fmt.Errorf("%w: Excel dosyası açılamadı", ErrStatementFormat)
		}
		defer f.Close()
		sheets := f.GetSheetList()
		if len(sheets) == 0 {
			return nil, fmt.Errorf("%w: Excel dosyasında sayfa yok", ErrStatementFormat)
		}
		if table, err = f.GetRows(sheets[0]); err != nil {
			return nil, fmt.Errorf("%w: Excel sayfası okunamadı", ErrStatementFormat)
		}
	} else {
		text := strings.TrimPrefix(string(data), "\ufeff")
		head := strings.SplitN(text, "\n", 16)
		if len(head) == 16 {
			head = head[:15]
		}
		r := csv.NewReader(strings.NewReader(text))
		r.Comma = detectDelimiter(strings.Join(head, "\n"))
		r.FieldsPerRecord = -1
		r.LazyQuotes = true
		for {
			rec, err := r.Read()
			if err == io.EOF {
				break
			}
			if err != nil {
				return nil, fmt.Errorf("%w: CSV okunamadı (%v)", ErrStatementFormat, err)
			}
			line, _ := r.FieldPos(0)
			table = append(table, rec)
			lineNos = append(lineNos, line)
		}
	}
	return parseTable(table, lineNos)
}

// detectDelimiter, ilk satırlarda en sık geçen ayırıcıyı seçer (başlıktan önce hesap bilgisi olabilir).
func detectDelimiter(header string) rune {
	best, n := ',', 0
	for _, d := range []rune{';', ',', '\t', '|'} {
		if c := strings.Count(header, string(d)); c > n {
			best, n = d, c
		}
	}
	return best
}

type columns struct{ date, amount, credit, debit, desc, ref int }

func fold(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	return strings.NewReplacer("ı", "i", "İ", "i", "ş", "s", "ğ", "g", "ü", "u", "ö", "o", "ç", "c", "â", "a").Replace(s)
}

// findHeader, ilk 15 satırda tarih ve tutar sütunu olan başlık satırını arar (bazı bankalar
// başlıktan önce hesap bilgisi satırları koyar).
func findHeader(table [][]string) (int, columns, bool) {
	for i := 0; i < len(table) && i < 15; i++ {
		c := columns{-1, -1, -1, -1, -1, -1}
		for j, cell := range table[i] {
			h := fold(cell)
			switch {
			case c.date < 0 && strings.Contains(h, "tarih") || h == "date":
				c.date = j
			case strings.Contains(h, "alacak") || h == "credit":
				c.credit = j
			case strings.Contains(h, "borc") || h == "debit":
				c.debit = j
			case c.amount < 0 && (strings.Contains(h, "tutar") || strings.Contains(h, "miktar") || h == "amount"):
				c.amount = j
			case c.desc < 0 && (strings.Contains(h, "aciklama") || strings.Contains(h, "description")):
				c.desc = j
			case c.ref < 0 && (strings.Contains(h, "referans") || strings.Contains(h, "dekont") || strings.Contains(h, "islem no") || strings.Contains(h, "reference")):
				c.ref = j
			}
		}
		if c.date >= 0 && (c.amount >= 0 || c.credit >= 0) {
			return i, c, true
		}
	}
	return 0, columns{}, false
}

func cell(row []string, i int) string {
	if i < 0 || i >= len(row) {
		return ""
	}
	return strings.TrimSpace(row[i])
}

func parseTable(table [][]string, lineNos []int) ([]StatementRow, error) {
	h, c, ok := findHeader(table)
	if !ok {
		return nil, fmt.Errorf("%w: başlık satırında tarih ve tutar (ya da alacak) sütunu bulunamadı", ErrStatementFormat)
	}
	out := []StatementRow{}
	for i := h + 1; i < len(table); i++ {
		row := table[i]
		if strings.TrimSpace(strings.Join(row, "")) == "" {
			continue
		}
		lineNo := i + 1
		if i < len(lineNos) {
			lineNo = lineNos[i]
		}
		ds := cell(row, c.date)
		if ds == "" {
			continue // alt toplam / bakiye satırı
		}
		d, err := parseDate(ds)
		if err != nil {
			return nil, fmt.Errorf("%w: %d. satırda tarih okunamadı (%q)", ErrStatementFormat, lineNo, ds)
		}
		var amount int64
		switch {
		case c.amount >= 0 && cell(row, c.amount) != "":
			if amount, err = ParseAmountKurus(cell(row, c.amount)); err != nil {
				return nil, fmt.Errorf("%w: %d. satırda tutar okunamadı (%q)", ErrStatementFormat, lineNo, cell(row, c.amount))
			}
		case c.credit >= 0 && cell(row, c.credit) != "":
			if amount, err = ParseAmountKurus(cell(row, c.credit)); err != nil {
				return nil, fmt.Errorf("%w: %d. satırda alacak okunamadı", ErrStatementFormat, lineNo)
			}
		case c.debit >= 0 && cell(row, c.debit) != "":
			if amount, err = ParseAmountKurus(cell(row, c.debit)); err != nil {
				return nil, fmt.Errorf("%w: %d. satırda borç okunamadı", ErrStatementFormat, lineNo)
			}
			if amount > 0 {
				amount = -amount
			}
		default:
			return nil, fmt.Errorf("%w: %d. satırda tutar yok", ErrStatementFormat, lineNo)
		}
		out = append(out, StatementRow{LineNo: lineNo, Date: d, AmountKurus: amount,
			Description: cell(row, c.desc), Reference: cell(row, c.ref)})
		if len(out) > MaxStatementRows {
			return nil, fmt.Errorf("%w: tek yüklemede en çok %d hareket", ErrStatementFormat, MaxStatementRows)
		}
	}
	if len(out) == 0 {
		return nil, fmt.Errorf("%w: hareket satırı yok", ErrStatementFormat)
	}
	return out, nil
}

var dateLayouts = []string{"02.01.2006", "02/01/2006", "2006-01-02", "02-01-2006", "02.01.2006 15:04", "02.01.2006 15:04:05",
	"02/01/2006 15:04", "02/01/2006 15:04:05", "2006-01-02 15:04:05", "2006-01-02T15:04:05"}

func parseDate(s string) (time.Time, error) {
	s = strings.TrimSpace(s)
	for _, l := range dateLayouts {
		if t, err := time.Parse(l, s); err == nil {
			return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC), nil
		}
	}
	// Excel seri tarih (biçimlenmemiş hücre)
	if f, err := strconv.ParseFloat(s, 64); err == nil && f > 20000 && f < 80000 {
		if t, err := excelize.ExcelDateToTime(f, false); err == nil {
			return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC), nil
		}
	}
	return time.Time{}, errors.New("tarih biçimi tanınmadı")
}

// ParseAmountKurus, "1.234,56", "1,234.56", "1234.56", "-150,00 TL", "₺ 75" biçimlerini kuruşa çevirir.
func ParseAmountKurus(s string) (int64, error) {
	s = strings.NewReplacer(" ", "", " ", "", "TL", "", "TRY", "", "₺", "", "+", "").Replace(strings.TrimSpace(s))
	neg := false
	if strings.HasPrefix(s, "(") && strings.HasSuffix(s, ")") {
		neg, s = true, s[1:len(s)-1]
	}
	if strings.HasPrefix(s, "-") {
		neg, s = true, s[1:]
	}
	if strings.HasSuffix(s, "-") {
		neg, s = true, s[:len(s)-1]
	}
	lastDot, lastComma := strings.LastIndex(s, "."), strings.LastIndex(s, ",")
	switch {
	case lastDot >= 0 && lastComma >= 0:
		if lastComma > lastDot { // 1.234,56
			s = strings.ReplaceAll(s, ".", "")
			s = strings.Replace(s, ",", ".", 1)
		} else { // 1,234.56
			s = strings.ReplaceAll(s, ",", "")
		}
	case lastComma >= 0:
		if strings.Count(s, ",") > 1 || len(s)-lastComma-1 == 3 { // 1,234 ya da 1,234,567 → binlik
			s = strings.ReplaceAll(s, ",", "")
		} else {
			s = strings.Replace(s, ",", ".", 1)
		}
	case lastDot >= 0:
		if strings.Count(s, ".") > 1 || len(s)-lastDot-1 == 3 { // 1.234 → binlik
			s = strings.ReplaceAll(s, ".", "")
		}
	}
	d, err := decimal.NewFromString(s)
	if err != nil || s == "" {
		return 0, errors.New("tutar biçimi tanınmadı")
	}
	k := d.Mul(decimal.NewFromInt(100)).Round(0).IntPart()
	if neg {
		k = -k
	}
	return k, nil
}
