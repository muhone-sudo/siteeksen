// energy_analytics-service — Tüketim analizi ve olağandışı tüketim tespiti.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-14): Bu servis mock'tu; sabit "AI analizi" ve
// uydurma tahminler döndürüyordu. Artık gerçek veri katmanına bağlıdır
// (FAZ 5 — 17/22).
//
// KAPSAM — DÜRÜSTLÜK: BU SERVİSTE YAPAY ZEKÂ YOKTUR.
// Şemadaki `ai_model_version`, `predictions`, `recommendations` alanları
// bilerek DOLDURULMAZ. Bir model olmadan sürüm numarası yazmak ve "gelecek ay
// 1.240 kWh tüketeceksiniz" demek, olmayan bir yeteneği var göstermektir.
//
// Bunun yerine formülü açıkça yazılı, açıklanabilir istatistikler üretilir:
//   - dönemsel toplamlar (okumalardan, saklanmış özetten değil)
//   - önceki dönem ve önceki yıl karşılaştırması
//   - MEDYANDAN sapan bölümlerin işaretlenmesi (kaçak/arıza şüphesi)
//
// Neden medyan: tek bir kaçak ortalamayı yukarı çeker ve kendini normal
// gösterir. Neden alan başına: ham tüketim, büyük daireyi haksız yere
// "anormal" gösterir.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/energy_analytics/repository"
	esvc "github.com/siteeksen/backend/services/energy_analytics/service"
)

// noAINotice, her yanıta eklenen kapsam uyarısıdır.
const noAINotice = "Bu analizde YAPAY ZEKÂ KULLANILMAMIŞTIR. Tüm sonuçlar, " +
	"formülü kodda açıkça yazılı istatistiklerdir. Tahmin (öngörü) üretilmez."

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
			"status": "healthy", "service": "energy_analytics", "persistent": true,
			"scope_note": noAINotice,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "energy"))

	// Analizler yönetim, denetçi ve görevliye açıktır: bölüm bazlı tüketim
	// kişisel veridir ve sakinler birbirininkini görmemelidir.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleStaff))
	{
		// Aylık toplamlar ve eğilim.
		read.GET("/energy/trends", func(c *gin.Context) {
			months, _ := strconv.Atoi(c.Query("months"))
			totals, err := repo.MonthlyTotals(c.Request.Context(),
				c.GetString("property_id"), c.Query("meter_type"), months)
			if err != nil {
				fail(c, err, "eğilim")
				return
			}

			resp := gin.H{"periods": totals, "note": noAINotice}
			if len(totals) >= 2 {
				prev := mustDecimal(totals[len(totals)-2].Total)
				curr := mustDecimal(totals[len(totals)-1].Total)
				resp["month_over_month"] = esvc.CalcTrend(prev, curr)
			}
			// Yıllık karşılaştırma: 13 dönem varsa aynı ayın geçen yılki değeri.
			if len(totals) >= 13 {
				prevYear := mustDecimal(totals[len(totals)-13].Total)
				curr := mustDecimal(totals[len(totals)-1].Total)
				resp["year_over_year"] = esvc.CalcTrend(prevYear, curr)
			} else {
				resp["year_over_year_note"] = "Yıllık karşılaştırma için en az 13 aylık " +
					"okuma gerekir; yeterli veri yok. Eksik veriyle karşılaştırma üretilmez."
			}
			c.JSON(http.StatusOK, resp)
		})

		// Bölüm bazlı tüketim ve olağandışı tüketim tespiti.
		read.GET("/energy/anomalies", func(c *gin.Context) {
			from, to, perr := parseRange(c.Query("from"), c.Query("to"))
			if perr != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "from/to YYYY-AA-GG biçiminde olmalıdır"})
				return
			}
			usages, err := repo.UnitUsages(c.Request.Context(),
				c.GetString("property_id"), c.Query("meter_type"), from, to)
			if err != nil {
				fail(c, err, "olağandışı tüketim")
				return
			}

			// Karşılaştırma ölçüsü: alan başına tüketim. Alanı tanımsız bölümler
			// karşılaştırmaya GİRMEZ — ham tüketimle karşılaştırmak büyük daireyi
			// haksız yere anormal gösterir.
			inputs := make([]esvc.AnomalyInput, 0, len(usages))
			missingArea := 0
			for _, u := range usages {
				in := esvc.AnomalyInput{UnitID: u.UnitID, UnitName: u.UnitName}
				if u.PerSquareMeter != "" {
					in.Value = mustDecimal(u.PerSquareMeter)
					in.HasValue = true
				} else {
					missingArea++
				}
				inputs = append(inputs, in)
			}

			anomalies := esvc.DetectAnomalies(inputs)
			resp := gin.H{
				"usages":    usages,
				"anomalies": anomalies,
				"basis":     "Karşılaştırma ölçüsü: KULLANIM ALANI BAŞINA tüketim (medyana göre sapma).",
				"note":      noAINotice,
			}
			if missingArea > 0 {
				resp["excluded_units"] = missingArea
				resp["excluded_note"] = "Kullanım alanı (net_area_m2) tanımsız bölümler " +
					"karşılaştırmaya alınmadı; ham tüketimle karşılaştırma büyük daireyi " +
					"haksız yere anormal gösterirdi."
			}
			if len(anomalies) == 0 {
				resp["anomalies_note"] = "Olağandışı tüketim bulunamadı ya da karşılaştırma " +
					"için yeterli sayıda (en az 3) ölçülebilir bölüm yok."
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8092" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Energy Analytics Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func mustDecimal(s string) decimal.Decimal {
	v, err := decimal.NewFromString(s)
	if err != nil {
		return decimal.Zero
	}
	return v
}

// parseRange, dönem aralığını çözer. Verilmezse son 12 ay kullanılır.
func parseRange(fromStr, toStr string) (time.Time, time.Time, error) {
	to := time.Now()
	from := to.AddDate(-1, 0, 0)
	if s := strings.TrimSpace(fromStr); s != "" {
		t, err := time.Parse("2006-01-02", s)
		if err != nil {
			return from, to, err
		}
		from = t
	}
	if s := strings.TrimSpace(toStr); s != "" {
		t, err := time.Parse("2006-01-02", s)
		if err != nil {
			return from, to, err
		}
		to = t
	}
	return from, to, nil
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Geçersiz sayaç türü", "valid_types": repository.MeterTypes})
	case errors.Is(err, repository.ErrNoData):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Bu dönemde ve bu sayaç türünde veri yok",
			"note":  "Veri olmadan analiz üretilmez."})
	default:
		log.Printf("[energy] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
