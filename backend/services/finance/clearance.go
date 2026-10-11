package main

// Borcu yoktur belgesi (migration 055, Apsiyon BUG-04).
//
// Belge yalnızca VADESİ GEÇMİŞ (muaccel) borç sıfırken üretilir; son ödeme günü gelmemiş
// cari tahakkuk borç sayılmaz ama belgede ayrıca yazılır. Onay bekleyen ödeme bildirimi
// varsa belge, ödeme onaylanınca alınır (beyan ödeme yerine geçmez). Belge değiştirilemez
// ve SHA-256 doğrulama koduyla kimliksiz doğrulanır (kişisel veri dönmez).

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/reports"
)

// clearanceValidDays: belgenin geçerlilik süresi (bankalar genellikle güncel tarihli belge ister).
const clearanceValidDays = 30

func verifyBaseURL() string {
	if v := strings.TrimRight(os.Getenv("PUBLIC_VERIFY_BASE_URL"), "/"); v != "" {
		return v
	}
	return "https://app.siteeksen.com/dogrula"
}

func isFinanceManager(c *gin.Context) bool {
	v, _ := c.Get("roles")
	roles, _ := v.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager || r == middleware.RoleBoardMember || r == middleware.RoleAuditor {
			return true
		}
	}
	return false
}

// canRequestFor: yönetim ya da bölümün aktif sakini (malik, kiracı, vekil).
func canRequestFor(c *gin.Context, pool *pgxpool.Pool, propertyID, unitID string) (bool, error) {
	if isFinanceManager(c) {
		return true, nil
	}
	var ok bool
	err := dbscope.For(pool, propertyID).QueryRow(c.Request.Context(), `
		SELECT EXISTS (SELECT 1 FROM resident_units ru JOIN units u ON u.id = ru.unit_id
		               WHERE ru.unit_id = $1 AND ru.resident_id = $2 AND ru.is_active AND ru.role <> 'HOUSEHOLD' AND u.property_id = $3)`,
		unitID, c.GetString("user_id"), propertyID).Scan(&ok)
	return ok, err
}

// clearanceScope (070, D5): yönetim ve malik/vekil bölümün BÜTÜN borcu için belge alır (UNIT); kiracı yalnız kendi
// kiracılığına bağlı kullanım borcu için (TENANCY) — malikin borcu kiracının belgesine engel değildir, kiracı da onu göremez.
func clearanceScope(c *gin.Context, pool *pgxpool.Pool, propertyID, unitID string) (scope, tenantLink string, ownerView bool, err error) {
	if isFinanceManager(c) {
		return "UNIT", "", false, nil
	}
	var owner bool
	var link *string
	err = dbscope.For(pool, propertyID).QueryRow(c.Request.Context(), `
		SELECT EXISTS (SELECT 1 FROM resident_units WHERE unit_id = $1 AND resident_id = $2 AND is_active AND role IN ('OWNER', 'PROXY')),
		       (SELECT id::text FROM resident_units WHERE unit_id = $1 AND resident_id = $2 AND is_active AND role = 'TENANT' LIMIT 1)`,
		unitID, c.GetString("user_id")).Scan(&owner, &link)
	if err != nil {
		return "", "", false, err
	}
	if owner {
		return "UNIT", "", true, nil
	}
	if link != nil {
		return "TENANCY", *link, false, nil
	}
	return "UNIT", "", false, nil
}

func clearanceFail(c *gin.Context, err error) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[finance] borcu yoktur belgesi: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}

