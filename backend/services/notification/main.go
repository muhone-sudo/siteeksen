package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// NotificationRequest - Bildirim isteği
type NotificationRequest struct {
	Type       string            `json:"type" binding:"required"` // PUSH, SMS, EMAIL
	Recipients []string          `json:"recipients" binding:"required"`
	Title      string            `json:"title"`
	Body       string            `json:"body" binding:"required"`
	Data       map[string]string `json:"data,omitempty"`
	Priority   string            `json:"priority"` // LOW, NORMAL, HIGH
	ScheduleAt *time.Time        `json:"schedule_at,omitempty"`
}

// NotificationLog - Bildirim kaydı
type NotificationLog struct {
	ID          string    `json:"id"`
	Type        string    `json:"type"`
	Recipient   string    `json:"recipient"`
	Title       string    `json:"title"`
	Body        string    `json:"body"`
	Status      string    `json:"status"` // PENDING, SENT, FAILED
	SentAt      time.Time `json:"sent_at"`
	Error       string    `json:"error,omitempty"`
}

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "notification"})
	})

	// Notification endpoints
	r.POST("/api/v1/notifications/send", sendNotification)
	r.POST("/api/v1/notifications/send-bulk", sendBulkNotification)
	r.GET("/api/v1/notifications/logs", getNotificationLogs)
	r.GET("/api/v1/notifications/stats", getNotificationStats)

	// Templates
	r.GET("/api/v1/notifications/templates", listTemplates)
	r.POST("/api/v1/notifications/templates", createTemplate)
	r.PUT("/api/v1/notifications/templates/:id", updateTemplate)

	// User preferences
	r.GET("/api/v1/users/:id/notification-preferences", getPreferences)
	r.PUT("/api/v1/users/:id/notification-preferences", updatePreferences)

	// Device tokens (FCM)
	r.POST("/api/v1/devices/register", registerDevice)
	r.DELETE("/api/v1/devices/:token", unregisterDevice)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8085"
	}

	log.Printf("Notification Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func sendNotification(c *gin.Context) {
	var req NotificationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Bildirim tipine göre gönderim
	switch req.Type {
	case "PUSH":
		// Firebase FCM
		log.Printf("Sending push notification to %v", req.Recipients)
	case "SMS":
		// SMS provider (Netgsm, Iletisimci, etc.)
		log.Printf("Sending SMS to %v", req.Recipients)
	case "EMAIL":
		// SMTP / SendGrid / AWS SES
		log.Printf("Sending email to %v", req.Recipients)
	}

	c.JSON(http.StatusOK, gin.H{
		"message":       "Bildirim gönderildi",
		"notification_id": "notif-" + time.Now().Format("20060102150405"),
		"recipients":    len(req.Recipients),
	})
}

func sendBulkNotification(c *gin.Context) {
	var req struct {
		Type       string `json:"type"`
		PropertyID string `json:"property_id"` // Tüm site sakinlerine
		Title      string `json:"title"`
		Body       string `json:"body"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Property'deki tüm kullanıcılara gönder
	c.JSON(http.StatusOK, gin.H{
		"message":    "Toplu bildirim kuyruğa alındı",
		"property_id": req.PropertyID,
		"estimated_recipients": 124,
	})
}

func getNotificationLogs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []NotificationLog{
			{
				ID:        "log-001",
				Type:      "PUSH",
				Recipient: "user-001",
				Title:     "Ödeme Hatırlatması",
				Body:      "Ocak ayı aidatınızın son ödeme tarihi yaklaşıyor",
				Status:    "SENT",
				SentAt:    time.Now().Add(-1 * time.Hour),
			},
		},
		"total": 1,
	})
}

func getNotificationStats(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"today": gin.H{
			"push":  45,
			"sms":   12,
			"email": 8,
		},
		"this_month": gin.H{
			"push":  1250,
			"sms":   340,
			"email": 180,
		},
		"success_rate": 98.5,
	})
}

// ============ TEMPLATES ============

func listTemplates(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":      "tpl-001",
				"name":    "payment_reminder",
				"type":    "PUSH",
				"title":   "Ödeme Hatırlatması",
				"body":    "{{month}} ayı aidatınızın son ödeme tarihi {{due_date}}",
				"is_active": true,
			},
			{
				"id":      "tpl-002",
				"name":    "payment_received",
				"type":    "PUSH",
				"title":   "Ödeme Alındı ✓",
				"body":    "{{amount}} TL ödemeniz başarıyla alındı",
				"is_active": true,
			},
		},
	})
}

func createTemplate(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "tpl-new", "message": "Şablon oluşturuldu"})
}

func updateTemplate(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Şablon güncellendi"})
}

// ============ PREFERENCES ============

func getPreferences(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"user_id": c.Param("id"),
		"preferences": gin.H{
			"push_enabled":          true,
			"sms_enabled":           true,
			"email_enabled":         true,
			"payment_reminders":     true,
			"announcement_alerts":   true,
			"request_updates":       true,
			"marketing_messages":    false,
			"quiet_hours": gin.H{
				"enabled": true,
				"start":   "22:00",
				"end":     "08:00",
			},
		},
	})
}

func updatePreferences(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Tercihler güncellendi"})
}

// ============ DEVICE TOKENS ============

func registerDevice(c *gin.Context) {
	var req struct {
		UserID   string `json:"user_id" binding:"required"`
		Token    string `json:"token" binding:"required"`
		Platform string `json:"platform"` // ios, android, web
		DeviceID string `json:"device_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Cihaz kaydedildi"})
}

func unregisterDevice(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Cihaz kaydı silindi"})
}
