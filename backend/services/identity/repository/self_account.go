package repository

// Sakinin kendi telefon/e-posta değişikliği (migration 062, beşinci tur B4).

import (
	"context"
	"crypto/subtle"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// ErrEmailTaken: e-posta başka bir etkin hesapta kayıtlı.
var ErrEmailTaken = errors.New("bu e-posta başka bir hesapta kayıtlı")

// PhoneChangeThrottle, son değişiklik isteğinin zamanını ve son bir saatteki sayısını döner.
func (r *UserRepository) PhoneChangeThrottle(ctx context.Context, userID string) (*time.Time, int, error) {
	var last *time.Time
	var n int
	err := r.pool.QueryRow(ctx, `SELECT max(created_at),
		count(*) FILTER (WHERE created_at > now() - interval '1 hour')::int
		FROM phone_change_requests WHERE user_id = $1`, userID).Scan(&last, &n)
	return last, n, err
}

// PhoneTaken, numaranın başka bir hesapta kayıtlı olup olmadığını söyler.
func (r *UserRepository) PhoneTaken(ctx context.Context, phone, userID string) (bool, error) {
	var taken bool
	err := r.pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE phone = $1 AND id <> $2)`, phone, userID).Scan(&taken)
	return taken, err
}

// CreatePhoneChange, önceki açık istekleri kapatır ve yenisini yazar; geçerlilik sonunu döner.
func (r *UserRepository) CreatePhoneChange(ctx context.Context, userID, newPhone, codeHash string, ttl time.Duration) (time.Time, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return time.Time{}, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, `UPDATE phone_change_requests SET used_at = now() WHERE user_id = $1 AND used_at IS NULL`, userID); err != nil {
		return time.Time{}, err
	}
	var expires time.Time
	if err := tx.QueryRow(ctx, `INSERT INTO phone_change_requests (user_id, new_phone, code_hash, expires_at)
		VALUES ($1, $2, $3, now() + make_interval(secs => $4)) RETURNING expires_at`,
		userID, newPhone, codeHash, ttl.Seconds()).Scan(&expires); err != nil {
		return time.Time{}, err
	}
	return expires, tx.Commit(ctx)
}

// ConfirmPhoneChange, kod doğruysa numarayı değiştirir; eski ve yeni numarayı döner.
// Hatalı denemede sayaç artar; MaxCodeAttempts'te istek kilitlenir.
func (r *UserRepository) ConfirmPhoneChange(ctx context.Context, userID, codeHash string) (string, string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id, newPhone, stored string
	var attempts int
	err = tx.QueryRow(ctx, `SELECT id::text, new_phone, code_hash, failed_attempts FROM phone_change_requests
		WHERE user_id = $1 AND used_at IS NULL AND expires_at > now()
		ORDER BY created_at DESC LIMIT 1 FOR UPDATE`, userID).Scan(&id, &newPhone, &stored, &attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", ErrInvalidCode
	}
	if err != nil {
		return "", "", err
	}
	if attempts >= MaxCodeAttempts {
		return "", "", ErrCodeLocked
	}
	if subtle.ConstantTimeCompare([]byte(stored), []byte(codeHash)) != 1 {
		if _, err := tx.Exec(ctx, `UPDATE phone_change_requests SET failed_attempts = failed_attempts + 1 WHERE id = $1`, id); err != nil {
			return "", "", err
		}
		if err := tx.Commit(ctx); err != nil {
			return "", "", err
		}
		if attempts+1 >= MaxCodeAttempts {
			return "", "", ErrCodeLocked
		}
		return "", "", ErrInvalidCode
	}
	var oldPhone string
	if err := tx.QueryRow(ctx, `SELECT phone FROM users WHERE id = $1 AND deleted = 0 FOR UPDATE`, userID).Scan(&oldPhone); err != nil {
		return "", "", err
	}
	var taken bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE phone = $1 AND id <> $2)`, newPhone, userID).Scan(&taken); err != nil {
		return "", "", err
	}
	if taken {
		return "", "", ErrPhoneTaken
	}
	if _, err := tx.Exec(ctx, `UPDATE users SET phone = $2, updated_at = now() WHERE id = $1`, userID, newPhone); err != nil {
		return "", "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE phone_change_requests SET used_at = now() WHERE id = $1`, id); err != nil {
		return "", "", err
	}
	return oldPhone, newPhone, tx.Commit(ctx)
}

