package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/database"
	"github.com/siteeksen/backend/pkg/middleware"
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
	authService := service.NewAuthService(userRepo, os.Getenv("JWT_SECRET"))

	// Gin router
	r := gin.Default()

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
			auth.POST("/logout", handlers.Logout(authService))
		}
	}

	// Protected routes
	protected := api.Group("/users")
	protected.Use(middleware.AuthMiddleware())
	{
		protected.GET("/me", handlers.GetCurrentUser(authService))
		protected.GET("/me/properties", handlers.GetUserProperties(authService))
		protected.POST("/me/active-property", handlers.SetActiveProperty(authService))
	}

	// Sunucuyu başlat
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}
	log.Printf("Identity Service başlatıldı: :%s", port)
	r.Run(":" + port)
}
