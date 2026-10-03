// Command rotate-pii, şifreli kişisel verileri BİRİNCİL anahtara taşır.
//
// Anahtar döndürmenin üçüncü adımıdır (docs/runbook-anahtar-dondurme.md):
//  1. Yeni anahtar PII_ENCRYPTION_KEY yapılır, eskisi PII_ENCRYPTION_PREVIOUS_KEYS'e
//     taşınır ve servisler yeniden başlatılır (eski kayıtlar okunmaya devam eder).
//  2. Bu komut, birincil anahtarla YENİ biçimde yazılmamış her kaydı çözer,
//     birincil anahtarla yeniden şifreler ve arama anahtarını yeniden üretir.
//  3. Komut "eski anahtarla kayıt kalmadı" dedikten sonra eski anahtar halkadan çıkarılır.
//
// Aynı komut, 2026-09-27 öncesinin kimliksiz biçimini de (ham anahtarla şifreli
// ve ham anahtarla HMAC) yeni biçime geçirir; bu yüzden anahtar değişmese de bir
// kez çalıştırılmalıdır.
//
// Çözülemeyen kayıt ATLANMAZ: o sitenin işlemi geri alınır ve komut hata verir.
// Atlayıp devam etmek, eski anahtar halkadan çıkarıldığında o kaydı sonsuza dek
// okunamaz bırakırdı.
//
// İşlem tekrarlanabilir: birincil anahtarla yazılmış kayıtlara dokunmaz.
//
// Kullanım:
//
//	DATABASE_URL=... PII_ENCRYPTION_KEY=... PII_ENCRYPTION_KEY_ID=k2 \
//	PII_ENCRYPTION_PREVIOUS_KEYS=k1:... go run ./cmd/rotate-pii [-dry-run]
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/pii"
)

func main() {
	dryRun := flag.Bool("dry-run", false, "hiçbir şey yazma, yalnızca kaç kaydın taşınacağını göster")
	flag.Parse()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL tanımlı değil")
	}
	vault, err := pii.FromEnv()
	if err != nil {
		log.Fatalf("Anahtar halkası okunamadı: %v\n\n"+
			"Birincil anahtar %s (kimliği %s), çözmek için gereken eski anahtarlar\n"+
			"%s=\"k1:<base64>,...\" biçiminde verilmelidir.", err, pii.EnvKey, pii.EnvKeyID, pii.EnvPreviousKeys)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Minute)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("Veritabanına bağlanılamadı: %v", err)
	}
	defer pool.Close()

	if err := dbscope.RequireAllSitesRole(ctx, pool); err != nil {
		log.Fatalf("Döndürme başlatılmadı: %v", err)
	}

	remaining, err := run(ctx, pool, vault, *dryRun)
	if err != nil {
		log.Fatalf("Döndürme başarısız: %v", err)
	}
	if remaining > 0 && !*dryRun {
		// run hata vermeden bitip kayıt kaldıysa bir şey ters gitmiştir; eski
		// anahtarın "artık çıkarılabilir" sanılmasına izin verilmez.
		os.Exit(2)
	}
}

type employeeRow struct {
	id, tcEnc, ibanEnc string
}

// run, siteleri tek tek, her birini kendi kapsamı ve işlemi içinde işler
// (cmd/encrypt-pii ile aynı gerekçe: RLS'i delen "her şeyi gör" kapısı açılmaz).
// Dönen değer, birincil anahtarla yazılmamış kalan şifreli alan sayısıdır.
func run(ctx context.Context, pool *pgxpool.Pool, vault *pii.Vault, dryRun bool) (int, error) {
	properties, err := listProperties(ctx, pool)
	if err != nil {
		return 0, err
	}
	fmt.Printf("Birincil anahtar: %s — %d site taranacak.\n", vault.PrimaryKeyID(), len(properties))

	var total int
	for _, propertyID := range properties {
		n, err := rotateProperty(ctx, pool, vault, propertyID, dryRun)
		if err != nil {
			return 0, fmt.Errorf("site %s: %w", propertyID, err)
		}
		total += n
	}
	if dryRun {
		fmt.Printf("\n(-dry-run) %d kayıt taşınacaktı; hiçbir şey yazılmadı.\n", total)
	} else {
		fmt.Printf("\nToplam %d kayıt birincil anahtara taşındı.\n", total)
	}
	return report(ctx, pool, vault, properties)
}

func listProperties(ctx context.Context, pool *pgxpool.Pool) ([]string, error) {
	rows, err := pool.Query(ctx, `SELECT id::text FROM properties ORDER BY created_at`)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowTo[string])
}

func scoped(ctx context.Context, pool *pgxpool.Pool, propertyID string) (pgx.Tx, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	if _, err := tx.Exec(ctx, `SELECT set_config('app.property_id', $1, true)`, propertyID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}
	return tx, nil
}

