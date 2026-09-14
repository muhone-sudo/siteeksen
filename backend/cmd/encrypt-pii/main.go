// Command encrypt-pii, mevcut düz metin kişisel verileri şifreler (FAZ 2.8).
//
// Migration 019 şifreli kolonları ekler ama mevcut satırları ŞİFRELEYEMEZ:
// şifreleme uygulama anahtarını gerektirir ve anahtar veritabanında değildir
// (olsaydı şifrelemenin anlamı kalmazdı). Bu komut o boşluğu doldurur.
//
// Ne yapar:
//  1. Düz metin TCKN/IBAN taşıyan satırları okur.
//  2. Şifreler, arama anahtarını (blind index) ve son dört haneyi üretir.
//  3. Şifreli kolonlara yazar ve DÜZ METİN KOLONU NULL'lar.
//
// Neden düz metni NULL'lar: şifreli kopya yanında düz metni bırakmak, şifrelemeyi
// tamamen anlamsız kılar. Sızıntıda saldırgan zaten düz metni okur.
//
// İşlem tekrarlanabilir (idempotent): zaten şifrelenmiş satırlara dokunmaz.
//
// Kullanım:
//
//	DATABASE_URL=... PII_ENCRYPTION_KEY=... go run ./cmd/encrypt-pii
//	DATABASE_URL=... PII_ENCRYPTION_KEY=... go run ./cmd/encrypt-pii -dry-run
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/pii"
)

func main() {
	dryRun := flag.Bool("dry-run", false, "hiçbir şey yazma, yalnızca ne yapılacağını göster")
	flag.Parse()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL tanımlı değil")
	}

	vault, err := pii.FromEnv()
	if err != nil {
		// Anahtarsız çalıştırmak, "şifreledim" deyip hiçbir şey yapmamak olurdu.
		log.Fatalf("Şifreleme anahtarı okunamadı: %v\n\n"+
			"32 baytlık bir anahtar üretmek için:\n"+
			"  openssl rand -base64 32\n"+
			"Ardından %s ortam değişkenine verin.", err, pii.EnvKey)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()

	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("Veritabanına bağlanılamadı: %v", err)
	}
	defer pool.Close()

	if err := run(ctx, pool, vault, *dryRun); err != nil {
		log.Fatalf("Şifreleme başarısız: %v", err)
	}
}

// run, tüm siteleri tek tek dolaşır.
//
// `employees` tablosunda satır düzeyi güvenliği açıktır (migration 020): kapsam
// ayarlanmadan hiçbir satır görünmez. Bu araç, "her şeyi gör" gibi bir kapı
// açmak yerine her site için kapsamı ayrı ayrı ayarlar — böyle bir kapı,
// uygulamadaki tek satırlık bir hatayla tüm izolasyonu devre dışı bırakabilirdi.
func run(ctx context.Context, pool *pgxpool.Pool, vault *pii.Vault, dryRun bool) error {
	propRows, err := pool.Query(ctx, `SELECT id::text FROM properties ORDER BY created_at`)
	if err != nil {
		return err
	}
	var properties []string
	for propRows.Next() {
		var id string
		if err := propRows.Scan(&id); err != nil {
			propRows.Close()
			return err
		}
		properties = append(properties, id)
	}
	propRows.Close()
	if err := propRows.Err(); err != nil {
		return err
	}
	fmt.Printf("%d site taranacak.\n", len(properties))

	var totalEncrypted, totalSkipped int
	for _, propertyID := range properties {
		enc, skip, err := runForProperty(ctx, pool, vault, propertyID, dryRun)
		if err != nil {
			return fmt.Errorf("site %s: %w", propertyID, err)
		}
		totalEncrypted += enc
		totalSkipped += skip
	}

	fmt.Printf("\nToplam %d kayıt şifrelendi, %d kayıt atlandı.\n", totalEncrypted, totalSkipped)
	if totalSkipped > 0 {
		fmt.Println("ATLANAN kayıtlar DÜZ METİN olarak duruyor. Doğrulamadan geçmeyen " +
			"değerler elle düzeltilip komut yeniden çalıştırılmalıdır.")
	}
	return reportStatus(ctx, pool, properties)
}

