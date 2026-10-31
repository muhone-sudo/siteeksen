-- =====================================================
-- 079 — USTA & HİZMET TEKLİF, İŞ, PUAN, SAKLAMA (FAZ M7, docs/usta-hizmet/plan.md)
--
-- Talep iletişim bilgisi ve yazışmalar KVKK periyodik imhasına girer (pkg/retention MARKET_REQUEST): saklama süresini
-- site belirler (data_retention_rules); kapanmış talebin kişiyi belirleyen alanları anonimleştirilir, talep ve bakiye
-- defteri kalır.
-- =====================================================

ALTER TABLE data_retention_rules DROP CONSTRAINT IF EXISTS data_retention_rules_category_check;
ALTER TABLE data_retention_rules ADD CONSTRAINT data_retention_rules_category_check
    CHECK (category IN ('VISITOR', 'PARKING_LOG', 'PACKAGE', 'CLIENT_ERROR', 'MARKET_REQUEST'));
