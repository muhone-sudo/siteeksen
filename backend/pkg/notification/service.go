package notification

import (
	"context"
	"fmt"
)

// NotificationType - bildirim tipleri
type NotificationType string

const (
	TypePaymentReminder  NotificationType = "PAYMENT_REMINDER"
	TypePaymentReceived  NotificationType = "PAYMENT_RECEIVED"
	TypeNewAnnouncement  NotificationType = "NEW_ANNOUNCEMENT"
	TypeRequestUpdate    NotificationType = "REQUEST_UPDATE"
	TypeMeterReading     NotificationType = "METER_READING"
	TypeEmergency        NotificationType = "EMERGENCY"
)

// NotificationService - bildirim servisi
type NotificationService struct {
	fcm *FCMClient
}

// NewNotificationService - yeni bildirim servisi
func NewNotificationService() (*NotificationService, error) {
	fcm, err := NewFCMClient()
	if err != nil {
		return nil, err
	}

	return &NotificationService{fcm: fcm}, nil
}

// SendPaymentReminder - ödeme hatırlatma bildirimi
func (s *NotificationService) SendPaymentReminder(ctx context.Context, token string, amount float64, dueDate string) error {
	data := map[string]string{
		"type":     string(TypePaymentReminder),
		"amount":   fmt.Sprintf("%.2f", amount),
		"due_date": dueDate,
		"action":   "OPEN_PAYMENTS",
	}

	_, err := s.fcm.SendToDevice(
		ctx,
		token,
		"Aidat Hatırlatması",
		fmt.Sprintf("₺%.2f tutarındaki aidatınızın son ödeme tarihi %s. Hemen ödeyin!", amount, dueDate),
		data,
	)
	return err
}

// SendPaymentConfirmation - ödeme onay bildirimi
func (s *NotificationService) SendPaymentConfirmation(ctx context.Context, token string, amount float64, assessmentPeriod string) error {
	data := map[string]string{
		"type":   string(TypePaymentReceived),
		"amount": fmt.Sprintf("%.2f", amount),
		"period": assessmentPeriod,
		"action": "OPEN_RECEIPT",
	}

	_, err := s.fcm.SendToDevice(
		ctx,
		token,
		"Ödeme Alındı ✓",
		fmt.Sprintf("%s dönemi için ₺%.2f ödemeniz başarıyla alındı.", assessmentPeriod, amount),
		data,
	)
	return err
}

// SendNewAnnouncement - yeni duyuru bildirimi
func (s *NotificationService) SendNewAnnouncement(ctx context.Context, propertyID string, title string, category string) error {
	topic := fmt.Sprintf("property_%s", propertyID)

	data := map[string]string{
		"type":     string(TypeNewAnnouncement),
		"category": category,
		"action":   "OPEN_ANNOUNCEMENTS",
	}

	_, err := s.fcm.SendToTopic(
		ctx,
		topic,
		"📢 Yeni Duyuru",
		title,
		data,
	)
	return err
}

// SendRequestStatusUpdate - talep durum güncelleme bildirimi
func (s *NotificationService) SendRequestStatusUpdate(ctx context.Context, token string, ticketNo string, newStatus string) error {
	statusText := map[string]string{
		"IN_PROGRESS": "işleme alındı",
		"RESOLVED":    "çözüldü",
		"CLOSED":      "kapatıldı",
	}

	data := map[string]string{
		"type":      string(TypeRequestUpdate),
		"ticket_no": ticketNo,
		"status":    newStatus,
		"action":    "OPEN_REQUEST",
	}

	_, err := s.fcm.SendToDevice(
		ctx,
		token,
		"Talep Güncellendi",
		fmt.Sprintf("%s numaralı talebiniz %s.", ticketNo, statusText[newStatus]),
		data,
	)
	return err
}

// SendMeterReadingReminder - sayaç okuma hatırlatması
func (s *NotificationService) SendMeterReadingReminder(ctx context.Context, propertyID string, meterType string, deadline string) error {
	topic := fmt.Sprintf("property_%s_meters", propertyID)

	meterTypeText := map[string]string{
		"HEAT":       "Isı",
		"WATER_COLD": "Soğuk Su",
		"WATER_HOT":  "Sıcak Su",
	}

	data := map[string]string{
		"type":       string(TypeMeterReading),
		"meter_type": meterType,
		"deadline":   deadline,
		"action":     "OPEN_METERS",
	}

	_, err := s.fcm.SendToTopic(
		ctx,
		topic,
		"Sayaç Okuma Hatırlatması",
		fmt.Sprintf("%s sayaç okumalarının son giriş tarihi: %s", meterTypeText[meterType], deadline),
		data,
	)
	return err
}

// SendEmergencyAlert - acil durum bildirimi
func (s *NotificationService) SendEmergencyAlert(ctx context.Context, propertyID string, title, message string) error {
	topic := fmt.Sprintf("property_%s", propertyID)

	data := map[string]string{
		"type":     string(TypeEmergency),
		"priority": "HIGH",
		"action":   "OPEN_ANNOUNCEMENTS",
	}

	_, err := s.fcm.SendToTopic(
		ctx,
		topic,
		"🚨 "+title,
		message,
		data,
	)
	return err
}

// SubscribeToPropertyTopic - kullanıcıyı site topic'ine abone et
func (s *NotificationService) SubscribeToPropertyTopic(ctx context.Context, token, propertyID string) error {
	// FCM Admin SDK ile topic subscription yapılır
	// Bu basit implementasyonda client-side subscription kullanılır
	return nil
}
