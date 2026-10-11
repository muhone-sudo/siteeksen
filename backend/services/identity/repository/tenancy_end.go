package repository

// Kiracılığın bitişi (altıncı tur D4, migration 069). Kurallar ve kullanıcı kararları migration başlığındadır.
// Her durum değişikliği aynı işlemde değiştirilemez olay kaydına (tenancy_end_events) yazılır.

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

// ObjectionWindow: yönetim yolunda kiracının itiraz süresi (kullanıcı kararı: 1 hafta).
const ObjectionWindow = 7 * 24 * time.Hour

var (
	// ErrNoActiveTenant: dairede bitirilecek aktif kiracılık yok.
	ErrNoActiveTenant = errors.New("dairede aktif kiracılık yok")
	// ErrEndRequestOpen: bu kiracılık için açık bir bitiş isteği var.
	ErrEndRequestOpen = errors.New("bu kiracılık için yanıt bekleyen bir bitiş isteği zaten var")
	// ErrEndRequestNotFound: istek yok ya da çağıranı ilgilendirmiyor.
	ErrEndRequestNotFound = errors.New("bitiş isteği bulunamadı")
	// ErrEndRequestState: istek bu işlem için uygun durumda değil.
	ErrEndRequestState = errors.New("bitiş isteği bu işlem için uygun durumda değil")
	// ErrObjectionClosed: itiraz süresi doldu.
	ErrObjectionClosed = errors.New("itiraz süresi doldu")
	// ErrWindowOpen: itiraz süresi dolmadan yönetim yolu tamamlanamaz.
	ErrWindowOpen = errors.New("itiraz süresi dolmadan kiracılık bitirilemez")
	// ErrConflictOfInterest: yönetim yolunu dairenin maliki ya da vekili başlatamaz (V2).
	ErrConflictOfInterest = errors.New("bu dairenin maliki ya da vekili olduğunuz için yönetim yolunu siz başlatamazsınız; başka bir yönetici ya da kurul üyesi başlatmalı")
	// ErrNotTenant: çağıran bu kiracılığın kiracısı değil.
	ErrNotTenant = errors.New("bu dairenin aktif kiracısı değilsiniz")
	// ErrNotOwner: çağıran bu dairenin aktif maliki değil.
	ErrNotOwner = errors.New("bu dairenin aktif maliki değilsiniz")
	// ErrTenancyEndFlow: aktif kiracı doğrudan pasifleştirilemez; bitiş akışı kullanılmalı.
	ErrTenancyEndFlow = errors.New("aktif kiracı doğrudan pasifleştirilemez ya da rolü değiştirilemez; kiracılık bitiş akışını kullanın (kiracının onayı, kendi çıkışı ya da yönetim yolu)")
)

// EndRequest, bitiş isteğinin görünümü.
type EndRequest struct {
	ID                string          `json:"id"`
	UnitID            string          `json:"unit_id"`
	Unit              string          `json:"unit"`
	TenantLinkID      string          `json:"tenant_link_id"`
	TenantName        string          `json:"tenant_name"`
	Kind              string          `json:"kind"`
	Status            string          `json:"status"`
	Reason            string          `json:"reason"`
	ObjectionDeadline *time.Time      `json:"objection_deadline,omitempty"`
	EndDate           *time.Time      `json:"end_date,omitempty"`
	CreatedAt         time.Time       `json:"created_at"`
	ClosedAt          *time.Time      `json:"closed_at,omitempty"`
	RequestedBySelf   bool            `json:"requested_by_self"`
	IsTenant          bool            `json:"is_tenant"`
	Documents         []EndDocument   `json:"documents"`
	Events            []EndEvent      `json:"events"`
	Contacts          []ContactTarget `json:"-"`
}

// EndDocument, yönetim yolu belgesinin üst verisi (içerik ayrı uçtan indirilir).
type EndDocument struct {
	ID           string    `json:"id"`
	DocumentKind string    `json:"document_kind"`
	UyapCode     string    `json:"uyap_code,omitempty"`
	FileName     string    `json:"file_name"`
	ContentType  string    `json:"content_type"`
	SizeBytes    int64     `json:"size_bytes"`
	SHA256       string    `json:"sha256"`
	CreatedAt    time.Time `json:"created_at"`
	StorageKey   string    `json:"-"`
}

