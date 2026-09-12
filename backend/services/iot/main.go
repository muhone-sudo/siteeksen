package main

import (
	"log"
	"os"

	"github.com/siteeksen/backend/pkg/stub"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// Health check
	r.GET("/health", stub.Health("iot"))

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

func listMeters(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getMeter(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func submitReading(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getReadingHistory(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getConsumption(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

// ============ SENSORS ============

func listSensors(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getSensor(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getSensorData(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func ingestSensorData(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

// ============ ALERTS ============

func listAlerts(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func acknowledgeAlert(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

// ============ CONSUMPTION REPORTS ============

func getConsumptionSummary(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}

func getConsumptionComparison(c *gin.Context) { // STUB: gercek veri katmani yok
	stub.NotImplemented(c, "iot")
}
