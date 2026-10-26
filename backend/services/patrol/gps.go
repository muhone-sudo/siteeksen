package main

// Devriye: QR + GPS zorunluluğu, konum izi ve rapor (075, FAZ H.5, kullanıcı kararı K2).
//
// Okutma kuralları SUNUCUDA uygulanır; istemcinin "yakınındayım" demesine güvenilmez:
//   1. Tur açık ve görevliye ait olmalı (repository.ScanCheckpoint).
//   2. QR, noktanın GÜNCEL qr_token'ı olmalı (yeniden üretilince eski baskı geçersiz).
//   3. Sahte konum (Android isMocked) → red.
//   4. Doğruluk > 50 m → red ("açık alana çıkın").
//   5. Mesafe > yarıçap + doğruluk → red. Nokta "konum muaf" ise 3-5 atlanır, okutma işaretlenir.
//   6. Önceki kabul edilen okutmaya göre fiziksel olarak imkânsız hız (> 15 m/s) → kabul, "şüpheli".
// Her deneme (red dahil) patrol_scan_attempts'e kanıt olarak yazılır.

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/patrol/repository"
)

const (
	qrPrefix            = "SITEEKSEN-PATROL:"
	maxScanAccuracyM    = 50.0
	maxSetupAccuracyM   = 20.0
	impossibleSpeedMPS  = 15.0
	maxTrackPointsBatch = 100
	trackGapMinutes     = 2
)

var scanReasonText = map[string]string{
	"QR_UNKNOWN":        "QR kodu tanınmadı ya da eski (yeniden basılmış olabilir)",
	"NO_LOCATION":       "Konum alınamadı; konum izni ve GPS açık olmalı",
	"MOCKED":            "Sahte konum algılandı; konum taklit uygulamasını kapatın",
	"LOW_ACCURACY":      "Konum yeterince hassas değil; açık alana çıkıp yeniden deneyin",
	"TOO_FAR":           "Noktanın yanında değilsiniz",
	"NO_POINT_LOCATION": "Bu noktanın konumu tanımlanmamış; yönetim noktanın yanında konumu kaydetmeli",
	"EXEMPT_NEEDS_QR":   "Konum muaf noktada okutma yalnız QR ile yapılır",
	"NOT_IN_ROUTE":      "Nokta bu turun güzergâhında değil",
	"ALREADY_SCANNED":   "Bu nokta bu turda zaten okutuldu",
	"PATROL_CLOSED":     "Tur devam etmiyor",
}

// haversine, iki koordinat arasındaki mesafe (metre).
func haversine(lat1, lon1, lat2, lon2 float64) float64 {
	const r = 6371000.0
	toRad := func(d float64) float64 { return d * math.Pi / 180 }
	dLat, dLon := toRad(lat2-lat1), toRad(lon2-lon1)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) + math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*math.Sin(dLon/2)*math.Sin(dLon/2)
	return 2 * r * math.Asin(math.Min(1, math.Sqrt(a)))
}

func validCoord(lat, lon float64) bool {
	return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180 && !(lat == 0 && lon == 0)
}

type scanInput struct {
	QR           string   `json:"qr"`
	CheckpointID string   `json:"checkpoint_id"`
	Latitude     *float64 `json:"latitude"`
	Longitude    *float64 `json:"longitude"`
	AccuracyM    *float64 `json:"accuracy_m"`
	IsMocked     bool     `json:"is_mocked"`
	Note         string   `json:"note"`
}

type pointInfo struct {
	id, name, check string
	lat, lon        *float64
	radius          int
}

