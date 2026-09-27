package middleware

import (
	"log/slog"
	"net/http"
	"os"
	"regexp"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// Yapılandırılmış günlük ve istek kimliği (FAZ 3.5).
//
// NEDEN VAR (2026-09-26):
//   - Servisler gin'in düz metin günlüğünü yazıyordu; bir isteği gateway'den
//     servise ve denetim izine kadar izlemek mümkün değildi.
//   - GÜVENLİK: istemciden gelen X-Request-Id doğrulanmadan denetim izine
//     yazılıyordu. `audit_logs.request_id` 64 karakterdir; daha uzun bir başlık
//     gönderen biri INSERT'i başarısız kılıp denetim kaydının HİÇ yazılmamasını
//     sağlayabiliyordu (denetimden kaçma). Artık biçime uymayan kimlik atılır
//     ve yerine yenisi üretilir.

// RequestIDHeader, istek kimliği başlığıdır.
const RequestIDHeader = "X-Request-Id"

var requestIDPattern = regexp.MustCompile(`^[A-Za-z0-9._-]{1,64}$`)

// SanitizeRequestID, geçerli bir istek kimliğini olduğu gibi döner; boş ya da
// biçime uymayan (uzun, boşluklu, kontrol karakterli) kimlik yerine yenisini üretir.
func SanitizeRequestID(id string) string {
	if requestIDPattern.MatchString(id) {
		return id
	}
	return uuid.NewString()
}

// InitLogging, sürecin günlüğünü JSON'a çevirir. `log` paketiyle yazılan
// satırlar da (log.Printf) aynı işleyiciden geçer; hepsi `service` alanını taşır.
func InitLogging(service string) {
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)).With("service", service))
}

// NewRouter, servisler için ortak gin motorudur: JSON günlük, istek kimliği,
// panik kurtarma. gin.Default()'un düz metin günlüğü yerine kullanılır.
func NewRouter(service string) *gin.Engine {
	InitLogging(service)
	r := gin.New()
	r.Use(RequestLog(), gin.Recovery())
	return r
}

// RequestLog, istek kimliğini doğrular/üretir ve her isteği tek JSON satırıyla
// günlüğe yazar.
//
// Ham yol ve sorgu dizesi YAZILMAZ; yalnızca rota şablonu (/residents/:id)
// yazılır. Sorgu dizesi arama terimi olarak telefon ya da ad taşıyabilir;
// günlüğe kişisel veri sızdırmak KVKK m.12 veri güvenliği yükümlülüğüne aykırıdır.
func RequestLog() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		rid := SanitizeRequestID(c.GetHeader(RequestIDHeader))
		c.Request.Header.Set(RequestIDHeader, rid)
		c.Writer.Header().Set(RequestIDHeader, rid)
		c.Set("request_id", rid)

		c.Next()

		status := c.Writer.Status()
		route := c.FullPath()
		if route == "" {
			route = "(eşleşmeyen yol)"
		}
		// Sağlık yoklamaları (k8s/compose her 10-30 sn) günlüğü boğmasın.
		if route == "/health" && status == http.StatusOK {
			return
		}
		level := slog.LevelInfo
		switch {
		case status >= 500:
			level = slog.LevelError
		case status >= 400:
			level = slog.LevelWarn
		}
		slog.LogAttrs(c.Request.Context(), level, "http",
			slog.String("request_id", rid),
			slog.String("method", c.Request.Method),
			slog.String("route", route),
			slog.Int("status", status),
			slog.Int64("latency_ms", time.Since(start).Milliseconds()),
			slog.String("user_id", c.GetString("user_id")),
			slog.String("property_id", c.GetString("property_id")),
			slog.String("ip", c.ClientIP()),
		)
	}
}
