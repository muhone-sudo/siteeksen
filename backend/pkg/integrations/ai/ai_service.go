package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// ===============================================
// OpenAI Vision - Plaka Tanıma
// ===============================================

// OpenAIConfig OpenAI yapılandırması
type OpenAIConfig struct {
	APIKey  string `json:"api_key"`
	BaseURL string `json:"base_url"`
	Model   string `json:"model"`
}

// PlateRecognitionResult plaka tanıma sonucu
type PlateRecognitionResult struct {
	Plate       string    `json:"plate"`
	Confidence  float64   `json:"confidence"`
	VehicleType string    `json:"vehicle_type"`
	Color       string    `json:"color,omitempty"`
	ProcessedAt time.Time `json:"processed_at"`
}

// VisionService OpenAI Vision servisi
type VisionService struct {
	config     OpenAIConfig
	httpClient *http.Client
}

// NewVisionService yeni vision servisi oluşturur
func NewVisionService(config OpenAIConfig) *VisionService {
	if config.BaseURL == "" {
		config.BaseURL = "https://api.openai.com/v1"
	}
	if config.Model == "" {
		config.Model = "gpt-4o"
	}
	return &VisionService{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// RecognizePlate plaka tanır
func (v *VisionService) RecognizePlate(ctx context.Context, imageBase64 string) (*PlateRecognitionResult, error) {
	payload := map[string]interface{}{
		"model": v.config.Model,
		"messages": []map[string]interface{}{
			{
				"role": "user",
				"content": []map[string]interface{}{
					{
						"type": "text",
						"text": `Bu resimde bir araç plakası var. Lütfen şu bilgileri JSON formatında ver:
{
  "plate": "plaka numarası (boşluksuz, büyük harf)",
  "vehicle_type": "araba/motosiklet/kamyon/minibüs",
  "color": "aracın rengi"
}
Sadece JSON döndür, başka bir şey yazma.`,
					},
					{
						"type": "image_url",
						"image_url": map[string]string{
							"url": fmt.Sprintf("data:image/jpeg;base64,%s", imageBase64),
						},
					},
				},
			},
		},
		"max_tokens": 500,
	}

	jsonBody, _ := json.Marshal(payload)
	req, err := http.NewRequestWithContext(ctx, "POST", v.config.BaseURL+"/chat/completions", bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+v.config.APIKey)

	resp, err := v.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	var result map[string]interface{}
	json.Unmarshal(body, &result)

	// Parse response
	if choices, ok := result["choices"].([]interface{}); ok && len(choices) > 0 {
		if choice, ok := choices[0].(map[string]interface{}); ok {
			if message, ok := choice["message"].(map[string]interface{}); ok {
				if content, ok := message["content"].(string); ok {
					var plateInfo struct {
						Plate       string `json:"plate"`
						VehicleType string `json:"vehicle_type"`
						Color       string `json:"color"`
					}
					json.Unmarshal([]byte(content), &plateInfo)

					return &PlateRecognitionResult{
						Plate:       plateInfo.Plate,
						VehicleType: plateInfo.VehicleType,
						Color:       plateInfo.Color,
						Confidence:  0.95,
						ProcessedAt: time.Now(),
					}, nil
				}
			}
		}
	}

	return nil, fmt.Errorf("plaka tanınamadı")
}

// ===============================================
// Google Gemini - Akıllı Analiz
// ===============================================

// GeminiConfig Gemini yapılandırması
type GeminiConfig struct {
	APIKey  string `json:"api_key"`
	BaseURL string `json:"base_url"`
	Model   string `json:"model"`
}

// AnalysisResult analiz sonucu
type AnalysisResult struct {
	Summary         string       `json:"summary"`
	Insights        []string     `json:"insights"`
	Predictions     []Prediction `json:"predictions,omitempty"`
	Anomalies       []Anomaly    `json:"anomalies,omitempty"`
	Suggestions     []string     `json:"suggestions"`
	ConfidenceScore float64      `json:"confidence_score"`
	ProcessedAt     time.Time    `json:"processed_at"`
}

// Prediction tahmin
type Prediction struct {
	Category   string  `json:"category"`
	Value      float64 `json:"value"`
	Confidence float64 `json:"confidence"`
	Period     string  `json:"period"`
}

// Anomaly anomali
type Anomaly struct {
	Type       string  `json:"type"`
	Severity   string  `json:"severity"`
	Message    string  `json:"message"`
	Confidence float64 `json:"confidence"`
}

// GeminiService Gemini AI servisi
type GeminiService struct {
	config     GeminiConfig
	httpClient *http.Client
}

// NewGeminiService yeni Gemini servisi oluşturur
func NewGeminiService(config GeminiConfig) *GeminiService {
	if config.BaseURL == "" {
		config.BaseURL = "https://generativelanguage.googleapis.com/v1beta"
	}
	if config.Model == "" {
		config.Model = "gemini-2.0-flash"
	}
	return &GeminiService{
		config: config,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// AnalyzeExpenses gider analizi yapar
func (g *GeminiService) AnalyzeExpenses(ctx context.Context, expenses []map[string]interface{}) (*AnalysisResult, error) {
	expensesJSON, _ := json.Marshal(expenses)

	prompt := fmt.Sprintf(`Site yönetimi gider verilerini analiz et:
%s

Şu bilgileri JSON formatında ver:
{
  "summary": "genel özet",
  "insights": ["önemli bulgular listesi"],
  "predictions": [{"category": "kategori", "value": 1000, "confidence": 0.8, "period": "gelecek ay"}],
  "anomalies": [{"type": "tip", "severity": "high/medium/low", "message": "açıklama", "confidence": 0.9}],
  "suggestions": ["tasarruf önerileri listesi"]
}`, string(expensesJSON))

	return g.analyze(ctx, prompt)
}

// AnalyzeEnergy enerji tüketimi analizi yapar
func (g *GeminiService) AnalyzeEnergy(ctx context.Context, consumption []map[string]interface{}) (*AnalysisResult, error) {
	consumptionJSON, _ := json.Marshal(consumption)

	prompt := fmt.Sprintf(`Site enerji tüketim verilerini analiz et:
%s

Anomalileri tespit et, tasarruf önerileri sun ve gelecek tüketimi tahmin et.
JSON formatında yanıt ver.`, string(consumptionJSON))

	return g.analyze(ctx, prompt)
}

// AnalyzeCollectionRisk tahsilat risk analizi yapar
func (g *GeminiService) AnalyzeCollectionRisk(ctx context.Context, debtorData map[string]interface{}) (*AnalysisResult, error) {
	dataJSON, _ := json.Marshal(debtorData)

	prompt := fmt.Sprintf(`Aidat borçlusu risk analizi yap:
%s

Risk seviyesini belirle ve tahsilat stratejisi öner.
JSON formatında yanıt ver.`, string(dataJSON))

	return g.analyze(ctx, prompt)
}

// SummarizeMeeting toplantı özetler
func (g *GeminiService) SummarizeMeeting(ctx context.Context, transcript string) (*MeetingSummary, error) {
	prompt := fmt.Sprintf(`Toplantı transkriptini özetle:
%s

Şu bilgileri JSON formatında ver:
{
  "summary": "toplantı özeti",
  "decisions": ["alınan kararlar"],
  "action_items": [{"task": "görev", "assignee": "sorumlu", "due_date": "tarih"}],
  "key_points": ["önemli noktalar"]
}`, transcript)

	result, err := g.analyze(ctx, prompt)
	if err != nil {
		return nil, err
	}

	return &MeetingSummary{
		Summary:     result.Summary,
		Decisions:   result.Insights,
		KeyPoints:   result.Suggestions,
		ProcessedAt: result.ProcessedAt,
	}, nil
}

// MeetingSummary toplantı özeti
type MeetingSummary struct {
	Summary     string       `json:"summary"`
	Decisions   []string     `json:"decisions"`
	ActionItems []ActionItem `json:"action_items"`
	KeyPoints   []string     `json:"key_points"`
	ProcessedAt time.Time    `json:"processed_at"`
}

// ActionItem eylem kalemi
type ActionItem struct {
	Task     string `json:"task"`
	Assignee string `json:"assignee"`
	DueDate  string `json:"due_date"`
}

// analyze genel analiz fonksiyonu
func (g *GeminiService) analyze(ctx context.Context, prompt string) (*AnalysisResult, error) {
	payload := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]string{
					{"text": prompt},
				},
			},
		},
		"generationConfig": map[string]interface{}{
			"temperature":     0.7,
			"maxOutputTokens": 2000,
		},
	}

	jsonBody, _ := json.Marshal(payload)
	url := fmt.Sprintf("%s/models/%s:generateContent?key=%s", g.config.BaseURL, g.config.Model, g.config.APIKey)

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(jsonBody))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := g.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)

	var geminiResp map[string]interface{}
	json.Unmarshal(body, &geminiResp)

	// Parse Gemini response
	if candidates, ok := geminiResp["candidates"].([]interface{}); ok && len(candidates) > 0 {
		if candidate, ok := candidates[0].(map[string]interface{}); ok {
			if content, ok := candidate["content"].(map[string]interface{}); ok {
				if parts, ok := content["parts"].([]interface{}); ok && len(parts) > 0 {
					if part, ok := parts[0].(map[string]interface{}); ok {
						if text, ok := part["text"].(string); ok {
							var result AnalysisResult
							json.Unmarshal([]byte(text), &result)
							result.ProcessedAt = time.Now()
							return &result, nil
						}
					}
				}
			}
		}
	}

	return &AnalysisResult{
		Summary:     "Analiz tamamlanamadı",
		ProcessedAt: time.Now(),
	}, nil
}