func registerGPS(r *gin.Engine, repo *repository.Repository, pool *pgxpool.Pool) {
	api := r.Group("/api/v1")
	api.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "patrol"))

	ops := api.Group("")
	ops.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleStaff))
	ops.POST("/patrols/:id/scan", func(c *gin.Context) { scanWithLocation(c, repo, pool) })
	ops.POST("/patrols/:id/track", func(c *gin.Context) { addTrack(c, pool) })

	view := api.Group("")
	view.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor, middleware.RoleStaff))
	view.GET("/patrols/:id/report", func(c *gin.Context) { patrolReport(c, pool) })
	view.GET("/patrol-reports", func(c *gin.Context) { patrolReports(c, pool) })

	admin := api.Group("")
	admin.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	admin.PATCH("/patrol-checkpoints/:id", func(c *gin.Context) { updateCheckpoint(c, pool) })
	admin.POST("/patrol-checkpoints/:id/location", func(c *gin.Context) { setCheckpointLocation(c, pool) })
	admin.POST("/patrol-checkpoints/:id/rotate-qr", func(c *gin.Context) {
		var token string
		err := dbscope.For(pool, c.GetString("property_id")).QueryRow(c.Request.Context(), `
UPDATE patrol_checkpoints SET qr_token = replace(gen_random_uuid()::text, '-', '')
WHERE id = $1 AND property_id = $2 RETURNING qr_token`, c.Param("id"), c.GetString("property_id")).Scan(&token)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Nokta bulunamadı"})
			return
		}
		if err != nil {
			fail(c, err, "QR yenileme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"qr_value": qrPrefix + token, "note": "Eski QR baskısı artık geçersiz; yenisini noktaya asın."})
	})
}

