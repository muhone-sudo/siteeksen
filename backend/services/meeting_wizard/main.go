// meeting_wizard-service — Toplantı sihirbazı.
//
// DURUM (2026-09-14): Bu servis mock'tu ve sabit toplantı kayıtları, uydurma
// "yapay zekâ özeti", uydurma transkript ve uydurma kararlar döndürüyordu.
// FAZ 5 kapsamında ele alındı ve şu karara varıldı (19/22 — kapsam kararı):
//
// BU SERVİS AYRI BİR VERİ KATMANIYLA GERÇEKLEŞTİRİLMEDİ; uçları governance
// servisine yönlendirir. Gerekçe:
//
//  1. TEKRAR OLURDU. Kat malikleri kurulu toplantısının verisi zaten
//     governance servisindedir: çağrı, gündem, katılım, vekâletname, oylama ve
//     KARAR DEFTERİ. Aynı toplantıyı ikinci bir tabloda tutmak, iki ayrı
//     "gerçek" üretir ve hangisinin karar defterine esas olduğu belirsizleşir.
//     Karar defteri KMK m.32 uyarınca tek ve noterce onaylı olmak zorundadır.
//
//  2. "SİHİRBAZ" BİR ARAYÜZ MESELESİDİR. Yöneticiyi çağrıdan tutanağa
//     adım adım götürmek, sunucuda yeni bir veri modeli değil, panelde bir akış
//     gerektirir. Bunun için ayrı bir servis yazmak, arayüz ihtiyacını
//     mimariye taşımaktır.
//
//  3. SES KAYDI VE ÖZETLEME YOKTUR. Transkript ve "yapay zekâ özeti" uçları
//     ses işleme altyapısı gerektirir; böyle bir altyapı ne kurulu ne de
//     planlıdır. Ayrıca genel kurulun ses kaydı KVKK m.5-6 kapsamında ayrı bir
//     hukuki dayanak ve açık rıza sorunu doğurur. Var gibi göstermek yerine
//     olmadığı söylenir.
//
// Tutanak taslağının karar defterine dönüştürülmesi governance servisinin işidir
// (bkz. tasks/todo.md FAZ 6.6).
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
)

// governanceNote, her yanıtta verilen yönlendirmedir.
const governanceNote = "Kat malikleri kurulu toplantısı governance servisinde " +
	"yürütülür: çağrı, gündem, katılım, vekâletname, yeter sayı (KMK m.30/31) ve " +
	"karar defteri (m.32). Bu servis aynı veriyi ikinci kez tutmaz."

func main() {
	// Veritabanı yalnızca JETON İPTALİ denetimi için gerekir (FAZ 2.7):
	// bu servis hiçbir iş verisi tutmaz. Kimlik doğrulama davranışı tüm
	// servislerde aynı olmalıdır; aksi hâlde iptal edilmiş bir jeton burada
	// kabul edilirdi.
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	r := gin.Default()
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "meeting_wizard",
			"persistent":    false,
			"module_status": "redirected",
			"redirect_to":   "governance-service",
			"scope_note": governanceNote + " Ses kaydı ve otomatik özetleme " +
				"YOKTUR ve planlı değildir.",
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool))

	// Toplantı uçları: governance'a yönlendirilir.
	redirect := func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{
			"error":   "Bu modül governance servisinde yürütülür",
			"service": "governance-service",
			"note":    "İstek İŞLENMEDİ. " + governanceNote,
			"endpoints": []string{
				"GET  /api/v1/governance/assemblies",
				"POST /api/v1/governance/assemblies",
				"POST /api/v1/governance/assemblies/{id}/attendees",
				"POST /api/v1/governance/assemblies/{id}/hold",
				"POST /api/v1/governance/agenda-items/{itemId}/votes",
				"POST /api/v1/governance/agenda-items/{itemId}/close",
				"POST /api/v1/governance/books?kind=DECISION&year=YYYY",
				"GET  /api/v1/governance/books/{id}/entries",
			},
			"legal_basis": "634 s. KMK m.29-32",
		})
	}

	// Ses kaydı / özetleme uçları: altyapı yok, var gibi gösterilmez.
	notAvailable := func(c *gin.Context) {
		c.JSON(http.StatusNotImplemented, gin.H{
			"error": "Ses kaydı, transkript ve otomatik özetleme YOKTUR",
			"note": "İstek İŞLENMEDİ. Ses işleme altyapısı kurulu değildir ve " +
				"planlı değildir. Ayrıca genel kurulun ses kaydı, KVKK m.5-6 " +
				"kapsamında ayrı bir hukuki dayanak ve açık rıza sorunu doğurur; " +
				"bu konu çözülmeden böyle bir özellik yazılmayacaktır.",
		})
	}

	meetings := api.Group("/meetings")
	{
		meetings.GET("", redirect)
		meetings.GET("/stats", redirect)
		meetings.GET("/:id", redirect)
		meetings.POST("", redirect)
		meetings.POST("/:id/start", redirect)
		meetings.POST("/:id/end", redirect)
		meetings.GET("/:id/attendees", redirect)
		meetings.POST("/:id/attendees", redirect)
		meetings.POST("/:id/attendance", redirect)
		meetings.GET("/:id/decisions", redirect)
		meetings.GET("/:id/action-items", redirect)
		meetings.POST("/:id/generate-minutes", redirect)

		meetings.POST("/:id/transcribe", notAvailable)
		meetings.GET("/:id/transcript", notAvailable)
		meetings.POST("/:id/summarize", notAvailable)
		meetings.GET("/:id/summary", notAvailable)
	}
	api.GET("/action-items", redirect)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8095" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Meeting Wizard Service başlatıldı (governance'a yönlendirir): :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
