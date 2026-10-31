package main

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/iyzico"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/storage"
	"github.com/siteeksen/backend/services/marketplace/store"
)

// App, uçların ortak bağımlılıklarıdır.
type App struct {
	store    *store.Store
	notifier *notify.Notifier
	// files, belge ve fotoğraf deposudur; yapılandırılmamışsa nil (dosya uçları 503).
	files storage.Store
	// card, bakiye yüklemesi için ödeme sağlayıcısıdır; yapılandırılmamışsa nil (yükleme 503).
	card *iyzico.Client
}

// fail, hatayı istemciye uygun yanıta çevirir; tanınmayan hata 500'dür ve ayrıntısı günlüğe yazılır.
func fail(c *gin.Context, err error, op string) {
	var ue *store.UserError
	switch {
	case errors.As(err, &ue):
		body := gin.H{"error": ue.Message}
		if ue.Code != "" {
			body["code"] = ue.Code
		}
		if ue.Note != "" {
			body["note"] = ue.Note
		}
		c.JSON(ue.Status, body)
	case errors.Is(err, store.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case middleware.DBErrorResponse(c, err):
	default:
		log.Printf("[marketplace] %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem yapılamadı: " + op})
	}
}

// hasRole, oturumdaki rollerden birinin verilenlerden olup olmadığını söyler.
func hasRole(c *gin.Context, roles ...string) bool {
	v, _ := c.Get("roles")
	mine, _ := v.([]string)
	for _, r := range roles {
		for _, m := range mine {
			if m == r {
				return true
			}
		}
	}
	return false
}
