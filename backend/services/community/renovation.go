package main

// Tadilat izni (FAZ 7.5, M-45, migration 037).
//
// Malik/vekil başvurur; yönetim kapsamın hukuki ön koşuluna göre onaylar:
//   - STRUCTURAL: yapı ruhsatı/izin no zorunlu (3194 s. İmar K. m.21; KMK m.19/2
//     anayapıya zarar veren değişiklik yasaktır).
//   - COMMON_AREA / FACADE: bütün kat maliklerinin 4/5 yazılı rızası (KMK m.19/2):
//     ya kayıtlı rızalar ya da bu nisapla kabul edilmiş genel kurul maddesi.
// Onayda sitenin tadilat saati izne kopyalanır; başvurana ve aynı bloktaki
// komşulara bildirim gider. Para cezası yoktur: idari yaptırım yetkisi kamu
// mercilerindedir (5326 s. Kabahatler K. m.22).

import (
	"errors"
	"fmt"
	"log"
	"math"
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/pkg/listcap"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/community/repository"
)

var renovationScopeLabels = map[string]string{
	"INTERIOR": "iç tadilat", "STRUCTURAL": "taşıyıcı sistem / esaslı tadilat",
	"COMMON_AREA": "ortak yerde değişiklik", "FACADE": "dış cephe değişikliği",
}

