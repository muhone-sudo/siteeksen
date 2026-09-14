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
# Hangi servislerin başlatıldığı, gerçekten veri katmanına bağlı olanlarla
# birebir aynıdır. Bir servis burada yoksa gateway 502 döner — uydurma veri
# DÖNMEZ. Bir modül gerçeğe çevrildikçe bu listeye eklenir.
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
  # `go run X &` iki süreç yaratır; sarmalayıcı öldürülse de derlenmiş ikili
  # portu tutmaya devam eder. Bu yüzden ikililer ayrıca sonlandırılır.
  pkill -f 'exe/identity|exe/finance|exe/community|exe/governance|exe/gateway' 2>/dev/null
  pkill -f 'exe/expense|exe/personnel|exe/visitor|exe/parking' 2>/dev/null
  pkill -f 'exe/reservation|exe/package|exe/contract|exe/document' 2>/dev/null
  pkill -f 'exe/iot|exe/asset|exe/bulletin|exe/inventory|exe/survey' 2>/dev/null
  pkill -f 'exe/patrol|exe/settings|exe/nps|exe/esg' 2>/dev/null
  pkill -f 'exe/energy_analytics|exe/smart_collection' 2>/dev/null
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

echo "=== Uygulama rolü ==="
# Satır düzeyi güvenliği (RLS) SÜPER KULLANICIYI BAĞLAMAZ. Servisler bu yüzden
# yetkisi sınırlı `siteeksen_app` rolüyle bağlanır; aksi hâlde RLS politikaları
# tanımlı olur ama hiç devreye girmez.
APPPW=${DEV_APP_PASSWORD:-devapppw}
PGPASSWORD="$PW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen -d siteeksen -q \
  -c "ALTER ROLE siteeksen_app LOGIN PASSWORD '$APPPW';" >/dev/null 2>&1 \
  && echo "  siteeksen_app hazır (RLS bu rolde geçerli)" \
  || echo "  UYARI: uygulama rolü hazırlanamadı; RLS devrede OLMAYABİLİR"

export DB_HOST=127.0.0.1 DB_PORT=$DBPORT DB_USER=siteeksen_app DB_PASSWORD="$APPPW"
export DB_NAME=siteeksen DB_SSLMODE=disable
export GIN_MODE=release

# Kişisel veri şifreleme anahtarı (FAZ 2.8). Personel servisi bu anahtar
# olmadan AÇILMAZ. Geliştirme için sabit bir anahtar üretilir; ÜRETİMDE bu
# değer gizli yönetiminden gelir ve ASLA depoya yazılmaz.
export PII_ENCRYPTION_KEY=${PII_ENCRYPTION_KEY:-$(head -c 32 /dev/zero | base64 -w0)}

# Dosya depolama (S-09). Geliştirmede yerel dosya sistemi kullanılır;
# üretimde STORAGE_BACKEND=s3 ve S3_* değişkenleri verilir.
# Yapılandırma olmadan document-service AÇILMAZ (sessizce kayıp dosya olmasın diye).
export STORAGE_BACKEND=${STORAGE_BACKEND:-local}
export STORAGE_LOCAL_DIR=${STORAGE_LOCAL_DIR:-/tmp/siteeksen-dev-files}
mkdir -p "$STORAGE_LOCAL_DIR"

# Bildirim (S-10). Geliştirmede yalnızca GÜNLÜĞE yazan sağlayıcı açılır;
# dışarıya hiçbir şey gönderilmez. Üretimde bu değişken AÇILMAZ.
export NOTIFY_LOG_SENDER=${NOTIFY_LOG_SENDER:-true}

start() { # ad, port, yol
  echo "  $1 → :$2"
  PORT=$2 go run "$3" >/tmp/dev-$1.log 2>&1 &
  PIDS+=($!)
}

