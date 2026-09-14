package notify

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
)

// Bu dosya, MODÜLLERİN bildirim göndermesini mümkün kılar.
//
// Neden ayrı bir dosya: kargo, rezervasyon, anket, duyuru ve stok modülleri
// "kime gönderilecek?" sorusunu kendi başlarına çözerse, aynı sorgu beş kez
// yazılır ve beşi de zamanla birbirinden ayrışır. Bir tanesinde `is_active`
// filtresi unutulduğunda, siteden taşınmış birine bildirim gider ve bunu
// kimse fark etmez.
//
// Bu yüzden alıcı kümesi TEK YERDE tanımlanır.

// ErrNoPool, havuz verilmediğinde döner.
var ErrNoPool = errors.New("bildirim alıcıları için veritabanı havuzu gerekli")

// Recipient, bildirim alacak kişidir.
//
// UnitID bilgisi taşınır çünkü bazı bildirimler (kargo, rezervasyon) bir
// bağımsız bölüme aittir ve alıcı listesi oradan türer.
type Recipient struct {
	UserID string
	UnitID string
	// Role: OWNER / TENANT / PROXY (634 s. KMK'daki sıfatlar).
	Role string
}

// Residents, sitenin AKTİF sakinlerini döner (malik, kiracı, vekil).
//
// Aynı kişi birden çok bağımsız bölümde sakin olabilir; bu fonksiyon kişiyi
// TEK KEZ döner. Aksi hâlde iki daireli bir malik her duyuruyu iki kez alırdı.
//
// `is_active` ve `end_date` filtresi bilerek buradadır: siteden taşınmış
// birine site duyurusu göndermek, KVKK m.4 ölçülülük ilkesine aykırıdır.
func Residents(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]Recipient, error) {
	return queryRecipients(ctx, pool, propertyID, `
		SELECT DISTINCT ON (ru.resident_id)
		       ru.resident_id::text, ru.unit_id::text, ru.role
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1
		  AND COALESCE(ru.is_active, true)
		  AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)
		ORDER BY ru.resident_id, ru.role`, propertyID)
}

// UnitResidents, tek bir bağımsız bölümün aktif sakinlerini döner.
//
// Kargo ve rezervasyon gibi konularda bildirim yalnızca ilgili daireye gider;
// tüm siteye göndermek hem gereksiz hem de kişisel veriyi yayan bir davranış
// olurdu (bir dairenin kargosu diğer sakinleri ilgilendirmez).
func UnitResidents(ctx context.Context, pool *pgxpool.Pool, propertyID, unitID string) ([]Recipient, error) {
	if unitID == "" {
		return nil, nil
	}
	return queryRecipients(ctx, pool, propertyID, `
		SELECT DISTINCT ON (ru.resident_id)
		       ru.resident_id::text, ru.unit_id::text, ru.role
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1 AND ru.unit_id = $2::uuid
		  AND COALESCE(ru.is_active, true)
		  AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE)
		ORDER BY ru.resident_id, ru.role`, propertyID, unitID)
}

// Managers, sitenin yönetim yetkisi olan kullanıcılarını döner.
//
// Stok azalması, devriye aksaması gibi konular sakinleri değil YÖNETİMİ
// ilgilendirir. Bu ayrımı yapmamak, sakinlere anlamsız bildirim yağdırır ve
// bildirimlerin tamamının kapatılmasına yol açar.
func Managers(ctx context.Context, pool *pgxpool.Pool, propertyID string) ([]Recipient, error) {
	// Roller `property_roles` tablosundaki CHECK kısıtıyla sınırlıdır
	// (013 numaralı migration): MANAGER, AUDITOR, STAFF, BOARD_MEMBER.
	// STAFF dışarıda bırakıldı: görevli personel, yönetim kararlarının
	// muhatabı değildir.
	return queryRecipients(ctx, pool, propertyID, `
		SELECT DISTINCT ON (pr.user_id) pr.user_id::text, ''::text, pr.role
		FROM property_roles pr
		WHERE pr.property_id = $1
		  AND pr.role IN ('MANAGER','BOARD_MEMBER','AUDITOR')
		  AND pr.is_active
		  AND pr.valid_from <= CURRENT_DATE
		  AND (pr.valid_to IS NULL OR pr.valid_to >= CURRENT_DATE)
		ORDER BY pr.user_id, pr.role`, propertyID)
}

