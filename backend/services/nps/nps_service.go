package nps

import (
	"context"
	"fmt"
	"time"
)

// ScoreCategory NPS skoru kategorisi
type ScoreCategory string

const (
	ScorePromoter  ScoreCategory = "promoter"  // 9-10
	ScorePassive   ScoreCategory = "passive"   // 7-8
	ScoreDetractor ScoreCategory = "detractor" // 0-6
)

// Survey NPS anketi
type Survey struct {
	ID          string    `json:"id"`
	SiteID      string    `json:"site_id"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

// Response anket yanıtı
type Response struct {
	ID         string    `json:"id"`
	SurveyID   string    `json:"survey_id"`
	ResidentID string    `json:"resident_id"`
	UnitNo     string    `json:"unit_no"`
	Score      int       `json:"score"` // 0-10
	Comment    string    `json:"comment,omitempty"`
	Tags       []string  `json:"tags,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
}

// NPSResult NPS sonucu
type NPSResult struct {
	SurveyID       string        `json:"survey_id"`
	TotalResponses int           `json:"total_responses"`
	Promoters      int           `json:"promoters"`
	Passives       int           `json:"passives"`
	Detractors     int           `json:"detractors"`
	NPSScore       float64       `json:"nps_score"`
	Trend          string        `json:"trend"` // up, down, stable
	PreviousScore  float64       `json:"previous_score,omitempty"`
	ByCategory     []CategoryNPS `json:"by_category,omitempty"`
	TopIssues      []Issue       `json:"top_issues,omitempty"`
}

// CategoryNPS kategori bazlı NPS
type CategoryNPS struct {
	Category  string  `json:"category"`
	Score     float64 `json:"score"`
	Responses int     `json:"responses"`
}

// Issue sorun
type Issue struct {
	Tag       string `json:"tag"`
	Count     int    `json:"count"`
	Sentiment string `json:"sentiment"` // negative, mixed
}

// Service NPS servisi
type Service struct {
	// database connection would go here
}

// NewService yeni servis oluşturur
func NewService() *Service {
	return &Service{}
}

// CreateSurvey anket oluşturur
func (s *Service) CreateSurvey(ctx context.Context, survey *Survey) error {
	survey.CreatedAt = time.Now()
	survey.IsActive = true
	// Save to database
	return nil
}

// SubmitResponse yanıt gönderir
func (s *Service) SubmitResponse(ctx context.Context, response *Response) error {
	if response.Score < 0 || response.Score > 10 {
		return fmt.Errorf("skor 0-10 arasında olmalıdır")
	}
	response.CreatedAt = time.Now()
	// Save to database
	return nil
}

// CalculateNPS NPS hesaplar
func (s *Service) CalculateNPS(ctx context.Context, surveyID string) (*NPSResult, error) {
	// Demo data
	responses := []Response{
		{Score: 10}, {Score: 9}, {Score: 9}, {Score: 8},
		{Score: 8}, {Score: 7}, {Score: 6}, {Score: 5},
		{Score: 10}, {Score: 9}, {Score: 8}, {Score: 3},
	}

	result := &NPSResult{
		SurveyID:       surveyID,
		TotalResponses: len(responses),
	}

	for _, r := range responses {
		switch GetScoreCategory(r.Score) {
		case ScorePromoter:
			result.Promoters++
		case ScorePassive:
			result.Passives++
		case ScoreDetractor:
			result.Detractors++
		}
	}

	// NPS = %Promoters - %Detractors
	if result.TotalResponses > 0 {
		promoterPct := float64(result.Promoters) / float64(result.TotalResponses) * 100
		detractorPct := float64(result.Detractors) / float64(result.TotalResponses) * 100
		result.NPSScore = promoterPct - detractorPct
	}

	// Determine trend
	result.PreviousScore = 45.0 // Previous period
	if result.NPSScore > result.PreviousScore {
		result.Trend = "up"
	} else if result.NPSScore < result.PreviousScore {
		result.Trend = "down"
	} else {
		result.Trend = "stable"
	}

	// Category breakdown
	result.ByCategory = []CategoryNPS{
		{Category: "Güvenlik", Score: 72.5, Responses: 45},
		{Category: "Temizlik", Score: 65.0, Responses: 52},
		{Category: "Yönetim", Score: 58.3, Responses: 48},
		{Category: "Ortak Alanlar", Score: 45.0, Responses: 38},
	}

	// Top issues from detractor comments
	result.TopIssues = []Issue{
		{Tag: "otopark", Count: 12, Sentiment: "negative"},
		{Tag: "gürültü", Count: 8, Sentiment: "negative"},
		{Tag: "temizlik", Count: 6, Sentiment: "mixed"},
	}

	return result, nil
}

// GetScoreCategory skoru kategorize eder
func GetScoreCategory(score int) ScoreCategory {
	switch {
	case score >= 9:
		return ScorePromoter
	case score >= 7:
		return ScorePassive
	default:
		return ScoreDetractor
	}
}

// GetRecommendations iyileştirme önerileri getirir
func (s *Service) GetRecommendations(ctx context.Context, result *NPSResult) []string {
	recommendations := []string{}

	if result.NPSScore < 0 {
		recommendations = append(recommendations, "Acil: Detractor oranı yüksek, kök neden analizi yapılmalı")
	}

	for _, issue := range result.TopIssues {
		if issue.Count > 5 {
			recommendations = append(recommendations,
				fmt.Sprintf("%s konusunda iyileştirme aksiyonu alınmalı (%d şikayet)", issue.Tag, issue.Count))
		}
	}

	for _, cat := range result.ByCategory {
		if cat.Score < 50 {
			recommendations = append(recommendations,
				fmt.Sprintf("%s kategorisinde memnuniyet düşük (NPS: %.0f)", cat.Category, cat.Score))
		}
	}

	return recommendations
}

// GenerateReport rapor oluşturur
func (s *Service) GenerateReport(ctx context.Context, siteID string, startDate, endDate time.Time) (*NPSReport, error) {
	return &NPSReport{
		SiteID:    siteID,
		Period:    fmt.Sprintf("%s - %s", startDate.Format("02.01.2006"), endDate.Format("02.01.2006")),
		Generated: time.Now(),
		Summary: ReportSummary{
			CurrentNPS:     58.3,
			PreviousNPS:    52.1,
			Change:         6.2,
			TotalResponses: 187,
			ResponseRate:   78.5,
		},
		MonthlyTrend: []MonthlyNPS{
			{Month: "Ocak", Score: 58.3},
			{Month: "Aralık", Score: 55.0},
			{Month: "Kasım", Score: 52.1},
			{Month: "Ekim", Score: 48.5},
		},
	}, nil
}

// NPSReport NPS raporu
type NPSReport struct {
	SiteID       string        `json:"site_id"`
	Period       string        `json:"period"`
	Generated    time.Time     `json:"generated"`
	Summary      ReportSummary `json:"summary"`
	MonthlyTrend []MonthlyNPS  `json:"monthly_trend"`
}

// ReportSummary rapor özeti
type ReportSummary struct {
	CurrentNPS     float64 `json:"current_nps"`
	PreviousNPS    float64 `json:"previous_nps"`
	Change         float64 `json:"change"`
	TotalResponses int     `json:"total_responses"`
	ResponseRate   float64 `json:"response_rate"`
}

// MonthlyNPS aylık NPS
type MonthlyNPS struct {
	Month string  `json:"month"`
	Score float64 `json:"score"`
}
