package reports

import (
	"testing"
)

func TestPDFGeneration(t *testing.T) {
	gen := NewPDFGenerator()
	if gen == nil {
		t.Fatal("Failed to create PDFGenerator")
	}

	data := &AssessmentReportData{
		PropertyName:   "Test Site Yönetimi",
		Period:         "Haziran 2026",
		TotalAssessed:  5000.0,
		TotalCollected: 4000.0,
		TotalPending:   1000.0,
		CollectionRate: 80.0,
		ExpenseItems: []ExpenseItem{
			{Name: "Asansör Bakımı", DistributionType: "EŞİT", Amount: 2000.0},
			{Name: "Temizlik", DistributionType: "ARSA_PAYI", Amount: 3000.0},
		},
		UnitAssessments: []UnitAssessment{
			{UnitName: "A Blok Daire 1", ResidentName: "Ahmet Yılmaz", Assessed: 250.0, Paid: 250.0, Balance: 0.0},
			{UnitName: "A Blok Daire 2", ResidentName: "Mehmet Demir", Assessed: 250.0, Paid: 0.0, Balance: 250.0},
		},
	}

	pdfBytes, err := gen.GenerateAssessmentReport(data)
	if err != nil {
		t.Fatalf("Failed to generate PDF report: %v", err)
	}

	if len(pdfBytes) == 0 {
		t.Error("Generated PDF byte slice is empty")
	}
}

func TestExcelGeneration(t *testing.T) {
	gen := NewExcelGenerator()
	if gen == nil {
		t.Fatal("Failed to create ExcelGenerator")
	}

	data := &AssessmentReportData{
		PropertyName:   "Test Site Yönetimi",
		Period:         "Haziran 2026",
		TotalAssessed:  5000.0,
		TotalCollected: 4000.0,
		TotalPending:   1000.0,
		CollectionRate: 80.0,
		ExpenseItems: []ExpenseItem{
			{Name: "Asansör Bakımı", DistributionType: "EŞİT", Amount: 2000.0},
			{Name: "Temizlik", DistributionType: "ARSA_PAYI", Amount: 3000.0},
		},
		UnitAssessments: []UnitAssessment{
			{UnitName: "A Blok Daire 1", ResidentName: "Ahmet Yılmaz", Assessed: 250.0, Paid: 250.0, Balance: 0.0},
			{UnitName: "A Blok Daire 2", ResidentName: "Mehmet Demir", Assessed: 250.0, Paid: 0.0, Balance: 250.0},
		},
	}

	excelBytes, err := gen.GenerateAssessmentExcel(data)
	if err != nil {
		t.Fatalf("Failed to generate Excel report: %v", err)
	}

	if len(excelBytes) == 0 {
		t.Error("Generated Excel byte slice is empty")
	}
}
