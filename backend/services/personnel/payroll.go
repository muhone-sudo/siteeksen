package main

// Bordro KAYDI (FAZ 7.4, migration 047, kullanıcı kararı S-22 = b).
//
// Bordro mali müşavirden gelir; bu modül ücret, vergi ya da SGK primi HESAPLAMAZ.
// Kaydedilen: çalışana ödenen net tutar, sitenin işveren maliyeti, bordronun
// kaynağı ve ödeme bilgisi. Bordrodaki ara kalemler (brüt, SGK, vergi) isteğe
// bağlıdır ve bilgi amaçlı saklanır; sistem onları birbirine göre doğrulamaz —
// doğrulamak, hesaplamak demek olurdu.
//
// Maaş bilgisi STAFF rolüne kapalıdır (personel modülünün genel kuralı).

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/middleware"
)

var periodRe = regexp.MustCompile(`^[0-9]{4}-(0[1-9]|1[0-2])$`)

// PayrollNote her yanıtta döner: sistemin ne yapmadığını açıkça söyler.
const PayrollNote = "Bordro mali müşavirden gelir; sistem ücret, gelir/damga vergisi ve SGK primi hesaplamaz. " +
	"Kaydedilen tutarlar bordrodan girilir ve doğrulanmaz."

type payrollRow struct {
	ID               string   `json:"id"`
	EmployeeID       string   `json:"employee_id"`
	EmployeeName     string   `json:"employee_name"`
	Position         string   `json:"position"`
	Period           string   `json:"period"`
	NetSalary        float64  `json:"net_salary"`
	EmployerCost     float64  `json:"employer_cost"`
	GrossSalary      *float64 `json:"gross_salary,omitempty"`
	SGKEmployee      *float64 `json:"sgk_employee,omitempty"`
	SGKEmployer      *float64 `json:"sgk_employer,omitempty"`
	IncomeTax        *float64 `json:"income_tax,omitempty"`
	StampTax         *float64 `json:"stamp_tax,omitempty"`
	SourceRef        string   `json:"source_ref"`
	PaymentStatus    string   `json:"payment_status"`
	PaymentDate      *string  `json:"payment_date,omitempty"`
	PaymentReference string   `json:"payment_reference,omitempty"`
	CancelReason     string   `json:"cancel_reason,omitempty"`
	Notes            string   `json:"notes,omitempty"`
}

// parseAmount, isteğe bağlı JSON tutarını kayan nokta kullanmadan ayrıştırır.
func parseAmount(n *json.Number) (*string, bool) {
	if n == nil || *n == "" {
		return nil, true
	}
	d, err := decimal.NewFromString(n.String())
	if err != nil || d.IsNegative() || d.Exponent() < -2 {
		return nil, false
	}
	s := d.StringFixed(2)
	return &s, true
}

