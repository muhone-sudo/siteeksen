-- Multi-tenant için ek tablolar
-- Migration 003

-- Tenant (Site Yönetimi) tablosu
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL, -- subdomain için
    custom_domain VARCHAR(255) UNIQUE,
    subscription_plan VARCHAR(50) NOT NULL DEFAULT 'starter', -- starter, pro, enterprise
    subscription_status VARCHAR(50) NOT NULL DEFAULT 'trial', -- trial, active, suspended, cancelled
    stripe_customer_id VARCHAR(255),
    stripe_subscription_id VARCHAR(255),
    max_units INTEGER NOT NULL DEFAULT 50,
    max_users INTEGER NOT NULL DEFAULT 100,
    features JSONB DEFAULT '[]'::jsonb,
    settings JSONB DEFAULT '{}'::jsonb,
    branding JSONB DEFAULT '{}'::jsonb,
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_custom_domain ON tenants(custom_domain);
CREATE INDEX idx_tenants_subscription_status ON tenants(subscription_status);

-- Property tablosuna tenant_id ekle (mevcut property = tenant)
ALTER TABLE properties ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id);

-- Fatura tablosu
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    stripe_invoice_id VARCHAR(255),
    amount_total INTEGER NOT NULL, -- Kuruş cinsinden
    currency VARCHAR(10) DEFAULT 'TRY',
    status VARCHAR(50) NOT NULL, -- draft, open, paid, void, uncollectible
    period_start TIMESTAMP WITH TIME ZONE,
    period_end TIMESTAMP WITH TIME ZONE,
    pdf_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    paid_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Kullanım metrikleri
CREATE TABLE IF NOT EXISTS usage_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    metric_type VARCHAR(100) NOT NULL, -- units, users, sms_sent, storage_mb
    metric_value INTEGER NOT NULL,
    recorded_at DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE(tenant_id, metric_type, recorded_at)
);

CREATE INDEX idx_usage_metrics_tenant ON usage_metrics(tenant_id, recorded_at);

-- Audit log (tenant bazlı)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- CREATE, UPDATE, DELETE, LOGIN, etc.
    entity_type VARCHAR(100), -- user, assessment, payment, etc.
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id, created_at);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);

-- Varsayılan tenant oluştur (demo)
INSERT INTO tenants (id, name, slug, subscription_plan, subscription_status, max_units, max_users, features, settings)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Mavi Kent Sitesi',
    'mavikent',
    'pro',
    'active',
    200,
    500,
    '["assessments", "payments", "announcements", "requests", "meters", "reservations", "surveys", "reports"]',
    '{"timezone": "Europe/Istanbul", "currency": "TRY", "language": "tr", "assessment_due_day": 10}'
) ON CONFLICT (slug) DO NOTHING;

-- Mevcut property'yi tenant'a bağla
UPDATE properties 
SET tenant_id = 'a0000000-0000-0000-0000-000000000001'
WHERE tenant_id IS NULL;
