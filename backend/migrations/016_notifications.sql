-- =====================================================
-- 016 — BİLDİRİM ALTYAPISI (S-10)
--
-- Neden: Projede bildirim gönderimi HİÇ YOKTU. `pkg/notification` (Firebase)
-- yazılmış ama hiçbir yerden import edilmiyordu; modüller "bildirim gönderildi"
-- diyor ama hiçbir şey göndermiyordu. Bu tablo, sağlayıcıdan bağımsız bir
-- GİDEN KUTUSU (outbox) kurar: her bildirim önce buraya yazılır, sonra bir
-- sağlayıcı tarafından gönderilir. Sağlayıcı yoksa kayıt PENDING kalır ve
-- hiçbir yerde "gönderildi" denmez.
--
-- Hukuki dayanak:
--   6563 s. Elektronik Ticaretin Düzenlenmesi Hakkında Kanun m.6 — TİCARİ
--   elektronik ileti için alıcının ÖNCEDEN ONAYI şarttır (ve İYS kaydı gerekir).
--   Site yönetiminin aidat, borç, arıza, genel kurul çağrısı gibi bildirimleri
--   ticari ileti DEĞİLDİR; hizmetin ifasına ilişkin bildirimdir. Bu ayrım
--   `category` kolonuyla veri modeline işlenmiştir: COMMERCIAL kategorisindeki
--   bildirim, açık onay olmadan gönderilemez (tetikleyiciyle engellenir).
--
--   6698 s. KVKK m.5 — iletişim verisinin işlenmesi; alıcı tercihleri
--   `notification_preferences` tablosunda tutulur ve saygı gösterilir.
--
--   634 s. KMK m.29 — genel kurul çağrısı bildirimi. DİKKAT: kanun çağrının
--   taahhütlü mektup ya da imza karşılığı yapılmasını arar; buradan gönderilen
--   elektronik bildirim USULÜNE UYGUN ÇAĞRI YERİNE GEÇMEZ, yalnızca hatırlatmadır.
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    property_id UUID NOT NULL REFERENCES properties(id),

    -- Alıcı. user_id NULL ise dış alıcıdır (örn. kargo firması, tedarikçi).
    recipient_user_id UUID REFERENCES users(id),
    recipient_address TEXT NOT NULL,   -- telefon, e-posta ya da cihaz jetonu

    channel VARCHAR(20) NOT NULL
        CHECK (channel IN ('IN_APP', 'PUSH', 'SMS', 'EMAIL')),

    -- Ticari / işlemsel ayrımı (6563 s. Kanun m.6).
    category VARCHAR(20) NOT NULL DEFAULT 'TRANSACTIONAL'
        CHECK (category IN ('TRANSACTIONAL', 'COMMERCIAL')),

    -- Bildirimin konusu: hangi modülden, neye dair.
    topic VARCHAR(50) NOT NULL,
    subject VARCHAR(255),
    body TEXT NOT NULL,
    payload JSONB DEFAULT '{}',

    -- Aynı olayın iki kez bildirilmemesi için. Örn: "aidat-hatirlatma-<unit>-2026-09".
    dedupe_key VARCHAR(200),

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'SUPPRESSED')),
    -- SUPPRESSED: alıcı tercihi ya da onay eksikliği nedeniyle GÖNDERİLMEDİ.
    suppress_reason TEXT,

    provider VARCHAR(50),              -- gerçekten kullanılan sağlayıcı
    provider_message_id VARCHAR(200),
    attempts INT NOT NULL DEFAULT 0,
    last_error TEXT,

    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at TIMESTAMPTZ,

    CONSTRAINT notifications_sent_needs_provider
        CHECK (status <> 'SENT' OR (provider IS NOT NULL AND sent_at IS NOT NULL)),
    CONSTRAINT notifications_suppressed_needs_reason
        CHECK (status <> 'SUPPRESSED' OR suppress_reason IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_notifications_property ON notifications(property_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_pending ON notifications(status) WHERE status = 'PENDING';

-- Aynı olay iki kez kuyruğa girmesin.
CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_dedupe
    ON notifications(property_id, dedupe_key) WHERE dedupe_key IS NOT NULL;

-- -----------------------------------------------------
-- Alıcı tercihleri
--
-- Varsayılan: işlemsel bildirimler AÇIK, ticari bildirimler KAPALI.
-- Ticari iletide varsayılanı açık yapmak 6563 s. Kanun m.6'ya aykırıdır
-- (önceden onay şarttır).
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID REFERENCES properties(id),
    channel VARCHAR(20) NOT NULL
        CHECK (channel IN ('IN_APP', 'PUSH', 'SMS', 'EMAIL')),
    category VARCHAR(20) NOT NULL
        CHECK (category IN ('TRANSACTIONAL', 'COMMERCIAL')),
    enabled BOOLEAN NOT NULL DEFAULT true,
    -- Ticari ileti onayının ne zaman ve nasıl alındığı (6563 s. Kanun m.6/İYS).
    consent_at TIMESTAMPTZ,
    consent_source VARCHAR(50),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(user_id, property_id, channel, category),
    CONSTRAINT notification_prefs_commercial_needs_consent
        CHECK (category <> 'COMMERCIAL' OR enabled = false OR consent_at IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_notification_prefs_user ON notification_preferences(user_id);

-- -----------------------------------------------------
-- Gönderim kayıtları değiştirilemez alanlar
--
-- Bir bildirimin "gönderildi" kaydı sonradan silinirse, sakine haber verildiğinin
-- kanıtı kaybolur. Bu yüzden SENT kaydı geri alınamaz.
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION notifications_sent_is_final()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.status = 'SENT' THEN
            RAISE EXCEPTION 'Gönderilmiş bildirim silinemez (haber verildiğinin kanıtıdır)';
        END IF;
        RETURN OLD;
    END IF;

    IF OLD.status = 'SENT' AND NEW.status <> 'SENT' THEN
        RAISE EXCEPTION 'Gönderilmiş bildirimin durumu değiştirilemez';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notifications_sent_final ON notifications;
CREATE TRIGGER notifications_sent_final
    BEFORE UPDATE OR DELETE ON notifications
    FOR EACH ROW EXECUTE FUNCTION notifications_sent_is_final();
