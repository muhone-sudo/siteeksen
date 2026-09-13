// Package repository, stok (sarf malzeme) modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
)

var (
	ErrNotFound        = errors.New("stok kalemi bulunamadı")
	ErrInvalidCategory = errors.New("kategori bu siteye ait değil")
	ErrInvalidUnit     = errors.New("geçersiz birim")
	ErrInvalidQuantity = errors.New("miktar sıfırdan büyük olmalıdır")
	ErrInsufficient    = errors.New("stok yetersiz")
	ErrInactive        = errors.New("stok kalemi pasif")
	ErrReasonRequired  = errors.New("sayım düzeltmesi için gerekçe zorunludur")
)

// Units, kabul edilen ölçü birimleridir. Serbest metin bırakılırsa aynı malzeme
// "ADET" ve "adet" olarak iki kez tutulur ve stok raporu anlamını yitirir.
var Units = []string{"ADET", "KG", "LT", "METRE", "M2", "M3", "PAKET", "KUTU"}

// MovementTypes, şemadaki CHECK kısıtıyla birebir aynıdır.
var MovementTypes = []string{"IN", "OUT", "ADJUST"}

// ReferenceTypes, hareketin dayanağıdır.
var ReferenceTypes = []string{"PURCHASE", "USAGE", "ADJUSTMENT", "RETURN", "WASTE"}

// Item, bir stok kalemidir.
type Item struct {
	ID           string `json:"id"`
	CategoryID   string `json:"category_id,omitempty"`
	CategoryName string `json:"category_name,omitempty"`
	Name         string `json:"name"`
	Description  string `json:"description,omitempty"`
	SKU          string `json:"sku,omitempty"`
	Unit         string `json:"unit"`

	CurrentStock string `json:"current_stock"`
	MinimumStock string `json:"minimum_stock"`
	ReorderPoint string `json:"reorder_point,omitempty"`

	// UnitPrice, ağırlıklı ortalama birim maliyettir (hareketlerden hesaplanıp saklanır).
	UnitPrice         *float64 `json:"unit_price,omitempty"`
	LastPurchasePrice *float64 `json:"last_purchase_price,omitempty"`
	// StockValue, mevcut stoğun ağırlıklı ortalama maliyetle değeridir.
	StockValue *float64 `json:"stock_value,omitempty"`

	Warehouse string `json:"warehouse,omitempty"`
	Location  string `json:"location,omitempty"`
	IsActive  bool   `json:"is_active"`

	// BelowMinimum true ise stok asgari seviyenin altındadır.
	BelowMinimum bool      `json:"below_minimum"`
	Notes        string    `json:"notes,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

// Movement, bir stok hareketidir.
type Movement struct {
	ID              string    `json:"id"`
	ItemID          string    `json:"item_id"`
	ItemName        string    `json:"item_name,omitempty"`
	Unit            string    `json:"unit,omitempty"`
	MovementType    string    `json:"movement_type"`
	Quantity        string    `json:"quantity"`
	PreviousStock   string    `json:"previous_stock"`
	NewStock        string    `json:"new_stock"`
	UnitPrice       *float64  `json:"unit_price,omitempty"`
	TotalPrice      *float64  `json:"total_price,omitempty"`
	ReferenceType   string    `json:"reference_type,omitempty"`
	ReferenceNumber string    `json:"reference_number,omitempty"`
	Vendor          string    `json:"vendor,omitempty"`
	Notes           string    `json:"notes,omitempty"`
	CreatedByName   string    `json:"created_by_name,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// Category, stok kategorisidir.
type Category struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	ItemCount int    `json:"item_count"`
}

// ListCategories, siteye ait ve global kategorileri döner.
func (r *Repository) ListCategories(ctx context.Context, propertyID string) ([]Category, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT c.id, c.name,
		       (SELECT count(*) FROM inventory_items i
		         WHERE i.category_id = c.id AND i.property_id = $1)
		FROM inventory_categories c
		WHERE c.property_id = $1 OR c.property_id IS NULL
		ORDER BY c.name`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Category{}
	for rows.Next() {
		var c Category
		if err := rows.Scan(&c.ID, &c.Name, &c.ItemCount); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// CreateCategory, siteye özel kategori ekler.
func (r *Repository) CreateCategory(ctx context.Context, propertyID, name, description string) (string, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO inventory_categories (property_id, name, description)
		VALUES ($1,$2,NULLIF($3,'')) RETURNING id`, propertyID, name, description).Scan(&id)
	return id, err
}

