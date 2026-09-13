// personnel-service — Personel (özlük, izin) yönetimi.
//
// DURUM DEĞİŞİKLİĞİ (2026-09-13): Bu servis mock'tu ve sabit JSON döndürüyordu.
// Artık gerçek veri katmanına bağlıdır (FAZ 5 — 2/22).
//
// KVKK: Bu modül TCKN, SGK numarası, IBAN ve maaş işler — kişisel verinin en
// hassas grubudur. Bu yüzden:
//   - Modülün tamamı yönetim rolleri arkasındadır; sakinler erişemez.
//   - STAFF personeli görebilir (vardiya/iletişim) ama maaş, IBAN, SGK ve TCKN'yi GÖREMEZ.
//   - TCKN ve IBAN listelerde MASKELİ döner; maskesiz değer yalnızca yöneticiye
//     ve yalnızca tekil kayıt okumasında verilir.
//   - Her erişim denetim izine yazılır (middleware.AuditLog).
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/personnel/handlers"
	"github.com/siteeksen/backend/services/personnel/repository"
	"github.com/siteeksen/backend/services/personnel/service"
)

func main() {
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	svc := service.New(repository.New(pool))

	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":     "healthy",
			"service":    "personnel",
			"persistent": true,
		})
	})

	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "personnel"))

	// Okuma: yönetim, denetçi ve görevli personel.
	// Hassas alan maskeleme handler katmanında role göre yapılır.
	read := api.Group("")
	read.Use(middleware.RequireRole(
		middleware.RoleManager, middleware.RoleBoardMember,
		middleware.RoleAuditor, middleware.RoleStaff))
	{
		read.GET("/employees", handlers.ListEmployees(svc))
		read.GET("/employees/summary", handlers.Summary(svc))
		read.GET("/employees/:id", handlers.GetEmployee(svc))
		read.GET("/leaves", handlers.ListLeaves(svc))
	}

	// Yazma: yalnızca yönetici ve kurul üyesi. Denetçi ve personel yazamaz.
	write := api.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	{
		write.POST("/employees", handlers.CreateEmployee(svc))
		write.POST("/employees/:id/terminate", handlers.TerminateEmployee(svc))
		write.POST("/leaves", handlers.CreateLeave(svc))
		write.POST("/leaves/:id/approve", handlers.ApproveLeave(svc))
		write.POST("/leaves/:id/reject", handlers.RejectLeave(svc))
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8100"
	}
	log.Printf("Personnel Service başlatıldı: :%s", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