// ===============================================
// Whisper API - Ses Transkripsiyon
// ===============================================

// TranscriptionResult transkripsiyon sonucu
type TranscriptionResult struct {
	Text        string    `json:"text"`
	Language    string    `json:"language"`
	Duration    float64   `json:"duration"`
	ProcessedAt time.Time `json:"processed_at"`
}

// WhisperService Whisper servisi
type WhisperService struct {
	config     OpenAIConfig
	httpClient *http.Client
}

// NewWhisperService yeni Whisper servisi oluşturur
func NewWhisperService(config OpenAIConfig) *WhisperService {
	if config.BaseURL == "" {
		config.BaseURL = "https://api.openai.com/v1"
	}
	return &WhisperService{
		config: config,
		httpClient: &http.Client{
			Timeout: 300 * time.Second,
		},
	}
}

// Transcribe ses dosyasını metne çevirir
func (w *WhisperService) Transcribe(ctx context.Context, audioData []byte, filename string) (*TranscriptionResult, error) {
	// Multipart form oluştur
	var body bytes.Buffer
	boundary := "----WebKitFormBoundary7MA4YWxkTrZu0gW"

	body.WriteString(fmt.Sprintf("--%s\r\n", boundary))
	body.WriteString(fmt.Sprintf("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n", filename))
	body.WriteString("Content-Type: audio/mpeg\r\n\r\n")
	body.Write(audioData)
	body.WriteString(fmt.Sprintf("\r\n--%s\r\n", boundary))
	body.WriteString("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
	body.WriteString("whisper-1")
	body.WriteString(fmt.Sprintf("\r\n--%s\r\n", boundary))
	body.WriteString("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
	body.WriteString("tr")
	body.WriteString(fmt.Sprintf("\r\n--%s--\r\n", boundary))

	req, err := http.NewRequestWithContext(ctx, "POST", w.config.BaseURL+"/audio/transcriptions", &body)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Authorization", "Bearer "+w.config.APIKey)
	req.Header.Set("Content-Type", fmt.Sprintf("multipart/form-data; boundary=%s", boundary))

	resp, err := w.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	var result map[string]interface{}
	json.Unmarshal(respBody, &result)

	return &TranscriptionResult{
		Text:        fmt.Sprintf("%v", result["text"]),
		Language:    "tr",
		ProcessedAt: time.Now(),
	}, nil
}