const itemSelect = `
SELECT i.id, COALESCE(i.category_id::text,''), COALESCE(c.name,''),
       i.name, COALESCE(i.description,''), COALESCE(i.sku,''), i.unit,
       COALESCE(i.current_stock,0)::text, COALESCE(i.minimum_stock,0)::text,
       COALESCE(i.reorder_point,0)::text,
       i.unit_price::float8, i.last_purchase_price::float8,
       (COALESCE(i.current_stock,0) * COALESCE(i.unit_price,0))::float8,
       COALESCE(i.warehouse,''), COALESCE(i.location,''), COALESCE(i.is_active,true),
       (COALESCE(i.current_stock,0) <= COALESCE(i.minimum_stock,0)),
       COALESCE(i.notes,''), i.created_at
FROM inventory_items i
LEFT JOIN inventory_categories c ON c.id = i.category_id`

func scanItem(row pgx.Row) (*Item, error) {
	var it Item
	var value float64
	err := row.Scan(&it.ID, &it.CategoryID, &it.CategoryName, &it.Name, &it.Description,
		&it.SKU, &it.Unit, &it.CurrentStock, &it.MinimumStock, &it.ReorderPoint,
		&it.UnitPrice, &it.LastPurchasePrice, &value,
		&it.Warehouse, &it.Location, &it.IsActive, &it.BelowMinimum,
		&it.Notes, &it.CreatedAt)
	if err != nil {
		return nil, err
	}
	if it.UnitPrice != nil {
		it.StockValue = &value
	}
	return &it, nil
}

// ListFilter, stok listeleme ölçütleridir.
type ListFilter struct {
	CategoryID      string
	Search          string
	BelowMinimum    bool
	IncludeInactive bool
}

// List, stok kalemlerini getirir.
func (r *Repository) List(ctx context.Context, propertyID string, f ListFilter) ([]Item, error) {
	rows, err := r.pool.Query(ctx, itemSelect+`
		WHERE i.property_id = $1
		  AND ($2 = '' OR i.category_id = NULLIF($2,'')::uuid)
		  AND ($3 = '' OR i.name ILIKE '%' || $3 || '%' OR i.sku ILIKE '%' || $3 || '%')
		  AND ($4 = false OR COALESCE(i.current_stock,0) <= COALESCE(i.minimum_stock,0))
		  AND ($5 OR i.is_active = true)
		ORDER BY i.name
		LIMIT 1000`,
		propertyID, f.CategoryID, f.Search, f.BelowMinimum, f.IncludeInactive)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Item{}
	for rows.Next() {
		it, err := scanItem(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *it)
	}
	return out, rows.Err()
}

// Get, tek stok kalemini getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id string) (*Item, error) {
	it, err := scanItem(r.pool.QueryRow(ctx,
		itemSelect+` WHERE i.property_id = $1 AND i.id = $2`, propertyID, id))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return it, err
}

// CreateItemInput, yeni stok kalemi girdisidir.
type CreateItemInput struct {
	CategoryID   string `json:"category_id"`
	Name         string `json:"name" binding:"required"`
	Description  string `json:"description"`
	SKU          string `json:"sku"`
	Unit         string `json:"unit" binding:"required"`
	MinimumStock string `json:"minimum_stock"`
	ReorderPoint string `json:"reorder_point"`
	Warehouse    string `json:"warehouse"`
	Location     string `json:"location"`
	Notes        string `json:"notes"`
}

