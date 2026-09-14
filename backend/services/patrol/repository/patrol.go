// Package repository, tur kontrol (devriye) modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrNotFound        = errors.New("kayıt bulunamadı")
	ErrRouteInactive   = errors.New("tur güzergâhı pasif")
	ErrAlreadyOpen     = errors.New("bu görevlinin devam eden bir turu var")
	ErrNoOpenPatrol    = errors.New("devam eden tur yok")
	ErrCheckpointOther = errors.New("kontrol noktası bu güzergâha ait değil")
	ErrAlreadyScanned  = errors.New("bu nokta bu turda zaten okutuldu")
	ErrNoCheckpoints   = errors.New("güzergâh en az bir kontrol noktası içermelidir")
	ErrDuplicateTag    = errors.New("bu NFC/QR kimliği zaten kullanılıyor")
)

// Checkpoint, bir kontrol noktasıdır.
type Checkpoint struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	Location    string `json:"location,omitempty"`
	Building    string `json:"building,omitempty"`
	Floor       string `json:"floor,omitempty"`
	NFCTagID    string `json:"nfc_tag_id,omitempty"`
	QRCode      string `json:"qr_code,omitempty"`
	IsActive    bool   `json:"is_active"`
	Order       int    `json:"display_order"`
}

// Route, sıralı kontrol noktalarından oluşan tur güzergâhıdır.
type Route struct {
	ID           string            `json:"id"`
	Name         string            `json:"name"`
	Description  string            `json:"description,omitempty"`
	Checkpoints  []RouteCheckpoint `json:"checkpoints"`
	ExpectedMins int               `json:"expected_duration_minutes"`
	ToleranceMin int               `json:"tolerance_minutes"`
	IsActive     bool              `json:"is_active"`
}

// RouteCheckpoint, güzergâhtaki bir noktanın sırasıdır.
type RouteCheckpoint struct {
	CheckpointID string `json:"checkpoint_id"`
	Name         string `json:"name,omitempty"`
	Order        int    `json:"order"`
	Optional     bool   `json:"optional"`
}

// Patrol, bir tur kaydıdır.
type Patrol struct {
	ID           string     `json:"id"`
	RouteID      string     `json:"route_id,omitempty"`
	RouteName    string     `json:"route_name,omitempty"`
	GuardID      string     `json:"guard_id"`
	GuardName    string     `json:"guard_name,omitempty"`
	StartedAt    time.Time  `json:"started_at"`
	CompletedAt  *time.Time `json:"completed_at,omitempty"`
	ExpectedMins *int       `json:"expected_duration_minutes,omitempty"`
	ActualMins   *int       `json:"actual_duration_minutes,omitempty"`
	Status       string     `json:"status"`

	CheckpointsExpected int `json:"checkpoints_expected"`
	CheckpointsVisited  int `json:"checkpoints_visited"`
	IssuesReported      int `json:"issues_reported"`

	Scans  []Scan  `json:"scans,omitempty"`
	Issues []Issue `json:"issues,omitempty"`
	Notes  string  `json:"notes,omitempty"`

	// TooFast true ise tur beklenenden belirgin biçimde kısa sürmüştür.
	TooFast bool `json:"too_fast"`
}

// Scan, bir kontrol noktasının okutulmasıdır.
type Scan struct {
	CheckpointID   string    `json:"checkpoint_id"`
	CheckpointName string    `json:"checkpoint_name,omitempty"`
	ScannedAt      time.Time `json:"scanned_at"`
	Note           string    `json:"note,omitempty"`
}

// Issue, tur sırasında bildirilen bir sorundur.
type Issue struct {
	CheckpointID string    `json:"checkpoint_id,omitempty"`
	Severity     string    `json:"severity"`
	Description  string    `json:"description"`
	ReportedAt   time.Time `json:"reported_at"`
}

