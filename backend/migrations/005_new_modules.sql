-- =====================================================
-- SiteEksen Kapsamlı Modül Migration
-- 15+ Yeni Modül için Veritabanı Şeması
-- =====================================================

-- =====================================================
-- 1. ZİYARETÇİ TAKİBİ
-- =====================================================

CREATE TABLE IF NOT EXISTS visitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    unit_id UUID REFERENCES units(id),
    
    -- Ziyaretçi bilgileri
    visitor_name VARCHAR(255) NOT NULL,
    visitor_phone VARCHAR(20),
    visitor_id_number VARCHAR(20),
    visitor_company VARCHAR(255),
    visitor_photo_url TEXT,
    
    -- Araç bilgisi (opsiyonel)
    vehicle_plate VARCHAR(20),
    
    -- Ziyaret detayları
    purpose VARCHAR(100),
    visit_reason TEXT,
    expected_at TIMESTAMP WITH TIME ZONE,
    
    -- Giriş/Çıkış
    checked_in_at TIMESTAMP WITH TIME ZONE,
    checked_in_by UUID REFERENCES users(id),
    checked_out_at TIMESTAMP WITH TIME ZONE,
    checked_out_by UUID REFERENCES users(id),
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'EXPECTED' 
        CHECK (status IN ('EXPECTED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED', 'NO_SHOW')),
    
    -- QR Kod
    qr_code VARCHAR(100) UNIQUE,
    qr_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Bildirimler
    resident_notified_at TIMESTAMP WITH TIME ZONE,
    notification_method VARCHAR(20),  -- SMS, PUSH, EMAIL
    
    -- Meta
    notes TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_visitors_property ON visitors(property_id);
CREATE INDEX idx_visitors_unit ON visitors(unit_id);
CREATE INDEX idx_visitors_status ON visitors(status);
CREATE INDEX idx_visitors_date ON visitors(expected_at);
CREATE INDEX idx_visitors_qr ON visitors(qr_code);

-- =====================================================
-- 2. ARAÇ / OTOPARK TAKİBİ
-- =====================================================

CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    unit_id UUID REFERENCES units(id),
    
    -- Sahip tipi
    owner_type VARCHAR(20) NOT NULL CHECK (owner_type IN ('RESIDENT', 'VISITOR', 'STAFF', 'SERVICE')),
    owner_id UUID,
    owner_name VARCHAR(255),
    
    -- Araç bilgileri
    plate VARCHAR(20) NOT NULL,
    brand VARCHAR(50),
    model VARCHAR(50),
    color VARCHAR(30),
    year INT,
    vehicle_type VARCHAR(20) DEFAULT 'CAR' CHECK (vehicle_type IN ('CAR', 'MOTORCYCLE', 'TRUCK', 'OTHER')),
    
    -- Park yeri
    parking_spot VARCHAR(20),
    parking_zone_id UUID,
    
    -- Geçiş sistemleri
    rfid_tag VARCHAR(100),
    hgs_tag VARCHAR(100),
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    is_primary BOOLEAN DEFAULT false,  -- Ana araç mı
    
    -- Meta
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_vehicles_plate_property ON vehicles(property_id, plate) WHERE is_active = true;
CREATE INDEX idx_vehicles_unit ON vehicles(unit_id);
CREATE INDEX idx_vehicles_owner ON vehicles(owner_type, owner_id);

-- Otopark Bölgeleri
CREATE TABLE IF NOT EXISTS parking_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    capacity INT NOT NULL DEFAULT 0,
    current_count INT DEFAULT 0,
    
    -- Ücretlendirme
    is_paid BOOLEAN DEFAULT false,
    hourly_fee DECIMAL(10,2),
    daily_fee DECIMAL(10,2),
    monthly_fee DECIMAL(10,2),
    
    -- Erişim
    is_visitor_allowed BOOLEAN DEFAULT true,
    is_staff_allowed BOOLEAN DEFAULT true,
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Otopark Giriş/Çıkış Logları
CREATE TABLE IF NOT EXISTS parking_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    parking_zone_id UUID REFERENCES parking_zones(id),
    vehicle_id UUID REFERENCES vehicles(id),
    
    -- Plaka (vehicle_id olmasa bile)
    plate VARCHAR(20) NOT NULL,
    
    -- Giriş
    entry_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    entry_gate VARCHAR(50),
    entry_method VARCHAR(20),  -- RFID, PLATE_RECOGNITION, MANUAL, QR
    entry_photo_url TEXT,
    
    -- Çıkış
    exit_at TIMESTAMP WITH TIME ZONE,
    exit_gate VARCHAR(50),
    exit_method VARCHAR(20),
    exit_photo_url TEXT,
    
    -- Süre ve ücret
    duration_minutes INT,
    calculated_fee DECIMAL(10,2),
    paid_fee DECIMAL(10,2),
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parking_logs_property ON parking_logs(property_id);
CREATE INDEX idx_parking_logs_vehicle ON parking_logs(vehicle_id);
CREATE INDEX idx_parking_logs_entry ON parking_logs(entry_at);
CREATE INDEX idx_parking_logs_plate ON parking_logs(plate);

