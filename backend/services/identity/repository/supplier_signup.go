package repository

// Tedarikçi kaydı (migration 076, FAZ M1).
//
// Akış: telefon → SMS kodu → kod doğrulanınca tek kullanımlık tamamlama jetonu → hesap açma ya da mevcut
// hesaba SUPPLIER ekleme. Kod ve jeton yalnızca özet olarak saklanır.

import (
	"context"
	"crypto/subtle"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// SupplierRole, tedarikçinin platform rolüdür (users.roles).
const SupplierRole = "SUPPLIER"

// Hesap durumları: kod doğrulandıktan sonra istemciye söylenir.
const (
	PhoneStateNew      = "NEW"      // numarada hesap yok: kişi hesap açar
	PhoneStateExisting = "EXISTING" // etkin hesap var: mevcut şifresiyle onaylar
	PhoneStateInactive = "INACTIVE" // hesap var ama şifre hiç belirlenmemiş: şifre belirler
	PhoneStateBlocked  = "BLOCKED"  // hesap kapatılmış/pasif: bu numarayla kayıt yapılamaz
)

// ErrSignupTokenInvalid: tamamlama jetonu yok, kullanılmış ya da süresi dolmuş.
var ErrSignupTokenInvalid = errors.New("kayıt oturumu geçersiz ya da süresi dolmuş; telefonunuzu yeniden doğrulayın")

// SignupThrottle, sıklık sınırı için son isteğin zamanını ve son bir saatteki sayıları döner.
func (r *UserRepository) SignupThrottle(ctx context.Context, phone, ip string) (last *time.Time, phoneHour, ipHour int, err error) {
	err = r.pool.QueryRow(ctx, `
		SELECT (SELECT max(created_at) FROM phone_verifications WHERE phone = $1),
		       (SELECT count(*) FROM phone_verifications WHERE phone = $1 AND created_at > now() - interval '1 hour')::int,
		       (SELECT count(*) FROM phone_verifications WHERE request_ip = $2 AND created_at > now() - interval '1 hour')::int`,
		phone, ip).Scan(&last, &phoneHour, &ipHour)
	return
}

// CreatePhoneVerification, yeni bir doğrulama kodu kaydeder; aynı numaranın açık eski kodları kapanır.
func (r *UserRepository) CreatePhoneVerification(ctx context.Context, phone, codeHash, ip string, ttl time.Duration) (time.Time, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return time.Time{}, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, `UPDATE phone_verifications SET used_at = now()
		WHERE phone = $1 AND used_at IS NULL AND verified_at IS NULL`, phone); err != nil {
		return time.Time{}, err
	}
	var expires time.Time
	if err := tx.QueryRow(ctx, `
		INSERT INTO phone_verifications (phone, purpose, code_hash, expires_at, request_ip)
		VALUES ($1, 'SUPPLIER_SIGNUP', $2, now() + make_interval(secs => $3), NULLIF($4, ''))
		RETURNING expires_at`, phone, codeHash, ttl.Seconds(), ip).Scan(&expires); err != nil {
		return time.Time{}, err
	}
	return expires, tx.Commit(ctx)
}

// VerifyPhoneCode, kodu doğrular. Doğruysa kodu kapatır, tamamlama jetonunun özetini yazar ve
// numaradaki hesabın durumunu döner. Hatalı denemede sayaç artar; sınırda kod kilitlenir.
func (r *UserRepository) VerifyPhoneCode(ctx context.Context, phone, code, completionHash string, completionTTL time.Duration) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id, stored string
	var attempts int
	err = tx.QueryRow(ctx, `
		SELECT id, code_hash, failed_attempts FROM phone_verifications
		WHERE phone = $1 AND purpose = 'SUPPLIER_SIGNUP' AND used_at IS NULL AND verified_at IS NULL AND expires_at > now()
		ORDER BY created_at DESC LIMIT 1
		FOR UPDATE`, phone).Scan(&id, &stored, &attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrInvalidCode
	}
	if err != nil {
		return "", err
	}
	if attempts >= MaxCodeAttempts {
		return "", ErrCodeLocked
	}
	if subtle.ConstantTimeCompare([]byte(stored), []byte(HashCode(code))) != 1 {
		if _, err := tx.Exec(ctx, `UPDATE phone_verifications SET failed_attempts = failed_attempts + 1 WHERE id = $1`, id); err != nil {
			return "", err
		}
		if err := tx.Commit(ctx); err != nil {
			return "", err
		}
		if attempts+1 >= MaxCodeAttempts {
			return "", ErrCodeLocked
		}
		return "", ErrInvalidCode
	}
	if _, err := tx.Exec(ctx, `UPDATE phone_verifications
		SET verified_at = now(), completion_hash = $2, completion_expires_at = now() + make_interval(secs => $3)
		WHERE id = $1`, id, completionHash, completionTTL.Seconds()); err != nil {
		return "", err
	}
	state, _, err := phoneState(ctx, tx, phone)
	if err != nil {
		return "", err
	}
	return state, tx.Commit(ctx)
}

