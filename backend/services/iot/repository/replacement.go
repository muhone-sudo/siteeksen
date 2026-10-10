package repository

// Sayaç değişim protokolü ve yayımlanmış tüketim pusulaları (migration 056, Apsiyon BUG-07).

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/shopspring/decimal"
)

var (
	// ErrRemovalBelowLast: söküm endeksi son okumadan küçük olamaz.
	ErrRemovalBelowLast = errors.New("söküm endeksi sayacın son okumasından küçük olamaz")
	// ErrAllocationPublished: aynı dönem ve tür için paylaştırma zaten yayımlanmış.
	ErrAllocationPublished = errors.New("bu dönem için paylaştırma zaten yayımlanmış")
	// ErrUseReplace: okuma ucunda "sayaç değişti" bildirimi; değişim protokolü kullanılmalı.
	ErrUseReplace = errors.New("sayaç değişimi okuma ucundan bildirilemez")
)

// ReplaceInput, sayaç değişim girdisidir.
type ReplaceInput struct {
	RemovalValue    string `json:"removal_value"`
	ReplacedOn      string `json:"replaced_on"`
	NewSerial       string `json:"new_serial_number"`
	NewInitialValue string `json:"new_initial_value"`
	Reason          string `json:"reason"`
}

// ReplaceMeter: eski sayaca söküm okuması yazılır ve pasife alınır; aynı bölüm/türde yeni
// sayaç montaj endeksiyle açılır (tüketimsiz başlangıç okuması). Dönem tüketimi iki sayaçtan toplanır.
func (r *Repository) ReplaceMeter(ctx context.Context, propertyID, userID, meterID string, in ReplaceInput) (string, error) {
	removal, err1 := decimal.NewFromString(strings.ReplaceAll(strings.TrimSpace(in.RemovalValue), ",", "."))
	initial, err2 := decimal.NewFromString(strings.ReplaceAll(strings.TrimSpace(in.NewInitialValue), ",", "."))
	if err1 != nil || err2 != nil || removal.IsNegative() || initial.IsNegative() {
		return "", ErrInvalidValue
	}
	day, err := time.Parse("2006-01-02", strings.TrimSpace(in.ReplacedOn))
	if err != nil || day.After(time.Now()) {
		return "", ErrInvalidType
	}
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var unitID, meterType string
	var brand, model *string
	err = tx.QueryRow(ctx, `
		SELECT m.unit_id::text, m.meter_type, m.brand, m.model FROM meters m JOIN units u ON u.id = m.unit_id
		WHERE m.id = $1 AND u.property_id = $2 AND COALESCE(m.is_active, true)
		FOR UPDATE OF m`, meterID, propertyID).Scan(&unitID, &meterType, &brand, &model)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", err
	}
	var lastStr *string
	var lastDate *time.Time
	if err := tx.QueryRow(ctx, `SELECT current_value::text, reading_date FROM meter_readings WHERE meter_id = $1
		ORDER BY reading_date DESC, created_at DESC LIMIT 1`, meterID).Scan(&lastStr, &lastDate); err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return "", err
	}
	last := decimal.Zero
	if lastStr != nil {
		last, _ = decimal.NewFromString(*lastStr)
	}
	if removal.LessThan(last) {
		return "", ErrRemovalBelowLast
	}
	if lastDate != nil && !day.After(*lastDate) {
		return "", ErrChainBroken
	}
	// Eski sayacın söküm okuması (son okumadan söküme kadarki tüketim kaybolmaz).
	if _, err := tx.Exec(ctx, `INSERT INTO meter_readings (meter_id, reading_date, previous_value, current_value, reading_type, reader_user_id)
		VALUES ($1, $2, $3, $4, 'MANUAL', NULLIF($5,'')::uuid)`, meterID, day, last.String(), removal.String(), userID); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `UPDATE meters SET is_active = false WHERE id = $1`, meterID); err != nil {
		return "", err
	}
	var newID string
	err = tx.QueryRow(ctx, `INSERT INTO meters (unit_id, meter_type, serial_number, brand, model, installation_date, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, true) RETURNING id`, unitID, meterType, strings.TrimSpace(in.NewSerial), brand, model, day).Scan(&newID)
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		return "", ErrDuplicateSerial
	}
	if err != nil {
		return "", err
	}
	// Yeni sayacın montaj endeksi: tüketimsiz başlangıç okuması (zincir buradan devam eder).
	if _, err := tx.Exec(ctx, `INSERT INTO meter_readings (meter_id, reading_date, previous_value, current_value, reading_type, reader_user_id)
		VALUES ($1, $2, $3, $3, 'MANUAL', NULLIF($4,'')::uuid)`, newID, day, initial.String(), userID); err != nil {
		return "", err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO meter_replacements (property_id, unit_id, old_meter_id, new_meter_id, replaced_on,
		removal_value, initial_value, reason, created_by) VALUES ($1,$2,$3,$4,$5,$6::numeric,$7::numeric,$8,NULLIF($9,'')::uuid)`,
		propertyID, unitID, meterID, newID, day, removal.String(), initial.String(), strings.TrimSpace(in.Reason), userID); err != nil {
		return "", err
	}
	return newID, tx.Commit(ctx)
}

// StatementLine, yayımlanmış paylaştırmada bir bölümün pusulasıdır.
type StatementLine struct {
	UnitID           string     `json:"unit_id"`
	UnitName         string     `json:"unit_name"`
	FirstDate        *time.Time `json:"first_date,omitempty"`
	FirstValue       *string    `json:"first_value,omitempty"`
	LastDate         *time.Time `json:"last_date,omitempty"`
	LastValue        *string    `json:"last_value,omitempty"`
	Replaced         bool       `json:"meter_replaced"`
	Consumption      string     `json:"consumption"`
	UsableArea       *string    `json:"usable_area,omitempty"`
	ConsumptionKurus int64      `json:"consumption_kurus"`
	AreaKurus        int64      `json:"area_kurus"`
	TotalKurus       int64      `json:"total_kurus"`
}

// PublishedAllocation, yayımlanmış paylaştırmadır.
type PublishedAllocation struct {
	ID                  string          `json:"id"`
	MeterType           string          `json:"meter_type"`
	PeriodFrom          time.Time       `json:"period_from"`
	PeriodTo            time.Time       `json:"period_to"`
	TotalKurus          int64           `json:"total_kurus"`
	ConsumptionSharePct *string         `json:"consumption_share_pct,omitempty"`
	AreaSharePct        *string         `json:"area_share_pct,omitempty"`
	BasisNote           string          `json:"basis_note,omitempty"`
	PublishedAt         time.Time       `json:"published_at"`
	Lines               []StatementLine `json:"lines,omitempty"`
	// OutlierUnits: yayımda medyanın 3 katını aşan bölümler (JSON) ve teyit eden (063, B8).
	OutlierUnits        []byte `json:"-"`
	OutliersConfirmedBy string `json:"-"`
}

// PublishAllocation, hesaplanmış paylaştırmayı değiştirilemez biçimde saklar.
func (r *Repository) PublishAllocation(ctx context.Context, propertyID, userID string, a *PublishedAllocation) (string, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id string
	var outliers any
	if len(a.OutlierUnits) > 0 {
		outliers = string(a.OutlierUnits)
	}
	err = tx.QueryRow(ctx, `INSERT INTO consumption_allocations (property_id, meter_type, period_from, period_to, total_kurus,
		consumption_share_pct, area_share_pct, basis_note, published_by, outlier_units, outliers_confirmed_by)
		VALUES ($1,$2,$3,$4,$5,$6::numeric,$7::numeric,$8,NULLIF($9,'')::uuid,$10::jsonb,NULLIF($11,'')::uuid)
		RETURNING id`, propertyID, a.MeterType, a.PeriodFrom, a.PeriodTo, a.TotalKurus, a.ConsumptionSharePct, a.AreaSharePct,
		a.BasisNote, userID, outliers, a.OutliersConfirmedBy).Scan(&id)
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		return "", ErrAllocationPublished
	}
	if err != nil {
		return "", err
	}
	for _, l := range a.Lines {
		if _, err := tx.Exec(ctx, `INSERT INTO consumption_allocation_units (allocation_id, property_id, unit_id, first_date, first_value,
			last_date, last_value, replaced, consumption, usable_area, consumption_kurus, area_kurus, total_kurus)
			VALUES ($1,$2,$3,$4,$5::numeric,$6,$7::numeric,$8,$9::numeric,$10::numeric,$11,$12,$13)`,
			id, propertyID, l.UnitID, l.FirstDate, l.FirstValue, l.LastDate, l.LastValue, l.Replaced, l.Consumption, l.UsableArea,
			l.ConsumptionKurus, l.AreaKurus, l.TotalKurus); err != nil {
			return "", err
		}
	}
	return id, tx.Commit(ctx)
}

// ListAllocations, yayımlanmış paylaştırmaları verir; unitScope doluysa yalnızca o bölümün satırı eklenir.
func (r *Repository) ListAllocations(ctx context.Context, propertyID, unitScope string) ([]PublishedAllocation, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, meter_type, period_from, period_to, total_kurus, consumption_share_pct::text, area_share_pct::text,
		       COALESCE(basis_note, ''), published_at
		FROM consumption_allocations WHERE property_id = $1 ORDER BY period_to DESC, meter_type LIMIT 200`, propertyID)
	if err != nil {
		return nil, err
	}
	out := []PublishedAllocation{}
	for rows.Next() {
		var a PublishedAllocation
		if err := rows.Scan(&a.ID, &a.MeterType, &a.PeriodFrom, &a.PeriodTo, &a.TotalKurus, &a.ConsumptionSharePct,
			&a.AreaSharePct, &a.BasisNote, &a.PublishedAt); err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, a)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if unitScope == "" {
		return out, nil
	}
	mine := []PublishedAllocation{}
	for _, a := range out {
		lines, err := r.AllocationLines(ctx, propertyID, a.ID, unitScope)
		if err != nil {
			return nil, err
		}
		if len(lines) > 0 {
			a.Lines = lines
			mine = append(mine, a)
		}
	}
	return mine, nil
}

