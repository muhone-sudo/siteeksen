package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"sitesen/backend/services/settings"
)

// APICredentialsHandler API credentials handler
type APICredentialsHandler struct {
	service *settings.Service
}

// NewAPICredentialsHandler yeni handler oluşturur
func NewAPICredentialsHandler(service *settings.Service) *APICredentialsHandler {
	return &APICredentialsHandler{service: service}
}

// ===============================================
// MIDDLEWARE
// ===============================================

// RequireSuperAdmin süper admin rolü gerektirir
func (h *APICredentialsHandler) RequireSuperAdmin(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// TODO: JWT veya session'dan kullanıcı rolü al
		userRole := r.Header.Get("X-User-Role")

		if userRole != "super_admin" {
			h.sendError(w, http.StatusForbidden, "Bu sayfaya erişim yetkiniz yok. Sadece Süper Admin erişebilir.", "FORBIDDEN")
			return
		}

		next(w, r)
	}
}

// ===============================================
// HANDLERS
// ===============================================

// ListCredentials tüm credentialları listeler (maskelenmiş)
// GET /api/v1/settings/credentials
func (h *APICredentialsHandler) ListCredentials(w http.ResponseWriter, r *http.Request) {
	credentials, err := h.service.GetAll(r.Context())
	if err != nil {
		h.sendError(w, http.StatusInternalServerError, "Kimlik bilgileri alınamadı", "FETCH_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusOK, map[string]interface{}{
		"credentials": credentials,
		"total":       len(credentials),
	})
}

// GetCredential tek credential getirir
// GET /api/v1/settings/credentials/{id}
func (h *APICredentialsHandler) GetCredential(w http.ResponseWriter, r *http.Request) {
	id := h.getPathParam(r, "id")
	if id == "" {
		h.sendError(w, http.StatusBadRequest, "ID gereklidir", "MISSING_ID")
		return
	}

	credential, err := h.service.GetByID(r.Context(), id)
	if err != nil {
		h.sendError(w, http.StatusNotFound, "Kimlik bilgisi bulunamadı", "NOT_FOUND")
		return
	}

	h.sendSuccess(w, http.StatusOK, credential)
}

// CreateCredential yeni credential oluşturur
// POST /api/v1/settings/credentials
func (h *APICredentialsHandler) CreateCredential(w http.ResponseWriter, r *http.Request) {
	var req settings.CreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.sendError(w, http.StatusBadRequest, "Geçersiz istek formatı", "INVALID_JSON")
		return
	}

	// Validation
	if req.ServiceName == "" {
		h.sendError(w, http.StatusBadRequest, "Servis adı gereklidir", "MISSING_SERVICE")
		return
	}
	if req.APIKey == "" {
		h.sendError(w, http.StatusBadRequest, "API anahtarı gereklidir", "MISSING_API_KEY")
		return
	}

	userID := r.Header.Get("X-User-ID")
	userName := r.Header.Get("X-User-Name")
	ipAddress := h.getClientIP(r)

	credential, err := h.service.Create(r.Context(), &req, userID, userName, ipAddress)
	if err != nil {
		h.sendError(w, http.StatusInternalServerError, err.Error(), "CREATE_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusCreated, map[string]interface{}{
		"message":    "API anahtarı başarıyla eklendi",
		"credential": credential,
	})
}

// UpdateCredential credential günceller
// PUT /api/v1/settings/credentials/{id}
func (h *APICredentialsHandler) UpdateCredential(w http.ResponseWriter, r *http.Request) {
	id := h.getPathParam(r, "id")
	if id == "" {
		h.sendError(w, http.StatusBadRequest, "ID gereklidir", "MISSING_ID")
		return
	}

	var req settings.UpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.sendError(w, http.StatusBadRequest, "Geçersiz istek formatı", "INVALID_JSON")
		return
	}

	userID := r.Header.Get("X-User-ID")
	userName := r.Header.Get("X-User-Name")
	ipAddress := h.getClientIP(r)

	credential, err := h.service.Update(r.Context(), id, &req, userID, userName, ipAddress)
	if err != nil {
		h.sendError(w, http.StatusInternalServerError, err.Error(), "UPDATE_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusOK, map[string]interface{}{
		"message":    "API anahtarı başarıyla güncellendi",
		"credential": credential,
	})
}

// DeleteCredential credential siler
// DELETE /api/v1/settings/credentials/{id}
func (h *APICredentialsHandler) DeleteCredential(w http.ResponseWriter, r *http.Request) {
	id := h.getPathParam(r, "id")
	if id == "" {
		h.sendError(w, http.StatusBadRequest, "ID gereklidir", "MISSING_ID")
		return
	}

	userID := r.Header.Get("X-User-ID")
	userName := r.Header.Get("X-User-Name")
	ipAddress := h.getClientIP(r)

	if err := h.service.Delete(r.Context(), id, userID, userName, ipAddress); err != nil {
		h.sendError(w, http.StatusInternalServerError, err.Error(), "DELETE_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusOK, map[string]interface{}{
		"message": "API anahtarı başarıyla silindi",
	})
}

