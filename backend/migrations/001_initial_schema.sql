-- SiteEksen Veritabanı Şeması
-- Migration: 001_initial_schema.sql

-- UUID extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. ANA VARLIKLAR (Core Entities)
-- =====================================================

-- Siteler/Apartmanlar
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100),
    postal_code VARCHAR(10),
    total_share_ratio DECIMAL(12,4) DEFAULT 0,
    total_units INT DEFAULT 0,
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Bloklar
CREATE TABLE blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    floor_count INT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Bağımsız Bölümler (Daireler/Dükkanlar)
CREATE TABLE units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    block_id UUID REFERENCES blocks(id),
    block VARCHAR(50),
    floor INT NOT NULL,
    door_number VARCHAR(20) NOT NULL,
    share_ratio DECIMAL(10,4) NOT NULL, -- Arsa payı
    gross_area_m2 DECIMAL(8,2),
    net_area_m2 DECIMAL(8,2),
    unit_type VARCHAR(20) DEFAULT 'APARTMENT', -- APARTMENT, SHOP, OFFICE, PARKING
    is_commercial BOOLEAN DEFAULT false,
    is_ground_floor BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(property_id, block, door_number)
);

CREATE INDEX idx_units_property ON units(property_id);

-- =====================================================
-- 2. KULLANICILAR VE ROLLER
-- =====================================================

-- Kullanıcılar
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tc_encrypted VARCHAR(500), -- AES-256 şifreli TCKN
    tc_hash VARCHAR(100), -- SHA-256 hash (arama için)
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    phone_encrypted VARCHAR(500),
    email VARCHAR(200),
    password_hash VARCHAR(255) NOT NULL,
    active_property_id UUID REFERENCES properties(id),
    roles TEXT[] DEFAULT ARRAY['RESIDENT'],
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_tc_hash ON users(tc_hash);

-- Sakin-Daire İlişkisi (N:N)
CREATE TABLE resident_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resident_id UUID REFERENCES users(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- OWNER, TENANT, PROXY (Vekil)
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(resident_id, unit_id, role)
);

CREATE INDEX idx_resident_units_resident ON resident_units(resident_id);
CREATE INDEX idx_resident_units_unit ON resident_units(unit_id);

-- Yönetim Kadrosu
CREATE TABLE management_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    title VARCHAR(100) NOT NULL, -- Yönetim Kurulu Başkanı, Bşk. Yrd., Denetçi
    phone VARCHAR(20),
    email VARCHAR(200),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 3. FİNANSAL YAPILAR
-- =====================================================

-- Hesap Planı (Çift taraflı muhasebe)
CREATE TABLE chart_of_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) NOT NULL, -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
    parent_account_id UUID REFERENCES chart_of_accounts(id),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(property_id, account_code)
);

-- Gider Kalemleri
CREATE TABLE expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    distribution_type VARCHAR(20) NOT NULL, -- SHARE_RATIO, EQUAL, AREA_M2, CUSTOM, METER_READING
    applies_to_commercial BOOLEAN DEFAULT true,
    applies_to_ground_floor BOOLEAN DEFAULT true,
    custom_formula JSONB,
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Aylık Tahakkuklar
CREATE TABLE monthly_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
    period_year INT NOT NULL,
    period_month INT NOT NULL,
    base_amount DECIMAL(12,2) NOT NULL,
    late_fee DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    due_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, PARTIAL, PAID, OVERDUE
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(unit_id, period_year, period_month)
);

CREATE INDEX idx_assessments_unit ON monthly_assessments(unit_id);
CREATE INDEX idx_assessments_status ON monthly_assessments(status);
CREATE INDEX idx_assessments_period ON monthly_assessments(period_year, period_month);

-- Tahakkuk Detayları
CREATE TABLE assessment_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID REFERENCES monthly_assessments(id) ON DELETE CASCADE,
    expense_category_id UUID REFERENCES expense_categories(id),
    amount DECIMAL(12,2) NOT NULL,
    calculation_basis VARCHAR(100),
    share_value DECIMAL(10,4)
);

-- Yevmiye Defteri (Ledger)
CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    transaction_date DATE NOT NULL,
    document_number VARCHAR(50),
    document_type VARCHAR(30), -- AIDAT, TAHSILAT, FATURA, SAYAC, DUZELTME
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_ledger_property ON ledger_entries(property_id);
CREATE INDEX idx_ledger_date ON ledger_entries(transaction_date);

-- Yevmiye Kalemleri
CREATE TABLE ledger_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID REFERENCES ledger_entries(id) ON DELETE CASCADE,
    account_id UUID REFERENCES chart_of_accounts(id),
    unit_id UUID REFERENCES units(id),
    debit_amount DECIMAL(14,2) DEFAULT 0,
    credit_amount DECIMAL(14,2) DEFAULT 0,
    CONSTRAINT chk_debit_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (credit_amount > 0 AND debit_amount = 0)
    )
);

-- Ödemeler
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    unit_id UUID REFERENCES units(id),
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL, -- CREDIT_CARD, BANK_TRANSFER, CASH, SAVED_CARD
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, COMPLETED, FAILED, REFUNDED
    transaction_id VARCHAR(100),
    gateway_response JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);

-- Ödeme-Aidat İlişkisi
CREATE TABLE payment_assessments (
    payment_id UUID REFERENCES payments(id) ON DELETE CASCADE,
    assessment_id UUID REFERENCES monthly_assessments(id),
    amount DECIMAL(12,2),
    PRIMARY KEY (payment_id, assessment_id)
);

-- =====================================================
-- 4. SAYAÇ VE TÜKETİM
-- =====================================================