// CreateItem, stok kalemini AÇILIŞ STOĞU SIFIR olarak oluşturur.
//
// Açılış stoğu doğrudan yazılmaz: her miktar değişikliği bir HAREKET kaydı
// üretmek zorundadır. Aksi hâlde stoğun nereden geldiği kaydın hiçbir yerinde
// görünmez ve sayım farkı araştırılamaz. Açılış için `ADJUST` hareketi kullanılır.
func (r *Repository) CreateItem(ctx context.Context, propertyID string, in CreateItemInput) (string, error) {
	unit := strings.ToUpper(strings.TrimSpace(in.Unit))
	if !contains(Units, unit) {
		return "", ErrInvalidUnit
	}
	if in.CategoryID != "" {
		var ok bool
		if err := r.pool.QueryRow(ctx, `
			SELECT EXISTS(SELECT 1 FROM inventory_categories
			              WHERE id = $1 AND (property_id = $2 OR property_id IS NULL))`,
			in.CategoryID, propertyID).Scan(&ok); err != nil {
			return "", err
		}
		if !ok {
			return "", ErrInvalidCategory
		}
	}

	minStock, err := parseQuantity(in.MinimumStock, true)
	if err != nil {
		return "", err
	}
	reorder, err := parseQuantity(in.ReorderPoint, true)
	if err != nil {
		return "", err
	}

	var id string
	err = r.pool.QueryRow(ctx, `
		INSERT INTO inventory_items
			(property_id, category_id, name, description, sku, unit,
			 current_stock, minimum_stock, reorder_point, warehouse, location, notes, is_active)
		VALUES ($1,NULLIF($2,'')::uuid,$3,NULLIF($4,''),NULLIF($5,''),$6,
		        0,$7,$8,NULLIF($9,''),NULLIF($10,''),NULLIF($11,''),true)
		RETURNING id`,
		propertyID, in.CategoryID, in.Name, in.Description, in.SKU, unit,
		minStock, reorder, in.Warehouse, in.Location, in.Notes).Scan(&id)
	return id, err
}

// MovementInput, stok hareketi girdisidir.
type MovementInput struct {
	MovementType    string   `json:"movement_type" binding:"required"`
	Quantity        string   `json:"quantity" binding:"required"`
	UnitPrice       *float64 `json:"unit_price"`
	ReferenceType   string   `json:"reference_type"`
	ReferenceNumber string   `json:"reference_number"`
	Vendor          string   `json:"vendor"`
	Notes           string   `json:"notes"`
}

// MovementResult, hareket sonrası durumu bildirir.
type MovementResult struct {
	MovementID    string   `json:"movement_id"`
	PreviousStock string   `json:"previous_stock"`
	NewStock      string   `json:"new_stock"`
	UnitPrice     *float64 `json:"unit_price,omitempty"`
	BelowMinimum  bool     `json:"below_minimum"`
}

