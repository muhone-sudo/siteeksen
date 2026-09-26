package handlers

import (
	"github.com/siteeksen/backend/pkg/middleware"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/authtoken"
	"github.com/siteeksen/backend/pkg/revocation"
)

// Logout, mevcut oturumu sonlandırır (FAZ 2.7).
//
// Önceki sürüm yalnızca "Çıkış başarılı" yazıyor ve HİÇBİR ŞEY YAPMIYORDU:
// jeton süresi dolana kadar (erişim 15 dk, YENİLEME 7 GÜN) geçerli kalıyordu.
// Ortak bir bilgisayardan çıkan sakinin oturumu fiilen kapanmıyordu.
//
// Artık:
//   - Erişim jetonunun `jti` değeri reddetme listesine yazılır.
//   - Gövdede yenileme jetonu verilirse o da iptal edilir. Asıl tehlike
//     yenileme jetonudur: 7 gün boyunca yeni erişim jetonu üretebilir.
//   - Süresi dolmuş iptal kayıtları aynı istekte temizlenir (amorti edilmiş).
func Logout(checker *revocation.Checker) gin.HandlerFunc {
	return func(c *gin.Context) {
		claims, err := authtoken.ParseAuthHeader(c.GetHeader("Authorization"))
		if err != nil {
			// Kimliksiz çıkış isteği: yapacak bir şey yok ama hata da değil.
			// Yine de "başarılı" DENMEZ; ne olduğu açıkça söylenir.
			c.JSON(http.StatusOK, gin.H{
				"message": "Geçerli bir oturum bulunamadı",
				"note":    "İptal edilecek jeton yok; istemci yerel oturumunu temizlemelidir.",
			})
			return
		}

		userID := claims.Subject()
		revokedAccess := false
		if claims.ExpiresAt != nil {
			if rerr := checker.Revoke(c.Request.Context(), claims.ID, userID,
				"ACCESS", claims.ExpiresAt.Time, "LOGOUT"); rerr != nil {
				log.Printf("[identity] erişim jetonu iptal edilemedi: %v", rerr)
				c.JSON(http.StatusInternalServerError, gin.H{
					"error": "Çıkış tamamlanamadı; oturum HÂLÂ AÇIK",
					"note": "Jeton iptal edilemedi. 'Çıkış yapıldı' demek, kapanmamış " +
						"bir oturumu kapanmış göstermek olurdu.",
				})
				return
			}
			revokedAccess = true
		}

		// Yenileme jetonu asıl tehlikedir: 7 gün boyunca yeni erişim jetonu üretir.
		var in struct {
			RefreshToken string `json:"refresh_token"`
		}
		_ = c.ShouldBindJSON(&in)

		revokedRefresh := false
		if rt := strings.TrimSpace(in.RefreshToken); rt != "" {
			rClaims, rerr := authtoken.Parse(rt)
			if rerr == nil && rClaims.ExpiresAt != nil {
				if err := checker.Revoke(c.Request.Context(), rClaims.ID,
					rClaims.Subject(), "REFRESH", rClaims.ExpiresAt.Time, "LOGOUT"); err != nil {
					log.Printf("[identity] yenileme jetonu iptal edilemedi: %v", err)
				} else {
					revokedRefresh = true
				}
			}
		}

		// Amorti edilmiş temizlik: zamanlanmış görev altyapısı yok.
		if _, perr := checker.Purge(c.Request.Context()); perr != nil {
			log.Printf("[identity] süresi dolmuş iptal kayıtları temizlenemedi: %v", perr)
		}

		resp := gin.H{
			"message":               "Çıkış yapıldı",
			"access_token_revoked":  revokedAccess,
			"refresh_token_revoked": revokedRefresh,
		}
		if !revokedRefresh {
			resp["warning"] = "Yenileme jetonu GÖNDERİLMEDİĞİ için iptal edilemedi. " +
				"Yenileme jetonu 7 gün boyunca yeni erişim jetonu üretebilir; " +
				"çıkış isteğinde refresh_token da gönderilmelidir."
		}
		c.JSON(http.StatusOK, resp)
	}
}

// LogoutAll, kullanıcının TÜM cihazlardaki oturumlarını sonlandırır.
//
// Tek tek `jti` toplamak gerekmez: bu andan önce üretilmiş jetonlar reddedilir.
// Hesabın ele geçirildiği şüphesinde ve şifre değişikliğinde kullanılır.
func LogoutAll(checker *revocation.Checker) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		if userID == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Oturum bulunamadı"})
			return
		}
		if err := checker.RevokeAll(c.Request.Context(), userID, "LOGOUT_ALL"); err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[identity] toplu iptal başarısız: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "İşlem tamamlanamadı; oturumlar HÂLÂ AÇIK",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Tüm cihazlardaki oturumlar sonlandırıldı",
			"note": "Bu andan önce üretilmiş tüm jetonlar (erişim ve yenileme) " +
				"geçersizdir. Yeniden giriş yapılması gerekir.",
		})
	}
}
