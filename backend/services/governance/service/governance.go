package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/services/governance/models"
	"github.com/siteeksen/backend/services/governance/repository"
)

// İş kuralı hataları.
var (
	// ErrNoticeTooLate, genel kurul çağrısı yasal süreden geç yapıldığında döner.
	ErrNoticeTooLate = errors.New("genel kurul çağrısı yasal süreye uymuyor")
	// ErrProxyLimitExceeded, vekâlet sınırları aşıldığında döner (KMK m.31).
	ErrProxyLimitExceeded = errors.New("vekâlet sınırı aşıldı")
	// ErrUnknownDistribution, tanınmayan dağıtım türü.
	ErrUnknownDistribution = errors.New("bilinmeyen dağıtım türü")
)

// Service, yönetişim iş kurallarını uygular.
type Service struct {
	repo   *repository.Repository
	params *legalparams.Resolver
}

// New yeni servis üretir.
func New(repo *repository.Repository, params *legalparams.Resolver) *Service {
	return &Service{repo: repo, params: params}
}

// -----------------------------------------------------------------------------
// İŞLETME PROJESİ
// -----------------------------------------------------------------------------

// CreateBudget, işletme projesini hazırlar ve her bağımsız bölüme düşen payı hesaplar.
//
// KMK m.20 dağıtım kuralları kaleme göre uygulanır:
//   - EQUAL       : eşit (kapıcı, kaloriferci, bahçıvan, bekçi, yönetici aylığı)
//   - SHARE_RATIO : arsa payı (sigorta, ortak yer bakım/onarım, ortak tesis işletme)
//   - AREA_M2     : kullanım alanı (yönetim planı öngörürse)
//
// Dağıtım `pkg/money` ile KURUŞ üzerinden ve en büyük kalan yöntemiyle yapılır;
// böylece payların toplamı kalemin tutarına BİREBİR eşittir (kuruş kaybı yok).
func (s *Service) CreateBudget(ctx context.Context, propertyID, userID string, in models.CreateBudgetInput) (*models.Budget, error) {
	units, err := s.repo.ListUnits(ctx, propertyID)
	if err != nil {
		return nil, err
	}

	// unitID -> yıllık kuruş ve kalem bazlı döküm
	annual := make(map[string]int64, len(units))
	breakdown := make(map[string]map[string]int64, len(units))
	for _, u := range units {
		breakdown[u.ID] = map[string]int64{}
	}

	total := decimal.Zero
	for _, item := range in.Items {
		if item.Kind == "INCOME" {
			// Gelir kalemleri paylaştırılmaz; toplam gideri azaltır ama pay hesabına
			// girmez. Bilinçli sadeleştirme: gelirin hangi kaleme mahsup edileceği
			// yönetim planına bağlıdır ve tek doğru yolu yoktur (bkz. questions.md S-02).
			continue
		}
		total = total.Add(decimal.NewFromFloat(item.Amount))

		amount := money.FromFloatTRY(item.Amount)
		shares, err := s.distributionShares(item.DistributionType, units)
		if err != nil {
			return nil, fmt.Errorf("%w: %s (kalem: %s)", err, item.DistributionType, item.Name)
		}
		dist, err := money.Distribute(amount, shares)
		if err != nil {
			return nil, fmt.Errorf("%s kalemi paylaştırılamadı: %w", item.Name, err)
		}
		for _, d := range dist {
			annual[d.Key] += int64(d.Amount)
			breakdown[d.Key][item.Name] += int64(d.Amount)
		}
	}

	// Aylık pay: yıllık payı 12'ye böler; kuruş artığı aylara dağıtılmaz, ilk aya
	// bırakılmaz — yerine aylık pay AŞAĞI yuvarlanır ve fark yıllık toplamda kalır.
	// Böylece 12 × aylık ≤ yıllık olur ve fazla tahsilat yapılmaz.
	unitShares := make([]models.UnitShare, 0, len(units))
	for _, u := range units {
		a := annual[u.ID]
		unitShares = append(unitShares, models.UnitShare{
			UnitID:       u.ID,
			UnitName:     u.Name,
			AnnualKurus:  a,
			MonthlyKurus: a / 12,
			Breakdown:    breakdown[u.ID],
		})
	}

	totalFloat, _ := total.Float64()
	id, err := s.repo.CreateBudget(ctx, propertyID, userID, in, totalFloat, unitShares)
	if err != nil {
		return nil, err
	}
	return s.repo.GetBudget(ctx, propertyID, id)
}

