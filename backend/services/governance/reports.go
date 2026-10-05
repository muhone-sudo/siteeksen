package main

// Yönetişim dökümleri: hazirun cetveli, karar defteri, işletme projesi (TEST_RAPORU 2.6).

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/dbscope"
	"github.com/siteeksen/backend/pkg/reports"
)

func govWriteReport(c *gin.Context, d *reports.Document, base string) {
	if err := reports.Write(c.Writer, d, c.Query("format"), base); err != nil {
		if errors.Is(err, reports.ErrFormat) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "format pdf ya da xlsx olmalı"})
			return
		}
		log.Printf("[governance] rapor üretilemedi: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Rapor üretilemedi"})
	}
}

func govReportFail(c *gin.Context, err error) {
	if errors.Is(err, pgx.ErrNoRows) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
		return
	}
	log.Printf("[governance] rapor verisi: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": "Rapor verisi alınamadı"})
}

func share(s string) string {
	d, err := decimal.NewFromString(s)
	if err != nil {
		return s
	}
	return strings.Replace(d.StringFixed(2), ".", ",", 1)
}

// attendanceSheet: GET /governance/assemblies/:id/attendance-sheet — hazirun cetveli.
// Toplantı öncesi boş imza cetveli olarak (tüm malikler), toplantıdan sonra katılım
// işaretli olarak kullanılır (KMK m.29-30: nisap sayı ve arsa payıyla).
func attendanceSheet(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		sc := dbscope.For(pool, propertyID)
		var kind, status string
		var call int
		var scheduled time.Time
		var held *time.Time
		var location *string
		var totalUnits *int
		var totalShare, attShare *string
		err := sc.QueryRow(ctx, `SELECT kind, call_number, scheduled_at, held_at, location, status, total_units,
		        total_share_ratio::text, attended_share_ratio::text
			FROM assemblies WHERE id = $1 AND property_id = $2`, c.Param("id"), propertyID).
			Scan(&kind, &call, &scheduled, &held, &location, &status, &totalUnits, &totalShare, &attShare)
		if err != nil {
			govReportFail(c, err)
			return
		}
		rows, err := sc.Query(ctx, `
			SELECT COALESCE(u.block,'') || '-' || u.door_number, u.share_ratio::text,
			       COALESCE((SELECT string_agg(us.first_name || ' ' || us.last_name, ', ' ORDER BY us.last_name)
			                 FROM resident_units ru JOIN users us ON us.id = ru.resident_id
			                 WHERE ru.unit_id = u.id AND ru.is_active AND ru.role = 'OWNER'), '') AS owners,
			       a.attendance_type, COALESCE(ph.first_name || ' ' || ph.last_name, '')
			FROM units u
			LEFT JOIN assembly_attendees a ON a.unit_id = u.id AND a.assembly_id = $2
			LEFT JOIN users ph ON ph.id = a.proxy_holder_id
			WHERE u.property_id = $1 AND u.deleted = 0
			ORDER BY u.block, u.door_number`, propertyID, c.Param("id"))
		if err != nil {
			govReportFail(c, err)
			return
		}
		defer rows.Close()
		table := [][]string{}
		present := 0
		for rows.Next() {
			var unit, sr, owners, holder string
			var att *string
			if err := rows.Scan(&unit, &sr, &owners, &att, &holder); err != nil {
				govReportFail(c, err)
				return
			}
			how := ""
			if att != nil {
				present++
				how = "Asaleten"
				if *att == "PROXY" {
					how = "Vekâleten: " + holder
				}
			}
			table = append(table, []string{unit, share(sr), owners, how, ""})
		}
		if err := rows.Err(); err != nil {
			govReportFail(c, err)
			return
		}
		facts := [][2]string{
			{"Toplantı", fmt.Sprintf("%s genel kurul, %d. toplantı", map[string]string{"ORDINARY": "Olağan", "EXTRAORDINARY": "Olağanüstü"}[kind], call)},
			{"Tarih", scheduled.In(time.Local).Format("02.01.2006 15:04")},
			{"Durum", status},
		}
		if location != nil && *location != "" {
			facts = append(facts, [2]string{"Yer", *location})
		}
		if held != nil {
			facts = append(facts, [2]string{"Katılan bölüm", fmt.Sprintf("%d / %d (arsa payı %s / %s)", present, len(table),
				share(deref(attShare)), share(deref(totalShare)))})
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(ctx, pool, propertyID),
			Title:        "Hazirun cetveli", Subtitle: "Kat malikleri kurulu toplantısına katılanlar listesi",
			GeneratedAt: time.Now(), Landscape: true, Facts: facts,
			Tables: []reports.Table{{Title: "Bağımsız bölümler", Headers: []string{"Bölüm", "Arsa payı", "Kat malik(ler)i", "Katılım", "İmza"},
				Widths: []float64{25, 25, 90, 70, 57}, RightAlign: []int{1}, Rows: table}},
			Notes: []string{"KMK m.29: toplantı çağrısı en az 15 gün önce imza karşılığı ya da taahhütlü mektupla yapılır. " +
				"KMK m.30: kurul, kat maliklerinin sayı ve arsa payı çoğunluğuyla toplanır; vekil kat maliki olmayabilir " +
				"(vekâletname tutanağa eklenir)."},
			SignatureLines: []string{"Toplantı başkanı", "Yazman", "Oy toplayıcı"},
		}
		govWriteReport(c, doc, "hazirun-cetveli")
	}
}

