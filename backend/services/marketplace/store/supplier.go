package store

// Tedarikçi hesabı, belgeleri, işletmeleri ve hizmet kalemleri (FAZ M3). Bütün yazmalar tedarikçi kapsamında
// (dbscope.ForSupplier) çalışır: başka hesabın satırı görünmez, güncellenemez.

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/siteeksen/backend/pkg/phone"
	"github.com/siteeksen/backend/services/marketplace/rules"
)

// AccountInput, hesap bilgileridir.
type AccountInput struct {
	TradeName string `json:"trade_name"`
	TaxNumber string `json:"tax_number"`
	TaxOffice string `json:"tax_office"`
}

func (in *AccountInput) clean() error {
	in.TradeName, in.TaxNumber, in.TaxOffice = strings.TrimSpace(in.TradeName), strings.TrimSpace(in.TaxNumber), strings.TrimSpace(in.TaxOffice)
	if in.TaxNumber != "" && !rules.ValidTaxNumber(in.TaxNumber) {
		return userErr(http.StatusUnprocessableEntity, "TAX_NUMBER", "Vergi numarası 10 hane (şahıs işletmesinde T.C. kimlik no 11 hane) rakam olmalı")
	}
	return nil
}

// CreateAccount, kişinin tedarikçi hesabını açar (DRAFT, varsayılan ücretsiz paket, sözleşme onayı zamanı).
func (s *Store) CreateAccount(ctx context.Context, userID string, in AccountInput) (*Account, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	id := uuid.NewString()
	_, err := s.supplier(id).Exec(ctx, `
		INSERT INTO mp_supplier_accounts (id, user_id, trade_name, tax_number, tax_office, package_id, terms_accepted_at)
		VALUES ($1, $2, $3, $4, $5, (SELECT id FROM mp_packages WHERE is_default), now())`,
		id, userID, in.TradeName, in.TaxNumber, in.TaxOffice)
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		return nil, userErr(http.StatusConflict, "ACCOUNT_EXISTS", "Tedarikçi hesabınız zaten var")
	}
	if err != nil {
		return nil, err
	}
	return s.Account(ctx, id)
}

// Account, hesabı tedarikçi kapsamında okur.
func (s *Store) Account(ctx context.Context, accountID string) (*Account, error) {
	return scanAccount(s.supplier(accountID).QueryRow(ctx, accountSelect+` WHERE a.id = $1`, accountID))
}

