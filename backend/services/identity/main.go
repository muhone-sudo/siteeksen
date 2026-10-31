package main

import (
	"errors"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/revocation"
	"github.com/siteeksen/backend/pkg/storage"
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
	authService.WithInvitations(residentRepo)
	residentService := service.NewResidentService(residentRepo).WithActivation(authService, userRepo)

	// Etkinleştirme kodu SMS ile (Netgsm; TEST_RAPORU 2.4). Yapılandırma yoksa kod
	// yalnızca yöneticiye gösterilir; yarım/hatalı yapılandırma açılışı durdurur.
	if sms, err := notify.NetgsmFromEnv(); err != nil {
		log.Fatalf("SMS yapılandırması hatalı: %v", err)
	} else if sms != nil {
		handlers.SetActivationSMS(sms)
		log.Printf("[identity] etkinleştirme kodları SMS ile gönderilecek (netgsm)")
	}
	if mail, err := notify.SMTPFromEnv(); err != nil {
		log.Fatalf("SMTP yapılandırması hatalı: %v", err)
	} else if mail != nil {
		handlers.SetActivationEmail(mail)
	}
	// Kiracılık bitişi belgeleri (069, D4). Yapılandırılmamışsa servis açılır, yönetim yolu 503 döner;
	// yapılandırma HATALIYSA servis açılmaz (sessiz dosya kaybı olmasın).
	store, serr := storage.FromEnv()
	if errors.Is(serr, storage.ErrNotConfigured) && os.Getenv("STORAGE_BACKEND") == "" {
		log.Printf("[identity] dosya deposu yapılandırılmamış: kiracılık bitişi yönetim yolu belgesi saklanamaz (STORAGE_BACKEND)")
		store = nil
	} else if serr != nil {
		log.Fatalf("Dosya deposu yapılandırması hatalı: %v", serr)
	}
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
		// Giriş/çıkış ve hesap kurtarma olayları zorunlu işlem kaydıdır (073); başarısız giriş (401) de yazılır.
		auth.Use(middleware.AuditLog(pool, "auth"))
		{
			auth.POST("/login", handlers.Login(authService))
			auth.POST("/refresh", handlers.RefreshToken(authService))
			// Etkinleştirme koduyla şifre belirleme (oturum gerektirmez).
			auth.POST("/activate", handlers.Activate(authService))
			// Sakinin kendi "şifremi unuttum" isteği (beşinci tur B3): kod SMS/e-postayla gider.
			auth.POST("/password-reset/request", handlers.RequestPasswordReset(authService))
			// Tedarikçinin kendi kaydı (076, FAZ M1): kod → doğrulama → hesap/rol.
			auth.POST("/supplier-signup/request", handlers.RequestSupplierSignup(authService))
			auth.POST("/supplier-signup/verify", handlers.VerifySupplierSignup(authService))
			auth.POST("/supplier-signup/complete", handlers.CompleteSupplierSignup(authService))
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
		// Sakinin kendi telefon/e-posta değişikliği (062, beşinci tur B4).
		protected.POST("/me/phone/request", handlers.RequestPhoneChange(authService))
		protected.POST("/me/phone/confirm", handlers.ConfirmPhoneChange(authService))
		protected.POST("/me/email", handlers.RequestEmailChange(authService))
		protected.POST("/me/email/confirm", handlers.ConfirmEmailChange(authService))
		// Malikin kendi bölümündeki kiracı/vekil yönetimi (beşinci tur B5).
		protected.GET("/me/units/:id/residents", handlers.OwnerUnitResidents(residentService))
		// Altıncı tur D3: malik ve oturan doğrudan eklemez, davet gönderir (SMS + e-posta).
		protected.POST("/me/units/:id/invitations", handlers.OwnerInvite(residentService))
		protected.POST("/me/units/:id/residents/:residentId/end", handlers.OwnerEndResident(residentService))
		// Kiracılığın bitişi (069, D4): malik ister + kiracı onaylar; kiracı kendi çıkışını bildirir; itiraz.
		protected.POST("/me/units/:id/tenancy-end", handlers.OwnerRequestTenancyEnd(residentService))
		protected.POST("/me/units/:id/tenancy-exit", handlers.TenantExitHandler(residentService))
		protected.GET("/me/tenancy-requests", handlers.MyTenancyRequests(residentService))
		protected.POST("/me/tenancy-requests/:id/approve", handlers.TenantRespondHandler(residentService, true))
		protected.POST("/me/tenancy-requests/:id/decline", handlers.TenantRespondHandler(residentService, false))
		protected.POST("/me/tenancy-requests/:id/object", handlers.TenantObjectHandler(residentService))
		protected.POST("/me/tenancy-requests/:id/cancel", handlers.OwnerCancelHandler(residentService))
		protected.GET("/me/tenancy-requests/:id/documents/:docId", handlers.EndDocumentDownload(residentService, store))
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
		residents.POST("/invitations", handlers.ManagementInvite(residentService))
		residents.POST("/invitations/:id/cancel", handlers.CancelInvitation(residentService))
		// Kiracılığın bitişi — yönetim yolu (069, D4): belge + şifreyle beyan + 7 gün itiraz.
		residents.GET("/tenancy-requests", handlers.ManagementTenancyRequests(residentService))
		residents.POST("/tenancy-requests", handlers.ManagementStartHandler(residentService, store))
		residents.POST("/tenancy-requests/:id/documents", handlers.ManagementNewDocumentHandler(residentService, store))
		residents.POST("/tenancy-requests/:id/complete", handlers.ManagementCompleteHandler(residentService))
		residents.POST("/tenancy-requests/:id/cancel", handlers.ManagementCancelHandler(residentService))
		residents.POST("/tenancy-requests/:id/reverse", handlers.ManagementReverseHandler(residentService))
		residents.GET("/tenancy-requests/:id/documents/:docId", handlers.EndDocumentDownload(residentService, store))
		residents.GET("/:id", handlers.GetResident(residentService))
		residents.PATCH("/:id", handlers.UpdateResident(residentService))
		residents.POST("/:id/activation-code", handlers.IssueActivationCode(residentService))
		// Yönetim destekli hesap kurtarma (Apsiyon BUG-05/06): telefon değişikliği, giriş kilidi kaldırma.
		residentAdmin := middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember)
		residents.POST("/:id/phone", residentAdmin, handlers.ChangeResidentPhone(userRepo, authService, revocationChecker))
		residents.POST("/:id/unlock", residentAdmin, handlers.UnlockResidentLogin(userRepo))
	}

	// Site yaşam döngüsü (058, Apsiyon BUG-11): pasifleştirme yalnızca yönetici, gerekçe ve site adı onayıyla.
	site := api.Group("/property")
	site.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "property"))
	{
		site.GET("", handlers.PropertyStatus(pool))
		site.POST("/deactivate", middleware.RequireRole(middleware.RoleManager), handlers.SetPropertyActive(pool, false))
		site.POST("/reactivate", middleware.RequireRole(middleware.RoleManager), handlers.SetPropertyActive(pool, true))
		// Site konumu (077, FAZ M2.4): Usta & Hizmet eşleşmesi için.
		site.PUT("/location", middleware.RequireRole(middleware.RoleManager), handlers.SetPropertyLocation(pool))
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
