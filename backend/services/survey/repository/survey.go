// Package repository, anket/oylama modülünün veritabanı işlemlerini içerir.
package repository

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
)

var (
	ErrInvalidType      = errors.New("anket türü geçersiz")
	ErrNotFound         = errors.New("anket bulunamadı")
	ErrBadState         = errors.New("anket bu işlem için uygun durumda değil")
	ErrAlreadyVoted     = errors.New("bu ankete zaten oy verdiniz")
	ErrNotEligible      = errors.New("bu oylamada oy hakkınız yok")
	ErrNotStarted       = errors.New("oylama henüz başlamadı")
	ErrEnded            = errors.New("oylama sona erdi")
	ErrInvalidOption    = errors.New("seçenek bu ankete ait değil")
	ErrNeedsTwoOptions  = errors.New("anket en az iki seçenek içermelidir")
	ErrGeneralAssembly  = errors.New("genel kurul kararı bu servisten alınamaz")
	ErrResultsNotPublic = errors.New("sonuçlar oylama bitmeden açıklanmıyor")
	ErrInvalidDate      = errors.New("tarih geçersiz")
)

// Types, şemadaki CHECK kısıtıyla birebir aynıdır.
//
// GENERAL_ASSEMBLY bilerek DESTEKLENMEZ: genel kurul kararı KMK m.29-32 uyarınca
// usulüne uygun çağrı, nisap ve karar defteri gerektirir; bunlar governance
// servisindedir. Buradan "genel kurul kararı" üretmek, hukuken geçersiz bir
// kararı geçerli göstermek olurdu.
var Types = []string{"POLL", "SURVEY", "VOTE"}

// Survey, bir anket/oylamadır.
type Survey struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Description string `json:"description,omitempty"`
	SurveyType  string `json:"survey_type"`

	IsAnonymous   bool `json:"is_anonymous"`
	IsWeighted    bool `json:"is_weighted"`
	AllowComments bool `json:"allow_comments"`
	ShowResults   bool `json:"show_results_before_end"`

	StartsAt time.Time  `json:"starts_at"`
	EndsAt   *time.Time `json:"ends_at,omitempty"`
	Status   string     `json:"status"`

	EligibleVoters int    `json:"eligible_voters"`
	TotalVotes     int    `json:"total_votes"`
	Participation  string `json:"participation_rate"`

	CreatedByName string    `json:"created_by_name,omitempty"`
	CreatedAt     time.Time `json:"created_at"`

	// HasVoted, isteği yapanın oy verip vermediğini gösterir.
	HasVoted bool `json:"has_voted"`
	// Options yalnızca tekil okumada doldurulur.
	Options []Option `json:"options,omitempty"`
}

// Option, bir anket seçeneğidir. Sayımlar SAKLANAN kolonlardan değil, oylardan
// hesaplanır — saklanan sayaç bir kez bozulursa sonuç sessizce yanlış kalır.
type Option struct {
	ID          string `json:"id"`
	Text        string `json:"option_text"`
	Description string `json:"description,omitempty"`
	Order       int    `json:"display_order"`

	// VoteCount ve WeightedShare yalnızca sonuç görünürken doldurulur.
	VoteCount     *int    `json:"vote_count,omitempty"`
	WeightedShare *string `json:"weighted_share,omitempty"`
	Percentage    *string `json:"percentage,omitempty"`
}

// Comment, anket yorumudur.
type Comment struct {
	VoterName string    `json:"voter_name,omitempty"`
	Comment   string    `json:"comment"`
	VotedAt   time.Time `json:"voted_at"`
}

type Repository struct{ pool *pgxpool.Pool }

func New(pool *pgxpool.Pool) *Repository { return &Repository{pool: pool} }

const surveySelect = `
SELECT s.id, s.title, COALESCE(s.description,''), s.survey_type,
       COALESCE(s.is_anonymous,true), COALESCE(s.is_weighted,false),
       COALESCE(s.allow_comments,true), COALESCE(s.show_results_before_end,false),
       s.starts_at, s.ends_at, s.status,
       COALESCE(s.total_eligible_voters,0),
       (SELECT count(*) FROM survey_votes v WHERE v.survey_id = s.id),
       COALESCE(u.first_name || ' ' || u.last_name, ''), s.created_at,
       EXISTS(SELECT 1 FROM survey_votes v WHERE v.survey_id = s.id AND v.voter_id = NULLIF($2,'')::uuid)
FROM surveys s
LEFT JOIN users u ON u.id = s.created_by`

