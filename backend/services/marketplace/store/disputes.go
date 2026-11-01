package store

// Geçersiz talep bildirimi ve iade (FAZ M7.6, K6): tedarikçi kabul ettiği talebi geçersiz bulursa bildirir; iade yalnız
// platform onayıyla bakiyeye (dahil talep hakkıyla kabul edildiyse hak geri) yapılır. Yorum denetimi (M7.7): platform
// gerekçeyle gizler, silmez. Gelir raporu (M7.8): defterden.

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
)

// Dispute, geçersiz talep bildirimidir.
type Dispute struct {
	ID           string     `json:"id"`
	RequestID    string     `json:"request_id"`
	AccountID    string     `json:"account_id"`
	TradeName    string     `json:"trade_name,omitempty"`
	Category     string     `json:"category"`
	ReasonCode   string     `json:"reason_code"`
	Note         string     `json:"note"`
	Status       string     `json:"status"`
	FeeKurus     int64      `json:"fee_kurus"`
	UsedIncluded bool       `json:"used_included"`
	DecidedAt    *time.Time `json:"decided_at"`
	DecisionNote *string    `json:"decision_note"`
	CreatedAt    time.Time  `json:"created_at"`
}

const disputeSelect = `SELECT x.id, x.request_id, x.account_id, a.trade_name, c.name, x.reason_code, x.note, x.status,
	COALESCE(d.fee_kurus, 0), d.used_included, x.decided_at, x.decision_note, x.created_at
	FROM mp_disputes x JOIN mp_request_dispatch d ON d.id = x.dispatch_id JOIN mp_requests r ON r.id = x.request_id
	JOIN mp_categories c ON c.id = r.category_id JOIN mp_supplier_accounts a ON a.id = x.account_id`

func scanDispute(r pgx.Row) (*Dispute, error) {
	x := &Dispute{}
	err := r.Scan(&x.ID, &x.RequestID, &x.AccountID, &x.TradeName, &x.Category, &x.ReasonCode, &x.Note, &x.Status,
		&x.FeeKurus, &x.UsedIncluded, &x.DecidedAt, &x.DecisionNote, &x.CreatedAt)
	return x, err
}

var disputeReasons = map[string]bool{"FAKE": true, "WRONG_CATEGORY": true, "UNREACHABLE": true, "OTHER": true}

