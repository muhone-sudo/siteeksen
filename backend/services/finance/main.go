package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/finance/handlers"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

func main() {
	// Veritabanı bağlantısı
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	// Repository ve Service
	financeRepo := repository.NewFinanceRepository(pool)
	financeService := service.NewFinanceService(financeRepo)

	// Gin router
	r := gin.Default()

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "finance"})
	})

	// Protected routes
	api := r.Group("/api/v1/finance")
	api.Use(middleware.AuthMiddleware())
	{
		// Borç durumu
		api.GET("/debt-status", handlers.GetDebtStatus(financeService))
		
		// Aidatlar
		api.GET("/assessments", handlers.GetAssessments(financeService))
		api.GET("/assessments/:id", handlers.GetAssessmentDetails(financeService))
		
		// Ödemeler
		api.POST("/payments", handlers.CreatePayment(financeService))
		api.GET("/payments", handlers.GetPaymentHistory(financeService))
		
		// Tüketim
		api.GET("/consumption/summary", handlers.GetConsumptionSummary(financeService))
	}

	// Sunucuyu başlat
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}
	log.Printf("Finance Service başlatıldı: :%s", port)
	r.Run(":" + port)
}
