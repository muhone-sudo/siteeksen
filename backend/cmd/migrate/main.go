// migrate — SiteEksen veritabanı migration çalıştırıcısı.
//
// NEDEN VAR:
// Proje bugüne kadar migration'ları "elle uygula" yöntemiyle yönetiyordu. Sonuçları:
//   - hangi migration'ın uygulandığı hiçbir yerde tutulmuyordu,
//   - iki kişi/iki süreç aynı anda uygularsa yarış durumu oluşuyordu,
//   - uygulanmış bir migration dosyası sonradan değiştirildiğinde kimse fark etmiyordu,
//   - bir migration yarıda kalırsa şema tanımsız bir durumda kalıyordu.
//
// Bu araç dördünü de çözer:
//  1. `schema_migrations` tablosu — hangi sürüm, ne zaman, hangi sürede uygulandı.
//  2. PostgreSQL advisory lock — aynı anda yalnızca bir çalıştırıcı ilerler.
//  3. SHA-256 sağlama — uygulanmış bir dosya değişmişse çalıştırıcı DURUR.
//  4. Migration başına transaction — ya tamamı uygulanır ya hiçbiri.
//
// KULLANIM:
//
//	go run ./cmd/migrate            # eksik migration'ları uygula
//	go run ./cmd/migrate -status    # durum tablosunu yazdır, hiçbir şey uygulama
//	go run ./cmd/migrate -dry-run   # ne uygulanacağını göster, uygulama
//	go run ./cmd/migrate -dir path  # migration dizinini değiştir
//
// Bağlantı bilgileri DATABASE_URL veya DB_HOST/DB_PORT/DB_USER/DB_PASSWORD/DB_NAME
// ortam değişkenlerinden okunur.
package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// advisoryLockKey — bu projeye özgü sabit. Aynı veritabanında iki çalıştırıcının
// eşzamanlı ilerlemesini engeller.
const advisoryLockKey int64 = 8_243_119_007

// migrationFilePattern — `001_initial_schema.sql` biçimi zorunludur.
var migrationFilePattern = regexp.MustCompile(`^(\d+)_([A-Za-z0-9_\-]+)\.sql$`)

type migration struct {
	Version  int
	Name     string
	Path     string
	Checksum string
	SQL      string
}

type appliedRecord struct {
	Version    int
	Name       string
	Checksum   string
	AppliedAt  time.Time
	DurationMS int64
}