// EmailTaken, e-postanın başka bir etkin hesapta kayıtlı olup olmadığını söyler (büyük/küçük harf duyarsız).
func (r *UserRepository) EmailTaken(ctx context.Context, email, userID string) (bool, error) {
	var taken bool
	err := r.pool.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE lower(email) = lower($1) AND id <> $2 AND deleted = 0)`,
		email, userID).Scan(&taken)
	return taken, err
}

// EmailChangeThrottle, son e-posta değişikliği isteğinin zamanını ve son bir saatteki sayısını döner (065).
func (r *UserRepository) EmailChangeThrottle(ctx context.Context, userID string) (*time.Time, int, error) {
	var last *time.Time
	var n int
	err := r.pool.QueryRow(ctx, `SELECT max(created_at),
		count(*) FILTER (WHERE created_at > now() - interval '1 hour')::int
		FROM email_change_requests WHERE user_id = $1`, userID).Scan(&last, &n)
	return last, n, err
}

// CreateEmailChange, önceki açık istekleri kapatır ve yenisini yazar; geçerlilik sonunu döner (065).
func (r *UserRepository) CreateEmailChange(ctx context.Context, userID, newEmail, codeHash string, ttl time.Duration) (time.Time, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return time.Time{}, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := tx.Exec(ctx, `UPDATE email_change_requests SET used_at = now() WHERE user_id = $1 AND used_at IS NULL`, userID); err != nil {
		return time.Time{}, err
	}
	var expires time.Time
	if err := tx.QueryRow(ctx, `INSERT INTO email_change_requests (user_id, new_email, code_hash, expires_at)
		VALUES ($1, $2, $3, now() + make_interval(secs => $4)) RETURNING expires_at`,
		userID, newEmail, codeHash, ttl.Seconds()).Scan(&expires); err != nil {
		return time.Time{}, err
	}
	return expires, tx.Commit(ctx)
}

// ConfirmEmailChange, kod doğruysa e-postayı değiştirir; eski ve yeni adresi döner (065).
// Hatalı denemede sayaç artar; MaxCodeAttempts'te istek kilitlenir.
func (r *UserRepository) ConfirmEmailChange(ctx context.Context, userID, codeHash string) (string, string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id, newEmail, stored string
	var attempts int
	err = tx.QueryRow(ctx, `SELECT id::text, new_email, code_hash, failed_attempts FROM email_change_requests
		WHERE user_id = $1 AND used_at IS NULL AND expires_at > now()
		ORDER BY created_at DESC LIMIT 1 FOR UPDATE`, userID).Scan(&id, &newEmail, &stored, &attempts)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", ErrInvalidCode
	}
	if err != nil {
		return "", "", err
	}
	if attempts >= MaxCodeAttempts {
		return "", "", ErrCodeLocked
	}
	if subtle.ConstantTimeCompare([]byte(stored), []byte(codeHash)) != 1 {
		if _, err := tx.Exec(ctx, `UPDATE email_change_requests SET failed_attempts = failed_attempts + 1 WHERE id = $1`, id); err != nil {
			return "", "", err
		}
		if err := tx.Commit(ctx); err != nil {
			return "", "", err
		}
		if attempts+1 >= MaxCodeAttempts {
			return "", "", ErrCodeLocked
		}
		return "", "", ErrInvalidCode
	}
	var old string
	if err := tx.QueryRow(ctx, `SELECT COALESCE(email, '') FROM users WHERE id = $1 AND deleted = 0 FOR UPDATE`, userID).Scan(&old); err != nil {
		return "", "", err
	}
	var taken bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM users WHERE lower(email) = lower($1) AND id <> $2 AND deleted = 0)`,
		newEmail, userID).Scan(&taken); err != nil {
		return "", "", err
	}
	if taken {
		return "", "", ErrEmailTaken
	}
	if _, err := tx.Exec(ctx, `UPDATE users SET email = $2, updated_at = now() WHERE id = $1`, userID, newEmail); err != nil {
		return "", "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE email_change_requests SET used_at = now() WHERE id = $1`, id); err != nil {
		return "", "", err
	}
	return old, newEmail, tx.Commit(ctx)
}
