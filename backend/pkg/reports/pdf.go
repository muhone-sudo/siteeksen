package reports

import (
	"bytes"
	"fmt"
	"time"

	"github.com/jung-kurt/gofpdf"
)

// PDFGenerator - PDF rapor oluşturucu
type PDFGenerator struct {
	pdf       *gofpdf.Fpdf
	pageWidth float64
}

// NewPDFGenerator - Yeni PDF generator
func NewPDFGenerator() *PDFGenerator {
	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.SetAutoPageBreak(true, 15)
	
	return &PDFGenerator{
		pdf:       pdf,
		pageWidth: 210,
	}
}

// GenerateAssessmentReport - Aidat raporu
func (g *PDFGenerator) GenerateAssessmentReport(data *AssessmentReportData) ([]byte, error) {
	g.pdf.AddPage()
	g.addHeader(data.PropertyName, "Aidat Raporu")
	
	// Dönem bilgisi
	g.pdf.SetFont("Arial", "B", 12)
	g.pdf.Cell(0, 10, fmt.Sprintf("Dönem: %s", data.Period), "", 1, "L", false, 0, "")
	g.pdf.Ln(5)

	// Özet kartları
	g.addSummaryCards([]SummaryCard{
		{Label: "Toplam Tahakkuk", Value: formatCurrency(data.TotalAssessed)},
		{Label: "Tahsilat", Value: formatCurrency(data.TotalCollected)},
		{Label: "Bekleyen", Value: formatCurrency(data.TotalPending)},
		{Label: "Tahsilat Oranı", Value: fmt.Sprintf("%%%.1f", data.CollectionRate)},
	})

	// Gider kalemleri tablosu
	g.pdf.Ln(10)
	g.pdf.SetFont("Arial", "B", 11)
	g.pdf.Cell(0, 8, "Gider Kalemleri", "", 1, "L", false, 0, "")

	headers := []string{"Kalem", "Dağıtım", "Tutar"}
	widths := []float64{80, 50, 50}
	g.addTableHeader(headers, widths)

	for _, item := range data.ExpenseItems {
		g.addTableRow([]string{
			item.Name,
			item.DistributionType,
			formatCurrency(item.Amount),
		}, widths)
	}

	// Daire bazlı tahakkuklar
	g.pdf.AddPage()
	g.pdf.SetFont("Arial", "B", 11)
	g.pdf.Cell(0, 8, "Daire Bazlı Tahakkuklar", "", 1, "L", false, 0, "")

	unitHeaders := []string{"Daire", "Sakin", "Tahakkuk", "Ödenen", "Kalan"}
	unitWidths := []float64{30, 50, 35, 35, 35}
	g.addTableHeader(unitHeaders, unitWidths)

	for _, unit := range data.UnitAssessments {
		g.addTableRow([]string{
			unit.UnitName,
			unit.ResidentName,
			formatCurrency(unit.Assessed),
			formatCurrency(unit.Paid),
			formatCurrency(unit.Balance),
		}, unitWidths)
	}

	g.addFooter()

	var buf bytes.Buffer
	err := g.pdf.Output(&buf)
	return buf.Bytes(), err
}

// GenerateCollectionReport - Tahsilat raporu
func (g *PDFGenerator) GenerateCollectionReport(data *CollectionReportData) ([]byte, error) {
	g.pdf.AddPage()
	g.addHeader(data.PropertyName, "Tahsilat Raporu")

	g.pdf.SetFont("Arial", "", 10)
	g.pdf.Cell(0, 8, fmt.Sprintf("Rapor Dönemi: %s - %s", data.StartDate, data.EndDate), "", 1, "L", false, 0, "")
	g.pdf.Ln(5)

	// Ödeme listesi
	headers := []string{"Tarih", "Daire", "Sakin", "Tutar", "Yöntem"}
	widths := []float64{30, 25, 50, 35, 40}
	g.addTableHeader(headers, widths)

	for _, payment := range data.Payments {
		g.addTableRow([]string{
			payment.Date,
			payment.UnitName,
			payment.ResidentName,
			formatCurrency(payment.Amount),
			payment.Method,
		}, widths)
	}

	// Toplam
	g.pdf.SetFont("Arial", "B", 10)
	g.pdf.Cell(105, 8, "", "", 0, "", false, 0, "")
	g.pdf.Cell(35, 8, formatCurrency(data.TotalAmount), "T", 1, "R", false, 0, "")

	g.addFooter()

	var buf bytes.Buffer
	err := g.pdf.Output(&buf)
	return buf.Bytes(), err
}