func deref(s *string) string {
	if s == nil {
		return "0"
	}
	return *s
}

// bookExport: GET /governance/books/:id/export — karar/işletme defteri dökümü + zincir doğrulaması.
func bookExport(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		sc := dbscope.For(pool, propertyID)
		var kind, status string
		var year int
		var notaryRef *string
		var opened *time.Time
		if err := sc.QueryRow(ctx, `SELECT kind, period_year, status, notary_ref, notary_opened_at FROM books
			WHERE id = $1 AND property_id = $2`, c.Param("id"), propertyID).Scan(&kind, &year, &status, &notaryRef, &opened); err != nil {
			govReportFail(c, err)
			return
		}
		rows, err := sc.Query(ctx, `SELECT entry_no, entry_date, title, body, COALESCE(prev_hash,''), entry_hash
			FROM book_entries WHERE book_id = $1 ORDER BY entry_no`, c.Param("id"))
		if err != nil {
			govReportFail(c, err)
			return
		}
		defer rows.Close()
		table := [][]string{}
		chainOK, prev := true, ""
		for rows.Next() {
			var no int
			var date time.Time
			var title, body, prevHash, hash string
			if err := rows.Scan(&no, &date, &title, &body, &prevHash, &hash); err != nil {
				govReportFail(c, err)
				return
			}
			// Zincir bağı: her kaydın önceki özeti bir önceki kaydın özetiyle aynı olmalı.
			if no > 1 && prevHash != prev {
				chainOK = false
			}
			prev = hash
			table = append(table, []string{strconv.Itoa(no), date.Format("02.01.2006"), title + "\n" + body, hash[:16] + "…"})
		}
		if err := rows.Err(); err != nil {
			govReportFail(c, err)
			return
		}
		name := map[string]string{"DECISION": "Karar defteri", "OPERATING": "İşletme defteri"}[kind]
		chain := "Bağlar tutarlı (her kayıt bir öncekinin SHA-256 özetine bağlı)"
		if !chainOK {
			chain = "UYARI: zincir bağı kopuk — defter kaydı değiştirilmiş olabilir"
		}
		facts := [][2]string{{"Defter", fmt.Sprintf("%s — %d", name, year)}, {"Durum", status}, {"Kayıt sayısı", strconv.Itoa(len(table))}, {"Zincir", chain}}
		if notaryRef != nil && *notaryRef != "" {
			facts = append(facts, [2]string{"Noter onayı", *notaryRef})
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(ctx, pool, propertyID), Title: name + " dökümü", GeneratedAt: time.Now(), Facts: facts,
			Tables: []reports.Table{{Title: "Kayıtlar", Headers: []string{"No", "Tarih", "Karar / kayıt", "Özet (SHA-256)"},
				Widths: []float64{12, 22, 110, 36}, Rows: table}},
			Notes: []string{"KMK m.32: kurul kararları noterce onaylı karar defterine yazılır ve toplantıya katılanlarca imzalanır. " +
				"Bu döküm noter onaylı defterin yerine geçmez; defterle karşılaştırma ve denetim içindir. " +
				"Tam özetler ve zincir doğrulaması uygulamadaki \"Doğrula\" işlemiyle de görülebilir."},
		}
		govWriteReport(c, doc, strings.ToLower(strings.ReplaceAll(name, " ", "-")))
	}
}

