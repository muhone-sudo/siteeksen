package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/services/finance/models"
	"github.com/siteeksen/backend/services/finance/repository"
)

// ErrAssessmentForbidden yönetim dışı kullanıcı tahakkuk oluşturmaya çalışırsa döner
var ErrAssessmentForbidden = errors.New("bu işlem için yetkiniz yok")

// isFinanceManagement kullanıcının yönetim rolüne sahip olup olmadığını kontrol eder.
// BOARD_MEMBER (yönetim kurulu üyesi) migration 013 ile tanımlandı ve buraya eklendi;
// aksi hâlde kurul üyesi kendi sitesinin mali özetini göremiyordu.
func isFinanceManagement(roles []string) bool {
	for _, role := range roles {
		switch role {
		// STAFF (görevli) bilerek YOK: site geneli mali veri görevlinin işi
		// değildir. Önceden burada vardı ama rota katmanı (RequireRole)
		// dışarıda bırakıyordu; iki katman farklı kural söylüyordu.
		case middleware.RoleManager, middleware.RoleAuditor, middleware.RoleBoardMember:
			return true
		}
	}
	return false
}

// FinanceService finans servisi
type FinanceService struct {
	repo   *repository.FinanceRepository
	params *legalparams.Resolver
}

// NewFinanceService yeni servis oluşturur.
// params, mevzuata bağlı oranların (gecikme tazminatı vb.) tek kaynağıdır.
func NewFinanceService(repo *repository.FinanceRepository, params *legalparams.Resolver) *FinanceService {
	return &FinanceService{repo: repo, params: params}
}

// DebtStatusResponse borç durumu yanıtı
type DebtStatusResponse struct {
	HasDebt        bool      `json:"has_debt"`
	CurrentBalance float64   `json:"current_balance"`
	OverdueAmount  float64   `json:"overdue_amount"`
	OverdueMonths  int       `json:"overdue_months"`
	NextDueDate    time.Time `json:"next_due_date"`
	NextDueAmount  float64   `json:"next_due_amount"`
}

// GetDebtStatus anlık borç durumu hesaplar
func (s *FinanceService) GetDebtStatus(ctx context.Context, userID, propertyID string) (*DebtStatusResponse, error) {
	balance, err := s.repo.GetUnitBalance(ctx, propertyID, userID)
	if err != nil {
		return nil, err
	}

	overdueInfo, err := s.repo.GetOverdueInfo(ctx, propertyID, userID)
	if err != nil {
		return nil, err
	}

	nextDue, err := s.repo.GetNextDueAssessment(ctx, propertyID, userID)
	if err != nil {
		// Gelecek ay için tahakkuk yoksa sıfır döndür
		nextDue = &models.Assessment{}
	}

	return &DebtStatusResponse{
		HasDebt:        balance > 0,
		CurrentBalance: balance,
		OverdueAmount:  overdueInfo.Amount,
		OverdueMonths:  overdueInfo.Months,
		NextDueDate:    nextDue.DueDate,
		NextDueAmount:  nextDue.TotalAmount,
	}, nil
}

// GetAssessments aidat listesi getirir
func (s *FinanceService) GetAssessments(ctx context.Context, propertyID, userID string, year int) ([]models.AssessmentSummary, error) {
	if year == 0 {
		year = time.Now().Year()
	}
	return s.repo.GetAssessments(ctx, propertyID, userID, year)
}

// ListAssessmentOverview site genelinde dönem bazlı tahakkuk/tahsilat özetini getirir (yalnızca yönetim rolleri)
func (s *FinanceService) ListAssessmentOverview(ctx context.Context, propertyID string, roles []string, year int) ([]models.AssessmentPeriodSummary, error) {
	if !isFinanceManagement(roles) {
		return nil, ErrAssessmentForbidden
	}
	if year == 0 {
		year = time.Now().Year()
	}
	return s.repo.ListAssessmentPeriods(ctx, propertyID, year)
}

// GetAssessmentDetails aidat detayı getirir
func (s *FinanceService) GetAssessmentDetails(ctx context.Context, propertyID, userID string, roles []string, assessmentID string) (*models.AssessmentDetail, error) {
	resident := userID
	if isFinanceManagement(roles) {
		resident = "" // yönetim ve denetçi site genelini görür
	}
	return s.repo.GetAssessmentDetails(ctx, propertyID, resident, assessmentID)
}

// ListExpenseCategories sitenin gider kalemlerini getirir (yalnızca yönetim rolleri —
// aidat tahakkuku formu bu listeden kalem seçtirir)
func (s *FinanceService) ListExpenseCategories(ctx context.Context, propertyID string, roles []string) ([]models.ExpenseCategory, error) {
	if !isFinanceManagement(roles) {
		return nil, ErrAssessmentForbidden
	}
	return s.repo.ListExpenseCategories(ctx, propertyID)
}

