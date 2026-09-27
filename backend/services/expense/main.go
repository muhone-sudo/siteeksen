// expense-service — Gider ve fatura yönetimi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis, sabit JSON döndüren 22 mock servisten
// biriydi; `pkg/stub` ile dürüstçe 501 döndürmeye çevrilmişti. Bu sürümde GERÇEK
// veri katmanına bağlandı (FAZ 5'in ilk modülü).
//
// Neden ilk bu modül: gider kayıtları hem işletme projesinin (KMK m.37) hem yıllık
// hesap vermenin (m.39) girdisidir; aidat tahakkuku da bu kalemler üzerinden üretilir.
//
// Kapsam:
//   - Gider kaydı, kalem bazlı sınıflandırma, fatura bilgisi
//   - Aidata yansıyan giderlerin bağımsız bölümlere KURUŞ hassasiyetinde paylaştırılması
//     (KMK m.20 dağıtım kuralları; en büyük kalan yöntemi)
//   - Faturasız giderler için onay akışı (denetlenebilirlik)
//   - Dönem bazlı özet (faturalı/faturasız ayrımıyla)
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/expense/handlers"
	"github.com/siteeksen/backend/services/expense/repository"
	"github.com/siteeksen/backend/services/expense/service"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	svc := service.New(repository.New(pool))

	r := middleware.NewRouter("expense")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":     "healthy",
			"service":    "expense",
			"persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "expense"))

	// Okuma: yönetim + denetçi (KMK m.41 denetim görevi giderleri görmeyi gerektirir).
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		read.GET("/expense-categories", handlers.ListCategories(svc))
		read.GET("/expenses", handlers.List(svc))
		read.GET("/expenses/summary", handlers.Summary(svc))
		read.GET("/expenses/:id", handlers.Get(svc))
	}

	// Yazma: yönetici ve kurul üyesi. Denetçi YAZAMAZ (görevler ayrılığı).
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/expenses", handlers.Create(svc))
		write.POST("/expenses/:id/approve", handlers.Approve(svc))
		write.POST("/expenses/:id/reject", handlers.Reject(svc))
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8086"
	}
	log.Printf("Expense Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
