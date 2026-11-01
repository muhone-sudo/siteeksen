package main

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/pii"
)

// Item, denetim kuyruğundaki fotoğraftır.
type Item struct {
	ID             string     `json:"id"`
	StorageKey     string     `json:"-"`
	Source         string     `json:"source"`
	ServiceID      *string    `json:"service_id"`
	RequestID      *string    `json:"request_id"`
	AccountID      *string    `json:"account_id"`
	PropertyID     *string    `json:"property_id"`
	UploadedBy     *string    `json:"uploaded_by"`
	ContentType    string     `json:"content_type"`
	Status         string     `json:"status"`
	OCRText        *string    `json:"ocr_text"`
	OCRFindings    []string   `json:"ocr_findings"`
	AIProvider     *string    `json:"ai_provider"`
	AIVerdict      *string    `json:"ai_verdict"`
	AICategories   []string   `json:"ai_categories"`
	AIReason       *string    `json:"ai_reason"`
	DecisionSource *string    `json:"decision_source"`
	DecidedAt      *time.Time `json:"decided_at"`
	Reason         *string    `json:"reason"`
	Attempts       int        `json:"attempts"`
	LastError      *string    `json:"last_error"`
	CreatedAt      time.Time  `json:"created_at"`
	// Bağlam (platform ekranı için): hangi işletmenin hangi kalemi ya da hangi talep.
	Context string `json:"context"`
	Owner   string `json:"owner"`
}

const itemSelect = `SELECT m.id, m.storage_key, m.source, m.service_id, m.request_id, m.account_id, m.property_id, m.uploaded_by,
	m.content_type, m.status, m.ocr_text, m.ocr_findings, m.ai_provider, m.ai_verdict, m.ai_categories, m.ai_reason, m.decision_source,
	m.decided_at, m.reason, m.attempts, m.last_error, m.created_at,
	COALESCE(b.name || ' — ' || s.name, c.name || ' talebi (' || r.district || ' / ' || r.city || ')', ''),
	COALESCE(a.trade_name, p.name, '')
	FROM photo_moderation m
	LEFT JOIN mp_business_services s ON s.id = m.service_id
	LEFT JOIN mp_businesses b ON b.id = s.business_id
	LEFT JOIN mp_supplier_accounts a ON a.id = m.account_id
	LEFT JOIN mp_requests r ON r.id = m.request_id
	LEFT JOIN mp_categories c ON c.id = r.category_id
	LEFT JOIN properties p ON p.id = m.property_id`

func scanItem(r pgx.Row) (*Item, error) {
	x := &Item{}
	err := r.Scan(&x.ID, &x.StorageKey, &x.Source, &x.ServiceID, &x.RequestID, &x.AccountID, &x.PropertyID, &x.UploadedBy,
		&x.ContentType, &x.Status, &x.OCRText, &x.OCRFindings, &x.AIProvider, &x.AIVerdict, &x.AICategories, &x.AIReason,
		&x.DecisionSource, &x.DecidedAt, &x.Reason, &x.Attempts, &x.LastError, &x.CreatedAt, &x.Context, &x.Owner)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, errNotFound
	}
	return x, err
}

var errNotFound = errors.New("kayıt bulunamadı")

// userError, istemciye olduğu gibi gösterilen hatadır.
type userError struct {
	status int
	msg    string
}

func (e *userError) Error() string { return e.msg }

// Store, kuyruk ve ayar tablolarıdır. Bütün okuma/yazmalar platform kapsamındadır (082 politikaları).
type Store struct {
	pool  *pgxpool.Pool
	vault *pii.Vault
}

func (s *Store) platform(userID string) *dbscope.Scoped { return dbscope.ForPlatform(s.pool, userID) }

const workerScope = "moderation-worker"

