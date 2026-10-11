package handlers

// Sakinin kendi telefon/e-posta değişikliği (migration 062, beşinci tur B4).
//   POST /me/phone/request {password, phone} → yeni numaraya SMS kodu
//   POST /me/phone/confirm {code}            → numara değişir, bütün oturumlar kapanır
//   POST /me/email {password, email}         → yeni adrese doğrulama kodu (065)
//   POST /me/email/confirm {code}            → e-posta değişir, eski adrese bilgi gider

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

func selfAccountError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, service.ErrWrongPassword):
		// 401 DEĞİL: istemciler 401'de oturumu kapatır; şifre değiştirmedeki gibi 400.
		c.JSON(http.StatusBadRequest, gin.H{"error": "Mevcut şifreniz hatalı"})
	case errors.Is(err, service.ErrSamePhone), errors.Is(err, service.ErrInvalidEmail), errors.Is(err, service.ErrSameEmail):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrPhoneTaken):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu numara başka bir hesapta kayıtlı"})
	case errors.Is(err, repository.ErrEmailTaken):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	case errors.Is(err, service.ErrTooSoon):
		c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrInvalidCode):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Kod geçersiz ya da süresi dolmuş; yeni kod isteyin"})
	case errors.Is(err, repository.ErrCodeLocked):
		c.JSON(http.StatusTooManyRequests, gin.H{"error": "Kod çok sayıda hatalı deneme nedeniyle kilitlendi; yeni kod isteyin"})
	default:
		log.Printf("[identity] %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// RequestPhoneChange: POST /me/phone/request.
func RequestPhoneChange(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Password string `json:"password"`
			Phone    string `json:"phone"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.Password == "" || strings.TrimSpace(in.Phone) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "password ve phone zorunludur"})
			return
		}
		phone := normalizePhone(in.Phone)
		if phone == "" {
			errInvalidPhone(c)
			return
		}
		// Yeni numaranın kişiye ait olduğu yalnızca o numaraya giden kodla kanıtlanabilir.
		if activationSMS == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"code": "NO_SMS_CHANNEL",
				"error": "Bu kurulumda SMS gönderimi yapılandırılmamış; numaranızı site yönetimi değiştirebilir."})
			return
		}
		code, expires, err := auth.RequestPhoneChange(c.Request.Context(), c.GetString("user_id"), in.Password, phone, time.Now())
		if err != nil {
			selfAccountError(c, err, "telefon değişikliği isteği")
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
		defer cancel()
		if _, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
			Topic: "identity.phone_change", Recipient: phone,
			Body: "SiteEksen numara doğrulama kodunuz: " + code + ". Kod saat " + expires.In(time.Local).Format("15:04") +
				"'e kadar geçerlidir. Bu isteği siz yapmadıysanız dikkate almayın."}); err != nil {
			log.Printf("[identity] numara doğrulama SMS'i gönderilemedi (%s): %v", maskPhone(phone), err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Doğrulama kodu yeni numaraya gönderilemedi; biraz sonra yeniden deneyin."})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message":         "Doğrulama kodu yeni numaranıza SMS ile gönderildi. Kodu girdiğinizde numaranız değişir ve bütün cihazlardaki oturumlarınız kapanır.",
			"expires_in_sec":  int(service.PhoneChangeTTL.Seconds()),
			"retry_after_sec": int(service.SelfResetCooldown.Seconds()),
		})
	}
}

// ConfirmPhoneChange: POST /me/phone/confirm.
func ConfirmPhoneChange(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Code string `json:"code"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Code) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "code zorunludur"})
			return
		}
		oldPhone, newPhone, err := auth.ConfirmPhoneChange(c.Request.Context(), c.GetString("user_id"), in.Code)
		if err != nil && oldPhone == "" {
			selfAccountError(c, err, "telefon değişikliği onayı")
			return
		}
		revoked := err == nil
		if err != nil {
			log.Printf("[identity] numara değişti ama oturumlar kapatılamadı: %v", err)
		}
		// Eski numaraya uyarı (hesap ele geçirmeye karşı): mesaj kişinin kendi değişikliğini anlatır.
		notice := "NOT_CONFIGURED"
		if activationSMS != nil {
			ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
			defer cancel()
			if _, serr := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
				Topic: "identity.phone_changed", Recipient: oldPhone,
				Body: "SiteEksen hesabınızın telefon numarası hesap sahibi tarafından değiştirildi. Bu işlemi siz yapmadıysanız site yönetimiyle hemen görüşün."}); serr != nil {
				log.Printf("[identity] eski numaraya bildirim gönderilemedi: %v", serr)
				notice = "FAILED"
			} else {
				notice = "SENT"
			}
		}
		c.JSON(http.StatusOK, gin.H{"message": "Telefon numaranız değişti. Yeni numaranızla yeniden giriş yapın.",
			"phone": newPhone, "sessions_revoked": revoked, "old_phone_notice": notice})
	}
}