func registerRenovation(r *gin.Engine, pool *pgxpool.Pool, notifier *notify.Notifier) {
	repo := repository.NewRenovationRepository(pool)
	params := legalparams.New(pool)

	g := r.Group("/api/v1/renovations")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "renovation"))

	g.GET("", func(c *gin.Context) {
		owner := c.GetString("user_id")
		if isManagement(c) {
			owner = ""
		}
		list, err := repo.List(c.Request.Context(), c.GetString("property_id"), owner, listcap.Default)
		if err != nil {
			failRenovation(c, err, "listeleme")
			return
		}
		list, truncated := listcap.Trim(list, listcap.Default)
		c.JSON(http.StatusOK, gin.H{"data": list, "truncated": truncated, "limit": listcap.Default})
	})

	g.GET("/:id", func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		p, err := repo.Get(ctx, propertyID, c.Param("id"))
		if err != nil {
			failRenovation(c, err, "okuma")
			return
		}
		if !isManagement(c) && p.ApplicantID != c.GetString("user_id") {
			member, err := repo.IsUnitMember(ctx, propertyID, p.UnitID, c.GetString("user_id"))
			if err != nil {
				failRenovation(c, err, "okuma")
				return
			}
			if !member {
				// Var olduğunu da sızdırmaz.
				c.JSON(http.StatusNotFound, gin.H{"error": "Tadilat izni bulunamadı"})
				return
			}
		}
		consents, err := repo.Consents(ctx, propertyID, p.ID)
		if err != nil {
			failRenovation(c, err, "rıza listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"permit": p, "consents": consents})
	})

	g.POST("", func(c *gin.Context) {
		var in repository.CreateRenovationInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Scope = strings.ToUpper(strings.TrimSpace(in.Scope))
		in.Description = strings.TrimSpace(in.Description)
		in.ContractorName = strings.TrimSpace(in.ContractorName)
		in.ContractorPhone = strings.TrimSpace(in.ContractorPhone)
		if !slices.Contains(repository.RenovationScopes, in.Scope) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kapsam geçersiz", "valid": repository.RenovationScopes})
			return
		}
		if len([]rune(in.Description)) < 10 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yapılacak işi kısaca açıklayın (en az 10 karakter)"})
			return
		}
		start, err1 := time.ParseInLocation("2006-01-02", in.StartDate, time.Local)
		end, err2 := time.ParseInLocation("2006-01-02", in.EndDate, time.Local)
		if err1 != nil || err2 != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Başlangıç ve bitiş tarihi YYYY-AA-GG biçiminde zorunludur"})
			return
		}
		y, m, d := time.Now().Date()
		today := time.Date(y, m, d, 0, 0, 0, 0, time.Local)
		if start.Before(today) || end.Before(start) || end.Sub(start) > 365*24*time.Hour {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Başlangıç bugünden önce olamaz; bitiş başlangıçtan önce olamaz; süre en çok bir yıl"})
			return
		}
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		var ok bool
		var err error
		if isManagement(c) {
			ok, err = repo.UnitInSite(ctx, propertyID, in.UnitID)
		} else {
			ok, err = repo.IsUnitOwnerOrProxy(ctx, propertyID, in.UnitID, userID)
		}
		if err != nil {
			failRenovation(c, err, "başvuru yetkisi")
			return
		}
		if !ok {
			failRenovation(c, repository.ErrNotOwnerOfUnit, "başvuru yetkisi")
			return
		}
		p, err := repo.Create(ctx, propertyID, userID, in)
		if err != nil {
			failRenovation(c, err, "başvuru")
			return
		}
		res := notifyRenovation(c, notifier, pool, propertyID, nil, notify.Message{
			Topic:     "renovation.request",
			Subject:   "Yeni tadilat izni başvurusu",
			Body:      fmt.Sprintf("%s dairesi için %s başvurusu: %s – %s.", p.Unit, renovationScopeLabels[p.Scope], trDay(p.StartDate), trDay(p.EndDate)),
			Payload:   map[string]any{"renovation_id": p.ID},
			DedupeKey: "renovation.request:" + p.ID,
		})
		c.JSON(http.StatusCreated, gin.H{"permit": p, "notification": res, "requirement": renovationRequirement(p.Scope)})
	})

	g.POST("/:id/cancel", func(c *gin.Context) {
		p, err := repo.Cancel(c.Request.Context(), c.GetString("property_id"), c.Param("id"), c.GetString("user_id"))
		if err != nil {
			failRenovation(c, err, "geri çekme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"permit": p})
	})

	w := g.Group("")
	w.Use(middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember))

	w.POST("/:id/consents", func(c *gin.Context) {
		var in struct {
			OwnerUserID string `json:"owner_user_id"`
			ConsentedOn string `json:"consented_on"`
			DocumentRef string `json:"document_ref"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.OwnerUserID) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "owner_user_id zorunludur"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		if err := repo.AddConsent(ctx, propertyID, c.Param("id"), in.OwnerUserID, in.ConsentedOn,
			strings.TrimSpace(in.DocumentRef), c.GetString("user_id")); err != nil {
			failRenovation(c, err, "rıza kaydı")
			return
		}
		p, err := repo.Get(ctx, propertyID, c.Param("id"))
		if err != nil {
			failRenovation(c, err, "rıza kaydı")
			return
		}
		required, owners, err := consentRequirement(c, repo, params, propertyID)
		if err != nil {
			failRenovation(c, err, "rıza nisabı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"consent_count": p.ConsentCount, "consent_required": required, "owner_count": owners})
	})

	w.POST("/:id/approve", func(c *gin.Context) {
		var in repository.ApproveRenovationInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Conditions = strings.TrimSpace(in.Conditions)
		in.PermitRef = strings.TrimSpace(in.PermitRef)
		in.AgendaItemID = strings.TrimSpace(in.AgendaItemID)
		if in.DepositAmount < 0 || math.IsNaN(in.DepositAmount) || math.Round(in.DepositAmount*100) != in.DepositAmount*100 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Teminat sıfır ya da pozitif, en çok iki ondalıklı olmalı"})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		p, err := repo.Get(ctx, propertyID, c.Param("id"))
		if err != nil {
			failRenovation(c, err, "onay")
			return
		}
		if p.Status != "PENDING" {
			failRenovation(c, repository.ErrRenovationState, "onay")
			return
		}
		var required *int
		switch p.Scope {
		case "STRUCTURAL":
			if in.PermitRef == "" {
				c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Taşıyıcı sistemi etkileyen (esaslı) tadilat ruhsata tabidir (3194 s. İmar K. m.21): " +
					"yapı ruhsatı / belediye izni numarası zorunludur. Anayapıya zarar verecek değişiklik ruhsatla da yapılamaz (KMK m.19/2)."})
				return
			}
		case "COMMON_AREA", "FACADE":
			req, owners, err := consentRequirement(c, repo, params, propertyID)
			if err != nil {
				failRenovation(c, err, "rıza nisabı")
				return
			}
			required = &req
			if in.AgendaItemID != "" {
				ok, err := repo.AgendaAcceptedForConsent(ctx, propertyID, in.AgendaItemID)
				if err != nil && !isInvalidUUID(err) {
					failRenovation(c, err, "genel kurul kararı")
					return
				}
				if !ok {
					c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gündem maddesi bu sitenin yapılmış bir genel kurulunda " +
						"ortak yer değişikliği nisabıyla (MAJORITY_CONSTRUCTION_CONSENT, KMK m.19/2) kabul edilmiş değil"})
					return
				}
			} else if p.ConsentCount < req {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": fmt.Sprintf("Ortak yer ve dış cephe değişikliği bütün kat maliklerinin beşte dördünün yazılı rızasını ister (KMK m.19/2): "+
						"%d kat malikinden en az %d rıza gerekli, %d kayıtlı. Rızaları kaydedin ya da kabul edilmiş genel kurul maddesini gösterin.",
						owners, req, p.ConsentCount),
					"consent_count": p.ConsentCount, "consent_required": req, "owner_count": owners})
				return
			}
		}
		hours, err := repo.WorkHours(ctx, propertyID)
		if err != nil {
			failRenovation(c, err, "çalışma saatleri")
			return
		}
		p, err = repo.Approve(ctx, propertyID, p.ID, c.GetString("user_id"), hours, in, required, p.ConsentCount)
		if err != nil {
			failRenovation(c, err, "onay")
			return
		}
		body := fmt.Sprintf("%s dairesinin %s başvurusu onaylandı: %s – %s.", p.Unit, renovationScopeLabels[p.Scope], trDay(p.StartDate), trDay(p.EndDate))
		if p.WorkHours != "" {
			body += " Çalışma saatleri: " + p.WorkHours + "."
		}
		applicant := notifyRenovation(c, notifier, pool, propertyID, []notify.Recipient{{UserID: p.ApplicantID}}, notify.Message{
			Topic: "renovation.approved", Subject: "Tadilat izniniz onaylandı",
			Body:    body + conditionsText(p.Conditions, p.DepositAmount),
			Payload: map[string]any{"renovation_id": p.ID}, DedupeKey: "renovation.approved:" + p.ID,
		})
		// Komşu bilgilendirmesi: aynı bloğa, kişi adı OLMADAN (KVKK m.4 ölçülülük).
		var neighbors *notify.BroadcastResult
		if to, err := notify.BlockNeighbors(ctx, pool, propertyID, p.UnitID); err != nil {
			log.Printf("[community] tadilat komşu alıcıları: %v", err)
			neighbors = &notify.BroadcastResult{Note: "Komşu listesi okunamadı; komşulara bildirim oluşturulmadı."}
		} else if len(to) == 0 {
			neighbors = &notify.BroadcastResult{Note: "Aynı blokta bildirim alacak başka sakin yok."}
		} else {
			neighbors = notifyRenovation(c, notifier, pool, propertyID, to, notify.Message{
				Topic: "renovation.neighbors", Subject: "Bloğunuzda tadilat",
				Body:    fmt.Sprintf("%s dairesinde %s – %s tarihleri arasında tadilat yapılacak.", p.Unit, trDay(p.StartDate), trDay(p.EndDate)) + hoursText(p.WorkHours),
				Payload: map[string]any{"renovation_id": p.ID}, DedupeKey: "renovation.neighbors:" + p.ID,
			})
		}
		c.JSON(http.StatusOK, gin.H{"permit": p, "notification": applicant, "neighbors": neighbors})
	})

	w.POST("/:id/reject", func(c *gin.Context) {
		reason, ok := bindReason(c)
		if !ok {
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		p, err := repo.Reject(ctx, propertyID, c.Param("id"), c.GetString("user_id"), reason)
		if err != nil {
			failRenovation(c, err, "ret")
			return
		}
		res := notifyRenovation(c, notifier, pool, propertyID, []notify.Recipient{{UserID: p.ApplicantID}}, notify.Message{
			Topic: "renovation.rejected", Subject: "Tadilat izni başvurunuz reddedildi", Body: "Gerekçe: " + reason,
			Payload: map[string]any{"renovation_id": p.ID}, DedupeKey: "renovation.rejected:" + p.ID,
		})
		c.JSON(http.StatusOK, gin.H{"permit": p, "notification": res})
	})

	w.POST("/:id/stop", func(c *gin.Context) {
		reason, ok := bindReason(c)
		if !ok {
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		p, err := repo.Stop(ctx, propertyID, c.Param("id"), reason)
		if err != nil {
			failRenovation(c, err, "durdurma")
			return
		}
		res := notifyRenovation(c, notifier, pool, propertyID, []notify.Recipient{{UserID: p.ApplicantID}}, notify.Message{
			Topic: "renovation.stopped", Subject: "Tadilat çalışması durduruldu", Body: "Gerekçe: " + reason,
			Payload: map[string]any{"renovation_id": p.ID}, DedupeKey: "renovation.stopped:" + p.ID,
		})
		c.JSON(http.StatusOK, gin.H{"permit": p, "notification": res})
	})

	w.POST("/:id/complete", func(c *gin.Context) {
		var in struct {
			DepositRefunded *float64 `json:"deposit_refunded"`
			Note            string   `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Note = strings.TrimSpace(in.Note)
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		p, err := repo.Get(ctx, propertyID, c.Param("id"))
		if err != nil {
			failRenovation(c, err, "tamamlama")
			return
		}
		refunded := p.DepositAmount
		if in.DepositRefunded != nil {
			refunded = *in.DepositRefunded
		}
		if refunded < 0 || refunded > p.DepositAmount {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": fmt.Sprintf("İade tutarı 0 ile teminat (%.2f TL) arasında olmalı", p.DepositAmount)})
			return
		}
		if refunded < p.DepositAmount && in.Note == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Teminattan kesinti yapılıyorsa gerekçe (hasar tespiti) zorunludur"})
			return
		}
		p, err = repo.Complete(ctx, propertyID, p.ID, c.GetString("user_id"), refunded, in.Note)
		if err != nil {
			failRenovation(c, err, "tamamlama")
			return
		}
		body := "Tadilat denetimden geçti ve izin kapatıldı."
		if p.DepositAmount > 0 {
			body += fmt.Sprintf(" Teminat iadesi: %.2f TL / %.2f TL.", refunded, p.DepositAmount)
			if in.Note != "" {
				body += " Açıklama: " + in.Note
			}
		}
		res := notifyRenovation(c, notifier, pool, propertyID, []notify.Recipient{{UserID: p.ApplicantID}}, notify.Message{
			Topic: "renovation.completed", Subject: "Tadilat izni kapatıldı", Body: body,
			Payload: map[string]any{"renovation_id": p.ID}, DedupeKey: "renovation.completed:" + p.ID,
		})
		c.JSON(http.StatusOK, gin.H{"permit": p, "notification": res})
	})
}

