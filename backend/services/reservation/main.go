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

type Facility struct {
	ID                    string   `json:"id"`
	PropertyID            string   `json:"property_id"`
	Name                  string   `json:"name"`
	Description           string   `json:"description,omitempty"`
	Category              string   `json:"category"` // POOL, GYM, TENNIS, MEETING_ROOM, BBQ, SAUNA
	PhotoURLs             []string `json:"photo_urls,omitempty"`
	Capacity              int      `json:"capacity"`
	IsPaid                bool     `json:"is_paid"`
	HourlyFee             float64  `json:"hourly_fee,omitempty"`
	DailyFee              float64  `json:"daily_fee,omitempty"`
	DepositAmount         float64  `json:"deposit_amount,omitempty"`
	AvailableFrom         string   `json:"available_from"` // "08:00"
	AvailableTo           string   `json:"available_to"`   // "22:00"
	AvailableDays         []int    `json:"available_days"` // 0-6
	MinDurationMinutes    int      `json:"min_duration_minutes"`
	MaxDurationMinutes    int      `json:"max_duration_minutes"`
	AdvanceBookingDays    int      `json:"advance_booking_days"`
	RequiresApproval      bool     `json:"requires_approval"`
	Rules                 string   `json:"rules,omitempty"`
	IsActive              bool     `json:"is_active"`
	MaintenanceMode       bool     `json:"maintenance_mode"`
	MaintenanceNote       string   `json:"maintenance_note,omitempty"`
	TodayReservationCount int      `json:"today_reservation_count,omitempty"`
	UpcomingReservations  int      `json:"upcoming_reservations,omitempty"`
}

