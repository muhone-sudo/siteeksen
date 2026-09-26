// notification-service — Bildirim kuyruğu, alıcı tercihleri ve gönderim (S-10).
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; "bildirim gönderildi" diyip
// hiçbir şey yapmıyordu. Artık `pkg/notify` üzerinden gerçek bir GİDEN KUTUSU
// (outbox) yürütür (FAZ 5 — 13/22, S-10).
//
// Dürüstlük sözleşmesi:
//   - Bildirim önce veritabanına yazılır; gönderilemese bile kaydı kalır.
//   - Sağlayıcı yoksa kayıt PENDING kalır ve yanıt bunu açıkça söyler.
//     Hiçbir koşulda "gönderildi" denmez.
//   - Alıcı tercihi ya da onay eksikse kayıt SUPPRESSED olur, GEREKÇESİYLE.
//
// Hukuki çerçeve:
//   - 6563 s. Kanun m.6: TİCARİ elektronik ileti için önceden onay şarttır.
//     Onaysız ticari bildirim gönderilmez. Site yönetiminin aidat/borç/arıza
//     bildirimi ticari ileti değildir (hizmetin ifasına ilişkindir).
//   - 634 s. KMK m.29: genel kurul çağrısı taahhütlü mektup ya da imza
//     karşılığı yapılır; buradan gönderilen bildirim kanuni çağrı yerine geçmez
//     ve gövdeye bu uyarı eklenir.
//   - 6698 s. KVKK m.4: alıcı adresi sunucu günlüğüne maskelenerek yazılır.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/notification/repository"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	senders := notify.SendersFromEnv()
	notifier := notify.New(pool, senders...)
	repo := repository.New(pool)

	r := gin.Default()
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "notification", "persistent": true,
			"delivery": notify.Describe(senders),
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "notification"))

	// --- Kullanıcının kendi bildirimleri ---
	api.GET("/notifications", func(c *gin.Context) {
		limit, _ := strconv.Atoi(c.Query("limit"))
		list, err := repo.ListForUser(c.Request.Context(),
			c.GetString("property_id"), c.GetString("user_id"),
			c.Query("status"), limit)
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	// --- Alıcı tercihleri ---
	api.GET("/notification-preferences", func(c *gin.Context) {
		list, err := repo.Preferences(c.Request.Context(),
			c.GetString("property_id"), c.GetString("user_id"))
		if err != nil {
			fail(c, err, "tercih okuma")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data": list,
			"note": "Kayıt bulunmayan kanal/kategori için varsayılan: işlemsel " +
				"bildirimler AÇIK, ticari bildirimler KAPALI. Ticari ileti " +
				"varsayılanının kapalı olması 6563 s. Kanun m.6 gereğidir.",
		})
	})

	api.PUT("/notification-preferences", func(c *gin.Context) {
		var in struct {
			Channel  string `json:"channel" binding:"required"`
			Category string `json:"category" binding:"required"`
			Enabled  bool   `json:"enabled"`
			// ConsentSource, ticari ileti onayının nasıl alındığını belgeler
			// (örn. "mobil-uygulama-onay-ekrani").
			ConsentSource string `json:"consent_source"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error":    "channel ve category zorunludur",
				"channels": repository.Channels, "categories": repository.Categories})
			return
		}
		err := repo.SetPreference(c.Request.Context(), c.GetString("property_id"),
			c.GetString("user_id"), in.Channel, in.Category, in.Enabled, in.ConsentSource)
		if err != nil {
			fail(c, err, "tercih kaydı")
			return
		}
		resp := gin.H{"message": "Tercih kaydedildi"}
		if strings.EqualFold(in.Category, notify.CategoryCommercial) && in.Enabled {
			resp["consent_note"] = "Ticari elektronik ileti onayı kaydedildi " +
				"(6563 s. Kanun m.6). Onayın kaynağı ve zamanı saklandı; alıcı " +
				"dilediğinde ret hakkını kullanabilir."
		}
		c.JSON(http.StatusOK, resp)
	})

	// --- Gönderim: yönetim ---
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/notifications", func(c *gin.Context) {
			var in struct {
				RecipientUserID string         `json:"recipient_user_id"`
				Recipient       string         `json:"recipient"`
				Channel         string         `json:"channel" binding:"required"`
				Category        string         `json:"category"`
				Topic           string         `json:"topic"`
				Subject         string         `json:"subject"`
				Body            string         `json:"body" binding:"required"`
				Payload         map[string]any `json:"payload"`
				DedupeKey       string         `json:"dedupe_key"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":    "channel ve body zorunludur",
					"channels": repository.Channels, "categories": repository.Categories})
				return
			}

			propertyID := c.GetString("property_id")
			recipient := strings.TrimSpace(in.Recipient)

			// Alıcı adresi verilmediyse kullanıcının kayıtlı telefonundan
			// çözülür. Çözülemezse bildirim OLUŞTURULMAZ — boş adrese
			// "gönderdim" demek en kaba yalan olurdu.
			if recipient == "" && in.RecipientUserID != "" {
				addr, rerr := repo.RecipientAddress(c.Request.Context(),
					propertyID, in.RecipientUserID, in.Channel)
				if rerr != nil {
					fail(c, rerr, "alıcı adresi")
					return
				}
				recipient = addr
			}

			res, err := notifier.Enqueue(c.Request.Context(), notify.Message{
				PropertyID:      propertyID,
				RecipientUserID: in.RecipientUserID,
				Recipient:       recipient,
				Channel:         in.Channel,
				Category:        in.Category,
				Topic:           in.Topic,
				Subject:         in.Subject,
				Body:            in.Body,
				Payload:         in.Payload,
				DedupeKey:       in.DedupeKey,
				CreatedBy:       c.GetString("user_id"),
			})
			if err != nil {
				fail(c, err, "bildirim")
				return
			}
			c.JSON(statusCodeFor(res.Status), gin.H{"notification": res})
		})

		// Site genelindeki bildirim kayıtları (denetim ve hata ayıklama).
		write.GET("/notifications/outbox", func(c *gin.Context) {
			limit, _ := strconv.Atoi(c.Query("limit"))
			list, err := repo.ListAll(c.Request.Context(), c.GetString("property_id"),
				c.Query("status"), c.Query("channel"), limit)
			if err != nil {
				fail(c, err, "giden kutusu")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		write.GET("/notifications/summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"summary":  s,
				"delivery": notify.Describe(senders),
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8085"
	}
	log.Printf("Notification Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// statusCodeFor, kuyruk sonucunu HTTP durumuna çevirir.
//
// PENDING ve SUPPRESSED için 202 kullanılır: istek KABUL EDİLDİ ama gönderim
// YAPILMADI. 200/201 dönmek, çağıranın bildirimin ulaştığını sanmasına yol açardı.
func statusCodeFor(status string) int {
	switch status {
	case "SENT":
		return http.StatusCreated
	case "FAILED":
		return http.StatusBadGateway
	default: // PENDING, SUPPRESSED
		return http.StatusAccepted
	}
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, notify.ErrInvalidChannel):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz bildirim kanalı", "channels": repository.Channels})
	case errors.Is(err, notify.ErrInvalidCategory):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz bildirim kategorisi", "categories": repository.Categories})
	case errors.Is(err, notify.ErrNoRecipient), errors.Is(err, repository.ErrNoAddress):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Alıcı adresi yok",
			"note": "Kullanıcının bu kanal için kayıtlı adresi (telefon/e-posta) " +
				"bulunamadı. Bildirim OLUŞTURULMADI.",
		})
	case errors.Is(err, notify.ErrNoBody):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bildirim gövdesi boş"})
	case errors.Is(err, notify.ErrDuplicate):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Bu bildirim zaten kuyruğa alınmış (dedupe_key)",
			"note":  "Aynı olay iki kez bildirilmez."})
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrInvalidValue):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error":    "Geçersiz kanal ya da kategori",
			"channels": repository.Channels, "categories": repository.Categories})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[notification] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
