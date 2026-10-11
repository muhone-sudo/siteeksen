package main

// Malikin görünürlük politikası (altıncı tur D6, migration 071).
//   GET  /settings/owner-visibility                 — sitedeki herkes etkin politikayı görür (kiracıya şeffaflık);
//                                                     yönetim bekleyen öneriyi ve geçmişi de görür
//   POST /settings/owner-visibility                 — yönetim önerir {show_*…, note}
//   POST /settings/owner-visibility/:id/approve     — öneren DIŞINDAKİ bir kurul üyesi onaylar → yürürlük, kiracılara bildirim
//   POST /settings/owner-visibility/:id/reject      — öneren dışındaki kurul üyesi reddeder {note}
//   POST /settings/owner-visibility/:id/cancel      — öneren geri çeker
// Varsayılan (kayıt yoksa) en dar: seçenekli alanların hepsi kapalı.

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
)

type visibilityPolicy struct {
	ID                  string     `json:"id"`
	Status              string     `json:"status"`
	ShowTenantContact   bool       `json:"show_tenant_contact"`
	ShowTenantDebtTotal bool       `json:"show_tenant_debt_total"`
	ShowTenantOverdue   bool       `json:"show_tenant_overdue"`
	ShowUnitRequests    bool       `json:"show_unit_requests"`
	Note                string     `json:"note"`
	ProposedBy          string     `json:"proposed_by_name,omitempty"`
	ProposedByID        string     `json:"proposed_by"`
	ProposedAt          time.Time  `json:"proposed_at"`
	DecidedBy           string     `json:"decided_by_name,omitempty"`
	DecidedAt           *time.Time `json:"decided_at,omitempty"`
	DecisionNote        string     `json:"decision_note,omitempty"`
}

var visibilityLabels = []gin.H{
	{"key": "show_tenant_contact", "label": "Kiracının adı ve maskeli telefonu"},
	{"key": "show_tenant_debt_total", "label": "Kiracı sorumluluğundaki kullanım borcunun toplamı"},
	{"key": "show_tenant_overdue", "label": "Vadesi geçen kullanım borcu ve malike aylık uyarı"},
	{"key": "show_unit_requests", "label": "Dairenin arıza/talep kayıtları"},
}

var (
	visibilityAlways = []string{"Malik sınıfı borçlar (demirbaş, yenilik, yeni tesis)", "Genel kurul çağrıları ve oy işlemleri",
		"Dairenin oturum durumu (kiracı oturuyor / boş)", "Kiracılık bitiş süreçleri", "Kiracılık bittikten sonra kalan açık kullanım borcu"}
	visibilityNever = []string{"Ziyaretçi kayıtları", "Kargo kayıtları", "Sayaç ve tüketim pusulası ayrıntıları", "Hane üyeleri"}
)

const visibilitySelect = `
	SELECT p.id::text, p.status, p.show_tenant_contact, p.show_tenant_debt_total, p.show_tenant_overdue, p.show_unit_requests,
	       p.note, COALESCE(pu.first_name || ' ' || pu.last_name, ''), p.proposed_by::text, p.proposed_at,
	       COALESCE(du.first_name || ' ' || du.last_name, ''), p.decided_at, p.decision_note
	FROM owner_visibility_policies p
	LEFT JOIN users pu ON pu.id = p.proposed_by
	LEFT JOIN users du ON du.id = p.decided_by`

func scanVisibility(row pgx.Row) (*visibilityPolicy, error) {
	v := &visibilityPolicy{}
	err := row.Scan(&v.ID, &v.Status, &v.ShowTenantContact, &v.ShowTenantDebtTotal, &v.ShowTenantOverdue, &v.ShowUnitRequests,
		&v.Note, &v.ProposedBy, &v.ProposedByID, &v.ProposedAt, &v.DecidedBy, &v.DecidedAt, &v.DecisionNote)
	return v, err
}

func hasRole(c *gin.Context, roles ...string) bool {
	v, _ := c.Get("roles")
	have, _ := v.([]string)
	for _, h := range have {
		for _, r := range roles {
			if h == r {
				return true
			}
		}
	}
	return false
}

func failVisibility(c *gin.Context, err error) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[settings] görünürlük politikası: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}

