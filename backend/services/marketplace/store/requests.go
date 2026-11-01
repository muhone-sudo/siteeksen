package store

// Talepler (FAZ M6, K9/K10): alıcı (site kapsamı) talep açar; eşleşen hesaplara gönderim satırı yazılır (ücretli paket
// hemen, diğerleri öncelik penceresi sonunda görür). Tedarikçi kendi kapsamında maskeli önizlemeyi görür; kabul ettiğinde
// ücret aynı işlemde bakiyeden (ya da paketin dahil talep hakkından) düşer ve iletişim bilgisi açılır.

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5"
	"github.com/siteeksen/backend/services/marketplace/rules"
)

// Buyer, talep açan kişidir: Management site adına talep açar (yönetici), Oversight site taleplerini okur
// (yönetici, kurul üyesi, denetçi).
type Buyer struct {
	UserID, PropertyID    string
	Management, Oversight bool
}

// RequestInput, talep formudur.
type RequestInput struct {
	CategoryID       string `json:"category_id"`
	BuyerType        string `json:"buyer_type"`
	UnitID           string `json:"unit_id"`
	TargetBusinessID string `json:"target_business_id"`
	Description      string `json:"description"`
	PreferredTime    string `json:"preferred_time"`
	PhoneHidden      bool   `json:"phone_hidden"`
	Consent          bool   `json:"consent"`
}

// BuyerRequest, alıcının gördüğü taleptir.
type BuyerRequest struct {
	ID               string       `json:"id"`
	BuyerType        string       `json:"buyer_type"`
	UnitID           *string      `json:"unit_id"`
	CategoryID       string       `json:"category_id"`
	CategoryName     string       `json:"category_name"`
	TargetBusinessID *string      `json:"target_business_id"`
	Description      string       `json:"description"`
	PreferredTime    string       `json:"preferred_time"`
	PhoneHidden      bool         `json:"phone_hidden"`
	PhotoCount       int          `json:"photo_count"`
	PhotoStatuses    []PhotoState `json:"photo_statuses"`
	Status           string       `json:"status"`
	AcceptedCount    int          `json:"accepted_count"`
	MaxAccepts       int          `json:"max_accepts"`
	DispatchCount    int          `json:"dispatch_count"`
	ExpiresAt        time.Time    `json:"expires_at"`
	ClosedAt         *time.Time   `json:"closed_at"`
	CreatedAt        time.Time    `json:"created_at"`
	Masked           bool         `json:"masked,omitempty"`
	Accepted         []Acceptor   `json:"accepted,omitempty"`
}

// PhotoState, talep fotoğrafının denetim durumudur (M13.4): tedarikçiye yalnız APPROVED olanlar gösterilir.
type PhotoState struct {
	Status string  `json:"status"`
	Reason *string `json:"reason"`
}

// Acceptor, talebi kabul etmiş işletmedir (alıcıya görünen).
type Acceptor struct {
	BusinessID   string    `json:"business_id"`
	BusinessName string    `json:"business_name"`
	AcceptedAt   time.Time `json:"accepted_at"`
}

// RequestContact, kabulden sonra tedarikçiye açılan iletişim bilgisidir (daire numarası mesajla paylaşılır).
type RequestContact struct {
	Name        string  `json:"name"`
	Phone       *string `json:"phone"`
	SiteName    string  `json:"site_name"`
	SiteAddress string  `json:"site_address"`
}

// SupplierRequest, tedarikçinin gördüğü taleptir: kabulden önce yalnız maskeli önizleme (ad, telefon, adres YOK).
type SupplierRequest struct {
	ID            string          `json:"id"`
	BuyerType     string          `json:"buyer_type"`
	CategoryName  string          `json:"category_name"`
	City          string          `json:"city"`
	District      string          `json:"district"`
	DistanceM     *int            `json:"distance_m"`
	BusinessID    string          `json:"business_id"`
	BusinessName  string          `json:"business_name"`
	Description   string          `json:"description"`
	PreferredTime string          `json:"preferred_time"`
	PhoneHidden   bool            `json:"phone_hidden"`
	PhotoCount    int             `json:"photo_count"`
	Direct        bool            `json:"direct"`
	Status        string          `json:"status"`
	AcceptedCount int             `json:"accepted_count"`
	MaxAccepts    int             `json:"max_accepts"`
	ExpiresAt     time.Time       `json:"expires_at"`
	VisibleAt     time.Time       `json:"visible_at"`
	AcceptedAt    *time.Time      `json:"accepted_at"`
	FeeKurus      int64           `json:"fee_kurus"`
	UsesIncluded  bool            `json:"uses_included"`
	CanAfford     bool            `json:"can_afford"`
	Contact       *RequestContact `json:"contact,omitempty"`
	OfferStatus   *string         `json:"offer_status"`
	JobStatus     *string         `json:"job_status"`
	CreatedAt     time.Time       `json:"created_at"`
}

