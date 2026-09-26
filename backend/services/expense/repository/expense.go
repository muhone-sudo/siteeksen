// Package repository, gider yönetiminin veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/services/expense/models"
)

var (
	ErrNotFound        = errors.New("gider kaydı bulunamadı")
	ErrCategoryInvalid = errors.New("gider kalemi bulunamadı veya bu siteye ait değil")
	ErrNotPending      = errors.New("gider onay bekleyen durumda değil")
	ErrNoUnits         = errors.New("sitede tanımlı bağımsız bölüm yok")
)

// Unit, dağıtım hesabında kullanılan bağımsız bölüm özetidir.
type Unit struct {
	ID         string
	Name       string
	ShareRatio float64
	AreaM2     float64
	IsGround   bool
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// ListUnits, sitedeki bağımsız bölümleri getirir.
func (r *Repository) ListUnits(ctx context.Context, propertyID string) ([]Unit, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id,
		       COALESCE(block,'') || '-' || COALESCE(door_number,''),
		       COALESCE(share_ratio,0)::float8,
		       COALESCE(gross_area_m2,0)::float8,
		       COALESCE(is_ground_floor,false)
		FROM units WHERE property_id = $1 AND deleted = 0
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

// ListCategories, siteye ait ve global (şablon) gider kalemlerini getirir.
func (r *Repository) ListCategories(ctx context.Context, propertyID string) ([]models.Category, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, COALESCE(property_id::text,''), name, COALESCE(description,''),
		       COALESCE(type,''), distribution_type,
		       COALESCE(reflects_to_assessment, true),
		       COALESCE(applies_to_ground_floor, true),
		       COALESCE(is_default,false), COALESCE(display_order, sort_order, 0),
		       COALESCE(is_active,true)
		FROM expense_categories
		WHERE property_id = $1 OR property_id IS NULL
		ORDER BY COALESCE(display_order, sort_order, 0), name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Category{}
	for rows.Next() {
		var c models.Category
		if err := rows.Scan(&c.ID, &c.PropertyID, &c.Name, &c.Description, &c.Type,
			&c.DistributionType, &c.ReflectsToAssessment, &c.AppliesToGroundFloor,
			&c.IsDefault, &c.DisplayOrder, &c.IsActive); err != nil {
			return nil, err
		}
		c.LegalBasis = legalBasisFor(c.DistributionType)
		out = append(out, c)
	}
	return out, rows.Err()
}

// legalBasisFor, dağıtım türünün KMK dayanağını açıklar.
// Arayüzde gösterilir ki yönetici neden o şekilde paylaştırıldığını görebilsin.
func legalBasisFor(distributionType string) string {
	switch distributionType {
	case "EQUAL":
		return "KMK m.20/1-a — kapıcı, kaloriferci, bahçıvan ve bekçi giderleri eşit paylaşılır"
	case "SHARE_RATIO":
		return "KMK m.20/1-b — sigorta primi, ortak yer bakım/onarım ve ortak tesis işletme giderleri arsa payı oranında paylaşılır"
	case "AREA_M2":
		return "Yönetim planında öngörülmüşse kullanım alanına göre paylaşım"
	case "METER_READING":
		return "Ölçülen tüketime göre (Merkezi Isıtma Yönetmeliği %70 tüketim + %30 alan)"
	default:
		return ""
	}
}

// GetCategory, kalemi getirir ve siteye uygunluğunu doğrular.
func (r *Repository) GetCategory(ctx context.Context, propertyID, categoryID string) (*models.Category, error) {
	var c models.Category
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT id, COALESCE(property_id::text,''), name, COALESCE(description,''),
		       COALESCE(type,''), distribution_type,
		       COALESCE(reflects_to_assessment, true),
		       COALESCE(applies_to_ground_floor, true),
		       COALESCE(is_default,false), COALESCE(display_order, sort_order, 0),
		       COALESCE(is_active,true)
		FROM expense_categories
		WHERE id = $1 AND (property_id = $2 OR property_id IS NULL)`,
		categoryID, propertyID).Scan(&c.ID, &c.PropertyID, &c.Name, &c.Description, &c.Type,
		&c.DistributionType, &c.ReflectsToAssessment, &c.AppliesToGroundFloor,
		&c.IsDefault, &c.DisplayOrder, &c.IsActive)
	if err == pgx.ErrNoRows {
		return nil, ErrCategoryInvalid
	}
	if err != nil {
		return nil, err
	}
	c.LegalBasis = legalBasisFor(c.DistributionType)
	return &c, nil
}

// Create, gideri ve (varsa) birim dağıtımını tek transaction içinde yazar.
//
// Dağıtım paylarını SERVICE katmanı `pkg/money` ile hesaplar; repository yalnızca
// kalıcılaştırır. Böylece kuruş dağıtım mantığı tek yerde kalır ve test edilebilir olur.
func (r *Repository) Create(
	ctx context.Context,
	propertyID, userID string,
	in models.CreateExpenseInput,
	expenseDate time.Time,
	invoiceDate *time.Time,
	isInvoiced, reflects bool,
	distributionType string,
	distributions []models.Distribution,
) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Faturasız gider yönetim kurulu onayı gerektirir (denetim ve KMK m.39 hesap verme).
	status := models.StatusApproved
	if !isInvoiced {
		status = models.StatusPending
	}

	var id string
	err = tx.QueryRow(ctx, `
		INSERT INTO expenses
			(property_id, category_id, description, amount, expense_date,
			 is_invoiced, invoice_reason, reflects_to_assessment, assessment_period,
			 distribution_type, status, vendor_name, vendor_tax_id, invoice_number,
			 invoice_date, notes, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,NULLIF($7,''),$8,NULLIF($9,''),$10,$11,
		        NULLIF($12,''),NULLIF($13,''),NULLIF($14,''),$15,NULLIF($16,''),$17)
		RETURNING id`,
		propertyID, in.CategoryID, in.Description, in.Amount, expenseDate,
		isInvoiced, in.InvoiceReason, reflects, in.AssessmentPeriod,
		distributionType, status, in.VendorName, in.VendorTaxID, in.InvoiceNumber,
		invoiceDate, in.Notes, userID).Scan(&id)
	if err != nil {
		return "", err
	}

	for _, d := range distributions {
		if _, err := tx.Exec(ctx,
			`INSERT INTO expense_distributions (expense_id, unit_id, amount) VALUES ($1,$2,$3)`,
			id, d.UnitID, d.Amount); err != nil {
			return "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

const expenseSelect = `
SELECT e.id, e.property_id, e.category_id, COALESCE(c.name,''), e.description,
       e.amount, COALESCE(e.currency,'TRY'), e.expense_date,
       e.is_invoiced, COALESCE(e.invoice_reason,''),
       e.reflects_to_assessment, COALESCE(e.assessment_period,''),
       COALESCE(e.distribution_type,''), e.status,
       COALESCE(e.approved_by::text,''), e.approved_at, COALESCE(e.rejection_reason,''),
       COALESCE(e.vendor_name,''), COALESCE(e.vendor_tax_id,''),
       COALESCE(e.invoice_number,''), e.invoice_date, COALESCE(e.notes,''),
       COALESCE(e.created_by::text,''), e.created_at
FROM expenses e
LEFT JOIN expense_categories c ON c.id = e.category_id`

func scanExpense(row pgx.Row) (*models.Expense, error) {
	var e models.Expense
	err := row.Scan(&e.ID, &e.PropertyID, &e.CategoryID, &e.CategoryName, &e.Description,
		&e.Amount, &e.Currency, &e.ExpenseDate, &e.IsInvoiced, &e.InvoiceReason,
		&e.ReflectsToAssessment, &e.AssessmentPeriod, &e.DistributionType, &e.Status,
		&e.ApprovedBy, &e.ApprovedAt, &e.RejectionReason, &e.VendorName, &e.VendorTaxID,
		&e.InvoiceNumber, &e.InvoiceDate, &e.Notes, &e.CreatedBy, &e.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &e, nil
}

// List, filtrelenmiş gider listesini getirir.
func (r *Repository) List(ctx context.Context, propertyID string, year, month int, status, categoryID string) ([]models.Expense, error) {
	rows, err := r.scope(propertyID).Query(ctx, expenseSelect+`
		WHERE e.property_id = $1
		  AND ($2 = 0 OR EXTRACT(YEAR FROM e.expense_date) = $2)
		  AND ($3 = 0 OR EXTRACT(MONTH FROM e.expense_date) = $3)
		  AND ($4 = '' OR e.status = $4)
		  AND ($5 = '' OR e.category_id = NULLIF($5,'')::uuid)
		ORDER BY e.expense_date DESC, e.created_at DESC`,
		propertyID, year, month, status, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Expense{}
	for rows.Next() {
		e, err := scanExpense(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *e)
	}
	return out, rows.Err()
}

// Get, tek gideri dağıtım detayıyla getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id string) (*models.Expense, error) {
	e, err := scanExpense(r.scope(propertyID).QueryRow(ctx, expenseSelect+`
		WHERE e.id = $1 AND e.property_id = $2`, id, propertyID))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT d.unit_id, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       d.amount, COALESCE(d.is_paid,false)
		FROM expense_distributions d
		JOIN units u ON u.id = d.unit_id
		WHERE d.expense_id = $1
		ORDER BY u.block, u.door_number`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var d models.Distribution
		if err := rows.Scan(&d.UnitID, &d.UnitName, &d.Amount, &d.IsPaid); err != nil {
			return nil, err
		}
		e.Distributions = append(e.Distributions, d)
	}
	if n := len(e.Distributions); n > 0 {
		avg := e.Amount / float64(n)
		e.PerUnitAmount = &avg
	}
	return e, rows.Err()
}

// SetStatus, faturasız giderin onay/ret işlemini yapar.
func (r *Repository) SetStatus(ctx context.Context, propertyID, id, status, userID, reason string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE expenses
		SET status = $3,
		    approved_by = NULLIF($4,'')::uuid,
		    approved_at = now(),
		    rejection_reason = NULLIF($5,''),
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING'`,
		id, propertyID, status, userID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "expenses", id, ErrNotFound, ErrNotPending)
	}
	return nil
}

