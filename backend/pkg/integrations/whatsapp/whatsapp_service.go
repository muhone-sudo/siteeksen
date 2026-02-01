package whatsapp

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// MessageType mesaj türü
type MessageType string

const (
	MessageTypeText     MessageType = "text"
	MessageTypeTemplate MessageType = "template"
	MessageTypeImage    MessageType = "image"
	MessageTypeDocument MessageType = "document"
)

// TemplateType şablon türü
type TemplateType string

const (
	TemplateDuesReminder       TemplateType = "aidat_hatirlatma"
	TemplateVisitorNotify      TemplateType = "ziyaretci_bildirim"
	TemplatePackageArrived     TemplateType = "kargo_geldi"
	TemplateAnnouncement       TemplateType = "duyuru"
	TemplateMaintenanceAlert   TemplateType = "bakim_bildirimi"
	TemplatePaymentConfirm     TemplateType = "odeme_onay"
	TemplateReservationConfirm TemplateType = "rezervasyon_onay"
)

// WhatsAppConfig WhatsApp Business API yapılandırması
type WhatsAppConfig struct {
	AccessToken       string `json:"access_token"`
	PhoneNumberID     string `json:"phone_number_id"`
	BusinessAccountID string `json:"business_account_id"`
	WebhookToken      string `json:"webhook_token"`
	BaseURL           string `json:"base_url"`
}

// Message mesaj yapısı
type Message struct {
	ID        string           `json:"id,omitempty"`
	To        string           `json:"to"`
	Type      MessageType      `json:"type"`
	Text      *TextContent     `json:"text,omitempty"`
	Template  *TemplateContent `json:"template,omitempty"`
	Image     *MediaContent    `json:"image,omitempty"`
	Document  *MediaContent    `json:"document,omitempty"`
	Timestamp time.Time        `json:"timestamp"`
}

// TextContent metin içeriği
type TextContent struct {
	Body       string `json:"body"`
	PreviewURL bool   `json:"preview_url,omitempty"`
}

// TemplateContent şablon içeriği
type TemplateContent struct {
	Name       string              `json:"name"`
	Language   TemplateLanguage    `json:"language"`
	Components []TemplateComponent `json:"components,omitempty"`
}

// TemplateLanguage şablon dili
type TemplateLanguage struct {
	Code string `json:"code"`
}

// TemplateComponent şablon bileşeni
type TemplateComponent struct {
	Type       string              `json:"type"`
	Parameters []TemplateParameter `json:"parameters,omitempty"`
}

// TemplateParameter şablon parametresi
type TemplateParameter struct {
	Type     string         `json:"type"`
	Text     string         `json:"text,omitempty"`
	Currency *CurrencyParam `json:"currency,omitempty"`
	DateTime *DateTimeParam `json:"date_time,omitempty"`
}

// CurrencyParam para birimi parametresi
type CurrencyParam struct {
	FallbackValue string `json:"fallback_value"`
	Code          string `json:"code"`
	Amount1000    int64  `json:"amount_1000"`
}

// DateTimeParam tarih parametresi
type DateTimeParam struct {
	FallbackValue string `json:"fallback_value"`
}

// SendResult gönderim sonucu
type SendResult struct {
	Success   bool      `json:"success"`
	MessageID string    `json:"message_id,omitempty"`
	Error     string    `json:"error,omitempty"`
	ErrorCode string    `json:"error_code,omitempty"`
	SentAt    time.Time `json:"sent_at,omitempty"`
}

// DeliveryStatus teslimat durumu
type DeliveryStatus struct {
	MessageID   string    `json:"message_id"`
	Status      string    `json:"status"` // sent, delivered, read, failed
	Timestamp   time.Time `json:"timestamp"`
	RecipientID string    `json:"recipient_id"`
}

// ===============================================
// WHATSAPP SERVİSİ
// ===============================================

// Service WhatsApp servisi
type Service struct {
	config     WhatsAppConfig
	httpClient *http.Client
	templates  map[TemplateType]string
}

// NewService yeni servis oluşturur
func NewService(config WhatsAppConfig) *Service {
	if config.BaseURL == "" {
		config.BaseURL = "https://graph.facebook.com/v18.0"
	}

	s := &Service{
		config: config,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		templates: make(map[TemplateType]string),
	}

	// Varsayılan şablonları yükle
	s.registerDefaultTemplates()

	return s
}

// registerDefaultTemplates varsayılan şablonları kaydeder
func (s *Service) registerDefaultTemplates() {
	s.templates[TemplateDuesReminder] = "aidat_hatirlatma"
	s.templates[TemplateVisitorNotify] = "ziyaretci_bildirim"
	s.templates[TemplatePackageArrived] = "kargo_geldi"
	s.templates[TemplateAnnouncement] = "duyuru"
	s.templates[TemplateMaintenanceAlert] = "bakim_bildirimi"
	s.templates[TemplatePaymentConfirm] = "odeme_onay"
	s.templates[TemplateReservationConfirm] = "rezervasyon_onay"
}

