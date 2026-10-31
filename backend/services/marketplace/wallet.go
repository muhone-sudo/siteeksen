package main

// Bakiye ve paket uçları (FAZ M5): kartla bakiye yükleme (iyzico ödeme formu; kart bilgisi bu sisteme gelmez),
// sonuç sağlayıcıdan yeniden sorgulanarak işlenir; defter; paket seçimi; platformun üyelik kapanışı.

import (
	"context"
	"errors"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/iyzico"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/marketplace/store"
)

func (a *App) wallet(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if limit < 1 || limit > 200 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}
	acc, err := a.store.Account(c.Request.Context(), id)
	if err != nil {
		fail(c, err, "hesap")
		return
	}
	list, total, err := a.store.Ledger(c.Request.Context(), id, limit, offset)
	if err != nil {
		fail(c, err, "bakiye hareketleri")
		return
	}
	c.JSON(http.StatusOK, gin.H{"balance_kurus": acc.BalanceKurus, "package": acc.Package, "next_package_id": acc.NextPackageID,
		"package_renews_at": acc.PackageRenewsAt, "period_included_left": acc.PeriodIncludedLeft, "period_sms_left": acc.PeriodSMSLeft,
		"data": list, "total": total, "limit": limit, "offset": offset, "card_ready": a.card != nil})
}

