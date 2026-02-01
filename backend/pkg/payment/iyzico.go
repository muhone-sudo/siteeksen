package payment

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

// IyzicoClient - iyzico ödeme gateway client
type IyzicoClient struct {
	apiKey    string
	secretKey string
	baseURL   string
}

// NewIyzicoClient - yeni iyzico client oluştur
func NewIyzicoClient() *IyzicoClient {
	baseURL := os.Getenv("IYZICO_BASE_URL")
	if baseURL == "" {
		baseURL = "https://sandbox-api.iyzipay.com" // Sandbox varsayılan
	}

	return &IyzicoClient{
		apiKey:    os.Getenv("IYZICO_API_KEY"),
		secretKey: os.Getenv("IYZICO_SECRET_KEY"),
		baseURL:   baseURL,
	}
}

// PaymentRequest - ödeme isteği
type PaymentRequest struct {
	Price           string         `json:"price"`
	PaidPrice       string         `json:"paidPrice"`
	Currency        string         `json:"currency"`
	Installment     int            `json:"installment"`
	BasketID        string         `json:"basketId"`
	PaymentCard     *PaymentCard   `json:"paymentCard"`
	Buyer           *Buyer         `json:"buyer"`
	ShippingAddress *Address       `json:"shippingAddress"`
	BillingAddress  *Address       `json:"billingAddress"`
	BasketItems     []BasketItem   `json:"basketItems"`
	CallbackURL     string         `json:"callbackUrl,omitempty"`
}

type PaymentCard struct {
	CardHolderName string `json:"cardHolderName"`
	CardNumber     string `json:"cardNumber"`
	ExpireMonth    string `json:"expireMonth"`
	ExpireYear     string `json:"expireYear"`
	Cvc            string `json:"cvc"`
	RegisterCard   int    `json:"registerCard,omitempty"`
	CardToken      string `json:"cardToken,omitempty"`
	CardUserKey    string `json:"cardUserKey,omitempty"`
}

type Buyer struct {
	ID                  string `json:"id"`
	Name                string `json:"name"`
	Surname             string `json:"surname"`
	GsmNumber           string `json:"gsmNumber"`
	Email               string `json:"email"`
	IdentityNumber      string `json:"identityNumber"`
	RegistrationAddress string `json:"registrationAddress"`
	IP                  string `json:"ip"`
	City                string `json:"city"`
	Country             string `json:"country"`
}

type Address struct {
	ContactName string `json:"contactName"`
	City        string `json:"city"`
	Country     string `json:"country"`
	Address     string `json:"address"`
}

type BasketItem struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Category1 string `json:"category1"`
	ItemType  string `json:"itemType"`
	Price     string `json:"price"`
}

// PaymentResponse - ödeme yanıtı
type PaymentResponse struct {
	Status              string  `json:"status"`
	ErrorCode           string  `json:"errorCode,omitempty"`
	ErrorMessage        string  `json:"errorMessage,omitempty"`
	PaymentID           string  `json:"paymentId,omitempty"`
	Price               float64 `json:"price,omitempty"`
	PaidPrice           float64 `json:"paidPrice,omitempty"`
	Currency            string  `json:"currency,omitempty"`
	Installment         int     `json:"installment,omitempty"`
	PaymentTransactionID string `json:"paymentTransactionId,omitempty"`
	CardToken           string  `json:"cardToken,omitempty"`
	CardUserKey         string  `json:"cardUserKey,omitempty"`
}

// ThreeDSInitRequest - 3D Secure başlatma
type ThreeDSInitRequest struct {
	PaymentRequest
	CallbackURL string `json:"callbackUrl"`
}

// ThreeDSInitResponse - 3D Secure başlatma yanıtı
type ThreeDSInitResponse struct {
	Status            string `json:"status"`
	ErrorCode         string `json:"errorCode,omitempty"`
	ErrorMessage      string `json:"errorMessage,omitempty"`
	ThreeDSHtmlContent string `json:"threeDSHtmlContent,omitempty"`
}

// CreatePayment - direkt ödeme (3D'siz)
func (c *IyzicoClient) CreatePayment(req *PaymentRequest) (*PaymentResponse, error) {
	return c.makeRequest("/payment/auth", req)
}

// Create3DSPayment - 3D Secure ile ödeme başlat
func (c *IyzicoClient) Create3DSPayment(req *ThreeDSInitRequest) (*ThreeDSInitResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequest("POST", c.baseURL+"/payment/3dsecure/initialize", bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	c.setHeaders(httpReq, body)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result ThreeDSInitResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

// Complete3DSPayment - 3D Secure tamamlama
func (c *IyzicoClient) Complete3DSPayment(paymentID string) (*PaymentResponse, error) {
	req := map[string]string{"paymentId": paymentID}
	return c.makeRequest("/payment/3dsecure/auth", req)
}

// CreateCardToken - kart tokenize et
func (c *IyzicoClient) CreateCardToken(card *PaymentCard, email string) (*CardTokenResponse, error) {
	req := map[string]interface{}{
		"card":  card,
		"email": email,
	}

	body, _ := json.Marshal(req)
	httpReq, _ := http.NewRequest("POST", c.baseURL+"/cardstorage/card", bytes.NewBuffer(body))
	c.setHeaders(httpReq, body)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result CardTokenResponse
	json.NewDecoder(resp.Body).Decode(&result)
	return &result, nil
}

type CardTokenResponse struct {
	Status       string `json:"status"`
	CardToken    string `json:"cardToken"`
	CardUserKey  string `json:"cardUserKey"`
	CardAlias    string `json:"cardAlias"`
	BinNumber    string `json:"binNumber"`
	LastFourDigits string `json:"lastFourDigits"`
	CardType     string `json:"cardType"`
}

// Refund - iade işlemi
func (c *IyzicoClient) Refund(paymentTransactionID string, price string) (*RefundResponse, error) {
	req := map[string]string{
		"paymentTransactionId": paymentTransactionID,
		"price":                price,
		"currency":             "TRY",
	}

	body, _ := json.Marshal(req)
	httpReq, _ := http.NewRequest("POST", c.baseURL+"/payment/refund", bytes.NewBuffer(body))
	c.setHeaders(httpReq, body)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result RefundResponse
	json.NewDecoder(resp.Body).Decode(&result)
	return &result, nil
}

type RefundResponse struct {
	Status       string  `json:"status"`
	PaymentID    string  `json:"paymentId"`
	Price        float64 `json:"price"`
	ErrorCode    string  `json:"errorCode,omitempty"`
	ErrorMessage string  `json:"errorMessage,omitempty"`
}

func (c *IyzicoClient) makeRequest(endpoint string, data interface{}) (*PaymentResponse, error) {
	body, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", c.baseURL+endpoint, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	c.setHeaders(req, body)

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result PaymentResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

func (c *IyzicoClient) setHeaders(req *http.Request, body []byte) {
	randomString := fmt.Sprintf("%d", time.Now().UnixNano())

	// iyzico authorization header oluştur
	hashString := c.apiKey + randomString + c.secretKey + string(body)
	hash := hmac.New(sha256.New, []byte(c.secretKey))
	hash.Write([]byte(hashString))
	signature := base64.StdEncoding.EncodeToString(hash.Sum(nil))

	authorizationString := fmt.Sprintf("IYZWS %s:%s", c.apiKey, signature)

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authorizationString)
	req.Header.Set("x-iyzi-rnd", randomString)
}
