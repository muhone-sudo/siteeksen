package storage

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// S3, S3 uyumlu nesne depolarına yazar.
//
// Aynı kod üç sağlayıcıda da çalışır (S-09):
//   - Oracle Cloud Object Storage (S3 uyumluluk uç noktası)
//   - Cloudflare R2
//   - AWS S3
//
// İmzalama AWS Signature Version 4 ile, HARİCİ BAĞIMLILIK OLMADAN yapılır.
// Büyük bir SDK eklemek yerine stdlib kullanmak, hem bağımlılık yüzeyini hem de
// sürüm çakışması riskini küçük tutar; SigV4 kapalı ve iyi tanımlı bir algoritmadır.
type S3 struct {
	cfg    S3Config
	client *http.Client
	host   string
	scheme string
}

// S3Config, S3 uyumlu depo ayarlarıdır.
type S3Config struct {
	Bucket      string
	Region      string
	Endpoint    string // boşsa AWS S3 varsayılır
	AccessKeyID string
	SecretKey   string
	// ForcePathStyle true ise URL https://host/bucket/key biçiminde kurulur.
	// Oracle ve R2 bu biçimi ister; AWS ikisini de kabul eder.
	ForcePathStyle bool
	MaxBytes       int64
	// HTTPClient yalnızca testler için; boşsa varsayılan istemci kullanılır.
	HTTPClient *http.Client
}

// NewS3, ayarları doğrular ve istemciyi kurar.
func NewS3(cfg S3Config) (*S3, error) {
	missing := []string{}
	if strings.TrimSpace(cfg.Bucket) == "" {
		missing = append(missing, "S3_BUCKET")
	}
	if strings.TrimSpace(cfg.Region) == "" {
		missing = append(missing, "S3_REGION")
	}
	if strings.TrimSpace(cfg.AccessKeyID) == "" {
		missing = append(missing, "S3_ACCESS_KEY_ID")
	}
	if strings.TrimSpace(cfg.SecretKey) == "" {
		missing = append(missing, "S3_SECRET_ACCESS_KEY")
	}
	if len(missing) > 0 {
		return nil, fmt.Errorf("%w: eksik ayarlar: %s", ErrNotConfigured, strings.Join(missing, ", "))
	}
	if cfg.MaxBytes <= 0 {
		cfg.MaxBytes = DefaultMaxBytes
	}

	scheme, host := "https", ""
	if cfg.Endpoint == "" {
		host = fmt.Sprintf("s3.%s.amazonaws.com", cfg.Region)
	} else {
		u, err := url.Parse(cfg.Endpoint)
		if err != nil {
			return nil, fmt.Errorf("S3_ENDPOINT ayrıştırılamadı: %w", err)
		}
		if u.Scheme != "" {
			scheme = u.Scheme
		}
		host = u.Host
		if host == "" {
			host = strings.TrimSuffix(u.Path, "/")
		}
		if host == "" {
			return nil, fmt.Errorf("%w: S3_ENDPOINT geçersiz", ErrNotConfigured)
		}
	}

	client := cfg.HTTPClient
	if client == nil {
		client = &http.Client{Timeout: 60 * time.Second}
	}
	return &S3{cfg: cfg, client: client, host: host, scheme: scheme}, nil
}

func (s *S3) Backend() string { return "s3" }

// Describe, ayarları SIR İÇERMEDEN özetler. Erişim anahtarı asla yazılmaz.
func (s *S3) Describe() map[string]string {
	return map[string]string{
		"backend":          "s3",
		"bucket":           s.cfg.Bucket,
		"region":           s.cfg.Region,
		"endpoint":         s.scheme + "://" + s.host,
		"force_path_style": strconv.FormatBool(s.cfg.ForcePathStyle),
		"max_bytes":        strconv.FormatInt(s.cfg.MaxBytes, 10),
	}
}

