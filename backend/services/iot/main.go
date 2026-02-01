package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "iot"})
	})

	// Meters
	meters := r.Group("/api/v1/meters")
	{
		meters.GET("", listMeters)
		meters.GET("/:id", getMeter)
		meters.POST("/:id/readings", submitReading)
		meters.GET("/:id/readings", getReadingHistory)
		meters.GET("/:id/consumption", getConsumption)
	}

	// Sensors
	sensors := r.Group("/api/v1/sensors")
	{
		sensors.GET("", listSensors)
		sensors.GET("/:id", getSensor)
		sensors.GET("/:id/data", getSensorData)
		sensors.POST("/:id/data", ingestSensorData) // IoT cihazlardan veri alımı
	}

	// Alerts
	alerts := r.Group("/api/v1/iot/alerts")
	{
		alerts.GET("", listAlerts)
		alerts.POST("/:id/acknowledge", acknowledgeAlert)
	}

	// Consumption Reports
	r.GET("/api/v1/consumption/summary", getConsumptionSummary)
	r.GET("/api/v1/consumption/comparison", getConsumptionComparison)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8084"
	}

	log.Printf("IoT Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// ============ METERS ============

func listMeters(c *gin.Context) {
	meterType := c.Query("type") // HEAT, WATER_COLD, WATER_HOT, ELECTRIC, GAS
	
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":           "mtr-001",
				"type":         "HEAT",
				"unit_id":      "unit-001",
				"unit_name":    "A Blok Daire 1",
				"serial_number": "HM-2024-00001",
				"last_reading": 1234.56,
				"last_read_at": "2026-01-31T10:00:00Z",
			},
			{
				"id":           "mtr-002",
				"type":         "WATER_COLD",
				"unit_id":      "unit-001",
				"unit_name":    "A Blok Daire 1",
				"serial_number": "WC-2024-00001",
				"last_reading": 45.2,
				"last_read_at": "2026-01-31T10:00:00Z",
			},
		},
		"filter": meterType,
	})
}

func getMeter(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"id":            c.Param("id"),
		"type":          "HEAT",
		"serial_number": "HM-2024-00001",
		"installed_at":  "2024-01-15",
	})
}

func submitReading(c *gin.Context) {
	var input struct {
		Value     float64 `json:"value" binding:"required"`
		ReadAt    string  `json:"read_at"`
		ImageURL  string  `json:"image_url"` // Sayaç fotoğrafı
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":          "reading-new",
		"meter_id":    c.Param("id"),
		"value":       input.Value,
		"consumption": 12.5, // Önceki okumadan fark
		"message":     "Okuma kaydedildi",
	})
}

func getReadingHistory(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"meter_id": c.Param("id"),
		"readings": []gin.H{
			{"period": "2026-01", "value": 1234.56, "consumption": 12.5},
			{"period": "2025-12", "value": 1222.06, "consumption": 11.2},
			{"period": "2025-11", "value": 1210.86, "consumption": 10.8},
		},
	})
}

func getConsumption(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"meter_id":      c.Param("id"),
		"current_month": 12.5,
		"last_month":    11.2,
		"year_total":    145.6,
		"unit_price":    8.50,
		"current_cost":  106.25,
	})
}

// ============ SENSORS ============

func listSensors(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":          "sensor-001",
				"type":        "TEMPERATURE",
				"location":    "Kazan Dairesi",
				"last_value":  65.2,
				"unit":        "°C",
				"status":      "ONLINE",
				"last_update": time.Now().Add(-5 * time.Minute).Format(time.RFC3339),
			},
			{
				"id":          "sensor-002",
				"type":        "HUMIDITY",
				"location":    "Bodrum",
				"last_value":  45.0,
				"unit":        "%",
				"status":      "ONLINE",
				"last_update": time.Now().Add(-3 * time.Minute).Format(time.RFC3339),
			},
		},
	})
}

func getSensor(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"id":       c.Param("id"),
		"type":     "TEMPERATURE",
		"location": "Kazan Dairesi",
		"min_threshold": 50.0,
		"max_threshold": 80.0,
	})
}

func getSensorData(c *gin.Context) {
	// Son 24 saat verisi
	c.JSON(http.StatusOK, gin.H{
		"sensor_id": c.Param("id"),
		"data": []gin.H{
			{"timestamp": time.Now().Add(-1 * time.Hour).Format(time.RFC3339), "value": 64.5},
			{"timestamp": time.Now().Add(-2 * time.Hour).Format(time.RFC3339), "value": 65.0},
			{"timestamp": time.Now().Add(-3 * time.Hour).Format(time.RFC3339), "value": 65.2},
		},
	})
}

func ingestSensorData(c *gin.Context) {
	// IoT cihazlardan veri alımı (MQTT/HTTP)
	var input struct {
		Value     float64 `json:"value" binding:"required"`
		Timestamp string  `json:"timestamp"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Threshold kontrolü ve alert oluşturma
	c.JSON(http.StatusCreated, gin.H{"status": "ingested"})
}

// ============ ALERTS ============

func listAlerts(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"data": []gin.H{
			{
				"id":         "alert-001",
				"sensor_id":  "sensor-001",
				"type":       "HIGH_TEMPERATURE",
				"message":    "Kazan sıcaklığı eşik değeri aştı: 82°C",
				"severity":   "WARNING",
				"created_at": time.Now().Add(-30 * time.Minute).Format(time.RFC3339),
				"acknowledged": false,
			},
		},
	})
}

func acknowledgeAlert(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Alert onaylandı"})
}

// ============ CONSUMPTION REPORTS ============

func getConsumptionSummary(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"period": "2026-01",
		"summary": gin.H{
			"heat": gin.H{
				"total":    1250.5,
				"unit":     "GJ",
				"cost":     10629.25,
				"avg_unit": 10.08,
			},
			"water_cold": gin.H{
				"total":    4520.0,
				"unit":     "m³",
				"cost":     31640.00,
				"avg_unit": 36.45,
			},
			"water_hot": gin.H{
				"total":    1850.0,
				"unit":     "m³",
				"cost":     22200.00,
				"avg_unit": 14.92,
			},
		},
	})
}

func getConsumptionComparison(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"unit_id": c.Query("unit_id"),
		"comparison": gin.H{
			"your_consumption": 12.5,
			"building_average": 10.2,
			"difference":       "+22.5%",
			"rank":             "85/124", // Sıralama
		},
	})
}