// rowQuerier, havuz ve transaction için ortak tek satır sorgusudur.
type rowQuerier interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

// SignupPhoneState, numaradaki hesabın durumunu okur.
func (r *UserRepository) SignupPhoneState(ctx context.Context, phone string) (string, error) {
	state, _, err := phoneState(ctx, r.pool, phone)
	return state, err
}

// phoneState, numaradaki hesabın durumunu ve (varsa) kimliğini döner.
func phoneState(ctx context.Context, q rowQuerier, phone string) (string, string, error) {
	var id string
	var deleted int
	var active, passwordSet bool
	err := q.QueryRow(ctx, `SELECT id::text, deleted, COALESCE(is_active, true), password_set_at IS NOT NULL
		FROM users WHERE phone = $1`, phone).Scan(&id, &deleted, &active, &passwordSet)
	switch {
	case errors.Is(err, pgx.ErrNoRows):
		return PhoneStateNew, "", nil
	case err != nil:
		return "", "", err
	case deleted != 0 || !active:
		return PhoneStateBlocked, id, nil
	case passwordSet:
		return PhoneStateExisting, id, nil
	default:
		return PhoneStateInactive, id, nil
	}
}

// SignupCompletion, tamamlama adımının girdisidir. Verify edilen alanlar duruma göre kullanılır.
type SignupCompletion struct {
	Phone, TokenHash string
	// NEW: ad, soyad, e-posta, yeni şifre özeti. INACTIVE: yeni şifre özeti.
	FirstName, LastName, Email, NewPasswordHash string
	// EXISTING: mevcut şifreyi doğrulayan işlev (çağıran bcrypt karşılaştırmasını yapar, kilidi işler).
	CheckExisting func(ctx context.Context, userID, passwordHash string) error
}

// CompleteSupplierSignup, jetonu tüketir ve duruma göre hesabı açar ya da mevcut hesaba SUPPLIER ekler.
// Mevcut hesapta şifre yanlışsa jeton TÜKETİLMEZ (kişi yeniden deneyebilir; giriş kilidi işler).
func (r *UserRepository) CompleteSupplierSignup(ctx context.Context, in SignupCompletion) (string, string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var vid string
	err = tx.QueryRow(ctx, `
		SELECT id FROM phone_verifications
		WHERE phone = $1 AND completion_hash = $2 AND used_at IS NULL AND completion_expires_at > now()
		FOR UPDATE`, in.Phone, in.TokenHash).Scan(&vid)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", ErrSignupTokenInvalid
	}
	if err != nil {
		return "", "", err
	}
	state, userID, err := phoneState(ctx, tx, in.Phone)
	if err != nil {
		return "", "", err
	}
	switch state {
	case PhoneStateBlocked:
		return "", state, nil
	case PhoneStateNew:
		if err := tx.QueryRow(ctx, `
			INSERT INTO users (first_name, last_name, phone, email, password_hash, password_set_at, kvkk_consent_at, roles)
			VALUES ($1, $2, $3, NULLIF($4, ''), $5, now(), now(), ARRAY[$6])
			RETURNING id::text`, in.FirstName, in.LastName, in.Phone, in.Email, in.NewPasswordHash, SupplierRole).Scan(&userID); err != nil {
			return "", "", err
		}
	case PhoneStateInactive:
		if _, err := tx.Exec(ctx, `
			UPDATE users SET password_hash = $2, password_set_at = now(), failed_login_attempts = 0, locked_until = NULL,
			       roles = CASE WHEN $3 = ANY(COALESCE(roles, '{}')) THEN roles ELSE array_append(COALESCE(roles, '{}'), $3) END,
			       updated_at = now()
			WHERE id = $1`, userID, in.NewPasswordHash, SupplierRole); err != nil {
			return "", "", err
		}
	case PhoneStateExisting:
		var hash string
		if err := tx.QueryRow(ctx, `SELECT password_hash FROM users WHERE id = $1`, userID).Scan(&hash); err != nil {
			return "", "", err
		}
		if err := in.CheckExisting(ctx, userID, hash); err != nil {
			return "", state, err
		}
		if _, err := tx.Exec(ctx, `
			UPDATE users SET roles = CASE WHEN $2 = ANY(COALESCE(roles, '{}')) THEN roles ELSE array_append(COALESCE(roles, '{}'), $2) END,
			       updated_at = now()
			WHERE id = $1`, userID, SupplierRole); err != nil {
			return "", "", err
		}
	}
	if _, err := tx.Exec(ctx, `UPDATE phone_verifications SET used_at = now() WHERE id = $1`, vid); err != nil {
		return "", "", err
	}
	return userID, state, tx.Commit(ctx)
}
