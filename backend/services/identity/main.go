package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/revocation"
	"github.com/siteeksen/backend/services/identity/handlers"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

func main() {
	// Veritabanı bağlantısı
	dbConfig := database.NewConfigFromEnv()
	pool, err := database.Connect(dbConfig)
	if err != nil {
		log.Fatalf("Veritabanı bağlantısı başarısız: %v", err)
	}
	defer database.Close()

	// Repository ve Service
	userRepo := repository.NewUserRepository(pool)
	revocationChecker := revocation.New(pool)
	authService := service.NewAuthService(userRepo, os.Getenv("JWT_SECRET")).
		WithRevocations(revocationChecker)
	residentRepo := repository.NewResidentRepository(pool)
	residentService := service.NewResidentService(residentRepo).WithActivation(authService, userRepo)
	roleService := service.NewRoleService(repository.NewRoleRepository(pool), authService, revocationChecker)

	// Gin router
	r := middleware.NewRouter("identity")
	// Biçimi bozuk kimlik 500 değil 404 döner (pkg/middleware/params.go).
	r.Use(middleware.UUIDParams())

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok", "service": "identity"})
	})

	// Public routes
	api := r.Group("/api/v1")
	{
		auth := api.Group("/auth")
		{
			auth.POST("/login", handlers.Login(authService))
			auth.POST("/refresh", handlers.RefreshToken(authService))
			// Etkinleştirme koduyla şifre belirleme (oturum gerektirmez).
			auth.POST("/activate", handlers.Activate(authService))
			// Çıkış, kimlik doğrulama middleware'inin ARKASINDA DEĞİLDİR:
			// süresi dolmuş ya da iptal edilmiş bir jetonla da çıkış denenebilmeli
			// ve istemci anlamlı bir yanıt almalıdır. Jeton başlıktan elle okunur.
			auth.POST("/logout", handlers.Logout(revocationChecker))
		}
	}

	// Protected routes
	protected := api.Group("/users")
	protected.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "user"))
	{
		protected.GET("/me", handlers.GetCurrentUser(authService))
		protected.GET("/me/properties", handlers.GetUserProperties(authService))
		protected.POST("/me/properties", middleware.RequireRole(middleware.RoleManager, middleware.RoleOwner), handlers.CreateProperty(authService))
		protected.POST("/me/active-property", handlers.SetActiveProperty(authService))
		protected.POST("/me/kvkk-consent", handlers.SetKVKKConsent(authService))
		// Tüm cihazlardan çıkış: hesabın ele geçirildiği şüphesinde kullanılır.
		protected.POST("/me/logout-all", handlers.LogoutAll(revocationChecker))
		protected.POST("/me/password", handlers.ChangePassword(authService))
		// Sakin davetleri (S-20): kişi başka sitenin davetini kendisi kabul eder.
		protected.GET("/me/invitations", handlers.MyInvitations(residentService))
		protected.POST("/me/invitations/:id/accept", handlers.RespondInvitation(residentService, true))
		protected.POST("/me/invitations/:id/decline", handlers.RespondInvitation(residentService, false))
	}

	// Sakinler ve birimler
	residents := api.Group("/residents")
	residents.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "resident"))
	{
		residents.GET("", handlers.ListResidents(residentService))
		residents.POST("", handlers.CreateResident(residentService))
		residents.POST("/bulk", handlers.BulkCreateResidents(residentService))
		residents.GET("/invitations", handlers.ListInvitations(residentService))
		residents.POST("/invitations/:id/cancel", handlers.CancelInvitation(residentService))
		residents.GET("/:id", handlers.GetResident(residentService))
		residents.PATCH("/:id", handlers.UpdateResident(residentService))
		residents.POST("/:id/activation-code", handlers.IssueActivationCode(residentService))
	}

	// Site görevlendirmeleri: yönetici, kurul üyesi, denetçi, görevli (2026-10-03).
	siteRoles := api.Group("/property-roles")
	siteRoles.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "property_role"))
	{
		siteRoles.GET("", handlers.ListSiteRoles(roleService))
		siteRoles.POST("", handlers.GrantSiteRole(roleService))
		siteRoles.POST("/:id/end", handlers.EndSiteRole(roleService))
	}

	units := api.Group("/units")
	units.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "unit"))
	{
		units.GET("", handlers.ListUnits(residentService))
		// Site kurulumu (FAZ 8.1): tek ya da toplu bölüm ekleme, güncelleme.
		units.POST("", handlers.CreateUnits(residentService))
		units.PATCH("/:id", handlers.UpdateUnit(residentService))
	}

	// Sunucuyu başlat
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}
	log.Printf("Identity Service başlatıldı: :%s", port)
	r.Run(":" + port)
}
