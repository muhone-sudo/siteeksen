package notify

// Netgsm SMS sağlayıcısı (TEST_RAPORU 2.4).
//
// REST v2: POST {NETGSM_API_URL}/sms/rest/v2/send, HTTP Basic (kullanıcı kodu + API
// şifresi), gövde {msgheader, messages:[{msg,no}], encoding, iysfilter}. Başarılı
// yanıt {"code":"00","jobid":"…"}; diğer kodlar hatadır ve açıklamasıyla döner.
// Kaynak: Netgsm resmi Python SDK'sı (netgsm/netgsm-sms-python, sms_service.py).
//
// Yalnızca İŞLEMSEL ileti (aktivasyon kodu, acil duyuru, hatırlatma) gönderilir:
// iysfilter "0". Ticari ileti İYS kaydı ister (6563 s. Kanun, Ticari İletişim ve
// Ticari Elektronik İletiler Hakkında Yönetmelik); Notifier zaten onaysız ticari
// iletiyi SUPPRESSED yapar, bu sağlayıcı ticari iletiyi ayrıca reddeder.

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// DefaultNetgsmURL, Netgsm API kökü.
const DefaultNetgsmURL = "https://api.netgsm.com.tr"

// NetgsmSender, SMS kanalını Netgsm üzerinden gönderir.
type NetgsmSender struct {
	BaseURL  string
	UserCode string
	Password string
	Header   string // onaylı gönderici başlığı (msgheader)
	Client   *http.Client
}

// NetgsmFromEnv, NETGSM_USERCODE / NETGSM_PASSWORD / NETGSM_MSGHEADER ile kurar; eksikse nil.
func NetgsmFromEnv() (*NetgsmSender, error) {
	user := strings.TrimSpace(os.Getenv("NETGSM_USERCODE"))
	pass := os.Getenv("NETGSM_PASSWORD")
	header := strings.TrimSpace(os.Getenv("NETGSM_MSGHEADER"))
	if user == "" && pass == "" && header == "" {
		return nil, nil
	}
	if user == "" || pass == "" || header == "" {
		return nil, errors.New("Netgsm için NETGSM_USERCODE, NETGSM_PASSWORD ve NETGSM_MSGHEADER birlikte verilmeli")
	}
	base := strings.TrimRight(strings.TrimSpace(os.Getenv("NETGSM_API_URL")), "/")
	if base == "" {
		base = DefaultNetgsmURL
	}
	return &NetgsmSender{BaseURL: base, UserCode: user, Password: pass, Header: header,
		Client: &http.Client{Timeout: 20 * time.Second}}, nil
}

func (s *NetgsmSender) Name() string { return "netgsm" }

func (s *NetgsmSender) Supports(channel string) bool { return channel == ChannelSMS }

// NormalizePhoneTR, numarayı Netgsm'in beklediği biçime getirir: yurt içi 5XXXXXXXXX,
// yurt dışı 00 ile başlayan uluslararası biçim. Geçersizse boş döner.
func NormalizePhoneTR(p string) string {
	d := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, p)
	plus := strings.HasPrefix(strings.TrimSpace(p), "+")
	switch {
	case plus && strings.HasPrefix(d, "90") && len(d) == 12:
		return d[2:]
	case plus && len(d) >= 8 && len(d) <= 15:
		return "00" + d
	case strings.HasPrefix(d, "0090") && len(d) == 14:
		return d[4:]
	case strings.HasPrefix(d, "00") && len(d) >= 10:
		return d
	case strings.HasPrefix(d, "90") && len(d) == 12:
		return d[2:]
	case strings.HasPrefix(d, "0") && len(d) == 11:
		return d[1:]
	case len(d) == 10 && strings.HasPrefix(d, "5"):
		return d
	}
	return ""
}

type netgsmRequest struct {
	MsgHeader string          `json:"msgheader"`
	Messages  []netgsmMessage `json:"messages"`
	Encoding  string          `json:"encoding"`
	IYSFilter string          `json:"iysfilter"`
}

type netgsmMessage struct {
	Msg string `json:"msg"`
	No  string `json:"no"`
}

// netgsmErrors, Netgsm sonuç kodlarının açıklamaları (SDK hata tablosu).
var netgsmErrors = map[string]string{
	"20": "mesaj metni hatalı ya da azami uzunluğu aşıyor",
	"30": "geçersiz kullanıcı adı/şifre ya da API erişim izni yok (IP kısıtı)",
	"40": "gönderici başlığı (msgheader) sistemde tanımlı değil",
	"50": "İYS kontrollü gönderimde hata",
	"51": "İYS marka bilgisi bulunamadı",
	"70": "hatalı sorgu: parametrelerden biri hatalı ya da eksik",
	"80": "gönderim sınırı aşıldı",
	"85": "mükerrer gönderim sınırı aşıldı (aynı numaraya kısa sürede aynı ileti)",
}

func (s *NetgsmSender) Send(ctx context.Context, m Message) (string, error) {
	if m.Category == CategoryCommercial {
		return "", errors.New("ticari SMS bu sağlayıcıyla gönderilmez (İYS kaydı gerekir)")
	}
	no := NormalizePhoneTR(m.Recipient)
	if no == "" {
		return "", fmt.Errorf("telefon numarası geçersiz: %s", maskRecipient(m.Recipient))
	}
	body, err := json.Marshal(netgsmRequest{MsgHeader: s.Header, Encoding: "TR", IYSFilter: "0",
		Messages: []netgsmMessage{{Msg: m.Body, No: no}}})
	if err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, s.BaseURL+"/sms/rest/v2/send", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.SetBasicAuth(s.UserCode, s.Password)
	req.Header.Set("Content-Type", "application/json")
	client := s.Client
	if client == nil {
		client = &http.Client{Timeout: 20 * time.Second}
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("Netgsm'e ulaşılamadı: %w", err)
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	var out struct {
		Code        string `json:"code"`
		JobID       string `json:"jobid"`
		Description string `json:"description"`
	}
	if jerr := json.Unmarshal(raw, &out); jerr != nil || resp.StatusCode >= 300 {
		return "", fmt.Errorf("Netgsm yanıtı beklenmedik (HTTP %d): %s", resp.StatusCode, truncate(string(raw), 120))
	}
	if out.Code != "00" {
		why := netgsmErrors[out.Code]
		if why == "" {
			why = out.Description
		}
		return "", fmt.Errorf("Netgsm %s: %s", out.Code, why)
	}
	return out.JobID, nil
}
