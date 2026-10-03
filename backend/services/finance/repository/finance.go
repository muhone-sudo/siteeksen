package repository

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/services/finance/models"
)

// Sentinel hatalar
var (
	ErrExpenseCategoryNotFound = errors.New("gider kalemi bulunamadı")
	ErrAssessmentPeriodExists  = errors.New("bu dönem için tahakkuk zaten oluşturulmuş")
	ErrNoUnitsInProperty       = errors.New("sitede tanımlı birim bulunamadı")
	// ErrInvalidAssessmentInput: istemcinin düzeltebileceği tahakkuk girdisi
	// hatası (vade biçimi, dağıtım yapılamayan kalem). Mesajı istemciye gösterilir;
	// önceden eşleyici HER hatanın ham metnini — veritabanı hataları dahil —
	// istemciye yazıyordu.
	ErrInvalidAssessmentInput = errors.New("tahakkuk girdisi geçersiz")
	// ErrAssessmentNotFound: tahakkuk yok ya da çağıranın dairesine ait değil.
	ErrAssessmentNotFound = errors.New("aidat bulunamadı")

	// ErrAssessmentNotPayable seçilen tahakkuklardan en az biri kullanıcıya ait değil,
	// silinmiş ya da ödenecek bakiyesi yok.
	ErrAssessmentNotPayable = errors.New("seçilen aidatlardan biri ödenebilir durumda değil")
	// ErrNoPayableAssessment ödenecek hiçbir tahakkuk seçilmemiş.
	ErrNoPayableAssessment = errors.New("ödenecek aidat seçilmedi")

	// ErrPaymentNotFound onaylanmak istenen ödeme kaydı yok.
	ErrPaymentNotFound = errors.New("ödeme kaydı bulunamadı")
	// ErrPaymentNotPending ödeme zaten sonuçlanmış (tamamlanmış/iptal edilmiş).
	// Çift onaylamayı engeller.
	ErrPaymentNotPending = errors.New("ödeme onay bekleyen durumda değil")
	// ErrPaymentNotOwned ödeme, onaylayan yöneticinin sitesine ait değil.
	ErrPaymentNotOwned = errors.New("bu ödeme sizin sitenize ait değil")
	// ErrPaymentAlreadyPending seçilen tahakkuklardan biri için onay bekleyen ödeme var.
	ErrPaymentAlreadyPending = errors.New("bu aidat için onay bekleyen bir ödeme zaten var")
)

// FinanceRepository finans veritabanı işlemleri
type FinanceRepository struct {
	pool *pgxpool.Pool
}

// NewFinanceRepository yeni repository oluşturur
func NewFinanceRepository(pool *pgxpool.Pool) *FinanceRepository {
	return &FinanceRepository{pool: pool}
}

// GetUnitBalance sakinin aktif olduğu bağımsız bölümlerin toplam bakiyesini hesaplar.
//
// DÜZELTME (2026-09-09) — önceki sorgu bakiyeyi KULLANICI SAYISIYLA ÇARPIYORDU:
//
//	FROM ledger_lines ll
//	JOIN users u ON ll.unit_id = ( SELECT ru.unit_id ... LIMIT 1 )
//
// Buradaki JOIN koşulu `u` tablosuna hiç referans vermiyor; bu bir CROSS JOIN'dir.
// Eşleşen her `ledger_lines` satırı `users` tablosundaki satır sayısı kadar tekrarlanıyor,
// dolayısıyla SUM sonucu = gerçek bakiye × kullanıcı sayısı. 156 sakinli bir sitede
// 1.200 TL borç sakine 187.200 TL olarak gösteriliyordu. Bu değer doğrudan
// `current_balance` ve `has_debt` alanlarını besliyor (service/finance.go).
//
// Ayrıca `LIMIT 1` ORDER BY'sız kullanıldığı için iki dairesi olan bir sakinin hangi
// dairesinin hesaplandığı belirsizdi; artık sakinin TÜM aktif bağımsız bölümlerinin
// bakiyesi toplanıyor.
//
// Hesap `unit_balances` görünümü üzerinden yapılır (tek doğruluk kaynağı).
// 030'a kadar görünüm hiç yazılmayan `ledger_lines`'tan okuyordu ve herkes için
// 0 dönüyordu; artık tahakkuklardan (`monthly_assessments`) hesaplanır —
// panelin borçlu listesiyle (ListDebtors) aynı kaynak.
func (r *FinanceRepository) GetUnitBalance(ctx context.Context, propertyID, userID string) (float64, error) {
	query := `
		SELECT COALESCE(SUM(ub.balance), 0) AS balance
		FROM unit_balances ub
		WHERE ub.unit_id IN (
			SELECT ru.unit_id
			FROM resident_units ru
			WHERE ru.resident_id = $1 AND ru.is_active = true
		)
	`
	var balance float64
	err := r.scope(propertyID).QueryRow(ctx, query, userID).Scan(&balance)
	return balance, err
}

// GetOverdueInfo gecikmiş borç bilgisi
func (r *FinanceRepository) GetOverdueInfo(ctx context.Context, propertyID, userID string) (*models.OverdueInfo, error) {
	query := `
		SELECT COALESCE(SUM(total_amount - paid_amount), 0), COUNT(*)
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.due_date < CURRENT_DATE
		  AND ma.status != 'PAID'
		  AND ma.deleted = 0
	`
	info := &models.OverdueInfo{}
	err := r.scope(propertyID).QueryRow(ctx, query, userID).Scan(&info.Amount, &info.Months)
	return info, err
}

