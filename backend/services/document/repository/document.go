// Package repository, belge arşivi modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrNotFound        = errors.New("belge bulunamadı")
	ErrInvalidCategory = errors.New("geçersiz belge kategorisi")
	ErrInvalidVisible  = errors.New("geçersiz görünürlük")
	ErrAlreadyArchived = errors.New("belge zaten arşivden çıkarılmış")
	ErrDuplicateKey    = errors.New("bu dosya zaten kayıtlı")
)

// Categories, migration 015'teki CHECK kısıtıyla birebir aynıdır.
var Categories = []string{
	"MANAGEMENT_PLAN", "DECISION", "BUDGET", "ACCOUNTING", "CONTRACT", "INVOICE",
	"INSURANCE", "REPORT", "LEGAL", "PERSONNEL", "TECHNICAL", "OTHER",
}

// Visibilities, görünürlük kademeleridir (geniş → dar).
var Visibilities = []string{"RESIDENTS", "OWNERS", "MANAGEMENT"}

// Document, arşivdeki bir belgenin üst verisidir. Dosyanın kendisi nesne
// deposundadır; burada yalnızca ona işaret eden anahtar tutulur.
type Document struct {
	ID          string `json:"id"`
	Category    string `json:"category"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`

	StorageBackend string `json:"storage_backend"`
	StorageKey     string `json:"-"` // istemciye ASLA verilmez
	FileName       string `json:"file_name"`
	ContentType    string `json:"content_type"`
	SizeBytes      int64  `json:"size_bytes"`
	SHA256         string `json:"sha256"`

	Visibility  string `json:"visibility"`
	RelatedType string `json:"related_type,omitempty"`
	RelatedID   string `json:"related_id,omitempty"`

	Version    int     `json:"version"`
	ReplacesID *string `json:"replaces_id,omitempty"`
	IsCurrent  bool    `json:"is_current"`

	RetentionUntil *time.Time `json:"retention_until,omitempty"`

	UploadedByName string    `json:"uploaded_by_name,omitempty"`
	UploadedAt     time.Time `json:"uploaded_at"`

	ArchivedAt    *time.Time `json:"archived_at,omitempty"`
	ArchiveReason string     `json:"archive_reason,omitempty"`
	Notes         string     `json:"notes,omitempty"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const documentSelect = `
SELECT d.id, d.category, d.title, COALESCE(d.description,''),
       d.storage_backend, d.storage_key, d.file_name, d.content_type,
       d.size_bytes, d.sha256, d.visibility,
       COALESCE(d.related_type,''), d.related_id,
       d.version, d.replaces_id, d.is_current, d.retention_until,
       COALESCE(u.first_name || ' ' || u.last_name, ''), d.uploaded_at,
       d.archived_at, COALESCE(d.archive_reason,''), COALESCE(d.notes,'')
FROM documents d
LEFT JOIN users u ON u.id = d.uploaded_by`

func scanDocument(row pgx.Row) (*Document, error) {
	var d Document
	var relatedID, replacesID *string
	err := row.Scan(&d.ID, &d.Category, &d.Title, &d.Description,
		&d.StorageBackend, &d.StorageKey, &d.FileName, &d.ContentType,
		&d.SizeBytes, &d.SHA256, &d.Visibility, &d.RelatedType, &relatedID,
		&d.Version, &replacesID, &d.IsCurrent, &d.RetentionUntil,
		&d.UploadedByName, &d.UploadedAt, &d.ArchivedAt, &d.ArchiveReason, &d.Notes)
	if err != nil {
		return nil, err
	}
	if relatedID != nil {
		d.RelatedID = *relatedID
	}
	d.ReplacesID = replacesID
	return &d, nil
}

// ListFilter, listeleme ölçütleridir.
type ListFilter struct {
	Category      string
	RelatedType   string
	RelatedID     string
	IncludeOldVer bool
	IncludeArchiv bool
	// MaxVisibility, isteği yapanın görebileceği en geniş kademedir.
	// Boş bırakılamaz; boşsa hiçbir belge dönmez (fail-closed).
	AllowedVisibilities []string
}

// List, görünürlük kısıtını SORGUDA uygular.
//
// Süzmeyi uygulama katmanında yapmak, bir hata durumunda tüm belgelerin
// istemciye gitmesi demektir; bu yüzden kısıt sorgunun kendisindedir.
func (r *Repository) List(ctx context.Context, propertyID string, f ListFilter) ([]Document, error) {
	if len(f.AllowedVisibilities) == 0 {
		return []Document{}, nil
	}
	rows, err := r.pool.Query(ctx, documentSelect+`
		WHERE d.property_id = $1
		  AND d.visibility = ANY($2)
		  AND ($3 = '' OR d.category = $3)
		  AND ($4 = '' OR d.related_type = $4)
		  AND ($5 = '' OR d.related_id = NULLIF($5,'')::uuid)
		  AND ($6 OR d.is_current = true)
		  AND ($7 OR d.archived_at IS NULL)
		ORDER BY d.uploaded_at DESC
		LIMIT 500`,
		propertyID, f.AllowedVisibilities, strings.ToUpper(f.Category),
		strings.ToUpper(f.RelatedType), f.RelatedID, f.IncludeOldVer, f.IncludeArchiv)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Document{}
	for rows.Next() {
		d, err := scanDocument(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *d)
	}
	return out, rows.Err()
}

// Get, tek belgeyi getirir; görünürlük kısıtı burada da uygulanır.
func (r *Repository) Get(ctx context.Context, propertyID, id string, allowed []string) (*Document, error) {
	if len(allowed) == 0 {
		return nil, ErrNotFound
	}
	d, err := scanDocument(r.pool.QueryRow(ctx, documentSelect+`
		WHERE d.property_id = $1 AND d.id = $2 AND d.visibility = ANY($3)`,
		propertyID, id, allowed))
	if err == pgx.ErrNoRows {
		// Yetkisiz erişimde "var ama göremezsin" demek, belgenin varlığını
		// sızdırır. Bu yüzden bulunamadı denir.
		return nil, ErrNotFound
	}
	return d, err
}

// CreateInput, yeni belge kaydıdır.
type CreateInput struct {
	Category    string
	Title       string
	Description string
	Visibility  string

	StorageBackend string
	StorageKey     string
	FileName       string
	ContentType    string
	SizeBytes      int64
	SHA256         string

	RelatedType    string
	RelatedID      string
	ReplacesID     string
	RetentionUntil *time.Time
	Notes          string
}

// Create, belgeyi kaydeder. Yeni sürümse version otomatik artar.
func (r *Repository) Create(ctx context.Context, propertyID, uploadedBy string, in CreateInput) (string, error) {
	category := strings.ToUpper(strings.TrimSpace(in.Category))
	if !contains(Categories, category) {
		return "", ErrInvalidCategory
	}
	visibility := strings.ToUpper(strings.TrimSpace(in.Visibility))
	if visibility == "" {
		// Belirtilmemişse EN DAR kademe uygulanır. Varsayılanı geniş tutmak,
		// unutulan bir alan yüzünden özlük dosyasının herkese açılması demektir.
		visibility = "MANAGEMENT"
	}
	if !contains(Visibilities, visibility) {
		return "", ErrInvalidVisible
	}

	version := 1
	if in.ReplacesID != "" {
		var prev int
		err := r.pool.QueryRow(ctx,
			`SELECT version FROM documents WHERE id = $1 AND property_id = $2`,
			in.ReplacesID, propertyID).Scan(&prev)
		if err == pgx.ErrNoRows {
			return "", ErrNotFound
		}
		if err != nil {
			return "", err
		}
		version = prev + 1
	}

	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO documents
			(property_id, category, title, description, storage_backend, storage_key,
			 file_name, content_type, size_bytes, sha256, visibility,
			 related_type, related_id, version, replaces_id, retention_until,
			 uploaded_by, notes)
		VALUES ($1,$2,$3,NULLIF($4,''),$5,$6,$7,$8,$9,$10,$11,
		        NULLIF($12,''),NULLIF($13,'')::uuid,$14,NULLIF($15,'')::uuid,$16,
		        NULLIF($17,'')::uuid,NULLIF($18,''))
		RETURNING id`,
		propertyID, category, in.Title, in.Description, in.StorageBackend, in.StorageKey,
		in.FileName, in.ContentType, in.SizeBytes, in.SHA256, visibility,
		strings.ToUpper(in.RelatedType), in.RelatedID, version, in.ReplacesID,
		in.RetentionUntil, uploadedBy, in.Notes).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "uq_documents_storage_key") {
		return "", ErrDuplicateKey
	}
	return id, err
}

