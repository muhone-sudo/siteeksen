// Package handlers, personel yönetiminin HTTP uçlarıdır.
package handlers

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/services/personnel/models"
	"github.com/siteeksen/backend/services/personnel/repository"
	"github.com/siteeksen/backend/services/personnel/service"
)

// canSeeSalary, maaş/IBAN/SGK gibi alanları görebilecek rolleri belirler.
//
// STAFF (görevli personel) personel listesini görebilir (vardiya, iletişim) ama
// maaş bilgisini GÖREMEZ. Denetçi ise mali denetim görevi (KMK m.41) gereği görür.
func canSeeSalary(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		switch r {
		case middleware.RoleManager, middleware.RoleBoardMember,
			middleware.RoleAuditor, middleware.RoleSuperAdmin:
			return true
		}
	}
	return false
}

// isManager, TCKN/IBAN'ın MASKESİZ görülebileceği rolleri belirler.
func isManager(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager || r == middleware.RoleSuperAdmin {
			return true
		}
	}
	return false
}

func mapError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Personel kaydı bulunamadı"})
	case errors.Is(err, repository.ErrNotPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu izin talebi zaten sonuçlanmış"})
	case errors.Is(err, repository.ErrOverlapping):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Bu tarihlerde personelin çakışan bir izni var"})
	case errors.Is(err, service.ErrInvalidDate),
		errors.Is(err, service.ErrDateOrder),
		errors.Is(err, service.ErrReasonRequired):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		log.Printf("[personnel] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

func ListEmployees(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		activeOnly := c.Query("all") != "true"
		list, err := svc.ListEmployees(c.Request.Context(), c.GetString("property_id"),
			activeOnly, canSeeSalary(c))
		if err != nil {
			mapError(c, err, "personel listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func GetEmployee(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		e, err := svc.GetEmployee(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), canSeeSalary(c), isManager(c))
		if err != nil {
			mapError(c, err, "personel okuma")
			return
		}
		c.JSON(http.StatusOK, e)
	}
}

func CreateEmployee(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateEmployeeInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		e, err := svc.CreateEmployee(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			mapError(c, err, "personel oluşturma")
			return
		}
		c.JSON(http.StatusCreated, e)
	}
}

func TerminateEmployee(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason  string `json:"reason" binding:"required"`
			EndDate string `json:"end_date"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ayrılış gerekçesi zorunludur"})
			return
		}
		if err := svc.Terminate(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), in.Reason, in.EndDate); err != nil {
			mapError(c, err, "işten ayrılış")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"message": "Personel pasife alındı",
			"note":    "Özlük kaydı silinmez; İş Kanunu ve SGK mevzuatı gereği saklanır.",
		})
	}
}

func Summary(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		s, err := svc.Summary(c.Request.Context(), c.GetString("property_id"), canSeeSalary(c))
		if err != nil {
			mapError(c, err, "personel özeti")
			return
		}
		c.JSON(http.StatusOK, s)
	}
}

func ListLeaves(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListLeaves(c.Request.Context(), c.GetString("property_id"), c.Query("status"))
		if err != nil {
			mapError(c, err, "izin listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func CreateLeave(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateLeaveInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		id, err := svc.CreateLeave(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			mapError(c, err, "izin talebi")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"id": id, "status": "PENDING"})
	}
}

func ApproveLeave(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := svc.ApproveLeave(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id")); err != nil {
			mapError(c, err, "izin onaylama")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "İzin onaylandı"})
	}
}

func RejectLeave(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Reason string `json:"reason" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ret gerekçesi zorunludur"})
			return
		}
		if err := svc.RejectLeave(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), c.GetString("user_id"), in.Reason); err != nil {
			mapError(c, err, "izin reddetme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "İzin reddedildi"})
	}
}
