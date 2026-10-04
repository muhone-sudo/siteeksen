// Package legalparams, mevzuata bağlı parametreleri (gecikme tazminatı oranı, ısıtma
// gider paylaşım oranları, genel kurul nisapları, vekâlet sınırları …) veritabanından
// okur.
//
// NEDEN VAR (tasks/questions.md S-05):
// Bu değerler doğrudan para hesabına ve karar geçerliliğine girer. Koda gömüldüklerinde
// mevzuat değişikliği kod değişikliği + yeniden dağıtım gerektirir; ayrıca geçmiş
// dönemlerin hangi oranla hesaplandığı kaybolur. Parametreler `legal_parameters`
// tablosunda YÜRÜRLÜK TARİHLİ tutulur; bu paket doğru tarihe ait değeri getirir.
//
// Çözümleme sırası:
//  1. İlgili siteye (property_id) ait, tarihe uyan kayıt
//  2. Yoksa sistem geneli (property_id IS NULL) kayıt
//  3. O da yoksa hata — SESSİZ VARSAYILAN YOKTUR.
//
// Üçüncü madde bilinçlidir: parametre bulunamadığında "0" ya da "makul bir değer"
// varsaymak, sessizce yanlış tahakkuk üretmenin en kolay yoludur.
package legalparams

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Bilinen parametre kodları. Kod adını elle yazmak yerine bunları kullanın;
// yazım hatası derleme zamanında yakalanır.
const (
	LateFeeMonthlyRate = "LATE_FEE_MONTHLY_RATE"
	ExpenseDistStaff   = "EXPENSE_DIST_STAFF"
	ExpenseDistCommon  = "EXPENSE_DIST_COMMON"

	HeatingConsumptionShare          = "HEATING_CONSUMPTION_SHARE"
	HeatingAreaShare                 = "HEATING_AREA_SHARE"
	HeatingMinTemperatureC           = "HEATING_MIN_TEMPERATURE_C"
	HeatingConversionUnanimityAreaM2 = "HEATING_CONVERSION_UNANIMITY_AREA_M2"

	GANoticeDays   = "GA_NOTICE_DAYS"
	GAQuorumFirst  = "GA_QUORUM_FIRST"
	GAQuorumSecond = "GA_QUORUM_SECOND"

	OwnerMaxVoteShare               = "OWNER_MAX_VOTE_SHARE"
	ProxyMaxVoteShare               = "PROXY_MAX_VOTE_SHARE"
	ProxySmallBuildingUnitThreshold = "PROXY_SMALL_BUILDING_UNIT_THRESHOLD"
	ProxyMaxCountSmallBuilding      = "PROXY_MAX_COUNT_SMALL_BUILDING"

	MajorityConstructionConsent  = "MAJORITY_CONSTRUCTION_CONSENT"
	MajorityManagementPlanChange = "MAJORITY_MANAGEMENT_PLAN_CHANGE"
	MajorityInnovation           = "MAJORITY_INNOVATION"
	UnanimityTransferActs        = "UNANIMITY_TRANSFER_ACTS"

	ManagerMandatoryUnitCount     = "MANAGER_MANDATORY_UNIT_COUNT"
	BudgetObjectionDays           = "BUDGET_OBJECTION_DAYS"
	DecisionBookNotaryCloseMonths = "DECISION_BOOK_NOTARY_CLOSE_MONTHS"
	AnnualAccountMonth            = "ANNUAL_ACCOUNT_MONTH"
	AuditIntervalMonths           = "AUDIT_INTERVAL_MONTHS"

	TenantLiabilityScope   = "TENANT_LIABILITY_SCOPE"
	NewOwnerJointLiability = "NEW_OWNER_JOINT_LIABILITY"

	// KVKKResponseDays: ilgili kişi başvurusunun en geç sonuçlandırılacağı gün (6698 s. KVKK m.13/2).
	KVKKResponseDays = "KVKK_RESPONSE_DAYS"
)

// Parameter, tek bir parametrenin çözümlenmiş hâlidir.
type Parameter struct {
	Code        string
	Numeric     decimal.Decimal
	HasNumeric  bool
	Text        string
	Unit        string
	LegalBasis  string
	IsMandatory bool
	// PropertyScoped true ise değer siteye özel bir kayıttan gelmiştir.
	PropertyScoped bool
	EffectiveFrom  time.Time
}

// ErrNotFound, ne siteye özel ne de sistem geneli bir kayıt bulunamadığında döner.
type ErrNotFound struct {
	Code string
	On   time.Time
}

func (e *ErrNotFound) Error() string {
	return fmt.Sprintf("mevzuat parametresi bulunamadı: %s (%s tarihinde geçerli kayıt yok)",
		e.Code, e.On.Format("2006-01-02"))
}

// Resolver, parametreleri okur ve süreli önbelleğe alır.
//
// Önbellek NEDEN var: tahakkuk üretimi bağımsız bölüm başına parametre sorar;
// 500 daireli bir sitede bu, tek bir işlem için yüzlerce sorgu demektir.
// Önbellek NEDEN süreli: parametre değiştiğinde (yeni yürürlük kaydı) sistemin
// yeniden başlatılmasını beklemek istemiyoruz.
type Resolver struct {
	pool *pgxpool.Pool
	ttl  time.Duration

	mu    sync.RWMutex
	cache map[cacheKey]cacheEntry
}

type cacheKey struct {
	propertyID string
	code       string
	day        string // yürürlük çözümlemesi gün bazındadır
}

