package store

// Vitrin (FAZ M8.1, K7/K17): sakinin sitesini hizmet alanı kapsayan, onaylı hesapların yayındaki işletmeleri; hizmet
// kalemleri, fiyat aralıkları, puan. Telefon yalnız paketi izin veriyorsa (görünüm karar verir); vergi no, bakiye yok.

import (
	"context"
	"errors"
	"sort"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/siteeksen/backend/services/marketplace/rules"
)

// ShowcaseBusiness, vitrindeki işletmedir.
type ShowcaseBusiness struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	Description   string   `json:"description"`
	City          string   `json:"city"`
	District      string   `json:"district"`
	DistanceM     *int     `json:"distance_m"`
	ServiceArea   string   `json:"service_area"`
	Phone         *string  `json:"phone"`
	Featured      bool     `json:"featured"`
	RatingAvg     *float64 `json:"rating_avg"`
	RatingCount   int      `json:"rating_count"`
	CompletedJobs int      `json:"completed_jobs"`
	CategoryIDs   []string `json:"category_ids"`
	ServiceCount  int      `json:"service_count"`
	MinPriceKurus *int64   `json:"min_price_kurus"`
	rank          int
}

// PublicService, vitrindeki hizmet/ürün kalemidir.
type PublicService struct {
	ID            string  `json:"id"`
	Name          string  `json:"name"`
	Description   string  `json:"description"`
	PriceMinKurus *int64  `json:"price_min_kurus"`
	PriceMaxKurus *int64  `json:"price_max_kurus"`
	Unit          *string `json:"unit"`
	HasPhoto      bool    `json:"has_photo"`
}

// PublicReview, vitrindeki yorumdur (gizlenenler yok).
type PublicReview struct {
	Rating    int        `json:"rating"`
	Comment   string     `json:"comment"`
	Reply     *string    `json:"reply"`
	RepliedAt *time.Time `json:"replied_at"`
	CreatedAt time.Time  `json:"created_at"`
}

// ShowcaseDetail, işletme sayfasıdır.
type ShowcaseDetail struct {
	ShowcaseBusiness
	Services []PublicService `json:"services"`
	Reviews  []PublicReview  `json:"reviews"`
}

const showcaseSelect = `SELECT p.id, p.name, p.description, p.city, p.district, p.latitude::float8, p.longitude::float8,
	p.service_area, COALESCE(p.radius_km, 0), p.phone, p.paid_package, p.rank_weight, p.rating_avg::float8, p.rating_count,
	p.completed_jobs, p.category_ids::text[],
	(SELECT count(*) FROM mp_business_services_public s WHERE s.business_id = p.id),
	(SELECT min(s.price_min_kurus) FROM mp_business_services_public s WHERE s.business_id = p.id)
	FROM mp_business_public p`

func scanShowcase(r pgx.Row) (*ShowcaseBusiness, rules.Area, error) {
	x := &ShowcaseBusiness{}
	a := rules.Area{}
	err := r.Scan(&x.ID, &x.Name, &x.Description, &x.City, &x.District, &a.Lat, &a.Lng, &x.ServiceArea, &a.RadiusKm, &x.Phone,
		&x.Featured, &x.rank, &x.RatingAvg, &x.RatingCount, &x.CompletedJobs, &x.CategoryIDs, &x.ServiceCount, &x.MinPriceKurus)
	a.Kind, a.City, a.District = x.ServiceArea, x.City, x.District
	return x, a, err
}

func siteOf(ctx context.Context, tx pgx.Tx, propertyID string) (rules.Site, error) {
	var s rules.Site
	err := tx.QueryRow(ctx, `SELECT COALESCE(city, ''), COALESCE(district, ''), latitude::float8, longitude::float8
		FROM properties WHERE id = $1`, propertyID).Scan(&s.City, &s.District, &s.Lat, &s.Lng)
	return s, err
}

// Showcase, sitenin vitrinidir: hizmet alanı siteyi kapsayan işletmeler; sıralama paket ağırlığı, uzaklık, puan.
func (s *Store) Showcase(ctx context.Context, b Buyer, categoryID string) ([]ShowcaseBusiness, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	site, err := siteOf(ctx, tx, b.PropertyID)
	if err != nil {
		return nil, err
	}
	rows, err := tx.Query(ctx, showcaseSelect+` WHERE ($1 = '' OR $1 = ANY(p.category_ids::text[])) LIMIT 500`, categoryID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []ShowcaseBusiness{}
	for rows.Next() {
		x, area, err := scanShowcase(rows)
		if err != nil {
			return nil, err
		}
		if ok, dist := rules.Covers(area, site); ok {
			x.DistanceM = dist
			out = append(out, *x)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	sort.SliceStable(out, func(i, j int) bool {
		a, c := out[i], out[j]
		if a.rank != c.rank {
			return a.rank > c.rank
		}
		if (a.DistanceM == nil) != (c.DistanceM == nil) {
			return a.DistanceM != nil
		}
		if a.DistanceM != nil && *a.DistanceM != *c.DistanceM {
			return *a.DistanceM < *c.DistanceM
		}
		ra, rc := 0.0, 0.0
		if a.RatingAvg != nil {
			ra = *a.RatingAvg
		}
		if c.RatingAvg != nil {
			rc = *c.RatingAvg
		}
		return ra > rc
	})
	return out, nil
}

// ShowcaseBusinessByID, vitrindeki işletmenin sayfasıdır (hizmetleri ve görünür yorumlarıyla).
func (s *Store) ShowcaseBusinessByID(ctx context.Context, b Buyer, id string) (*ShowcaseDetail, error) {
	tx, err := s.site(b.PropertyID).Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx) //nolint:errcheck
	site, err := siteOf(ctx, tx, b.PropertyID)
	if err != nil {
		return nil, err
	}
	x, area, err := scanShowcase(tx.QueryRow(ctx, showcaseSelect+` WHERE p.id = $1`, id))
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	_, x.DistanceM = rules.Covers(area, site)
	d := &ShowcaseDetail{ShowcaseBusiness: *x, Services: []PublicService{}, Reviews: []PublicReview{}}
	rows, err := tx.Query(ctx, `SELECT id, name, description, price_min_kurus, price_max_kurus, unit, photo_key IS NOT NULL
		FROM mp_business_services_public WHERE business_id = $1 ORDER BY sort_order, name`, id)
	if err != nil {
		return nil, err
	}
	for rows.Next() {
		v := PublicService{}
		if err := rows.Scan(&v.ID, &v.Name, &v.Description, &v.PriceMinKurus, &v.PriceMaxKurus, &v.Unit, &v.HasPhoto); err != nil {
			rows.Close()
			return nil, err
		}
		d.Services = append(d.Services, v)
	}
	rows.Close()
	rows, err = tx.Query(ctx, `SELECT rating, comment, reply, replied_at, created_at FROM mp_reviews_public
		WHERE business_id = $1 ORDER BY created_at DESC LIMIT 50`, id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		v := PublicReview{}
		if err := rows.Scan(&v.Rating, &v.Comment, &v.Reply, &v.RepliedAt, &v.CreatedAt); err != nil {
			return nil, err
		}
		d.Reviews = append(d.Reviews, v)
	}
	return d, rows.Err()
}