// scanWithLocation, okutmayı konumla doğrular; her denemeyi kanıt olarak yazar.
func scanWithLocation(c *gin.Context, repo *repository.Repository, pool *pgxpool.Pool) {
	var in scanInput
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek"})
		return
	}
	ctx, pid, uid, patrolID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id")
	sc := dbscope.For(pool, pid)
	method := "MANUAL"
	qr := strings.TrimSpace(in.QR)
	if qr != "" {
		method = "QR"
	}
	if qr == "" && strings.TrimSpace(in.CheckpointID) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "qr ya da checkpoint_id zorunludur"})
		return
	}

	// Tur görevliye ait mi? (Başkasının turuna deneme yazılmaz.)
	var status string
	if err := sc.QueryRow(ctx, `SELECT status FROM patrol_logs WHERE id = $1 AND property_id = $2 AND guard_id = $3`,
		patrolID, pid, uid).Scan(&status); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tur bulunamadı"})
			return
		}
		fail(c, err, "tur")
		return
	}

	var pt pointInfo
	var err error
	if method == "QR" {
		token := strings.TrimPrefix(qr, qrPrefix)
		err = sc.QueryRow(ctx, `
SELECT id::text, name, location_check, latitude::float8, longitude::float8, radius_m
FROM patrol_checkpoints WHERE property_id = $1 AND qr_token = $2 AND COALESCE(is_active, true)`, pid, token).
			Scan(&pt.id, &pt.name, &pt.check, &pt.lat, &pt.lon, &pt.radius)
	} else {
		err = sc.QueryRow(ctx, `
SELECT id::text, name, location_check, latitude::float8, longitude::float8, radius_m
FROM patrol_checkpoints WHERE property_id = $1 AND id = $2 AND COALESCE(is_active, true)`, pid, in.CheckpointID).
			Scan(&pt.id, &pt.name, &pt.check, &pt.lat, &pt.lon, &pt.radius)
	}
	attempt := func(accepted bool, reason string, distance *float64, suspicious bool) {
		var cp any
		if pt.id != "" {
			cp = pt.id
		}
		if _, e := sc.Exec(ctx, `
INSERT INTO patrol_scan_attempts (patrol_log_id, property_id, checkpoint_id, guard_id, method, latitude, longitude,
    accuracy_m, is_mocked, distance_m, accepted, reason, location_exempt, suspicious, note)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NULLIF($12,''), $13, $14, NULLIF($15,''))`,
			patrolID, pid, cp, uid, method, in.Latitude, in.Longitude, in.AccuracyM, in.IsMocked, distance,
			accepted, reason, pt.check == "EXEMPT", suspicious, strings.TrimSpace(in.Note)); e != nil {
			log.Printf("[patrol] okutma denemesi yazılamadı: %v", e)
		}
	}
	reject := func(code int, reason string, distance *float64, extra gin.H) {
		attempt(false, reason, distance, false)
		body := gin.H{"error": scanReasonText[reason], "reason": reason}
		for k, v := range extra {
			body[k] = v
		}
		c.JSON(code, body)
	}
	if errors.Is(err, pgx.ErrNoRows) {
		reject(http.StatusUnprocessableEntity, "QR_UNKNOWN", nil, nil)
		return
	}
	if err != nil {
		fail(c, err, "nokta")
		return
	}
	if status != "IN_PROGRESS" {
		reject(http.StatusConflict, "PATROL_CLOSED", nil, nil)
		return
	}

	var distance *float64
	exempt := pt.check == "EXEMPT"
	if exempt && method != "QR" {
		reject(http.StatusUnprocessableEntity, "EXEMPT_NEEDS_QR", nil, nil)
		return
	}
	if !exempt {
		if in.Latitude == nil || in.Longitude == nil || !validCoord(*in.Latitude, *in.Longitude) {
			reject(http.StatusUnprocessableEntity, "NO_LOCATION", nil, nil)
			return
		}
		if in.IsMocked {
			reject(http.StatusUnprocessableEntity, "MOCKED", nil, nil)
			return
		}
		if in.AccuracyM == nil || *in.AccuracyM > maxScanAccuracyM {
			reject(http.StatusUnprocessableEntity, "LOW_ACCURACY", nil, gin.H{"max_accuracy_m": maxScanAccuracyM})
			return
		}
		if pt.lat == nil || pt.lon == nil {
			reject(http.StatusUnprocessableEntity, "NO_POINT_LOCATION", nil, nil)
			return
		}
		d := haversine(*in.Latitude, *in.Longitude, *pt.lat, *pt.lon)
		distance = &d
		if d > float64(pt.radius)+*in.AccuracyM {
			reject(http.StatusUnprocessableEntity, "TOO_FAR", distance, gin.H{
				"distance_m": math.Round(d), "allowed_m": pt.radius + int(math.Round(*in.AccuracyM)),
				"detail": fmt.Sprintf("Noktaya uzaklığınız %.0f m; izin verilen %d m.", d, pt.radius+int(math.Round(*in.AccuracyM)))})
			return
		}
	}

	res, err := repo.ScanCheckpoint(ctx, pid, patrolID, pt.id, uid, in.Note)
	switch {
	case errors.Is(err, repository.ErrCheckpointOther):
		reject(http.StatusUnprocessableEntity, "NOT_IN_ROUTE", distance, nil)
		return
	case errors.Is(err, repository.ErrAlreadyScanned):
		reject(http.StatusConflict, "ALREADY_SCANNED", distance, nil)
		return
	case errors.Is(err, repository.ErrNoOpenPatrol):
		reject(http.StatusConflict, "PATROL_CLOSED", distance, nil)
		return
	case err != nil:
		fail(c, err, "nokta okutma")
		return
	}

	// İmkânsız hız: önceki kabul edilmiş, konumlu okutmaya göre.
	suspicious := false
	if !exempt {
		var plat, plon *float64
		var pat time.Time
		if e := sc.QueryRow(ctx, `
SELECT latitude::float8, longitude::float8, created_at FROM patrol_scan_attempts
WHERE patrol_log_id = $1 AND accepted AND latitude IS NOT NULL ORDER BY created_at DESC LIMIT 1`, patrolID).
			Scan(&plat, &plon, &pat); e == nil && plat != nil && plon != nil {
			secs := time.Since(pat).Seconds()
			if secs < 1 {
				secs = 1
			}
			if haversine(*plat, *plon, *in.Latitude, *in.Longitude)/secs > impossibleSpeedMPS {
				suspicious = true
			}
		}
	}
	attempt(true, "", distance, suspicious)
	resp := gin.H{"scan": res, "location_exempt": exempt, "suspicious": suspicious}
	if distance != nil {
		resp["distance_m"] = math.Round(*distance)
	}
	if suspicious {
		resp["warning"] = "Önceki noktadan bu noktaya geçiş süresi fiziksel olarak mümkün görünmüyor; okutma raporda şüpheli olarak işaretlendi."
	}
	if exempt {
		resp["note"] = "Bu nokta konum denetiminden muaf (yönetim kararı); okutma raporda ayrıca gösterilir."
	}
	c.JSON(http.StatusOK, resp)
}

