// Package repository, rezervasyon modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrNotFound = errors.New("kayıt bulunamadı")
	ErrConflict = errors.New("seçilen saat aralığı dolu")
	// ErrBadState, hem "durum uygun değil" hem "kayıt size ait değil" halini kapsar:
	// sahiplik bilgisini ayrıştırmak, başkasının rezervasyonunun varlığını sızdırır.
	ErrBadState = errors.New("rezervasyon bu işlem için uygun durumda değil")
	ErrNoUnit   = errors.New("kullanıcının sitede aktif bir bağımsız bölümü yok")
)

// Facility, ortak kullanım tesisidir.
type Facility struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Category    string   `json:"category,omitempty"`
	Capacity    *int     `json:"capacity,omitempty"`
	IsPaid      bool     `json:"is_paid"`
	HourlyFee   *float64 `json:"hourly_fee,omitempty"`
	DailyFee    *float64 `json:"daily_fee,omitempty"`
	Deposit     *float64 `json:"deposit_amount,omitempty"`

	AvailableFrom string `json:"available_from"`
	AvailableTo   string `json:"available_to"`
	AvailableDays []int  `json:"available_days"`

	MinDurationMinutes     int `json:"min_duration_minutes"`
	MaxDurationMinutes     int `json:"max_duration_minutes"`
	AdvanceBookingDays     int `json:"advance_booking_days"`
	MaxReservationsPerUnit int `json:"max_reservations_per_unit"`
	BufferMinutes          int `json:"buffer_minutes"`

	RequiresApproval     bool   `json:"requires_approval"`
	AutoApproveResidents bool   `json:"auto_approve_residents"`
	Rules                string `json:"rules,omitempty"`
	IsActive             bool   `json:"is_active"`
	MaintenanceMode      bool   `json:"maintenance_mode"`
	MaintenanceNote      string `json:"maintenance_note,omitempty"`
}

