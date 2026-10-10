package handlers

// Yönetim destekli hesap işlemleri (Apsiyon BUG-05, BUG-06):
//   - telefon değişikliği: eski oturumlar kapanır, yeni kod üretilir ve yeni numaraya
//     (SMS yapılandırılmışsa) gönderilir; eski numaraya değişiklik bildirimi gider
//   - giriş kilidinin kaldırılması: yanlış şifre kilidinin süresini beklemeden açılması

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/revocation"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

// ChangeResidentPhone: POST /residents/:id/phone {phone} (yönetim).
func ChangeResidentPhone(users *repository.UserRepository, auth *service.AuthService, rev *revocation.Checker) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Phone string `json:"phone"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Phone) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "phone zorunludur"})
			return
		}
		phone := normalizePhone(in.Phone)
		if len(phone) < 8 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Telefon numarası geçersiz"})
			return
		}
		ctx := c.Request.Context()
		userID, oldPhone, pwSet, err := users.ChangePhone(ctx, c.GetString("property_id"), c.Param("id"), phone)
		switch {
		case errors.Is(err, repository.ErrResidentNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "Sakin bulunamadı"})
			return
		case errors.Is(err, repository.ErrPhoneTaken):
			c.JSON(http.StatusConflict, gin.H{"error": "Bu numara başka bir hesapta kayıtlı"})
			return
		case errors.Is(err, repository.ErrPhoneOtherSites):
			c.JSON(http.StatusConflict, gin.H{"error": "Kişi başka sitelerde de kayıtlı; numarasını tek bir sitenin yönetimi değiştiremez. Kişi kendi hesabından değiştirmeli ya da platform desteğine başvurmalı."})
			return
		case err != nil:
			log.Printf("[identity] telefon değişikliği: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Telefon değiştirilemedi"})
			return
		}
		// Eski numarayla açılmış oturumlar kapanır (çalınmış/kaybolmuş telefon senaryosu).
		revoked := rev.RevokeAll(ctx, userID, "phone_changed_by_manager") == nil
		code, expires, purpose, err := auth.IssueActivation(ctx, userID, c.GetString("user_id"), pwSet)
		if err != nil {
			log.Printf("[identity] telefon sonrası kod: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Numara değişti ancak yeni kod üretilemedi; sakin için yeni kod üretin"})
			return
		}
		act := &models.Activation{Code: code, Purpose: purpose, ExpiresAt: expires,
			Note: "Kodu bu ekranda bir kez görüyorsunuz. Sakin yeni numarası ve bu kodla şifresini belirler."}
		act.SMS = sendActivationSMS(ctx, phone, act)
		oldNotice := notifyOldPhone(ctx, oldPhone)
		c.JSON(http.StatusOK, gin.H{
			"message": "Telefon numarası değişti", "phone": phone, "sessions_revoked": revoked,
			"activation": act, "old_phone_notice": oldNotice,
		})
	}
}

// notifyOldPhone, eski numaraya değişiklik bilgisi gönderir (hesap ele geçirmeye karşı uyarı).
func notifyOldPhone(ctx context.Context, oldPhone string) string {
	if activationSMS == nil {
		return "NOT_CONFIGURED"
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	_, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
		Topic: "identity.phone_changed", Recipient: oldPhone,
		Body: "SiteEksen hesabınızın telefon numarası site yönetimi tarafından değiştirildi. Bu işlemi siz istemediyseniz yönetimle hemen görüşün."})
	if err != nil {
		log.Printf("[identity] eski numaraya bildirim gönderilemedi: %v", err)
		return "FAILED"
	}
	return "SENT"
}

// UnlockResidentLogin: POST /residents/:id/unlock (yönetim) — giriş kilidini kaldırır.
func UnlockResidentLogin(users *repository.UserRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		was, err := users.UnlockLogin(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if errors.Is(err, repository.ErrResidentNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Sakin bulunamadı"})
			return
		}
		if err != nil {
			log.Printf("[identity] kilit kaldırma: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Kilit kaldırılamadı"})
			return
		}
		msg := "Hesapta etkin giriş kilidi yoktu; hatalı deneme sayacı sıfırlandı"
		if was {
			msg = "Giriş kilidi kaldırıldı; sakin hemen giriş yapabilir"
		}
		c.JSON(http.StatusOK, gin.H{"message": msg, "was_locked": was})
	}
}
