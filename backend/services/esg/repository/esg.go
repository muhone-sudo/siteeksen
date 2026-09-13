// Package repository, ESG (karbon ayak izi) modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNoData, dönemde okuma yoksa döner.
var ErrNoData = errors.New("bu dönemde sayaç okuması yok")

// TypeTotal, bir sayaç türünün dönem toplamıdır.
type TypeTotal struct {
	MeterType    string `json:"meter_type"`
	Total        string `json:"total_consumption"`
	MeterCount   int    `json:"meter_count"`
	ReadingCount int    `json:"reading_count"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// ConsumptionByType, dönemdeki tüketimi sayaç türüne göre toplar.
//
// Toplam, meter_readings'teki `consumption` üretilmiş kolonundan gelir
// (current_value − previous_value). Bu kolon veritabanı tarafından hesaplandığı
// için uygulama katmanında yeniden hesaplanmaz; iki yerde hesaplamak iki farklı
// sonuç riskidir.
func (r *Repository) ConsumptionByType(ctx context.Context, propertyID string, from, to time.Time) ([]TypeTotal, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT m.meter_type,
		       COALESCE(SUM(r.consumption),0)::text,
		       count(DISTINCT m.id)::int,
		       count(r.id)::int
		FROM meters m
		JOIN units u ON u.id = m.unit_id
		LEFT JOIN meter_readings r ON r.meter_id = m.id
		     AND r.reading_date >= $2::date AND r.reading_date <= $3::date
		WHERE u.property_id = $1
		GROUP BY m.meter_type
		HAVING count(r.id) > 0
		ORDER BY m.meter_type`, propertyID, from, to)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []TypeTotal{}
	for rows.Next() {
		var t TypeTotal
		if err := rows.Scan(&t.MeterType, &t.Total, &t.MeterCount, &t.ReadingCount); err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return nil, ErrNoData
	}
	return out, nil
}
