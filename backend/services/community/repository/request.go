package repository

import (
	"context"
	"errors"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/services/community/models"
)

// ErrRequestNotFound talep bulunamadığında döner
var ErrRequestNotFound = errors.New("talep bulunamadı")

// ErrStatusChanged talep, durumu okunduktan sonra başka bir istekle değişti.
var ErrStatusChanged = errors.New("talebin durumu bu sırada değişti")

// ErrUnitNotYours talepte belirtilen daire çağıranın bu sitedeki aktif dairesi değil.
var ErrUnitNotYours = errors.New("belirtilen daire size ait değil")

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
func (r *RequestRepository) ListByResident(ctx context.Context, propertyID, residentID, status string) ([]*models.Request, error) {
	query := `SELECT ` + requestColumns + ` FROM requests WHERE resident_id = $1`
	args := []interface{}{residentID}
	if status != "" {
		query += ` AND status = $2`
		args = append(args, status)
	}
	query += ` ORDER BY created_at DESC`
	return r.list(ctx, propertyID, query, args...)
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
	return r.list(ctx, propertyID, query, args...)
}

func (r *RequestRepository) list(ctx context.Context, propertyID, query string, args ...interface{}) ([]*models.Request, error) {
	rows, err := r.scope(propertyID).Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	requests := []*models.Request{}
	for rows.Next() {
		req, err := scanRequest(rows)
		if err != nil {
			return nil, err
		}
		requests = append(requests, req)
	}
	return requests, rows.Err()
}

