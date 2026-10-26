package main

// IoT sensörleri (074, FAZ H.4, kullanıcı kararı K1). Cihaz okumayı kendi anahtarıyla
// (X-Device-Key) kimliksiz uca gönderir; eşik dışı değer, tetiklenen ikili sensör ya da
// kesilen sinyal alarm açar ve işletme ekibine (Operations) bildirim gider. Alarm sensör ve
// tür başına tektir; değer normale dönünce "normale döndü" işaretlenir, kapatma insan işidir.

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
)

var sensorTypeLabel = map[string]string{
	"WATER_LEAK": "Su kaçağı", "TEMPERATURE": "Sıcaklık", "HUMIDITY": "Nem", "SMOKE": "Duman", "GAS": "Gaz",
	"POWER_OUTAGE": "Elektrik kesintisi", "TANK_LEVEL": "Depo seviyesi", "ELEVATOR_FAULT": "Asansör arızası",
	"DOOR_OPEN": "Kapı açık", "OTHER": "Sensör",
}

// binarySensors: değeri 1 (tetiklendi) / 0 (normal) olan sensörler; eşik yerine tetik alarmı açar.
var binarySensors = map[string]bool{"WATER_LEAK": true, "SMOKE": true, "GAS": true, "POWER_OUTAGE": true,
	"ELEVATOR_FAULT": true, "DOOR_OPEN": true}

var alertKindLabel = map[string]string{"HIGH": "üst eşik aşıldı", "LOW": "alt eşiğin altında", "TRIGGERED": "tetiklendi", "OFFLINE": "sinyal kesildi"}

type sensorInput struct {
	Name                string   `json:"name"`
	SensorType          string   `json:"sensor_type"`
	Location            string   `json:"location"`
	UnitLabel           string   `json:"unit_label"`
	MinThreshold        *float64 `json:"min_threshold"`
	MaxThreshold        *float64 `json:"max_threshold"`
	OfflineAfterMinutes int      `json:"offline_after_minutes"`
}

func (in *sensorInput) validate() error {
	in.Name = strings.TrimSpace(in.Name)
	in.SensorType = strings.ToUpper(strings.TrimSpace(in.SensorType))
	if in.Name == "" {
		return errors.New("Ad zorunludur")
	}
	if _, ok := sensorTypeLabel[in.SensorType]; !ok {
		return errors.New("Geçersiz sensör türü")
	}
	if in.MinThreshold != nil && in.MaxThreshold != nil && *in.MinThreshold >= *in.MaxThreshold {
		return errors.New("Alt eşik üst eşikten küçük olmalı")
	}
	if !binarySensors[in.SensorType] && in.MinThreshold == nil && in.MaxThreshold == nil {
		return errors.New("Sayısal sensörde en az bir eşik (alt ya da üst) gerekir; eşiksiz sensör alarm üretmez")
	}
	if in.OfflineAfterMinutes == 0 {
		in.OfflineAfterMinutes = 30
	}
	if in.OfflineAfterMinutes < 2 || in.OfflineAfterMinutes > 1440 {
		return errors.New("Sinyal kesilme süresi 2-1440 dakika olmalı")
	}
	return nil
}

func newDeviceKey() (string, string, error) {
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return "", "", err
	}
	key := "sen_" + hex.EncodeToString(raw)
	sum := sha256.Sum256([]byte(key))
	return key, hex.EncodeToString(sum[:]), nil
}

func hashKey(key string) string {
	sum := sha256.Sum256([]byte(key))
	return hex.EncodeToString(sum[:])
}

const sensorCols = `s.id::text, s.name, s.sensor_type, COALESCE(s.location,''), COALESCE(s.unit_label,''),
	s.min_threshold::float8, s.max_threshold::float8, s.offline_after_minutes, s.last_value::float8, s.last_seen_at,
	s.is_active, s.created_at,
	(SELECT count(*) FROM sensor_alerts a WHERE a.sensor_id = s.id AND a.status <> 'CLOSED')`

func scanSensor(row pgx.Row) (gin.H, error) {
	var id, name, typ, loc, unit string
	var minT, maxT, last *float64
	var offline int
	var seen *time.Time
	var active bool
	var created time.Time
	var openAlerts int
	if err := row.Scan(&id, &name, &typ, &loc, &unit, &minT, &maxT, &offline, &last, &seen, &active, &created, &openAlerts); err != nil {
		return nil, err
	}
	state := "OK"
	switch {
	case !active:
		state = "PASSIVE"
	case seen == nil:
		state = "NO_DATA"
	case time.Since(*seen) > time.Duration(offline)*time.Minute:
		state = "OFFLINE"
	case openAlerts > 0:
		state = "ALERT"
	}
	return gin.H{"id": id, "name": name, "sensor_type": typ, "type_label": sensorTypeLabel[typ], "location": loc,
		"unit_label": unit, "min_threshold": minT, "max_threshold": maxT, "offline_after_minutes": offline,
		"last_value": last, "last_seen_at": seen, "is_active": active, "created_at": created,
		"open_alerts": openAlerts, "state": state, "binary": binarySensors[typ]}, nil
}

