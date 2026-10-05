package main

// İşletme projesinden aylık aidat tahakkuku (TEST_RAPORU 2.7, migration 050).
//
// KMK m.37 (7579 s. Kanunla değişik): yöneticinin hazırladığı proje genel kurulda
// onaylanır; genel kurula kadar yeniden değerleme tavanı içinde GEÇİCİ olarak
// uygulanır. Bu yüzden tahakkuk hem kesinleşmiş (FINAL) hem bildirilmiş geçici
// (NOTIFIED) projeden üretilebilir; taslaktan üretilemez.
//
// Bölümün yıllık payı 12 aya kuruşu kuruşuna bölünür (pkg/money, en büyük kalan):
// on iki ayın toplamı yıllık paya birebir eşittir. Aynı ay için ikinci tahakkuk
// (projeden ya da elle) açılamaz (uq_monthly_assessments_regular_period).

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
)

// monthKeys, yıllık payın bölüneceği ayların sabit anahtarlarıdır (belirlenimci dağıtım).
var monthKeys = []string{"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"}

// MonthlyInstallment, yıllık payın verilen aya (1-12) düşen kısmını verir.
func MonthlyInstallment(annual money.Kurus, month int) (money.Kurus, error) {
	if month < 1 || month > 12 {
		return 0, fmt.Errorf("ay 1-12 arasında olmalı")
	}
	parts, err := money.DistributeEqual(annual, monthKeys)
	if err != nil {
		return 0, err
	}
	for _, p := range parts {
		if p.Key == monthKeys[month-1] {
			return p.Amount, nil
		}
	}
	return 0, fmt.Errorf("ay payı bulunamadı")
}

// createBudgetAssessments: POST /governance/budgets/:id/assessments (yönetim).
func createBudgetAssessments(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			PeriodMonth int    `json:"period_month"`
			DueDate     string `json:"due_date"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.PeriodMonth < 1 || in.PeriodMonth > 12 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "period_month (1-12) ve due_date (YYYY-AA-GG) zorunludur"})
			return
		}
		due, err := time.ParseInLocation("2006-01-02", in.DueDate, time.Local)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "due_date YYYY-AA-GG biçiminde olmalı"})
			return
		}
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		tx, err := dbscope.For(pool, propertyID).Begin(ctx)
		if err != nil {
			failAssess(c, err)
			return
		}
		defer tx.Rollback(ctx) //nolint:errcheck

		var status string
		var year int
		err = tx.QueryRow(ctx, `SELECT status, period_year FROM operating_budgets
			WHERE id = $1 AND property_id = $2 FOR UPDATE`, c.Param("id"), propertyID).Scan(&status, &year)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "İşletme projesi bulunamadı"})
			return
		}
		if err != nil {
			failAssess(c, err)
			return
		}
		if status != "FINAL" && status != "NOTIFIED" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tahakkuk yalnızca bildirilmiş (geçici) ya da genel kurulda kesinleşmiş projeden üretilir; taslak projeden üretilemez"})
			return
		}
		// Vade, tahakkuk edilen aydan önce olamaz.
		if due.Before(time.Date(year, time.Month(in.PeriodMonth), 1, 0, 0, 0, 0, time.Local)) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Vade tarihi tahakkuk edilen aydan önce olamaz"})
			return
		}

		rows, err := tx.Query(ctx, `
			SELECT s.unit_id::text, s.annual_kurus FROM operating_budget_unit_shares s
			JOIN units u ON u.id = s.unit_id AND u.deleted = 0
			WHERE s.budget_id = $1 ORDER BY s.unit_id`, c.Param("id"))
		if err != nil {
			failAssess(c, err)
			return
		}
		type share struct {
			unit   string
			annual money.Kurus
		}
		shares := []share{}
		for rows.Next() {
			var s share
			var a int64
			if err := rows.Scan(&s.unit, &a); err != nil {
				rows.Close()
				failAssess(c, err)
				return
			}
			s.annual = money.Kurus(a)
			shares = append(shares, s)
		}
		rows.Close()
		if err := rows.Err(); err != nil {
			failAssess(c, err)
			return
		}
		if len(shares) == 0 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Projede bağımsız bölüm payı yok"})
			return
		}

		total, created := money.Kurus(0), 0
		for _, s := range shares {
			amt, err := MonthlyInstallment(s.annual, in.PeriodMonth)
			if err != nil {
				failAssess(c, err)
				return
			}
			if amt == 0 {
				continue // payı olmayan bölüme sıfır tutarlı borç kaydı açılmaz
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount,
				                                 total_amount, due_date, status, budget_id)
				VALUES ($1, $2, $3, $4, $5::numeric, $5::numeric, $6, 'PENDING', $7)`,
				propertyID, s.unit, year, in.PeriodMonth, amt.String(), due, c.Param("id")); err != nil {
				var pg *pgconn.PgError
				if errors.As(err, &pg) && pg.Code == "23505" {
					c.JSON(http.StatusConflict, gin.H{"error": fmt.Sprintf("%d-%02d dönemi için tahakkuk zaten var (projeden ya da elle); aynı ay iki kez tahakkuk edilemez", year, in.PeriodMonth)})
					return
				}
				failAssess(c, err)
				return
			}
			total += amt
			created++
		}
		if err := tx.Commit(ctx); err != nil {
			failAssess(c, err)
			return
		}
		note := "Yıllık paylar 12 aya kuruşu kuruşuna bölündü; on iki ayın toplamı yıllık paya eşittir."
		if status == "NOTIFIED" {
			note += " Proje GEÇİCİ olarak uygulanıyor (KMK m.37); genel kurul farklı karar verirse sonraki aylar yeni projeden tahakkuk edilir."
		}
		c.JSON(http.StatusCreated, gin.H{
			"period": fmt.Sprintf("%d-%02d", year, in.PeriodMonth), "created": created,
			"total_kurus": int64(total), "budget_status": status, "note": note,
		})
	}
}

func failAssess(c *gin.Context, err error) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[governance] projeden tahakkuk: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}
