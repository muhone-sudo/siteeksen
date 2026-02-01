package payment

import (
	"fmt"
)

// PaymentService - ödeme servisi
type PaymentService struct {
	iyzico *IyzicoClient
}

// NewPaymentService - yeni ödeme servisi
func NewPaymentService() *PaymentService {
	return &PaymentService{
		iyzico: NewIyzicoClient(),
	}
}

// AssessmentPaymentInput - aidat ödeme input
type AssessmentPaymentInput struct {
	UserID         string
	UserName       string
	UserSurname    string
	UserEmail      string
	UserPhone      string
	UserIP         string
	AssessmentIDs  []string
	TotalAmount    float64
	Card           *CardInput
	SaveCard       bool
	Use3DSecure    bool
	CallbackURL    string
}

type CardInput struct {
	HolderName  string
	Number      string
	ExpireMonth string
	ExpireYear  string
	Cvc         string
	Token       string // Kayıtlı kart için
	UserKey     string
}

// PaymentResult - ödeme sonucu
type PaymentResult struct {
	Success          bool
	PaymentID        string
	TransactionID    string
	ErrorMessage     string
	ThreeDSContent   string // 3DS için HTML
	CardToken        string // Kart kaydedildiyse
	CardUserKey      string
}

// ProcessAssessmentPayment - aidat ödemesi işle
func (s *PaymentService) ProcessAssessmentPayment(input *AssessmentPaymentInput) (*PaymentResult, error) {
	// Basket items oluştur
	basketItems := make([]BasketItem, len(input.AssessmentIDs))
	pricePerItem := input.TotalAmount / float64(len(input.AssessmentIDs))

	for i, assessmentID := range input.AssessmentIDs {
		basketItems[i] = BasketItem{
			ID:        assessmentID,
			Name:      fmt.Sprintf("Aidat Ödemesi - %s", assessmentID[:8]),
			Category1: "Aidat",
			ItemType:  "VIRTUAL",
			Price:     fmt.Sprintf("%.2f", pricePerItem),
		}
	}

	// Alıcı bilgileri
	buyer := &Buyer{
		ID:                  input.UserID,
		Name:                input.UserName,
		Surname:             input.UserSurname,
		GsmNumber:           input.UserPhone,
		Email:               input.UserEmail,
		IdentityNumber:      "11111111111", // Gerçek uygulamada kullanıcıdan alınmalı
		RegistrationAddress: "Türkiye",
		IP:                  input.UserIP,
		City:                "İstanbul",
		Country:             "Turkey",
	}

	// Adres
	address := &Address{
		ContactName: fmt.Sprintf("%s %s", input.UserName, input.UserSurname),
		City:        "İstanbul",
		Country:     "Turkey",
		Address:     "Türkiye",
	}

	// Kart bilgileri
	var paymentCard *PaymentCard
	if input.Card.Token != "" {
		// Kayıtlı kart ile ödeme
		paymentCard = &PaymentCard{
			CardToken:   input.Card.Token,
			CardUserKey: input.Card.UserKey,
		}
	} else {
		// Yeni kart ile ödeme
		registerCard := 0
		if input.SaveCard {
			registerCard = 1
		}
		paymentCard = &PaymentCard{
			CardHolderName: input.Card.HolderName,
			CardNumber:     input.Card.Number,
			ExpireMonth:    input.Card.ExpireMonth,
			ExpireYear:     input.Card.ExpireYear,
			Cvc:            input.Card.Cvc,
			RegisterCard:   registerCard,
		}
	}

	priceStr := fmt.Sprintf("%.2f", input.TotalAmount)

	// 3D Secure kullanılacak mı?
	if input.Use3DSecure {
		req := &ThreeDSInitRequest{
			PaymentRequest: PaymentRequest{
				Price:           priceStr,
				PaidPrice:       priceStr,
				Currency:        "TRY",
				Installment:     1,
				BasketID:        fmt.Sprintf("B-%s", input.AssessmentIDs[0][:8]),
				PaymentCard:     paymentCard,
				Buyer:           buyer,
				ShippingAddress: address,
				BillingAddress:  address,
				BasketItems:     basketItems,
			},
			CallbackURL: input.CallbackURL,
		}

		resp, err := s.iyzico.Create3DSPayment(req)
		if err != nil {
			return nil, err
		}

		if resp.Status != "success" {
			return &PaymentResult{
				Success:      false,
				ErrorMessage: resp.ErrorMessage,
			}, nil
		}

		return &PaymentResult{
			Success:        true,
			ThreeDSContent: resp.ThreeDSHtmlContent,
		}, nil
	}

	// Direkt ödeme (3D'siz)
	req := &PaymentRequest{
		Price:           priceStr,
		PaidPrice:       priceStr,
		Currency:        "TRY",
		Installment:     1,
		BasketID:        fmt.Sprintf("B-%s", input.AssessmentIDs[0][:8]),
		PaymentCard:     paymentCard,
		Buyer:           buyer,
		ShippingAddress: address,
		BillingAddress:  address,
		BasketItems:     basketItems,
	}

	resp, err := s.iyzico.CreatePayment(req)
	if err != nil {
		return nil, err
	}

	if resp.Status != "success" {
		return &PaymentResult{
			Success:      false,
			ErrorMessage: resp.ErrorMessage,
		}, nil
	}

	return &PaymentResult{
		Success:       true,
		PaymentID:     resp.PaymentID,
		TransactionID: resp.PaymentTransactionID,
		CardToken:     resp.CardToken,
		CardUserKey:   resp.CardUserKey,
	}, nil
}

// Complete3DSPayment - 3DS tamamlama
func (s *PaymentService) Complete3DSPayment(paymentID string) (*PaymentResult, error) {
	resp, err := s.iyzico.Complete3DSPayment(paymentID)
	if err != nil {
		return nil, err
	}

	if resp.Status != "success" {
		return &PaymentResult{
			Success:      false,
			ErrorMessage: resp.ErrorMessage,
		}, nil
	}

	return &PaymentResult{
		Success:       true,
		PaymentID:     resp.PaymentID,
		TransactionID: resp.PaymentTransactionID,
	}, nil
}

// RefundPayment - ödeme iadesi
func (s *PaymentService) RefundPayment(transactionID string, amount float64) (*PaymentResult, error) {
	resp, err := s.iyzico.Refund(transactionID, fmt.Sprintf("%.2f", amount))
	if err != nil {
		return nil, err
	}

	if resp.Status != "success" {
		return &PaymentResult{
			Success:      false,
			ErrorMessage: resp.ErrorMessage,
		}, nil
	}

	return &PaymentResult{
		Success:   true,
		PaymentID: resp.PaymentID,
	}, nil
}
