// Package repository, otopark modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrNotFound      = errors.New("kayıt bulunamadı")
	ErrPlateExists   = errors.New("bu plaka sitede zaten kayıtlı")
	ErrUnitNotInSite = errors.New("belirtilen bağımsız bölüm bu siteye ait değil")
	ErrAlreadyInside = errors.New("bu plaka hâlihazırda otoparkta (çıkış kaydı yok)")
	ErrNotInside     = errors.New("bu kayıt için açık bir giriş bulunmuyor")
	ErrZoneFull      = errors.New("otopark bölgesi dolu")
	// ErrPlateRequired: boş plaka önceden düz bir errors.New ile dönüyor ve
	// eşleyicide 500'e düşüyordu.
	ErrPlateRequired = errors.New("plaka zorunludur")
	ErrInvalidOwner  = errors.New("geçersiz araç sahibi türü")
	ErrNotYourUnit   = errors.New("bağımsız bölüm size ait değil")
	ErrUnitRequired  = errors.New("bağımsız bölüm zorunludur")
)

// OwnerTypes, vehicles.owner_type CHECK kısıtıyla (migration 005) aynıdır.
var OwnerTypes = []string{"RESIDENT", "VISITOR", "STAFF", "SERVICE"}

// ownUnitSQL, bağımsız bölümün verilen kullanıcının AKTİF dairesi olup
// olmadığını denetler.
const ownUnitSQL = `SELECT EXISTS (SELECT 1 FROM resident_units ru
	WHERE ru.unit_id = $1 AND ru.resident_id = $2 AND ru.is_active = true)`

