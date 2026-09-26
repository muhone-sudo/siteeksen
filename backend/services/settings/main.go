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

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/stub"
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

	r := gin.Default()
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "settings", "persistent": true,
			"modules": gin.H{
				"settings":    "persistent",
				"credentials": "not_implemented",
			},
			"scope_note": "Mevzuata bağlı oranlar ve nisaplar BURADA DEĞİLDİR; " +
				"legal_parameters tablosundadır ve site bazında değiştirilemez. " +
				"Entegrasyon kimlik bilgileri modülü gerçek DEĞİLDİR (501): " +
				"alan düzeyinde şifreleme yazılmadan sağlayıcı anahtarı saklanmaz.",
		})
	})

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
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.PUT("/settings/:key", func(c *gin.Context) {
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
			c.JSON(http.StatusOK, gin.H{"setting": s})
		})

		write.DELETE("/settings/:key", func(c *gin.Context) {
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

	// --- Entegrasyon kimlik bilgileri: bilerek 501 ---
	//
	// Bu uçlar daha önce UYDURMA API ANAHTARLARI döndürüyordu ve denetimde
	// "kimlik doğrulaması olmadan API anahtarı servis ediliyor" bulgusuyla
	// işaretlenmişti. Gerçek bir kimlik bilgisi kasası yazmak için önce alan
	// düzeyinde şifreleme (todo 2.8) gerekir: sağlayıcı anahtarını veritabanına
	// DÜZ METİN yazmak, tek bir yedek sızıntısında sitenin tüm entegrasyonlarını
	// ele verir. O yüzden bu modül GERÇEK DEĞİLDİR ve öyle olduğunu söyler.
	creds := api.Group("/credentials")
	{
		creds.GET("", stub.Handler("settings.credentials"))
		creds.POST("", stub.Handler("settings.credentials"))
		creds.PUT("/:id", stub.Handler("settings.credentials"))
		creds.DELETE("/:id", stub.Handler("settings.credentials"))
		creds.POST("/:id/test", stub.Handler("settings.credentials"))
		creds.GET("/:id/audit-log", stub.Handler("settings.credentials"))
	}
	api.GET("/credentials-available-services", stub.Handler("settings.credentials"))

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
