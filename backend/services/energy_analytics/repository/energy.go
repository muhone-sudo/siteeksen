// Package repository, enerji/tüketim analizi modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrNoData      = errors.New("bu dönemde veri yok")
	ErrInvalidType = errors.New("geçersiz sayaç türü")
)

// MeterTypes, analiz edilebilen sayaç türleridir.
var MeterTypes = []string{"HEAT", "WATER_COLD", "WATER_HOT", "GAS", "ELECTRIC"}

// PeriodTotal, bir dönemin toplam tüketimidir.
type PeriodTotal struct {
	Period       string `json:"period"`
	MeterType    string `json:"meter_type"`
	Total        string `json:"total_consumption"`
	UnitCount    int    `json:"units_with_reading"`
	ReadingCount int    `json:"reading_count"`
}

// UnitUsage, bir bağımsız bölümün dönem tüketimidir.
type UnitUsage struct {
	UnitID      string `json:"unit_id"`
	UnitName    string `json:"unit_name"`
	Consumption string `json:"consumption"`
	UsableArea  string `json:"usable_area,omitempty"`
	// PerSquareMeter, alan başına tüketimdir; farklı büyüklükteki bölümleri
	// karşılaştırmanın tek dürüst yoludur.
	PerSquareMeter string `json:"per_square_meter,omitempty"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// MonthlyTotals, son N ayın toplam tüketimini döner.
//
// Toplam, OKUMALARDAN hesaplanır; `energy_analytics` tablosundaki saklanmış
// özetlerden değil. Saklanan özet, arada yeni okuma girildiğinde bayatlar.
func (r *Repository) MonthlyTotals(ctx context.Context, propertyID, meterType string, months int) ([]PeriodTotal, error) {
	mt := strings.ToUpper(strings.TrimSpace(meterType))
	if !contains(MeterTypes, mt) {
		return nil, ErrInvalidType
	}
	if months <= 0 || months > 36 {
		months = 12
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT to_char(date_trunc('month', r.reading_date), 'YYYY-MM') AS period,
		       COALESCE(SUM(r.consumption),0)::text,
		       count(DISTINCT m.unit_id)::int,
		       count(*)::int
		FROM meter_readings r
		JOIN meters m ON m.id = r.meter_id
		JOIN units u ON u.id = m.unit_id
		WHERE u.property_id = $1 AND m.meter_type = $2
		  AND r.reading_date >= date_trunc('month', CURRENT_DATE) - make_interval(months => $3)
		GROUP BY date_trunc('month', r.reading_date)
		ORDER BY date_trunc('month', r.reading_date)`, propertyID, mt, months)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []PeriodTotal{}
	for rows.Next() {
		var p PeriodTotal
		p.MeterType = mt
		if err := rows.Scan(&p.Period, &p.Total, &p.UnitCount, &p.ReadingCount); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// UnitUsages, bir dönemdeki bağımsız bölüm tüketimlerini döner.
func (r *Repository) UnitUsages(ctx context.Context, propertyID, meterType string, from, to time.Time) ([]UnitUsage, error) {
	mt := strings.ToUpper(strings.TrimSpace(meterType))
	if !contains(MeterTypes, mt) {
		return nil, ErrInvalidType
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT u.id::text,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       COALESCE(SUM(r.consumption),0)::text,
		       COALESCE(u.net_area_m2,0)::text
		FROM units u
		JOIN meters m ON m.unit_id = u.id AND m.meter_type = $2
		LEFT JOIN meter_readings r ON r.meter_id = m.id
		     AND r.reading_date >= $3::date AND r.reading_date <= $4::date
		WHERE u.property_id = $1
		GROUP BY u.id, u.block, u.door_number, u.net_area_m2
		ORDER BY u.block, u.door_number`, propertyID, mt, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []UnitUsage{}
	for rows.Next() {
		var uu UnitUsage
		var areaStr string
		if err := rows.Scan(&uu.UnitID, &uu.UnitName, &uu.Consumption, &areaStr); err != nil {
			return nil, err
		}
		area, err := decimal.NewFromString(areaStr)
		if err != nil {
			area = decimal.Zero
		}
		cons, err := decimal.NewFromString(uu.Consumption)
		if err != nil {
			cons = decimal.Zero
		}
		if area.GreaterThan(decimal.Zero) {
			uu.UsableArea = area.String()
			uu.PerSquareMeter = cons.Div(area).Round(4).String()
		}
		out = append(out, uu)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return nil, ErrNoData
	}
	return out, nil
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
// Okunan `meters` ve `meter_readings` tablolarında RLS açıktır (migration 024).
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
