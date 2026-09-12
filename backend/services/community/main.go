package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/stub"
	"github.com/siteeksen/backend/services/community/handlers"
	"github.com/siteeksen/backend/services/community/repository"
	"github.com/siteeksen/backend/services/community/service"
)

func main() {
	// Veritabanı bağlantısı (talepler modülü gerçek DB'ye bağlı; diğer modüller henüz uygulanmadı)
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	requestRepo := repository.NewRequestRepository(pool)
	requestService := service.NewRequestService(requestRepo)

	r := gin.Default()

	// Health check — hangi modülün gerçek olduğunu açıkça bildirir.
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "community",
			"modules": gin.H{
				"requests":      "persistent",
				"announcements": "not_implemented",
				"surveys":       "not_implemented",
				"bulletins":     "not_implemented",
				"reservations":  "not_implemented",
			},
		})
	})

	// Requests (gerçek DB'ye bağlı)
	requests := r.Group("/api/v1/requests")
	requests.Use(middleware.AuthMiddleware(), middleware.AuditLog(pool, "request"))
	{
		requests.GET("", handlers.ListRequests(requestService))
		requests.POST("", handlers.CreateRequest(requestService))
		requests.PATCH("/:id/status", handlers.UpdateRequestStatus(requestService))
		requests.POST("/:id/confirm-resolution", handlers.ConfirmRequestResolution(requestService))
	}

	// --------------------------------------------------------------------
	// Henüz uygulanmamış modüller.
	//
	// Bu dört modül (duyuru, anket, ilan, rezervasyon) daha önce uydurma veri
	// döndürüyor, yazma isteklerine 201/200 dönüp hiçbir yere kaydetmiyor ve
	// üstelik KİMLİK DOĞRULAMASI OLMADAN erişilebiliyordu (herkes duyuru
	// oluşturabilir/silebilirdi). İkisi de düzeltildi:
	//   1) Tüm uçlar AuthMiddleware arkasına alındı.
	//   2) Tüm uçlar 501 döndürüyor (tasks/dogrulama-politikasi.md §3.5).
	// Gerçek uygulamaya geçildikçe bu gruplar tek tek kaldırılacaktır.
	// --------------------------------------------------------------------
	notImpl := r.Group("/api/v1")
	notImpl.Use(middleware.AuthMiddleware())
	{
		announcements := notImpl.Group("/announcements")
		{
			announcements.GET("", stub.Handler("community.announcements"))
			announcements.GET("/:id", stub.Handler("community.announcements"))
			announcements.POST("", stub.Handler("community.announcements"))
			announcements.PUT("/:id", stub.Handler("community.announcements"))
			announcements.DELETE("/:id", stub.Handler("community.announcements"))
			announcements.POST("/:id/pin", stub.Handler("community.announcements"))
			announcements.POST("/:id/read", stub.Handler("community.announcements"))
		}

		surveys := notImpl.Group("/surveys")
		{
			surveys.GET("", stub.Handler("community.surveys"))
			surveys.GET("/:id", stub.Handler("community.surveys"))
			surveys.POST("", stub.Handler("community.surveys"))
			surveys.POST("/:id/vote", stub.Handler("community.surveys"))
			surveys.GET("/:id/results", stub.Handler("community.surveys"))
		}

		bulletins := notImpl.Group("/bulletins")
		{
			bulletins.GET("", stub.Handler("community.bulletins"))
			bulletins.POST("", stub.Handler("community.bulletins"))
			bulletins.DELETE("/:id", stub.Handler("community.bulletins"))
		}

		reservations := notImpl.Group("/reservations")
		{
			reservations.GET("/facilities", stub.Handler("community.reservations"))
			reservations.GET("/facilities/:id/slots", stub.Handler("community.reservations"))
			reservations.POST("", stub.Handler("community.reservations"))
			reservations.GET("", stub.Handler("community.reservations"))
			reservations.DELETE("/:id", stub.Handler("community.reservations"))
		}
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8083"
	}

	log.Printf("Community Service starting on port %s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
