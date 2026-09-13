package storage

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestValidateKeyRejectsTraversal(t *testing.T) {
	bad := []string{
		"", "/mutlak/yol", "../ustdizin", "a/../../b", "a//b",
		"a\\b", "a/./b", strings.Repeat("x", 1025), "a\x00b",
	}
	for _, k := range bad {
		if err := ValidateKey(k); err == nil {
			t.Errorf("ValidateKey(%q) hata döndürmedi; dizin dışına çıkma riski", k)
		}
	}
	good := []string{
		"a", "site/11111111/belge.pdf", "2026/09/fatura-1.png", "a-b_c.d",
	}
	for _, k := range good {
		if err := ValidateKey(k); err != nil {
			t.Errorf("ValidateKey(%q) beklenmedik hata: %v", k, err)
		}
	}
}

func TestLocalPutGetStatDelete(t *testing.T) {
	ctx := context.Background()
	st, err := NewLocal(t.TempDir(), DefaultMaxBytes)
	if err != nil {
		t.Fatal(err)
	}

	content := []byte("kat malikleri kurulu karar ornegi")
	want := sha256.Sum256(content)
	wantHex := hex.EncodeToString(want[:])

	obj, err := st.Put(ctx, "site/a/karar.txt", "text/plain", bytes.NewReader(content))
	if err != nil {
		t.Fatal(err)
	}
	if obj.SHA256 != wantHex {
		t.Fatalf("özet yanlış: %s != %s", obj.SHA256, wantHex)
	}
	if obj.Size != int64(len(content)) {
		t.Fatalf("boyut yanlış: %d", obj.Size)
	}

	meta, err := st.Stat(ctx, "site/a/karar.txt")
	if err != nil {
		t.Fatal(err)
	}
	if meta.ContentType != "text/plain" || meta.SHA256 != wantHex {
		t.Fatalf("Stat üst verisi yanlış: %+v", meta)
	}

	rc, _, err := st.Get(ctx, "site/a/karar.txt")
	if err != nil {
		t.Fatal(err)
	}
	got, _ := io.ReadAll(rc)
	rc.Close()
	if !bytes.Equal(got, content) {
		t.Fatalf("içerik değişti: %q", got)
	}

	if err := st.Delete(ctx, "site/a/karar.txt"); err != nil {
		t.Fatal(err)
	}
	if _, err := st.Stat(ctx, "site/a/karar.txt"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("silinen dosya için ErrNotFound bekleniyordu, gelen: %v", err)
	}
	// Silme idempotent olmalı
	if err := st.Delete(ctx, "site/a/karar.txt"); err != nil {
		t.Fatalf("ikinci silme hata verdi: %v", err)
	}
}

func TestLocalRejectsTraversalOnPut(t *testing.T) {
	st, _ := NewLocal(t.TempDir(), DefaultMaxBytes)
	_, err := st.Put(context.Background(), "../disari.txt", "text/plain", strings.NewReader("x"))
	if !errors.Is(err, ErrInvalidKey) {
		t.Fatalf("kök dizin dışına yazma engellenmedi: %v", err)
	}
}

func TestLocalEnforcesMaxBytes(t *testing.T) {
	st, _ := NewLocal(t.TempDir(), 10)
	_, err := st.Put(context.Background(), "buyuk.bin", "", strings.NewReader("0123456789AB"))
	if !errors.Is(err, ErrTooLarge) {
		t.Fatalf("boyut sınırı uygulanmadı: %v", err)
	}
	// Tam sınırdaki dosya kabul edilmeli
	if _, err := st.Put(context.Background(), "tam.bin", "", strings.NewReader("0123456789")); err != nil {
		t.Fatalf("sınırdaki dosya reddedildi: %v", err)
	}
}

func TestFromEnvFailsClosed(t *testing.T) {
	t.Setenv("STORAGE_BACKEND", "")
	if _, err := FromEnv(); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("yapılandırma yokken sessizce varsayılana düşüldü: %v", err)
	}

	t.Setenv("STORAGE_BACKEND", "local")
	t.Setenv("STORAGE_LOCAL_DIR", "")
	if _, err := FromEnv(); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("STORAGE_LOCAL_DIR yokken hata bekleniyordu: %v", err)
	}

	t.Setenv("STORAGE_BACKEND", "s3")
	t.Setenv("S3_BUCKET", "")
	if _, err := FromEnv(); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("S3 ayarları eksikken hata bekleniyordu: %v", err)
	}

	t.Setenv("STORAGE_BACKEND", "uydurma")
	if _, err := FromEnv(); !errors.Is(err, ErrNotConfigured) {
		t.Fatalf("bilinmeyen sağlayıcı kabul edildi: %v", err)
	}
}