// SendText metin mesajı gönderir
func (s *Service) SendText(ctx context.Context, to, message string) (*SendResult, error) {
	payload := map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                s.normalizePhone(to),
		"type":              "text",
		"text": map[string]interface{}{
			"preview_url": false,
			"body":        message,
		},
	}

	return s.send(ctx, payload)
}

// SendTemplate şablon mesajı gönderir
func (s *Service) SendTemplate(ctx context.Context, to string, templateType TemplateType, params map[string]string) (*SendResult, error) {
	templateName, ok := s.templates[templateType]
	if !ok {
		return nil, fmt.Errorf("şablon bulunamadı: %s", templateType)
	}

	// Parametreleri hazırla
	var components []map[string]interface{}
	if len(params) > 0 {
		var parameters []map[string]interface{}
		for _, value := range params {
			parameters = append(parameters, map[string]interface{}{
				"type": "text",
				"text": value,
			})
		}
		components = append(components, map[string]interface{}{
			"type":       "body",
			"parameters": parameters,
		})
	}

	payload := map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                s.normalizePhone(to),
		"type":              "template",
		"template": map[string]interface{}{
			"name": templateName,
			"language": map[string]string{
				"code": "tr",
			},
			"components": components,
		},
	}

	return s.send(ctx, payload)
}

// SendDuesReminder aidat hatırlatması gönderir
func (s *Service) SendDuesReminder(ctx context.Context, to, residentName, amount, dueDate string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplateDuesReminder, map[string]string{
		"1": residentName,
		"2": amount,
		"3": dueDate,
	})
}

// SendVisitorNotification ziyaretçi bildirimi gönderir
func (s *Service) SendVisitorNotification(ctx context.Context, to, visitorName, visitorPurpose, arrivalTime string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplateVisitorNotify, map[string]string{
		"1": visitorName,
		"2": visitorPurpose,
		"3": arrivalTime,
	})
}

// SendPackageNotification kargo bildirimi gönderir
func (s *Service) SendPackageNotification(ctx context.Context, to, carrierName, trackingNo string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplatePackageArrived, map[string]string{
		"1": carrierName,
		"2": trackingNo,
	})
}

// SendAnnouncement duyuru gönderir
func (s *Service) SendAnnouncement(ctx context.Context, to, title, summary string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplateAnnouncement, map[string]string{
		"1": title,
		"2": summary,
	})
}

// SendPaymentConfirmation ödeme onayı gönderir
func (s *Service) SendPaymentConfirmation(ctx context.Context, to, amount, paymentDate, receiptNo string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplatePaymentConfirm, map[string]string{
		"1": amount,
		"2": paymentDate,
		"3": receiptNo,
	})
}

// SendReservationConfirmation rezervasyon onayı gönderir
func (s *Service) SendReservationConfirmation(ctx context.Context, to, facilityName, reservationDate, timeSlot string) (*SendResult, error) {
	return s.SendTemplate(ctx, to, TemplateReservationConfirm, map[string]string{
		"1": facilityName,
		"2": reservationDate,
		"3": timeSlot,
	})
}

// SendImage resim gönderir
func (s *Service) SendImage(ctx context.Context, to, imageURL, caption string) (*SendResult, error) {
	payload := map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                s.normalizePhone(to),
		"type":              "image",
		"image": map[string]interface{}{
			"link":    imageURL,
			"caption": caption,
		},
	}

	return s.send(ctx, payload)
}

// SendDocument döküman gönderir
func (s *Service) SendDocument(ctx context.Context, to, documentURL, filename, caption string) (*SendResult, error) {
	payload := map[string]interface{}{
		"messaging_product": "whatsapp",
		"recipient_type":    "individual",
		"to":                s.normalizePhone(to),
		"type":              "document",
		"document": map[string]interface{}{
			"link":     documentURL,
			"filename": filename,
			"caption":  caption,
		},
	}

	return s.send(ctx, payload)
}

// send mesaj gönderir
func (s *Service) send(ctx context.Context, payload map[string]interface{}) (*SendResult, error) {
	jsonBody, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s/%s/messages", s.config.BaseURL, s.config.PhoneNumberID)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.config.AccessToken)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("WhatsApp API hatası: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	var result map[string]interface{}
	json.Unmarshal(body, &result)

	if resp.StatusCode != 200 {
		errorMsg := "Bilinmeyen hata"
		if errObj, ok := result["error"].(map[string]interface{}); ok {
			if msg, ok := errObj["message"].(string); ok {
				errorMsg = msg
			}
		}
		return &SendResult{
			Success:   false,
			Error:     errorMsg,
			ErrorCode: fmt.Sprintf("%d", resp.StatusCode),
		}, nil
	}

	// Başarılı yanıt
	messageID := ""
	if messages, ok := result["messages"].([]interface{}); ok && len(messages) > 0 {
		if msg, ok := messages[0].(map[string]interface{}); ok {
			if id, ok := msg["id"].(string); ok {
				messageID = id
			}
		}
	}

	return &SendResult{
		Success:   true,
		MessageID: messageID,
		SentAt:    time.Now(),
	}, nil
}

