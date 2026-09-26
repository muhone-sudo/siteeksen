package repository

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// Hesap etkinleştirme ve giriş kilidi (migration 027).
//
// Bu dosyadaki sorgular kimlik servisinin kendi rolüyle (siteeksen_identity)
// çalışır; uygulama rolü etkinleştirme kodlarını hiç göremez.

var (
	// ErrInvalidCode: kod yok, süresi dolmuş, kullanılmış ya da telefonla eşleşmiyor.
	// Hangisi olduğu BİLEREK söylenmez (hesap varlığı sızmasın).
	ErrInvalidCode = errors.New("etkinleştirme kodu geçersiz ya da süresi dolmuş")
	// ErrCodeLocked: kod 5 hatalı denemeden sonra kilitlendi.
	ErrCodeLocked = errors.New("etkinleştirme kodu çok sayıda hatalı deneme nedeniyle kilitlendi")
)

// MaxCodeAttempts, bir kod kilitlenmeden önce izin verilen hatalı deneme sayısıdır.
const MaxCodeAttempts = 5

// HashCode, etkinleştirme kodunun saklanan özetidir. Kod yüksek entropili ve
// kısa ömürlü olduğu için tuzsuz SHA-256 yeterlidir (şifre değildir); asıl
// koruma deneme sınırı ve süre sınırıdır.
func HashCode(code string) string {
	sum := sha256.Sum256([]byte(code))
	return hex.EncodeToString(sum[:])
}

// UserAccount, etkinleştirme akışının ihtiyaç duyduğu kullanıcı bilgisidir.
type UserAccount struct {
	ID            string
	Phone         string
	PasswordSetAt *time.Time
}

// AccountByResident, sakin kaydından (resident_units.id) kullanıcı hesabını bulur.
func (r *UserRepository) AccountByResident(ctx context.Context, propertyID, residentUnitID string) (*UserAccount, error) {
	var a UserAccount
	err := r.pool.QueryRow(ctx, `
		SELECT u.id, u.phone, u.password_set_at
		FROM resident_units ru
		JOIN units un ON un.id = ru.unit_id AND un.property_id = $2
		JOIN users u ON u.id = ru.resident_id AND u.deleted = 0
		WHERE ru.id = $1`, residentUnitID, propertyID).Scan(&a.ID, &a.Phone, &a.PasswordSetAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrResidentNotFound
	}
	if err != nil {
		return nil, err
	}
	return &a, nil
}

// CreateActivationCode, kullanıcı için yeni bir kod kaydeder ve açık kalan
// eski kodları geçersiz kılar (aynı anda tek geçerli kod).
func (r *UserRepository) CreateActivationCode(ctx context.Context, userID, createdBy, purpose, codeHash string, ttl time.Duration) (time.Time, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return time.Time{}, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	if _, err := tx.Exec(ctx, `
		UPDATE user_activation_codes SET used_at = now()
		WHERE user_id = $1 AND used_at IS NULL`, userID); err != nil {
		return time.Time{}, err
	}
	var expires time.Time
	if err := tx.QueryRow(ctx, `
		INSERT INTO user_activation_codes (user_id, code_hash, purpose, expires_at, created_by)
		VALUES ($1, $2, $3, now() + make_interval(secs => $4), NULLIF($5,'')::uuid)
		RETURNING expires_at`, userID, codeHash, purpose, ttl.Seconds(), createdBy).Scan(&expires); err != nil {
		return time.Time{}, err
	}
	return expires, tx.Commit(ctx)
}

// ActivateWithCode, telefon + kod doğruysa şifreyi belirler ve kodu kullanılmış
// sayar. Hatalı denemede kodun sayacı artar; sınır aşılınca kod kilitlenir.
// Dönen değer kullanıcı kimliğidir (çağıran açık oturumları iptal eder).
func (r *UserRepository) ActivateWithCode(ctx context.Context, phone, code, passwordHash string) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var userID, codeID, storedHash string
	var attempts int
	err = tx.QueryRow(ctx, `
		SELECT u.id, c.id, c.code_hash, c.failed_attempts
		FROM users u
		JOIN user_activation_codes c ON c.user_id = u.id
		WHERE u.phone = $1 AND u.deleted = 0 AND COALESCE(u.is_active, true)
		  AND c.used_at IS NULL AND c.expires_at > now()
		ORDER BY c.created_at DESC
		LIMIT 1
		FOR UPDATE OF c`, phone).Scan(&userID, &codeID, &storedHash, &attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrInvalidCode
	}
	if err != nil {
		return "", err
	}
	if attempts >= MaxCodeAttempts {
		return "", ErrCodeLocked
	}
	if subtle.ConstantTimeCompare([]byte(storedHash), []byte(HashCode(code))) != 1 {
		if _, err := tx.Exec(ctx,
			`UPDATE user_activation_codes SET failed_attempts = failed_attempts + 1 WHERE id = $1`, codeID); err != nil {
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

	if _, err := tx.Exec(ctx, `
		UPDATE users SET password_hash = $2, password_set_at = now(),
		       failed_login_attempts = 0, locked_until = NULL, updated_at = now()
		WHERE id = $1`, userID, passwordHash); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx,
		`UPDATE user_activation_codes SET used_at = now() WHERE id = $1`, codeID); err != nil {
		return "", err
	}
	return userID, tx.Commit(ctx)
}

// SetPassword, şifreyi değiştirir (mevcut şifre çağıran tarafından doğrulanmıştır).
func (r *UserRepository) SetPassword(ctx context.Context, userID, passwordHash string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE users SET password_hash = $2, password_set_at = now(), updated_at = now()
		WHERE id = $1 AND deleted = 0`, userID, passwordHash)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

// LockState, girişteki kilit durumunu okur.
func (r *UserRepository) LockState(ctx context.Context, userID string) (*time.Time, error) {
	var until *time.Time
	err := r.pool.QueryRow(ctx, `SELECT locked_until FROM users WHERE id = $1`, userID).Scan(&until)
	return until, err
}

// RecordLoginFailure, hatalı girişi sayar; eşik aşılınca hesabı kilitler.
func (r *UserRepository) RecordLoginFailure(ctx context.Context, userID string, threshold int, lock time.Duration) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE users
		SET failed_login_attempts = failed_login_attempts + 1,
		    locked_until = CASE WHEN failed_login_attempts + 1 >= $2
		                        THEN now() + make_interval(secs => $3) ELSE locked_until END
		WHERE id = $1`, userID, threshold, lock.Seconds())
	return err
}

// ResetLoginFailures, başarılı girişte sayacı sıfırlar.
func (r *UserRepository) ResetLoginFailures(ctx context.Context, userID string) error {
	_, err := r.pool.Exec(ctx, `
		UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = now()
		WHERE id = $1`, userID)
	return err
}
