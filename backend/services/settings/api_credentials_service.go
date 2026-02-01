package settings

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"os"
	"time"
)

// ServiceCategory API servis kategorisi
type ServiceCategory string

const (
	CategoryMessaging ServiceCategory = "messaging"
	CategoryBanking   ServiceCategory = "banking"
	CategoryPayment   ServiceCategory = "payment"
	CategoryAI        ServiceCategory = "ai"
	CategoryPush      ServiceCategory = "push"
)

// ServiceName servis adı
type ServiceName string

const (
	// Messaging
	ServiceWhatsApp     ServiceName = "whatsapp"
	ServiceNetgsm       ServiceName = "netgsm"
	ServiceIletiMerkezi ServiceName = "ileti_merkezi"
	// Banking
	ServiceZiraat    ServiceName = "ziraat_bank"
	ServiceGaranti   ServiceName = "garanti_bank"
	ServiceAkbank    ServiceName = "akbank"
	ServiceIsBankasi ServiceName = "is_bankasi"
	ServiceYapiKredi ServiceName = "yapi_kredi"
	// Payment
	ServiceIyzico ServiceName = "iyzico"
	// AI
	ServiceOpenAI  ServiceName = "openai"
	ServiceGemini  ServiceName = "gemini"
	ServiceWhisper ServiceName = "whisper"
	// Push
	ServiceFCM ServiceName = "firebase_fcm"
)

// APICredential API kimlik bilgisi
type APICredential struct {
	ID           string            `json:"id"`
	ServiceName  ServiceName       `json:"service_name"`
	DisplayName  string            `json:"display_name"`
	Category     ServiceCategory   `json:"category"`
	APIKey       string            `json:"api_key,omitempty"`      // Şifreli
	APISecret    string            `json:"api_secret,omitempty"`   // Şifreli
	ExtraConfig  map[string]string `json:"extra_config,omitempty"` // Şifreli
	IsActive     bool              `json:"is_active"`
	LastTestAt   *time.Time        `json:"last_test_at,omitempty"`
	TestStatus   string            `json:"test_status,omitempty"` // success, failed, pending
	CreatedAt    time.Time         `json:"created_at"`
	LastModified time.Time         `json:"last_modified"`
	ModifiedBy   string            `json:"modified_by"`
}

// MaskedCredential maskelenmiş kimlik bilgisi (UI için)
type MaskedCredential struct {
	ID           string          `json:"id"`
	ServiceName  ServiceName     `json:"service_name"`
	DisplayName  string          `json:"display_name"`
	Category     ServiceCategory `json:"category"`
	APIKeyMasked string          `json:"api_key_masked"`
	HasSecret    bool            `json:"has_secret"`
	ExtraFields  []string        `json:"extra_fields,omitempty"`
	IsActive     bool            `json:"is_active"`
	LastTestAt   *time.Time      `json:"last_test_at,omitempty"`
	TestStatus   string          `json:"test_status,omitempty"`
	LastModified time.Time       `json:"last_modified"`
	ModifiedBy   string          `json:"modified_by"`
}

// AuditLogEntry değişiklik kaydı
type AuditLogEntry struct {
	ID           string    `json:"id"`
	CredentialID string    `json:"credential_id"`
	Action       string    `json:"action"` // create, update, delete, test
	Field        string    `json:"field,omitempty"`
	OldValue     string    `json:"old_value,omitempty"` // Maskelenmiş
	NewValue     string    `json:"new_value,omitempty"` // Maskelenmiş
	UserID       string    `json:"user_id"`
	UserName     string    `json:"user_name"`
	IPAddress    string    `json:"ip_address"`
	Timestamp    time.Time `json:"timestamp"`
}

// CreateRequest oluşturma isteği
type CreateRequest struct {
	ServiceName ServiceName       `json:"service_name" validate:"required"`
	APIKey      string            `json:"api_key" validate:"required"`
	APISecret   string            `json:"api_secret,omitempty"`
	ExtraConfig map[string]string `json:"extra_config,omitempty"`
	IsActive    bool              `json:"is_active"`
}

// UpdateRequest güncelleme isteği
type UpdateRequest struct {
	APIKey      *string           `json:"api_key,omitempty"`
	APISecret   *string           `json:"api_secret,omitempty"`
	ExtraConfig map[string]string `json:"extra_config,omitempty"`
	IsActive    *bool             `json:"is_active,omitempty"`
}

// TestResult test sonucu
type TestResult struct {
	Success    bool      `json:"success"`
	Message    string    `json:"message"`
	ResponseMs int64     `json:"response_ms"`
	TestedAt   time.Time `json:"tested_at"`
}

// ===============================================
// API CREDENTIALS SERVİSİ
// ===============================================

