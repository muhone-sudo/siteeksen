package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Acil durum hataları.
var (
	ErrEmergencyNotFound = errors.New("kayıt bulunamadı")
	ErrSafetyCheckOpen   = errors.New("zaten açık bir durum bildirimi çağrısı var")
	ErrSafetyCheckClosed = errors.New("durum bildirimi çağrısı kapalı")

	EmergencyPointKinds  = []string{"ASSEMBLY_AREA", "WATER_VALVE", "GAS_VALVE", "ELECTRIC_PANEL", "GENERATOR", "FIRE_PUMP", "FIRE_CABINET", "FIRST_AID", "SHELTER", "OTHER"}
	EmergencyContactCats = []string{"EMERGENCY", "UTILITY", "HOSPITAL", "MANAGEMENT", "SECURITY", "TECHNICAL", "OTHER"}
	DrillKinds           = []string{"FIRE", "EARTHQUAKE", "EVACUATION", "FLOOD", "OTHER"}
)

// EmergencyPoint, kritik altyapı / toplanma alanı kaydıdır.
type EmergencyPoint struct {
	ID       string `json:"id"`
	Kind     string `json:"kind"`
	Name     string `json:"name"`
	Location string `json:"location"`
	Note     string `json:"note,omitempty"`
}

// EmergencyContact, acil iletişim satırıdır.
type EmergencyContact struct {
	ID        string `json:"id"`
	Category  string `json:"category"`
	Name      string `json:"name"`
	Phone     string `json:"phone"`
	Note      string `json:"note,omitempty"`
	SortOrder int    `json:"sort_order"`
}