-- =====================================================
-- 3. REZERVASYON SİSTEMİ
-- =====================================================

-- Tesisler
CREATE TABLE IF NOT EXISTS facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- Temel bilgiler
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),  -- POOL, GYM, TENNIS, MEETING_ROOM, BBQ, SAUNA, OTHER
    photo_urls JSONB DEFAULT '[]',
    
    -- Kapasite
    capacity INT,
    min_capacity INT DEFAULT 1,
    
    -- Fiyatlandırma
    is_paid BOOLEAN DEFAULT false,
    hourly_fee DECIMAL(10,2),
    daily_fee DECIMAL(10,2),
    deposit_amount DECIMAL(10,2),
    
    -- Çalışma saatleri
    available_from TIME DEFAULT '08:00',
    available_to TIME DEFAULT '22:00',
    available_days INT[] DEFAULT '{1,2,3,4,5,6,0}',  -- 0=Pazar
    
    -- Rezervasyon kuralları
    min_duration_minutes INT DEFAULT 60,
    max_duration_minutes INT DEFAULT 240,
    advance_booking_days INT DEFAULT 14,
    max_reservations_per_unit INT DEFAULT 2,  -- Haftalık
    buffer_minutes INT DEFAULT 15,  -- Rezervasyonlar arası
    
    -- Onay
    requires_approval BOOLEAN DEFAULT false,
    auto_approve_residents BOOLEAN DEFAULT true,
    
    -- Kurallar ve koşullar
    rules TEXT,
    terms TEXT,
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    maintenance_mode BOOLEAN DEFAULT false,
    maintenance_note TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facilities_property ON facilities(property_id);
CREATE INDEX idx_facilities_category ON facilities(category);

-- Rezervasyonlar
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    facility_id UUID NOT NULL REFERENCES facilities(id),
    unit_id UUID NOT NULL REFERENCES units(id),
    resident_id UUID NOT NULL REFERENCES users(id),
    
    -- Zaman
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INT,
    
    -- Detaylar
    guest_count INT DEFAULT 1,
    purpose TEXT,
    special_requests TEXT,
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'COMPLETED', 'NO_SHOW')),
    
    -- Ücret
    total_fee DECIMAL(10,2) DEFAULT 0,
    deposit_amount DECIMAL(10,2) DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'NOT_REQUIRED',
    payment_id UUID,
    
    -- Onay/Red
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Hatırlatıcı
    reminder_sent BOOLEAN DEFAULT false,
    reminder_sent_at TIMESTAMP WITH TIME ZONE,
    
    -- İptal
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancelled_by UUID REFERENCES users(id),
    cancellation_reason TEXT,
    refund_amount DECIMAL(10,2),
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reservations_property ON reservations(property_id);
CREATE INDEX idx_reservations_facility ON reservations(facility_id);
CREATE INDEX idx_reservations_unit ON reservations(unit_id);
CREATE INDEX idx_reservations_time ON reservations(start_time, end_time);
CREATE INDEX idx_reservations_status ON reservations(status);

-- Çakışma kontrolü için unique constraint
CREATE UNIQUE INDEX idx_reservations_no_overlap ON reservations(facility_id, start_time)
    WHERE status IN ('APPROVED', 'PENDING');

-- =====================================================
-- 4. BANKA ENTEGRASYONU
-- =====================================================

CREATE TABLE IF NOT EXISTS bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- Banka bilgileri
    bank_code VARCHAR(10) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    branch_code VARCHAR(10),
    branch_name VARCHAR(100),
    
    -- Hesap bilgileri
    iban VARCHAR(34) NOT NULL,
    account_number VARCHAR(20),
    account_name VARCHAR(255),
    currency VARCHAR(3) DEFAULT 'TRY',
    
    -- API erişim (şifreli)
    api_enabled BOOLEAN DEFAULT false,
    api_credentials_encrypted TEXT,
    api_last_error TEXT,
    
    -- Senkronizasyon
    last_sync_at TIMESTAMP WITH TIME ZONE,
    last_sync_status VARCHAR(20),
    sync_from_date DATE,
    
    -- Ayarlar
    is_primary BOOLEAN DEFAULT false,
    is_collection_account BOOLEAN DEFAULT true,  -- Tahsilat hesabı mı
    is_expense_account BOOLEAN DEFAULT true,     -- Gider hesabı mı
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_property ON bank_accounts(property_id);
CREATE UNIQUE INDEX idx_bank_accounts_iban ON bank_accounts(iban) WHERE is_active = true;

