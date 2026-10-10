package handlers

import (
	"errors"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/middleware"
	"github.com/siteeksen/backend/pkg/notify"
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
	case errors.Is(err, repository.ErrInvalidAssessmentInput):
		// Mesaj bizim yazdığımız metindir (vade biçimi, dağıtılamayan kalem).
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
	default:
		// Önceki sürüm burada HER hatanın ham metnini 400 ile istemciye yazıyordu;
		// PostgreSQL hata metni tablo/kısıt adlarını sızdırıyordu.
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[finance] tahakkuk işlemi başarısız: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// GetDebtStatus anlık borç durumu (Dashboard kartı)
func GetDebtStatus(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")

		status, err := svc.GetDebtStatus(c.Request.Context(), userID, propertyID)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
		propertyID := c.GetString("property_id")
		year, _ := strconv.Atoi(c.DefaultQuery("year", "0"))

		assessments, err := svc.GetAssessments(c.Request.Context(), propertyID, userID, year)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
		propertyID := c.GetString("property_id")

		details, err := svc.GetAssessmentDetails(c.Request.Context(), propertyID,
			c.GetString("user_id"), getRoles(c), assessmentID)
		if errors.Is(err, repository.ErrAssessmentNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Aidat bulunamadı"})
			return
		}
		if err != nil {
			// Önceden HER hata (veritabanı arızası dahil) "bulunamadı" diye
			// dönüyordu; arıza, kaydın yokluğu gibi görünüyordu.
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] aidat detayı okunamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Aidat detayı alınamadı"})
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
//
// Oluşan her borç için daire sakinlerine bildirim gider (beşinci tur B1); sonuç
// `notification` alanında sayaçlarla döner.
func CreateAssessment(svc *service.FinanceService, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
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
		ids := make([]string, 0, len(summaries))
		for _, s := range summaries {
			ids = append(ids, s.ID)
		}
		c.JSON(http.StatusCreated, gin.H{"data": summaries,
			"notification": notify.NotifyCharges(c.Request.Context(), n, pool, propertyID, c.GetString("user_id"), ids)})
	}
}

// validPaymentMethods, payments.payment_method için kabul edilen değerlerdir
// (001_initial_schema.sql'deki sözleşme).
var validPaymentMethods = map[string]bool{
	"CREDIT_CARD": true, "SAVED_CARD": true, "BANK_TRANSFER": true, "CASH": true,
}

// CreatePaymentRequest ödeme isteği
type CreatePaymentRequest struct {
	AssessmentIDs []string `json:"assessment_ids" binding:"required"`
	PaymentMethod string   `json:"payment_method" binding:"required"` // CREDIT_CARD, SAVED_CARD
	CardToken     string   `json:"card_token"`
	SaveCard      bool     `json:"save_card"`
	// ValueDate: havale/EFT/nakit ödemenin yapıldığı (valör) gün, YYYY-AA-GG; boşsa bugün (053).
	ValueDate string `json:"value_date"`
	// Reference: havale açıklaması / dekont numarası (yöneticinin banka hareketiyle eşleştirmesi için).
	Reference string `json:"reference"`
}

// CreatePayment ödeme başlatır
func CreatePayment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req CreatePaymentRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek formatı"})
			return
		}
		// Ödeme yöntemi doğrulanmıyordu: istemci ne yazarsa ('CARD', 'TRANSFER'…)
		// kaydediliyor, yönetim ekranı tanımadığı yöntemi gösteremiyordu.
		req.PaymentMethod = strings.ToUpper(strings.TrimSpace(req.PaymentMethod))
		if !validPaymentMethods[req.PaymentMethod] {
			c.JSON(http.StatusUnprocessableEntity, gin.H{
				"error": "Geçersiz ödeme yöntemi",
				"valid": []string{"CREDIT_CARD", "SAVED_CARD", "BANK_TRANSFER", "CASH"},
			})
			return
		}

		// Valör (Apsiyon BUG-02): havale/EFT/nakitte gecikme tazminatı ödeme gününde durur.
		var valueDate *time.Time
		if req.PaymentMethod == "BANK_TRANSFER" || req.PaymentMethod == "CASH" {
			today, _ := time.Parse("2006-01-02", time.Now().Format("2006-01-02"))
			vd := today
			if strings.TrimSpace(req.ValueDate) != "" {
				p, perr := time.Parse("2006-01-02", strings.TrimSpace(req.ValueDate))
				if perr != nil || p.After(today) || p.Before(today.AddDate(-1, 0, 0)) {
					c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Ödeme (valör) tarihi YYYY-AA-GG biçiminde, bugünden ileri olmayan ve son bir yıl içinde bir tarih olmalı"})
					return
				}
				vd = p
			}
			valueDate = &vd
		}
		if len(req.Reference) > 140 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Referans en fazla 140 karakter olabilir"})
			return
		}

		userID := c.GetString("user_id")
		var result *service.PaymentResult
		var err error
		if req.PaymentMethod == "CREDIT_CARD" && svc.CardReady() {
			// Kartla ödeme (060): iyzico ödeme sayfası; kart bilgisi bu sisteme gelmez.
			result, err = svc.StartCardPayment(c.Request.Context(), c.GetString("property_id"), userID, req.AssessmentIDs, c.ClientIP())
			if errors.Is(err, service.ErrCardUnavailable) {
				c.JSON(http.StatusBadGateway, gin.H{"error": err.Error(), "code": "CARD_GATEWAY",
					"note": "Kartınızdan tutar çekilmedi. Gecikme tazminatı bu denemenin gününe göre hesaplanır; birazdan yeniden deneyebilirsiniz."})
				return
			}
		} else {
			result, err = svc.CreatePayment(c.Request.Context(), c.GetString("property_id"), userID, req.AssessmentIDs, req.PaymentMethod, req.CardToken,
				valueDate, strings.TrimSpace(req.Reference))
		}
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
			case errors.Is(err, repository.ErrPaymentAlreadyPending):
				c.JSON(http.StatusConflict, gin.H{
					"error": "Bu aidat için yönetim onayı bekleyen bir ödemeniz zaten var; " +
						"onaylanmasını ya da reddedilmesini bekleyin",
				})
			default:
				if middleware.DBErrorResponse(c, err) {
					return
				}
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
			if middleware.DBErrorResponse(c, err) {
				return
			}
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

		err := svc.ConfirmPayment(c.Request.Context(), paymentID, propertyID, req.Reference, c.GetString("user_id"))
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
			if middleware.DBErrorResponse(c, err) {
				return
			}
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
		if middleware.DBErrorResponse(c, err) {
			return
		}
		log.Printf("[finance] ödeme onay/ret hatası (payment=%s): %v", paymentID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "İşlem tamamlanamadı"})
	}
}