func (a *App) startTopup(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	if a.card == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Kartla ödeme bu kurulumda yapılandırılmamış", "code": "NO_PAYMENT"})
		return
	}
	var in struct {
		AmountKurus int64 `json:"amount_kurus"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "amount_kurus (kuruş, tam sayı) zorunludur"})
		return
	}
	ctx := c.Request.Context()
	t, created, err := a.store.CreateTopup(ctx, id, c.GetString("user_id"), in.AmountKurus, strings.TrimSpace(c.GetHeader("Idempotency-Key")))
	if err != nil {
		fail(c, err, "bakiye yükleme")
		return
	}
	if !created {
		c.JSON(http.StatusOK, gin.H{"topup": t, "note": "Bu istek daha önce alındı; aynı yükleme döndü."})
		return
	}
	contact, err := a.store.AccountContact(ctx, "", id)
	if err != nil {
		fail(c, err, "alıcı bilgisi")
		return
	}
	user, err := a.store.UserName(ctx, id, contact.UserID)
	if err != nil {
		fail(c, err, "alıcı bilgisi")
		return
	}
	email := contact.Email
	if email == "" {
		// iyzico e-postayı zorunlu tutar; kayıtlı e-posta yoksa yalnız işlem için geçersiz alan adı kullanılır.
		email = "tedarikci-" + id[:8] + "@siteeksen.invalid"
	}
	price := iyzico.Price(t.AmountKurus)
	init, err := a.card.Initialize(ctx, iyzico.InitializeRequest{
		ConversationID: t.ID, Price: price, PaidPrice: price, BasketID: t.ID,
		Buyer: iyzico.Buyer{ID: contact.UserID, Name: user[0], Surname: user[1], GsmNumber: contact.Phone, Email: email,
			IdentityNumber: "11111111111", RegistrationAddress: "Usta & Hizmet tedarikçi hesabı", IP: c.ClientIP(), City: "Istanbul", Country: "Turkey"},
		BillingAddress: iyzico.Address{ContactName: user[0] + " " + user[1], City: "Istanbul", Country: "Turkey", Address: "Usta & Hizmet tedarikçi hesabı"},
		BasketItems:    []iyzico.BasketItem{{ID: t.ID, Name: "Usta & Hizmet bakiye yükleme", Category1: "Pazaryeri", ItemType: "VIRTUAL", Price: price}},
	})
	if err != nil {
		msg := "Ödeme sağlayıcısına ulaşılamadı; lütfen birazdan yeniden deneyin"
		var ae *iyzico.APIError
		if errors.As(err, &ae) {
			_, msg = iyzico.Classify(ae.Code, ae.Message)
		} else {
			log.Printf("[marketplace] iyzico başlatma (%s): %v", t.ID, err)
		}
		_ = a.store.FailTopup(ctx, id, t.ID, msg)
		c.JSON(http.StatusBadGateway, gin.H{"error": msg, "topup_id": t.ID})
		return
	}
	if err := a.store.SetTopupToken(ctx, id, t.ID, init.Token); err != nil {
		fail(c, err, "ödeme kaydı")
		return
	}
	c.JSON(http.StatusCreated, gin.H{"topup": t, "checkout_url": init.PaymentPageURL,
		"note": "Ödeme sayfasında kart bilgilerinizi ve 3D Secure doğrulamasını girin. Tutar, ödeme onaylanınca bakiyenize eklenir."})
}

func (a *App) topupStatus(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	t, err := a.store.GetTopup(c.Request.Context(), id, c.Param("id"))
	if err != nil {
		fail(c, err, "yükleme")
		return
	}
	c.JSON(http.StatusOK, t)
}

// settleTopup, yüklemenin sonucunu sağlayıcıdan sorar; tutar ve sepet kimliği doğrulanınca bakiyeye işler.
// expire=true ise sonuç hâlâ belirsizse yükleme başarısız kapanır (tutar çekilmemiştir).
func (a *App) settleTopup(ctx context.Context, t *store.Topup, expire bool) (string, string, error) {
	switch t.Status {
	case "SUCCEEDED":
		return "SUCCEEDED", "Bakiye yüklendi.", nil
	case "FAILED":
		msg := ""
		if t.ErrorMessage != nil {
			msg = *t.ErrorMessage
		}
		return "FAILED", msg, nil
	}
	if a.card == nil || t.Token == nil {
		return "PENDING", "Ödeme sonucu bekleniyor.", nil
	}
	res, err := a.card.Retrieve(ctx, *t.Token, t.ID)
	if err != nil {
		log.Printf("[marketplace] iyzico sonuç sorgusu (%s): %v", t.ID, err)
		if expire {
			msg := "Ödeme sonucu bankadan alınamadı; tutar kartınızdan çekilmedi. Yeniden deneyebilirsiniz."
			return "FAILED", msg, a.store.FailTopup(ctx, t.AccountID, t.ID, msg)
		}
		return "PENDING", "Ödeme sonucu bankadan bekleniyor.", nil
	}
	switch res.PaymentStatus {
	case "SUCCESS":
		paid, perr := iyzico.ParsePriceKurus(res.PaidPrice)
		if perr != nil || paid != t.AmountKurus || res.BasketID != t.ID {
			log.Printf("[marketplace] KRİTİK: iyzico tutar/sepet uyuşmazlığı yükleme=%s çekilen=%s sepet=%s", t.ID, res.PaidPrice, res.BasketID)
			msg := "Bankadan dönen tutar yükleme kaydıyla uyuşmadı; bakiyeye işlenmedi. Destek ekibi inceleyecek."
			return "FAILED", msg, a.store.FailTopup(ctx, t.AccountID, t.ID, msg)
		}
		if _, err := a.store.CompleteTopup(ctx, t.AccountID, t.ID, res.PaymentID); err != nil {
			return "", "", err
		}
		return "SUCCEEDED", "Bakiye yüklendi.", nil
	case "FAILURE":
		_, msg := iyzico.Classify(res.ErrorCode, res.ErrorMessage)
		return "FAILED", msg, a.store.FailTopup(ctx, t.AccountID, t.ID, msg)
	}
	if expire {
		msg := "3D Secure doğrulaması süresinde tamamlanmadı; tutar kartınızdan çekilmedi."
		return "FAILED", msg, a.store.FailTopup(ctx, t.AccountID, t.ID, msg)
	}
	return "PENDING", "3D Secure doğrulaması bekleniyor.", nil
}

// topupCallback: kimliksiz; iyzico tarayıcıyı jetonla gönderir. Sonuç sağlayıcıdan YENİDEN sorgulanır.
func (a *App) topupCallback(c *gin.Context) {
	token := c.PostForm("token")
	if token == "" {
		token = c.Query("token")
	}
	t, err := a.store.TopupByToken(c.Request.Context(), strings.TrimSpace(token))
	if errors.Is(err, store.ErrNotFound) || strings.TrimSpace(token) == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Yükleme bulunamadı"})
		return
	}
	if err != nil {
		fail(c, err, "ödeme dönüşü")
		return
	}
	status, msg, err := a.settleTopup(c.Request.Context(), t, false)
	if err != nil {
		log.Printf("[marketplace] ödeme dönüşü (%s): %v", t.ID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme sonucu işlenemedi; durum birkaç dakika içinde kendiliğinden güncellenecek"})
		return
	}
	if base := strings.TrimSpace(os.Getenv("MARKET_TOPUP_RESULT_URL")); base != "" && !strings.Contains(c.GetHeader("Accept"), "application/json") {
		q := url.Values{"topup_id": {t.ID}, "status": {status}, "message": {msg}}
		c.Redirect(http.StatusSeeOther, base+"?"+q.Encode())
		return
	}
	c.JSON(http.StatusOK, gin.H{"topup_id": t.ID, "status": status, "message": msg})
}

func (a *App) changePackage(c *gin.Context) {
	id := a.accountID(c)
	if id == "" {
		return
	}
	var in struct {
		PackageID string `json:"package_id"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.PackageID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "package_id zorunludur"})
		return
	}
	acc, msg, err := a.store.ChangePackage(c.Request.Context(), id, c.GetString("user_id"), in.PackageID)
	if err != nil {
		fail(c, err, "paket değişikliği")
		return
	}
	a.lowBalanceCheck(c.Request.Context(), id, acc.BalanceKurus)
	c.JSON(http.StatusOK, gin.H{"account": acc, "message": msg})
}