func registerSensors(r *gin.Engine, pool *pgxpool.Pool, n *notify.Notifier) {
	// Cihazdan okuma (kimliksiz; anahtar özetiyle çözülür).
	r.POST("/api/v1/public/sensors/data", func(c *gin.Context) {
		key := strings.TrimSpace(c.GetHeader("X-Device-Key"))
		if key == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "X-Device-Key başlığı zorunludur"})
			return
		}
		var in struct {
			Value      *float64 `json:"value"`
			RecordedAt string   `json:"recorded_at"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.Value == nil || math.IsNaN(*in.Value) || math.IsInf(*in.Value, 0) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "value (sayı) zorunludur"})
			return
		}
		var at *time.Time
		if in.RecordedAt != "" {
			t, err := time.Parse(time.RFC3339, in.RecordedAt)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "recorded_at RFC3339 olmalı"})
				return
			}
			at = &t
		}
		var sensorID, propertyID string
		err := pool.QueryRow(c.Request.Context(), `SELECT sensor_id::text, property_id::text FROM sensor_ingest($1, $2, $3)`,
			hashKey(key), *in.Value, at).Scan(&sensorID, &propertyID)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Sensör anahtarı tanınmadı ya da sensör pasif"})
			return
		}
		if err != nil {
			log.Printf("[iot] sensör okuması: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Okuma kaydedilemedi"})
			return
		}
		opened, normalized := evaluateReading(c.Request.Context(), pool, n, propertyID, sensorID, *in.Value)
		c.JSON(http.StatusOK, gin.H{"status": "ok", "alert_opened": opened, "normalized": normalized})
	})

	// Ayrı grup: rota denetleyicisi (check-gateway-routes.py) önekleri dosya içinde çözer.
	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "iot"))
	ops := []string{middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff, middleware.RoleAuditor}
	view := api.Group("")
	view.Use(middleware.RequireRole(ops...))
	view.GET("/sensors", func(c *gin.Context) {
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(),
			`SELECT `+sensorCols+` FROM sensors s WHERE s.property_id = $1 ORDER BY s.is_active DESC, s.name`, c.GetString("property_id"))
		if err != nil {
			sensorFail(c, err)
			return
		}
		defer rows.Close()
		out := []gin.H{}
		for rows.Next() {
			s, err := scanSensor(rows)
			if err != nil {
				sensorFail(c, err)
				return
			}
			out = append(out, s)
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "types": sensorTypeLabel})
	})
	view.GET("/sensors/:id", func(c *gin.Context) {
		s, err := scanSensor(dbscope.For(pool, c.GetString("property_id")).QueryRow(c.Request.Context(),
			`SELECT `+sensorCols+` FROM sensors s WHERE s.id = $1 AND s.property_id = $2`, c.Param("id"), c.GetString("property_id")))
		if err != nil {
			sensorFail(c, err)
			return
		}
		c.JSON(http.StatusOK, s)
	})
	view.GET("/sensors/:id/data", func(c *gin.Context) {
		hours, _ := strconv.Atoi(c.DefaultQuery("hours", "24"))
		if hours < 1 || hours > 24*31 {
			hours = 24
		}
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
SELECT value::float8, recorded_at FROM sensor_readings
WHERE sensor_id = $1 AND property_id = $2 AND recorded_at >= now() - make_interval(hours => $3)
ORDER BY recorded_at DESC LIMIT 2000`, c.Param("id"), c.GetString("property_id"), hours)
		if err != nil {
			sensorFail(c, err)
			return
		}
		defer rows.Close()
		out := []gin.H{}
		for rows.Next() {
			var v float64
			var at time.Time
			if err := rows.Scan(&v, &at); err != nil {
				sensorFail(c, err)
				return
			}
			out = append(out, gin.H{"value": v, "recorded_at": at})
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "hours": hours, "truncated": len(out) == 2000})
	})
	view.GET("/iot/alerts", func(c *gin.Context) {
		status := strings.ToUpper(c.Query("status"))
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
SELECT a.id::text, a.sensor_id::text, s.name, s.sensor_type, COALESCE(s.location,''), a.kind, a.value::float8, a.threshold::float8,
       a.status, a.opened_at, a.normalized_at, a.acknowledged_at,
       COALESCE(ua.first_name || ' ' || ua.last_name, ''), a.closed_at, COALESCE(uc.first_name || ' ' || uc.last_name, ''),
       COALESCE(a.close_note,'')
FROM sensor_alerts a JOIN sensors s ON s.id = a.sensor_id
LEFT JOIN users ua ON ua.id = a.acknowledged_by LEFT JOIN users uc ON uc.id = a.closed_by
WHERE a.property_id = $1 AND ($2 = '' OR a.status = $2 OR ($2 = 'ACTIVE' AND a.status <> 'CLOSED'))
ORDER BY (a.status = 'CLOSED'), a.opened_at DESC LIMIT 500`, c.GetString("property_id"), status)
		if err != nil {
			sensorFail(c, err)
			return
		}
		defer rows.Close()
		out := []gin.H{}
		for rows.Next() {
			var id, sid, name, typ, loc, kind, st, ackBy, closedBy, note string
			var val, thr *float64
			var opened time.Time
			var norm, ack, closed *time.Time
			if err := rows.Scan(&id, &sid, &name, &typ, &loc, &kind, &val, &thr, &st, &opened, &norm, &ack, &ackBy, &closed, &closedBy, &note); err != nil {
				sensorFail(c, err)
				return
			}
			out = append(out, gin.H{"id": id, "sensor_id": sid, "sensor_name": name, "sensor_type": typ, "type_label": sensorTypeLabel[typ],
				"location": loc, "kind": kind, "kind_label": alertKindLabel[kind], "value": val, "threshold": thr, "status": st,
				"opened_at": opened, "normalized_at": norm, "acknowledged_at": ack, "acknowledged_by": ackBy,
				"closed_at": closed, "closed_by": closedBy, "close_note": note})
		}
		c.JSON(http.StatusOK, gin.H{"data": out})
	})

	// Alarm onayı ve kapatma: sahadaki görevli dahil işletme ekibi.
	act := api.Group("")
	act.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	act.POST("/iot/alerts/:id/acknowledge", func(c *gin.Context) {
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
UPDATE sensor_alerts SET status = 'ACKNOWLEDGED', acknowledged_at = now(), acknowledged_by = $3
WHERE id = $1 AND property_id = $2 AND status = 'OPEN'`, c.Param("id"), c.GetString("property_id"), c.GetString("user_id"))
		if err != nil {
			sensorFail(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Alarm bulunamadı ya da zaten onaylanmış/kapatılmış"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Alarm onaylandı; sorun giderilince kapatın"})
	})
	act.POST("/iot/alerts/:id/close", func(c *gin.Context) {
		var in struct {
			Note string `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Note) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Kapatma notu zorunludur (ne yapıldı?)"})
			return
		}
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
UPDATE sensor_alerts SET status = 'CLOSED', closed_at = now(), closed_by = $3, close_note = $4,
       acknowledged_at = COALESCE(acknowledged_at, now()), acknowledged_by = COALESCE(acknowledged_by, $3)
WHERE id = $1 AND property_id = $2 AND status <> 'CLOSED'`, c.Param("id"), c.GetString("property_id"), c.GetString("user_id"), strings.TrimSpace(in.Note))
		if err != nil {
			sensorFail(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Alarm bulunamadı ya da zaten kapatılmış"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Alarm kapatıldı"})
	})

	// Tanım: yönetim.
	admin := api.Group("")
	admin.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	admin.POST("/sensors", func(c *gin.Context) {
		var in sensorInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek"})
			return
		}
		if err := in.validate(); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error(), "types": sensorTypeLabel})
			return
		}
		key, hash, err := newDeviceKey()
		if err != nil {
			sensorFail(c, err)
			return
		}
		var id string
		err = dbscope.For(pool, c.GetString("property_id")).QueryRow(c.Request.Context(), `
INSERT INTO sensors (property_id, name, sensor_type, location, unit_label, min_threshold, max_threshold, key_hash, offline_after_minutes, created_by)
VALUES ($1, $2, $3, NULLIF($4,''), NULLIF($5,''), $6, $7, $8, $9, $10) RETURNING id::text`,
			c.GetString("property_id"), in.Name, in.SensorType, strings.TrimSpace(in.Location), strings.TrimSpace(in.UnitLabel),
			in.MinThreshold, in.MaxThreshold, hash, in.OfflineAfterMinutes, c.GetString("user_id")).Scan(&id)
		if err != nil {
			sensorFail(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "device_key": key,
			"note": "Anahtarı cihaza şimdi girin; bir daha gösterilmez (yalnız özeti saklanır). Cihaz okumayı " +
				"POST /api/v1/public/sensors/data ucuna X-Device-Key başlığı ve {\"value\": sayı} gövdesiyle göndermelidir."})
	})
	admin.PATCH("/sensors/:id", func(c *gin.Context) {
		var in struct {
			sensorInput
			IsActive *bool `json:"is_active"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek"})
			return
		}
		if err := in.validate(); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
			return
		}
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
UPDATE sensors SET name = $3, sensor_type = $4, location = NULLIF($5,''), unit_label = NULLIF($6,''),
       min_threshold = $7, max_threshold = $8, offline_after_minutes = $9, is_active = COALESCE($10, is_active), updated_at = now()
WHERE id = $1 AND property_id = $2`, c.Param("id"), c.GetString("property_id"), in.Name, in.SensorType,
			strings.TrimSpace(in.Location), strings.TrimSpace(in.UnitLabel), in.MinThreshold, in.MaxThreshold, in.OfflineAfterMinutes, in.IsActive)
		if err != nil {
			sensorFail(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Sensör bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Sensör güncellendi", "note": "Eşik değişikliği bir sonraki okumadan itibaren uygulanır."})
	})
	admin.POST("/sensors/:id/rotate-key", func(c *gin.Context) {
		key, hash, err := newDeviceKey()
		if err != nil {
			sensorFail(c, err)
			return
		}
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(),
			`UPDATE sensors SET key_hash = $3, updated_at = now() WHERE id = $1 AND property_id = $2`, c.Param("id"), c.GetString("property_id"), hash)
		if err != nil {
			sensorFail(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusNotFound, gin.H{"error": "Sensör bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"device_key": key, "note": "Eski anahtar artık geçersiz. Yeni anahtarı cihaza girin; bir daha gösterilmez."})
	})
}

// evaluateReading, okumayı sensörün eşikleriyle karşılaştırır: gerekiyorsa alarm açar ve bildirir,
// değer normale dönmüşse açık değer alarmlarını "normale döndü" işaretler. Sinyal geldiği için
// açık OFFLINE alarmı da normale döner.
func evaluateReading(ctx context.Context, pool *pgxpool.Pool, n *notify.Notifier, propertyID, sensorID string, value float64) (bool, bool) {
	sc := dbscope.For(pool, propertyID)
	var typ string
	var minT, maxT *float64
	if err := sc.QueryRow(ctx, `SELECT sensor_type, min_threshold::float8, max_threshold::float8 FROM sensors WHERE id = $1`, sensorID).
		Scan(&typ, &minT, &maxT); err != nil {
		log.Printf("[iot] sensör okunamadı: %v", err)
		return false, false
	}
	kind, threshold := "", (*float64)(nil)
	switch {
	case binarySensors[typ] && value >= 1:
		kind = "TRIGGERED"
	case !binarySensors[typ] && maxT != nil && value > *maxT:
		kind, threshold = "HIGH", maxT
	case !binarySensors[typ] && minT != nil && value < *minT:
		kind, threshold = "LOW", minT
	}
	normalized := false
	tag, err := sc.Exec(ctx, `
UPDATE sensor_alerts SET normalized_at = now()
WHERE sensor_id = $1 AND status <> 'CLOSED' AND normalized_at IS NULL AND (kind = 'OFFLINE' OR kind <> $2)`, sensorID, kind)
	if err == nil && tag.RowsAffected() > 0 {
		normalized = true
	}
	if kind == "" {
		return false, normalized
	}
	// Açık alarm varsa yenisi açılmaz; son değer güncellenir (xmax = 0 → yeni eklendi).
	var alertID string
	var created bool
	err = sc.QueryRow(ctx, `
INSERT INTO sensor_alerts (property_id, sensor_id, kind, value, threshold) VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (sensor_id, kind) WHERE status <> 'CLOSED' DO UPDATE SET value = EXCLUDED.value, normalized_at = NULL
RETURNING id::text, (xmax = 0)`, propertyID, sensorID, kind, value, threshold).Scan(&alertID, &created)
	if err != nil {
		log.Printf("[iot] alarm açılamadı: %v", err)
		return false, normalized
	}
	if created {
		notifySensor(ctx, n, pool, propertyID, sensorID, alertID, kind, value)
	}
	return created, normalized
}

func notifySensor(ctx context.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID, sensorID, alertID, kind string, value float64) {
	if n == nil {
		log.Printf("[iot] bildirim altyapısı yok; sensör alarmı %s bildirilemedi", alertID)
		return
	}
	var name, typ, loc, unit string
	if err := dbscope.For(pool, propertyID).QueryRow(ctx,
		`SELECT name, sensor_type, COALESCE(location,''), COALESCE(unit_label,'') FROM sensors WHERE id = $1`, sensorID).
		Scan(&name, &typ, &loc, &unit); err != nil {
		log.Printf("[iot] sensör adı okunamadı: %v", err)
		return
	}
	recipients, err := notify.Operations(ctx, pool, propertyID)
	if err != nil {
		log.Printf("[iot] alıcılar okunamadı: %v", err)
		return
	}
	where := ""
	if loc != "" {
		where = " (" + loc + ")"
	}
	body := fmt.Sprintf("%s sensörü \"%s\"%s: %s.", sensorTypeLabel[typ], name, where, alertKindLabel[kind])
	if kind == "HIGH" || kind == "LOW" {
		body += fmt.Sprintf(" Okunan değer: %g %s.", value, unit)
	}
	topic := "iot.alert"
	if kind == "OFFLINE" {
		topic = "iot.offline"
	}
	res := n.Broadcast(ctx, notify.Message{PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Topic: topic, Subject: sensorTypeLabel[typ] + " alarmı: " + name, Body: body + " Uygulamadan onaylayıp giderilince kapatın.",
		Payload: map[string]any{"sensor_id": sensorID, "alert_id": alertID, "kind": kind}, DedupeKey: "iot.alert:" + alertID}, recipients)
	log.Printf("[iot] sensör alarmı %s (%s): %s", alertID, kind, res.Note)
}

// startSensorWatch, sinyali kesilen sensör için OFFLINE alarmı açan bekçiyi başlatır
// (SENSOR_WATCH_INTERVAL, varsayılan 60 sn; "off" kapatır).
func startSensorWatch(ctx context.Context, pool *pgxpool.Pool, n *notify.Notifier) {
	interval := 60 * time.Second
	if v := strings.TrimSpace(os.Getenv("SENSOR_WATCH_INTERVAL")); v != "" {
		if v == "off" {
			log.Printf("[iot] sensör bekçisi kapalı (SENSOR_WATCH_INTERVAL=off)")
			return
		}
		d, err := time.ParseDuration(v)
		if err != nil || d < time.Second {
			log.Fatalf("[iot] SENSOR_WATCH_INTERVAL geçersiz: %q", v)
		}
		interval = d
	}
	go func() {
		t := time.NewTicker(interval)
		defer t.Stop()
		for {
			sensorWatchOnce(ctx, pool, n)
			select {
			case <-ctx.Done():
				return
			case <-t.C:
			}
		}
	}()
}

func sensorWatchOnce(ctx context.Context, pool *pgxpool.Pool, n *notify.Notifier) {
	rows, err := pool.Query(ctx, `SELECT sensor_watch_property_ids()::text`)
	if err != nil {
		log.Printf("[iot] sensör bekçisi: %v", err)
		return
	}
	var ids []string
	for rows.Next() {
		var id string
		if rows.Scan(&id) == nil {
			ids = append(ids, id)
		}
	}
	rows.Close()
	for _, pid := range ids {
		r, err := dbscope.For(pool, pid).Query(ctx, `
INSERT INTO sensor_alerts (property_id, sensor_id, kind)
SELECT s.property_id, s.id, 'OFFLINE' FROM sensors s
WHERE s.property_id = $1 AND s.is_active
  AND COALESCE(s.last_seen_at, s.created_at) < now() - make_interval(mins => s.offline_after_minutes)
ON CONFLICT (sensor_id, kind) WHERE status <> 'CLOSED' DO NOTHING
RETURNING id::text, sensor_id::text`, pid)
		if err != nil {
			log.Printf("[iot] sensör bekçisi (site %s): %v", pid, err)
			continue
		}
		type opened struct{ alert, sensor string }
		var list []opened
		for r.Next() {
			var o opened
			if r.Scan(&o.alert, &o.sensor) == nil {
				list = append(list, o)
			}
		}
		r.Close()
		for _, o := range list {
			notifySensor(ctx, n, pool, pid, o.sensor, o.alert, "OFFLINE", 0)
		}
	}
}

func sensorFail(c *gin.Context, err error) {
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[iot] sensör işlemi: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem yapılamadı"})
}
