// Package repository, NPS (memnuniyet ölçümü) modülünün veritabanı işlemlerini içerir.
//
// Ayrı bir tablo YOKTUR: NPS, anket altyapısının (surveys / survey_options /
// survey_votes) özel bir kullanımıdır. 0-10 arası on bir seçenekli, anonim bir
// anket açılır ve sonuç NPS tanımına göre hesaplanır. Ayrı bir şema açmak,
// aynı veriyi iki yerde tutmak ve iki ayrı "kim oy verdi" mantığı yazmak olurdu.
package repository

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrNotFound     = errors.New("memnuniyet anketi bulunamadı")
	ErrBadState     = errors.New("anket bu işlem için uygun durumda değil")
	ErrAlreadyVoted = errors.New("bu ankete zaten yanıt verdiniz")
	ErrNotEligible  = errors.New("sitede aktif bir bağımsız bölümünüz yok")
	ErrInvalidScore = errors.New("puan 0-10 arasında olmalıdır")
)

// topicPrefix, NPS anketlerini diğer anketlerden ayırmak için başlık ön ekidir.
// Ayrı bir kolon eklemek yerine ön ek kullanmak, mevcut şemaya dokunmadan
// ayrımı mümkün kılar ve anket servisi bu kayıtları olduğu gibi gösterebilir.
const topicPrefix = "[NPS] "

// Survey, bir memnuniyet ölçümüdür.
type Survey struct {
	ID          string     `json:"id"`
	Title       string     `json:"title"`
	Description string     `json:"description,omitempty"`
	Status      string     `json:"status"`
	StartsAt    time.Time  `json:"starts_at"`
	EndsAt      *time.Time `json:"ends_at,omitempty"`
	Eligible    int        `json:"eligible_respondents"`
	Responses   int        `json:"responses"`
	HasAnswered bool       `json:"has_answered"`
}