// distributionShares, dağıtım türüne göre ağırlıkları üretir.
func (s *Service) distributionShares(kind string, units []repository.Unit) ([]money.Share, error) {
	out := make([]money.Share, 0, len(units))
	switch kind {
	case "EQUAL":
		for _, u := range units {
			out = append(out, money.Share{Key: u.ID, Weight: decimal.NewFromInt(1)})
		}
	case "SHARE_RATIO":
		for _, u := range units {
			out = append(out, money.Share{Key: u.ID, Weight: decimal.NewFromFloat(u.ShareRatio)})
		}
	case "AREA_M2":
		for _, u := range units {
			out = append(out, money.Share{Key: u.ID, Weight: decimal.NewFromFloat(u.AreaM2)})
		}
	default:
		// METER_READING gibi tüketim bazlı kalemler yıllık bütçede paylaştırılmaz;
		// aylık tahakkukta ölçüm verisiyle hesaplanır.
		return nil, ErrUnknownDistribution
	}
	return out, nil
}

// NotifyBudget, projeyi tebliğ edilmiş sayar ve itiraz süresini başlatır (m.37/2).
func (s *Service) NotifyBudget(ctx context.Context, propertyID, budgetID string, in models.NotifyBudgetInput) (*models.Budget, error) {
	days, err := s.params.Int(ctx, propertyID, legalparams.BudgetObjectionDays, time.Now())
	if err != nil {
		return nil, err
	}
	return s.repo.NotifyBudget(ctx, propertyID, budgetID, in.Method, days)
}

// FinalizeBudget, itiraz süresi dolduktan sonra projeyi kesinleştirir.
func (s *Service) FinalizeBudget(ctx context.Context, propertyID, budgetID, decisionRef string) (*models.Budget, error) {
	return s.repo.FinalizeBudget(ctx, propertyID, budgetID, decisionRef)
}

// GetBudget / ListBudgets / itiraz işlemleri doğrudan repository'ye devredilir.
func (s *Service) GetBudget(ctx context.Context, propertyID, id string) (*models.Budget, error) {
	return s.repo.GetBudget(ctx, propertyID, id)
}
func (s *Service) ListBudgets(ctx context.Context, propertyID string) ([]models.Budget, error) {
	return s.repo.ListBudgets(ctx, propertyID)
}
func (s *Service) AddObjection(ctx context.Context, propertyID, budgetID, unitID, userID, reason string) (*models.Objection, error) {
	return s.repo.AddObjection(ctx, propertyID, budgetID, unitID, userID, reason)
}
func (s *Service) ListObjections(ctx context.Context, propertyID, budgetID string) ([]models.Objection, error) {
	return s.repo.ListObjections(ctx, propertyID, budgetID)
}
func (s *Service) ResolveObjection(ctx context.Context, propertyID, id, status, resolution string) error {
	return s.repo.ResolveObjection(ctx, propertyID, id, status, resolution)
}

// -----------------------------------------------------------------------------
// GENEL KURUL
// -----------------------------------------------------------------------------

// CreateAssembly, toplantıyı oluşturur.
func (s *Service) CreateAssembly(ctx context.Context, propertyID, userID string, in models.CreateAssemblyInput) (*models.Assembly, error) {
	id, err := s.repo.CreateAssembly(ctx, propertyID, userID, in)
	if err != nil {
		return nil, err
	}
	return s.repo.GetAssembly(ctx, propertyID, id)
}

