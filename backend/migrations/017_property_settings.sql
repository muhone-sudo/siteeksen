-- =====================================================
-- 017 — SİTE AYARLARI
--
-- Neden: settings-service mock'tu ve sabit ayar döndürüyordu; sitenin iletişim
-- bilgisi, ofis saatleri, aidat son ödeme günü gibi işletme ayarları hiçbir
-- yerde tutulmuyordu.
--
-- ÖNEMLİ SINIR: Bu tablo MEVZUATA BAĞLI hiçbir değeri tutmaz. Gecikme tazminatı
-- oranı, genel kurul nisapları, vekâlet sınırları ve ısı paylaşım oranları
-- `legal_parameters` tablosundadır (migration 012) ve kanunla sabit olanlar
-- site bazında değiştirilemez. Bu ayrım bilinçlidir: aksi hâlde bir site
-- "gecikme tazminatı %0" ayarı yapıp 634 s. KMK m.20/2'yi işlevsiz bırakabilirdi.
-- Kod tarafında da yasaklı anahtarlar reddedilir.
-- =====================================================

CREATE TABLE IF NOT EXISTS property_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,

    -- Ayar anahtarı. Serbest metin DEĞİLDİR; uygulama katmanındaki kayıtlı
    -- anahtar listesiyle sınırlıdır (services/settings/repository/registry.go).
    setting_key VARCHAR(60) NOT NULL,

    -- Değer, türüne göre ilgili kolonda tutulur. Tek bir JSONB'ye yığmak,
    -- "8" ile 8'i ayırt edilemez hâle getirir ve sessiz tür hatalarına yol açar.
    value_text TEXT,
    value_int INT,
    value_bool BOOLEAN,

    value_type VARCHAR(10) NOT NULL CHECK (value_type IN ('TEXT', 'INT', 'BOOL')),

    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(property_id, setting_key),

    -- Değer, ilan edilen türle uyumlu olmak zorundadır.
    CONSTRAINT property_settings_value_matches_type CHECK (
        (value_type = 'TEXT' AND value_text IS NOT NULL AND value_int IS NULL AND value_bool IS NULL) OR
        (value_type = 'INT'  AND value_int  IS NOT NULL AND value_text IS NULL AND value_bool IS NULL) OR
        (value_type = 'BOOL' AND value_bool IS NOT NULL AND value_text IS NULL AND value_int IS NULL)
    ),

    -- Mevzuat parametrelerinin buradan ezilmesini VERİTABANI DÜZEYİNDE engelle.
    -- Uygulama katmanındaki kontrol tek başına yeterli değildir: doğrudan SQL ile
    -- yazan bir betik ya da ileride yazılacak başka bir servis bu kısıtla karşılaşır.
    CONSTRAINT property_settings_no_legal_keys CHECK (
        setting_key NOT LIKE 'LATE_FEE%' AND
        setting_key NOT LIKE 'HEATING\_%' AND
        setting_key NOT LIKE 'GA\_%' AND
        setting_key NOT LIKE 'PROXY\_%' AND
        setting_key NOT LIKE 'MAJORITY\_%' AND
        setting_key NOT LIKE 'BUDGET\_OBJECTION%' AND
        setting_key NOT LIKE 'AUDIT\_INTERVAL%' AND
        setting_key NOT LIKE 'DECISION\_BOOK%'
    )
);

CREATE INDEX IF NOT EXISTS idx_property_settings_property ON property_settings(property_id);

-- -----------------------------------------------------
-- Ayar değişiklik geçmişi
--
-- "Aidat son ödeme günü ayın 5'iydi, kim 20 yaptı?" sorusunun cevabı olmalıdır.
-- Salt-ekleme: geçmiş değiştirilemez.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS property_setting_history (
    id BIGSERIAL PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    setting_key VARCHAR(60) NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_setting_history_property
    ON property_setting_history(property_id, changed_at DESC);

CREATE OR REPLACE FUNCTION property_setting_history_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'property_setting_history yalnızca eklenebilir; değiştirilemez ve silinemez';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS property_setting_history_no_change ON property_setting_history;
CREATE TRIGGER property_setting_history_no_change
    BEFORE UPDATE OR DELETE ON property_setting_history
    FOR EACH ROW EXECUTE FUNCTION property_setting_history_append_only();