// consentRequirement, KMK m.19/2 rıza sayısını hesaplar: ceil(malik × oran).
func consentRequirement(c *gin.Context, repo *repository.RenovationRepository, params *legalparams.Resolver, propertyID string) (int, int, error) {
	owners, err := repo.OwnerCount(c.Request.Context(), propertyID)
	if err != nil {
		return 0, 0, err
	}
	ratio, err := params.Decimal(c.Request.Context(), propertyID, legalparams.MajorityConstructionConsent, time.Now())
	if err != nil {
		return 0, 0, err
	}
	need := ratio.Mul(decimal.NewFromInt(int64(owners))).Ceil().IntPart()
	if need < 1 {
		need = 1
	}
	return int(need), owners, nil
}

func renovationRequirement(scope string) string {
	switch scope {
	case "STRUCTURAL":
		return "Onay için yapı ruhsatı / belediye izni gerekir (İmar K. m.21). Anayapıya zarar verecek değişiklik yapılamaz (KMK m.19/2)."
	case "COMMON_AREA", "FACADE":
		return "Onay için bütün kat maliklerinin beşte dördünün yazılı rızası ya da bu nisapla alınmış genel kurul kararı gerekir (KMK m.19/2)."
	default:
		return "Yönetim onayından sonra çalışmaya başlanabilir."
	}
}

