// Package notify, sağlayıcıdan bağımsız bildirim gönderimi sağlar (S-10).
//
// Neden var: projede bildirim gönderimi HİÇ YOKTU. `pkg/notification` (Firebase)
// yazılmış ama hiçbir yerden import edilmiyordu; modüller "bildirim gönderildi"
// diyor, hiçbir şey göndermiyordu.
//
// Tasarım — giden kutusu (outbox):
//  1. Bildirim ÖNCE veritabanına yazılır (PENDING). Böylece gönderilemese bile
//     "haber verilmeye çalışıldığı" kayıtlıdır ve kaybolmaz.
//  2. Sonra sağlayıcıya verilir. Sağlayıcı yoksa kayıt PENDING kalır —
//     hiçbir yerde "gönderildi" DENMEZ.
//  3. Alıcı tercihi ya da onay eksikse kayıt SUPPRESSED olur ve GEREKÇESİ yazılır.
//
// Hukuki çerçeve:
//   - 6563 s. Kanun m.6: TİCARİ elektronik ileti için önceden onay şarttır.
//     Bu paket, onayı olmayan COMMERCIAL bildirimi göndermez (SUPPRESSED).
//     Site yönetiminin aidat/borç/arıza bildirimi TRANSACTIONAL'dır; hizmetin
//     ifasına ilişkindir ve onay gerektirmez.
//   - 634 s. KMK m.29: genel kurul çağrısı taahhütlü mektup ya da imza karşılığı
//     yapılır. Buradan gönderilen bildirim USULÜNE UYGUN ÇAĞRI YERİNE GEÇMEZ;
//     `TopicAssemblyCall` kullanıldığında bu uyarı kayda ve yanıta yazılır.
package notify

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Kanallar.
const (
	ChannelInApp = "IN_APP"
	ChannelPush  = "PUSH"
	ChannelSMS   = "SMS"
	ChannelEmail = "EMAIL"
)

// Kategoriler (6563 s. Kanun m.6 ayrımı).
const (
	// CategoryTransactional: hizmetin ifasına ilişkin bildirim. Onay gerekmez.
	CategoryTransactional = "TRANSACTIONAL"
	// CategoryCommercial: tanıtım/pazarlama içerikli ileti. ÖNCEDEN ONAY şarttır.
	CategoryCommercial = "COMMERCIAL"
)

// TopicAssemblyCall, genel kurul çağrısı hatırlatmasıdır. Bu konuda gönderilen
// bildirime, kanuni çağrı yerine geçmediği uyarısı EKLENİR.
const TopicAssemblyCall = "assembly.call"

// legalDisclaimerAssembly, genel kurul bildirimlerine eklenen zorunlu uyarıdır.
const legalDisclaimerAssembly = "\n\n---\nBu bildirim bir HATIRLATMADIR. Kat malikleri " +
	"kurulu çağrısı, 634 sayılı Kat Mülkiyeti Kanunu m.29 uyarınca taahhütlü mektupla " +
	"ya da imza karşılığı yapılır; bu elektronik bildirim kanuni çağrı yerine geçmez."

var (
	// ErrNoRecipient, alıcı adresi boşsa döner.
	ErrNoRecipient = errors.New("alıcı adresi boş")
	// ErrNoBody, gövde boşsa döner.
	ErrNoBody = errors.New("bildirim gövdesi boş")
	// ErrInvalidChannel, bilinmeyen kanal için döner.
	ErrInvalidChannel = errors.New("geçersiz bildirim kanalı")
	// ErrInvalidCategory, bilinmeyen kategori için döner.
	ErrInvalidCategory = errors.New("geçersiz bildirim kategorisi")
	// ErrDuplicate, aynı dedupe_key ile ikinci kayıt denendiğinde döner.
	ErrDuplicate = errors.New("bu bildirim zaten kuyruğa alınmış")
)

// Message, gönderilecek bildirimdir.
type Message struct {
	PropertyID string
	// RecipientUserID boş bırakılabilir (site dışı alıcı).
	RecipientUserID string
	// Recipient, kanala göre telefon / e-posta / cihaz jetonudur.
	Recipient string
	Channel   string
	Category  string
	Topic     string
	Subject   string
	Body      string
	Payload   map[string]any
	// DedupeKey verilirse aynı olay iki kez kuyruğa girmez.
	DedupeKey string
	CreatedBy string
}

// Result, kuyruğa alma sonucudur.
type Result struct {
	ID       string `json:"id"`
	Status   string `json:"status"`
	Provider string `json:"provider,omitempty"`
	// Reason, SUPPRESSED ya da PENDING kaldıysa nedenini açıklar.
	Reason string `json:"reason,omitempty"`
}

