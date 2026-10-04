package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Tadilat izni hataları.
var (
	ErrRenovationNotFound = errors.New("tadilat izni bulunamadı")
	// ErrRenovationState: izin bu işlem için uygun durumda değil.
	ErrRenovationState = errors.New("tadilat izni bu işlem için uygun durumda değil")
	// ErrNotOwnerOfUnit: başvuran, bölümün aktif maliki ya da vekili değil.
	ErrNotOwnerOfUnit = errors.New("başvuru yalnızca bölümün maliki ya da vekili tarafından yapılabilir")
	// ErrNotPropertyOwner: rıza veren kişi sitenin aktif kat maliki değil.
	ErrNotPropertyOwner = errors.New("rıza veren kişi bu sitenin kat maliki değil")
	// ErrConsentNotApplicable: rıza yalnızca ortak yer / dış cephe başvurusunda kaydedilir.
	ErrConsentNotApplicable = errors.New("rıza yalnızca ortak yer ve dış cephe başvurularında kaydedilir")
	ErrConsentDuplicate     = errors.New("bu kat malikinin rızası zaten kayıtlı")

	RenovationScopes = []string{"INTERIOR", "STRUCTURAL", "COMMON_AREA", "FACADE"}
)

// RenovationPermit, tadilat izni kaydıdır (migration 037).
type RenovationPermit struct {
	ID              string     `json:"id"`
	UnitID          string     `json:"unit_id"`
	Unit            string     `json:"unit"`
	Block           string     `json:"-"`
	ApplicantID     string     `json:"applicant_id"`
	ApplicantName   string     `json:"applicant_name"`
	Scope           string     `json:"scope"`
	Description     string     `json:"description"`
	ContractorName  string     `json:"contractor_name,omitempty"`
	ContractorPhone string     `json:"contractor_phone,omitempty"`
	StartDate       time.Time  `json:"start_date"`
	EndDate         time.Time  `json:"end_date"`
	Status          string     `json:"status"`
	WorkHours       string     `json:"work_hours,omitempty"`
	Conditions      string     `json:"conditions,omitempty"`
	DepositAmount   float64    `json:"deposit_amount"`
	DepositRefunded *float64   `json:"deposit_refunded,omitempty"`
	PermitRef       string     `json:"permit_ref,omitempty"`
	AgendaItemID    string     `json:"agenda_item_id,omitempty"`
	ConsentRequired *int       `json:"consent_required,omitempty"`
	ConsentCount    int        `json:"consent_count"`
	DecisionNote    string     `json:"decision_note,omitempty"`
	DecidedAt       *time.Time `json:"decided_at,omitempty"`
	StopReason      string     `json:"stop_reason,omitempty"`
	StoppedAt       *time.Time `json:"stopped_at,omitempty"`
	CompletionNote  string     `json:"completion_note,omitempty"`
	CompletedAt     *time.Time `json:"completed_at,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}

// RenovationConsent, kat maliki yazılı rızasıdır.
type RenovationConsent struct {
	OwnerUserID string    `json:"owner_user_id"`
	OwnerName   string    `json:"owner_name"`
	ConsentedOn time.Time `json:"consented_on"`
	DocumentRef string    `json:"document_ref,omitempty"`
}

// CreateRenovationInput, başvuru girdisidir.
type CreateRenovationInput struct {
	UnitID          string `json:"unit_id"`
	Scope           string `json:"scope"`
	Description     string `json:"description"`
	ContractorName  string `json:"contractor_name"`
	ContractorPhone string `json:"contractor_phone"`
	StartDate       string `json:"start_date"`
	EndDate         string `json:"end_date"`
}

// ApproveRenovationInput, onay girdisidir.
type ApproveRenovationInput struct {
	Conditions    string  `json:"conditions"`
	DepositAmount float64 `json:"deposit_amount"`
	PermitRef     string  `json:"permit_ref"`
	AgendaItemID  string  `json:"agenda_item_id"`
}

// RenovationRepository, tadilat izni deposu.
type RenovationRepository struct{ pool *pgxpool.Pool }

// NewRenovationRepository depoyu kurar.
func NewRenovationRepository(pool *pgxpool.Pool) *RenovationRepository {
	return &RenovationRepository{pool: pool}
}

func (r *RenovationRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

const renovationSelect = `
	SELECT p.id::text, p.unit_id::text, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''), COALESCE(u.block,''),
	       p.applicant_id::text, COALESCE(a.first_name || ' ' || a.last_name, ''),
	       p.scope, p.description, COALESCE(p.contractor_name,''), COALESCE(p.contractor_phone,''),
	       p.start_date, p.end_date, p.status, COALESCE(p.work_hours,''), COALESCE(p.conditions,''),
	       p.deposit_amount::float8, p.deposit_refunded::float8, COALESCE(p.permit_ref,''),
	       COALESCE(p.agenda_item_id::text,''), p.consent_required,
	       (SELECT count(*) FROM renovation_consents c WHERE c.permit_id = p.id)::int,
	       COALESCE(p.decision_note,''), p.decided_at, COALESCE(p.stop_reason,''), p.stopped_at,
	       COALESCE(p.completion_note,''), p.completed_at, p.created_at
	FROM renovation_permits p
	JOIN units u ON u.id = p.unit_id
	LEFT JOIN users a ON a.id = p.applicant_id`

func scanRenovation(row pgx.Row) (*RenovationPermit, error) {
	p := &RenovationPermit{}
	err := row.Scan(&p.ID, &p.UnitID, &p.Unit, &p.Block, &p.ApplicantID, &p.ApplicantName,
		&p.Scope, &p.Description, &p.ContractorName, &p.ContractorPhone,
		&p.StartDate, &p.EndDate, &p.Status, &p.WorkHours, &p.Conditions,
		&p.DepositAmount, &p.DepositRefunded, &p.PermitRef,
		&p.AgendaItemID, &p.ConsentRequired, &p.ConsentCount,
		&p.DecisionNote, &p.DecidedAt, &p.StopReason, &p.StoppedAt,
		&p.CompletionNote, &p.CompletedAt, &p.CreatedAt)
	return p, err
}

// IsUnitOwnerOrProxy: kişi bölümün aktif maliki ya da vekili mi (başvuru hakkı).
func (r *RenovationRepository) IsUnitOwnerOrProxy(ctx context.Context, propertyID, unitID, userID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		               WHERE ru.unit_id = $1::uuid AND u.property_id = $2 AND u.deleted = 0
		                 AND ru.resident_id = $3::uuid AND ru.role IN ('OWNER','PROXY')
		                 AND COALESCE(ru.is_active, true)
		                 AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))`,
		unitID, propertyID, userID).Scan(&ok)
	return ok, err
}

