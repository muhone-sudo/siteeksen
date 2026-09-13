-- ============================================================================
-- 012 — Mevzuata bağlı parametreler (yürürlük tarihli, site bazında geçersiz kılınabilir)
-- ============================================================================
--
-- NEDEN VAR (tasks/questions.md S-05):
--
-- Gecikme tazminatı oranı, ısıtma gider paylaşım oranı, genel kurul çağrı süresi,
-- nisaplar ve vekâlet sınırları doğrudan PARA HESABINA ve KARAR GEÇERLİLİĞİNE girer.
-- Bu değerler bugüne kadar hiçbir yerde tanımlı değildi; koda gömülmeleri hâlinde
-- mevzuat değiştiğinde kod değişikliği ve yeniden dağıtım gerekirdi.
--
-- Bu tablo üç sorunu birden çözer:
--   1. YÜRÜRLÜK TARİHİ: Bir oran değiştiğinde eski kayıt kapatılır, yenisi eklenir.
--      Geçmiş dönem tahakkukları eski oranla yeniden üretilebilir kalır.
--   2. SİTE BAZINDA ÖZELLEŞTİRME: Yönetim planı kanunun izin verdiği yerlerde farklı
--      bir düzen öngörebilir (KMK m.20 "aralarında başka türlü anlaşma olmadıkça").
--      `property_id` NULL olan satır sistem geneli varsayılandır.
--   3. HUKUKİ DAYANAK: Her parametre `legal_basis` alanında dayanağını taşır; denetimde
--      "bu oran nereden geliyor?" sorusunun yanıtı veritabanındadır.
--
-- `is_mandatory = true` olan parametreler KANUNLA SABİTTİR ve yönetim planıyla
-- değiştirilemez (örn. gecikme tazminatı aylık %5). Bunlar için site bazlı geçersiz
-- kılma kaydı oluşturulması bir tetikleyici ile engellenir.
--
-- ARAŞTIRMA NOTU (2026-09-13): Aşağıdaki değerler yürürlükteki mevzuat metinleri
-- üzerinden doğrulanmıştır. Yine de bu tablo bir HUKUK GÖRÜŞÜ DEĞİLDİR; nihai teyit
-- için hukuk danışmanı onayı alınmalıdır (questions.md S-05).
-- Tüm ifadeler idempotenttir.
-- ============================================================================

CREATE TABLE IF NOT EXISTS legal_parameters (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- NULL = sistem geneli varsayılan; dolu = o siteye özel geçersiz kılma
    property_id     UUID REFERENCES properties(id) ON DELETE CASCADE,
    code            VARCHAR(80)  NOT NULL,
    value_numeric   NUMERIC(18,6),
    value_text      TEXT,
    unit            VARCHAR(40)  NOT NULL,
    effective_from  DATE         NOT NULL DEFAULT DATE '1900-01-01',
    effective_to    DATE,
    legal_basis     TEXT         NOT NULL,
    is_mandatory    BOOLEAN      NOT NULL DEFAULT false,
    description     TEXT,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

    -- En az bir değer alanı dolu olmalı
    CONSTRAINT legal_parameters_value_present
        CHECK (value_numeric IS NOT NULL OR value_text IS NOT NULL),
    CONSTRAINT legal_parameters_period_valid
        CHECK (effective_to IS NULL OR effective_to > effective_from)
);

-- Aynı kapsam + kod + yürürlük başlangıcı yalnızca bir kez bulunabilir.
-- property_id NULL olduğu için iki ayrı kısmi benzersiz indeks gerekir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_legal_parameters_global
    ON legal_parameters (code, effective_from) WHERE property_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS uq_legal_parameters_property
    ON legal_parameters (property_id, code, effective_from) WHERE property_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_legal_parameters_lookup
    ON legal_parameters (code, effective_from DESC);

-- ---------------------------------------------------------------------------
-- Kanunla sabit parametrelerin site bazında değiştirilmesini engelle.
--
-- Örnek: gecikme tazminatı KMK m.20/2 ile aylık %5 olarak belirlenmiştir ve
-- yönetim planıyla artırılıp azaltılamaz. Bunu veritabanı düzeyinde garanti
-- ediyoruz; aksi hâlde bir arayüz hatası hukuka aykırı tahakkuk üretebilir.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION legal_parameters_guard_mandatory()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.property_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM legal_parameters g
        WHERE g.property_id IS NULL
          AND g.code = NEW.code
          AND g.is_mandatory
    ) THEN
        RAISE EXCEPTION
            'Parametre "%" kanunla sabittir; site bazında değiştirilemez (KMK).', NEW.code
            USING ERRCODE = 'check_violation';
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS legal_parameters_guard ON legal_parameters;
CREATE TRIGGER legal_parameters_guard
    BEFORE INSERT OR UPDATE ON legal_parameters
    FOR EACH ROW EXECUTE FUNCTION legal_parameters_guard_mandatory();