func (s *Service) GetAssembly(ctx context.Context, propertyID, id string) (*models.Assembly, error) {
	return s.repo.GetAssembly(ctx, propertyID, id)
}
func (s *Service) ListAssemblies(ctx context.Context, propertyID string) ([]models.Assembly, error) {
	return s.repo.ListAssemblies(ctx, propertyID)
}

// NotifyAssembly, çağrıyı yapar.
//
// KMK m.29: çağrı, toplantı gününden en az 15 gün önce yapılmalıdır. Süre
// tutmuyorsa işlem REDDEDİLİR — geç yapılmış bir çağrı, toplantıda alınan
// kararların iptal edilebilir olması anlamına gelir; sistemin bunu sessizce
// kabul etmesi kullanıcıyı hukuki riske sokar.
func (s *Service) NotifyAssembly(ctx context.Context, propertyID, assemblyID, method string) error {
	assembly, err := s.repo.GetAssembly(ctx, propertyID, assemblyID)
	if err != nil {
		return err
	}
	days, err := s.params.Int(ctx, propertyID, legalparams.GANoticeDays, time.Now())
	if err != nil {
		return err
	}
	earliest := assembly.ScheduledAt.AddDate(0, 0, -days)
	if time.Now().After(earliest) {
		return fmt.Errorf("%w: toplantı %s tarihinde; çağrı en geç %s tarihinde yapılmalıydı (KMK m.29, %d gün)",
			ErrNoticeTooLate,
			assembly.ScheduledAt.Format("2006-01-02"),
			earliest.Format("2006-01-02"), days)
	}
	return s.repo.NotifyAssembly(ctx, propertyID, assemblyID, method)
}

// AddAttendee, hazirun kaydı ekler ve vekâlet sınırlarını denetler.
//
// KMK m.31:
//   - Bir kişi, toplam oyun %5'inden fazlasını kullanmak üzere vekil tayin edilemez.
//   - Kırk ve daha az bağımsız bölümü olan yapılarda bir kişi en fazla iki vekâlet alabilir.
//
// Sınır aşılırsa kayıt REDDEDİLİR: sınırı aşan vekâletle kullanılan oy geçersizdir
// ve kararın iptaline yol açar.
func (s *Service) AddAttendee(ctx context.Context, propertyID, assemblyID string, in models.AttendeeInput) error {
	if in.AttendanceType == "PROXY" && in.ProxyHolderID != "" {
		if err := s.checkProxyLimits(ctx, propertyID, assemblyID, in); err != nil {
			return err
		}
	}
	return s.repo.AddAttendee(ctx, propertyID, assemblyID, in)
}

func (s *Service) checkProxyLimits(ctx context.Context, propertyID, assemblyID string, in models.AttendeeInput) error {
	units, err := s.repo.ListUnits(ctx, propertyID)
	if err != nil {
		return err
	}
	totalUnits := len(units)
	totalShare := 0.0
	newShare := 0.0
	for _, u := range units {
		totalShare += u.ShareRatio
		if u.ID == in.UnitID {
			newShare = u.ShareRatio
		}
	}

	count, share, err := s.repo.ProxyLoad(ctx, propertyID, assemblyID, in.ProxyHolderID)
	if err != nil {
		return err
	}

	now := time.Now()
	threshold, err := s.params.Int(ctx, propertyID, legalparams.ProxySmallBuildingUnitThreshold, now)
	if err != nil {
		return err
	}

	if totalUnits <= threshold {
		maxCount, err := s.params.Int(ctx, propertyID, legalparams.ProxyMaxCountSmallBuilding, now)
		if err != nil {
			return err
		}
		if count+1 > maxCount {
			return fmt.Errorf("%w: %d veya daha az bağımsız bölümlü yapıda bir kişi en fazla %d vekâlet alabilir (KMK m.31); bu vekilde zaten %d vekâlet var",
				ErrProxyLimitExceeded, threshold, maxCount, count)
		}
		return nil
	}

	maxShare, err := s.params.Decimal(ctx, propertyID, legalparams.ProxyMaxVoteShare, now)
	if err != nil {
		return err
	}
	limit, _ := maxShare.Float64()
	if totalShare > 0 && (share+newShare) > limit*totalShare {
		return fmt.Errorf("%w: bir vekil toplam oyun en fazla %%%.0f'ini kullanabilir (KMK m.31); bu kayıtla oran %%%.2f olur",
			ErrProxyLimitExceeded, limit*100, (share+newShare)/totalShare*100)
	}
	return nil
}

