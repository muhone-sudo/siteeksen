package middleware

import (
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/audit"
)

// jwtSigningMethod — imza algoritması allowlist'i.
// Belirtilmezse jwt kütüphanesi token'ın kendi `alg` başlığına güvenir; bu, algoritma
// karıştırma (algorithm confusion) saldırılarına kapı açar.
var jwtSigningMethods = []string{"HS256"}

// Rol değerleri (users.roles TEXT[] içinde taşınır)
const (
	RoleResident = "RESIDENT"
	RoleOwner    = "OWNER"
	RoleTenant   = "TENANT"
	RoleManager  = "MANAGER"
	RoleAuditor  = "AUDITOR"
	RoleStaff    = "STAFF"
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

		// GÜVENLİK (2026-09-09): Önceki sürüm JWT_SECRET boş olsa dahi doğrulamaya devam
		// ediyordu. Boş anahtarla HS256 doğrulaması, saldırganın istediği user_id/property_id/
		// roles değerleriyle geçerli token üretmesine izin verir. Artık anahtar yoksa istek
		// reddedilir (fail-closed).
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			log.Printf("[auth] KRİTİK: JWT_SECRET tanımlı değil — kimlik doğrulama yapılamıyor")
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "Sunucu kimlik doğrulama yapılandırması eksik",
			})
			return
		}

		tokenString := parts[1]
		claims := &Claims{}

		token, err := jwt.ParseWithClaims(
			tokenString,
			claims,
			func(token *jwt.Token) (interface{}, error) { return []byte(secret), nil },
			jwt.WithValidMethods(jwtSigningMethods),
		)

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Geçersiz veya süresi dolmuş token",
			})
			return
		}

		// Context'e kullanıcı bilgilerini ekle
		// JWT'de user_id "sub" claim'inde taşınıyor
		userID := claims.UserID
		if userID == "" {
			userID = claims.RegisteredClaims.Subject
		}
		c.Set("user_id", userID)
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

		userRoles, ok := roles.([]string)
		if !ok {
			// Kontrolsüz tip dönüşümü panic'e yol açardı; fail-closed davranıyoruz.
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error": "Yetki bilgisi okunamadı",
			})
			return
		}

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

// AuditLog hassas kaynaklara erişimi audit_logs tablosuna kaydeder.
// entityType bu route grubunun neyi temsil ettiğini belirtir (örn. "user", "finance", "credentials").
//
// 2026-09-09 düzeltmeleri:
//   - Hata artık yutulmuyor. Önceki sürüm `_ = audit.LogAction(...)` ile hatayı atıyordu; kolon
//     adları şemayla uyuşmadığı için INSERT her çağrıda başarısız oluyor ve tablo boş kalıyordu.
//     Denetim izi yazılamaması sessizce geçilecek bir durum değildir (KVKK) — en azından loglanır.
//   - `property_id` kaydediliyor (denetim kaydının hangi siteye ait olduğu).
//   - HTTP durum kodu kaydediliyor; 401/403 ile reddedilen istekler `DENIED` olarak ayrışıyor.
//     Böylece yetkisiz erişim denemeleri başarılı erişimlerden ayırt edilebiliyor.
func AuditLog(pool *pgxpool.Pool, entityType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		status := c.Writer.Status()

		// Kimlik doğrulanamadığı için reddedilen istekler (401) denetim izine yazılmaz:
		// kullanıcı bilinmiyor ve bu kayıtlar tabloyu gürültüyle doldurur.
		// Yetkisi olmadığı için reddedilenler (403) ise güvenlik açısından değerlidir, yazılır.
		if status == http.StatusUnauthorized {
			return
		}

		userIDValue, _ := c.Get("user_id")
		userID, _ := userIDValue.(string)

		propertyIDValue, _ := c.Get("property_id")
		propertyID, _ := propertyIDValue.(string)

		action := auditActionFromMethod(c.Request.Method)
		if status == http.StatusForbidden {
			action = "DENIED"
		}

		err := audit.Log(c.Request.Context(), pool, audit.Entry{
			UserID:     userID,
			PropertyID: propertyID,
			IPAddress:  c.ClientIP(),
			UserAgent:  c.Request.UserAgent(),
			Action:     action,
			EntityType: entityType,
			EntityID:   c.Param("id"),
			RequestID:  c.GetHeader("X-Request-Id"),
			StatusCode: status,
		})
		if err != nil {
			// Denetim izi yazılamadı: isteği başarısız saymıyoruz (kullanıcı işlemi tamamlandı),
			// ama sessizce geçmiyoruz — bu kayıt izleme sisteminde uyarı üretmelidir.
			log.Printf("[audit] kayıt yazılamadı: %v (entity=%s action=%s user=%s)",
				err, entityType, action, userID)
		}
	}
}

func auditActionFromMethod(method string) string {
	switch method {
	case http.MethodGet:
		return "VIEW"
	case http.MethodPost:
		return "CREATE"
	case http.MethodPut, http.MethodPatch:
		return "UPDATE"
	case http.MethodDelete:
		return "DELETE"
	default:
		return method
	}
}
