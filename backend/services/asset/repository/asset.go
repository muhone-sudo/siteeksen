// Package repository, demirbaş (sabit kıymet) modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrNotFound        = errors.New("demirbaş bulunamadı")
	ErrBadState        = errors.New("demirbaş bu işlem için uygun durumda değil")
	ErrInvalidCategory = errors.New("kategori bu siteye ait değil")
	ErrDuplicateCode   = errors.New("bu demirbaş kodu zaten kullanılıyor")
	ErrInvalidDate     = errors.New("tarih geçersiz")
)

// Conditions ve Statuses, migration 005'teki CHECK kısıtlarıyla birebir aynıdır.
var (
	Conditions = []string{"NEW", "GOOD", "FAIR", "POOR", "DISPOSED", "LOST"}
	Statuses   = []string{"ACTIVE", "IN_MAINTENANCE", "RESERVED", "DISPOSED"}
	// MaintenanceTypes, bakım kaydı türleridir (şemada CHECK yok; burada sınırlanır).
	MaintenanceTypes = []string{"PREVENTIVE", "CORRECTIVE", "INSPECTION"}
)

// Category, demirbaş kategorisidir.
type Category struct {
	ID                string `json:"id"`
	Name              string `json:"name"`
	Description       string `json:"description,omitempty"`
	DepreciationYears int    `json:"depreciation_years"`
	IsGlobal          bool   `json:"is_global"`
	AssetCount        int    `json:"asset_count"`
}

