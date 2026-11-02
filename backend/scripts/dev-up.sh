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
# DEV_PORT_OFFSET=N: servis ve gateway portlarına N eklenir (test ortamı 20000 kullanır: gateway 28888),
# böylece aynı makinedeki başka bir yığınla (ör. docker compose) çakışmaz.
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
OFF=${DEV_PORT_OFFSET:-0}
GW=$((8888 + OFF))

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
  pkill -f 'exe/energy_analytics|exe/smart_collection|exe/scheduler|exe/marketplace|exe/moderation' 2>/dev/null
  # Go 1.24+ `go run` ikilisini önbellekte `<özet>-d/<ad>` olarak tutar ("exe/" yok);
  # yukarıdaki kalıplar onu yakalamaz. Portu tutan süreç her durumda sonlandırılır.
  for p in 8081 8082 8083 8084 8085 8086 8087 8089 8090 8091 8092 8093 8094 8096 8097 8098 8099 8100 8101 8102 8103 \
           8104 8105 8107 8110 8111 8112 8888; do fuser -k $((p + OFF))/tcp >/dev/null 2>&1; done
  docker rm -fv "$CNAME" >/dev/null 2>&1
  echo "Durduruldu."
}

if [ "${1:-}" = "--stop" ]; then
  stop_all
  exit 0
fi

trap stop_all EXIT INT TERM

cd "$BACKEND_DIR" || exit 1

echo "=== PostgreSQL ==="
docker rm -fv "$CNAME" >/dev/null 2>&1
docker run --rm -d --name "$CNAME" --label com.docker.compose.project=sitesen --label com.docker.compose.service=dev-db \
  -e POSTGRES_PASSWORD="$PW" -e POSTGRES_USER=siteeksen -e POSTGRES_DB=siteeksen \
  -p ${DBPORT}:5432 postgres:16 -c max_connections=300 >/dev/null
for _ in $(seq 1 60); do
  docker exec "$CNAME" pg_isready -U siteeksen >/dev/null 2>&1 && break
  sleep 1
done
echo "  hazır (port ${DBPORT})"

echo "=== Migration ve roller ==="
# Satır düzeyi güvenliği (RLS) SÜPER KULLANICIYI BAĞLAMAZ. Servisler bu yüzden
# yetkisi sınırlı rollerle bağlanır: kimlik servisi `siteeksen_identity`,
# diğerleri `siteeksen_app`. Parolaları dağıtımda olduğu gibi cmd/migrate atar.
APPPW=${DEV_APP_PASSWORD:-devapppw}
IDPW=${DEV_IDENTITY_PASSWORD:-devidpw}
export DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable"
APP_DB_PASSWORD="$APPPW" IDENTITY_DB_PASSWORD="$IDPW" go run ./cmd/migrate | sed 's/^/  /'

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
  echo "  $1 → :$(($2 + OFF))"
  PORT=$(($2 + OFF)) go run "$3" >/tmp/dev-$1.log 2>&1 &
  PIDS+=($!)
}

echo "=== Servisler ==="
# Kimlik servisi kendi rolüyle: dizini bütünüyle görür, site verisine erişemez.
echo "  identity → :$((8081 + OFF)) (rol: siteeksen_identity)"
DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" PORT=$((8081 + OFF)) \
  go run ./services/identity >/tmp/dev-identity.log 2>&1 &
PIDS+=($!)
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
start marketplace  8111 ./services/marketplace
# Fotoğraf denetimi (M13.4): ana makinede Tesseract yoksa Docker sarmalayıcısı kullanılır.
command -v tesseract >/dev/null 2>&1 || export OCR_COMMAND=${OCR_COMMAND:-$SCRIPT_DIR/tools/ocr-docker/tesseract}
start moderation   8112 ./services/moderation
# Zamana bağlı bildirimler (gecikmiş aidat, sözleşme ihbarı, açık devriye).
SCHEDULER_INTERVAL=${SCHEDULER_INTERVAL:-5m} start scheduler 8110 ./cmd/scheduler