func getVisibility(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		sc := dbscope.For(pool, propertyID)
		out := gin.H{"options": visibilityLabels, "always_visible": visibilityAlways, "never_visible": visibilityNever,
			"note": "Malikin kiracılı dairede neyi gördüğünü site yönetimi belirler (malik değil); site genelinde tek politika vardır, " +
				"değişiklik öneren dışındaki bir kurul üyesinin onayıyla yürürlüğe girer. Kayıt yoksa en dar ayar geçerlidir: seçenekli alanların hepsi kapalı."}
		active, err := scanVisibility(sc.QueryRow(ctx, visibilitySelect+` WHERE p.property_id = $1 AND p.status = 'ACTIVE'`, propertyID))
		switch {
		case errors.Is(err, pgx.ErrNoRows):
			out["active"] = &visibilityPolicy{Status: "DEFAULT"}
		case err != nil:
			failVisibility(c, err)
			return
		default:
			out["active"] = active
		}
		if hasRole(c, middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor) {
			rows, err := sc.Query(ctx, visibilitySelect+` WHERE p.property_id = $1 ORDER BY p.proposed_at DESC LIMIT 50`, propertyID)
			if err != nil {
				failVisibility(c, err)
				return
			}
			history := []*visibilityPolicy{}
			for rows.Next() {
				v, err := scanVisibility(rows)
				if err != nil {
					rows.Close()
					failVisibility(c, err)
					return
				}
				history = append(history, v)
				if v.Status == "PENDING" {
					out["pending"] = v
				}
			}
			rows.Close()
			out["history"] = history
		}
		c.JSON(http.StatusOK, out)
	}
}

