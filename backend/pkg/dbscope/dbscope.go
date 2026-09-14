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
