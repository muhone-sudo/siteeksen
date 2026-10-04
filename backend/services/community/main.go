package main

import (
	"errors"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/listcap"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
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

	// Bildirim: duyuru yayımlandığında sakinlere uygulama içi bildirim
	// düşer. Uygulama içi kanalın sağlayıcısı her zaman etkindir (kayıt
	// zaten veritabanındadır), bu yüzden burada "gönderildi" demek
	// gerçeği yansıtır. SMS/e-posta sağlayıcısı yoksa o kanallar
	// kullanılmaz — sahte bir gönderim iddiası üretilmez.
	notifier := notify.FromEnvOrNil(pool)

	r := middleware.NewRouter("community")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())

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
			list, truncated := listcap.Trim(list, 200)
			c.JSON(http.StatusOK, gin.H{"data": list, "truncated": truncated, "limit": 200})
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
			// Duyuru YAYIMLANDI. Bildirim ikincil bir iştir: başarısız
			// olursa duyuru geri alınmaz, ama sonucu gizlenmez de.
			// Yöneticinin "sakinlere ulaştı mı?" sorusunun cevabı yanıtta yazar.
			propertyID := c.GetString("property_id")
			notice := notifyAnnouncement(c, notifier, pool, propertyID, id, in)
			c.JSON(http.StatusCreated, gin.H{"id": id, "notification": notice})
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
			if ok, err := announcementRepo.Exists(c.Request.Context(), c.GetString("property_id"), "announcements", c.Param("id")); err != nil {
				failAnnouncement(c, err, "kayıt denetimi")
				return
			} else if !ok {
				c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
				return
			}
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
			middleware.RoleAuditor:
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
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[community/announcement] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// notifyAnnouncement, yayımlanan duyuruyu sitenin aktif sakinlerine
// uygulama içi bildirim olarak kuyruğa alır.
//
// Neden yanıtın içinde raporlanıyor: bildirimi sessizce denemek, "duyuru
// yayımlandı" yazıp kimseye ulaşmamak demektir. Yönetici, kaç kişiye
// ulaşıldığını ve ulaşılamayanların NEDEN ulaşılamadığını görmelidir.
//
// Neden duyuru geri alınmıyor: duyurunun kendisi kalıcı kayıttır ve panoda
// görünür. Bildirim gönderilemedi diye duyuruyu silmek, asıl işi ikincil
// işin başarısına bağlamak olurdu.
func notifyAnnouncement(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool,
	propertyID, announcementID string, in repository.CreateAnnouncementInput) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{
			Note: "Bildirim altyapısı kurulu değil; hiçbir bildirim oluşturulmadı."}
	}

	recipients, err := notify.Residents(c.Request.Context(), pool, propertyID)
	if err != nil {
		// Hata YUTULMAZ: yönetici duyurunun sessiz kaldığını bilmelidir.
		log.Printf("[community] duyuru bildirimi alıcı listesi alınamadı: %v", err)
		return &notify.BroadcastResult{
			Note: "Alıcı listesi okunamadı; bildirim oluşturulmadı. Duyuru panoda yayımlandı."}
	}

	return n.Broadcast(c.Request.Context(), notify.Message{
		PropertyID: propertyID,
		Channel:    notify.ChannelInApp,
		Category:   notify.CategoryTransactional,
		Topic:      "announcement",
		Subject:    in.Title,
		Body:       in.Content,
		Payload: map[string]any{
			"announcement_id": announcementID,
			"category":        in.Category,
			"priority":        in.Priority,
		},
		// Aynı duyuru iki kez bildirime dönüşmesin.
		DedupeKey: "announcement:" + announcementID,
		CreatedBy: c.GetString("user_id"),
	}, recipients)
}
