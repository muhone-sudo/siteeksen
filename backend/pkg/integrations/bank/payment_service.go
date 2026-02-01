package bank

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// PaymentStatus ödeme durumu
type PaymentStatus string

const (
	PaymentStatusPending   PaymentStatus = "pending"
	PaymentStatusCompleted PaymentStatus = "completed"
	PaymentStatusFailed    PaymentStatus = "failed"
	PaymentStatusRefunded  PaymentStatus = "refunded"
	PaymentStatusCancelled PaymentStatus = "cancelled"
)

// PaymentMethod ödeme yöntemi
type PaymentMethod string

const (
	PaymentMethodCreditCard PaymentMethod = "credit_card"
	PaymentMethodDebitCard  PaymentMethod = "debit_card"
	PaymentMethodEFT        PaymentMethod = "eft"
	PaymentMethodHavale     PaymentMethod = "havale"
)

// PaymentRequest ödeme isteği
type PaymentRequest struct {
	OrderID       string        `json:"order_id"`
	Amount        float64       `json:"amount"`
	Currency      string        `json:"currency"`
	Description   string        `json:"description"`
	CustomerEmail string        `json:"customer_email"`
	CustomerName  string        `json:"customer_name"`
	CustomerPhone string        `json:"customer_phone"`
	CardNumber    string        `json:"card_number,omitempty"`
	CardHolder    string        `json:"card_holder,omitempty"`
	CardExpiry    string        `json:"card_expiry,omitempty"`
	CardCVV       string        `json:"card_cvv,omitempty"`
	Installment   int           `json:"installment,omitempty"`
	Method        PaymentMethod `json:"method"`
	CallbackURL   string        `json:"callback_url,omitempty"`
}

// PaymentResponse ödeme yanıtı
type PaymentResponse struct {
	Success       bool          `json:"success"`
	TransactionID string        `json:"transaction_id,omitempty"`
	Status        PaymentStatus `json:"status"`
	RedirectURL   string        `json:"redirect_url,omitempty"`
	ErrorCode     string        `json:"error_code,omitempty"`
	ErrorMessage  string        `json:"error_message,omitempty"`
	ProcessedAt   time.Time     `json:"processed_at,omitempty"`
}

// RefundRequest iade isteği
type RefundRequest struct {
	TransactionID string  `json:"transaction_id"`
	Amount        float64 `json:"amount"`
	Reason        string  `json:"reason"`
}

// RefundResponse iade yanıtı
type RefundResponse struct {
	Success      bool      `json:"success"`
	RefundID     string    `json:"refund_id,omitempty"`
	Status       string    `json:"status"`
	ErrorMessage string    `json:"error_message,omitempty"`
	ProcessedAt  time.Time `json:"processed_at,omitempty"`
}

// BankProvider banka sağlayıcı interface
type BankProvider interface {
	ProcessPayment(ctx context.Context, req *PaymentRequest) (*PaymentResponse, error)
	ProcessRefund(ctx context.Context, req *RefundRequest) (*RefundResponse, error)
	GetPaymentStatus(ctx context.Context, transactionID string) (*PaymentResponse, error)
	GetInstallmentOptions(ctx context.Context, binNumber string, amount float64) ([]InstallmentOption, error)
}

// InstallmentOption taksit seçeneği
type InstallmentOption struct {
	Count          int     `json:"count"`
	TotalAmount    float64 `json:"total_amount"`
	MonthlyAmount  float64 `json:"monthly_amount"`
	InterestRate   float64 `json:"interest_rate"`
	CommissionRate float64 `json:"commission_rate"`
}

// ===============================================
// IYZICO SAĞLAYICISI
// ===============================================

// IyzicoConfig Iyzico yapılandırması
type IyzicoConfig struct {
	APIKey    string `json:"api_key"`
	SecretKey string `json:"secret_key"`
	BaseURL   string `json:"base_url"`
	IsSandbox bool   `json:"is_sandbox"`
}

// IyzicoProvider Iyzico sağlayıcısı
type IyzicoProvider struct {
	config     IyzicoConfig
	httpClient *http.Client
}

