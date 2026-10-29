#!/usr/bin/env bash
# Test hesaplarını oluşturur (test-ortami.sh çağırır; taze veritabanında bir kez çalışır).
#   bash backend/scripts/test-hesaplari.sh [http://127.0.0.1:8888/api/v1]
exec python3 -I "$(dirname "${BASH_SOURCE[0]}")/test-araclari/hesaplar.py" "${1:-http://127.0.0.1:8888/api/v1}"
