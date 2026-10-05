package main

// Ziyaretçi geçiş kodu (TEST_RAPORU 2.8, migration 051).
//
// Ön kayıtta tek kullanımlık 6 haneli PIN ve QR jetonu üretilir; kodlar YALNIZCA bir
// kez (üretildiği yanıtta) gösterilir ve veritabanında özetleri tutulur. Sakin kodu
// ziyaretçiye kendisi iletir: site dışı numaraya SMS göndermek ayrı onay ve sağlayıcı
// ister (6563 s. Kanun). Güvenlik görevlisi PIN/QR ile girişi tek adımda kaydeder ve
// daireye teyit bildirimi düşer.
//
// Kaba kuvvet: doğrulama ucu yalnızca güvenlik rollerine açıktır ve kullanıcı başına
// 10 dakikada 10 hatalı denemeyle sınırlıdır (1.000.000 olasılık, az sayıda etkin kod).

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/visitor/repository"
)

// passTTL: beklenen saat verilmemişse kodun geçerlilik süresi.
const passTTL = 24 * time.Hour

// passGrace: beklenen saatten sonra kodun geçerli kaldığı süre.
const passGrace = 12 * time.Hour

type visitorPass struct {
	PIN       string    `json:"pin"`
	QRToken   string    `json:"qr_token"`
	ExpiresAt time.Time `json:"expires_at"`
}

func pinHash(propertyID, pin string) string {
	s := sha256.Sum256([]byte(propertyID + ":" + pin))
	return hex.EncodeToString(s[:])
}

func tokenHash(token string) string {
	s := sha256.Sum256([]byte("qr:" + token))
	return hex.EncodeToString(s[:])
}

func randomPIN() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func randomToken() (string, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return "SEV1-" + strings.ToUpper(hex.EncodeToString(b)), nil
}

// issuePass, beklenen ziyaretçiye yeni PIN ve QR jetonu üretir (öncekiler geçersiz olur).
// ownerUserID doluysa yalnızca kaydı açan kişi üretebilir.
func issuePass(ctx context.Context, pool *pgxpool.Pool, propertyID, visitorID, ownerUserID string) (*visitorPass, error) {
	var expectedAt *time.Time
	err := dbscope.For(pool, propertyID).QueryRow(ctx, `
		SELECT expected_at FROM visitors
		WHERE id = $1 AND property_id = $2 AND status = 'EXPECTED'
		  AND ($3 = '' OR created_by = NULLIF($3,'')::uuid)`, visitorID, propertyID, ownerUserID).Scan(&expectedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, repository.ErrBadState
	}
	if err != nil {
		return nil, err
	}
	expires := time.Now().Add(passTTL)
	if expectedAt != nil && expectedAt.After(time.Now()) {
		expires = expectedAt.Add(passGrace)
	}
	// Etkin PIN'le çakışma (çok düşük olasılık) olursa yeniden üretilir.
	for attempt := 0; attempt < 5; attempt++ {
		pin, err := randomPIN()
		if err != nil {
			return nil, err
		}
		token, err := randomToken()
		if err != nil {
			return nil, err
		}
		_, err = dbscope.For(pool, propertyID).Exec(ctx, `
			UPDATE visitors SET pin_hash = $3, qr_code = $4, qr_expires_at = $5, updated_at = now()
			WHERE id = $1 AND property_id = $2 AND status = 'EXPECTED'`,
			visitorID, propertyID, pinHash(propertyID, pin), tokenHash(token), expires)
		var pg *pgconn.PgError
		if errors.As(err, &pg) && pg.Code == "23505" {
			continue
		}
		if err != nil {
			return nil, err
		}
		return &visitorPass{PIN: pin, QRToken: token, ExpiresAt: expires}, nil
	}
	return nil, errors.New("geçiş kodu üretilemedi (çakışma)")
}

// passLimiter, kullanıcı başına hatalı doğrulama denemelerini sınırlar.
type passLimiter struct {
	mu   sync.Mutex
	hits map[string][]time.Time
}

const passMaxFails = 10
const passWindow = 10 * time.Minute

