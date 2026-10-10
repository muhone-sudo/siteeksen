package service

// Kartla ödeme (migration 060, TEST_RAPORU 2.5, Apsiyon BUG-09): iyzico ödeme formu, 3D Secure
// dönüşü ve durum makinesi. Kart bilgisi bu sisteme hiç gelmez.

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/siteeksen/backend/pkg/iyzico"
	"github.com/siteeksen/backend/services/finance/repository"
)

// ErrCardUnavailable: sağlayıcıya ulaşılamadı ya da ödeme sayfası açılamadı.
var ErrCardUnavailable = errors.New("ödeme sayfası açılamadı")

// SetCardGateway, kartla ödeme sağlayıcısını verir (nil olabilir).
func (s *FinanceService) SetCardGateway(c *iyzico.Client) { s.card = c }

// CardReady, kartla ödemenin yapılandırılıp yapılandırılmadığını söyler.
func (s *FinanceService) CardReady() bool { return s.card != nil }

// CardOutcome, geri dönüş/uzlaştırma sonucudur.
type CardOutcome struct {
	PaymentID string `json:"payment_id"`
	Status    string `json:"status"` // COMPLETED | FAILED | PENDING
	Message   string `json:"message"`
}

func today() time.Time {
	t, _ := time.Parse("2006-01-02", time.Now().Format("2006-01-02"))
	return t
}

// StartCardPayment: ödeme kaydı (PENDING) açılır, gecikme tazminatı deneme gününde dondurulur,
// iyzico ödeme sayfası başlatılır. Son iki günde sistem kaynaklı başarısız deneme varsa onun günü valör olur.
func (s *FinanceService) StartCardPayment(ctx context.Context, propertyID, userID string, assessmentIDs []string, clientIP string) (*PaymentResult, error) {
	if s.card == nil {
		return nil, iyzico.ErrNotConfigured
	}
	vd := today()
	inherited := false
	if d, err := s.repo.SystemFailedValueDate(ctx, propertyID, userID, assessmentIDs); err != nil {
		return nil, err
	} else if d != nil && d.Before(vd) {
		vd, inherited = *d, true
	}
	if err := s.freezeLateFees(ctx, propertyID, userID, assessmentIDs, vd); err != nil {
		return nil, err
	}
	paymentID, total, err := s.repo.CreatePayment(ctx, propertyID, userID, assessmentIDs, "CREDIT_CARD", &vd, "")
	if err != nil {
		return nil, err
	}
	// Açılamayan ödeme PENDING bırakılmaz: aynı tahakkuk için yeni denemeyi engellerdi.
	fail := func(code, msg string) {
		if _, ferr := s.repo.FailCardPayment(ctx, propertyID, paymentID, "FAILED", code, msg, "SYSTEM"); ferr != nil {
			log.Printf("[finance] kart ödemesi kapatılamadı (%s): %v", paymentID, ferr)
		}
	}
	buyer, err := s.repo.BuyerInfo(ctx, propertyID, userID, assessmentIDs)
	if err != nil {
		fail("BUYER", "Alıcı bilgisi okunamadı")
		return nil, err
	}
	lines, err := s.repo.PaymentLines(ctx, propertyID, paymentID)
	if err != nil {
		fail("BASKET", "Sepet oluşturulamadı")
		return nil, err
	}
	var totalKurus int64
	items := make([]iyzico.BasketItem, 0, len(lines))
	for _, l := range lines {
		totalKurus += l.Kurus
		items = append(items, iyzico.BasketItem{ID: l.AssessmentID, Name: l.Label, Category1: "Aidat", ItemType: "VIRTUAL", Price: iyzico.Price(l.Kurus)})
	}
	city := buyer.City
	if city == "" {
		city = "Istanbul"
	}
	addr := strings.TrimSpace(buyer.PropertyName + " " + strings.Join(buyer.Units, ", ") + " " + buyer.Address)
	email := buyer.Email
	if email == "" {
		// iyzico e-postayı zorunlu tutar; kayıtlı e-posta yoksa yalnızca işlem için geçersiz alan adı kullanılır.
		email = "sakin-" + userID[:8] + "@siteeksen.invalid"
	}
	req := iyzico.InitializeRequest{
		ConversationID: paymentID, Price: iyzico.Price(totalKurus), PaidPrice: iyzico.Price(totalKurus), BasketID: paymentID,
		Buyer: iyzico.Buyer{ID: userID, Name: buyer.FirstName, Surname: buyer.LastName, GsmNumber: buyer.Phone, Email: email,
			// TCKN sakinlerde tutulmaz (veri en aza indirme, KVKK m.4); iyzico'nun kabul ettiği yer tutucu gönderilir.
			IdentityNumber: "11111111111", RegistrationAddress: addr, IP: clientIP, City: city, Country: "Turkey"},
		BillingAddress: iyzico.Address{ContactName: buyer.FirstName + " " + buyer.LastName, City: city, Country: "Turkey", Address: addr},
		BasketItems:    items,
	}
	init, err := s.card.Initialize(ctx, req)
	if err != nil {
		var ae *iyzico.APIError
		if errors.As(err, &ae) {
			_, msg := iyzico.Classify(ae.Code, ae.Message)
			fail(ae.Code, msg)
			return nil, fmt.Errorf("%w: %s", ErrCardUnavailable, msg)
		}
		log.Printf("[finance] iyzico başlatma hatası (%s): %v", paymentID, err)
		fail("UNREACHABLE", "Ödeme sağlayıcısına ulaşılamadı")
		return nil, fmt.Errorf("%w: ödeme sağlayıcısına ulaşılamadı; lütfen birazdan yeniden deneyin", ErrCardUnavailable)
	}
	if err := s.repo.SetCardInitiated(ctx, propertyID, paymentID, "IYZICO", init.Token); err != nil {
		return nil, err
	}
	note := "Ödeme sayfasında kart bilgilerinizi ve 3D Secure doğrulamasını girin. İşlem sonuçlanana kadar ödemeniz " +
		"\"işlemde\" görünür ve gecikme tazminatı " + vd.Format("02.01.2006") + " itibarıyla işlemez."
	if inherited {
		note += " Önceki denemeniz sistem kaynaklı bir hatayla tamamlanamadığı için o günün tarihi esas alındı."
	}
	return &PaymentResult{PaymentID: paymentID, Amount: total, Status: "PENDING", PaymentGatewayReady: true,
		CheckoutURL: init.PaymentPageURL, GatewayStatus: "INITIATED", ValueDate: vd.Format("2006-01-02"), Note: note}, nil
}

