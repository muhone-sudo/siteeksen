// Package repository, ziyaretçi yönetiminin veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/services/visitor/models"
)

var (
	ErrNotFound      = errors.New("ziyaretçi kaydı bulunamadı")
	ErrUnitNotInSite = errors.New("belirtilen bağımsız bölüm bu siteye ait değil")
	ErrBadState      = errors.New("ziyaretçi bu işlem için uygun durumda değil")
)

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const visitorSelect = `
SELECT v.id, v.property_id, COALESCE(v.unit_id::text,''),
       COALESCE(u.block,'') || CASE WHEN u.id IS NULL THEN '' ELSE '-' END || COALESCE(u.door_number,''),
       v.visitor_name, COALESCE(v.visitor_phone,''), COALESCE(v.visitor_company,''),
       COALESCE(v.visitor_id_number,''), COALESCE(v.vehicle_plate,''),
       COALESCE(v.purpose,''), COALESCE(v.visit_reason,''), v.expected_at,
       v.checked_in_at, v.checked_out_at, v.status,
       COALESCE(v.notes,''), v.created_at
FROM visitors v
LEFT JOIN units u ON u.id = v.unit_id`

func scanVisitor(row pgx.Row) (*models.Visitor, error) {
	var v models.Visitor
	err := row.Scan(&v.ID, &v.PropertyID, &v.UnitID, &v.UnitName, &v.VisitorName,
		&v.VisitorPhone, &v.VisitorCompany, &v.VisitorIDNumber, &v.VehiclePlate,
		&v.Purpose, &v.VisitReason, &v.ExpectedAt, &v.CheckedInAt, &v.CheckedOutAt,
		&v.Status, &v.Notes, &v.CreatedAt)
	if err != nil {
		return nil, err
	}
	if v.CheckedInAt != nil && v.CheckedOutAt != nil {
		d := int(v.CheckedOutAt.Sub(*v.CheckedInAt).Minutes())
		v.DurationMinutes = &d
	}
	return &v, nil
}

// List, ziyaretçileri getirir.
//
// residentUserID boş değilse sonuçlar YALNIZCA o sakinin bağımsız bölümleriyle
// sınırlanır. Bir sakinin komşusunun ziyaretçilerini görmesi mahremiyet ihlalidir.
func (r *Repository) List(ctx context.Context, propertyID, status, residentUserID string, inside bool) ([]models.Visitor, error) {
	rows, err := r.scope(propertyID).Query(ctx, visitorSelect+`
		WHERE v.property_id = $1
		  AND ($2 = '' OR v.status = $2)
		  AND ($3 = false OR v.status = 'CHECKED_IN')
		  AND ($4 = '' OR v.unit_id IN (
		        SELECT ru.unit_id FROM resident_units ru
		        WHERE ru.resident_id = NULLIF($4,'')::uuid AND ru.is_active = true))
		ORDER BY COALESCE(v.checked_in_at, v.expected_at, v.created_at) DESC
		LIMIT 500`, propertyID, status, inside, residentUserID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []models.Visitor{}
	for rows.Next() {
		v, err := scanVisitor(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *v)
	}
	return out, rows.Err()
}

// Get, tek ziyaretçi kaydını getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id string) (*models.Visitor, error) {
	v, err := scanVisitor(r.scope(propertyID).QueryRow(ctx, visitorSelect+`
		WHERE v.id = $1 AND v.property_id = $2`, id, propertyID))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return v, err
}

