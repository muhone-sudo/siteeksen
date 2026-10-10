package main

// Geçiş cihazı canlılık izleme (migration 057, Apsiyon BUG-08).
//
// Cihaz (PTS kamerası, bariyer ünitesi) kendi anahtarıyla düzenli sinyal gönderir:
//   POST /api/v1/public/devices/heartbeat   X-Device-Key: dev_…   {"status":"…"}
// Bekçi (DEVICE_WATCH_INTERVAL, varsayılan 30 sn) eşik süresini aşan cihaz için olay açar ve
// yönetim + görevliye bildirim gönderir; sinyal geri gelince olay kapanır ve "yeniden
// çevrimiçi" bildirimi gider. Zamanlayıcı (cmd/scheduler) saatlik çalıştığı için bu iş
// orada değil burada yapılır: 3 dakikalık alarm hedefi saatlik turla karşılanamaz.
//
// Bariyerin uzaktan açılması bu sürümde YOKTUR: cihaz üreticisinin komut protokolü
// olmadan "açıldı" demek sakini kapıda bırakırdı.

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/parking/repository"
)

var deviceKindLabel = map[string]string{
	"PTS_CAMERA": "Plaka tanıma kamerası", "BARRIER": "Bariyer", "TURNSTILE": "Turnike", "INTERCOM": "Kapı telefonu", "OTHER": "Cihaz",
}

func registerDevices(r *gin.Engine, repo *repository.Repository, pool *pgxpool.Pool, n *notify.Notifier) {
	// Kimliksiz uç: cihazın kimliği anahtarıdır (gateway'de public yol).
	r.POST("/api/v1/public/devices/heartbeat", func(c *gin.Context) {
		key := strings.TrimSpace(c.GetHeader("X-Device-Key"))
		if key == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "X-Device-Key başlığı zorunludur"})
			return
		}
		var in struct {
			Status string `json:"status"`
		}
		_ = c.ShouldBindJSON(&in)
		deviceID, propertyID, recovered, err := repo.Heartbeat(c.Request.Context(), key, in.Status)
		if errors.Is(err, repository.ErrUnknownDevice) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Cihaz anahtarı tanınmadı ya da cihaz pasif"})
			return
		}
		if err != nil {
			log.Printf("[parking] cihaz sinyali: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Sinyal kaydedilemedi"})
			return
		}
		if recovered != nil {
			notifyDevice(c.Request.Context(), n, pool, repo, propertyID, deviceID, *recovered, false)
		}
		c.JSON(http.StatusOK, gin.H{"status": "ok", "recovered": recovered != nil})
	})

	g := r.Group("/api/v1/access-devices")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "parking"))
	view := g.Group("")
	view.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff, middleware.RoleAuditor))
	view.GET("", func(c *gin.Context) {
		list, err := repo.ListDevices(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "cihaz listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "valid_kinds": repository.DeviceKinds})
	})
	view.GET("/incidents", func(c *gin.Context) {
		list, err := repo.ListIncidents(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			fail(c, err, "olay listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	admin := g.Group("")
	admin.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	admin.POST("", func(c *gin.Context) {
		var in repository.DeviceInput
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Name) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "name ve kind zorunludur", "valid_kinds": repository.DeviceKinds})
			return
		}
		id, key, err := repo.CreateDevice(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			fail(c, err, "cihaz kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "device_key": key,
			"note": "Anahtarı cihaza şimdi girin; bir daha gösterilmez (yalnızca özeti saklanır). Cihaz her sinyal aralığında " +
				"POST /api/v1/public/devices/heartbeat ucuna X-Device-Key başlığıyla istek göndermelidir."})
	})
	admin.DELETE("/:id", func(c *gin.Context) {
		if err := repo.DeactivateDevice(c.Request.Context(), c.GetString("property_id"), c.Param("id")); err != nil {
			fail(c, err, "cihaz pasife alma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Cihaz pasife alındı; izleme durdu", "note": "Kayıt ve olay geçmişi silinmez."})
	})
}

// notifyDevice, çevrimdışı (offline=true) ya da yeniden çevrimiçi bildirimini gönderir.
func notifyDevice(ctx context.Context, n *notify.Notifier, pool *pgxpool.Pool, repo *repository.Repository,
	propertyID, deviceID, incidentID string, offline bool) {
	if n == nil {
		log.Printf("[parking] bildirim altyapısı yok; cihaz olayı %s bildirilemedi", incidentID)
		return
	}
	name, kind, err := repo.DeviceName(ctx, propertyID, deviceID)
	if err != nil {
		log.Printf("[parking] cihaz adı okunamadı: %v", err)
		return
	}
	recipients, err := notify.Operations(ctx, pool, propertyID)
	if err != nil {
		log.Printf("[parking] alıcılar okunamadı: %v", err)
		return
	}
	label := deviceKindLabel[kind]
	msg := notify.Message{PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Payload: map[string]any{"device_id": deviceID, "incident_id": incidentID}}
	if offline {
		msg.Topic, msg.Subject = "device.offline", label+" çevrimdışı: "+name
		msg.Body = label + " \"" + name + "\" belirlenen süre içinde sinyal göndermedi. Cihazı ve bağlantısını kontrol edin; " +
			"geçişleri görevli elle kaydetmelidir."
		msg.DedupeKey = "device.offline:" + incidentID
	} else {
		msg.Topic, msg.Subject = "device.recovered", label+" yeniden çevrimiçi: "+name
		msg.Body = label + " \"" + name + "\" yeniden sinyal göndermeye başladı."
		msg.DedupeKey = "device.recovered:" + incidentID
	}
	res := n.Broadcast(ctx, msg, recipients)
	log.Printf("[parking] cihaz olayı %s (%s): %s", incidentID, msg.Topic, res.Note)
}

// startDeviceWatch, eşik süresini aşan cihazlar için olay açan bekçiyi başlatır.
func startDeviceWatch(ctx context.Context, repo *repository.Repository, pool *pgxpool.Pool, n *notify.Notifier) {
	interval := 30 * time.Second
	if v := strings.TrimSpace(os.Getenv("DEVICE_WATCH_INTERVAL")); v != "" {
		if v == "off" {
			log.Printf("[parking] cihaz bekçisi kapalı (DEVICE_WATCH_INTERVAL=off)")
			return
		}
		d, err := time.ParseDuration(v)
		if err != nil || d < time.Second {
			log.Fatalf("[parking] DEVICE_WATCH_INTERVAL geçersiz: %q", v)
		}
		interval = d
	}
	go func() {
		t := time.NewTicker(interval)
		defer t.Stop()
		for {
			watchOnce(ctx, repo, pool, n)
			select {
			case <-ctx.Done():
				return
			case <-t.C:
			}
		}
	}()
}

func watchOnce(ctx context.Context, repo *repository.Repository, pool *pgxpool.Pool, n *notify.Notifier) {
	ids, err := repo.WatchPropertyIDs(ctx)
	if err != nil {
		log.Printf("[parking] cihaz bekçisi: %v", err)
		return
	}
	for _, pid := range ids {
		incidents, err := repo.OpenOfflineIncidents(ctx, pid)
		if err != nil {
			log.Printf("[parking] cihaz bekçisi (site %s): %v", pid, err)
			continue
		}
		for _, inc := range incidents {
			notifyDevice(ctx, n, pool, repo, pid, inc.DeviceID, inc.ID, true)
		}
	}
}
