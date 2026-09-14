// Package repository, sözleşme yönetimi modülünün veritabanı işlemlerini içerir.
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
	ErrNotFound     = errors.New("kayıt bulunamadı")
	ErrBadState     = errors.New("sözleşme bu işlem için uygun durumda değil")
	ErrNoRenewal    = errors.New("sözleşmede yenileme süresi tanımlı değil")
	ErrMaxRenewals  = errors.New("azami yenileme sayısına ulaşıldı")
	ErrInvalidDates = errors.New("tarih geçersiz")
	ErrInvalidType  = errors.New("geçersiz sözleşme türü")
)

// ValidTypes, şemadaki CHECK kısıtıyla birebir aynıdır. Koddaki liste ile
// veritabanındaki kısıt ayrışırsa kullanıcı anlamsız bir 500 görür.
var ValidTypes = []string{"RENTAL", "SERVICE", "MAINTENANCE", "EMPLOYMENT", "INSURANCE", "OTHER"}

// Contract, bir sözleşme kaydıdır.
type Contract struct {
	ID             string `json:"id"`
	ContractType   string `json:"contract_type"`
	Title          string `json:"title"`
	Description    string `json:"description,omitempty"`
	ContractNumber string `json:"contract_number,omitempty"`

	PartyName          string `json:"party_name"`
	PartyType          string `json:"party_type,omitempty"`
	PartyTaxID         string `json:"party_tax_id,omitempty"`
	PartyPhone         string `json:"party_phone,omitempty"`
	PartyEmail         string `json:"party_email,omitempty"`
	PartyContactPerson string `json:"party_contact_person,omitempty"`

	StartDate  time.Time  `json:"start_date"`
	EndDate    *time.Time `json:"end_date,omitempty"`
	SignedDate *time.Time `json:"signed_date,omitempty"`

	AutoRenew           bool `json:"auto_renew"`
	RenewalPeriodMonths *int `json:"renewal_period_months,omitempty"`
	RenewalNoticeDays   int  `json:"renewal_notice_days"`
	MaxRenewals         *int `json:"max_renewals,omitempty"`
	CurrentRenewal      int  `json:"current_renewal"`

	PaymentType   string   `json:"payment_type,omitempty"`
	MonthlyAmount *float64 `json:"monthly_amount,omitempty"`
	YearlyAmount  *float64 `json:"yearly_amount,omitempty"`
	TotalAmount   *float64 `json:"total_amount,omitempty"`
	Currency      string   `json:"currency"`

	Status            string     `json:"status"`
	TerminationReason string     `json:"termination_reason,omitempty"`
	TerminatedAt      *time.Time `json:"terminated_at,omitempty"`
	Notes             string     `json:"notes,omitempty"`
	CreatedAt         time.Time  `json:"created_at"`

	// DaysRemaining, bitişe kalan gün sayısıdır (bitmiş sözleşmelerde negatif).
	// Süresiz sözleşmelerde null kalır.
	DaysRemaining *int `json:"days_remaining,omitempty"`
	// NoticeDue, fesih ihbar süresinin dolmak üzere olduğunu gösterir: sözleşme
	// kendiliğinden yenileniyorsa, ihbar penceresi kaçırılırsa bir dönem daha bağlanılır.
	NoticeDue bool `json:"notice_due"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const contractSelect = `
SELECT id, contract_type, title, COALESCE(description,''), COALESCE(contract_number,''),
       party_name, COALESCE(party_type,''), COALESCE(party_tax_id,''),
       COALESCE(party_phone,''), COALESCE(party_email,''), COALESCE(party_contact_person,''),
       start_date, end_date, signed_date,
       COALESCE(auto_renew,false), renewal_period_months,
       COALESCE(renewal_notice_days,30), max_renewals, COALESCE(current_renewal,0),
       COALESCE(payment_type,''), monthly_amount::float8, yearly_amount::float8,
       total_amount::float8, COALESCE(currency,'TRY'),
       status, COALESCE(termination_reason,''), terminated_at, COALESCE(notes,''), created_at,
       CASE WHEN end_date IS NULL THEN NULL ELSE (end_date - CURRENT_DATE) END,
       CASE WHEN end_date IS NOT NULL AND status = 'ACTIVE'
             AND end_date - COALESCE(renewal_notice_days,30) <= CURRENT_DATE
            THEN true ELSE false END
FROM contracts`

func scanContract(row pgx.Row) (*Contract, error) {
	var c Contract
	err := row.Scan(&c.ID, &c.ContractType, &c.Title, &c.Description, &c.ContractNumber,
		&c.PartyName, &c.PartyType, &c.PartyTaxID, &c.PartyPhone, &c.PartyEmail,
		&c.PartyContactPerson, &c.StartDate, &c.EndDate, &c.SignedDate,
		&c.AutoRenew, &c.RenewalPeriodMonths, &c.RenewalNoticeDays, &c.MaxRenewals,
		&c.CurrentRenewal, &c.PaymentType, &c.MonthlyAmount, &c.YearlyAmount,
		&c.TotalAmount, &c.Currency, &c.Status, &c.TerminationReason, &c.TerminatedAt,
		&c.Notes, &c.CreatedAt, &c.DaysRemaining, &c.NoticeDue)
	if err != nil {
		return nil, err
	}
	return &c, nil
}

// List, sözleşmeleri getirir.
//
//	expiringDays > 0 ise yalnızca o kadar gün içinde bitecek AKTİF sözleşmeler döner.
func (r *Repository) List(ctx context.Context, propertyID, contractType, status string, expiringDays int) ([]Contract, error) {
	rows, err := r.scope(propertyID).Query(ctx, contractSelect+`
		WHERE property_id = $1
		  AND ($2 = '' OR contract_type = $2)
		  AND ($3 = '' OR status = $3)
		  AND ($4 = 0 OR (status = 'ACTIVE' AND end_date IS NOT NULL
		                  AND end_date <= CURRENT_DATE + make_interval(days => $4)))
		ORDER BY (end_date IS NULL), end_date, title
		LIMIT 500`, propertyID, strings.ToUpper(contractType), strings.ToUpper(status), expiringDays)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Contract{}
	for rows.Next() {
		c, err := scanContract(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *c)
	}
	return out, rows.Err()
}

// Get, tek sözleşmeyi getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id string) (*Contract, error) {
	c, err := scanContract(r.scope(propertyID).QueryRow(ctx,
		contractSelect+` WHERE property_id = $1 AND id = $2`, propertyID, id))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return c, err
}

// CreateInput, yeni sözleşme girdisidir.
type CreateInput struct {
	ContractType   string `json:"contract_type" binding:"required"`
	Title          string `json:"title" binding:"required"`
	Description    string `json:"description"`
	ContractNumber string `json:"contract_number"`

	PartyName          string `json:"party_name" binding:"required"`
	PartyType          string `json:"party_type"`
	PartyTaxID         string `json:"party_tax_id"`
	PartyAddress       string `json:"party_address"`
	PartyPhone         string `json:"party_phone"`
	PartyEmail         string `json:"party_email"`
	PartyContactPerson string `json:"party_contact_person"`

	StartDate  string `json:"start_date" binding:"required"`
	EndDate    string `json:"end_date"`
	SignedDate string `json:"signed_date"`

	AutoRenew           bool `json:"auto_renew"`
	RenewalPeriodMonths *int `json:"renewal_period_months"`
	RenewalNoticeDays   *int `json:"renewal_notice_days"`
	MaxRenewals         *int `json:"max_renewals"`

	PaymentType   string   `json:"payment_type"`
	MonthlyAmount *float64 `json:"monthly_amount"`
	YearlyAmount  *float64 `json:"yearly_amount"`
	TotalAmount   *float64 `json:"total_amount"`
	PaymentDay    *int     `json:"payment_day"`

	Terms string `json:"terms"`
	Notes string `json:"notes"`
}

// Create, sözleşmeyi kaydeder.
func (r *Repository) Create(ctx context.Context, propertyID, createdBy string, in CreateInput) (string, error) {
	ctype := strings.ToUpper(strings.TrimSpace(in.ContractType))
	if !validType(ctype) {
		return "", ErrInvalidType
	}

	start, err := parseDate(in.StartDate)
	if err != nil {
		return "", ErrInvalidDates
	}
	end, err := parseOptionalDate(in.EndDate)
	if err != nil {
		return "", ErrInvalidDates
	}
	if end != nil && end.Before(start) {
		return "", ErrInvalidDates
	}
	signed, err := parseOptionalDate(in.SignedDate)
	if err != nil {
		return "", ErrInvalidDates
	}

	// Kendiliğinden yenilenen bir sözleşmede yenileme süresi bilinmiyorsa,
	// ihbar penceresi hesaplanamaz ve site farkında olmadan yeni döneme bağlanır.
	if in.AutoRenew && (in.RenewalPeriodMonths == nil || *in.RenewalPeriodMonths <= 0) {
		return "", ErrNoRenewal
	}

	notice := 30
	if in.RenewalNoticeDays != nil && *in.RenewalNoticeDays >= 0 {
		notice = *in.RenewalNoticeDays
	}

	var id string
	err = r.scope(propertyID).QueryRow(ctx, `
		INSERT INTO contracts
			(property_id, contract_type, title, description, contract_number,
			 party_name, party_type, party_tax_id, party_address, party_phone,
			 party_email, party_contact_person,
			 start_date, end_date, signed_date,
			 auto_renew, renewal_period_months, renewal_notice_days, max_renewals,
			 payment_type, monthly_amount, yearly_amount, total_amount, payment_day,
			 terms, notes, created_by, status)
		VALUES ($1,$2,$3,NULLIF($4,''),NULLIF($5,''),
		        $6,NULLIF($7,''),NULLIF($8,''),NULLIF($9,''),NULLIF($10,''),
		        NULLIF($11,''),NULLIF($12,''),
		        $13,$14,$15,
		        $16,$17,$18,$19,
		        NULLIF($20,''),$21,$22,$23,$24,
		        NULLIF($25,''),NULLIF($26,''),NULLIF($27,'')::uuid,'ACTIVE')
		RETURNING id`,
		propertyID, ctype, in.Title, in.Description, in.ContractNumber,
		in.PartyName, strings.ToUpper(in.PartyType), in.PartyTaxID, in.PartyAddress, in.PartyPhone,
		in.PartyEmail, in.PartyContactPerson,
		start, end, signed,
		in.AutoRenew, in.RenewalPeriodMonths, notice, in.MaxRenewals,
		strings.ToUpper(in.PaymentType), in.MonthlyAmount, in.YearlyAmount, in.TotalAmount, in.PaymentDay,
		in.Terms, in.Notes, createdBy).Scan(&id)
	return id, err
}

// Renew, sözleşmeyi bir dönem uzatır.
//
// Uzatma, mevcut bitiş tarihine yenileme süresi eklenerek yapılır — "bugünden
// itibaren" uzatmak, arada geçen süreyi sözleşmesiz bırakır ve dönem takibini bozar.
func (r *Repository) Renew(ctx context.Context, propertyID, id string) (*Contract, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status string
	var period, maxRenewals *int
	var current int
	var endDate *time.Time
	err = tx.QueryRow(ctx, `
		SELECT status, renewal_period_months, max_renewals,
		       COALESCE(current_renewal,0), end_date
		FROM contracts WHERE id = $1 AND property_id = $2 FOR UPDATE`, id, propertyID).
		Scan(&status, &period, &maxRenewals, &current, &endDate)
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	if status != "ACTIVE" && status != "EXPIRED" {
		return nil, ErrBadState
	}
	if period == nil || *period <= 0 {
		return nil, ErrNoRenewal
	}
	if endDate == nil {
		// Süresiz sözleşmenin yenilenecek dönemi yoktur.
		return nil, ErrNoRenewal
	}
	if maxRenewals != nil && current >= *maxRenewals {
		return nil, ErrMaxRenewals
	}

	if _, err := tx.Exec(ctx, `
		UPDATE contracts
		SET end_date = end_date + make_interval(months => $3),
		    current_renewal = COALESCE(current_renewal,0) + 1,
		    status = 'ACTIVE',
		    updated_at = now()
		WHERE id = $1 AND property_id = $2`, id, propertyID, *period); err != nil {
		return nil, err
	}

	c, err := scanContract(tx.QueryRow(ctx,
		contractSelect+` WHERE property_id = $1 AND id = $2`, propertyID, id))
	if err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return c, nil
}

// Terminate, sözleşmeyi fesheder. Gerekçe zorunludur.
func (r *Repository) Terminate(ctx context.Context, propertyID, id, reason string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE contracts
		SET status = 'TERMINATED', termination_reason = $3,
		    terminated_at = CURRENT_DATE, updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status IN ('DRAFT','ACTIVE','EXPIRED')`,
		id, propertyID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}