-- Banka İşlemleri (Havale/EFT)
CREATE TABLE IF NOT EXISTS bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id),
    
    -- İşlem bilgileri
    transaction_id VARCHAR(100),  -- Banka işlem ID
    transaction_date DATE NOT NULL,
    value_date DATE,
    
    -- Tutar
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TRY',
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('IN', 'OUT')),
    
    -- Gönderen/Alıcı
    counterparty_name VARCHAR(255),
    counterparty_iban VARCHAR(34),
    counterparty_bank VARCHAR(100),
    
    -- Açıklama
    description TEXT,
    reference_number VARCHAR(100),
    
    -- Eşleştirme
    is_matched BOOLEAN DEFAULT false,
    matched_type VARCHAR(20),  -- PAYMENT, EXPENSE, OTHER
    matched_id UUID,
    matched_at TIMESTAMP WITH TIME ZONE,
    matched_by UUID REFERENCES users(id),
    match_method VARCHAR(20),  -- AUTO, MANUAL
    match_confidence DECIMAL(3,2),  -- 0.00-1.00
    
    -- Ham veri
    raw_data JSONB,
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_transactions_property ON bank_transactions(property_id);
CREATE INDEX idx_bank_transactions_account ON bank_transactions(bank_account_id);
CREATE INDEX idx_bank_transactions_date ON bank_transactions(transaction_date);
CREATE INDEX idx_bank_transactions_matched ON bank_transactions(is_matched);
CREATE INDEX idx_bank_transactions_amount ON bank_transactions(amount, direction);

-- =====================================================
-- 5. SİTE İLAN PANOSU
-- =====================================================

CREATE TABLE IF NOT EXISTS bulletin_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    unit_id UUID REFERENCES units(id),
    author_id UUID NOT NULL REFERENCES users(id),
    
    -- İçerik
    category VARCHAR(50) NOT NULL 
        CHECK (category IN ('SALE', 'RENT', 'LOST_FOUND', 'HELP', 'SUGGESTION', 'CARPOOL', 'SERVICE', 'EVENT', 'OTHER')),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    photo_urls JSONB DEFAULT '[]',
    
    -- Fiyat (satılık/kiralık için)
    price DECIMAL(12,2),
    price_negotiable BOOLEAN DEFAULT true,
    
    -- Anonim
    is_anonymous BOOLEAN DEFAULT false,
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'CLOSED')),
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    -- Süre
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- İstatistikler
    view_count INT DEFAULT 0,
    contact_count INT DEFAULT 0,
    
    -- Meta
    is_pinned BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bulletin_posts_property ON bulletin_posts(property_id);
CREATE INDEX idx_bulletin_posts_category ON bulletin_posts(category);
CREATE INDEX idx_bulletin_posts_status ON bulletin_posts(status);
CREATE INDEX idx_bulletin_posts_author ON bulletin_posts(author_id);

-- İlan Yorumları
CREATE TABLE IF NOT EXISTS bulletin_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES bulletin_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id),
    parent_id UUID REFERENCES bulletin_comments(id),  -- Yanıtlar için
    
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    
    -- Durum
    is_deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID REFERENCES users(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bulletin_comments_post ON bulletin_comments(post_id);

-- İlan Özel Mesajları
CREATE TABLE IF NOT EXISTS bulletin_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES bulletin_posts(id),
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID NOT NULL REFERENCES users(id),
    
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bulletin_messages_post ON bulletin_messages(post_id);
CREATE INDEX idx_bulletin_messages_receiver ON bulletin_messages(receiver_id, is_read);

-- =====================================================
-- 6. ANKET / OYLAMA SİSTEMİ
-- =====================================================

CREATE TABLE IF NOT EXISTS surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- İçerik
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Tip
    survey_type VARCHAR(20) NOT NULL DEFAULT 'POLL'
        CHECK (survey_type IN ('POLL', 'SURVEY', 'VOTE', 'GENERAL_ASSEMBLY')),
    
    -- Ayarlar
    is_anonymous BOOLEAN DEFAULT true,
    is_weighted BOOLEAN DEFAULT false,  -- m² bazlı ağırlık
    allow_multiple BOOLEAN DEFAULT false,
    allow_comments BOOLEAN DEFAULT true,
    show_results_before_end BOOLEAN DEFAULT false,
    require_all_options BOOLEAN DEFAULT false,  -- Tüm seçenekleri değerlendirme
    
    -- Zamanlama
    starts_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITH TIME ZONE,
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT', 'ACTIVE', 'ENDED', 'CANCELLED')),
    
    -- İstatistikler
    total_eligible_voters INT DEFAULT 0,
    total_votes INT DEFAULT 0,
    participation_rate DECIMAL(5,2),
    
    -- Meta
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_surveys_property ON surveys(property_id);
CREATE INDEX idx_surveys_status ON surveys(status);
CREATE INDEX idx_surveys_dates ON surveys(starts_at, ends_at);

-- Anket Seçenekleri
CREATE TABLE IF NOT EXISTS survey_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    
    option_text VARCHAR(500) NOT NULL,
    description TEXT,
    display_order INT DEFAULT 0,
    
    -- Sonuçlar
    vote_count INT DEFAULT 0,
    weighted_vote_count DECIMAL(12,4) DEFAULT 0,
    percentage DECIMAL(5,2) DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_survey_options_survey ON survey_options(survey_id);

-- Oylar
CREATE TABLE IF NOT EXISTS survey_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    option_id UUID NOT NULL REFERENCES survey_options(id) ON DELETE CASCADE,
    
    voter_id UUID NOT NULL REFERENCES users(id),
    unit_id UUID REFERENCES units(id),
    
    -- Ağırlık (m² bazlı oylamalar için)
    weight DECIMAL(10,4) DEFAULT 1,
    
    -- Yorum
    comment TEXT,
    
    voted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Aynı kişi aynı ankete tekrar oy veremesin
    UNIQUE(survey_id, voter_id)
);