const maxRequestPhotos = 3

func (s *Store) candidates(ctx context.Context, tx pgx.Tx, categoryID string) ([]rules.Candidate, error) {
	rows, err := tx.Query(ctx, `SELECT b.id, b.account_id, b.latitude::float8, b.longitude::float8, b.city, b.district,
		b.service_area, COALESCE(b.radius_km, 0), ap.priority_access
		FROM mp_businesses b
		JOIN mp_business_categories bc ON bc.business_id = b.id AND bc.category_id = $1
		CROSS JOIN LATERAL mp_account_public(b.account_id) ap
		WHERE b.status = 'PUBLISHED' AND ap.approved ORDER BY b.id`, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []rules.Candidate{}
	for rows.Next() {
		var c rules.Candidate
		if err := rows.Scan(&c.BusinessID, &c.AccountID, &c.Area.Lat, &c.Area.Lng, &c.Area.City, &c.Area.District,
			&c.Area.Kind, &c.Area.RadiusKm, &c.Priority); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

type siteInfo struct {
	name, address string
	rules.Site
}

// match, talebin gideceği hesapları bulur (site kapsamındaki işlemde).
func (s *Store) match(ctx context.Context, tx pgx.Tx, b Buyer, categoryID, buyerType, target string) ([]rules.Dispatch, *siteInfo, error) {
	si := &siteInfo{}
	if err := tx.QueryRow(ctx, `SELECT name, COALESCE(address, ''), COALESCE(city, ''), COALESCE(district, ''),
		latitude::float8, longitude::float8 FROM properties WHERE id = $1`, b.PropertyID).
		Scan(&si.name, &si.address, &si.City, &si.District, &si.Lat, &si.Lng); err != nil {
		return nil, nil, err
	}
	cands, err := s.candidates(ctx, tx, categoryID)
	if err != nil {
		return nil, nil, err
	}
	excluded := map[string]bool{}
	if buyerType == "MANAGEMENT" {
		rows, err := tx.Query(ctx, `SELECT mp_conflicted_accounts($1)::text`, b.PropertyID)
		if err != nil {
			return nil, nil, err
		}
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				rows.Close()
				return nil, nil, err
			}
			excluded[id] = true
		}
		rows.Close()
	}
	return rules.Match(cands, si.Site, excluded, target), si, nil
}

// category, talep kategorisini alıcı türüne göre doğrular.
func category(ctx context.Context, tx pgx.Tx, id, buyerType string) (string, error) {
	var name, scope string
	var active bool
	err := tx.QueryRow(ctx, `SELECT name, buyer_scope, is_active FROM mp_categories WHERE id = $1`, id).Scan(&name, &scope, &active)
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && !active) {
		return "", userErr(http.StatusUnprocessableEntity, "CATEGORY", "Kategori yok ya da talebe kapalı")
	}
	if err != nil {
		return "", err
	}
	if scope != "BOTH" && scope != buyerType {
		if buyerType == "RESIDENT" {
			return "", userErr(http.StatusUnprocessableEntity, "CATEGORY_SCOPE", name+" kategorisinde yalnız site yönetimi talep açabilir")
		}
		return "", userErr(http.StatusUnprocessableEntity, "CATEGORY_SCOPE", name+" kategorisi sakinlerin kendi daireleri içindir")
	}
	return name, nil
}

func checkBuyerType(b Buyer, buyerType string) error {
	switch buyerType {
	case "RESIDENT":
		return nil
	case "MANAGEMENT":
		if !b.Management {
			return userErr(http.StatusForbidden, "ROLE", "Site adına talebi yalnız site yöneticisi açabilir")
		}
		return nil
	}
	return userErr(http.StatusUnprocessableEntity, "BUYER_TYPE", "buyer_type RESIDENT ya da MANAGEMENT olmalı")
}