// HandleCardCallback: sağlayıcının geri dönüşü. Sonuç jetonla sağlayıcıdan YENİDEN sorgulanır;
// tutar ve sepet kimliği doğrulanır. Aynı jetonla ikinci çağrı sonucu değiştirmez (idempotent).
func (s *FinanceService) HandleCardCallback(ctx context.Context, token string) (*CardOutcome, error) {
	token = strings.TrimSpace(token)
	if token == "" {
		return nil, repository.ErrUnknownToken
	}
	paymentID, propertyID, err := s.repo.CardPaymentByToken(ctx, token)
	if err != nil {
		return nil, err
	}
	if err := s.repo.MarkCardProcessing(ctx, propertyID, paymentID); err != nil {
		return nil, err
	}
	return s.settleCard(ctx, propertyID, paymentID, false)
}

// settleCard, ödemenin sonucunu sağlayıcıdan sorgulayıp durumunu kapatır. expire=true ise
// sonuç hâlâ belirsizse ödeme zaman aşımına (EXPIRED, sistem kaynaklı) düşer.
func (s *FinanceService) settleCard(ctx context.Context, propertyID, paymentID string, expire bool) (*CardOutcome, error) {
	p, err := s.repo.GetCardPayment(ctx, propertyID, paymentID)
	if err != nil {
		return nil, err
	}
	out := &CardOutcome{PaymentID: paymentID}
	switch p.Status {
	case "COMPLETED":
		out.Status, out.Message = "COMPLETED", "Ödeme alındı."
		return out, nil
	case "FAILED":
		out.Status, out.Message = "FAILED", deref(p.ErrorMessage)
		return out, nil
	}
	if s.card == nil || p.Token == nil {
		out.Status, out.Message = "PENDING", "Ödeme sonucu bekleniyor."
		return out, nil
	}
	res, err := s.card.Retrieve(ctx, *p.Token, paymentID)
	if err != nil {
		// Sağlayıcıya ulaşılamadı ya da sonuç henüz yok: ödeme havada BIRAKILMAZ — uzlaştırma
		// bekçisi yeniden sorar; süre dolarsa zaman aşımıyla kapanır.
		log.Printf("[finance] iyzico sonuç sorgusu (%s): %v", paymentID, err)
		if expire {
			msg := "Ödeme sonucu bankadan alınamadı; tutar kartınızdan çekilmedi. Yeniden deneyebilirsiniz; gecikme tazminatı ilk deneme gününe göre hesaplanır."
			if _, ferr := s.repo.FailCardPayment(ctx, propertyID, paymentID, "EXPIRED", "TIMEOUT", msg, "SYSTEM"); ferr != nil {
				return nil, ferr
			}
			out.Status, out.Message = "FAILED", msg
			return out, nil
		}
		out.Status, out.Message = "PENDING", "Ödeme sonucu bankadan bekleniyor."
		return out, nil
	}
	switch res.PaymentStatus {
	case "SUCCESS":
		paid, perr := iyzico.ParsePriceKurus(res.PaidPrice)
		if perr != nil || paid != p.AmountKurus || res.BasketID != paymentID {
			// Çekilen tutar/sepet borçla uyuşmuyor: borç DÜŞÜRÜLMEZ; yönetim iade/inceleme yapmalı.
			log.Printf("[finance] KRİTİK: iyzico tutar/sepet uyuşmazlığı ödeme=%s çekilen=%s sepet=%s", paymentID, res.PaidPrice, res.BasketID)
			msg := "Bankadan dönen tutar ödeme kaydıyla uyuşmadı; ödeme borca işlenmedi. Site yönetimi inceleyecek."
			if _, ferr := s.repo.FailCardPayment(ctx, propertyID, paymentID, "FAILED", "AMOUNT_MISMATCH", msg, "SYSTEM"); ferr != nil {
				return nil, ferr
			}
			out.Status, out.Message = "FAILED", msg
			return out, nil
		}
		if _, err := s.repo.CompleteCardPayment(ctx, propertyID, paymentID, res.PaymentID); err != nil {
			return nil, err
		}
		out.Status, out.Message = "COMPLETED", "Ödeme alındı ve borcunuzdan düşüldü."
		return out, nil
	case "FAILURE":
		kind, msg := iyzico.Classify(res.ErrorCode, res.ErrorMessage)
		if _, err := s.repo.FailCardPayment(ctx, propertyID, paymentID, "FAILED", res.ErrorCode, msg, kind); err != nil {
			return nil, err
		}
		out.Status, out.Message = "FAILED", msg
		return out, nil
	}
	// INIT_THREEDS / CALLBACK_THREEDS: 3D Secure tamamlanmadı.
	if expire {
		msg := "3D Secure doğrulaması süresinde tamamlanmadı; tutar kartınızdan çekilmedi. Yeniden deneyebilirsiniz."
		if _, err := s.repo.FailCardPayment(ctx, propertyID, paymentID, "EXPIRED", "3DS_TIMEOUT", msg, "SYSTEM"); err != nil {
			return nil, err
		}
		out.Status, out.Message = "FAILED", msg
		return out, nil
	}
	out.Status, out.Message = "PENDING", "3D Secure doğrulaması bekleniyor."
	return out, nil
}

// ReconcileCards, sonucu gelmemiş eski kart ödemelerini sağlayıcıdan sorar ve kapatır.
func (s *FinanceService) ReconcileCards(ctx context.Context, ageSecs int) {
	list, err := s.repo.StaleCardPayments(ctx, ageSecs)
	if err != nil {
		log.Printf("[finance] kart uzlaştırma: %v", err)
		return
	}
	for _, it := range list {
		if out, err := s.settleCard(ctx, it[1], it[0], true); err != nil {
			log.Printf("[finance] kart uzlaştırma (%s): %v", it[0], err)
		} else {
			log.Printf("[finance] kart uzlaştırma %s → %s", it[0], out.Status)
		}
	}
}

// CardStatus, ödemenin durumunu verir (sahibi ya da yönetim).
func (s *FinanceService) CardStatus(ctx context.Context, propertyID, paymentID string) (*repository.CardPayment, error) {
	return s.repo.GetCardPayment(ctx, propertyID, paymentID)
}

func deref(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}
