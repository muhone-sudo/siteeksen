package handlers

// Etkinleştirme kodunun SMS ile iletilmesi (TEST_RAPORU 2.4).
//
// Kod bildirim kuyruğuna (notifications) YAZILMAZ: tek kullanımlık giriş sırrıdır,
// veritabanında yalnızca özeti tutulur. SMS sağlayıcısı (Netgsm) yapılandırılmışsa
// doğrudan gönderilir; yanıt sonucu dürüstçe söyler. Kod yöneticiye yine bir kez
// gösterilir: SMS ulaşmazsa yönetici iletebilsin (önceki akış korunur).

import (
	"context"
	"log"
	"time"

	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/identity/models"
)

// SMSDelivery, kodun SMS ile iletim sonucudur.
type SMSDelivery struct {
	Status string `json:"status"` // SENT | FAILED | NOT_CONFIGURED
	Note   string `json:"note"`
}

var activationSMS notify.Sender

// SetActivationSMS, kimlik servisinin açılışında SMS sağlayıcısını verir (nil olabilir).
func SetActivationSMS(s notify.Sender) { activationSMS = s }

func sendActivationSMS(ctx context.Context, phone string, act *models.Activation) *SMSDelivery {
	if act == nil {
		return nil
	}
	if activationSMS == nil {
		return &SMSDelivery{Status: "NOT_CONFIGURED", Note: "SMS sağlayıcısı yapılandırılmamış; kodu sakine siz iletin."}
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	body := "SiteEksen etkinleştirme kodunuz: " + act.Code + ". Kod " + act.ExpiresAt.In(time.Local).Format("02.01.2006") +
		" tarihine kadar geçerlidir. Kodu kimseyle paylaşmayın."
	_, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
		Topic: "identity.activation", Recipient: phone, Body: body})
	if err != nil {
		log.Printf("[identity] etkinleştirme SMS'i gönderilemedi: %v", err)
		return &SMSDelivery{Status: "FAILED", Note: "SMS gönderilemedi (" + err.Error() + "); kodu sakine siz iletin."}
	}
	return &SMSDelivery{Status: "SENT", Note: "Kod sakinin telefonuna SMS ile gönderildi."}
}

var activationEmail notify.Sender

// SetActivationEmail, e-posta sağlayıcısını verir (SMTP; nil olabilir). SMS ulaşmadığında
// sakinin e-postası kayıtlıysa kod oraya da gider (Apsiyon BUG-05: tek kanala bağımlılık).
func SetActivationEmail(s notify.Sender) { activationEmail = s }

