// survey-service — Anket, görüş yoklaması ve danışma oylaması.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu; sabit anket ve sabit sonuç
// döndürüyordu — yani kimse oy vermese bile "%68 evet" yazıyordu. Artık gerçek
// veri katmanına bağlıdır (FAZ 5 — 11/22).
//
// HUKUKİ SINIR (en önemli tasarım kararı):
// Bu servisten alınan sonuç GENEL KURUL KARARI DEĞİLDİR ve karar yerine geçmez.
// Kat malikleri kurulu kararı, KMK m.29-32 uyarınca usulüne uygun çağrı, toplantı
// ve yeter sayı ile alınır; karar defterine yazılır. Bunların tamamı governance
// servisindedir. Bu yüzden `survey_type=GENERAL_ASSEMBLY` isteği REDDEDİLİR —
// bir sitenin çevrimiçi anketi "genel kurul kararı" sanması, sonradan iptal
// davasıyla (KMK m.33) geri dönen bir hatadır.
//
// Diğer hukuka bağlı kararlar:
//   - VOTE türünde oy hakkı yalnızca KAT MALİKLERİNDEDİR ve bağımsız bölüm
//     başına bir oydur (KMK m.31/1). Kiracı görüş yoklamasına katılır, karara değil.
//   - Ağırlıklı oylamada ölçü ARSA PAYIDIR, metrekare değil (KMK m.20). Şemadaki
//     "m² bazlı ağırlık" açıklaması hukuken yanlıştı; kod arsa payını kullanır.
//   - Sonuçlar saklanan sayaçlardan değil, OYLARDAN hesaplanır.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/survey/repository"
)