// Vehicle, kayıtlı araçtır.
type Vehicle struct {
	ID          string    `json:"id"`
	PropertyID  string    `json:"property_id"`
	UnitID      string    `json:"unit_id,omitempty"`
	UnitName    string    `json:"unit_name,omitempty"`
	OwnerType   string    `json:"owner_type"`
	OwnerName   string    `json:"owner_name,omitempty"`
	Plate       string    `json:"plate"`
	Brand       string    `json:"brand,omitempty"`
	Model       string    `json:"model,omitempty"`
	Color       string    `json:"color,omitempty"`
	VehicleType string    `json:"vehicle_type"`
	ParkingSpot string    `json:"parking_spot,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
}

// Zone, otopark bölgesidir.
type Zone struct {
	ID             string   `json:"id"`
	Name           string   `json:"name"`
	Location       string   `json:"location,omitempty"`
	Capacity       int      `json:"capacity"`
	OccupiedCount  int      `json:"occupied_count"`
	AvailableSpots int      `json:"available_spots"`
	IsPaid         bool     `json:"is_paid"`
	HourlyFee      *float64 `json:"hourly_fee,omitempty"`
	DailyFee       *float64 `json:"daily_fee,omitempty"`
	VisitorAllowed bool     `json:"is_visitor_allowed"`
	IsActive       bool     `json:"is_active"`
}

// Log, otopark giriş/çıkış kaydıdır.
type Log struct {
	ID              string     `json:"id"`
	ZoneID          string     `json:"parking_zone_id,omitempty"`
	ZoneName        string     `json:"zone_name,omitempty"`
	VehicleID       string     `json:"vehicle_id,omitempty"`
	Plate           string     `json:"plate"`
	EntryAt         time.Time  `json:"entry_at"`
	EntryGate       string     `json:"entry_gate,omitempty"`
	EntryMethod     string     `json:"entry_method,omitempty"`
	ExitAt          *time.Time `json:"exit_at,omitempty"`
	DurationMinutes *int       `json:"duration_minutes,omitempty"`
	CalculatedFee   *float64   `json:"calculated_fee,omitempty"`
	PaidFee         *float64   `json:"paid_fee,omitempty"`
	PaymentStatus   string     `json:"payment_status,omitempty"`
	// IsResident true ise araç sitede kayıtlıdır (ücretsiz geçiş kuralı buna bağlıdır).
	IsResident bool `json:"is_resident"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// NormalizePlate, plakayı karşılaştırılabilir biçime getirir.
//
// NEDEN: "34 ABC 123", "34abc123" ve "34-ABC-123" aynı araçtır. Normalleştirme
// olmadan aynı araç birden çok kez kaydedilebilir ve plaka tanıma sistemi
// eşleşme bulamaz.
func NormalizePlate(p string) string {
	var b strings.Builder
	for _, r := range strings.ToUpper(strings.TrimSpace(p)) {
		if (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
		}
	}
	return b.String()
}

const vehicleSelect = `
SELECT v.id, COALESCE(v.property_id::text,''), COALESCE(v.unit_id::text,''),
       COALESCE(u.block,'') || CASE WHEN u.id IS NULL THEN '' ELSE '-' END || COALESCE(u.door_number,''),
       COALESCE(v.owner_type,'RESIDENT'), COALESCE(v.owner_name,''),
       COALESCE(v.plate, v.plate_number, ''), COALESCE(v.brand,''), COALESCE(v.model,''),
       COALESCE(v.color,''), COALESCE(v.vehicle_type,'CAR'), COALESCE(v.parking_spot,''),
       COALESCE(v.is_active,true), v.created_at
FROM vehicles v
LEFT JOIN units u ON u.id = v.unit_id`

func scanVehicle(row pgx.Row) (*Vehicle, error) {
	var v Vehicle
	err := row.Scan(&v.ID, &v.PropertyID, &v.UnitID, &v.UnitName, &v.OwnerType,
		&v.OwnerName, &v.Plate, &v.Brand, &v.Model, &v.Color, &v.VehicleType,
		&v.ParkingSpot, &v.IsActive, &v.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &v, nil
}

// ListVehicles, sitedeki araçları getirir.
// residentUserID doluysa yalnızca o sakinin araçları döner.
func (r *Repository) ListVehicles(ctx context.Context, propertyID, residentUserID string) ([]Vehicle, error) {
	rows, err := r.scope(propertyID).Query(ctx, vehicleSelect+`
		WHERE v.property_id = $1
		  AND ($2 = '' OR v.unit_id IN (
		        SELECT ru.unit_id FROM resident_units ru
		        WHERE ru.resident_id = NULLIF($2,'')::uuid AND ru.is_active = true))
		ORDER BY v.is_active DESC, u.block, u.door_number`, propertyID, residentUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Vehicle{}
	for rows.Next() {
		v, err := scanVehicle(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *v)
	}
	return out, rows.Err()
}

// FindByPlate, normalleştirilmiş plakayla araç arar.
func (r *Repository) FindByPlate(ctx context.Context, propertyID, plate string) (*Vehicle, error) {
	v, err := scanVehicle(r.scope(propertyID).QueryRow(ctx, vehicleSelect+`
		WHERE v.property_id = $1
		  AND regexp_replace(upper(COALESCE(v.plate, v.plate_number, '')), '[^A-Z0-9]', '', 'g') = $2
		  AND COALESCE(v.is_active,true)
		LIMIT 1`, propertyID, NormalizePlate(plate)))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return v, err
}

// CreateVehicle, araç kaydeder. Aynı plaka sitede iki kez kaydedilemez.
//
// ownerUserID doluysa (yönetim/görevli OLMAYAN çağıran) araç yalnızca o
// kişinin kendi dairesine kaydedilebilir. Önceden yalnızca dairenin siteye ait
// olduğu denetleniyordu: sakin, komşusunun dairesine araç bağlayabiliyordu.
func (r *Repository) CreateVehicle(ctx context.Context, propertyID, ownerUserID string, v Vehicle) (string, error) {
	norm := NormalizePlate(v.Plate)
	if norm == "" {
		return "", ErrPlateRequired
	}
	v.OwnerType = strings.ToUpper(strings.TrimSpace(defaultStr(v.OwnerType, "RESIDENT")))
	valid := false
	for _, t := range OwnerTypes {
		if t == v.OwnerType {
			valid = true
		}
	}
	if !valid {
		return "", ErrInvalidOwner
	}
	if ownerUserID != "" {
		if v.UnitID == "" {
			return "", ErrUnitRequired
		}
		var own bool
		if err := r.scope(propertyID).QueryRow(ctx, ownUnitSQL, v.UnitID, ownerUserID).Scan(&own); err != nil {
			return "", err
		}
		if !own {
			return "", ErrNotYourUnit
		}
	}

	if v.UnitID != "" {
		var ok bool
		if err := r.scope(propertyID).QueryRow(ctx,
			`SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2 AND deleted = 0)`,
			v.UnitID, propertyID).Scan(&ok); err != nil {
			return "", err
		}
		if !ok {
			return "", ErrUnitNotInSite
		}
	}

	if _, err := r.FindByPlate(ctx, propertyID, v.Plate); err == nil {
		return "", ErrPlateExists
	} else if !errors.Is(err, ErrNotFound) {
		return "", err
	}

	var id string
	// `plate_number` 001'den gelen kolon; NOT NULL kısıtı 005'te kaldırıldı ama
	// eski okuyucular için aynı değerle doldurulur (tek kaynak: `plate`).
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO vehicles
			(property_id, unit_id, owner_type, owner_name, plate, plate_number,
			 brand, model, color, vehicle_type, parking_spot, is_active)
		VALUES ($1, NULLIF($2,'')::uuid, $3, NULLIF($4,''), $5, $5,
		        NULLIF($6,''), NULLIF($7,''), NULLIF($8,''), $9, NULLIF($10,''), true)
		RETURNING id`,
		propertyID, v.UnitID, v.OwnerType, v.OwnerName,
		strings.ToUpper(strings.TrimSpace(v.Plate)), v.Brand, v.Model, v.Color,
		defaultStr(v.VehicleType, "CAR"), v.ParkingSpot).Scan(&id)
	return id, err
}

// DeactivateVehicle, aracı pasife alır (kayıt silinmez — geçmiş loglar bağlıdır).
//
// ownerUserID doluysa yalnızca o kişinin dairesine kayıtlı araç pasife
// alınabilir. Önceden hiçbir denetim yoktu: her sakin sitedeki HER aracı
// pasife alabiliyordu (araç otoparkta "misafir" sayılıp ücretlendirilirdi).
// Başkasının aracı "bulunamadı" olarak döner; varlığı sızdırılmaz.
func (r *Repository) DeactivateVehicle(ctx context.Context, propertyID, ownerUserID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx,
		`UPDATE vehicles SET is_active = false, updated_at = now()
		 WHERE id = $1 AND property_id = $2 AND COALESCE(is_active,true)
		   AND ($3 = '' OR unit_id IN (SELECT ru.unit_id FROM resident_units ru
		                               WHERE ru.resident_id = NULLIF($3,'')::uuid AND ru.is_active = true))`,
		id, propertyID, ownerUserID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// ListZones, otopark bölgelerini GERÇEK doluluk sayısıyla getirir.
//
// `parking_zones.current_count` kolonu güncel tutulmadığı için ona güvenilmez;
// doluluk açık giriş kayıtlarından sayılır. Aksi hâlde ekranda "15 boş yer var"
// yazarken otopark dolu olabilir.
func (r *Repository) ListZones(ctx context.Context, propertyID string) ([]Zone, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT z.id, z.name, COALESCE(z.location,''), COALESCE(z.capacity,0),
		       (SELECT count(*) FROM parking_logs l
		          WHERE l.parking_zone_id = z.id AND l.exit_at IS NULL)::int,
		       COALESCE(z.is_paid,false), z.hourly_fee::float8, z.daily_fee::float8,
		       COALESCE(z.is_visitor_allowed,true), COALESCE(z.is_active,true)
		FROM parking_zones z
		WHERE z.property_id = $1
		ORDER BY z.name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Zone{}
	for rows.Next() {
		var z Zone
		if err := rows.Scan(&z.ID, &z.Name, &z.Location, &z.Capacity, &z.OccupiedCount,
			&z.IsPaid, &z.HourlyFee, &z.DailyFee, &z.VisitorAllowed, &z.IsActive); err != nil {
			return nil, err
		}
		z.AvailableSpots = z.Capacity - z.OccupiedCount
		if z.AvailableSpots < 0 {
			z.AvailableSpots = 0
		}
		out = append(out, z)
	}
	return out, rows.Err()
}

// ZoneFeeInfo, ücret hesabı için bölge bilgisini getirir.
func (r *Repository) ZoneFeeInfo(ctx context.Context, propertyID, zoneID string) (isPaid bool, hourly, daily *float64, capacity, occupied int, err error) {
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT COALESCE(z.is_paid,false), z.hourly_fee::float8, z.daily_fee::float8,
		       COALESCE(z.capacity,0),
		       (SELECT count(*) FROM parking_logs l WHERE l.parking_zone_id = z.id AND l.exit_at IS NULL)::int
		FROM parking_zones z WHERE z.id = $1 AND z.property_id = $2`,
		zoneID, propertyID).Scan(&isPaid, &hourly, &daily, &capacity, &occupied)
	if err == pgx.ErrNoRows {
		err = ErrNotFound
	}
	return
}

// RecordEntry, araç girişini kaydeder.
//
// Aynı plaka için açık bir giriş varsa yeni giriş REDDEDİLİR; aksi hâlde araç
// otoparkta iki kez sayılır ve doluluk bilgisi bozulur.
func (r *Repository) RecordEntry(ctx context.Context, propertyID, zoneID, plate, gate, method string) (string, bool, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", false, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	norm := NormalizePlate(plate)

	// Doluluk denetimi TRANSACTION İÇİNDE ve bölge satırı kilitlenerek yapılır.
	// Önceden transaction dışındaydı: aynı anda gelen iki giriş, son boş yere
	// ikisi birden alınabiliyordu.
	if zoneID != "" {
		var capacity, occupied int
		if err := tx.QueryRow(ctx, `
			SELECT COALESCE(capacity,0) FROM parking_zones
			WHERE id = $1 AND property_id = $2 FOR UPDATE`, zoneID, propertyID).Scan(&capacity); err != nil {
			if err == pgx.ErrNoRows {
				return "", false, ErrNotFound
			}
			return "", false, err
		}
		if err := tx.QueryRow(ctx, `
			SELECT count(*) FROM parking_logs WHERE parking_zone_id = $1 AND exit_at IS NULL`,
			zoneID).Scan(&occupied); err != nil {
			return "", false, err
		}
		if capacity > 0 && occupied >= capacity {
			return "", false, ErrZoneFull
		}
	}

	var open int
	if err := tx.QueryRow(ctx, `
		SELECT count(*) FROM parking_logs
		WHERE property_id = $1 AND exit_at IS NULL
		  AND regexp_replace(upper(plate), '[^A-Z0-9]', '', 'g') = $2`,
		propertyID, norm).Scan(&open); err != nil {
		return "", false, err
	}
	if open > 0 {
		return "", false, ErrAlreadyInside
	}

	// Sitede kayıtlı araç mı? (ücretsiz geçiş ve sahip bilgisi için)
	var vehicleID *string
	var resident bool
	err = tx.QueryRow(ctx, `
		SELECT id::text FROM vehicles
		WHERE property_id = $1
		  AND regexp_replace(upper(COALESCE(plate, plate_number, '')), '[^A-Z0-9]', '', 'g') = $2
		  AND COALESCE(is_active,true) LIMIT 1`, propertyID, norm).Scan(&vehicleID)
	if err != nil && err != pgx.ErrNoRows {
		return "", false, err
	}
	resident = vehicleID != nil

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO parking_logs
			(property_id, parking_zone_id, vehicle_id, plate, entry_gate, entry_method, payment_status)
		VALUES ($1, NULLIF($2,'')::uuid, NULLIF($3,'')::uuid, $4, NULLIF($5,''), NULLIF($6,''), 'PENDING')
		RETURNING id`,
		propertyID, zoneID, strOrEmpty(vehicleID), strings.ToUpper(strings.TrimSpace(plate)),
		gate, method).Scan(&id); err != nil {
		return "", false, err
	}

	if err := tx.Commit(ctx); err != nil {
		return "", false, err
	}
	return id, resident, nil
}

// OpenLog, açık (çıkış yapılmamış) kaydı getirir.
func (r *Repository) OpenLog(ctx context.Context, propertyID, id string) (entryAt time.Time, zoneID string, isResident bool, err error) {
	var zone *string
	var vehicle *string
	err = r.scope(propertyID).QueryRow(ctx, `
		SELECT entry_at, parking_zone_id::text, vehicle_id::text
		FROM parking_logs WHERE id = $1 AND property_id = $2 AND exit_at IS NULL`,
		id, propertyID).Scan(&entryAt, &zone, &vehicle)
	if err == pgx.ErrNoRows {
		err = ErrNotInside
		return
	}
	zoneID = strOrEmpty(zone)
	isResident = vehicle != nil
	return
}

// RecordExit, çıkışı ve hesaplanan ücreti yazar.
func (r *Repository) RecordExit(ctx context.Context, propertyID, id, gate string, durationMinutes int, feeTRY float64) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE parking_logs
		SET exit_at = now(), exit_gate = NULLIF($3,''),
		    duration_minutes = $4,
		    -- Açık cast: aynı parametre hem atamada hem karşılaştırmada kullanıldığında
		    -- PostgreSQL tip çıkarımı yapamıyor (42P08 inconsistent types).
		    calculated_fee = $5::numeric,
		    payment_status = CASE WHEN $5::numeric = 0 THEN 'FREE' ELSE 'PENDING' END
		WHERE id = $1 AND property_id = $2 AND exit_at IS NULL`,
		id, propertyID, gate, durationMinutes, feeTRY)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "parking_logs", id, ErrNotFound, ErrNotInside)
	}
	return nil
}

