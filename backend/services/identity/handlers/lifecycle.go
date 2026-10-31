package handlers

// Site yaşam döngüsü (migration 058, Apsiyon BUG-11): pasifleştirme ve yeniden etkinleştirme.
//
// Pasif sitede yeni tahakkuk, gecikme tazminatı ve bildirim veritabanı tetikleyicisiyle
// engellenir (fail-closed); zamanlayıcı ve cihaz bekçisi siteyi taramaz. Giriş ve okuma
// sürer: sakin geçmiş kayıtlarını görebilmeli, yönetici siteyi yeniden açabilmelidir.

import (
	"errors"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// PropertyStatus: GET /property — aktif sitenin durumu ve son yaşam döngüsü olayları.
func PropertyStatus(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx := c.Request.Context()
		pid := c.GetString("property_id")
		var name string
		var active bool
		var at *time.Time
		var reason *string
		var lat, lng *float64
		err := pool.QueryRow(ctx, `SELECT name, is_active, deactivated_at, deactivation_reason, latitude::float8, longitude::float8
			FROM properties WHERE id = $1`, pid).Scan(&name, &active, &at, &reason, &lat, &lng)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Site bulunamadı"})
			return
		}
		if err != nil {
			log.Printf("[identity] site durumu: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Site durumu okunamadı"})
			return
		}
		rows, err := pool.Query(ctx, `SELECT action, reason, created_at FROM property_lifecycle_events
			WHERE property_id = $1 ORDER BY created_at DESC LIMIT 20`, pid)
		if err != nil {
			log.Printf("[identity] site olayları: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Site durumu okunamadı"})
			return
		}
		defer rows.Close()
		events := []gin.H{}
		for rows.Next() {
			var action, why string
			var when time.Time
			if err := rows.Scan(&action, &why, &when); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Site durumu okunamadı"})
				return
			}
			events = append(events, gin.H{"action": action, "reason": why, "at": when})
		}
		c.JSON(http.StatusOK, gin.H{"id": pid, "name": name, "is_active": active, "deactivated_at": at,
			"deactivation_reason": reason, "events": events, "latitude": lat, "longitude": lng})
	}
}

// SetPropertyLocation, sitenin harita konumunu yazar (077, FAZ M2.4). Usta & Hizmet eşleşmesi tedarikçinin hizmet
// yarıçapını bu konuma göre ölçer; konum yoksa ilçe eşleşmesi kullanılır. İkisi birlikte boş verilirse konum silinir.
func SetPropertyLocation(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Latitude  *float64 `json:"latitude"`
			Longitude *float64 `json:"longitude"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || (in.Latitude == nil) != (in.Longitude == nil) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "latitude ve longitude birlikte verilmeli (silmek için ikisi de null)"})
			return
		}
		if in.Latitude != nil && (*in.Latitude < -90 || *in.Latitude > 90 || *in.Longitude < -180 || *in.Longitude > 180) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Konum geçersiz: enlem -90..90, boylam -180..180 olmalı"})
			return
		}
		tag, err := pool.Exec(c.Request.Context(), `UPDATE properties SET latitude = $2, longitude = $3, updated_at = now() WHERE id = $1`,
			c.GetString("property_id"), in.Latitude, in.Longitude)
		if err != nil {
			log.Printf("[identity] site konumu: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Site konumu kaydedilemedi"})
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Site bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Site konumu kaydedildi", "latitude": in.Latitude, "longitude": in.Longitude})
	}
}

// SetPropertyActive: POST /property/deactivate {reason, confirm_name} · /property/reactivate {reason} (yönetici).
func SetPropertyActive(pool *pgxpool.Pool, active bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason      string `json:"reason"`
			ConfirmName string `json:"confirm_name"`
		}
		_ = c.ShouldBindJSON(&in)
		reason := strings.TrimSpace(in.Reason)
		if len([]rune(reason)) < 5 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Gerekçe zorunludur (en az 5 karakter)"})
			return
		}
		ctx := c.Request.Context()
		pid := c.GetString("property_id")
		tx, err := pool.Begin(ctx)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem başlatılamadı"})
			return
		}
		defer tx.Rollback(ctx) //nolint:errcheck
		var name string
		var current bool
		if err := tx.QueryRow(ctx, `SELECT name, is_active FROM properties WHERE id = $1 FOR UPDATE`, pid).Scan(&name, &current); err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Site bulunamadı"})
			return
		}
		if current == active {
			state := "zaten etkin"
			if !active {
				state = "zaten pasif"
			}
			c.JSON(http.StatusConflict, gin.H{"error": "Site " + state})
			return
		}
		// Yanlışlıkla pasifleştirmeye karşı: site adı yazılarak onaylanır.
		if !active && !strings.EqualFold(strings.TrimSpace(in.ConfirmName), strings.TrimSpace(name)) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Onay için site adını aynen yazın (confirm_name)", "site_name": name})
			return
		}
		if active {
			_, err = tx.Exec(ctx, `UPDATE properties SET is_active = true, deactivated_at = NULL, deactivation_reason = NULL,
				updated_at = now() WHERE id = $1`, pid)
		} else {
			_, err = tx.Exec(ctx, `UPDATE properties SET is_active = false, deactivated_at = now(), deactivation_reason = $2,
				updated_at = now() WHERE id = $1`, pid, reason)
		}
		if err == nil {
			action := "DEACTIVATED"
			if active {
				action = "REACTIVATED"
			}
			_, err = tx.Exec(ctx, `INSERT INTO property_lifecycle_events (property_id, action, reason, actor_id)
				VALUES ($1, $2, $3, NULLIF($4,'')::uuid)`, pid, action, reason, c.GetString("user_id"))
		}
		if err == nil {
			err = tx.Commit(ctx)
		}
		if err != nil {
			log.Printf("[identity] site durum değişikliği: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Site durumu değiştirilemedi"})
			return
		}
		if active {
			c.JSON(http.StatusOK, gin.H{"is_active": true, "message": "Site yeniden etkinleştirildi",
				"note": "Pasif dönem için tahakkuk ve gecikme tazminatı GERİYE DÖNÜK üretilmez; gerekiyorsa genel kurul kararıyla ayrıca tahakkuk edilir."})
			return
		}
		c.JSON(http.StatusOK, gin.H{"is_active": false, "message": "Site pasife alındı",
			"note": "Yeni tahakkuk, gecikme tazminatı, zamanlanmış hatırlatma ve bildirim üretilmez. Kayıtlar silinmez; sakinler geçmiş kayıtlarını görebilir."})
	}
}