// Claim, sırası gelen fotoğrafları işleyiciye ayırır (aynı satırı iki işleyici almaz; çökerse 5 dk sonra yeniden alınır).
func (s *Store) Claim(ctx context.Context, limit int) ([]Item, error) {
	tx, err := s.platform(workerScope).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	rows, err := tx.Query(ctx, `SELECT id FROM photo_moderation WHERE status = 'PENDING' AND next_attempt_at <= now()
		ORDER BY next_attempt_at LIMIT $1 FOR UPDATE SKIP LOCKED`, limit)
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
	if _, err := tx.Exec(ctx, `UPDATE photo_moderation SET attempts = attempts + 1, next_attempt_at = now() + interval '5 minutes'
		WHERE id = ANY($1::uuid[])`, ids); err != nil {
		return nil, err
	}
	out := []Item{}
	rs, err := tx.Query(ctx, itemSelect+` WHERE m.id = ANY($1::uuid[]) ORDER BY m.created_at`, ids)
	if err != nil {
		return nil, err
	}
	for rs.Next() {
		x, err := scanItem(rs)
		if err != nil {
			rs.Close()
			return nil, err
		}
		out = append(out, *x)
	}
	rs.Close()
	return out, tx.Commit(ctx)
}

// Outcome, işleyicinin bir fotoğraf için vardığı sonuçtur.
type Outcome struct {
	Status         string // PENDING (yeniden dene) | REVIEW | APPROVED | REJECTED | REPLACED
	OCRText        *string
	OCRFindings    []string
	AIProvider     *string
	AIVerdict      *string
	AICategories   []string
	AIReason       *string
	DecisionSource *string
	Reason         *string
	LastError      *string
}

// Finish, işleyicinin sonucunu yazar (yalnız hâlâ PENDING ise; bu arada platform karar verdiyse dokunulmaz).
func (s *Store) Finish(ctx context.Context, id string, o Outcome) (*Item, error) {
	if o.OCRFindings == nil {
		o.OCRFindings = []string{}
	}
	if o.AICategories == nil {
		o.AICategories = []string{}
	}
	sc := s.platform(workerScope)
	decided := o.Status == "APPROVED" || o.Status == "REJECTED"
	tag, err := sc.Exec(ctx, `UPDATE photo_moderation SET status = $2, ocr_text = COALESCE($3, ocr_text), ocr_findings = $4,
		ai_provider = $5, ai_verdict = $6, ai_categories = $7, ai_reason = $8, decision_source = $9, reason = $10, last_error = $11,
		decided_at = CASE WHEN $12 THEN now() ELSE decided_at END
		WHERE id = $1 AND status = 'PENDING'`, id, o.Status, o.OCRText, o.OCRFindings, o.AIProvider, o.AIVerdict, o.AICategories,
		o.AIReason, o.DecisionSource, o.Reason, o.LastError, decided)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, nil
	}
	return scanItem(sc.QueryRow(ctx, itemSelect+` WHERE m.id = $1`, id))
}

