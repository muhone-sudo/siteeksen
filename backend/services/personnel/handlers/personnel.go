// Package handlers, personel yönetiminin HTTP uçlarıdır.
package handlers

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/audit"
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
			middleware.RoleAuditor:
			return true
		}
	}
	return false
}

// wantsReveal, istemcinin TCKN/IBAN'ı MASKESİZ istediğini söyler.
//
// Varsayılan MASKELİDİR. Yönetici bu veriye SGK ve bordro işlemleri için
// gerçekten ihtiyaç duyar, ama HER ekranda değil: KVKK m.4, verinin işlendiği
// amaçla "bağlantılı, sınırlı ve ölçülü" olmasını ister.
//
// Maskesiz istek `?reveal=true` ile yapılır ve audit_logs'a yolu ve sorgusuyla
// birlikte yazılır; böylece kimin ne zaman tam veriyi gördüğü kayıtlıdır
// (KVKK m.12). Yetki hâlâ şarttır: reveal, yetkisi olmayana veri açmaz.
func wantsReveal(c *gin.Context) bool {
	return c.Query("reveal") == "true" && isManager(c)
}

// isManager, TCKN/IBAN'ın MASKESİZ görülebileceği rolleri belirler.
func isManager(c *gin.Context) bool {
	value, _ := c.Get("roles")
	roles, _ := value.([]string)
	for _, r := range roles {
		if r == middleware.RoleManager {
			return true
		}
	}
	return false
}

func mapError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrInvalidTCKN):
		// Şifreli bir alandaki yazım hatası sonradan gözle bulunamaz; bu yüzden
		// TCKN kaydedilmeden önce algoritmik olarak doğrulanır.
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "T.C. kimlik numarası geçersiz",
			"note": "Numara algoritmik doğrulamadan geçmedi. Şifreli bir alandaki " +
				"yazım hatası sonradan gözle bulunamaz; bu yüzden kayıt kabul edilmiyor."})
	case errors.Is(err, repository.ErrInvalidIBAN):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error": "IBAN geçersiz",
			"note": "IBAN, ISO 13616 mod-97 doğrulamasından geçmedi. Yanlış IBAN, " +
				"maaşın başkasının hesabına gitmesi demektir."})
	case errors.Is(err, repository.ErrDuplicateTC):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Bu T.C. kimlik numarasıyla aktif bir personel kaydı zaten var",
			"note":  "Aynı kişinin iki kez kaydedilip iki maaş alması engellenir."})
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Personel kaydı bulunamadı"})
	case errors.Is(err, repository.ErrLeaveInvalid):
		c.JSON(http.StatusNotFound, gin.H{"error": "İzin kaydı bulunamadı"})
	case errors.Is(err, repository.ErrNotPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu izin talebi zaten sonuçlanmış"})
	case errors.Is(err, repository.ErrOverlapping):
		c.JSON(http.StatusConflict, gin.H{
			"error": "Bu tarihlerde personelin çakışan bir izni var"})
	case errors.Is(err, service.ErrInvalidEnum):
		c.JSON(http.StatusUnprocessableEntity, gin.H{
			"error":          "Sözleşme ya da izin türü geçersiz",
			"contract_types": service.ContractTypes,
			"leave_types":    service.LeaveTypes})
	case errors.Is(err, service.ErrInvalidDate),
		errors.Is(err, service.ErrDateOrder),
		errors.Is(err, service.ErrReasonRequired):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
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

func GetEmployee(svc *service.Service, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		e, err := svc.GetEmployee(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), canSeeSalary(c), wantsReveal(c))
		if err != nil {
			mapError(c, err, "personel okuma")
			return
		}

		// Maskesiz görüntüleme AYRI bir denetim kaydı üretir. Genel istek kaydı
		// "bu kaydı okudu" der; hangi isteğin TAM TCKN/IBAN gördüğünü söylemez.
		// KVKK m.12, hassas veriye erişimin kanıtlanabilir olmasını gerektirir.
		if wantsReveal(c) {
			if aerr := audit.Log(c.Request.Context(), pool, audit.Entry{
				UserID:     c.GetString("user_id"),
				PropertyID: c.GetString("property_id"),
				IPAddress:  c.ClientIP(),
				UserAgent:  c.Request.UserAgent(),
				Action:     "PII_REVEAL",
				EntityType: "employee",
				EntityID:   c.Param("id"),
				StatusCode: http.StatusOK,
				NewValues:  map[string]any{"fields": []string{"tc_number", "bank_iban"}},
			}); aerr != nil {
				// Kayıt tutulamıyorsa veri AÇILMAZ: izi tutulamayan bir erişim,
				// sonradan hesabı verilemeyecek bir erişimdir.
				log.Printf("[personnel] maskesiz erişim kaydı yazılamadı: %v", aerr)
				c.JSON(http.StatusInternalServerError, gin.H{
					"error": "Erişim kaydı tutulamadığı için maskesiz veri açılamadı",
				})
				return
			}
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