func scanSurvey(row pgx.Row) (*Survey, error) {
	var s Survey
	err := row.Scan(&s.ID, &s.Title, &s.Description, &s.SurveyType,
		&s.IsAnonymous, &s.IsWeighted, &s.AllowComments, &s.ShowResults,
		&s.StartsAt, &s.EndsAt, &s.Status, &s.EligibleVoters, &s.TotalVotes,
		&s.CreatedByName, &s.CreatedAt, &s.HasVoted)
	if err != nil {
		return nil, err
	}
	s.Participation = participation(s.TotalVotes, s.EligibleVoters)
	return &s, nil
}

func participation(votes, eligible int) string {
	if eligible <= 0 {
		return "0.00"
	}
	return decimal.NewFromInt(int64(votes)).
		Mul(decimal.NewFromInt(100)).
		Div(decimal.NewFromInt(int64(eligible))).
		StringFixed(2)
}

// List, anketleri getirir. includeDrafts yalnızca yönetim için true olmalıdır.
func (r *Repository) List(ctx context.Context, propertyID, userID, status string, includeDrafts bool) ([]Survey, error) {
	rows, err := r.scope(propertyID).Query(ctx, surveySelect+`
		WHERE s.property_id = $1
		  AND ($3 = '' OR s.status = $3)
		  AND ($4 OR s.status <> 'DRAFT')
		ORDER BY s.starts_at DESC
		LIMIT 201`, propertyID, userID, strings.ToUpper(status), includeDrafts)
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

// Get, tek anketi seçenekleriyle birlikte getirir.
// withResults false ise sayımlar doldurulmaz (sonuçlar henüz açık değil).
func (r *Repository) Get(ctx context.Context, propertyID, id, userID string, withResults bool) (*Survey, error) {
	s, err := scanSurvey(r.scope(propertyID).QueryRow(ctx,
		surveySelect+` WHERE s.property_id = $1 AND s.id = $3`, propertyID, userID, id))
	if err == pgx.ErrNoRows {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}

	opts, err := r.options(ctx, propertyID, id, withResults, s.IsWeighted)
	if err != nil {
		return nil, err
	}
	s.Options = opts
	return s, nil
}

// options, seçenekleri ve (istenirse) OYLARDAN HESAPLANAN sayımları döner.
func (r *Repository) options(ctx context.Context, propertyID, surveyID string, withResults, weighted bool) ([]Option, error) {
	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT o.id, o.option_text, COALESCE(o.description,''), COALESCE(o.display_order,0),
		       (SELECT count(*) FROM survey_votes v WHERE v.option_id = o.id),
		       COALESCE((SELECT sum(v.weight) FROM survey_votes v WHERE v.option_id = o.id),0)::text
		FROM survey_options o
		WHERE o.survey_id = $1
		ORDER BY o.display_order, o.created_at`, surveyID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	type raw struct {
		o      Option
		count  int
		weight decimal.Decimal
	}
	items := []raw{}
	totalCount := 0
	totalWeight := decimal.Zero

	for rows.Next() {
		var o Option
		var count int
		var weightStr string
		if err := rows.Scan(&o.ID, &o.Text, &o.Description, &o.Order, &count, &weightStr); err != nil {
			return nil, err
		}
		w, err := decimal.NewFromString(weightStr)
		if err != nil {
			w = decimal.Zero
		}
		items = append(items, raw{o: o, count: count, weight: w})
		totalCount += count
		totalWeight = totalWeight.Add(w)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]Option, 0, len(items))
	for _, it := range items {
		o := it.o
		if withResults {
			cnt := it.count
			o.VoteCount = &cnt
			if weighted {
				ws := it.weight.StringFixed(4)
				o.WeightedShare = &ws
				o.Percentage = pct(it.weight, totalWeight)
			} else {
				o.Percentage = pct(decimal.NewFromInt(int64(it.count)), decimal.NewFromInt(int64(totalCount)))
			}
		}
		out = append(out, o)
	}
	return out, nil
}

func pct(part, total decimal.Decimal) *string {
	if total.LessThanOrEqual(decimal.Zero) {
		z := "0.00"
		return &z
	}
	s := part.Mul(decimal.NewFromInt(100)).Div(total).StringFixed(2)
	return &s
}

// CreateInput, yeni anket girdisidir.
type CreateInput struct {
	Title         string   `json:"title" binding:"required"`
	Description   string   `json:"description"`
	SurveyType    string   `json:"survey_type"`
	Options       []string `json:"options" binding:"required"`
	IsAnonymous   *bool    `json:"is_anonymous"`
	IsWeighted    bool     `json:"is_weighted"`
	AllowComments *bool    `json:"allow_comments"`
	ShowResults   bool     `json:"show_results_before_end"`
	StartsAt      string   `json:"starts_at"`
	EndsAt        string   `json:"ends_at"`
}

// Create, anketi TASLAK olarak oluşturur ve uygun seçmen sayısını hesaplar.
//
// Uygun seçmen sayısı oluşturulurken dondurulur: oylama sürerken siteye yeni
// biri taşınırsa katılım oranı geriye dönük değişir ve sonuç tartışmalı hâle gelir.
func (r *Repository) Create(ctx context.Context, propertyID, userID string, in CreateInput) (string, error) {
	sType := strings.ToUpper(strings.TrimSpace(in.SurveyType))
	if sType == "" {
		sType = "POLL"
	}
	if sType == "GENERAL_ASSEMBLY" {
		return "", ErrGeneralAssembly
	}
	if !contains(Types, sType) {
		return "", ErrInvalidType
	}

	clean := make([]string, 0, len(in.Options))
	for _, o := range in.Options {
		if t := strings.TrimSpace(o); t != "" {
			clean = append(clean, t)
		}
	}
	if len(clean) < 2 {
		return "", ErrNeedsTwoOptions
	}

	starts := time.Now()
	if in.StartsAt != "" {
		t, err := time.Parse(time.RFC3339, in.StartsAt)
		if err != nil {
			return "", ErrInvalidDate
		}
		starts = t
	}
	var ends *time.Time
	if in.EndsAt != "" {
		t, err := time.Parse(time.RFC3339, in.EndsAt)
		if err != nil {
			return "", ErrInvalidDate
		}
		if !t.After(starts) {
			return "", ErrInvalidDate
		}
		ends = &t
	}

	anonymous := true
	if in.IsAnonymous != nil {
		anonymous = *in.IsAnonymous
	}
	comments := true
	if in.AllowComments != nil {
		comments = *in.AllowComments
	}

	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return "", err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	eligible, err := countEligible(ctx, tx, propertyID, sType)
	if err != nil {
		return "", err
	}

	var id string
	if err := tx.QueryRow(ctx, `
		INSERT INTO surveys
			(property_id, title, description, survey_type, is_anonymous, is_weighted,
			 allow_comments, show_results_before_end, starts_at, ends_at,
			 status, total_eligible_voters, created_by)
		VALUES ($1,$2,NULLIF($3,''),$4,$5,$6,$7,$8,$9,$10,'DRAFT',$11,$12)
		RETURNING id`,
		propertyID, in.Title, in.Description, sType, anonymous, in.IsWeighted,
		comments, in.ShowResults, starts, ends, eligible, userID).Scan(&id); err != nil {
		return "", err
	}

	for i, text := range clean {
		if _, err := tx.Exec(ctx, `
			INSERT INTO survey_options (survey_id, option_text, display_order)
			VALUES ($1,$2,$3)`, id, text, i); err != nil {
			return "", err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return "", err
	}
	return id, nil
}

// countEligible, oy hakkı olanların sayısını verir.
//
//	VOTE  → yalnızca KAT MALİKLERİ (bağımsız bölüm başına bir oy — KMK m.31/1)
//	diğer → sitede oturan herkes (görüş yoklaması)
func countEligible(ctx context.Context, q pgx.Tx, propertyID, sType string) (int, error) {
	var n int
	if sType == "VOTE" {
		// KMK m.31/1: her kat maliki arsa payına bakılmaksızın BİR oy hakkına
		// sahiptir. Bu yüzden sayım bağımsız bölüm başına yapılır, kişi başına değil.
		err := q.QueryRow(ctx, `
			SELECT count(DISTINCT ru.unit_id)
			FROM resident_units ru
			JOIN units u ON u.id = ru.unit_id
			WHERE u.property_id = $1 AND ru.is_active = true AND ru.role = 'OWNER'`,
			propertyID).Scan(&n)
		return n, err
	}
	err := q.QueryRow(ctx, `
		SELECT count(DISTINCT ru.resident_id)
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE u.property_id = $1 AND ru.is_active = true`, propertyID).Scan(&n)
	return n, err
}

// Publish, taslağı yayına alır.
func (r *Repository) Publish(ctx context.Context, propertyID, id string) (*PublishedSurvey, error) {
	// Önce anket var mı: önceden seçenek sayısı önce sayılıyor, var olmayan
	// anket için "en az iki seçenek gerekir" (422) dönüyordu.
	if ok, err := r.scope(propertyID).Exists(ctx, "surveys", id); err != nil {
		return nil, err
	} else if !ok {
		return nil, ErrNotFound
	}
	var optionCount int
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT count(*) FROM survey_options WHERE survey_id = $1`, id).Scan(&optionCount); err != nil {
		return nil, err
	}
	if optionCount < 2 {
		return nil, ErrNeedsTwoOptions
	}
	// Yayına alırken bildirim için gereken bilgiyi AYNI sorguda alıyoruz;
	// ikinci bir SELECT, aradaki sürede anket kapatılırsa artık geçerli
	// olmayan bir duruma göre bildirim üretirdi.
	var out PublishedSurvey
	err := r.scope(propertyID).QueryRow(ctx, `
		UPDATE surveys SET status = 'ACTIVE', updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'DRAFT'
		RETURNING title, survey_type, ends_at`, id, propertyID).Scan(
		&out.Title, &out.Type, &out.EndsAt)
	if err == pgx.ErrNoRows {
		return nil, r.stateOrNotFound(ctx, propertyID, "surveys", id, ErrNotFound, ErrBadState)
	}
	if err != nil {
		return nil, err
	}
	return &out, nil
}

