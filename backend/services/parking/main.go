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

type Vehicle struct {
	ID          string    `json:"id"`
	PropertyID  string    `json:"property_id"`
	UnitID      string    `json:"unit_id,omitempty"`
	OwnerType   string    `json:"owner_type"` // RESIDENT, VISITOR, STAFF
	OwnerID     string    `json:"owner_id,omitempty"`
	OwnerName   string    `json:"owner_name,omitempty"`
	Plate       string    `json:"plate"`
	Brand       string    `json:"brand,omitempty"`
	Model       string    `json:"model,omitempty"`
	Color       string    `json:"color,omitempty"`
	Year        int       `json:"year,omitempty"`
	VehicleType string    `json:"vehicle_type"` // CAR, MOTORCYCLE, TRUCK
	ParkingSpot string    `json:"parking_spot,omitempty"`
	RFIDTag     string    `json:"rfid_tag,omitempty"`
	IsActive    bool      `json:"is_active"`
	IsPrimary   bool      `json:"is_primary"`
	CreatedAt   time.Time `json:"created_at"`
}

type ParkingZone struct {
	ID               string  `json:"id"`
	PropertyID       string  `json:"property_id"`
	Name             string  `json:"name"`
	Description      string  `json:"description,omitempty"`
	Location         string  `json:"location,omitempty"`
	Capacity         int     `json:"capacity"`
	CurrentCount     int     `json:"current_count"`
	AvailableSpots   int     `json:"available_spots"`
	IsPaid           bool    `json:"is_paid"`
	HourlyFee        float64 `json:"hourly_fee,omitempty"`
	DailyFee         float64 `json:"daily_fee,omitempty"`
	IsVisitorAllowed bool    `json:"is_visitor_allowed"`
	IsActive         bool    `json:"is_active"`
}

type ParkingLog struct {
	ID            string     `json:"id"`
	PropertyID    string     `json:"property_id"`
	ParkingZoneID string     `json:"parking_zone_id,omitempty"`
	VehicleID     string     `json:"vehicle_id,omitempty"`
	Plate         string     `json:"plate"`
	EntryAt       time.Time  `json:"entry_at"`
	EntryGate     string     `json:"entry_gate,omitempty"`
	EntryMethod   string     `json:"entry_method,omitempty"` // RFID, PLATE_RECOGNITION, MANUAL
	ExitAt        *time.Time `json:"exit_at,omitempty"`
	ExitGate      string     `json:"exit_gate,omitempty"`
	Duration      int        `json:"duration_minutes,omitempty"`
	CalculatedFee float64    `json:"calculated_fee,omitempty"`
	PaidFee       float64    `json:"paid_fee,omitempty"`
	PaymentStatus string     `json:"payment_status,omitempty"`
	VehicleInfo   *Vehicle   `json:"vehicle_info,omitempty"`
}

type VehicleRequest struct {
	UnitID      string `json:"unit_id"`
	OwnerType   string `json:"owner_type" binding:"required"`
	OwnerName   string `json:"owner_name"`
	Plate       string `json:"plate" binding:"required"`
	Brand       string `json:"brand"`
	Model       string `json:"model"`
	Color       string `json:"color"`
	Year        int    `json:"year"`
	VehicleType string `json:"vehicle_type"`
	ParkingSpot string `json:"parking_spot"`
	RFIDTag     string `json:"rfid_tag"`
}

type ParkingEntryRequest struct {
	Plate         string `json:"plate" binding:"required"`
	ParkingZoneID string `json:"parking_zone_id"`
	EntryGate     string `json:"entry_gate"`
	EntryMethod   string `json:"entry_method"`
	PhotoURL      string `json:"photo_url"`
}

type ParkingExitRequest struct {
	ExitGate string  `json:"exit_gate"`
	PaidFee  float64 `json:"paid_fee"`
}

type ParkingStats struct {
	TotalSpots      int `json:"total_spots"`
	OccupiedSpots   int `json:"occupied_spots"`
	AvailableSpots  int `json:"available_spots"`
	TodayEntries    int `json:"today_entries"`
	TodayExits      int `json:"today_exits"`
	CurrentVehicles int `json:"current_vehicles"`
}

