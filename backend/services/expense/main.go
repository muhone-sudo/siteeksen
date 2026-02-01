package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// Models
type Expense struct {
	ID                   string    `json:"id"`
	PropertyID           string    `json:"property_id"`
	CategoryID           string    `json:"category_id"`
	CategoryName         string    `json:"category_name,omitempty"`
	Description          string    `json:"description"`
	Amount               float64   `json:"amount"`
	Currency             string    `json:"currency"`
	ExpenseDate          string    `json:"expense_date"`
	IsInvoiced           bool      `json:"is_invoiced"`
	InvoiceReason        string    `json:"invoice_reason,omitempty"`
	ReflectsToAssessment bool      `json:"reflects_to_assessment"`
	AssessmentPeriod     string    `json:"assessment_period,omitempty"`
	DistributionType     string    `json:"distribution_type"`
	Status               string    `json:"status"`
	VendorName           string    `json:"vendor_name,omitempty"`
	InvoiceNumber        string    `json:"invoice_number,omitempty"`
	InvoiceDate          string    `json:"invoice_date,omitempty"`
	Notes                string    `json:"notes,omitempty"`
	Invoices             []Invoice `json:"invoices,omitempty"`
	CreatedBy            string    `json:"created_by"`
	CreatedAt            time.Time `json:"created_at"`
}

type Invoice struct {
	ID              string                 `json:"id"`
	ExpenseID       string                 `json:"expense_id"`
	FileName        string                 `json:"file_name"`
	FileURL         string                 `json:"file_url"`
	FileType        string                 `json:"file_type"`
	FileSize        int64                  `json:"file_size"`
	AIProcessed     bool                   `json:"ai_processed"`
	AIExtractedData map[string]interface{} `json:"ai_extracted_data,omitempty"`
	AIConfidence    float64                `json:"ai_confidence_score,omitempty"`
	UploadedAt      time.Time              `json:"uploaded_at"`
}

type ExpenseCategory struct {
	ID                   string `json:"id"`
	Name                 string `json:"name"`
	Description          string `json:"description,omitempty"`
	Type                 string `json:"type"` // FIXED, VARIABLE, UNPLANNED
	ReflectsToAssessment bool   `json:"reflects_to_assessment"`
	DisplayOrder         int    `json:"display_order"`
}

type AIInvoiceScanRequest struct {
	FileURL  string `json:"file_url"`
	FileType string `json:"file_type"`
}

