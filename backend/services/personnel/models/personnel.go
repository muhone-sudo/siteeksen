// Package models, personel yönetimi veri yapılarını tanımlar.
//
// KVKK NOTU: Bu modülün işlediği veriler (TCKN, SGK numarası, IBAN, maaş) kişisel
// verinin en hassas grubundadır. Bu yüzden:
//   - Liste yanıtlarında TCKN ve IBAN **maskelenir**;
//   - Tam değerler yalnızca tekil kayıt okumasında ve yalnızca yönetici rolüne döner;
//   - Her okuma denetim izine yazılır (`middleware.AuditLog`).
package models

import "time"

// Employee, personel kaydıdır.
type Employee struct {
	ID             string `json:"id"`
	PropertyID     string `json:"property_id"`
	EmployeeNumber string `json:"employee_number,omitempty"`
	FirstName      string `json:"first_name"`
	LastName       string `json:"last_name"`

	// TCNumber ve BankIBAN liste yanıtlarında MASKELİ döner (örn. "123*****89").
	TCNumber string `json:"tc_number,omitempty"`
	BankIBAN string `json:"bank_iban,omitempty"`
	BankName string `json:"bank_name,omitempty"`

	Phone string `json:"phone,omitempty"`
	Email string `json:"email,omitempty"`

	Position   string `json:"position"`
	Department string `json:"department,omitempty"`

	HireDate     time.Time  `json:"hire_date"`
	EndDate      *time.Time `json:"end_date,omitempty"`
	ContractType string     `json:"contract_type"`

	GrossSalary *float64 `json:"gross_salary,omitempty"`
	NetSalary   *float64 `json:"net_salary,omitempty"`

	SGKNumber string `json:"sgk_number,omitempty"`

	AnnualLeaveDays    int  `json:"annual_leave_days"`
	UsedLeaveDays      int  `json:"used_leave_days"`
	RemainingLeaveDays int  `json:"remaining_leave_days"`
	IsActive           bool `json:"is_active"`

	Notes     string    `json:"notes,omitempty"`
	CreatedAt time.Time `json:"created_at"`

	// SalaryVisible false ise maaş alanları bilerek boş bırakılmıştır (yetki kısıtı).
	SalaryVisible bool `json:"salary_visible"`
}

// CreateEmployeeInput, yeni personel girdisidir.
type CreateEmployeeInput struct {
	FirstName      string  `json:"first_name" binding:"required"`
	LastName       string  `json:"last_name" binding:"required"`
	Position       string  `json:"position" binding:"required"`
	HireDate       string  `json:"hire_date" binding:"required"` // YYYY-AA-GG
	EmployeeNumber string  `json:"employee_number"`
	TCNumber       string  `json:"tc_number"`
	Phone          string  `json:"phone"`
	Email          string  `json:"email"`
	Department     string  `json:"department"`
	ContractType   string  `json:"contract_type"`
	GrossSalary    float64 `json:"gross_salary"`
	NetSalary      float64 `json:"net_salary"`
	BankName       string  `json:"bank_name"`
	BankIBAN       string  `json:"bank_iban"`
	SGKNumber      string  `json:"sgk_number"`
	// AnnualLeaveDays verilmezse 14 gün (4857 s. İş Kanunu m.53 asgari hakkı) kullanılır.
	AnnualLeaveDays int    `json:"annual_leave_days"`
	Notes           string `json:"notes"`
}

// Leave, personel izin kaydıdır.
type Leave struct {
	ID              string     `json:"id"`
	EmployeeID      string     `json:"employee_id"`
	EmployeeName    string     `json:"employee_name,omitempty"`
	LeaveType       string     `json:"leave_type"`
	StartDate       time.Time  `json:"start_date"`
	EndDate         time.Time  `json:"end_date"`
	Days            float64    `json:"days"`
	Reason          string     `json:"reason,omitempty"`
	Status          string     `json:"status"`
	ApprovedBy      string     `json:"approved_by,omitempty"`
	ApprovedAt      *time.Time `json:"approved_at,omitempty"`
	RejectionReason string     `json:"rejection_reason,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}

// CreateLeaveInput, izin talebidir.
type CreateLeaveInput struct {
	EmployeeID string `json:"employee_id" binding:"required"`
	LeaveType  string `json:"leave_type" binding:"required"`
	StartDate  string `json:"start_date" binding:"required"`
	EndDate    string `json:"end_date" binding:"required"`
	Reason     string `json:"reason"`
}

// Summary, personel özetidir.
type Summary struct {
	TotalActive   int `json:"total_active"`
	TotalInactive int `json:"total_inactive"`
	PendingLeaves int `json:"pending_leaves"`
	// MonthlySalaryCost yalnızca maaş görme yetkisi olanlara döner.
	MonthlySalaryCost *float64        `json:"monthly_salary_cost,omitempty"`
	ByPosition        []PositionCount `json:"by_position"`
}

// PositionCount, görev bazlı personel sayısıdır.
type PositionCount struct {
	Position string `json:"position"`
	Count    int    `json:"count"`
}
