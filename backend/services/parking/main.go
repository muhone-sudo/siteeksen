// parking-service — Araç kaydı ve otopark giriş/çıkış takibi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu ve her çağrıda "34 ABC 123 /
// Ali Veli" gibi uydurma veri döndürüyordu; plaka tanıma ucu da her seferinde
// aynı sahte sonucu veriyordu. Artık gerçek veri katmanına bağlıdır (FAZ 5 — 4/22).
//
// Not: Plaka tanıma (AI) entegrasyonu YOKTUR ve var gibi gösterilmez; giriş
// kaydı elle ya da harici bir sistemden gelen plaka ile yapılır.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/services/parking/repository"
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
			"status": "healthy", "service": "parking", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "parking"))

	// --- Araçlar ---
	// Sakin kendi araçlarını görür ve kaydeder; yönetim/görevli site genelini görür.
	api.GET("/vehicles", func(c *gin.Context) {
		scope := ""
		if !hasOpsScope(c) {
			scope = c.GetString("user_id")
		}
		list, err := repo.ListVehicles(c.Request.Context(), c.GetString("property_id"), scope)
		if err != nil {
			fail(c, err, "araç listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	api.POST("/vehicles", func(c *gin.Context) {
		var in repository.Vehicle
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		id, err := repo.CreateVehicle(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			fail(c, err, "araç kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "plate": in.Plate})
	})

	api.DELETE("/vehicles/:id", func(c *gin.Context) {
		if err := repo.DeactivateVehicle(c.Request.Context(),
			c.GetString("property_id"), c.Param("id")); err != nil {
			fail(c, err, "araç pasife alma")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Araç pasife alındı",
			"note":    "Kayıt silinmez; geçmiş otopark hareketleri bu araca bağlıdır.",
		})
	})

	// Plakadan araç sorgulama — güvenlik görevlisinin en sık kullandığı uç.
	api.GET("/vehicles/plate/:plate", func(c *gin.Context) {
		if !hasOpsScope(c) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
			return
		}
		v, err := repo.FindByPlate(c.Request.Context(), c.GetString("property_id"), c.Param("plate"))
		if err != nil {
			fail(c, err, "plaka sorgulama")
			return
		}
		c.JSON(http.StatusOK, v)
	})

	// --- Bölgeler ---
	api.GET("/parking-zones", func(c *gin.Context) {
		list, err := repo.ListZones(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "bölge listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	// --- Giriş / çıkış ---
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		ops.GET("/parking-logs", func(c *gin.Context) {
			list, err := repo.ListLogs(c.Request.Context(),
				c.GetString("property_id"), c.Query("inside") == "true")
			if err != nil {
				fail(c, err, "hareket listeleme")
				return
			}
			c.JSON(http.StatusOK, gin.H{"data": list})
		})

		ops.POST("/parking-logs/entry", func(c *gin.Context) {
			var in struct {
				Plate         string `json:"plate" binding:"required"`
				ParkingZoneID string `json:"parking_zone_id"`
				EntryGate     string `json:"entry_gate"`
				EntryMethod   string `json:"entry_method"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Plaka zorunludur"})
				return
			}
			propertyID := c.GetString("property_id")

			// Bölge doluysa giriş alınmaz — "boş yer var" diyip araç içeri almak,
			// çıkışta ücret ve yer karmaşasına yol açar.
			if in.ParkingZoneID != "" {
				_, _, _, capacity, occupied, zerr := repo.ZoneFeeInfo(c.Request.Context(), propertyID, in.ParkingZoneID)
				if zerr != nil {
					fail(c, zerr, "bölge okuma")
					return
				}
				if capacity > 0 && occupied >= capacity {
					c.JSON(http.StatusConflict, gin.H{
						"error": "Otopark bölgesi dolu", "capacity": capacity, "occupied": occupied})
					return
				}
			}

			id, resident, err := repo.RecordEntry(c.Request.Context(), propertyID,
				in.ParkingZoneID, in.Plate, in.EntryGate, in.EntryMethod)
			if err != nil {
				fail(c, err, "giriş kaydı")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id, "plate": in.Plate, "is_resident_vehicle": resident,
			})
		})

		ops.POST("/parking-logs/:id/exit", func(c *gin.Context) {
			var in struct {
				ExitGate string `json:"exit_gate"`
			}
			_ = c.ShouldBindJSON(&in)

			propertyID := c.GetString("property_id")
			entryAt, zoneID, isResident, err := repo.OpenLog(c.Request.Context(), propertyID, c.Param("id"))
			if err != nil {
				fail(c, err, "çıkış kaydı")
				return
			}

			minutes := int(time.Since(entryAt).Minutes())
			if minutes < 0 {
				minutes = 0
			}

			fee := money.Kurus(0)
			if !isResident && zoneID != "" {
				// Sitede kayıtlı araçlar ücretsizdir; ücret yalnızca misafir araçlara işler.
				isPaid, hourly, daily, _, _, zerr := repo.ZoneFeeInfo(c.Request.Context(), propertyID, zoneID)
				if zerr != nil {
					fail(c, zerr, "ücret hesabı")
					return
				}
				if isPaid {
					fee = calculateFee(minutes, hourly, daily)
				}
			}

			feeTRY, _ := fee.TRY().Float64()
			if err := repo.RecordExit(c.Request.Context(), propertyID, c.Param("id"),
				in.ExitGate, minutes, feeTRY); err != nil {
				fail(c, err, "çıkış kaydı")
				return
			}

			resp := gin.H{
				"duration_minutes":    minutes,
				"calculated_fee":      feeTRY,
				"is_resident_vehicle": isResident,
			}
			if feeTRY > 0 {
				// Tahsilat altyapısı yok; ücretin TAHSİL EDİLDİĞİ iddia edilmez.
				resp["note"] = "Ücret hesaplandı ancak TAHSİL EDİLMEDİ; ödeme sağlayıcısı " +
					"entegrasyonu henüz yoktur. Tahsilat görevli tarafından yapılmalıdır."
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8098"
	}
	log.Printf("Parking Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// calculateFee, otopark ücretini KURUŞ üzerinden hesaplar.
//
// Kurallar:
//   - Başlanan her saat TAM saat sayılır (otopark işletmeciliğinde yaygın ve
//     beklenen davranış). Bu yüzden 1 dakikalık duruş da ilk saati başlatır.
//   - Günlük ücret tanımlıysa ve saatlik toplam günlüğü aşarsa günlük ücret
//     uygulanır — müşteri aleyhine olmayan hesap.
//   - Ücretsiz tolerans süresi (grace period) TANIMLI DEĞİLDİR. Böyle bir süre
//     isteniyorsa bölge ayarı olarak eklenmelidir (todo: FAZ 7).
//
// Hesap `decimal` ile yapılır ve kuruşa yuvarlanır; float birikimi yoktur.
func calculateFee(minutes int, hourly, daily *float64) money.Kurus {
	if hourly == nil && daily == nil {
		return 0
	}
	if minutes < 0 {
		minutes = 0
	}

	days := minutes / (24 * 60)
	remainder := minutes % (24 * 60)
	// Tam gün katı olmayan her duruşta en az bir saat işler.
	if remainder == 0 && days == 0 {
		remainder = 1
	}

	total := decimal.Zero
	if daily != nil {
		total = total.Add(decimal.NewFromFloat(*daily).Mul(decimal.NewFromInt(int64(days))))
	} else if hourly != nil {
		// Günlük ücret yoksa tüm süre saatlik hesaplanır.
		remainder = minutes
	}

	if remainder > 0 {
		hours := (remainder + 59) / 60 // başlanan saat tam sayılır
		var partial decimal.Decimal
		if hourly != nil {
			partial = decimal.NewFromFloat(*hourly).Mul(decimal.NewFromInt(int64(hours)))
		}
		if daily != nil {
			d := decimal.NewFromFloat(*daily)
			if hourly == nil || partial.GreaterThan(d) {
				partial = d
			}
		}
		total = total.Add(partial)
	}

	return money.FromTRY(total)
}

func hasOpsScope(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleStaff, middleware.RoleSuperAdmin:
			return true
		}
	}
	return false
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrPlateExists):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu plaka sitede zaten kayıtlı"})
	case errors.Is(err, repository.ErrAlreadyInside):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu plaka hâlihazırda otoparkta"})
	case errors.Is(err, repository.ErrNotInside):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu kayıt için açık bir giriş bulunmuyor"})
	case errors.Is(err, repository.ErrUnitNotInSite):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belirtilen bağımsız bölüm bu siteye ait değil"})
	default:
		log.Printf("[parking] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
