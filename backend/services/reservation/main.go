// reservation-service — Ortak alan (havuz, spor salonu, toplantı odası…) rezervasyonu.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit tesis listesi döndürüyor
// ve rezervasyon isteklerine 201 dönüp hiçbir yere kaydetmiyordu. Daha da önemlisi
// ÇAKIŞMA DENETİMİ YOKTU: iki sakin aynı saati "ayırttığını" sanabiliyordu.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 5/22).
//
// Sunucu tarafında uygulanan kurallar (hepsi tesis ayarından okunur):
//   - çakışma denetimi (tesis satırı kilitlenerek, aralık kesişimi + tampon süre)
//   - min/max süre, çalışma saatleri, açık günler, ileri tarih sınırı
//   - bağımsız bölüm başına haftalık rezervasyon kotası
//   - ücret hesabı kuruş üzerinden (pkg/money)
//
// Not: Ücret TAHSİL EDİLMEZ; ödeme sağlayıcısı entegrasyonu yoktur. Hatırlatma
// bildirimi de GÖNDERİLMEZ; bildirim altyapısı henüz bağlı değildir.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/services/reservation/repository"
)

// siteLocation, çalışma saati ve gün denetimlerinin yapılacağı yerel saat dilimi.
// Kat mülkiyeti uygulaması Türkiye'dedir; UTC üzerinden gün/saat denetimi yapmak
// 03:00 kaymasıyla yanlış sonuç verir.
var siteLocation = loadLocation()

