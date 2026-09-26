// Package repository, kargo/paket takibi modülünün veritabanı işlemlerini içerir.
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
	ErrInvalidType   = errors.New("paket türü geçersiz")
	ErrNotFound      = errors.New("kayıt bulunamadı")
	ErrUnitNotInSite = errors.New("bağımsız bölüm bu siteye ait değil")
	ErrBadState      = errors.New("paket bu işlem için uygun durumda değil")
	ErrNoUnit        = errors.New("kullanıcının sitede aktif bir bağımsız bölümü yok")
)

// Package, teslim alınan bir kargo/paket kaydıdır.
type Package struct {
	ID             string `json:"id"`
	UnitID         string `json:"unit_id"`
	UnitName       string `json:"unit_name,omitempty"`
	RecipientName  string `json:"recipient_name"`
	RecipientPhone string `json:"recipient_phone,omitempty"`
	Carrier        string `json:"carrier,omitempty"`
	TrackingNumber string `json:"tracking_number,omitempty"`
	PackageType    string `json:"package_type"`
	Description    string `json:"description,omitempty"`

	ReceivedAt      time.Time `json:"received_at"`
	ReceivedByName  string    `json:"received_by_name,omitempty"`
	StorageLocation string    `json:"storage_location,omitempty"`

	NotificationSent bool `json:"notification_sent"`
	ReminderCount    int  `json:"reminder_count"`

	DeliveredAt     *time.Time `json:"delivered_at,omitempty"`
	DeliveredByName string     `json:"delivered_by_name,omitempty"`
	DeliveredToName string     `json:"delivered_to_name,omitempty"`

	Status string `json:"status"`
	Notes  string `json:"notes,omitempty"`

	// WaitingDays, teslim alınmayan paketin kaç gündür beklediğidir. Görevlinin
	// depo yükünü ve unutulan paketleri görebilmesi için hesaplanır.
	WaitingDays int `json:"waiting_days,omitempty"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const packageSelect = `
SELECT p.id, p.unit_id,
       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
       p.recipient_name, COALESCE(p.recipient_phone,''),
       COALESCE(p.carrier,''), COALESCE(p.tracking_number,''),
       COALESCE(p.package_type,'PACKAGE'), COALESCE(p.description,''),
       p.received_at, COALESCE(rb.first_name || ' ' || rb.last_name, ''),
       COALESCE(p.storage_location,''),
       COALESCE(p.notification_sent,false), COALESCE(p.reminder_count,0),
       p.delivered_at, COALESCE(db.first_name || ' ' || db.last_name, ''),
       COALESCE(p.delivered_to_name,''), p.status, COALESCE(p.notes,''),
       CASE WHEN p.delivered_at IS NULL
            THEN GREATEST(0, EXTRACT(DAY FROM (now() - p.received_at))::int)
            ELSE 0 END
FROM packages p
LEFT JOIN units u ON u.id = p.unit_id
LEFT JOIN users rb ON rb.id = p.received_by
LEFT JOIN users db ON db.id = p.delivered_by`

func scanPackage(row pgx.Row) (*Package, error) {
	var p Package
	err := row.Scan(&p.ID, &p.UnitID, &p.UnitName, &p.RecipientName, &p.RecipientPhone,
		&p.Carrier, &p.TrackingNumber, &p.PackageType, &p.Description,
		&p.ReceivedAt, &p.ReceivedByName, &p.StorageLocation,
		&p.NotificationSent, &p.ReminderCount,
		&p.DeliveredAt, &p.DeliveredByName, &p.DeliveredToName,
		&p.Status, &p.Notes, &p.WaitingDays)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// List, paketleri getirir.
//
//	unitScope dolu ise yalnızca o bağımsız bölümün paketleri döner (sakin görünümü).
//	pending true ise yalnızca teslim edilmemiş paketler döner.
func (r *Repository) List(ctx context.Context, propertyID, unitScope, status string, pending bool) ([]Package, error) {
	rows, err := r.scope(propertyID).Query(ctx, packageSelect+`
		WHERE p.property_id = $1
		  AND ($2 = '' OR p.unit_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR p.status = $3)
		  AND ($4 = false OR p.status IN ('RECEIVED','NOTIFIED'))
		ORDER BY p.received_at DESC
		LIMIT 500`, propertyID, unitScope, status, pending)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Package{}
	for rows.Next() {
		p, err := scanPackage(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *p)
	}
	return out, rows.Err()
}

// Get, tek paketi getirir. unitScope dolu ise başka bölümün paketi görünmez.
func (r *Repository) Get(ctx context.Context, propertyID, id, unitScope string) (*Package, error) {
	p, err := scanPackage(r.scope(propertyID).QueryRow(ctx, packageSelect+`
		WHERE p.property_id = $1 AND p.id = $2
		  AND ($3 = '' OR p.unit_id = NULLIF($3,'')::uuid)`, propertyID, id, unitScope))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return p, err
}

// ResidentUnit, kullanıcının bu sitedeki aktif bağımsız bölümünü verir.
func (r *Repository) ResidentUnit(ctx context.Context, propertyID, userID string) (string, error) {
	var unitID string
	err := r.scope(propertyID).QueryRow(ctx, `
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

// CreateInput, kargo teslim alma girdisidir.
type CreateInput struct {
	UnitID          string `json:"unit_id" binding:"required"`
	RecipientName   string `json:"recipient_name" binding:"required"`
	RecipientPhone  string `json:"recipient_phone"`
	Carrier         string `json:"carrier"`
	TrackingNumber  string `json:"tracking_number"`
	PackageType     string `json:"package_type"`
	Description     string `json:"description"`
	StorageLocation string `json:"storage_location"`
	Notes           string `json:"notes"`
}

// Create, kargoyu KALICI olarak kaydeder.
//
// notification_sent alanı bilerek false bırakılır: bildirim altyapısı bağlı
// değildir ve "bildirim gönderildi" yazmak sakine yalan söylemek olur.
func (r *Repository) Create(ctx context.Context, propertyID, receivedBy string, in CreateInput) (string, error) {
	// Bağımsız bölümün gerçekten bu siteye ait olduğu doğrulanır; aksi hâlde
	// başka sitenin kapısına kargo kaydı düşebilir.
	var ok bool
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2)`,
		in.UnitID, propertyID).Scan(&ok); err != nil {
		return "", err
	}
	if !ok {
		return "", ErrUnitNotInSite
	}

	pkgType := strings.ToUpper(strings.TrimSpace(in.PackageType))
	switch pkgType {
	case "":
		pkgType = "PACKAGE"
	case "PACKAGE", "ENVELOPE", "LARGE":
	default:
		// Önceden geçersiz tür SESSİZCE "PACKAGE" yapılıyordu.
		return "", ErrInvalidType
	}

	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO packages
			(property_id, unit_id, recipient_name, recipient_phone, carrier,
			 tracking_number, package_type, description, received_by,
			 storage_location, notes, status)
		VALUES ($1,$2,$3,NULLIF($4,''),NULLIF($5,''),NULLIF($6,''),$7,NULLIF($8,''),
		        NULLIF($9,'')::uuid, NULLIF($10,''), NULLIF($11,''), 'RECEIVED')
		RETURNING id`,
		propertyID, in.UnitID, in.RecipientName, in.RecipientPhone, in.Carrier,
		in.TrackingNumber, pkgType, in.Description, receivedBy,
		in.StorageLocation, in.Notes).Scan(&id)
	return id, err
}

