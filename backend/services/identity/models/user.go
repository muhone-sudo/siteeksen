package models

import "time"

// User veritabanı modeli
type User struct {
	ID               string    `json:"id"`
	TCEncrypted      string    `json:"-"`
	TCHash           string    `json:"-"`
	FirstName        string    `json:"first_name"`
	LastName         string    `json:"last_name"`
	Phone            string    `json:"phone"`
	PhoneEncrypted   string    `json:"-"`
	Email            string    `json:"email"`
	PasswordHash     string    `json:"-"`
	ActivePropertyID string    `json:"active_property_id"`
	Roles            []string  `json:"roles"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

// UserProperty kullanıcının bağlı olduğu site
type UserProperty struct {
	PropertyID   string `json:"property_id"`
	PropertyName string `json:"property_name"`
	UnitID       string `json:"unit_id"`
	UnitName     string `json:"unit_name"`
	Role         string `json:"role"` // OWNER, TENANT, PROXY
}

// UserResponse API yanıtı için kullanıcı
type UserResponse struct {
	ID         string         `json:"id"`
	FirstName  string         `json:"first_name"`
	LastName   string         `json:"last_name"`
	Phone      string         `json:"phone"`
	Email      string         `json:"email"`
	Properties []UserProperty `json:"properties"`
}

// Property site/apartman modeli
type Property struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	Address         string    `json:"address"`
	City            string    `json:"city"`
	TotalShareRatio float64   `json:"total_share_ratio"`
	Settings        string    `json:"settings"` // JSONB
	CreatedAt       time.Time `json:"created_at"`
}

// Unit bağımsız bölüm modeli
type Unit struct {
	ID           string  `json:"id"`
	PropertyID   string  `json:"property_id"`
	Block        string  `json:"block"`
	Floor        int     `json:"floor"`
	DoorNumber   string  `json:"door_number"`
	ShareRatio   float64 `json:"share_ratio"`
	GrossAreaM2  float64 `json:"gross_area_m2"`
	UnitType     string  `json:"unit_type"`
	IsCommercial bool    `json:"is_commercial"`
}
