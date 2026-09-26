// contract-service — Site yönetiminin taraf olduğu sözleşmelerin takibi
// (asansör bakımı, güvenlik, temizlik, sigorta, kira, personel…).
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit sözleşme listesi
// döndürüyor ve yazma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 7/22).
//
// Neden önemli: yenilenme ihbar süresi kaçırılan bir sözleşme (örn. asansör
// bakımı) siteyi haberi olmadan yeni bir döneme ve yeni bir mali yüke bağlar.
// Bu yüzden kendiliğinden yenileme SİSTEM TARAFINDAN YAPILMAZ; yalnızca ihbar
// penceresi (notice_due) işaretlenir ve yenileme elle onaylanır.
//
// Erişim: sözleşmeler karşı tarafın kişisel/ticari verisini içerir; ayrıntılar
// yönetim ve denetçiye açıktır. Kat maliklerine yalnızca KİŞİSEL VERİ İÇERMEYEN
// özet (toplam mali yük, yaklaşan bitişler) açılır — KMK m.39 hesap verme ve
// m.41 denetim hakkı ile KVKK m.4 veri minimizasyonunun birlikte karşılanması.
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
	"github.com/siteeksen/backend/services/contract/repository"
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
			"status": "healthy", "service": "contract", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "contract"))

	// Özet: kişisel veri içermez, siteye kayıtlı herkese açıktır.
	api.GET("/contracts-summary", func(c *gin.Context) {
		s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "özet")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"summary": s,
			"note": "Bu özet karşı tarafın kişisel/ticari verisini içermez. Sözleşme " +
				"ayrıntıları yönetim ve denetçiye açıktır (KMK m.39/m.41, KVKK m.4).",
		})
	})

	// Ayrıntılı görünüm: yönetim + denetçi.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		read.GET("/contracts", func(c *gin.Context) {
			expiring := 0
			if v := c.Query("expiring_days"); v != "" {
				n, err := strconv.Atoi(v)
				if err != nil || n < 0 {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "expiring_days pozitif bir tam sayı olmalıdır"})
					return
				}
				expiring = n
			}
			list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
				c.Query("type"), c.Query("status"), expiring)
			if err != nil {
				fail(c, err, "listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/contracts/:id", func(c *gin.Context) {
			ct, err := repo.Get(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "okuma")
				return
			}
			c.JSON(http.StatusOK, ct)
		})
	}

	// Yazma: yalnızca yönetim. Denetçi denetler, sözleşme yapmaz.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/contracts", func(c *gin.Context) {
			var in repository.CreateInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "contract_type, title, party_name ve start_date zorunludur",
					"valid_types": repository.ValidTypes})
				return
			}
			id, err := repo.Create(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"), in)
			if err != nil {
				fail(c, err, "oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id, "status": "ACTIVE",
				"note": "Sözleşme metni DOSYA OLARAK saklanmadı; dosya depolama " +
					"altyapısı henüz yoktur (todo S-09).",
			})
		})

		write.POST("/contracts/:id/renew", func(c *gin.Context) {
			ct, err := repo.Renew(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "yenileme")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"contract": ct,
				"note": "Yenileme elle onaylandı ve kayda geçti. Sistem sözleşmeleri " +
					"KENDİLİĞİNDEN YENİLEMEZ — site habersiz mali yükümlülük altına girmesin diye.",
			})
		})

		write.POST("/contracts/:id/terminate", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				// Gerekçesiz fesih, sonraki denetimde hesabı verilemez.
				c.JSON(http.StatusBadRequest, gin.H{"error": "Fesih gerekçesi zorunludur"})
				return
			}
			if err := repo.Terminate(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.Reason); err != nil {
				fail(c, err, "fesih")
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": "TERMINATED"})
		})

		// Süresi dolmuş sözleşmeleri işaretler. Zamanlanmış görev altyapısı
		// olmadığı için elle tetiklenir; işlem idempotenttir.
		write.POST("/contracts/expire-due", func(c *gin.Context) {
			n, err := repo.ExpireDue(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "süre dolumu")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"expired_count": n,
				"note": "Zamanlanmış görev altyapısı yoktur; bu uç elle tetiklenir. " +
					"Kendiliğinden yenilenen sözleşmeler kapsam dışıdır.",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8090" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Contract Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{"error": "Sözleşme bu işlem için uygun durumda değil"})
	case errors.Is(err, repository.ErrNoRenewal):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Sözleşmede yenileme süresi (renewal_period_months) tanımlı değil"})
	case errors.Is(err, repository.ErrMaxRenewals):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Azami yenileme sayısına ulaşıldı; yeni sözleşme yapılmalıdır"})
	case errors.Is(err, repository.ErrInvalidDates):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Tarihler geçersiz (YYYY-AA-GG bekleniyor; bitiş, başlangıçtan önce olamaz)"})
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz sözleşme türü", "valid_types": repository.ValidTypes})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[contract] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
