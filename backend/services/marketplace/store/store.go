// Package store, pazaryeri veritabanı erişimidir (077). Her sorgu bir kapsam içinde çalışır:
// site (dbscope.For), tedarikçi hesabı (dbscope.ForSupplier) ya da platform (dbscope.ForPlatform).
package store

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// ErrNotFound: kayıt yok ya da kapsam dışında (varlığı sızdırılmaz).
var ErrNotFound = errors.New("kayıt bulunamadı")

// UserError, istemcinin düzeltebileceği bir durumdur (HTTP durumu ve açıklamasıyla).
type UserError struct {
	Status        int
	Message, Code string
	Note          string
}

func (e *UserError) Error() string { return e.Message }

func userErr(status int, code, msg string) *UserError {
	return &UserError{Status: status, Code: code, Message: msg}
}

// Store, pazaryeri deposudur.
type Store struct {
	pool *pgxpool.Pool
	// now, zaman kaynağıdır (zamanlayıcı işleri ve sınamalar için tek yerden).
	now func() time.Time
}

// New, depo kurar.
func New(pool *pgxpool.Pool) *Store { return &Store{pool: pool, now: time.Now} }

func (s *Store) supplier(accountID string) *dbscope.Scoped {
	return dbscope.ForSupplier(s.pool, accountID)
}
func (s *Store) site(propertyID string) *dbscope.Scoped { return dbscope.For(s.pool, propertyID) }
func (s *Store) platform(userID string) *dbscope.Scoped { return dbscope.ForPlatform(s.pool, userID) }

// Setting, ayar tablosundaki tam sayı değeridir.
type Setting struct {
	Key         string `json:"key"`
	Value       int    `json:"value"`
	Description string `json:"description"`
}

// Category, talep kategorisidir.
type Category struct {
	ID              string  `json:"id"`
	ParentID        *string `json:"parent_id"`
	Name            string  `json:"name"`
	RequestFeeKurus int64   `json:"request_fee_kurus"`
	BuyerScope      string  `json:"buyer_scope"`
	IsActive        bool    `json:"is_active"`
	SortOrder       int     `json:"sort_order"`
}

// Package, tedarikçi paketidir.
type Package struct {
	ID               string `json:"id"`
	Name             string `json:"name"`
	MonthlyFeeKurus  int64  `json:"monthly_fee_kurus"`
	FeeDiscountPct   int    `json:"fee_discount_pct"`
	IncludedRequests int    `json:"included_requests"`
	MonthlySMS       int    `json:"monthly_sms"`
	PriorityAccess   bool   `json:"priority_access"`
	PhoneInShowcase  bool   `json:"phone_in_showcase"`
	RankWeight       int    `json:"rank_weight"`
	IsDefault        bool   `json:"is_default"`
	IsActive         bool   `json:"is_active"`
	SortOrder        int    `json:"sort_order"`
}

// MetaInfo, istemcilerin ihtiyaç duyduğu sabit olmayan pazaryeri bilgileridir.
type MetaInfo struct {
	Settings   []Setting  `json:"settings"`
	Categories []Category `json:"categories"`
	Packages   []Package  `json:"packages"`
}

const categoryCols = `id, parent_id, name, request_fee_kurus, buyer_scope, is_active, sort_order`
const packageCols = `id, name, monthly_fee_kurus, fee_discount_pct, included_requests, monthly_sms, priority_access,
	phone_in_showcase, rank_weight, is_default, is_active, sort_order`

func scanCategory(r pgx.Row) (Category, error) {
	var x Category
	err := r.Scan(&x.ID, &x.ParentID, &x.Name, &x.RequestFeeKurus, &x.BuyerScope, &x.IsActive, &x.SortOrder)
	return x, err
}

func scanPackage(r pgx.Row) (Package, error) {
	var x Package
	err := r.Scan(&x.ID, &x.Name, &x.MonthlyFeeKurus, &x.FeeDiscountPct, &x.IncludedRequests, &x.MonthlySMS,
		&x.PriorityAccess, &x.PhoneInShowcase, &x.RankWeight, &x.IsDefault, &x.IsActive, &x.SortOrder)
	return x, err
}

// Meta, ayarları ve etkin kategori/paketleri okur (bu tablolar her kapsamda okunur; kapsamsız havuzla).
func (s *Store) Meta(ctx context.Context) (*MetaInfo, error) {
	m := &MetaInfo{Settings: []Setting{}, Categories: []Category{}, Packages: []Package{}}
	rows, err := s.pool.Query(ctx, `SELECT key, value_int, description FROM mp_settings ORDER BY key`)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var x Setting
		if err := rows.Scan(&x.Key, &x.Value, &x.Description); err != nil {
			rows.Close()
			return nil, err
		}
		m.Settings = append(m.Settings, x)
	}
	rows.Close()
	if m.Categories, err = s.categories(ctx, s.pool, true); err != nil {
		return nil, err
	}
	if m.Packages, err = s.packages(ctx, s.pool, true); err != nil {
		return nil, err
	}
	return m, nil
}

type querier interface {
	Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error)
}

