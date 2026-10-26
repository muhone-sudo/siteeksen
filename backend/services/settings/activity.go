package main

// İşlem kaydı (073, FAZ H.3, kullanıcı kararı K5): istemci etkinliğinin alınması ve sitenin
// denetim izinin görüntülenmesi. Kayıtlar audit_logs'ta tek yerde durur; uygulama rolü tabloyu
// doğrudan okuyamaz, okuma yalnız aktif siteyle sınırlı audit_log_list / audit_log_stats
// işlevleriyle yapılır.

import (
	"encoding/csv"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/audit"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

// clientEvents: istemcinin gönderebileceği olay türleri. Bilinmeyen tür reddedilir
// (istemci kayda keyfi içerik basamasın).
var clientEvents = map[string]bool{
	"screen.view": true, "menu.open": true, "tab.change": true, "search": true, "filter": true,
	"export": true, "action.click": true, "session.start": true, "session.end": true,
}

const (
	maxEventsPerRequest = 50
	maxEventsPerMinute  = 300
	maxDetailBytes      = 2000
)

type rateWindow struct {
	start time.Time
	count int
}

var (
	rateMu sync.Mutex
	rates  = map[string]*rateWindow{}
)

// allowEvents, kişi başı dakikalık sınırı uygular; izin verilen olay sayısını döner.
func allowEvents(userID string, n int) int {
	rateMu.Lock()
	defer rateMu.Unlock()
	w := rates[userID]
	if w == nil || time.Since(w.start) > time.Minute {
		w = &rateWindow{start: time.Now()}
		rates[userID] = w
	}
	left := maxEventsPerMinute - w.count
	if left <= 0 {
		return 0
	}
	if n > left {
		n = left
	}
	w.count += n
	return n
}

func registerActivity(r *gin.Engine, pool *pgxpool.Pool) {
	// İstemci etkinliği kendi başına denetim kaydıdır; AuditLog ara katmanı bu grupta YOKTUR
	// (aynı olayı iki kez yazmamak için).
	act := r.Group("/api/v1")
	act.Use(middleware.AuthMiddleware(pool))
	act.GET("/activity-level", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"level": middleware.ActivityLogLevel(c.Request.Context(), pool, c.GetString("property_id"))})
	})
	act.POST("/activity", func(c *gin.Context) {
		var in struct {
			Events []struct {
				Event    string         `json:"event"`
				Screen   string         `json:"screen"`
				Details  map[string]any `json:"details"`
				ClientAt string         `json:"client_at"`
				Client   string         `json:"client"`
			} `json:"events"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || len(in.Events) == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "events alanı zorunludur"})
			return
		}
		if len(in.Events) > maxEventsPerRequest {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": fmt.Sprintf("Tek istekte en çok %d olay gönderilebilir", maxEventsPerRequest)})
			return
		}
		pid, uid := c.GetString("property_id"), c.GetString("user_id")
		level := middleware.ActivityLogLevel(c.Request.Context(), pool, pid)
		if level != middleware.LogLevelFull {
			c.JSON(http.StatusOK, gin.H{"accepted": 0, "level": level,
				"note": "Uygulama içi etkinlik yalnız TAM düzeyde kaydedilir."})
			return
		}
		allowed := allowEvents(uid, len(in.Events))
		accepted, rejected := 0, 0
		for i, e := range in.Events {
			if i >= allowed {
				rejected += len(in.Events) - i
				break
			}
			if !clientEvents[e.Event] {
				rejected++
				continue
			}
			details := map[string]any{}
			for k, v := range e.Details {
				details[k] = v
			}
			if e.ClientAt != "" {
				details["client_at"] = e.ClientAt
			}
			if e.Client != "" {
				details["client"] = e.Client
			}
			if b := fmt.Sprint(details); len(b) > maxDetailBytes {
				details = map[string]any{"truncated": true}
			}
			err := audit.Log(c.Request.Context(), pool, audit.Entry{
				UserID: uid, PropertyID: pid, IPAddress: c.ClientIP(), UserAgent: c.Request.UserAgent(),
				Action: "CLIENT", EntityType: "client", Source: "CLIENT",
				Event: e.Event, Screen: e.Screen, Details: details,
			})
			if err != nil {
				log.Printf("[settings] istemci etkinliği yazılamadı: %v", err)
				rejected++
				continue
			}
			accepted++
		}
		c.JSON(http.StatusOK, gin.H{"accepted": accepted, "rejected": rejected, "level": level})
	})

	// Görüntüleme: site yöneticisi ve denetçi (KMK m.41). Görüntüleme de kayda geçer.
	view := r.Group("/api/v1")
	view.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "audit"),
		middleware.RequireRole(middleware.RoleManager, middleware.RoleAuditor))
	view.GET("/audit-logs", func(c *gin.Context) {
		rows, err := listAuditLogs(c, pool, 0)
		if err != nil {
			auditFail(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": rows, "level": middleware.ActivityLogLevel(c.Request.Context(), pool, c.GetString("property_id"))})
	})
	view.GET("/audit-logs/stats", func(c *gin.Context) {
		r, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(),
			`SELECT source, action, total, oldest FROM audit_log_stats()`)
		if err != nil {
			auditFail(c, err)
			return
		}
		defer r.Close()
		out := []gin.H{}
		for r.Next() {
			var source, action string
			var total int64
			var oldest *time.Time
			if err := r.Scan(&source, &action, &total, &oldest); err != nil {
				auditFail(c, err)
				return
			}
			out = append(out, gin.H{"source": source, "action": action, "total": total, "oldest": oldest})
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "period_days": 30})
	})
	view.GET("/audit-logs/export", func(c *gin.Context) {
		c.Set("audit_event", "audit.export")
		rows, err := listAuditLogs(c, pool, 1000)
		if err != nil {
			auditFail(c, err)
			return
		}
		c.Header("Content-Type", "text/csv; charset=utf-8")
		c.Header("Content-Disposition", fmt.Sprintf(`attachment; filename="islem-kayitlari-%s.csv"`, time.Now().Format("2006-01-02")))
		c.Status(http.StatusOK)
		_, _ = c.Writer.Write([]byte("\xEF\xBB\xBF"))
		w := csv.NewWriter(c.Writer)
		w.Comma = ';'
		_ = w.Write([]string{"Zaman", "Kullanıcı", "IP", "Kaynak", "İşlem", "Olay", "Modül", "Ekran/yol", "Durum kodu", "Kayıt"})
		for _, r := range rows {
			_ = w.Write([]string{r.CreatedAt.Format(time.RFC3339), r.UserName, r.IP, r.Source, r.Action, r.Event,
				r.EntityType, r.Screen, strconv.Itoa(r.StatusCode), r.EntityID})
		}
		w.Flush()
	})
}

type auditRow struct {
	ID         string         `json:"id"`
	CreatedAt  time.Time      `json:"created_at"`
	UserID     string         `json:"user_id,omitempty"`
	UserName   string         `json:"user_name,omitempty"`
	IP         string         `json:"ip,omitempty"`
	Action     string         `json:"action"`
	EntityType string         `json:"entity_type"`
	EntityID   string         `json:"entity_id,omitempty"`
	StatusCode int            `json:"status_code,omitempty"`
	Source     string         `json:"source"`
	Event      string         `json:"event,omitempty"`
	Screen     string         `json:"screen,omitempty"`
	Details    map[string]any `json:"details,omitempty"`
	RequestID  string         `json:"request_id,omitempty"`
}

var errBadFilter = errors.New("geçersiz süzgeç")

func listAuditLogs(c *gin.Context, pool *pgxpool.Pool, forceLimit int) ([]auditRow, error) {
	var from, to *time.Time
	if v := c.Query("from"); v != "" {
		t, err := time.Parse("2006-01-02", v)
		if err != nil {
			return nil, errBadFilter
		}
		from = &t
	}
	if v := c.Query("to"); v != "" {
		t, err := time.Parse("2006-01-02", v)
		if err != nil {
			return nil, errBadFilter
		}
		t = t.AddDate(0, 0, 1)
		to = &t
	}
	nullable := func(k string) *string {
		if v := strings.TrimSpace(c.Query(k)); v != "" {
			return &v
		}
		return nil
	}
	limit, _ := strconv.Atoi(c.Query("limit"))
	offset, _ := strconv.Atoi(c.Query("offset"))
	if forceLimit > 0 {
		limit, offset = forceLimit, 0
	}
	rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
SELECT id::text, created_at, COALESCE(user_id::text,''), COALESCE(user_name,''), COALESCE(ip_address,''),
       action, COALESCE(entity_type,''), COALESCE(entity_id::text,''), COALESCE(status_code,0), source,
       COALESCE(event,''), COALESCE(screen,''), details, COALESCE(request_id,'')
FROM audit_log_list($1, $2, $3::uuid, $4, $5, $6, $7, $8, $9)`,
		from, to, nullable("user_id"), nullable("action"), nullable("entity"), nullable("source"), nullable("q"), limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []auditRow{}
	for rows.Next() {
		var r auditRow
		if err := rows.Scan(&r.ID, &r.CreatedAt, &r.UserID, &r.UserName, &r.IP, &r.Action, &r.EntityType,
			&r.EntityID, &r.StatusCode, &r.Source, &r.Event, &r.Screen, &r.Details, &r.RequestID); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

func auditFail(c *gin.Context, err error) {
	if errors.Is(err, errBadFilter) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tarih YYYY-AA-GG biçiminde olmalı"})
		return
	}
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusOK, gin.H{"data": []any{}})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[settings] işlem kaydı okunamadı: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem kayıtları okunamadı"})
}