// createClearance: POST /finance/clearance-certificates {unit_id}.
func createClearance(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			UnitID string `json:"unit_id"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || in.UnitID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "unit_id zorunludur"})
			return
		}
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		ok, err := canRequestFor(c, pool, propertyID, in.UnitID)
		if err != nil {
			clearanceFail(c, err)
			return
		}
		if !ok {
			c.JSON(http.StatusForbidden, gin.H{"error": "Belge yalnızca bölümün sakini ya da yönetim tarafından alınabilir"})
			return
		}
		scope, tenantLink, ownerView, err := clearanceScope(c, pool, propertyID, in.UnitID)
		if err != nil {
			clearanceFail(c, err)
			return
		}
		sc := dbscope.For(pool, propertyID)
		// Vadesi geçmiş kalemler (muaccel) ve vadesi gelmemiş toplam (müeccel). Kiracının belgesi yalnız kendi
		// kiracılığına bağlı borcu kapsar (070).
		rows, err := sc.Query(ctx, `
			SELECT CASE WHEN ma.kind = 'OPENING' THEN 'Devir bakiyesi'
			            ELSE to_char(make_date(ma.period_year, ma.period_month, 1), 'YYYY-MM') END,
			       ma.due_date, round((ma.total_amount - COALESCE(ma.paid_amount, 0)) * 100)::bigint,
			       EXISTS (SELECT 1 FROM payment_assessments pa JOIN payments p ON p.id = pa.payment_id
			               WHERE pa.assessment_id = ma.id AND p.status = 'PENDING'),
			       assessment_responsible(ma.id)
			FROM monthly_assessments ma JOIN units u ON u.id = ma.unit_id
			WHERE ma.unit_id = $1 AND u.property_id = $2 AND ma.deleted = 0
			  AND ma.total_amount > COALESCE(ma.paid_amount, 0)
			  AND ($3 = '' OR ma.tenant_link_id = NULLIF($3, '')::uuid)
			ORDER BY ma.due_date`, in.UnitID, propertyID, tenantLink)
		if err != nil {
			clearanceFail(c, err)
			return
		}
		today, _ := time.Parse("2006-01-02", time.Now().Format("2006-01-02"))
		type item struct {
			Period  string `json:"period"`
			DueDate string `json:"due_date"`
			Kurus   int64  `json:"remaining_kurus"`
			Pending bool   `json:"payment_pending_approval"`
			// Responsible: TENANT | OWNER. Malik, kiracı sorumluluğundaki borcun tutarını görmez (070; görünürlük D6).
			Responsible string `json:"responsible"`
		}
		overdue := []item{}
		var notDue int64
		for rows.Next() {
			var it item
			var due time.Time
			if err := rows.Scan(&it.Period, &due, &it.Kurus, &it.Pending, &it.Responsible); err != nil {
				rows.Close()
				clearanceFail(c, err)
				return
			}
			it.DueDate = due.Format("2006-01-02")
			if ownerView && it.Responsible == "TENANT" {
				it.Kurus, it.Period = 0, "Kiracı sorumluluğundaki borç"
			}
			if due.Before(today) {
				overdue = append(overdue, it)
			} else {
				notDue += it.Kurus
			}
		}
		rows.Close()
		if len(overdue) > 0 {
			var total int64
			pending := false
			for _, o := range overdue {
				total += o.Kurus
				pending = pending || o.Pending
			}
			msg := "Vadesi geçmiş borç bulunduğu için borcu yoktur belgesi üretilemez: " + money.Kurus(total).Display()
			for _, o := range overdue {
				if ownerView && o.Responsible == "TENANT" {
					msg += ". Kiracı sorumluluğunda vadesi geçmiş borç da var (tutarı kiracıya ve yönetime görünür)"
					break
				}
			}
			if pending {
				msg += ". Ödeme bildiriminiz yönetim onayı bekliyor; onaylandığında belge alınabilir."
			}
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": msg, "overdue": overdue, "overdue_kurus": total})
			return
		}
		b := make([]byte, 32)
		if _, err := rand.Read(b); err != nil {
			clearanceFail(c, err)
			return
		}
		sum := sha256.Sum256(append(b, []byte(in.UnitID+today.Format("2006-01-02"))...))
		code := hex.EncodeToString(sum[:])
		var id string
		if err := sc.QueryRow(ctx, `
			INSERT INTO clearance_certificates (property_id, unit_id, requested_by, as_of_date, expires_at, not_due_kurus,
			                                    verification_code, scope, tenant_link_id)
			VALUES ($1, $2, NULLIF($3, '')::uuid, $4, $5, $6, $7, $8, NULLIF($9, '')::uuid) RETURNING id`,
			propertyID, in.UnitID, c.GetString("user_id"), today, today.AddDate(0, 0, clearanceValidDays), notDue, code,
			scope, tenantLink).Scan(&id); err != nil {
			clearanceFail(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{
			"id": id, "verification_code": code, "verify_url": verifyBaseURL() + "/" + code,
			"as_of_date": today.Format("2006-01-02"), "expires_at": today.AddDate(0, 0, clearanceValidDays).Format("2006-01-02"),
			"not_due_kurus": notDue, "scope": scope,
			"note": map[string]string{
				"UNIT":    "Vadesi geçmiş borç yoktur. Vadesi gelmemiş cari tahakkuk borç sayılmaz ve belgede ayrıca belirtilir.",
				"TENANCY": "Kiracılık döneminize ait vadesi geçmiş kullanım gideri borcu yoktur. Belge malikin borçlarını kapsamaz.",
			}[scope],
		})
	}
}

// clearancePDF: GET /finance/clearance-certificates/:id/pdf — yönetim ya da bölümün sakini.
func clearancePDF(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		var unitID, unitLabel, code, scope, tenantName string
		var asOf, expires time.Time
		var issued time.Time
		var notDue int64
		err := dbscope.For(pool, propertyID).QueryRow(ctx, `
			SELECT c.unit_id::text, COALESCE(u.block, '') || '-' || u.door_number, c.verification_code,
			       c.as_of_date, c.expires_at, c.issued_at, c.not_due_kurus, c.scope,
			       COALESCE((SELECT us.first_name || ' ' || us.last_name FROM resident_units ru JOIN users us ON us.id = ru.resident_id
			                 WHERE ru.id = c.tenant_link_id), '')
			FROM clearance_certificates c JOIN units u ON u.id = c.unit_id
			WHERE c.id = $1 AND c.property_id = $2`, c.Param("id"), propertyID).
			Scan(&unitID, &unitLabel, &code, &asOf, &expires, &issued, &notDue, &scope, &tenantName)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Belge bulunamadı"})
			return
		}
		if err != nil {
			clearanceFail(c, err)
			return
		}
		if ok, err := canRequestFor(c, pool, propertyID, unitID); err != nil || !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "Belge bulunamadı"})
			return
		}
		url := verifyBaseURL() + "/" + code
		site := reports.PropertyName(ctx, pool, propertyID)
		facts := [][2]string{
			{"Bağımsız bölüm", unitLabel},
			{"Belge tarihi", asOf.Format("02.01.2006")},
			{"Geçerlilik", expires.Format("02.01.2006") + " tarihine kadar"},
		}
		if scope == "TENANCY" {
			facts = append(facts, [2]string{"Kapsam", "Kiracılık dönemi kullanım giderleri (" + tenantName + "); malikin borçlarını kapsamaz"})
		}
		if notDue > 0 {
			facts = append(facts, [2]string{"Vadesi gelmemiş tahakkuk", money.Kurus(notDue).Display() + " (son ödeme günü gelmediği için borç sayılmaz)"})
		}
		facts = append(facts, [2]string{"Doğrulama adresi", url}, [2]string{"Doğrulama kodu", code})
		subtitle := fmt.Sprintf("%s bağımsız bölümünün %s tarihi itibarıyla vadesi geçmiş hiçbir aidat veya ortak gider borcu bulunmamaktadır.",
			unitLabel, asOf.Format("02.01.2006"))
		if scope == "TENANCY" {
			subtitle = fmt.Sprintf("%s bağımsız bölümünde %s adına kiracılık dönemine ait vadesi geçmiş kullanım gideri borcu %s tarihi itibarıyla bulunmamaktadır. Belge malikin borçlarını kapsamaz.",
				unitLabel, tenantName, asOf.Format("02.01.2006"))
		}
		doc := &reports.Document{
			PropertyName: site,
			Title:        "Borcu yoktur belgesi",
			Subtitle:     subtitle,
			GeneratedAt:  issued, Facts: facts, QRText: url,
			Notes: []string{
				"Bu belge yönetim kayıtlarına göre otomatik üretilmiştir. Belgenin geçerliliği karekod ya da doğrulama adresiyle, " +
					"kimlik bilgisi gerekmeden sınanabilir; doğrulama sayfası kişisel veri göstermez.",
				"Vadesi gelmemiş (müeccel) cari dönem tahakkuku temerrüt doğurmaz; KMK m.20 uyarınca gecikme tazminatı yalnızca " +
					"vadesi geçmiş borca işler.",
			},
			SignatureLines: []string{"Yönetici"},
		}
		if err := reports.Write(c.Writer, doc, "pdf", "borcu-yoktur-belgesi"); err != nil {
			clearanceFail(c, err)
		}
	}
}

// verifyClearance: GET /api/v1/public/clearance/:code — KİMLİKSİZ; banka/tapu memuru doğrular.
func verifyClearance(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		code := strings.ToLower(strings.TrimSpace(c.Param("code")))
		if len(code) != 64 || strings.Trim(code, "0123456789abcdef") != "" {
			c.JSON(http.StatusBadRequest, gin.H{"valid": false, "error": "Doğrulama kodu 64 karakterlik onaltılık bir değer olmalı"})
			return
		}
		var site, unit string
		var asOf, expires time.Time
		var issued time.Time
		var scope string
		err := pool.QueryRow(c.Request.Context(),
			`SELECT property_name, unit_label, as_of_date, issued_at, expires_at, scope FROM verify_clearance_certificate_scoped($1)`, code).
			Scan(&site, &unit, &asOf, &issued, &expires, &scope)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"valid": false, "error": "Bu kodla üretilmiş bir belge yok"})
			return
		}
		if err != nil {
			log.Printf("[finance] belge doğrulama: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"valid": false, "error": "Doğrulama yapılamadı"})
			return
		}
		today, _ := time.Parse("2006-01-02", time.Now().Format("2006-01-02"))
		expired := today.After(expires)
		c.JSON(http.StatusOK, gin.H{
			"valid": !expired, "expired": expired, "property_name": site, "unit": unit,
			"as_of_date": asOf.Format("2006-01-02"), "issued_at": issued, "expires_at": expires.Format("2006-01-02"),
			"scope": scope,
			"statement": map[string]string{
				"UNIT":    "Belge tarihinde bu bağımsız bölümün vadesi geçmiş aidat veya ortak gider borcu yoktu.",
				"TENANCY": "Belge tarihinde bu bağımsız bölümdeki kiracılık dönemine ait vadesi geçmiş kullanım gideri borcu yoktu (malikin borçlarını kapsamaz).",
			}[scope],
		})
	}
}
