package notify

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"
)

// InAppSender, uygulama içi bildirimleri "gönderir".
//
// Uygulama içi bildirimde gönderim diye bir şey yoktur: kayıt zaten
// veritabanındadır ve kullanıcı uygulamayı açtığında okur. Bu yüzden bu
// sağlayıcı GERÇEKTEN işini yapar — dışarıya bir şey göndermediği için de
// hiçbir yalan söylemez.
type InAppSender struct{}

func (InAppSender) Name() string { return "in_app" }

func (InAppSender) Supports(channel string) bool { return channel == ChannelInApp }

func (InAppSender) Send(_ context.Context, _ Message) (string, error) {
	// Kayıt zaten yazıldı; okunacağı yer veritabanı.
	return "", nil
}

// LogSender, bildirimi yalnızca sunucu günlüğüne yazar.
//
// NE İŞE YARAR: geliştirme ve ilk kurulumda, sağlayıcı sözleşmesi yapılmadan
// akışın uçtan uca denenebilmesi için. Dışarıya HİÇBİR ŞEY GÖNDERMEZ ve bunu
// hem günlükte hem sağlayıcı adında ("log") açıkça belirtir.
//
// DİKKAT: Bu sağlayıcı etkinken kayıtlar SENT olur. Bu, "sakine ulaştı"
// anlamına GELMEZ; yalnızca sistemin bildirimi ürettiği anlamına gelir.
// Üretimde kullanılmamalıdır; bu yüzden yalnızca NOTIFY_LOG_SENDER=true ile
// açılır ve açılışta uyarı basar.
type LogSender struct {
	channels []string
}

// NewLogSender, verilen kanallar için günlük sağlayıcısı kurar.
func NewLogSender(channels ...string) *LogSender {
	if len(channels) == 0 {
		channels = []string{ChannelPush, ChannelSMS, ChannelEmail}
	}
	return &LogSender{channels: channels}
}

func (l *LogSender) Name() string { return "log" }

func (l *LogSender) Supports(channel string) bool {
	for _, c := range l.channels {
		if c == channel {
			return true
		}
	}
	return false
}

func (l *LogSender) Send(_ context.Context, m Message) (string, error) {
	id := randomID()
	// Gövde günlüğe KISALTILARAK yazılır: bildirim metni kişisel veri içerebilir
	// (borç tutarı, daire numarası) ve sunucu günlüğü kalıcıdır.
	log.Printf("[notify:log] GÖNDERİM YAPILMADI (yalnızca günlük) — kanal=%s konu=%s "+
		"alıcı=%s mesaj_id=%s gövde=%q",
		m.Channel, m.Topic, maskRecipient(m.Recipient), id, truncate(m.Body, 60))
	return id, nil
}

// maskRecipient, telefon/e-postayı günlükte maskeler (KVKK m.4 veri minimizasyonu).
func maskRecipient(s string) string {
	if i := strings.Index(s, "@"); i > 1 {
		return s[:1] + "***" + s[i:]
	}
	if len(s) > 6 {
		return s[:3] + "****" + s[len(s)-2:]
	}
	return "***"
}

func truncate(s string, n int) string {
	s = strings.ReplaceAll(s, "\n", " ")
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

func randomID() string {
	b := make([]byte, 8)
	if _, err := rand.Read(b); err != nil {
		return "log-unknown"
	}
	return "log-" + hex.EncodeToString(b)
}

// SendersFromEnv, ortam değişkenlerine göre sağlayıcı listesini kurar.
//
// Uygulama içi bildirim HER ZAMAN etkindir (dışarıya çıkmaz).
// Diğer kanallar için sağlayıcı YOKSA liste boş kalır ve bildirimler kuyrukta
// PENDING bekler — sessizce "gönderildi" denmez.
//
//	NOTIFY_LOG_SENDER=true  → günlük sağlayıcısı (yalnızca geliştirme)
//	NOTIFY_LOG_CHANNELS     → virgülle ayrılmış kanal listesi (varsayılan PUSH,SMS,EMAIL)
//
// Gerçek sağlayıcılar (FCM, SMS operatörü, SMTP) henüz YAZILMAMIŞTIR; sözleşme
// ve anahtar gerektirdikleri için bilerek eklenmemiştir. Eklendiklerinde bu
// fonksiyona kaydedilmeleri yeterlidir; çağıran kodun değişmesi gerekmez.
func SendersFromEnv() []Sender {
	senders := []Sender{InAppSender{}}

	if strings.EqualFold(strings.TrimSpace(os.Getenv("NOTIFY_LOG_SENDER")), "true") {
		channels := []string{}
		if raw := os.Getenv("NOTIFY_LOG_CHANNELS"); raw != "" {
			for _, c := range strings.Split(raw, ",") {
				if t := strings.ToUpper(strings.TrimSpace(c)); t != "" {
					channels = append(channels, t)
				}
			}
		}
		log.Printf("[notify] UYARI: günlük sağlayıcısı etkin. Bildirimler DIŞARIYA " +
			"GÖNDERİLMEZ, yalnızca sunucu günlüğüne yazılır. Üretimde kullanmayın.")
		senders = append(senders, NewLogSender(channels...))
	}
	return senders
}

// Describe, etkin sağlayıcıları ve kapsamlarını insan diliyle özetler.
func Describe(senders []Sender) map[string]any {
	names := make([]string, 0, len(senders))
	for _, s := range senders {
		names = append(names, s.Name())
	}
	covered := map[string]bool{}
	for _, ch := range []string{ChannelInApp, ChannelPush, ChannelSMS, ChannelEmail} {
		for _, s := range senders {
			if s.Supports(ch) {
				covered[ch] = true
			}
		}
	}
	missing := []string{}
	for _, ch := range []string{ChannelInApp, ChannelPush, ChannelSMS, ChannelEmail} {
		if !covered[ch] {
			missing = append(missing, ch)
		}
	}

	d := map[string]any{
		"providers":                 names,
		"channels_without_provider": missing,
	}
	if len(missing) > 0 {
		d["note"] = fmt.Sprintf("Şu kanallar için sağlayıcı YOK: %s. Bu kanallardaki "+
			"bildirimler kuyruğa yazılır ama GÖNDERİLMEZ (PENDING kalır).",
			strings.Join(missing, ", "))
	}
	return d
}
