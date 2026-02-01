package banking

import (
	"bytes"
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net/http"
	"time"
)

// BankType banka türü
type BankType string

const (
	BankZiraat    BankType = "ziraat"
	BankIsbank    BankType = "isbank"
	BankGaranti   BankType = "garanti"
	BankYapiKredi BankType = "yapikredi"
	BankAkbank    BankType = "akbank"
	BankVakifbank BankType = "vakifbank"
	BankHalkbank  BankType = "halkbank"
	BankQNB       BankType = "qnb"
	BankING       BankType = "ing"
	BankDenizbank BankType = "denizbank"
)

// TransactionType işlem türü
type TransactionType string

const (
	TransactionIncoming TransactionType = "incoming"
	TransactionOutgoing TransactionType = "outgoing"
)

// MatchStatus eşleştirme durumu
type MatchStatus string

const (
	MatchPending  MatchStatus = "pending"
	MatchMatched  MatchStatus = "matched"
	MatchManual   MatchStatus = "manual"
	MatchRejected MatchStatus = "rejected"
)

// BankAccount banka hesabı
type BankAccount struct {
	ID          string    `json:"id"`
	SiteID      string    `json:"site_id"`
	Bank        BankType  `json:"bank"`
	AccountNo   string    `json:"account_no"`
	IBAN        string    `json:"iban"`
	BranchCode  string    `json:"branch_code"`
	AccountName string    `json:"account_name"`
	Currency    string    `json:"currency"`
	Balance     float64   `json:"balance"`
	LastSyncAt  time.Time `json:"last_sync_at"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

// BankTransaction banka hareketi
type BankTransaction struct {
	ID                string          `json:"id"`
	AccountID         string          `json:"account_id"`
	TransactionDate   time.Time       `json:"transaction_date"`
	ValueDate         time.Time       `json:"value_date"`
	Type              TransactionType `json:"type"`
	Amount            float64         `json:"amount"`
	Balance           float64         `json:"balance"`
	Description       string          `json:"description"`
	SenderName        string          `json:"sender_name,omitempty"`
	SenderIBAN        string          `json:"sender_iban,omitempty"`
	ReceiverName      string          `json:"receiver_name,omitempty"`
	ReceiverIBAN      string          `json:"receiver_iban,omitempty"`
	ReferenceNo       string          `json:"reference_no"`
	MatchStatus       MatchStatus     `json:"match_status"`
	MatchedDuesID     string          `json:"matched_dues_id,omitempty"`
	MatchedResidentID string          `json:"matched_resident_id,omitempty"`
	MatchConfidence   float64         `json:"match_confidence,omitempty"`
	CreatedAt         time.Time       `json:"created_at"`
}

// MatchResult eşleştirme sonucu
type MatchResult struct {
	TransactionID  string           `json:"transaction_id"`
	Status         MatchStatus      `json:"status"`
	DuesID         string           `json:"dues_id,omitempty"`
	ResidentID     string           `json:"resident_id,omitempty"`
	ResidentName   string           `json:"resident_name,omitempty"`
	UnitNo         string           `json:"unit_no,omitempty"`
	Confidence     float64          `json:"confidence"`
	MatchReason    string           `json:"match_reason,omitempty"`
	SuggestedMatch []SuggestedMatch `json:"suggested_matches,omitempty"`
}

// SuggestedMatch önerilen eşleşme
type SuggestedMatch struct {
	DuesID       string  `json:"dues_id"`
	ResidentID   string  `json:"resident_id"`
	ResidentName string  `json:"resident_name"`
	UnitNo       string  `json:"unit_no"`
	Amount       float64 `json:"amount"`
	DueDate      string  `json:"due_date"`
	Confidence   float64 `json:"confidence"`
	Reason       string  `json:"reason"`
}

// BankProvider banka sağlayıcı interface
type BankProvider interface {
	GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error)
	GetBalance(ctx context.Context, account *BankAccount) (float64, error)
	ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error
}

// ===============================================
// ZİRAAT BANKASI
// ===============================================

// ZiraatConfig Ziraat Bankası yapılandırması
type ZiraatConfig struct {
	MerchantID string `json:"merchant_id"`
	TerminalID string `json:"terminal_id"`
	Username   string `json:"username"`
	Password   string `json:"password"`
	BaseURL    string `json:"base_url"`
}

// ZiraatProvider Ziraat Bankası sağlayıcısı
type ZiraatProvider struct {
	config     ZiraatConfig
	httpClient *http.Client
}

// NewZiraatProvider yeni Ziraat sağlayıcısı
func NewZiraatProvider(config ZiraatConfig) *ZiraatProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://eticaret.ziraatbank.com.tr"
	}
	return &ZiraatProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{MinVersion: tls.VersionTLS12},
			},
		},
	}
}

// GetTransactions hesap hareketlerini alır
func (z *ZiraatProvider) GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	// XML request for Ziraat Bank API
	xmlRequest := fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
<GIB_Ekstre>
	<Baslik>
		<KullaniciAdi>%s</KullaniciAdi>
		<Sifre>%s</Sifre>
		<MusteriNo>%s</MusteriNo>
	</Baslik>
	<Detay>
		<HesapNo>%s</HesapNo>
		<BaslangicTarihi>%s</BaslangicTarihi>
		<BitisTarihi>%s</BitisTarihi>
	</Detay>
</GIB_Ekstre>`,
		z.config.Username,
		z.config.Password,
		z.config.MerchantID,
		account.AccountNo,
		startDate.Format("2006-01-02"),
		endDate.Format("2006-01-02"),
	)

	req, err := http.NewRequestWithContext(ctx, "POST", z.config.BaseURL+"/api/ekstre", bytes.NewReader([]byte(xmlRequest)))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/xml")

	resp, err := z.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("ziraat API hatası: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	// Parse XML response
	var transactions []BankTransaction
	// XML parsing logic...
	_ = body

	return transactions, nil
}

