// Package repository, yönetişim modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/services/governance/models"
)

// Sentinel hatalar — HTTP durum eşlemesi handler katmanında yapılır.
var (
	ErrNotFound             = errors.New("kayıt bulunamadı")
	ErrBudgetNotDraft       = errors.New("yalnızca taslak durumundaki işletme projesi tebliğ edilebilir")
	ErrBudgetNotNotified    = errors.New("kesinleştirmeden önce işletme projesi tebliğ edilmelidir")
	ErrObjectionPeriodOpen  = errors.New("itiraz süresi dolmadan işletme projesi kesinleşemez")
	ErrOpenObjections       = errors.New("açık itirazlar çözülmeden işletme projesi kesinleşemez")
	ErrBudgetExists         = errors.New("bu dönem için zaten bir işletme projesi var")
	ErrNoUnits              = errors.New("sitede tanımlı bağımsız bölüm yok")
	ErrAssemblyNotOpen      = errors.New("toplantı bu işlem için uygun durumda değil")
	ErrNotAttending         = errors.New("oy kullanan bağımsız bölüm hazirun listesinde yok")
	ErrBookClosed           = errors.New("defter kapatılmış; yeni kayıt eklenemez")
	ErrObjectionNotEntitled = errors.New("itiraz yalnızca dairenin maliki ya da vekili tarafından yapılabilir")
	// ErrAlreadyDecided: kayıt var ama zaten sonuçlanmış (itiraz, gündem maddesi).
	// Önceden bu durum "bulunamadı" (404) dönüyordu.
	ErrAlreadyDecided = errors.New("kayıt zaten sonuçlanmış")
	// ErrUnitNotInSite: bağımsız bölüm bu siteye ait değil ya da yok.
	ErrUnitNotInSite = errors.New("bağımsız bölüm bu sitede bulunamadı")
	// ErrCategoryNotInSite: gider kalemi bu siteye ait değil (ortak şablonlar hariç).
	ErrCategoryNotInSite = errors.New("gider kalemi bu sitede bulunamadı")
)

// Unit, dağıtım hesaplarında kullanılan bağımsız bölüm özetidir.
type Unit struct {
	ID         string
	Name       string
	ShareRatio float64
	AreaM2     float64
	IsGround   bool
}

// Repository, yönetişim veritabanı işlemleri.
type Repository struct {
	pool *pgxpool.Pool
}

// New yeni repository üretir.
func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// Pool, bağlantı havuzunu döndürür (mevzuat parametreleri çözümleyicisi için).
func (r *Repository) Pool() *pgxpool.Pool { return r.pool }