// UpdateAccount, hesap bilgilerini yalnız taslakta değiştirir (onaylı bilgiler incelemesiz değişmez).
func (s *Store) UpdateAccount(ctx context.Context, accountID string, in AccountInput) (*Account, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	tag, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_supplier_accounts SET trade_name = $2, tax_number = $3, tax_office = $4,
		updated_at = now() WHERE id = $1 AND status = 'DRAFT'`, accountID, in.TradeName, in.TaxNumber, in.TaxOffice)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, userErr(http.StatusConflict, "NOT_DRAFT", "Hesap bilgileri yalnız taslak durumundayken değiştirilebilir")
	}
	return s.Account(ctx, accountID)
}

// Document, hesap belgesidir.
type Document struct {
	ID          string     `json:"id"`
	DocType     string     `json:"doc_type"`
	FileName    string     `json:"file_name"`
	ContentType string     `json:"content_type"`
	SizeBytes   int64      `json:"size_bytes"`
	SHA256      string     `json:"sha256"`
	Status      string     `json:"status"`
	ReviewNote  *string    `json:"review_note"`
	ReviewedAt  *time.Time `json:"reviewed_at"`
	UploadedAt  time.Time  `json:"uploaded_at"`
	StorageKey  string     `json:"-"`
	AccountID   string     `json:"account_id"`
}

const documentCols = `id, doc_type, file_name, content_type, size_bytes, sha256, status, review_note, reviewed_at, uploaded_at, storage_key, account_id`

func scanDocument(r pgx.Row) (*Document, error) {
	d := &Document{}
	err := r.Scan(&d.ID, &d.DocType, &d.FileName, &d.ContentType, &d.SizeBytes, &d.SHA256, &d.Status, &d.ReviewNote,
		&d.ReviewedAt, &d.UploadedAt, &d.StorageKey, &d.AccountID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return d, err
}

// DocumentTypes, kabul edilen belge türleridir.
var DocumentTypes = []string{"TAX_PLATE", "ID_CARD", "CHAMBER_RECORD", "OTHER"}

// CanUploadDocument, hesabın belge yüklemeye açık olup olmadığını söyler (taslak ya da incelemede).
func (s *Store) CanUploadDocument(ctx context.Context, accountID string) error {
	var st string
	if err := s.supplier(accountID).QueryRow(ctx, `SELECT status FROM mp_supplier_accounts WHERE id = $1`, accountID).Scan(&st); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return err
	}
	if st != "DRAFT" && st != "REVIEW" {
		return userErr(http.StatusConflict, "NOT_EDITABLE", "Belge yalnız taslak ya da incelemedeki hesaba yüklenebilir")
	}
	return nil
}

// AddDocument, yüklenmiş dosyanın kaydını yazar.
func (s *Store) AddDocument(ctx context.Context, accountID, userID string, d Document) (*Document, error) {
	return scanDocument(s.supplier(accountID).QueryRow(ctx, `
		INSERT INTO mp_account_documents (account_id, doc_type, file_name, content_type, size_bytes, sha256, storage_key, uploaded_by)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING `+documentCols,
		accountID, d.DocType, d.FileName, d.ContentType, d.SizeBytes, d.SHA256, d.StorageKey, userID))
}

// Documents, hesabın belgeleri.
func (s *Store) Documents(ctx context.Context, accountID string) ([]Document, error) {
	rows, err := s.supplier(accountID).Query(ctx, `SELECT `+documentCols+` FROM mp_account_documents
		WHERE account_id = $1 ORDER BY uploaded_at DESC`, accountID)
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

// DocumentForOwner, belgeyi sahibine verir ve erişimi kaydeder (kimlik belgesi kişisel veridir).
func (s *Store) DocumentForOwner(ctx context.Context, accountID, docID, userID string) (*Document, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	d, err := scanDocument(tx.QueryRow(ctx, `SELECT `+documentCols+` FROM mp_account_documents WHERE id = $1`, docID))
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO mp_document_access_logs (document_id, account_id, user_id, accessor)
		VALUES ($1, $2, $3, 'OWNER')`, docID, d.AccountID, userID); err != nil {
		return nil, err
	}
	return d, tx.Commit(ctx)
}

// DeleteDocument, yanlış yüklenen belgeyi siler: yalnız taslak hesapta ve henüz incelenmemiş belgede.
// Silinen satırın dosya anahtarı döner (çağıran depodan da siler).
func (s *Store) DeleteDocument(ctx context.Context, accountID, docID string) (string, error) {
	var key string
	err := s.supplier(accountID).QueryRow(ctx, `
		DELETE FROM mp_account_documents d USING mp_supplier_accounts a
		WHERE d.id = $1 AND a.id = d.account_id AND a.status = 'DRAFT' AND d.status = 'PENDING'
		  AND NOT EXISTS (SELECT 1 FROM mp_document_access_logs l WHERE l.document_id = d.id)
		RETURNING d.storage_key`, docID).Scan(&key)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", userErr(http.StatusConflict, "NOT_DELETABLE",
			"Belge silinemez: yalnız taslak hesapta, incelenmemiş ve hiç açılmamış belge silinebilir")
	}
	return key, err
}