func proposeVisibility(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			ShowTenantContact   bool   `json:"show_tenant_contact"`
			ShowTenantDebtTotal bool   `json:"show_tenant_debt_total"`
			ShowTenantOverdue   bool   `json:"show_tenant_overdue"`
			ShowUnitRequests    bool   `json:"show_unit_requests"`
			Note                string `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || len([]rune(strings.TrimSpace(in.Note))) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gerekçe (en az 10 karakter) zorunludur; kiracılar bu metni görür"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		var id string
		err := dbscope.For(pool, propertyID).QueryRow(ctx, `
			INSERT INTO owner_visibility_policies (property_id, show_tenant_contact, show_tenant_debt_total, show_tenant_overdue,
			                                       show_unit_requests, note, proposed_by)
			VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id::text`,
			propertyID, in.ShowTenantContact, in.ShowTenantDebtTotal, in.ShowTenantOverdue, in.ShowUnitRequests,
			strings.TrimSpace(in.Note), c.GetString("user_id")).Scan(&id)
		var pg *pgconn.PgError
		if errors.As(err, &pg) && pg.ConstraintName == "uq_owner_visibility_pending" {
			c.JSON(http.StatusConflict, gin.H{"error": "Onay bekleyen bir öneri zaten var; önce o sonuçlanmalı"})
			return
		}
		if err != nil {
			failVisibility(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "status": "PENDING",
			"message": "Öneri kaydedildi; öneren dışındaki bir kurul üyesi onaylayınca yürürlüğe girer."})
	}
}

// decideVisibility: onay / ret. Yalnız kurul üyesi ve öneren dışında biri karar verir.
func decideVisibility(pool *pgxpool.Pool, approve bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if !hasRole(c, middleware.RoleBoardMember) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Görünürlük politikasını yalnız yönetim kurulu üyesi onaylar ya da reddeder"})
			return
		}
		var in struct {
			Note string `json:"note"`
		}
		_ = c.ShouldBindJSON(&in)
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		tx, err := dbscope.For(pool, propertyID).Begin(ctx)
		if err != nil {
			failVisibility(c, err)
			return
		}
		defer tx.Rollback(ctx) //nolint:errcheck
		var proposer, status string
		err = tx.QueryRow(ctx, `SELECT proposed_by::text, status FROM owner_visibility_policies WHERE id = $1 AND property_id = $2 FOR UPDATE`,
			c.Param("id"), propertyID).Scan(&proposer, &status)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Öneri bulunamadı"})
			return
		}
		if err != nil {
			failVisibility(c, err)
			return
		}
		if status != "PENDING" {
			c.JSON(http.StatusConflict, gin.H{"error": "Öneri sonuçlanmış"})
			return
		}
		if proposer == userID {
			c.JSON(http.StatusForbidden, gin.H{"error": "Kendi önerinizi onaylayamaz ya da reddedemezsiniz; başka bir kurul üyesi karar vermeli"})
			return
		}
		next := "REJECTED"
		if approve {
			next = "ACTIVE"
			if _, err := tx.Exec(ctx, `UPDATE owner_visibility_policies SET status = 'SUPERSEDED' WHERE property_id = $1 AND status = 'ACTIVE'`, propertyID); err != nil {
				failVisibility(c, err)
				return
			}
		}
		if _, err := tx.Exec(ctx, `UPDATE owner_visibility_policies SET status = $2, decided_by = $3, decided_at = now(), decision_note = $4 WHERE id = $1`,
			c.Param("id"), next, userID, strings.TrimSpace(in.Note)); err != nil {
			failVisibility(c, err)
			return
		}
		if err := tx.Commit(ctx); err != nil {
			failVisibility(c, err)
			return
		}
		resp := gin.H{"status": next}
		if approve {
			resp["notification"] = notifyTenantsOfPolicy(ctx, pool, propertyID, userID, c.Param("id"))
			resp["message"] = "Politika yürürlüğe girdi; kiracılara bildirildi."
		} else {
			resp["message"] = "Öneri reddedildi; mevcut politika sürüyor."
		}
		c.JSON(http.StatusOK, resp)
	}
}

func cancelVisibility(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		tag, err := dbscope.For(pool, propertyID).Exec(ctx, `UPDATE owner_visibility_policies SET status = 'CANCELLED', decided_at = now()
			WHERE id = $1 AND property_id = $2 AND status = 'PENDING' AND proposed_by = $3`, c.Param("id"), propertyID, c.GetString("user_id"))
		if err != nil {
			failVisibility(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Geri çekilebilecek öneriniz yok"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "CANCELLED", "message": "Öneri geri çekildi."})
	}
}

// notifyTenantsOfPolicy: yürürlüğe giren politikayı bütün aktif kiracılara bildirir (şeffaflık).
// visibilityNotifier, servis açılışında kurulur (main).
var visibilityNotifier *notify.Notifier

func notifyTenantsOfPolicy(ctx context.Context, pool *pgxpool.Pool, propertyID, actorID, policyID string) *notify.BroadcastResult {
	n := visibilityNotifier
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; kiracılara bildirim oluşturulmadı."}
	}
	recipients, err := notify.Tenants(ctx, pool, propertyID)
	if err != nil {
		return &notify.BroadcastResult{Note: "Kiracılar okunamadı; bildirim oluşturulmadı.", Errors: []string{err.Error()}}
	}
	var v visibilityPolicy
	if err := dbscope.For(pool, propertyID).QueryRow(ctx, `SELECT show_tenant_contact, show_tenant_debt_total, show_tenant_overdue, show_unit_requests
		FROM owner_visibility_policies WHERE id = $1`, policyID).Scan(&v.ShowTenantContact, &v.ShowTenantDebtTotal, &v.ShowTenantOverdue, &v.ShowUnitRequests); err != nil {
		return &notify.BroadcastResult{Note: "Politika okunamadı; bildirim oluşturulmadı.", Errors: []string{err.Error()}}
	}
	open := []string{}
	for _, x := range []struct {
		on    bool
		label string
	}{{v.ShowTenantContact, "adınız ve maskeli telefonunuz"}, {v.ShowTenantDebtTotal, "borç toplamınız"},
		{v.ShowTenantOverdue, "vadesi geçen borcunuz"}, {v.ShowUnitRequests, "dairenin talep kayıtları"}} {
		if x.on {
			open = append(open, x.label)
		}
	}
	what := "Maliki seçenekli hiçbir bilginizi görmüyor."
	if len(open) > 0 {
		what = "Malikiniz artık şunları görebilir: " + strings.Join(open, ", ") + "."
	}
	return n.Broadcast(ctx, notify.Message{
		PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Topic: "visibility.policy", Subject: "Malikin görebildikleri değişti",
		Body:      fmt.Sprintf("Site yönetimi malik görünürlük politikasını değiştirdi. %s Ayrıntı uygulamadaki \"Malikim neyi görüyor\" ekranındadır.", what),
		Payload:   map[string]any{"policy_id": policyID},
		DedupeKey: "visibility.policy:" + policyID,
		CreatedBy: actorID,
	}, recipients)
}