// ListUnits, dağıtım ve nisap hesapları için sitedeki bağımsız bölümleri getirir.
func (r *Repository) ListUnits(ctx context.Context, propertyID string) ([]Unit, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id,
		       COALESCE(block, '') || '-' || COALESCE(door_number, ''),
		       COALESCE(share_ratio, 0)::float8,
		       COALESCE(gross_area_m2, 0)::float8,
		       COALESCE(is_ground_floor, false)
		FROM units
		WHERE property_id = $1 AND deleted = 0
		ORDER BY block, door_number`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Unit{}
	for rows.Next() {
		var u Unit
		if err := rows.Scan(&u.ID, &u.Name, &u.ShareRatio, &u.AreaM2, &u.IsGround); err != nil {
			return nil, err
		}
		out = append(out, u)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return nil, ErrNoUnits
	}
	return out, nil
}

// -----------------------------------------------------------------------------
// İŞLETME PROJESİ
// -----------------------------------------------------------------------------

// CreateBudget, taslak işletme projesini kalemleri ve birim paylarıyla birlikte yazar.
// Paylar çağıran (service) tarafından hesaplanır; repository yalnızca kalıcılaştırır.
func (r *Repository) CreateBudget(
	ctx context.Context,
	propertyID, preparedBy string,
	in models.CreateBudgetInput,
	total float64,
	shares []models.UnitShare,
) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var budgetID string
	err = tx.QueryRow(ctx, `
		INSERT INTO operating_budgets
			(property_id, period_year, status, total_amount, prepared_by, prepared_at, note)
		VALUES ($1, $2, 'DRAFT', $3, NULLIF($4,'')::uuid, now(), NULLIF($5,''))
		RETURNING id`,
		propertyID, in.PeriodYear, total, preparedBy, in.Note).Scan(&budgetID)
	if err != nil {
		if isUniqueViolation(err) {
			return "", ErrBudgetExists
		}
		return "", err
	}

	for i, it := range in.Items {
		kind := it.Kind
		if kind == "" {
			kind = "EXPENSE"
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO operating_budget_items
				(budget_id, category_id, name, amount, distribution_type, kind, note, sort_order)
			VALUES ($1, NULLIF($2,'')::uuid, $3, $4, $5, $6, NULLIF($7,''), $8)`,
			budgetID, it.CategoryID, it.Name, it.Amount, it.DistributionType, kind, it.Note, i); err != nil {
			return "", err
		}
	}

	for _, s := range shares {
		breakdown, err := json.Marshal(s.Breakdown)
		if err != nil {
			return "", err
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO operating_budget_unit_shares
				(budget_id, unit_id, annual_kurus, monthly_kurus, breakdown)
			VALUES ($1, $2, $3, $4, $5)`,
			budgetID, s.UnitID, s.AnnualKurus, s.MonthlyKurus, breakdown); err != nil {
			return "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return budgetID, nil
}

// GetBudget, projeyi kalemleri, payları ve açık itiraz sayısıyla getirir.
func (r *Repository) GetBudget(ctx context.Context, propertyID, budgetID string) (*models.Budget, error) {
	b := &models.Budget{}
	var preparedBy, noticeMethod, decisionRef, note *string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT id, property_id, period_year, status, total_amount,
		       prepared_by::text, prepared_at, notified_at, notice_method,
		       objection_deadline, finalized_at, decision_ref, note,
		       (SELECT count(*) FROM budget_objections o
		          WHERE o.budget_id = b.id AND o.status = 'OPEN')
		FROM operating_budgets b
		WHERE id = $1 AND property_id = $2`, budgetID, propertyID).Scan(
		&b.ID, &b.PropertyID, &b.PeriodYear, &b.Status, &b.TotalAmount,
		&preparedBy, &b.PreparedAt, &b.NotifiedAt, &noticeMethod,
		&b.ObjectionDeadline, &b.FinalizedAt, &decisionRef, &note, &b.OpenObjections)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	b.PreparedBy = deref(preparedBy)
	b.NoticeMethod = deref(noticeMethod)
	b.DecisionRef = deref(decisionRef)
	b.Note = deref(note)

	itemRows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, COALESCE(category_id::text,''), name, amount, distribution_type,
		       kind, COALESCE(note,''), sort_order
		FROM operating_budget_items WHERE budget_id = $1 ORDER BY sort_order`, budgetID)
	if err != nil {
		return nil, err
	}
	defer itemRows.Close()
	for itemRows.Next() {
		var it models.BudgetItem
		if err := itemRows.Scan(&it.ID, &it.CategoryID, &it.Name, &it.Amount,
			&it.DistributionType, &it.Kind, &it.Note, &it.SortOrder); err != nil {
			return nil, err
		}
		b.Items = append(b.Items, it)
	}

	shareRows, err := r.scope(propertyID).Query(ctx, `
		SELECT s.unit_id, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       s.annual_kurus, s.monthly_kurus, COALESCE(s.breakdown, '{}'::jsonb)
		FROM operating_budget_unit_shares s
		JOIN units u ON u.id = s.unit_id
		WHERE s.budget_id = $1
		ORDER BY u.block, u.door_number`, budgetID)
	if err != nil {
		return nil, err
	}
	defer shareRows.Close()
	for shareRows.Next() {
		var s models.UnitShare
		raw := []byte{}
		if err := shareRows.Scan(&s.UnitID, &s.UnitName, &s.AnnualKurus, &s.MonthlyKurus, &raw); err != nil {
			return nil, err
		}
		_ = json.Unmarshal(raw, &s.Breakdown)
		b.UnitShares = append(b.UnitShares, s)
	}
	return b, nil
}

// ListBudgets, sitenin işletme projelerini özet olarak listeler.
func (r *Repository) ListBudgets(ctx context.Context, propertyID string) ([]models.Budget, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, property_id, period_year, status, total_amount,
		       notified_at, objection_deadline, finalized_at
		FROM operating_budgets
		WHERE property_id = $1
		ORDER BY period_year DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Budget{}
	for rows.Next() {
		var b models.Budget
		if err := rows.Scan(&b.ID, &b.PropertyID, &b.PeriodYear, &b.Status,
			&b.TotalAmount, &b.NotifiedAt, &b.ObjectionDeadline, &b.FinalizedAt); err != nil {
			return nil, err
		}
		out = append(out, b)
	}
	return out, rows.Err()
}

// NotifyBudget, tebliğ anını ve itiraz süresi bitişini işler (KMK m.37/2).
// objectionDays mevzuat parametresinden gelir.
func (r *Repository) NotifyBudget(ctx context.Context, propertyID, budgetID, method string, objectionDays int) (*models.Budget, error) {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE operating_budgets
		SET status = 'NOTIFIED',
		    notified_at = now(),
		    notice_method = $3,
		    -- make_interval kullanılır: metin birleştirmeli interval biçimi, parametre
		    -- tipi çıkarımında belirsizlik yaratıp "operator is not unique" hatası veriyordu.
		    objection_deadline = (CURRENT_DATE + make_interval(days => $4))::date,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'DRAFT'`,
		budgetID, propertyID, method, objectionDays)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, r.stateOrNotFound(ctx, propertyID, "operating_budgets", budgetID, ErrNotFound, ErrBudgetNotDraft)
	}
	return r.GetBudget(ctx, propertyID, budgetID)
}

// FinalizeBudget, itiraz süresi dolmuş ve açık itirazı olmayan projeyi kesinleştirir.
//
// Kesinleşen işletme projesi İİK m.68 anlamında BELGE niteliği kazanır; bu yüzden
// koşullar veritabanı düzeyinde de kontrol edilir, yalnızca arayüzde değil.
func (r *Repository) FinalizeBudget(ctx context.Context, propertyID, budgetID, decisionRef string) (*models.Budget, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status string
	var deadline *time.Time
	err = tx.QueryRow(ctx, `
		SELECT status, objection_deadline FROM operating_budgets
		WHERE id = $1 AND property_id = $2 FOR UPDATE`, budgetID, propertyID).Scan(&status, &deadline)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if status != models.BudgetNotified {
		return nil, ErrBudgetNotNotified
	}
	if deadline == nil || time.Now().Before(*deadline) {
		return nil, ErrObjectionPeriodOpen
	}

	var open int
	if err := tx.QueryRow(ctx,
		`SELECT count(*) FROM budget_objections WHERE budget_id = $1 AND status = 'OPEN'`,
		budgetID).Scan(&open); err != nil {
		return nil, err
	}
	if open > 0 {
		return nil, ErrOpenObjections
	}

	if _, err := tx.Exec(ctx, `
		UPDATE operating_budgets
		SET status = 'FINAL', finalized_at = now(), decision_ref = NULLIF($2,''), updated_at = now()
		WHERE id = $1 AND property_id = $3`, budgetID, decisionRef, propertyID); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return r.GetBudget(ctx, propertyID, budgetID)
}

