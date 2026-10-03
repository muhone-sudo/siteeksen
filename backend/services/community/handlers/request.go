package handlers

import (
	"errors"
	"github.com/siteeksen/backend/pkg/middleware"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/community/models"
	"github.com/siteeksen/backend/services/community/repository"
	"github.com/siteeksen/backend/services/community/service"
)

func getRoles(c *gin.Context) []string {
	value, exists := c.Get("roles")
	if !exists {
		return nil
	}
	roles, _ := value.([]string)
	return roles
}

// ListRequests rol bazlı talep listesi (yönetim: site geneli, sakin: kendi talepleri)
func ListRequests(svc *service.RequestService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")
		status := c.Query("status")

		requests, err := svc.List(c.Request.Context(), userID, propertyID, getRoles(c), status)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Talepler alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": requests})
	}
}

// CreateRequest sakin yeni talep oluşturur
func CreateRequest(svc *service.RequestService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.CreateRequestInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")

		req, err := svc.Create(c.Request.Context(), userID, propertyID, input)
		if err != nil {
			if errors.Is(err, repository.ErrUnitNotYours) {
				c.JSON(http.StatusUnprocessableEntity, gin.H{
					"error": "Belirtilen daire bu sitedeki aktif daireleriniz arasında değil"})
				return
			}
			if middleware.DBErrorResponse(c, err) {
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Talep oluşturulamadı"})
			return
		}
		c.JSON(http.StatusCreated, req)
	}
}

// UpdateRequestStatus yönetici talep durumunu ilerletir (OPEN -> IN_PROGRESS -> RESOLVED)
func UpdateRequestStatus(svc *service.RequestService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.UpdateStatusInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		req, err := svc.UpdateStatus(c.Request.Context(), c.GetString("property_id"), c.Param("id"), getRoles(c), input.Status)
		switch {
		case errors.Is(err, service.ErrForbidden):
			c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
		case errors.Is(err, service.ErrInvalidTransition):
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz durum geçişi"})
		case errors.Is(err, repository.ErrStatusChanged):
			c.JSON(http.StatusConflict, gin.H{"error": "Talebin durumu bu sırada değişti; yenileyip tekrar deneyin"})
		case errors.Is(err, repository.ErrRequestNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "Talep bulunamadı"})
		case err != nil:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Talep güncellenemedi"})
		default:
			c.JSON(http.StatusOK, req)
		}
	}
}

// ConfirmRequestResolution sakin "sorunum çözüldü" onayını/reddini kaydeder
func ConfirmRequestResolution(svc *service.RequestService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.ConfirmResolutionInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		userID := c.GetString("user_id")
		req, err := svc.ConfirmResolution(c.Request.Context(), c.GetString("property_id"), c.Param("id"), userID, input.Approved)
		switch {
		case errors.Is(err, service.ErrForbidden):
			c.JSON(http.StatusForbidden, gin.H{"error": "Bu talep size ait değil"})
		case errors.Is(err, service.ErrInvalidTransition):
			c.JSON(http.StatusBadRequest, gin.H{"error": "Talep onay bekleyen durumda değil"})
		case errors.Is(err, repository.ErrStatusChanged):
			c.JSON(http.StatusConflict, gin.H{"error": "Talebin durumu bu sırada değişti; yenileyip tekrar deneyin"})
		case errors.Is(err, repository.ErrRequestNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "Talep bulunamadı"})
		case err != nil:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Onay kaydedilemedi"})
		default:
			c.JSON(http.StatusOK, req)
		}
	}
}