// GetBalance bakiye sorgular
func (z *ZiraatProvider) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	return account.Balance, nil
}

// ValidateCredentials kimlik bilgilerini doğrular
func (z *ZiraatProvider) ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error {
	return nil
}

// ===============================================
// GARANTİ BANKASI (GarantiPay)
// ===============================================

// GarantiConfig Garanti Bankası yapılandırması
type GarantiConfig struct {
	MerchantID   string `json:"merchant_id"`
	TerminalID   string `json:"terminal_id"`
	ProvUserID   string `json:"prov_user_id"`
	ProvUserPass string `json:"prov_user_pass"`
	UserID       string `json:"user_id"`
	StoreKey     string `json:"store_key"`
	BaseURL      string `json:"base_url"`
}

// GarantiProvider Garanti Bankası sağlayıcısı
type GarantiProvider struct {
	config     GarantiConfig
	httpClient *http.Client
}

// NewGarantiProvider yeni Garanti sağlayıcısı
func NewGarantiProvider(config GarantiConfig) *GarantiProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://sanalposprov.garanti.com.tr"
	}
	return &GarantiProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GetTransactions hesap hareketlerini alır
func (g *GarantiProvider) GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	// Garanti XML API
	return []BankTransaction{}, nil
}

// GetBalance bakiye sorgular
func (g *GarantiProvider) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	return account.Balance, nil
}

// ValidateCredentials kimlik bilgilerini doğrular
func (g *GarantiProvider) ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error {
	return nil
}

// ===============================================
// AKBANK
// ===============================================

// AkbankConfig Akbank yapılandırması
type AkbankConfig struct {
	ClientID     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	APIKey       string `json:"api_key"`
	BaseURL      string `json:"base_url"`
}

// AkbankProvider Akbank sağlayıcısı
type AkbankProvider struct {
	config     AkbankConfig
	httpClient *http.Client
}

// NewAkbankProvider yeni Akbank sağlayıcısı
func NewAkbankProvider(config AkbankConfig) *AkbankProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://apiselfemp-o.akbank.com"
	}
	return &AkbankProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GetTransactions hesap hareketlerini alır