CREATE INDEX idx_survey_votes_survey ON survey_votes(survey_id);
CREATE INDEX idx_survey_votes_option ON survey_votes(option_id);

-- =====================================================
-- 7. KARGO TAKİBİ
-- =====================================================

CREATE TABLE IF NOT EXISTS packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    unit_id UUID NOT NULL REFERENCES units(id),
    
    -- Alıcı
    recipient_name VARCHAR(255) NOT NULL,
    recipient_phone VARCHAR(20),
    
    -- Kargo bilgileri
    carrier VARCHAR(100),  -- Aras, Yurtiçi, MNG, PTT, UPS, DHL...
    tracking_number VARCHAR(100),
    
    -- Paket detayları
    package_type VARCHAR(50) DEFAULT 'PACKAGE',  -- PACKAGE, ENVELOPE, LARGE
    description TEXT,
    photo_url TEXT,
    
    -- Teslim alım
    received_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    received_by UUID REFERENCES users(id),
    storage_location VARCHAR(100),
    
    -- Bildirim
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    notification_method VARCHAR(20),
    reminder_count INT DEFAULT 0,
    last_reminder_at TIMESTAMP WITH TIME ZONE,
    
    -- Teslim
    delivered_at TIMESTAMP WITH TIME ZONE,
    delivered_by UUID REFERENCES users(id),
    delivered_to_name VARCHAR(255),
    delivery_signature_url TEXT,
    delivery_photo_url TEXT,
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED'
        CHECK (status IN ('RECEIVED', 'NOTIFIED', 'DELIVERED', 'RETURNED')),
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_packages_property ON packages(property_id);
CREATE INDEX idx_packages_unit ON packages(unit_id);
CREATE INDEX idx_packages_status ON packages(status);
CREATE INDEX idx_packages_received ON packages(received_at);

-- =====================================================
-- 8. DEMİRBAŞ TAKİBİ
-- =====================================================

-- Demirbaş Kategorileri
CREATE TABLE IF NOT EXISTS asset_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id),  -- NULL = global
    name VARCHAR(100) NOT NULL,
    description TEXT,
    depreciation_years INT DEFAULT 5,
    parent_id UUID REFERENCES asset_categories(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Demirbaşlar
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    category_id UUID REFERENCES asset_categories(id),
    
    -- Temel bilgiler
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Tanımlayıcılar
    asset_code VARCHAR(50),
    serial_number VARCHAR(100),
    barcode VARCHAR(100),
    qr_code VARCHAR(100) UNIQUE,
    
    -- Görsel
    photo_urls JSONB DEFAULT '[]',
    
    -- Konum
    location VARCHAR(255),
    building VARCHAR(100),
    floor VARCHAR(20),
    room VARCHAR(50),
    
    -- Satın alma
    purchase_date DATE,
    purchase_price DECIMAL(12,2),
    purchase_invoice VARCHAR(100),
    vendor VARCHAR(255),
    
    -- Garanti
    warranty_start DATE,
    warranty_end DATE,
    warranty_provider VARCHAR(255),
    warranty_document_url TEXT,
    
    -- Amortisman
    depreciation_method VARCHAR(20) DEFAULT 'LINEAR',
    depreciation_years INT,
    residual_value DECIMAL(12,2) DEFAULT 0,
    current_value DECIMAL(12,2),
    accumulated_depreciation DECIMAL(12,2) DEFAULT 0,
    
    -- Durum
    condition VARCHAR(20) DEFAULT 'GOOD'
        CHECK (condition IN ('NEW', 'GOOD', 'FAIR', 'POOR', 'DISPOSED', 'LOST')),
    status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'IN_MAINTENANCE', 'RESERVED', 'DISPOSED')),
    
    -- Zimmet
    assigned_to VARCHAR(255),
    assigned_to_id UUID,
    assigned_at DATE,
    
    -- Bakım
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    maintenance_interval_days INT,
    
    -- Meta
    notes TEXT,
    custom_fields JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_assets_property ON assets(property_id);
