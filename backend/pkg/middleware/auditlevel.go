package middleware

import (
	"context"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// İşlem kaydı düzeyi (073, kullanıcı kararı K5). Site ayarı ACTIVITY_LOG_LEVEL:
//
//	OFF      — yalnız ZORUNLU çekirdek: yazma işlemleri, 403 (DENIED), kişisel veri okumaları,
//	           giriş/çıkış ve hesap güvenliği olayları. Bunlar hiçbir düzeyde kapanmaz
//	           (KVKK m.12 veri güvenliği; mali kayıtların değiştirilemezliği).
//	STANDARD — zorunlu + diğer bütün okuma istekleri (önceki davranış, varsayılan).
//	FULL     — standart + istemci etkinliği (ekran, menü, sekme, arama, dışa aktarma).
const (
	LogLevelOff      = "OFF"
	LogLevelStandard = "STANDARD"
	LogLevelFull     = "FULL"
)

// sensitiveEntities: okunması kişisel veri erişimi sayılan kaynaklar; OFF düzeyinde de kaydedilir.
var sensitiveEntities = map[string]bool{
	"user": true, "resident": true, "personnel": true, "kvkk_request": true, "document": true,
	"emergency": true, "finance": true, "visitor": true, "parking": true, "package": true,
	"violation": true, "renovation": true, "audit": true,
}

type levelEntry struct {
	level string
	at    time.Time
}

var (
	levelMu    sync.Mutex
	levelCache = map[string]levelEntry{}
	// LevelTTL: ayar değişikliği en geç bu süre sonra her serviste geçerli olur.
	// ACTIVITY_LEVEL_CACHE_TTL ile değiştirilebilir (doğrulamada 0s: her istekte okunur).
	LevelTTL = func() time.Duration {
		if d, err := time.ParseDuration(os.Getenv("ACTIVITY_LEVEL_CACHE_TTL")); err == nil && d >= 0 {
			return d
		}
		return 60 * time.Second
	}()
)

// ActivityLogLevel sitenin işlem kaydı düzeyini döner. Okunamazsa (ör. kimlik servisinin
// site verisine erişimi yoktur) STANDARD döner: kayıt azaltılmaz, sessizce kapanmaz.
func ActivityLogLevel(ctx context.Context, pool *pgxpool.Pool, propertyID string) string {
	if pool == nil || propertyID == "" {
		return LogLevelStandard
	}
	levelMu.Lock()
	e, ok := levelCache[propertyID]
	levelMu.Unlock()
	if ok && time.Since(e.at) < LevelTTL {
		return e.level
	}
	level := LogLevelStandard
	var v *string
	err := dbscope.For(pool, propertyID).QueryRow(ctx,
		`SELECT value_text FROM property_settings WHERE property_id = $1 AND setting_key = 'ACTIVITY_LOG_LEVEL'`,
		propertyID).Scan(&v)
	if err == nil && v != nil {
		switch strings.ToUpper(*v) {
		case LogLevelOff, LogLevelStandard, LogLevelFull:
			level = strings.ToUpper(*v)
		}
	}
	levelMu.Lock()
	levelCache[propertyID] = levelEntry{level: level, at: time.Now()}
	levelMu.Unlock()
	return level
}

// ForgetActivityLogLevel, ayarı değiştiren servisin önbelleğini hemen boşaltır.
func ForgetActivityLogLevel(propertyID string) {
	levelMu.Lock()
	delete(levelCache, propertyID)
	levelMu.Unlock()
}

// shouldAudit, bir isteğin denetim izine yazılıp yazılmayacağını düzeye göre söyler.
func shouldAudit(level, method, entityType string, status int, explicit bool) bool {
	if explicit || method != "GET" || status == 403 {
		return true
	}
	if level == LogLevelOff {
		return sensitiveEntities[entityType]
	}
	return true
}