// GetNextDueAssessment sonraki vadeli aidat
func (r *FinanceRepository) GetNextDueAssessment(ctx context.Context, propertyID, userID string) (*models.Assessment, error) {
	query := `
		SELECT ma.id, ma.total_amount, ma.due_date
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.due_date >= CURRENT_DATE
		  AND ma.status != 'PAID'
		  AND ma.deleted = 0
		ORDER BY ma.due_date ASC
		LIMIT 1
	`
	a := &models.Assessment{}
	err := r.scope(propertyID).QueryRow(ctx, query, userID).Scan(&a.ID, &a.TotalAmount, &a.DueDate)
	return a, err
}

// GetAssessments yıllık aidat listesi
func (r *FinanceRepository) GetAssessments(ctx context.Context, propertyID, userID string, year int) ([]models.AssessmentSummary, error) {
	query := `
		SELECT ma.id, 
			   TO_CHAR(MAKE_DATE(ma.period_year, ma.period_month, 1), 'YYYY-MM'),
			   ma.base_amount, ma.late_fee, ma.total_amount, 
			   COALESCE(ma.paid_amount, 0), ma.status
		FROM monthly_assessments ma
		JOIN resident_units ru ON ma.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND ma.period_year = $2
		  AND ma.deleted = 0
		ORDER BY ma.period_month DESC
	`
	rows, err := r.scope(propertyID).Query(ctx, query, userID, year)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	assessments := []models.AssessmentSummary{}
	for rows.Next() {
		var a models.AssessmentSummary
		if err := rows.Scan(&a.ID, &a.Period, &a.BaseAmount, &a.LateFee, &a.TotalAmount, &a.PaidAmount, &a.Status); err != nil {
			return nil, err
		}
		assessments = append(assessments, a)
	}
	return assessments, nil
}

// ListAssessmentPeriods site genelinde dönem bazlı tahakkuk/tahsilat özetini listeler (yönetim görünümü)
func (r *FinanceRepository) ListAssessmentPeriods(ctx context.Context, propertyID string, year int) ([]models.AssessmentPeriodSummary, error) {
	// Oran ve durum SQL'de, numeric ile hesaplanır (2026-10-03, B54). Önceden
	// `int(c / t * 100)` kullanılıyordu: kayan nokta hatası tam yüzdeleri de bir
	// aşağı kesiyordu (29/100 → 28,999… → %28) ve %99,9 → %99 oluyordu. Oran
	// tek ondalığa AŞAĞI yuvarlanır: 1 kuruş bile açık kalan dönem %100 görünmez.
	// "completed" yalnızca tahsilat tahakkuka KESİN olarak ulaştığında.
	query := `
		SELECT TO_CHAR(MAKE_DATE(ma.period_year, ma.period_month, 1), 'YYYY-MM'),
		       MIN(ma.due_date), SUM(ma.total_amount), SUM(COALESCE(ma.paid_amount, 0)),
		       COALESCE(floor(SUM(COALESCE(ma.paid_amount, 0)) * 1000
		                      / NULLIF(SUM(ma.total_amount), 0)) / 10, 0)::float8,
		       SUM(COALESCE(ma.paid_amount, 0)) >= SUM(ma.total_amount)
		FROM monthly_assessments ma
		WHERE ma.property_id = $1 AND ma.period_year = $2 AND ma.deleted = 0
		GROUP BY ma.period_year, ma.period_month
		ORDER BY ma.period_month DESC
	`
	rows, err := r.scope(propertyID).Query(ctx, query, propertyID, year)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	periods := []models.AssessmentPeriodSummary{}
	for rows.Next() {
		var p models.AssessmentPeriodSummary
		var completed bool
		if err := rows.Scan(&p.Period, &p.DueDate, &p.TotalAmount, &p.CollectedAmount,
			&p.Rate, &completed); err != nil {
			return nil, err
		}
		p.Status = "active"
		if completed {
			p.Status = "completed"
		}
		periods = append(periods, p)
	}
	return periods, rows.Err()
}

// GetAssessmentDetails aidat detayı
//
// residentID doluysa (yönetim OLMAYAN çağıran) yalnızca kişinin AKTİF
// dairesinin tahakkuku döner. Önceden sahiplik denetimi yoktu: sitedeki her
// sakin, kimliğini bildiği her dairenin borç dökümünü okuyabiliyordu.
// Ayrıca `paid_amount` okunmuyor, her zaman 0 görünüyordu.
func (r *FinanceRepository) GetAssessmentDetails(ctx context.Context, propertyID, residentID, assessmentID string) (*models.AssessmentDetail, error) {
	// Ana aidat bilgisi
	query := `
		SELECT ma.id, ma.property_id, ma.unit_id, ma.period_year, ma.period_month,
			   ma.base_amount, ma.late_fee, ma.total_amount, COALESCE(ma.paid_amount, 0),
			   ma.due_date, ma.status, ma.created_at
		FROM monthly_assessments ma
		WHERE ma.id = $1 AND ma.deleted = 0
		  AND ($2 = '' OR ma.unit_id IN (SELECT ru.unit_id FROM resident_units ru
		                                 WHERE ru.resident_id = NULLIF($2,'')::uuid AND ru.is_active = true))
	`
	detail := &models.AssessmentDetail{}
	err := r.scope(propertyID).QueryRow(ctx, query, assessmentID, residentID).Scan(
		&detail.ID, &detail.PropertyID, &detail.UnitID, &detail.PeriodYear, &detail.PeriodMonth,
		&detail.BaseAmount, &detail.LateFee, &detail.TotalAmount, &detail.PaidAmount,
		&detail.DueDate, &detail.Status, &detail.CreatedAt,
	)
	if err == pgx.ErrNoRows {
		return nil, ErrAssessmentNotFound
	}
	if err != nil {
		return nil, err
	}

	// Detay kalemleri
	detailQuery := `
		SELECT ec.name, ad.amount, ad.calculation_basis
		FROM assessment_details ad
		JOIN expense_categories ec ON ad.expense_category_id = ec.id
		WHERE ad.assessment_id = $1
	`
	rows, err := r.scope(propertyID).Query(ctx, detailQuery, assessmentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var item models.AssessmentDetailItem
		if err := rows.Scan(&item.Category, &item.Amount, &item.CalculationBasis); err != nil {
			return nil, err
		}
		detail.Details = append(detail.Details, item)
	}

	return detail, nil
}

