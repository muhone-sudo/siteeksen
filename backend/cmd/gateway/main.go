// SiteEksen API Gateway (geliştirme ortamı)
//
// 2026-09-13 revizyonu — üç kritik sorun giderildi:
//
//  1. KİMLİK DOĞRULAMASI YOKTU. Gateway 25 servise yönlendiriyor ama hiçbir jeton
//     doğrulaması yapmıyordu; maaş, TCKN, IBAN ve API anahtarları token'sız
//     erişilebiliyordu. Artık /api/v1/auth/* dışındaki her yol geçerli bir JWT ister.
//  2. UYDURMA VERİ. /dashboard/stats gerçek servisler erişilemezse sabit sayılar
//     (156 sakin, 245.000 TL gelir) döndürüyordu; /reports/generate ise içi tamamen
//     uydurma olan PDF/Excel üretiyordu (indirilebilir sahte mali rapor).
//     Artık uydurma değer yok; erişilemeyen kaynak açıkça bildirilir.
//  3. İSTEMCİ KİMLİK BAŞLIKLARI. Aşağı akıştaki bazı kodlar X-User-Role gibi
//     başlıklara güveniyordu. Gateway bu başlıkları artık istekten SİLER.
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
	"time"

	"github.com/google/uuid"
	"github.com/siteeksen/backend/pkg/authtoken"
)

// Response, gateway'in kendi ürettiği yanıtların sözleşmesidir.
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// unavailable, bir veri kaynağına ulaşılamadığında istemciye bildirilen kayıttır.
// Uydurma değer üretmek yerine "bu kaynak şu an yok" demek için vardır.
type unavailable struct {
	Source string `json:"source"`
	Reason string `json:"reason"`
}

// İstemciden gelmesi YASAK başlıklar: aşağı akış servisleri bunlara güvenmemeli,
// güvenenler de istemci tarafından kandırılamamalı.
var strippedRequestHeaders = []string{
	"X-User-Id", "X-User-Role", "X-User-Roles", "X-Property-Id", "X-Tenant-Id",
	"X-Forwarded-User", "X-Auth-Request-User",
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
		writeJSON(w, http.StatusBadGateway, Response{Success: false, Error: "Servis şu an erişilemiyor"})
	}
	return proxy
}

func writeJSON(w http.ResponseWriter, status int, body interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Printf("[gateway] yanıt yazılamadı: %v", err)
	}
}

// corsMiddleware — köken allowlist'i.
// Önceki sürüm her kökene `*` veriyordu; kimlik doğrulaması eklendiği için artık
// yalnızca yapılandırılmış kökenlere izin verilir (CORS_ALLOWED_ORIGINS).
func corsMiddleware(allowed []string, next http.Handler) http.Handler {
	allowedSet := make(map[string]bool, len(allowed))
	for _, o := range allowed {
		allowedSet[strings.TrimSpace(o)] = true
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin != "" && allowedSet[origin] {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Set("Vary", "Origin")
			w.Header().Set("Access-Control-Allow-Credentials", "true")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Request-Id")
		}
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// requestIDMiddleware — her isteğe izlenebilir bir kimlik verir (FAZ 3.5).
// Denetim izi (audit_logs.request_id) bu değeri kullanır.
func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rid := r.Header.Get("X-Request-Id")
		if rid == "" {
			rid = uuid.NewString()
			r.Header.Set("X-Request-Id", rid)
		}
		w.Header().Set("X-Request-Id", rid)
		next.ServeHTTP(w, r)
	})
}

func logMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s (%s)", r.Method, r.URL.Path, time.Since(start).Round(time.Millisecond))
	})
}

func stripSpoofableHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		for _, h := range strippedRequestHeaders {
			r.Header.Del(h)
		}
		next.ServeHTTP(w, r)
	})
}

// isPublicPath — kimlik doğrulaması gerektirmeyen yollar.
// Bilerek çok dar tutulmuştur: yeni bir yol eklemek bilinçli bir karar olmalıdır.
func isPublicPath(p string) bool {
	switch p {
	case "/health", "/":
		return true
	}
	return strings.HasPrefix(p, "/api/v1/auth/")
}