# Gateway yalnızca gerçek servislere yönlendirir; diğerleri ayakta değilse
# 502 döner (uydurma veri DÖNMEZ).
IDENTITY_SERVICE_URL=http://127.0.0.1:$((8081 + OFF)) \
FINANCE_SERVICE_URL=http://127.0.0.1:$((8082 + OFF)) \
COMMUNITY_SERVICE_URL=http://127.0.0.1:$((8083 + OFF)) \
IOT_SERVICE_URL=http://127.0.0.1:$((8084 + OFF)) \
NOTIFICATION_SERVICE_URL=http://127.0.0.1:$((8085 + OFF)) \
EXPENSE_SERVICE_URL=http://127.0.0.1:$((8086 + OFF)) \
ASSET_SERVICE_URL=http://127.0.0.1:$((8087 + OFF)) \
BULLETIN_SERVICE_URL=http://127.0.0.1:$((8089 + OFF)) \
CONTRACT_SERVICE_URL=http://127.0.0.1:$((8090 + OFF)) \
DOCUMENT_SERVICE_URL=http://127.0.0.1:$((8091 + OFF)) \
ENERGY_SERVICE_URL=http://127.0.0.1:$((8092 + OFF)) \
ESG_SERVICE_URL=http://127.0.0.1:$((8093 + OFF)) \
INVENTORY_SERVICE_URL=http://127.0.0.1:$((8094 + OFF)) \
NPS_SERVICE_URL=http://127.0.0.1:$((8096 + OFF)) \
PACKAGE_SERVICE_URL=http://127.0.0.1:$((8097 + OFF)) \
PARKING_SERVICE_URL=http://127.0.0.1:$((8098 + OFF)) \
PATROL_SERVICE_URL=http://127.0.0.1:$((8099 + OFF)) \
PERSONNEL_SERVICE_URL=http://127.0.0.1:$((8100 + OFF)) \
RESERVATION_SERVICE_URL=http://127.0.0.1:$((8101 + OFF)) \
SETTINGS_SERVICE_URL=http://127.0.0.1:$((8102 + OFF)) \
SMART_COLLECTION_SERVICE_URL=http://127.0.0.1:$((8103 + OFF)) \
SURVEY_SERVICE_URL=http://127.0.0.1:$((8104 + OFF)) \
VISITOR_SERVICE_URL=http://127.0.0.1:$((8105 + OFF)) \
GOVERNANCE_SERVICE_URL=http://127.0.0.1:$((8107 + OFF)) \
MARKETPLACE_SERVICE_URL=http://127.0.0.1:$((8111 + OFF)) \
MODERATION_SERVICE_URL=http://127.0.0.1:$((8112 + OFF)) \
CORS_ALLOWED_ORIGINS=${CORS_ALLOWED_ORIGINS:-http://localhost:3000,http://localhost:3001} \
PORT=$GW go run ./cmd/gateway >/tmp/dev-gateway.log 2>&1 &
PIDS+=($!)
echo "  gateway → :$GW"

echo ""
echo "Servislerin açılması bekleniyor..."
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:$GW/health >/dev/null 2>&1 && break
  sleep 1
done

echo ""
echo "======================================================================"
echo "  HAZIR"
echo ""
echo "  Yönetim paneli : http://localhost:3001    (ayrı terminalde: cd admin && npm run dev)"
echo "  API gateway    : http://localhost:$GW"
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
echo "  Bilerek yazılmayanlar        : banka entegrasyonu (S-07 kararı)"
echo "  Dosya depolama               : ${STORAGE_BACKEND} (${STORAGE_LOCAL_DIR})"
echo "  Veritabanı rolleri           : siteeksen_app (23 servis, RLS geçerli, DDL yetkisi yok)"
echo "                                 siteeksen_identity (yalnızca kimlik servisi)"
echo "  Kişisel veri                 : TCKN/IBAN şifreli (PII_ENCRYPTION_KEY)"
echo "======================================================================"
echo ""
echo "Durdurmak için Ctrl+C."

wait
