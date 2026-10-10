package main

import "testing"

// Kimliksiz yol listesi bilerek dardır; genişlemesi bilinçli bir karar olmalıdır.
func TestIsPublicPathDar(t *testing.T) {
	public := []string{
		"/health", "/", "/api/v1/auth/login",
		"/api/v1/public/clearance/abc",
		"/api/v1/public/devices/heartbeat",
		"/api/v1/public/payments/iyzico/callback",
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
	}
	for _, p := range private {
		if isPublicPath(p) {
			t.Errorf("%s kimlik doğrulaması istemeliydi", p)
		}
	}
}
