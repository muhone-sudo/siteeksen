package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// =====================================================
// MODELS
// =====================================================

type Package struct {
	ID                   string     `json:"id"`
	PropertyID           string     `json:"property_id"`
	UnitID               string     `json:"unit_id"`
	UnitNumber           string     `json:"unit_number,omitempty"`
	RecipientName        string     `json:"recipient_name"`
	RecipientPhone       string     `json:"recipient_phone,omitempty"`
	Carrier              string     `json:"carrier,omitempty"`
	TrackingNumber       string     `json:"tracking_number,omitempty"`
	PackageType          string     `json:"package_type"` // PACKAGE, ENVELOPE, LARGE
	Description          string     `json:"description,omitempty"`
	PhotoURL             string     `json:"photo_url,omitempty"`
	StorageLocation      string     `json:"storage_location,omitempty"`
	ReceivedAt           time.Time  `json:"received_at"`
	ReceivedBy           string     `json:"received_by,omitempty"`
	ReceivedByName       string     `json:"received_by_name,omitempty"`
	NotificationSent     bool       `json:"notification_sent"`
	NotificationSentAt   *time.Time `json:"notification_sent_at,omitempty"`
	ReminderCount        int        `json:"reminder_count"`
	DeliveredAt          *time.Time `json:"delivered_at,omitempty"`
	DeliveredBy          string     `json:"delivered_by,omitempty"`
	DeliveredToName      string     `json:"delivered_to_name,omitempty"`
	DeliverySignatureURL string     `json:"delivery_signature_url,omitempty"`
	DeliveryPhotoURL     string     `json:"delivery_photo_url,omitempty"`
	Status               string     `json:"status"` // RECEIVED, NOTIFIED, DELIVERED, RETURNED
	Notes                string     `json:"notes,omitempty"`
}

type PackageRequest struct {
	UnitID          string `json:"unit_id" binding:"required"`
	RecipientName   string `json:"recipient_name" binding:"required"`
	RecipientPhone  string `json:"recipient_phone"`
	Carrier         string `json:"carrier"`
	TrackingNumber  string `json:"tracking_number"`
	PackageType     string `json:"package_type"`
	Description     string `json:"description"`
	PhotoURL        string `json:"photo_url"`
	StorageLocation string `json:"storage_location"`
}

type DeliveryRequest struct {
	DeliveredToName string `json:"delivered_to_name" binding:"required"`
	SignatureURL    string `json:"signature_url"`
	PhotoURL        string `json:"photo_url"`
	Notes           string `json:"notes"`
}

type PackageStats struct {
	TotalReceived   int `json:"total_received"`
	PendingDelivery int `json:"pending_delivery"`
	DeliveredToday  int `json:"delivered_today"`
	AwaitingPickup  int `json:"awaiting_pickup"`
	OverduePending  int `json:"overdue_pending"` // 3+ gün bekleyenler
}

var carriers = []string{
	"Aras Kargo",
	"Yurtiçi Kargo",
	"MNG Kargo",
	"PTT Kargo",
	"UPS",
	"DHL",
	"Sürat Kargo",
	"Trendyol Express",
	"Hepsijet",
	"Getir",
	"Diğer",
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "package",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		v1.GET("/carriers", getCarriers)

		packages := v1.Group("/packages")
		{
			packages.GET("", listPackages)
			packages.GET("/pending", getPendingPackages)
			packages.GET("/stats", getPackageStats)
			packages.GET("/:id", getPackage)
			packages.POST("", receivePackage)
			packages.PUT("/:id", updatePackage)
			packages.DELETE("/:id", deletePackage)
			packages.POST("/:id/notify", sendNotification)
			packages.POST("/:id/deliver", deliverPackage)
			packages.POST("/:id/return", returnPackage)
		}

		// Unit packages
		v1.GET("/units/:unit_id/packages", getUnitPackages)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8096"
	}

	log.Printf("Package Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func getCarriers(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"carriers": carriers})
}