-- ---------------------------------------------------------------------------
-- Sistem geneli varsayılanlar
-- ---------------------------------------------------------------------------
INSERT INTO legal_parameters (code, value_numeric, value_text, unit, legal_basis, is_mandatory, description) VALUES

-- ---- PARA / TAHAKKUK ----
('LATE_FEE_MONTHLY_RATE', 0.05, NULL, 'RATIO_PER_MONTH',
 'KMK m.20/2 — "ödemede geciktiği günler için aylık yüzde beş hesabıyla gecikme tazminatı"',
 true,
 'Gecikme tazminatı aylık oranı. Kanunla sabittir; yönetim planıyla değiştirilemez.'),

('EXPENSE_DIST_STAFF', NULL, 'EQUAL', 'DISTRIBUTION_TYPE',
 'KMK m.20/1-a — kapıcı, kaloriferci, bahçıvan ve bekçi giderleri ve avansı: eşit',
 false,
 'Kapıcı/kaloriferci/bahçıvan/bekçi giderlerinin varsayılan dağıtım türü.'),

('EXPENSE_DIST_COMMON', NULL, 'SHARE_RATIO', 'DISTRIBUTION_TYPE',
 'KMK m.20/1-b — sigorta primleri, ortak yerlerin bakım/koruma/güçlendirme/onarım giderleri, yönetici aylığı, ortak tesis işletme giderleri: arsa payı oranında',
 false,
 'Ortak gider kalemlerinin varsayılan dağıtım türü.'),

-- ---- ISITMA ----
('HEATING_CONSUMPTION_SHARE', 0.70, NULL, 'RATIO',
 'Merkezi Isıtma ve Sıhhi Sıcak Su Sistemlerinde Isınma ve Sıhhi Sıcak Su Giderlerinin Paylaştırılmasına İlişkin Yönetmelik (RG 14.04.2008)',
 false,
 'Toplam ısıtma giderinin ölçülen tüketime göre paylaştırılan kısmı.'),

('HEATING_AREA_SHARE', 0.30, NULL, 'RATIO',
 'Merkezi Isıtma ve Sıhhi Sıcak Su Yönetmeliği (RG 14.04.2008) — ortak alan ısıtması, sistem kayıpları, asgari ısınma ve işletme giderleri',
 false,
 'Toplam ısıtma giderinin kullanım alanına göre paylaştırılan kısmı. Tüketim payı ile toplamı 1 olmalıdır.'),

('HEATING_MIN_TEMPERATURE_C', 15, NULL, 'CELSIUS',
 'Merkezi Isıtma ve Sıhhi Sıcak Su Yönetmeliği — merkezi sistemle ısıtılan bağımsız bölümlerde asgari sıcaklık',
 false,
 'Bağımsız bölümde sağlanması gereken asgari sıcaklık.'),

('HEATING_CONVERSION_UNANIMITY_AREA_M2', 2000, NULL, 'M2',
 'KMK m.42 (5627 sayılı Enerji Verimliliği Kanunu ile) — toplam inşaat alanı 2000 m2 ve üzeri binalarda merkezi sistemden ferdi sisteme geçiş oybirliği gerektirir',
 false,
 'Bu eşiğin altında sayı ve arsa payı çoğunluğu yeterlidir; eşik ve üzerinde oybirliği aranır.'),

-- ---- GENEL KURUL ----
('GA_NOTICE_DAYS', 15, NULL, 'DAY',
 'KMK m.29 — toplantı gününden en az on beş gün önce, imza karşılığı veya taahhütlü mektupla bildirim',
 false,
 'Genel kurul çağrısının toplantıdan kaç gün önce yapılması gerektiği.'),

('GA_QUORUM_FIRST', 0.50, NULL, 'RATIO_EXCLUSIVE',
 'KMK m.30 — kat maliklerinin sayı ve arsa payı bakımından YARIDAN FAZLASI ile toplanır',
 false,
 'Birinci toplantı yeter sayısı. Oran "den fazla" olarak uygulanır (tam yarı yetmez); sayı VE arsa payı birlikte aranır.'),

('GA_QUORUM_SECOND', 0.00, NULL, 'RATIO',
 'KMK m.30/3 — ilk toplantıda yeter sayı sağlanamazsa ikinci toplantı, katılanların salt çoğunluğu ile karar alır',
 false,
 'İkinci toplantıda toplantı yeter sayısı aranmaz; karar katılanların salt çoğunluğu ile alınır.'),

('OWNER_MAX_VOTE_SHARE', 0.333333, NULL, 'RATIO',
 'KMK m.31 — bir kat malikinin oyları, kaç bağımsız bölümü olursa olsun bütün oyların üçte birinden fazla olamaz',
 true,
 'Tek bir malikin kullanabileceği azami oy oranı. Kesirler hesaba katılmaz.'),

('PROXY_MAX_VOTE_SHARE', 0.05, NULL, 'RATIO',
 'KMK m.31 — bir kişi, oy sayısının yüzde beşinden fazlasını kullanmak üzere vekil tayin edilemez',
 true,
 'Bir vekilin kullanabileceği azami toplam oy oranı.'),

