package store

// Bakiye, yükleme ve paket aidatı (FAZ M5, K6). Bakiye hesabın satırında tutulur (CHECK >= 0, borç oluşmaz);
// her hareket değiştirilemez deftere bakiyenin yeni değeriyle yazılır. Bakiye ile defter aynı işlemde değişir.

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

// LedgerEntry, bakiye defteri satırıdır.
type LedgerEntry struct {
	ID           string    `json:"id"`
	Kind         string    `json:"kind"`
	AmountKurus  int64     `json:"amount_kurus"`
	BalanceAfter int64     `json:"balance_after"`
	TopupID      *string   `json:"topup_id"`
	DispatchID   *string   `json:"dispatch_id"`
	PackageID    *string   `json:"package_id"`
	Note         string    `json:"note"`
	CreatedAt    time.Time `json:"created_at"`
}

// Ledger, hesabın defteri (en yeni önce, sayfalı).
func (s *Store) Ledger(ctx context.Context, accountID string, limit, offset int) ([]LedgerEntry, int, error) {
	sc := s.supplier(accountID)
	var total int
	if err := sc.QueryRow(ctx, `SELECT count(*) FROM mp_wallet_ledger WHERE account_id = $1`, accountID).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := sc.Query(ctx, `SELECT id, kind, amount_kurus, balance_after, topup_id, dispatch_id, package_id, note, created_at
		FROM mp_wallet_ledger WHERE account_id = $1 ORDER BY created_at DESC, id DESC LIMIT $2 OFFSET $3`, accountID, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	out := []LedgerEntry{}
	for rows.Next() {
		var x LedgerEntry
		if err := rows.Scan(&x.ID, &x.Kind, &x.AmountKurus, &x.BalanceAfter, &x.TopupID, &x.DispatchID, &x.PackageID, &x.Note, &x.CreatedAt); err != nil {
			return nil, 0, err
		}
		out = append(out, x)
	}
	return out, total, rows.Err()
}

// post, bakiyeyi değiştirir ve deftere yazar (çağıranın açtığı işlemde). Bakiye yetmezse ErrInsufficient.
// Dönen değer yeni bakiye ve defter satırı kimliğidir.
func post(ctx context.Context, tx pgx.Tx, accountID, kind string, amount int64, ref ledgerRef) (int64, string, error) {
	var balance int64
	err := tx.QueryRow(ctx, `UPDATE mp_supplier_accounts SET balance_kurus = balance_kurus + $2, updated_at = now()
		WHERE id = $1 AND balance_kurus + $2 >= 0 RETURNING balance_kurus`, accountID, amount).Scan(&balance)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, "", ErrInsufficient
	}
	if err != nil {
		return 0, "", err
	}
	var id string
	err = tx.QueryRow(ctx, `INSERT INTO mp_wallet_ledger (account_id, kind, amount_kurus, balance_after, topup_id, dispatch_id,
		package_id, note, created_by) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
		accountID, kind, amount, balance, ref.topup, ref.dispatch, ref.pkg, ref.note, ref.by).Scan(&id)
	return balance, id, err
}

type ledgerRef struct {
	topup, dispatch, pkg, by *string
	note                     string
}

func strp(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

// ErrInsufficient: bakiye işlem tutarını karşılamıyor.
var ErrInsufficient = &UserError{Status: http.StatusConflict, Code: "INSUFFICIENT_BALANCE",
	Message: "Bakiyeniz yetersiz; önce bakiye yükleyin"}

// Topup, bakiye yüklemesidir.
type Topup struct {
	ID           string     `json:"id"`
	AmountKurus  int64      `json:"amount_kurus"`
	Status       string     `json:"status"`
	Token        *string    `json:"-"`
	ErrorMessage *string    `json:"error_message"`
	CreatedAt    time.Time  `json:"created_at"`
	CompletedAt  *time.Time `json:"completed_at"`
	AccountID    string     `json:"-"`
	ReturnTarget string     `json:"return_target"`
}

const topupCols = `id, amount_kurus, status, gateway_token, error_message, created_at, completed_at, account_id, return_target`

func scanTopup(r pgx.Row) (*Topup, error) {
	t := &Topup{}
	err := r.Scan(&t.ID, &t.AmountKurus, &t.Status, &t.Token, &t.ErrorMessage, &t.CreatedAt, &t.CompletedAt, &t.AccountID, &t.ReturnTarget)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	return t, err
}

// CreateTopup, yüklemeyi PENDING açar. Aynı anahtarla ikinci istek aynı kaydı döner (çift tıklama, ağ yinelemesi).
func (s *Store) CreateTopup(ctx context.Context, accountID, userID string, amount int64, idemKey, returnTarget string) (*Topup, bool, error) {
	if returnTarget != "APP" {
		returnTarget = "PANEL"
	}
	if amount <= 0 {
		return nil, false, userErr(http.StatusUnprocessableEntity, "AMOUNT", "Yükleme tutarı sıfırdan büyük olmalı")
	}
	if idemKey == "" {
		return nil, false, userErr(http.StatusBadRequest, "IDEMPOTENCY_KEY", "Idempotency-Key başlığı zorunludur")
	}
	sc := s.supplier(accountID)
	t, err := scanTopup(sc.QueryRow(ctx, `SELECT `+topupCols+` FROM mp_topups WHERE account_id = $1 AND idempotency_key = $2`, accountID, idemKey))
	if err == nil {
		if t.AmountKurus != amount {
			return nil, false, userErr(http.StatusConflict, "IDEMPOTENCY_MISMATCH", "Bu anahtar farklı bir tutarla kullanılmış")
		}
		return t, false, nil
	}
	if !errors.Is(err, ErrNotFound) {
		return nil, false, err
	}
	var st string
	if err := sc.QueryRow(ctx, `SELECT status FROM mp_supplier_accounts WHERE id = $1`, accountID).Scan(&st); err != nil {
		return nil, false, err
	}
	if st == "CLOSED" {
		return nil, false, userErr(http.StatusConflict, "CLOSED", "Kapatılmış hesaba bakiye yüklenemez")
	}
	if acc, err := termsAccepted(ctx, sc, accountID); err != nil {
		return nil, false, err
	} else if acc == nil {
		return nil, false, ErrTermsRequired
	}
	// Sağlayıcıdaki konuşma ve sepet kimliği yüklemenin kendi kimliğidir: dönen sonuç bununla eşleştirilir.
	id := uuid.NewString()
	t, err = scanTopup(sc.QueryRow(ctx, `INSERT INTO mp_topups (id, account_id, amount_kurus, idempotency_key, conversation_id, created_by, return_target)
		VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING `+topupCols, id, accountID, amount, idemKey, id, userID, returnTarget))
	return t, true, err
}

// SetTopupToken, ödeme sayfası açılınca sağlayıcı jetonunu yazar.
func (s *Store) SetTopupToken(ctx context.Context, accountID, id, token string) error {
	_, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_topups SET gateway_token = $2 WHERE id = $1 AND status = 'PENDING'`, id, token)
	return err
}

