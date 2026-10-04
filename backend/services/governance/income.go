package main

// Ortak alan geliri (FAZ 7.6, M-46, migration 042).
//
// Kiralama, bütün kat maliklerinin oybirliğiyle (KMK m.45; UNANIMITY_TRANSFER_ACTS)
// kabul edilmiş genel kurul maddesine bağlanmadan kaydedilmez. Gelir bağımsız
// bölümlere arsa payı oranında kuruş hassasiyetinde paylaştırılır (pkg/money);
// her kat maliki kendi payını beyan eder, işyeri kiracısının stopajı da paylaştırılır.

import (
	"errors"
	"log"
	"net/http"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/money"
)

var leaseKinds = []string{"ROOF_FACADE_AD", "ANTENNA", "CARETAKER_FLAT", "PARKING", "STORAGE", "SHOP", "OTHER"}

type commonLease struct {
	ID               string     `json:"id"`
	AreaKind         string     `json:"area_kind"`
	AreaName         string     `json:"area_name"`
	TenantName       string     `json:"tenant_name"`
	TenantIsBusiness bool       `json:"tenant_is_business"`
	StartDate        time.Time  `json:"start_date"`
	EndDate          *time.Time `json:"end_date,omitempty"`
	MonthlyRent      float64    `json:"monthly_rent"`
	AgendaItemID     string     `json:"agenda_item_id"`
	DecisionRef      string     `json:"decision_ref"`
	Status           string     `json:"status"`
	Note             string     `json:"note,omitempty"`
	IncomeTotal      float64    `json:"income_total"`
}

func failIncome(c *gin.Context, err error, op string) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[governance] ortak alan geliri %s: %v", op, err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}

func listLeases(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		rows, err := dbscope.For(pool, propertyID).Query(c.Request.Context(), `
			SELECT l.id::text, l.area_kind, l.area_name, l.tenant_name, l.tenant_is_business, l.start_date, l.end_date,
			       l.monthly_rent::float8, l.agenda_item_id::text,
			       to_char(a.held_at AT TIME ZONE 'Europe/Istanbul', 'DD.MM.YYYY') || ' genel kurul, gündem ' || ai.order_no,
			       l.status, COALESCE(l.note,''),
			       COALESCE((SELECT sum(i.gross_amount) FROM common_area_incomes i WHERE i.lease_id = l.id), 0)::float8
			FROM common_area_leases l
			JOIN assembly_agenda_items ai ON ai.id = l.agenda_item_id
			JOIN assemblies a ON a.id = ai.assembly_id
			WHERE l.property_id = $1
			ORDER BY (l.status = 'ACTIVE') DESC, l.start_date DESC`, propertyID)
		if err != nil {
			failIncome(c, err, "listeleme")
			return
		}
		defer rows.Close()
		out := []commonLease{}
		for rows.Next() {
			var l commonLease
			if err := rows.Scan(&l.ID, &l.AreaKind, &l.AreaName, &l.TenantName, &l.TenantIsBusiness, &l.StartDate, &l.EndDate,
				&l.MonthlyRent, &l.AgendaItemID, &l.DecisionRef, &l.Status, &l.Note, &l.IncomeTotal); err != nil {
				failIncome(c, err, "listeleme")
				return
			}
			out = append(out, l)
		}
		if err := rows.Err(); err != nil {
			failIncome(c, err, "listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": out})
	}
}

