package reports

import (
	"bytes"
	"fmt"

	"github.com/xuri/excelize/v2"
)

// ExcelGenerator - Excel rapor oluşturucu
type ExcelGenerator struct {
	file *excelize.File
}

// NewExcelGenerator - Yeni Excel generator
func NewExcelGenerator() *ExcelGenerator {
	return &ExcelGenerator{
		file: excelize.NewFile(),
	}
}

// GenerateAssessmentExcel - Aidat Excel raporu
func (g *ExcelGenerator) GenerateAssessmentExcel(data *AssessmentReportData) ([]byte, error) {
	sheet := "Aidat Raporu"
	g.file.SetSheetName("Sheet1", sheet)

	// Başlık
	g.file.SetCellValue(sheet, "A1", data.PropertyName)
	g.file.SetCellValue(sheet, "A2", fmt.Sprintf("Aidat Raporu - %s", data.Period))

	// Özet
	g.file.SetCellValue(sheet, "A4", "Toplam Tahakkuk")
	g.file.SetCellValue(sheet, "B4", data.TotalAssessed)
	g.file.SetCellValue(sheet, "A5", "Tahsilat")
	g.file.SetCellValue(sheet, "B5", data.TotalCollected)
	g.file.SetCellValue(sheet, "A6", "Bekleyen")
	g.file.SetCellValue(sheet, "B6", data.TotalPending)
	g.file.SetCellValue(sheet, "A7", "Tahsilat Oranı")
	g.file.SetCellValue(sheet, "B7", fmt.Sprintf("%%%.1f", data.CollectionRate))

	// Gider kalemleri
	g.file.SetCellValue(sheet, "A9", "Gider Kalemleri")
	headers := []string{"Kalem", "Dağıtım Şekli", "Tutar"}
	for i, h := range headers {
		col := string(rune('A' + i))
		g.file.SetCellValue(sheet, col+"10", h)
	}

	for i, item := range data.ExpenseItems {
		row := 11 + i
		g.file.SetCellValue(sheet, fmt.Sprintf("A%d", row), item.Name)
		g.file.SetCellValue(sheet, fmt.Sprintf("B%d", row), item.DistributionType)
		g.file.SetCellValue(sheet, fmt.Sprintf("C%d", row), item.Amount)
	}

	// Daire bazlı - yeni sheet
	unitSheet := "Daire Detay"
	g.file.NewSheet(unitSheet)

	unitHeaders := []string{"Daire", "Sakin", "Tahakkuk", "Ödenen", "Kalan"}
	for i, h := range unitHeaders {
		col := string(rune('A' + i))
		g.file.SetCellValue(unitSheet, col+"1", h)
	}

	for i, unit := range data.UnitAssessments {
		row := 2 + i
		g.file.SetCellValue(unitSheet, fmt.Sprintf("A%d", row), unit.UnitName)
		g.file.SetCellValue(unitSheet, fmt.Sprintf("B%d", row), unit.ResidentName)
		g.file.SetCellValue(unitSheet, fmt.Sprintf("C%d", row), unit.Assessed)
		g.file.SetCellValue(unitSheet, fmt.Sprintf("D%d", row), unit.Paid)
		g.file.SetCellValue(unitSheet, fmt.Sprintf("E%d", row), unit.Balance)
	}

	// Stil uygula
	g.applyStyles(sheet)
	g.applyStyles(unitSheet)

	var buf bytes.Buffer
	err := g.file.Write(&buf)
	return buf.Bytes(), err
}

// GenerateCollectionExcel - Tahsilat Excel raporu
func (g *ExcelGenerator) GenerateCollectionExcel(data *CollectionReportData) ([]byte, error) {
	sheet := "Tahsilat Raporu"
	g.file.SetSheetName("Sheet1", sheet)

	g.file.SetCellValue(sheet, "A1", data.PropertyName)
	g.file.SetCellValue(sheet, "A2", fmt.Sprintf("Tahsilat Raporu: %s - %s", data.StartDate, data.EndDate))

	headers := []string{"Tarih", "Daire", "Sakin", "Tutar", "Ödeme Yöntemi"}
	for i, h := range headers {
		col := string(rune('A' + i))
		g.file.SetCellValue(sheet, col+"4", h)
	}

	for i, payment := range data.Payments {
		row := 5 + i
		g.file.SetCellValue(sheet, fmt.Sprintf("A%d", row), payment.Date)
		g.file.SetCellValue(sheet, fmt.Sprintf("B%d", row), payment.UnitName)
		g.file.SetCellValue(sheet, fmt.Sprintf("C%d", row), payment.ResidentName)
		g.file.SetCellValue(sheet, fmt.Sprintf("D%d", row), payment.Amount)
		g.file.SetCellValue(sheet, fmt.Sprintf("E%d", row), payment.Method)
	}

	// Toplam
	totalRow := 5 + len(data.Payments) + 1
	g.file.SetCellValue(sheet, fmt.Sprintf("C%d", totalRow), "TOPLAM:")
	g.file.SetCellValue(sheet, fmt.Sprintf("D%d", totalRow), data.TotalAmount)

	g.applyStyles(sheet)

	var buf bytes.Buffer
	err := g.file.Write(&buf)
	return buf.Bytes(), err
}