// Deliver, paketi teslim eder. Kime teslim edildiği zorunludur.
//
// Teslim, yalnızca teslim edilmemiş paketlerde yapılabilir; aksi hâlde aynı paket
// iki kez "teslim edildi" görünür ve kaybolan kargonun izi kaybolur.
func (r *Repository) Deliver(ctx context.Context, propertyID, id, deliveredBy, toName string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE packages
		SET status = 'DELIVERED', delivered_at = now(),
		    delivered_by = NULLIF($3,'')::uuid, delivered_to_name = $4
		WHERE id = $1 AND property_id = $2 AND status IN ('RECEIVED','NOTIFIED')`,
		id, propertyID, deliveredBy, toName)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "packages", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// Return, paketi kargo firmasına iade eder. Gerekçe zorunludur.
func (r *Repository) Return(ctx context.Context, propertyID, id, reason string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE packages
		SET status = 'RETURNED',
		    notes = COALESCE(notes || E'\n', '') || 'İade: ' || $3
		WHERE id = $1 AND property_id = $2 AND status IN ('RECEIVED','NOTIFIED')`,
		id, propertyID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "packages", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// MarkNotified, sakine haber verildiğini işaretler.
//
// method alanı, haberin NASIL verildiğini kaydeder. Otomatik bildirim altyapısı
// yoktur; bu uç, görevlinin elle (kapı zili, telefon, yüz yüze) haber verdiğini
// kayda geçirmesi içindir. Sistem kendiliğinden bildirim GÖNDERMEZ.
func (r *Repository) MarkNotified(ctx context.Context, propertyID, id, method string) (int, error) {
	var reminders int
	err := r.scope(propertyID).QueryRow(ctx, `
		UPDATE packages
		SET status = CASE WHEN status = 'RECEIVED' THEN 'NOTIFIED' ELSE status END,
		    notification_sent = true,
		    notification_sent_at = COALESCE(notification_sent_at, now()),
		    notification_method = $3,
		    reminder_count = COALESCE(reminder_count,0) + CASE WHEN notification_sent THEN 1 ELSE 0 END,
		    last_reminder_at = CASE WHEN notification_sent THEN now() ELSE last_reminder_at END
		WHERE id = $1 AND property_id = $2 AND status IN ('RECEIVED','NOTIFIED')
		RETURNING reminder_count`, id, propertyID, method).Scan(&reminders)
	if err == pgx.ErrNoRows {
		return 0, r.stateOrNotFound(ctx, propertyID, "packages", id, ErrNotFound, ErrBadState)
	}
	return reminders, err
}

// Summary, depodaki paket durumunun özetidir.
type Summary struct {
	Pending        int `json:"pending"`
	Delivered      int `json:"delivered"`
	Returned       int `json:"returned"`
	NotNotified    int `json:"not_notified"`
	WaitingOver7   int `json:"waiting_over_7_days"`
	OldestWaitDays int `json:"oldest_waiting_days"`
}

// Summary, site genelinde paket sayımlarını verir.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	var s Summary
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT
		  count(*) FILTER (WHERE status IN ('RECEIVED','NOTIFIED')),
		  count(*) FILTER (WHERE status = 'DELIVERED'),
		  count(*) FILTER (WHERE status = 'RETURNED'),
		  count(*) FILTER (WHERE status IN ('RECEIVED','NOTIFIED') AND notification_sent = false),
		  count(*) FILTER (WHERE status IN ('RECEIVED','NOTIFIED') AND received_at < now() - interval '7 days'),
		  COALESCE(MAX(EXTRACT(DAY FROM (now() - received_at))::int)
		           FILTER (WHERE status IN ('RECEIVED','NOTIFIED')), 0)
		FROM packages WHERE property_id = $1`, propertyID).
		Scan(&s.Pending, &s.Delivered, &s.Returned, &s.NotNotified, &s.WaitingOver7, &s.OldestWaitDays)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// packages tablolarında RLS açıktır (migration 022).
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

// PackageTypes, kabul edilen paket türleridir.
var PackageTypes = []string{"PACKAGE", "ENVELOPE", "LARGE"}
