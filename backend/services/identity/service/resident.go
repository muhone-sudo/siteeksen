package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// ErrResidentForbidden yalnızca yönetim rollerinin yapabileceği bir işlem denendiğinde döner
var ErrResidentForbidden = errors.New("bu işlem için yetkiniz yok")

// ErrInvalidResidentRole sakinlik rolü OWNER/TENANT/PROXY dışında.
var ErrInvalidResidentRole = errors.New("geçersiz sakinlik rolü")

// residentRoles, bir daire bağının taşıyabileceği roller.
//
// YETKİ YÜKSELTME (2026-10-03): bağın rolü jeton rollerine OLDUĞU GİBİ girer
// (UserRepository.GetPropertyRoles). Değer doğrulanmıyordu: sakin yazma yetkisi
// olan yönetim kurulu üyesi kendi hesabını "MANAGER" rolüyle bir daireye bağlayıp
// bir sonraki girişte YÖNETİCİ olabiliyordu (KMK m.34 atama izi atlanarak);
// "SUPER_ADMIN" dizesi de jetona giriyordu. Yönetim rolleri yalnızca
// property_roles üzerinden verilir. Veritabanı da kısıtlar (migration 031).
var residentRoles = map[string]bool{"OWNER": true, "TENANT": true, "PROXY": true}

// ResidentService sakin yönetimi iş kuralları
type ResidentService struct {
	repo *repository.ResidentRepository
	// auth, etkinleştirme kodu üretimi için (hesap işlemleri kimlik servisindedir).
	auth *AuthService
	// users, sakin kaydından kullanıcı hesabına ulaşmak için.
	users *repository.UserRepository
}

// WithActivation, etkinleştirme kodu üretimini bağlar.
func (s *ResidentService) WithActivation(auth *AuthService, users *repository.UserRepository) *ResidentService {
	s.auth = auth
	s.users = users
	return s
}

const activationNote = "Bu kod YALNIZCA BİR KEZ gösterilir. SMS sağlayıcısı bağlı olmadığı için " +
	"kodu sakine siz iletin (elden ya da telefonla). Sakin uygulamada 'Hesabımı etkinleştir' " +
	"ekranında telefonu, bu kodu ve yeni şifresini girer. Kod 7 gün geçerlidir; 5 hatalı " +
	"denemede kilitlenir."

func activationOf(code, purpose string, expires time.Time) *models.Activation {
	return &models.Activation{Code: code, Purpose: purpose, ExpiresAt: expires, Note: activationNote}
}

// NewResidentService yeni servis oluşturur
func NewResidentService(repo *repository.ResidentRepository) *ResidentService {
	return &ResidentService{repo: repo}
}

// canReadResidents: sakin listesini görebilen roller (görevli kapıda kimlik
// doğrulaması için görür; denetçi denetim için okur).
func canReadResidents(roles []string) bool {
	for _, role := range roles {
		switch role {
		case middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor, middleware.RoleStaff:
			return true
		}
	}
	return false
}

// canWriteResidents: sakin EKLEYEBİLEN / DEĞİŞTİREBİLEN roller.
//
// Önceden okuma ve yazma aynı listeydi ve DENETÇİ sakin ekleyip sıfat
// değiştirebiliyordu (KMK m.41: denetçi denetler, yönetmez); kurul üyesi ise
// sakin listesini hiç göremiyordu. Görevli de yazamaz: malik/kiracı sıfatı
// oy hakkını ve borç sorumluluğunu belirler.
func canWriteResidents(roles []string) bool {
	for _, role := range roles {
		switch role {
		case middleware.RoleManager, middleware.RoleBoardMember:
			return true
		}
	}
	return false
}

// List bir sitedeki sakinleri filtreleyerek getirir (yalnızca yönetim)
func (s *ResidentService) List(ctx context.Context, propertyID string, roles []string, search, block, role string) ([]*models.Resident, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.List(ctx, propertyID, search, block, role)
}

// Get sakin detayını getirir (yalnızca yönetim)
func (s *ResidentService) Get(ctx context.Context, propertyID, id string, roles []string) (*models.Resident, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.GetByID(ctx, propertyID, id)
}

