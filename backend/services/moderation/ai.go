package main

// Yapay zekâ ile görsel denetimi (FAZ M13.4). Sağlayıcıyı platform seçer: Anthropic Messages API ya da OpenAI uyumlu
// sohbet API'si (Ollama, LM Studio, vLLM gibi yerel sunucular ya da SaaS). Kimlik: API anahtarı, kullanıcı adı/parola
// (Basic) ya da yok. Yanıt yalnız {unsafe, categories, reason} JSON'udur; okunamazsa hata sayılır ve fotoğraf
// platformun elle onay kuyruğuna düşer (sessiz onay yok).
//
// Anthropic çağrısı ham HTTP ile yapılır: resmî Go SDK'sı (v2) Go 1.25 istiyor; proje ve dağıtım imajları Go 1.24'te.

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// AISettings, platformun yapay zekâ sağlayıcı ayarıdır (gizli değerler çözülmüş hâlde).
type AISettings struct {
	Enabled  bool
	Provider string // ANTHROPIC | OPENAI
	BaseURL  string
	Model    string
	AuthType string // API_KEY | BASIC | NONE
	APIKey   string
	Username string
	Password string
}

// Verdict, yapay zekânın kararıdır.
type Verdict struct {
	Unsafe     bool     `json:"unsafe"`
	Categories []string `json:"categories"`
	Reason     string   `json:"reason"`
}

// Categories, sakıncalı içerik sınıflarıdır (istem ve JSON şeması aynı listeyi kullanır).
var Categories = []string{"NUDITY", "SEXUAL", "VIOLENCE", "GORE", "HATE", "WEAPONS", "DRUGS", "SELF_HARM",
	"CONTACT_INFO", "PERSONAL_DATA", "OTHER"}

const moderationPrompt = `You review a photo uploaded to a Turkish home-services marketplace (service listings of tradespeople and job requests of apartment residents). Decide whether the photo may be shown to other users.

Mark it unsafe and list every matching category if it shows any of:
- NUDITY or SEXUAL content
- VIOLENCE or GORE
- HATE: hate symbols, slurs, extremist propaganda
- WEAPONS or DRUGS
- SELF_HARM
- CONTACT_INFO: a phone number, e-mail address, website, social media handle, QR code, or a messaging app logo with a number (contact details let users bypass the marketplace)
- PERSONAL_DATA: identity cards, documents showing someone's personal data, readable licence plates
- OTHER: anything else clearly inappropriate for a public marketplace

Ordinary work photos are fine: tools, pipes, wiring, rooms, appliances, materials, finished work, shop fronts or vehicles without readable contact details.

Answer only with JSON: {"unsafe": true|false, "categories": [...], "reason": "one short sentence in Turkish"}.`

var verdictSchema = map[string]any{
	"type": "object",
	"properties": map[string]any{
		"unsafe":     map[string]any{"type": "boolean"},
		"categories": map[string]any{"type": "array", "items": map[string]any{"type": "string", "enum": Categories}},
		"reason":     map[string]any{"type": "string"},
	},
	"required":             []string{"unsafe", "categories", "reason"},
	"additionalProperties": false,
}

// ErrRefused: sağlayıcı görseli değerlendirmeyi reddetti (kendi güvenlik sınıflandırıcısı). Fotoğraf elle onaya gider.
var ErrRefused = errors.New("sağlayıcı görseli değerlendirmeyi reddetti")

// AIClient, sağlayıcıya HTTP ile bağlanır.
type AIClient struct{ HTTP *http.Client }

func newAIClient() *AIClient { return &AIClient{HTTP: &http.Client{Timeout: 90 * time.Second}} }

func (s AISettings) authorize(req *http.Request) {
	switch s.AuthType {
	case "API_KEY":
		if s.Provider == "ANTHROPIC" {
			req.Header.Set("x-api-key", s.APIKey)
		} else {
			req.Header.Set("Authorization", "Bearer "+s.APIKey)
		}
	case "BASIC":
		req.SetBasicAuth(s.Username, s.Password)
	}
}