// UnitInSite: bölüm bu sitede ve silinmemiş mi.
func (r *RenovationRepository) UnitInSite(ctx context.Context, propertyID, unitID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM units WHERE id = $1::uuid AND property_id = $2 AND deleted = 0)`,
		unitID, propertyID).Scan(&ok)
	return ok, err
}

// IsUnitMember: kişinin bölümle aktif sakinlik bağı var mı (izni görme hakkı).
func (r *RenovationRepository) IsUnitMember(ctx context.Context, propertyID, unitID, userID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru
		               WHERE ru.unit_id = $1::uuid AND ru.resident_id = $2::uuid
		                 AND COALESCE(ru.is_active, true)
		                 AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))`,
		unitID, userID).Scan(&ok)
	return ok, err
}

// Create başvuruyu kaydeder.
func (r *RenovationRepository) Create(ctx context.Context, propertyID, applicantID string, in CreateRenovationInput) (*RenovationPermit, error) {
	var id string
	if err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO renovation_permits (property_id, unit_id, applicant_id, scope, description,
		    contractor_name, contractor_phone, start_date, end_date)
		VALUES ($1, $2, $3, $4, $5, NULLIF($6,''), NULLIF($7,''), $8::date, $9::date)
		RETURNING id::text`,
		propertyID, in.UnitID, applicantID, in.Scope, in.Description,
		in.ContractorName, in.ContractorPhone, in.StartDate, in.EndDate).Scan(&id); err != nil {
		return nil, err
	}
	return r.Get(ctx, propertyID, id)
}

// Get tek izin.
func (r *RenovationRepository) Get(ctx context.Context, propertyID, id string) (*RenovationPermit, error) {
	p, err := scanRenovation(r.scope(propertyID).QueryRow(ctx, renovationSelect+`
		WHERE p.id = $1 AND p.property_id = $2`, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrRenovationNotFound
	}
	return p, err
}

// List: userID doluysa kişinin başvurduğu ya da sakini olduğu bölümlerin
// izinleri; boşsa sitenin tümü (bekleyenler önce).
func (r *RenovationRepository) List(ctx context.Context, propertyID, userID string, limit int) ([]*RenovationPermit, error) {
	rows, err := r.scope(propertyID).Query(ctx, renovationSelect+`
		WHERE p.property_id = $1
		  AND ($2 = '' OR p.applicant_id::text = $2 OR EXISTS (
		        SELECT 1 FROM resident_units ru WHERE ru.unit_id = p.unit_id AND ru.resident_id::text = $2
		          AND COALESCE(ru.is_active, true) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)))
		ORDER BY (p.status = 'PENDING') DESC, p.start_date DESC, p.created_at DESC
		LIMIT $3`, propertyID, userID, limit+1)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*RenovationPermit{}
	for rows.Next() {
		p, err := scanRenovation(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// Consents, izne kaydedilmiş yazılı rızalar.
func (r *RenovationRepository) Consents(ctx context.Context, propertyID, permitID string) ([]RenovationConsent, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT c.owner_user_id::text, COALESCE(u.first_name || ' ' || u.last_name, ''), c.consented_on,
		       COALESCE(c.document_ref, '')
		FROM renovation_consents c
		JOIN renovation_permits p ON p.id = c.permit_id AND p.property_id = $2
		LEFT JOIN users u ON u.id = c.owner_user_id
		WHERE c.permit_id = $1
		ORDER BY c.created_at`, permitID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []RenovationConsent{}
	for rows.Next() {
		var c RenovationConsent
		if err := rows.Scan(&c.OwnerUserID, &c.OwnerName, &c.ConsentedOn, &c.DocumentRef); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// OwnerCount, sitenin AKTİF kat maliki sayısıdır (kişi bazında; iki dairesi
// olan malik bir kez sayılır). KMK m.19/2 "bütün kat maliklerinin beşte dördü"
// kişi sayısıdır, daire sayısı değil.
func (r *RenovationRepository) OwnerCount(ctx context.Context, propertyID string) (int, error) {
	var n int
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(DISTINCT ru.resident_id)::int
		FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1 AND u.deleted = 0 AND ru.role = 'OWNER'
		  AND COALESCE(ru.is_active, true) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)`,
		propertyID).Scan(&n)
	return n, err
}

// AddConsent, kat maliki rızasını kaydeder. İzin bekliyor ve ortak yer/dış
// cephe kapsamında olmalı; rıza veren sitenin aktif kat maliki olmalıdır.
func (r *RenovationRepository) AddConsent(ctx context.Context, propertyID, permitID, ownerID, consentedOn, documentRef, recordedBy string) error {
	p, err := r.Get(ctx, propertyID, permitID)
	if err != nil {
		return err
	}
	if p.Status != "PENDING" {
		return ErrRenovationState
	}
	if p.Scope != "COMMON_AREA" && p.Scope != "FACADE" {
		return ErrConsentNotApplicable
	}
	var isOwner bool
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		               WHERE u.property_id = $1 AND u.deleted = 0 AND ru.resident_id = $2::uuid
		                 AND ru.role = 'OWNER' AND COALESCE(ru.is_active, true)
		                 AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))`,
		propertyID, ownerID).Scan(&isOwner); err != nil {
		return err
	}
	if !isOwner {
		return ErrNotPropertyOwner
	}
	_, err = r.scope(propertyID).Exec(ctx, `
		INSERT INTO renovation_consents (permit_id, owner_user_id, consented_on, document_ref, recorded_by)
		VALUES ($1, $2::uuid, COALESCE(NULLIF($3,'')::date, CURRENT_DATE), NULLIF($4,''), NULLIF($5,'')::uuid)`,
		permitID, ownerID, consentedOn, documentRef, recordedBy)
	if err != nil && isUnique(err) {
		return ErrConsentDuplicate
	}
	return err
}

