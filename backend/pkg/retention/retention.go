// Package retention, KVKK periyodik imhasını uygular (FAZ 7.8, migration 043).
//
// Saklama süresi site tarafından kategori bazında tanımlanır (data_retention_rules);
// kural yoksa o kategoride imha YAPILMAZ. İmha anonimleştirmedir: kayıt ve
// tarihleri kalır, kişiyi belirleyen alanlar silinir. Her çalıştırma — sıfır kayıt
// etkilense bile — data_destruction_log'a yazılır (İmha Yönetmeliği m.7/3).
package retention

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/legalparams"
)

// Anonymized, anonimleştirilmiş ad alanına yazılan değerdir.
const Anonymized = "[imha edildi]"

// Category, imha edilebilir veri kategorisidir.
type Category struct {
	Code        string `json:"code"`
	Title       string `json:"title"`
	Fields      string `json:"fields"`
	Condition   string `json:"condition"`
	Method      string `json:"method"` // ANONYMIZE | DELETE
	updateQuery string
}

// Categories, desteklenen kategoriler. Sorgu $1 = site, $2 = kesim zamanı alır.
var Categories = []Category{
	{Code: "VISITOR", Method: "ANONYMIZE", Title: "Ziyaretçi kayıtları", Fields: "ad soyad, telefon, kimlik no, firma, fotoğraf bağlantısı, plaka, ziyaret nedeni, not",
		Condition: "ziyareti bitmiş (çıkış/iptal/gelmedi) ve ziyaret zamanı saklama süresinden eski",
		updateQuery: `UPDATE visitors SET visitor_name = '` + Anonymized + `', visitor_phone = NULL,
			visitor_id_number = NULL, visitor_company = NULL, visitor_photo_url = NULL, vehicle_plate = NULL,
			visit_reason = NULL, notes = NULL
			WHERE property_id = $1 AND status IN ('CHECKED_OUT','CANCELLED','NO_SHOW')
			  AND COALESCE(checked_in_at, expected_at, created_at) < $2 AND visitor_name <> '` + Anonymized + `'`},
	{Code: "PARKING_LOG", Method: "ANONYMIZE", Title: "Otopark giriş-çıkış kayıtları", Fields: "plaka, giriş/çıkış fotoğraf bağlantısı",
		Condition: "çıkışı yapılmış ve giriş zamanı saklama süresinden eski",
		updateQuery: `UPDATE parking_logs SET plate = '[imha]', entry_photo_url = NULL, exit_photo_url = NULL
			WHERE property_id = $1 AND exit_at IS NOT NULL AND entry_at < $2 AND plate <> '[imha]'`},
	{Code: "PACKAGE", Method: "ANONYMIZE", Title: "Kargo kayıtları", Fields: "alıcı adı, telefon, teslim alan, takip no, imza/fotoğraf bağlantısı",
		Condition: "teslim edilmiş/iade edilmiş ve teslim alma zamanı saklama süresinden eski",
		// Teslim kanıtı dosyalarının anahtarı silinmeden önce kuyruğa bırakılır; kargo
		// servisi (depoya erişimi olan tek servis) kuyruğu işleyip dosyaları siler (052).
		updateQuery: `WITH due AS (
				SELECT id, property_id, delivery_signature_url, delivery_photo_url FROM packages
				WHERE property_id = $1 AND status IN ('DELIVERED','RETURNED') AND received_at < $2
				  AND recipient_name <> '` + Anonymized + `'),
			queued AS (
				INSERT INTO storage_deletion_queue (property_id, storage_key, reason)
				SELECT property_id, k, 'KVKK_RETENTION' FROM due, unnest(ARRAY[delivery_signature_url, delivery_photo_url]) AS k
				WHERE k IS NOT NULL AND k LIKE 'packages/%')
			UPDATE packages p SET recipient_name = '` + Anonymized + `', recipient_phone = NULL, delivered_to_name = NULL,
				tracking_number = NULL, photo_url = NULL, delivery_signature_url = NULL, delivery_photo_url = NULL,
				delivery_signature_sha256 = NULL, delivery_photo_sha256 = NULL
			FROM due WHERE p.id = due.id`},
	{Code: "CLIENT_ERROR", Method: "DELETE", Title: "Uygulama hata raporları", Fields: "hata metni, yığın izi, kullanıcı kimliği",
		Condition:   "rapor zamanı saklama süresinden eski (kayıt silinir)",
		updateQuery: `DELETE FROM client_error_reports WHERE property_id = $1 AND created_at < $2`},
}

// Lookup kategoriyi döner.
func Lookup(code string) (Category, bool) {
	for _, c := range Categories {
		if c.Code == code {
			return c, true
		}
	}
	return Category{}, false
}

// Result, bir kategorinin imha sonucudur.
type Result struct {
	Category string    `json:"category"`
	Cutoff   time.Time `json:"cutoff"`
	Count    int64     `json:"count"`
	Skipped  string    `json:"skipped,omitempty"` // çalışmadıysa nedeni
}

// Run, sitenin kurallarına göre imhayı uygular. force=false iken bir kategori,
// son çalıştırmasının üzerinden periyodik süre (KVKK_PERIODIC_DESTRUCTION_MONTHS)
// geçmemişse atlanır. Kural tanımlanmamış kategoriler "kural yok" olarak döner.
func Run(ctx context.Context, pool *pgxpool.Pool, propertyID string, now time.Time, executedBy string, force bool) ([]Result, error) {
	months, err := legalparams.New(pool).Int(ctx, propertyID, legalparams.KVKKPeriodicDestructionMonths, now)
	if err != nil {
		return nil, err
	}
	scope := dbscope.For(pool, propertyID)
	out := []Result{}
	for _, cat := range Categories {
		var retention *int
		var last *time.Time
		if err := scope.QueryRow(ctx, `
			SELECT (SELECT retention_months FROM data_retention_rules WHERE property_id = $1 AND category = $2),
			       (SELECT max(executed_at) FROM data_destruction_log WHERE property_id = $1 AND category = $2)`,
			propertyID, cat.Code).Scan(&retention, &last); err != nil {
			return nil, err
		}
		if retention == nil {
			out = append(out, Result{Category: cat.Code, Skipped: "saklama süresi tanımlı değil"})
			continue
		}
		if !force && last != nil && last.AddDate(0, months, 0).After(now) {
			out = append(out, Result{Category: cat.Code, Skipped: "periyodik süre dolmadı"})
			continue
		}
		cutoff := now.AddDate(0, -*retention, 0)
		tx, err := scope.Begin(ctx)
		if err != nil {
			return nil, err
		}
		tag, err := tx.Exec(ctx, cat.updateQuery, propertyID, cutoff)
		if err != nil {
			_ = tx.Rollback(ctx)
			return nil, fmt.Errorf("%s imhası: %w", cat.Code, err)
		}
		if _, err := tx.Exec(ctx, `INSERT INTO data_destruction_log (property_id, category, method, cutoff, record_count, executed_by)
			VALUES ($1, $2, $3, $4, $5, $6)`, propertyID, cat.Code, cat.Method, cutoff, tag.RowsAffected(), executedBy); err != nil {
			_ = tx.Rollback(ctx)
			return nil, err
		}
		if err := tx.Commit(ctx); err != nil {
			return nil, err
		}
		out = append(out, Result{Category: cat.Code, Cutoff: cutoff, Count: tag.RowsAffected()})
	}
	return out, nil
}
