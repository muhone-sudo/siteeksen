package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/siteeksen/backend/pkg/reports"
)

type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

var (
	reportsMutex     sync.RWMutex
	generatedReports = make(map[string]struct {
		Filename string
		Data     []byte
		MimeType string
	})
)

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
	bankingURL := getEnv("BANKING_SERVICE_URL", "http://localhost:8106")
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
	proxyPaths(mux, newProxy(identityURL), "/api/v1/auth", "/api/v1/users", "/api/v1/residents")
	
	// Custom units routing to separate identity vs package services
	unitsProxy := newProxy(identityURL)
	packageProxy := newProxy(packageURL)
	mux.Handle("/api/v1/units", unitsProxy)
	mux.Handle("/api/v1/units/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.Contains(r.URL.Path, "/packages") {
			packageProxy.ServeHTTP(w, r)
		} else {
			unitsProxy.ServeHTTP(w, r)
		}
	}))

	// --- FINANCE SERVICE (8082) ---
	proxyPaths(mux, newProxy(financeURL), "/api/v1/finance", "/api/v1/assessments", "/api/v1/payments")

	// --- COMMUNITY SERVICE (8083) ---
	proxyPaths(mux, newProxy(communityURL), "/api/v1/announcements", "/api/v1/requests")

	// --- IOT SERVICE (8084) ---
	proxyPaths(mux, newProxy(iotURL), "/api/v1/sensors", "/api/v1/iot", "/api/v1/meters")

	// --- NOTIFICATION SERVICE (8085) ---
	proxyPaths(mux, newProxy(notificationURL), "/api/v1/notifications")

	// --- EXPENSE SERVICE (8086) ---
	proxyPaths(mux, newProxy(expenseURL), "/api/v1/expenses", "/api/v1/expense-categories")

	// --- ASSET SERVICE (8087) ---
	proxyPaths(mux, newProxy(assetURL), "/api/v1/assets", "/api/v1/asset-categories")

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
	proxyPaths(mux, newProxy(inventoryURL), "/api/v1/inventory", "/api/v1/stock-movements")

	// --- MEETING SERVICE (8095) ---
	proxyPaths(mux, newProxy(meetingURL), "/api/v1/meetings")

	// --- NPS SERVICE (8096) ---
	proxyPaths(mux, newProxy(npsURL), "/api/v1/nps")

	// --- PACKAGE SERVICE (8097) ---
	proxyPaths(mux, newProxy(packageURL), "/api/v1/packages", "/api/v1/carriers")

	// --- PARKING SERVICE (8098) ---
	proxyPaths(mux, newProxy(parkingURL), "/api/v1/parking", "/api/v1/vehicles", "/api/v1/parking-zones", "/api/v1/parking-logs", "/api/v1/plate-recognition")

	// --- PATROL SERVICE (8099) ---
	proxyPaths(mux, newProxy(patrolURL), "/api/v1/patrol", "/api/v1/patrol-routes", "/api/v1/patrol-sessions")

	// --- PERSONNEL SERVICE (8100) ---
	proxyPaths(mux, newProxy(personnelURL), "/api/v1/personnel", "/api/v1/employees", "/api/v1/payroll", "/api/v1/leaves")

	// --- RESERVATION SERVICE (8101) ---
	proxyPaths(mux, newProxy(reservationURL), "/api/v1/reservations", "/api/v1/facilities")

	// --- SETTINGS SERVICE (8102) ---
	proxyPaths(mux, newProxy(settingsURL), "/api/v1/credentials")

	// --- SMART COLLECTION SERVICE (8103) ---
	proxyPaths(mux, newProxy(smartCollectionURL), "/api/v1/smart-collection", "/api/v1/collection")

	// --- SURVEY SERVICE (8104) ---
	proxyPaths(mux, newProxy(surveyURL), "/api/v1/surveys", "/api/v1/my-surveys")

	// --- VISITOR SERVICE (8105) ---
	proxyPaths(mux, newProxy(visitorURL), "/api/v1/visitors")

	// --- BANKING SERVICE (8106) ---
	proxyPaths(mux, newProxy(bankingURL), "/api/v1/bank-accounts", "/api/v1/bank-transactions", "/api/v1/banking")

	// --- MOCK: Aggregate / henüz gerçek servisi olmayan endpointler ---

	mux.Handle("/api/v1/dashboard/stats", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		stats := map[string]interface{}{
			"totalResidents":   156,
			"totalUnits":       180,
			"monthlyIncome":    245000,
			"pendingRequests":  12,
			"occupancyRate":    87,
			"collectionRate":   94,
			"activeVisitors":   3,
			"upcomingMeetings": 2,
		}

		// 1. Residents Count
		var residents []interface{}
		if err := fetchJSON(identityURL+"/api/v1/residents", auth, &residents); err == nil {
			stats["totalResidents"] = len(residents)
		}

		// 2. Units Count
		var units []interface{}
		if err := fetchJSON(identityURL+"/api/v1/units", auth, &units); err == nil {
			stats["totalUnits"] = len(units)
		}

		// 3. Pending Requests Count
		var requests []interface{}
		if err := fetchJSON(communityURL+"/api/v1/requests", auth, &requests); err == nil {
			// Filter for OPEN requests
			openCount := 0
			for _, reqVal := range requests {
				if reqMap, ok := reqVal.(map[string]interface{}); ok {
					if reqMap["status"] == "OPEN" {
						openCount++
					}
				}
			}
			stats["pendingRequests"] = openCount
		}

		// 4. Active Visitors
		var visitors []interface{}
		if err := fetchJSON(visitorURL+"/api/v1/visitors", auth, &visitors); err == nil {
			stats["activeVisitors"] = len(visitors)
		}

		// 5. Upcoming Meetings
		var meetings []interface{}
		if err := fetchJSON(meetingURL+"/api/v1/meetings", auth, &meetings); err == nil {
			stats["upcomingMeetings"] = len(meetings)
		}

		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data:    stats,
		})
	}))

	mux.Handle("/api/v1/dashboard/recent-payments", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		var payments interface{}
		if err := fetchJSON(financeURL+"/api/v1/payments", auth, &payments); err == nil {
			json.NewEncoder(w).Encode(Response{Success: true, Data: payments})
		} else {
			json.NewEncoder(w).Encode(Response{Success: true, Data: []interface{}{}})
		}
	}))

	mux.Handle("/api/v1/dashboard/recent-requests", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		var requests interface{}
		if err := fetchJSON(communityURL+"/api/v1/requests", auth, &requests); err == nil {
			json.NewEncoder(w).Encode(Response{Success: true, Data: requests})
		} else {
			json.NewEncoder(w).Encode(Response{Success: true, Data: []interface{}{}})
		}
	}))

	mux.Handle("/api/v1/dashboard/", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(Response{Success: true, Data: map[string]interface{}{}})
	}))



	mux.Handle("/api/v1/reports/generate", jsonHandler(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}
		
		var req struct {
			Type   string                 `json:"type"`
			Params map[string]interface{} `json:"params"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		reportID := fmt.Sprintf("rpt-%d", time.Now().UnixNano())
		var fileBytes []byte
		var err error
		filename := "rapor.pdf"
		mimeType := "application/pdf"

		format := "pdf"
		if req.Params != nil {
			if fmtVal, ok := req.Params["format"].(string); ok {
				format = strings.ToLower(fmtVal)
			}
		}

		if format == "xlsx" || format == "excel" {
			mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
			filename = "rapor.xlsx"
			gen := reports.NewExcelGenerator()
			
			data := &reports.AssessmentReportData{
				PropertyName:   "SiteEksen Yönetim",
				Period:         "Temmuz 2026",
				TotalAssessed:  12500.0,
				TotalCollected: 10000.0,
				TotalPending:   2500.0,
				CollectionRate: 80.0,
				ExpenseItems: []reports.ExpenseItem{
					{Name: "Asansör Bakımı", DistributionType: "EŞİT", Amount: 2500},
					{Name: "Ortak Alan Temizlik", DistributionType: "ARSA_PAYI", Amount: 5000},
					{Name: "Güvenlik", DistributionType: "EŞİT", Amount: 5000},
				},
				UnitAssessments: []reports.UnitAssessment{
					{UnitName: "A Blok Daire 1", ResidentName: "Ahmet Yılmaz", Assessed: 500.0, Paid: 500.0, Balance: 0.0},
					{UnitName: "A Blok Daire 2", ResidentName: "Mehmet Demir", Assessed: 500.0, Paid: 0.0, Balance: 500.0},
				},
			}
			fileBytes, err = gen.GenerateAssessmentExcel(data)
		} else {
			gen := reports.NewPDFGenerator()
			data := &reports.AssessmentReportData{
				PropertyName:   "SiteEksen Yönetim",
				Period:         "Temmuz 2026",
				TotalAssessed:  12500.0,
				TotalCollected: 10000.0,
				TotalPending:   2500.0,
				CollectionRate: 80.0,
				ExpenseItems: []reports.ExpenseItem{
					{Name: "Asansör Bakımı", DistributionType: "EŞİT", Amount: 2500},
					{Name: "Ortak Alan Temizlik", DistributionType: "ARSA_PAYI", Amount: 5000},
					{Name: "Güvenlik", DistributionType: "EŞİT", Amount: 5000},
				},
				UnitAssessments: []reports.UnitAssessment{
					{UnitName: "A Blok Daire 1", ResidentName: "Ahmet Yılmaz", Assessed: 500.0, Paid: 500.0, Balance: 0.0},
					{UnitName: "A Blok Daire 2", ResidentName: "Mehmet Demir", Assessed: 500.0, Paid: 0.0, Balance: 500.0},
				},
			}
			fileBytes, err = gen.GenerateAssessmentReport(data)
		}

		if err != nil {
			json.NewEncoder(w).Encode(Response{Success: false, Error: "Rapor üretilemedi: " + err.Error()})
			return
		}

		reportsMutex.Lock()
		generatedReports[reportID] = struct {
			Filename string
			Data     []byte
			MimeType string
		}{Filename: filename, Data: fileBytes, MimeType: mimeType}
		reportsMutex.Unlock()

		json.NewEncoder(w).Encode(Response{
			Success: true,
			Data: map[string]interface{}{
				"report_id": reportID,
				"status":    "generated",
			},
		})
	}))

	mux.Handle("/api/v1/reports/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		parts := strings.Split(r.URL.Path, "/")
		if len(parts) >= 6 && parts[5] == "download" {
			reportID := parts[4]
			reportsMutex.RLock()
			report, exists := generatedReports[reportID]
			reportsMutex.RUnlock()

			if !exists {
				http.Error(w, "Report not found", http.StatusNotFound)
				return
			}

			w.Header().Set("Content-Type", report.MimeType)
			w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s", report.Filename))
			w.Write(report.Data)
			return
		}

		json.NewEncoder(w).Encode(Response{Success: true, Data: map[string]interface{}{}})
	}))

	handler := logMiddleware(corsMiddleware(mux))

	addr := fmt.Sprintf(":%s", port)
	log.Printf("SiteEksen API Gateway v1.2.0 başlatıldı: http://localhost%s", addr)
	log.Fatal(http.ListenAndServe(addr, handler))
}

func fetchJSON(url string, authHeader string, target interface{}) error {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	if authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("bad status: %d", resp.StatusCode)
	}
	
	// Unpack outer Response wrapper if present
	var outer struct {
		Success bool            `json:"success"`
		Data    json.RawMessage `json:"data"`
		Error   string          `json:"error"`
	}
	
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	
	if err := json.Unmarshal(bodyBytes, &outer); err == nil && outer.Success {
		return json.Unmarshal(outer.Data, target)
	}
	
	return json.Unmarshal(bodyBytes, target)
}