// authMiddleware — gateway'in kimlik kapısı.
// JWT_SECRET tanımlı değilse istek REDDEDİLİR (fail-closed); boş anahtarla
// doğrulama yapmak saldırgana istediği kimliği üretme imkânı verir.
func authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if isPublicPath(r.URL.Path) {
			next.ServeHTTP(w, r)
			return
		}

		claims, err := authtoken.ParseAuthHeader(r.Header.Get("Authorization"))
		if err != nil {
			if err == authtoken.ErrNoSecret {
				log.Printf("[gateway] KRİTİK: JWT_SECRET tanımlı değil — kimlik doğrulama yapılamıyor")
				writeJSON(w, http.StatusInternalServerError, Response{
					Success: false, Error: "Sunucu kimlik doğrulama yapılandırması eksik",
				})
				return
			}
			writeJSON(w, http.StatusUnauthorized, Response{Success: false, Error: err.Error()})
			return
		}
		_ = claims // Aşağı akış servisleri jetonu kendileri de doğrular; gateway kapı görevi görür.

		next.ServeHTTP(w, r)
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

// notImplemented — gateway düzeyinde kalıcı olmayan uçlar için 501.
// pkg/stub ile aynı sözleşme (o paket gin'e bağlı olduğu için burada elle yazıldı).
func notImplemented(w http.ResponseWriter, module, detail string) {
	w.Header().Set("X-SiteEksen-Not-Implemented", "true")
	writeJSON(w, http.StatusNotImplemented, map[string]interface{}{
		"error":   "not_implemented",
		"module":  module,
		"message": "Bu uç noktası henüz gerçek veri katmanına bağlanmamıştır. İstek İŞLENMEDİ.",
		"detail":  detail,
		"docs":    "tasks/todo.md (FAZ 4/5)",
	})
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
	corsOrigins := strings.Split(getEnv("CORS_ALLOWED_ORIGINS",
		"http://localhost:3000,http://localhost:3001"), ",")

	if _, err := authtoken.Secret(); err != nil {
		log.Printf("[gateway] UYARI: JWT_SECRET tanımlı değil. " +
			"Kimlik doğrulaması gereken tüm istekler 500 ile reddedilecek.")
	}

	mux := http.NewServeMux()

	// Health (herkese açık)
	mux.Handle("/health", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, secretErr := authtoken.Secret()
		writeJSON(w, http.StatusOK, Response{
			Success: true,
			Message: "SiteEksen API Gateway çalışıyor",
			Data: map[string]interface{}{
				"version":         "1.3.0",
				"time":            time.Now().Format(time.RFC3339),
				"auth_configured": secretErr == nil,
			},
		})
	}))

	// --- IDENTITY SERVICE (8081) ---
	proxyPaths(mux, newProxy(identityURL), "/api/v1/auth", "/api/v1/users", "/api/v1/residents")

	// units yolu identity ile package servisi arasında paylaşılıyor
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
	proxyPaths(mux, newProxy(parkingURL), "/api/v1/parking", "/api/v1/vehicles",
		"/api/v1/parking-zones", "/api/v1/parking-logs", "/api/v1/plate-recognition")

	// --- PATROL SERVICE (8099) ---
	proxyPaths(mux, newProxy(patrolURL), "/api/v1/patrol", "/api/v1/patrol-routes", "/api/v1/patrol-sessions")

	// --- PERSONNEL SERVICE (8100) ---
	proxyPaths(mux, newProxy(personnelURL), "/api/v1/personnel", "/api/v1/employees",
		"/api/v1/payroll", "/api/v1/leaves")

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

	// --- TOPLU (aggregate) UÇLAR ---
	// Bu uçlar birden çok servisten veri toplar. Hiçbir kaynağa ulaşılamazsa
	// UYDURMA DEĞER ÜRETİLMEZ; ilgili alan yanıtta yer almaz ve `unavailable`
	// listesinde nedeniyle birlikte bildirilir.
	registerDashboard(mux, identityURL, communityURL, financeURL)

	// Rapor üretimi: gateway'de uydurma mali rapor üretiliyordu (sabit daire, sakin
	// adı ve tutarlarla indirilebilir PDF/Excel). Kaldırıldı. Gerçek rapor üretimi
	// finance-service içinde, veritabanı verisiyle yapılacaktır (FAZ 4/6).
	mux.Handle("/api/v1/reports/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		notImplemented(w, "reports",
			"Rapor üretimi gerçek mali veriye bağlanana kadar kapalıdır. "+
				"Önceki sürüm uydurma tutarlarla PDF/Excel üretiyordu; bu kaldırıldı.")
	}))
	mux.Handle("/api/v1/reports", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		notImplemented(w, "reports", "Rapor üretimi gerçek mali veriye bağlanana kadar kapalıdır.")
	}))

	handler := requestIDMiddleware(
		logMiddleware(
			corsMiddleware(corsOrigins,
				stripSpoofableHeaders(
					authMiddleware(mux)))))

	addr := fmt.Sprintf(":%s", port)
	log.Printf("SiteEksen API Gateway v1.3.0 başlatıldı: http://localhost%s (CORS: %v)", addr, corsOrigins)
	log.Fatal(http.ListenAndServe(addr, handler))
}

