package main

// Tedarikçi bildirimleri (077, pkg/notify sitesiz kayıt): uygulama içi her zaman, e-posta adresi varsa e-posta;
// SMS yalnız çağıran istediğinde (ücretli paketin SMS hakkı — FAZ M6).

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
)

// notifyResult, bildirimin kanal kanal sonucudur (yanıtta dürüstçe söylenir).
type notifyResult struct {
	InApp string `json:"in_app"`
	Email string `json:"email,omitempty"`
	SMS   string `json:"sms,omitempty"`
}

// notifySupplier, tedarikçi hesabının sahibine bildirim kuyruğa alır. adminID boşsa tedarikçi kapsamında çalışır.
func (a *App) notifySupplier(c *gin.Context, adminID, accountID, topic, subject, body string, payload map[string]any, dedupe string, extra ...string) *notifyResult {
	res := &notifyResult{}
	if a.notifier == nil {
		res.InApp = "bildirim altyapısı yapılandırılmamış; GÖNDERİLMEDİ"
		return res
	}
	ctx := c.Request.Context()
	contact, err := a.store.AccountContact(ctx, adminID, accountID)
	if err != nil {
		log.Printf("[marketplace] bildirim alıcısı okunamadı (%s): %v", topic, err)
		res.InApp = "alıcı okunamadı; GÖNDERİLMEDİ"
		return res
	}
	base := notify.Message{SupplierAccountID: accountID, RecipientUserID: contact.UserID, Category: notify.CategoryTransactional,
		Topic: topic, Subject: subject, Body: body, Payload: payload, CreatedBy: adminID}
	send := func(ch, addr string) string {
		m := base
		m.Channel, m.Recipient = ch, addr
		if dedupe != "" {
			m.DedupeKey = dedupe + ":" + ch
		}
		r, err := a.notifier.Enqueue(ctx, m)
		if err != nil {
			log.Printf("[marketplace] bildirim (%s/%s): %v", topic, ch, err)
			return "HATA: " + err.Error()
		}
		if r.Reason != "" {
			return r.Status + " — " + r.Reason
		}
		return r.Status
	}
	res.InApp = send(notify.ChannelInApp, contact.UserID)
	if contact.Email != "" {
		res.Email = send(notify.ChannelEmail, contact.Email)
	}
	for _, e := range extra {
		if e == notify.ChannelSMS {
			res.SMS = send(notify.ChannelSMS, contact.Phone)
		}
	}
	return res
}
