package service

// Sakinin kendi telefon/e-posta değişikliği (migration 062, beşinci tur B4).
//
// Önceden numarayı yalnızca site yönetimi değiştirebiliyordu (kişi birden çok sitede
// kayıtlıysa o da değiştiremiyordu); e-postayı ise kimse değiştiremiyordu.
//   - Telefon: mevcut şifreyle istenir; yeni numaraya SMS ile giden kodla onaylanır (numaranın
//     kişiye ait olduğu kanıtlanır). Onayda bütün oturumlar kapanır, eski numaraya uyarı gider.
//   - E-posta: mevcut şifreyle istenir; YENİ adrese giden kodla onaylanır (065); eski adrese bilgi gider.

import (
	"context"
	"errors"
	"net/mail"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/siteeksen/backend/services/identity/repository"
)

// PhoneChangeTTL, yeni numaraya giden kodun geçerlilik süresidir.
const PhoneChangeTTL = 15 * time.Minute

var (
	// ErrSamePhone: yeni numara mevcut numarayla aynı.
	ErrSamePhone = errors.New("yeni numara mevcut numaranızla aynı")
	// ErrTooSoon: sıklık sınırı (60 sn, saatte 3).
	ErrTooSoon = errors.New("çok sık istek; 60 saniye sonra yeniden deneyin (saatte en çok 3 kod)")
	// ErrInvalidEmail: e-posta biçimi geçersiz.
	ErrInvalidEmail = errors.New("geçerli bir e-posta adresi girin")
)

// RequestPhoneChange, şifreyi doğrular ve yeni numara için kod üretir.
func (s *AuthService) RequestPhoneChange(ctx context.Context, userID, password, newPhone string, now time.Time) (code string, expires time.Time, err error) {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil {
		return "", time.Time{}, ErrWrongPassword
	}
	if newPhone == user.Phone {
		return "", time.Time{}, ErrSamePhone
	}
	if taken, err := s.userRepo.PhoneTaken(ctx, newPhone, userID); err != nil {
		return "", time.Time{}, err
	} else if taken {
		return "", time.Time{}, repository.ErrPhoneTaken
	}
	last, n, err := s.userRepo.PhoneChangeThrottle(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	if !SelfResetAllowed(last, n, now) {
		return "", time.Time{}, ErrTooSoon
	}
	if code, err = GenerateCode(); err != nil {
		return "", time.Time{}, err
	}
	expires, err = s.userRepo.CreatePhoneChange(ctx, userID, newPhone, repository.HashCode(code), PhoneChangeTTL)
	return code, expires, err
}

// ConfirmPhoneChange, kodu doğrular, numarayı değiştirir ve bütün oturumları kapatır.
// Eski ve yeni numarayı döner.
func (s *AuthService) ConfirmPhoneChange(ctx context.Context, userID, code string) (string, string, error) {
	oldPhone, newPhone, err := s.userRepo.ConfirmPhoneChange(ctx, userID, repository.HashCode(strings.ToUpper(strings.TrimSpace(code))))
	if err != nil {
		return "", "", err
	}
	if s.revocations != nil {
		if err := s.revocations.RevokeAll(ctx, userID, "PHONE_CHANGED_BY_USER"); err != nil {
			return oldPhone, newPhone, err
		}
	}
	return oldPhone, newPhone, nil
}

// ErrSameEmail: yeni e-posta mevcut adresle aynı.
var ErrSameEmail = errors.New("yeni e-posta mevcut adresinizle aynı")

// RequestEmailChange, şifreyi doğrular ve YENİ adrese gidecek kodu üretir (065). Adres ancak
// kod girilince değişir: yanlış yazılmış ya da başkasına ait adres doğrulanmadan kaydedilmez.
func (s *AuthService) RequestEmailChange(ctx context.Context, userID, password, email string, now time.Time) (code string, expires time.Time, err error) {
	email = strings.TrimSpace(email)
	if !ValidEmail(email) {
		return "", time.Time{}, ErrInvalidEmail
	}
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)) != nil {
		return "", time.Time{}, ErrWrongPassword
	}
	if strings.EqualFold(user.Email, email) {
		return "", time.Time{}, ErrSameEmail
	}
	if taken, err := s.userRepo.EmailTaken(ctx, email, userID); err != nil {
		return "", time.Time{}, err
	} else if taken {
		return "", time.Time{}, repository.ErrEmailTaken
	}
	last, n, err := s.userRepo.EmailChangeThrottle(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	if !SelfResetAllowed(last, n, now) {
		return "", time.Time{}, ErrTooSoon
	}
	if code, err = GenerateCode(); err != nil {
		return "", time.Time{}, err
	}
	expires, err = s.userRepo.CreateEmailChange(ctx, userID, email, repository.HashCode(code), PhoneChangeTTL)
	return code, expires, err
}

// ConfirmEmailChange, yeni adrese giden kodu doğrular ve e-postayı değiştirir; eski ve yeni adresi döner.
func (s *AuthService) ConfirmEmailChange(ctx context.Context, userID, code string) (string, string, error) {
	return s.userRepo.ConfirmEmailChange(ctx, userID, repository.HashCode(strings.ToUpper(strings.TrimSpace(code))))
}

// ValidEmail, tek bir yalın adres kabul eder ("Ad <a@b>" biçimi değil).
func ValidEmail(e string) bool {
	if e == "" || len(e) > 254 || strings.ContainsAny(e, " <>") {
		return false
	}
	a, err := mail.ParseAddress(e)
	return err == nil && a.Address == e && strings.Contains(e[strings.LastIndex(e, "@")+1:], ".")
}
