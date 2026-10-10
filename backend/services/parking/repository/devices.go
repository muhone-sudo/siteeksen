package repository

// Geçiş cihazı canlılık izleme (migration 057, Apsiyon BUG-08).

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

var (
	// ErrDeviceKind: tanımsız cihaz türü.
	ErrDeviceKind = errors.New("geçersiz cihaz türü")
	// ErrDeviceInterval: sinyal aralığı/eşik kurala aykırı.
	ErrDeviceInterval = errors.New("sinyal aralığı 10–3600 sn olmalı; çevrimdışı eşiği en az iki aralık ve en çok 1 gün olmalı")
	// ErrUnknownDevice: anahtar hiçbir aktif cihaza ait değil.
	ErrUnknownDevice = errors.New("cihaz anahtarı tanınmadı")
)

// DeviceKinds, access_devices.kind CHECK kısıtıyla aynıdır.
var DeviceKinds = []string{"PTS_CAMERA", "BARRIER", "TURNSTILE", "INTERCOM", "OTHER"}

// Device, kayıtlı geçiş cihazıdır. Online, son sinyalin eşik içinde olup olmadığıdır.
type Device struct {
	ID               string     `json:"id"`
	Name             string     `json:"name"`
	Kind             string     `json:"kind"`
	Location         *string    `json:"location,omitempty"`
	IntervalSec      int        `json:"heartbeat_interval_sec"`
	OfflineAfterSec  int        `json:"offline_after_sec"`
	LastSeenAt       *time.Time `json:"last_seen_at,omitempty"`
	LastStatus       *string    `json:"last_status,omitempty"`
	IsActive         bool       `json:"is_active"`
	Online           bool       `json:"online"`
	OpenIncidentID   *string    `json:"open_incident_id,omitempty"`
	OpenIncidentFrom *time.Time `json:"open_incident_since,omitempty"`
}

// DeviceInput, cihaz kaydı girdisidir.
type DeviceInput struct {
	Name            string `json:"name"`
	Kind            string `json:"kind"`
	Location        string `json:"location"`
	IntervalSec     int    `json:"heartbeat_interval_sec"`
	OfflineAfterSec int    `json:"offline_after_sec"`
}

// Incident, cihaz çevrimdışı olayıdır.
type Incident struct {
	ID          string     `json:"id"`
	DeviceID    string     `json:"device_id"`
	DeviceName  string     `json:"device_name"`
	Kind        string     `json:"kind"`
	LastSeenAt  *time.Time `json:"last_seen_at,omitempty"`
	DetectedAt  time.Time  `json:"detected_at"`
	RecoveredAt *time.Time `json:"recovered_at,omitempty"`
}

// HashDeviceKey, cihaz anahtarının saklanan özetidir.
func HashDeviceKey(key string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(key)))
	return hex.EncodeToString(sum[:])
}

// CreateDevice, cihazı kaydeder ve anahtarı BİR KEZ döner (veritabanında yalnızca özeti kalır).
func (r *Repository) CreateDevice(ctx context.Context, propertyID, userID string, in DeviceInput) (string, string, error) {
	kind := strings.ToUpper(strings.TrimSpace(in.Kind))
	valid := false
	for _, k := range DeviceKinds {
		valid = valid || k == kind
	}
	if !valid {
		return "", "", ErrDeviceKind
	}
	if in.IntervalSec == 0 {
		in.IntervalSec = 60
	}
	if in.OfflineAfterSec == 0 {
		in.OfflineAfterSec = 3 * in.IntervalSec
	}
	if in.IntervalSec < 10 || in.IntervalSec > 3600 || in.OfflineAfterSec < 2*in.IntervalSec || in.OfflineAfterSec > 86400 {
		return "", "", ErrDeviceInterval
	}
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return "", "", err
	}
	key := "dev_" + hex.EncodeToString(raw)
	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO access_devices (property_id, name, kind, location, key_hash, heartbeat_interval_sec, offline_after_sec, created_by)
		VALUES ($1, $2, $3, NULLIF($4,''), $5, $6, $7, NULLIF($8,'')::uuid) RETURNING id`,
		propertyID, strings.TrimSpace(in.Name), kind, strings.TrimSpace(in.Location), HashDeviceKey(key),
		in.IntervalSec, in.OfflineAfterSec, userID).Scan(&id)
	return id, key, err
}

// ListDevices, sitenin cihazlarını canlılık durumuyla döner.
func (r *Repository) ListDevices(ctx context.Context, propertyID string) ([]Device, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT d.id, d.name, d.kind, d.location, d.heartbeat_interval_sec, d.offline_after_sec, d.last_seen_at, d.last_status,
		       d.is_active,
		       d.last_seen_at IS NOT NULL AND d.last_seen_at >= now() - make_interval(secs => d.offline_after_sec),
		       i.id::text, i.detected_at
		FROM access_devices d
		LEFT JOIN device_incidents i ON i.device_id = d.id AND i.recovered_at IS NULL
		WHERE d.property_id = $1
		ORDER BY d.is_active DESC, d.name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Device{}
	for rows.Next() {
		var d Device
		if err := rows.Scan(&d.ID, &d.Name, &d.Kind, &d.Location, &d.IntervalSec, &d.OfflineAfterSec, &d.LastSeenAt,
			&d.LastStatus, &d.IsActive, &d.Online, &d.OpenIncidentID, &d.OpenIncidentFrom); err != nil {
			return nil, err
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

// DeactivateDevice, cihazı pasife alır (izleme durur, açık olay kapanır). Kayıt silinmez.
func (r *Repository) DeactivateDevice(ctx context.Context, propertyID, id string) error {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	tag, err := tx.Exec(ctx, `UPDATE access_devices SET is_active = false WHERE id = $1 AND property_id = $2 AND is_active`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	if _, err := tx.Exec(ctx, `UPDATE device_incidents SET recovered_at = now() WHERE device_id = $1 AND recovered_at IS NULL`, id); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ListIncidents, son olayları döner.
func (r *Repository) ListIncidents(ctx context.Context, propertyID string) ([]Incident, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT i.id, i.device_id, d.name, d.kind, i.last_seen_at, i.detected_at, i.recovered_at
		FROM device_incidents i JOIN access_devices d ON d.id = i.device_id
		WHERE i.property_id = $1 ORDER BY i.detected_at DESC LIMIT 200`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Incident{}
	for rows.Next() {
		var i Incident
		if err := rows.Scan(&i.ID, &i.DeviceID, &i.DeviceName, &i.Kind, &i.LastSeenAt, &i.DetectedAt, &i.RecoveredAt); err != nil {
			return nil, err
		}
		out = append(out, i)
	}
	return out, rows.Err()
}

