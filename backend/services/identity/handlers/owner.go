package handlers

// Malikin kendi bölümündeki kiracı/vekil yönetimi (beşinci tur B5).
//   GET  /users/me/units/:id/residents
//   POST /users/me/units/:id/residents          {first_name, last_name, phone, email?, role: TENANT|PROXY}
//   POST /users/me/units/:id/residents/:residentId/end

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/service"
)

func ownerError(c *gin.Context, err error, fallback string) {
	switch {
	case errors.Is(err, service.ErrNotUnitOwner):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, service.ErrOwnerRole):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		mapResidentError(c, err, fallback)
	}
}

// OwnerUnitResidents: bölümün sakinleri (malik).
func OwnerUnitResidents(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.OwnerUnitResidents(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"))
		if err != nil {
			ownerError(c, err, "Bölüm sakinleri alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// OwnerAddResident: malik kiracı/vekil ekler.
func OwnerAddResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Bölüm URL'den gelir; gövdede unit_id istenmez.
		var body struct {
			FirstName string `json:"first_name" binding:"required"`
			LastName  string `json:"last_name" binding:"required"`
			Phone     string `json:"phone" binding:"required"`
			Email     string `json:"email"`
			Role      string `json:"role" binding:"required"`
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "first_name, last_name, phone ve role (TENANT|PROXY) zorunludur"})
			return
		}
		input := models.CreateResidentInput{FirstName: strings.TrimSpace(body.FirstName), LastName: strings.TrimSpace(body.LastName),
			Phone: body.Phone, Email: strings.TrimSpace(body.Email), Role: body.Role}
		if input.Phone = normalizePhone(input.Phone); input.Phone == "" {
			errInvalidPhone(c)
			return
		}
		input.Role = strings.ToUpper(strings.TrimSpace(input.Role))
		result, err := svc.OwnerAddResident(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), input)
		if err != nil {
			ownerError(c, err, "Sakin eklenemedi")
			return
		}
		if result.Activation != nil {
			result.Activation.SMS = sendActivationSMS(c.Request.Context(), input.Phone, result.Activation)
			if e := sendActivationEmail(c.Request.Context(), strings.TrimSpace(input.Email), result.Activation); e != nil {
				result.Activation.Email = e
			}
		}
		if result.Invitation != nil {
			c.JSON(http.StatusAccepted, result)
			return
		}
		c.JSON(http.StatusCreated, result)
	}
}

// OwnerEndResident: malik kiracılığı/vekilliği bitirir.
func OwnerEndResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		res, err := svc.OwnerEndResident(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), c.Param("residentId"))
		if err != nil {
			ownerError(c, err, "Sakinlik bitirilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"resident": res,
			"message": "Sakinlik bitirildi; kişi bu bölüm için bildirim almaz ve yeni borçlar ona yansımaz. Geçmiş kayıtlar silinmez."})
	}
}