func createLease(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			AreaKind         string  `json:"area_kind"`
			AreaName         string  `json:"area_name"`
			TenantName       string  `json:"tenant_name"`
			TenantIsBusiness bool    `json:"tenant_is_business"`
			StartDate        string  `json:"start_date"`
			EndDate          string  `json:"end_date"`
			MonthlyRent      float64 `json:"monthly_rent"`
			AgendaItemID     string  `json:"agenda_item_id"`
			Note             string  `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.AreaKind = strings.ToUpper(strings.TrimSpace(in.AreaKind))
		in.AreaName, in.TenantName = strings.TrimSpace(in.AreaName), strings.TrimSpace(in.TenantName)
		if strings.Contains(strings.ToUpper(in.AreaKind), "SHELTER") || strings.Contains(strings.ToLower(in.AreaName), "sığınak") {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Sığınak kiraya verilemez (Sığınak Yönetmeliği); özel amaca tahsisli yer tahsis kaldırılmadan kiralanamaz"})
			return
		}
		start, err := time.ParseInLocation("2006-01-02", in.StartDate, time.Local)
		if !slices.Contains(leaseKinds, in.AreaKind) || in.AreaName == "" || in.TenantName == "" || err != nil || in.MonthlyRent <= 0 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Alan türü, adı, kiracı, başlangıç tarihi ve pozitif aylık kira zorunludur", "valid": leaseKinds})
			return
		}
		var end *time.Time
		if in.EndDate != "" {
			t, err := time.ParseInLocation("2006-01-02", in.EndDate, time.Local)
			if err != nil || t.Before(start) {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bitiş tarihi başlangıçtan önce olamaz"})
				return
			}
			end = &t
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		scope := dbscope.For(pool, propertyID)
		var ok bool
		if err := scope.QueryRow(ctx, `
			SELECT EXISTS (SELECT 1 FROM assembly_agenda_items ai JOIN assemblies a ON a.id = ai.assembly_id
			               WHERE ai.id = $1::uuid AND a.property_id = $2 AND a.status = 'HELD'
			                 AND ai.decision_status = 'ACCEPTED' AND ai.required_majority_code = 'UNANIMITY_TRANSFER_ACTS')`,
			in.AgendaItemID, propertyID).Scan(&ok); err != nil && !isBadUUID(err) {
			failIncome(c, err, "karar denetimi")
			return
		}
		if !ok {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ortak yerin kiraya verilmesi bütün kat maliklerinin oybirliğini ister (KMK m.45): " +
				"oybirliği nisabıyla (UNANIMITY_TRANSFER_ACTS) kabul edilmiş, yapılmış genel kurul gündem maddesi gösterilmelidir"})
			return
		}
		var id string
		if err := scope.QueryRow(ctx, `
			INSERT INTO common_area_leases (property_id, area_kind, area_name, tenant_name, tenant_is_business, start_date, end_date,
			    monthly_rent, agenda_item_id, note)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NULLIF($10,'')) RETURNING id::text`,
			propertyID, in.AreaKind, in.AreaName, in.TenantName, in.TenantIsBusiness, start, end, in.MonthlyRent,
			in.AgendaItemID, strings.TrimSpace(in.Note)).Scan(&id); err != nil {
			failIncome(c, err, "kiralama kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id})
	}
}

func endLease(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			EndDate string `json:"end_date"`
		}
		_ = c.ShouldBindJSON(&in)
		end, err := time.ParseInLocation("2006-01-02", in.EndDate, time.Local)
		if err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "end_date (YYYY-AA-GG) zorunludur"})
			return
		}
		tag, err := dbscope.For(pool, c.GetString("property_id")).Exec(c.Request.Context(), `
			UPDATE common_area_leases SET status = 'ENDED', end_date = $3
			WHERE id = $1 AND property_id = $2 AND status = 'ACTIVE' AND start_date <= $3`, c.Param("id"), c.GetString("property_id"), end)
		if err != nil {
			failIncome(c, err, "sona erdirme")
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Aktif kiralama bulunamadı ya da bitiş başlangıçtan önce"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Kiralama sona erdirildi"})
	}
}

// recordIncome, aylık kira tahsilatını yazar ve arsa payı oranında paylaştırır.
func recordIncome(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Period            string  `json:"period"`
			GrossAmount       float64 `json:"gross_amount"`
			WithholdingAmount float64 `json:"withholding_amount"`
			ReceivedOn        string  `json:"received_on"`
			Note              string  `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		recv, err := time.ParseInLocation("2006-01-02", in.ReceivedOn, time.Local)
		if _, perr := time.Parse("2006-01", in.Period); perr != nil || err != nil || recv.After(time.Now()) ||
			in.GrossAmount <= 0 || in.WithholdingAmount < 0 || in.WithholdingAmount > in.GrossAmount {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Dönem (YYYY-AA), bugünden ileri olmayan tahsilat tarihi ve pozitif tutar zorunlu; stopaj brüt tutarı aşamaz"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		tx, err := dbscope.For(pool, propertyID).Begin(ctx)
		if err != nil {
			failIncome(c, err, "gelir kaydı")
			return
		}
		defer tx.Rollback(ctx) //nolint:errcheck
		var business bool
		err = tx.QueryRow(ctx, `SELECT tenant_is_business FROM common_area_leases WHERE id = $1 AND property_id = $2`,
			c.Param("id"), propertyID).Scan(&business)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Kiralama bulunamadı"})
			return
		}
		if err != nil {
			failIncome(c, err, "gelir kaydı")
			return
		}
		if !business && in.WithholdingAmount > 0 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kiracı işyeri değilse kira ödemesinden stopaj yapılmaz (GVK m.94)"})
			return
		}
		var incomeID string
		if err := tx.QueryRow(ctx, `
			INSERT INTO common_area_incomes (lease_id, period, gross_amount, withholding_amount, received_on, note, recorded_by)
			VALUES ($1, $2, $3, $4, $5, NULLIF($6,''), NULLIF($7,'')::uuid) RETURNING id::text`,
			c.Param("id"), in.Period, in.GrossAmount, in.WithholdingAmount, recv, strings.TrimSpace(in.Note), c.GetString("user_id")).Scan(&incomeID); err != nil {
			var pg *pgconn.PgError
			if errors.As(err, &pg) && pg.Code == "23505" {
				c.JSON(http.StatusConflict, gin.H{"error": "Bu dönemin geliri zaten kayıtlı"})
				return
			}
			failIncome(c, err, "gelir kaydı")
			return
		}
		rows, err := tx.Query(ctx, `SELECT id::text, COALESCE(share_ratio, 0)::text FROM units WHERE property_id = $1 AND deleted = 0`, propertyID)
		if err != nil {
			failIncome(c, err, "paylaştırma")
			return
		}
		var shares []money.Share
		for rows.Next() {
			var id, w string
			if err := rows.Scan(&id, &w); err != nil {
				rows.Close()
				failIncome(c, err, "paylaştırma")
				return
			}
			shares = append(shares, money.Share{Key: id, Weight: decimal.RequireFromString(w)})
		}
		rows.Close()
		gross, err1 := money.Distribute(money.FromFloatTRY(in.GrossAmount), shares)
		wh, err2 := money.Distribute(money.FromFloatTRY(in.WithholdingAmount), shares)
		if err1 != nil || err2 != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gelir paylaştırılamadı: bağımsız bölümlerin arsa payı tanımlı değil"})
			return
		}
		whBy := map[string]int64{}
		for _, d := range wh {
			whBy[d.Key] = int64(d.Amount)
		}
		for _, d := range gross {
			if _, err := tx.Exec(ctx, `INSERT INTO common_area_income_shares (income_id, unit_id, gross_kurus, withholding_kurus)
				VALUES ($1, $2, $3, $4)`, incomeID, d.Key, int64(d.Amount), whBy[d.Key]); err != nil {
				failIncome(c, err, "paylaştırma")
				return
			}
		}
		if err := tx.Commit(ctx); err != nil {
			failIncome(c, err, "gelir kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": incomeID, "units": len(gross),
			"note": "Gelir bağımsız bölümlere arsa payı oranında paylaştırıldı; her kat maliki kendi payını beyan eder."})
	}
}

