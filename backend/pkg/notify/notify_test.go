package notify

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type fakeSender struct {
	name     string
	channels []string
	err      error
	sent     []Message
}

func (f *fakeSender) Name() string { return f.name }

func (f *fakeSender) Supports(channel string) bool {
	for _, c := range f.channels {
		if c == channel {
			return true
		}
	}
	return false
}

func (f *fakeSender) Send(_ context.Context, m Message) (string, error) {
	if f.err != nil {
		return "", f.err
	}
	f.sent = append(f.sent, m)
	return "msg-1", nil
}

func TestValidateKanalVeKategori(t *testing.T) {
	m := Message{Recipient: "5551234567", Body: "test", Channel: "sms"}
	if err := validate(&m); err != nil {
		t.Fatalf("küçük harfli kanal reddedildi: %v", err)
	}
	if m.Channel != ChannelSMS {
		t.Fatalf("kanal büyük harfe çevrilmedi: %s", m.Channel)
	}
	if m.Category != CategoryTransactional {
		t.Fatalf("varsayılan kategori işlemsel olmalı: %s", m.Category)
	}

	bad := Message{Recipient: "x", Body: "y", Channel: "GUVERCIN"}
	if err := validate(&bad); !errors.Is(err, ErrInvalidChannel) {
		t.Fatalf("uydurma kanal kabul edildi: %v", err)
	}

	noRecipient := Message{Body: "y", Channel: ChannelSMS}
	if err := validate(&noRecipient); !errors.Is(err, ErrNoRecipient) {
		t.Fatalf("alıcısız bildirim kabul edildi: %v", err)
	}

	noBody := Message{Recipient: "x", Channel: ChannelSMS}
	if err := validate(&noBody); !errors.Is(err, ErrNoBody) {
		t.Fatalf("boş gövde kabul edildi: %v", err)
	}
}

func TestSenderForKanalaGoreSecilir(t *testing.T) {
	sms := &fakeSender{name: "sms", channels: []string{ChannelSMS}}
	mail := &fakeSender{name: "mail", channels: []string{ChannelEmail}}
	n := &Notifier{senders: []Sender{sms, mail}}

	if got := n.senderFor(ChannelSMS); got == nil || got.Name() != "sms" {
		t.Fatalf("SMS için yanlış sağlayıcı: %v", got)
	}
	if got := n.senderFor(ChannelEmail); got == nil || got.Name() != "mail" {
		t.Fatalf("e-posta için yanlış sağlayıcı: %v", got)
	}
	if got := n.senderFor(ChannelPush); got != nil {
		t.Fatalf("sağlayıcısı olmayan kanal için sağlayıcı döndü: %s", got.Name())
	}
}

func TestGenelKurulBildirimineKanuniUyariEklenir(t *testing.T) {
	// KMK m.29: çağrı taahhütlü mektup ya da imza karşılığı yapılır. Elektronik
	// bildirim kanuni çağrı yerine GEÇMEZ; bu uyarı alıcının gördüğü gövdeye
	// eklenmelidir, yalnızca API yanıtında kalmamalıdır.
	m := Message{
		Recipient: "5551234567", Body: "Genel kurul 1 Ekim'de",
		Channel: ChannelSMS, Topic: TopicAssemblyCall,
	}
	if err := validate(&m); err != nil {
		t.Fatal(err)
	}
	if m.Topic == TopicAssemblyCall {
		m.Body += legalDisclaimerAssembly
	}
	if !strings.Contains(m.Body, "m.29") {
		t.Fatal("genel kurul bildirimine kanuni uyarı eklenmedi")
	}
	if !strings.Contains(m.Body, "kanuni çağrı yerine geçmez") {
		t.Fatal("uyarı metni çağrının yerine geçmediğini söylemiyor")
	}
}

func TestInAppSenderDisariyaGondermez(t *testing.T) {
	s := InAppSender{}
	if !s.Supports(ChannelInApp) {
		t.Fatal("uygulama içi kanal desteklenmiyor")
	}
	if s.Supports(ChannelSMS) {
		t.Fatal("uygulama içi sağlayıcı SMS desteklediğini iddia ediyor")
	}
	if _, err := s.Send(context.Background(), Message{}); err != nil {
		t.Fatalf("uygulama içi gönderim hata verdi: %v", err)
	}
}

func TestLogSenderKanalSecimi(t *testing.T) {
	l := NewLogSender()
	for _, ch := range []string{ChannelPush, ChannelSMS, ChannelEmail} {
		if !l.Supports(ch) {
			t.Fatalf("varsayılan günlük sağlayıcısı %s desteklemiyor", ch)
		}
	}
	only := NewLogSender(ChannelSMS)
	if only.Supports(ChannelEmail) {
		t.Fatal("kanal listesi dışındaki kanal destekleniyor görünüyor")
	}
}

func TestMaskRecipientKisiselVeriSizdirmaz(t *testing.T) {
	cases := map[string]string{
		"5551234567":        "555****67",
		"ahmet@example.com": "a***@example.com",
		"12345":             "***",
	}
	for in, want := range cases {
		if got := maskRecipient(in); got != want {
			t.Errorf("maskRecipient(%q) = %q, beklenen %q", in, got, want)
		}
	}
	// Maskelenmiş değer, orijinalin tamamını içermemelidir.
	if strings.Contains(maskRecipient("5551234567"), "1234") {
		t.Fatal("maskeleme telefonun orta hanelerini sızdırıyor")
	}
}

func TestDescribeEksikKanallariBildirir(t *testing.T) {
	d := Describe([]Sender{InAppSender{}})
	missing, _ := d["channels_without_provider"].([]string)
	if len(missing) != 3 {
		t.Fatalf("eksik kanallar doğru sayılmadı: %v", missing)
	}
	note, _ := d["note"].(string)
	if !strings.Contains(note, "GÖNDERİLMEZ") {
		t.Fatalf("eksik sağlayıcı durumu dürüstçe bildirilmiyor: %q", note)
	}

	full := Describe([]Sender{InAppSender{}, NewLogSender()})
	if m, _ := full["channels_without_provider"].([]string); len(m) != 0 {
		t.Fatalf("tüm kanallar kapsanmışken eksik bildirildi: %v", m)
	}
	if _, hasNote := full["note"]; hasNote {
		t.Fatal("eksik kanal yokken uyarı notu üretildi")
	}
}

func TestTruncateUzunGovdeyiKisaltir(t *testing.T) {
	long := strings.Repeat("a", 100)
	got := truncate(long, 10)
	if len([]rune(got)) != 11 { // 10 karakter + …
		t.Fatalf("kısaltma uzunluğu yanlış: %d", len([]rune(got)))
	}
	if truncate("kısa", 10) != "kısa" {
		t.Fatal("kısa metin gereksiz kısaltıldı")
	}
	if strings.Contains(truncate("a\nb", 10), "\n") {
		t.Fatal("satır sonu günlüğe olduğu gibi yazılıyor")
	}
}
