-- Teklif seçildikten sonra içerik kilidi (kullanıcı kararı 2026-11-02): seçilen teklif ve talebin içeriği iki taraf
-- için de değişmez. API bu yolları zaten kapatıyor (talep CLOSED → teklif/fotoğraf 409, yalnız etkin teklif geri çekilir);
-- tetikleyici aynı kuralı veritabanında da uygular.

CREATE OR REPLACE FUNCTION mp_offer_accepted_lock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = 'ACCEPTED' AND (NEW.status, NEW.amount_kurus, NEW.description, NEW.valid_until, NEW.account_id,
            NEW.business_id, NEW.request_id, NEW.dispatch_id, NEW.edit_count)
        IS DISTINCT FROM (OLD.status, OLD.amount_kurus, OLD.description, OLD.valid_until, OLD.account_id,
            OLD.business_id, OLD.request_id, OLD.dispatch_id, OLD.edit_count) THEN
        RAISE EXCEPTION 'Seçilen teklif değiştirilemez' USING ERRCODE = 'SE002';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS mp_offers_accepted_lock ON mp_offers;
CREATE TRIGGER mp_offers_accepted_lock BEFORE UPDATE ON mp_offers
    FOR EACH ROW EXECUTE FUNCTION mp_offer_accepted_lock();

CREATE OR REPLACE FUNCTION mp_request_closed_lock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = 'CLOSED' AND (NEW.status, NEW.description, NEW.photo_keys, NEW.preferred_time, NEW.phone_hidden,
            NEW.category_id, NEW.buyer_type, NEW.unit_id, NEW.target_business_id, NEW.city, NEW.district,
            NEW.latitude, NEW.longitude, NEW.requester_user_id, NEW.property_id)
        IS DISTINCT FROM (OLD.status, OLD.description, OLD.photo_keys, OLD.preferred_time, OLD.phone_hidden,
            OLD.category_id, OLD.buyer_type, OLD.unit_id, OLD.target_business_id, OLD.city, OLD.district,
            OLD.latitude, OLD.longitude, OLD.requester_user_id, OLD.property_id) THEN
        RAISE EXCEPTION 'Teklifi seçilmiş talep değiştirilemez' USING ERRCODE = 'SE002';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS mp_requests_closed_lock ON mp_requests;
CREATE TRIGGER mp_requests_closed_lock BEFORE UPDATE ON mp_requests
    FOR EACH ROW EXECUTE FUNCTION mp_request_closed_lock();
