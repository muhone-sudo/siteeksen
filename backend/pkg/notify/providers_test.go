package notify

// SMS (Netgsm) ve SMTP sağlayıcılarının sahte sunuculara karşı sınanması.
// Gerçek gönderim kullanıcının hesabıyla yapılır; burada istek biçimi, kimlik
// doğrulama ve hata eşlemesi doğrulanır.

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestNormalizePhoneTR(t *testing.T) {
	cases := map[string]string{
		"+905551234567": "5551234567", "05551234567": "5551234567", "5551234567": "5551234567",
		"905551234567": "5551234567", "0090 555 123 45 67": "5551234567", "+352 621 123 456": "00352621123456",
		"12345": "", "": "",
	}
	for in, want := range cases {
		if got := NormalizePhoneTR(in); got != want {
			t.Errorf("NormalizePhoneTR(%q) = %q, beklenen %q", in, got, want)
		}
	}
}

func TestNetgsmSendRequestAndSuccess(t *testing.T) {
	var got netgsmRequest
	var user, pass, path string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		path = r.URL.Path
		user, pass, _ = r.BasicAuth()
		_ = json.NewDecoder(r.Body).Decode(&got)
		_, _ = w.Write([]byte(`{"code":"00","jobid":"J123","description":"queued"}`))
	}))
	defer srv.Close()
	s := &NetgsmSender{BaseURL: srv.URL, UserCode: "850xxx", Password: "gizli", Header: "SITEEKSEN"}
	id, err := s.Send(context.Background(), Message{Channel: ChannelSMS, Category: CategoryTransactional,
		Recipient: "+905551234567", Body: "Etkinleştirme kodunuz: ABCD1234"})
	if err != nil || id != "J123" {
		t.Fatalf("gönderim: id=%q err=%v", id, err)
	}
	if path != "/sms/rest/v2/send" || user != "850xxx" || pass != "gizli" {
		t.Fatalf("istek: yol=%s kullanıcı=%s", path, user)
	}
	if got.MsgHeader != "SITEEKSEN" || got.Encoding != "TR" || got.IYSFilter != "0" ||
		len(got.Messages) != 1 || got.Messages[0].No != "5551234567" || !strings.Contains(got.Messages[0].Msg, "ABCD1234") {
		t.Fatalf("gövde beklenmedik: %+v", got)
	}
}

func TestNetgsmErrorCodeAndCommercialRefused(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`{"code":"40","description":"header"}`))
	}))
	defer srv.Close()
	s := &NetgsmSender{BaseURL: srv.URL, UserCode: "u", Password: "p", Header: "YANLIS"}
	_, err := s.Send(context.Background(), Message{Channel: ChannelSMS, Recipient: "5551234567", Body: "x"})
	if err == nil || !strings.Contains(err.Error(), "gönderici başlığı") {
		t.Fatalf("kod 40 açıklamayla dönmeli: %v", err)
	}
	if _, err := s.Send(context.Background(), Message{Channel: ChannelSMS, Category: CategoryCommercial, Recipient: "5551234567", Body: "kampanya"}); err == nil {
		t.Fatal("ticari SMS reddedilmeliydi")
	}
	if _, err := s.Send(context.Background(), Message{Channel: ChannelSMS, Recipient: "123", Body: "x"}); err == nil {
		t.Fatal("geçersiz numara reddedilmeliydi")
	}
}

func TestNetgsmFromEnvRequiresAllFields(t *testing.T) {
	t.Setenv("NETGSM_USERCODE", "u")
	t.Setenv("NETGSM_PASSWORD", "")
	t.Setenv("NETGSM_MSGHEADER", "")
	if _, err := NetgsmFromEnv(); err == nil {
		t.Fatal("eksik yapılandırma hata vermeliydi")
	}
}

