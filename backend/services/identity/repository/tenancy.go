package repository

// Kayıt ve davet kuralları (altıncı tur D3, migration 068).
//
// Kullanıcı kararları (2026-10-11):
//   - Kiracıyı malik ya da yönetim davet eder; yönetim doğrudan da kaydeder. Dairede aktif kiracı varken
//     kiracı daveti de kaydı da yapılamaz (yönetim dahil). Dairede aynı anda tek bekleyen kiracı daveti olur.
//   - Davet edilen kişinin hesabı yoksa hesap HEMEN açılır; etkinleştirme kodunu girince davet kabul edilir.
//   - Hane üyesini dairede oturan ve yönetim ekler; dairede oturan yoksa hane üyesi eklenmez.
//   - Malik yalnız maliki kayıtlı olmayan (kiracıyla kayıtlı) daireye davet edilir.
// Kurallar kabul anında yeniden denetlenir: davetten sonra dairenin durumu değişmiş olabilir.

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/siteeksen/backend/services/identity/models"
)

var (
	// ErrUnitHasTenant: dairede aktif kiracı var; yeni kiracı ancak kiracılık bittikten sonra gelir.
	ErrUnitHasTenant = errors.New("dairede aktif bir kiracı var; yeni kiracı ancak mevcut kiracılık bittikten sonra eklenebilir")
	// ErrTenantInvitePending: daire için yanıt bekleyen bir kiracı daveti var.
	ErrTenantInvitePending = errors.New("bu daire için yanıt bekleyen bir kiracı daveti zaten var; önce onu iptal edin")
	// ErrUnitHasOwner: malik daveti yalnız maliki kayıtlı olmayan daireye gönderilir.
	ErrUnitHasOwner = errors.New("bu dairenin kayıtlı maliki var; malik daveti yalnız yalnızca kiracıyla kayıtlı daireye gönderilir")
	// ErrNoOccupant: hane üyesi, dairede oturan (kiracı ya da oturan malik) varken eklenir.
	ErrNoOccupant = errors.New("dairede oturan yok (boş ya da kayıtsız); hane üyesi ancak oturanın hanesine eklenir")
	// ErrAlreadyLinked: kişi bu daireye bu sıfatla zaten kayıtlı.
	ErrAlreadyLinked = errors.New("bu kişi bu daireye bu sıfatla zaten kayıtlı")
)

// isTenantConflict, tek aktif kiracı kısıtının ihlali mi.
func isTenantConflict(err error) bool {
	var pg *pgconn.PgError
	return errors.As(err, &pg) && pg.Code == "23505" && pg.ConstraintName == "uq_resident_units_one_active_tenant"
}

// UnitOccupancy, dairenin oturum durumu ve aktif malik sayısı (067).
func unitOccupancy(ctx context.Context, q pgx.Tx, propertyID, unitID string) (occupancy string, owners int, err error) {
	err = q.QueryRow(ctx, `
		SELECT unit_occupancy(un.id),
		       (SELECT count(*) FROM resident_units r WHERE r.unit_id = un.id AND r.is_active AND r.role = 'OWNER')
		FROM units un WHERE un.id = $1 AND un.property_id = $2 AND un.deleted = 0
		FOR UPDATE OF un`, unitID, propertyID).Scan(&occupancy, &owners)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", 0, ErrUnitNotFound
	}
	return occupancy, owners, err
}

// checkLinkRule, rolün daireye bağlanma kuralı (davet açılırken ve kabul edilirken).
func checkLinkRule(occupancy string, owners int, role string, inviting bool) error {
	switch role {
	case "TENANT":
		if occupancy == "TENANT_OCCUPIED" {
			return ErrUnitHasTenant
		}
	case "HOUSEHOLD":
		if occupancy != "TENANT_OCCUPIED" && occupancy != "OWNER_OCCUPIED" {
			return ErrNoOccupant
		}
	case "OWNER":
		if inviting && owners > 0 {
			return ErrUnitHasOwner
		}
	}
	return nil
}

