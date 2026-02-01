package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/identity/service"
)

// LoginRequest giriş isteği
type LoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Login kullanıcı girişi
func Login(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req LoginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		tokens, user, err := svc.Login(c.Request.Context(), req.Phone, req.Password)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Geçersiz telefon veya şifre"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"access_token":  tokens.AccessToken,
			"refresh_token": tokens.RefreshToken,
			"expires_in":    tokens.ExpiresIn,
			"user":          user,
		})
	}
}

// RefreshToken token yenileme
func RefreshToken(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			RefreshToken string `json:"refresh_token" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		tokens, err := svc.RefreshToken(c.Request.Context(), req.RefreshToken)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Geçersiz refresh token"})
			return
		}

		c.JSON(http.StatusOK, tokens)
	}
}

// Logout çıkış işlemi
func Logout(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Token'ı blacklist'e ekle
		c.JSON(http.StatusOK, gin.H{"message": "Çıkış başarılı"})
	}
}

// GetCurrentUser mevcut kullanıcı bilgisi
func GetCurrentUser(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		user, err := svc.GetUserByID(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kullanıcı bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, user)
	}
}

// GetUserProperties kullanıcının kayıtlı siteleri
func GetUserProperties(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		properties, err := svc.GetUserProperties(c.Request.Context(), userID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Siteler alınamadı"})
			return
		}
		c.JSON(http.StatusOK, properties)
	}
}

// SetActiveProperty aktif site seçimi
func SetActiveProperty(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			PropertyID string `json:"property_id" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		userID := c.GetString("user_id")
		err := svc.SetActiveProperty(c.Request.Context(), userID, req.PropertyID)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Site seçilemedi"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Aktif site güncellendi"})
	}
}
