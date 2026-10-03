// Package dbscope, veritabanı isteklerini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// Neden var: izolasyon bugün yalnızca uygulama katmanındadır — her sorguya elle
// `WHERE property_id = $1` yazılır. Tek bir sorguda bu filtre unutulursa başka
// sitenin verisi sızar ve bunu yakalayan hiçbir şey yoktur.
//
// PostgreSQL satır düzeyi güvenliği (RLS) bu filtreyi VERİTABANINA taşır:
// filtre unutulsa bile satırlar dönmez. RLS'in çalışması için her isteğin
// hangi siteye ait olduğunu veritabanının bilmesi gerekir; bu paket o bilgiyi
// oturum değişkeniyle (`app.property_id`) taşır.
//
// Neden transaction içinde: `SET LOCAL` yalnızca o transaction boyunca geçerlidir.
// Havuzdan alınan bağlantı bir sonraki isteğe geçtiğinde değişken kendiliğinden
// sıfırlanır. Oturum düzeyinde (`SET`) ayarlamak, bağlantı havuza geri
// döndüğünde BAŞKA BİR SİTENİN isteğine sızardı — sessiz ve çok tehlikeli bir hata.
package dbscope

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrNoProperty, kapsam kimliği verilmediğinde döner.
var ErrNoProperty = errors.New("site kimliği (property_id) olmadan veritabanı işlemi yapılamaz")

// SettingName, RLS politikalarının okuduğu oturum değişkeninin adı.
const SettingName = "app.property_id"

// WithProperty, verilen işi SİTE KAPSAMLI bir transaction içinde çalıştırır.
//
// Akış: BEGIN → SET LOCAL app.property_id → iş → COMMIT (hata olursa ROLLBACK).
//
// propertyID boşsa iş HİÇ ÇALIŞTIRILMAZ. Boş kapsamla devam etmek, RLS
// politikalarının hiçbir satırı eşleştirmemesine ya da (politikalar gevşekse)
// tüm sitelerin verisinin dönmesine yol açardı; ikisi de sessiz hatadır.
func WithProperty(ctx context.Context, pool *pgxpool.Pool, propertyID string, fn func(pgx.Tx) error) error {
	if propertyID == "" {
		return ErrNoProperty
	}

	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Üçüncü parametre `true`: değişken yalnızca bu transaction boyunca geçerli.
	if _, err := tx.Exec(ctx,
		`SELECT set_config($1, $2, true)`, SettingName, propertyID); err != nil {
		return err
	}

	if err := fn(tx); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

// ErrCannotSeeAllSites, bütün siteleri dolaşması gereken bir bakım aracı
// RLS'e tabi bir rolle bağlandığında döner.
var ErrCannotSeeAllSites = errors.New("bu rol bütün siteleri göremiyor (RLS)")

// RequireAllSitesRole, bağlantı rolünün site listesinin (`properties`)
// TAMAMINI kapsamsız okuyabildiğini doğrular.
//
// Site listesini dolaşan bakım araçları (cmd/encrypt-pii, cmd/rotate-pii)
// uygulama rolüyle çalıştırılırsa kapsamsız sorgu SIFIR site döndürür; araç
// hiçbir şey yapmadan "taşınacak kayıt kalmadı" der. Bu sessiz başarısızlık,
// eski bir anahtarın halkadan çıkarılıp verinin okunamaz kalmasına yol açabilir.
//
// Görebilen roller: süper kullanıcı, BYPASSRLS, ya da tablonun sahibi (tabloda
// FORCE ROW LEVEL SECURITY yoksa). Site içi tablolar araçlarda zaten site
// kapsamıyla sorgulandığı için FORCE'lu tablolarda da sahip doğru satırları görür.
func RequireAllSitesRole(ctx context.Context, pool *pgxpool.Pool) error {
	var role string
	var ok bool
	if err := pool.QueryRow(ctx, `
		SELECT current_user::text,
		       r.rolsuper OR r.rolbypassrls OR NOT c.relrowsecurity
		       OR (pg_has_role(current_user, c.relowner, 'USAGE') AND NOT c.relforcerowsecurity)
		FROM pg_roles r, pg_class c
		WHERE r.rolname = current_user AND c.oid = 'public.properties'::regclass`).Scan(&role, &ok); err != nil {
		return err
	}
	if !ok {
		return fmt.Errorf("%w: %q ile bağlanıldı; bu komut RLS'i aşan migration rolüyle "+
			"çalıştırılmalıdır, aksi hâlde göremediği kayıtları yok sayar", ErrCannotSeeAllSites, role)
	}
	return nil
}

// WithPropertyValue, tek bir değer döndüren işler için kolaylık sarmalayıcısıdır.
func WithPropertyValue[T any](ctx context.Context, pool *pgxpool.Pool, propertyID string, fn func(pgx.Tx) (T, error)) (T, error) {
	var result T
	err := WithProperty(ctx, pool, propertyID, func(tx pgx.Tx) error {
		v, err := fn(tx)
		if err != nil {
			return err
		}
		result = v
		return nil
	})
	return result, err
}
