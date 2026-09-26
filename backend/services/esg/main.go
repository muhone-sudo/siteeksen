// esg-service — Karbon ayak izi hesabı.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-14): Bu servis mock'tu; sabit bir "karbon ayak
// izi" ve uydurma bir "sürdürülebilirlik skoru" döndürüyordu. Artık gerçek
// tüketim verisinden hesap yapar (FAZ 5 — 20/22).
//
// EN ÖNEMLİ TASARIM KARARI: EMİSYON KATSAYISI KODA GÖMÜLMEZ.
// Karbon ayak izi = tüketim × emisyon katsayısı. Katsayı ülkeye, yıla ve enerji
// kaynağına göre değişir (elektrikte şebeke karışımı, doğal gazda yanma
// katsayısı). Doğrulanmamış bir katsayıyı koda gömmek, sayıyı bilimsel
// göstermek ama uydurmak olurdu.
//
// Bu yüzden katsayı ÇAĞIRAN TARAFÇA verilir ve kaynağı da birlikte istenir.
// Katsayı verilmeden hesap YAPILMAZ (422) ve nereden alınacağı söylenir.
// Böylece çıkan sayının dayanağı her zaman bellidir.
//
// "Sürdürülebilirlik skoru" gibi bir bileşik puan ÜRETİLMEZ: kabul görmüş tek
// bir formülü yoktur; ağırlıkları biz uydurursak sayı bir şey ölçmez.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/esg/repository"
)