func conditionsText(conditions string, deposit float64) string {
	s := ""
	if conditions != "" {
		s += " Koşullar: " + conditions + "."
	}
	if deposit > 0 {
		s += fmt.Sprintf(" Teminat: %.2f TL.", deposit)
	}
	return s
}

func hoursText(h string) string {
	if h == "" {
		return ""
	}
	return " Çalışma saatleri: " + h + "."
}

func trDay(t time.Time) string { return t.Format("02.01.2006") }

func bindReason(c *gin.Context) (string, bool) {
	var in struct {
		Reason string `json:"reason"`
	}
	_ = c.ShouldBindJSON(&in)
	in.Reason = strings.TrimSpace(in.Reason)
	if in.Reason == "" {
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gerekçe zorunludur"})
		return "", false
	}
	return in.Reason, true
}

func notifyRenovation(c *gin.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID string,
	to []notify.Recipient, m notify.Message) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	if to == nil {
		var err error
		if to, err = notify.Approvers(c.Request.Context(), pool, propertyID); err != nil {
			log.Printf("[community] tadilat bildirimi alıcıları: %v", err)
			return &notify.BroadcastResult{Note: "Alıcı listesi okunamadı; bildirim oluşturulmadı."}
		}
	}
	m.PropertyID = propertyID
	m.Channel = notify.ChannelInApp
	m.Category = notify.CategoryTransactional
	m.CreatedBy = c.GetString("user_id")
	return n.Broadcast(c.Request.Context(), m, to)
}

func failRenovation(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrRenovationNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Tadilat izni bulunamadı"})
	case errors.Is(err, repository.ErrRenovationState):
		c.JSON(http.StatusConflict, gin.H{"error": "Tadilat izni bu işlem için uygun durumda değil"})
	case errors.Is(err, repository.ErrConsentDuplicate):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu kat malikinin rızası zaten kayıtlı"})
	case errors.Is(err, repository.ErrNotOwnerOfUnit):
		c.JSON(http.StatusForbidden, gin.H{"error": "Başvuru yalnızca bölümün maliki ya da vekili tarafından yapılabilir"})
	case errors.Is(err, repository.ErrNotPropertyOwner), errors.Is(err, repository.ErrConsentNotApplicable):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[community] tadilat izni %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

func isInvalidUUID(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "22P02"
}