// MatchCount, göndermeden önce "yakınınızda bu kategoride N onaylı işletme var" bilgisidir.
func (s *Store) MatchCount(ctx context.Context, b Buyer, categoryID, buyerType, target string) (int, error) {
	if err := checkBuyerType(b, buyerType); err != nil {
		return 0, err
	}
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := category(ctx, tx, categoryID, buyerType); err != nil {
		return 0, err
	}
	d, _, err := s.match(ctx, tx, b, categoryID, buyerType, target)
	return len(d), err
}

// CreateRequest, talebi açar ve eşleşen hesaplara gönderir. Dönen değer talep kimliği ve gönderim sayısıdır.
func (s *Store) CreateRequest(ctx context.Context, b Buyer, in RequestInput) (string, int, error) {
	if err := checkBuyerType(b, in.BuyerType); err != nil {
		return "", 0, err
	}
	desc := strings.TrimSpace(in.Description)
	if desc == "" || utf8.RuneCountInString(desc) > 2000 {
		return "", 0, userErr(http.StatusUnprocessableEntity, "DESCRIPTION", "Açıklama zorunludur (en çok 2000 karakter)")
	}
	pref := strings.TrimSpace(in.PreferredTime)
	if utf8.RuneCountInString(pref) > 200 {
		return "", 0, userErr(http.StatusUnprocessableEntity, "PREFERRED_TIME", "Zaman tercihi en çok 200 karakter")
	}
	if in.BuyerType == "RESIDENT" && !in.Consent {
		return "", 0, userErr(http.StatusUnprocessableEntity, "CONSENT",
			"Talebiniz ve iletişim bilginiz, talebi kabul eden en fazla birkaç tedarikçiyle paylaşılır; göndermek için onay verin")
	}
	ttl, err := s.setting(ctx, "request_ttl_hours")
	if err != nil {
		return "", 0, err
	}
	window, err := s.setting(ctx, "priority_window_minutes")
	if err != nil {
		return "", 0, err
	}
	maxAccepts, err := s.setting(ctx, "max_accepts_per_request")
	if err != nil {
		return "", 0, err
	}
	daily, err := s.setting(ctx, "resident_daily_request_limit")
	if err != nil {
		return "", 0, err
	}

	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return "", 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	if _, err := category(ctx, tx, in.CategoryID, in.BuyerType); err != nil {
		return "", 0, err
	}
	var unitID *string
	if in.BuyerType == "RESIDENT" {
		rows, err := tx.Query(ctx, `SELECT DISTINCT ru.unit_id::text FROM resident_units ru JOIN units u ON u.id = ru.unit_id
			WHERE ru.resident_id = $1 AND u.property_id = $2 AND COALESCE(ru.is_active, true)
			  AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)`, b.UserID, b.PropertyID)
		if err != nil {
			return "", 0, err
		}
		units := []string{}
		for rows.Next() {
			var u string
			if err := rows.Scan(&u); err != nil {
				rows.Close()
				return "", 0, err
			}
			units = append(units, u)
		}
		rows.Close()
		switch {
		case len(units) == 0:
			return "", 0, userErr(http.StatusForbidden, "NOT_RESIDENT", "Bu sitede kayıtlı bir bölümünüz yok; sakin talebi açılamaz")
		case in.UnitID == "" && len(units) == 1:
			unitID = &units[0]
		case in.UnitID == "":
			return "", 0, userErr(http.StatusUnprocessableEntity, "UNIT", "Birden çok bölümünüz var; talebin hangi bölüm için olduğunu seçin")
		default:
			for i := range units {
				if units[i] == in.UnitID {
					unitID = &units[i]
				}
			}
			if unitID == nil {
				return "", 0, userErr(http.StatusForbidden, "UNIT", "Bu bölüm adına talep açamazsınız")
			}
		}
		var today int
		if err := tx.QueryRow(ctx, `SELECT count(*) FROM mp_requests WHERE requester_user_id = $1 AND buyer_type = 'RESIDENT'
			AND created_at >= date_trunc('day', now() AT TIME ZONE 'Europe/Istanbul') AT TIME ZONE 'Europe/Istanbul'`,
			b.UserID).Scan(&today); err != nil {
			return "", 0, err
		}
		if today >= daily {
			return "", 0, userErr(http.StatusTooManyRequests, "DAILY_LIMIT", fmt.Sprintf("Günde en çok %d talep açabilirsiniz; yarın yeniden deneyin", daily))
		}
	}
	matches, si, err := s.match(ctx, tx, b, in.CategoryID, in.BuyerType, in.TargetBusinessID)
	if err != nil {
		return "", 0, err
	}
	if len(matches) == 0 {
		if in.TargetBusinessID != "" {
			return "", 0, userErr(http.StatusUnprocessableEntity, "TARGET", "Bu işletme seçtiğiniz kategoride ya da bölgenizde hizmet vermiyor")
		}
		return "", 0, userErr(http.StatusUnprocessableEntity, "NO_SUPPLIER", "Yakınınızda bu kategoride onaylı işletme yok; talep açılmadı")
	}
	masked, _ := rules.MaskContacts(desc)
	var target *string
	if in.TargetBusinessID != "" {
		target = &in.TargetBusinessID
		maxAccepts = 1
	}
	var id string
	if err := tx.QueryRow(ctx, `INSERT INTO mp_requests (property_id, requester_user_id, buyer_type, unit_id, category_id,
		target_business_id, description, preferred_time, phone_hidden, city, district, latitude, longitude, max_accepts,
		consent_at, expires_at)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14, now(), now() + make_interval(hours => $15)) RETURNING id`,
		b.PropertyID, b.UserID, in.BuyerType, unitID, in.CategoryID, target, masked, pref, in.PhoneHidden,
		si.City, si.District, si.Lat, si.Lng, maxAccepts, ttl).Scan(&id); err != nil {
		return "", 0, err
	}
	if _, err := tx.Exec(ctx, `INSERT INTO mp_request_contacts (request_id, property_id, contact_name, contact_phone, site_name, site_address)
		SELECT $1, $2, trim(u.first_name || ' ' || u.last_name), CASE WHEN $3 THEN NULL ELSE u.phone END, $4, $5
		FROM users u WHERE u.id = $6`, id, b.PropertyID, in.PhoneHidden, si.name, si.address, b.UserID); err != nil {
		return "", 0, err
	}
	for _, m := range matches {
		delay := window
		if m.Priority || target != nil {
			delay = 0
		}
		if _, err := tx.Exec(ctx, `INSERT INTO mp_request_dispatch (request_id, property_id, account_id, business_id, distance_m, visible_at)
			VALUES ($1, $2, $3, $4, $5, now() + make_interval(mins => $6))`,
			id, b.PropertyID, m.AccountID, m.BusinessID, m.DistanceM, delay); err != nil {
			return "", 0, err
		}
	}
	return id, len(matches), tx.Commit(ctx)
}

