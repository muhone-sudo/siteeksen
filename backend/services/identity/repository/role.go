package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/identity/models"
)

// Görevlendirme hataları.
var (
	ErrRoleExists      = errors.New("bu kişinin sitede bu görevi zaten var")
	ErrRoleNotFound    = errors.New("görevlendirme bulunamadı")
	ErrRoleNotActive   = errors.New("görevlendirme zaten sona ermiş")
	ErrLastManager     = errors.New("sitenin tek yöneticisinin görevi sonlandırılamaz")
	ErrUserOtherSite   = errors.New("bu telefon numarası bu siteyle bağı olmayan bir hesaba ait")
	ErrNameRequiredNew = errors.New("bu telefonla kayıtlı hesap yok; yeni hesap için ad ve soyad gerekli")
)

// RoleRepository site görevlendirmeleri (property_roles). Yalnızca kimlik
// servisi bu tabloya yazar (025).
type RoleRepository struct {
	pool *pgxpool.Pool
}

// NewRoleRepository depoyu kurar.
func NewRoleRepository(pool *pgxpool.Pool) *RoleRepository { return &RoleRepository{pool: pool} }

const roleSelect = `
	SELECT pr.id::text, pr.user_id::text, u.first_name, u.last_name, u.phone, pr.role,
	       pr.valid_from, pr.valid_to, COALESCE(pr.decision_ref, ''),
	       pr.is_active AND pr.valid_from <= CURRENT_DATE
	         AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE),
	       COALESCE(gb.first_name || ' ' || gb.last_name, ''), pr.granted_at
	FROM property_roles pr
	JOIN users u ON u.id = pr.user_id
	LEFT JOIN users gb ON gb.id = pr.granted_by`

func scanRole(row pgx.Row) (*models.SiteRole, error) {
	r := &models.SiteRole{}
	err := row.Scan(&r.ID, &r.UserID, &r.FirstName, &r.LastName, &r.Phone, &r.Role,
		&r.ValidFrom, &r.ValidTo, &r.DecisionRef, &r.Active, &r.GrantedByName, &r.GrantedAt)
	return r, err
}

// List sitenin görevlendirmeleri (etkin olanlar önce; geçmiş korunur).
func (r *RoleRepository) List(ctx context.Context, propertyID string) ([]*models.SiteRole, error) {
	rows, err := r.pool.Query(ctx, roleSelect+`
		WHERE pr.property_id = $1
		ORDER BY pr.is_active DESC, pr.granted_at DESC
		LIMIT 500`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*models.SiteRole{}
	for rows.Next() {
		sr, err := scanRole(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, sr)
	}
	return out, rows.Err()
}

func (r *RoleRepository) get(ctx context.Context, propertyID, id string) (*models.SiteRole, error) {
	sr, err := scanRole(r.pool.QueryRow(ctx, roleSelect+`
		WHERE pr.id = $1 AND pr.property_id = $2`, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRoleNotFound
	}
	return sr, err
}

// Grant görevlendirme yazar. Kişi telefonla bulunur:
//   - hesap yoksa ve ad/soyad verildiyse kullanılamaz parola özetiyle hesap açılır
//     (ikinci dönüş true: etkinleştirme kodu üretilmeli);
//   - hesap bu siteyle bağlıysa (sakin ya da görevli, geçmiş dahil) görev verilir;
//   - hesap bu siteyle bağı olmayan biriyse REDDEDİLİR: kişinin onayı olmadan
//     başka siteden birine yönetim yetkisi bağlanmaz (B25 ile aynı ilke).
func (r *RoleRepository) Grant(ctx context.Context, propertyID, actorID, passwordHash string,
	in models.GrantRoleInput, validFrom, validTo *time.Time) (*models.SiteRole, bool, string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, false, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var userID string
	created := false
	err = tx.QueryRow(ctx, `SELECT id::text FROM users WHERE phone = $1 AND deleted = 0`, in.Phone).Scan(&userID)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		if in.FirstName == "" || in.LastName == "" {
			return nil, false, "", ErrNameRequiredNew
		}
		if err := tx.QueryRow(ctx, `
			INSERT INTO users (first_name, last_name, phone, password_hash, roles)
			VALUES ($1, $2, $3, $4, ARRAY['RESIDENT']) RETURNING id::text`,
			in.FirstName, in.LastName, in.Phone, passwordHash).Scan(&userID); err != nil {
			return nil, false, "", err
		}
		created = true
	case err != nil:
		return nil, false, "", err
	default:
		var linked bool
		if err := tx.QueryRow(ctx, `
			SELECT EXISTS (SELECT 1 FROM resident_units ru JOIN units un ON un.id = ru.unit_id
			               WHERE ru.resident_id = $1 AND un.property_id = $2)
			    OR EXISTS (SELECT 1 FROM property_roles pr WHERE pr.user_id = $1 AND pr.property_id = $2)`,
			userID, propertyID).Scan(&linked); err != nil {
			return nil, false, "", err
		}
		if !linked {
			return nil, false, "", ErrUserOtherSite
		}
	}

	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO property_roles (user_id, property_id, role, granted_by, valid_from, valid_to, decision_ref)
		VALUES ($1, $2, $3, NULLIF($4, '')::uuid, COALESCE($5::date, CURRENT_DATE), $6, NULLIF($7, ''))
		ON CONFLICT (user_id, property_id, role) WHERE is_active DO NOTHING
		RETURNING id::text`,
		userID, propertyID, in.Role, actorID, validFrom, validTo, in.DecisionRef).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, false, "", ErrRoleExists
	}
	if err != nil {
		return nil, false, "", err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, false, "", err
	}
	sr, err := r.get(ctx, propertyID, id)
	return sr, created, userID, err
}

// End görevi sonlandırır (kayıt silinmez: atama geçmişi iz olarak kalır).
// Sitenin geçerli tek yöneticisinin görevi sonlandırılamaz: site yönetimsiz
// kalır ve kimse yeni yönetici atayamazdı. Dönen değer kişinin kimliğidir
// (oturumları kapatılmalıdır).
func (r *RoleRepository) End(ctx context.Context, propertyID, id string) (*models.SiteRole, string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var userID, role string
	var active bool
	err = tx.QueryRow(ctx, `
		SELECT user_id::text, role, is_active FROM property_roles
		WHERE id = $1 AND property_id = $2 FOR UPDATE`, id, propertyID).Scan(&userID, &role, &active)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, "", ErrRoleNotFound
	}
	if err != nil {
		return nil, "", err
	}
	if !active {
		return nil, "", ErrRoleNotActive
	}
	if role == "MANAGER" {
		// Diğer yönetici satırları da kilitlenir: iki yönetici aynı anda birbirini
		// sonlandırırsa site yöneticisiz kalmasın.
		var others int
		if err := tx.QueryRow(ctx, `
			SELECT count(*) FROM (
				SELECT 1 FROM property_roles
				WHERE property_id = $1 AND role = 'MANAGER' AND is_active AND id <> $2
				  AND valid_from <= CURRENT_DATE AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
				FOR UPDATE) x`, propertyID, id).Scan(&others); err != nil {
			return nil, "", err
		}
		if others == 0 {
			return nil, "", ErrLastManager
		}
	}
	if _, err := tx.Exec(ctx, `
		UPDATE property_roles
		SET is_active = false,
		    valid_to = GREATEST(valid_from, LEAST(COALESCE(valid_to, CURRENT_DATE), CURRENT_DATE))
		WHERE id = $1`, id); err != nil {
		return nil, "", err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, "", err
	}
	sr, err := r.get(ctx, propertyID, id)
	return sr, userID, err
}
