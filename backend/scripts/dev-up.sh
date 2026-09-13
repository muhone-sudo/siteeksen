#!/usr/bin/env bash
#
# dev-up.sh — Geliştirme ortamını tek komutla ayağa kaldırır.
#
# NEDEN VAR: `docker-compose up` 30+ imaj derlediği için ilk çalıştırmada çok uzun
# sürüyor. Bu betik yalnızca GERÇEK VERİ KATMANINA BAĞLI servisleri (identity,
# finance, community, governance) ve gateway'i doğrudan `go run` ile çalıştırır;
# veritabanını tek bir Docker kabında açar. Böylece panel saniyeler içinde
# kullanılabilir hâle gelir.
#
# KULLANIM:
#   bash backend/scripts/dev-up.sh          # servisleri başlat (ön planda çalışır)
#   bash backend/scripts/dev-up.sh --stop   # her şeyi durdur
#
# Panel:  http://localhost:3001   (ayrıca `cd admin && npm run dev` gerekir)
# Gateway: http://localhost:8888
# Demo giriş: 5551234567 / Demo123!
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export PATH=$PATH:/usr/local/go/bin

CNAME=${DEV_DB_CONTAINER:-siteeksen-dev-db}
DBPORT=${DEV_DB_PORT:-55432}
PW=${DEV_DB_PASSWORD:-devpw}
export JWT_SECRET=${JWT_SECRET:-dev-secret-key-at-least-32-characters-long}

PIDS=()

stop_all() {
  echo ""
  echo "Servisler durduruluyor..."
  for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null; done
  pkill -f 'exe/identity|exe/finance|exe/community|exe/governance|exe/gateway' 2>/dev/null
  docker rm -f "$CNAME" >/dev/null 2>&1
  echo "Durduruldu."
}

if [ "${1:-}" = "--stop" ]; then
  stop_all
  exit 0
fi

trap stop_all EXIT INT TERM

cd "$BACKEND_DIR" || exit 1

echo "=== PostgreSQL ==="
docker rm -f "$CNAME" >/dev/null 2>&1
docker run --rm -d --name "$CNAME" \
  -e POSTGRES_PASSWORD="$PW" -e POSTGRES_USER=siteeksen -e POSTGRES_DB=siteeksen \
  -p ${DBPORT}:5432 postgres:16 >/dev/null
for _ in $(seq 1 60); do
  docker exec "$CNAME" pg_isready -U siteeksen >/dev/null 2>&1 && break
  sleep 1
done
echo "  hazır (port ${DBPORT})"

echo "=== Migration ==="
export DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable"
go run ./cmd/migrate | sed 's/^/  /'

export DB_HOST=127.0.0.1 DB_PORT=$DBPORT DB_USER=siteeksen DB_PASSWORD="$PW"
export DB_NAME=siteeksen DB_SSLMODE=disable
export GIN_MODE=release

start() { # ad, port, yol
  echo "  $1 → :$2"
  PORT=$2 go run "$3" >/tmp/dev-$1.log 2>&1 &
  PIDS+=($!)
}

echo "=== Servisler ==="
start identity   8081 ./services/identity
start finance    8082 ./services/finance
start community  8083 ./services/community
start governance 8107 ./services/governance

# Gateway yalnızca gerçek servislere yönlendirir; diğerleri ayakta değilse
# 502 döner (uydurma veri DÖNMEZ).
IDENTITY_SERVICE_URL=http://127.0.0.1:8081 \
FINANCE_SERVICE_URL=http://127.0.0.1:8082 \
COMMUNITY_SERVICE_URL=http://127.0.0.1:8083 \
GOVERNANCE_SERVICE_URL=http://127.0.0.1:8107 \
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001 \
PORT=8888 go run ./cmd/gateway >/tmp/dev-gateway.log 2>&1 &
PIDS+=($!)
echo "  gateway → :8888"

echo ""
echo "Servislerin açılması bekleniyor..."
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:8888/health >/dev/null 2>&1 && break
  sleep 1
done

echo ""
echo "======================================================================"
echo "  HAZIR"
echo ""
echo "  Yönetim paneli : http://localhost:3001    (ayrı terminalde: cd admin && npm run dev)"
echo "  API gateway    : http://localhost:8888"
echo "  Veritabanı     : localhost:${DBPORT} (siteeksen / ${PW})"
echo ""
echo "  Demo giriş     : 5551234567  /  Demo123!   (yönetici)"
echo "                   5559876543  /  Demo123!   (kiracı — yetkisi kısıtlı)"
echo ""
echo "  Gerçek veriye bağlı modüller : giriş, sakin, aidat/ödeme, talep, yönetişim"
echo "  Diğer modüller 501 döner     : bilerek — kaydetmeyen uç 2xx dönmez"
echo "======================================================================"
echo ""
echo "Durdurmak için Ctrl+C."

wait