func queryRecipients(ctx context.Context, pool *pgxpool.Pool, propertyID, sql string,
	args ...any) ([]Recipient, error) {
	if pool == nil {
		return nil, ErrNoPool
	}
	if propertyID == "" {
		return nil, dbscope.ErrNoProperty
	}
	rows, err := dbscope.For(pool, propertyID).Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Recipient{}
	for rows.Next() {
		var r Recipient
		if err := rows.Scan(&r.UserID, &r.UnitID, &r.Role); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// BroadcastResult, toplu gönderimin SONUCUDUR.
//
// Neden sayaçlar: "bildirim gönderildi" demek yetmez. Alıcı kalmadıysa,
// herkes kanalı kapattıysa ya da kayıt sağlayıcısız kuyrukta beklediyse,
// çağıran bunu GÖRMELİDİR. Bu yapı olmadan modüller "gönderildi" der,
// gerçekte hiçbir şey gitmez ve fark edilmesi aylar alır.
type BroadcastResult struct {
	// Recipients, hedeflenen alıcı sayısıdır.
	Recipients int `json:"recipients"`
	Sent       int `json:"sent"`
	Pending    int `json:"pending"`
	Suppressed int `json:"suppressed"`
	Failed     int `json:"failed"`
	// Duplicate, dedupe anahtarı yüzünden atlananlardır (hata değildir).
	Duplicate int `json:"duplicate"`
	// Note, sonucu insan diliyle özetler; API yanıtına olduğu gibi konur.
	Note string `json:"note"`
	// Errors, ilk birkaç hatanın metnidir. Tamamı değil: bin alıcılı bir
	// sitede bin hata metnini yanıta koymak yanıtı kullanılamaz hâle getirir.
	Errors []string `json:"errors,omitempty"`
}

// maxReportedErrors, yanıta konulacak en fazla hata sayısı.
const maxReportedErrors = 5

// Broadcast, aynı bildirimi birden çok alıcıya kuyruğa alır.
//
// base.RecipientUserID ve base.Recipient DOLDURULMAZ; her alıcı için bu
// paket doldurur. base.DedupeKey verilmişse alıcı kimliği sonuna eklenir:
// aksi hâlde ikinci alıcının kaydı "zaten kuyrukta" sayılır ve SESSİZCE
// düşerdi — tam olarak bu paketin engellemek için var olduğu şey.
//
// Bir alıcıya gönderim başarısız olursa diğerleri denenmeye DEVAM EDER;
// tek bir sakinin kapalı kanalı yüzünden tüm duyurunun iptal olması doğru
// olmazdı. Başarısızlıklar sayılır ve sonuçta raporlanır.
func (n *Notifier) Broadcast(ctx context.Context, base Message, recipients []Recipient) *BroadcastResult {
	res := &BroadcastResult{Recipients: len(recipients)}
	if len(recipients) == 0 {
		res.Note = "Bildirim alacak kayıtlı sakin bulunamadı; HİÇBİR bildirim oluşturulmadı."
		return res
	}

	baseDedupe := base.DedupeKey
	for _, r := range recipients {
		m := base
		m.RecipientUserID = r.UserID
		// Uygulama içi bildirimde adres kullanıcı kimliğidir: kayıt zaten
		// veritabanındadır, dışarı çıkan bir adres yoktur.
		m.Recipient = r.UserID
		if baseDedupe != "" {
			m.DedupeKey = baseDedupe + ":" + r.UserID
		}

		out, err := n.Enqueue(ctx, m)
		if err != nil {
			if errors.Is(err, ErrDuplicate) {
				res.Duplicate++
				continue
			}
			res.Failed++
			if len(res.Errors) < maxReportedErrors {
				res.Errors = append(res.Errors, err.Error())
			}
			continue
		}
		switch out.Status {
		case "SENT":
			res.Sent++
		case "SUPPRESSED":
			res.Suppressed++
		case "FAILED":
			res.Failed++
			if out.Reason != "" && len(res.Errors) < maxReportedErrors {
				res.Errors = append(res.Errors, out.Reason)
			}
		default:
			res.Pending++
		}
	}
	res.Note = summarize(res)
	return res
}

// summarize, sonucu tek cümleyle ve ABARTMADAN anlatır.
//
// "Gönderildi" sözcüğü yalnızca gerçekten gönderilen kayıt varsa geçer.
// Kuyrukta bekleyen bir kayıt için "gönderildi" demek, sakine yalan
// söylemektir.
func summarize(r *BroadcastResult) string {
	if r.Sent == 0 && r.Pending == 0 && r.Suppressed == 0 && r.Failed == 0 {
		return "Bildirim oluşturulmadı."
	}
	s := fmt.Sprintf("%d alıcı için bildirim oluşturuldu", r.Recipients)
	if r.Sent > 0 {
		s += fmt.Sprintf("; %d tanesi iletildi", r.Sent)
	}
	if r.Pending > 0 {
		s += fmt.Sprintf("; %d tanesi sağlayıcı olmadığı için kuyrukta BEKLİYOR "+
			"(GÖNDERİLMEDİ)", r.Pending)
	}
	if r.Suppressed > 0 {
		s += fmt.Sprintf("; %d tanesi alıcı tercihi/onayı nedeniyle gönderilmedi", r.Suppressed)
	}
	if r.Duplicate > 0 {
		s += fmt.Sprintf("; %d tanesi daha önce oluşturulduğu için atlandı", r.Duplicate)
	}
	if r.Failed > 0 {
		s += fmt.Sprintf("; %d tanesi BAŞARISIZ", r.Failed)
	}
	return s + "."
}

// FromEnvOrNil, servislerin tek satırla bildirim kurmasını sağlar.
//
// Havuz yoksa nil döner; çağıran `if notifier != nil` ile korur. Sessizce
// çalışmayan bir Notifier döndürmek, "bildirim gitti" sanılmasına yol açardı.
func FromEnvOrNil(pool *pgxpool.Pool) *Notifier {
	if pool == nil {
		return nil
	}
	return New(pool, SendersFromEnv()...)
}