// listPayroll: GET /payroll?period=YYYY-AA (yönetim, kurul, denetçi).
func listPayroll(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		period := c.DefaultQuery("period", time.Now().Format("2006-01"))
		if !periodRe.MatchString(period) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "period YYYY-AA biçiminde olmalı"})
			return
		}
		propertyID := c.GetString("property_id")
		sc := dbscope.For(pool, propertyID)
		rows, err := sc.Query(c.Request.Context(), `
			SELECT p.id, p.employee_id, e.first_name || ' ' || e.last_name, e.position, p.period,
			       p.net_salary::float8, p.employer_cost::float8, p.gross_salary::float8,
			       p.sgk_employee::float8, p.sgk_employer::float8, p.income_tax::float8, p.stamp_tax::float8,
			       p.source_ref, p.payment_status, to_char(p.payment_date, 'YYYY-MM-DD'),
			       COALESCE(p.payment_reference, ''), COALESCE(p.cancel_reason, ''), COALESCE(p.notes, '')
			FROM payroll p JOIN employees e ON e.id = p.employee_id
			WHERE p.property_id = $1 AND p.period = $2
			ORDER BY e.last_name, e.first_name`, propertyID, period)
		if err != nil {
			failPayroll(c, err)
			return
		}
		defer rows.Close()
		out := []payrollRow{}
		for rows.Next() {
			var r payrollRow
			if err := rows.Scan(&r.ID, &r.EmployeeID, &r.EmployeeName, &r.Position, &r.Period,
				&r.NetSalary, &r.EmployerCost, &r.GrossSalary, &r.SGKEmployee, &r.SGKEmployer,
				&r.IncomeTax, &r.StampTax, &r.SourceRef, &r.PaymentStatus, &r.PaymentDate,
				&r.PaymentReference, &r.CancelReason, &r.Notes); err != nil {
				failPayroll(c, err)
				return
			}
			out = append(out, r)
		}
		if err := rows.Err(); err != nil {
			failPayroll(c, err)
			return
		}

		// Toplamlar veritabanında NUMERIC ile alınır (kuruş kaybı yok); iptal edilenler hariç.
		var net, cost, unpaid string
		var paidN, pendingN int
		if err := sc.QueryRow(c.Request.Context(), `
			SELECT COALESCE(sum(net_salary), 0)::text, COALESCE(sum(employer_cost), 0)::text,
			       COALESCE(sum(net_salary) FILTER (WHERE payment_status = 'PENDING'), 0)::text,
			       count(*) FILTER (WHERE payment_status = 'PAID'),
			       count(*) FILTER (WHERE payment_status = 'PENDING')
			FROM payroll WHERE property_id = $1 AND period = $2 AND payment_status <> 'CANCELLED'`,
			propertyID, period).Scan(&net, &cost, &unpaid, &paidN, &pendingN); err != nil {
			failPayroll(c, err)
			return
		}

		// Dönemde çalışmış ama bordrosu girilmemiş personel — mali müşavirden eksik gelen bordroyu gösterir.
		var missing []string
		mrows, err := sc.Query(c.Request.Context(), `
			SELECT e.first_name || ' ' || e.last_name
			FROM employees e
			WHERE e.property_id = $1 AND e.deleted = 0
			  AND e.hire_date <= (to_date($2, 'YYYY-MM') + interval '1 month' - interval '1 day')::date
			  AND (e.end_date IS NULL OR e.end_date >= to_date($2, 'YYYY-MM'))
			  AND NOT EXISTS (SELECT 1 FROM payroll p WHERE p.employee_id = e.id AND p.period = $2
			                  AND p.payment_status <> 'CANCELLED')
			ORDER BY e.last_name, e.first_name`, propertyID, period)
		if err != nil {
			failPayroll(c, err)
			return
		}
		for mrows.Next() {
			var n string
			if err := mrows.Scan(&n); err != nil {
				mrows.Close()
				failPayroll(c, err)
				return
			}
			missing = append(missing, n)
		}
		mrows.Close()
		if missing == nil {
			missing = []string{}
		}

		c.JSON(http.StatusOK, gin.H{
			"period": period, "data": out,
			"totals": gin.H{"net": decimalFloat(net), "employer_cost": decimalFloat(cost), "unpaid_net": decimalFloat(unpaid),
				"paid_count": paidN, "pending_count": pendingN},
			"missing": missing, "note": PayrollNote,
		})
	}
}

