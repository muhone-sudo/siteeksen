package main

import (
	"context"
	"fmt"
	"time"
	_ "time/tzdata"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/notify"
)

// notice, bir işin ürettiği tek bildirimdir: kime ve ne.
type notice struct {
	recipients []notify.Recipient
	msg        notify.Message
}

// job, bir site için çalışan zamanlanmış iştir. İş bildirimi KENDİSİ
// göndermez; ne gönderileceğini döner. Gönderim ve sayım tek yerde
// (Scheduler.runJob) yapılır — her iş kendi sayacını tutsaydı raporlar
// birbirinden ayrışırdı.
type job struct {
	name string
	// what, raporda ve sağlık ucunda işin ne yaptığını anlatır.
	what string
	run  func(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error)
}

// contractLeadDays, ihbar son gününden kaç gün önce uyarılacağıdır. Mevzuat
// değil İŞLETME tercihidir (legal_parameters'a girmez): yönetimin fesih
// yazısını hazırlayıp göndermesine yetecek bir süre.
const contractLeadDays = 14

// maintenanceLeadDays, demirbaş bakım/periyodik kontrol tarihinden kaç gün önce
// uyarılacağıdır (işletme tercihi; yetkili firmadan randevu almaya yetecek süre).
const maintenanceLeadDays = 14

func jobs() []job {
	return []job{
		{name: "dues.overdue", what: "Vadesi geçmiş aidatı olan daireye ayda en fazla bir hatırlatma", run: overdueDues},
		{name: "contract.notice", what: "İhbar son günü yaklaşan ya da geçen sözleşme → yönetim", run: contractNotices},
		{name: "contract.expired", what: "Süresi dolduğu hâlde ACTIVE kalan sözleşme → yönetim", run: expiredContracts},
		{name: "patrol.overdue", what: "Beklenen süre + tolerans aşıldığı hâlde açık kalan devriye → yönetim", run: overduePatrols},
		{name: "asset.maintenance", what: "Bakım/periyodik kontrol tarihi yaklaşan ya da geçen demirbaş → yönetim", run: maintenanceDue},
		{name: "kvkk.due", what: "Yasal yanıt süresi (KVKK m.13) dolmak üzere ya da dolmuş açık başvuru → yönetim", run: kvkkDue},
	}
}

// istanbul, bildirim metnindeki saatlerin gösterildiği saat dilimidir. Kap UTC
// çalışır; "03:10'da başladı" yazıp 06:10'u kastetmek görevliyi zan altında
// bırakırdı. Saat dilimi verisi ikiliye gömülüdür (time/tzdata).
var istanbul = func() *time.Location {
	loc, err := time.LoadLocation("Europe/Istanbul")
	if err != nil {
		return time.FixedZone("TRT", 3*60*60)
	}
	return loc
}()

// trDate, tarih (saat içermeyen DATE sütunu) biçimidir.
func trDate(t time.Time) string { return t.Format("02.01.2006") }