CREATE INDEX idx_assets_category ON assets(category_id);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_location ON assets(location);
CREATE INDEX idx_assets_qr ON assets(qr_code);

-- Demirbaş Bakım Kayıtları
CREATE TABLE IF NOT EXISTS asset_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    
    maintenance_type VARCHAR(50) NOT NULL,  -- PREVENTIVE, CORRECTIVE, INSPECTION
    description TEXT NOT NULL,
    
    -- Maliyet
    labor_cost DECIMAL(12,2) DEFAULT 0,
    parts_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Yapan
    performed_by VARCHAR(255),
    vendor VARCHAR(255),
    
    -- Tarihler
    scheduled_date DATE,
    performed_at DATE,
    next_due DATE,
    
    -- Durum
    status VARCHAR(20) DEFAULT 'COMPLETED',
    
    -- Belgeler
    document_urls JSONB DEFAULT '[]',
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_asset_maintenance_asset ON asset_maintenance(asset_id);
CREATE INDEX idx_asset_maintenance_date ON asset_maintenance(performed_at);

-- =====================================================
-- 9. SÖZLEŞME YÖNETİMİ
-- =====================================================

CREATE TABLE IF NOT EXISTS contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- Sözleşme tipi
    contract_type VARCHAR(50) NOT NULL
        CHECK (contract_type IN ('RENTAL', 'SERVICE', 'MAINTENANCE', 'EMPLOYMENT', 'INSURANCE', 'OTHER')),
    
    -- Temel bilgiler
    title VARCHAR(255) NOT NULL,
    description TEXT,
    contract_number VARCHAR(100),
    
    -- Taraf bilgileri
    party_name VARCHAR(255) NOT NULL,
    party_type VARCHAR(20),  -- COMPANY, INDIVIDUAL
    party_tax_id VARCHAR(20),
    party_address TEXT,
    party_phone VARCHAR(20),
    party_email VARCHAR(255),
    party_contact_person VARCHAR(255),
    
    -- Tarihler
    start_date DATE NOT NULL,
    end_date DATE,
    signed_date DATE,
    
    -- Yenileme
    auto_renew BOOLEAN DEFAULT false,
    renewal_period_months INT,
    renewal_notice_days INT DEFAULT 30,
    max_renewals INT,
    current_renewal INT DEFAULT 0,
    
    -- Ödeme
    payment_type VARCHAR(20),  -- MONTHLY, YEARLY, ONE_TIME
    monthly_amount DECIMAL(12,2),
    yearly_amount DECIMAL(12,2),
    total_amount DECIMAL(12,2),
    payment_day INT,  -- Ayın kaçı
    currency VARCHAR(3) DEFAULT 'TRY',
    
    -- Belgeler
    document_urls JSONB DEFAULT '[]',
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'RENEWED')),
    termination_reason TEXT,
    terminated_at DATE,
    
    -- Hatırlatıcılar
    reminder_days INT[] DEFAULT '{60, 30, 7}',
    last_reminder_sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Meta
    terms TEXT,
    notes TEXT,
    tags VARCHAR(50)[],
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_contracts_property ON contracts(property_id);
CREATE INDEX idx_contracts_type ON contracts(contract_type);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_dates ON contracts(start_date, end_date);

-- =====================================================
-- 10. TUR KONTROL SİSTEMİ
-- =====================================================

-- Kontrol Noktaları
CREATE TABLE IF NOT EXISTS patrol_checkpoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    
    -- Konum
    building VARCHAR(100),
    floor VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Tanımlayıcılar
    nfc_tag_id VARCHAR(100) UNIQUE,
    qr_code VARCHAR(100) UNIQUE,
    
    -- Ayarlar
    requires_photo BOOLEAN DEFAULT false,
    requires_note BOOLEAN DEFAULT false,
    check_items JSONB,  -- [{item: "Kapı kilitli mi?", type: "YES_NO"}]
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    display_order INT DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patrol_checkpoints_property ON patrol_checkpoints(property_id);
CREATE INDEX idx_patrol_checkpoints_nfc ON patrol_checkpoints(nfc_tag_id);
CREATE INDEX idx_patrol_checkpoints_qr ON patrol_checkpoints(qr_code);

-- Tur Rotaları
CREATE TABLE IF NOT EXISTS patrol_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Noktalar (sıralı)
    checkpoints JSONB NOT NULL,  -- [{checkpoint_id, order, optional}]
    checkpoint_count INT,
    
    -- Zamanlama
    expected_duration_minutes INT DEFAULT 30,
    tolerance_minutes INT DEFAULT 10,
    
    -- Frekans
    frequency_type VARCHAR(20) DEFAULT 'FIXED',  -- FIXED, INTERVAL
    schedule_times TIME[],  -- Sabit saatler
    interval_hours INT,      -- Her X saatte
    
    -- Çalışma saatleri
    active_from TIME DEFAULT '00:00',
    active_to TIME DEFAULT '23:59',
    active_days INT[] DEFAULT '{0,1,2,3,4,5,6}',
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patrol_routes_property ON patrol_routes(property_id);

