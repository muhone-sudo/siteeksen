package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AI-Powered Smart Collection Service
// Ödeme riski analizi, tahsilat stratejileri

type PaymentRisk struct {
	ID              string       `json:"id"`
	ResidentID      string       `json:"resident_id"`
	ResidentName    string       `json:"resident_name"`
	UnitNumber      string       `json:"unit_number"`
	RiskScore       float64      `json:"risk_score"` // 0-100
	RiskLevel       string       `json:"risk_level"` // LOW, MEDIUM, HIGH, CRITICAL
	PaymentHistory  gin.H        `json:"payment_history"`
	Factors         []RiskFactor `json:"factors"`
	Prediction      string       `json:"prediction"`
	SuggestedAction string       `json:"suggested_action"`
	LastUpdated     time.Time    `json:"last_updated"`
}

type RiskFactor struct {
	Factor      string  `json:"factor"`
	Impact      string  `json:"impact"` // POSITIVE, NEGATIVE
	Weight      float64 `json:"weight"`
	Description string  `json:"description"`
}

type CollectionStrategy struct {
	ID           string           `json:"id"`
	ResidentID   string           `json:"resident_id"`
	ResidentName string           `json:"resident_name"`
	UnitNumber   string           `json:"unit_number"`
	TotalDebt    float64          `json:"total_debt"`
	DaysOverdue  int              `json:"days_overdue"`
	RiskLevel    string           `json:"risk_level"`
	Strategy     string           `json:"strategy"` // REMINDER, PAYMENT_PLAN, LEGAL_WARNING, LEGAL_ACTION
	Actions      []StrategyAction `json:"actions"`
	Status       string           `json:"status"` // PENDING, IN_PROGRESS, COMPLETED
	CreatedAt    time.Time        `json:"created_at"`
}

type StrategyAction struct {
	Order       int        `json:"order"`
	ActionType  string     `json:"action_type"` // SMS, EMAIL, PHONE_CALL, LETTER, LEGAL
	Description string     `json:"description"`
	ScheduledAt string     `json:"scheduled_at"`
	ExecutedAt  *time.Time `json:"executed_at,omitempty"`
	Result      string     `json:"result,omitempty"`
	Status      string     `json:"status"` // PENDING, EXECUTED, SKIPPED
}

type CollectionDashboard struct {
	TotalOverdue       float64 `json:"total_overdue"`
	OverdueAccounts    int     `json:"overdue_accounts"`
	HighRiskAccounts   int     `json:"high_risk_accounts"`
	CollectedThisMonth float64 `json:"collected_this_month"`
	CollectionRate     float64 `json:"collection_rate"`
	RiskDistribution   gin.H   `json:"risk_distribution"`
	AgingReport        []gin.H `json:"aging_report"`
}

func main() {
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "healthy", "service": "smart-collection", "ai_enabled": true})
	})

	v1 := r.Group("/api/v1")
	{
		// Dashboard
		v1.GET("/collection/dashboard", getCollectionDashboard)

		// Risk Analysis
		v1.GET("/collection/risks", listPaymentRisks)
		v1.GET("/collection/risks/:id", getPaymentRisk)
		v1.POST("/collection/analyze", runRiskAnalysis)

		// Strategies
		v1.GET("/collection/strategies", listStrategies)
		v1.GET("/collection/strategies/:id", getStrategy)
		v1.POST("/collection/strategies/generate", generateStrategies)
		v1.POST("/collection/strategies/:id/execute", executeStrategy)
		v1.POST("/collection/strategies/:id/actions/:action_id/execute", executeAction)

		// Predictions
		v1.GET("/collection/predictions", getPaymentPredictions)
		v1.GET("/collection/forecast", getCollectionForecast)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8104"
	}
	log.Printf("Smart Collection Service starting on port %s", port)
	r.Run(":" + port)
}

func getCollectionDashboard(c *gin.Context) {
	dashboard := CollectionDashboard{
		TotalOverdue:       185000,
		OverdueAccounts:    15,
		HighRiskAccounts:   4,
		CollectedThisMonth: 42000,
		CollectionRate:     92.5,
		RiskDistribution: gin.H{
			"low": 95, "medium": 18, "high": 8, "critical": 3,
		},
		AgingReport: []gin.H{
			{"range": "0-30 gün", "amount": 45000, "accounts": 8},
			{"range": "31-60 gün", "amount": 65000, "accounts": 4},
			{"range": "61-90 gün", "amount": 35000, "accounts": 2},
			{"range": "90+ gün", "amount": 40000, "accounts": 1},
		},
	}
	c.JSON(http.StatusOK, dashboard)
}

