-- SiteEksen Seed Data
-- Migration: 002_seed_data.sql
--
-- UYARI: Bu dosya yalnızca GELİŞTİRME/DEMO içindir. Üretim ortamında çalıştırılmamalıdır;
-- bilinen şifreli hesap açar. Üretimde `SEED_DEMO_DATA=false` ile atlanmalıdır
-- (bkz. backend/scripts/init-db.sh ve tasks/todo.md 1.7b).
--
-- DÜZELTME (2026-09-13):
--   1. IDEMPOTENCY (madde 1.4): Dosya daha önce tekrar çalıştırıldığında birincil anahtar
--      çakışmasıyla patlıyordu. Artık tüm blok bir koruma altında: demo site zaten varsa
--      hiçbir şey yapılmaz.
--   2. TUTARLILIK (madde 1.8): `properties.total_units` 24 diyor ama yalnızca 6 bağımsız
--      bölüm ekleniyordu; `total_share_ratio` 10000 iken birimlerin arsa payı toplamı 2480'di.
--      Bu tutarsızlık, aidat dağıtım matematiğini (KMK m.20) test edilemez hâle getiriyordu:
--      arsa payına göre dağıtımda payda yanlış olduğu için her tahakkuk hatalı çıkardı.
--      Artık 24 bağımsız bölüm var ve arsa payları **tam olarak 10000** ediyor.

DO $seed$
BEGIN

-- ÜRETİM KORUMASI (madde 1.7b): Demo veri yalnızca açıkça izin verildiğinde yüklenir.
-- `cmd/migrate` bu ayarı SEED_DEMO_DATA ortam değişkeninden doldurur (varsayılan: true).
-- Üretimde SEED_DEMO_DATA=false verilir; migration uygulanmış sayılır (sürüm zinciri
-- kırılmaz) ama bilinen şifreli demo hesaplar açılmaz.
IF COALESCE(current_setting('siteeksen.seed_demo_data', true), 'true') <> 'true' THEN
    RAISE NOTICE 'SEED_DEMO_DATA kapalı — demo veri yüklenmiyor.';
    RETURN;
END IF;

IF EXISTS (SELECT 1 FROM properties WHERE id = '11111111-1111-1111-1111-111111111111') THEN
    RAISE NOTICE 'Demo veri zaten yüklü — 002_seed_data atlanıyor.';
    RETURN;
END IF;

-- =====================================================
-- Demo Site
-- =====================================================
-- total_share_ratio: 24 bağımsız bölümün arsa payı toplamı (aşağıda birebir 10000 eder)
INSERT INTO properties (id, name, address, city, district, total_share_ratio, total_units) VALUES
('11111111-1111-1111-1111-111111111111', 'Güneş Sitesi', 'Atatürk Cad. No:123', 'İstanbul', 'Kadıköy', 10000, 24);

