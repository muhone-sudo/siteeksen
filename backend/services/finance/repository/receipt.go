package repository

// Havale bildirimine dekont dosyası (migration 064, beşinci tur B9).

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

var (
	// ErrReceiptNotAllowed: dekontu yalnız ödemeyi bildiren sakin, ödeme onay beklerken ekler.
	ErrReceiptNotAllowed = errors.New("dekont yalnızca kendi onay bekleyen havale/EFT bildiriminize eklenebilir")
	// ErrReceiptLimit: ödeme başına en çok MaxReceipts dosya.
	ErrReceiptLimit = errors.New("bir ödemeye en çok 3 dekont eklenebilir")
)

// MaxReceipts, bir ödemeye eklenebilecek en çok dekont sayısıdır.
const MaxReceipts = 3

// Receipt, dekont kaydıdır.
type Receipt struct {
	ID          string    `json:"id"`
	PaymentID   string    `json:"payment_id"`
	StorageKey  string    `json:"-"`
	FileName    string    `json:"file_name"`
	ContentType string    `json:"content_type"`
	SizeBytes   int64     `json:"size_bytes"`
	SHA256      string    `json:"sha256"`
	CreatedAt   time.Time `json:"created_at"`
}

// ReceiptAllowed, çağıranın bu ödemeye dekont ekleyip ekleyemeyeceğini ve mevcut sayısını söyler.
func (r *FinanceRepository) ReceiptAllowed(ctx context.Context, propertyID, userID, paymentID string) (int, error) {
	var owner *string
	var status, method string
	var n int
	err := r.scope(propertyID).QueryRow(ctx, `SELECT p.user_id::text, p.status, p.payment_method,
		(SELECT count(*) FROM payment_receipts x WHERE x.payment_id = p.id)::int
		FROM payments p WHERE p.id = $1 AND p.property_id = $2 AND p.deleted = 0`, paymentID, propertyID).Scan(&owner, &status, &method, &n)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, ErrPaymentNotFound
	}
	if err != nil {
		return 0, err
	}
	if owner == nil || *owner != userID || status != "PENDING" || (method != "BANK_TRANSFER" && method != "CASH") {
		return n, ErrReceiptNotAllowed
	}
	if n >= MaxReceipts {
		return n, ErrReceiptLimit
	}
	return n, nil
}

// AddReceipt, dekont kaydını yazar (dosya önceden depoya konmuş olmalı).
func (r *FinanceRepository) AddReceipt(ctx context.Context, propertyID, userID string, rc *Receipt) (*Receipt, error) {
	err := r.scope(propertyID).QueryRow(ctx, `INSERT INTO payment_receipts
		(property_id, payment_id, storage_key, file_name, content_type, size_bytes, sha256, uploaded_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id::text, created_at`,
		propertyID, rc.PaymentID, rc.StorageKey, rc.FileName, rc.ContentType, rc.SizeBytes, rc.SHA256, userID).Scan(&rc.ID, &rc.CreatedAt)
	return rc, err
}

// CanViewReceipts: ödemeyi bildiren sakin ya da yönetim (isManagement) görebilir.
func (r *FinanceRepository) CanViewReceipts(ctx context.Context, propertyID, userID, paymentID string, isManagement bool) error {
	var owner *string
	err := r.scope(propertyID).QueryRow(ctx, `SELECT user_id::text FROM payments WHERE id = $1 AND property_id = $2 AND deleted = 0`,
		paymentID, propertyID).Scan(&owner)
	if errors.Is(err, pgx.ErrNoRows) {
		return ErrPaymentNotFound
	}
	if err != nil {
		return err
	}
	if !isManagement && (owner == nil || *owner != userID) {
		return ErrPaymentNotFound
	}
	return nil
}

// ListReceipts, ödemenin dekontları.
func (r *FinanceRepository) ListReceipts(ctx context.Context, propertyID, paymentID string) ([]Receipt, error) {
	rows, err := r.scope(propertyID).Query(ctx, `SELECT id::text, payment_id::text, storage_key, file_name, content_type, size_bytes, sha256, created_at
		FROM payment_receipts WHERE payment_id = $1 AND property_id = $2 ORDER BY created_at`, paymentID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Receipt{}
	for rows.Next() {
		var x Receipt
		if err := rows.Scan(&x.ID, &x.PaymentID, &x.StorageKey, &x.FileName, &x.ContentType, &x.SizeBytes, &x.SHA256, &x.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}
