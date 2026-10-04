package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestMetricsRecordsRouteTemplates(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := NewRouter("test")
	g := r.Group("/api/v1/items")
	g.GET("", func(c *gin.Context) { c.Status(http.StatusOK) })
	g.POST("/:id/respond", func(c *gin.Context) { c.Status(http.StatusConflict) })

	for _, req := range []*http.Request{
		httptest.NewRequest(http.MethodGet, "/api/v1/items", nil),
		httptest.NewRequest(http.MethodPost, "/api/v1/items/0b9e1f3a-1111-2222-3333-444455556666/respond", nil),
		httptest.NewRequest(http.MethodPost, "/api/v1/items/0b9e1f3a-1111-2222-3333-444455556666/respond", nil),
	} {
		r.ServeHTTP(httptest.NewRecorder(), req)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	body := w.Body.String()
	for _, want := range []string{
		`siteeksen_http_requests_total{service="test",route="/api/v1/items",method="GET",status="2xx"} 1`,
		`siteeksen_http_requests_total{service="test",route="/api/v1/items/:id/respond",method="POST",status="4xx"} 2`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("eksik: %s\n---\n%s", want, body)
		}
	}
	if strings.Contains(body, "0b9e1f3a") {
		t.Error("ham yol/kimlik metriklere sızdı")
	}
}