// EvaluateQuorumFor, toplantının güncel nisap durumunu hesaplar (toplantı yapılmadan önce de çağrılabilir).
func (s *Service) EvaluateQuorumFor(ctx context.Context, propertyID, assemblyID string) (models.QuorumResult, error) {
	assembly, err := s.repo.GetAssembly(ctx, propertyID, assemblyID)
	if err != nil {
		return models.QuorumResult{}, err
	}
	totalUnits, totalShare, attUnits, attShare, err := s.repo.AttendanceTotals(ctx, propertyID, assemblyID)
	if err != nil {
		return models.QuorumResult{}, err
	}

	code := legalparams.GAQuorumFirst
	if assembly.CallNumber >= 2 {
		code = legalparams.GAQuorumSecond
	}
	p, err := s.params.Get(ctx, propertyID, code, time.Now())
	if err != nil {
		return models.QuorumResult{}, err
	}
	ratio, _ := p.Numeric.Float64()

	return EvaluateQuorum(assembly.CallNumber, totalUnits, totalShare,
		attUnits, attShare, ratio, p.LegalBasis), nil
}

// HoldAssembly, toplantıyı yapılmış işaretler ve nisap fotoğrafını saklar.
func (s *Service) HoldAssembly(ctx context.Context, propertyID, assemblyID string) (models.QuorumResult, error) {
	q, err := s.EvaluateQuorumFor(ctx, propertyID, assemblyID)
	if err != nil {
		return q, err
	}
	return q, s.repo.HoldAssembly(ctx, propertyID, assemblyID, q)
}

// CastVote, oy kaydeder.
func (s *Service) CastVote(ctx context.Context, propertyID, agendaItemID string, in models.VoteInput, userID string) error {
	return s.repo.CastVote(ctx, propertyID, agendaItemID, in, userID)
}

// CloseAgendaItem, gündem maddesini nisap kurallarına göre sonuçlandırır.
func (s *Service) CloseAgendaItem(ctx context.Context, propertyID, agendaItemID, decisionText string) (models.MajorityResult, error) {
	item, assembly, err := s.repo.GetAgendaItem(ctx, propertyID, agendaItemID)
	if err != nil {
		return models.MajorityResult{}, err
	}
	totalUnits, totalShare, attUnits, attShare, err := s.repo.AttendanceTotals(ctx, propertyID, assembly.ID)
	if err != nil {
		return models.MajorityResult{}, err
	}

	required := 0.0
	basis := ""
	if item.RequiredMajorityCode != "" {
		p, err := s.params.Get(ctx, propertyID, item.RequiredMajorityCode, time.Now())
		if err != nil {
			return models.MajorityResult{}, err
		}
		required, _ = p.Numeric.Float64()
		basis = p.LegalBasis
	}

	res := EvaluateMajority(item.RequiredMajorityCode, required, assembly.CallNumber,
		totalUnits, totalShare, attUnits, attShare,
		item.VotesFor, item.ShareFor, basis)

	status := "REJECTED"
	if res.Accepted {
		status = "ACCEPTED"
	}
	text := decisionText
	if text == "" {
		text = res.Explanation
	}
	if err := s.repo.CloseAgendaItem(ctx, propertyID, agendaItemID, status, text); err != nil {
		return res, err
	}
	return res, nil
}