// factorSources, kullanıcıya katsayıyı nereden alacağını söyler.
var factorSources = []string{
	"Elektrik: TEİAŞ / Enerji ve Tabii Kaynaklar Bakanlığı yıllık şebeke emisyon faktörü",
	"Doğal gaz: IPCC 2006 Rehberi Cilt 2 yanma emisyon faktörleri ya da dağıtım şirketi beyanı",
	"Isı (bölgesel ısıtma): işletmeci firmanın beyan ettiği faktör",
	"Su: yerel su idaresinin arıtma/dağıtım enerji yoğunluğu verisi",
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
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "esg", "persistent": true,
			"scope_note": "Karbon ayak izi GERÇEK tüketim verisinden hesaplanır. " +
				"Emisyon katsayısı koda GÖMÜLMEZ; çağıran taraf kaynağıyla birlikte " +
				"verir. Bileşik 'sürdürülebilirlik skoru' üretilmez.",
		})
	})

	api := r.Group("/api/v1/esg")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "esg"))

	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		// Dönem tüketimi: katsayı gerekmez, ham veri döner.
		read.GET("/consumption", func(c *gin.Context) {
			from, to, perr := parseRange(c.Query("from"), c.Query("to"))
			if perr != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "from/to YYYY-AA-GG biçiminde olmalıdır"})
				return
			}
			totals, err := repo.ConsumptionByType(c.Request.Context(),
				c.GetString("property_id"), from, to)
			if err != nil {
				fail(c, err, "tüketim")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"from": from.Format("2006-01-02"), "to": to.Format("2006-01-02"),
				"consumption": totals,
				"note": "Bu uç yalnızca ölçülen tüketimi döndürür. Karbon ayak izi " +
					"için POST /esg/carbon-footprint kullanın ve emisyon katsayısını " +
					"kaynağıyla birlikte verin.",
			})
		})

		// Karbon ayak izi: katsayı ZORUNLU.
		read.POST("/carbon-footprint", func(c *gin.Context) {
			var in struct {
				From string `json:"from"`
				To   string `json:"to"`
				// Factors: sayaç türü → kg CO2e / birim
				Factors map[string]float64 `json:"emission_factors"`
				// FactorSource: katsayının kaynağı (zorunlu — sayının dayanağıdır)
				FactorSource string `json:"emission_factor_source"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
				return
			}
			if len(in.Factors) == 0 || strings.TrimSpace(in.FactorSource) == "" {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": "Emisyon katsayısı ve kaynağı zorunludur",
					"note": "Katsayı koda GÖMÜLMEZ: ülkeye, yıla ve enerji kaynağına " +
						"göre değişir. Doğrulanmamış bir katsayıyla üretilen sayı " +
						"bilimsel görünür ama uydurmadır. Katsayıyı aşağıdaki " +
						"kaynaklardan alıp kaynağıyla birlikte gönderin.",
					"factor_sources": factorSources,
					"expected_format": map[string]any{
						"emission_factors":       map[string]float64{"ELECTRIC": 0.44, "GAS": 2.0},
						"emission_factor_source": "TEİAŞ 2025 şebeke emisyon faktörü",
					},
					"unit_note": "Katsayı birimi: kg CO2e / sayaç birimi (kWh, m³ …). " +
						"Sayaç birimiyle katsayı biriminin uyuştuğundan emin olun; " +
						"sistem bunu doğrulayamaz.",
				})
				return
			}

			from, to, perr := parseRange(in.From, in.To)
			if perr != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "from/to YYYY-AA-GG biçiminde olmalıdır"})
				return
			}

			totals, err := repo.ConsumptionByType(c.Request.Context(),
				c.GetString("property_id"), from, to)
			if err != nil {
				fail(c, err, "karbon ayak izi")
				return
			}

			type line struct {
				MeterType   string `json:"meter_type"`
				Consumption string `json:"consumption"`
				Factor      string `json:"emission_factor"`
				CO2eKg      string `json:"co2e_kg"`
			}
			lines := []line{}
			missing := []string{}
			total := decimal.Zero

			for _, t := range totals {
				f, ok := in.Factors[t.MeterType]
				if !ok {
					// Katsayısı verilmeyen tür hesaba KATILMAZ ve bu söylenir.
					missing = append(missing, t.MeterType)
					continue
				}
				cons, cerr := decimal.NewFromString(t.Total)
				if cerr != nil {
					continue
				}
				factor := decimal.NewFromFloat(f)
				co2 := cons.Mul(factor).Round(2)
				total = total.Add(co2)
				lines = append(lines, line{
					MeterType: t.MeterType, Consumption: t.Total,
					Factor: factor.String(), CO2eKg: co2.String(),
				})
			}

			if len(lines) == 0 {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error":                 "Verilen katsayılarla eşleşen tüketim verisi yok",
					"available_meter_types": meterTypesOf(totals),
				})
				return
			}

			resp := gin.H{
				"from": from.Format("2006-01-02"), "to": to.Format("2006-01-02"),
				"lines":                  lines,
				"total_co2e_kg":          total.String(),
				"emission_factor_source": strings.TrimSpace(in.FactorSource),
				"method": "CO2e = tüketim × emisyon katsayısı. Katsayı kullanıcı " +
					"tarafından verilmiştir; sistem katsayının doğruluğunu DOĞRULAYAMAZ.",
				"note": "Bu hesap yalnızca SAYAÇLA ÖLÇÜLEN tüketimi kapsar. Atık, " +
					"ulaşım, inşaat malzemesi gibi kalemler hesaba dahil DEĞİLDİR; " +
					"bu yüzden sonuç sitenin toplam karbon ayak izi değildir.",
			}
			if len(missing) > 0 {
				resp["excluded_meter_types"] = missing
				resp["excluded_note"] = "Katsayısı verilmeyen sayaç türleri hesaba " +
					"katılmadı. Eksik katsayı için varsayılan kullanılmaz."
			}
			c.JSON(http.StatusOK, resp)
		})

		// Bileşik skor bilerek üretilmez.
		read.GET("/sustainability-score", func(c *gin.Context) {
			c.JSON(http.StatusNotImplemented, gin.H{
				"error": "Bileşik sürdürülebilirlik skoru ÜRETİLMEZ",
				"note": "Kabul görmüş tek bir formülü yoktur. Ağırlıkları biz " +
					"belirlersek çıkan sayı bir şey ölçmez, yalnızca ölçüyormuş gibi " +
					"görünür. Bunun yerine ölçülebilir veriyi kullanın: " +
					"GET /esg/consumption ve POST /esg/carbon-footprint.",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8093" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("ESG Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func meterTypesOf(totals []repository.TypeTotal) []string {
	out := make([]string, 0, len(totals))
	for _, t := range totals {
		out = append(out, t.MeterType)
	}
	return out
}

// parseRange, dönem aralığını çözer. Verilmezse son 12 ay.
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
	case errors.Is(err, repository.ErrNoData):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Bu dönemde sayaç okuması yok; hesap yapılamaz",
			"note":  "Veri olmadan karbon ayak izi üretilmez."})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[esg] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