const buyerRequestSelect = `SELECT r.id, r.buyer_type, r.unit_id, r.category_id, c.name, r.target_business_id, r.description,
	r.preferred_time, r.phone_hidden, jsonb_array_length(r.photo_keys),
	(SELECT COALESCE(jsonb_agg(jsonb_build_object('status', COALESCE(pm.status, 'PENDING'), 'reason', pm.reason) ORDER BY k.ord), '[]')
	   FROM jsonb_array_elements_text(r.photo_keys) WITH ORDINALITY AS k(key, ord) LEFT JOIN photo_moderation pm ON pm.storage_key = k.key),
	r.status, r.accepted_count, r.max_accepts,
	(SELECT count(*) FROM mp_request_dispatch d WHERE d.request_id = r.id), r.expires_at, r.closed_at, r.created_at
	FROM mp_requests r JOIN mp_categories c ON c.id = r.category_id`

func scanBuyerRequest(r pgx.Row) (*BuyerRequest, error) {
	x := &BuyerRequest{}
	err := r.Scan(&x.ID, &x.BuyerType, &x.UnitID, &x.CategoryID, &x.CategoryName, &x.TargetBusinessID, &x.Description,
		&x.PreferredTime, &x.PhoneHidden, &x.PhotoCount, &x.PhotoStatuses, &x.Status, &x.AcceptedCount, &x.MaxAccepts, &x.DispatchCount,
		&x.ExpiresAt, &x.ClosedAt, &x.CreatedAt)
	x.Masked = strings.Contains(x.Description, rules.MaskedNotice)
	return x, err
}

// buyerFilter: sakin yalnız kendi sakin taleplerini; yönetim rolü site adına açılanları görür.
func buyerFilter(b Buyer, management bool) (string, []any) {
	if management {
		return ` WHERE r.buyer_type = 'MANAGEMENT'`, nil
	}
	return ` WHERE r.buyer_type = 'RESIDENT' AND r.requester_user_id = $1`, []any{b.UserID}
}