-- Bloklar
INSERT INTO blocks (id, property_id, name, floor_count) VALUES
('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111', 'A Blok', 6),
('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'B Blok', 6);

-- =====================================================
-- Bağımsız Bölümler — 2 blok x 12 daire = 24
-- Arsa payı toplamı: A Blok 5000 + B Blok 5000 = 10000
-- Kat başına: zemin 380, 1. kat 410, 2-3. kat 415, 4. kat 420, 5. kat (çatı) 460
-- =====================================================
INSERT INTO units (id, property_id, block_id, block, floor, door_number, share_ratio, gross_area_m2, unit_type, is_ground_floor) VALUES
-- A Blok
('33333333-3333-3333-3333-333333333301', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 0, '1',  380, 85,  'APARTMENT', true),
('33333333-3333-3333-3333-333333333302', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 0, '2',  380, 85,  'APARTMENT', true),
('33333333-3333-3333-3333-333333333303', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 1, '3',  410, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333304', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 1, '4',  410, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333305', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 2, '5',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333306', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 2, '6',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333307', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 3, '7',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333308', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 3, '8',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333309', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 4, '9',  420, 100, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333310', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 4, '10', 420, 100, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333311', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 5, '11', 460, 110, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333312', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222221', 'A', 5, '12', 460, 110, 'APARTMENT', false),
-- B Blok
('33333333-3333-3333-3333-333333333321', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 0, '1',  380, 85,  'APARTMENT', true),
('33333333-3333-3333-3333-333333333322', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 0, '2',  380, 85,  'APARTMENT', true),
('33333333-3333-3333-3333-333333333323', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 1, '3',  410, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333324', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 1, '4',  410, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333325', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 2, '5',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333326', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 2, '6',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333327', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 3, '7',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333328', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 3, '8',  415, 95,  'APARTMENT', false),
('33333333-3333-3333-3333-333333333329', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 4, '9',  420, 100, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333330', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 4, '10', 420, 100, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333331', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 5, '11', 460, 110, 'APARTMENT', false),
('33333333-3333-3333-3333-333333333332', '11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', 'B', 5, '12', 460, 110, 'APARTMENT', false);

-- =====================================================
-- Demo Kullanıcılar — Şifre: Demo123!
--
-- DÜZELTME (2026-09-12): Buradaki bcrypt hash BOZUKTU. `demo123`, `Demo123!`, `Demo123`,
-- `demo1234`, `password`, `123456`, `siteeksen` gibi aday şifrelerin HİÇBİRİ ile eşleşmiyordu
-- (bcrypt ile fiilen test edildi). Üstelik iki kullanıcıya AYNI hash yazılmıştı — oysa bcrypt
-- her çağrıda farklı salt üretir; bu, değerin gerçek bir hash değil kopyala-yapıştır bir
-- yer tutucu olduğunun işaretiydi.
--
-- Aşağıdaki hash'ler `bcrypt.GenerateFromPassword(cost=12)` ile üretildi ve üretildikten hemen
-- sonra `bcrypt.CompareHashAndPassword` ile doğrulandı. Her kullanıcı için ayrı salt kullanıldı.
-- =====================================================
INSERT INTO users (id, first_name, last_name, phone, email, password_hash, active_property_id, roles) VALUES
('44444444-4444-4444-4444-444444444401', 'Ahmet', 'Yılmaz', '+905551234567', 'ahmet@example.com',
 '$2a$12$jLt6qcUb2lnr4/h4fWWnAOdMsIwPAQBnlSdkWfv9/yG4EBcOJEdXm', -- Demo123!
 '11111111-1111-1111-1111-111111111111', ARRAY['RESIDENT', 'OWNER']),
('44444444-4444-4444-4444-444444444402', 'Mehmet', 'Demir', '+905559876543', 'mehmet@example.com',
 '$2a$12$y2HxX/x04.wWORM2eymgv.6Pi8.PAYYe3JrcEUvWjYXGkk0HmBwfq', -- Demo123!
 '11111111-1111-1111-1111-111111111111', ARRAY['RESIDENT', 'TENANT']);

-- Sakin-Daire İlişkileri
INSERT INTO resident_units (resident_id, unit_id, role, start_date) VALUES
('44444444-4444-4444-4444-444444444401', '33333333-3333-3333-3333-333333333303', 'OWNER', '2020-01-01'),
('44444444-4444-4444-4444-444444444402', '33333333-3333-3333-3333-333333333304', 'TENANT', '2024-06-01');

-- =====================================================
-- Gider Kalemleri
-- Dağıtım türleri KMK m.20'ye göre: kapıcı/kaloriferci/bahçıvan/bekçi giderleri ve yönetim
-- gideri EŞİT; sigorta primi, ortak yer bakım-onarımı ve ortak tesis işletme gideri ARSA PAYI.
-- (Oranların hukuki teyidi: tasks/questions.md S-05)
-- =====================================================
INSERT INTO expense_categories (id, property_id, name, distribution_type, applies_to_ground_floor, sort_order) VALUES
('55555555-5555-5555-5555-555555555501', '11111111-1111-1111-1111-111111111111', 'Genel Yönetim', 'EQUAL', true, 1),
('55555555-5555-5555-5555-555555555502', '11111111-1111-1111-1111-111111111111', 'Asansör Bakım', 'SHARE_RATIO', false, 2),
('55555555-5555-5555-5555-555555555503', '11111111-1111-1111-1111-111111111111', 'Temizlik Personeli', 'EQUAL', true, 3),
('55555555-5555-5555-5555-555555555504', '11111111-1111-1111-1111-111111111111', 'Bahçe Bakım', 'EQUAL', true, 4),
('55555555-5555-5555-5555-555555555505', '11111111-1111-1111-1111-111111111111', 'Ortak Elektrik', 'SHARE_RATIO', true, 5),
('55555555-5555-5555-5555-555555555506', '11111111-1111-1111-1111-111111111111', 'Isınma', 'METER_READING', true, 6);

-- Demo Aidatlar (Son 3 ay)
INSERT INTO monthly_assessments (id, property_id, unit_id, period_year, period_month, base_amount, late_fee, total_amount, due_date, status, paid_amount) VALUES
-- Ahmet Yılmaz - A-3
('66666666-6666-6666-6666-666666666601', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333303', 2026, 1, 1200.00, 0, 1200.00, '2026-01-10', 'PENDING', 0),
('66666666-6666-6666-6666-666666666602', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333303', 2025, 12, 1150.00, 0, 1150.00, '2025-12-10', 'PAID', 1150.00),
('66666666-6666-6666-6666-666666666603', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333303', 2025, 11, 1150.00, 0, 1150.00, '2025-11-10', 'PAID', 1150.00);

-- Sayaçlar
INSERT INTO meters (id, unit_id, meter_type, serial_number, brand) VALUES
('77777777-7777-7777-7777-777777777701', '33333333-3333-3333-3333-333333333303', 'HEAT', 'ISI-A3-001', 'Siemens'),
('77777777-7777-7777-7777-777777777702', '33333333-3333-3333-3333-333333333303', 'WATER_COLD', 'SU-A3-001', 'Danfoss');

-- Sayaç Okumaları (Son 6 ay ısı)
INSERT INTO meter_readings (meter_id, reading_date, previous_value, current_value, reading_type) VALUES
('77777777-7777-7777-7777-777777777701', '2025-08-01', 0, 850, 'AUTOMATIC'),
('77777777-7777-7777-7777-777777777701', '2025-09-01', 850, 1120, 'AUTOMATIC'),
('77777777-7777-7777-7777-777777777701', '2025-10-01', 1120, 1580, 'AUTOMATIC'),
('77777777-7777-7777-7777-777777777701', '2025-11-01', 1580, 2150, 'AUTOMATIC'),
('77777777-7777-7777-7777-777777777701', '2025-12-01', 2150, 2890, 'AUTOMATIC'),
('77777777-7777-7777-7777-777777777701', '2026-01-01', 2890, 3750, 'AUTOMATIC');

-- Tüketim Tarifeleri
INSERT INTO consumption_tariffs (property_id, meter_type, effective_from, unit_price, fixed_fee, tax_rate) VALUES
('11111111-1111-1111-1111-111111111111', 'HEAT', '2025-01-01', 0.85, 25.00, 18.00),
('11111111-1111-1111-1111-111111111111', 'WATER_COLD', '2025-01-01', 32.50, 15.00, 8.00);

-- Talep Kategorileri
INSERT INTO request_categories (id, property_id, name, icon, sla_hours) VALUES
('88888888-8888-8888-8888-888888888801', '11111111-1111-1111-1111-111111111111', 'Asansör', 'elevator', 4),
('88888888-8888-8888-8888-888888888802', '11111111-1111-1111-1111-111111111111', 'Temizlik', 'cleaning', 24),
('88888888-8888-8888-8888-888888888803', '11111111-1111-1111-1111-111111111111', 'Güvenlik', 'security', 2),
('88888888-8888-8888-8888-888888888804', '11111111-1111-1111-1111-111111111111', 'Bahçe', 'garden', 48),
('88888888-8888-8888-8888-888888888805', '11111111-1111-1111-1111-111111111111', 'Diğer', 'other', 72);

-- Demo Duyuru
INSERT INTO announcements (property_id, title, content, category, priority, created_by) VALUES
('11111111-1111-1111-1111-111111111111', 'Asansör Bakımı',
 'Sayın Sakinlerimiz, 5 Şubat 2026 Perşembe günü saat 10:00-14:00 arasında asansör periyodik bakımı yapılacaktır. Bu süre zarfında asansörler kullanılamayacaktır. Anlayışınız için teşekkür ederiz.',
 'MAINTENANCE', 'HIGH', '44444444-4444-4444-4444-444444444401');

-- Yönetim Kadrosu
INSERT INTO management_staff (property_id, user_id, title, phone, start_date) VALUES
('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444401', 'Yönetim Kurulu Başkanı', '+905551234567', '2024-01-01');

END
$seed$;
