// Package models, ziyaretçi yönetimi veri yapılarını tanımlar.
//
// KVKK NOTU: Ziyaretçi kaydı, ziyaret edilen kişi hakkında da bilgi üretir
// (kim, kimi, ne zaman ziyaret etti). Bu yüzden kayıtlar yalnızca yönetim ve
// güvenlik personeline, sakinlere ise YALNIZCA kendi dairelerine ait olanlar
// gösterilir.
package models

import "time"

// Ziyaretçi durumları.
const (
	StatusExpected   = "EXPECTED"    // ön kayıt yapıldı, henüz gelmedi
	StatusCheckedIn  = "CHECKED_IN"  // siteye giriş yaptı
	StatusCheckedOut = "CHECKED_OUT" // siteden ayrıldı
	StatusCancelled  = "CANCELLED"
	StatusNoShow     = "NO_SHOW"
)

// Visitor, ziyaretçi kaydıdır.
type Visitor struct {
	ID         string `json:"id"`
	PropertyID string `json:"property_id"`
	UnitID     string `json:"unit_id,omitempty"`
	UnitName   string `json:"unit_name,omitempty"`

	VisitorName    string `json:"visitor_name"`
	VisitorPhone   string `json:"visitor_phone,omitempty"`
	VisitorCompany string `json:"visitor_company,omitempty"`
	// VisitorIDNumber (kimlik no) liste yanıtlarında MASKELİ döner.
	VisitorIDNumber string `json:"visitor_id_number,omitempty"`
	VehiclePlate    string `json:"vehicle_plate,omitempty"`

	Purpose     string     `json:"purpose,omitempty"`
	VisitReason string     `json:"visit_reason,omitempty"`
	ExpectedAt  *time.Time `json:"expected_at,omitempty"`

	CheckedInAt  *time.Time `json:"checked_in_at,omitempty"`
	CheckedOutAt *time.Time `json:"checked_out_at,omitempty"`

	Status string `json:"status"`
	// DurationMinutes yalnızca çıkış yapılmışsa doludur.
	DurationMinutes *int `json:"duration_minutes,omitempty"`

	Notes     string    `json:"notes,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateVisitorInput, ziyaretçi ön kaydıdır.
type CreateVisitorInput struct {
	UnitID          string `json:"unit_id"`
	VisitorName     string `json:"visitor_name" binding:"required"`
	VisitorPhone    string `json:"visitor_phone"`
	VisitorIDNumber string `json:"visitor_id_number"`
	VisitorCompany  string `json:"visitor_company"`
	VehiclePlate    string `json:"vehicle_plate"`
	Purpose         string `json:"purpose"`
	VisitReason     string `json:"visit_reason"`
	// ExpectedAt RFC3339 biçiminde beklenen geliş zamanı.
	ExpectedAt string `json:"expected_at"`
	Notes      string `json:"notes"`
}

// Summary, ziyaretçi özetidir.
type Summary struct {
	CurrentlyInside int `json:"currently_inside"`
	TodayExpected   int `json:"today_expected"`
	TodayCheckedIn  int `json:"today_checked_in"`
	TodayCheckedOut int `json:"today_checked_out"`
}
