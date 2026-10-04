package main

// İstemci hata raporları (todo 3.6, migration 044). Mobil uygulamalar ve panel
// yakalanmayan hatayı buraya bildirir. Metin kısaltılır; kişi başı saatte en çok
// 30 rapor (döngüye giren bir hata veritabanını doldurmasın). Her rapor ayrıca
// yapılandırılmış günlüğe yazılır (günlük toplayıcıdan izlenebilsin).

import (
	"log"
	"net/http"
	"slices"
	"strings"
	"unicode/utf8"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

const clientErrorHourlyLimit = 30

var clientApps = []string{"mobile", "admin_app", "admin_panel"}

func truncateRunes(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	r := []rune(s)
	return string(r[:n])
}

func reportClientError(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			App        string `json:"app"`
			AppVersion string `json:"app_version"`
			Platform   string `json:"platform"`
			Fatal      bool   `json:"fatal"`
			Message    string `json:"message"`
			Stack      string `json:"stack"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.App = strings.TrimSpace(in.App)
		in.Message = strings.TrimSpace(in.Message)
		if !slices.Contains(clientApps, in.App) || in.Message == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "app ve message zorunludur", "valid": clientApps})
			return
		}
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		scope := dbscope.For(pool, propertyID)
		var recent int
		if err := scope.QueryRow(ctx, `SELECT count(*) FROM client_error_reports
			WHERE user_id = $1::uuid AND created_at > now() - interval '1 hour'`, userID).Scan(&recent); err != nil {
			failClientError(c, err)
			return
		}
		if recent >= clientErrorHourlyLimit {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Saatlik hata raporu sınırı aşıldı", "accepted": false})
			return
		}
		msg := truncateRunes(in.Message, 2000)
		stack := truncateRunes(in.Stack, 8000)
		var id string
		if err := scope.QueryRow(ctx, `
			INSERT INTO client_error_reports (property_id, user_id, app, app_version, platform, fatal, message, stack)
			VALUES ($1, NULLIF($2,'')::uuid, $3, NULLIF($4,''), NULLIF($5,''), $6, $7, NULLIF($8,'')) RETURNING id::text`,
			propertyID, userID, in.App, truncateRunes(in.AppVersion, 40), truncateRunes(in.Platform, 40), in.Fatal, msg, stack).Scan(&id); err != nil {
			failClientError(c, err)
			return
		}
		// Günlüğe yalnızca rapor kimliği, uygulama ve ilk satır gider (yığın izi değil).
		first := msg
		if i := strings.IndexByte(first, '\n'); i >= 0 {
			first = first[:i]
		}
		log.Printf("[client-error] id=%s app=%s version=%s platform=%s fatal=%t request_id=%s msg=%q",
			id, in.App, in.AppVersion, in.Platform, in.Fatal, c.GetString("request_id"), truncateRunes(first, 200))
		c.JSON(http.StatusCreated, gin.H{"id": id, "accepted": true})
	}
}

func failClientError(c *gin.Context, err error) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[community] istemci hata raporu yazılamadı: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}
