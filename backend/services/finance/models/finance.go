package models

import "time"

// Assessment aylık tahakkuk
type Assessment struct {
	ID          string    `json:"id"`
	PropertyID  string    `json:"property_id"`
	UnitID      string    `json:"unit_id"`
	PeriodYear  int       `json:"period_year"`
	PeriodMonth int       `json:"period_month"`
	BaseAmount  float64   `json:"base_amount"`
	LateFee     float64   `json:"late_fee"`
	TotalAmount float64   `json:"total_amount"`
	PaidAmount  float64   `json:"paid_amount"`
	DueDate     time.Time `json:"due_date"`
	Status      string    `json:"status"` // PENDING, PARTIAL, PAID, OVERDUE
	CreatedAt   time.Time `json:"created_at"`
}

// AssessmentSummary aidat özeti (liste görünümü)
type AssessmentSummary struct {
	ID          string    `json:"id"`
	Period      string    `json:"period"` // "2026-01"
	BaseAmount  float64   `json:"base_amount"`
	LateFee     float64   `json:"late_fee"`
	TotalAmount float64   `json:"total_amount"`
	PaidAmount  float64   `json:"paid_amount"`
	Status      string    `json:"status"`
}

// AssessmentDetail aidat detayı
type AssessmentDetail struct {
	Assessment
	Details []AssessmentDetailItem `json:"details"`
}

// AssessmentDetailItem gider kalemi detayı
type AssessmentDetailItem struct {
	Category         string  `json:"category"`
	Amount           float64 `json:"amount"`
	CalculationBasis string  `json:"calculation_basis"`
}

// ExpenseCategory gider kalemi
type ExpenseCategory struct {
	ID                   string  `json:"id"`
	PropertyID           string  `json:"property_id"`
	Name                 string  `json:"name"`
	DistributionType     string  `json:"distribution_type"` // SHARE_RATIO, EQUAL, AREA_M2
	AppliesToCommercial  bool    `json:"applies_to_commercial"`
	AppliesToGroundFloor bool    `json:"applies_to_ground_floor"`
	CustomFormula        string  `json:"custom_formula"`
	IsActive             bool    `json:"is_active"`
}

// Payment ödeme kaydı
type Payment struct {
	ID            string    `json:"id"`
	UserID        string    `json:"user_id"`
	Amount        float64   `json:"amount"`
	PaymentMethod string    `json:"payment_method"`
	Status        string    `json:"status"` // PENDING, COMPLETED, FAILED, REFUNDED
	TransactionID string    `json:"transaction_id,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	CompletedAt   time.Time `json:"completed_at,omitempty"`
}

// OverdueInfo gecikmiş borç bilgisi
type OverdueInfo struct {
	Amount float64
	Months int
}

// ConsumptionData tüketim verisi (grafik için)
type ConsumptionData struct {
	Period      string  `json:"period"` // "2026-01"
	Consumption float64 `json:"consumption"`
	Amount      float64 `json:"amount"`
	Status      string  `json:"status"` // BILLED, PENDING
}

// MeterReading sayaç okuma
type MeterReading struct {
	ID             string    `json:"id"`
	MeterID        string    `json:"meter_id"`
	ReadingDate    time.Time `json:"reading_date"`
	PreviousValue  float64   `json:"previous_value"`
	CurrentValue   float64   `json:"current_value"`
	Consumption    float64   `json:"consumption"`
	ReadingType    string    `json:"reading_type"` // MANUAL, AUTOMATIC, ESTIMATED
	PhotoEvidence  string    `json:"photo_evidence_url,omitempty"`
	ReaderUserID   string    `json:"reader_user_id,omitempty"`
}