// Service API credentials servisi
type Service struct {
	encryptionKey []byte
	// db connection would go here
}

// NewService yeni servis oluşturur
func NewService() (*Service, error) {
	keyStr := os.Getenv("API_CREDENTIALS_ENCRYPTION_KEY")
	if keyStr == "" {
		// Geliştirme ortamı için varsayılan anahtar (üretimde kullanılmamalı!)
		keyStr = "sitesen-dev-key-32-bytes-long!!"
	}

	key := []byte(keyStr)
	if len(key) != 32 {
		return nil, errors.New("şifreleme anahtarı 32 byte olmalıdır (AES-256)")
	}

	return &Service{
		encryptionKey: key,
	}, nil
}

// ===============================================
// CRUD İŞLEMLERİ
// ===============================================

// Create yeni credential oluşturur
func (s *Service) Create(ctx context.Context, req *CreateRequest, userID, userName, ipAddress string) (*APICredential, error) {
	// Şifrele
	encryptedKey, err := s.encrypt(req.APIKey)
	if err != nil {
		return nil, fmt.Errorf("anahtar şifreleme hatası: %w", err)
	}

	var encryptedSecret string
	if req.APISecret != "" {
		encryptedSecret, err = s.encrypt(req.APISecret)
		if err != nil {
			return nil, fmt.Errorf("secret şifreleme hatası: %w", err)
		}
	}

	// Extra config'i şifrele
	encryptedExtra := make(map[string]string)
	for k, v := range req.ExtraConfig {
		encrypted, err := s.encrypt(v)
		if err != nil {
			return nil, fmt.Errorf("extra config şifreleme hatası: %w", err)
		}
		encryptedExtra[k] = encrypted
	}

	cred := &APICredential{
		ID:           generateID(),
		ServiceName:  req.ServiceName,
		DisplayName:  getDisplayName(req.ServiceName),
		Category:     getCategory(req.ServiceName),
		APIKey:       encryptedKey,
		APISecret:    encryptedSecret,
		ExtraConfig:  encryptedExtra,
		IsActive:     req.IsActive,
		CreatedAt:    time.Now(),
		LastModified: time.Now(),
		ModifiedBy:   userName,
	}

	// Audit log
	s.logAudit(ctx, &AuditLogEntry{
		CredentialID: cred.ID,
		Action:       "create",
		UserID:       userID,
		UserName:     userName,
		IPAddress:    ipAddress,
		Timestamp:    time.Now(),
	})

	// TODO: Veritabanına kaydet

	return cred, nil
}

// Update credential günceller
func (s *Service) Update(ctx context.Context, id string, req *UpdateRequest, userID, userName, ipAddress string) (*APICredential, error) {
	// TODO: Veritabanından mevcut kaydı al
	existing := &APICredential{ID: id} // Placeholder

	changes := []AuditLogEntry{}

	if req.APIKey != nil && *req.APIKey != "" {
		encryptedKey, err := s.encrypt(*req.APIKey)
		if err != nil {
			return nil, err
		}
		changes = append(changes, AuditLogEntry{
			CredentialID: id,
			Action:       "update",
			Field:        "api_key",
			OldValue:     s.mask(existing.APIKey),
			NewValue:     s.mask(*req.APIKey),
			UserID:       userID,
			UserName:     userName,
			IPAddress:    ipAddress,
			Timestamp:    time.Now(),
		})
		existing.APIKey = encryptedKey
	}

	if req.APISecret != nil && *req.APISecret != "" {
		encryptedSecret, err := s.encrypt(*req.APISecret)
		if err != nil {
			return nil, err
		}
		changes = append(changes, AuditLogEntry{
			CredentialID: id,
			Action:       "update",
			Field:        "api_secret",
			OldValue:     "••••••••",
			NewValue:     "••••••••",
			UserID:       userID,
			UserName:     userName,
			IPAddress:    ipAddress,
			Timestamp:    time.Now(),
		})
		existing.APISecret = encryptedSecret
	}

	if req.IsActive != nil {
		changes = append(changes, AuditLogEntry{
			CredentialID: id,
			Action:       "update",
			Field:        "is_active",
			OldValue:     fmt.Sprintf("%v", existing.IsActive),
			NewValue:     fmt.Sprintf("%v", *req.IsActive),
			UserID:       userID,
			UserName:     userName,
			IPAddress:    ipAddress,
			Timestamp:    time.Now(),
		})
		existing.IsActive = *req.IsActive
	}

	existing.LastModified = time.Now()
	existing.ModifiedBy = userName

	// Audit logları kaydet
	for _, entry := range changes {
		s.logAudit(ctx, &entry)
	}

	// TODO: Veritabanına kaydet

	return existing, nil
}

