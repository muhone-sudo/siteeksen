package main

// KVKK saklama süreleri ve periyodik imha (FAZ 7.8, migration 043).

import (
	"errors"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/retention"
)

type retentionRule struct {
	Category        string     `json:"category"`
	Title           string     `json:"title"`
	Fields          string     `json:"fields"`
	Condition       string     `json:"condition"`
	RetentionMonths *int       `json:"retention_months,omitempty"`
	Justification   string     `json:"justification,omitempty"`
	LastRunAt       *time.Time `json:"last_run_at,omitempty"`
	LastRunCount    *int       `json:"last_run_count,omitempty"`
}

func failRetention(c *gin.Context, err error, op string) {
	var nf *legalparams.ErrNotFound
	if errors.As(err, &nf) {
		log.Printf("[settings] mevzuat parametresi eksik: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Mevzuat parametresi tanımlı değil"})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[settings] saklama/imha %s: %v", op, err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}

func listRetention(pool *pgxpool.Pool) gin.HandlerFunc {
	params := legalparams.New(pool)
	return func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		months, err := params.Int(ctx, propertyID, legalparams.KVKKPeriodicDestructionMonths, time.Now())
		if err != nil {
			failRetention(c, err, "listeleme")
			return
		}
		out := []retentionRule{}
		for _, cat := range retention.Categories {
			r := retentionRule{Category: cat.Code, Title: cat.Title, Fields: cat.Fields, Condition: cat.Condition}
			var just *string
			if err := dbscope.For(pool, propertyID).QueryRow(ctx, `
				SELECT (SELECT retention_months FROM data_retention_rules WHERE property_id = $1 AND category = $2),
				       (SELECT justification FROM data_retention_rules WHERE property_id = $1 AND category = $2),
				       (SELECT executed_at FROM data_destruction_log WHERE property_id = $1 AND category = $2 ORDER BY executed_at DESC LIMIT 1),
				       (SELECT record_count FROM data_destruction_log WHERE property_id = $1 AND category = $2 ORDER BY executed_at DESC LIMIT 1)`,
				propertyID, cat.Code).Scan(&r.RetentionMonths, &just, &r.LastRunAt, &r.LastRunCount); err != nil {
				failRetention(c, err, "listeleme")
				return
			}
			if just != nil {
				r.Justification = *just
			}
			out = append(out, r)
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "periodic_months": months,
			"note": "Saklama süresi tanımlanan kategoride kişisel veriler en geç her " + strconv.Itoa(months) + " ayda bir anonimleştirilir " +
				"(İmha Yönetmeliği m.11/2); her işlem en az 3 yıl saklanan imha kaydına yazılır (m.7/3). Süresi tanımlanmamış kategori imha edilmez."})
	}
}

func setRetention(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		cat, ok := retention.Lookup(strings.ToUpper(c.Param("category")))
		if !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kategori bulunamadı"})
			return
		}
		var in struct {
			RetentionMonths int    `json:"retention_months"`
			Justification   string `json:"justification"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Justification = strings.TrimSpace(in.Justification)
		if in.RetentionMonths < 1 || in.RetentionMonths > 120 || in.Justification == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Saklama süresi 1-120 ay olmalı ve gerekçesi (işleme amacı/hukuki dayanak) yazılmalıdır (KVKK m.4/2-d, m.7)"})
			return
		}
		if _, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
			INSERT INTO data_retention_rules (property_id, category, retention_months, justification, updated_by)
			VALUES ($1, $2, $3, $4, NULLIF($5,'')::uuid)
			ON CONFLICT (property_id, category) DO UPDATE
			SET retention_months = EXCLUDED.retention_months, justification = EXCLUDED.justification,
			    updated_by = EXCLUDED.updated_by, updated_at = now()`,
			c.GetString("property_id"), cat.Code, in.RetentionMonths, in.Justification, c.GetString("user_id")); err != nil {
			failRetention(c, err, "kural kaydı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Saklama süresi kaydedildi; bir sonraki periyodik imhada uygulanır"})
	}
}

func runRetention(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		res, err := retention.Run(c.Request.Context(), pool, c.GetString("property_id"), time.Now(), "user:"+c.GetString("user_id"), true)
		if err != nil {
			failRetention(c, err, "imha")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": res, "note": "İmha işlemleri kayda yazıldı."})
	}
}

func destructionLog(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
			SELECT category, method, cutoff, record_count, executed_at, executed_by FROM data_destruction_log
			WHERE property_id = $1 ORDER BY executed_at DESC LIMIT 200`, c.GetString("property_id"))
		if err != nil {
			failRetention(c, err, "imha kaydı")
			return
		}
		defer rows.Close()
		type entry struct {
			Category    string    `json:"category"`
			Method      string    `json:"method"`
			Cutoff      time.Time `json:"cutoff"`
			RecordCount int       `json:"record_count"`
			ExecutedAt  time.Time `json:"executed_at"`
			ExecutedBy  string    `json:"executed_by"`
		}
		out := []entry{}
		for rows.Next() {
			var e entry
			if err := rows.Scan(&e.Category, &e.Method, &e.Cutoff, &e.RecordCount, &e.ExecutedAt, &e.ExecutedBy); err != nil {
				failRetention(c, err, "imha kaydı")
				return
			}
			out = append(out, e)
		}
		c.JSON(http.StatusOK, gin.H{"data": out})
	}
}
