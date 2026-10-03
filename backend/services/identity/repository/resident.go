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

// Davet hataları (S-20, migration 032).
var (
	ErrInvitationPending    = errors.New("bu kişiye bu daire için bekleyen bir davet zaten var")
	ErrInvitationNotFound   = errors.New("davet bulunamadı")
	ErrInvitationNotPending = errors.New("davet artık yanıtlanamaz (yanıtlanmış, iptal edilmiş ya da süresi dolmuş)")
)

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
func (r *ResidentRepository) Create(ctx context.Context, propertyID, actorID, passwordHash string, input models.CreateResidentInput) (*models.Resident, bool, *models.Invitation, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, false, nil, err
	}
	defer tx.Rollback(ctx)

	var unitExists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2)`, input.UnitID, propertyID).Scan(&unitExists); err != nil {
		return nil, false, nil, err
	}
	if !unitExists {
		return nil, false, nil, ErrUnitNotFound
	}

	var userID, existingName string // existingName yanıtta KULLANILMAZ (B25)
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
			return nil, false, nil, err
		}
	case err != nil:
		return nil, false, nil, err
	default:
		// B25 (2026-10-03): telefon başka bir sitede kayıtlı bir hesaba aitse,
		// hesap önceden SESSİZCE bu daireye bağlanıyor ve yanıtta o kişinin
		// gerçek adı, soyadı ve e-postası yöneticiye gösteriliyordu (KVKK); kişinin
		// uygulamasında da hiç ilgisi olmayan bir site beliriyordu. Artık yalnızca
		// bu sitede zaten sakin ya da görevli olan hesap bağlanır (ikinci daire,
		// rol değişikliği). Hesap sahibinin onayıyla bağlama (davet) ayrı bir
		// akıştır — tasks/questions.md S-20.
		var linked bool
		if err := tx.QueryRow(ctx, `
			SELECT EXISTS (
				SELECT 1 FROM resident_units ru JOIN units un ON un.id = ru.unit_id
				WHERE ru.resident_id = $1 AND un.property_id = $2
			) OR EXISTS (
				SELECT 1 FROM property_roles pr WHERE pr.user_id = $1 AND pr.property_id = $2
			)`, userID, propertyID).Scan(&linked); err != nil {
			return nil, false, nil, err
		}
		if !linked {
			// S-20: bağ kurulmaz, DAVET açılır; kişi kendi uygulamasında kabul edince
			// bağlanır. Süresi dolmuş bekleyen davet önce kapatılır (yenisine yer açılır).
			if _, err := tx.Exec(ctx, `
				UPDATE resident_invitations SET status = 'EXPIRED'
				WHERE user_id = $1 AND unit_id = $2 AND role = $3
				  AND status = 'PENDING' AND expires_at <= now()`,
				userID, input.UnitID, input.Role); err != nil {
				return nil, false, nil, err
			}
			var invID string
			err := tx.QueryRow(ctx, `
				INSERT INTO resident_invitations (property_id, unit_id, user_id, role, invited_by)
				VALUES ($1, $2, $3, $4, NULLIF($5, '')::uuid)
				ON CONFLICT (user_id, unit_id, role) WHERE status = 'PENDING' DO NOTHING
				RETURNING id`, propertyID, input.UnitID, userID, input.Role, actorID).Scan(&invID)
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, false, nil, ErrInvitationPending
			}
			if err != nil {
				return nil, false, nil, err
			}
			if err := tx.Commit(ctx); err != nil {
				return nil, false, nil, err
			}
			inv, err := r.getInvitation(ctx, propertyID, invID)
			return nil, false, inv, err
		}
	}

	var residentUnitID string
	err = tx.QueryRow(ctx, `
		INSERT INTO resident_units (resident_id, unit_id, role)
		VALUES ($1, $2, $3)
		RETURNING id
	`, userID, input.UnitID, input.Role).Scan(&residentUnitID)
	if err != nil {
		return nil, false, nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, false, nil, err
	}

	res, err := r.GetByID(ctx, propertyID, residentUnitID)
	return res, created, nil, err
}

// Update sakinin birim ilişkisindeki rol/aktiflik bilgisini günceller.
//
// TEK ATOMİK UPDATE (2026-10-03, B65): önceden kayıt okunup eksik alanlar okunan
// değerle doldurularak yazılıyordu. Aynı anda biri rolü, diğeri aktifliği
// değiştirirse ikinci yazım birincinin değişikliğini sessizce geri alıyordu
// (kayıp güncelleme). Verilmeyen alan artık veritabanındaki güncel değeri korur;
// site denetimi aynı ifadede yapılır.
func (r *ResidentRepository) Update(ctx context.Context, propertyID, id string, input models.UpdateResidentInput) (*models.Resident, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE resident_units ru
		SET role = COALESCE($3, ru.role), is_active = COALESCE($4, ru.is_active)
		FROM units un, users u
		WHERE ru.id = $1 AND un.id = ru.unit_id AND un.property_id = $2
		  AND u.id = ru.resident_id AND u.deleted = 0`,
		id, propertyID, input.Role, input.IsActive)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, ErrResidentNotFound
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

