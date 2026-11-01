package store

// Teklif, mesaj, iş ve puan (FAZ M7, K10/K11/K12): yalnız talebi kabul etmiş (ücretini ödemiş) tedarikçi teklif verir ve
// yazışır; alıcı tekliflerden birini seçince iş oluşur, diğer teklifler reddedilir. Tedarikçi "tamamlandı" der; alıcı
// onaylar ya da itiraz eder; yanıt gelmezse ayardaki gün sonunda iş kendiliğinden tamamlanır. Puanı alıcı, yalnız
// tamamlanan işe bir kez verir; tedarikçi bir kez yanıtlar.

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
)

// Offer, tedarikçinin teklifidir.
type Offer struct {
	ID           string    `json:"id"`
	RequestID    string    `json:"request_id"`
	DispatchID   string    `json:"dispatch_id"`
	BusinessID   string    `json:"business_id"`
	BusinessName string    `json:"business_name"`
	AmountKurus  int64     `json:"amount_kurus"`
	Description  string    `json:"description"`
	ValidUntil   string    `json:"valid_until"`
	Status       string    `json:"status"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	// Alıcıya: işletmenin telefonu ve puan özeti (kabul edip ödemiş tedarikçi, K10).
	BusinessPhone *string `json:"business_phone,omitempty"`
	RatingSum     *int    `json:"rating_sum,omitempty"`
	RatingCount   *int    `json:"rating_count,omitempty"`
	CompletedJobs *int    `json:"completed_jobs,omitempty"`
}

// OfferInput, teklif formudur.
type OfferInput struct {
	AmountKurus int64  `json:"amount_kurus"`
	Description string `json:"description"`
	ValidUntil  string `json:"valid_until"`
}

// Message, alıcı ile tek bir tedarikçi arasındaki yazışmadır.
type Message struct {
	ID         string    `json:"id"`
	SenderSide string    `json:"sender_side"`
	Body       string    `json:"body"`
	CreatedAt  time.Time `json:"created_at"`
	Anonymized bool      `json:"anonymized"`
}

// Job, seçilen teklifle oluşan iştir.
type Job struct {
	ID               string     `json:"id"`
	RequestID        string     `json:"request_id"`
	OfferID          string     `json:"offer_id"`
	AccountID        string     `json:"-"`
	BusinessID       string     `json:"business_id"`
	BusinessName     string     `json:"business_name"`
	AmountKurus      int64      `json:"amount_kurus"`
	Status           string     `json:"status"`
	SupplierDoneAt   *time.Time `json:"supplier_done_at"`
	CompletedAt      *time.Time `json:"completed_at"`
	CompletionSource *string    `json:"completion_source"`
	DisputeNote      *string    `json:"dispute_note"`
	CreatedAt        time.Time  `json:"created_at"`
	Review           *Review    `json:"review,omitempty"`
	// Vendor, site adına alımda tedarikçinin fatura bilgisidir (gider/sözleşme kaydı için; 080).
	Vendor *Vendor `json:"vendor,omitempty"`
}

// Vendor, tedarikçi hesabının fatura bilgisidir.
type Vendor struct {
	TradeName string `json:"trade_name"`
	TaxNumber string `json:"tax_number"`
	TaxOffice string `json:"tax_office"`
}

// Review, işletmeye verilen puan ve yorumdur.
type Review struct {
	ID           string     `json:"id"`
	BusinessID   string     `json:"business_id"`
	BusinessName string     `json:"business_name,omitempty"`
	Rating       int        `json:"rating"`
	Comment      string     `json:"comment"`
	Reply        *string    `json:"reply"`
	RepliedAt    *time.Time `json:"replied_at"`
	HiddenAt     *time.Time `json:"hidden_at,omitempty"`
	HiddenReason *string    `json:"hidden_reason,omitempty"`
	CreatedAt    time.Time  `json:"created_at"`
}

// Party, bildirim için talebin karşı tarafıdır.
type Party struct {
	RequestID, PropertyID, RequesterUserID, AccountID, Category string
}

const offerSelect = `SELECT o.id, o.request_id, o.dispatch_id, o.business_id, b.name, o.amount_kurus, o.description,
	to_char(o.valid_until, 'YYYY-MM-DD'), o.status, o.created_at, o.updated_at FROM mp_offers o JOIN mp_businesses b ON b.id = o.business_id`

func scanOffer(r pgx.Row) (*Offer, error) {
	o := &Offer{}
	err := r.Scan(&o.ID, &o.RequestID, &o.DispatchID, &o.BusinessID, &o.BusinessName, &o.AmountKurus, &o.Description,
		&o.ValidUntil, &o.Status, &o.CreatedAt, &o.UpdatedAt)
	return o, err
}

// acceptedDispatch, tedarikçinin talebi kabul ettiği gönderim satırını kilitler; kabul etmediyse 403.
func acceptedDispatch(ctx context.Context, tx pgx.Tx, accountID, requestID string) (dispatchID, businessID string, p *Party, err error) {
	var accepted *time.Time
	p = &Party{RequestID: requestID, AccountID: accountID}
	err = tx.QueryRow(ctx, `SELECT d.id, d.business_id, d.accepted_at, r.property_id, r.requester_user_id, c.name
		FROM mp_request_dispatch d JOIN mp_requests r ON r.id = d.request_id JOIN mp_categories c ON c.id = r.category_id
		WHERE d.request_id = $1 AND d.account_id = $2 FOR UPDATE OF d`, requestID, accountID).
		Scan(&dispatchID, &businessID, &accepted, &p.PropertyID, &p.RequesterUserID, &p.Category)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", "", nil, ErrNotFound
	}
	if err != nil {
		return "", "", nil, err
	}
	if accepted == nil {
		return "", "", nil, userErr(http.StatusForbidden, "NOT_ACCEPTED", "Teklif ve yazışma için önce talebi kabul etmelisiniz")
	}
	return dispatchID, businessID, p, nil
}

// SaveOffer, kabul edilmiş talebe teklif verir; etkin teklif varsa onu günceller.
func (s *Store) SaveOffer(ctx context.Context, accountID, requestID string, in OfferInput) (*Offer, *Party, bool, error) {
	desc := strings.TrimSpace(in.Description)
	if in.AmountKurus <= 0 || desc == "" || utf8.RuneCountInString(desc) > 2000 {
		return nil, nil, false, userErr(http.StatusUnprocessableEntity, "OFFER", "Tutar (kuruş, sıfırdan büyük) ve açıklama (en çok 2000 karakter) zorunludur")
	}
	until, err := time.Parse("2006-01-02", in.ValidUntil)
	if err != nil || until.Before(s.now().Truncate(24*time.Hour)) {
		return nil, nil, false, userErr(http.StatusUnprocessableEntity, "VALID_UNTIL", "Geçerlilik tarihi (YYYY-AA-GG) bugün ya da sonrası olmalı")
	}
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, nil, false, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	dispatchID, businessID, p, err := acceptedDispatch(ctx, tx, accountID, requestID)
	if err != nil {
		return nil, nil, false, err
	}
	var status string
	if err := tx.QueryRow(ctx, `SELECT status FROM mp_requests WHERE id = $1`, requestID).Scan(&status); err != nil {
		return nil, nil, false, err
	}
	if status == "CLOSED" || status == "CANCELLED" {
		return nil, nil, false, userErr(http.StatusConflict, "REQUEST_CLOSED", "Alıcı talebi kapattı ya da bir teklif seçti; yeni teklif verilemez")
	}
	var id string
	created := false
	err = tx.QueryRow(ctx, `UPDATE mp_offers SET amount_kurus = $2, description = $3, valid_until = $4, updated_at = now()
		WHERE dispatch_id = $1 AND status = 'ACTIVE' RETURNING id`, dispatchID, in.AmountKurus, desc, until).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		created = true
		err = tx.QueryRow(ctx, `INSERT INTO mp_offers (request_id, dispatch_id, property_id, account_id, business_id, amount_kurus,
			description, valid_until) VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id`,
			requestID, dispatchID, p.PropertyID, accountID, businessID, in.AmountKurus, desc, until).Scan(&id)
	}
	if err != nil {
		return nil, nil, false, err
	}
	o, err := scanOffer(tx.QueryRow(ctx, offerSelect+` WHERE o.id = $1`, id))
	if err != nil {
		return nil, nil, false, err
	}
	return o, p, created, tx.Commit(ctx)
}

// WithdrawOffer, etkin teklifi geri çeker.
func (s *Store) WithdrawOffer(ctx context.Context, accountID, offerID string) error {
	tag, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_offers SET status = 'WITHDRAWN', updated_at = now()
		WHERE id = $1 AND account_id = $2 AND status = 'ACTIVE'`, offerID, accountID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return userErr(http.StatusConflict, "OFFER_STATE", "Yalnız etkin teklif geri çekilebilir")
	}
	return nil
}

