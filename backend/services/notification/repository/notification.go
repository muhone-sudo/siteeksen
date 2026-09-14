// Package repository, bildirim modülünün veritabanı işlemlerini içerir.
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
	ErrInvalidValue = errors.New("geçersiz kanal ya da kategori")
	ErrNoAddress    = errors.New("alıcının bu kanal için adresi yok")
)

// Channels ve Categories, migration 016'daki CHECK kısıtlarıyla birebir aynıdır.
var (
	Channels   = []string{"IN_APP", "PUSH", "SMS", "EMAIL"}
	Categories = []string{"TRANSACTIONAL", "COMMERCIAL"}
)

// Notification, giden kutusundaki bir kayıttır.
//
// `recipient_address` istemciye MASKELENEREK verilir: bildirim listesini okuyan
// yönetici, komşunun telefon numarasının tamamını görmek zorunda değildir
// (KVKK m.4 veri minimizasyonu).
type Notification struct {
	ID             string     `json:"id"`
	RecipientName  string     `json:"recipient_name,omitempty"`
	Recipient      string     `json:"recipient_masked"`
	Channel        string     `json:"channel"`
	Category       string     `json:"category"`
	Topic          string     `json:"topic"`
	Subject        string     `json:"subject,omitempty"`
	Body           string     `json:"body"`
	Status         string     `json:"status"`
	SuppressReason string     `json:"suppress_reason,omitempty"`
	Provider       string     `json:"provider,omitempty"`
	Attempts       int        `json:"attempts"`
	LastError      string     `json:"last_error,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	SentAt         *time.Time `json:"sent_at,omitempty"`
}

// Preference, bir alıcı tercihidir.
type Preference struct {
	Channel       string     `json:"channel"`
	Category      string     `json:"category"`
	Enabled       bool       `json:"enabled"`
	ConsentAt     *time.Time `json:"consent_at,omitempty"`
	ConsentSource string     `json:"consent_source,omitempty"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const notificationSelect = `
SELECT n.id, COALESCE(u.first_name || ' ' || u.last_name, ''),
       n.recipient_address, n.channel, n.category, n.topic,
       COALESCE(n.subject,''), n.body, n.status, COALESCE(n.suppress_reason,''),
       COALESCE(n.provider,''), n.attempts, COALESCE(n.last_error,''),
       n.created_at, n.sent_at
FROM notifications n
LEFT JOIN users u ON u.id = n.recipient_user_id`

func scanNotification(row pgx.Row) (*Notification, error) {
	var n Notification
	err := row.Scan(&n.ID, &n.RecipientName, &n.Recipient, &n.Channel, &n.Category,
		&n.Topic, &n.Subject, &n.Body, &n.Status, &n.SuppressReason,
		&n.Provider, &n.Attempts, &n.LastError, &n.CreatedAt, &n.SentAt)
	if err != nil {
		return nil, err
	}
	n.Recipient = MaskAddress(n.Recipient)
	return &n, nil
}

// MaskAddress, telefon/e-posta adresini maskeler.
func MaskAddress(s string) string {
	if i := strings.Index(s, "@"); i > 1 {
		return s[:1] + "***" + s[i:]
	}
	if len(s) > 6 {
		return s[:3] + "****" + s[len(s)-2:]
	}
	if s == "" {
		return ""
	}
	return "***"
}

func clampLimit(limit int) int {
	if limit <= 0 || limit > 500 {
		return 100
	}
	return limit
}

// ListForUser, kullanıcının kendi bildirimlerini döner.
func (r *Repository) ListForUser(ctx context.Context, propertyID, userID, status string, limit int) ([]Notification, error) {
	rows, err := r.scope(propertyID).Query(ctx, notificationSelect+`
		WHERE n.property_id = $1 AND n.recipient_user_id = $2
		  AND ($3 = '' OR n.status = $3)
		ORDER BY n.created_at DESC
		LIMIT $4`, propertyID, userID, strings.ToUpper(status), clampLimit(limit))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collect(rows)
}

// ListAll, site genelindeki giden kutusunu döner (yalnızca yönetim).
func (r *Repository) ListAll(ctx context.Context, propertyID, status, channel string, limit int) ([]Notification, error) {
	rows, err := r.scope(propertyID).Query(ctx, notificationSelect+`
		WHERE n.property_id = $1
		  AND ($2 = '' OR n.status = $2)
		  AND ($3 = '' OR n.channel = $3)
		ORDER BY n.created_at DESC
		LIMIT $4`, propertyID, strings.ToUpper(status), strings.ToUpper(channel), clampLimit(limit))
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return collect(rows)
}

func collect(rows pgx.Rows) ([]Notification, error) {
	out := []Notification{}
	for rows.Next() {
		n, err := scanNotification(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *n)
	}
	return out, rows.Err()
}

// RecipientAddress, kullanıcının ilgili kanal için adresini çözer.
//
// Adres bulunamazsa ErrNoAddress döner ve bildirim OLUŞTURULMAZ. Boş adrese
// bildirim kaydı açmak, sonradan "gönderildi" görünen bir kayıt bırakırdı.
func (r *Repository) RecipientAddress(ctx context.Context, propertyID, userID, channel string) (string, error) {
	ch := strings.ToUpper(strings.TrimSpace(channel))
	if !contains(Channels, ch) {
		return "", ErrInvalidValue
	}

	var phone, email *string
	err := r.scope(propertyID).QueryRow(ctx, `
		SELECT u.phone, u.email
		FROM users u
		WHERE u.id = $1
		  AND EXISTS (
		    SELECT 1 FROM resident_units ru
		    JOIN units un ON un.id = ru.unit_id
		    WHERE ru.resident_id = u.id AND un.property_id = $2
		  )`, userID, propertyID).Scan(&phone, &email)
	if err == pgx.ErrNoRows {
		// Kullanıcı bu sitede kayıtlı değil: başka sitenin sakinine bildirim
		// gönderilmesini engeller.
		return "", ErrNotFound
	}
	if err != nil {
		return "", err
	}

	switch ch {
	case "EMAIL":
		if email == nil || strings.TrimSpace(*email) == "" {
			return "", ErrNoAddress
		}
		return *email, nil
	case "SMS", "PUSH":
		// PUSH için doğru adres cihaz jetonudur; cihaz kaydı altyapısı YOKTUR.
		// Telefonu cihaz jetonu gibi kullanmak sahte bir adres üretmek olurdu.
		if ch == "PUSH" {
			return "", ErrNoAddress
		}
		if phone == nil || strings.TrimSpace(*phone) == "" {
			return "", ErrNoAddress
		}
		return *phone, nil
	default: // IN_APP
		return userID, nil
	}
}

// Preferences, kullanıcının kayıtlı tercihlerini döner.
func (r *Repository) Preferences(ctx context.Context, propertyID, userID string) ([]Preference, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT channel, category, enabled, consent_at, COALESCE(consent_source,'')
		FROM notification_preferences
		WHERE user_id = $1 AND (property_id = $2 OR property_id IS NULL)
		ORDER BY channel, category`, userID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Preference{}
	for rows.Next() {
		var p Preference
		if err := rows.Scan(&p.Channel, &p.Category, &p.Enabled,
			&p.ConsentAt, &p.ConsentSource); err != nil {
			return nil, err
		}
		out = append(out, p)
	}
	return out, rows.Err()
}

// SetPreference, tercihi kaydeder.
//
// Ticari ileti AÇILIRKEN onay zamanı ve kaynağı da yazılır: 6563 s. Kanun m.6
// onayın ispatını gönderene yükler. Kapatmada onay bilgisi silinmez — ret
// hakkının kullanıldığı tarih, onayın hiç alınmadığı anlamına gelmez.
func (r *Repository) SetPreference(ctx context.Context, propertyID, userID, channel, category string, enabled bool, consentSource string) error {
	ch := strings.ToUpper(strings.TrimSpace(channel))
	cat := strings.ToUpper(strings.TrimSpace(category))
	if !contains(Channels, ch) || !contains(Categories, cat) {
		return ErrInvalidValue
	}
	if cat == "COMMERCIAL" && enabled && strings.TrimSpace(consentSource) == "" {
		consentSource = "kullanici-tercih-ekrani"
	}

	_, err := r.scope(propertyID).Exec(ctx, `
		INSERT INTO notification_preferences
			(user_id, property_id, channel, category, enabled, consent_at, consent_source)
		VALUES ($1::uuid,$2::uuid,$3::varchar,$4::varchar,$5::boolean,
		        CASE WHEN $4::varchar = 'COMMERCIAL' AND $5::boolean THEN now() ELSE NULL END,
		        NULLIF($6,''))
		ON CONFLICT (user_id, property_id, channel, category) DO UPDATE
		SET enabled = EXCLUDED.enabled,
		    consent_at = CASE
		        WHEN EXCLUDED.category = 'COMMERCIAL' AND EXCLUDED.enabled
		            THEN COALESCE(notification_preferences.consent_at, now())
		        ELSE notification_preferences.consent_at END,
		    consent_source = COALESCE(EXCLUDED.consent_source, notification_preferences.consent_source),
		    updated_at = now()`,
		userID, propertyID, ch, cat, enabled, consentSource)
	return err
}

// Summary, giden kutusunun özetidir.
type Summary struct {
	Total       int            `json:"total"`
	Pending     int            `json:"pending"`
	Sent        int            `json:"sent"`
	Failed      int            `json:"failed"`
	Suppressed  int            `json:"suppressed"`
	ByChannel   map[string]int `json:"by_channel"`
	PendingNote string         `json:"pending_note,omitempty"`
}

// Summary, durum ve kanal dağılımını verir.
func (r *Repository) Summary(ctx context.Context, propertyID string) (*Summary, error) {
	s := &Summary{ByChannel: map[string]int{}}
	if err := r.scope(propertyID).QueryRow(ctx, `
		SELECT count(*),
		       count(*) FILTER (WHERE status = 'PENDING'),
		       count(*) FILTER (WHERE status = 'SENT'),
		       count(*) FILTER (WHERE status = 'FAILED'),
		       count(*) FILTER (WHERE status = 'SUPPRESSED')
		FROM notifications WHERE property_id = $1`, propertyID).
		Scan(&s.Total, &s.Pending, &s.Sent, &s.Failed, &s.Suppressed); err != nil {
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT channel, count(*) FROM notifications
		WHERE property_id = $1 GROUP BY channel`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var ch string
		var n int
		if err := rows.Scan(&ch, &n); err != nil {
			return nil, err
		}
		s.ByChannel[ch] = n
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	if s.Pending > 0 {
		s.PendingNote = "Bekleyen bildirimler GÖNDERİLMEMİŞTİR. Çoğunlukla nedeni " +
			"o kanal için yapılandırılmış bir sağlayıcının bulunmamasıdır."
	}
	return s, nil
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// notifications / notification_preferences tablolarında RLS açıktır (migration 020).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
