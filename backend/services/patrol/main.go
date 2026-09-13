// patrol-service — Güvenlik turu (devriye) kontrol sistemi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit tur kaydı döndürüyor
// ve okutma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu — yani hiç
// gezilmemiş bir tur "tamamlandı" görünüyordu. Artık gerçek veri katmanına
// bağlıdır (FAZ 5 — 14/22).
//
// Tasarımın iki ilkesi:
//  1. ZAMAN SUNUCUDAN gelir. Tur süresi, güvenlik hizmetinin fiilen yapıldığının
//     kanıtıdır; istemcinin saatine bırakılırsa 30 dakikalık tur 3 dakikada
//     "yapılmış" gösterilebilir.
//  2. TUR DURUMU İSTEMCİDEN ALINMAZ, hesaplanır. Görevli "tamamladım" dese bile
//     zorunlu noktalardan biri okutulmamışsa kayıt INCOMPLETE olur.
//
// Ayrıca beklenen süreden (tolerans düşülerek) kısa süren turlar DENETİM İÇİN
// işaretlenir. Bu bir hata değil, yöneticinin bakması gereken bir işarettir.
//
// Neden önemli: güvenlik hizmeti ortak giderdir (KMK m.20) ve hizmetin
// verilmediği bir dönemin bedeli kat maliklerinden istenemez. Tur kayıtları,
// hizmetin verildiğinin belgesidir (KMK m.36 — belgelerin incelemeye hazır
// bulundurulması).
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
	"github.com/siteeksen/backend/services/patrol/repository"
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
			"status": "healthy", "service": "patrol", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(), middleware.AuditLog(pool, "patrol"))

	// Okuma: yönetim, denetçi ve görevli.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleStaff))
	{
		read.GET("/patrol-checkpoints", func(c *gin.Context) {
			list, err := repo.ListCheckpoints(c.Request.Context(),
				c.GetString("property_id"), c.Query("include_inactive") == "true")
			if err != nil {
				fail(c, err, "nokta listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/patrol-routes", func(c *gin.Context) {
			list, err := repo.ListRoutes(c.Request.Context(),
				c.GetString("property_id"), c.Query("include_inactive") == "true")
			if err != nil {
				fail(c, err, "güzergâh listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/patrols", func(c *gin.Context) {
			limit, _ := strconv.Atoi(c.Query("limit"))
			guard := c.Query("guard_id")
			if !isManagement(c) {
				// Görevli yalnızca kendi turlarını görür.
				guard = c.GetString("user_id")
			}
			list, err := repo.ListPatrols(c.Request.Context(),
				c.GetString("property_id"), guard, c.Query("status"), limit)
			if err != nil {
				fail(c, err, "tur listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/patrols-summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			resp := gin.H{"summary": s}
			if s.TooFastCount > 0 {
				resp["warning"] = "Beklenen sürenin yarısından kısa süren turlar var; " +
					"noktalar fiilen gezilmemiş olabilir."
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	// Tur yürütme: görevli ve yönetim.
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		ops.POST("/patrols", func(c *gin.Context) {
			var in struct {
				RouteID string `json:"route_id" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "route_id zorunludur"})
				return
			}
			p, err := repo.StartPatrol(c.Request.Context(), c.GetString("property_id"),
				in.RouteID, c.GetString("user_id"))
			if err != nil {
				fail(c, err, "tur başlatma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"patrol": p,
				"note":   "Başlangıç zamanı SUNUCUDAN alındı; istemci saati kullanılmaz.",
			})
		})

		ops.POST("/patrols/:id/scan", func(c *gin.Context) {
			var in struct {
				CheckpointID string `json:"checkpoint_id" binding:"required"`
				Note         string `json:"note"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "checkpoint_id zorunludur"})
				return
			}
			res, err := repo.ScanCheckpoint(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.CheckpointID, c.GetString("user_id"), in.Note)
			if err != nil {
				fail(c, err, "nokta okutma")
				return
			}
			c.JSON(http.StatusOK, gin.H{"scan": res})
		})

		ops.POST("/patrols/:id/issues", func(c *gin.Context) {
			var in struct {
				CheckpointID string `json:"checkpoint_id"`
				Severity     string `json:"severity"`
				Description  string `json:"description" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "description zorunludur", "severities": repository.Severities})
				return
			}
			if err := repo.ReportIssue(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), in.CheckpointID,
				in.Severity, in.Description); err != nil {
				fail(c, err, "sorun bildirimi")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"message": "Sorun tur kaydına işlendi",
				"note": "Bu kayıt bir TALEP/ARIZA KAYDI AÇMAZ; ilgili iş emri community " +
					"servisinden ayrıca açılmalıdır.",
			})
		})

		ops.POST("/patrols/:id/complete", func(c *gin.Context) {
			var in struct {
				Notes string `json:"notes"`
			}
			_ = c.ShouldBindJSON(&in)

			res, err := repo.CompletePatrol(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), c.GetString("user_id"), in.Notes)
			if err != nil {
				fail(c, err, "tur kapatma")
				return
			}
			resp := gin.H{"result": res}
			if res.Status == "INCOMPLETE" {
				resp["note"] = "Tur EKSİK olarak kapatıldı: zorunlu noktalardan bazıları " +
					"okutulmadı. Durum istemciden alınmaz, kayıttan hesaplanır."
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	// Tanımlama: yalnızca yönetim.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/patrol-checkpoints", func(c *gin.Context) {
			var in struct {
				Name         string `json:"name" binding:"required"`
				Description  string `json:"description"`
				Location     string `json:"location"`
				Building     string `json:"building"`
				Floor        string `json:"floor"`
				NFCTagID     string `json:"nfc_tag_id"`
				QRCode       string `json:"qr_code"`
				DisplayOrder int    `json:"display_order"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "name zorunludur"})
				return
			}
			id, err := repo.CreateCheckpoint(c.Request.Context(), c.GetString("property_id"),
				in.Name, in.Description, in.Location, in.Building, in.Floor,
				in.NFCTagID, in.QRCode, in.DisplayOrder)
			if err != nil {
				fail(c, err, "nokta oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id,
				"note": "NFC/QR etiketi FİZİKSEL OLARAK ÜRETİLMEZ; etiketin noktaya " +
					"asılması ayrı bir iştir.",
			})
		})

		write.POST("/patrol-routes", func(c *gin.Context) {
			var in struct {
				Name             string                       `json:"name" binding:"required"`
				Description      string                       `json:"description"`
				Checkpoints      []repository.RouteCheckpoint `json:"checkpoints" binding:"required"`
				ExpectedDuration int                          `json:"expected_duration_minutes"`
				ToleranceMinutes int                          `json:"tolerance_minutes"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "name ve en az bir kontrol noktası (checkpoints) zorunludur"})
				return
			}
			id, err := repo.CreateRoute(c.Request.Context(), c.GetString("property_id"),
				in.Name, in.Description, in.Checkpoints, in.ExpectedDuration, in.ToleranceMinutes)
			if err != nil {
				fail(c, err, "güzergâh oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{"id": id})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8099" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Patrol Service başlatıldı: :%s", port)
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
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrRouteInactive):
		c.JSON(http.StatusConflict, gin.H{"error": "Tur güzergâhı pasif"})
	case errors.Is(err, repository.ErrAlreadyOpen):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Devam eden bir turunuz var",
			"note": "Aynı anda iki tur açık olamaz; hangi noktanın hangi tura ait " +
				"olduğu belirsizleşir. Önceki turu kapatın."})
	case errors.Is(err, repository.ErrNoOpenPatrol):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu tur devam etmiyor"})
	case errors.Is(err, repository.ErrCheckpointOther):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Kontrol noktası bu güzergâha ya da bu siteye ait değil"})
	case errors.Is(err, repository.ErrAlreadyScanned):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Bu nokta bu turda zaten okutuldu",
			"note": "Tek noktada durup turu tamamlanmış göstermeyi engellemek için " +
				"aynı nokta iki kez sayılmaz."})
	case errors.Is(err, repository.ErrNoCheckpoints):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Güzergâh en az bir kontrol noktası içermelidir"})
	case errors.Is(err, repository.ErrDuplicateTag):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu NFC/QR kimliği zaten kullanılıyor"})
	default:
		log.Printf("[patrol] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
