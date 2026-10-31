package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// Kimliksiz yol listesi bilerek dardır; genişlemesi bilinçli bir karar olmalıdır.
func TestIsPublicPathDar(t *testing.T) {
	public := []string{
		"/health", "/", "/api/v1/auth/login",
		"/api/v1/public/clearance/abc",
		"/api/v1/public/devices/heartbeat",
		"/api/v1/public/payments/iyzico/callback",
		"/api/v1/public/market/topups/iyzico/callback",
	}
	for _, p := range public {
		if !isPublicPath(p) {
			t.Errorf("%s kimliksiz olmalıydı", p)
		}
	}
	private := []string{
		"/api/v1/access-devices", "/api/v1/access-devices/incidents",
		"/api/v1/public/devices", "/api/v1/public/devices/heartbeat/x", "/api/v1/public/devicesX",
		"/api/v1/public", "/api/v1/finance/clearance-certificates", "/api/v1/vehicles",
		"/api/v1/public/payments", "/api/v1/public/payments/iyzico/callback/x", "/api/v1/finance/payments/x/status",
		"/api/v1/public/market", "/api/v1/public/market/topups", "/api/v1/market/supplier/wallet",
	}
	for _, p := range private {
		if isPublicPath(p) {
			t.Errorf("%s kimlik doğrulaması istemeliydi", p)
		}
	}
}

// Bakiye yüklemesi (pazaryeri) Idempotency-Key başlığı gönderir; tarayıcı ön isteği bu başlığa izin vermeli.
func TestCORSIdempotencyKey(t *testing.T) {
	h := corsMiddleware([]string{"http://localhost:3001"}, http.HandlerFunc(func(http.ResponseWriter, *http.Request) {}))
	req := httptest.NewRequest(http.MethodOptions, "/api/v1/market/supplier/topups", nil)
	req.Header.Set("Origin", "http://localhost:3001")
	req.Header.Set("Access-Control-Request-Headers", "authorization,content-type,idempotency-key")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	if !strings.Contains(rec.Header().Get("Access-Control-Allow-Headers"), "Idempotency-Key") {
		t.Fatalf("Idempotency-Key izinli başlıklarda yok: %q", rec.Header().Get("Access-Control-Allow-Headers"))
	}
}
