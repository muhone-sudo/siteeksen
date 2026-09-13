-- ============================================================================
-- 013 — Site bazlı roller (property-scoped roles)
-- ============================================================================
--
-- SORUN (tasks/gap-analizi.md B22, todo 2.5):
--
-- Roller `users.roles TEXT[]` kolonunda GLOBAL tutuluyordu. Sonuç:
-- bir sitede yönetici (MANAGER) olarak atanan kişi, SİSTEMDEKİ TÜM SİTELERDE
-- yönetici sayılıyordu. Çok siteli bir SaaS'ta bu, kiracı (tenant) izolasyonunun
-- doğrudan ihlalidir: A sitesinin yöneticisi, B sitesinin maaş bordrosunu,
-- TCKN'lerini ve banka bilgilerini görebilirdi.
--
-- Ayrıca yönetim rolleri hiçbir yerde "kim, ne zaman, kim tarafından atadı"
-- bilgisiyle kaydedilmiyordu; KMK m.34 uyarınca yönetici genel kurul kararıyla
-- atanır ve bu atamanın izlenebilir olması gerekir.
--
-- ÇÖZÜM:
--   - `property_roles`: (kullanıcı, site, rol) üçlüsü + atama izi + geçerlilik dönemi.
--   - Jeton üretilirken roller AKTİF SİTEYE göre hesaplanır (bkz. identity servisi).
--   - `users.roles` yalnızca PLATFORM düzeyi roller için kalır (örn. SUPER_ADMIN);
--     site düzeyi roller oradan okunmaz.
--
-- Sakinlik rolleri (OWNER, TENANT, RESIDENT) bu tabloya YAZILMAZ; onların kaynağı
-- `resident_units` tablosudur (tek doğruluk kaynağı ilkesi).
--
-- Tüm ifadeler idempotenttir.
-- ============================================================================

CREATE TABLE IF NOT EXISTS property_roles (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    role         VARCHAR(30) NOT NULL,
    -- Atamanın izlenebilirliği (KMK m.34: yönetici genel kurul kararıyla atanır)
    granted_by   UUID REFERENCES users(id),
    granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_from   DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to     DATE,
    decision_ref TEXT,
    is_active    BOOLEAN NOT NULL DEFAULT true,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT property_roles_role_check
        CHECK (role IN ('MANAGER', 'AUDITOR', 'STAFF', 'BOARD_MEMBER')),
    CONSTRAINT property_roles_period_check
        CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- Aynı kullanıcıya aynı sitede aynı rol bir kez verilir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_property_roles_active
    ON property_roles (user_id, property_id, role) WHERE is_active;

CREATE INDEX IF NOT EXISTS idx_property_roles_lookup
    ON property_roles (user_id, property_id) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_property_roles_property
    ON property_roles (property_id, role) WHERE is_active;

COMMENT ON TABLE property_roles IS
 'Site bazlı yönetim rolleri. Sakinlik rolleri (OWNER/TENANT) burada DEĞİL, resident_units tablosundadır.';

-- ---------------------------------------------------------------------------
-- Geriye dönük taşıma: mevcut global yönetim rollerini, kullanıcının bağlı
-- olduğu sitelere taşı.
--
-- Global rol "her sitede geçerli" anlamına geldiği için, veriyi kaybetmemek
-- adına kullanıcının fiilen bağlı olduğu (resident_units) her siteye yazıyoruz.
-- Bağlı olmadığı sitelerdeki yetkisi ise BİLEREK düşürülüyor — zaten hatalıydı.
-- ---------------------------------------------------------------------------
INSERT INTO property_roles (user_id, property_id, role, decision_ref)
SELECT DISTINCT u.id, un.property_id, r.role,
       'Migration 013: users.roles kolonundan taşındı (global rol → site bazlı)'
FROM users u
CROSS JOIN LATERAL unnest(u.roles) AS r(role)
JOIN resident_units ru ON ru.resident_id = u.id AND ru.is_active = true
JOIN units un ON un.id = ru.unit_id
WHERE r.role IN ('MANAGER', 'AUDITOR', 'STAFF')
ON CONFLICT DO NOTHING;

-- management_staff kayıtları da yönetim rolü anlamına gelir; onları da taşı.
INSERT INTO property_roles (user_id, property_id, role, valid_from, valid_to, decision_ref)
SELECT ms.user_id, ms.property_id,
       CASE WHEN ms.title ILIKE '%denetçi%' THEN 'AUDITOR' ELSE 'BOARD_MEMBER' END,
       ms.start_date, ms.end_date,
       'Migration 013: management_staff tablosundan taşındı (' || ms.title || ')'
FROM management_staff ms
WHERE ms.user_id IS NOT NULL
  AND ms.property_id IS NOT NULL
  AND COALESCE(ms.is_active, true)
ON CONFLICT DO NOTHING;

COMMENT ON COLUMN users.roles IS
 'YALNIZCA platform düzeyi roller (örn. SUPER_ADMIN). Site düzeyi yönetim rolleri property_roles, '
 'sakinlik rolleri resident_units tablosundadır. Migration 013 ile bu ayrım getirilmiştir.';
