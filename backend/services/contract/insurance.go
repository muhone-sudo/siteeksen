package main

// Sigorta: bağımsız bölüm DASK takibi ve ortak alan hasar kaydı (FAZ 7.2, migration 045).
// DASK yükümlülüğü MALİKİNDİR (6305 m.10/3); yönetim izler, zamanlayıcı malike hatırlatır.

import (
	"errors"
	"log"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

type daskRow struct {
	UnitID    string     `json:"unit_id"`
	Unit      string     `json:"unit"`
	PolicyNo  string     `json:"policy_no,omitempty"`
	Insurer   string     `json:"insurer,omitempty"`
	StartDate *time.Time `json:"start_date,omitempty"`
	EndDate   *time.Time `json:"end_date,omitempty"`
	State     string     `json:"state"` // VALID | EXPIRING | EXPIRED | MISSING
	DaysLeft  *int       `json:"days_left,omitempty"`
}

func isManagementRole(c *gin.Context) bool {
	v, _ := c.Get("roles")
	roles, _ := v.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager || r == middleware.RoleBoardMember || r == middleware.RoleAuditor {
			return true
		}
	}
	return false
}

func failInsurance(c *gin.Context, err error, op string) {
	var pg *pgconn.PgError
	if errors.As(err, &pg) && pg.Code == "23505" {
		c.JSON(http.StatusConflict, gin.H{"error": "Bu poliçe zaten kayıtlı"})
		return
	}
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[contract] sigorta %s: %v", op, err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}

// listDASK: yönetime bütün bölümlerin son DASK poliçesi ve durumu; sakine yalnızca
// malik/vekil olduğu bölümler.
func listDASK(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		user := c.GetString("user_id")
		if isManagementRole(c) {
			user = ""
		}
		propertyID := c.GetString("property_id")
		rows, err := dbscope.For(pool, propertyID).Query(c.Request.Context(), `
			SELECT u.id::text, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
			       p.policy_no, p.insurer, p.start_date, p.end_date, (p.end_date - CURRENT_DATE)::int
			FROM units u
			LEFT JOIN LATERAL (SELECT policy_no, COALESCE(insurer,'') AS insurer, start_date, end_date
			                   FROM unit_insurance_policies x WHERE x.unit_id = u.id AND x.kind = 'DASK'
			                   ORDER BY end_date DESC LIMIT 1) p ON true
			WHERE u.property_id = $1 AND u.deleted = 0
			  AND ($2 = '' OR EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = u.id AND ru.resident_id::text = $2
			        AND ru.role IN ('OWNER','PROXY') AND COALESCE(ru.is_active, true)))
			ORDER BY u.block, u.door_number`, propertyID, user)
		if err != nil {
			failInsurance(c, err, "DASK listesi")
			return
		}
		defer rows.Close()
		out := []daskRow{}
		counts := map[string]int{}
		for rows.Next() {
			var r daskRow
			var policy, insurer *string
			if err := rows.Scan(&r.UnitID, &r.Unit, &policy, &insurer, &r.StartDate, &r.EndDate, &r.DaysLeft); err != nil {
				failInsurance(c, err, "DASK listesi")
				return
			}
			if policy != nil {
				r.PolicyNo = *policy
			}
			if insurer != nil {
				r.Insurer = *insurer
			}
			switch {
			case r.EndDate == nil:
				r.State = "MISSING"
			case *r.DaysLeft < 0:
				r.State = "EXPIRED"
			case *r.DaysLeft <= 30:
				r.State = "EXPIRING"
			default:
				r.State = "VALID"
			}
			counts[r.State]++
			out = append(out, r)
		}
		if err := rows.Err(); err != nil {
			failInsurance(c, err, "DASK listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "summary": counts,
			"note": "Zorunlu deprem sigortasını malik ya da intifa hakkı sahibi yaptırır ve her yıl yeniler (6305 s. Kanun m.10/3). " +
				"Taşıyıcı sistemi olumsuz etkileyen izinsiz tadilatta tazminat hakkı kaybedilir (m.12/2)."})
	}
}