// Reservation, rezervasyon kaydıdır.
type Reservation struct {
	ID              string     `json:"id"`
	FacilityID      string     `json:"facility_id"`
	FacilityName    string     `json:"facility_name,omitempty"`
	UnitID          string     `json:"unit_id"`
	UnitName        string     `json:"unit_name,omitempty"`
	ResidentID      string     `json:"resident_id"`
	ResidentName    string     `json:"resident_name,omitempty"`
	StartTime       time.Time  `json:"start_time"`
	EndTime         time.Time  `json:"end_time"`
	DurationMinutes int        `json:"duration_minutes"`
	GuestCount      int        `json:"guest_count"`
	Purpose         string     `json:"purpose,omitempty"`
	Status          string     `json:"status"`
	TotalFee        float64    `json:"total_fee"`
	PaymentStatus   string     `json:"payment_status,omitempty"`
	RejectionReason string     `json:"rejection_reason,omitempty"`
	CancelledAt     *time.Time `json:"cancelled_at,omitempty"`
	CreatedAt       time.Time  `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// ListFacilities, sitedeki tesisleri getirir.
func (r *Repository) ListFacilities(ctx context.Context, propertyID string) ([]Facility, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, COALESCE(description,''), COALESCE(category,''), capacity,
		       COALESCE(is_paid,false), hourly_fee::float8, daily_fee::float8, deposit_amount::float8,
		       to_char(COALESCE(available_from, TIME '08:00'), 'HH24:MI'),
		       to_char(COALESCE(available_to, TIME '22:00'), 'HH24:MI'),
		       COALESCE(available_days, '{1,2,3,4,5,6,0}'),
		       COALESCE(min_duration_minutes,60), COALESCE(max_duration_minutes,240),
		       COALESCE(advance_booking_days,14), COALESCE(max_reservations_per_unit,2),
		       COALESCE(buffer_minutes,0), COALESCE(requires_approval,false),
		       COALESCE(auto_approve_residents,true),
		       COALESCE(rules,''), COALESCE(is_active,true),
		       COALESCE(maintenance_mode,false), COALESCE(maintenance_note,'')
		FROM facilities WHERE property_id = $1 ORDER BY name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Facility{}
	for rows.Next() {
		var f Facility
		if err := rows.Scan(&f.ID, &f.Name, &f.Description, &f.Category, &f.Capacity,
			&f.IsPaid, &f.HourlyFee, &f.DailyFee, &f.Deposit, &f.AvailableFrom, &f.AvailableTo,
			&f.AvailableDays, &f.MinDurationMinutes, &f.MaxDurationMinutes,
			&f.AdvanceBookingDays, &f.MaxReservationsPerUnit, &f.BufferMinutes,
			&f.RequiresApproval, &f.AutoApproveResidents, &f.Rules, &f.IsActive,
			&f.MaintenanceMode, &f.MaintenanceNote); err != nil {
			return nil, err
		}
		out = append(out, f)
	}
	return out, rows.Err()
}

// GetFacility, tek tesisi getirir.
func (r *Repository) GetFacility(ctx context.Context, propertyID, id string) (*Facility, error) {
	list, err := r.ListFacilities(ctx, propertyID)
	if err != nil {
		return nil, err
	}
	for i := range list {
		if list[i].ID == id {
			return &list[i], nil
		}
	}
	return nil, ErrNotFound
}

// ResidentUnit, kullanıcının bu sitedeki aktif bağımsız bölümünü verir.
func (r *Repository) ResidentUnit(ctx context.Context, propertyID, userID string) (string, error) {
	var unitID string
	err := r.pool.QueryRow(ctx, `
		SELECT ru.unit_id::text
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE ru.resident_id = $1 AND ru.is_active = true AND u.property_id = $2
		LIMIT 1`, userID, propertyID).Scan(&unitID)
	if err == pgx.ErrNoRows {
		return "", ErrNoUnit
	}
	return unitID, err
}

const reservationSelect = `
SELECT r.id, r.facility_id, COALESCE(f.name,''), r.unit_id,
       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
       r.resident_id, COALESCE(us.first_name || ' ' || us.last_name, ''),
       r.start_time, r.end_time, COALESCE(r.duration_minutes,0),
       COALESCE(r.guest_count,1), COALESCE(r.purpose,''), r.status,
       COALESCE(r.total_fee,0)::float8, COALESCE(r.payment_status,''),
       COALESCE(r.rejection_reason,''), r.cancelled_at, r.created_at
FROM reservations r
LEFT JOIN facilities f ON f.id = r.facility_id
LEFT JOIN units u ON u.id = r.unit_id
LEFT JOIN users us ON us.id = r.resident_id`

func scanReservation(row pgx.Row) (*Reservation, error) {
	var r2 Reservation
	err := row.Scan(&r2.ID, &r2.FacilityID, &r2.FacilityName, &r2.UnitID, &r2.UnitName,
		&r2.ResidentID, &r2.ResidentName, &r2.StartTime, &r2.EndTime, &r2.DurationMinutes,
		&r2.GuestCount, &r2.Purpose, &r2.Status, &r2.TotalFee, &r2.PaymentStatus,
		&r2.RejectionReason, &r2.CancelledAt, &r2.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &r2, nil
}

// List, rezervasyonları getirir. residentUserID doluysa yalnızca o kişininkiler.
func (r *Repository) List(ctx context.Context, propertyID, residentUserID, status, facilityID string) ([]Reservation, error) {
	rows, err := r.pool.Query(ctx, reservationSelect+`
		WHERE r.property_id = $1
		  AND ($2 = '' OR r.resident_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR r.status = $3)
		  AND ($4 = '' OR r.facility_id = NULLIF($4,'')::uuid)
		ORDER BY r.start_time DESC
		LIMIT 500`, propertyID, residentUserID, status, facilityID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Reservation{}
	for rows.Next() {
		res, err := scanReservation(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *res)
	}
	return out, rows.Err()
}

// Slots, bir tesisin belirli gündeki DOLU aralıklarını verir.
func (r *Repository) Slots(ctx context.Context, propertyID, facilityID string, day time.Time) ([]Reservation, error) {
	rows, err := r.pool.Query(ctx, reservationSelect+`
		WHERE r.property_id = $1 AND r.facility_id = $2
		  AND r.status IN ('PENDING','APPROVED')
		  AND r.start_time::date = $3::date
		ORDER BY r.start_time`, propertyID, facilityID, day)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Reservation{}
	for rows.Next() {
		res, err := scanReservation(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *res)
	}
	return out, rows.Err()
}

// WeeklyCount, bir bağımsız bölümün ilgili tesiste o haftaki rezervasyon sayısını verir.
func (r *Repository) WeeklyCount(ctx context.Context, facilityID, unitID string, start time.Time) (int, error) {
	var n int
	err := r.pool.QueryRow(ctx, `
		SELECT count(*) FROM reservations
		WHERE facility_id = $1 AND unit_id = $2
		  AND status IN ('PENDING','APPROVED')
		  AND date_trunc('week', start_time) = date_trunc('week', $3::timestamptz)`,
		facilityID, unitID, start).Scan(&n)
	return n, err
}

// Create, rezervasyonu ÇAKIŞMA DENETİMİYLE oluşturur.
//
// Çakışma kontrolü ile kayıt AYNI TRANSACTION içinde ve ilgili tesis satırı
// kilitlenerek yapılır. Aksi hâlde iki kişi aynı anda aynı saati alabilir
// (yarış durumu) — mock sürümde çakışma denetimi hiç yoktu ve iki sakin aynı
// saati "ayırttığını" sanabiliyordu.
//
// bufferMinutes, tesis ayarındaki ardışık rezervasyonlar arası zorunlu boşluktur
// (temizlik/hazırlık payı).
func (r *Repository) Create(
	ctx context.Context,
	propertyID, facilityID, unitID, residentID string,
	start, end time.Time,
	bufferMinutes, guestCount int,
	purpose, status string,
	totalFee float64,
) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Tesis satırını kilitle: aynı tesise eşzamanlı rezervasyonlar sıraya girer.
	var locked string
	if err := tx.QueryRow(ctx,
		`SELECT id::text FROM facilities WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		facilityID, propertyID).Scan(&locked); err != nil {
		if err == pgx.ErrNoRows {
			return "", ErrNotFound
		}
		return "", err
	}

	buffer := time.Duration(bufferMinutes) * time.Minute
	var conflicts int
	if err := tx.QueryRow(ctx, `
		SELECT count(*) FROM reservations
		WHERE facility_id = $1
		  AND status IN ('PENDING','APPROVED')
		  AND tstzrange(start_time, end_time, '[)') && tstzrange($2::timestamptz, $3::timestamptz, '[)')`,
		facilityID, start.Add(-buffer), end.Add(buffer)).Scan(&conflicts); err != nil {
		return "", err
	}
	if conflicts > 0 {
		return "", ErrConflict
	}

	duration := int(end.Sub(start).Minutes())
	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO reservations
			(property_id, facility_id, unit_id, resident_id, start_time, end_time,
			 duration_minutes, guest_count, purpose, status, total_fee, payment_status)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,NULLIF($9,''),$10,$11::numeric,
		        CASE WHEN $11::numeric > 0 THEN 'PENDING' ELSE 'NOT_REQUIRED' END)
		RETURNING id`,
		propertyID, facilityID, unitID, residentID, start, end,
		duration, guestCount, purpose, status, totalFee).Scan(&id); err != nil {
		return "", err
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

// Decide, rezervasyonu onaylar veya reddeder (yönetim).
func (r *Repository) Decide(ctx context.Context, propertyID, id, status, userID, reason string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE reservations
		SET status = $3, reviewed_by = NULLIF($4,'')::uuid, reviewed_at = now(),
		    rejection_reason = NULLIF($5,''), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING'`,
		id, propertyID, status, userID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// Cancel, rezervasyonu iptal eder. residentID doluysa yalnızca sahibi iptal edebilir.
func (r *Repository) Cancel(ctx context.Context, propertyID, id, residentID, reason string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE reservations
		SET status = 'CANCELLED', cancelled_at = now(),
		    cancelled_by = NULLIF($3,'')::uuid, cancellation_reason = NULLIF($4,''),
		    updated_at = now()
		WHERE id = $1 AND property_id = $2
		  AND status IN ('PENDING','APPROVED')
		  AND ($3 = '' OR resident_id = NULLIF($3,'')::uuid)`,
		id, propertyID, residentID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}
