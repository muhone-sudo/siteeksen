package handlers

import (
	"errors"
	"github.com/siteeksen/backend/pkg/middleware"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

// normalizePhone, telefonu tek biçime (+90XXXXXXXXXX) getirir. Boşluk, tire,
// parantez ve nokta atılır: "0 (555) 123-45-67" ile "+905551234567" aynı kişidir.
func normalizePhone(phone string) string {
	phone = strings.Map(func(r rune) rune {
		switch r {
		case ' ', '-', '(', ')', '.', '\t':
			return -1
		}
		return r
	}, strings.TrimSpace(phone))
	if strings.HasPrefix(phone, "+90") {
		return phone
	}
	if strings.HasPrefix(phone, "0") {
		return "+90" + phone[1:]
	}
	if len(phone) == 10 {
		return "+90" + phone
	}
	return phone
}

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

		tokens, user, err := svc.Login(c.Request.Context(), normalizePhone(req.Phone), req.Password)
		if errors.Is(err, service.ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Geçersiz telefon veya şifre"})
			return
		}
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[identity] giriş yapılamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Giriş şu anda yapılamıyor; lütfen daha sonra deneyin"})
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
		switch {
		case errors.Is(err, service.ErrTokenReused):
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Oturumunuz güvenlik nedeniyle kapatıldı; lütfen yeniden giriş yapın",
				"note":  "Bu yenileme jetonu daha önce kullanılmıştı. Jetonunuz başka bir cihaza geçmiş olabilir; bütün oturumlar kapatıldı. Şüpheleniyorsanız şifrenizi değiştirin.",
			})
			return
		case errors.Is(err, service.ErrInvalidToken), errors.Is(err, service.ErrTokenRevoked):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Geçersiz refresh token"})
			return
		case errors.Is(err, service.ErrRevocationUnavailable):
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Oturum doğrulanamadı; lütfen biraz sonra deneyin"})
			return
		case err != nil:
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[identity] jeton yenilenemedi: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Oturum yenilenemedi"})
			return
		}

		c.JSON(http.StatusOK, tokens)
	}
}

// GetCurrentUser mevcut kullanıcı bilgisi
func GetCurrentUser(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		user, err := svc.GetUserByID(c.Request.Context(), userID)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kullanıcı bulunamadı"})
			return
		}
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[identity] kullanıcı okunamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Kullanıcı bilgisi alınamadı"})
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
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
			// Kullanıcının bağlı olmadığı bir site seçmeye çalışması bir yetki ihlalidir;
			// 400 değil 403 döner ve denetim izinde DENIED olarak ayrışır.
			if errors.Is(err, repository.ErrPropertyNotOwned) {
				c.JSON(http.StatusForbidden, gin.H{"error": "Bu siteye erişim yetkiniz yok"})
				return
			}
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[identity] aktif site güncellenemedi (user=%s): %v", userID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Site seçilemedi"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"message": "Aktif site güncellendi"})
	}
}

// SetKVKKConsent kullanıcının KVKK açık rıza onayını kaydeder
func SetKVKKConsent(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		if err := svc.SetKVKKConsent(c.Request.Context(), userID); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Onay kaydedilemedi"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "KVKK onayı kaydedildi"})
	}
}

// CreateProperty yeni site oluşturur
func CreateProperty(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req models.CreatePropertyRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		userID := c.GetString("user_id")
		property, err := svc.CreateProperty(c.Request.Context(), userID, req)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Site oluşturulamadı"})
			return
		}

		c.JSON(http.StatusCreated, property)
	}
}

// Activate, etkinleştirme koduyla şifre belirler (kimlik doğrulaması gerekmez).
func Activate(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Phone       string `json:"phone" binding:"required"`
			Code        string `json:"code" binding:"required"`
			NewPassword string `json:"new_password" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Telefon, kod ve yeni şifre zorunludur"})
			return
		}
		err := svc.Activate(c.Request.Context(), normalizePhone(in.Phone), in.Code, in.NewPassword)
		switch {
		case errors.Is(err, service.ErrWeakPassword):
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		case errors.Is(err, repository.ErrInvalidCode):
			c.JSON(http.StatusBadRequest, gin.H{"error": "Telefon ya da kod hatalı, kod kullanılmış veya süresi dolmuş"})
		case errors.Is(err, repository.ErrCodeLocked):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Kod çok sayıda hatalı deneme nedeniyle kilitlendi; yönetimden yeni kod isteyin"})
		case err != nil:
			log.Printf("[identity] etkinleştirme başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Şifre belirlenemedi"})
		default:
			c.JSON(http.StatusOK, gin.H{"message": "Şifreniz belirlendi; şimdi giriş yapabilirsiniz"})
		}
	}
}

// ChangePassword, oturumdaki kullanıcının şifresini değiştirir.
func ChangePassword(svc *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			CurrentPassword string `json:"current_password" binding:"required"`
			NewPassword     string `json:"new_password" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Mevcut ve yeni şifre zorunludur"})
			return
		}
		err := svc.ChangePassword(c.Request.Context(), c.GetString("user_id"), in.CurrentPassword, in.NewPassword)
		switch {
		case errors.Is(err, service.ErrWrongPassword):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		case errors.Is(err, service.ErrWeakPassword):
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		case err != nil:
			log.Printf("[identity] şifre değiştirilemedi: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Şifre değiştirilemedi"})
		default:
			c.JSON(http.StatusOK, gin.H{
				"message": "Şifreniz değiştirildi",
				"note":    "Güvenlik için bütün oturumlarınız kapatıldı; yeniden giriş yapın.",
			})
		}
	}
}
