package dbscope

// Veritabanı gerektiren kapsam testleri. DBSCOPE_TEST_DSN tanımlı değilse atlanır;
// verify-stack bunları gerçek PostgreSQL'e karşı çalıştırır (FAZ M1.6).

import (
	"context"
	"errors"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

func testPool(t *testing.T) *pgxpool.Pool {
	dsn := os.Getenv("DBSCOPE_TEST_DSN")
	if dsn == "" {
		t.Skip("DBSCOPE_TEST_DSN tanımlı değil")
	}
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		t.Fatal(err)
	}
	cfg.MaxConns = 1 // aynı bağlantının yeniden kullanıldığı kesin olsun
	pool, err := pgxpool.NewWithConfig(context.Background(), cfg)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func TestScopesRefuseEmptyID(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	var v string
	if err := ForSupplier(pool, "").QueryRow(ctx, `SELECT 1`).Scan(&v); !errors.Is(err, ErrNoSupplier) {
		t.Fatalf("boş tedarikçi kimliği: %v", err)
	}
	if err := ForPlatform(pool, "").QueryRow(ctx, `SELECT 1`).Scan(&v); !errors.Is(err, ErrNoPlatform) {
		t.Fatalf("boş platform kimliği: %v", err)
	}
	if _, err := For(pool, "").Exec(ctx, `SELECT 1`); !errors.Is(err, ErrNoProperty) {
		t.Fatalf("boş site kimliği: %v", err)
	}
}

func TestScopeSettingDoesNotLeak(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	const acc = "6f1c2c1e-1111-4a4a-9b9b-000000000001"
	for _, c := range []struct {
		s       *Scoped
		setting string
	}{{ForSupplier(pool, acc), SupplierSettingName}, {ForPlatform(pool, acc), PlatformSettingName}, {For(pool, acc), SettingName}} {
		var inside, after string
		if err := c.s.QueryRow(ctx, `SELECT current_setting($1, true)`, c.setting).Scan(&inside); err != nil {
			t.Fatal(err)
		}
		if inside != acc {
			t.Fatalf("%s kapsam içinde %q, beklenen %q", c.setting, inside, acc)
		}
		if err := pool.QueryRow(ctx, `SELECT COALESCE(current_setting($1, true), '')`, c.setting).Scan(&after); err != nil {
			t.Fatal(err)
		}
		if after != "" {
			t.Fatalf("%s transaction dışına sızdı: %q", c.setting, after)
		}
	}
}