func (l *passLimiter) blocked(user string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	cut := time.Now().Add(-passWindow)
	kept := l.hits[user][:0]
	for _, t := range l.hits[user] {
		if t.After(cut) {
			kept = append(kept, t)
		}
	}
	l.hits[user] = kept
	return len(kept) >= passMaxFails
}

func (l *passLimiter) fail(user string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.hits[user] = append(l.hits[user], time.Now())
}

// verifyPass: POST /visitors/verify-pass {code} — PIN (6 hane) ya da okutulan QR jetonu.
// Geçerliyse giriş kaydedilir, kod tüketilir ve daireye bildirim düşer.
func verifyPass(pool *pgxpool.Pool, repo *repository.Repository, n *notify.Notifier) gin.HandlerFunc {
	lim := &passLimiter{hits: map[string][]time.Time{}}
	return func(c *gin.Context) {
		user := c.GetString("user_id")
		if lim.blocked(user) {
			c.JSON(http.StatusTooManyRequests, gin.H{"error": "Çok sayıda hatalı kod denendi; 10 dakika sonra tekrar deneyin"})
			return
		}
		var in struct {
			Code string `json:"code"`
		}
		_ = c.ShouldBindJSON(&in)
		code := strings.ToUpper(strings.TrimSpace(in.Code))
		propertyID := c.GetString("property_id")
		var cond, val string
		switch {
		case len(code) == 6 && strings.Trim(code, "0123456789") == "":
			cond, val = "pin_hash = $2", pinHash(propertyID, code)
		case strings.HasPrefix(code, "SEV1-"):
			cond, val = "qr_code = $2", tokenHash(code)
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "6 haneli PIN ya da QR kodu girin"})
			return
		}
		var id string
		var expires *time.Time
		err := dbscope.For(pool, propertyID).QueryRow(c.Request.Context(),
			`SELECT id::text, qr_expires_at FROM visitors WHERE property_id = $1 AND status = 'EXPECTED' AND `+cond,
			propertyID, val).Scan(&id, &expires)
		if errors.Is(err, pgx.ErrNoRows) {
			lim.fail(user)
			c.JSON(http.StatusNotFound, gin.H{"error": "Kod geçersiz ya da kullanılmış"})
			return
		}
		if err != nil {
			log.Printf("[visitor] geçiş kodu: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
			return
		}
		if expires != nil && time.Now().After(*expires) {
			c.JSON(http.StatusGone, gin.H{"error": "Geçiş kodunun süresi dolmuş; sakinden yeni kod isteyin ya da girişi elle kaydedin"})
			return
		}
		info, err := repo.CheckIn(c.Request.Context(), propertyID, id, user)
		if err != nil {
			mapStateError(c, err)
			return
		}
		// Kod tek kullanımlıktır: girişten sonra özetler silinir.
		if _, err := dbscope.For(pool, propertyID).Exec(c.Request.Context(),
			`UPDATE visitors SET pin_hash = NULL, qr_code = NULL WHERE id = $1 AND property_id = $2`, id, propertyID); err != nil {
			log.Printf("[visitor] geçiş kodu tüketilemedi: %v", err)
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Geçiş kodu doğrulandı; ziyaretçi girişi kaydedildi", "visitor_id": id,
			"visitor_name": info.VisitorName, "notification": notifyCheckIn(c, n, repo, pool, info),
		})
	}
}

// reissuePass: POST /visitors/:id/pass — kaydı açan kişi ya da güvenlik rolü yeni kod üretir.
func reissuePass(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		owner := ""
		if !hasSecurityScope(c) {
			owner = c.GetString("user_id")
		}
		p, err := issuePass(c.Request.Context(), pool, c.GetString("property_id"), c.Param("id"), owner)
		if err != nil {
			if errors.Is(err, repository.ErrBadState) {
				c.JSON(http.StatusConflict, gin.H{"error": "Yalnızca kendi açtığınız ve henüz giriş yapmamış ziyaretçi için kod üretilebilir"})
				return
			}
			log.Printf("[visitor] geçiş kodu üretimi: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"pass": p, "note": passNote})
	}
}

const passNote = "PIN ve QR kodu yalnızca bu yanıtta gösterilir; ziyaretçiye siz iletin. Kod tek kullanımlıktır, " +
	"yeni kod üretildiğinde eskisi geçersiz olur."
