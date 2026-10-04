// package-service — Site girişinde teslim alınan kargo/paket takibi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit kargo listesi döndürüyor
// ve teslim alma/teslim etme isteklerine 2xx dönüp hiçbir yere kaydetmiyordu.
// Ayrıca "sakine bildirim gönderildi" diyordu — bildirim altyapısı hiç yoktu.
//
// 2026-09-14: bildirim altyapısı bağlandı. Kargo kaydedildiğinde İLGİLİ
// DAİRENİN sakinlerine uygulama içi bildirim düşer ve kayıt ancak bildirim
// GERÇEKTEN oluşturulduysa "haber verildi" olarak işaretlenir.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 6/22).
//
// Dürüstlük notları:
//   - Sistem KENDİLİĞİNDEN BİLDİRİM GÖNDERMEZ. /notify ucu, görevlinin sakine elle
//     (zil, telefon, yüz yüze) haber verdiğini KAYDA GEÇİRMESİ içindir.
//   - Teslim imzası / fotoğrafı saklanmaz; dosya depolama altyapısı henüz yoktur.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/listcap"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/package/repository"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	repo := repository.New(pool)

	// Uygulama içi bildirim her zaman çalışır (kayıt veritabanındadır).
	// SMS/push sağlayıcısı olmadığı sürece o kanallar kullanılmaz.
	notifier := notify.FromEnvOrNil(pool)

	r := middleware.NewRouter("package")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "package", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "package"))

	// Sakin yalnızca kendi bağımsız bölümünün kargolarını görür.
	// Kargo kaydı, kimin ne aldığını gösterir; bu KVKK kapsamında kişisel veridir
	// ve komşunun paketini görmek için hiçbir meşru menfaat yoktur.
	api.GET("/packages", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		scope := ""
		if !hasOpsScope(c) {
			unitID, uerr := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
			if uerr != nil {
				fail(c, uerr, "bağımsız bölüm çözümleme")
				return
			}
			scope = unitID
		} else if q := c.Query("unit_id"); q != "" {
			scope = q
		}

		list, err := repo.List(c.Request.Context(), propertyID, scope,
			strings.ToUpper(c.Query("status")), c.Query("pending") == "true")
		if err != nil {
			fail(c, err, "kargo listeleme")
			return
		}
		list, truncated := listcap.Trim(list, listcap.Default)
		c.JSON(http.StatusOK, gin.H{"data": list, "truncated": truncated, "limit": listcap.Default})
	})

	api.GET("/packages/:id", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		scope := ""
		if !hasOpsScope(c) {
			unitID, uerr := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
			if uerr != nil {
				fail(c, uerr, "bağımsız bölüm çözümleme")
				return
			}
			scope = unitID
		}
		p, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), scope)
		if err != nil {
			fail(c, err, "kargo okuma")
			return
		}
		c.JSON(http.StatusOK, p)
	})

	// --- Görevli / yönetim işlemleri ---
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		// Depo özeti — unutulmuş paketleri görünür kılar.
		ops.GET("/packages-summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			c.JSON(http.StatusOK, s)
		})

		ops.POST("/packages", func(c *gin.Context) {
			var in repository.CreateInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "unit_id ve recipient_name zorunludur"})
				return
			}
			id, err := repo.Create(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"), in)
			if err != nil {
				fail(c, err, "kargo kaydı")
				return
			}
			// Kargo kaydedildi; şimdi DAİRENİN sakinlerine haber veriliyor.
			// Kayıt, ancak bildirim GERÇEKTEN oluşturulduysa "haber verildi"
			// durumuna geçer — bildirim üretilmeden durumu değiştirmek,
			// sakinin haberi olduğunu varsaymak olurdu.
			res, status := notifyPackage(c, notifier, repo, pool, id, in)
			c.JSON(http.StatusCreated, gin.H{
				"id":                id,
				"status":            status,
				"notification_sent": res != nil && res.Sent > 0,
				"notification":      res,
				"note": "Kapıda teslim edilemeyen kargo için elle haber verildiyse " +
					"POST /packages/{id}/notify ile ayrıca kayda geçirin.",
			})
		})

		// Haber verildi kaydı — bildirim GÖNDERMEZ, gönderildiğini iddia etmez.
		ops.POST("/packages/:id/notify", func(c *gin.Context) {
			var in struct {
				Method string `json:"method"`
			}
			_ = c.ShouldBindJSON(&in)
			if in.Method == "" {
				in.Method = "MANUAL"
			}
			reminders, err := repo.MarkNotified(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), strings.ToUpper(in.Method))
			if err != nil {
				fail(c, err, "haber verildi kaydı")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status":         "NOTIFIED",
				"reminder_count": reminders,
				"note": "Bu kayıt, sakine ELLE haber verildiğini belgeler. Sistem " +
					"SMS/push bildirim GÖNDERMEZ.",
			})
		})

		ops.POST("/packages/:id/deliver", func(c *gin.Context) {
			var in struct {
				DeliveredToName string `json:"delivered_to_name" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				// Kime teslim edildiği yazılmadan teslim kaydı, kaybolan kargoda
				// sorumluluğu belirsiz bırakır.
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Teslim alan kişinin adı (delivered_to_name) zorunludur"})
				return
			}
			if err := repo.Deliver(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), strings.TrimSpace(in.DeliveredToName)); err != nil {
				fail(c, err, "teslim")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status": "DELIVERED",
				"note": "Teslim kaydedildi. İmza/fotoğraf SAKLANMADI; dosya depolama " +
					"altyapısı henüz yoktur.",
			})
		})

		ops.POST("/packages/:id/return", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "İade gerekçesi zorunludur"})
				return
			}
			if err := repo.Return(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), strings.TrimSpace(in.Reason)); err != nil {
				fail(c, err, "iade")
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": "RETURNED"})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8097"
	}
	log.Printf("Package Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func hasOpsScope(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleStaff:
			return true
		}
	}
	return false
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrUnitNotInSite):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belirtilen bağımsız bölüm bu siteye ait değil"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{"error": "Paket bu işlem için uygun durumda değil"})
	case errors.Is(err, repository.ErrNoUnit):
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu sitede aktif bir bağımsız bölümünüz bulunmuyor"})
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Paket türü geçersiz", "valid_types": repository.PackageTypes})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[package] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// notifyPackage, kargoyu İLGİLİ DAİRENİN sakinlerine bildirir.
//
// Neden yalnızca o daire: bir dairenin kargosu diğer sakinleri ilgilendirmez.
// Tüm siteye göndermek, kimin ne aldığını herkese duyurmak olurdu (6698 s.
// Kanun m.4 — veri işleme amaçla sınırlı ve ölçülü olmalıdır).
//
// Gövdeye gönderici/içerik YAZILMAZ: kargo içeriği kişisel veridir ve bildirim
// ekranı kilit ekranında görünebilir. "Kargonuz var" demek yeterlidir.
//
// Dönen ikinci değer, kaydın GÜNCEL durumudur. Bildirim oluşturulamadıysa
// durum RECEIVED kalır; "NOTIFIED" yazmak sakinin haberi olduğunu iddia etmek
// olurdu ve kargo kaybolduğunda bu kayıt yanıltıcı delil hâline gelirdi.
func notifyPackage(c *gin.Context, n *notify.Notifier, repo *repository.Repository,
	pool *pgxpool.Pool, packageID string, in repository.CreateInput) (*notify.BroadcastResult, string) {
	if n == nil {
		return &notify.BroadcastResult{
			Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}, "RECEIVED"
	}

	propertyID := c.GetString("property_id")
	recipients, err := notify.UnitResidents(c.Request.Context(), pool, propertyID, in.UnitID)
	if err != nil {
		log.Printf("[package] kargo bildirimi alıcıları alınamadı: %v", err)
		return &notify.BroadcastResult{
			Note: "Daire sakinleri okunamadı; bildirim oluşturulmadı."}, "RECEIVED"
	}

	body := "Adınıza bir kargo teslim alındı."
	if in.StorageLocation != "" {
		body += " Teslim yeri: " + in.StorageLocation + "."
	}

	res := n.Broadcast(c.Request.Context(), notify.Message{
		PropertyID: propertyID,
		Channel:    notify.ChannelInApp,
		Category:   notify.CategoryTransactional,
		Topic:      "package.received",
		Subject:    "Kargonuz var",
		Body:       body,
		Payload: map[string]any{
			"package_id": packageID,
			"unit_id":    in.UnitID,
			"carrier":    in.Carrier,
		},
		DedupeKey: "package:" + packageID,
		CreatedBy: c.GetString("user_id"),
	}, recipients)

	if res.Sent == 0 {
		return res, "RECEIVED"
	}
	if _, err := repo.MarkNotified(c.Request.Context(), propertyID, packageID, "IN_APP"); err != nil {
		// Bildirim oluştu ama kayıt güncellenemedi. Durumu NOTIFIED yazmak
		// yanlış olurdu; hata da yutulmaz.
		log.Printf("[package] bildirim oluştu fakat kayıt güncellenemedi: %v", err)
		res.Note += " (Uyarı: bildirim oluşturuldu fakat kargo kaydı NOTIFIED olarak işaretlenemedi.)"
		return res, "RECEIVED"
	}
	return res, "NOTIFIED"
}
