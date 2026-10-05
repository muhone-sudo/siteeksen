package notify

// SMTP e-posta sağlayıcısı (TEST_RAPORU 2.4). Standart SMTP sunucusu, AWS SES SMTP
// arayüzü ya da SendGrid SMTP ile çalışır; harici bağımlılık yoktur (net/smtp).
//
//	SMTP_HOST, SMTP_PORT (varsayılan 587), SMTP_USERNAME, SMTP_PASSWORD, SMTP_FROM
//	SMTP_TLS: starttls (varsayılan) | tls (465, örtük TLS) | none (yalnızca yerel test)

import (
	"context"
	"crypto/rand"
	"crypto/tls"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"mime"
	"net"
	"net/mail"
	"net/smtp"
	"os"
	"strings"
	"time"
)

// SMTPSender, EMAIL kanalını SMTP ile gönderir.
type SMTPSender struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
	TLSMode  string // starttls | tls | none
}

// SMTPFromEnv, SMTP_* değişkenleriyle kurar; SMTP_HOST yoksa nil.
func SMTPFromEnv() (*SMTPSender, error) {
	host := strings.TrimSpace(os.Getenv("SMTP_HOST"))
	if host == "" {
		return nil, nil
	}
	s := &SMTPSender{Host: host, Port: strings.TrimSpace(os.Getenv("SMTP_PORT")),
		Username: os.Getenv("SMTP_USERNAME"), Password: os.Getenv("SMTP_PASSWORD"),
		From: strings.TrimSpace(os.Getenv("SMTP_FROM")), TLSMode: strings.ToLower(strings.TrimSpace(os.Getenv("SMTP_TLS")))}
	if s.Port == "" {
		s.Port = "587"
	}
	if s.TLSMode == "" {
		s.TLSMode = "starttls"
	}
	if s.TLSMode != "starttls" && s.TLSMode != "tls" && s.TLSMode != "none" {
		return nil, fmt.Errorf("SMTP_TLS geçersiz: %q (starttls|tls|none)", s.TLSMode)
	}
	if _, err := mail.ParseAddress(s.From); err != nil {
		return nil, fmt.Errorf("SMTP_FROM geçerli bir adres olmalı: %v", err)
	}
	if s.TLSMode == "none" && s.Username != "" {
		// Parola şifresiz bağlantıda gönderilmez.
		return nil, errors.New("SMTP_TLS=none iken kimlik bilgisi kullanılamaz (parola açık metin giderdi)")
	}
	return s, nil
}

func (s *SMTPSender) Name() string { return "smtp" }

func (s *SMTPSender) Supports(channel string) bool { return channel == ChannelEmail }

// buildEmail, UTF-8 düz metin iletiyi RFC 5322 biçiminde kurar (başlıklar RFC 2047).
func buildEmail(from, to, subject, body string) []byte {
	id := make([]byte, 12)
	_, _ = rand.Read(id)
	host := "siteeksen.local"
	if i := strings.LastIndex(from, "@"); i >= 0 {
		host = strings.Trim(from[i+1:], "> ")
	}
	var b strings.Builder
	// Görünen ad ASCII dışı karakter içerebilir ("Yönetim"): RFC 2047 ile kodlanır.
	if a, err := mail.ParseAddress(from); err == nil {
		from = a.String()
	}
	b.WriteString("From: " + from + "\r\n")
	b.WriteString("To: " + to + "\r\n")
	b.WriteString("Subject: " + mime.QEncoding.Encode("utf-8", subject) + "\r\n")
	b.WriteString("Date: " + time.Now().Format(time.RFC1123Z) + "\r\n")
	b.WriteString("Message-ID: <" + hex.EncodeToString(id) + "@" + host + ">\r\n")
	b.WriteString("MIME-Version: 1.0\r\n")
	b.WriteString("Content-Type: text/plain; charset=utf-8\r\n")
	b.WriteString("Content-Transfer-Encoding: base64\r\n\r\n")
	enc := base64.StdEncoding.EncodeToString([]byte(body))
	for len(enc) > 76 {
		b.WriteString(enc[:76] + "\r\n")
		enc = enc[76:]
	}
	b.WriteString(enc + "\r\n")
	return []byte(b.String())
}

func (s *SMTPSender) Send(ctx context.Context, m Message) (string, error) {
	to, err := mail.ParseAddress(m.Recipient)
	if err != nil {
		return "", fmt.Errorf("e-posta adresi geçersiz: %s", maskRecipient(m.Recipient))
	}
	subject := m.Subject
	if subject == "" {
		subject = "SiteEksen bildirimi"
	}
	msg := buildEmail(s.From, to.Address, subject, m.Body)
	addr := net.JoinHostPort(s.Host, s.Port)
	dialer := &net.Dialer{Timeout: 15 * time.Second}

	var conn net.Conn
	if s.TLSMode == "tls" {
		conn, err = tls.DialWithDialer(dialer, "tcp", addr, &tls.Config{ServerName: s.Host, MinVersion: tls.VersionTLS12})
	} else {
		conn, err = dialer.DialContext(ctx, "tcp", addr)
	}
	if err != nil {
		return "", fmt.Errorf("SMTP sunucusuna bağlanılamadı: %w", err)
	}
	if dl, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(dl)
	} else {
		_ = conn.SetDeadline(time.Now().Add(30 * time.Second))
	}
	c, err := smtp.NewClient(conn, s.Host)
	if err != nil {
		conn.Close()
		return "", fmt.Errorf("SMTP oturumu açılamadı: %w", err)
	}
	defer c.Close()
	if s.TLSMode == "starttls" {
		if ok, _ := c.Extension("STARTTLS"); !ok {
			return "", errors.New("SMTP sunucusu STARTTLS desteklemiyor; şifresiz gönderim yapılmadı")
		}
		if err := c.StartTLS(&tls.Config{ServerName: s.Host, MinVersion: tls.VersionTLS12}); err != nil {
			return "", fmt.Errorf("STARTTLS başarısız: %w", err)
		}
	}
	if s.Username != "" {
		if err := c.Auth(smtp.PlainAuth("", s.Username, s.Password, s.Host)); err != nil {
			return "", fmt.Errorf("SMTP kimlik doğrulaması başarısız: %w", err)
		}
	}
	from, _ := mail.ParseAddress(s.From)
	if err := c.Mail(from.Address); err != nil {
		return "", fmt.Errorf("SMTP MAIL FROM reddedildi: %w", err)
	}
	if err := c.Rcpt(to.Address); err != nil {
		return "", fmt.Errorf("SMTP alıcı reddedildi: %w", err)
	}
	w, err := c.Data()
	if err != nil {
		return "", fmt.Errorf("SMTP DATA reddedildi: %w", err)
	}
	if _, err := w.Write(msg); err != nil {
		return "", err
	}
	if err := w.Close(); err != nil {
		return "", fmt.Errorf("SMTP ileti kabul edilmedi: %w", err)
	}
	_ = c.Quit()
	return "", nil
}