// ListLogs, otopark hareketlerini getirir. `inside` true ise yalnızca içeridekiler.
func (r *Repository) ListLogs(ctx context.Context, propertyID string, inside bool) ([]Log, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT l.id, COALESCE(l.parking_zone_id::text,''), COALESCE(z.name,''),
		       COALESCE(l.vehicle_id::text,''), l.plate, l.entry_at,
		       COALESCE(l.entry_gate,''), COALESCE(l.entry_method,''),
		       l.exit_at, l.duration_minutes, l.calculated_fee::float8,
		       l.paid_fee::float8, COALESCE(l.payment_status,''),
		       (l.vehicle_id IS NOT NULL)
		FROM parking_logs l
		LEFT JOIN parking_zones z ON z.id = l.parking_zone_id
		WHERE l.property_id = $1 AND ($2 = false OR l.exit_at IS NULL)
		ORDER BY l.entry_at DESC
		LIMIT 501`, propertyID, inside)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Log{}
	for rows.Next() {
		var l Log
		if err := rows.Scan(&l.ID, &l.ZoneID, &l.ZoneName, &l.VehicleID, &l.Plate,
			&l.EntryAt, &l.EntryGate, &l.EntryMethod, &l.ExitAt, &l.DurationMinutes,
			&l.CalculatedFee, &l.PaidFee, &l.PaymentStatus, &l.IsResident); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	return out, rows.Err()
}

func defaultStr(v, def string) string {
	if strings.TrimSpace(v) == "" {
		return def
	}
	return v
}

func strOrEmpty(p *string) string {
	if p == nil {
		return ""
	}
	return *p
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// vehicles, parking_zones, parking_logs tablolarında RLS açıktır (migration 021).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// stateOrNotFound, durum geçişli bir güncelleme 0 satır etkilediğinde iki
// ihtimali ayırır: kayıt hiç yoksa (ya da başka siteye aitse) notFound (404),
// varsa ama durumu uygun değilse state (409). Önceden ikisi de 409 dönüyordu;
// istemci var olmayan kaydı "başkası işlem yapmış" sanıyordu.
func (r *Repository) stateOrNotFound(ctx context.Context, propertyID, table, id string, notFound, state error) error {
	ok, err := r.scope(propertyID).Exists(ctx, table, id)
	if err != nil {
		return err
	}
	if !ok {
		return notFound
	}
	return state
}