// UnitRelation, kişinin dairedeki aktif sıfatları ve dairenin oturum durumu (davet yetkisi için).
func (r *ResidentRepository) UnitRelation(ctx context.Context, propertyID, userID, unitID string) (isOwner, isTenant bool, occupancy string, err error) {
	err = r.pool.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = un.id AND ru.resident_id = $3 AND ru.is_active AND ru.role = 'OWNER'),
		       EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = un.id AND ru.resident_id = $3 AND ru.is_active AND ru.role = 'TENANT'),
		       unit_occupancy(un.id)
		FROM units un WHERE un.id = $1 AND un.property_id = $2 AND un.deleted = 0`, unitID, propertyID, userID).
		Scan(&isOwner, &isTenant, &occupancy)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, false, "", ErrUnitNotFound
	}
	return isOwner, isTenant, occupancy, err
}

// InvitationResult, davet açma sonucu.
type InvitationResult struct {
	Invitation   *models.Invitation
	UserID       string
	NewAccount   bool
	PropertyName string
}

// CreateInvitation, daire daveti açar (tek işlem). Kişinin hesabı yoksa kullanılamaz parola özetiyle hesap
// açılır (kod ayrıca üretilir). invitedAs: MANAGEMENT | OWNER | OCCUPANT.
func (r *ResidentRepository) CreateInvitation(ctx context.Context, propertyID, actorID, invitedAs, passwordHash string, in models.CreateResidentInput) (*InvitationResult, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	occupancy, owners, err := unitOccupancy(ctx, tx, propertyID, in.UnitID)
	if err != nil {
		return nil, err
	}
	if err := checkLinkRule(occupancy, owners, in.Role, true); err != nil {
		return nil, err
	}

	out := &InvitationResult{}
	var linked bool
	err = tx.QueryRow(ctx, `SELECT id FROM users WHERE phone = $1 AND deleted = 0`, in.Phone).Scan(&out.UserID)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		if in.FirstName == "" || in.LastName == "" {
			return nil, ErrNameRequiredNew
		}
		out.NewAccount = true
		if err := tx.QueryRow(ctx, `
			INSERT INTO users (first_name, last_name, phone, email, password_hash, roles)
			VALUES ($1, $2, $3, NULLIF($4, ''), $5, ARRAY['RESIDENT']) RETURNING id`,
			in.FirstName, in.LastName, in.Phone, in.Email, passwordHash).Scan(&out.UserID); err != nil {
			return nil, err
		}
	case err != nil:
		return nil, err
	default:
		if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM resident_units
			WHERE resident_id = $1 AND unit_id = $2 AND role = $3 AND is_active)`, out.UserID, in.UnitID, in.Role).Scan(&linked); err != nil {
			return nil, err
		}
		if linked {
			return nil, ErrAlreadyLinked
		}
	}

	// Süresi dolmuş bekleyen davetler kalıcı olarak kapatılır (yenisine yer açılır).
	if _, err := tx.Exec(ctx, `
		UPDATE resident_invitations SET status = 'EXPIRED'
		WHERE status = 'PENDING' AND expires_at <= now()
		  AND ((user_id = $1 AND unit_id = $2 AND role = $3) OR (unit_id = $2 AND role = 'TENANT' AND $3 = 'TENANT'))`,
		out.UserID, in.UnitID, in.Role); err != nil {
		return nil, err
	}
	var invID string
	err = tx.QueryRow(ctx, `
		INSERT INTO resident_invitations (property_id, unit_id, user_id, role, invited_by, invited_as)
		VALUES ($1, $2, $3, $4, NULLIF($5, '')::uuid, $6)
		RETURNING id`, propertyID, in.UnitID, out.UserID, in.Role, actorID, invitedAs).Scan(&invID)
	if err != nil {
		var pg *pgconn.PgError
		if errors.As(err, &pg) && pg.Code == "23505" {
			if pg.ConstraintName == "uq_resident_invitations_unit_tenant_pending" {
				return nil, ErrTenantInvitePending
			}
			return nil, ErrInvitationPending
		}
		return nil, err
	}
	if err := tx.QueryRow(ctx, `SELECT name FROM properties WHERE id = $1`, propertyID).Scan(&out.PropertyName); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	out.Invitation, err = r.getInvitation(ctx, propertyID, invID)
	return out, err
}

// linkResidentTx, daire bağını kurar (kabul ya da kayıt). Önceden pasifleşmiş aynı bağ yeniden etkinleşir.
// Kiracı gelince malikin hanesinin kaydı veritabanı tetikleyicisiyle biter (068).
func linkResidentTx(ctx context.Context, tx pgx.Tx, propertyID, userID, unitID, role string) (string, error) {
	occupancy, owners, err := unitOccupancy(ctx, tx, propertyID, unitID)
	if err != nil {
		return "", err
	}
	if err := checkLinkRule(occupancy, owners, role, false); err != nil {
		return "", err
	}
	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO resident_units (resident_id, unit_id, role)
		VALUES ($1, $2, $3)
		ON CONFLICT (resident_id, unit_id, role)
		DO UPDATE SET is_active = true, end_date = NULL, start_date = CURRENT_DATE
		RETURNING id`, userID, unitID, role).Scan(&id)
	if isTenantConflict(err) {
		return "", ErrUnitHasTenant
	}
	return id, err
}

// AcceptPendingFor, kişinin bekleyen (süresi dolmamış) bütün davetlerini kabul etmeyi dener: hesabını
// etkinleştiren davetli kodu girdiğinde daireye bağlanır (D3 kararı). Kabul edilemeyen davet bekler; neden döner.
func (r *ResidentRepository) AcceptPendingFor(ctx context.Context, userID string) (accepted int, failed map[string]string, err error) {
	rows, err := r.pool.Query(ctx, `SELECT id::text FROM resident_invitations
		WHERE user_id = $1 AND status = 'PENDING' AND expires_at > now() ORDER BY created_at`, userID)
	if err != nil {
		return 0, nil, err
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return 0, nil, err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, nil, err
	}
	failed = map[string]string{}
	for _, id := range ids {
		if _, err := r.RespondInvitation(ctx, userID, id, true); err != nil {
			failed[id] = err.Error()
			continue
		}
		accepted++
	}
	return accepted, failed, nil
}
