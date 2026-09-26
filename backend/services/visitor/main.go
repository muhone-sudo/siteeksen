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
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
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

	notifier := notify.FromEnvOrNil(pool)

	r := gin.Default()
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "visitor", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "visitor"))

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
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[visitor] oluşturma başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ziyaretçi kaydı oluşturulamadı"})
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"id":     id,
			"status": models.StatusExpected,
			// ZİYARETÇİYE (site dışı kişiye) SMS/QR gönderimi yoktur: SMS
			// sağlayıcısı sözleşmesi bulunmuyor ve site dışı bir numaraya
			// ileti göndermek 6563 s. Kanun kapsamında ayrıca onay ister.
			// SAKİNE haber verme, ziyaretçi giriş yaptığında yapılır.
			"note": "Kayıt oluşturuldu. Ziyaretçiye SMS/QR GÖNDERİLMEZ. Ziyaretçi " +
				"giriş yaptığında ilgili daireye uygulama içi bildirim düşer.",
		})
	})

	// Giriş/çıkış yalnızca güvenlik yetkisi olan rollerde.
	guard := api.Group("")
	guard.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		guard.POST("/visitors/:id/check-in", func(c *gin.Context) {
			info, err := repo.CheckIn(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"))
			if err != nil {
				mapStateError(c, err)
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message":      "Ziyaretçi girişi kaydedildi",
				"notification": notifyCheckIn(c, notifier, repo, pool, info),
			})
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
		owner := ""
		if !hasSecurityScope(c) {
			owner = c.GetString("user_id")
		}
		if err := repo.Cancel(c.Request.Context(), c.GetString("property_id"), owner, c.Param("id")); err != nil {
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
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[visitor] durum değişikliği başarısız: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// notifyCheckIn, ziyaretçi giriş yaptığında ilgili daireye haber verir.
//
// Neden giriş anında: sakinin bilmesi gereken an, ziyaretçinin KAPIDA
// olduğu andır. Kayıt açıldığında haber vermek (ziyaret saatler sonra
// olabilir) ne güvenlik ne de kolaylık sağlar.
//
// Neden dairenin TÜM sakinleri: kaydı güvenlik görevlisi açmış olabilir;
// yalnızca kaydı açana haber vermek, asıl ziyaret edilen kişiyi atlardı.
// Daire bilgisi yoksa (yönetim ofisi ziyareti) kaydı açan kişiye düşer.
func notifyCheckIn(c *gin.Context, n *notify.Notifier, repo *repository.Repository,
	pool *pgxpool.Pool, info *repository.CheckInInfo) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{
			Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	if info == nil {
		return &notify.BroadcastResult{Note: "Ziyaretçi bilgisi çözülemedi; bildirim oluşturulmadı."}
	}

	propertyID := c.GetString("property_id")
	var recipients []notify.Recipient
	if info.UnitID != "" {
		rs, err := notify.UnitResidents(c.Request.Context(), pool, propertyID, info.UnitID)
		if err != nil {
			log.Printf("[visitor] daire sakinleri alınamadı: %v", err)
			return &notify.BroadcastResult{
				Note: "Daire sakinleri okunamadı; bildirim oluşturulmadı. Giriş kaydedildi."}
		}
		recipients = rs
	}
	if len(recipients) == 0 && info.CreatedBy != "" {
		recipients = []notify.Recipient{{UserID: info.CreatedBy}}
	}

	who := info.VisitorName
	if info.Company != "" {
		who += " (" + info.Company + ")"
	}

	res := n.Broadcast(c.Request.Context(), notify.Message{
		PropertyID: propertyID,
		Channel:    notify.ChannelInApp,
		Category:   notify.CategoryTransactional,
		Topic:      "visitor.checkin",
		Subject:    "Ziyaretçiniz giriş yaptı",
		Body:       who + " adlı ziyaretçi siteye giriş yaptı.",
		Payload: map[string]any{
			"visitor_id": c.Param("id"),
			"unit_id":    info.UnitID,
		},
		DedupeKey: "visitor.checkin:" + c.Param("id"),
		CreatedBy: c.GetString("user_id"),
	}, recipients)

	if res.Sent > 0 {
		if err := repo.MarkResidentNotified(c.Request.Context(), propertyID,
			c.Param("id"), "IN_APP"); err != nil {
			log.Printf("[visitor] bildirim oluştu fakat kayıt işaretlenemedi: %v", err)
			res.Note += " (Uyarı: bildirim oluşturuldu fakat ziyaretçi kaydına işlenemedi.)"
		}
	}
	return res
}