// payrollCosts: GET /payroll/costs?year=YYYY — aylık işveren maliyeti (bütçe ve denetim için).
func payrollCosts(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		year := c.DefaultQuery("year", time.Now().Format("2006"))
		if len(year) != 4 || strings.Trim(year, "0123456789") != "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "year YYYY biçiminde olmalı"})
			return
		}
		propertyID := c.GetString("property_id")
		rows, err := dbscope.For(pool, propertyID).Query(c.Request.Context(), `
			SELECT period, count(*), sum(net_salary)::text, sum(employer_cost)::text
			FROM payroll WHERE property_id = $1 AND period LIKE $2 || '-%' AND payment_status <> 'CANCELLED'
			GROUP BY period ORDER BY period`, propertyID, year)
		if err != nil {
			failPayroll(c, err)
			return
		}
		defer rows.Close()
		type month struct {
			Period       string  `json:"period"`
			Employees    int     `json:"employees"`
			Net          float64 `json:"net"`
			EmployerCost float64 `json:"employer_cost"`
		}
		out := []month{}
		total := decimal.Zero
		for rows.Next() {
			var m month
			var n, ec string
			if err := rows.Scan(&m.Period, &m.Employees, &n, &ec); err != nil {
				failPayroll(c, err)
				return
			}
			m.Net, m.EmployerCost = decimalFloat(n), decimalFloat(ec)
			if d, err := decimal.NewFromString(ec); err == nil {
				total = total.Add(d)
			}
			out = append(out, m)
		}
		if err := rows.Err(); err != nil {
			failPayroll(c, err)
			return
		}
		tf, _ := total.Float64()
		c.JSON(http.StatusOK, gin.H{"year": year, "data": out, "employer_cost_total": tf, "note": PayrollNote})
	}
}

// createPayroll: POST /payroll (yönetim). Ödeme tarihi verilirse kayıt ÖDENDİ olarak açılır.
func createPayroll(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			EmployeeID       string       `json:"employee_id"`
			Period           string       `json:"period"`
			NetSalary        *json.Number `json:"net_salary"`
			EmployerCost     *json.Number `json:"employer_cost"`
			GrossSalary      *json.Number `json:"gross_salary"`
			SGKEmployee      *json.Number `json:"sgk_employee"`
			SGKEmployer      *json.Number `json:"sgk_employer"`
			IncomeTax        *json.Number `json:"income_tax"`
			StampTax         *json.Number `json:"stamp_tax"`
			SourceRef        string       `json:"source_ref"`
			PaymentDate      string       `json:"payment_date"`
			PaymentReference string       `json:"payment_reference"`
			Notes            string       `json:"notes"`
		}
		dec := json.NewDecoder(c.Request.Body)
		dec.UseNumber()
		if err := dec.Decode(&in); err != nil || in.EmployeeID == "" || !periodRe.MatchString(in.Period) ||
			in.NetSalary == nil || in.EmployerCost == nil || strings.TrimSpace(in.SourceRef) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "employee_id, period (YYYY-AA), net_salary, employer_cost ve source_ref (bordronun kaynağı) zorunludur"})
			return
		}
		if in.Period > time.Now().Format("2006-01") {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gelecek döneme bordro kaydı girilemez"})
			return
		}
		amounts := map[string]*json.Number{"net_salary": in.NetSalary, "employer_cost": in.EmployerCost,
			"gross_salary": in.GrossSalary, "sgk_employee": in.SGKEmployee, "sgk_employer": in.SGKEmployer,
			"income_tax": in.IncomeTax, "stamp_tax": in.StampTax}
		parsed := map[string]*string{}
		for k, v := range amounts {
			s, ok := parseAmount(v)
			if !ok {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": k + " negatif olmayan, en fazla iki ondalıklı bir tutar olmalı"})
				return
			}
			parsed[k] = s
		}
		net, _ := decimal.NewFromString(*parsed["net_salary"])
		cost, _ := decimal.NewFromString(*parsed["employer_cost"])
		if !net.IsPositive() || cost.LessThan(net) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Net tutar sıfırdan büyük ve işveren maliyeti net tutardan küçük olmamalı"})
			return
		}
		var payDate *time.Time
		if in.PaymentDate != "" {
			t, err := time.ParseInLocation("2006-01-02", in.PaymentDate, time.Local)
			if err != nil || t.After(time.Now()) {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ödeme tarihi geçerli ve bugünden ileri olmayan bir tarih olmalı"})
				return
			}
			payDate = &t
		}
		status := "PENDING"
		if payDate != nil {
			status = "PAID"
		}

		propertyID := c.GetString("property_id")
		var id string
		err := dbscope.For(pool, propertyID).QueryRow(c.Request.Context(), `
			INSERT INTO payroll (property_id, employee_id, period, period_start, period_end,
			                     net_salary, employer_cost, gross_salary, sgk_employee, sgk_employer,
			                     income_tax, stamp_tax, source_ref, payment_status, payment_date,
			                     payment_reference, notes, recorded_by)
			SELECT $1, e.id, $3::text, to_date($3::text, 'YYYY-MM'), (to_date($3::text, 'YYYY-MM') + interval '1 month' - interval '1 day')::date,
			       $4::numeric, $5::numeric, $6::numeric, $7::numeric, $8::numeric, $9::numeric, $10::numeric,
			       $11, $12, $13, NULLIF($14, ''), NULLIF($15, ''), $16
			FROM employees e
			WHERE e.id = $2 AND e.property_id = $1 AND e.deleted = 0
			  AND e.hire_date <= (to_date($3::text, 'YYYY-MM') + interval '1 month' - interval '1 day')::date
			  AND (e.end_date IS NULL OR e.end_date >= to_date($3::text, 'YYYY-MM'))
			RETURNING id`,
			propertyID, in.EmployeeID, in.Period, parsed["net_salary"], parsed["employer_cost"],
			parsed["gross_salary"], parsed["sgk_employee"], parsed["sgk_employer"], parsed["income_tax"],
			parsed["stamp_tax"], strings.TrimSpace(in.SourceRef), status, payDate,
			strings.TrimSpace(in.PaymentReference), strings.TrimSpace(in.Notes), c.GetString("user_id")).Scan(&id)
		if errors.Is(err, pgx.ErrNoRows) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Personel bulunamadı ya da bu dönemde çalışmıyordu (işe giriş / ayrılış tarihi)"})
			return
		}
		if err != nil {
			failPayroll(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "payment_status": status, "note": PayrollNote})
	}
}