// budgetExport: GET /governance/budgets/:id/export — işletme projesi (kalemler + bölüm payları).
func budgetExport(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		ctx := c.Request.Context()
		sc := dbscope.For(pool, propertyID)
		var year int
		var status, total string
		var decision *string
		if err := sc.QueryRow(ctx, `SELECT period_year, status, total_amount::text, decision_ref FROM operating_budgets
			WHERE id = $1 AND property_id = $2`, c.Param("id"), propertyID).Scan(&year, &status, &total, &decision); err != nil {
			govReportFail(c, err)
			return
		}
		irows, err := sc.Query(ctx, `SELECT name, amount::text, distribution_type, COALESCE(kind,'EXPENSE') FROM operating_budget_items
			WHERE budget_id = $1 ORDER BY sort_order, name`, c.Param("id"))
		if err != nil {
			govReportFail(c, err)
			return
		}
		items := [][]string{}
		dist := map[string]string{"EQUAL": "Eşit", "SHARE_RATIO": "Arsa payı", "AREA_M2": "m²", "METER_READING": "Sayaç", "CUSTOM": "Özel"}
		for irows.Next() {
			var n, amt, d, k string
			if err := irows.Scan(&n, &amt, &d, &k); err != nil {
				irows.Close()
				govReportFail(c, err)
				return
			}
			kindTxt := "Gider"
			if k == "INCOME" {
				kindTxt = "Gelir"
			}
			a, _ := decimal.NewFromString(amt)
			items = append(items, []string{n, kindTxt, dist[d], reports.Money(a.Mul(decimal.NewFromInt(100)).IntPart())})
		}
		irows.Close()
		srows, err := sc.Query(ctx, `SELECT COALESCE(u.block,'') || '-' || u.door_number, s.annual_kurus, s.monthly_kurus
			FROM operating_budget_unit_shares s JOIN units u ON u.id = s.unit_id WHERE s.budget_id = $1 ORDER BY u.block, u.door_number`, c.Param("id"))
		if err != nil {
			govReportFail(c, err)
			return
		}
		shares := [][]string{}
		var sum int64
		for srows.Next() {
			var u string
			var annual, monthly int64
			if err := srows.Scan(&u, &annual, &monthly); err != nil {
				srows.Close()
				govReportFail(c, err)
				return
			}
			sum += annual
			shares = append(shares, []string{u, reports.Money(annual), reports.Money(monthly)})
		}
		srows.Close()
		t, _ := decimal.NewFromString(total)
		facts := [][2]string{{"Dönem", strconv.Itoa(year)}, {"Durum", status}, {"Toplam", reports.Money(t.Mul(decimal.NewFromInt(100)).IntPart())}}
		if decision != nil && *decision != "" {
			facts = append(facts, [2]string{"Genel kurul kararı", *decision})
		}
		doc := &reports.Document{
			PropertyName: reports.PropertyName(ctx, pool, propertyID), Title: fmt.Sprintf("%d yılı işletme projesi", year),
			GeneratedAt: time.Now(), Facts: facts,
			Tables: []reports.Table{
				{Title: "Kalemler", Headers: []string{"Kalem", "Tür", "Dağıtım", "Tutar"}, Widths: []float64{80, 25, 30, 45}, RightAlign: []int{3}, Rows: items},
				{Title: "Bağımsız bölüm payları", Headers: []string{"Bölüm", "Yıllık pay", "Aylık pay"}, Widths: []float64{60, 60, 60},
					RightAlign: []int{1, 2}, Rows: shares, Footer: []string{"Toplam", reports.Money(sum), ""}},
			},
			Notes: []string{"KMK m.37 (7579 s. Kanunla değişik): işletme projesi kat malikleri kurulunda onaylanır; genel kurula kadar " +
				"yönetici tarafından bildirilen proje, yeniden değerleme oranı tavanı içinde geçici olarak uygulanır. " +
				"Kesinleşen projeye göre ödenmeyen avans için İİK m.68 kapsamında ilamsız takip yapılabilir."},
			SignatureLines: []string{"Yönetici", "Denetçi"},
		}
		govWriteReport(c, doc, fmt.Sprintf("isletme-projesi-%d", year))
	}
}
