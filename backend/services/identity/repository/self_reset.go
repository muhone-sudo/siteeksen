package repository

// Sakinin kendi "şifremi unuttum" isteği (beşinci tur B3).
//
// Kendi isteğiyle üretilen kodun `created_by` alanı BOŞTUR; yönetimin ürettiği kodda
// üreten yöneticinin kimliği vardır. Sıklık sınırı yalnızca kendi isteğiyle üretilen
// kodlara bakar: yönetimin ürettiği kod sakinin isteğini engellemez.

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// SelfResetTarget, numarası verilen etkin hesabın sıfırlama için gereken bilgileridir.
type SelfResetTarget struct {
	ID          string
	Phone       string
	Email       string
	PasswordSet bool
	// LastSelfAt: son kendi isteğiyle üretilen kodun zamanı; SelfLastHour: son bir saatteki sayısı.
	LastSelfAt   *time.Time
	SelfLastHour int
}

// GetSelfResetTarget, numaraya ait etkin hesabı döner; yoksa (nil, nil).
func (r *UserRepository) GetSelfResetTarget(ctx context.Context, phone string) (*SelfResetTarget, error) {
	t := &SelfResetTarget{}
	err := r.pool.QueryRow(ctx, `
		SELECT u.id::text, u.phone, COALESCE(u.email, ''), u.password_set_at IS NOT NULL,
		       (SELECT max(c.created_at) FROM user_activation_codes c WHERE c.user_id = u.id AND c.created_by IS NULL),
		       (SELECT count(*) FROM user_activation_codes c WHERE c.user_id = u.id AND c.created_by IS NULL
		          AND c.created_at > now() - interval '1 hour')::int
		FROM users u
		WHERE u.phone = $1 AND u.deleted = 0 AND COALESCE(u.is_active, true)`, phone).
		Scan(&t.ID, &t.Phone, &t.Email, &t.PasswordSet, &t.LastSelfAt, &t.SelfLastHour)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return t, nil
}
