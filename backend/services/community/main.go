package main

import (
	"errors"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
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
	announcementRepo := repository.NewAnnouncementRepository(pool)

	r := gin.Default()

	// Health check — hangi modülün gerçek olduğunu açıkça bildirir.
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "community",
			"modules": gin.H{
				"requests":      "persistent",
				"announcements": "persistent",
				"surveys":       "moved:survey-service",
				"bulletins":     "moved:bulletin-service",
				"reservations":  "moved:reservation-service",
			},
		})
	})

	// Requests (gerçek DB'ye bağlı)
	requests := r.Group("/api/v1/requests")
	requests.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "request"))
	{
		requests.GET("", handlers.ListRequests(requestService))
		requests.POST("", handlers.CreateRequest(requestService))
		requests.PATCH("/:id/status", handlers.UpdateRequestStatus(requestService))
		requests.POST("/:id/confirm-resolution", handlers.ConfirmRequestResolution(requestService))
	}

	// --------------------------------------------------------------------
	// Duyurular — GERÇEK veri katmanı (2026-09-13).
	//
	// Önceki durum: uydurma veri döndürüyor, yazma isteklerine 2xx dönüp hiçbir
	// yere kaydetmiyor ve KİMLİK DOĞRULAMASI OLMADAN erişilebiliyordu.
	//
	// Duyuru ile sakin ilanı (bulletin) farklı şeylerdir: duyuruyu yönetim
	// yayımlar, onay gerektirmez; ilanı sakin verir ve yönetim onayından geçer.
	// --------------------------------------------------------------------
	ann := r.Group("/api/v1/announcements")
	ann.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "announcement"))
	{
		ann.GET("", func(c *gin.Context) {
			list, err := announcementRepo.List(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"),
				isManagement(c), c.Query("include_expired") == "true", c.Query("category"))
			if err != nil {
				failAnnouncement(c, err, "listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		ann.GET("/:id", func(c *gin.Context) {
			a, err := announcementRepo.Get(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), isManagement(c))
			if err != nil {
				failAnnouncement(c, err, "okuma")
				return
			}
			c.JSON(http.StatusOK, a)
		})

		// Okundu işareti sakinin kendi eylemidir; tekrarlanabilir.
		ann.POST("/:id/read", func(c *gin.Context) {
			if err := announcementRepo.MarkRead(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), c.GetString("user_id")); err != nil {
				failAnnouncement(c, err, "okundu işareti")
				return
			}
			c.JSON(http.StatusOK, gin.H{"message": "Duyuru okundu olarak işaretlendi"})
		})
	}

	annWrite := r.Group("/api/v1/announcements")
	annWrite.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "announcement"),
		middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		annWrite.POST("", func(c *gin.Context) {
			var in repository.CreateAnnouncementInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":      "title ve content zorunludur",
					"categories": repository.AnnouncementCategories,
					"priorities": repository.AnnouncementPriorities})
				return
			}
			id, err := announcementRepo.Create(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"), in)
			if err != nil {
				failAnnouncement(c, err, "oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id,
				"note": "Duyuru yayımlandı. Sakinlere BİLDİRİM GÖNDERİLMEDİ; bildirim " +
					"istenirse notification servisinden ayrıca kuyruğa alınmalıdır.",
			})
		})

		annWrite.POST("/:id/pin", func(c *gin.Context) {
			var in struct {
				Pinned *bool `json:"pinned"`
			}
			_ = c.ShouldBindJSON(&in)
			pinned := true
			if in.Pinned != nil {
				pinned = *in.Pinned
			}
			if err := announcementRepo.Pin(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), pinned); err != nil {
				failAnnouncement(c, err, "sabitleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"is_pinned": pinned})
		})

		// Okunma istatistiği: acil bir duyurunun kimlere ulaştığının tek kanıtı.
		annWrite.GET("/:id/read-stats", func(c *gin.Context) {
			s, err := announcementRepo.ReadStats(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"))
			if err != nil {
				failAnnouncement(c, err, "okunma istatistiği")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"stats": s,
				"note": "Okunma sayısı yalnızca uygulamayı açıp duyuruyu görüntüleyenleri " +
					"kapsar; duyurunun sakine FİİLEN ULAŞTIĞININ kanıtı değildir.",
			})
		})
	}

	// --------------------------------------------------------------------
	// Başka servise TAŞINAN modüller.
	//
	// Anket, ilan ve rezervasyon artık kendi servislerinde GERÇEK veri
	// katmanıyla çalışıyor. Buradaki uçlar, eski istemcileri sessizce yanlış
	// yere götürmemek için 501 döndürmeye devam eder — ama nereye gidileceğini
	// söyleyerek.
	// --------------------------------------------------------------------
	moved := r.Group("/api/v1")
	moved.Use(middleware.AuthMiddleware(pool))
	{
		for _, m := range []struct{ path, service string }{
			{"/surveys", "survey-service"},
			{"/bulletins", "bulletin-service"},
			{"/reservations", "reservation-service"},
		} {
			svc := m.service
			g := moved.Group(m.path)
			handler := func(c *gin.Context) {
				c.JSON(http.StatusNotImplemented, gin.H{
					"error":   "Bu modül community servisinden taşındı",
					"service": svc,
					"note": "İstek İŞLENMEDİ. Aynı işlevi " + svc + " üzerinden " +
						"kullanın; orada gerçek veri katmanı vardır.",
				})
			}
			g.Any("", handler)
			g.Any("/:id", handler)
			g.Any("/:id/*rest", handler)
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

// isManagement, isteği yapanın yönetim/denetim yetkisi olup olmadığını söyler.
func isManagement(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleAuditor, middleware.RoleSuperAdmin:
			return true
		}
	}
	return false
}

func failAnnouncement(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrAnnouncementNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Duyuru bulunamadı"})
	case errors.Is(err, repository.ErrInvalidAnnouncement):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error":      "Geçersiz kategori, öncelik ya da tarih",
			"categories": repository.AnnouncementCategories,
			"priorities": repository.AnnouncementPriorities})
	default:
		log.Printf("[community/announcement] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
