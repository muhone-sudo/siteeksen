package repository

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrUnknownKey  = errors.New("tanınmayan ayar anahtarı")
	ErrLegalKey    = errors.New("mevzuat parametresi site ayarı olarak değiştirilemez")
	ErrInvalidType = errors.New("değer türü ayarın tanımıyla uyuşmuyor")
	ErrOutOfRange  = errors.New("değer izin verilen aralığın dışında")
)

// Setting, bir ayarın geçerli değeridir.
type Setting struct {
	Key         string     `json:"key"`
	Type        string     `json:"type"`
	Description string     `json:"description"`
	Value       any        `json:"value"`
	IsDefault   bool       `json:"is_default"`
	UpdatedBy   string     `json:"updated_by_name,omitempty"`
	UpdatedAt   *time.Time `json:"updated_at,omitempty"`
}

// HistoryEntry, bir ayar değişikliğidir.
type HistoryEntry struct {
	Key       string    `json:"key"`
	OldValue  string    `json:"old_value,omitempty"`
	NewValue  string    `json:"new_value"`
	ChangedBy string    `json:"changed_by_name,omitempty"`
	ChangedAt time.Time `json:"changed_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// List, TÜM tanınan ayarları döner — kaydedilmemiş olanlar varsayılan değeriyle.
//
// Yalnızca kaydedilmiş olanları döndürmek, istemciyi "ayar yok" ile "ayar
// varsayılanda" arasında ayrım yapamaz hâle getirir ve her istemci kendi
// varsayılanını uydurur.
func (r *Repository) List(ctx context.Context, propertyID string) ([]Setting, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT s.setting_key, s.value_type, s.value_text, s.value_int, s.value_bool,
		       COALESCE(u.first_name || ' ' || u.last_name,''), s.updated_at
		FROM property_settings s
		LEFT JOIN users u ON u.id = s.updated_by
		WHERE s.property_id = $1`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	type stored struct {
		value     any
		updatedBy string
		updatedAt time.Time
	}
	saved := map[string]stored{}
	for rows.Next() {
		var key, vtype, updatedBy string
		var vtext *string
		var vint *int
		var vbool *bool
		var updatedAt time.Time
		if err := rows.Scan(&key, &vtype, &vtext, &vint, &vbool, &updatedBy, &updatedAt); err != nil {
			return nil, err
		}
		var v any
		switch vtype {
		case TypeText:
			if vtext != nil {
				v = *vtext
			}
		case TypeInt:
			if vint != nil {
				v = *vint
			}
		case TypeBool:
			if vbool != nil {
				v = *vbool
			}
		}
		saved[key] = stored{value: v, updatedBy: updatedBy, updatedAt: updatedAt}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]Setting, 0, len(Definitions))
	for _, d := range Definitions {
		s := Setting{Key: d.Key, Type: d.Type, Description: d.Description,
			Value: d.Default, IsDefault: true}
		if st, ok := saved[d.Key]; ok && st.value != nil {
			s.Value = st.value
			s.IsDefault = false
			s.UpdatedBy = st.updatedBy
			at := st.updatedAt
			s.UpdatedAt = &at
		}
		out = append(out, s)
	}
	return out, nil
}

