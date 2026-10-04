// Package repository, sayaç ve tüketim modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrInvalidValue    = errors.New("endeks negatif olmayan bir sayı olmalıdır")
	ErrNotFound        = errors.New("sayaç bulunamadı")
	ErrUnitNotInSite   = errors.New("bağımsız bölüm bu siteye ait değil")
	ErrDuplicateSerial = errors.New("bu seri numarası zaten kayıtlı")
	ErrInvalidType     = errors.New("geçersiz sayaç türü")
	ErrInactive        = errors.New("sayaç pasif")
	ErrChainBroken     = errors.New("önceki endeks son okumayla uyuşmuyor")
	ErrBackwards       = errors.New("sayaç geriye dönemez")
	ErrDuplicateRead   = errors.New("bu dönem için okuma zaten girilmiş")
	ErrNoReadings      = errors.New("dönemde okuma yok")
	ErrMissingArea     = errors.New("kullanım alanı tanımsız bağımsız bölüm var")
)

// MeterTypes, desteklenen sayaç türleridir.
var MeterTypes = []string{"HEAT", "WATER_COLD", "WATER_HOT", "GAS", "ELECTRIC"}

// ReadingTypes, okuma kaynağını belirtir. ESTIMATED (tahmini) okuma, gerçek
// okuma yapılamadığında kullanılır ve raporda ayrıca işaretlenir — tahmini
// tüketimi gerçekmiş gibi göstermek, sonraki dönemde düzeltme kavgası çıkarır.
var ReadingTypes = []string{"MANUAL", "AUTOMATIC", "ESTIMATED"}

// Meter, bir bağımsız bölüme bağlı sayaçtır.
type Meter struct {
	ID           string `json:"id"`
	UnitID       string `json:"unit_id"`
	UnitName     string `json:"unit_name,omitempty"`
	MeterType    string `json:"meter_type"`
	SerialNumber string `json:"serial_number"`
	Brand        string `json:"brand,omitempty"`
	Model        string `json:"model,omitempty"`

	InstallationDate *time.Time `json:"installation_date,omitempty"`
	LastCalibration  *time.Time `json:"last_calibration_date,omitempty"`
	IsActive         bool       `json:"is_active"`

	LastReadingDate  *time.Time `json:"last_reading_date,omitempty"`
	LastReadingValue *string    `json:"last_reading_value,omitempty"`
}