// overdueDues: gecikmiş borcu olan her daireye AYDA EN FAZLA BİR hatırlatma.
//
// Neden daire başına ve aylık: tahakkuk başına bildirim, üç dönem borcu olan
// daireye her taramada üç ayrı bildirim demekti; sakin bildirimleri kapatır ve
// asıl önemli olanı da görmez. Anahtar ayı içerdiği için borç sürdükçe her ay
// bir kez hatırlatılır, ödenince durur.
//
// Alıcı dairenin AKTİF sakinleridir (malik, kiracı, vekil); ödemeyi hangisinin
// yapacağı aralarındaki anlaşmaya bağlıdır ve sistem bunu bilmez. Taşınmış
// sakine bildirim gitmez (pkg/notify.UnitResidents).
func overdueDues(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT ma.unit_id::text,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       count(*)::int,
		       SUM(round((ma.total_amount - COALESCE(ma.paid_amount,0)) * 100))::bigint,
		       min(ma.due_date),
		       to_char(CURRENT_DATE, 'YYYY-MM')
		FROM monthly_assessments ma
		JOIN units u ON u.id = ma.unit_id
		WHERE ma.property_id = $1 AND u.property_id = $1
		  AND ma.deleted = 0
		  AND COALESCE(ma.status,'') <> 'PAID'
		  AND ma.due_date < CURRENT_DATE
		  AND ma.total_amount - COALESCE(ma.paid_amount,0) > 0
		GROUP BY ma.unit_id, u.block, u.door_number
		ORDER BY 2`, propertyID)
	if err != nil {
		return nil, err
	}
	type row struct {
		unitID, label, month string
		periods              int
		remaining            int64
		oldest               time.Time
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.unitID, &r.label, &r.periods, &r.remaining, &r.oldest, &r.month); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]notice, 0, len(list))
	for _, r := range list {
		recipients, err := notify.UnitResidents(ctx, pool, propertyID, r.unitID)
		if err != nil {
			return nil, err
		}
		body := fmt.Sprintf("%s bağımsız bölümünün vadesi geçmiş %d dönem aidat borcu var.\n"+
			"Kalan toplam: %s · En eski vade: %s\n"+
			"Ödenmeyen aidata KMK m.20 uyarınca gecikme tazminatı işler. Ödeme yaptıysanız "+
			"ve kayıt henüz güncellenmediyse site yönetimiyle iletişime geçin.",
			r.label, r.periods, money.Kurus(r.remaining).Display(), trDate(r.oldest))
		out = append(out, notice{recipients: recipients, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "dues.overdue",
			Subject:    "Gecikmiş aidat borcu",
			Body:       body,
			Payload: map[string]any{
				"unit_id": r.unitID, "periods": r.periods,
				"remaining_kurus": r.remaining, "oldest_due_date": r.oldest.Format("2006-01-02"),
			},
			DedupeKey: "dues.overdue:" + r.unitID + ":" + r.month,
		}})
	}
	return out, nil
}

// contractNotices: fesih ihbarı için son gün (bitiş − ihbar süresi) 14 gün
// içindeyse ya da geçtiyse yönetim uyarılır. Sözleşme döngüsü başına BİR kez:
// anahtar bitiş tarihini içerir, yenilenince yeni döngü yeniden uyarılır.
//
// Otomatik yenilenen sözleşmede ihbar kaçırılırsa site bir dönem daha
// bağlanır; yenilenmeyen sözleşmede ise hizmet kesintiye uğrar. Metin ikisini ayırır.
func contractNotices(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT id::text, title, party_name, end_date,
		       COALESCE(renewal_notice_days,30), COALESCE(auto_renew,false),
		       (end_date - CURRENT_DATE)::int,
		       (end_date - COALESCE(renewal_notice_days,30) - CURRENT_DATE)::int
		FROM contracts
		WHERE property_id = $1 AND deleted = 0 AND status = 'ACTIVE'
		  AND end_date IS NOT NULL AND end_date >= CURRENT_DATE
		  AND end_date - COALESCE(renewal_notice_days,30) - $2::int <= CURRENT_DATE
		ORDER BY end_date`, propertyID, contractLeadDays)
	if err != nil {
		return nil, err
	}
	type row struct {
		id, title, party                   string
		end                                time.Time
		noticeDays, daysLeft, deadlineLeft int
		autoRenew                          bool
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.title, &r.party, &r.end, &r.noticeDays, &r.autoRenew,
			&r.daysLeft, &r.deadlineLeft); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}
	managers, err := notify.Managers(ctx, pool, propertyID)
	if err != nil {
		return nil, err
	}

	out := make([]notice, 0, len(list))
	for _, r := range list {
		deadline := r.end.AddDate(0, 0, -r.noticeDays)
		var when string
		switch {
		case r.deadlineLeft > 0:
			when = fmt.Sprintf("Fesih ihbarı için son gün %s (%d gün kaldı).", trDate(deadline), r.deadlineLeft)
		case r.deadlineLeft == 0:
			when = fmt.Sprintf("Fesih ihbarı için son gün BUGÜN (%s).", trDate(deadline))
		default:
			when = fmt.Sprintf("Fesih ihbarı için son gün %s idi; %d gün geçti.", trDate(deadline), -r.deadlineLeft)
		}
		effect := "Otomatik yenileme yok: bitişten sonra hizmetin sürmesi için yenileme ya da yeni sözleşme gerekir."
		if r.autoRenew {
			effect = "Sözleşme kendiliğinden yenilenir: yenilenmesi istenmiyorsa fesih bildirimi " +
				"son günden önce karşı tarafa ULAŞMIŞ olmalıdır."
		}
		body := fmt.Sprintf("'%s' (%s) sözleşmesi %s tarihinde bitiyor (%d gün kaldı; ihbar süresi %d gün).\n%s\n%s",
			r.title, r.party, trDate(r.end), r.daysLeft, r.noticeDays, when, effect)
		out = append(out, notice{recipients: managers, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "contract.notice",
			Subject:    "Sözleşme ihbar süresi: " + r.title,
			Body:       body,
			Payload: map[string]any{
				"contract_id": r.id, "end_date": r.end.Format("2006-01-02"),
				"notice_deadline": deadline.Format("2006-01-02"), "auto_renew": r.autoRenew,
			},
			DedupeKey: "contract.notice:" + r.id + ":" + r.end.Format("2006-01-02"),
		}})
	}
	return out, nil
}