// SubmitAccount, hesabı incelemeye gönderir. Eksikler birlikte söylenir.
func (s *Store) SubmitAccount(ctx context.Context, accountID string) (*Account, error) {
	a, err := s.Account(ctx, accountID)
	if err != nil {
		return nil, err
	}
	if a.Status != "DRAFT" {
		return nil, userErr(http.StatusConflict, "NOT_DRAFT", "Hesap zaten incelemede ya da sonuçlanmış")
	}
	docs, err := s.Documents(ctx, accountID)
	if err != nil {
		return nil, err
	}
	has := map[string]bool{}
	for _, d := range docs {
		if d.Status != "REJECTED" {
			has[d.DocType] = true
		}
	}
	missing := []string{}
	if a.TradeName == "" {
		missing = append(missing, "ticari unvan")
	}
	if a.TaxNumber == "" {
		missing = append(missing, "vergi numarası")
	}
	if a.TaxOffice == "" {
		missing = append(missing, "vergi dairesi")
	}
	if !has["TAX_PLATE"] && !has["CHAMBER_RECORD"] {
		missing = append(missing, "vergi levhası ya da oda kaydı belgesi")
	}
	if !has["ID_CARD"] {
		missing = append(missing, "kimlik belgesi")
	}
	if len(missing) > 0 {
		e := userErr(http.StatusUnprocessableEntity, "INCOMPLETE", "İncelemeye göndermek için eksikler: "+strings.Join(missing, ", "))
		return nil, e
	}
	if _, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_supplier_accounts SET status = 'REVIEW', status_reason = NULL,
		updated_at = now() WHERE id = $1 AND status = 'DRAFT'`, accountID); err != nil {
		return nil, err
	}
	return s.Account(ctx, accountID)
}

// Business, işletmedir (şube).
type Business struct {
	ID            string     `json:"id"`
	AccountID     string     `json:"account_id"`
	Name          string     `json:"name"`
	Description   string     `json:"description"`
	Phone         string     `json:"phone"`
	Address       string     `json:"address"`
	City          string     `json:"city"`
	District      string     `json:"district"`
	Latitude      float64    `json:"latitude"`
	Longitude     float64    `json:"longitude"`
	ServiceArea   string     `json:"service_area"`
	RadiusKm      *int       `json:"radius_km"`
	Status        string     `json:"status"`
	ReviewNote    *string    `json:"review_note"`
	ReviewedAt    *time.Time `json:"reviewed_at"`
	RatingCount   int        `json:"rating_count"`
	RatingSum     int        `json:"rating_sum"`
	CompletedJobs int        `json:"completed_jobs"`
	CategoryIDs   []string   `json:"category_ids"`
	CreatedAt     time.Time  `json:"created_at"`
}

const businessCols = `b.id, b.account_id, b.name, b.description, b.phone, b.address, b.city, b.district, b.latitude::float8,
	b.longitude::float8, b.service_area, b.radius_km, b.status, b.review_note, b.reviewed_at, b.rating_count, b.rating_sum,
	b.completed_jobs, COALESCE((SELECT array_agg(bc.category_id::text ORDER BY bc.category_id) FROM mp_business_categories bc
	WHERE bc.business_id = b.id), '{}'), b.created_at`

func scanBusiness(r pgx.Row) (*Business, error) {
	b := &Business{}
	err := r.Scan(&b.ID, &b.AccountID, &b.Name, &b.Description, &b.Phone, &b.Address, &b.City, &b.District, &b.Latitude,
		&b.Longitude, &b.ServiceArea, &b.RadiusKm, &b.Status, &b.ReviewNote, &b.ReviewedAt, &b.RatingCount, &b.RatingSum,
		&b.CompletedJobs, &b.CategoryIDs, &b.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return b, err
}

// BusinessInput, işletme bilgileridir.
type BusinessInput struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Phone       string   `json:"phone"`
	Address     string   `json:"address"`
	City        string   `json:"city"`
	District    string   `json:"district"`
	Latitude    *float64 `json:"latitude"`
	Longitude   *float64 `json:"longitude"`
	ServiceArea string   `json:"service_area"`
	RadiusKm    *int     `json:"radius_km"`
	CategoryIDs []string `json:"category_ids"`
}

func (in *BusinessInput) clean() error {
	in.Name, in.Address = strings.TrimSpace(in.Name), strings.TrimSpace(in.Address)
	in.City, in.District = strings.TrimSpace(in.City), strings.TrimSpace(in.District)
	in.Description, _ = rules.MaskContacts(strings.TrimSpace(in.Description))
	missing := []string{}
	for _, f := range []struct{ v, n string }{{in.Name, "işletme adı"}, {in.Address, "adres"}, {in.City, "il"}, {in.District, "ilçe"}} {
		if f.v == "" {
			missing = append(missing, f.n)
		}
	}
	if len(missing) > 0 {
		return userErr(http.StatusUnprocessableEntity, "FIELDS", "Zorunlu alanlar: "+strings.Join(missing, ", "))
	}
	p, err := phone.Normalize(in.Phone)
	if err != nil {
		return userErr(http.StatusUnprocessableEntity, "PHONE", "İşletme telefonu geçersiz")
	}
	in.Phone = p
	if in.Latitude == nil || in.Longitude == nil || *in.Latitude < -90 || *in.Latitude > 90 || *in.Longitude < -180 || *in.Longitude > 180 {
		return userErr(http.StatusUnprocessableEntity, "LOCATION", "Konum geçersiz: haritada işletmenin yerini seçin")
	}
	switch in.ServiceArea {
	case "KM":
		if in.RadiusKm == nil || *in.RadiusKm < 1 || *in.RadiusKm > 500 {
			return userErr(http.StatusUnprocessableEntity, "RADIUS", "Hizmet yarıçapı 1–500 km olmalı")
		}
	case "CITY", "COUNTRY":
		in.RadiusKm = nil
	default:
		return userErr(http.StatusUnprocessableEntity, "SERVICE_AREA", "Hizmet alanı KM, CITY ya da COUNTRY olmalı")
	}
	if len(in.CategoryIDs) == 0 {
		return userErr(http.StatusUnprocessableEntity, "CATEGORIES", "En az bir kategori seçin")
	}
	return nil
}

func (s *Store) writeCategories(ctx context.Context, tx pgx.Tx, accountID, businessID string, ids []string) error {
	var n int
	if err := tx.QueryRow(ctx, `SELECT count(*) FROM mp_categories WHERE id = ANY($1::uuid[]) AND is_active`, ids).Scan(&n); err != nil {
		return err
	}
	if n != len(uniq(ids)) {
		return userErr(http.StatusUnprocessableEntity, "CATEGORIES", "Seçilen kategorilerden biri yok ya da etkin değil")
	}
	if _, err := tx.Exec(ctx, `DELETE FROM mp_business_categories WHERE business_id = $1`, businessID); err != nil {
		return err
	}
	_, err := tx.Exec(ctx, `INSERT INTO mp_business_categories (business_id, category_id, account_id)
		SELECT $1, c, $2 FROM unnest($3::uuid[]) c ON CONFLICT DO NOTHING`, businessID, accountID, uniq(ids))
	return err
}

func uniq(ids []string) []string {
	seen := map[string]bool{}
	out := []string{}
	for _, id := range ids {
		if !seen[id] {
			seen[id] = true
			out = append(out, id)
		}
	}
	return out
}

// CreateBusiness, hesaba yeni işletme ekler (taslak).
func (s *Store) CreateBusiness(ctx context.Context, accountID string, in BusinessInput) (*Business, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var id string
	if err := tx.QueryRow(ctx, `INSERT INTO mp_businesses (account_id, name, description, phone, address, city, district,
		latitude, longitude, service_area, radius_km) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
		accountID, in.Name, in.Description, in.Phone, in.Address, in.City, in.District, in.Latitude, in.Longitude,
		in.ServiceArea, in.RadiusKm).Scan(&id); err != nil {
		return nil, err
	}
	if err := s.writeCategories(ctx, tx, accountID, id, in.CategoryIDs); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.Business(ctx, accountID, id)
}