// =====================================================
// HANDLERS
// =====================================================

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "parking",
			"version": "1.0.0",
		})
	})

	v1 := r.Group("/api/v1")
	{
		// Vehicles
		vehicles := v1.Group("/vehicles")
		{
			vehicles.GET("", listVehicles)
			vehicles.GET("/:id", getVehicle)
			vehicles.POST("", createVehicle)
			vehicles.PUT("/:id", updateVehicle)
			vehicles.DELETE("/:id", deleteVehicle)
			vehicles.GET("/plate/:plate", getVehicleByPlate)
			vehicles.GET("/unit/:unit_id", getUnitVehicles)
		}

		// Parking Zones
		zones := v1.Group("/parking-zones")
		{
			zones.GET("", listParkingZones)
			zones.GET("/:id", getParkingZone)
			zones.POST("", createParkingZone)
			zones.PUT("/:id", updateParkingZone)
			zones.DELETE("/:id", deleteParkingZone)
			zones.GET("/:id/vehicles", getZoneVehicles)
		}

		// Parking Logs
		logs := v1.Group("/parking-logs")
		{
			logs.GET("", listParkingLogs)
			logs.GET("/stats", getParkingStats)
			logs.GET("/current", getCurrentVehicles)
			logs.POST("/entry", recordEntry)
			logs.POST("/exit/:id", recordExit)
			logs.GET("/vehicle/:vehicle_id", getVehicleParkingHistory)
		}

		// Plate Recognition (AI)
		v1.POST("/plate-recognition", recognizePlate)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8091"
	}

	log.Printf("Parking Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Vehicle Handlers
func listVehicles(c *gin.Context) {
	vehicles := []Vehicle{
		{
			ID:          uuid.New().String(),
			PropertyID:  "prop-1",
			UnitID:      "unit-101",
			OwnerType:   "RESIDENT",
			OwnerName:   "Ali Veli",
			Plate:       "34 ABC 123",
			Brand:       "Toyota",
			Model:       "Corolla",
			Color:       "Beyaz",
			Year:        2022,
			VehicleType: "CAR",
			ParkingSpot: "A-15",
			IsActive:    true,
			IsPrimary:   true,
			CreatedAt:   time.Now(),
		},
		{
			ID:          uuid.New().String(),
			PropertyID:  "prop-1",
			UnitID:      "unit-205",
			OwnerType:   "RESIDENT",
			OwnerName:   "Ayşe Yılmaz",
			Plate:       "06 DEF 456",
			Brand:       "Honda",
			Model:       "Civic",
			Color:       "Siyah",
			Year:        2021,
			VehicleType: "CAR",
			ParkingSpot: "B-03",
			IsActive:    true,
			IsPrimary:   true,
			CreatedAt:   time.Now(),
		},
	}
	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles, "total": len(vehicles)})
}

func getVehicle(c *gin.Context) {
	id := c.Param("id")
	vehicle := Vehicle{
		ID:          id,
		PropertyID:  "prop-1",
		UnitID:      "unit-101",
		OwnerType:   "RESIDENT",
		OwnerName:   "Ali Veli",
		Plate:       "34 ABC 123",
		Brand:       "Toyota",
		Model:       "Corolla",
		Color:       "Beyaz",
		Year:        2022,
		VehicleType: "CAR",
		ParkingSpot: "A-15",
		IsActive:    true,
		IsPrimary:   true,
		CreatedAt:   time.Now(),
	}
	c.JSON(http.StatusOK, vehicle)
}

func createVehicle(c *gin.Context) {
	var req VehicleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	vehicle := Vehicle{
		ID:          uuid.New().String(),
		PropertyID:  "prop-1",
		UnitID:      req.UnitID,
		OwnerType:   req.OwnerType,
		OwnerName:   req.OwnerName,
		Plate:       req.Plate,
		Brand:       req.Brand,
		Model:       req.Model,
		Color:       req.Color,
		Year:        req.Year,
		VehicleType: req.VehicleType,
		ParkingSpot: req.ParkingSpot,
		RFIDTag:     req.RFIDTag,
		IsActive:    true,
		CreatedAt:   time.Now(),
	}

	c.JSON(http.StatusCreated, vehicle)
}

func updateVehicle(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Araç güncellendi"})
}

func deleteVehicle(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Araç silindi"})
}

func getVehicleByPlate(c *gin.Context) {
	plate := c.Param("plate")
	vehicle := Vehicle{
		ID:        uuid.New().String(),
		Plate:     plate,
		OwnerType: "RESIDENT",
		OwnerName: "Sakin",
		Brand:     "Ford",
		Model:     "Focus",
		IsActive:  true,
	}
	c.JSON(http.StatusOK, vehicle)
}

func getUnitVehicles(c *gin.Context) {
	unitID := c.Param("unit_id")
	vehicles := []Vehicle{
		{
			ID:        uuid.New().String(),
			UnitID:    unitID,
			Plate:     "34 XYZ 789",
			Brand:     "BMW",
			Model:     "320i",
			IsActive:  true,
			IsPrimary: true,
		},
	}
	c.JSON(http.StatusOK, gin.H{"vehicles": vehicles})
}

