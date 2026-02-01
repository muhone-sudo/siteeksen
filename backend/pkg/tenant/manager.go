package tenant

import (
	"context"
	"fmt"
	"sync"
)

// Tenant - Kiracı (Site Yönetimi) bilgileri
type Tenant struct {
	ID                string             `json:"id"`
	Name              string             `json:"name"`
	Slug              string             `json:"slug"` // subdomain için: mavikent.siteeksen.com
	CustomDomain      string             `json:"custom_domain,omitempty"` // mavikent-siteyonetimi.com
	SubscriptionPlan  string             `json:"subscription_plan"` // STARTER, PRO, ENTERPRISE
	SubscriptionStatus string            `json:"subscription_status"` // ACTIVE, TRIAL, SUSPENDED
	MaxUnits          int                `json:"max_units"` // Plan limiti
	MaxUsers          int                `json:"max_users"`
	Features          []string           `json:"features"` // Aktif özellikler
	Settings          *TenantSettings    `json:"settings"`
	Branding          *TenantBranding    `json:"branding,omitempty"`
	CreatedAt         string             `json:"created_at"`
	ExpiresAt         string             `json:"expires_at,omitempty"`
}

// TenantSettings - Kiracı ayarları
type TenantSettings struct {
	Timezone           string `json:"timezone"`
	Currency           string `json:"currency"`
	Language           string `json:"language"`
	DateFormat         string `json:"date_format"`
	AssessmentDueDay   int    `json:"assessment_due_day"` // Aidat son ödeme günü
	LateFeePercentage  float64 `json:"late_fee_percentage"`
	MeterReadingDeadline int  `json:"meter_reading_deadline"` // Ay içinde günü
	EnableReservations bool   `json:"enable_reservations"`
	EnableSurveys      bool   `json:"enable_surveys"`
	EnableBulletins    bool   `json:"enable_bulletins"`
}

// TenantBranding - Marka özelleştirme
type TenantBranding struct {
	LogoURL       string `json:"logo_url,omitempty"`
	PrimaryColor  string `json:"primary_color"`
	SecondaryColor string `json:"secondary_color"`
	AppName       string `json:"app_name,omitempty"` // Özel uygulama adı
}

// SubscriptionPlan - Abonelik planı
type SubscriptionPlan struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	PriceMonthly int     `json:"price_monthly"` // TL
	PriceYearly int      `json:"price_yearly"`
	MaxUnits    int      `json:"max_units"`
	MaxUsers    int      `json:"max_users"`
	Features    []string `json:"features"`
}

// GetPlans - Mevcut planlar
func GetPlans() []SubscriptionPlan {
	return []SubscriptionPlan{
		{
			ID:           "starter",
			Name:         "Başlangıç",
			PriceMonthly: 299,
			PriceYearly:  2990,
			MaxUnits:     50,
			MaxUsers:     100,
			Features:     []string{"assessments", "payments", "announcements", "requests"},
		},
		{
			ID:           "pro",
			Name:         "Profesyonel",
			PriceMonthly: 599,
			PriceYearly:  5990,
			MaxUnits:     200,
			MaxUsers:     500,
			Features:     []string{"assessments", "payments", "announcements", "requests", "meters", "reservations", "surveys", "reports"},
		},
		{
			ID:           "enterprise",
			Name:         "Kurumsal",
			PriceMonthly: 1499,
			PriceYearly:  14990,
			MaxUnits:     -1, // Sınırsız
			MaxUsers:     -1,
			Features:     []string{"all", "custom_domain", "api_access", "dedicated_support", "sla"},
		},
	}
}

// TenantManager - Kiracı yöneticisi
type TenantManager struct {
	tenants map[string]*Tenant
	mu      sync.RWMutex
}

var (
	manager *TenantManager
	once    sync.Once
)

// GetManager - Singleton tenant manager
func GetManager() *TenantManager {
	once.Do(func() {
		manager = &TenantManager{
			tenants: make(map[string]*Tenant),
		}
	})
	return manager
}

// GetTenant - Kiracı bilgisi getir
func (m *TenantManager) GetTenant(ctx context.Context, tenantID string) (*Tenant, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	tenant, ok := m.tenants[tenantID]
	if !ok {
		return nil, fmt.Errorf("tenant not found: %s", tenantID)
	}
	return tenant, nil
}

// GetTenantBySlug - Subdomain ile kiracı bul
func (m *TenantManager) GetTenantBySlug(ctx context.Context, slug string) (*Tenant, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, tenant := range m.tenants {
		if tenant.Slug == slug {
			return tenant, nil
		}
	}
	return nil, fmt.Errorf("tenant not found for slug: %s", slug)
}

// GetTenantByDomain - Custom domain ile kiracı bul
func (m *TenantManager) GetTenantByDomain(ctx context.Context, domain string) (*Tenant, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, tenant := range m.tenants {
		if tenant.CustomDomain == domain {
			return tenant, nil
		}
	}
	return nil, fmt.Errorf("tenant not found for domain: %s", domain)
}

// RegisterTenant - Yeni kiracı kaydet
func (m *TenantManager) RegisterTenant(tenant *Tenant) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.tenants[tenant.ID]; exists {
		return fmt.Errorf("tenant already exists: %s", tenant.ID)
	}

	m.tenants[tenant.ID] = tenant
	return nil
}

// HasFeature - Kiracının özelliği var mı kontrol et
func (t *Tenant) HasFeature(feature string) bool {
	for _, f := range t.Features {
		if f == feature || f == "all" {
			return true
		}
	}
	return false
}

// IsActive - Abonelik aktif mi
func (t *Tenant) IsActive() bool {
	return t.SubscriptionStatus == "ACTIVE" || t.SubscriptionStatus == "TRIAL"
}

// WithinLimits - Limit kontrolü
func (t *Tenant) WithinLimits(currentUnits, currentUsers int) bool {
	if t.MaxUnits != -1 && currentUnits >= t.MaxUnits {
		return false
	}
	if t.MaxUsers != -1 && currentUsers >= t.MaxUsers {
		return false
	}
	return true
}
