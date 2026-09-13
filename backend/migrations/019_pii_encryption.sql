-- =====================================================
-- 019 — KİŞİSEL VERİ ŞİFRELEMESİ (TCKN / IBAN)
--
-- Neden: TCKN ve IBAN veritabanında DÜZ METİN duruyordu. `pkg/encryption`
-- yazılmış ama hiçbir yerden import edilmiyordu. Tek bir yedek dosyasının ya da
-- veritabanı sızıntısının bedeli, çalışanların kimlik numarası ve banka hesabıdır.
--
-- Hukuki dayanak:
--   6698 s. KVKK m.12/1 — veri sorumlusu, kişisel verilerin hukuka aykırı
--   erişimini önlemek için UYGUN GÜVENLİK DÜZEYİNİ sağlamakla yükümlüdür.
--   KVKK Kurumu'nun "Kişisel Veri Güvenliği Rehberi" özel önem taşıyan verilerin
--   şifreli saklanmasını açıkça önerir.
--   5490 s. Nüfus Hizmetleri Kanunu m.45 — TCKN'nin kullanımı sınırlıdır.
--
-- Tasarım:
--   *_encrypted  → AES-256-GCM ile şifrelenmiş değer (uygulama katmanında)
--   *_index      → HMAC-SHA256 arama anahtarı (blind index)
--   *_last4      → yalnızca gösterim için son dört hane
--
-- Neden ayrı arama anahtarı: şifreli metin her seferinde farklıdır (nonce),
-- bu yüzden eşitlik araması yapılamaz. Neden düz SHA-256 değil: TCKN 11 hanedir
-- ve anahtarsız bir özet kaba kuvvetle geri çevrilebilir.
--
-- Neden gösterim için ayrı kolon: liste ekranında "IBAN son 4 hane" göstermek
-- için her satırı çözmek gerekseydi, her listeleme tüm IBAN'ları düz metin
-- olarak belleğe getirirdi.
--
-- DÜZ METİN KOLONLAR BU MIGRATION'DA SİLİNMEZ. Mevcut satırların şifrelenmesi
-- uygulama anahtarını gerektirir; `cmd/encrypt-pii` bunu yapar ve düz metni
-- NULL'lar. Kolonun düşürülmesi ayrı bir migration'a bırakılmıştır: veri
-- taşınmadan kolon düşürmek, geri dönüşü olmayan veri kaybıdır.
-- =====================================================

ALTER TABLE employees
    ADD COLUMN IF NOT EXISTS tc_number_encrypted TEXT,
    ADD COLUMN IF NOT EXISTS tc_number_index     CHAR(64),
    ADD COLUMN IF NOT EXISTS bank_iban_encrypted TEXT,
    ADD COLUMN IF NOT EXISTS bank_iban_index     CHAR(64),
    ADD COLUMN IF NOT EXISTS bank_iban_last4     VARCHAR(4),
    ADD COLUMN IF NOT EXISTS pii_encrypted_at    TIMESTAMPTZ;

-- Arama anahtarı üzerinden eşitlik sorgusu.
CREATE INDEX IF NOT EXISTS idx_employees_tc_index   ON employees(tc_number_index);
CREATE INDEX IF NOT EXISTS idx_employees_iban_index ON employees(bank_iban_index);

-- Aynı TCKN ile ikinci bir AKTİF personel kaydı açılamaz.
-- Düz metin kolonda böyle bir kısıt yoktu; aynı kişi iki kez kaydedilip iki maaş
-- alabilirdi. Kısmi indeks: işten ayrılmış kayıtlar bu kısıta girmez.
CREATE UNIQUE INDEX IF NOT EXISTS uq_employees_tc_active
    ON employees(property_id, tc_number_index)
    WHERE tc_number_index IS NOT NULL AND COALESCE(is_active, true);

-- -----------------------------------------------------
-- Şifreleme durumu görünümü
--
-- "Hangi kayıtlar hâlâ düz metin?" sorusunun cevabı tek sorguyla görülebilmeli;
-- aksi hâlde taşımanın tamamlandığı sanılır ve düz metin satırlar unutulur.
-- -----------------------------------------------------
CREATE OR REPLACE VIEW pii_encryption_status AS
SELECT
    'employees'::text AS table_name,
    count(*)                                                      AS total_rows,
    count(*) FILTER (WHERE tc_number IS NOT NULL)                 AS plaintext_tc,
    count(*) FILTER (WHERE tc_number_encrypted IS NOT NULL)       AS encrypted_tc,
    count(*) FILTER (WHERE bank_iban IS NOT NULL)                 AS plaintext_iban,
    count(*) FILTER (WHERE bank_iban_encrypted IS NOT NULL)       AS encrypted_iban
FROM employees;

COMMENT ON VIEW pii_encryption_status IS
    'Kişisel verilerin şifrelenme durumu. plaintext_* sütunları SIFIR olmalıdır; '
    'değilse cmd/encrypt-pii çalıştırılmamıştır.';