// addDASK: malik/vekil kendi bölümü için, yönetim her bölüm için poliçe kaydeder.
func addDASK(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			UnitID    string `json:"unit_id"`
			Kind      string `json:"kind"`
			PolicyNo  string `json:"policy_no"`
			Insurer   string `json:"insurer"`
			StartDate string `json:"start_date"`
			EndDate   string `json:"end_date"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Kind = strings.ToUpper(strings.TrimSpace(in.Kind))
		if in.Kind == "" {
			in.Kind = "DASK"
		}
		in.PolicyNo = strings.TrimSpace(in.PolicyNo)
		start, e1 := time.ParseInLocation("2006-01-02", in.StartDate, time.Local)
		end, e2 := time.ParseInLocation("2006-01-02", in.EndDate, time.Local)
		if !slices.Contains([]string{"DASK", "HOME"}, in.Kind) || in.PolicyNo == "" || e1 != nil || e2 != nil || !end.After(start) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tür (DASK/HOME), poliçe no ve geçerli başlangıç/bitiş tarihi zorunludur"})
			return
		}
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		scope := dbscope.For(pool, propertyID)
		var allowed bool
		q := `SELECT EXISTS (SELECT 1 FROM units u WHERE u.id = $1::uuid AND u.property_id = $2 AND u.deleted = 0
		        AND ($3 OR EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = u.id AND ru.resident_id = $4::uuid
		             AND ru.role IN ('OWNER','PROXY') AND COALESCE(ru.is_active, true))))`
		mgmt := false
		v, _ := c.Get("roles")
		roles, _ := v.([]string)
		for _, r := range roles {
			if r == middleware.RoleManager || r == middleware.RoleBoardMember {
				mgmt = true
			}
		}
		if err := scope.QueryRow(ctx, q, in.UnitID, propertyID, mgmt, userID).Scan(&allowed); err != nil {
			var pg *pgconn.PgError
			if !(errors.As(err, &pg) && pg.Code == "22P02") {
				failInsurance(c, err, "poliçe yetkisi")
				return
			}
		}
		if !allowed {
			c.JSON(http.StatusForbidden, gin.H{"error": "Poliçeyi bölümün maliki/vekili ya da yönetim kaydedebilir"})
			return
		}
		if _, err := scope.Exec(ctx, `
			INSERT INTO unit_insurance_policies (property_id, unit_id, kind, policy_no, insurer, start_date, end_date, recorded_by)
			VALUES ($1, $2, $3, $4, NULLIF($5,''), $6, $7, NULLIF($8,'')::uuid)`,
			propertyID, in.UnitID, in.Kind, in.PolicyNo, strings.TrimSpace(in.Insurer), start, end, userID); err != nil {
			failInsurance(c, err, "poliçe kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Poliçe kaydedildi"})
	}
}

type claim struct {
	ID            string     `json:"id"`
	ContractID    string     `json:"contract_id,omitempty"`
	OccurredOn    time.Time  `json:"occurred_on"`
	Description   string     `json:"description"`
	ClaimedAmount *float64   `json:"claimed_amount,omitempty"`
	Status        string     `json:"status"`
	InsurerRef    string     `json:"insurer_ref,omitempty"`
	PaidAmount    *float64   `json:"paid_amount,omitempty"`
	PaidOn        *time.Time `json:"paid_on,omitempty"`
	Note          string     `json:"note,omitempty"`
	CreatedAt     time.Time  `json:"created_at"`
}

func listClaims(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, err := dbscope.For(pool, c.GetString("property_id")).Query(c.Request.Context(), `
			SELECT id::text, COALESCE(contract_id::text,''), occurred_on, description, claimed_amount::float8, status,
			       COALESCE(insurer_ref,''), paid_amount::float8, paid_on, COALESCE(note,''), created_at
			FROM insurance_claims WHERE property_id = $1 ORDER BY (status IN ('REPORTED','EXPERT_ASSIGNED')) DESC, occurred_on DESC`,
			c.GetString("property_id"))
		if err != nil {
			failInsurance(c, err, "hasar listesi")
			return
		}
		defer rows.Close()
		out := []claim{}
		for rows.Next() {
			var x claim
			if err := rows.Scan(&x.ID, &x.ContractID, &x.OccurredOn, &x.Description, &x.ClaimedAmount, &x.Status,
				&x.InsurerRef, &x.PaidAmount, &x.PaidOn, &x.Note, &x.CreatedAt); err != nil {
				failInsurance(c, err, "hasar listesi")
				return
			}
			out = append(out, x)
		}
		c.JSON(http.StatusOK, gin.H{"data": out})
	}
}

func createClaim(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			ContractID    string   `json:"contract_id"`
			OccurredOn    string   `json:"occurred_on"`
			Description   string   `json:"description"`
			ClaimedAmount *float64 `json:"claimed_amount"`
			InsurerRef    string   `json:"insurer_ref"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		occ, err := time.ParseInLocation("2006-01-02", in.OccurredOn, time.Local)
		if err != nil || occ.After(time.Now()) || len([]rune(strings.TrimSpace(in.Description))) < 10 ||
			(in.ClaimedAmount != nil && *in.ClaimedAmount < 0) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Geçmiş/bugün tarihli olay tarihi ve en az 10 karakterlik açıklama zorunludur"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		scope := dbscope.For(pool, propertyID)
		if in.ContractID != "" {
			var ok bool
			if err := scope.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM contracts WHERE id = $1::uuid AND property_id = $2 AND contract_type = 'INSURANCE')`,
				in.ContractID, propertyID).Scan(&ok); err != nil || !ok {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Poliçe bu sitenin sigorta sözleşmeleri arasında bulunamadı"})
				return
			}
		}
		var id string
		if err := scope.QueryRow(ctx, `
			INSERT INTO insurance_claims (property_id, contract_id, occurred_on, description, claimed_amount, insurer_ref, created_by)
			VALUES ($1, NULLIF($2,'')::uuid, $3, $4, $5, NULLIF($6,''), NULLIF($7,'')::uuid) RETURNING id::text`,
			propertyID, in.ContractID, occ, strings.TrimSpace(in.Description), in.ClaimedAmount, strings.TrimSpace(in.InsurerRef),
			c.GetString("user_id")).Scan(&id); err != nil {
			failInsurance(c, err, "hasar kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id})
	}
}

// claimTransitions: izin verilen durum geçişleri (geri dönüş yok).
var claimTransitions = map[string][]string{
	"REPORTED":        {"EXPERT_ASSIGNED", "PAID", "REJECTED"},
	"EXPERT_ASSIGNED": {"PAID", "REJECTED"},
	"PAID":            {"CLOSED"},
	"REJECTED":        {"CLOSED"},
}

func updateClaim(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Status     string   `json:"status"`
			PaidAmount *float64 `json:"paid_amount"`
			PaidOn     string   `json:"paid_on"`
			Note       string   `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Status = strings.ToUpper(strings.TrimSpace(in.Status))
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		scope := dbscope.For(pool, propertyID)
		var cur string
		err := scope.QueryRow(ctx, `SELECT status FROM insurance_claims WHERE id = $1 AND property_id = $2`, c.Param("id"), propertyID).Scan(&cur)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Hasar kaydı bulunamadı"})
			return
		}
		if err != nil {
			failInsurance(c, err, "hasar güncelleme")
			return
		}
		if !slices.Contains(claimTransitions[cur], in.Status) {
			c.JSON(http.StatusConflict, gin.H{"error": "Bu durum geçişi yapılamaz", "from": cur, "allowed": claimTransitions[cur]})
			return
		}
		var paidOn *time.Time
		if in.Status == "PAID" {
			t, err := time.ParseInLocation("2006-01-02", in.PaidOn, time.Local)
			if err != nil || in.PaidAmount == nil || *in.PaidAmount < 0 {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ödenen tazminat tutarı ve ödeme tarihi zorunludur"})
				return
			}
			paidOn = &t
		}
		if in.Status == "REJECTED" && strings.TrimSpace(in.Note) == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ret gerekçesi (sigortacının açıklaması) zorunludur"})
			return
		}
		tag, err := scope.Exec(ctx, `
			UPDATE insurance_claims SET status = $3, paid_amount = COALESCE($4, paid_amount), paid_on = COALESCE($5, paid_on),
			       note = COALESCE(NULLIF($6,''), note), updated_at = now()
			WHERE id = $1 AND property_id = $2 AND status = $7`,
			c.Param("id"), propertyID, in.Status, in.PaidAmount, paidOn, strings.TrimSpace(in.Note), cur)
		if err != nil {
			failInsurance(c, err, "hasar güncelleme")
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Kayıt bu arada değişti; yeniden deneyin"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Hasar kaydı güncellendi"})
	}
}
