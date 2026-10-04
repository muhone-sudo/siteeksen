package main

// Kural ihlali (FAZ 7.5, M-44, migration 039).
//
// Kural kataloğu yönetim planına atıflıdır (KMK m.28). Sakin ya da yönetim
// ihlal bildirir; yönetim doğrular ya da gerekçeyle reddeder, ardından kademeli
// süreç işler: sözlü uyarı → yazılı uyarı → ihtar → hukuki yol (KMK m.33 sulh
// hukuk mahkemesi; hâkim kararına rağmen bir yıl ısrar m.25/b çekilmezlik).
// Dairenin sakinleri savunma yazabilir. Uyarılar dairenin BÜTÜN aktif
// sakinlerine gider: kiracı malikle müteselsil sorumludur (m.18/2).
// Para cezası YOKTUR (5326 s. Kabahatler K. m.22). Bildirenin kimliği
// ihlal edilen daireye gösterilmez.

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/listcap"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/community/repository"
)

var stageLabels = map[string]string{
	"VERBAL_WARNING": "sözlü uyarı", "WRITTEN_WARNING": "yazılı uyarı",
	"FORMAL_NOTICE": "ihtar", "LEGAL": "hukuki yola başvuru",
}

// stageNotice, kademe bildiriminin metnidir.
func stageNotice(stage, rule, planRef, note string) string {
	s := fmt.Sprintf("Dairenizle ilgili \"%s\" kuralının (%s) ihlali nedeniyle %s yapıldı.", rule, planRef, stageLabels[stage])
	if note != "" {
		s += " Açıklama: " + note
	}
	switch stage {
	case "FORMAL_NOTICE":
		s += " İhlalin sürmesi hâlinde yönetim, sulh hukuk mahkemesinden hâkimin müdahalesini isteyebilir (KMK m.33)."
	case "LEGAL":
		s += " Yönetim, sulh hukuk mahkemesine başvurmaya karar verdi (KMK m.33)."
	}
	return s + " Savunmanızı uygulamadan iletebilirsiniz."
}

