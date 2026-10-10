package main

// Tüketim pusulasına itiraz (migration 063, beşinci tur B8, Şikayetvar "absürt fatura, itiraz incelenene kadar").
//   POST /consumption/statements/:id/objections {unit_id, reason} — bölümün aktif sakini
//   GET  /consumption/objections?status=                         — yönetim tümü, sakin kendi bölümleri
//   POST /consumption/objections/:id/respond {decision, response} — yönetim (MANAGER, BOARD_MEMBER)
// Yayımlanmış pusula değişmez; kabul edilen itirazda düzeltme yönetimin açıklamasındaki yolla yapılır.

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/siteeksen/backend/pkg/notify"
	"github.com/siteeksen/backend/services/iot/repository"
)

func objectionError(c *gin.Context, err error, op string) {
	switch {
	case errors.Is(err, repository.ErrNotUnitResident):
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
	case errors.Is(err, repository.ErrObjectionOpen), errors.Is(err, repository.ErrObjectionClosed):
		c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
	default:
		fail(c, err, op)
	}
}

func createObjection(repo *repository.Repository, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			UnitID string `json:"unit_id"`
			Reason string `json:"reason"`
		}
		if err := c.ShouldBindJSON(&in); err != nil || strings.TrimSpace(in.UnitID) == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "unit_id ve reason zorunludur"})
			return
		}
		reason := strings.TrimSpace(in.Reason)
		if len([]rune(reason)) < 10 || len([]rune(reason)) > 2000 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "İtiraz gerekçesi 10-2000 karakter olmalı (ör. okunan endeks, sayaçtaki değer, fotoğraf tarihi)"})
			return
		}
		propertyID := c.GetString("property_id")
		o, err := repo.CreateObjection(c.Request.Context(), propertyID, c.GetString("user_id"), c.Param("id"), in.UnitID, reason)
		if err != nil {
			objectionError(c, err, "itiraz")
			return
		}
		c.JSON(http.StatusCreated, gin.H{"objection": o,
			"message":      "İtirazınız yönetime iletildi; yanıt verildiğinde bildirim alırsınız.",
			"notification": notifyObjection(c.Request.Context(), n, pool, propertyID, c.GetString("user_id"), o)})
	}
}

func listObjections(repo *repository.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		resident := c.GetString("user_id")
		if isStatementAdmin(c) {
			resident = ""
		}
		status := strings.ToUpper(c.Query("status"))
		if status != "" && status != "OPEN" && status != "ACCEPTED" && status != "REJECTED" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "status OPEN, ACCEPTED ya da REJECTED olmalı"})
			return
		}
		list, err := repo.ListObjections(c.Request.Context(), c.GetString("property_id"), resident, status)
		if err != nil {
			fail(c, err, "itiraz listeleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"data": list})
	}
}

func respondObjection(repo *repository.Repository, n *notify.Notifier, pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var in struct {
			Decision string `json:"decision"`
			Response string `json:"response"`
		}
		_ = c.ShouldBindJSON(&in)
		decision := strings.ToUpper(strings.TrimSpace(in.Decision))
		response := strings.TrimSpace(in.Response)
		if (decision != "ACCEPTED" && decision != "REJECTED") || len([]rune(response)) < 5 {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "decision ACCEPTED ya da REJECTED olmalı ve açıklama en az 5 karakter olmalı " +
				"(kabulde düzeltmenin nasıl yapılacağını yazın: yeniden okuma, alacak dekontu vb.)"})
			return
		}
		propertyID := c.GetString("property_id")
		o, err := repo.RespondObjection(c.Request.Context(), propertyID, c.GetString("user_id"), c.Param("id"), decision, response)
		if err != nil {
			objectionError(c, err, "itiraz yanıtı")
			return
		}
		c.JSON(http.StatusOK, gin.H{"objection": o, "message": "İtiraz yanıtlandı; sakine bildirildi.",
			"notification": notifyObjectionAnswer(c.Request.Context(), n, propertyID, c.GetString("user_id"), o)})
	}
}

// notifyObjection, onay yetkili yönetime "yeni itiraz" bildirimi gönderir.
func notifyObjection(ctx context.Context, n *notify.Notifier, pool *pgxpool.Pool, propertyID, actorID string, o *repository.Objection) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; yönetime bildirim oluşturulmadı."}
	}
	recipients, err := notify.Approvers(ctx, pool, propertyID)
	if err != nil {
		log.Printf("[iot] itiraz bildirimi alıcıları: %v", err)
		return &notify.BroadcastResult{Note: "Yönetim alıcıları okunamadı; bildirim oluşturulmadı."}
	}
	return n.Broadcast(ctx, notify.Message{
		PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Topic: "statement.objection", Subject: "Tüketim pusulasına itiraz: " + o.Unit,
		Body: o.Unit + " bölümü " + meterTypeLabel[o.MeterType] + " pusulasına (" + o.PeriodFrom.Format("02.01.2006") + " – " +
			o.PeriodTo.Format("02.01.2006") + ") itiraz etti: " + o.Reason,
		Payload:   map[string]any{"objection_id": o.ID, "allocation_id": o.AllocationID, "unit_id": o.UnitID},
		DedupeKey: "statement.objection:" + o.ID,
		CreatedBy: actorID,
	}, recipients)
}

// notifyObjectionAnswer, itiraz edene yanıtı bildirir.
func notifyObjectionAnswer(ctx context.Context, n *notify.Notifier, propertyID, actorID string, o *repository.Objection) *notify.BroadcastResult {
	if n == nil {
		return &notify.BroadcastResult{Note: "Bildirim altyapısı kurulu değil; sakine bildirim oluşturulmadı."}
	}
	word := map[string]string{"ACCEPTED": "kabul edildi", "REJECTED": "reddedildi"}[o.Status]
	resp := ""
	if o.Response != nil {
		resp = *o.Response
	}
	return n.Broadcast(ctx, notify.Message{
		PropertyID: propertyID, Channel: notify.ChannelInApp, Category: notify.CategoryTransactional,
		Topic: "statement.objection.answer", Subject: "Pusula itirazınız " + word,
		Body:      meterTypeLabel[o.MeterType] + " pusulasına (" + o.Unit + ") itirazınız " + word + ". Yönetimin açıklaması: " + resp,
		Payload:   map[string]any{"objection_id": o.ID, "status": o.Status},
		DedupeKey: "statement.objection.answer:" + o.ID,
		CreatedBy: actorID,
	}, []notify.Recipient{{UserID: o.UserID, UnitID: o.UnitID}})
}
