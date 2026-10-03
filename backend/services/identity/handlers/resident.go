package handlers

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/repository"
	"github.com/siteeksen/backend/services/identity/service"
)

func getRoles(c *gin.Context) []string {
	value, exists := c.Get("roles")
	if !exists {
		return nil
	}
	roles, _ := value.([]string)
	return roles
}

// residentError, bilinen hata için HTTP durumunu ve kullanıcıya gösterilecek
// mesajı döner (toplu içe aktarmada satır sonucu olarak da kullanılır).
func residentError(err error) (int, string, bool) {
	switch {
	case errors.Is(err, service.ErrResidentForbidden):
		return http.StatusForbidden, "Bu işlem için yetkiniz yok", true
	case errors.Is(err, service.ErrInvalidResidentRole):
		return http.StatusUnprocessableEntity, "Sakinlik rolü OWNER, TENANT ya da PROXY olmalı; yönetim rolleri görevlendirmeyle verilir", true
	case errors.Is(err, repository.ErrResidentNotFound):
		return http.StatusNotFound, "Sakin bulunamadı", true
	case errors.Is(err, repository.ErrUnitNotFound):
		return http.StatusBadRequest, "Belirtilen birim bu siteye ait değil", true
	case errors.Is(err, repository.ErrPhoneAlreadyExists):
		return http.StatusConflict, "Bu telefon numarası başka bir kullanıcıya ait", true
	case errors.Is(err, service.ErrInvalidRoleInput):
		return http.StatusUnprocessableEntity, err.Error(), true
	case errors.Is(err, repository.ErrRoleExists), errors.Is(err, repository.ErrRoleNotActive),
		errors.Is(err, repository.ErrLastManager):
		return http.StatusConflict, err.Error(), true
	case errors.Is(err, repository.ErrUserOtherSite):
		return http.StatusConflict, "Bu telefon numarası bu siteyle bağı olmayan bir hesaba ait; kişi önce sakin olarak davet edilmeli (kişisel veri gösterilmez)", true
	case errors.Is(err, repository.ErrNameRequiredNew):
		return http.StatusUnprocessableEntity, err.Error(), true
	case errors.Is(err, repository.ErrRoleNotFound):
		return http.StatusNotFound, "Görevlendirme bulunamadı", true
	case errors.Is(err, service.ErrInvalidUnit):
		// Mesaj bizim yazdığımız doğrulama metnidir (satır numarasıyla).
		return http.StatusUnprocessableEntity, err.Error(), true
	case errors.Is(err, repository.ErrUnitExists):
		return http.StatusConflict, err.Error(), true
	case errors.Is(err, repository.ErrInvitationPending):
		return http.StatusConflict, "Bu kişiye bu daire ve rol için yanıt bekleyen bir davet zaten var", true
	case errors.Is(err, repository.ErrInvitationNotFound):
		return http.StatusNotFound, "Davet bulunamadı", true
	case errors.Is(err, repository.ErrInvitationNotPending):
		return http.StatusConflict, "Davet artık yanıtlanamaz: yanıtlanmış, iptal edilmiş ya da süresi dolmuş", true
	}
	return 0, "", false
}

func mapResidentError(c *gin.Context, err error, fallback string) {
	if status, msg, ok := residentError(err); ok {
		c.JSON(status, gin.H{"error": msg})
		return
	}
	// Aynı daireye aynı kişinin ikinci kaydı (benzersizlik) ve biçimi bozuk
	// kimlik gibi istemci hataları 500 değildir.
	if middleware.DBErrorResponse(c, err) {
		return
	}
	log.Printf("[identity] sakin işlemi başarısız: %v", err)
	c.JSON(http.StatusInternalServerError, gin.H{"error": fallback})
}

// ListResidents bir sitedeki sakinleri arama/blok/rol filtreleriyle listeler
func ListResidents(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		residents, err := svc.List(c.Request.Context(), propertyID, getRoles(c),
			c.Query("search"), c.Query("block"), c.Query("role"))
		if err != nil {
			mapResidentError(c, err, "Sakinler alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": residents})
	}
}

// GetResident sakin detayını döner
func GetResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		resident, err := svc.Get(c.Request.Context(), propertyID, c.Param("id"), getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Sakin alınamadı")
			return
		}
		c.JSON(http.StatusOK, resident)
	}
}