// UpdateBusiness, işletmeyi günceller (kapatılmış işletme değişmez).
func (s *Store) UpdateBusiness(ctx context.Context, accountID, id string, in BusinessInput) (*Business, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	tag, err := tx.Exec(ctx, `UPDATE mp_businesses SET name=$3, description=$4, phone=$5, address=$6, city=$7, district=$8,
		latitude=$9, longitude=$10, service_area=$11, radius_km=$12, updated_at=now()
		WHERE id=$1 AND account_id=$2 AND status <> 'CLOSED'`, id, accountID, in.Name, in.Description, in.Phone, in.Address,
		in.City, in.District, in.Latitude, in.Longitude, in.ServiceArea, in.RadiusKm)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, s.businessMissingOrClosed(ctx, accountID, id)
	}
	if err := s.writeCategories(ctx, tx, accountID, id, in.CategoryIDs); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.Business(ctx, accountID, id)
}

func (s *Store) businessMissingOrClosed(ctx context.Context, accountID, id string) error {
	if ok, err := s.supplier(accountID).Exists(ctx, "mp_businesses", id); err != nil {
		return err
	} else if !ok {
		return ErrNotFound
	}
	return userErr(http.StatusConflict, "CLOSED", "Kapatılmış işletme değiştirilemez")
}

