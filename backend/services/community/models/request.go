package models

import "time"

// Talep durumları
const (
	StatusOpen       = "OPEN"
	StatusInProgress = "IN_PROGRESS"
	StatusResolved   = "RESOLVED"
	StatusClosed     = "CLOSED"
)

// Request bir bakım/arıza talebini temsil eder
type Request struct {
	ID              string     `json:"id"`
	PropertyID      string     `json:"property_id"`
	UnitID          *string    `json:"unit_id"`
	ResidentID      string     `json:"resident_id"`
	CategoryID      *string    `json:"category_id"`
	TicketNumber    string     `json:"ticket_number"`
	Title           string     `json:"title"`
	Description     string     `json:"description"`
	Location        string     `json:"location"`
	Priority        string     `json:"priority"`
	Status          string     `json:"status"`
	PhotoURLs       []string   `json:"photo_urls"`
	ResolvedAt      *time.Time `json:"resolved_at"`
	ClosedAt        *time.Time `json:"closed_at"`
	UserConfirmedAt *time.Time `json:"user_confirmed_at"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// CreateRequestInput yeni talep oluşturma isteği
type CreateRequestInput struct {
	CategoryID  string   `json:"category_id"`
	Title       string   `json:"title" binding:"required"`
	Description string   `json:"description" binding:"required"`
	Location    string   `json:"location"`
	Photos      []string `json:"photos"`
	Priority    string   `json:"priority"`
}

// UpdateStatusInput yönetici talep durumu güncelleme isteği
type UpdateStatusInput struct {
	Status string `json:"status" binding:"required"`
}

// ConfirmResolutionInput sakin onay/red isteği
type ConfirmResolutionInput struct {
	Approved bool `json:"approved"`
}