// GetMyPayments, çağıranın kendi ödeme geçmişi (sakin uygulaması için).
func GetMyPayments(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, ok := parsePage(c)
		if !ok {
			return
		}
		payments, total, err := svc.GetMyPayments(c.Request.Context(), c.GetString("user_id"), c.GetString("property_id"), page)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] kişisel ödeme geçmişi alınamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme geçmişi alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": payments, "total": total, "limit": page.Limit, "offset": page.Offset})
	}
}

// GetPaymentHistory ödeme geçmişi — yönetim rolleri site genelini, sakinler kendi geçmişini görür
func GetPaymentHistory(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		propertyID := c.GetString("property_id")

		page, ok := parsePage(c)
		if !ok {
			return
		}
		payments, total, err := svc.GetPaymentHistory(c.Request.Context(), userID, propertyID, getRoles(c), page)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ödeme geçmişi alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": payments, "total": total, "limit": page.Limit, "offset": page.Offset})
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

		summary, err := svc.GetConsumptionSummary(c.Request.Context(), c.GetString("property_id"), userID, meterType)
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Tüketim verisi alınamadı"})
			return
		}
		c.JSON(http.StatusOK, summary)
	}
}

// parsePage, `limit` (varsayılan 50, en çok 500) ve `offset` sorgu
// parametrelerini okur. Geçersizse 400 yazar ve false döner. Yanıtta `total`
// döndüğü için istemci listenin kesildiğini bilir (B69: önceden sabit LIMIT 50
// sessizce uygulanıyordu).
func parsePage(c *gin.Context) (models.Page, bool) {
	p := models.Page{Limit: 50}
	if v := c.Query("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > 500 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "limit 1 ile 500 arasında olmalı"})
			return p, false
		}
		p.Limit = n
	}
	if v := c.Query("offset"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "offset sıfır ya da pozitif olmalı"})
			return p, false
		}
		p.Offset = n
	}
	return p, true
}