// AddObjection, itiraz kaydeder ve süresinde olup olmadığını hesaplar.
func (r *Repository) AddObjection(ctx context.Context, propertyID, budgetID, unitID, userID, reason string) (*models.Objection, error) {
	var deadline *time.Time
	var status string
	err := r.scope(propertyID).QueryRow(ctx,
		`SELECT status, objection_deadline FROM operating_budgets WHERE id=$1 AND property_id=$2`,
		budgetID, propertyID).Scan(&status, &deadline)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	// İtiraz hakkı KAT MALİKİNİNDİR (KMK m.37/2). Önceden daire kimliği hiç
	// doğrulanmıyordu: kiracı, başka birinin dairesi — hatta başka sitenin
	// dairesi — adına itiraz yazabiliyordu ve açık itiraz projenin kesinleşmesini
	// engellediği için bu, bir sitenin bütçe sürecini durdurmak demekti.
	// Kabul edilenler: dairenin aktif maliki ya da vekili; ya da yazılı itirazı
	// kayda geçiren site yönetimi (yönetici / denetim kurulu üyesi).
	var entitled bool
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM units u
			WHERE u.id = $1 AND u.property_id = $2 AND u.deleted = 0
			  AND (EXISTS (SELECT 1 FROM resident_units ru
			               WHERE ru.unit_id = u.id AND ru.resident_id = $3
			                 AND ru.is_active AND ru.role IN ('OWNER','PROXY'))
			    OR EXISTS (SELECT 1 FROM property_roles pr
			               WHERE pr.user_id = $3 AND pr.property_id = $2 AND pr.is_active
			                 AND pr.role IN ('MANAGER','BOARD_MEMBER')
			                 AND pr.valid_from <= CURRENT_DATE
			                 AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE))))`,
		unitID, propertyID, userID).Scan(&entitled); err != nil {
		if IsInvalidID(err) {
			return nil, ErrObjectionNotEntitled
		}
		return nil, err
	}
	if !entitled {
		return nil, ErrObjectionNotEntitled
	}

	o := &models.Objection{BudgetID: budgetID, UnitID: unitID, UserID: userID, Reason: reason}
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO budget_objections (budget_id, unit_id, user_id, reason)
		VALUES ($1, NULLIF($2,'')::uuid, NULLIF($3,'')::uuid, $4)
		RETURNING id, submitted_at, status`,
		budgetID, unitID, userID, reason).Scan(&o.ID, &o.SubmittedAt, &o.Status)
	if err != nil {
		return nil, err
	}
	// Süresinde mi? (m.37/2 — tebliğden itibaren 7 gün)
	o.InTime = deadline != nil && !o.SubmittedAt.After(*deadline)
	return o, nil
}

// ListObjections, projeye yapılan itirazları getirir.
//
// GÜVENLİK (2026-09-26): `b.property_id` filtresi eklendi. Önceden yalnızca proje
// kimliğine bakılıyordu; başka sitenin itirazları (daire, kişi, gerekçe) okunabiliyordu.
func (r *Repository) ListObjections(ctx context.Context, propertyID, budgetID string) ([]models.Objection, error) {
	// Proje yoksa boş liste DEĞİL 404: boş liste "itiraz yok" demektir ve yanıltır.
	if ok, err := r.scope(propertyID).Exists(ctx, "operating_budgets", budgetID); err != nil {
		return nil, err
	} else if !ok {
		return nil, ErrNotFound
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT o.id, o.budget_id, COALESCE(o.unit_id::text,''), COALESCE(o.user_id::text,''),
		       o.reason, o.submitted_at, o.status, COALESCE(o.resolution,''), o.resolved_at,
		       (b.objection_deadline IS NOT NULL AND o.submitted_at::date <= b.objection_deadline)
		FROM budget_objections o
		JOIN operating_budgets b ON b.id = o.budget_id
		WHERE o.budget_id = $1 AND b.property_id = $2
		ORDER BY o.submitted_at`, budgetID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Objection{}
	for rows.Next() {
		var o models.Objection
		if err := rows.Scan(&o.ID, &o.BudgetID, &o.UnitID, &o.UserID, &o.Reason,
			&o.SubmittedAt, &o.Status, &o.Resolution, &o.ResolvedAt, &o.InTime); err != nil {
			return nil, err
		}
		out = append(out, o)
	}
	return out, rows.Err()
}

// ResolveObjection, itirazı sonuçlandırır.
//
// GÜVENLİK (2026-09-26): itirazın ait olduğu projenin sitesi denetlenir. Önceden
// yalnızca itiraz kimliğine bakılıyordu: A sitesinin yöneticisi B sitesindeki açık
// itirazı "reddedildi" yapıp B'nin işletme projesinin kesinleşme engelini
// kaldırabiliyordu (KMK m.37 — kesinleşen proje İİK m.68 belgesidir).
//
// budgetID de denetlenir: önceden yoldaki proje kimliği yok sayılıyor, aynı
// sitedeki BAŞKA bir projenin itirazı herhangi bir proje adresinden
// sonuçlandırılabiliyordu.
func (r *Repository) ResolveObjection(ctx context.Context, propertyID, budgetID, objectionID, status, resolution string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE budget_objections
		SET status = $2, resolution = NULLIF($3,''), resolved_at = now()
		WHERE id = $1 AND status = 'OPEN' AND budget_id = $5
		  AND budget_id IN (SELECT id FROM operating_budgets WHERE property_id = $4)`,
		objectionID, status, resolution, propertyID, budgetID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		var exists bool
		if err := r.scope(propertyID).QueryRow(ctx,
			`SELECT EXISTS (SELECT 1 FROM budget_objections WHERE id = $1 AND budget_id = $2)`,
			objectionID, budgetID).Scan(&exists); err != nil {
			return err
		}
		if exists {
			return ErrAlreadyDecided
		}
		return ErrNotFound
	}
	return nil
}

