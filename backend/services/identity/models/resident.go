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
	// EndDate: ilişik kesme (ayrılış) tarihi; pasifleştirmede yazılır (beşinci tur B7).
	EndDate *time.Time `json:"end_date,omitempty"`
	// IsOccupant: bu kayıt dairede oturan tarafta mı (kiracı, hane üyesi ya da kiracısız dairede oturan malik) — 067.
	IsOccupant bool `json:"is_occupant"`
}

// Activation, yöneticiye YALNIZCA BİR KEZ gösterilen etkinleştirme kodudur.
// SMS sağlayıcısı bağlı olmadığı için kodu sakine yönetici iletir.
type Activation struct {
	Code      string    `json:"activation_code"`
	Purpose   string    `json:"purpose"`
	ExpiresAt time.Time `json:"expires_at"`
	Note      string    `json:"note"`
	// SMS, kodun SMS ile iletim sonucudur (sağlayıcı yoksa NOT_CONFIGURED).
	SMS any `json:"sms,omitempty"`
	// Email, kodun e-postayla (yedek kanal) iletim sonucudur.
	Email any `json:"email,omitempty"`
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
	// EndDate: ayrılış tarihi (YYYY-AA-GG); yalnızca is_active=false ile verilir, boşsa bugün (B7).
	EndDate *string `json:"end_date"`
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
