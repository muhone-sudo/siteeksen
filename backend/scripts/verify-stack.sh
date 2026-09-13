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
GOV_PID=""
EXP_PID=""
PER_PID=""
VIS_PID=""
PRK_PID=""

ok()   { echo "  [GEÇTİ]    $1"; PASS=$((PASS+1)); }
bad()  { echo "  [BAŞARISIZ] $1"; FAIL=$((FAIL+1)); }
step() { echo ""; echo "=== $1 ==="; }

cleanup() {
  [ -n "$SVC_PID" ] && kill "$SVC_PID" 2>/dev/null
  [ -n "$STUB_PID" ] && kill "$STUB_PID" 2>/dev/null
  [ -n "$GW_PID" ] && kill "$GW_PID" 2>/dev/null
  [ -n "$FIN_PID" ] && kill "$FIN_PID" 2>/dev/null
  [ -n "$GOV_PID" ] && kill "$GOV_PID" 2>/dev/null
  [ -n "$EXP_PID" ] && kill "$EXP_PID" 2>/dev/null
  [ -n "$PER_PID" ] && kill "$PER_PID" 2>/dev/null
  [ -n "$VIS_PID" ] && kill "$VIS_PID" 2>/dev/null
  [ -n "$PRK_PID" ] && kill "$PRK_PID" 2>/dev/null
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
if go test ./services/governance/service/... -count=1 >/tmp/verify-quorum.log 2>&1; then
  ok "go test ./services/governance/service/... (nisap ve çoğunluk kuralları)"
else
  bad "go test ./services/governance/service/..."; tail -15 /tmp/verify-quorum.log
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
PORT=${STUB_PORT:-18191} go run ./services/asset >/tmp/verify-stub.log 2>&1 &
STUB_PID=$!
SUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${STUB_PORT:-18191}/health" >/dev/null 2>&1 && { SUP=1; break; }
  sleep 1
done
if [ "$SUP" = "1" ]; then
  ok "stub servis (asset) ayağa kalktı"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/assets")
  [ "$SC" = "501" ] && ok "stub GET /assets → 501" || bad "stub GET /assets → $SC (501 bekleniyordu)"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/assets" \
    -H 'Content-Type: application/json' -d '{"name":"Test demirbas"}')
  [ "$SC" = "501" ] && ok "stub POST /assets → 501 (veri kaydedilmiyor)" || bad "stub POST /assets → $SC (501 bekleniyordu)"
  HDR=$(curl -s -D- -o /dev/null "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/assets" | grep -ci 'X-SiteEksen-Not-Implemented: true')
  [ "$HDR" -ge 1 ] && ok "stub yanıtında X-SiteEksen-Not-Implemented başlığı var" || bad "stub başlığı eksik"
else
  bad "stub servis başlamadı"
fi
kill "$STUB_PID" 2>/dev/null

# Kaynak düzeyinde: mock servislerde uydurma veri kalmamalı
# Yorum satırları hariç (neyin kaldırıldığını anlatan açıklamalar sayılmaz).
FAKE=$(grep -rn "Ali Veli\|Ayşe Yılmaz\|Ahmet Yılmaz\|Mehmet Demir\|AYEDAŞ" "$BACKEND_DIR/services" --include=*.go 2>/dev/null \
  | grep -v _test | grep -v ':[0-9]*:[[:space:]]*//' | wc -l)
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

  # --- Gecikme tazminatı (KMK m.20/2, aylık %5) ---
  # Demo tahakkuk: 1.200,00 TL, vade 2026-01-10. as_of 2026-02-09 → tam 30 gün gecikme.
  # Beklenen tazminat: 120000 kuruş × %5 × 30/30 = 6000 kuruş = 60,00 TL
  LFR=$(curl -s -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/late-fees/accrue" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"as_of":"2026-02-09"}')
  echo "$LFR" | grep -q '"monthly_rate":"0.05"' && ok "gecikme tazminatı oranı mevzuattan okundu (%5)" \
    || bad "gecikme tazminatı oranı beklenmedik: $LFR"

  LFV=$($PSQL -t -A -c "SELECT late_fee::text FROM monthly_assessments WHERE id='$ASSESS';")
  [ "$LFV" = "60.00" ] && ok "gecikme tazminatı doğru hesaplandı: 30 gün → 60,00 TL" \
    || bad "gecikme tazminatı $LFV (60.00 bekleniyordu)"

  TOTV=$($PSQL -t -A -c "SELECT total_amount::text FROM monthly_assessments WHERE id='$ASSESS';")
  [ "$TOTV" = "1260.00" ] && ok "toplam borç anapara + tazminat olarak güncellendi (1.260,00 TL)" \
    || bad "toplam borç $TOTV (1260.00 bekleniyordu)"

  # İkinci çalıştırma borcu ikiye katlamamalı (idempotency)
  curl -s -o /dev/null -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/late-fees/accrue" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"as_of":"2026-02-09"}'
  LFV2=$($PSQL -t -A -c "SELECT late_fee::text FROM monthly_assessments WHERE id='$ASSESS';")
  [ "$LFV2" = "60.00" ] && ok "gecikme tazminatı ikinci çalıştırmada değişmedi (idempotent)" \
    || bad "ikinci çalıştırmada tazminat $LFV2 oldu (birikmeli hesap hatası)"

  # Tahakkuk izi bırakılmış olmalı (borçlu itiraz ederse savunulabilir olmalı)
  ACC=$($PSQL -t -A -c "SELECT count(*) FROM late_fee_accruals WHERE assessment_id='$ASSESS' AND accrued_on='2026-02-09';")
  [ "$ACC" = "1" ] && ok "gecikme tazminatı tahakkuk izi kaydedildi (gün, oran, anapara)" \
    || bad "tahakkuk izi yok ($ACC kayıt)"

  $PSQL -c "UPDATE monthly_assessments SET late_fee=0, total_amount=base_amount, status='PENDING' WHERE id='$ASSESS'; DELETE FROM late_fee_accruals WHERE assessment_id='$ASSESS';" >/dev/null 2>&1
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

step "11) Yönetişim: işletme projesi, genel kurul, defter (FAZ 6)"
GOVPORT=${VERIFY_GOV_PORT:-18107}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${GOVPORT} \
  go run ./services/governance >/tmp/verify-governance.log 2>&1 &
GOV_PID=$!
GUP2=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${GOVPORT}/health" >/dev/null 2>&1 && { GUP2=1; break; }
  sleep 1
done

if [ "$GUP2" = "1" ] && [ -n "${MGR:-}" ]; then
  ok "governance-service ayağa kalktı"
  GA="Authorization: Bearer $MGR"
  GJ='Content-Type: application/json'
  GURL="http://127.0.0.1:${GOVPORT}/api/v1/governance"

  # --- İşletme projesi (KMK m.37) ---
  # 240.000 eşit + 60.000 arsa payı + 36.000 arsa payı = 336.000,00 TL = 33.600.000 kuruş
  BUD=$(curl -s -X POST "$GURL/budgets" -H "$GA" -H "$GJ" -d '{
    "period_year": 2031,
    "items":[{"name":"Kapıcı gideri","amount":240000,"distribution_type":"EQUAL"},
             {"name":"Sigorta primi","amount":60000,"distribution_type":"SHARE_RATIO"},
             {"name":"Asansör bakım","amount":36000,"distribution_type":"SHARE_RATIO"}]}')
  BID=$(echo "$BUD" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$BID" ] && ok "işletme projesi oluşturuldu" || bad "işletme projesi oluşturulamadı: $BUD"

  if [ -n "$BID" ]; then
    # Kuruş kaybı olmamalı: payların toplamı tutara BİREBİR eşit
    SUMK=$($PSQL -t -A -c "SELECT COALESCE(sum(annual_kurus),0) FROM operating_budget_unit_shares WHERE budget_id='$BID';")
    [ "$SUMK" = "33600000" ] && ok "dağıtımda kuruş kaybı yok (toplam $SUMK kuruş = 336.000,00 TL)" \
      || bad "dağıtım toplamı $SUMK kuruş (33600000 bekleniyordu)"

    # Eşit dağıtılan kalemde daireler arası fark en çok 1 kuruş olmalı
    SPREAD=$($PSQL -t -A -c "SELECT max(v)-min(v) FROM (SELECT (breakdown->>'Kapıcı gideri')::bigint AS v FROM operating_budget_unit_shares WHERE budget_id='$BID') t;")
    [ "$SPREAD" -le 1 ] 2>/dev/null && ok "eşit dağıtımda daireler arası fark <= 1 kuruş" \
      || bad "eşit dağıtımda fark $SPREAD kuruş"

    # Tebliğ edilmeden kesinleştirilemez (m.37)
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/finalize" -H "$GA" -H "$GJ" -d '{}')
    [ "$SC" = "409" ] && ok "tebliğ edilmeden kesinleştirme engellendi → 409" || bad "tebliğsiz kesinleştirme → $SC"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/notify" -H "$GA" -H "$GJ" \
      -d '{"method":"TAAHHUTLU_MEKTUP"}')
    [ "$SC" = "200" ] && ok "işletme projesi tebliğ edildi" || bad "tebliğ → $SC"

    # İtiraz süresi (7 gün) dolmadan kesinleşemez (m.37/2)
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/finalize" -H "$GA" -H "$GJ" -d '{}')
    [ "$SC" = "409" ] && ok "itiraz süresi dolmadan kesinleştirme engellendi → 409" \
      || bad "süre dolmadan kesinleştirme → $SC"

    DL=$($PSQL -t -A -c "SELECT (objection_deadline - CURRENT_DATE) FROM operating_budgets WHERE id='$BID';")
    [ "$DL" = "7" ] && ok "itiraz süresi 7 gün olarak işlendi (KMK m.37/2)" || bad "itiraz süresi $DL gün"
  fi

  # --- Genel kurul (KMK m.29-30) ---
  ASM=$(curl -s -X POST "$GURL/assemblies" -H "$GA" -H "$GJ" -d '{
    "kind":"ORDINARY","call_number":1,"scheduled_at":"2031-03-01T18:00:00Z",
    "agenda_items":[{"order_no":1,"title":"Yönetici seçimi"}]}')
  AID=$(echo "$ASM" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$AID" ] && ok "genel kurul oluşturuldu" || bad "genel kurul oluşturulamadı"

  if [ -n "$AID" ]; then
    # Tam yarı katılımda nisap SAĞLANMAMALI (m.30 "yarıdan fazla")
    for u in $($PSQL -t -A -c "SELECT id FROM units WHERE property_id='11111111-1111-1111-1111-111111111111' ORDER BY block, door_number LIMIT 12;"); do
      curl -s -o /dev/null -X POST "$GURL/assemblies/$AID/attendees" -H "$GA" -H "$GJ" -d "{\"unit_id\":\"$u\"}"
    done
    Q=$(curl -s "$GURL/assemblies/$AID/quorum" -H "$GA")
    echo "$Q" | grep -q '"met":false' && ok "12/24 katılımda nisap sağlanmadı (tam yarı yetmez)" \
      || bad "tam yarı katılımda nisap sağlandı sayıldı: $Q"

    # 13. daire eklenince nisap sağlanmalı
    U13=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='11111111-1111-1111-1111-111111111111' ORDER BY block, door_number OFFSET 12 LIMIT 1;")
    curl -s -o /dev/null -X POST "$GURL/assemblies/$AID/attendees" -H "$GA" -H "$GJ" -d "{\"unit_id\":\"$U13\"}"
    Q=$(curl -s "$GURL/assemblies/$AID/quorum" -H "$GA")
    echo "$Q" | grep -q '"met":true' && ok "13/24 katılımda nisap sağlandı" || bad "13/24 katılımda nisap sağlanmadı: $Q"
  fi

  # --- Defter (KMK m.32/36) ---
  BOOK=$(curl -s -X POST "$GURL/books?kind=DECISION&year=2031" -H "$GA" -H "$GJ" -d '{}')
  BKID=$(echo "$BOOK" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$BKID" ]; then
    curl -s -o /dev/null -X POST "$GURL/books/$BKID/entries" -H "$GA" -H "$GJ" \
      -d '{"title":"Olağan genel kurul","body":"Yönetici seçildi."}'
    curl -s -o /dev/null -X POST "$GURL/books/$BKID/entries" -H "$GA" -H "$GJ" \
      -d '{"title":"İşletme projesi","body":"2031 projesi kabul edildi."}'
    V=$(curl -s "$GURL/books/$BKID/verify" -H "$GA")
    echo "$V" | grep -q '"valid":true' && ok "defter hash zinciri doğrulandı" || bad "defter zinciri bozuk: $V"

    # Defter kaydı değiştirilemez olmalı
    UPD=$($PSQL -c "UPDATE book_entries SET body='degistirildi' WHERE book_id='$BKID';" 2>&1)
    echo "$UPD" | grep -q "değiştirilemez" && ok "defter kaydı değiştirilemiyor (veritabanı koruması)" \
      || bad "defter kaydı değiştirilebildi"
  else
    bad "defter oluşturulamadı"
  fi

  # --- Denetçi yazma yetkisi olmamalı (görevler ayrılığı) ---
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets" -H "Authorization: Bearer $TEN" -H "$GJ" \
    -d '{"period_year":2032,"items":[{"name":"x","amount":1,"distribution_type":"EQUAL"}]}')
  [ "$SC" = "403" ] && ok "yönetim rolü olmayan kullanıcı işletme projesi oluşturamıyor → 403" \
    || bad "yetkisiz kullanıcı işletme projesi oluşturdu → $SC"
else
  bad "governance-service başlamadı"; tail -10 /tmp/verify-governance.log
fi
kill "$GOV_PID" 2>/dev/null

step "12) Gider modülü — mock'tan gerçeğe (FAZ 5, ilk modül)"
EXPPORT=${VERIFY_EXP_PORT:-18086}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${EXPPORT} \
  go run ./services/expense >/tmp/verify-expense.log 2>&1 &
EXP_PID=$!
EUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${EXPPORT}/health" >/dev/null 2>&1 && { EUP=1; break; }
  sleep 1
done

if [ "$EUP" = "1" ] && [ -n "${MGR:-}" ]; then
  ok "expense-service ayağa kalktı"
  EA="Authorization: Bearer $MGR"
  EJ='Content-Type: application/json'
  EURL="http://127.0.0.1:${EXPPORT}/api/v1"

  # Sağlık ucu artık "not_implemented" değil "healthy" demeli
  curl -s "http://127.0.0.1:${EXPPORT}/health" | grep -q '"persistent":true' \
    && ok "expense sağlık ucu kalıcı veri katmanı bildiriyor" || bad "expense sağlık ucu yanlış"

  # Gider kalemleri gerçek veritabanından gelmeli (004 seed'i: 10 varsayılan kalem)
  CATS=$(curl -s "$EURL/expense-categories" -H "$EA")
  CATID=$(echo "$CATS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$CATID" ] && ok "gider kalemleri veritabanından geldi" || bad "gider kalemi alınamadı: $CATS"
  echo "$CATS" | grep -q 'KMK m.20' && ok "kalemler dağıtım türünün hukuki dayanağını taşıyor" \
    || bad "hukuki dayanak alanı yok"

  # Arsa payına göre paylaştırılan gider: 24 daire, toplam 10000 arsa payı
  # 12.000,00 TL → 1.200.000 kuruş; payların toplamı BİREBİR eşit olmalı
  # Aidata yansıyan ve zemin katı da kapsayan bir kalem seçilir ki 24 birimin
  # tamamına pay düşsün (kalem bazlı istisnalar ayrı olarak sınanır).
  SHARECAT=$($PSQL -t -A -c "SELECT id FROM expense_categories
      WHERE distribution_type='SHARE_RATIO' AND property_id IS NULL
        AND COALESCE(reflects_to_assessment,true)
        AND COALESCE(applies_to_ground_floor,true)
      ORDER BY COALESCE(display_order, sort_order, 0) LIMIT 1;")
  EXP=$(curl -s -X POST "$EURL/expenses" -H "$EA" -H "$EJ" -d "{
    \"category_id\":\"$SHARECAT\",\"description\":\"Ortak alan sigorta primi\",
    \"amount\":12000,\"expense_date\":\"2026-03-15\",\"vendor_name\":\"Test Sigorta\",
    \"invoice_number\":\"FT-2026-001\"}")
  EXPID=$(echo "$EXP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$EXPID" ] && ok "gider kaydı oluşturuldu ve KALICI" || bad "gider oluşturulamadı: $EXP"

  if [ -n "$EXPID" ]; then
    DSUM=$($PSQL -t -A -c "SELECT COALESCE(sum(amount),0)::text FROM expense_distributions WHERE expense_id='$EXPID';")
    [ "$DSUM" = "12000.00" ] && ok "gider dağıtımında kuruş kaybı yok (toplam 12.000,00 TL)" \
      || bad "dağıtım toplamı $DSUM (12000.00 bekleniyordu)"

    DCNT=$($PSQL -t -A -c "SELECT count(*) FROM expense_distributions WHERE expense_id='$EXPID';")
    [ "$DCNT" = "24" ] && ok "24 bağımsız bölümün tamamına pay düştü" || bad "$DCNT birime pay düştü"

    # Faturalı gider doğrudan onaylı olmalı
    ST=$($PSQL -t -A -c "SELECT status FROM expenses WHERE id='$EXPID';")
    [ "$ST" = "APPROVED" ] && ok "faturalı gider doğrudan onaylı" || bad "faturalı gider durumu $ST"
  fi

  # Faturasız gider gerekçe olmadan reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EURL/expenses" -H "$EA" -H "$EJ" -d "{
    \"category_id\":\"$SHARECAT\",\"description\":\"Faturasız tamir\",\"amount\":500,
    \"expense_date\":\"2026-03-16\",\"is_invoiced\":false}")
  [ "$SC" = "422" ] && ok "faturasız gider gerekçesiz kabul edilmiyor → 422" \
    || bad "faturasız gider gerekçesiz kabul edildi → $SC"

  # Gerekçeli faturasız gider ONAY BEKLER (doğrudan onaylanmaz)
  UNINV=$(curl -s -X POST "$EURL/expenses" -H "$EA" -H "$EJ" -d "{
    \"category_id\":\"$SHARECAT\",\"description\":\"Faturasız acil tamir\",\"amount\":500,
    \"expense_date\":\"2026-03-16\",\"is_invoiced\":false,
    \"invoice_reason\":\"Usta fatura kesemedi, tutanak tutuldu\"}")
  UID2=$(echo "$UNINV" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  UST=$($PSQL -t -A -c "SELECT status FROM expenses WHERE id='$UID2';")
  [ "$UST" = "PENDING" ] && ok "faturasız gider onay bekliyor (KMK m.39 hesap verme)" \
    || bad "faturasız gider durumu $UST (PENDING bekleniyordu)"

  # Onaydan sonra ikinci onay reddedilmeli
  curl -s -o /dev/null -X POST "$EURL/expenses/$UID2/approve" -H "$EA" -H "$EJ" -d '{}'
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EURL/expenses/$UID2/approve" -H "$EA" -H "$EJ" -d '{}')
  [ "$SC" = "409" ] && ok "çift onaylama engellendi → 409" || bad "çift onaylama → $SC"

  # Özet gerçek kayıtlardan üretilmeli
  SUM=$(curl -s "$EURL/expenses/summary?year=2026&month=3" -H "$EA")
  echo "$SUM" | grep -q '"total_amount":12500' && ok "dönem özeti gerçek kayıtlardan hesaplandı (12.500,00 TL)" \
    || bad "dönem özeti beklenmedik: $SUM"

  # Sakin gideri görememeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$EURL/expenses" -H "Authorization: Bearer $TEN")
  [ "$SC" = "403" ] && ok "sakin site geneli gider listesini göremiyor → 403" \
    || bad "sakin gider listesini gördü → $SC"
else
  bad "expense-service başlamadı"; tail -10 /tmp/verify-expense.log
fi
kill "$EXP_PID" 2>/dev/null

step "13) Personel modülü — mock'tan gerçeğe (FAZ 5, 2. modül)"
PERPORT=${VERIFY_PER_PORT:-18100}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PERPORT} \
  go run ./services/personnel >/tmp/verify-personnel.log 2>&1 &
PER_PID=$!
PUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${PERPORT}/health" >/dev/null 2>&1 && { PUP=1; break; }
  sleep 1
done

if [ "$PUP" = "1" ] && [ -n "${MGR:-}" ]; then
  ok "personnel-service ayağa kalktı"
  PA="Authorization: Bearer $MGR"
  PJ='Content-Type: application/json'
  PURL="http://127.0.0.1:${PERPORT}/api/v1"

  EMP=$(curl -s -X POST "$PURL/employees" -H "$PA" -H "$PJ" -d '{
    "first_name":"Test","last_name":"Personel","position":"Kapıcı",
    "hire_date":"2026-01-15","tc_number":"12345678901",
    "bank_iban":"TR330006100519786457841326","bank_name":"Test Bank",
    "gross_salary":30000,"net_salary":22000,"sgk_number":"1234567890"}')
  EMPID=$(echo "$EMP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$EMPID" ] && ok "personel kaydı oluşturuldu ve KALICI" || bad "personel oluşturulamadı: $EMP"

  # Varsayılan yıllık izin 14 gün olmalı (4857 s. İş Kanunu m.53)
  AL=$($PSQL -t -A -c "SELECT annual_leave_days FROM employees WHERE id='$EMPID';")
  [ "$AL" = "14" ] && ok "varsayılan yıllık izin 14 gün (İş K. m.53)" || bad "yıllık izin $AL gün"

  # KVKK: liste yanıtında TCKN ve IBAN MASKELİ olmalı
  LST=$(curl -s "$PURL/employees" -H "$PA")
  echo "$LST" | grep -q '12345678901' && bad "liste yanıtında TCKN maskesiz görünüyor" \
    || ok "liste yanıtında TCKN maskeli (KVKK veri minimizasyonu)"
  echo "$LST" | grep -q 'TR330006100519786457841326' && bad "liste yanıtında IBAN maskesiz" \
    || ok "liste yanıtında IBAN maskeli"
  echo "$LST" | grep -q '"gross_salary":30000' && ok "yöneticiye maaş bilgisi dönüyor" \
    || bad "yöneticiye maaş dönmedi"

  # Sakin personel modülüne hiç erişememeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/employees" -H "Authorization: Bearer $TEN")
  [ "$SC" = "403" ] && ok "sakin personel modülüne erişemiyor → 403" \
    || bad "sakin personel listesini gördü → $SC"

  # İzin akışı: talep → onay → bakiye düşümü
  LV=$(curl -s -X POST "$PURL/leaves" -H "$PA" -H "$PJ" -d "{
    \"employee_id\":\"$EMPID\",\"leave_type\":\"ANNUAL\",
    \"start_date\":\"2026-07-01\",\"end_date\":\"2026-07-05\",\"reason\":\"Yıllık izin\"}")
  LVID=$(echo "$LV" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$LVID" ] && ok "izin talebi oluşturuldu" || bad "izin talebi oluşturulamadı: $LV"

  # Gün sayısı sunucuda hesaplanmalı (1-5 Temmuz dahil = 5 gün)
  LD=$($PSQL -t -A -c "SELECT days::int FROM employee_leaves WHERE id='$LVID';")
  [ "$LD" = "5" ] && ok "izin gün sayısı sunucuda hesaplandı (5 gün)" || bad "izin günü $LD"

  # Çakışan izin reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/leaves" -H "$PA" -H "$PJ" -d "{
    \"employee_id\":\"$EMPID\",\"leave_type\":\"ANNUAL\",
    \"start_date\":\"2026-07-03\",\"end_date\":\"2026-07-08\"}")
  [ "$SC" = "409" ] && ok "çakışan izin talebi reddedildi → 409" || bad "çakışan izin kabul edildi → $SC"

  curl -s -o /dev/null -X POST "$PURL/leaves/$LVID/approve" -H "$PA" -H "$PJ" -d '{}'
  REM=$($PSQL -t -A -c "SELECT remaining_leave_days FROM employees WHERE id='$EMPID';")
  [ "$REM" = "9" ] && ok "onaydan sonra izin bakiyesi düştü (14 → 9)" || bad "izin bakiyesi $REM (9 bekleniyordu)"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/leaves/$LVID/approve" -H "$PA" -H "$PJ" -d '{}')
  [ "$SC" = "409" ] && ok "çift onaylama engellendi → 409" || bad "çift onaylama → $SC"

  # İşten ayrılışta kayıt SİLİNMEMELİ
  curl -s -o /dev/null -X POST "$PURL/employees/$EMPID/terminate" -H "$PA" -H "$PJ" \
    -d '{"reason":"İstifa","end_date":"2026-08-31"}'
  STILL=$($PSQL -t -A -c "SELECT count(*) FROM employees WHERE id='$EMPID';")
  ACT=$($PSQL -t -A -c "SELECT is_active FROM employees WHERE id='$EMPID';")
  [ "$STILL" = "1" ] && [ "$ACT" = "f" ] && ok "işten ayrılışta özlük kaydı silinmiyor, pasife alınıyor" \
    || bad "özlük kaydı silindi ya da pasife alınmadı (count=$STILL active=$ACT)"
else
  bad "personnel-service başlamadı"; tail -10 /tmp/verify-personnel.log
fi
kill "$PER_PID" 2>/dev/null

step "14) Ziyaretçi modülü — mock'tan gerçeğe (FAZ 5, 3. modül)"
VISPORT=${VERIFY_VIS_PORT:-18105}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${VISPORT} \
  go run ./services/visitor >/tmp/verify-visitor.log 2>&1 &
VIS_PID=$!
VUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${VISPORT}/health" >/dev/null 2>&1 && { VUP=1; break; }
  sleep 1
done

if [ "$VUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "visitor-service ayağa kalktı"
  VA="Authorization: Bearer $MGR"
  VT="Authorization: Bearer $TEN"
  VJ='Content-Type: application/json'
  VURL="http://127.0.0.1:${VISPORT}/api/v1"

  # Yöneticinin dairesi A-3, kiracının dairesi A-4
  MGRUNIT='33333333-3333-3333-3333-333333333303'
  TENUNIT='33333333-3333-3333-3333-333333333304'

  V1=$(curl -s -X POST "$VURL/visitors" -H "$VA" -H "$VJ" -d "{
    \"unit_id\":\"$MGRUNIT\",\"visitor_name\":\"Yonetici Ziyaretcisi\",
    \"visitor_id_number\":\"98765432109\",\"purpose\":\"Misafir\",
    \"expected_at\":\"2026-10-01T14:00:00Z\"}")
  V1ID=$(echo "$V1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$V1ID" ] && ok "ziyaretçi ön kaydı oluşturuldu ve KALICI" || bad "ziyaretçi kaydı yok: $V1"

  # Sahte "SMS/QR gönderildi" iddiası olmamalı
  echo "$V1" | grep -q 'henüz devrede değildir' \
    && ok "bildirim gönderilmediği dürüstçe bildiriliyor" || bad "bildirim durumu belirtilmemiş"

  # Kiracı kendi dairesine ziyaretçi kaydeder
  V2=$(curl -s -X POST "$VURL/visitors" -H "$VT" -H "$VJ" -d "{
    \"unit_id\":\"$TENUNIT\",\"visitor_name\":\"Kiraci Ziyaretcisi\",\"purpose\":\"Misafir\"}")
  V2ID=$(echo "$V2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$V2ID" ] && ok "sakin kendi dairesine ziyaretçi kaydedebiliyor" || bad "sakin ziyaretçi kaydedemedi: $V2"

  # MAHREMİYET: kiracı yalnızca KENDİ dairesinin ziyaretçisini görmeli
  TLIST=$(curl -s "$VURL/visitors" -H "$VT")
  echo "$TLIST" | grep -q 'Kiraci Ziyaretcisi' && ok "sakin kendi ziyaretçisini görüyor" \
    || bad "sakin kendi ziyaretçisini göremedi"
  echo "$TLIST" | grep -q 'Yonetici Ziyaretcisi' \
    && bad "sakin BAŞKA DAİRENİN ziyaretçisini görüyor (mahremiyet ihlali)" \
    || ok "sakin başka dairenin ziyaretçisini göremiyor (mahremiyet)"

  # Yönetim tüm siteyi görür
  MLIST=$(curl -s "$VURL/visitors" -H "$VA")
  echo "$MLIST" | grep -q 'Kiraci Ziyaretcisi' && ok "yönetim site genelini görüyor" \
    || bad "yönetim tüm ziyaretçileri göremedi"

  # Kimlik numarası maskeli (yönetici olmayan için)
  echo "$TLIST" | grep -q '98765432109' && bad "kimlik numarası maskesiz sızdı" \
    || ok "kimlik numarası sakine maskeli/gizli"

  # Giriş/çıkış akışı ve çift giriş koruması
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V1ID/check-in" -H "$VA" -H "$VJ" -d '{}')
  [ "$SC" = "200" ] && ok "ziyaretçi girişi kaydedildi" || bad "giriş → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V1ID/check-in" -H "$VA" -H "$VJ" -d '{}')
  [ "$SC" = "409" ] && ok "çift giriş engellendi → 409" || bad "çift giriş → $SC"

  INSIDE=$(curl -s "$VURL/visitors/summary" -H "$VA")
  echo "$INSIDE" | grep -q '"currently_inside":1' && ok "içerideki ziyaretçi sayısı doğru (1)" \
    || bad "içeride sayısı beklenmedik: $INSIDE"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V1ID/check-out" -H "$VA" -H "$VJ" -d '{}')
  [ "$SC" = "200" ] && ok "ziyaretçi çıkışı kaydedildi" || bad "çıkış → $SC"

  # Sakin giriş/çıkış yapamaz (güvenlik görevi değil)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V2ID/check-in" -H "$VT" -H "$VJ" -d '{}')
  [ "$SC" = "403" ] && ok "sakin giriş/çıkış kaydı yapamıyor → 403" || bad "sakin giriş yaptı → $SC"

  # Başka sitenin bağımsız bölümü kabul edilmemeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors" -H "$VA" -H "$VJ" -d '{
    "unit_id":"00000000-0000-0000-0000-000000000999","visitor_name":"Test"}')
  [ "$SC" = "400" ] && ok "başka siteye ait bağımsız bölüm reddedildi → 400" \
    || bad "geçersiz bağımsız bölüm kabul edildi → $SC"
else
  bad "visitor-service başlamadı"; tail -10 /tmp/verify-visitor.log
fi
kill "$VIS_PID" 2>/dev/null

step "15) Otopark modülü — mock'tan gerçeğe (FAZ 5, 4. modül)"
PRKPORT=${VERIFY_PRK_PORT:-18098}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_PASSWORD="$PW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PRKPORT} \
  go run ./services/parking >/tmp/verify-parking.log 2>&1 &
PRK_PID=$!
KUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${PRKPORT}/health" >/dev/null 2>&1 && { KUP=1; break; }
  sleep 1
done

if [ "$KUP" = "1" ] && [ -n "${MGR:-}" ]; then
  ok "parking-service ayağa kalktı"
  KA="Authorization: Bearer $MGR"
  KJ='Content-Type: application/json'
  KURL="http://127.0.0.1:${PRKPORT}/api/v1"

  # Ücretli misafir otoparkı: saatlik 25 TL, günlük 100 TL, kapasite 2
  ZONE=$($PSQL -t -A -c "INSERT INTO parking_zones (property_id, name, capacity, is_paid, hourly_fee, daily_fee, is_visitor_allowed)
      VALUES ('11111111-1111-1111-1111-111111111111','Misafir Otoparki',2,true,25,100,true) RETURNING id;")
  [ -n "$ZONE" ] && ok "otopark bölgesi oluşturuldu" || bad "bölge oluşturulamadı"

  # Araç kaydı — plaka normalleştirmesi sınanır
  V=$(curl -s -X POST "$KURL/vehicles" -H "$KA" -H "$KJ" -d '{
    "unit_id":"33333333-3333-3333-3333-333333333303","plate":"34 abc 123",
    "brand":"Test","model":"Arac","owner_name":"Sakin"}')
  VID=$(echo "$V" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$VID" ] && ok "araç kaydı oluşturuldu ve KALICI" || bad "araç kaydedilemedi: $V"

  # Aynı plaka farklı yazımla tekrar kaydedilememeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/vehicles" -H "$KA" -H "$KJ" \
    -d '{"plate":"34-ABC-123"}')
  [ "$SC" = "409" ] && ok "aynı plaka farklı yazımla tekrar kaydedilemiyor → 409" \
    || bad "plaka çift kaydedildi → $SC"

  # Plakadan sorgulama (normalleştirilmiş arama)
  PQ=$(curl -s "$KURL/vehicles/plate/34ABC123" -H "$KA")
  echo "$PQ" | grep -q '"plate"' && ok "plakadan araç sorgulama çalışıyor" || bad "plaka sorgusu: $PQ"

  # Sakin aracı giriş yapar → ÜCRETSİZ olmalı
  E1=$(curl -s -X POST "$KURL/parking-logs/entry" -H "$KA" -H "$KJ" -d "{
    \"plate\":\"34 ABC 123\",\"parking_zone_id\":\"$ZONE\",\"entry_method\":\"MANUAL\"}")
  E1ID=$(echo "$E1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "$E1" | grep -q '"is_resident_vehicle":true' && ok "sitede kayıtlı araç tanındı" \
    || bad "kayıtlı araç tanınmadı: $E1"

  # Aynı plaka çıkış yapmadan tekrar giremez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/parking-logs/entry" -H "$KA" -H "$KJ" \
    -d "{\"plate\":\"34ABC123\",\"parking_zone_id\":\"$ZONE\"}")
  [ "$SC" = "409" ] && ok "çıkış yapmamış araç tekrar giremiyor → 409" || bad "çift giriş → $SC"

  # Misafir aracı girişi
  E2=$(curl -s -X POST "$KURL/parking-logs/entry" -H "$KA" -H "$KJ" -d "{
    \"plate\":\"06 XYZ 999\",\"parking_zone_id\":\"$ZONE\"}")
  E2ID=$(echo "$E2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "$E2" | grep -q '"is_resident_vehicle":false' && ok "misafir aracı ayırt edildi" \
    || bad "misafir aracı ayırt edilemedi"

  # Bölge kapasitesi 2 → üçüncü araç reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/parking-logs/entry" -H "$KA" -H "$KJ" \
    -d "{\"plate\":\"35 KKK 111\",\"parking_zone_id\":\"$ZONE\"}")
  [ "$SC" = "409" ] && ok "dolu bölgeye giriş engellendi → 409" || bad "dolu bölgeye giriş → $SC"

  # Doluluk GERÇEK açık kayıtlardan sayılmalı
  ZL=$(curl -s "$KURL/parking-zones" -H "$KA")
  echo "$ZL" | grep -q '"occupied_count":2' && ok "doluluk gerçek giriş kayıtlarından sayılıyor (2/2)" \
    || bad "doluluk yanlış: $ZL"

  # Sakin aracı çıkışı → ücret 0
  X1=$(curl -s -X POST "$KURL/parking-logs/$E1ID/exit" -H "$KA" -H "$KJ" -d '{}')
  echo "$X1" | grep -q '"calculated_fee":0' && ok "sitede kayıtlı araçtan ücret alınmıyor" \
    || bad "kayıtlı araca ücret çıktı: $X1"

  # Misafir çıkışı → başlanan saat tam sayılır (25 TL)
  X2=$(curl -s -X POST "$KURL/parking-logs/$E2ID/exit" -H "$KA" -H "$KJ" -d '{}')
  echo "$X2" | grep -q '"calculated_fee":25' && ok "misafir ücreti hesaplandı (başlanan saat = 25 TL)" \
    || bad "misafir ücreti beklenmedik: $X2"
  echo "$X2" | grep -q 'TAHSİL EDİLMEDİ' && ok "ücretin tahsil edilmediği dürüstçe bildiriliyor" \
    || bad "tahsilat durumu belirtilmemiş"

  # Çıkış yapmış kayda tekrar çıkış verilemez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/parking-logs/$E2ID/exit" -H "$KA" -H "$KJ" -d '{}')
  [ "$SC" = "409" ] && ok "çift çıkış engellendi → 409" || bad "çift çıkış → $SC"

  # Sakin giriş/çıkış kaydı yapamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/parking-logs/entry" \
    -H "Authorization: Bearer $TEN" -H "$KJ" -d '{"plate":"01 AAA 111"}')
  [ "$SC" = "403" ] && ok "sakin otopark giriş kaydı yapamıyor → 403" || bad "sakin giriş yaptı → $SC"
else
  bad "parking-service başlamadı"; tail -10 /tmp/verify-parking.log
fi
kill "$PRK_PID" 2>/dev/null

step "SONUÇ"
echo "  Geçen: $PASS   Başarısız: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TÜM KONTROLLER GEÇTİ"; exit 0; } || { echo "  BAŞARISIZ KONTROL VAR"; exit 1; }
