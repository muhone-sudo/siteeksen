package service

// Tedarikçi kaydı (migration 076, FAZ M1, docs/usta-hizmet/plan.md).
//
// Güvenlik:
//   - Kod isteğinin yanıtı numaranın kayıtlı olup olmamasından bağımsızdır; kod her numaraya gider.
//   - Hesabın durumu ancak kod doğrulandıktan sonra (numaranın sahibi kanıtlandıktan sonra) söylenir.
//   - Kod 15 dk, 5 deneme; tamamlama jetonu 15 dk ve tek kullanımlık.
//   - Sıklık sınırı numara ve IP başınadır; aşımı her numara için aynı biçimde söylenir (varlık sızmaz).
//   - Kayıtlı hesaba rol eklemek mevcut şifreyi ister; yanlış şifre giriş kilidine sayılır.

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

const (
	SupplierSignupTTL           = 15 * time.Minute
	SupplierSignupCompletionTTL = 15 * time.Minute
	SupplierSignupCooldown      = 60 * time.Second
	SupplierSignupPerPhoneHour  = 3
	SupplierSignupPerIPHour     = 10
)

var (
	// ErrSignupThrottled: sıklık sınırı aşıldı (numara ya da IP).
	ErrSignupThrottled = errors.New("çok sık kod istendi; biraz sonra yeniden deneyin")
	// ErrSignupBlocked: numaradaki hesap kapatılmış; bu numarayla kayıt yapılamaz.
	ErrSignupBlocked = errors.New("bu numarayla kayıt yapılamıyor; destek ile iletişime geçin")
	// ErrSignupFields: yeni hesap için ad/soyad eksik ya da sözleşme onaylanmamış.
	ErrSignupFields = errors.New("ad, soyad ve üyelik sözleşmesi onayı zorunludur")
)

// SupplierSignupAllowed, sıklık sınırını uygular (saf fonksiyon; birim testli).
func SupplierSignupAllowed(last *time.Time, phoneHour, ipHour int, now time.Time) bool {
	if phoneHour >= SupplierSignupPerPhoneHour || ipHour >= SupplierSignupPerIPHour {
		return false
	}
	return last == nil || now.Sub(*last) >= SupplierSignupCooldown
}

// RequestSupplierSignup, numaraya gönderilecek kodu üretir. Kod numaranın kayıtlı olup olmamasından
// bağımsız olarak üretilir; çağıran gönderimi arka planda yapar.
func (s *AuthService) RequestSupplierSignup(ctx context.Context, phone, ip string, now time.Time) (code string, expires time.Time, err error) {
	last, ph, iph, err := s.userRepo.SignupThrottle(ctx, phone, ip)
	if err != nil {
		return "", time.Time{}, err
	}
	if !SupplierSignupAllowed(last, ph, iph, now) {
		return "", time.Time{}, ErrSignupThrottled
	}
	code, err = GenerateCode()
	if err != nil {
		return "", time.Time{}, err
	}
	expires, err = s.userRepo.CreatePhoneVerification(ctx, phone, repository.HashCode(code), ip, SupplierSignupTTL)
	return code, expires, err
}

// VerifySupplierSignup, kodu doğrular; numaradaki hesabın durumunu ve tamamlama jetonunu döner.
func (s *AuthService) VerifySupplierSignup(ctx context.Context, phone, code string) (state, token string, err error) {
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return "", "", err
	}
	token = hex.EncodeToString(raw)
	state, err = s.userRepo.VerifyPhoneCode(ctx, phone, strings.ToUpper(strings.TrimSpace(code)),
		repository.HashCode(token), SupplierSignupCompletionTTL)
	if err != nil {
		return "", "", err
	}
	if state == repository.PhoneStateBlocked {
		return state, "", nil
	}
	return state, token, nil
}

// SupplierSignupInput, tamamlama adımının girdisidir.
type SupplierSignupInput struct {
	Phone, Token, Password, FirstName, LastName, Email string
	TermsAccepted                                      bool
}

