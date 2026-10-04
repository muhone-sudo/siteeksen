package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Kural ihlali hataları.
var (
	ErrRuleNotFound      = errors.New("kural bulunamadı ya da etkin değil")
	ErrViolationNotFound = errors.New("ihlal kaydı bulunamadı")
	ErrViolationState    = errors.New("ihlal kaydı bu işlem için uygun durumda değil")
	ErrUnitNotFound      = errors.New("bağımsız bölüm bu sitede bulunamadı")

	RuleCategories = []string{"NOISE", "PET", "PARKING", "WASTE", "COMMON_AREA", "RENOVATION", "OTHER"}
	// ViolationStages, kademeli sürecin sırasıdır (yalnızca ileri gider).
	ViolationStages = []string{"NONE", "VERBAL_WARNING", "WRITTEN_WARNING", "FORMAL_NOTICE", "LEGAL"}
)

// SiteRule, yönetim planına dayanan kuraldır.
type SiteRule struct {
	ID                string    `json:"id"`
	Category          string    `json:"category"`
	Title             string    `json:"title"`
	Description       string    `json:"description,omitempty"`
	ManagementPlanRef string    `json:"management_plan_ref"`
	IsActive          bool      `json:"is_active"`
	CreatedAt         time.Time `json:"created_at"`
}

// Violation, kural ihlali kaydıdır. Bildiren bilgisi yalnızca yönetime ve
// bildirenin kendisine doldurulur (handler temizler).
type Violation struct {
	ID              string           `json:"id"`
	RuleID          string           `json:"rule_id"`
	RuleTitle       string           `json:"rule_title"`
	PlanRef         string           `json:"management_plan_ref"`
	UnitID          string           `json:"unit_id"`
	Unit            string           `json:"unit"`
	ReportedBy      string           `json:"reported_by,omitempty"`
	ReporterName    string           `json:"reporter_name,omitempty"`
	Description     string           `json:"description"`
	OccurredAt      time.Time        `json:"occurred_at"`
	Status          string           `json:"status"`
	Stage           string           `json:"stage"`
	UnitRepeatCount int              `json:"unit_repeat_count"` // son 24 ayda doğrulanmış ihlal
	CreatedAt       time.Time        `json:"created_at"`
	Events          []ViolationEvent `json:"events,omitempty"`
}

// ViolationEvent, olay geçmişi satırıdır.
type ViolationEvent struct {
	EventType string    `json:"event_type"`
	Note      string    `json:"note,omitempty"`
	ActorID   string    `json:"actor_id,omitempty"`
	ActorName string    `json:"actor_name,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// ViolationRepository deposu.
type ViolationRepository struct{ pool *pgxpool.Pool }

// NewViolationRepository depoyu kurar.
func NewViolationRepository(pool *pgxpool.Pool) *ViolationRepository {
	return &ViolationRepository{pool: pool}
}

func (r *ViolationRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// ListRules, sitenin kuralları (onlyActive: yalnızca etkinler).
func (r *ViolationRepository) ListRules(ctx context.Context, propertyID string, onlyActive bool) ([]SiteRule, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id::text, category, title, COALESCE(description,''), management_plan_ref, is_active, created_at
		FROM site_rules WHERE property_id = $1 AND (NOT $2 OR is_active)
		ORDER BY is_active DESC, category, title`, propertyID, onlyActive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []SiteRule{}
	for rows.Next() {
		var s SiteRule
		if err := rows.Scan(&s.ID, &s.Category, &s.Title, &s.Description, &s.ManagementPlanRef, &s.IsActive, &s.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, rows.Err()
}

// CreateRule kural ekler.
func (r *ViolationRepository) CreateRule(ctx context.Context, propertyID, actorID string, s SiteRule) (*SiteRule, error) {
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO site_rules (property_id, category, title, description, management_plan_ref, created_by)
		VALUES ($1, $2, $3, NULLIF($4,''), $5, NULLIF($6,'')::uuid)
		RETURNING id::text, is_active, created_at`,
		propertyID, s.Category, s.Title, s.Description, s.ManagementPlanRef, actorID).Scan(&s.ID, &s.IsActive, &s.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// DeactivateRule kuralı pasifleştirir (silinmez: geçmiş ihlaller ona bağlıdır).
func (r *ViolationRepository) DeactivateRule(ctx context.Context, propertyID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx,
		`UPDATE site_rules SET is_active = false WHERE id = $1 AND property_id = $2`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrRuleNotFound
	}
	return nil
}

const violationSelect = `
	SELECT v.id::text, v.rule_id::text, r.title, r.management_plan_ref, v.unit_id::text,
	       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
	       v.reported_by::text, COALESCE(p.first_name || ' ' || p.last_name, ''),
	       v.description, v.occurred_at, v.status, v.stage,
	       (SELECT count(*) FROM rule_violations o WHERE o.unit_id = v.unit_id
	          AND o.status IN ('VERIFIED','RESOLVED') AND o.created_at >= now() - interval '24 months')::int,
	       v.created_at
	FROM rule_violations v
	JOIN site_rules r ON r.id = v.rule_id
	JOIN units u ON u.id = v.unit_id
	LEFT JOIN users p ON p.id = v.reported_by`

func scanViolation(row pgx.Row) (*Violation, error) {
	v := &Violation{}
	err := row.Scan(&v.ID, &v.RuleID, &v.RuleTitle, &v.PlanRef, &v.UnitID, &v.Unit,
		&v.ReportedBy, &v.ReporterName, &v.Description, &v.OccurredAt, &v.Status, &v.Stage,
		&v.UnitRepeatCount, &v.CreatedAt)
	return v, err
}

// Create, ihlal bildirimini kaydeder (kural etkin ve sitede, bölüm sitede olmalı).
func (r *ViolationRepository) Create(ctx context.Context, propertyID, reporterID, ruleID, unitID, description string, occurredAt *time.Time) (*Violation, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var ok bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM site_rules WHERE id = $1::uuid AND property_id = $2 AND is_active)`,
		ruleID, propertyID).Scan(&ok); err != nil {
		return nil, err
	}
	if !ok {
		return nil, ErrRuleNotFound
	}
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM units WHERE id = $1::uuid AND property_id = $2 AND deleted = 0)`,
		unitID, propertyID).Scan(&ok); err != nil {
		return nil, err
	}
	if !ok {
		return nil, ErrUnitNotFound
	}
	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO rule_violations (property_id, rule_id, unit_id, reported_by, description, occurred_at)
		VALUES ($1, $2, $3, $4, $5, COALESCE($6, now())) RETURNING id::text`,
		propertyID, ruleID, unitID, reporterID, description, occurredAt).Scan(&id); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO rule_violation_events (violation_id, event_type, actor_id) VALUES ($1, 'REPORTED', $2)`,
		id, reporterID); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return r.Get(ctx, propertyID, id)
}

// Get tek kayıt + olay geçmişi.
func (r *ViolationRepository) Get(ctx context.Context, propertyID, id string) (*Violation, error) {
	v, err := scanViolation(r.scope(propertyID).QueryRow(ctx, violationSelect+`
		WHERE v.id = $1 AND v.property_id = $2`, id, propertyID))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrViolationNotFound
	}
	if err != nil {
		return nil, err
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT e.event_type, COALESCE(e.note,''), COALESCE(e.actor_id::text,''),
		       COALESCE(a.first_name || ' ' || a.last_name, ''), e.created_at
		FROM rule_violation_events e LEFT JOIN users a ON a.id = e.actor_id
		WHERE e.violation_id = $1 ORDER BY e.created_at, e.id`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var e ViolationEvent
		if err := rows.Scan(&e.EventType, &e.Note, &e.ActorID, &e.ActorName, &e.CreatedAt); err != nil {
			return nil, err
		}
		v.Events = append(v.Events, e)
	}
	return v, rows.Err()
}

