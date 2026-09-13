package handlers

import (
	"errors"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/siteeksen/backend/services/finance/models"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

func getRoles(c *gin.Context) []string {
	value, exists := c.Get("roles")
	if !exists {
		return nil
	}
	roles, _ := value.([]string)
	return roles
}

func mapAssessmentError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, service.ErrAssessmentForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu işlem için yetkiniz yok"})
	case errors.Is(err, repository.ErrExpenseCategoryNotFound):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Belirtilen gider kalemi bulunamadı"})
	case errors.Is(err, repository.ErrAssessmentPeriodExists):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu dönem için tahakkuk zaten oluşturulmuş"})
	case errors.Is(err, repository.ErrNoUnitsInProperty):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Sitede tanımlı birim bulunamadı"})
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	}
}

// GetDebtStatus anlık borç durumu (Dashboard kartı)
func GetDebtStatus(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")

		status, err := svc.GetDebtStatus(c.Request.Context(), userID, propertyID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Borç durumu alınamadı"})
			return
		}
		c.JSON(http.StatusOK, status)
	}
}

// GetAssessments aidat listesi
func GetAssessments(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		year, _ := strconv.Atoi(c.DefaultQuery("year", "0"))

		assessments, err := svc.GetAssessments(c.Request.Context(), userID, year)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Aidatlar alınamadı"})
			return
		}
		// Liste uçları tek sözleşme kullanır: {"data": [...]}.
		// Bazı uçlar düz dizi, bazıları sarmalayıcı döndürüyordu; istemciler
		// bu farkı bilmediği için çalışan bir sunucuda bile hata gösteriyordu.
		c.JSON(http.StatusOK, gin.H{"data": assessments})
	}
}

// GetAssessmentOverview site genelinde dönem bazlı tahakkuk/tahsilat özetini getirir (yönetim görünümü)
func GetAssessmentOverview(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		year, _ := strconv.Atoi(c.DefaultQuery("year", "0"))

		periods, err := svc.ListAssessmentOverview(c.Request.Context(), propertyID, getRoles(c), year)
		if err != nil {
			mapAssessmentError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": periods})
	}
}

// GetAssessmentDetails aidat detayı
func GetAssessmentDetails(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		assessmentID := c.Param("id")

		details, err := svc.GetAssessmentDetails(c.Request.Context(), assessmentID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Aidat bulunamadı"})
			return
		}
		c.JSON(http.StatusOK, details)
	}
}

// GetExpenseCategories sitenin gider kalemlerini listeler (aidat tahakkuku formu için)
func GetExpenseCategories(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		categories, err := svc.ListExpenseCategories(c.Request.Context(), propertyID, getRoles(c))
		if err != nil {
			mapAssessmentError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": categories})
	}
}

// CreateAssessment yönetimin gider kalemlerine göre dönemlik aidat tahakkuku oluşturur
func CreateAssessment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var input models.CreateAssessmentInput
		if err := c.ShouldBindJSON(&input); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		propertyID := c.GetString("property_id")
		summaries, err := svc.CreateAssessment(c.Request.Context(), propertyID, getRoles(c), input)
		if err != nil {
			mapAssessmentError(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"data": summaries})
	}
}

// CreatePaymentRequest ödeme isteği
type CreatePaymentRequest struct {
	AssessmentIDs []string `json:"assessment_ids" binding:"required"`
	PaymentMethod string   `json:"payment_method" binding:"required"` // CREDIT_CARD, SAVED_CARD
	CardToken     string   `json:"card_token"`
	SaveCard      bool     `json:"save_card"`
}

// CreatePayment ödeme başlatır
func CreatePayment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req CreatePaymentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}

		userID := c.GetString("user_id")
		result, err := svc.CreatePayment(c.Request.Context(), userID, req.AssessmentIDs, req.PaymentMethod, req.CardToken)
		if err != nil {
			// Hata eşlemesi (2026-09-09): Önceki sürüm her hatayı `err.Error()` ile ham metin
			// olarak döndürüyordu; bu, PostgreSQL hata mesajlarıyla tablo/sütun/kısıt adlarını
			// istemciye sızdırıyordu (bilgi toplama riski).
			switch {
			case errors.Is(err, repository.ErrNoPayableAssessment):
				c.JSON(http.StatusBadRequest, gin.H{"error": "Ödenecek aidat seçilmedi"})
			case errors.Is(err, repository.ErrAssessmentNotPayable):
				// Kullanıcıya ait olmayan tahakkuk kimlikleri de buraya düşer; hangi kimliğin
				// var olduğu bilgisini sızdırmamak için tek ve genel bir mesaj kullanılır.
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Seçilen aidatlardan biri ödenebilir durumda değil",
				})
			default:
				log.Printf("[finance] ödeme oluşturulamadı (user=%s): %v", userID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme kaydı oluşturulamadı"})
			}
			return
		}

		c.JSON(http.StatusOK, result)
	}
}