// Comment, ankete bırakılan açık uçlu yorumdur.
type Comment struct {
	Score     *int      `json:"score,omitempty"`
	Comment   string    `json:"comment"`
	CreatedAt time.Time `json:"created_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

// Create, 0-10 seçenekli anonim memnuniyet anketi açar.
func (r *Repository) Create(ctx context.Context, propertyID, userID, title, description string, endsAt *time.Time) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	// Uygun yanıtlayan sayısı: sitede oturan herkes. Anket açılırken dondurulur
	// ki katılım oranı sonradan değişmesin.
	var eligible int
	if err := tx.QueryRow(ctx, `
		SELECT count(DISTINCT ru.resident_id)
		FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1 AND ru.is_active = true`, propertyID).Scan(&eligible); err != nil {
		return "", err
	}

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO surveys
			(property_id, title, description, survey_type, is_anonymous, is_weighted,
			 allow_comments, show_results_before_end, starts_at, ends_at,
			 status, total_eligible_voters, created_by)
		VALUES ($1,$2,NULLIF($3,''),'SURVEY',true,false,true,false,now(),$4,
		        'ACTIVE',$5,$6)
		RETURNING id`,
		propertyID, topicPrefix+title, description, endsAt, eligible, userID).Scan(&id); err != nil {
		return "", err
	}

	// 0'dan 10'a on bir seçenek. Sıra numarası puanın kendisidir; böylece
	// seçenek metni değişse bile puan display_order'dan güvenle okunur.
	for i := 0; i <= 10; i++ {
		if _, err := tx.Exec(ctx, `
			INSERT INTO survey_options (survey_id, option_text, display_order)
			VALUES ($1,$2,$3)`, id, strconv.Itoa(i), i); err != nil {
			return "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

const surveySelect = `
SELECT s.id, s.title, COALESCE(s.description,''), s.status, s.starts_at, s.ends_at,
       COALESCE(s.total_eligible_voters,0),
       (SELECT count(*) FROM survey_votes v WHERE v.survey_id = s.id),
       EXISTS(SELECT 1 FROM survey_votes v
              WHERE v.survey_id = s.id AND v.voter_id = NULLIF($2,'')::uuid)
FROM surveys s`

func scanSurvey(row pgx.Row) (*Survey, error) {
	var s Survey
	if err := row.Scan(&s.ID, &s.Title, &s.Description, &s.Status, &s.StartsAt,
		&s.EndsAt, &s.Eligible, &s.Responses, &s.HasAnswered); err != nil {
		return nil, err
	}
	s.Title = strings.TrimPrefix(s.Title, topicPrefix)
	return &s, nil
}

// List, memnuniyet anketlerini getirir.
func (r *Repository) List(ctx context.Context, propertyID, userID string) ([]Survey, error) {
	rows, err := r.pool.Query(ctx, surveySelect+`
		WHERE s.property_id = $1 AND s.title LIKE $3 || '%'
		ORDER BY s.starts_at DESC
		LIMIT 100`, propertyID, userID, topicPrefix)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Survey{}
	for rows.Next() {
		s, err := scanSurvey(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *s)
	}
	return out, rows.Err()
}

// Get, tek anketi getirir.
func (r *Repository) Get(ctx context.Context, propertyID, id, userID string) (*Survey, error) {
	s, err := scanSurvey(r.pool.QueryRow(ctx, surveySelect+`
		WHERE s.property_id = $1 AND s.id = $3 AND s.title LIKE $4 || '%'`,
		propertyID, userID, id, topicPrefix))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	return s, err
}

// Respond, 0-10 arası puanı ve isteğe bağlı yorumu kaydeder.
func (r *Repository) Respond(ctx context.Context, propertyID, surveyID, userID string, score int, comment string) error {
	if score < 0 || score > 10 {
		return ErrInvalidScore
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status string
	var endsAt *time.Time
	if err := tx.QueryRow(ctx, `
		SELECT status, ends_at FROM surveys
		WHERE id = $1 AND property_id = $2 AND title LIKE $3 || '%'`,
		surveyID, propertyID, topicPrefix).Scan(&status, &endsAt); err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotFound
		}
		return err
	}
	if status != "ACTIVE" {
		return ErrBadState
	}
	if endsAt != nil && time.Now().After(*endsAt) {
		return ErrBadState
	}

	// Yanıt verebilmek için sitede oturuyor olmak gerekir.
	var unitID string
	if err := tx.QueryRow(ctx, `
		SELECT ru.unit_id::text FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE ru.resident_id = $1 AND ru.is_active = true AND u.property_id = $2
		LIMIT 1`, userID, propertyID).Scan(&unitID); err != nil {
		if err == pgx.ErrNoRows {
			return ErrNotEligible
		}
		return err
	}

	var optionID string
	if err := tx.QueryRow(ctx, `
		SELECT id FROM survey_options WHERE survey_id = $1 AND display_order = $2`,
		surveyID, score).Scan(&optionID); err != nil {
		return err
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO survey_votes (survey_id, option_id, voter_id, unit_id, weight, comment)
		VALUES ($1,$2,$3,NULLIF($4,'')::uuid,1,NULLIF($5,''))`,
		surveyID, optionID, userID, unitID, strings.TrimSpace(comment)); err != nil {
		if strings.Contains(err.Error(), "duplicate key") {
			return ErrAlreadyVoted
		}
		return err
	}
	return tx.Commit(ctx)
}

// Scores, ankete verilen puanları döner.
//
// Puan, seçeneğin display_order değerinden okunur: metin değişse bile puan
// bozulmaz.
func (r *Repository) Scores(ctx context.Context, propertyID, surveyID string) ([]int, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT o.display_order
		FROM survey_votes v
		JOIN survey_options o ON o.id = v.option_id
		JOIN surveys s ON s.id = v.survey_id
		WHERE v.survey_id = $1 AND s.property_id = $2`, surveyID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []int{}
	for rows.Next() {
		var n int
		if err := rows.Scan(&n); err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

// Comments, açık uçlu yorumları döner.
//
// Anket ANONİMDİR: yanıtlayanın adı hiçbir koşulda döndürülmez. Puanla yorum
// birlikte gösterilir çünkü "3 verdim çünkü asansör sürekli bozuk" bilgisi
// yönetim için asıl değerli olan şeydir.
func (r *Repository) Comments(ctx context.Context, propertyID, surveyID string) ([]Comment, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT o.display_order, v.comment, v.voted_at
		FROM survey_votes v
		JOIN survey_options o ON o.id = v.option_id
		JOIN surveys s ON s.id = v.survey_id
		WHERE v.survey_id = $1 AND s.property_id = $2
		  AND v.comment IS NOT NULL AND v.comment <> ''
		ORDER BY o.display_order, v.voted_at
		LIMIT 300`, surveyID, propertyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Comment{}
	for rows.Next() {
		var c Comment
		var score int
		if err := rows.Scan(&score, &c.Comment, &c.CreatedAt); err != nil {
			return nil, err
		}
		s := score
		c.Score = &s
		out = append(out, c)
	}
	return out, rows.Err()
}

// Close, anketi sonlandırır.
func (r *Repository) Close(ctx context.Context, propertyID, id string) error {
	tag, err := r.pool.Exec(ctx, `
		UPDATE surveys SET status = 'ENDED', ends_at = COALESCE(ends_at, now()), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'ACTIVE' AND title LIKE $3 || '%'`,
		id, propertyID, topicPrefix)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrBadState
	}
	return nil
}
