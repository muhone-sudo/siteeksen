package dbscope

import (
	"context"
	"fmt"
	"regexp"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Scoped, bir siteye bağlanmış veritabanı erişimidir.
//
// `pgxpool.Pool` ile aynı imzalara sahiptir (Query / QueryRow / Exec / Begin),
// bu yüzden mevcut depo kodunda `r.pool.` yerine `r.scope(propertyID).` yazmak
// yeterlidir. Her çağrı, kapsamı ayarlanmış bir transaction içinde çalışır;
// böylece RLS politikaları devreye girer.
//
// Neden her çağrı için ayrı transaction: `SET LOCAL` transaction ömrüyle
// sınırlıdır. Havuzdan alınan bağlantıya oturum düzeyinde yazmak, bağlantı
// havuza döndüğünde BAŞKA BİR SİTENİN isteğine sızardı.
//
// Maliyet: çağrı başına bir ek gidiş-dönüş. Bunun karşılığında, unutulan bir
// `WHERE property_id` filtresi artık veri sızdırmaz.
type Scoped struct {
	pool       *pgxpool.Pool
	propertyID string
}

// For, verilen site için kapsamlı erişim üretir.
func For(pool *pgxpool.Pool, propertyID string) *Scoped {
	return &Scoped{pool: pool, propertyID: propertyID}
}

// begin, kapsamı ayarlanmış bir transaction açar.
func (s *Scoped) begin(ctx context.Context) (pgx.Tx, error) {
	if s.propertyID == "" {
		return nil, ErrNoProperty
	}
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `SELECT set_config($1, $2, true)`,
		SettingName, s.propertyID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}
	return tx, nil
}

// Begin, kapsamı ayarlanmış transaction'ı çağırana verir.
// Çağıran Commit ya da Rollback etmekle yükümlüdür.
func (s *Scoped) Begin(ctx context.Context) (pgx.Tx, error) {
	return s.begin(ctx)
}

// Exec, tek bir yazma işini kapsam içinde çalıştırır.
func (s *Scoped) Exec(ctx context.Context, sql string, args ...any) (pgconn.CommandTag, error) {
	tx, err := s.begin(ctx)
	if err != nil {
		return pgconn.CommandTag{}, err
	}
	tag, err := tx.Exec(ctx, sql, args...)
	if err != nil {
		_ = tx.Rollback(ctx)
		return tag, err
	}
	if cerr := tx.Commit(ctx); cerr != nil {
		return tag, cerr
	}
	return tag, nil
}

// scopedRows, satırlar kapatıldığında transaction'ı da kapatır.
//
// Transaction'ı hemen kapatmak satırları geçersiz kılardı; bu yüzden ömrü
// satırlara bağlanır. Çağıran zaten `defer rows.Close()` yazmak zorundadır.
type scopedRows struct {
	pgx.Rows
	tx  pgx.Tx
	ctx context.Context
}

func (r *scopedRows) Close() {
	r.Rows.Close()
	// Salt okuma işi olduğu için Commit ile Rollback arasında fark yoktur;
	// Commit, açık kalan transaction uyarısı bırakmaz.
	_ = r.tx.Commit(r.ctx)
}

// Query, sorguyu kapsam içinde çalıştırır. Satırlar kapatıldığında
// transaction da kapanır.
func (s *Scoped) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	tx, err := s.begin(ctx)
	if err != nil {
		return nil, err
	}
	rows, err := tx.Query(ctx, sql, args...)
	if err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}
	return &scopedRows{Rows: rows, tx: tx, ctx: ctx}, nil
}

// scopedRow, Scan çağrıldığında transaction'ı kapatır.
type scopedRow struct {
	row pgx.Row
	tx  pgx.Tx
	ctx context.Context
	err error
}

func (r *scopedRow) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	err := r.row.Scan(dest...)
	_ = r.tx.Commit(r.ctx)
	return err
}

// errRow, kapsam açılamadığında hatayı Scan'e taşır.
type errRow struct{ err error }

func (r errRow) Scan(_ ...any) error { return r.err }

// identPattern, Exists'e verilen tablo adının düz bir tanımlayıcı olduğunu
// güvenceye alır (tablo adı SQL'e parametre olarak verilemez).
var identPattern = regexp.MustCompile(`^[a-z_][a-z0-9_]*$`)

// Exists, kapsam içinde `id`'si verilen satırın var olup olmadığını söyler.
//
// NEDEN VAR (2026-09-26): durum geçişli güncellemeler (`UPDATE … WHERE id=$1
// AND status='PENDING'`) etkilenen satır 0 olduğunda "uygun durumda değil"
// (409) döndürüyordu — kayıt HİÇ YOKKEN de. İstemci var olmayan bir kaydı
// "başka biri işlem yapmış" sanıyordu. Bu yardımcı, 0 satır durumunda iki
// ihtimali ayırmak içindir: yoksa 404, varsa 409.
//
// RLS altında çalıştığı için başka sitenin kaydı da "yok" sayılır — doğru
// davranış budur (varlığı sızdırılmaz).
func (s *Scoped) Exists(ctx context.Context, table, id string) (bool, error) {
	if !identPattern.MatchString(table) {
		return false, fmt.Errorf("dbscope.Exists: geçersiz tablo adı %q", table)
	}
	var ok bool
	err := s.QueryRow(ctx,
		`SELECT EXISTS (SELECT 1 FROM `+table+` WHERE id = $1)`, id).Scan(&ok)
	return ok, err
}

// QueryRow, tek satırlık sorguyu kapsam içinde çalıştırır.
//
// Transaction, Scan çağrıldığında kapanır. Çağıran Scan'i çağırmazsa
// transaction bağlantı havuza dönene kadar açık kalır; bu yüzden QueryRow
// sonucunun Scan'i her zaman çağrılmalıdır (pgx'in kendi sözleşmesi de budur).
func (s *Scoped) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	tx, err := s.begin(ctx)
	if err != nil {
		return errRow{err: err}
	}
	return &scopedRow{row: tx.QueryRow(ctx, sql, args...), tx: tx, ctx: ctx}
}
