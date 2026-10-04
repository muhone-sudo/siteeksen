package main

// KVKK ilgili kişi başvuruları (FAZ 7.8, migration 035).
//
// Sakin/personel kendi başvurusunu açar ve izler; yönetim site genelini görür
// ve sonuçlandırır. Yanıt süresi kanunla sabittir (KVKK m.13/2) ve
// legal_parameters'tan okunur; son gün başvuru anında kayda yazılır.

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/community/repository"
)

var kvkkTypeLabels = map[string]string{
	"INFO": "bilgi talebi", "CORRECTION": "düzeltme", "ERASURE": "silme/yok etme",
	"OBJECTION": "itiraz", "COMPENSATION": "zararın giderilmesi", "OTHER": "diğer",
}

func registerKVKK(r *gin.Engine, pool *pgxpool.Pool, notifier *notify.Notifier) {
	repo := repository.NewKVKKRepository(pool)
	params := legalparams.New(pool)

	g := r.Group("/api/v1/kvkk-requests")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "kvkk_request"))

	// Kendi başvurusu ya da (yönetim) site geneli.
	g.GET("", func(c *gin.Context) {
		owner := c.GetString("user_id")
		if isManagement(c) {
			owner = ""
		}
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"), owner)
		if err != nil {
			failKVKK(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	g.POST("", func(c *gin.Context) {
		var in struct {
			RequestType string `json:"request_type"`
			Description string `json:"description"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.RequestType = strings.ToUpper(strings.TrimSpace(in.RequestType))
		in.Description = strings.TrimSpace(in.Description)
		if !slices.Contains(repository.KVKKRequestTypes, in.RequestType) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Başvuru türü geçersiz", "valid": repository.KVKKRequestTypes})
			return
		}
		if len(in.Description) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Talebinizi kısaca açıklayın (en az 10 karakter)"})
			return
		}
		propertyID := c.GetString("property_id")
		days, err := params.Int(c.Request.Context(), propertyID, legalparams.KVKKResponseDays, time.Now())
		if err != nil {
			// Süre bilinmeden başvuru kaydedilmez: son günü uydurmak yanıltıcı olurdu.
			log.Printf("[community] KVKK yanıt süresi okunamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Yasal yanıt süresi okunamadı; başvuru kaydedilmedi"})
			return
		}
		k, err := repo.Create(c.Request.Context(), propertyID, c.GetString("user_id"), in.RequestType, in.Description, days)
		if err != nil {
			failKVKK(c, err, "kayıt")
			return
		}
		res := notifyKVKK(c, notifier, pool, propertyID, nil, notify.Message{
			Topic:   "kvkk.request",
			Subject: "Yeni KVKK başvurusu (" + kvkkTypeLabels[k.RequestType] + ")",
			Body: fmt.Sprintf("%s bir KVKK başvurusu yaptı. Kanun gereği en geç %s tarihine kadar yanıtlanmalı (KVKK m.13).",
				k.ApplicantName, k.DueDate.Format("02.01.2006")),
			Payload:   map[string]any{"kvkk_request_id": k.ID},
			DedupeKey: "kvkk.request:" + k.ID,
		})
		c.JSON(http.StatusCreated, gin.H{"request": k, "notification": res,
			"note": fmt.Sprintf("Başvurunuz kaydedildi; site yönetimi en geç %s tarihine kadar yanıtlamakla yükümlüdür.",
				k.DueDate.Format("02.01.2006"))})
	})

	write := g.Group("")
	write.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	write.POST("/:id/respond", func(c *gin.Context) {
		var in struct {
			Status   string `json:"status"`
			Response string `json:"response"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Status = strings.ToUpper(strings.TrimSpace(in.Status))
		in.Response = strings.TrimSpace(in.Response)
		if !slices.Contains(repository.KVKKResultStatus, in.Status) || in.Response == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{
				"error": "Sonuç ANSWERED ya da REJECTED olmalı ve yanıt metni boş olamaz (ret gerekçeli olmalıdır, KVKK m.13/3)"})
			return
		}
		propertyID := c.GetString("property_id")
		k, err := repo.Respond(c.Request.Context(), propertyID, c.Param("id"), c.GetString("user_id"), in.Status, in.Response)
		if err != nil {
			failKVKK(c, err, "yanıt")
			return
		}
		res := notifyKVKK(c, notifier, pool, propertyID,
			[]notify.Recipient{{UserID: k.UserID}}, notify.Message{
				Topic:     "kvkk.response",
				Subject:   "KVKK başvurunuz sonuçlandı",
				Body:      k.Response,
				Payload:   map[string]any{"kvkk_request_id": k.ID, "status": k.Status},
				DedupeKey: "kvkk.response:" + k.ID,
			})
		c.JSON(http.StatusOK, gin.H{"request": k, "notification": res})
	})
}

// notifyKVKK: alıcı verilmezse yönetime. Bildirim hatası başvuruyu geri almaz
// ama sessizce de geçmez: yanıtta raporlanır.
func notifyKVKK(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID string,
	to []notify.Recipient, m notify.Message) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	if to == nil {
		var err error
		if to, err = notify.Managers(c.Request.Context(), pool, propertyID); err != nil {
			log.Printf("[community] KVKK bildirimi alıcıları: %v", err)
			return &notify.BroadcastResult{Note: "Alıcı listesi okunamadı; bildirim oluşturulmadı."}
		}
	}
	m.PropertyID = propertyID
	m.Channel = notify.ChannelInApp
	m.Category = notify.CategoryTransactional
	m.CreatedBy = c.GetString("user_id")
	return n.Broadcast(c.Request.Context(), m, to)
}

func failKVKK(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrKVKKNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Başvuru bulunamadı"})
	case errors.Is(err, repository.ErrKVKKNotOpen):
		c.JSON(http.StatusConflict, gin.H{"error": "Başvuru zaten sonuçlandırılmış"})
	default:
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[community] KVKK başvurusu %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
