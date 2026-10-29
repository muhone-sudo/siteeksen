# 7. Veritabanı kuralları ve bütünlük

> Bu dosya koddan üretilir (`bash docs/ozellik-haritasi/arac/uret.sh`); elle düzenlemeyin. Kurallar, hesaplar ve sorgular: [00-baslangic.md](00-baslangic.md).

Adminer (http://localhost:18080, `test_okuyucu`) salt okunurdur: buradan veri DEĞİŞTİRİLEMEZ, bu bilerek böyledir. Tetikleyicilerin engellediği işlemler arayüzden denenir; arayüz anlaşılır bir hata göstermeli, veri değişmemelidir.

## 7.1 Tetikleyiciler

| ID | Tablo | Tetikleyici | Ne zaman | Etki / engel | Nasıl denenir |
|---|---|---|---|---|---|
| T-BOOK-ENTRIES-NO-UPDATE | `book_entries` | `book_entries_no_update` | BEFORE UPDATE OR DELETE | engeller: Defter kaydı değiştirilemez veya silinemez (KMK m.32/36). Düzeltme için yeni kayıt açın. | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-CONSUMPTION-STATEMENT-OBJECT | `consumption_statement_objections` | `consumption_statement_objections_guard` | BEFORE UPDATE | engeller: Yanıtlanmış itiraz değiştirilemez | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-CREDIT-NOTES-GUARD | `credit_notes` | `credit_notes_guard` | BEFORE UPDATE | engeller: Alacak dekontu değiştirilemez; yalnızca bir kez gerekçeli ters kaydı yapılabilir | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-DOCUMENT-ACCESS-LOGS-NO-UPDA | `document_access_logs` | `document_access_logs_no_update` | BEFORE UPDATE OR DELETE | engeller: document_access_logs yalnızca eklenebilir; güncelleme/silme yasaktır (KVKK m.12) | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-DOCUMENTS-SUPERSEDE | `documents` | `documents_supersede` | AFTER INSERT | UPDATE documents | ilgili işlemi yap → `UPDATE documents` sonucu Adminer'de görünmeli |
| T-EXPENSE-UPDATED-AT | `expenses` | `expense_updated_at` | BEFORE UPDATE | satırı düzenler | ilgili işlemi yap → `satır düzenlemesi` sonucu Adminer'de görünmeli |
| T-LATE-FEE-ACCRUALS-ACTIVE-PRO | `late_fee_accruals` | `late_fee_accruals_active_property` | BEFORE INSERT | engeller: site pasif: gecikme tazminatı işletilemez | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-LEGAL-PARAMETERS-GUARD | `legal_parameters` | `legal_parameters_guard` | BEFORE INSERT OR UPDATE | engeller: Parametre "%" kanunla sabittir; site bazında değiştirilemez (KMK). | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-MONTHLY-ASSESSMENTS-ACTIVE-P | `monthly_assessments` | `monthly_assessments_active_property` | BEFORE INSERT | engeller: site pasif: % tablosuna yeni kayıt yazılamaz | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-MONTHLY-ASSESSMENTS-ACTIVE-P | `monthly_assessments` | `monthly_assessments_active_property_increase` | BEFORE UPDATE OF total_amount, late_fee | engeller: site pasif: tahakkuk tutarı artırılamaz | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-MONTHLY-ASSESSMENTS-GUARD | `monthly_assessments` | `monthly_assessments_guard` | BEFORE UPDATE | engeller: Tahakkukun sınıfı (kullanım/malik) değiştirilemez; düzeltme alacak dekontu ve yeni tahakkukla yapılır | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-TRG-MONTHLY-ASSESSMENTS-TENA | `monthly_assessments` | `trg_monthly_assessments_tenant_link` | BEFORE INSERT | satırı düzenler | ilgili işlemi yap → `satır düzenlemesi` sonucu Adminer'de görünmeli |
| T-NOTIFICATIONS-ACTIVE-PROPERT | `notifications` | `notifications_active_property` | BEFORE INSERT | engeller: site pasif: % tablosuna yeni kayıt yazılamaz | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-NOTIFICATIONS-SENT-FINAL | `notifications` | `notifications_sent_final` | BEFORE UPDATE OR DELETE | engeller: Gönderilmiş bildirim silinemez (haber verildiğinin kanıtıdır) | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-TRG-OWNER-VISIBILITY-GUARD | `owner_visibility_policies` | `trg_owner_visibility_guard` | BEFORE UPDATE | engeller: Görünürlük önerisi değiştirilemez; yeni öneri açılmalı | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-PAYMENT-ASSESSMENTS-GUARD | `payment_assessments` | `payment_assessments_guard` | BEFORE UPDATE | engeller: Ödeme-tahakkuk bağı değiştirilemez | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-PAYMENTS-GUARD | `payments` | `payments_guard` | BEFORE UPDATE | engeller: Sonuçlanmış ödeme silinemez | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-PAYROLL-GUARD | `payroll` | `payroll_guard` | BEFORE UPDATE | engeller: Sonuçlanmış bordro kaydı değiştirilemez (durum: %) | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-PROPERTY-SETTING-HISTORY-NO- | `property_setting_history` | `property_setting_history_no_change` | BEFORE UPDATE OR DELETE | engeller: property_setting_history yalnızca eklenebilir; değiştirilemez ve silinemez | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-PROPERTY-SETTINGS-GUARD-LEGA | `property_settings` | `property_settings_guard_legal_key` | BEFORE INSERT OR UPDATE OF setting_key | engeller: Mevzuat parametresi (%) site ayarı olarak yazılamaz; legal_parameters tablosundadır | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-TRG-RESIDENT-UNITS-TENANCY-G | `resident_units` | `trg_resident_units_tenancy_guard` | BEFORE UPDATE OF is_active, role | engeller: Kiracılık yalnız bitiş akışıyla biter (kiracının onayı, kendi çıkışı ya da yönetim yolu) | ilgili kaydı arayüzden değiştirmeyi/silmeyi dene → reddedilmeli |
| T-TRG-RESIDENT-UNITS-TENANT-AR | `resident_units` | `trg_resident_units_tenant_arrival` | AFTER INSERT OR UPDATE OF is_active, role | UPDATE resident_units | ilgili işlemi yap → `UPDATE resident_units` sonucu Adminer'de görünmeli |
| T-TRG-RESIDENT-UNITS-TENANT-DE | `resident_units` | `trg_resident_units_tenant_departure` | AFTER UPDATE OF is_active | UPDATE resident_units | ilgili işlemi yap → `UPDATE resident_units` sonucu Adminer'de görünmeli |

## 7.2 Bütünlük sorguları (testlerin sonunda çalıştırın)

#### D-RLS · RLS açık tablolar
- **Sorgu:** `SELECT count(*) FILTER (WHERE relrowsecurity) AS rls_acik, count(*) AS toplam FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'public' AND c.relkind = 'r';`
- **Beklenen:** rls_acik = 129 (bilerek dışarıda 10 tablo)
- **Sonuç:** `D-RLS`

#### D-PARA · Ödenen tutar tahakkuku aşmaz
- **Sorgu:** `SELECT id, total_amount, paid_amount FROM monthly_assessments WHERE paid_amount > total_amount;`
- **Beklenen:** 0 satır
- **Sonuç:** `D-PARA`

#### D-ODEME · Onaylı ödemenin dağıtımı tutarına eşit
- **Sorgu:** `SELECT p.id, p.amount, sum(pa.amount) FROM payments p JOIN payment_assessments pa ON pa.payment_id = p.id WHERE p.status = 'COMPLETED' GROUP BY 1,2 HAVING sum(pa.amount) <> p.amount;`
- **Beklenen:** 0 satır
- **Sonuç:** `D-ODEME`

#### D-DEFTER · Tahsilat defteri zinciri
- **Sorgu:** `SELECT count(*) FROM finance_ledger;`
- **Beklenen:** panelde/sakin uygulamasında "Tahsilat kayıtlarını doğrula" zincir sağlam demeli; sayı ödeme işlemleriyle artmış olmalı
- **Sonuç:** `D-DEFTER`

#### D-KARAR · Karar defteri değişmez
- **Sorgu:** `SELECT count(*) FROM book_entries;`
- **Beklenen:** kayıt eklenmiş; düzenleme/silme arayüzde yok ya da reddediliyor
- **Sonuç:** `D-KARAR`

#### D-AUDIT · İşlem kaydı eksiksiz
- **Sorgu:** `SELECT source, action, count(*) FROM audit_logs GROUP BY 1,2 ORDER BY 1,2;`
- **Beklenen:** API satırları her işlem türü için var; DENIED satırları yetki testlerinde oluşmuş; CLIENT satırları (ekran gezintisi) site ayarındaki düzeye göre
- **Sonuç:** `D-AUDIT`

#### D-KISI · Personel kişisel verisi şifreli
- **Sorgu:** `SELECT first_name, tc_number, tc_number_encrypted IS NOT NULL AS tc_sifreli, bank_iban, bank_iban_encrypted IS NOT NULL AS iban_sifreli, bank_iban_last4 FROM employees;`
- **Beklenen:** personel eklendiyse `tc_number` ve `bank_iban` BOŞ (NULL), şifreli sütunlar dolu; ekranda yalnız maskeli (son 4 hane) görünür
- **Sonuç:** `D-KISI`

#### D-SAKIN · Ayrılan sakine bildirim gitmez
- **Sorgu:** `SELECT u.phone, ru.is_active, ru.end_date FROM resident_units ru JOIN users u ON u.id = ru.resident_id ORDER BY ru.end_date NULLS FIRST;`
- **Beklenen:** pasifleştirilen sakin sonraki toplu bildirimlerin alıcısı değil (6. bölüm sorgularıyla karşılaştır)
- **Sonuç:** `D-SAKIN`

#### D-SITE · Her kayıt doğru sitede
- **Sorgu:** `SELECT property_id, count(*) FROM notifications GROUP BY 1;`
- **Beklenen:** Deniz Apartmanı satırları yalnız o sitedeki işlemlerden
- **Sonuç:** `D-SITE`

Not: sorgudaki bir sütun adı şemada farklıysa Adminer hata verir; o durumda tabloyu Adminer'de açıp ilgili sütunu bulun ve gözleme yazın (KALDI değil, sorgu düzeltilir).
