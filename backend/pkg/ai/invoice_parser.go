package ai

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// InvoiceData - Faturadan çıkarılan veriler
type InvoiceData struct {
	VendorName      string                 `json:"vendor_name"`
	VendorTaxID     string                 `json:"vendor_tax_id,omitempty"`
	InvoiceNumber   string                 `json:"invoice_number"`
	InvoiceDate     string                 `json:"invoice_date"`
	DueDate         string                 `json:"due_date,omitempty"`
	TotalAmount     float64                `json:"total_amount"`
	Currency        string                 `json:"currency"`
	TaxAmount       float64                `json:"tax_amount,omitempty"`
	SubTotal        float64                `json:"sub_total,omitempty"`
	CategorySuggest string                 `json:"category_suggestion"`
	LineItems       []LineItem             `json:"line_items,omitempty"`
	RawText         string                 `json:"raw_text,omitempty"`
	Metadata        map[string]interface{} `json:"metadata,omitempty"`
}

// LineItem - Fatura kalemi
type LineItem struct {
	Description string  `json:"description"`
	Quantity    float64 `json:"quantity,omitempty"`
	UnitPrice   float64 `json:"unit_price,omitempty"`
	Amount      float64 `json:"amount"`
}

// ScanResult - AI tarama sonucu
type ScanResult struct {
	Success    bool        `json:"success"`
	Data       InvoiceData `json:"data,omitempty"`
	Confidence float64     `json:"confidence_score"`
	Error      string      `json:"error,omitempty"`
	ProcessedAt time.Time  `json:"processed_at"`
}

// InvoiceParser - Fatura okuyucu servis
type InvoiceParser struct {
	openAIKey     string
	googleAIKey   string
	preferredAI   string // "openai" veya "google"
}

// NewInvoiceParser - Yeni parser oluştur
func NewInvoiceParser() *InvoiceParser {
	return &InvoiceParser{
		openAIKey:   os.Getenv("OPENAI_API_KEY"),
		googleAIKey: os.Getenv("GOOGLE_AI_KEY"),
		preferredAI: os.Getenv("PREFERRED_AI"), // default openai
	}
}

// ParseInvoice - Fatura dosyasını analiz et
func (p *InvoiceParser) ParseInvoice(ctx context.Context, fileData []byte, fileType string) (*ScanResult, error) {
	// PDF için önce görüntüye dönüştür veya text çıkar
	if strings.ToLower(fileType) == "pdf" {
		return p.parsePDF(ctx, fileData)
	}
	
	// Görüntü dosyaları için direkt AI Vision kullan
	return p.parseImage(ctx, fileData, fileType)
}

// parseImage - Görüntü dosyasını AI ile analiz et
func (p *InvoiceParser) parseImage(ctx context.Context, imageData []byte, fileType string) (*ScanResult, error) {
	// Base64 encode
	base64Image := base64.StdEncoding.EncodeToString(imageData)
	
	// OpenAI GPT-4 Vision API çağrısı
	if p.openAIKey != "" {
		return p.callOpenAIVision(ctx, base64Image, fileType)
	}
	
	// Google Document AI fallback
	if p.googleAIKey != "" {
		return p.callGoogleDocumentAI(ctx, imageData)
	}
	
	return &ScanResult{
		Success: false,
		Error:   "AI servis anahtarı yapılandırılmamış",
	}, nil
}

