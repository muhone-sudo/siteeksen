package handlers

// Tedarikçi kaydı (076, FAZ M1, docs/usta-hizmet/plan.md). Oturum gerektirmez.
//
//	POST /auth/supplier-signup/request  {phone}                 → her numaraya aynı yanıt; kod SMS ile gider
//	POST /auth/supplier-signup/verify   {phone, code}           → hesap durumu + tek kullanımlık kayıt jetonu
//	POST /auth/supplier-signup/complete {phone, signup_token, …} → hesap açılır / mevcut hesaba SUPPLIER eklenir, oturum açılır
//
// İstek gövdesindeki `roles` gibi alanlar BİLEREK okunmaz: verilen tek rol SUPPLIER'dır.

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

// RequestSupplierSignup: kod üretir ve numaraya SMS ile gönderir.
func RequestSupplierSignup(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Phone string `json:"phone"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Phone) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "phone zorunludur"})
			return
		}
		phone := normalizePhone(in.Phone)
		if phone == "" {
			errInvalidPhone(c)
			return
		}
		if activationSMS == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"code": "NO_DELIVERY_CHANNEL",
				"error": "Bu kurulumda SMS gönderimi yapılandırılmamış; tedarikçi kaydı şu an yapılamıyor."})
			return
		}
		c.Set("audit_event", "auth.supplier_signup_request")
		c.Set("audit_details", gin.H{"phone": maskPhone(phone)})
		code, expires, err := auth.RequestSupplierSignup(c.Request.Context(), phone, c.ClientIP(), time.Now())
		switch {
		case errors.Is(err, service.ErrSignupThrottled):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": err.Error(),
				"retry_after_sec": int(service.SupplierSignupCooldown.Seconds())})
			return
		case err != nil:
			log.Printf("[identity] tedarikçi kayıt kodu üretilemedi (%s): %v", maskPhone(phone), err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Kod üretilemedi; biraz sonra yeniden deneyin"})
			return
		}
		go sendSupplierSignupCode(phone, code, expires)
		c.JSON(http.StatusOK, gin.H{
			"message":         "Doğrulama kodu SMS ile gönderildi. Kod 15 dakika geçerlidir; gelmezse 60 saniye sonra yeniden isteyebilirsiniz.",
			"retry_after_sec": int(service.SupplierSignupCooldown.Seconds()),
			"expires_in_sec":  int(service.SupplierSignupTTL.Seconds()),
		})
	}
}

func sendSupplierSignupCode(phone, code string, expires time.Time) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	_, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
		Topic: "identity.supplier_signup", Recipient: phone,
		Body: "SiteEksen Usta & Hizmet tedarikçi kayıt kodunuz: " + code + ". Kod saat " +
			expires.In(time.Local).Format("15:04") + "'e kadar geçerlidir. Kodu kimseyle paylaşmayın."})
	if err != nil {
		log.Printf("[identity] tedarikçi kayıt SMS'i gönderilemedi (%s): %v", maskPhone(phone), err)
	}
}

// VerifySupplierSignup: kodu doğrular; hesap durumunu ve kayıt jetonunu döner.
func VerifySupplierSignup(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Phone string `json:"phone"`
			Code  string `json:"code"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Phone) == "" || strings.TrimSpace(in.Code) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Telefon ve kod zorunludur"})
			return
		}
		phone := normalizePhone(in.Phone)
		if phone == "" {
			errInvalidPhone(c)
			return
		}
		state, token, err := auth.VerifySupplierSignup(c.Request.Context(), phone, in.Code)
		c.Set("audit_event", "auth.supplier_signup_verify")
		c.Set("audit_details", gin.H{"phone": maskPhone(phone), "ok": err == nil, "state": state})
		switch {
		case errors.Is(err, repository.ErrInvalidCode):
			c.JSON(http.StatusBadRequest, gin.H{"error": "Kod hatalı, kullanılmış ya da süresi dolmuş"})
		case errors.Is(err, repository.ErrCodeLocked):
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Kod çok sayıda hatalı deneme nedeniyle kilitlendi; yeni kod isteyin"})
		case err != nil:
			log.Printf("[identity] tedarikçi kayıt kodu doğrulanamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Kod doğrulanamadı"})
		case state == repository.PhoneStateBlocked:
			c.JSON(http.StatusForbidden, gin.H{"state": state, "error": service.ErrSignupBlocked.Error()})
		default:
			c.JSON(http.StatusOK, gin.H{"state": state, "signup_token": token,
				"expires_in_sec": int(service.SupplierSignupCompletionTTL.Seconds()),
				"next":           signupNext(state)})
		}
	}
}

func signupNext(state string) string {
	switch state {
	case repository.PhoneStateExisting:
		return "Bu numarayla bir SiteEksen hesabınız var. Mevcut şifrenizi girin; hesabınıza tedarikçi paneli eklenecek."
	case repository.PhoneStateInactive:
		return "Bu numarayla açılmış ama etkinleştirilmemiş bir hesabınız var. Yeni şifrenizi belirleyin."
	default:
		return "Adınızı, soyadınızı ve şifrenizi girerek hesabınızı açın."
	}
}

// CompleteSupplierSignup: hesabı açar ya da mevcut hesaba SUPPLIER ekler; jeton çifti döner.
func CompleteSupplierSignup(auth *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Phone         string `json:"phone"`
			SignupToken   string `json:"signup_token"`
			Password      string `json:"password"`
			FirstName     string `json:"first_name"`
			LastName      string `json:"last_name"`
			Email         string `json:"email"`
			TermsAccepted bool   `json:"terms_accepted"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.SignupToken == "" || in.Password == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Telefon, kayıt jetonu ve şifre zorunludur"})
			return
		}
		phone := normalizePhone(in.Phone)
		if phone == "" {
			errInvalidPhone(c)
			return
		}
		tokens, user, state, err := auth.CompleteSupplierSignup(c.Request.Context(), service.SupplierSignupInput{
			Phone: phone, Token: in.SignupToken, Password: in.Password, FirstName: in.FirstName,
			LastName: in.LastName, Email: in.Email, TermsAccepted: in.TermsAccepted})
		c.Set("audit_event", "auth.supplier_signup_complete")
		c.Set("audit_details", gin.H{"phone": maskPhone(phone), "ok": err == nil, "state": state})
		if user != nil {
			c.Set("audit_user_id", user.ID)
		}
		switch {
		case errors.Is(err, service.ErrSignupFields), errors.Is(err, service.ErrWeakPassword), errors.Is(err, service.ErrInvalidEmail):
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		case errors.Is(err, repository.ErrSignupTokenInvalid):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		case errors.Is(err, service.ErrInvalidCredentials):
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Mevcut şifre hatalı", "note": loginLockNote})
		case errors.Is(err, service.ErrSignupBlocked):
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		case err != nil:
			log.Printf("[identity] tedarikçi kaydı tamamlanamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Kayıt tamamlanamadı"})
		default:
			c.JSON(http.StatusOK, gin.H{"access_token": tokens.AccessToken, "refresh_token": tokens.RefreshToken,
				"expires_in": tokens.ExpiresIn, "user": user, "state": state})
		}
	}
}
