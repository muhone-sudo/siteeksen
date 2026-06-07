package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/community/models"
)

// ErrRequestNotFound talep bulunamadığında döner
var ErrRequestNotFound = errors.New("talep bulunamadı")

// RequestRepository talep veritabanı işlemleri
type RequestRepository struct {
	pool *pgxpool.Pool
}

// NewRequestRepository yeni repository oluşturur
func NewRequestRepository(pool *pgxpool.Pool) *RequestRepository {
	return &RequestRepository{pool: pool}
}

const requestColumns = `
	id, property_id, unit_id::text, resident_id, category_id::text, ticket_number, title,
	COALESCE(description, ''), COALESCE(location, ''), priority, status, photo_urls,
	resolved_at, closed_at, user_confirmed_at, created_at, updated_at
`

func scanRequest(row pgx.Row) (*models.Request, error) {
	req := &models.Request{}
	var unitID, categoryID *string
	err := row.Scan(
		&req.ID, &req.PropertyID, &unitID, &req.ResidentID, &categoryID, &req.TicketNumber, &req.Title,
		&req.Description, &req.Location, &req.Priority, &req.Status, &req.PhotoURLs,
		&req.ResolvedAt, &req.ClosedAt, &req.UserConfirmedAt, &req.CreatedAt, &req.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	req.UnitID = unitID
	req.CategoryID = categoryID
	return req, nil
}

// ListByResident sakinin kendi taleplerini getirir
func (r *RequestRepository) ListByResident(ctx context.Context, residentID, status string) ([]*models.Request, error) {
	query := `SELECT ` + requestColumns + ` FROM requests WHERE resident_id = $1`
	args := []interface{}{residentID}
	if status != "" {
		query += ` AND status = $2`
		args = append(args, status)
	}
	query += ` ORDER BY created_at DESC`
	return r.list(ctx, query, args...)
}

// ListByProperty bir sitedeki tüm talepleri getirir (yönetim görünümü)
func (r *RequestRepository) ListByProperty(ctx context.Context, propertyID, status string) ([]*models.Request, error) {
	query := `SELECT ` + requestColumns + ` FROM requests WHERE property_id = $1`
	args := []interface{}{propertyID}
	if status != "" {
		query += ` AND status = $2`
		args = append(args, status)
	}
	query += ` ORDER BY created_at DESC`
	return r.list(ctx, query, args...)
}

func (r *RequestRepository) list(ctx context.Context, query string, args ...interface{}) ([]*models.Request, error) {
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []*models.Request
	for rows.Next() {
		req, err := scanRequest(rows)
		if err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, rows.Err()
}

// GetByID ID'ye göre talep getirir
func (r *RequestRepository) GetByID(ctx context.Context, id string) (*models.Request, error) {
	query := `SELECT ` + requestColumns + ` FROM requests WHERE id = $1`
	req, err := scanRequest(r.pool.QueryRow(ctx, query, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRequestNotFound
	}
	if err != nil {
		return nil, err
	}
	return req, nil
}

// Create yeni talep oluşturur
func (r *RequestRepository) Create(ctx context.Context, propertyID, residentID, ticketNumber string, input models.CreateRequestInput) (*models.Request, error) {
	query := `
		INSERT INTO requests (property_id, resident_id, category_id, ticket_number, title, description, location, priority, photo_urls, status)
		VALUES ($1, $2, NULLIF($3, '')::uuid, $4, $5, $6, $7, COALESCE(NULLIF($8, ''), 'NORMAL'), $9, 'OPEN')
		RETURNING ` + requestColumns

	priority := input.Priority
	row := r.pool.QueryRow(ctx, query,
		propertyID, residentID, input.CategoryID, ticketNumber, input.Title, input.Description,
		input.Location, priority, input.Photos,
	)
	return scanRequest(row)
}

// UpdateStatus yönetici tarafından talep durumunu günceller (OPEN -> IN_PROGRESS -> RESOLVED)
func (r *RequestRepository) UpdateStatus(ctx context.Context, id, status string) (*models.Request, error) {
	var query string
	switch status {
	case models.StatusResolved:
		query = `UPDATE requests SET status = $2, resolved_at = NOW(), updated_at = NOW() WHERE id = $1 RETURNING ` + requestColumns
	default:
		query = `UPDATE requests SET status = $2, updated_at = NOW() WHERE id = $1 RETURNING ` + requestColumns
	}

	row := r.pool.QueryRow(ctx, query, id, status)
	req, err := scanRequest(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRequestNotFound
	}
	return req, err
}

// ConfirmResolution sakin onayı: onaylarsa CLOSED + user_confirmed_at, reddederse IN_PROGRESS'e döner
func (r *RequestRepository) ConfirmResolution(ctx context.Context, id string, approved bool) (*models.Request, error) {
	var query string
	if approved {
		query = `
			UPDATE requests
			SET status = 'CLOSED', user_confirmed_at = NOW(), closed_at = NOW(), updated_at = NOW()
			WHERE id = $1
			RETURNING ` + requestColumns
	} else {
		query = `
			UPDATE requests
			SET status = 'IN_PROGRESS', resolved_at = NULL, updated_at = NOW()
			WHERE id = $1
			RETURNING ` + requestColumns
	}

	row := r.pool.QueryRow(ctx, query, id)
	req, err := scanRequest(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRequestNotFound
	}
	return req, err
}