// Reading, bir sayaç okumasıdır.
type Reading struct {
	ID            string    `json:"id"`
	MeterID       string    `json:"meter_id"`
	SerialNumber  string    `json:"serial_number,omitempty"`
	UnitName      string    `json:"unit_name,omitempty"`
	ReadingDate   time.Time `json:"reading_date"`
	PreviousValue string    `json:"previous_value"`
	CurrentValue  string    `json:"current_value"`
	Consumption   string    `json:"consumption"`
	ReadingType   string    `json:"reading_type"`
	ReaderName    string    `json:"reader_name,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const meterSelect = `
SELECT m.id, m.unit_id, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
       m.meter_type, m.serial_number, COALESCE(m.brand,''), COALESCE(m.model,''),
       m.installation_date, m.last_calibration_date, COALESCE(m.is_active,true),
       lr.reading_date, lr.current_value::text
FROM meters m
JOIN units u ON u.id = m.unit_id
LEFT JOIN LATERAL (
    SELECT r.reading_date, r.current_value
    FROM meter_readings r
    WHERE r.meter_id = m.id
    ORDER BY r.reading_date DESC, r.created_at DESC
    LIMIT 1
) lr ON true`

func scanMeter(row pgx.Row) (*Meter, error) {
	var m Meter
	err := row.Scan(&m.ID, &m.UnitID, &m.UnitName, &m.MeterType, &m.SerialNumber,
		&m.Brand, &m.Model, &m.InstallationDate, &m.LastCalibration, &m.IsActive,
		&m.LastReadingDate, &m.LastReadingValue)
	if err != nil {
		return nil, err
	}
	return &m, nil
}

// ListMeters, sitedeki sayaçları getirir. unitScope doluysa yalnızca o bölümünkiler.
func (r *Repository) ListMeters(ctx context.Context, propertyID, unitScope, meterType string, includeInactive bool) ([]Meter, error) {
	rows, err := r.scope(propertyID).Query(ctx, meterSelect+`
		WHERE u.property_id = $1
		  AND ($2 = '' OR m.unit_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR m.meter_type = $3)
		  AND ($4 OR COALESCE(m.is_active,true) = true)
		ORDER BY u.block, u.door_number, m.meter_type
		LIMIT 2001`, propertyID, unitScope, strings.ToUpper(meterType), includeInactive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Meter{}
	for rows.Next() {
		m, err := scanMeter(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *m)
	}
	return out, rows.Err()
}

// CreateMeter, sayacı kaydeder.
func (r *Repository) CreateMeter(ctx context.Context, propertyID, unitID, meterType, serial, brand, model, installDate string) (string, error) {
	mType := strings.ToUpper(strings.TrimSpace(meterType))
	if !contains(MeterTypes, mType) {
		return "", ErrInvalidType
	}

	var ok bool
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2)`,
		unitID, propertyID).Scan(&ok); err != nil {
		return "", err
	}
	if !ok {
		return "", ErrUnitNotInSite
	}

	var install *time.Time
	if d := strings.TrimSpace(installDate); d != "" {
		t, err := time.Parse("2006-01-02", d)
		if err != nil {
			return "", ErrInvalidType
		}
		install = &t
	}

	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO meters (unit_id, meter_type, serial_number, brand, model,
		                    installation_date, is_active)
		VALUES ($1,$2,$3,NULLIF($4,''),NULLIF($5,''),$6,true)
		RETURNING id`,
		unitID, mType, strings.TrimSpace(serial), brand, model, install).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "duplicate key") {
		return "", ErrDuplicateSerial
	}
	return id, err
}

// ReadingInput, tek sayaç okuması girdisidir.
type ReadingInput struct {
	MeterID      string `json:"meter_id" binding:"required"`
	ReadingDate  string `json:"reading_date"`
	CurrentValue string `json:"current_value" binding:"required"`
	ReadingType  string `json:"reading_type"`
	// MeterReplaced true ise sayaç değişmiş/sıfırlanmış demektir; endeks zinciri
	// kırılmasına yalnızca gerekçeyle izin verilir.
	MeterReplaced bool   `json:"meter_replaced"`
	Reason        string `json:"reason"`
}

// AddReading, okumayı kaydeder.
//
// Denetimler (hepsi sunucuda):
//   - sayaç bu siteye mi ait, aktif mi
//   - önceki endeks, son okumanın endeksiyle aynı mı (zincir bütünlüğü)
//   - sayaç geriye dönmüş mü (endeks azalmışsa hata; ancak sayaç değişimi
//     bildirilmişse gerekçeyle kabul edilir)
//   - aynı gün için ikinci okuma var mı
//
// Zincir denetimi olmadan bir dönemin tüketimi iki kez faturalanabilir ya da
// hiç faturalanmayabilir; sakine "sayacın yanlış okundu" denemez hâle gelir.
func (r *Repository) AddReading(ctx context.Context, propertyID, userID string, in ReadingInput) (*Reading, error) {
	current, err := decimal.NewFromString(strings.TrimSpace(strings.ReplaceAll(in.CurrentValue, ",", ".")))
	if err != nil || current.IsNegative() {
		// Önceden "sayaç geri gidemez" diyordu; sayı olmayan değer için yanıltıcıydı.
		return nil, ErrInvalidValue
	}

	readingDate := time.Now()
	if d := strings.TrimSpace(in.ReadingDate); d != "" {
		t, perr := time.Parse("2006-01-02", d)
		if perr != nil {
			return nil, ErrInvalidType
		}
		readingDate = t
	}

	rType := strings.ToUpper(strings.TrimSpace(in.ReadingType))
	if rType == "" {
		rType = "MANUAL"
	}
	if !contains(ReadingTypes, rType) {
		return nil, ErrInvalidType
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var isActive bool
	var serial, unitName string
	if err := tx.QueryRow(ctx, `
		SELECT COALESCE(m.is_active,true), m.serial_number,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,'')
		FROM meters m JOIN units u ON u.id = m.unit_id
		WHERE m.id = $1 AND u.property_id = $2
		FOR UPDATE OF m`, in.MeterID, propertyID).Scan(&isActive, &serial, &unitName); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if !isActive {
		return nil, ErrInactive
	}

	// Son okuma: önceki endeks buradan alınır — istemciden DEĞİL.
	// İstemciye bırakılsaydı, yanlış bir "önceki endeks" ile tüketim istenildiği
	// gibi büyütülüp küçültülebilirdi.
	var lastValue decimal.Decimal
	var lastDate *time.Time
	var lastStr *string
	if err := tx.QueryRow(ctx, `
		SELECT current_value::text, reading_date FROM meter_readings
		WHERE meter_id = $1 ORDER BY reading_date DESC, created_at DESC LIMIT 1`,
		in.MeterID).Scan(&lastStr, &lastDate); err != nil && err != pgx.ErrNoRows {
		return nil, err
	}
	if lastStr != nil {
		if lastValue, err = decimal.NewFromString(*lastStr); err != nil {
			return nil, err
		}
	}

	if lastDate != nil && !readingDate.After(*lastDate) {
		if readingDate.Format("2006-01-02") == lastDate.Format("2006-01-02") {
			return nil, ErrDuplicateRead
		}
		return nil, ErrChainBroken
	}

	previous := lastValue
	if current.LessThan(previous) {
		// Sayaç geriye dönmüş: ya yanlış okuma ya da sayaç değişimi.
		if !in.MeterReplaced || strings.TrimSpace(in.Reason) == "" {
			return nil, ErrBackwards
		}
		// Sayaç değiştiyse yeni sayaç sıfırdan başlar; eski endeksle
		// karşılaştırma yapılmaz.
		previous = decimal.Zero
	}

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO meter_readings
			(meter_id, reading_date, previous_value, current_value, reading_type, reader_user_id)
		VALUES ($1,$2,$3,$4,$5,NULLIF($6,'')::uuid)
		RETURNING id`,
		in.MeterID, readingDate, previous.String(), current.String(), rType, userID).Scan(&id); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &Reading{
		ID: id, MeterID: in.MeterID, SerialNumber: serial, UnitName: unitName,
		ReadingDate: readingDate, PreviousValue: previous.String(),
		CurrentValue: current.String(), Consumption: current.Sub(previous).String(),
		ReadingType: rType,
	}, nil
}

