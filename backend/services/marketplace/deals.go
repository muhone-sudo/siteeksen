package main

// Teklif, mesaj, iş, puan, geçersiz talep bildirimi, yorum denetimi ve gelir raporu uçları (FAZ M7).

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/marketplace/store"
)

// notifyBuyer, talep sahibine uygulama içi bildirimdir (site kaydı).
func (a *App) notifyBuyer(ctx context.Context, p *store.Party, topic, subject, body, dedupe string) {
	if a.notifier == nil {
		log.Printf("[marketplace] alıcı bildirimi GÖNDERİLMEDİ (bildirim altyapısı yok): %s", topic)
		return
	}
	if _, err := a.notifier.Enqueue(ctx, notify.Message{PropertyID: p.PropertyID, RecipientUserID: p.RequesterUserID,
		Recipient: p.RequesterUserID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional, Topic: topic,
		Subject: subject, Body: body, Payload: map[string]any{"request_id": p.RequestID}, DedupeKey: dedupe}); err != nil {
		log.Printf("[marketplace] alıcı bildirimi (%s): %v", topic, err)
	}
}

func messagePage(c *gin.Context) (*time.Time, int) {
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	if v := c.Query("before"); v != "" {
		if t, err := time.Parse(time.RFC3339Nano, v); err == nil {
			return &t, limit
		}
	}
	return nil, limit
}

// --- Tedarikçi ---

func (a *App) saveOffer(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in store.OfferInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	o, p, created, err := a.store.SaveOffer(c.Request.Context(), id, c.Param("id"), in)
	if err != nil {
		fail(c, err, "teklif")
		return
	}
	verb := "güncelledi"
	if created {
		verb = "verdi"
	}
	a.notifyBuyer(c.Request.Context(), p, "market.offer.new", "Talebinize teklif: "+p.Category,
		fmt.Sprintf("%s, %s talebinize %s tutarında teklif %s. Teklifleri karşılaştırıp seçebilirsiniz.", o.BusinessName, p.Category, store.TL(o.AmountKurus), verb),
		"market.offer.new:"+o.ID+":"+o.UpdatedAt.Format(time.RFC3339Nano))
	c.JSON(http.StatusOK, o)
}

func (a *App) withdrawOffer(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	if err := a.store.WithdrawOffer(c.Request.Context(), id, c.Param("id")); err != nil {
		fail(c, err, "teklif")
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Teklif geri çekildi"})
}

func (a *App) supplierDeal(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	d, err := a.store.SupplierDealOf(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "talep")
		return
	}
	c.JSON(http.StatusOK, d)
}