// List: userID boşsa site geneli (yönetim); doluysa kişinin bildirdikleri ve
// sakini olduğu dairelere ait kayıtlar.
func (r *ViolationRepository) List(ctx context.Context, propertyID, userID string, limit int) ([]*Violation, error) {
	rows, err := r.scope(propertyID).Query(ctx, violationSelect+`
		WHERE v.property_id = $1
		  AND ($2 = '' OR v.reported_by::text = $2 OR EXISTS (
		        SELECT 1 FROM resident_units ru WHERE ru.unit_id = v.unit_id AND ru.resident_id::text = $2
		          AND COALESCE(ru.is_active, true) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)))
		ORDER BY (v.status IN ('OPEN','VERIFIED')) DESC, v.created_at DESC
		LIMIT $3`, propertyID, userID, limit+1)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*Violation{}
	for rows.Next() {
		v, err := scanViolation(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

// IsUnitMember: kişinin bölümle aktif sakinlik bağı var mı.
func (r *ViolationRepository) IsUnitMember(ctx context.Context, propertyID, unitID, userID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru
		               WHERE ru.unit_id = $1::uuid AND ru.resident_id = $2::uuid
		                 AND COALESCE(ru.is_active, true) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))`,
		unitID, userID).Scan(&ok)
	return ok, err
}

// Transition, durum/kademe geçişini ve olay kaydını AYNI işlemde yazar.
// fromStatuses ve (verilirse) fromStage karşılaştır-ve-değiştir koşuludur.
func (r *ViolationRepository) Transition(ctx context.Context, propertyID, id string, fromStatuses []string,
	toStatus, toStage, eventType, note, actorID string, stageMustAdvance bool) (*Violation, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var curStatus, curStage string
	err = tx.QueryRow(ctx, `SELECT status, stage FROM rule_violations WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		id, propertyID).Scan(&curStatus, &curStage)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrViolationNotFound
	}
	if err != nil {
		return nil, err
	}
	allowed := false
	for _, s := range fromStatuses {
		if s == curStatus {
			allowed = true
		}
	}
	if !allowed || (stageMustAdvance && stageIndex(toStage) <= stageIndex(curStage)) {
		return nil, ErrViolationState
	}
	if toStatus == "" {
		toStatus = curStatus
	}
	if toStage == "" {
		toStage = curStage
	}
	if _, err := tx.Exec(ctx, `UPDATE rule_violations SET status = $3, stage = $4, updated_at = now() WHERE id = $1 AND property_id = $2`,
		id, propertyID, toStatus, toStage); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO rule_violation_events (violation_id, event_type, note, actor_id)
		VALUES ($1, $2, NULLIF($3,''), NULLIF($4,'')::uuid)`, id, eventType, note, actorID); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return r.Get(ctx, propertyID, id)
}

func stageIndex(s string) int {
	for i, x := range ViolationStages {
		if x == s {
			return i
		}
	}
	return -1
}
