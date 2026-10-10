package main

// Kartla ödeme uçları (migration 060, TEST_RAPORU 2.5, Apsiyon BUG-09).

import (
	"context"
	"errors"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

// cardCallback: POST /api/v1/public/payments/iyzico/callback (form: token) — kimliksiz.
// Tarayıcı PAYMENT_RESULT_URL tanımlıysa sonuç sayfasına yönlendirilir; değilse JSON döner.
func cardCallback(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.PostForm("token")
		if token == "" {
			token = c.Query("token")
		}
		out, err := svc.HandleCardCallback(c.Request.Context(), token)
		if errors.Is(err, repository.ErrUnknownToken) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Ödeme bulunamadı"})
			return
		}
		if err != nil {
			log.Printf("[finance] kart geri dönüşü: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme sonucu işlenemedi; durum birkaç dakika içinde kendiliğinden güncellenecek"})
			return
		}
		if base := strings.TrimSpace(os.Getenv("PAYMENT_RESULT_URL")); base != "" && !strings.Contains(c.GetHeader("Accept"), "application/json") {
			q := url.Values{"payment_id": {out.PaymentID}, "status": {out.Status}, "message": {out.Message}}
			c.Redirect(http.StatusSeeOther, base+"?"+q.Encode())
			return
		}
		c.JSON(http.StatusOK, out)
	}
}

// cardStatus: GET /finance/payments/:id/status — ödemenin sahibi ya da yönetim.
func cardStatus(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		p, err := svc.CardStatus(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if errors.Is(err, repository.ErrPaymentNotFound) || (err == nil && p.UserID != c.GetString("user_id") && !isFinanceManager(c)) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Ödeme bulunamadı"})
			return
		}
		if err != nil {
			log.Printf("[finance] ödeme durumu: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme durumu okunamadı"})
			return
		}
		c.JSON(http.StatusOK, p)
	}
}

// startCardReconcile, sonucu gelmemiş kart ödemelerini düzenli aralıkla sağlayıcıdan sorar.
// CARD_RECONCILE_INTERVAL (vars. 1m), CARD_RECONCILE_AGE (vars. 20m: iyzico ödeme formu jetonu ~30 dk geçerli).
func startCardReconcile(svc *service.FinanceService) {
	if !svc.CardReady() {
		return
	}
	interval, age := 1*time.Minute, 20*time.Minute
	if v := os.Getenv("CARD_RECONCILE_INTERVAL"); v != "" {
		d, err := time.ParseDuration(v)
		if err != nil || d < time.Second {
			log.Fatalf("[finance] CARD_RECONCILE_INTERVAL geçersiz: %q", v)
		}
		interval = d
	}
	if v := os.Getenv("CARD_RECONCILE_AGE"); v != "" {
		d, err := time.ParseDuration(v)
		if err != nil || d < time.Second {
			log.Fatalf("[finance] CARD_RECONCILE_AGE geçersiz: %q", v)
		}
		age = d
	}
	go func() {
		t := time.NewTicker(interval)
		defer t.Stop()
		for range t.C {
			ctx, cancel := context.WithTimeout(context.Background(), interval*5)
			svc.ReconcileCards(ctx, int(age.Seconds()))
			cancel()
		}
	}()
}
