#!/usr/bin/env bash
#
# verify-stack.sh — Uçtan uca doğrulama betiği
#
# NEDEN VAR:
# 2026-09-09 denetiminde, proje dokümanlarındaki 78 "yapıldı" iddiasının %49'u yanlış çıktı.
# Kök neden: hiçbir iş çalıştırılarak doğrulanmıyor, yalnızca "kod yazıldı" anlamında
# tamamlandı işaretleniyordu. Bu betik o boşluğu kapatır: sıfırdan bir veritabanı kurar,
# tüm migration'ları uygular, gerçek servisi ayağa kaldırır ve gerçek HTTP istekleriyle
# temel akışları sınar.
#
# KULLANIM (WSL / Linux):
#   bash backend/scripts/verify-stack.sh
#
# GEREKSİNİMLER: docker, psql, go (1.24+), curl
#
# ÇIKIŞ KODU: 0 = tüm kontroller geçti, 1 = en az bir kontrol başarısız
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MIG_DIR="$BACKEND_DIR/migrations"

CNAME=${VERIFY_CONTAINER:-siteeksen-verify}
DBPORT=${VERIFY_DB_PORT:-55440}
SVCPORT=${VERIFY_SVC_PORT:-18090}
PW=${VERIFY_DB_PASSWORD:-verifypw}

PASS=0
FAIL=0
SVC_PID=""
STUB_PID=""
GW_PID=""
FIN_PID=""

ok()   { echo "  [GEÇTİ]    $1"; PASS=$((PASS+1)); }
bad()  { echo "  [BAŞARISIZ] $1"; FAIL=$((FAIL+1)); }
step() { echo ""; echo "=== $1 ==="; }

cleanup() {
  [ -n "$SVC_PID" ] && kill "$SVC_PID" 2>/dev/null
  [ -n "$STUB_PID" ] && kill "$STUB_PID" 2>/dev/null
  [ -n "$GW_PID" ] && kill "$GW_PID" 2>/dev/null
  [ -n "$FIN_PID" ] && kill "$FIN_PID" 2>/dev/null
  docker rm -f "$CNAME" >/dev/null 2>&1
}
trap cleanup EXIT

command -v docker >/dev/null || { echo "docker bulunamadı"; exit 1; }
command -v psql   >/dev/null || { echo "psql bulunamadı"; exit 1; }
command -v go     >/dev/null || { echo "go bulunamadı (PATH'e /usr/local/go/bin ekleyin)"; exit 1; }

step "0) Go derleme ve statik denetim"
cd "$BACKEND_DIR"
if go build ./... >/tmp/verify-build.log 2>&1; then ok "go build ./..."; else bad "go build ./..."; tail -15 /tmp/verify-build.log; fi
if go vet   ./... >/tmp/verify-vet.log   2>&1; then ok "go vet ./...";   else bad "go vet ./...";   tail -15 /tmp/verify-vet.log; fi
# Veritabanı gerektirmeyen birim testleri
if go test ./pkg/authtoken/... -count=1 >/tmp/verify-authtoken.log 2>&1; then
  ok "go test ./pkg/authtoken/... (JWT doğrulama)"
else
  bad "go test ./pkg/authtoken/..."; tail -15 /tmp/verify-authtoken.log
fi

step "1) Temiz PostgreSQL 16"
docker rm -f "$CNAME" >/dev/null 2>&1
docker run --rm -d --name "$CNAME" -e POSTGRES_PASSWORD="$PW" -e POSTGRES_DB=siteeksen \
  -e POSTGRES_USER=siteeksen -p ${DBPORT}:5432 postgres:16 >/dev/null
for _ in $(seq 1 60); do
  docker exec "$CNAME" pg_isready -U siteeksen -d siteeksen >/dev/null 2>&1 && break
  sleep 1
done
docker exec "$CNAME" pg_isready -U siteeksen -d siteeksen >/dev/null 2>&1 \
  && ok "veritabanı hazır" || { bad "veritabanı başlamadı"; exit 1; }

export PGPASSWORD="$PW"
PSQL="psql -h 127.0.0.1 -p ${DBPORT} -U siteeksen -d siteeksen -v ON_ERROR_STOP=1 -q"

step "2) Migration'lar (sıfırdan kurulum, cmd/migrate ile)"
export DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable"
if go run ./cmd/migrate -dir "$MIG_DIR" >/tmp/verify-mig.log 2>&1; then
  APPLIED=$(grep -c 'uygulandı:' /tmp/verify-mig.log)
  ok "cmd/migrate: $APPLIED migration uygulandı"
