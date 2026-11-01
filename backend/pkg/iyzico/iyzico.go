// Package iyzico, iyzico Ödeme Formu (Checkout Form) istemcisidir (TEST_RAPORU 2.5, Apsiyon BUG-09).
//
// Kart bilgisi bu sisteme HİÇ gelmez: kullanıcı iyzico'nun barındırdığı ödeme sayfasında
// kartını ve 3D Secure doğrulamasını girer (PCI-DSS kapsamı sağlayıcıdadır). Akış:
//
//  1. Initialize: sepet ve alıcıyla ödeme sayfası açılır → jeton + ödeme sayfası adresi.
//  2. iyzico, işlem bitince jetonu geri dönüş adresine POST eder.
//  3. Retrieve: sonuç jetonla iyzico'dan YENİDEN sorgulanır — geri dönüş gövdesine güvenilmez.
//
// Kimlik doğrulama IYZWSv2: imza = HMAC-SHA256(gizli anahtar, rastgele anahtar + URI yolu + gövde).
// Yalnızca standart kütüphane kullanılır.
package iyzico

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	initializePath = "/payment/iyzipos/checkoutform/initialize/auth/ecom"
	retrievePath   = "/payment/iyzipos/checkoutform/auth/ecom/detail"
	refundPath     = "/v2/payment/refund"
)

// ErrNotConfigured, sağlayıcının yapılandırılmadığını bildirir.
var ErrNotConfigured = errors.New("iyzico yapılandırılmamış")

// Client, iyzico API istemcisidir.
type Client struct {
	APIKey, SecretKey, BaseURL, CallbackURL string
	HTTP                                    *http.Client
}

// FromEnv, IYZICO_API_KEY / IYZICO_SECRET_KEY / IYZICO_BASE_URL / IYZICO_CALLBACK_URL ile kurar.
// Hiçbiri yoksa (nil, nil) döner; bir kısmı varsa hata döner — yarım yapılandırma sessizce
// "kartla ödeme yok" demez, servis açılmaz.
func FromEnv() (*Client, error) {
	c := &Client{
		APIKey: strings.TrimSpace(os.Getenv("IYZICO_API_KEY")), SecretKey: strings.TrimSpace(os.Getenv("IYZICO_SECRET_KEY")),
		BaseURL: strings.TrimRight(strings.TrimSpace(os.Getenv("IYZICO_BASE_URL")), "/"), CallbackURL: strings.TrimSpace(os.Getenv("IYZICO_CALLBACK_URL")),
		HTTP: &http.Client{Timeout: 20 * time.Second},
	}
	set := 0
	for _, v := range []string{c.APIKey, c.SecretKey, c.BaseURL, c.CallbackURL} {
		if v != "" {
			set++
		}
	}
	switch {
	case set == 0:
		return nil, nil
	case set < 4:
		return nil, errors.New("iyzico yapılandırması eksik: IYZICO_API_KEY, IYZICO_SECRET_KEY, IYZICO_BASE_URL ve IYZICO_CALLBACK_URL birlikte verilmeli")
	}
	if !strings.HasPrefix(c.CallbackURL, "https://") && !strings.HasPrefix(c.CallbackURL, "http://127.0.0.1") && !strings.HasPrefix(c.CallbackURL, "http://localhost") {
		return nil, errors.New("IYZICO_CALLBACK_URL https olmalıdır")
	}
	return c, nil
}

// Price, iyzico'nun beklediği tutar metnidir ("640.0", "250.5"): kuruştan üretilir, float kullanılmaz.
func Price(kurus int64) string {
	s := fmt.Sprintf("%d.%02d", kurus/100, kurus%100)
	s = strings.TrimRight(s, "0")
	if strings.HasSuffix(s, ".") {
		s += "0"
	}
	return s
}

// ParsePriceKurus, iyzico'nun döndürdüğü tutarı (sayı ya da metin) kuruşa çevirir.
func ParsePriceKurus(v json.Number) (int64, error) {
	s := v.String()
	whole, frac, _ := strings.Cut(s, ".")
	if len(frac) > 2 {
		if strings.Trim(frac[2:], "0") != "" {
			return 0, fmt.Errorf("tutar kuruş hassasiyetini aşıyor: %s", s)
		}
		frac = frac[:2]
	}
	for len(frac) < 2 {
		frac += "0"
	}
	w, err := strconv.ParseInt(whole, 10, 64)
	if err != nil {
		return 0, err
	}
	f, err := strconv.ParseInt(frac, 10, 64)
	if err != nil {
		return 0, err
	}
	return w*100 + f, nil
}

