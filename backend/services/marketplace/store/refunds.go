package store

// Kalan bakiyenin karta iadesi (FAZ M13.3, bakiye koşulları m.2–5). Kapanışta bakiye, son RefundWindowDays gündeki başarılı
// yüklemelerin henüz iade edilmemiş kısmıyla en yeniden eskiye eşleştirilir; her eşleşme bir iade satırı ve aynı işlemde
// defterde CARD_REFUND olur (bakiye hemen düşer; para karta borçludur). Eşleşmeyen kısım EXPIRED_BALANCE ile kapanır.
// iyzico çağrısı işlem dışında, zamanlayıcıyla yapılır; sonuç bilinmiyorsa yeniden denenmez (çift iade yok), elle kuyruğa düşer.

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
)

// CardRefund, karta iade satırıdır.
type CardRefund struct {
	ID               string     `json:"id"`
	AccountID        string     `json:"account_id"`
	TradeName        string     `json:"trade_name,omitempty"`
	TopupID          string     `json:"topup_id"`
	AmountKurus      int64      `json:"amount_kurus"`
	Reason           string     `json:"reason"`
	Status           string     `json:"status"`
	Attempts         int        `json:"attempts"`
	LastError        *string    `json:"last_error"`
	GatewayReference *string    `json:"gateway_reference"`
	ManualReference  *string    `json:"manual_reference"`
	ManualDate       *time.Time `json:"manual_date"`
	TopupAt          *time.Time `json:"topup_at"`
	CreatedAt        time.Time  `json:"created_at"`
	CompletedAt      *time.Time `json:"completed_at"`
	PaymentID        string     `json:"-"`
}

const cardRefundSelect = `SELECT r.id, r.account_id, a.trade_name, r.topup_id, r.amount_kurus, r.reason, r.status, r.attempts, r.last_error,
	r.gateway_reference, r.manual_reference, r.manual_date, t.completed_at, r.created_at, r.completed_at, COALESCE(t.gateway_payment_id, '')
	FROM mp_card_refunds r JOIN mp_topups t ON t.id = r.topup_id JOIN mp_supplier_accounts a ON a.id = r.account_id`

