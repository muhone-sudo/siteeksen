// Package models, gider yönetimi veri yapılarını tanımlar.
package models

import "time"

// Gider onay durumları.
const (
	StatusPending  = "PENDING"
	StatusApproved = "APPROVED"
	StatusRejected = "REJECTED"
)

// Category, gider kalemidir.
//
// `property_id` NULL olan kayıtlar tüm siteler için VARSAYILAN şablondur;
// site kendi kalemini tanımlayabilir (KMK m.20: "aralarında başka türlü anlaşma olmadıkça").
type Category struct {
	ID                   string `json:"id"`
	PropertyID           string `json:"property_id,omitempty"`
	Name                 string `json:"name"`
	Description          string `json:"description,omitempty"`
	Type                 string `json:"type,omitempty"` // FIXED | VARIABLE | UNPLANNED
	DistributionType     string `json:"distribution_type"`
	ReflectsToAssessment bool   `json:"reflects_to_assessment"`
	AppliesToGroundFloor bool   `json:"applies_to_ground_floor"`
	IsDefault            bool   `json:"is_default"`
	DisplayOrder         int    `json:"display_order"`
	IsActive             bool   `json:"is_active"`
	// LegalBasis, dağıtım türünün KMK dayanağını açıklar (arayüzde gösterilir).
	LegalBasis string `json:"legal_basis,omitempty"`
}

// Expense, tek bir gider kaydıdır.
type Expense struct {
	ID            string    `json:"id"`
	PropertyID    string    `json:"property_id"`
	CategoryID    string    `json:"category_id"`
	CategoryName  string    `json:"category_name,omitempty"`
	Description   string    `json:"description"`
	Amount        float64   `json:"amount"`
	Currency      string    `json:"currency"`
	ExpenseDate   time.Time `json:"expense_date"`
	IsInvoiced    bool      `json:"is_invoiced"`
	InvoiceReason string    `json:"invoice_reason,omitempty"`

	ReflectsToAssessment bool   `json:"reflects_to_assessment"`
	AssessmentPeriod     string `json:"assessment_period,omitempty"`
	DistributionType     string `json:"distribution_type"`

	Status          string     `json:"status"`
	ApprovedBy      string     `json:"approved_by,omitempty"`
	ApprovedAt      *time.Time `json:"approved_at,omitempty"`
	RejectionReason string     `json:"rejection_reason,omitempty"`

	VendorName    string     `json:"vendor_name,omitempty"`
	VendorTaxID   string     `json:"vendor_tax_id,omitempty"`
	InvoiceNumber string     `json:"invoice_number,omitempty"`
	InvoiceDate   *time.Time `json:"invoice_date,omitempty"`

	Notes     string    `json:"notes,omitempty"`
	CreatedBy string    `json:"created_by,omitempty"`
	CreatedAt time.Time `json:"created_at"`

	// PerUnitAmount, bu giderin bağımsız bölüm başına ortalama payıdır (bilgi amaçlı).
	// Gerçek paylar `Distributions` içindedir; dağıtım türüne göre daireler arasında farklıdır.
	PerUnitAmount *float64       `json:"per_unit_amount,omitempty"`
	Distributions []Distribution `json:"distributions,omitempty"`
}

// Distribution, giderin bir bağımsız bölüme düşen payıdır.
type Distribution struct {
	UnitID   string  `json:"unit_id"`
	UnitName string  `json:"unit_name,omitempty"`
	Amount   float64 `json:"amount"`
	IsPaid   bool    `json:"is_paid"`
}

// CreateExpenseInput, yeni gider girdisidir.
type CreateExpenseInput struct {
	CategoryID    string  `json:"category_id" binding:"required"`
	Description   string  `json:"description" binding:"required"`
	Amount        float64 `json:"amount" binding:"required,gt=0"`
	ExpenseDate   string  `json:"expense_date" binding:"required"` // YYYY-AA-GG
	IsInvoiced    *bool   `json:"is_invoiced"`
	InvoiceReason string  `json:"invoice_reason"`

	ReflectsToAssessment *bool  `json:"reflects_to_assessment"`
	AssessmentPeriod     string `json:"assessment_period"` // YYYY-AA
	// DistributionType verilmezse kalemin varsayılanı kullanılır.
	DistributionType string `json:"distribution_type"`

	VendorName    string `json:"vendor_name"`
	VendorTaxID   string `json:"vendor_tax_id"`
	InvoiceNumber string `json:"invoice_number"`
	InvoiceDate   string `json:"invoice_date"`
	Notes         string `json:"notes"`
}

// Summary, dönem bazlı gider özetidir.
type Summary struct {
	PeriodYear  int     `json:"period_year"`
	PeriodMonth int     `json:"period_month,omitempty"`
	TotalAmount float64 `json:"total_amount"`
	// InvoicedAmount / NonInvoicedAmount ayrımı denetim için önemlidir:
	// faturasız gider yönetim kurulu kararı gerektirir.
	InvoicedAmount    float64         `json:"invoiced_amount"`
	NonInvoicedAmount float64         `json:"non_invoiced_amount"`
	PendingCount      int             `json:"pending_count"`
	ByCategory        []CategoryTotal `json:"by_category"`
}

// CategoryTotal, kalem bazlı toplamdır.
type CategoryTotal struct {
	CategoryID   string  `json:"category_id"`
	CategoryName string  `json:"category_name"`
	Amount       float64 `json:"amount"`
	Count        int     `json:"count"`
}
