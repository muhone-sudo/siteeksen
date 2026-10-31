package main

// Talepler (FAZ M6): alıcı uçları (site oturumu: sakin kendi dairesi için, yönetici site adına) ve tedarikçi uçları
// (maskeli önizleme, kabul). Eşleşme ve ücret kuralları store/requests.go ve rules paketindedir.

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/marketplace/store"
)

// buyer, oturumdaki alıcıdır; aktif site yoksa (ör. yalnız tedarikçi hesabı) talep açılamaz.
func buyer(c *gin.Context) (store.Buyer, bool) {
	b := store.Buyer{UserID: c.GetString("user_id"), PropertyID: c.GetString("property_id"),
		Management: hasRole(c, middleware.RoleManager),
		Oversight:  hasRole(c, middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor)}
	if b.PropertyID == "" {
		c.JSON(http.StatusForbidden, gin.H{"error": "Talep için bir sitede sakin ya da yönetici olmalısınız", "code": "NO_PROPERTY"})
		return b, false
	}
	return b, true
}

func (a *App) matchCount(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	bt := c.DefaultQuery("buyer_type", "RESIDENT")
	n, err := a.store.MatchCount(c.Request.Context(), b, c.Query("category_id"), bt, c.Query("target_business_id"))
	if err != nil {
		fail(c, err, "uygun işletme sayısı")
		return
	}
	c.JSON(http.StatusOK, gin.H{"count": n})
}

func (a *App) createRequest(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	var in store.RequestInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	id, n, err := a.store.CreateRequest(c.Request.Context(), b, in)
	if err != nil {
		fail(c, err, "talep")
		return
	}
	// Ücretli paketler (öncelik) ve doğrudan talepte hedef işletme hemen bildirilir; diğerleri zamanlayıcıyla.
	a.notifyDueDispatches(c.Request.Context(), id)
	r, err := a.store.BuyerRequestByID(c.Request.Context(), b, id)
	if err != nil {
		fail(c, err, "talep")
		return
	}
	c.JSON(http.StatusCreated, gin.H{"request": r, "dispatched": n})
}

func (a *App) buyerRequests(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	list, err := a.store.BuyerRequests(c.Request.Context(), b, c.Query("scope") == "management")
	if err != nil {
		fail(c, err, "talepler")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) buyerRequest(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	r, err := a.store.BuyerRequestByID(c.Request.Context(), b, c.Param("id"))
	if err != nil {
		fail(c, err, "talep")
		return
	}
	c.JSON(http.StatusOK, r)
}

func (a *App) addRequestPhoto(c *gin.Context) {
	b, ok := buyer(c)
	if !ok || !a.needStorage(c) {
		return
	}
	if _, err := a.store.BuyerRequestByID(c.Request.Context(), b, c.Param("id")); err != nil {
		fail(c, err, "talep")
		return
	}
	data, ctype, _, ok := readUpload(c, maxPhotoBytes, photoTypes)
	if !ok {
		return
	}
	key := fmt.Sprintf("market/requests/%s/%s", c.Param("id"), uuid.NewString())
	if _, err := a.files.Put(c.Request.Context(), key, ctype, bytes.NewReader(data)); err != nil {
		fail(c, err, "fotoğraf saklama")
		return
	}
	if err := a.store.AddRequestPhoto(c.Request.Context(), b, c.Param("id"), key); err != nil {
		_ = a.files.Delete(c.Request.Context(), key)
		fail(c, err, "fotoğraf kaydı")
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Fotoğraf eklendi"})
}

// requestPhoto, talep fotoğrafını alıcıya (kendi talebi) ya da talebi görebilen tedarikçiye verir.
func (a *App) requestPhoto(supplierSide bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !a.needStorage(c) {
			return
		}
		n, err := strconv.Atoi(c.Param("n"))
		if err != nil || n < 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
			return
		}
		var key string
		if supplierSide {
			acc := a.accountID(c)
			if acc == "" {
				return
			}
			key, err = a.store.RequestPhotoKey(c.Request.Context(), nil, acc, c.Param("id"), n)
		} else {
			b, ok := buyer(c)
			if !ok {
				return
			}
			key, err = a.store.RequestPhotoKey(c.Request.Context(), &b, "", c.Param("id"), n)
		}
		if err != nil {
			fail(c, err, "fotoğraf")
			return
		}
		rc, obj, err := a.files.Get(c.Request.Context(), key)
		if err != nil {
			fail(c, err, "fotoğraf okuma")
			return
		}
		defer rc.Close()
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("Cache-Control", "private, max-age=300")
		c.DataFromReader(http.StatusOK, obj.Size, obj.ContentType, rc, nil)
	}
}