// Sender, bir bildirim sağlayıcısıdır.
//
// Send yalnızca GERÇEKTEN gönderim yapabiliyorsa nil hata döndürmelidir.
// "Gönderdim" deyip hiçbir şey yapmayan bir uygulama, bu paketin varlık
// sebebine aykırıdır.
type Sender interface {
	// Name, sağlayıcı adıdır (kayıtta `provider` olarak saklanır).
	Name() string
	// Supports, sağlayıcının bu kanalı destekleyip desteklemediğini söyler.
	Supports(channel string) bool
	// Send, bildirimi gönderir ve sağlayıcı mesaj kimliğini döner.
	Send(ctx context.Context, m Message) (providerMessageID string, err error)
}

// Notifier, bildirimleri kuyruğa alır ve (sağlayıcı varsa) gönderir.
type Notifier struct {
	pool    *pgxpool.Pool
	senders []Sender
}

// New, kayıtlı sağlayıcılarla bir Notifier kurar.
// Sağlayıcı listesi boş olabilir: o hâlde bildirimler kuyrukta PENDING kalır.
func New(pool *pgxpool.Pool, senders ...Sender) *Notifier {
	return &Notifier{pool: pool, senders: senders}
}

// Providers, kayıtlı sağlayıcı adlarını döner (sağlık ucunda dürüstlük için).
func (n *Notifier) Providers() []string {
	out := make([]string, 0, len(n.senders))
	for _, s := range n.senders {
		out = append(out, s.Name())
	}
	return out
}

// Enqueue, bildirimi kuyruğa alır ve mümkünse gönderir.
//
// Akış:
//  1. Girdi doğrulanır.
//  2. Alıcı tercihi ve (ticari ise) onay denetlenir → gerekiyorsa SUPPRESSED.
//  3. Kayıt PENDING olarak yazılır.
//  4. Kanalı destekleyen sağlayıcı varsa gönderilir → SENT ya da FAILED.
//     Sağlayıcı yoksa PENDING kalır ve nedeni açıkça bildirilir.
func (n *Notifier) Enqueue(ctx context.Context, m Message) (*Result, error) {
	if err := validate(&m); err != nil {
		return nil, err
	}

	// Genel kurul bildirimine kanuni uyarı eklenir; bu metin gövdeye YAZILIR ki
	// alıcı da görsün, yalnızca API yanıtında kalmasın.
	if m.Topic == TopicAssemblyCall {
		m.Body += legalDisclaimerAssembly
	}

	if reason, err := n.suppressReason(ctx, m); err != nil {
		return nil, err
	} else if reason != "" {
		id, ierr := n.insert(ctx, m, "SUPPRESSED", reason)
		if ierr != nil {
			return nil, ierr
		}
		return &Result{ID: id, Status: "SUPPRESSED", Reason: reason}, nil
	}

	id, err := n.insert(ctx, m, "PENDING", "")
	if err != nil {
		return nil, err
	}

	sender := n.senderFor(m.Channel)
	if sender == nil {
		// Sağlayıcı yok: kayıt kuyrukta kalır. "Gönderildi" DENMEZ.
		reason := fmt.Sprintf("%s kanalı için yapılandırılmış sağlayıcı yok; "+
			"bildirim kuyrukta bekliyor ve GÖNDERİLMEDİ", m.Channel)
		return &Result{ID: id, Status: "PENDING", Reason: reason}, nil
	}

	providerMsgID, sendErr := sender.Send(ctx, m)
	if sendErr != nil {
		if _, err := n.scope(m.PropertyID).Exec(ctx, `
			UPDATE notifications
			SET status = 'FAILED', attempts = attempts + 1, last_error = $2, provider = $3
			WHERE id = $1`, id, sendErr.Error(), sender.Name()); err != nil {
			return nil, err
		}
		return &Result{ID: id, Status: "FAILED", Provider: sender.Name(),
			Reason: sendErr.Error()}, nil
	}

	if _, err := n.scope(m.PropertyID).Exec(ctx, `
		UPDATE notifications
		SET status = 'SENT', sent_at = now(), attempts = attempts + 1,
		    provider = $2, provider_message_id = NULLIF($3,'')
		WHERE id = $1`, id, sender.Name(), providerMsgID); err != nil {
		return nil, err
	}
	return &Result{ID: id, Status: "SENT", Provider: sender.Name()}, nil
}

