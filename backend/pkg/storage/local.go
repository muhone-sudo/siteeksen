package storage

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Local, dosyaları yerel dosya sisteminde saklar.
//
// Geliştirme ve tek sunuculu kurulumlar içindir. Çok sunuculu üretimde S3 uyumlu
// bir sağlayıcı kullanılmalıdır; aksi hâlde dosya bir sunucuda yazılır, diğerinde
// bulunamaz. Bu uyarı Describe() ile sağlık ucunda da görünür.
type Local struct {
	dir      string
	maxBytes int64
}

// NewLocal, kök dizini hazırlar.
func NewLocal(dir string, maxBytes int64) (*Local, error) {
	abs, err := filepath.Abs(dir)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(abs, 0o750); err != nil {
		return nil, err
	}
	return &Local{dir: abs, maxBytes: maxBytes}, nil
}

func (l *Local) Backend() string { return "local" }

func (l *Local) Describe() map[string]string {
	return map[string]string{
		"backend":   "local",
		"dir":       l.dir,
		"max_bytes": strconv.FormatInt(l.maxBytes, 10),
		"warning": "Yerel dosya sistemi yalnızca tek sunuculu kurulum içindir; " +
			"birden çok kopya çalıştırıldığında dosyalar paylaşılmaz.",
	}
}

// path, anahtarı doğrulayıp kök dizin altındaki mutlak yola çevirir.
func (l *Local) path(key string) (string, error) {
	if err := ValidateKey(key); err != nil {
		return "", err
	}
	full := filepath.Join(l.dir, filepath.FromSlash(key))
	// ValidateKey yeterli olmalı; yine de kök dizin dışına çıkılmadığı
	// son bir kez doğrulanır (savunma katmanı).
	if !strings.HasPrefix(full, l.dir+string(os.PathSeparator)) {
		return "", ErrInvalidKey
	}
	return full, nil
}

// meta, üst verinin yazıldığı yan dosyadır (içerik türü ve özet).
func metaPath(full string) string { return full + ".meta.json" }

type localMeta struct {
	ContentType string `json:"content_type"`
	SHA256      string `json:"sha256"`
}

func (l *Local) Put(_ context.Context, key, contentType string, r io.Reader) (*Object, error) {
	full, err := l.path(key)
	if err != nil {
		return nil, err
	}
	data, sum, err := readAllLimited(r, l.maxBytes)
	if err != nil {
		return nil, err
	}
	if err := os.MkdirAll(filepath.Dir(full), 0o750); err != nil {
		return nil, err
	}

	// Önce geçici dosyaya yazılır, sonra taşınır: yazma yarıda kesilirse
	// yarım bir dosya "yüklendi" görünmez.
	tmp, err := os.CreateTemp(filepath.Dir(full), ".upload-*")
	if err != nil {
		return nil, err
	}
	tmpName := tmp.Name()
	defer os.Remove(tmpName) //nolint:errcheck

	if _, err := tmp.Write(data); err != nil {
		tmp.Close() //nolint:errcheck,gosec
		return nil, err
	}
	if err := tmp.Close(); err != nil {
		return nil, err
	}
	if err := os.Chmod(tmpName, 0o640); err != nil {
		return nil, err
	}
	if err := os.Rename(tmpName, full); err != nil {
		return nil, err
	}

	if contentType == "" {
		contentType = "application/octet-stream"
	}
	metaJSON, err := json.Marshal(localMeta{ContentType: contentType, SHA256: sum})
	if err != nil {
		return nil, err
	}
	if err := os.WriteFile(metaPath(full), metaJSON, 0o640); err != nil {
		return nil, err
	}

	return &Object{
		Key: key, Size: int64(len(data)), ContentType: contentType,
		SHA256: sum, ModifiedAt: time.Now().UTC(),
	}, nil
}

func (l *Local) Stat(_ context.Context, key string) (*Object, error) {
	full, err := l.path(key)
	if err != nil {
		return nil, err
	}
	fi, err := os.Stat(full)
	if errors.Is(err, os.ErrNotExist) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	var m localMeta
	if b, err := os.ReadFile(metaPath(full)); err == nil {
		_ = json.Unmarshal(b, &m)
	}
	if m.ContentType == "" {
		m.ContentType = "application/octet-stream"
	}
	return &Object{
		Key: key, Size: fi.Size(), ContentType: m.ContentType,
		SHA256: m.SHA256, ModifiedAt: fi.ModTime().UTC(),
	}, nil
}

func (l *Local) Get(ctx context.Context, key string) (io.ReadCloser, *Object, error) {
	obj, err := l.Stat(ctx, key)
	if err != nil {
		return nil, nil, err
	}
	full, err := l.path(key)
	if err != nil {
		return nil, nil, err
	}
	f, err := os.Open(full) //nolint:gosec // yol ValidateKey + path ile doğrulandı
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil, ErrNotFound
	}
	if err != nil {
		return nil, nil, err
	}
	return f, obj, nil
}

func (l *Local) Delete(_ context.Context, key string) error {
	full, err := l.path(key)
	if err != nil {
		return err
	}
	if err := os.Remove(full); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	if err := os.Remove(metaPath(full)); err != nil && !errors.Is(err, os.ErrNotExist) {
		return err
	}
	return nil
}

// ensure interface compliance at compile time
var _ Store = (*Local)(nil)