func sendActivationEmail(ctx context.Context, email string, act *models.Activation) *SMSDelivery {
	if act == nil || email == "" {
		return nil
	}
	if activationEmail == nil {
		return &SMSDelivery{Status: "NOT_CONFIGURED", Note: "E-posta sağlayıcısı yapılandırılmamış."}
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	_, err := activationEmail.Send(ctx, notify.Message{Channel: notify.ChannelEmail, Category: notify.CategoryTransactional,
		Topic: "identity.activation", Recipient: email, Subject: "SiteEksen etkinleştirme kodunuz",
		Body: "Merhaba,\n\nSiteEksen hesabınız için etkinleştirme kodunuz: " + act.Code + "\nKod " +
			act.ExpiresAt.In(time.Local).Format("02.01.2006") + " tarihine kadar geçerlidir. Uygulamada telefon numaranız ve bu kodla " +
			"şifrenizi belirleyin. Kodu kimseyle paylaşmayın; bu işlemi siz istemediyseniz site yönetimine bildirin."})
	if err != nil {
		log.Printf("[identity] etkinleştirme e-postası gönderilemedi: %v", err)
		return &SMSDelivery{Status: "FAILED", Note: "E-posta gönderilemedi."}
	}
	return &SMSDelivery{Status: "SENT", Note: "Kod sakinin e-posta adresine de gönderildi."}
}

// Davet iletimi (altıncı tur D3). Hesabı davetle açılan kişiye kod, hesabı olan kişiye davet bildirimi gider.

func sendInvitationActivationSMS(ctx context.Context, phone, what string, act *models.Activation) *SMSDelivery {
	if act == nil {
		return nil
	}
	if activationSMS == nil {
		return &SMSDelivery{Status: "NOT_CONFIGURED", Note: "SMS sağlayıcısı yapılandırılmamış."}
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	body := "SiteEksen: " + what + ". Etkinleştirme kodunuz: " + act.Code + " (" +
		act.ExpiresAt.In(time.Local).Format("02.01.2006") + " tarihine kadar). Uygulamada 'Hesabımı etkinleştir' ile kodu girince daireye bağlanırsınız."
	if _, err := activationSMS.Send(ctx, notify.Message{Channel: notify.ChannelSMS, Category: notify.CategoryTransactional,
		Topic: "identity.invitation", Recipient: phone, Body: body}); err != nil {
		log.Printf("[identity] davet SMS'i gönderilemedi: %v", err)
		return &SMSDelivery{Status: "FAILED", Note: "SMS gönderilemedi."}
	}
	return &SMSDelivery{Status: "SENT", Note: "Kod davet edilen kişinin telefonuna SMS ile gönderildi."}
}

func sendInvitationActivationEmail(ctx context.Context, email, what string, act *models.Activation) *SMSDelivery {
	if act == nil || email == "" {
		return nil
	}
	if activationEmail == nil {
		return &SMSDelivery{Status: "NOT_CONFIGURED", Note: "E-posta sağlayıcısı yapılandırılmamış."}
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	if _, err := activationEmail.Send(ctx, notify.Message{Channel: notify.ChannelEmail, Category: notify.CategoryTransactional,
		Topic: "identity.invitation", Recipient: email, Subject: "SiteEksen daire daveti",
		Body: "Merhaba,\n\n" + what + ".\nEtkinleştirme kodunuz: " + act.Code + "\nKod " + act.ExpiresAt.In(time.Local).Format("02.01.2006") +
			" tarihine kadar geçerlidir. Uygulamada telefon numaranız ve bu kodla şifrenizi belirlediğinizde daireye bağlanırsınız. " +
			"Kodu kimseyle paylaşmayın; bu daveti beklemiyorsanız site yönetimine bildirin."}); err != nil {
		log.Printf("[identity] davet e-postası gönderilemedi: %v", err)
		return &SMSDelivery{Status: "FAILED", Note: "E-posta gönderilemedi."}
	}
	return &SMSDelivery{Status: "SENT", Note: "Kod davet edilen kişinin e-posta adresine gönderildi."}
}

// sendInvitationNotice, hesabı olan kişiye davet bildirimi (telefon ya da e-posta; biri boş olur).
func sendInvitationNotice(ctx context.Context, phone, email, what string) *SMSDelivery {
	sender, recipient, channel := activationSMS, phone, notify.ChannelSMS
	if phone == "" {
		sender, recipient, channel = activationEmail, email, notify.ChannelEmail
	}
	if recipient == "" {
		return nil
	}
	if sender == nil {
		return &SMSDelivery{Status: "NOT_CONFIGURED", Note: "Sağlayıcı yapılandırılmamış; davet uygulamada görünür."}
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	defer cancel()
	if _, err := sender.Send(ctx, notify.Message{Channel: channel, Category: notify.CategoryTransactional,
		Topic: "identity.invitation", Recipient: recipient, Subject: "SiteEksen daire daveti",
		Body: "SiteEksen: " + what + ". Uygulamadaki davetlerinizden kabul ya da reddedebilirsiniz (14 gün)."}); err != nil {
		log.Printf("[identity] davet bildirimi gönderilemedi: %v", err)
		return &SMSDelivery{Status: "FAILED", Note: "Gönderilemedi; davet uygulamada görünür."}
	}
	return &SMSDelivery{Status: "SENT", Note: "Davet bildirimi gönderildi."}
}
