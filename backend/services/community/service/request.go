package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/community/models"
	"github.com/siteeksen/backend/services/community/repository"
)

// Servis seviyesi hatalar
var (
	ErrForbidden         = errors.New("bu işlem için yetkiniz yok")
	ErrInvalidTransition = errors.New("geçersiz durum geçişi")
)

// RequestService talep iş kuralları
type RequestService struct {
	repo *repository.RequestRepository
}

// NewRequestService yeni servis oluşturur
func NewRequestService(repo *repository.RequestRepository) *RequestService {
	return &RequestService{repo: repo}
}

// canSeeAll: site genelindeki talepleri görebilen roller.
func canSeeAll(roles []string) bool {
	for _, role := range roles {
		switch role {
		case middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor, middleware.RoleStaff:
			return true
		}
	}
	return false
}

// canAdvance: talebi iş akışında ilerletebilen roller. Denetçi (AUDITOR) YOK:
// denetler, yönetmez (KMK m.41). Önceden okuma ve yazma aynı listeydi; denetçi
// talebi "çözüldü" yapabiliyor, kurul üyesi ise talepleri hiç göremiyordu.
func canAdvance(roles []string) bool {
	for _, role := range roles {
		switch role {
		case middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff:
			return true
		}
	}
	return false
}

// List rol bazlı talep listesi döner: yönetim site genelini, sakin yalnızca kendi taleplerini görür
func (s *RequestService) List(ctx context.Context, userID, propertyID string, roles []string, status string) ([]*models.Request, error) {
	if canSeeAll(roles) {
		return s.repo.ListByProperty(ctx, propertyID, status)
	}
	return s.repo.ListByResident(ctx, propertyID, userID, status)
}

// Create sakin adına yeni talep oluşturur
func (s *RequestService) Create(ctx context.Context, userID, propertyID string, input models.CreateRequestInput) (*models.Request, error) {
	ticketNumber := fmt.Sprintf("TLP-%s", strings.ToUpper(uuid.New().String()[:8]))
	return s.repo.Create(ctx, propertyID, userID, ticketNumber, input)
}

// allowedStatusTransitions yöneticinin tetikleyebileceği geçişler.
// CLOSED'a doğrudan geçiş yok — yalnızca sakin onayı (ConfirmResolution) ile mümkündür.
var allowedStatusTransitions = map[string]string{
	models.StatusOpen:       models.StatusInProgress,
	models.StatusInProgress: models.StatusResolved,
}

// UpdateStatus yönetici talebi OPEN -> IN_PROGRESS -> RESOLVED akışında ilerletir
func (s *RequestService) UpdateStatus(ctx context.Context, propertyID, requestID string, roles []string, newStatus string) (*models.Request, error) {
	if !canAdvance(roles) {
		return nil, ErrForbidden
	}

	// GÜVENLİK: talep, isteği yapanın AKTİF SİTESİNE ait olmalı. Yalnızca rol
	// denetlemek yetmez — yönetici olmak, BAŞKA sitenin talebine dokunma
	// yetkisi vermez. Kapsam dışı bir kimlik burada "bulunamadı" döner.
	req, err := s.repo.GetByID(ctx, propertyID, requestID)
	if err != nil {
		return nil, err
	}

	if allowedStatusTransitions[req.Status] != newStatus {
		return nil, ErrInvalidTransition
	}

	return s.repo.UpdateStatus(ctx, propertyID, requestID, newStatus)
}

// ConfirmResolution sakinin "sorunum çözüldü" onayını ya da reddini kaydeder.
// Onay: CLOSED + user_confirmed_at. Red: IN_PROGRESS'e geri döner, resolved_at temizlenir.
func (s *RequestService) ConfirmResolution(ctx context.Context, propertyID, requestID, residentID string, approved bool) (*models.Request, error) {
	req, err := s.repo.GetByID(ctx, propertyID, requestID)
	if err != nil {
		return nil, err
	}

	if req.ResidentID != residentID {
		return nil, ErrForbidden
	}
	if req.Status != models.StatusResolved {
		return nil, ErrInvalidTransition
	}

	return s.repo.ConfirmResolution(ctx, propertyID, requestID, approved)
}