// ExpireDue, bitiş tarihi geçmiş AKTİF sözleşmeleri EXPIRED yapar ve kaç kaydın
// değiştiğini döner. İşlem idempotenttir; iki kez çalıştırmak zarar vermez.
//
// Kendiliğinden yenilenen sözleşmeler BU İŞLEMİN DIŞINDADIR: onların süresi
// dolmaz, yenilenir. Yenilemeyi sistemin kendiliğinden yapması, sitenin haberi
// olmadan mali yükümlülük doğurur; bu yüzden yenileme elle onaylanır.
func (r *Repository) ExpireDue(ctx context.Context, propertyID string) (int64, error) {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE contracts
		SET status = 'EXPIRED', updated_at = now()
		WHERE property_id = $1 AND status = 'ACTIVE'
		  AND end_date IS NOT NULL AND end_date < CURRENT_DATE
		  AND auto_renew = false`, propertyID)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

// Summary, sözleşme portföyünün özetidir. Kişisel veri içermez; bu yüzden
// kat maliklerine de açılabilir (KMK m.39 hesap verme / denetim hakkı).
type Summary struct {
	Active            int     `json:"active"`
	Expired           int     `json:"expired"`
	Terminated        int     `json:"terminated"`
	NoticeDue         int     `json:"notice_due"`
	ExpiringIn30Days  int     `json:"expiring_in_30_days"`
	MonthlyCommitment float64 `json:"monthly_commitment_try"`
	YearlyCommitment  float64 `json:"yearly_commitment_try"`
}

// Summary, aktif sözleşmelerden doğan mali yükü ve yaklaşan bitişleri verir.
//
// Aylık yük: MONTHLY ödemeli sözleşmelerin aylık tutarı + YEARLY ödemelilerin
// yıllık tutarının 1/12'si. İşletme projesi (KMK m.37) hazırlanırken bu tutar
// gider tahmininin bilinen kısmını oluşturur.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	var s Summary
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT
		  count(*) FILTER (WHERE status = 'ACTIVE'),
		  count(*) FILTER (WHERE status = 'EXPIRED'),
		  count(*) FILTER (WHERE status = 'TERMINATED'),
		  count(*) FILTER (WHERE status = 'ACTIVE' AND end_date IS NOT NULL
		                     AND end_date - COALESCE(renewal_notice_days,30) <= CURRENT_DATE),
		  count(*) FILTER (WHERE status = 'ACTIVE' AND end_date IS NOT NULL
		                     AND end_date <= CURRENT_DATE + interval '30 days'),
		  COALESCE(SUM(
		    CASE WHEN status <> 'ACTIVE' OR currency <> 'TRY' THEN 0
		         WHEN payment_type = 'MONTHLY' THEN COALESCE(monthly_amount,0)
		         WHEN payment_type = 'YEARLY'  THEN COALESCE(yearly_amount,0) / 12
		         ELSE 0 END), 0)::float8
		FROM contracts WHERE property_id = $1`, propertyID).
		Scan(&s.Active, &s.Expired, &s.Terminated, &s.NoticeDue,
			&s.ExpiringIn30Days, &s.MonthlyCommitment)
	if err != nil {
		return nil, err
	}
	s.YearlyCommitment = round2(s.MonthlyCommitment * 12)
	s.MonthlyCommitment = round2(s.MonthlyCommitment)
	return &s, nil
}

func round2(f float64) float64 {
	return float64(int64(f*100+0.5)) / 100
}

func validType(t string) bool {
	for _, v := range ValidTypes {
		if v == t {
			return true
		}
	}
	return false
}

func parseDate(s string) (time.Time, error) {
	return time.Parse("2006-01-02", strings.TrimSpace(s))
}

func parseOptionalDate(s string) (*time.Time, error) {
	if strings.TrimSpace(s) == "" {
		return nil, nil
	}
	t, err := parseDate(s)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// contracts tablolarında RLS açıktır (migration 022).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