-- Tur Logları
CREATE TABLE IF NOT EXISTS patrol_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    route_id UUID REFERENCES patrol_routes(id),
    guard_id UUID NOT NULL REFERENCES users(id),
    
    -- Zaman
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    expected_duration_minutes INT,
    actual_duration_minutes INT,
    
    -- Durum
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS'
        CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'INCOMPLETE', 'MISSED')),
    
    -- Noktalar
    checkpoints_expected INT,
    checkpoints_visited INT,
    checkpoint_details JSONB,  -- [{checkpoint_id, scanned_at, photo_url, note, check_results}]
    
    -- Sorunlar
    issues_reported INT DEFAULT 0,
    issues JSONB,
    
    -- Konum takibi
    gps_track JSONB,
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_patrol_logs_property ON patrol_logs(property_id);
CREATE INDEX idx_patrol_logs_guard ON patrol_logs(guard_id);
CREATE INDEX idx_patrol_logs_date ON patrol_logs(started_at);
CREATE INDEX idx_patrol_logs_status ON patrol_logs(status);

-- =====================================================
-- 11. PERSONEL YÖNETİMİ
-- =====================================================

CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    user_id UUID REFERENCES users(id),  -- Sisteme giriş yapabiliyorsa
    
    -- Kişisel bilgiler
    employee_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    tc_number VARCHAR(11),
    birth_date DATE,
    gender VARCHAR(10),
    marital_status VARCHAR(20),
    
    -- İletişim
    phone VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    address TEXT,
    
    -- İş bilgileri
    position VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    manager_id UUID REFERENCES employees(id),
    
    -- İşe giriş/çıkış
    hire_date DATE NOT NULL,
    probation_end_date DATE,
    end_date DATE,
    termination_reason TEXT,
    
    -- Sözleşme
    contract_type VARCHAR(20) DEFAULT 'FULL_TIME'
        CHECK (contract_type IN ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERN')),
    contract_end_date DATE,
    
    -- Maaş
    gross_salary DECIMAL(12,2),
    net_salary DECIMAL(12,2),
    salary_currency VARCHAR(3) DEFAULT 'TRY',
    payment_method VARCHAR(20) DEFAULT 'BANK',
    bank_name VARCHAR(100),
    bank_iban VARCHAR(34),
    
    -- SGK
    sgk_number VARCHAR(20),
    sgk_registration_date DATE,
    
    -- Çalışma
    work_schedule VARCHAR(50),  -- 08:00-17:00
    weekly_hours INT DEFAULT 45,
    
    -- İzin hakları
    annual_leave_days INT DEFAULT 14,
    used_leave_days INT DEFAULT 0,
    remaining_leave_days INT DEFAULT 14,
    
    -- Belgeler
    photo_url TEXT,
    document_urls JSONB DEFAULT '[]',
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employees_property ON employees(property_id);
CREATE INDEX idx_employees_active ON employees(is_active);
CREATE INDEX idx_employees_tc ON employees(tc_number);

-- Bordro
CREATE TABLE IF NOT EXISTS payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    employee_id UUID NOT NULL REFERENCES employees(id),
    
    -- Dönem
    period VARCHAR(7) NOT NULL,  -- 2026-02
    period_start DATE,
    period_end DATE,
    
    -- Çalışma
    work_days INT,
    overtime_hours DECIMAL(5,2) DEFAULT 0,
    
    -- Kazançlar
    gross_salary DECIMAL(12,2),
    overtime_pay DECIMAL(12,2) DEFAULT 0,
    bonus DECIMAL(12,2) DEFAULT 0,
    other_earnings DECIMAL(12,2) DEFAULT 0,
    total_earnings DECIMAL(12,2),
    
    -- Kesintiler
    sgk_employee DECIMAL(12,2),
    sgk_employer DECIMAL(12,2),
    unemployment_employee DECIMAL(12,2),
    unemployment_employer DECIMAL(12,2),
    income_tax DECIMAL(12,2),
    stamp_tax DECIMAL(12,2),
    other_deductions DECIMAL(12,2) DEFAULT 0,
    total_deductions DECIMAL(12,2),
    
    -- Net
    net_salary DECIMAL(12,2),
    
    -- Ödeme
    payment_date DATE,
    payment_status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (payment_status IN ('PENDING', 'PAID', 'CANCELLED')),
    payment_reference VARCHAR(100),
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(employee_id, period)
);

CREATE INDEX idx_payroll_property ON payroll(property_id);
CREATE INDEX idx_payroll_employee ON payroll(employee_id);
CREATE INDEX idx_payroll_period ON payroll(period);

