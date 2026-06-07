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

func proxyPaths(mux *http.ServeMux, proxy *httputil.ReverseProxy, paths ...string) {
	for _, p := range paths {
		mux.Handle(p, proxy)
		if !strings.HasSuffix(p, "/") {
			mux.Handle(p+"/", proxy)
		}
	}
}

func main() {
	identityURL := getEnv("IDENTITY_SERVICE_URL", "http://localhost:8081")
	financeURL := getEnv("FINANCE_SERVICE_URL", "http://localhost:8082")
	communityURL := getEnv("COMMUNITY_SERVICE_URL", "http://localhost:8083")
	iotURL := getEnv("IOT_SERVICE_URL", "http://localhost:8084")
	notificationURL := getEnv("NOTIFICATION_SERVICE_URL", "http://localhost:8085")
	expenseURL := getEnv("EXPENSE_SERVICE_URL", "http://localhost:8086")
	assetURL := getEnv("ASSET_SERVICE_URL", "http://localhost:8087")
	bulletinURL := getEnv("BULLETIN_SERVICE_URL", "http://localhost:8089")
	contractURL := getEnv("CONTRACT_SERVICE_URL", "http://localhost:8090")
	documentURL := getEnv("DOCUMENT_SERVICE_URL", "http://localhost:8091")
	energyURL := getEnv("ENERGY_SERVICE_URL", "http://localhost:8092")
	esgURL := getEnv("ESG_SERVICE_URL", "http://localhost:8093")
	inventoryURL := getEnv("INVENTORY_SERVICE_URL", "http://localhost:8094")
	meetingURL := getEnv("MEETING_SERVICE_URL", "http://localhost:8095")
	npsURL := getEnv("NPS_SERVICE_URL", "http://localhost:8096")
	packageURL := getEnv("PACKAGE_SERVICE_URL", "http://localhost:8097")
	parkingURL := getEnv("PARKING_SERVICE_URL", "http://localhost:8098")
	patrolURL := getEnv("PATROL_SERVICE_URL", "http://localhost:8099")
	personnelURL := getEnv("PERSONNEL_SERVICE_URL", "http://localhost:8100")
	reservationURL := getEnv("RESERVATION_SERVICE_URL", "http://localhost:8101")
	settingsURL := getEnv("SETTINGS_SERVICE_URL", "http://localhost:8102")
	smartCollectionURL := getEnv("SMART_COLLECTION_SERVICE_URL", "http://localhost:8103")
	surveyURL := getEnv("SURVEY_SERVICE_URL", "http://localhost:8104")
	visitorURL := getEnv("VISITOR_SERVICE_URL", "http://localhost:8105")
	port := getEnv("PORT", "8888")

	mux := http.NewServeMux()

	// Health
	mux.Handle("/health", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{
			Success: true,
			Message: "SiteEksen API Gateway çalışıyor",
			Data:    map[string]interface{}{"version": "1.2.0", "time": time.Now().Format(time.RFC3339)},
		})
	}))

	// --- IDENTITY SERVICE (8081) ---
	proxyPaths(mux, newProxy(identityURL), "/api/v1/auth", "/api/v1/users", "/api/v1/residents", "/api/v1/units")

	// --- FINANCE SERVICE (8082) ---
	proxyPaths(mux, newProxy(financeURL), "/api/v1/finance", "/api/v1/assessments", "/api/v1/payments")

	// --- COMMUNITY SERVICE (8083) ---
	proxyPaths(mux, newProxy(communityURL), "/api/v1/announcements", "/api/v1/requests")

	// --- IOT SERVICE (8084) ---
	proxyPaths(mux, newProxy(iotURL), "/api/v1/sensors", "/api/v1/iot")

	// --- NOTIFICATION SERVICE (8085) ---
	proxyPaths(mux, newProxy(notificationURL), "/api/v1/notifications")

	// --- EXPENSE SERVICE (8086) ---
	proxyPaths(mux, newProxy(expenseURL), "/api/v1/expenses", "/api/v1/expense-categories")

	// --- ASSET SERVICE (8087) ---
	proxyPaths(mux, newProxy(assetURL), "/api/v1/assets")

	// --- BULLETIN SERVICE (8089) ---
	proxyPaths(mux, newProxy(bulletinURL), "/api/v1/bulletin")

	// --- CONTRACT SERVICE (8090) ---
	proxyPaths(mux, newProxy(contractURL), "/api/v1/contracts")

	// --- DOCUMENT SERVICE (8091) ---
	proxyPaths(mux, newProxy(documentURL), "/api/v1/documents")

	// --- ENERGY SERVICE (8092) ---
	proxyPaths(mux, newProxy(energyURL), "/api/v1/energy")

	// --- ESG SERVICE (8093) ---
	proxyPaths(mux, newProxy(esgURL), "/api/v1/esg")

	// --- INVENTORY SERVICE (8094) ---
	proxyPaths(mux, newProxy(inventoryURL), "/api/v1/inventory")

	// --- MEETING SERVICE (8095) ---
	proxyPaths(mux, newProxy(meetingURL), "/api/v1/meetings")

	// --- NPS SERVICE (8096) ---
	proxyPaths(mux, newProxy(npsURL), "/api/v1/nps")

	// --- PACKAGE SERVICE (8097) ---
	proxyPaths(mux, newProxy(packageURL), "/api/v1/packages")

	// --- PARKING SERVICE (8098) ---
	proxyPaths(mux, newProxy(parkingURL), "/api/v1/parking")

	// --- PATROL SERVICE (8099) ---
	proxyPaths(mux, newProxy(patrolURL), "/api/v1/patrol")

	// --- PERSONNEL SERVICE (8100) ---
	proxyPaths(mux, newProxy(personnelURL), "/api/v1/personnel")

	// --- RESERVATION SERVICE (8101) ---
	proxyPaths(mux, newProxy(reservationURL), "/api/v1/reservations")

	// --- SETTINGS SERVICE (8102) ---
	proxyPaths(mux, newProxy(settingsURL), "/api/v1/credentials")

	// --- SMART COLLECTION SERVICE (8103) ---
	proxyPaths(mux, newProxy(smartCollectionURL), "/api/v1/smart-collection")

	// --- SURVEY SERVICE (8104) ---
	proxyPaths(mux, newProxy(surveyURL), "/api/v1/surveys")

	// --- VISITOR SERVICE (8105) ---
	proxyPaths(mux, newProxy(visitorURL), "/api/v1/visitors")

	// --- MOCK: Aggregate / henüz gerçek servisi olmayan endpointler ---

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
	log.Printf("SiteEksen API Gateway v1.2.0 başlatıldı: http://localhost%s", addr)
	log.Fatal(http.ListenAndServe(addr, handler))
}
