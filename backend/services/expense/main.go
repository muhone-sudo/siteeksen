package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

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
	r.GET("/health", stub.Health("expense"))

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
func listCategories(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func createCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func updateCategory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

// Expense handlers
func listExpenses(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func getExpense(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func createExpense(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func updateExpense(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func deleteExpense(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func updateExpenseStatus(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

// Invoice handlers
func uploadInvoice(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func deleteInvoice(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

// AI Invoice Scanning
func scanInvoice(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

// Reports
func getExpenseSummary(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

func getMonthlyReport(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}

// Resident view
func getResidentExpenses(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "expense")
}
