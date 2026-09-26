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
	// ErrAnnouncementNotFound, duyuru bulunamadığında döner.
	ErrAnnouncementNotFound = errors.New("duyuru bulunamadı")
	// ErrInvalidAnnouncement, kategori/öncelik geçersizse döner.
	ErrInvalidAnnouncement = errors.New("geçersiz kategori ya da öncelik")
)

// AnnouncementCategories ve Priorities, şemadaki serbest metin alanlarını
// sınırlar. Serbest bırakılırsa aynı kategori üç farklı yazımla tutulur ve
// süzme anlamını yitirir.
var (
	AnnouncementCategories = []string{"GENERAL", "MAINTENANCE", "FINANCIAL", "EMERGENCY", "ASSEMBLY"}
	AnnouncementPriorities = []string{"LOW", "NORMAL", "HIGH", "URGENT"}
)

// Announcement, yönetimin sakinlere duyurusudur.
//
// Yönetim duyurusu ile sakin ilanı (bulletin) farklı şeylerdir: duyuruyu
// yönetim yayımlar ve onay gerektirmez; ilanı sakin verir ve yönetim onayından
// geçer.
type Announcement struct {
	ID          string     `json:"id"`
	Title       string     `json:"title"`
	Content     string     `json:"content"`
	Category    string     `json:"category"`
	Priority    string     `json:"priority"`
	IsPinned    bool       `json:"is_pinned"`
	PublishedAt time.Time  `json:"published_at"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	CreatedBy   string     `json:"created_by_name,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`

	// IsRead, isteği yapanın duyuruyu okuyup okumadığını gösterir.
	IsRead bool `json:"is_read"`
	// ReadCount yalnızca yönetime doldurulur.
	ReadCount *int `json:"read_count,omitempty"`
}

// AnnouncementRepository, duyuru işlemlerini yürütür.
type AnnouncementRepository struct{ pool *pgxpool.Pool }

// NewAnnouncementRepository, depo kurar.
func NewAnnouncementRepository(pool *pgxpool.Pool) *AnnouncementRepository {
	return &AnnouncementRepository{pool: pool}
}

const announcementSelect = `
SELECT a.id, a.title, a.content, COALESCE(a.category,'GENERAL'),
       COALESCE(a.priority,'NORMAL'), COALESCE(a.is_pinned,false),
       a.published_at, a.expires_at,
       COALESCE(u.first_name || ' ' || u.last_name,''), a.created_at,
       EXISTS(SELECT 1 FROM announcement_reads ar
              WHERE ar.announcement_id = a.id AND ar.user_id = NULLIF($2,'')::uuid),
       CASE WHEN $3 THEN (SELECT count(*)::int FROM announcement_reads ar2
                          WHERE ar2.announcement_id = a.id) ELSE NULL END
FROM announcements a
LEFT JOIN users u ON u.id = a.created_by`