// CompleteSupplierSignup, hesabı açar ya da mevcut hesaba SUPPLIER ekler ve oturum açar.
func (s *AuthService) CompleteSupplierSignup(ctx context.Context, in SupplierSignupInput) (*TokenPair, *models.UserResponse, string, error) {
	if !in.TermsAccepted {
		return nil, nil, "", ErrSignupFields
	}
	c := repository.SignupCompletion{Phone: in.Phone, TokenHash: repository.HashCode(strings.TrimSpace(in.Token))}
	c.FirstName, c.LastName = strings.TrimSpace(in.FirstName), strings.TrimSpace(in.LastName)
	if in.Email = strings.TrimSpace(in.Email); in.Email != "" {
		if !ValidEmail(in.Email) {
			return nil, nil, "", ErrInvalidEmail
		}
		c.Email = in.Email
	}
	// Yeni şifre gereken durumlar (NEW, INACTIVE) için özet önceden hazırlanır; EXISTING'de kullanılmaz.
	newHash := ""
	if err := ValidatePassword(in.Password, in.Phone); err == nil {
		h, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
		if err != nil {
			return nil, nil, "", err
		}
		newHash = string(h)
	}
	c.NewPasswordHash = newHash
	c.CheckExisting = func(ctx context.Context, userID, hash string) error {
		locked, err := s.userRepo.LockState(ctx, userID)
		if err != nil {
			return err
		}
		mismatch := bcrypt.CompareHashAndPassword([]byte(hash), []byte(in.Password)) != nil
		if locked != nil && time.Now().Before(*locked) {
			return ErrInvalidCredentials
		}
		if mismatch {
			if err := s.userRepo.RecordLoginFailure(ctx, userID, LoginLockFor); err != nil {
				return fmt.Errorf("hatalı deneme kaydedilemedi: %w", err)
			}
			return ErrInvalidCredentials
		}
		return nil
	}
	state, err := s.peekSignupState(ctx, in.Phone)
	if err != nil {
		return nil, nil, "", err
	}
	switch state {
	case repository.PhoneStateNew:
		if c.FirstName == "" || c.LastName == "" {
			return nil, nil, state, ErrSignupFields
		}
		fallthrough
	case repository.PhoneStateInactive:
		if err := ValidatePassword(in.Password, in.Phone); err != nil {
			return nil, nil, state, err
		}
	}
	userID, state, err := s.userRepo.CompleteSupplierSignup(ctx, c)
	if err != nil {
		return nil, nil, state, err
	}
	if state == repository.PhoneStateBlocked {
		return nil, nil, state, ErrSignupBlocked
	}
	if state == repository.PhoneStateInactive && s.revocations != nil {
		if err := s.revocations.RevokeAll(ctx, userID, "PASSWORD_SET"); err != nil {
			return nil, nil, state, fmt.Errorf("şifre belirlendi ama eski oturumlar kapatılamadı: %w", err)
		}
	}
	if err := s.userRepo.ResetLoginFailures(ctx, userID); err != nil {
		return nil, nil, state, err
	}
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, nil, state, err
	}
	tokens, resp, err := s.openSession(ctx, user)
	return tokens, resp, state, err
}

// peekSignupState, doğrulamada istemciye söylenen durumu yeniden okur (alan denetimi için).
func (s *AuthService) peekSignupState(ctx context.Context, phone string) (string, error) {
	u, err := s.userRepo.SignupPhoneState(ctx, phone)
	return u, err
}

// openSession, kimliği doğrulanmış kullanıcı için girişteki gibi jeton ve yanıt üretir.
func (s *AuthService) openSession(ctx context.Context, user *models.User) (*TokenPair, *models.UserResponse, error) {
	properties, err := s.ensureActiveProperty(ctx, user)
	if err != nil {
		return nil, nil, err
	}
	roles, err := s.resolveRoles(ctx, user)
	if err != nil {
		return nil, nil, err
	}
	tokens, err := s.generateTokens(user, roles)
	if err != nil {
		return nil, nil, err
	}
	return tokens, &models.UserResponse{
		ID: user.ID, FirstName: user.FirstName, LastName: user.LastName, Phone: user.Phone, Email: user.Email,
		ActivePropertyID: user.ActivePropertyID, Roles: roles, Properties: properties,
		KVKKConsentRequired: user.KVKKConsentAt == nil,
	}, nil
}
