// iot-service — Sayaç yönetimi, endeks okuma ve tüketim giderinin paylaştırılması.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Sayaç ve tüketim uçları mock'tu; sabit endeks
// döndürüyor, okuma isteklerine 2xx dönüp hiçbir yere kaydetmiyordu. Artık gerçek
// veri katmanına bağlıdır (FAZ 5 — 12/22).
//
// KAPSAM SINIRI — DÜRÜSTLÜK: Sensör (sıcaklık/nem/yangın) ve uyarı uçları hâlâ
// gerçek DEĞİLDİR ve bilerek 501 döndürür. Zaman serisi deposu (MongoDB) ne
// kurulu ne de `go.mod`'da; gerçek bir cihaz entegrasyonu da yoktur. Bu uçları
// "çalışıyor" göstermek, yangın sensörünün izlendiği izlenimi verirdi.
//
// Mevzuat: merkezi ısıtma gideri, "Merkezi Isıtma ve Sıhhi Sıcak Su Sistemlerinde
// Isınma ve Sıhhi Sıcak Su Giderlerinin Paylaştırılmasına İlişkin Yönetmelik"
// (RG 14.04.2008/26847) uyarınca %70 tüketim + %30 kullanım alanı olarak
// paylaştırılır. Oranlar koda gömülmez; `legal_parameters` tablosundan okunur.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/stub"
	"github.com/siteeksen/backend/services/iot/repository"
	iotsvc "github.com/siteeksen/backend/services/iot/service"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	repo := repository.New(pool)
	params := legalparams.New(pool)

	r := gin.Default()
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "iot", "persistent": true,
			"scope_note": "Sayaç ve tüketim paylaştırma GERÇEKTİR. Sensör ve uyarı " +
				"uçları gerçek değildir ve 501 döner (zaman serisi deposu ve cihaz " +
				"entegrasyonu yoktur).",
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "iot"))

	// --- Sayaçlar ---
	// Sakin kendi bölümünün sayaçlarını görür; yönetim site genelini görür.
	api.GET("/meters", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		scope := ""
		if !isOps(c) {
			unitID, uerr := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
			if uerr != nil {
				fail(c, uerr, "bağımsız bölüm çözümleme")
				return
			}
			scope = unitID
		} else if q := c.Query("unit_id"); q != "" {
			scope = q
		}
		list, err := repo.ListMeters(c.Request.Context(), propertyID, scope,
			c.Query("meter_type"), c.Query("include_inactive") == "true" && isOps(c))
		if err != nil {
			fail(c, err, "sayaç listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "valid_types": repository.MeterTypes})
	})

	api.GET("/meter-readings", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		if !isOps(c) {
			// Sakin başkasının endeksini göremez; tek sayaç kapsamı zorunludur.
			meterID := c.Query("meter_id")
			if meterID == "" {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "meter_id zorunludur (yalnızca kendi sayacınızın okumalarını görebilirsiniz)"})
				return
			}
			unitID, uerr := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
			if uerr != nil {
				fail(c, uerr, "bağımsız bölüm çözümleme")
				return
			}
			own, oerr := repo.ListMeters(c.Request.Context(), propertyID, unitID, "", true)
			if oerr != nil {
				fail(c, oerr, "sayaç doğrulama")
				return
			}
			allowed := false
			for _, m := range own {
				if m.ID == meterID {
					allowed = true
				}
			}
			if !allowed {
				c.JSON(http.StatusNotFound, gin.H{"error": "Sayaç bulunamadı"})
				return
			}
		}
		from, to, perr := parseRange(c.Query("from"), c.Query("to"))
		if perr != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "from/to YYYY-AA-GG biçiminde olmalıdır"})
			return
		}
		list, err := repo.Readings(c.Request.Context(), propertyID, c.Query("meter_id"), from, to)
		if err != nil {
			fail(c, err, "okuma listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	// --- Görevli/yönetim işlemleri ---
	ops := api.Group("")
	ops.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	{
		ops.POST("/meter-readings", func(c *gin.Context) {
			var in repository.ReadingInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "meter_id ve current_value zorunludur",
					"valid_types": repository.ReadingTypes})
				return
			}
			rd, err := repo.AddReading(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"), in)
			if err != nil {
				fail(c, err, "okuma kaydı")
				return
			}
			resp := gin.H{"reading": rd}
			if rd.ReadingType == "ESTIMATED" {
				resp["note"] = "Bu okuma TAHMİNİDİR. Paylaştırma raporunda tahmini " +
					"okuma yapılan bölümler ayrıca işaretlenir."
			}
			c.JSON(http.StatusCreated, resp)
		})
	}

	// --- Tanımlama ve paylaştırma: yönetim ---
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/meters", func(c *gin.Context) {
			var in struct {
				UnitID           string `json:"unit_id" binding:"required"`
				MeterType        string `json:"meter_type" binding:"required"`
				SerialNumber     string `json:"serial_number" binding:"required"`
				Brand            string `json:"brand"`
				Model            string `json:"model"`
				InstallationDate string `json:"installation_date"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "unit_id, meter_type ve serial_number zorunludur",
					"valid_types": repository.MeterTypes})
				return
			}
			id, err := repo.CreateMeter(c.Request.Context(), c.GetString("property_id"),
				in.UnitID, in.MeterType, in.SerialNumber, in.Brand, in.Model, in.InstallationDate)
			if err != nil {
				fail(c, err, "sayaç kaydı")
				return
			}
			c.JSON(http.StatusCreated, gin.H{"id": id})
		})

		write.DELETE("/meters/:id", func(c *gin.Context) {
			if err := repo.DeactivateMeter(c.Request.Context(),
				c.GetString("property_id"), c.Param("id")); err != nil {
				fail(c, err, "sayaç pasife alma")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"message": "Sayaç pasife alındı",
				"note":    "Okuma geçmişi SİLİNMEDİ; geçmiş dönem paylaştırmaları buna dayanıyor.",
			})
		})

		// Dönem giderini bağımsız bölümlere paylaştırır.
		write.POST("/consumption/allocate", func(c *gin.Context) {
			var in struct {
				MeterType string `json:"meter_type" binding:"required"`
				From      string `json:"from" binding:"required"`
				To        string `json:"to" binding:"required"`
				// `required` bir float için 0'ı da "yok" sayar; sıfır tutar aşağıda
				// anlaşılır bir mesajla (422) reddedilir.
				TotalTRY float64 `json:"total_amount_try"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "meter_type, from ve to zorunludur",
					"valid_types": repository.MeterTypes})
				return
			}
			if in.TotalTRY <= 0 {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": "Paylaştırılacak tutar sıfırdan büyük olmalıdır"})
				return
			}
			from, to, perr := parseRange(in.From, in.To)
			if perr != nil || from == nil || to == nil || to.Before(*from) {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "from/to YYYY-AA-GG biçiminde ve to >= from olmalıdır"})
				return
			}

			propertyID := c.GetString("property_id")
			meterType := strings.ToUpper(in.MeterType)

			basis, missingArea, err := repo.PeriodConsumption(
				c.Request.Context(), propertyID, meterType, *from, *to)
			if err != nil {
				fail(c, err, "dönem tüketimi")
				return
			}
			// Kullanım alanı YALNIZCA ısıtmada gereklidir: sabit pay ona göre
			// dağıtılır. Su/elektrik/gazda alan hiç kullanılmadığı için eksik
			// alan dağıtımı engellemez.
			if meterType == "HEAT" && missingArea {
				fail(c, repository.ErrMissingArea, "dönem tüketimi")
				return
			}

			units := make([]iotsvc.UnitBasis, 0, len(basis))
			withoutReading, estimated := 0, 0
			for _, b := range basis {
				units = append(units, iotsvc.UnitBasis{
					UnitID: b.UnitID, UnitName: b.UnitName,
					Consumption: b.Consumption, UsableArea: b.UsableArea,
				})
				if !b.HasReading {
					withoutReading++
				}
				if b.Estimated {
					estimated++
				}
			}

			total := money.FromFloatTRY(in.TotalTRY)
			var alloc *iotsvc.Allocation
			var basisNote string

			if meterType == "HEAT" {
				// Oranlar mevzuat parametrelerinden; koda gömülmez.
				consShare, cerr := params.Decimal(c.Request.Context(), propertyID,
					legalparams.HeatingConsumptionShare, time.Now())
				if cerr != nil {
					failParam(c, cerr, legalparams.HeatingConsumptionShare)
					return
				}
				areaShare, aerr := params.Decimal(c.Request.Context(), propertyID,
					legalparams.HeatingAreaShare, time.Now())
				if aerr != nil {
					failParam(c, aerr, legalparams.HeatingAreaShare)
					return
				}
				alloc, err = iotsvc.AllocateHeating(total, consShare, areaShare, units)
				basisNote = "Merkezi ısıtma gideri: tüketim + kullanım alanı bileşenleri " +
					"(RG 14.04.2008/26847 sayılı Yönetmelik). Oranlar legal_parameters " +
					"tablosundan okundu, koda gömülü değildir."
			} else {
				alloc, err = iotsvc.AllocateByConsumption(total, units)
				basisNote = "Bu gider türünde sabit pay yoktur; tamamı tüketime göre " +
					"paylaştırılır (tüketmeyen ödemez)."
			}
			if err != nil {
				fail(c, err, "paylaştırma")
				return
			}

			alloc.UnitsWithoutReading = withoutReading
			alloc.UnitsWithEstimated = estimated

			resp := gin.H{
				"allocation": alloc,
				"basis_note": basisNote,
				"note": "Paylaştırma HESAPLANDI ancak aidat tahakkuku olarak " +
					"KAYDEDİLMEDİ; tahakkuk finance servisinden yapılır.",
			}
			if withoutReading > 0 {
				resp["warning_missing_readings"] = withoutReading
				resp["warning"] = "Bazı bağımsız bölümlerde dönem okuması yok; bu " +
					"bölümler tüketim payına sıfır tüketimle girdi. Paylaştırmayı " +
					"kesinleştirmeden önce okumaları tamamlayın."
			}
			if estimated > 0 {
				resp["warning_estimated_readings"] = estimated
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	// --- Gerçek OLMAYAN uçlar: bilerek 501 ---
	// Zaman serisi deposu ve cihaz entegrasyonu yoktur; "çalışıyor" göstermek
	// yangın/su baskını sensörünün izlendiği izlenimi verirdi.
	sensors := api.Group("/sensors")
	{
		sensors.GET("", stub.Handler("iot-sensors"))
		sensors.GET("/:id", stub.Handler("iot-sensors"))
		sensors.GET("/:id/data", stub.Handler("iot-sensors"))
		sensors.POST("/:id/data", stub.Handler("iot-sensors"))
	}
	alerts := api.Group("/iot/alerts")
	{
		alerts.GET("", stub.Handler("iot-alerts"))
		alerts.POST("/:id/acknowledge", stub.Handler("iot-alerts"))
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8084"
	}
	log.Printf("IoT Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func parseRange(fromStr, toStr string) (*time.Time, *time.Time, error) {
	var from, to *time.Time
	if s := strings.TrimSpace(fromStr); s != "" {
		t, err := time.Parse("2006-01-02", s)
		if err != nil {
			return nil, nil, err
		}
		from = &t
	}
	if s := strings.TrimSpace(toStr); s != "" {
		t, err := time.Parse("2006-01-02", s)
		if err != nil {
			return nil, nil, err
		}
		to = &t
	}
	return from, to, nil
}

func isOps(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleAuditor, middleware.RoleStaff:
			return true
		}
	}
	return false
}