// AgendaAcceptedForConsent: gündem maddesi bu sitenin yapılmış toplantısında,
// ortak yer değişikliği nisabıyla (KMK m.19/2) KABUL edilmiş mi.
func (r *RenovationRepository) AgendaAcceptedForConsent(ctx context.Context, propertyID, agendaItemID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM assembly_agenda_items ai JOIN assemblies a ON a.id = ai.assembly_id
		               WHERE ai.id = $1::uuid AND a.property_id = $2 AND a.status = 'HELD'
		                 AND ai.decision_status = 'ACCEPTED'
		                 AND ai.required_majority_code = 'MAJORITY_CONSTRUCTION_CONSENT')`,
		agendaItemID, propertyID).Scan(&ok)
	return ok, err
}

// WorkHours, sitenin tadilat çalışma saatleri ayarıdır (yoksa boş).
func (r *RenovationRepository) WorkHours(ctx context.Context, propertyID string) (string, error) {
	var v string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT COALESCE(value_text, '') FROM property_settings
		WHERE property_id = $1 AND setting_key = 'RENOVATION_HOURS'`, propertyID).Scan(&v)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", nil
	}
	return v, err
}

// Approve izni onaylar (yalnızca bekleyen). Ön koşullar çağıran tarafından
// denetlenir; veritabanı kısıtları aynı koşulları ikinci kez arar.
func (r *RenovationRepository) Approve(ctx context.Context, propertyID, id, actorID, workHours string,
	in ApproveRenovationInput, consentRequired *int, consentCount int) (*RenovationPermit, error) {
	return r.transition(ctx, propertyID, id, `
		UPDATE renovation_permits
		SET status = 'APPROVED', work_hours = NULLIF($3,''), conditions = NULLIF($4,''),
		    deposit_amount = $5, permit_ref = NULLIF($6,''), agenda_item_id = NULLIF($7,'')::uuid,
		    consent_required = $8, consent_count = $9,
		    decided_by = NULLIF($10,'')::uuid, decided_at = now(), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING'`,
		id, propertyID, workHours, in.Conditions, in.DepositAmount, in.PermitRef, in.AgendaItemID,
		consentRequired, consentCount, actorID)
}