// RecordMovement, stok hareketini kaydeder ve stoğu AYNI TRANSACTION içinde,
// kalem satırı KİLİTLENEREK günceller.
//
// Neden kilit: iki görevli aynı anda 8 birer birim çıkış yaparsa, ikisi de
// stoğu 10 okur, ikisi de 2 yazar ve depoda olmayan 6 birim kayıtta durur.
// `FOR UPDATE` ile ikinci istek birincinin yazdığı değeri okur.
//
// Neden negatif stok yasak: olmayan malzemenin çıkışı kaydedilirse stok raporu
// hiçbir zaman gerçeğe dönmez; eksik varsa ADJUST (sayım düzeltmesi) kullanılır
// ve gerekçesi kayda geçer.
//
// Giriş hareketinde birim maliyet AĞIRLIKLI ORTALAMA ile güncellenir: son alış
// fiyatını maliyet saymak, elde kalan eski stoğu da yeni fiyattan değerler ve
// stok değerini şişirir.
func (r *Repository) RecordMovement(ctx context.Context, propertyID, itemID, userID string, in MovementInput) (*MovementResult, error) {
	mType := strings.ToUpper(strings.TrimSpace(in.MovementType))
	if !contains(MovementTypes, mType) {
		return nil, ErrInvalidQuantity
	}
	refType := strings.ToUpper(strings.TrimSpace(in.ReferenceType))
	if refType != "" && !contains(ReferenceTypes, refType) {
		refType = ""
	}

	// ADJUST'ta miktar hedef stoktur (sayım sonucu), sıfır olabilir.
	qty, err := parseQuantity(in.Quantity, mType == "ADJUST")
	if err != nil {
		return nil, err
	}
	if mType == "ADJUST" && strings.TrimSpace(in.Notes) == "" {
		// Gerekçesiz sayım düzeltmesi, kaybı ve fireyi görünmez kılar.
		return nil, ErrReasonRequired
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var current, minimum decimal.Decimal
	var unitPrice *float64
	var isActive bool
	var curStr, minStr string
	if err := tx.QueryRow(ctx, `
		SELECT COALESCE(current_stock,0)::text, COALESCE(minimum_stock,0)::text,
		       unit_price::float8, COALESCE(is_active,true)
		FROM inventory_items WHERE id = $1 AND property_id = $2 FOR UPDATE`,
		itemID, propertyID).Scan(&curStr, &minStr, &unitPrice, &isActive); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if !isActive {
		return nil, ErrInactive
	}
	if current, err = decimal.NewFromString(curStr); err != nil {
		return nil, err
	}
	if minimum, err = decimal.NewFromString(minStr); err != nil {
		return nil, err
	}

	var newStock decimal.Decimal
	switch mType {
	case "IN":
		newStock = current.Add(qty)
	case "OUT":
		newStock = current.Sub(qty)
		if newStock.IsNegative() {
			return nil, ErrInsufficient
		}
	case "ADJUST":
		newStock = qty
	}

	// Ağırlıklı ortalama maliyet yalnızca GİRİŞTE ve fiyat verildiğinde güncellenir.
	newUnitPrice := unitPrice
	if mType == "IN" && in.UnitPrice != nil && *in.UnitPrice >= 0 {
		incoming := decimal.NewFromFloat(*in.UnitPrice)
		if unitPrice == nil || current.LessThanOrEqual(decimal.Zero) {
			v := incoming.InexactFloat64()
			newUnitPrice = &v
		} else {
			existing := decimal.NewFromFloat(*unitPrice)
			totalValue := current.Mul(existing).Add(qty.Mul(incoming))
			if newStock.GreaterThan(decimal.Zero) {
				v := totalValue.Div(newStock).Round(2).InexactFloat64()
				newUnitPrice = &v
			}
		}
	}

	var totalPrice *float64
	if in.UnitPrice != nil {
		tp := qty.Mul(decimal.NewFromFloat(*in.UnitPrice)).Round(2).InexactFloat64()
		totalPrice = &tp
	}

	var movementID string
	if err := tx.QueryRow(ctx, `
		INSERT INTO inventory_movements
			(item_id, movement_type, quantity, previous_stock, new_stock,
			 unit_price, total_price, reference_type, reference_number, vendor,
			 notes, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,$7,NULLIF($8,''),NULLIF($9,''),NULLIF($10,''),
		        NULLIF($11,''),NULLIF($12,'')::uuid)
		RETURNING id`,
		itemID, mType, qty.String(), current.String(), newStock.String(),
		in.UnitPrice, totalPrice, refType, in.ReferenceNumber, in.Vendor,
		in.Notes, userID).Scan(&movementID); err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, `
		UPDATE inventory_items
		SET current_stock = $3::numeric,
		    unit_price = $4,
		    last_purchase_price = CASE WHEN $5 = 'IN' AND $6::numeric IS NOT NULL
		                               THEN $6::numeric ELSE last_purchase_price END,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2`,
		itemID, propertyID, newStock.String(), newUnitPrice, mType, in.UnitPrice); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &MovementResult{
		MovementID:    movementID,
		PreviousStock: current.String(),
		NewStock:      newStock.String(),
		UnitPrice:     newUnitPrice,
		BelowMinimum:  newStock.LessThanOrEqual(minimum),
	}, nil
}