// Severities, sorun ciddiyet düzeyleridir.
var Severities = []string{"LOW", "MEDIUM", "HIGH", "CRITICAL"}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// ListCheckpoints, sitedeki kontrol noktalarını getirir.
func (r *Repository) ListCheckpoints(ctx context.Context, propertyID string, includeInactive bool) ([]Checkpoint, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, name, COALESCE(description,''), COALESCE(location,''),
		       COALESCE(building,''), COALESCE(floor,''),
		       COALESCE(nfc_tag_id,''), COALESCE(qr_code,''),
		       COALESCE(is_active,true), COALESCE(display_order,0)
		FROM patrol_checkpoints
		WHERE property_id = $1 AND ($2 OR COALESCE(is_active,true))
		ORDER BY display_order, name`, propertyID, includeInactive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Checkpoint{}
	for rows.Next() {
		var c Checkpoint
		if err := rows.Scan(&c.ID, &c.Name, &c.Description, &c.Location,
			&c.Building, &c.Floor, &c.NFCTagID, &c.QRCode, &c.IsActive, &c.Order); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// CreateCheckpoint, kontrol noktası tanımlar.
func (r *Repository) CreateCheckpoint(ctx context.Context, propertyID, name, description, location, building, floor, nfc, qr string, order int) (string, error) {
	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO patrol_checkpoints
			(property_id, name, description, location, building, floor,
			 nfc_tag_id, qr_code, display_order, is_active)
		VALUES ($1,$2,NULLIF($3,''),NULLIF($4,''),NULLIF($5,''),NULLIF($6,''),
		        NULLIF($7,''),NULLIF($8,''),$9,true)
		RETURNING id`,
		propertyID, name, description, location, building, floor, nfc, qr, order).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "duplicate key") {
		return "", ErrDuplicateTag
	}
	return id, err
}

// CreateRoute, güzergâh tanımlar. Noktaların siteye ait olduğu doğrulanır.
func (r *Repository) CreateRoute(ctx context.Context, propertyID, name, description string, checkpoints []RouteCheckpoint, expectedMins, toleranceMins int) (string, error) {
	if len(checkpoints) == 0 {
		return "", ErrNoCheckpoints
	}
	if expectedMins <= 0 {
		expectedMins = 30
	}
	if toleranceMins < 0 {
		toleranceMins = 10
	}

	ids := make([]string, 0, len(checkpoints))
	for _, cp := range checkpoints {
		ids = append(ids, cp.CheckpointID)
	}
	var valid int
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*) FROM patrol_checkpoints
		WHERE property_id = $1 AND id = ANY($2::uuid[])`, propertyID, ids).Scan(&valid); err != nil {
		return "", err
	}
	if valid != len(ids) {
		// Başka sitenin noktası güzergâha eklenemez.
		return "", ErrCheckpointOther
	}

	payload, err := json.Marshal(checkpoints)
	if err != nil {
		return "", err
	}

	var id string
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO patrol_routes
			(property_id, name, description, checkpoints, checkpoint_count,
			 expected_duration_minutes, tolerance_minutes, is_active)
		VALUES ($1,$2,NULLIF($3,''),$4,$5,$6,$7,true)
		RETURNING id`,
		propertyID, name, description, payload, len(checkpoints),
		expectedMins, toleranceMins).Scan(&id)
	return id, err
}