// PublishedSurvey, yayına alınan anketin bildirimde kullanılan bilgisidir.
type PublishedSurvey struct {
	Title  string
	Type   string
	EndsAt *time.Time
}

// Close, oylamayı sonlandırır.
func (r *Repository) Close(ctx context.Context, propertyID, id string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE surveys SET status = 'ENDED', ends_at = COALESCE(ends_at, now()), updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status = 'ACTIVE'`, id, propertyID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "surveys", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// Cancel, oylamayı iptal eder. Oylar silinmez.
func (r *Repository) Cancel(ctx context.Context, propertyID, id, reason string) error {
	tag, err := r.scope(propertyID).Exec(ctx, `
		UPDATE surveys
		SET status = 'CANCELLED',
		    description = COALESCE(description || E'\n', '') || 'İPTAL: ' || $3,
		    updated_at = now()
		WHERE id = $1 AND property_id = $2 AND status IN ('DRAFT','ACTIVE')`,
		id, propertyID, reason)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return r.stateOrNotFound(ctx, propertyID, "surveys", id, ErrNotFound, ErrBadState)
	}
	return nil
}

// VoteResult, oy kaydının sonucudur.
type VoteResult struct {
	Weight   string `json:"weight"`
	UnitName string `json:"unit_name,omitempty"`
}

// Vote, oyu kaydeder.
//
// Yapılan denetimler (hepsi sunucuda, istemciye güvenilmez):
//   - anket yayında mı, başladı mı, bitti mi
//   - seçenek gerçekten bu ankete ait mi
//   - oy veren uygun mu (VOTE türünde yalnızca kat maliki)
//   - daha önce oy vermiş mi (veritabanı UNIQUE kısıtı son savunma hattıdır)
//
// Ağırlık: ağırlıklı oylamada ARSA PAYI kullanılır, metrekare değil. KMK'da
// paylaşım ölçüsü arsa payıdır (m.20); metrekareyle ağırlıklandırma hukuki
// dayanaktan yoksundur. Ağırlıksız oylamada ağırlık 1'dir (KMK m.31/1).
func (r *Repository) Vote(ctx context.Context, propertyID, surveyID, optionID, userID, comment string) (*VoteResult, error) {
	tx, err := r.scope(propertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck

	var status, sType string
	var weighted, allowComments bool
	var starts time.Time
	var ends *time.Time
	if err := tx.QueryRow(ctx, `
		SELECT status, survey_type, COALESCE(is_weighted,false), COALESCE(allow_comments,true),
		       starts_at, ends_at
		FROM surveys WHERE id = $1 AND property_id = $2`, surveyID, propertyID).
		Scan(&status, &sType, &weighted, &allowComments, &starts, &ends); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}

	if status != "ACTIVE" {
		return nil, ErrBadState
	}
	now := time.Now()
	if now.Before(starts) {
		return nil, ErrNotStarted
	}
	if ends != nil && now.After(*ends) {
		return nil, ErrEnded
	}

	var optionOK bool
	if err := tx.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM survey_options WHERE id = $1 AND survey_id = $2)`,
		optionID, surveyID).Scan(&optionOK); err != nil {
		return nil, err
	}
	if !optionOK {
		return nil, ErrInvalidOption
	}

	// Oy hakkı ve ağırlık: kullanıcının bu sitedeki bağımsız bölümü üzerinden.
	var unitID, unitName, shareRatio string
	var role string
	err = tx.QueryRow(ctx, `
		SELECT ru.unit_id::text,
		       COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
		       u.share_ratio::text, ru.role
		FROM resident_units ru
		JOIN units u ON u.id = ru.unit_id
		WHERE ru.resident_id = $1 AND ru.is_active = true AND u.property_id = $2
		ORDER BY (ru.role = 'OWNER') DESC
		LIMIT 1`, userID, propertyID).Scan(&unitID, &unitName, &shareRatio, &role)
	if err == pgx.ErrNoRows {
		return nil, ErrNotEligible
	}
	if err != nil {
		return nil, err
	}
	if sType == "VOTE" && role != "OWNER" {
		// Kararlara yalnızca kat malikleri oy verir (KMK m.31/1).
		return nil, ErrNotEligible
	}

	weight := decimal.NewFromInt(1)
	if weighted {
		w, err := decimal.NewFromString(shareRatio)
		if err != nil {
			return nil, err
		}
		weight = w
	}

	if !allowComments {
		comment = ""
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO survey_votes (survey_id, option_id, voter_id, unit_id, weight, comment)
		VALUES ($1,$2,$3,NULLIF($4,'')::uuid,$5,NULLIF($6,''))`,
		surveyID, optionID, userID, unitID, weight.String(), strings.TrimSpace(comment)); err != nil {
		if strings.Contains(err.Error(), "survey_votes_survey_id_voter_id_key") ||
			strings.Contains(err.Error(), "duplicate key") {
			return nil, ErrAlreadyVoted
		}
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &VoteResult{Weight: weight.String(), UnitName: unitName}, nil
}

// Comments, ankete bırakılan yorumları döner.
// Anonim ankette isim DÖNDÜRÜLMEZ.
func (r *Repository) Comments(ctx context.Context, propertyID, surveyID string) ([]Comment, error) {
	var anonymous bool
	if err := r.scope(propertyID).QueryRow(ctx,
		`SELECT COALESCE(is_anonymous,true) FROM surveys WHERE id = $1 AND property_id = $2`,
		surveyID, propertyID).Scan(&anonymous); err != nil {
		if err == pgx.ErrNoRows {
			return nil, ErrNotFound
		}
		return nil, err
	}

	rows, err := r.scope(propertyID).Query(ctx, `
		SELECT CASE WHEN $3 THEN '' ELSE COALESCE(u.first_name || ' ' || u.last_name,'') END,
		       v.comment, v.voted_at
		FROM survey_votes v
		LEFT JOIN users u ON u.id = v.voter_id
		WHERE v.survey_id = $1 AND v.comment IS NOT NULL AND v.comment <> ''
		  AND EXISTS(SELECT 1 FROM surveys s WHERE s.id = v.survey_id AND s.property_id = $2)
		ORDER BY v.voted_at DESC
		LIMIT 201`, surveyID, propertyID, anonymous)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	out := []Comment{}
	for rows.Next() {
		var c Comment
		if err := rows.Scan(&c.VoterName, &c.Comment, &c.VotedAt); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

func contains(list []string, v string) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}

// scope, veritabanı erişimini SİTE KAPSAMINA bağlar (FAZ 2.6).
//
// surveys, survey_options, survey_votes tablolarında RLS açıktır (migration 021).
//
// Kapsam, PostgreSQL satır düzeyi güvenliği tarafından okunur: sorguda
// `WHERE property_id` filtresi unutulsa bile başka sitenin satırları DÖNMEZ.
// Bu, uygulama katmanındaki filtrenin yerine geçmez — onu YEDEKLER.
func (r *Repository) scope(propertyID string) *dbscope.Scoped {
	return dbscope.For(r.pool, propertyID)
}

// stateOrNotFound, durum geçişli bir güncelleme 0 satır etkilediğinde iki
// ihtimali ayırır: kayıt hiç yoksa (ya da başka siteye aitse) notFound (404),
// varsa ama durumu uygun değilse state (409). Önceden ikisi de 409 dönüyordu;
// istemci var olmayan kaydı "başkası işlem yapmış" sanıyordu.
func (r *Repository) stateOrNotFound(ctx context.Context, propertyID, table, id string, notFound, state error) error {
	ok, err := r.scope(propertyID).Exists(ctx, table, id)
	if err != nil {
		return err
	}
	if !ok {
		return notFound
	}
	return state
}
