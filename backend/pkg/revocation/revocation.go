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

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Precision, jeton zamanlarının (iat/exp) hassasiyetidir.
//
// DÜZELTME (2026-09-26): jetonlar saniye hassasiyetindeydi. Toplu iptal bu
// yüzden "şimdi + 1 sn" yazıyordu; bunun yan etkisi, iptalden sonraki 1-2 sn
// içinde ALINAN YENİ jetonun da reddedilmesiydi. Şifresini belirleyip hemen
// giriş yapan kullanıcı, girişi başarılı görüp ilk istekte 401 alıyordu.
// Milisaniye hassasiyetiyle iptal anı ile yeni jeton birbirinden ayrılır.
//
// Paket düzeyinde ayarlanır: jetonu üreten (identity) ve doğrulayan her servis
// bu paketi içe aktarır; ayar hepsinde aynı olmak ZORUNDADIR — biri saniyeye
// yuvarlarsa aynı saniyede üretilmiş jeton yine "önce" görünür.
const Precision = time.Millisecond

func init() { jwt.TimePrecision = Precision }

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
// İptal anı veritabanının değil BU sürecin saatinden alınır: jetonların `iat`
// değeri de jetonu üreten kimlik servisinin saatindendir. İki farklı saati
// karşılaştırmak, saat kayması kadar bir pencerede yanlış sonuç verirdi.
func (c *Checker) RevokeAll(ctx context.Context, userID, reason string) error {
	if c == nil || c.pool == nil {
		return ErrNotConfigured
	}
	if reason == "" {
		reason = "LOGOUT_ALL"
	}
	_, err := c.pool.Exec(ctx, `
		INSERT INTO user_token_invalidation (user_id, invalidate_before, reason)
		VALUES ($1::uuid, $3, $2)
		ON CONFLICT (user_id) DO UPDATE
		SET invalidate_before = GREATEST(user_token_invalidation.invalidate_before, EXCLUDED.invalidate_before),
		    reason = EXCLUDED.reason,
		    updated_at = now()`, userID, reason, time.Now().Truncate(Precision))
	return err
}

// RefreshUse, bir yenileme jetonunun bu kullanımının ne olduğudur.
type RefreshUse int

const (
	// RefreshFresh: jetonun ilk kullanımı. Yeni çift verilir, jeton tükenir.
	RefreshFresh RefreshUse = iota
	// RefreshGrace: jeton az önce (tolerans süresi içinde) kullanılmış. Aynı
	// istemcinin eşzamanlı iki isteğidir (iki sekme, yeniden deneme); yeni
	// çift verilir, oturum kapatılmaz.
	RefreshGrace
	// RefreshReused: tüketilmiş jeton tolerans süresinden SONRA yeniden
	// kullanıldı. Meşru istemci yeni jetonu çoktan almıştır; eski jetonu
	// sunan büyük olasılıkla onu ele geçirmiş biridir.
	RefreshReused
	// RefreshRevoked: jeton çıkış vb. ile iptal edilmiş.
	RefreshRevoked
)

// ClaimRefresh, yenileme jetonunu TEK KULLANIMLIK yapar (rotation).
//
// NEDEN (2026-09-26): yenileme jetonu 7 gün boyunca sınırsız kullanılabiliyordu.
// Çalınan bir jeton, sahibi fark etmeden 7 gün yeni erişim jetonu üretebilirdi
// ve bu hiçbir yerde görünmezdi. Artık her yenilemede jeton tükenir; tükenmiş
// jetonun sonradan yeniden sunulması çalınma işareti sayılır (çağıran kullanıcının
// bütün oturumlarını kapatır).
//
// Eşzamanlılık: iki istek aynı jetonu aynı anda sunarsa biri kaydı yazar,
// diğeri yazamaz; ikincisi tolerans içinde sayılır (RefreshGrace).
func (c *Checker) ClaimRefresh(ctx context.Context, jti, userID string, expiresAt time.Time, grace time.Duration) (RefreshUse, error) {
	if c == nil || c.pool == nil {
		return RefreshRevoked, ErrNotConfigured
	}
	if jti == "" {
		return RefreshRevoked, nil
	}
	var inserted bool
	var reason *string
	var recent *bool
	err := c.pool.QueryRow(ctx, `
		WITH ins AS (
			INSERT INTO revoked_tokens (jti, user_id, token_type, expires_at, reason)
			VALUES ($1::uuid, NULLIF($2,'')::uuid, 'REFRESH', $3, 'ROTATED')
			ON CONFLICT (jti) DO NOTHING
			RETURNING 1)
		SELECT EXISTS (SELECT 1 FROM ins),
		       (SELECT reason FROM revoked_tokens WHERE jti = $1::uuid),
		       (SELECT revoked_at > now() - make_interval(secs => $4) FROM revoked_tokens WHERE jti = $1::uuid)`,
		jti, userID, expiresAt, grace.Seconds()).Scan(&inserted, &reason, &recent)
	if err != nil {
		return RefreshRevoked, err
	}
	switch {
	case inserted:
		return RefreshFresh, nil
	case reason == nil:
		// Çakışan kaydı eşzamanlı bir istek yazdı ve bu sorgunun anlık
		// görüntüsünde henüz görünmüyor: aynı anda gelen iki istektir.
		return RefreshGrace, nil
	case *reason != "ROTATED":
		return RefreshRevoked, nil
	case recent != nil && *recent:
		return RefreshGrace, nil
	default:
		return RefreshReused, nil
	}
}

// UserInvalidated, kullanıcının toplu iptalinin (tüm cihazlardan çıkış, şifre
// değişikliği) bu jetonu kapsayıp kapsamadığını söyler.
func (c *Checker) UserInvalidated(ctx context.Context, userID string, issuedAt time.Time) (bool, error) {
	if c == nil || c.pool == nil {
		return false, ErrNotConfigured
	}
	var before *time.Time
	err := c.pool.QueryRow(ctx, `
		SELECT (SELECT invalidate_before FROM user_token_invalidation WHERE user_id = NULLIF($1,'')::uuid)`,
		userID).Scan(&before)
	if err != nil {
		return false, err
	}
	return before != nil && !issuedAt.IsZero() && issuedAt.Before(*before), nil
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