// Reject izni gerekçesiyle reddeder (yalnızca bekleyen).
func (r *RenovationRepository) Reject(ctx context.Context, propertyID, id, actorID, reason string) (*RenovationPermit, error) {
	return r.transition(ctx, propertyID, id, `
		UPDATE renovation_permits
		SET status = 'REJECTED', decision_note = $3, decided_by = NULLIF($4,'')::uuid,
		    decided_at = now(), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING'`, id, propertyID, reason, actorID)
}

// Cancel, başvuranın kendi bekleyen başvurusunu geri çekmesidir.
func (r *RenovationRepository) Cancel(ctx context.Context, propertyID, id, applicantID string) (*RenovationPermit, error) {
	return r.transition(ctx, propertyID, id, `
		UPDATE renovation_permits SET status = 'CANCELLED', updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING' AND applicant_id = $3::uuid`,
		id, propertyID, applicantID)
}

// Stop, onaylı izni gerekçesiyle durdurur (ihlal, izinsiz kapsam genişlemesi).
func (r *RenovationRepository) Stop(ctx context.Context, propertyID, id, reason string) (*RenovationPermit, error) {
	return r.transition(ctx, propertyID, id, `
		UPDATE renovation_permits SET status = 'STOPPED', stop_reason = $3, stopped_at = now(), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'APPROVED'`, id, propertyID, reason)
}

// Complete, denetimden sonra izni kapatır ve teminat iadesini yazar.
func (r *RenovationRepository) Complete(ctx context.Context, propertyID, id, actorID string, refunded float64, note string) (*RenovationPermit, error) {
	return r.transition(ctx, propertyID, id, `
		UPDATE renovation_permits
		SET status = 'COMPLETED', deposit_refunded = $3, completion_note = NULLIF($4,''),
		    completed_by = NULLIF($5,'')::uuid, completed_at = now(), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'APPROVED'`, id, propertyID, refunded, note, actorID)
}

func isUnique(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}

// transition, durum geçişini karşılaştır-ve-değiştir ile yapar: etkilenen satır
// yoksa kaydın var olup olmadığına bakılır (404 ile 409 ayrılır).
func (r *RenovationRepository) transition(ctx context.Context, propertyID, id, sql string, args ...any) (*RenovationPermit, error) {
	tag, err := r.scope(propertyID).Exec(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		if _, gerr := r.Get(ctx, propertyID, id); gerr != nil {
			return nil, gerr
		}
		return nil, ErrRenovationState
	}
	return r.Get(ctx, propertyID, id)
}