// Create, ziyaretçi ön kaydı oluşturur.
func (r *Repository) Create(ctx context.Context, propertyID, userID string, in models.CreateVisitorInput, expectedAt *time.Time) (string, error) {
	// Bağımsız bölüm verilmişse bu siteye ait olmalı.
	if in.UnitID != "" {
		var ok bool
		if err := r.scope(propertyID).QueryRow(ctx,
			`SELECT EXISTS(SELECT 1 FROM units WHERE id = $1 AND property_id = $2 AND deleted = 0)`,
			in.UnitID, propertyID).Scan(&ok); err != nil {
			return "", err
		}
		if !ok {
			return "", ErrUnitNotInSite
		}
	}

	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO visitors
			(property_id, unit_id, visitor_name, visitor_phone, visitor_id_number,
			 visitor_company, vehicle_plate, purpose, visit_reason, expected_at,
			 notes, created_by, status)
		VALUES ($1, NULLIF($2,'')::uuid, $3, NULLIF($4,''), NULLIF($5,''),
		        NULLIF($6,''), NULLIF($7,''), NULLIF($8,''), NULLIF($9,''), $10,
		        NULLIF($11,''), NULLIF($12,'')::uuid, 'EXPECTED')
		RETURNING id`,
		propertyID, in.UnitID, in.VisitorName, in.VisitorPhone, in.VisitorIDNumber,
		in.VisitorCompany, in.VehiclePlate, in.Purpose, in.VisitReason, expectedAt,
		in.Notes, userID).Scan(&id)
	return id, err
}

// CheckIn, ziyaretçinin siteye girişini kaydeder.
//
// Yalnızca EXPECTED durumundaki kayıt giriş yapabilir; çift giriş engellenir.
// Aksi hâlde aynı ziyaretçi "içeride" iki kez sayılır ve mevcut ziyaretçi
// listesi güvenilmez hâle gelir.
func (r *Repository) CheckIn(ctx context.Context, propertyID, id, userID string) (*CheckInInfo, error) {
	// Giriş kaydı ile bildirim için gereken bilgiyi TEK sorguda alıyoruz.
	// Ayrı bir SELECT, aradaki sürede kaydın değişmesi hâlinde artık
	// geçerli olmayan bir duruma göre bildirim üretirdi.
	var info CheckInInfo
	err := r.scope(propertyID).QueryRow(ctx, `
		UPDATE visitors
		SET status = 'CHECKED_IN', checked_in_at = now(),
		    checked_in_by = NULLIF($3,'')::uuid, updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'EXPECTED'
		RETURNING visitor_name, COALESCE(unit_id::text,''), COALESCE(created_by::text,''),
		          COALESCE(visitor_company,'')`,
		id, propertyID, userID).Scan(
		&info.VisitorName, &info.UnitID, &info.CreatedBy, &info.Company)
	if err == pgx.ErrNoRows {
		return nil, r.stateOrNotFound(ctx, propertyID, "visitors", id, ErrNotFound, ErrBadState)
	}
	if err != nil {
		return nil, err
	}
	return &info, nil
}

// CheckInInfo, giriş sonrası bildirim üretmek için gereken en az bilgidir.
//
// CreatedBy bilerek taşınır: ziyaretçi bir bağımsız bölüme bağlı değilse
// (ör. yönetim ofisine gelen ziyaretçi) haber verilecek tek kişi, kaydı
// açan kişidir. Bu alan olmasaydı o durumda kimseye haber verilemezdi.
type CheckInInfo struct {
	VisitorName string
	UnitID      string
	CreatedBy   string
	Company     string
}

// MarkResidentNotified, sakine haber verildiğini kayda geçirir.
//
// Yalnızca bildirim GERÇEKTEN oluşturulduğunda çağrılır. Bu alanı bildirim
// üretilmeden doldurmak, ziyaretçi kaydını sonradan "sakinin haberi vardı"
// diyen yanıltıcı bir belgeye dönüştürürdü.
func (r *Repository) MarkResidentNotified(ctx context.Context, propertyID, id, method string) error {
	_, err := r.scope(propertyID).Exec(ctx, `
		UPDATE visitors
		SET resident_notified_at = COALESCE(resident_notified_at, now()),
		    notification_method = $3, updated_at = now()
		WHERE id = $1 AND property_id = $2`, id, propertyID, method)
	return err
}

// CheckOut, ziyaretçinin çıkışını kaydeder.
func (r *Repository) CheckOut(ctx context.Context, propertyID, id, userID string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE visitors
		SET status = 'CHECKED_OUT', checked_out_at = now(),
		    checked_out_by = NULLIF($3,'')::uuid, updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'CHECKED_IN'`,
		id, propertyID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "visitors", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// Cancel, gelmemiş ziyaretçi kaydını iptal eder.
//
// ownerUserID doluysa (güvenlik/yönetim OLMAYAN çağıran) yalnızca kişinin
// kendi oluşturduğu ya da kendi dairesine gelen ziyaretçi iptal edilebilir.
// Önceden hiçbir denetim yoktu: her sakin sitedeki HER beklenen ziyaretçiyi
// iptal edebiliyordu — güvenlik görevlisi misafiri kapıdan geri çevirirdi.
// Başkasının kaydı "bulunamadı" döner; varlığı sızdırılmaz.
func (r *Repository) Cancel(ctx context.Context, propertyID, ownerUserID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE visitors SET status = 'CANCELLED', updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'EXPECTED'
		  AND ($3 = '' OR created_by = NULLIF($3,'')::uuid
		       OR unit_id IN (SELECT ru.unit_id FROM resident_units ru
		                      WHERE ru.resident_id = NULLIF($3,'')::uuid AND ru.is_active = true))`,
		id, propertyID, ownerUserID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		if ownerUserID != "" {
			return ErrNotFound
		}
		return r.stateOrNotFound(ctx, propertyID, "visitors", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// Summary, günlük ziyaretçi özetini verir.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*models.Summary, error) {
	var s models.Summary
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE status = 'CHECKED_IN'),
		       count(*) FILTER (WHERE status = 'EXPECTED' AND expected_at::date = CURRENT_DATE),
		       count(*) FILTER (WHERE checked_in_at::date = CURRENT_DATE),
		       count(*) FILTER (WHERE checked_out_at::date = CURRENT_DATE)
		FROM visitors WHERE property_id = $1`, propertyID).
		Scan(&s.CurrentlyInside, &s.TodayExpected, &s.TodayCheckedIn, &s.TodayCheckedOut)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// visitors tablolarında RLS açıktır (migration 021).
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