// TopupByToken, kimliksiz ödeme dönüşünde jetonun yüklemesini bulur (hesap kimliği tanımlayıcı işlevle çözülür).
func (s *Store) TopupByToken(ctx context.Context, token string) (*Topup, error) {
	var acc *string
	if err := s.pool.QueryRow(ctx, `SELECT mp_topup_account($1)::text`, token).Scan(&acc); err != nil {
		return nil, err
	}
	if acc == nil {
		return nil, ErrNotFound
	}
	return scanTopup(s.supplier(*acc).QueryRow(ctx, `SELECT `+topupCols+` FROM mp_topups WHERE gateway_token = $1`, token))
}

// GetTopup, tedarikçinin kendi yüklemesi.
func (s *Store) GetTopup(ctx context.Context, accountID, id string) (*Topup, error) {
	return scanTopup(s.supplier(accountID).QueryRow(ctx, `SELECT `+topupCols+` FROM mp_topups WHERE id = $1`, id))
}

// CompleteTopup, başarılı yüklemeyi bakiyeye işler: tek işlemde yükleme SUCCEEDED, bakiye artar, deftere TOPUP yazılır.
// Aynı yükleme ikinci kez işlenmez (satır kilidi + defterde yükleme başına tekil indeks). Hesap bu arada kapatıldıysa tutar
// bakiyeye yazılmaz, tamamı karta iade sırasına girer (bakiye koşulları m.4); ikinci dönüş değeri bunu söyler.
func (s *Store) CompleteTopup(ctx context.Context, accountID, id, gatewayPaymentID string) (bool, bool, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return false, false, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var status string
	if err := tx.QueryRow(ctx, `SELECT status FROM mp_supplier_accounts WHERE id = $1 FOR UPDATE`, accountID).Scan(&status); err != nil {
		return false, false, err
	}
	var amount int64
	err = tx.QueryRow(ctx, `UPDATE mp_topups SET status = 'SUCCEEDED', completed_at = now(), gateway_payment_id = $2
		WHERE id = $1 AND status = 'PENDING' RETURNING amount_kurus`, id, gatewayPaymentID).Scan(&amount)
	if errors.Is(err, pgx.ErrNoRows) {
		return false, false, nil
	}
	if err != nil {
		return false, false, err
	}
	if status == "CLOSED" {
		if _, err := tx.Exec(ctx, `INSERT INTO mp_card_refunds (account_id, topup_id, amount_kurus, reason) VALUES ($1, $2, $3, 'LATE_TOPUP')`,
			accountID, id, amount); err != nil {
			return false, false, err
		}
		return true, true, tx.Commit(ctx)
	}
	if _, _, err := post(ctx, tx, accountID, "TOPUP", amount, ledgerRef{topup: &id, note: "Kartla bakiye yükleme"}); err != nil {
		return false, false, err
	}
	return true, false, tx.Commit(ctx)
}

