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
	"strconv"
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
		// JETON İPTALİ (FAZ 2.7) burada DEĞİL, aşağı akış servislerinde denetlenir.
		//
		// Gerekçe: iptal denetimi veritabanı sorgusu ister; gateway'in veritabanı
		// bağlantısı yoktur ve olmaması bilinçlidir (kapı katmanı, veri katmanına
		// bağımlı olmamalı). Gateway her isteği Authorization başlığıyla birlikte
		// ilgili servise iletir; iptal edilmiş jeton orada 401 alır.
		//
		// Gateway'in kendi ürettiği özet uçları da aynı başlığı aşağı akışa
		// taşıdığı için iptal edilmiş jetonla veri dönmez.
		_ = claims

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
	governanceURL := getEnv("GOVERNANCE_SERVICE_URL", "http://localhost:8107")
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

	// --- YÖNLENDİRME TABLOSU ---
	//
	// Her satır: servis adresi → o servisin GERÇEKTEN kaydettiği rota ön ekleri.
	// Bu tablo elle tutulur ama DOĞRULANIR: backend/scripts/check-gateway-routes.py
	// her servisin main.go'sundaki rotaları çözer ve (1) her rotanın burada bir ön
	// eke düştüğünü, (2) doğru servise gittiğini, (3) ölü ön ek kalmadığını denetler
	// (verify-stack.sh). Önceki sürümde ayarlar, devriye, ilan panosu, sayaç okuma,
	// bildirim tercihleri ve modül özetleri hiç yönlendirilmiyordu; yalnızca
	// servisler doğrudan sınandığı için bu fark edilmemişti.
	routes := []struct {
		url      string
		prefixes []string
	}{
		{identityURL, []string{"/api/v1/auth", "/api/v1/users", "/api/v1/residents", "/api/v1/units"}},
		{financeURL, []string{"/api/v1/finance"}},
		{communityURL, []string{"/api/v1/announcements", "/api/v1/requests"}},
		{iotURL, []string{"/api/v1/meters", "/api/v1/meter-readings", "/api/v1/consumption",
			"/api/v1/sensors", "/api/v1/iot"}},
		{notificationURL, []string{"/api/v1/notifications", "/api/v1/notification-preferences"}},
		{expenseURL, []string{"/api/v1/expenses", "/api/v1/expense-categories"}},
		{assetURL, []string{"/api/v1/assets", "/api/v1/assets-summary", "/api/v1/asset-categories"}},
		{bulletinURL, []string{"/api/v1/bulletins", "/api/v1/bulletins-summary", "/api/v1/bulletin-comments"}},
		{contractURL, []string{"/api/v1/contracts", "/api/v1/contracts-summary"}},
		{documentURL, []string{"/api/v1/documents", "/api/v1/documents-summary"}},
		{energyURL, []string{"/api/v1/energy"}},
		{esgURL, []string{"/api/v1/esg"}},
		{inventoryURL, []string{"/api/v1/inventory", "/api/v1/inventory-categories",
			"/api/v1/inventory-movements", "/api/v1/inventory-summary"}},
		{meetingURL, []string{"/api/v1/meetings", "/api/v1/action-items"}},
		{npsURL, []string{"/api/v1/nps"}},
		{packageURL, []string{"/api/v1/packages", "/api/v1/packages-summary"}},
		{parkingURL, []string{"/api/v1/vehicles", "/api/v1/parking-zones", "/api/v1/parking-logs"}},
		{patrolURL, []string{"/api/v1/patrols", "/api/v1/patrols-summary", "/api/v1/patrol-routes",
			"/api/v1/patrol-checkpoints"}},
		{personnelURL, []string{"/api/v1/employees", "/api/v1/leaves"}},
		{reservationURL, []string{"/api/v1/reservations", "/api/v1/facilities"}},
		{settingsURL, []string{"/api/v1/settings", "/api/v1/settings-history", "/api/v1/credentials",
			"/api/v1/credentials-available-services"}},
		{smartCollectionURL, []string{"/api/v1/collection"}},
		{surveyURL, []string{"/api/v1/surveys"}},
		{visitorURL, []string{"/api/v1/visitors"}},
		{bankingURL, []string{"/api/v1/banking", "/api/v1/bank-accounts", "/api/v1/bank-transactions"}},
		{governanceURL, []string{"/api/v1/governance"}},
	}
	for _, rt := range routes {
		proxyPaths(mux, newProxy(rt.url), rt.prefixes...)
	}

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
//
// DÜZELTME (2026-09-26): önceki sürüm servis yanıtlarını DÜZ DİZİ bekliyordu;
// servisler ise {"data": [...]} döndürüyor. Sonuç: sakin, daire ve talep sayısı
// HİÇBİR ZAMAN gelmiyor, hepsi "unavailable" listesinde görünüyordu. Tahsilat
// özeti de var olmayan anahtarlardan (total_collected, collection_rate)
// okunuyor ve sessizce boş kalıyordu — "unavailable" listesine bile girmiyordu.
func registerDashboard(mux *http.ServeMux, identityURL, communityURL, financeURL string) {
	mux.Handle("/api/v1/dashboard/stats", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		stats := map[string]interface{}{}
		var missing []unavailable

		if list, err := fetchList(identityURL+"/api/v1/residents", auth); err == nil {
			stats["totalResidents"] = len(list)
		} else {
			missing = append(missing, unavailable{"identity.residents", err.Error()})
		}

		if list, err := fetchList(identityURL+"/api/v1/units", auth); err == nil {
			stats["totalUnits"] = len(list)
		} else {
			missing = append(missing, unavailable{"identity.units", err.Error()})
		}

		if list, err := fetchList(communityURL+"/api/v1/requests", auth); err == nil {
			open := 0
			for _, m := range list {
				// Bekleyen = henüz çözülmemiş: açık ya da işlemde.
				if st, _ := m["status"].(string); st == "OPEN" || st == "IN_PROGRESS" {
					open++
				}
			}
			stats["pendingRequests"] = open
		} else {
			missing = append(missing, unavailable{"community.requests", err.Error()})
		}

		// Tahsilat: EN SON tahakkuk döneminin gerçek toplamları. Dönem yoksa
		// alan yazılmaz ve nedeni söylenir — sıfır "tahsilat yapılmadı" demektir,
		// "tahakkuk yok" ile karıştırılmamalı.
		if list, err := fetchList(financeURL+"/api/v1/finance/assessments/overview", auth); err == nil {
			if len(list) == 0 {
				missing = append(missing, unavailable{"finance.assessments.overview",
					"bu yıl için tahakkuk dönemi yok"})
			} else {
				latest := list[0]
				for _, m := range list[1:] {
					if p, _ := m["period"].(string); p > fmt.Sprint(latest["period"]) {
						latest = m
					}
				}
				stats["period"] = latest["period"]
				stats["monthlyIncome"] = latest["collected_amount"]
				stats["monthlyAssessed"] = latest["total_amount"]
				stats["collectionRate"] = latest["rate"]
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

	// Son hareketler: servis listesi olduğu gibi aktarılır ({success, data: [...]}).
	// Önceden yanıt bir kez daha sarılıyor, istemci data.data okumak zorunda kalıyordu.
	recent := func(url, what string) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			list, err := fetchList(url, r.Header.Get("Authorization"))
			if err != nil {
				// Sessizce boş liste döndürmek "kayıt yok" anlamına gelir — bu yanlıştır.
				writeJSON(w, http.StatusBadGateway, Response{
					Success: false, Error: what + " alınamadı: " + err.Error(),
				})
				return
			}
			limit := 5
			if v, perr := strconv.Atoi(r.URL.Query().Get("limit")); perr == nil && v > 0 && v <= 50 {
				limit = v
			}
			if len(list) > limit {
				list = list[:limit]
			}
			writeJSON(w, http.StatusOK, Response{Success: true, Data: list})
		}
	}
	mux.Handle("/api/v1/dashboard/recent-payments", recent(financeURL+"/api/v1/finance/payments", "Ödeme verisi"))
	mux.Handle("/api/v1/dashboard/recent-requests", recent(communityURL+"/api/v1/requests", "Talep verisi"))

	// Tanımlı olmayan /dashboard/* yolları: boş başarı yerine 404.
	mux.Handle("/api/v1/dashboard/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusNotFound, Response{Success: false, Error: "Bilinmeyen dashboard ucu"})
	}))
}

// fetchList, bir servisin liste ucunu çağırır ve {"data": [...]} sarmalayıcısını
// açar. Servislerin tek liste sözleşmesi budur; "data": null boş liste sayılır.
// 403 ayrıca belirtilir: rolü o listeyi görmeye yetmeyen kullanıcının panosunda
// alanın neden boş olduğu anlaşılsın.
func fetchList(url, authHeader string) ([]map[string]interface{}, error) {
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	if authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	switch resp.StatusCode {
	case http.StatusOK:
	case http.StatusForbidden:
		return nil, fmt.Errorf("bu veriyi görme yetkiniz yok (403)")
	case http.StatusNotImplemented:
		return nil, fmt.Errorf("kaynak henüz uygulanmadı (501)")
	default:
		return nil, fmt.Errorf("beklenmeyen durum kodu: %d", resp.StatusCode)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	var outer struct {
		Data []map[string]interface{} `json:"data"`
	}
	if err := json.Unmarshal(body, &outer); err != nil {
		return nil, fmt.Errorf("yanıt çözülemedi: %w", err)
	}
	if outer.Data == nil {
		return []map[string]interface{}{}, nil
	}
	return outer.Data, nil
}