func listPaymentRisks(c *gin.Context) {
	risks := []PaymentRisk{
		{
			ID:             uuid.New().String(),
			ResidentName:   "Mehmet Demir",
			UnitNumber:     "D.301",
			RiskScore:      78,
			RiskLevel:      "HIGH",
			PaymentHistory: gin.H{"on_time_rate": 45.0, "avg_delay_days": 25, "missed_payments": 3},
			Factors: []RiskFactor{
				{Factor: "Geçmiş Gecikmeler", Impact: "NEGATIVE", Weight: 0.35, Description: "Son 6 ayda 4 gecikme"},
				{Factor: "Ödeme Miktarı", Impact: "NEGATIVE", Weight: 0.25, Description: "Genellikle eksik ödeme"},
			},
			Prediction:      "Gelecek ödeme %70 ihtimalle gecikmeli",
			SuggestedAction: "Ödeme planı öner",
			LastUpdated:     time.Now(),
		},
		{
			ID:             uuid.New().String(),
			ResidentName:   "Ali Veli",
			UnitNumber:     "D.101",
			RiskScore:      12,
			RiskLevel:      "LOW",
			PaymentHistory: gin.H{"on_time_rate": 98.0, "avg_delay_days": 0, "missed_payments": 0},
			Factors: []RiskFactor{
				{Factor: "Düzenli Ödeme", Impact: "POSITIVE", Weight: 0.40, Description: "Son 24 ayda tüm ödemeler zamanında"},
			},
			Prediction:      "Ödeme zamanında gerçekleşecek",
			SuggestedAction: "Aksiyon gerekli değil",
			LastUpdated:     time.Now(),
		},
	}
	c.JSON(http.StatusOK, gin.H{"risks": risks})
}

func getPaymentRisk(c *gin.Context) {
	c.JSON(http.StatusOK, PaymentRisk{ID: c.Param("id"), RiskLevel: "MEDIUM", LastUpdated: time.Now()})
}

func runRiskAnalysis(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"analysis_completed_at": time.Now(),
		"accounts_analyzed":     124,
		"risk_changes":          gin.H{"upgraded": 3, "downgraded": 2, "unchanged": 119},
		"message":               "AI risk analizi tamamlandı",
	})
}

func listStrategies(c *gin.Context) {
	strategies := []CollectionStrategy{
		{
			ID:           uuid.New().String(),
			ResidentName: "Mehmet Demir",
			UnitNumber:   "D.301",
			TotalDebt:    5100,
			DaysOverdue:  45,
			RiskLevel:    "HIGH",
			Strategy:     "PAYMENT_PLAN",
			Actions: []StrategyAction{
				{Order: 1, ActionType: "SMS", Description: "Borç hatırlatma", ScheduledAt: "2026-02-01", Status: "EXECUTED"},
				{Order: 2, ActionType: "EMAIL", Description: "Detaylı borç dökümü", ScheduledAt: "2026-02-03", Status: "EXECUTED"},
				{Order: 3, ActionType: "PHONE_CALL", Description: "Ödeme planı görüşmesi", ScheduledAt: "2026-02-05", Status: "PENDING"},
			},
			Status:    "IN_PROGRESS",
			CreatedAt: time.Now(),
		},
	}
	c.JSON(http.StatusOK, gin.H{"strategies": strategies})
}

func getStrategy(c *gin.Context) {
	c.JSON(http.StatusOK, CollectionStrategy{ID: c.Param("id"), Status: "IN_PROGRESS", CreatedAt: time.Now()})
}

func generateStrategies(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"generated_at":       time.Now(),
		"strategies_created": 4,
		"by_type":            gin.H{"REMINDER": 2, "PAYMENT_PLAN": 1, "LEGAL_WARNING": 1},
		"message":            "AI tahsilat stratejileri oluşturuldu",
	})
}

func executeStrategy(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": c.Param("id"), "status": "IN_PROGRESS", "message": "Strateji uygulamaya alındı"})
}

func executeAction(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"strategy_id": c.Param("id"),
		"action_id":   c.Param("action_id"),
		"executed_at": time.Now(),
		"message":     "Aksiyon gerçekleştirildi",
	})
}

func getPaymentPredictions(c *gin.Context) {
	predictions := []gin.H{
		{"resident_name": "Mehmet Demir", "unit_number": "D.301", "due_date": "2026-02-05", "prediction": "LATE", "confidence": 0.78, "expected_delay_days": 15},
		{"resident_name": "Zeynep Kaya", "unit_number": "D.405", "due_date": "2026-02-05", "prediction": "ON_TIME", "confidence": 0.92, "expected_delay_days": 0},
		{"resident_name": "Can Demir", "unit_number": "D.502", "due_date": "2026-02-05", "prediction": "PARTIAL", "confidence": 0.65, "expected_amount_percent": 60},
	}
	c.JSON(http.StatusOK, gin.H{"predictions": predictions})
}

func getCollectionForecast(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"forecast_period":            "2026-02",
		"expected_collection":        285000,
		"expected_overdue":           25000,
		"collection_rate_prediction": 91.9,
		"confidence":                 0.85,
		"recommendations": []string{
			"4 yüksek riskli hesap için proaktif iletişim önerilir",
			"2 hesap için ödeme planı görüşmesi başlatılmalı",
		},
	})
}