// CreateResident yeni sakin kaydı oluşturur
func CreateResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.CreateResidentInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		// Telefon, girişle AYNI biçimde saklanır. Önceden "0555…" olduğu gibi
		// yazılıyor, giriş ise "+90555…" arıyordu: sakin giriş yapamıyordu.
		input.Phone = normalizePhone(input.Phone)
		propertyID := c.GetString("property_id")
		result, err := svc.Create(c.Request.Context(), propertyID, c.GetString("user_id"), getRoles(c), input)
		if err != nil {
			mapResidentError(c, err, "Sakin oluşturulamadı")
			return
		}
		if result.Invitation != nil {
			// Bağ kurulmadı; davet açıldı (S-20). 202: istek kabul edildi, sonuç kişinin yanıtına bağlı.
			c.JSON(http.StatusAccepted, result)
			return
		}
		c.JSON(http.StatusCreated, result)
	}
}

// UpdateResident sakinin rol/aktiflik bilgisini günceller
func UpdateResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.UpdateResidentInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		propertyID := c.GetString("property_id")
		resident, err := svc.Update(c.Request.Context(), propertyID, c.Param("id"), getRoles(c), input)
		if err != nil {
			mapResidentError(c, err, "Sakin güncellenemedi")
			return
		}
		c.JSON(http.StatusOK, resident)
	}
}

// ListUnits bir sitedeki birimleri listeler
func ListUnits(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		units, err := svc.ListUnits(c.Request.Context(), propertyID, getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Birimler alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": units})
	}
}

// IssueActivationCode, sakin için yeni etkinleştirme / şifre sıfırlama kodu üretir.
func IssueActivationCode(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		act, err := svc.IssueActivationCode(c.Request.Context(), c.GetString("property_id"),
			c.GetString("user_id"), getRoles(c), c.Param("id"))
		if err != nil {
			mapResidentError(c, err, "Kod üretilemedi")
			return
		}
		c.JSON(http.StatusCreated, act)
	}
}

// ListInvitations sitenin sakin davetlerini listeler (yönetim).
func ListInvitations(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListInvitations(c.Request.Context(), c.GetString("property_id"), getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Davetler alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// CancelInvitation bekleyen daveti iptal eder (yönetim).
func CancelInvitation(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		inv, err := svc.CancelInvitation(c.Request.Context(), c.GetString("property_id"), c.Param("id"), getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Davet iptal edilemedi")
			return
		}
		c.JSON(http.StatusOK, inv)
	}
}

// MyInvitations çağıranın yanıt bekleyen davetlerini listeler.
func MyInvitations(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.MyInvitations(c.Request.Context(), c.GetString("user_id"))
		if err != nil {
			mapResidentError(c, err, "Davetler alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// RespondInvitation çağıranın davete kabul/ret yanıtını işler.
func RespondInvitation(svc *service.ResidentService, accept bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID, err := svc.RespondInvitation(c.Request.Context(), c.GetString("user_id"), c.Param("id"), accept)
		if err != nil {
			mapResidentError(c, err, "Davet yanıtlanamadı")
			return
		}
		msg := "Davet reddedildi; daireye bağlanmadınız"
		if accept {
			msg = "Davet kabul edildi; site, site seçiminizde görünür"
		}
		c.JSON(http.StatusOK, gin.H{"property_id": propertyID, "accepted": accept, "message": msg})
	}
}

// CreateUnits bağımsız bölüm ekler. Gövde tek bölüm nesnesi ya da
// {"units": [...]} (toplu, site kurulumu) olabilir; hepsi tek işlemde eklenir.
func CreateUnits(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var raw map[string]json.RawMessage
		body, err := c.GetRawData()
		if err == nil {
			err = json.Unmarshal(body, &raw)
		}
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		var in []models.UnitInput
		if list, ok := raw["units"]; ok {
			err = json.Unmarshal(list, &in)
		} else {
			var one models.UnitInput
			err = json.Unmarshal(body, &one)
			in = []models.UnitInput{one}
		}
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		units, err := svc.CreateUnits(c.Request.Context(), c.GetString("property_id"), getRoles(c), in)
		if err != nil {
			mapResidentError(c, err, "Bölümler eklenemedi")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": units, "created": len(units)})
	}
}

// UpdateUnit bölümü günceller.
func UpdateUnit(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.UnitInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		u, err := svc.UpdateUnit(c.Request.Context(), c.GetString("property_id"), c.Param("id"), getRoles(c), in)
		if err != nil {
			mapResidentError(c, err, "Bölüm güncellenemedi")
			return
		}
		c.JSON(http.StatusOK, u)
	}
}

// ListSiteRoles sitenin görevlendirmelerini listeler.
func ListSiteRoles(svc *service.RoleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.List(c.Request.Context(), c.GetString("property_id"), getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Görevlendirmeler alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// GrantSiteRole görev verir (yalnızca yönetici).
func GrantSiteRole(svc *service.RoleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.GrantRoleInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "phone ve role zorunlu"})
			return
		}
		in.Phone = normalizePhone(in.Phone)
		res, err := svc.Grant(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), getRoles(c), in)
		if err != nil {
			mapResidentError(c, err, "Görev verilemedi")
			return
		}
		c.JSON(http.StatusCreated, res)
	}
}

