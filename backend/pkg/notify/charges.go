package notify

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/money"
)

// Yeni borç bildirimi (Şikayetvar raporu §3.2 "habersiz borçlandırma", beşinci tur B1).
//
// Önceden tahakkuk, devir bakiyesi ve işletme projesinden tahakkuk hiçbir bildirim
// üretmiyordu: sakin borcu ancak uygulamayı açınca ya da vade geçip zamanlanmış
// hatırlatma gelince görüyordu ("haberim yoktu"). Üç tahakkuk noktası da bu tek
// fonksiyonu çağırır; metin ve alıcı kümesi tek yerde kalır.
//
// Alıcı borcun SORUMLUSUDUR (AssessmentPayers, 070): kiracılığa bağlı kullanım borcunda kiracı, diğerinde malik ve
// vekil; taşınmış kişiye ve hane üyesine gitmez.
// Bildirim tahakkuk başına bir kez oluşur (dedupe `charge:<tahakkuk>`); aynı çağrı
// yinelenirse çift kayıt açılmaz.

// chargeRow, bildirimi yazılacak tahakkuktur.
type chargeRow struct {
	id, unitID, unit, kind, description string
	year, month                         int
	kurus                               int64
	due                                 time.Time
}

// SupportsChannel, kanal için kayıtlı bir sağlayıcı olup olmadığını söyler.
// E-posta gibi isteğe bağlı kanallar yalnızca sağlayıcı varsa denenir; yoksa her
// alıcı için "kuyrukta bekliyor" kaydı açmak gürültüden ibaret olurdu.
func (n *Notifier) SupportsChannel(channel string) bool {
	return n != nil && n.senderFor(channel) != nil
}

// NotifyCharges, verilen tahakkuklar için daire sakinlerine "yeni borç" bildirimi
// oluşturur ve toplam sonucu döner. n nil ise ya da kimlik yoksa hiçbir şey yapmaz
// ve bunu söyler. Hata asıl işlemi (tahakkuk) geri almaz: borç zaten kayıtlıdır;
// sonuç ve hata metni yanıtta yöneticiye gösterilir.
func NotifyCharges(ctx context.Context, n *Notifier, pool *pgxpool.Pool, propertyID, actorID string, assessmentIDs []string) *BroadcastResult {
	if n == nil {
		return &BroadcastResult{Note: "Bildirim altyapısı kurulu değil; sakinlere bildirim oluşturulmadı."}
	}
	if len(assessmentIDs) == 0 {
		return &BroadcastResult{Note: "Yeni borç kaydı yok; bildirim oluşturulmadı."}
	}
	rows, err := dbscope.For(pool, propertyID).Query(ctx, `
		SELECT ma.id::text, ma.unit_id::text, COALESCE(NULLIF(u.block, ''), '') || '-' || COALESCE(u.door_number, ''),
		       COALESCE(ma.kind, 'REGULAR'), COALESCE(ma.description, ''), ma.period_year, ma.period_month,
		       round(ma.total_amount * 100)::bigint, ma.due_date
		FROM monthly_assessments ma
		JOIN units u ON u.id = ma.unit_id
		WHERE ma.property_id = $1 AND ma.id::text = ANY($2) AND ma.deleted = 0
		ORDER BY u.block, u.door_number`, propertyID, assessmentIDs)
	if err != nil {
		return &BroadcastResult{Failed: len(assessmentIDs), Errors: []string{err.Error()},
			Note: "Yeni borç kayıtları okunamadı; sakinlere bildirim oluşturulmadı."}
	}
	var list []chargeRow
	for rows.Next() {
		var c chargeRow
		if err := rows.Scan(&c.id, &c.unitID, &c.unit, &c.kind, &c.description, &c.year, &c.month, &c.kurus, &c.due); err != nil {
			rows.Close()
			return &BroadcastResult{Failed: len(assessmentIDs), Errors: []string{err.Error()},
				Note: "Yeni borç kayıtları okunamadı; sakinlere bildirim oluşturulmadı."}
		}
		list = append(list, c)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return &BroadcastResult{Failed: len(assessmentIDs), Errors: []string{err.Error()},
			Note: "Yeni borç kayıtları okunamadı; sakinlere bildirim oluşturulmadı."}
	}

	channels := []string{ChannelInApp}
	if n.SupportsChannel(ChannelEmail) {
		channels = append(channels, ChannelEmail)
	}
	total := &BroadcastResult{}
	noResident := 0
	today := time.Now()
	for _, c := range list {
		recipients, err := AssessmentPayers(ctx, pool, propertyID, []string{c.id})
		if err != nil {
			total.Failed++
			if len(total.Errors) < maxReportedErrors {
				total.Errors = append(total.Errors, err.Error())
			}
			continue
		}
		if len(recipients) == 0 {
			noResident++ // maliksiz dairenin malik borcu (V3) ya da sakinsiz bölüm
			continue
		}
		subject, body := chargeText(c, today)
		for _, ch := range channels {
			res := n.Broadcast(ctx, Message{
				PropertyID: propertyID, Channel: ch, Category: CategoryTransactional,
				Topic: "dues.created", Subject: subject, Body: body,
				Payload: map[string]any{
					"assessment_id": c.id, "unit_id": c.unitID, "kind": c.kind,
					"amount_kurus": c.kurus, "due_date": c.due.Format("2006-01-02"),
				},
				DedupeKey: "charge:" + c.id + ":" + strings.ToLower(ch),
				CreatedBy: actorID,
			}, recipients)
			mergeResult(total, res, ch == ChannelInApp)
		}
	}
	total.Note = summarize(total)
	if noResident > 0 {
		total.Note += fmt.Sprintf(" %d borcun kayıtlı sorumlusu olmadığı için bildirim oluşturulmadı (sakinsiz bölüm ya da malik kaydı yok).", noResident)
	}
	if len(channels) == 1 {
		total.Note += " E-posta sağlayıcısı yapılandırılmadığı için yalnız uygulama içi bildirim oluşturuldu."
	}
	return total
}

