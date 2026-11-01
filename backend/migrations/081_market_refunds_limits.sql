-- 081: Usta & Hizmet M13 — mesaj/teklif hız sınırı, bakiye koşullarının ayrıca kabulü (TBK m.21), kalan bakiyenin karta iadesi.

INSERT INTO mp_settings (key, value_int, description) VALUES
    ('message_per_minute_limit', 20, 'Bir kişinin bir dakikada gönderebileceği en çok mesaj'),
    ('message_per_day_limit', 300, 'Bir kişinin bir günde gönderebileceği en çok mesaj'),
    ('offer_per_hour_limit', 20, 'Bir tedarikçi hesabının bir saatte verebileceği en çok yeni teklif'),
    ('offer_edit_limit', 5, 'Bir teklifin en çok kaç kez düzenlenebileceği'),
    ('card_refund_max_attempts', 5, 'Karta iade başarısız olursa en çok deneme; sonra platformun elle işlem kuyruğuna düşer')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE mp_offers ADD COLUMN IF NOT EXISTS edit_count INT NOT NULL DEFAULT 0 CHECK (edit_count >= 0);

-- Ödeme dönüşünün yönleneceği yer: panel (/tedarikci/bakiye) ya da tedarikçi uygulaması (M13.1). Adresler sunucu ayarıdır;
-- istemci yalnız hangisini istediğini söyler (açık yönlendirme yok).
ALTER TABLE mp_topups ADD COLUMN IF NOT EXISTS return_target VARCHAR(5) NOT NULL DEFAULT 'PANEL' CHECK (return_target IN ('PANEL', 'APP'));

-- Defter: karta iade (kalan bakiye karta döner) ve süresi dolan bakiye (365 günü geçen yüklemelerden kalan, sözleşme gereği iade edilmez).
ALTER TABLE mp_wallet_ledger DROP CONSTRAINT IF EXISTS mp_wallet_ledger_kind_check;
ALTER TABLE mp_wallet_ledger ADD CONSTRAINT mp_wallet_ledger_kind_check CHECK (kind IN
    ('TOPUP', 'PACKAGE_FEE', 'REQUEST_FEE', 'INCLUDED_REQUEST', 'REFUND', 'CLOSURE_REFUND', 'CARD_REFUND', 'EXPIRED_BALANCE'));
ALTER TABLE mp_wallet_ledger DROP CONSTRAINT IF EXISTS mp_ledger_sign;
ALTER TABLE mp_wallet_ledger ADD CONSTRAINT mp_ledger_sign CHECK (
    (kind IN ('TOPUP', 'REFUND') AND amount_kurus > 0) OR
    (kind IN ('PACKAGE_FEE', 'REQUEST_FEE', 'CLOSURE_REFUND', 'CARD_REFUND', 'EXPIRED_BALANCE') AND amount_kurus < 0) OR
    (kind = 'INCLUDED_REQUEST' AND amount_kurus = 0));

-- Koşul kabulü: hangi hesap, hangi kullanıcı, hangi metnin hangi sürümünü ne zaman kabul etti.
CREATE TABLE IF NOT EXISTS mp_terms_acceptances (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id   UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    user_id      UUID NOT NULL REFERENCES users(id),
    terms_key    VARCHAR(40) NOT NULL,
    version      VARCHAR(20) NOT NULL,
    text_sha256  CHAR(64) NOT NULL,
    ip           VARCHAR(64) NOT NULL DEFAULT '',
    accepted_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (account_id, terms_key, version)
);

-- Karta iade: her satır bir yüklemenin (iyzico ödemesinin) kısmi ya da tam iadesidir.
CREATE TABLE IF NOT EXISTS mp_card_refunds (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id        UUID NOT NULL REFERENCES mp_supplier_accounts(id),
    topup_id          UUID NOT NULL REFERENCES mp_topups(id),
    amount_kurus      BIGINT NOT NULL CHECK (amount_kurus > 0),
    reason            VARCHAR(20) NOT NULL CHECK (reason IN ('CLOSURE', 'LATE_TOPUP', 'CLOSED_ACCOUNT')),
    ledger_id         UUID REFERENCES mp_wallet_ledger(id),
    status            VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SUCCEEDED', 'FAILED', 'MANUAL')),
    attempts          INT NOT NULL DEFAULT 0,
    next_attempt_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error        TEXT,
    gateway_reference VARCHAR(100),
    manual_reference  VARCHAR(100),
    manual_date       DATE,
    resolved_by       UUID REFERENCES users(id),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at      TIMESTAMPTZ,
    CONSTRAINT mp_card_refund_manual CHECK (status <> 'MANUAL' OR (manual_reference IS NOT NULL AND manual_date IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS idx_mp_card_refunds_topup ON mp_card_refunds (topup_id);
CREATE INDEX IF NOT EXISTS idx_mp_card_refunds_account ON mp_card_refunds (account_id);
CREATE INDEX IF NOT EXISTS idx_mp_card_refunds_due ON mp_card_refunds (next_attempt_at) WHERE status = 'PENDING';

ALTER TABLE mp_terms_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE mp_terms_acceptances FORCE ROW LEVEL SECURITY;
ALTER TABLE mp_card_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE mp_card_refunds FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mp_terms_acceptances_scope ON mp_terms_acceptances;
CREATE POLICY mp_terms_acceptances_scope ON mp_terms_acceptances
    USING (account_id = current_supplier_account_id() OR platform_scope())
    WITH CHECK (account_id = current_supplier_account_id() OR platform_scope());
DROP POLICY IF EXISTS mp_card_refunds_scope ON mp_card_refunds;
CREATE POLICY mp_card_refunds_scope ON mp_card_refunds
    USING (account_id = current_supplier_account_id() OR platform_scope())
    WITH CHECK (account_id = current_supplier_account_id() OR platform_scope());

-- Mesaj hız sınırı: kişinin bütün yazışmalarındaki mesajları sayar (alıcı birden çok sitede olabilir; site kapsamı yalnız birini görür).
CREATE OR REPLACE FUNCTION mp_user_message_count(p_user UUID, p_since TIMESTAMPTZ)
RETURNS INT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
    SELECT count(*)::int FROM mp_messages WHERE sender_user_id = p_user AND created_at >= p_since
$$;
REVOKE ALL ON FUNCTION mp_user_message_count(UUID, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mp_user_message_count(UUID, TIMESTAMPTZ) TO siteeksen_app;

GRANT SELECT, INSERT ON mp_terms_acceptances TO siteeksen_app;
GRANT SELECT, INSERT, UPDATE ON mp_card_refunds TO siteeksen_app;

COMMENT ON TABLE mp_terms_acceptances IS 'Tedarikçinin ayrıca kabul ettiği koşul metinleri (sürüm + metin özeti) — 081';
COMMENT ON TABLE mp_card_refunds IS 'Kalan bakiyenin karta iadesi (iyzico); başarısızsa platform elle havale kaydeder — 081';
