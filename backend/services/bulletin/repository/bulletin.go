// Package repository, sakin ilan panosu modülünün veritabanı işlemlerini içerir.
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
	ErrNotFound        = errors.New("ilan bulunamadı")
	ErrBadState        = errors.New("ilan bu işlem için uygun durumda değil")
	ErrInvalidCategory = errors.New("geçersiz ilan kategorisi")
	ErrNotOwner        = errors.New("bu ilan size ait değil")
	ErrNoUnit          = errors.New("sitede aktif bir bağımsız bölümünüz yok")
	ErrNotApproved     = errors.New("ilan henüz yayımlanmadı")
)

// Categories, şemadaki CHECK kısıtıyla birebir aynıdır.
var Categories = []string{
	"SALE", "RENT", "LOST_FOUND", "HELP", "SUGGESTION", "CARPOOL", "SERVICE", "EVENT", "OTHER",
}

// Post, sakinin verdiği bir ilandır.
//
// İlan panosu, yönetim duyurusundan farklıdır: içeriği sakin üretir. Bu yüzden
// ilan ÖNCE YÖNETİM ONAYINDAN geçer — onaysız yayın, sitenin panosunu
// denetimsiz bir ilan alanına çevirir ve yönetimi içerikten sorumlu bırakır.
type Post struct {
	ID         string `json:"id"`
	Category   string `json:"category"`
	Title      string `json:"title"`
	Content    string `json:"content"`
	AuthorName string `json:"author_name,omitempty"`
	UnitName   string `json:"unit_name,omitempty"`

	Price           *float64 `json:"price,omitempty"`
	PriceNegotiable bool     `json:"price_negotiable"`

	IsAnonymous bool       `json:"is_anonymous"`
	Status      string     `json:"status"`
	Rejection   string     `json:"rejection_reason,omitempty"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	IsPinned    bool       `json:"is_pinned"`
	ViewCount   int        `json:"view_count"`
	CreatedAt   time.Time  `json:"created_at"`

	CommentCount int `json:"comment_count"`
	// IsMine, isteği yapanın kendi ilanı olduğunu gösterir.
	IsMine bool `json:"is_mine"`
}

// Comment, ilana yapılan yorumdur.
type Comment struct {
	ID         string    `json:"id"`
	AuthorName string    `json:"author_name,omitempty"`
	Content    string    `json:"content"`
	IsMine     bool      `json:"is_mine"`
	CreatedAt  time.Time `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const postSelect = `
SELECT p.id, p.category, p.title, p.content,
       CASE WHEN COALESCE(p.is_anonymous,false) AND p.author_id <> NULLIF($2,'')::uuid
            THEN '' ELSE COALESCE(u.first_name || ' ' || u.last_name,'') END,
       CASE WHEN COALESCE(p.is_anonymous,false) AND p.author_id <> NULLIF($2,'')::uuid
            THEN '' ELSE COALESCE(un.block,'') || '-' || COALESCE(un.door_number,'') END,
       p.price::float8, COALESCE(p.price_negotiable,true),
       COALESCE(p.is_anonymous,false), p.status, COALESCE(p.rejection_reason,''),
       p.expires_at, COALESCE(p.is_pinned,false), COALESCE(p.view_count,0), p.created_at,
       (SELECT count(*)::int FROM bulletin_comments bc
         WHERE bc.post_id = p.id AND NOT COALESCE(bc.is_deleted,false)),
       (p.author_id = NULLIF($2,'')::uuid)
FROM bulletin_posts p
LEFT JOIN users u ON u.id = p.author_id
LEFT JOIN units un ON un.id = p.unit_id`

func scanPost(row pgx.Row) (*Post, error) {
	var p Post
	err := row.Scan(&p.ID, &p.Category, &p.Title, &p.Content, &p.AuthorName, &p.UnitName,
		&p.Price, &p.PriceNegotiable, &p.IsAnonymous, &p.Status, &p.Rejection,
		&p.ExpiresAt, &p.IsPinned, &p.ViewCount, &p.CreatedAt,
		&p.CommentCount, &p.IsMine)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// List, ilanları getirir.
//
// Sakin YALNIZCA yayımlanmış ilanları ve kendi ilanlarını görür. Yönetim
// bekleyen ve reddedilenleri de görür (onaylaması gerekir).
func (r *Repository) List(ctx context.Context, propertyID, userID, category, status string, isManagement, mineOnly bool) ([]Post, error) {
	rows, err := r.scope(propertyID).Query(ctx, postSelect+`
		WHERE p.property_id = $1
		  AND ($3 = '' OR p.category = $3)
		  AND ($4 = '' OR p.status = $4)
		  AND ($5 OR p.status = 'APPROVED' OR p.author_id = NULLIF($2,'')::uuid)
		  AND ($6 = false OR p.author_id = NULLIF($2,'')::uuid)
		  AND (p.status <> 'APPROVED' OR p.expires_at IS NULL OR p.expires_at > now()
		       OR p.author_id = NULLIF($2,'')::uuid OR $5)
		ORDER BY p.is_pinned DESC, p.created_at DESC
		LIMIT 300`,
		propertyID, userID, strings.ToUpper(category), strings.ToUpper(status),
		isManagement, mineOnly)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Post{}
	for rows.Next() {
		p, err := scanPost(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *p)
	}
	return out, rows.Err()
}

// Get, tek ilanı getirir ve görüntülenme sayacını artırır.
//
// Sayaç yalnızca BAŞKASININ ilanında artar: kendi ilanını açan sakin
// görüntülenme sayısını şişiremesin diye.
func (r *Repository) Get(ctx context.Context, propertyID, id, userID string, isManagement bool) (*Post, error) {
	p, err := scanPost(r.scope(propertyID).QueryRow(ctx, postSelect+`
		WHERE p.property_id = $1 AND p.id = $3`, propertyID, userID, id))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if p.Status != "APPROVED" && !p.IsMine && !isManagement {
		// Onaylanmamış ilan başkasına gösterilmez; varlığı da sızdırılmaz.
		return nil, ErrNotFound
	}

	if !p.IsMine {
		if _, err := r.scope(propertyID).Exec(ctx,
			`UPDATE bulletin_posts SET view_count = COALESCE(view_count,0) + 1 WHERE id = $1`,
			id); err != nil {
			return nil, err
		}
		p.ViewCount++
	}
	return p, nil
}

// CreateInput, yeni ilan girdisidir.
type CreateInput struct {
	Category        string   `json:"category" binding:"required"`
	Title           string   `json:"title" binding:"required"`
	Content         string   `json:"content" binding:"required"`
	Price           *float64 `json:"price"`
	PriceNegotiable *bool    `json:"price_negotiable"`
	IsAnonymous     bool     `json:"is_anonymous"`
	ExpiresAt       string   `json:"expires_at"`
}

// Create, ilanı ONAY BEKLİYOR durumunda kaydeder.
func (r *Repository) Create(ctx context.Context, propertyID, userID string, in CreateInput) (string, error) {
	category := strings.ToUpper(strings.TrimSpace(in.Category))
	if !contains(Categories, category) {
		return "", ErrInvalidCategory
	}

	var unitID string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT ru.unit_id::text
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE ru.resident_id = $1 AND ru.is_active = true AND u.property_id = $2
		LIMIT 1`, userID, propertyID).Scan(&unitID)
	if err == pgx.ErrNoRows {
		// İlan verebilmek için sitede oturuyor olmak gerekir.
		return "", ErrNoUnit
	}
	if err != nil {
		return "", err
	}

	var expires *time.Time
	if s := strings.TrimSpace(in.ExpiresAt); s != "" {
		t, perr := time.Parse(time.RFC3339, s)
		if perr != nil {
			return "", ErrInvalidCategory
		}
		expires = &t
	}

	negotiable := true
	if in.PriceNegotiable != nil {
		negotiable = *in.PriceNegotiable
	}

	var id string
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO bulletin_posts
			(property_id, unit_id, author_id, category, title, content,
			 price, price_negotiable, is_anonymous, status, expires_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'PENDING',$10)
		RETURNING id`,
		propertyID, unitID, userID, category, in.Title, in.Content,
		in.Price, negotiable, in.IsAnonymous, expires).Scan(&id)
	return id, err
}

// Review, ilanı onaylar ya da reddeder (yönetim).
func (r *Repository) Review(ctx context.Context, propertyID, id, reviewerID, status, reason string) error {
	if status != "APPROVED" && status != "REJECTED" {
		return ErrBadState
	}
	if status == "REJECTED" && strings.TrimSpace(reason) == "" {
		// Gerekçesiz ret, sakinin ilanı düzeltmesini imkânsız kılar.
		return ErrBadState
	}
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE bulletin_posts
		SET status = $3, reviewed_by = NULLIF($4,'')::uuid, reviewed_at = now(),
		    rejection_reason = NULLIF($5,''), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'PENDING'`,
		id, propertyID, status, reviewerID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "bulletin_posts", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// Visible, ilanın çağırana görünür olup olmadığını söyler (Get ile aynı kural,
// görüntülenme sayacını ARTTIRMADAN). Yoksa ErrNotFound döner.
func (r *Repository) Visible(ctx context.Context, propertyID, id, userID string, isManagement bool) error {
	var status string
	var mine bool
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT status, (author_id = NULLIF($3,'')::uuid)
		FROM bulletin_posts WHERE id = $1 AND property_id = $2`,
		id, propertyID, userID).Scan(&status, &mine)
	if err == pgx.ErrNoRows {
		return ErrNotFound
	}
	if err != nil {
		return err
	}
	if status != "APPROVED" && !mine && !isManagement {
		return ErrNotFound
	}
	return nil
}

