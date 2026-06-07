package models

import "time"

// Resident kullanıcı + birim ilişkisi (resident_units) görünümü
type Resident struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	Phone     string    `json:"phone"`
	Email     string    `json:"email"`
	UnitID    string    `json:"unit_id"`
	Unit      string    `json:"unit"`
	Role      string    `json:"role"`
	IsActive  bool      `json:"is_active"`
	CreatedAt time.Time `json:"created_at"`
}

// CreateResidentInput yeni sakin ekleme isteği
type CreateResidentInput struct {
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	Phone     string `json:"phone" binding:"required"`
	Email     string `json:"email"`
	UnitID    string `json:"unit_id" binding:"required"`
	Role      string `json:"role" binding:"required"`
}

// UpdateResidentInput sakin güncelleme isteği (sadece resident_units alanları)
type UpdateResidentInput struct {
	Role     *string `json:"role"`
	IsActive *bool   `json:"is_active"`
}