// Readings, okuma geçmişini döner.
func (r *Repository) Readings(ctx context.Context, propertyID, meterID string, from, to *time.Time) ([]Reading, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT r.id, r.meter_id, m.serial_number,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       r.reading_date, r.previous_value::text, r.current_value::text,
		       r.consumption::text, COALESCE(r.reading_type,'MANUAL'),
		       COALESCE(us.first_name || ' ' || us.last_name,''), r.created_at
		FROM meter_readings r
		JOIN meters m ON m.id = r.meter_id
		JOIN units u ON u.id = m.unit_id
		LEFT JOIN users us ON us.id = r.reader_user_id
		WHERE u.property_id = $1
		  AND ($2 = '' OR r.meter_id = NULLIF($2,'')::uuid)
		  AND ($3::date IS NULL OR r.reading_date >= $3::date)
		  AND ($4::date IS NULL OR r.reading_date <= $4::date)
		ORDER BY r.reading_date DESC, r.created_at DESC
		LIMIT 1001`, propertyID, meterID, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Reading{}
	for rows.Next() {
		var rd Reading
		if err := rows.Scan(&rd.ID, &rd.MeterID, &rd.SerialNumber, &rd.UnitName,
			&rd.ReadingDate, &rd.PreviousValue, &rd.CurrentValue, &rd.Consumption,
			&rd.ReadingType, &rd.ReaderName, &rd.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, rd)
	}
	return out, rows.Err()
}

// UnitConsumption, bir bağımsız bölümün dönem tüketimi ve kullanım alanıdır.
type UnitConsumption struct {
	UnitID      string          `json:"unit_id"`
	UnitName    string          `json:"unit_name"`
	Consumption decimal.Decimal `json:"-"`
	UsableArea  decimal.Decimal `json:"-"`
	// Estimated true ise dönemde en az bir tahmini okuma vardır.
	Estimated bool `json:"estimated"`
	// HasReading false ise bölümde hiç okuma yoktur.
	HasReading bool `json:"has_reading"`
}

// PeriodConsumption, verilen dönemde her bağımsız bölümün tüketimini ve
// KULLANIM ALANINI döner.
//
// Kullanım alanı için `net_area_m2` kullanılır. Merkezi ısıtma yönetmeliğinde
// (RG 14.04.2008) sabit pay "kullanım alanı" üzerinden dağıtılır; brüt alan
// kullanmak, ortak alan paylarını da hesaba katarak dağıtımı bozar.
//
// İkinci dönüş değeri, alanı tanımsız bölüm bulunup bulunmadığını söyler.
// Bunu HATA yapıp yapmamak çağıranın kararıdır: ısıtmada sabit pay alana göre
// dağıtıldığı için alan zorunludur (eksik alanı sıfır saymak o bölümü paydan
// muaf tutup diğerlerine yüklerdi); su/elektrik/gazda alan hiç kullanılmaz.
func (r *Repository) PeriodConsumption(ctx context.Context, propertyID, meterType string, from, to time.Time) ([]UnitConsumption, bool, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT u.id::text,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       COALESCE(SUM(r.consumption) FILTER (WHERE r.id IS NOT NULL), 0)::text,
		       COALESCE(u.net_area_m2, 0)::text,
		       (u.net_area_m2 IS NULL),
		       COALESCE(bool_or(r.reading_type = 'ESTIMATED'), false),
		       COALESCE(bool_or(r.id IS NOT NULL), false)
		FROM units u
		JOIN meters m ON m.unit_id = u.id AND m.meter_type = $2 AND COALESCE(m.is_active,true)
		LEFT JOIN meter_readings r ON r.meter_id = m.id
		     AND r.reading_date >= $3::date AND r.reading_date <= $4::date
		WHERE u.property_id = $1
		GROUP BY u.id, u.block, u.door_number, u.net_area_m2
		ORDER BY u.block, u.door_number`,
		propertyID, strings.ToUpper(meterType), from, to)
	if err != nil {
		return nil, false, err
	}
	defer rows.Close()

	out := []UnitConsumption{}
	missingArea := false
	for rows.Next() {
		var uc UnitConsumption
		var consStr, areaStr string
		var areaNull bool
		if err := rows.Scan(&uc.UnitID, &uc.UnitName, &consStr, &areaStr,
			&areaNull, &uc.Estimated, &uc.HasReading); err != nil {
			return nil, false, err
		}
		if uc.Consumption, err = decimal.NewFromString(consStr); err != nil {
			return nil, false, err
		}
		if uc.UsableArea, err = decimal.NewFromString(areaStr); err != nil {
			return nil, false, err
		}
		if areaNull || uc.UsableArea.LessThanOrEqual(decimal.Zero) {
			missingArea = true
		}
		out = append(out, uc)
	}
	if err := rows.Err(); err != nil {
		return nil, false, err
	}
	if len(out) == 0 {
		return nil, false, ErrNoReadings
	}
	return out, missingArea, nil
}

// DeactivateMeter, sayacı pasife alır. Okumalar silinmez.
func (r *Repository) DeactivateMeter(ctx context.Context, propertyID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE meters SET is_active = false
		WHERE id = $1 AND COALESCE(is_active,true) = true
		  AND unit_id IN (SELECT id FROM units WHERE property_id = $2)`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
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
		return "", ErrNotFound
	}
	return unitID, err
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `meters` ve `meter_readings` tablolarında RLS açıktır (migration 024).
// Sayaçlar dört servis tarafından okunur (iot, energy_analytics, esg, finance);
// dördü de kapsamlı sorguya geçmeden açılamazdı.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