// Buyer, alıcıdır (iyzico zorunlu alanları).
type Buyer struct {
	ID                  string `json:"id"`
	Name                string `json:"name"`
	Surname             string `json:"surname"`
	GsmNumber           string `json:"gsmNumber,omitempty"`
	Email               string `json:"email"`
	IdentityNumber      string `json:"identityNumber"`
	RegistrationAddress string `json:"registrationAddress"`
	IP                  string `json:"ip"`
	City                string `json:"city"`
	Country             string `json:"country"`
}

// Address, fatura adresidir.
type Address struct {
	ContactName string `json:"contactName"`
	City        string `json:"city"`
	Country     string `json:"country"`
	Address     string `json:"address"`
}

// BasketItem, sepet kalemidir (aidat: sanal ürün).
type BasketItem struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Category1 string `json:"category1"`
	ItemType  string `json:"itemType"`
	Price     string `json:"price"`
}

// InitializeRequest, ödeme formu başlatma isteğidir.
type InitializeRequest struct {
	Locale              string       `json:"locale"`
	ConversationID      string       `json:"conversationId"`
	Price               string       `json:"price"`
	PaidPrice           string       `json:"paidPrice"`
	Currency            string       `json:"currency"`
	BasketID            string       `json:"basketId"`
	PaymentGroup        string       `json:"paymentGroup"`
	CallbackURL         string       `json:"callbackUrl"`
	EnabledInstallments []int        `json:"enabledInstallments"`
	Buyer               Buyer        `json:"buyer"`
	BillingAddress      Address      `json:"billingAddress"`
	BasketItems         []BasketItem `json:"basketItems"`
}

// InitializeResponse, ödeme formu yanıtıdır.
type InitializeResponse struct {
	Status         string `json:"status"`
	ErrorCode      string `json:"errorCode"`
	ErrorMessage   string `json:"errorMessage"`
	Token          string `json:"token"`
	PaymentPageURL string `json:"paymentPageUrl"`
	TokenExpire    int    `json:"tokenExpireTime"`
}

// RetrieveResponse, ödeme sonucu sorgusunun yanıtıdır.
type RetrieveResponse struct {
	Status        string      `json:"status"`
	ErrorCode     string      `json:"errorCode"`
	ErrorMessage  string      `json:"errorMessage"`
	PaymentStatus string      `json:"paymentStatus"` // SUCCESS | FAILURE | INIT_THREEDS | CALLBACK_THREEDS
	PaymentID     string      `json:"paymentId"`
	PaidPrice     json.Number `json:"paidPrice"`
	BasketID      string      `json:"basketId"`
	FraudStatus   int         `json:"fraudStatus"`
	MDStatus      int         `json:"mdStatus"`
}

// RefundResponse, iade yanıtıdır (iade v2: ödeme kimliğiyle, kısmi tutar; ödemeden sonra 365 gün içinde).
type RefundResponse struct {
	Status              string      `json:"status"`
	ErrorCode           string      `json:"errorCode"`
	ErrorMessage        string      `json:"errorMessage"`
	PaymentID           string      `json:"paymentId"`
	Price               json.Number `json:"price"`
	RefundHostReference string      `json:"refundHostReference"`
}

// APIError, iyzico'nun "failure" yanıtıdır (iş kuralı reddi).
type APIError struct{ Code, Message string }

func (e *APIError) Error() string { return "iyzico: " + e.Code + " " + e.Message }

// Authorization, IYZWSv2 başlığını üretir (testlerde doğrulama için dışa açık).
func Authorization(apiKey, secret, randomKey, uriPath string, body []byte) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(randomKey + uriPath))
	mac.Write(body)
	sig := hex.EncodeToString(mac.Sum(nil))
	raw := "apiKey:" + apiKey + "&randomKey:" + randomKey + "&signature:" + sig
	return "IYZWSv2 " + base64.StdEncoding.EncodeToString([]byte(raw))
}

func (c *Client) post(ctx context.Context, path string, in, out any) error {
	body, err := json.Marshal(in)
	if err != nil {
		return err
	}
	rb := make([]byte, 8)
	if _, err := rand.Read(rb); err != nil {
		return err
	}
	randomKey := strconv.FormatInt(time.Now().UnixMilli(), 10) + hex.EncodeToString(rb)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+path, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("x-iyzi-rnd", randomKey)
	req.Header.Set("Authorization", Authorization(c.APIKey, c.SecretKey, randomKey, path, body))
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return err
	}
	if resp.StatusCode >= 500 {
		return fmt.Errorf("iyzico HTTP %d", resp.StatusCode)
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()
	if err := dec.Decode(out); err != nil {
		return fmt.Errorf("iyzico yanıtı çözülemedi (HTTP %d): %w", resp.StatusCode, err)
	}
	return nil
}