// Summary, dönem bazlı gider özetini hesaplar.
func (r *Repository) Summary(ctx context.Context, propertyID string, year, month int) (*models.Summary, error) {
	s := &models.Summary{PeriodYear: year, PeriodMonth: month}

	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT COALESCE(sum(amount),0)::float8,
		       COALESCE(sum(amount) FILTER (WHERE is_invoiced),0)::float8,
		       COALESCE(sum(amount) FILTER (WHERE NOT is_invoiced),0)::float8,
		       count(*) FILTER (WHERE status = 'PENDING')
		FROM expenses
		WHERE property_id = $1
		  AND status <> 'REJECTED'
		  AND ($2 = 0 OR EXTRACT(YEAR FROM expense_date) = $2)
		  AND ($3 = 0 OR EXTRACT(MONTH FROM expense_date) = $3)`,
		propertyID, year, month).Scan(&s.TotalAmount, &s.InvoicedAmount,
		&s.NonInvoicedAmount, &s.PendingCount)
	if err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT e.category_id, COALESCE(c.name,''), COALESCE(sum(e.amount),0)::float8, count(*)
		FROM expenses e
		LEFT JOIN expense_categories c ON c.id = e.category_id
		WHERE e.property_id = $1
		  AND e.status <> 'REJECTED'
		  AND ($2 = 0 OR EXTRACT(YEAR FROM e.expense_date) = $2)
		  AND ($3 = 0 OR EXTRACT(MONTH FROM e.expense_date) = $3)
		GROUP BY e.category_id, c.name
		ORDER BY sum(e.amount) DESC`, propertyID, year, month)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	s.ByCategory = []models.CategoryTotal{}
	for rows.Next() {
		var t models.CategoryTotal
		if err := rows.Scan(&t.CategoryID, &t.CategoryName, &t.Amount, &t.Count); err != nil {
			return nil, err
		}
		s.ByCategory = append(s.ByCategory, t)
	}
	return s, rows.Err()
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `expenses` ve `expense_distributions` (migration 023) ile `expense_categories`
// (migration 024) tablolarında RLS açıktır. Kategori tablosunda ORTAK şablon
// satırları (property_id IS NULL) her sitede okunur ama uygulama rolüyle
// yazılamaz.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// stateOrNotFound, durum geçişli bir güncelleme 0 satır etkilediğinde iki
// ihtimali ayırır: kayıt hiç yoksa (ya da başka siteye aitse) notFound (404),
// varsa ama durumu uygun değilse state (409). Önceden ikisi de 409 dönüyordu;
// istemci var olmayan kaydı "başkası işlem yapmış" sanıyordu.
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