// SupplierDeal, tedarikçinin bir talepteki teklifleri, işi ve itirazıdır.
type SupplierDeal struct {
	Offers  []Offer  `json:"offers"`
	Job     *Job     `json:"job"`
	Dispute *Dispute `json:"dispute"`
}

// SupplierDealOf, tedarikçinin talepteki durumunu döner (kabul etmediyse boş).
func (s *Store) SupplierDealOf(ctx context.Context, accountID, requestID string) (*SupplierDeal, error) {
	sc := s.supplier(accountID)
	d := &SupplierDeal{Offers: []Offer{}}
	rows, err := sc.Query(ctx, offerSelect+` WHERE o.request_id = $1 AND o.account_id = $2 ORDER BY o.created_at DESC`, requestID, accountID)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		o, err := scanOffer(rows)
		if err != nil {
			rows.Close()
			return nil, err
		}
		d.Offers = append(d.Offers, *o)
	}
	rows.Close()
	if j, err := s.jobBy(ctx, sc, `j.request_id = $1 AND j.account_id = $2`, requestID, accountID); err == nil {
		d.Job = j
	} else if !errors.Is(err, ErrNotFound) {
		return nil, err
	}
	if x, err := scanDispute(sc.QueryRow(ctx, disputeSelect+` WHERE x.request_id = $1 AND x.account_id = $2`, requestID, accountID)); err == nil {
		d.Dispute = x
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	return d, nil
}

