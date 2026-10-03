-- =====================================================
-- 030 — DAİRE BAKİYESİ GERÇEK BORÇ KAYDINDAN HESAPLANIR
--
-- SORUN: `unit_balances` (001) bakiyeyi `ledger_lines` üzerinden hesaplıyordu.
-- `ledger_lines`'a HİÇBİR KOD YAZMAZ (çift taraflı defter henüz kurulmadı);
-- görünüm her daire için 0 döndürüyordu. Sakinin `/finance/debt-status`
-- yanıtı bu yüzden borcu ne olursa olsun `current_balance: 0`,
-- `has_debt: false` diyordu ve mobil uygulama bunu "borcunuz yok" diye
-- gösteriyordu. Doğrulamadaki "ödeme sonrası has_debt:false" kontrolü de
-- ödemeden ÖNCE de false döndüğü için hiçbir şey kanıtlamıyordu.
--
-- ÇÖZÜM: borcun bugünkü tek kaynağı tahakkuklardır (`monthly_assessments`;
-- ödeme onayı `paid_amount`'ı, gecikme tazminatı `total_amount`'ı günceller).
-- Panelin borçlu listesi de aynı kaynağı kullanır; iki ekran artık aynı
-- rakamı gösterir. Kolonlar ve anlamları korunur:
--   total_debit  = tahakkuk edilen toplam (gecikme tazminatı dahil)
--   total_credit = onaylanmış ödemelerle kapanan toplam
--   balance      = fark (eksi değer fazla ödemedir; gizlenmez)
-- Silinmiş (deleted <> 0) tahakkuklar sayılmaz.
--
-- `ledger_entries`/`ledger_lines` tabloları ileride çift taraflı muhasebe
-- için korunur; o kurulduğunda bu görünüm deftere geri bağlanmalıdır.
-- =====================================================

CREATE OR REPLACE VIEW unit_balances
WITH (security_invoker = true) AS
SELECT
    u.id AS unit_id,
    u.property_id,
    u.block || '-' || u.door_number AS unit_name,
    COALESCE(SUM(ma.total_amount), 0) AS total_debit,
    COALESCE(SUM(COALESCE(ma.paid_amount, 0)), 0) AS total_credit,
    COALESCE(SUM(ma.total_amount - COALESCE(ma.paid_amount, 0)), 0) AS balance
FROM units u
LEFT JOIN monthly_assessments ma ON ma.unit_id = u.id AND ma.deleted = 0
GROUP BY u.id, u.property_id, u.block, u.door_number;

COMMENT ON VIEW unit_balances IS
    'Daire bakiyesi: monthly_assessments (tahakkuk - onaylı ödeme). ledger_lines kullanılmaz (030).';
