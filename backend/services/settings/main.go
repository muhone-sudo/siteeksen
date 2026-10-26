// settings-service — Site işletme ayarları.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-14): Bu servis mock'tu; sabit ayar döndürüyor ve
// yazma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu. Artık gerçek veri
// katmanına bağlıdır (FAZ 5 — 16/22).
//
// KAPSAM SINIRI — en önemli tasarım kararı:
// Bu servis MEVZUATA BAĞLI hiçbir değeri tutmaz ve değiştiremez. Gecikme
// tazminatı oranı (KMK m.20/2), genel kurul nisapları (m.30/31), vekâlet
// sınırları (m.31) ve ısı paylaşım oranları (RG 14.04.2008) `legal_parameters`
// tablosundadır; kanunla sabit olanlar site bazında değiştirilemez.
// Bu sınır iki katmanda birden uygulanır:
//   - uygulama: mevzuat ön ekli anahtarlar reddedilir (422 + dayanak)
//   - veritabanı: aynı kısıt CHECK olarak tanımlıdır (migration 017)
//
// Neden iki katman: uygulama kontrolü, doğrudan SQL yazan bir betiği ya da
// ileride yazılacak başka bir servisi bağlamaz. Kanunu ezen bir ayar, sessizce
// hatalı tahakkuk üretir ve sonradan iade/dava konusu olur.
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
	"github.com/siteeksen/backend/services/settings/repository"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	repo := repository.New(pool)
	// Görünürlük politikası değişikliğinde kiracılara bildirim (071).
	visibilityNotifier = notify.FromEnvOrNil(pool)

	r := middleware.NewRouter("settings")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "settings", "persistent": true,
			"modules": gin.H{
				"settings": "persistent",
			},
			"scope_note": "Mevzuata bağlı oranlar ve nisaplar BURADA DEĞİLDİR; " +
				"legal_parameters tablosundadır ve site bazında değiştirilemez. " +
				"Sağlayıcı anahtarları burada saklanmaz; ortam değişkeniyle verilir " +
				"(durum: GET /api/v1/integrations/status).",
		})
	})

	registerActivity(r, pool)

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "settings"))

	// Okuma: sitedeki herkes. İletişim bilgisi, ofis saatleri ve son ödeme günü
	// sakinin bilmesi gereken şeylerdir.
	api.GET("/settings", func(c *gin.Context) {
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"data": list,
			"note": "Kaydedilmemiş ayarlar varsayılan değeriyle döner (is_default=true).",
		})
	})

	api.GET("/settings/definitions", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"data": repository.Definitions,
			"note": "Yalnızca bu listedeki anahtarlar kaydedilebilir. Mevzuat " +
				"parametreleri bu listede YOKTUR ve buradan değiştirilemez.",
		})
	})

	// Yazma ve geçmiş: yalnızca yönetim.
	// Kamera ve biyometrik envanteri (FAZ 7.8): kamera listesi aydınlatma amacıyla herkese açık.
	// Malikin görünürlük politikası (071, D6): herkes etkin politikayı görür (kiracıya şeffaflık).
	api.GET("/settings/owner-visibility", getVisibility(pool))
	api.GET("/privacy/cameras", listCameras(pool, isPrivacyManager))
	api.GET("/privacy/biometrics", middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor), listBiometrics(pool))

	// KVKK saklama süreleri ve periyodik imha (FAZ 7.8): denetçi okur.
	api.GET("/retention-rules", middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor), listRetention(pool))
	api.GET("/retention-rules/log", middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor), destructionLog(pool))

	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.PUT("/settings/:key", func(c *gin.Context) {
			if !canChangeKey(c, c.Param("key")) {
				return
			}
			var in struct {
				Value any `json:"value"`
			}
			if err := c.ShouldBindJSON(&in); err != nil || in.Value == nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "value alanı zorunludur"})
				return
			}
			s, err := repo.Set(c.Request.Context(), c.GetString("property_id"),
				c.GetString("user_id"), c.Param("key"), in.Value)
			if err != nil {
				fail(c, err, "kaydetme")
				return
			}
			middleware.ForgetActivityLogLevel(c.GetString("property_id"))
			c.JSON(http.StatusOK, gin.H{"setting": s})
		})

		write.DELETE("/settings/:key", func(c *gin.Context) {
			if !canChangeKey(c, c.Param("key")) {
				return
			}
			middleware.ForgetActivityLogLevel(c.GetString("property_id"))
			if err := repo.Reset(c.Request.Context(), c.GetString("property_id"),
				c.GetString("user_id"), c.Param("key")); err != nil {
				fail(c, err, "varsayılana döndürme")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Ayar varsayılan değerine döndürüldü",
				"note":    "Değişiklik geçmişi korunur.",
			})
		})

		// "Son ödeme günü ayın 5'iydi, kim 20 yaptı?" sorusunun cevabı.
		write.PUT("/retention-rules/:category", setRetention(pool))
		// Görünürlük: yönetim önerir; öneren dışındaki kurul üyesi onaylar/reddeder (işleyicide denetlenir).
		write.POST("/settings/owner-visibility", proposeVisibility(pool))
		write.POST("/settings/owner-visibility/:id/approve", decideVisibility(pool, true))
		write.POST("/settings/owner-visibility/:id/reject", decideVisibility(pool, false))
		write.POST("/settings/owner-visibility/:id/cancel", cancelVisibility(pool))
		write.POST("/privacy/cameras", createCamera(pool))
		write.PUT("/privacy/cameras/:id", updateCamera(pool))
		write.POST("/privacy/biometrics", createBiometric(pool))
		write.POST("/retention-rules/run", runRetention(pool))

		write.GET("/settings-history", func(c *gin.Context) {
			limit, _ := strconv.Atoi(c.Query("limit"))
			list, err := repo.History(c.Request.Context(),
				c.GetString("property_id"), c.Query("key"), limit)
			if err != nil {
				fail(c, err, "geçmiş")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8102" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Settings Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrLegalKey):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Mevzuat parametresi site ayarı olarak değiştirilemez",
			"note": "Gecikme tazminatı oranı, nisaplar, vekâlet sınırları ve ısı " +
				"paylaşım oranları legal_parameters tablosundadır. Kanunla sabit " +
				"olanlar site bazında değiştirilemez.",
			"legal_basis": "634 s. KMK m.20/2, m.30, m.31; RG 14.04.2008/26847",
		})
	case errors.Is(err, repository.ErrUnknownKey):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Tanınmayan ayar anahtarı",
			"note":  "Geçerli anahtarlar için GET /settings/definitions"})
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Değer, ayarın türüyle uyuşmuyor"})
	case errors.Is(err, repository.ErrOutOfRange):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[settings] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// managerOnlyKeys: işlem kaydını azaltan ayarlar yalnız site yöneticisi tarafından değiştirilir
// (kurul üyesi kendi işlemlerinin kaydını kapatamasın).
var managerOnlyKeys = map[string]bool{"ACTIVITY_LOG_LEVEL": true, "ACTIVITY_LOG_RETENTION_DAYS": true}

func canChangeKey(c *gin.Context, key string) bool {
	if managerOnlyKeys[strings.ToUpper(strings.TrimSpace(key))] && !hasRole(c, middleware.RoleManager) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu ayarı yalnız site yöneticisi değiştirebilir"})
		return false
	}
	return true
}
