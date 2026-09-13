-- =====================================================
-- 015 — BELGE ARŞİVİ
--
-- Neden: Projede dosya saklama hiç yoktu. Belge/fatura/imza uçları "yüklendi"
-- deyip hiçbir şey saklamıyordu; yönetim planı, genel kurul tutanağı, işletme
-- projesi, sigorta poliçesi gibi hukuken tutulması ZORUNLU belgelerin dijital
-- karşılığı bulunmuyordu.
--
-- Hukuki dayanak:
--   634 s. KMK m.36  — Yönetici, işletme defterini ve BELGELERİ kat maliklerinin
--                      incelemesine hazır bulundurmakla yükümlüdür.
--   634 s. KMK m.32  — Kararlar karar defterine yazılır (defter zinciri: 014).
--   634 s. KMK m.37  — İşletme projesi ve ekleri.
--   634 s. KMK m.28  — Yönetim planı ve değişiklikleri (sürüm takibi gerekir).
--   6698 s. KVKK m.4 — Veri minimizasyonu ve saklama süresi sınırı.
--   6698 s. KVKK m.12— Erişim kayıtlarının tutulması.
--
-- Dosyanın kendisi veritabanında DEĞİL, nesne deposunda (pkg/storage) tutulur;
-- burada yalnızca üst veri ve erişim kuralı saklanır.
-- =====================================================

CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),

    -- Sınıflandırma
    category VARCHAR(30) NOT NULL
        CHECK (category IN (
            'MANAGEMENT_PLAN',   -- Yönetim planı (KMK m.28)
            'DECISION',          -- Genel kurul kararı / tutanak (KMK m.32)
            'BUDGET',            -- İşletme projesi ve ekleri (KMK m.37)
            'ACCOUNTING',        -- Hesap belgeleri, mizan, bilanço (KMK m.39)
            'CONTRACT',          -- Sözleşmeler
            'INVOICE',           -- Fatura, fiş, gider belgesi
            'INSURANCE',         -- Sigorta poliçesi (KMK m.20/b)
            'REPORT',            -- Denetim ve teknik raporlar (KMK m.41)
            'LEGAL',             -- Dava, icra, ihtarname
            'PERSONNEL',         -- Özlük dosyası (KVKK: en dar erişim)
            'TECHNICAL',         -- Proje, ruhsat, asansör muayene belgesi
            'OTHER'
        )),
    title VARCHAR(255) NOT NULL,
    description TEXT,

    -- Nesne deposundaki karşılığı
    storage_backend VARCHAR(20) NOT NULL,
    storage_key TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(120) NOT NULL,
    size_bytes BIGINT NOT NULL CHECK (size_bytes >= 0),
    -- Belgenin sonradan değiştirilmediği bu özetle kanıtlanır.
    sha256 CHAR(64) NOT NULL,

    -- Görünürlük. Kat maliklerinin inceleme hakkı (KMK m.36) ile KVKK veri
    -- minimizasyonunu birlikte karşılayan en dar kademelendirme.
    visibility VARCHAR(20) NOT NULL DEFAULT 'MANAGEMENT'
        CHECK (visibility IN (
            'RESIDENTS',    -- Sitede oturan herkes (duyuru eki, yönetim planı…)
            'OWNERS',       -- Yalnızca kat malikleri (hesap belgeleri)
            'MANAGEMENT'    -- Yönetim + denetçi (özlük, sözleşme, dava)
        )),

    -- İlişkilendirme (sözleşme, genel kurul, gider…) — zayıf bağ bilinçlidir:
    -- belge arşivi, ilgili kaydı silinse bile ayakta kalmalıdır.
    related_type VARCHAR(30),
    related_id UUID,

    -- Sürümleme: yönetim planı değişikliği eskisini SİLMEZ, yenisini ekler.
    version INT NOT NULL DEFAULT 1,
    replaces_id UUID REFERENCES documents(id),
    is_current BOOLEAN NOT NULL DEFAULT true,

    -- KVKK saklama süresi. NULL = süresiz saklanır (yönetim planı, kararlar).
    retention_until DATE,

    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Belgeler silinmez, arşivden çıkarılır; gerekçesi kayda geçer.
    archived_at TIMESTAMPTZ,
    archived_by UUID REFERENCES users(id),
    archive_reason TEXT,

    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT documents_archive_reason_required
        CHECK (archived_at IS NULL OR (archive_reason IS NOT NULL AND length(trim(archive_reason)) > 0))
);

CREATE INDEX IF NOT EXISTS idx_documents_property ON documents(property_id);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(property_id, category);
CREATE INDEX IF NOT EXISTS idx_documents_related ON documents(related_type, related_id);
CREATE INDEX IF NOT EXISTS idx_documents_current ON documents(property_id, is_current)
    WHERE archived_at IS NULL;

-- Aynı nesne anahtarı iki kez kaydedilemez: kayıt silinip dosya ortada kalırsa
-- ya da tersi olursa arşiv ile depo birbirini tutmaz.
CREATE UNIQUE INDEX IF NOT EXISTS uq_documents_storage_key
    ON documents(storage_backend, storage_key);

-- -----------------------------------------------------
-- Belge erişim kayıtları (KVKK m.12)
--
-- Özlük dosyası, sözleşme ya da dava belgesi gibi kayıtlara KİMİN, NE ZAMAN
-- eriştiği kanıtlanabilmelidir. audit_logs istek düzeyinde tutar; burada
-- belge düzeyinde ve indirme/görüntüleme ayrımıyla tutulur.
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS document_access_logs (
    id BIGSERIAL PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id),
    user_id UUID REFERENCES users(id),
    action VARCHAR(20) NOT NULL CHECK (action IN ('VIEW', 'DOWNLOAD', 'DENIED')),
    ip_address INET,
    user_agent TEXT,
    accessed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_document_access_document ON document_access_logs(document_id, accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_document_access_user ON document_access_logs(user_id, accessed_at DESC);

-- Erişim kayıtları değiştirilemez ve silinemez; aksi hâlde kanıt değeri kalmaz.
CREATE OR REPLACE FUNCTION document_access_logs_append_only()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'document_access_logs yalnızca eklenebilir; güncelleme/silme yasaktır (KVKK m.12)';
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS document_access_logs_no_update ON document_access_logs;
CREATE TRIGGER document_access_logs_no_update
    BEFORE UPDATE OR DELETE ON document_access_logs
    FOR EACH ROW EXECUTE FUNCTION document_access_logs_append_only();

-- -----------------------------------------------------
-- Sürümleme tetikleyicisi: yeni sürüm eklendiğinde eskisi güncel olmaktan çıkar.
-- Uygulama katmanına bırakılsaydı, iki eşzamanlı yükleme iki "güncel" yönetim
-- planı bırakabilirdi.
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION documents_supersede_previous()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.replaces_id IS NOT NULL THEN
        UPDATE documents
        SET is_current = false, updated_at = now()
        WHERE id = NEW.replaces_id AND property_id = NEW.property_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS documents_supersede ON documents;
CREATE TRIGGER documents_supersede
    AFTER INSERT ON documents
    FOR EACH ROW EXECUTE FUNCTION documents_supersede_previous();