// -----------------------------------------------------------------------------
// DEFTERLER
// -----------------------------------------------------------------------------

func (s *Service) EnsureBook(ctx context.Context, propertyID, kind string, year int) (*models.Book, error) {
	return s.repo.EnsureBook(ctx, propertyID, kind, year)
}
func (s *Service) AppendBookEntry(ctx context.Context, propertyID, bookID, userID string, in models.CreateBookEntryInput) (*models.BookEntry, error) {
	return s.repo.AppendBookEntry(ctx, propertyID, bookID, userID, in)
}
func (s *Service) ListBookEntries(ctx context.Context, propertyID, bookID string) ([]models.BookEntry, error) {
	return s.repo.ListBookEntries(ctx, propertyID, bookID)
}
func (s *Service) VerifyBook(ctx context.Context, propertyID, bookID string) (*models.BookIntegrity, error) {
	return s.repo.VerifyBook(ctx, propertyID, bookID)
}

// CloseBook, defteri notere kapattırıldı olarak işaretler.
//
// KMK m.36: karar defteri, her takvim yılının bitiminden başlayarak BİR AY içinde
// notere kapattırılır. Süre aşılmışsa işlem engellenmez (geçmişe dönük kayıt
// yapılabilmelidir) ama yanıtta uyarı döndürülür.
func (s *Service) CloseBook(ctx context.Context, propertyID, bookID, notaryRef string, closedAt time.Time, periodYear int) (string, error) {
	if closedAt.IsZero() {
		closedAt = time.Now()
	}
	if err := s.repo.CloseBook(ctx, propertyID, bookID, notaryRef, closedAt); err != nil {
		return "", err
	}

	months, err := s.params.Int(ctx, propertyID, legalparams.DecisionBookNotaryCloseMonths, time.Now())
	if err != nil {
		return "", err
	}
	deadline := time.Date(periodYear+1, time.January, 1, 0, 0, 0, 0, closedAt.Location()).
		AddDate(0, months, 0)
	if closedAt.After(deadline) {
		return fmt.Sprintf(
			"UYARI: Defter %s tarihinde kapatıldı; yasal süre %s tarihinde dolmuştu (KMK m.36).",
			closedAt.Format("2006-01-02"), deadline.Format("2006-01-02")), nil
	}
	return "", nil
}

// -----------------------------------------------------------------------------
// HUKUK / İCRA
// -----------------------------------------------------------------------------

// CreateLegalCase, takip açar. Borç tutarı tahakkuklardan hesaplanır; elle girilmez.
//
// KMK m.37/son: kesinleşmiş işletme projesi ya da kat malikleri kurulu kararı
// İİK m.68'deki belgelerdendir. Takip bu belgeye dayandırılmalıdır; dayanak
// belirtilmemişse uyarı verilir.
func (s *Service) CreateLegalCase(ctx context.Context, propertyID string, in models.CreateLegalCaseInput) (*models.LegalCase, string, error) {
	principal, lateFee, err := s.repo.UnitDebt(ctx, propertyID, in.UnitID)
	if err != nil {
		return nil, "", err
	}
	id, err := s.repo.CreateLegalCase(ctx, propertyID, in, principal, lateFee)
	if err != nil {
		return nil, "", err
	}

	warning := ""
	if in.BasisDocumentType == "" {
		warning = "UYARI: Takibe dayanak belge belirtilmedi. İcra takibinin İİK m.68 " +
			"kapsamında belgeye dayanması gerekir (kesinleşmiş işletme projesi veya kurul kararı)."
	}

	cases, err := s.repo.ListLegalCases(ctx, propertyID)
	if err != nil {
		return nil, warning, err
	}
	for i := range cases {
		if cases[i].ID == id {
			return &cases[i], warning, nil
		}
	}
	return nil, warning, nil
}

func (s *Service) ListLegalCases(ctx context.Context, propertyID string) ([]models.LegalCase, error) {
	return s.repo.ListLegalCases(ctx, propertyID)
}
