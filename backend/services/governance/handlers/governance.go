// Package handlers, yönetişim modülünün HTTP uçlarıdır.
package handlers

import (
	"errors"
	"github.com/siteeksen/backend/pkg/middleware"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/pkg/legalparams"
	"github.com/siteeksen/backend/services/governance/models"
	"github.com/siteeksen/backend/services/governance/repository"
	"github.com/siteeksen/backend/services/governance/service"
)

// mapError, iş kuralı hatalarını HTTP durumlarına çevirir.
// Ham veritabanı hatası istemciye SIZDIRILMAZ; yalnızca loglanır.
func mapError(c *gin.Context, err error, op string) {
	var verr *service.ValidationError
	switch {
	// Yoldaki bozuk kimlik middleware.UUIDParams ile 404 döner; buraya ulaşan
	// 22P02 GÖVDEDEKİ bir alandır ve istemci hatasıdır (400, default dalında).
	case errors.Is(err, repository.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Kayıt bulunamadı"})
	case errors.Is(err, repository.ErrNoUnits):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sitede tanımlı bağımsız bölüm yok"})
	case errors.Is(err, repository.ErrBudgetExists):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu dönem için zaten bir işletme projesi var"})
	case errors.Is(err, repository.ErrBudgetNotDraft):
		c.JSON(http.StatusConflict, gin.H{"error": "Yalnızca taslak durumundaki proje tebliğ edilebilir"})
	case errors.Is(err, repository.ErrBudgetNotNotified):
		c.JSON(http.StatusConflict, gin.H{"error": "Kesinleştirmeden önce proje tebliğ edilmelidir (KMK m.37)"})
	case errors.Is(err, repository.ErrObjectionPeriodOpen):
		c.JSON(http.StatusConflict, gin.H{"error": "İtiraz süresi dolmadan proje kesinleşemez (KMK m.37/2)"})
	case errors.Is(err, repository.ErrOpenObjections):
		c.JSON(http.StatusConflict, gin.H{"error": "Açık itirazlar çözülmeden proje kesinleşemez"})
	case errors.Is(err, repository.ErrAssemblyNotOpen):
		c.JSON(http.StatusConflict, gin.H{"error": "Toplantı bu işlem için uygun durumda değil"})
	case errors.Is(err, repository.ErrNotAttending):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Oy kullanan bağımsız bölüm hazirun listesinde yok"})
	case errors.Is(err, repository.ErrAlreadyDecided):
		c.JSON(http.StatusConflict, gin.H{"error": "Kayıt zaten sonuçlanmış"})
	case errors.Is(err, repository.ErrUnitNotInSite):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Bağımsız bölüm bu sitede bulunamadı"})
	case errors.Is(err, repository.ErrCategoryNotInSite):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Gider kalemi bu sitede bulunamadı"})
	case errors.As(err, &verr):
		body := gin.H{"error": verr.Msg}
		if len(verr.Valid) > 0 {
			body["valid"] = verr.Valid
		}
		c.JSON(http.StatusUnprocessableEntity, body)
	case errors.Is(err, repository.ErrObjectionNotEntitled):
		c.JSON(http.StatusForbidden, gin.H{"error": "İtiraz yalnızca dairenin maliki ya da vekili tarafından yapılabilir (KMK m.37/2)"})
	case errors.Is(err, repository.ErrBookClosed):
		c.JSON(http.StatusConflict, gin.H{"error": "Defter kapatılmış; yeni kayıt eklenemez"})
	case errors.Is(err, service.ErrNoticeTooLate), errors.Is(err, service.ErrProxyLimitExceeded),
		errors.Is(err, service.ErrUnknownDistribution):
		// Mevzuat sınırı ihlali: kullanıcıya NEDENİ ile birlikte gösterilir.
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
	default:
		// İstemci kaynaklı veritabanı hatası (biçim, kısıt, uzunluk) 500 değildir.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		var nf *legalparams.ErrNotFound
		if errors.As(err, &nf) {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[governance] mevzuat parametresi eksik (%s): %v", op, err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"error": "Mevzuat parametresi tanımlı değil; işlem yapılamadı"})
			return
		}
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[governance] %s başarısız: %v", op, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// ---------------------------------------------------------------------------
// İŞLETME PROJESİ
// ---------------------------------------------------------------------------

func CreateBudget(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateBudgetInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		b, err := svc.CreateBudget(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			mapError(c, err, "işletme projesi oluşturma")
			return
		}
		c.JSON(http.StatusCreated, b)
	}
}

func ListBudgets(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListBudgets(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			mapError(c, err, "işletme projesi listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func GetBudget(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		b, err := svc.GetBudget(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "işletme projesi okuma")
			return
		}
		c.JSON(http.StatusOK, b)
	}
}

func NotifyBudget(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.NotifyBudgetInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Tebliğ yöntemi zorunludur"})
			return
		}
		b, err := svc.NotifyBudget(c.Request.Context(), c.GetString("property_id"), c.Param("id"), in)
		if err != nil {
			mapError(c, err, "işletme projesi tebliği")
			return
		}
		c.JSON(http.StatusOK, b)
	}
}

