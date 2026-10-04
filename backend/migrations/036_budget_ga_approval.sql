-- =====================================================
-- 036 — İŞLETME PROJESİ: GENEL KURUL ONAYI (7579 s. Kanun, KMK m.37)
--
-- 7/5/2026 tarihli 7579 sayılı Kanun (RG 22/5/2026, sayı 33261; yürürlük
-- 22/5/2026) KMK m.37'yi değiştirdi:
--   * İşletme projesi kat malikleri GENEL KURULUNDA onaylanır.
--   * Onaylı proje yoksa yönetici GEÇİCİ işletme projesi yapar; bildirilir ve
--     en geç ÜÇ AY içinde genel kurulda karara bağlanır.
--   * "Tebliğden itibaren yedi gün içinde itiraz edilmezse kesinleşir" cümlesi
--     MÜLGA. Yönetici artık itiraz süresinin dolmasıyla projeyi kesinleştiremez.
--   * Mevcut proje varsa geçici projenin bedeli, yürürlükteki proje bedelinin
--     bir önceki yıla ilişkin VUK mük. m.298 yeniden değerleme oranını
--     aşmayacak şekilde belirlenir.
--   * m.35/d: yönetici "işletme projesi onaylanıncaya kadar" avans toplar.
--
-- Sistem 22/5/2026'dan sonra da eski kuralı uyguluyordu: tebliğden yedi gün
-- sonra yönetici projeyi "kesinleşti — İİK m.68 belgesi" yapabiliyordu.
--
-- Bu migration:
--   1. BUDGET_OBJECTION_DAYS'in yürürlüğünü 22/5/2026'da kapatır (eski
--      projelerin itiraz süresi hesabı geçmişe dönük doğru kalır).
--   2. BUDGET_GA_APPROVAL_MONTHS (3 ay, kanunla sabit) ekler.
--   3. REVALUATION_RATE: yıl bazlı yeniden değerleme oranı. Değer, uygulandığı
--      dönemin 1 Ocak'ından yürürlüktedir (2025 oranı → 2026 dönemi).
--   4. operating_budgets: genel kurul onayının bağlandığı gündem maddesi,
--      onay son günü ve geçici proje tavanının dökümü.
-- =====================================================

UPDATE legal_parameters
SET effective_to = DATE '2026-05-22',
    description = 'İşletme projesine itiraz süresi. 7579 s. Kanunla (RG 22/5/2026) mülga; '
                  || 'yalnızca bu tarihten önce tebliğ edilen projeler için geçerlidir.',
    updated_at = now()
WHERE code = 'BUDGET_OBJECTION_DAYS' AND property_id IS NULL AND effective_to IS NULL;

INSERT INTO legal_parameters (code, value_numeric, unit, effective_from, legal_basis, is_mandatory, description)
SELECT 'BUDGET_GA_APPROVAL_MONTHS', 3, 'MONTH', DATE '2026-05-22',
       'KMK m.37/2 (7579 s. Kanun m.4, RG 22/5/2026) — geçici işletme projesi bildirilir ve en geç üç ay içinde '
       || 'aynen veya değiştirilerek kabulüne yönelik genel kurulda karar alınır',
       true, 'Geçici işletme projesinin genel kurulda karara bağlanma süresi'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters
                  WHERE code = 'BUDGET_GA_APPROVAL_MONTHS' AND property_id IS NULL);

-- Oran KESİR olarak tutulur (0.2549 = %25,49). Her yıl Kasım/Aralık'ta Hazine ve
-- Maliye Bakanlığının VUK Genel Tebliğiyle ilan ettiği oran yeni satır olarak
-- eklenir; ilan edilmemiş yıl için geçici proje tavanı hesaplanamaz ve sistem
-- tavanı uydurmak yerine işlemi durdurur.
INSERT INTO legal_parameters (code, value_numeric, unit, effective_from, effective_to, legal_basis, is_mandatory, description)
SELECT 'REVALUATION_RATE', 0.2549, 'RATIO', DATE '2026-01-01', DATE '2027-01-01',
       '213 s. VUK mük. m.298/B — 2025 yılı yeniden değerleme oranı %25,49 (VUK Genel Tebliği Sıra No: 585, '
       || 'RG 27/11/2025, sayı 33090). KMK m.37 son fıkra (7579 s. Kanun) geçici işletme projesi tavanı',
       true, '2026 dönemi geçici işletme projesi için uygulanan (2025 yılına ilişkin) yeniden değerleme oranı'
WHERE NOT EXISTS (SELECT 1 FROM legal_parameters
                  WHERE code = 'REVALUATION_RATE' AND property_id IS NULL AND effective_from = DATE '2026-01-01');

ALTER TABLE operating_budgets
    ADD COLUMN IF NOT EXISTS approval_deadline DATE,
    ADD COLUMN IF NOT EXISTS approved_agenda_item_id UUID REFERENCES assembly_agenda_items(id),
    -- Geçici proje tavanı: hangi projeye ve hangi orana göre hesaplandığı
    -- denetimde sorulduğunda yanıt kayıttadır.
    ADD COLUMN IF NOT EXISTS cap_base_budget_id UUID REFERENCES operating_budgets(id),
    ADD COLUMN IF NOT EXISTS cap_rate NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS cap_amount DECIMAL(14,2);

-- Bir gündem maddesi yalnızca bir işletme projesini onaylayabilir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_operating_budgets_agenda_item
    ON operating_budgets (approved_agenda_item_id) WHERE approved_agenda_item_id IS NOT NULL;

COMMENT ON COLUMN operating_budgets.approval_deadline IS
    'Geçici projenin genel kurulda karara bağlanması gereken son gün (KMK m.37/2, 3 ay)';
COMMENT ON COLUMN operating_budgets.approved_agenda_item_id IS
    'Projeyi kabul eden genel kurul gündem maddesi (7579 sonrası FINAL için zorunlu)';
COMMENT ON TABLE operating_budgets IS
    'İşletme projesi (KMK m.37). NOTIFIED = bildirilmiş geçici proje (avans dayanağı, m.35/d); '
    'FINAL = genel kurulda kabul edildi (İİK m.68 belgesi).';