// failParam, mevzuat parametresi bulunamadığında açık hata döndürür.
// Sessizce bir varsayılan kullanmak, kanuna aykırı bir paylaştırmayı doğru
// göstermek olurdu.
func failParam(c *gin.Context, err error, code string) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[iot] mevzuat parametresi okunamadı (%s): %v", code, err)
	c.JSON(http.StatusInternalServerError, gin.H{
		"error": "Paylaştırma oranı tanımlı değil: " + code,
		"note": "Oran varsayılan bir değerle TAHMİN EDİLMEZ; legal_parameters " +
			"tablosunda tanımlanmalıdır.",
	})
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Sayaç bulunamadı"})
	case errors.Is(err, repository.ErrUnitNotInSite):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Bağımsız bölüm bu siteye ait değil"})
	case errors.Is(err, repository.ErrDuplicateSerial):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu seri numarası zaten kayıtlı"})
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error":       "Geçersiz tür ya da tarih",
			"valid_types": repository.MeterTypes, "valid_reading_types": repository.ReadingTypes})
	case errors.Is(err, repository.ErrInactive):
		c.JSON(http.StatusConflict, gin.H{"error": "Sayaç pasif; okuma girilemez"})
	case errors.Is(err, repository.ErrDuplicateRead):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu tarih için okuma zaten girilmiş"})
	case errors.Is(err, repository.ErrChainBroken):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Okuma tarihi son okumadan eski ya da aynı",
			"note":  "Endeks zinciri geriye doğru kırılamaz; düzeltme için yeni okuma girin."})
	case errors.Is(err, repository.ErrBackwards):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Endeks son okumadan küçük — sayaç geriye dönemez",
			"note": "Sayaç değiştiyse meter_replaced=true ve gerekçe (reason) ile " +
				"gönderin; aksi hâlde yanlış okuma kabul edilmez.",
		})
	case errors.Is(err, repository.ErrNoReadings):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Bu dönemde ve bu sayaç türünde hiç kayıt yok"})
	case errors.Is(err, repository.ErrMissingArea):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Kullanım alanı (net_area_m2) tanımsız bağımsız bölüm var",
			"note": "Sabit pay kullanım alanına göre dağıtılır; eksik alanı sıfır " +
				"saymak o bölümü paydan muaf tutup diğerlerine yüklerdi.",
			"legal_basis": "RG 14.04.2008/26847 sayılı Yönetmelik",
		})
	case errors.Is(err, iotsvc.ErrNoBasis):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Paylaştırma için yeterli veri yok (tüketim ve kullanım alanı)"})
	case errors.Is(err, iotsvc.ErrInvalidShares):
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Paylaşım oranları toplamı 1 değil — legal_parameters hatalı"})
	case errors.Is(err, repository.ErrInvalidValue):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Endeks negatif olmayan bir sayı olmalıdır (ondalık ayırıcı , ya da .)"})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[iot] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