// addTrack, açık tur boyunca toplanan konum noktalarını yazar (en çok 100 nokta / istek).
func addTrack(c *gin.Context, pool *pgxpool.Pool) {
	var in struct {
		Points []struct {
			Latitude   float64  `json:"latitude"`
			Longitude  float64  `json:"longitude"`
			AccuracyM  *float64 `json:"accuracy_m"`
			SpeedMPS   *float64 `json:"speed_mps"`
			IsMocked   bool     `json:"is_mocked"`
			RecordedAt string   `json:"recorded_at"`
		} `json:"points"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || len(in.Points) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "points zorunludur"})
		return
	}
	if len(in.Points) > maxTrackPointsBatch {
		c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": fmt.Sprintf("Tek istekte en çok %d nokta", maxTrackPointsBatch)})
		return
	}
	ctx, pid := c.Request.Context(), c.GetString("property_id")
	sc := dbscope.For(pool, pid)
	var status string
	var started time.Time
	if err := sc.QueryRow(ctx, `SELECT status, started_at FROM patrol_logs WHERE id = $1 AND property_id = $2 AND guard_id = $3`,
		c.Param("id"), pid, c.GetString("user_id")).Scan(&status, &started); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Tur bulunamadı"})
			return
		}
		fail(c, err, "tur")
		return
	}
	if status != "IN_PROGRESS" {
		// KVKK m.4 ölçülülük: konum yalnız açık tur boyunca alınır.
		c.JSON(http.StatusConflict, gin.H{"error": "Tur devam etmiyor; konum kaydedilmez"})
		return
	}
	now := time.Now()
	accepted, mocked := 0, 0
	for _, p := range in.Points {
		if !validCoord(p.Latitude, p.Longitude) {
			continue
		}
		at, err := time.Parse(time.RFC3339, p.RecordedAt)
		if err != nil || at.After(now.Add(time.Minute)) || at.Before(started.Add(-time.Minute)) {
			at = now
		}
		if p.IsMocked {
			mocked++
		}
		if _, err := sc.Exec(ctx, `
INSERT INTO patrol_track_points (patrol_log_id, property_id, recorded_at, latitude, longitude, accuracy_m, speed_mps, is_mocked)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`, c.Param("id"), pid, at, p.Latitude, p.Longitude, p.AccuracyM, p.SpeedMPS, p.IsMocked); err != nil {
			fail(c, err, "konum izi")
			return
		}
		accepted++
	}
	resp := gin.H{"accepted": accepted}
	if mocked > 0 {
		resp["warning"] = "Sahte konum işaretli noktalar kaydedildi ve raporda gösterilecek."
	}
	c.JSON(http.StatusOK, resp)
}

func updateCheckpoint(c *gin.Context, pool *pgxpool.Pool) {
	var in struct {
		RadiusM       *int     `json:"radius_m"`
		LocationCheck *string  `json:"location_check"`
		ExemptReason  *string  `json:"exempt_reason"`
		Latitude      *float64 `json:"latitude"`
		Longitude     *float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek"})
		return
	}
	if in.RadiusM != nil && (*in.RadiusM < 5 || *in.RadiusM > 500) {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yarıçap 5-500 m olmalı"})
		return
	}
	if in.LocationCheck != nil {
		v := strings.ToUpper(*in.LocationCheck)
		in.LocationCheck = &v
		if v != "REQUIRED" && v != "EXEMPT" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "location_check REQUIRED ya da EXEMPT olmalı"})
			return
		}
		if v == "EXEMPT" && (in.ExemptReason == nil || strings.TrimSpace(*in.ExemptReason) == "") {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Konum muafiyeti için gerekçe zorunludur (ör. bodrum, GPS çekmiyor)"})
			return
		}
	}
	if (in.Latitude == nil) != (in.Longitude == nil) || (in.Latitude != nil && !validCoord(*in.Latitude, *in.Longitude)) {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Enlem ve boylam birlikte ve geçerli verilmeli"})
		return
	}
	tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
UPDATE patrol_checkpoints SET
  radius_m = COALESCE($3, radius_m),
  location_check = COALESCE($4, location_check),
  exempt_reason = CASE WHEN COALESCE($4, location_check) = 'EXEMPT' THEN COALESCE(NULLIF(trim($5),''), exempt_reason) ELSE NULL END,
  exempt_by = CASE WHEN $4 = 'EXEMPT' THEN $8::uuid WHEN COALESCE($4, location_check) = 'EXEMPT' THEN exempt_by ELSE NULL END,
  latitude = COALESCE($6, latitude), longitude = COALESCE($7, longitude),
  location_accuracy_m = CASE WHEN $6::float8 IS NULL THEN location_accuracy_m ELSE NULL END,
  location_set_at = CASE WHEN $6::float8 IS NULL THEN location_set_at ELSE now() END,
  location_set_by = CASE WHEN $6::float8 IS NULL THEN location_set_by ELSE $8::uuid END
WHERE id = $1 AND property_id = $2`, c.Param("id"), c.GetString("property_id"), in.RadiusM, in.LocationCheck, in.ExemptReason,
		in.Latitude, in.Longitude, c.GetString("user_id"))
	if err != nil {
		fail(c, err, "nokta güncelleme")
		return
	}
	if tag.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nokta bulunamadı"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nokta güncellendi"})
}

