package handlers

// Dairenin maliki ve oturanı için sakin işlemleri (beşinci tur B5; altıncı tur D3'te davete geçti).
//   GET  /users/me/units/:id/residents                  — malik ya da kiracı (telefon maskeli)
//   POST /users/me/units/:id/invitations                {first_name, last_name, phone, email?, role}
//        malik: TENANT | PROXY | (oturuyorsa) HOUSEHOLD · kiracı: HOUSEHOLD
//   POST /users/me/units/:id/residents/:residentId/end  — malik vekili, oturan hane üyesini çıkarır;
//        kiracılık bu yoldan bitmez (409)
// Yönetim daveti: POST /residents/invitations {…, unit_id, role}.

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/identity/models"
	"github.com/siteeksen/backend/services/identity/service"
)

func ownerError(c *gin.Context, err error, fallback string) {
	switch {
	case errors.Is(err, service.ErrNotUnitMember):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, service.ErrInviteRole):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	case errors.Is(err, service.ErrTenancyEndNeedsConsent):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	default:
		mapResidentError(c, err, fallback)
	}
}

// OwnerUnitResidents: dairenin sakinleri (malik ya da kiracı).
func OwnerUnitResidents(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.UnitResidents(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"))
		if err != nil {
			ownerError(c, err, "Daire sakinleri alınamadı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// bindInvitation, davet gövdesini okur ve telefonu girişle aynı biçime getirir.
func bindInvitation(c *gin.Context, needUnit bool) (models.CreateResidentInput, bool) {
	var body struct {
		FirstName string `json:"first_name"`
		LastName  string `json:"last_name"`
		Phone     string `json:"phone" binding:"required"`
		Email     string `json:"email"`
		UnitID    string `json:"unit_id"`
		Role      string `json:"role" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || (needUnit && strings.TrimSpace(body.UnitID) == "") {
		msg := "phone ve role zorunludur (hesabı olmayan kişi için first_name ve last_name de)"
		if needUnit {
			msg = "unit_id, phone ve role zorunludur (hesabı olmayan kişi için first_name ve last_name de)"
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": msg})
		return models.CreateResidentInput{}, false
	}
	in := models.CreateResidentInput{FirstName: strings.TrimSpace(body.FirstName), LastName: strings.TrimSpace(body.LastName),
		Phone: normalizePhone(body.Phone), Email: strings.TrimSpace(body.Email), UnitID: strings.TrimSpace(body.UnitID),
		Role: strings.ToUpper(strings.TrimSpace(body.Role))}
	if in.Phone == "" {
		errInvalidPhone(c)
		return in, false
	}
	return in, true
}

// deliverInvitation, daveti kişiye iletir: hesabı yeni açıldıysa etkinleştirme kodu, varsa davet bildirimi
// (SMS + e-posta). Sonuç yanıtta dürüstçe döner; hiçbir kanal yoksa bu söylenir.
func deliverInvitation(ctx context.Context, out *service.InvitationOutcome) {
	inv := out.Invitation
	what := "daire davetiniz var"
	if inv != nil {
		what = out.PropertyName + " sitesi " + inv.Unit + " dairesi için " + roleTR(inv.Role) + " olarak davet edildiniz"
	}
	if out.Code != nil {
		out.Delivery = gin.H{
			"sms":   sendInvitationActivationSMS(ctx, out.Phone, what, out.Code),
			"email": sendInvitationActivationEmail(ctx, out.Email, what, out.Code),
		}
		return
	}
	out.Delivery = gin.H{
		"sms":   sendInvitationNotice(ctx, out.Phone, "", what),
		"email": sendInvitationNotice(ctx, "", out.Email, what),
	}
}

func roleTR(role string) string {
	switch role {
	case "OWNER":
		return "kat maliki"
	case "TENANT":
		return "kiracı"
	case "PROXY":
		return "vekil"
	case "HOUSEHOLD":
		return "hane üyesi"
	}
	return role
}

// OwnerInvite: dairenin maliki ya da kiracısı davet gönderir.
func OwnerInvite(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		in, ok := bindInvitation(c, false)
		if !ok {
			return
		}
		out, err := svc.UnitInvite(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), in)
		if err != nil {
			ownerError(c, err, "Davet gönderilemedi")
			return
		}
		deliverInvitation(c.Request.Context(), out)
		c.JSON(http.StatusCreated, out)
	}
}

// ManagementInvite: yönetimin daire daveti.
func ManagementInvite(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		in, ok := bindInvitation(c, true)
		if !ok {
			return
		}
		out, err := svc.Invite(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), getRoles(c), in)
		if err != nil {
			mapResidentError(c, err, "Davet gönderilemedi")
			return
		}
		deliverInvitation(c.Request.Context(), out)
		c.JSON(http.StatusCreated, out)
	}
}

// OwnerEndResident: malik vekilliği, oturan hane üyeliğini bitirir.
func OwnerEndResident(svc *service.ResidentService) gin.HandlerFunc {
	return func(c *gin.Context) {
		res, err := svc.UnitEndResident(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), c.Param("id"), c.Param("residentId"))
		if err != nil {
			ownerError(c, err, "Sakinlik bitirilemedi")
			return
		}
		c.JSON(http.StatusOK, gin.H{"resident": res,
			"message": "Kayıt bitirildi; kişi bu daire için bildirim almaz. Geçmiş kayıtlar silinmez."})
	}
}
