// Package compliance, işveren olarak site yönetiminin vergi/SGK sürelerini
// hesaplar (FAZ 7.7, migration 041). Hem personel servisi (takvim ekranı) hem
// zamanlayıcı (hatırlatma) aynı hesabı kullanır; iki ayrı yerde yazılsaydı
// biri değiştiğinde ekran ile hatırlatma farklı gün söylerdi.
//
// Sistem verginin DOĞUP DOĞMADIĞINA karar vermez; yalnızca süreyi gösterir.
package compliance

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/legalparams"
)

// Item, takvimdeki bir yükümlülüktür.
type Item struct {
	Kind       string    `json:"kind"` // MUHSGK | SGK_PREMIUM | SGK_ENTRY | SGK_EXIT
	Title      string    `json:"title"`
	DueDate    time.Time `json:"due_date"`
	DaysLeft   int       `json:"days_left"` // eksi: süre geçti
	EmployeeID string    `json:"employee_id,omitempty"`
	Period     string    `json:"period,omitempty"` // YYYY-MM (aylık beyanlar)
	LegalBasis string    `json:"legal_basis"`
}

// Note, takvimin sınırlarını söyler (ekranda gösterilir).
const Note = "Son gün hafta sonuna denk gelirse izleyen iş gününe kaydırıldı (VUK m.18). Resmî tatiller ve idari " +
	"uzatmalar (ör. bayram) sistemde bilinmez; Gelir İdaresi/SGK duyurularını kontrol edin. Ödemenin vergi doğurup " +
	"doğurmadığı (kapıcı istisnası, ticari bölüm, Kolay İşverenlik) mali müşavirce değerlendirilir."

// NextWorkday, cumartesi/pazar gününü izleyen pazartesiye kaydırır.
func NextWorkday(t time.Time) time.Time {
	for t.Weekday() == time.Saturday || t.Weekday() == time.Sunday {
		t = t.AddDate(0, 0, 1)
	}
	return t
}

func day(t time.Time) time.Time {
	y, m, d := t.Date()
	return time.Date(y, m, d, 0, 0, 0, 0, t.Location())
}

// MonthlyDue, bugünden itibaren ilk "ayın N'i" son gününü (kaydırılmış) ve ait
// olduğu dönemi (bir önceki ay) döner. Bugün son günse bugün döner.
func MonthlyDue(today time.Time, dueDay int) (time.Time, string) {
	today = day(today)
	for i := 0; i < 3; i++ {
		base := time.Date(today.Year(), today.Month()+time.Month(i), 1, 0, 0, 0, 0, today.Location())
		d := dueDay
		if last := base.AddDate(0, 1, -1).Day(); d > last {
			d = last
		}
		due := NextWorkday(base.AddDate(0, 0, d-1))
		if !due.Before(today) {
			return due, base.AddDate(0, -1, 0).Format("2006-01")
		}
	}
	return today, ""
}

// MonthEndDue, bugünden itibaren ilk ay sonu son gününü (kaydırılmış) ve dönemini döner.
func MonthEndDue(today time.Time) (time.Time, string) {
	today = day(today)
	// Önceki ayın sonu hafta sonuysa son gün bu aya kayar: oradan başlanır.
	for i := -1; i < 3; i++ {
		base := time.Date(today.Year(), today.Month()+time.Month(i), 1, 0, 0, 0, 0, today.Location())
		due := NextWorkday(base.AddDate(0, 1, -1))
		if !due.Before(today) {
			return due, base.AddDate(0, -1, 0).Format("2006-01")
		}
	}
	return today, ""
}

func daysBetween(a, b time.Time) int { return int(day(b).Sub(day(a)).Hours() / 24) }

// Load, sitenin yükümlülük takvimini üretir. enabled=false ise aylık beyanlar
// (MUHSGK, prim) gösterilmez; personel bazlı SGK bildirimleri her zaman gösterilir.
func Load(ctx context.Context, pool *pgxpool.Pool, params *legalparams.Resolver, propertyID string, today time.Time, enabled bool) ([]Item, error) {
	today = day(today)
	exitDays, err := params.Int(ctx, propertyID, legalparams.SGKExitNoticeDays, today)
	if err != nil {
		return nil, err
	}
	items := []Item{}
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT id::text, first_name || ' ' || last_name, hire_date, sgk_registration_date, end_date, sgk_exit_date,
		       COALESCE(is_active, true)
		FROM employees
		WHERE property_id = $1 AND deleted = 0
		  AND (COALESCE(is_active, true) OR (end_date IS NOT NULL AND end_date >= CURRENT_DATE - 90))`, propertyID)
	if err != nil {
		return nil, err
	}
	payroll := false
	for rows.Next() {
		var id, name string
		var hire time.Time
		var entry, end, exit *time.Time
		var active bool
		if err := rows.Scan(&id, &name, &hire, &entry, &end, &exit, &active); err != nil {
			rows.Close()
			return nil, err
		}
		if active || (end != nil && !day(*end).Before(today.AddDate(0, -1, 0))) {
			payroll = true
		}
		if active && entry == nil {
			items = append(items, Item{Kind: "SGK_ENTRY", EmployeeID: id, DueDate: day(hire), DaysLeft: daysBetween(today, hire),
				Title:      name + " — SGK işe giriş bildirgesi (çalışmaya başlamadan önce)",
				LegalBasis: "5510 s. Kanun m.8/1"})
		}
		if end != nil && exit == nil {
			due := NextWorkday(day(*end).AddDate(0, 0, exitDays))
			items = append(items, Item{Kind: "SGK_EXIT", EmployeeID: id, DueDate: due, DaysLeft: daysBetween(today, due),
				Title:      fmt.Sprintf("%s — SGK işten ayrılış bildirgesi (%d gün)", name, exitDays),
				LegalBasis: "5510 s. Kanun m.9"})
		}
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if enabled && payroll {
		dueDay, err := params.Int(ctx, propertyID, legalparams.MUHSGKDueDay, today)
		if err != nil {
			return nil, err
		}
		rule, err := params.Text(ctx, propertyID, legalparams.SGKPremiumDue, today)
		if err != nil {
			return nil, err
		}
		due, period := MonthlyDue(today, dueDay)
		items = append(items, Item{Kind: "MUHSGK", DueDate: due, DaysLeft: daysBetween(today, due), Period: period,
			Title:      period + " dönemi Muhtasar ve Prim Hizmet Beyannamesi; stopaj ve damga vergisi ödemesi",
			LegalBasis: "GVK m.98; 5510 s. Kanun m.86"})
		if rule != "MONTH_END" {
			return nil, fmt.Errorf("SGK_PREMIUM_DUE için bilinmeyen kural: %q", rule)
		}
		pdue, pperiod := MonthEndDue(today)
		items = append(items, Item{Kind: "SGK_PREMIUM", DueDate: pdue, DaysLeft: daysBetween(today, pdue), Period: pperiod,
			Title:      pperiod + " dönemi SGK primlerinin ödenmesi",
			LegalBasis: "5510 s. Kanun m.88"})
	}
	sort.SliceStable(items, func(i, j int) bool { return items[i].DueDate.Before(items[j].DueDate) })
	return items, nil
}
