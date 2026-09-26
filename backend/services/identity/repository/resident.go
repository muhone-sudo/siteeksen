package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/identity/models"
)

// ErrResidentNotFound sakin bulunamadığında döner
var ErrResidentNotFound = errors.New("sakin bulunamadı")

// ErrUnitNotFound birim bulunamadığında döner
var ErrUnitNotFound = errors.New("birim bulunamadı")

// ErrPhoneAlreadyExists telefon numarası başka bir kullanıcıda kayıtlıysa döner
var ErrPhoneAlreadyExists = errors.New("bu telefon numarası başka bir kullanıcıya ait")

// ResidentRepository sakin (kullanıcı + birim ilişkisi) veritabanı işlemleri
type ResidentRepository struct {
	pool *pgxpool.Pool
}

// NewResidentRepository yeni repository oluşturur
func NewResidentRepository(pool *pgxpool.Pool) *ResidentRepository {
	return &ResidentRepository{pool: pool}
}

const residentColumns = `
	ru.id, u.id, u.first_name, u.last_name, u.phone, COALESCE(u.email, ''),
	un.id, COALESCE(NULLIF(un.block, ''), '') || '-' || un.door_number,
	ru.role, ru.is_active, ru.created_at
`

func scanResident(row pgx.Row) (*models.Resident, error) {
	res := &models.Resident{}
	err := row.Scan(
		&res.ID, &res.UserID, &res.FirstName, &res.LastName, &res.Phone, &res.Email,
		&res.UnitID, &res.Unit, &res.Role, &res.IsActive, &res.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return res, nil
}

// List bir sitedeki sakinleri arama/blok/rol filtreleriyle getirir
func (r *ResidentRepository) List(ctx context.Context, propertyID, search, block, role string) ([]*models.Resident, error) {
	query := `
		SELECT ` + residentColumns + `
		FROM resident_units ru
		JOIN users u ON ru.resident_id = u.id
		JOIN units un ON ru.unit_id = un.id
		WHERE un.property_id = $1 AND u.deleted = 0
		  AND ($2 = '' OR u.first_name || ' ' || u.last_name ILIKE '%' || $2 || '%' OR u.phone ILIKE '%' || $2 || '%')
		  AND ($3 = '' OR un.block = $3)
		  AND ($4 = '' OR ru.role = $4)
		ORDER BY u.first_name, u.last_name
	`
	rows, err := r.pool.Query(ctx, query, propertyID, search, block, role)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	residents := []*models.Resident{}
	for rows.Next() {
		res, err := scanResident(rows)
		if err != nil {
			return nil, err
		}
		residents = append(residents, res)
	}
	return residents, rows.Err()
}

// GetByID ID'ye göre sakin getirir
func (r *ResidentRepository) GetByID(ctx context.Context, propertyID, id string) (*models.Resident, error) {
	query := `
		SELECT ` + residentColumns + `
		FROM resident_units ru
		JOIN users u ON ru.resident_id = u.id
		JOIN units un ON ru.unit_id = un.id
		WHERE ru.id = $1 AND un.property_id = $2 AND u.deleted = 0
	`
	res, err := scanResident(r.pool.QueryRow(ctx, query, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrResidentNotFound
	}
	if err != nil {
		return nil, err
	}
	return res, nil
}

// Create sakin kaydı açar: telefon numarasıyla kullanıcı varsa daireye bağlar,
// yoksa kullanılamaz bir parola özetiyle yeni hesap açıp bağlar (tek transaction).
// İkinci dönüş değeri, bu işlemde YENİ bir kullanıcı
// hesabı açılıp açılmadığıdır (açıldıysa etkinleştirme kodu üretilmelidir).
func (r *ResidentRepository) Create(ctx context.Context, propertyID, passwordHash string, input models.CreateResidentInput) (*models.Resident, bool, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, false, err
	}
	defer tx.Rollback(ctx)

	var unitExists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2)`, input.UnitID, propertyID).Scan(&unitExists); err != nil {
		return nil, false, err
	}
	if !unitExists {
		return nil, false, ErrUnitNotFound
	}

	var userID, existingName string
	created := false
	err = tx.QueryRow(ctx, `SELECT id, first_name FROM users WHERE phone = $1 AND deleted = 0`, input.Phone).Scan(&userID, &existingName)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		created = true
		err = tx.QueryRow(ctx, `
			INSERT INTO users (first_name, last_name, phone, email, password_hash, roles)
			VALUES ($1, $2, $3, NULLIF($4, ''), $5, ARRAY['RESIDENT'])
			RETURNING id
		`, input.FirstName, input.LastName, input.Phone, input.Email, passwordHash).Scan(&userID)
		if err != nil {
			return nil, false, err
		}
	case err != nil:
		return nil, false, err
	}

	var residentUnitID string
	err = tx.QueryRow(ctx, `
		INSERT INTO resident_units (resident_id, unit_id, role)
		VALUES ($1, $2, $3)
		RETURNING id
	`, userID, input.UnitID, input.Role).Scan(&residentUnitID)
	if err != nil {
		return nil, false, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, false, err
	}

	res, err := r.GetByID(ctx, propertyID, residentUnitID)
	return res, created, err
}

// Update sakinin birim ilişkisindeki rol/aktiflik bilgisini günceller
func (r *ResidentRepository) Update(ctx context.Context, propertyID, id string, input models.UpdateResidentInput) (*models.Resident, error) {
	current, err := r.GetByID(ctx, propertyID, id)
	if err != nil {
		return nil, err
	}

	role := current.Role
	if input.Role != nil {
		role = *input.Role
	}
	isActive := current.IsActive
	if input.IsActive != nil {
		isActive = *input.IsActive
	}

	_, err = r.pool.Exec(ctx, `UPDATE resident_units SET role = $2, is_active = $3 WHERE id = $1`, id, role, isActive)
	if err != nil {
		return nil, err
	}
	return r.GetByID(ctx, propertyID, id)
}

// ListUnits bir sitedeki birimleri getirir
func (r *ResidentRepository) ListUnits(ctx context.Context, propertyID string) ([]*models.Unit, error) {
	query := `
		SELECT id, property_id, COALESCE(block, ''), floor, door_number, share_ratio,
		       COALESCE(gross_area_m2, 0), unit_type, is_commercial
		FROM units
		WHERE property_id = $1
		ORDER BY block, floor, door_number
	`
	rows, err := r.pool.Query(ctx, query, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	units := []*models.Unit{}
	for rows.Next() {
		u := &models.Unit{}
		if err := rows.Scan(&u.ID, &u.PropertyID, &u.Block, &u.Floor, &u.DoorNumber, &u.ShareRatio,
			&u.GrossAreaM2, &u.UnitType, &u.IsCommercial); err != nil {
			return nil, err
		}
		units = append(units, u)
	}
	return units, rows.Err()
}
