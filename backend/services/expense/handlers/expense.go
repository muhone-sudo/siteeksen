// Package handlers, gider yönetiminin HTTP uçlarıdır.
package handlers

import (
	"errors"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/expense/models"
	"github.com/siteeksen/backend/services/expense/repository"
	"github.com/siteeksen/backend/services/expense/service"
)

// mapError, iş kuralı hatalarını HTTP durumlarına çevirir.
// Ham veritabanı hatası istemciye SIZDIRILMAZ; yalnızca loglanır.
func mapError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Gider kaydı bulunamadı"})
	case errors.Is(err, repository.ErrCategoryInvalid):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Gider kalemi bulunamadı veya bu siteye ait değil"})
	case errors.Is(err, repository.ErrNotPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu gider zaten sonuçlanmış"})
	case errors.Is(err, repository.ErrNoUnits):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sitede tanımlı bağımsız bölüm yok; gider paylaştırılamaz"})
	case errors.Is(err, service.ErrInvalidDate),
		errors.Is(err, service.ErrInvoiceReasonRequired),
		errors.Is(err, service.ErrUnknownDistribution):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		log.Printf("[expense] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

func ListCategories(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListCategories(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			mapError(c, err, "kalem listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func List(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		year, _ := strconv.Atoi(c.Query("year"))
		month, _ := strconv.Atoi(c.Query("month"))
		list, err := svc.List(c.Request.Context(), c.GetString("property_id"),
			year, month, c.Query("status"), c.Query("category_id"))
		if err != nil {
			mapError(c, err, "gider listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func Get(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		e, err := svc.Get(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "gider okuma")
			return
		}
		c.JSON(http.StatusOK, e)
	}
}

func Summary(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		year, _ := strconv.Atoi(c.Query("year"))
		month, _ := strconv.Atoi(c.Query("month"))
		s, err := svc.Summary(c.Request.Context(), c.GetString("property_id"), year, month)
		if err != nil {
			mapError(c, err, "gider özeti")
			return
		}
		c.JSON(http.StatusOK, s)
	}
}

func Create(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateExpenseInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		e, err := svc.Create(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			mapError(c, err, "gider oluşturma")
			return
		}

		resp := gin.H{"expense": e}
		if e.Status == models.StatusPending {
			resp["note"] = "Faturasız gider onay bekliyor. Yönetim kurulu onayı olmadan " +
				"hesap verme belgelerine dahil edilmemelidir (KMK m.39)."
		}
		c.JSON(http.StatusCreated, resp)
	}
}

func Approve(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		err := svc.Approve(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"))
		if err != nil {
			mapError(c, err, "gider onaylama")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Gider onaylandı"})
	}
}

func Reject(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ret gerekçesi zorunludur"})
			return
		}
		err := svc.Reject(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), in.Reason)
		if err != nil {
			mapError(c, err, "gider reddetme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Gider reddedildi"})
	}
}