// setCheckpointLocation, yöneticinin noktanın YANINDA telefonla ölçtüğü konumu kaydeder.
func setCheckpointLocation(c *gin.Context, pool *pgxpool.Pool) {
	var in struct {
		Latitude  *float64 `json:"latitude"`
		Longitude *float64 `json:"longitude"`
		AccuracyM *float64 `json:"accuracy_m"`
		IsMocked  bool     `json:"is_mocked"`
	}
	if err := c.ShouldBindJSON(&in); err != nil || in.Latitude == nil || in.Longitude == nil || !validCoord(*in.Latitude, *in.Longitude) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçerli enlem ve boylam zorunludur"})
		return
	}
	if in.IsMocked {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": scanReasonText["MOCKED"]})
		return
	}
	if in.AccuracyM == nil || *in.AccuracyM > maxSetupAccuracyM {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": fmt.Sprintf("Konum en az %.0f m hassasiyetle ölçülmeli; açık alanda biraz bekleyip yeniden deneyin", maxSetupAccuracyM)})
		return
	}
	tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
UPDATE patrol_checkpoints SET latitude = $3, longitude = $4, location_accuracy_m = $5, location_set_at = now(), location_set_by = $6
WHERE id = $1 AND property_id = $2`, c.Param("id"), c.GetString("property_id"), *in.Latitude, *in.Longitude, *in.AccuracyM, c.GetString("user_id"))
	if err != nil {
		fail(c, err, "nokta konumu")
		return
	}
	if tag.RowsAffected() == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Nokta bulunamadı"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "Nokta konumu kaydedildi", "accuracy_m": *in.AccuracyM})
}

type trackPoint struct {
	At       time.Time `json:"recorded_at"`
	Lat      float64   `json:"latitude"`
	Lon      float64   `json:"longitude"`
	Accuracy *float64  `json:"accuracy_m,omitempty"`
	Speed    *float64  `json:"speed_mps,omitempty"`
	Mocked   bool      `json:"is_mocked"`
}

// patrolReport, tek turun ayrıntılı raporu: noktalar, denemeler, konum izi, kesintiler.
func patrolReport(c *gin.Context, pool *pgxpool.Pool) {
	ctx, pid := c.Request.Context(), c.GetString("property_id")
	sc := dbscope.For(pool, pid)
	var p struct {
		ID, RouteName, GuardID, GuardName, Status, Notes string
		RouteID                                          *string
		Started                                          time.Time
		Completed                                        *time.Time
		Expected, Visited, ExpMins, ActMins              *int
	}
	err := sc.QueryRow(ctx, `