// List, platformun denetim listesi (durum boşsa hepsi; elle onay bekleyenler önce).
func (s *Store) List(ctx context.Context, adminID, status string) ([]Item, error) {
	rows, err := s.platform(adminID).Query(ctx, itemSelect+` WHERE m.status <> 'REPLACED' AND ($1 = '' OR m.status = $1)
		ORDER BY (m.status = 'REVIEW') DESC, m.created_at DESC LIMIT 300`, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []Item{}
	for rows.Next() {
		x, err := scanItem(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *x)
	}
	return out, rows.Err()
}

func (s *Store) Get(ctx context.Context, adminID, id string) (*Item, error) {
	return scanItem(s.platform(adminID).QueryRow(ctx, itemSelect+` WHERE m.id = $1`, id))
}

// Decide, platformun elle kararıdır: onay (bekleyen, incelemedeki ya da reddedilmiş fotoğraf) ya da gerekçeli ret
// (otomatik onaylanmış fotoğraf da kaldırılabilir).
func (s *Store) Decide(ctx context.Context, adminID, id string, approve bool, reason string) (*Item, error) {
	sc := s.platform(adminID)
	var tagRows int64
	if approve {
		tag, err := sc.Exec(ctx, `UPDATE photo_moderation SET status = 'APPROVED', decision_source = 'PLATFORM', decided_by = $2,
			decided_at = now(), reason = NULLIF($3, '') WHERE id = $1 AND status IN ('PENDING', 'REVIEW', 'REJECTED')`, id, adminID, reason)
		if err != nil {
			return nil, err
		}
		tagRows = tag.RowsAffected()
	} else {
		if len([]rune(reason)) < 5 {
			return nil, &userError{http.StatusUnprocessableEntity, "Ret gerekçesi zorunludur (en az 5 karakter); yükleyene gösterilir"}
		}
		tag, err := sc.Exec(ctx, `UPDATE photo_moderation SET status = 'REJECTED', decision_source = 'PLATFORM', decided_by = $2,
			decided_at = now(), reason = $3 WHERE id = $1 AND status IN ('PENDING', 'REVIEW', 'APPROVED')`, id, adminID, reason)
		if err != nil {
			return nil, err
		}
		tagRows = tag.RowsAffected()
	}
	if tagRows == 0 {
		if _, err := s.Get(ctx, adminID, id); err != nil {
			return nil, err
		}
		return nil, &userError{http.StatusConflict, "Fotoğraf bu karara uygun durumda değil"}
	}
	return s.Get(ctx, adminID, id)
}

// Recheck, fotoğrafı yeniden denetime alır (ör. yapay zekâ açıldıktan sonra incelemedekiler için).
func (s *Store) Recheck(ctx context.Context, adminID, id string) (*Item, error) {
	tag, err := s.platform(adminID).Exec(ctx, `UPDATE photo_moderation SET status = 'PENDING', attempts = 0, next_attempt_at = now(),
		last_error = NULL WHERE id = $1 AND status IN ('REVIEW', 'REJECTED')`, id)
	if err != nil {
		return nil, err
	}
	if tag.RowsAffected() == 0 {
		return nil, &userError{http.StatusConflict, "Yalnız incelemedeki ya da reddedilmiş fotoğraf yeniden denetlenebilir"}
	}
	return s.Get(ctx, adminID, id)
}

// AccountOwner, tedarikçi hesabının sahibidir (bildirim alıcısı; eski kayıtlarda yükleyen boş olabilir).
func (s *Store) AccountOwner(ctx context.Context, accountID string) (string, error) {
	var uid string
	err := s.platform(workerScope).QueryRow(ctx, `SELECT user_id::text FROM mp_supplier_accounts WHERE id = $1`, accountID).Scan(&uid)
	return uid, err
}

// --- Yapay zekâ ayarı ---

// AIView, ayarın istemciye dönen hâlidir: gizli değerler dönmez, yalnız tanımlı olup olmadıkları.
type AIView struct {
	Enabled     bool       `json:"enabled"`
	Provider    string     `json:"provider"`
	BaseURL     string     `json:"base_url"`
	Model       string     `json:"model"`
	AuthType    string     `json:"auth_type"`
	APIKeySet   bool       `json:"api_key_set"`
	Username    string     `json:"username"`
	PasswordSet bool       `json:"password_set"`
	UpdatedAt   *time.Time `json:"updated_at"`
	Encryption  bool       `json:"encryption_ready"`
}

func (s *Store) loadRaw(ctx context.Context, scope string) (*AIView, *string, *string, error) {
	v := &AIView{Encryption: s.vault != nil}
	var key, pw *string
	err := s.platform(scope).QueryRow(ctx, `SELECT enabled, provider, base_url, model, auth_type, api_key_enc, username, password_enc, updated_at
		FROM moderation_ai_settings WHERE id = 1`).Scan(&v.Enabled, &v.Provider, &v.BaseURL, &v.Model, &v.AuthType, &key, &v.Username, &pw, &v.UpdatedAt)
	if err != nil {
		return nil, nil, nil, err
	}
	v.APIKeySet, v.PasswordSet = key != nil && *key != "", pw != nil && *pw != ""
	return v, key, pw, nil
}

// AIView, platform ekranı için ayardır.
func (s *Store) AIView(ctx context.Context, adminID string) (*AIView, error) {
	v, _, _, err := s.loadRaw(ctx, adminID)
	return v, err
}

// AISettings, işleyicinin kullandığı çözülmüş ayardır.
func (s *Store) AISettings(ctx context.Context) (*AISettings, error) {
	v, key, pw, err := s.loadRaw(ctx, workerScope)
	if err != nil {
		return nil, err
	}
	out := &AISettings{Enabled: v.Enabled, Provider: v.Provider, BaseURL: v.BaseURL, Model: v.Model, AuthType: v.AuthType, Username: v.Username}
	if s.vault != nil {
		if key != nil && *key != "" {
			if out.APIKey, err = s.vault.Decrypt(*key); err != nil {
				return nil, errors.New("API anahtarı çözülemedi (şifreleme anahtarı değişmiş olabilir); ayardan yeniden girin")
			}
		}
		if pw != nil && *pw != "" {
			if out.Password, err = s.vault.Decrypt(*pw); err != nil {
				return nil, errors.New("parola çözülemedi (şifreleme anahtarı değişmiş olabilir); ayardan yeniden girin")
			}
		}
	}
	return out, nil
}

// AIInput, ayar formudur. APIKey/Password boş bırakılırsa mevcut değer korunur; Clear* ile silinir.
type AIInput struct {
	Enabled       bool   `json:"enabled"`
	Provider      string `json:"provider"`
	BaseURL       string `json:"base_url"`
	Model         string `json:"model"`
	AuthType      string `json:"auth_type"`
	APIKey        string `json:"api_key"`
	ClearAPIKey   bool   `json:"clear_api_key"`
	Username      string `json:"username"`
	Password      string `json:"password"`
	ClearPassword bool   `json:"clear_password"`
}

// SaveAI, ayarı kaydeder; gizli değerler şifreli yazılır.
func (s *Store) SaveAI(ctx context.Context, adminID string, in AIInput) (*AIView, error) {
	if in.Provider != "ANTHROPIC" && in.Provider != "OPENAI" {
		return nil, &userError{http.StatusUnprocessableEntity, "Sağlayıcı türü ANTHROPIC ya da OPENAI (OpenAI uyumlu) olmalı"}
	}
	if in.AuthType != "API_KEY" && in.AuthType != "BASIC" && in.AuthType != "NONE" {
		return nil, &userError{http.StatusUnprocessableEntity, "Kimlik türü API_KEY, BASIC ya da NONE olmalı"}
	}
	if !validURL(in.BaseURL) {
		return nil, &userError{http.StatusUnprocessableEntity, "Sağlayıcı adresi http:// ya da https:// ile başlamalı"}
	}
	if (in.APIKey != "" || in.Password != "") && s.vault == nil {
		return nil, &userError{http.StatusServiceUnavailable, "Gizli değer saklamak için şifreleme anahtarı (PII_ENCRYPTION_KEY) yapılandırılmamış"}
	}
	enc := func(v string) (*string, error) {
		if v == "" {
			return nil, nil
		}
		c, err := s.vault.Encrypt(v)
		return &c, err
	}
	key, err := enc(in.APIKey)
	if err != nil {
		return nil, err
	}
	pw, err := enc(in.Password)
	if err != nil {
		return nil, err
	}
	cur, _, _, err := s.loadRaw(ctx, adminID)
	if err != nil {
		return nil, err
	}
	keySet := (cur.APIKeySet && !in.ClearAPIKey) || key != nil
	pwSet := (cur.PasswordSet && !in.ClearPassword) || pw != nil
	if in.Enabled && in.Model == "" {
		return nil, &userError{http.StatusUnprocessableEntity, "Yapay zekâ açıkken model adı zorunludur"}
	}
	if in.Enabled && in.AuthType == "API_KEY" && !keySet {
		return nil, &userError{http.StatusUnprocessableEntity, "API anahtarı girilmeden yapay zekâ açılamaz"}
	}
	if in.Enabled && in.AuthType == "BASIC" && (in.Username == "" || !pwSet) {
		return nil, &userError{http.StatusUnprocessableEntity, "Kullanıcı adı ve parola girilmeden yapay zekâ açılamaz"}
	}
	if _, err := s.platform(adminID).Exec(ctx, `UPDATE moderation_ai_settings SET enabled = $1, provider = $2, base_url = $3, model = $4,
		auth_type = $5, username = $6,
		api_key_enc = CASE WHEN $7::text IS NOT NULL THEN $7 WHEN $8 THEN NULL ELSE api_key_enc END,
		password_enc = CASE WHEN $9::text IS NOT NULL THEN $9 WHEN $10 THEN NULL ELSE password_enc END,
		updated_by = $11, updated_at = now() WHERE id = 1`,
		in.Enabled, in.Provider, in.BaseURL, in.Model, in.AuthType, in.Username, key, in.ClearAPIKey, pw, in.ClearPassword, adminID); err != nil {
		return nil, err
	}
	return s.AIView(ctx, adminID)
}