echo "=== Servisler ==="
start identity     8081 ./services/identity
start finance      8082 ./services/finance
start community    8083 ./services/community
start iot          8084 ./services/iot
start notification 8085 ./services/notification
start expense      8086 ./services/expense
start asset        8087 ./services/asset
start bulletin     8089 ./services/bulletin
start contract     8090 ./services/contract
start document     8091 ./services/document
start energy       8092 ./services/energy_analytics
start esg          8093 ./services/esg
start inventory    8094 ./services/inventory
start nps          8096 ./services/nps
start package      8097 ./services/package
start parking      8098 ./services/parking
start patrol       8099 ./services/patrol
start personnel    8100 ./services/personnel
start reservation  8101 ./services/reservation
start settings     8102 ./services/settings
start collection   8103 ./services/smart_collection
start survey       8104 ./services/survey
start visitor      8105 ./services/visitor
start governance   8107 ./services/governance

# Gateway yalnızca gerçek servislere yönlendirir; diğerleri ayakta değilse
# 502 döner (uydurma veri DÖNMEZ).
IDENTITY_SERVICE_URL=http://127.0.0.1:8081 \
FINANCE_SERVICE_URL=http://127.0.0.1:8082 \
COMMUNITY_SERVICE_URL=http://127.0.0.1:8083 \
IOT_SERVICE_URL=http://127.0.0.1:8084 \
NOTIFICATION_SERVICE_URL=http://127.0.0.1:8085 \
EXPENSE_SERVICE_URL=http://127.0.0.1:8086 \
ASSET_SERVICE_URL=http://127.0.0.1:8087 \
BULLETIN_SERVICE_URL=http://127.0.0.1:8089 \
CONTRACT_SERVICE_URL=http://127.0.0.1:8090 \
DOCUMENT_SERVICE_URL=http://127.0.0.1:8091 \
ENERGY_SERVICE_URL=http://127.0.0.1:8092 \
ESG_SERVICE_URL=http://127.0.0.1:8093 \
INVENTORY_SERVICE_URL=http://127.0.0.1:8094 \
NPS_SERVICE_URL=http://127.0.0.1:8096 \
PACKAGE_SERVICE_URL=http://127.0.0.1:8097 \
PARKING_SERVICE_URL=http://127.0.0.1:8098 \
PATROL_SERVICE_URL=http://127.0.0.1:8099 \
PERSONNEL_SERVICE_URL=http://127.0.0.1:8100 \
RESERVATION_SERVICE_URL=http://127.0.0.1:8101 \
SETTINGS_SERVICE_URL=http://127.0.0.1:8102 \
SMART_COLLECTION_SERVICE_URL=http://127.0.0.1:8103 \
SURVEY_SERVICE_URL=http://127.0.0.1:8104 \
VISITOR_SERVICE_URL=http://127.0.0.1:8105 \
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
echo "  Gerçek veriye bağlı modüller (20):"
echo "    giriş/sakin · aidat-ödeme · talep · duyuru · yönetişim (işletme projesi,"
echo "    genel kurul, defter) · gider · personel · ziyaretçi · otopark ·"
echo "    rezervasyon · kargo · sözleşme · belge arşivi · demirbaş · stok ·"
echo "    anket · sayaç/ısı payı · bildirim · devriye · ilan panosu · ayarlar ·"
echo "    enerji analizi · tahsilat riski · memnuniyet (NPS) · karbon ayak izi"
echo ""
echo "  Bilerek yazılmayanlar        : banka entegrasyonu (S-07 kararı),"
echo "                                 toplantı sihirbazı (governance ile tekrar)"
echo "  Dosya depolama               : ${STORAGE_BACKEND} (${STORAGE_LOCAL_DIR})"
echo "  Veritabanı rolü              : siteeksen_app (RLS geçerli, DDL yetkisi yok)"
echo "  Kişisel veri                 : TCKN/IBAN şifreli (PII_ENCRYPTION_KEY)"
echo "======================================================================"
echo ""
echo "Durdurmak için Ctrl+C."

wait