type cacheEntry struct {
	param   Parameter
	expires time.Time
}

// New, varsayılan 5 dakikalık önbellekle bir çözümleyici üretir.
func New(pool *pgxpool.Pool) *Resolver {
	return NewWithTTL(pool, 5*time.Minute)
}

// NewWithTTL, önbellek ömrünü açıkça belirler. ttl <= 0 ise önbellek kapalıdır.
func NewWithTTL(pool *pgxpool.Pool, ttl time.Duration) *Resolver {
	return &Resolver{pool: pool, ttl: ttl, cache: map[cacheKey]cacheEntry{}}
}

// Get, verilen site ve tarih için parametreyi çözümler.
// propertyID boş bırakılırsa yalnızca sistem geneli varsayılanlara bakılır.
func (r *Resolver) Get(ctx context.Context, propertyID, code string, on time.Time) (Parameter, error) {
	if on.IsZero() {
		on = time.Now()
	}
	key := cacheKey{propertyID: propertyID, code: code, day: on.Format("2006-01-02")}

	if r.ttl > 0 {
		r.mu.RLock()
		if e, ok := r.cache[key]; ok && time.Now().Before(e.expires) {
			r.mu.RUnlock()
			return e.param, nil
		}
		r.mu.RUnlock()
	}

	p, err := r.load(ctx, propertyID, code, on)
	if err != nil {
		return Parameter{}, err
	}

	if r.ttl > 0 {
		r.mu.Lock()
		r.cache[key] = cacheEntry{param: p, expires: time.Now().Add(r.ttl)}
		r.mu.Unlock()
	}
	return p, nil
}

// InvalidateCache, parametre yazıldıktan sonra çağrılmalıdır.
func (r *Resolver) InvalidateCache() {
	r.mu.Lock()
	r.cache = map[cacheKey]cacheEntry{}
	r.mu.Unlock()
}

// Sorgu, siteye özel kaydı sistem geneline tercih eder (ORDER BY ... NULLS LAST),
// ardından en güncel yürürlük tarihini seçer.
const selectQuery = `
SELECT code,
       value_numeric,
       COALESCE(value_text, ''),
       unit,
       legal_basis,
       is_mandatory,
       (property_id IS NOT NULL) AS property_scoped,
       effective_from
FROM legal_parameters
WHERE code = $1
  AND (property_id = NULLIF($2, '')::uuid OR property_id IS NULL)
  AND effective_from <= $3::date
  AND (effective_to IS NULL OR effective_to > $3::date)
ORDER BY (property_id IS NOT NULL) DESC, effective_from DESC
LIMIT 1`

func (r *Resolver) load(ctx context.Context, propertyID, code string, on time.Time) (Parameter, error) {
	var (
		p       Parameter
		numeric *decimal.Decimal
	)
	// Siteye özel istisna yalnızca site kapsamında görünür (RLS, migration 029).
	// Kapsamsız sorgu istisnayı SESSİZCE atlar ve sistem varsayılanını döndürürdü.
	// Site verilmemişse yalnızca sistem geneli satırlar okunur.
	var row pgx.Row
	if propertyID == "" {
		row = r.pool.QueryRow(ctx, selectQuery, code, propertyID, on)
	} else {
		row = dbscope.For(r.pool, propertyID).QueryRow(ctx, selectQuery, code, propertyID, on)
	}
	err := row.Scan(
		&p.Code, &numeric, &p.Text, &p.Unit, &p.LegalBasis, &p.IsMandatory,
		&p.PropertyScoped, &p.EffectiveFrom,
	)
	if err == pgx.ErrNoRows {
		return Parameter{}, &ErrNotFound{Code: code, On: on}
	}
	if err != nil {
		return Parameter{}, fmt.Errorf("mevzuat parametresi okunamadı (%s): %w", code, err)
	}
	if numeric != nil {
		p.Numeric = *numeric
		p.HasNumeric = true
	}
	return p, nil
}

// Decimal, sayısal parametreyi döndürür. Parametre sayısal değilse hata verir.
func (r *Resolver) Decimal(ctx context.Context, propertyID, code string, on time.Time) (decimal.Decimal, error) {
	p, err := r.Get(ctx, propertyID, code, on)
	if err != nil {
		return decimal.Zero, err
	}
	if !p.HasNumeric {
		return decimal.Zero, fmt.Errorf("mevzuat parametresi sayısal değil: %s (unit=%s)", code, p.Unit)
	}
	return p.Numeric, nil
}

// Int, tam sayı parametreleri (gün, ay, adet) için kısayoldur.
func (r *Resolver) Int(ctx context.Context, propertyID, code string, on time.Time) (int, error) {
	d, err := r.Decimal(ctx, propertyID, code, on)
	if err != nil {
		return 0, err
	}
	return int(d.IntPart()), nil
}

// decOne, testlerde ve oran doğrulamalarında kullanılan sabit 1 değeridir.
func decOne() decimal.Decimal { return decimal.NewFromInt(1) }

// Text, metinsel parametreleri döndürür.
func (r *Resolver) Text(ctx context.Context, propertyID, code string, on time.Time) (string, error) {
	p, err := r.Get(ctx, propertyID, code, on)
	if err != nil {
		return "", err
	}
	if p.Text == "" {
		return "", fmt.Errorf("mevzuat parametresi metinsel değil: %s (unit=%s)", code, p.Unit)
	}
	return p.Text, nil
}
