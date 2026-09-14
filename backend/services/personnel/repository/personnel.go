// Package repository, personel yönetiminin veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/pii"
	"github.com/siteeksen/backend/services/personnel/models"
)

var (
	ErrNotFound     = errors.New("personel kaydı bulunamadı")
	ErrLeaveInvalid = errors.New("izin kaydı bulunamadı veya bu siteye ait değil")
	ErrNotPending   = errors.New("izin talebi onay bekleyen durumda değil")
	ErrOverlapping  = errors.New("bu tarihlerde personelin onaylı başka bir izni var")
	// ErrInvalidTCKN, TCKN algoritmik doğrulamadan geçmezse döner.
	ErrInvalidTCKN = errors.New("geçersiz T.C. kimlik numarası")
	// ErrInvalidIBAN, IBAN doğrulamadan geçmezse döner.
	ErrInvalidIBAN = errors.New("geçersiz IBAN")
	// ErrDuplicateTC, aynı TCKN ile ikinci bir aktif personel açılırsa döner.
	ErrDuplicateTC = errors.New("bu T.C. kimlik numarasıyla aktif bir personel kaydı zaten var")
)

// Repository, personel verilerini yönetir.
//
// TCKN ve IBAN ŞİFRELİ saklanır (FAZ 2.8, KVKK m.12). `vault` olmadan bu
// servis açılmaz: şifresiz yazmaya devam etmek, korumanın yapılandırma
// hatasıyla sessizce kapanması olurdu.
type Repository struct {
	pool  *pgxpool.Pool
	vault *pii.Vault
}

// New, depoyu kurar. vault nil olamaz.
func New(pool *pgxpool.Pool, vault *pii.Vault) *Repository {
	return &Repository{pool: pool, vault: vault}
}

// employeeSelect, şifreli kolonları okur. Düz metin kolonlar (tc_number,
// bank_iban) BİLEREK okunmaz: migration 019 sonrası yeni kayıtlarda boşturlar,
// eski kayıtlar `cmd/encrypt-pii` ile taşınır. Okumaya devam etmek, taşınmamış
// bir kaydı sessizce düz metin göstermek olurdu.
const employeeSelect = `
SELECT id, property_id, COALESCE(employee_number,''), first_name, last_name,
       COALESCE(tc_number_encrypted,''), COALESCE(bank_iban_encrypted,''),
       COALESCE(bank_name,''),
       COALESCE(phone,''), COALESCE(email,''), position, COALESCE(department,''),
       hire_date, end_date, COALESCE(contract_type,'FULL_TIME'),
       gross_salary::float8, net_salary::float8, COALESCE(sgk_number,''),
       COALESCE(annual_leave_days,0), COALESCE(used_leave_days,0),
       COALESCE(remaining_leave_days,0), COALESCE(is_active,true),
       COALESCE(notes,''), created_at
FROM employees`

// scanEmployee, satırı okur ve şifreli alanları ÇÖZER.
//
// Çözme hatası yutulmaz: anahtar değişmiş ya da veri bozulmuşsa, alanı boş
// göstermek "bu personelin TCKN'si yok" gibi yanlış bir izlenim verirdi.
func (r *Repository) scanEmployee(row pgx.Row) (*models.Employee, error) {
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

	if e.TCNumber != "" {
		plain, derr := r.vault.Decrypt(e.TCNumber)
		if derr != nil {
			return nil, fmt.Errorf("personel %s: TCKN çözülemedi: %w", e.ID, derr)
		}
		e.TCNumber = plain
	}
	if e.BankIBAN != "" {
		plain, derr := r.vault.Decrypt(e.BankIBAN)
		if derr != nil {
			return nil, fmt.Errorf("personel %s: IBAN çözülemedi: %w", e.ID, derr)
		}
		e.BankIBAN = plain
	}
	return &e, nil
}

// ListEmployees, sitedeki personeli getirir.
func (r *Repository) ListEmployees(ctx context.Context, propertyID string, activeOnly bool) ([]models.Employee, error) {
	rows, err := r.scope(propertyID).Query(ctx, employeeSelect+`
		WHERE property_id = $1 AND ($2 = false OR COALESCE(is_active,true))
		ORDER BY is_active DESC, last_name, first_name`, propertyID, activeOnly)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Employee{}
	for rows.Next() {
		e, err := r.scanEmployee(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *e)
	}
	return out, rows.Err()
}