func (s *Store) categories(ctx context.Context, q querier, activeOnly bool) ([]Category, error) {
	rows, err := q.Query(ctx, `SELECT `+categoryCols+` FROM mp_categories WHERE is_active OR NOT $1
		ORDER BY sort_order, name`, activeOnly)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Category{}
	for rows.Next() {
		x, err := scanCategory(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

func (s *Store) packages(ctx context.Context, q querier, activeOnly bool) ([]Package, error) {
	rows, err := q.Query(ctx, `SELECT `+packageCols+` FROM mp_packages WHERE is_active OR NOT $1
		ORDER BY sort_order, monthly_fee_kurus`, activeOnly)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Package{}
	for rows.Next() {
		x, err := scanPackage(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, x)
	}
	return out, rows.Err()
}

// SettingValue, tek bir ayarı okur (dışa açık).
func (s *Store) SettingValue(ctx context.Context, key string) (int, error) {
	return s.setting(ctx, key)
}

// Setting, tek bir ayarı okur; tanımlı değilse hata döner (varsayılan değer TAHMİN EDİLMEZ).
func (s *Store) setting(ctx context.Context, key string) (int, error) {
	var v int
	err := s.pool.QueryRow(ctx, `SELECT value_int FROM mp_settings WHERE key = $1`, key).Scan(&v)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, userErr(http.StatusInternalServerError, "SETTING_MISSING", "Pazaryeri ayarı tanımlı değil: "+key)
	}
	return v, err
}

// Account, tedarikçi hesabıdır (paket bilgisiyle).
type Account struct {
	ID                 string     `json:"id"`
	UserID             string     `json:"user_id"`
	TradeName          string     `json:"trade_name"`
	TaxNumber          string     `json:"tax_number"`
	TaxOffice          string     `json:"tax_office"`
	Status             string     `json:"status"`
	StatusReason       *string    `json:"status_reason"`
	ReviewedAt         *time.Time `json:"reviewed_at"`
	Package            Package    `json:"package"`
	NextPackageID      *string    `json:"next_package_id"`
	PackageRenewsAt    *time.Time `json:"package_renews_at"`
	PeriodIncludedLeft int        `json:"period_included_left"`
	PeriodSMSLeft      int        `json:"period_sms_left"`
	BalanceKurus       int64      `json:"balance_kurus"`
	TermsAcceptedAt    time.Time  `json:"terms_accepted_at"`
	CreatedAt          time.Time  `json:"created_at"`
}

const accountSelect = `SELECT a.id, a.user_id, a.trade_name, a.tax_number, a.tax_office, a.status, a.status_reason, a.reviewed_at,
	p.id, p.name, p.monthly_fee_kurus, p.fee_discount_pct, p.included_requests, p.monthly_sms, p.priority_access,
	p.phone_in_showcase, p.rank_weight, p.is_default, p.is_active, p.sort_order,
	a.next_package_id, a.package_renews_at, a.period_included_left, a.period_sms_left, a.balance_kurus,
	a.terms_accepted_at, a.created_at
	FROM mp_supplier_accounts a JOIN mp_packages p ON p.id = a.package_id`

func scanAccount(r pgx.Row) (*Account, error) {
	a := &Account{}
	p := &a.Package
	err := r.Scan(&a.ID, &a.UserID, &a.TradeName, &a.TaxNumber, &a.TaxOffice, &a.Status, &a.StatusReason, &a.ReviewedAt,
		&p.ID, &p.Name, &p.MonthlyFeeKurus, &p.FeeDiscountPct, &p.IncludedRequests, &p.MonthlySMS, &p.PriorityAccess,
		&p.PhoneInShowcase, &p.RankWeight, &p.IsDefault, &p.IsActive, &p.SortOrder,
		&a.NextPackageID, &a.PackageRenewsAt, &a.PeriodIncludedLeft, &a.PeriodSMSLeft, &a.BalanceKurus,
		&a.TermsAcceptedAt, &a.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return a, err
}

// AccountIDOfUser, kişinin tedarikçi hesabının kimliğini döner (yoksa boş).
func (s *Store) AccountIDOfUser(ctx context.Context, userID string) (string, error) {
	var id *string
	if err := s.pool.QueryRow(ctx, `SELECT mp_account_of_user($1)::text`, userID).Scan(&id); err != nil {
		return "", err
	}
	if id == nil {
		return "", nil
	}
	return *id, nil
}

// AccountOfUser, kişinin tedarikçi hesabını döner; hesap yoksa (nil, nil).
func (s *Store) AccountOfUser(ctx context.Context, userID string) (*Account, error) {
	id, err := s.AccountIDOfUser(ctx, userID)
	if err != nil || id == "" {
		return nil, err
	}
	return scanAccount(s.supplier(id).QueryRow(ctx, accountSelect+` WHERE a.id = $1`, id))
}

// UserName, hesabın sahibinin adı ve soyadı (tedarikçi kapsamında).
func (s *Store) UserName(ctx context.Context, accountID, userID string) ([2]string, error) {
	var n [2]string
	err := s.supplier(accountID).QueryRow(ctx, `SELECT first_name, last_name FROM users WHERE id = $1`, userID).Scan(&n[0], &n[1])
	return n, err
}

// TryJobsLock, zamanlı işler için oturum düzeyinde danışma kilidi alır (tek kopya çalışsın). Alınamazsa ok=false.
// Kilit aynı bağlantıda bırakılmalıdır; dönen işlev kilidi bırakır ve bağlantıyı havuza iade eder.
func (s *Store) TryJobsLock(ctx context.Context, key int64) (func(), bool, error) {
	conn, err := s.pool.Acquire(ctx)
	if err != nil {
		return nil, false, err
	}
	var ok bool
	if err := conn.QueryRow(ctx, `SELECT pg_try_advisory_lock($1)`, key).Scan(&ok); err != nil || !ok {
		conn.Release()
		return nil, false, err
	}
	return func() {
		_, _ = conn.Exec(context.Background(), `SELECT pg_advisory_unlock($1)`, key)
		conn.Release()
	}, true, nil
}