// -----------------------------------------------------------------------------
// GENEL KURUL
// -----------------------------------------------------------------------------

// CreateAssembly, toplantıyı gündem maddeleriyle birlikte oluşturur.
func (r *Repository) CreateAssembly(ctx context.Context, propertyID, createdBy string, in models.CreateAssemblyInput) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	kind := in.Kind
	if kind == "" {
		kind = "ORDINARY"
	}
	call := in.CallNumber
	if call == 0 {
		call = 1
	}

	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO assemblies (property_id, kind, call_number, scheduled_at, location, created_by)
		VALUES ($1, $2, $3, $4, NULLIF($5,''), NULLIF($6,'')::uuid)
		RETURNING id`,
		propertyID, kind, call, in.ScheduledAt, in.Location, createdBy).Scan(&id)
	if err != nil {
		return "", err
	}

	for i, a := range in.AgendaItems {
		order := a.OrderNo
		if order == 0 {
			order = i + 1
		}
		if _, err := tx.Exec(ctx, `
			INSERT INTO assembly_agenda_items
				(assembly_id, order_no, title, description, required_majority_code)
			VALUES ($1, $2, $3, NULLIF($4,''), NULLIF($5,''))`,
			id, order, a.Title, a.Description, a.RequiredMajorityCode); err != nil {
			return "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

// GetAssembly, toplantıyı gündem maddeleriyle getirir.
func (r *Repository) GetAssembly(ctx context.Context, propertyID, assemblyID string) (*models.Assembly, error) {
	a := &models.Assembly{}
	var noticeMethod, minutesRef *string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT id, property_id, kind, call_number, scheduled_at, COALESCE(location,''),
		       notice_sent_at, notice_method, status, held_at,
		       total_units, total_share_ratio::float8, attended_units,
		       attended_share_ratio::float8, quorum_met, minutes_ref
		FROM assemblies WHERE id = $1 AND property_id = $2`, assemblyID, propertyID).Scan(
		&a.ID, &a.PropertyID, &a.Kind, &a.CallNumber, &a.ScheduledAt, &a.Location,
		&a.NoticeSentAt, &noticeMethod, &a.Status, &a.HeldAt,
		&a.TotalUnits, &a.TotalShareRatio, &a.AttendedUnits,
		&a.AttendedShareRatio, &a.QuorumMet, &minutesRef)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	a.NoticeMethod = deref(noticeMethod)
	a.MinutesRef = deref(minutesRef)

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, assembly_id, order_no, title, COALESCE(description,''),
		       COALESCE(required_majority_code,''), COALESCE(decision_text,''), decision_status,
		       votes_for, votes_against, votes_abstain,
		       share_for::float8, share_against::float8, share_abstain::float8
		FROM assembly_agenda_items WHERE assembly_id = $1 ORDER BY order_no`, assemblyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var it models.AgendaItem
		if err := rows.Scan(&it.ID, &it.AssemblyID, &it.OrderNo, &it.Title, &it.Description,
			&it.RequiredMajorityCode, &it.DecisionText, &it.DecisionStatus,
			&it.VotesFor, &it.VotesAgainst, &it.VotesAbstain,
			&it.ShareFor, &it.ShareAgainst, &it.ShareAbstain); err != nil {
			return nil, err
		}
		a.AgendaItems = append(a.AgendaItems, it)
	}
	return a, rows.Err()
}

// ListAssemblies, sitenin toplantılarını listeler.
func (r *Repository) ListAssemblies(ctx context.Context, propertyID string) ([]models.Assembly, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, property_id, kind, call_number, scheduled_at, COALESCE(location,''),
		       notice_sent_at, status, held_at, quorum_met
		FROM assemblies WHERE property_id = $1 ORDER BY scheduled_at DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Assembly{}
	for rows.Next() {
		var a models.Assembly
		if err := rows.Scan(&a.ID, &a.PropertyID, &a.Kind, &a.CallNumber, &a.ScheduledAt,
			&a.Location, &a.NoticeSentAt, &a.Status, &a.HeldAt, &a.QuorumMet); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// NotifyAssembly, çağrının yapıldığını işler.
// noticeDays yalnızca bilgi amaçlıdır; süre denetimi service katmanında yapılır.
func (r *Repository) NotifyAssembly(ctx context.Context, propertyID, assemblyID, method string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE assemblies
		SET status = 'NOTIFIED', notice_sent_at = now(), notice_method = $3, updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PLANNED'`,
		assemblyID, propertyID, method)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrAssemblyNotOpen
	}
	return nil
}

