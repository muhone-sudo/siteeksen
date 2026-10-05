-- =====================================================
-- 050 — İŞLETME PROJESİNDEN AYLIK TAHAKKUK (TEST_RAPORU 2.7)
--
-- Kesinleşen (genel kurulda onaylanan) ya da geçici olarak uygulanan işletme
-- projesi (KMK m.37, 7579 s. Kanun) bağımsız bölüm paylarını hesaplıyordu ama bu
-- paylardan aidat tahakkuku üretilemiyordu; yönetici aynı tutarları ayrıca elle
-- girmek zorundaydı. Tahakkukun hangi projeden üretildiği bu kolonla izlenir.
-- =====================================================

ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS budget_id UUID REFERENCES operating_budgets(id);
CREATE INDEX IF NOT EXISTS idx_monthly_assessments_budget ON monthly_assessments(budget_id) WHERE budget_id IS NOT NULL;

COMMENT ON COLUMN monthly_assessments.budget_id IS
    'Tahakkukun üretildiği işletme projesi (KMK m.37; yıllık pay 12 aya kuruşu kuruşuna bölünür) — 050';