// Initialize, ödeme formunu başlatır.
func (c *Client) Initialize(ctx context.Context, r InitializeRequest) (*InitializeResponse, error) {
	if c == nil {
		return nil, ErrNotConfigured
	}
	r.Locale, r.Currency, r.CallbackURL = "tr", "TRY", c.CallbackURL
	if r.PaymentGroup == "" {
		r.PaymentGroup = "PRODUCT"
	}
	if len(r.EnabledInstallments) == 0 {
		r.EnabledInstallments = []int{1}
	}
	var out InitializeResponse
	if err := c.post(ctx, initializePath, r, &out); err != nil {
		return nil, err
	}
	if out.Status != "success" || out.Token == "" {
		return nil, &APIError{Code: out.ErrorCode, Message: out.ErrorMessage}
	}
	return &out, nil
}

// Retrieve, jetonla ödeme sonucunu sorgular.
func (c *Client) Retrieve(ctx context.Context, token, conversationID string) (*RetrieveResponse, error) {
	if c == nil {
		return nil, ErrNotConfigured
	}
	var out RetrieveResponse
	if err := c.post(ctx, retrievePath, map[string]string{"locale": "tr", "conversationId": conversationID, "token": token}, &out); err != nil {
		return nil, err
	}
	if out.Status != "success" {
		return nil, &APIError{Code: out.ErrorCode, Message: out.ErrorMessage}
	}
	return &out, nil
}

// Refund, ödemenin bir kısmını ya da tamamını karta iade eder. Sağlayıcının onayladığı tutar istenenle aynı değilse
// hata döner (iade tutarı sessizce farklı kabul edilmez).
func (c *Client) Refund(ctx context.Context, paymentID string, kurus int64, conversationID, ip string) (*RefundResponse, error) {
	if c == nil {
		return nil, ErrNotConfigured
	}
	var out RefundResponse
	if err := c.post(ctx, refundPath, map[string]string{"locale": "tr", "conversationId": conversationID, "paymentId": paymentID,
		"price": Price(kurus), "currency": "TRY", "ip": ip}, &out); err != nil {
		return nil, err
	}
	if out.Status != "success" {
		return nil, &APIError{Code: out.ErrorCode, Message: out.ErrorMessage}
	}
	if got, err := ParsePriceKurus(out.Price); err != nil || got != kurus {
		return nil, fmt.Errorf("iyzico iade tutarı uyuşmadı: istenen %d kuruş, yanıt %q", kurus, out.Price)
	}
	return &out, nil
}

// cardDeclineCodes: kartın/bankanın reddettiği işlemler (kullanıcı başka kartla deneyebilir).
// Bunların dışındaki başarısızlıklar sistem kaynaklı sayılır.
var cardDeclineCodes = map[string]string{
	"10005": "İşlem bankanız tarafından onaylanmadı.",
	"10012": "Geçersiz işlem; kartınız bu işleme kapalı olabilir.",
	"10041": "Kayıp kart; bankanızla görüşün.",
	"10043": "Çalıntı kart; bankanızla görüşün.",
	"10051": "Kartınızın limiti yetersiz.",
	"10054": "Kartın son kullanma tarihi hatalı.",
	"10057": "Kart sahibi bu işlemi yapamaz.",
	"10058": "Terminalin bu işlemi yapma yetkisi yok.",
	"10084": "CVC (güvenlik kodu) hatalı.",
	"10093": "Kartınız internetten alışverişe kapalı; bankanızdan açtırın.",
	"10201": "Kart işleme izin vermiyor.",
	"10202": "Ödeme işlemi esnasında genel bir hata oluştu.",
	"10204": "Ödeme işlemi esnasında genel bir hata oluştu.",
	"10206": "CVC uzunluğu geçersiz.",
	"10215": "Geçersiz kart numarası.",
	"10217": "3D Secure doğrulaması yapılmadan bu kartla ödeme yapılamaz.",
	"10219": "Bankaya gönderilen istek zaman aşımına uğradı.",
	"10227": "Kart numarası ya da son kullanma tarihi hatalı.",
	"10236": "Kart için 3D Secure doğrulaması başarısız.",
}

// systemCodes: sağlayıcı/banka tarafı geçici hataları (kullanıcının kusuru değildir).
var systemCodes = map[string]bool{"10202": true, "10204": true, "10219": true}

// Classify, başarısızlığı CARD (kart/banka reddi) ya da SYSTEM (geçici, kullanıcının kusuru değil)
// olarak sınıflar ve Türkçe kullanıcı mesajı döner. iyzico'nun kendi Türkçe mesajı varsa o kullanılır.
func Classify(code, providerMessage string) (kind, message string) {
	msg, known := cardDeclineCodes[code]
	if strings.TrimSpace(providerMessage) != "" {
		msg = providerMessage
	}
	if msg == "" {
		msg = "Ödeme tamamlanamadı."
	}
	if !known || systemCodes[code] {
		return "SYSTEM", msg
	}
	return "CARD", msg
}
