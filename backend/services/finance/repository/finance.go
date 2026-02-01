package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/finance/models"
)

// FinanceRepository finans veritabanı işlemleri
type FinanceRepository struct {
	pool *pgxpool.Pool
}

// NewFinanceRepository yeni repository oluşturur
func NewFinanceRepository(pool *pgxpool.Pool) *FinanceRepository {
	return &FinanceRepository{pool: pool}
}

// GetUnitBalance daire bakiyesini hesaplar
func (r *FinanceRepository) GetUnitBalance(ctx context.Context, userID string) (float64, error) {
	query := `
		SELECT COALESCE(SUM(ll.debit_amount) - SUM(ll.credit_amount), 0) as balance
		FROM ledger_lines ll
		JOIN users u ON ll.unit_id = (
			SELECT ru.unit_id FROM resident_units ru 
			WHERE ru.resident_id = $1 AND ru.is_active = true 
			LIMIT 1
		)
	`
	var balance float64
	err := r.pool.QueryRow(ctx, query, userID).Scan(&balance)
	return balance, err
}

// GetOverdueInfo gecikmiş borç bilgisi
func (r *FinanceRepository) GetOverdueInfo(ctx context.Context, userID string) (*models.OverdueInfo, error) {
	query := `
		SELECT COALESCE(SUM(total_amount - paid_amount), 0), COUNT(*)
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.due_date < CURRENT_DATE
		  AND ma.status != 'PAID'
	`
	info := &models.OverdueInfo{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(&info.Amount, &info.Months)
	return info, err
}

// GetNextDueAssessment sonraki vadeli aidat
func (r *FinanceRepository) GetNextDueAssessment(ctx context.Context, userID string) (*models.Assessment, error) {
	query := `
		SELECT ma.id, ma.total_amount, ma.due_date
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.due_date >= CURRENT_DATE
		  AND ma.status != 'PAID'
		ORDER BY ma.due_date ASC
		LIMIT 1
	`
	a := &models.Assessment{}
	err := r.pool.QueryRow(ctx, query, userID).Scan(&a.ID, &a.TotalAmount, &a.DueDate)
	return a, err
}

// GetAssessments yıllık aidat listesi
func (r *FinanceRepository) GetAssessments(ctx context.Context, userID string, year int) ([]models.AssessmentSummary, error) {
	query := `
		SELECT ma.id, 
			   TO_CHAR(MAKE_DATE(ma.period_year, ma.period_month, 1), 'YYYY-MM'),
			   ma.base_amount, ma.late_fee, ma.total_amount, 
			   COALESCE(ma.paid_amount, 0), ma.status
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.period_year = $2
		ORDER BY ma.period_month DESC
	`
	rows, err := r.pool.Query(ctx, query, userID, year)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var assessments []models.AssessmentSummary
	for rows.Next() {
		var a models.AssessmentSummary
		if err := rows.Scan(&a.ID, &a.Period, &a.BaseAmount, &a.LateFee, &a.TotalAmount, &a.PaidAmount, &a.Status); err != nil {
			return nil, err
		}
		assessments = append(assessments, a)
	}
	return assessments, nil
}

// GetAssessmentDetails aidat detayı
func (r *FinanceRepository) GetAssessmentDetails(ctx context.Context, assessmentID string) (*models.AssessmentDetail, error) {
	// Ana aidat bilgisi
	query := `
		SELECT id, property_id, unit_id, period_year, period_month, 
			   base_amount, late_fee, total_amount, due_date, status, created_at
		FROM monthly_assessments WHERE id = $1
	`
	detail := &models.AssessmentDetail{}
	err := r.pool.QueryRow(ctx, query, assessmentID).Scan(
		&detail.ID, &detail.PropertyID, &detail.UnitID, &detail.PeriodYear, &detail.PeriodMonth,
		&detail.BaseAmount, &detail.LateFee, &detail.TotalAmount, &detail.DueDate, &detail.Status, &detail.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Detay kalemleri
	detailQuery := `
		SELECT ec.name, ad.amount, ad.calculation_basis
		FROM assessment_details ad
		JOIN expense_categories ec ON ad.expense_category_id = ec.id
		WHERE ad.assessment_id = $1
	`
	rows, err := r.pool.Query(ctx, detailQuery, assessmentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var item models.AssessmentDetailItem
		if err := rows.Scan(&item.Category, &item.Amount, &item.CalculationBasis); err != nil {
			return nil, err
		}
		detail.Details = append(detail.Details, item)
	}

	return detail, nil
}

// CalculateTotalAmount seçili aidatların toplam tutarı
func (r *FinanceRepository) CalculateTotalAmount(ctx context.Context, assessmentIDs []string) (float64, error) {
	query := `
		SELECT COALESCE(SUM(total_amount - COALESCE(paid_amount, 0)), 0)
		FROM monthly_assessments
		WHERE id = ANY($1)
	`
	var total float64
	err := r.pool.QueryRow(ctx, query, assessmentIDs).Scan(&total)
	return total, err
}

// CreatePayment ödeme kaydı oluşturur
func (r *FinanceRepository) CreatePayment(ctx context.Context, userID string, assessmentIDs []string, amount float64, method string) (string, error) {
	paymentID := uuid.New().String()
	query := `
		INSERT INTO payments (id, user_id, amount, payment_method, status, created_at)
		VALUES ($1, $2, $3, $4, 'PENDING', NOW())
	`
	_, err := r.pool.Exec(ctx, query, paymentID, userID, amount, method)
	if err != nil {
		return "", err
	}

	// Ödeme-aidat ilişkisini kaydet
	for _, aID := range assessmentIDs {
		linkQuery := `INSERT INTO payment_assessments (payment_id, assessment_id) VALUES ($1, $2)`
		r.pool.Exec(ctx, linkQuery, paymentID, aID)
	}

	return paymentID, nil
}

// GetPaymentHistory ödeme geçmişi
func (r *FinanceRepository) GetPaymentHistory(ctx context.Context, userID string) ([]models.Payment, error) {
	query := `
		SELECT id, user_id, amount, payment_method, status, transaction_id, created_at, completed_at
		FROM payments
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 50
	`
	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var payments []models.Payment
	for rows.Next() {
		var p models.Payment
		var txID, completedAt interface{}
		if err := rows.Scan(&p.ID, &p.UserID, &p.Amount, &p.PaymentMethod, &p.Status, &txID, &p.CreatedAt, &completedAt); err != nil {
			return nil, err
		}
		if txID != nil {
			p.TransactionID = txID.(string)
		}
		if completedAt != nil {
			p.CompletedAt = completedAt.(time.Time)
		}
		payments = append(payments, p)
	}
	return payments, nil
}

// GetConsumptionData tüketim verisi (grafik için)
func (r *FinanceRepository) GetConsumptionData(ctx context.Context, userID, meterType string, months int) ([]models.ConsumptionData, error) {
	query := `
		SELECT TO_CHAR(ci.period_start, 'YYYY-MM'), ci.consumption_amount, ci.total_amount, ci.status
		FROM consumption_invoices ci
		JOIN meters m ON ci.meter_id = m.id
		JOIN resident_units ru ON m.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND m.meter_type = $2
		ORDER BY ci.period_start DESC
		LIMIT $3
	`
	rows, err := r.pool.Query(ctx, query, userID, meterType, months)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var data []models.ConsumptionData
	for rows.Next() {
		var d models.ConsumptionData
		if err := rows.Scan(&d.Period, &d.Consumption, &d.Amount, &d.Status); err != nil {
			return nil, err
		}
		data = append(data, d)
	}

	// Ters çevir (eskiden yeniye)
	for i, j := 0, len(data)-1; i < j; i, j = i+1, j-1 {
		data[i], data[j] = data[j], data[i]
	}

	return data, nil
}
