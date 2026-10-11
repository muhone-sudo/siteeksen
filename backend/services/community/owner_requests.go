package main

// Malikin dairesine ait talep kayıtları (altıncı tur D6, migration 071).
//   GET /requests/units/:unitId — dairenin aktif maliki/vekili. Daire kiracılıysa yalnız site görünürlük politikası
//   `show_unit_requests` açıksa; kiracısız (malik oturuyor / boş) dairede her zaman. Talep edenin kimliği ve açıklama
//   dönmez: malik mülkünün bakım durumunu görür, kiracının özel bilgisini değil.

import (
	"errors"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

func ownerUnitRequests(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, propertyID, userID, unitID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("unitId")
		sc := dbscope.For(pool, propertyID)
		fail := func(err error) {
			if !middleware.DBErrorResponse(c, err) {
				log.Printf("[community] malikin daire talepleri: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
			}
		}
		var owner bool
		var occupancy string
		var allowed bool
		if err := sc.QueryRow(ctx, `
			SELECT EXISTS (SELECT 1 FROM resident_units WHERE unit_id = un.id AND resident_id = $2 AND is_active AND role IN ('OWNER', 'PROXY')),
			       unit_occupancy(un.id), (SELECT show_unit_requests FROM owner_visibility($3))
			FROM units un WHERE un.id = $1 AND un.property_id = $3 AND un.deleted = 0`, unitID, userID, propertyID).
			Scan(&owner, &occupancy, &allowed); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				c.JSON(http.StatusNotFound, gin.H{"error": "Bölüm bulunamadı"})
				return
			}
			fail(err)
			return
		}
		if !owner {
			c.JSON(http.StatusForbidden, gin.H{"error": "Bu dairenin aktif maliki ya da vekili değilsiniz"})
			return
		}
		if occupancy == "TENANT_OCCUPIED" && !allowed {
			c.JSON(http.StatusForbidden, gin.H{"error": "Site yönetiminin görünürlük politikası kiracılı dairenin talep kayıtlarını malike göstermiyor",
				"policy": gin.H{"show_unit_requests": false}})
			return
		}
		rows, err := sc.Query(ctx, `
			SELECT r.id::text, r.ticket_number, r.title, COALESCE(rc.name, ''), COALESCE(r.status, 'OPEN'), COALESCE(r.priority, 'NORMAL'),
			       r.created_at, r.resolved_at
			FROM requests r LEFT JOIN request_categories rc ON rc.id = r.category_id
			WHERE r.property_id = $1 AND r.unit_id = $2
			ORDER BY r.created_at DESC LIMIT 200`, propertyID, unitID)
		if err != nil {
			fail(err)
			return
		}
		defer rows.Close()
		type item struct {
			ID         string     `json:"id"`
			Ticket     string     `json:"ticket_number"`
			Title      string     `json:"title"`
			Category   string     `json:"category"`
			Status     string     `json:"status"`
			Priority   string     `json:"priority"`
			CreatedAt  time.Time  `json:"created_at"`
			ResolvedAt *time.Time `json:"resolved_at,omitempty"`
		}
		out := []item{}
		for rows.Next() {
			var it item
			if err := rows.Scan(&it.ID, &it.Ticket, &it.Title, &it.Category, &it.Status, &it.Priority, &it.CreatedAt, &it.ResolvedAt); err != nil {
				fail(err)
				return
			}
			out = append(out, it)
		}
		c.JSON(http.StatusOK, gin.H{"data": out,
			"note": "Talebi açan kişinin kimliği ve açıklaması gösterilmez; bakım durumu ve sonuç görünür."})
	}
}