// Archive, belgeyi arşivden çıkarır. Kayıt SİLİNMEZ; gerekçesi kayda geçer.
func (r *Repository) Archive(ctx context.Context, propertyID, id, userID, reason string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE documents
		SET archived_at = now(), archived_by = NULLIF($3,'')::uuid,
		    archive_reason = $4, is_current = false, updated_at = now()
		WHERE id = $1 AND property_id = $2 AND archived_at IS NULL`,
		id, propertyID, userID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrAlreadyArchived
	}
	return nil
}

// LogAccess, belge erişimini kayda geçer (KVKK m.12).
//
// Hata YUTULMAZ: erişim kaydı yazılamıyorsa bu, denetim izinin eksik kalması
// demektir ve çağıran bunu bilmek zorundadır.
func (r *Repository) LogAccess(ctx context.Context, propertyID, documentID, userID, action, ip, agent string) error {
	_, err := r.pool.Exec(ctx, `
		INSERT INTO document_access_logs
			(document_id, property_id, user_id, action, ip_address, user_agent)
		VALUES ($1,$2,NULLIF($3,'')::uuid,$4,NULLIF($5,'')::inet,NULLIF($6,''))`,
		documentID, propertyID, userID, action, ip, agent)
	return err
}

// AccessEntry, bir belgeye yapılmış tek erişimdir.
type AccessEntry struct {
	UserName   string    `json:"user_name,omitempty"`
	Action     string    `json:"action"`
	IPAddress  string    `json:"ip_address,omitempty"`
	AccessedAt time.Time `json:"accessed_at"`
}

// AccessLog, belgeye kimin eriştiğini döner (yalnızca yönetim/denetçi).
func (r *Repository) AccessLog(ctx context.Context, propertyID, documentID string) ([]AccessEntry, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT COALESCE(u.first_name || ' ' || u.last_name, ''), l.action,
		       COALESCE(host(l.ip_address),''), l.accessed_at
		FROM document_access_logs l
		LEFT JOIN users u ON u.id = l.user_id
		WHERE l.document_id = $1 AND l.property_id = $2
		ORDER BY l.accessed_at DESC
		LIMIT 200`, documentID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []AccessEntry{}
	for rows.Next() {
		var e AccessEntry
		if err := rows.Scan(&e.UserName, &e.Action, &e.IPAddress, &e.AccessedAt); err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

// Summary, arşivin özetidir.
type Summary struct {
	Total          int            `json:"total"`
	Archived       int            `json:"archived"`
	ByCategory     map[string]int `json:"by_category"`
	TotalSizeBytes int64          `json:"total_size_bytes"`
	RetentionDue   int            `json:"retention_due"`
}

// Summary, kategori dağılımını ve saklama süresi dolan belge sayısını verir.
func (r *Repository) Summary(ctx context.Context, propertyID string, allowed []string) (*Summary, error) {
	s := &Summary{ByCategory: map[string]int{}}
	if len(allowed) == 0 {
		return s, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT category, count(*), COALESCE(SUM(size_bytes),0),
		       count(*) FILTER (WHERE archived_at IS NOT NULL),
		       count(*) FILTER (WHERE retention_until IS NOT NULL
		                          AND retention_until < CURRENT_DATE
		                          AND archived_at IS NULL)
		FROM documents
		WHERE property_id = $1 AND visibility = ANY($2)
		GROUP BY category`, propertyID, allowed)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var cat string
		var n, archived, retention int
		var size int64
		if err := rows.Scan(&cat, &n, &size, &archived, &retention); err != nil {
			return nil, err
		}
		s.ByCategory[cat] = n
		s.Total += n
		s.Archived += archived
		s.TotalSizeBytes += size
		s.RetentionDue += retention
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