// ListRoutes, güzergâhları getirir.
func (r *Repository) ListRoutes(ctx context.Context, propertyID string, includeInactive bool) ([]Route, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, name, COALESCE(description,''), checkpoints,
		       COALESCE(expected_duration_minutes,30), COALESCE(tolerance_minutes,10),
		       COALESCE(is_active,true)
		FROM patrol_routes
		WHERE property_id = $1 AND ($2 OR COALESCE(is_active,true))
		ORDER BY name`, propertyID, includeInactive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Route{}
	for rows.Next() {
		var rt Route
		var raw []byte
		if err := rows.Scan(&rt.ID, &rt.Name, &rt.Description, &raw,
			&rt.ExpectedMins, &rt.ToleranceMin, &rt.IsActive); err != nil {
			return nil, err
		}
		if err := json.Unmarshal(raw, &rt.Checkpoints); err != nil {
			return nil, err
		}
		out = append(out, rt)
	}
	return out, rows.Err()
}

// getRoute, tek güzergâhı okur.
func (r *Repository) getRoute(ctx context.Context, q pgx.Tx, propertyID, routeID string) (*Route, error) {
	var rt Route
	var raw []byte
	err := q.QueryRow(ctx, `
		SELECT id, name, checkpoints, COALESCE(expected_duration_minutes,30),
		       COALESCE(tolerance_minutes,10), COALESCE(is_active,true)
		FROM patrol_routes WHERE id = $1 AND property_id = $2`, routeID, propertyID).
		Scan(&rt.ID, &rt.Name, &raw, &rt.ExpectedMins, &rt.ToleranceMin, &rt.IsActive)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(raw, &rt.Checkpoints); err != nil {
		return nil, err
	}
	return &rt, nil
}

// StartPatrol, turu başlatır.
//
// Başlangıç zamanı SUNUCUDAN alınır, istemciden değil: tur süresi güvenlik
// hizmetinin fiilen yapılıp yapılmadığının kanıtıdır ve istemcinin saatine
// bırakılırsa 30 dakikalık tur 3 dakikada "yapılmış" gösterilebilir.
//
// Bir görevlinin aynı anda yalnızca bir açık turu olabilir; aksi hâlde iki tur
// iç içe geçer ve hangi noktanın hangi tura ait olduğu belirsizleşir.
func (r *Repository) StartPatrol(ctx context.Context, propertyID, routeID, guardID string) (*Patrol, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	route, err := r.getRoute(ctx, tx, propertyID, routeID)
	if err != nil {
		return nil, err
	}
	if !route.IsActive {
		return nil, ErrRouteInactive
	}

	var open int
	if err := tx.QueryRow(ctx, `
		SELECT count(*) FROM patrol_logs
		WHERE property_id = $1 AND guard_id = $2 AND status = 'IN_PROGRESS'`,
		propertyID, guardID).Scan(&open); err != nil {
		return nil, err
	}
	if open > 0 {
		return nil, ErrAlreadyOpen
	}

	expected := len(route.Checkpoints)
	var id string
	var startedAt time.Time
	if err := tx.QueryRow(ctx, `
		INSERT INTO patrol_logs
			(property_id, route_id, guard_id, started_at, expected_duration_minutes,
			 status, checkpoints_expected, checkpoints_visited, checkpoint_details,
			 issues_reported, issues)
		VALUES ($1,$2,$3,now(),$4,'IN_PROGRESS',$5,0,'[]'::jsonb,0,'[]'::jsonb)
		RETURNING id, started_at`,
		propertyID, routeID, guardID, route.ExpectedMins, expected).Scan(&id, &startedAt); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &Patrol{
		ID: id, RouteID: routeID, RouteName: route.Name, GuardID: guardID,
		StartedAt: startedAt, Status: "IN_PROGRESS",
		CheckpointsExpected: expected, ExpectedMins: &route.ExpectedMins,
	}, nil
}

// ScanResult, okutma sonucudur.
type ScanResult struct {
	CheckpointName string `json:"checkpoint_name"`
	Visited        int    `json:"checkpoints_visited"`
	Expected       int    `json:"checkpoints_expected"`
	Remaining      int    `json:"checkpoints_remaining"`
}

// ScanCheckpoint, kontrol noktasını turun içine okutur.
//
// Okutma zamanı SUNUCUDAN yazılır. Aynı nokta aynı turda iki kez okutulamaz —
// tek noktada durup "tur tamamlandı" göstermeyi engeller.
func (r *Repository) ScanCheckpoint(ctx context.Context, propertyID, patrolID, checkpointID, guardID, note string) (*ScanResult, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var routeID *string
	var status string
	var raw []byte
	var expected int
	err = tx.QueryRow(ctx, `
		SELECT route_id::text, status, checkpoint_details, COALESCE(checkpoints_expected,0)
		FROM patrol_logs
		WHERE id = $1 AND property_id = $2 AND guard_id = $3
		FOR UPDATE`, patrolID, propertyID, guardID).Scan(&routeID, &status, &raw, &expected)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if status != "IN_PROGRESS" {
		return nil, ErrNoOpenPatrol
	}

	// Nokta güzergâhta mı?
	if routeID != nil {
		route, rerr := r.getRoute(ctx, tx, propertyID, *routeID)
		if rerr != nil {
			return nil, rerr
		}
		found := false
		for _, cp := range route.Checkpoints {
			if cp.CheckpointID == checkpointID {
				found = true
				break
			}
		}
		if !found {
			return nil, ErrCheckpointOther
		}
	}

	var scans []Scan
	if err := json.Unmarshal(raw, &scans); err != nil {
		scans = []Scan{}
	}
	for _, s := range scans {
		if s.CheckpointID == checkpointID {
			return nil, ErrAlreadyScanned
		}
	}

	var name string
	if err := tx.QueryRow(ctx,
		`SELECT name FROM patrol_checkpoints WHERE id = $1 AND property_id = $2`,
		checkpointID, propertyID).Scan(&name); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrCheckpointOther
		}
		return nil, err
	}

	scans = append(scans, Scan{
		CheckpointID: checkpointID, CheckpointName: name,
		ScannedAt: time.Now(), Note: strings.TrimSpace(note),
	})
	payload, err := json.Marshal(scans)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE patrol_logs
		SET checkpoint_details = $3, checkpoints_visited = $4
		WHERE id = $1 AND property_id = $2`,
		patrolID, propertyID, payload, len(scans)); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	remaining := expected - len(scans)
	if remaining < 0 {
		remaining = 0
	}
	return &ScanResult{
		CheckpointName: name, Visited: len(scans),
		Expected: expected, Remaining: remaining,
	}, nil
}