// RequestEmailChange: POST /me/email {password, email} — kod YENİ adrese gider (065).
func RequestEmailChange(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Password string `json:"password"`
			Email    string `json:"email"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.Password == "" || strings.TrimSpace(in.Email) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "password ve email zorunludur"})
			return
		}
		// Yeni adresin kişiye ait olduğu yalnızca o adrese giden kodla kanıtlanabilir.
		if activationEmail == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"code": "NO_EMAIL_CHANNEL",
				"error": "Bu kurulumda e-posta gönderimi yapılandırılmamış; e-posta adresi şu an değiştirilemez."})
			return
		}
		email := strings.TrimSpace(in.Email)
		code, expires, err := auth.RequestEmailChange(c.Request.Context(), c.GetString("user_id"), in.Password, email, time.Now())
		if err != nil {
			selfAccountError(c, err, "e-posta değişikliği isteği")
			return
		}
		ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
		defer cancel()
		if _, err := activationEmail.Send(ctx, notify.Message{Channel: notify.ChannelEmail, Category: notify.CategoryTransactional,
			Topic: "identity.email_change", Recipient: email, Subject: "SiteEksen e-posta doğrulama kodunuz",
			Body: "Merhaba,\n\nSiteEksen hesabınıza bu adresi eklemek için doğrulama kodunuz: " + code + "\nKod saat " +
				expires.In(time.Local).Format("15:04") + "'e kadar geçerlidir. Bu isteği siz yapmadıysanız bu iletiyi dikkate almayın."}); err != nil {
			log.Printf("[identity] e-posta doğrulama kodu gönderilemedi: %v", err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Doğrulama kodu yeni adrese gönderilemedi; adresi kontrol edip yeniden deneyin."})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message":         "Doğrulama kodu yeni e-posta adresinize gönderildi. Kodu girdiğinizde adresiniz değişir.",
			"expires_in_sec":  int(service.PhoneChangeTTL.Seconds()),
			"retry_after_sec": int(service.SelfResetCooldown.Seconds()),
		})
	}
}

// ConfirmEmailChange: POST /me/email/confirm {code} — adres değişir, eski adrese bilgi gider.
func ConfirmEmailChange(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Code string `json:"code"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Code) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "code zorunludur"})
			return
		}
		old, email, err := auth.ConfirmEmailChange(c.Request.Context(), c.GetString("user_id"), in.Code)
		if err != nil {
			selfAccountError(c, err, "e-posta değişikliği onayı")
			return
		}
		notice := "NONE"
		if old != "" && !strings.EqualFold(old, email) {
			notice = "NOT_CONFIGURED"
			if activationEmail != nil {
				ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
				defer cancel()
				if _, serr := activationEmail.Send(ctx, notify.Message{Channel: notify.ChannelEmail, Category: notify.CategoryTransactional,
					Topic: "identity.email_changed", Recipient: old, Subject: "SiteEksen e-posta adresiniz değişti",
					Body: "Merhaba,\n\nSiteEksen hesabınızın e-posta adresi hesap sahibi tarafından değiştirildi. " +
						"Bu işlemi siz yapmadıysanız şifrenizi değiştirin ve site yönetimiyle görüşün."}); serr != nil {
					log.Printf("[identity] eski e-postaya bildirim gönderilemedi: %v", serr)
					notice = "FAILED"
				} else {
					notice = "SENT"
				}
			}
		}
		c.JSON(http.StatusOK, gin.H{"message": "E-posta adresiniz doğrulandı ve güncellendi.", "email": email, "old_email_notice": notice})
	}
}