// GenerateConsumptionReport - Tüketim raporu
func (g *PDFGenerator) GenerateConsumptionReport(data *ConsumptionReportData) ([]byte, error) {
	g.pdf.AddPage()
	g.addHeader(data.PropertyName, fmt.Sprintf("%s Tüketim Raporu", data.MeterType))

	g.pdf.SetFont("Arial", "", 10)
	g.pdf.Cell(0, 8, fmt.Sprintf("Dönem: %s", data.Period), "", 1, "L", false, 0, "")
	g.pdf.Ln(5)

	headers := []string{"Daire", "Sayaç No", "Önceki", "Yeni", "Tüketim", "Tutar"}
	widths := []float64{25, 35, 25, 25, 25, 30}
	g.addTableHeader(headers, widths)

	for _, reading := range data.Readings {
		g.addTableRow([]string{
			reading.UnitName,
			reading.MeterSerial,
			fmt.Sprintf("%.2f", reading.PreviousValue),
			fmt.Sprintf("%.2f", reading.CurrentValue),
			fmt.Sprintf("%.2f", reading.Consumption),
			formatCurrency(reading.Cost),
		}, widths)
	}

	g.addFooter()

	var buf bytes.Buffer
	err := g.pdf.Output(&buf)
	return buf.Bytes(), err
}

func (g *PDFGenerator) addHeader(propertyName, reportTitle string) {
	g.pdf.SetFont("Arial", "B", 16)
	g.pdf.Cell(0, 10, propertyName, "", 1, "C", false, 0, "")
	g.pdf.SetFont("Arial", "", 14)
	g.pdf.Cell(0, 8, reportTitle, "", 1, "C", false, 0, "")
	g.pdf.SetFont("Arial", "", 9)
	g.pdf.SetTextColor(128, 128, 128)
	g.pdf.Cell(0, 6, fmt.Sprintf("Oluşturulma: %s", time.Now().Format("02.01.2006 15:04")), "", 1, "C", false, 0, "")
	g.pdf.SetTextColor(0, 0, 0)
	g.pdf.Ln(5)
}

func (g *PDFGenerator) addFooter() {
	g.pdf.SetY(-20)
	g.pdf.SetFont("Arial", "I", 8)
	g.pdf.SetTextColor(128, 128, 128)
	g.pdf.Cell(0, 10, "SiteEksen - Site Yönetim Platformu", "", 0, "C", false, 0, "")
}

func (g *PDFGenerator) addSummaryCards(cards []SummaryCard) {
	cardWidth := (g.pageWidth - 20) / float64(len(cards))
	
	g.pdf.SetFillColor(240, 240, 245)
	for _, card := range cards {
		g.pdf.SetFont("Arial", "", 9)
		g.pdf.CellFormat(cardWidth-2, 6, card.Label, "", 0, "C", true, 0, "")
	}
	g.pdf.Ln(-1)
	for _, card := range cards {
		g.pdf.SetFont("Arial", "B", 12)
		g.pdf.CellFormat(cardWidth-2, 8, card.Value, "", 0, "C", true, 0, "")
	}
	g.pdf.Ln(-1)
}

func (g *PDFGenerator) addTableHeader(headers []string, widths []float64) {
	g.pdf.SetFillColor(37, 99, 235)
	g.pdf.SetTextColor(255, 255, 255)
	g.pdf.SetFont("Arial", "B", 9)
	
	for i, h := range headers {
		g.pdf.CellFormat(widths[i], 7, h, "1", 0, "C", true, 0, "")
	}
	g.pdf.Ln(-1)
	g.pdf.SetTextColor(0, 0, 0)
}

func (g *PDFGenerator) addTableRow(cells []string, widths []float64) {
	g.pdf.SetFont("Arial", "", 9)
	for i, cell := range cells {
		g.pdf.CellFormat(widths[i], 6, cell, "1", 0, "L", false, 0, "")
	}
	g.pdf.Ln(-1)
}

func formatCurrency(amount float64) string {
	return fmt.Sprintf("₺%.2f", amount)
}

// Data types
type SummaryCard struct {
	Label string
	Value string
}

type AssessmentReportData struct {
	PropertyName    string
	Period          string
	TotalAssessed   float64
	TotalCollected  float64
	TotalPending    float64
	CollectionRate  float64
	ExpenseItems    []ExpenseItem
	UnitAssessments []UnitAssessment
}

type ExpenseItem struct {
	Name             string
	DistributionType string
	Amount           float64
}

type UnitAssessment struct {
	UnitName     string
	ResidentName string
	Assessed     float64
	Paid         float64
	Balance      float64
}

type CollectionReportData struct {
	PropertyName string
	StartDate    string
	EndDate      string
	TotalAmount  float64
	Payments     []PaymentEntry
}

type PaymentEntry struct {
	Date         string
	UnitName     string
	ResidentName string
	Amount       float64
	Method       string
}

type ConsumptionReportData struct {
	PropertyName string
	MeterType    string
	Period       string
	Readings     []ConsumptionReading
}

type ConsumptionReading struct {
	UnitName      string
	MeterSerial   string
	PreviousValue float64
	CurrentValue  float64
	Consumption   float64
	Cost          float64
}