// EndSiteRole görevi sonlandırır (yalnızca yönetici).
func EndSiteRole(svc *service.RoleService) gin.HandlerFunc {
	return func(c *gin.Context) {
		sr, err := svc.End(c.Request.Context(), c.GetString("property_id"), c.Param("id"), getRoles(c))
		if err != nil {
			mapResidentError(c, err, "Görev sonlandırılamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"role": sr, "note": "Kişinin açık oturumları kapatıldı; yeniden girişte yetkisi olmaz."})
	}
}

// BulkResidentRow, toplu içe aktarmada bir satırın sonucudur.
type BulkResidentRow struct {
	Row          int                `json:"row"`
	Status       string             `json:"status"` // created, linked, invited, error
	Phone        string             `json:"phone"`
	ResidentID   string             `json:"resident_id,omitempty"`
	InvitationID string             `json:"invitation_id,omitempty"`
	Activation   *models.Activation `json:"activation,omitempty"`
	Error        string             `json:"error,omitempty"`
}

// BulkCreateResidents, sakinleri toplu ekler (site kurulumu / rakipten geçiş).
//
// Satırlar BİRBİRİNDEN BAĞIMSIZ işlenir ve her birinin sonucu döner: hesap açıldı
// (etkinleştirme kodu bir kez döner), var olan hesap bağlandı, başka sitede
// kayıtlı kişiye davet gönderildi ya da hata (nedeniyle). Tek işlem yapılmaz:
// başka sitede kayıtlı tek bir kişi yüzünden yüz satırlık listenin reddedilmesi
// kullanıcının işine yaramazdı. Hiçbir satır sessizce atlanmaz.
func BulkCreateResidents(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Residents []models.CreateResidentInput `json:"residents"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || len(in.Residents) == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "residents listesi gerekli"})
			return
		}
		if len(in.Residents) > 500 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "tek seferde en çok 500 sakin eklenebilir"})
			return
		}
		propertyID, actor, roles := c.GetString("property_id"), c.GetString("user_id"), getRoles(c)
		out := make([]BulkResidentRow, 0, len(in.Residents))
		counts := map[string]int{}
		for i, r := range in.Residents {
			row := BulkResidentRow{Row: i + 1, Phone: normalizePhone(r.Phone)}
			r.Phone = row.Phone
			switch {
			case strings.TrimSpace(r.FirstName) == "" || strings.TrimSpace(r.LastName) == "" || row.Phone == "" || r.UnitID == "":
				row.Status, row.Error = "error", "ad, soyad, telefon ve daire zorunlu"
			default:
				res, err := svc.Create(c.Request.Context(), propertyID, actor, roles, r)
				switch {
				case errors.Is(err, service.ErrResidentForbidden):
					c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
					return
				case err != nil:
					row.Status = "error"
					if _, msg, ok := residentError(err); ok {
						row.Error = msg
					} else if pgErr := (*pgconn.PgError)(nil); errors.As(err, &pgErr) && pgErr.Code == "23505" {
						row.Error = "bu kişi bu dairede bu sıfatla zaten kayıtlı"
					} else {
						log.Printf("[identity] toplu sakin satırı %d: %v", i+1, err)
						row.Error = "kaydedilemedi"
					}
				case res.Invitation != nil:
					row.Status, row.InvitationID = "invited", res.Invitation.ID
				case res.Activation != nil:
					row.Status, row.Activation = "created", res.Activation
					row.ResidentID = res.Resident.ID
				default:
					row.Status = "linked"
					row.ResidentID = res.Resident.ID
				}
			}
			counts[row.Status]++
			out = append(out, row)
		}
		c.JSON(http.StatusOK, gin.H{"data": out, "summary": counts,
			"note": "Etkinleştirme kodları yalnızca bu yanıtta görünür; sakinlere iletin."})
	}
}
