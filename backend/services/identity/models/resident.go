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

// Activation, yöneticiye YALNIZCA BİR KEZ gösterilen etkinleştirme kodudur.
// SMS sağlayıcısı bağlı olmadığı için kodu sakine yönetici iletir.
type Activation struct {
	Code      string    `json:"activation_code"`
	Purpose   string    `json:"purpose"`
	ExpiresAt time.Time `json:"expires_at"`
	Note      string    `json:"note"`
}

// CreateResidentResult, sakin ekleme yanıtıdır.
type CreateResidentResult struct {
	*Resident
	Activation *Activation `json:"activation,omitempty"`
	// Invitation, kişi bu siteyle bağı olmayan mevcut bir hesapsa açılan davettir
	// (S-20). Bu durumda Resident boştur: bağ, kişi kabul edince kurulur.
	Invitation *Invitation `json:"invitation,omitempty"`
	Note       string      `json:"note,omitempty"`
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

// Invitation, sakin davetinin YÖNETİM görünümüdür (S-20, migration 032).
// Kişinin adı/e-postası bilerek yoktur; telefon, yöneticinin kendi girdiği değerdir.
type Invitation struct {
	ID          string     `json:"id"`
	UnitID      string     `json:"unit_id"`
	Unit        string     `json:"unit"`
	Phone       string     `json:"phone"`
	Role        string     `json:"role"`
	Status      string     `json:"status"` // PENDING, ACCEPTED, DECLINED, CANCELLED, EXPIRED
	CreatedAt   time.Time  `json:"created_at"`
	ExpiresAt   time.Time  `json:"expires_at"`
	RespondedAt *time.Time `json:"responded_at,omitempty"`
}

// MyInvitation, davet edilen kişinin kendi uygulamasında gördüğü davettir.
type MyInvitation struct {
	ID           string    `json:"id"`
	PropertyID   string    `json:"property_id"`
	PropertyName string    `json:"property_name"`
	Unit         string    `json:"unit"`
	Role         string    `json:"role"`
	CreatedAt    time.Time `json:"created_at"`
	ExpiresAt    time.Time `json:"expires_at"`
}
