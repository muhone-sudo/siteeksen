package legalparams

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Bu testler GERÇEK bir veritabanına karşı çalışır.
// TEST_DATABASE_URL verilmezse atlanır (CI ve verify-stack.sh bunu sağlar).
func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	dsn := os.Getenv("TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TEST_DATABASE_URL tanımlı değil — veritabanı testi atlanıyor")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		t.Fatalf("veritabanına bağlanılamadı: %v", err)
	}
	t.Cleanup(pool.Close)
	if err := pool.Ping(context.Background()); err != nil {
		t.Fatalf("veritabanı yanıt vermiyor: %v", err)
	}
	return pool
}

func TestVarsayilanlarYuklu(t *testing.T) {
	r := New(testPool(t))
	ctx := context.Background()

	// KMK m.20/2 — aylık %5
	p, err := r.Get(ctx, "", LateFeeMonthlyRate, time.Now())
	if err != nil {
		t.Fatalf("gecikme tazminatı parametresi okunamadı: %v", err)
	}
	if p.Numeric.String() != "0.05" {
		t.Errorf("gecikme tazminatı oranı %s, beklenen 0.05", p.Numeric)
	}
	if !p.IsMandatory {
		t.Errorf("gecikme tazminatı kanunla sabit olarak işaretlenmemiş")
	}
	if p.LegalBasis == "" {
		t.Errorf("hukuki dayanak boş")
	}

	// Isıtma payları toplamı 1 olmalı (yönetmelik %70 + %30)
	c, err := r.Decimal(ctx, "", HeatingConsumptionShare, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	a, err := r.Decimal(ctx, "", HeatingAreaShare, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if !c.Add(a).Equal(decOne()) {
		t.Errorf("ısıtma payları toplamı 1 değil: %s + %s", c, a)
	}

	// Tam sayı parametreler
	days, err := r.Int(ctx, "", GANoticeDays, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if days != 15 {
		t.Errorf("genel kurul çağrı süresi %d gün, beklenen 15 (KMK m.29)", days)
	}

	units, err := r.Int(ctx, "", ManagerMandatoryUnitCount, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if units != 8 {
		t.Errorf("yönetici zorunluluğu eşiği %d, beklenen 8 (KMK m.34)", units)
	}

	// Metinsel parametre
	scope, err := r.Text(ctx, "", TenantLiabilityScope, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if scope != "RENT_AMOUNT" {
		t.Errorf("kiracı sorumluluk kapsamı %q, beklenen RENT_AMOUNT (KMK m.22)", scope)
	}
}

// Bulunmayan parametre için SESSİZ VARSAYILAN dönmemeli.
func TestBulunmayanParametreHataDondurur(t *testing.T) {
	r := NewWithTTL(testPool(t), 0)
	_, err := r.Get(context.Background(), "", "OLMAYAN_PARAMETRE_KODU", time.Now())
	var nf *ErrNotFound
	if !errors.As(err, &nf) {
		t.Fatalf("bulunmayan parametre için ErrNotFound bekleniyordu, gelen: %v", err)
	}
}

// Kanunla sabit bir parametre site bazında geçersiz kılınamamalı (migration 012 tetikleyicisi).
func TestKanunlaSabitParametreSiteBazindaDegistirilemez(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	var propertyID string
	err := pool.QueryRow(ctx, `SELECT id::text FROM properties LIMIT 1`).Scan(&propertyID)
	if err != nil {
		t.Skipf("test için site kaydı yok: %v", err)
	}

	_, err = pool.Exec(ctx, `
		INSERT INTO legal_parameters (property_id, code, value_numeric, unit, legal_basis, effective_from)
		VALUES ($1, $2, 0.20, 'RATIO_PER_MONTH', 'test', DATE '2000-01-01')`,
		propertyID, LateFeeMonthlyRate)
	if err == nil {
		// Temizle ve başarısız say
		_, _ = pool.Exec(ctx, `DELETE FROM legal_parameters WHERE property_id = $1 AND legal_basis = 'test'`, propertyID)
		t.Fatal("kanunla sabit parametre site bazında değiştirilebildi — veritabanı koruması çalışmıyor")
	}
}

// Site bazlı geçersiz kılma, kanunla sabit OLMAYAN parametrelerde çalışmalı ve
// sistem geneli varsayılana tercih edilmeli.
func TestSiteBazliDegerVarsayilaniEzer(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	var propertyID string
	if err := pool.QueryRow(ctx, `SELECT id::text FROM properties LIMIT 1`).Scan(&propertyID); err != nil {
		t.Skipf("test için site kaydı yok: %v", err)
	}

	// AUDIT_INTERVAL_MONTHS kanunla sabit değildir (yönetim planı farklı öngörebilir).
	_, err := pool.Exec(ctx, `
		INSERT INTO legal_parameters (property_id, code, value_numeric, unit, legal_basis, effective_from)
		VALUES ($1, $2, 1, 'MONTH', 'test-yonetim-plani', DATE '2000-01-01')
		ON CONFLICT DO NOTHING`, propertyID, AuditIntervalMonths)
	if err != nil {
		t.Fatalf("site bazlı parametre yazılamadı: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(context.Background(),
			`DELETE FROM legal_parameters WHERE property_id = $1 AND legal_basis = 'test-yonetim-plani'`, propertyID)
	})

	r := NewWithTTL(pool, 0)

	got, err := r.Int(ctx, propertyID, AuditIntervalMonths, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if got != 1 {
		t.Errorf("site bazlı değer uygulanmadı: %d (beklenen 1)", got)
	}

	// Sistem geneli değer değişmemiş olmalı
	global, err := r.Int(ctx, "", AuditIntervalMonths, time.Now())
	if err != nil {
		t.Fatal(err)
	}
	if global != 3 {
		t.Errorf("sistem geneli denetim sıklığı %d, beklenen 3 (KMK m.41)", global)
	}
}

// Yürürlük tarihi: geçmiş bir tarih sorulduğunda o tarihte geçerli olan değer dönmeli.
func TestYururlukTarihiCozumlemesi(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	const code = "TEST_YURURLUK_PARAMETRESI"
	_, err := pool.Exec(ctx, `
		INSERT INTO legal_parameters (code, value_numeric, unit, legal_basis, effective_from, effective_to)
		VALUES ($1, 10, 'RATIO', 'test-eski', DATE '2020-01-01', DATE '2025-01-01'),
		       ($1, 20, 'RATIO', 'test-yeni', DATE '2025-01-01', NULL)
		ON CONFLICT DO NOTHING`, code)
	if err != nil {
		t.Fatalf("test parametreleri yazılamadı: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(context.Background(), `DELETE FROM legal_parameters WHERE code = $1`, code)
	})

	r := NewWithTTL(pool, 0)

	old, err := r.Decimal(ctx, "", code, time.Date(2022, 6, 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatal(err)
	}
	if old.IntPart() != 10 {
		t.Errorf("2022 için %s dönmüş, beklenen 10", old)
	}

	now, err := r.Decimal(ctx, "", code, time.Date(2026, 6, 1, 0, 0, 0, 0, time.UTC))
	if err != nil {
		t.Fatal(err)
	}
	if now.IntPart() != 20 {
		t.Errorf("2026 için %s dönmüş, beklenen 20", now)
	}
}