// AddAttendee, hazirun kaydı ekler. Arsa payı toplantı anındaki değerden alınır.
func (r *Repository) AddAttendee(ctx context.Context, propertyID, assemblyID string, in models.AttendeeInput) error {
	attType := in.AttendanceType
	if attType == "" {
		attType = "SELF"
	}
	// Toplantı var mı ve hazirun alınabilir durumda mı? Önceden denetlenmiyordu:
	// yapılmış (HELD) toplantıya sonradan katılımcı eklenebiliyor ve nisap
	// fotoğrafı ile hazirun listesi birbirini tutmuyordu.
	var status string
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT status FROM assemblies WHERE id = $1 AND property_id = $2`,
		assemblyID, propertyID).Scan(&status); err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return err
	}
	if status != "PLANNED" && status != "NOTIFIED" {
		return ErrAssemblyNotOpen
	}
	tag, err := r.scope(propertyID).Exec(ctx, `
		INSERT INTO assembly_attendees
			(assembly_id, unit_id, user_id, attendance_type, proxy_holder_id, share_ratio)
		SELECT $1, u.id, NULLIF($3,'')::uuid, $4, NULLIF($5,'')::uuid, COALESCE(u.share_ratio,0)
		FROM units u
		JOIN assemblies a ON a.id = $1 AND a.property_id = u.property_id
		WHERE u.id = $2 AND u.property_id = $6 AND u.deleted = 0
		ON CONFLICT (assembly_id, unit_id) DO UPDATE
		SET attendance_type = EXCLUDED.attendance_type,
		    user_id = EXCLUDED.user_id,
		    proxy_holder_id = EXCLUDED.proxy_holder_id`,
		assemblyID, in.UnitID, in.UserID, attType, in.ProxyHolderID, propertyID)
	if err != nil {
		return err
	}
	// INSERT … SELECT, daire bu sitede yoksa SESSİZCE 0 satır ekler. Önceden bu
	// durumda "Hazirun kaydedildi" (201) dönüyordu — kaydedilmemiş bir katılımı
	// kaydedilmiş göstermek, nisabı yanlış hesaplatır.
	if tag.RowsAffected() == 0 {
		return ErrUnitNotInSite
	}
	return nil
}

// ProxyLoad, bir vekilin taşıdığı vekâlet sayısı ve oy payını verir (m.31 sınırları).
func (r *Repository) ProxyLoad(ctx context.Context, propertyID, assemblyID, holderID string) (count int, share float64, err error) {
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*), COALESCE(sum(share_ratio),0)::float8
		FROM assembly_attendees
		WHERE assembly_id = $1 AND attendance_type = 'PROXY' AND proxy_holder_id = $2
		  AND assembly_id IN (SELECT id FROM assemblies WHERE property_id = $3)`,
		assemblyID, holderID, propertyID).Scan(&count, &share)
	return
}

// AttendanceTotals, hazirun ve site toplamlarını verir.
func (r *Repository) AttendanceTotals(ctx context.Context, propertyID, assemblyID string) (
	totalUnits int, totalShare float64, attendedUnits int, attendedShare float64, err error) {
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT (SELECT count(*) FROM units WHERE property_id = $1 AND deleted = 0),
		       (SELECT COALESCE(sum(share_ratio),0)::float8 FROM units WHERE property_id = $1 AND deleted = 0),
		       (SELECT count(*) FROM assembly_attendees
		          WHERE assembly_id = $2
		            AND assembly_id IN (SELECT id FROM assemblies WHERE property_id = $1)),
		       (SELECT COALESCE(sum(share_ratio),0)::float8 FROM assembly_attendees
		          WHERE assembly_id = $2
		            AND assembly_id IN (SELECT id FROM assemblies WHERE property_id = $1))`,
		propertyID, assemblyID).Scan(&totalUnits, &totalShare, &attendedUnits, &attendedShare)
	return
}

// HoldAssembly, toplantıyı yapılmış olarak işaretler ve nisap fotoğrafını saklar.
func (r *Repository) HoldAssembly(ctx context.Context, propertyID, assemblyID string, q models.QuorumResult) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE assemblies
		SET status = 'HELD', held_at = now(),
		    total_units = $3, total_share_ratio = $4,
		    attended_units = $5, attended_share_ratio = $6, quorum_met = $7,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status IN ('PLANNED','NOTIFIED')`,
		assemblyID, propertyID, q.TotalUnits, q.TotalShareRatio,
		q.AttendedUnits, q.AttendedShareRatio, q.Met)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrAssemblyNotOpen
	}
	return nil
}