// expiredContracts: bitiş tarihi geçtiği hâlde durumu ACTIVE kalan sözleşme.
// Ya yenilenmiş ama kayda işlenmemiştir ya da bitmiş ama kapatılmamıştır; iki
// durumda da kayıt gerçeği yansıtmıyor ve ödeme planı yanlış görünür.
func expiredContracts(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT id::text, title, party_name, end_date, (CURRENT_DATE - end_date)::int
		FROM contracts
		WHERE property_id = $1 AND deleted = 0 AND status = 'ACTIVE'
		  AND end_date IS NOT NULL AND end_date < CURRENT_DATE
		ORDER BY end_date`, propertyID)
	if err != nil {
		return nil, err
	}
	type row struct {
		id, title, party string
		end              time.Time
		daysAgo          int
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.title, &r.party, &r.end, &r.daysAgo); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}
	managers, err := notify.Managers(ctx, pool, propertyID)
	if err != nil {
		return nil, err
	}
	out := make([]notice, 0, len(list))
	for _, r := range list {
		out = append(out, notice{recipients: managers, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "contract.expired",
			Subject:    "Süresi dolmuş sözleşme: " + r.title,
			Body: fmt.Sprintf("'%s' (%s) sözleşmesinin süresi %s tarihinde doldu (%d gün önce) ama kayıt hâlâ "+
				"AKTİF görünüyor. Yenilendiyse yenilemeyi, bittiyse feshi kayda işleyin.",
				r.title, r.party, trDate(r.end), r.daysAgo),
			Payload:   map[string]any{"contract_id": r.id, "end_date": r.end.Format("2006-01-02")},
			DedupeKey: "contract.expired:" + r.id + ":" + r.end.Format("2006-01-02"),
		}})
	}
	return out, nil
}

// overduePatrols: beklenen süre + tolerans aşıldığı hâlde kapatılmamış tur.
// Görevli turu yarıda bırakmış, cihazı kapanmış ya da başına bir şey gelmiş
// olabilir; yönetim bunu turun sonunda değil, aksadığı anda öğrenmelidir.
//
// Planlı tur saatleri (patrol_routes.schedule_times) API'de tanımlanamıyor;
// bu yüzden "hiç başlatılmamış planlı tur" ölçülemez ve burada UYDURULMAZ.
func overduePatrols(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT l.id::text, COALESCE(r.name, 'Güzergâhsız tur'),
		       COALESCE(NULLIF(trim(COALESCE(g.first_name,'') || ' ' || COALESCE(g.last_name,'')), ''), 'görevli'),
		       l.started_at,
		       COALESCE(l.expected_duration_minutes, r.expected_duration_minutes, 30)::int,
		       COALESCE(r.tolerance_minutes, 10)::int,
		       floor(extract(epoch FROM now() - l.started_at) / 60)::int
		FROM patrol_logs l
		LEFT JOIN patrol_routes r ON r.id = l.route_id
		LEFT JOIN users g ON g.id = l.guard_id
		WHERE l.property_id = $1 AND l.status = 'IN_PROGRESS'
		  AND l.started_at + make_interval(mins =>
		        COALESCE(l.expected_duration_minutes, r.expected_duration_minutes, 30)
		        + COALESCE(r.tolerance_minutes, 10)) < now()
		ORDER BY l.started_at`, propertyID)
	if err != nil {
		return nil, err
	}
	type row struct {
		id, route, guard            string
		started                     time.Time
		expected, tolerance, elapse int
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.route, &r.guard, &r.started, &r.expected, &r.tolerance, &r.elapse); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}
	managers, err := notify.Managers(ctx, pool, propertyID)
	if err != nil {
		return nil, err
	}
	out := make([]notice, 0, len(list))
	for _, r := range list {
		out = append(out, notice{recipients: managers, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "patrol.overdue",
			Subject:    "Devriye süresini aştı: " + r.route,
			Body: fmt.Sprintf("%s turu %s tarafından %s saatinde başlatıldı ve %d dakikadır açık "+
				"(beklenen %d dk + tolerans %d dk). Görevliye ulaşıp durumu kontrol edin.",
				r.route, r.guard, r.started.In(istanbul).Format("15:04"), r.elapse, r.expected, r.tolerance),
			Payload:   map[string]any{"patrol_id": r.id, "elapsed_minutes": r.elapse},
			DedupeKey: "patrol.overdue:" + r.id,
		}})
	}
	return out, nil
}

