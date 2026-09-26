// Package service, personel yönetiminin iş kurallarını uygular.
package service

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/siteeksen/backend/services/personnel/models"
	"github.com/siteeksen/backend/services/personnel/repository"
)

var (
	ErrInvalidDate    = errors.New("tarih biçimi YYYY-AA-GG olmalıdır")
	ErrDateOrder      = errors.New("bitiş tarihi başlangıç tarihinden önce olamaz")
	ErrReasonRequired = errors.New("gerekçe zorunludur")
	// ErrInvalidEnum, sözleşme ya da izin türü izin verilen değerlerden biri
	// değilse döner. Önceden kodda denetlenmiyor, veritabanı CHECK kısıtı
	// reddediyor ve istemci 500 alıyordu.
	ErrInvalidEnum = errors.New("geçersiz tür")
)

// ContractTypes ve LeaveTypes, veritabanı CHECK kısıtlarıyla (migration 005)
// birebir aynıdır. İzin türleri 4857 s. İş Kanunu'ndaki izin çeşitlerine karşılık gelir.
var (
	ContractTypes = []string{"FULL_TIME", "PART_TIME", "CONTRACT", "INTERN"}
	LeaveTypes    = []string{"ANNUAL", "SICK", "UNPAID", "MATERNITY", "PATERNITY", "MARRIAGE", "BEREAVEMENT", "OTHER"}
)