func registerViolations(r *gin.Engine, pool *pgxpool.Pool, notifier *notify.Notifier) {
	repo := repository.NewViolationRepository(pool)

	rules := r.Group("/api/v1/site-rules")
	rules.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "site_rule"))
	rules.GET("", func(c *gin.Context) {
		list, err := repo.ListRules(c.Request.Context(), c.GetString("property_id"), !isManagement(c))
		if err != nil {
			failViolation(c, err, "kural listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})
	rw := rules.Group("")
	rw.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))
	rw.POST("", func(c *gin.Context) {
		var in repository.SiteRule
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Category = strings.ToUpper(strings.TrimSpace(in.Category))
		if in.Category == "" {
			in.Category = "OTHER"
		}
		in.Title, in.Description = strings.TrimSpace(in.Title), strings.TrimSpace(in.Description)
		in.ManagementPlanRef = strings.TrimSpace(in.ManagementPlanRef)
		if !slices.Contains(repository.RuleCategories, in.Category) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kategori geçersiz", "valid": repository.RuleCategories})
			return
		}
		if in.Title == "" || in.ManagementPlanRef == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kural başlığı ve yönetim planındaki dayanağı (madde) zorunludur: " +
				"yönetim planında karşılığı olmayan kural kat maliklerini bağlamaz (KMK m.28)"})
			return
		}
		s, err := repo.CreateRule(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			failViolation(c, err, "kural ekleme")
			return
		}
		c.JSON(http.StatusCreated, s)
	})
	rw.POST("/:id/deactivate", func(c *gin.Context) {
		if err := repo.DeactivateRule(c.Request.Context(), c.GetString("property_id"), c.Param("id")); err != nil {
			failViolation(c, err, "kural pasifleştirme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Kural pasifleştirildi; geçmiş kayıtlar korunur"})
	})

	g := r.Group("/api/v1/violations")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "violation"))

	g.GET("", func(c *gin.Context) {
		mgmt := isManagement(c)
		owner := c.GetString("user_id")
		if mgmt {
			owner = ""
		}
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"), owner, listcap.Default)
		if err != nil {
			failViolation(c, err, "listeleme")
			return
		}
		list, truncated := listcap.Trim(list, listcap.Default)
		for _, v := range list {
			redactViolation(v, mgmt, c.GetString("user_id"))
		}
		c.JSON(http.StatusOK, gin.H{"data": list, "truncated": truncated, "limit": listcap.Default})
	})

	g.GET("/:id", func(c *gin.Context) {
		v, ok := loadVisibleViolation(c, repo)
		if !ok {
			return
		}
		c.JSON(http.StatusOK, v)
	})

	g.POST("", func(c *gin.Context) {
		var in struct {
			RuleID      string `json:"rule_id"`
			UnitID      string `json:"unit_id"`
			Description string `json:"description"`
			OccurredAt  string `json:"occurred_at"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Description = strings.TrimSpace(in.Description)
		if strings.TrimSpace(in.RuleID) == "" || strings.TrimSpace(in.UnitID) == "" || len([]rune(in.Description)) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kural, daire ve en az 10 karakterlik açıklama zorunludur"})
			return
		}
		var occurred *time.Time
		if in.OccurredAt != "" {
			t, err := time.Parse(time.RFC3339, in.OccurredAt)
			if err != nil || t.After(time.Now().Add(5*time.Minute)) {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Olay zamanı RFC3339 biçiminde olmalı ve gelecekte olamaz"})
				return
			}
			occurred = &t
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		v, err := repo.Create(ctx, propertyID, c.GetString("user_id"), in.RuleID, in.UnitID, in.Description, occurred)
		if err != nil {
			failViolation(c, err, "bildirim")
			return
		}
		res := notifyViolation(c, notifier, pool, propertyID, nil, notify.Message{
			Topic: "violation.reported", Subject: "Yeni kural ihlali bildirimi",
			Body:    fmt.Sprintf("%s dairesi için \"%s\" kuralı ihlali bildirildi.", v.Unit, v.RuleTitle),
			Payload: map[string]any{"violation_id": v.ID}, DedupeKey: "violation.reported:" + v.ID,
		})
		redactViolation(v, isManagement(c), c.GetString("user_id"))
		c.JSON(http.StatusCreated, gin.H{"violation": v, "notification": res,
			"note": "Bildiriminiz yönetime iletildi. Kimliğiniz ihlal bildirilen daireye gösterilmez."})
	})

	// Savunma: yalnızca dairenin aktif sakini, kayıt kapanmadan.
	g.POST("/:id/respond", func(c *gin.Context) {
		note, ok := bindViolationNote(c, true)
		if !ok {
			return
		}
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		cur, err := repo.Get(ctx, propertyID, c.Param("id"))
		if err != nil {
			failViolation(c, err, "savunma")
			return
		}
		member, err := repo.IsUnitMember(ctx, propertyID, cur.UnitID, userID)
		if err != nil {
			failViolation(c, err, "savunma")
			return
		}
		if !member {
			c.JSON(http.StatusForbidden, gin.H{"error": "Savunmayı yalnızca ihlal bildirilen dairenin sakini yazabilir"})
			return
		}
		v, err := repo.Transition(ctx, propertyID, cur.ID, []string{"OPEN", "VERIFIED"}, "", "", "RESPONSE", note, userID, false)
		if err != nil {
			failViolation(c, err, "savunma")
			return
		}
		res := notifyViolation(c, notifier, pool, propertyID, nil, notify.Message{
			Topic: "violation.response", Subject: "İhlal kaydına savunma yazıldı",
			Body:    fmt.Sprintf("%s dairesi \"%s\" kaydına savunma yazdı.", v.Unit, v.RuleTitle),
			Payload: map[string]any{"violation_id": v.ID}, DedupeKey: fmt.Sprintf("violation.response:%s:%d", v.ID, len(v.Events)),
		})
		redactViolation(v, false, userID)
		c.JSON(http.StatusCreated, gin.H{"violation": v, "notification": res})
	})

	w := g.Group("")
	w.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))

	w.POST("/:id/verify", func(c *gin.Context) {
		note, _ := bindViolationNote(c, false)
		v, err := repo.Transition(c.Request.Context(), c.GetString("property_id"), c.Param("id"),
			[]string{"OPEN"}, "VERIFIED", "", "VERIFIED", note, c.GetString("user_id"), false)
		if err != nil {
			failViolation(c, err, "doğrulama")
			return
		}
		c.JSON(http.StatusOK, gin.H{"violation": v})
	})

	w.POST("/:id/dismiss", func(c *gin.Context) {
		note, ok := bindViolationNote(c, true)
		if !ok {
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		v, err := repo.Transition(ctx, propertyID, c.Param("id"), []string{"OPEN", "VERIFIED"}, "DISMISSED", "", "DISMISSED", note, c.GetString("user_id"), false)
		if err != nil {
			failViolation(c, err, "ret")
			return
		}
		res := notifyViolation(c, notifier, pool, propertyID, []notify.Recipient{{UserID: v.ReportedBy}}, notify.Message{
			Topic: "violation.dismissed", Subject: "İhlal bildiriminiz sonuçlandı",
			Body:    fmt.Sprintf("\"%s\" bildiriminiz doğrulanmadı. Gerekçe: %s", v.RuleTitle, note),
			Payload: map[string]any{"violation_id": v.ID}, DedupeKey: "violation.dismissed:" + v.ID,
		})
		c.JSON(http.StatusOK, gin.H{"violation": v, "notification": res})
	})

	w.POST("/:id/escalate", func(c *gin.Context) {
		var in struct {
			Stage string `json:"stage"`
			Note  string `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Stage = strings.ToUpper(strings.TrimSpace(in.Stage))
		in.Note = strings.TrimSpace(in.Note)
		if _, ok := stageLabels[in.Stage]; !ok {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kademe geçersiz", "valid": repository.ViolationStages[1:]})
			return
		}
		if in.Stage != "VERBAL_WARNING" && in.Note == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yazılı uyarı, ihtar ve hukuki yol için açıklama zorunludur"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		v, err := repo.Transition(ctx, propertyID, c.Param("id"), []string{"VERIFIED"}, "", in.Stage, in.Stage, in.Note, c.GetString("user_id"), true)
		if err != nil {
			if errors.Is(err, repository.ErrViolationState) {
				c.JSON(http.StatusConflict, gin.H{"error": "Kademe yalnızca doğrulanmış kayıtta ve ileri yönde değiştirilebilir " +
					"(sözlü uyarı → yazılı uyarı → ihtar → hukuki yol)"})
				return
			}
			failViolation(c, err, "kademe")
			return
		}
		to, err := notify.UnitResidents(ctx, pool, propertyID, v.UnitID)
		var res *notify.BroadcastResult
		if err != nil {
			log.Printf("[community] ihlal alıcıları: %v", err)
			res = &notify.BroadcastResult{Note: "Daire sakinleri okunamadı; bildirim oluşturulmadı."}
		} else {
			res = notifyViolation(c, notifier, pool, propertyID, to, notify.Message{
				Topic: "violation." + strings.ToLower(in.Stage), Subject: "Kural ihlali: " + stageLabels[in.Stage],
				Body:    stageNotice(in.Stage, v.RuleTitle, v.PlanRef, in.Note),
				Payload: map[string]any{"violation_id": v.ID, "stage": in.Stage}, DedupeKey: "violation." + in.Stage + ":" + v.ID,
			})
		}
		c.JSON(http.StatusOK, gin.H{"violation": v, "notification": res})
	})

	w.POST("/:id/resolve", func(c *gin.Context) {
		note, ok := bindViolationNote(c, true)
		if !ok {
			return
		}
		v, err := repo.Transition(c.Request.Context(), c.GetString("property_id"), c.Param("id"),
			[]string{"VERIFIED"}, "RESOLVED", "", "RESOLVED", note, c.GetString("user_id"), false)
		if err != nil {
			failViolation(c, err, "kapatma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"violation": v})
	})
}

// loadVisibleViolation: yönetim her kaydı; sakin kendi bildirdiğini ya da
// dairesine ait olanı görür (diğerleri 404 — varlığı da sızdırılmaz).
func loadVisibleViolation(c *gin.Context, repo *repository.ViolationRepository) (*repository.Violation, bool) {
	ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
	v, err := repo.Get(ctx, propertyID, c.Param("id"))
	if err != nil {
		failViolation(c, err, "okuma")
		return nil, false
	}
	mgmt := isManagement(c)
	if !mgmt && v.ReportedBy != userID {
		member, err := repo.IsUnitMember(ctx, propertyID, v.UnitID, userID)
		if err != nil {
			failViolation(c, err, "okuma")
			return nil, false
		}
		if !member {
			c.JSON(http.StatusNotFound, gin.H{"error": "İhlal kaydı bulunamadı"})
			return nil, false
		}
	}
	redactViolation(v, mgmt, userID)
	return v, true
}

// redactViolation: bildirenin kimliği ve olaylardaki kişi adları yalnızca
// yönetime görünür; bildiren kendi bildirimini görür ama olay yürütenlerin
// adlarını görmez.
func redactViolation(v *repository.Violation, mgmt bool, userID string) {
	if mgmt {
		return
	}
	if v.ReportedBy != userID {
		v.ReportedBy, v.ReporterName = "", ""
	}
	for i := range v.Events {
		if v.Events[i].ActorID != userID {
			v.Events[i].ActorID, v.Events[i].ActorName = "", ""
		}
	}
}

func bindViolationNote(c *gin.Context, required bool) (string, bool) {
	var in struct {
		Note string `json:"note"`
	}
	_ = c.ShouldBindJSON(&in)
	in.Note = strings.TrimSpace(in.Note)
	if required && in.Note == "" {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Açıklama zorunludur"})
		return "", false
	}
	return in.Note, true
}

func notifyViolation(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID string,
	to []notify.Recipient, m notify.Message) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	if to == nil {
		var err error
		if to, err = notify.Approvers(c.Request.Context(), pool, propertyID); err != nil {
			log.Printf("[community] ihlal bildirimi alıcıları: %v", err)
			return &notify.BroadcastResult{Note: "Alıcı listesi okunamadı; bildirim oluşturulmadı."}
		}
	}
	m.PropertyID = propertyID
	m.Channel = notify.ChannelInApp
	m.Category = notify.CategoryTransactional
	m.CreatedBy = c.GetString("user_id")
	return n.Broadcast(c.Request.Context(), m, to)
}

func failViolation(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrViolationNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "İhlal kaydı bulunamadı"})
	case errors.Is(err, repository.ErrRuleNotFound):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kural bulunamadı ya da etkin değil"})
	case errors.Is(err, repository.ErrUnitNotFound):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bağımsız bölüm bu sitede bulunamadı"})
	case errors.Is(err, repository.ErrViolationState):
		c.JSON(http.StatusConflict, gin.H{"error": "İhlal kaydı bu işlem için uygun durumda değil"})
	default:
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[community] kural ihlali %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