// Close, ilanı kapatır. Sahibi kendi ilanını, yönetim her ilanı kapatabilir.
func (r *Repository) Close(ctx context.Context, propertyID, id, userID string, isManagement bool) error {
	owner := userID
	if isManagement {
		owner = ""
	}
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE bulletin_posts
		SET status = 'CLOSED', updated_at = now()
		WHERE id = $1 AND property_id = $2
		  AND status IN ('PENDING','APPROVED')
		  AND ($3 = '' OR author_id = NULLIF($3,'')::uuid)`,
		id, propertyID, owner)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// Comments, ilanın yorumlarını getirir. Silinen yorumlar gösterilmez.
func (r *Repository) Comments(ctx context.Context, propertyID, postID, userID string) ([]Comment, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT c.id,
		       CASE WHEN COALESCE(c.is_anonymous,false) AND c.author_id <> NULLIF($3,'')::uuid
		            THEN '' ELSE COALESCE(u.first_name || ' ' || u.last_name,'') END,
		       c.content, (c.author_id = NULLIF($3,'')::uuid), c.created_at
		FROM bulletin_comments c
		LEFT JOIN users u ON u.id = c.author_id
		JOIN bulletin_posts p ON p.id = c.post_id
		WHERE c.post_id = $1 AND p.property_id = $2
		  AND NOT COALESCE(c.is_deleted,false)
		ORDER BY c.created_at
		LIMIT 300`, postID, propertyID, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Comment{}
	for rows.Next() {
		var c Comment
		if err := rows.Scan(&c.ID, &c.AuthorName, &c.Content, &c.IsMine, &c.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// AddComment, yoruma ekler. Yalnızca YAYIMLANMIŞ ilana yorum yapılabilir.
func (r *Repository) AddComment(ctx context.Context, propertyID, postID, userID, content string, anonymous bool) (string, error) {
	var status string
	err := r.scope(propertyID).QueryRow(ctx,
		`SELECT status FROM bulletin_posts WHERE id = $1 AND property_id = $2`,
		postID, propertyID).Scan(&status)
	if err == pgx.ErrNoRows {
		return "", ErrNotFound
	}
	if err != nil {
		return "", err
	}
	if status != "APPROVED" {
		return "", ErrNotApproved
	}

	var id string
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO bulletin_comments (post_id, author_id, content, is_anonymous)
		VALUES ($1,$2,$3,$4) RETURNING id`,
		postID, userID, strings.TrimSpace(content), anonymous).Scan(&id)
	return id, err
}

// DeleteComment, yorumu siler. Sahibi kendi yorumunu, yönetim her yorumu siler.
// Kayıt SİLİNMEZ, işaretlenir: kimin ne yazdığı denetim için korunur.
func (r *Repository) DeleteComment(ctx context.Context, propertyID, commentID, userID string, isManagement bool) error {
	owner := userID
	if isManagement {
		owner = ""
	}
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE bulletin_comments c
		SET is_deleted = true, deleted_at = now(), deleted_by = NULLIF($4,'')::uuid
		FROM bulletin_posts p
		WHERE c.id = $1 AND c.post_id = p.id AND p.property_id = $2
		  AND NOT COALESCE(c.is_deleted,false)
		  AND ($3 = '' OR c.author_id = NULLIF($3,'')::uuid)`,
		commentID, propertyID, owner, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// ExpirePosts, süresi dolmuş yayımlanmış ilanları EXPIRED yapar (idempotent).
func (r *Repository) ExpirePosts(ctx context.Context, propertyID string) (int64, error) {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE bulletin_posts
		SET status = 'EXPIRED', updated_at = now()
		WHERE property_id = $1 AND status = 'APPROVED'
		  AND expires_at IS NOT NULL AND expires_at <= now()`, propertyID)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// Summary, pano özetidir.
type Summary struct {
	Pending    int            `json:"pending_review"`
	Approved   int            `json:"approved"`
	Rejected   int            `json:"rejected"`
	Expired    int            `json:"expired"`
	Closed     int            `json:"closed"`
	ByCategory map[string]int `json:"by_category"`
}

// Summary, ilan panosunun durumunu verir.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	s := &Summary{ByCategory: map[string]int{}}
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE status = 'PENDING'),
		       count(*) FILTER (WHERE status = 'APPROVED'),
		       count(*) FILTER (WHERE status = 'REJECTED'),
		       count(*) FILTER (WHERE status = 'EXPIRED'),
		       count(*) FILTER (WHERE status = 'CLOSED')
		FROM bulletin_posts WHERE property_id = $1`, propertyID).
		Scan(&s.Pending, &s.Approved, &s.Rejected, &s.Expired, &s.Closed); err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT category, count(*) FROM bulletin_posts
		WHERE property_id = $1 AND status = 'APPROVED' GROUP BY category`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var cat string
		var n int
		if err := rows.Scan(&cat, &n); err != nil {
			return nil, err
		}
		s.ByCategory[cat] = n
	}
	return s, rows.Err()
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
// bulletin_posts, bulletin_comments tablolarında RLS açıktır (migration 021).
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
