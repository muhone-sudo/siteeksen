package main

// Acil durum ve afet (FAZ 7.3, M-37, migration 040).
//
//   - Bilgi kartı (toplanma alanı, vanalar, pano, acil telefonlar): bütün site
//     üyelerine açık; mobil uygulama çevrimdışı kullanım için saklar.
//   - Tatbikat kaydı: tarih, eksiklikler, düzeltici faaliyet (İşyerlerinde Acil
//     Durumlar Hk. Yönetmelik m.13). Yıllık süre aşımı zamanlayıcıyla hatırlatılır.
//   - Sakin acil bilgi kartı: özel nitelikli veri (KVKK m.6). Açık rıza zorunlu,
//     pkg/pii ile şifreli; yalnızca yönetici/kurul görür ve her görüntüleme ayrı
//     denetim kaydı üretir; sakin kartını silince veri silinir (m.7).
//   - Durum bildirimi: afet sonrası "güvendeyim / yardım gerekiyor"; yanıt
//     vermeyen bölümler yönetime listelenir.

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
	"github.com/siteeksen/backend/pkg/audit"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/pkg/pii"
	"github.com/siteeksen/backend/services/community/repository"
)

// emergencyConsentVersion, sakin acil kartı aydınlatma/açık rıza metninin sürümüdür.
const emergencyConsentVersion = "2026-10-04"

// emergencyConsentText, karta yazmadan önce sakine gösterilen metindir (KVKK m.6/3-a, m.10).
const emergencyConsentText = "Acil durumda tahliye ve kurtarma için yardım ihtiyacımı (hareket kısıtı, sağlık durumu vb.) " +
	"site yönetimiyle paylaşıyorum. Bilgi şifreli saklanır, yalnızca yönetici ve yönetim kurulu acil durum amacıyla görür, " +
	"her görüntüleme kayda geçer. Rızamı kartı silerek dilediğim an geri alabilirim; bu durumda bilgi silinir."