// Parking Zone Handlers
func listParkingZones(c *gin.Context) {
	zones := []ParkingZone{
		{
			ID:               uuid.New().String(),
			PropertyID:       "prop-1",
			Name:             "A Blok Otoparkı",
			Capacity:         50,
			CurrentCount:     35,
			AvailableSpots:   15,
			IsPaid:           false,
			IsVisitorAllowed: true,
			IsActive:         true,
		},
		{
			ID:               uuid.New().String(),
			PropertyID:       "prop-1",
			Name:             "Misafir Otoparkı",
			Capacity:         20,
			CurrentCount:     8,
			AvailableSpots:   12,
			IsPaid:           true,
			HourlyFee:        25.00,
			DailyFee:         100.00,
			IsVisitorAllowed: true,
			IsActive:         true,
		},
	}
	c.JSON(http.StatusOK, gin.H{"zones": zones})
}

func getParkingZone(c *gin.Context) {
	id := c.Param("id")
	zone := ParkingZone{
		ID:             id,
		Name:           "A Blok Otoparkı",
		Capacity:       50,
		CurrentCount:   35,
		AvailableSpots: 15,
		IsActive:       true,
	}
	c.JSON(http.StatusOK, zone)
}

func createParkingZone(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Otopark bölgesi oluşturuldu"})
}

func updateParkingZone(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Otopark bölgesi güncellendi"})
}

func deleteParkingZone(c *gin.Context) {
	id := c.Param("id")
	c.JSON(http.StatusOK, gin.H{"id": id, "message": "Otopark bölgesi silindi"})
}

func getZoneVehicles(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"vehicles": []Vehicle{}, "count": 0})
}

// Parking Log Handlers
func listParkingLogs(c *gin.Context) {
	now := time.Now()
	exit := now.Add(-2 * time.Hour)

	logs := []ParkingLog{
		{
			ID:            uuid.New().String(),
			Plate:         "34 ABC 123",
			EntryAt:       now.Add(-4 * time.Hour),
			EntryGate:     "Giriş-1",
			EntryMethod:   "RFID",
			ExitAt:        &exit,
			Duration:      120,
			PaymentStatus: "FREE",
		},
		{
			ID:            uuid.New().String(),
			Plate:         "06 XYZ 999",
			EntryAt:       now.Add(-1 * time.Hour),
			EntryGate:     "Giriş-2",
			EntryMethod:   "MANUAL",
			PaymentStatus: "PENDING",
		},
	}
	c.JSON(http.StatusOK, gin.H{"logs": logs})
}

func getParkingStats(c *gin.Context) {
	stats := ParkingStats{
		TotalSpots:      100,
		OccupiedSpots:   65,
		AvailableSpots:  35,
		TodayEntries:    45,
		TodayExits:      38,
		CurrentVehicles: 65,
	}
	c.JSON(http.StatusOK, stats)
}

func getCurrentVehicles(c *gin.Context) {
	now := time.Now()
	logs := []ParkingLog{
		{
			ID:          uuid.New().String(),
			Plate:       "34 ABC 123",
			EntryAt:     now.Add(-2 * time.Hour),
			EntryMethod: "RFID",
			VehicleInfo: &Vehicle{
				OwnerType: "RESIDENT",
				OwnerName: "Ali Veli",
				UnitID:    "unit-101",
			},
		},
	}
	c.JSON(http.StatusOK, gin.H{"vehicles": logs, "count": len(logs)})
}

func recordEntry(c *gin.Context) {
	var req ParkingEntryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	log := ParkingLog{
		ID:          uuid.New().String(),
		Plate:       req.Plate,
		EntryAt:     time.Now(),
		EntryGate:   req.EntryGate,
		EntryMethod: req.EntryMethod,
	}

	c.JSON(http.StatusCreated, log)
}

func recordExit(c *gin.Context) {
	id := c.Param("id")
	var req ParkingExitRequest
	c.ShouldBindJSON(&req)

	now := time.Now()
	c.JSON(http.StatusOK, gin.H{
		"id":             id,
		"exit_at":        now,
		"calculated_fee": 50.00,
		"paid_fee":       req.PaidFee,
		"message":        "Çıkış kaydedildi",
	})
}

func getVehicleParkingHistory(c *gin.Context) {
	vehicleID := c.Param("vehicle_id")
	c.JSON(http.StatusOK, gin.H{
		"vehicle_id": vehicleID,
		"logs":       []ParkingLog{},
	})
}

// Plate Recognition (AI mock)
func recognizePlate(c *gin.Context) {
	// Mock: Gerçekte AI model kullanılacak
	c.JSON(http.StatusOK, gin.H{
		"plate":      "34 ABC 123",
		"confidence": 0.95,
		"vehicle": Vehicle{
			OwnerType: "RESIDENT",
			OwnerName: "Ali Veli",
			UnitID:    "unit-101",
		},
		"action": "ALLOW", // ALLOW, DENY, UNKNOWN
	})
}