SELECT l.id::text, l.route_id::text, COALESCE(r.name,''), l.guard_id::text, COALESCE(u.first_name || ' ' || u.last_name, ''),
       l.status, COALESCE(l.notes,''), l.started_at, l.completed_at, l.checkpoints_expected, l.checkpoints_visited,
       l.expected_duration_minutes, l.actual_duration_minutes
FROM patrol_logs l LEFT JOIN patrol_routes r ON r.id = l.route_id LEFT JOIN users u ON u.id = l.guard_id
WHERE l.id = $1 AND l.property_id = $2`, c.Param("id"), pid).Scan(&p.ID, &p.RouteID, &p.RouteName, &p.GuardID, &p.GuardName,
		&p.Status, &p.Notes, &p.Started, &p.Completed, &p.Expected, &p.Visited, &p.ExpMins, &p.ActMins)
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tur bulunamadı"})
		return
	}
	if err != nil {
		fail(c, err, "rapor")
		return
	}
	if !isManagement(c) && !hasRoleAuditor(c) && p.GuardID != c.GetString("user_id") {
		c.JSON(http.StatusForbidden, gin.H{"error": "Görevli yalnız kendi turunun raporunu görür"})
		return
	}

	// Güzergâh noktaları (konumlarıyla).
	points := []gin.H{}
	if p.RouteID != nil {
		rows, err := sc.Query(ctx, `
SELECT cp.id::text, cp.name, COALESCE(cp.location,''), cp.latitude::float8, cp.longitude::float8, cp.radius_m, cp.location_check,
       COALESCE((rc->>'optional')::bool, false), COALESCE((rc->>'order')::int, 0)
FROM patrol_routes r, jsonb_array_elements(r.checkpoints) rc
JOIN patrol_checkpoints cp ON cp.id = (rc->>'checkpoint_id')::uuid
WHERE r.id = $1 AND r.property_id = $2 ORDER BY 9`, *p.RouteID, pid)
		if err != nil {
			fail(c, err, "rapor noktaları")
			return
		}
		for rows.Next() {
			var id, name, loc, check string
			var lat, lon *float64
			var radius, order int
			var optional bool
			if err := rows.Scan(&id, &name, &loc, &lat, &lon, &radius, &check, &optional, &order); err != nil {
				rows.Close()
				fail(c, err, "rapor noktaları")
				return
			}
			points = append(points, gin.H{"id": id, "name": name, "location": loc, "latitude": lat, "longitude": lon,
				"radius_m": radius, "location_check": check, "optional": optional, "order": order})
		}
		rows.Close()
	}

	attempts := []gin.H{}
	rows, err := sc.Query(ctx, `
SELECT a.created_at, COALESCE(cp.name,''), a.checkpoint_id::text, a.method, a.latitude::float8, a.longitude::float8, a.accuracy_m::float8,
       a.is_mocked, a.distance_m::float8, a.accepted, COALESCE(a.reason,''), a.location_exempt, a.suspicious, COALESCE(a.note,'')
FROM patrol_scan_attempts a LEFT JOIN patrol_checkpoints cp ON cp.id = a.checkpoint_id
WHERE a.patrol_log_id = $1 ORDER BY a.created_at`, p.ID)
	if err != nil {
		fail(c, err, "rapor denemeleri")
		return
	}
	rejected, suspicious, exempt := 0, 0, 0
	for rows.Next() {
		var at time.Time
		var name, method, reason, note string
		var cpID *string
		var lat, lon, acc, dist *float64
		var mocked, accepted, ex, susp bool
		if err := rows.Scan(&at, &name, &cpID, &method, &lat, &lon, &acc, &mocked, &dist, &accepted, &reason, &ex, &susp, &note); err != nil {
			rows.Close()
			fail(c, err, "rapor denemeleri")
			return
		}
		if !accepted {
			rejected++
		}
		if susp {
			suspicious++
		}
		if ex && accepted {
			exempt++
		}
		attempts = append(attempts, gin.H{"at": at, "checkpoint": name, "checkpoint_id": cpID, "method": method, "latitude": lat,
			"longitude": lon, "accuracy_m": acc, "is_mocked": mocked, "distance_m": dist, "accepted": accepted, "reason": reason,
			"reason_text": scanReasonText[reason], "location_exempt": ex, "suspicious": susp, "note": note})
	}
	rows.Close()

	track := []trackPoint{}
	rows, err = sc.Query(ctx, `
