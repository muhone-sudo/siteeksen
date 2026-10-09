package repository

// Tahsilat defteri zinciri ve ödeme ters kaydı (migration 054, Apsiyon BUG-03).

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/shopspring/decimal"
)

// ErrPaymentNotCompleted, yalnızca tamamlanmış ödemenin ters kaydı yapılabilir.
var ErrPaymentNotCompleted = errors.New("yalnızca tamamlanmış ödemenin ters kaydı yapılabilir")

// LedgerEntry, tahsilat defteri kaydıdır.
type LedgerEntry struct {
	Seq         int64           `json:"seq"`
	EntryType   string          `json:"entry_type"`
	PaymentID   *string         `json:"payment_id,omitempty"`
	AmountKurus int64           `json:"amount_kurus"`
	Detail      json.RawMessage `json:"detail"`
	CreatedBy   string          `json:"created_by_name,omitempty"`
	CreatedAt   time.Time       `json:"created_at"`
	EntryHash   string          `json:"entry_hash"`
}

// LedgerVerification, zincir doğrulama sonucudur.
type LedgerVerification struct {
	Valid        bool   `json:"valid"`
	Entries      int    `json:"entries"`
	FirstInvalid *int64 `json:"first_invalid_seq,omitempty"`
	Reason       string `json:"reason,omitempty"`
	HeadHash     string `json:"head_hash,omitempty"`
}

// appendLedger, kaydı zincire ekler. Site başına danışma kilidiyle sıraya girer (aynı sıra
// numarası iki kez verilmez); özet veritabanı fonksiyonuyla hesaplanır.
func appendLedger(ctx context.Context, tx pgx.Tx, propertyID, entryType string, paymentID *string,
	amountKurus int64, detail map[string]any, userID string) error {
	raw, err := json.Marshal(detail)
	if err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended('finance_ledger:' || $1::text, 0))`, propertyID); err != nil {
		return err
	}
	_, err = tx.Exec(ctx, `
		WITH last AS (SELECT seq, entry_hash FROM finance_ledger WHERE property_id = $1::uuid ORDER BY seq DESC LIMIT 1),
		     v AS (SELECT COALESCE((SELECT seq FROM last), 0) + 1 AS seq, (SELECT entry_hash FROM last) AS prev,
		                  date_trunc('microseconds', clock_timestamp()) AS ts)
		INSERT INTO finance_ledger (property_id, seq, entry_type, payment_id, amount_kurus, detail, created_by,
		                            created_at, prev_hash, entry_hash)
		SELECT $1::uuid, v.seq, $2::text, $3::uuid, $4::bigint, $5::jsonb, NULLIF($6::text, '')::uuid, v.ts, v.prev,
		       finance_ledger_hash(v.prev, $1::uuid, v.seq, $2::text, $3::uuid, $4::bigint, $5::jsonb, v.ts)
		FROM v`, propertyID, entryType, paymentID, amountKurus, string(raw), userID)
	return err
}

// ReversePayment, tamamlanmış ödemenin ters kaydını yapar: tahakkukların ödenen tutarı
// geri alınır, ödeme REVERSED olur (silinmez), zincire gerekçeli kayıt düşer.
func (r *FinanceRepository) ReversePayment(ctx context.Context, paymentID, propertyID, userID, reason string) error {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status, amount string
	err = tx.QueryRow(ctx, `SELECT status, amount::text FROM payments WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		paymentID, propertyID).Scan(&status, &amount)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrPaymentNotFound
	}
	if err != nil {
		return err
	}
	if status != "COMPLETED" {
		return ErrPaymentNotCompleted
	}
	// Ödenen tutarın azaltılmasına yalnızca bu işlemde izin verilir (054 tetikleyicisi).
	if _, err := tx.Exec(ctx, `SELECT set_config('siteeksen.reversal', 'on', true)`); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE monthly_assessments ma
		SET paid_amount = GREATEST(COALESCE(ma.paid_amount, 0) - pa.amount, 0),
		    status = CASE
		        WHEN COALESCE(ma.paid_amount, 0) - pa.amount >= ma.total_amount THEN 'PAID'
		        WHEN COALESCE(ma.paid_amount, 0) - pa.amount > 0 THEN 'PARTIAL'
		        WHEN ma.due_date < CURRENT_DATE THEN 'OVERDUE'
		        ELSE 'PENDING'
		    END,
		    updated_at = NOW()
		FROM payment_assessments pa
		WHERE pa.payment_id = $1 AND ma.id = pa.assessment_id AND ma.property_id = $2`, paymentID, propertyID); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		UPDATE payments SET status = 'REVERSED', reversed_at = NOW(), reversed_by = NULLIF($2, '')::uuid, reversal_reason = $3
		WHERE id = $1`, paymentID, userID, reason); err != nil {
		return err
	}
	d, _ := decimal.NewFromString(amount)
	if err := appendLedger(ctx, tx, propertyID, "PAYMENT_REVERSED", &paymentID, -d.Mul(decimal.NewFromInt(100)).IntPart(),
		map[string]any{"reason": reason}, userID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ListLedger, sitenin tahsilat defterini (son 500 kayıt) getirir.
func (r *FinanceRepository) ListLedger(ctx context.Context, propertyID string) ([]LedgerEntry, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT l.seq, l.entry_type, l.payment_id::text, l.amount_kurus, l.detail::text,
		       COALESCE(u.first_name || ' ' || u.last_name, ''), l.created_at, l.entry_hash
		FROM finance_ledger l LEFT JOIN users u ON u.id = l.created_by
		WHERE l.property_id = $1 ORDER BY l.seq DESC LIMIT 500`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []LedgerEntry{}
	for rows.Next() {
		var e LedgerEntry
		var detail string
		if err := rows.Scan(&e.Seq, &e.EntryType, &e.PaymentID, &e.AmountKurus, &detail, &e.CreatedBy, &e.CreatedAt, &e.EntryHash); err != nil {
			return nil, err
		}
		e.Detail = json.RawMessage(detail)
		out = append(out, e)
	}
	return out, rows.Err()
}

// VerifyLedger, zinciri baştan doğrular: sıra kesintisiz, her kaydın önceki özeti bir
// öncekinin özetine eşit ve her özet içerikten yeniden hesaplananla aynı olmalı.
func (r *FinanceRepository) VerifyLedger(ctx context.Context, propertyID string) (*LedgerVerification, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT seq, COALESCE(prev_hash, ''), entry_hash, COALESCE(lag(entry_hash) OVER (ORDER BY seq), ''),
		       finance_ledger_hash(prev_hash, property_id, seq, entry_type, payment_id, amount_kurus, detail, created_at)
		FROM finance_ledger WHERE property_id = $1 ORDER BY seq`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	v := &LedgerVerification{Valid: true}
	var expect int64 = 1
	for rows.Next() {
		var seq int64
		var prev, hash, lagHash, recomputed string
		if err := rows.Scan(&seq, &prev, &hash, &lagHash, &recomputed); err != nil {
			return nil, err
		}
		v.Entries++
		v.HeadHash = hash
		if !v.Valid {
			continue
		}
		bad := func(why string) {
			s := seq
			v.Valid, v.FirstInvalid, v.Reason = false, &s, why
		}
		switch {
		case seq != expect:
			bad("sıra numarası kesintili (kayıt silinmiş olabilir)")
		case prev != lagHash:
			bad("önceki kayıt özeti tutmuyor (zincir kopuk)")
		case hash != recomputed:
			bad("kaydın içeriği özetiyle uyuşmuyor (kayıt değiştirilmiş)")
		}
		expect = seq + 1
	}
	return v, rows.Err()
}
