package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"time"
)

type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func newProxy(target string) *httputil.ReverseProxy {
	u, err := url.Parse(target)
	if err != nil {
		log.Fatalf("Geçersiz hedef URL %s: %v", target, err)
	}
	proxy := httputil.NewSingleHostReverseProxy(u)
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Printf("Proxy hatası [%s %s]: %v", r.Method, r.URL.Path, err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		json.NewEncoder(w).Encode(Response{Success: false, Error: "Servis şu an erişilemiyor"})
	}
	return proxy
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Tenant-ID")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func logMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

func jsonHandler(fn http.HandlerFunc) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fn(w, r)
	})
}

func main() {
	identityURL := getEnv("IDENTITY_SERVICE_URL", "http://localhost:8081")
	financeURL := getEnv("FINANCE_SERVICE_URL", "http://localhost:8082")
	communityURL := getEnv("COMMUNITY_SERVICE_URL", "http://localhost:8083")
	port := getEnv("PORT", "8888")

	identityProxy := newProxy(identityURL)
	financeProxy := newProxy(financeURL)
	communityProxy := newProxy(communityURL)

	mux := http.NewServeMux()

	// Health
	mux.Handle("/health", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Message: "SiteEksen API Gateway çalışıyor",
			Data:    map[string]interface{}{"version": "1.1.0", "time": time.Now().Format(time.RFC3339)},
		})
	}))

	// --- IDENTITY SERVICE ---
	// /api/v1/auth/* ve /api/v1/users/*
	mux.Handle("/api/v1/auth/", identityProxy)
	mux.Handle("/api/v1/users/", identityProxy)

	// --- FINANCE SERVICE ---
	// /api/v1/finance/*
	mux.Handle("/api/v1/finance/", financeProxy)

	// --- COMMUNITY SERVICE ---
	// /api/v1/announcements/*, /api/v1/surveys/*, /api/v1/bulletins/*, /api/v1/reservations/*
	mux.Handle("/api/v1/announcements/", communityProxy)
	mux.Handle("/api/v1/announcements", communityProxy)
	mux.Handle("/api/v1/surveys/", communityProxy)
	mux.Handle("/api/v1/surveys", communityProxy)
	mux.Handle("/api/v1/bulletins/", communityProxy)
	mux.Handle("/api/v1/bulletins", communityProxy)
	mux.Handle("/api/v1/reservations/", communityProxy)
	mux.Handle("/api/v1/reservations", communityProxy)

	// --- MOCK: Henüz gerçek servisi olmayan endpointler ---

	// Dashboard istatistikleri (aggregate — gerçek servisler hazır olunca buradan toplanacak)
	mux.Handle("/api/v1/dashboard/stats", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data: map[string]interface{}{
				"totalResidents":   156,
				"totalUnits":       180,
				"monthlyIncome":    245000,
				"pendingRequests":  12,
				"occupancyRate":    87,
				"collectionRate":   94,
				"activeVisitors":   3,
				"upcomingMeetings": 2,
			},
		})
	}))
	mux.Handle("/api/v1/dashboard/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{Success: true, Data: map[string]interface{}{}})
	}))

	// Sakinler (residents servisi henüz yok)
	mux.Handle("/api/v1/residents", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			w.WriteHeader(http.StatusCreated)
			json.NewEncoder(w).Encode(Response{Success: true, Message: "Sakin eklendi"})
			return
		}
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data: []map[string]interface{}{
				{"id": "1", "first_name": "Ahmet", "last_name": "Yılmaz", "unit": "A-12", "phone": "5551234567", "status": "active", "role": "OWNER"},
				{"id": "2", "first_name": "Mehmet", "last_name": "Demir", "unit": "B-05", "phone": "5559876543", "status": "active", "role": "TENANT"},
				{"id": "3", "first_name": "Ayşe", "last_name": "Kaya", "unit": "C-08", "phone": "5553334455", "status": "active", "role": "OWNER"},
			},
		})
	}))
	mux.Handle("/api/v1/residents/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{Success: true, Message: "İşlem tamamlandı"})
	}))

	// Sayaçlar (iot servisi bu endpoint'i sunmuyor henüz)
	mux.Handle("/api/v1/meters", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data: []map[string]interface{}{
				{"id": "m-001", "name": "A Blok Su Sayacı", "type": "WATER", "unit": "m³", "last_reading": 1245.5},
				{"id": "m-002", "name": "B Blok Elektrik", "type": "ELECTRIC", "unit": "kWh", "last_reading": 8820.0},
				{"id": "m-003", "name": "Ana Doğalgaz", "type": "GAS", "unit": "m³", "last_reading": 3310.2},
			},
		})
	}))
	mux.Handle("/api/v1/meters/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{Success: true, Message: "Sayaç işlemi tamamlandı"})
	}))

	// Talepler/İş emirleri (ayrı bir servis olacak)
	mux.Handle("/api/v1/requests", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodPost {
			w.WriteHeader(http.StatusCreated)
			json.NewEncoder(w).Encode(Response{Success: true, Message: "Talep oluşturuldu"})
			return
		}
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data: []map[string]interface{}{
				{"id": "req-001", "title": "Asansör Arızası", "status": "OPEN", "priority": "HIGH", "unit": "A-05", "created_at": "2026-06-05T10:00:00Z"},
				{"id": "req-002", "title": "Ortak Alan Temizliği", "status": "IN_PROGRESS", "priority": "NORMAL", "unit": "B-12", "created_at": "2026-06-04T14:00:00Z"},
				{"id": "req-003", "title": "Bahçe Sulama Sistemi", "status": "CLOSED", "priority": "LOW", "unit": "C-01", "created_at": "2026-06-03T09:00:00Z"},
			},
		})
	}))
	mux.Handle("/api/v1/requests/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{Success: true, Message: "Talep güncellendi"})
	}))

	// Raporlar
	mux.Handle("/api/v1/reports/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/download") {
			w.Header().Set("Content-Type", "application/pdf")
			w.Write([]byte("%PDF-1.4 mock"))
			return
		}
		json.NewEncoder(w).Encode(Response{Success: true, Data: map[string]interface{}{"report_id": "rpt-001", "status": "generated"}})
	}))

	handler := logMiddleware(corsMiddleware(mux))

	addr := fmt.Sprintf(":%s", port)
	log.Printf("SiteEksen API Gateway başlatıldı: http://localhost%s", addr)
	log.Printf("  → Identity:  %s", identityURL)
	log.Printf("  → Finance:   %s", financeURL)
	log.Printf("  → Community: %s", communityURL)
	log.Fatal(http.ListenAndServe(addr, handler))
}
