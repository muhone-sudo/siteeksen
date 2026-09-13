// smart_collection-service — Ödeme riski değerlendirmesi ve tahsilat önerisi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-14): Bu servis mock'tu; sabit "AI risk skoru" ve
// uydurma ödeme olasılıkları döndürüyordu. Artık gerçek veri katmanına
// bağlıdır (FAZ 5 — 18/22).
//
// KAPSAM — DÜRÜSTLÜK: BU SERVİSTE YAPAY ZEKÂ YOKTUR.
// Skor, ağırlıkları kodda açıkça yazılı bir kural toplamıdır ve HER BİLEŞENİ
// gerekçesiyle birlikte döner. `ai_model_version` ve "ödeme olasılığı %62"
// gibi alanlar doldurulmaz: model yokken olasılık yazmak uydurmadır.
//
// Neden açıklanabilirlik şart: bu skor, icra takibi gibi sonuçlar doğurabilecek
// bir yönetim kararını besler (634 s. KMK m.20/2 gecikme tazminatı, m.22 kanuni
// ipotek ve takip). Gerekçesi gösterilemeyen bir skor, yönetimin hesap
// veremeyeceği bir karardır.
//
// Servis HİÇBİR İŞLEMİ KENDİLİĞİNDEN YAPMAZ: hatırlatma göndermez, takip
// başlatmaz. Yalnızca önceliklendirme yapar ve ilk adımı ÖNERİR.
package main

import (
	"errors"
	"log"
	"net/http"
	"os"
	"sort"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/smart_collection/repository"
	svc "github.com/siteeksen/backend/services/smart_collection/service"
)

const noAINotice = "Bu değerlendirmede YAPAY ZEKÂ KULLANILMAMIŞTIR. Skor, " +
	"ağırlıkları kodda yazılı bir kural toplamıdır; her bileşeni gerekçesiyle " +
	"birlikte döner. Ödeme olasılığı tahmini ÜRETİLMEZ."

const actionNotice = "Öneriler UYGULANMAZ, yalnızca gösterilir. Hatırlatma " +
	"gönderilmez, icra takibi başlatılmaz. Hukuki adımlar yönetim kararıyla ve " +
	"gereken hâllerde kat malikleri kurulu kararıyla atılır."

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
			"status": "healthy", "service": "smart_collection", "persistent": true,
			"scope_note": noAINotice,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "smart_collection"))

	// Borç ve ödeme geçmişi kişisel veridir; yalnızca yönetim ve denetçi görür.
	// Görevli (staff) BİLEREK dışarıda: kapıcının komşunun borcunu bilmesi için
	// hiçbir meşru gerekçe yoktur (KVKK m.4 veri minimizasyonu).
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		read.GET("/collection/risk", func(c *gin.Context) {
			histories, err := repo.Histories(c.Request.Context(), c.GetString("property_id"))
			if err != nil {
				fail(c, err, "risk değerlendirme")
				return
			}

			list := make([]svc.Assessment, 0, len(histories))
			for _, h := range histories {
				list = append(list, svc.Evaluate(h))
			}
			// En riskli önce: yönetimin sınırlı zamanı en çok buraya harcanmalı.
			sort.Slice(list, func(i, j int) bool { return list[i].Score > list[j].Score })

			counts := map[string]int{}
			unreliable := 0
			for _, a := range list {
				counts[a.Category]++
				if a.TotalAssessments > 0 && !a.Reliable {
					unreliable++
				}
			}

			resp := gin.H{
				"data":   list,
				"totals": counts,
				"method": "Skor bileşenleri: ödenmemiş oranı (40), geç ödeme oranı (20), " +
					"ortalama gecikme (15), en uzun süren gecikme (25). Toplam 100.",
				"note":        noAINotice,
				"action_note": actionNotice,
				"data_limitation": "Ödeme tarihi ayrı bir kolonda tutulmadığı için " +
					"'zamanında ödendi' tespiti kaydın güncellenme tarihinden çıkarılır; " +
					"geçmişe dönük düzeltmelerde yanılabilir.",
			}
			if unreliable > 0 {
				resp["short_history_units"] = unreliable
				resp["short_history_note"] = "Bazı bölümlerin ödeme geçmişi skoru anlamlı " +
					"kılacak kadar uzun değil; bu kayıtlar reliable=false ile işaretlendi."
			}
			c.JSON(http.StatusOK, resp)
		})
	}

	// Skorların kaydı bir yönetim işlemidir (dönemsel karşılaştırma için).
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/collection/risk/snapshot", func(c *gin.Context) {
			propertyID := c.GetString("property_id")
			histories, err := repo.Histories(c.Request.Context(), propertyID)
			if err != nil {
				fail(c, err, "anlık görüntü")
				return
			}
			list := make([]svc.Assessment, 0, len(histories))
			for _, h := range histories {
				list = append(list, svc.Evaluate(h))
			}
			if err := repo.SaveScores(c.Request.Context(), propertyID, list); err != nil {
				fail(c, err, "anlık görüntü kaydı")
				return
			}
			c.JSON(http.StatusCreated, gin.H{
				"saved": len(list),
				"note": "Skorlar bugünün tarihiyle kaydedildi (aynı gün tekrar " +
					"çalıştırılırsa önceki kayıt yenilenir). Skor bileşenlerinin " +
					"gerekçeleri de saklandı: bir ay sonra 'bu daire neden kritikti?' " +
					"sorusunun cevabı kayıtta bulunur.",
				"action_note": actionNotice,
			})
		})
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8103" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Smart Collection Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}

func fail(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNoUnits):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Sitede bağımsız bölüm kaydı yok; değerlendirme yapılamaz"})
	default:
		log.Printf("[smart_collection] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
