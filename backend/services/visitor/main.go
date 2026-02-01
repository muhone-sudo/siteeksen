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
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "visitor",
			"version": "1.0.0",
		})
	})

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
		port = "8090"
	}

	log.Printf("Visitor Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// List all visitors with filters
func listVisitors(c *gin.Context) {
	// Query params: date, status, unit_id, search
	now := time.Now()
	visitors := []Visitor{
		{
			ID:           uuid.New().String(),
			PropertyID:   "prop-1",
			UnitID:       "unit-101",
			VisitorName:  "Ahmet Yılmaz",
			VisitorPhone: "0532 111 2233",
			Purpose:      "Misafir",
			ExpectedAt:   &now,
			Status:       "EXPECTED",
			QRCode:       "VIS-" + uuid.New().String()[:8],
			CreatedAt:    now,
			UpdatedAt:    now,
		},
		{
			ID:          uuid.New().String(),
			PropertyID:  "prop-1",
			UnitID:      "unit-205",
			VisitorName: "Kargo - Aras",
			Purpose:     "Kargo Teslimi",
			CheckedInAt: &now,
			Status:      "CHECKED_IN",
			CreatedAt:   now,
			UpdatedAt:   now,
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"visitors": visitors,
		"total":    len(visitors),
	})
}

// Get visitor stats
func getVisitorStats(c *gin.Context) {
	stats := VisitorStats{
		TodayTotal:    12,
		TodayExpected: 3,
		CurrentInside: 2,
		TodayLeft:     7,
	}
	c.JSON(http.StatusOK, stats)
}

// Get today's visitors
func getTodayVisitors(c *gin.Context) {
	now := time.Now()
	visitors := []Visitor{
		{
			ID:           uuid.New().String(),
			VisitorName:  "Mehmet Demir",
			UnitID:       "unit-301",
			Purpose:      "Tadilat Ustası",
			CheckedInAt:  &now,
			CheckedOutAt: &now,
			Status:       "CHECKED_OUT",
		},
	}
	c.JSON(http.StatusOK, gin.H{"visitors": visitors})
}

// Get expected visitors
func getExpectedVisitors(c *gin.Context) {
	expected := time.Now().Add(2 * time.Hour)
	visitors := []Visitor{
		{
			ID:          uuid.New().String(),
			VisitorName: "Zeynep Kaya",
			UnitID:      "unit-102",
			Purpose:     "Doğum Günü Partisi",
			ExpectedAt:  &expected,
			Status:      "EXPECTED",
			QRCode:      "VIS-ABC12345",
		},
	}
	c.JSON(http.StatusOK, gin.H{"visitors": visitors})
}

// Get visitors currently inside
func getCurrentVisitors(c *gin.Context) {
	now := time.Now()
	visitors := []Visitor{
		{
			ID:          uuid.New().String(),
			VisitorName: "Kargo Yurtiçi",
			UnitID:      "unit-405",
			Purpose:     "Kargo",
			CheckedInAt: &now,
			Status:      "CHECKED_IN",
		},
	}
	c.JSON(http.StatusOK, gin.H{"visitors": visitors, "count": len(visitors)})
}

// Get single visitor
func getVisitor(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	visitor := Visitor{
		ID:           id,
		PropertyID:   "prop-1",
		UnitID:       "unit-101",
		VisitorName:  "Ahmet Yılmaz",
		VisitorPhone: "0532 111 2233",
		Purpose:      "Misafir",
		ExpectedAt:   &now,
		Status:       "EXPECTED",
		QRCode:       "VIS-12345678",
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	c.JSON(http.StatusOK, visitor)
}

// Create visitor (pre-registration)
func createVisitor(c *gin.Context) {
	var req VisitorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	qrExpiry := now.Add(24 * time.Hour)

	visitor := Visitor{
		ID:           uuid.New().String(),
		PropertyID:   "prop-1",
		UnitID:       req.UnitID,
		VisitorName:  req.VisitorName,
		VisitorPhone: req.VisitorPhone,
		Purpose:      req.Purpose,
		Status:       "EXPECTED",
		QRCode:       "VIS-" + uuid.New().String()[:8],
		QRExpiresAt:  &qrExpiry,
		Notes:        req.Notes,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	c.JSON(http.StatusCreated, visitor)
}

// Update visitor
func updateVisitor(c *gin.Context) {
	id := c.Param("id")
	var req VisitorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"message": "Ziyaretçi güncellendi",
	})
}

// Delete visitor
func deleteVisitor(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"message": "Ziyaretçi kaydı silindi",
	})
}

// Check in visitor
func checkInVisitor(c *gin.Context) {
	id := c.Param("id")
	var req CheckInRequest
	c.ShouldBindJSON(&req)

	now := time.Now()
	c.JSON(http.StatusOK, gin.H{
		"id":            id,
		"status":        "CHECKED_IN",
		"checked_in_at": now,
		"message":       "Ziyaretçi girişi yapıldı",
	})
}

// Check out visitor
func checkOutVisitor(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	c.JSON(http.StatusOK, gin.H{
		"id":             id,
		"status":         "CHECKED_OUT",
		"checked_out_at": now,
		"message":        "Ziyaretçi çıkışı yapıldı",
	})
}

// Get visitor by QR code
func getVisitorByQR(c *gin.Context) {
	code := c.Param("code")
	now := time.Now()
	expected := now.Add(1 * time.Hour)

	visitor := Visitor{
		ID:          uuid.New().String(),
		VisitorName: "QR ile Gelen Ziyaretçi",
		UnitID:      "unit-101",
		Purpose:     "Misafir",
		ExpectedAt:  &expected,
		Status:      "EXPECTED",
		QRCode:      code,
	}

	c.JSON(http.StatusOK, visitor)
}

// Regenerate QR code
func regenerateQR(c *gin.Context) {
	id := c.Param("id")
	newQR := "VIS-" + uuid.New().String()[:8]
	expiry := time.Now().Add(24 * time.Hour)

	c.JSON(http.StatusOK, gin.H{
		"id":         id,
		"qr_code":    newQR,
		"expires_at": expiry,
		"message":    "Yeni QR kod oluşturuldu",
	})
}

// Notify resident about visitor
func notifyResident(c *gin.Context) {
	id := c.Param("id")
	var req NotifyRequest
	c.ShouldBindJSON(&req)

	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"method":  req.Method,
		"sent_at": time.Now(),
		"message": "Bildirim gönderildi",
	})
}

// Get visitors for a specific unit
func getUnitVisitors(c *gin.Context) {
	unitID := c.Param("unit_id")
	now := time.Now()

	visitors := []Visitor{
		{
			ID:          uuid.New().String(),
			UnitID:      unitID,
			VisitorName: "Daire Ziyaretçisi",
			Purpose:     "Misafir",
			ExpectedAt:  &now,
			Status:      "EXPECTED",
		},
	}

	c.JSON(http.StatusOK, gin.H{"visitors": visitors})
}

// Get visitor history for a unit
func getUnitVisitorHistory(c *gin.Context) {
	unitID := c.Param("unit_id")
	now := time.Now()
	past := now.Add(-24 * time.Hour)

	visitors := []Visitor{
		{
			ID:           uuid.New().String(),
			UnitID:       unitID,
			VisitorName:  "Geçmiş Ziyaretçi 1",
			Purpose:      "Misafir",
			CheckedInAt:  &past,
			CheckedOutAt: &past,
			Status:       "CHECKED_OUT",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"visitors": visitors,
		"total":    len(visitors),
	})
}