// -----------------------------------------------------------------------------
// DAVETLER (S-20, migration 032)
// -----------------------------------------------------------------------------

// invitationSelect, yönetim görünümü. Süresi dolan bekleyen davet EXPIRED görünür.
const invitationSelect = `
	SELECT i.id::text, i.unit_id::text, COALESCE(NULLIF(un.block, ''), '') || '-' || un.door_number,
	       u.phone, i.role,
	       CASE WHEN i.status = 'PENDING' AND i.expires_at <= now() THEN 'EXPIRED' ELSE i.status END,
	       i.created_at, i.expires_at, i.responded_at
	FROM resident_invitations i
	JOIN units un ON un.id = i.unit_id
	JOIN users u ON u.id = i.user_id`

func scanInvitation(row pgx.Row) (*models.Invitation, error) {
	inv := &models.Invitation{}
	err := row.Scan(&inv.ID, &inv.UnitID, &inv.Unit, &inv.Phone, &inv.Role, &inv.Status,
		&inv.CreatedAt, &inv.ExpiresAt, &inv.RespondedAt)
	return inv, err
}

func (r *ResidentRepository) getInvitation(ctx context.Context, propertyID, id string) (*models.Invitation, error) {
	inv, err := scanInvitation(r.pool.QueryRow(ctx, invitationSelect+`
		WHERE i.id = $1 AND i.property_id = $2`, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrInvitationNotFound
	}
	return inv, err
}

// ListInvitations, sitenin davetlerini (en yeni önce) getirir.
func (r *ResidentRepository) ListInvitations(ctx context.Context, propertyID string) ([]*models.Invitation, error) {
	rows, err := r.pool.Query(ctx, invitationSelect+`
		WHERE i.property_id = $1 ORDER BY i.created_at DESC LIMIT 200`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*models.Invitation{}
	for rows.Next() {
		inv, err := scanInvitation(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, inv)
	}
	return out, rows.Err()
}

// CancelInvitation, bekleyen daveti yönetim adına iptal eder.
func (r *ResidentRepository) CancelInvitation(ctx context.Context, propertyID, id string) (*models.Invitation, error) {
	tag, err := r.pool.Exec(ctx, `
		UPDATE resident_invitations SET status = 'CANCELLED'
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING' AND expires_at > now()`, id, propertyID)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		if _, gerr := r.getInvitation(ctx, propertyID, id); gerr != nil {
			return nil, gerr
		}
		return nil, ErrInvitationNotPending
	}
	return r.getInvitation(ctx, propertyID, id)
}

// MyInvitations, kişinin yanıt bekleyen (süresi dolmamış) davetleri.
func (r *ResidentRepository) MyInvitations(ctx context.Context, userID string) ([]*models.MyInvitation, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT i.id::text, i.property_id::text, p.name,
		       COALESCE(NULLIF(un.block, ''), '') || '-' || un.door_number,
		       i.role, i.created_at, i.expires_at
		FROM resident_invitations i
		JOIN properties p ON p.id = i.property_id
		JOIN units un ON un.id = i.unit_id
		WHERE i.user_id = $1 AND i.status = 'PENDING' AND i.expires_at > now()
		ORDER BY i.created_at DESC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*models.MyInvitation{}
	for rows.Next() {
		m := &models.MyInvitation{}
		if err := rows.Scan(&m.ID, &m.PropertyID, &m.PropertyName, &m.Unit, &m.Role,
			&m.CreatedAt, &m.ExpiresAt); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// RespondInvitation, kişinin davete yanıtını işler. Kabulde daire bağı AYNI
// işlemde kurulur (daha önce pasifleşmiş bağ yeniden etkinleşir). Davet
// yalnızca davet edilen kişi tarafından ve süresi dolmadan yanıtlanabilir.
// Dönen değer davetin sitesidir.
func (r *ResidentRepository) RespondInvitation(ctx context.Context, userID, id string, accept bool) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var propertyID, unitID, role, status string
	var expired bool
	err = tx.QueryRow(ctx, `
		SELECT property_id::text, unit_id::text, role, status, expires_at <= now()
		FROM resident_invitations WHERE id = $1 AND user_id = $2
		FOR UPDATE`, id, userID).Scan(&propertyID, &unitID, &role, &status, &expired)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrInvitationNotFound
	}
	if err != nil {
		return "", err
	}
	if status != "PENDING" || expired {
		return "", ErrInvitationNotPending
	}

	newStatus := "DECLINED"
	if accept {
		newStatus = "ACCEPTED"
		if _, err := tx.Exec(ctx, `
			INSERT INTO resident_units (resident_id, unit_id, role)
			VALUES ($1, $2, $3)
			ON CONFLICT (resident_id, unit_id, role)
			DO UPDATE SET is_active = true, end_date = NULL`, userID, unitID, role); err != nil {
			return "", err
		}
	}
	if _, err := tx.Exec(ctx, `
		UPDATE resident_invitations SET status = $2, responded_at = now() WHERE id = $1`,
		id, newStatus); err != nil {
		return "", err
	}
	return propertyID, tx.Commit(ctx)
}
