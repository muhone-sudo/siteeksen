package handlers

// POST /auth/password-reset/request {phone} — sakinin kendi "şifremi unuttum" isteği
// (beşinci tur B3). Oturum gerektirmez.
//
// Yanıt, numaranın kayıtlı olup olmamasından BAĞIMSIZDIR: hem metin hem süre aynıdır.
// Kod gönderimi bu yüzden isteğin dışında (arka planda) yapılır; aksi hâlde SMS'in
// gönderildiği istek daha uzun sürer ve numaranın kayıtlı olduğu yanıt süresinden anlaşılırdı.

import (
	"context"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/identity/service"
)

// RequestPasswordReset: kod üretir ve kayıtlı telefon/e-postaya gönderir.
func RequestPasswordReset(auth *service.AuthService) gin.HandlerFunc {
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
		// Kurulum düzeyinde bir bilgidir (hesaba özgü değil): gönderim kanalı yoksa kod
		// üretmek anlamsızdır ve bunu söylemek kimseyi ifşa etmez.
		if activationSMS == nil && activationEmail == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"code": "NO_DELIVERY_CHANNEL",
				"error": "Bu kurulumda SMS ve e-posta gönderimi yapılandırılmamış; şifre sıfırlama kodunu site yönetiminden isteyin."})
			return
		}
		issue, err := auth.IssueSelfReset(c.Request.Context(), phone, time.Now())
		if err != nil {
			log.Printf("[identity] şifre sıfırlama isteği (%s): %v", maskPhone(phone), err)
		} else if issue != nil {
			go sendSelfResetCode(issue)
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Numara kayıtlı ve etkin bir hesaba aitse doğrulama kodu SMS ile (e-posta kayıtlıysa e-postaya da) gönderildi. " +
				"Kod 15 dakika geçerlidir. Kod gelmezse 60 saniye sonra yeniden isteyebilir ya da site yönetiminden kod alabilirsiniz.",
			"retry_after_sec": int(service.SelfResetCooldown.Seconds()),
			"expires_in_sec":  int(service.SelfResetTTL.Seconds()),
		})
	}
}

// maskPhone, günlüğe yazılacak numaranın yalnızca son iki hanesini bırakır (KVKK m.12).
func maskPhone(p string) string {
	if len(p) <= 2 {
		return "**"
	}
	return strings.Repeat("*", len(p)-2) + p[len(p)-2:]
}

// sendSelfResetCode, kodu kayıtlı telefona ve (varsa) e-postaya gönderir; sonuç günlüğe yazılır.
func sendSelfResetCode(issue *service.SelfResetIssue) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	what := "şifre sıfırlama"
	if issue.Purpose == "ACTIVATION" {
		what = "hesap etkinleştirme"
	}
	until := issue.ExpiresAt.In(time.Local).Format("15:04")
	if activationSMS != nil {
		_, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
			Topic: "identity.self_reset", Recipient: issue.Phone,
			Body: "SiteEksen " + what + " kodunuz: " + issue.Code + ". Kod saat " + until +
				"'e kadar geçerlidir. Kodu kimseyle paylaşmayın; bu isteği siz yapmadıysanız dikkate almayın."})
		if err != nil {
			log.Printf("[identity] sıfırlama SMS'i gönderilemedi (%s): %v", maskPhone(issue.Phone), err)
		}
	}
	if activationEmail != nil && issue.Email != "" {
		_, err := activationEmail.Send(ctx, notify.Message{Channel: notify.ChannelEmail, Category: notify.CategoryTransactional,
			Topic: "identity.self_reset", Recipient: issue.Email, Subject: "SiteEksen " + what + " kodunuz",
			Body: "Merhaba,\n\nSiteEksen " + what + " kodunuz: " + issue.Code + "\nKod saat " + until +
				"'e kadar geçerlidir. Uygulamada telefon numaranız ve bu kodla yeni şifrenizi belirleyin.\n" +
				"Bu isteği siz yapmadıysanız bu iletiyi dikkate almayın; şifreniz değişmez."})
		if err != nil {
			log.Printf("[identity] sıfırlama e-postası gönderilemedi: %v", err)
		}
	}
}