// CastVote, oy kaydeder ve gündem maddesinin sayaçlarını günceller.
// Oy yalnızca hazirun listesindeki bağımsız bölümler için kabul edilir.
func (r *Repository) CastVote(ctx context.Context, propertyID, agendaItemID string, in models.VoteInput, castBy string) error {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Önce madde ve toplantı: önceden madde yoksa da "hazirunda yok" (400)
	// dönüyordu; toplantı durumu ve maddenin sonuçlanıp sonuçlanmadığı hiç
	// denetlenmiyordu — KARARA BAĞLANMIŞ maddeye oy eklenip sayaçlar
	// değiştirilebiliyordu.
	var assemblyStatus, decision string
	err = tx.QueryRow(ctx, `
		SELECT a.status, ai.decision_status
		FROM assembly_agenda_items ai
		JOIN assemblies a ON a.id = ai.assembly_id AND a.property_id = $2
		WHERE ai.id = $1 FOR UPDATE OF ai`, agendaItemID, propertyID).Scan(&assemblyStatus, &decision)
	if err == pgx.ErrNoRows {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if assemblyStatus != "HELD" {
		return ErrAssemblyNotOpen
	}
	if decision != "PENDING" {
		return ErrAlreadyDecided
	}

	var share float64
	err = tx.QueryRow(ctx, `
		SELECT at.share_ratio::float8
		FROM assembly_agenda_items ai
		JOIN assembly_attendees at ON at.assembly_id = ai.assembly_id AND at.unit_id = $2
		WHERE ai.id = $1`, agendaItemID, in.UnitID).Scan(&share)
	if err == pgx.ErrNoRows {
		return ErrNotAttending
	}
	if err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO assembly_votes (agenda_item_id, unit_id, vote, share_ratio, cast_by)
		VALUES ($1, $2, $3, $4, NULLIF($5,'')::uuid)
		ON CONFLICT (agenda_item_id, unit_id) DO UPDATE
		SET vote = EXCLUDED.vote, share_ratio = EXCLUDED.share_ratio, cast_at = now()`,
		agendaItemID, in.UnitID, in.Vote, share, castBy); err != nil {
		return err
	}

	// Sayaçları oylardan yeniden hesapla — artımlı güncelleme, oy değişiminde sapar.
	if _, err := tx.Exec(ctx, `
		UPDATE assembly_agenda_items ai
		SET votes_for     = v.f,  votes_against = v.a,  votes_abstain = v.b,
		    share_for     = v.sf, share_against = v.sa, share_abstain = v.sb
		FROM (
			SELECT count(*) FILTER (WHERE vote='FOR')     AS f,
			       count(*) FILTER (WHERE vote='AGAINST') AS a,
			       count(*) FILTER (WHERE vote='ABSTAIN') AS b,
			       COALESCE(sum(share_ratio) FILTER (WHERE vote='FOR'),0)     AS sf,
			       COALESCE(sum(share_ratio) FILTER (WHERE vote='AGAINST'),0) AS sa,
			       COALESCE(sum(share_ratio) FILTER (WHERE vote='ABSTAIN'),0) AS sb
			FROM assembly_votes WHERE agenda_item_id = $1
		) v
		WHERE ai.id = $1`, agendaItemID); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// GetAgendaItem, tek gündem maddesini ve ait olduğu toplantıyı getirir.
func (r *Repository) GetAgendaItem(ctx context.Context, propertyID, agendaItemID string) (*models.AgendaItem, *models.Assembly, error) {
	var assemblyID string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT ai.assembly_id::text
		FROM assembly_agenda_items ai
		JOIN assemblies a ON a.id = ai.assembly_id AND a.property_id = $2
		WHERE ai.id = $1`, agendaItemID, propertyID).Scan(&assemblyID)
	if err == pgx.ErrNoRows {
		return nil, nil, ErrNotFound
	}
	if err != nil {
		return nil, nil, err
	}

	assembly, err := r.GetAssembly(ctx, propertyID, assemblyID)
	if err != nil {
		return nil, nil, err
	}
	for i := range assembly.AgendaItems {
		if assembly.AgendaItems[i].ID == agendaItemID {
			return &assembly.AgendaItems[i], assembly, nil
		}
	}
	return nil, nil, ErrNotFound
}

// CloseAgendaItem, nisap değerlendirmesinin sonucunu yazar.
func (r *Repository) CloseAgendaItem(ctx context.Context, propertyID, agendaItemID, status, decisionText string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE assembly_agenda_items
		SET decision_status = $2, decision_text = NULLIF($3,'')
		WHERE id = $1 AND decision_status = 'PENDING'
		  AND assembly_id IN (SELECT id FROM assemblies WHERE property_id = $4)`,
		agendaItemID, status, decisionText, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "assembly_agenda_items", agendaItemID, ErrNotFound, ErrAlreadyDecided)
	}
	return nil
}

// -----------------------------------------------------------------------------
// DEFTERLER
// -----------------------------------------------------------------------------

// EnsureBook, ilgili yıl için defteri yoksa oluşturur.
func (r *Repository) EnsureBook(ctx context.Context, propertyID, kind string, year int) (*models.Book, error) {
	_, err := r.scope(propertyID).Exec(ctx, `
		INSERT INTO books (property_id, kind, period_year)
		VALUES ($1, $2, $3) ON CONFLICT (property_id, kind, period_year) DO NOTHING`,
		propertyID, kind, year)
	if err != nil {
		return nil, err
	}

	b := &models.Book{}
	var notaryRef *string
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT id, property_id, kind, period_year, notary_opened_at, notary_closed_at,
		       notary_ref, status,
		       (SELECT count(*) FROM book_entries e WHERE e.book_id = books.id)
		FROM books WHERE property_id=$1 AND kind=$2 AND period_year=$3`,
		propertyID, kind, year).Scan(&b.ID, &b.PropertyID, &b.Kind, &b.PeriodYear,
		&b.NotaryOpenedAt, &b.NotaryClosedAt, &notaryRef, &b.Status, &b.EntryCount)
	if err != nil {
		return nil, err
	}
	b.NotaryRef = deref(notaryRef)
	return b, nil
}

