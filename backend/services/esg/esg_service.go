package esg

import (
	"context"
	"fmt"
	"time"
)

// MetricCategory ESG metrik kategorisi
type MetricCategory string

const (
	CategoryEnvironment MetricCategory = "environment"
	CategorySocial      MetricCategory = "social"
	CategoryGovernance  MetricCategory = "governance"
)

// Metric ESG metriği
type Metric struct {
	ID         string         `json:"id"`
	SiteID     string         `json:"site_id"`
	Category   MetricCategory `json:"category"`
	Name       string         `json:"name"`
	Value      float64        `json:"value"`
	Unit       string         `json:"unit"`
	Period     string         `json:"period"`
	RecordedAt time.Time      `json:"recorded_at"`
}

// CarbonFootprint karbon ayak izi
type CarbonFootprint struct {
	SiteID          string           `json:"site_id"`
	Period          string           `json:"period"`
	TotalEmissions  float64          `json:"total_emissions"` // ton CO2
	PerCapita       float64          `json:"per_capita"`      // ton CO2/kişi
	BySource        []EmissionSource `json:"by_source"`
	Trend           string           `json:"trend"`
	PreviousTotal   float64          `json:"previous_total"`
	ReductionTarget float64          `json:"reduction_target"`
	CalculatedAt    time.Time        `json:"calculated_at"`
}

// EmissionSource emisyon kaynağı
type EmissionSource struct {
	Source     string  `json:"source"`
	Emissions  float64 `json:"emissions"` // ton CO2
	Percentage float64 `json:"percentage"`
}

// SustainabilityScore sürdürülebilirlik skoru
type SustainabilityScore struct {
	SiteID          string           `json:"site_id"`
	OverallScore    float64          `json:"overall_score"` // 0-100
	Grade           string           `json:"grade"`         // A, B, C, D, F
	CategoryScores  []CategoryScore  `json:"category_scores"`
	Achievements    []Achievement    `json:"achievements"`
	Recommendations []Recommendation `json:"recommendations"`
	CalculatedAt    time.Time        `json:"calculated_at"`
}

// CategoryScore kategori skoru
type CategoryScore struct {
	Category   MetricCategory `json:"category"`
	Score      float64        `json:"score"`
	Trend      string         `json:"trend"`
	Highlights []string       `json:"highlights"`
}

// Achievement başarı
type Achievement struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Icon        string `json:"icon"`
	EarnedAt    string `json:"earned_at"`
}

// Recommendation öneri
type Recommendation struct {
	Priority     string  `json:"priority"` // high, medium, low
	Category     string  `json:"category"`
	Action       string  `json:"action"`
	Impact       string  `json:"impact"`
	Savings      float64 `json:"savings,omitempty"`
	CO2Reduction float64 `json:"co2_reduction,omitempty"`
}

// ESGReport ESG raporu
type ESGReport struct {
	SiteID           string              `json:"site_id"`
	SiteName         string              `json:"site_name"`
	ReportYear       int                 `json:"report_year"`
	GeneratedAt      time.Time           `json:"generated_at"`
	ExecutiveSummary string              `json:"executive_summary"`
	CarbonFootprint  CarbonFootprint     `json:"carbon_footprint"`
	Sustainability   SustainabilityScore `json:"sustainability"`
	YearOverYear     YoYComparison       `json:"year_over_year"`
	Goals            []Goal              `json:"goals"`
}

// YoYComparison yıldan yıla karşılaştırma
type YoYComparison struct {
	EmissionsChange    float64 `json:"emissions_change"`
	EnergyChange       float64 `json:"energy_change"`
	WaterChange        float64 `json:"water_change"`
	WasteRecyclingRate float64 `json:"waste_recycling_rate"`
}

// Goal hedef
type Goal struct {
	ID       string  `json:"id"`
	Title    string  `json:"title"`
	Target   float64 `json:"target"`
	Current  float64 `json:"current"`
	Unit     string  `json:"unit"`
	Deadline string  `json:"deadline"`
	Progress float64 `json:"progress"` // 0-100
}

// Service ESG servisi
type Service struct{}

// NewService yeni servis oluşturur
func NewService() *Service {
	return &Service{}
}

// CalculateCarbonFootprint karbon ayak izi hesaplar
func (s *Service) CalculateCarbonFootprint(ctx context.Context, siteID string, year int) (*CarbonFootprint, error) {
	// Emission factors (kg CO2 per unit)
	const (
		electricityFactor = 0.47  // kg CO2/kWh (Turkey grid)
		gasFactor         = 2.0   // kg CO2/m³
		waterFactor       = 0.376 // kg CO2/m³
		wasteFactor       = 0.5   // kg CO2/kg
	)

	// Demo consumption data
	electricityUsage := 125000.0 // kWh
	gasUsage := 15000.0          // m³
	waterUsage := 2500.0         // m³
	wasteGenerated := 8000.0     // kg

	// Calculate emissions
	electricityEmissions := electricityUsage * electricityFactor / 1000
	gasEmissions := gasUsage * gasFactor / 1000
	waterEmissions := waterUsage * waterFactor / 1000
	wasteEmissions := wasteGenerated * wasteFactor / 1000

	totalEmissions := electricityEmissions + gasEmissions + waterEmissions + wasteEmissions

	// Residents count
	residents := 450.0

	return &CarbonFootprint{
		SiteID:         siteID,
		Period:         fmt.Sprintf("%d", year),
		TotalEmissions: totalEmissions,
		PerCapita:      totalEmissions / residents,
		BySource: []EmissionSource{
			{Source: "Elektrik", Emissions: electricityEmissions, Percentage: electricityEmissions / totalEmissions * 100},
			{Source: "Doğalgaz", Emissions: gasEmissions, Percentage: gasEmissions / totalEmissions * 100},
			{Source: "Su", Emissions: waterEmissions, Percentage: waterEmissions / totalEmissions * 100},
			{Source: "Atık", Emissions: wasteEmissions, Percentage: wasteEmissions / totalEmissions * 100},
		},
		Trend:           "down",
		PreviousTotal:   totalEmissions * 1.08, // %8 azalma varsayımı
		ReductionTarget: 10.0,                  // %10 hedef
		CalculatedAt:    time.Now(),
	}, nil
}