// CreatePayment ödeme kaydını ve ödeme-tahakkuk ilişkilerini TEK TRANSACTION içinde oluşturur.
// Ödenecek toplam tutarı kendisi hesaplar ve geri döndürür.
//
// DÜZELTME (2026-09-09) — önceki sürümdeki sorunlar:
//
//  1. TRANSACTION YOKTU: `payments` satırı yazılıp `payment_assessments` yazılamazsa yarım
//     kayıt kalıyordu.
//  2. HATA YUTULUYORDU: `r.scope(propertyID).Exec(ctx, linkQuery, ...)` dönüş değeri hiç atanmıyordu →
//     yabancı anahtar ihlali veya mükerrer birincil anahtar hatası sessizce kayboluyordu.
//  3. `payment_assessments.amount` HİÇ YAZILMIYORDU (sütun mevcut) → hangi tahakkuğa ne kadar
//     düştüğü kayıtsızdı, mutabakat yapılamıyordu.
//  4. SAHİPLİK DOĞRULANMIYORDU: `CalculateTotalAmount` yalnızca `WHERE id = ANY($1)` ile
//     çalışıyordu; kullanıcı BAŞKASININ tahakkuk kimliklerini gönderip tutarını öğrenebiliyor
//     ve o tahakkuklara kendi ödemesini bağlayabiliyordu (IDOR).
//  5. `deleted = 0` FİLTRESİ YOKTU → silinmiş tahakkuklar için ödeme alınabiliyordu.
//  6. Tutar hesaplama ile kayıt ayrı sorgulardaydı; arada tahakkuk değişirse tutarsızlık
//     oluşuyordu. Artık ikisi aynı transaction içinde ve satırlar `FOR UPDATE` ile kilitli.
//
// Not: `monthly_assessments.paid_amount` bu aşamada GÜNCELLENMEZ. Ödeme `PENDING` durumunda
// oluşturulur; borç düşümü, ödeme sağlayıcısından onay geldiğinde yapılmalıdır. Bu akış henüz
// yazılmadığı için (ödeme sağlayıcısı entegrasyonu yok — bkz. tasks/questions.md S-06)
// ödenen tutar borçtan düşmez. Bu bilinen ve dokümante edilmiş bir eksiktir
// (tasks/gap-analizi.md B46), sessiz bir hata değildir.
func (r *FinanceRepository) CreatePayment(
	ctx context.Context,
	propertyID, userID string,
	assessmentIDs []string,
	method string,
) (string, float64, error) {
	if len(assessmentIDs) == 0 {
		return "", 0, ErrNoPayableAssessment
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // commit başarılıysa no-op

	// Yalnızca çağıran kullanıcıya ait, AKTİF SİTEDEKİ, silinmemiş ve ödenecek bakiyesi olan
	// tahakkukları al. FOR UPDATE: tutar hesaplandıktan sonra commit'e kadar satırlar kilitli kalır.
	//
	// `ma.property_id = $3` (2026-09-26): önceden yoktu. İki sitede dairesi olan bir sakin, A
	// sitesi aktifken B'nin tahakkuklarını tek ödemeye bağlayabiliyordu; ödeme hangi sitenin
	// yöneticisine düşeceği belirsiz bir kayıt olarak kalıyordu.
	rows, err := tx.Query(ctx, `
		SELECT ma.id, (ma.total_amount - COALESCE(ma.paid_amount, 0)) AS remaining, ma.unit_id
		FROM monthly_assessments ma
		JOIN resident_units ru ON ru.unit_id = ma.unit_id AND ru.is_active = true
		WHERE ma.id = ANY($1)
		  AND ru.resident_id = $2
		  AND ma.property_id = $3
		  AND ma.deleted = 0
		FOR UPDATE OF ma
	`, assessmentIDs, userID, propertyID)
	if err != nil {
		return "", 0, err
	}

	type payable struct {
		id        string
		remaining float64
		unitID    string
	}
	items := []payable{}
	for rows.Next() {
		var p payable
		if err := rows.Scan(&p.id, &p.remaining, &p.unitID); err != nil {
			rows.Close()
			return "", 0, err
		}
		items = append(items, p)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return "", 0, err
	}

	// İstenen tahakkukların hepsi kullanıcıya ait ve ödenebilir olmalı.
	if len(items) != len(assessmentIDs) {
		return "", 0, ErrAssessmentNotPayable
	}

	// ÇİFT GÖNDERİM (2026-10-03, roadmap 4.5): önceden aynı tahakkuk için ikinci
	// bir PENDING ödeme açılabiliyordu (çift dokunma, ağ zaman aşımında yeniden
	// deneme). Yönetici ikisini de onaylarsa borç İKİ KEZ düşer ve sakin fazla
	// ödemiş görünürdü. Tahakkuk satırları yukarıda FOR UPDATE ile kilitli
	// olduğundan eşzamanlı iki istek bu denetimi sırayla görür.
	var pending bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS (
			SELECT 1 FROM payment_assessments pa
			JOIN payments p ON p.id = pa.payment_id
			WHERE pa.assessment_id = ANY($1) AND p.status = 'PENDING')`,
		assessmentIDs).Scan(&pending); err != nil {
		return "", 0, err
	}
	if pending {
		return "", 0, ErrPaymentAlreadyPending
	}

	var total float64
	sameUnit := true
	for i, p := range items {
		if p.remaining <= 0 {
			return "", 0, ErrAssessmentNotPayable
		}
		total += p.remaining
		if i > 0 && p.unitID != items[0].unitID {
			sameUnit = false
		}
	}
	if total <= 0 {
		return "", 0, ErrNoPayableAssessment
	}

	// Tüm tahakkuklar aynı bağımsız bölüme aitse ödemeyi o birimle ilişkilendir.
	// (payments.unit_id daha önce hiç doldurulmuyordu; site bazlı ödeme raporlarının
	//  doğru çalışabilmesi için gerekli — bkz. gap-analizi.md B56.)
	var unitID *string
	if sameUnit {
		unitID = &items[0].unitID
	}

	paymentID := uuid.New().String()
	if _, err := tx.Exec(ctx, `
		INSERT INTO payments (id, property_id, user_id, unit_id, amount, payment_method, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, 'PENDING', NOW())
	`, paymentID, propertyID, userID, unitID, total, method); err != nil {
		return "", 0, err
	}

	for _, p := range items {
		if _, err := tx.Exec(ctx, `
			INSERT INTO payment_assessments (payment_id, assessment_id, amount)
			VALUES ($1, $2, $3)
		`, paymentID, p.id, p.remaining); err != nil {
			return "", 0, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", 0, err
	}
	return paymentID, total, nil
}

// ConfirmPayment, bekleyen bir ödemeyi TAMAMLANDI olarak işaretler ve ilgili
// tahakkukların ödenen tutarını günceller.
//
// NEDEN VAR (2026-09-13, todo 4.2 / gap-analizi B46):
// Ödeme akışı `monthly_assessments.paid_amount` alanını HİÇ güncellemiyordu.
// Sonuç: ödemesini yapan sakin sistemde sonsuza dek borçlu görünüyor, gecikme
// tazminatı işlemeye devam ediyor ve borçlu listesinden düşmüyordu. Bu, para
// ile ilgili en ağır hatalardan biridir.
//
// Ödeme sağlayıcısı entegrasyonu henüz yok (questions.md S-06). Türkiye'deki
// site yönetimlerinin büyük kısmı zaten havale/EFT ile tahsil ettiği için,
// tahsilatı YÖNETİCİNİN ONAYLAMASI gerçek bir iş akışıdır ve bu fonksiyon onu
// karşılar. Sağlayıcı entegrasyonu geldiğinde aynı fonksiyon webhook'tan da
// çağrılabilir.
//
// Garantiler:
//   - Tek transaction; ödeme satırı `FOR UPDATE` ile kilitli.
//   - Yalnızca `PENDING` ödeme onaylanabilir → çift onay (idempotency ihlali) engellenir.
//   - Onaylayan kişi, ödemenin ait olduğu SİTENİN yöneticisi olmalıdır.
//   - `paid_amount` artırılır, `status` PARTIAL/PAID olarak yeniden hesaplanır.
func (r *FinanceRepository) ConfirmPayment(
	ctx context.Context,
	paymentID, propertyID, reference string,
) error {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck // commit başarılıysa no-op

	var status string
	err = tx.QueryRow(ctx,
		`SELECT status FROM payments WHERE id = $1 FOR UPDATE`, paymentID).Scan(&status)
	if err == pgx.ErrNoRows {
		return ErrPaymentNotFound
	}
	if err != nil {
		return err
	}
	if status != "PENDING" {
		return ErrPaymentNotPending
	}

	// Ödemenin bağlı olduğu tahakkuklar onaylayanın sitesine ait mi?
	// Aksi hâlde bir sitenin yöneticisi başka sitenin ödemesini onaylayabilirdi.
	var foreign int
	err = tx.QueryRow(ctx, `
		SELECT count(*)
		FROM payment_assessments pa
		JOIN monthly_assessments ma ON ma.id = pa.assessment_id
		WHERE pa.payment_id = $1 AND ma.property_id <> $2`, paymentID, propertyID).Scan(&foreign)
	if err != nil {
		return err
	}
	if foreign > 0 {
		return ErrPaymentNotOwned
	}

	// Tahakkukları güncelle. paid_amount artırılır; durum yeniden hesaplanır.
	// GREATEST/LEAST kullanılmaz: fazla ödeme (paid > total) bir veri hatasıdır,
	// gizlenmemeli — bu durumda status PAID olur ve fark raporlarda görünür.
	tag, err := tx.Exec(ctx, `
		UPDATE monthly_assessments ma
		SET paid_amount = COALESCE(ma.paid_amount, 0) + pa.amount,
		    status = CASE
		        WHEN COALESCE(ma.paid_amount, 0) + pa.amount >= ma.total_amount THEN 'PAID'
		        ELSE 'PARTIAL'
		    END,
		    updated_at = NOW()
		FROM payment_assessments pa
		WHERE pa.payment_id = $1 AND ma.id = pa.assessment_id AND ma.deleted = 0`, paymentID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNoPayableAssessment
	}

	if _, err := tx.Exec(ctx, `
		UPDATE payments
		SET status = 'COMPLETED', completed_at = NOW(), transaction_id = NULLIF($2, '')
		WHERE id = $1`, paymentID, reference); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// RejectPayment, bekleyen bir ödemeyi başarısız olarak işaretler.
// Tahakkuklar değişmez; borç olduğu gibi kalır.
func (r *FinanceRepository) RejectPayment(ctx context.Context, paymentID, propertyID string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE payments p
		SET status = 'FAILED', completed_at = NOW()
		WHERE p.id = $1
		  AND p.status = 'PENDING'
		  AND EXISTS (
			SELECT 1 FROM payment_assessments pa
			JOIN monthly_assessments ma ON ma.id = pa.assessment_id
			WHERE pa.payment_id = p.id AND ma.property_id = $2
		  )`, paymentID, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		// Yoksa 404, varsa (onaylanmış/reddedilmiş) 409. Önceden ikisi de 409'du.
		if ok, err := r.scope(propertyID).Exists(ctx, "payments", paymentID); err != nil {
			return err
		} else if !ok {
			return ErrPaymentNotFound
		}
		return ErrPaymentNotPending
	}
	return nil
}

