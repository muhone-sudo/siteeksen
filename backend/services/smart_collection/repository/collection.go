// Package repository, tahsilat riski modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
	svc "github.com/siteeksen/backend/services/smart_collection/service"
)

// ErrNoUnits, sitede hiç bağımsız bölüm yoksa döner.
var ErrNoUnits = errors.New("sitede bağımsız bölüm yok")

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// Histories, her bağımsız bölümün ödeme geçmişi özetini döner.
//
// "Zamanında ödendi" tanımı: tahakkuk tamamen ödenmiş VE son ödeme tarihinden
// sonra güncellenmemiş. Ödeme tarihi ayrı bir kolonda tutulmadığı için
// `updated_at` kullanılır; bu yaklaşım kayıt düzeltmelerinde yanılabilir ve
// bu sınır yanıtta belirtilir.
//
// Borç, `total_amount - paid_amount` üzerinden hesaplanır; hiçbir yerde
// varsayılan ya da tahmin kullanılmaz.
func (r *Repository) Histories(ctx context.Context, propertyID string) ([]svc.History, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT u.id::text,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       count(a.id)::int,
		       count(a.id) FILTER (
		           WHERE COALESCE(a.paid_amount,0) >= a.total_amount
		             AND a.updated_at::date <= a.due_date)::int,
		       count(a.id) FILTER (
		           WHERE COALESCE(a.paid_amount,0) >= a.total_amount
		             AND a.updated_at::date > a.due_date)::int,
		       count(a.id) FILTER (WHERE COALESCE(a.paid_amount,0) < a.total_amount)::int,
		       COALESCE(AVG(GREATEST(a.updated_at::date - a.due_date, 0)) FILTER (
		           WHERE COALESCE(a.paid_amount,0) >= a.total_amount
		             AND a.updated_at::date > a.due_date), 0)::text,
		       COALESCE(SUM(a.total_amount - COALESCE(a.paid_amount,0)) FILTER (
		           WHERE COALESCE(a.paid_amount,0) < a.total_amount), 0)::text,
		       count(a.id) FILTER (
		           WHERE COALESCE(a.paid_amount,0) < a.total_amount
		             AND a.due_date < CURRENT_DATE)::int,
		       COALESCE(MAX(CURRENT_DATE - a.due_date) FILTER (
		           WHERE COALESCE(a.paid_amount,0) < a.total_amount
		             AND a.due_date < CURRENT_DATE), 0)::int
		FROM units u
		LEFT JOIN monthly_assessments a ON a.unit_id = u.id AND a.property_id = $1
		WHERE u.property_id = $1
		GROUP BY u.id, u.block, u.door_number
		ORDER BY u.block, u.door_number`, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []svc.History{}
	for rows.Next() {
		var h svc.History
		var avgDelay, debt string
		if err := rows.Scan(&h.UnitID, &h.UnitName, &h.TotalAssessments,
			&h.PaidOnTime, &h.PaidLate, &h.Unpaid, &avgDelay, &debt,
			&h.OverdueCount, &h.LongestOverdueDays); err != nil {
			return nil, err
		}
		if h.AverageDelayDays, err = decimal.NewFromString(avgDelay); err != nil {
			h.AverageDelayDays = decimal.Zero
		}
		if h.CurrentDebt, err = decimal.NewFromString(debt); err != nil {
			h.CurrentDebt = decimal.Zero
		}
		out = append(out, h)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return nil, ErrNoUnits
	}
	return out, nil
}

// SaveScores, hesaplanan skorları kaydeder (dönemsel karşılaştırma için).
//
// `ai_model_version` ve `predicted_payment_probability` alanları BİLEREK boş
// bırakılır: model yoktur, olasılık hesaplanmaz. Boş bırakmak, uydurma bir
// değerle doldurmaktan iyidir.
// Dönen sayı GERÇEKTEN yazılan satır sayısıdır. Önceden çağıran len(list)
// yazıyordu; geçmişi olmayan (atlanan) bölümler de "kaydedildi" sayılıyordu.
func (r *Repository) SaveScores(ctx context.Context, propertyID string, list []svc.Assessment) (int, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	saved := 0

	// Aynı günün ikinci çalıştırması önceki kaydı tekrarlamaz.
	if _, err := tx.Exec(ctx,
		`DELETE FROM payment_risk_scores WHERE property_id = $1 AND analysis_date = CURRENT_DATE`,
		propertyID); err != nil {
		return 0, err
	}

	for _, a := range list {
		if a.TotalAssessments == 0 {
			// Geçmişi olmayan bölüm için skor saklanmaz.
			continue
		}
		saved++
		if _, err := tx.Exec(ctx, `
			INSERT INTO payment_risk_scores
				(property_id, unit_id, risk_score, risk_category,
				 total_assessments, paid_on_time, paid_late, unpaid,
				 average_delay_days, current_debt, suggested_strategy,
				 recommendations, analysis_date)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::numeric,$10::numeric,$11,$12,CURRENT_DATE)`,
			propertyID, a.UnitID, a.Score, a.Category,
			a.TotalAssessments, a.PaidOnTime, a.PaidLate, a.Unpaid,
			a.AverageDelayDays, a.CurrentDebt, a.Action, factorsJSON(a)); err != nil {
			return 0, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return 0, err
	}
	return saved, nil
}

// factorsJSON, skor bileşenlerini kayda uygun biçime çevirir.
// Gerekçeler saklanır: bir ay sonra "bu daire neden kritikti?" sorusunun
// cevabı kayıtta bulunmalıdır.
func factorsJSON(a svc.Assessment) []map[string]any {
	out := make([]map[string]any, 0, len(a.Factors)+1)
	for _, f := range a.Factors {
		out = append(out, map[string]any{
			"code": f.Code, "points": f.Points, "reason": f.Detail,
		})
	}
	out = append(out, map[string]any{
		"code": "SUGGESTED_ACTION", "action": a.Action, "reason": a.ActionReason,
	})
	return out
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// `payment_risk_scores` ve okunan `monthly_assessments` tablolarında RLS
// açıktır (migration 024).
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}
