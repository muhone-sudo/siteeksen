package main

import (
	"bytes"
	"errors"
	"image"
	"image/color"
	"image/png"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/middleware"
)

func fail(c *gin.Context, err error, op string) {
	var ue *userError
	switch {
	case errors.As(err, &ue):
		c.JSON(ue.status, gin.H{"error": ue.msg})
	case errors.Is(err, errNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case middleware.DBErrorResponse(c, err):
	default:
		log.Printf("[moderation] %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem yapılamadı: " + op})
	}
}

func validURL(u string) bool {
	return strings.HasPrefix(u, "https://") || strings.HasPrefix(u, "http://")
}

func (a *App) list(c *gin.Context) {
	status := strings.ToUpper(strings.TrimSpace(c.DefaultQuery("status", "REVIEW")))
	list, err := a.store.List(c.Request.Context(), c.GetString("user_id"), status)
	if err != nil {
		fail(c, err, "fotoğraf listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) image(c *gin.Context) {
	it, err := a.store.Get(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	if err != nil {
		fail(c, err, "fotoğraf")
		return
	}
	if a.files == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Dosya deposu yapılandırılmamış"})
		return
	}
	rc, obj, err := a.files.Get(c.Request.Context(), it.StorageKey)
	if err != nil {
		fail(c, err, "fotoğraf okuma")
		return
	}
	defer rc.Close()
	c.Header("X-Content-Type-Options", "nosniff")
	c.Header("Cache-Control", "private, no-store")
	c.DataFromReader(http.StatusOK, obj.Size, obj.ContentType, rc, nil)
}

func (a *App) decide(approve bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason"`
		}
		_ = c.ShouldBindJSON(&in)
		it, err := a.store.Decide(c.Request.Context(), c.GetString("user_id"), c.Param("id"), approve, strings.TrimSpace(in.Reason))
		if err != nil {
			fail(c, err, "fotoğraf kararı")
			return
		}
		c.Set("audit_details", gin.H{"photo_id": it.ID, "status": it.Status, "reason": in.Reason, "source": it.Source})
		if !approve {
			a.notifyRejected(c.Request.Context(), it)
		}
		c.JSON(http.StatusOK, it)
	}
}

func (a *App) recheck(c *gin.Context) {
	it, err := a.store.Recheck(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	if err != nil {
		fail(c, err, "yeniden denetim")
		return
	}
	go a.processDue(c.Copy().Request.Context())
	c.JSON(http.StatusOK, it)
}

func (a *App) aiSettings(c *gin.Context) {
	v, err := a.store.AIView(c.Request.Context(), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "yapay zekâ ayarı")
		return
	}
	c.JSON(http.StatusOK, v)
}

func (a *App) saveAISettings(c *gin.Context) {
	var in AIInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	in.Provider, in.AuthType = strings.ToUpper(strings.TrimSpace(in.Provider)), strings.ToUpper(strings.TrimSpace(in.AuthType))
	in.BaseURL, in.Model, in.Username = strings.TrimSpace(in.BaseURL), strings.TrimSpace(in.Model), strings.TrimSpace(in.Username)
	v, err := a.store.SaveAI(c.Request.Context(), c.GetString("user_id"), in)
	if err != nil {
		fail(c, err, "yapay zekâ ayarı")
		return
	}
	// Gizli değerler işlem kaydına yazılmaz; yalnız değişip değişmedikleri.
	c.Set("audit_details", gin.H{"enabled": v.Enabled, "provider": v.Provider, "base_url": v.BaseURL, "model": v.Model,
		"auth_type": v.AuthType, "api_key_changed": in.APIKey != "" || in.ClearAPIKey, "password_changed": in.Password != "" || in.ClearPassword})
	c.JSON(http.StatusOK, v)
}

// testAI, kayıtlı ayarla sağlayıcıya küçük, düz renkli bir görsel gönderir: bağlantı, kimlik ve yanıt biçimi sınanır.
func (a *App) testAI(c *gin.Context) {
	cfg, err := a.store.AISettings(c.Request.Context())
	if err != nil {
		fail(c, err, "yapay zekâ ayarı")
		return
	}
	img := image.NewRGBA(image.Rect(0, 0, 64, 64))
	for x := 0; x < 64; x++ {
		for y := 0; y < 64; y++ {
			img.Set(x, y, color.RGBA{R: 200, G: 200, B: 200, A: 255})
		}
	}
	var buf bytes.Buffer
	_ = png.Encode(&buf, img)
	v, err := a.ai.Classify(c.Request.Context(), *cfg, buf.Bytes(), "image/png")
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"ok": false, "error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true, "verdict": v, "provider": cfg.Provider, "model": cfg.Model})
}