// Asset, bir demirbaş kaydıdır.
//
// Amortisman alanları (BookValue, AccumulatedDepreciation) veritabanındaki
// `current_value` / `accumulated_depreciation` kolonlarından OKUNMAZ; her
// okumada yeniden hesaplanır. Saklanan değer, üzerinden zaman geçtikçe
// sessizce yanlışa döner ve yanlış bir defter değeri işletme projesine
// (KMK m.37) yanlış gider tahmini olarak yansır.
type Asset struct {
	ID           string `json:"id"`
	CategoryID   string `json:"category_id,omitempty"`
	CategoryName string `json:"category_name,omitempty"`
	Name         string `json:"name"`
	Description  string `json:"description,omitempty"`

	AssetCode    string `json:"asset_code,omitempty"`
	SerialNumber string `json:"serial_number,omitempty"`

	Location string `json:"location,omitempty"`
	Building string `json:"building,omitempty"`
	Floor    string `json:"floor,omitempty"`
	Room     string `json:"room,omitempty"`

	PurchaseDate  *time.Time `json:"purchase_date,omitempty"`
	PurchasePrice *float64   `json:"purchase_price,omitempty"`
	Vendor        string     `json:"vendor,omitempty"`

	WarrantyEnd *time.Time `json:"warranty_end,omitempty"`
	// WarrantyDaysLeft negatifse garanti bitmiştir. Garanti tanımsızsa null.
	WarrantyDaysLeft *int `json:"warranty_days_left,omitempty"`

	DepreciationMethod string   `json:"depreciation_method"`
	DepreciationYears  *int     `json:"depreciation_years,omitempty"`
	ResidualValue      float64  `json:"residual_value"`
	AccumulatedDeprec  *float64 `json:"accumulated_depreciation,omitempty"`
	BookValue          *float64 `json:"book_value,omitempty"`

	Condition string `json:"condition"`
	Status    string `json:"status"`

	AssignedTo string     `json:"assigned_to,omitempty"`
	AssignedAt *time.Time `json:"assigned_at,omitempty"`

	LastMaintenanceDate *time.Time `json:"last_maintenance_date,omitempty"`
	NextMaintenanceDate *time.Time `json:"next_maintenance_date,omitempty"`
	MaintenanceInterval *int       `json:"maintenance_interval_days,omitempty"`
	// MaintenanceOverdueDays > 0 ise bakım gecikmiştir.
	MaintenanceOverdueDays *int `json:"maintenance_overdue_days,omitempty"`

	Notes     string    `json:"notes,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// Maintenance, bir bakım/onarım kaydıdır.
type Maintenance struct {
	ID              string     `json:"id"`
	AssetID         string     `json:"asset_id"`
	AssetName       string     `json:"asset_name,omitempty"`
	MaintenanceType string     `json:"maintenance_type"`
	Description     string     `json:"description"`
	LaborCost       float64    `json:"labor_cost"`
	PartsCost       float64    `json:"parts_cost"`
	TotalCost       float64    `json:"total_cost"`
	PerformedBy     string     `json:"performed_by,omitempty"`
	Vendor          string     `json:"vendor,omitempty"`
	PerformedAt     *time.Time `json:"performed_at,omitempty"`
	NextDue         *time.Time `json:"next_due,omitempty"`
	Status          string     `json:"status"`
	Notes           string     `json:"notes,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// ListCategories, siteye ait ve global kategorileri döner.
func (r *Repository) ListCategories(ctx context.Context, propertyID string) ([]Category, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT c.id, c.name, COALESCE(c.description,''),
		       COALESCE(c.depreciation_years,5), (c.property_id IS NULL),
		       (SELECT count(*) FROM assets a WHERE a.category_id = c.id AND a.property_id = $1)
		FROM asset_categories c
		WHERE c.property_id = $1 OR c.property_id IS NULL
		ORDER BY (c.property_id IS NULL), c.name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Category{}
	for rows.Next() {
		var c Category
		if err := rows.Scan(&c.ID, &c.Name, &c.Description, &c.DepreciationYears,
			&c.IsGlobal, &c.AssetCount); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// CreateCategory, siteye özel kategori ekler.
func (r *Repository) CreateCategory(ctx context.Context, propertyID, name, description string, years int) (string, error) {
	if years <= 0 {
		years = 5
	}
	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO asset_categories (property_id, name, description, depreciation_years)
		VALUES ($1,$2,NULLIF($3,''),$4) RETURNING id`,
		propertyID, name, description, years).Scan(&id)
	return id, err
}

const assetSelect = `
SELECT a.id, COALESCE(a.category_id::text,''), COALESCE(c.name,''),
       a.name, COALESCE(a.description,''),
       COALESCE(a.asset_code,''), COALESCE(a.serial_number,''),
       COALESCE(a.location,''), COALESCE(a.building,''), COALESCE(a.floor,''), COALESCE(a.room,''),
       a.purchase_date, a.purchase_price::float8, COALESCE(a.vendor,''),
       a.warranty_end,
       CASE WHEN a.warranty_end IS NULL THEN NULL ELSE (a.warranty_end - CURRENT_DATE) END,
       COALESCE(a.depreciation_method,'LINEAR'),
       COALESCE(a.depreciation_years, c.depreciation_years),
       COALESCE(a.residual_value,0)::float8,
       COALESCE(a.condition,'GOOD'), COALESCE(a.status,'ACTIVE'),
       COALESCE(a.assigned_to,''), a.assigned_at,
       a.last_maintenance_date, a.next_maintenance_date, a.maintenance_interval_days,
       CASE WHEN a.next_maintenance_date IS NULL OR a.next_maintenance_date >= CURRENT_DATE
            THEN NULL ELSE (CURRENT_DATE - a.next_maintenance_date) END,
       COALESCE(a.notes,''), a.created_at
FROM assets a
LEFT JOIN asset_categories c ON c.id = a.category_id`

func scanAsset(row pgx.Row) (*Asset, error) {
	var a Asset
	err := row.Scan(&a.ID, &a.CategoryID, &a.CategoryName, &a.Name, &a.Description,
		&a.AssetCode, &a.SerialNumber, &a.Location, &a.Building, &a.Floor, &a.Room,
		&a.PurchaseDate, &a.PurchasePrice, &a.Vendor,
		&a.WarrantyEnd, &a.WarrantyDaysLeft,
		&a.DepreciationMethod, &a.DepreciationYears, &a.ResidualValue,
		&a.Condition, &a.Status, &a.AssignedTo, &a.AssignedAt,
		&a.LastMaintenanceDate, &a.NextMaintenanceDate, &a.MaintenanceInterval,
		&a.MaintenanceOverdueDays, &a.Notes, &a.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &a, nil
}

// ListFilter, demirbaş listeleme ölçütleridir.
type ListFilter struct {
	CategoryID      string
	Status          string
	Condition       string
	Location        string
	MaintenanceDue  bool
	WarrantyExpires int // gün; >0 ise bu süre içinde garantisi bitecekler
	IncludeDisposed bool
}

// List, demirbaşları getirir.
func (r *Repository) List(ctx context.Context, propertyID string, f ListFilter) ([]Asset, error) {
	rows, err := r.scope(propertyID).Query(ctx, assetSelect+`
		WHERE a.property_id = $1
		  AND ($2 = '' OR a.category_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR a.status = $3)
		  AND ($4 = '' OR a.condition = $4)
		  AND ($5 = '' OR a.location ILIKE '%' || $5 || '%')
		  AND ($6 = false OR (a.next_maintenance_date IS NOT NULL
		                      AND a.next_maintenance_date < CURRENT_DATE))
		  AND ($7 = 0 OR (a.warranty_end IS NOT NULL
		                  AND a.warranty_end <= CURRENT_DATE + make_interval(days => $7)))
		  AND ($8 OR a.status <> 'DISPOSED')
		ORDER BY a.name
		LIMIT 1000`,
		propertyID, f.CategoryID, strings.ToUpper(f.Status), strings.ToUpper(f.Condition),
		f.Location, f.MaintenanceDue, f.WarrantyExpires, f.IncludeDisposed)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Asset{}
	for rows.Next() {
		a, err := scanAsset(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *a)
	}
	return out, rows.Err()
}

// Get, tek demirbaşı getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id string) (*Asset, error) {
	a, err := scanAsset(r.scope(propertyID).QueryRow(ctx,
		assetSelect+` WHERE a.property_id = $1 AND a.id = $2`, propertyID, id))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return a, err
}

// CreateInput, yeni demirbaş girdisidir.
type CreateInput struct {
	CategoryID   string `json:"category_id"`
	Name         string `json:"name" binding:"required"`
	Description  string `json:"description"`
	AssetCode    string `json:"asset_code"`
	SerialNumber string `json:"serial_number"`

	Location string `json:"location"`
	Building string `json:"building"`
	Floor    string `json:"floor"`
	Room     string `json:"room"`

	PurchaseDate    string   `json:"purchase_date"`
	PurchasePrice   *float64 `json:"purchase_price"`
	PurchaseInvoice string   `json:"purchase_invoice"`
	Vendor          string   `json:"vendor"`

	WarrantyStart string `json:"warranty_start"`
	WarrantyEnd   string `json:"warranty_end"`

	DepreciationYears *int     `json:"depreciation_years"`
	ResidualValue     *float64 `json:"residual_value"`

	Condition           string `json:"condition"`
	MaintenanceInterval *int   `json:"maintenance_interval_days"`
	Notes               string `json:"notes"`
}

// Create, demirbaşı kaydeder.
func (r *Repository) Create(ctx context.Context, propertyID string, in CreateInput) (string, error) {
	if in.CategoryID != "" {
		var ok bool
		if err := r.scope(propertyID).QueryRow(ctx, `
			SELECT EXISTS(SELECT 1 FROM asset_categories
			              WHERE id = $1 AND (property_id = $2 OR property_id IS NULL))`,
			in.CategoryID, propertyID).Scan(&ok); err != nil {
			return "", err
		}
		if !ok {
			return "", ErrInvalidCategory
		}
	}

	purchase, err := parseOptionalDate(in.PurchaseDate)
	if err != nil {
		return "", err
	}
	wStart, err := parseOptionalDate(in.WarrantyStart)
	if err != nil {
		return "", err
	}
	wEnd, err := parseOptionalDate(in.WarrantyEnd)
	if err != nil {
		return "", err
	}
	if wStart != nil && wEnd != nil && wEnd.Before(*wStart) {
		return "", ErrInvalidDate
	}

	condition := strings.ToUpper(strings.TrimSpace(in.Condition))
	if condition == "" {
		condition = "GOOD"
	}
	if !contains(Conditions, condition) {
		return "", ErrBadState
	}

	// İlk bakım tarihi, satın alma tarihine aralık eklenerek belirlenir; satın
	// alma tarihi yoksa bugünden başlar. Boş bırakmak, bakımın hiç hatırlatılmaması
	// demektir.
	var nextMaintenance *time.Time
	if in.MaintenanceInterval != nil && *in.MaintenanceInterval > 0 {
		base := time.Now()
		if purchase != nil {
			base = *purchase
		}
		nm := base.AddDate(0, 0, *in.MaintenanceInterval)
		nextMaintenance = &nm
	}

	var id string
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO assets
			(property_id, category_id, name, description, asset_code, serial_number,
			 location, building, floor, room,
			 purchase_date, purchase_price, purchase_invoice, vendor,
			 warranty_start, warranty_end,
			 depreciation_method, depreciation_years, residual_value,
			 condition, status, maintenance_interval_days, next_maintenance_date, notes)
		VALUES ($1,NULLIF($2,'')::uuid,$3,NULLIF($4,''),NULLIF($5,''),NULLIF($6,''),
		        NULLIF($7,''),NULLIF($8,''),NULLIF($9,''),NULLIF($10,''),
		        $11,$12,NULLIF($13,''),NULLIF($14,''),
		        $15,$16,
		        'LINEAR',$17,COALESCE($18,0),
		        $19,'ACTIVE',$20,$21,NULLIF($22,''))
		RETURNING id`,
		propertyID, in.CategoryID, in.Name, in.Description, in.AssetCode, in.SerialNumber,
		in.Location, in.Building, in.Floor, in.Room,
		purchase, in.PurchasePrice, in.PurchaseInvoice, in.Vendor,
		wStart, wEnd,
		in.DepreciationYears, in.ResidualValue,
		condition, in.MaintenanceInterval, nextMaintenance, in.Notes).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "duplicate key") {
		return "", ErrDuplicateCode
	}
	return id, err
}

// Assign, demirbaşı bir kişiye/birime zimmetler. Boş ad zimmeti kaldırır.
func (r *Repository) Assign(ctx context.Context, propertyID, id, assignee string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE assets
		SET assigned_to = NULLIF($3,''),
		    assigned_at = CASE WHEN $3 = '' THEN NULL ELSE CURRENT_DATE END,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status <> 'DISPOSED'`,
		id, propertyID, strings.TrimSpace(assignee))
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// Dispose, demirbaşı kayıttan düşer (hurda/satış/kayıp).
//
// KMK m.45: ortak yerler üzerinde temliki tasarruf (satış, devir) için kat
// maliklerinin OYBİRLİĞİ gerekir. Bu yüzden elden çıkarma, gerekçesinin yanı sıra
// bir KARAR DAYANAĞI (genel kurul karar tarih/no) olmadan kaydedilmez. Kayıt
// silinmez; durumu DISPOSED olur ve geçmişi korunur.
func (r *Repository) Dispose(ctx context.Context, propertyID, id, reason, decisionRef, condition string) error {
	if condition == "" {
		condition = "DISPOSED"
	}
	if !contains(Conditions, condition) {
		return ErrBadState
	}
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE assets
		SET status = 'DISPOSED', condition = $5,
		    assigned_to = NULL, assigned_at = NULL,
		    next_maintenance_date = NULL,
		    notes = COALESCE(notes || E'\n', '') ||
		            'Kayıttan düşme (' || CURRENT_DATE || ') — karar: ' || $4 || ' — gerekçe: ' || $3,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status <> 'DISPOSED'`,
		id, propertyID, reason, decisionRef, condition)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// MaintenanceInput, bakım kaydı girdisidir.
type MaintenanceInput struct {
	MaintenanceType string   `json:"maintenance_type" binding:"required"`
	Description     string   `json:"description" binding:"required"`
	LaborCost       float64  `json:"labor_cost"`
	PartsCost       float64  `json:"parts_cost"`
	PerformedBy     string   `json:"performed_by"`
	Vendor          string   `json:"vendor"`
	PerformedAt     string   `json:"performed_at"`
	Notes           string   `json:"notes"`
	NewCondition    string   `json:"new_condition"`
	TotalCost       *float64 `json:"total_cost"`
}

// RecordMaintenance, bakımı kaydeder ve demirbaşın bakım takvimini AYNI
// TRANSACTION içinde günceller.
//
// İkisi ayrı yapılırsa bakım kaydı düşer ama "sıradaki bakım" tarihi eski kalır;
// yönetici bakımı yapılmış bir cihazı sürekli gecikmiş görür ve listeye güveni biter.
func (r *Repository) RecordMaintenance(ctx context.Context, propertyID, assetID string, in MaintenanceInput) (string, error) {
	mType := strings.ToUpper(strings.TrimSpace(in.MaintenanceType))
	if !contains(MaintenanceTypes, mType) {
		return "", ErrBadState
	}
	performed, err := parseOptionalDate(in.PerformedAt)
	if err != nil {
		return "", err
	}
	if performed == nil {
		now := time.Now()
		performed = &now
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var interval *int
	var status string
	if err := tx.QueryRow(ctx, `
		SELECT maintenance_interval_days, status
		FROM assets WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		assetID, propertyID).Scan(&interval, &status); err != nil {
		if err == pgx.ErrNoRows {
			return "", ErrNotFound
		}
		return "", err
	}
	if status == "DISPOSED" {
		return "", ErrBadState
	}

	// Toplam maliyet sunucuda hesaplanır; istemcinin gönderdiği toplam
	// kalemlerle tutmayabilir ve gider raporu sessizce yanlış çıkar.
	total := in.LaborCost + in.PartsCost

	var nextDue *time.Time
	if interval != nil && *interval > 0 {
		nd := performed.AddDate(0, 0, *interval)
		nextDue = &nd
	}

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO asset_maintenance
			(asset_id, maintenance_type, description, labor_cost, parts_cost, total_cost,
			 performed_by, vendor, performed_at, next_due, status, notes)
		VALUES ($1,$2,$3,$4,$5,$6,NULLIF($7,''),NULLIF($8,''),$9,$10,'COMPLETED',NULLIF($11,''))
		RETURNING id`,
		assetID, mType, in.Description, in.LaborCost, in.PartsCost, total,
		in.PerformedBy, in.Vendor, performed, nextDue, in.Notes).Scan(&id); err != nil {
		return "", err
	}

	newCondition := strings.ToUpper(strings.TrimSpace(in.NewCondition))
	if newCondition != "" && !contains(Conditions, newCondition) {
		return "", ErrBadState
	}
	if _, err := tx.Exec(ctx, `
		UPDATE assets
		SET last_maintenance_date = $3,
		    next_maintenance_date = $4,
		    condition = COALESCE(NULLIF($5,''), condition),
		    updated_at = now()
		WHERE id = $1 AND property_id = $2`,
		assetID, propertyID, performed, nextDue, newCondition); err != nil {
		return "", err
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

// MaintenanceHistory, demirbaşın bakım geçmişini döner.
func (r *Repository) MaintenanceHistory(ctx context.Context, propertyID, assetID string) ([]Maintenance, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT m.id, m.asset_id, a.name, m.maintenance_type, m.description,
		       COALESCE(m.labor_cost,0)::float8, COALESCE(m.parts_cost,0)::float8,
		       COALESCE(m.total_cost,0)::float8,
		       COALESCE(m.performed_by,''), COALESCE(m.vendor,''),
		       m.performed_at, m.next_due, COALESCE(m.status,'COMPLETED'),
		       COALESCE(m.notes,''), m.created_at
		FROM asset_maintenance m
		JOIN assets a ON a.id = m.asset_id
		WHERE m.asset_id = $1 AND a.property_id = $2
		ORDER BY m.performed_at DESC NULLS LAST, m.created_at DESC
		LIMIT 200`, assetID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Maintenance{}
	for rows.Next() {
		var m Maintenance
		if err := rows.Scan(&m.ID, &m.AssetID, &m.AssetName, &m.MaintenanceType,
			&m.Description, &m.LaborCost, &m.PartsCost, &m.TotalCost,
			&m.PerformedBy, &m.Vendor, &m.PerformedAt, &m.NextDue, &m.Status,
			&m.Notes, &m.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// Summary, demirbaş envanterinin özetidir.
type Summary struct {
	Total              int            `json:"total"`
	Active             int            `json:"active"`
	Disposed           int            `json:"disposed"`
	ByCondition        map[string]int `json:"by_condition"`
	MaintenanceOverdue int            `json:"maintenance_overdue"`
	WarrantyExpiring30 int            `json:"warranty_expiring_30_days"`
	PurchaseTotalTRY   float64        `json:"purchase_total_try"`
	MaintenanceYTDTRY  float64        `json:"maintenance_cost_ytd_try"`
}

// Summary, yönetim için envanter özetini üretir.
//
// `maintenance_cost_ytd_try`, içinde bulunulan yılın bakım gideri toplamıdır;
// işletme projesi hazırlanırken (KMK m.37) bakım kalemi tahmininin gerçekleşen
// kısmıdır.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	s := &Summary{ByCondition: map[string]int{}}

	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT
		  count(*),
		  count(*) FILTER (WHERE status <> 'DISPOSED'),
		  count(*) FILTER (WHERE status = 'DISPOSED'),
		  count(*) FILTER (WHERE status <> 'DISPOSED' AND next_maintenance_date IS NOT NULL
		                     AND next_maintenance_date < CURRENT_DATE),
		  count(*) FILTER (WHERE status <> 'DISPOSED' AND warranty_end IS NOT NULL
		                     AND warranty_end BETWEEN CURRENT_DATE AND CURRENT_DATE + interval '30 days'),
		  COALESCE(SUM(purchase_price) FILTER (WHERE status <> 'DISPOSED'),0)::float8
		FROM assets WHERE property_id = $1`, propertyID).
		Scan(&s.Total, &s.Active, &s.Disposed, &s.MaintenanceOverdue,
			&s.WarrantyExpiring30, &s.PurchaseTotalTRY)
	if err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT condition, count(*) FROM assets
		WHERE property_id = $1 AND status <> 'DISPOSED' GROUP BY condition`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var cond string
		var n int
		if err := rows.Scan(&cond, &n); err != nil {
			return nil, err
		}
		s.ByCondition[cond] = n
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT COALESCE(SUM(m.total_cost),0)::float8
		FROM asset_maintenance m
		JOIN assets a ON a.id = m.asset_id
		WHERE a.property_id = $1
		  AND m.performed_at >= date_trunc('year', CURRENT_DATE)`, propertyID).
		Scan(&s.MaintenanceYTDTRY); err != nil {
		return nil, err
	}
	return s, nil
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

func parseOptionalDate(s string) (*time.Time, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, nil
	}
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		return nil, ErrInvalidDate
	}
	return &t, nil
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// assets, asset_categories, asset_maintenance tablolarında RLS açıktır (migration 021).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
