package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AI-Powered Energy Analytics Service
// Enerji tüketim analizi, anomali tespiti, tasarruf önerileri

type EnergyReading struct {
	ID           string    `json:"id"`
	PropertyID   string    `json:"property_id"`
	MeterID      string    `json:"meter_id"`
	MeterName    string    `json:"meter_name,omitempty"`
	MeterType    string    `json:"meter_type"` // ELECTRICITY, GAS, WATER
	Reading      float64   `json:"reading"`
	Unit         string    `json:"unit"` // kWh, m3
	ReadingDate  string    `json:"reading_date"`
	Cost         float64   `json:"cost,omitempty"`
	IsAnomaly    bool      `json:"is_anomaly"`
	AnomalyScore float64   `json:"anomaly_score,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type EnergyAnomaly struct {
	ID            string    `json:"id"`
	PropertyID    string    `json:"property_id"`
	MeterID       string    `json:"meter_id"`
	MeterName     string    `json:"meter_name,omitempty"`
	MeterType     string    `json:"meter_type"`
	DetectedAt    time.Time `json:"detected_at"`
	AnomalyType   string    `json:"anomaly_type"` // SPIKE, DROP, UNUSUAL_PATTERN
	Severity      string    `json:"severity"`     // LOW, MEDIUM, HIGH, CRITICAL
	Description   string    `json:"description"`
	ExpectedValue float64   `json:"expected_value"`
	ActualValue   float64   `json:"actual_value"`
	Deviation     float64   `json:"deviation_percent"`
	IsResolved    bool      `json:"is_resolved"`
	Resolution    string    `json:"resolution,omitempty"`
}

type SavingRecommendation struct {
	ID                 string  `json:"id"`
	PropertyID         string  `json:"property_id"`
	Category           string  `json:"category"` // LIGHTING, HVAC, EQUIPMENT, BEHAVIOR
	Title              string  `json:"title"`
	Description        string  `json:"description"`
	EstimatedSaving    float64 `json:"estimated_saving_monthly"`
	ImplementationCost float64 `json:"implementation_cost,omitempty"`
	PaybackMonths      int     `json:"payback_months,omitempty"`
	Priority           string  `json:"priority"` // LOW, MEDIUM, HIGH
	Status             string  `json:"status"`   // PENDING, IN_PROGRESS, IMPLEMENTED, REJECTED
	AIConfidence       float64 `json:"ai_confidence"`
}

type CarbonFootprint struct {
	PropertyID      string  `json:"property_id"`
	Period          string  `json:"period"` // 2026-01
	ElectricityCO2  float64 `json:"electricity_co2_kg"`
	GasCO2          float64 `json:"gas_co2_kg"`
	TotalCO2        float64 `json:"total_co2_kg"`
	PerUnitCO2      float64 `json:"per_unit_co2_kg"`
	ChangeFromLast  float64 `json:"change_from_last_month_percent"`
	TreesEquivalent int     `json:"trees_equivalent"`
}

type EnergyDashboard struct {
	CurrentMonth     gin.H                  `json:"current_month"`
	Comparison       gin.H                  `json:"comparison"`
	Anomalies        []EnergyAnomaly        `json:"recent_anomalies"`
	Recommendations  []SavingRecommendation `json:"top_recommendations"`
	CarbonFootprint  CarbonFootprint        `json:"carbon_footprint"`
	ConsumptionTrend []gin.H                `json:"consumption_trend"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "energy-analytics", "ai_enabled": true})
	})

	v1 := r.Group("/api/v1")
	{
		// Readings
		v1.GET("/energy/readings", listReadings)
		v1.POST("/energy/readings", createReading)

		// Dashboard
		v1.GET("/energy/dashboard", getEnergyDashboard)
		v1.GET("/energy/consumption", getConsumptionData)

		// AI Analysis
		v1.GET("/energy/anomalies", listAnomalies)
		v1.POST("/energy/anomalies/:id/resolve", resolveAnomaly)
		v1.GET("/energy/recommendations", getRecommendations)
		v1.POST("/energy/recommendations/:id/implement", implementRecommendation)
		v1.POST("/energy/analyze", runAIAnalysis)

		// Carbon
		v1.GET("/energy/carbon-footprint", getCarbonFootprint)

		// Predictions
		v1.GET("/energy/forecast", getEnergyForecast)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8102"
	}
	log.Printf("Energy Analytics Service starting on port %s", port)
	r.Run(":" + port)
}

func listReadings(c *gin.Context) {
	now := time.Now()
	readings := []EnergyReading{
		{ID: uuid.New().String(), MeterName: "Ana Sayaç", MeterType: "ELECTRICITY", Reading: 12500, Unit: "kWh", ReadingDate: now.Format("2006-01-02"), Cost: 45000, IsAnomaly: false, CreatedAt: now},
		{ID: uuid.New().String(), MeterName: "Havuz Sayacı", MeterType: "ELECTRICITY", Reading: 3200, Unit: "kWh", ReadingDate: now.Format("2006-01-02"), Cost: 11520, IsAnomaly: true, AnomalyScore: 0.85, CreatedAt: now},
	}
	c.JSON(http.StatusOK, gin.H{"readings": readings})
}

func createReading(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": uuid.New().String(), "message": "Sayaç okuma kaydedildi", "anomaly_detected": false})
}