// List, yayımdaki duyuruları getirir.
//
// Süresi dolmuş duyurular varsayılan olarak GİZLENİR: bitmiş bir bakım
// duyurusunun listede durması, sakinin güncel duyuruyu gözden kaçırmasına
// yol açar. Yönetim isterse tümünü görebilir.
func (r *AnnouncementRepository) List(ctx context.Context, propertyID, userID string, isManagement, includeExpired bool, category string) ([]Announcement, error) {
	rows, err := r.scope(propertyID).Query(ctx, announcementSelect+`
		WHERE a.property_id = $1
		  AND ($4 = '' OR a.category = $4)
		  AND ($5 OR a.expires_at IS NULL OR a.expires_at > now())
		ORDER BY a.is_pinned DESC, a.published_at DESC
		LIMIT 200`,
		propertyID, userID, isManagement, strings.ToUpper(category),
		includeExpired && isManagement)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Announcement{}
	for rows.Next() {
		var a Announcement
		if err := rows.Scan(&a.ID, &a.Title, &a.Content, &a.Category, &a.Priority,
			&a.IsPinned, &a.PublishedAt, &a.ExpiresAt, &a.CreatedBy, &a.CreatedAt,
			&a.IsRead, &a.ReadCount); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// Get, tek duyuruyu getirir.
func (r *AnnouncementRepository) Get(ctx context.Context, propertyID, id, userID string, isManagement bool) (*Announcement, error) {
	var a Announcement
	err := r.scope(propertyID).QueryRow(ctx, announcementSelect+`
		WHERE a.property_id = $1 AND a.id = $4`,
		propertyID, userID, isManagement, id).
		Scan(&a.ID, &a.Title, &a.Content, &a.Category, &a.Priority,
			&a.IsPinned, &a.PublishedAt, &a.ExpiresAt, &a.CreatedBy, &a.CreatedAt,
			&a.IsRead, &a.ReadCount)
	if err == pgx.ErrNoRows {
		return nil, ErrAnnouncementNotFound
	}
	if err != nil {
		return nil, err
	}
	return &a, nil
}

// CreateAnnouncementInput, yeni duyuru girdisidir.
type CreateAnnouncementInput struct {
	Title     string `json:"title" binding:"required"`
	Content   string `json:"content" binding:"required"`
	Category  string `json:"category"`
	Priority  string `json:"priority"`
	IsPinned  bool   `json:"is_pinned"`
	ExpiresAt string `json:"expires_at"`
}

// Create, duyuruyu yayımlar.
func (r *AnnouncementRepository) Create(ctx context.Context, propertyID, userID string, in CreateAnnouncementInput) (string, error) {
	category := strings.ToUpper(strings.TrimSpace(in.Category))
	if category == "" {
		category = "GENERAL"
	}
	priority := strings.ToUpper(strings.TrimSpace(in.Priority))
	if priority == "" {
		priority = "NORMAL"
	}
	if !contains(AnnouncementCategories, category) || !contains(AnnouncementPriorities, priority) {
		return "", ErrInvalidAnnouncement
	}

	var expires *time.Time
	if s := strings.TrimSpace(in.ExpiresAt); s != "" {
		t, err := time.Parse(time.RFC3339, s)
		if err != nil {
			return "", ErrInvalidAnnouncement
		}
		expires = &t
	}

	var id string
	err := r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO announcements
			(property_id, title, content, category, priority, is_pinned,
			 published_at, expires_at, created_by)
		VALUES ($1,$2,$3,$4,$5,$6,now(),$7,NULLIF($8,'')::uuid)
		RETURNING id`,
		propertyID, in.Title, in.Content, category, priority, in.IsPinned,
		expires, userID).Scan(&id)
	return id, err
}

// MarkRead, duyuruyu okundu işaretler. İşlem tekrarlanabilir (idempotent).
//
// Okundu bilgisi, acil bir duyurunun (örn. su kesintisi) kimlere ulaştığının
// tek kanıtıdır; bu yüzden ayrı tabloda tutulur ve silinmez.
func (r *AnnouncementRepository) MarkRead(ctx context.Context, propertyID, id, userID string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		INSERT INTO announcement_reads (announcement_id, user_id)
		SELECT $1, NULLIF($3,'')::uuid
		FROM announcements WHERE id = $1 AND property_id = $2
		ON CONFLICT (announcement_id, user_id) DO NOTHING`, id, propertyID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		// Ya duyuru yok ya da zaten okunmuş; ayrımı için kontrol edilir.
		var exists bool
		if err := r.scope(propertyID).QueryRow(ctx,
			`SELECT EXISTS(SELECT 1 FROM announcements WHERE id = $1 AND property_id = $2)`,
			id, propertyID).Scan(&exists); err != nil {
			return err
		}
		if !exists {
			return ErrAnnouncementNotFound
		}
	}
	return nil
}

// Pin, duyuruyu sabitler ya da sabitlemeyi kaldırır.
func (r *AnnouncementRepository) Pin(ctx context.Context, propertyID, id string, pinned bool) error {
	tag, err := r.scope(propertyID).Exec(ctx,
		`UPDATE announcements SET is_pinned = $3 WHERE id = $1 AND property_id = $2`,
		id, propertyID, pinned)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrAnnouncementNotFound
	}
	return nil
}

// ReadStats, bir duyurunun okunma durumudur.
type ReadStats struct {
	TotalResidents int `json:"total_residents"`
	ReadCount      int `json:"read_count"`
	UnreadCount    int `json:"unread_count"`
}

// ReadStats, duyuruyu kaç sakinin okuduğunu verir (yalnızca yönetim).
func (r *AnnouncementRepository) ReadStats(ctx context.Context, propertyID, id string) (*ReadStats, error) {
	var s ReadStats
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT
		  (SELECT count(DISTINCT ru.resident_id)
		     FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		    WHERE u.property_id = $1 AND ru.is_active),
		  (SELECT count(*) FROM announcement_reads ar
		    WHERE ar.announcement_id = $2)`, propertyID, id).
		Scan(&s.TotalResidents, &s.ReadCount)
	if err != nil {
		return nil, err
	}
	s.UnreadCount = s.TotalResidents - s.ReadCount
	if s.UnreadCount < 0 {
		s.UnreadCount = 0
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

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `announcements` ve `announcement_reads` tablolarında RLS açıktır
// (migration 023).
func (r *AnnouncementRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// Exists, kayıt bu sitede var mı (RLS kapsamında) — handler'ın üst kaydı
// doğrulaması için. Üst kayıt yokken alt liste boş dönerse istemci "kayıt
// var ama boş" sanar.
func (r *AnnouncementRepository) Exists(ctx context.Context, propertyID, table, id string) (bool, error) {
	return r.scope(propertyID).Exists(ctx, table, id)
}