type incomeShareRow struct {
	UnitID           string  `json:"unit_id"`
	Unit             string  `json:"unit"`
	Owners           string  `json:"owners"`
	GrossKurus       int64   `json:"gross_kurus"`
	WithholdingKurus int64   `json:"withholding_kurus"`
	ShareRatio       float64 `json:"share_ratio"`
}

// incomeReport: yıl bazında bölüm (ve malik) payları. onlyUser doluysa yalnızca
// kişinin MALİKİ olduğu bölümler (kendi beyanı için).
func incomeReport(pool *pgxpool.Pool, mine bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		year, err := strconv.Atoi(c.DefaultQuery("year", strconv.Itoa(time.Now().Year()-1)))
		if err != nil || year < 2000 || year > 2200 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "year geçersiz"})
			return
		}
		user := ""
		if mine {
			user = c.GetString("user_id")
		}
		propertyID := c.GetString("property_id")
		rows, err := dbscope.For(pool, propertyID).Query(c.Request.Context(), `
			SELECT u.id::text, COALESCE(u.block,'') || '-' || COALESCE(u.door_number,''),
			       COALESCE((SELECT string_agg(p.first_name || ' ' || p.last_name, ', ' ORDER BY p.first_name)
			                 FROM resident_units ru JOIN users p ON p.id = ru.resident_id
			                 WHERE ru.unit_id = u.id AND ru.role = 'OWNER' AND COALESCE(ru.is_active, true)), ''),
			       sum(s.gross_kurus)::bigint, sum(s.withholding_kurus)::bigint, COALESCE(u.share_ratio, 0)::float8
			FROM common_area_income_shares s
			JOIN common_area_incomes i ON i.id = s.income_id
			JOIN common_area_leases l ON l.id = i.lease_id AND l.property_id = $1
			JOIN units u ON u.id = s.unit_id
			WHERE left(i.period, 4) = $2
			  AND ($3 = '' OR EXISTS (SELECT 1 FROM resident_units ru WHERE ru.unit_id = u.id AND ru.resident_id::text = $3
			                           AND ru.role = 'OWNER' AND COALESCE(ru.is_active, true)))
			GROUP BY u.id, u.block, u.door_number, u.share_ratio
			ORDER BY u.block, u.door_number`, propertyID, strconv.Itoa(year), user)
		if err != nil {
			failIncome(c, err, "rapor")
			return
		}
		defer rows.Close()
		out := []incomeShareRow{}
		var tg, tw int64
		for rows.Next() {
			var r incomeShareRow
			if err := rows.Scan(&r.UnitID, &r.Unit, &r.Owners, &r.GrossKurus, &r.WithholdingKurus, &r.ShareRatio); err != nil {
				failIncome(c, err, "rapor")
				return
			}
			tg += r.GrossKurus
			tw += r.WithholdingKurus
			out = append(out, r)
		}
		if err := rows.Err(); err != nil {
			failIncome(c, err, "rapor")
			return
		}
		c.JSON(http.StatusOK, gin.H{"year": year, "data": out, "total_gross_kurus": tg, "total_withholding_kurus": tw,
			"note": "Ortak alan kira geliri kat maliklerinindir; her malik kendi payını yıllık beyannamesinde değerlendirir " +
				"(birden çok malik varsa pay oranında). Kesilen stopaj beyanda mahsup edilir. Beyan zorunluluğu ve istisnalar mali müşavirce değerlendirilir."})
	}
}

func isBadUUID(err error) bool {
	var pg *pgconn.PgError
	return errors.As(err, &pg) && pg.Code == "22P02"
}