// EndEvent, olay kaydı satırı.
type EndEvent struct {
	Event     string    `json:"event"`
	Note      string    `json:"note"`
	CreatedAt time.Time `json:"created_at"`
	ByRole    string    `json:"by"` // TENANT | OWNER | MANAGEMENT
}

// ContactTarget, SMS/e-posta ile haber verilecek kişi (yanıta girmez).
type ContactTarget struct {
	Phone, Email string
}

// NewDocument, yüklenen belge (dosya depoya yazılmış olmalı).
type NewDocument struct {
	DocumentKind, UyapCode, StorageKey, FileName, ContentType, SHA256, AttestationText, IP string
	SizeBytes                                                                              int64
}

func addEvent(ctx context.Context, tx pgx.Tx, requestID, event, actorID, note string) error {
	_, err := tx.Exec(ctx, `INSERT INTO tenancy_end_events (request_id, event, actor_id, note) VALUES ($1, $2, $3, $4)`,
		requestID, event, actorID, note)
	return err
}

// activeTenantLink: dairenin aktif kiracı bağı ve kiracı kullanıcı.
func activeTenantLink(ctx context.Context, tx pgx.Tx, propertyID, unitID string) (linkID, tenantID string, err error) {
	err = tx.QueryRow(ctx, `
		SELECT ru.id::text, ru.resident_id::text FROM resident_units ru JOIN units un ON un.id = ru.unit_id
		WHERE ru.unit_id = $1 AND un.property_id = $2 AND ru.role = 'TENANT' AND ru.is_active
		FOR UPDATE OF ru`, unitID, propertyID).Scan(&linkID, &tenantID)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", ErrNoActiveTenant
	}
	return linkID, tenantID, err
}

func isActiveRole(ctx context.Context, tx pgx.Tx, userID, unitID string, roles ...string) (bool, error) {
	var ok bool
	err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM resident_units WHERE resident_id = $1 AND unit_id = $2
		AND is_active AND role = ANY($3))`, userID, unitID, roles).Scan(&ok)
	return ok, err
}

func insertRequest(ctx context.Context, tx pgx.Tx, propertyID, unitID, linkID, kind, status, actorID, reason string, deadline *time.Time) (string, error) {
	var id string
	err := tx.QueryRow(ctx, `
		INSERT INTO tenancy_end_requests (property_id, unit_id, tenant_link_id, kind, status, requested_by, reason, objection_deadline)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id::text`,
		propertyID, unitID, linkID, kind, status, actorID, reason, deadline).Scan(&id)
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" && pg.ConstraintName == "uq_tenancy_end_open" {
		return "", ErrEndRequestOpen
	}
	if err != nil {
		return "", err
	}
	return id, addEvent(ctx, tx, id, "CREATED", actorID, reason)
}

// endTenancyTx, kiracı bağını pasifleştirir (hanesi tetikleyiciyle biter) ve daireyi boş işaretler (V8).
func endTenancyTx(ctx context.Context, tx pgx.Tx, requestID, linkID, actorID, event, note string) error {
	if _, err := tx.Exec(ctx, `SELECT set_config('siteeksen.tenancy_end', 'on', true)`); err != nil {
		return err
	}
	tag, err := tx.Exec(ctx, `UPDATE resident_units SET is_active = false, end_date = CURRENT_DATE WHERE id = $1 AND is_active`, linkID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNoActiveTenant
	}
	if _, err := tx.Exec(ctx, `UPDATE units SET owner_occupied = false, updated_at = now()
		WHERE id = (SELECT unit_id FROM resident_units WHERE id = $1)`, linkID); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'COMPLETED', end_date = CURRENT_DATE,
		closed_by = $2, closed_at = now(), updated_at = now() WHERE id = $1`, requestID, actorID); err != nil {
		return err
	}
	return addEvent(ctx, tx, requestID, event, actorID, note)
}

