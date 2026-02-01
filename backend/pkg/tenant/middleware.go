package tenant

import (
	"context"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// TenantContextKey - Context key for tenant
type TenantContextKey string

const (
	ContextKeyTenant TenantContextKey = "tenant"
)

// TenantMiddleware - Her istekte tenant'ı belirle
func TenantMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		var tenant *Tenant
		var err error

		manager := GetManager()
		ctx := c.Request.Context()

		// 1. Header'dan tenant ID kontrolü (API kullanımı için)
		tenantID := c.GetHeader("X-Tenant-ID")
		if tenantID != "" {
			tenant, err = manager.GetTenant(ctx, tenantID)
			if err == nil {
				setTenantContext(c, tenant)
				c.Next()
				return
			}
		}

		// 2. Subdomain kontrolü (mavikent.siteeksen.com)
		host := c.Request.Host
		if strings.Contains(host, ".siteeksen.com") {
			parts := strings.Split(host, ".")
			if len(parts) >= 3 {
				slug := parts[0]
				tenant, err = manager.GetTenantBySlug(ctx, slug)
				if err == nil {
					setTenantContext(c, tenant)
					c.Next()
					return
				}
			}
		}

		// 3. Custom domain kontrolü
		tenant, err = manager.GetTenantByDomain(ctx, host)
		if err == nil {
			setTenantContext(c, tenant)
			c.Next()
			return
		}

		// Tenant bulunamadı
		c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
			"error": "Tenant not found",
			"code":  "TENANT_NOT_FOUND",
		})
	}
}

func setTenantContext(c *gin.Context, tenant *Tenant) {
	// Abonelik kontrolü
	if !tenant.IsActive() {
		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
			"error": "Subscription expired or suspended",
			"code":  "SUBSCRIPTION_INACTIVE",
		})
		return
	}

	// Context'e tenant ekle
	ctx := context.WithValue(c.Request.Context(), ContextKeyTenant, tenant)
	c.Request = c.Request.WithContext(ctx)
	c.Set("tenant", tenant)
	c.Set("tenant_id", tenant.ID)
	c.Set("property_id", tenant.ID) // property_id = tenant_id
}

// GetTenantFromContext - Context'ten tenant al
func GetTenantFromContext(ctx context.Context) *Tenant {
	tenant, ok := ctx.Value(ContextKeyTenant).(*Tenant)
	if !ok {
		return nil
	}
	return tenant
}

// GetTenantFromGin - Gin context'ten tenant al
func GetTenantFromGin(c *gin.Context) *Tenant {
	tenant, exists := c.Get("tenant")
	if !exists {
		return nil
	}
	return tenant.(*Tenant)
}

// RequireFeature - Özellik gerektiren endpoint'ler için middleware
func RequireFeature(feature string) gin.HandlerFunc {
	return func(c *gin.Context) {
		tenant := GetTenantFromGin(c)
		if tenant == nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Tenant not found in context",
			})
			return
		}

		if !tenant.HasFeature(feature) {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error":   "Feature not available in your plan",
				"code":    "FEATURE_NOT_AVAILABLE",
				"feature": feature,
				"plan":    tenant.SubscriptionPlan,
			})
			return
		}

		c.Next()
	}
}

// EnforceLimits - Limit kontrolü middleware
func EnforceLimits(resourceType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		tenant := GetTenantFromGin(c)
		if tenant == nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Tenant not found",
			})
			return
		}

		// TODO: Veritabanından mevcut kaynak sayısını al
		// currentCount := getResourceCount(tenant.ID, resourceType)

		// Şimdilik geç
		c.Next()
	}
}
