package push

import (
	"context"
	"fmt"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// NotificationType bildirim türü
type NotificationType string

const (
	NotificationTypeAnnouncement NotificationType = "announcement"
	NotificationTypePayment      NotificationType = "payment"
	NotificationTypeVisitor      NotificationType = "visitor"
	NotificationTypePackage      NotificationType = "package"
	NotificationTypeRequest      NotificationType = "request"
	NotificationTypeAlert        NotificationType = "alert"
)

// Notification bildirim yapısı
type Notification struct {
	ID        string            `json:"id"`
	Title     string            `json:"title"`
	Body      string            `json:"body"`
	Type      NotificationType  `json:"type"`
	Data      map[string]string `json:"data,omitempty"`
	ImageURL  string            `json:"image_url,omitempty"`
	Badge     int               `json:"badge,omitempty"`
	Sound     string            `json:"sound,omitempty"`
	Priority  string            `json:"priority,omitempty"`
	CreatedAt time.Time         `json:"created_at"`
}

// SendResult gönderim sonucu
type SendResult struct {
	Success      bool   `json:"success"`
	MessageID    string `json:"message_id,omitempty"`
	Error        string `json:"error,omitempty"`
	FailureCount int    `json:"failure_count,omitempty"`
	SuccessCount int    `json:"success_count,omitempty"`
}

// ===============================================
// FIREBASE CLOUD MESSAGING SERVİSİ
// ===============================================

// FirebaseConfig Firebase yapılandırması
type FirebaseConfig struct {
	ProjectID       string `json:"project_id"`
	CredentialsFile string `json:"credentials_file"`
	CredentialsJSON []byte `json:"credentials_json,omitempty"`
}

// Service push notification servisi
type Service struct {
	client *messaging.Client
	config FirebaseConfig
}

// NewService yeni servis oluşturur
func NewService(ctx context.Context, config FirebaseConfig) (*Service, error) {
	var app *firebase.App
	var err error

	if len(config.CredentialsJSON) > 0 {
		app, err = firebase.NewApp(ctx, nil, option.WithCredentialsJSON(config.CredentialsJSON))
	} else if config.CredentialsFile != "" {
		app, err = firebase.NewApp(ctx, nil, option.WithCredentialsFile(config.CredentialsFile))
	} else {
		// Use default credentials (from GOOGLE_APPLICATION_CREDENTIALS env var)
		app, err = firebase.NewApp(ctx, nil)
	}

	if err != nil {
		return nil, fmt.Errorf("firebase app oluşturulamadı: %w", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("messaging client oluşturulamadı: %w", err)
	}

	return &Service{
		client: client,
		config: config,
	}, nil
}

// SendToDevice tek cihaza bildirim gönderir
func (s *Service) SendToDevice(ctx context.Context, token string, notification *Notification) (*SendResult, error) {
	msg := s.buildMessage(notification)
	msg.Token = token

	response, err := s.client.Send(ctx, msg)
	if err != nil {
		return &SendResult{
			Success: false,
			Error:   err.Error(),
		}, err
	}

	return &SendResult{
		Success:   true,
		MessageID: response,
	}, nil
}

// SendToDevices birden fazla cihaza bildirim gönderir
func (s *Service) SendToDevices(ctx context.Context, tokens []string, notification *Notification) (*SendResult, error) {
	if len(tokens) == 0 {
		return &SendResult{Success: true}, nil
	}

	msg := s.buildMulticastMessage(tokens, notification)

	response, err := s.client.SendEachForMulticast(ctx, msg)
	if err != nil {
		return &SendResult{
			Success: false,
			Error:   err.Error(),
		}, err
	}

	return &SendResult{
		Success:      response.SuccessCount > 0,
		SuccessCount: response.SuccessCount,
		FailureCount: response.FailureCount,
	}, nil
}

// SendToTopic bir konuya abone olan cihazlara bildirim gönderir
func (s *Service) SendToTopic(ctx context.Context, topic string, notification *Notification) (*SendResult, error) {
	msg := s.buildMessage(notification)
	msg.Topic = topic

	response, err := s.client.Send(ctx, msg)
	if err != nil {
		return &SendResult{
			Success: false,
			Error:   err.Error(),
		}, err
	}

	return &SendResult{
		Success:   true,
		MessageID: response,
	}, nil
}

// SendToCondition koşula göre bildirim gönderir
func (s *Service) SendToCondition(ctx context.Context, condition string, notification *Notification) (*SendResult, error) {
	msg := s.buildMessage(notification)
	msg.Condition = condition

	response, err := s.client.Send(ctx, msg)
	if err != nil {
		return &SendResult{
			Success: false,
			Error:   err.Error(),
		}, err
	}

	return &SendResult{
		Success:   true,
		MessageID: response,
	}, nil
}

// SubscribeToTopic cihazları konuya abone eder
func (s *Service) SubscribeToTopic(ctx context.Context, tokens []string, topic string) error {
	_, err := s.client.SubscribeToTopic(ctx, tokens, topic)
	return err
}

// UnsubscribeFromTopic cihazların konu aboneliğini kaldırır
func (s *Service) UnsubscribeFromTopic(ctx context.Context, tokens []string, topic string) error {
	_, err := s.client.UnsubscribeFromTopic(ctx, tokens, topic)
	return err
}

// buildMessage mesaj oluşturur
func (s *Service) buildMessage(notification *Notification) *messaging.Message {
	msg := &messaging.Message{
		Notification: &messaging.Notification{
			Title:    notification.Title,
			Body:     notification.Body,
			ImageURL: notification.ImageURL,
		},
		Data: notification.Data,
		Android: &messaging.AndroidConfig{
			Priority: notification.Priority,
			Notification: &messaging.AndroidNotification{
				Sound:       notification.Sound,
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
				ChannelID:   "siteeksen_default",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound:            notification.Sound,
					Badge:            &notification.Badge,
					MutableContent:   true,
					ContentAvailable: true,
				},
			},
		},
	}

	// Type'ı data'ya ekle
	if msg.Data == nil {
		msg.Data = make(map[string]string)
	}
	msg.Data["type"] = string(notification.Type)
	msg.Data["notification_id"] = notification.ID

	return msg
}

// buildMulticastMessage çoklu cihaz mesajı oluşturur
func (s *Service) buildMulticastMessage(tokens []string, notification *Notification) *messaging.MulticastMessage {
	data := notification.Data
	if data == nil {
		data = make(map[string]string)
	}
	data["type"] = string(notification.Type)
	data["notification_id"] = notification.ID

	return &messaging.MulticastMessage{
		Tokens: tokens,
		Notification: &messaging.Notification{
			Title:    notification.Title,
			Body:     notification.Body,
			ImageURL: notification.ImageURL,
		},
		Data: data,
		Android: &messaging.AndroidConfig{
			Priority: notification.Priority,
			Notification: &messaging.AndroidNotification{
				Sound:       notification.Sound,
				ClickAction: "FLUTTER_NOTIFICATION_CLICK",
				ChannelID:   "siteeksen_default",
			},
		},
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound:            notification.Sound,
					Badge:            &notification.Badge,
					MutableContent:   true,
					ContentAvailable: true,
				},
			},
		},
	}
}

// ===============================================
// TOPIC YÖNETİMİ
// ===============================================

// TopicManager topic yöneticisi
type TopicManager struct {
	service *Service
}

// NewTopicManager yeni topic yöneticisi oluşturur
func NewTopicManager(service *Service) *TopicManager {
	return &TopicManager{service: service}
}

// SiteTopicName site konusunu oluşturur
func (t *TopicManager) SiteTopicName(siteID string) string {
	return fmt.Sprintf("site_%s", siteID)
}

// BlockTopicName blok konusunu oluşturur
func (t *TopicManager) BlockTopicName(siteID, blockID string) string {
	return fmt.Sprintf("site_%s_block_%s", siteID, blockID)
}

// NotifyAllResidents tüm sakinleri bilgilendirir
func (t *TopicManager) NotifyAllResidents(ctx context.Context, siteID string, notification *Notification) (*SendResult, error) {
	return t.service.SendToTopic(ctx, t.SiteTopicName(siteID), notification)
}

// NotifyBlock blok sakinlerini bilgilendirir
func (t *TopicManager) NotifyBlock(ctx context.Context, siteID, blockID string, notification *Notification) (*SendResult, error) {
	return t.service.SendToTopic(ctx, t.BlockTopicName(siteID, blockID), notification)
}
