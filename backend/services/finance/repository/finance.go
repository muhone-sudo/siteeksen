package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/finance/models"
)

// Sentinel hatalar
var (
	ErrExpenseCategoryNotFound = errors.New("gider kalemi bulunamadı")
	ErrAssessmentPeriodExists  = errors.New("bu dönem için tahakkuk zaten oluşturulmuş")
	ErrNoUnitsInProperty       = errors.New("sitede tanımlı birim bulunamadı")
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
		  AND ma.deleted = 0
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
		  AND ma.deleted = 0
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
		  AND ma.deleted = 0
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
		FROM monthly_assessments WHERE id = $1 AND deleted = 0
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

// ListDebtors sitede borcu olan birimlerin sahiplerini borç tutarına göre listeler (yönetim görünümü)
func (r *FinanceRepository) ListDebtors(ctx context.Context, propertyID string) ([]models.Debtor, error) {
	query := `
		SELECT u.id, u.first_name, u.last_name,
		       COALESCE(un.block, '') || ' Blok D.' || un.door_number AS unit,
		       SUM(ma.total_amount - ma.paid_amount) AS amount
		FROM monthly_assessments ma
		JOIN units un ON un.id = ma.unit_id
		JOIN resident_units ru ON ru.unit_id = un.id AND ru.is_active = true AND ru.role = 'OWNER'
		JOIN users u ON u.id = ru.resident_id
		WHERE ma.property_id = $1 AND ma.deleted = 0 AND ma.total_amount > ma.paid_amount
		GROUP BY u.id, u.first_name, u.last_name, un.block, un.door_number
		ORDER BY amount DESC
	`
	rows, err := r.pool.Query(ctx, query, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	debtors := []models.Debtor{}
	for rows.Next() {
		var d models.Debtor
		var firstName, lastName string
		if err := rows.Scan(&d.ResidentID, &firstName, &lastName, &d.Unit, &d.Amount); err != nil {
			return nil, err
		}
		d.Name = firstName + " " + lastName
		debtors = append(debtors, d)
	}
	return debtors, nil
}

// ListPropertyPayments sitedeki tüm sakinlerin ödeme kayıtlarını listeler (yönetim görünümü)
func (r *FinanceRepository) ListPropertyPayments(ctx context.Context, propertyID string) ([]models.PropertyPayment, error) {
	query := `
		SELECT p.id, p.user_id, p.amount, p.payment_method, p.status, COALESCE(p.transaction_id, ''),
		       p.created_at, p.completed_at,
		       u.first_name, u.last_name,
		       COALESCE(COALESCE(un.block, '') || ' Blok D.' || un.door_number, '')
		FROM payments p
		JOIN users u ON u.id = p.user_id
		LEFT JOIN units un ON un.id = (
			SELECT ru.unit_id FROM resident_units ru
			WHERE ru.resident_id = u.id AND ru.is_active = true
			LIMIT 1
		)
		WHERE p.deleted = 0 AND EXISTS (
			SELECT 1 FROM resident_units ru2
			JOIN units un2 ON un2.id = ru2.unit_id
			WHERE ru2.resident_id = u.id AND ru2.is_active = true AND un2.property_id = $1
		)
		ORDER BY p.created_at DESC
		LIMIT 50
	`
	rows, err := r.pool.Query(ctx, query, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	payments := []models.PropertyPayment{}
	for rows.Next() {
		var pp models.PropertyPayment
		var firstName, lastName string
		var txID, completedAt interface{}
		if err := rows.Scan(&pp.ID, &pp.UserID, &pp.Amount, &pp.PaymentMethod, &pp.Status, &txID,
			&pp.CreatedAt, &completedAt, &firstName, &lastName, &pp.Unit); err != nil {
			return nil, err
		}
		if txID != nil {
			pp.TransactionID = txID.(string)
		}
		if completedAt != nil {
			pp.CompletedAt = completedAt.(time.Time)
		}
		pp.Name = firstName + " " + lastName
		payments = append(payments, pp)
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

// unitShare tahakkuk dağıtım hesabı için birim bilgisi
type unitShare struct {
	id             string
	shareRatio     float64
	grossAreaM2    float64
	isCommercial   bool
	isGroundFloor  bool
}

// assessmentDetailRow birime düşen gider kalemi payı
type assessmentDetailRow struct {
	unitID           string
	categoryID       string
	amount           float64
	calculationBasis string
	shareValue       float64
}

// CreateAssessment dönem için site genelinde aidat tahakkuku oluşturur.
// Her gider kalemini, kategorinin dağıtım yöntemine (SHARE_RATIO/EQUAL/AREA_M2)
// göre uygun birimlere paylaştırır ve her birim için tek bir monthly_assessments
// kaydı + ilgili assessment_details satırlarını tek transaction'da yazar.
func (r *FinanceRepository) CreateAssessment(ctx context.Context, propertyID string, input models.CreateAssessmentInput) ([]models.AssessmentSummary, error) {
	dueDate, err := time.Parse("2006-01-02", input.DueDate)
	if err != nil {
		return nil, errors.New("geçersiz vade tarihi formatı (YYYY-MM-DD bekleniyor)")
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
		SELECT id, share_ratio, COALESCE(gross_area_m2, 0), is_commercial, is_ground_floor
		FROM units WHERE property_id = $1 AND deleted = 0
	`, propertyID)
	if err != nil {
		return nil, err
	}
	var units []unitShare
	for rows.Next() {
		var u unitShare
		if err := rows.Scan(&u.id, &u.shareRatio, &u.grossAreaM2, &u.isCommercial, &u.isGroundFloor); err != nil {
			rows.Close()
			return nil, err
		}
		units = append(units, u)
	}
	rows.Close()
	if len(units) == 0 {
		return nil, ErrNoUnitsInProperty
	}

	unitTotals := make(map[string]float64, len(units))
	var details []assessmentDetailRow

	for _, item := range input.ExpenseItems {
		var distType string
		var appliesCommercial, appliesGround bool
		err := tx.QueryRow(ctx, `
			SELECT distribution_type, applies_to_commercial, applies_to_ground_floor
			FROM expense_categories WHERE id = $1 AND property_id = $2 AND is_active = true
		`, item.CategoryID, propertyID).Scan(&distType, &appliesCommercial, &appliesGround)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrExpenseCategoryNotFound
		}
		if err != nil {
			return nil, err
		}

		eligible := make([]unitShare, 0, len(units))
		for _, u := range units {
			if u.isCommercial && !appliesCommercial {
				continue
			}
			if u.isGroundFloor && !appliesGround {
				continue
			}
			eligible = append(eligible, u)
		}
		if len(eligible) == 0 {
			continue
		}

		switch distType {
		case "EQUAL":
			share := item.Amount / float64(len(eligible))
			basisValue := 1.0 / float64(len(eligible))
			for _, u := range eligible {
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "EQUAL", basisValue})
			}
		case "AREA_M2":
			var totalArea float64
			for _, u := range eligible {
				totalArea += u.grossAreaM2
			}
			if totalArea == 0 {
				return nil, fmt.Errorf("'%s' kalemi metrekareye göre dağıtılamıyor: birimlerde alan bilgisi yok", item.CategoryID)
			}
			for _, u := range eligible {
				ratio := u.grossAreaM2 / totalArea
				share := item.Amount * ratio
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "AREA_M2", ratio})
			}
		default: // SHARE_RATIO ve henüz desteklenmeyen yöntemler (METER_READING/CUSTOM) arsa payına göre paylaştırılır
			var totalRatio float64
			for _, u := range eligible {
				totalRatio += u.shareRatio
			}
			if totalRatio == 0 {
				return nil, fmt.Errorf("'%s' kalemi arsa payına göre dağıtılamıyor: birimlerde arsa payı bilgisi yok", item.CategoryID)
			}
			for _, u := range eligible {
				ratio := u.shareRatio / totalRatio
				share := item.Amount * ratio
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "SHARE_RATIO", ratio})
			}
		}
	}

	period := fmt.Sprintf("%04d-%02d", input.PeriodYear, input.PeriodMonth)
	assessmentIDs := make(map[string]string, len(unitTotals))
	for unitID, total := range unitTotals {
		id := uuid.New().String()
		_, err := tx.Exec(ctx, `
			INSERT INTO monthly_assessments (id, property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
			VALUES ($1, $2, $3, $4, $5, $6, $6, $7, 'PENDING')
		`, id, propertyID, unitID, input.PeriodYear, input.PeriodMonth, total, dueDate)
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" {
				return nil, ErrAssessmentPeriodExists
			}
			return nil, err
		}
		assessmentIDs[unitID] = id
	}

	for _, d := range details {
		_, err := tx.Exec(ctx, `
			INSERT INTO assessment_details (id, assessment_id, expense_category_id, amount, calculation_basis, share_value)
			VALUES ($1, $2, $3, $4, $5, $6)
		`, uuid.New().String(), assessmentIDs[d.unitID], d.categoryID, d.amount, d.calculationBasis, d.shareValue)
		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	summaries := make([]models.AssessmentSummary, 0, len(assessmentIDs))
	for unitID, id := range assessmentIDs {
		summaries = append(summaries, models.AssessmentSummary{
			ID:          id,
			Period:      period,
			BaseAmount:  unitTotals[unitID],
			TotalAmount: unitTotals[unitID],
			Status:      "PENDING",
		})
	}
	return summaries, nil
}

// ListExpenseCategories sitenin gider kalemlerini sıralı şekilde listeler
func (r *FinanceRepository) ListExpenseCategories(ctx context.Context, propertyID string) ([]models.ExpenseCategory, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, property_id, name, distribution_type, applies_to_commercial, applies_to_ground_floor,
		       COALESCE(custom_formula::text, ''), is_active
		FROM expense_categories
		WHERE property_id = $1 AND is_active = true
		ORDER BY sort_order, name
	`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var categories []models.ExpenseCategory
	for rows.Next() {
		var ec models.ExpenseCategory
		if err := rows.Scan(&ec.ID, &ec.PropertyID, &ec.Name, &ec.DistributionType,
			&ec.AppliesToCommercial, &ec.AppliesToGroundFloor, &ec.CustomFormula, &ec.IsActive); err != nil {
			return nil, err
		}
		categories = append(categories, ec)
	}
	return categories, nil
}