// AppendBookEntry, deftere yeni kayıt ekler ve hash zincirini sürdürür.
//
// Hash = SHA256(prev_hash | entry_no | entry_date | title | body | source_type | source_id)
// Bir kayıt sonradan değiştirilirse (tetikleyici engelliyor ama doğrudan veritabanı
// erişimi düşünülerek) zincir doğrulaması bunu yakalar.
//
// GÜVENLİK (2026-09-26): defterin sitesi denetlenir. Önceden yalnızca defter
// kimliğine bakılıyordu; A sitesinin yöneticisi B sitesinin KARAR DEFTERİNE
// kayıt ekleyebiliyordu. Karar defteri hukuki kayıttır (KMK m.32) ve hash
// zinciri eklenen kaydı "geçerli" gösterirdi — zincir sahteciliği değil,
// yetkisiz ama zincire uygun kayıt.
func (r *Repository) AppendBookEntry(ctx context.Context, propertyID, bookID, createdBy string, in models.CreateBookEntryInput) (*models.BookEntry, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status string
	if err := tx.QueryRow(ctx,
		`SELECT status FROM books WHERE id = $1 AND property_id = $2 FOR UPDATE`, bookID, propertyID).
		Scan(&status); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if status != "OPEN" {
		return nil, ErrBookClosed
	}

	var lastNo int
	var prevHash *string
	err = tx.QueryRow(ctx, `
		SELECT entry_no, entry_hash FROM book_entries
		WHERE book_id = $1 ORDER BY entry_no DESC LIMIT 1`, bookID).Scan(&lastNo, &prevHash)
	if err != nil && err != pgx.ErrNoRows {
		return nil, err
	}

	entryDate := time.Now()
	if in.EntryDate != "" {
		if d, perr := time.Parse("2006-01-02", in.EntryDate); perr == nil {
			entryDate = d
		}
	}

	e := &models.BookEntry{
		BookID:     bookID,
		EntryNo:    lastNo + 1,
		EntryDate:  entryDate,
		Title:      in.Title,
		Body:       in.Body,
		SourceType: in.SourceType,
		SourceID:   in.SourceID,
		CreatedBy:  createdBy,
		PrevHash:   deref(prevHash),
	}
	e.EntryHash = ComputeEntryHash(e)

	err = tx.QueryRow(ctx, `
		INSERT INTO book_entries
			(book_id, entry_no, entry_date, title, body, source_type, source_id,
			 created_by, prev_hash, entry_hash)
		VALUES ($1,$2,$3,$4,$5,NULLIF($6,''),NULLIF($7,'')::uuid,NULLIF($8,'')::uuid,
		        NULLIF($9,''),$10)
		RETURNING id, created_at`,
		bookID, e.EntryNo, e.EntryDate, e.Title, e.Body, e.SourceType, e.SourceID,
		createdBy, e.PrevHash, e.EntryHash).Scan(&e.ID, &e.CreatedAt)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return e, nil
}

// ComputeEntryHash, defter kaydının hash'ini üretir.
// Alan sırası sözleşmedir; değiştirilirse geçmiş defterlerin doğrulaması bozulur.
func ComputeEntryHash(e *models.BookEntry) string {
	h := sha256.New()
	fmt.Fprintf(h, "%s|%d|%s|%s|%s|%s|%s",
		e.PrevHash, e.EntryNo, e.EntryDate.Format("2006-01-02"),
		e.Title, e.Body, e.SourceType, e.SourceID)
	return hex.EncodeToString(h.Sum(nil))
}

