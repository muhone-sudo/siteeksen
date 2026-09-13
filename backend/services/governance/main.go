// governance-service — Kat Mülkiyeti Kanunu yönetişim süreçleri.
//
// Kapsam (tasks/modul-envanteri.md M-16…M-20):
//   - İşletme projesi / yıllık bütçe (KMK m.37)
//   - Kat malikleri kurulu (genel kurul) — çağrı, hazirun, vekâlet, nisap, oylama (m.29-33)
//   - Defterler — karar ve işletme defteri, hash zincirli, notere kapatma (m.32, m.36)
//   - İcra/dava takibi ve kanuni ipotek (m.22, İİK m.68)
//
// Bu servis, 22 mock servisin aksine BAŞTAN gerçek veri katmanına bağlı yazılmıştır.
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/governance/handlers"
	"github.com/siteeksen/backend/services/governance/repository"
	"github.com/siteeksen/backend/services/governance/service"
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
	svc := service.New(repo, params)

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":     "healthy",
			"service":    "governance",
			"persistent": true,
		})
	})

	api := r.Group("/api/v1/governance")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "governance"))

	// Okuma: yönetim + denetçi. Denetçinin denetim görevi (m.41) okuma gerektirir.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor))
	{
		read.GET("/budgets", handlers.ListBudgets(svc))
		read.GET("/budgets/:id", handlers.GetBudget(svc))
		read.GET("/budgets/:id/objections", handlers.ListObjections(svc))

		read.GET("/assemblies", handlers.ListAssemblies(svc))
		read.GET("/assemblies/:id", handlers.GetAssembly(svc))
		read.GET("/assemblies/:id/quorum", handlers.GetQuorum(svc))

		read.GET("/books/:id/entries", handlers.ListBookEntries(svc))
		read.GET("/books/:id/verify", handlers.VerifyBook(svc))

		read.GET("/legal-cases", handlers.ListLegalCases(svc))
	}

	// Yazma: yalnızca yönetici ve yönetim kurulu üyesi. Denetçi YAZAMAZ —
	// denetlediği işlemi kendisi yapamamalıdır (görevler ayrılığı).
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/budgets", handlers.CreateBudget(svc))
		write.POST("/budgets/:id/notify", handlers.NotifyBudget(svc))
		write.POST("/budgets/:id/finalize", handlers.FinalizeBudget(svc))
		write.PATCH("/budgets/:id/objections/:objectionId", handlers.ResolveObjection(svc))

		write.POST("/assemblies", handlers.CreateAssembly(svc))
		write.POST("/assemblies/:id/notify", handlers.NotifyAssembly(svc))
		write.POST("/assemblies/:id/attendees", handlers.AddAttendee(svc))
		write.POST("/assemblies/:id/hold", handlers.HoldAssembly(svc))
		write.POST("/agenda-items/:itemId/votes", handlers.CastVote(svc))
		write.POST("/agenda-items/:itemId/close", handlers.CloseAgendaItem(svc))

		write.POST("/books", handlers.EnsureBook(svc))
		write.POST("/books/:id/entries", handlers.AppendBookEntry(svc))
		write.POST("/books/:id/close", handlers.CloseBook(svc))

		write.POST("/legal-cases", handlers.CreateLegalCase(svc))
	}

	// İtiraz hakkı kat malikinindir; yönetim rolü aranmaz (KMK m.37/2).
	api.POST("/budgets/:id/objections", handlers.AddObjection(svc))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8107"
	}
	log.Printf("Governance Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