func scanCardRefund(r pgx.Row) (*CardRefund, error) {
	x := &CardRefund{}
	err := r.Scan(&x.ID, &x.AccountID, &x.TradeName, &x.TopupID, &x.AmountKurus, &x.Reason, &x.Status, &x.Attempts, &x.LastError,
		&x.GatewayReference, &x.ManualReference, &x.ManualDate, &x.TopupAt, &x.CreatedAt, &x.CompletedAt, &x.PaymentID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return x, err
}

func collectCardRefunds(rows pgx.Rows, err error) ([]CardRefund, error) {
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []CardRefund{}
	for rows.Next() {
		x, err := scanCardRefund(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

// RefundOutcome, bakiyenin iadeye çevrilmesinin özetidir.
type RefundOutcome struct {
	CardRefundKurus int64 `json:"card_refund_kurus"`
	CardRefunds     int   `json:"card_refunds"`
	ExpiredKurus    int64 `json:"expired_kurus"`
}

// refundBalance, hesabın `amount` kadar bakiyesini karta iadeye çevirir (çağıranın işleminde; hesap satırı kilitli olmalı).
func refundBalance(ctx context.Context, tx pgx.Tx, accountID, reason, by string, amount int64) (*RefundOutcome, error) {
	o := &RefundOutcome{}
	if amount <= 0 {
		return o, nil
	}
	rows, err := tx.Query(ctx, `SELECT t.id, t.amount_kurus - COALESCE((SELECT sum(r.amount_kurus) FROM mp_card_refunds r WHERE r.topup_id = t.id), 0)
		FROM mp_topups t WHERE t.account_id = $1 AND t.status = 'SUCCEEDED' AND t.gateway_payment_id IS NOT NULL
		AND t.completed_at >= now() - make_interval(days => $2) ORDER BY t.completed_at DESC, t.id DESC`, accountID, RefundWindowDays)
	if err != nil {
		return nil, err
	}
	type piece struct {
		topup string
		left  int64
	}
	var pieces []piece
	for rows.Next() {
		var p piece
		if err := rows.Scan(&p.topup, &p.left); err != nil {
			rows.Close()
			return nil, err
		}
		if p.left > 0 {
			pieces = append(pieces, p)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	rest := amount
	for _, p := range pieces {
		if rest == 0 {
			break
		}
		take := min(rest, p.left)
		topup := p.topup
		_, ledgerID, err := post(ctx, tx, accountID, "CARD_REFUND", -take, ledgerRef{topup: &topup, by: strp(by),
			note: "Kalan bakiye karta iade ediliyor (bakiye koşulları m.2)"})
		if err != nil {
			return nil, err
		}
		if _, err := tx.Exec(ctx, `INSERT INTO mp_card_refunds (account_id, topup_id, amount_kurus, reason, ledger_id) VALUES ($1,$2,$3,$4,$5)`,
			accountID, topup, take, reason, ledgerID); err != nil {
			return nil, err
		}
		rest -= take
		o.CardRefundKurus += take
		o.CardRefunds++
	}
	if rest > 0 {
		if _, _, err := post(ctx, tx, accountID, "EXPIRED_BALANCE", -rest, ledgerRef{by: strp(by),
			note: fmt.Sprintf("Son %d gündeki yüklemelerle karşılanmayan kalan bakiye iade edilmez (bakiye koşulları m.3)", RefundWindowDays)}); err != nil {
			return nil, err
		}
		o.ExpiredKurus = rest
	}
	return o, nil
}

// SupplierCardRefunds, tedarikçinin karta iadeleri.
func (s *Store) SupplierCardRefunds(ctx context.Context, accountID string) ([]CardRefund, error) {
	return collectCardRefunds(s.supplier(accountID).Query(ctx, cardRefundSelect+` WHERE r.account_id = $1 ORDER BY r.created_at DESC`, accountID))
}

// PlatformCardRefunds, platformun iade listesi (durum süzgeciyle; boşsa hepsi).
func (s *Store) PlatformCardRefunds(ctx context.Context, adminID, status string) ([]CardRefund, error) {
	return collectCardRefunds(s.platform(adminID).Query(ctx, cardRefundSelect+` WHERE ($1 = '' OR r.status = $1)
		ORDER BY (r.status = 'FAILED') DESC, r.created_at DESC LIMIT 500`, status))
}

// ClaimDueCardRefunds, sırası gelen iadeleri işleyiciye ayırır: deneme sayısı artar ve bir sonraki deneme ileri alınır
// (işleyici çökerse satır sonra yeniden alınır). Aynı satırı iki işleyici almaz.
func (s *Store) ClaimDueCardRefunds(ctx context.Context) ([]CardRefund, error) {
	tx, err := s.platform("jobs").Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	rows, err := tx.Query(ctx, `SELECT id FROM mp_card_refunds WHERE status = 'PENDING' AND next_attempt_at <= now()
		ORDER BY next_attempt_at LIMIT 20 FOR UPDATE SKIP LOCKED`)
	if err != nil {
		return nil, err
	}
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return nil, err
		}
		ids = append(ids, id)
	}
	rows.Close()
	if len(ids) == 0 {
		return nil, tx.Commit(ctx)
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_card_refunds SET attempts = attempts + 1, next_attempt_at = now() + interval '10 minutes'
		WHERE id = ANY($1::uuid[])`, ids); err != nil {
		return nil, err
	}
	list, err := collectCardRefunds(tx.Query(ctx, cardRefundSelect+` WHERE r.id = ANY($1::uuid[]) ORDER BY r.created_at`, ids))
	if err != nil {
		return nil, err
	}
	return list, tx.Commit(ctx)
}

// FinishCardRefund, iyzico sonucunu yazar. ok=true: SUCCEEDED. retry=true: sağlayıcı açıkça reddetti, deneme hakkı varsa
// üstel beklemeyle yeniden denenir, yoksa FAILED. retry=false ve ok=false: sonuç bilinmiyor ya da yeniden denenemez → FAILED.
func (s *Store) FinishCardRefund(ctx context.Context, id string, ok, retry bool, reference, errMsg string) (*CardRefund, error) {
	maxAttempts, err := s.setting(ctx, "card_refund_max_attempts")
	if err != nil {
		return nil, err
	}
	sc := s.platform("jobs")
	switch {
	case ok:
		_, err = sc.Exec(ctx, `UPDATE mp_card_refunds SET status = 'SUCCEEDED', gateway_reference = $2, last_error = NULL, completed_at = now()
			WHERE id = $1 AND status = 'PENDING'`, id, reference)
	case retry:
		_, err = sc.Exec(ctx, `UPDATE mp_card_refunds SET last_error = $2,
			status = CASE WHEN attempts >= $3 THEN 'FAILED' ELSE status END,
			next_attempt_at = now() + make_interval(mins => 5 * power(2, LEAST(attempts, 8))::int)
			WHERE id = $1 AND status = 'PENDING'`, id, errMsg, maxAttempts)
	default:
		_, err = sc.Exec(ctx, `UPDATE mp_card_refunds SET status = 'FAILED', last_error = $2 WHERE id = $1 AND status = 'PENDING'`, id, errMsg)
	}
	if err != nil {
		return nil, err
	}
	return scanCardRefund(sc.QueryRow(ctx, cardRefundSelect+` WHERE r.id = $1`, id))
}

// ResolveCardRefundManually, başarısız iadenin platformca havaleyle ödendiğini kaydeder (dekont no ve tarih zorunlu).
func (s *Store) ResolveCardRefundManually(ctx context.Context, adminID, id, reference, date string) (*CardRefund, error) {
	if len([]rune(reference)) < 3 {
		return nil, userErr(http.StatusUnprocessableEntity, "REFERENCE", "Havale dekont numarası zorunludur")
	}
	if _, err := time.Parse("2006-01-02", date); err != nil {
		return nil, userErr(http.StatusUnprocessableEntity, "DATE", "Havale tarihi YYYY-AA-GG biçiminde olmalı")
	}
	sc := s.platform(adminID)
	tag, err := sc.Exec(ctx, `UPDATE mp_card_refunds SET status = 'MANUAL', manual_reference = $2, manual_date = $3, resolved_by = $4,
		completed_at = now() WHERE id = $1 AND status = 'FAILED'`, id, reference, date, adminID)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, userErr(http.StatusConflict, "STATE", "Yalnız başarısız iade elle kapatılabilir")
	}
	return scanCardRefund(sc.QueryRow(ctx, cardRefundSelect+` WHERE r.id = $1`, id))
}

// RetryCardRefund, başarısız iadeyi yeniden denemeye alır (platform; ör. sağlayıcı arızası geçtikten sonra).
func (s *Store) RetryCardRefund(ctx context.Context, adminID, id string) (*CardRefund, error) {
	sc := s.platform(adminID)
	tag, err := sc.Exec(ctx, `UPDATE mp_card_refunds SET status = 'PENDING', attempts = 0, next_attempt_at = now() WHERE id = $1 AND status = 'FAILED'`, id)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, userErr(http.StatusConflict, "STATE", "Yalnız başarısız iade yeniden denenebilir")
	}
	return scanCardRefund(sc.QueryRow(ctx, cardRefundSelect+` WHERE r.id = $1`, id))
}