// GetByID ID'ye göre talep getirir.
//
// GÜVENLİK (2026-09-14): sorguya `property_id` filtresi EKLENDİ. Önceden
// yalnızca kimliğe bakılıyordu; A sitesinin yöneticisi, B sitesindeki bir
// talebin kimliğini bildiği takdirde onu okuyabiliyor ve UpdateStatus ile
// ilerletebiliyordu. Filtre uygulama katmanında; satır düzeyi güvenliği de
// aynı sonucu veritabanında zorlar (migration 023).
func (r *RequestRepository) GetByID(ctx context.Context, propertyID, id string) (*models.Request, error) {
	// Biçimi geçersiz kimlik veritabanına gitmez: PostgreSQL onu tür hatası
	// olarak reddeder ve istemci "bulunamadı" yerine 500 görürdü.
	if _, err := uuid.Parse(id); err != nil {
		return nil, ErrRequestNotFound
	}
	query := `SELECT ` + requestColumns + ` FROM requests WHERE id = $1 AND property_id = $2`
	req, err := scanRequest(r.scope(propertyID).QueryRow(ctx, query, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRequestNotFound
	}
	if err != nil {
		return nil, err
	}
	return req, nil
}

// Create yeni talep oluşturur
//
// DAİRE (2026-10-03, B63): `unit_id` önceden HİÇ yazılmıyordu; daire bazlı talep
// raporu ve "bu dairenin açık talepleri" sorusu yanıtlanamıyordu. Daire,
// çağıranın bu sitedeki AKTİF dairelerinden çözülür (başkasının dairesine talep
// bağlanamaz). Birden çok dairesi olan ve daire belirtmeyen ya da hiç dairesi
// olmayan çağıranın (ortak alan bildiren görevli/yönetici) talebi dairesiz kalır.
func (r *RequestRepository) Create(ctx context.Context, propertyID, residentID, ticketNumber string, input models.CreateRequestInput) (*models.Request, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	rows, err := tx.Query(ctx, `
		SELECT ru.unit_id::text
		FROM resident_units ru JOIN units un ON un.id = ru.unit_id
		WHERE ru.resident_id = $1 AND ru.is_active = true AND un.property_id = $2
		GROUP BY ru.unit_id`, residentID, propertyID)
	if err != nil {
		return nil, err
	}
	mine, err := pgx.CollectRows(rows, pgx.RowTo[string])
	if err != nil {
		return nil, err
	}
	var unitID *string
	if want := strings.TrimSpace(input.UnitID); want != "" {
		for i := range mine {
			if mine[i] == want {
				unitID = &mine[i]
			}
		}
		if unitID == nil {
			return nil, ErrUnitNotYours
		}
	} else if len(mine) == 1 {
		unitID = &mine[0]
	}

	query := `
		INSERT INTO requests (property_id, resident_id, unit_id, category_id, ticket_number, title, description, location, priority, photo_urls, status)
		VALUES ($1, $2, $10::uuid, NULLIF($3, '')::uuid, $4, $5, $6, $7, COALESCE(NULLIF($8, ''), 'NORMAL'), $9, 'OPEN')
		RETURNING ` + requestColumns

	req, err := scanRequest(tx.QueryRow(ctx, query,
		propertyID, residentID, input.CategoryID, ticketNumber, input.Title, input.Description,
		input.Location, input.Priority, input.Photos, unitID,
	))
	if err != nil {
		return nil, err
	}
	return req, tx.Commit(ctx)
}

// UpdateStatus yönetici tarafından talep durumunu günceller (OPEN -> IN_PROGRESS -> RESOLVED).
//
// KARŞILAŞTIR-VE-DEĞİŞTİR (2026-10-03, B65): servis geçişi okuduğu duruma göre
// denetler; UPDATE durum koşulu taşımazsa arada başka bir istek durumu
// değiştirdiğinde geçersiz bir geçiş sessizce yazılırdı. Satır `from` durumunda
// değilse hiçbir şey yazılmaz ve ErrStatusChanged döner.
func (r *RequestRepository) UpdateStatus(ctx context.Context, propertyID, id, from, status string) (*models.Request, error) {
	var query string
	switch status {
	case models.StatusResolved:
		query = `UPDATE requests SET status = $2, resolved_at = NOW(), updated_at = NOW() WHERE id = $1 AND property_id = $3 AND status = $4 RETURNING ` + requestColumns
	default:
		query = `UPDATE requests SET status = $2, updated_at = NOW() WHERE id = $1 AND property_id = $3 AND status = $4 RETURNING ` + requestColumns
	}

	row := r.scope(propertyID).QueryRow(ctx, query, id, status, propertyID, from)
	req, err := scanRequest(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrStatusChanged
	}
	return req, err
}

// ConfirmResolution sakin onayı: onaylarsa CLOSED + user_confirmed_at, reddederse IN_PROGRESS'e döner
// Durum hâlâ RESOLVED ve talep hâlâ bu sakinin ise yazılır (B65; çift dokunmada
// onay ile ret yarışırsa ikincisi ErrStatusChanged alır).
func (r *RequestRepository) ConfirmResolution(ctx context.Context, propertyID, id, residentID string, approved bool) (*models.Request, error) {
	var query string
	if approved {
		query = `
			UPDATE requests
			SET status = 'CLOSED', user_confirmed_at = NOW(), closed_at = NOW(), updated_at = NOW()
			WHERE id = $1 AND property_id = $2 AND status = 'RESOLVED' AND resident_id = $3
			RETURNING ` + requestColumns
	} else {
		query = `
			UPDATE requests
			SET status = 'IN_PROGRESS', resolved_at = NULL, updated_at = NOW()
			WHERE id = $1 AND property_id = $2 AND status = 'RESOLVED' AND resident_id = $3
			RETURNING ` + requestColumns
	}

	row := r.scope(propertyID).QueryRow(ctx, query, id, propertyID, residentID)
	req, err := scanRequest(row)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrStatusChanged
	}
	return req, err
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `requests` tablosunda RLS açıktır (migration 023). Uygulama katmanındaki
// `property_id` filtresinin yerine geçmez; onu YEDEKLER. Bu modülde yedeğin
// değeri somuttur: filtre üç sorguda hiç yoktu ve bunu yakalayan bir şey
// yoktu.
func (r *RequestRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