else
  bad "cmd/migrate başarısız"; tail -12 /tmp/verify-mig.log | sed 's/^/      /'
  echo "Migration zinciri kırık — sonraki adımlar atlanıyor"; exit 1
fi

# Sürüm tablosu gerçekten dolduruldu mu?
SM=$($PSQL -t -A -c "SELECT count(*) FROM schema_migrations;")
MIGFILES=$(ls "$MIG_DIR"/*.sql | wc -l)
[ "$SM" = "$MIGFILES" ] && ok "schema_migrations: $SM kayıt (dosya sayısıyla eşit)" \
  || bad "schema_migrations $SM kayıt, dosya sayısı $MIGFILES"

step "3) Şema beklentileri"
TBL=$($PSQL -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';")
[ "$TBL" -ge 60 ] && ok "tablo sayısı: $TBL (>=60)" || bad "tablo sayısı yetersiz: $TBL"

for t in expenses parking_zones reservations bank_accounts employees surveys assets meetings; do
  EX=$($PSQL -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='$t';")
  [ "$EX" = "1" ] && ok "tablo mevcut: $t" || bad "tablo eksik: $t"
done

# audit_logs kolonları pkg/audit ile uyumlu olmalı
for c in entity_type entity_id ip_address property_id request_id status_code; do
  EX=$($PSQL -t -A -c "SELECT count(*) FROM information_schema.columns WHERE table_name='audit_logs' AND column_name='$c';")
  [ "$EX" = "1" ] && ok "audit_logs.$c" || bad "audit_logs.$c eksik (pkg/audit yazamaz)"
done

step "4) Migration idempotency (tekrar uygulanabilirlik)"
# 4a) Çalıştırıcı ikinci kez çağrıldığında hiçbir şey uygulamamalı
if go run ./cmd/migrate -dir "$MIG_DIR" 2>&1 | grep -q 'güncel'; then
  ok "cmd/migrate tekrar çağrıldığında hiçbir şey uygulamıyor"
else
  bad "cmd/migrate tekrar çağrıldığında migration uyguladı (sürüm takibi çalışmıyor)"
fi

# 4b) Her migration dosyası ham olarak da tekrar uygulanabilmeli (madde 1.4).
# Sürüm tablosu bozulursa veya bir dosya elle çalıştırılırsa şema kırılmamalıdır.
for f in $(ls "$MIG_DIR"/*.sql | sort); do
  if $PSQL -f "$f" >/tmp/verify-idem.log 2>&1; then
    ok "tekrar: $(basename "$f")"
  else
    bad "tekrar: $(basename "$f") (idempotent değil)"
    grep -i ERROR /tmp/verify-idem.log | head -2 | sed 's/^/      /'
  fi
done

# 4c) Denetim izi migration tekrarında silinmemeli (madde 1.13)
$PSQL -c "INSERT INTO audit_logs (user_id, action, entity_type) VALUES (NULL, 'IDEMPOTENCY_PROBE', 'verify');" >/dev/null 2>&1
$PSQL -f "$MIG_DIR/003_multi_tenant.sql" >/dev/null 2>&1
PROBE=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='IDEMPOTENCY_PROBE';")
[ "$PROBE" = "1" ] && ok "003 tekrar uygulandığında denetim izi silinmiyor" \
  || bad "003 tekrarında denetim izi silindi (DROP TABLE audit_logs geri gelmiş)"
$PSQL -c "DELETE FROM audit_logs WHERE action='IDEMPOTENCY_PROBE';" >/dev/null 2>&1

# 4d) Seed verisi kendi içinde tutarlı olmalı (madde 1.8)
CONS=$($PSQL -t -A -c "SELECT CASE WHEN p.total_units = (SELECT count(*) FROM units WHERE property_id=p.id)
        AND p.total_share_ratio = (SELECT COALESCE(sum(share_ratio),0) FROM units WHERE property_id=p.id)
        THEN 'ok' ELSE 'tutarsiz' END FROM properties p WHERE p.id='11111111-1111-1111-1111-111111111111';")
[ "$CONS" = "ok" ] && ok "seed tutarlı: total_units ve arsa payı toplamı birimlerle eşleşiyor" \
  || bad "seed tutarsız (total_units / total_share_ratio birimlerle eşleşmiyor)"

step "5) pkg/audit birim testi (gerçek veritabanına karşı)"
if TEST_DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen" \
   go test ./pkg/audit/... -count=1 >/tmp/verify-audit.log 2>&1; then
  ok "go test ./pkg/audit/..."
else
  bad "go test ./pkg/audit/..."; tail -15 /tmp/verify-audit.log
fi

step "5b) Mevzuat parametreleri ve para aritmetiği"
if TEST_DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen" \
   go test ./pkg/legalparams/... -count=1 >/tmp/verify-legal.log 2>&1; then
  ok "go test ./pkg/legalparams/... (mevzuat parametreleri)"
else
  bad "go test ./pkg/legalparams/..."; tail -15 /tmp/verify-legal.log
fi
if go test ./pkg/money/... -count=1 >/tmp/verify-money.log 2>&1; then
  ok "go test ./pkg/money/... (kuruş dağıtımı, gecikme tazminatı)"
else
  bad "go test ./pkg/money/..."; tail -15 /tmp/verify-money.log
fi

# Gecikme tazminatı oranının kanuna uygunluğu (KMK m.20/2 — aylık %5)
LF=$($PSQL -t -A -c "SELECT value_numeric FROM legal_parameters WHERE code='LATE_FEE_MONTHLY_RATE' AND property_id IS NULL;")
[ "$LF" = "0.050000" ] && ok "gecikme tazminatı oranı %5 (KMK m.20/2)" || bad "gecikme tazminatı oranı beklenmedik: $LF"

# Isıtma paylarının toplamı 1 olmalı (%70 + %30)
HS=$($PSQL -t -A -c "SELECT sum(value_numeric) FROM legal_parameters WHERE code IN ('HEATING_CONSUMPTION_SHARE','HEATING_AREA_SHARE') AND property_id IS NULL;")
[ "$HS" = "1.000000" ] && ok "ısıtma gider payları toplamı 1 (%70 + %30)" || bad "ısıtma payları toplamı $HS"

step "6) identity-service uçtan uca"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${SVCPORT} \
  go run ./services/identity >/tmp/verify-identity.log 2>&1 &
SVC_PID=$!

UP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${SVCPORT}/health" >/dev/null 2>&1 && { UP=1; break; }
  sleep 1
done
if [ "$UP" = "1" ]; then ok "servis ayağa kalktı"; else bad "servis başlamadı"; tail -20 /tmp/verify-identity.log; exit 1; fi

RESP=$(curl -s -w '\n__HTTP__%{http_code}' -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
  -H 'Content-Type: application/json' -d '{"phone":"5551234567","password":"Demo123!"}')
CODE=$(echo "$RESP" | grep -o '__HTTP__[0-9]*' | sed 's/__HTTP__//')
BODY=$(echo "$RESP" | sed 's/__HTTP__[0-9]*//')
[ "$CODE" = "200" ] && ok "demo giriş (5551234567 / Demo123!) → 200" || bad "demo giriş → $CODE"

CODE2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
  -H 'Content-Type: application/json' -d '{"phone":"5551234567","password":"yanlis"}')