// registerDashboard, panel ana ekranının özet uçlarını kaydeder.
func registerDashboard(mux *http.ServeMux, identityURL, communityURL, financeURL string) {
	mux.Handle("/api/v1/dashboard/stats", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		stats := map[string]interface{}{}
		var missing []unavailable

		var residents []interface{}
		if err := fetchJSON(identityURL+"/api/v1/residents", auth, &residents); err == nil {
			stats["totalResidents"] = len(residents)
		} else {
			missing = append(missing, unavailable{"identity.residents", err.Error()})
		}

		var units []interface{}
		if err := fetchJSON(identityURL+"/api/v1/units", auth, &units); err == nil {
			stats["totalUnits"] = len(units)
		} else {
			missing = append(missing, unavailable{"identity.units", err.Error()})
		}

		var requests []interface{}
		if err := fetchJSON(communityURL+"/api/v1/requests", auth, &requests); err == nil {
			open := 0
			for _, v := range requests {
				if m, ok := v.(map[string]interface{}); ok && m["status"] == "OPEN" {
					open++
				}
			}
			stats["pendingRequests"] = open
		} else {
			missing = append(missing, unavailable{"community.requests", err.Error()})
		}

		// Tahsilat oranı ve dönem geliri yalnızca gerçek mali özetten gelir.
		var overview map[string]interface{}
		if err := fetchJSON(financeURL+"/api/v1/finance/assessments/overview", auth, &overview); err == nil {
			if v, ok := overview["total_collected"]; ok {
				stats["monthlyIncome"] = v
			}
			if v, ok := overview["collection_rate"]; ok {
				stats["collectionRate"] = v
			}
		} else {
			missing = append(missing, unavailable{"finance.assessments.overview", err.Error()})
		}

		writeJSON(w, http.StatusOK, map[string]interface{}{
			"success":     true,
			"data":        stats,
			"unavailable": missing,
			"partial":     len(missing) > 0,
		})
	}))

	mux.Handle("/api/v1/dashboard/recent-payments", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		var payments interface{}
		if err := fetchJSON(financeURL+"/api/v1/finance/payments", auth, &payments); err != nil {
			// Sessizce boş liste döndürmek "ödeme yok" anlamına gelir — bu yanlıştır.
			writeJSON(w, http.StatusBadGateway, Response{
				Success: false, Error: "Ödeme verisi alınamadı: " + err.Error(),
			})
			return
		}
		writeJSON(w, http.StatusOK, Response{Success: true, Data: payments})
	}))

	mux.Handle("/api/v1/dashboard/recent-requests", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		var requests interface{}
		if err := fetchJSON(communityURL+"/api/v1/requests", auth, &requests); err != nil {
			writeJSON(w, http.StatusBadGateway, Response{
				Success: false, Error: "Talep verisi alınamadı: " + err.Error(),
			})
			return
		}
		writeJSON(w, http.StatusOK, Response{Success: true, Data: requests})
	}))

	// Tanımlı olmayan /dashboard/* yolları: boş başarı yerine 404.
	mux.Handle("/api/v1/dashboard/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusNotFound, Response{Success: false, Error: "Bilinmeyen dashboard ucu"})
	}))
}

func fetchJSON(url string, authHeader string, target interface{}) error {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	if authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusNotImplemented {
		return fmt.Errorf("kaynak henüz uygulanmadı (501)")
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("beklenmeyen durum kodu: %d", resp.StatusCode)
	}

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	// Servisler yanıtı {success, data} sarmalayıcısıyla döndürebiliyor.
	var outer struct {
		Success bool            `json:"success"`
		Data    json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(bodyBytes, &outer); err == nil && outer.Success && len(outer.Data) > 0 {
		return json.Unmarshal(outer.Data, target)
	}
	return json.Unmarshal(bodyBytes, target)
}