// ListPendingPayments, yöneticinin onay bekleyen ödemelerini getirir.
func (r *FinanceRepository) ListPendingPayments(ctx context.Context, propertyID string) ([]models.PropertyPayment, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT DISTINCT p.id,
		       COALESCE(u.first_name || ' ' || u.last_name, ''),
		       COALESCE(un.block || '-' || un.door_number, ''),
		       p.amount, p.payment_method, p.status, p.created_at
		FROM payments p
		JOIN payment_assessments pa ON pa.payment_id = p.id
		JOIN monthly_assessments ma ON ma.id = pa.assessment_id
		LEFT JOIN users u ON u.id = p.user_id
		LEFT JOIN units un ON un.id = p.unit_id
		WHERE ma.property_id = $1 AND p.status = 'PENDING'
		ORDER BY p.created_at DESC`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	payments := []models.PropertyPayment{}
	for rows.Next() {
		var p models.PropertyPayment
		if err := rows.Scan(&p.ID, &p.Name, &p.Unit, &p.Amount,
			&p.PaymentMethod, &p.Status, &p.CreatedAt); err != nil {
			return nil, err
		}
		payments = append(payments, p)
	}
	return payments, rows.Err()
}

// OverdueAssessment, gecikme tazminatı hesabı için gereken asgari alanlardır.
type OverdueAssessment struct {
	ID             string
	PrincipalKurus int64
	OverdueDays    int
	BaseAmount     float64
	PaidAmount     float64
}

// ListOverdueForLateFee, gecikme tazminatı işletilecek tahakkukları getirir.
//
// Anapara = ödenmemiş ASIL borçtur; daha önce işletilmiş gecikme tazminatı anaparaya
// dahil edilmez. Aksi hâlde tazminat üzerinden tazminat (bileşik faiz) işlemiş olurdu;
// KMK m.20/2 buna dayanak vermez.
func (r *FinanceRepository) ListOverdueForLateFee(ctx context.Context, propertyID string, asOf time.Time) ([]OverdueAssessment, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id,
		       GREATEST(round((base_amount - LEAST(COALESCE(paid_amount,0), base_amount)) * 100), 0)::bigint,
		       ($2::date - due_date)::int,
		       base_amount, COALESCE(paid_amount, 0)
		FROM monthly_assessments
		WHERE property_id = $1
		  AND deleted = 0
		  AND due_date < $2::date
		  AND total_amount > COALESCE(paid_amount, 0)
		ORDER BY due_date`, propertyID, asOf)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []OverdueAssessment{}
	for rows.Next() {
		var a OverdueAssessment
		if err := rows.Scan(&a.ID, &a.PrincipalKurus, &a.OverdueDays, &a.BaseAmount, &a.PaidAmount); err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// ApplyLateFee, hesaplanan gecikme tazminatını tahakkuka işler ve izini bırakır.
//
// ÖNEMLİ: `late_fee` ARTIRILMAZ, YENİDEN YAZILIR. Tazminat (anapara, gün, oran)
// fonksiyonudur; her çalıştırmada baştan hesaplanır. Artımlı toplama yapılsaydı
// iş iki kez çalıştığında borç iki katına çıkardı.
//
// `late_fee_accruals` tablosundaki (assessment_id, accrued_on) benzersizliği,
// aynı gün ikinci çalıştırmanın yeni bir iz kaydı üretmesini engeller; hesabın
// kendisi zaten idempotenttir.
func (r *FinanceRepository) ApplyLateFee(
	ctx context.Context,
	propertyID, assessmentID string,
	asOf time.Time,
	overdueDays int,
	principalKurus, feeKurus int64,
	monthlyRate string,
) error {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	if _, err := tx.Exec(ctx, `
		UPDATE monthly_assessments
		SET late_fee = $2::numeric / 100,
		    total_amount = base_amount + ($2::numeric / 100),
		    status = CASE
		        WHEN COALESCE(paid_amount,0) >= base_amount + ($2::numeric / 100) THEN 'PAID'
		        WHEN COALESCE(paid_amount,0) > 0 THEN 'PARTIAL'
		        ELSE 'OVERDUE'
		    END,
		    updated_at = NOW()
		WHERE id = $1 AND deleted = 0`, assessmentID, feeKurus); err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO late_fee_accruals
			(assessment_id, accrued_on, overdue_days, principal_kurus, monthly_rate, fee_kurus)
		VALUES ($1, $2::date, $3, $4, $5::numeric, $6)
		ON CONFLICT (assessment_id, accrued_on) DO UPDATE
		SET overdue_days = EXCLUDED.overdue_days,
		    principal_kurus = EXCLUDED.principal_kurus,
		    monthly_rate = EXCLUDED.monthly_rate,
		    fee_kurus = EXCLUDED.fee_kurus`,
		assessmentID, asOf, overdueDays, principalKurus, monthlyRate, feeKurus); err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// GetPaymentHistory ödeme geçmişi
func (r *FinanceRepository) GetPaymentHistory(ctx context.Context, propertyID, userID string) ([]models.Payment, error) {
	query := `
		SELECT id, user_id, amount, payment_method, status, transaction_id, created_at, completed_at
		FROM payments
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 50
	`
	rows, err := r.scope(propertyID).Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	payments := []models.Payment{}
	for rows.Next() {
		var p models.Payment
		var txID, completedAt interface{}
		if err := rows.Scan(&p.ID, &p.UserID, &p.Amount, &p.PaymentMethod, &p.Status, &txID, &p.CreatedAt, &completedAt); err != nil {
			return nil, err
		}
		if txID != nil {
			p.TransactionID = txID.(string)
		}
		if completedAt != nil {
			p.CompletedAt = completedAt.(time.Time)
		}
		payments = append(payments, p)
	}
	return payments, nil
}

// ListDebtors sitede borcu olan DAİRELERİ borç tutarına göre listeler (yönetim görünümü).
//
// DÜZELTME (2026-10-03, B55): liste aktif MALİK üzerinden kuruluyordu:
//   - maliki sisteme kayıtlı olmayan dairenin borcu listede HİÇ görünmüyordu;
//   - iki malikli (hisseli) dairenin borcu her malik için ayrı satırda, yani
//     İKİ KEZ çıkıyordu — listenin toplamı gerçek alacaktan büyüktü.
//
// Artık her borçlu daire tek satırdır ve tutar daireye aittir. Kişi alanı aktif
// maliklerdir (virgülle); malik kayıtlı değilse sakin/kiracı gösterilir ve bu
// işaretlenir (KMK m.22: kiracı ortak giderden malikle birlikte sorumludur ama
// asıl borçlu malik değildir); kimse kayıtlı değilse bu açıkça yazılır. Vekil
// (PROXY) borçlu sayılmaz.
func (r *FinanceRepository) ListDebtors(ctx context.Context, propertyID string) ([]models.Debtor, error) {
	query := `
		WITH debt AS (
			SELECT ma.unit_id, SUM(ma.total_amount - COALESCE(ma.paid_amount, 0)) AS amount
			FROM monthly_assessments ma
			WHERE ma.property_id = $1 AND ma.deleted = 0
			  AND ma.total_amount > COALESCE(ma.paid_amount, 0)
			GROUP BY ma.unit_id
		)
		SELECT d.unit_id::text,
		       COALESCE(p.resident_id, ''),
		       COALESCE(p.names, 'Kayıtlı malik/sakin yok'),
		       COALESCE(un.block, '') || ' Blok D.' || un.door_number,
		       d.amount
		FROM debt d
		JOIN units un ON un.id = d.unit_id
		LEFT JOIN LATERAL (
			SELECT (array_agg(u.id::text ORDER BY u.last_name, u.first_name))[1] AS resident_id,
			       string_agg(u.first_name || ' ' || u.last_name, ', ' ORDER BY u.last_name, u.first_name)
			         || CASE WHEN bool_and(ru.role <> 'OWNER') THEN ' (malik kayıtlı değil)' ELSE '' END AS names
			FROM resident_units ru
			JOIN users u ON u.id = ru.resident_id
			WHERE ru.unit_id = un.id AND ru.is_active = true AND ru.role <> 'PROXY'
			  AND (ru.role = 'OWNER' OR NOT EXISTS (
			        SELECT 1 FROM resident_units o
			        WHERE o.unit_id = un.id AND o.is_active = true AND o.role = 'OWNER'))
		) p ON true
		ORDER BY d.amount DESC, un.block, un.door_number
	`
	rows, err := r.scope(propertyID).Query(ctx, query, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	debtors := []models.Debtor{}
	for rows.Next() {
		var d models.Debtor
		if err := rows.Scan(&d.UnitID, &d.ResidentID, &d.Name, &d.Unit, &d.Amount); err != nil {
			return nil, err
		}
		debtors = append(debtors, d)
	}
	return debtors, rows.Err()
}

// ListPropertyPayments sitedeki tüm sakinlerin ödeme kayıtlarını listeler (yönetim görünümü)
func (r *FinanceRepository) ListPropertyPayments(ctx context.Context, propertyID string) ([]models.PropertyPayment, error) {
	query := `
		SELECT p.id, p.user_id, p.amount, p.payment_method, p.status, COALESCE(p.transaction_id, ''),
		       p.created_at, p.completed_at,
		       u.first_name, u.last_name,
		       COALESCE(COALESCE(un.block, '') || ' Blok D.' || un.door_number, '')
		FROM payments p
		JOIN users u ON u.id = p.user_id
		LEFT JOIN units un ON un.id = (
			SELECT ru.unit_id FROM resident_units ru
			WHERE ru.resident_id = u.id AND ru.is_active = true
			LIMIT 1
		)
		WHERE p.deleted = 0 AND EXISTS (
			SELECT 1 FROM resident_units ru2
			JOIN units un2 ON un2.id = ru2.unit_id
			WHERE ru2.resident_id = u.id AND ru2.is_active = true AND un2.property_id = $1
		)
		ORDER BY p.created_at DESC
		LIMIT 50
	`
	rows, err := r.scope(propertyID).Query(ctx, query, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	payments := []models.PropertyPayment{}
	for rows.Next() {
		var pp models.PropertyPayment
		var firstName, lastName string
		var txID, completedAt interface{}
		if err := rows.Scan(&pp.ID, &pp.UserID, &pp.Amount, &pp.PaymentMethod, &pp.Status, &txID,
			&pp.CreatedAt, &completedAt, &firstName, &lastName, &pp.Unit); err != nil {
			return nil, err
		}
		if txID != nil {
			pp.TransactionID = txID.(string)
		}
		if completedAt != nil {
			pp.CompletedAt = completedAt.(time.Time)
		}
		pp.Name = firstName + " " + lastName
		payments = append(payments, pp)
	}
	return payments, nil
}

// GetConsumptionData tüketim verisi (grafik için)
func (r *FinanceRepository) GetConsumptionData(ctx context.Context, propertyID, userID, meterType string, months int) ([]models.ConsumptionData, error) {
	query := `
		SELECT TO_CHAR(ci.period_start, 'YYYY-MM'), ci.consumption_amount, ci.total_amount, ci.status
		FROM consumption_invoices ci
		JOIN meters m ON ci.meter_id = m.id
		JOIN resident_units ru ON m.unit_id = ru.unit_id
		WHERE ru.resident_id = $1 
		  AND ru.is_active = true
		  AND m.meter_type = $2
		ORDER BY ci.period_start DESC
		LIMIT $3
	`
	rows, err := r.scope(propertyID).Query(ctx, query, userID, meterType, months)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	data := []models.ConsumptionData{}
	for rows.Next() {
		var d models.ConsumptionData
		if err := rows.Scan(&d.Period, &d.Consumption, &d.Amount, &d.Status); err != nil {
			return nil, err
		}
		data = append(data, d)
	}

	// Ters çevir (eskiden yeniye)
	for i, j := 0, len(data)-1; i < j; i, j = i+1, j-1 {
		data[i], data[j] = data[j], data[i]
	}

	return data, nil
}

// unitShare tahakkuk dağıtım hesabı için birim bilgisi
type unitShare struct {
	id            string
	shareRatio    float64
	grossAreaM2   float64
	isCommercial  bool
	isGroundFloor bool
}

// assessmentDetailRow birime düşen gider kalemi payı
type assessmentDetailRow struct {
	unitID           string
	categoryID       string
	amount           float64
	calculationBasis string
	shareValue       float64
}

// CreateAssessment dönem için site genelinde aidat tahakkuku oluşturur.
// Her gider kalemini, kategorinin dağıtım yöntemine (SHARE_RATIO/EQUAL/AREA_M2)
// göre uygun birimlere paylaştırır ve her birim için tek bir monthly_assessments
// kaydı + ilgili assessment_details satırlarını tek transaction'da yazar.
func (r *FinanceRepository) CreateAssessment(ctx context.Context, propertyID string, input models.CreateAssessmentInput) ([]models.AssessmentSummary, error) {
	dueDate, err := time.Parse("2006-01-02", input.DueDate)
	if err != nil {
		return nil, fmt.Errorf("%w: geçersiz vade tarihi formatı (YYYY-MM-DD bekleniyor)", ErrInvalidAssessmentInput)
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
		SELECT id, share_ratio, COALESCE(gross_area_m2, 0), is_commercial, is_ground_floor
		FROM units WHERE property_id = $1 AND deleted = 0
	`, propertyID)
	if err != nil {
		return nil, err
	}
	units := []unitShare{}
	for rows.Next() {
		var u unitShare
		if err := rows.Scan(&u.id, &u.shareRatio, &u.grossAreaM2, &u.isCommercial, &u.isGroundFloor); err != nil {
			rows.Close()
			return nil, err
		}
		units = append(units, u)
	}
	rows.Close()
	if len(units) == 0 {
		return nil, ErrNoUnitsInProperty
	}

	unitTotals := make(map[string]float64, len(units))
	details := []assessmentDetailRow{}

	for _, item := range input.ExpenseItems {
		var distType string
		var appliesCommercial, appliesGround bool
		err := tx.QueryRow(ctx, `
			SELECT distribution_type, applies_to_commercial, applies_to_ground_floor
			FROM expense_categories WHERE id = $1 AND property_id = $2 AND is_active = true
		`, item.CategoryID, propertyID).Scan(&distType, &appliesCommercial, &appliesGround)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrExpenseCategoryNotFound
		}
		if err != nil {
			return nil, err
		}

		eligible := make([]unitShare, 0, len(units))
		for _, u := range units {
			if u.isCommercial && !appliesCommercial {
				continue
			}
			if u.isGroundFloor && !appliesGround {
				continue
			}
			eligible = append(eligible, u)
		}
		if len(eligible) == 0 {
			continue
		}

		switch distType {
		case "EQUAL":
			share := item.Amount / float64(len(eligible))
			basisValue := 1.0 / float64(len(eligible))
			for _, u := range eligible {
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "EQUAL", basisValue})
			}
		case "AREA_M2":
			var totalArea float64
			for _, u := range eligible {
				totalArea += u.grossAreaM2
			}
			if totalArea == 0 {
				return nil, fmt.Errorf("%w: '%s' kalemi metrekareye göre dağıtılamıyor: birimlerde alan bilgisi yok", ErrInvalidAssessmentInput, item.CategoryID)
			}
			for _, u := range eligible {
				ratio := u.grossAreaM2 / totalArea
				share := item.Amount * ratio
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "AREA_M2", ratio})
			}
		default: // SHARE_RATIO ve henüz desteklenmeyen yöntemler (METER_READING/CUSTOM) arsa payına göre paylaştırılır
			var totalRatio float64
			for _, u := range eligible {
				totalRatio += u.shareRatio
			}
			if totalRatio == 0 {
				return nil, fmt.Errorf("%w: '%s' kalemi arsa payına göre dağıtılamıyor: birimlerde arsa payı bilgisi yok", ErrInvalidAssessmentInput, item.CategoryID)
			}
			for _, u := range eligible {
				ratio := u.shareRatio / totalRatio
				share := item.Amount * ratio
				unitTotals[u.id] += share
				details = append(details, assessmentDetailRow{u.id, item.CategoryID, share, "SHARE_RATIO", ratio})
			}
		}
	}

	period := fmt.Sprintf("%04d-%02d", input.PeriodYear, input.PeriodMonth)
	assessmentIDs := make(map[string]string, len(unitTotals))
	for unitID, total := range unitTotals {
		id := uuid.New().String()
		_, err := tx.Exec(ctx, `
			INSERT INTO monthly_assessments (id, property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
			VALUES ($1, $2, $3, $4, $5, $6, $6, $7, 'PENDING')
		`, id, propertyID, unitID, input.PeriodYear, input.PeriodMonth, total, dueDate)
		if err != nil {
			var pgErr *pgconn.PgError
			if errors.As(err, &pgErr) && pgErr.Code == "23505" {
				return nil, ErrAssessmentPeriodExists
			}
			return nil, err
		}
		assessmentIDs[unitID] = id
	}

	for _, d := range details {
		_, err := tx.Exec(ctx, `
			INSERT INTO assessment_details (id, assessment_id, expense_category_id, amount, calculation_basis, share_value)
			VALUES ($1, $2, $3, $4, $5, $6)
		`, uuid.New().String(), assessmentIDs[d.unitID], d.categoryID, d.amount, d.calculationBasis, d.shareValue)
		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	summaries := make([]models.AssessmentSummary, 0, len(assessmentIDs))
	for unitID, id := range assessmentIDs {
		summaries = append(summaries, models.AssessmentSummary{
			ID:          id,
			Period:      period,
			BaseAmount:  unitTotals[unitID],
			TotalAmount: unitTotals[unitID],
			Status:      "PENDING",
		})
	}
	return summaries, nil
}