// TopupRefundQueued, yüklemenin karta iade sırasına girip girmediğini söyler (kapanış sonrası yükleme).
func (s *Store) TopupRefundQueued(ctx context.Context, accountID, topupID string) (bool, error) {
	var n int
	err := s.supplier(accountID).QueryRow(ctx, `SELECT count(*) FROM mp_card_refunds WHERE topup_id = $1 AND reason = 'LATE_TOPUP'`, topupID).Scan(&n)
	return n > 0, err
}

// FailTopup, yüklemeyi başarısız kapatır (bakiye değişmez).
func (s *Store) FailTopup(ctx context.Context, accountID, id, msg string) error {
	_, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_topups SET status = 'FAILED', completed_at = now(), error_message = $2
		WHERE id = $1 AND status = 'PENDING'`, id, msg)
	return err
}

// StaleTopups, sonucu gelmemiş eski yüklemeler (uzlaştırma için; platform kapsamı).
func (s *Store) StaleTopups(ctx context.Context, age time.Duration) ([]Topup, error) {
	rows, err := s.platform("jobs").Query(ctx, `SELECT `+topupCols+` FROM mp_topups WHERE status = 'PENDING'
		AND gateway_token IS NOT NULL AND created_at < now() - make_interval(secs => $1) ORDER BY created_at LIMIT 100`, age.Seconds())
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Topup{}
	for rows.Next() {
		t, err := scanTopup(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *t)
	}
	return out, rows.Err()
}

// ChangePackage, paket değişikliğidir. Daha pahalı (ya da eşit) pakete geçiş hemen olur ve ilk ayın aidatı bakiyeden
// düşer, haklar yenilenir; daha ucuz pakete geçiş dönem sonunda uygulanır. Varsayılan pakete geçiş de dönem sonundadır.
func (s *Store) ChangePackage(ctx context.Context, accountID, userID, packageID string) (*Account, string, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var curID, status string
	var curFee int64
	var renews *time.Time
	if err := tx.QueryRow(ctx, `SELECT a.package_id, a.status, p.monthly_fee_kurus, a.package_renews_at FROM mp_supplier_accounts a
		JOIN mp_packages p ON p.id = a.package_id WHERE a.id = $1 FOR UPDATE OF a`, accountID).Scan(&curID, &status, &curFee, &renews); err != nil {
		return nil, "", err
	}
	if status == "CLOSED" || status == "SUSPENDED" {
		return nil, "", userErr(http.StatusConflict, "STATE", "Kapalı ya da askıdaki hesapta paket değiştirilemez")
	}
	p, err := scanPackage(tx.QueryRow(ctx, `SELECT `+packageCols+` FROM mp_packages WHERE id = $1`, packageID))
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && !p.IsActive) {
		return nil, "", userErr(http.StatusUnprocessableEntity, "PACKAGE", "Paket yok ya da satışta değil")
	}
	if err != nil {
		return nil, "", err
	}
	var msg string
	switch {
	case p.ID == curID:
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET next_package_id = NULL, updated_at = now() WHERE id = $1`, accountID); err != nil {
			return nil, "", err
		}
		msg = "Paketiniz değişmedi; bekleyen paket değişikliği varsa iptal edildi."
	case p.MonthlyFeeKurus >= curFee && !p.IsDefault:
		if p.MonthlyFeeKurus > 0 {
			if _, _, err := post(ctx, tx, accountID, "PACKAGE_FEE", -p.MonthlyFeeKurus,
				ledgerRef{pkg: &p.ID, by: strp(userID), note: p.Name + " paketi — ilk ay aidatı"}); err != nil {
				if errors.Is(err, ErrInsufficient) {
					return nil, "", &UserError{Status: http.StatusConflict, Code: "INSUFFICIENT_BALANCE",
						Message: fmt.Sprintf("%s paketinin aylık aidatı için bakiye yetersiz", p.Name)}
				}
				return nil, "", err
			}
		}
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET package_id = $2, next_package_id = NULL,
			package_renews_at = now() + interval '1 month', period_included_left = $3, period_sms_left = $4, updated_at = now()
			WHERE id = $1`, accountID, p.ID, p.IncludedRequests, p.MonthlySMS); err != nil {
			return nil, "", err
		}
		msg = p.Name + " paketine geçildi; aidat bakiyeden düşüldü, aylık haklar tanımlandı."
	default:
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET next_package_id = $2, updated_at = now() WHERE id = $1`,
			accountID, p.ID); err != nil {
			return nil, "", err
		}
		msg = p.Name + " paketine geçiş, mevcut dönemin sonunda uygulanacak."
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, "", err
	}
	a, err := s.Account(ctx, accountID)
	return a, msg, err
}