func rotateProperty(ctx context.Context, pool *pgxpool.Pool, vault *pii.Vault, propertyID string, dryRun bool) (int, error) {
	tx, err := scoped(ctx, pool, propertyID)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// FOR UPDATE: döndürme sırasında servis aynı satırı değiştirirse biri
	// diğerini ezmesin.
	rows, err := tx.Query(ctx, `
		SELECT id::text, COALESCE(tc_number_encrypted,''), COALESCE(bank_iban_encrypted,'')
		FROM employees
		WHERE property_id = $1::uuid
		  AND (tc_number_encrypted IS NOT NULL OR bank_iban_encrypted IS NOT NULL)
		ORDER BY created_at
		FOR UPDATE`, propertyID)
	if err != nil {
		return 0, err
	}
	var pending []employeeRow
	for rows.Next() {
		var r employeeRow
		if err := rows.Scan(&r.id, &r.tcEnc, &r.ibanEnc); err != nil {
			rows.Close()
			return 0, err
		}
		if vault.NeedsRotation(r.tcEnc) || vault.NeedsRotation(r.ibanEnc) {
			pending = append(pending, r)
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, err
	}
	if len(pending) == 0 {
		return 0, nil
	}
	fmt.Printf("Site %s: %d kayıt birincil anahtarla yazılmamış.\n", propertyID, len(pending))
	if dryRun {
		return len(pending), nil
	}

	for _, r := range pending {
		tcEnc, tcIdx, err := reencrypt(vault, r.tcEnc)
		if err != nil {
			return 0, fmt.Errorf("personel %s TCKN: %w", r.id, err)
		}
		ibanEnc, ibanIdx, err := reencrypt(vault, r.ibanEnc)
		if err != nil {
			return 0, fmt.Errorf("personel %s IBAN: %w", r.id, err)
		}
		// Şifreli metin ve arama anahtarı AYNI anahtarla, aynı UPDATE'te yazılır:
		// biri yeni biri eski kalırsa yinelenen kayıt denetimi şaşar.
		// pii_encrypted_at değiştirilmez: ilk şifreleme zamanını gösterir.
		if _, err := tx.Exec(ctx, `
			UPDATE employees
			SET tc_number_encrypted = COALESCE($2, tc_number_encrypted),
			    tc_number_index     = COALESCE($3, tc_number_index),
			    bank_iban_encrypted = COALESCE($4, bank_iban_encrypted),
			    bank_iban_index     = COALESCE($5, bank_iban_index),
			    updated_at = now()
			WHERE id = $1::uuid`,
			r.id, tcEnc, tcIdx, ibanEnc, ibanIdx); err != nil {
			if strings.Contains(err.Error(), "uq_employees_tc_active") {
				return 0, fmt.Errorf("personel %s: aynı TCKN'li ikinci bir AKTİF kayıt var "+
					"(döndürme öncesi farklı anahtarlarla açılmış); kayıtlardan biri elle "+
					"pasifleştirilmeden döndürme tamamlanamaz: %w", r.id, err)
			}
			return 0, fmt.Errorf("personel %s: yazılamadı: %w", r.id, err)
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return 0, err
	}
	return len(pending), nil
}

// reencrypt, alanı birincil anahtarla yeniden şifreler. Alan boşsa ya da zaten
// birincil anahtarla yazılmışsa nil döner (COALESCE mevcut değeri korur).
func reencrypt(vault *pii.Vault, cipherText string) (enc, idx *string, err error) {
	if !vault.NeedsRotation(cipherText) {
		return nil, nil, nil
	}
	plain, err := vault.Decrypt(cipherText)
	if err != nil {
		return nil, nil, err
	}
	ct, err := vault.Encrypt(plain)
	if err != nil {
		return nil, nil, err
	}
	bi := vault.BlindIndex(plain)
	return &ct, &bi, nil
}

// report, şifreli alanları anahtar kimliğine göre sayar. Eski anahtarın
// halkadan çıkarılabileceği yalnızca bu sayım SIFIR olduğunda söylenir.
func report(ctx context.Context, pool *pgxpool.Pool, vault *pii.Vault, properties []string) (int, error) {
	counts := map[string]int{}
	for _, propertyID := range properties {
		tx, err := scoped(ctx, pool, propertyID)
		if err != nil {
			return 0, err
		}
		rows, err := tx.Query(ctx, `
			SELECT CASE WHEN position('$' IN v) > 0 THEN split_part(v, '$', 1)
			            ELSE '(eski biçim)' END, count(*)
			FROM employees, LATERAL (VALUES (tc_number_encrypted), (bank_iban_encrypted)) AS f(v)
			WHERE property_id = $1::uuid AND v IS NOT NULL AND v <> ''
			GROUP BY 1`, propertyID)
		if err != nil {
			_ = tx.Rollback(ctx)
			return 0, err
		}
		for rows.Next() {
			var key string
			var n int
			if err := rows.Scan(&key, &n); err != nil {
				rows.Close()
				_ = tx.Rollback(ctx)
				return 0, err
			}
			counts[key] += n
		}
		rows.Close()
		err = rows.Err()
		_ = tx.Rollback(ctx)
		if err != nil {
			return 0, err
		}
	}

	keys := make([]string, 0, len(counts))
	for k := range counts {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	fmt.Println("\nŞifreli alanlar (anahtar kimliğine göre):")
	if len(keys) == 0 {
		fmt.Println("  (şifreli alan yok)")
	}
	remaining := 0
	for _, k := range keys {
		fmt.Printf("  %-14s %d\n", k, counts[k])
		if k != vault.PrimaryKeyID() {
			remaining += counts[k]
		}
	}
	if remaining == 0 {
		fmt.Printf("Eski anahtarla yazılmış kayıt kalmadı; %s artık boşaltılabilir.\n", pii.EnvPreviousKeys)
	} else {
		fmt.Printf("UYARI: %d alan hâlâ birincil anahtarla yazılmamış; eski anahtar halkadan ÇIKARILMAMALI.\n", remaining)
	}
	return remaining, nil
}