func listPackages(c *gin.Context) {
	// Query params: status, date, unit_id, search
	now := time.Now()
	notified := now.Add(-2 * time.Hour)
	delivered := now.Add(-1 * time.Hour)

	packages := []Package{
		{
			ID:                 uuid.New().String(),
			PropertyID:         "prop-1",
			UnitID:             "unit-101",
			UnitNumber:         "D.101",
			RecipientName:      "Ali Veli",
			Carrier:            "Yurtiçi Kargo",
			TrackingNumber:     "YK123456789",
			PackageType:        "PACKAGE",
			StorageLocation:    "Raf A-3",
			ReceivedAt:         now.Add(-4 * time.Hour),
			ReceivedByName:     "Güvenlik Ali",
			NotificationSent:   true,
			NotificationSentAt: &notified,
			Status:             "NOTIFIED",
		},
		{
			ID:               uuid.New().String(),
			PropertyID:       "prop-1",
			UnitID:           "unit-205",
			UnitNumber:       "D.205",
			RecipientName:    "Ayşe Kaya",
			Carrier:          "Aras Kargo",
			TrackingNumber:   "AR987654321",
			PackageType:      "ENVELOPE",
			StorageLocation:  "Masa",
			ReceivedAt:       now.Add(-24 * time.Hour),
			ReceivedByName:   "Güvenlik Mehmet",
			NotificationSent: true,
			ReminderCount:    2,
			Status:           "NOTIFIED",
		},
		{
			ID:               uuid.New().String(),
			PropertyID:       "prop-1",
			UnitID:           "unit-301",
			UnitNumber:       "D.301",
			RecipientName:    "Mehmet Demir",
			Carrier:          "Trendyol Express",
			PackageType:      "LARGE",
			Description:      "Büyük kutu - TV",
			StorageLocation:  "Depo",
			ReceivedAt:       now.Add(-6 * time.Hour),
			ReceivedByName:   "Güvenlik Ali",
			NotificationSent: true,
			DeliveredAt:      &delivered,
			DeliveredToName:  "Mehmet Demir",
			Status:           "DELIVERED",
		},
	}

	c.JSON(http.StatusOK, gin.H{"packages": packages, "total": len(packages)})
}

func getPendingPackages(c *gin.Context) {
	now := time.Now()
	packages := []Package{
		{
			ID:            uuid.New().String(),
			UnitNumber:    "D.101",
			RecipientName: "Ali Veli",
			Carrier:       "Yurtiçi Kargo",
			PackageType:   "PACKAGE",
			ReceivedAt:    now.Add(-4 * time.Hour),
			Status:        "NOTIFIED",
		},
		{
			ID:            uuid.New().String(),
			UnitNumber:    "D.205",
			RecipientName: "Ayşe Kaya",
			Carrier:       "Aras Kargo",
			PackageType:   "ENVELOPE",
			ReceivedAt:    now.Add(-24 * time.Hour),
			ReminderCount: 2,
			Status:        "NOTIFIED",
		},
	}
	c.JSON(http.StatusOK, gin.H{"packages": packages, "count": len(packages)})
}

func getPackageStats(c *gin.Context) {
	stats := PackageStats{
		TotalReceived:   156,
		PendingDelivery: 8,
		DeliveredToday:  12,
		AwaitingPickup:  8,
		OverduePending:  2,
	}
	c.JSON(http.StatusOK, stats)
}

func getPackage(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()

	pkg := Package{
		ID:               id,
		PropertyID:       "prop-1",
		UnitID:           "unit-101",
		UnitNumber:       "D.101",
		RecipientName:    "Ali Veli",
		RecipientPhone:   "0532 111 2233",
		Carrier:          "Yurtiçi Kargo",
		TrackingNumber:   "YK123456789",
		PackageType:      "PACKAGE",
		StorageLocation:  "Raf A-3",
		ReceivedAt:       now.Add(-4 * time.Hour),
		ReceivedByName:   "Güvenlik Ali",
		NotificationSent: true,
		Status:           "NOTIFIED",
	}
	c.JSON(http.StatusOK, pkg)
}

func receivePackage(c *gin.Context) {
	var req PackageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	pkg := Package{
		ID:              uuid.New().String(),
		PropertyID:      "prop-1",
		UnitID:          req.UnitID,
		RecipientName:   req.RecipientName,
		RecipientPhone:  req.RecipientPhone,
		Carrier:         req.Carrier,
		TrackingNumber:  req.TrackingNumber,
		PackageType:     req.PackageType,
		Description:     req.Description,
		PhotoURL:        req.PhotoURL,
		StorageLocation: req.StorageLocation,
		ReceivedAt:      now,
		ReceivedBy:      "user-1",
		Status:          "RECEIVED",
	}

	c.JSON(http.StatusCreated, pkg)
}

func updatePackage(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Kargo bilgisi güncellendi"})
}

func deletePackage(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Kargo kaydı silindi"})
}

func sendNotification(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()

	c.JSON(http.StatusOK, gin.H{
		"id":                   id,
		"notification_sent":    true,
		"notification_sent_at": now,
		"status":               "NOTIFIED",
		"message":              "Bildirim gönderildi",
	})
}

func deliverPackage(c *gin.Context) {
	id := c.Param("id")
	var req DeliveryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	c.JSON(http.StatusOK, gin.H{
		"id":                id,
		"status":            "DELIVERED",
		"delivered_at":      now,
		"delivered_to_name": req.DeliveredToName,
		"message":           "Kargo teslim edildi",
	})
}

func returnPackage(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "RETURNED",
		"message": "Kargo iade edildi",
	})
}

func getUnitPackages(c *gin.Context) {
	unitID := c.Param("unit_id")
	c.JSON(http.StatusOK, gin.H{
		"unit_id":  unitID,
		"packages": []Package{},
		"total":    0,
	})
}
