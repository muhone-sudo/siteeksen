package service

import (
	"context"
	"time"

	"github.com/siteeksen/backend/services/finance/models"
	"github.com/siteeksen/backend/services/finance/repository"
)

// FinanceService finans servisi
type FinanceService struct {
	repo *repository.FinanceRepository
}

// NewFinanceService yeni servis oluşturur
func NewFinanceService(repo *repository.FinanceRepository) *FinanceService {
	return &FinanceService{repo: repo}
}

// DebtStatusResponse borç durumu yanıtı
type DebtStatusResponse struct {
	HasDebt       bool      `json:"has_debt"`
	CurrentBalance float64   `json:"current_balance"`
	OverdueAmount  float64   `json:"overdue_amount"`
	OverdueMonths  int       `json:"overdue_months"`
	NextDueDate    time.Time `json:"next_due_date"`
	NextDueAmount  float64   `json:"next_due_amount"`
}

// GetDebtStatus anlık borç durumu hesaplar
func (s *FinanceService) GetDebtStatus(ctx context.Context, userID, propertyID string) (*DebtStatusResponse, error) {
	balance, err := s.repo.GetUnitBalance(ctx, userID)
	if err != nil {
		return nil, err
	}

	overdueInfo, err := s.repo.GetOverdueInfo(ctx, userID)
	if err != nil {
		return nil, err
	}

	nextDue, err := s.repo.GetNextDueAssessment(ctx, userID)
	if err != nil {
		// Gelecek ay için tahakkuk yoksa sıfır döndür
		nextDue = &models.Assessment{}
	}

	return &DebtStatusResponse{
		HasDebt:        balance > 0,
		CurrentBalance: balance,
		OverdueAmount:  overdueInfo.Amount,
		OverdueMonths:  overdueInfo.Months,
		NextDueDate:    nextDue.DueDate,
		NextDueAmount:  nextDue.TotalAmount,
	}, nil
}

// GetAssessments aidat listesi getirir
func (s *FinanceService) GetAssessments(ctx context.Context, userID string, year int) ([]models.AssessmentSummary, error) {
	if year == 0 {
		year = time.Now().Year()
	}
	return s.repo.GetAssessments(ctx, userID, year)
}

// GetAssessmentDetails aidat detayı getirir
func (s *FinanceService) GetAssessmentDetails(ctx context.Context, assessmentID string) (*models.AssessmentDetail, error) {
	return s.repo.GetAssessmentDetails(ctx, assessmentID)
}

// PaymentResult ödeme sonucu
type PaymentResult struct {
	PaymentID   string `json:"payment_id"`
	CheckoutURL string `json:"checkout_url,omitempty"`
	Status      string `json:"status"`
}

// CreatePayment ödeme başlatır
func (s *FinanceService) CreatePayment(ctx context.Context, userID string, assessmentIDs []string, method, cardToken string) (*PaymentResult, error) {
	// Toplam tutar hesapla
	totalAmount, err := s.repo.CalculateTotalAmount(ctx, assessmentIDs)
	if err != nil {
		return nil, err
	}

	// Ödeme kaydı oluştur
	paymentID, err := s.repo.CreatePayment(ctx, userID, assessmentIDs, totalAmount, method)
	if err != nil {
		return nil, err
	}

	// TODO: Ödeme gateway entegrasyonu (iyzico, Param vb.)
	// Şimdilik mock checkout URL döndür
	checkoutURL := ""
	if method == "CREDIT_CARD" {
		checkoutURL = "https://checkout.siteeksen.com/pay/" + paymentID
	}

	return &PaymentResult{
		PaymentID:   paymentID,
		CheckoutURL: checkoutURL,
		Status:      "PENDING",
	}, nil
}

// GetPaymentHistory ödeme geçmişi getirir
func (s *FinanceService) GetPaymentHistory(ctx context.Context, userID string) ([]models.Payment, error) {
	return s.repo.GetPaymentHistory(ctx, userID)
}

// ConsumptionSummary tüketim özeti
type ConsumptionSummary struct {
	MeterType string                   `json:"meter_type"`
	Unit      string                   `json:"unit"`
	Data      []models.ConsumptionData `json:"data"`
}

// GetConsumptionSummary tüketim özeti getirir
func (s *FinanceService) GetConsumptionSummary(ctx context.Context, userID, meterType string) (*ConsumptionSummary, error) {
	data, err := s.repo.GetConsumptionData(ctx, userID, meterType, 6)
	if err != nil {
		return nil, err
	}

	unit := "kWh"
	if meterType == "WATER_COLD" || meterType == "WATER_HOT" {
		unit = "m³"
	}

	return &ConsumptionSummary{
		MeterType: meterType,
		Unit:      unit,
		Data:      data,
	}, nil
}