// Classify, görseli sağlayıcıya sorar.
func (c *AIClient) Classify(ctx context.Context, s AISettings, image []byte, contentType string) (*Verdict, error) {
	if s.Model == "" || s.BaseURL == "" {
		return nil, errors.New("yapay zekâ ayarı eksik: adres ve model zorunlu")
	}
	b64 := base64.StdEncoding.EncodeToString(image)
	var body any
	var url string
	if s.Provider == "ANTHROPIC" {
		url = strings.TrimRight(s.BaseURL, "/") + "/v1/messages"
		body = map[string]any{
			"model":      s.Model,
			"max_tokens": 4096,
			// Sınıflandırma basit bir iş: düşük çaba yeterli; yanıt JSON şemasıyla sınırlanır.
			"output_config": map[string]any{"effort": "low", "format": map[string]any{"type": "json_schema", "schema": verdictSchema}},
			"messages": []any{map[string]any{"role": "user", "content": []any{
				map[string]any{"type": "image", "source": map[string]any{"type": "base64", "media_type": contentType, "data": b64}},
				map[string]any{"type": "text", "text": moderationPrompt},
			}}},
		}
	} else {
		url = strings.TrimRight(s.BaseURL, "/") + "/chat/completions"
		body = map[string]any{
			"model": s.Model,
			"messages": []any{map[string]any{"role": "user", "content": []any{
				map[string]any{"type": "text", "text": moderationPrompt},
				map[string]any{"type": "image_url", "image_url": map[string]any{"url": "data:" + contentType + ";base64," + b64}},
			}}},
		}
	}
	raw, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(raw))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	if s.Provider == "ANTHROPIC" {
		req.Header.Set("anthropic-version", "2026-10-21")
	}
	s.authorize(req)
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, fmt.Errorf("sağlayıcıya ulaşılamadı: %w", err)
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(io.LimitReader(resp.Body, 2<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 300 {
		return nil, fmt.Errorf("sağlayıcı HTTP %d: %s", resp.StatusCode, snippet(data))
	}
	text, err := responseText(s.Provider, data)
	if err != nil {
		return nil, err
	}
	return parseVerdict(text)
}

func responseText(provider string, data []byte) (string, error) {
	if provider == "ANTHROPIC" {
		var r struct {
			StopReason string `json:"stop_reason"`
			Content    []struct {
				Type string `json:"type"`
				Text string `json:"text"`
			} `json:"content"`
		}
		if err := json.Unmarshal(data, &r); err != nil {
			return "", fmt.Errorf("sağlayıcı yanıtı okunamadı: %w", err)
		}
		if r.StopReason == "refusal" {
			return "", ErrRefused
		}
		for _, b := range r.Content {
			if b.Type == "text" && strings.TrimSpace(b.Text) != "" {
				return b.Text, nil
			}
		}
		return "", fmt.Errorf("sağlayıcı yanıtında metin yok (stop_reason %s)", r.StopReason)
	}
	var r struct {
		Choices []struct {
			FinishReason string `json:"finish_reason"`
			Message      struct {
				Content string `json:"content"`
				Refusal string `json:"refusal"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(data, &r); err != nil {
		return "", fmt.Errorf("sağlayıcı yanıtı okunamadı: %w", err)
	}
	if len(r.Choices) == 0 {
		return "", errors.New("sağlayıcı yanıtında seçenek yok")
	}
	if r.Choices[0].Message.Refusal != "" || r.Choices[0].FinishReason == "content_filter" {
		return "", ErrRefused
	}
	return r.Choices[0].Message.Content, nil
}

// parseVerdict, yanıttaki JSON nesnesini okur (yerel modeller JSON'u metin içine gömebilir).
func parseVerdict(text string) (*Verdict, error) {
	i, j := strings.IndexByte(text, '{'), strings.LastIndexByte(text, '}')
	if i < 0 || j <= i {
		return nil, fmt.Errorf("yanıtta JSON yok: %s", snippet([]byte(text)))
	}
	var v struct {
		Unsafe     *bool    `json:"unsafe"`
		Categories []string `json:"categories"`
		Reason     string   `json:"reason"`
	}
	if err := json.Unmarshal([]byte(text[i:j+1]), &v); err != nil || v.Unsafe == nil {
		return nil, fmt.Errorf("yanıt beklenen biçimde değil: %s", snippet([]byte(text)))
	}
	out := &Verdict{Unsafe: *v.Unsafe, Reason: strings.TrimSpace(v.Reason), Categories: []string{}}
	for _, c := range v.Categories {
		if c = strings.ToUpper(strings.TrimSpace(c)); c != "" {
			out.Categories = append(out.Categories, c)
		}
	}
	// Kategori bildirip "unsafe: false" diyen yanıt temiz sayılmaz.
	if len(out.Categories) > 0 {
		out.Unsafe = true
	}
	return out, nil
}

func snippet(b []byte) string {
	s := strings.TrimSpace(string(b))
	if len(s) > 300 {
		s = s[:300] + "…"
	}
	return s
}
