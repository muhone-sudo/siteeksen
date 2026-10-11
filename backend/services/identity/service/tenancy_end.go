package service

// Kiracılığın bitişi (altıncı tur D4, migration 069).
//   - Malik ister → kiracı onaylar ya da reddeder; malik bekleyen isteğini geri çeker.
//   - Kiracı kendi çıkışını bildirir (V1).
//   - Yönetim yolu: belge + şifreyle kimlik onayı + 7 gün itiraz; itirazda askı; tamamla / iptal / geri al (V2, V7).

import (
	"context"
	"strings"

	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// VerifyPassword, işlemi yapanın kimliğini şifresiyle yeniden doğrular (yönetim yolu beyanı).
func (s *AuthService) VerifyPassword(ctx context.Context, userID, password string) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil {
		return ErrWrongPassword
	}
	return nil
}

// AttestationText: yönetim yolunda belge yükleyenin şifresiyle onayladığı beyan (değiştirilemez kayda geçer).
const AttestationText = "Yüklediğim belgenin aslına uygun olduğunu, kiracılığın sona erdiğine dayanak teşkil ettiğini ve " +
	"bu daireyle maliki ya da vekili olarak çıkar ilişkim bulunmadığını beyan ederim. Sahte belge düzenlemenin ya da " +
	"kullanmanın suç olduğunu (TCK m.204–207) biliyorum."

// ConfirmManager: yönetim yolu işlemlerinde yetki ve şifreyle kimlik onayı.
func (s *ResidentService) ConfirmManager(ctx context.Context, userID string, roles []string, password string) error {
	if !canWriteResidents(roles) {
		return ErrResidentForbidden
	}
	if s.auth == nil {
		return ErrResidentForbidden
	}
	return s.auth.VerifyPassword(ctx, userID, password)
}

// OwnerRequestEnd: malik kiracılığın bitmesini ister.
func (s *ResidentService) OwnerRequestEnd(ctx context.Context, propertyID, userID, unitID, reason string) (string, []repository.ContactTarget, error) {
	return s.repo.OwnerRequestEnd(ctx, propertyID, userID, unitID, strings.TrimSpace(reason))
}

// TenantExit: kiracı kendi çıkışını bildirir.
func (s *ResidentService) TenantExit(ctx context.Context, propertyID, userID, unitID, reason string) (string, []repository.ContactTarget, error) {
	return s.repo.TenantExit(ctx, propertyID, userID, unitID, strings.TrimSpace(reason))
}

// TenantRespond: kiracının onayı / reddi.
func (s *ResidentService) TenantRespond(ctx context.Context, userID, id string, approve bool, note string) ([]repository.ContactTarget, error) {
	return s.repo.TenantRespond(ctx, userID, id, approve, strings.TrimSpace(note))
}

// TenantObject: kiracının yönetim yoluna itirazı.
func (s *ResidentService) TenantObject(ctx context.Context, userID, id, reason string) error {
	return s.repo.TenantObject(ctx, userID, id, strings.TrimSpace(reason))
}

// OwnerCancel: malikin isteğini geri çekmesi.
func (s *ResidentService) OwnerCancel(ctx context.Context, userID, id string) error {
	return s.repo.OwnerCancel(ctx, userID, id)
}

// MyEndRequests: kişinin dairelerindeki bitiş istekleri.
func (s *ResidentService) MyEndRequests(ctx context.Context, propertyID, userID string) ([]*repository.EndRequest, error) {
	return s.repo.EndRequestsForUser(ctx, propertyID, userID)
}

// EndRequests: yönetim görünümü.
func (s *ResidentService) EndRequests(ctx context.Context, propertyID string, roles []string) ([]*repository.EndRequest, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.EndRequestsForProperty(ctx, propertyID)
}

// ManagementStart: yönetim yolu (yetki ve şifre ConfirmManager ile önceden doğrulanmış olmalı).
func (s *ResidentService) ManagementStart(ctx context.Context, propertyID, userID, unitID, reason string, d repository.NewDocument) (string, []repository.ContactTarget, error) {
	return s.repo.ManagementStart(ctx, propertyID, userID, unitID, strings.TrimSpace(reason), d)
}

// ManagementNewDocument: askıdaki yönetim yoluna yeni belge.
func (s *ResidentService) ManagementNewDocument(ctx context.Context, propertyID, userID, id string, d repository.NewDocument) ([]repository.ContactTarget, error) {
	return s.repo.ManagementNewDocument(ctx, propertyID, userID, id, d)
}

// ManagementComplete: süresi dolan yönetim yolunu tamamlar.
func (s *ResidentService) ManagementComplete(ctx context.Context, propertyID, userID string, roles []string, id string) ([]repository.ContactTarget, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.ManagementComplete(ctx, propertyID, userID, id)
}

// ManagementCancel: açık yönetim yolunu iptal eder.
func (s *ResidentService) ManagementCancel(ctx context.Context, propertyID, userID string, roles []string, id, note string) error {
	if !canWriteResidents(roles) {
		return ErrResidentForbidden
	}
	return s.repo.ManagementCancel(ctx, propertyID, userID, id, strings.TrimSpace(note))
}

// ManagementReverse: yönetim yoluyla biten kiracılığı geri açar (şifre ConfirmManager ile doğrulanmış olmalı).
func (s *ResidentService) ManagementReverse(ctx context.Context, propertyID, userID, id, reason string) ([]repository.ContactTarget, error) {
	return s.repo.ManagementReverse(ctx, propertyID, userID, id, strings.TrimSpace(reason))
}

// EndDocument: belge üst verisi (indirme yetkisiyle).
func (s *ResidentService) EndDocument(ctx context.Context, propertyID, userID string, roles []string, requestID, documentID string) (*repository.EndDocument, error) {
	return s.repo.EndDocumentFor(ctx, propertyID, userID, requestID, documentID, canReadResidents(roles))
}
