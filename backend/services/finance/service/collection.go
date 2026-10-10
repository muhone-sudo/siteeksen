package service

// Yönetimin tahsilat girişi (migration 061, beşinci tur B2).

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/siteeksen/backend/services/finance/repository"
)

// CollectionInput, yönetimin tahsilat formudur.
type CollectionInput struct {
	UnitID        string   `json:"unit_id"`
	AssessmentIDs []string `json:"assessment_ids"`
	// PaymentMethod: BANK_TRANSFER (havale/EFT) ya da CASH (elden). Ekstre satırında yok sayılır.
	PaymentMethod string `json:"payment_method"`
	// ValueDate: paranın ödendiği gün (YYYY-AA-GG). Ekstre satırında hareketin günü kullanılır.
	ValueDate string `json:"value_date"`
	Reference string `json:"reference"`
}

// CollectionResult, girilen tahsilatın sonucudur.
type CollectionResult struct {
	PaymentID   string `json:"payment_id"`
	AmountKurus int64  `json:"amount_kurus"`
	ValueDate   string `json:"value_date"`
	Method      string `json:"payment_method"`
	Status      string `json:"status"`
}

// RecordCollection, tahsilatı doğrular, gecikme tazminatını ödeme gününe göre hesaplar
// (sakinin bildirdiği ödemeyle aynı kural, 053) ve ödemeyi açıp aynı işlemde onaylar.
// bankLineID verilirse gün, yöntem ve açıklama ekstre satırından alınır.
func (s *FinanceService) RecordCollection(ctx context.Context, propertyID, managerID string, in CollectionInput, bankLineID string) (*CollectionResult, error) {
	in.UnitID = strings.TrimSpace(in.UnitID)
	if in.UnitID == "" || len(in.AssessmentIDs) == 0 || len(in.AssessmentIDs) > 60 {
		return nil, fmt.Errorf("%w: bölüm ve en az bir (en çok 60) borç seçilmelidir", repository.ErrInvalidAssessmentInput)
	}
	seen := map[string]bool{}
	for _, id := range in.AssessmentIDs {
		if seen[id] {
			return nil, fmt.Errorf("%w: aynı borç iki kez seçildi", repository.ErrInvalidAssessmentInput)
		}
		seen[id] = true
	}
	in.Reference = strings.TrimSpace(in.Reference)
	if len([]rune(in.Reference)) > 140 {
		return nil, fmt.Errorf("%w: açıklama en çok 140 karakter olabilir", repository.ErrInvalidAssessmentInput)
	}

	var valueDate time.Time
	method := strings.ToUpper(strings.TrimSpace(in.PaymentMethod))
	if bankLineID != "" {
		line, err := s.repo.BankLineForCollection(ctx, propertyID, bankLineID)
		if err != nil {
			return nil, err
		}
		if line.AmountKurus <= 0 {
			return nil, repository.ErrBankLineResolved
		}
		valueDate, method = line.Date, "BANK_TRANSFER"
	} else {
		if method != "BANK_TRANSFER" && method != "CASH" {
			return nil, fmt.Errorf("%w: ödeme yöntemi BANK_TRANSFER ya da CASH olmalıdır", repository.ErrInvalidAssessmentInput)
		}
		d, err := time.ParseInLocation("2006-01-02", strings.TrimSpace(in.ValueDate), time.Local)
		if err != nil {
			return nil, fmt.Errorf("%w: ödeme günü YYYY-AA-GG biçiminde zorunludur", repository.ErrInvalidAssessmentInput)
		}
		y, m, dd := time.Now().Date()
		if d.After(time.Date(y, m, dd, 0, 0, 0, 0, time.Local)) {
			return nil, fmt.Errorf("%w: ödeme günü ileri bir tarih olamaz", repository.ErrInvalidAssessmentInput)
		}
		valueDate = d
	}

	if err := s.freezeLateFees(ctx, propertyID, "", in.AssessmentIDs, valueDate); err != nil {
		return nil, err
	}
	id, kurus, err := s.repo.RecordCollection(ctx, propertyID, managerID, repository.CollectionInput{
		UnitID: in.UnitID, AssessmentIDs: in.AssessmentIDs, Method: method, ValueDate: valueDate,
		Reference: in.Reference, BankLineID: bankLineID,
	})
	if err != nil {
		return nil, err
	}
	return &CollectionResult{PaymentID: id, AmountKurus: kurus, ValueDate: valueDate.Format("2006-01-02"),
		Method: method, Status: "COMPLETED"}, nil
}