// CalculateSustainabilityScore sürdürülebilirlik skoru hesaplar
func (s *Service) CalculateSustainabilityScore(ctx context.Context, siteID string) (*SustainabilityScore, error) {
	// Calculate individual category scores
	envScore := 72.0
	socialScore := 68.0
	govScore := 75.0

	// Overall score (weighted average)
	overallScore := (envScore*0.4 + socialScore*0.3 + govScore*0.3)

	// Determine grade
	var grade string
	switch {
	case overallScore >= 90:
		grade = "A"
	case overallScore >= 80:
		grade = "B"
	case overallScore >= 70:
		grade = "C"
	case overallScore >= 60:
		grade = "D"
	default:
		grade = "F"
	}

	return &SustainabilityScore{
		SiteID:       siteID,
		OverallScore: overallScore,
		Grade:        grade,
		CategoryScores: []CategoryScore{
			{
				Category:   CategoryEnvironment,
				Score:      envScore,
				Trend:      "up",
				Highlights: []string{"LED aydınlatmaya geçiş tamamlandı", "Geri dönüşüm oranı %45'e yükseldi"},
			},
			{
				Category:   CategorySocial,
				Score:      socialScore,
				Trend:      "stable",
				Highlights: []string{"Sakin memnuniyet skoru 78", "Topluluk etkinlikleri artırıldı"},
			},
			{
				Category:   CategoryGovernance,
				Score:      govScore,
				Trend:      "up",
				Highlights: []string{"Şeffaf bütçe yönetimi", "Dijital genel kurul sistemi"},
			},
		},
		Achievements: []Achievement{
			{ID: "1", Title: "Yeşil Bina", Description: "Enerji verimliliği hedefine ulaşıldı", Icon: "eco", EarnedAt: "2026"},
			{ID: "2", Title: "Geri Dönüşüm Şampiyonu", Description: "Atık ayrıştırma oranı %50 üzerinde", Icon: "recycling", EarnedAt: "2026"},
		},
		Recommendations: []Recommendation{
			{Priority: "high", Category: "Enerji", Action: "Güneş paneli kurulumu", Impact: "%25 enerji tasarrufu", Savings: 45000, CO2Reduction: 15.5},
			{Priority: "medium", Category: "Su", Action: "Yağmur suyu toplama sistemi", Impact: "%30 su tasarrufu", Savings: 12000, CO2Reduction: 2.8},
			{Priority: "low", Category: "Atık", Action: "Kompost sistemi kurulumu", Impact: "Organik atık azaltımı", CO2Reduction: 1.2},
		},
		CalculatedAt: time.Now(),
	}, nil
}

// GenerateAnnualReport yıllık ESG raporu oluşturur
func (s *Service) GenerateAnnualReport(ctx context.Context, siteID, siteName string, year int) (*ESGReport, error) {
	carbon, _ := s.CalculateCarbonFootprint(ctx, siteID, year)
	sustainability, _ := s.CalculateSustainabilityScore(ctx, siteID)

	return &ESGReport{
		SiteID:      siteID,
		SiteName:    siteName,
		ReportYear:  year,
		GeneratedAt: time.Now(),
		ExecutiveSummary: fmt.Sprintf(`%d yılında %s sitesi, sürdürülebilirlik çalışmalarında önemli ilerlemeler kaydetmiştir. 
Karbon ayak izi bir önceki yıla göre %%8 azaltılmış, genel sürdürülebilirlik skoru %s seviyesine ulaşmıştır.`,
			year, siteName, sustainability.Grade),
		CarbonFootprint: *carbon,
		Sustainability:  *sustainability,
		YearOverYear: YoYComparison{
			EmissionsChange:    -8.0,
			EnergyChange:       -5.2,
			WaterChange:        -3.1,
			WasteRecyclingRate: 45.0,
		},
		Goals: []Goal{
			{ID: "1", Title: "Karbon Nötr", Target: 0, Current: carbon.TotalEmissions, Unit: "ton CO2", Deadline: "2030", Progress: 25},
			{ID: "2", Title: "Geri Dönüşüm", Target: 75, Current: 45, Unit: "%", Deadline: "2027", Progress: 60},
			{ID: "3", Title: "Su Tasarrufu", Target: 30, Current: 18, Unit: "% azalma", Deadline: "2026", Progress: 60},
		},
	}, nil
}

// RecordMetric metrik kaydeder
func (s *Service) RecordMetric(ctx context.Context, metric *Metric) error {
	metric.RecordedAt = time.Now()
	// Save to database
	return nil
}

// GetMetrics metrikleri getirir
func (s *Service) GetMetrics(ctx context.Context, siteID string, category MetricCategory, startDate, endDate time.Time) ([]Metric, error) {
	// Fetch from database
	return []Metric{}, nil
}