-- Sayaçlar
CREATE TABLE meters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
    meter_type VARCHAR(20) NOT NULL, -- HEAT, WATER_COLD, WATER_HOT, GAS, ELECTRIC
    serial_number VARCHAR(50) UNIQUE NOT NULL,
    brand VARCHAR(50),
    model VARCHAR(50),
    installation_date DATE,
    last_calibration_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_meters_unit ON meters(unit_id);

-- Sayaç Okumaları
CREATE TABLE meter_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meter_id UUID REFERENCES meters(id) ON DELETE CASCADE,
    reading_date DATE NOT NULL,
    previous_value DECIMAL(12,3) NOT NULL,
    current_value DECIMAL(12,3) NOT NULL,
    consumption DECIMAL(12,3) GENERATED ALWAYS AS (current_value - previous_value) STORED,
    reading_type VARCHAR(20) DEFAULT 'MANUAL', -- MANUAL, AUTOMATIC, ESTIMATED
    photo_evidence_url VARCHAR(500),
    reader_user_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_readings_meter ON meter_readings(meter_id);
CREATE INDEX idx_readings_date ON meter_readings(reading_date);

-- Tüketim Tarifeleri
CREATE TABLE consumption_tariffs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    meter_type VARCHAR(20) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    unit_price DECIMAL(10,4) NOT NULL,
    fixed_fee DECIMAL(10,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 18.00,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Tüketim Faturaları
CREATE TABLE consumption_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meter_reading_id UUID REFERENCES meter_readings(id),
    unit_id UUID REFERENCES units(id),
    meter_id UUID REFERENCES meters(id),
    tariff_id UUID REFERENCES consumption_tariffs(id),
    period_start DATE,
    period_end DATE,
    consumption_amount DECIMAL(12,3),
    unit_price DECIMAL(10,4),
    subtotal DECIMAL(12,2),
    tax_amount DECIMAL(12,2),
    total_amount DECIMAL(12,2),
    invoice_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 5. ARAÇLAR VE GÜVENLİK
-- =====================================================

-- Araçlar
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID REFERENCES units(id) ON DELETE CASCADE,
    resident_id UUID REFERENCES users(id),
    plate_number VARCHAR(20) NOT NULL,
    plate_encrypted VARCHAR(500), -- Şifreli plaka
    vehicle_type VARCHAR(20) DEFAULT 'CAR', -- CAR, MOTORCYCLE, TRUCK
    brand VARCHAR(50),
    model VARCHAR(50),
    year INT,
    color VARCHAR(30),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_vehicles_plate ON vehicles(plate_number);
CREATE INDEX idx_vehicles_unit ON vehicles(unit_id);

-- =====================================================
-- 6. İLETİŞİM VE TALEPLER
-- =====================================================

-- Duyurular
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50), -- GENERAL, MAINTENANCE, FINANCIAL, EMERGENCY
    priority VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    attachment_urls TEXT[],
    is_pinned BOOLEAN DEFAULT false,
    published_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_announcements_property ON announcements(property_id);

-- Duyuru Okunma Durumu
CREATE TABLE announcement_reads (
    announcement_id UUID REFERENCES announcements(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (announcement_id, user_id)
);

-- Talep Kategorileri
CREATE TABLE request_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id),
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    sla_hours INT DEFAULT 48, -- Çözüm süresi hedefi
    is_active BOOLEAN DEFAULT true
);

-- Talepler/Şikayetler
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES units(id),
    resident_id UUID REFERENCES users(id),
    category_id UUID REFERENCES request_categories(id),
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    location VARCHAR(200),
    priority VARCHAR(20) DEFAULT 'NORMAL',
    status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, IN_PROGRESS, RESOLVED, CLOSED
    assigned_to UUID REFERENCES users(id),
    photo_urls TEXT[],
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_requests_property ON requests(property_id);
CREATE INDEX idx_requests_status ON requests(status);
CREATE INDEX idx_requests_resident ON requests(resident_id);

-- Talep Yorumları
CREATE TABLE request_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES requests(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT false, -- Yönetim içi not
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- 7. DENETİM LOGLARI (KVKK/5651)
-- =====================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    user_ip INET,
    user_agent TEXT,
    action VARCHAR(50) NOT NULL, -- VIEW, CREATE, UPDATE, DELETE, EXPORT, LOGIN
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON audit_logs(user_id);
CREATE INDEX idx_audit_action ON audit_logs(action);
CREATE INDEX idx_audit_date ON audit_logs(created_at);

-- =====================================================
-- 8. BAKIŞ (VIEWS)
-- =====================================================

-- Daire Bakiyeleri
CREATE VIEW unit_balances AS
SELECT 
    u.id as unit_id,
    u.property_id,
    u.block || '-' || u.door_number as unit_name,
    COALESCE(SUM(ll.debit_amount), 0) as total_debit,
    COALESCE(SUM(ll.credit_amount), 0) as total_credit,
    COALESCE(SUM(ll.debit_amount), 0) - COALESCE(SUM(ll.credit_amount), 0) as balance
FROM units u
LEFT JOIN ledger_lines ll ON u.id = ll.unit_id
GROUP BY u.id, u.property_id, u.block, u.door_number;

-- Aylık Tahsilat Özeti
CREATE VIEW monthly_collection_summary AS
SELECT 
    ma.property_id,
    ma.period_year,
    ma.period_month,
    COUNT(*) as total_units,
    SUM(ma.total_amount) as total_assessed,
    SUM(ma.paid_amount) as total_collected,
    SUM(ma.total_amount) - SUM(ma.paid_amount) as total_outstanding,
    COUNT(*) FILTER (WHERE ma.status = 'PAID') as paid_count,
    COUNT(*) FILTER (WHERE ma.status = 'OVERDUE') as overdue_count
FROM monthly_assessments ma
GROUP BY ma.property_id, ma.period_year, ma.period_month;
