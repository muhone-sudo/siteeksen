package service

import (
	"context"
	"crypto/rand"
	"errors"

	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// ErrResidentForbidden yalnızca yönetim rollerinin yapabileceği bir işlem denendiğinde döner
var ErrResidentForbidden = errors.New("bu işlem için yetkiniz yok")

const tempPasswordChars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789"
const tempPasswordLength = 10

// ResidentService sakin yönetimi iş kuralları
type ResidentService struct {
	repo *repository.ResidentRepository
}

// NewResidentService yeni servis oluşturur
func NewResidentService(repo *repository.ResidentRepository) *ResidentService {
	return &ResidentService{repo: repo}
}

func isResidentManagement(roles []string) bool {
	for _, role := range roles {
		switch role {
		case middleware.RoleManager, middleware.RoleAuditor, middleware.RoleStaff:
			return true
		}
	}
	return false
}

// List bir sitedeki sakinleri filtreleyerek getirir (yalnızca yönetim)
func (s *ResidentService) List(ctx context.Context, propertyID string, roles []string, search, block, role string) ([]*models.Resident, error) {
	if !isResidentManagement(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.List(ctx, propertyID, search, block, role)
}

// Get sakin detayını getirir (yalnızca yönetim)
func (s *ResidentService) Get(ctx context.Context, propertyID, id string, roles []string) (*models.Resident, error) {
	if !isResidentManagement(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.GetByID(ctx, propertyID, id)
}

// Create yeni sakin oluşturur; telefon numarası sistemde yoksa rastgele geçici şifreyle hesap açılır
func (s *ResidentService) Create(ctx context.Context, propertyID string, roles []string, input models.CreateResidentInput) (*models.Resident, error) {
	if !isResidentManagement(roles) {
		return nil, ErrResidentForbidden
	}

	tempPassword, err := generateTempPassword()
	if err != nil {
		return nil, err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(tempPassword), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	return s.repo.Create(ctx, propertyID, string(hash), input)
}

// Update sakinin rol/aktiflik bilgisini günceller (yalnızca yönetim)
func (s *ResidentService) Update(ctx context.Context, propertyID, id string, roles []string, input models.UpdateResidentInput) (*models.Resident, error) {
	if !isResidentManagement(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.Update(ctx, propertyID, id, input)
}

// ListUnits bir sitedeki birimleri getirir (yalnızca yönetim)
func (s *ResidentService) ListUnits(ctx context.Context, propertyID string, roles []string) ([]*models.Unit, error) {
	if !isResidentManagement(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.ListUnits(ctx, propertyID)
}

// generateTempPassword sakin için rastgele bir geçici şifre üretir.
// Sakin ilk girişte SMS/OTP doğrulamasıyla kendi şifresini belirleyebilir.
func generateTempPassword() (string, error) {
	buf := make([]byte, tempPasswordLength)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	for i, b := range buf {
		buf[i] = tempPasswordChars[int(b)%len(tempPasswordChars)]
	}
	return string(buf), nil
}
