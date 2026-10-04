package main

// Vergi / SGK yükümlülük takvimi (FAZ 7.7, migration 041). Hesap pkg/compliance'ta;
// zamanlayıcı aynı hesapla hatırlatır.

import (
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/compliance"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
)

// muhsgkEnabled: site ayarı MUHSGK_CALENDAR (varsayılan açık; Kolay İşverenlik
// kullanan ya da beyanı muhasebeciye bırakan site kapatabilir).
func muhsgkEnabled(c *gin.Context, pool *pgxpool.Pool, propertyID string) (bool, error) {
	var v *bool
	err := dbscope.For(pool, propertyID).QueryRow(c.Request.Context(),
		`SELECT value_bool FROM property_settings WHERE property_id = $1 AND setting_key = 'MUHSGK_CALENDAR'`, propertyID).Scan(&v)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && v == nil) {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	return *v, nil
}

// complianceCalendar: GET /compliance-calendar (yönetim ve denetçi).
func complianceCalendar(pool *pgxpool.Pool) gin.HandlerFunc {
	params := legalparams.New(pool)
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		enabled, err := muhsgkEnabled(c, pool, propertyID)
		if err != nil {
			failCompliance(c, err)
			return
		}
		items, err := compliance.Load(c.Request.Context(), pool, params, propertyID, time.Now(), enabled)
		if err != nil {
			failCompliance(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": items, "muhsgk_enabled": enabled, "note": compliance.Note})
	}
}

// SGK bildirge tarihlerinin kaydı: işe giriş (sgk_registration_date) ve
// işten ayrılış (sgk_exit_date). Gelecek tarih ve işten ayrılmamış personele
// ayrılış bildirgesi kabul edilmez.
// recordSGK: POST /employees/:id/sgk (yönetim).
func recordSGK(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			EntryDate string `json:"entry_date"`
			ExitDate  string `json:"exit_date"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || (in.EntryDate == "" && in.ExitDate == "") {
			c.JSON(http.StatusBadRequest, gin.H{"error": "entry_date ya da exit_date (YYYY-AA-GG) zorunludur"})
			return
		}
		parse := func(s string) (*time.Time, bool) {
			if s == "" {
				return nil, true
			}
			t, err := time.ParseInLocation("2006-01-02", s, time.Local)
			if err != nil || t.After(time.Now()) {
				return nil, false
			}
			return &t, true
		}
		entry, ok1 := parse(in.EntryDate)
		exit, ok2 := parse(in.ExitDate)
		if !ok1 || !ok2 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bildirge tarihi geçerli ve bugünden ileri olmayan bir tarih olmalı"})
			return
		}
		propertyID := c.GetString("property_id")
		tag, err := dbscope.For(pool, propertyID).Exec(c.Request.Context(), `
			UPDATE employees
			SET sgk_registration_date = COALESCE($3, sgk_registration_date),
			    sgk_exit_date = COALESCE($4, sgk_exit_date), updated_at = now()
			WHERE id = $1 AND property_id = $2 AND deleted = 0
			  AND ($4::date IS NULL OR end_date IS NOT NULL)`, c.Param("id"), propertyID, entry, exit)
		if err != nil {
			failCompliance(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Personel bulunamadı ya da işten ayrılmadığı için ayrılış bildirgesi kaydedilemez"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "SGK bildirge tarihi kaydedildi"})
	}
}

func failCompliance(c *gin.Context, err error) {
	var nf *legalparams.ErrNotFound
	if errors.As(err, &nf) {
		log.Printf("[personnel] mevzuat parametresi eksik: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Mevzuat parametresi tanımlı değil; takvim üretilemedi"})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[personnel] yükümlülük takvimi: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}