// maintenanceDue: bakım ya da periyodik kontrol tarihi yaklaşan (14 gün) ya da
// geçmiş demirbaş → yönetim (FAZ 7.1).
//
// Asansör yıllık periyodik kontrolü, yangın söndürücü dolumu gibi yasal
// yükümlülükler demirbaşa bakım aralığıyla tanımlanır; aralıklar koda GÖMÜLMEZ
// (yönetmelik değişir, bölüm/teçhizata göre farklıdır) — yönetim girer.
// Önceden tarih geçse bile kimse uyarılmıyordu; ilk fark eden denetim olurdu.
// Her demirbaş ve tarih için iki bildirim olabilir: "yaklaşıyor" ve "geçti".
func maintenanceDue(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT id::text, name, next_maintenance_date, (next_maintenance_date - CURRENT_DATE)::int
		FROM assets
		WHERE property_id = $1 AND deleted = 0 AND status <> 'DISPOSED'
		  AND next_maintenance_date IS NOT NULL
		  AND next_maintenance_date <= CURRENT_DATE + $2::int
		ORDER BY next_maintenance_date`, propertyID, maintenanceLeadDays)
	if err != nil {
		return nil, err
	}
	type row struct {
		id, name string
		due      time.Time
		daysLeft int
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.name, &r.due, &r.daysLeft); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}
	managers, err := notify.Managers(ctx, pool, propertyID)
	if err != nil {
		return nil, err
	}
	out := make([]notice, 0, len(list))
	for _, r := range list {
		state, subject, body := "upcoming", "Bakım tarihi yaklaşıyor: "+r.name,
			fmt.Sprintf("'%s' için bakım/periyodik kontrol tarihi %s (%d gün kaldı). Yetkili firmadan randevu alın; "+
				"bakım yapılınca demirbaş kaydına işleyin.", r.name, trDate(r.due), r.daysLeft)
		if r.daysLeft < 0 {
			state, subject, body = "overdue", "Bakım tarihi geçti: "+r.name,
				fmt.Sprintf("'%s' için bakım/periyodik kontrol tarihi %s idi (%d gün geçti). Yasal yükümlülükse "+
					"(ör. asansör periyodik kontrolü) gecikme sorumluluk doğurabilir; bakımı yaptırıp kayda işleyin.",
					r.name, trDate(r.due), -r.daysLeft)
		}
		out = append(out, notice{recipients: managers, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "asset.maintenance." + state,
			Subject:    subject,
			Body:       body,
			Payload:    map[string]any{"asset_id": r.id, "due_date": r.due.Format("2006-01-02"), "state": state},
			DedupeKey:  "asset.maintenance:" + r.id + ":" + r.due.Format("2006-01-02") + ":" + state,
		}})
	}
	return out, nil
}

// kvkkDue: yasal yanıt süresinin (KVKK m.13/2) son 5 gününe giren ya da süresi
// geçen AÇIK ilgili kişi başvurusu → yönetim. Süre aşımı Kurul'a şikâyet ve
// idari para cezası riskidir; son gün kayda başvuru anında yazılmıştır.
func kvkkDue(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]notice, error) {
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT id::text, request_type, due_date, (due_date - CURRENT_DATE)::int
		FROM kvkk_requests
		WHERE property_id = $1 AND status = 'OPEN' AND due_date <= CURRENT_DATE + 5
		ORDER BY due_date`, propertyID)
	if err != nil {
		return nil, err
	}
	type row struct {
		id, kind string
		due      time.Time
		daysLeft int
	}
	var list []row
	for rows.Next() {
		var r row
		if err := rows.Scan(&r.id, &r.kind, &r.due, &r.daysLeft); err != nil {
			rows.Close()
			return nil, err
		}
		list = append(list, r)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}
	managers, err := notify.Managers(ctx, pool, propertyID)
	if err != nil {
		return nil, err
	}
	out := make([]notice, 0, len(list))
	for _, r := range list {
		state, body := "soon", fmt.Sprintf("Açık bir KVKK başvurusunun yasal yanıt süresi %s tarihinde doluyor (%d gün kaldı; KVKK m.13/2).",
			trDate(r.due), r.daysLeft)
		if r.daysLeft < 0 {
			state, body = "overdue", fmt.Sprintf("Açık bir KVKK başvurusunun yasal yanıt süresi %s tarihinde doldu (%d gün geçti). "+
				"Süre aşımı ilgili kişinin Kurul'a şikâyet hakkını doğurur; başvuruyu hemen sonuçlandırın.", trDate(r.due), -r.daysLeft)
		}
		out = append(out, notice{recipients: managers, msg: notify.Message{
			PropertyID: propertyID,
			Channel:    notify.ChannelInApp,
			Category:   notify.CategoryTransactional,
			Topic:      "kvkk.due." + state,
			Subject:    "KVKK başvurusu yanıt süresi",
			Body:       body,
			Payload:    map[string]any{"kvkk_request_id": r.id, "due_date": r.due.Format("2006-01-02"), "state": state},
			DedupeKey:  "kvkk.due:" + r.id + ":" + state,
		}})
	}
	return out, nil
}
