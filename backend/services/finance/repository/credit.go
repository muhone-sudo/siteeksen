package repository

// Alacak dekontu (migration 059, Apsiyon BUG-12): oturulmayan ay, indirim, hatalı tahakkuk
// gibi düzeltmeler sisteme gerekçeli ve numaralı belge olarak işlenir; borç anında düşer,
// tahsilat sayılmaz, tahsilat defteri zincirine yazılır. Silinemez; ters kaydı yapılabilir.

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

var (
	// ErrCreditExceeds: dekont tutarı kalan borcu ya da kalan anaparayı aşamaz.
	ErrCreditExceeds = errors.New("dekont tutarı tahakkukun kalan borcunu ve kalan anaparasını aşamaz")
	// ErrCreditNoteNotFound: dekont bulunamadı.
	ErrCreditNoteNotFound = errors.New("alacak dekontu bulunamadı")
	// ErrCreditNoteReversed: dekontun ters kaydı zaten yapılmış.
	ErrCreditNoteReversed = errors.New("dekontun ters kaydı zaten yapılmış")
	// ErrCreditReverseInvalid: ters kayıt tahakkuku ödenmiş tutarın altına indiremez.
	ErrCreditReverseInvalid = errors.New("dekont ters kaydı bu tahakkukta yapılamaz")
)