// Business, işletmeyi okur.
func (s *Store) Business(ctx context.Context, accountID, id string) (*Business, error) {
	return scanBusiness(s.supplier(accountID).QueryRow(ctx, `SELECT `+businessCols+` FROM mp_businesses b WHERE b.id = $1`, id))
}

// Businesses, hesabın işletmeleri.
func (s *Store) Businesses(ctx context.Context, accountID string) ([]Business, error) {
	rows, err := s.supplier(accountID).Query(ctx, `SELECT `+businessCols+` FROM mp_businesses b WHERE b.account_id = $1
		ORDER BY b.created_at`, accountID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Business{}
	for rows.Next() {
		b, err := scanBusiness(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *b)
	}
	return out, rows.Err()
}

// SetBusinessStatus, tedarikçinin işletme durum geçişidir: incelemeye gönder (taslak/reddedilmiş → inceleme) ya da kapat.
func (s *Store) SetBusinessStatus(ctx context.Context, accountID, id, action string) (*Business, error) {
	var q string
	switch action {
	case "submit":
		q = `UPDATE mp_businesses SET status = 'REVIEW', review_note = NULL, updated_at = now()
			WHERE id = $1 AND status IN ('DRAFT', 'REJECTED')`
	case "close":
		q = `UPDATE mp_businesses SET status = 'CLOSED', updated_at = now() WHERE id = $1 AND status <> 'CLOSED'`
	default:
		return nil, fmt.Errorf("bilinmeyen işlem %q", action)
	}
	tag, err := s.supplier(accountID).Exec(ctx, q, id)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		if ok, err := s.supplier(accountID).Exists(ctx, "mp_businesses", id); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrNotFound
		}
		if action == "submit" {
			return nil, userErr(http.StatusConflict, "NOT_DRAFT", "İşletme zaten incelemede, yayında ya da kapalı")
		}
		return nil, userErr(http.StatusConflict, "CLOSED", "İşletme zaten kapalı")
	}
	return s.Business(ctx, accountID, id)
}

// Service, işletmenin hizmet/ürün kalemidir.
type Service struct {
	ID            string  `json:"id"`
	BusinessID    string  `json:"business_id"`
	Name          string  `json:"name"`
	Description   string  `json:"description"`
	PriceMinKurus *int64  `json:"price_min_kurus"`
	PriceMaxKurus *int64  `json:"price_max_kurus"`
	Unit          string  `json:"unit"`
	PhotoKey      *string `json:"-"`
	HasPhoto      bool    `json:"has_photo"`
	IsActive      bool    `json:"is_active"`
	SortOrder     int     `json:"sort_order"`
}

const serviceCols = `id, business_id, name, description, price_min_kurus, price_max_kurus, unit, photo_key, is_active, sort_order`

func scanService(r pgx.Row) (*Service, error) {
	x := &Service{}
	err := r.Scan(&x.ID, &x.BusinessID, &x.Name, &x.Description, &x.PriceMinKurus, &x.PriceMaxKurus, &x.Unit, &x.PhotoKey,
		&x.IsActive, &x.SortOrder)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	x.HasPhoto = x.PhotoKey != nil
	return x, err
}

// ServiceInput, hizmet kalemi bilgileridir. Fiyat ya aralıktır ya "teklifle" (ikisi de boş).
type ServiceInput struct {
	Name          string `json:"name"`
	Description   string `json:"description"`
	PriceMinKurus *int64 `json:"price_min_kurus"`
	PriceMaxKurus *int64 `json:"price_max_kurus"`
	Unit          string `json:"unit"`
	IsActive      *bool  `json:"is_active"`
	SortOrder     int    `json:"sort_order"`
}

