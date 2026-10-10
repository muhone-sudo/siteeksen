package service

// Sakinin kendi "şifremi unuttum" isteği (beşinci tur B3, Şikayetvar: SMS/giriş erişimi).
//
// Önceden kodu yalnızca site yönetimi üretebiliyordu: yönetime ulaşamayan sakin hesabına
// giremiyordu. Artık sakin numarasını girip kod ister; kod kayıtlı telefonuna SMS ile ve
// e-postası kayıtlıysa e-postasına gider.
//
// Güvenlik:
//   - Numaranın kayıtlı olup olmadığı yanıttan anlaşılmaz (çağıran her durumda aynı yanıtı verir).
//   - Kod kısa ömürlüdür (15 dk), tek kullanımlıktır, 5 hatalı denemede kilitlenir (027).
//   - Sıklık sınırı: aynı hesap için 60 saniyede bir, saatte en çok 3 kod (SMS bombardımanına karşı).

import (
	"context"
	"time"

	"github.com/siteeksen/backend/services/identity/repository"
)

const (
	// SelfResetTTL, kendi isteğiyle üretilen kodun geçerlilik süresidir.
	SelfResetTTL = 15 * time.Minute
	// SelfResetCooldown, aynı hesap için iki istek arasındaki en kısa süredir.
	SelfResetCooldown = 60 * time.Second
	// SelfResetPerHour, aynı hesap için bir saatte üretilebilecek en çok kod sayısıdır.
	SelfResetPerHour = 3
)

// SelfResetIssue, gönderilecek kod ve adreslerdir.
type SelfResetIssue struct {
	Phone, Email, Code, Purpose string
	ExpiresAt                   time.Time
}

// IssueSelfReset, numara etkin bir hesaba aitse ve sıklık sınırı aşılmadıysa kod üretir.
// Gönderilecek bir şey yoksa (nil, nil) döner; çağıran bu ayrımı DIŞARIYA yansıtmaz.
func (s *AuthService) IssueSelfReset(ctx context.Context, phone string, now time.Time) (*SelfResetIssue, error) {
	t, err := s.userRepo.GetSelfResetTarget(ctx, phone)
	if err != nil || t == nil {
		return nil, err
	}
	if !SelfResetAllowed(t.LastSelfAt, t.SelfLastHour, now) {
		return nil, nil
	}
	purpose := "ACTIVATION"
	if t.PasswordSet {
		purpose = "RESET"
	}
	code, err := GenerateCode()
	if err != nil {
		return nil, err
	}
	expires, err := s.userRepo.CreateActivationCode(ctx, t.ID, "", purpose, repository.HashCode(code), SelfResetTTL)
	if err != nil {
		return nil, err
	}
	return &SelfResetIssue{Phone: t.Phone, Email: t.Email, Code: code, Purpose: purpose, ExpiresAt: expires}, nil
}

// SelfResetAllowed, sıklık sınırını uygular (saf fonksiyon; birim testli).
func SelfResetAllowed(lastSelf *time.Time, lastHour int, now time.Time) bool {
	if lastHour >= SelfResetPerHour {
		return false
	}
	return lastSelf == nil || now.Sub(*lastSelf) >= SelfResetCooldown
}