-- Personel İzinleri
CREATE TABLE IF NOT EXISTS employee_leaves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES employees(id),
    
    -- İzin tipi
    leave_type VARCHAR(50) NOT NULL
        CHECK (leave_type IN ('ANNUAL', 'SICK', 'UNPAID', 'MATERNITY', 'PATERNITY', 'MARRIAGE', 'BEREAVEMENT', 'OTHER')),
    
    -- Tarihler
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days DECIMAL(4,1) NOT NULL,
    
    -- Detaylar
    reason TEXT,
    document_url TEXT,
    
    -- Onay
    status VARCHAR(20) DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Meta
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_employee_leaves_employee ON employee_leaves(employee_id);
CREATE INDEX idx_employee_leaves_dates ON employee_leaves(start_date, end_date);
CREATE INDEX idx_employee_leaves_status ON employee_leaves(status);

-- =====================================================
-- 12. STOK TAKİBİ
-- =====================================================

-- Stok Kategorileri
CREATE TABLE IF NOT EXISTS inventory_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES inventory_categories(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Stok Kalemleri
CREATE TABLE IF NOT EXISTS inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    category_id UUID REFERENCES inventory_categories(id),
    
    -- Temel bilgiler
    name VARCHAR(255) NOT NULL,
    description TEXT,
    sku VARCHAR(50),
    barcode VARCHAR(50),
    
    -- Birim
    unit VARCHAR(20) NOT NULL,  -- ADET, KG, LT, METRE, M2, M3
    
    -- Stok
    current_stock DECIMAL(12,3) DEFAULT 0,
    minimum_stock DECIMAL(12,3) DEFAULT 0,
    maximum_stock DECIMAL(12,3),
    reorder_point DECIMAL(12,3),
    
    -- Fiyat
    unit_price DECIMAL(12,2),
    last_purchase_price DECIMAL(12,2),
    
    -- Konum
    warehouse VARCHAR(100),
    location VARCHAR(100),
    
    -- Durum
    is_active BOOLEAN DEFAULT true,
    
    -- Meta
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_items_property ON inventory_items(property_id);
CREATE INDEX idx_inventory_items_category ON inventory_items(category_id);
CREATE INDEX idx_inventory_items_stock ON inventory_items(current_stock, minimum_stock);

-- Stok Hareketleri
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES inventory_items(id),
    
    -- Hareket tipi
    movement_type VARCHAR(10) NOT NULL CHECK (movement_type IN ('IN', 'OUT', 'ADJUST')),
    
    -- Miktar
    quantity DECIMAL(12,3) NOT NULL,
    previous_stock DECIMAL(12,3),
    new_stock DECIMAL(12,3),
    
    -- Fiyat
    unit_price DECIMAL(12,2),
    total_price DECIMAL(12,2),
    
    -- Referans
    reference_type VARCHAR(50),  -- PURCHASE, USAGE, ADJUSTMENT, RETURN
    reference_id UUID,
    reference_number VARCHAR(100),
    
    -- Detaylar
    vendor VARCHAR(255),
    notes TEXT,
    
    -- Meta
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_movements_item ON inventory_movements(item_id);
CREATE INDEX idx_inventory_movements_type ON inventory_movements(movement_type);
CREATE INDEX idx_inventory_movements_date ON inventory_movements(created_at);

-- =====================================================
-- 13. ENERJİ ANALİTİK (AI)
-- =====================================================

CREATE TABLE IF NOT EXISTS energy_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- Dönem
    period VARCHAR(7) NOT NULL,  -- 2026-02
    analysis_date DATE NOT NULL,
    
    -- Genel metrikler
    total_heat_consumption DECIMAL(12,2),
    total_cold_water_consumption DECIMAL(12,2),
    total_hot_water_consumption DECIMAL(12,2),
    
    -- Karşılaştırma
    yoy_heat_change DECIMAL(5,2),
    yoy_water_change DECIMAL(5,2),
    mom_heat_change DECIMAL(5,2),
    mom_water_change DECIMAL(5,2),
    
    -- Maliyet
    total_energy_cost DECIMAL(12,2),
    cost_per_unit DECIMAL(12,2),
    
    -- AI analizi
    anomalies JSONB,  -- [{unit_id, meter_type, deviation, severity}]
    predictions JSONB,  -- [{month, predicted_consumption, confidence}]
    recommendations JSONB,  -- [{category, description, potential_saving}]
    
    -- Karbon ayak izi
    carbon_footprint_kg DECIMAL(12,2),
    
    -- Meta
    ai_model_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_energy_analytics_property ON energy_analytics(property_id);
CREATE INDEX idx_energy_analytics_period ON energy_analytics(period);

-- =====================================================
-- 14. TOPLANTI KAYITLARI (AI)
-- =====================================================

CREATE TABLE IF NOT EXISTS meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    
    -- Toplantı tipi
    meeting_type VARCHAR(50) NOT NULL
        CHECK (meeting_type IN ('GENERAL_ASSEMBLY', 'BOARD', 'COMMITTEE', 'OTHER')),
    
    -- Temel bilgiler
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Zaman ve yer
    meeting_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location VARCHAR(255),
    
    -- Katılım
    total_eligible INT,
    total_attended INT,
    quorum_met BOOLEAN,
    attendance_list JSONB,  -- [{unit_id, resident_name, proxy_name}]
    
    -- Gündem
    agenda JSONB,  -- [{order, title, description}]
    
    -- Ses kaydı
    audio_recording_url TEXT,
    audio_duration_seconds INT,
    
    -- AI transkripsiyon
    transcription TEXT,
    transcription_status VARCHAR(20),  -- PENDING, PROCESSING, COMPLETED, FAILED
    transcription_model VARCHAR(50),
    
    -- AI tutanak
    ai_summary TEXT,
    ai_decisions JSONB,  -- [{decision, votes_for, votes_against}]
    ai_action_items JSONB,  -- [{item, responsible, deadline}]
    
    -- Resmi tutanak
    minutes_document_url TEXT,
    minutes_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- Onay
    approved_by JSONB,  -- [{user_id, name, signed_at}]
    
    -- Meta
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meetings_property ON meetings(property_id);
CREATE INDEX idx_meetings_type ON meetings(meeting_type);
CREATE INDEX idx_meetings_date ON meetings(meeting_date);

-- =====================================================
-- 15. AKILLI TAHSİLAT (AI)
-- =====================================================

CREATE TABLE IF NOT EXISTS payment_risk_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    unit_id UUID NOT NULL REFERENCES units(id),
    resident_id UUID REFERENCES users(id),
    
    -- Skor
    risk_score DECIMAL(5,2) NOT NULL,  -- 0-100
    risk_category VARCHAR(20) NOT NULL
        CHECK (risk_category IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    
    -- Analiz
    total_assessments INT,
    paid_on_time INT,
    paid_late INT,
    unpaid INT,
    average_delay_days DECIMAL(5,1),
    current_debt DECIMAL(12,2),
    
    -- Tahmin
    predicted_payment_probability DECIMAL(3,2),
    predicted_delay_days INT,
    
    -- Öneriler
    recommendations JSONB,  -- [{action, reason, priority}]
    suggested_strategy VARCHAR(50),  -- EARLY_REMINDER, INSTALLMENT, PERSONAL_CONTACT
    
    -- Meta
    analysis_date DATE NOT NULL,
    ai_model_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payment_risk_property ON payment_risk_scores(property_id);
CREATE INDEX idx_payment_risk_unit ON payment_risk_scores(unit_id);
CREATE INDEX idx_payment_risk_category ON payment_risk_scores(risk_category);
CREATE INDEX idx_payment_risk_date ON payment_risk_scores(analysis_date);

-- =====================================================
-- TRIGGER: updated_at otomatik güncelleme
-- =====================================================

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Tüm tablolar için trigger
DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
        AND table_schema = 'public'
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_modtime ON %I;
            CREATE TRIGGER update_%I_modtime
            BEFORE UPDATE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION update_modified_column();
        ', t.table_name, t.table_name, t.table_name, t.table_name);
    END LOOP;
END;
$$;

-- =====================================================
-- SEED DATA
-- =====================================================

-- Varsayılan demirbaş kategorileri
INSERT INTO asset_categories (id, property_id, name, depreciation_years) VALUES
    ('ac000001-0000-0000-0000-000000000001', NULL, 'Mobilya', 10),
    ('ac000002-0000-0000-0000-000000000002', NULL, 'Elektronik', 5),
    ('ac000003-0000-0000-0000-000000000003', NULL, 'Bahçe Ekipmanları', 7),
    ('ac000004-0000-0000-0000-000000000004', NULL, 'Temizlik Ekipmanları', 5),
    ('ac000005-0000-0000-0000-000000000005', NULL, 'Güvenlik Sistemleri', 8),
    ('ac000006-0000-0000-0000-000000000006', NULL, 'Asansör', 15),
    ('ac000007-0000-0000-0000-000000000007', NULL, 'HVAC Sistemleri', 12),
    ('ac000008-0000-0000-0000-000000000008', NULL, 'Diğer', 5)
ON CONFLICT (id) DO NOTHING;

-- Varsayılan stok kategorileri
INSERT INTO inventory_categories (id, property_id, name) VALUES
    ('ic000001-0000-0000-0000-000000000001', NULL, 'Temizlik Malzemeleri'),
    ('ic000002-0000-0000-0000-000000000002', NULL, 'Elektrik Malzemeleri'),
    ('ic000003-0000-0000-0000-000000000003', NULL, 'Tesisat Malzemeleri'),
    ('ic000004-0000-0000-0000-000000000004', NULL, 'Bahçe Malzemeleri'),
    ('ic000005-0000-0000-0000-000000000005', NULL, 'Ofis Malzemeleri'),
    ('ic000006-0000-0000-0000-000000000006', NULL, 'Diğer')
ON CONFLICT (id) DO NOTHING;
