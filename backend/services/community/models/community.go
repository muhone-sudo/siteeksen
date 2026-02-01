package models

import "time"

// Announcement - Duyuru modeli
type Announcement struct {
	ID         string    `json:"id"`
	PropertyID string    `json:"property_id"`
	Title      string    `json:"title"`
	Content    string    `json:"content"`
	Category   string    `json:"category"` // MAINTENANCE, PAYMENT, INFO, EMERGENCY
	Priority   string    `json:"priority"` // LOW, NORMAL, HIGH, URGENT
	IsPinned   bool      `json:"is_pinned"`
	CreatedBy  string    `json:"created_by"`
	CreatedAt  time.Time `json:"created_at"`
	ExpiresAt  *time.Time `json:"expires_at,omitempty"`
}

// AnnouncementRead - Duyuru okuma kaydı
type AnnouncementRead struct {
	ID             string    `json:"id"`
	AnnouncementID string    `json:"announcement_id"`
	UserID         string    `json:"user_id"`
	ReadAt         time.Time `json:"read_at"`
}

// Survey - Anket modeli
type Survey struct {
	ID          string       `json:"id"`
	PropertyID  string       `json:"property_id"`
	Title       string       `json:"title"`
	Description string       `json:"description"`
	Options     []SurveyOption `json:"options"`
	Status      string       `json:"status"` // DRAFT, ACTIVE, CLOSED
	CreatedBy   string       `json:"created_by"`
	CreatedAt   time.Time    `json:"created_at"`
	EndsAt      time.Time    `json:"ends_at"`
}

// SurveyOption - Anket seçeneği
type SurveyOption struct {
	ID       string `json:"id"`
	SurveyID string `json:"survey_id"`
	Text     string `json:"text"`
	Votes    int    `json:"votes"`
}

// SurveyVote - Anket oyu
type SurveyVote struct {
	ID       string    `json:"id"`
	SurveyID string    `json:"survey_id"`
	OptionID string    `json:"option_id"`
	UserID   string    `json:"user_id"`
	VotedAt  time.Time `json:"voted_at"`
}

// Bulletin - İlan panosu
type Bulletin struct {
	ID          string     `json:"id"`
	PropertyID  string     `json:"property_id"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Category    string     `json:"category"` // SALE, RENT, SERVICE, LOST_FOUND, OTHER
	ImageURLs   []string   `json:"image_urls,omitempty"`
	ContactInfo string     `json:"contact_info"`
	CreatedBy   string     `json:"created_by"`
	CreatedAt   time.Time  `json:"created_at"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	Status      string     `json:"status"` // ACTIVE, EXPIRED, REMOVED
}

// Facility - Ortak alan
type Facility struct {
	ID          string `json:"id"`
	PropertyID  string `json:"property_id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Capacity    int    `json:"capacity"`
	HourlyFee   int    `json:"hourly_fee"` // 0 = ücretsiz
	IsActive    bool   `json:"is_active"`
	Rules       string `json:"rules"`
}

// Reservation - Rezervasyon
type Reservation struct {
	ID         string    `json:"id"`
	FacilityID string    `json:"facility_id"`
	UserID     string    `json:"user_id"`
	Date       string    `json:"date"` // YYYY-MM-DD
	StartTime  string    `json:"start_time"` // HH:MM
	EndTime    string    `json:"end_time"`
	Status     string    `json:"status"` // PENDING, CONFIRMED, CANCELLED
	CreatedAt  time.Time `json:"created_at"`
}