// CreateAssessment yönetimin belirlediği gider kalemlerine göre site genelinde
// dönemlik aidat tahakkuku oluşturur (yalnızca yönetim rolleri).
func (s *FinanceService) CreateAssessment(ctx context.Context, propertyID string, roles []string, input models.CreateAssessmentInput) ([]models.AssessmentSummary, error) {
	if !isFinanceManagement(roles) {
		return nil, ErrAssessmentForbidden
	}
	return s.repo.CreateAssessment(ctx, propertyID, input)
}

// PaymentResult ödeme sonucu
type PaymentResult struct {
	PaymentID string  `json:"payment_id"`
	Amount    float64 `json:"amount"`
	Status    string  `json:"status"`
	// PaymentGatewayReady ödeme sağlayıcısı entegrasyonunun hazır olup olmadığını bildirir.
	// `false` iken istemci kullanıcıya "ödeme alınamıyor" bilgisini göstermeli, ödeme akışını
	// başarılı gibi sonlandırmamalıdır.
	PaymentGatewayReady bool   `json:"payment_gateway_ready"`
	CheckoutURL         string `json:"checkout_url,omitempty"`
}

// CreatePayment ödeme kaydı oluşturur.
//
// Tutar hesaplama, sahiplik doğrulaması ve kayıt artık repository katmanında tek bir
// transaction içinde yapılır (bkz. repository.CreatePayment).
//
// ÖNEMLİ (2026-09-09): Bu uç nokta gerçek bir ödeme ALMAZ. Yalnızca `PENDING` durumunda bir
// ödeme kaydı oluşturur. Önceki sürüm, kredi kartı seçildiğinde var olmayan bir adrese
// (`https://checkout.siteeksen.com/pay/...`) yönlendiren sahte bir "checkout URL" döndürüyordu;
// bu, istemciye ödemenin başlatıldığı izlenimi veriyordu. Ödeme sağlayıcısı entegrasyonu
// yazılana kadar (tasks/questions.md S-06) sahte adres döndürülmez.
func (s *FinanceService) CreatePayment(ctx context.Context, propertyID, userID string, assessmentIDs []string, method, cardToken string) (*PaymentResult, error) {
	paymentID, totalAmount, err := s.repo.CreatePayment(ctx, propertyID, userID, assessmentIDs, method)
	if err != nil {
		return nil, err
	}

	return &PaymentResult{
		PaymentID: paymentID,
		Amount:    totalAmount,
		Status:    "PENDING",
		// Ödeme sağlayıcısı bağlanana kadar tahsilat yapılamaz; istemci bunu kullanıcıya
		// açıkça göstermelidir.
		PaymentGatewayReady: false,
	}, nil
}

// LateFeeRunResult, gecikme tazminatı işletme sonucudur.
type LateFeeRunResult struct {
	AsOf           string  `json:"as_of"`
	MonthlyRate    string  `json:"monthly_rate"`
	LegalBasis     string  `json:"legal_basis"`
	ProcessedCount int     `json:"processed_count"`
	TotalFeeKurus  int64   `json:"total_fee_kurus"`
	TotalFeeTRY    float64 `json:"total_fee_try"`
	SkippedNotDue  int     `json:"skipped_not_due"`
}

// AccrueLateFees, vadesi geçmiş tahakkuklara gecikme tazminatı işler (KMK m.20/2).
//
// NEDEN VAR: Gecikme tazminatı bugüne kadar HİÇ hesaplanmıyordu. Kanun, ödemede
// geciken kat malikinin "geciktiği günler için aylık yüzde beş hesabıyla" tazminat
// ödeyeceğini söyler; bu, yönetimin takdirine bırakılmış bir şey değildir.
//
// Oran koda gömülmez; `legal_parameters` (KMK m.20/2, aylık %5) üzerinden okunur ve
// hesaplama `pkg/money` ile kuruş üzerinden yapılır.
//
// İşlem IDEMPOTENTTİR: tazminat (anapara, gün, oran) fonksiyonu olarak her seferinde
// baştan hesaplanır ve tahakkuka YAZILIR, eklenmez. Aynı gün iki kez çalıştırmak
// borcu iki katına çıkarmaz.
func (s *FinanceService) AccrueLateFees(ctx context.Context, propertyID string, asOf time.Time) (*LateFeeRunResult, error) {
	if asOf.IsZero() {
		asOf = time.Now()
	}

	rateParam, err := s.params.Get(ctx, propertyID, legalparams.LateFeeMonthlyRate, asOf)
	if err != nil {
		return nil, err
	}

	items, err := s.repo.ListOverdueForLateFee(ctx, propertyID, asOf)
	if err != nil {
		return nil, err
	}

	res := &LateFeeRunResult{
		AsOf:        asOf.Format("2006-01-02"),
		MonthlyRate: rateParam.Numeric.String(),
		LegalBasis:  rateParam.LegalBasis,
	}

	for _, it := range items {
		if it.OverdueDays <= 0 || it.PrincipalKurus <= 0 {
			res.SkippedNotDue++
			continue
		}
		fee, err := money.LateFee(money.Kurus(it.PrincipalKurus), rateParam.Numeric, it.OverdueDays)
		if err != nil {
			return nil, fmt.Errorf("gecikme tazminatı hesaplanamadı (tahakkuk %s): %w", it.ID, err)
		}
		if err := s.repo.ApplyLateFee(ctx, propertyID, it.ID, asOf, it.OverdueDays,
			it.PrincipalKurus, int64(fee), rateParam.Numeric.String()); err != nil {
			return nil, fmt.Errorf("gecikme tazminatı işlenemedi (tahakkuk %s): %w", it.ID, err)
		}
		res.ProcessedCount++
		res.TotalFeeKurus += int64(fee)
	}
	res.TotalFeeTRY = float64(res.TotalFeeKurus) / 100
	return res, nil
}