[ "$CODE2" = "401" ] && ok "yanlış şifre reddedildi → 401" || bad "yanlış şifre → $CODE2 (401 bekleniyordu)"

CODE3=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${SVCPORT}/api/v1/users/me")
[ "$CODE3" = "401" ] && ok "token'sız erişim reddedildi → 401" || bad "token'sız erişim → $CODE3 (401 bekleniyordu)"

TOKEN=$(echo "$BODY" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
if [ -n "$TOKEN" ]; then
  CODE4=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "http://127.0.0.1:${SVCPORT}/api/v1/users/me")
  [ "$CODE4" = "200" ] && ok "token ile /users/me → 200" || bad "token ile /users/me → $CODE4"

  sleep 1
  AUD=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs;")
  [ "$AUD" -ge 1 ] && ok "denetim izi yazıldı (audit_logs: $AUD kayıt)" || bad "denetim izi yazılmadı (audit_logs boş)"
else
  bad "access_token alınamadı"
fi

step "7) Dürüstlük: kalıcı olmayan uçlar 501 dönmeli"
# tasks/dogrulama-politikasi.md §3.5 — kaydetmeyen bir uç 2xx dönemez.
PORT=${STUB_PORT:-18191} go run ./services/parking >/tmp/verify-parking.log 2>&1 &
STUB_PID=$!
SUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${STUB_PORT:-18191}/health" >/dev/null 2>&1 && { SUP=1; break; }
  sleep 1