// OpenDispute, tedarikçinin kabul ettiği talep için geçersizlik bildirimidir (gönderim başına bir kez).
func (s *Store) OpenDispute(ctx context.Context, accountID, requestID, reason, note string) (*Dispute, error) {
	note = strings.TrimSpace(note)
	if !disputeReasons[reason] || utf8.RuneCountInString(note) < 10 || utf8.RuneCountInString(note) > 2000 {
		return nil, userErr(http.StatusUnprocessableEntity, "DISPUTE",
			"Neden (FAKE, WRONG_CATEGORY, UNREACHABLE, OTHER) ve açıklama (10–2000 karakter) zorunludur")
	}
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	dispatchID, _, _, err := acceptedDispatch(ctx, tx, accountID, requestID)
	if err != nil {
		return nil, err
	}
	var id string
	err = tx.QueryRow(ctx, `INSERT INTO mp_disputes (dispatch_id, request_id, account_id, reason_code, note)
		VALUES ($1, $2, $3, $4, $5) ON CONFLICT (dispatch_id) DO NOTHING RETURNING id`, dispatchID, requestID, accountID, reason, note).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, userErr(http.StatusConflict, "ALREADY_DISPUTED", "Bu talep için zaten bildirim yaptınız")
	}
	if err != nil {
		return nil, err
	}
	x, err := scanDispute(tx.QueryRow(ctx, disputeSelect+` WHERE x.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return x, tx.Commit(ctx)
}

// Disputes, platformun inceleme kuyruğudur.
func (s *Store) Disputes(ctx context.Context, adminID, status string) ([]Dispute, error) {
	rows, err := s.platform(adminID).Query(ctx, disputeSelect+` WHERE ($1 = '' OR x.status = $1) ORDER BY x.created_at LIMIT 200`, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Dispute{}
	for rows.Next() {
		x, err := scanDispute(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

// DecideDispute, platformun kararıdır. Onayda kabul ücreti bakiyeye iade edilir (defterde REFUND; aynı kabul için ikinci
// iade benzersiz indeksle engellenir) ya da dahil talep hakkı geri verilir. Gerekçe her iki kararda zorunludur.
func (s *Store) DecideDispute(ctx context.Context, adminID, id string, approve bool, note string) (*Dispute, error) {
	note = strings.TrimSpace(note)
	if utf8.RuneCountInString(note) < 5 {
		return nil, userErr(http.StatusUnprocessableEntity, "NOTE", "Karar gerekçesi zorunludur (en az 5 karakter)")
	}
	tx, err := s.platform(adminID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var status, dispatchID, accountID, category string
	var fee *int64
	var included bool
	var refunded *time.Time
	err = tx.QueryRow(ctx, `SELECT x.status, x.dispatch_id, x.account_id, d.fee_kurus, d.used_included, d.refunded_at, c.name
		FROM mp_disputes x JOIN mp_request_dispatch d ON d.id = x.dispatch_id JOIN mp_requests r ON r.id = x.request_id
		JOIN mp_categories c ON c.id = r.category_id WHERE x.id = $1 FOR UPDATE OF x, d`, id).
		Scan(&status, &dispatchID, &accountID, &fee, &included, &refunded, &category)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if status != "OPEN" {
		return nil, userErr(http.StatusConflict, "DECIDED", "Bu bildirim zaten karara bağlandı")
	}
	newStatus := "REJECTED"
	if approve {
		newStatus = "APPROVED"
		if refunded != nil {
			return nil, userErr(http.StatusConflict, "ALREADY_REFUNDED", "Bu kabulün ücreti zaten iade edildi")
		}
		switch {
		case included:
			if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET period_included_left = period_included_left + 1, updated_at = now()
				WHERE id = $1`, accountID); err != nil {
				return nil, err
			}
		case fee != nil && *fee > 0:
			var accStatus string
			if err := tx.QueryRow(ctx, `SELECT status FROM mp_supplier_accounts WHERE id = $1 FOR UPDATE`, accountID).Scan(&accStatus); err != nil {
				return nil, err
			}
			if _, _, err := post(ctx, tx, accountID, "REFUND", *fee, ledgerRef{dispatch: &dispatchID, by: strp(adminID),
				note: fmt.Sprintf("Geçersiz talep iadesi — %s: %s", category, note)}); err != nil {
				return nil, err
			}
			// Kapalı hesapta bakiye kullanılamaz: iade edilen ücret aynı işlemde karta iadeye çevrilir (bakiye koşulları m.2).
			if accStatus == "CLOSED" {
				if _, err := refundBalance(ctx, tx, accountID, "CLOSED_ACCOUNT", adminID, *fee); err != nil {
					return nil, err
				}
			}
		}
		if _, err := tx.Exec(ctx, `UPDATE mp_request_dispatch SET refunded_at = now() WHERE id = $1`, dispatchID); err != nil {
			return nil, err
		}
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_disputes SET status = $2, decided_by = $3, decided_at = now(), decision_note = $4 WHERE id = $1`,
		id, newStatus, adminID, note); err != nil {
		return nil, err
	}
	x, err := scanDispute(tx.QueryRow(ctx, disputeSelect+` WHERE x.id = $1`, id))
	if err != nil {
		return nil, err
	}
	return x, tx.Commit(ctx)
}

// PlatformReviews, denetim için yorumlardır (hidden: "1" gizlenenler, "0" görünenler, boş hepsi).
func (s *Store) PlatformReviews(ctx context.Context, adminID, hidden string) ([]Review, error) {
	rows, err := s.platform(adminID).Query(ctx, `SELECT r.id, r.business_id, b.name, r.rating, r.comment, r.reply, r.replied_at,
		r.hidden_at, r.hidden_reason, r.created_at FROM mp_reviews r JOIN mp_businesses b ON b.id = r.business_id
		WHERE ($1 = '' OR ($1 = '1') = (r.hidden_at IS NOT NULL)) ORDER BY r.created_at DESC LIMIT 200`, hidden)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Review{}
	for rows.Next() {
		r := Review{}
		if err := rows.Scan(&r.ID, &r.BusinessID, &r.BusinessName, &r.Rating, &r.Comment, &r.Reply, &r.RepliedAt, &r.HiddenAt,
			&r.HiddenReason, &r.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// HideReview, yorumu gerekçeyle gizler (silinmez; puan özetinden çıkar — tetikleyici).
func (s *Store) HideReview(ctx context.Context, adminID, id, reason string) error {
	reason = strings.TrimSpace(reason)
	if utf8.RuneCountInString(reason) < 5 {
		return userErr(http.StatusUnprocessableEntity, "REASON", "Gizleme gerekçesi zorunludur (en az 5 karakter)")
	}
	tag, err := s.platform(adminID).Exec(ctx, `UPDATE mp_reviews SET hidden_at = now(), hidden_reason = $2, hidden_by = $3
		WHERE id = $1 AND hidden_at IS NULL`, id, reason, adminID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		var n int
		if err := s.platform(adminID).QueryRow(ctx, `SELECT count(*) FROM mp_reviews WHERE id = $1`, id).Scan(&n); err != nil {
			return err
		}
		if n == 0 {
			return ErrNotFound
		}
		return userErr(http.StatusConflict, "ALREADY_HIDDEN", "Yorum zaten gizli")
	}
	return nil
}

// Revenue, dönemin gelir özetidir (kuruş). Gelir = aidat + talep ücreti − iade; yüklemeler gelir değil, tedarikçi
// adına tutulan bakiyedir (yükümlülük); kapanış iadeleri bu bakiyenin geri ödenmesidir.
type Revenue struct {
	From             string `json:"from"`
	To               string `json:"to"`
	PackageFees      int64  `json:"package_fees_kurus"`
	RequestFees      int64  `json:"request_fees_kurus"`
	Refunds          int64  `json:"refunds_kurus"`
	Net              int64  `json:"net_kurus"`
	Topups           int64  `json:"topups_kurus"`
	ClosureRefunds   int64  `json:"closure_refunds_kurus"`
	IncludedRequests int64  `json:"included_requests"`
	LedgerTotal      int64  `json:"ledger_total_kurus"`
	BalanceLiability int64  `json:"balance_liability_kurus"`
}

// RevenueReport, [from, to] (gün, İstanbul saati) için defterden gelir özetidir.
func (s *Store) RevenueReport(ctx context.Context, adminID, from, to string) (*Revenue, error) {
	f, err1 := time.Parse("2006-01-02", from)
	t, err2 := time.Parse("2006-01-02", to)
	if err1 != nil || err2 != nil || t.Before(f) {
		return nil, userErr(http.StatusUnprocessableEntity, "PERIOD", "from ve to (YYYY-AA-GG) zorunlu; to, from'dan önce olamaz")
	}
	r := &Revenue{From: from, To: to}
	err := s.platform(adminID).QueryRow(ctx, `
		WITH l AS (SELECT kind, amount_kurus FROM mp_wallet_ledger
		           WHERE created_at >= ($1::date)::timestamp AT TIME ZONE 'Europe/Istanbul'
		             AND created_at <  ($2::date + 1)::timestamp AT TIME ZONE 'Europe/Istanbul')
		SELECT COALESCE(-sum(amount_kurus) FILTER (WHERE kind = 'PACKAGE_FEE'), 0),
		       COALESCE(-sum(amount_kurus) FILTER (WHERE kind = 'REQUEST_FEE'), 0),
		       COALESCE(sum(amount_kurus) FILTER (WHERE kind = 'REFUND'), 0),
		       COALESCE(sum(amount_kurus) FILTER (WHERE kind = 'TOPUP'), 0),
		       COALESCE(-sum(amount_kurus) FILTER (WHERE kind = 'CLOSURE_REFUND'), 0),
		       count(*) FILTER (WHERE kind = 'INCLUDED_REQUEST'),
		       COALESCE(sum(amount_kurus), 0),
		       (SELECT COALESCE(sum(balance_kurus), 0) FROM mp_supplier_accounts)
		FROM l`, from, to).Scan(&r.PackageFees, &r.RequestFees, &r.Refunds, &r.Topups, &r.ClosureRefunds, &r.IncludedRequests,
		&r.LedgerTotal, &r.BalanceLiability)
	if err != nil {
		return nil, err
	}
	r.Net = r.PackageFees + r.RequestFees - r.Refunds
	return r, nil
}