// Movements, hareket geçmişini döner.
func (r *Repository) Movements(ctx context.Context, propertyID, itemID string, limit int) ([]Movement, error) {
	if limit <= 0 || limit > 500 {
		limit = 200
	}
	rows, err := r.pool.Query(ctx, `
		SELECT m.id, m.item_id, i.name, i.unit, m.movement_type,
		       m.quantity::text, COALESCE(m.previous_stock,0)::text, COALESCE(m.new_stock,0)::text,
		       m.unit_price::float8, m.total_price::float8,
		       COALESCE(m.reference_type,''), COALESCE(m.reference_number,''),
		       COALESCE(m.vendor,''), COALESCE(m.notes,''),
		       COALESCE(u.first_name || ' ' || u.last_name, ''), m.created_at
		FROM inventory_movements m
		JOIN inventory_items i ON i.id = m.item_id
		LEFT JOIN users u ON u.id = m.created_by
		WHERE i.property_id = $1 AND ($2 = '' OR m.item_id = NULLIF($2,'')::uuid)
		ORDER BY m.created_at DESC
		LIMIT $3`, propertyID, itemID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Movement{}
	for rows.Next() {
		var m Movement
		if err := rows.Scan(&m.ID, &m.ItemID, &m.ItemName, &m.Unit, &m.MovementType,
			&m.Quantity, &m.PreviousStock, &m.NewStock, &m.UnitPrice, &m.TotalPrice,
			&m.ReferenceType, &m.ReferenceNumber, &m.Vendor, &m.Notes,
			&m.CreatedByName, &m.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

// Deactivate, kalemi pasife alır. Kayıt ve hareket geçmişi silinmez.
func (r *Repository) Deactivate(ctx context.Context, propertyID, id, reason string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE inventory_items
		SET is_active = false,
		    notes = COALESCE(notes || E'\n', '') || 'Pasife alındı (' || CURRENT_DATE || '): ' || $3,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND is_active = true`, id, propertyID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

// Summary, stok özetidir.
type Summary struct {
	ItemCount        int     `json:"item_count"`
	BelowMinimum     int     `json:"below_minimum"`
	OutOfStock       int     `json:"out_of_stock"`
	TotalValueTRY    float64 `json:"total_value_try"`
	PurchaseYTDTRY   float64 `json:"purchase_cost_ytd_try"`
	ConsumptionYTD   float64 `json:"consumption_cost_ytd_try"`
	MovementsLast30d int     `json:"movements_last_30_days"`
}

// Summary, stok değerini ve yıl içi alım/tüketim maliyetini verir.
//
// Tüketim maliyeti, çıkış hareketlerinin O ANKİ ortalama maliyetle değeridir;
// işletme projesinde (KMK m.37) sarf malzeme kaleminin gerçekleşen kısmıdır.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	var s Summary
	if err := r.pool.QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE is_active),
		       count(*) FILTER (WHERE is_active AND COALESCE(current_stock,0) <= COALESCE(minimum_stock,0)),
		       count(*) FILTER (WHERE is_active AND COALESCE(current_stock,0) <= 0),
		       COALESCE(SUM(COALESCE(current_stock,0) * COALESCE(unit_price,0))
		                FILTER (WHERE is_active), 0)::float8
		FROM inventory_items WHERE property_id = $1`, propertyID).
		Scan(&s.ItemCount, &s.BelowMinimum, &s.OutOfStock, &s.TotalValueTRY); err != nil {
		return nil, err
	}

	if err := r.pool.QueryRow(ctx, `
		SELECT
		  COALESCE(SUM(m.total_price) FILTER (
		    WHERE m.movement_type = 'IN'
		      AND m.created_at >= date_trunc('year', CURRENT_DATE)), 0)::float8,
		  COALESCE(SUM(m.quantity * COALESCE(i.unit_price,0)) FILTER (
		    WHERE m.movement_type = 'OUT'
		      AND m.created_at >= date_trunc('year', CURRENT_DATE)), 0)::float8,
		  count(*) FILTER (WHERE m.created_at >= now() - interval '30 days')
		FROM inventory_movements m
		JOIN inventory_items i ON i.id = m.item_id
		WHERE i.property_id = $1`, propertyID).
		Scan(&s.PurchaseYTDTRY, &s.ConsumptionYTD, &s.MovementsLast30d); err != nil {
		return nil, err
	}
	return &s, nil
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// parseQuantity, miktarı ayrıştırır. allowZero false ise sıfır kabul edilmez.
func parseQuantity(s string, allowZero bool) (decimal.Decimal, error) {
	s = strings.TrimSpace(strings.ReplaceAll(s, ",", "."))
	if s == "" {
		if allowZero {
			return decimal.Zero, nil
		}
		return decimal.Zero, ErrInvalidQuantity
	}
	q, err := decimal.NewFromString(s)
	if err != nil {
		return decimal.Zero, ErrInvalidQuantity
	}
	if q.IsNegative() {
		return decimal.Zero, ErrInvalidQuantity
	}
	if !allowZero && q.IsZero() {
		return decimal.Zero, ErrInvalidQuantity
	}
	return q, nil
}