func registerEmergency(r *gin.Engine, pool *pgxpool.Pool, notifier *notify.Notifier) {
	repo := repository.NewEmergencyRepository(pool)
	vault, verr := pii.FromEnv()
	if verr != nil {
		// Servis açılır ama özel nitelikli veri ŞİFRESİZ yazılmaz: kart uçları 503 döner.
		log.Printf("[community] acil bilgi kartı devre dışı: şifreleme anahtarı yok (%v)", verr)
		vault = nil
	}
	mgmt := []string{middleware.RoleManager, middleware.RoleBoardMember}

	g := r.Group("/api/v1/emergency")
	g.Use(middleware.AuthMiddleware(pool), middleware.AuditLog(pool, "emergency"))

	g.GET("/info", func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		points, err := repo.Points(ctx, propertyID)
		if err != nil {
			failEmergency(c, err, "bilgi kartı")
			return
		}
		contacts, err := repo.Contacts(ctx, propertyID)
		if err != nil {
			failEmergency(c, err, "bilgi kartı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"points": points, "contacts": contacts, "national_emergency": "112",
			"note": "Her türlü acil durumda 112'yi arayın. Bu kart çevrimdışı kullanım için cihazınızda saklanır."})
	})

	w := g.Group("")
	w.Use(middleware.RequireRole(mgmt...))
	w.POST("/points", func(c *gin.Context) {
		var in repository.EmergencyPoint
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Kind = strings.ToUpper(strings.TrimSpace(in.Kind))
		in.Name, in.Location, in.Note = strings.TrimSpace(in.Name), strings.TrimSpace(in.Location), strings.TrimSpace(in.Note)
		if !slices.Contains(repository.EmergencyPointKinds, in.Kind) || in.Name == "" || in.Location == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tür, ad ve konum zorunludur", "valid": repository.EmergencyPointKinds})
			return
		}
		p, err := repo.AddPoint(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			failEmergency(c, err, "nokta ekleme")
			return
		}
		c.JSON(http.StatusCreated, p)
	})
	w.DELETE("/points/:id", func(c *gin.Context) {
		if err := repo.DeleteRow(c.Request.Context(), c.GetString("property_id"), "emergency_points", c.Param("id")); err != nil {
			failEmergency(c, err, "nokta silme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Silindi"})
	})
	w.POST("/contacts", func(c *gin.Context) {
		var in repository.EmergencyContact
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Category = strings.ToUpper(strings.TrimSpace(in.Category))
		in.Name, in.Phone, in.Note = strings.TrimSpace(in.Name), strings.TrimSpace(in.Phone), strings.TrimSpace(in.Note)
		if !slices.Contains(repository.EmergencyContactCats, in.Category) || in.Name == "" || len(in.Phone) < 3 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Kategori, ad ve telefon zorunludur", "valid": repository.EmergencyContactCats})
			return
		}
		ct, err := repo.AddContact(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			failEmergency(c, err, "kişi ekleme")
			return
		}
		c.JSON(http.StatusCreated, ct)
	})
	w.DELETE("/contacts/:id", func(c *gin.Context) {
		if err := repo.DeleteRow(c.Request.Context(), c.GetString("property_id"), "emergency_contacts", c.Param("id")); err != nil {
			failEmergency(c, err, "kişi silme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Silindi"})
	})

	// Tatbikat: denetçi okur (KMK m.41), yazma yönetimde.
	g.GET("/drills", middleware.RequireRole(middleware.RoleManager, middleware.RoleBoardMember, middleware.RoleAuditor), func(c *gin.Context) {
		list, err := repo.Drills(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			failEmergency(c, err, "tatbikat listesi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})
	w.POST("/drills", func(c *gin.Context) {
		var in struct {
			Kind              string `json:"kind"`
			DrillDate         string `json:"drill_date"`
			Participants      *int   `json:"participants"`
			Findings          string `json:"findings"`
			CorrectiveActions string `json:"corrective_actions"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Kind = strings.ToUpper(strings.TrimSpace(in.Kind))
		d, err := time.ParseInLocation("2006-01-02", in.DrillDate, time.Local)
		if err != nil || d.After(time.Now()) || !slices.Contains(repository.DrillKinds, in.Kind) ||
			(in.Participants != nil && *in.Participants < 0) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tür ve geçmiş/bugün tarihli tatbikat tarihi zorunludur", "valid": repository.DrillKinds})
			return
		}
		if strings.TrimSpace(in.Findings) == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tatbikat raporunda görülen eksiklikler yazılmalıdır " +
				"(yoksa 'eksiklik görülmedi' yazın) — İşyerlerinde Acil Durumlar Hk. Yönetmelik m.13"})
			return
		}
		out, err := repo.AddDrill(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), repository.Drill{
			Kind: in.Kind, DrillDate: d, Participants: in.Participants,
			Findings: strings.TrimSpace(in.Findings), CorrectiveActions: strings.TrimSpace(in.CorrectiveActions)})
		if err != nil {
			failEmergency(c, err, "tatbikat kaydı")
			return
		}
		c.JSON(http.StatusCreated, out)
	})

	// --- Sakin acil bilgi kartı (özel nitelikli veri) ---
	needVault := func(c *gin.Context) bool {
		if vault == nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Şifreleme anahtarı yapılandırılmamış; özel nitelikli veri kaydedilmez ve gösterilmez (KVKK m.6/4)"})
			return false
		}
		return true
	}
	decrypt := func(cards []*repository.EmergencyCard) error {
		for _, card := range cards {
			plain, err := vault.Decrypt(card.Cipher())
			if err != nil {
				return err
			}
			card.Needs = plain
		}
		return nil
	}

	g.GET("/cards/me", func(c *gin.Context) {
		if !needVault(c) {
			return
		}
		cards, err := repo.Cards(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"))
		if err == nil {
			err = decrypt(cards)
		}
		if err != nil {
			failEmergency(c, err, "kart okuma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": cards, "consent_text": emergencyConsentText, "consent_version": emergencyConsentVersion})
	})

	g.PUT("/cards/me", func(c *gin.Context) {
		if !needVault(c) {
			return
		}
		var in struct {
			UnitID         string `json:"unit_id"`
			Needs          string `json:"needs"`
			HouseholdCount *int   `json:"household_count"`
			ContactName    string `json:"contact_name"`
			ContactPhone   string `json:"contact_phone"`
			Consent        bool   `json:"consent"`
			ConsentVersion string `json:"consent_version"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if !in.Consent || in.ConsentVersion != emergencyConsentVersion {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Sağlık ve yardım ihtiyacı bilgisi özel nitelikli kişisel veridir; " +
				"güncel metne açık rıza verilmeden kaydedilmez (KVKK m.6/3-a)", "consent_text": emergencyConsentText, "consent_version": emergencyConsentVersion})
			return
		}
		in.Needs = strings.TrimSpace(in.Needs)
		if in.Needs == "" || len([]rune(in.Needs)) > 1000 || (in.HouseholdCount != nil && (*in.HouseholdCount < 1 || *in.HouseholdCount > 50)) {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Yardım ihtiyacı (en çok 1000 karakter) zorunlu; hane kişi sayısı 1-50"})
			return
		}
		cipher, err := vault.Encrypt(in.Needs)
		if err != nil {
			failEmergency(c, err, "şifreleme")
			return
		}
		if err := repo.UpsertCard(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in.UnitID, cipher,
			in.HouseholdCount, strings.TrimSpace(in.ContactName), strings.TrimSpace(in.ContactPhone), in.ConsentVersion); err != nil {
			failEmergency(c, err, "kart kaydı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Acil bilgi kartınız kaydedildi; yalnızca yönetici ve yönetim kurulu acil durum amacıyla görebilir."})
	})

	g.DELETE("/cards/me", func(c *gin.Context) {
		if err := repo.DeleteCard(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Query("unit_id")); err != nil {
			failEmergency(c, err, "kart silme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Kartınız ve rızanız silindi (KVKK m.7)."})
	})

	w.GET("/cards", func(c *gin.Context) {
		if !needVault(c) {
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		cards, err := repo.Cards(ctx, propertyID, "")
		if err == nil {
			err = decrypt(cards)
		}
		if err != nil {
			failEmergency(c, err, "kart listesi")
			return
		}
		// Özel nitelikli verinin her görüntülenmesi AYRI denetim kaydıdır (KVKK m.12).
		if aerr := audit.Log(ctx, pool, audit.Entry{
			UserID: c.GetString("user_id"), PropertyID: propertyID, IPAddress: c.ClientIP(), UserAgent: c.Request.UserAgent(),
			Action: "SENSITIVE_REVEAL", EntityType: "resident_emergency_card", StatusCode: http.StatusOK,
			NewValues: map[string]any{"count": len(cards), "purpose": "acil durum"},
		}); aerr != nil {
			log.Printf("[community] acil kart erişim kaydı yazılamadı: %v", aerr)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Erişim kaydı yazılamadığı için özel nitelikli veri gösterilmedi"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": cards, "note": "Bu görüntüleme denetim kaydına yazıldı. Bilgi yalnızca acil durum amacıyla kullanılabilir."})
	})

	// --- Afet sonrası durum bildirimi ---
	g.GET("/checks", func(c *gin.Context) {
		list, err := repo.Checks(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"))
		if err != nil {
			failEmergency(c, err, "durum çağrıları")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	})

	w.POST("/checks", func(c *gin.Context) {
		var in struct {
			Kind  string `json:"kind"`
			Title string `json:"title"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Kind = strings.ToUpper(strings.TrimSpace(in.Kind))
		in.Title = strings.TrimSpace(in.Title)
		if !slices.Contains(repository.DrillKinds, in.Kind) || in.Title == "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Tür ve başlık zorunludur", "valid": repository.DrillKinds})
			return
		}
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		id, err := repo.OpenCheck(ctx, propertyID, c.GetString("user_id"), in.Kind, in.Title)
		if err != nil {
			failEmergency(c, err, "durum çağrısı")
			return
		}
		var res *notify.BroadcastResult
		if to, err := notify.Residents(ctx, pool, propertyID); err != nil {
			log.Printf("[community] durum çağrısı alıcıları: %v", err)
			res = &notify.BroadcastResult{Note: "Sakin listesi okunamadı; bildirim oluşturulmadı. Çağrı açık."}
		} else {
			res = notifyEmergency(c, notifier, propertyID, to, notify.Message{
				Topic: "safety.check", Subject: in.Title,
				Body:    "Lütfen uygulamadan durumunuzu bildirin: Güvendeyim / Yardım gerekiyor. Hayati tehlikede 112'yi arayın.",
				Payload: map[string]any{"safety_check_id": id}, DedupeKey: "safety.check:" + id,
			})
		}
		s, err := repo.GetCheck(ctx, propertyID, id, "")
		if err != nil {
			failEmergency(c, err, "durum çağrısı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"check": s, "notification": res})
	})

	g.POST("/checks/:id/respond", func(c *gin.Context) {
		var in struct {
			Status string `json:"status"`
			Note   string `json:"note"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		in.Status = strings.ToUpper(strings.TrimSpace(in.Status))
		if in.Status != "SAFE" && in.Status != "NEED_HELP" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Durum SAFE ya da NEED_HELP olmalı"})
			return
		}
		ctx, propertyID, userID := c.Request.Context(), c.GetString("property_id"), c.GetString("user_id")
		if err := repo.Respond(ctx, propertyID, c.Param("id"), userID, in.Status, strings.TrimSpace(in.Note)); err != nil {
			failEmergency(c, err, "durum yanıtı")
			return
		}
		resp := gin.H{"message": "Durumunuz yönetime iletildi"}
		if in.Status == "NEED_HELP" {
			if to, err := notify.Approvers(ctx, pool, propertyID); err == nil {
				resp["notification"] = notifyEmergency(c, notifier, propertyID, to, notify.Message{
					Topic: "safety.need_help", Subject: "YARDIM GEREKİYOR",
					Body:      fmt.Sprintf("Bir sakin yardım istedi. %s", strings.TrimSpace(in.Note)),
					Payload:   map[string]any{"safety_check_id": c.Param("id"), "user_id": userID},
					DedupeKey: fmt.Sprintf("safety.need_help:%s:%s:%d", c.Param("id"), userID, time.Now().Unix()/60),
				})
			} else {
				log.Printf("[community] yardım bildirimi alıcıları: %v", err)
				resp["warning"] = "Yönetime bildirim oluşturulamadı; hayati tehlikede 112'yi arayın."
			}
			resp["message"] = "Yardım talebiniz yönetime iletildi. Hayati tehlikede 112'yi arayın."
		}
		c.JSON(http.StatusOK, resp)
	})

	w.GET("/checks/:id/responses", func(c *gin.Context) {
		ctx, propertyID := c.Request.Context(), c.GetString("property_id")
		s, err := repo.GetCheck(ctx, propertyID, c.Param("id"), "")
		if err != nil {
			failEmergency(c, err, "durum yanıtları")
			return
		}
		list, err := repo.Responses(ctx, propertyID, s.ID)
		if err != nil {
			failEmergency(c, err, "durum yanıtları")
			return
		}
		silent, err := repo.SilentUnits(ctx, propertyID, s.ID)
		if err != nil {
			failEmergency(c, err, "durum yanıtları")
			return
		}
		c.JSON(http.StatusOK, gin.H{"check": s, "data": list, "silent_units": silent})
	})

	w.POST("/checks/:id/close", func(c *gin.Context) {
		if err := repo.CloseCheck(c.Request.Context(), c.GetString("property_id"), c.Param("id")); err != nil {
			failEmergency(c, err, "durum çağrısı kapatma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Durum bildirimi çağrısı kapatıldı"})
	})
}

func notifyEmergency(c *gin.Context, n *notify.Notifier, propertyID string, to []notify.Recipient, m notify.Message) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; bildirim oluşturulmadı."}
	}
	m.PropertyID = propertyID
	m.Channel = notify.ChannelInApp
	m.Category = notify.CategoryTransactional
	m.CreatedBy = c.GetString("user_id")
	return n.Broadcast(c.Request.Context(), m, to)
}

func failEmergency(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrEmergencyNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrSafetyCheckOpen):
		c.JSON(http.StatusConflict, gin.H{"error": "Zaten açık bir durum bildirimi çağrısı var"})
	case errors.Is(err, repository.ErrSafetyCheckClosed):
		c.JSON(http.StatusConflict, gin.H{"error": "Durum bildirimi çağrısı kapalı"})
	case errors.Is(err, repository.ErrUnitNotFound):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bu bölümün aktif sakini değilsiniz"})
	default:
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[community] acil durum %s: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}