// BuyerRequests, alıcının taleplerini döner (management=true: site adına açılanlar, yalnız yönetim rolüne).
func (s *Store) BuyerRequests(ctx context.Context, b Buyer, management bool) ([]BuyerRequest, error) {
	if management && !b.Oversight {
		return nil, userErr(http.StatusForbidden, "ROLE", "Site taleplerini yalnız yönetim görür")
	}
	where, args := buyerFilter(b, management)
	rows, err := s.site(b.PropertyID).Query(ctx, buyerRequestSelect+where+` ORDER BY r.created_at DESC LIMIT 200`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []BuyerRequest{}
	for rows.Next() {
		x, err := scanBuyerRequest(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

// BuyerRequestByID, alıcının tek talebidir; başkasının talebi (aynı sitedeki komşu dahil) bulunamaz.
func (s *Store) BuyerRequestByID(ctx context.Context, b Buyer, id string) (*BuyerRequest, error) {
	sc := s.site(b.PropertyID)
	x, err := scanBuyerRequest(sc.QueryRow(ctx, buyerRequestSelect+` WHERE r.id = $1 AND
		((r.buyer_type = 'RESIDENT' AND r.requester_user_id = $2) OR (r.buyer_type = 'MANAGEMENT' AND $3))`, id, b.UserID, b.Oversight))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	rows, err := sc.Query(ctx, `SELECT b.id, b.name, d.accepted_at FROM mp_request_dispatch d JOIN mp_businesses b ON b.id = d.business_id
		WHERE d.request_id = $1 AND d.accepted_at IS NOT NULL ORDER BY d.accepted_at`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	x.Accepted = []Acceptor{}
	for rows.Next() {
		var a Acceptor
		if err := rows.Scan(&a.BusinessID, &a.BusinessName, &a.AcceptedAt); err != nil {
			return nil, err
		}
		x.Accepted = append(x.Accepted, a)
	}
	return x, rows.Err()
}

// AddRequestPhoto, talebe fotoğraf ekler (yalnız talep sahibi, en çok 3, açık ya da dolu talepte).
func (s *Store) AddRequestPhoto(ctx context.Context, b Buyer, id, key, contentType string) error {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	tag, err := tx.Exec(ctx, `UPDATE mp_requests SET photo_keys = photo_keys || to_jsonb($2::text)
		WHERE id = $1 AND requester_user_id = $3 AND status IN ('OPEN', 'FULL') AND jsonb_array_length(photo_keys) < $4`,
		id, key, b.UserID, maxRequestPhotos)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		_ = tx.Rollback(ctx)
		if _, err := s.BuyerRequestByID(ctx, b, id); err != nil {
			return err
		}
		return userErr(http.StatusConflict, "PHOTOS", fmt.Sprintf("Talebe en çok %d fotoğraf eklenebilir (kapanan talebe eklenemez)", maxRequestPhotos))
	}
	// Fotoğraf denetim kuyruğuna girer (M13.4): talep beklemeden tedarikçilere gider, fotoğraf onaylanınca görünür.
	if _, err := tx.Exec(ctx, `INSERT INTO photo_moderation (storage_key, source, request_id, property_id, uploaded_by, content_type)
		VALUES ($1, 'REQUEST_PHOTO', $2, $3, $4, $5)`, key, id, b.PropertyID, b.UserID, contentType); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// RequestPhotoKey, talebin n. fotoğrafının anahtarıdır: alıcı (b) ya da talebi görebilen tedarikçi (accountID).
func (s *Store) RequestPhotoKey(ctx context.Context, b *Buyer, accountID, id string, n int) (string, error) {
	var key *string
	var err error
	if b != nil {
		if _, err := s.BuyerRequestByID(ctx, *b, id); err != nil {
			return "", err
		}
		err = s.site(b.PropertyID).QueryRow(ctx, `SELECT photo_keys ->> $2::int FROM mp_requests WHERE id = $1`, id, n).Scan(&key)
	} else {
		// Tedarikçi yalnız onaylı fotoğrafları görür; n, onaylılar arasındaki sıradır (photo_count da onaylı sayısıdır).
		err = s.supplier(accountID).QueryRow(ctx, `SELECT k.key FROM mp_requests r, jsonb_array_elements_text(r.photo_keys) WITH ORDINALITY AS k(key, ord)
			WHERE r.id = $1 AND photo_approved(k.key) ORDER BY k.ord OFFSET $2 LIMIT 1`, id, n).Scan(&key)
	}
	if errors.Is(err, pgx.ErrNoRows) || (err == nil && key == nil) {
		return "", ErrNotFound
	}
	return derefKey(key), err
}

func derefKey(k *string) string {
	if k == nil {
		return ""
	}
	return *k
}

const supplierRequestSelect = `SELECT r.id, r.buyer_type, c.name, r.city, r.district, d.distance_m, b.id, b.name, r.description,
	r.preferred_time, r.phone_hidden, (SELECT count(*) FROM jsonb_array_elements_text(r.photo_keys) AS k(key) WHERE photo_approved(k.key)),
	r.target_business_id IS NOT NULL, r.status,
	r.accepted_count, r.max_accepts, r.expires_at, d.visible_at, d.accepted_at, d.fee_kurus, d.used_included,
	c.request_fee_kurus, r.created_at,
	(SELECT o.status FROM mp_offers o WHERE o.dispatch_id = d.id ORDER BY o.created_at DESC LIMIT 1),
	(SELECT j.status FROM mp_jobs j WHERE j.request_id = r.id AND j.account_id = d.account_id)
	FROM mp_request_dispatch d
	JOIN mp_requests r ON r.id = d.request_id
	JOIN mp_categories c ON c.id = r.category_id
	JOIN mp_businesses b ON b.id = d.business_id
	WHERE d.account_id = $1`

type walletView struct {
	discount, included int
	balance            int64
}

func (s *Store) supplierWallet(ctx context.Context, q interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}, accountID string) (*walletView, error) {
	w := &walletView{}
	err := q.QueryRow(ctx, `SELECT p.fee_discount_pct, a.period_included_left, a.balance_kurus FROM mp_supplier_accounts a
		JOIN mp_packages p ON p.id = a.package_id WHERE a.id = $1`, accountID).Scan(&w.discount, &w.included, &w.balance)
	return w, err
}

func scanSupplierRequest(r pgx.Row, w *walletView) (*SupplierRequest, error) {
	x := &SupplierRequest{}
	var fee *int64
	var catFee int64
	err := r.Scan(&x.ID, &x.BuyerType, &x.CategoryName, &x.City, &x.District, &x.DistanceM, &x.BusinessID, &x.BusinessName,
		&x.Description, &x.PreferredTime, &x.PhoneHidden, &x.PhotoCount, &x.Direct, &x.Status, &x.AcceptedCount, &x.MaxAccepts,
		&x.ExpiresAt, &x.VisibleAt, &x.AcceptedAt, &fee, &x.UsesIncluded, &catFee, &x.CreatedAt, &x.OfferStatus, &x.JobStatus)
	if err != nil {
		return nil, err
	}
	if x.AcceptedAt != nil {
		if fee != nil {
			x.FeeKurus = *fee
		}
		x.CanAfford = true
		return x, nil
	}
	x.FeeKurus = rules.RequestFee(catFee, w.discount)
	x.UsesIncluded = w.included > 0
	x.CanAfford = x.UsesIncluded || w.balance >= x.FeeKurus
	return x, nil
}

// SupplierRequests, tedarikçiye gönderilmiş ve görünür olmuş talepler (öncelik penceresindekiler RLS'le gizli).
func (s *Store) SupplierRequests(ctx context.Context, accountID string) ([]SupplierRequest, error) {
	sc := s.supplier(accountID)
	w, err := s.supplierWallet(ctx, sc, accountID)
	if err != nil {
		return nil, err
	}
	rows, err := sc.Query(ctx, supplierRequestSelect+` ORDER BY d.visible_at DESC LIMIT 200`, accountID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []SupplierRequest{}
	for rows.Next() {
		x, err := scanSupplierRequest(rows, w)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

// SupplierRequestByID, tek talep; iletişim bilgisi yalnız kabul ettiyse (RLS de yalnız o zaman açar).
func (s *Store) SupplierRequestByID(ctx context.Context, accountID, id string) (*SupplierRequest, error) {
	sc := s.supplier(accountID)
	w, err := s.supplierWallet(ctx, sc, accountID)
	if err != nil {
		return nil, err
	}
	x, err := scanSupplierRequest(sc.QueryRow(ctx, supplierRequestSelect+` AND d.request_id = $2`, accountID, id), w)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil || x.AcceptedAt == nil {
		return x, err
	}
	ct := &RequestContact{}
	err = sc.QueryRow(ctx, `SELECT COALESCE(contact_name, ''), contact_phone, COALESCE(site_name, ''), COALESCE(site_address, '')
		FROM mp_request_contacts WHERE request_id = $1`, id).Scan(&ct.Name, &ct.Phone, &ct.SiteName, &ct.SiteAddress)
	if err == nil {
		x.Contact = ct
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, err
	}
	return x, nil
}

// Accept, talebi kabul eder (K9/K10): tek işlemde dahil talep hakkı ya da bakiye düşer, kabul sayısı artar (sınır satır
// kilidiyle korunur), iletişim açılır. Bir hesap bir talebi bir kez kabul eder.
func (s *Store) Accept(ctx context.Context, accountID, userID, requestID string) (*SupplierRequest, error) {
	tx, err := s.supplier(accountID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	var accStatus string
	var discount, included int
	var balance int64
	if err := tx.QueryRow(ctx, `SELECT a.status, p.fee_discount_pct, a.period_included_left, a.balance_kurus
		FROM mp_supplier_accounts a JOIN mp_packages p ON p.id = a.package_id WHERE a.id = $1 FOR UPDATE OF a`, accountID).
		Scan(&accStatus, &discount, &included, &balance); err != nil {
		return nil, err
	}
	if accStatus != "APPROVED" {
		return nil, userErr(http.StatusConflict, "ACCOUNT_STATE", "Hesabınız onaylı değil; talep kabul edilemez")
	}
	var dispatchID string
	var acceptedAt *time.Time
	err = tx.QueryRow(ctx, `SELECT id, accepted_at FROM mp_request_dispatch WHERE request_id = $1 AND account_id = $2 FOR UPDATE`,
		requestID, accountID).Scan(&dispatchID, &acceptedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	if acceptedAt != nil {
		return nil, userErr(http.StatusConflict, "ALREADY_ACCEPTED", "Bu talebi zaten kabul ettiniz")
	}
	var status, catName string
	var count, maxAccepts int
	var expires time.Time
	var catFee int64
	if err := tx.QueryRow(ctx, `SELECT r.status, r.accepted_count, r.max_accepts, r.expires_at, c.request_fee_kurus, c.name
		FROM mp_requests r JOIN mp_categories c ON c.id = r.category_id WHERE r.id = $1 FOR UPDATE OF r`, requestID).
		Scan(&status, &count, &maxAccepts, &expires, &catFee, &catName); err != nil {
		return nil, err
	}
	if status == "FULL" || (status == "OPEN" && count >= maxAccepts) {
		return nil, userErr(http.StatusConflict, "FULL", fmt.Sprintf("Talep doldu: en çok %d tedarikçi kabul edebilir", maxAccepts))
	}
	if status != "OPEN" || !expires.After(s.now()) {
		return nil, userErr(http.StatusConflict, "CLOSED", "Talep kapandı; artık kabul edilemez")
	}
	fee := rules.RequestFee(catFee, discount)
	var ledgerID *string
	usedIncluded := false
	switch {
	case included > 0:
		if _, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET period_included_left = period_included_left - 1, updated_at = now()
			WHERE id = $1`, accountID); err != nil {
			return nil, err
		}
		_, id, err := post(ctx, tx, accountID, "INCLUDED_REQUEST", 0, ledgerRef{dispatch: &dispatchID, by: strp(userID),
			note: "Paketten talep hakkı — " + catName})
		if err != nil {
			return nil, err
		}
		ledgerID, usedIncluded, fee = &id, true, 0
	case fee > 0:
		_, id, err := post(ctx, tx, accountID, "REQUEST_FEE", -fee, ledgerRef{dispatch: &dispatchID, by: strp(userID),
			note: "Talep kabul ücreti — " + catName})
		if errors.Is(err, ErrInsufficient) {
			return nil, &UserError{Status: http.StatusConflict, Code: "INSUFFICIENT_BALANCE",
				Message: fmt.Sprintf("Bakiyeniz yetersiz: kabul ücreti %s, bakiyeniz %s. Bakiye yükleyip yeniden deneyin.", TL(fee), TL(balance))}
		}
		if err != nil {
			return nil, err
		}
		ledgerID = &id
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_request_dispatch SET accepted_at = now(), fee_kurus = $2, used_included = $3, fee_ledger_id = $4
		WHERE id = $1`, dispatchID, fee, usedIncluded, ledgerID); err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `UPDATE mp_requests SET accepted_count = accepted_count + 1,
		status = CASE WHEN accepted_count + 1 >= max_accepts THEN 'FULL' ELSE status END WHERE id = $1`, requestID); err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.SupplierRequestByID(ctx, accountID, requestID)
}

// TL, kuruşu "1.234,50 TL" biçiminde yazar (mesajlar için).
func TL(k int64) string {
	sign := ""
	if k < 0 {
		sign, k = "-", -k
	}
	lira := fmt.Sprintf("%d", k/100)
	for i := len(lira) - 3; i > 0; i -= 3 {
		lira = lira[:i] + "." + lira[i:]
	}
	return fmt.Sprintf("%s%s,%02d TL", sign, lira, k%100)
}

// DueDispatch, bildirimi zamanı gelmiş gönderimdir (zamanlayıcı ya da talep açılışı).
type DueDispatch struct {
	DispatchID, AccountID, RequestID string
	Category, City, District         string
	FeeKurus                         int64
	Included                         bool
	SMS                              bool
}

// ClaimDueDispatches, görünür olmuş ama bildirilmemiş gönderimleri alır ve bildirildi işaretler (eşzamanlı turlar aynı
// satırı iki kez almaz). requestID verilirse yalnız o talebinkiler. Talep artık açık değilse bildirim gitmez.
// SMS, hesabın dönemlik SMS hakkı varsa ve düşülebiliyorsa verilir (ücretli paket).
func (s *Store) ClaimDueDispatches(ctx context.Context, requestID string) ([]DueDispatch, error) {
	tx, err := s.platform("jobs").Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	rows, err := tx.Query(ctx, `UPDATE mp_request_dispatch d SET notified_at = now()
		FROM mp_requests r, mp_categories c, mp_supplier_accounts a, mp_packages p
		WHERE d.id IN (SELECT id FROM mp_request_dispatch WHERE notified_at IS NULL AND visible_at <= now()
		                 AND ($1 = '' OR request_id::text = $1) ORDER BY visible_at LIMIT 500 FOR UPDATE SKIP LOCKED)
		  AND r.id = d.request_id AND c.id = r.category_id AND a.id = d.account_id AND p.id = a.package_id
		RETURNING d.id, d.account_id, d.request_id, c.name, r.city, r.district, c.request_fee_kurus, p.fee_discount_pct,
		          a.period_included_left > 0, r.status = 'OPEN' AND a.status = 'APPROVED'`, requestID)
	if err != nil {
		return nil, err
	}
	out := []DueDispatch{}
	for rows.Next() {
		var d DueDispatch
		var catFee int64
		var discount int
		var live bool
		if err := rows.Scan(&d.DispatchID, &d.AccountID, &d.RequestID, &d.Category, &d.City, &d.District, &catFee, &discount, &d.Included, &live); err != nil {
			rows.Close()
			return nil, err
		}
		if live {
			d.FeeKurus = rules.RequestFee(catFee, discount)
			out = append(out, d)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	for i := range out {
		tag, err := tx.Exec(ctx, `UPDATE mp_supplier_accounts SET period_sms_left = period_sms_left - 1 WHERE id = $1 AND period_sms_left > 0`,
			out[i].AccountID)
		if err != nil {
			return nil, err
		}
		out[i].SMS = tag.RowsAffected() == 1
	}
	return out, tx.Commit(ctx)
}

// ExpiredRequest, süresi dolup kapanan taleptir (alıcıya bildirilir).
type ExpiredRequest struct {
	ID, PropertyID, RequesterUserID, Category string
	AcceptedCount                             int
}

// ExpireRequests, süresi dolan açık talepleri kapatır (K9): artık kabul edilemez; kabul etmiş olanlarla süreç sürer.
func (s *Store) ExpireRequests(ctx context.Context) ([]ExpiredRequest, error) {
	tx, err := s.platform("jobs").Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	rows, err := tx.Query(ctx, `UPDATE mp_requests r SET status = 'EXPIRED', closed_at = now()
		FROM mp_categories c WHERE c.id = r.category_id AND r.status = 'OPEN' AND r.expires_at <= now()
		RETURNING r.id, r.property_id, r.requester_user_id, c.name, r.accepted_count`)
	if err != nil {
		return nil, err
	}
	out := []ExpiredRequest{}
	for rows.Next() {
		var e ExpiredRequest
		if err := rows.Scan(&e.ID, &e.PropertyID, &e.RequesterUserID, &e.Category, &e.AcceptedCount); err != nil {
			rows.Close()
			return nil, err
		}
		out = append(out, e)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return out, tx.Commit(ctx)
}