type Reservation struct {
	ID              string     `json:"id"`
	PropertyID      string     `json:"property_id"`
	FacilityID      string     `json:"facility_id"`
	UnitID          string     `json:"unit_id"`
	ResidentID      string     `json:"resident_id"`
	ResidentName    string     `json:"resident_name,omitempty"`
	FacilityName    string     `json:"facility_name,omitempty"`
	StartTime       time.Time  `json:"start_time"`
	EndTime         time.Time  `json:"end_time"`
	DurationMinutes int        `json:"duration_minutes"`
	GuestCount      int        `json:"guest_count"`
	Purpose         string     `json:"purpose,omitempty"`
	SpecialRequests string     `json:"special_requests,omitempty"`
	Status          string     `json:"status"` // PENDING, APPROVED, REJECTED, CANCELLED, COMPLETED
	TotalFee        float64    `json:"total_fee"`
	DepositAmount   float64    `json:"deposit_amount"`
	PaymentStatus   string     `json:"payment_status,omitempty"`
	ReviewedBy      string     `json:"reviewed_by,omitempty"`
	ReviewedAt      *time.Time `json:"reviewed_at,omitempty"`
	RejectionReason string     `json:"rejection_reason,omitempty"`
	Notes           string     `json:"notes,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}

type TimeSlot struct {
	StartTime   string `json:"start_time"`
	EndTime     string `json:"end_time"`
	IsAvailable bool   `json:"is_available"`
	Reason      string `json:"reason,omitempty"` // BOOKED, MAINTENANCE, CLOSED
}

type ReservationRequest struct {
	FacilityID      string `json:"facility_id" binding:"required"`
	StartTime       string `json:"start_time" binding:"required"` // ISO 8601
	EndTime         string `json:"end_time" binding:"required"`
	GuestCount      int    `json:"guest_count"`
	Purpose         string `json:"purpose"`
	SpecialRequests string `json:"special_requests"`
}

type ReviewRequest struct {
	Action string `json:"action" binding:"required"` // APPROVE, REJECT
	Reason string `json:"reason"`
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "reservation",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		// Facilities
		facilities := v1.Group("/facilities")
		{
			facilities.GET("", listFacilities)
			facilities.GET("/:id", getFacility)
			facilities.POST("", createFacility)
			facilities.PUT("/:id", updateFacility)
			facilities.DELETE("/:id", deleteFacility)
			facilities.GET("/:id/availability", getFacilityAvailability)
			facilities.GET("/:id/reservations", getFacilityReservations)
			facilities.POST("/:id/maintenance", setMaintenanceMode)
		}

		// Reservations
		reservations := v1.Group("/reservations")
		{
			reservations.GET("", listReservations)
			reservations.GET("/pending", getPendingReservations)
			reservations.GET("/today", getTodayReservations)
			reservations.GET("/calendar", getCalendarView)
			reservations.GET("/:id", getReservation)
			reservations.POST("", createReservation)
			reservations.PUT("/:id", updateReservation)
			reservations.DELETE("/:id", cancelReservation)
			reservations.POST("/:id/review", reviewReservation)
			reservations.POST("/:id/complete", completeReservation)
		}

		// Unit reservations
		v1.GET("/units/:unit_id/reservations", getUnitReservations)
		v1.GET("/residents/:resident_id/reservations", getResidentReservations)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8092"
	}

	log.Printf("Reservation Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Facility Handlers
func listFacilities(c *gin.Context) {
	facilities := []Facility{
		{
			ID:                    uuid.New().String(),
			PropertyID:            "prop-1",
			Name:                  "Yüzme Havuzu",
			Description:           "Açık yüzme havuzu, çocuk havuzu dahil",
			Category:              "POOL",
			PhotoURLs:             []string{"/images/pool.jpg"},
			Capacity:              30,
			IsPaid:                true,
			HourlyFee:             50.00,
			AvailableFrom:         "09:00",
			AvailableTo:           "20:00",
			AvailableDays:         []int{1, 2, 3, 4, 5, 6, 0},
			MinDurationMinutes:    60,
			MaxDurationMinutes:    180,
			AdvanceBookingDays:    14,
			RequiresApproval:      false,
			IsActive:              true,
			TodayReservationCount: 5,
		},
		{
			ID:                    uuid.New().String(),
			PropertyID:            "prop-1",
			Name:                  "Spor Salonu",
			Description:           "Fitness merkezi, kardiyo ve ağırlık aletleri",
			Category:              "GYM",
			Capacity:              15,
			IsPaid:                false,
			AvailableFrom:         "06:00",
			AvailableTo:           "23:00",
			AvailableDays:         []int{1, 2, 3, 4, 5, 6, 0},
			MinDurationMinutes:    60,
			MaxDurationMinutes:    120,
			AdvanceBookingDays:    7,
			RequiresApproval:      false,
			IsActive:              true,
			TodayReservationCount: 12,
		},
		{
			ID:                    uuid.New().String(),
			PropertyID:            "prop-1",
			Name:                  "Toplantı Odası",
			Description:           "20 kişilik toplantı odası, projeksiyon cihazı mevcut",
			Category:              "MEETING_ROOM",
			Capacity:              20,
			IsPaid:                true,
			HourlyFee:             100.00,
			DepositAmount:         200.00,
			AvailableFrom:         "08:00",
			AvailableTo:           "22:00",
			AvailableDays:         []int{1, 2, 3, 4, 5, 6},
			MinDurationMinutes:    60,
			MaxDurationMinutes:    480,
			AdvanceBookingDays:    30,
			RequiresApproval:      true,
			IsActive:              true,
			TodayReservationCount: 2,
		},
		{
			ID:                    uuid.New().String(),
			PropertyID:            "prop-1",
			Name:                  "Mangal Alanı",
			Description:           "Açık mangal alanı, oturma grupları mevcut",
			Category:              "BBQ",
			Capacity:              25,
			IsPaid:                true,
			DailyFee:              150.00,
			DepositAmount:         100.00,
			AvailableFrom:         "10:00",
			AvailableTo:           "22:00",
			AvailableDays:         []int{6, 0},
			MinDurationMinutes:    240,
			MaxDurationMinutes:    480,
			AdvanceBookingDays:    14,
			RequiresApproval:      true,
			IsActive:              true,
			TodayReservationCount: 1,
		},
	}
	c.JSON(http.StatusOK, gin.H{"facilities": facilities, "total": len(facilities)})
}

func getFacility(c *gin.Context) {
	id := c.Param("id")
	facility := Facility{
		ID:                 id,
		Name:               "Yüzme Havuzu",
		Category:           "POOL",
		Capacity:           30,
		IsPaid:             true,
		HourlyFee:          50.00,
		AvailableFrom:      "09:00",
		AvailableTo:        "20:00",
		MinDurationMinutes: 60,
		MaxDurationMinutes: 180,
		IsActive:           true,
	}
	c.JSON(http.StatusOK, facility)
}

func createFacility(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Tesis oluşturuldu"})
}

func updateFacility(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Tesis güncellendi"})
}

func deleteFacility(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Tesis silindi"})
}

func getFacilityAvailability(c *gin.Context) {
	// Query params: date
	slots := []TimeSlot{
		{StartTime: "09:00", EndTime: "10:00", IsAvailable: true},
		{StartTime: "10:00", EndTime: "11:00", IsAvailable: false, Reason: "BOOKED"},
		{StartTime: "11:00", EndTime: "12:00", IsAvailable: true},
		{StartTime: "12:00", EndTime: "13:00", IsAvailable: true},
		{StartTime: "13:00", EndTime: "14:00", IsAvailable: false, Reason: "BOOKED"},
		{StartTime: "14:00", EndTime: "15:00", IsAvailable: true},
		{StartTime: "15:00", EndTime: "16:00", IsAvailable: true},
		{StartTime: "16:00", EndTime: "17:00", IsAvailable: true},
		{StartTime: "17:00", EndTime: "18:00", IsAvailable: false, Reason: "BOOKED"},
		{StartTime: "18:00", EndTime: "19:00", IsAvailable: true},
		{StartTime: "19:00", EndTime: "20:00", IsAvailable: true},
	}
	c.JSON(http.StatusOK, gin.H{"slots": slots, "date": c.Query("date")})
}

func getFacilityReservations(c *gin.Context) {
	id := c.Param("id")
	reservations := []Reservation{}
	c.JSON(http.StatusOK, gin.H{"facility_id": id, "reservations": reservations})
}

func setMaintenanceMode(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Bakım modu ayarlandı"})
}

// Reservation Handlers
func listReservations(c *gin.Context) {
	now := time.Now()
	reservations := []Reservation{
		{
			ID:              uuid.New().String(),
			FacilityName:    "Yüzme Havuzu",
			ResidentName:    "Ali Veli",
			UnitID:          "unit-101",
			StartTime:       now.Add(2 * time.Hour),
			EndTime:         now.Add(4 * time.Hour),
			DurationMinutes: 120,
			GuestCount:      4,
			Status:          "APPROVED",
			TotalFee:        100.00,
			CreatedAt:       now,
		},
		{
			ID:              uuid.New().String(),
			FacilityName:    "Toplantı Odası",
			ResidentName:    "Ayşe Yılmaz",
			UnitID:          "unit-205",
			StartTime:       now.Add(24 * time.Hour),
			EndTime:         now.Add(26 * time.Hour),
			DurationMinutes: 120,
			GuestCount:      10,
			Status:          "PENDING",
			TotalFee:        200.00,
			DepositAmount:   200.00,
			CreatedAt:       now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"reservations": reservations, "total": len(reservations)})
}

func getPendingReservations(c *gin.Context) {
	now := time.Now()
	reservations := []Reservation{
		{
			ID:            uuid.New().String(),
			FacilityName:  "Mangal Alanı",
			ResidentName:  "Mehmet Demir",
			UnitID:        "unit-301",
			StartTime:     now.Add(48 * time.Hour),
			EndTime:       now.Add(56 * time.Hour),
			GuestCount:    15,
			Status:        "PENDING",
			Purpose:       "Doğum günü kutlaması",
			TotalFee:      150.00,
			DepositAmount: 100.00,
			CreatedAt:     now,
		},
	}
	c.JSON(http.StatusOK, gin.H{"reservations": reservations, "count": len(reservations)})
}

func getTodayReservations(c *gin.Context) {
	now := time.Now()
	reservations := []Reservation{
		{
			ID:           uuid.New().String(),
			FacilityName: "Spor Salonu",
			ResidentName: "Zeynep Kaya",
			StartTime:    now,
			EndTime:      now.Add(time.Hour),
			Status:       "APPROVED",
		},
	}
	c.JSON(http.StatusOK, gin.H{"reservations": reservations})
}

func getCalendarView(c *gin.Context) {
	// Query params: facility_id, start_date, end_date
	c.JSON(http.StatusOK, gin.H{
		"events": []map[string]interface{}{
			{
				"id":          uuid.New().String(),
				"facility_id": "fac-1",
				"title":       "Havuz - Ali V.",
				"start":       time.Now().Format(time.RFC3339),
				"end":         time.Now().Add(2 * time.Hour).Format(time.RFC3339),
				"status":      "APPROVED",
				"color":       "#4CAF50",
			},
		},
	})
}

func getReservation(c *gin.Context) {
	id := c.Param("id")
	now := time.Now()
	reservation := Reservation{
		ID:              id,
		FacilityID:      "fac-1",
		FacilityName:    "Yüzme Havuzu",
		UnitID:          "unit-101",
		ResidentID:      "res-1",
		ResidentName:    "Ali Veli",
		StartTime:       now.Add(2 * time.Hour),
		EndTime:         now.Add(4 * time.Hour),
		DurationMinutes: 120,
		GuestCount:      4,
		Purpose:         "Aile etkinliği",
		Status:          "APPROVED",
		TotalFee:        100.00,
		PaymentStatus:   "PAID",
		CreatedAt:       now,
	}
	c.JSON(http.StatusOK, reservation)
}

func createReservation(c *gin.Context) {
	var req ReservationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	now := time.Now()
	reservation := Reservation{
		ID:           uuid.New().String(),
		FacilityID:   req.FacilityID,
		FacilityName: "Yüzme Havuzu",
		Status:       "PENDING",
		GuestCount:   req.GuestCount,
		Purpose:      req.Purpose,
		TotalFee:     100.00,
		CreatedAt:    now,
	}

	c.JSON(http.StatusCreated, reservation)
}

func updateReservation(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Rezervasyon güncellendi"})
}

func cancelReservation(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":            id,
		"status":        "CANCELLED",
		"refund_amount": 100.00,
		"message":       "Rezervasyon iptal edildi",
	})
}

func reviewReservation(c *gin.Context) {
	id := c.Param("id")
	var req ReviewRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	status := "APPROVED"
	if req.Action == "REJECT" {
		status = "REJECTED"
	}

	c.JSON(http.StatusOK, gin.H{
		"id":          id,
		"status":      status,
		"reviewed_at": time.Now(),
		"message":     "Rezervasyon değerlendirildi",
	})
}

func completeReservation(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{
		"id":      id,
		"status":  "COMPLETED",
		"message": "Rezervasyon tamamlandı",
	})
}

func getUnitReservations(c *gin.Context) {
	unitID := c.Param("unit_id")
	c.JSON(http.StatusOK, gin.H{"unit_id": unitID, "reservations": []Reservation{}})
}

func getResidentReservations(c *gin.Context) {
	residentID := c.Param("resident_id")
	c.JSON(http.StatusOK, gin.H{"resident_id": residentID, "reservations": []Reservation{}})
}