// CreditNote, alacak dekontudur.
type CreditNote struct {
	ID             string     `json:"id"`
	DocumentNo     string     `json:"document_no"`
	AssessmentID   string     `json:"assessment_id"`
	UnitID         string     `json:"unit_id"`
	Unit           string     `json:"unit"`
	Period         string     `json:"period"`
	AmountKurus    int64      `json:"amount_kurus"`
	Reason         string     `json:"reason"`
	CreatedBy      string     `json:"created_by_name,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	ReversedAt     *time.Time `json:"reversed_at,omitempty"`
	ReversalReason *string    `json:"reversal_reason,omitempty"`
}

const creditStatusSQL = `CASE
	WHEN COALESCE(paid_amount,0) >= total_amount THEN 'PAID'
	WHEN COALESCE(paid_amount,0) > 0 THEN 'PARTIAL'
	WHEN due_date < CURRENT_DATE THEN 'OVERDUE'
	ELSE 'PENDING' END`

// CreateCreditNote, dekontu keser ve tahakkukun borcunu düşürür.
func (r *FinanceRepository) CreateCreditNote(ctx context.Context, propertyID, userID, assessmentID string, amountKurus int64, reason string) (*CreditNote, error) {
	reason = strings.TrimSpace(reason)
	if amountKurus <= 0 || len([]rune(reason)) < 5 {
		return nil, fmt.Errorf("%w: tutar pozitif, gerekçe en az 5 karakter olmalı", ErrInvalidAssessmentInput)
	}
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var unitID string
	var outstanding, principalLeft int64
	err = tx.QueryRow(ctx, `
		SELECT unit_id::text,
		       round((total_amount - COALESCE(paid_amount,0)) * 100)::bigint,
		       round((base_amount - credited_amount) * 100)::bigint
		FROM monthly_assessments WHERE id = $1 AND property_id = $2 AND deleted = 0 FOR UPDATE`,
		assessmentID, propertyID).Scan(&unitID, &outstanding, &principalLeft)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrAssessmentNotFound
	}
	if err != nil {
		return nil, err
	}
	if amountKurus > outstanding || amountKurus > principalLeft {
		return nil, ErrCreditExceeds
	}
	// Belge numarası site ve yıl bazında kesintisiz: AD-2026-0001.
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('credit_note:' || $1::text, 0))`, propertyID); err != nil {
		return nil, err
	}
	year := time.Now().Year()
	var n int
	if err := tx.QueryRow(ctx, `SELECT count(*) + 1 FROM credit_notes WHERE property_id = $1 AND document_no LIKE $2`,
		propertyID, fmt.Sprintf("AD-%d-%%", year)).Scan(&n); err != nil {
		return nil, err
	}
	docNo := fmt.Sprintf("AD-%d-%04d", year, n)
	if _, err := tx.Exec(ctx, `
		UPDATE monthly_assessments
		SET credited_amount = credited_amount + $2::numeric / 100,
		    total_amount = total_amount - $2::numeric / 100,
		    updated_at = NOW()
		WHERE id = $1`, assessmentID, amountKurus); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE monthly_assessments SET status = `+creditStatusSQL+` WHERE id = $1`, assessmentID); err != nil {
		return nil, err
	}
	cn := &CreditNote{DocumentNo: docNo, AssessmentID: assessmentID, UnitID: unitID, AmountKurus: amountKurus, Reason: reason}
	if err := tx.QueryRow(ctx, `
		INSERT INTO credit_notes (property_id, document_no, assessment_id, unit_id, amount, reason, created_by)
		VALUES ($1, $2, $3, $4, $5::numeric / 100, $6, NULLIF($7,'')::uuid) RETURNING id, created_at`,
		propertyID, docNo, assessmentID, unitID, amountKurus, reason, userID).Scan(&cn.ID, &cn.CreatedAt); err != nil {
		return nil, err
	}
	if err := appendLedger(ctx, tx, propertyID, "CREDIT_NOTE", nil, amountKurus, map[string]any{
		"credit_note_id": cn.ID, "document_no": docNo, "assessment_id": assessmentID, "unit_id": unitID, "reason": reason,
	}, userID); err != nil {
		return nil, err
	}
	return cn, tx.Commit(ctx)
}

// ReverseCreditNote, dekontun gerekçeli ters kaydını yapar: borç geri yüklenir, dekont silinmez.
func (r *FinanceRepository) ReverseCreditNote(ctx context.Context, propertyID, userID, id, reason string) error {
	reason = strings.TrimSpace(reason)
	if len([]rune(reason)) < 5 {
		return fmt.Errorf("%w: gerekçe en az 5 karakter olmalı", ErrInvalidAssessmentInput)
	}
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var assessmentID, docNo string
	var amountKurus int64
	var reversed *time.Time
	err = tx.QueryRow(ctx, `SELECT assessment_id::text, document_no, round(amount * 100)::bigint, reversed_at
		FROM credit_notes WHERE id = $1 AND property_id = $2 FOR UPDATE`, id, propertyID).Scan(&assessmentID, &docNo, &amountKurus, &reversed)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrCreditNoteNotFound
	}
	if err != nil {
		return err
	}
	if reversed != nil {
		return ErrCreditNoteReversed
	}
	tag, err := tx.Exec(ctx, `
		UPDATE monthly_assessments
		SET credited_amount = credited_amount - $2::numeric / 100,
		    total_amount = total_amount + $2::numeric / 100,
		    updated_at = NOW()
		WHERE id = $1 AND credited_amount >= $2::numeric / 100`, assessmentID, amountKurus)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrCreditReverseInvalid
	}
	if _, err := tx.Exec(ctx, `UPDATE monthly_assessments SET status = `+creditStatusSQL+` WHERE id = $1`, assessmentID); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `UPDATE credit_notes SET reversed_at = NOW(), reversed_by = NULLIF($2,'')::uuid, reversal_reason = $3
		WHERE id = $1`, id, userID, reason); err != nil {
		return err
	}
	if err := appendLedger(ctx, tx, propertyID, "CREDIT_NOTE_REVERSED", nil, -amountKurus, map[string]any{
		"credit_note_id": id, "document_no": docNo, "assessment_id": assessmentID, "reason": reason,
	}, userID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ListCreditNotes, dekontları verir; residentID doluysa yalnızca o kişinin aktif dairelerinin dekontları.
func (r *FinanceRepository) ListCreditNotes(ctx context.Context, propertyID, residentID string) ([]CreditNote, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT c.id, c.document_no, c.assessment_id::text, c.unit_id::text, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       CASE WHEN ma.kind = 'OPENING' THEN 'Devir bakiyesi' ELSE to_char(make_date(ma.period_year, ma.period_month, 1), 'YYYY-MM') END,
		       round(c.amount * 100)::bigint, c.reason, COALESCE(us.first_name || ' ' || us.last_name, ''), c.created_at,
		       c.reversed_at, c.reversal_reason
		FROM credit_notes c
		JOIN units u ON u.id = c.unit_id
		JOIN monthly_assessments ma ON ma.id = c.assessment_id
		LEFT JOIN users us ON us.id = c.created_by
		WHERE c.property_id = $1
		  AND ($2 = '' OR EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = c.unit_id AND ru.is_active AND ru.resident_id = NULLIF($2,'')::uuid))
		ORDER BY c.created_at DESC LIMIT 500`, propertyID, residentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []CreditNote{}
	for rows.Next() {
		var c CreditNote
		if err := rows.Scan(&c.ID, &c.DocumentNo, &c.AssessmentID, &c.UnitID, &c.Unit, &c.Period, &c.AmountKurus, &c.Reason,
			&c.CreatedBy, &c.CreatedAt, &c.ReversedAt, &c.ReversalReason); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// OpenAssessment, dekont kesilebilecek açık tahakkuktur.
type OpenAssessment struct {
	ID               string    `json:"id"`
	Period           string    `json:"period"`
	DueDate          time.Time `json:"due_date"`
	TotalKurus       int64     `json:"total_kurus"`
	PaidKurus        int64     `json:"paid_kurus"`
	CreditedKurus    int64     `json:"credited_kurus"`
	OutstandingKurus int64     `json:"outstanding_kurus"`
	// MaxCreditKurus: kalan borç ile kalan anaparanın küçüğü.
	MaxCreditKurus int64 `json:"max_credit_kurus"`
}

// OpenAssessmentsForUnit, bölümün borcu kalan tahakkuklarını verir (yönetim).
func (r *FinanceRepository) OpenAssessmentsForUnit(ctx context.Context, propertyID, unitID string) ([]OpenAssessment, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, CASE WHEN kind = 'OPENING' THEN 'Devir bakiyesi' ELSE to_char(make_date(period_year, period_month, 1), 'YYYY-MM') END,
		       due_date, round(total_amount*100)::bigint, round(COALESCE(paid_amount,0)*100)::bigint, round(credited_amount*100)::bigint,
		       round((total_amount - COALESCE(paid_amount,0))*100)::bigint,
		       LEAST(round((total_amount - COALESCE(paid_amount,0))*100), round((base_amount - credited_amount)*100))::bigint
		FROM monthly_assessments
		WHERE property_id = $1 AND unit_id = $2 AND deleted = 0 AND total_amount > COALESCE(paid_amount,0)
		ORDER BY due_date`, propertyID, unitID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []OpenAssessment{}
	for rows.Next() {
		var a OpenAssessment
		if err := rows.Scan(&a.ID, &a.Period, &a.DueDate, &a.TotalKurus, &a.PaidKurus, &a.CreditedKurus, &a.OutstandingKurus, &a.MaxCreditKurus); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// GetCreditNote, tek dekontu verir (residentID doluysa erişim denetimiyle).
func (r *FinanceRepository) GetCreditNote(ctx context.Context, propertyID, residentID, id string) (*CreditNote, error) {
	list, err := r.ListCreditNotes(ctx, propertyID, residentID)
	if err != nil {
		return nil, err
	}
	for i := range list {
		if list[i].ID == id {
			return &list[i], nil
		}
	}
	return nil, ErrCreditNoteNotFound
}