// chargeText, bildirimin başlığı ve gövdesidir: dönem/tür, tutar ve son ödeme günü.
func chargeText(c chargeRow, today time.Time) (string, string) {
	what := fmt.Sprintf("%04d-%02d dönemi aidatı", c.year, c.month)
	if c.kind == "OPENING" {
		what = "Devir bakiyesi (önceki dönemden devreden borç)"
		if d := strings.TrimSpace(c.description); d != "" && d != "Devir bakiyesi" {
			what += " — " + d
		}
	}
	body := fmt.Sprintf("%s bağımsız bölümü için yeni borç kaydedildi.\n%s: %s\nSon ödeme günü: %s\n"+
		"Ayrıntı ve ödeme için uygulamadaki Aidat ekranına bakın.",
		c.unit, what, money.Kurus(c.kurus).Display(), c.due.Format("02.01.2006"))
	y, m, d := today.Date()
	if c.due.Before(time.Date(y, m, d, 0, 0, 0, 0, c.due.Location())) {
		body += "\nBu borcun son ödeme günü bugünden önceki bir tarih olarak kaydedildi; sorunuz varsa site yönetimiyle görüşün."
	}
	return "Yeni borç: " + money.Kurus(c.kurus).Display(), body
}

// mergeResult, bir gönderim sonucunu toplam sonuca ekler. Alıcı sayısı yalnız bir
// kanaldan sayılır: aynı kişiye uygulama içi + e-posta gitmesi iki alıcı değildir.
func mergeResult(total, r *BroadcastResult, countRecipients bool) {
	if countRecipients {
		total.Recipients += r.Recipients
	}
	total.Sent += r.Sent
	total.Pending += r.Pending
	total.Suppressed += r.Suppressed
	total.Failed += r.Failed
	total.Duplicate += r.Duplicate
	total.NoAddress += r.NoAddress
	for _, e := range r.Errors {
		if len(total.Errors) < maxReportedErrors {
			total.Errors = append(total.Errors, e)
		}
	}
}
