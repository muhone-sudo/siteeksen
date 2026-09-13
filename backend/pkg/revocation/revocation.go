// Package revocation, iptal edilmiş JWT'lerin denetimini sağlar.
//
// Neden var: JWT durumsuzdur; "çıkış yap" jetonu geçersiz kılmıyordu. Çalınan
// ya da ortak bilgisayarda bırakılan bir jeton, süresi dolana kadar (erişim
// 15 dk, yenileme 7 GÜN) geçerli kalıyordu.
//
// İki iptal yolu vardır:
//  1. TEK JETON: `revoked_tokens` tablosuna `jti` yazılır (bir cihazdan çıkış).
//  2. TOPLU: `user_token_invalidation` tablosuna bir zaman yazılır; o andan
//     ÖNCE üretilmiş tüm jetonlar reddedilir (tüm cihazlardan çıkış, şifre
//     değişikliği, hesap ele geçirme şüphesi).
//
// Performans: her istekte bir sorgu çalışır. Sorgu birincil anahtar üzerinden
// olduğu için ucuzdur. Kısa süreli bir ÖNBELLEK bilerek kullanılmaz: iptal
// edilmiş bir jetonu önbellek süresi kadar daha kabul etmek, iptalin amacını
// ortadan kaldırır.
package revocation

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNotConfigured, denetleyici kurulmadan kullanılmaya çalışılırsa döner.
var ErrNotConfigured = errors.New("jeton iptal denetimi yapılandırılmamış")

// Checker, jeton iptalini denetler.
type Checker struct{ pool *pgxpool.Pool }

// New, denetleyiciyi kurar.
func New(pool *pgxpool.Pool) *Checker { return &Checker{pool: pool} }

// IsRevoked, jetonun iptal edilip edilmediğini söyler.
//
// jti boşsa jeton iptal edilemez demektir; bu durumda HATA döner ve çağıran
// tarafın isteği reddetmesi beklenir. `jti` taşımayan bir jeton, çıkış
// yapıldığında geri alınamaz — sessizce kabul etmek iptal mekanizmasını
// baypas edilebilir kılardı.
func (c *Checker) IsRevoked(ctx context.Context, jti, userID string, issuedAt time.Time) (bool, string, error) {
	if c == nil || c.pool == nil {
		return false, "", ErrNotConfigured
	}
	if jti == "" {
		return true, "Jeton kimliği (jti) yok; iptal edilemeyeceği için kabul edilmiyor", nil
	}

	var revokedReason *string
	var invalidateBefore *time.Time
	err := c.pool.QueryRow(ctx, `
		SELECT
		  (SELECT reason FROM revoked_tokens WHERE jti = $1::uuid),
		  (SELECT invalidate_before FROM user_token_invalidation
		    WHERE user_id = NULLIF($2,'')::uuid)`,
		jti, userID).Scan(&revokedReason, &invalidateBefore)
	if err != nil {
		return false, "", err
	}

	if revokedReason != nil {
		return true, "Jeton iptal edilmiş (" + *revokedReason + ")", nil
	}
	if invalidateBefore != nil && !issuedAt.IsZero() && issuedAt.Before(*invalidateBefore) {
		return true, "Bu kullanıcının tüm oturumları sonlandırılmış", nil
	}
	return false, "", nil
}

// Revoke, tek bir jetonu iptal eder. İşlem tekrarlanabilir (idempotent).
func (c *Checker) Revoke(ctx context.Context, jti, userID, tokenType string, expiresAt time.Time, reason string) error {
	if c == nil || c.pool == nil {
		return ErrNotConfigured
	}
	if jti == "" {
		// Kimliksiz jeton iptal edilemez; çağıran bunu bilmelidir.
		return errors.New("jeton kimliği (jti) yok; iptal edilemez")
	}
	if reason == "" {
		reason = "LOGOUT"
	}
	_, err := c.pool.Exec(ctx, `
		INSERT INTO revoked_tokens (jti, user_id, token_type, expires_at, reason)
		VALUES ($1::uuid, NULLIF($2,'')::uuid, $3, $4, $5)
		ON CONFLICT (jti) DO NOTHING`,
		jti, userID, tokenType, expiresAt, reason)
	return err
}

// RevokeAll, kullanıcının o ana kadarki tüm jetonlarını geçersiz kılar.
//
// Zaman olarak `now()` yerine bir saniye ilerisi kullanılır: aynı saniye içinde
// üretilmiş bir jeton, saniye hassasiyetindeki `iat` karşılaştırmasında
// "önce üretilmiş" sayılmayabilirdi.
func (c *Checker) RevokeAll(ctx context.Context, userID, reason string) error {
	if c == nil || c.pool == nil {
		return ErrNotConfigured
	}
	if reason == "" {
		reason = "LOGOUT_ALL"
	}
	_, err := c.pool.Exec(ctx, `
		INSERT INTO user_token_invalidation (user_id, invalidate_before, reason)
		VALUES ($1::uuid, now() + interval '1 second', $2)
		ON CONFLICT (user_id) DO UPDATE
		SET invalidate_before = now() + interval '1 second',
		    reason = EXCLUDED.reason,
		    updated_at = now()`, userID, reason)
	return err
}

// Purge, süresi dolmuş iptal kayıtlarını siler ve silinen sayıyı döner.
//
// Zamanlanmış görev altyapısı yoktur; bu yüzden çıkış işleminde çağrılır
// (amorti edilmiş temizlik). Tablo yalnızca çıkış yapılan jeton kadar büyür.
func (c *Checker) Purge(ctx context.Context) (int, error) {
	if c == nil || c.pool == nil {
		return 0, ErrNotConfigured
	}
	var n int
	err := c.pool.QueryRow(ctx, `SELECT purge_expired_revoked_tokens()`).Scan(&n)
	return n, err
}