func (a *AkbankProvider) GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	// Akbank REST API with OAuth2
	return []BankTransaction{}, nil
}

// GetBalance bakiye sorgular
func (a *AkbankProvider) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	return account.Balance, nil
}

// ValidateCredentials kimlik bilgilerini doğrular
func (a *AkbankProvider) ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error {
	return nil
}

// ===============================================
// İŞ BANKASI
// ===============================================

// IsbankConfig İş Bankası yapılandırması
type IsbankConfig struct {
	BranchCode   string `json:"branch_code"`
	CustomerNo   string `json:"customer_no"`
	UserCode     string `json:"user_code"`
	UserPassword string `json:"user_password"`
	BaseURL      string `json:"base_url"`
}

// IsbankProvider İş Bankası sağlayıcısı
type IsbankProvider struct {
	config     IsbankConfig
	httpClient *http.Client
}

// NewIsbankProvider yeni İş Bankası sağlayıcısı
func NewIsbankProvider(config IsbankConfig) *IsbankProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://www.isbank.com.tr/api"
	}
	return &IsbankProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GetTransactions hesap hareketlerini alır
func (i *IsbankProvider) GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	return []BankTransaction{}, nil
}

// GetBalance bakiye sorgular
func (i *IsbankProvider) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	return account.Balance, nil
}

// ValidateCredentials kimlik bilgilerini doğrular
func (i *IsbankProvider) ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error {
	return nil
}

// ===============================================
// YAPI KREDİ
// ===============================================

// YapiKrediConfig Yapı Kredi yapılandırması
type YapiKrediConfig struct {
	MerchantID string `json:"merchant_id"`
	TerminalNo string `json:"terminal_no"`
	PosnetID   string `json:"posnet_id"`
	BaseURL    string `json:"base_url"`
}

// YapiKrediProvider Yapı Kredi sağlayıcısı
type YapiKrediProvider struct {
	config     YapiKrediConfig
	httpClient *http.Client
}

// NewYapiKrediProvider yeni Yapı Kredi sağlayıcısı
func NewYapiKrediProvider(config YapiKrediConfig) *YapiKrediProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://posnet.yapikredi.com.tr"
	}
	return &YapiKrediProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GetTransactions hesap hareketlerini alır
func (y *YapiKrediProvider) GetTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	return []BankTransaction{}, nil
}

// GetBalance bakiye sorgular
func (y *YapiKrediProvider) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	return account.Balance, nil
}

// ValidateCredentials kimlik bilgilerini doğrular
func (y *YapiKrediProvider) ValidateCredentials(ctx context.Context, account *BankAccount, credentials map[string]string) error {
	return nil
}

// ===============================================
// BANKA SERVİSİ
// ===============================================

// BankingService banka servisi
type BankingService struct {
	providers map[BankType]BankProvider
}

// NewBankingService yeni banka servisi oluşturur
func NewBankingService() *BankingService {
	return &BankingService{
		providers: make(map[BankType]BankProvider),
	}
}

// RegisterProvider banka sağlayıcısı kaydeder
func (s *BankingService) RegisterProvider(bankType BankType, provider BankProvider) {
	s.providers[bankType] = provider
}

// SyncTransactions işlemleri senkronize eder
func (s *BankingService) SyncTransactions(ctx context.Context, account *BankAccount, startDate, endDate time.Time) ([]BankTransaction, error) {
	provider, ok := s.providers[account.Bank]
	if !ok {
		return nil, fmt.Errorf("banka sağlayıcısı bulunamadı: %s", account.Bank)
	}
	return provider.GetTransactions(ctx, account, startDate, endDate)
}

// GetBalance bakiye sorgular
func (s *BankingService) GetBalance(ctx context.Context, account *BankAccount) (float64, error) {
	provider, ok := s.providers[account.Bank]
	if !ok {
		return 0, fmt.Errorf("banka sağlayıcısı bulunamadı: %s", account.Bank)
	}
	return provider.GetBalance(ctx, account)
}

