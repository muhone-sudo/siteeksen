package service

// Kayıt ve davet (altıncı tur D3, migration 068).
//
// Kullanıcı kararları (2026-10-11):
//   - Kiracıyı malik ya da yönetim davet eder (SMS + e-posta). Yönetim doğrudan da kaydedebilir (Create).
//   - Davet edilen kişinin hesabı yoksa hesap hemen açılır, etkinleştirme kodu gider; kişi kodu girince davet
//     kabul edilir. Hesabı olan kişi uygulamada kabul eder.
//   - Hane üyesini dairede oturan (kiracı ya da oturan malik) ve yönetim ekler; kiracılı dairede malik ekleyemez.
//   - Malik, yalnız kiracıyla kayıtlı daireye (yönetimce) davet edilir.
//   - Kiracılığı malik tek başına bitiremez (kiracının onayı ya da yönetim yolu — D4).

import (
	"context"
	"errors"

	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

var (
	// ErrInviteRole: bu sıfatla bu rol davet edilemez.
	ErrInviteRole = errors.New("bu rolde davet gönderemezsiniz: malik kiracı, vekil ya da (dairede oturuyorsa) hane üyesi; kiracı yalnız hane üyesi davet eder")
	// ErrNotUnitMember: çağıran bu dairenin aktif maliki ya da kiracısı değil.
	ErrNotUnitMember = errors.New("bu dairenin aktif maliki ya da kiracısı değilsiniz; sakin işlemleri için site yönetimine başvurun")
	// ErrTenancyEndNeedsConsent: kiracılık malikin tek taraflı işlemiyle bitmez.
	ErrTenancyEndNeedsConsent = errors.New("kiracılık malikin tek taraflı işlemiyle bitirilemez; kiracının onayı ya da yönetim yolu gerekir")
)

// inviteRoles: yönetimin davet edebileceği roller.
var inviteRoles = map[string]bool{"OWNER": true, "TENANT": true, "PROXY": true, "HOUSEHOLD": true}

// InvitationOutcome, davet sonucu. Etkinleştirme kodu yalnız YÖNETİME gösterilir: malik ya da kiracı,
// davet ettiği kişinin hesabını kendisi etkinleştirememeli (şifresini belirleyememeli).
type InvitationOutcome struct {
	Invitation *models.Invitation `json:"invitation"`
	NewAccount bool               `json:"new_account"`
	Activation *models.Activation `json:"activation,omitempty"`
	Delivery   any                `json:"delivery,omitempty"`
	Note       string             `json:"note"`

	// İletim için (yanıta girmez).
	Code         *models.Activation `json:"-"`
	PropertyName string             `json:"-"`
	Phone        string             `json:"-"`
	Email        string             `json:"-"`
}

func (s *ResidentService) invite(ctx context.Context, propertyID, actorID, invitedAs string, in models.CreateResidentInput, showCode bool) (*InvitationOutcome, error) {
	unusable, err := GenerateCode()
	if err != nil {
		return nil, err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(unusable+unusable), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	res, err := s.repo.CreateInvitation(ctx, propertyID, actorID, invitedAs, string(hash), in)
	if err != nil {
		return nil, err
	}
	out := &InvitationOutcome{Invitation: res.Invitation, NewAccount: res.NewAccount,
		PropertyName: res.PropertyName, Phone: in.Phone, Email: in.Email}
	if !res.NewAccount {
		out.Note = "Kişinin hesabı var; davet uygulamasında görünür, kabul edince daireye bağlanır (14 gün geçerli)."
		return out, nil
	}
	if s.auth == nil {
		out.Note = "Hesap açıldı ama etkinleştirme kodu üretilemedi (yapılandırma eksik); yönetim 'kod üret' ile yeniden denemeli."
		return out, nil
	}
	code, expires, purpose, err := s.auth.IssueActivation(ctx, res.UserID, actorID, false)
	if err != nil {
		return nil, err
	}
	out.Code = activationOf(code, purpose, expires)
	if showCode {
		out.Activation = out.Code
	}
	out.Note = "Kişi için hesap açıldı; etkinleştirme kodu SMS ve e-postayla gönderilir. Kişi kodu girip şifresini " +
		"belirlediğinde davet kabul edilmiş olur ve daireye bağlanır."
	return out, nil
}

// Invite, yönetimin daire daveti (malik, kiracı, vekil, hane üyesi).
func (s *ResidentService) Invite(ctx context.Context, propertyID, actorID string, roles []string, in models.CreateResidentInput) (*InvitationOutcome, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	if !inviteRoles[in.Role] {
		return nil, ErrInvalidResidentRole
	}
	return s.invite(ctx, propertyID, actorID, "MANAGEMENT", in, true)
}

// UnitInvite, dairenin maliki ya da oturanının daveti:
//   - malik: kiracı ve vekil; dairede kendisi oturuyorsa hane üyesi,
//   - kiracı: yalnız hane üyesi.
func (s *ResidentService) UnitInvite(ctx context.Context, propertyID, userID, unitID string, in models.CreateResidentInput) (*InvitationOutcome, error) {
	isOwner, isTenant, occupancy, err := s.repo.UnitRelation(ctx, propertyID, userID, unitID)
	if err != nil {
		return nil, err
	}
	if !isOwner && !isTenant {
		return nil, ErrNotUnitMember
	}
	invitedAs := ""
	switch in.Role {
	case "TENANT", "PROXY":
		if isOwner {
			invitedAs = "OWNER"
		}
	case "HOUSEHOLD":
		if isTenant || (isOwner && occupancy == "OWNER_OCCUPIED") {
			invitedAs = "OCCUPANT"
		}
	}
	if invitedAs == "" {
		return nil, ErrInviteRole
	}
	in.UnitID = unitID
	return s.invite(ctx, propertyID, userID, invitedAs, in, false)
}

// UnitResidents, dairenin maliki ya da kiracısının gördüğü sakin listesi (telefon maskeli).
func (s *ResidentService) UnitResidents(ctx context.Context, propertyID, userID, unitID string) ([]repository.UnitResident, error) {
	isOwner, isTenant, _, err := s.repo.UnitRelation(ctx, propertyID, userID, unitID)
	if err != nil {
		return nil, err
	}
	if !isOwner && !isTenant {
		return nil, ErrNotUnitMember
	}
	return s.repo.ListUnitResidents(ctx, propertyID, unitID, userID)
}

// UnitEndResident: malik vekilliği bitirir; oturan (kiracı ya da oturan malik) kendi hanesinin üyesinin kaydını
// bitirir. Kiracılık bu yoldan bitmez (ErrTenancyEndNeedsConsent).
func (s *ResidentService) UnitEndResident(ctx context.Context, propertyID, userID, unitID, residentUnitID string) (*models.Resident, error) {
	isOwner, isTenant, occupancy, err := s.repo.UnitRelation(ctx, propertyID, userID, unitID)
	if err != nil {
		return nil, err
	}
	if !isOwner && !isTenant {
		return nil, ErrNotUnitMember
	}
	link, err := s.repo.GetResidentLink(ctx, propertyID, residentUnitID)
	if err != nil {
		return nil, err
	}
	if link.UnitID != unitID {
		return nil, repository.ErrResidentNotFound
	}
	allowed := false
	switch link.Role {
	case "TENANT":
		return nil, ErrTenancyEndNeedsConsent
	case "PROXY":
		allowed = isOwner
	case "HOUSEHOLD":
		allowed = isTenant || (isOwner && occupancy == "OWNER_OCCUPIED")
	}
	if !allowed || link.ResidentID == userID {
		return nil, ErrInviteRole
	}
	inactive := false
	return s.repo.Update(ctx, propertyID, residentUnitID, models.UpdateResidentInput{IsActive: &inactive})
}
