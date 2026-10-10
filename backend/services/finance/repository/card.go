package repository

// Kartla ödeme durum makinesi (migration 060, TEST_RAPORU 2.5, Apsiyon BUG-09).

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

// ErrUnknownToken: geri dönüş jetonu hiçbir kart ödemesine ait değil.
var ErrUnknownToken = errors.New("ödeme jetonu tanınmadı")

// CardPayment, kart ödemesinin durumudur.
type CardPayment struct {
	ID            string     `json:"payment_id"`
	PropertyID    string     `json:"-"`
	UserID        string     `json:"-"`
	Status        string     `json:"status"`
	GatewayStatus *string    `json:"gateway_status,omitempty"`
	AmountKurus   int64      `json:"amount_kurus"`
	Token         *string    `json:"-"`
	ErrorCode     *string    `json:"error_code,omitempty"`
	ErrorMessage  *string    `json:"error_message,omitempty"`
	FailureKind   *string    `json:"failure_kind,omitempty"`
	ValueDate     *time.Time `json:"value_date,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
	CompletedAt   *time.Time `json:"completed_at,omitempty"`
}

// BuyerInfo, ödeme formu için alıcı ve site bilgisidir.
type BuyerInfo struct {
	FirstName, LastName, Phone, Email string
	PropertyName, City, Address       string
	Units                             []string
}

// SystemFailedValueDate: aynı tahakkuklar için son iki günde SİSTEM kaynaklı başarısız olmuş kart
// denemesinin en eski valör günü (yoksa nil). Yeni deneme bu günü devralır — sistem hatasının faizi
// kullanıcıya yüklenmez.
func (r *FinanceRepository) SystemFailedValueDate(ctx context.Context, propertyID, userID string, assessmentIDs []string) (*time.Time, error) {
	var d *time.Time
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT min(p.value_date) FROM payments p
		WHERE p.property_id = $1 AND p.user_id = $2 AND p.status = 'FAILED' AND p.failure_kind = 'SYSTEM'
		  AND p.gateway IS NOT NULL AND p.value_date IS NOT NULL AND COALESCE(p.completed_at, p.created_at) > now() - interval '2 days'
		  AND EXISTS (SELECT 1 FROM payment_assessments pa WHERE pa.payment_id = p.id AND pa.assessment_id = ANY($3))`,
		propertyID, userID, assessmentIDs).Scan(&d)
	return d, err
}

// BuyerInfo, ödeme formu için kullanıcının ve sitenin bilgisini verir.
func (r *FinanceRepository) BuyerInfo(ctx context.Context, propertyID, userID string, assessmentIDs []string) (*BuyerInfo, error) {
	b := &BuyerInfo{}
	var email *string
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT u.first_name, u.last_name, COALESCE(u.phone,''), u.email, p.name, COALESCE(p.city,''), COALESCE(p.address,'')
		FROM users u, properties p WHERE u.id = $1 AND p.id = $2`, userID, propertyID).
		Scan(&b.FirstName, &b.LastName, &b.Phone, &email, &b.PropertyName, &b.City, &b.Address); err != nil {
		return nil, err
	}
	if email != nil {
		b.Email = *email
	}
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT DISTINCT COALESCE(u.block,'') || '-' || COALESCE(u.door_number,'')
		FROM monthly_assessments ma JOIN units u ON u.id = ma.unit_id WHERE ma.id = ANY($1)`, assessmentIDs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, err
		}
		b.Units = append(b.Units, s)
	}
	return b, rows.Err()
}

