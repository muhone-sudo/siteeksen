package handlers

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
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

func mapResidentError(c *gin.Context, err error, fallback string) {
	switch {
	case errors.Is(err, service.ErrResidentForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
	case errors.Is(err, service.ErrInvalidResidentRole):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "Sakinlik rolü OWNER, TENANT ya da PROXY olmalı; yönetim rolleri görevlendirmeyle verilir"})
	case errors.Is(err, repository.ErrResidentNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Sakin bulunamadı"})
	case errors.Is(err, repository.ErrUnitNotFound):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belirtilen birim bu siteye ait değil"})
	case errors.Is(err, repository.ErrPhoneAlreadyExists):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu telefon numarası başka bir kullanıcıya ait"})
	case errors.Is(err, repository.ErrInvitationPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu kişiye bu daire ve rol için yanıt bekleyen bir davet zaten var"})
	case errors.Is(err, repository.ErrInvitationNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Davet bulunamadı"})
	case errors.Is(err, repository.ErrInvitationNotPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Davet artık yanıtlanamaz: yanıtlanmış, iptal edilmiş ya da süresi dolmuş"})
	default:
		// Aynı daireye aynı kişinin ikinci kaydı (benzersizlik) ve biçimi bozuk
		// kimlik gibi istemci hataları 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[identity] sakin işlemi başarısız: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": fallback})
	}
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