// Delete credential siler
func (s *Service) Delete(ctx context.Context, id string, userID, userName, ipAddress string) error {
	s.logAudit(ctx, &AuditLogEntry{
		CredentialID: id,
		Action:       "delete",
		UserID:       userID,
		UserName:     userName,
		IPAddress:    ipAddress,
		Timestamp:    time.Now(),
	})

	// TODO: Veritabanından sil

	return nil
}

// GetAll tüm credentialları getirir (maskelenmiş)
func (s *Service) GetAll(ctx context.Context) ([]MaskedCredential, error) {
	// TODO: Veritabanından al

	// Demo data
	return []MaskedCredential{
		{
			ID:           "1",
			ServiceName:  ServiceWhatsApp,
			DisplayName:  "WhatsApp Business API",
			Category:     CategoryMessaging,
			APIKeyMasked: "••••••••abc123",
			HasSecret:    true,
			ExtraFields:  []string{"phone_number_id", "business_account_id"},
			IsActive:     true,
			TestStatus:   "success",
			LastModified: time.Now().Add(-24 * time.Hour),
			ModifiedBy:   "admin",
		},
		{
			ID:           "2",
			ServiceName:  ServiceZiraat,
			DisplayName:  "Ziraat Bankası API",
			Category:     CategoryBanking,
			APIKeyMasked: "••••••••xyz789",
			HasSecret:    true,
			ExtraFields:  []string{"client_id", "iban"},
			IsActive:     true,
			TestStatus:   "success",
			LastModified: time.Now().Add(-48 * time.Hour),
			ModifiedBy:   "admin",
		},
		{
			ID:           "3",
			ServiceName:  ServiceIyzico,
			DisplayName:  "Iyzico Ödeme",
			Category:     CategoryPayment,
			APIKeyMasked: "••••••••pay456",
			HasSecret:    true,
			IsActive:     true,
			TestStatus:   "pending",
			LastModified: time.Now().Add(-72 * time.Hour),
			ModifiedBy:   "admin",
		},
		{
			ID:           "4",
			ServiceName:  ServiceOpenAI,
			DisplayName:  "OpenAI API",
			Category:     CategoryAI,
			APIKeyMasked: "••••••••sk-abc",
			HasSecret:    false,
			IsActive:     true,
			TestStatus:   "success",
			LastModified: time.Now().Add(-96 * time.Hour),
			ModifiedBy:   "admin",
		},
	}, nil
}

// GetByID tek credential getirir (maskelenmiş)
func (s *Service) GetByID(ctx context.Context, id string) (*MaskedCredential, error) {
	// TODO: Veritabanından al
	return nil, nil
}

// GetDecrypted şifresi çözülmüş credential getirir (dikkatli kullanılmalı!)
func (s *Service) GetDecrypted(ctx context.Context, id string) (*APICredential, error) {
	// TODO: Veritabanından al ve şifre çöz
	return nil, nil
}

// ===============================================
// TEST İŞLEMLERİ
// ===============================================

// TestConnection servis bağlantısını test eder
func (s *Service) TestConnection(ctx context.Context, id string, userID, userName, ipAddress string) (*TestResult, error) {
	// TODO: Credential'ı al ve decrypt et
	// TODO: Servise göre test yap

	start := time.Now()

	// Simulated test
	result := &TestResult{
		Success:    true,
		Message:    "Bağlantı başarılı",
		ResponseMs: time.Since(start).Milliseconds(),
		TestedAt:   time.Now(),
	}

	// Audit log
	s.logAudit(ctx, &AuditLogEntry{
		CredentialID: id,
		Action:       "test",
		UserID:       userID,
		UserName:     userName,
		IPAddress:    ipAddress,
		Timestamp:    time.Now(),
	})

	return result, nil
}

// ===============================================
// AUDIT LOG
// ===============================================

// GetAuditLog credential için audit log getirir
func (s *Service) GetAuditLog(ctx context.Context, credentialID string, limit int) ([]AuditLogEntry, error) {
	// TODO: Veritabanından al

	// Demo data
	return []AuditLogEntry{
		{
			ID:           "1",
			CredentialID: credentialID,
			Action:       "update",
			Field:        "api_key",
			OldValue:     "••••••••old123",
			NewValue:     "••••••••new456",
			UserID:       "1",
			UserName:     "admin",
			IPAddress:    "192.168.1.100",
			Timestamp:    time.Now().Add(-2 * time.Hour),
		},
		{
			ID:           "2",
			CredentialID: credentialID,
			Action:       "test",
			UserID:       "1",
			UserName:     "admin",
			IPAddress:    "192.168.1.100",
			Timestamp:    time.Now().Add(-1 * time.Hour),
		},
	}, nil
}

