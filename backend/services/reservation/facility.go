package main

// Tesis tanımlama ve düzenleme (TEST_RAPORU 2.1, migration 048). Önceden tesis
// yalnızca doğrudan SQL ile eklenebiliyordu; panelden rezervasyon akışı başlatılamıyordu.

import (
	"encoding/json"
	"net/http"
	"regexp"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
	"github.com/siteeksen/backend/services/reservation/repository"
)

var hhmm = regexp.MustCompile(`^([01][0-9]|2[0-3]):[0-5][0-9]$`)

// facilityCategories, şemadaki kategori listesidir (005).
var facilityCategories = map[string]bool{
	"POOL": true, "GYM": true, "TENNIS": true, "MEETING_ROOM": true, "BBQ": true, "SAUNA": true, "OTHER": true,
}

// facilityInput, tesis yazma isteğidir. Düzenlemede gönderilmeyen alan mevcut değerini korur.
type facilityInput struct {
	Name                      *string      `json:"name"`
	Description               *string      `json:"description"`
	Category                  *string      `json:"category"`
	Capacity                  *int         `json:"capacity"`
	IsPaid                    *bool        `json:"is_paid"`
	HourlyFee                 *json.Number `json:"hourly_fee"`
	DailyFee                  *json.Number `json:"daily_fee"`
	Deposit                   *json.Number `json:"deposit_amount"`
	AvailableFrom             *string      `json:"available_from"`
	AvailableTo               *string      `json:"available_to"`
	AvailableDays             *[]int       `json:"available_days"`
	MinDurationMinutes        *int         `json:"min_duration_minutes"`
	MaxDurationMinutes        *int         `json:"max_duration_minutes"`
	AdvanceBookingDays        *int         `json:"advance_booking_days"`
	MaxReservationsPerUnit    *int         `json:"max_reservations_per_unit"`
	BufferMinutes             *int         `json:"buffer_minutes"`
	RequiresApproval          *bool        `json:"requires_approval"`
	AutoApproveResidents      *bool        `json:"auto_approve_residents"`
	Rules                     *string      `json:"rules"`
	IsActive                  *bool        `json:"is_active"`
	MaintenanceMode           *bool        `json:"maintenance_mode"`
	MaintenanceNote           *string      `json:"maintenance_note"`
	CancellationDeadlineHours *int         `json:"cancellation_deadline_hours"`
}

// defaultFacility, yeni tesis için şema varsayılanlarıdır (005).
func defaultFacility() *repository.Facility {
	return &repository.Facility{
		AvailableFrom: "08:00", AvailableTo: "22:00", AvailableDays: []int{0, 1, 2, 3, 4, 5, 6},
		MinDurationMinutes: 60, MaxDurationMinutes: 240, AdvanceBookingDays: 14,
		MaxReservationsPerUnit: 2, AutoApproveResidents: true, IsActive: true,
	}
}

// fee, tutarı kuruş hassasiyetinde ayrıştırır; boş gönderilirse tutar kaldırılır.
func fee(n *json.Number, cur *float64) (*float64, string) {
	if n == nil {
		return cur, ""
	}
	if *n == "" {
		return nil, ""
	}
	d, err := decimal.NewFromString(n.String())
	if err != nil || d.IsNegative() || d.Exponent() < -2 {
		return nil, "Ücretler negatif olmayan, en fazla iki ondalıklı tutar olmalı"
	}
	f, _ := d.Float64()
	return &f, ""
}

