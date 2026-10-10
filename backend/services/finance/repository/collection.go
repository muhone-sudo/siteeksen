package repository

// Yönetimin tahsilat girişi (migration 061, beşinci tur B2).
//
// Sakin uygulamadan bildirim yapmadan havale gönderdiğinde ya da yönetime elden ödediğinde
// yönetici tahsilatı kendisi girer. Ödeme açılır ve AYNI işlemde onaylanır (confirmPaymentTx):
// tahakkuklar düşer, tahsilat defterine yazılır. Banka ekstresinden geliyorsa satır da aynı
// işlemde CONFIRMED olur ve tutar hareketle birebir aynı olmak zorundadır.

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shopspring/decimal"
)

// CollectionInput, yönetimin girdiği tahsilattır.
type CollectionInput struct {
	UnitID        string
	AssessmentIDs []string
	Method        string // BANK_TRANSFER | CASH
	ValueDate     time.Time
	Reference     string
	// BankLineID verilirse tahsilat bu ekstre satırına bağlanır (tutar birebir aynı olmalı).
	BankLineID string
}

// BankLineRef, tahsilata bağlanacak ekstre satırının özetidir.
type BankLineRef struct {
	Status      string
	AmountKurus int64
	Date        time.Time
	Reference   string
}

// BankLineForCollection, satırın durumunu, tutarını ve gününü okur (kilitlemez; kilit
// RecordCollection işleminde alınır).
func (r *FinanceRepository) BankLineForCollection(ctx context.Context, propertyID, lineID string) (*BankLineRef, error) {
	b := &BankLineRef{}
	var ref *string
	err := r.scope(propertyID).QueryRow(ctx, `SELECT status, round(amount*100)::bigint, txn_date, reference
		FROM bank_statement_lines WHERE id = $1 AND property_id = $2`, lineID, propertyID).
		Scan(&b.Status, &b.AmountKurus, &b.Date, &ref)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrBankLineNotFound
	}
	if err != nil {
		return nil, err
	}
	if ref != nil {
		b.Reference = *ref
	}
	return b, nil
}

// RecordCollection, tahsilatı açar ve aynı işlemde onaylar; ödeme kimliğini ve tutarını
// (kuruş) döner.
func (r *FinanceRepository) RecordCollection(ctx context.Context, propertyID, managerID string, in CollectionInput) (string, int64, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var lineKurus int64
	reference := in.Reference
	if in.BankLineID != "" {
		var status string
		var txnDate time.Time
		var ref *string
		err := tx.QueryRow(ctx, `SELECT status, round(amount*100)::bigint, txn_date, reference
			FROM bank_statement_lines WHERE id = $1 AND property_id = $2 FOR UPDATE`, in.BankLineID, propertyID).
			Scan(&status, &lineKurus, &txnDate, &ref)
		if errors.Is(err, pgx.ErrNoRows) {
			return "", 0, ErrBankLineNotFound
		}
		if err != nil {
			return "", 0, err
		}
		if status != "SUGGESTED" && status != "AMBIGUOUS" && status != "UNMATCHED" {
			return "", 0, ErrBankLineResolved
		}
		reference = "Banka ekstresi " + txnDate.Format("02.01.2006")
		if ref != nil && *ref != "" {
			reference += " · " + *ref
		}
	}

	// Tahakkuklar bu bölüme ait, silinmemiş ve ödenecek tutarı olan kayıtlar olmalı.
	rows, err := tx.Query(ctx, `
		SELECT ma.id::text, (ma.total_amount - COALESCE(ma.paid_amount, 0))::text
		FROM monthly_assessments ma
		WHERE ma.id::text = ANY($1) AND ma.property_id = $2 AND ma.unit_id = $3 AND ma.deleted = 0
		ORDER BY ma.due_date, ma.id
		FOR UPDATE OF ma`, in.AssessmentIDs, propertyID, in.UnitID)
	if err != nil {
		return "", 0, err
	}
	type item struct {
		id        string
		remaining decimal.Decimal
	}
	items := []item{}
	for rows.Next() {
		var it item
		var rem string
		if err := rows.Scan(&it.id, &rem); err != nil {
			rows.Close()
			return "", 0, err
		}
		if it.remaining, err = decimal.NewFromString(rem); err != nil {
			rows.Close()
			return "", 0, err
		}
		items = append(items, it)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return "", 0, err
	}
	if len(items) != len(in.AssessmentIDs) {
		return "", 0, ErrAssessmentNotPayable
	}
	total := decimal.Zero
	for _, it := range items {
		if !it.remaining.IsPositive() {
			return "", 0, ErrAssessmentNotPayable
		}
		total = total.Add(it.remaining)
	}

	// Sakinin onay bekleyen bildirimi varsa ikinci kayıt açılmaz: borç iki kez düşerdi.
	var pending bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM payment_assessments pa JOIN payments p ON p.id = pa.payment_id
		WHERE pa.assessment_id::text = ANY($1) AND p.status = 'PENDING')`, in.AssessmentIDs).Scan(&pending); err != nil {
		return "", 0, err
	}
	if pending {
		return "", 0, ErrPaymentAlreadyPending
	}

	totalKurus := total.Mul(decimal.NewFromInt(100)).IntPart()
	if in.BankLineID != "" && totalKurus != lineKurus {
		return "", 0, fmt.Errorf("%w: hareket %s TL, seçilen borçların kalanı %s TL", ErrBankAmountMismatch,
			decimal.NewFromInt(lineKurus).Div(decimal.NewFromInt(100)).StringFixed(2), total.StringFixed(2))
	}

	paymentID := uuid.New().String()
	if _, err := tx.Exec(ctx, `
		INSERT INTO payments (id, property_id, user_id, unit_id, amount, payment_method, status, created_at,
		                      value_date, payer_reference, recorded_by)
		VALUES ($1, $2, NULL, $3, $4::numeric, $5, 'PENDING', NOW(), $6, NULLIF($7, ''), $8)`,
		paymentID, propertyID, in.UnitID, total.StringFixed(2), in.Method, in.ValueDate, reference, managerID); err != nil {
		return "", 0, err
	}
	for _, it := range items {
		if _, err := tx.Exec(ctx, `INSERT INTO payment_assessments (payment_id, assessment_id, amount) VALUES ($1, $2, $3::numeric)`,
			paymentID, it.id, it.remaining.StringFixed(2)); err != nil {
			return "", 0, err
		}
	}
	label := map[string]string{"CASH": "Yönetim tahsilatı (nakit)", "BANK_TRANSFER": "Yönetim tahsilatı (havale/EFT)"}[in.Method]
	if in.BankLineID != "" {
		label = reference
	} else if in.Reference != "" {
		label += " · " + in.Reference
	}
	if err := confirmPaymentTx(ctx, tx, paymentID, propertyID, label, managerID); err != nil {
		return "", 0, err
	}
	if in.BankLineID != "" {
		if _, err := tx.Exec(ctx, `UPDATE bank_statement_lines SET status = 'CONFIRMED', matched_payment_id = $2,
			resolved_by = NULLIF($3,'')::uuid, resolved_at = now() WHERE id = $1`, in.BankLineID, paymentID, managerID); err != nil {
			return "", 0, err
		}
	}
	return paymentID, totalKurus, tx.Commit(ctx)
}
