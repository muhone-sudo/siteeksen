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

type Visitor struct {
	ID              string     `json:"id"`
	PropertyID      string     `json:"property_id"`
	UnitID          string     `json:"unit_id,omitempty"`
	VisitorName     string     `json:"visitor_name"`
	VisitorPhone    string     `json:"visitor_phone,omitempty"`
	VisitorIDNumber string     `json:"visitor_id_number,omitempty"`
	VisitorCompany  string     `json:"visitor_company,omitempty"`
	VisitorPhotoURL string     `json:"visitor_photo_url,omitempty"`
	VehiclePlate    string     `json:"vehicle_plate,omitempty"`
	Purpose         string     `json:"purpose,omitempty"`
	VisitReason     string     `json:"visit_reason,omitempty"`
	ExpectedAt      *time.Time `json:"expected_at,omitempty"`
	CheckedInAt     *time.Time `json:"checked_in_at,omitempty"`
	CheckedInBy     string     `json:"checked_in_by,omitempty"`
	CheckedOutAt    *time.Time `json:"checked_out_at,omitempty"`
	CheckedOutBy    string     `json:"checked_out_by,omitempty"`
	Status          string     `json:"status"`
	QRCode          string     `json:"qr_code,omitempty"`
	QRExpiresAt     *time.Time `json:"qr_expires_at,omitempty"`
	Notes           string     `json:"notes,omitempty"`
	CreatedBy       string     `json:"created_by,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

type VisitorRequest struct {
	UnitID          string `json:"unit_id" binding:"required"`
	VisitorName     string `json:"visitor_name" binding:"required"`
	VisitorPhone    string `json:"visitor_phone"`
	VisitorIDNumber string `json:"visitor_id_number"`
	VisitorCompany  string `json:"visitor_company"`
	VehiclePlate    string `json:"vehicle_plate"`
	Purpose         string `json:"purpose"`
	ExpectedAt      string `json:"expected_at"`
	Notes           string `json:"notes"`
}

type CheckInRequest struct {
	VisitorIDNumber string `json:"visitor_id_number"`
	VehiclePlate    string `json:"vehicle_plate"`
	PhotoURL        string `json:"photo_url"`
	Notes           string `json:"notes"`
}

type NotifyRequest struct {
	Method  string `json:"method"` // SMS, PUSH, EMAIL
	Message string `json:"message"`
}

type VisitorStats struct {
	TodayTotal    int `json:"today_total"`
	TodayExpected int `json:"today_expected"`
	CurrentInside int `json:"current_inside"`
	TodayLeft     int `json:"today_left"`
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", stub.Health("visitor"))

	// Visitor routes
	v1 := r.Group("/api/v1")
	{
		visitors := v1.Group("/visitors")
		{
			visitors.GET("", listVisitors)
			visitors.GET("/stats", getVisitorStats)
			visitors.GET("/today", getTodayVisitors)
			visitors.GET("/expected", getExpectedVisitors)
			visitors.GET("/inside", getCurrentVisitors)
			visitors.GET("/:id", getVisitor)
			visitors.POST("", createVisitor)
			visitors.PUT("/:id", updateVisitor)
			visitors.DELETE("/:id", deleteVisitor)

			// Giriş/Çıkış işlemleri
			visitors.POST("/:id/checkin", checkInVisitor)
			visitors.POST("/:id/checkout", checkOutVisitor)

			// QR kod işlemleri
			visitors.GET("/qr/:code", getVisitorByQR)
			visitors.POST("/:id/regenerate-qr", regenerateQR)

			// Bildirim
			visitors.POST("/:id/notify", notifyResident)
		}

		// Unit visitors
		v1.GET("/units/:unit_id/visitors", getUnitVisitors)
		v1.GET("/units/:unit_id/visitors/history", getUnitVisitorHistory)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8105"
	}

	log.Printf("Visitor Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// List all visitors with filters
func listVisitors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get visitor stats
func getVisitorStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get today's visitors
func getTodayVisitors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get expected visitors
func getExpectedVisitors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get visitors currently inside
func getCurrentVisitors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get single visitor
func getVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Create visitor (pre-registration)
func createVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Update visitor
func updateVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Delete visitor
func deleteVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Check in visitor
func checkInVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Check out visitor
func checkOutVisitor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get visitor by QR code
func getVisitorByQR(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Regenerate QR code
func regenerateQR(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Notify resident about visitor
func notifyResident(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get visitors for a specific unit
func getUnitVisitors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}

// Get visitor history for a unit
func getUnitVisitorHistory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "visitor")
}