func (a *App) supplierMessages(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	before, limit := messagePage(c)
	list, err := a.store.SupplierMessages(c.Request.Context(), id, c.Param("id"), before, limit)
	if err != nil {
		fail(c, err, "mesajlar")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) supplierSend(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in struct {
		Body string `json:"body"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	m, p, err := a.store.SupplierSend(c.Request.Context(), id, c.GetString("user_id"), c.Param("id"), in.Body)
	if err != nil {
		fail(c, err, "mesaj")
		return
	}
	a.notifyBuyer(c.Request.Context(), p, "market.message", "Yeni mesaj: "+p.Category, "Talebinizle ilgili tedarikçiden yeni mesaj var.",
		"market.message:"+m.ID)
	c.JSON(http.StatusCreated, m)
}

func (a *App) supplierDone(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	j, p, err := a.store.SupplierDone(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "iş")
		return
	}
	days, _ := a.store.SettingValue(c.Request.Context(), "auto_complete_days")
	a.notifyBuyer(c.Request.Context(), p, "market.job.completed", "İş tamamlandı: "+p.Category,
		fmt.Sprintf("%s işin tamamlandığını bildirdi. Onaylayın ya da itiraz edin; %d gün yanıt vermezseniz iş tamamlanmış sayılır.", j.BusinessName, days),
		"market.job.completed:"+j.ID)
	c.JSON(http.StatusOK, j)
}

func (a *App) replyReview(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in struct {
		Reply string `json:"reply"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	if err := a.store.ReplyReview(c.Request.Context(), id, c.Param("id"), in.Reply); err != nil {
		fail(c, err, "yanıt")
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Yanıtınız yayımlandı"})
}

func (a *App) supplierReviews(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, err := a.store.SupplierReviews(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "puanlar")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) openDispute(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in struct {
		ReasonCode string `json:"reason_code"`
		Note       string `json:"note"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	x, err := a.store.OpenDispute(c.Request.Context(), id, c.Param("id"), in.ReasonCode, in.Note)
	if err != nil {
		fail(c, err, "bildirim")
		return
	}
	c.JSON(http.StatusCreated, x)
}

// --- Alıcı ---

func (a *App) buyerOffers(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	list, err := a.store.BuyerOffers(c.Request.Context(), b, c.Param("id"))
	if err != nil {
		fail(c, err, "teklifler")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) selectOffer(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	r, err := a.store.SelectOffer(c.Request.Context(), b, c.Param("id"), c.Param("offerId"))
	if err != nil {
		fail(c, err, "teklif seçimi")
		return
	}
	ctx := c.Request.Context()
	a.notifySupplier(ctx, "", r.Chosen, "market.offer.accepted", "Teklifiniz seçildi: "+r.Category,
		fmt.Sprintf("%s talebinde teklifiniz (%s) seçildi. İşi tamamlayınca Usta & Hizmet'te \"tamamlandı\" olarak bildirin.", r.Category, store.TL(r.Job.AmountKurus)),
		map[string]any{"request_id": r.Job.RequestID, "job_id": r.Job.ID}, "market.offer.accepted:"+r.Job.ID)
	for _, acc := range r.Declined {
		a.notifySupplier(ctx, "", acc, "market.offer.declined", "Başka teklif seçildi: "+r.Category,
			r.Category+" talebinde alıcı başka bir teklifi seçti.", map[string]any{"request_id": r.Job.RequestID},
			"market.offer.declined:"+r.Job.RequestID+":"+acc)
	}
	c.JSON(http.StatusOK, gin.H{"job": r.Job, "declined": len(r.Declined)})
}

func (a *App) closeRequest(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	declined, cat, err := a.store.CloseRequest(c.Request.Context(), b, c.Param("id"))
	if err != nil {
		fail(c, err, "talep kapatma")
		return
	}
	for _, acc := range declined {
		a.notifySupplier(c.Request.Context(), "", acc, "market.offer.declined", "Talep kapatıldı: "+cat,
			cat+" talebini alıcı teklif seçmeden kapattı.", map[string]any{"request_id": c.Param("id")},
			"market.offer.declined:"+c.Param("id")+":"+acc)
	}
	c.JSON(http.StatusOK, gin.H{"message": "Talep kapatıldı. Kabul ücretleri iade edilmez.", "declined": len(declined)})
}

func (a *App) buyerMessages(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	before, limit := messagePage(c)
	list, err := a.store.BuyerMessages(c.Request.Context(), b, c.Param("id"), c.Param("dispatchId"), before, limit)
	if err != nil {
		fail(c, err, "mesajlar")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) buyerSend(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	var in struct {
		Body string `json:"body"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	m, p, err := a.store.BuyerSend(c.Request.Context(), b, c.Param("id"), c.Param("dispatchId"), in.Body)
	if err != nil {
		fail(c, err, "mesaj")
		return
	}
	a.notifySupplier(c.Request.Context(), "", p.AccountID, "market.message", "Yeni mesaj: "+p.Category,
		p.Category+" talebinin sahibinden yeni mesaj var.", map[string]any{"request_id": p.RequestID}, "market.message:"+m.ID)
	c.JSON(http.StatusCreated, m)
}

func (a *App) buyerJob(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	j, err := a.store.BuyerJob(c.Request.Context(), b, c.Param("id"))
	if err != nil {
		fail(c, err, "iş")
		return
	}
	c.JSON(http.StatusOK, j)
}

func (a *App) jobDecision(confirm bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		b, ok := buyer(c)
		if !ok {
			return
		}
		var in struct {
			Note string `json:"note"`
		}
		_ = c.ShouldBindJSON(&in)
		j, err := a.store.BuyerJobDecision(c.Request.Context(), b, c.Param("id"), confirm, in.Note)
		if err != nil {
			fail(c, err, "iş")
			return
		}
		c.JSON(http.StatusOK, j)
	}
}

func (a *App) addReview(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	var in struct {
		Rating  int    `json:"rating"`
		Comment string `json:"comment"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	r, acc, err := a.store.AddReview(c.Request.Context(), b, c.Param("id"), in.Rating, in.Comment)
	if err != nil {
		fail(c, err, "puan")
		return
	}
	a.notifySupplier(c.Request.Context(), "", acc, "market.review", "Yeni puan: "+strconv.Itoa(r.Rating)+"/5",
		"Tamamlanan işiniz için yeni bir değerlendirme var; Usta & Hizmet → Puanlar'dan yanıtlayabilirsiniz.",
		map[string]any{"review_id": r.ID}, "market.review:"+r.ID)
	c.JSON(http.StatusCreated, r)
}

// --- Platform ---

func (a *App) platformDisputes(c *gin.Context) {
	list, err := a.store.Disputes(c.Request.Context(), c.GetString("user_id"), c.Query("status"))
	if err != nil {
		fail(c, err, "bildirimler")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) decideDispute(approve bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Note string `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
			return
		}
		admin := c.GetString("user_id")
		x, err := a.store.DecideDispute(c.Request.Context(), admin, c.Param("id"), approve, in.Note)
		if err != nil {
			fail(c, err, "bildirim kararı")
			return
		}
		body := fmt.Sprintf("%s talebi için geçersizlik bildiriminiz reddedildi: %s", x.Category, in.Note)
		if approve {
			refund := "kabul ücretiniz (" + store.TL(x.FeeKurus) + ") bakiyenize iade edildi"
			if x.UsedIncluded {
				refund = "paketinizdeki talep hakkı geri verildi"
			}
			body = fmt.Sprintf("%s talebi için geçersizlik bildiriminiz onaylandı; %s. Not: %s", x.Category, refund, in.Note)
		}
		res := a.notifySupplier(c.Request.Context(), admin, x.AccountID, "market.dispute.resolved", "Geçersiz talep bildiriminiz", body,
			map[string]any{"dispute_id": x.ID, "request_id": x.RequestID}, "market.dispute.resolved:"+x.ID)
		c.JSON(http.StatusOK, gin.H{"dispute": x, "notification": res})
	}
}

func (a *App) platformReviews(c *gin.Context) {
	list, err := a.store.PlatformReviews(c.Request.Context(), c.GetString("user_id"), c.Query("hidden"))
	if err != nil {
		fail(c, err, "yorumlar")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) hideReview(c *gin.Context) {
	var in struct {
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	c.Set("audit_event", "market.review.hidden")
	if err := a.store.HideReview(c.Request.Context(), c.GetString("user_id"), c.Param("id"), in.Reason); err != nil {
		fail(c, err, "yorum gizleme")
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Yorum gizlendi (silinmedi)"})
}

func (a *App) revenue(c *gin.Context) {
	r, err := a.store.RevenueReport(c.Request.Context(), c.GetString("user_id"), c.Query("from"), c.Query("to"))
	if err != nil {
		fail(c, err, "gelir raporu")
		return
	}
	c.JSON(http.StatusOK, r)
}

// autoComplete, zamanlayıcının otomatik tamamlama turudur; iki tarafa bildirilir.
func (a *App) autoComplete(ctx context.Context) {
	list, err := a.store.AutoCompleteJobs(ctx)
	if err != nil {
		log.Printf("[marketplace] otomatik tamamlama: %v", err)
		return
	}
	for i := range list {
		x := list[i]
		a.notifyBuyer(ctx, &x.Party, "market.job.completed", "İş tamamlandı sayıldı: "+x.Party.Category,
			"Süresinde yanıt verilmediği için iş tamamlanmış sayıldı. Puan ve yorumunuzu yazabilirsiniz.", "market.job.auto:"+x.JobID)
		a.notifySupplier(ctx, "", x.AccountID, "market.job.completed", "İş tamamlandı: "+x.Party.Category,
			"Alıcı süresinde yanıt vermediği için iş tamamlanmış sayıldı.", map[string]any{"job_id": x.JobID}, "market.job.auto:"+x.JobID)
	}
}