// Set, ayarı kaydeder ve değişikliği geçmişe yazar.
//
// Doğrulama sırası bilinçlidir: önce mevzuat alanı mı diye bakılır, sonra
// anahtar tanınıyor mu, sonra tür ve aralık. Böylece kullanıcı en anlamlı
// hatayı alır.
func (r *Repository) Set(ctx context.Context, propertyID, userID, key string, raw any) (*Setting, error) {
	k := strings.ToUpper(strings.TrimSpace(key))
	if IsLegalKey(k) {
		return nil, ErrLegalKey
	}
	def, ok := Lookup(k)
	if !ok {
		return nil, ErrUnknownKey
	}

	var vtext *string
	var vint *int
	var vbool *bool
	var display string

	switch def.Type {
	case TypeText:
		s, err := toString(raw)
		if err != nil {
			return nil, ErrInvalidType
		}
		vtext = &s
		display = s
	case TypeInt:
		n, err := toInt(raw)
		if err != nil {
			return nil, ErrInvalidType
		}
		if def.Max > 0 && (n < def.Min || n > def.Max) {
			return nil, fmt.Errorf("%w: %s için izin verilen aralık %d-%d",
				ErrOutOfRange, def.Key, def.Min, def.Max)
		}
		vint = &n
		display = strconv.Itoa(n)
	case TypeBool:
		b, err := toBool(raw)
		if err != nil {
			return nil, ErrInvalidType
		}
		vbool = &b
		display = strconv.FormatBool(b)
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Eski değeri geçmiş için al.
	var oldValue *string
	if err := tx.QueryRow(ctx, `
		SELECT COALESCE(value_text, value_int::text, value_bool::text)
		FROM property_settings WHERE property_id = $1 AND setting_key = $2`,
		propertyID, k).Scan(&oldValue); err != nil && err.Error() != "no rows in result set" {
		return nil, err
	}

	var updatedAt time.Time
	if err := tx.QueryRow(ctx, `
		INSERT INTO property_settings
			(property_id, setting_key, value_text, value_int, value_bool, value_type, updated_by)
		VALUES ($1,$2,$3,$4,$5,$6,NULLIF($7,'')::uuid)
		ON CONFLICT (property_id, setting_key) DO UPDATE
		SET value_text = EXCLUDED.value_text,
		    value_int = EXCLUDED.value_int,
		    value_bool = EXCLUDED.value_bool,
		    value_type = EXCLUDED.value_type,
		    updated_by = EXCLUDED.updated_by,
		    updated_at = now()
		RETURNING updated_at`,
		propertyID, k, vtext, vint, vbool, def.Type, userID).Scan(&updatedAt); err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO property_setting_history
			(property_id, setting_key, old_value, new_value, changed_by)
		VALUES ($1,$2,$3,$4,NULLIF($5,'')::uuid)`,
		propertyID, k, oldValue, display, userID); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	s := &Setting{Key: def.Key, Type: def.Type, Description: def.Description, IsDefault: false}
	switch def.Type {
	case TypeText:
		s.Value = *vtext
	case TypeInt:
		s.Value = *vint
	case TypeBool:
		s.Value = *vbool
	}
	at := updatedAt
	s.UpdatedAt = &at
	return s, nil
}

// Reset, ayarı varsayılanına döndürür (kayıt silinir, geçmiş korunur).
func (r *Repository) Reset(ctx context.Context, propertyID, userID, key string) error {
	k := strings.ToUpper(strings.TrimSpace(key))
	def, ok := Lookup(k)
	if !ok {
		return ErrUnknownKey
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var oldValue *string
	_ = tx.QueryRow(ctx, `
		SELECT COALESCE(value_text, value_int::text, value_bool::text)
		FROM property_settings WHERE property_id = $1 AND setting_key = $2`,
		propertyID, k).Scan(&oldValue)

	if _, err := tx.Exec(ctx,
		`DELETE FROM property_settings WHERE property_id = $1 AND setting_key = $2`,
		propertyID, k); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO property_setting_history
			(property_id, setting_key, old_value, new_value, changed_by)
		VALUES ($1,$2,$3,$4,NULLIF($5,'')::uuid)`,
		propertyID, k, oldValue, fmt.Sprintf("(varsayılan: %v)", def.Default), userID); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// History, ayar değişiklik geçmişini döner.
func (r *Repository) History(ctx context.Context, propertyID, key string, limit int) ([]HistoryEntry, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT h.setting_key, COALESCE(h.old_value,''), h.new_value,
		       COALESCE(u.first_name || ' ' || u.last_name,''), h.changed_at
		FROM property_setting_history h
		LEFT JOIN users u ON u.id = h.changed_by
		WHERE h.property_id = $1 AND ($2 = '' OR h.setting_key = $2)
		ORDER BY h.changed_at DESC
		LIMIT $3`, propertyID, strings.ToUpper(strings.TrimSpace(key)), limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []HistoryEntry{}
	for rows.Next() {
		var e HistoryEntry
		if err := rows.Scan(&e.Key, &e.OldValue, &e.NewValue, &e.ChangedBy, &e.ChangedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

func toString(v any) (string, error) {
	switch x := v.(type) {
	case string:
		return strings.TrimSpace(x), nil
	default:
		return "", ErrInvalidType
	}
}

// toInt, JSON'dan gelen sayıyı çevirir. JSON sayıları float64 olarak gelir;
// ondalıklı bir değer tam sayı ayarına yazılamaz (5.5. gün diye bir şey yoktur).
func toInt(v any) (int, error) {
	switch x := v.(type) {
	case float64:
		if x != float64(int(x)) {
			return 0, ErrInvalidType
		}
		return int(x), nil
	case int:
		return x, nil
	case string:
		n, err := strconv.Atoi(strings.TrimSpace(x))
		if err != nil {
			return 0, ErrInvalidType
		}
		return n, nil
	default:
		return 0, ErrInvalidType
	}
}

func toBool(v any) (bool, error) {
	switch x := v.(type) {
	case bool:
		return x, nil
	case string:
		b, err := strconv.ParseBool(strings.TrimSpace(x))
		if err != nil {
			return false, ErrInvalidType
		}
		return b, nil
	default:
		return false, ErrInvalidType
	}
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `property_settings` ve `property_setting_history` tablolarında RLS açıktır
// (migration 024).
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