type rowQ interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

const jobSelect = `SELECT j.id, j.request_id, j.offer_id, j.account_id, j.business_id, b.name, o.amount_kurus, j.status,
	j.supplier_done_at, j.completed_at, j.completion_source, j.dispute_note, j.created_at
	FROM mp_jobs j JOIN mp_businesses b ON b.id = j.business_id JOIN mp_offers o ON o.id = j.offer_id WHERE `

func (s *Store) jobBy(ctx context.Context, q rowQ, where string, args ...any) (*Job, error) {
	j := &Job{}
	err := q.QueryRow(ctx, jobSelect+where, args...).Scan(&j.ID, &j.RequestID, &j.OfferID, &j.AccountID, &j.BusinessID,
		&j.BusinessName, &j.AmountKurus, &j.Status, &j.SupplierDoneAt, &j.CompletedAt, &j.CompletionSource, &j.DisputeNote, &j.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	r := &Review{}
	err = q.QueryRow(ctx, `SELECT id, business_id, rating, comment, reply, replied_at, hidden_at, hidden_reason, created_at
		FROM mp_reviews WHERE job_id = $1`, j.ID).Scan(&r.ID, &r.BusinessID, &r.Rating, &r.Comment, &r.Reply, &r.RepliedAt,
		&r.HiddenAt, &r.HiddenReason, &r.CreatedAt)
	if err == nil {
		j.Review = r
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	return j, nil
}

// buyerRequest, alıcının talebini kilitler: sakin talebinde yalnız sahibi, site talebinde yazma için yönetici.
func buyerRequest(ctx context.Context, tx pgx.Tx, b Buyer, id string, write bool) (*Party, string, error) {
	p := &Party{RequestID: id}
	var buyerType, status string
	err := tx.QueryRow(ctx, `SELECT r.property_id, r.requester_user_id, r.buyer_type, r.status, c.name
		FROM mp_requests r JOIN mp_categories c ON c.id = r.category_id WHERE r.id = $1 FOR UPDATE OF r`, id).
		Scan(&p.PropertyID, &p.RequesterUserID, &buyerType, &status, &p.Category)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, "", ErrNotFound
	}
	if err != nil {
		return nil, "", err
	}
	switch {
	case buyerType == "RESIDENT" && p.RequesterUserID == b.UserID:
	case buyerType == "MANAGEMENT" && (b.Management || (!write && b.Oversight)):
	case buyerType == "MANAGEMENT" && b.Oversight:
		return nil, "", userErr(http.StatusForbidden, "ROLE", "Site talebinde bu işlemi yalnız site yöneticisi yapar")
	default:
		return nil, "", ErrNotFound
	}
	return p, status, nil
}

// BuyerOffers, talebe gelen teklifleri yan yana karşılaştırma için döner (işletme telefonu ve puan özetiyle).
func (s *Store) BuyerOffers(ctx context.Context, b Buyer, id string) ([]Offer, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, _, err := buyerRequest(ctx, tx, b, id, false); err != nil {
		return nil, err
	}
	rows, err := tx.Query(ctx, `SELECT o.id, o.request_id, o.dispatch_id, o.business_id, b.name, o.amount_kurus, o.description,
		to_char(o.valid_until, 'YYYY-MM-DD'), o.status, o.created_at, o.updated_at, b.phone, b.rating_sum, b.rating_count, b.completed_jobs
		FROM mp_offers o JOIN mp_businesses b ON b.id = o.business_id
		WHERE o.request_id = $1 AND o.status <> 'WITHDRAWN' ORDER BY o.amount_kurus, o.created_at`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Offer{}
	for rows.Next() {
		o := Offer{}
		if err := rows.Scan(&o.ID, &o.RequestID, &o.DispatchID, &o.BusinessID, &o.BusinessName, &o.AmountKurus, &o.Description,
			&o.ValidUntil, &o.Status, &o.CreatedAt, &o.UpdatedAt, &o.BusinessPhone, &o.RatingSum, &o.RatingCount, &o.CompletedJobs); err != nil {
			return nil, err
		}
		out = append(out, o)
	}
	return out, rows.Err()
}

// SelectResult, teklif seçiminin sonucudur: seçilen ve reddedilen hesaplar (bildirim için).
type SelectResult struct {
	Job      *Job
	Chosen   string
	Declined []string
	Category string
}

// SelectOffer, alıcının teklifi seçmesidir: iş oluşur, talep kapanır, diğer etkin teklifler reddedilir.
func (s *Store) SelectOffer(ctx context.Context, b Buyer, requestID, offerID string) (*SelectResult, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	p, status, err := buyerRequest(ctx, tx, b, requestID, true)
	if err != nil {
		return nil, err
	}
	if status == "CLOSED" || status == "CANCELLED" {
		return nil, userErr(http.StatusConflict, "REQUEST_CLOSED", "Talep kapalı; teklif seçilemez")
	}
	var accountID, businessID, oStatus string
	var until time.Time
	err = tx.QueryRow(ctx, `SELECT account_id, business_id, status, valid_until FROM mp_offers WHERE id = $1 AND request_id = $2 FOR UPDATE`,
		offerID, requestID).Scan(&accountID, &businessID, &oStatus, &until)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if oStatus != "ACTIVE" {
		return nil, userErr(http.StatusConflict, "OFFER_STATE", "Bu teklif artık geçerli değil")
	}
	if until.Before(s.now().Truncate(24 * time.Hour)) {
		return nil, userErr(http.StatusConflict, "OFFER_EXPIRED", "Teklifin geçerlilik süresi dolmuş; tedarikçiden güncellemesini isteyin")
	}
	var jobID string
	if err := tx.QueryRow(ctx, `INSERT INTO mp_jobs (request_id, offer_id, property_id, account_id, business_id)
		VALUES ($1, $2, $3, $4, $5) RETURNING id`, requestID, offerID, p.PropertyID, accountID, businessID).Scan(&jobID); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_offers SET status = 'ACCEPTED', updated_at = now() WHERE id = $1`, offerID); err != nil {
		return nil, err
	}
	res := &SelectResult{Chosen: accountID, Category: p.Category, Declined: []string{}}
	rows, err := tx.Query(ctx, `UPDATE mp_offers SET status = 'DECLINED', updated_at = now()
		WHERE request_id = $1 AND status = 'ACTIVE' RETURNING account_id`, requestID)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		var a string
		if err := rows.Scan(&a); err != nil {
			rows.Close()
			return nil, err
		}
		res.Declined = append(res.Declined, a)
	}
	rows.Close()
	if _, err := tx.Exec(ctx, `UPDATE mp_requests SET status = 'CLOSED', closed_at = now() WHERE id = $1`, requestID); err != nil {
		return nil, err
	}
	if res.Job, err = s.jobBy(ctx, tx, `j.id = $1`, jobID); err != nil {
		return nil, err
	}
	return res, tx.Commit(ctx)
}

// CloseRequest, alıcının talebi teklif seçmeden kapatmasıdır; kabul ücretleri iade edilmez (aday teslim edilmiştir).
// Dönen değer, etkin teklifi reddedilen hesaplardır.
func (s *Store) CloseRequest(ctx context.Context, b Buyer, requestID string) ([]string, string, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	p, status, err := buyerRequest(ctx, tx, b, requestID, true)
	if err != nil {
		return nil, "", err
	}
	if status == "CLOSED" || status == "CANCELLED" {
		return nil, "", userErr(http.StatusConflict, "REQUEST_CLOSED", "Talep zaten kapalı")
	}
	rows, err := tx.Query(ctx, `UPDATE mp_offers SET status = 'DECLINED', updated_at = now()
		WHERE request_id = $1 AND status = 'ACTIVE' RETURNING account_id`, requestID)
	if err != nil {
		return nil, "", err
	}
	declined := []string{}
	for rows.Next() {
		var a string
		if err := rows.Scan(&a); err != nil {
			rows.Close()
			return nil, "", err
		}
		declined = append(declined, a)
	}
	rows.Close()
	if _, err := tx.Exec(ctx, `UPDATE mp_requests SET status = 'CANCELLED', closed_at = now() WHERE id = $1`, requestID); err != nil {
		return nil, "", err
	}
	return declined, p.Category, tx.Commit(ctx)
}

// --- Mesajlar ---

func listMessages(ctx context.Context, tx pgx.Tx, dispatchID string, before *time.Time, limit int) ([]Message, error) {
	if limit < 1 || limit > 200 {
		limit = 50
	}
	rows, err := tx.Query(ctx, `SELECT id, sender_side, body, created_at, anonymized_at IS NOT NULL FROM mp_messages
		WHERE dispatch_id = $1 AND ($2::timestamptz IS NULL OR created_at < $2) ORDER BY created_at DESC LIMIT $3`, dispatchID, before, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Message{}
	for rows.Next() {
		m := Message{}
		if err := rows.Scan(&m.ID, &m.SenderSide, &m.Body, &m.CreatedAt, &m.Anonymized); err != nil {
			return nil, err
		}
		out = append(out, m)
	}
	return out, rows.Err()
}

func checkBody(body string) (string, error) {
	body = strings.TrimSpace(body)
	if body == "" || utf8.RuneCountInString(body) > 2000 {
		return "", userErr(http.StatusUnprocessableEntity, "BODY", "Mesaj boş olamaz (en çok 2000 karakter)")
	}
	return body, nil
}

// SupplierMessages, tedarikçinin talepteki yazışmasıdır (yalnız kabul ettiyse).
func (s *Store) SupplierMessages(ctx context.Context, accountID, requestID string, before *time.Time, limit int) ([]Message, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	dispatchID, _, _, err := acceptedDispatch(ctx, tx, accountID, requestID)
	if err != nil {
		return nil, err
	}
	return listMessages(ctx, tx, dispatchID, before, limit)
}

// SupplierSend, tedarikçinin alıcıya mesajıdır.
func (s *Store) SupplierSend(ctx context.Context, accountID, userID, requestID, body string) (*Message, *Party, error) {
	body, err := checkBody(body)
	if err != nil {
		return nil, nil, err
	}
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	dispatchID, _, p, err := acceptedDispatch(ctx, tx, accountID, requestID)
	if err != nil {
		return nil, nil, err
	}
	m := &Message{SenderSide: "SUPPLIER", Body: body}
	if err := tx.QueryRow(ctx, `INSERT INTO mp_messages (request_id, dispatch_id, property_id, account_id, sender_side, sender_user_id, body)
		VALUES ($1,$2,$3,$4,'SUPPLIER',$5,$6) RETURNING id, created_at`, requestID, dispatchID, p.PropertyID, accountID, userID, body).
		Scan(&m.ID, &m.CreatedAt); err != nil {
		return nil, nil, err
	}
	return m, p, tx.Commit(ctx)
}

// buyerThread, alıcının bir tedarikçiyle yazışma satırıdır (kabul edilmiş gönderim).
func buyerThread(ctx context.Context, tx pgx.Tx, requestID, dispatchID string) (string, error) {
	var accountID string
	var accepted *time.Time
	err := tx.QueryRow(ctx, `SELECT account_id, accepted_at FROM mp_request_dispatch WHERE id = $1 AND request_id = $2`,
		dispatchID, requestID).Scan(&accountID, &accepted)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && accepted == nil) {
		return "", ErrNotFound
	}
	return accountID, err
}

// BuyerMessages, alıcının bir tedarikçiyle yazışmasıdır.
func (s *Store) BuyerMessages(ctx context.Context, b Buyer, requestID, dispatchID string, before *time.Time, limit int) ([]Message, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, _, err := buyerRequest(ctx, tx, b, requestID, false); err != nil {
		return nil, err
	}
	if _, err := buyerThread(ctx, tx, requestID, dispatchID); err != nil {
		return nil, err
	}
	return listMessages(ctx, tx, dispatchID, before, limit)
}

// BuyerSend, alıcının tedarikçiye mesajıdır (daire numarası burada paylaşılır).
func (s *Store) BuyerSend(ctx context.Context, b Buyer, requestID, dispatchID, body string) (*Message, *Party, error) {
	body, err := checkBody(body)
	if err != nil {
		return nil, nil, err
	}
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	p, _, err := buyerRequest(ctx, tx, b, requestID, true)
	if err != nil {
		return nil, nil, err
	}
	if p.AccountID, err = buyerThread(ctx, tx, requestID, dispatchID); err != nil {
		return nil, nil, err
	}
	m := &Message{SenderSide: "BUYER", Body: body}
	if err := tx.QueryRow(ctx, `INSERT INTO mp_messages (request_id, dispatch_id, property_id, account_id, sender_side, sender_user_id, body)
		VALUES ($1,$2,$3,$4,'BUYER',$5,$6) RETURNING id, created_at`, requestID, dispatchID, p.PropertyID, p.AccountID, b.UserID, body).
		Scan(&m.ID, &m.CreatedAt); err != nil {
		return nil, nil, err
	}
	return m, p, tx.Commit(ctx)
}

// --- İş ---

// SupplierDone, tedarikçinin işi tamamladığını bildirmesidir (ACTIVE → DONE_CLAIMED).
func (s *Store) SupplierDone(ctx context.Context, accountID, jobID string) (*Job, *Party, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	p := &Party{AccountID: accountID}
	err = tx.QueryRow(ctx, `UPDATE mp_jobs j SET status = 'DONE_CLAIMED', supplier_done_at = now()
		FROM mp_requests r, mp_categories c WHERE j.id = $1 AND j.account_id = $2 AND j.status = 'ACTIVE'
		  AND r.id = j.request_id AND c.id = r.category_id
		RETURNING j.request_id, j.property_id, r.requester_user_id, c.name`, jobID, accountID).
		Scan(&p.RequestID, &p.PropertyID, &p.RequesterUserID, &p.Category)
	if errors.Is(err, pgx.ErrNoRows) {
		if _, e := s.jobBy(ctx, tx, `j.id = $1 AND j.account_id = $2`, jobID, accountID); e != nil {
			return nil, nil, e
		}
		return nil, nil, userErr(http.StatusConflict, "JOB_STATE", "Yalnız süren iş tamamlandı olarak bildirilebilir")
	}
	if err != nil {
		return nil, nil, err
	}
	j, err := s.jobBy(ctx, tx, `j.id = $1`, jobID)
	if err != nil {
		return nil, nil, err
	}
	return j, p, tx.Commit(ctx)
}

// BuyerJob, talebin işidir.
func (s *Store) BuyerJob(ctx context.Context, b Buyer, requestID string) (*Job, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, _, err := buyerRequest(ctx, tx, b, requestID, false); err != nil {
		return nil, err
	}
	j, err := s.jobBy(ctx, tx, `j.request_id = $1`, requestID)
	if err != nil {
		return nil, err
	}
	v := &Vendor{}
	err = tx.QueryRow(ctx, `SELECT trade_name, tax_number, tax_office FROM mp_job_vendor($1)`, j.ID).Scan(&v.TradeName, &v.TaxNumber, &v.TaxOffice)
	if err == nil {
		j.Vendor = v
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	return j, nil
}

// BuyerJobDecision, alıcının onayı (COMPLETED, BUYER) ya da itirazıdır (DISPUTED, not zorunlu). İtirazdaki iş otomatik
// tamamlanmaz; alıcı sonradan onaylayabilir.
func (s *Store) BuyerJobDecision(ctx context.Context, b Buyer, requestID string, confirm bool, note string) (*Job, error) {
	note = strings.TrimSpace(note)
	if !confirm && utf8.RuneCountInString(note) < 5 {
		return nil, userErr(http.StatusUnprocessableEntity, "NOTE", "İtiraz gerekçesi zorunludur (en az 5 karakter)")
	}
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, _, err := buyerRequest(ctx, tx, b, requestID, true); err != nil {
		return nil, err
	}
	j, err := s.jobBy(ctx, tx, `j.request_id = $1`, requestID)
	if err != nil {
		return nil, err
	}
	switch {
	case confirm && (j.Status == "DONE_CLAIMED" || j.Status == "DISPUTED"):
		_, err = tx.Exec(ctx, `UPDATE mp_jobs SET status = 'COMPLETED', completed_at = now(), completion_source = 'BUYER' WHERE id = $1`, j.ID)
	case !confirm && j.Status == "DONE_CLAIMED":
		_, err = tx.Exec(ctx, `UPDATE mp_jobs SET status = 'DISPUTED', dispute_note = $2 WHERE id = $1`, j.ID, note)
	default:
		return nil, userErr(http.StatusConflict, "JOB_STATE", "İş bu işlem için uygun durumda değil (tedarikçi tamamlandı demeli)")
	}
	if err != nil {
		return nil, err
	}
	if j, err = s.jobBy(ctx, tx, `j.id = $1`, j.ID); err != nil {
		return nil, err
	}
	return j, tx.Commit(ctx)
}

// AutoCompleted, kendiliğinden tamamlanan iştir.
type AutoCompleted struct {
	JobID, AccountID string
	Party            Party
}

// AutoCompleteJobs: tedarikçi "tamamlandı" dedikten sonra alıcı ayardaki gün içinde yanıt vermezse iş tamamlanır.
func (s *Store) AutoCompleteJobs(ctx context.Context) ([]AutoCompleted, error) {
	days, err := s.setting(ctx, "auto_complete_days")
	if err != nil {
		return nil, err
	}
	tx, err := s.platform("jobs").Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	rows, err := tx.Query(ctx, `UPDATE mp_jobs j SET status = 'COMPLETED', completed_at = now(), completion_source = 'AUTO'
		FROM mp_requests r, mp_categories c
		WHERE j.status = 'DONE_CLAIMED' AND j.supplier_done_at <= now() - make_interval(days => $1)
		  AND r.id = j.request_id AND c.id = r.category_id
		RETURNING j.id, j.account_id, j.request_id, j.property_id, r.requester_user_id, c.name`, days)
	if err != nil {
		return nil, err
	}
	out := []AutoCompleted{}
	for rows.Next() {
		a := AutoCompleted{}
		if err := rows.Scan(&a.JobID, &a.AccountID, &a.Party.RequestID, &a.Party.PropertyID, &a.Party.RequesterUserID, &a.Party.Category); err != nil {
			rows.Close()
			return nil, err
		}
		a.Party.AccountID = a.AccountID
		out = append(out, a)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, tx.Commit(ctx)
}

// --- Puan ---

// AddReview, alıcının tamamlanan işe puanı ve yorumudur (işe bir kez; işletmeye yazılır).
func (s *Store) AddReview(ctx context.Context, b Buyer, requestID string, rating int, comment string) (*Review, string, error) {
	comment = strings.TrimSpace(comment)
	if rating < 1 || rating > 5 || utf8.RuneCountInString(comment) > 1000 {
		return nil, "", userErr(http.StatusUnprocessableEntity, "REVIEW", "Puan 1–5 arası olmalı; yorum en çok 1000 karakter")
	}
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, _, err := buyerRequest(ctx, tx, b, requestID, true); err != nil {
		return nil, "", err
	}
	j, err := s.jobBy(ctx, tx, `j.request_id = $1`, requestID)
	if err != nil {
		return nil, "", err
	}
	if j.Status != "COMPLETED" {
		return nil, "", userErr(http.StatusConflict, "JOB_NOT_COMPLETED", "Puan yalnız tamamlanan işe verilir")
	}
	if j.Review != nil {
		return nil, "", userErr(http.StatusConflict, "ALREADY_REVIEWED", "Bu işe zaten puan verdiniz")
	}
	r := &Review{BusinessID: j.BusinessID, Rating: rating, Comment: comment}
	if err := tx.QueryRow(ctx, `INSERT INTO mp_reviews (job_id, property_id, account_id, business_id, rating, comment)
		VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, created_at`, j.ID, b.PropertyID, j.AccountID, j.BusinessID, rating, comment).
		Scan(&r.ID, &r.CreatedAt); err != nil {
		return nil, "", err
	}
	return r, j.AccountID, tx.Commit(ctx)
}

// ReplyReview, tedarikçinin yoruma yanıtıdır (bir kez; veritabanı tetikleyicisi de korur).
func (s *Store) ReplyReview(ctx context.Context, accountID, reviewID, reply string) error {
	reply = strings.TrimSpace(reply)
	if reply == "" || utf8.RuneCountInString(reply) > 1000 {
		return userErr(http.StatusUnprocessableEntity, "REPLY", "Yanıt boş olamaz (en çok 1000 karakter)")
	}
	tag, err := s.supplier(accountID).Exec(ctx, `UPDATE mp_reviews SET reply = $3, replied_at = now()
		WHERE id = $1 AND account_id = $2 AND reply IS NULL`, reviewID, accountID, reply)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		var n int
		if err := s.supplier(accountID).QueryRow(ctx, `SELECT count(*) FROM mp_reviews WHERE id = $1 AND account_id = $2`, reviewID, accountID).Scan(&n); err != nil {
			return err
		}
		if n == 0 {
			return ErrNotFound
		}
		return userErr(http.StatusConflict, "ALREADY_REPLIED", "Bu yoruma zaten yanıt verdiniz")
	}
	return nil
}

// SupplierReviews, tedarikçinin işletmelerine verilen puanlardır (gizlenenler gerekçesiyle).
func (s *Store) SupplierReviews(ctx context.Context, accountID string) ([]Review, error) {
	rows, err := s.supplier(accountID).Query(ctx, `SELECT r.id, r.business_id, b.name, r.rating, r.comment, r.reply, r.replied_at,
		r.hidden_at, r.hidden_reason, r.created_at FROM mp_reviews r JOIN mp_businesses b ON b.id = r.business_id
		WHERE r.account_id = $1 ORDER BY r.created_at DESC LIMIT 200`, accountID)
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