// GenerateConsumptionExcel - Tüketim Excel raporu
func (g *ExcelGenerator) GenerateConsumptionExcel(data *ConsumptionReportData) ([]byte, error) {
	sheet := "Tüketim Raporu"
	g.file.SetSheetName("Sheet1", sheet)

	g.file.SetCellValue(sheet, "A1", data.PropertyName)
	g.file.SetCellValue(sheet, "A2", fmt.Sprintf("%s Tüketim Raporu - %s", data.MeterType, data.Period))

	headers := []string{"Daire", "Sayaç No", "Önceki Okuma", "Yeni Okuma", "Tüketim", "Tutar (TL)"}
	for i, h := range headers {
		col := string(rune('A' + i))
		g.file.SetCellValue(sheet, col+"4", h)
	}

	for i, reading := range data.Readings {
		row := 5 + i
		g.file.SetCellValue(sheet, fmt.Sprintf("A%d", row), reading.UnitName)
		g.file.SetCellValue(sheet, fmt.Sprintf("B%d", row), reading.MeterSerial)
		g.file.SetCellValue(sheet, fmt.Sprintf("C%d", row), reading.PreviousValue)
		g.file.SetCellValue(sheet, fmt.Sprintf("D%d", row), reading.CurrentValue)
		g.file.SetCellValue(sheet, fmt.Sprintf("E%d", row), reading.Consumption)
		g.file.SetCellValue(sheet, fmt.Sprintf("F%d", row), reading.Cost)
	}

	g.applyStyles(sheet)

	var buf bytes.Buffer
	err := g.file.Write(&buf)
	return buf.Bytes(), err
}

// GenerateMeterReadingTemplate - Sayaç okuma şablonu (boş)
func (g *ExcelGenerator) GenerateMeterReadingTemplate(units []MeterTemplateUnit) ([]byte, error) {
	sheet := "Sayaç Okuma"
	g.file.SetSheetName("Sheet1", sheet)

	headers := []string{"Daire", "Sakin", "Sayaç No", "Önceki Okuma", "Yeni Okuma (Giriniz)"}
	for i, h := range headers {
		col := string(rune('A' + i))
		g.file.SetCellValue(sheet, col+"1", h)
	}

	for i, unit := range units {
		row := 2 + i
		g.file.SetCellValue(sheet, fmt.Sprintf("A%d", row), unit.UnitName)
		g.file.SetCellValue(sheet, fmt.Sprintf("B%d", row), unit.ResidentName)
		g.file.SetCellValue(sheet, fmt.Sprintf("C%d", row), unit.MeterSerial)
		g.file.SetCellValue(sheet, fmt.Sprintf("D%d", row), unit.LastReading)
		// E sütunu kullanıcı tarafından doldurulacak
	}

	// Kolon genişliklerini ayarla
	g.file.SetColWidth(sheet, "A", "A", 15)
	g.file.SetColWidth(sheet, "B", "B", 25)
	g.file.SetColWidth(sheet, "C", "C", 20)
	g.file.SetColWidth(sheet, "D", "E", 18)

	var buf bytes.Buffer
	err := g.file.Write(&buf)
	return buf.Bytes(), err
}

func (g *ExcelGenerator) applyStyles(sheet string) {
	// Başlık stili
	headerStyle, _ := g.file.NewStyle(&excelize.Style{
		Font: &excelize.Font{Bold: true, Size: 14},
	})
	g.file.SetCellStyle(sheet, "A1", "A1", headerStyle)

	// Tablo başlığı stili
	tableHeaderStyle, _ := g.file.NewStyle(&excelize.Style{
		Font: &excelize.Font{Bold: true, Color: "FFFFFF"},
		Fill: excelize.Fill{Type: "pattern", Color: []string{"2563EB"}, Pattern: 1},
		Border: []excelize.Border{
			{Type: "left", Color: "000000", Style: 1},
			{Type: "right", Color: "000000", Style: 1},
			{Type: "top", Color: "000000", Style: 1},
			{Type: "bottom", Color: "000000", Style: 1},
		},
	})
	_ = tableHeaderStyle // Kullanılacak
}

type MeterTemplateUnit struct {
	UnitName     string
	ResidentName string
	MeterSerial  string
	LastReading  float64
}