done
if [ "$SUP" = "1" ]; then
  ok "stub servis (parking) ayağa kalktı"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/vehicles")
  [ "$SC" = "501" ] && ok "stub GET /vehicles → 501" || bad "stub GET /vehicles → $SC (501 bekleniyordu)"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/vehicles" \
    -H 'Content-Type: application/json' -d '{"owner_type":"RESIDENT","plate":"34ABC123"}')
  [ "$SC" = "501" ] && ok "stub POST /vehicles → 501 (veri kaydedilmiyor)" || bad "stub POST /vehicles → $SC (501 bekleniyordu)"
  HDR=$(curl -s -D- -o /dev/null "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/vehicles" | grep -ci 'X-SiteEksen-Not-Implemented: true')
  [ "$HDR" -ge 1 ] && ok "stub yanıtında X-SiteEksen-Not-Implemented başlığı var" || bad "stub başlığı eksik"
else
  bad "stub servis başlamadı"
fi
kill "$STUB_PID" 2>/dev/null

# Kaynak düzeyinde: mock servislerde uydurma veri kalmamalı
FAKE=$(grep -rn "Ali Veli\|Ayşe Yılmaz\|Ahmet Yılmaz\|Mehmet Demir\|AYEDAŞ" "$BACKEND_DIR/services" --include=*.go 2>/dev/null | grep -v _test | wc -l)
[ "$FAKE" -eq 0 ] && ok "servis kaynaklarında uydurma isim/veri kalmadı" || { bad "servis kaynaklarında $FAKE uydurma veri satırı var"; }

step "8) Gateway kimlik doğrulaması (FAZ 2.1)"
# Gateway daha önce HİÇBİR jeton doğrulaması yapmıyordu: maaş, TCKN, IBAN ve
# API anahtarları token'sız erişilebiliyordu.
GWPORT=${VERIFY_GW_PORT:-18099}
IDENTITY_SERVICE_URL="http://127.0.0.1:${SVCPORT}" \
JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${GWPORT} \
  go run ./cmd/gateway >/tmp/verify-gateway.log 2>&1 &
GW_PID=$!
GUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${GWPORT}/health" >/dev/null 2>&1 && { GUP=1; break; }
  sleep 1
