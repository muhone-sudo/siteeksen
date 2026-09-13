// asset-service — Demirbaş (sabit kıymet) envanteri, bakım takibi ve amortisman.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit demirbaş listesi
// döndürüyor ve yazma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 9/22).
//
// Neden önemli (hukuki çerçeve):
//   - KMK m.36: yönetici, işletme defterini ve BELGELERİ kat maliklerinin
//     incelemesine hazır bulundurur; demirbaş listesi bunun parçasıdır.
//   - KMK m.34/m.38: yönetici değişiminde demirbaş DEVREDİLİR. Devrin
//     yapılabilmesi için envanterin ve defter değerinin güncel olması gerekir.
//   - KMK m.45: ortak yerler üzerinde temliki tasarruf (satış/devir) OYBİRLİĞİ
//     ister. Bu yüzden kayıttan düşme, karar dayanağı olmadan kaydedilmez.
//   - KMK m.37: bakım gideri işletme projesinin kalemidir; yıl içi gerçekleşen
//     bakım maliyeti özet ucunda verilir.
//
// Amortisman DEFTERDE SAKLANMAZ, her okumada hesaplanır: saklanan değer zamanla
// sessizce yanlışa döner ve yanlış defter değeri devir/bütçe konuşmasını bozar.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/asset/repository"
	assetsvc "github.com/siteeksen/backend/services/asset/service"
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
			"status": "healthy", "service": "asset", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(), middleware.AuditLog(pool, "asset"))

	// Okuma: yönetim, denetçi ve görevli. Görevli bakımı yapan kişidir;
	// hangi cihazın bakımının geldiğini görmeden işini yapamaz.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleStaff))
	{
		read.GET("/asset-categories", func(c *gin.Context) {
			list, err := repo.ListCategories(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "kategori listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/assets", func(c *gin.Context) {
			expiring := 0
			if v := c.Query("warranty_expires_days"); v != "" {
				n, perr := strconv.Atoi(v)
				if perr != nil || n < 0 {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "warranty_expires_days pozitif bir tam sayı olmalıdır"})
					return
				}
				expiring = n
			}
			list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
				repository.ListFilter{
					CategoryID:      c.Query("category_id"),
					Status:          c.Query("status"),
					Condition:       c.Query("condition"),
					Location:        c.Query("location"),
					MaintenanceDue:  c.Query("maintenance_due") == "true",
					WarrantyExpires: expiring,
					IncludeDisposed: c.Query("include_disposed") == "true",
				})
			if err != nil {
				fail(c, err, "listeleme")
				return
			}
			now := time.Now()
			for i := range list {
				applyDepreciation(&list[i], now)
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/assets/:id", func(c *gin.Context) {
			a, err := repo.Get(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "okuma")
				return
			}
			dep := applyDepreciation(a, time.Now())
			resp := gin.H{"asset": a}
			if dep != nil {
				resp["depreciation"] = dep
			} else {
				resp["depreciation_note"] = "Amortisman hesaplanamadı: satın alma tarihi, " +
					"tutarı veya faydalı ömür tanımlı değil. Uydurma bir değer üretilmez."
			}
			c.JSON(http.StatusOK, resp)
		})

		read.GET("/assets/:id/maintenance", func(c *gin.Context) {
			list, err := repo.MaintenanceHistory(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "bakım geçmişi")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/assets-summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			c.JSON(http.StatusOK, s)
		})
	}

	// Bakım kaydı görevli tarafından da girilebilir — işi yapan kişidir.
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		ops.POST("/assets/:id/maintenance", func(c *gin.Context) {
			var in repository.MaintenanceInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "maintenance_type ve description zorunludur",
					"valid_types": repository.MaintenanceTypes})
				return
			}
			id, err := repo.RecordMaintenance(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), in)
			if err != nil {
				fail(c, err, "bakım kaydı")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id":         id,
				"total_cost": in.LaborCost + in.PartsCost,
				"note": "Toplam maliyet sunucuda işçilik + parça olarak hesaplandı; " +
					"sıradaki bakım tarihi aynı işlemde güncellendi. Bu tutar gider " +
					"kaydına OTOMATİK AKTARILMADI — gider modülüne ayrıca girilmelidir.",
			})
		})
	}

	// Yazma: yalnızca yönetim.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/asset-categories", func(c *gin.Context) {
			var in struct {
				Name              string `json:"name" binding:"required"`
				Description       string `json:"description"`
				DepreciationYears int    `json:"depreciation_years"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "name zorunludur"})
				return
			}
			id, err := repo.CreateCategory(c.Request.Context(), c.GetString("property_id"),
				in.Name, in.Description, in.DepreciationYears)
			if err != nil {
				fail(c, err, "kategori oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{"id": id})
		})

		write.POST("/assets", func(c *gin.Context) {
			var in repository.CreateInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "name zorunludur"})
				return
			}
			id, err := repo.Create(c.Request.Context(), c.GetString("property_id"), in)
			if err != nil {
				fail(c, err, "oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id, "status": "ACTIVE",
				"note": "Demirbaş fotoğrafı ve fatura görüntüsü BU UÇTAN yüklenmez; " +
					"belge servisine (related_type=ASSET, related_id=<id>) yüklenir.",
			})
		})

		write.POST("/assets/:id/assign", func(c *gin.Context) {
			var in struct {
				AssignedTo string `json:"assigned_to"`
			}
			_ = c.ShouldBindJSON(&in)
			if err := repo.Assign(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.AssignedTo); err != nil {
				fail(c, err, "zimmet")
				return
			}
			msg := "Zimmet kaydedildi"
			if in.AssignedTo == "" {
				msg = "Zimmet kaldırıldı"
			}
			c.JSON(http.StatusOK, gin.H{"message": msg})
		})

		write.POST("/assets/:id/dispose", func(c *gin.Context) {
			var in struct {
				Reason       string `json:"reason" binding:"required"`
				DecisionRef  string `json:"decision_ref" binding:"required"`
				NewCondition string `json:"new_condition"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				// Karar dayanağı olmadan ortak malın elden çıkarılması kaydedilemez.
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Kayıttan düşme için gerekçe (reason) ve karar dayanağı " +
						"(decision_ref: genel kurul karar tarih/no) zorunludur",
					"legal_basis": "634 s. KMK m.45 — ortak yerlerde temliki tasarruf oybirliği ister",
				})
				return
			}
			if err := repo.Dispose(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.Reason, in.DecisionRef, in.NewCondition); err != nil {
				fail(c, err, "kayıttan düşme")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status": "DISPOSED",
				"note": "Kayıt SİLİNMEDİ; geçmişi ve bakım kayıtları korunur " +
					"(yönetici devrinde hesap verilebilirlik — KMK m.34/m.38).",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8087" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Asset Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// applyDepreciation, demirbaşın amortismanını hesaplayıp alanlarına yazar.
// Hesaplanamıyorsa alanlar null kalır — sıfır yazmak "tamamen itfa edilmiş"
// izlenimi verirdi.
func applyDepreciation(a *repository.Asset, now time.Time) *assetsvc.Depreciation {
	dep := assetsvc.LinearDepreciation(
		a.PurchasePrice, a.ResidualValue, a.DepreciationYears, a.PurchaseDate, now)
	if dep == nil {
		return nil
	}
	acc, book := dep.Accumulated, dep.BookValue
	a.AccumulatedDeprec = &acc
	a.BookValue = &book
	return dep
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Demirbaş bulunamadı"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{
			"error":            "Demirbaş bu işlem için uygun durumda değil ya da gönderilen değer geçersiz",
			"valid_conditions": repository.Conditions, "valid_types": repository.MaintenanceTypes})
	case errors.Is(err, repository.ErrInvalidCategory):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kategori bu siteye ait değil"})
	case errors.Is(err, repository.ErrDuplicateCode):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu demirbaş kodu zaten kullanılıyor"})
	case errors.Is(err, repository.ErrInvalidDate):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Tarihler geçersiz (YYYY-AA-GG bekleniyor)"})
	default:
		log.Printf("[asset] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