func main() {
	var (
		dir     = flag.String("dir", defaultMigrationsDir(), "migration dosyalarının bulunduğu dizin")
		status  = flag.Bool("status", false, "yalnızca durum yazdır")
		dryRun  = flag.Bool("dry-run", false, "uygulanacakları göster, uygulama")
		timeout = flag.Duration("timeout", 10*time.Minute, "toplam süre sınırı")
	)
	flag.Parse()

	ctx, cancel := context.WithTimeout(context.Background(), *timeout)
	defer cancel()

	if err := run(ctx, *dir, *status, *dryRun); err != nil {
		fmt.Fprintf(os.Stderr, "HATA: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, dir string, statusOnly, dryRun bool) error {
	files, err := loadMigrations(dir)
	if err != nil {
		return err
	}
	if len(files) == 0 {
		return fmt.Errorf("%s içinde migration bulunamadı", dir)
	}

	pool, err := connect(ctx)
	if err != nil {
		return err
	}
	defer pool.Close()

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("bağlantı alınamadı: %w", err)
	}
	defer conn.Release()

	if err := ensureMigrationsTable(ctx, conn.Conn()); err != nil {
		return err
	}

	applied, err := loadApplied(ctx, conn.Conn())
	if err != nil {
		return err
	}

	// Uygulanmış dosyalar sonradan değiştirilmiş mi?
	if err := verifyChecksums(files, applied); err != nil {
		return err
	}

	pending := make([]migration, 0, len(files))
	for _, m := range files {
		if _, ok := applied[m.Version]; !ok {
			pending = append(pending, m)
		}
	}

	if statusOnly {
		printStatus(files, applied, pending)
		return nil
	}

	if len(pending) == 0 {
		fmt.Println("Veritabanı güncel — uygulanacak migration yok.")
		return nil
	}

	if dryRun {
		fmt.Printf("Uygulanacak %d migration (dry-run, hiçbir şey yazılmadı):\n", len(pending))
		for _, m := range pending {
			fmt.Printf("  %03d  %s\n", m.Version, m.Name)
		}
		return nil
	}

	// Advisory lock: aynı anda yalnızca bir çalıştırıcı.
	var locked bool
	if err := conn.QueryRow(ctx, "SELECT pg_try_advisory_lock($1)", advisoryLockKey).Scan(&locked); err != nil {
		return fmt.Errorf("kilit alınamadı: %w", err)
	}
	if !locked {
		return errors.New("başka bir migration çalıştırıcısı devrede (advisory lock alınamadı)")
	}
	defer func() {
		_, _ = conn.Exec(context.Background(), "SELECT pg_advisory_unlock($1)", advisoryLockKey)
	}()

	for _, m := range pending {
		if err := apply(ctx, conn.Conn(), m); err != nil {
			return fmt.Errorf("%03d_%s başarısız: %w", m.Version, m.Name, err)
		}
	}

	fmt.Printf("%d migration uygulandı.\n", len(pending))
	return nil
}

func apply(ctx context.Context, conn *pgx.Conn, m migration) error {
	start := time.Now()

	tx, err := conn.Begin(ctx)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	// Demo veri anahtarı: seed migration'ı bu ayara bakar.
	// Üretimde SEED_DEMO_DATA=false verilir; migration yine uygulanmış sayılır
	// (sürüm zinciri kırılmaz) ama bilinen şifreli demo hesaplar AÇILMAZ.
	if _, err := tx.Exec(ctx, "SELECT set_config('siteeksen.seed_demo_data', $1, true)", seedFlag()); err != nil {
		return fmt.Errorf("seed ayarı verilemedi: %w", err)
	}

	if _, err := tx.Exec(ctx, m.SQL); err != nil {
		return err
	}

	dur := time.Since(start)
	_, err = tx.Exec(ctx,
		`INSERT INTO schema_migrations (version, name, checksum, applied_at, duration_ms)
		 VALUES ($1, $2, $3, now(), $4)`,
		m.Version, m.Name, m.Checksum, dur.Milliseconds())
	if err != nil {
		return err
	}

	if err := tx.Commit(ctx); err != nil {
		return err
	}

	fmt.Printf("  uygulandı: %03d_%s (%s)\n", m.Version, m.Name, dur.Round(time.Millisecond))
	return nil
}

// seedFlag — demo verisinin yüklenip yüklenmeyeceği.
// Varsayılan "true" (geliştirme kolaylığı); üretim ortamı SEED_DEMO_DATA=false vermelidir.
func seedFlag() string {
	switch os.Getenv("SEED_DEMO_DATA") {
	case "false", "0", "no":
		return "false"
	default:
		return "true"
	}
}

func ensureMigrationsTable(ctx context.Context, conn *pgx.Conn) error {
	_, err := conn.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version     INTEGER PRIMARY KEY,
			name        TEXT        NOT NULL,
			checksum    TEXT        NOT NULL,
			applied_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
			duration_ms BIGINT      NOT NULL DEFAULT 0
		)`)
	if err != nil {
		return fmt.Errorf("schema_migrations oluşturulamadı: %w", err)
	}
	return nil
}

func loadApplied(ctx context.Context, conn *pgx.Conn) (map[int]appliedRecord, error) {
	rows, err := conn.Query(ctx,
		`SELECT version, name, checksum, applied_at, duration_ms FROM schema_migrations ORDER BY version`)
	if err != nil {
		return nil, fmt.Errorf("uygulanmış migration'lar okunamadı: %w", err)
	}
	defer rows.Close()

	out := map[int]appliedRecord{}
	for rows.Next() {
		var r appliedRecord
		if err := rows.Scan(&r.Version, &r.Name, &r.Checksum, &r.AppliedAt, &r.DurationMS); err != nil {
			return nil, err
		}
		out[r.Version] = r
	}
	return out, rows.Err()
}

// verifyChecksums — uygulanmış bir migration dosyası sonradan değiştirilmişse durur.
// Değiştirilmiş bir migration, farklı ortamlarda farklı şema anlamına gelir; sessizce
// geçilirse "benim makinemde çalışıyor" sınıfı hataların kaynağı olur.
func verifyChecksums(files []migration, applied map[int]appliedRecord) error {
	for _, m := range files {
		rec, ok := applied[m.Version]
		if !ok {
			continue
		}
		if rec.Checksum != m.Checksum {
			return fmt.Errorf(
				"migration %03d_%s uygulandıktan SONRA değiştirilmiş\n"+
					"  veritabanındaki sağlama: %s\n"+
					"  dosyadaki sağlama      : %s\n"+
					"Uygulanmış bir migration düzenlenmemelidir; değişikliği yeni bir migration olarak ekleyin.",
				m.Version, m.Name, short(rec.Checksum), short(m.Checksum))
		}
	}
	return nil
}

// short — sağlama değerlerini okunur uzunlukta kısaltır (kısa/bozuk değerlerde de güvenli).
func short(s string) string {
	if len(s) <= 12 {
		return s
	}
	return s[:12]
}

func loadMigrations(dir string) ([]migration, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("migration dizini okunamadı (%s): %w", dir, err)
	}

	var out []migration
	seen := map[int]string{}
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		mm := migrationFilePattern.FindStringSubmatch(e.Name())
		if mm == nil {
			if filepath.Ext(e.Name()) == ".sql" {
				return nil, fmt.Errorf("beklenmeyen migration dosya adı: %s (biçim: 001_ad.sql)", e.Name())
			}
			continue
		}
		version, err := strconv.Atoi(mm[1])
		if err != nil {
			return nil, err
		}
		if prev, dup := seen[version]; dup {
			return nil, fmt.Errorf("aynı sürüm numarası iki dosyada: %s ve %s", prev, e.Name())
		}
		seen[version] = e.Name()

		path := filepath.Join(dir, e.Name())
		content, err := os.ReadFile(path)
		if err != nil {
			return nil, err
		}
		sum := sha256.Sum256(content)
		out = append(out, migration{
			Version:  version,
			Name:     mm[2],
			Path:     path,
			Checksum: hex.EncodeToString(sum[:]),
			SQL:      string(content),
		})
	}

	sort.Slice(out, func(i, j int) bool { return out[i].Version < out[j].Version })
	return out, nil
}

func printStatus(files []migration, applied map[int]appliedRecord, pending []migration) {
	fmt.Printf("%-6s %-28s %-12s %s\n", "SÜRÜM", "AD", "DURUM", "UYGULANMA")
	for _, m := range files {
		if rec, ok := applied[m.Version]; ok {
			fmt.Printf("%-6d %-28s %-12s %s (%d ms)\n",
				m.Version, m.Name, "uygulandı",
				rec.AppliedAt.Local().Format("2006-01-02 15:04"), rec.DurationMS)
		} else {
			fmt.Printf("%-6d %-28s %-12s -\n", m.Version, m.Name, "BEKLİYOR")
		}
	}

	// Dosyası olmayan ama veritabanında kayıtlı sürümler (dosya silinmiş olabilir)
	known := map[int]bool{}
	for _, m := range files {
		known[m.Version] = true
	}
	var orphans []int
	for v := range applied {
		if !known[v] {
			orphans = append(orphans, v)
		}
	}
	sort.Ints(orphans)
	for _, v := range orphans {
		fmt.Printf("%-6d %-28s %-12s (dosya yok)\n", v, applied[v].Name, "UYARI")
	}

	fmt.Printf("\nToplam: %d dosya, %d uygulandı, %d bekliyor\n", len(files), len(applied), len(pending))
}

func connect(ctx context.Context) (*pgxpool.Pool, error) {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		host := envOr("DB_HOST", "localhost")
		port := envOr("DB_PORT", "5432")
		user := envOr("DB_USER", "siteeksen")
		pass := os.Getenv("DB_PASSWORD")
		name := envOr("DB_NAME", "siteeksen")
		ssl := envOr("DB_SSLMODE", "disable")
		dsn = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", user, pass, host, port, name, ssl)
	}
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return nil, fmt.Errorf("veritabanına bağlanılamadı: %w", err)
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("veritabanı yanıt vermiyor: %w", err)
	}
	return pool, nil
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func defaultMigrationsDir() string {
	if v := os.Getenv("MIGRATIONS_DIR"); v != "" {
		return v
	}
	return "migrations"
}