// GetEmployee, tek personeli getirir.
func (r *Repository) GetEmployee(ctx context.Context, propertyID, id string) (*models.Employee, error) {
	e, err := r.scanEmployee(r.scope(propertyID).QueryRow(ctx, employeeSelect+`
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

	// TCKN ve IBAN ÖNCE doğrulanır, sonra şifrelenir. Şifreli bir alandaki
	// yazım hatası sonradan gözle bulunamaz; yanlış IBAN maaşın başkasına
	// gitmesi demektir.
	var tcEnc, tcIdx, ibanEnc, ibanIdx, ibanLast4 *string
	if t := strings.TrimSpace(in.TCNumber); t != "" {
		if err := pii.ValidateTCKN(t); err != nil {
			return "", ErrInvalidTCKN
		}
		ct, err := r.vault.Encrypt(t)
		if err != nil {
			return "", err
		}
		idx := r.vault.BlindIndex(t)
		tcEnc, tcIdx = &ct, &idx
	}
	if b := strings.TrimSpace(in.BankIBAN); b != "" {
		if err := pii.ValidateIBAN(b); err != nil {
			return "", ErrInvalidIBAN
		}
		ct, err := r.vault.Encrypt(b)
		if err != nil {
			return "", err
		}
		idx := r.vault.BlindIndex(b)
		l4 := pii.Last4(b)
		ibanEnc, ibanIdx, ibanLast4 = &ct, &idx, &l4
	}

	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO employees
			(property_id, employee_number, first_name, last_name, phone, email,
			 position, department, hire_date, contract_type, gross_salary, net_salary,
			 bank_name, sgk_number, annual_leave_days, remaining_leave_days, notes,
			 tc_number_encrypted, tc_number_index,
			 bank_iban_encrypted, bank_iban_index, bank_iban_last4, pii_encrypted_at)
		VALUES ($1, NULLIF($2,''), $3, $4, NULLIF($5,''), NULLIF($6,''),
		        $7, NULLIF($8,''), $9, $10, NULLIF($11,0), NULLIF($12,0),
		        NULLIF($13,''), NULLIF($14,''), $15, $15, NULLIF($16,''),
		        $17, $18, $19, $20, $21, now())
		RETURNING id`,
		propertyID, in.EmployeeNumber, in.FirstName, in.LastName,
		in.Phone, in.Email, in.Position, in.Department, hireDate, contract,
		in.GrossSalary, in.NetSalary, in.BankName, in.SGKNumber,
		annualLeave, in.Notes,
		tcEnc, tcIdx, ibanEnc, ibanIdx, ibanLast4).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "uq_employees_tc_active") {
		return "", ErrDuplicateTC
	}
	return id, err
}

// TerminateEmployee, işten ayrılışı işler. Kayıt SİLİNMEZ — özlük kayıtları
// İş Kanunu ve SGK mevzuatı gereği saklanmak zorundadır.
func (r *Repository) TerminateEmployee(ctx context.Context, propertyID, id, reason string, endDate time.Time) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
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
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE COALESCE(is_active,true)),
		       count(*) FILTER (WHERE NOT COALESCE(is_active,true)),
		       sum(gross_salary) FILTER (WHERE COALESCE(is_active,true))::float8
		FROM employees WHERE property_id = $1`, propertyID).
		Scan(&s.TotalActive, &s.TotalInactive, &cost)
	if err != nil {
		return nil, err
	}
	s.MonthlySalaryCost = cost

	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*) FROM employee_leaves l
		JOIN employees e ON e.id = l.employee_id
		WHERE e.property_id = $1 AND l.status = 'PENDING'`, propertyID).
		Scan(&s.PendingLeaves); err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
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
	rows, err := r.scope(propertyID).Query(ctx, leaveSelect+`
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
	tx, err := r.scope(propertyID).Begin(ctx)
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
	tx, err := r.scope(propertyID).Begin(ctx)
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

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// employees / employee_leaves / payroll tablolarında RLS açıktır (migration 020).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