done
if [ "$GUP" = "1" ]; then
  ok "gateway ayağa kalktı"

  SC=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${GWPORT}/api/v1/users/me")
  [ "$SC" = "401" ] && ok "gateway: token'sız /users/me → 401" || bad "gateway: token'sız /users/me → $SC (401 bekleniyordu)"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer sahte.jeton.dizesi" \
    "http://127.0.0.1:${GWPORT}/api/v1/users/me")
  [ "$SC" = "401" ] && ok "gateway: geçersiz jeton → 401" || bad "gateway: geçersiz jeton → $SC (401 bekleniyordu)"

  GRESP=$(curl -s "http://127.0.0.1:${GWPORT}/api/v1/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5551234567","password":"Demo123!"}')
  GTOKEN=$(echo "$GRESP" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  [ -n "$GTOKEN" ] && ok "gateway: /auth/login açık uç olarak çalışıyor" || bad "gateway: /auth/login üzerinden giriş yapılamadı"

  if [ -n "$GTOKEN" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $GTOKEN" \
      "http://127.0.0.1:${GWPORT}/api/v1/users/me")
    [ "$SC" = "200" ] && ok "gateway: geçerli jetonla /users/me → 200" || bad "gateway: geçerli jetonla /users/me → $SC"
  fi

  # Uydurma mali rapor üretimi kaldırıldı
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "Authorization: Bearer ${GTOKEN:-x}" \
    "http://127.0.0.1:${GWPORT}/api/v1/reports/generate" -H 'Content-Type: application/json' -d '{"type":"assessment"}')
  [ "$SC" = "501" ] && ok "gateway: uydurma rapor üretimi kapatıldı → 501" || bad "gateway: /reports/generate → $SC (501 bekleniyordu)"
else
  bad "gateway başlamadı"; tail -10 /tmp/verify-gateway.log
fi
kill "$GW_PID" 2>/dev/null

# Kaynak düzeyinde: Kong yapılandırmasında jwt eklentisi olmalı
KJ=$(grep -c "name: jwt" "$BACKEND_DIR/../kong/kong.yml" 2>/dev/null | head -1)
KJ=${KJ:-0}
[ "$KJ" -ge 20 ] && ok "kong.yml: jwt eklentisi $KJ rotada tanımlı" || bad "kong.yml: jwt eklentisi eksik ($KJ)"
KC=$(grep -c 'origins:' "$BACKEND_DIR/../kong/kong.yml" 2>/dev/null | head -1)
KW=$(grep -c "'\*'" "$BACKEND_DIR/../kong/kong.yml" 2>/dev/null | head -1)
KC=${KC:-0}; KW=${KW:-0}
[ "$KW" -eq 0 ] && ok "kong.yml: joker (*) CORS kökeni kalmadı ($KC servis)" || bad "kong.yml: hâlâ $KW joker CORS kökeni var"

step "9) Yetkilendirme: site bazlı roller ve sahiplik doğrulaması (FAZ 2.4/2.5/2.9)"
FINPORT=${VERIFY_FIN_PORT:-18092}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${FINPORT} \
  go run ./services/finance >/tmp/verify-finance.log 2>&1 &
FIN_PID=$!
FUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${FINPORT}/health" >/dev/null 2>&1 && { FUP=1; break; }
  sleep 1
done

if [ "$FUP" = "1" ]; then
  ok "finance-service ayağa kalktı"

  # Yönetici hesabı (migration 008 + 013 ile MANAGER rolü site bazlı atanmış)
  MGR=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5551234567","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  # Kiracı hesabı (yönetim rolü YOK)
  TEN=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5559876543","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  [ -n "$MGR" ] && ok "yönetici girişi" || bad "yönetici girişi başarısız"
  [ -n "$TEN" ] && ok "kiracı girişi" || bad "kiracı girişi başarısız"

  # Rollerin jetondan site bazlı geldiğini doğrula
  MGR_ROLES=$(echo "$MGR" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null)
  echo "$MGR_ROLES" | grep -q 'MANAGER' && ok "yönetici jetonunda MANAGER rolü var" \
    || bad "yönetici jetonunda MANAGER rolü yok"
  TEN_ROLES=$(echo "$TEN" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null)
  echo "$TEN_ROLES" | grep -q 'MANAGER' && bad "kiracı jetonunda MANAGER rolü VAR (roller hâlâ global)" \
    || ok "kiracı jetonunda yönetim rolü yok (roller site bazlı)"
  echo "$TEN_ROLES" | grep -q 'TENANT' && ok "kiracı jetonunda TENANT rolü var" \
    || bad "kiracı jetonunda TENANT rolü yok"

  # Site geneli borçlu listesi yalnızca yönetime açık olmalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $MGR" \
    "http://127.0.0.1:${FINPORT}/api/v1/finance/debtors")
  [ "$SC" = "200" ] && ok "yönetici: /finance/debtors → 200" || bad "yönetici: /finance/debtors → $SC"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TEN" \
    "http://127.0.0.1:${FINPORT}/api/v1/finance/debtors")
  [ "$SC" = "403" ] && ok "kiracı: /finance/debtors → 403 (site geneli borç listesi gizli)" \
    || bad "kiracı: /finance/debtors → $SC (403 bekleniyordu)"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TEN" \
    "http://127.0.0.1:${FINPORT}/api/v1/finance/debt-status")
  [ "$SC" = "200" ] && ok "kiracı: kendi borç durumunu görebiliyor → 200" \
    || bad "kiracı: /finance/debt-status → $SC"

  # Yetkisiz erişim denemesi denetim izine DENIED olarak yazılmalı
  sleep 1
  DEN=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='DENIED';")
  [ "$DEN" -ge 1 ] && ok "yetkisiz erişim denetim izine DENIED olarak yazıldı ($DEN kayıt)" \
    || bad "DENIED denetim kaydı yok"
else
  bad "finance-service başlamadı"; tail -10 /tmp/verify-finance.log
fi
# NOT: finance-service burada kapatılmaz; 10. adım (para doğruluğu) aynı servisi kullanır.
# Temizlik `cleanup` tuzağı tarafından yapılır.