// Drill, tatbikat kaydıdır.
type Drill struct {
	ID                string    `json:"id"`
	Kind              string    `json:"kind"`
	DrillDate         time.Time `json:"drill_date"`
	Participants      *int      `json:"participants,omitempty"`
	Findings          string    `json:"findings"`
	CorrectiveActions string    `json:"corrective_actions,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
}

// EmergencyCard, sakin acil bilgi kartıdır. Needs çözülmüş metindir; depoda şifrelidir.
type EmergencyCard struct {
	ID             string    `json:"id"`
	UserID         string    `json:"user_id"`
	ResidentName   string    `json:"resident_name,omitempty"`
	UnitID         string    `json:"unit_id"`
	Unit           string    `json:"unit"`
	Needs          string    `json:"needs"`
	HouseholdCount *int      `json:"household_count,omitempty"`
	ContactName    string    `json:"contact_name,omitempty"`
	ContactPhone   string    `json:"contact_phone,omitempty"`
	ConsentAt      time.Time `json:"consent_at"`
	ConsentVersion string    `json:"consent_version"`
	UpdatedAt      time.Time `json:"updated_at"`
	needsCipher    string
}

// Cipher, depodaki şifreli metni döndürür (çözme handler'da yapılır).
func (c *EmergencyCard) Cipher() string { return c.needsCipher }

// SafetyCheck, afet sonrası durum bildirimi çağrısıdır.
type SafetyCheck struct {
	ID        string     `json:"id"`
	Kind      string     `json:"kind"`
	Title     string     `json:"title"`
	Status    string     `json:"status"`
	OpenedAt  time.Time  `json:"opened_at"`
	ClosedAt  *time.Time `json:"closed_at,omitempty"`
	Safe      int        `json:"safe"`
	NeedHelp  int        `json:"need_help"`
	Units     int        `json:"units"`     // sakini olan bölüm sayısı
	Responded int        `json:"responded"` // en az bir sakini yanıt veren bölüm
	MyStatus  string     `json:"my_status,omitempty"`
}

// SafetyResponse, bir sakinin yanıtıdır.
type SafetyResponse struct {
	UserID      string    `json:"user_id"`
	Name        string    `json:"name"`
	Unit        string    `json:"unit"`
	Status      string    `json:"status"`
	Note        string    `json:"note,omitempty"`
	RespondedAt time.Time `json:"responded_at"`
}

// EmergencyRepository deposu.
type EmergencyRepository struct{ pool *pgxpool.Pool }

// NewEmergencyRepository depoyu kurar.
func NewEmergencyRepository(pool *pgxpool.Pool) *EmergencyRepository {
	return &EmergencyRepository{pool: pool}
}

func (r *EmergencyRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// Points / Contacts / Drills — okuma.
func (r *EmergencyRepository) Points(ctx context.Context, propertyID string) ([]EmergencyPoint, error) {
	rows, err := r.scope(propertyID).Query(ctx, `SELECT id::text, kind, name, location, COALESCE(note,'')
		FROM emergency_points WHERE property_id = $1 ORDER BY kind, name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []EmergencyPoint{}
	for rows.Next() {
		var p EmergencyPoint
		if err := rows.Scan(&p.ID, &p.Kind, &p.Name, &p.Location, &p.Note); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

func (r *EmergencyRepository) Contacts(ctx context.Context, propertyID string) ([]EmergencyContact, error) {
	rows, err := r.scope(propertyID).Query(ctx, `SELECT id::text, category, name, phone, COALESCE(note,''), sort_order
		FROM emergency_contacts WHERE property_id = $1 ORDER BY sort_order, name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []EmergencyContact{}
	for rows.Next() {
		var c EmergencyContact
		if err := rows.Scan(&c.ID, &c.Category, &c.Name, &c.Phone, &c.Note, &c.SortOrder); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func (r *EmergencyRepository) Drills(ctx context.Context, propertyID string) ([]Drill, error) {
	rows, err := r.scope(propertyID).Query(ctx, `SELECT id::text, kind, drill_date, participants, findings,
		COALESCE(corrective_actions,''), created_at FROM emergency_drills WHERE property_id = $1
		ORDER BY drill_date DESC LIMIT 200`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Drill{}
	for rows.Next() {
		var d Drill
		if err := rows.Scan(&d.ID, &d.Kind, &d.DrillDate, &d.Participants, &d.Findings, &d.CorrectiveActions, &d.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

// AddPoint / AddContact / AddDrill — yazma.
func (r *EmergencyRepository) AddPoint(ctx context.Context, propertyID string, p EmergencyPoint) (*EmergencyPoint, error) {
	err := r.scope(propertyID).QueryRow(ctx, `INSERT INTO emergency_points (property_id, kind, name, location, note)
		VALUES ($1, $2, $3, $4, NULLIF($5,'')) RETURNING id::text`, propertyID, p.Kind, p.Name, p.Location, p.Note).Scan(&p.ID)
	return &p, err
}

func (r *EmergencyRepository) AddContact(ctx context.Context, propertyID string, c EmergencyContact) (*EmergencyContact, error) {
	err := r.scope(propertyID).QueryRow(ctx, `INSERT INTO emergency_contacts (property_id, category, name, phone, note, sort_order)
		VALUES ($1, $2, $3, $4, NULLIF($5,''), $6) RETURNING id::text`, propertyID, c.Category, c.Name, c.Phone, c.Note, c.SortOrder).Scan(&c.ID)
	return &c, err
}

func (r *EmergencyRepository) AddDrill(ctx context.Context, propertyID, actorID string, d Drill) (*Drill, error) {
	err := r.scope(propertyID).QueryRow(ctx, `INSERT INTO emergency_drills (property_id, kind, drill_date, participants,
		findings, corrective_actions, recorded_by) VALUES ($1, $2, $3, $4, $5, NULLIF($6,''), NULLIF($7,'')::uuid)
		RETURNING id::text, created_at`, propertyID, d.Kind, d.DrillDate, d.Participants, d.Findings, d.CorrectiveActions, actorID).
		Scan(&d.ID, &d.CreatedAt)
	return &d, err
}

// DeletePoint / DeleteContact: dizin bilgisidir, delil değildir; silinebilir.
func (r *EmergencyRepository) DeleteRow(ctx context.Context, propertyID, table, id string) error {
	if table != "emergency_points" && table != "emergency_contacts" {
		return errors.New("geçersiz tablo")
	}
	tag, err := r.scope(propertyID).Exec(ctx, `DELETE FROM `+table+` WHERE id = $1 AND property_id = $2`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrEmergencyNotFound
	}
	return nil
}

const cardSelect = `
	SELECT c.id::text, c.user_id::text, COALESCE(p.first_name || ' ' || p.last_name, ''), c.unit_id::text,
	       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''), c.needs_encrypted, c.household_count,
	       COALESCE(c.contact_name,''), COALESCE(c.contact_phone,''), c.consent_at, c.consent_version, c.updated_at
	FROM resident_emergency_cards c
	JOIN units u ON u.id = c.unit_id
	LEFT JOIN users p ON p.id = c.user_id`

func scanCard(row pgx.Row) (*EmergencyCard, error) {
	c := &EmergencyCard{}
	err := row.Scan(&c.ID, &c.UserID, &c.ResidentName, &c.UnitID, &c.Unit, &c.needsCipher, &c.HouseholdCount,
		&c.ContactName, &c.ContactPhone, &c.ConsentAt, &c.ConsentVersion, &c.UpdatedAt)
	return c, err
}

// Cards: userID doluysa kişinin kartları; boşsa sitenin tümü.
func (r *EmergencyRepository) Cards(ctx context.Context, propertyID, userID string) ([]*EmergencyCard, error) {
	rows, err := r.scope(propertyID).Query(ctx, cardSelect+`
		WHERE c.property_id = $1 AND ($2 = '' OR c.user_id::text = $2)
		ORDER BY u.block, u.door_number`, propertyID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []*EmergencyCard{}
	for rows.Next() {
		c, err := scanCard(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// UpsertCard kartı yazar; kişi bölümün aktif sakini olmalıdır.
func (r *EmergencyRepository) UpsertCard(ctx context.Context, propertyID, userID, unitID, needsCipher string,
	household *int, contactName, contactPhone, consentVersion string) error {
	var member bool
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		               WHERE ru.unit_id = $1::uuid AND u.property_id = $2 AND ru.resident_id = $3::uuid
		                 AND COALESCE(ru.is_active, true) AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))`,
		unitID, propertyID, userID).Scan(&member); err != nil {
		return err
	}
	if !member {
		return ErrUnitNotFound
	}
	_, err := r.scope(propertyID).Exec(ctx, `
		INSERT INTO resident_emergency_cards (property_id, user_id, unit_id, needs_encrypted, household_count,
		    contact_name, contact_phone, consent_at, consent_version)
		VALUES ($1, $2, $3, $4, $5, NULLIF($6,''), NULLIF($7,''), now(), $8)
		ON CONFLICT (property_id, user_id, unit_id) DO UPDATE
		SET needs_encrypted = EXCLUDED.needs_encrypted, household_count = EXCLUDED.household_count,
		    contact_name = EXCLUDED.contact_name, contact_phone = EXCLUDED.contact_phone,
		    consent_at = now(), consent_version = EXCLUDED.consent_version, updated_at = now()`,
		propertyID, userID, unitID, needsCipher, household, contactName, contactPhone, consentVersion)
	return err
}

// DeleteCard, rıza geri alındığında kartı gerçekten siler (KVKK m.7).
func (r *EmergencyRepository) DeleteCard(ctx context.Context, propertyID, userID, unitID string) error {
	tag, err := r.scope(propertyID).Exec(ctx,
		`DELETE FROM resident_emergency_cards WHERE property_id = $1 AND user_id = $2::uuid AND unit_id = $3::uuid`,
		propertyID, userID, unitID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrEmergencyNotFound
	}
	return nil
}

// OpenCheck yeni durum bildirimi çağrısı açar (aynı anda tek açık).
func (r *EmergencyRepository) OpenCheck(ctx context.Context, propertyID, actorID, kind, title string) (string, error) {
	var id string
	err := r.scope(propertyID).QueryRow(ctx, `INSERT INTO safety_checks (property_id, kind, title, opened_by)
		VALUES ($1, $2, $3, NULLIF($4,'')::uuid) RETURNING id::text`, propertyID, kind, title, actorID).Scan(&id)
	if err != nil && isUnique(err) {
		return "", ErrSafetyCheckOpen
	}
	return id, err
}

// CloseCheck çağrıyı kapatır.
func (r *EmergencyRepository) CloseCheck(ctx context.Context, propertyID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `UPDATE safety_checks SET status = 'CLOSED', closed_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'OPEN'`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		if _, gerr := r.GetCheck(ctx, propertyID, id, ""); gerr != nil {
			return gerr
		}
		return ErrSafetyCheckClosed
	}
	return nil
}

