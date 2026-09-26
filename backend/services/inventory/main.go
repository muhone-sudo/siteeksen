// inventory-service — Sarf malzeme stoğu (temizlik, bakım, kırtasiye) ve hareketleri.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit stok listesi döndürüyor
// ve hareket isteklerine 2xx dönüp hiçbir yere kaydetmiyordu — yani stok sayısı
// hiç değişmiyordu. Artık gerçek veri katmanına bağlıdır (FAZ 5 — 10/22).
//
// Tasarımın iki ilkesi:
//  1. Her miktar değişikliği bir HAREKET kaydı üretir. Stok alanına doğrudan
//     yazılmaz; aksi hâlde sayım farkının nereden geldiği hiçbir yerde görünmez.
//  2. Stok güncellemesi kalem satırı kilitlenerek, hareketle aynı transaction'da
//     yapılır. Kilitsiz güncelleme, eşzamanlı iki çıkışta depoda olmayan malzemeyi
//     kayıtta bırakır.
//
// Sarf malzeme gideri KMK m.20 uyarınca ortak giderdir ve işletme projesinin
// (m.37) kalemidir; yıl içi alım ve tüketim maliyeti özet ucunda verilir.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/inventory/repository"
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
			"status": "healthy", "service": "inventory", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "inventory"))

	// Okuma: yönetim, denetçi ve görevli (malzemeyi kullanan kişi).
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleStaff))
	{
		read.GET("/inventory-categories", func(c *gin.Context) {
			list, err := repo.ListCategories(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "kategori listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/inventory", func(c *gin.Context) {
			list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
				repository.ListFilter{
					CategoryID:      c.Query("category_id"),
					Search:          c.Query("q"),
					BelowMinimum:    c.Query("below_minimum") == "true",
					IncludeInactive: c.Query("include_inactive") == "true",
				})
			if err != nil {
				fail(c, err, "listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/inventory/:id", func(c *gin.Context) {
			it, err := repo.Get(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "okuma")
				return
			}
			c.JSON(http.StatusOK, it)
		})

		read.GET("/inventory/:id/movements", func(c *gin.Context) {
			if ok, err := repo.Exists(c.Request.Context(), c.GetString("property_id"), "inventory_items", c.Param("id")); err != nil {
				fail(c, err, "kayıt denetimi")
				return
			} else if !ok {
				c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
				return
			}
			limit, _ := strconv.Atoi(c.Query("limit"))
			list, err := repo.Movements(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), limit)
			if err != nil {
				fail(c, err, "hareket geçmişi")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/inventory-movements", func(c *gin.Context) {
			limit, _ := strconv.Atoi(c.Query("limit"))
			list, err := repo.Movements(c.Request.Context(), c.GetString("property_id"), "", limit)
			if err != nil {
				fail(c, err, "hareket listesi")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		read.GET("/inventory-summary", func(c *gin.Context) {
			s, err := repo.Summary(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "özet")
				return
			}
			c.JSON(http.StatusOK, s)
		})
	}

	// Hareket: görevli de girebilir — malzemeyi depodan alan kişidir.
	// Sayım düzeltmesi (ADJUST) bilinçli olarak burada DEĞİL, yönetim grubundadır:
	// stoğu tek kalemde değiştirebilmek kaybı gizlemeye açık kapı bırakır.
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		ops.POST("/inventory/:id/movements", func(c *gin.Context) {
			var in repository.MovementInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "movement_type ve quantity zorunludur",
					"valid_types": repository.MovementTypes})
				return
			}
			// Büyük harfe çevirme denetimden ÖNCE yapılır. Önceden karşılaştırma
			// harf duyarlıydı ama depo değeri büyük harfe çeviriyordu: görevli
			// "adjust" göndererek yönetime ayrılmış sayım düzeltmesini yapabiliyordu.
			in.MovementType = strings.ToUpper(strings.TrimSpace(in.MovementType))
			if in.MovementType == "ADJUST" && !isManagement(c) {
				c.JSON(http.StatusForbidden, gin.H{
					"error": "Sayım düzeltmesi (ADJUST) yalnızca yönetim tarafından yapılabilir",
					"note":  "Giriş (IN) ve çıkış (OUT) hareketlerini görevli de girebilir."})
				return
			}
			res, err := repo.RecordMovement(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"), c.GetString("user_id"), in)
			if err != nil {
				fail(c, err, "hareket")
				return
			}
			resp := gin.H{"movement": res}
			if res.BelowMinimum {
				resp["warning"] = "Stok asgari seviyenin altına düştü."
				resp["notification"] = notifyLowStock(c, notifier, pool, c.Param("id"), res)
			}
			c.JSON(http.StatusCreated, resp)
		})
	}

	// Tanımlama ve sayım düzeltmesi: yalnızca yönetim.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/inventory-categories", func(c *gin.Context) {
			var in struct {
				Name        string `json:"name" binding:"required"`
				Description string `json:"description"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "name zorunludur"})
				return
			}
			id, err := repo.CreateCategory(c.Request.Context(),
				c.GetString("property_id"), in.Name, in.Description)
			if err != nil {
				fail(c, err, "kategori oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{"id": id})
		})

		write.POST("/inventory", func(c *gin.Context) {
			var in repository.CreateItemInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "name ve unit zorunludur", "valid_units": repository.Units})
				return
			}
			id, err := repo.CreateItem(c.Request.Context(), c.GetString("property_id"), in)
			if err != nil {
				fail(c, err, "kalem oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id, "current_stock": "0",
				"note": "Açılış stoğu SIFIRDIR. Mevcut stoğu girmek için sayım düzeltmesi " +
					"(movement_type=ADJUST) kullanın; böylece stoğun nereden geldiği kayda geçer.",
			})
		})

		write.DELETE("/inventory/:id", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Pasife alma gerekçesi zorunludur"})
				return
			}
			if err := repo.Deactivate(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.Reason); err != nil {
				fail(c, err, "pasife alma")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Stok kalemi pasife alındı",
				"note":    "Kayıt ve hareket geçmişi SİLİNMEDİ; denetim izi korunur.",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8094" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Inventory Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func isManagement(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember:
			return true
		}
	}
	return false
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Stok kalemi bulunamadı"})
	case errors.Is(err, repository.ErrInvalidCategory):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kategori bu siteye ait değil"})
	case errors.Is(err, repository.ErrInvalidUnit):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz birim", "valid_units": repository.Units})
	case errors.Is(err, repository.ErrInvalidQuantity):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error":       "Miktar geçersiz (negatif olamaz; giriş/çıkışta sıfır olamaz)",
			"valid_types": repository.MovementTypes})
	case errors.Is(err, repository.ErrInsufficient):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Stok yetersiz — çıkış yapılamaz",
			"note": "Depoda olmayan malzemenin çıkışı kaydedilirse stok raporu bir daha " +
				"gerçeğe dönmez. Fiilî eksik varsa sayım düzeltmesi (ADJUST) kullanın.",
		})
	case errors.Is(err, repository.ErrInactive):
		c.JSON(http.StatusConflict, gin.H{"error": "Stok kalemi pasif; hareket girilemez"})
	case errors.Is(err, repository.ErrReasonRequired):
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Sayım düzeltmesi için gerekçe (notes) zorunludur",
			"note":  "Gerekçesiz düzeltme, kaybı ve fireyi görünmez kılar."})
	case errors.Is(err, repository.ErrInvalidMovementType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Hareket türü geçersiz", "valid_types": repository.MovementTypes})
	case errors.Is(err, repository.ErrInvalidReferenceType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Hareket dayanağı geçersiz", "valid_reference_types": repository.ReferenceTypes})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[inventory] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// notifyLowStock, asgari seviyenin altına düşen stoğu YÖNETİME bildirir.
//
// Neden sakinlere değil: depo stoğu sakinleri ilgilendirmez. Site genelinde
// "temizlik malzemesi azaldı" bildirimi göndermek, bildirimlerin tamamının
// kapatılmasına yol açar ve gerçekten önemli olanların da okunmamasına
// sebep olur.
//
// Neden hareket başına bir kez: dedupe anahtarı HAREKET kimliğidir. Kalem
// kimliği kullanılsaydı ilk uyarıdan sonra stok daha da düştüğünde ikinci
// uyarı SESSİZCE düşerdi; tarih kullanılsaydı gün içindeki ikinci düşüş
// görünmezdi. Hareket kimliği, her gerçek olayı bir kez bildirir.
func notifyLowStock(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool,
	itemID string, res *repository.MovementResult) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{
			Note: "Bildirim altyapısı kurulu değil; uyarı bildirimi oluşturulmadı."}
	}

	propertyID := c.GetString("property_id")
	recipients, err := notify.Managers(c.Request.Context(), pool, propertyID)
	if err != nil {
		log.Printf("[inventory] yönetim alıcıları alınamadı: %v", err)
		return &notify.BroadcastResult{
			Note: "Yönetim listesi okunamadı; uyarı bildirimi oluşturulmadı."}
	}

	unit := ""
	if res.ItemUnit != "" {
		unit = " " + res.ItemUnit
	}
	body := res.ItemName + " stoğu asgari seviyenin altına düştü.\n" +
		"Mevcut: " + res.NewStock + unit + " · Asgari: " + res.MinimumStock + unit

	return n.Broadcast(c.Request.Context(), notify.Message{
		PropertyID: propertyID,
		Channel:    notify.ChannelInApp,
		Category:   notify.CategoryTransactional,
		Topic:      "inventory.low_stock",
		Subject:    "Stok uyarısı: " + res.ItemName,
		Body:       body,
		Payload: map[string]any{
			"item_id":       itemID,
			"movement_id":   res.MovementID,
			"current_stock": res.NewStock,
			"minimum_stock": res.MinimumStock,
		},
		DedupeKey: "inventory.low_stock:" + res.MovementID,
		CreatedBy: c.GetString("user_id"),
	}, recipients)
}