func validate(m *Message) error {
	m.Recipient = strings.TrimSpace(m.Recipient)
	m.Body = strings.TrimSpace(m.Body)
	m.Channel = strings.ToUpper(strings.TrimSpace(m.Channel))
	m.Category = strings.ToUpper(strings.TrimSpace(m.Category))
	if m.Category == "" {
		m.Category = CategoryTransactional
	}
	if m.Topic == "" {
		m.Topic = "general"
	}

	switch m.Channel {
	case ChannelInApp, ChannelPush, ChannelSMS, ChannelEmail:
	default:
		return ErrInvalidChannel
	}
	switch m.Category {
	case CategoryTransactional, CategoryCommercial:
	default:
		return ErrInvalidCategory
	}
	if m.Recipient == "" {
		return ErrNoRecipient
	}
	if m.Body == "" {
		return ErrNoBody
	}
	return nil
}

// suppressReason, bildirimin gönderilmemesi gerekiyorsa gerekçesini döner.
//
// İki ayrı kural:
//   - TİCARİ ileti: alıcının AÇIK ONAYI yoksa gönderilmez (6563 s. Kanun m.6).
//     Onayın yokluğu varsayılan olarak "gönderme" anlamına gelir; tersi kanuna
//     aykırı olurdu.
//   - İŞLEMSEL ileti: alıcı bu kanalı kapatmışsa gönderilmez. Kapatma kaydı
//     yoksa gönderilir (hizmetin ifasına ilişkin bildirim varsayılan açıktır).
func (n *Notifier) suppressReason(ctx context.Context, m Message) (string, error) {
	if m.RecipientUserID == "" {
		// Site dışı alıcıda tercih kaydı aranmaz; ticari ileti ise gönderilmez.
		if m.Category == CategoryCommercial {
			return "Ticari elektronik ileti için alıcı onayı kaydı yok " +
				"(6563 s. Kanun m.6)", nil
		}
		return "", nil
	}

	var enabled *bool
	var consentAt *time.Time
	err := n.scope(m.PropertyID).QueryRow(ctx, `
		SELECT enabled, consent_at FROM notification_preferences
		WHERE user_id = $1 AND channel = $2 AND category = $3
		  AND (property_id = $4 OR property_id IS NULL)
		ORDER BY (property_id IS NOT NULL) DESC
		LIMIT 1`,
		m.RecipientUserID, m.Channel, m.Category, m.PropertyID).Scan(&enabled, &consentAt)
	if err != nil && err != pgx.ErrNoRows {
		return "", err
	}

	if m.Category == CategoryCommercial {
		if err == pgx.ErrNoRows || enabled == nil || !*enabled || consentAt == nil {
			return "Ticari elektronik ileti için alıcının önceden onayı yok " +
				"(6563 s. Kanun m.6)", nil
		}
		return "", nil
	}

	if err != pgx.ErrNoRows && enabled != nil && !*enabled {
		return fmt.Sprintf("Alıcı %s kanalını kapatmış", m.Channel), nil
	}
	return "", nil
}

func (n *Notifier) insert(ctx context.Context, m Message, status, reason string) (string, error) {
	payload := m.Payload
	if payload == nil {
		payload = map[string]any{}
	}
	var id string
	err := n.scope(m.PropertyID).QueryRow(ctx, `
		INSERT INTO notifications
			(property_id, recipient_user_id, recipient_address, channel, category,
			 topic, subject, body, payload, dedupe_key, status, suppress_reason, created_by)
		VALUES ($1, NULLIF($2,'')::uuid, $3, $4, $5, $6, NULLIF($7,''), $8, $9,
		        NULLIF($10,''), $11, NULLIF($12,''), NULLIF($13,'')::uuid)
		RETURNING id`,
		m.PropertyID, m.RecipientUserID, m.Recipient, m.Channel, m.Category,
		m.Topic, m.Subject, m.Body, payload, m.DedupeKey, status, reason, m.CreatedBy).Scan(&id)
	if err != nil && strings.Contains(err.Error(), "uq_notifications_dedupe") {
		return "", ErrDuplicate
	}
	return id, err
}

func (n *Notifier) senderFor(channel string) Sender {
	for _, s := range n.senders {
		if s.Supports(channel) {
			return s
		}
	}
	return nil
}

// scope, bildirim tablolarına SİTE KAPSAMLI erişim verir (FAZ 2.6).
//
// `notifications` ve `notification_preferences` tablolarında satır düzeyi
// güvenliği açıktır (migration 020): kapsam ayarlanmadan ne okuma ne yazma
// mümkündür. Bu, bir sitenin bildiriminin yanlışlıkla başka siteye yazılmasını
// veritabanı düzeyinde engeller.
func (n *Notifier) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(n.pool, propertyID)
}