// GetCheck çağrıyı sayaçlarıyla getirir; userID verilirse kişinin yanıtı da.
func (r *EmergencyRepository) GetCheck(ctx context.Context, propertyID, id, userID string) (*SafetyCheck, error) {
	s := &SafetyCheck{}
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT s.id::text, s.kind, s.title, s.status, s.opened_at, s.closed_at,
		       (SELECT count(*) FROM safety_check_responses x WHERE x.check_id = s.id AND x.status = 'SAFE')::int,
		       (SELECT count(*) FROM safety_check_responses x WHERE x.check_id = s.id AND x.status = 'NEED_HELP')::int,
		       (SELECT count(DISTINCT ru.unit_id) FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		          WHERE u.property_id = s.property_id AND u.deleted = 0 AND COALESCE(ru.is_active, true)
		            AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE))::int,
		       (SELECT count(DISTINCT x.unit_id) FROM safety_check_responses x WHERE x.check_id = s.id AND x.unit_id IS NOT NULL)::int,
		       COALESCE((SELECT x.status FROM safety_check_responses x WHERE x.check_id = s.id AND x.user_id::text = $3), '')
		FROM safety_checks s WHERE s.id = $1 AND s.property_id = $2`, id, propertyID, userID).
		Scan(&s.ID, &s.Kind, &s.Title, &s.Status, &s.OpenedAt, &s.ClosedAt, &s.Safe, &s.NeedHelp, &s.Units, &s.Responded, &s.MyStatus)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrEmergencyNotFound
	}
	return s, err
}

// Checks, son çağrılar (açık olan önce).
func (r *EmergencyRepository) Checks(ctx context.Context, propertyID, userID string) ([]*SafetyCheck, error) {
	rows, err := r.scope(propertyID).Query(ctx, `SELECT id::text FROM safety_checks WHERE property_id = $1
		ORDER BY (status = 'OPEN') DESC, opened_at DESC LIMIT 20`, propertyID)
	if err != nil {
		return nil, err
	}
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return nil, err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	out := []*SafetyCheck{}
	for _, id := range ids {
		s, err := r.GetCheck(ctx, propertyID, id, userID)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

// Respond, sakinin durum yanıtını yazar (çağrı açıkken; yeniden yanıt günceller).
func (r *EmergencyRepository) Respond(ctx context.Context, propertyID, checkID, userID, status, note string) error {
	s, err := r.GetCheck(ctx, propertyID, checkID, "")
	if err != nil {
		return err
	}
	if s.Status != "OPEN" {
		return ErrSafetyCheckClosed
	}
	_, err = r.scope(propertyID).Exec(ctx, `
		INSERT INTO safety_check_responses (check_id, user_id, unit_id, status, note)
		VALUES ($1, $2::uuid,
		        (SELECT ru.unit_id FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		          WHERE ru.resident_id = $2::uuid AND u.property_id = $5 AND COALESCE(ru.is_active, true)
		            AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE) ORDER BY ru.role LIMIT 1),
		        $3, NULLIF($4,''))
		ON CONFLICT (check_id, user_id) DO UPDATE
		SET status = EXCLUDED.status, note = EXCLUDED.note, responded_at = now()`,
		checkID, userID, status, note, propertyID)
	return err
}

// Responses, çağrının yanıtları (yardım isteyenler önce).
func (r *EmergencyRepository) Responses(ctx context.Context, propertyID, checkID string) ([]SafetyResponse, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT x.user_id::text, COALESCE(p.first_name || ' ' || p.last_name, ''),
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''), x.status, COALESCE(x.note,''), x.responded_at
		FROM safety_check_responses x
		JOIN safety_checks s ON s.id = x.check_id AND s.property_id = $2
		LEFT JOIN users p ON p.id = x.user_id
		LEFT JOIN units u ON u.id = x.unit_id
		WHERE x.check_id = $1
		ORDER BY (x.status = 'NEED_HELP') DESC, x.responded_at`, checkID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []SafetyResponse{}
	for rows.Next() {
		var x SafetyResponse
		if err := rows.Scan(&x.UserID, &x.Name, &x.Unit, &x.Status, &x.Note, &x.RespondedAt); err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// SilentUnits, sakini olup henüz hiçbir sakini yanıt vermemiş bölümler.
func (r *EmergencyRepository) SilentUnits(ctx context.Context, propertyID, checkID string) ([]string, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT DISTINCT COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''), u.block, u.door_number
		FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1 AND u.deleted = 0 AND COALESCE(ru.is_active, true)
		  AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)
		  AND NOT EXISTS (SELECT 1 FROM safety_check_responses x WHERE x.check_id = $2 AND x.unit_id = u.id)
		ORDER BY u.block, u.door_number`, propertyID, checkID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []string{}
	for rows.Next() {
		var name string
		var b, d *string
		if err := rows.Scan(&name, &b, &d); err != nil {
			return nil, err
		}
		out = append(out, name)
	}
	return out, rows.Err()
}
