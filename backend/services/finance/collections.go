package main

// Yönetimin tahsilat girişi (migration 061, beşinci tur B2, Şikayetvar "ödedim, borç silinmedi").

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/money"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/finance/repository"
	"github.com/siteeksen/backend/services/finance/service"
)

func collectionError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, repository.ErrAssessmentNotPayable):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "Seçilen borçların hepsi bu bölüme ait değil ya da ödenecek tutarı kalmamış"})
	case errors.Is(err, repository.ErrPaymentAlreadyPending):
		c.JSON(http.StatusConflict, gin.H{"error": "Bu borçlar için sakinin onay bekleyen ödeme bildirimi var; ikinci kayıt borcu iki kez düşürürdü. Bekleyen bildirimi onaylayın ya da reddedin."})
	default:
		adjustmentError(c, err, "tahsilat girişi")
	}
}

// recordCollection: POST /finance/collections {unit_id, assessment_ids, payment_method, value_date, reference} (yönetim).
func recordCollection(svc *service.FinanceService, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in service.CollectionInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "unit_id, assessment_ids, payment_method ve value_date zorunludur"})
			return
		}
		res, err := svc.RecordCollection(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in, "")
		if err != nil {
			collectionError(c, err)
			return
		}
		c.JSON(http.StatusCreated, gin.H{"collection": res,
			"message":      "Tahsilat kaydedildi; borç düşüldü ve tahsilat defterine yazıldı",
			"notification": notifyCollection(c.Request.Context(), n, pool, c.GetString("property_id"), c.GetString("user_id"), in.UnitID, res)})
	}
}

// collectBankLine: POST /finance/bank-statements/lines/:id/collect {unit_id, assessment_ids} (yönetim).
// Bildirimi olmayan banka hareketi doğrudan bölümün borçlarına işlenir; tutar birebir aynı olmalıdır.
func collectBankLine(svc *service.FinanceService, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in service.CollectionInput
		if err := c.ShouldBindJSON(&in); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "unit_id ve assessment_ids zorunludur"})
			return
		}
		res, err := svc.RecordCollection(c.Request.Context(), c.GetString("property_id"), c.GetString("user_id"), in, c.Param("id"))
		if err != nil {
			collectionError(c, err)
			return
		}
		c.JSON(http.StatusOK, gin.H{"collection": res, "payment_id": res.PaymentID,
			"message":      "Banka hareketi bölümün borçlarına işlendi; borç düşüldü ve tahsilat defterine yazıldı",
			"notification": notifyCollection(c.Request.Context(), n, pool, c.GetString("property_id"), c.GetString("user_id"), in.UnitID, res)})
	}
}

// notifyCollection, bölümün aktif sakinlerine "ödemeniz kaydedildi" bildirimi gönderir.
// Hata tahsilatı geri almaz; sonuç yanıtta döner.
func notifyCollection(ctx context.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID, actorID, unitID string, res *service.CollectionResult) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; sakine bildirim oluşturulmadı."}
	}
	recipients, err := notify.UnitResidents(ctx, pool, propertyID, unitID)
	if err != nil {
		log.Printf("[finance] tahsilat bildirimi alıcıları: %v", err)
		return &notify.BroadcastResult{Note: "Bölüm sakinleri okunamadı; bildirim oluşturulmadı."}
	}
	how := map[string]string{"CASH": "elden (nakit)", "BANK_TRANSFER": "havale/EFT"}[res.Method]
	day, _ := time.Parse("2006-01-02", res.ValueDate)
	return n.Broadcast(ctx, notify.Message{
		PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Topic: "payment.recorded", Subject: "Ödemeniz kaydedildi",
		Body: fmt.Sprintf("%s tarihli %s ödemeniz (%s) site yönetimi tarafından kaydedildi ve borcunuzdan düşüldü.",
			day.Format("02.01.2006"), how, money.Kurus(res.AmountKurus).Display()),
		Payload:   map[string]any{"payment_id": res.PaymentID, "unit_id": unitID, "amount_kurus": res.AmountKurus},
		DedupeKey: "payment.recorded:" + res.PaymentID,
		CreatedBy: actorID,
	}, recipients)
}
