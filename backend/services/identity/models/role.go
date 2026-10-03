package models

import "time"

// SiteRole, sitedeki bir yönetim görevlendirmesidir (property_roles).
// Yönetici, kurul üyesi ve denetçi KMK m.34/m.41 uyarınca kat malikleri kurulu
// kararıyla atanır; karar bilgisi decision_ref'te tutulur.
type SiteRole struct {
	ID            string     `json:"id"`
	UserID        string     `json:"user_id"`
	FirstName     string     `json:"first_name"`
	LastName      string     `json:"last_name"`
	Phone         string     `json:"phone"`
	Role          string     `json:"role"`
	ValidFrom     time.Time  `json:"valid_from"`
	ValidTo       *time.Time `json:"valid_to,omitempty"`
	DecisionRef   string     `json:"decision_ref"`
	Active        bool       `json:"active"`
	GrantedByName string     `json:"granted_by_name"`
	GrantedAt     time.Time  `json:"granted_at"`
}

// GrantRoleInput görevlendirme isteği. Ad/soyad yalnızca telefonla kayıtlı
// hesap yoksa (yeni hesap açılacaksa) gerekir.
type GrantRoleInput struct {
	Phone       string `json:"phone" binding:"required"`
	Role        string `json:"role" binding:"required"`
	FirstName   string `json:"first_name"`
	LastName    string `json:"last_name"`
	ValidFrom   string `json:"valid_from"` // YYYY-MM-DD, boşsa bugün
	ValidTo     string `json:"valid_to"`   // YYYY-MM-DD, boşsa süresiz
	DecisionRef string `json:"decision_ref"`
}

// GrantRoleResult görevlendirme sonucu; yeni hesap açıldıysa etkinleştirme kodu bir kez döner.
type GrantRoleResult struct {
	Role       *SiteRole   `json:"role"`
	Activation *Activation `json:"activation,omitempty"`
	Note       string      `json:"note,omitempty"`
}
