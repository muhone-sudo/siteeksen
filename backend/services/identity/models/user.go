package models

import "time"

// User veritabanı modeli
type User struct {
	ID               string     `json:"id"`
	TCEncrypted      string     `json:"-"`
	TCHash           string     `json:"-"`
	FirstName        string     `json:"first_name"`
	LastName         string     `json:"last_name"`
	Phone            string     `json:"phone"`
	PhoneEncrypted   string     `json:"-"`
	Email            string     `json:"email"`
	PasswordHash     string     `json:"-"`
	ActivePropertyID string     `json:"active_property_id"`
	Roles            []string   `json:"roles"`
	KVKKConsentAt    *time.Time `json:"kvkk_consent_at"`
	CreatedAt        time.Time  `json:"created_at"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

// UserProperty kullanıcının bağlı olduğu site
type UserProperty struct {
	PropertyID   string `json:"property_id"`
	PropertyName string `json:"property_name"`
	UnitID       string `json:"unit_id"`
	UnitName     string `json:"unit_name"`
	Role         string `json:"role"` // OWNER, TENANT, PROXY
}

// UserResponse API yanıtı için kullanıcı.
//
// `ActivePropertyID` ve `Roles` alanları, istemcinin (admin paneli / mobil) hangi
// ekranları gösterebileceğine karar verebilmesi için ZORUNLUDUR. Bu alanlar
// yanıtta yokken panel, oturumda rol bulamadığı için giriş yapan herkesi
// "yetkiniz yok" sayfasına yönlendiriyordu.
//
// Roller AKTİF SİTEYE göre çözülür (bkz. repository.GetPropertyRoles); yani bu
// alan jetondaki `roles` claim'i ile birebir aynı kümedir. İstemci bu listeye
// güvenerek YETKİ VERMEZ — yalnızca arayüzü şekillendirir; asıl kontrol
// sunucudadır (`pkg/middleware.RequireRole`).
type UserResponse struct {
	ID                  string         `json:"id"`
	FirstName           string         `json:"first_name"`
	LastName            string         `json:"last_name"`
	Phone               string         `json:"phone"`
	Email               string         `json:"email"`
	ActivePropertyID    string         `json:"active_property_id"`
	Roles               []string       `json:"roles"`
	Properties          []UserProperty `json:"properties"`
	KVKKConsentRequired bool           `json:"kvkk_consent_required"`
}

// Property site/apartman modeli
type Property struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	Type            string    `json:"type"` // SITE, APARTMENT, BUILDING
	Address         string    `json:"address"`
	City            string    `json:"city"`
	TotalShareRatio float64   `json:"total_share_ratio"`
	Settings        string    `json:"settings"` // JSONB
	CreatedAt       time.Time `json:"created_at"`
}

// CreatePropertyRequest yeni site oluşturma isteği
type CreatePropertyRequest struct {
	Name     string `json:"name" binding:"required"`
	Type     string `json:"type"` // SITE, APARTMENT, BUILDING — boşsa SITE varsayılır
	Address  string `json:"address" binding:"required"`
	City     string `json:"city" binding:"required"`
	District string `json:"district"`
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