// runForProperty, tek bir sitenin kayıtlarını kapsam içinde işler.
func runForProperty(ctx context.Context, pool *pgxpool.Pool, vault *pii.Vault, propertyID string, dryRun bool) (int, int, error) {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return 0, 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	if _, err := tx.Exec(ctx, `SELECT set_config('app.property_id', $1, true)`,
		propertyID); err != nil {
		return 0, 0, err
	}

	rows, err := tx.Query(ctx, `
		SELECT id::text, COALESCE(tc_number,''), COALESCE(bank_iban,'')
		FROM employees
		WHERE tc_number IS NOT NULL OR bank_iban IS NOT NULL
		ORDER BY created_at`)
	if err != nil {
		return 0, 0, err
	}

	type row struct{ id, tc, iban string }
	var pending []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.tc, &r.iban); err != nil {
			rows.Close()
			return 0, 0, err
		}
		pending = append(pending, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, 0, err
	}

	if len(pending) == 0 {
		return 0, 0, nil
	}
	fmt.Printf("Site %s: %d kayıtta düz metin kişisel veri bulundu.\n", propertyID, len(pending))
	if dryRun {
		fmt.Println("  (-dry-run) Hiçbir şey yazılmadı.")
		return 0, 0, nil
	}

	var encrypted, skipped int
	for _, r := range pending {
		var tcEnc, tcIdx, ibanEnc, ibanIdx, ibanLast4 *string

		if r.tc != "" {
			// Geçersiz TCKN şifrelenmez: şifreli alandaki bir yazım hatası
			// sonradan gözle bulunamaz. Kayıt olduğu gibi bırakılır ve raporlanır.
			if err := pii.ValidateTCKN(r.tc); err != nil {
				fmt.Printf("  ATLANDI %s: TCKN algoritmik doğrulamadan geçmedi (%s)\n",
					r.id, pii.MaskTCKN(r.tc))
				skipped++
				continue
			}
			ct, err := vault.Encrypt(r.tc)
			if err != nil {
				return 0, 0, fmt.Errorf("%s: TCKN şifrelenemedi: %w", r.id, err)
			}
			idx := vault.BlindIndex(r.tc)
			tcEnc, tcIdx = &ct, &idx
		}

		if r.iban != "" {
			if err := pii.ValidateIBAN(r.iban); err != nil {
				fmt.Printf("  ATLANDI %s: IBAN doğrulamadan geçmedi (%s)\n",
					r.id, pii.MaskIBAN(r.iban))
				skipped++
				continue
			}
			ct, err := vault.Encrypt(r.iban)
			if err != nil {
				return 0, 0, fmt.Errorf("%s: IBAN şifrelenemedi: %w", r.id, err)
			}
			idx := vault.BlindIndex(r.iban)
			l4 := pii.Last4(r.iban)
			ibanEnc, ibanIdx, ibanLast4 = &ct, &idx, &l4
		}

		// Şifreli değeri yazmak ve düz metni silmek AYNI işlemde olmalıdır:
		// arada bir kesinti olursa ya şifresiz kalır ya da veri kaybolur.
		if _, err := tx.Exec(ctx, `
			UPDATE employees
			SET tc_number_encrypted = COALESCE($2, tc_number_encrypted),
			    tc_number_index     = COALESCE($3, tc_number_index),
			    bank_iban_encrypted = COALESCE($4, bank_iban_encrypted),
			    bank_iban_index     = COALESCE($5, bank_iban_index),
			    bank_iban_last4     = COALESCE($6, bank_iban_last4),
			    tc_number = CASE WHEN $2 IS NOT NULL THEN NULL ELSE tc_number END,
			    bank_iban = CASE WHEN $4 IS NOT NULL THEN NULL ELSE bank_iban END,
			    pii_encrypted_at = now(),
			    updated_at = now()
			WHERE id = $1::uuid`,
			r.id, tcEnc, tcIdx, ibanEnc, ibanIdx, ibanLast4); err != nil {
			return 0, 0, fmt.Errorf("%s: yazılamadı: %w", r.id, err)
		}
		encrypted++
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, 0, err
	}
	return encrypted, skipped, nil
}

// reportStatus, taşımanın gerçekten tamamlanıp tamamlanmadığını gösterir.
//
// Görünüm de RLS'e tabidir; bu yüzden site site sorgulanır ve toplanır.
func reportStatus(ctx context.Context, pool *pgxpool.Pool, properties []string) error {
	var total, plainTC, encTC, plainIBAN, encIBAN int
	for _, propertyID := range properties {
		tx, err := pool.Begin(ctx)
		if err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, `SELECT set_config('app.property_id', $1, true)`,
			propertyID); err != nil {
			_ = tx.Rollback(ctx)
			return err
		}
		var t, pt, et, pi, ei int
		err = tx.QueryRow(ctx, `
			SELECT total_rows, plaintext_tc, encrypted_tc, plaintext_iban, encrypted_iban
			FROM pii_encryption_status WHERE table_name = 'employees'`).
			Scan(&t, &pt, &et, &pi, &ei)
		_ = tx.Commit(ctx)
		if err != nil {
			return err
		}
		total += t
		plainTC += pt
		encTC += et
		plainIBAN += pi
		encIBAN += ei
	}

	fmt.Printf("\nDurum (employees): toplam %d | TCKN düz %d / şifreli %d | "+
		"IBAN düz %d / şifreli %d\n", total, plainTC, encTC, plainIBAN, encIBAN)
	if plainTC > 0 || plainIBAN > 0 {
		fmt.Println("UYARI: hâlâ düz metin kişisel veri var; taşıma TAMAMLANMADI.")
	} else {
		fmt.Println("Şifrelenecek düz metin kayıt yok.")
	}
	return nil
}
