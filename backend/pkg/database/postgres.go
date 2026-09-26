package database

import (
	"context"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

var pool *pgxpool.Pool

// Config veritabanı bağlantı ayarları
type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
	// MaxConns / MinConns, servis başına havuz sınırlarıdır.
	MaxConns int32
	MinConns int32
}

// NewConfigFromEnv ortam değişkenlerinden config oluşturur.
//
// Havuz boyutu (2026-09-26): önceden her servis sabit 25 azami / 5 ASGARİ
// bağlantı açıyordu. 26 servis × 5 = 130 boşta bağlantı, PostgreSQL'in
// varsayılan 100 sınırını AŞIYOR: son açılan servisler "remaining connection
// slots are reserved" hatasıyla hiç başlamıyordu (geliştirme ortamında
// community ve reservation böyle düşüyordu; aynısı compose dağıtımında da
// olurdu). Artık varsayılan 8 azami / 0 asgari; DB_MAX_CONNS / DB_MIN_CONNS
// ile değiştirilebilir. Toplam azami (26 × 8 = 208) için veritabanının
// max_connections ayarı yükseltilir (compose ve betikler 300 kullanır).
func NewConfigFromEnv() *Config {
	return &Config{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     getEnv("DB_PORT", "5432"),
		User:     getEnv("DB_USER", "siteeksen"),
		Password: getEnv("DB_PASSWORD", ""),
		DBName:   getEnv("DB_NAME", "siteeksen"),
		SSLMode:  getEnv("DB_SSLMODE", "disable"),
		MaxConns: int32(getInt("DB_MAX_CONNS", 8)),
		MinConns: int32(getInt("DB_MIN_CONNS", 0)),
	}
}

// DSN, bağlantı adresini kurar. Kullanıcı adı ve parola URL KAÇIŞIYLA eklenir:
// önceden düz metin birleştiriliyordu ve `/`, `@`, `+`, `#` içeren bir parola
// (ör. `openssl rand -base64 32` çıktısı) adresi bozuyordu.
func (c *Config) DSN() string {
	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(c.User, c.Password),
		Host:     c.Host + ":" + c.Port,
		Path:     "/" + c.DBName,
		RawQuery: url.Values{"sslmode": {c.SSLMode}}.Encode(),
	}
	return u.String()
}

// Connect veritabanına bağlanır
func Connect(cfg *Config) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(cfg.DSN())
	if err != nil {
		return nil, fmt.Errorf("config parse hatası: %w", err)
	}

	config.MaxConns = cfg.MaxConns
	if config.MaxConns <= 0 {
		config.MaxConns = 8
	}
	config.MinConns = cfg.MinConns
	if config.MinConns < 0 || config.MinConns > config.MaxConns {
		config.MinConns = 0
	}
	config.MaxConnLifetime = time.Hour
	config.MaxConnIdleTime = 30 * time.Minute

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err = pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("bağlantı hatası: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping hatası: %w", err)
	}

	return pool, nil
}

// GetPool aktif pool'u döndürür
func GetPool() *pgxpool.Pool {
	return pool
}

// Close bağlantıları kapatır
func Close() {
	if pool != nil {
		pool.Close()
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func getInt(key string, fallback int) int {
	if v, ok := os.LookupEnv(key); ok {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}
