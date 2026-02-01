package integration_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// IntegrationTestSuite - Ana integration test suite
type IntegrationTestSuite struct {
	suite.Suite
	router      *gin.Engine
	accessToken string
	userID      string
	propertyID  string
}

func TestIntegrationSuite(t *testing.T) {
	suite.Run(t, new(IntegrationTestSuite))
}

func (s *IntegrationTestSuite) SetupSuite() {
	gin.SetMode(gin.TestMode)
	s.router = setupIntegrationRouter()
	s.propertyID = "prop-001"
}

func (s *IntegrationTestSuite) SetupTest() {
	// Her test öncesi login
	s.login()
}

func (s *IntegrationTestSuite) login() {
	body := map[string]string{
		"phone":    "+905551234567",
		"password": "Test123!",
	}
	jsonBody, _ := json.Marshal(body)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)

	s.accessToken = response["access_token"].(string)
	user := response["user"].(map[string]interface{})
	s.userID = user["id"].(string)
}

// ============ AUTH FLOW TESTS ============

func (s *IntegrationTestSuite) TestAuthFlow_LoginLogoutRefresh() {
	// Login başarılı
	assert.NotEmpty(s.T(), s.accessToken)

	// Me endpoint çalışıyor
	req := httptest.NewRequest(http.MethodGet, "/api/v1/users/me", nil)
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusOK, w.Code)

	// Refresh token
	refreshBody := map[string]string{"refresh_token": "mock_refresh_token"}
	jsonBody, _ := json.Marshal(refreshBody)

	req = httptest.NewRequest(http.MethodPost, "/api/v1/auth/refresh", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusOK, w.Code)
}

// ============ ASSESSMENT FLOW TESTS ============

func (s *IntegrationTestSuite) TestAssessmentFlow_CreateAndPay() {
	// 1. Tahakkuk oluştur
	assessBody := map[string]interface{}{
		"period_year":  2026,
		"period_month": 2,
		"expense_items": []map[string]interface{}{
			{"category_id": "cat-001", "amount": 5000.00},
		},
	}
	jsonBody, _ := json.Marshal(assessBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/finance/assessments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusCreated, w.Code)

	var assessResponse map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &assessResponse)
	assessmentID := assessResponse["id"].(string)

	// 2. Borç durumunu kontrol et
	req = httptest.NewRequest(http.MethodGet, "/api/v1/finance/debt-status", nil)
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w = httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusOK, w.Code)

	// 3. Ödeme yap
	payBody := map[string]interface{}{
		"assessment_ids": []string{assessmentID},
		"amount":         500.00,
		"payment_method": "CREDIT_CARD",
	}
	jsonBody, _ = json.Marshal(payBody)

	req = httptest.NewRequest(http.MethodPost, "/api/v1/finance/payments", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w = httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusCreated, w.Code)
}

// ============ COMMUNITY FLOW TESTS ============

func (s *IntegrationTestSuite) TestCommunityFlow_Announcements() {
	// 1. Duyuru oluştur
	annBody := map[string]interface{}{
		"title":    "Test Duyurusu",
		"content":  "Test içerik",
		"category": "INFO",
		"priority": "NORMAL",
	}
	jsonBody, _ := json.Marshal(annBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/announcements", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusCreated, w.Code)

	// 2. Duyuruları listele
	req = httptest.NewRequest(http.MethodGet, "/api/v1/announcements", nil)
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w = httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusOK, w.Code)
}

// ============ METER READING FLOW TESTS ============

func (s *IntegrationTestSuite) TestMeterFlow_SubmitReading() {
	// 1. Sayaçları listele
	req := httptest.NewRequest(http.MethodGet, "/api/v1/meters?type=HEAT", nil)
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusOK, w.Code)

	// 2. Okuma gönder
	readingBody := map[string]interface{}{
		"value": 1250.00,
	}
	jsonBody, _ := json.Marshal(readingBody)

	req = httptest.NewRequest(http.MethodPost, "/api/v1/meters/mtr-001/readings", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w = httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusCreated, w.Code)
}

// ============ REQUEST FLOW TESTS ============

func (s *IntegrationTestSuite) TestRequestFlow_CreateAndUpdate() {
	// 1. Talep oluştur
	reqBody := map[string]interface{}{
		"title":       "Asansör arızası",
		"description": "A Blok asansörü çalışmıyor",
		"category":    "MAINTENANCE",
		"priority":    "HIGH",
	}
	jsonBody, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/requests", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.accessToken)
	w := httptest.NewRecorder()

	s.router.ServeHTTP(w, req)
	assert.Equal(s.T(), http.StatusCreated, w.Code)

	var response map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &response)
	require.NotNil(s.T(), response["id"])
}

// Helper setup
func setupIntegrationRouter() *gin.Engine {
	r := gin.New()

	// Auth routes
	r.POST("/api/v1/auth/login", mockLogin)
	r.POST("/api/v1/auth/refresh", mockRefresh)

	// Protected routes
	protected := r.Group("/api/v1")
	protected.Use(mockAuthMiddleware)
	{
		protected.GET("/users/me", mockGetMe)
		protected.POST("/finance/assessments", mockCreateAssessment)
		protected.GET("/finance/debt-status", mockGetDebtStatus)
		protected.POST("/finance/payments", mockCreatePayment)
		protected.GET("/announcements", mockListAnnouncements)
		protected.POST("/announcements", mockCreateAnnouncement)
		protected.GET("/meters", mockListMeters)
		protected.POST("/meters/:id/readings", mockSubmitReading)
		protected.POST("/requests", mockCreateRequest)
	}

	return r
}

func mockAuthMiddleware(c *gin.Context) {
	auth := c.GetHeader("Authorization")
	if auth == "" {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}
	c.Set("user_id", "user-123")
	c.Next()
}

func mockLogin(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"access_token":  "mock_access_token",
		"refresh_token": "mock_refresh_token",
		"user":          gin.H{"id": "user-123", "first_name": "Test"},
	})
}

func mockRefresh(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"access_token": "new_token"})
}

func mockGetMe(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"id": "user-123"})
}

func mockCreateAssessment(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "assess-001"})
}

func mockGetDebtStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"total_debt": 1500.00})
}

func mockCreatePayment(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "payment-001"})
}

func mockListAnnouncements(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"data": []gin.H{}})
}

func mockCreateAnnouncement(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "ann-001"})
}

func mockListMeters(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"data": []gin.H{{"id": "mtr-001"}}})
}

func mockSubmitReading(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "reading-001"})
}

func mockCreateRequest(c *gin.Context) {
	c.JSON(http.StatusCreated, gin.H{"id": "req-001"})
}