func oneOf(v string, list []string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// defaultAnnualLeaveDays — 4857 sayılı İş Kanunu m.53'e göre 1-5 yıl kıdemde
// yıllık ücretli izin en az 14 gündür. Kıdeme göre artan hak (5-15 yıl: 20 gün,
// 15+ yıl: 26 gün) personel bazında elle girilebilir.
const defaultAnnualLeaveDays = 14

type Service struct{ repo *repository.Repository }

func New(repo *repository.Repository) *Service { return &Service{repo: repo} }

// maskTC, TCKN'yi maskeler: 12345678901 → 123*****01
//
// NEDEN: Personel listesi ekranı gündelik olarak açılır; TCKN'nin tam hâlinin
// her listede görünmesi KVKK'nın veri minimizasyonu ilkesine aykırıdır.
func maskTC(tc string) string {
	if len(tc) < 5 {
		return ""
	}
	return tc[:3] + "*****" + tc[len(tc)-2:]
}

// maskIBAN, IBAN'ı maskeler: TR12...3456
func maskIBAN(iban string) string {
	if len(iban) < 8 {
		return ""
	}
	return iban[:4] + "..." + iban[len(iban)-4:]
}

// applyPrivacy, yetkiye göre hassas alanları maskeler veya kaldırır.
//
// canSeeSalary=false olan roller (örn. STAFF) personeli görebilir ama maaş,
// IBAN ve SGK numarasını GÖREMEZ. `SalaryVisible` alanı istemciye bunun bir
// yetki kısıtı olduğunu söyler — "veri yok" ile karıştırılmasın diye.
func applyPrivacy(e *models.Employee, canSeeSalary, full bool) {
	e.SalaryVisible = canSeeSalary
	if !canSeeSalary {
		e.GrossSalary = nil
		e.NetSalary = nil
		e.BankIBAN = ""
		e.BankName = ""
		e.SGKNumber = ""
		e.TCNumber = ""
		return
	}
	if !full {
		e.TCNumber = maskTC(e.TCNumber)
		e.BankIBAN = maskIBAN(e.BankIBAN)
	}
}

// ListEmployees, personel listesini yetkiye göre maskeleyerek döndürür.
func (s *Service) ListEmployees(ctx context.Context, propertyID string, activeOnly, canSeeSalary bool) ([]models.Employee, error) {
	list, err := s.repo.ListEmployees(ctx, propertyID, activeOnly)
	if err != nil {
		return nil, err
	}
	for i := range list {
		applyPrivacy(&list[i], canSeeSalary, false)
	}
	return list, nil
}

// GetEmployee, tek personeli döndürür. `full` yalnızca yönetici için true olmalıdır.
func (s *Service) GetEmployee(ctx context.Context, propertyID, id string, canSeeSalary, full bool) (*models.Employee, error) {
	e, err := s.repo.GetEmployee(ctx, propertyID, id)
	if err != nil {
		return nil, err
	}
	applyPrivacy(e, canSeeSalary, full)
	return e, nil
}

// CreateEmployee, personel kaydı açar.
func (s *Service) CreateEmployee(ctx context.Context, propertyID string, in models.CreateEmployeeInput) (*models.Employee, error) {
	hireDate, err := time.Parse("2006-01-02", in.HireDate)
	if err != nil {
		return nil, ErrInvalidDate
	}
	in.ContractType = strings.ToUpper(strings.TrimSpace(in.ContractType))
	if in.ContractType == "" {
		in.ContractType = "FULL_TIME"
	}
	if !oneOf(in.ContractType, ContractTypes) {
		return nil, ErrInvalidEnum
	}
	annual := in.AnnualLeaveDays
	if annual <= 0 {
		annual = defaultAnnualLeaveDays
	}
	id, err := s.repo.CreateEmployee(ctx, propertyID, in, hireDate, annual)
	if err != nil {
		return nil, err
	}
	return s.GetEmployee(ctx, propertyID, id, true, true)
}

// Terminate, işten ayrılışı işler. Kayıt silinmez (özlük dosyası saklanır).
func (s *Service) Terminate(ctx context.Context, propertyID, id, reason, endDateStr string) error {
	if reason == "" {
		return ErrReasonRequired
	}
	endDate := time.Now()
	if endDateStr != "" {
		d, err := time.Parse("2006-01-02", endDateStr)
		if err != nil {
			return ErrInvalidDate
		}
		endDate = d
	}
	return s.repo.TerminateEmployee(ctx, propertyID, id, reason, endDate)
}

// Summary, personel özetini döndürür. Maaş maliyeti yalnızca yetkiliye gösterilir.
func (s *Service) Summary(ctx context.Context, propertyID string, canSeeSalary bool) (*models.Summary, error) {
	sum, err := s.repo.Summary(ctx, propertyID)
	if err != nil {
		return nil, err
	}
	if !canSeeSalary {
		sum.MonthlySalaryCost = nil
	}
	return sum, nil
}

func (s *Service) ListLeaves(ctx context.Context, propertyID, status string) ([]models.Leave, error) {
	return s.repo.ListLeaves(ctx, propertyID, status)
}

// CreateLeave, izin talebi oluşturur. Gün sayısı tarihlerden hesaplanır —
// istemciden gelen gün sayısına güvenilmez.
func (s *Service) CreateLeave(ctx context.Context, propertyID string, in models.CreateLeaveInput) (string, error) {
	in.LeaveType = strings.ToUpper(strings.TrimSpace(in.LeaveType))
	if !oneOf(in.LeaveType, LeaveTypes) {
		return "", ErrInvalidEnum
	}
	start, err := time.Parse("2006-01-02", in.StartDate)
	if err != nil {
		return "", ErrInvalidDate
	}
	end, err := time.Parse("2006-01-02", in.EndDate)
	if err != nil {
		return "", ErrInvalidDate
	}
	if end.Before(start) {
		return "", ErrDateOrder
	}
	// Başlangıç ve bitiş günleri dahil.
	days := end.Sub(start).Hours()/24 + 1
	return s.repo.CreateLeave(ctx, propertyID, in, start, end, days)
}

func (s *Service) ApproveLeave(ctx context.Context, propertyID, leaveID, userID string) error {
	return s.repo.DecideLeave(ctx, propertyID, leaveID, "APPROVED", userID, "")
}

func (s *Service) RejectLeave(ctx context.Context, propertyID, leaveID, userID, reason string) error {
	if reason == "" {
		return ErrReasonRequired
	}
	return s.repo.DecideLeave(ctx, propertyID, leaveID, "REJECTED", userID, reason)
}