// PaymentLines, sepet kalemleri için ödemenin tahakkuk dağılımını verir.
func (r *FinanceRepository) PaymentLines(ctx context.Context, propertyID, paymentID string) ([]struct {
	AssessmentID, Label string
	Kurus               int64
}, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT pa.assessment_id::text,
		       CASE WHEN ma.kind = 'OPENING' THEN 'Devir bakiyesi' ELSE to_char(make_date(ma.period_year, ma.period_month, 1), 'YYYY-MM') || ' aidat' END,
		       round(pa.amount * 100)::bigint
		FROM payment_assessments pa JOIN monthly_assessments ma ON ma.id = pa.assessment_id
		WHERE pa.payment_id = $1 ORDER BY ma.due_date`, paymentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []struct {
		AssessmentID, Label string
		Kurus               int64
	}
	for rows.Next() {
		var l struct {
			AssessmentID, Label string
			Kurus               int64
		}
		if err := rows.Scan(&l.AssessmentID, &l.Label, &l.Kurus); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	return out, rows.Err()
}

// SetCardInitiated, ödeme sayfası açılan ödemeye jetonu yazar.
func (r *FinanceRepository) SetCardInitiated(ctx context.Context, propertyID, paymentID, gateway, token string) error {
	_, err := r.scope(propertyID).Exec(ctx, `UPDATE payments SET gateway = $2, gateway_status = 'INITIATED', gateway_token = $3,
		gateway_updated_at = now() WHERE id = $1 AND status = 'PENDING'`, paymentID, gateway, token)
	return err
}

// CardPaymentByToken, jetondan ödemeyi ve sitesini bulur (geri dönüş kimliksizdir).
func (r *FinanceRepository) CardPaymentByToken(ctx context.Context, token string) (string, string, error) {
	var pid, prop string
	err := r.pool.QueryRow(ctx, `SELECT payment_id::text, property_id::text FROM card_payment_by_token($1)`, token).Scan(&pid, &prop)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", ErrUnknownToken
	}
	return pid, prop, err
}

// StaleCardPayments, sonucu gelmemiş eski kart ödemeleri (ödeme, site).
func (r *FinanceRepository) StaleCardPayments(ctx context.Context, ageSecs int) ([][2]string, error) {
	rows, err := r.pool.Query(ctx, `SELECT payment_id::text, property_id::text FROM card_payments_stale($1)`, ageSecs)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out [][2]string
	for rows.Next() {
		var a, b string
		if err := rows.Scan(&a, &b); err != nil {
			return nil, err
		}
		out = append(out, [2]string{a, b})
	}
	return out, rows.Err()
}

// GetCardPayment, ödemenin kart durumunu verir.
func (r *FinanceRepository) GetCardPayment(ctx context.Context, propertyID, paymentID string) (*CardPayment, error) {
	var c CardPayment
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT id::text, property_id::text, user_id::text, status, gateway_status, round(amount*100)::bigint, gateway_token,
		       gateway_error_code, gateway_error_message, failure_kind, value_date, created_at, completed_at
		FROM payments WHERE id = $1 AND property_id = $2`, paymentID, propertyID).
		Scan(&c.ID, &c.PropertyID, &c.UserID, &c.Status, &c.GatewayStatus, &c.AmountKurus, &c.Token, &c.ErrorCode, &c.ErrorMessage,
			&c.FailureKind, &c.ValueDate, &c.CreatedAt, &c.CompletedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrPaymentNotFound
	}
	return &c, err
}

// MarkCardProcessing, geri dönüş alınan ödemeyi PROCESSING yapar (yalnızca INITIATED'dan).
func (r *FinanceRepository) MarkCardProcessing(ctx context.Context, propertyID, paymentID string) error {
	_, err := r.scope(propertyID).Exec(ctx, `UPDATE payments SET gateway_status = 'PROCESSING', gateway_updated_at = now()
		WHERE id = $1 AND status = 'PENDING' AND gateway_status = 'INITIATED'`, paymentID)
	return err
}

// CompleteCardPayment, başarılı kart ödemesini onaylar: borç düşer, zincire yazılır (tek işlem).
// Ödeme zaten sonuçlanmışsa hiçbir şey yapmaz (idempotent; false döner).
func (r *FinanceRepository) CompleteCardPayment(ctx context.Context, propertyID, paymentID, gatewayPaymentID string) (bool, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return false, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var status string
	if err := tx.QueryRow(ctx, `SELECT status FROM payments WHERE id = $1 FOR UPDATE`, paymentID).Scan(&status); err != nil {
		return false, err
	}
	if status != "PENDING" {
		return false, nil
	}
	if err := confirmPaymentTx(ctx, tx, paymentID, propertyID, "iyzico:"+gatewayPaymentID, ""); err != nil {
		return false, err
	}
	if _, err := tx.Exec(ctx, `UPDATE payments SET gateway_status = 'SUCCEEDED', gateway_payment_id = $2, gateway_updated_at = now()
		WHERE id = $1`, paymentID, gatewayPaymentID); err != nil {
		return false, err
	}
	return true, tx.Commit(ctx)
}

// FailCardPayment, kart ödemesini başarısız (ya da zaman aşımı) olarak kapatır; borç değişmez.
func (r *FinanceRepository) FailCardPayment(ctx context.Context, propertyID, paymentID, gatewayStatus, code, message, kind string) (bool, error) {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE payments SET status = 'FAILED', completed_at = now(), gateway = COALESCE(gateway, 'IYZICO'),
		       gateway_status = $2, gateway_error_code = NULLIF($3,''),
		       gateway_error_message = $4, failure_kind = $5, gateway_updated_at = now()
		WHERE id = $1 AND status = 'PENDING'`, paymentID, gatewayStatus, code, message, kind)
	if err != nil {
		return false, err
	}
	return tag.RowsAffected() > 0, nil
}
