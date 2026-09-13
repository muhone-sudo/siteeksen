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

	r.GET("/health", stub.Health("parking"))

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
		port = "8098"
	}

	log.Printf("Parking Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// Vehicle Handlers
func listVehicles(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getVehicle(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func createVehicle(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func updateVehicle(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func deleteVehicle(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getVehicleByPlate(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getUnitVehicles(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

// Parking Zone Handlers
func listParkingZones(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getParkingZone(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func createParkingZone(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func updateParkingZone(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func deleteParkingZone(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getZoneVehicles(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

// Parking Log Handlers
func listParkingLogs(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getParkingStats(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getCurrentVehicles(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func recordEntry(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func recordExit(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

func getVehicleParkingHistory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}

// Plate Recognition (AI mock)
func recognizePlate(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "parking")
}
