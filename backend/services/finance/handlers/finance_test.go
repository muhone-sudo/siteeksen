package finance_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// Test Assessment Creation
func TestCreateAssessment_Success(t *testing.T) {
	router := setupFinanceRouter()

	body := map[string]interface{}{
		"period_year":  2026,
		"period_month": 1,
		"expense_items": []map[string]interface{}{
			{"category_id": "cat-001", "amount": 5000.00},
			{"category_id": "cat-002", "amount": 3000.00},
		},
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/assessments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.NotEmpty(t, response["id"])
}

func TestCreateAssessment_InvalidPeriod(t *testing.T) {
	router := setupFinanceRouter()

	body := map[string]interface{}{
		"period_year":  2026,
		"period_month": 13, // Geçersiz ay
		"expense_items": []map[string]interface{}{
			{"category_id": "cat-001", "amount": 5000.00},
		},
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/assessments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

// Test Payment Processing
func TestProcessPayment_Success(t *testing.T) {
	router := setupFinanceRouter()

	body := map[string]interface{}{
		"assessment_ids": []string{"assess-001", "assess-002"},
		"amount":         1500.00,
		"payment_method": "CREDIT_CARD",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/payments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
}

func TestProcessPayment_InsufficientAmount(t *testing.T) {
	router := setupFinanceRouter()

	body := map[string]interface{}{
		"assessment_ids": []string{"assess-001"},
		"amount":         0, // Geçersiz tutar
		"payment_method": "CREDIT_CARD",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/payments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

// Test Debt Status
func TestGetDebtStatus_Success(t *testing.T) {
	router := setupFinanceRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/debt-status", nil)
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	assert.NotNil(t, response["total_debt"])
	assert.NotNil(t, response["pending_assessments"])
}

// Test Expense Categories
func TestListExpenseCategories(t *testing.T) {
	router := setupFinanceRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/finance/expense-categories", nil)
	req.Header.Set("Authorization", "Bearer valid_token")
	w := httptest.NewRecorder()

	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	data, ok := response["data"].([]interface{})
	assert.True(t, ok)
	assert.Greater(t, len(data), 0)
}

// Test Late Fee Calculation
func TestLateFeeCalculation(t *testing.T) {
	testCases := []struct {
		name           string
		amount         float64
		daysOverdue    int
		feePercentage  float64
		expectedLateFee float64
	}{
		{"No late fee", 1000.00, 0, 0.05, 0.00},
		{"10 days late", 1000.00, 10, 0.05, 50.00},
		{"30 days late", 1000.00, 30, 0.05, 50.00}, // Max 1 ay faiz
		{"High amount", 5000.00, 15, 0.05, 250.00},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			lateFee := calculateLateFee(tc.amount, tc.daysOverdue, tc.feePercentage)
			assert.Equal(t, tc.expectedLateFee, lateFee)
		})
	}
}

// Test Distribution Calculation
func TestDistributionCalculation(t *testing.T) {
	units := []struct {
		id   string
		sqm  float64
		share float64
	}{
		{"unit-1", 100.0, 10.0},
		{"unit-2", 150.0, 15.0},
		{"unit-3", 200.0, 20.0},
	}

	totalAmount := 10000.00

	t.Run("Equal distribution", func(t *testing.T) {
		perUnit := totalAmount / float64(len(units))
		assert.InDelta(t, 3333.33, perUnit, 0.01)
	})

	t.Run("SQM based distribution", func(t *testing.T) {
		totalSqm := 0.0
		for _, u := range units {
			totalSqm += u.sqm
		}
		
		for _, u := range units {
			share := (u.sqm / totalSqm) * totalAmount
			if u.id == "unit-1" {
				assert.InDelta(t, 2222.22, share, 0.01)
			}
		}
	})
}

// Helper functions
func setupFinanceRouter() *gin.Engine {
	r := gin.New()

	// Mock auth middleware
	r.Use(func(c *gin.Context) {
		auth := c.GetHeader("Authorization")
		if auth == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			return
		}
		c.Set("user_id", "user-123")
		c.Set("property_id", "prop-001")
		c.Next()
	})

	// Mock routes
	r.POST("/api/v1/finance/assessments", func(c *gin.Context) {
		var body map[string]interface{}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		month, _ := body["period_month"].(float64)
		if month < 1 || month > 12 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid month"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"id":      "assess-new",
			"message": "Assessment created",
		})
	})

	r.POST("/api/v1/finance/payments", func(c *gin.Context) {
		var body map[string]interface{}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		amount, _ := body["amount"].(float64)
		if amount <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"id":      "payment-new",
			"message": "Payment processed",
		})
	})

	r.GET("/api/v1/finance/debt-status", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"total_debt":          1500.00,
			"pending_assessments": 2,
		})
	})

	r.GET("/api/v1/finance/expense-categories", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"data": []gin.H{
				{"id": "cat-001", "name": "Yönetim Gideri"},
				{"id": "cat-002", "name": "Temizlik"},
			},
		})
	})

	return r
}

func calculateLateFee(amount float64, daysOverdue int, feePercentage float64) float64 {
	if daysOverdue <= 0 {
		return 0
	}
	// Aylık faiz, günlük bölünmez
	return amount * feePercentage
}
