package service

// Malikin kendi bölümündeki kiracı/vekil yönetimi (beşinci tur B5, Şikayetvar "daire içi rol yönetimi").
//
// Önceden kiracıyı yalnızca site yönetimi ekleyip çıkarabiliyordu; kiracı değişiminde malik
// yönetimin işlem yapmasını bekliyordu. Artık bölümün AKTİF maliki:
//   - bölümünün sakinlerini görür (telefon maskeli),
//   - kiracı (TENANT) ya da vekil (PROXY) ekler — malik ekleyemez (mülkiyet tapuyla değişir,
//     yönetim işler),
//   - kiracılığı/vekilliği bitirir — maliki ve kendisini çıkaramaz.
// Her işlem denetim izine (audit_logs) çağıranla birlikte yazılır; yönetim sakin listesinde görür.

import (
	"context"
	"errors"

	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
)

var (
	// ErrNotUnitOwner: çağıran bu bölümün aktif maliki değil.
	ErrNotUnitOwner = errors.New("bu bölümün aktif maliki değilsiniz; sakin işlemleri için site yönetimine başvurun")
	// ErrOwnerRole: malik yalnızca kiracı ya da vekil ekleyip çıkarabilir.
	ErrOwnerRole = errors.New("malik yalnızca kiracı (TENANT) ya da vekil (PROXY) ekleyip çıkarabilir; malik değişikliği yönetimce işlenir")
)

var ownerManagedRoles = map[string]bool{"TENANT": true, "PROXY": true}

func (s *ResidentService) requireOwner(ctx context.Context, propertyID, userID, unitID string) error {
	ok, err := s.repo.IsActiveOwner(ctx, propertyID, userID, unitID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrNotUnitOwner
	}
	return nil
}

// OwnerUnitResidents, malikin bölümündeki sakinler.
func (s *ResidentService) OwnerUnitResidents(ctx context.Context, propertyID, ownerID, unitID string) ([]repository.UnitResident, error) {
	if err := s.requireOwner(ctx, propertyID, ownerID, unitID); err != nil {
		return nil, err
	}
	return s.repo.ListUnitResidents(ctx, propertyID, unitID, ownerID)
}

// OwnerAddResident, malikin bölümüne kiracı/vekil ekler (yeni hesapsa etkinleştirme kodu üretilir,
// başka sitede hesabı varsa davet açılır — yönetimin akışıyla aynı).
func (s *ResidentService) OwnerAddResident(ctx context.Context, propertyID, ownerID, unitID string, in models.CreateResidentInput) (*models.CreateResidentResult, error) {
	if err := s.requireOwner(ctx, propertyID, ownerID, unitID); err != nil {
		return nil, err
	}
	if !ownerManagedRoles[in.Role] {
		return nil, ErrOwnerRole
	}
	in.UnitID = unitID
	return s.create(ctx, propertyID, ownerID, in)
}

// OwnerEndResident, malikin bölümündeki kiracılığı/vekilliği bitirir.
func (s *ResidentService) OwnerEndResident(ctx context.Context, propertyID, ownerID, unitID, residentUnitID string) (*models.Resident, error) {
	if err := s.requireOwner(ctx, propertyID, ownerID, unitID); err != nil {
		return nil, err
	}
	link, err := s.repo.GetResidentLink(ctx, propertyID, residentUnitID)
	if err != nil {
		return nil, err
	}
	if link.UnitID != unitID {
		return nil, repository.ErrResidentNotFound
	}
	if !ownerManagedRoles[link.Role] || link.ResidentID == ownerID {
		return nil, ErrOwnerRole
	}
	inactive := false
	return s.repo.Update(ctx, propertyID, residentUnitID, models.UpdateResidentInput{IsActive: &inactive})
}