// Heartbeat, cihaz anahtarıyla canlılık sinyalini kaydeder. Açık olay varsa kapanır ve
// recovered dolu döner (yönetime "yeniden çevrimiçi" bildirimi için).
func (r *Repository) Heartbeat(ctx context.Context, key, status string) (deviceID, propertyID string, recovered *string, err error) {
	err = r.pool.QueryRow(ctx, `SELECT device_id::text, property_id::text, recovered_incident::text FROM device_heartbeat($1, $2)`,
		HashDeviceKey(key), status).Scan(&deviceID, &propertyID, &recovered)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", nil, ErrUnknownDevice
	}
	return deviceID, propertyID, recovered, err
}

// DeviceName, bildirim metni için cihaz adını verir.
func (r *Repository) DeviceName(ctx context.Context, propertyID, id string) (string, string, error) {
	var name, kind string
	err := r.scope(propertyID).QueryRow(ctx, `SELECT name, kind FROM access_devices WHERE id = $1 AND property_id = $2`, id, propertyID).
		Scan(&name, &kind)
	return name, kind, err
}

// WatchPropertyIDs, sinyal süresi aşılmış ve açık olayı olmayan cihazı bulunan siteler (yalnızca kimlik).
func (r *Repository) WatchPropertyIDs(ctx context.Context) ([]string, error) {
	rows, err := r.pool.Query(ctx, `SELECT id::text FROM device_watch_property_ids() AS id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}

// OpenOfflineIncidents, sitede sinyal süresi aşılmış cihazlar için olay açar ve açılanları döner.
// Benzersiz kısmi indeks aynı cihaz için ikinci açık olayı engeller (eşzamanlı bekçiye karşı).
func (r *Repository) OpenOfflineIncidents(ctx context.Context, propertyID string) ([]Incident, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		INSERT INTO device_incidents (property_id, device_id, last_seen_at)
		SELECT d.property_id, d.id, d.last_seen_at FROM access_devices d
		 WHERE d.property_id = $1 AND d.is_active
		   AND COALESCE(d.last_seen_at, d.created_at) < now() - make_interval(secs => d.offline_after_sec)
		   AND NOT EXISTS (SELECT 1 FROM device_incidents i WHERE i.device_id = d.id AND i.recovered_at IS NULL)
		ON CONFLICT DO NOTHING
		RETURNING id, device_id, last_seen_at, detected_at`, propertyID)
	if err != nil {
		return nil, err
	}
	var out []Incident
	for rows.Next() {
		var i Incident
		if err := rows.Scan(&i.ID, &i.DeviceID, &i.LastSeenAt, &i.DetectedAt); err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, i)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for k := range out {
		if out[k].DeviceName, out[k].Kind, err = r.DeviceName(ctx, propertyID, out[k].DeviceID); err != nil {
			return nil, err
		}
	}
	return out, nil
}
