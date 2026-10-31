package store

// Platform yönetimi (FAZ M4): hesap belge onayı, işletme yayın onayı, kategori, paket, ayar. Platform kapsamında
// (dbscope.ForPlatform) çalışır; değer işlemi yapan yöneticinin kimliğidir. Talep iletişim bilgisi ve mesajlar
// platforma KAPALIDIR (077 politikaları).

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

// AccountReview, inceleme kuyruğundaki hesaptır (kişi bilgisiyle).
type AccountReview struct {
	Account
	OwnerName     string     `json:"owner_name"`
	OwnerPhone    string     `json:"owner_phone"`
	OwnerEmail    string     `json:"owner_email"`
	DocumentCount int        `json:"document_count"`
	BusinessCount int        `json:"business_count"`
	UpdatedAt     *time.Time `json:"updated_at"`
}

// PlatformAccounts, hesapları duruma göre listeler (boşsa hepsi).
func (s *Store) PlatformAccounts(ctx context.Context, adminID, status string) ([]AccountReview, error) {
	rows, err := s.platform(adminID).Query(ctx, accountSelectReview+`
		WHERE ($1 = '' OR a.status = $1) ORDER BY a.updated_at DESC LIMIT 500`, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []AccountReview{}
	for rows.Next() {
		r, err := scanAccountReview(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *r)
	}
	return out, rows.Err()
}

const accountSelectReview = `SELECT a.id, a.user_id, a.trade_name, a.tax_number, a.tax_office, a.status, a.status_reason, a.reviewed_at,
	p.id, p.name, p.monthly_fee_kurus, p.fee_discount_pct, p.included_requests, p.monthly_sms, p.priority_access,
	p.phone_in_showcase, p.rank_weight, p.is_default, p.is_active, p.sort_order,
	a.next_package_id, a.package_renews_at, a.period_included_left, a.period_sms_left, a.balance_kurus,
	a.terms_accepted_at, a.created_at,
	u.first_name || ' ' || u.last_name, u.phone, COALESCE(u.email, ''),
	(SELECT count(*) FROM mp_account_documents d WHERE d.account_id = a.id)::int,
	(SELECT count(*) FROM mp_businesses b WHERE b.account_id = a.id)::int, a.updated_at
	FROM mp_supplier_accounts a JOIN mp_packages p ON p.id = a.package_id JOIN users u ON u.id = a.user_id`

func scanAccountReview(r pgx.Row) (*AccountReview, error) {
	x := &AccountReview{}
	a, p := &x.Account, &x.Account.Package
	err := r.Scan(&a.ID, &a.UserID, &a.TradeName, &a.TaxNumber, &a.TaxOffice, &a.Status, &a.StatusReason, &a.ReviewedAt,
		&p.ID, &p.Name, &p.MonthlyFeeKurus, &p.FeeDiscountPct, &p.IncludedRequests, &p.MonthlySMS, &p.PriorityAccess,
		&p.PhoneInShowcase, &p.RankWeight, &p.IsDefault, &p.IsActive, &p.SortOrder,
		&a.NextPackageID, &a.PackageRenewsAt, &a.PeriodIncludedLeft, &a.PeriodSMSLeft, &a.BalanceKurus,
		&a.TermsAcceptedAt, &a.CreatedAt, &x.OwnerName, &x.OwnerPhone, &x.OwnerEmail, &x.DocumentCount, &x.BusinessCount, &x.UpdatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return x, err
}

// PlatformAccount, hesap ayrıntısı: kişi, belgeler, işletmeler.
func (s *Store) PlatformAccount(ctx context.Context, adminID, id string) (*AccountReview, []Document, []Business, error) {
	sc := s.platform(adminID)
	acc, err := scanAccountReview(sc.QueryRow(ctx, accountSelectReview+` WHERE a.id = $1`, id))
	if err != nil {
		return nil, nil, nil, err
	}
	docs := []Document{}
	rows, err := sc.Query(ctx, `SELECT `+documentCols+` FROM mp_account_documents WHERE account_id = $1 ORDER BY uploaded_at`, id)
	if err != nil {
		return nil, nil, nil, err
	}
	for rows.Next() {
		d, err := scanDocument(rows)
		if err != nil {
			rows.Close()
			return nil, nil, nil, err
		}
		docs = append(docs, *d)
	}
	rows.Close()
	biz, err := s.platformBusinesses(ctx, adminID, `b.account_id = $1`, id)
	return acc, docs, biz, err
}

func (s *Store) platformBusinesses(ctx context.Context, adminID, where string, arg any) ([]Business, error) {
	rows, err := s.platform(adminID).Query(ctx, `SELECT `+businessCols+` FROM mp_businesses b WHERE `+where+` ORDER BY b.updated_at DESC LIMIT 500`, arg)
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

// PlatformDocument, belgeyi platform yöneticisine verir ve erişimi kaydeder.
func (s *Store) PlatformDocument(ctx context.Context, adminID, docID string) (*Document, error) {
	tx, err := s.platform(adminID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	d, err := scanDocument(tx.QueryRow(ctx, `SELECT `+documentCols+` FROM mp_account_documents WHERE id = $1`, docID))
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO mp_document_access_logs (document_id, account_id, user_id, accessor)
		VALUES ($1, $2, $3, 'PLATFORM')`, docID, d.AccountID, adminID); err != nil {
		return nil, err
	}
	return d, tx.Commit(ctx)
}

// ReviewAccount, hesabın inceleme kararıdır: approve (REVIEW→APPROVED, bekleyen belgeler onaylanır),
// reject (REVIEW→DRAFT, gerekçe zorunlu; seçilen belgeler reddedilir), suspend (APPROVED→SUSPENDED, gerekçe),
// reinstate (SUSPENDED→APPROVED).
func (s *Store) ReviewAccount(ctx context.Context, adminID, id, action, reason string, rejectDocs []string) (*AccountReview, error) {
	reason = strings.TrimSpace(reason)
	if (action == "reject" || action == "suspend") && len([]rune(reason)) < 5 {
		return nil, userErr(http.StatusUnprocessableEntity, "REASON", "Gerekçe zorunludur (en az 5 karakter); tedarikçiye gösterilir")
	}
	from, to := map[string][2]string{
		"approve": {"REVIEW", "APPROVED"}, "reject": {"REVIEW", "DRAFT"},
		"suspend": {"APPROVED", "SUSPENDED"}, "reinstate": {"SUSPENDED", "APPROVED"},
	}[action][0], map[string][2]string{
		"approve": {"REVIEW", "APPROVED"}, "reject": {"REVIEW", "DRAFT"},
		"suspend": {"APPROVED", "SUSPENDED"}, "reinstate": {"SUSPENDED", "APPROVED"},
	}[action][1]
	if from == "" {
		return nil, errors.New("bilinmeyen inceleme işlemi " + action)
	}
	tx, err := s.platform(adminID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	tag, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET status = $3, status_reason = NULLIF($4, ''), reviewed_by = $2,
		reviewed_at = now(), updated_at = now() WHERE id = $1 AND status = $5`, id, adminID, to, reason, from)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		if ok, err := s.platform(adminID).Exists(ctx, "mp_supplier_accounts", id); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrNotFound
		}
		return nil, userErr(http.StatusConflict, "STATE", "Hesap bu işlem için uygun durumda değil")
	}
	switch action {
	case "approve":
		if _, err := tx.Exec(ctx, `UPDATE mp_account_documents SET status = 'APPROVED', reviewed_by = $2, reviewed_at = now()
			WHERE account_id = $1 AND status = 'PENDING'`, id, adminID); err != nil {
			return nil, err
		}
	case "reject":
		if len(rejectDocs) > 0 {
			if _, err := tx.Exec(ctx, `UPDATE mp_account_documents SET status = 'REJECTED', review_note = $3, reviewed_by = $2,
				reviewed_at = now() WHERE account_id = $1 AND id = ANY($4::uuid[])`, id, adminID, reason, rejectDocs); err != nil {
				return nil, err
			}
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return scanAccountReview(s.platform(adminID).QueryRow(ctx, accountSelectReview+` WHERE a.id = $1`, id))
}

// PlatformBusinesses, işletmeleri duruma göre listeler.
func (s *Store) PlatformBusinesses(ctx context.Context, adminID, status string) ([]Business, error) {
	return s.platformBusinesses(ctx, adminID, `($1 = '' OR b.status = $1)`, status)
}

// ReviewBusiness, işletme yayın kararıdır: approve (REVIEW→PUBLISHED; hesap onaylı olmalı) ya da reject (gerekçe).
func (s *Store) ReviewBusiness(ctx context.Context, adminID, id, action, reason string) (*Business, error) {
	reason = strings.TrimSpace(reason)
	sc := s.platform(adminID)
	var accStatus, bStatus string
	err := sc.QueryRow(ctx, `SELECT a.status, b.status FROM mp_businesses b JOIN mp_supplier_accounts a ON a.id = b.account_id
		WHERE b.id = $1`, id).Scan(&accStatus, &bStatus)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if bStatus != "REVIEW" {
		return nil, userErr(http.StatusConflict, "STATE", "İşletme incelemede değil")
	}
	var to string
	switch action {
	case "approve":
		if accStatus != "APPROVED" {
			return nil, userErr(http.StatusConflict, "ACCOUNT_NOT_APPROVED", "Önce tedarikçi hesabının belgeleri onaylanmalı")
		}
		to = "PUBLISHED"
	case "reject":
		if len([]rune(reason)) < 5 {
			return nil, userErr(http.StatusUnprocessableEntity, "REASON", "Gerekçe zorunludur (en az 5 karakter); tedarikçiye gösterilir")
		}
		to = "REJECTED"
	default:
		return nil, errors.New("bilinmeyen inceleme işlemi " + action)
	}
	if _, err := sc.Exec(ctx, `UPDATE mp_businesses SET status = $3, review_note = NULLIF($4, ''), reviewed_by = $2,
		reviewed_at = now(), updated_at = now() WHERE id = $1 AND status = 'REVIEW'`, id, adminID, to, reason); err != nil {
		return nil, err
	}
	return scanBusiness(sc.QueryRow(ctx, `SELECT `+businessCols+` FROM mp_businesses b WHERE b.id = $1`, id))
}

// AllCategories, platform için bütün kategoriler (pasifler dahil).
func (s *Store) AllCategories(ctx context.Context, adminID string) ([]Category, error) {
	return s.categories(ctx, s.platform(adminID), false)
}

// CategoryInput, kategori bilgileridir.
type CategoryInput struct {
	ParentID        *string `json:"parent_id"`
	Name            string  `json:"name"`
	RequestFeeKurus int64   `json:"request_fee_kurus"`
	BuyerScope      string  `json:"buyer_scope"`
	IsActive        *bool   `json:"is_active"`
	SortOrder       int     `json:"sort_order"`
}

func (in *CategoryInput) clean() error {
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" {
		return userErr(http.StatusUnprocessableEntity, "FIELDS", "Kategori adı zorunludur")
	}
	if in.RequestFeeKurus < 0 {
		return userErr(http.StatusUnprocessableEntity, "FEE", "Talep ücreti eksi olamaz")
	}
	switch in.BuyerScope {
	case "RESIDENT", "MANAGEMENT", "BOTH":
	default:
		return userErr(http.StatusUnprocessableEntity, "SCOPE", "Kimin talep açabileceği RESIDENT, MANAGEMENT ya da BOTH olmalı")
	}
	if in.IsActive == nil {
		t := true
		in.IsActive = &t
	}
	if in.ParentID != nil && *in.ParentID == "" {
		in.ParentID = nil
	}
	return nil
}

// SaveCategory, kategori ekler (id boş) ya da günceller.
func (s *Store) SaveCategory(ctx context.Context, adminID, id string, in CategoryInput) (*Category, error) {
	if err := in.clean(); err != nil {
		return nil, err
	}
	sc := s.platform(adminID)
	if id == "" {
		c, err := scanCategory(sc.QueryRow(ctx, `INSERT INTO mp_categories (parent_id, name, request_fee_kurus, buyer_scope, is_active, sort_order)
			VALUES ($1,$2,$3,$4,$5,$6) RETURNING `+categoryCols, in.ParentID, in.Name, in.RequestFeeKurus, in.BuyerScope, *in.IsActive, in.SortOrder))
		return &c, err
	}
	if in.ParentID != nil && *in.ParentID == id {
		return nil, userErr(http.StatusUnprocessableEntity, "PARENT", "Kategori kendi altında olamaz")
	}
	c, err := scanCategory(sc.QueryRow(ctx, `UPDATE mp_categories SET parent_id=$2, name=$3, request_fee_kurus=$4, buyer_scope=$5,
		is_active=$6, sort_order=$7, updated_at=now() WHERE id=$1 RETURNING `+categoryCols,
		id, in.ParentID, in.Name, in.RequestFeeKurus, in.BuyerScope, *in.IsActive, in.SortOrder))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return &c, err
}

// AllPackages, platform için bütün paketler.
func (s *Store) AllPackages(ctx context.Context, adminID string) ([]Package, error) {
	return s.packages(ctx, s.platform(adminID), false)
}

// SavePackage, paket ekler ya da günceller. Fiyat değişikliği mevcut abonelere bir sonraki yenilemede uygulanır
// (aidat yenileme anında paketin o anki fiyatından alınır).
func (s *Store) SavePackage(ctx context.Context, adminID, id string, in Package) (*Package, error) {
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" || in.MonthlyFeeKurus < 0 || in.FeeDiscountPct < 0 || in.FeeDiscountPct > 100 || in.IncludedRequests < 0 ||
		in.MonthlySMS < 0 || in.RankWeight < 0 {
		return nil, userErr(http.StatusUnprocessableEntity, "FIELDS", "Paket adı zorunlu; ücret, indirim (0–100), dahil talep, SMS ve ağırlık eksi olamaz")
	}
	sc := s.platform(adminID)
	var p Package
	var err error
	if id == "" {
		p, err = scanPackage(sc.QueryRow(ctx, `INSERT INTO mp_packages (name, monthly_fee_kurus, fee_discount_pct, included_requests,
			monthly_sms, priority_access, phone_in_showcase, rank_weight, is_active, sort_order)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING `+packageCols, in.Name, in.MonthlyFeeKurus, in.FeeDiscountPct,
			in.IncludedRequests, in.MonthlySMS, in.PriorityAccess, in.PhoneInShowcase, in.RankWeight, in.IsActive, in.SortOrder))
	} else {
		p, err = scanPackage(sc.QueryRow(ctx, `UPDATE mp_packages SET name=$2, monthly_fee_kurus=$3, fee_discount_pct=$4,
			included_requests=$5, monthly_sms=$6, priority_access=$7, phone_in_showcase=$8, rank_weight=$9,
			is_active = CASE WHEN is_default THEN true ELSE $10 END, sort_order=$11, updated_at=now()
			WHERE id=$1 RETURNING `+packageCols, id, in.Name, in.MonthlyFeeKurus, in.FeeDiscountPct, in.IncludedRequests,
			in.MonthlySMS, in.PriorityAccess, in.PhoneInShowcase, in.RankWeight, in.IsActive, in.SortOrder))
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
	}
	return &p, err
}

// SaveSetting, bir ayarın değerini değiştirir (yeni anahtar eklenmez; anahtarlar migration ile tanımlıdır).
func (s *Store) SaveSetting(ctx context.Context, adminID, key string, value int) (*Setting, error) {
	if value < 0 {
		return nil, userErr(http.StatusUnprocessableEntity, "VALUE", "Değer eksi olamaz")
	}
	if key == "max_accepts_per_request" && value < 1 {
		return nil, userErr(http.StatusUnprocessableEntity, "VALUE", "Bir talebi en az bir tedarikçi kabul edebilmeli")
	}
	x := &Setting{}
	err := s.platform(adminID).QueryRow(ctx, `UPDATE mp_settings SET value_int = $2, updated_by = $3, updated_at = now()
		WHERE key = $1 RETURNING key, value_int, description`, key, value, adminID).Scan(&x.Key, &x.Value, &x.Description)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return x, err
}

// SupplierContact, tedarikçi hesabı sahibinin bildirim adresleridir (platform ya da tedarikçi kapsamında okunur).
type SupplierContact struct {
	AccountID, UserID, Phone, Email string
}

// AccountContact, hesabın sahibinin iletişim adresleri.
func (s *Store) AccountContact(ctx context.Context, adminID, accountID string) (*SupplierContact, error) {
	sc := s.supplier(accountID)
	if adminID != "" {
		sc = s.platform(adminID)
	}
	x := &SupplierContact{AccountID: accountID}
	err := sc.QueryRow(ctx, `SELECT u.id, u.phone, COALESCE(u.email, '') FROM mp_supplier_accounts a JOIN users u ON u.id = a.user_id
		WHERE a.id = $1`, accountID).Scan(&x.UserID, &x.Phone, &x.Email)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return x, err
}
