// visitor-service — Ziyaretçi kayıt ve giriş/çıkış takibi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; artık gerçek veri katmanına
// bağlıdır (FAZ 5 — 3/22).
//
// Mahremiyet kuralı: Ziyaretçi kaydı, ziyaret edilen kişi hakkında da bilgi üretir.
// Bu yüzden:
//   - Yönetim ve görevli personel sitedeki tüm ziyaretçileri görür (güvenlik görevi).
//   - Sakin YALNIZCA kendi bağımsız bölümüne ait ziyaretçileri görür.
//   - Kimlik numarası liste yanıtlarında maskelenir.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/visitor/models"
	"github.com/siteeksen/backend/services/visitor/repository"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	repo := repository.New(pool)

	r := gin.Default()
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "visitor", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(), middleware.AuditLog(pool, "visitor"))

	api.GET("/visitors", func(c *gin.Context) {
		propertyID := c.GetString("property_id")

		// Güvenlik görevi olan roller siteyi bütün olarak görür; diğerleri yalnızca kendi dairesini.
		scopeUser := ""
		if !hasSecurityScope(c) {
			scopeUser = c.GetString("user_id")
		}

		list, err := repo.List(c.Request.Context(), propertyID,
			c.Query("status"), scopeUser, c.Query("inside") == "true")
		if err != nil {
			log.Printf("[visitor] listeleme başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ziyaretçiler alınamadı"})
			return
		}
		if !isManagement(c) {
			for i := range list {
				list[i].VisitorIDNumber = maskID(list[i].VisitorIDNumber)
			}
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	api.GET("/visitors/summary", func(c *gin.Context) {
		if !hasSecurityScope(c) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
			return
		}
		s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			log.Printf("[visitor] özet başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Özet alınamadı"})
			return
		}
		c.JSON(http.StatusOK, s)
	})

	// Ön kayıt: sakin kendi ziyaretçisini kaydedebilir (asıl kullanım senaryosu).
	api.POST("/visitors", func(c *gin.Context) {
		var in models.CreateVisitorInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		var expectedAt *time.Time
		if in.ExpectedAt != "" {
			t, perr := time.Parse(time.RFC3339, in.ExpectedAt)
			if perr != nil {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": "expected_at RFC3339 biçiminde olmalıdır (örn. 2026-07-01T14:00:00Z)"})
				return
			}
			expectedAt = &t
		}

		id, err := repo.Create(c.Request.Context(), c.GetString("property_id"),
			c.GetString("user_id"), in, expectedAt)
		if err != nil {
			if errors.Is(err, repository.ErrUnitNotInSite) {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}
			log.Printf("[visitor] oluşturma başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ziyaretçi kaydı oluşturulamadı"})
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"id":     id,
			"status": models.StatusExpected,
			// Bildirim altyapısı henüz yok; kullanıcıya SMS/QR gönderildiği İDDİA EDİLMEZ.
			"note": "Kayıt oluşturuldu. Ziyaretçiye otomatik bildirim (SMS/QR) gönderimi " +
				"henüz devrede değildir; görevliye bilgi veriniz.",
		})
	})

	// Giriş/çıkış yalnızca güvenlik yetkisi olan rollerde.
	guard := api.Group("")
	guard.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		guard.POST("/visitors/:id/check-in", func(c *gin.Context) {
			err := repo.CheckIn(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"))
			if err != nil {
				mapStateError(c, err)
				return
			}
			c.JSON(http.StatusOK, gin.H{"message": "Ziyaretçi girişi kaydedildi"})
		})
		guard.POST("/visitors/:id/check-out", func(c *gin.Context) {
			err := repo.CheckOut(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"))
			if err != nil {
				mapStateError(c, err)
				return
			}
			c.JSON(http.StatusOK, gin.H{"message": "Ziyaretçi çıkışı kaydedildi"})
		})
	}

	api.POST("/visitors/:id/cancel", func(c *gin.Context) {
		if err := repo.Cancel(c.Request.Context(), c.GetString("property_id"), c.Param("id")); err != nil {
			mapStateError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Ziyaretçi kaydı iptal edildi"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8105"
	}
	log.Printf("Visitor Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// maskID, kimlik numarasını maskeler.
func maskID(v string) string {
	if len(v) < 5 {
		return ""
	}
	return v[:3] + "*****" + v[len(v)-2:]
}

func hasSecurityScope(c *gin.Context) bool {
	return hasAnyRole(c, middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleStaff, middleware.RoleSuperAdmin)
}

func isManagement(c *gin.Context) bool {
	return hasAnyRole(c, middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleSuperAdmin)
}

func hasAnyRole(c *gin.Context, want ...string) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		for _, w := range want {
			if r == w {
				return true
			}
		}
	}
	return false
}

func mapStateError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{"error": "Ziyaretçi bu işlem için uygun durumda değil"})
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Ziyaretçi kaydı bulunamadı"})
	default:
		log.Printf("[visitor] durum değişikliği başarısız: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
