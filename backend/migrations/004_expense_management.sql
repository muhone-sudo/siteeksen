-- Gider ve Fatura Yönetimi Migration
-- ======================================

-- Gider kategorileri
CREATE TABLE IF NOT EXISTS expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID REFERENCES properties(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('FIXED', 'VARIABLE', 'UNPLANNED')),
    reflects_to_assessment BOOLEAN NOT NULL DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    display_order INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Varsayılan gider kategorileri (tüm siteler için)
INSERT INTO expense_categories (id, property_id, name, description, type, reflects_to_assessment, is_default, display_order) VALUES
    ('10000000-0000-0000-0000-000000000001', NULL, 'Bina Temizliği', 'Ortak alan temizlik hizmeti', 'FIXED', false, true, 1),
    ('10000000-0000-0000-0000-000000000002', NULL, 'Güvenlik', 'Site güvenlik hizmeti', 'FIXED', false, true, 2),
    ('10000000-0000-0000-0000-000000000003', NULL, 'Yönetici Ücreti', 'Profesyonel yönetim hizmeti', 'FIXED', false, true, 3),
    ('10000000-0000-0000-0000-000000000004', NULL, 'Ortak Elektrik', 'Ortak alan elektrik gideri', 'VARIABLE', true, true, 4),
    ('10000000-0000-0000-0000-000000000005', NULL, 'Ortak Su', 'Ortak alan su gideri', 'VARIABLE', true, true, 5),
    ('10000000-0000-0000-0000-000000000006', NULL, 'Ortak Isınma', 'Ortak alan ısınma gideri', 'VARIABLE', true, true, 6),
    ('10000000-0000-0000-0000-000000000007', NULL, 'Asansör Bakımı', 'Periyodik asansör bakım ve onarım', 'UNPLANNED', true, true, 7),
    ('10000000-0000-0000-0000-000000000008', NULL, 'Bahçe Bakımı', 'Peyzaj ve bahçe bakım hizmeti', 'VARIABLE', true, true, 8),
    ('10000000-0000-0000-0000-000000000009', NULL, 'Acil Tamir', 'Beklenmeyen arıza ve tamir giderleri', 'UNPLANNED', true, true, 9),
    ('10000000-0000-0000-0000-000000000010', NULL, 'Diğer', 'Diğer giderler', 'UNPLANNED', true, true, 99)
ON CONFLICT (id) DO NOTHING;

-- Giderler tablosu
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),
    category_id UUID NOT NULL REFERENCES expense_categories(id),
    
    -- Temel bilgiler
    description TEXT NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'TRY',
    expense_date DATE NOT NULL,
    
    -- Fatura durumu
    is_invoiced BOOLEAN NOT NULL DEFAULT true,
    invoice_reason TEXT,  -- Faturasız ise neden
    
    -- Aidat yansıma
    reflects_to_assessment BOOLEAN NOT NULL DEFAULT true,
    assessment_period VARCHAR(7),  -- 2026-02 formatında (aidata yansıyacak dönem)
    distribution_type VARCHAR(20) DEFAULT 'EQUAL',  -- EQUAL, AREA, PERSON
    
    -- Onay durumu (faturasız giderler için)
    status VARCHAR(20) NOT NULL DEFAULT 'APPROVED' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Firma bilgisi
    vendor_name VARCHAR(255),
    vendor_tax_id VARCHAR(20),
    invoice_number VARCHAR(100),
    invoice_date DATE,
    
    -- Meta
    notes TEXT,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Fatura dosyaları
CREATE TABLE IF NOT EXISTS expense_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    
    -- Dosya bilgisi
    file_name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(20) NOT NULL,  -- PDF, JPG, PNG, HEIC
    file_size INT,
    
    -- AI çıkarım sonuçları
    ai_processed BOOLEAN DEFAULT false,
    ai_extracted_data JSONB,
    ai_confidence_score DECIMAL(3, 2),  -- 0.00 - 1.00
    ai_processed_at TIMESTAMP WITH TIME ZONE,
    
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI çıkarım örnek yapısı (ai_extracted_data)
COMMENT ON COLUMN expense_invoices.ai_extracted_data IS '
{
    "vendor_name": "AYEDAŞ",
    "invoice_number": "2024-123456",
    "invoice_date": "2024-01-15",
    "total_amount": 1250.50,
    "currency": "TRY",
    "tax_amount": 225.09,
    "category_suggestion": "Ortak Elektrik",
    "line_items": [
        {"description": "Tüketim Bedeli", "amount": 1025.41}
    ],
    "raw_text": "..."
}';

-- Gider dağıtım detayı (daire başı)
CREATE TABLE IF NOT EXISTS expense_distributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES units(id),
    amount DECIMAL(12, 2) NOT NULL,
    is_paid BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- İndeksler
CREATE INDEX IF NOT EXISTS idx_expenses_property ON expenses(property_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses(status);
CREATE INDEX IF NOT EXISTS idx_expenses_assessment ON expenses(assessment_period);
CREATE INDEX IF NOT EXISTS idx_expense_invoices_expense ON expense_invoices(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_distributions_expense ON expense_distributions(expense_id);

-- Trigger: updated_at otomatik güncelleme
CREATE OR REPLACE FUNCTION update_expense_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER expense_updated_at
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION update_expense_updated_at();

-- View: Aylık gider özeti
CREATE OR REPLACE VIEW monthly_expense_summary AS
SELECT 
    e.property_id,
    DATE_TRUNC('month', e.expense_date) AS month,
    ec.name AS category_name,
    ec.type AS category_type,
    COUNT(*) AS expense_count,
    SUM(e.amount) AS total_amount,
    SUM(CASE WHEN e.is_invoiced THEN e.amount ELSE 0 END) AS invoiced_amount,
    SUM(CASE WHEN NOT e.is_invoiced THEN e.amount ELSE 0 END) AS non_invoiced_amount,
    SUM(CASE WHEN e.reflects_to_assessment THEN e.amount ELSE 0 END) AS assessment_amount
FROM expenses e
JOIN expense_categories ec ON e.category_id = ec.id
WHERE e.status = 'APPROVED'
GROUP BY e.property_id, DATE_TRUNC('month', e.expense_date), ec.name, ec.type;
