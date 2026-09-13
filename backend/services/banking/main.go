// banking-service — Banka hesap mutabakatı ve otomatik eşleştirme.
//
// DURUM (2026-09-14): Bu servis mock'tu; sabit banka hesapları, uydurma bakiye
// ve uydurma "eşleşme önerileri" döndürüyordu. Uydurma veri KALDIRILDI.
//
// GERÇEKLEŞTİRİLMEDİ — KULLANICI KARARI (S-07).
// Banka entegrasyonu, `tasks/questions.md` S-07 sorusunda kullanıcıya soruldu ve
// **sonraki sürüme bırakılmasına** karar verildi. Bu bir eksiklik değil, kayıtlı
// bir kapsam kararıdır.
//
// Neden yazılmadı (kararın teknik gerekçesi):
//  1. Her bankanın kendi API'si, sözleşmesi ve kurumsal internet bankacılığı
//     başvurusu vardır. Sözleşme olmadan yazılacak istemci, test edilemez ve
//     doğrulanamaz kod olurdu.
//  2. Banka kimlik bilgileri (API anahtarı, sertifika) alan düzeyinde
//     şifreleme gerektirir; bu altyapı henüz yoktur (todo 2.8). Şifrelemesiz
//     saklamak, tek bir yedek sızıntısında site hesabını ele verir.
//  3. Otomatik eşleştirme, yanlış eşleştiğinde bir sakinin borcunu SİLER ya da
//     başkasının ödemesini ona yazar. Mutabakat mantığı, gerçek banka ekstresi
//     biçimiyle sınanmadan yazılamaz.
//
// Bu yüzden uçlar 501 döndürür ve hiçbir koşulda uydurma bakiye ya da eşleşme
// göstermez. Bugün ödeme kaydı finance servisinde yöneticinin onayıyla yapılır.
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/middleware"
)

const decisionNote = "Banka entegrasyonu, kullanıcı kararıyla (tasks/questions.md " +
	"S-07) SONRAKİ SÜRÜME bırakılmıştır. İstek İŞLENMEDİ ve hiçbir veri " +
	"döndürülmedi. Ödeme kaydı bugün finance servisinde yönetici onayıyla yapılır."

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "healthy", "service": "banking",
			"persistent":    false,
			"module_status": "deferred_by_decision",
			"decision_ref":  "tasks/questions.md S-07",
			"scope_note": "Banka entegrasyonu bilinçli olarak yazılmamıştır. " +
				"Sabit/uydurma bakiye ve eşleşme önerisi DÖNDÜRÜLMEZ.",
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware())

	deferred := func(c *gin.Context) {
		c.Header("X-SiteEksen-Not-Implemented", "true")
		c.JSON(http.StatusNotImplemented, gin.H{
			"error":        "Banka entegrasyonu bu sürümde yoktur",
			"note":         decisionNote,
			"decision_ref": "tasks/questions.md S-07",
			"blockers": []string{
				"Banka API sözleşmesi ve kurumsal internet bankacılığı başvurusu",
				"Alan düzeyinde şifreleme (todo 2.8) — banka kimlik bilgileri için",
				"Gerçek ekstre biçimiyle sınanmış mutabakat mantığı",
			},
		})
	}

	accounts := api.Group("/bank-accounts")
	{
		accounts.GET("", deferred)
		accounts.GET("/banks", deferred)
		accounts.GET("/stats", deferred)
		accounts.GET("/:id", deferred)
		accounts.POST("", deferred)
		accounts.POST("/:id/sync", deferred)
		accounts.GET("/:id/balance", deferred)
		accounts.GET("/:id/transactions", deferred)
	}

	transactions := api.Group("/bank-transactions")
	{
		transactions.GET("", deferred)
		transactions.GET("/unmatched", deferred)
		transactions.GET("/suggestions", deferred)
		transactions.GET("/:id", deferred)
		transactions.POST("/:id/match", deferred)
		transactions.POST("/:id/unmatch", deferred)
		transactions.POST("/auto-match", deferred)
	}

	api.GET("/banking/report", deferred)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8106" // kong/kong.yml ile aynı olmalı
	}
	log.Printf("Banking Service başlatıldı (S-07 kararıyla ertelenmiş): :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