func loadLocation() *time.Location {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		// tzdata yoksa sabit +03 kullanılır; sessizce UTC'ye düşülmez.
		log.Printf("[reservation] Europe/Istanbul yüklenemedi (%v); sabit UTC+3 kullanılıyor", err)
		return time.FixedZone("+03", 3*60*60)
	}
	return loc
}

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
			"status": "healthy", "service": "reservation", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "reservation"))

	// --- Tesisler ---
	api.GET("/facilities", func(c *gin.Context) {
		list, err := repo.ListFacilities(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "tesis listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	api.GET("/facilities/:id", func(c *gin.Context) {
		f, err := repo.GetFacility(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			fail(c, err, "tesis okuma")
			return
		}
		c.JSON(http.StatusOK, f)
	})

	// Bir günün DOLU aralıkları — sakin takvimde boş saati görebilsin diye.
	api.GET("/facilities/:id/slots", func(c *gin.Context) {
		day, err := time.ParseInLocation("2006-01-02", c.Query("date"), siteLocation)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "date parametresi YYYY-AA-GG biçiminde olmalıdır"})
			return
		}
		propertyID := c.GetString("property_id")
		f, err := repo.GetFacility(c.Request.Context(), propertyID, c.Param("id"))
		if err != nil {
			fail(c, err, "tesis okuma")
			return
		}
		busy, err := repo.Slots(c.Request.Context(), propertyID, c.Param("id"), day)
		if err != nil {
			fail(c, err, "dolu saat listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"date":           day.Format("2006-01-02"),
			"open":           isOpenDay(f, day),
			"available_from": f.AvailableFrom,
			"available_to":   f.AvailableTo,
			"buffer_minutes": f.BufferMinutes,
			"busy":           busy,
			"note": "Yalnızca DOLU aralıklar döndürülür; tampon süre (buffer_minutes) " +
				"bu aralıkların önüne ve arkasına eklenerek uygulanır.",
		})
	})

	// --- Rezervasyonlar ---
	// Sakin yalnızca kendi rezervasyonlarını görür; yönetim site genelini görür.
	api.GET("/reservations", func(c *gin.Context) {
		scope := ""
		if !hasOpsScope(c) {
			scope = c.GetString("user_id")
		}
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
			scope, c.Query("status"), c.Query("facility_id"))
		if err != nil {
			fail(c, err, "rezervasyon listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	api.POST("/reservations", func(c *gin.Context) {
		var in struct {
			FacilityID string `json:"facility_id" binding:"required"`
			StartTime  string `json:"start_time" binding:"required"`
			EndTime    string `json:"end_time" binding:"required"`
			GuestCount int    `json:"guest_count"`
			Purpose    string `json:"purpose"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "facility_id, start_time ve end_time zorunludur"})
			return
		}

		start, err := parseTime(in.StartTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "start_time geçersiz (RFC3339 bekleniyor)"})
			return
		}
		end, err := parseTime(in.EndTime)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "end_time geçersiz (RFC3339 bekleniyor)"})
			return
		}

		propertyID := c.GetString("property_id")
		userID := c.GetString("user_id")

		f, err := repo.GetFacility(c.Request.Context(), propertyID, in.FacilityID)
		if err != nil {
			fail(c, err, "tesis okuma")
			return
		}

		if reason := validate(f, start, end, in.GuestCount); reason != "" {
			// 422: istek biçimsel olarak doğru ama iş kuralına aykırı.
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": reason})
			return
		}

		unitID, err := repo.ResidentUnit(c.Request.Context(), propertyID, userID)
		if err != nil {
			fail(c, err, "bağımsız bölüm çözümleme")
			return
		}

		// Haftalık kota — tesis ayarı (max_reservations_per_unit) bağımsız bölüm başınadır.
		if f.MaxReservationsPerUnit > 0 {
			n, cerr := repo.WeeklyCount(c.Request.Context(), f.ID, unitID, start)
			if cerr != nil {
				fail(c, cerr, "kota denetimi")
				return
			}
			if n >= f.MaxReservationsPerUnit {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": "Bu tesis için haftalık rezervasyon hakkınız doldu",
					"limit": f.MaxReservationsPerUnit, "current": n})
				return
			}
		}

		fee := money.Kurus(0)
		if f.IsPaid {
			fee = calculateFee(int(end.Sub(start).Minutes()), f.HourlyFee, f.DailyFee)
		}
		feeTRY, _ := fee.TRY().Float64()

		status := "APPROVED"
		if f.RequiresApproval && !f.AutoApproveResidents {
			status = "PENDING"
		}

		id, err := repo.Create(c.Request.Context(), propertyID, f.ID, unitID, userID,
			start, end, f.BufferMinutes, guestCountOr1(in.GuestCount), in.Purpose, status, feeTRY)
		if err != nil {
			fail(c, err, "rezervasyon oluşturma")
			return
		}

		resp := gin.H{"id": id, "status": status, "total_fee": feeTRY}
		if feeTRY > 0 {
			resp["note"] = "Ücret hesaplandı ancak TAHSİL EDİLMEDİ; ödeme sağlayıcısı " +
				"entegrasyonu henüz yoktur."
		}
		if f.Deposit != nil && *f.Deposit > 0 {
			resp["deposit_note"] = "Tesis için depozito tanımlıdır; depozito tahsilatı da yapılmamıştır."
		}
		c.JSON(http.StatusCreated, resp)
	})

	// İptal: sahibi kendi rezervasyonunu iptal edebilir, yönetim herkesinkini.
	api.POST("/reservations/:id/cancel", func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason"`
		}
		_ = c.ShouldBindJSON(&in)

		owner := ""
		if !hasOpsScope(c) {
			owner = c.GetString("user_id")
		}
		if err := repo.Cancel(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), owner, in.Reason); err != nil {
			fail(c, err, "iptal")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Rezervasyon iptal edildi",
			"note":    "İade tutarı hesaplanmadı; tahsilat yapılmadığı için iade de yoktur.",
		})
	})

	// --- Yönetim: onay / red ---
	ops := api.Group("")
	ops.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		ops.POST("/reservations/:id/approve", func(c *gin.Context) {
			if err := repo.Decide(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), "APPROVED", c.GetString("user_id"), ""); err != nil {
				fail(c, err, "onay")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Rezervasyon onaylandı",
				"note":    "Sakine bildirim GÖNDERİLMEDİ; bildirim altyapısı bağlı değildir.",
			})
		})

		ops.POST("/reservations/:id/reject", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				// Gerekçesiz red, sakinin itiraz hakkını işlevsiz bırakır.
				c.JSON(http.StatusBadRequest, gin.H{"error": "Red gerekçesi zorunludur"})
				return
			}
			if err := repo.Decide(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), "REJECTED", c.GetString("user_id"), in.Reason); err != nil {
				fail(c, err, "red")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Rezervasyon reddedildi",
				"note":    "Sakine bildirim GÖNDERİLMEDİ; bildirim altyapısı bağlı değildir.",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8101" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Reservation Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func parseTime(s string) (time.Time, error) {
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func guestCountOr1(n int) int {
	if n < 1 {
		return 1
	}
	return n
}

// isOpenDay, tesisin o gün açık olup olmadığını yerel saate göre söyler.
func isOpenDay(f *repository.Facility, t time.Time) bool {
	if len(f.AvailableDays) == 0 {
		return true
	}
	wd := int(t.In(siteLocation).Weekday()) // 0=Pazar — şema da 0=Pazar diyor
	for _, d := range f.AvailableDays {
		if d == wd {
			return true
		}
	}
	return false
}

// validate, iş kurallarını sunucu tarafında uygular ve ihlâl varsa Türkçe gerekçe döner.
// İstemciye güvenilmez: mobil uygulama bu denetimleri yapsa da sunucu yeniden yapar.
func validate(f *repository.Facility, start, end time.Time, guests int) string {
	if !f.IsActive {
		return "Tesis kullanıma kapalıdır"
	}
	if f.MaintenanceMode {
		if f.MaintenanceNote != "" {
			return "Tesis bakımdadır: " + f.MaintenanceNote
		}
		return "Tesis bakımdadır"
	}
	if !end.After(start) {
		return "Bitiş saati başlangıçtan sonra olmalıdır"
	}

	now := time.Now()
	if start.Before(now) {
		return "Geçmiş bir saat için rezervasyon yapılamaz"
	}
	if f.AdvanceBookingDays > 0 {
		limit := now.AddDate(0, 0, f.AdvanceBookingDays)
		if start.After(limit) {
			return "Bu tesis en fazla " + strconv.Itoa(f.AdvanceBookingDays) + " gün öncesinden rezerve edilebilir"
		}
	}

	minutes := int(end.Sub(start).Minutes())
	if f.MinDurationMinutes > 0 && minutes < f.MinDurationMinutes {
		return "En az " + strconv.Itoa(f.MinDurationMinutes) + " dakika rezervasyon yapılabilir"
	}
	if f.MaxDurationMinutes > 0 && minutes > f.MaxDurationMinutes {
		return "En fazla " + strconv.Itoa(f.MaxDurationMinutes) + " dakika rezervasyon yapılabilir"
	}

	if !isOpenDay(f, start) {
		return "Tesis seçilen günde kapalıdır"
	}

	// Çalışma saatleri yerel saate göre denetlenir. Gece yarısını aşan
	// rezervasyon, tesis kapanış saatini aştığı için zaten reddedilir.
	ls, le := start.In(siteLocation), end.In(siteLocation)
	if ls.Format("2006-01-02") != le.Format("2006-01-02") {
		return "Rezervasyon aynı gün içinde bitmelidir"
	}
	if f.AvailableFrom != "" && ls.Format("15:04") < f.AvailableFrom {
		return "Tesis " + f.AvailableFrom + " öncesinde kapalıdır"
	}
	if f.AvailableTo != "" && le.Format("15:04") > f.AvailableTo {
		return "Tesis " + f.AvailableTo + " sonrasında kapalıdır"
	}

	if f.Capacity != nil && *f.Capacity > 0 && guests > *f.Capacity {
		return "Tesis kapasitesi " + strconv.Itoa(*f.Capacity) + " kişidir"
	}
	return ""
}

// calculateFee, rezervasyon ücretini KURUŞ üzerinden hesaplar.
//
//   - Başlanan her saat tam saat sayılır.
//   - Günlük ücret tanımlıysa ve saatlik toplam günlüğü aşarsa günlük ücret uygulanır
//     (kullanıcı aleyhine olmayan hesap).
//   - İkisi de tanımsızsa ücret sıfırdır; uydurma bir varsayılan kullanılmaz.
func calculateFee(minutes int, hourly, daily *float64) money.Kurus {
	if minutes <= 0 || (hourly == nil && daily == nil) {
		return 0
	}
	hours := (minutes + 59) / 60

	var total decimal.Decimal
	if hourly != nil {
		total = decimal.NewFromFloat(*hourly).Mul(decimal.NewFromInt(int64(hours)))
	}
	if daily != nil {
		d := decimal.NewFromFloat(*daily)
		if hourly == nil || total.GreaterThan(d) {
			total = d
		}
	}
	return money.FromTRY(total)
}

func hasOpsScope(c *gin.Context) bool {
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
	case errors.Is(err, repository.ErrConflict):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Seçilen saat aralığı dolu (tesis tampon süresi dahil)"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Rezervasyon bu işlem için uygun durumda değil ya da size ait değil"})
	case errors.Is(err, repository.ErrNoUnit):
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Bu sitede aktif bir bağımsız bölümünüz bulunmuyor"})
	default:
		log.Printf("[reservation] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