func FinalizeBudget(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			DecisionRef string `json:"decision_ref"`
		}
		_ = c.ShouldBindJSON(&in)
		b, err := svc.FinalizeBudget(c.Request.Context(), c.GetString("property_id"), c.Param("id"), in.DecisionRef)
		if err != nil {
			mapError(c, err, "işletme projesi kesinleştirme")
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"budget": b,
			"note": "Kesinleşen işletme projesi, İİK m.68 anlamında belge niteliğindedir " +
				"(KMK m.37/son); icra takibine dayanak yapılabilir.",
		})
	}
}

func AddObjection(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			UnitID string `json:"unit_id" binding:"required"`
			Reason string `json:"reason" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Daire ve itiraz gerekçesi zorunludur"})
			return
		}
		o, err := svc.AddObjection(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), in.UnitID, c.GetString("user_id"), in.Reason)
		if err != nil {
			mapError(c, err, "itiraz kaydı")
			return
		}
		resp := gin.H{"objection": o}
		if !o.InTime {
			resp["warning"] = "Bu itiraz yasal süre (KMK m.37/2) dışında yapılmıştır; " +
				"süresinde yapılmayan itiraz projenin kesinleşmesini engellemez."
		}
		c.JSON(http.StatusCreated, resp)
	}
}

func ListObjections(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListObjections(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "itiraz listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func ResolveObjection(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Status     string `json:"status" binding:"required"`
			Resolution string `json:"resolution"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if in.Status != "ACCEPTED" && in.Status != "REJECTED" && in.Status != "WITHDRAWN" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz itiraz durumu"})
			return
		}
		if err := svc.ResolveObjection(c.Request.Context(), c.GetString("property_id"), c.Param("id"), c.Param("objectionId"), in.Status, in.Resolution); err != nil {
			mapError(c, err, "itiraz sonuçlandırma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "İtiraz sonuçlandırıldı"})
	}
}

// ---------------------------------------------------------------------------
// GENEL KURUL
// ---------------------------------------------------------------------------

func CreateAssembly(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateAssemblyInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		a, err := svc.CreateAssembly(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in)
		if err != nil {
			mapError(c, err, "toplantı oluşturma")
			return
		}
		c.JSON(http.StatusCreated, a)
	}
}

func ListAssemblies(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListAssemblies(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			mapError(c, err, "toplantı listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func GetAssembly(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		a, err := svc.GetAssembly(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "toplantı okuma")
			return
		}
		c.JSON(http.StatusOK, a)
	}
}

func NotifyAssembly(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Method string `json:"method" binding:"required"`
		}
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Çağrı yöntemi zorunludur"})
			return
		}
		if err := svc.NotifyAssembly(c.Request.Context(), c.GetString("property_id"), c.Param("id"), in.Method); err != nil {
			mapError(c, err, "toplantı çağrısı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Çağrı kaydedildi"})
	}
}

func AddAttendee(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.AttendeeInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if err := svc.AddAttendee(c.Request.Context(), c.GetString("property_id"), c.Param("id"), in); err != nil {
			mapError(c, err, "hazirun kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Hazirun kaydedildi"})
	}
}