// payPayroll: POST /payroll/:id/pay — bekleyen kaydı ÖDENDİ yapar.
func payPayroll(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			PaymentDate      string `json:"payment_date"`
			PaymentReference string `json:"payment_reference"`
		}
		_ = c.ShouldBindJSON(&in)
		t, err := time.ParseInLocation("2006-01-02", in.PaymentDate, time.Local)
		if err != nil || t.After(time.Now()) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "payment_date geçerli ve bugünden ileri olmayan bir tarih olmalı"})
			return
		}
		propertyID := c.GetString("property_id")
		tag, err := dbscope.For(pool, propertyID).Exec(c.Request.Context(), `
			UPDATE payroll SET payment_status = 'PAID', payment_date = $3, payment_reference = NULLIF($4, '')
			WHERE id = $1 AND property_id = $2 AND payment_status = 'PENDING'`,
			c.Param("id"), propertyID, t, strings.TrimSpace(in.PaymentReference))
		if err != nil {
			failPayroll(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Kayıt bulunamadı ya da ödeme bekleyen durumda değil"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Ödeme kaydedildi"})
	}
}

// cancelPayroll: POST /payroll/:id/cancel — bekleyen hatalı kaydı gerekçeyle iptal eder (silinmez).
func cancelPayroll(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.Reason) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "İptal gerekçesi zorunludur"})
			return
		}
		propertyID := c.GetString("property_id")
		tag, err := dbscope.For(pool, propertyID).Exec(c.Request.Context(), `
			UPDATE payroll SET payment_status = 'CANCELLED', cancel_reason = $3
			WHERE id = $1 AND property_id = $2 AND payment_status = 'PENDING'`,
			c.Param("id"), propertyID, strings.TrimSpace(in.Reason))
		if err != nil {
			failPayroll(c, err)
			return
		}
		if tag.RowsAffected() == 0 {
			c.JSON(http.StatusConflict, gin.H{"error": "Yalnızca ödeme bekleyen kayıt iptal edilebilir; ödenmiş bordro değiştirilemez"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Bordro kaydı iptal edildi"})
	}
}

func decimalFloat(s string) float64 {
	d, err := decimal.NewFromString(s)
	if err != nil {
		return 0
	}
	f, _ := d.Float64()
	return f
}

func failPayroll(c *gin.Context, err error) {
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[personnel] bordro: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
}