('PROXY_SMALL_BUILDING_UNIT_THRESHOLD', 40, NULL, 'COUNT',
 'KMK m.31 — kırk ve daha az bağımsız bölümü olan gayrimenkullerde bir kişi en fazla iki kişiye vekâlet edebilir',
 true,
 'Küçük yapı istisnasının uygulandığı bağımsız bölüm sayısı eşiği.'),

('PROXY_MAX_COUNT_SMALL_BUILDING', 2, NULL, 'COUNT',
 'KMK m.31 — kırk ve daha az bağımsız bölümlü yapılarda bir kişinin üstlenebileceği azami vekâlet sayısı',
 true,
 'Küçük yapılarda bir kişinin taşıyabileceği azami vekâlet sayısı.'),

-- ---- NİSAPLAR ----
('MAJORITY_CONSTRUCTION_CONSENT', 0.80, NULL, 'RATIO',
 'KMK m.19/2 — ortak yerlerde inşaat, onarım ve tesis ile değişiklik için kat maliklerinin beşte dördünün yazılı rızası',
 true,
 'Ortak yerlerde inşaat/onarım/değişiklik için gereken rıza oranı (4/5).'),

('MAJORITY_MANAGEMENT_PLAN_CHANGE', 0.80, NULL, 'RATIO',
 'KMK m.28 — yönetim planının değiştirilmesi için bütün kat maliklerinin beşte dördünün oyu',
 true,
 'Yönetim planı değişikliği nisabı (4/5).'),

('MAJORITY_INNOVATION', 0.50, NULL, 'RATIO_EXCLUSIVE',
 'KMK m.42 — yenilik ve ilaveler için kat maliklerinin sayı ve arsa payı çoğunluğu',
 false,
 'Yenilik ve ilavelerde aranan çoğunluk; sayı VE arsa payı birlikte değerlendirilir.'),

('UNANIMITY_TRANSFER_ACTS', 1.00, NULL, 'RATIO',
 'KMK m.45 — anagayrimenkulün bir kısmının kiralanması, ortak yerlerde temliki tasarruf ve önemli yönetim işleri için oybirliği',
 true,
 'Çatı/dış duvar reklam kiralaması gibi temliki tasarruflarda oybirliği gerekir.'),

-- ---- YÖNETİM VE DENETİM ----
('MANAGER_MANDATORY_UNIT_COUNT', 8, NULL, 'COUNT',
 'KMK m.34 — bağımsız bölüm sayısı sekiz veya daha fazla ise yönetici atanması zorunludur',
 true,
 'Yönetici atama zorunluluğunun başladığı bağımsız bölüm sayısı.'),

('BUDGET_OBJECTION_DAYS', 7, NULL, 'DAY',
 'KMK m.37 — işletme projesine tebliğ tarihinden itibaren yedi gün içinde itiraz edilebilir',
 true,
 'İşletme projesine itiraz süresi.'),

('DECISION_BOOK_NOTARY_CLOSE_MONTHS', 1, NULL, 'MONTH',
 'KMK m.36 — karar defterinin her takvim yılı bitiminden başlayarak bir ay içinde notere kapattırılması',
 true,
 'Karar defterinin notere kapattırılma süresi.'),

('ANNUAL_ACCOUNT_MONTH', 1, NULL, 'MONTH_OF_YEAR',
 'KMK m.39 — yönetici, kat maliklerine her takvim yılının birinci ayı içinde hesap vermekle yükümlüdür',
 true,
 'Yıllık hesap verme yükümlülüğünün yerine getirileceği ay.'),

('AUDIT_INTERVAL_MONTHS', 3, NULL, 'MONTH',
 'KMK m.41 — denetim, yönetim planında başka bir süre öngörülmemişse en az üç ayda bir yapılır',
 false,
 'Denetim sıklığı. Yönetim planı daha sık denetim öngörebilir.'),

-- ---- SORUMLULUK ----
('TENANT_LIABILITY_SCOPE', NULL, 'RENT_AMOUNT', 'LIABILITY_SCOPE',
 'KMK m.22 — kiracı, ortak gider ve avans payından kat maliki ile MÜTESELSİLEN, ancak kira bedeli kadar sorumludur',
 true,
 'Kiracının ortak gider sorumluluğunun üst sınırı.'),

('NEW_OWNER_JOINT_LIABILITY', NULL, 'true', 'BOOLEAN',
 'KMK m.22 — bağımsız bölümü sonradan edinen kişi, eski malikin ödemediği ortak gider borcundan müteselsilen sorumludur',
 true,
 'Yeni malikin önceki malikin borcundan müteselsil sorumluluğu.')

ON CONFLICT DO NOTHING;

COMMENT ON TABLE legal_parameters IS
 'Mevzuata bağlı, yürürlük tarihli parametreler. property_id NULL = sistem geneli varsayılan. '
 'is_mandatory = kanunla sabit, site bazında değiştirilemez.';