// AccrueLateFees, vadesi geçmiş tahakkuklara gecikme tazminatı işler (KMK m.20/2).
// `as_of` verilmezse bugün kullanılır; geçmiş bir tarih verilerek yeniden hesaplama yapılabilir.
func AccrueLateFees(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			AsOf string `json:"as_of"`
		}
		_ = c.ShouldBindJSON(&req)

		asOf := time.Now()
		if req.AsOf != "" {
			parsed, err := time.Parse("2006-01-02", req.AsOf)
			if err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Tarih biçimi YYYY-AA-GG olmalıdır"})
				return
			}
			asOf = parsed
		}

		propertyID := c.GetString("property_id")
		res, err := svc.AccrueLateFees(c.Request.Context(), propertyID, asOf)
		if err != nil {
			log.Printf("[finance] gecikme tazminatı işlenemedi (property=%s): %v", propertyID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Gecikme tazminatı işlenemedi"})
			return
		}
		c.JSON(http.StatusOK, res)
	}
}

// ConfirmPayment, yöneticinin bekleyen bir ödemeyi tahsil edilmiş olarak onaylamasıdır (todo 4.2).
// Bu işlem tahakkukların `paid_amount` değerini artırır ve durumlarını PARTIAL/PAID yapar.
func ConfirmPayment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		paymentID := c.Param("id")
		propertyID := c.GetString("property_id")

		var req struct {
			// Reference: dekont/havale referansı. Zorunlu değildir ama denetim için önerilir.
			Reference string `json:"reference"`
		}
		_ = c.ShouldBindJSON(&req) // gövde boş olabilir

		err := svc.ConfirmPayment(c.Request.Context(), paymentID, propertyID, req.Reference)
		if err != nil {
			mapPaymentConfirmError(c, err, paymentID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Ödeme onaylandı ve borçtan düşüldü"})
	}
}

// RejectPayment, bekleyen ödemeyi başarısız işaretler. Borç olduğu gibi kalır.
func RejectPayment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		paymentID := c.Param("id")
		propertyID := c.GetString("property_id")

		if err := svc.RejectPayment(c.Request.Context(), paymentID, propertyID); err != nil {
			mapPaymentConfirmError(c, err, paymentID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Ödeme reddedildi; borç değişmedi"})
	}
}

// ListPendingPayments, onay bekleyen ödemeleri listeler (yönetim ekranı).
func ListPendingPayments(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")
		payments, err := svc.ListPendingPayments(c.Request.Context(), propertyID)
		if err != nil {
			log.Printf("[finance] bekleyen ödemeler alınamadı (property=%s): %v", propertyID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Bekleyen ödemeler alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": payments})
	}
}

// mapPaymentConfirmError, onay/ret akışının hatalarını HTTP durumlarına eşler.
// Ham veritabanı hatası istemciye sızdırılmaz.
func mapPaymentConfirmError(c *gin.Context, err error, paymentID string) {
	switch {
	case errors.Is(err, repository.ErrPaymentNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "Ödeme kaydı bulunamadı"})
	case errors.Is(err, repository.ErrPaymentNotPending):
		// Çift onaylama girişimi. 409: kaynağın durumu bu işleme uygun değil.
		c.JSON(http.StatusConflict, gin.H{"error": "Bu ödeme zaten sonuçlanmış"})
	case errors.Is(err, repository.ErrPaymentNotOwned):
		c.JSON(http.StatusForbidden, gin.H{"error": "Bu ödeme sizin sitenize ait değil"})
	case errors.Is(err, repository.ErrNoPayableAssessment):
		c.JSON(http.StatusBadRequest, gin.H{"error": "Ödemeye bağlı tahakkuk bulunamadı"})
	default:
		log.Printf("[finance] ödeme onay/ret hatası (payment=%s): %v", paymentID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// GetPaymentHistory ödeme geçmişi — yönetim rolleri site genelini, sakinler kendi geçmişini görür
func GetPaymentHistory(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")

		payments, err := svc.GetPaymentHistory(c.Request.Context(), userID, propertyID, getRoles(c))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme geçmişi alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": payments})
	}
}

// GetDebtors sitede borcu olan sakinlerin özetini getirir (yönetim görünümü)
func GetDebtors(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.GetString("property_id")

		debtors, err := svc.ListDebtors(c.Request.Context(), propertyID, getRoles(c))
		if err != nil {
			mapAssessmentError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": debtors})
	}
}

// GetConsumptionSummary tüketim özeti (6 aylık grafik)
func GetConsumptionSummary(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		meterType := c.DefaultQuery("meter_type", "HEAT")

		summary, err := svc.GetConsumptionSummary(c.Request.Context(), userID, meterType)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Tüketim verisi alınamadı"})
			return
		}
		c.JSON(http.StatusOK, summary)
	}
}
