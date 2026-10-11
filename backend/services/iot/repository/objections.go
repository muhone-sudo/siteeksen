package repository

// Tüketim pusulasına itiraz (migration 063, beşinci tur B8).

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

var (
	// ErrObjectionOpen: bu pusula ve bölüm için yanıt bekleyen itiraz zaten var.
	ErrObjectionOpen = errors.New("bu pusula için yanıt bekleyen bir itirazınız zaten var")
	// ErrObjectionClosed: itiraz zaten yanıtlanmış.
	ErrObjectionClosed = errors.New("itiraz zaten yanıtlanmış")
	// ErrNotUnitResident: çağıran bölümün aktif sakini değil ya da bölüm pusulada yok.
	ErrNotUnitResident = errors.New("bu bölümde pusulaya itiraz hakkınız yok ya da bölüm bu pusulada yok (kiracılı dairede kullanım işlemlerini kiracı ve hanesi yapar)")
)

// Objection, pusula itirazıdır.
type Objection struct {
	ID            string     `json:"id"`
	AllocationID  string     `json:"allocation_id"`
	MeterType     string     `json:"meter_type"`
	PeriodFrom    time.Time  `json:"period_from"`
	PeriodTo      time.Time  `json:"period_to"`
	UnitID        string     `json:"unit_id"`
	Unit          string     `json:"unit"`
	UserID        string     `json:"user_id"`
	UserName      string     `json:"user_name"`
	TotalKurus    int64      `json:"total_kurus"`
	Reason        string     `json:"reason"`
	Status        string     `json:"status"`
	Response      *string    `json:"response,omitempty"`
	RespondedAt   *time.Time `json:"responded_at,omitempty"`
	RespondedName *string    `json:"responded_by_name,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

const objectionSelect = `
	SELECT o.id::text, o.allocation_id::text, a.meter_type, a.period_from, a.period_to, o.unit_id::text,
	       COALESCE(NULLIF(un.block, ''), '') || '-' || COALESCE(un.door_number, ''), o.user_id::text,
	       TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')), COALESCE(cu.total_kurus, 0),
	       o.reason, o.status, o.response, o.responded_at,
	       NULLIF(TRIM(COALESCE(r.first_name, '') || ' ' || COALESCE(r.last_name, '')), ''), o.created_at
	FROM consumption_statement_objections o
	JOIN consumption_allocations a ON a.id = o.allocation_id
	JOIN units un ON un.id = o.unit_id
	LEFT JOIN users u ON u.id = o.user_id
	LEFT JOIN users r ON r.id = o.responded_by
	LEFT JOIN consumption_allocation_units cu ON cu.allocation_id = o.allocation_id AND cu.unit_id = o.unit_id`

func scanObjection(row pgx.Row) (*Objection, error) {
	o := &Objection{}
	err := row.Scan(&o.ID, &o.AllocationID, &o.MeterType, &o.PeriodFrom, &o.PeriodTo, &o.UnitID, &o.Unit, &o.UserID,
		&o.UserName, &o.TotalKurus, &o.Reason, &o.Status, &o.Response, &o.RespondedAt, &o.RespondedName, &o.CreatedAt)
	return o, err
}

// CreateObjection, sakinin itirazını yazar. Çağıran bölümün AKTİF sakini olmalı ve bölüm
// yayımlanmış pusulada yer almalıdır.
func (r *Repository) CreateObjection(ctx context.Context, propertyID, userID, allocationID, unitID, reason string) (*Objection, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var ok bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (
		SELECT 1 FROM consumption_allocation_units cu
		JOIN resident_units ru ON ru.unit_id = cu.unit_id AND ru.resident_id = $3 AND ru.is_active AND resident_can_use(ru.id)
		     AND ru.role <> 'HOUSEHOLD' -- pusula tutar içerir; itiraz ödeyenindir (V4)
		WHERE cu.allocation_id = $1 AND cu.unit_id = $2)`, allocationID, unitID, userID).Scan(&ok); err != nil {
		return nil, err
	}
	if !ok {
		return nil, ErrNotUnitResident
	}
	var id string
	err = tx.QueryRow(ctx, `INSERT INTO consumption_statement_objections (property_id, allocation_id, unit_id, user_id, reason)
		VALUES ($1, $2, $3, $4, $5) RETURNING id::text`, propertyID, allocationID, unitID, userID, reason).Scan(&id)
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		return nil, ErrObjectionOpen
	}
	if err != nil {
		return nil, err
	}
	o, err := scanObjection(tx.QueryRow(ctx, objectionSelect+` WHERE o.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return o, tx.Commit(ctx)
}

// ListObjections: yönetim için tümü (status süzgeci isteğe bağlı), sakin için kendi bölümleri.
func (r *Repository) ListObjections(ctx context.Context, propertyID, residentID, status string) ([]*Objection, error) {
	rows, err := r.scope(propertyID).Query(ctx, objectionSelect+`
		WHERE o.property_id = $1 AND ($2 = '' OR o.status = $2)
		  AND ($3 = '' OR o.unit_id IN (SELECT unit_id FROM resident_units WHERE resident_id::text = $3 AND is_active AND resident_can_use(id) AND role <> 'HOUSEHOLD'))
		ORDER BY (o.status = 'OPEN') DESC, o.created_at DESC
		LIMIT 500`, propertyID, status, residentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*Objection{}
	for rows.Next() {
		o, err := scanObjection(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, o)
	}
	return out, rows.Err()
}

// RespondObjection, açık itirazı kabul/ret ve açıklamayla yanıtlar.
func (r *Repository) RespondObjection(ctx context.Context, propertyID, userID, id, decision, response string) (*Objection, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var status string
	err = tx.QueryRow(ctx, `SELECT status FROM consumption_statement_objections WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		id, propertyID).Scan(&status)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if status != "OPEN" {
		return nil, ErrObjectionClosed
	}
	if _, err := tx.Exec(ctx, `UPDATE consumption_statement_objections SET status = $2, response = $3,
		responded_by = NULLIF($4,'')::uuid, responded_at = now() WHERE id = $1`, id, decision, response, userID); err != nil {
		return nil, err
	}
	o, err := scanObjection(tx.QueryRow(ctx, objectionSelect+` WHERE o.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return o, tx.Commit(ctx)
}