// TestCredential bağlantı testi yapar
// POST /api/v1/settings/credentials/{id}/test
func (h *APICredentialsHandler) TestCredential(w http.ResponseWriter, r *http.Request) {
	id := h.getPathParam(r, "id")
	if id == "" {
		h.sendError(w, http.StatusBadRequest, "ID gereklidir", "MISSING_ID")
		return
	}

	userID := r.Header.Get("X-User-ID")
	userName := r.Header.Get("X-User-Name")
	ipAddress := h.getClientIP(r)

	result, err := h.service.TestConnection(r.Context(), id, userID, userName, ipAddress)
	if err != nil {
		h.sendError(w, http.StatusInternalServerError, err.Error(), "TEST_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusOK, result)
}

// GetAuditLog değişiklik geçmişi getirir
// GET /api/v1/settings/credentials/{id}/audit
func (h *APICredentialsHandler) GetAuditLog(w http.ResponseWriter, r *http.Request) {
	id := h.getPathParam(r, "id")
	if id == "" {
		h.sendError(w, http.StatusBadRequest, "ID gereklidir", "MISSING_ID")
		return
	}

	entries, err := h.service.GetAuditLog(r.Context(), id, 50)
	if err != nil {
		h.sendError(w, http.StatusInternalServerError, err.Error(), "AUDIT_ERROR")
		return
	}

	h.sendSuccess(w, http.StatusOK, map[string]interface{}{
		"audit_log": entries,
		"total":     len(entries),
	})
}

// GetAvailableServices yapılandırılabilir servisleri döner
// GET /api/v1/settings/credentials/services
func (h *APICredentialsHandler) GetAvailableServices(w http.ResponseWriter, r *http.Request) {
	services := settings.GetAvailableServices()
	h.sendSuccess(w, http.StatusOK, map[string]interface{}{
		"services": services,
	})
}

// ===============================================
// HELPERS
// ===============================================

func (h *APICredentialsHandler) getPathParam(r *http.Request, param string) string {
	// URL path'ten parametre al
	// Örnek: /api/v1/settings/credentials/123 -> id = "123"
	path := r.URL.Path
	parts := strings.Split(path, "/")

	// Son parça id olmalı
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return ""
}

func (h *APICredentialsHandler) getClientIP(r *http.Request) string {
	// X-Forwarded-For header'ı kontrol et
	xff := r.Header.Get("X-Forwarded-For")
	if xff != "" {
		ips := strings.Split(xff, ",")
		return strings.TrimSpace(ips[0])
	}

	// X-Real-IP header'ı kontrol et
	xri := r.Header.Get("X-Real-IP")
	if xri != "" {
		return xri
	}

	// RemoteAddr kullan
	ip := r.RemoteAddr
	if idx := strings.LastIndex(ip, ":"); idx != -1 {
		ip = ip[:idx]
	}
	return ip
}

func (h *APICredentialsHandler) sendSuccess(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    data,
	})
}

func (h *APICredentialsHandler) sendError(w http.ResponseWriter, status int, message, code string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": false,
		"error": map[string]string{
			"message": message,
			"code":    code,
		},
	})
}

// ===============================================
// ROUTER REGISTRATION
// ===============================================

// RegisterRoutes rotaları kaydeder
func (h *APICredentialsHandler) RegisterRoutes(mux *http.ServeMux) {
	// Tüm rotalar süper admin kontrolü gerektirir
	mux.HandleFunc("GET /api/v1/settings/credentials", h.RequireSuperAdmin(h.ListCredentials))
	mux.HandleFunc("GET /api/v1/settings/credentials/services", h.RequireSuperAdmin(h.GetAvailableServices))
	mux.HandleFunc("GET /api/v1/settings/credentials/{id}", h.RequireSuperAdmin(h.GetCredential))
	mux.HandleFunc("POST /api/v1/settings/credentials", h.RequireSuperAdmin(h.CreateCredential))
	mux.HandleFunc("PUT /api/v1/settings/credentials/{id}", h.RequireSuperAdmin(h.UpdateCredential))
	mux.HandleFunc("DELETE /api/v1/settings/credentials/{id}", h.RequireSuperAdmin(h.DeleteCredential))
	mux.HandleFunc("POST /api/v1/settings/credentials/{id}/test", h.RequireSuperAdmin(h.TestCredential))
	mux.HandleFunc("GET /api/v1/settings/credentials/{id}/audit", h.RequireSuperAdmin(h.GetAuditLog))
}