func (in *ServiceInput) clean() error {
	in.Name, in.Unit = strings.TrimSpace(in.Name), strings.TrimSpace(in.Unit)
	in.Description, _ = rules.MaskContacts(strings.TrimSpace(in.Description))
	if in.Name == "" {
		return userErr(http.StatusUnprocessableEntity, "FIELDS", "Hizmet adı zorunludur")
	}
	if (in.PriceMinKurus == nil) != (in.PriceMaxKurus == nil) {
		return userErr(http.StatusUnprocessableEntity, "PRICE", "Fiyat aralığının iki ucu birlikte verilmeli (teklifle verilecekse ikisi de boş)")
	}
	if in.PriceMinKurus != nil && (*in.PriceMinKurus < 0 || *in.PriceMinKurus > *in.PriceMaxKurus) {
		return userErr(http.StatusUnprocessableEntity, "PRICE", "Alt fiyat üst fiyattan büyük olamaz")
	}
	if in.IsActive == nil {
		t := true
		in.IsActive = &t
	}
	return nil
}

// Services, işletmenin hizmet kalemleri.
func (s *Store) Services(ctx context.Context, accountID, businessID string) ([]Service, error) {
	if _, err := s.Business(ctx, accountID, businessID); err != nil {
		return nil, err
	}
	rows, err := s.supplier(accountID).Query(ctx, `SELECT `+serviceCols+` FROM mp_business_services WHERE business_id = $1
		ORDER BY sort_order, name`, businessID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Service{}
	for rows.Next() {
		x, err := scanService(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

// CreateService, işletmeye hizmet kalemi ekler.
func (s *Store) CreateService(ctx context.Context, accountID, businessID string, in ServiceInput) (*Service, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	if _, err := s.Business(ctx, accountID, businessID); err != nil {
		return nil, err
	}
	return scanService(s.supplier(accountID).QueryRow(ctx, `INSERT INTO mp_business_services (business_id, account_id, name,
		description, price_min_kurus, price_max_kurus, unit, is_active, sort_order) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
		RETURNING `+serviceCols, businessID, accountID, in.Name, in.Description, in.PriceMinKurus, in.PriceMaxKurus, in.Unit,
		*in.IsActive, in.SortOrder))
}

// UpdateService, hizmet kalemini günceller.
func (s *Store) UpdateService(ctx context.Context, accountID, id string, in ServiceInput) (*Service, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	return scanService(s.supplier(accountID).QueryRow(ctx, `UPDATE mp_business_services SET name=$2, description=$3,
		price_min_kurus=$4, price_max_kurus=$5, unit=$6, is_active=$7, sort_order=$8, updated_at=now() WHERE id=$1
		RETURNING `+serviceCols, id, in.Name, in.Description, in.PriceMinKurus, in.PriceMaxKurus, in.Unit, *in.IsActive, in.SortOrder))
}

// DeleteService, hizmet kalemini siler; fotoğraf anahtarı döner.
func (s *Store) DeleteService(ctx context.Context, accountID, id string) (*string, error) {
	var key *string
	err := s.supplier(accountID).QueryRow(ctx, `DELETE FROM mp_business_services WHERE id = $1 RETURNING photo_key`, id).Scan(&key)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return key, err
}

// SetServicePhoto, hizmet fotoğrafının anahtarını yazar; önceki anahtar döner (çağıran depodan siler).
func (s *Store) SetServicePhoto(ctx context.Context, accountID, id, key string) (*string, error) {
	var old *string
	err := s.supplier(accountID).QueryRow(ctx, `UPDATE mp_business_services x SET photo_key = $2, updated_at = now()
		FROM (SELECT photo_key FROM mp_business_services WHERE id = $1) prev WHERE x.id = $1 RETURNING prev.photo_key`, id, key).Scan(&old)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return old, err
}

// ServicePhotoKey, yayındaki (vitrinde görünen) hizmetin fotoğraf anahtarı — herkes görebilir; ya da sahibinin kendi kalemi.
func (s *Store) ServicePhotoKey(ctx context.Context, accountID, id string) (string, error) {
	var key *string
	err := s.pool.QueryRow(ctx, `SELECT photo_key FROM mp_business_services_public WHERE id = $1`, id).Scan(&key)
	if errors.Is(err, pgx.ErrNoRows) && accountID != "" {
		err = s.supplier(accountID).QueryRow(ctx, `SELECT photo_key FROM mp_business_services WHERE id = $1`, id).Scan(&key)
	}
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && key == nil) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", err
	}
	return *key, nil
}