// ListBookEntries, defter kayıtlarını sırayla getirir.
//
// Defter başka siteye aitse ya da yoksa ErrNotFound döner — boş liste DEĞİL:
// boş liste "bu defterde kayıt yok" anlamına gelir ve yanıltıcı olurdu.
func (r *Repository) ListBookEntries(ctx context.Context, propertyID, bookID string) ([]models.BookEntry, error) {
	var owned bool
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM books WHERE id = $1 AND property_id = $2)`,
		bookID, propertyID).Scan(&owned); err != nil {
		return nil, err
	}
	if !owned {
		return nil, ErrNotFound
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, book_id, entry_no, entry_date, title, body,
		       COALESCE(source_type,''), COALESCE(source_id::text,''),
		       COALESCE(created_by::text,''), created_at,
		       COALESCE(prev_hash,''), entry_hash
		FROM book_entries
		WHERE book_id = $1
		  AND book_id IN (SELECT id FROM books WHERE property_id = $2)
		ORDER BY entry_no`, bookID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.BookEntry{}
	for rows.Next() {
		var e models.BookEntry
		if err := rows.Scan(&e.ID, &e.BookID, &e.EntryNo, &e.EntryDate, &e.Title, &e.Body,
			&e.SourceType, &e.SourceID, &e.CreatedBy, &e.CreatedAt,
			&e.PrevHash, &e.EntryHash); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

// VerifyBook, defterin hash zincirini baştan sona doğrular.
func (r *Repository) VerifyBook(ctx context.Context, propertyID, bookID string) (*models.BookIntegrity, error) {
	entries, err := r.ListBookEntries(ctx, propertyID, bookID)
	if err != nil {
		return nil, err
	}

	result := &models.BookIntegrity{BookID: bookID, EntryCount: len(entries), Valid: true}
	prev := ""
	for i := range entries {
		e := entries[i]
		if e.PrevHash != prev {
			result.Valid = false
			result.BrokenAtNo = e.EntryNo
			result.Message = fmt.Sprintf(
				"%d numaralı kayıtta zincir kırık: önceki kaydın hash'i beklenenle uyuşmuyor. "+
					"Defter üzerinde yetkisiz değişiklik yapılmış olabilir.", e.EntryNo)
			return result, nil
		}
		if ComputeEntryHash(&e) != e.EntryHash {
			result.Valid = false
			result.BrokenAtNo = e.EntryNo
			result.Message = fmt.Sprintf(
				"%d numaralı kaydın içeriği hash'iyle uyuşmuyor; kayıt sonradan değiştirilmiş.", e.EntryNo)
			return result, nil
		}
		prev = e.EntryHash
	}
	result.Message = fmt.Sprintf("Defter bütünlüğü doğrulandı: %d kayıt, zincir sağlam.", len(entries))
	return result, nil
}

// CloseBook, defteri notere kapattırıldı olarak işaretler (m.36).
func (r *Repository) CloseBook(ctx context.Context, propertyID, bookID, notaryRef string, closedAt time.Time) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE books SET status='CLOSED', notary_closed_at=$3, notary_ref=NULLIF($4,'')
		WHERE id=$1 AND property_id=$2 AND status='OPEN'`,
		bookID, propertyID, closedAt, notaryRef)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "books", bookID, ErrNotFound, ErrBookClosed)
	}
	return nil
}

// -----------------------------------------------------------------------------
// HUKUK / İCRA
// -----------------------------------------------------------------------------

// CreateLegalCase, takip kaydı açar. Anapara ve gecikme tazminatı, birimin
// ödenmemiş tahakkuklarından hesaplanır.
func (r *Repository) CreateLegalCase(ctx context.Context, propertyID string, in models.CreateLegalCaseInput,
	principalKurus, lateFeeKurus int64) (string, error) {
	// Daire bu siteye ait mi? Önceden yalnızca yabancı anahtar denetleniyordu:
	// BAŞKA sitenin dairesi için takip açılabiliyor (borç 0 hesaplanıyordu).
	var ok bool
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM units WHERE id = $1 AND property_id = $2)`,
		in.UnitID, propertyID).Scan(&ok); err != nil {
		return "", err
	}
	if !ok {
		return "", ErrUnitNotInSite
	}
	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO legal_cases
			(property_id, unit_id, debtor_user_id, case_type, principal_kurus, late_fee_kurus,
			 basis_document_type, basis_document_id, office_or_court, file_no, lawyer_name, note)
		VALUES ($1, $2, NULLIF($3,'')::uuid, $4, $5, $6, NULLIF($7,''), NULLIF($8,'')::uuid,
		        NULLIF($9,''), NULLIF($10,''), NULLIF($11,''), NULLIF($12,''))
		RETURNING id`,
		propertyID, in.UnitID, in.DebtorUserID, in.CaseType, principalKurus, lateFeeKurus,
		in.BasisDocumentType, in.BasisDocumentID, in.OfficeOrCourt, in.FileNo,
		in.LawyerName, in.Note).Scan(&id)
	return id, err
}

// ListLegalCases, sitenin takiplerini listeler.
func (r *Repository) ListLegalCases(ctx context.Context, propertyID string) ([]models.LegalCase, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, property_id, COALESCE(unit_id::text,''), COALESCE(debtor_user_id::text,''),
		       case_type, status, principal_kurus, late_fee_kurus,
		       COALESCE(basis_document_type,''), COALESCE(basis_document_id::text,''),
		       filed_at, COALESCE(office_or_court,''), COALESCE(file_no,''),
		       COALESCE(lawyer_name,''), COALESCE(note,'')
		FROM legal_cases WHERE property_id=$1 ORDER BY created_at DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.LegalCase{}
	for rows.Next() {
		var c models.LegalCase
		if err := rows.Scan(&c.ID, &c.PropertyID, &c.UnitID, &c.DebtorUserID, &c.CaseType,
			&c.Status, &c.PrincipalKurus, &c.LateFeeKurus, &c.BasisDocumentType,
			&c.BasisDocumentID, &c.FiledAt, &c.OfficeOrCourt, &c.FileNo,
			&c.LawyerName, &c.Note); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// UnitDebt, bir bağımsız bölümün ödenmemiş ortak gider borcunu kuruş olarak verir.
func (r *Repository) UnitDebt(ctx context.Context, propertyID, unitID string) (principal, lateFee int64, err error) {
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT COALESCE(sum(round((total_amount - COALESCE(paid_amount,0) - COALESCE(late_fee,0)) * 100)), 0)::bigint,
		       COALESCE(sum(round(COALESCE(late_fee,0) * 100)), 0)::bigint
		FROM monthly_assessments
		WHERE property_id = $1 AND unit_id = $2 AND deleted = 0
		  AND total_amount > COALESCE(paid_amount, 0)`, propertyID, unitID).Scan(&principal, &lateFee)
	return
}

// -----------------------------------------------------------------------------

// CategoryVisible, gider kaleminin bu sitede kullanılabilir olduğunu söyler
// (siteye ait ya da ortak şablon). Yabancı anahtar denetimi RLS'i atlar;
// denetlenmeseydi başka sitenin kalemi bütçeye bağlanabilirdi.
func (r *Repository) CategoryVisible(ctx context.Context, propertyID, categoryID string) (bool, error) {
	var ok bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM expense_categories
		               WHERE id = $1 AND (property_id = $2 OR property_id IS NULL))`,
		categoryID, propertyID).Scan(&ok)
	return ok, err
}

// stateOrNotFound, 0 satır etkileyen durum geçişinde kaydın hiç olmadığını
// (notFound) durumunun uygun olmadığından (state) ayırır.
func (r *Repository) stateOrNotFound(ctx context.Context, propertyID, table, id string, notFound, state error) error {
	ok, err := r.scope(propertyID).Exists(ctx, table, id)
	if err != nil {
		return err
	}
	if !ok {
		return notFound
	}
	return state
}

// IsInvalidID, istemciden gelen bir kimliğin UUID biçiminde olmadığı için
// veritabanının reddettiğini bildirir (PostgreSQL 22P02). Handler bunu
// "bulunamadı" olarak döndürür; 500 dönmek hem yanlış hem de sunucu arızası
// gibi alarm üretir.
func IsInvalidID(err error) bool { return containsCode(err, "22P02") }

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func isUniqueViolation(err error) bool {
	return err != nil && (containsCode(err, "23505"))
}

func containsCode(err error, code string) bool {
	type coder interface{ SQLState() string }
	var c coder
	if errors.As(err, &c) {
		return c.SQLState() == code
	}
	return false
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// Yönetişim tablolarında RLS açıktır (migration 024). Uygulama katmanındaki
// `property_id` filtreleri korunur; RLS onları YEDEKLER. Bu modülde yedeğin
// değeri somuttur: beş sorguda filtre hiç yoktu.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
