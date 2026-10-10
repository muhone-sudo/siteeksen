-- =====================================================
-- 059 — ALACAK DEKONTU VE BANKA EKSTRESİ MUTABAKATI (Apsiyon BUG-12)
--
-- Apsiyon şikâyeti: yönetim "oturulmayan aylar" için indirim yapmış, makbuz Excel'de
-- hazırlanıp WhatsApp'tan gönderilmiş; sisteme işlenmediği için sakin borçlu görünmeye
-- devam etmiş. Burada:
--   1) Alacak dekontu: gerekçeli, numaralı, silinemez belge; tahakkukun borcunu düşürür
--      (ödeme gibi görünmez — tahsilat raporuna girmez) ve tahsilat defteri zincirine yazılır.
--      Hata ancak gerekçeli ters kayıtla düzeltilir.
--   2) Banka ekstresi: yöneticinin bankadan indirdiği CSV/Excel yüklenir; gelen her hareket
--      sakinin bildirdiği onay bekleyen ödemeyle eşleştirilmeye çalışılır, yönetici onaylar.
--      Aynı hareket ikinci yüklemede tekrar işlenmez (satır özeti).
-- =====================================================

ALTER TABLE monthly_assessments ADD COLUMN IF NOT EXISTS credited_amount NUMERIC(12,2) NOT NULL DEFAULT 0;
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'monthly_assessments_credited_rules') THEN
        ALTER TABLE monthly_assessments ADD CONSTRAINT monthly_assessments_credited_rules
            CHECK (credited_amount >= 0 AND credited_amount <= base_amount);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS credit_notes (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id      UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    document_no      VARCHAR(30) NOT NULL,
    assessment_id    UUID NOT NULL REFERENCES monthly_assessments(id),
    unit_id          UUID NOT NULL REFERENCES units(id),
    amount           NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    reason           TEXT NOT NULL CHECK (length(trim(reason)) >= 5),
    created_by       UUID REFERENCES users(id),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    reversed_at      TIMESTAMPTZ,
    reversed_by      UUID REFERENCES users(id),
    reversal_reason  TEXT,
    UNIQUE (property_id, document_no),
    CHECK (reversed_at IS NULL OR length(trim(COALESCE(reversal_reason, ''))) >= 5)
);
CREATE INDEX IF NOT EXISTS idx_credit_notes_assessment ON credit_notes(assessment_id);
ALTER TABLE credit_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_notes FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS credit_notes_property_scope ON credit_notes;
CREATE POLICY credit_notes_property_scope ON credit_notes
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE DELETE, TRUNCATE ON credit_notes FROM siteeksen_app;

-- Dekont değiştirilemez; tek geçiş ters kayıttır (bir kez).
CREATE OR REPLACE FUNCTION credit_notes_guard() RETURNS trigger AS $$
BEGIN
    IF current_user <> 'siteeksen_app' THEN
        RETURN NEW;
    END IF;
    IF OLD.reversed_at IS NOT NULL
       OR NEW.amount <> OLD.amount OR NEW.assessment_id <> OLD.assessment_id OR NEW.unit_id <> OLD.unit_id
       OR NEW.reason <> OLD.reason OR NEW.document_no <> OLD.document_no OR NEW.created_at <> OLD.created_at
       OR NEW.reversed_at IS NULL THEN
        RAISE EXCEPTION 'Alacak dekontu değiştirilemez; yalnızca bir kez gerekçeli ters kaydı yapılabilir'
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS credit_notes_guard ON credit_notes;
CREATE TRIGGER credit_notes_guard BEFORE UPDATE ON credit_notes FOR EACH ROW EXECUTE FUNCTION credit_notes_guard();

-- Tahsilat defteri: dekontun ters kaydı da zincire yazılır.
ALTER TABLE finance_ledger DROP CONSTRAINT IF EXISTS finance_ledger_entry_type_check;
ALTER TABLE finance_ledger ADD CONSTRAINT finance_ledger_entry_type_check
    CHECK (entry_type IN ('PAYMENT_CONFIRMED', 'PAYMENT_REVERSED', 'CREDIT_NOTE', 'CREDIT_NOTE_REVERSED'));

CREATE TABLE IF NOT EXISTS bank_statement_imports (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id  UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    file_name    VARCHAR(255) NOT NULL,
    file_sha256  CHAR(64) NOT NULL,
    row_count    INT NOT NULL DEFAULT 0,
    created_by   UUID REFERENCES users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS bank_statement_lines (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    import_id            UUID NOT NULL REFERENCES bank_statement_imports(id) ON DELETE CASCADE,
    property_id          UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    line_no              INT NOT NULL,
    txn_date             DATE NOT NULL,
    amount               NUMERIC(14,2) NOT NULL,
    description          TEXT NOT NULL DEFAULT '',
    reference            VARCHAR(120),
    line_hash            CHAR(64) NOT NULL,
    status               VARCHAR(20) NOT NULL CHECK (status IN ('SUGGESTED','AMBIGUOUS','UNMATCHED','OUTGOING','DUPLICATE','CONFIRMED','IGNORED')),
    suggested_payment_id UUID REFERENCES payments(id),
    matched_payment_id   UUID REFERENCES payments(id),
    note                 TEXT,
    resolved_by          UUID REFERENCES users(id),
    resolved_at          TIMESTAMPTZ,
    CHECK (status <> 'CONFIRMED' OR matched_payment_id IS NOT NULL)
);
-- Aynı banka hareketi iki kez işlenmez (tekrar yüklenen satır DUPLICATE kaydedilir).
CREATE UNIQUE INDEX IF NOT EXISTS uq_bank_statement_lines_hash ON bank_statement_lines(property_id, line_hash) WHERE status <> 'DUPLICATE';
-- Bir ödeme tek banka hareketiyle eşleşir.
CREATE UNIQUE INDEX IF NOT EXISTS uq_bank_statement_lines_payment ON bank_statement_lines(matched_payment_id) WHERE matched_payment_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bank_statement_lines_import ON bank_statement_lines(import_id, line_no);

ALTER TABLE bank_statement_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_statement_imports FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bank_statement_imports_property_scope ON bank_statement_imports;
CREATE POLICY bank_statement_imports_property_scope ON bank_statement_imports
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
ALTER TABLE bank_statement_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_statement_lines FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS bank_statement_lines_property_scope ON bank_statement_lines;
CREATE POLICY bank_statement_lines_property_scope ON bank_statement_lines
    USING (property_id = current_property_id()) WITH CHECK (property_id = current_property_id());
REVOKE DELETE, TRUNCATE ON bank_statement_imports, bank_statement_lines FROM siteeksen_app;

COMMENT ON TABLE credit_notes IS 'Alacak dekontu: numaralı, gerekçeli, silinemez; borcu düşürür, tahsilat sayılmaz (Apsiyon BUG-12) — 059';
COMMENT ON TABLE bank_statement_lines IS 'Banka ekstresi satırları ve ödeme eşleştirmesi (Apsiyon BUG-12) — 059';