// RenewalOutcome, aidat yenileme sonucudur (bildirim için).
type RenewalOutcome struct {
	AccountID, Result, PackageName string
	BalanceAfter                   int64
}

// RenewPackages, yenileme zamanı gelmiş hesapların aidatını alır: hedef paket (bekleyen değişiklik ya da mevcut) ücretliyse
// bakiye yetiyorsa düşülür ve dönem uzar; yetmiyorsa varsayılan (ücretsiz) pakete inilir. Hedef ücretsizse ona geçilir.
// Her hesap kendi işleminde ve satır kilidiyle işlenir; yenileme zamanı ileri alındığı için ikinci çalıştırma aidatı yinelemez.
func (s *Store) RenewPackages(ctx context.Context) ([]RenewalOutcome, error) {
	rows, err := s.platform("jobs").Query(ctx, `SELECT id FROM mp_supplier_accounts WHERE package_renews_at <= now()
		AND status <> 'CLOSED' ORDER BY package_renews_at LIMIT 200`)
	if err != nil {
		return nil, err
	}
	ids := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return nil, err
		}
		ids = append(ids, id)
	}
	rows.Close()
	out := []RenewalOutcome{}
	for _, id := range ids {
		o, err := s.renewOne(ctx, id)
		if err != nil {
			return out, fmt.Errorf("hesap %s: %w", id, err)
		}
		if o != nil {
			out = append(out, *o)
		}
	}
	return out, nil
}

