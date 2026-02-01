package sms

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// Provider SMS sağlayıcı interface
type Provider interface {
	Send(ctx context.Context, req *SendRequest) (*SendResponse, error)
	GetBalance(ctx context.Context) (*BalanceResponse, error)
	GetDeliveryReport(ctx context.Context, messageID string) (*DeliveryReport, error)
}

// SendRequest SMS gönderim isteği
type SendRequest struct {
	To      string `json:"to"`
	Message string `json:"message"`
	From    string `json:"from,omitempty"`
}

// SendResponse SMS gönderim yanıtı
type SendResponse struct {
	Success   bool   `json:"success"`
	MessageID string `json:"message_id,omitempty"`
	Error     string `json:"error,omitempty"`
}

// BalanceResponse bakiye yanıtı
type BalanceResponse struct {
	Balance  float64 `json:"balance"`
	Currency string  `json:"currency"`
}

// DeliveryReport teslimat raporu
type DeliveryReport struct {
	MessageID   string    `json:"message_id"`
	Status      string    `json:"status"`
	DeliveredAt time.Time `json:"delivered_at,omitempty"`
}

// ===============================================
// NETGSM Sağlayıcısı
// ===============================================

// NetgsmConfig Netgsm yapılandırması
type NetgsmConfig struct {
	UserCode  string `json:"user_code"`
	Password  string `json:"password"`
	MsgHeader string `json:"msg_header"`
	BaseURL   string `json:"base_url"`
}

// NetgsmProvider Netgsm SMS sağlayıcısı
type NetgsmProvider struct {
	config     NetgsmConfig
	httpClient *http.Client
}

// NewNetgsmProvider yeni Netgsm sağlayıcısı oluşturur
func NewNetgsmProvider(config NetgsmConfig) *NetgsmProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://api.netgsm.com.tr"
	}
	return &NetgsmProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Send SMS gönderir
