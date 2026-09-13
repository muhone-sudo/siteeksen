// Package service, gider yönetiminin iş kurallarını uygular.
package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/services/expense/models"
	"github.com/siteeksen/backend/services/expense/repository"
)

var (
	// ErrInvalidDate, tarih biçimi YYYY-AA-GG değilse döner.
	ErrInvalidDate = errors.New("tarih biçimi YYYY-AA-GG olmalıdır")
	// ErrInvoiceReasonRequired, faturasız gider için gerekçe zorunludur.
	//
	// NEDEN ZORUNLU: Faturasız gider, yönetimin hesap verme yükümlülüğü (KMK m.39) ve
	// denetim (m.41) açısından en hassas kalemdir. Gerekçesiz faturasız gider, denetçinin
	// ve kat maliklerinin sorgulayamayacağı bir harcama demektir.
	ErrInvoiceReasonRequired = errors.New("faturasız gider için gerekçe zorunludur")
	// ErrUnknownDistribution, tanınmayan dağıtım türü.
	ErrUnknownDistribution = errors.New("bilinmeyen dağıtım türü")
)

type Service struct{ repo *repository.Repository }

func New(repo *repository.Repository) *Service { return &Service{repo: repo} }

func (s *Service) ListCategories(ctx context.Context, propertyID string) ([]models.Category, error) {
	return s.repo.ListCategories(ctx, propertyID)
}

func (s *Service) List(ctx context.Context, propertyID string, year, month int, status, categoryID string) ([]models.Expense, error) {
	return s.repo.List(ctx, propertyID, year, month, status, categoryID)
}

func (s *Service) Get(ctx context.Context, propertyID, id string) (*models.Expense, error) {
	return s.repo.Get(ctx, propertyID, id)
}

func (s *Service) Summary(ctx context.Context, propertyID string, year, month int) (*models.Summary, error) {
	return s.repo.Summary(ctx, propertyID, year, month)
}

// Create, gideri kaydeder ve aidata yansıyacaksa bağımsız bölümlere paylaştırır.
//
// Dağıtım `pkg/money` ile KURUŞ üzerinden ve en büyük kalan yöntemiyle yapılır;
// payların toplamı gider tutarına BİREBİR eşittir. Her payı ayrı yuvarlamak,
// toplanan avans ile giderin örtüşmemesine yol açardı.
func (s *Service) Create(ctx context.Context, propertyID, userID string, in models.CreateExpenseInput) (*models.Expense, error) {
	expenseDate, err := time.Parse("2006-01-02", in.ExpenseDate)
	if err != nil {
		return nil, ErrInvalidDate
	}

	var invoiceDate *time.Time
	if in.InvoiceDate != "" {
		d, perr := time.Parse("2006-01-02", in.InvoiceDate)
		if perr != nil {
			return nil, ErrInvalidDate
		}
		invoiceDate = &d
	}

	category, err := s.repo.GetCategory(ctx, propertyID, in.CategoryID)
	if err != nil {
		return nil, err
	}

	isInvoiced := true
	if in.IsInvoiced != nil {
		isInvoiced = *in.IsInvoiced
	}
	if !isInvoiced && in.InvoiceReason == "" {
		return nil, ErrInvoiceReasonRequired
	}

	reflects := category.ReflectsToAssessment
	if in.ReflectsToAssessment != nil {
		reflects = *in.ReflectsToAssessment
	}

	distributionType := in.DistributionType
	if distributionType == "" {
		distributionType = category.DistributionType
	}

	var distributions []models.Distribution
	if reflects {
		distributions, err = s.distribute(ctx, propertyID, in.Amount, distributionType, category.AppliesToGroundFloor)
		if err != nil {
			return nil, err
		}
	}

	id, err := s.repo.Create(ctx, propertyID, userID, in, expenseDate, invoiceDate,
		isInvoiced, reflects, distributionType, distributions)
	if err != nil {
		return nil, err
	}
	return s.repo.Get(ctx, propertyID, id)
}

// distribute, tutarı dağıtım türüne göre bağımsız bölümlere paylaştırır.
//
// `appliesToGroundFloor=false` olan kalemlerde (örn. asansör bakımı) zemin kat
// bağımsız bölümleri dağıtıma DAHİL EDİLMEZ. KMK m.20 "başka türlü anlaşma
// olmadıkça" dediği için bu, yönetim planında sık görülen ve hukuken kabul edilen
// bir düzenlemedir; kalem bazında yapılandırılabilir.
func (s *Service) distribute(ctx context.Context, propertyID string, amount float64, kind string, appliesToGroundFloor bool) ([]models.Distribution, error) {
	units, err := s.repo.ListUnits(ctx, propertyID)
	if err != nil {
		return nil, err
	}

	shares := make([]money.Share, 0, len(units))
	names := make(map[string]string, len(units))
	for _, u := range units {
		names[u.ID] = u.Name
		if !appliesToGroundFloor && u.IsGround {
			continue
		}
		var w decimal.Decimal
		switch kind {
		case "EQUAL":
			w = decimal.NewFromInt(1)
		case "SHARE_RATIO":
			w = decimal.NewFromFloat(u.ShareRatio)
		case "AREA_M2":
			w = decimal.NewFromFloat(u.AreaM2)
		default:
			// METER_READING gibi tüketim bazlı kalemler gider kaydında paylaştırılmaz;
			// sayaç okumaları üzerinden ayrı hesaplanır.
			return nil, fmt.Errorf("%w: %s", ErrUnknownDistribution, kind)
		}
		shares = append(shares, money.Share{Key: u.ID, Weight: w})
	}
	if len(shares) == 0 {
		return nil, repository.ErrNoUnits
	}

	dist, err := money.Distribute(money.FromFloatTRY(amount), shares)
	if err != nil {
		return nil, err
	}

	out := make([]models.Distribution, 0, len(dist))
	for _, d := range dist {
		amt, _ := d.Amount.TRY().Float64()
		out = append(out, models.Distribution{
			UnitID:   d.Key,
			UnitName: names[d.Key],
			Amount:   amt,
		})
	}
	return out, nil
}

// Approve, faturasız gideri onaylar.
func (s *Service) Approve(ctx context.Context, propertyID, id, userID string) error {
	return s.repo.SetStatus(ctx, propertyID, id, models.StatusApproved, userID, "")
}

// Reject, faturasız gideri reddeder. Gerekçe zorunludur (denetlenebilirlik).
func (s *Service) Reject(ctx context.Context, propertyID, id, userID, reason string) error {
	if reason == "" {
		return errors.New("ret gerekçesi zorunludur")
	}
	return s.repo.SetStatus(ctx, propertyID, id, models.StatusRejected, userID, reason)
}