func (s *Store) renewOne(ctx context.Context, accountID string) (*RenewalOutcome, error) {
	tx, err := s.platform("jobs").Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var target string
	var renews time.Time
	err = tx.QueryRow(ctx, `SELECT COALESCE(next_package_id, package_id), package_renews_at FROM mp_supplier_accounts
		WHERE id = $1 AND package_renews_at <= now() FOR UPDATE`, accountID).Scan(&target, &renews)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	p, err := scanPackage(tx.QueryRow(ctx, `SELECT `+packageCols+` FROM mp_packages WHERE id = $1`, target))
	if err != nil {
		return nil, err
	}
	o := &RenewalOutcome{AccountID: accountID, PackageName: p.Name}
	// Satıştan kaldırılmış (pasif) paket yeni aboneye satılmaz; mevcut abonenin dönemi normal yenilenir.
	if p.MonthlyFeeKurus == 0 {
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET package_id = $2, next_package_id = NULL, package_renews_at = NULL,
			period_included_left = $3, period_sms_left = $4, updated_at = now() WHERE id = $1`,
			accountID, p.ID, p.IncludedRequests, p.MonthlySMS); err != nil {
			return nil, err
		}
		o.Result = "SWITCHED_FREE"
		return o, tx.Commit(ctx)
	}
	bal, _, perr := post(ctx, tx, accountID, "PACKAGE_FEE", -p.MonthlyFeeKurus,
		ledgerRef{pkg: &p.ID, note: p.Name + " paketi — aylık aidat (" + renews.In(time.Local).Format("02.01.2006") + ")"})
	switch {
	case errors.Is(perr, ErrInsufficient):
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET package_id = (SELECT id FROM mp_packages WHERE is_default),
			next_package_id = NULL, package_renews_at = NULL, period_included_left = 0, period_sms_left = 0, updated_at = now()
			WHERE id = $1`, accountID); err != nil {
			return nil, err
		}
		o.Result = "DOWNGRADED"
	case perr != nil:
		return nil, perr
	default:
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET package_id = $2, next_package_id = NULL,
			package_renews_at = $3::timestamptz + interval '1 month', period_included_left = $4, period_sms_left = $5,
			updated_at = now() WHERE id = $1`, accountID, p.ID, renews, p.IncludedRequests, p.MonthlySMS); err != nil {
			return nil, err
		}
		o.Result, o.BalanceAfter = "RENEWED", bal
	}
	return o, tx.Commit(ctx)
}

// CloseAccount, üyeliği kapatır (platform): kalan bakiye son RefundWindowDays gündeki yüklemelerden karşılanan kısmıyla
// karta iade sırasına girer, kalanı süresi dolan bakiye olarak düşülür (bakiye koşulları m.2–3); bakiye aynı işlemde 0 olur,
// işletmeler kapanır. iyzico iadesi zamanlayıcıyla yapılır.
func (s *Store) CloseAccount(ctx context.Context, adminID, accountID, reason string) (*AccountReview, *RefundOutcome, error) {
	if len([]rune(reason)) < 5 {
		return nil, nil, userErr(http.StatusUnprocessableEntity, "REASON", "Kapanış gerekçesi zorunludur (en az 5 karakter)")
	}
	tx, err := s.platform(adminID).Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var bal int64
	var status string
	err = tx.QueryRow(ctx, `SELECT balance_kurus, status FROM mp_supplier_accounts WHERE id = $1 FOR UPDATE`, accountID).Scan(&bal, &status)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil, ErrNotFound
	}
	if err != nil {
		return nil, nil, err
	}
	if status == "CLOSED" {
		return nil, nil, userErr(http.StatusConflict, "STATE", "Hesap zaten kapalı")
	}
	outcome, err := refundBalance(ctx, tx, accountID, "CLOSURE", adminID, bal)
	if err != nil {
		return nil, nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET status = 'CLOSED', status_reason = $3, closed_at = now(),
		reviewed_by = $2, reviewed_at = now(), package_renews_at = NULL, next_package_id = NULL, updated_at = now() WHERE id = $1`,
		accountID, adminID, reason); err != nil {
		return nil, nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_businesses SET status = 'CLOSED', updated_at = now() WHERE account_id = $1 AND status <> 'CLOSED'`, accountID); err != nil {
		return nil, nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, nil, err
	}
	acc, err := scanAccountReview(s.platform(adminID).QueryRow(ctx, accountSelectReview+` WHERE a.id = $1`, accountID))
	return acc, outcome, err
}

// BalanceDrift, hesap bakiyesi ile defter toplamı arasındaki farkı bulur (tutarlılık sorgusu; platform).
func (s *Store) BalanceDrift(ctx context.Context) ([]string, error) {
	rows, err := s.platform("jobs").Query(ctx, `SELECT a.id::text FROM mp_supplier_accounts a
		LEFT JOIN (SELECT account_id, sum(amount_kurus) s FROM mp_wallet_ledger GROUP BY account_id) l ON l.account_id = a.id
		WHERE a.balance_kurus <> COALESCE(l.s, 0)`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		out = append(out, id)
	}
	return out, rows.Err()
}