// CreateOpeningBalances devir bakiyelerini girer (site kurulumu, FAZ 8.1).
func CreateOpeningBalances(svc *service.FinanceService, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in models.OpeningBalanceInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "due_date ve en az bir {unit_id, amount>0} satırı gerekli"})
			return
		}
		list, err := svc.CreateOpeningBalances(c.Request.Context(), c.GetString("property_id"), in)
		switch {
		case errors.Is(err, repository.ErrInvalidAssessmentInput):
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
		case errors.Is(err, repository.ErrOpeningExists):
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		case err != nil:
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] devir bakiyesi yazılamadı: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Devir bakiyesi kaydedilemedi"})
		default:
			ids := make([]string, 0, len(list))
			for _, o := range list {
				ids = append(ids, o.ID)
			}
			c.JSON(http.StatusCreated, gin.H{"data": list, "created": len(list),
				"note":         "Devir bakiyesine otomatik gecikme tazminatı işletilmez; önceki tazminat devir tutarına dahil edilmelidir.",
				"notification": notify.NotifyCharges(c.Request.Context(), n, pool, c.GetString("property_id"), c.GetString("user_id"), ids)})
		}
	}
}

// ListOpeningBalances etkin devir kayıtlarını listeler.
func ListOpeningBalances(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListOpeningBalances(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] devir listesi: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Devir kayıtları alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// CancelOpeningBalance hatalı devir kaydını iptal eder.
func CancelOpeningBalance(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		err := svc.CancelOpeningBalance(c.Request.Context(), c.GetString("property_id"), c.Param("id"))
		switch {
		case errors.Is(err, repository.ErrOpeningNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "Devir kaydı bulunamadı"})
		case errors.Is(err, repository.ErrOpeningNotCancellable):
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		case err != nil:
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] devir iptali: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Devir kaydı iptal edilemedi"})
		default:
			c.JSON(http.StatusOK, gin.H{"message": "Devir kaydı iptal edildi"})
		}
	}
}

// ReversePayment: POST /finance/payments/:id/reverse {reason} — tamamlanmış ödemenin ters kaydı.
// Ödeme silinmez; tahakkukların ödenen tutarı geri alınır ve tahsilat defterine gerekçeli kayıt düşer.
func ReversePayment(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Reason string `json:"reason"`
		}
		if err := c.ShouldBindJSON(&req); err != nil || len(strings.TrimSpace(req.Reason)) < 5 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Ters kayıt gerekçesi zorunludur (en az 5 karakter)"})
			return
		}
		err := svc.ReversePayment(c.Request.Context(), c.Param("id"), c.GetString("property_id"), c.GetString("user_id"), strings.TrimSpace(req.Reason))
		switch {
		case err == nil:
			c.JSON(http.StatusOK, gin.H{"message": "Ödemenin ters kaydı yapıldı; ödeme silinmedi, tahsilat defterine gerekçesiyle yazıldı"})
		case errors.Is(err, repository.ErrPaymentNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "Ödeme bulunamadı"})
		case errors.Is(err, repository.ErrPaymentNotCompleted):
			c.JSON(http.StatusConflict, gin.H{"error": "Yalnızca tamamlanmış ödemenin ters kaydı yapılabilir"})
		default:
			if middleware.DBErrorResponse(c, err) {
				return
			}
			log.Printf("[finance] ters kayıt: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ters kayıt yapılamadı"})
		}
	}
}

// ListLedger: GET /finance/ledger — tahsilat defteri (yönetim, denetçi).
func ListLedger(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		list, err := svc.ListLedger(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			log.Printf("[finance] defter: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Defter alınamadı"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

// VerifyLedger: GET /finance/ledger/verify — zincir doğrulaması; sitenin her üyesi (kat maliki dahil)
// tahsilat kayıtlarının sonradan değiştirilmediğini görebilir. Tutar/kişi bilgisi dönmez.
func VerifyLedger(svc *service.FinanceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		v, err := svc.VerifyLedger(c.Request.Context(), c.GetString("property_id"))
		if err != nil {
			log.Printf("[finance] defter doğrulama: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Doğrulama yapılamadı"})
			return
		}
		c.JSON(http.StatusOK, v)
	}
}
