#!/usr/bin/env bash
# Yedekten geri yükleme — başarısız ya da hatalı bir migration'ı GERİ ALMANIN
# tek güvenli yolu. Yordam ve gerekçe: docs/runbook-veritabani-geri-alma.md
#
#   DATABASE_URL=... CONFIRM_RESTORE=<veritabanı adı> bash backend/scripts/db-restore.sh yedek.dump
#
# Veritabanındaki MEVCUT şemayı ve veriyi yedektekiyle DEĞİŞTİRİR. Yedekten sonra
# yazılan kayıtlar (ödeme, denetim izi…) kaybolur; bu yüzden yazmalar durdurulmuş
# olmalıdır (servisler kapalı). Yanlış veritabanına uygulanmasın diye adı açıkça
# onaylatılır.
set -euo pipefail

IN=${1:?kullanım: db-restore.sh <yedek.dump>}
: "${DATABASE_URL:?DATABASE_URL (tablo sahibi / süper kullanıcı) gerekli}"
[ -r "$IN" ] || { echo "yedek okunamıyor: $IN" >&2; exit 1; }

DB=$(psql "$DATABASE_URL" -tAc "SELECT current_database()")
if [ "${CONFIRM_RESTORE:-}" != "$DB" ]; then
  echo "Geri yükleme '$DB' veritabanının içeriğini DEĞİŞTİRİR." >&2
  echo "Onay için CONFIRM_RESTORE=$DB verin." >&2
  exit 2
fi

pg_restore --list "$IN" >/dev/null

# YETKİLERİN KORUNMASI (2026-10-10): 020'deki ALTER DEFAULT PRIVILEGES, pg_restore'un
# yeniden oluşturduğu HER tabloya uygulama rolü için SELECT/INSERT/UPDATE/DELETE verir;
# pg_dump ise tablo yetkilerini "yalnızca sahip" başlangıcına göre yazar. Sonuç: göçlerin
# REVOKE ettiği yetkiler (ödeme/defter silme, sonuçlanmış kaydı değiştirme…) geri yüklemeden
# sonra SESSİZCE geri geliyordu. Geri yükleme süresince varsayılan yetkiler askıya alınır;
# tablolar yedekteki yetkilerle birebir kurulur, varsayılanlar her durumda geri verilir.
DEFAULTS_GRANT="ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO siteeksen_app;"
restore_defaults() { psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -c "$DEFAULTS_GRANT" >/dev/null; }
trap restore_defaults EXIT
psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON SEQUENCES FROM siteeksen_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM siteeksen_app;" >/dev/null

# Tek transaction: yarıda kalan geri yükleme yarım bir şema bırakmaz.
# --clean --if-exists: yedekteki nesneler önce kaldırılır, sonra yeniden kurulur;
# yedekten SONRA eklenen nesneler (başarısız migration'ın tabloları) ayrıca
# temizlenmezse kalır — bu yüzden sürüm tablosu ile şema aşağıda karşılaştırılır.
pg_restore --clean --if-exists --single-transaction --no-password --exit-on-error \
  --dbname="$DATABASE_URL" "$IN"

VER=$(psql "$DATABASE_URL" -tAc "SELECT COALESCE(max(version),0) FROM schema_migrations")
echo "geri yüklendi: $DB, şema sürümü: $VER"

# Yedekte OLMAYAN tablolar (yedekten sonra, örneğin başarısız migration'ın
# oluşturduğu) --clean ile kaldırılmaz. Kendiliğinden silmek, bilinmeyen bir
# tabloyu yok etmek olurdu; operatöre gösterilir ve çıkış kodu 3 olur.
DUMPED=$(pg_restore --list "$IN" | awk '$4=="TABLE" && $5=="public" {print $6}' | sort -u)
LIVE=$(psql "$DATABASE_URL" -tAc "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY 1")
EXTRA=$(comm -13 <(echo "$DUMPED") <(echo "$LIVE") | tr '\n' ' ')
if [ -n "${EXTRA// /}" ]; then
  echo "UYARI: yedekte olmayan tablolar kaldı: $EXTRA" >&2
  echo "Yedekten sonra oluşturulmuşlar (başarısız migration?). İnceleyip elle kaldırın." >&2
  exit 3
fi
echo "Sonraki adım: 'go run ./cmd/migrate -status' ile sürümü doğrulayın; düzeltilmiş"
echo "migration YENİ bir numarayla eklenir (uygulanmış dosya düzenlenmez)."