// ReportIssue, tur sırasında bir sorun kaydeder.
func (r *Repository) ReportIssue(ctx context.Context, propertyID, patrolID, guardID, checkpointID, severity, description string) error {
	sev := strings.ToUpper(strings.TrimSpace(severity))
	if !contains(Severities, sev) {
		sev = "MEDIUM"
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var raw []byte
	var status string
	err = tx.QueryRow(ctx, `
		SELECT COALESCE(issues,'[]'::jsonb), status FROM patrol_logs
		WHERE id = $1 AND property_id = $2 AND guard_id = $3 FOR UPDATE`,
		patrolID, propertyID, guardID).Scan(&raw, &status)
	if err == pgx.ErrNoRows {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if status != "IN_PROGRESS" {
		return ErrNoOpenPatrol
	}

	var issues []Issue
	if err := json.Unmarshal(raw, &issues); err != nil {
		issues = []Issue{}
	}
	issues = append(issues, Issue{
		CheckpointID: checkpointID, Severity: sev,
		Description: strings.TrimSpace(description), ReportedAt: time.Now(),
	})
	payload, err := json.Marshal(issues)
	if err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE patrol_logs SET issues = $3, issues_reported = $4
		WHERE id = $1 AND property_id = $2`,
		patrolID, propertyID, payload, len(issues)); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// CompleteResult, tur sonlandırma sonucudur.
type CompleteResult struct {
	Status              string   `json:"status"`
	ActualMinutes       int      `json:"actual_duration_minutes"`
	ExpectedMinutes     int      `json:"expected_duration_minutes"`
	CheckpointsVisited  int      `json:"checkpoints_visited"`
	CheckpointsExpected int      `json:"checkpoints_expected"`
	MissedCheckpoints   []string `json:"missed_checkpoints,omitempty"`
	TooFast             bool     `json:"too_fast"`
	Warning             string   `json:"warning,omitempty"`
}

// CompletePatrol, turu kapatır ve gerçek duruma göre sonuç üretir.
//
// Durum İSTEMCİDEN ALINMAZ, hesaplanır:
//   - Zorunlu noktaların tamamı okutulduysa COMPLETED
//   - Eksik nokta varsa INCOMPLETE (görevli "tamamladım" dese bile)
//
// Ayrıca tur, beklenen sürenin tolerans payı düşülmüş hâlinden de kısa sürdüyse
// "çok hızlı" olarak işaretlenir. Bu bir hata değil, DENETİM İŞARETİDİR:
// 30 dakikalık bir tur 3 dakikada bitmişse noktalar gerçekten gezilmemiş olabilir.
func (r *Repository) CompletePatrol(ctx context.Context, propertyID, patrolID, guardID, notes string) (*CompleteResult, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var routeID *string
	var status string
	var raw []byte
	var startedAt time.Time
	var expectedMins *int
	err = tx.QueryRow(ctx, `
		SELECT route_id::text, status, checkpoint_details, started_at, expected_duration_minutes
		FROM patrol_logs
		WHERE id = $1 AND property_id = $2 AND guard_id = $3 FOR UPDATE`,
		patrolID, propertyID, guardID).Scan(&routeID, &status, &raw, &startedAt, &expectedMins)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if status != "IN_PROGRESS" {
		return nil, ErrNoOpenPatrol
	}

	var scans []Scan
	if err := json.Unmarshal(raw, &scans); err != nil {
		scans = []Scan{}
	}
	visited := map[string]bool{}
	for _, s := range scans {
		visited[s.CheckpointID] = true
	}

	res := &CompleteResult{
		CheckpointsVisited: len(scans),
		ActualMinutes:      int(time.Since(startedAt).Minutes()),
	}
	if expectedMins != nil {
		res.ExpectedMinutes = *expectedMins
	}

	tolerance := 10
	if routeID != nil {
		route, rerr := r.getRoute(ctx, tx, propertyID, *routeID)
		if rerr != nil {
			return nil, rerr
		}
		tolerance = route.ToleranceMin
		res.CheckpointsExpected = len(route.Checkpoints)
		for _, cp := range route.Checkpoints {
			if cp.Optional {
				continue
			}
			if !visited[cp.CheckpointID] {
				name := cp.Name
				if name == "" {
					name = cp.CheckpointID
				}
				res.MissedCheckpoints = append(res.MissedCheckpoints, name)
			}
		}
	}

	if len(res.MissedCheckpoints) == 0 {
		res.Status = "COMPLETED"
	} else {
		res.Status = "INCOMPLETE"
	}

	// Beklenen süreden tolerans kadar kısa olmak normaldir; bunun da altına
	// inmek gerçekten gezilmediğine işarettir.
	if res.ExpectedMinutes > 0 {
		floor := res.ExpectedMinutes - tolerance
		if floor < 1 {
			floor = 1
		}
		if res.ActualMinutes < floor {
			res.TooFast = true
			res.Warning = fmt.Sprintf(
				"Tur beklenenden belirgin biçimde kısa sürdü (%d dk / beklenen %d dk, "+
					"tolerans %d dk). Noktalar fiilen gezilmemiş olabilir; kayıt "+
					"denetim için işaretlendi.",
				res.ActualMinutes, res.ExpectedMinutes, tolerance)
		}
	}

	if _, err := tx.Exec(ctx, `
		UPDATE patrol_logs
		SET status = $3, completed_at = now(), actual_duration_minutes = $4,
		    notes = NULLIF($5,'')
		WHERE id = $1 AND property_id = $2`,
		patrolID, propertyID, res.Status, res.ActualMinutes, strings.TrimSpace(notes)); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return res, nil
}

// ListPatrols, tur kayıtlarını getirir.
func (r *Repository) ListPatrols(ctx context.Context, propertyID, guardID, status string, limit int) ([]Patrol, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT l.id, COALESCE(l.route_id::text,''), COALESCE(rt.name,''),
		       l.guard_id::text, COALESCE(u.first_name || ' ' || u.last_name,''),
		       l.started_at, l.completed_at, l.expected_duration_minutes,
		       l.actual_duration_minutes, l.status,
		       COALESCE(l.checkpoints_expected,0), COALESCE(l.checkpoints_visited,0),
		       COALESCE(l.issues_reported,0), COALESCE(l.checkpoint_details,'[]'::jsonb),
		       COALESCE(l.issues,'[]'::jsonb), COALESCE(l.notes,'')
		FROM patrol_logs l
		LEFT JOIN patrol_routes rt ON rt.id = l.route_id
		LEFT JOIN users u ON u.id = l.guard_id
		WHERE l.property_id = $1
		  AND ($2 = '' OR l.guard_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR l.status = $3)
		ORDER BY l.started_at DESC
		LIMIT $4`, propertyID, guardID, strings.ToUpper(status), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Patrol{}
	for rows.Next() {
		var p Patrol
		var scansRaw, issuesRaw []byte
		if err := rows.Scan(&p.ID, &p.RouteID, &p.RouteName, &p.GuardID, &p.GuardName,
			&p.StartedAt, &p.CompletedAt, &p.ExpectedMins, &p.ActualMins, &p.Status,
			&p.CheckpointsExpected, &p.CheckpointsVisited, &p.IssuesReported,
			&scansRaw, &issuesRaw, &p.Notes); err != nil {
			return nil, err
		}
		_ = json.Unmarshal(scansRaw, &p.Scans)
		_ = json.Unmarshal(issuesRaw, &p.Issues)
		if p.ExpectedMins != nil && p.ActualMins != nil && *p.ExpectedMins > 0 {
			p.TooFast = *p.ActualMins < *p.ExpectedMins/2
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// Summary, devriye özetidir.
type Summary struct {
	Last7Days      int `json:"patrols_last_7_days"`
	Completed      int `json:"completed"`
	Incomplete     int `json:"incomplete"`
	InProgress     int `json:"in_progress"`
	IssuesReported int `json:"issues_reported"`
	TooFastCount   int `json:"suspiciously_fast"`
}

// Summary, son 7 günün devriye durumunu verir.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	var s Summary
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*),
		       count(*) FILTER (WHERE status = 'COMPLETED'),
		       count(*) FILTER (WHERE status = 'INCOMPLETE'),
		       count(*) FILTER (WHERE status = 'IN_PROGRESS'),
		       COALESCE(SUM(COALESCE(issues_reported,0)),0),
		       count(*) FILTER (
		         WHERE actual_duration_minutes IS NOT NULL
		           AND expected_duration_minutes IS NOT NULL
		           AND expected_duration_minutes > 0
		           AND actual_duration_minutes < expected_duration_minutes / 2)
		FROM patrol_logs
		WHERE property_id = $1 AND started_at >= now() - interval '7 days'`, propertyID).
		Scan(&s.Last7Days, &s.Completed, &s.Incomplete, &s.InProgress,
			&s.IssuesReported, &s.TooFastCount)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// patrol_checkpoints, patrol_routes, patrol_logs tablolarında RLS açıktır (migration 021).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
