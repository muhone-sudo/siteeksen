package main

// Finans dökümleri: PDF / Excel (TEST_RAPORU 2.6).
//
// Çift taraflı muhasebe (yevmiye, büyük defter, mizan) bu sistemde YOKTUR; tahakkuk ve
// tahsilat takibi vardır. Bu yüzden "mizan" yerine dönem tahakkuk/tahsilat özeti verilir
// ve belge bunu açıkça söyler (mizan mali müşavirin muhasebe programından alınır).

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/reports"
	"github.com/siteeksen/backend/services/finance/service"
)

func reportRoles(c *gin.Context) []string {
	v, _ := c.Get("roles")
	r, _ := v.([]string)
	return r
}

func writeReport(c *gin.Context, d *reports.Document, base string) {
	if err := reports.Write(c.Writer, d, c.Query("format"), base); err != nil {
		if errors.Is(err, reports.ErrFormat) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "format pdf ya da xlsx olmalı"})
			return
		}
		log.Printf("[finance] rapor üretilemedi: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Rapor üretilemedi"})
	}
}

func reportFail(c *gin.Context, err error) {
	if errors.Is(err, service.ErrAssessmentForbidden) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu rapor için yetkiniz yok"})
		return
	}
	log.Printf("[finance] rapor verisi: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "Rapor verisi alınamadı"})
}

// debtorsReport: GET /finance/reports/debtors?format=pdf|xlsx (yönetim).
func debtorsReport(svc *service.FinanceService, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		list, err := svc.ListDebtors(c.Request.Context(), propertyID, reportRoles(c))
		if err != nil {
			reportFail(c, err)
			return
		}
		rows := make([][]string, 0, len(list))
		var total int64
		for _, d := range list {
			k := reports.KurusOf(d.Amount)
			total += k
			name := d.Name
			if name == "" {
				name = "— (kayıtlı malik/sakin yok)"
			}
			rows = append(rows, []string{d.Unit, name, reports.Money(k)})
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(c.Request.Context(), pool, propertyID),
			Title:        "Borçlu listesi", Subtitle: "Bağımsız bölüm bazında ödenmemiş aidat ve ortak gider bakiyesi",
			GeneratedAt: time.Now(),
			Facts:       [][2]string{{"Borçlu bölüm", strconv.Itoa(len(list))}, {"Toplam alacak", reports.Money(total)}},
			Tables: []reports.Table{{Title: "Borçlu bölümler", Headers: []string{"Bölüm", "Malik / sakin", "Borç"},
				Widths: []float64{30, 100, 50}, RightAlign: []int{2}, Rows: rows,
				Footer: []string{"Toplam", "", reports.Money(total)}}},
			Notes: []string{
				"KVKK: Bu liste yalnızca yönetimin iç kullanımı içindir. Borçlu listesinin ortak alanlara asılması ya da " +
					"site gruplarında paylaşılması hukuka aykırıdır (KVK Kurulu 2026/348 sayılı karar, RG 31.03.2026).",
				"Bakiye, vadesi gelmemiş cari dönem tahakkukunu da içerir; vadesi geçmiş borç ayrımı borcu yoktur belgesinde yapılır.",
			},
		}
		writeReport(c, doc, "borclu-listesi")
	}
}

// collectionReport: GET /finance/reports/collections?year=YYYY&format= — dönem tahakkuk/tahsilat özeti.
func collectionReport(svc *service.FinanceService, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		year, _ := strconv.Atoi(c.DefaultQuery("year", strconv.Itoa(time.Now().Year())))
		periods, err := svc.ListAssessmentOverview(c.Request.Context(), propertyID, reportRoles(c), year)
		if err != nil {
			reportFail(c, err)
			return
		}
		rows := [][]string{}
		var tAss, tCol int64
		for _, p := range periods {
			a, col := reports.KurusOf(p.TotalAmount), reports.KurusOf(p.CollectedAmount)
			tAss += a
			tCol += col
			rows = append(rows, []string{p.Period, p.DueDate.Format("02.01.2006"), reports.Money(a), reports.Money(col),
				reports.Money(a - col), fmt.Sprintf("%%%.1f", p.Rate)})
		}
		rate := "—"
		if tAss > 0 {
			rate = fmt.Sprintf("%%%.1f", float64(tCol)*100/float64(tAss))
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(c.Request.Context(), pool, propertyID),
			Title:        fmt.Sprintf("%d yılı tahakkuk ve tahsilat özeti", year),
			GeneratedAt:  time.Now(), Landscape: true,
			Facts: [][2]string{{"Toplam tahakkuk", reports.Money(tAss)}, {"Toplam tahsilat", reports.Money(tCol)},
				{"Kalan", reports.Money(tAss - tCol)}, {"Tahsilat oranı", rate}},
			Tables: []reports.Table{{Title: "Dönemler", Headers: []string{"Dönem", "Son ödeme", "Tahakkuk", "Tahsilat", "Kalan", "Oran"},
				Widths: []float64{30, 35, 50, 50, 50, 25}, RightAlign: []int{2, 3, 4, 5}, Rows: rows,
				Footer: []string{"Toplam", "", reports.Money(tAss), reports.Money(tCol), reports.Money(tAss - tCol), rate}}},
			Notes: []string{"Bu belge tahakkuk/tahsilat takibidir; çift taraflı muhasebe kaydı (yevmiye, mizan) değildir. " +
				"Mizan ve bilanço mali müşavirin muhasebe programından alınır."},
			SignatureLines: []string{"Yönetici", "Denetçi"},
		}
		writeReport(c, doc, fmt.Sprintf("tahsilat-ozeti-%d", year))
	}
}