// TestS3SignsAndUploads, S3 uyumlu bir sunucuyu taklit ederek imzanın
// üretildiğini, yolun doğru kurulduğunu ve gövdenin bozulmadan gittiğini sınar.
func TestS3SignsAndUploads(t *testing.T) {
	var gotAuth, gotPath, gotPayloadHash, gotBody, gotDate string

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		gotAuth = r.Header.Get("Authorization")
		gotPath = r.URL.Path
		gotPayloadHash = r.Header.Get("X-Amz-Content-Sha256")
		gotDate = r.Header.Get("X-Amz-Date")
		gotBody = string(body)
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	st, err := NewS3(S3Config{
		Bucket: "siteeksen", Region: "eu-central-1",
		Endpoint: srv.URL, AccessKeyID: "AKIATEST", SecretKey: "gizli",
		ForcePathStyle: true, HTTPClient: srv.Client(),
	})
	if err != nil {
		t.Fatal(err)
	}

	content := "isletme projesi 2026"
	obj, err := st.Put(context.Background(), "site/x/proje.pdf", "application/pdf",
		strings.NewReader(content))
	if err != nil {
		t.Fatal(err)
	}

	if gotBody != content {
		t.Fatalf("gövde bozuldu: %q", gotBody)
	}
	if gotPath != "/siteeksen/site/x/proje.pdf" {
		t.Fatalf("yol yanlış kuruldu: %s", gotPath)
	}
	want := sha256.Sum256([]byte(content))
	if gotPayloadHash != hex.EncodeToString(want[:]) {
		t.Fatalf("yük özeti yanlış: %s", gotPayloadHash)
	}
	if obj.SHA256 != hex.EncodeToString(want[:]) {
		t.Fatalf("dönen özet yanlış: %s", obj.SHA256)
	}
	if gotDate == "" {
		t.Fatal("X-Amz-Date gönderilmedi")
	}
	for _, part := range []string{
		"AWS4-HMAC-SHA256", "Credential=AKIATEST/", "/eu-central-1/s3/aws4_request",
		"SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date", "Signature=",
	} {
		if !strings.Contains(gotAuth, part) {
			t.Fatalf("Authorization başlığında %q yok: %s", part, gotAuth)
		}
	}
	// İmzanın gizli anahtarı sızdırmadığı
	if strings.Contains(gotAuth, "gizli") {
		t.Fatal("Authorization başlığı gizli anahtarı içeriyor")
	}
}

func TestS3NotFoundAndIdempotentDelete(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusNotFound)
	}))
	defer srv.Close()

	st, _ := NewS3(S3Config{
		Bucket: "b", Region: "r", Endpoint: srv.URL,
		AccessKeyID: "k", SecretKey: "s", ForcePathStyle: true, HTTPClient: srv.Client(),
	})

	if _, err := st.Stat(context.Background(), "yok.txt"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("404 ErrNotFound'a çevrilmedi: %v", err)
	}
	if _, _, err := st.Get(context.Background(), "yok.txt"); !errors.Is(err, ErrNotFound) {
		t.Fatalf("Get 404 ErrNotFound'a çevrilmedi: %v", err)
	}
	if err := st.Delete(context.Background(), "yok.txt"); err != nil {
		t.Fatalf("olmayan dosyanın silinmesi hata verdi: %v", err)
	}
}

func TestS3DescribeHidesSecret(t *testing.T) {
	st, _ := NewS3(S3Config{
		Bucket: "b", Region: "r", Endpoint: "https://ornek.example",
		AccessKeyID: "AKIA-GIZLI", SecretKey: "COK-GIZLI", ForcePathStyle: true,
	})
	for k, v := range st.Describe() {
		if strings.Contains(v, "COK-GIZLI") || strings.Contains(v, "AKIA-GIZLI") {
			t.Fatalf("Describe() sır sızdırıyor: %s=%s", k, v)
		}
	}
}