SELECT recorded_at, latitude::float8, longitude::float8, accuracy_m::float8, speed_mps::float8, is_mocked
FROM patrol_track_points WHERE patrol_log_id = $1 ORDER BY recorded_at LIMIT 5000`, p.ID)
	if err != nil {
		fail(c, err, "rapor izi")
		return
	}
	mockedPts := 0
	for rows.Next() {
		var t trackPoint
		if err := rows.Scan(&t.At, &t.Lat, &t.Lon, &t.Accuracy, &t.Speed, &t.Mocked); err != nil {
			rows.Close()
			fail(c, err, "rapor izi")
			return
		}
		if t.Mocked {
			mockedPts++
		}
		track = append(track, t)
	}
	rows.Close()

	// Takip kesintileri: başlangıç → ilk nokta, noktalar arası ve son nokta → bitiş arası 2 dakikadan uzun boşluklar.
	gaps := []gin.H{}
	end := time.Now()
	if p.Completed != nil {
		end = *p.Completed
	}
	prev := p.Started
	addGap := func(from, to time.Time) {
		if to.Sub(from) > trackGapMinutes*time.Minute {
			gaps = append(gaps, gin.H{"from": from, "to": to, "minutes": int(to.Sub(from).Minutes())})
		}
	}
	distance := 0.0
	for i, t := range track {
		addGap(prev, t.At)
		if i > 0 {
			distance += haversine(track[i-1].Lat, track[i-1].Lon, t.Lat, t.Lon)
		}
		prev = t.At
	}
	addGap(prev, end)

	var rawIssues string
	if err := sc.QueryRow(ctx, `SELECT COALESCE(issues, '[]'::jsonb)::text FROM patrol_logs WHERE id = $1`, p.ID).Scan(&rawIssues); err != nil {
		rawIssues = "[]"
	}

	c.JSON(http.StatusOK, gin.H{
		"patrol": gin.H{"id": p.ID, "route_id": p.RouteID, "route_name": p.RouteName, "guard_id": p.GuardID, "guard_name": p.GuardName,
			"status": p.Status, "notes": p.Notes, "started_at": p.Started, "completed_at": p.Completed,
			"checkpoints_expected": p.Expected, "checkpoints_visited": p.Visited,
			"expected_duration_minutes": p.ExpMins, "actual_duration_minutes": p.ActMins},
		"checkpoints": points, "attempts": attempts, "track": track, "gaps": gaps,
		"issues": json.RawMessage(rawIssues),
		"stats": gin.H{"rejected_attempts": rejected, "suspicious_scans": suspicious, "exempt_scans": exempt,
			"track_points": len(track), "mocked_track_points": mockedPts, "track_gaps": len(gaps),
			"track_distance_m": math.Round(distance)},
	})
}

// patrolReports, dönem raporu: turlar ve özet.
func patrolReports(c *gin.Context, pool *pgxpool.Pool) {
	ctx, pid := c.Request.Context(), c.GetString("property_id")
	from, to := time.Now().AddDate(0, 0, -30), time.Now().Add(time.Minute)
	if v := c.Query("from"); v != "" {
		t, err := time.Parse("2006-01-02", v)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Tarih YYYY-AA-GG olmalı"})
			return
		}
		from = t
	}
	if v := c.Query("to"); v != "" {
		t, err := time.Parse("2006-01-02", v)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Tarih YYYY-AA-GG olmalı"})
			return
		}
		to = t.AddDate(0, 0, 1)
	}
	guard := c.Query("guard_id")
	if !isManagement(c) && !hasRoleAuditor(c) {
		guard = c.GetString("user_id")
	}
	rows, err := dbscope.For(pool, pid).Query(ctx, `
