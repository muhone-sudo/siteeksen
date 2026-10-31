package main

// Platform yönetimi uçları (FAZ M4): yalnız PLATFORM_ADMIN. Hesap ve işletme incelemesi, kategori, paket, ayar.

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/marketplace/store"
)

func (a *App) platformAccounts(c *gin.Context) {
	list, err := a.store.PlatformAccounts(c.Request.Context(), c.GetString("user_id"), c.Query("status"))
	if err != nil {
		fail(c, err, "hesap listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) platformAccount(c *gin.Context) {
	acc, docs, biz, err := a.store.PlatformAccount(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	if err != nil {
		fail(c, err, "hesap")
		return
	}
	c.JSON(http.StatusOK, gin.H{"account": acc, "documents": docs, "businesses": biz})
}

func (a *App) platformDocument(c *gin.Context) {
	if !a.needStorage(c) {
		return
	}
	d, err := a.store.PlatformDocument(c.Request.Context(), c.GetString("user_id"), c.Param("id"))
	if err != nil {
		fail(c, err, "belge")
		return
	}
	a.serveFile(c, d.StorageKey, d.ContentType, d.FileName)
}

var accountReviewText = map[string][2]string{
	"approve":   {"market.supplier.approved", "Tedarikçi hesabınız onaylandı. İşletmeleriniz incelemeden geçince Usta & Hizmet havuzunda görünecek."},
	"reject":    {"market.supplier.rejected", "Tedarikçi hesabınız onaylanmadı. Gerekçe: %s. Bilgilerinizi düzeltip yeniden incelemeye gönderebilirsiniz."},
	"suspend":   {"market.supplier.suspended", "Tedarikçi hesabınız askıya alındı. Gerekçe: %s. İşletmeleriniz havuzda görünmez."},
	"reinstate": {"market.supplier.approved", "Tedarikçi hesabınız yeniden etkinleştirildi."},
}

func (a *App) reviewAccount(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason            string   `json:"reason"`
			RejectDocumentIDs []string `json:"reject_document_ids"`
		}
		_ = c.ShouldBindJSON(&in)
		admin := c.GetString("user_id")
		acc, err := a.store.ReviewAccount(c.Request.Context(), admin, c.Param("id"), action, in.Reason, in.RejectDocumentIDs)
		if err != nil {
			fail(c, err, "hesap incelemesi")
			return
		}
		t := accountReviewText[action]
		body := t[1]
		if strings.Contains(body, "%s") {
			body = fmt.Sprintf(body, in.Reason)
		}
		res := a.notifySupplier(c, admin, acc.ID, t[0], "Usta & Hizmet hesabınız", body,
			map[string]any{"account_id": acc.ID, "status": acc.Status}, "")
		c.JSON(http.StatusOK, gin.H{"account": acc, "notification": res})
	}
}

func (a *App) platformBusinesses(c *gin.Context) {
	list, err := a.store.PlatformBusinesses(c.Request.Context(), c.GetString("user_id"), c.Query("status"))
	if err != nil {
		fail(c, err, "işletme listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) reviewBusiness(action string) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason"`
		}
		_ = c.ShouldBindJSON(&in)
		admin := c.GetString("user_id")
		b, err := a.store.ReviewBusiness(c.Request.Context(), admin, c.Param("id"), action, in.Reason)
		if err != nil {
			fail(c, err, "işletme incelemesi")
			return
		}
		topic, body := "market.business.approved", "\""+b.Name+"\" işletmeniz yayına alındı; artık Usta & Hizmet havuzunda görünüyor."
		if action == "reject" {
			topic, body = "market.business.rejected", "\""+b.Name+"\" işletmeniz yayına alınmadı. Gerekçe: "+in.Reason
		}
		res := a.notifySupplier(c, admin, b.AccountID, topic, "Usta & Hizmet işletmeniz", body,
			map[string]any{"business_id": b.ID, "status": b.Status}, "")
		c.JSON(http.StatusOK, gin.H{"business": b, "notification": res})
	}
}

func (a *App) platformCategories(c *gin.Context) {
	list, err := a.store.AllCategories(c.Request.Context(), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "kategori listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) saveCategory(c *gin.Context) {
	var in store.CategoryInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	cat, err := a.store.SaveCategory(c.Request.Context(), c.GetString("user_id"), c.Param("id"), in)
	if err != nil {
		fail(c, err, "kategori kaydı")
		return
	}
	c.Set("audit_details", gin.H{"category_id": cat.ID, "name": cat.Name, "request_fee_kurus": cat.RequestFeeKurus,
		"buyer_scope": cat.BuyerScope, "is_active": cat.IsActive})
	status := http.StatusOK
	if c.Param("id") == "" {
		status = http.StatusCreated
	}
	c.JSON(status, cat)
}

func (a *App) platformPackages(c *gin.Context) {
	list, err := a.store.AllPackages(c.Request.Context(), c.GetString("user_id"))
	if err != nil {
		fail(c, err, "paket listesi")
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": list})
}

func (a *App) savePackage(c *gin.Context) {
	var in store.Package
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return
	}
	p, err := a.store.SavePackage(c.Request.Context(), c.GetString("user_id"), c.Param("id"), in)
	if err != nil {
		fail(c, err, "paket kaydı")
		return
	}
	c.Set("audit_details", gin.H{"package_id": p.ID, "name": p.Name, "monthly_fee_kurus": p.MonthlyFeeKurus,
		"fee_discount_pct": p.FeeDiscountPct, "included_requests": p.IncludedRequests, "monthly_sms": p.MonthlySMS})
	status := http.StatusOK
	if c.Param("id") == "" {
		status = http.StatusCreated
	}
	c.JSON(status, p)
}

func (a *App) saveSetting(c *gin.Context) {
	var in struct {
		Value *int `json:"value"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.Value == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "value (tam sayı) zorunludur"})
		return
	}
	x, err := a.store.SaveSetting(c.Request.Context(), c.GetString("user_id"), c.Param("key"), *in.Value)
	if err != nil {
		fail(c, err, "ayar kaydı")
		return
	}
	c.Set("audit_details", gin.H{"key": x.Key, "value": x.Value})
	c.JSON(http.StatusOK, x)
}
