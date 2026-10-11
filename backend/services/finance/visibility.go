package main

// Malikin kiracılı dairesindeki kiracı borcu özeti (altıncı tur D6, migration 071).
//   GET /finance/tenant-debt-summary — dairenin aktif maliki/vekili; site politikası açtığı ölçüde:
//     show_tenant_debt_total → kiracı sorumluluğundaki açık kullanım borcunun toplamı
//     show_tenant_overdue    → bunun vadesi geçmiş kısmı
// Politika kapalıyken tutar dönmez (ayrıntı hiçbir zaman dönmez: dönem/kalem kiracının ve yönetimin bilgisidir).
// Siteye karşı asıl borçlu malik olsa da (KMK m.20) kiracının ödeme düzeni malik baskısına açılmaz: kararı yönetim verir.

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

func tenantDebtSummary(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		sc := dbscope.For(pool, propertyID)
		var contact, total, overdue, requests bool
		if err := sc.QueryRow(ctx, `SELECT show_tenant_contact, show_tenant_debt_total, show_tenant_overdue, show_unit_requests
			FROM owner_visibility($1)`, propertyID).Scan(&contact, &total, &overdue, &requests); err != nil {
			if !middleware.DBErrorResponse(c, err) {
				log.Printf("[finance] görünürlük politikası: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
			}
			return
		}
		policy := gin.H{"show_tenant_debt_total": total, "show_tenant_overdue": overdue}
		type row struct {
			UnitID       string `json:"unit_id"`
			Unit         string `json:"unit"`
			TotalKurus   *int64 `json:"total_kurus,omitempty"`
			OverdueKurus *int64 `json:"overdue_kurus,omitempty"`
		}
		out := []row{}
		if !total && !overdue {
			c.JSON(http.StatusOK, gin.H{"data": out, "policy": policy,
				"note": "Site yönetiminin politikası kiracı borcunu malike göstermiyor. Kiracılık bittiğinde kalan açık borç size görünür."})
			return
		}
		rows, err := sc.Query(ctx, `
			SELECT un.id::text, COALESCE(NULLIF(un.block, ''), '') || '-' || un.door_number,
			       COALESCE(SUM(round((ma.total_amount - COALESCE(ma.paid_amount, 0)) * 100)), 0)::bigint,
			       COALESCE(SUM(round((ma.total_amount - COALESCE(ma.paid_amount, 0)) * 100)) FILTER (WHERE ma.due_date < CURRENT_DATE), 0)::bigint
			FROM resident_units o
			JOIN units un ON un.id = o.unit_id AND un.property_id = $2 AND un.deleted = 0
			JOIN resident_units t ON t.unit_id = un.id AND t.role = 'TENANT' AND t.is_active
			LEFT JOIN monthly_assessments ma ON ma.tenant_link_id = t.id AND ma.deleted = 0
			     AND ma.total_amount > COALESCE(ma.paid_amount, 0)
			WHERE o.resident_id = $1 AND o.is_active AND o.role IN ('OWNER', 'PROXY')
			GROUP BY un.id, un.block, un.door_number
			ORDER BY 2`, userID, propertyID)
		if err != nil {
			if !middleware.DBErrorResponse(c, err) {
				log.Printf("[finance] kiracı borç özeti: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
			}
			return
		}
		defer rows.Close()
		for rows.Next() {
			var r row
			var t, o int64
			if err := rows.Scan(&r.UnitID, &r.Unit, &t, &o); err != nil {
				log.Printf("[finance] kiracı borç özeti: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
				return
			}
			if total {
				r.TotalKurus = &t
			}
			if overdue {
				r.OverdueKurus = &o
			}
			out = append(out, r)
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "policy": policy,
			"note": "Tutar site yönetiminin görünürlük politikasına göre gösterilir; dönem ve kalem ayrıntısı kiracı ile yönetimdedir."})
	}
}