// objectURL, nesnenin tam adresini ve imzalanacak yolu üretir.
func (s *S3) objectURL(key string) (full string, canonicalPath string) {
	escaped := escapePath(key)
	if s.cfg.ForcePathStyle {
		canonicalPath = "/" + s.cfg.Bucket + "/" + escaped
		return s.scheme + "://" + s.host + canonicalPath, canonicalPath
	}
	canonicalPath = "/" + escaped
	return s.scheme + "://" + s.cfg.Bucket + "." + s.host + canonicalPath, canonicalPath
}

func (s *S3) hostFor() string {
	if s.cfg.ForcePathStyle {
		return s.host
	}
	return s.cfg.Bucket + "." + s.host
}

func (s *S3) Put(ctx context.Context, key, contentType string, r io.Reader) (*Object, error) {
	if err := ValidateKey(key); err != nil {
		return nil, err
	}
	data, sum, err := readAllLimited(r, s.cfg.MaxBytes)
	if err != nil {
		return nil, err
	}
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	resp, err := s.do(ctx, http.MethodPut, key, data, map[string]string{
		"content-type": contentType,
	})
	if err != nil {
		return nil, err
	}
	defer drain(resp)

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return nil, s3Error("yükleme", resp)
	}
	return &Object{
		Key: key, Size: int64(len(data)), ContentType: contentType,
		SHA256: sum, ModifiedAt: time.Now().UTC(),
	}, nil
}

func (s *S3) Stat(ctx context.Context, key string) (*Object, error) {
	if err := ValidateKey(key); err != nil {
		return nil, err
	}
	resp, err := s.do(ctx, http.MethodHead, key, nil, nil)
	if err != nil {
		return nil, err
	}
	defer drain(resp)

	if resp.StatusCode == http.StatusNotFound {
		return nil, ErrNotFound
	}
	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return nil, s3Error("üst veri okuma", resp)
	}
	return objectFromHeaders(key, resp), nil
}

func (s *S3) Get(ctx context.Context, key string) (io.ReadCloser, *Object, error) {
	if err := ValidateKey(key); err != nil {
		return nil, nil, err
	}
	resp, err := s.do(ctx, http.MethodGet, key, nil, nil)
	if err != nil {
		return nil, nil, err
	}
	if resp.StatusCode == http.StatusNotFound {
		drain(resp)
		return nil, nil, ErrNotFound
	}
	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		err := s3Error("indirme", resp)
		drain(resp)
		return nil, nil, err
	}
	return resp.Body, objectFromHeaders(key, resp), nil
}

func (s *S3) Delete(ctx context.Context, key string) error {
	if err := ValidateKey(key); err != nil {
		return err
	}
	resp, err := s.do(ctx, http.MethodDelete, key, nil, nil)
	if err != nil {
		return err
	}
	defer drain(resp)

	// S3 olmayan nesnenin silinmesine de 204 döner; bu idempotentlik istenen davranıştır.
	if resp.StatusCode == http.StatusNotFound {
		return nil
	}
	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return s3Error("silme", resp)
	}
	return nil
}

// do, imzalanmış bir istek gönderir.
func (s *S3) do(ctx context.Context, method, key string, body []byte, extraHeaders map[string]string) (*http.Response, error) {
	fullURL, canonicalPath := s.objectURL(key)

	var reader io.Reader
	if body != nil {
		reader = bytes.NewReader(body)
	}
	req, err := http.NewRequestWithContext(ctx, method, fullURL, reader)
	if err != nil {
		return nil, err
	}
	for k, v := range extraHeaders {
		req.Header.Set(k, v)
	}
	if body != nil {
		req.ContentLength = int64(len(body))
	}
	s.sign(req, canonicalPath, body)
	return s.client.Do(req)
}