func (a *App) closeAccount(c *gin.Context) {
	var in struct {
		Reason          string `json:"reason"`
		RefundReference string `json:"refund_reference"`
		RefundDate      string `json:"refund_date"`
	}
	_ = c.ShouldBindJSON(&in)
	admin := c.GetString("user_id")
	acc, err := a.store.CloseAccount(c.Request.Context(), admin, c.Param("id"), strings.TrimSpace(in.Reason),
		strings.TrimSpace(in.RefundReference), strings.TrimSpace(in.RefundDate))
	if err != nil {
		fail(c, err, "üyelik kapanışı")
		return
	}
	c.Set("audit_details", gin.H{"account_id": acc.ID, "refund_reference": in.RefundReference, "refund_date": in.RefundDate})
	res := a.notifySupplier(c.Request.Context(), admin, acc.ID, "market.supplier.closed", "Usta & Hizmet üyeliğiniz", "Usta & Hizmet üyeliğiniz kapatıldı. "+
		"Gerekçe: "+in.Reason, map[string]any{"account_id": acc.ID}, "")
	c.JSON(http.StatusOK, gin.H{"account": acc, "notification": res})
}

// lowBalanceCheck, bakiye eşiğin altındaysa tedarikçiye (günde bir kez) haber verir.
func (a *App) lowBalanceCheck(ctx context.Context, accountID string, balance int64) {
	threshold, err := a.store.SettingValue(ctx, "low_balance_threshold_kurus")
	if err != nil || balance >= int64(threshold) || a.notifier == nil {
		return
	}
	contact, err := a.store.AccountContact(ctx, "", accountID)
	if err != nil {
		return
	}
	_, err = a.notifier.Enqueue(ctx, notify.Message{SupplierAccountID: accountID, RecipientUserID: contact.UserID,
		Recipient: contact.UserID, Channel: notify.ChannelInApp, Topic: "market.wallet.low", Subject: "Bakiyeniz azaldı",
		Body:      "Usta & Hizmet bakiyeniz azaldı. Talepleri kabul edebilmek için bakiye yükleyin.",
		DedupeKey: "market.wallet.low:" + time.Now().Format("2006-01-02")})
	if err != nil && !errors.Is(err, notify.ErrDuplicate) {
		log.Printf("[marketplace] bakiye uyarısı (%s): %v", accountID, err)
	}
}
