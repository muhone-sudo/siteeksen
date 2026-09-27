package middleware

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestSanitizeRequestID(t *testing.T) {
	for _, ok := range []string{"abc-123", "a.b_c", strings.Repeat("x", 64)} {
		if got := SanitizeRequestID(ok); got != ok {
			t.Errorf("geçerli kimlik değiştirildi: %q → %q", ok, got)
		}
	}
	for _, bad := range []string{"", strings.Repeat("x", 65), "a b", "x\ny", "<script>", "ğ"} {
		got := SanitizeRequestID(bad)
		if got == bad || !requestIDPattern.MatchString(got) {
			t.Errorf("geçersiz kimlik kabul edildi: %q → %q", bad, got)
		}
	}
}

func TestRequestLog_JSONveKisiselVeriYok(t *testing.T) {
	gin.SetMode(gin.TestMode)
	var buf bytes.Buffer
	prev := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&buf, nil)))
	defer slog.SetDefault(prev)

	r := gin.New()
	r.Use(RequestLog())
	r.GET("/residents/:id", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	req := httptest.NewRequest(http.MethodGet, "/residents/42?search=5551234567", nil)
	req.Header.Set(RequestIDHeader, strings.Repeat("A", 200))
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	rid := w.Header().Get(RequestIDHeader)
	if len(rid) == 0 || len(rid) > 64 {
		t.Fatalf("yanıttaki istek kimliği geçersiz: %q", rid)
	}
	var rec map[string]any
	if err := json.Unmarshal(bytes.TrimSpace(buf.Bytes()), &rec); err != nil {
		t.Fatalf("günlük satırı JSON değil: %v — %q", err, buf.String())
	}
	if rec["request_id"] != rid || rec["route"] != "/residents/:id" || rec["status"] != float64(204) {
		t.Errorf("beklenmeyen kayıt: %v", rec)
	}
	if strings.Contains(buf.String(), "5551234567") || strings.Contains(buf.String(), "/residents/42") {
		t.Errorf("günlüğe ham yol ya da sorgu (kişisel veri) yazıldı: %s", buf.String())
	}
}
