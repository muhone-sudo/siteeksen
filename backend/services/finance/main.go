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

	// -----------------------------------------------------------------------
	// Korumalı uçlar
	//
	// YETKİLENDİRME (2026-09-13, todo 2.9 / gap-analizi B28):
	// Bu servis daha önce yalnızca "giriş yapmış olma" şartı arıyordu. Sonuç:
	// herhangi bir sakin, sitedeki TÜM DAİRELERİN borç listesini (`/debtors`),
	// tüm ödemeleri (`/payments`) ve dönem özetlerini görebiliyordu. Bunlar
	// yönetim bilgisidir; KVKK açısından da gereğinden fazla veri paylaşımıdır.
	//
	// Ayrım:
	//   - SAKİN uçları: kişinin KENDİ borcu, KENDİ tahakkukları, KENDİ ödemesi.
	//   - YÖNETİM uçları: site geneli listeler ve tahakkuk oluşturma.
	//     MANAGER (yönetici), BOARD_MEMBER (yönetim kurulu) ve AUDITOR (denetçi)
	//     erişebilir; AUDITOR yalnızca okuma uçlarında yer alır (KMK m.41 denetim
	//     görevi okumayı gerektirir, tahakkuk oluşturmayı değil).
	// -----------------------------------------------------------------------
	api := r.Group("/api/v1/finance")
	api.Use(middleware.AuthMiddleware(), middleware.AuditLog(pool, "finance"))
	{
		// --- Sakinin kendi verisi ---
		api.GET("/debt-status", handlers.GetDebtStatus(financeService))
		api.GET("/assessments", handlers.GetAssessments(financeService))
		api.GET("/assessments/:id", handlers.GetAssessmentDetails(financeService))
		api.POST("/payments", handlers.CreatePayment(financeService))
		api.GET("/consumption/summary", handlers.GetConsumptionSummary(financeService))

		// --- Yönetim: site geneli okuma ---
		mgmtRead := api.Group("")
		mgmtRead.Use(middleware.RequireRole(
			middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
		{
			mgmtRead.GET("/debtors", handlers.GetDebtors(financeService))
			mgmtRead.GET("/payments", handlers.GetPaymentHistory(financeService))
			mgmtRead.GET("/assessments/overview", handlers.GetAssessmentOverview(financeService))
			mgmtRead.GET("/expense-categories", handlers.GetExpenseCategories(financeService))
		}

		// --- Yönetim: yazma (denetçi hariç) ---
		mgmtWrite := api.Group("")
		mgmtWrite.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
		{
			mgmtWrite.POST("/assessments", handlers.CreateAssessment(financeService))
		}
	}

	// Sunucuyu başlat
	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}
	log.Printf("Finance Service başlatıldı: :%s", port)
	r.Run(":" + port)
}
