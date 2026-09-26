package service

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"time"
	"unicode"

	"github.com/siteeksen/backend/services/identity/repository"
	"golang.org/x/crypto/bcrypt"
)

// Hesap etkinleştirme ve şifre işlemleri (migration 027).

const (
	// ActivationTTL, etkinleştirme kodunun geçerlilik süresidir.
	ActivationTTL = 7 * 24 * time.Hour
	// codeAlphabet: karışabilecek karakterler (0/O, 1/I/l) çıkarıldı; kod
	// telefonda okunarak ya da elden verilerek iletilir.
	codeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	codeLength   = 8 // 32^8 ≈ 1,1 trilyon; 5 deneme sınırıyla tahmin edilemez
	// Girişte art arda bu kadar hatadan sonra hesap kısa süreli kilitlenir.
	loginFailureThreshold = 5
	loginLockDuration     = 15 * time.Minute
)

var (
	// ErrWeakPassword: şifre politikaya uymuyor (mesajı istemciye gösterilir).
	ErrWeakPassword = errors.New("şifre en az 8 karakter olmalı ve en az bir harf ile bir rakam içermelidir")
	// ErrWrongPassword: şifre değiştirirken mevcut şifre yanlış.
	ErrWrongPassword = errors.New("mevcut şifre hatalı")
)

// GenerateCode, düzgün dağılımlı rastgele kod üretir. Önceki geçici şifre
// üreteci `byte % len(alfabe)` kullanıyordu: 256 alfabe uzunluğuna tam
// bölünmediğinde bazı karakterler daha sık çıkar (modulo sapması).
func GenerateCode() (string, error) {
	var b strings.Builder
	max := big.NewInt(int64(len(codeAlphabet)))
	for i := 0; i < codeLength; i++ {
		n, err := rand.Int(rand.Reader, max)
		if err != nil {
			return "", err
		}
		b.WriteByte(codeAlphabet[n.Int64()])
	}
	return b.String(), nil
}

// ValidatePassword, asgari şifre politikasını uygular.
func ValidatePassword(pw, phone string) error {
	if len([]rune(pw)) < 8 {
		return ErrWeakPassword
	}
	var letter, digit bool
	for _, r := range pw {
		switch {
		case unicode.IsLetter(r):
			letter = true
		case unicode.IsDigit(r):
			digit = true
		}
	}
	if !letter || !digit {
		return ErrWeakPassword
	}
	// Telefon numarası (ya da onu içeren şifre) ilk denenen tahmindir.
	digits := strings.TrimPrefix(phone, "+90")
	if digits != "" && strings.Contains(pw, digits) {
		return fmt.Errorf("%w (telefon numaranızı içeremez)", ErrWeakPassword)
	}
	return nil
}

// IssueActivation, kullanıcı için yeni kod üretir ve kaydeder. Kod yalnızca
// burada, düz metin olarak döner; veritabanında özeti saklanır.
func (s *AuthService) IssueActivation(ctx context.Context, userID, createdBy string, alreadyActive bool) (code string, expires time.Time, purpose string, err error) {
	purpose = "ACTIVATION"
	if alreadyActive {
		purpose = "RESET"
	}
	code, err = GenerateCode()
	if err != nil {
		return "", time.Time{}, "", err
	}
	expires, err = s.userRepo.CreateActivationCode(ctx, userID, createdBy, purpose, repository.HashCode(code), ActivationTTL)
	return code, expires, purpose, err
}

// Activate, telefon + kod ile şifre belirler ve kullanıcının açık TÜM
// oturumlarını iptal eder (kod bir şifre sıfırlamaysa eski oturumlar kapanmalı).
func (s *AuthService) Activate(ctx context.Context, phone, code, newPassword string) error {
	if err := ValidatePassword(newPassword, phone); err != nil {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	userID, err := s.userRepo.ActivateWithCode(ctx, phone, strings.ToUpper(strings.TrimSpace(code)), string(hash))
	if err != nil {
		return err
	}
	if s.revocations != nil {
		if err := s.revocations.RevokeAll(ctx, userID, "PASSWORD_SET"); err != nil {
			return fmt.Errorf("şifre belirlendi ama eski oturumlar kapatılamadı: %w", err)
		}
	}
	return nil
}

// ChangePassword, mevcut şifreyi doğrulayıp yenisini yazar; diğer oturumlar kapanır.
func (s *AuthService) ChangePassword(ctx context.Context, userID, current, next string) error {
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return err
	}
	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(current)) != nil {
		return ErrWrongPassword
	}
	if err := ValidatePassword(next, user.Phone); err != nil {
		return err
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(next), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	if err := s.userRepo.SetPassword(ctx, userID, string(hash)); err != nil {
		return err
	}
	if s.revocations != nil {
		if err := s.revocations.RevokeAll(ctx, userID, "PASSWORD_CHANGED"); err != nil {
			return fmt.Errorf("şifre değişti ama diğer oturumlar kapatılamadı: %w", err)
		}
	}
	return nil
}