// apply, isteği tesis üzerine uygular ve iş kurallarını denetler; ihlâlde Türkçe gerekçe döner.
func (in *facilityInput) apply(f *repository.Facility) string {
	str := func(p *string, dst *string) {
		if p != nil {
			*dst = strings.TrimSpace(*p)
		}
	}
	num := func(p *int, dst *int) {
		if p != nil {
			*dst = *p
		}
	}
	flag := func(p *bool, dst *bool) {
		if p != nil {
			*dst = *p
		}
	}
	str(in.Name, &f.Name)
	str(in.Description, &f.Description)
	str(in.Category, &f.Category)
	str(in.AvailableFrom, &f.AvailableFrom)
	str(in.AvailableTo, &f.AvailableTo)
	str(in.Rules, &f.Rules)
	str(in.MaintenanceNote, &f.MaintenanceNote)
	num(in.MinDurationMinutes, &f.MinDurationMinutes)
	num(in.MaxDurationMinutes, &f.MaxDurationMinutes)
	num(in.AdvanceBookingDays, &f.AdvanceBookingDays)
	num(in.MaxReservationsPerUnit, &f.MaxReservationsPerUnit)
	num(in.BufferMinutes, &f.BufferMinutes)
	num(in.CancellationDeadlineHours, &f.CancellationDeadlineHours)
	flag(in.IsPaid, &f.IsPaid)
	flag(in.RequiresApproval, &f.RequiresApproval)
	flag(in.AutoApproveResidents, &f.AutoApproveResidents)
	flag(in.IsActive, &f.IsActive)
	flag(in.MaintenanceMode, &f.MaintenanceMode)
	if in.Capacity != nil {
		if *in.Capacity == 0 {
			f.Capacity = nil
		} else {
			c := *in.Capacity
			f.Capacity = &c
		}
	}
	if in.AvailableDays != nil {
		f.AvailableDays = *in.AvailableDays
	}
	var msg string
	if f.HourlyFee, msg = fee(in.HourlyFee, f.HourlyFee); msg != "" {
		return msg
	}
	if f.DailyFee, msg = fee(in.DailyFee, f.DailyFee); msg != "" {
		return msg
	}
	if f.Deposit, msg = fee(in.Deposit, f.Deposit); msg != "" {
		return msg
	}

	switch {
	case f.Name == "":
		return "Tesis adı zorunludur"
	case f.Category != "" && !facilityCategories[f.Category]:
		return "Kategori şunlardan biri olmalı: POOL, GYM, TENNIS, MEETING_ROOM, BBQ, SAUNA, OTHER"
	case f.Capacity != nil && *f.Capacity < 1:
		return "Kapasite en az 1 kişi olmalı"
	case !hhmm.MatchString(f.AvailableFrom) || !hhmm.MatchString(f.AvailableTo):
		return "Çalışma saatleri SS:DD biçiminde olmalı"
	case f.AvailableFrom >= f.AvailableTo:
		return "Açılış saati kapanış saatinden önce olmalı"
	case len(f.AvailableDays) == 0:
		return "Tesisin açık olduğu en az bir gün seçilmeli"
	case f.MinDurationMinutes < 15 || f.MinDurationMinutes > 1440:
		return "En kısa süre 15-1440 dakika arasında olmalı"
	case f.MaxDurationMinutes < f.MinDurationMinutes || f.MaxDurationMinutes > 1440:
		return "En uzun süre en kısa süreden az ve 1440 dakikadan fazla olamaz"
	case f.AdvanceBookingDays < 1 || f.AdvanceBookingDays > 365:
		return "İleri tarih sınırı 1-365 gün arasında olmalı"
	case f.MaxReservationsPerUnit < 0 || f.MaxReservationsPerUnit > 50:
		return "Haftalık kota 0-50 arasında olmalı (0 = sınırsız)"
	case f.BufferMinutes < 0 || f.BufferMinutes > 240:
		return "Tampon süre 0-240 dakika arasında olmalı"
	case f.CancellationDeadlineHours < 0 || f.CancellationDeadlineHours > 720:
		return "İptal son süresi 0-720 saat arasında olmalı"
	case f.IsPaid && (f.HourlyFee == nil || *f.HourlyFee == 0) && (f.DailyFee == nil || *f.DailyFee == 0):
		return "Ücretli tesiste saatlik ya da günlük ücret tanımlanmalı"
	case f.MaintenanceMode && f.MaintenanceNote == "":
		return "Bakım kipinde sakinlere gösterilecek bakım notu zorunludur"
	}
	seen := map[int]bool{}
	for _, d := range f.AvailableDays {
		if d < 0 || d > 6 || seen[d] {
			return "Açık günler 0 (Pazar) ile 6 (Cumartesi) arasında ve tekrarsız olmalı"
		}
		seen[d] = true
	}
	return ""
}

func bindFacility(c *gin.Context) (*facilityInput, bool) {
	var in facilityInput
	dec := json.NewDecoder(c.Request.Body)
	dec.UseNumber()
	if err := dec.Decode(&in); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Geçersiz istek gövdesi"})
		return nil, false
	}
	return &in, true
}

// createFacility: POST /facilities (yönetim).
func createFacility(repo *repository.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		in, ok := bindFacility(c)
		if !ok {
			return
		}
		f := defaultFacility()
		if reason := in.apply(f); reason != "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": reason})
			return
		}
		id, err := repo.SaveFacility(c.Request.Context(), c.GetString("property_id"), "", f)
		if err != nil {
			fail(c, err, "tesis ekleme")
			return
		}
		f.ID = id
		c.JSON(http.StatusCreated, f)
	}
}

// updateFacility: PATCH /facilities/:id (yönetim). Mevcut rezervasyonlar değişmez.
func updateFacility(repo *repository.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		in, ok := bindFacility(c)
		if !ok {
			return
		}
		propertyID := c.GetString("property_id")
		f, err := repo.GetFacility(c.Request.Context(), propertyID, c.Param("id"))
		if err != nil {
			fail(c, err, "tesis okuma")
			return
		}
		if reason := in.apply(f); reason != "" {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": reason})
			return
		}
		if _, err := repo.SaveFacility(c.Request.Context(), propertyID, f.ID, f); err != nil {
			fail(c, err, "tesis güncelleme")
			return
		}
		c.JSON(http.StatusOK, gin.H{"facility": f,
			"note": "Yeni kurallar yalnızca bundan sonraki rezervasyonlara uygulanır; mevcut rezervasyonlar değişmedi."})
	}
}