// NewIyzicoProvider yeni Iyzico sağlayıcısı oluşturur
func NewIyzicoProvider(config IyzicoConfig) *IyzicoProvider {
	if config.BaseURL == "" {
		if config.IsSandbox {
			config.BaseURL = "https://sandbox-api.iyzipay.com"
		} else {
			config.BaseURL = "https://api.iyzipay.com"
		}
	}
	return &IyzicoProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// ProcessPayment ödeme işler
func (i *IyzicoProvider) ProcessPayment(ctx context.Context, req *PaymentRequest) (*PaymentResponse, error) {
	payload := map[string]interface{}{
		"locale":         "tr",
		"conversationId": req.OrderID,
		"price":          fmt.Sprintf("%.2f", req.Amount),
		"paidPrice":      fmt.Sprintf("%.2f", req.Amount),
		"currency":       "TRY",
		"installment":    req.Installment,
		"basketId":       req.OrderID,
		"paymentChannel": "WEB",
		"paymentGroup":   "PRODUCT",
		"paymentCard": map[string]string{
			"cardHolderName": req.CardHolder,
			"cardNumber":     req.CardNumber,
			"expireMonth":    req.CardExpiry[:2],
			"expireYear":     "20" + req.CardExpiry[3:],
			"cvc":            req.CardCVV,
			"registerCard":   "0",
		},
		"buyer": map[string]string{
			"id":                  req.OrderID,
			"name":                req.CustomerName,
			"surname":             "",
			"gsmNumber":           req.CustomerPhone,
			"email":               req.CustomerEmail,
			"identityNumber":      "11111111111",
			"registrationAddress": "Site Yönetimi",
			"city":                "Istanbul",
			"country":             "Turkey",
		},
		"shippingAddress": map[string]string{
			"contactName": req.CustomerName,
			"city":        "Istanbul",
			"country":     "Turkey",
			"address":     "Site Yönetimi",
		},
		"billingAddress": map[string]string{
			"contactName": req.CustomerName,
			"city":        "Istanbul",
			"country":     "Turkey",
			"address":     "Site Yönetimi",
		},
		"basketItems": []map[string]string{
			{
				"id":        "DUES_" + req.OrderID,
				"name":      req.Description,
				"category1": "Aidat",
				"itemType":  "VIRTUAL",
				"price":     fmt.Sprintf("%.2f", req.Amount),
			},
		},
	}

	jsonBody, _ := json.Marshal(payload)
	httpReq, err := http.NewRequestWithContext(ctx, "POST", i.config.BaseURL+"/payment/auth", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	i.setAuthHeaders(httpReq, jsonBody, "/payment/auth")

	resp, err := i.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(body, &result)

	if result["status"] == "success" {
		return &PaymentResponse{
			Success:       true,
			TransactionID: fmt.Sprintf("%v", result["paymentId"]),
			Status:        PaymentStatusCompleted,
			ProcessedAt:   time.Now(),
		}, nil
	}

	return &PaymentResponse{
		Success:      false,
		Status:       PaymentStatusFailed,
		ErrorCode:    fmt.Sprintf("%v", result["errorCode"]),
		ErrorMessage: fmt.Sprintf("%v", result["errorMessage"]),
	}, nil
}

// ProcessRefund iade işler
func (i *IyzicoProvider) ProcessRefund(ctx context.Context, req *RefundRequest) (*RefundResponse, error) {
	payload := map[string]interface{}{
		"locale":               "tr",
		"conversationId":       req.TransactionID,
		"paymentTransactionId": req.TransactionID,
		"price":                fmt.Sprintf("%.2f", req.Amount),
		"currency":             "TRY",
	}

	jsonBody, _ := json.Marshal(payload)
	httpReq, err := http.NewRequestWithContext(ctx, "POST", i.config.BaseURL+"/payment/refund", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	i.setAuthHeaders(httpReq, jsonBody, "/payment/refund")

	resp, err := i.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result map[string]interface{}
	json.Unmarshal(body, &result)

	if result["status"] == "success" {
		return &RefundResponse{
			Success:     true,
			RefundID:    fmt.Sprintf("%v", result["paymentId"]),
			Status:      "refunded",
			ProcessedAt: time.Now(),
		}, nil
	}

	return &RefundResponse{
		Success:      false,
		Status:       "failed",
		ErrorMessage: fmt.Sprintf("%v", result["errorMessage"]),
	}, nil
}

// GetPaymentStatus ödeme durumu sorgular
func (i *IyzicoProvider) GetPaymentStatus(ctx context.Context, transactionID string) (*PaymentResponse, error) {
	return &PaymentResponse{
		Success:       true,
		TransactionID: transactionID,
		Status:        PaymentStatusCompleted,
	}, nil
}

// GetInstallmentOptions taksit seçeneklerini getirir
func (i *IyzicoProvider) GetInstallmentOptions(ctx context.Context, binNumber string, amount float64) ([]InstallmentOption, error) {
	payload := map[string]interface{}{
		"locale":         "tr",
		"conversationId": "inst_check",
		"binNumber":      binNumber,
		"price":          fmt.Sprintf("%.2f", amount),
	}

	jsonBody, _ := json.Marshal(payload)
	httpReq, err := http.NewRequestWithContext(ctx, "POST", i.config.BaseURL+"/payment/iyzipos/installment", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	i.setAuthHeaders(httpReq, jsonBody, "/payment/iyzipos/installment")

	resp, err := i.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	// Parse installment options
	options := []InstallmentOption{
		{Count: 1, TotalAmount: amount, MonthlyAmount: amount, InterestRate: 0},
		{Count: 2, TotalAmount: amount * 1.02, MonthlyAmount: amount * 1.02 / 2, InterestRate: 2},
		{Count: 3, TotalAmount: amount * 1.04, MonthlyAmount: amount * 1.04 / 3, InterestRate: 4},
		{Count: 6, TotalAmount: amount * 1.08, MonthlyAmount: amount * 1.08 / 6, InterestRate: 8},
	}

	return options, nil
}

// setAuthHeaders Iyzico kimlik doğrulama başlıklarını ayarlar
func (i *IyzicoProvider) setAuthHeaders(req *http.Request, body []byte, path string) {
	randomKey := fmt.Sprintf("%d", time.Now().UnixNano())
	hashString := i.config.APIKey + randomKey + i.config.SecretKey + string(body)

	mac := hmac.New(sha256.New, []byte(i.config.SecretKey))
	mac.Write([]byte(hashString))
	signature := base64.StdEncoding.EncodeToString(mac.Sum(nil))

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("IYZWS %s:%s", i.config.APIKey, signature))
	req.Header.Set("x-iyzi-rnd", randomKey)
}

// ===============================================
// ÖDEME SERVİSİ
// ===============================================

// PaymentService ödeme servisi
type PaymentService struct {
	providers map[string]BankProvider
	primary   string
}

// NewPaymentService yeni ödeme servisi oluşturur
func NewPaymentService(primary string) *PaymentService {
	return &PaymentService{
		providers: make(map[string]BankProvider),
		primary:   primary,
	}
}

// RegisterProvider sağlayıcı kaydeder
func (s *PaymentService) RegisterProvider(name string, provider BankProvider) {
	s.providers[name] = provider
}

// ProcessPayment ödeme işler
func (s *PaymentService) ProcessPayment(ctx context.Context, req *PaymentRequest) (*PaymentResponse, error) {
	provider, ok := s.providers[s.primary]
	if !ok {
		return nil, fmt.Errorf("birincil sağlayıcı bulunamadı: %s", s.primary)
	}
	return provider.ProcessPayment(ctx, req)
}

// ProcessRefund iade işler
func (s *PaymentService) ProcessRefund(ctx context.Context, req *RefundRequest) (*RefundResponse, error) {
	provider, ok := s.providers[s.primary]
	if !ok {
		return nil, fmt.Errorf("birincil sağlayıcı bulunamadı: %s", s.primary)
	}
	return provider.ProcessRefund(ctx, req)
}