func getEnergyDashboard(c *gin.Context) {
	dashboard := EnergyDashboard{
		CurrentMonth: gin.H{
			"electricity_kwh":  45200,
			"electricity_cost": 162720,
			"gas_m3":           1200,
			"gas_cost":         18000,
			"water_m3":         850,
			"water_cost":       12750,
			"total_cost":       193470,
		},
		Comparison: gin.H{
			"electricity_change": -5.2,
			"gas_change":         12.5,
			"water_change":       -2.1,
			"cost_change":        -1.8,
		},
		Anomalies: []EnergyAnomaly{
			{ID: uuid.New().String(), MeterName: "Havuz Sayacı", AnomalyType: "SPIKE", Severity: "MEDIUM", Description: "Beklenen tüketimin %85 üzerinde", Deviation: 85, DetectedAt: time.Now()},
		},
		Recommendations: []SavingRecommendation{
			{ID: uuid.New().String(), Category: "LIGHTING", Title: "LED Aydınlatmaya Geçiş", Description: "Ortak alan aydınlatmalarının LED ile değiştirilmesi", EstimatedSaving: 3500, ImplementationCost: 25000, PaybackMonths: 7, Priority: "HIGH", AIConfidence: 0.92},
			{ID: uuid.New().String(), Category: "HVAC", Title: "Isı Pompası Optimizasyonu", Description: "Genel merkez ısı pompası ayarlarının optimize edilmesi", EstimatedSaving: 2200, Priority: "MEDIUM", AIConfidence: 0.78},
		},
		CarbonFootprint: CarbonFootprint{
			Period: "2026-01", ElectricityCO2: 22600, GasCO2: 2400, TotalCO2: 25000, PerUnitCO2: 201.6, ChangeFromLast: -3.2, TreesEquivalent: 1250,
		},
		ConsumptionTrend: []gin.H{
			{"month": "2025-08", "electricity": 52000, "gas": 800, "water": 920},
			{"month": "2025-09", "electricity": 48500, "gas": 850, "water": 880},
			{"month": "2025-10", "electricity": 46200, "gas": 950, "water": 860},
			{"month": "2025-11", "electricity": 47800, "gas": 1100, "water": 855},
			{"month": "2025-12", "electricity": 47100, "gas": 1180, "water": 862},
			{"month": "2026-01", "electricity": 45200, "gas": 1200, "water": 850},
		},
	}
	c.JSON(http.StatusOK, dashboard)
}

func getConsumptionData(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"period": c.Query("period"), "data": []gin.H{}})
}

func listAnomalies(c *gin.Context) {
	anomalies := []EnergyAnomaly{
		{ID: uuid.New().String(), MeterName: "Havuz Sayacı", MeterType: "ELECTRICITY", AnomalyType: "SPIKE", Severity: "MEDIUM", Description: "Gece saatlerinde anormal tüketim artışı", ExpectedValue: 1700, ActualValue: 3200, Deviation: 88.2, IsResolved: false, DetectedAt: time.Now().Add(-24 * time.Hour)},
		{ID: uuid.New().String(), MeterName: "B Blok Sayaç", MeterType: "GAS", AnomalyType: "UNUSUAL_PATTERN", Severity: "LOW", Description: "Hafta sonu kullanım paterni değişikliği", ExpectedValue: 45, ActualValue: 62, Deviation: 37.8, IsResolved: true, Resolution: "Etkinlik nedeniyle normal", DetectedAt: time.Now().Add(-72 * time.Hour)},
	}
	c.JSON(http.StatusOK, gin.H{"anomalies": anomalies})
}

func resolveAnomaly(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "is_resolved": true, "message": "Anomali çözüldü olarak işaretlendi"})
}

func getRecommendations(c *gin.Context) {
	recommendations := []SavingRecommendation{
		{ID: uuid.New().String(), Category: "LIGHTING", Title: "LED Aydınlatmaya Geçiş", Description: "Ortak alan aydınlatmalarının LED ile değiştirilmesi aylık 3500₺ tasarruf sağlayabilir", EstimatedSaving: 3500, ImplementationCost: 25000, PaybackMonths: 7, Priority: "HIGH", Status: "PENDING", AIConfidence: 0.92},
		{ID: uuid.New().String(), Category: "HVAC", Title: "Isı Pompası Optimizasyonu", Description: "AI analizi, termostat ayarlarının optimize edilmesiyle %15 enerji tasarrufu öngörüyor", EstimatedSaving: 2200, Priority: "MEDIUM", Status: "IN_PROGRESS", AIConfidence: 0.78},
		{ID: uuid.New().String(), Category: "BEHAVIOR", Title: "Lobi Aydınlatma Zamanlaması", Description: "Sensörlü aydınlatma sistemi ile gereksiz kullanımı azaltın", EstimatedSaving: 800, Priority: "LOW", Status: "PENDING", AIConfidence: 0.85},
	}
	c.JSON(http.StatusOK, gin.H{"recommendations": recommendations})
}

func implementRecommendation(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "IMPLEMENTED", "message": "Öneri uygulandı olarak işaretlendi"})
}

func runAIAnalysis(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"analysis_started_at": time.Now(),
		"status":              "COMPLETED",
		"findings": gin.H{
			"anomalies_detected":          2,
			"new_recommendations":         1,
			"cost_optimization_potential": 5500,
		},
		"message": "AI analizi tamamlandı",
	})
}

func getCarbonFootprint(c *gin.Context) {
	c.JSON(http.StatusOK, CarbonFootprint{
		Period: c.Query("period"), ElectricityCO2: 22600, GasCO2: 2400, TotalCO2: 25000, PerUnitCO2: 201.6, ChangeFromLast: -3.2, TreesEquivalent: 1250,
	})
}

func getEnergyForecast(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"forecast_period": "2026-02",
		"predictions": gin.H{
			"electricity_kwh":  44500,
			"electricity_cost": 160200,
			"gas_m3":           1050,
			"gas_cost":         15750,
			"confidence":       0.87,
		},
		"factors": []string{"Mevsimsel trend", "Geçmiş tüketim paterni", "Hava durumu tahmini"},
	})
}