// Create yeni sakin oluşturur; telefon numarası sistemde yoksa rastgele geçici şifreyle hesap açılır
//
// DÜZELTME (2026-09-26): önceki sürüm rastgele bir geçici şifre üretip özetini
// saklıyor ve şifreyi HİÇ KİMSEYE iletmiyordu; şifre belirleme akışı da
// yoktu. Yönetimin eklediği sakin hiçbir zaman giriş yapamıyordu. Artık yeni
// açılan hesap için tek kullanımlık etkinleştirme kodu üretilir ve yanıtla
// yöneticiye bir kez gösterilir. Hesabın parolası, kullanıcı kodla kendi
// şifresini belirleyene kadar HİÇBİR değerle eşleşmeyen rastgele bir özettir.
func (s *ResidentService) Create(ctx context.Context, propertyID, actorID string, roles []string, input models.CreateResidentInput) (*models.CreateResidentResult, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	if !residentRoles[input.Role] {
		return nil, ErrInvalidResidentRole
	}

	unusable, err := GenerateCode()
	if err != nil {
		return nil, err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(unusable+unusable), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	res, created, inv, err := s.repo.Create(ctx, propertyID, actorID, string(hash), input)
	if err != nil {
		return nil, err
	}
	if inv != nil {
		return &models.CreateResidentResult{
			Invitation: inv,
			Note: "Bu telefon numarası bu siteyle bağı olmayan mevcut bir hesaba ait. Kişiye davet gönderildi; " +
				"kendi uygulamasından kabul ettiğinde daireye bağlanır (14 gün geçerli). Kişinin bilgileri gösterilmez.",
		}, nil
	}
	out := &models.CreateResidentResult{Resident: res}
	if !created {
		out.Note = "Bu telefon numarasıyla kayıtlı bir hesap zaten var; kişi mevcut şifresiyle giriş yapar. Kod üretilmedi."
		return out, nil
	}
	if s.auth == nil {
		out.Note = "Hesap açıldı ama etkinleştirme kodu üretilemedi (yapılandırma eksik); 'kod üret' ile yeniden deneyin."
		return out, nil
	}
	code, expires, purpose, err := s.auth.IssueActivation(ctx, res.UserID, actorID, false)
	if err != nil {
		return nil, fmt.Errorf("sakin eklendi ama etkinleştirme kodu üretilemedi: %w", err)
	}
	out.Activation = activationOf(code, purpose, expires)
	return out, nil
}

// IssueActivationCode, var olan sakin için yeni kod üretir (ilk etkinleştirme
// ya da unutulan şifre). Eski açık kod geçersizleşir.
func (s *ResidentService) IssueActivationCode(ctx context.Context, propertyID, actorID string, roles []string, residentUnitID string) (*models.Activation, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	if s.auth == nil || s.users == nil {
		return nil, errors.New("etkinleştirme bağlı değil")
	}
	acct, err := s.users.AccountByResident(ctx, propertyID, residentUnitID)
	if err != nil {
		return nil, err
	}
	code, expires, purpose, err := s.auth.IssueActivation(ctx, acct.ID, actorID, acct.PasswordSetAt != nil)
	if err != nil {
		return nil, err
	}
	return activationOf(code, purpose, expires), nil
}

// Update sakinin rol/aktiflik bilgisini günceller (yalnızca yönetim)
func (s *ResidentService) Update(ctx context.Context, propertyID, id string, roles []string, input models.UpdateResidentInput) (*models.Resident, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	if input.Role != nil && !residentRoles[*input.Role] {
		return nil, ErrInvalidResidentRole
	}
	return s.repo.Update(ctx, propertyID, id, input)
}

// ListUnits bir sitedeki birimleri getirir (yalnızca yönetim)
func (s *ResidentService) ListUnits(ctx context.Context, propertyID string, roles []string) ([]*models.Unit, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.ListUnits(ctx, propertyID)
}

// ListInvitations, sitenin sakin davetlerini getirir (yönetim okuma yetkisi).
func (s *ResidentService) ListInvitations(ctx context.Context, propertyID string, roles []string) ([]*models.Invitation, error) {
	if !canReadResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.ListInvitations(ctx, propertyID)
}

// CancelInvitation, bekleyen daveti iptal eder (sakin yazma yetkisi).
func (s *ResidentService) CancelInvitation(ctx context.Context, propertyID, id string, roles []string) (*models.Invitation, error) {
	if !canWriteResidents(roles) {
		return nil, ErrResidentForbidden
	}
	return s.repo.CancelInvitation(ctx, propertyID, id)
}

// MyInvitations, çağıranın yanıt bekleyen davetleri. Rol gerekmez: davet,
// kişinin henüz hiçbir rolü olmayan bir siteden gelir.
func (s *ResidentService) MyInvitations(ctx context.Context, userID string) ([]*models.MyInvitation, error) {
	return s.repo.MyInvitations(ctx, userID)
}

// RespondInvitation, çağıranın davete yanıtını işler.
func (s *ResidentService) RespondInvitation(ctx context.Context, userID, id string, accept bool) (string, error) {
	return s.repo.RespondInvitation(ctx, userID, id, accept)
}