func (a *App) supplierRequests(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	list, err := a.store.SupplierRequests(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "talepler")
		return
	}
	acc, err := a.store.Account(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "hesap")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list, "balance_kurus": acc.BalanceKurus, "period_included_left": acc.PeriodIncludedLeft,
		"account_status": acc.Status})
}

func (a *App) supplierRequest(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	r, err := a.store.SupplierRequestByID(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "talep")
		return
	}
	c.JSON(http.StatusOK, r)
}

func (a *App) acceptRequest(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	// İletişim bilgisinin açıldığı an işlem kaydına ayrıca adıyla yazılır (K10).
	c.Set("audit_event", "market.request.accepted")
	r, err := a.store.Accept(c.Request.Context(), id, c.GetString("user_id"), c.Param("id"))
	if err != nil {
		fail(c, err, "talep kabulü")
		return
	}
	c.JSON(http.StatusOK, gin.H{"request": r, "message": "Talebi kabul ettiniz; alıcının iletişim bilgileri açıldı"})
}

// notifyDueDispatches, görünür olmuş gönderimleri bildirir: uygulama içi + e-posta; SMS hakkı olan pakete SMS de.
func (a *App) notifyDueDispatches(ctx context.Context, requestID string) {
	due, err := a.store.ClaimDueDispatches(ctx, requestID)
	if err != nil {
		log.Printf("[marketplace] talep bildirimi: %v", err)
		return
	}
	for _, d := range due {
		fee := "Kabul ücreti " + store.TL(d.FeeKurus)
		if d.Included {
			fee = "Kabul, paketinizdeki talep hakkından düşer"
		}
		body := fmt.Sprintf("%s / %s bölgesinde yeni %s talebi. %s. Ayrıntı ve kabul: Usta & Hizmet → Talepler.",
			d.District, d.City, d.Category, fee)
		var extra []string
		if d.SMS {
			extra = append(extra, notify.ChannelSMS)
		}
		a.notifySupplier(ctx, "", d.AccountID, "market.request.new", "Yeni talep: "+d.Category, body,
			map[string]any{"request_id": d.RequestID}, "market.request.new:"+d.DispatchID, extra...)
	}
}

// notifyExpired, süresi dolan talebi alıcıya bildirir (uygulama içi).
func (a *App) notifyExpired(ctx context.Context, e store.ExpiredRequest) {
	if a.notifier == nil {
		log.Printf("[marketplace] talep süresi bildirimi GÖNDERİLMEDİ (bildirim altyapısı yok): %s", e.ID)
		return
	}
	body := fmt.Sprintf("%s talebinizin süresi doldu; yeni kabul alınmayacak.", e.Category)
	if e.AcceptedCount > 0 {
		body += fmt.Sprintf(" Kabul eden %d tedarikçiyle görüşmeye devam edebilirsiniz.", e.AcceptedCount)
	} else {
		body += " Talebi kabul eden olmadı; dilerseniz yeniden açabilirsiniz."
	}
	if _, err := a.notifier.Enqueue(ctx, notify.Message{PropertyID: e.PropertyID, RecipientUserID: e.RequesterUserID,
		Channel: notify.ChannelInApp, Recipient: e.RequesterUserID, Category: notify.CategoryTransactional,
		Topic: "market.request.expired", Subject: "Talebinizin süresi doldu", Body: body,
		Payload: map[string]any{"request_id": e.ID}, DedupeKey: "market.request.expired:" + e.ID}); err != nil {
		log.Printf("[marketplace] talep süresi bildirimi (%s): %v", e.ID, err)
	}
}

// showcase, sitenin vitrinidir (sakin ve yönetim): yakındaki yayındaki işletmeler.
func (a *App) showcase(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	list, err := a.store.Showcase(c.Request.Context(), b, c.Query("category_id"))
	if err != nil {
		fail(c, err, "vitrin")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) showcaseBusiness(c *gin.Context) {
	b, ok := buyer(c)
	if !ok {
		return
	}
	d, err := a.store.ShowcaseBusinessByID(c.Request.Context(), b, c.Param("id"))
	if err != nil {
		fail(c, err, "işletme")
		return
	}
	c.JSON(http.StatusOK, d)
}