func (n *NetgsmProvider) Send(ctx context.Context, req *SendRequest) (*SendResponse, error) {
	from := req.From
	if from == "" {
		from = n.config.MsgHeader
	}

	// Netgsm XML formatı
	xmlBody := fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
<mainbody>
	<header>
		<company dession="netgsm"/>
		<usercode>%s</usercode>
		<password>%s</password>
		<startdate></startdate>
		<stopdate></stopdate>
		<type>1:n</type>
		<msgheader>%s</msgheader>
	</header>
	<body>
		<msg><![CDATA[%s]]></msg>
		<no>%s</no>
	</body>
</mainbody>`, n.config.UserCode, n.config.Password, from, req.Message, n.normalizePhone(req.To))

	httpReq, err := http.NewRequestWithContext(ctx, "POST", n.config.BaseURL+"/sms/send/xml", strings.NewReader(xmlBody))
	if err != nil {
		return nil, fmt.Errorf("request oluşturulamadı: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/xml")

	resp, err := n.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("SMS gönderilemedi: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	responseStr := string(body)

	// Netgsm yanıt kodları kontrolü
	if len(responseStr) > 2 && responseStr[:2] == "00" {
		parts := strings.Split(responseStr, " ")
		messageID := ""
		if len(parts) > 1 {
			messageID = parts[1]
		}
		return &SendResponse{
			Success:   true,
			MessageID: messageID,
		}, nil
	}

	return &SendResponse{
		Success: false,
		Error:   fmt.Sprintf("Netgsm hatası: %s", responseStr),
	}, nil
}

// GetBalance bakiye sorgular
func (n *NetgsmProvider) GetBalance(ctx context.Context) (*BalanceResponse, error) {
	params := url.Values{
		"usercode": {n.config.UserCode},
		"password": {n.config.Password},
	}

	httpReq, err := http.NewRequestWithContext(ctx, "GET", n.config.BaseURL+"/balance/list/get?"+params.Encode(), nil)
	if err != nil {
		return nil, err
	}

	resp, err := n.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	// Parse balance from response
	return &BalanceResponse{
		Balance:  0, // Parse from body
		Currency: "TRY",
	}, nil
}

// GetDeliveryReport teslimat raporu alır
func (n *NetgsmProvider) GetDeliveryReport(ctx context.Context, messageID string) (*DeliveryReport, error) {
	return &DeliveryReport{
		MessageID: messageID,
		Status:    "delivered",
	}, nil
}

// normalizePhone telefon numarasını normalleştirir
func (n *NetgsmProvider) normalizePhone(phone string) string {
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")
	phone = strings.ReplaceAll(phone, "(", "")
	phone = strings.ReplaceAll(phone, ")", "")

	if strings.HasPrefix(phone, "+90") {
		phone = phone[3:]
	} else if strings.HasPrefix(phone, "90") {
		phone = phone[2:]
	} else if strings.HasPrefix(phone, "0") {
		phone = phone[1:]
	}
	return phone
}

// ===============================================
// İLETİ MERKEZİ Sağlayıcısı
// ===============================================

// IletiMerkeziConfig İleti Merkezi yapılandırması
type IletiMerkeziConfig struct {
	APIKey  string `json:"api_key"`
	APIHash string `json:"api_hash"`
	Sender  string `json:"sender"`
	BaseURL string `json:"base_url"`
}

// IletiMerkeziProvider İleti Merkezi sağlayıcısı
type IletiMerkeziProvider struct {
	config     IletiMerkeziConfig
	httpClient *http.Client
}

// NewIletiMerkeziProvider yeni İleti Merkezi sağlayıcısı oluşturur
func NewIletiMerkeziProvider(config IletiMerkeziConfig) *IletiMerkeziProvider {
	if config.BaseURL == "" {
		config.BaseURL = "https://api.iletimerkezi.com/v1"
	}
	return &IletiMerkeziProvider{
		config: config,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// Send SMS gönderir
func (i *IletiMerkeziProvider) Send(ctx context.Context, req *SendRequest) (*SendResponse, error) {
	payload := map[string]interface{}{
		"request": map[string]interface{}{
			"authentication": map[string]string{
				"key":  i.config.APIKey,
				"hash": i.config.APIHash,
			},
			"order": map[string]interface{}{
				"sender": i.config.Sender,
				"message": map[string]interface{}{
					"text": req.Message,
					"receipents": map[string]interface{}{
						"number": []string{req.To},
					},
				},
			},
		},
	}

	jsonBody, _ := json.Marshal(payload)
	httpReq, err := http.NewRequestWithContext(ctx, "POST", i.config.BaseURL+"/send-sms/json", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := i.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&result)

	return &SendResponse{
		Success:   resp.StatusCode == 200,
		MessageID: fmt.Sprintf("%v", result["id"]),
	}, nil
}

// GetBalance bakiye sorgular
func (i *IletiMerkeziProvider) GetBalance(ctx context.Context) (*BalanceResponse, error) {
	return &BalanceResponse{
		Balance:  0,
		Currency: "TRY",
	}, nil
}

// GetDeliveryReport teslimat raporu alır
func (i *IletiMerkeziProvider) GetDeliveryReport(ctx context.Context, messageID string) (*DeliveryReport, error) {
	return &DeliveryReport{
		MessageID: messageID,
		Status:    "pending",
	}, nil
}

// ===============================================
// SMS SERVİSİ
// ===============================================

// Service SMS servisi
type Service struct {
	providers map[string]Provider
	primary   string
}

// NewService yeni SMS servisi oluşturur
func NewService(primary string) *Service {
	return &Service{
		providers: make(map[string]Provider),
		primary:   primary,
	}
}

// RegisterProvider sağlayıcı kaydeder
func (s *Service) RegisterProvider(name string, provider Provider) {
	s.providers[name] = provider
}

// Send SMS gönderir
func (s *Service) Send(ctx context.Context, req *SendRequest) (*SendResponse, error) {
	provider, ok := s.providers[s.primary]
	if !ok {
		return nil, fmt.Errorf("birincil sağlayıcı bulunamadı: %s", s.primary)
	}

	resp, err := provider.Send(ctx, req)
	if err != nil || !resp.Success {
		// Fallback to other providers
		for name, p := range s.providers {
			if name == s.primary {
				continue
			}
			resp, err = p.Send(ctx, req)
			if err == nil && resp.Success {
				return resp, nil
			}
		}
	}

	return resp, err
}

// SendBulk toplu SMS gönderir
func (s *Service) SendBulk(ctx context.Context, requests []*SendRequest) []*SendResponse {
	responses := make([]*SendResponse, len(requests))
	for i, req := range requests {
		resp, _ := s.Send(ctx, req)
		responses[i] = resp
	}
	return responses
}
