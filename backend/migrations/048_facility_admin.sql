-- =====================================================
-- 048 — TESİS TANIMLAMA (TEST_RAPORU 2.1)
--
-- Tesisler bugüne kadar yalnızca doğrudan SQL ile eklenebiliyordu; panelde ve API'de
-- tesis ekleme yoktu, demo sitede hiç tesis olmadığı için rezervasyon akışı
-- başlatılamıyordu. Bu migration:
--   * sakinin iptal edebileceği son saati (cancellation_deadline_hours) ekler —
--     0 = başlangıca kadar iptal serbest; yönetim her zaman iptal edebilir
--   * tesis kurallarını veritabanı kısıtıyla korur (API'yi yedekler)
--   * demo siteye iki tesis ekler (yalnızca SEED_DEMO_DATA açıkken)
-- =====================================================

ALTER TABLE facilities ADD COLUMN IF NOT EXISTS cancellation_deadline_hours INT NOT NULL DEFAULT 0;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'facilities_rules') THEN
        ALTER TABLE facilities ADD CONSTRAINT facilities_rules CHECK (
            length(trim(name)) > 0
            AND (capacity IS NULL OR capacity > 0)
            AND COALESCE(hourly_fee, 0) >= 0 AND COALESCE(daily_fee, 0) >= 0 AND COALESCE(deposit_amount, 0) >= 0
            AND (NOT COALESCE(is_paid, false) OR COALESCE(hourly_fee, 0) > 0 OR COALESCE(daily_fee, 0) > 0)
            AND COALESCE(available_from, TIME '08:00') < COALESCE(available_to, TIME '22:00')
            AND COALESCE(min_duration_minutes, 60) BETWEEN 15 AND 1440
            AND COALESCE(max_duration_minutes, 240) BETWEEN COALESCE(min_duration_minutes, 60) AND 1440
            AND COALESCE(advance_booking_days, 14) BETWEEN 1 AND 365
            AND COALESCE(max_reservations_per_unit, 2) BETWEEN 0 AND 50
            AND COALESCE(buffer_minutes, 0) BETWEEN 0 AND 240
            AND cancellation_deadline_hours BETWEEN 0 AND 720
            AND (NOT COALESCE(maintenance_mode, false) OR length(trim(COALESCE(maintenance_note, ''))) > 0)
        );
    END IF;
END $$;

COMMENT ON COLUMN facilities.cancellation_deadline_hours IS
    'Sakinin rezervasyonu iptal edebileceği son süre (başlangıçtan önce, saat); 0 = serbest — 048';

-- Demo tesisler (yalnızca geliştirme/demo; üretimde SEED_DEMO_DATA=false).
DO $seed$
BEGIN
    IF COALESCE(current_setting('siteeksen.seed_demo_data', true), 'true') <> 'true'
       OR NOT EXISTS (SELECT 1 FROM properties WHERE id = '11111111-1111-1111-1111-111111111111') THEN
        RETURN;
    END IF;
    INSERT INTO facilities (property_id, name, description, category, capacity, is_paid,
                            available_from, available_to, available_days, min_duration_minutes,
                            max_duration_minutes, advance_booking_days, max_reservations_per_unit,
                            buffer_minutes, requires_approval, auto_approve_residents,
                            cancellation_deadline_hours, rules)
    SELECT '11111111-1111-1111-1111-111111111111', 'Sosyal Tesis Toplantı Salonu',
           'Blok toplantıları ve aile etkinlikleri için', 'MEETING_ROOM', 30, false,
           '09:00', '22:00', '{0,1,2,3,4,5,6}', 60, 240, 30, 2, 30, true, false, 24,
           'Kullanım sonrası salon temiz bırakılır.'
    WHERE NOT EXISTS (SELECT 1 FROM facilities WHERE property_id = '11111111-1111-1111-1111-111111111111'
                      AND name = 'Sosyal Tesis Toplantı Salonu');
    INSERT INTO facilities (property_id, name, description, category, capacity, is_paid,
                            available_from, available_to, available_days, min_duration_minutes,
                            max_duration_minutes, advance_booking_days, max_reservations_per_unit,
                            buffer_minutes, requires_approval, auto_approve_residents,
                            cancellation_deadline_hours, rules)
    SELECT '11111111-1111-1111-1111-111111111111', 'Tenis Kortu', 'Açık hava kortu', 'TENNIS', 4, false,
           '08:00', '21:00', '{0,1,2,3,4,5,6}', 60, 120, 7, 3, 0, false, true, 2,
           'Kort ayakkabısı zorunludur.'
    WHERE NOT EXISTS (SELECT 1 FROM facilities WHERE property_id = '11111111-1111-1111-1111-111111111111'
                      AND name = 'Tenis Kortu');
END $seed$;
