package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

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
	ID        string    `json:"id"`
	Type      string    `json:"type"`
	Recipient string    `json:"recipient"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	Status    string    `json:"status"` // PENDING, SENT, FAILED
	SentAt    time.Time `json:"sent_at"`
	Error     string    `json:"error,omitempty"`
}

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", stub.Health("notification"))

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

func sendNotification(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func sendBulkNotification(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func getNotificationLogs(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func getNotificationStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

// ============ TEMPLATES ============

func listTemplates(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func createTemplate(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func updateTemplate(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

// ============ PREFERENCES ============

func getPreferences(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func updatePreferences(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

// ============ DEVICE TOKENS ============

func registerDevice(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}

func unregisterDevice(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "notification")
}
