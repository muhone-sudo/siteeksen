// Package repository, personel yönetiminin veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/services/personnel/models"
)

var (
	ErrNotFound     = errors.New("personel kaydı bulunamadı")
	ErrLeaveInvalid = errors.New("izin kaydı bulunamadı veya bu siteye ait değil")
	ErrNotPending   = errors.New("izin talebi onay bekleyen durumda değil")
	ErrOverlapping  = errors.New("bu tarihlerde personelin onaylı başka bir izni var")
)

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const employeeSelect = `
SELECT id, property_id, COALESCE(employee_number,''), first_name, last_name,
       COALESCE(tc_number,''), COALESCE(bank_iban,''), COALESCE(bank_name,''),
       COALESCE(phone,''), COALESCE(email,''), position, COALESCE(department,''),
       hire_date, end_date, COALESCE(contract_type,'FULL_TIME'),
       gross_salary::float8, net_salary::float8, COALESCE(sgk_number,''),
       COALESCE(annual_leave_days,0), COALESCE(used_leave_days,0),
       COALESCE(remaining_leave_days,0), COALESCE(is_active,true),
       COALESCE(notes,''), created_at
FROM employees`

func scanEmployee(row pgx.Row) (*models.Employee, error) {
	var e models.Employee
	err := row.Scan(&e.ID, &e.PropertyID, &e.EmployeeNumber, &e.FirstName, &e.LastName,
		&e.TCNumber, &e.BankIBAN, &e.BankName, &e.Phone, &e.Email, &e.Position,
		&e.Department, &e.HireDate, &e.EndDate, &e.ContractType,
		&e.GrossSalary, &e.NetSalary, &e.SGKNumber,
		&e.AnnualLeaveDays, &e.UsedLeaveDays, &e.RemainingLeaveDays, &e.IsActive,
		&e.Notes, &e.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &e, nil
}

// ListEmployees, sitedeki personeli getirir.
func (r *Repository) ListEmployees(ctx context.Context, propertyID string, activeOnly bool) ([]models.Employee, error) {
	rows, err := r.pool.Query(ctx, employeeSelect+`
		WHERE property_id = $1 AND ($2 = false OR COALESCE(is_active,true))
		ORDER BY is_active DESC, last_name, first_name`, propertyID, activeOnly)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Employee{}
	for rows.Next() {
		e, err := scanEmployee(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *e)
	}
	return out, rows.Err()
}

// GetEmployee, tek personeli getirir.
func (r *Repository) GetEmployee(ctx context.Context, propertyID, id string) (*models.Employee, error) {
	e, err := scanEmployee(r.pool.QueryRow(ctx, employeeSelect+`
		WHERE id = $1 AND property_id = $2`, id, propertyID))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return e, err
}

// CreateEmployee, personel kaydı açar.
func (r *Repository) CreateEmployee(ctx context.Context, propertyID string, in models.CreateEmployeeInput, hireDate time.Time, annualLeave int) (string, error) {
	contract := in.ContractType
	if contract == "" {
		contract = "FULL_TIME"
	}
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO employees
			(property_id, employee_number, first_name, last_name, tc_number, phone, email,
			 position, department, hire_date, contract_type, gross_salary, net_salary,
			 bank_name, bank_iban, sgk_number, annual_leave_days, remaining_leave_days, notes)
		VALUES ($1, NULLIF($2,''), $3, $4, NULLIF($5,''), NULLIF($6,''), NULLIF($7,''),
		        $8, NULLIF($9,''), $10, $11, NULLIF($12,0), NULLIF($13,0),
		        NULLIF($14,''), NULLIF($15,''), NULLIF($16,''), $17, $17, NULLIF($18,''))
		RETURNING id`,
		propertyID, in.EmployeeNumber, in.FirstName, in.LastName, in.TCNumber,
		in.Phone, in.Email, in.Position, in.Department, hireDate, contract,
		in.GrossSalary, in.NetSalary, in.BankName, in.BankIBAN, in.SGKNumber,
		annualLeave, in.Notes).Scan(&id)
	return id, err
}

// TerminateEmployee, işten ayrılışı işler. Kayıt SİLİNMEZ — özlük kayıtları
// İş Kanunu ve SGK mevzuatı gereği saklanmak zorundadır.
func (r *Repository) TerminateEmployee(ctx context.Context, propertyID, id, reason string, endDate time.Time) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE employees
		SET is_active = false, end_date = $3, termination_reason = NULLIF($4,''), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND COALESCE(is_active,true)`,
		id, propertyID, endDate, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Summary, personel özetini hesaplar.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*models.Summary, error) {
	s := &models.Summary{}
	var cost *float64
	err := r.pool.QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE COALESCE(is_active,true)),
		       count(*) FILTER (WHERE NOT COALESCE(is_active,true)),
		       sum(gross_salary) FILTER (WHERE COALESCE(is_active,true))::float8
		FROM employees WHERE property_id = $1`, propertyID).
		Scan(&s.TotalActive, &s.TotalInactive, &cost)
	if err != nil {
		return nil, err
	}
	s.MonthlySalaryCost = cost

	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM employee_leaves l
		JOIN employees e ON e.id = l.employee_id
		WHERE e.property_id = $1 AND l.status = 'PENDING'`, propertyID).
		Scan(&s.PendingLeaves); err != nil {
		return nil, err
	}

	rows, err := r.pool.Query(ctx, `
		SELECT position, count(*)
		FROM employees WHERE property_id = $1 AND COALESCE(is_active,true)
		GROUP BY position ORDER BY count(*) DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	s.ByPosition = []models.PositionCount{}
	for rows.Next() {
		var p models.PositionCount
		if err := rows.Scan(&p.Position, &p.Count); err != nil {
			return nil, err
		}
		s.ByPosition = append(s.ByPosition, p)
	}
	return s, rows.Err()
}

// -----------------------------------------------------------------------------
// İZİNLER
// -----------------------------------------------------------------------------

const leaveSelect = `
SELECT l.id, l.employee_id, e.first_name || ' ' || e.last_name,
       l.leave_type, l.start_date, l.end_date, l.days::float8,
       COALESCE(l.reason,''), l.status, COALESCE(l.approved_by::text,''),
       l.approved_at, COALESCE(l.rejection_reason,''), l.created_at
FROM employee_leaves l
JOIN employees e ON e.id = l.employee_id`

// ListLeaves, sitenin izin taleplerini getirir.
func (r *Repository) ListLeaves(ctx context.Context, propertyID, status string) ([]models.Leave, error) {
	rows, err := r.pool.Query(ctx, leaveSelect+`
		WHERE e.property_id = $1 AND ($2 = '' OR l.status = $2)
		ORDER BY l.created_at DESC`, propertyID, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Leave{}
	for rows.Next() {
		var l models.Leave
		if err := rows.Scan(&l.ID, &l.EmployeeID, &l.EmployeeName, &l.LeaveType,
			&l.StartDate, &l.EndDate, &l.Days, &l.Reason, &l.Status,
			&l.ApprovedBy, &l.ApprovedAt, &l.RejectionReason, &l.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	return out, rows.Err()
}

// CreateLeave, izin talebi oluşturur.
//
// ÇAKIŞMA DENETİMİ: Aynı personelin onaylı izniyle çakışan yeni talep reddedilir.
// Çakışan izinler bordroda çift kesinti/çift hak kaybına yol açar.
func (r *Repository) CreateLeave(ctx context.Context, propertyID string, in models.CreateLeaveInput, start, end time.Time, days float64) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Personel bu siteye ait mi?
	var exists bool
	if err := tx.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM employees WHERE id = $1 AND property_id = $2)`,
		in.EmployeeID, propertyID).Scan(&exists); err != nil {
		return "", err
	}
	if !exists {
		return "", ErrNotFound
	}

	var overlap int
	if err := tx.QueryRow(ctx, `
		SELECT count(*) FROM employee_leaves
		WHERE employee_id = $1 AND status IN ('PENDING','APPROVED')
		  AND daterange(start_date, end_date, '[]') && daterange($2::date, $3::date, '[]')`,
		in.EmployeeID, start, end).Scan(&overlap); err != nil {
		return "", err
	}
	if overlap > 0 {
		return "", ErrOverlapping
	}

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO employee_leaves (employee_id, leave_type, start_date, end_date, days, reason)
		VALUES ($1,$2,$3,$4,$5,NULLIF($6,''))
		RETURNING id`,
		in.EmployeeID, in.LeaveType, start, end, days, in.Reason).Scan(&id); err != nil {
		return "", err
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

// DecideLeave, izin talebini onaylar ya da reddeder.
//
// Onay durumunda yıllık izin bakiyesi tek transaction içinde düşülür; aksi hâlde
// bakiye ile kullanılan izin birbirini tutmaz.
func (r *Repository) DecideLeave(ctx context.Context, propertyID, leaveID, status, userID, reason string) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var employeeID, leaveType string
	var days float64
	err = tx.QueryRow(ctx, `
		SELECT l.employee_id, l.leave_type, l.days::float8
		FROM employee_leaves l
		JOIN employees e ON e.id = l.employee_id
		WHERE l.id = $1 AND e.property_id = $2 AND l.status = 'PENDING'
		FOR UPDATE OF l`, leaveID, propertyID).Scan(&employeeID, &leaveType, &days)
	if err == pgx.ErrNoRows {
		return ErrNotPending
	}
	if err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE employee_leaves
		SET status = $2, approved_by = NULLIF($3,'')::uuid, approved_at = now(),
		    rejection_reason = NULLIF($4,'')
		WHERE id = $1`, leaveID, status, userID, reason); err != nil {
		return err
	}

	// Yalnızca YILLIK izin bakiyeden düşer; hastalık/ücretsiz izin yıllık hakkı etkilemez.
	if status == "APPROVED" && leaveType == "ANNUAL" {
		if _, err := tx.Exec(ctx, `
			UPDATE employees
			SET used_leave_days = COALESCE(used_leave_days,0) + $2,
			    remaining_leave_days = GREATEST(COALESCE(annual_leave_days,0) - (COALESCE(used_leave_days,0) + $2), 0),
			    updated_at = now()
			WHERE id = $1`, employeeID, int(days)); err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}