// ConfirmPayment, yöneticinin bekleyen bir ödemeyi tahsil edilmiş olarak onaylamasıdır.
//
// NEDEN BU AKIŞ VAR (todo 4.2): Ödeme sağlayıcısı entegrasyonu yok (questions.md S-06),
// ama Türkiye'de site aidatlarının büyük kısmı havale/EFT ve nakit ile tahsil ediliyor.
// Yönetici onayı olmadan `paid_amount` hiç güncellenmiyor; ödemesini yapmış sakin
// sistemde sonsuza dek borçlu kalıyordu. Onay akışı bu boşluğu kapatır ve sağlayıcı
// entegrasyonu geldiğinde aynı repository çağrısı webhook'tan kullanılabilir.
func (s *FinanceService) ConfirmPayment(ctx context.Context, paymentID, propertyID, reference string) error {
	return s.repo.ConfirmPayment(ctx, paymentID, propertyID, reference)
}

// RejectPayment, bekleyen ödemeyi başarısız işaretler; borç olduğu gibi kalır.
func (s *FinanceService) RejectPayment(ctx context.Context, paymentID, propertyID string) error {
	return s.repo.RejectPayment(ctx, paymentID, propertyID)
}

// ListPendingPayments, onay bekleyen ödemeleri getirir (yönetim ekranı için).
func (s *FinanceService) ListPendingPayments(ctx context.Context, propertyID string) ([]models.PropertyPayment, error) {
	return s.repo.ListPendingPayments(ctx, propertyID)
}

// GetPaymentHistory ödeme geçmişi getirir — yönetim rolleri site genelindeki tüm ödemeleri,
// sakinler yalnızca kendi ödemelerini görür
func (s *FinanceService) GetPaymentHistory(ctx context.Context, userID, propertyID string, roles []string) (interface{}, error) {
	if isFinanceManagement(roles) {
		return s.repo.ListPropertyPayments(ctx, propertyID)
	}
	return s.repo.GetPaymentHistory(ctx, propertyID, userID)
}

// GetMyPayments, çağıranın KENDİ ödemelerini döner — rolünden bağımsız.
// Önceden sakinin kendi ödeme geçmişine ulaşabileceği bir uç yoktu: servis
// kodu vardı ama rota yalnızca yönetime açıktı.
func (s *FinanceService) GetMyPayments(ctx context.Context, userID, propertyID string) (interface{}, error) {
	return s.repo.GetPaymentHistory(ctx, propertyID, userID)
}

// ListDebtors sitede borcu olan sakinlerin özetini getirir (yalnızca yönetim rolleri)
func (s *FinanceService) ListDebtors(ctx context.Context, propertyID string, roles []string) ([]models.Debtor, error) {
	if !isFinanceManagement(roles) {
		return nil, ErrAssessmentForbidden
	}
	return s.repo.ListDebtors(ctx, propertyID)
}

// ConsumptionSummary tüketim özeti
type ConsumptionSummary struct {
	MeterType string                   `json:"meter_type"`
	Unit      string                   `json:"unit"`
	Data      []models.ConsumptionData `json:"data"`
}

// GetConsumptionSummary tüketim özeti getirir
func (s *FinanceService) GetConsumptionSummary(ctx context.Context, propertyID, userID, meterType string) (*ConsumptionSummary, error) {
	data, err := s.repo.GetConsumptionData(ctx, propertyID, userID, meterType, 6)
	if err != nil {
		return nil, err
	}

	unit := "kWh"
	if meterType == "WATER_COLD" || meterType == "WATER_HOT" {
		unit = "m³"
	}

	return &ConsumptionSummary{
		MeterType: meterType,
		Unit:      unit,
		Data:      data,
	}, nil
}