// callOpenAIVision - OpenAI GPT-4 Vision ile fatura okuma
func (p *InvoiceParser) callOpenAIVision(ctx context.Context, base64Image, fileType string) (*ScanResult, error) {
	prompt := `Bu bir fatura/fiş görüntüsüdür. Lütfen aşağıdaki bilgileri JSON formatında çıkar:
1. vendor_name: Firma/kurum adı
2. vendor_tax_id: Vergi numarası (varsa)
3. invoice_number: Fatura numarası
4. invoice_date: Fatura tarihi (YYYY-MM-DD formatında)
5. total_amount: Toplam tutar (sayı olarak)
6. currency: Para birimi (TRY, USD, EUR)
7. tax_amount: KDV tutarı (varsa)
8. category_suggestion: Bu fatura hangi gider kategorisine ait olabilir? (Ortak Elektrik, Ortak Su, Ortak Isınma, Asansör Bakımı, Bahçe Bakımı, Bina Temizliği, Güvenlik, Acil Tamir, Diğer)
9. line_items: Fatura kalemleri listesi (varsa)

Sadece JSON döndür, başka açıklama ekleme.`

	mediaType := "image/jpeg"
	if fileType == "PNG" {
		mediaType = "image/png"
	}

	requestBody := map[string]interface{}{
		"model": "gpt-4-vision-preview",
		"messages": []map[string]interface{}{
			{
				"role": "user",
				"content": []map[string]interface{}{
					{"type": "text", "text": prompt},
					{
						"type": "image_url",
						"image_url": map[string]string{
							"url": fmt.Sprintf("data:%s;base64,%s", mediaType, base64Image),
						},
					},
				},
			},
		},
		"max_tokens": 1000,
	}

	jsonBody, _ := json.Marshal(requestBody)
	
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.openai.com/v1/chat/completions", bytes.NewBuffer(jsonBody))
	if err != nil {
		return nil, err
	}
	
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+p.openAIKey)
	
	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	body, _ := io.ReadAll(resp.Body)
	
	// Response parse
	var openAIResp struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	
	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return nil, err
	}
	
	if len(openAIResp.Choices) == 0 {
		return &ScanResult{Success: false, Error: "AI yanıt vermedi"}, nil
	}
	
	// JSON çıkarma
	content := openAIResp.Choices[0].Message.Content
	content = strings.TrimPrefix(content, "```json")
	content = strings.TrimSuffix(content, "```")
	content = strings.TrimSpace(content)
	
	var invoiceData InvoiceData
	if err := json.Unmarshal([]byte(content), &invoiceData); err != nil {
		return &ScanResult{
			Success:    false,
			Error:      "AI yanıtı parse edilemedi",
			Confidence: 0.5,
		}, nil
	}
	
	return &ScanResult{
		Success:     true,
		Data:        invoiceData,
		Confidence:  0.92, // OpenAI Vision genelde yüksek doğruluk
		ProcessedAt: time.Now(),
	}, nil
}

// callGoogleDocumentAI - Google Document AI ile fatura okuma
func (p *InvoiceParser) callGoogleDocumentAI(ctx context.Context, fileData []byte) (*ScanResult, error) {
	// Google Document AI Invoice Parser
	// https://cloud.google.com/document-ai/docs/processors-list#processor_invoice-parser
	
	// TODO: Gerçek entegrasyon
	return &ScanResult{
		Success: false,
		Error:   "Google Document AI henüz yapılandırılmamış",
	}, nil
}

// parsePDF - PDF dosyasını analiz et
func (p *InvoiceParser) parsePDF(ctx context.Context, pdfData []byte) (*ScanResult, error) {
	// PDF'i görüntüye dönüştür (poppler veya ImageMagick ile)
	// Veya PDF'den text çıkar ve text olarak analiz et
	
	// Şimdilik direkt base64 olarak gönder (GPT-4 PDF desteği gelecekte)
	base64PDF := base64.StdEncoding.EncodeToString(pdfData)
	
	return p.callOpenAIVision(ctx, base64PDF, "PDF")
}

// SuggestCategory - Açıklamaya göre kategori öner
func (p *InvoiceParser) SuggestCategory(description string) string {
	description = strings.ToLower(description)
	
	categoryKeywords := map[string][]string{
		"Ortak Elektrik": {"elektrik", "enerji", "ayedaş", "bedaş", "enerjisa"},
		"Ortak Su":       {"su", "iski", "aski"},
		"Ortak Isınma":   {"doğalgaz", "igdaş", "ısınma"},
		"Asansör Bakımı": {"asansör", "elevator", "kone", "schindler", "otis"},
		"Bahçe Bakımı":   {"bahçe", "peyzaj", "çim", "ağaç"},
		"Bina Temizliği": {"temizlik", "cleaning"},
		"Güvenlik":       {"güvenlik", "security", "kamera"},
	}
	
	for category, keywords := range categoryKeywords {
		for _, keyword := range keywords {
			if strings.Contains(description, keyword) {
				return category
			}
		}
	}
	
	return "Diğer"
}
