package middleware

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// Claims JWT token payload
type Claims struct {
	UserID     string   `json:"user_id"`
	PropertyID string   `json:"property_id"`
	Roles      []string `json:"roles"`
	jwt.RegisteredClaims
}

// AuthMiddleware JWT doğrulama middleware'i
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header gerekli",
			})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Geçersiz Authorization formatı",
			})
			return
		}

		tokenString := parts[1]
		claims := &Claims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Geçersiz veya süresi dolmuş token",
			})
			return
		}

		// Context'e kullanıcı bilgilerini ekle
		c.Set("user_id", claims.UserID)
		c.Set("property_id", claims.PropertyID)
		c.Set("roles", claims.Roles)

		c.Next()
	}
}

// RequireRole belirli rol gerektirir
func RequireRole(requiredRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		roles, exists := c.Get("roles")
		if !exists {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": "Yetki bilgisi bulunamadı",
			})
			return
		}

		userRoles := roles.([]string)
		for _, required := range requiredRoles {
			for _, userRole := range userRoles {
				if userRole == required {
					c.Next()
					return
				}
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error": "Bu işlem için yetkiniz yok",
		})
	}
}

// AuditLog erişim loglarını kaydeder
func AuditLog() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Request öncesi
		c.Next()

		// Request sonrası - audit log kaydet
		userID, _ := c.Get("user_id")
		// TODO: Audit log veritabanına kaydet
		_ = userID
	}
}
