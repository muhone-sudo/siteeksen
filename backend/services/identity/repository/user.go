package repository

import (
	"context"
	"errors"

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
		SELECT id, COALESCE(tc_encrypted, ''), COALESCE(tc_hash, ''), first_name, last_name,
			   phone, COALESCE(email, ''), password_hash, COALESCE(active_property_id::text, ''), roles, kvkk_consent_at, created_at, updated_at
		FROM users
		WHERE phone = $1 AND deleted = 0 AND COALESCE(is_active, true)
	`
	user := &models.User{}
	err := r.pool.QueryRow(ctx, query, phone).Scan(
		&user.ID, &user.TCEncrypted, &user.TCHash, &user.FirstName, &user.LastName,
		&user.Phone, &user.Email, &user.PasswordHash, &user.ActivePropertyID, &user.Roles, &user.KVKKConsentAt,
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
		SELECT id, COALESCE(tc_encrypted, ''), COALESCE(tc_hash, ''), first_name, last_name,
			   phone, COALESCE(email, ''), password_hash, COALESCE(active_property_id::text, ''), roles, kvkk_consent_at, created_at, updated_at
		FROM users
		WHERE id = $1 AND deleted = 0 AND COALESCE(is_active, true)
	`
	user := &models.User{}
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.TCEncrypted, &user.TCHash, &user.FirstName, &user.LastName,
		&user.Phone, &user.Email, &user.PasswordHash, &user.ActivePropertyID, &user.Roles, &user.KVKKConsentAt,
		&user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// GetUserProperties kullanıcının bağlı olduğu siteleri getirir: sakin olduğu
// daireler VE yönetim rolü taşıdığı siteler.
//
// DÜZELTME (2026-09-26): yalnızca sakinlik bağı okunuyordu. Sitede oturmayan
// profesyonel yönetici (yalnızca property_roles kaydı olan) sitesini listede
// görmüyor ve seçemiyordu. Yönetim satırında daire yoktur (unit_id boş).
func (r *UserRepository) GetUserProperties(ctx context.Context, userID string) ([]models.UserProperty, error) {
	query := `
		SELECT p.id::text, p.name, u.id::text, u.block || '-' || u.door_number, ru.role
		FROM resident_units ru
		JOIN units u ON ru.unit_id = u.id
		JOIN properties p ON u.property_id = p.id
		WHERE ru.resident_id = $1 AND ru.is_active = true
		UNION ALL
		SELECT p.id::text, p.name, '', '', pr.role
		FROM property_roles pr
		JOIN properties p ON p.id = pr.property_id
		WHERE pr.user_id = $1 AND pr.is_active
		  AND pr.valid_from <= CURRENT_DATE
		  AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE)
		ORDER BY 2, 1, 3
	`
	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	properties := []models.UserProperty{}
	for rows.Next() {
		var p models.UserProperty
		if err := rows.Scan(&p.PropertyID, &p.PropertyName, &p.UnitID, &p.UnitName, &p.Role); err != nil {
			return nil, err
		}
		properties = append(properties, p)
	}
	return properties, nil
}

// ErrPropertyNotOwned, kullanıcı seçmeye çalıştığı siteye bağlı değilse döner.
var ErrPropertyNotOwned = errors.New("kullanıcı bu siteye bağlı değil")

// SetActiveProperty aktif siteyi değiştirir.
//
// GÜVENLİK (2026-09-13, todo 2.4 / gap-analizi B21):
// Önceki sürüm gelen `propertyID`'yi HİÇ DOĞRULAMADAN yazıyordu. JWT'deki
// `property_id` claim'i tüm izolasyonun tek dayanağı olduğu için bu, herhangi bir
// kullanıcının bir istekle BAŞKA BİR SİTENİN verisine geçmesi anlamına geliyordu:
//
//	POST /users/me/active-property {"property_id": "<başka site>"} → 200
//	ardından alınan jeton o siteye erişim veriyordu.
//
// Artık site, kullanıcının aktif bir `resident_units` bağı bulunan siteler
// arasından seçilmek zorunda. Bağ yoksa istek reddedilir (fail-closed).
// Güncelleme, yarış durumuna yer bırakmamak için tek ifadede yapılır:
// UPDATE yalnızca bağ var ise satır etkiler.
func (r *UserRepository) SetActiveProperty(ctx context.Context, userID, propertyID string) error {
	const query = `
		UPDATE users
		SET active_property_id = $1, updated_at = NOW()
		WHERE id = $2
		  AND (EXISTS (
			SELECT 1
			FROM resident_units ru
			JOIN units u ON ru.unit_id = u.id
			WHERE ru.resident_id = $2
			  AND ru.is_active = true
			  AND u.property_id = $1
		  ) OR EXISTS (
			-- Sitede oturmayan yönetici: geçerli bir yönetim rolü yeterlidir.
			SELECT 1 FROM property_roles pr
			WHERE pr.user_id = $2 AND pr.property_id = $1 AND pr.is_active
			  AND pr.valid_from <= CURRENT_DATE
			  AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE)
		  ))`
	tag, err := r.pool.Exec(ctx, query, propertyID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrPropertyNotOwned
	}
	return nil
}

// ClearActiveProperty, kullanıcının artık bağlı olmadığı aktif siteyi boşaltır.
func (r *UserRepository) ClearActiveProperty(ctx context.Context, userID string) error {
	_, err := r.pool.Exec(ctx, `UPDATE users SET active_property_id = NULL, updated_at = NOW() WHERE id = $1`, userID)
	return err
}

// GetPropertyRoles, kullanıcının BELİRLİ BİR SİTEDEKİ rollerini döndürür.
//
// GÜVENLİK (2026-09-13, todo 2.5 / gap-analizi B22):
// Roller daha önce `users.roles` kolonundan GLOBAL okunuyordu; bir sitede yönetici
// olan kişi tüm sitelerde yönetici sayılıyordu. Artık roller aktif siteye göre,
// iki kaynaktan birleştirilerek hesaplanır:
//
//	property_roles  → yönetim rolleri (MANAGER, AUDITOR, STAFF, BOARD_MEMBER)
//	resident_units  → sakinlik rolleri (OWNER, TENANT) + her bağ için RESIDENT
//
// `users.roles` yalnızca platform düzeyi roller (örn. SUPER_ADMIN) için kalır.
//
// propertyID boşsa yalnızca platform rolleri döner — yani hiçbir site verisine
// erişim vermeyen, en dar yetki kümesi (fail-closed).
func (r *UserRepository) GetPropertyRoles(ctx context.Context, userID, propertyID string) ([]string, error) {
	const query = `
		-- Platform düzeyi roller (site bağımsız)
		SELECT DISTINCT pr.role
		FROM users u
		CROSS JOIN LATERAL unnest(u.roles) AS pr(role)
		WHERE u.id = $1 AND u.deleted = 0 AND pr.role = 'SUPER_ADMIN'

		UNION

		-- Site bazlı yönetim rolleri
		SELECT DISTINCT p.role
		FROM property_roles p
		WHERE p.user_id = $1
		  AND p.property_id = NULLIF($2, '')::uuid
		  AND p.is_active
		  AND p.valid_from <= CURRENT_DATE
		  AND (p.valid_to IS NULL OR p.valid_to >= CURRENT_DATE)

		UNION

		-- Sakinlik rolleri (bağımsız bölüm bağından türer)
		SELECT DISTINCT ru.role
		FROM resident_units ru
		JOIN units un ON un.id = ru.unit_id
		WHERE ru.resident_id = $1
		  AND ru.is_active = true
		  AND un.property_id = NULLIF($2, '')::uuid

		UNION

		-- Sitede herhangi bir bağı olan herkes RESIDENT sayılır
		SELECT 'RESIDENT'
		FROM resident_units ru
		JOIN units un ON un.id = ru.unit_id
		WHERE ru.resident_id = $1
		  AND ru.is_active = true
		  AND un.property_id = NULLIF($2, '')::uuid
		LIMIT 100`

	rows, err := r.pool.Query(ctx, query, userID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	roles := []string{}
	for rows.Next() {
		var role string
		if err := rows.Scan(&role); err != nil {
			return nil, err
		}
		roles = append(roles, role)
	}
	return roles, rows.Err()
}

// SetKVKKConsent kullanıcının KVKK açık rıza onay zamanını işaretler
func (r *UserRepository) SetKVKKConsent(ctx context.Context, userID string) error {
	query := `UPDATE users SET kvkk_consent_at = NOW(), updated_at = NOW() WHERE id = $1 AND kvkk_consent_at IS NULL`
	_, err := r.pool.Exec(ctx, query, userID)
	return err
}

// CreateProperty yeni site oluşturur ve oluşturan kullanıcıyı OWNER olarak bağlar
func (r *UserRepository) CreateProperty(ctx context.Context, userID string, req models.CreatePropertyRequest) (*models.Property, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	property := &models.Property{}
	err = tx.QueryRow(ctx, `
		INSERT INTO properties (name, type, address, city, district)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, name, type, address, city, created_at
	`, req.Name, req.Type, req.Address, req.City, req.District).Scan(
		&property.ID, &property.Name, &property.Type, &property.Address, &property.City, &property.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	var unitID string
	err = tx.QueryRow(ctx, `
		INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type)
		VALUES ($1, 'A', 0, 'YÖNETİM', 0, 'OFFICE')
		RETURNING id
	`, property.ID).Scan(&unitID)
	if err != nil {
		return nil, err
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO resident_units (resident_id, unit_id, role)
		VALUES ($1, $2, 'OWNER')
	`, userID, unitID)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return property, nil
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