SELECT l.id::text, COALESCE(r.name,''), COALESCE(u.first_name || ' ' || u.last_name, ''), l.status, l.started_at, l.completed_at,
       COALESCE(l.checkpoints_expected,0), COALESCE(l.checkpoints_visited,0), l.actual_duration_minutes, l.expected_duration_minutes,
       (SELECT count(*) FROM patrol_scan_attempts a WHERE a.patrol_log_id = l.id AND NOT a.accepted),
       (SELECT count(*) FROM patrol_scan_attempts a WHERE a.patrol_log_id = l.id AND a.suspicious),
       (SELECT count(*) FROM patrol_scan_attempts a WHERE a.patrol_log_id = l.id AND a.accepted AND a.location_exempt),
       (SELECT count(*) FROM patrol_track_points t WHERE t.patrol_log_id = l.id),
       COALESCE(l.issues_reported,0)
FROM patrol_logs l LEFT JOIN patrol_routes r ON r.id = l.route_id LEFT JOIN users u ON u.id = l.guard_id
WHERE l.property_id = $1 AND l.started_at >= $2 AND l.started_at < $3
  AND ($4 = '' OR l.guard_id::text = $4) AND ($5 = '' OR l.route_id::text = $5)
ORDER BY l.started_at DESC LIMIT 500`, pid, from, to, guard, c.Query("route_id"))
	if err != nil {
		fail(c, err, "dönem raporu")
		return
	}
	defer rows.Close()
	list := []gin.H{}
	total, completed, incomplete, rejected, suspicious, durSum, durN := 0, 0, 0, 0, 0, 0, 0
	for rows.Next() {
		var id, route, guardName, status string
		var started time.Time
		var done *time.Time
		var exp, vis, rej, susp, ex, pts, iss int
		var act, expM *int
		if err := rows.Scan(&id, &route, &guardName, &status, &started, &done, &exp, &vis, &act, &expM, &rej, &susp, &ex, &pts, &iss); err != nil {
			fail(c, err, "dönem raporu")
			return
		}
		total++
		switch status {
		case "COMPLETED":
			completed++
		case "INCOMPLETE", "MISSED":
			incomplete++
		}
		rejected += rej
		suspicious += susp
		if act != nil {
			durSum += *act
			durN++
		}
		list = append(list, gin.H{"id": id, "route_name": route, "guard_name": guardName, "status": status, "started_at": started,
			"completed_at": done, "checkpoints_expected": exp, "checkpoints_visited": vis, "actual_duration_minutes": act,
			"expected_duration_minutes": expM, "rejected_attempts": rej, "suspicious_scans": susp, "exempt_scans": ex,
			"track_points": pts, "issues_reported": iss})
	}
	if err := rows.Err(); err != nil {
		fail(c, err, "dönem raporu")
		return
	}
	var top []gin.H
	tr, err := dbscope.For(pool, pid).Query(ctx, `
SELECT COALESCE(cp.name,'(tanınmayan QR)'), a.reason, count(*)
FROM patrol_scan_attempts a LEFT JOIN patrol_checkpoints cp ON cp.id = a.checkpoint_id
WHERE a.property_id = $1 AND NOT a.accepted AND a.created_at >= $2 AND a.created_at < $3
GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 5`, pid, from, to)
	if err == nil {
		for tr.Next() {
			var name, reason string
			var n int
			if tr.Scan(&name, &reason, &n) == nil {
				top = append(top, gin.H{"checkpoint": name, "reason": reason, "reason_text": scanReasonText[reason], "count": n})
			}
		}
		tr.Close()
	}
	avg := 0
	if durN > 0 {
		avg = durSum / durN
	}
	c.JSON(http.StatusOK, gin.H{"data": list, "from": from.Format("2006-01-02"), "to": to.AddDate(0, 0, -1).Format("2006-01-02"),
		"summary": gin.H{"total": total, "completed": completed, "incomplete": incomplete, "rejected_attempts": rejected,
			"suspicious_scans": suspicious, "avg_duration_minutes": avg, "top_rejections": top}})
}

func hasRoleAuditor(c *gin.Context) bool {
	v, _ := c.Get("roles")
	roles, _ := v.([]string)
	for _, r := range roles {
		if r == middleware.RoleAuditor {
			return true
		}
	}
	return false
}