func GetQuorum(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		q, err := svc.EvaluateQuorumFor(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "nisap hesabı")
			return
		}
		c.JSON(http.StatusOK, q)
	}
}

func HoldAssembly(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		q, err := svc.HoldAssembly(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "toplantı açılışı")
			return
		}
		c.JSON(http.StatusOK, q)
	}
}

func CastVote(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.VoteInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		if in.Vote != "FOR" && in.Vote != "AGAINST" && in.Vote != "ABSTAIN" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Oy değeri FOR, AGAINST veya ABSTAIN olmalıdır"})
			return
		}
		if err := svc.CastVote(c.Request.Context(), c.GetString("property_id"),
			c.Param("itemId"), in, c.GetString("user_id")); err != nil {
			mapError(c, err, "oy kaydı")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"message": "Oy kaydedildi"})
	}
}

func CloseAgendaItem(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			DecisionText string `json:"decision_text"`
		}
		_ = c.ShouldBindJSON(&in)
		res, err := svc.CloseAgendaItem(c.Request.Context(), c.GetString("property_id"),
			c.Param("itemId"), in.DecisionText)
		if err != nil {
			mapError(c, err, "gündem maddesi sonuçlandırma")
			return
		}
		c.JSON(http.StatusOK, res)
	}
}

// ---------------------------------------------------------------------------
// DEFTERLER
// ---------------------------------------------------------------------------

func EnsureBook(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		kind := c.Query("kind")
		if kind == "" {
			kind = "DECISION"
		}
		year, _ := strconv.Atoi(c.Query("year"))
		if year == 0 {
			year = time.Now().Year()
		}
		b, err := svc.EnsureBook(c.Request.Context(), c.GetString("property_id"), kind, year)
		if err != nil {
			mapError(c, err, "defter açma")
			return
		}
		c.JSON(http.StatusOK, b)
	}
}

func AppendBookEntry(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateBookEntryInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Başlık ve içerik zorunludur"})
			return
		}
		e, err := svc.AppendBookEntry(c.Request.Context(), c.GetString("property_id"), c.Param("id"), c.GetString("user_id"), in)
		if err != nil {
			mapError(c, err, "defter kaydı")
			return
		}
		c.JSON(http.StatusCreated, e)
	}
}

func ListBookEntries(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListBookEntries(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "defter okuma")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func VerifyBook(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		res, err := svc.VerifyBook(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		if err != nil {
			mapError(c, err, "defter doğrulama")
			return
		}
		c.JSON(http.StatusOK, res)
	}
}

func CloseBook(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			NotaryRef  string `json:"notary_ref"`
			ClosedAt   string `json:"closed_at"`
			PeriodYear int    `json:"period_year"`
		}
		_ = c.ShouldBindJSON(&in)
		closedAt := time.Now()
		if in.ClosedAt != "" {
			if d, err := time.Parse("2006-01-02", in.ClosedAt); err == nil {
				closedAt = d
			}
		}
		if in.PeriodYear == 0 {
			in.PeriodYear = closedAt.Year() - 1
		}
		warning, err := svc.CloseBook(c.Request.Context(), c.GetString("property_id"),
			c.Param("id"), in.NotaryRef, closedAt, in.PeriodYear)
		if err != nil {
			mapError(c, err, "defter kapatma")
			return
		}
		resp := gin.H{"message": "Defter kapatıldı"}
		if warning != "" {
			resp["warning"] = warning
		}
		c.JSON(http.StatusOK, resp)
	}
}

// ---------------------------------------------------------------------------
// HUKUK / İCRA
// ---------------------------------------------------------------------------

func CreateLegalCase(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.CreateLegalCaseInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		cse, warning, err := svc.CreateLegalCase(c.Request.Context(), c.GetString("property_id"), in)
		if err != nil {
			mapError(c, err, "takip açma")
			return
		}
		resp := gin.H{"case": cse}
		if warning != "" {
			resp["warning"] = warning
		}
		c.JSON(http.StatusCreated, resp)
	}
}

func ListLegalCases(svc *service.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListLegalCases(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			mapError(c, err, "takip listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}
