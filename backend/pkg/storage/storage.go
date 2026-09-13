// Package storage, dosya (belge, fotoğraf, fatura görüntüsü) saklamak için
// sağlayıcıdan bağımsız bir arayüz sunar.
//
// Neden var (S-09): projede dosya saklama hiç yoktu; belge/fatura/imza uçları
// "yüklendi" diyip hiçbir şey saklamıyordu. Bu paket tek bir sözleşme tanımlar;
// altına Oracle Object Storage, Cloudflare R2 ve AWS S3 (hepsi S3 uyumlu) ya da
// geliştirme için yerel dosya sistemi takılabilir.
//
// Tasarım kararları:
//   - Yapılandırma eksikse SESSİZCE varsayılana düşülmez; ErrNotConfigured döner.
//     Sessiz varsayılan, üretimde dosyaların yanlış yere yazılması demektir.
//   - Her yükleme SHA-256 özeti ile birlikte döner. Belgenin sonradan değişip
//     değişmediği bu özetle kanıtlanır (defter zinciriyle aynı yaklaşım).
//   - Anahtar (key) doğrulanır: `..`, mutlak yol ve ters eğik çizgi kabul edilmez;
//     aksi hâlde bir site başka sitenin dosyalarının üzerine yazabilir.
package storage

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"time"
)

var (
	// ErrNotConfigured, depolama yapılandırması eksik olduğunda döner.
	ErrNotConfigured = errors.New("dosya depolama yapılandırılmamış")
	// ErrNotFound, istenen nesne bulunamadığında döner.
	ErrNotFound = errors.New("dosya bulunamadı")
	// ErrInvalidKey, anahtar güvenlik kurallarına uymadığında döner.
	ErrInvalidKey = errors.New("geçersiz dosya anahtarı")
	// ErrTooLarge, dosya izin verilen boyutu aştığında döner.
	ErrTooLarge = errors.New("dosya izin verilen boyutu aşıyor")
)

// DefaultMaxBytes, tek bir dosyanın azami boyutudur (25 MiB).
// STORAGE_MAX_BYTES ile değiştirilebilir.
const DefaultMaxBytes int64 = 25 << 20

// Object, saklanan bir dosyanın üst verisidir.
type Object struct {
	Key         string    `json:"key"`
	Size        int64     `json:"size"`
	ContentType string    `json:"content_type"`
	SHA256      string    `json:"sha256"`
	ModifiedAt  time.Time `json:"modified_at"`
}

// Store, dosya saklama sözleşmesidir.
type Store interface {
	// Put, veriyi key altına yazar ve üst verisini döner.
	Put(ctx context.Context, key, contentType string, r io.Reader) (*Object, error)
	// Get, dosyayı okur. Çağıran ReadCloser'ı kapatmakla yükümlüdür.
	Get(ctx context.Context, key string) (io.ReadCloser, *Object, error)
	// Stat, dosyayı indirmeden üst verisini verir.
	Stat(ctx context.Context, key string) (*Object, error)
	// Delete, dosyayı siler. Olmayan dosyada hata dönmez (idempotent).
	Delete(ctx context.Context, key string) error
	// Backend, hangi sağlayıcının kullanıldığını söyler ("local", "s3").
	Backend() string
	// Describe, yapılandırmayı SIR İÇERMEDEN özetler (sağlık ucu için).
	Describe() map[string]string
}

// FromEnv, ortam değişkenlerinden bir Store kurar.
//
//	STORAGE_BACKEND=local  → STORAGE_LOCAL_DIR (zorunlu)
//	STORAGE_BACKEND=s3     → S3_BUCKET, S3_REGION, S3_ACCESS_KEY_ID,
//	                         S3_SECRET_ACCESS_KEY (zorunlu)
//	                         S3_ENDPOINT (Oracle/R2 için zorunlu, AWS'de boş bırakılabilir)
//	                         S3_FORCE_PATH_STYLE=true|false
//	STORAGE_MAX_BYTES      → azami dosya boyutu (bayt)
func FromEnv() (Store, error) {
	backend := strings.ToLower(strings.TrimSpace(os.Getenv("STORAGE_BACKEND")))
	maxBytes := DefaultMaxBytes
	if v := os.Getenv("STORAGE_MAX_BYTES"); v != "" {
		n, err := strconv.ParseInt(v, 10, 64)
		if err != nil || n <= 0 {
			return nil, fmt.Errorf("STORAGE_MAX_BYTES geçersiz: %q", v)
		}
		maxBytes = n
	}

	switch backend {
	case "local":
		dir := strings.TrimSpace(os.Getenv("STORAGE_LOCAL_DIR"))
		if dir == "" {
			return nil, fmt.Errorf("%w: STORAGE_BACKEND=local için STORAGE_LOCAL_DIR gerekli", ErrNotConfigured)
		}
		return NewLocal(dir, maxBytes)
	case "s3":
		return NewS3(S3Config{
			Bucket:         os.Getenv("S3_BUCKET"),
			Region:         os.Getenv("S3_REGION"),
			Endpoint:       os.Getenv("S3_ENDPOINT"),
			AccessKeyID:    os.Getenv("S3_ACCESS_KEY_ID"),
			SecretKey:      os.Getenv("S3_SECRET_ACCESS_KEY"),
			ForcePathStyle: os.Getenv("S3_FORCE_PATH_STYLE") != "false",
			MaxBytes:       maxBytes,
		})
	case "":
		return nil, fmt.Errorf("%w: STORAGE_BACKEND belirtilmeli (local|s3)", ErrNotConfigured)
	default:
		return nil, fmt.Errorf("%w: bilinmeyen STORAGE_BACKEND=%q (local|s3)", ErrNotConfigured, backend)
	}
}

// ValidateKey, dosya anahtarının güvenli olduğunu doğrular.
//
// Kabul edilmeyenler: boş, `/` ile başlayan, `..` parçası içeren, ters eğik
// çizgi ya da denetim karakteri içeren, 1024 bayttan uzun anahtarlar.
// Bunlar dizin dışına çıkma (path traversal) saldırısının klasik yollarıdır.
func ValidateKey(key string) error {
	if key == "" || len(key) > 1024 {
		return ErrInvalidKey
	}
	if strings.HasPrefix(key, "/") || strings.Contains(key, "\\") {
		return ErrInvalidKey
	}
	for _, part := range strings.Split(key, "/") {
		if part == "" || part == "." || part == ".." {
			return ErrInvalidKey
		}
	}
	for _, r := range key {
		if r < 0x20 || r == 0x7f {
			return ErrInvalidKey
		}
	}
	return nil
}

// readAllLimited, veriyi bellekte toplar ve SHA-256 özetini hesaplar.
//
// Tamponlama bilinçli bir tercihtir: hem imzalama (S3 SigV4) hem de bütünlük
// özeti için içeriğin tamamı gerekir. Sınır aşılırsa ErrTooLarge döner —
// sınırsız okuma, tek bir istekle sunucunun belleğini tüketmeye açık kapı bırakır.
func readAllLimited(r io.Reader, maxBytes int64) ([]byte, string, error) {
	buf, err := io.ReadAll(io.LimitReader(r, maxBytes+1))
	if err != nil {
		return nil, "", err
	}
	if int64(len(buf)) > maxBytes {
		return nil, "", ErrTooLarge
	}
	sum := sha256.Sum256(buf)
	return buf, hex.EncodeToString(sum[:]), nil
}