// ownerContacts / tenantContact: haber verilecek kişiler.
func unitContacts(ctx context.Context, tx pgx.Tx, unitID string, roles ...string) ([]ContactTarget, error) {
	rows, err := tx.Query(ctx, `SELECT u.phone, COALESCE(u.email, '') FROM resident_units ru JOIN users u ON u.id = ru.resident_id
		WHERE ru.unit_id = $1 AND ru.is_active AND ru.role = ANY($2) AND u.deleted = 0`, unitID, roles)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []ContactTarget{}
	for rows.Next() {
		var c ContactTarget
		if err := rows.Scan(&c.Phone, &c.Email); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func userContact(ctx context.Context, tx pgx.Tx, userID string) ([]ContactTarget, error) {
	var c ContactTarget
	if err := tx.QueryRow(ctx, `SELECT phone, COALESCE(email, '') FROM users WHERE id = $1`, userID).Scan(&c.Phone, &c.Email); err != nil {
		return nil, err
	}
	return []ContactTarget{c}, nil
}

func (r *ResidentRepository) begin(ctx context.Context) (pgx.Tx, error) { return r.pool.Begin(ctx) }

// OwnerRequestEnd: malik kiracılığın bitmesini ister; kiracı onaylayana kadar bekler.
func (r *ResidentRepository) OwnerRequestEnd(ctx context.Context, propertyID, ownerID, unitID, reason string) (string, []ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return "", nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if ok, err := isActiveRole(ctx, tx, ownerID, unitID, "OWNER"); err != nil {
		return "", nil, err
	} else if !ok {
		return "", nil, ErrNotOwner
	}
	linkID, tenantID, err := activeTenantLink(ctx, tx, propertyID, unitID)
	if err != nil {
		return "", nil, err
	}
	id, err := insertRequest(ctx, tx, propertyID, unitID, linkID, "OWNER_REQUEST", "PENDING_TENANT", ownerID, reason, nil)
	if err != nil {
		return "", nil, err
	}
	contacts, err := userContact(ctx, tx, tenantID)
	if err != nil {
		return "", nil, err
	}
	return id, contacts, tx.Commit(ctx)
}

// TenantExit: kiracı kendi çıkışını bildirir (V1); kiracılık hemen biter.
func (r *ResidentRepository) TenantExit(ctx context.Context, propertyID, tenantID, unitID, reason string) (string, []ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return "", nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	linkID, current, err := activeTenantLink(ctx, tx, propertyID, unitID)
	if errors.Is(err, ErrNoActiveTenant) || (err == nil && current != tenantID) {
		return "", nil, ErrNotTenant
	}
	if err != nil {
		return "", nil, err
	}
	// Açık bir istek (malik isteği ya da yönetim yolu) varsa kiracının çıkışı onu da kapatır.
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'CANCELLED', closed_by = $2, closed_at = now(), updated_at = now()
		WHERE tenant_link_id = $1 AND status IN ('PENDING_TENANT', 'OBJECTION_WINDOW', 'SUSPENDED')`, linkID, tenantID); err != nil {
		return "", nil, err
	}
	id, err := insertRequest(ctx, tx, propertyID, unitID, linkID, "TENANT_EXIT", "PENDING_TENANT", tenantID, reason, nil)
	if err != nil {
		return "", nil, err
	}
	if err := endTenancyTx(ctx, tx, id, linkID, tenantID, "COMPLETED", "Kiracı çıkışını bildirdi"); err != nil {
		return "", nil, err
	}
	contacts, err := unitContacts(ctx, tx, unitID, "OWNER", "PROXY")
	if err != nil {
		return "", nil, err
	}
	return id, contacts, tx.Commit(ctx)
}

// lockRequest: isteği kilitleyip okur.
func lockRequest(ctx context.Context, tx pgx.Tx, id string) (propertyID, unitID, linkID, tenantID, kind, status, requestedBy string, deadline *time.Time, err error) {
	err = tx.QueryRow(ctx, `
		SELECT r.property_id::text, r.unit_id::text, r.tenant_link_id::text, ru.resident_id::text, r.kind, r.status,
		       r.requested_by::text, r.objection_deadline
		FROM tenancy_end_requests r JOIN resident_units ru ON ru.id = r.tenant_link_id
		WHERE r.id = $1 FOR UPDATE OF r`, id).Scan(&propertyID, &unitID, &linkID, &tenantID, &kind, &status, &requestedBy, &deadline)
	if errors.Is(err, pgx.ErrNoRows) {
		err = ErrEndRequestNotFound
	}
	return
}

// TenantRespond: kiracı malik isteğini onaylar/reddeder; askıdaki yönetim yolunu onaylayarak da bitirebilir.
func (r *ResidentRepository) TenantRespond(ctx context.Context, tenantID, id string, approve bool, note string) ([]ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	_, unitID, linkID, owner, kind, status, _, _, err := lockRequest(ctx, tx, id)
	if err != nil {
		return nil, err
	}
	if owner != tenantID {
		return nil, ErrEndRequestNotFound
	}
	switch {
	case approve && (status == "PENDING_TENANT" || (kind == "MANAGEMENT" && (status == "SUSPENDED" || status == "OBJECTION_WINDOW"))):
		if err := endTenancyTx(ctx, tx, id, linkID, tenantID, "APPROVED", note); err != nil {
			return nil, err
		}
	case !approve && status == "PENDING_TENANT" && kind == "OWNER_REQUEST":
		if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'REJECTED', closed_by = $2, closed_at = now(), updated_at = now()
			WHERE id = $1`, id, tenantID); err != nil {
			return nil, err
		}
		if err := addEvent(ctx, tx, id, "DECLINED", tenantID, note); err != nil {
			return nil, err
		}
	default:
		return nil, ErrEndRequestState
	}
	contacts, err := unitContacts(ctx, tx, unitID, "OWNER", "PROXY")
	if err != nil {
		return nil, err
	}
	return contacts, tx.Commit(ctx)
}