// normalizePhone telefon numarasını normalleştirir
func (s *Service) normalizePhone(phone string) string {
	// Türkiye formatına dönüştür
	phone = removeNonDigits(phone)

	if len(phone) == 10 && phone[0] == '5' {
		phone = "90" + phone
	} else if len(phone) == 11 && phone[0] == '0' {
		phone = "9" + phone
	}

	return phone
}

func removeNonDigits(s string) string {
	result := ""
	for _, c := range s {
		if c >= '0' && c <= '9' {
			result += string(c)
		}
	}
	return result
}

// ===============================================
// WEBHOOK HANDLER
// ===============================================

// WebhookHandler webhook işleyici
type WebhookHandler struct {
	service        *Service
	statusCallback func(status *DeliveryStatus)
}

// NewWebhookHandler yeni webhook handler oluşturur
func NewWebhookHandler(service *Service, callback func(*DeliveryStatus)) *WebhookHandler {
	return &WebhookHandler{
		service:        service,
		statusCallback: callback,
	}
}

// VerifyWebhook webhook doğrulama
func (w *WebhookHandler) VerifyWebhook(mode, token, challenge string) (string, bool) {
	if mode == "subscribe" && token == w.service.config.WebhookToken {
		return challenge, true
	}
	return "", false
}

// HandleWebhook webhook işleme
func (w *WebhookHandler) HandleWebhook(payload []byte) error {
	var data map[string]interface{}
	if err := json.Unmarshal(payload, &data); err != nil {
		return err
	}

	// Status değişikliklerini işle
	if entry, ok := data["entry"].([]interface{}); ok && len(entry) > 0 {
		if changes, ok := entry[0].(map[string]interface{})["changes"].([]interface{}); ok {
			for _, change := range changes {
				if changeObj, ok := change.(map[string]interface{}); ok {
					if value, ok := changeObj["value"].(map[string]interface{}); ok {
						if statuses, ok := value["statuses"].([]interface{}); ok {
							for _, status := range statuses {
								if statusObj, ok := status.(map[string]interface{}); ok {
									ds := &DeliveryStatus{
										MessageID:   fmt.Sprintf("%v", statusObj["id"]),
										Status:      fmt.Sprintf("%v", statusObj["status"]),
										RecipientID: fmt.Sprintf("%v", statusObj["recipient_id"]),
										Timestamp:   time.Now(),
									}
									if w.statusCallback != nil {
										w.statusCallback(ds)
									}
								}
							}
						}
					}
				}
			}
		}
	}

	return nil
}

// ===============================================
// BULK MESSAGE SERVİSİ
// ===============================================

// BulkService toplu mesaj servisi
type BulkService struct {
	service   *Service
	rateLimit int // mesaj/dakika
}

// NewBulkService yeni toplu mesaj servisi
func NewBulkService(service *Service, rateLimit int) *BulkService {
	if rateLimit <= 0 {
		rateLimit = 80 // Meta rate limit: ~80 mesaj/dakika
	}
	return &BulkService{
		service:   service,
		rateLimit: rateLimit,
	}
}

// SendBulkTemplate toplu şablon mesajı gönderir
func (b *BulkService) SendBulkTemplate(ctx context.Context, recipients []string, templateType TemplateType, paramsFunc func(recipient string) map[string]string) []*SendResult {
	results := make([]*SendResult, len(recipients))
	interval := time.Minute / time.Duration(b.rateLimit)

	for i, recipient := range recipients {
		params := paramsFunc(recipient)
		result, err := b.service.SendTemplate(ctx, recipient, templateType, params)
		if err != nil {
			results[i] = &SendResult{Success: false, Error: err.Error()}
		} else {
			results[i] = result
		}

		// Rate limiting
		if i < len(recipients)-1 {
			time.Sleep(interval)
		}
	}

	return results
}

// SendBulkDuesReminder toplu aidat hatırlatması
func (b *BulkService) SendBulkDuesReminder(ctx context.Context, reminders []DuesReminderData) []*SendResult {
	results := make([]*SendResult, len(reminders))
	interval := time.Minute / time.Duration(b.rateLimit)

	for i, r := range reminders {
		result, err := b.service.SendDuesReminder(ctx, r.Phone, r.ResidentName, r.Amount, r.DueDate)
		if err != nil {
			results[i] = &SendResult{Success: false, Error: err.Error()}
		} else {
			results[i] = result
		}

		if i < len(reminders)-1 {
			time.Sleep(interval)
		}
	}

	return results
}

// DuesReminderData aidat hatırlatma verisi
type DuesReminderData struct {
	Phone        string `json:"phone"`
	ResidentName string `json:"resident_name"`
	Amount       string `json:"amount"`
	DueDate      string `json:"due_date"`
}
