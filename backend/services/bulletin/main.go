// bulletin-service — Sakin ilan panosu (satılık/kiralık, kayıp eşya, yardım,
// araç paylaşımı, etkinlik…).
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit ilan listesi
// döndürüyor ve yazma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 15/22).
//
// Duyuru ile ilan farklı şeylerdir:
//   - DUYURU (community servisi): yönetim yayımlar, onay gerektirmez.
//   - İLAN (bu servis): sakin verir ve YÖNETİM ONAYINDAN geçer.
//
// Onay neden zorunlu: onaysız yayın, sitenin panosunu denetimsiz bir ilan
// alanına çevirir ve yönetimi içerikten sorumlu bırakır. Reddin gerekçesi de
// zorunludur; aksi hâlde sakin ilanını düzeltemez.
//
// KVKK: anonim ilanda ilan sahibinin adı ve bağımsız bölümü DİĞER SAKİNLERE
// gösterilmez. Kayıt yine de kullanıcıya bağlıdır (onay ve sorumluluk için);
// bu sınır kullanıcıya açıkça bildirilir.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/bulletin/repository"
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
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "bulletin", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "bulletin"))

	api.GET("/bulletins", func(c *gin.Context) {
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
			c.GetString("user_id"), c.Query("category"), c.Query("status"),
			isManagement(c), c.Query("mine") == "true")
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "categories": repository.Categories})
	})

	api.GET("/bulletins/:id", func(c *gin.Context) {
		p, err := repo.Get(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), isManagement(c))
		if err != nil {
			fail(c, err, "okuma")
			return
		}
		resp := gin.H{"post": p}
		if p.IsAnonymous {
			resp["anonymity_note"] = "İlan anonimdir: ilan sahibinin adı ve bağımsız " +
				"bölümü diğer sakinlere gösterilmez. Kayıt, onay ve sorumluluk için " +
				"yine de kullanıcıya bağlıdır — bu, mutlak anonimlik değildir."
		}
		c.JSON(http.StatusOK, resp)
	})

	api.POST("/bulletins", func(c *gin.Context) {
		var in repository.CreateInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":      "category, title ve content zorunludur",
				"categories": repository.Categories})
			return
		}
		id, err := repo.Create(c.Request.Context(),
			c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			fail(c, err, "oluşturma")
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"id": id, "status": "PENDING",
			"note": "İlan YÖNETİM ONAYINA gönderildi; onaylanana kadar panoda " +
				"görünmez. Yöneticiye BİLDİRİM GÖNDERİLMEDİ.",
		})
	})

	api.POST("/bulletins/:id/close", func(c *gin.Context) {
		if err := repo.Close(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), isManagement(c)); err != nil {
			fail(c, err, "kapatma")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status": "CLOSED",
			"note":   "İlan kapatıldı; kayıt ve yorumlar silinmedi.",
		})
	})

	// --- Yorumlar ---
	api.GET("/bulletins/:id/comments", func(c *gin.Context) {
		// Onaylanmamış ilanın yorumları yalnızca sahibine ve yönetime görünür.
		// Önceden denetim yoktu: başkasının bekleyen ilanının yorumları okunabiliyordu.
		if err := repo.Visible(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), isManagement(c)); err != nil {
			fail(c, err, "ilan okuma")
			return
		}
		list, err := repo.Comments(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"))
		if err != nil {
			fail(c, err, "yorum listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	api.POST("/bulletins/:id/comments", func(c *gin.Context) {
		var in struct {
			Content     string `json:"content" binding:"required"`
			IsAnonymous bool   `json:"is_anonymous"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "content zorunludur"})
			return
		}
		id, err := repo.AddComment(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), in.Content, in.IsAnonymous)
		if err != nil {
			fail(c, err, "yorum")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id})
	})

	api.DELETE("/bulletin-comments/:id", func(c *gin.Context) {
		if err := repo.DeleteComment(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), isManagement(c)); err != nil {
			fail(c, err, "yorum silme")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Yorum kaldırıldı",
			"note":    "Kayıt SİLİNMEDİ, gizlendi; kimin ne yazdığı denetim için korunur.",
		})
	})

	// --- Yönetim: onay/ret ---
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/bulletins/:id/approve", func(c *gin.Context) {
			if err := repo.Review(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), "APPROVED", ""); err != nil {
				fail(c, err, "onay")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status": "APPROVED",
				"note":   "İlan sahibine BİLDİRİM GÖNDERİLMEDİ.",
			})
		})

		write.POST("/bulletins/:id/reject", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Red gerekçesi zorunludur",
					"note":  "Gerekçesiz ret, sakinin ilanını düzeltmesini imkânsız kılar."})
				return
			}
			if err := repo.Review(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), "REJECTED", in.Reason); err != nil {
				fail(c, err, "ret")
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": "REJECTED"})
		})

		write.POST("/bulletins/expire-due", func(c *gin.Context) {
			n, err := repo.ExpirePosts(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "süre dolumu")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"expired_count": n,
				"note":          "Zamanlanmış görev altyapısı yoktur; bu uç elle tetiklenir.",
			})
		})

		write.GET("/bulletins-summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			c.JSON(http.StatusOK, s)
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8089" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Bulletin Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

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

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "İlan bulunamadı"})
	case errors.Is(err, repository.ErrInvalidCategory):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz kategori ya da tarih", "categories": repository.Categories})
	case errors.Is(err, repository.ErrNoUnit):
		c.JSON(http.StatusForbidden, gin.H{
			"error": "İlan verebilmek için sitede aktif bir bağımsız bölümünüz olmalıdır"})
	case errors.Is(err, repository.ErrNotApproved):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Yayımlanmamış ilana yorum yapılamaz"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{
			"error": "İlan bu işlem için uygun durumda değil ya da size ait değil"})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[bulletin] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