func (s *Service) logAudit(ctx context.Context, entry *AuditLogEntry) {
	entry.ID = generateID()
	// TODO: Veritabanına kaydet
}

// ===============================================
// ŞİFRELEME
// ===============================================

// encrypt AES-256-GCM ile şifreler
func (s *Service) encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(s.encryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.StdEncoding.EncodeToString(ciphertext), nil
}

// decrypt AES-256-GCM ile şifre çözer
func (s *Service) decrypt(ciphertext string) (string, error) {
	data, err := base64.StdEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", err
	}

	block, err := aes.NewCipher(s.encryptionKey)
	if err != nil {
		return "", err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", errors.New("ciphertext çok kısa")
	}

	nonce, cipherBytes := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, cipherBytes, nil)
	if err != nil {
		return "", err
	}

	return string(plaintext), nil
}

// mask değeri maskeler
func (s *Service) mask(value string) string {
	if len(value) <= 6 {
		return "••••••••"
	}
	return "••••••••" + value[len(value)-6:]
}

// ===============================================
// YARDIMCI FONKSİYONLAR
// ===============================================

func generateID() string {
	b := make([]byte, 8)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}

func getDisplayName(service ServiceName) string {
	names := map[ServiceName]string{
		ServiceWhatsApp:     "WhatsApp Business API",
		ServiceNetgsm:       "Netgsm SMS",
		ServiceIletiMerkezi: "İleti Merkezi SMS",
		ServiceZiraat:       "Ziraat Bankası",
		ServiceGaranti:      "Garanti BBVA",
		ServiceAkbank:       "Akbank",
		ServiceIsBankasi:    "İş Bankası",
		ServiceYapiKredi:    "Yapı Kredi",
		ServiceIyzico:       "Iyzico Ödeme",
		ServiceOpenAI:       "OpenAI API",
		ServiceGemini:       "Google Gemini",
		ServiceWhisper:      "OpenAI Whisper",
		ServiceFCM:          "Firebase Cloud Messaging",
	}
	if name, ok := names[service]; ok {
		return name
	}
	return string(service)
}

func getCategory(service ServiceName) ServiceCategory {
	switch service {
	case ServiceWhatsApp, ServiceNetgsm, ServiceIletiMerkezi:
		return CategoryMessaging
	case ServiceZiraat, ServiceGaranti, ServiceAkbank, ServiceIsBankasi, ServiceYapiKredi:
		return CategoryBanking
	case ServiceIyzico:
		return CategoryPayment
	case ServiceOpenAI, ServiceGemini, ServiceWhisper:
		return CategoryAI
	case ServiceFCM:
		return CategoryPush
	default:
		return CategoryMessaging
	}
}

// GetAvailableServices yapılandırılabilir servisleri döner
func GetAvailableServices() []struct {
	Name        ServiceName     `json:"name"`
	DisplayName string          `json:"display_name"`
	Category    ServiceCategory `json:"category"`
	Fields      []string        `json:"fields"`
} {
	return []struct {
		Name        ServiceName     `json:"name"`
		DisplayName string          `json:"display_name"`
		Category    ServiceCategory `json:"category"`
		Fields      []string        `json:"fields"`
	}{
		{ServiceWhatsApp, "WhatsApp Business API", CategoryMessaging, []string{"access_token", "phone_number_id", "business_account_id", "webhook_token"}},
		{ServiceNetgsm, "Netgsm SMS", CategoryMessaging, []string{"username", "password", "header"}},
		{ServiceIletiMerkezi, "İleti Merkezi SMS", CategoryMessaging, []string{"api_key", "sender"}},
		{ServiceZiraat, "Ziraat Bankası", CategoryBanking, []string{"client_id", "client_secret", "iban"}},
		{ServiceGaranti, "Garanti BBVA", CategoryBanking, []string{"api_key", "api_secret", "merchant_id"}},
		{ServiceAkbank, "Akbank", CategoryBanking, []string{"client_id", "client_secret", "iban"}},
		{ServiceIsBankasi, "İş Bankası", CategoryBanking, []string{"api_key", "api_secret", "customer_no"}},
		{ServiceYapiKredi, "Yapı Kredi", CategoryBanking, []string{"client_id", "client_secret", "iban"}},
		{ServiceIyzico, "Iyzico Ödeme", CategoryPayment, []string{"api_key", "secret_key", "base_url"}},
		{ServiceOpenAI, "OpenAI API", CategoryAI, []string{"api_key"}},
		{ServiceGemini, "Google Gemini", CategoryAI, []string{"api_key"}},
		{ServiceWhisper, "OpenAI Whisper", CategoryAI, []string{"api_key"}},
		{ServiceFCM, "Firebase Cloud Messaging", CategoryPush, []string{"server_key", "project_id"}},
	}
}