// ===============================================
// OTOMATİK EŞLEŞTİRME SERVİSİ
// ===============================================

// AutoMatchService otomatik eşleştirme servisi
type AutoMatchService struct{}

// NewAutoMatchService yeni eşleştirme servisi
func NewAutoMatchService() *AutoMatchService {
	return &AutoMatchService{}
}

// MatchTransaction işlemi eşleştirir
func (a *AutoMatchService) MatchTransaction(ctx context.Context, transaction *BankTransaction, residents []ResidentDues) *MatchResult {
	result := &MatchResult{
		TransactionID: transaction.ID,
		Status:        MatchPending,
	}

	// 1. IBAN eşleştirme (en yüksek güven)
	for _, r := range residents {
		if transaction.SenderIBAN != "" && r.ResidentIBAN == transaction.SenderIBAN {
			result.Status = MatchMatched
			result.DuesID = r.DuesID
			result.ResidentID = r.ResidentID
			result.ResidentName = r.ResidentName
			result.UnitNo = r.UnitNo
			result.Confidence = 0.99
			result.MatchReason = "IBAN eşleşmesi"
			return result
		}
	}

	// 2. İsim + Tutar eşleştirme
	for _, r := range residents {
		nameMatch := containsName(transaction.Description, r.ResidentName)
		amountMatch := isAmountClose(transaction.Amount, r.PendingAmount, 0.01)

		if nameMatch && amountMatch {
			result.Status = MatchMatched
			result.DuesID = r.DuesID
			result.ResidentID = r.ResidentID
			result.ResidentName = r.ResidentName
			result.UnitNo = r.UnitNo
			result.Confidence = 0.90
			result.MatchReason = "İsim ve tutar eşleşmesi"
			return result
		}
	}

	// 3. Tutar eşleştirme (güven düşük, öneri olarak)
	var suggestions []SuggestedMatch
	for _, r := range residents {
		if isAmountClose(transaction.Amount, r.PendingAmount, 0.01) {
			suggestions = append(suggestions, SuggestedMatch{
				DuesID:       r.DuesID,
				ResidentID:   r.ResidentID,
				ResidentName: r.ResidentName,
				UnitNo:       r.UnitNo,
				Amount:       r.PendingAmount,
				DueDate:      r.DueDate,
				Confidence:   0.60,
				Reason:       "Tutar eşleşmesi",
			})
		}
	}

	// 4. Daire no araştırma
	for _, r := range residents {
		if containsUnitNo(transaction.Description, r.UnitNo) {
			suggestions = append(suggestions, SuggestedMatch{
				DuesID:       r.DuesID,
				ResidentID:   r.ResidentID,
				ResidentName: r.ResidentName,
				UnitNo:       r.UnitNo,
				Amount:       r.PendingAmount,
				DueDate:      r.DueDate,
				Confidence:   0.70,
				Reason:       "Daire numarası eşleşmesi",
			})
		}
	}

	if len(suggestions) > 0 {
		result.SuggestedMatch = suggestions
		result.Status = MatchPending
	}

	return result
}

// ResidentDues sakin borç bilgisi
type ResidentDues struct {
	ResidentID    string  `json:"resident_id"`
	ResidentName  string  `json:"resident_name"`
	ResidentIBAN  string  `json:"resident_iban"`
	UnitNo        string  `json:"unit_no"`
	DuesID        string  `json:"dues_id"`
	PendingAmount float64 `json:"pending_amount"`
	DueDate       string  `json:"due_date"`
}

// Helper functions
func containsName(text, name string) bool {
	// İsim kontrolü
	return false
}

func containsUnitNo(text, unitNo string) bool {
	// Daire no kontrolü
	return false
}

func isAmountClose(a, b, tolerance float64) bool {
	diff := a - b
	if diff < 0 {
		diff = -diff
	}
	return diff <= tolerance
}