// ListExpenseCategories sitenin gider kalemlerini sıralı şekilde listeler
func (r *FinanceRepository) ListExpenseCategories(ctx context.Context, propertyID string) ([]models.ExpenseCategory, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT id, property_id, name, distribution_type, applies_to_commercial, applies_to_ground_floor,
		       COALESCE(custom_formula::text, ''), is_active
		FROM expense_categories
		WHERE property_id = $1 AND is_active = true
		ORDER BY sort_order, name
	`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	categories := []models.ExpenseCategory{}
	for rows.Next() {
		var ec models.ExpenseCategory
		if err := rows.Scan(&ec.ID, &ec.PropertyID, &ec.Name, &ec.DistributionType,
			&ec.AppliesToCommercial, &ec.AppliesToGroundFloor, &ec.CustomFormula, &ec.IsActive); err != nil {
			return nil, err
		}
		categories = append(categories, ec)
	}
	return categories, nil
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// finance-service, sakin uçlarında sorguyu kullanıcı kimliğiyle daraltıyordu
// (`WHERE resident_id = $1`). Bu, doğru sonucu veriyordu ama izolasyonu
// TAMAMEN uygulama katmanına bırakıyordu: tek bir sorguda filtre unutulsa
// başka sitenin aidatı görünürdü ve bunu yakalayan hiçbir şey yoktu.
//
// Kapsam, satır düzeyi güvenliği tarafından okunur. Sakin uçlarına da kapsam
// verilmesinin sebebi budur; kullanıcı kimliği zaten tek siteye işaret etse
// bile, koruma o varsayıma DEĞİL veritabanına dayanmalıdır.
func (r *FinanceRepository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
