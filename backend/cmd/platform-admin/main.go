// Command platform-admin, SiteEksen platform yöneticisi rolünü (PLATFORM_ADMIN) verir ya da geri alır (FAZ M1).
//
// Platform yöneticisi tedarikçi belgelerini onaylar, pazaryeri ücretlerini ve paketlerini yönetir. Bu rol hiçbir
// arayüzden ya da kayıt isteğinden alınamaz; yalnızca veritabanı yetkisi olan işletmeci bu komutla verir.
// Rol SİTE VERİSİNE yetki vermez (pkg/middleware). Değişiklik kişinin açık oturumlarını kapatır: yeni rol
// ancak yeni girişte jetona yazılır, geri alınan rol eski jetonda kalmamalıdır.
//
// Kullanım:
//
//	DATABASE_URL=... go run ./cmd/platform-admin -phone 5551234567
//	DATABASE_URL=... go run ./cmd/platform-admin -phone 5551234567 -revoke
//	DATABASE_URL=... go run ./cmd/platform-admin -phone 5550000030 -create -first Ad -last Soyad
//
// -create: numarada hesap yoksa açar (yalnız PLATFORM_ADMIN rolüyle, şifresiz) ve 7 gün geçerli bir etkinleştirme
// kodu yazdırır; kişi şifresini /activate ekranında bu kodla belirler. Kod veritabanında yalnızca özet olarak durur.
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/phone"
	"github.com/siteeksen/backend/pkg/revocation"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

const role = "PLATFORM_ADMIN"

func main() {
	rawPhone := flag.String("phone", "", "rol verilecek hesabın telefon numarası")
	revoke := flag.Bool("revoke", false, "rolü geri al")
	create := flag.Bool("create", false, "numarada hesap yoksa aç ve etkinleştirme kodu yazdır")
	first := flag.String("first", "", "-create için ad")
	last := flag.String("last", "", "-create için soyad")
	flag.Parse()

	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL tanımlı değil")
	}
	p, err := phone.Normalize(*rawPhone)
	if err != nil {
		log.Fatalf("telefon numarası geçersiz: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		log.Fatalf("veritabanına bağlanılamadı: %v", err)
	}
	defer pool.Close()

	if *create {
		if *first == "" || *last == "" {
			log.Fatal("-create için -first ve -last zorunludur")
		}
		var id string
		err := pool.QueryRow(ctx, `INSERT INTO users (first_name, last_name, phone, password_hash, roles, kvkk_consent_at)
			VALUES ($1, $2, $3, '!', ARRAY[$4], now()) ON CONFLICT (phone) DO NOTHING RETURNING id::text`,
			*first, *last, p, role).Scan(&id)
		if err == nil {
			code, err := service.GenerateCode()
			if err != nil {
				log.Fatal(err)
			}
			if _, err := pool.Exec(ctx, `INSERT INTO user_activation_codes (user_id, code_hash, purpose, expires_at)
				VALUES ($1, $2, 'ACTIVATION', now() + interval '7 days')`, id, repository.HashCode(code)); err != nil {
				log.Fatalf("etkinleştirme kodu yazılamadı: %v", err)
			}
			fmt.Printf("%s: hesap açıldı, roller [%s], etkinleştirme kodu %s (7 gün)\n", p, role, code)
			return
		}
	}

	q := `UPDATE users SET roles = CASE WHEN $2 = ANY(COALESCE(roles, '{}')) THEN roles ELSE array_append(COALESCE(roles, '{}'), $2) END,
	             updated_at = now()
	      WHERE phone = $1 AND deleted = 0 RETURNING id::text, roles`
	if *revoke {
		q = `UPDATE users SET roles = array_remove(roles, $2), updated_at = now()
		      WHERE phone = $1 AND deleted = 0 RETURNING id::text, roles`
	}
	var id string
	var roles []string
	if err := pool.QueryRow(ctx, q, p, role).Scan(&id, &roles); err != nil {
		log.Fatalf("hesap bulunamadı ya da güncellenemedi (%s): %v", p, err)
	}
	if err := revocation.New(pool).RevokeAll(ctx, id, "ROLE_CHANGED"); err != nil {
		log.Fatalf("rol değişti ama açık oturumlar kapatılamadı; kişiye yeniden giriş yaptırın: %v", err)
	}
	fmt.Printf("%s: roller %v (açık oturumlar kapatıldı)\n", p, roles)
}
