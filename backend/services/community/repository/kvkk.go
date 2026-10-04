package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// KVKK başvuru hataları.
var (
	ErrKVKKNotFound  = errors.New("başvuru bulunamadı")
	ErrKVKKNotOpen   = errors.New("başvuru zaten sonuçlandırılmış")
	ErrKVKKInvalid   = errors.New("başvuru bilgisi geçersiz")
	KVKKRequestTypes = []string{"INFO", "CORRECTION", "ERASURE", "OBJECTION", "COMPENSATION", "OTHER"}
	KVKKResultStatus = []string{"ANSWERED", "REJECTED"}
)

// KVKKRequest, ilgili kişi başvurusudur (KVKK m.11, migration 035).
type KVKKRequest struct {
	ID            string     `json:"id"`
	UserID        string     `json:"user_id"`
	ApplicantName string     `json:"applicant_name"`
	RequestType   string     `json:"request_type"`
	Description   string     `json:"description"`
	Status        string     `json:"status"`
	DueDate       time.Time  `json:"due_date"`
	DaysLeft      int        `json:"days_left"` // eksi: süre geçti
	Response      string     `json:"response,omitempty"`
	RespondedAt   *time.Time `json:"responded_at,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

// KVKKRepository başvuru deposu.
type KVKKRepository struct{ pool *pgxpool.Pool }

// NewKVKKRepository depoyu kurar.
func NewKVKKRepository(pool *pgxpool.Pool) *KVKKRepository { return &KVKKRepository{pool: pool} }

func (r *KVKKRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

const kvkkSelect = `
	SELECT k.id::text, k.user_id::text, COALESCE(u.first_name || ' ' || u.last_name, ''),
	       k.request_type, k.description, k.status, k.due_date, (k.due_date - CURRENT_DATE)::int,
	       COALESCE(k.response, ''), k.responded_at, k.created_at
	FROM kvkk_requests k
	LEFT JOIN users u ON u.id = k.user_id`

func scanKVKK(row pgx.Row) (*KVKKRequest, error) {
	k := &KVKKRequest{}
	err := row.Scan(&k.ID, &k.UserID, &k.ApplicantName, &k.RequestType, &k.Description, &k.Status,
		&k.DueDate, &k.DaysLeft, &k.Response, &k.RespondedAt, &k.CreatedAt)
	return k, err
}

// Create başvuruyu kaydeder; son gün, başvuru anında yasal süreyle hesaplanır.
func (r *KVKKRepository) Create(ctx context.Context, propertyID, userID, requestType, description string, responseDays int) (*KVKKRequest, error) {
	var id string
	if err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO kvkk_requests (property_id, user_id, request_type, description, due_date)
		VALUES ($1, $2, $3, $4, CURRENT_DATE + $5::int) RETURNING id::text`,
		propertyID, userID, requestType, description, responseDays).Scan(&id); err != nil {
		return nil, err
	}
	return r.Get(ctx, propertyID, id)
}

// Get tek başvuru.
func (r *KVKKRepository) Get(ctx context.Context, propertyID, id string) (*KVKKRequest, error) {
	k, err := scanKVKK(r.scope(propertyID).QueryRow(ctx, kvkkSelect+`
		WHERE k.id = $1 AND k.property_id = $2`, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrKVKKNotFound
	}
	return k, err
}

// List: userID doluysa yalnızca o kişinin başvuruları; boşsa sitenin tümü
// (açıklar ve süresi yaklaşanlar önce).
func (r *KVKKRepository) List(ctx context.Context, propertyID, userID string) ([]*KVKKRequest, error) {
	rows, err := r.scope(propertyID).Query(ctx, kvkkSelect+`
		WHERE k.property_id = $1 AND ($2 = '' OR k.user_id::text = $2)
		ORDER BY (k.status = 'OPEN') DESC, k.due_date, k.created_at DESC
		LIMIT 500`, propertyID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*KVKKRequest{}
	for rows.Next() {
		k, err := scanKVKK(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, k)
	}
	return out, rows.Err()
}

// Respond başvuruyu sonuçlandırır (yalnızca açıksa).
func (r *KVKKRepository) Respond(ctx context.Context, propertyID, id, actorID, status, response string) (*KVKKRequest, error) {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE kvkk_requests
		SET status = $3, response = $4, responded_by = NULLIF($5, '')::uuid, responded_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'OPEN'`, id, propertyID, status, response, actorID)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		if _, gerr := r.Get(ctx, propertyID, id); gerr != nil {
			return nil, gerr
		}
		return nil, ErrKVKKNotOpen
	}
	return r.Get(ctx, propertyID, id)
}
