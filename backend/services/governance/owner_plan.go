package main

// Malikin işletme projesi görünümü (FAZ H.6 S12, kullanıcı kararı K3 — seçenekli).
//
// İşletme projesi KMK m.37 gereği genel kurulda onaylanır; malik projeyi görüp görüş/itiraz bildirebilir
// (m.37/2 hakkı malikindir). Yönetim ekranları (GET /budgets) yalnız yönetime açıktır; bu dosya malike
// TASLAK OLMAYAN projeleri ve yalnız KENDİ bölümlerinin payını gösterir. Görüş/itiraz alımı site ayarı
// OWNER_PLAN_OBJECTIONS ile kapatılabilir; kapalıyken proje yine görünür, yeni itiraz alınmaz.

import (
	"context"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/governance/repository"
	"github.com/siteeksen/backend/services/governance/service"
)

func ownerFail(c *gin.Context, err error, op string) {
	if errors.Is(err, repository.ErrNotFound) || errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	c.JSON(http.StatusInternalServerError, gin.H{"error": op + " okunamadı"})
}

// ownerObjectionsEnabled, OWNER_PLAN_OBJECTIONS site ayarını okur (varsayılan açık).
func ownerObjectionsEnabled(ctx context.Context, pool *pgxpool.Pool, propertyID string) (bool, error) {
	var v *bool
	err := dbscope.For(pool, propertyID).QueryRow(ctx,
		`SELECT value_bool FROM property_settings WHERE property_id = $1 AND setting_key = 'OWNER_PLAN_OBJECTIONS'`, propertyID).Scan(&v)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && v == nil) {
		return true, nil
	}
	if err != nil {
		return false, err
	}
	return *v, nil
}

// ownerUnits, kişinin bu sitede malik ya da vekil olduğu aktif bölümler.
func ownerUnits(ctx context.Context, pool *pgxpool.Pool, propertyID, userID string) (map[string]string, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
SELECT u.id::text, COALESCE(u.block,'') || CASE WHEN COALESCE(u.block,'') = '' THEN '' ELSE '-' END || u.door_number
FROM resident_units ru JOIN units u ON u.id = ru.unit_id
WHERE u.property_id = $1 AND ru.resident_id = $2 AND ru.role IN ('OWNER','PROXY') AND ru.is_active
  AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)`, propertyID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := map[string]string{}
	for rows.Next() {
		var id, name string
		if err := rows.Scan(&id, &name); err != nil {
			return nil, err
		}
		out[id] = name
	}
	return out, rows.Err()
}

func registerOwnerPlan(r *gin.Engine, svc *service.Service, pool *pgxpool.Pool) {
	g := r.Group("/api/v1/governance")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "governance"))

	g.GET("/my-budgets", func(c *gin.Context) {
		ctx, pid := c.Request.Context(), c.GetString("property_id")
		units, err := ownerUnits(ctx, pool, pid, c.GetString("user_id"))
		if err != nil {
			ownerFail(c, err, "bölüm")
			return
		}
		if len(units) == 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "İşletme projesini bölüm maliki ya da vekili görür (KMK m.37)"})
			return
		}
		list, err := svc.ListBudgets(ctx, pid)
		if err != nil {
			ownerFail(c, err, "proje listeleme")
			return
		}
		out := []gin.H{}
		for _, b := range list {
			if b.Status == "DRAFT" {
				continue
			}
			out = append(out, gin.H{"id": b.ID, "period_year": b.PeriodYear, "status": b.Status, "total_amount": b.TotalAmount,
				"notified_at": b.NotifiedAt, "approval_deadline": b.ApprovalDeadline, "finalized_at": b.FinalizedAt,
				"decision_ref": b.DecisionRef})
		}
		enabled, err := ownerObjectionsEnabled(ctx, pool, pid)
		if err != nil {
			ownerFail(c, err, "ayar")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "objections_enabled": enabled})
	})

	g.GET("/my-budgets/:id", func(c *gin.Context) {
		ctx, pid, uid := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		units, err := ownerUnits(ctx, pool, pid, uid)
		if err != nil {
			ownerFail(c, err, "bölüm")
			return
		}
		if len(units) == 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "İşletme projesini bölüm maliki ya da vekili görür (KMK m.37)"})
			return
		}
		b, err := svc.GetBudget(ctx, pid, c.Param("id"))
		if err != nil {
			ownerFail(c, err, "proje")
			return
		}
		if b.Status == "DRAFT" {
			c.JSON(http.StatusNotFound, gin.H{"error": "Proje bulunamadı"})
			return
		}
		shares := []gin.H{}
		for _, s := range b.UnitShares {
			if name, ok := units[s.UnitID]; ok {
				shares = append(shares, gin.H{"unit_id": s.UnitID, "unit_name": name, "annual_kurus": s.AnnualKurus,
					"monthly_kurus": s.MonthlyKurus, "annual_usage_kurus": s.AnnualUsageKurus, "annual_owner_kurus": s.AnnualOwnerKurus})
			}
		}
		objs, err := svc.ListObjections(ctx, pid, b.ID)
		if err != nil {
			ownerFail(c, err, "itirazlar")
			return
		}
		mine := []gin.H{}
		for _, o := range objs {
			if o.UserID == uid {
				mine = append(mine, gin.H{"id": o.ID, "unit_id": o.UnitID, "reason": o.Reason, "submitted_at": o.SubmittedAt,
					"status": o.Status, "resolution": o.Resolution, "resolved_at": o.ResolvedAt})
			}
		}
		enabled, err := ownerObjectionsEnabled(ctx, pool, pid)
		if err != nil {
			ownerFail(c, err, "ayar")
			return
		}
		myUnits := []gin.H{}
		for id, name := range units {
			myUnits = append(myUnits, gin.H{"id": id, "name": name})
		}
		c.JSON(http.StatusOK, gin.H{
			"budget": gin.H{"id": b.ID, "period_year": b.PeriodYear, "status": b.Status, "total_amount": b.TotalAmount,
				"notified_at": b.NotifiedAt, "approval_deadline": b.ApprovalDeadline, "finalized_at": b.FinalizedAt,
				"decision_ref": b.DecisionRef, "note": b.Note, "items": b.Items},
			"my_shares": shares, "my_units": myUnits, "my_objections": mine, "objections_enabled": enabled,
			"note": "Görüş ve itirazlar genel kurulda görüşülür; 7579 sayılı Kanun sonrası projenin kesinleşmesini engellemez (KMK m.37).",
		})
	})
}
