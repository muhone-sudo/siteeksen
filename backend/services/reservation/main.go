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

	r.GET("/health", stub.Health("reservation"))

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
func listFacilities(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getFacility(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func createFacility(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func updateFacility(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func deleteFacility(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getFacilityAvailability(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getFacilityReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func setMaintenanceMode(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

// Reservation Handlers
func listReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getPendingReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getTodayReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getCalendarView(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func createReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func updateReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func cancelReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func reviewReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func completeReservation(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getUnitReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}

func getResidentReservations(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "reservation")
}