// sign, isteği AWS Signature Version 4 ile imzalar.
//
// İmzalanan başlıklar: host, x-amz-content-sha256, x-amz-date ve (varsa)
// content-type. Yük özeti gerçek içerikten hesaplanır (UNSIGNED-PAYLOAD
// kullanılmaz) — böylece aktarım sırasında değişen bir yük imzayı bozar.
func (s *S3) sign(req *http.Request, canonicalPath string, body []byte) {
	now := time.Now().UTC()
	amzDate := now.Format("20060102T150405Z")
	dateStamp := now.Format("20060102")

	sum := sha256.Sum256(body) // body nil ise boş dizinin özeti: doğru davranış
	payloadHash := hex.EncodeToString(sum[:])

	req.Host = s.hostFor()
	req.Header.Set("X-Amz-Date", amzDate)
	req.Header.Set("X-Amz-Content-Sha256", payloadHash)

	signed := []string{"host", "x-amz-content-sha256", "x-amz-date"}
	headerValues := map[string]string{
		"host":                 s.hostFor(),
		"x-amz-content-sha256": payloadHash,
		"x-amz-date":           amzDate,
	}
	if ct := req.Header.Get("Content-Type"); ct != "" {
		signed = append(signed, "content-type")
		headerValues["content-type"] = ct
	}
	sort.Strings(signed)

	var canonicalHeaders strings.Builder
	for _, h := range signed {
		canonicalHeaders.WriteString(h)
		canonicalHeaders.WriteString(":")
		canonicalHeaders.WriteString(strings.TrimSpace(headerValues[h]))
		canonicalHeaders.WriteString("\n")
	}
	signedHeaders := strings.Join(signed, ";")

	canonicalRequest := strings.Join([]string{
		req.Method,
		canonicalPath,
		"", // sorgu dizesi kullanılmıyor
		canonicalHeaders.String(),
		signedHeaders,
		payloadHash,
	}, "\n")

	crSum := sha256.Sum256([]byte(canonicalRequest))
	scope := strings.Join([]string{dateStamp, s.cfg.Region, "s3", "aws4_request"}, "/")
	stringToSign := strings.Join([]string{
		"AWS4-HMAC-SHA256", amzDate, scope, hex.EncodeToString(crSum[:]),
	}, "\n")

	kDate := hmacSHA256([]byte("AWS4"+s.cfg.SecretKey), dateStamp)
	kRegion := hmacSHA256(kDate, s.cfg.Region)
	kService := hmacSHA256(kRegion, "s3")
	kSigning := hmacSHA256(kService, "aws4_request")
	signature := hex.EncodeToString(hmacSHA256(kSigning, stringToSign))

	req.Header.Set("Authorization", fmt.Sprintf(
		"AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s",
		s.cfg.AccessKeyID, scope, signedHeaders, signature))
}

func hmacSHA256(key []byte, data string) []byte {
	h := hmac.New(sha256.New, key)
	h.Write([]byte(data))
	return h.Sum(nil)
}

// escapePath, anahtarı S3'ün beklediği biçimde kodlar.
// Eğik çizgiler korunur (dizin benzeri anahtarlar), diğer karakterler yüzdelenir.
func escapePath(key string) string {
	parts := strings.Split(key, "/")
	for i, p := range parts {
		parts[i] = strings.ReplaceAll(url.QueryEscape(p), "+", "%20")
	}
	return strings.Join(parts, "/")
}

func objectFromHeaders(key string, resp *http.Response) *Object {
	size, _ := strconv.ParseInt(resp.Header.Get("Content-Length"), 10, 64)
	ct := resp.Header.Get("Content-Type")
	if ct == "" {
		ct = "application/octet-stream"
	}
	modified, _ := http.ParseTime(resp.Header.Get("Last-Modified"))
	return &Object{
		Key: key, Size: size, ContentType: ct,
		SHA256:     resp.Header.Get("X-Amz-Meta-Sha256"),
		ModifiedAt: modified.UTC(),
	}
}

// s3Error, sağlayıcının hata gövdesini KISALTARAK hataya çevirir.
// Gövdenin tamamını loglamak, imzalı URL ya da anahtar sızdırabilir.
func s3Error(op string, resp *http.Response) error {
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
	msg := strings.TrimSpace(string(body))
	if len(msg) > 200 {
		msg = msg[:200]
	}
	return fmt.Errorf("S3 %s başarısız (HTTP %d): %s", op, resp.StatusCode, msg)
}

func drain(resp *http.Response) {
	if resp == nil || resp.Body == nil {
		return
	}
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	_ = resp.Body.Close()
}

var _ Store = (*S3)(nil)