step "10) Para doğruluğu: ödeme tahakkuktan düşüyor mu? (FAZ 4.2)"
# Önceki davranış: ödeme kaydı oluşuyor ama monthly_assessments.paid_amount HİÇ
# güncellenmiyordu → ödeyen sakin sonsuza dek borçlu kalıyordu (gap-analizi B46).
if [ "$FUP" = "1" ] && [ -n "${MGR:-}" ]; then
  ASSESS='66666666-6666-6666-6666-666666666601'   # demo: A-3, 1200,00 TL, PENDING
  BEFORE=$($PSQL -t -A -c "SELECT COALESCE(paid_amount,0)::text FROM monthly_assessments WHERE id='$ASSESS';")

  PAYRESP=$(curl -s -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\"}")
  PAYID=$(echo "$PAYRESP" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
  [ -n "$PAYID" ] && ok "ödeme kaydı oluşturuldu" || bad "ödeme kaydı oluşturulamadı: $PAYRESP"

  echo "$PAYRESP" | grep -q '"payment_gateway_ready":false' \
    && ok "istemciye tahsilatın yapılmadığı bildiriliyor (payment_gateway_ready:false)" \
    || bad "payment_gateway_ready alanı yok/yanlış"

  # Onay öncesi borç DEĞİŞMEMELİ
  MID=$($PSQL -t -A -c "SELECT COALESCE(paid_amount,0)::text FROM monthly_assessments WHERE id='$ASSESS';")
  [ "$MID" = "$BEFORE" ] && ok "onay öncesi borç değişmedi (ödeme PENDING)" \
    || bad "onaysız ödeme borçtan düştü: $BEFORE → $MID"

  if [ -n "$PAYID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
      "http://127.0.0.1:${FINPORT}/api/v1/finance/payments/${PAYID}/confirm" \
      -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
      -d '{"reference":"DEKONT-TEST-1"}')
    [ "$SC" = "200" ] && ok "yönetici ödemeyi onayladı → 200" || bad "ödeme onayı → $SC"

    AFTER=$($PSQL -t -A -c "SELECT COALESCE(paid_amount,0)::text FROM monthly_assessments WHERE id='$ASSESS';")
    STAT=$($PSQL -t -A -c "SELECT status FROM monthly_assessments WHERE id='$ASSESS';")
    [ "$AFTER" = "1200.00" ] && ok "tahakkukun ödenen tutarı güncellendi: $BEFORE → $AFTER" \
      || bad "ödenen tutar güncellenmedi: $BEFORE → $AFTER (1200.00 bekleniyordu)"
    [ "$STAT" = "PAID" ] && ok "tahakkuk durumu PAID oldu" || bad "tahakkuk durumu $STAT (PAID bekleniyordu)"

    # Çift onay engellenmeli (idempotency)
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
      "http://127.0.0.1:${FINPORT}/api/v1/finance/payments/${PAYID}/confirm" \
      -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{}')
    [ "$SC" = "409" ] && ok "çift onaylama engellendi → 409" || bad "çift onaylama → $SC (409 bekleniyordu)"

    # Borç durumu da düşmüş olmalı
    DEBT=$(curl -s -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/debt-status")
    echo "$DEBT" | grep -q '"has_debt":false' \
      && ok "ödeme sonrası borç durumu güncellendi (has_debt:false)" \
      || bad "ödeme sonrası hâlâ borçlu görünüyor: $DEBT"

    # Geri al: betik tekrar çalıştırılabilir kalsın
    $PSQL -c "UPDATE monthly_assessments SET paid_amount=0, status='PENDING' WHERE id='$ASSESS';" >/dev/null 2>&1
  fi
else
  bad "para doğruluğu adımı atlandı (finance servisi ya da jeton yok)"
fi

# Aktif site seçiminde sahiplik doğrulaması (FAZ 2.4)
if [ -n "${MGR:-}" ]; then
  # Kullanıcının bağlı OLMADIĞI bir site kimliği
  OTHER=$($PSQL -t -A -c "INSERT INTO properties (id, name, address, city, district, total_share_ratio, total_units) VALUES (gen_random_uuid(), 'Yabanci Site', 'x', 'x', 'x', 1000, 1) RETURNING id;")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${SVCPORT}/api/v1/users/me/active-property" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"property_id\":\"$OTHER\"}")
  [ "$SC" = "403" ] && ok "başkasının sitesine geçiş reddedildi → 403" \
    || bad "başkasının sitesine geçiş → $SC (403 bekleniyordu)"

  OWN=$($PSQL -t -A -c "SELECT id FROM properties WHERE id='11111111-1111-1111-1111-111111111111';")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${SVCPORT}/api/v1/users/me/active-property" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"property_id\":\"$OWN\"}")
  [ "$SC" = "200" ] && ok "kendi sitesine geçiş kabul edildi → 200" || bad "kendi sitesine geçiş → $SC"
fi

step "SONUÇ"
echo "  Geçen: $PASS   Başarısız: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TÜM KONTROLLER GEÇTİ"; exit 0; } || { echo "  BAŞARISIZ KONTROL VAR"; exit 1; }
