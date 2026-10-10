package main

// Tüketim pusulası (migration 056, Apsiyon BUG-07): yayımlanmış paylaştırmada her bölüm için
// ilk/son endeks, net tüketim, tüketim payı, alan payı ve toplam. Sakin yalnızca kendi
// bölümünün pusulasını görür; yönetim ve denetçi tümünü.

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/reports"
	"github.com/siteeksen/backend/services/iot/repository"
)

func deref(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

func isStatementAdmin(c *gin.Context) bool {
	v, _ := c.Get("roles")
	roles, _ := v.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager || r == middleware.RoleBoardMember || r == middleware.RoleAuditor {
			return true
		}
	}
	return false
}

// statementScope: yönetim için boş (tüm satırlar), sakin için kendi bölümü.
func statementScope(c *gin.Context, repo *repository.Repository, propertyID string) (string, bool) {
	if isStatementAdmin(c) {
		return "", true
	}
	unitID, err := repo.ResidentUnit(c.Request.Context(), propertyID, c.GetString("user_id"))
	if err != nil {
		fail(c, err, "bağımsız bölüm çözümleme")
		return "", false
	}
	return unitID, true
}

var meterTypeLabel = map[string]string{"HEAT": "Isınma", "WATER_COLD": "Soğuk su", "WATER_HOT": "Sıcak su", "GAS": "Doğalgaz", "ELECTRIC": "Elektrik"}

func dateOr(t *time.Time) string {
	if t == nil {
		return "—"
	}
	return t.Format("02.01.2006")
}

// statementPDF: GET /consumption/statements/:id/pdf — gider paylaşım belgesi (pusula).
func statementPDF(repo *repository.Repository, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		scope, ok := statementScope(c, repo, propertyID)
		if !ok {
			return
		}
		a, err := repo.GetAllocation(c.Request.Context(), propertyID, c.Param("id"))
		if err != nil {
			fail(c, err, "pusula okuma")
			return
		}
		lines, err := repo.AllocationLines(c.Request.Context(), propertyID, a.ID, scope)
		if err != nil {
			fail(c, err, "pusula satırları")
			return
		}
		if len(lines) == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
			return
		}
		rows := make([][]string, 0, len(lines))
		for _, l := range lines {
			first := fmt.Sprintf("%s · %s", dateOr(l.FirstDate), deref(l.FirstValue))
			last := fmt.Sprintf("%s · %s", dateOr(l.LastDate), deref(l.LastValue))
			if l.Replaced {
				last += " (sayaç değişti)"
			}
			rows = append(rows, []string{l.UnitName, first, last, l.Consumption, money.Kurus(l.ConsumptionKurus).Display(),
				money.Kurus(l.AreaKurus).Display(), money.Kurus(l.TotalKurus).Display()})
		}
		title := "Gider paylaşım belgesi (tüketim pusulası)"
		if scope != "" {
			title += " — " + lines[0].UnitName
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(c.Request.Context(), pool, propertyID), Title: title, Landscape: true,
			GeneratedAt: a.PublishedAt,
			Facts: [][2]string{
				{"Gider türü", meterTypeLabel[a.MeterType]},
				{"Dönem", a.PeriodFrom.Format("02.01.2006") + " – " + a.PeriodTo.Format("02.01.2006")},
				{"Toplam gider", money.Kurus(a.TotalKurus).Display()},
				{"Paylaşım", "tüketim %" + deref(a.ConsumptionSharePct) + " · kullanım alanı %" + deref(a.AreaSharePct)},
			},
			Tables: []reports.Table{{Title: "Bağımsız bölüm payları",
				Headers:    []string{"Bölüm", "İlk okuma (tarih · endeks)", "Son okuma (tarih · endeks)", "Net tüketim", "Tüketim payı", "Alan payı", "Toplam"},
				Widths:     []float64{22, 45, 52, 28, 38, 38, 44},
				RightAlign: []int{3, 4, 5, 6}, Rows: rows}},
			Notes: []string{a.BasisNote, "Sayaç değişen bölümde net tüketim, eski sayacın söküm endeksine kadarki tüketim ile yeni " +
				"sayacın montaj endeksinden sonraki tüketimin toplamıdır. Pusula yayımlandıktan sonra değiştirilemez."},
		}
		if err := reports.Write(c.Writer, doc, "pdf", "tuketim-pusulasi"); err != nil {
			if errors.Is(err, reports.ErrFormat) {
				c.JSON(http.StatusBadRequest, gin.H{"error": "format desteklenmiyor"})
				return
			}
			log.Printf("[iot] pusula PDF: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Pusula üretilemedi"})
		}
	}
}