// fakeSMTP, tek iletiyi kabul eden en küçük SMTP sunucusudur (TLS yok — SMTP_TLS=none).
func fakeSMTP(t *testing.T) (addr string, got chan string) {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	got = make(chan string, 1)
	go func() {
		conn, err := ln.Accept()
		if err != nil {
			return
		}
		defer conn.Close()
		defer ln.Close()
		r := bufio.NewReader(conn)
		w := func(s string) { _, _ = conn.Write([]byte(s + "\r\n")) }
		w("220 test ESMTP")
		var data strings.Builder
		inData := false
		for {
			line, err := r.ReadString('\n')
			if err != nil {
				return
			}
			if inData {
				if line == ".\r\n" {
					inData = false
					w("250 OK kabul")
					got <- data.String()
					continue
				}
				data.WriteString(line)
				continue
			}
			cmd := strings.ToUpper(strings.TrimSpace(line))
			switch {
			case strings.HasPrefix(cmd, "EHLO"), strings.HasPrefix(cmd, "HELO"):
				w("250 test")
			case strings.HasPrefix(cmd, "MAIL"), strings.HasPrefix(cmd, "RCPT"):
				data.WriteString(strings.TrimSpace(line) + "\n")
				w("250 OK")
			case cmd == "DATA":
				inData = true
				w("354 devam")
			case cmd == "QUIT":
				w("221 güle güle")
				return
			default:
				w("250 OK")
			}
		}
	}()
	return ln.Addr().String(), got
}

func TestSMTPSendPlainLocal(t *testing.T) {
	addr, got := fakeSMTP(t)
	host, port, _ := net.SplitHostPort(addr)
	s := &SMTPSender{Host: host, Port: port, From: "Yönetim <yonetim@site.test>", TLSMode: "none"}
	if _, err := s.Send(context.Background(), Message{Channel: ChannelEmail, Recipient: "sakin@ornek.test",
		Subject: "Acil duyuru: yarın su kesintisi", Body: "Yarın 10:00-14:00 arası su kesilecektir."}); err != nil {
		t.Fatalf("gönderim: %v", err)
	}
	raw := <-got
	if !strings.Contains(raw, "MAIL FROM:<yonetim@site.test>") || !strings.Contains(raw, "RCPT TO:<sakin@ornek.test>") {
		t.Fatalf("zarf beklenmedik: %s", raw)
	}
	if !strings.Contains(raw, "Subject: =?utf-8?q?") || !strings.Contains(raw, "charset=utf-8") || !strings.Contains(raw, "From: =?utf-8?q?Y=C3=B6netim?=") {
		t.Fatalf("başlık kodlaması yok: %s", raw)
	}
	body := raw[strings.Index(raw, "\r\n\r\n")+4:]
	dec, _ := base64.StdEncoding.DecodeString(strings.ReplaceAll(strings.TrimSpace(body), "\r\n", ""))
	if !strings.Contains(string(dec), "su kesilecektir") {
		t.Fatalf("gövde çözülemedi: %q", body)
	}
}

func TestSMTPFromEnvRefusesCredentialsWithoutTLS(t *testing.T) {
	t.Setenv("SMTP_HOST", "smtp.ornek.test")
	t.Setenv("SMTP_FROM", "a@b.test")
	t.Setenv("SMTP_TLS", "none")
	t.Setenv("SMTP_USERNAME", "kullanici")
	if _, err := SMTPFromEnv(); err == nil {
		t.Fatal("şifresiz bağlantıda parola gönderimine izin verilmemeli")
	}
	t.Setenv("SMTP_TLS", "starttls")
	s, err := SMTPFromEnv()
	if err != nil || s == nil || s.Port != "587" {
		t.Fatalf("varsayılan STARTTLS/587: %v %+v", err, s)
	}
}

func TestSendersFromEnvRegistersProviders(t *testing.T) {
	t.Setenv("NETGSM_USERCODE", "u")
	t.Setenv("NETGSM_PASSWORD", "p")
	t.Setenv("NETGSM_MSGHEADER", "H")
	t.Setenv("SMTP_HOST", "smtp.ornek.test")
	t.Setenv("SMTP_FROM", "a@b.test")
	d := Describe(SendersFromEnv())
	names := strings.Join(d["providers"].([]string), ",")
	if !strings.Contains(names, "netgsm") || !strings.Contains(names, "smtp") {
		t.Fatalf("sağlayıcılar: %s", names)
	}
	missing := d["channels_without_provider"].([]string)
	if len(missing) != 1 || missing[0] != ChannelPush {
		t.Fatalf("eksik kanal yalnızca PUSH olmalı: %v", missing)
	}
}