// legalNotice, her anket yanıtında verilen uyarıdır. Kullanıcının sonucu
// genel kurul kararı sanmasını engeller.
const legalNotice = "Bu sonuç GENEL KURUL KARARI DEĞİLDİR ve karar yerine geçmez. " +
	"Kat malikleri kurulu kararı, usulüne uygun çağrı ve yeter sayı ile toplantıda " +
	"alınır ve karar defterine yazılır (634 s. KMK m.29-32)."

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
			"status": "healthy", "service": "survey", "persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "survey"))

	// Listeleme: sitedeki herkes. Taslaklar yalnızca yönetime görünür.
	api.GET("/surveys", func(c *gin.Context) {
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"),
			c.GetString("user_id"), c.Query("status"), isManagement(c))
		if err != nil {
			fail(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "legal_notice": legalNotice})
	})

	api.GET("/surveys/:id", func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		userID := c.GetString("user_id")

		// Sonuçların görünürlüğünü belirlemek için önce anketi sonuçsuz okuyup
		// ayarına bakarız; sonuç sızdırmamak için iki aşamalı yapılır.
		base, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), userID, false)
		if err != nil {
			fail(c, err, "okuma")
			return
		}
		if base.Status == "DRAFT" && !isManagement(c) {
			// Yayınlanmamış anket sakinlere görünmez.
			c.JSON(http.StatusNotFound, gin.H{"error": "Anket bulunamadı"})
			return
		}

		visible := resultsVisible(base, isManagement(c))
		s, err := repo.Get(c.Request.Context(), propertyID, c.Param("id"), userID, visible)
		if err != nil {
			fail(c, err, "okuma")
			return
		}

		resp := gin.H{"survey": s, "results_visible": visible, "legal_notice": legalNotice}
		if !visible {
			resp["results_note"] = "Sonuçlar oylama bitmeden açıklanmıyor " +
				"(anket ayarı: show_results_before_end=false). Erken sonuç göstermek " +
				"sonraki oyları etkiler."
		}
		if s.IsAnonymous {
			resp["anonymity_note"] = "Anket anonimdir: kimin hangi seçeneğe oy verdiği " +
				"HİÇBİR KULLANICIYA gösterilmez. Ancak aynı kişinin iki kez oy vermesini " +
				"engellemek için oy kaydı kullanıcıya bağlıdır — bu, mutlak anonimlik değildir."
		}
		c.JSON(http.StatusOK, resp)
	})

	api.GET("/surveys/:id/comments", func(c *gin.Context) {
		// Anket yoksa ya da sakin için görünmeyen bir TASLAKSA 404. Önceden bu
		// uçta taslak denetimi yoktu; yayımlanmamış anketin yorumları okunabiliyordu.
		base, err := repo.Get(c.Request.Context(), c.GetString("property_id"), c.Param("id"),
			c.GetString("user_id"), false)
		if err != nil {
			fail(c, err, "okuma")
			return
		}
		if base.Status == "DRAFT" && !isManagement(c) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Anket bulunamadı"})
			return
		}
		list, err := repo.Comments(c.Request.Context(),
			c.GetString("property_id"), c.Param("id"))
		if err != nil {
			fail(c, err, "yorumlar")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	// Oy verme: sitedeki herkes deneyebilir; uygunluk sunucuda denetlenir.
	api.POST("/surveys/:id/vote", func(c *gin.Context) {
		var in struct {
			OptionID string `json:"option_id" binding:"required"`
			Comment  string `json:"comment"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "option_id zorunludur"})
			return
		}
		res, err := repo.Vote(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), in.OptionID, c.GetString("user_id"), in.Comment)
		if err != nil {
			fail(c, err, "oy")
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"message": "Oyunuz kaydedildi", "weight": res.Weight,
			"unit": res.UnitName, "legal_notice": legalNotice,
		})
	})

	// Yönetim işlemleri.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/surveys", func(c *gin.Context) {
			var in repository.CreateInput
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{
					"error":       "title ve en az iki seçenek (options) zorunludur",
					"valid_types": repository.Types})
				return
			}
			id, err := repo.Create(c.Request.Context(),
				c.GetString("property_id"), c.GetString("user_id"), in)
			if err != nil {
				fail(c, err, "oluşturma")
				return
			}
			resp := gin.H{
				"id": id, "status": "DRAFT",
				"note": "Anket TASLAK olarak oluşturuldu; yayına almak için " +
					"POST /surveys/{id}/publish çağrılmalıdır.",
				"legal_notice": legalNotice,
			}
			if in.IsWeighted {
				resp["weighting_note"] = "Ağırlıklı oylamada ölçü ARSA PAYIDIR " +
					"(634 s. KMK m.20), metrekare değil."
			}
			c.JSON(http.StatusCreated, resp)
		})

		write.POST("/surveys/:id/publish", func(c *gin.Context) {
			pub, err := repo.Publish(c.Request.Context(),
				c.GetString("property_id"), c.Param("id"))
			if err != nil {
				fail(c, err, "yayınlama")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status":       "ACTIVE",
				"notification": notifySurveyPublished(c, notifier, pool, pub),
				"legal_notice": legalNotice,
			})
		})

		write.POST("/surveys/:id/close", func(c *gin.Context) {
			if err := repo.Close(c.Request.Context(),
				c.GetString("property_id"), c.Param("id")); err != nil {
				fail(c, err, "sonlandırma")
				return
			}
			c.JSON(http.StatusOK, gin.H{"status": "ENDED", "legal_notice": legalNotice})
		})

		write.POST("/surveys/:id/cancel", func(c *gin.Context) {
			var in struct {
				Reason string `json:"reason" binding:"required"`
			}
			if err := c.ShouldBindJSON(&in); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "İptal gerekçesi zorunludur"})
				return
			}
			if err := repo.Cancel(c.Request.Context(), c.GetString("property_id"),
				c.Param("id"), in.Reason); err != nil {
				fail(c, err, "iptal")
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"status": "CANCELLED",
				"note":   "Verilmiş oylar SİLİNMEDİ; iptal gerekçesi kayda geçti.",
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8104" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Survey Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

// resultsVisible, sonuçların isteği yapana gösterilip gösterilmeyeceğini söyler.
//
// Yönetim her zaman görür (oylamayı yürüten taraftır). Sakinler için: oylama
// bittiyse ya da anket "erken sonuç göster" ayarıyla açıldıysa görünür.
// Erken sonuç göstermek sonraki oyları etkiler; bu yüzden varsayılan kapalıdır.
func resultsVisible(s *repository.Survey, management bool) bool {
	if management {
		return true
	}
	if s.Status == "ENDED" || s.Status == "CANCELLED" {
		return true
	}
	if s.EndsAt != nil && time.Now().After(*s.EndsAt) {
		return true
	}
	return s.ShowResults
}

func isManagement(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleAuditor:
			return true
		}
	}
	return false
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Anket bulunamadı"})
	case errors.Is(err, repository.ErrGeneralAssembly):
		// En önemli reddetme: hukuken geçersiz bir "karar" üretilmesini engeller.
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Genel kurul kararı bu servisten alınamaz",
			"note": "Kat malikleri kurulu kararı için governance servisini kullanın: " +
				"çağrı, yeter sayı (KMK m.30/31) ve karar defteri (m.32) orada işlenir.",
			"legal_basis": "634 s. KMK m.29-32",
		})
	case errors.Is(err, repository.ErrNeedsTwoOptions):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Anket en az iki seçenek içermelidir"})
	case errors.Is(err, repository.ErrAlreadyVoted):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu ankete zaten oy verdiniz"})
	case errors.Is(err, repository.ErrNotEligible):
		c.JSON(http.StatusForbidden, gin.H{
			"error": "Bu oylamada oy hakkınız yok",
			"note": "Karar oylamalarında (VOTE) oy hakkı kat maliklerine aittir ve " +
				"bağımsız bölüm başına bir oydur (634 s. KMK m.31/1).",
		})
	case errors.Is(err, repository.ErrNotStarted):
		c.JSON(http.StatusConflict, gin.H{"error": "Oylama henüz başlamadı"})
	case errors.Is(err, repository.ErrEnded):
		c.JSON(http.StatusConflict, gin.H{"error": "Oylama sona erdi"})
	case errors.Is(err, repository.ErrInvalidOption):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Seçenek bu ankete ait değil"})
	case errors.Is(err, repository.ErrBadState):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Anket bu işlem için uygun durumda değil", "valid_types": repository.Types})
	case errors.Is(err, repository.ErrInvalidDate):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Tarihler geçersiz (RFC3339 bekleniyor; bitiş, başlangıçtan sonra olmalı)"})
	case errors.Is(err, repository.ErrInvalidType):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Anket türü geçersiz", "valid_types": repository.Types})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[survey] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// notifySurveyPublished, yayına alınan anketi sitenin sakinlerine duyurur.
//
// Neden tüm sakinler: anket/oylama katılım içindir; katılacak kişinin haberi
// olmaması, düşük katılımı "ilgisizlik" gibi göstermek olur.
//
// KANUNİ SINIR: buradan gönderilen bildirim, genel kurul ÇAĞRISI DEĞİLDİR.
// 634 s. KMK m.29 çağrının taahhütlü mektupla ya da imza karşılığı
// yapılmasını arar. Bu yüzden gövdeye, sonucun karar yerine geçmediği
// uyarısı eklenir ve konu `assembly.call` OLARAK İŞARETLENMEZ — o konu
// yalnızca yönetişim modülünün gerçek çağrı hatırlatmaları içindir.
func notifySurveyPublished(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool,
	pub *repository.PublishedSurvey) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{
			Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	if pub == nil {
		return &notify.BroadcastResult{Note: "Anket bilgisi çözülemedi; bildirim oluşturulmadı."}
	}

	propertyID := c.GetString("property_id")
	recipients, err := notify.Residents(c.Request.Context(), pool, propertyID)
	if err != nil {
		log.Printf("[survey] anket bildirimi alıcıları alınamadı: %v", err)
		return &notify.BroadcastResult{
			Note: "Alıcı listesi okunamadı; bildirim oluşturulmadı. Anket yayında."}
	}

	kind := "Anket"
	if pub.Type == "VOTE" {
		kind = "Oylama"
	} else if pub.Type == "POLL" {
		kind = "Hızlı anket"
	}
	body := kind + " katılımınıza açıldı: " + pub.Title
	if pub.EndsAt != nil {
		body += "\nSon katılım: " + pub.EndsAt.Format("02.01.2006 15:04")
	}
	body += "\n\n" + legalNotice

	return n.Broadcast(c.Request.Context(), notify.Message{
		PropertyID: propertyID,
		Channel:    notify.ChannelInApp,
		Category:   notify.CategoryTransactional,
		Topic:      "survey.published",
		Subject:    kind + ": " + pub.Title,
		Body:       body,
		Payload: map[string]any{
			"survey_id":   c.Param("id"),
			"survey_type": pub.Type,
		},
		DedupeKey: "survey.published:" + c.Param("id"),
		CreatedBy: c.GetString("user_id"),
	}, recipients)
}
