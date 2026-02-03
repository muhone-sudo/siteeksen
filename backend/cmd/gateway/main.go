package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

// Basit API Gateway - Demo amaçlı

type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

type LoginRequest struct {
	Phone    string `json:"phone"`
	Password string `json:"password"`
}

type User struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Role     string `json:"role"`
	SiteID   string `json:"site_id"`
	SiteName string `json:"site_name"`
}

// Demo kullanıcılar
var demoUsers = map[string]User{
	"5551234567": {
		ID:       "usr_001",
		Name:     "Ahmet Yönetici",
		Email:    "ahmet@siteeksen.com",
		Phone:    "5551234567",
		Role:     "super_admin",
		SiteID:   "site_001",
		SiteName: "Örnek Sitesi",
	},
	"5559876543": {
		ID:       "usr_002",
		Name:     "Mehmet Sakin",
		Email:    "mehmet@email.com",
		Phone:    "5559876543",
		Role:     "resident",
		SiteID:   "site_001",
		SiteName: "Örnek Sitesi",
	},
}

func main() {
	// CORS middleware
	corsMiddleware := func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}
			next(w, r)
		}
	}

	// Routes
	http.HandleFunc("/api/health", corsMiddleware(healthHandler))
	http.HandleFunc("/api/auth/login", corsMiddleware(loginHandler))
	http.HandleFunc("/api/auth/me", corsMiddleware(meHandler))
	http.HandleFunc("/api/dashboard/stats", corsMiddleware(dashboardHandler))
	http.HandleFunc("/api/residents", corsMiddleware(residentsHandler))
	http.HandleFunc("/api/announcements", corsMiddleware(announcementsHandler))

	port := ":8888"
	fmt.Printf("🚀 SiteEksen API Gateway başlatıldı: http://localhost%s\n", port)
	fmt.Println("📋 Demo kullanıcılar:")
	fmt.Println("   - Tel: 5551234567 / Şifre: demo123 (Süper Admin)")
	fmt.Println("   - Tel: 5559876543 / Şifre: demo123 (Sakin)")

	log.Fatal(http.ListenAndServe(port, nil))
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Message: "SiteEksen API Gateway çalışıyor",
		Data: map[string]interface{}{
			"version": "1.0.0",
			"time":    time.Now().Format(time.RFC3339),
		},
	})
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(Response{Success: false, Error: "Method not allowed"})
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(Response{Success: false, Error: "Geçersiz istek"})
		return
	}

	// Telefon numarasını normalize et
	phone := req.Phone
	// +90 prefix'ini kaldır
	if len(phone) > 2 && phone[:3] == "+90" {
		phone = phone[3:]
	}
	// 0 prefix'ini kaldır
	if len(phone) > 0 && phone[0] == '0' {
		phone = phone[1:]
	}
	fmt.Printf("Login attempt: original=%s, normalized=%s\n", req.Phone, phone)

	// Demo doğrulama
	user, exists := demoUsers[phone]
	if !exists || req.Password != "demo123" {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(Response{
			Success: false,
			Error:   "Telefon numarası veya şifre hatalı",
		})
		return
	}

	// Başarılı giriş
	// NextAuth için düz yanıt yapısı
	json.NewEncoder(w).Encode(map[string]interface{}{
		"access_token":  "demo_token_" + user.ID,
		"refresh_token": "demo_refresh_" + user.ID,
		"user": map[string]interface{}{
			"id":                 user.ID,
			"first_name":         "Ahmet", // Demo için sabit
			"last_name":          "Yönetici",
			"email":              user.Email,
			"phone":              user.Phone,
			"roles":              []string{user.Role},
			"active_property_id": user.SiteID,
		},
	})
}

func meHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Demo: İlk kullanıcıyı döndür
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Data:    demoUsers["5551234567"],
	})
}

func dashboardHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
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
}

func residentsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Data: []map[string]interface{}{
			{"id": "1", "name": "Ahmet Yılmaz", "unit": "A-12", "phone": "5551234567", "status": "active"},
			{"id": "2", "name": "Mehmet Demir", "unit": "B-05", "phone": "5559876543", "status": "active"},
			{"id": "3", "name": "Ayşe Kaya", "unit": "C-08", "phone": "5553334455", "status": "active"},
		},
	})
}

func announcementsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Success: true,
		Data: []map[string]interface{}{
			{"id": "1", "title": "Su Kesintisi", "content": "Yarın 10:00-14:00 arası bakım çalışması", "date": "2024-02-01", "priority": "high"},
			{"id": "2", "title": "Genel Kurul", "content": "15 Şubat'ta genel kurul toplantısı", "date": "2024-02-01", "priority": "normal"},
		},
	})
}
