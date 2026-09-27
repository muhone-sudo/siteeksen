// nps-service — Sakin memnuniyeti ölçümü (Net Tavsiye Skoru).
//
// DURUM DEĞİŞİKLİĞİ (2026-09-14): Bu servis mock'tu; kimse yanıt vermeden
// sabit bir "NPS: 42" döndürüyordu. Artık gerçek veri katmanına bağlıdır
// (FAZ 5 — 19/22).
//
// Veri modeli: AYRI TABLO AÇILMADI. NPS, anket altyapısının (surveys /
// survey_options / survey_votes) özel bir kullanımıdır — 0-10 arası on bir
// seçenekli, anonim bir anket. Ayrı şema açmak aynı veriyi iki yerde tutmak ve
// iki ayrı "kim yanıtladı" mantığı yazmak olurdu.
//
// Hesap tanımı sabittir ve değiştirilmez:
//
//	0-6 kötüleyen, 7-8 kararsız, 9-10 tavsiye eden
//	NPS = %tavsiye eden − %kötüleyen
//
// Kararsızlar skora girmez ama paydada sayılır. Bu tanımın parçasıdır;
// değiştirilirse çıkan sayı "NPS" olmaz.
//
// Anonimlik: yanıtlayanın kimliği HİÇBİR uçta döndürülmez. Kayıt, aynı kişinin
// iki kez yanıtlamasını engellemek için kullanıcıya bağlıdır; bu sınır
// kullanıcıya açıkça söylenir.
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
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/nps/repository"
	npssvc "github.com/siteeksen/backend/services/nps/service"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	repo := repository.New(pool)

	r := middleware.NewRouter("nps")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "nps", "persistent": true,
			"scope_note": "NPS hesabı sabit tanıma göre yapılır (0-6 kötüleyen, " +
				"7-8 kararsız, 9-10 tavsiye eden). Yapay zekâ kullanılmaz.",
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "nps"))

	api.GET("/nps", func(c *gin.Context) {
		list, err := repo.List(c.Request.Context(),
			c.GetString("property_id"), c.GetString("user_id"))
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	// Yanıt verme: sitedeki herkes.
	api.POST("/nps/:id/respond", func(c *gin.Context) {
		var in struct {
			Score   *int   `json:"score" binding:"required"`
			Comment string `json:"comment"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.Score == nil {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "score zorunludur (0-10 arası)"})
			return
		}
		if err := repo.Respond(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), *in.Score, in.Comment); err != nil {
			fail(c, err, "yanıt")
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"message": "Yanıtınız kaydedildi",
			"anonymity_note": "Ankette kimin kaç verdiği HİÇBİR kullanıcıya " +
				"gösterilmez. Kayıt, aynı kişinin iki kez yanıtlamasını engellemek " +
				"için kullanıcıya bağlıdır — bu, mutlak anonimlik değildir.",
		})
	})

	// Sonuçlar yönetime ve denetçiye açıktır.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		read.GET("/nps/:id", func(c *gin.Context) {
			propertyID := c.GetString("property_id")
			s, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), c.GetString("user_id"))
			if err != nil {
				fail(c, err, "okuma")
				return
			}
			scores, err := repo.Scores(c.Request.Context(), propertyID, c.Param("id"))
			if err != nil {
				fail(c, err, "puanlar")
				return
			}

			resp := gin.H{"survey": s}
			result, rerr := npssvc.Calculate(scores)
			if rerr != nil {
				resp["result_note"] = "Henüz yanıt yok; skor hesaplanmadı. " +
					"Sıfır yanıtla skor üretmek uydurma olurdu."
			} else {
				resp["result"] = result
				if s.Eligible > 0 {
					resp["participation_pct"] = participation(result.Responses, s.Eligible)
				}
			}
			resp["method"] = "NPS = %tavsiye eden (9-10) − %kötüleyen (0-6). " +
				"Kararsızlar (7-8) skora girmez, paydada sayılır."
			c.JSON(http.StatusOK, resp)
		})

		// Açık uçlu yorumlar: yönetimin asıl işine yarayan kısım.
		read.GET("/nps/:id/comments", func(c *gin.Context) {
			if ok, err := repo.Exists(c.Request.Context(), c.GetString("property_id"), "surveys", c.Param("id")); err != nil {
				fail(c, err, "kayıt denetimi")
				return
			} else if !ok {
				c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
				return
			}
			list, err := repo.Comments(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "yorumlar")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"data": list,
				"note": "Yorumlar ANONİMDİR; yanıtlayanın kimliği döndürülmez.",
			})
		})
	}

	// Anket açma/kapama: yönetim.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/nps", func(c *gin.Context) {
			var in struct {
				Title       string `json:"title" binding:"required"`
				Description string `json:"description"`
				EndsAt      string `json:"ends_at"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "title zorunludur"})
				return
			}
			var endsAt *time.Time
			if s := strings.TrimSpace(in.EndsAt); s != "" {
				t, perr := time.Parse(time.RFC3339, s)
				if perr != nil {
					c.JSON(http.StatusBadRequest, gin.H{
						"error": "ends_at RFC3339 biçiminde olmalıdır"})
					return
				}
				endsAt = &t
			}
			id, err := repo.Create(c.Request.Context(), c.GetString("property_id"),
				c.GetString("user_id"), in.Title, in.Description, endsAt)
			if err != nil {
				fail(c, err, "oluşturma")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"id": id, "status": "ACTIVE",
				"note": "0-10 arası on bir seçenekli anonim anket açıldı. Sakinlere " +
					"BİLDİRİM GÖNDERİLMEDİ.",
			})
		})

		write.POST("/nps/:id/close", func(c *gin.Context) {
			if err := repo.Close(c.Request.Context(),
				c.GetString("property_id"), c.Param("id")); err != nil {
				fail(c, err, "kapatma")
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": "ENDED"})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8096" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("NPS Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// participation, katılım oranını yüzde olarak verir.
func participation(responses, eligible int) string {
	if eligible <= 0 {
		return "0.0"
	}
	return strconv.FormatFloat(float64(responses)*100/float64(eligible), 'f', 1, 64)
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Memnuniyet anketi bulunamadı"})
	case errors.Is(err, repository.ErrInvalidScore):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Puan 0-10 arasında olmalıdır",
			"note":  "NPS tanımı gereği ölçek sabittir; farklı bir ölçek NPS üretmez."})
	case errors.Is(err, repository.ErrAlreadyVoted):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu ankete zaten yanıt verdiniz"})
	case errors.Is(err, repository.ErrNotEligible):
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Yanıt verebilmek için sitede aktif bir bağımsız bölümünüz olmalıdır"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{"error": "Anket bu işlem için uygun durumda değil"})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[nps] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
