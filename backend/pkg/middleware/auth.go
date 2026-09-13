package middleware

import (
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/audit"
	"github.com/siteeksen/backend/pkg/authtoken"
	"github.com/siteeksen/backend/pkg/revocation"
)

// Rol değerleri.
//
// Roller AKTİF SİTEYE göre çözümlenir (migration 013 + identity servisi):
//   - Sakinlik rolleri `resident_units` tablosundan gelir.
//   - Yönetim rolleri `property_roles` tablosundan gelir.
//   - `users.roles` yalnızca platform düzeyi roller içindir (SUPER_ADMIN).
const (
	RoleResident    = "RESIDENT"
	RoleOwner       = "OWNER"
	RoleTenant      = "TENANT"
	RoleManager     = "MANAGER"
	RoleAuditor     = "AUDITOR"
	RoleStaff       = "STAFF"
	RoleBoardMember = "BOARD_MEMBER"
	RoleSuperAdmin  = "SUPER_ADMIN"
)

// Claims, jeton doğrulamasının tek kaynağı olan pkg/authtoken'a takma addır.
// Aynı doğrulama mantığı net/http tabanlı gateway tarafından da kullanılır.
type Claims = authtoken.Claims

// AuthMiddleware, JWT doğrulaması ve JETON İPTALİ denetimi yapar.
//
// `pool` ZORUNLUDUR ve imzada yer alır. Paket düzeyinde bir "kurulmuşsa
// denetle" değişkeni kullanmak, kurulumu unutulan bir serviste iptal edilmiş
// jetonu sessizce kabul etmek olurdu. Bu imza sayesinde eksik kalan her çağrı
// yeri derleme hatası verir.
//
// pool nil ise istek REDDEDİLİR (fail-closed): iptal denetimi yapılamayan bir
// jetona güvenilmez.
func AuthMiddleware(pool *pgxpool.Pool) gin.HandlerFunc {
	checker := revocation.New(pool)
	return func(c *gin.Context) {
		if pool == nil {
			log.Printf("[auth] KRİTİK: jeton iptal denetimi yapılandırılmamış")
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
				"error": "Sunucu kimlik doğrulama yapılandırması eksik",
			})
			return
		}

		claims, err := authtoken.ParseAuthHeader(c.GetHeader("Authorization"))
		if err != nil {
			// GÜVENLİK (2026-09-09): Önceki sürüm JWT_SECRET boş olsa dahi doğrulamaya devam
			// ediyordu. Boş anahtarla HS256 doğrulaması, saldırganın istediği user_id/
			// property_id/roles değerleriyle geçerli token üretmesine izin verir.
			// Artık anahtar yoksa istek reddedilir (fail-closed).
			if errors.Is(err, authtoken.ErrNoSecret) {
				log.Printf("[auth] KRİTİK: JWT_SECRET tanımlı değil — kimlik doğrulama yapılamıyor")
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error": "Sunucu kimlik doğrulama yapılandırması eksik",
				})
				return
			}
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}

		// Jeton iptal edilmiş mi? (çıkış, tüm cihazlardan çıkış, şifre değişikliği)
		var issuedAt time.Time
		if claims.IssuedAt != nil {
			issuedAt = claims.IssuedAt.Time
		}
		revoked, reason, rerr := checker.IsRevoked(
			c.Request.Context(), claims.ID, claims.Subject(), issuedAt)
		if rerr != nil {
			// Denetim yapılamadıysa jeton KABUL EDİLMEZ. "Veritabanı yanıt
			// vermiyor" durumunda iptal edilmiş jetonları kabul etmek, iptal
			// mekanizmasını saldırgan için kapatılabilir hâle getirirdi.
			log.Printf("[auth] jeton iptal denetimi başarısız: %v", rerr)
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
				"error": "Kimlik doğrulama geçici olarak yapılamıyor",
			})
			return
		}
		if revoked {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Oturum sonlandırılmış; lütfen tekrar giriş yapın",
				"note":  reason,
			})
			return
		}

		// Context'e kullanıcı bilgilerini ekle
		// JWT'de user_id "sub" claim'inde de taşınabiliyor
		c.Set("user_id", claims.Subject())
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