// AllocationLines, bir paylaştırmanın pusula satırlarını verir (unitScope doluysa yalnızca o bölüm).
func (r *Repository) AllocationLines(ctx context.Context, propertyID, allocationID, unitScope string) ([]StatementLine, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT l.unit_id::text, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''), l.first_date, trim_scale(l.first_value)::text,
		       l.last_date, trim_scale(l.last_value)::text, l.replaced, trim_scale(l.consumption)::text, trim_scale(l.usable_area)::text,
		       l.consumption_kurus, l.area_kurus, l.total_kurus
		FROM consumption_allocation_units l JOIN units u ON u.id = l.unit_id
		WHERE l.allocation_id = $1 AND l.property_id = $2 AND ($3 = '' OR l.unit_id = NULLIF($3,'')::uuid)
		ORDER BY u.block, u.door_number`, allocationID, propertyID, unitScope)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []StatementLine{}
	for rows.Next() {
		var l StatementLine
		if err := rows.Scan(&l.UnitID, &l.UnitName, &l.FirstDate, &l.FirstValue, &l.LastDate, &l.LastValue, &l.Replaced,
			&l.Consumption, &l.UsableArea, &l.ConsumptionKurus, &l.AreaKurus, &l.TotalKurus); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	return out, rows.Err()
}

// GetAllocation, tek paylaştırmanın başlığını verir.
func (r *Repository) GetAllocation(ctx context.Context, propertyID, id string) (*PublishedAllocation, error) {
	var a PublishedAllocation
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT id, meter_type, period_from, period_to, total_kurus, consumption_share_pct::text, area_share_pct::text,
		       COALESCE(basis_note, ''), published_at
		FROM consumption_allocations WHERE id = $1 AND property_id = $2`, id, propertyID).Scan(&a.ID, &a.MeterType, &a.PeriodFrom,
		&a.PeriodTo, &a.TotalKurus, &a.ConsumptionSharePct, &a.AreaSharePct, &a.BasisNote, &a.PublishedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return &a, err
}