type AIInvoiceScanResult struct {
	Success         bool                   `json:"success"`
	VendorName      string                 `json:"vendor_name,omitempty"`
	InvoiceNumber   string                 `json:"invoice_number,omitempty"`
	InvoiceDate     string                 `json:"invoice_date,omitempty"`
	TotalAmount     float64                `json:"total_amount,omitempty"`
	Currency        string                 `json:"currency,omitempty"`
	TaxAmount       float64                `json:"tax_amount,omitempty"`
	CategorySuggest string                 `json:"category_suggestion,omitempty"`
	Confidence      float64                `json:"confidence_score"`
	RawData         map[string]interface{} `json:"raw_data,omitempty"`
	Error           string                 `json:"error,omitempty"`
}

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "expense"})
	})

	// Expense Categories
	categories := r.Group("/api/v1/expense-categories")
	{
		categories.GET("", listCategories)
		categories.POST("", createCategory)
		categories.PUT("/:id", updateCategory)
	}

	// Expenses
	expenses := r.Group("/api/v1/expenses")
	{
		expenses.GET("", listExpenses)
		expenses.GET("/:id", getExpense)
		expenses.POST("", createExpense)
		expenses.PUT("/:id", updateExpense)
		expenses.DELETE("/:id", deleteExpense)
		expenses.PATCH("/:id/status", updateExpenseStatus)

		// Invoices
		expenses.POST("/:id/invoices", uploadInvoice)
		expenses.DELETE("/:id/invoices/:invoiceId", deleteInvoice)
	}

	// AI Invoice Scanning
	r.POST("/api/v1/expenses/scan-invoice", scanInvoice)

	// Reports
	r.GET("/api/v1/expenses/summary", getExpenseSummary)
	r.GET("/api/v1/expenses/monthly", getMonthlyReport)

	// Resident view (read-only)
	r.GET("/api/v1/resident/expenses", getResidentExpenses)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8086"
	}

	log.Printf("Expense Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Category handlers
func listCategories(c *gin.Context) {
	categories := []ExpenseCategory{
		{ID: "1", Name: "Bina Temizliği", Type: "FIXED", ReflectsToAssessment: false, DisplayOrder: 1},
		{ID: "2", Name: "Güvenlik", Type: "FIXED", ReflectsToAssessment: false, DisplayOrder: 2},
		{ID: "3", Name: "Yönetici Ücreti", Type: "FIXED", ReflectsToAssessment: false, DisplayOrder: 3},
		{ID: "4", Name: "Ortak Elektrik", Type: "VARIABLE", ReflectsToAssessment: true, DisplayOrder: 4},
		{ID: "5", Name: "Ortak Su", Type: "VARIABLE", ReflectsToAssessment: true, DisplayOrder: 5},
		{ID: "6", Name: "Ortak Isınma", Type: "VARIABLE", ReflectsToAssessment: true, DisplayOrder: 6},
		{ID: "7", Name: "Asansör Bakımı", Type: "UNPLANNED", ReflectsToAssessment: true, DisplayOrder: 7},
		{ID: "8", Name: "Bahçe Bakımı", Type: "VARIABLE", ReflectsToAssessment: true, DisplayOrder: 8},
		{ID: "9", Name: "Acil Tamir", Type: "UNPLANNED", ReflectsToAssessment: true, DisplayOrder: 9},
	}
	c.JSON(http.StatusOK, gin.H{"data": categories})
}

func createCategory(c *gin.Context) {
	var cat ExpenseCategory
	if err := c.ShouldBindJSON(&cat); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	cat.ID = "new-id"
	c.JSON(http.StatusCreated, cat)
}

func updateCategory(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Kategori güncellendi"})
}

// Expense handlers
func listExpenses(c *gin.Context) {
	// Query params: month, category_id, is_invoiced, reflects_to_assessment
	expenses := []Expense{
		{
			ID: "1", CategoryName: "Ortak Elektrik", Description: "Ocak 2026 elektrik faturası",
			Amount: 2450.75, ExpenseDate: "2026-01-28", IsInvoiced: true,
			ReflectsToAssessment: true, Status: "APPROVED", VendorName: "AYEDAŞ",
		},
		{
			ID: "2", CategoryName: "Asansör Bakımı", Description: "Yıllık bakım",
			Amount: 3500.00, ExpenseDate: "2026-01-15", IsInvoiced: true,
			ReflectsToAssessment: true, Status: "APPROVED", VendorName: "Kone",
		},
		{
			ID: "3", CategoryName: "Acil Tamir", Description: "Çatı tamir işlemi",
			Amount: 1800.00, ExpenseDate: "2026-01-20", IsInvoiced: false,
			InvoiceReason: "Elden ödeme - usta", ReflectsToAssessment: true, Status: "PENDING",
		},
	}
	c.JSON(http.StatusOK, gin.H{"data": expenses, "total": len(expenses)})
}

func getExpense(c *gin.Context) {
	id := c.Param("id")
	expense := Expense{
		ID: id, CategoryID: "4", CategoryName: "Ortak Elektrik",
		Description: "Ocak 2026 elektrik faturası", Amount: 2450.75,
		ExpenseDate: "2026-01-28", IsInvoiced: true, ReflectsToAssessment: true,
		Status: "APPROVED", VendorName: "AYEDAŞ", InvoiceNumber: "2026-001234",
		Invoices: []Invoice{
			{ID: "inv1", FileName: "fatura.pdf", FileURL: "/uploads/fatura.pdf", FileType: "PDF", AIProcessed: true},
		},
	}
	c.JSON(http.StatusOK, expense)
}

func createExpense(c *gin.Context) {
	var expense Expense
	if err := c.ShouldBindJSON(&expense); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	expense.ID = "new-expense-id"
	expense.Status = "APPROVED"
	if !expense.IsInvoiced {
		expense.Status = "PENDING" // Faturasız giderler onay bekler
	}
	expense.CreatedAt = time.Now()
	c.JSON(http.StatusCreated, expense)
}

func updateExpense(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Gider güncellendi"})
}

func deleteExpense(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Gider silindi"})
}

func updateExpenseStatus(c *gin.Context) {
	var req struct {
		Status string `json:"status"`
		Reason string `json:"reason,omitempty"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Durum güncellendi", "status": req.Status})
}

// Invoice handlers
func uploadInvoice(c *gin.Context) {
	// Normalde file upload olacak
	invoice := Invoice{
		ID:        "new-invoice-id",
		ExpenseID: c.Param("id"),
		FileName:  "fatura.pdf",
		FileURL:   "/uploads/fatura.pdf",
		FileType:  "PDF",
	}
	c.JSON(http.StatusCreated, invoice)
}

func deleteInvoice(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Fatura silindi"})
}

// AI Invoice Scanning
func scanInvoice(c *gin.Context) {
	var req AIInvoiceScanRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Gerçek AI servisi entegrasyonu
	// Bu mock response, gerçekte OpenAI GPT-4 Vision veya Google Document AI kullanılacak
	result := AIInvoiceScanResult{
		Success:         true,
		VendorName:      "AYEDAŞ Elektrik Dağıtım A.Ş.",
		InvoiceNumber:   "2026-001234",
		InvoiceDate:     "2026-01-28",
		TotalAmount:     2450.75,
		Currency:        "TRY",
		TaxAmount:       441.14,
		CategorySuggest: "Ortak Elektrik",
		Confidence:      0.94,
		RawData: map[string]interface{}{
			"consumption_kwh": 1250,
			"unit_price":      1.85,
		},
	}

	c.JSON(http.StatusOK, result)
}

// Reports
func getExpenseSummary(c *gin.Context) {
	summary := gin.H{
		"total_expenses":         45750.25,
		"invoiced_expenses":      42150.25,
		"non_invoiced_expenses":  3600.00,
		"assessment_reflecting":  28500.00,
		"fixed_expenses":         17250.25,
		"variable_expenses":      21500.00,
		"unplanned_expenses":     7000.00,
		"pending_approval_count": 2,
		"pending_approval_amount": 3600.00,
	}
	c.JSON(http.StatusOK, summary)
}

func getMonthlyReport(c *gin.Context) {
	// month := c.Query("month") // 2026-01
	report := []gin.H{
		{"category": "Ortak Elektrik", "amount": 2450.75, "invoiced": true, "reflects": true},
		{"category": "Ortak Su", "amount": 1850.00, "invoiced": true, "reflects": true},
		{"category": "Bina Temizliği", "amount": 8000.00, "invoiced": true, "reflects": false},
		{"category": "Güvenlik", "amount": 12000.00, "invoiced": true, "reflects": false},
		{"category": "Asansör Bakımı", "amount": 3500.00, "invoiced": true, "reflects": true},
	}
	c.JSON(http.StatusOK, gin.H{"data": report})
}

// Resident view
func getResidentExpenses(c *gin.Context) {
	// Sakinler sadece onaylanmış giderleri görebilir
	expenses := []gin.H{
		{
			"category":     "Ortak Elektrik",
			"amount":       2450.75,
			"date":         "2026-01-28",
			"is_invoiced":  true,
			"reflects":     true,
			"has_document": true,
		},
		{
			"category":                 "Acil Tamir",
			"description":              "Çatı tamir işlemi",
			"amount":                   1800.00,
			"date":                     "2026-01-20",
			"is_invoiced":              false,
			"non_invoiced_reason":      "Elden ödeme - usta",
			"reflects":                 true,
			"has_document":             false,
			"non_invoiced_badge":       true, // Frontend'de belirgin gösterim için
			"non_invoiced_explanation": "Bu gider için resmi fatura alınamamıştır. Detay için yönetime başvurun.",
		},
	}
	c.JSON(http.StatusOK, gin.H{"data": expenses})
}
