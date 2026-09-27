#!/usr/bin/env bash
# Veritabanı yedeği — migration geri alma yordamının İLK adımı.
# Yordam ve gerekçe: docs/runbook-veritabani-geri-alma.md
#
#   DATABASE_URL=postgres://<sahip>@host/db bash backend/scripts/db-backup.sh yedek.dump
#
# Sahip (ya da süper kullanıcı) bağlantısı gerekir: uygulama rolü RLS nedeniyle
# her tablonun ancak kendi sitesindeki satırlarını görür, yedek eksik kalırdı.
set -euo pipefail

OUT=${1:?kullanım: db-backup.sh <çıktı.dump>}
: "${DATABASE_URL:?DATABASE_URL (tablo sahibi / süper kullanıcı) gerekli}"

pg_dump --format=custom --no-password --file="$OUT" "$DATABASE_URL"

# Okunamayan yedek, yedeksizlikten daha tehlikelidir: varmış gibi görünür.
pg_restore --list "$OUT" >/dev/null

VER=$(psql "$DATABASE_URL" -tAc "SELECT COALESCE(max(version),0) FROM schema_migrations")
echo "yedek: $OUT ($(du -h "$OUT" | cut -f1)), şema sürümü: $VER"
