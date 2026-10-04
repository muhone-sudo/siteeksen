-- =====================================================
-- 038 — SİTE AYARLARI MEVZUAT PARAMETRESİNİ GÖLGELEYEMEZ (tetikleyici)
--
-- 017'deki property_settings_no_legal_keys kısıtı sabit bir ön ek listesine
-- dayanıyordu; sonradan eklenen parametreler (KVKK_RESPONSE_DAYS,
-- BUDGET_GA_APPROVAL_MONTHS, REVALUATION_RATE, MANAGER_MANDATORY_UNIT_COUNT…)
-- listede olmadığı için doğrudan SQL ile aynı adla site ayarı yazılabiliyordu.
-- Liste her yeni parametrede elle güncellenmek zorunda kalırdı ve unutulurdu.
--
-- Tetikleyici, anahtarın legal_parameters'ta KOD olarak var olup olmadığına
-- bakar: yeni parametre eklendiği anda koruma kendiliğinden kapsar.
-- 017 kısıtı ek savunma olarak yerinde kalır.
-- =====================================================

CREATE OR REPLACE FUNCTION property_settings_guard_legal_key()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM legal_parameters WHERE upper(code) = upper(NEW.setting_key)) THEN
        RAISE EXCEPTION 'Mevzuat parametresi (%) site ayarı olarak yazılamaz; legal_parameters tablosundadır', NEW.setting_key
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS property_settings_guard_legal_key ON property_settings;
CREATE TRIGGER property_settings_guard_legal_key
    BEFORE INSERT OR UPDATE OF setting_key ON property_settings
    FOR EACH ROW EXECUTE FUNCTION property_settings_guard_legal_key();
