package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/identity/models"
)

// UserRepository kullanıcı veritabanı işlemleri
type UserRepository struct {
	pool *pgxpool.Pool
}

// NewUserRepository yeni repository oluşturur
func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

// GetByPhone telefon numarasına göre kullanıcı getirir
func (r *UserRepository) GetByPhone(ctx context.Context, phone string) (*models.User, error) {
	query := `
		SELECT id, tc_encrypted, tc_hash, first_name, last_name, 
			   phone, email, password_hash, active_property_id, roles, created_at, updated_at
		FROM users 
		WHERE phone = $1
	`
	user := &models.User{}
	err := r.pool.QueryRow(ctx, query, phone).Scan(
		&user.ID, &user.TCEncrypted, &user.TCHash, &user.FirstName, &user.LastName,
		&user.Phone, &user.Email, &user.PasswordHash, &user.ActivePropertyID, &user.Roles,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// GetByID ID'ye göre kullanıcı getirir
func (r *UserRepository) GetByID(ctx context.Context, id string) (*models.User, error) {
	query := `
		SELECT id, tc_encrypted, tc_hash, first_name, last_name, 
			   phone, email, password_hash, active_property_id, roles, created_at, updated_at
		FROM users 
		WHERE id = $1
	`
	user := &models.User{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.TCEncrypted, &user.TCHash, &user.FirstName, &user.LastName,
		&user.Phone, &user.Email, &user.PasswordHash, &user.ActivePropertyID, &user.Roles,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// GetUserProperties kullanıcının bağlı olduğu siteleri getirir
func (r *UserRepository) GetUserProperties(ctx context.Context, userID string) ([]models.UserProperty, error) {
	query := `
		SELECT p.id, p.name, u.id, u.block || '-' || u.door_number, ru.role
		FROM resident_units ru
		JOIN units u ON ru.unit_id = u.id
		JOIN properties p ON u.property_id = p.id
		WHERE ru.resident_id = $1 AND ru.is_active = true
	`
	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var properties []models.UserProperty
	for rows.Next() {
		var p models.UserProperty
		if err := rows.Scan(&p.PropertyID, &p.PropertyName, &p.UnitID, &p.UnitName, &p.Role); err != nil {
			return nil, err
		}
		properties = append(properties, p)
	}
	return properties, nil
}

// SetActiveProperty aktif siteyi değiştirir
func (r *UserRepository) SetActiveProperty(ctx context.Context, userID, propertyID string) error {
	query := `UPDATE users SET active_property_id = $1, updated_at = NOW() WHERE id = $2`
	_, err := r.pool.Exec(ctx, query, propertyID, userID)
	return err
}

// Create yeni kullanıcı oluşturur
func (r *UserRepository) Create(ctx context.Context, user *models.User) error {
	query := `
		INSERT INTO users (id, tc_encrypted, tc_hash, first_name, last_name, phone, email, password_hash, roles)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.pool.Exec(ctx, query,
		user.ID, user.TCEncrypted, user.TCHash, user.FirstName, user.LastName,
		user.Phone, user.Email, user.PasswordHash, user.Roles,
	)
	return err
}
