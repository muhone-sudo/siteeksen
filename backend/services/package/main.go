package main

import (
	"log"
	"os"
	"time"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
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

	r.GET("/health", stub.Health("package"))

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
		port = "8097"
	}

	log.Printf("Package Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func getCarriers(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func listPackages(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func getPendingPackages(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func getPackageStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func getPackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func receivePackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func updatePackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func deletePackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func sendNotification(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func deliverPackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func returnPackage(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}

func getUnitPackages(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "package")
}
