package audit_test

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/audit"
)

// Bu test GERÇEK bir PostgreSQL'e karşı çalışır ve `pkg/audit`'in yazdığı kolonların
// migration şemasıyla uyumlu olduğunu doğrular.
//
// Neden gerekli: 2026-09-09 denetiminde, `audit.LogAction`'ın şemada BULUNMAYAN kolon
// adlarına (`user_ip`, `resource_type`, `resource_id`) yazdığı ve INSERT'in her çağrıda
// `42703 undefined_column` hatası verdiği tespit edildi. Hata çağıran tarafta `_ =` ile
// yutulduğu için `audit_logs` tablosu aylarca boş kaldı ve kimse fark etmedi.
// Böyle bir hatayı derleyici yakalayamaz — yalnızca gerçek veritabanına yazan bir test yakalar.
//
// Çalıştırmak için (WSL):
//
//	docker run --rm -d --name audit-test -e POSTGRES_PASSWORD=testpw -e POSTGRES_USER=siteeksen \
//	  -e POSTGRES_DB=siteeksen -p 55432:5432 postgres:16
//	for f in backend/migrations/*.sql; do psql -h 127.0.0.1 -p 55432 -U siteeksen -d siteeksen -f "$f"; done
//	TEST_DATABASE_URL='postgres://siteeksen:testpw@127.0.0.1:55432/siteeksen' go test ./pkg/audit/...
//
// TEST_DATABASE_URL tanımlı değilse test atlanır (CI'da veritabanı yoksa kırmızı olmasın diye).
func TestLogWritesRow(t *testing.T) {
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL tanımlı değil — veritabanı gerektiren test atlandı")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("veritabanına bağlanılamadı: %v", err)
	}
	defer pool.Close()

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("veritabanı ping başarısız: %v", err)
	}

	// Testin kendi kaydını ayırt edebilmesi için benzersiz bir entity_type kullanılır.
	entityType := "audit_test_" + time.Now().Format("20060102150405.000000000")

	entry := audit.Entry{
		UserID:     "", // NULL yazılmalı — geçersiz UUID hatası vermemeli
		PropertyID: "",
		IPAddress:  "203.0.113.10",
		UserAgent:  "go-test",
		Action:     "VIEW",
		EntityType: entityType,
		EntityID:   "", // NULL yazılmalı
		RequestID:  "req-test-1",
		StatusCode: 200,
		OldValues:  nil,
		NewValues:  map[string]any{"alan": "değer"},
	}

	if err := audit.Log(ctx, pool, entry); err != nil {
		t.Fatalf("audit.Log hata döndürdü (kolon adları şemayla uyuşmuyor olabilir): %v", err)
	}

	var (
		count      int
		action     string
		ip         string
		requestID  string
		statusCode int
	)
	// host() kullanılır: `inet::text` dönüşümü ağ maskesini de ekler ("203.0.113.10/32"),
	// host() ise yalnızca adresi döndürür.
	err = pool.QueryRow(ctx, `
		SELECT count(*) OVER (), action, host(ip_address), request_id, status_code
		FROM audit_logs
		WHERE entity_type = $1
		LIMIT 1
	`, entityType).Scan(&count, &action, &ip, &requestID, &statusCode)
	if err != nil {
		t.Fatalf("yazılan denetim kaydı okunamadı: %v", err)
	}

	if count != 1 {
		t.Errorf("beklenen kayıt sayısı 1, bulunan %d", count)
	}
	if action != "VIEW" {
		t.Errorf("action beklenen %q, bulunan %q", "VIEW", action)
	}
	if ip != "203.0.113.10" {
		t.Errorf("ip_address beklenen %q, bulunan %q", "203.0.113.10", ip)
	}
	if requestID != "req-test-1" {
		t.Errorf("request_id beklenen %q, bulunan %q", "req-test-1", requestID)
	}
	if statusCode != 200 {
		t.Errorf("status_code beklenen 200, bulunan %d", statusCode)
	}

	// Temizlik
	if _, err := pool.Exec(ctx, `DELETE FROM audit_logs WHERE entity_type = $1`, entityType); err != nil {
		t.Logf("uyarı: test kaydı temizlenemedi: %v", err)
	}
}

// Boş string olarak verilen kimliklerin NULL yazıldığını ve UUID cast hatası üretmediğini doğrular.
func TestLogWithEmptyIdentifiers(t *testing.T) {
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL tanımlı değil — veritabanı gerektiren test atlandı")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		t.Fatalf("veritabanına bağlanılamadı: %v", err)
	}
	defer pool.Close()

	entityType := "audit_test_null_" + time.Now().Format("20060102150405.000000000")

	err = audit.Log(ctx, pool, audit.Entry{
		Action:     "DENIED",
		EntityType: entityType,
		StatusCode: 403,
	})
	if err != nil {
		t.Fatalf("boş kimliklerle audit.Log başarısız: %v", err)
	}

	var userIDNull, propertyIDNull, entityIDNull bool
	err = pool.QueryRow(ctx, `
		SELECT user_id IS NULL, property_id IS NULL, entity_id IS NULL
		FROM audit_logs WHERE entity_type = $1 LIMIT 1
	`, entityType).Scan(&userIDNull, &propertyIDNull, &entityIDNull)
	if err != nil {
		t.Fatalf("kayıt okunamadı: %v", err)
	}

	if !userIDNull || !propertyIDNull || !entityIDNull {
		t.Errorf("boş string kimlikler NULL yazılmalıydı (user=%v property=%v entity=%v)",
			userIDNull, propertyIDNull, entityIDNull)
	}

	if _, err := pool.Exec(ctx, `DELETE FROM audit_logs WHERE entity_type = $1`, entityType); err != nil {
		t.Logf("uyarı: test kaydı temizlenemedi: %v", err)
	}
}
