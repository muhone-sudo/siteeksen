package repository

// Dairenin malik ve kiracısının gördüğü sakin listesi (beşinci tur B5; altıncı tur D3'te davet akışına geçti).

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// UnitResident, malik ya da kiracının kendi dairesinde gördüğü sakin bilgisidir. Telefon maskelenir,
// e-posta gösterilmez: malik kiracısını tanır ama sistem gereğinden fazla veri paylaşmaz (KVKK m.4).
type UnitResident struct {
	ID          string     `json:"id"`
	FirstName   string     `json:"first_name"`
	LastName    string     `json:"last_name"`
	Role        string     `json:"role"`
	PhoneMasked string     `json:"phone_masked"`
	IsActive    bool       `json:"is_active"`
	IsSelf      bool       `json:"is_self"`
	CreatedAt   time.Time  `json:"created_at"`
	EndDate     *time.Time `json:"end_date,omitempty"`
}

// ListUnitResidents, bölümün sakinlerini döner (aktifler önce; ayrılanlar son 1 yıl).
func (r *ResidentRepository) ListUnitResidents(ctx context.Context, propertyID, unitID, viewerID string) ([]UnitResident, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT ru.id::text, u.first_name, u.last_name, ru.role,
		       CASE WHEN length(u.phone) > 4 THEN repeat('*', length(u.phone) - 4) || right(u.phone, 4) ELSE '****' END,
		       ru.is_active, u.id = $3, ru.created_at, ru.end_date
		FROM resident_units ru
		JOIN units un ON un.id = ru.unit_id
		JOIN users u ON u.id = ru.resident_id AND u.deleted = 0
		WHERE ru.unit_id = $1 AND un.property_id = $2
		  AND (ru.is_active OR ru.end_date >= CURRENT_DATE - 365)
		ORDER BY ru.is_active DESC, ru.role, u.first_name`, unitID, propertyID, viewerID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []UnitResident{}
	for rows.Next() {
		var x UnitResident
		if err := rows.Scan(&x.ID, &x.FirstName, &x.LastName, &x.Role, &x.PhoneMasked, &x.IsActive, &x.IsSelf, &x.CreatedAt, &x.EndDate); err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// ResidentLink, bir daire bağının özetidir.
type ResidentLink struct {
	UnitID, Role, ResidentID string
	IsActive                 bool
}

// GetResidentLink, bağı (sitesiyle birlikte) okur.
func (r *ResidentRepository) GetResidentLink(ctx context.Context, propertyID, residentUnitID string) (*ResidentLink, error) {
	l := &ResidentLink{}
	err := r.pool.QueryRow(ctx, `SELECT ru.unit_id::text, ru.role, ru.resident_id::text, ru.is_active
		FROM resident_units ru JOIN units un ON un.id = ru.unit_id
		WHERE ru.id = $1 AND un.property_id = $2`, residentUnitID, propertyID).Scan(&l.UnitID, &l.Role, &l.ResidentID, &l.IsActive)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrResidentNotFound
	}
	return l, err
}