// TenantObject: kiracı yönetim yoluna itiraz süresi içinde itiraz eder; işlem askıya alınır.
func (r *ResidentRepository) TenantObject(ctx context.Context, tenantID, id, reason string) error {
	tx, err := r.begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	_, _, _, owner, kind, status, _, deadline, err := lockRequest(ctx, tx, id)
	if err != nil {
		return err
	}
	if owner != tenantID {
		return ErrEndRequestNotFound
	}
	if kind != "MANAGEMENT" || status != "OBJECTION_WINDOW" {
		return ErrEndRequestState
	}
	if deadline != nil && time.Now().After(*deadline) {
		return ErrObjectionClosed
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'SUSPENDED', updated_at = now() WHERE id = $1`, id); err != nil {
		return err
	}
	if err := addEvent(ctx, tx, id, "OBJECTED", tenantID, reason); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// OwnerCancel: malik kendi bekleyen isteğini geri çeker.
func (r *ResidentRepository) OwnerCancel(ctx context.Context, ownerID, id string) error {
	tx, err := r.begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	_, _, _, _, kind, status, requestedBy, _, err := lockRequest(ctx, tx, id)
	if err != nil {
		return err
	}
	if requestedBy != ownerID {
		return ErrEndRequestNotFound
	}
	if kind != "OWNER_REQUEST" || status != "PENDING_TENANT" {
		return ErrEndRequestState
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'CANCELLED', closed_by = $2, closed_at = now(), updated_at = now()
		WHERE id = $1`, id, ownerID); err != nil {
		return err
	}
	if err := addEvent(ctx, tx, id, "CANCELLED", ownerID, ""); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func insertDocument(ctx context.Context, tx pgx.Tx, requestID, actorID string, d NewDocument) error {
	if _, err := tx.Exec(ctx, `
		INSERT INTO tenancy_end_documents (request_id, document_kind, uyap_code, storage_key, file_name, content_type,
		                                   size_bytes, sha256, uploaded_by, attestation_text, attested_ip)
		VALUES ($1, $2, NULLIF($3, ''), $4, $5, $6, $7, $8, $9, $10, $11)`,
		requestID, d.DocumentKind, d.UyapCode, d.StorageKey, d.FileName, d.ContentType, d.SizeBytes, d.SHA256,
		actorID, d.AttestationText, d.IP); err != nil {
		return err
	}
	return addEvent(ctx, tx, requestID, "DOCUMENT_ADDED", actorID, d.DocumentKind)
}

// ManagementStart: yönetim yolunu belgeyle başlatır; 7 günlük itiraz penceresi açılır.
func (r *ResidentRepository) ManagementStart(ctx context.Context, propertyID, actorID, unitID, reason string, d NewDocument) (string, []ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return "", nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if conflict, err := isActiveRole(ctx, tx, actorID, unitID, "OWNER", "PROXY"); err != nil {
		return "", nil, err
	} else if conflict {
		return "", nil, ErrConflictOfInterest
	}
	linkID, tenantID, err := activeTenantLink(ctx, tx, propertyID, unitID)
	if err != nil {
		return "", nil, err
	}
	deadline := time.Now().Add(ObjectionWindow)
	id, err := insertRequest(ctx, tx, propertyID, unitID, linkID, "MANAGEMENT", "OBJECTION_WINDOW", actorID, reason, &deadline)
	if err != nil {
		return "", nil, err
	}
	if err := insertDocument(ctx, tx, id, actorID, d); err != nil {
		return "", nil, err
	}
	contacts, err := userContact(ctx, tx, tenantID)
	if err != nil {
		return "", nil, err
	}
	return id, contacts, tx.Commit(ctx)
}

// ManagementNewDocument: askıdaki (ya da penceredeki) yönetim yoluna yeni belge; yeni 7 günlük pencere başlar.
func (r *ResidentRepository) ManagementNewDocument(ctx context.Context, propertyID, actorID, id string, d NewDocument) ([]ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	prop, unitID, _, tenantID, kind, status, _, _, err := lockRequest(ctx, tx, id)
	if err != nil {
		return nil, err
	}
	if prop != propertyID {
		return nil, ErrEndRequestNotFound
	}
	if kind != "MANAGEMENT" || (status != "SUSPENDED" && status != "OBJECTION_WINDOW") {
		return nil, ErrEndRequestState
	}
	if conflict, err := isActiveRole(ctx, tx, actorID, unitID, "OWNER", "PROXY"); err != nil {
		return nil, err
	} else if conflict {
		return nil, ErrConflictOfInterest
	}
	if err := insertDocument(ctx, tx, id, actorID, d); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'OBJECTION_WINDOW', objection_deadline = $2, updated_at = now()
		WHERE id = $1`, id, time.Now().Add(ObjectionWindow)); err != nil {
		return nil, err
	}
	contacts, err := userContact(ctx, tx, tenantID)
	if err != nil {
		return nil, err
	}
	return contacts, tx.Commit(ctx)
}

// ManagementComplete: itiraz süresi itirazsız dolan yönetim yolunu tamamlar.
func (r *ResidentRepository) ManagementComplete(ctx context.Context, propertyID, actorID, id string) ([]ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	prop, unitID, linkID, tenantID, kind, status, _, deadline, err := lockRequest(ctx, tx, id)
	if err != nil {
		return nil, err
	}
	if prop != propertyID {
		return nil, ErrEndRequestNotFound
	}
	if kind != "MANAGEMENT" || status != "OBJECTION_WINDOW" {
		return nil, ErrEndRequestState
	}
	if deadline == nil || time.Now().Before(*deadline) {
		return nil, ErrWindowOpen
	}
	if conflict, err := isActiveRole(ctx, tx, actorID, unitID, "OWNER", "PROXY"); err != nil {
		return nil, err
	} else if conflict {
		return nil, ErrConflictOfInterest
	}
	contacts, err := userContact(ctx, tx, tenantID)
	if err != nil {
		return nil, err
	}
	if err := endTenancyTx(ctx, tx, id, linkID, actorID, "COMPLETED", "İtiraz süresi itirazsız doldu"); err != nil {
		return nil, err
	}
	return contacts, tx.Commit(ctx)
}

// ManagementCancel: yönetim kendi başlattığı (ya da herhangi bir) açık yönetim yolunu iptal eder.
func (r *ResidentRepository) ManagementCancel(ctx context.Context, propertyID, actorID, id, note string) error {
	tx, err := r.begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	prop, _, _, _, kind, status, _, _, err := lockRequest(ctx, tx, id)
	if err != nil {
		return err
	}
	if prop != propertyID {
		return ErrEndRequestNotFound
	}
	if kind != "MANAGEMENT" || (status != "OBJECTION_WINDOW" && status != "SUSPENDED") {
		return ErrEndRequestState
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'CANCELLED', closed_by = $2, closed_at = now(), updated_at = now()
		WHERE id = $1`, id, actorID); err != nil {
		return err
	}
	if err := addEvent(ctx, tx, id, "CANCELLED", actorID, note); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ManagementReverse: yönetim yoluyla biten kiracılığı geri açar (belge sahte çıktı). Kiracı bağı aynı kayıtla,
// geçmişiyle yeniden etkinleşir; dairede bu arada başka kiracı varsa geri alınamaz.
func (r *ResidentRepository) ManagementReverse(ctx context.Context, propertyID, actorID, id, reason string) ([]ContactTarget, error) {
	tx, err := r.begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	prop, _, linkID, tenantID, kind, status, _, _, err := lockRequest(ctx, tx, id)
	if err != nil {
		return nil, err
	}
	if prop != propertyID {
		return nil, ErrEndRequestNotFound
	}
	if kind != "MANAGEMENT" || status != "COMPLETED" {
		return nil, ErrEndRequestState
	}
	_, err = tx.Exec(ctx, `UPDATE resident_units SET is_active = true, end_date = NULL WHERE id = $1`, linkID)
	if isTenantConflict(err) {
		return nil, ErrUnitHasTenant
	}
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE tenancy_end_requests SET status = 'REVERSED', closed_by = $2, closed_at = now(), updated_at = now()
		WHERE id = $1`, id, actorID); err != nil {
		return nil, err
	}
	if err := addEvent(ctx, tx, id, "REVERSED", actorID, reason); err != nil {
		return nil, err
	}
	contacts, err := userContact(ctx, tx, tenantID)
	if err != nil {
		return nil, err
	}
	return contacts, tx.Commit(ctx)
}

const endRequestSelect = `
	SELECT r.id::text, r.unit_id::text, COALESCE(NULLIF(un.block, ''), '') || '-' || un.door_number, r.tenant_link_id::text,
	       tu.first_name || ' ' || tu.last_name, r.kind, r.status, r.reason, r.objection_deadline, r.end_date,
	       r.created_at, r.closed_at, COALESCE(r.requested_by = NULLIF($1, '')::uuid, false),
	       COALESCE(ru.resident_id = NULLIF($1, '')::uuid, false)
	FROM tenancy_end_requests r
	JOIN units un ON un.id = r.unit_id
	JOIN resident_units ru ON ru.id = r.tenant_link_id
	JOIN users tu ON tu.id = ru.resident_id`

func (r *ResidentRepository) queryEndRequests(ctx context.Context, viewerID, where string, args ...any) ([]*EndRequest, error) {
	rows, err := r.pool.Query(ctx, endRequestSelect+" WHERE "+where+" ORDER BY r.created_at DESC LIMIT 200", append([]any{viewerID}, args...)...)
	if err != nil {
		return nil, err
	}
	out := []*EndRequest{}
	for rows.Next() {
		e := &EndRequest{Documents: []EndDocument{}, Events: []EndEvent{}}
		if err := rows.Scan(&e.ID, &e.UnitID, &e.Unit, &e.TenantLinkID, &e.TenantName, &e.Kind, &e.Status, &e.Reason,
			&e.ObjectionDeadline, &e.EndDate, &e.CreatedAt, &e.ClosedAt, &e.RequestedBySelf, &e.IsTenant); err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, e)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for _, e := range out {
		if e.Documents, err = r.endDocuments(ctx, e.ID); err != nil {
			return nil, err
		}
		if e.Events, err = r.endEvents(ctx, e.ID); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (r *ResidentRepository) endDocuments(ctx context.Context, requestID string) ([]EndDocument, error) {
	rows, err := r.pool.Query(ctx, `SELECT id::text, document_kind, COALESCE(uyap_code, ''), file_name, content_type, size_bytes,
		sha256, created_at, storage_key FROM tenancy_end_documents WHERE request_id = $1 ORDER BY created_at`, requestID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []EndDocument{}
	for rows.Next() {
		var d EndDocument
		if err := rows.Scan(&d.ID, &d.DocumentKind, &d.UyapCode, &d.FileName, &d.ContentType, &d.SizeBytes, &d.SHA256,
			&d.CreatedAt, &d.StorageKey); err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

func (r *ResidentRepository) endEvents(ctx context.Context, requestID string) ([]EndEvent, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT e.event, e.note, e.created_at,
		       CASE WHEN e.actor_id = ru.resident_id THEN 'TENANT'
		            WHEN EXISTS (SELECT 1 FROM resident_units o WHERE o.unit_id = r.unit_id AND o.resident_id = e.actor_id
		                         AND o.role IN ('OWNER', 'PROXY')) AND r.kind = 'OWNER_REQUEST' THEN 'OWNER'
		            ELSE 'MANAGEMENT' END
		FROM tenancy_end_events e
		JOIN tenancy_end_requests r ON r.id = e.request_id
		JOIN resident_units ru ON ru.id = r.tenant_link_id
		WHERE e.request_id = $1 ORDER BY e.created_at`, requestID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []EndEvent{}
	for rows.Next() {
		var ev EndEvent
		if err := rows.Scan(&ev.Event, &ev.Note, &ev.CreatedAt, &ev.ByRole); err != nil {
			return nil, err
		}
		out = append(out, ev)
	}
	return out, rows.Err()
}

// EndRequestsForUser: kişinin kiracısı olduğu ya da maliki/vekili olduğu dairelerin bitiş istekleri (aktif sitede).
func (r *ResidentRepository) EndRequestsForUser(ctx context.Context, propertyID, userID string) ([]*EndRequest, error) {
	return r.queryEndRequests(ctx, userID, `r.property_id = $2 AND (ru.resident_id = NULLIF($1, '')::uuid
		OR EXISTS (SELECT 1 FROM resident_units o WHERE o.unit_id = r.unit_id AND o.resident_id = NULLIF($1, '')::uuid
		           AND o.is_active AND o.role IN ('OWNER', 'PROXY')))`, propertyID)
}

// EndRequestsForProperty: yönetim görünümü.
func (r *ResidentRepository) EndRequestsForProperty(ctx context.Context, propertyID string) ([]*EndRequest, error) {
	return r.queryEndRequests(ctx, "", `r.property_id = $2`, propertyID)
}

// EndDocumentFor: belgeyi okur. Kiracı kendi kiracılığının, yönetim sitesinin belgesini görür.
func (r *ResidentRepository) EndDocumentFor(ctx context.Context, propertyID, userID, requestID, documentID string, management bool) (*EndDocument, error) {
	var d EndDocument
	err := r.pool.QueryRow(ctx, `
		SELECT d.id::text, d.document_kind, COALESCE(d.uyap_code, ''), d.file_name, d.content_type, d.size_bytes, d.sha256,
		       d.created_at, d.storage_key
		FROM tenancy_end_documents d
		JOIN tenancy_end_requests r ON r.id = d.request_id
		JOIN resident_units ru ON ru.id = r.tenant_link_id
		WHERE d.id = $1 AND r.id = $2 AND r.property_id = $3 AND ($5 OR ru.resident_id = $4)`,
		documentID, requestID, propertyID, userID, management).
		Scan(&d.ID, &d.DocumentKind, &d.UyapCode, &d.FileName, &d.ContentType, &d.SizeBytes, &d.SHA256, &d.CreatedAt, &d.StorageKey)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrEndRequestNotFound
	}
	return &d, err
}

// LinkRole: daire bağının rolü ve aktifliği (doğrudan güncellemeyi bitiş akışına yönlendirmek için).
func (r *ResidentRepository) LinkRole(ctx context.Context, propertyID, residentUnitID string) (role string, active bool, err error) {
	err = r.pool.QueryRow(ctx, `SELECT ru.role, COALESCE(ru.is_active, false) FROM resident_units ru JOIN units un ON un.id = ru.unit_id
		WHERE ru.id = $1 AND un.property_id = $2`, residentUnitID, propertyID).Scan(&role, &active)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", false, ErrResidentNotFound
	}
	return role, active, err
}
