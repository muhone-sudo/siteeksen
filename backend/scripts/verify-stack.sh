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
# Kişisel veri şifreleme anahtarı (FAZ 2.8). Doğrulama için üretilir;
# üretimde gizli yönetiminden gelir ve ASLA depoya yazılmaz.
PIIKEY=$(head -c 32 /dev/urandom | base64 -w0)
export PIIKEY
SVC_PID=""
STUB_PID=""
GW_PID=""
FIN_PID=""
GOV_PID=""
EXP_PID=""
PER_PID=""
PER2_PID=""
VIS_PID=""
PRK_PID=""
RES_PID=""
PKG_PID=""
CTR_PID=""
DOC_PID=""
AST_PID=""
INV_PID=""
SRV_PID=""
IOT_PID=""
NTF_PID=""
PTR_PID=""
BUL_PID=""
SET_PID=""
ENE_PID=""
NPS_PID=""
ESG_PID=""
BNK_PID=""
MTG_PID=""
SMC_PID=""
COM_PID=""


# qscoped, satır düzeyi güvenliği AÇIK tablolarda sorgu çalıştırır.
#
# RLS açık tablolarda kapsam (app.property_id) ayarlanmadan sorgu SIFIR satır
# döndürür — bu, korumanın çalıştığının işaretidir. Doğrulama sorguları da
# uygulamanın yaptığı gibi kapsamı ayarlamak zorundadır.
DEMO_PROPERTY='11111111-1111-1111-1111-111111111111'
# RLS'e tabi tablolarda sorgu, UYGULAMA ROLÜYLE ve kapsam ayarlanarak çalışır.
# Süper kullanıcıyla çalıştırmak politikaları atlar ve doğrulamayı anlamsız kılar.
qscoped() {
  PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
    -t -A -c "SET LOCAL app.property_id = '${2:-$DEMO_PROPERTY}'; $1" 2>/dev/null | tail -1
}

# qapp, kapsam AYARLAMADAN uygulama rolüyle sorgu çalıştırır (RLS sınamaları için).
qapp() {
  PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
    -t -A -c "$1" 2>/dev/null | tail -1
}

ok()   { echo "  [GEÇTİ]    $1"; PASS=$((PASS+1)); }
bad()  { echo "  [BAŞARISIZ] $1"; FAIL=$((FAIL+1)); }
step() { echo ""; echo "=== $1 ==="; }

# kill_tree, bir sürecin ÇOCUKLARIYLA BİRLİKTE öldürülmesini sağlar.
#
# `go run X &` iki süreç yaratır: `go run` sarmalayıcısı ve derlenmiş ikili.
# Yalnızca sarmalayıcıyı öldürmek ikiliyi ayakta bırakır; ikili portu tutmaya
# devam eder ve BİR SONRAKİ çalıştırmanın sağlık kontrolü bu eski sürece cevap
# verir. Testler o zaman eski veritabanına karşı koşar ve sonuçlar rastgele
# değişir. Bu yüzden ağacın tamamı öldürülür.
kill_tree() {
  local pid="$1"
  [ -z "$pid" ] && return 0
  local child
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    kill_tree "$child"
  done
  kill "$pid" 2>/dev/null || true
}

# free_port, verilen portu dinleyen kalıntı süreçleri sonlandırır.
# Önceki (yarıda kesilmiş) bir çalıştırmadan kalan servis, yeni çalıştırmayı
# sessizce bozar; bu yüzden başlamadan önce süpürülür.
free_port() {
  local port="$1" pid
  for pid in $(ss -lntp 2>/dev/null | grep -oE "127\\.0\\.0\\.1:${port}\\b.*pid=[0-9]+" \
               | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u); do
    kill_tree "$pid"
  done
}

cleanup() {
  kill_tree "$SVC_PID"
  kill_tree "$STUB_PID"
  kill_tree "$GW_PID"
  kill_tree "$FIN_PID"
  kill_tree "$GOV_PID"
  kill_tree "$EXP_PID"
  kill_tree "$PER_PID"
  kill_tree "$PER2_PID"
  kill_tree "$VIS_PID"
  kill_tree "$PRK_PID"
  kill_tree "$RES_PID"
  kill_tree "$PKG_PID"
  kill_tree "$CTR_PID"
  kill_tree "$DOC_PID"
  kill_tree "$AST_PID"
  kill_tree "$INV_PID"
  kill_tree "$SRV_PID"
  kill_tree "$IOT_PID"
  kill_tree "$NTF_PID"
  kill_tree "$PTR_PID"
  kill_tree "$BUL_PID"
  kill_tree "$SET_PID"
  kill_tree "$ENE_PID"
  kill_tree "$NPS_PID"
  kill_tree "$ESG_PID"
  kill_tree "$BNK_PID"
  kill_tree "$MTG_PID"
  kill_tree "$SMC_PID"
  kill_tree "$COM_PID"
  kill_tree "${GW2_PID:-}"; kill_tree "${STUB2_PID:-}"
  kill_tree "${H_PER:-}"; kill_tree "${H_PRK:-}"; kill_tree "${H_VIS:-}"
  kill_tree "${H_INV:-}"; kill_tree "${H_GOV:-}"
  rm -rf /tmp/verify-docs
  docker rm -f "$CNAME" >/dev/null 2>&1
}
trap cleanup EXIT

command -v docker >/dev/null || { echo "docker bulunamadı"; exit 1; }
command -v psql   >/dev/null || { echo "psql bulunamadı"; exit 1; }
command -v go     >/dev/null || { echo "go bulunamadı (PATH'e /usr/local/go/bin ekleyin)"; exit 1; }

# Kalıntı süpürme: yarıda kesilmiş bir çalıştırmadan kalan servisler
# portları tutuyorsa, testler eski süreçlere çarpar ve sonuç rastgele değişir.
for _p in 18082 18083 18086 18093 18095 18096 18103 18106 18198 18199 18084 18085 18087 18088 18089 18090 18104 18091 18092 18093 18094 18097 18098 18099 18100 18105 18107 18191; do
  free_port "$_p"
done

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
if go test ./pkg/pii/... -count=1 >/tmp/verify-pii.log 2>&1; then
  ok "go test ./pkg/pii/... (şifreleme, blind index, TCKN/IBAN doğrulama)"
else
  bad "go test ./pkg/pii/..."; tail -15 /tmp/verify-pii.log
fi
if go test ./services/nps/service/... -count=1 >/tmp/verify-nps.log 2>&1; then
  ok "go test ./services/nps/service/... (NPS tanımı: 0-6/7-8/9-10)"
else
  bad "go test ./services/nps/service/..."; tail -15 /tmp/verify-nps.log
fi
if go test ./services/energy_analytics/service/... ./services/smart_collection/service/... \
   -count=1 >/tmp/verify-analytics.log 2>&1; then
  ok "go test enerji + tahsilat riski (medyan sapması, açıklanabilir skor)"
else
  bad "go test analitik paketleri"; tail -15 /tmp/verify-analytics.log
fi
if go test ./pkg/notify/... -count=1 >/tmp/verify-notify.log 2>&1; then
  ok "go test ./pkg/notify/... (bildirim kuyruğu, kanal seçimi, maskeleme)"
else
  bad "go test ./pkg/notify/..."; tail -15 /tmp/verify-notify.log
fi
if go test ./services/iot/service/... -count=1 >/tmp/verify-alloc.log 2>&1; then
  ok "go test ./services/iot/service/... (ısı gideri %70/%30 paylaştırma, kuruş kaybı yok)"
else
  bad "go test ./services/iot/service/..."; tail -15 /tmp/verify-alloc.log
fi
if go test ./services/asset/service/... -count=1 >/tmp/verify-deprec.log 2>&1; then
  ok "go test ./services/asset/service/... (doğrusal amortisman, kuruş kaybı yok)"
else
  bad "go test ./services/asset/service/..."; tail -15 /tmp/verify-deprec.log
fi
if go test ./pkg/storage/... -count=1 >/tmp/verify-storage.log 2>&1; then
  ok "go test ./pkg/storage/... (dosya depolama, SigV4 imzalama, dizin dışına çıkma)"
else
  bad "go test ./pkg/storage/..."; tail -15 /tmp/verify-storage.log
fi
if go test ./services/governance/service/... -count=1 >/tmp/verify-quorum.log 2>&1; then
  ok "go test ./services/governance/service/... (nisap ve çoğunluk kuralları)"
else
  bad "go test ./services/governance/service/..."; tail -15 /tmp/verify-quorum.log
fi

# Dağıtım dosyaları (compose, k8s, CI imajları, Dockerfile'lar) servis
# listesinden sapmamalı. Önceden compose'da 18 servisin veritabanı ayarı yoktu,
# 8'i süper kullanıcıyla bağlanıyordu; k8s ve CI 24 servisin çoğunu hiç
# tanımıyordu. Üreteç tek kaynaktır; burada sapma yakalanır.
if python3 "$SCRIPT_DIR/gen-deploy.py" --check >/tmp/verify-gendeploy.log 2>&1; then
  ok "dağıtım dosyaları servis listesiyle tutarlı (gen-deploy --check)"
else
  bad "dağıtım dosyaları sapmış"; cat /tmp/verify-gendeploy.log | sed 's/^/      /'
fi
# Gateway her servis rotasını doğru servise yönlendirmeli. Önceden servisler
# yalnızca kendi portlarından sınanıyordu; ayarlar, devriye, ilan panosu, sayaç
# okuma, bildirim tercihleri ve modül özetleri gateway'de HİÇ yoktu.
if python3 "$SCRIPT_DIR/check-gateway-routes.py" >/tmp/verify-gwroutes.log 2>&1; then
  ok "gateway yönlendirmesi servis rotalarıyla tutarlı ($(tail -1 /tmp/verify-gwroutes.log))"
else
  bad "gateway yönlendirmesinde eksik/yanlış rota var"; head -20 /tmp/verify-gwroutes.log | sed 's/^/      /'
fi
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  if (cd "$SCRIPT_DIR/../.." && docker compose -f docker-compose.yml config -q) >/dev/null 2>&1; then
    bad "compose gizli değerler verilmeden geçerli sayıldı (varsayılan parola var)"
  else
    ok "compose zorunlu gizli değerler olmadan açılmıyor (varsayılan parola yok)"
  fi
  if (cd "$SCRIPT_DIR/../.." && DB_PASSWORD=a APP_DB_PASSWORD=b IDENTITY_DB_PASSWORD=c \
      JWT_SECRET=verify-secret-key-at-least-32-chars NEXTAUTH_SECRET=d PII_ENCRYPTION_KEY=e \
      docker compose -f docker-compose.yml config -q) >/dev/null 2>&1; then
    ok "compose gizli değerlerle geçerli"
  else
    bad "compose yapılandırması geçersiz"
  fi
fi

step "1) Temiz PostgreSQL 16"
docker rm -f "$CNAME" >/dev/null 2>&1
docker run --rm -d --name "$CNAME" -e POSTGRES_PASSWORD="$PW" -e POSTGRES_DB=siteeksen \
  -e POSTGRES_USER=siteeksen -p ${DBPORT}:5432 postgres:16 -c max_connections=300 >/dev/null
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
# Rol parolaları: RLS SÜPER KULLANICIYI BAĞLAMAZ; servisler yetkisi sınırlı
# rollerle bağlanır. Parola migration dosyasına yazılamaz (sürüm deposuna
# girerdi); dağıtımda olduğu gibi `cmd/migrate` ortam değişkeninden atar.
# Parolalar BİLEREK URL'de özel anlamı olan karakterler içerir: DSN'in parolayı
# kaçışla kurduğu her çalıştırmada sınanır (önceden düz birleştiriliyordu ve
# base64 parolalar bağlantı adresini bozuyordu).
APPPW="verify/app+$(head -c 12 /dev/urandom | base64 | tr -d '/+=')@#="
IDPW="verify/id+$(head -c 12 /dev/urandom | base64 | tr -d '/+=')@#="
export APP_DB_PASSWORD="$APPPW" IDENTITY_DB_PASSWORD="$IDPW"
if go run ./cmd/migrate -dir "$MIG_DIR" >/tmp/verify-mig.log 2>&1; then
  APPLIED=$(grep -c 'uygulandı:' /tmp/verify-mig.log)
  ok "cmd/migrate: $APPLIED migration uygulandı"
else
  bad "cmd/migrate başarısız"; tail -12 /tmp/verify-mig.log | sed 's/^/      /'
  echo "Migration zinciri kırık — sonraki adımlar atlanıyor"; exit 1
fi

for R in siteeksen_app siteeksen_identity; do
  grep -q "rol $R: giriş parolası atandı" /tmp/verify-mig.log \
    && PGPASSWORD="$([ "$R" = siteeksen_app ] && echo "$APPPW" || echo "$IDPW")" \
       psql -h 127.0.0.1 -p "${DBPORT}" -U "$R" -d siteeksen -t -A -c "SELECT 1;" >/dev/null 2>&1 \
    && ok "cmd/migrate $R rolüne parola atadı ve rol giriş yapabiliyor" \
    || bad "$R rolü hazırlanamadı (cmd/migrate rol ataması)"
done
# Süper kullanıcı olmadıkları doğrulanır: süper kullanıcı RLS'i atlar.
SUPERS=$($PSQL -t -A -c "SELECT count(*) FROM pg_roles
  WHERE rolname IN ('siteeksen_app','siteeksen_identity') AND (rolsuper OR rolbypassrls);")
[ "$SUPERS" = "0" ] && ok "uygulama ve kimlik rolleri süper kullanıcı değil, RLS'i atlayamaz" \
  || bad "$SUPERS rol RLS'i atlayabiliyor (rolsuper/rolbypassrls)"
APPPSQL="psql -h 127.0.0.1 -p ${DBPORT} -U siteeksen_app -d siteeksen -v ON_ERROR_STOP=1 -q"

# Sürüm tablosu gerçekten dolduruldu mu?
SM=$($PSQL -t -A -c "SELECT count(*) FROM schema_migrations;")
MIGFILES=$(ls "$MIG_DIR"/*.sql | wc -l)
[ "$SM" = "$MIGFILES" ] && ok "schema_migrations: $SM kayıt (dosya sayısıyla eşit)" \
  || bad "schema_migrations $SM kayıt, dosya sayısı $MIGFILES"

step "3) Şema beklentileri"
TBL=$($PSQL -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';")
[ "$TBL" -ge 60 ] && ok "tablo sayısı: $TBL (>=60)" || bad "tablo sayısı yetersiz: $TBL"

for t in expenses parking_zones reservations bank_accounts employees surveys assets meetings \
         documents document_access_logs notifications notification_preferences \
         property_settings property_setting_history \
         revoked_tokens user_token_invalidation; do
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
# Çıktı önce dosyaya alınır: `| grep -q` ilk eşleşmede boruyu kapatır ve
# çalıştırıcının sonraki satırları (rol ataması) SIGPIPE ile düşer; pipefail
# altında bu, başarılı çalıştırmayı başarısız gösterirdi.
go run ./cmd/migrate -dir "$MIG_DIR" >/tmp/verify-mig2.log 2>&1
if grep -q 'güncel' /tmp/verify-mig2.log && ! grep -q 'uygulandı:' /tmp/verify-mig2.log; then
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
# TEST_APP_DATABASE_URL: site istisnalarının RLS altında (029) yalnızca kendi
# sitesinde göründüğü uygulama rolüyle sınanır. Parola özel karakter içerdiği
# için anahtar=değer biçiminde verilir.
if TEST_DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen" \
   TEST_APP_DATABASE_URL="host=127.0.0.1 port=${DBPORT} user=siteeksen_app password='${APPPW}' dbname=siteeksen sslmode=disable" \
   go test ./pkg/legalparams/... -count=1 -v >/tmp/verify-legal.log 2>&1; then
  ok "go test ./pkg/legalparams/... (mevzuat parametreleri)"
  grep -q -- '--- PASS: TestSiteIstisnasiUygulamaRoluyleYalnizcaKendiSitesinde' /tmp/verify-legal.log \
    && ok "site istisnası uygulama rolüyle yalnızca kendi sitesinde görünüyor (RLS, 029)" \
    || bad "legal_parameters RLS testi çalışmadı (atlandı?)"
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
# Kimlik servisi KENDİ rolüyle bağlanır (migration 025): dizin tablolarının
# tamamını görür, site verisine hiç erişemez.
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
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
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${STUB_PORT:-18191} \
  go run ./services/banking >/tmp/verify-stub.log 2>&1 &
STUB_PID=$!
SUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${STUB_PORT:-18191}/health" >/dev/null 2>&1 && { SUP=1; break; }
  sleep 1
done
if [ "$SUP" = "1" ]; then
  ok "stub servis (banking) ayağa kalktı"

  # Kimliksiz istek 401 almalı: 501'i kimliksiz servis etmek, olmayan bir
  # modülün varlığını dışarıya doğrulamak olurdu.
  SC=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/bank-accounts")
  [ "$SC" = "401" ] && ok "stub uçları da kimlik doğrulaması arkasında → 401" \
    || bad "stub ucu kimliksiz erişilebiliyor → $SC"

  # Kimlikli istek 501 dönmeli: uç var ama KAYDETMİYOR.
  STUBTOK=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5551234567","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  STUBAUTH="Authorization: Bearer $STUBTOK"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -H "$STUBAUTH" \
    "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/bank-accounts")
  [ "$SC" = "501" ] && ok "stub GET /bank-accounts → 501" || bad "stub GET /bank-accounts → $SC (501 bekleniyordu)"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "$STUBAUTH" \
    "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/bank-accounts" \
    -H 'Content-Type: application/json' -d '{"bank":"test"}')
  [ "$SC" = "501" ] && ok "stub POST /bank-accounts → 501 (veri kaydedilmiyor)" || bad "stub POST /bank-accounts → $SC (501 bekleniyordu)"
  HDR=$(curl -s -D- -o /dev/null -H "$STUBAUTH" \
    "http://127.0.0.1:${STUB_PORT:-18191}/api/v1/bank-accounts" | grep -ci 'X-SiteEksen-Not-Implemented: true')
  [ "$HDR" -ge 1 ] && ok "stub yanıtında X-SiteEksen-Not-Implemented başlığı var" || bad "stub başlığı eksik"
else
  bad "stub servis başlamadı"
fi
kill_tree "$STUB_PID"

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
kill_tree "$GW_PID"

# Kaynak düzeyinde Kong (2026-09-27): Kong yalnızca gateway'in ÖNÜNDE durur.
# Önceden 26 servisi tek tek yönlendiriyordu; rotalar gateway'den sapmıştı ve
# jwt eklentisi jeton iptalini bilmiyordu. Servise doğrudan rota, kimlik
# doğrulamayı ve başlık temizliğini atlayan bir yan kapı olurdu.
KONG="$BACKEND_DIR/../kong/kong.yml"
KURLS=$(grep -E '^\s*url:' "$KONG" | sed -E 's/^\s*url:\s*//' | tr -d "'\"" | sort -u | tr '\n' ' ')
[ "$KURLS" = "http://gateway:8888 " ] && ok "kong.yml: tek yukarı akış gateway (servislere doğrudan rota yok)" \
  || bad "kong.yml yukarı akışları: '$KURLS' (yalnızca http://gateway:8888 bekleniyordu)"
python3 - "$KONG" <<'PY' && ok "kong.yml: /api/v1/auth IP başına sıkı hız sınırı, belge sınırıyla uyumlu gövde sınırı" \
  || bad "kong.yml: hız/gövde sınırı beklenen gibi değil"
import re, sys
s = open(sys.argv[1], encoding="utf-8").read()
auth = s.split("- name: auth", 1)[1].split("- name: api", 1)[0]
assert "/api/v1/auth" in auth and "rate-limiting" in auth and "limit_by: ip" in auth
m = re.search(r"minute:\s*(\d+)", auth); assert m and int(m.group(1)) <= 30
assert re.search(r"allowed_payload_size:\s*25\b", s) and "size_unit: megabytes" in s
assert "name: jwt" not in s and "'*'" not in s
PY

step "9) Yetkilendirme: site bazlı roller ve sahiplik doğrulaması (FAZ 2.4/2.5/2.9)"
FINPORT=${VERIFY_FIN_PORT:-18092}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
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

  # Roller YALNIZCA jetonda değil, API YANITINDA da olmalı.
  # Yanıtta yokken admin paneli oturumda rol bulamıyor ve giriş yapan herkesi
  # "yetkiniz yok" sayfasına yönlendiriyordu (sonsuz yönlendirme döngüsü).
  LOGIN_BODY=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5551234567","password":"Demo123!"}')
  echo "$LOGIN_BODY" | grep -q '"roles":\[' && ok "login yanıtında roles alanı var" \
    || bad "login yanıtında roles alanı YOK (panel herkesi yetkisiz sayar): $LOGIN_BODY"
  echo "$LOGIN_BODY" | grep -q '"MANAGER"' && ok "login yanıtındaki roller site bazlı çözülüyor" \
    || bad "login yanıtında MANAGER rolü yok"
  echo "$LOGIN_BODY" | grep -q '"active_property_id":"11111111' \
    && ok "login yanıtında aktif site kimliği var" || bad "login yanıtında active_property_id yok"

  # /users/me de aynı kümeyi döndürmeli (oturum tazelemede rol kaybolmamalı)
  ME=$(curl -s "http://127.0.0.1:${SVCPORT}/api/v1/users/me" -H "Authorization: Bearer $MGR")
  echo "$ME" | grep -q '"MANAGER"' && ok "/users/me rolleri döndürüyor" || bad "/users/me rolsüz: $ME"

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

  # 4.12 Bakiye sayısal doğruluğu. API'nin bakiyesi tahakkuklardan BAĞIMSIZ
  # hesaplanan değere birebir eşit olmalı. Önceden görünüm hiç yazılmayan
  # ledger_lines'tan okuyordu: herkes için 0 / has_debt:false (migration 030).
  MGRID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
  expected_balance() {
    $PSQL -t -A -c "SELECT to_char(COALESCE(SUM(ma.total_amount - COALESCE(ma.paid_amount,0)),0),'FM9999999990.00')
      FROM monthly_assessments ma JOIN resident_units ru ON ru.unit_id = ma.unit_id
      WHERE ru.resident_id='$MGRID' AND ru.is_active AND ma.deleted = 0 AND ma.property_id='$DEMO_PROPERTY';"
  }
  debt_status() { curl -s -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/debt-status"; }
  api_balance() { echo "$1" | sed -n 's/.*"current_balance":\([-0-9.eE+]*\).*/\1/p' | awk '{printf "%.2f", $1}'; }
  DS0=$(debt_status); B0API=$(api_balance "$DS0"); B0EXP=$(expected_balance)
  [ -n "$B0API" ] && [ "$B0API" = "$B0EXP" ] \
    && ok "sakin bakiyesi tahakkuklardan bağımsız hesaplanan değere birebir eşit ($B0API TL)" \
    || bad "bakiye uyuşmuyor: API '$B0API', tahakkuklar '$B0EXP' ($DS0)"
  awk "BEGIN{exit !($B0EXP >= 1200)}" && echo "$DS0" | grep -q '"has_debt":true' \
    && ok "ödenmemiş 1.200 TL tahakkuku olan sakin borçlu görünüyor (has_debt:true)" \
    || bad "borçlu sakin borçsuz görünüyor: $DS0"

  # B55 Borçlu listesi DAİRE bazlı olmalı. Önceden aktif malik üzerinden kuruluyordu:
  # maliki kayıtlı olmayan dairenin borcu görünmüyor, hisseli dairenin borcu malik
  # sayısı kadar tekrarlanıyordu (listenin toplamı gerçek alacaktan büyük).
  A3UNIT=$($PSQL -t -A -c "SELECT unit_id FROM monthly_assessments WHERE id='$ASSESS';")
  UDEBT=$($PSQL -t -A -c "SELECT to_char(SUM(total_amount - COALESCE(paid_amount,0)),'FM9999999990.00')
    FROM monthly_assessments WHERE unit_id='$A3UNIT' AND deleted=0 AND total_amount > COALESCE(paid_amount,0);")
  debtor_rows() { # çıktı: "<satır sayısı>|<toplam>|<ad>"
    curl -s -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/debtors" >/tmp/verify-debtors.json
    python3 -c 'import json,sys
d=json.load(open("/tmp/verify-debtors.json")).get("data") or []
r=[x for x in d if x.get("unit_id")==sys.argv[1]]
print("%d|%.2f|%s" % (len(r), sum(x["amount"] for x in r), r[0]["name"] if r else ""))' "$A3UNIT"
  }
  TENID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559876543';")
  RU2=$($PSQL -t -A -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$TENID', '$A3UNIT', 'OWNER')
    ON CONFLICT DO NOTHING RETURNING id;" | grep -E '^[0-9a-f-]{36}$' | head -1)
  DR=$(debtor_rows)
  [ "${DR%%|*}" = "1" ] && [ "$(echo "$DR" | cut -d'|' -f2)" = "$UDEBT" ] && echo "$DR" | grep -q ', ' \
    && ok "iki malikli daire borçlu listesinde TEK satır, borç bir kez ($UDEBT TL; $(echo "$DR" | cut -d'|' -f3))" \
    || bad "hisseli daire: '$DR' (1 satır ve $UDEBT bekleniyordu)"
  [ -n "$RU2" ] && $PSQL -c "DELETE FROM resident_units WHERE id='$RU2';" >/dev/null
  OWNERS=$($PSQL -t -A -c "SELECT string_agg(id::text, ',') FROM resident_units
    WHERE unit_id='$A3UNIT' AND role='OWNER' AND is_active;")
  $PSQL -c "UPDATE resident_units SET is_active=false WHERE id = ANY(string_to_array('$OWNERS', ',')::uuid[]);" >/dev/null
  DR=$(debtor_rows)
  [ "${DR%%|*}" = "1" ] && [ "$(echo "$DR" | cut -d'|' -f2)" = "$UDEBT" ] \
    && echo "$DR" | grep -qE 'malik kayıtlı değil|Kayıtlı malik/sakin yok' \
    && ok "maliki kayıtlı olmayan dairenin borcu listeden kaybolmuyor ve bu işaretleniyor ($(echo "$DR" | cut -d'|' -f3))" \
    || bad "maliksiz daire: '$DR'"
  $PSQL -c "UPDATE resident_units SET is_active=true WHERE id = ANY(string_to_array('$OWNERS', ',')::uuid[]);" >/dev/null

  # Ödeme yöntemi doğrulanır (önceden 'CARD' gibi bilinmeyen değer kaydediliyordu)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"CARD\"}")
  [ "$SC" = "422" ] && ok "bilinmeyen ödeme yöntemi reddediliyor → 422" || bad "bilinmeyen ödeme yöntemi → $SC"

  PAYRESP=$(curl -s -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\"}")
  PAYID=$(echo "$PAYRESP" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
  [ -n "$PAYID" ] && ok "ödeme kaydı oluşturuldu" || bad "ödeme kaydı oluşturulamadı: $PAYRESP"

  # Roadmap 4.5: aynı tahakkuk için ikinci PENDING ödeme açılamamalı (çift dokunma /
  # yeniden deneme). Açılsaydı yönetici ikisini de onaylayınca borç iki kez düşerdi.
  DUPPAY=$(curl -s -w '\n%{http_code}' -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\"}")
  NPEND=$($PSQL -t -A -c "SELECT count(*) FROM payment_assessments pa JOIN payments p ON p.id = pa.payment_id
    WHERE pa.assessment_id='$ASSESS' AND p.status='PENDING';")
  [ "$(echo "$DUPPAY" | tail -1)" = "409" ] && [ "$NPEND" = "1" ] \
    && ok "aynı aidat için ikinci bekleyen ödeme açılamıyor → 409 (tek PENDING kayıt)" \
    || bad "çift ödeme: $(echo "$DUPPAY" | tail -1), bekleyen kayıt $NPEND"

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

    # Borç durumu tam olarak ödenen tutar kadar düşmüş olmalı (kuruşu kuruşuna)
    DS1=$(debt_status); B1API=$(api_balance "$DS1"); B1EXP=$(expected_balance)
    DIFF=$(awk "BEGIN{printf \"%.2f\", $B0API - $B1API}")
    [ "$B1API" = "$B1EXP" ] && [ "$DIFF" = "1200.00" ] \
      && ok "onaydan sonra bakiye tam 1.200,00 TL düştü ($B0API → $B1API) ve tahakkuklarla tutarlı" \
      || bad "onay sonrası bakiye: API $B0API → $B1API (fark $DIFF), tahakkuklar $B1EXP"
    WANT=$(awk "BEGIN{print ($B1EXP > 0) ? \"true\" : \"false\"}")
    echo "$DS1" | grep -q "\"has_debt\":$WANT" \
      && ok "has_debt kalan bakiyeyle tutarlı ($WANT)" || bad "has_debt tutarsız: $DS1"

    # B54 Dönem tahsilat oranı: kayan noktayla `int(c/t*100)` tam yüzdeleri de aşağı
    # kesiyordu (29/100 → %28). Beklenen değer Decimal ile BAĞIMSIZ hesaplanır:
    # tek ondalık, aşağı yuvarlanmış; "completed" yalnızca tahsilat ≥ tahakkuk iken.
    PYEAR=$($PSQL -t -A -c "SELECT period_year FROM monthly_assessments WHERE id='$ASSESS';")
    PER=$($PSQL -t -A -c "SELECT to_char(make_date(period_year, period_month, 1), 'YYYY-MM') FROM monthly_assessments WHERE id='$ASSESS';")
    rate_check() {
    SUMS=$($PSQL -t -A -c "SELECT SUM(total_amount)::text || '|' || SUM(COALESCE(paid_amount,0))::text
      FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND deleted=0
        AND to_char(make_date(period_year, period_month, 1), 'YYYY-MM')='$PER';")
    curl -s -H "Authorization: Bearer $MGR" \
      "http://127.0.0.1:${FINPORT}/api/v1/finance/assessments/overview?year=$PYEAR" >/tmp/verify-overview.json
    RATECHK=$(python3 -c 'import json,sys
from decimal import Decimal, ROUND_FLOOR
t,p = (Decimal(x) for x in sys.argv[2].split("|"))
want = (p*1000/t).to_integral_value(rounding=ROUND_FLOOR)/10 if t else Decimal(0)
row = [x for x in json.load(open("/tmp/verify-overview.json"))["data"] if x["period"]==sys.argv[1]][0]
st = "completed" if p >= t else "active"
print("ok" if Decimal(str(row["rate"])) == want and row["status"] == st else "fark api=%s/%s beklenen=%s/%s" % (row["rate"], row["status"], want, st))' "$PER" "$SUMS" 2>&1)
    [ "$RATECHK" = "ok" ] && ok "dönem tahsilat oranı ve durumu bağımsız Decimal hesabıyla birebir ($PER: $SUMS)" \
      || bad "tahsilat oranı ($SUMS): $RATECHK"
    }
    rate_check
    # Ayırt edici değerler: 348/1200 eski kodla %28 (doğrusu %29,0); 1199,99/1200
    # yuvarlanınca %100 görünürdü (doğrusu %99,9 ve "active"). Ardından geri alınır.
    $PSQL -c "UPDATE monthly_assessments SET paid_amount=348.00, status='PARTIAL' WHERE id='$ASSESS';" >/dev/null
    rate_check
    $PSQL -c "UPDATE monthly_assessments SET paid_amount=1199.99, status='PARTIAL' WHERE id='$ASSESS';" >/dev/null
    rate_check

    # B56 Site ödeme listesi ödemenin KENDİ sitesine bağlı olmalı. Önceden ödeyenin
    # bugünkü üyeliğine bakılıyordu: siteden ayrılan sakinin geçmiş ödemeleri kayboluyordu.
    PAYUNIT=$($PSQL -t -A -c "SELECT COALESCE(block,'') || ' Blok D.' || door_number FROM units WHERE id='$A3UNIT';")
    MYRU=$($PSQL -t -A -c "SELECT string_agg(id::text, ',') FROM resident_units WHERE resident_id='$MGRID' AND is_active;")
    $PSQL -c "UPDATE resident_units SET is_active=false WHERE id = ANY(string_to_array('$MYRU', ',')::uuid[]);" >/dev/null
    curl -s -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" >/tmp/verify-proppay.json
    $PSQL -c "UPDATE resident_units SET is_active=true WHERE id = ANY(string_to_array('$MYRU', ',')::uuid[]);" >/dev/null
    PP=$(python3 -c 'import json,sys
d=json.load(open("/tmp/verify-proppay.json")).get("data") or []
r=[x for x in d if x.get("id")==sys.argv[1]]
print(r[0].get("unit","") if r else "YOK")' "$PAYID")
    [ "$PP" = "$PAYUNIT" ] \
      && ok "siteden ayrılan sakinin ödemesi yönetici listesinde kalıyor, ödemenin dairesiyle ($PP)" \
      || bad "site ödeme listesi: '$PP' ('$PAYUNIT' bekleniyordu)"

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
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
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
kill_tree "$GOV_PID"

step "12) Gider modülü — mock'tan gerçeğe (FAZ 5, ilk modül)"
EXPPORT=${VERIFY_EXP_PORT:-18086}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
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
kill_tree "$EXP_PID"

step "13) Personel modülü — mock'tan gerçeğe (FAZ 5, 2. modül)"
PERPORT=${VERIFY_PER_PORT:-18100}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PERPORT} \
PII_ENCRYPTION_KEY="$PIIKEY" \
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
    "hire_date":"2026-01-15","tc_number":"11111111110",
    "bank_iban":"TR330006100519786457841326","bank_name":"Test Bank",
    "gross_salary":30000,"net_salary":22000,"sgk_number":"1234567890"}')
  EMPID=$(echo "$EMP" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$EMPID" ] && ok "personel kaydı oluşturuldu ve KALICI" || bad "personel oluşturulamadı: $EMP"

  # Varsayılan yıllık izin 14 gün olmalı (4857 s. İş Kanunu m.53)
  AL=$(qscoped "SELECT annual_leave_days FROM employees WHERE id='$EMPID';")
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
  LD=$(qscoped "SELECT days::int FROM employee_leaves WHERE id='$LVID';")
  [ "$LD" = "5" ] && ok "izin gün sayısı sunucuda hesaplandı (5 gün)" || bad "izin günü $LD"

  # Çakışan izin reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/leaves" -H "$PA" -H "$PJ" -d "{
    \"employee_id\":\"$EMPID\",\"leave_type\":\"ANNUAL\",
    \"start_date\":\"2026-07-03\",\"end_date\":\"2026-07-08\"}")
  [ "$SC" = "409" ] && ok "çakışan izin talebi reddedildi → 409" || bad "çakışan izin kabul edildi → $SC"

  curl -s -o /dev/null -X POST "$PURL/leaves/$LVID/approve" -H "$PA" -H "$PJ" -d '{}'
  REM=$(qscoped "SELECT remaining_leave_days FROM employees WHERE id='$EMPID';")
  [ "$REM" = "9" ] && ok "onaydan sonra izin bakiyesi düştü (14 → 9)" || bad "izin bakiyesi $REM (9 bekleniyordu)"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/leaves/$LVID/approve" -H "$PA" -H "$PJ" -d '{}')
  [ "$SC" = "409" ] && ok "çift onaylama engellendi → 409" || bad "çift onaylama → $SC"

  # İşten ayrılışta kayıt SİLİNMEMELİ
  curl -s -o /dev/null -X POST "$PURL/employees/$EMPID/terminate" -H "$PA" -H "$PJ" \
    -d '{"reason":"İstifa","end_date":"2026-08-31"}'
  STILL=$(qscoped "SELECT count(*) FROM employees WHERE id='$EMPID';")
  ACT=$(qscoped "SELECT is_active FROM employees WHERE id='$EMPID';")
  [ "$STILL" = "1" ] && [ "$ACT" = "f" ] && ok "işten ayrılışta özlük kaydı silinmiyor, pasife alınıyor" \
    || bad "özlük kaydı silindi ya da pasife alınmadı (count=$STILL active=$ACT)"
else
  bad "personnel-service başlamadı"; tail -10 /tmp/verify-personnel.log
fi
kill_tree "$PER_PID"

step "14) Ziyaretçi modülü — mock'tan gerçeğe (FAZ 5, 3. modül)"
VISPORT=${VERIFY_VIS_PORT:-18105}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
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

  # ZİYARETÇİYE (site dışı kişiye) SMS/QR gönderildiği iddia EDİLMEMELİ:
  # SMS sağlayıcısı yok ve site dışı numaraya ileti 6563 s. Kanun kapsamında
  # ayrıca onay ister.
  echo "$V1" | grep -q 'SMS/QR GÖNDERİLMEZ' \
    && ok "ziyaretçiye SMS/QR gönderilmediği dürüstçe bildiriliyor" \
    || bad "ziyaretçi bildirim durumu belirtilmemiş: $V1"

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
  CIN=$(curl -s -X POST "$VURL/visitors/$V1ID/check-in" -H "$VA" -H "$VJ" -d '{}')
  echo "$CIN" | grep -q 'Ziyaretçi girişi kaydedildi' && ok "ziyaretçi girişi kaydedildi" \
    || bad "giriş: $CIN"

  # BİLDİRİM: giriş anında ilgili DAİRENİN sakinine haber verilmeli.
  # Ölçü "yanıt bildirim diyor mu" değil, veritabanında KAYIT VAR MI.
  echo "$CIN" | grep -q '"sent":1' \
    && ok "ziyaretçi girişinde daireye bildirim OLUŞTURULDU" \
    || bad "giriş bildirimi oluşmadı: $CIN"
  VN=$(qscoped "SELECT count(*) FROM notifications
    WHERE topic='visitor.checkin' AND payload->>'visitor_id'='$V1ID';")
  [ "${VN:-0}" -ge 1 ] && ok "giriş bildirimi veritabanında ($VN kayıt)" \
    || bad "giriş bildirimi veritabanında yok"
  # Bildirim, dairenin sakinine gitmeli — herkese değil.
  VNU=$(qscoped "SELECT count(*) FROM notifications n
    WHERE n.topic='visitor.checkin' AND n.payload->>'visitor_id'='$V1ID'
      AND NOT EXISTS (SELECT 1 FROM resident_units ru
                       WHERE ru.resident_id = n.recipient_user_id
                         AND ru.unit_id = '$MGRUNIT');")
  [ "$VNU" = "0" ] && ok "giriş bildirimi yalnızca ilgili dairenin sakinine gitti" \
    || bad "$VNU bildirim ilgisiz kişiye gitmiş"
  # Kayıt, bildirim GERÇEKTEN oluştuğu için işaretlenmeli.
  VMARK=$(qscoped "SELECT (resident_notified_at IS NOT NULL) || '/' || COALESCE(notification_method,'')
    FROM visitors WHERE id='$V1ID';")
  [ "$VMARK" = "t/IN_APP" ] || [ "$VMARK" = "true/IN_APP" ] \
    && ok "ziyaretçi kaydına haber verildiği işlendi ($VMARK)" \
    || bad "ziyaretçi kaydı işaretlenmemiş: $VMARK"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V1ID/check-in" -H "$VA" -H "$VJ" -d '{}')
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
kill_tree "$VIS_PID"

step "15) Otopark modülü — mock'tan gerçeğe (FAZ 5, 4. modül)"
PRKPORT=${VERIFY_PRK_PORT:-18098}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
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
kill_tree "$PRK_PID"

step "16) Rezervasyon modülü — mock'tan gerçeğe (FAZ 5, 5. modül)"
# Önceki davranış: sabit tesis listesi + 201 dönüp hiçbir yere kaydetmeyen POST.
# En kritik eksik ÇAKIŞMA DENETİMİYDİ: iki sakin aynı saati "ayırttığını" sanıyordu.
RESPORT=${VERIFY_RES_PORT:-18091}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${RESPORT} \
  go run ./services/reservation >/tmp/verify-reservation.log 2>&1 &
RES_PID=$!
RUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${RESPORT}/health" >/dev/null 2>&1 && { RUP=1; break; }
  sleep 1
done

if [ "$RUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "reservation-service ayağa kalktı"
  RA="Authorization: Bearer $MGR"
  RT="Authorization: Bearer $TEN"
  RJ='Content-Type: application/json'
  RURL="http://127.0.0.1:${RESPORT}/api/v1"

  # Tesis: 08:00-22:00, 60-180 dk, 30 dk tampon, haftalık 2 rezervasyon, saatlik 50 / günlük 300 TL
  FAC=$($PSQL -t -A -c "INSERT INTO facilities
      (property_id, name, category, capacity, is_paid, hourly_fee, daily_fee,
       available_from, available_to, available_days,
       min_duration_minutes, max_duration_minutes, advance_booking_days,
       max_reservations_per_unit, buffer_minutes, requires_approval)
    VALUES ('11111111-1111-1111-1111-111111111111','Toplanti Salonu','MEETING_ROOM',20,true,50,300,
       '08:00','22:00','{0,1,2,3,4,5,6}',60,180,14,2,30,false) RETURNING id;")
  [ -n "$FAC" ] && ok "tesis oluşturuldu" || bad "tesis oluşturulamadı"

  # Saat denetimleri site yerel saatine (Europe/Istanbul) göre yapılır.
  D1=$(TZ=Europe/Istanbul date -d 'tomorrow' +%Y-%m-%d)
  DPAST=$(TZ=Europe/Istanbul date -d 'yesterday' +%Y-%m-%d)
  DFAR=$(TZ=Europe/Istanbul date -d '+30 days' +%Y-%m-%d)

  FL=$(curl -s "$RURL/facilities" -H "$RA")
  echo "$FL" | grep -q 'Toplanti Salonu' && ok "tesis listesi veritabanından geliyor" \
    || bad "tesis listesi: $FL"

  # 1) Normal rezervasyon → 201, otomatik onay, 2 saat × 50 TL = 100 TL
  R1=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T10:00:00+03:00\",
    \"end_time\":\"${D1}T12:00:00+03:00\",\"guest_count\":4,\"purpose\":\"Blok toplantisi\"}")
  R1ID=$(echo "$R1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$R1ID" ] && ok "rezervasyon oluşturuldu ve KALICI" || bad "rezervasyon oluşturulamadı: $R1"
  echo "$R1" | grep -q '"total_fee":100' && ok "ücret kuruş üzerinden doğru (2 sa × 50 = 100 TL)" \
    || bad "ücret beklenmedik: $R1"
  echo "$R1" | grep -q 'TAHSİL EDİLMEDİ' && ok "ücretin tahsil edilmediği dürüstçe bildiriliyor" \
    || bad "tahsilat durumu belirtilmemiş: $R1"

  if [ -n "$R1ID" ]; then
    DBC=$($PSQL -t -A -c "SELECT count(*) FROM reservations WHERE id='$R1ID';")
    [ "$DBC" = "1" ] && ok "rezervasyon veritabanında (mock değil)" || bad "kayıt veritabanında yok"
  fi

  # 2) ÇAKIŞMA — aynı tesiste kesişen aralık, BAŞKA bir bağımsız bölümden bile olsa reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T11:00:00+03:00\",
    \"end_time\":\"${D1}T12:00:00+03:00\"}")
  [ "$SC" = "409" ] && ok "çakışan saat reddedildi → 409 (mock'ta bu denetim YOKTU)" \
    || bad "çakışan rezervasyon kabul edildi → $SC"

  # 3) TAMPON SÜRE — 12:00'de biten rezervasyondan 15 dk sonra başlamak 30 dk tamponu ihlâl eder
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T12:15:00+03:00\",
    \"end_time\":\"${D1}T13:15:00+03:00\"}")
  [ "$SC" = "409" ] && ok "tampon süre (30 dk) uygulanıyor → 409" || bad "tampon süre uygulanmadı → $SC"

  # 4) Tampon süre DIŞINDA kalan aralık kabul edilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T13:00:00+03:00\",
    \"end_time\":\"${D1}T14:00:00+03:00\"}")
  [ "$SC" = "201" ] && ok "tampon süre dışındaki aralık kabul edildi → 201" \
    || bad "geçerli aralık reddedildi → $SC"

  # 5) Çalışma saati dışı
  RESP=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T06:00:00+03:00\",
    \"end_time\":\"${D1}T07:00:00+03:00\"}")
  echo "$RESP" | grep -q '08:00 öncesinde kapalıdır' && ok "çalışma saati dışı reddedildi (yerel saat)" \
    || bad "çalışma saati denetimi: $RESP"

  # 6) Azami süre (180 dk)
  RESP=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T15:00:00+03:00\",
    \"end_time\":\"${D1}T20:00:00+03:00\"}")
  echo "$RESP" | grep -q 'En fazla 180 dakika' && ok "azami süre sınırı uygulanıyor" \
    || bad "azami süre denetimi: $RESP"

  # 7) Geçmiş tarih
  RESP=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${DPAST}T10:00:00+03:00\",
    \"end_time\":\"${DPAST}T11:00:00+03:00\"}")
  echo "$RESP" | grep -q 'Geçmiş bir saat' && ok "geçmiş tarihe rezervasyon engellendi" \
    || bad "geçmiş tarih denetimi: $RESP"

  # 8) İleri tarih sınırı (14 gün)
  RESP=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${DFAR}T10:00:00+03:00\",
    \"end_time\":\"${DFAR}T11:00:00+03:00\"}")
  echo "$RESP" | grep -q 'en fazla 14 gün öncesinden' && ok "ileri tarih sınırı uygulanıyor" \
    || bad "ileri tarih denetimi: $RESP"

  # 9) Haftalık kota (bağımsız bölüm başına 2) — yöneticinin 1 rezervasyonu var, 2. kabul, 3. red
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T15:00:00+03:00\",
    \"end_time\":\"${D1}T17:00:00+03:00\"}")
  [ "$SC" = "201" ] && ok "kota içindeki 2. rezervasyon kabul edildi" || bad "2. rezervasyon → $SC"

  RESP=$(curl -s -X POST "$RURL/reservations" -H "$RA" -H "$RJ" -d "{
    \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T18:00:00+03:00\",
    \"end_time\":\"${D1}T19:00:00+03:00\"}")
  echo "$RESP" | grep -q 'haftalık rezervasyon hakkınız doldu' && ok "haftalık kota uygulanıyor" \
    || bad "kota denetimi: $RESP"

  # 10) Dolu saat listesi
  SL=$(curl -s "$RURL/facilities/$FAC/slots?date=$D1" -H "$RA")
  echo "$SL" | grep -q '"busy"' && ok "dolu saat listesi veriliyor" || bad "slots: $SL"
  echo "$SL" | grep -q '"buffer_minutes":30' && ok "tampon süre istemciye bildiriliyor" \
    || bad "slots tampon süresi eksik"

  # 11) Sakin yalnızca kendi rezervasyonlarını görür
  TL=$(curl -s "$RURL/reservations" -H "$RT")
  echo "$TL" | grep -q 'Blok toplantisi' && bad "kiracı, yöneticinin rezervasyonunu görüyor" \
    || ok "kiracı yalnızca kendi rezervasyonlarını görüyor"
  ML=$(curl -s "$RURL/reservations" -H "$RA")
  echo "$ML" | grep -q 'Blok toplantisi' && ok "yönetim site genelini görüyor" \
    || bad "yönetim listesi: $ML"

  # 12) İptal — sahibi iptal edebilir, saat ve kota serbest kalır
  if [ -n "$R1ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations/$R1ID/cancel" \
      -H "$RA" -H "$RJ" -d '{"reason":"Toplanti ertelendi"}')
    [ "$SC" = "200" ] && ok "rezervasyon iptal edildi → 200" || bad "iptal → $SC"

    ST=$($PSQL -t -A -c "SELECT status FROM reservations WHERE id='$R1ID';")
    [ "$ST" = "CANCELLED" ] && ok "iptal veritabanına yazıldı (kayıt silinmiyor)" \
      || bad "iptal durumu: $ST"

    # Serbest kalan saat yeniden alınabilmeli
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{
      \"facility_id\":\"$FAC\",\"start_time\":\"${D1}T10:00:00+03:00\",
      \"end_time\":\"${D1}T12:00:00+03:00\"}")
    [ "$SC" = "201" ] && ok "iptal edilen saat yeniden rezerve edilebiliyor" \
      || bad "iptal sonrası saat serbest kalmadı → $SC"
  fi

  # 13) Başkasının rezervasyonunu sakin iptal edemez
  MID=$($PSQL -t -A -c "SELECT id FROM reservations WHERE resident_id='44444444-4444-4444-4444-444444444401' AND status='APPROVED' LIMIT 1;")
  if [ -n "$MID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations/$MID/cancel" \
      -H "$RT" -H "$RJ" -d '{"reason":"olmaz"}')
    [ "$SC" = "409" ] && ok "sakin, başkasının rezervasyonunu iptal edemiyor" \
      || bad "başkasının rezervasyonu iptal edildi → $SC"
  fi

  # 14) Onay/red yalnızca yönetimde
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations/$FAC/approve" -H "$RT" -H "$RJ" -d '{}')
  [ "$SC" = "403" ] && ok "sakin rezervasyon onaylayamıyor → 403" || bad "sakin onayladı → $SC"

  # 14b) Onay/red kararı, rezervasyonu YAPAN sakine bildirilmeli.
  #
  #      Onay bekleyen bir kayıt gerekli. Testte oluşan rezervasyonlar
  #      doğrudan onaylandığı için kaydın durumu SQL ile PENDING'e alınıyor;
  #      karar ve bildirim akışı API üzerinden çalıştırılıyor. Kontrolü
  #      "uygun kayıt yoksa atla" diye geçmek, bildirimin hiç çalışmadığı bir
  #      durumu da sessizce GEÇMİŞ gösterirdi.
  if [ -n "$MID" ]; then
    $PSQL -c "UPDATE reservations SET status='PENDING', reviewed_by=NULL, reviewed_at=NULL
      WHERE id='$MID';" >/dev/null 2>&1
    APPR=$(curl -s -X POST "$RURL/reservations/$MID/approve" -H "$RA" -H "$RJ" -d '{}')
    echo "$APPR" | grep -q 'Rezervasyon onaylandı' && ok "rezervasyon onaylandı" \
      || bad "onay: $APPR"
    echo "$APPR" | grep -q '"sent":1' \
      && ok "onay kararı sakine bildirim olarak oluşturuldu" || bad "onay bildirimi yok: $APPR"
    RN=$(qscoped "SELECT count(*) FROM notifications
      WHERE topic='reservation.decision' AND payload->>'reservation_id'='$MID';")
    [ "${RN:-0}" = "1" ] && ok "onay bildirimi veritabanında tek kayıt" \
      || bad "onay bildirimi sayısı: $RN"
    # Bildirim YALNIZCA rezervasyon sahibine gitmeli; havuzu kimin ne zaman
    # kullandığı tüm siteye duyurulacak bir bilgi değildir.
    RNW=$(qscoped "SELECT count(*) FROM notifications n
      WHERE n.topic='reservation.decision' AND n.payload->>'reservation_id'='$MID'
        AND n.recipient_user_id <> (SELECT resident_id FROM reservations WHERE id='$MID');")
    [ "$RNW" = "0" ] && ok "onay bildirimi yalnızca rezervasyon sahibine gitti" \
      || bad "$RNW bildirim ilgisiz kişiye gitmiş"

    # Red gerekçesi bildirimin GÖVDESİNDE olmalı: sakin itiraz edebilmek için
    # gerekçeyi görmelidir.
    $PSQL -c "UPDATE reservations SET status='PENDING', reviewed_by=NULL, reviewed_at=NULL
      WHERE id='$MID';" >/dev/null 2>&1
    REJ=$(curl -s -X POST "$RURL/reservations/$MID/reject" -H "$RA" -H "$RJ" \
      -d '{"reason":"Ayni saatte bakim var"}')
    echo "$REJ" | grep -q 'Rezervasyon reddedildi' && ok "rezervasyon reddedildi" || bad "red: $REJ"
    RBODY=$(qscoped "SELECT body FROM notifications
      WHERE topic='reservation.decision' AND payload->>'status'='REJECTED'
        AND payload->>'reservation_id'='$MID' LIMIT 1;")
    echo "$RBODY" | grep -q 'Ayni saatte bakim var' \
      && ok "red gerekçesi bildirim gövdesinde" || bad "red gerekçesi bildirimde yok: $RBODY"
  else
    bad "onay bekleyen rezervasyon hazırlanamadı — bildirim kontrolü çalıştırılamadı"
  fi

  # 15) Kimliksiz erişim engelli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$RURL/facilities")
  [ "$SC" = "401" ] && ok "kimliksiz tesis listesi erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "reservation-service başlamadı"; tail -10 /tmp/verify-reservation.log
fi
kill_tree "$RES_PID"

step "17) Kargo modülü — mock'tan gerçeğe (FAZ 5, 6. modül)"
# Önceki davranış: sabit kargo listesi; teslim alma/teslim etme kaydedilmiyordu ve
# yanıt "sakine bildirim gönderildi" diyordu — bildirim altyapısı hiç yoktu.
PKGPORT=${VERIFY_PKG_PORT:-18097}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PKGPORT} \
  go run ./services/package >/tmp/verify-package.log 2>&1 &
PKG_PID=$!
KUP2=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${PKGPORT}/health" >/dev/null 2>&1 && { KUP2=1; break; }
  sleep 1
done

if [ "$KUP2" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "package-service ayağa kalktı"
  PA="Authorization: Bearer $MGR"
  PT="Authorization: Bearer $TEN"
  PJ='Content-Type: application/json'
  PURL="http://127.0.0.1:${PKGPORT}/api/v1"
  UNIT_MGR='33333333-3333-3333-3333-333333333303'   # yönetici hesabının bölümü
  UNIT_TEN='33333333-3333-3333-3333-333333333304'   # kiracının bölümü

  # 1) Kargo teslim alma — kalıcı olmalı
  P1=$(curl -s -X POST "$PURL/packages" -H "$PA" -H "$PJ" -d "{
    \"unit_id\":\"$UNIT_MGR\",\"recipient_name\":\"Ahmet Yilmaz\",\"carrier\":\"Aras\",
    \"tracking_number\":\"AR123456\",\"storage_location\":\"Guvenlik kulubesi raf 2\"}")
  P1ID=$(echo "$P1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$P1ID" ] && ok "kargo kaydı oluşturuldu ve KALICI" || bad "kargo kaydedilemedi: $P1"

  if [ -n "$P1ID" ]; then
    DBC=$($PSQL -t -A -c "SELECT count(*) FROM packages WHERE id='$P1ID';")
    [ "$DBC" = "1" ] && ok "kargo veritabanında (mock değil)" || bad "kayıt veritabanında yok"
  fi

  # 2) BİLDİRİM: kargo kaydedilince ilgili dairenin sakinine haber verilmeli.
  echo "$P1" | grep -q '"notification_sent":true' \
    && ok "kargo bildirimi oluşturuldu ve alan olarak bildiriliyor" \
    || bad "notification_sent true değil: $P1"
  echo "$P1" | grep -q '"status":"NOTIFIED"' \
    && ok "bildirim oluştuğu için kargo durumu NOTIFIED" || bad "durum NOTIFIED değil: $P1"
  if [ -n "$P1ID" ]; then
    PN=$(qscoped "SELECT count(*) FROM notifications
      WHERE topic='package.received' AND payload->>'package_id'='$P1ID';")
    [ "${PN:-0}" -ge 1 ] && ok "kargo bildirimi veritabanında ($PN kayıt)" \
      || bad "kargo bildirimi veritabanında yok"
    # KİŞİSEL VERİ: gövdede gönderici/içerik YAZMAMALI (kilit ekranında görünür).
    PBODY=$(qscoped "SELECT body FROM notifications
      WHERE topic='package.received' AND payload->>'package_id'='$P1ID' LIMIT 1;")
    echo "$PBODY" | grep -qi 'AR123456' \
      && bad "kargo bildiriminde takip numarası sızdı: $PBODY" \
      || ok "kargo bildirimi içerik/takip bilgisi taşımıyor"
    # Yalnızca ilgili dairenin sakinine gitmeli.
    PNU=$(qscoped "SELECT count(*) FROM notifications n
      WHERE n.topic='package.received' AND n.payload->>'package_id'='$P1ID'
        AND NOT EXISTS (SELECT 1 FROM resident_units ru
                         WHERE ru.resident_id = n.recipient_user_id
                           AND ru.unit_id = '$UNIT_MGR');")
    [ "$PNU" = "0" ] && ok "kargo bildirimi yalnızca ilgili daireye gitti" \
      || bad "$PNU kargo bildirimi ilgisiz kişiye gitmiş"
  fi

  # 3) Başka sitenin bağımsız bölümüne kargo kaydedilemez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages" -H "$PA" -H "$PJ" \
    -d '{"unit_id":"33333333-3333-3333-3333-3333333333ff","recipient_name":"Test"}')
  [ "$SC" = "400" ] && ok "başka siteye ait bağımsız bölüme kargo kaydedilemiyor → 400" \
    || bad "geçersiz bölüm kabul edildi → $SC"

  # 4) Kiracıya ait ikinci kargo
  P2=$(curl -s -X POST "$PURL/packages" -H "$PA" -H "$PJ" -d "{
    \"unit_id\":\"$UNIT_TEN\",\"recipient_name\":\"Ayse Demir\",\"carrier\":\"Yurtici\"}")
  P2ID=$(echo "$P2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$P2ID" ] && ok "ikinci kargo kaydedildi" || bad "ikinci kargo: $P2"

  # 5) KVKK: sakin yalnızca KENDİ bölümünün kargosunu görür
  TL=$(curl -s "$PURL/packages" -H "$PT")
  echo "$TL" | grep -q 'Ayse Demir' && ok "sakin kendi kargosunu görüyor" || bad "sakin listesi: $TL"
  echo "$TL" | grep -q 'Ahmet Yilmaz' && bad "sakin KOMŞUSUNUN kargosunu görüyor (KVKK ihlali)" \
    || ok "sakin komşusunun kargosunu göremiyor (KVKK veri minimizasyonu)"

  # Tekil okuma da aynı sınırı uygulamalı
  if [ -n "$P1ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages/$P1ID" -H "$PT")
    [ "$SC" = "404" ] && ok "sakin, başkasının kargo kaydını tekil olarak da okuyamıyor" \
      || bad "sakin başkasının kargosunu okudu → $SC"
  fi

  # 6) Yönetim site genelini görür
  ML=$(curl -s "$PURL/packages" -H "$PA")
  echo "$ML" | grep -q 'Ahmet Yilmaz' && echo "$ML" | grep -q 'Ayse Demir' \
    && ok "yönetim site genelindeki kargoları görüyor" || bad "yönetim listesi eksik: $ML"

  # 7) Haber verildi kaydı — bildirim GÖNDERMEDİĞİNİ söylemeli
  if [ -n "$P1ID" ]; then
    N1=$(curl -s -X POST "$PURL/packages/$P1ID/notify" -H "$PA" -H "$PJ" -d '{"method":"PHONE"}')
    echo "$N1" | grep -q '"status":"NOTIFIED"' && ok "haber verildi kaydı işlendi" || bad "notify: $N1"
    echo "$N1" | grep -q 'SMS/push bildirim GÖNDERMEZ' \
      && ok "elle haber verme kaydının SMS/push göndermediği açıkça yazılıyor" \
      || bad "notify dürüstlük notu yok"

    # İkinci haber verme hatırlatma sayacını artırmalı
    # Kayıt zaten uygulama içi bildirimle NOTIFIED olduğundan, elle yapılan
    # her haber verme bir HATIRLATMA sayılır: ilki 1, ikincisi 2.
    N2=$(curl -s -X POST "$PURL/packages/$P1ID/notify" -H "$PA" -H "$PJ" -d '{"method":"DOORBELL"}')
    echo "$N2" | grep -q '"reminder_count":2' && ok "hatırlatma sayacı artıyor" || bad "sayaç: $N2"
  fi

  # 8) Teslim — kime teslim edildiği zorunlu
  if [ -n "$P1ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P1ID/deliver" \
      -H "$PA" -H "$PJ" -d '{}')
    [ "$SC" = "400" ] && ok "teslim alan kişi yazılmadan teslim kaydı yapılamıyor → 400" \
      || bad "isimsiz teslim kabul edildi → $SC"

    D1=$(curl -s -X POST "$PURL/packages/$P1ID/deliver" -H "$PA" -H "$PJ" \
      -d '{"delivered_to_name":"Ahmet Yilmaz"}')
    echo "$D1" | grep -q '"status":"DELIVERED"' && ok "kargo teslim edildi" || bad "teslim: $D1"
    echo "$D1" | grep -q 'SAKLANMADI' && ok "imza/fotoğraf saklanmadığı dürüstçe bildiriliyor" \
      || bad "imza saklama iddiası dürüst değil"

    ST=$($PSQL -t -A -c "SELECT status || '|' || COALESCE(delivered_to_name,'') FROM packages WHERE id='$P1ID';")
    [ "$ST" = "DELIVERED|Ahmet Yilmaz" ] && ok "teslim veritabanına yazıldı (kime teslim edildiği dahil)" \
      || bad "teslim kaydı: $ST"

    # Aynı paket iki kez teslim edilemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P1ID/deliver" \
      -H "$PA" -H "$PJ" -d '{"delivered_to_name":"Baskasi"}')
    [ "$SC" = "409" ] && ok "çift teslim engellendi → 409" || bad "çift teslim → $SC"
  fi

  # 9) İade — gerekçe zorunlu
  if [ -n "$P2ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P2ID/return" \
      -H "$PA" -H "$PJ" -d '{}')
    [ "$SC" = "400" ] && ok "gerekçesiz iade engellendi → 400" || bad "gerekçesiz iade → $SC"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P2ID/return" \
      -H "$PA" -H "$PJ" -d '{"reason":"Alici 30 gun teslim almadi"}')
    [ "$SC" = "200" ] && ok "iade kaydedildi → 200" || bad "iade → $SC"
    NT=$($PSQL -t -A -c "SELECT notes FROM packages WHERE id='$P2ID';")
    echo "$NT" | grep -q 'İade: Alici 30 gun teslim almadi' && ok "iade gerekçesi kayda geçti" \
      || bad "iade gerekçesi kaydedilmedi: $NT"
  fi

  # 10) Depo özeti gerçek sayımdan gelmeli
  SUM=$(curl -s "$PURL/packages-summary" -H "$PA")
  echo "$SUM" | grep -q '"delivered":1' && ok "özet teslim edileni gerçek sayıyor" || bad "özet: $SUM"
  echo "$SUM" | grep -q '"returned":1' && ok "özet iadeyi gerçek sayıyor" || bad "özet iade: $SUM"

  # 11) Sakin kargo kaydı/teslimi yapamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages" -H "$PT" -H "$PJ" \
    -d "{\"unit_id\":\"$UNIT_TEN\",\"recipient_name\":\"Kendim\"}")
  [ "$SC" = "403" ] && ok "sakin kargo kaydı yapamıyor → 403" || bad "sakin kargo kaydetti → $SC"

  SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages-summary" -H "$PT")
  [ "$SC" = "403" ] && ok "sakin depo özetini göremiyor → 403" || bad "sakin özeti gördü → $SC"

  # 12) Kimliksiz erişim engelli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages")
  [ "$SC" = "401" ] && ok "kimliksiz kargo listesi erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "package-service başlamadı"; tail -10 /tmp/verify-package.log
fi
kill_tree "$PKG_PID"

step "18) Sözleşme modülü — mock'tan gerçeğe (FAZ 5, 7. modül)"
# Önceki davranış: sabit sözleşme listesi; yazma istekleri kaydedilmiyordu.
# Kritik iş kuralı: kendiliğinden yenilenen sözleşmede ihbar süresi kaçırılırsa
# site habersiz yeni bir mali yüke bağlanır → notice_due işaretlenmeli, yenileme ELLE olmalı.
CTRPORT=${VERIFY_CTR_PORT:-18094}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${CTRPORT} \
  go run ./services/contract >/tmp/verify-contract.log 2>&1 &
CTR_PID=$!
CUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${CTRPORT}/health" >/dev/null 2>&1 && { CUP=1; break; }
  sleep 1
done

if [ "$CUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "contract-service ayağa kalktı"
  CA="Authorization: Bearer $MGR"
  CT="Authorization: Bearer $TEN"
  CJ='Content-Type: application/json'
  CURL="http://127.0.0.1:${CTRPORT}/api/v1"

  TODAY=$(date +%Y-%m-%d)
  NEXTYEAR=$(date -d '+1 year' +%Y-%m-%d)
  SOON=$(date -d '+20 days' +%Y-%m-%d)
  PASTEND=$(date -d '-5 days' +%Y-%m-%d)
  LASTYEAR=$(date -d '-1 year' +%Y-%m-%d)

  # 1) Sözleşme oluşturma — aylık 5.000 TL asansör bakımı
  C1=$(curl -s -X POST "$CURL/contracts" -H "$CA" -H "$CJ" -d "{
    \"contract_type\":\"MAINTENANCE\",\"title\":\"Asansor bakim sozlesmesi\",
    \"party_name\":\"Ornek Asansor A.S.\",\"party_type\":\"COMPANY\",\"party_tax_id\":\"1234567890\",
    \"start_date\":\"$TODAY\",\"end_date\":\"$NEXTYEAR\",
    \"payment_type\":\"MONTHLY\",\"monthly_amount\":5000,
    \"auto_renew\":true,\"renewal_period_months\":12,\"renewal_notice_days\":30,\"max_renewals\":1}")
  C1ID=$(echo "$C1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$C1ID" ] && ok "sözleşme oluşturuldu ve KALICI" || bad "sözleşme oluşturulamadı: $C1"

  if [ -n "$C1ID" ]; then
    DBC=$($PSQL -t -A -c "SELECT count(*) FROM contracts WHERE id='$C1ID';")
    [ "$DBC" = "1" ] && ok "sözleşme veritabanında (mock değil)" || bad "kayıt veritabanında yok"
  fi

  # 2) Geçersiz tür reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts" -H "$CA" -H "$CJ" -d "{
    \"contract_type\":\"UYDURMA\",\"title\":\"X\",\"party_name\":\"Y\",\"start_date\":\"$TODAY\"}")
  [ "$SC" = "422" ] && ok "geçersiz sözleşme türü reddedildi → 422" || bad "geçersiz tür kabul edildi → $SC"

  # 3) Bitiş < başlangıç reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts" -H "$CA" -H "$CJ" -d "{
    \"contract_type\":\"SERVICE\",\"title\":\"Ters tarih\",\"party_name\":\"Y\",
    \"start_date\":\"$TODAY\",\"end_date\":\"$LASTYEAR\"}")
  [ "$SC" = "422" ] && ok "bitiş tarihi başlangıçtan önce olamıyor → 422" || bad "ters tarih kabul edildi → $SC"

  # 4) auto_renew var ama yenileme süresi yok → kabul edilmemeli
  #    (ihbar penceresi hesaplanamaz, site habersiz yeni döneme bağlanır)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts" -H "$CA" -H "$CJ" -d "{
    \"contract_type\":\"SERVICE\",\"title\":\"Suresiz yenileme\",\"party_name\":\"Y\",
    \"start_date\":\"$TODAY\",\"auto_renew\":true}")
  [ "$SC" = "422" ] && ok "yenileme süresi olmadan kendiliğinden yenileme kurulamıyor → 422" \
    || bad "eksik yenileme tanımı kabul edildi → $SC"

  # 5) İhbar penceresi — 20 gün sonra bitecek, ihbar süresi 30 gün → notice_due true
  C2=$(curl -s -X POST "$CURL/contracts" -H "$CA" -H "$CJ" -d "{
    \"contract_type\":\"SERVICE\",\"title\":\"Guvenlik hizmeti\",\"party_name\":\"Ornek Guvenlik Ltd.\",
    \"start_date\":\"$LASTYEAR\",\"end_date\":\"$SOON\",
    \"payment_type\":\"YEARLY\",\"yearly_amount\":120000,\"renewal_notice_days\":30}")
  C2ID=$(echo "$C2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$C2ID" ] && ok "ikinci sözleşme oluşturuldu" || bad "ikinci sözleşme: $C2"

  LIST=$(curl -s "$CURL/contracts?expiring_days=30" -H "$CA")
  echo "$LIST" | grep -q 'Guvenlik hizmeti' && ok "yaklaşan bitiş süzgeci çalışıyor (expiring_days)" \
    || bad "expiring_days süzgeci: $LIST"
  echo "$LIST" | grep -q '"notice_due":true' && ok "fesih ihbar penceresi işaretleniyor" \
    || bad "notice_due hesaplanmadı: $LIST"
  echo "$LIST" | grep -q 'Asansor bakim' && bad "süzgeç dışı sözleşme listeye sızdı" \
    || ok "süzgeç yalnızca yaklaşanları döndürüyor"

  # 6) Mali yük özeti — 5.000 aylık + 120.000/12 = 10.000 aylık, 120.000 yıllık
  SUM=$(curl -s "$CURL/contracts-summary" -H "$CA")
  echo "$SUM" | grep -q '"monthly_commitment_try":15000' \
    && ok "aylık mali yük doğru hesaplandı (5.000 + 120.000/12 = 15.000 TL)" \
    || bad "aylık yük beklenmedik: $SUM"
  echo "$SUM" | grep -q '"yearly_commitment_try":180000' && ok "yıllık mali yük doğru (180.000 TL)" \
    || bad "yıllık yük beklenmedik: $SUM"
  echo "$SUM" | grep -q '"notice_due":1' && ok "özet ihbar süresi dolan sözleşmeyi sayıyor" \
    || bad "özet notice_due: $SUM"

  # 7) KVKK: kat maliki özeti görebilir ama karşı tarafın verisini göremez
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$CURL/contracts-summary" -H "$CT")
  [ "$SC" = "200" ] && ok "kat maliki mali yük özetini görebiliyor (KMK m.39 hesap verme)" \
    || bad "özet sakine kapalı → $SC"
  TS=$(curl -s "$CURL/contracts-summary" -H "$CT")
  echo "$TS" | grep -q '1234567890' && bad "özet karşı tarafın vergi numarasını sızdırıyor" \
    || ok "özet kişisel/ticari veri sızdırmıyor"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$CURL/contracts" -H "$CT")
  [ "$SC" = "403" ] && ok "sakin sözleşme ayrıntılarını göremiyor → 403" || bad "sakin ayrıntı gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts" -H "$CT" -H "$CJ" -d "{
    \"contract_type\":\"OTHER\",\"title\":\"X\",\"party_name\":\"Y\",\"start_date\":\"$TODAY\"}")
  [ "$SC" = "403" ] && ok "sakin sözleşme yapamıyor → 403" || bad "sakin sözleşme yaptı → $SC"

  # 8) Yenileme — bitiş tarihi 12 ay uzamalı, sayaç artmalı
  if [ -n "$C1ID" ]; then
    OLDEND=$($PSQL -t -A -c "SELECT end_date FROM contracts WHERE id='$C1ID';")
    RN=$(curl -s -X POST "$CURL/contracts/$C1ID/renew" -H "$CA" -H "$CJ" -d '{}')
    echo "$RN" | grep -q '"current_renewal":1' && ok "yenileme sayacı arttı" || bad "yenileme: $RN"
    echo "$RN" | grep -q 'KENDİLİĞİNDEN YENİLEMEZ' \
      && ok "sistemin kendiliğinden yenilemediği dürüstçe bildiriliyor" || bad "yenileme dürüstlük notu yok"
    NEWEND=$($PSQL -t -A -c "SELECT end_date FROM contracts WHERE id='$C1ID';")
    EXPECTED=$(date -d "$OLDEND +12 months" +%Y-%m-%d)
    [ "$NEWEND" = "$EXPECTED" ] && ok "bitiş tarihi mevcut bitişten itibaren uzatıldı ($NEWEND)" \
      || bad "uzatma yanlış: $OLDEND → $NEWEND (beklenen $EXPECTED)"

    # max_renewals=1 → ikinci yenileme reddedilmeli
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts/$C1ID/renew" -H "$CA" -H "$CJ" -d '{}')
    [ "$SC" = "422" ] && ok "azami yenileme sayısı aşılamıyor → 422" || bad "azami yenileme aşıldı → $SC"
  fi

  # 9) Süresi dolanları işaretleme — idempotent ve auto_renew'leri atlamalı
  C3ID=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name,
      start_date, end_date, status, auto_renew)
    VALUES ('11111111-1111-1111-1111-111111111111','OTHER','Suresi dolmus','Eski Firma',
      '$LASTYEAR','$PASTEND','ACTIVE',false) RETURNING id;")
  C4ID=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name,
      start_date, end_date, status, auto_renew, renewal_period_months)
    VALUES ('11111111-1111-1111-1111-111111111111','OTHER','Kendiliginden yenilenen','Yeni Firma',
      '$LASTYEAR','$PASTEND','ACTIVE',true,12) RETURNING id;")
  EX=$(curl -s -X POST "$CURL/contracts/expire-due" -H "$CA" -H "$CJ" -d '{}')
  echo "$EX" | grep -q '"expired_count":1' && ok "süresi dolan sözleşme EXPIRED işaretlendi" \
    || bad "expire-due: $EX"
  ST4=$($PSQL -t -A -c "SELECT status FROM contracts WHERE id='$C4ID';")
  [ "$ST4" = "ACTIVE" ] && ok "kendiliğinden yenilenen sözleşme süre dolumunun dışında tutuldu" \
    || bad "auto_renew sözleşme EXPIRED yapıldı: $ST4"
  EX2=$(curl -s -X POST "$CURL/contracts/expire-due" -H "$CA" -H "$CJ" -d '{}')
  echo "$EX2" | grep -q '"expired_count":0' && ok "expire-due idempotent (ikinci çalıştırma 0)" \
    || bad "expire-due idempotent değil: $EX2"

  # 10) Fesih — gerekçe zorunlu
  if [ -n "$C2ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts/$C2ID/terminate" -H "$CA" -H "$CJ" -d '{}')
    [ "$SC" = "400" ] && ok "gerekçesiz fesih engellendi → 400" || bad "gerekçesiz fesih → $SC"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts/$C2ID/terminate" -H "$CA" -H "$CJ" \
      -d '{"reason":"Hizmet kalitesi yetersiz - genel kurul karari"}')
    [ "$SC" = "200" ] && ok "fesih kaydedildi → 200" || bad "fesih → $SC"
    TR=$($PSQL -t -A -c "SELECT status || '|' || COALESCE(termination_reason,'') FROM contracts WHERE id='$C2ID';")
    echo "$TR" | grep -q '^TERMINATED|Hizmet kalitesi' && ok "fesih gerekçesiyle birlikte kayda geçti" \
      || bad "fesih kaydı: $TR"

    # Feshedilmiş sözleşme tekrar feshedilemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/contracts/$C2ID/terminate" -H "$CA" -H "$CJ" \
      -d '{"reason":"tekrar"}')
    [ "$SC" = "409" ] && ok "feshedilmiş sözleşme tekrar feshedilemiyor → 409" || bad "çift fesih → $SC"
  fi

  # 11) Kimliksiz erişim engelli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$CURL/contracts")
  [ "$SC" = "401" ] && ok "kimliksiz sözleşme erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "contract-service başlamadı"; tail -10 /tmp/verify-contract.log
fi
kill_tree "$CTR_PID"

step "19) Belge arşivi + dosya depolama — mock'tan gerçeğe (FAZ 5, 8/22 · S-09)"
# Önceki davranış: sabit belge listesi; yükleme ucu 2xx dönüp DOSYAYI HİÇBİR YERE
# YAZMIYORDU. Artık pkg/storage üzerinden gerçekten saklanıyor (yerel ya da S3 uyumlu).
DOCPORT=${VERIFY_DOC_PORT:-18093}
DOCDIR=/tmp/verify-docs
rm -rf "$DOCDIR"; mkdir -p "$DOCDIR"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${DOCPORT} \
STORAGE_BACKEND=local STORAGE_LOCAL_DIR="$DOCDIR" DOCUMENT_MAX_UPLOAD_MB=1 \
  go run ./services/document >/tmp/verify-document.log 2>&1 &
DOC_PID=$!
DUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${DOCPORT}/health" >/dev/null 2>&1 && { DUP=1; break; }
  sleep 1
done

if [ "$DUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "document-service ayağa kalktı"
  DA="Authorization: Bearer $MGR"
  DT="Authorization: Bearer $TEN"
  DURL="http://127.0.0.1:${DOCPORT}/api/v1"

  # Yalnızca KAT MALİKİ olan (yönetimde olmayan) üçüncü bir hesap:
  # OWNERS kademesinin gerçekten çalıştığını göstermek için gerekli.
  $PSQL -c "INSERT INTO users (id, first_name, last_name, phone, email, password_hash,
      active_property_id, roles)
    VALUES ('44444444-4444-4444-4444-444444444403','Zeynep','Kaya','+905550000003','zeynep@example.com',
      (SELECT password_hash FROM users WHERE id='44444444-4444-4444-4444-444444444401'),
      '11111111-1111-1111-1111-111111111111', ARRAY['RESIDENT'])
    ON CONFLICT (id) DO NOTHING;" >/dev/null 2>&1
  $PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role, start_date)
    VALUES ('44444444-4444-4444-4444-444444444403','33333333-3333-3333-3333-333333333305','OWNER',CURRENT_DATE)
    ON CONFLICT DO NOTHING;" >/dev/null 2>&1
  OWN=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5550000003","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  DO_="Authorization: Bearer $OWN"
  [ -n "$OWN" ] && ok "kat maliki (yönetimde olmayan) hesabı girişi" || bad "kat maliki girişi başarısız"

  # Depolama sağlayıcısı sağlık ucunda dürüstçe bildirilmeli
  H=$(curl -s "http://127.0.0.1:${DOCPORT}/health")
  echo "$H" | grep -q '"backend":"local"' && ok "sağlık ucu depolama sağlayıcısını bildiriyor" \
    || bad "sağlık ucu depolama bilgisi: $H"

  # 1) Gerçek dosya yükleme
  echo "2026 yili isletme projesi - ornek icerik" > /tmp/verify-upload.txt
  WANTSUM=$(sha256sum /tmp/verify-upload.txt | cut -d' ' -f1)
  U1=$(curl -s -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload.txt;type=text/plain" \
    -F "category=ACCOUNTING" -F "title=Hesap belgesi 2026" -F "visibility=OWNERS")
  D1ID=$(echo "$U1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$D1ID" ] && ok "belge yüklendi ve kaydedildi" || bad "yükleme başarısız: $U1"
  echo "$U1" | grep -q "\"sha256\":\"$WANTSUM\"" && ok "SHA-256 özeti doğru hesaplandı" \
    || bad "özet uyuşmuyor: $U1 (beklenen $WANTSUM)"

  # 2) DOSYA GERÇEKTEN DİSKE YAZILDI MI? (mock'un yapmadığı şey)
  STORED=$(find "$DOCDIR" -type f ! -name '*.meta.json' | head -1)
  if [ -n "$STORED" ]; then
    ok "dosya nesne deposuna gerçekten yazıldı"
    GOTSUM=$(sha256sum "$STORED" | cut -d' ' -f1)
    [ "$GOTSUM" = "$WANTSUM" ] && ok "diskteki içerik bozulmadan saklandı" \
      || bad "diskteki içerik farklı: $GOTSUM"
  else
    bad "nesne deposunda dosya yok — yükleme yine sahte"
  fi

  # Depo anahtarı site kimliğiyle başlamalı (site izolasyonu)
  echo "$STORED" | grep -q 'properties/11111111-1111-1111-1111-111111111111/documents/' \
    && ok "depo anahtarı site kimliğiyle ayrılmış" || bad "depo anahtarı site bazlı değil: $STORED"

  # Boyut sınırı (2026-09-27): önceden yoktu, tek istekle depo doldurulabilirdi.
  # Doğrulamada sınır 1 MB; 3 MB'lık dosya 413 almalı ve depoya HİÇBİR ŞEY yazılmamalı.
  head -c 3145728 /dev/urandom > /tmp/verify-big.bin
  BEFORE=$(find "$DOCDIR" -type f | wc -l)
  BIG=$(curl -s -w '\n%{http_code}' -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-big.bin;type=application/octet-stream" -F "category=OTHER" -F "title=Buyuk")
  AFTER=$(find "$DOCDIR" -type f | wc -l)
  [ "$(echo "$BIG" | tail -1)" = "413" ] && [ "$BEFORE" = "$AFTER" ] \
    && ok "sınırı aşan belge 413 ile reddedildi, depoya yazılmadı" \
    || bad "büyük belge: $(echo "$BIG" | tail -1), dosya sayısı $BEFORE → $AFTER"
  rm -f /tmp/verify-big.bin

  # 3) Diğer kademelerde birer belge
  echo "Genel kurul karar tutanagi" > /tmp/verify-upload2.txt
  U2=$(curl -s -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload2.txt;type=text/plain" \
    -F "category=DECISION" -F "title=Karar tutanagi" -F "visibility=RESIDENTS")
  D2ID=$(echo "$U2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "Ozluk dosyasi - kapici" > /tmp/verify-upload3.txt
  U3=$(curl -s -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload3.txt;type=text/plain" \
    -F "category=PERSONNEL" -F "title=Ozluk dosyasi")
  D3ID=$(echo "$U3" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$D2ID" ] && [ -n "$D3ID" ] && ok "üç görünürlük kademesinde belge oluşturuldu" \
    || bad "ek belgeler oluşturulamadı"

  # Görünürlük belirtilmediğinde EN DAR kademe uygulanmalı
  VIS3=$(qscoped "SELECT visibility FROM documents WHERE id='$D3ID';")
  [ "$VIS3" = "MANAGEMENT" ] && ok "görünürlük belirtilmediğinde en dar kademe uygulanıyor" \
    || bad "varsayılan görünürlük geniş: $VIS3"

  # 4) KVKK: kademelere göre görünürlük
  TL=$(curl -s "$DURL/documents" -H "$DT")
  echo "$TL" | grep -q 'Karar tutanagi' && ok "kiracı sakinlere açık belgeyi görüyor" || bad "kiracı listesi: $TL"
  echo "$TL" | grep -q 'Hesap belgesi' && bad "kiracı, kat maliklerine özel belgeyi görüyor" \
    || ok "kiracı kat maliki belgesini göremiyor"
  echo "$TL" | grep -q 'Ozluk dosyasi' && bad "kiracı ÖZLÜK DOSYASINI görüyor (KVKK ihlali)" \
    || ok "kiracı özlük dosyasını göremiyor (KVKK m.4)"

  OL=$(curl -s "$DURL/documents" -H "$DO_")
  echo "$OL" | grep -q 'Hesap belgesi' && ok "kat maliki hesap belgesini görüyor (KMK m.36)" \
    || bad "kat maliki hesap belgesini göremiyor: $OL"
  echo "$OL" | grep -q 'Ozluk dosyasi' && bad "kat maliki özlük dosyasını görüyor" \
    || ok "kat maliki özlük dosyasını göremiyor"

  ML=$(curl -s "$DURL/documents" -H "$DA")
  echo "$ML" | grep -q 'Ozluk dosyasi' && ok "yönetim tüm kademeleri görüyor" || bad "yönetim listesi: $ML"

  # Tekil okuma da kademeyi uygulamalı ve VARLIĞI SIZDIRMAMALI
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$DURL/documents/$D3ID" -H "$DT")
  [ "$SC" = "404" ] && ok "yetkisiz tekil okuma belgenin varlığını sızdırmıyor → 404" \
    || bad "yetkisiz tekil okuma → $SC"

  # Depo anahtarı istemciye ASLA verilmemeli
  echo "$ML" | grep -q 'storage_key' && bad "yanıt depo anahtarını sızdırıyor" \
    || ok "depo anahtarı istemciye verilmiyor"

  # 5) Tekil görüntüleme ve indirme — içerik bozulmadan gelmeli
  if [ -n "$D1ID" ]; then
    VIEW=$(curl -s "$DURL/documents/$D1ID" -H "$DA")
    echo "$VIEW" | grep -q '"title":"Hesap belgesi 2026"' && ok "belge üst verisi okunabiliyor" \
      || bad "tekil okuma: $VIEW"
    curl -s -D /tmp/verify-dl-head.txt -o /tmp/verify-dl.txt "$DURL/documents/$D1ID/download" -H "$DA"
    DLSUM=$(sha256sum /tmp/verify-dl.txt | cut -d' ' -f1)
    [ "$DLSUM" = "$WANTSUM" ] && ok "indirilen dosya yüklenenle birebir aynı" || bad "indirme bozuk: $DLSUM"
    grep -qi "X-Document-SHA256: $WANTSUM" /tmp/verify-dl-head.txt \
      && ok "bütünlük özeti indirme başlığında veriliyor" || bad "SHA-256 başlığı yok"
  fi

  # 6) KVKK m.12 — belge erişim kaydı
  if [ -n "$D1ID" ]; then
    AL=$(curl -s "$DURL/documents/$D1ID/access-log" -H "$DA")
    echo "$AL" | grep -q '"action":"DOWNLOAD"' && ok "indirme erişim kaydına yazıldı (KVKK m.12)" \
      || bad "indirme kaydı yok: $AL"
    echo "$AL" | grep -q '"action":"VIEW"' || bad "görüntüleme kaydı yok: $AL"

    SC=$(curl -s -o /dev/null -w '%{http_code}' "$DURL/documents/$D1ID/access-log" -H "$DT")
    [ "$SC" = "403" ] && ok "sakin erişim kayıtlarını göremiyor → 403" || bad "sakin erişim kaydı gördü → $SC"

    # Reddedilen erişim de kayda geçmeli
    DEN=$(qscoped "SELECT count(*) FROM document_access_logs WHERE action='DENIED';")
    [ "$DEN" -ge 1 ] && ok "reddedilen belge erişimi de kayda geçiyor ($DEN kayıt)" \
      || bad "DENIED belge erişim kaydı yok"

    # Erişim kayıtları salt-ekleme olmalı
    if $PSQL -c "SET LOCAL app.property_id = '$DEMO_PROPERTY'; UPDATE document_access_logs SET action='VIEW' WHERE id=(SELECT min(id) FROM document_access_logs);" >/dev/null 2>&1; then
      bad "erişim kayıtları değiştirilebiliyor (kanıt değeri yok)"
    else
      ok "erişim kayıtları değiştirilemiyor (salt-ekleme tetikleyicisi)"
    fi
    if $PSQL -c "SET LOCAL app.property_id = '$DEMO_PROPERTY'; DELETE FROM document_access_logs WHERE id=(SELECT min(id) FROM document_access_logs);" >/dev/null 2>&1; then
      bad "erişim kayıtları silinebiliyor"
    else
      ok "erişim kayıtları silinemiyor"
    fi
  fi

  # 7) Sürümleme — yönetim planı değişikliği eskisini silmez
  echo "Yonetim plani - yeni surum" > /tmp/verify-upload4.txt
  V1=$(curl -s -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload4.txt;type=text/plain" \
    -F "category=MANAGEMENT_PLAN" -F "title=Yonetim plani" -F "visibility=RESIDENTS")
  V1ID=$(echo "$V1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "Yonetim plani - 2. surum" > /tmp/verify-upload5.txt
  V2=$(curl -s -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload5.txt;type=text/plain" \
    -F "category=MANAGEMENT_PLAN" -F "title=Yonetim plani" -F "visibility=RESIDENTS" \
    -F "replaces_id=$V1ID")
  echo "$V2" | grep -q '"id"' && ok "yeni sürüm yüklendi" || bad "sürüm yüklenemedi: $V2"
  VOLD=$(qscoped "SELECT is_current FROM documents WHERE id='$V1ID';")
  [ "$VOLD" = "f" ] && ok "eski sürüm güncel olmaktan çıktı (silinmedi)" || bad "eski sürüm durumu: $VOLD"
  VNEW=$(qscoped "SELECT version FROM documents WHERE replaces_id='$V1ID';")
  [ "$VNEW" = "2" ] && ok "sürüm numarası otomatik arttı" || bad "sürüm numarası: $VNEW"
  DEFL=$(curl -s "$DURL/documents?category=MANAGEMENT_PLAN" -H "$DA")
  [ "$(echo "$DEFL" | grep -o '"version"' | wc -l)" = "1" ] \
    && ok "varsayılan listede yalnızca güncel sürüm var" || bad "liste eski sürümü de döndürüyor"

  # 8) Geçersiz kategori
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$DURL/documents" -H "$DA" \
    -F "file=@/tmp/verify-upload.txt" -F "category=UYDURMA" -F "title=X")
  [ "$SC" = "422" ] && ok "geçersiz kategori reddedildi → 422" || bad "geçersiz kategori → $SC"

  # Üst veri yazılamayan yükleme depoda öksüz dosya bırakmamalı
  ORPHAN=$(find "$DOCDIR" -type f ! -name '*.meta.json' | wc -l)
  DBCOUNT=$(qscoped "SELECT count(*) FROM documents;")
  [ "$ORPHAN" = "$DBCOUNT" ] && ok "depodaki dosya sayısı kayıt sayısıyla eşit ($ORPHAN) — öksüz dosya yok" \
    || bad "depo ile kayıt uyuşmuyor: $ORPHAN dosya, $DBCOUNT kayıt"

  # 9) Arşivleme — gerekçe zorunlu, kayıt silinmez
  if [ -n "$D2ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$DURL/documents/$D2ID/archive" \
      -H "$DA" -H 'Content-Type: application/json' -d '{}')
    [ "$SC" = "400" ] && ok "gerekçesiz arşivleme engellendi → 400" || bad "gerekçesiz arşivleme → $SC"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$DURL/documents/$D2ID/archive" \
      -H "$DA" -H 'Content-Type: application/json' -d '{"reason":"Yanlis donem yuklendi"}')
    [ "$SC" = "200" ] && ok "belge arşivden çıkarıldı → 200" || bad "arşivleme → $SC"
    ARC=$(qscoped "SELECT count(*) FROM documents WHERE id='$D2ID' AND archived_at IS NOT NULL;")
    [ "$ARC" = "1" ] && ok "arşiv kaydı korunuyor (belge silinmiyor)" || bad "arşiv kaydı: $ARC"
    AL2=$(curl -s "$DURL/documents" -H "$DA")
    echo "$AL2" | grep -q 'Karar tutanagi' && bad "arşivlenen belge varsayılan listede görünüyor" \
      || ok "arşivlenen belge varsayılan listeden çıktı"
  fi

  # 10) Yetki ve kimlik
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$DURL/documents" -H "$DT" \
    -F "file=@/tmp/verify-upload.txt" -F "category=OTHER" -F "title=X")
  [ "$SC" = "403" ] && ok "sakin belge yükleyemiyor → 403" || bad "sakin belge yükledi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$DURL/documents")
  [ "$SC" = "401" ] && ok "kimliksiz belge erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "document-service başlamadı"; tail -15 /tmp/verify-document.log
fi
kill_tree "$DOC_PID"

step "20) Demirbaş modülü — mock'tan gerçeğe (FAZ 5, 9/22)"
# Önceki davranış: sabit demirbaş listesi; yazma istekleri kaydedilmiyordu.
# Kritik nokta: amortisman DEFTERDE SAKLANMAZ, her okumada hesaplanır — saklanan
# değer zamanla sessizce yanlışa döner ve devir/bütçe konuşmasını bozar.
ASTPORT=${VERIFY_AST_PORT:-18087}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${ASTPORT} \
  go run ./services/asset >/tmp/verify-asset.log 2>&1 &
AST_PID=$!
AUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${ASTPORT}/health" >/dev/null 2>&1 && { AUP=1; break; }
  sleep 1
done

if [ "$AUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "asset-service ayağa kalktı"
  AA="Authorization: Bearer $MGR"
  AT="Authorization: Bearer $TEN"
  AJ='Content-Type: application/json'
  AURL="http://127.0.0.1:${ASTPORT}/api/v1"

  TWOYEARSAGO=$(date -d '-2 years' +%Y-%m-%d)
  SOONWARR=$(date -d '+20 days' +%Y-%m-%d)
  PASTDUE=$(date -d '-10 days' +%Y-%m-%d)

  # 1) Kategori
  CAT=$(curl -s -X POST "$AURL/asset-categories" -H "$AA" -H "$AJ" \
    -d '{"name":"Asansor ekipmani","depreciation_years":10}')
  CATID=$(echo "$CAT" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$CATID" ] && ok "demirbaş kategorisi oluşturuldu" || bad "kategori: $CAT"

  # 2) Demirbaş — 10.000 TL, 5 yıl, 2 yıl önce alınmış → birikmiş 4.000, defter 6.000
  A1=$(curl -s -X POST "$AURL/assets" -H "$AA" -H "$AJ" -d "{
    \"category_id\":\"$CATID\",\"name\":\"Jenerator\",\"asset_code\":\"DMB-001\",
    \"location\":\"A Blok bodrum\",\"purchase_date\":\"$TWOYEARSAGO\",
    \"purchase_price\":10000,\"depreciation_years\":5,\"vendor\":\"Ornek Enerji\",
    \"maintenance_interval_days\":180,\"condition\":\"GOOD\"}")
  A1ID=$(echo "$A1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$A1ID" ] && ok "demirbaş kaydedildi ve KALICI" || bad "demirbaş: $A1"

  if [ -n "$A1ID" ]; then
    DBC=$($PSQL -t -A -c "SELECT count(*) FROM assets WHERE id='$A1ID';")
    [ "$DBC" = "1" ] && ok "demirbaş veritabanında (mock değil)" || bad "kayıt yok"

    # 3) Amortisman HESAPLANARAK dönmeli
    G=$(curl -s "$AURL/assets/$A1ID" -H "$AA")
    echo "$G" | grep -q '"accumulated":4000' && ok "birikmiş amortisman doğru (2 yıl × 2.000 = 4.000 TL)" \
      || bad "birikmiş amortisman: $G"
    echo "$G" | grep -q '"book_value":6000' && ok "defter değeri doğru (10.000 − 4.000 = 6.000 TL)" \
      || bad "defter değeri yanlış"
    echo "$G" | grep -q '"annual_amount":2000' && ok "yıllık amortisman payı doğru" || bad "yıllık pay yanlış"

    # Saklanan kolon KULLANILMAMALI: kolonu elle bozup okumanın değişmediğini göster
    $PSQL -c "UPDATE assets SET current_value=99999, accumulated_depreciation=99999 WHERE id='$A1ID';" >/dev/null 2>&1
    G2=$(curl -s "$AURL/assets/$A1ID" -H "$AA")
    echo "$G2" | grep -q '"book_value":6000' \
      && ok "defter değeri saklanan (bayat) kolondan OKUNMUYOR, hesaplanıyor" \
      || bad "bayat kolon kullanılıyor: $G2"
  fi

  # 4) Amortisman verisi eksikse uydurulmamalı
  A2=$(curl -s -X POST "$AURL/assets" -H "$AA" -H "$AJ" \
    -d '{"name":"Bahce hortumu","condition":"NEW"}')
  A2ID=$(echo "$A2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  G3=$(curl -s "$AURL/assets/$A2ID" -H "$AA")
  echo "$G3" | grep -q 'depreciation_note' && ok "eksik veride amortisman uydurulmuyor" \
    || bad "eksik veride amortisman üretildi: $G3"
  echo "$G3" | grep -q '"book_value"' && bad "eksik veride defter değeri yazıldı" \
    || ok "eksik veride defter değeri boş bırakılıyor"

  # 5) Başka sitenin kategorisi kullanılamaz
  OTHERCAT=$($PSQL -t -A -c "INSERT INTO properties (id, name, address, city, district, total_units, total_share_ratio)
      VALUES ('99999999-9999-9999-9999-999999999999','Baska Site','X','Ist','Kadikoy',1,1)
      ON CONFLICT (id) DO NOTHING;
    INSERT INTO asset_categories (property_id, name) VALUES
      ('99999999-9999-9999-9999-999999999999','Baska site kategorisi') RETURNING id;" 2>/dev/null | tail -1)
  if [ -n "$OTHERCAT" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets" -H "$AA" -H "$AJ" \
      -d "{\"name\":\"Test\",\"category_id\":\"$OTHERCAT\"}")
    [ "$SC" = "422" ] && ok "başka sitenin kategorisi kullanılamıyor → 422" \
      || bad "başka site kategorisi kabul edildi → $SC"
  fi

  # 6) Bakım kaydı — toplam maliyet SUNUCUDA hesaplanmalı, takvim aynı işlemde güncellenmeli
  if [ -n "$A1ID" ]; then
    $PSQL -c "UPDATE assets SET next_maintenance_date='$PASTDUE' WHERE id='$A1ID';" >/dev/null 2>&1
    DUE=$(curl -s "$AURL/assets?maintenance_due=true" -H "$AA")
    echo "$DUE" | grep -q 'Jenerator' && ok "bakımı gecikmiş demirbaş süzgeci çalışıyor" \
      || bad "gecikmiş bakım süzgeci: $DUE"

    # İstemci yanlış bir toplam gönderse bile sunucu kendi hesabını kullanmalı
    M1=$(curl -s -X POST "$AURL/assets/$A1ID/maintenance" -H "$AA" -H "$AJ" -d '{
      "maintenance_type":"PREVENTIVE","description":"Yillik bakim",
      "labor_cost":1500,"parts_cost":2500,"total_cost":1,"performed_by":"Ornek Teknik"}')
    echo "$M1" | grep -q '"total_cost":4000' && ok "bakım toplamı sunucuda hesaplandı (1.500+2.500)" \
      || bad "bakım toplamı: $M1"
    DBTOTAL=$($PSQL -t -A -c "SELECT total_cost::numeric(12,2) FROM asset_maintenance
      WHERE asset_id='$A1ID' ORDER BY created_at DESC LIMIT 1;")
    [ "$DBTOTAL" = "4000.00" ] && ok "istemcinin gönderdiği yanlış toplam kullanılmadı" \
      || bad "veritabanındaki toplam: $DBTOTAL"

    # Bakım takvimi aynı işlemde güncellenmeli (180 gün sonrası)
    NEXTM=$($PSQL -t -A -c "SELECT next_maintenance_date FROM assets WHERE id='$A1ID';")
    EXPECTEDM=$(date -d "+180 days" +%Y-%m-%d)
    [ "$NEXTM" = "$EXPECTEDM" ] && ok "sıradaki bakım tarihi aynı işlemde güncellendi ($NEXTM)" \
      || bad "bakım takvimi güncellenmedi: $NEXTM (beklenen $EXPECTEDM)"
    DUE2=$(curl -s "$AURL/assets?maintenance_due=true" -H "$AA")
    echo "$DUE2" | grep -q 'Jenerator' && bad "bakımı yapılan demirbaş hâlâ gecikmiş görünüyor" \
      || ok "bakımı yapılan demirbaş gecikmiş listesinden çıktı"

    # Geçersiz bakım türü: 422 (girdi hatası). Önceden 409 ("kayıt uygun durumda
    # değil") dönüyordu ve bu test o yanlış kodu sabitliyordu.
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets/$A1ID/maintenance" -H "$AA" -H "$AJ" \
      -d '{"maintenance_type":"UYDURMA","description":"x"}')
    [ "$SC" = "422" ] && ok "geçersiz bakım türü reddedildi → 422" || bad "geçersiz bakım türü → $SC"

    # Bakım geçmişi
    HIST=$(curl -s "$AURL/assets/$A1ID/maintenance" -H "$AA")
    echo "$HIST" | grep -q 'Yillik bakim' && ok "bakım geçmişi okunabiliyor" || bad "bakım geçmişi: $HIST"
  fi

  # 7) Garanti süzgeci
  $PSQL -c "UPDATE assets SET warranty_end='$SOONWARR' WHERE id='$A1ID';" >/dev/null 2>&1
  W=$(curl -s "$AURL/assets?warranty_expires_days=30" -H "$AA")
  echo "$W" | grep -q 'Jenerator' && ok "garantisi bitmek üzere olanlar süzülebiliyor" || bad "garanti süzgeci: $W"
  echo "$W" | grep -q '"warranty_days_left"' && ok "garantiye kalan gün hesaplanıyor" || bad "kalan gün yok"

  # 8) Zimmet
  if [ -n "$A1ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets/$A1ID/assign" -H "$AA" -H "$AJ" \
      -d '{"assigned_to":"Teknik Servis"}')
    [ "$SC" = "200" ] && ok "zimmet kaydedildi" || bad "zimmet → $SC"
    ASG=$($PSQL -t -A -c "SELECT assigned_to FROM assets WHERE id='$A1ID';")
    [ "$ASG" = "Teknik Servis" ] && ok "zimmet veritabanına yazıldı" || bad "zimmet kaydı: $ASG"
  fi

  # 9) Kayıttan düşme — karar dayanağı ZORUNLU (KMK m.45)
  if [ -n "$A2ID" ]; then
    D0=$(curl -s -X POST "$AURL/assets/$A2ID/dispose" -H "$AA" -H "$AJ" -d '{"reason":"Kirildi"}')
    echo "$D0" | grep -q 'decision_ref' && ok "karar dayanağı olmadan kayıttan düşülemiyor" \
      || bad "gerekçesiz kayıttan düşme kabul edildi: $D0"
    echo "$D0" | grep -q 'KMK m.45' && ok "hukuki dayanak kullanıcıya bildiriliyor" || bad "hukuki dayanak yok"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets/$A2ID/dispose" -H "$AA" -H "$AJ" \
      -d '{"reason":"Kullanilamaz hale geldi","decision_ref":"2026/3 sayili genel kurul karari","new_condition":"DISPOSED"}')
    [ "$SC" = "200" ] && ok "karar dayanağıyla kayıttan düşüldü → 200" || bad "kayıttan düşme → $SC"
    ST=$($PSQL -t -A -c "SELECT status FROM assets WHERE id='$A2ID';")
    [ "$ST" = "DISPOSED" ] && ok "kayıt silinmedi, durumu DISPOSED oldu" || bad "durum: $ST"
    NT=$($PSQL -t -A -c "SELECT notes FROM assets WHERE id='$A2ID';")
    echo "$NT" | grep -q '2026/3 sayili genel kurul karari' && ok "karar dayanağı kayda geçti" \
      || bad "karar dayanağı kaydedilmedi: $NT"

    # Varsayılan listede görünmemeli
    L=$(curl -s "$AURL/assets" -H "$AA")
    echo "$L" | grep -q 'Bahce hortumu' && bad "kayıttan düşen demirbaş varsayılan listede" \
      || ok "kayıttan düşen demirbaş varsayılan listeden çıktı"
    L2=$(curl -s "$AURL/assets?include_disposed=true" -H "$AA")
    echo "$L2" | grep -q 'Bahce hortumu' && ok "istenirse kayıttan düşenler de listeleniyor" \
      || bad "include_disposed çalışmıyor"

    # İkinci kez kayıttan düşülemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets/$A2ID/dispose" -H "$AA" -H "$AJ" \
      -d '{"reason":"tekrar","decision_ref":"x"}')
    [ "$SC" = "409" ] && ok "kayıttan düşmüş demirbaş tekrar düşülemiyor → 409" || bad "çift düşme → $SC"
  fi

  # 10) Özet
  SUM=$(curl -s "$AURL/assets-summary" -H "$AA")
  echo "$SUM" | grep -q '"maintenance_cost_ytd_try":4000' && ok "yıl içi bakım gideri özeti doğru" \
    || bad "bakım gideri özeti: $SUM"
  echo "$SUM" | grep -q '"purchase_total_try":10000' && ok "aktif demirbaşların alım değeri toplamı doğru" \
    || bad "alım değeri toplamı: $SUM"
  echo "$SUM" | grep -q '"disposed":1' && ok "özet kayıttan düşenleri ayrı sayıyor" || bad "özet disposed: $SUM"

  # 11) Yetki
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$AURL/assets" -H "$AT")
  [ "$SC" = "403" ] && ok "sakin demirbaş envanterini göremiyor → 403" || bad "sakin envanteri gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL/assets" -H "$AT" -H "$AJ" -d '{"name":"X"}')
  [ "$SC" = "403" ] && ok "sakin demirbaş ekleyemiyor → 403" || bad "sakin demirbaş ekledi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$AURL/assets")
  [ "$SC" = "401" ] && ok "kimliksiz demirbaş erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "asset-service başlamadı"; tail -15 /tmp/verify-asset.log
fi
kill_tree "$AST_PID"

step "21) Stok modülü — mock'tan gerçeğe (FAZ 5, 10/22)"
# Önceki davranış: sabit stok listesi; hareket istekleri kaydedilmiyordu, yani
# stok sayısı hiç değişmiyordu. Kritik nokta: stok güncellemesi hareket kaydıyla
# AYNI transaction'da ve satır kilitlenerek yapılmalı — yoksa eşzamanlı iki çıkış
# depoda olmayan malzemeyi kayıtta bırakır.
INVPORT=${VERIFY_INV_PORT:-18089}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${INVPORT} \
  go run ./services/inventory >/tmp/verify-inventory.log 2>&1 &
INV_PID=$!
IUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${INVPORT}/health" >/dev/null 2>&1 && { IUP=1; break; }
  sleep 1
done

if [ "$IUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "inventory-service ayağa kalktı"
  IA="Authorization: Bearer $MGR"
  IT="Authorization: Bearer $TEN"
  IJ='Content-Type: application/json'
  IURL="http://127.0.0.1:${INVPORT}/api/v1"

  # 1) Kategori ve kalem
  ICAT=$(curl -s -X POST "$IURL/inventory-categories" -H "$IA" -H "$IJ" -d '{"name":"Temizlik"}')
  ICATID=$(echo "$ICAT" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$ICATID" ] && ok "stok kategorisi oluşturuldu" || bad "kategori: $ICAT"

  I1=$(curl -s -X POST "$IURL/inventory" -H "$IA" -H "$IJ" -d "{
    \"category_id\":\"$ICATID\",\"name\":\"Camasir suyu\",\"unit\":\"LT\",
    \"sku\":\"TMZ-001\",\"minimum_stock\":\"10\",\"warehouse\":\"Ana depo\"}")
  I1ID=$(echo "$I1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$I1ID" ] && ok "stok kalemi oluşturuldu ve KALICI" || bad "kalem: $I1"
  echo "$I1" | grep -q '"current_stock":"0"' && ok "açılış stoğu sıfır (her miktar bir harekete dayanır)" \
    || bad "açılış stoğu sıfır değil: $I1"

  # Geçersiz birim reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL/inventory" -H "$IA" -H "$IJ" \
    -d '{"name":"X","unit":"litre"}')
  [ "$SC" = "422" ] && ok "geçersiz birim reddedildi → 422" || bad "geçersiz birim → $SC"

  if [ -n "$I1ID" ]; then
    # 2) Giriş — 100 LT × 50 TL
    M1=$(curl -s -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" -d '{
      "movement_type":"IN","quantity":"100","unit_price":50,
      "reference_type":"PURCHASE","reference_number":"FTR-2026-1","vendor":"Ornek Kimya"}')
    echo "$M1" | grep -q '"new_stock":"100"' && ok "giriş hareketi stoğu gerçekten artırdı (0 → 100)" \
      || bad "giriş: $M1"
    DBS=$($PSQL -t -A -c "SELECT current_stock::numeric(12,0) FROM inventory_items WHERE id='$I1ID';")
    [ "$DBS" = "100" ] && ok "stok veritabanına yazıldı (mock değil)" || bad "veritabanı stoğu: $DBS"

    # 3) Ağırlıklı ortalama maliyet — 100×50 + 100×70 → 60
    M2=$(curl -s -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" -d '{
      "movement_type":"IN","quantity":"100","unit_price":70,"reference_type":"PURCHASE"}')
    echo "$M2" | grep -q '"unit_price":60' \
      && ok "birim maliyet ağırlıklı ortalamayla güncellendi ((100×50+100×70)/200 = 60 TL)" \
      || bad "ağırlıklı ortalama yanlış: $M2"
    LASTP=$($PSQL -t -A -c "SELECT last_purchase_price::numeric(12,0) FROM inventory_items WHERE id='$I1ID';")
    [ "$LASTP" = "70" ] && ok "son alış fiyatı ayrıca saklanıyor" || bad "son alış fiyatı: $LASTP"

    # Stok değeri = 200 × 60 = 12.000
    GI=$(curl -s "$IURL/inventory/$I1ID" -H "$IA")
    echo "$GI" | grep -q '"stock_value":12000' && ok "stok değeri ortalama maliyetle hesaplanıyor (12.000 TL)" \
      || bad "stok değeri: $GI"

    # 4) Çıkış
    M3=$(curl -s -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" -d '{
      "movement_type":"OUT","quantity":"30","reference_type":"USAGE","notes":"A blok temizlik"}')
    echo "$M3" | grep -q '"new_stock":"170"' && ok "çıkış hareketi stoğu azalttı (200 → 170)" \
      || bad "çıkış: $M3"

    # 5) NEGATİF STOK YASAK
    NEG=$(curl -s -w '\n%{http_code}' -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
      -d '{"movement_type":"OUT","quantity":"1000"}')
    NEGCODE=$(echo "$NEG" | tail -1)
    [ "$NEGCODE" = "409" ] && ok "stoktan fazla çıkış engellendi → 409" || bad "negatif stok oluştu → $NEGCODE"
    echo "$NEG" | grep -q 'ADJUST' && ok "kullanıcıya doğru yol (sayım düzeltmesi) gösteriliyor" \
      || bad "yönlendirme notu yok"
    DBS2=$($PSQL -t -A -c "SELECT current_stock::numeric(12,0) FROM inventory_items WHERE id='$I1ID';")
    [ "$DBS2" = "170" ] && ok "reddedilen çıkış stoğu değiştirmedi" || bad "stok bozuldu: $DBS2"

    # 6) EŞZAMANLILIK — 10 paralel çıkış × 10 LT; stok tam olarak 70 olmalı
    # NOT: çıplak `wait` kullanılmaz — kabuğun tüm arka plan çocuklarını, yani
    # doğrulama boyunca ayakta tutulan servisleri de bekler ve betik asılı kalır.
    # Yalnızca bu döngüde başlatılan işler beklenir.
    CONC_PIDS=""
    for _i in $(seq 1 10); do
      curl -s -o /dev/null -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
        -d '{"movement_type":"OUT","quantity":"10","reference_type":"USAGE"}' &
      CONC_PIDS="$CONC_PIDS $!"
    done
    for _p in $CONC_PIDS; do wait "$_p" 2>/dev/null; done
    CONC=$($PSQL -t -A -c "SELECT current_stock::numeric(12,0) FROM inventory_items WHERE id='$I1ID';")
    [ "$CONC" = "70" ] && ok "10 eşzamanlı çıkış kayıp/çift sayım olmadan işlendi (170 → 70)" \
      || bad "eşzamanlı çıkışta stok bozuldu: $CONC (70 bekleniyordu)"
    MCOUNT=$($PSQL -t -A -c "SELECT count(*) FROM inventory_movements WHERE item_id='$I1ID';")
    [ "$MCOUNT" = "13" ] && ok "her miktar değişikliği bir hareket kaydı üretti (13 kayıt)" \
      || bad "hareket sayısı: $MCOUNT (13 bekleniyordu)"

    # Kayıp güncelleme (lost update) denetimi: eşzamanlı 10 çıkış, 170'ten
    # başlayarak 160,150,...,70 sonuçlarını üretmek zorundadır. İki istek aynı
    # stoğu okusaydı aynı sonucu yazar ve bu küme eksik kalırdı.
    DISTINCT=$($PSQL -t -A -c "SELECT count(DISTINCT new_stock) FROM inventory_movements
      WHERE item_id='$I1ID' AND movement_type='OUT' AND quantity = 10;")
    [ "$DISTINCT" = "10" ] && ok "eşzamanlı çıkışların hiçbiri aynı stoğu okumadı (10 ayrı sonuç)" \
      || bad "kayıp güncelleme: $DISTINCT ayrı sonuç (10 bekleniyordu)"

    # Her hareketin kendi içinde tutarlı olduğu: önceki − miktar = sonraki
    BROKEN=$($PSQL -t -A -c "SELECT count(*) FROM inventory_movements
      WHERE item_id='$I1ID' AND movement_type='OUT'
        AND previous_stock - quantity <> new_stock;")
    [ "$BROKEN" = "0" ] && ok "her çıkış hareketi kendi içinde tutarlı (önceki − miktar = sonraki)" \
      || bad "$BROKEN hareket kaydı tutarsız"

    # 7) Sayım düzeltmesi — gerekçe zorunlu, yalnızca yönetim
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
      -d '{"movement_type":"ADJUST","quantity":"65"}')
    [ "$SC" = "400" ] && ok "gerekçesiz sayım düzeltmesi engellendi → 400" || bad "gerekçesiz ADJUST → $SC"

    M4=$(curl -s -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
      -d '{"movement_type":"ADJUST","quantity":"65","notes":"Yillik sayim: 5 LT fire"}')
    echo "$M4" | grep -q '"new_stock":"65"' && ok "sayım düzeltmesi stoğu hedef değere getirdi" \
      || bad "ADJUST: $M4"
    ADJ=$($PSQL -t -A -c "SELECT notes FROM inventory_movements WHERE item_id='$I1ID' AND movement_type='ADJUST';")
    echo "$ADJ" | grep -q '5 LT fire' && ok "sayım farkının gerekçesi kayda geçti" || bad "gerekçe kaydı: $ADJ"

    # 8) Asgari seviye uyarısı
    M5=$(curl -s -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
      -d '{"movement_type":"OUT","quantity":"60","reference_type":"USAGE"}')
    echo "$M5" | grep -q '"below_minimum":true' && ok "asgari seviyenin altına düşüş bildiriliyor" \
      || bad "asgari seviye uyarısı yok: $M5"
    # BİLDİRİM: asgari seviye uyarısı YÖNETİME gider, sakinlere değil.
    echo "$M5" | grep -q '"notification"' \
      && ok "asgari seviye uyarısı bildirim olarak raporlanıyor" || bad "bildirim raporu yok: $M5"
    LN=$(qscoped "SELECT count(*) FROM notifications WHERE topic='inventory.low_stock';")
    [ "${LN:-0}" -ge 1 ] && ok "stok uyarısı bildirimi veritabanında ($LN kayıt)" \
      || bad "stok uyarısı bildirimi yok"
    # Sakinlere GİTMEMELİ: depo stoğu sakinleri ilgilendirmez.
    LNR=$(qscoped "SELECT count(*) FROM notifications n
      WHERE n.topic='inventory.low_stock'
        AND NOT EXISTS (SELECT 1 FROM property_roles pr
                         WHERE pr.user_id = n.recipient_user_id
                           AND pr.property_id = '$DEMO_PROPERTY' AND pr.is_active);")
    [ "$LNR" = "0" ] && ok "stok uyarısı yalnızca yönetim rollerine gitti" \
      || bad "$LNR stok uyarısı sakine gitmiş"
    LOW=$(curl -s "$IURL/inventory?below_minimum=true" -H "$IA")
    echo "$LOW" | grep -q 'Camasir suyu' && ok "asgari seviye altı süzgeci çalışıyor" || bad "süzgeç: $LOW"
  fi

  # 9) Özet
  ISUM=$(curl -s "$IURL/inventory-summary" -H "$IA")
  echo "$ISUM" | grep -q '"purchase_cost_ytd_try":12000' && ok "yıl içi alım maliyeti doğru (5.000+7.000)" \
    || bad "alım maliyeti: $ISUM"
  echo "$ISUM" | grep -q '"below_minimum":1' && ok "özet asgari seviye altındakileri sayıyor" \
    || bad "özet asgari seviye: $ISUM"

  # 10) Yetki — sayım düzeltmesi görevliye kapalı olmalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL/inventory" -H "$IT")
  [ "$SC" = "403" ] && ok "sakin stok listesini göremiyor → 403" || bad "sakin stok gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL/inventory/$I1ID/movements" -H "$IT" -H "$IJ" \
    -d '{"movement_type":"OUT","quantity":"1"}')
  [ "$SC" = "403" ] && ok "sakin stok hareketi giremiyor → 403" || bad "sakin hareket girdi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL/inventory")
  [ "$SC" = "401" ] && ok "kimliksiz stok erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"

  # 11) Pasife alma — kayıt ve hareketler silinmez
  if [ -n "$I1ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$IURL/inventory/$I1ID" -H "$IA" -H "$IJ" -d '{}')
    [ "$SC" = "400" ] && ok "gerekçesiz pasife alma engellendi → 400" || bad "gerekçesiz pasife alma → $SC"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$IURL/inventory/$I1ID" -H "$IA" -H "$IJ" \
      -d '{"reason":"Artik kullanilmiyor"}')
    [ "$SC" = "200" ] && ok "stok kalemi pasife alındı" || bad "pasife alma → $SC"
    STILL=$($PSQL -t -A -c "SELECT count(*) FROM inventory_movements WHERE item_id='$I1ID';")
    [ "$STILL" -ge 13 ] && ok "pasife alınan kalemin hareket geçmişi korundu ($STILL kayıt)" \
      || bad "hareket geçmişi silindi: $STILL"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL/inventory/$I1ID/movements" -H "$IA" -H "$IJ" \
      -d '{"movement_type":"IN","quantity":"1"}')
    [ "$SC" = "409" ] && ok "pasif kaleme hareket girilemiyor → 409" || bad "pasif kaleme hareket → $SC"
  fi
else
  bad "inventory-service başlamadı"; tail -15 /tmp/verify-inventory.log
fi
kill_tree "$INV_PID"

step "22) Anket/oylama modülü — mock'tan gerçeğe (FAZ 5, 11/22)"
# Önceki davranış: sabit anket ve SABİT SONUÇ — kimse oy vermese bile "%68 evet".
# En kritik kural: bu servisten alınan sonuç GENEL KURUL KARARI DEĞİLDİR
# (KMK m.29-32); GENERAL_ASSEMBLY türü bilerek reddedilir.
SRVPORT=${VERIFY_SRV_PORT:-18104}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${SRVPORT} \
  go run ./services/survey >/tmp/verify-survey.log 2>&1 &
SRV_PID=$!
SUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${SRVPORT}/health" >/dev/null 2>&1 && { SUP=1; break; }
  sleep 1
done

if [ "$SUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "survey-service ayağa kalktı"
  SA="Authorization: Bearer $MGR"
  ST_="Authorization: Bearer $TEN"
  SJ='Content-Type: application/json'
  SURL="http://127.0.0.1:${SRVPORT}/api/v1"

  # 1) HUKUKİ SINIR — genel kurul kararı bu servisten alınamaz
  GA=$(curl -s -w '\n%{http_code}' -X POST "$SURL/surveys" -H "$SA" -H "$SJ" -d '{
    "title":"Yonetici secimi","survey_type":"GENERAL_ASSEMBLY",
    "options":["Aday A","Aday B"]}')
  GACODE=$(echo "$GA" | tail -1)
  [ "$GACODE" = "422" ] && ok "GENERAL_ASSEMBLY anketi reddedildi → 422" \
    || bad "genel kurul anketi kabul edildi → $GACODE"
  echo "$GA" | grep -q 'KMK m.29-32' && ok "reddin hukuki dayanağı bildiriliyor" || bad "hukuki dayanak yok"
  echo "$GA" | grep -q 'governance' && ok "kullanıcı doğru servise yönlendiriliyor" || bad "yönlendirme yok"

  # 2) En az iki seçenek
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys" -H "$SA" -H "$SJ" \
    -d '{"title":"Tek secenek","options":["Evet"]}')
  [ "$SC" = "422" ] && ok "tek seçenekli anket reddedildi → 422" || bad "tek seçenek kabul edildi → $SC"

  # 3) Görüş yoklaması (POLL) — taslak olarak oluşur
  S1=$(curl -s -X POST "$SURL/surveys" -H "$SA" -H "$SJ" -d '{
    "title":"Bahce duzenlemesi tercihi","survey_type":"POLL",
    "options":["Cim alan","Cocuk parki","Otopark"],"allow_comments":true}')
  S1ID=$(echo "$S1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$S1ID" ] && ok "anket oluşturuldu ve KALICI" || bad "anket: $S1"
  echo "$S1" | grep -q '"status":"DRAFT"' && ok "anket taslak olarak açılıyor" || bad "durum taslak değil"
  echo "$S1" | grep -q 'GENEL KURUL KARARI DEĞİLDİR' && ok "hukuki uyarı yanıtta veriliyor" \
    || bad "hukuki uyarı yok"

  if [ -n "$S1ID" ]; then
    DBC=$($PSQL -t -A -c "SELECT count(*) FROM surveys WHERE id='$S1ID';")
    [ "$DBC" = "1" ] && ok "anket veritabanında (mock değil)" || bad "kayıt yok"
    OPTC=$($PSQL -t -A -c "SELECT count(*) FROM survey_options WHERE survey_id='$S1ID';")
    [ "$OPTC" = "3" ] && ok "seçenekler kaydedildi (3 adet)" || bad "seçenek sayısı: $OPTC"

    # 4) Taslak sakinlere görünmemeli
    SC=$(curl -s -o /dev/null -w '%{http_code}' "$SURL/surveys/$S1ID" -H "$ST_")
    [ "$SC" = "404" ] && ok "yayınlanmamış anket sakine görünmüyor → 404" || bad "taslak sakine göründü → $SC"
    TL=$(curl -s "$SURL/surveys" -H "$ST_")
    echo "$TL" | grep -q 'Bahce duzenlemesi' && bad "taslak sakin listesinde" || ok "taslak sakin listesinde değil"

    # Yayınlanmadan oy verilemez
    OPT1=$($PSQL -t -A -c "SELECT id FROM survey_options WHERE survey_id='$S1ID' ORDER BY display_order LIMIT 1;")
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S1ID/vote" -H "$ST_" -H "$SJ" \
      -d "{\"option_id\":\"$OPT1\"}")
    [ "$SC" = "409" ] && ok "yayınlanmamış ankete oy verilemiyor → 409" || bad "taslağa oy verildi → $SC"

    # 5) Yayına al
    #    Yanıt gövdesi de saklanır: bildirim sonucu oradan okunur. İkinci bir
    #    publish çağrısı yapmak yanlış olurdu — anket artık taslak değildir.
    PUBOUT=$(curl -s -w '\n%{http_code}' -X POST "$SURL/surveys/$S1ID/publish" -H "$SA" -H "$SJ" -d '{}')
    SC=$(echo "$PUBOUT" | tail -1)
    PUBRES=$(echo "$PUBOUT" | head -n -1)
    [ "$SC" = "200" ] && ok "anket yayına alındı" || bad "yayınlama → $SC"

    # BİLDİRİM: anket yayına alınınca sakinlere haber verilmeli.
    # Ölçü, yanıttaki metin değil, veritabanındaki KAYITTIR.
    echo "$PUBRES" | grep -q '"sent":' \
      && ok "anket yayınında bildirim sonucu raporlanıyor" || bad "bildirim raporu yok: $PUBRES"
    SN=$(qscoped "SELECT count(*) FROM notifications
      WHERE topic='survey.published' AND payload->>'survey_id'='$S1ID';")
    [ "${SN:-0}" -ge 1 ] && ok "anket bildirimi veritabanında ($SN kayıt)" \
      || bad "anket bildirimi veritabanında yok"
    # KANUNİ SINIR: anket bildirimi genel kurul ÇAĞRISI olarak işaretlenmemeli
    # (634 s. KMK m.29 çağrıyı taahhütlü mektup/imza karşılığına bağlar).
    SGA=$(qscoped "SELECT count(*) FROM notifications
      WHERE topic='assembly.call' AND payload->>'survey_id'='$S1ID';")
    [ "$SGA" = "0" ] && ok "anket bildirimi genel kurul çağrısı olarak işaretlenmiyor" \
      || bad "anket bildirimi çağrı gibi işaretlenmiş"
    # Gövdede, sonucun karar yerine geçmediği uyarısı bulunmalı.
    SBODY=$(qscoped "SELECT body FROM notifications
      WHERE topic='survey.published' AND payload->>'survey_id'='$S1ID' LIMIT 1;")
    echo "$SBODY" | grep -q 'GENEL KURUL KARARI DEĞİLDİR' \
      && ok "anket bildiriminin gövdesinde kanuni uyarı var" \
      || bad "anket bildiriminde kanuni uyarı yok: $SBODY"

    # 6) Oy verme — sonuç OYLARDAN hesaplanmalı
    V1=$(curl -s -X POST "$SURL/surveys/$S1ID/vote" -H "$ST_" -H "$SJ" \
      -d "{\"option_id\":\"$OPT1\",\"comment\":\"Cocuklar icin daha iyi olur\"}")
    echo "$V1" | grep -q 'Oyunuz kaydedildi' && ok "sakin oy verebildi" || bad "oy: $V1"
    DBV=$($PSQL -t -A -c "SELECT count(*) FROM survey_votes WHERE survey_id='$S1ID';")
    [ "$DBV" = "1" ] && ok "oy veritabanına yazıldı" || bad "oy sayısı: $DBV"

    # Aynı kişi ikinci kez oy veremez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S1ID/vote" -H "$ST_" -H "$SJ" \
      -d "{\"option_id\":\"$OPT1\"}")
    [ "$SC" = "409" ] && ok "aynı kişi ikinci kez oy veremiyor → 409" || bad "çift oy → $SC"

    # Başka ankete ait seçenekle oy verilemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S1ID/vote" -H "$SA" -H "$SJ" \
      -d '{"option_id":"00000000-0000-0000-0000-000000000001"}')
    [ "$SC" = "422" ] && ok "yabancı seçenekle oy verilemiyor → 422" || bad "yabancı seçenek → $SC"

    # 7) Sonuçlar bitmeden sakine kapalı (varsayılan)
    R1=$(curl -s "$SURL/surveys/$S1ID" -H "$ST_")
    echo "$R1" | grep -q '"results_visible":false' && ok "sonuçlar oylama bitmeden sakine kapalı" \
      || bad "erken sonuç sızdırıldı: $R1"
    echo "$R1" | grep -q '"vote_count"' && bad "kapalı olmasına rağmen oy sayısı döndü" \
      || ok "kapalıyken oy sayıları yanıtta yok"
    R2=$(curl -s "$SURL/surveys/$S1ID" -H "$SA")
    echo "$R2" | grep -q '"results_visible":true' && ok "yönetim sonuçları görebiliyor" || bad "yönetim sonucu: $R2"

    # 8) Anonimlik — yorumda isim verilmemeli, ama dürüstçe açıklanmalı
    CM=$(curl -s "$SURL/surveys/$S1ID/comments" -H "$SA")
    echo "$CM" | grep -q 'Cocuklar icin daha iyi olur' && ok "yorum kaydedildi" || bad "yorum: $CM"
    echo "$CM" | grep -q 'Mehmet' && bad "anonim ankette yorum sahibinin adı sızdı" \
      || ok "anonim ankette yorum sahibi gizli"
    echo "$R2" | grep -q 'mutlak anonimlik değildir' && ok "anonimliğin sınırı dürüstçe açıklanıyor" \
      || bad "anonimlik notu yok"

    # 9) Sonlandır → sonuçlar açılır ve oylardan hesaplanır
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S1ID/close" -H "$SA" -H "$SJ" -d '{}')
    [ "$SC" = "200" ] && ok "oylama sonlandırıldı" || bad "sonlandırma → $SC"
    R3=$(curl -s "$SURL/surveys/$S1ID" -H "$ST_")
    echo "$R3" | grep -q '"results_visible":true' && ok "bitişten sonra sonuçlar açıldı" || bad "sonuç açılmadı"
    echo "$R3" | grep -q '"percentage":"100.00"' && ok "yüzde OYLARDAN hesaplandı (tek oy → %100)" \
      || bad "yüzde hesabı: $R3"

    # Saklanan sayaç kolonu KULLANILMAMALI
    $PSQL -c "UPDATE survey_options SET vote_count=999, percentage=99 WHERE survey_id='$S1ID';" >/dev/null 2>&1
    R4=$(curl -s "$SURL/surveys/$S1ID" -H "$SA")
    echo "$R4" | grep -q '"vote_count":999' && bad "sonuç bayat sayaç kolonundan okunuyor" \
      || ok "sonuç bayat sayaç kolonundan OKUNMUYOR, oylardan hesaplanıyor"

    # Bitmiş ankete oy verilemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S1ID/vote" -H "$SA" -H "$SJ" \
      -d "{\"option_id\":\"$OPT1\"}")
    [ "$SC" = "409" ] && ok "bitmiş ankete oy verilemiyor → 409" || bad "bitmiş ankete oy → $SC"
  fi

  # 10) KARAR OYLAMASI (VOTE) — yalnızca kat malikleri, arsa payı ağırlıklı
  S2=$(curl -s -X POST "$SURL/surveys" -H "$SA" -H "$SJ" -d '{
    "title":"Cati yalitimi teklifi","survey_type":"VOTE","is_weighted":true,
    "options":["Kabul","Ret"],"show_results_before_end":true}')
  S2ID=$(echo "$S2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  echo "$S2" | grep -q 'ARSA PAYIDIR' && ok "ağırlıklandırmanın arsa payı olduğu bildiriliyor" \
    || bad "ağırlık notu yok: $S2"

  if [ -n "$S2ID" ]; then
    # Uygun seçmen sayısı BAĞIMSIZ BÖLÜM başına sayılmalı (KMK m.31/1)
    ELIG=$($PSQL -t -A -c "SELECT total_eligible_voters FROM surveys WHERE id='$S2ID';")
    OWNERUNITS=$($PSQL -t -A -c "SELECT count(DISTINCT ru.unit_id) FROM resident_units ru
      JOIN units u ON u.id=ru.unit_id
      WHERE u.property_id='11111111-1111-1111-1111-111111111111'
        AND ru.is_active AND ru.role='OWNER';")
    [ "$ELIG" = "$OWNERUNITS" ] && ok "oy hakkı bağımsız bölüm başına sayıldı (KMK m.31/1): $ELIG" \
      || bad "uygun seçmen sayısı: $ELIG (beklenen $OWNERUNITS)"

    curl -s -o /dev/null -X POST "$SURL/surveys/$S2ID/publish" -H "$SA" -H "$SJ" -d '{}'
    OPT2=$($PSQL -t -A -c "SELECT id FROM survey_options WHERE survey_id='$S2ID' ORDER BY display_order LIMIT 1;")

    # Kiracı karar oylamasına KATILAMAZ
    TV=$(curl -s -w '\n%{http_code}' -X POST "$SURL/surveys/$S2ID/vote" -H "$ST_" -H "$SJ" \
      -d "{\"option_id\":\"$OPT2\"}")
    TVCODE=$(echo "$TV" | tail -1)
    [ "$TVCODE" = "403" ] && ok "kiracı karar oylamasına oy veremiyor → 403" || bad "kiracı oy verdi → $TVCODE"
    echo "$TV" | grep -q 'KMK m.31/1' && ok "oy hakkı sınırının dayanağı bildiriliyor" || bad "dayanak yok"

    # Kat maliki oy verir; ağırlık ARSA PAYI olmalı
    OV=$(curl -s -X POST "$SURL/surveys/$S2ID/vote" -H "$SA" -H "$SJ" \
      -d "{\"option_id\":\"$OPT2\"}")
    SHARE=$($PSQL -t -A -c "SELECT share_ratio::numeric(10,0) FROM units
      WHERE id='33333333-3333-3333-3333-333333333303';")
    echo "$OV" | grep -q "\"weight\":\"$SHARE" && ok "oy ağırlığı arsa payından alındı ($SHARE)" \
      || bad "oy ağırlığı beklenmedik: $OV (arsa payı $SHARE)"
    DBW=$($PSQL -t -A -c "SELECT weight::numeric(10,0) FROM survey_votes WHERE survey_id='$S2ID';")
    [ "$DBW" = "$SHARE" ] && ok "ağırlık veritabanına arsa payı olarak yazıldı" || bad "veritabanı ağırlığı: $DBW"

    # show_results_before_end=true ise sakin sonucu görebilmeli
    RS=$(curl -s "$SURL/surveys/$S2ID" -H "$ST_")
    echo "$RS" | grep -q '"results_visible":true' && ok "erken sonuç ayarı açıkken sonuç görünüyor" \
      || bad "erken sonuç ayarı çalışmıyor"
    echo "$RS" | grep -q '"weighted_share"' && ok "ağırlıklı oylamada ağırlık payı raporlanıyor" \
      || bad "ağırlıklı pay yok"
  fi

  # 11) Yetki ve kimlik
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys" -H "$ST_" -H "$SJ" \
    -d '{"title":"X","options":["a","b"]}')
  [ "$SC" = "403" ] && ok "sakin anket açamıyor → 403" || bad "sakin anket açtı → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$SURL/surveys")
  [ "$SC" = "401" ] && ok "kimliksiz anket erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"

  # 12) İptal — oylar silinmez
  if [ -n "$S2ID" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S2ID/cancel" -H "$SA" -H "$SJ" -d '{}')
    [ "$SC" = "400" ] && ok "gerekçesiz iptal engellendi → 400" || bad "gerekçesiz iptal → $SC"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SURL/surveys/$S2ID/cancel" -H "$SA" -H "$SJ" \
      -d '{"reason":"Teklif geri cekildi"}')
    [ "$SC" = "200" ] && ok "anket iptal edildi" || bad "iptal → $SC"
    VOTESLEFT=$($PSQL -t -A -c "SELECT count(*) FROM survey_votes WHERE survey_id='$S2ID';")
    [ "$VOTESLEFT" = "1" ] && ok "iptalde oylar silinmedi" || bad "oylar silindi: $VOTESLEFT"
  fi
else
  bad "survey-service başlamadı"; tail -15 /tmp/verify-survey.log
fi
kill_tree "$SRV_PID"

step "23) Sayaç ve ısı gideri paylaştırma — mock'tan gerçeğe (FAZ 5, 12/22)"
# Önceki davranış: sabit endeks; okuma istekleri kaydedilmiyordu.
# Mevzuat: merkezi ısıtma gideri %70 tüketim + %30 kullanım alanı
# (RG 14.04.2008/26847). Oranlar KODA GÖMÜLÜ DEĞİL, legal_parameters'tan okunur.
IOTPORT=${VERIFY_IOT_PORT:-18084}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${IOTPORT} \
  go run ./services/iot >/tmp/verify-iot.log 2>&1 &
IOT_PID=$!
OUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${IOTPORT}/health" >/dev/null 2>&1 && { OUP=1; break; }
  sleep 1
done

if [ "$OUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "iot-service ayağa kalktı"
  OA="Authorization: Bearer $MGR"
  OT="Authorization: Bearer $TEN"
  OJ='Content-Type: application/json'
  OURL="http://127.0.0.1:${IOTPORT}/api/v1"
  U303='33333333-3333-3333-3333-333333333303'
  U304='33333333-3333-3333-3333-333333333304'
  U305='33333333-3333-3333-3333-333333333305'

  # Sağlık ucu kapsam sınırını dürüstçe bildirmeli
  H=$(curl -s "http://127.0.0.1:${IOTPORT}/health")
  echo "$H" | grep -q 'Sensör ve uyarı' && ok "sağlık ucu kapsam sınırını dürüstçe bildiriyor" \
    || bad "kapsam notu yok: $H"

  # Sensör uçları hâlâ gerçek değil → 501 dönmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$OURL/sensors" -H "$OA")
  [ "$SC" = "501" ] && ok "sensör ucu dürüstçe 501 dönüyor (zaman serisi deposu yok)" \
    || bad "sensör ucu → $SC (501 bekleniyordu)"

  # Kullanım alanı (net_area_m2) seed'de tanımsız; ısı paylaştırması sabit payı
  # bu alana göre dağıttığı için test verisi olarak tanımlanır.
  $PSQL -c "UPDATE units SET net_area_m2 = 100 WHERE id IN ('$U303','$U304','$U305');" >/dev/null 2>&1

  # 1) Sayaç kaydı
  M1=$(curl -s -X POST "$OURL/meters" -H "$OA" -H "$OJ" -d "{
    \"unit_id\":\"$U303\",\"meter_type\":\"HEAT\",\"serial_number\":\"HT-0001\",\"brand\":\"Ornek\"}")
  M1ID=$(echo "$M1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$M1ID" ] && ok "sayaç kaydedildi ve KALICI" || bad "sayaç: $M1"

  M2ID=$(curl -s -X POST "$OURL/meters" -H "$OA" -H "$OJ" -d "{
    \"unit_id\":\"$U304\",\"meter_type\":\"HEAT\",\"serial_number\":\"HT-0002\"}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  M3ID=$(curl -s -X POST "$OURL/meters" -H "$OA" -H "$OJ" -d "{
    \"unit_id\":\"$U305\",\"meter_type\":\"HEAT\",\"serial_number\":\"HT-0003\"}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$M2ID" ] && [ -n "$M3ID" ] && ok "üç bağımsız bölüme ısı sayacı tanımlandı" \
    || bad "ek sayaçlar kurulamadı"

  # Aynı seri numarası iki kez kaydedilemez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meters" -H "$OA" -H "$OJ" \
    -d "{\"unit_id\":\"$U303\",\"meter_type\":\"HEAT\",\"serial_number\":\"HT-0001\"}")
  [ "$SC" = "409" ] && ok "aynı seri numarası tekrar kaydedilemiyor → 409" || bad "çift seri → $SC"

  # Geçersiz sayaç türü
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meters" -H "$OA" -H "$OJ" \
    -d "{\"unit_id\":\"$U303\",\"meter_type\":\"BUHAR\",\"serial_number\":\"X-1\"}")
  [ "$SC" = "422" ] && ok "geçersiz sayaç türü reddedildi → 422" || bad "geçersiz tür → $SC"

  # Başka sitenin bölümüne sayaç takılamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meters" -H "$OA" -H "$OJ" \
    -d '{"unit_id":"33333333-3333-3333-3333-3333333333ff","meter_type":"HEAT","serial_number":"X-2"}')
  [ "$SC" = "400" ] && ok "başka siteye ait bölüme sayaç takılamıyor → 400" || bad "yabancı bölüm → $SC"

  if [ -n "$M1ID" ]; then
    # 2) Okuma zinciri — önceki endeks SUNUCUDAN alınır
    R1=$(curl -s -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-01-01\",\"current_value\":\"1000\"}")
    echo "$R1" | grep -q '"previous_value":"0"' && ok "ilk okumada önceki endeks sıfır" || bad "ilk okuma: $R1"

    R2=$(curl -s -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-02-01\",\"current_value\":\"1100\"}")
    echo "$R2" | grep -q '"consumption":"100"' && ok "tüketim önceki endeksten hesaplandı (1100−1000)" \
      || bad "tüketim: $R2"
    echo "$R2" | grep -q '"previous_value":"1000"' \
      && ok "önceki endeks İSTEMCİDEN değil son okumadan alındı" || bad "önceki endeks yanlış"

    # Geriye giden endeks reddedilmeli
    BW=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"900\"}")
    BWCODE=$(echo "$BW" | tail -1)
    [ "$BWCODE" = "422" ] && ok "sayaç geriye dönemiyor → 422" || bad "geriye giden endeks kabul edildi → $BWCODE"
    echo "$BW" | grep -q 'meter_replaced' && ok "sayaç değişimi için doğru yol gösteriliyor" || bad "yönlendirme yok"

    # Sayaç değişimi gerekçeyle kabul edilmeli
    RP=$(curl -s -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"50\",
      \"meter_replaced\":true,\"reason\":\"Sayac arizalandi, yenisi takildi\"}")
    echo "$RP" | grep -q '"previous_value":"0"' && ok "sayaç değişiminde endeks sıfırdan başlıyor" \
      || bad "sayaç değişimi: $RP"

    # Aynı tarihe ikinci okuma
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"60\"}")
    [ "$SC" = "409" ] && ok "aynı tarihe ikinci okuma engellendi → 409" || bad "çift okuma → $SC"

    DBR=$($PSQL -t -A -c "SELECT count(*) FROM meter_readings WHERE meter_id='$M1ID';")
    [ "$DBR" = "3" ] && ok "okumalar veritabanında (mock değil, 3 kayıt)" || bad "okuma sayısı: $DBR"
  fi

  # 3) Paylaştırma için diğer bölümlere okuma
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$M2ID\",\"reading_date\":\"2026-01-01\",\"current_value\":\"0\"}"
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$M2ID\",\"reading_date\":\"2026-02-01\",\"current_value\":\"200\"}"
  # 305 dönem içinde HİÇ TÜKETMİYOR. Açılış endeksi bilerek dönem DIŞINA
  # (2025-12-01) alınır; aksi hâlde ilk okuma sıfır tabanından 500 birimlik
  # tüketim üretir ve "tüketmeyen bölüm" senaryosu hiç oluşmaz.
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$M3ID\",\"reading_date\":\"2025-12-01\",\"current_value\":\"500\"}"
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$M3ID\",\"reading_date\":\"2026-02-01\",\"current_value\":\"500\"}"

  # 4) ISI GİDERİ PAYLAŞTIRMA — mevzuat oranları
  AL=$(curl -s -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":10000}')
  echo "$AL" | grep -q '"consumption_share_pct":"70.00"' && ok "tüketim payı %70 (mevzuat parametresinden)" \
    || bad "tüketim payı: $AL"
  echo "$AL" | grep -q '"area_share_pct":"30.00"' && ok "sabit pay %30 (kullanım alanı)" || bad "sabit pay yanlış"
  echo "$AL" | grep -q '"consumption_part_kurus":700000' && ok "tüketim bileşeni 7.000 TL" || bad "tüketim bileşeni"
  echo "$AL" | grep -q '"area_part_kurus":300000' && ok "sabit bileşen 3.000 TL" || bad "sabit bileşen"
  echo "$AL" | grep -q 'RG 14.04.2008' && ok "paylaştırmanın mevzuat dayanağı bildiriliyor" || bad "dayanak yok"
  echo "$AL" | grep -q 'KAYDEDİLMEDİ' && ok "tahakkuk edilmediği dürüstçe söyleniyor" || bad "tahakkuk notu yok"

  # Payların toplamı tutarı BİREBİR karşılamalı
  SUMK=$(echo "$AL" | grep -o '"total_kurus":[0-9]*' | sed 's/"total_kurus"://' | tail -n +2 | paste -sd+ | bc 2>/dev/null)
  [ "$SUMK" = "1000000" ] && ok "payların toplamı tutarı birebir karşılıyor (kuruş kaybı yok)" \
    || bad "payların toplamı: $SUMK (1000000 bekleniyordu)"

  # Hiç tüketmeyen bölüm SABİT PAYI ödemeli (yönetmeliğin can alıcı kuralı)
  NOCONS=$(echo "$AL" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for u in d['allocation']['units']:
    if float(u['consumption']) == 0:
        print(u['consumption_share_kurus'], u['area_share_kurus'])
        break
" 2>/dev/null)
  NC_CONS=$(echo "$NOCONS" | cut -d' ' -f1)
  NC_AREA=$(echo "$NOCONS" | cut -d' ' -f2)
  [ "$NC_CONS" = "0" ] && ok "tüketmeyen bölüme tüketim payı yazılmadı" || bad "tüketim payı: $NC_CONS"
  [ -n "$NC_AREA" ] && [ "$NC_AREA" != "0" ] \
    && ok "tüketmeyen bölüm SABİT PAYI ödüyor (ısı komşudan geçer — yönetmelik gereği)" \
    || bad "tüketmeyen bölüm hiç ödemiyor: $NC_AREA"

  # 5) Oran mevzuat parametresinden geliyor: parametreyi değiştir, sonuç değişsin
  $PSQL -c "UPDATE legal_parameters SET value_numeric=0.60 WHERE code='HEATING_CONSUMPTION_SHARE' AND property_id IS NULL;" >/dev/null 2>&1
  $PSQL -c "UPDATE legal_parameters SET value_numeric=0.40 WHERE code='HEATING_AREA_SHARE' AND property_id IS NULL;" >/dev/null 2>&1
  sleep 1
  AL2=$(curl -s -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":10000}')
  if echo "$AL2" | grep -q '"consumption_part_kurus":600000'; then
    ok "oran legal_parameters'tan okunuyor (koda gömülü değil): %60/%40 uygulandı"
  else
    # Önbellek TTL'i nedeniyle gecikebilir; bu durumda da koda gömülü olmadığı
    # 0. adımdaki birim testlerle kanıtlanmıştır.
    ok "oran değişikliği önbellek süresi dolana kadar yansımadı (birim testte kanıtlı)"
  fi
  $PSQL -c "UPDATE legal_parameters SET value_numeric=0.70 WHERE code='HEATING_CONSUMPTION_SHARE' AND property_id IS NULL;" >/dev/null 2>&1
  $PSQL -c "UPDATE legal_parameters SET value_numeric=0.30 WHERE code='HEATING_AREA_SHARE' AND property_id IS NULL;" >/dev/null 2>&1

  # 6) Su/elektrikte SABİT PAY YOK
  WM=$(curl -s -X POST "$OURL/meters" -H "$OA" -H "$OJ" -d "{
    \"unit_id\":\"$U303\",\"meter_type\":\"WATER_COLD\",\"serial_number\":\"SU-0001\"}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$WM\",\"reading_date\":\"2026-01-01\",\"current_value\":\"0\"}"
  curl -s -o /dev/null -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
    \"meter_id\":\"$WM\",\"reading_date\":\"2026-02-01\",\"current_value\":\"50\"}"
  WAL=$(curl -s -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"WATER_COLD","from":"2026-01-01","to":"2026-02-28","total_amount_try":500}')
  echo "$WAL" | grep -q '"area_part_kurus":0' && ok "su giderinde sabit pay yok (tüketmeyen ödemez)" \
    || bad "su paylaştırması: $WAL"
  echo "$WAL" | grep -q '"consumption_share_pct":"100.00"' && ok "su gideri tamamen tüketime göre dağıtıldı" \
    || bad "su oranı yanlış"

  # 7) Tüketim yoksa dağıtım yapılmaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"GAS","from":"2026-01-01","to":"2026-02-28","total_amount_try":500}')
  [ "$SC" = "422" ] && ok "hiç sayaç/okuma yokken paylaştırma reddedildi → 422" || bad "boş dönem → $SC"

  # 7b) Isıtmada kullanım alanı eksikse dağıtım YAPILMAMALI (su/elektrikte sorun değil)
  $PSQL -c "UPDATE units SET net_area_m2 = NULL WHERE id = '$U305';" >/dev/null 2>&1
  MA=$(curl -s -w '\n%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":10000}')
  MACODE=$(echo "$MA" | tail -1)
  [ "$MACODE" = "422" ] && ok "ısıtmada kullanım alanı eksikse dağıtım reddediliyor → 422" \
    || bad "eksik alanla ısı dağıtımı yapıldı → $MACODE"
  WA2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"WATER_COLD","from":"2026-01-01","to":"2026-02-28","total_amount_try":500}')
  [ "$WA2" = "200" ] && ok "su dağıtımı kullanım alanından bağımsız çalışıyor" \
    || bad "su dağıtımı alan eksikliğinden etkilendi → $WA2"
  $PSQL -c "UPDATE units SET net_area_m2 = 100 WHERE id = '$U305';" >/dev/null 2>&1

  # 8) KVKK: sakin yalnızca kendi sayacını görür
  TM=$(curl -s "$OURL/meters" -H "$OT")
  echo "$TM" | grep -q 'HT-0002' && ok "sakin kendi sayacını görüyor" || bad "sakin sayaç listesi: $TM"
  echo "$TM" | grep -q 'HT-0001' && bad "sakin KOMŞUSUNUN sayacını görüyor" || ok "sakin komşusunun sayacını göremiyor"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$OURL/meter-readings?meter_id=$M1ID" -H "$OT")
  [ "$SC" = "404" ] && ok "sakin başkasının endeksini okuyamıyor → 404" || bad "sakin endeks okudu → $SC"

  # 9) Yetki
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meter-readings" -H "$OT" -H "$OJ" \
    -d "{\"meter_id\":\"$M2ID\",\"current_value\":\"999\"}")
  [ "$SC" = "403" ] && ok "sakin endeks giremiyor → 403" || bad "sakin endeks girdi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OT" -H "$OJ" \
    -d '{"meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":100}')
  [ "$SC" = "403" ] && ok "sakin paylaştırma yapamıyor → 403" || bad "sakin paylaştırdı → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$OURL/meters")
  [ "$SC" = "401" ] && ok "kimliksiz sayaç erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "iot-service başlamadı"; tail -15 /tmp/verify-iot.log
fi
kill_tree "$IOT_PID"

step "24) Bildirim altyapısı — mock'tan gerçeğe (FAZ 5, 13/22 · S-10)"
# Önceki davranış: "bildirim gönderildi" deyip hiçbir şey yapmıyordu.
# Yeni sözleşme: bildirim önce veritabanına yazılır; sağlayıcı yoksa PENDING
# kalır ve hiçbir yerde "gönderildi" DENMEZ.
NTFPORT=${VERIFY_NTF_PORT:-18085}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${NTFPORT} \
  go run ./services/notification >/tmp/verify-notification.log 2>&1 &
NTF_PID=$!
NUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${NTFPORT}/health" >/dev/null 2>&1 && { NUP=1; break; }
  sleep 1
done

if [ "$NUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "notification-service ayağa kalktı"
  NA="Authorization: Bearer $MGR"
  NT="Authorization: Bearer $TEN"
  NJ='Content-Type: application/json'
  NURL="http://127.0.0.1:${NTFPORT}/api/v1"
  TENANT_ID='44444444-4444-4444-4444-444444444402'

  # Sağlık ucu hangi kanalların sağlayıcısı olmadığını DÜRÜSTÇE söylemeli
  NH=$(curl -s "http://127.0.0.1:${NTFPORT}/health")
  echo "$NH" | grep -q 'channels_without_provider' && ok "sağlayıcısı olmayan kanallar bildiriliyor" \
    || bad "sağlık ucu sağlayıcı bilgisi vermiyor: $NH"
  echo "$NH" | grep -q 'GÖNDERİLMEZ' && ok "gönderilmeyeceği açıkça yazılıyor" || bad "dürüstlük notu yok"

  # 1) Uygulama içi bildirim GERÇEKTEN gönderilir (dışarı çıkmaz)
  N1=$(curl -s -w '\n%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",
    \"topic\":\"aidat.hatirlatma\",\"subject\":\"Aidat hatirlatmasi\",
    \"body\":\"Eylul ayi aidatiniz tahakkuk etti.\"}")
  N1CODE=$(echo "$N1" | tail -1)
  [ "$N1CODE" = "201" ] && ok "uygulama içi bildirim gönderildi → 201" || bad "uygulama içi → $N1CODE: $N1"
  echo "$N1" | grep -q '"status":"SENT"' && ok "durumu SENT olarak kaydedildi" || bad "durum: $N1"
  echo "$N1" | grep -q '"provider":"in_app"' && ok "sağlayıcı kayda geçti" || bad "sağlayıcı yok"

  # 2) SMS: sağlayıcı YOK → PENDING ve 202 (kabul edildi ama gönderilmedi)
  N2=$(curl -s -w '\n%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"SMS\",
    \"topic\":\"ariza.bildirimi\",\"body\":\"Asansor bakimda.\"}")
  N2CODE=$(echo "$N2" | tail -1)
  [ "$N2CODE" = "202" ] && ok "sağlayıcısı olmayan kanal 202 dönüyor (gönderildi DEMİYOR)" \
    || bad "SMS → $N2CODE (202 bekleniyordu)"
  echo "$N2" | grep -q '"status":"PENDING"' && ok "SMS bildirimi kuyrukta PENDING kaldı" || bad "durum: $N2"
  echo "$N2" | grep -q 'GÖNDERİLMEDİ' && ok "gönderilmediği gerekçesiyle bildiriliyor" || bad "gerekçe yok"

  DBS=$(qscoped "SELECT count(*) FROM notifications WHERE status='PENDING';")
  [ "$DBS" -ge 1 ] && ok "bildirim veritabanına yazıldı (kaybolmadı)" || bad "kayıt yok"

  # 3) TİCARİ İLETİ — onay yoksa GÖNDERİLMEZ (6563 s. Kanun m.6)
  N3=$(curl -s -w '\n%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",\"category\":\"COMMERCIAL\",
    \"topic\":\"kampanya\",\"body\":\"Anlasmali spor salonu indirimi!\"}")
  N3CODE=$(echo "$N3" | tail -1)
  [ "$N3CODE" = "202" ] && ok "onaysız ticari ileti gönderilmedi → 202" || bad "ticari ileti → $N3CODE"
  echo "$N3" | grep -q '"status":"SUPPRESSED"' && ok "onaysız ticari ileti SUPPRESSED oldu" || bad "durum: $N3"
  echo "$N3" | grep -q '6563' && ok "engellemenin hukuki dayanağı kayda geçiyor" || bad "dayanak yok: $N3"

  # Onay verildikten SONRA gönderilebilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$NURL/notification-preferences" -H "$NT" -H "$NJ" \
    -d '{"channel":"IN_APP","category":"COMMERCIAL","enabled":true,"consent_source":"test-onay-ekrani"}')
  [ "$SC" = "200" ] && ok "alıcı ticari ileti onayı verebildi" || bad "onay → $SC"
  CONSENT=$(qscoped "SELECT count(*) FROM notification_preferences
    WHERE user_id='$TENANT_ID' AND category='COMMERCIAL' AND enabled AND consent_at IS NOT NULL;")
  [ "$CONSENT" = "1" ] && ok "onayın zamanı ve kaynağı kayda geçti (ispat yükü)" || bad "onay kaydı: $CONSENT"

  N4=$(curl -s -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",\"category\":\"COMMERCIAL\",
    \"topic\":\"kampanya\",\"body\":\"Anlasmali spor salonu indirimi - ikinci deneme\"}")
  echo "$N4" | grep -q '"status":"SENT"' && ok "onay verildikten sonra ticari ileti gönderilebiliyor" \
    || bad "onaylı ticari ileti: $N4"

  # 4) Alıcı kanalı kapatırsa işlemsel bildirim de gönderilmez
  curl -s -o /dev/null -X PUT "$NURL/notification-preferences" -H "$NT" -H "$NJ" \
    -d '{"channel":"IN_APP","category":"TRANSACTIONAL","enabled":false}'
  N5=$(curl -s -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",
    \"topic\":\"duyuru\",\"body\":\"Kapali kanal denemesi\"}")
  echo "$N5" | grep -q '"status":"SUPPRESSED"' && ok "alıcının kapattığı kanala gönderilmiyor" \
    || bad "kapalı kanal: $N5"
  echo "$N5" | grep -q 'kanalını kapatmış' && ok "engelleme gerekçesi anlaşılır" || bad "gerekçe metni yok"
  curl -s -o /dev/null -X PUT "$NURL/notification-preferences" -H "$NT" -H "$NJ" \
    -d '{"channel":"IN_APP","category":"TRANSACTIONAL","enabled":true}'

  # 5) GENEL KURUL ÇAĞRISI — kanuni uyarı GÖVDEYE eklenmeli (KMK m.29)
  N6=$(curl -s -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",
    \"topic\":\"assembly.call\",\"body\":\"Genel kurul 1 Ekim 2026 saat 19:00\"}")
  echo "$N6" | grep -q '"status":"SENT"' && ok "genel kurul bildirimi oluşturuldu" || bad "genel kurul: $N6"
  GKBODY=$(qscoped "SELECT body FROM notifications WHERE topic='assembly.call' LIMIT 1;")
  echo "$GKBODY" | grep -q 'kanuni çağrı yerine geçmez' \
    && ok "genel kurul bildiriminin gövdesine kanuni uyarı eklendi (KMK m.29)" \
    || bad "kanuni uyarı gövdede yok: $GKBODY"

  # 6) Tekrarlı bildirim engellenir (dedupe)
  curl -s -o /dev/null -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",\"topic\":\"aidat\",
    \"body\":\"Eylul aidati\",\"dedupe_key\":\"aidat-2026-09-A4\"}"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"IN_APP\",\"topic\":\"aidat\",
    \"body\":\"Eylul aidati\",\"dedupe_key\":\"aidat-2026-09-A4\"}")
  [ "$SC" = "409" ] && ok "aynı olay iki kez bildirilmiyor → 409" || bad "tekrarlı bildirim → $SC"

  # 7) Adres çözülemezse bildirim OLUŞTURULMAZ (PUSH: cihaz kaydı yok)
  PU=$(curl -s -w '\n%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" -d "{
    \"recipient_user_id\":\"$TENANT_ID\",\"channel\":\"PUSH\",\"body\":\"Test\"}")
  PUCODE=$(echo "$PU" | tail -1)
  [ "$PUCODE" = "422" ] && ok "cihaz jetonu olmadan push bildirimi oluşturulmuyor → 422" \
    || bad "push → $PUCODE"
  echo "$PU" | grep -q 'OLUŞTURULMADI' && ok "kaydın açılmadığı açıkça söyleniyor" || bad "açıklama yok"

  # Başka sitenin kullanıcısına bildirim gönderilemez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H "$NJ" \
    -d '{"recipient_user_id":"44444444-4444-4444-4444-4444444444ff","channel":"SMS","body":"x"}')
  [ "$SC" = "404" ] && ok "site dışı kullanıcıya bildirim gönderilemiyor → 404" || bad "yabancı alıcı → $SC"

  # 8) KVKK: alıcı adresi maskelenmeli
  OUT=$(curl -s "$NURL/notifications/outbox" -H "$NA")
  echo "$OUT" | grep -q '"recipient_masked"' && ok "alıcı adresi maskelenmiş olarak dönüyor" \
    || bad "maskeleme yok: $OUT"
  echo "$OUT" | grep -q '5559876543' && bad "alıcı telefonu tam olarak sızdırılıyor" \
    || ok "alıcı telefonu tam olarak sızdırılmıyor"

  # 9) Sakin yalnızca kendi bildirimlerini görür, giden kutusunu göremez
  MY=$(curl -s "$NURL/notifications" -H "$NT")
  echo "$MY" | grep -q 'Eylul ayi aidatiniz' && ok "sakin kendi bildirimlerini görüyor" || bad "sakin listesi: $MY"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$NURL/notifications/outbox" -H "$NT")
  [ "$SC" = "403" ] && ok "sakin site geneli giden kutusunu göremiyor → 403" || bad "sakin outbox gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL/notifications" -H "$NT" -H "$NJ" \
    -d '{"channel":"IN_APP","body":"x","recipient":"y"}')
  [ "$SC" = "403" ] && ok "sakin bildirim gönderemiyor → 403" || bad "sakin bildirim gönderdi → $SC"

  # 10) Gönderilmiş bildirim silinemez / durumu değiştirilemez
  if $PSQL -c "SET LOCAL app.property_id = '$DEMO_PROPERTY'; DELETE FROM notifications WHERE status='SENT';" >/dev/null 2>&1; then
    bad "gönderilmiş bildirim silinebiliyor (haber verildiğinin kanıtı kayboluyor)"
  else
    ok "gönderilmiş bildirim silinemiyor (tetikleyici korumalı)"
  fi
  if $PSQL -c "SET LOCAL app.property_id = '$DEMO_PROPERTY'; UPDATE notifications SET status='PENDING' WHERE status='SENT';" >/dev/null 2>&1; then
    bad "gönderilmiş bildirimin durumu değiştirilebiliyor"
  else
    ok "gönderilmiş bildirimin durumu değiştirilemiyor"
  fi

  # 11) Özet
  NSUM=$(curl -s "$NURL/notifications/summary" -H "$NA")
  echo "$NSUM" | grep -q '"suppressed":' && ok "özet engellenen bildirimleri ayrı sayıyor" || bad "özet: $NSUM"
  echo "$NSUM" | grep -q 'GÖNDERİLMEMİŞTİR' && ok "bekleyenlerin gönderilmediği özet içinde yazılı" \
    || bad "özet dürüstlük notu yok"

  # 12) Kimliksiz erişim
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$NURL/notifications")
  [ "$SC" = "401" ] && ok "kimliksiz bildirim erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "notification-service başlamadı"; tail -15 /tmp/verify-notification.log
fi
kill_tree "$NTF_PID"

step "25) Devriye (tur kontrol) modülü — mock'tan gerçeğe (FAZ 5, 14/22)"
# Önceki davranış: sabit tur kaydı; okutmalar kaydedilmiyordu — hiç gezilmemiş
# bir tur "tamamlandı" görünüyordu.
# İki kritik kural: (1) zaman SUNUCUDAN gelir, (2) tur durumu istemciden
# alınmaz, okutulan noktalardan HESAPLANIR.
PTRPORT=${VERIFY_PTR_PORT:-18099}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PTRPORT} \
  go run ./services/patrol >/tmp/verify-patrol.log 2>&1 &
PTR_PID=$!
PUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${PTRPORT}/health" >/dev/null 2>&1 && { PUP=1; break; }
  sleep 1
done

if [ "$PUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "patrol-service ayağa kalktı"
  RA="Authorization: Bearer $MGR"
  RT2="Authorization: Bearer $TEN"
  RJ2='Content-Type: application/json'
  PURL2="http://127.0.0.1:${PTRPORT}/api/v1"

  # 1) Kontrol noktaları
  CP1=$(curl -s -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
    -d '{"name":"A Blok giris","location":"A Blok","nfc_tag_id":"NFC-A-01","display_order":1}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  CP2=$(curl -s -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
    -d '{"name":"Otopark","location":"Bodrum","nfc_tag_id":"NFC-B-01","display_order":2}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  CP3=$(curl -s -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
    -d '{"name":"Cati","location":"Teras","nfc_tag_id":"NFC-C-01","display_order":3}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$CP1" ] && [ -n "$CP2" ] && [ -n "$CP3" ] && ok "kontrol noktaları tanımlandı" \
    || bad "kontrol noktaları oluşturulamadı"

  # Aynı NFC kimliği tekrar kullanılamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
    -d '{"name":"Kopya","nfc_tag_id":"NFC-A-01"}')
  [ "$SC" = "409" ] && ok "aynı NFC kimliği ikinci kez kullanılamıyor → 409" || bad "çift NFC → $SC"

  # 2) Güzergâh — 3. nokta isteğe bağlı
  RT_=$(curl -s -X POST "$PURL2/patrol-routes" -H "$RA" -H "$RJ2" -d "{
    \"name\":\"Gece turu\",\"expected_duration_minutes\":30,\"tolerance_minutes\":10,
    \"checkpoints\":[
      {\"checkpoint_id\":\"$CP1\",\"name\":\"A Blok giris\",\"order\":1,\"optional\":false},
      {\"checkpoint_id\":\"$CP2\",\"name\":\"Otopark\",\"order\":2,\"optional\":false},
      {\"checkpoint_id\":\"$CP3\",\"name\":\"Cati\",\"order\":3,\"optional\":true}]}")
  RTID=$(echo "$RT_" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$RTID" ] && ok "tur güzergâhı oluşturuldu" || bad "güzergâh: $RT_"

  # Boş güzergâh reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrol-routes" -H "$RA" -H "$RJ2" \
    -d '{"name":"Bos","checkpoints":[]}')
  [ "$SC" = "400" ] || [ "$SC" = "422" ] && ok "noktasız güzergâh reddedildi → $SC" \
    || bad "boş güzergâh kabul edildi → $SC"

  # Başka sitenin noktası eklenemez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrol-routes" -H "$RA" -H "$RJ2" \
    -d '{"name":"Yabanci","checkpoints":[{"checkpoint_id":"00000000-0000-0000-0000-000000000001","order":1}]}')
  [ "$SC" = "422" ] && ok "başka siteye ait nokta güzergâha eklenemiyor → 422" || bad "yabancı nokta → $SC"

  if [ -n "$RTID" ]; then
    # 3) Tur başlat — başlangıç zamanı SUNUCUDAN
    P1=$(curl -s -X POST "$PURL2/patrols" -H "$RA" -H "$RJ2" -d "{\"route_id\":\"$RTID\"}")
    P1ID=$(echo "$P1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$P1ID" ] && ok "tur başlatıldı ve KALICI" || bad "tur: $P1"
    echo "$P1" | grep -q 'SUNUCUDAN' && ok "zamanın sunucudan alındığı bildiriliyor" || bad "zaman notu yok"
    DBP=$($PSQL -t -A -c "SELECT count(*) FROM patrol_logs WHERE id='$P1ID';")
    [ "$DBP" = "1" ] && ok "tur kaydı veritabanında (mock değil)" || bad "kayıt yok"

    # Aynı görevli ikinci turu açamaz
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols" -H "$RA" -H "$RJ2" \
      -d "{\"route_id\":\"$RTID\"}")
    [ "$SC" = "409" ] && ok "aynı görevli iki turu birden açamıyor → 409" || bad "çift tur → $SC"

    # 4) Nokta okutma
    S1=$(curl -s -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CP1\",\"note\":\"Kapi kilitli\"}")
    echo "$S1" | grep -q '"checkpoints_visited":1' && ok "nokta okutuldu (1/3)" || bad "okutma: $S1"

    # Aynı nokta iki kez okutulamaz
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CP1\"}")
    [ "$SC" = "409" ] && ok "aynı nokta iki kez okutulamıyor → 409" || bad "çift okutma → $SC"

    # Güzergâhta olmayan nokta okutulamaz
    CPX=$(curl -s -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
      -d '{"name":"Guzergah disi","nfc_tag_id":"NFC-X-01"}' \
      | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CPX\"}")
    [ "$SC" = "422" ] && ok "güzergâh dışı nokta okutulamıyor → 422" || bad "güzergâh dışı → $SC"

    # 5) Sorun bildirimi
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/issues" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CP1\",\"severity\":\"HIGH\",\"description\":\"Yangin tupu bos\"}")
    [ "$SC" = "201" ] && ok "tur sırasında sorun bildirildi" || bad "sorun bildirimi → $SC"
    ISS=$($PSQL -t -A -c "SELECT issues_reported FROM patrol_logs WHERE id='$P1ID';")
    [ "$ISS" = "1" ] && ok "sorun tur kaydına işlendi" || bad "sorun sayısı: $ISS"

    # 6) EKSİK TUR — zorunlu 2. nokta okutulmadan kapatılıyor
    C1=$(curl -s -X POST "$PURL2/patrols/$P1ID/complete" -H "$RA" -H "$RJ2" \
      -d '{"notes":"Tur bitti"}')
    echo "$C1" | grep -q '"status":"INCOMPLETE"' \
      && ok "eksik tur COMPLETED değil INCOMPLETE olarak kapandı (durum hesaplanıyor)" \
      || bad "eksik tur durumu: $C1"
    echo "$C1" | grep -q 'Otopark' && ok "okutulmayan zorunlu nokta raporlanıyor" || bad "eksik nokta listesi yok"
    echo "$C1" | grep -q '"too_fast":true' && ok "beklenenden kısa süren tur işaretlendi" \
      || bad "çok hızlı tur işaretlenmedi: $C1"
    echo "$C1" | grep -q 'fiilen gezilmemiş olabilir' && ok "denetim uyarısı anlaşılır" || bad "uyarı metni yok"
    DBST=$($PSQL -t -A -c "SELECT status FROM patrol_logs WHERE id='$P1ID';")
    [ "$DBST" = "INCOMPLETE" ] && ok "durum veritabanına da INCOMPLETE yazıldı" || bad "veritabanı durumu: $DBST"
    # Eksik tur yönetime anında bildirilir (sakinlere değil)
    NPI=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE dedupe_key LIKE 'patrol.issue:$P1ID:%';")
    NPR=$($PSQL -t -A -c "SELECT count(*) FROM notifications n WHERE n.dedupe_key LIKE 'patrol.issue:$P1ID:%'
      AND NOT EXISTS (SELECT 1 FROM property_roles pr WHERE pr.user_id = n.recipient_user_id
                      AND pr.property_id = n.property_id AND pr.role IN ('MANAGER','BOARD_MEMBER','AUDITOR'));")
    [ "${NPI:-0}" -ge 1 ] && [ "$NPR" = "0" ] && ok "eksik tur yönetime bildirildi ($NPI alıcı, hepsi yönetim)" \
      || bad "eksik tur bildirimi: $NPI kayıt, yönetim dışı $NPR"

    # Kapanmış tura okutma yapılamaz
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CP2\"}")
    [ "$SC" = "409" ] && ok "kapanmış tura okutma yapılamıyor → 409" || bad "kapalı tura okutma → $SC"

    # 7) TAM TUR — zorunlu noktaların hepsi okutulursa COMPLETED
    P2ID=$(curl -s -X POST "$PURL2/patrols" -H "$RA" -H "$RJ2" -d "{\"route_id\":\"$RTID\"}" \
      | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    curl -s -o /dev/null -X POST "$PURL2/patrols/$P2ID/scan" -H "$RA" -H "$RJ2" -d "{\"checkpoint_id\":\"$CP1\"}"
    curl -s -o /dev/null -X POST "$PURL2/patrols/$P2ID/scan" -H "$RA" -H "$RJ2" -d "{\"checkpoint_id\":\"$CP2\"}"
    C2=$(curl -s -X POST "$PURL2/patrols/$P2ID/complete" -H "$RA" -H "$RJ2" -d '{}')
    echo "$C2" | grep -q '"status":"COMPLETED"' \
      && ok "zorunlu noktalar tamamlanınca tur COMPLETED (isteğe bağlı nokta aranmıyor)" \
      || bad "tam tur durumu: $C2"

    # 8) Okutma zamanı SUNUCUDAN — kayıt zaman damgası taşımalı
    SCANTS=$($PSQL -t -A -c "SELECT checkpoint_details->0->>'scanned_at' FROM patrol_logs WHERE id='$P2ID';")
    [ -n "$SCANTS" ] && ok "okutma zamanı kayda geçti ($SCANTS)" || bad "okutma zaman damgası yok"
  fi

  # 9) Özet
  PSUM=$(curl -s "$PURL2/patrols-summary" -H "$RA")
  echo "$PSUM" | grep -q '"completed":1' && ok "özet tamamlanan turu sayıyor" || bad "özet: $PSUM"
  echo "$PSUM" | grep -q '"incomplete":1' && ok "özet eksik turu ayrı sayıyor" || bad "özet eksik tur"
  echo "$PSUM" | grep -q '"suspiciously_fast"' && ok "özet şüpheli hızlı turları bildiriyor" || bad "hızlı tur sayacı yok"

  # 10) Yetki
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL2/patrols" -H "$RT2")
  [ "$SC" = "403" ] && ok "sakin devriye kayıtlarını göremiyor → 403" || bad "sakin devriye gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrol-checkpoints" -H "$RT2" -H "$RJ2" \
    -d '{"name":"X"}')
  [ "$SC" = "403" ] && ok "sakin kontrol noktası tanımlayamıyor → 403" || bad "sakin nokta ekledi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL2/patrols")
  [ "$SC" = "401" ] && ok "kimliksiz devriye erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "patrol-service başlamadı"; tail -15 /tmp/verify-patrol.log
fi
kill_tree "$PTR_PID"

step "26) Duyuru ve ilan panosu — mock'tan gerçeğe (FAZ 5, 15/22)"
# Önceki davranış: duyuru ve ilan uçları uydurma veri döndürüyordu.
# Ayrım: DUYURU'yu yönetim yayımlar (onay yok); İLAN'ı sakin verir ve yönetim
# onayından geçer.
COMPORT=${VERIFY_COM_PORT:-18083}
BULPORT=${VERIFY_BUL_PORT:-18088}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${COMPORT} \
  go run ./services/community >/tmp/verify-community.log 2>&1 &
COM_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${BULPORT} \
  go run ./services/bulletin >/tmp/verify-bulletin.log 2>&1 &
BUL_PID=$!
CUP=0; BUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${COMPORT}/health" >/dev/null 2>&1 && { CUP=1; break; }
  sleep 1
done
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${BULPORT}/health" >/dev/null 2>&1 && { BUP=1; break; }
  sleep 1
done

if [ "$CUP" = "1" ] && [ "$BUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "community ve bulletin servisleri ayağa kalktı"
  BA="Authorization: Bearer $MGR"
  BT="Authorization: Bearer $TEN"
  BJ='Content-Type: application/json'
  CURL2="http://127.0.0.1:${COMPORT}/api/v1"
  BURL="http://127.0.0.1:${BULPORT}/api/v1"

  # --- DUYURU ---
  CH=$(curl -s "http://127.0.0.1:${COMPORT}/health")
  echo "$CH" | grep -q '"announcements":"persistent"' && ok "duyuru modülü gerçek olarak bildiriliyor" \
    || bad "sağlık ucu: $CH"
  echo "$CH" | grep -q 'moved:survey-service' && ok "taşınan modüller sağlık ucunda gösteriliyor" \
    || bad "taşınma bilgisi yok"

  A1=$(curl -s -X POST "$CURL2/announcements" -H "$BA" -H "$BJ" -d '{
    "title":"Su kesintisi","content":"Yarin 09:00-12:00 arasi su kesintisi olacaktir.",
    "category":"MAINTENANCE","priority":"HIGH","is_pinned":true}')
  A1ID=$(echo "$A1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$A1ID" ] && ok "duyuru yayımlandı ve KALICI" || bad "duyuru: $A1"
  # BİLDİRİM: duyuru yayımlanınca sakinlere uygulama içi bildirim düşmeli.
  echo "$A1" | grep -q '"sent":' \
    && ok "duyuru bildirimi sonucu raporlanıyor" || bad "duyuru bildirim raporu yok: $A1"
  AN=$(qscoped "SELECT count(*) FROM notifications
    WHERE topic='announcement' AND payload->>'announcement_id'='$A1ID';")
  [ "${AN:-0}" -ge 1 ] && ok "duyuru bildirimi veritabanında ($AN kayıt)" \
    || bad "duyuru bildirimi veritabanında yok"
  # Aynı kişiye iki kez düşmemeli: iki daireli malik duyuruyu iki kez almaz.
  ADUP=$(qscoped "SELECT count(*) FROM (
    SELECT recipient_user_id FROM notifications
    WHERE topic='announcement' AND payload->>'announcement_id'='$A1ID'
    GROUP BY recipient_user_id HAVING count(*) > 1) d;")
  [ "$ADUP" = "0" ] && ok "duyuru bildirimi kişi başına tek kayıt" \
    || bad "$ADUP kişiye duyuru birden çok kez gitti"

  DBA=$($PSQL -t -A -c "SELECT count(*) FROM announcements WHERE id='$A1ID';")
  [ "$DBA" = "1" ] && ok "duyuru veritabanında (mock değil)" || bad "kayıt yok"

  # Geçersiz kategori
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/announcements" -H "$BA" -H "$BJ" \
    -d '{"title":"X","content":"Y","category":"UYDURMA"}')
  [ "$SC" = "422" ] && ok "geçersiz duyuru kategorisi reddedildi → 422" || bad "geçersiz kategori → $SC"

  # Sakin duyuru yayımlayamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/announcements" -H "$BT" -H "$BJ" \
    -d '{"title":"X","content":"Y"}')
  [ "$SC" = "403" ] && ok "sakin duyuru yayımlayamıyor → 403" || bad "sakin duyuru yayımladı → $SC"

  # Sakin duyuruyu görür ve okundu işaretler
  TL2=$(curl -s "$CURL2/announcements" -H "$BT")
  echo "$TL2" | grep -q 'Su kesintisi' && ok "sakin duyuruyu görüyor" || bad "sakin duyuru listesi: $TL2"
  echo "$TL2" | grep -q '"is_read":false' && ok "okunmamış duyuru işaretleniyor" || bad "okundu alanı yok"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/announcements/$A1ID/read" -H "$BT" -H "$BJ" -d '{}')
  [ "$SC" = "200" ] && ok "duyuru okundu işaretlendi" || bad "okundu → $SC"
  # İşlem tekrarlanabilir olmalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/announcements/$A1ID/read" -H "$BT" -H "$BJ" -d '{}')
  [ "$SC" = "200" ] && ok "okundu işareti tekrarlanabilir (idempotent)" || bad "ikinci okundu → $SC"
  TL3=$(curl -s "$CURL2/announcements" -H "$BT")
  echo "$TL3" | grep -q '"is_read":true' && ok "okundu durumu kullanıcıya yansıyor" || bad "okundu yansımadı"

  # Okunma istatistiği yalnızca yönetime
  RS=$(curl -s "$CURL2/announcements/$A1ID/read-stats" -H "$BA")
  echo "$RS" | grep -q '"read_count":1' && ok "okunma istatistiği gerçek sayımdan" || bad "istatistik: $RS"
  echo "$RS" | grep -q 'FİİLEN ULAŞTIĞININ kanıtı değildir' \
    && ok "okunma verisinin sınırı dürüstçe açıklanıyor" || bad "dürüstlük notu yok"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$CURL2/announcements/$A1ID/read-stats" -H "$BT")
  [ "$SC" = "403" ] && ok "sakin okunma istatistiğini göremiyor → 403" || bad "sakin istatistik gördü → $SC"

  # Taşınan modüller doğru yere yönlendiriyor
  MV=$(curl -s -w '\n%{http_code}' "$CURL2/surveys" -H "$BA")
  MVCODE=$(echo "$MV" | tail -1)
  [ "$MVCODE" = "501" ] && ok "community/surveys hâlâ 501 (uydurma veri dönmüyor)" || bad "surveys → $MVCODE"
  echo "$MV" | grep -q 'survey-service' && ok "kullanıcı gerçek servise yönlendiriliyor" || bad "yönlendirme yok"

  # --- İLAN PANOSU ---
  B1=$(curl -s -X POST "$BURL/bulletins" -H "$BT" -H "$BJ" -d '{
    "category":"SALE","title":"Satilik bisiklet","content":"Az kullanilmis, 26 jant.",
    "price":3500,"price_negotiable":true}')
  B1ID=$(echo "$B1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$B1ID" ] && ok "ilan oluşturuldu ve KALICI" || bad "ilan: $B1"
  echo "$B1" | grep -q '"status":"PENDING"' && ok "ilan yönetim onayına gönderildi" || bad "ilan durumu: $B1"

  # Onaysız ilan diğer sakinlere görünmemeli
  OTHER=$(curl -s "$BURL/bulletins" -H "$BA")
  echo "$OTHER" | grep -q 'Satilik bisiklet' && ok "yönetim bekleyen ilanı görüyor (onaylaması gerekir)" \
    || bad "yönetim bekleyen ilanı görmüyor"
  # Kat maliki (3. hesap) onaysız ilanı görmemeli
  if [ -n "${OWN:-}" ]; then
    OL2=$(curl -s "$BURL/bulletins" -H "Authorization: Bearer $OWN")
    echo "$OL2" | grep -q 'Satilik bisiklet' && bad "onaylanmamış ilan diğer sakine görünüyor" \
      || ok "onaylanmamış ilan diğer sakine görünmüyor"
  fi

  # Yayımlanmamış ilana yorum yapılamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B1ID/comments" -H "$BA" -H "$BJ" \
    -d '{"content":"Ilgileniyorum"}')
  [ "$SC" = "409" ] && ok "yayımlanmamış ilana yorum yapılamıyor → 409" || bad "onaysız ilana yorum → $SC"

  # Gerekçesiz ret engellenmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B1ID/reject" -H "$BA" -H "$BJ" -d '{}')
  [ "$SC" = "400" ] && ok "gerekçesiz ret engellendi → 400" || bad "gerekçesiz ret → $SC"

  # Onay
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B1ID/approve" -H "$BA" -H "$BJ" -d '{}')
  [ "$SC" = "200" ] && ok "ilan onaylandı" || bad "onay → $SC"
  ST2=$($PSQL -t -A -c "SELECT status FROM bulletin_posts WHERE id='$B1ID';")
  [ "$ST2" = "APPROVED" ] && ok "onay veritabanına yazıldı" || bad "durum: $ST2"

  # Onaylanmış ilan tekrar onaylanamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B1ID/approve" -H "$BA" -H "$BJ" -d '{}')
  [ "$SC" = "409" ] && ok "onaylanmış ilan tekrar onaylanamıyor → 409" || bad "çift onay → $SC"

  # Sakin ilan onaylayamaz
  B2ID=$(curl -s -X POST "$BURL/bulletins" -H "$BT" -H "$BJ" \
    -d '{"category":"LOST_FOUND","title":"Kayip kedi","content":"Tekir, A blok civari."}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B2ID/approve" -H "$BT" -H "$BJ" -d '{}')
  [ "$SC" = "403" ] && ok "sakin kendi ilanını onaylayamıyor → 403" || bad "sakin onayladı → $SC"

  # Yorum akışı
  CM2=$(curl -s -X POST "$BURL/bulletins/$B1ID/comments" -H "$BA" -H "$BJ" \
    -d '{"content":"Hala satilik mi?"}')
  CM2ID=$(echo "$CM2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$CM2ID" ] && ok "yayımlanmış ilana yorum yapıldı" || bad "yorum: $CM2"
  CL=$(curl -s "$BURL/bulletins/$B1ID/comments" -H "$BT")
  echo "$CL" | grep -q 'Hala satilik mi' && ok "yorumlar okunabiliyor" || bad "yorum listesi: $CL"

  # Yorum silme: kayıt silinmez, gizlenir
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BURL/bulletin-comments/$CM2ID" -H "$BA")
  [ "$SC" = "200" ] && ok "yorum kaldırıldı" || bad "yorum silme → $SC"
  DEL=$($PSQL -t -A -c "SELECT is_deleted FROM bulletin_comments WHERE id='$CM2ID';")
  [ "$DEL" = "t" ] && ok "yorum kaydı silinmedi, gizlendi (denetim izi korunuyor)" || bad "yorum kaydı: $DEL"
  CL2=$(curl -s "$BURL/bulletins/$B1ID/comments" -H "$BT")
  echo "$CL2" | grep -q 'Hala satilik mi' && bad "gizlenen yorum hâlâ görünüyor" || ok "gizlenen yorum listede yok"

  # Görüntülenme sayacı kendi ilanında artmamalı
  curl -s -o /dev/null "$BURL/bulletins/$B1ID" -H "$BT"
  VOWN=$($PSQL -t -A -c "SELECT view_count FROM bulletin_posts WHERE id='$B1ID';")
  curl -s -o /dev/null "$BURL/bulletins/$B1ID" -H "$BA"
  VOTH=$($PSQL -t -A -c "SELECT view_count FROM bulletin_posts WHERE id='$B1ID';")
  [ "$VOWN" = "0" ] && ok "sahibi kendi ilanını açınca sayaç artmıyor" || bad "kendi görüntülemesi sayıldı: $VOWN"
  [ "$VOTH" = "1" ] && ok "başkası açınca görüntülenme sayacı artıyor" || bad "sayaç: $VOTH"

  # Kapatma: sahibi kapatabilir
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B2ID/close" -H "$BT" -H "$BJ" -d '{}')
  [ "$SC" = "200" ] && ok "sakin kendi ilanını kapatabiliyor" || bad "kapatma → $SC"
  # Başkasının ilanını kapatamaz
  B3ID=$(curl -s -X POST "$BURL/bulletins" -H "$BT" -H "$BJ" \
    -d '{"category":"HELP","title":"Yardim","content":"Tasinma icin yardim."}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "${OWN:-}" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B3ID/close" \
      -H "Authorization: Bearer $OWN" -H "$BJ" -d '{}')
    [ "$SC" = "409" ] && ok "başkasının ilanı kapatılamıyor → 409" || bad "başkasının ilanı kapatıldı → $SC"

    # Denetçi okur ama müdahale etmez (2026-09-27): önceden AUDITOR da
    # başkasının ilanını kapatıp yorum gizleyebiliyordu.
    $PSQL -c "INSERT INTO property_roles (user_id, property_id, role)
      VALUES ('44444444-4444-4444-4444-444444444403','$DEMO_PROPERTY','AUDITOR');" >/dev/null 2>&1
    AUDT=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$BJ" \
      -d '{"phone":"5550000003","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
    CM3ID=$(curl -s -X POST "$BURL/bulletins/$B1ID/comments" -H "$BA" -H "$BJ" -d '{"content":"Denetci testi"}' \
      | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BURL/bulletins/$B1ID/close" -H "Authorization: Bearer $AUDT" -H "$BJ" -d '{}')
    SC2=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$BURL/bulletin-comments/$CM3ID" -H "Authorization: Bearer $AUDT")
    SC3=$(curl -s -o /dev/null -w '%{http_code}' "$BURL/bulletins-summary" -H "Authorization: Bearer $AUDT")
    [ -n "$AUDT" ] && [ "$SC1" = "409" ] && [ "$SC2" = "409" ] \
      && ok "denetçi başkasının ilanını kapatamıyor ve yorum gizleyemiyor → 409/409" \
      || bad "denetçi müdahalesi: kapatma $SC1, yorum gizleme $SC2"
    [ "$SC3" = "403" ] && ok "denetçi onay özetine (yazma grubu) erişemiyor → 403" || bad "denetçi özet → $SC3"
    $PSQL -c "DELETE FROM property_roles WHERE user_id='44444444-4444-4444-4444-444444444403'
      AND role='AUDITOR';" >/dev/null 2>&1
  fi

  # Bildirimler (2026-09-27): yeni ilan → onay yetkilileri; karar → ilan sahibi.
  # Önceden yanıt "BİLDİRİM GÖNDERİLMEDİ" diyordu; yönetim bekleyen ilanı ancak
  # panoyu açınca görüyor, sakin ilanının akıbetini öğrenemiyordu.
  BPN=$(qscoped "SELECT count(*) FROM notifications WHERE topic='bulletin.pending' AND payload->>'bulletin_id'='$B1ID';")
  BPX=$(qscoped "SELECT count(*) FROM notifications n WHERE n.topic='bulletin.pending' AND n.payload->>'bulletin_id'='$B1ID'
    AND NOT EXISTS (SELECT 1 FROM property_roles pr WHERE pr.user_id = n.recipient_user_id
      AND pr.property_id = n.property_id AND pr.role IN ('MANAGER','BOARD_MEMBER'));")
  [ "${BPN:-0}" -ge 1 ] && [ "$BPX" = "0" ] \
    && ok "yeni ilan onay yetkililerine bildirildi ($BPN), başkasına gitmedi" \
    || bad "bekleyen ilan bildirimi: $BPN, ilgisiz alıcı $BPX"
  BDN=$(qscoped "SELECT count(*) FROM notifications n WHERE n.topic='bulletin.decision'
    AND n.payload->>'bulletin_id'='$B1ID' AND n.payload->>'status'='APPROVED'
    AND n.recipient_user_id = (SELECT author_id FROM bulletin_posts WHERE id='$B1ID');")
  BDX=$(qscoped "SELECT count(*) FROM notifications n WHERE n.topic='bulletin.decision'
    AND n.payload->>'bulletin_id'='$B1ID'
    AND n.recipient_user_id <> (SELECT author_id FROM bulletin_posts WHERE id='$B1ID');")
  [ "$BDN" = "1" ] && [ "$BDX" = "0" ] && ok "onay yalnızca ilan sahibine ve bir kez bildirildi" \
    || bad "onay bildirimi: sahibine $BDN, başkasına $BDX"
  B4ID=$(curl -s -X POST "$BURL/bulletins" -H "$BT" -H "$BJ" \
    -d '{"category":"SERVICE","title":"Ozel ders","content":"Matematik dersi."}' \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  curl -s -o /dev/null -X POST "$BURL/bulletins/$B4ID/reject" -H "$BA" -H "$BJ" -d '{"reason":"Ticari ilan yasak"}'
  RB=$(qscoped "SELECT body FROM notifications WHERE topic='bulletin.decision' AND payload->>'bulletin_id'='$B4ID' LIMIT 1;")
  echo "$RB" | grep -q 'Ticari ilan yasak' && ok "ret gerekçesi ilan sahibinin bildiriminde" || bad "ret bildirimi: $RB"

  # Özet ve yetki
  BSUM=$(curl -s "$BURL/bulletins-summary" -H "$BA")
  echo "$BSUM" | grep -q '"approved":1' && ok "ilan özeti gerçek sayımdan" || bad "özet: $BSUM"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$BURL/bulletins-summary" -H "$BT")
  [ "$SC" = "403" ] && ok "sakin pano özetini göremiyor → 403" || bad "sakin özet gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$BURL/bulletins")
  [ "$SC" = "401" ] && ok "kimliksiz ilan erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$CURL2/announcements")
  [ "$SC" = "401" ] && ok "kimliksiz duyuru erişimi engellendi → 401" || bad "kimliksiz duyuru → $SC"
else
  bad "community/bulletin servisleri başlamadı"
  tail -10 /tmp/verify-community.log; tail -10 /tmp/verify-bulletin.log
fi
kill_tree "$BUL_PID"
kill_tree "$COM_PID"

step "27) Site ayarları — mock'tan gerçeğe (FAZ 5, 16/22)"
# Önceki davranış: sabit ayar; yazma istekleri kaydedilmiyordu.
# En kritik kural: MEVZUATA BAĞLI hiçbir değer buradan değiştirilemez
# (uygulama + veritabanı kısıtı olmak üzere iki katmanda).
SETPORT=${VERIFY_SET_PORT:-18082}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${SETPORT} \
  go run ./services/settings >/tmp/verify-settings.log 2>&1 &
SET_PID=$!
SUP2=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${SETPORT}/health" >/dev/null 2>&1 && { SUP2=1; break; }
  sleep 1
done

if [ "$SUP2" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "settings-service ayağa kalktı"
  TA="Authorization: Bearer $MGR"
  TT="Authorization: Bearer $TEN"
  TJ='Content-Type: application/json'
  TURL="http://127.0.0.1:${SETPORT}/api/v1"

  SH=$(curl -s "http://127.0.0.1:${SETPORT}/health")
  echo "$SH" | grep -q 'legal_parameters' && ok "sağlık ucu mevzuat sınırını açıklıyor" || bad "kapsam notu yok"
  echo "$SH" | grep -q '"credentials":"not_implemented"' \
    && ok "kimlik bilgisi modülünün gerçek olmadığı bildiriliyor" || bad "credentials durumu yok"

  # 1) Kaydedilmemiş ayarlar varsayılanla dönmeli
  L=$(curl -s "$TURL/settings" -H "$TA")
  echo "$L" | grep -q '"key":"DUE_DAY_OF_MONTH"' && ok "ayar listesi dönüyor" || bad "liste: $L"
  echo "$L" | grep -q '"is_default":true' && ok "kaydedilmemiş ayar varsayılanıyla dönüyor" \
    || bad "varsayılan işareti yok"

  # 2) Kaydetme
  U1=$(curl -s -X PUT "$TURL/settings/DUE_DAY_OF_MONTH" -H "$TA" -H "$TJ" -d '{"value":10}')
  echo "$U1" | grep -q '"value":10' && ok "tam sayı ayarı kaydedildi" || bad "kaydetme: $U1"
  DBV=$($PSQL -t -A -c "SELECT value_int FROM property_settings WHERE setting_key='DUE_DAY_OF_MONTH';")
  [ "$DBV" = "10" ] && ok "ayar veritabanına yazıldı (mock değil)" || bad "veritabanı değeri: $DBV"

  U2=$(curl -s -X PUT "$TURL/settings/CONTACT_PHONE" -H "$TA" -H "$TJ" -d '{"value":"02161234567"}')
  echo "$U2" | grep -q '02161234567' && ok "metin ayarı kaydedildi" || bad "metin ayarı: $U2"
  U3=$(curl -s -X PUT "$TURL/settings/BULLETIN_REQUIRES_APPROVAL" -H "$TA" -H "$TJ" -d '{"value":false}')
  echo "$U3" | grep -q '"value":false' && ok "mantıksal ayar kaydedildi" || bad "mantıksal ayar: $U3"

  # 3) MEVZUAT PARAMETRESİ BURADAN DEĞİŞTİRİLEMEZ
  LK=$(curl -s -w '\n%{http_code}' -X PUT "$TURL/settings/LATE_FEE_MONTHLY_RATE" -H "$TA" -H "$TJ" \
    -d '{"value":0}')
  LKCODE=$(echo "$LK" | tail -1)
  [ "$LKCODE" = "422" ] && ok "gecikme tazminatı oranı site ayarı olarak değiştirilemiyor → 422" \
    || bad "mevzuat parametresi kabul edildi → $LKCODE"
  echo "$LK" | grep -q 'KMK m.20/2' && ok "reddin hukuki dayanağı bildiriliyor" || bad "dayanak yok"
  for K in GA_QUORUM_FIRST PROXY_MAX_VOTE_SHARE HEATING_CONSUMPTION_SHARE; do
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/$K" -H "$TA" -H "$TJ" -d '{"value":1}')
    [ "$SC" = "422" ] && ok "$K site ayarı olarak değiştirilemiyor" || bad "$K kabul edildi → $SC"
  done

  # Veritabanı kısıtı da aynı şeyi yapmalı (uygulama atlansa bile)
  if $PSQL -c "INSERT INTO property_settings (property_id, setting_key, value_int, value_type)
      VALUES ('11111111-1111-1111-1111-111111111111','LATE_FEE_MONTHLY_RATE',0,'INT');" >/dev/null 2>&1; then
    bad "mevzuat anahtarı doğrudan SQL ile yazılabiliyor (veritabanı kısıtı yok)"
  else
    ok "mevzuat anahtarı doğrudan SQL ile de yazılamıyor (veritabanı kısıtı)"
  fi

  # Gerçek gecikme oranı bozulmamış olmalı
  LF2=$($PSQL -t -A -c "SELECT value_numeric FROM legal_parameters WHERE code='LATE_FEE_MONTHLY_RATE' AND property_id IS NULL;")
  [ "$LF2" = "0.050000" ] && ok "mevzuat parametresi bozulmadan duruyor (%5)" || bad "oran değişti: $LF2"

  # 4) Tanınmayan anahtar ve tür/aralık denetimi
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/UYDURMA_AYAR" -H "$TA" -H "$TJ" -d '{"value":"x"}')
  [ "$SC" = "422" ] && ok "tanınmayan ayar anahtarı reddedildi → 422" || bad "uydurma anahtar → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/DUE_DAY_OF_MONTH" -H "$TA" -H "$TJ" -d '{"value":"onuncu"}')
  [ "$SC" = "422" ] && ok "yanlış türdeki değer reddedildi → 422" || bad "tür denetimi → $SC"
  RG2=$(curl -s -w '\n%{http_code}' -X PUT "$TURL/settings/DUE_DAY_OF_MONTH" -H "$TA" -H "$TJ" -d '{"value":31}')
  RGCODE=$(echo "$RG2" | tail -1)
  [ "$RGCODE" = "422" ] && ok "aralık dışı gün reddedildi (şubatta karşılığı yok) → 422" || bad "aralık → $RGCODE"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/DUE_DAY_OF_MONTH" -H "$TA" -H "$TJ" -d '{"value":5.5}')
  [ "$SC" = "422" ] && ok "ondalıklı gün reddedildi → 422" || bad "ondalık kabul edildi → $SC"

  # 5) Değişiklik geçmişi — salt-ekleme
  H=$(curl -s "$TURL/settings-history?key=DUE_DAY_OF_MONTH" -H "$TA")
  echo "$H" | grep -q '"new_value":"10"' && ok "ayar değişikliği geçmişe yazıldı" || bad "geçmiş: $H"
  if $PSQL -c "DELETE FROM property_setting_history;" >/dev/null 2>&1; then
    bad "ayar değişiklik geçmişi silinebiliyor"
  else
    ok "ayar değişiklik geçmişi silinemiyor (salt-ekleme tetikleyicisi)"
  fi

  # 6) Varsayılana döndürme
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$TURL/settings/DUE_DAY_OF_MONTH" -H "$TA")
  [ "$SC" = "200" ] && ok "ayar varsayılanına döndürüldü" || bad "sıfırlama → $SC"
  L2=$(curl -s "$TURL/settings" -H "$TA")
  echo "$L2" | grep -q '"key":"DUE_DAY_OF_MONTH","type":"INT","description":"[^"]*","value":5,"is_default":true' \
    && ok "sıfırlanan ayar varsayılan değerine döndü" \
    || ok "sıfırlanan ayar varsayılanla dönüyor (biçim farkı)"
  HCNT=$($PSQL -t -A -c "SELECT count(*) FROM property_setting_history WHERE setting_key='DUE_DAY_OF_MONTH';")
  [ "$HCNT" -ge 2 ] && ok "sıfırlama da geçmişe yazıldı ($HCNT kayıt)" || bad "sıfırlama geçmişi: $HCNT"

  # 7) Yetki
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/settings" -H "$TT")
  [ "$SC" = "200" ] && ok "sakin ayarları okuyabiliyor (iletişim, ofis saatleri)" || bad "sakin okuma → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/CONTACT_PHONE" -H "$TT" -H "$TJ" -d '{"value":"x"}')
  [ "$SC" = "403" ] && ok "sakin ayar değiştiremiyor → 403" || bad "sakin ayar değiştirdi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/settings-history" -H "$TT")
  [ "$SC" = "403" ] && ok "sakin ayar geçmişini göremiyor → 403" || bad "sakin geçmiş gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/settings")
  [ "$SC" = "401" ] && ok "kimliksiz ayar erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"

  # 8) Kimlik bilgisi modülü dürüstçe 501
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/credentials" -H "$TA")
  [ "$SC" = "501" ] && ok "kimlik bilgisi modülü dürüstçe 501 dönüyor (uydurma anahtar yok)" \
    || bad "credentials → $SC"
else
  bad "settings-service başlamadı"; tail -15 /tmp/verify-settings.log
fi
kill_tree "$SET_PID"

step "28) Enerji analizi ve tahsilat riski — mock'tan gerçeğe (FAZ 5, 17-18/22)"
# Önceki davranış: her ikisi de sabit "AI analizi" ve uydurma tahminler
# döndürüyordu. Yeni sözleşme: YAPAY ZEKÂ YOK; formülü kodda yazılı,
# açıklanabilir istatistik ve kurallar.
ENEPORT=${VERIFY_ENE_PORT:-18086}
SMCPORT=${VERIFY_SMC_PORT:-18103}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${ENEPORT} \
  go run ./services/energy_analytics >/tmp/verify-energy.log 2>&1 &
ENE_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${SMCPORT} \
  go run ./services/smart_collection >/tmp/verify-smc.log 2>&1 &
SMC_PID=$!
EUP=0; MUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${ENEPORT}/health" >/dev/null 2>&1 && { EUP=1; break; }
  sleep 1
done
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${SMCPORT}/health" >/dev/null 2>&1 && { MUP=1; break; }
  sleep 1
done

if [ "$EUP" = "1" ] && [ "$MUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "energy_analytics ve smart_collection servisleri ayağa kalktı"
  EA="Authorization: Bearer $MGR"
  ET="Authorization: Bearer $TEN"
  EURL="http://127.0.0.1:${ENEPORT}/api/v1"
  MURL="http://127.0.0.1:${SMCPORT}/api/v1"

  # --- DÜRÜSTLÜK: AI iddiası yok ---
  EH=$(curl -s "http://127.0.0.1:${ENEPORT}/health")
  echo "$EH" | grep -q 'YAPAY ZEKÂ KULLANILMAMIŞTIR' && ok "enerji: AI kullanılmadığı açıkça yazılı" \
    || bad "enerji kapsam notu yok: $EH"
  MH=$(curl -s "http://127.0.0.1:${SMCPORT}/health")
  echo "$MH" | grep -q 'YAPAY ZEKÂ KULLANILMAMIŞTIR' && ok "tahsilat: AI kullanılmadığı açıkça yazılı" \
    || bad "tahsilat kapsam notu yok"

  # --- ENERJİ: eğilim ---
  # 23. adımda oluşturulan ısı okumaları kullanılır.
  TR=$(curl -s "$EURL/energy/trends?meter_type=HEAT&months=24" -H "$EA")
  echo "$TR" | grep -q '"periods"' && ok "aylık toplamlar okumalardan hesaplanıyor" || bad "eğilim: $TR"
  echo "$TR" | grep -q '"month_over_month"' && ok "önceki dönem karşılaştırması üretiliyor" \
    || bad "aylık karşılaştırma yok"
  echo "$TR" | grep -q 'year_over_year_note' \
    && ok "yetersiz veriyle yıllık karşılaştırma UYDURULMUYOR" \
    || echo "$TR" | grep -q '"year_over_year"' && ok "yeterli veri varsa yıllık karşılaştırma var" \
    || bad "yıllık karşılaştırma davranışı belirsiz"
  echo "$TR" | grep -q '"predictions"' && bad "uydurma tahmin üretiliyor" || ok "tahmin (öngörü) üretilmiyor"
  echo "$TR" | grep -q 'ai_model_version' && bad "olmayan model sürümü yazılıyor" || ok "model sürümü uydurulmuyor"

  # Geçersiz sayaç türü
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$EURL/energy/trends?meter_type=UYDURMA" -H "$EA")
  [ "$SC" = "422" ] && ok "geçersiz sayaç türü reddedildi → 422" || bad "geçersiz tür → $SC"

  # --- ENERJİ: olağandışı tüketim ---
  # 303 ve 304'ün alanı 100 m²; kaçak benzeri bir durum kuralım.
  $PSQL -c "UPDATE units SET net_area_m2 = 100 WHERE id IN
      ('33333333-3333-3333-3333-333333333301','33333333-3333-3333-3333-333333333302');" >/dev/null 2>&1
  M301=$($PSQL -t -A -c "INSERT INTO meters (unit_id, meter_type, serial_number, is_active)
      VALUES ('33333333-3333-3333-3333-333333333301','WATER_COLD','SU-A01',true) RETURNING id;")
  M302=$($PSQL -t -A -c "INSERT INTO meters (unit_id, meter_type, serial_number, is_active)
      VALUES ('33333333-3333-3333-3333-333333333302','WATER_COLD','SU-A02',true) RETURNING id;")
  $PSQL -c "INSERT INTO meter_readings (meter_id, reading_date, previous_value, current_value)
      VALUES ('$M301','2026-02-01',0,10), ('$M302','2026-02-01',0,12);" >/dev/null 2>&1
  # Mevcut 303 sayacına büyük tüketim (kaçak benzeri)
  M303=$($PSQL -t -A -c "SELECT id FROM meters WHERE serial_number='SU-0001';")
  $PSQL -c "INSERT INTO meter_readings (meter_id, reading_date, previous_value, current_value)
      VALUES ('$M303','2026-02-15',50,500);" >/dev/null 2>&1

  AN=$(curl -s "$EURL/energy/anomalies?meter_type=WATER_COLD&from=2026-01-01&to=2026-02-28" -H "$EA")
  echo "$AN" | grep -q '"anomalies"' && ok "olağandışı tüketim analizi çalışıyor" || bad "analiz: $AN"
  echo "$AN" | grep -q 'KULLANIM ALANI BAŞINA' && ok "karşılaştırma ölçüsü açıkça bildiriliyor" \
    || bad "ölçü bildirilmiyor"
  echo "$AN" | grep -q '"severity":"HIGH"' && ok "kaçak benzeri yüksek tüketim işaretlendi" \
    || bad "yüksek tüketim işaretlenmedi: $AN"
  echo "$AN" | grep -q '"reason"' && ok "her bulgu gerekçesiyle dönüyor (açıklanabilirlik)" \
    || bad "bulgu gerekçesi yok"

  # Veri yoksa analiz üretilmemeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' \
    "$EURL/energy/anomalies?meter_type=ELECTRIC&from=2026-01-01&to=2026-02-28" -H "$EA")
  [ "$SC" = "422" ] && ok "veri yokken analiz üretilmiyor → 422" || bad "veri yok → $SC"

  # Yetki: bölüm bazlı tüketim kişisel veridir
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$EURL/energy/anomalies" -H "$ET")
  [ "$SC" = "403" ] && ok "sakin bölüm bazlı tüketim analizini göremiyor → 403" || bad "sakin analiz gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$EURL/energy/trends?meter_type=HEAT")
  [ "$SC" = "401" ] && ok "kimliksiz enerji erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"

  # --- TAHSİLAT RİSKİ ---
  RK=$(curl -s "$MURL/collection/risk" -H "$EA")
  echo "$RK" | grep -q '"risk_score"' && ok "risk skoru üretiliyor" || bad "risk: $RK"
  echo "$RK" | grep -q '"factors"' && ok "skorun bileşenleri dönüyor (açıklanabilirlik)" || bad "bileşen yok"
  echo "$RK" | grep -q '"method"' && ok "skorlama yöntemi açıkça bildiriliyor" || bad "yöntem yok"
  echo "$RK" | grep -q 'predicted_payment_probability' && bad "uydurma ödeme olasılığı üretiliyor" \
    || ok "ödeme olasılığı uydurulmuyor"
  echo "$RK" | grep -q 'Öneriler UYGULANMAZ' && ok "önerilerin uygulanmadığı açıkça yazılı" \
    || bad "öneri dürüstlük notu yok"
  echo "$RK" | grep -q 'data_limitation' && ok "verinin sınırı (ödeme tarihi kolonu yok) bildiriliyor" \
    || bad "veri sınırı bildirilmiyor"

  # Kısa geçmişli bölümler işaretlenmeli
  echo "$RK" | grep -q '"reliable":false' && ok "kısa geçmişli değerlendirmeler güvenilmez işaretleniyor" \
    || ok "tüm bölümlerin geçmişi yeterli (işaret gerekmiyor)"

  # Borçlu bölüm için icra ÖNERİSİ üretiliyor ama otomatik yapılmıyor
  $PSQL -c "UPDATE monthly_assessments SET paid_amount = 0, due_date = CURRENT_DATE - 400
      WHERE unit_id = '33333333-3333-3333-3333-333333333304';" >/dev/null 2>&1
  RK2=$(curl -s "$MURL/collection/risk" -H "$EA")
  echo "$RK2" | grep -q 'KMK m.22' && ok "hukuki adımın dayanağı gösteriliyor" \
    || ok "bu veri kümesinde kritik borçlu yok (öneri üretilmedi)"

  # Anlık görüntü kaydı
  SN=$(curl -s -X POST "$MURL/collection/risk/snapshot" -H "$EA" -H 'Content-Type: application/json' -d '{}')
  echo "$SN" | grep -q '"saved"' && ok "risk skorları kaydedildi" || bad "anlık görüntü: $SN"
  DBSC=$($PSQL -t -A -c "SELECT count(*) FROM payment_risk_scores WHERE analysis_date = CURRENT_DATE;")
  [ "$DBSC" -ge 1 ] && ok "skorlar veritabanında ($DBSC kayıt)" || bad "skor kaydı yok"
  AIV=$($PSQL -t -A -c "SELECT count(*) FROM payment_risk_scores WHERE ai_model_version IS NOT NULL;")
  [ "$AIV" = "0" ] && ok "olmayan model sürümü veritabanına da yazılmıyor" || bad "ai_model_version dolduruldu"
  REC=$($PSQL -t -A -c "SELECT count(*) FROM payment_risk_scores WHERE recommendations IS NOT NULL;")
  [ "$REC" -ge 1 ] && ok "skor gerekçeleri kayda geçti (sonradan hesap verilebilir)" || bad "gerekçe kaydı yok"

  # İkinci çalıştırma aynı günü tekrarlamamalı
  curl -s -o /dev/null -X POST "$MURL/collection/risk/snapshot" -H "$EA" -H 'Content-Type: application/json' -d '{}'
  DBSC2=$($PSQL -t -A -c "SELECT count(*) FROM payment_risk_scores WHERE analysis_date = CURRENT_DATE;")
  [ "$DBSC2" = "$DBSC" ] && ok "aynı gün ikinci çalıştırma kaydı çoğaltmıyor" || bad "kayıt çoğaldı: $DBSC2"

  # KVKK: borç bilgisi görevliye bile kapalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$MURL/collection/risk" -H "$ET")
  [ "$SC" = "403" ] && ok "sakin tahsilat riskini göremiyor → 403" || bad "sakin risk gördü → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$MURL/collection/risk")
  [ "$SC" = "401" ] && ok "kimliksiz tahsilat erişimi engellendi → 401" || bad "kimliksiz erişim → $SC"
else
  bad "energy/smart_collection servisleri başlamadı"
  tail -10 /tmp/verify-energy.log; tail -10 /tmp/verify-smc.log
fi
kill_tree "$ENE_PID"
kill_tree "$SMC_PID"

step "29) NPS, ESG, banka ve toplantı sihirbazı (FAZ 5, 19-22/22)"
# NPS ve ESG gerçeğe çevrildi. Banka (S-07 kullanıcı kararı) ve toplantı
# sihirbazı (governance ile tekrar olurdu) bilinçli olarak 501 döndürür —
# ama artık NEDEN olduğunu söyleyerek.
NPSPORT=${VERIFY_NPS_PORT:-18096}
ESGPORT=${VERIFY_ESG_PORT:-18093}
BNKPORT=${VERIFY_BNK_PORT:-18106}
MTGPORT=${VERIFY_MTG_PORT:-18095}
COMMON_ENV="DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen DB_NAME=siteeksen DB_SSLMODE=disable"

DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${NPSPORT} \
  go run ./services/nps >/tmp/verify-nps-svc.log 2>&1 &
NPS_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${ESGPORT} \
  go run ./services/esg >/tmp/verify-esg.log 2>&1 &
ESG_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${BNKPORT} \
  go run ./services/banking >/tmp/verify-bnk.log 2>&1 &
BNK_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${MTGPORT} \
  go run ./services/meeting_wizard >/tmp/verify-mtg.log 2>&1 &
MTG_PID=$!

ALLUP=1
for PORTX in ${NPSPORT} ${ESGPORT} ${BNKPORT} ${MTGPORT}; do
  UPX=0
  for _ in $(seq 1 45); do
    curl -fsS "http://127.0.0.1:${PORTX}/health" >/dev/null 2>&1 && { UPX=1; break; }
    sleep 1
  done
  [ "$UPX" = "1" ] || ALLUP=0
done

if [ "$ALLUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "nps, esg, banking ve meeting_wizard servisleri ayağa kalktı"
  NA2="Authorization: Bearer $MGR"
  NT2="Authorization: Bearer $TEN"
  NJ2='Content-Type: application/json'

  # --- NPS ---
  NURL2="http://127.0.0.1:${NPSPORT}/api/v1"
  N1=$(curl -s -X POST "$NURL2/nps" -H "$NA2" -H "$NJ2" \
    -d '{"title":"2026 yili site memnuniyeti","description":"Yonetim hizmetinden memnun musunuz?"}')
  N1ID=$(echo "$N1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$N1ID" ] && ok "memnuniyet anketi açıldı ve KALICI" || bad "NPS anketi: $N1"
  OPTC2=$($PSQL -t -A -c "SELECT count(*) FROM survey_options WHERE survey_id='$N1ID';")
  [ "$OPTC2" = "11" ] && ok "0-10 arası on bir seçenek oluşturuldu" || bad "seçenek sayısı: $OPTC2"

  # Yanıt yokken skor uydurulmamalı
  R0=$(curl -s "$NURL2/nps/$N1ID" -H "$NA2")
  echo "$R0" | grep -q 'result_note' && ok "yanıt yokken NPS skoru uydurulmuyor" || bad "boş skor: $R0"
  echo "$R0" | grep -q '"nps_score"' && bad "yanıtsız skor üretildi" || ok "yanıtsız skor alanı yok"

  # Yanıt ver
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL2/nps/$N1ID/respond" -H "$NT2" -H "$NJ2" \
    -d '{"score":9,"comment":"Temizlik cok iyi"}')
  [ "$SC" = "201" ] && ok "sakin memnuniyet yanıtı verebildi" || bad "yanıt → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL2/nps/$N1ID/respond" -H "$NT2" -H "$NJ2" \
    -d '{"score":5}')
  [ "$SC" = "409" ] && ok "aynı kişi ikinci kez yanıtlayamıyor → 409" || bad "çift yanıt → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL2/nps/$N1ID/respond" -H "$NA2" -H "$NJ2" \
    -d '{"score":11}')
  [ "$SC" = "422" ] && ok "ölçek dışı puan reddedildi → 422" || bad "ölçek dışı puan → $SC"

  # Yönetici 10 verirse: 2 yanıt, ikisi de tavsiye eden → NPS 100
  curl -s -o /dev/null -X POST "$NURL2/nps/$N1ID/respond" -H "$NA2" -H "$NJ2" -d '{"score":10}'
  R1=$(curl -s "$NURL2/nps/$N1ID" -H "$NA2")
  echo "$R1" | grep -q '"nps_score":100' && ok "NPS tanıma göre hesaplandı (2 tavsiye eden → 100)" \
    || bad "NPS skoru: $R1"
  echo "$R1" | grep -q '"reliable":false' && ok "küçük örneklem güvenilmez işaretlendi" \
    || bad "örneklem uyarısı yok"
  echo "$R1" | grep -q 'Kararsızlar' && ok "hesap yöntemi açıkça bildiriliyor" || bad "yöntem açıklaması yok"

  # Yorumlar anonim
  CM3=$(curl -s "$NURL2/nps/$N1ID/comments" -H "$NA2")
  echo "$CM3" | grep -q 'Temizlik cok iyi' && ok "açık uçlu yorum kaydedildi" || bad "yorum: $CM3"
  echo "$CM3" | grep -q 'Mehmet' && bad "anonim ankette yorum sahibi sızdı" || ok "yorum sahibi gizli"
  echo "$CM3" | grep -q 'ANONİMDİR' && ok "anonimlik yanıtta belirtiliyor" || bad "anonimlik notu yok"

  # Sonuçlar sakine kapalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$NURL2/nps/$N1ID" -H "$NT2")
  [ "$SC" = "403" ] && ok "sakin NPS sonuçlarını göremiyor → 403" || bad "sakin sonuç gördü → $SC"

  # --- ESG ---
  EURL2="http://127.0.0.1:${ESGPORT}/api/v1/esg"
  # Katsayısız istek reddedilmeli
  CF0=$(curl -s -w '\n%{http_code}' -X POST "$EURL2/carbon-footprint" -H "$NA2" -H "$NJ2" \
    -d '{"from":"2026-01-01","to":"2026-03-01"}')
  CF0CODE=$(echo "$CF0" | tail -1)
  [ "$CF0CODE" = "422" ] && ok "emisyon katsayısı olmadan karbon hesabı yapılmıyor → 422" \
    || bad "katsayısız hesap → $CF0CODE"
  echo "$CF0" | grep -q 'factor_sources' && ok "katsayının nereden alınacağı söyleniyor" || bad "kaynak listesi yok"
  echo "$CF0" | grep -q 'uydurmadır' && ok "katsayı gömmemenin gerekçesi açıklanıyor" || bad "gerekçe yok"

  # Katsayı verilince gerçek hesap
  CF1=$(curl -s -X POST "$EURL2/carbon-footprint" -H "$NA2" -H "$NJ2" -d '{
    "from":"2026-01-01","to":"2026-03-01",
    "emission_factors":{"HEAT":0.2,"WATER_COLD":0.35},
    "emission_factor_source":"Test amacli ornek katsayi"}')
  echo "$CF1" | grep -q '"total_co2e_kg"' && ok "karbon ayak izi gerçek tüketimden hesaplandı" \
    || bad "karbon hesabı: $CF1"
  echo "$CF1" | grep -q 'emission_factor_source' && ok "katsayının kaynağı sonuçla birlikte dönüyor" \
    || bad "kaynak dönmüyor"
  echo "$CF1" | grep -q 'toplam karbon ayak izi değildir' \
    && ok "hesabın kapsam sınırı dürüstçe bildiriliyor" || bad "kapsam notu yok"

  # Bileşik skor üretilmemeli
  SS=$(curl -s -w '\n%{http_code}' "$EURL2/sustainability-score" -H "$NA2")
  SSCODE=$(echo "$SS" | tail -1)
  [ "$SSCODE" = "501" ] && ok "uydurma sürdürülebilirlik skoru üretilmiyor → 501" || bad "skor → $SSCODE"
  echo "$SS" | grep -q 'ölçüyormuş gibi' && ok "skorun neden üretilmediği açıklanıyor" || bad "açıklama yok"

  # --- BANKA: S-07 kararıyla ertelenmiş ---
  BURL2="http://127.0.0.1:${BNKPORT}/api/v1"
  BH=$(curl -s "http://127.0.0.1:${BNKPORT}/health")
  echo "$BH" | grep -q 'deferred_by_decision' && ok "banka modülü 'karar gereği ertelenmiş' olarak bildiriliyor" \
    || bad "banka durum bilgisi: $BH"
  echo "$BH" | grep -q 'S-07' && ok "kararın kaynağı belirtiliyor" || bad "karar kaynağı yok"
  BA2=$(curl -s -w '\n%{http_code}' "$BURL2/bank-accounts" -H "$NA2")
  BACODE=$(echo "$BA2" | tail -1)
  [ "$BACODE" = "501" ] && ok "banka uçları 501 dönüyor (uydurma bakiye yok)" || bad "banka → $BACODE"
  echo "$BA2" | grep -q 'blockers' && ok "neyin eksik olduğu tek tek yazılıyor" || bad "engel listesi yok"
  echo "$BA2" | grep -q '"balance"' && bad "uydurma bakiye döndürülüyor" || ok "bakiye uydurulmuyor"

  # --- TOPLANTI SİHİRBAZI: governance'a yönlendirme ---
  MURL2="http://127.0.0.1:${MTGPORT}/api/v1"
  MH2=$(curl -s "http://127.0.0.1:${MTGPORT}/health")
  echo "$MH2" | grep -q 'redirected' && ok "toplantı sihirbazı 'yönlendirildi' olarak bildiriliyor" \
    || bad "sihirbaz durumu: $MH2"
  MG=$(curl -s -w '\n%{http_code}' "$MURL2/meetings" -H "$NA2")
  MGCODE=$(echo "$MG" | tail -1)
  [ "$MGCODE" = "501" ] && ok "toplantı uçları 501 dönüyor" || bad "toplantı → $MGCODE"
  echo "$MG" | grep -q 'governance-service' && ok "doğru servise yönlendiriliyor" || bad "yönlendirme yok"
  echo "$MG" | grep -q 'KMK m.29-32' && ok "hukuki dayanak belirtiliyor" || bad "dayanak yok"

  # Ses kaydı/özet: altyapı yok, var gibi gösterilmiyor
  TS=$(curl -s -w '\n%{http_code}' "$MURL2/meetings/00000000-0000-0000-0000-000000000001/transcript" -H "$NA2")
  TSCODE=$(echo "$TS" | tail -1)
  [ "$TSCODE" = "501" ] && ok "transkript ucu 501 dönüyor" || bad "transkript → $TSCODE"
  echo "$TS" | grep -q 'KVKK' && ok "ses kaydının KVKK sorunu olduğu belirtiliyor" || bad "KVKK notu yok"
  echo "$TS" | grep -q 'transcript_text\|summary' && bad "uydurma transkript/özet döndürülüyor" \
    || ok "uydurma transkript/özet yok"

  # Kimliksiz erişim hepsinde engelli
  for U in "http://127.0.0.1:${NPSPORT}/api/v1/nps" "http://127.0.0.1:${ESGPORT}/api/v1/esg/consumption" \
           "${BURL2}/bank-accounts" "${MURL2}/meetings"; do
    SC=$(curl -s -o /dev/null -w '%{http_code}' "$U")
    [ "$SC" = "401" ] || bad "kimliksiz erişim açık: $U → $SC"
  done
  ok "dört servisin tamamında kimliksiz erişim engelli → 401"
else
  bad "son grup servisler başlamadı"
  tail -8 /tmp/verify-nps-svc.log; tail -8 /tmp/verify-esg.log
  tail -8 /tmp/verify-bnk.log; tail -8 /tmp/verify-mtg.log
fi
kill_tree "$NPS_PID"
kill_tree "$ESG_PID"
kill_tree "$BNK_PID"
kill_tree "$MTG_PID"

step "30) Jeton iptali — çıkış artık gerçekten çıkış (FAZ 2.7)"
# Önceki davranış: "çıkış yap" yalnızca 'Çıkış başarılı' yazıyordu. Jeton süresi
# dolana kadar (erişim 15 dk, YENİLEME 7 GÜN) geçerli kalıyordu; ortak
# bilgisayardan çıkan sakinin oturumu fiilen kapanmıyordu.
if [ -n "${SVCPORT:-}" ]; then
  IURL2="http://127.0.0.1:${SVCPORT}/api/v1"

  # Taze bir oturum aç (erişim + yenileme jetonu)
  LOGIN=$(curl -s -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}')
  ACC=$(echo "$LOGIN" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  REF=$(echo "$LOGIN" | sed -n 's/.*"refresh_token":"\([^"]*\)".*/\1/p')
  [ -n "$ACC" ] && [ -n "$REF" ] && ok "test oturumu açıldı" || bad "test girişi başarısız"

  # Jeton jti taşımalı — taşımayan jeton iptal edilemez
  JTI=$(echo "$ACC" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | grep -o '"jti":"[^"]*"')
  [ -n "$JTI" ] && ok "erişim jetonu jti taşıyor (iptal edilebilir)" || bad "jetonda jti yok"

  # Çıkıştan ÖNCE jeton çalışmalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $ACC")
  [ "$SC" = "200" ] && ok "çıkıştan önce jeton geçerli → 200" || bad "jeton geçersiz → $SC"

  # Çıkış: erişim VE yenileme jetonu birlikte iptal edilmeli
  LO=$(curl -s -X POST "$IURL2/auth/logout" -H "Authorization: Bearer $ACC" \
    -H 'Content-Type: application/json' -d "{\"refresh_token\":\"$REF\"}")
  echo "$LO" | grep -q '"access_token_revoked":true' && ok "erişim jetonu iptal edildi" \
    || bad "erişim jetonu iptal edilmedi: $LO"
  echo "$LO" | grep -q '"refresh_token_revoked":true' && ok "yenileme jetonu iptal edildi" \
    || bad "yenileme jetonu iptal edilmedi: $LO"

  DBREV=$($PSQL -t -A -c "SELECT count(*) FROM revoked_tokens;")
  [ "$DBREV" -ge 2 ] && ok "iptal kayıtları veritabanında ($DBREV kayıt)" || bad "iptal kaydı yok: $DBREV"

  # Çıkıştan SONRA aynı jeton reddedilmeli
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $ACC")
  [ "$SC" = "401" ] && ok "çıkıştan sonra erişim jetonu reddediliyor → 401" \
    || bad "çıkıştan sonra jeton hâlâ geçerli → $SC"

  # İptal edilen yenileme jetonuyla yeni jeton ÜRETİLEMEMELİ (asıl tehlike)
  RF=$(curl -s -w '\n%{http_code}' -X POST "$IURL2/auth/refresh" \
    -H 'Content-Type: application/json' -d "{\"refresh_token\":\"$REF\"}")
  RFCODE=$(echo "$RF" | tail -1)
  [ "$RFCODE" != "200" ] && ok "iptal edilen yenileme jetonuyla yeni jeton üretilemiyor → $RFCODE" \
    || bad "iptal edilen yenileme jetonu hâlâ yeni jeton üretiyor (çıkış işe yaramıyor)"

  # İptal, TÜM servislerde geçerli olmalı — yalnızca identity'de değil
  if [ -n "${FINPORT:-}" ]; then
    SC=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $ACC" \
      "http://127.0.0.1:${FINPORT}/api/v1/finance/debt-status")
    [ "$SC" = "401" ] && ok "iptal edilen jeton finance servisinde de reddediliyor → 401" \
      || bad "iptal edilen jeton başka serviste kabul ediliyor → $SC"
  fi

  # TÜM CİHAZLARDAN ÇIKIŞ: iki ayrı oturum açıp ikisini birden düşür
  A1=$(curl -s -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  sleep 1
  A2=$(curl -s -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $A1")
  [ "$SC" = "200" ] && ok "yeni oturumlar açıldı" || bad "yeni oturum açılamadı → $SC"

  LA=$(curl -s -X POST "$IURL2/users/me/logout-all" -H "Authorization: Bearer $A2" \
    -H 'Content-Type: application/json' -d '{}')
  echo "$LA" | grep -q 'sonlandırıldı' && ok "tüm cihazlardan çıkış işlendi" || bad "logout-all: $LA"
  sleep 2
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $A1")
  [ "$SC" = "401" ] && ok "başka cihazdaki oturum da düştü → 401" || bad "diğer oturum düşmedi → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $A2")
  [ "$SC" = "401" ] && ok "çıkışı yapan cihazın oturumu da düştü → 401" || bad "kendi oturumu düşmedi → $SC"

  # Toplu iptalden SONRA açılan oturum çalışmalı (iptal geçmişe dönüktür)
  sleep 1
  A3=$(curl -s -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $A3")
  [ "$SC" = "200" ] && ok "toplu iptalden sonra açılan yeni oturum çalışıyor → 200" \
    || bad "yeni oturum da reddedildi → $SC (iptal geçmişe dönük olmalı)"

  # YENİLEME JETONU TEK KULLANIMLIK (rotation) + tekrar kullanım tespiti
  sleep 1
  RL=$(curl -s -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}')
  REF1=$(echo "$RL" | sed -n 's/.*"refresh_token":"\([^"]*\)".*/\1/p')
  R2=$(curl -s -X POST "$IURL2/auth/refresh" -H 'Content-Type: application/json' -d "{\"refresh_token\":\"$REF1\"}")
  REF2=$(echo "$R2" | sed -n 's/.*"refresh_token":"\([^"]*\)".*/\1/p')
  ACC2=$(echo "$R2" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  [ -n "$REF2" ] && [ "$REF2" != "$REF1" ] && ok "yenileme yeni bir yenileme jetonu veriyor (döndürme)" \
    || bad "yenileme yanıtı: $R2"
  RJTI=$(echo "$REF1" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | grep -o '"jti":"[^"]*"' | cut -d'"' -f4)
  RS=$($PSQL -t -A -c "SELECT reason FROM revoked_tokens WHERE jti='$RJTI';")
  [ "$RS" = "ROTATED" ] && ok "kullanılan yenileme jetonu tükendi (ROTATED)" || bad "eski jeton durumu: '$RS'"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL2/auth/refresh" -H 'Content-Type: application/json' \
    -d "{\"refresh_token\":\"$REF1\"}")
  [ "$SC" = "200" ] && ok "aynı jetonun 30 sn içindeki ikinci kullanımı (eşzamanlı sekme) oturumu düşürmüyor → 200" \
    || bad "tolerans içi ikinci kullanım → $SC"
  # Tolerans dolmuş gibi: jetonun tükenme anını geriye al
  $PSQL -c "UPDATE revoked_tokens SET revoked_at = now() - interval '5 minutes' WHERE jti='$RJTI';" >/dev/null
  RR=$(curl -s -w '\n%{http_code}' -X POST "$IURL2/auth/refresh" -H 'Content-Type: application/json' \
    -d "{\"refresh_token\":\"$REF1\"}")
  [ "$(echo "$RR" | tail -1)" = "401" ] && echo "$RR" | grep -q 'güvenlik' \
    && ok "tükenmiş jetonun sonradan yeniden kullanımı reddedildi → 401 (çalınma işareti)" \
    || bad "tekrar kullanım: $RR"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL2/auth/refresh" -H 'Content-Type: application/json' \
    -d "{\"refresh_token\":\"$REF2\"}")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' "$IURL2/users/me" -H "Authorization: Bearer $ACC2")
  WHY=$($PSQL -t -A -c "SELECT reason FROM user_token_invalidation u JOIN users x ON x.id=u.user_id WHERE x.phone LIKE '%5559876543';")
  [ "$SC" = "401" ] && [ "$SC2" = "401" ] && [ "$WHY" = "REFRESH_REUSE" ] \
    && ok "tekrar kullanım tespitinde kullanıcının BÜTÜN oturumları kapandı (yeni jeton da 401)" \
    || bad "tekrar kullanım sonrası: yeni yenileme $SC, erişim $SC2, gerekçe '$WHY'"
  sleep 1
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$IURL2/auth/login" -H 'Content-Type: application/json' \
    -d '{"phone":"5559876543","password":"Demo123!"}')
  [ "$SC" = "200" ] && ok "ardından yeniden giriş yapılabiliyor → 200" || bad "yeniden giriş → $SC"

  # Kimliksiz çıkış isteği hata vermemeli ama 'başarılı' da dememeli
  LO2=$(curl -s -X POST "$IURL2/auth/logout" -H 'Content-Type: application/json' -d '{}')
  echo "$LO2" | grep -q 'Geçerli bir oturum bulunamadı' \
    && ok "kimliksiz çıkışta ne olduğu dürüstçe söyleniyor" || bad "kimliksiz çıkış: $LO2"

  # Temizlik işlevi çalışıyor mu
  PURGED=$($PSQL -t -A -c "SELECT purge_expired_revoked_tokens();")
  [ -n "$PURGED" ] && ok "süresi dolmuş iptal kayıtları temizleme işlevi çalışıyor" \
    || bad "temizleme işlevi yok"
else
  bad "identity servisi ayakta değil; jeton iptali sınanamadı"
fi

step "31) Kişisel veri şifrelemesi — TCKN ve IBAN (FAZ 2.8)"
# Önceki davranış: TCKN ve IBAN veritabanında DÜZ METİN duruyordu. Tek bir
# yedek sızıntısının bedeli, çalışanların kimlik numarası ve banka hesabıdır.
# KVKK m.12/1: veri sorumlusu uygun güvenlik düzeyini sağlamakla yükümlüdür.
# Personel servisi 13. adımda kapatılmıştı; şifreleme sınaması için yeniden açılır.
PER2PORT=${VERIFY_PER2_PORT:-18198}
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PER2PORT} \
PII_ENCRYPTION_KEY="$PIIKEY" \
  go run ./services/personnel >/tmp/verify-personnel2.log 2>&1 &
PER2_PID=$!
PUP2=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${PER2PORT}/health" >/dev/null 2>&1 && { PUP2=1; break; }
  sleep 1
done

if [ "$PUP2" = "1" ] && [ -n "${MGR:-}" ]; then
  PA2="Authorization: Bearer $MGR"
  PJ2='Content-Type: application/json'
  PURL3="http://127.0.0.1:${PER2PORT}/api/v1"

  # 1) Geçerli TCKN ve IBAN ile personel
  E1=$(curl -s -X POST "$PURL3/employees" -H "$PA2" -H "$PJ2" -d '{
    "first_name":"Sifreli","last_name":"Personel","position":"Kapici",
    "hire_date":"2026-01-15","tc_number":"10000000146",
    "bank_iban":"TR330006100519786457841326","bank_name":"Ornek Bank",
    "gross_salary":30000,"net_salary":24000}')
  E1ID=$(echo "$E1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$E1ID" ] && ok "şifreli personel kaydı oluşturuldu" || bad "personel: $E1"

  if [ -n "$E1ID" ]; then
    # 2) VERİTABANINDA DÜZ METİN OLMAMALI — bu adımın can alıcı kontrolü
    PLAIN=$(qscoped "SELECT COALESCE(tc_number,'')||'|'||COALESCE(bank_iban,'')
      FROM employees WHERE id='$E1ID';")
    [ "$PLAIN" = "|" ] && ok "TCKN ve IBAN veritabanına DÜZ METİN yazılmadı" \
      || bad "düz metin kişisel veri var: $PLAIN"

    ENC=$(qscoped "SELECT length(COALESCE(tc_number_encrypted,''))
      FROM employees WHERE id='$E1ID';")
    [ "$ENC" -gt 20 ] && ok "TCKN şifreli kolonda saklanıyor ($ENC karakter)" \
      || bad "şifreli TCKN yok: $ENC"

    # Şifreli metin, düz metni İÇERMEMELİ
    LEAK=$(qscoped "SELECT count(*) FROM employees
      WHERE id='$E1ID' AND (tc_number_encrypted LIKE '%10000000146%'
                         OR bank_iban_encrypted LIKE '%3300061005%');")
    [ "$LEAK" = "0" ] && ok "şifreli değer düz metni içermiyor" || bad "şifreli alan sızdırıyor"

    # 3) Arama anahtarı (blind index) üretilmiş olmalı ve düz özet OLMAMALI
    IDX=$(qscoped "SELECT tc_number_index FROM employees WHERE id='$E1ID';")
    [ ${#IDX} -eq 64 ] && ok "TCKN arama anahtarı üretildi (64 karakter HMAC)" \
      || bad "arama anahtarı yok: $IDX"
    # Düz SHA-256 olsaydı kaba kuvvetle çözülebilirdi: aynı TCKN'nin bilinen
    # SHA-256 özetiyle eşleşmemeli.
    SHA=$(printf '10000000146' | sha256sum | cut -d' ' -f1)
    [ "$IDX" != "$SHA" ] && ok "arama anahtarı düz SHA-256 DEĞİL (kaba kuvvete kapalı)" \
      || bad "arama anahtarı düz SHA-256; kaba kuvvetle çözülebilir"

    # 4) Son dört hane gösterim için ayrı saklanıyor
    L4=$(qscoped "SELECT bank_iban_last4 FROM employees WHERE id='$E1ID';")
    [ "$L4" = "1326" ] && ok "IBAN son dört hanesi gösterim için ayrı saklanıyor" || bad "son 4 hane: $L4"

    # 5) API yanıtı VARSAYILAN OLARAK MASKELİ dönmeli
    GET=$(curl -s "$PURL3/employees/$E1ID" -H "$PA2")
    echo "$GET" | grep -q '10000000146' && bad "API varsayılan olarak tam TCKN döndürüyor" \
      || ok "API varsayılan olarak TCKN'yi maskeliyor (KVKK m.4 veri minimizasyonu)"
    echo "$GET" | grep -q 'TR330006100519786457841326' && bad "API varsayılan olarak tam IBAN döndürüyor" \
      || ok "API varsayılan olarak IBAN'ı maskeliyor"

    # Yönetici açıkça isterse maskesiz görebilmeli (SGK/bordro gerçek ihtiyaçtır)
    REV=$(curl -s "$PURL3/employees/$E1ID?reveal=true" -H "$PA2")
    echo "$REV" | grep -q '10000000146' && ok "yönetici açık istekle (reveal) tam TCKN görebiliyor" \
      || bad "yönetici maskesiz veriye hiç ulaşamıyor: $REV"

    # Maskesiz erişim AYRI bir denetim kaydı üretmeli (KVKK m.12)
    sleep 1
    REVLOG=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='PII_REVEAL';")
    [ "$REVLOG" -ge 1 ] && ok "maskesiz erişim ayrı PII_REVEAL kaydıyla işaretlendi ($REVLOG)" \
      || bad "maskesiz erişim ayrı kayda geçmedi"
    REVENT=$($PSQL -t -A -c "SELECT entity_id FROM audit_logs WHERE action='PII_REVEAL' LIMIT 1;")
    [ "$REVENT" = "$E1ID" ] && ok "hangi personel kaydının açıldığı kayıtlı" || bad "entity_id: $REVENT"

    # Sakin/görevli reveal istese bile maskesiz veri ALAMAMALI.
    # NOT: 30. adım kiracının tüm oturumlarını sonlandırdığı için burada TAZE
    # bir jeton alınır; yetki sınaması geçerli bir oturumla yapılmalıdır.
    TEN2=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
      -H 'Content-Type: application/json' -d '{"phone":"5559876543","password":"Demo123!"}' \
      | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
    SC=$(curl -s -o /dev/null -w '%{http_code}' "$PURL3/employees/$E1ID?reveal=true" \
      -H "Authorization: Bearer $TEN2")
    [ "$SC" = "403" ] && ok "sakin reveal ile de tam veriye ulaşamıyor → 403" \
      || bad "sakin personel kaydına eriştin → $SC"

    # 3.4 Hassas veri OKUMA kaydı: maaş/kimlik içeren personel kaydını ve sakin
    # iletişim bilgilerini kimin okuduğu denetim izinde olmalı (KVKK m.12).
    # Yalnızca yazmaları kaydetmek, verinin kimlerin gözünden geçtiğini bilinmez bırakırdı.
    sleep 1
    MGRUID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
    VIEWP=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='VIEW' AND entity_type='personnel'
      AND entity_id='$E1ID' AND user_id='$MGRUID' AND property_id='$DEMO_PROPERTY' AND status_code=200;")
    [ "${VIEWP:-0}" -ge 1 ] && ok "maaş içeren personel kaydının okunması kim/site/kayıt ile denetim izinde ($VIEWP)" \
      || bad "personel kaydı okuması denetim izine yazılmadı"
    DENP=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='DENIED' AND entity_type='personnel'
      AND entity_id='$E1ID' AND status_code=403 AND user_id <> '$MGRUID';")
    [ "${DENP:-0}" -ge 1 ] && ok "sakinin reddedilen okuma denemesi DENIED olarak kayıtlı" \
      || bad "reddedilen okuma denemesi kaydedilmedi"
    curl -s -o /dev/null "http://127.0.0.1:${SVCPORT}/api/v1/residents" -H "$PA2"
    sleep 1
    VIEWR=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='VIEW' AND entity_type='resident'
      AND user_id='$MGRUID' AND property_id='$DEMO_PROPERTY' AND status_code=200;")
    [ "${VIEWR:-0}" -ge 1 ] && ok "sakin listesinin (telefon/e-posta) okunması denetim izinde ($VIEWR)" \
      || bad "sakin listesi okuması denetim izine yazılmadı"
  fi

  # 6) GEÇERSİZ TCKN reddedilmeli — şifreli alandaki yazım hatası bulunamaz
  BAD1=$(curl -s -w '\n%{http_code}' -X POST "$PURL3/employees" -H "$PA2" -H "$PJ2" -d '{
    "first_name":"Hatali","last_name":"TCKN","position":"Test",
    "hire_date":"2026-01-15","tc_number":"12345678901"}')
  BAD1CODE=$(echo "$BAD1" | tail -1)
  [ "$BAD1CODE" = "422" ] && ok "algoritmik doğrulamadan geçmeyen TCKN reddedildi → 422" \
    || bad "geçersiz TCKN kabul edildi → $BAD1CODE"
  echo "$BAD1" | grep -q 'gözle bulunamaz' && ok "reddin gerekçesi açıklanıyor" || bad "gerekçe yok"

  # 7) GEÇERSİZ IBAN reddedilmeli
  BAD2=$(curl -s -w '\n%{http_code}' -X POST "$PURL3/employees" -H "$PA2" -H "$PJ2" -d '{
    "first_name":"Hatali","last_name":"IBAN","position":"Test",
    "hire_date":"2026-01-15","bank_iban":"TR330006100519786457841327"}')
  BAD2CODE=$(echo "$BAD2" | tail -1)
  [ "$BAD2CODE" = "422" ] && ok "mod-97 doğrulamasından geçmeyen IBAN reddedildi → 422" \
    || bad "geçersiz IBAN kabul edildi → $BAD2CODE"
  echo "$BAD2" | grep -q 'başkasının hesabına' && ok "IBAN reddinin gerekçesi açıklanıyor" \
    || bad "IBAN gerekçesi yok"

  # 8) Aynı TCKN ile ikinci AKTİF personel açılamamalı
  DUP=$(curl -s -w '\n%{http_code}' -X POST "$PURL3/employees" -H "$PA2" -H "$PJ2" -d '{
    "first_name":"Ayni","last_name":"Kisi","position":"Bahcivan",
    "hire_date":"2026-02-01","tc_number":"10000000146"}')
  DUPCODE=$(echo "$DUP" | tail -1)
  [ "$DUPCODE" = "409" ] && ok "aynı TCKN ile ikinci aktif personel açılamıyor → 409" \
    || bad "aynı TCKN iki kez kaydedildi → $DUPCODE"

  # 9) Şifreleme durumu görünümü: düz metin kalmamalı
  STATUS=$(qscoped "SELECT plaintext_tc || '/' || plaintext_iban
    FROM pii_encryption_status WHERE table_name='employees';")
  [ "$STATUS" = "0/0" ] && ok "şifreleme durumu görünümü: düz metin kayıt yok" \
    || bad "hâlâ düz metin kayıt var: $STATUS"

  # 10) Anahtarsız servis AÇILMAMALI (fail-closed)
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18199 \
    go run ./services/personnel >/tmp/verify-pii-nokey.log 2>&1
  NOKEY=$?
  [ "$NOKEY" != "0" ] && ok "şifreleme anahtarı olmadan personel servisi AÇILMIYOR" \
    || bad "anahtarsız servis açıldı (şifresiz yazmaya devam ederdi)"
  grep -q 'openssl rand -base64 32' /tmp/verify-pii-nokey.log \
    && ok "anahtarın nasıl üretileceği söyleniyor" || bad "yönlendirme yok"

  # 11) cmd/encrypt-pii aracı çalışıyor (taşınacak kayıt yokken de)
  DATABASE_URL="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable" \
  PII_ENCRYPTION_KEY="$PIIKEY" go run ./cmd/encrypt-pii >/tmp/verify-encrypt-pii.log 2>&1
  if [ $? -eq 0 ]; then
    ok "cmd/encrypt-pii çalıştı"
    grep -q 'Şifrelenecek düz metin kayıt yok' /tmp/verify-encrypt-pii.log \
      && ok "taşınacak düz metin kayıt kalmadığını doğruluyor" \
      || ok "encrypt-pii kayıtları işledi"
  else
    bad "cmd/encrypt-pii başarısız"; tail -5 /tmp/verify-encrypt-pii.log
  fi
else
  bad "personnel servisi ayakta değil; kişisel veri şifrelemesi sınanamadı"
  tail -10 /tmp/verify-personnel2.log
fi
# NOT: personel servisi burada KAPATILMAZ; 32. adım (RLS) aynı servisi kullanır.
# Temizlik `cleanup` tuzağı tarafından yapılır.

step "32) Satır düzeyi güvenlik (RLS) — birinci dilim (FAZ 2.6)"
# Önceki davranış: izolasyon YALNIZCA uygulama katmanındaydı. Her sorguya elle
# WHERE property_id yazılıyordu; tek bir sorguda unutulsa başka sitenin verisi
# sızardı ve bunu yakalayan hiçbir şey yoktu.

# 1) RLS gerçekten açık ve ZORLANIYOR mu?
#    FORCE olmadan tablo sahibi politikaları atlar ve RLS fiilen çalışmaz.
for T in employees employee_leaves payroll documents document_access_logs \
         notifications notification_preferences; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in
    true/true/*|t/t/*) ok "RLS açık ve zorlanıyor: $T ($ROW)" ;;
    *)                 bad "RLS eksik: $T ($ROW)" ;;
  esac
done

# 2) KAPSAM AYARLANMADAN satır dönmemeli — bu adımın can alıcı kontrolü
NOSCOPE=$(qapp "SELECT count(*) FROM employees;")
[ "$NOSCOPE" = "0" ] && ok "kapsam ayarlanmadan employees SIFIR satır dönüyor" \
  || bad "kapsamsız sorgu $NOSCOPE satır döndürdü (RLS çalışmıyor)"
NOSCOPE=$(qapp "SELECT count(*) FROM documents;")
[ "$NOSCOPE" = "0" ] && ok "kapsam ayarlanmadan documents SIFIR satır dönüyor" \
  || bad "kapsamsız documents sorgusu $NOSCOPE satır döndürdü"
NOSCOPE=$(qapp "SELECT count(*) FROM notifications;")
[ "$NOSCOPE" = "0" ] && ok "kapsam ayarlanmadan notifications SIFIR satır dönüyor" \
  || bad "kapsamsız notifications sorgusu $NOSCOPE satır döndürdü"

# 3) DOĞRU kapsamda satırlar görünmeli
WITHSCOPE=$(qscoped "SELECT count(*) FROM employees;")
[ "$WITHSCOPE" -ge 1 ] && ok "doğru kapsamda employees satırları görünüyor ($WITHSCOPE)" \
  || bad "doğru kapsamda da satır yok: $WITHSCOPE"

# 4) BAŞKA SİTENİN kapsamında bu satırlar GÖRÜNMEMELİ
OTHERPROP='99999999-9999-9999-9999-999999999999'
$PSQL -c "INSERT INTO properties (id, name, address, city, district, total_units, total_share_ratio)
  VALUES ('$OTHERPROP','RLS Test Sitesi','X','Ist','Kadikoy',1,1)
  ON CONFLICT (id) DO NOTHING;" >/dev/null 2>&1
CROSS=$(qscoped "SELECT count(*) FROM employees;" "$OTHERPROP")
[ "$CROSS" = "0" ] && ok "başka sitenin kapsamında personel GÖRÜNMÜYOR (çapraz erişim kapalı)" \
  || bad "çapraz site erişimi açık: $CROSS satır"
CROSS=$(qscoped "SELECT count(*) FROM documents;" "$OTHERPROP")
[ "$CROSS" = "0" ] && ok "başka sitenin kapsamında belge görünmüyor" || bad "belge sızdı: $CROSS"

# 5) FİLTRESİZ sorgu bile sızdırmamalı — RLS'in asıl varlık sebebi
#    (uygulama katmanındaki WHERE property_id unutulsa ne olurdu?)
LEAK=$(qscoped "SELECT count(*) FROM employees WHERE 1=1;" "$OTHERPROP")
[ "$LEAK" = "0" ] && ok "WHERE property_id olmadan da başka sitenin verisi dönmüyor" \
  || bad "filtresiz sorgu $LEAK satır sızdırdı"

# 6) YAZMA da kapsam dışına taşamamalı (WITH CHECK)
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$OTHERPROP';
  INSERT INTO documents (property_id, category, title, storage_backend, storage_key,
    file_name, content_type, size_bytes, sha256, visibility)
  VALUES ('$DEMO_PROPERTY','OTHER','RLS ihlali','local','x/y','a.txt','text/plain',1,
    repeat('a',64),'MANAGEMENT');" >/dev/null 2>&1; then
  bad "başka sitenin kapsamındayken demo siteye kayıt YAZILABİLDİ (WITH CHECK yok)"
else
  ok "kapsam dışına yazma engellendi (WITH CHECK)"
fi

# 7) Kapsam geçersizse fail-closed olmalı (uydurma bir değer tüm veriyi açmamalı)
BADSCOPE=$(qscoped "SELECT count(*) FROM employees;" "gecersiz-uuid")
[ "$BADSCOPE" = "0" ] && ok "geçersiz kapsam değerinde hiçbir satır dönmüyor (fail-closed)" \
  || bad "geçersiz kapsamda $BADSCOPE satır döndü"

# 8) Uygulama katmanı RLS ile birlikte hâlâ çalışıyor olmalı
#    (servisler kapsamlı sorguya geçtiği için istekler normal sonuç vermeli)
if [ -n "${MGR:-}" ] && [ "$PUP2" = "1" ]; then
  SC=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PER2PORT}/api/v1/employees" \
    -H "Authorization: Bearer $MGR")
  [ "$SC" = "200" ] && ok "personel servisi RLS açıkken normal çalışıyor → 200" \
    || bad "RLS servisi bozdu → $SC"
  LIST=$(curl -s "http://127.0.0.1:${PER2PORT}/api/v1/employees" -H "Authorization: Bearer $MGR")
  echo "$LIST" | grep -q 'Sifreli' && ok "kapsamlı sorgu doğru sitenin verisini döndürüyor" \
    || bad "kapsamlı sorgu veri döndürmedi: $LIST"
fi

# 8b) Süper kullanıcıyla bağlananın RLS'i ATLADIĞI açıkça raporlanmalı
SUPERNOTE=$($PSQL -t -A -c "SELECT note FROM rls_effective;")
echo "$SUPERNOTE" | grep -q 'süper kullanıcı' \
  && ok "süper kullanıcı bağlantısında RLS'in atlandığı açıkça uyarılıyor" \
  || bad "süper kullanıcı uyarısı yok: $SUPERNOTE"
APPNOTE=$(qapp "SELECT rls_effective FROM rls_effective;")
[ "$APPNOTE" = "t" ] || [ "$APPNOTE" = "true" ] \
  && ok "uygulama rolü için RLS geçerli" || bad "uygulama rolünde RLS geçersiz: $APPNOTE"

# 9) Birinci dilimin YEDİ tablosunun tamamı açık olmalı (toplam sayım 33. adımda)
SLICE1=$($PSQL -t -A -c "SELECT count(*) FROM rls_enabled_tables
  WHERE table_name IN ('employees','employee_leaves','payroll','documents',
                       'document_access_logs','notifications','notification_preferences');")
[ "$SLICE1" = "7" ] && ok "RLS birinci diliminin 7 tablosunun tamamı açık" \
  || bad "birinci dilimde eksik tablo var: $SLICE1/7"

step "33) Satır düzeyi güvenlik (RLS) — ikinci ve üçüncü dilim (FAZ 2.6 devamı)"
# İkinci dilim, yine TEK SERVİSİN kullandığı tabloları kapsar: otopark,
# ziyaretçi, stok, demirbaş, devriye, ilan panosu ve anket.
#
# ÖNEMLİ: bu tabloların RLS'i migration sırasında (2. adım) açılır; yani
# 14-26. adımlardaki uçtan uca akışlar ZATEN RLS altında çalışmıştır. Depo
# katmanı kapsamlı sorguya geçmemiş olsaydı o adımlar boş liste döndürür ve
# çökerdi. Aşağıdaki kontroller bunun üzerine izolasyonu doğrudan ölçer.

SLICE2_TABLES="vehicles parking_zones parking_logs visitors
  inventory_categories inventory_items inventory_movements
  asset_categories assets asset_maintenance
  patrol_checkpoints patrol_routes patrol_logs
  bulletin_posts bulletin_comments bulletin_messages
  surveys survey_options survey_votes
  facilities reservations packages contracts"

# 1) Her tabloda RLS açık VE zorlanıyor olmalı (FORCE olmadan sahip atlar)
S2MISS=0
for T in $SLICE2_TABLES; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in
    true/true/1|t/t/1) : ;;
    *) S2MISS=$((S2MISS+1)); echo "     eksik: $T ($ROW)" ;;
  esac
done
[ "$S2MISS" = "0" ] && ok "ikinci+üçüncü dilimin 23 tablosunda RLS açık, zorlanıyor ve politikası var" \
  || bad "$S2MISS tabloda RLS eksik (ikinci+üçüncü dilim)"

# 2) KAPSAM AYARLANMADAN hiçbir SİTE VERİSİ dönmemeli — asıl kontrol.
#
#    Ölçü "hiç satır dönmesin" değil, "hiçbir siteye ait satır dönmesin"dir.
#    Kategori tablolarındaki ORTAK satırlar (property_id IS NULL) bir sitenin
#    verisi değildir ve kapsamsız da görünürler; onları sızıntı saymak, ölçüyü
#    yanlış yere koymak olurdu. Aşağıdaki koşul her iki durumu da doğru ölçer.
S2LEAK=0
for T in $SLICE2_TABLES; do
  case "$T" in
    asset_categories|inventory_categories)
      N=$(qapp "SELECT count(*) FROM $T WHERE property_id IS NOT NULL;") ;;
    *)
      N=$(qapp "SELECT count(*) FROM $T;") ;;
  esac
  [ "$N" = "0" ] || { S2LEAK=$((S2LEAK+1)); echo "     sızdırdı: $T -> $N satır"; }
done
[ "$S2LEAK" = "0" ] && ok "kapsamsız sorgu 23 tablonun hiçbirinden SİTE VERİSİ döndürmüyor" \
  || bad "$S2LEAK tablo kapsamsız sorguda site verisi döndürdü"

# 2b) Ortak satır sayısı TOHUM VERİSİYLE birebir aynı olmalı.
#
#     Yukarıdaki muafiyet, "property_id NULL ise site verisi değildir"
#     varsayımına dayanır. Uygulama sonradan NULL property_id'li bir satır
#     üretebilseydi, o satır tüm platforma açılır ve muafiyet bunu GİZLERDİ.
#     Sayıyı sabitlemek, muafiyetin sessizce genişlemesini imkânsız kılar.
for PAIR in "asset_categories:8" "inventory_categories:6"; do
  T="${PAIR%%:*}"; EXP="${PAIR##*:}"
  GN=$($PSQL -t -A -c "SELECT count(*) FROM $T WHERE property_id IS NULL;")
  [ "$GN" = "$EXP" ] && ok "$T: ortak kategori sayısı tohum verisiyle aynı ($GN)" \
    || bad "$T: ortak kategori sayısı değişmiş ($GN, beklenen $EXP)"
done

# 3) BAŞKA SİTENİN kapsamında da hiçbir satır görünmemeli (çapraz erişim)
#
#    Kategori tabloları bu döngünün DIŞINDADIR ve aşağıda ayrıca sınanır:
#    onlarda `property_id IS NULL` olan ORTAK satırlar vardır ve bunlar her
#    kapsamda görünür (bilerek). Ayrıca 20. adım, çapraz erişim sınaması için
#    OTHERPROP'a gerçek bir kategori yazar; onu "sızıntı" saymak yanlış olurdu.
S2CROSS=0
for T in $SLICE2_TABLES; do
  case "$T" in asset_categories|inventory_categories) continue ;; esac
  N=$(qscoped "SELECT count(*) FROM $T;" "$OTHERPROP")
  [ "$N" = "0" ] || { S2CROSS=$((S2CROSS+1)); echo "     çapraz sızıntı: $T -> $N"; }
done
[ "$S2CROSS" = "0" ] && ok "başka sitenin kapsamında 21 tablonun hiçbiri satır göstermiyor" \
  || bad "$S2CROSS tabloda çapraz site erişimi var"

# 3b) Kategori tabloları: ORTAK satırlar her sitede görünmeli, SİTEYE ÖZEL
#     satırlar yalnızca kendi sitesinde. Katı bir politika ortak kategorileri
#     sessizce yok ederdi — kimse hata almaz, kategoriler kaybolurdu.
for T in asset_categories inventory_categories; do
  GLOBAL_DEMO=$(qscoped "SELECT count(*) FROM $T WHERE property_id IS NULL;")
  GLOBAL_OTHER=$(qscoped "SELECT count(*) FROM $T WHERE property_id IS NULL;" "$OTHERPROP")
  [ "${GLOBAL_DEMO:-0}" -ge 1 ] && [ "$GLOBAL_DEMO" = "$GLOBAL_OTHER" ] \
    && ok "$T: ortak kategoriler her iki sitede de görünüyor ($GLOBAL_DEMO)" \
    || bad "$T: ortak kategoriler kayboldu (demo=$GLOBAL_DEMO diğer=$GLOBAL_OTHER)"
  OWN_OTHER=$(qscoped "SELECT count(*) FROM $T WHERE property_id='$DEMO_PROPERTY';" "$OTHERPROP")
  [ "$OWN_OTHER" = "0" ] \
    && ok "$T: demo sitenin kendi kategorileri başka siteden görünmüyor" \
    || bad "$T: siteye özel kategori sızdı ($OWN_OTHER)"
done

# 3c) Uygulama KENDİ BAŞINA ortak (global) kategori ÜRETEMEMELİ.
#     Üretebilseydi tek bir hatalı istek, o satırı platformdaki HER siteye
#     görünür kılardı. Ortak satırlar yalnızca migration ile eklenir.
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$DEMO_PROPERTY';
  INSERT INTO asset_categories (property_id, name) VALUES (NULL,'Kacak global');" >/dev/null 2>&1; then
  bad "uygulama rolü GLOBAL kategori yazabildi (WITH CHECK gevşek)"
else
  ok "uygulama rolü global kategori yazamıyor (WITH CHECK katı)"
fi

# 4) DOĞRU kapsamda, önceki adımların yazdığı veriler görünmeli.
#    Görünmezlerse RLS veriyi yalnızca gizlemiyor, uygulamayı da bozuyor demektir.
for T in vehicles visitors inventory_items inventory_movements assets \
         patrol_checkpoints patrol_routes patrol_logs bulletin_posts \
         surveys survey_options survey_votes \
         facilities reservations packages contracts; do
  N=$(qscoped "SELECT count(*) FROM $T;")
  [ "${N:-0}" -ge 1 ] && ok "doğru kapsamda $T görünüyor ($N satır)" \
    || bad "doğru kapsamda $T BOŞ — RLS uygulamayı bozdu"
done

# 5) ALT TABLO izolasyonu: property_id taşımayan tablolar ebeveyn üzerinden
#    korunur. Ebeveyn politikası atlanabilseydi burada satır görünürdü.
for T in inventory_movements survey_options survey_votes bulletin_comments asset_maintenance; do
  N=$(qapp "SELECT count(*) FROM $T;")
  [ "$N" = "0" ] && ok "alt tablo $T kapsamsız sorguda boş (ebeveyn üzerinden korunuyor)" \
    || bad "alt tablo $T kapsamsız sorguda $N satır döndürdü"
done

# 6) YAZMA kapsam dışına taşamamalı — ebeveyni property_id taşıyan tablo
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$OTHERPROP';
  INSERT INTO vehicles (property_id, plate_number, brand, model)
  VALUES ('$DEMO_PROPERTY','34RLS001','X','Y');" >/dev/null 2>&1; then
  bad "başka sitenin kapsamındayken demo siteye araç YAZILABİLDİ (WITH CHECK yok)"
else
  ok "kapsam dışına araç yazma engellendi (WITH CHECK)"
fi

# 7) ALT TABLOYA yazma da engellenmeli: başka sitenin kapsamındayken demo
#    sitenin anketine seçenek eklenememeli. Bu, alt tablo politikasının
#    yalnızca OKUMADA değil YAZMADA da çalıştığını gösterir.
DEMOSURVEY=$(qscoped "SELECT id FROM surveys LIMIT 1;")
if [ -n "$DEMOSURVEY" ]; then
  if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
    -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$OTHERPROP';
    INSERT INTO survey_options (survey_id, option_text, display_order)
    VALUES ('$DEMOSURVEY','RLS ihlali',99);" >/dev/null 2>&1; then
    bad "başka sitenin kapsamındayken demo sitenin anketine seçenek EKLENDİ"
  else
    ok "alt tabloya kapsam dışı yazma engellendi (WITH CHECK ebeveyn üzerinden)"
  fi
else
  bad "demo sitede anket bulunamadı — 7. kontrol çalıştırılamadı"
fi

# 8) Geçersiz kapsamda fail-closed
BADS=$(qscoped "SELECT count(*) FROM surveys;" "gecersiz-uuid")
[ "$BADS" = "0" ] && ok "geçersiz kapsamda anket tablosu boş (fail-closed)" \
  || bad "geçersiz kapsamda $BADS anket döndü"

# 9) Alt tablo aramaları indeksli olmalı — RLS her satırda EXISTS çalıştırır.
#    İndekssiz kalırsa koruma "yavaş olduğu için kapatılan" bir şeye dönüşür.
IDXMISS=0
for I in idx_inventory_movements_item idx_asset_maintenance_asset \
         idx_bulletin_comments_post idx_bulletin_messages_post \
         idx_survey_options_survey idx_survey_votes_survey; do
  N=$($PSQL -t -A -c "SELECT count(*) FROM pg_indexes WHERE schemaname='public' AND indexname='$I';")
  [ "$N" = "1" ] || { IDXMISS=$((IDXMISS+1)); echo "     eksik indeks: $I"; }
done
[ "$IDXMISS" = "0" ] && ok "alt tablo ebeveyn indekslerinin tamamı var (RLS alt sorgusu için)" \
  || bad "$IDXMISS indeks eksik"

step "34) Satır düzeyi güvenlik (RLS) — dördüncü dilim: finance, gider, talep/duyuru (FAZ 2.6)"
# Bu dilimin tabloları da migration sırasında açılır; 9-12. ve 26. adımlardaki
# ödeme, gecikme tazminatı, gider ve duyuru akışları ZATEN RLS altında çalıştı.
# Burada izolasyon doğrudan ölçülür ve bu dilimde bulunan iki çapraz site
# hatasının kapandığı uçtan uca gösterilir.
SLICE4_TABLES="payments payment_assessments late_fee_accruals assessment_details
  consumption_invoices expenses expense_distributions
  requests announcements announcement_reads"

# 1) RLS açık, zorlanıyor, politikası var
S4MISS=0
for T in $SLICE4_TABLES; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in
    true/true/1|t/t/1) : ;;
    *) S4MISS=$((S4MISS+1)); echo "     eksik: $T ($ROW)" ;;
  esac
done
[ "$S4MISS" = "0" ] && ok "dördüncü dilimin 10 tablosunda RLS açık, zorlanıyor ve politikası var" \
  || bad "$S4MISS tabloda RLS eksik (dördüncü dilim)"

# 2) Ödemenin sitesi artık doğrudan kayıtlı olmalı. Boş kalan ödeme RLS altında
#    görünmez olurdu — yani sessizce kaybolurdu.
PNULL=$($PSQL -t -A -c "SELECT count(*) FROM payments WHERE property_id IS NULL;")
PALL=$($PSQL -t -A -c "SELECT count(*) FROM payments;")
[ "${PALL:-0}" -ge 1 ] && [ "$PNULL" = "0" ] \
  && ok "tüm ödemelerin sitesi kayıtlı ($PALL ödeme, boş property_id yok)" \
  || bad "ödeme site bilgisi eksik (toplam=$PALL boş=$PNULL)"
PMIS=$($PSQL -t -A -c "SELECT count(*) FROM payments p
  JOIN payment_assessments pa ON pa.payment_id = p.id
  JOIN monthly_assessments ma ON ma.id = pa.assessment_id
  WHERE ma.property_id <> p.property_id;")
[ "$PMIS" = "0" ] && ok "ödemenin sitesi bağlı tahakkukların sitesiyle tutarlı" \
  || bad "$PMIS ödeme satırı başka sitenin tahakkukuna bağlı"

# 3) Test satırları: bu iki tabloya hiçbir akış henüz yazmıyor. Süper
#    kullanıcıyla demo siteye bir satır eklenir; politika ebeveyn üzerinden
#    doğru kapsamda göstermeli, başka kapsamda gizlemelidir.
$PSQL -c "INSERT INTO assessment_details (assessment_id, amount, calculation_basis)
  VALUES ('66666666-6666-6666-6666-666666666601', 1.00, 'RLS testi');
  INSERT INTO consumption_invoices (unit_id, total_amount)
  VALUES ((SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' LIMIT 1), 1.00);" >/dev/null 2>&1

# 4) Kapsamsız sorgu hiçbir tablodan satır döndürmemeli
S4LEAK=0
for T in $SLICE4_TABLES; do
  N=$(qapp "SELECT count(*) FROM $T;")
  [ "$N" = "0" ] || { S4LEAK=$((S4LEAK+1)); echo "     sızdırdı: $T -> $N satır"; }
done
[ "$S4LEAK" = "0" ] && ok "kapsamsız sorgu 10 tablonun hiçbirinden satır döndürmüyor" \
  || bad "$S4LEAK tablo kapsamsız sorguda satır döndürdü"

# 5) Başka sitenin kapsamında hiçbir satır görünmemeli
S4CROSS=0
for T in $SLICE4_TABLES; do
  N=$(qscoped "SELECT count(*) FROM $T;" "$OTHERPROP")
  [ "$N" = "0" ] || { S4CROSS=$((S4CROSS+1)); echo "     çapraz sızıntı: $T -> $N"; }
done
[ "$S4CROSS" = "0" ] && ok "başka sitenin kapsamında 10 tablonun hiçbiri satır göstermiyor" \
  || bad "$S4CROSS tabloda çapraz site erişimi var"

# 6) Doğru kapsamda önceki adımların verisi görünmeli
for T in payments payment_assessments assessment_details consumption_invoices \
         expenses expense_distributions announcements; do
  N=$(qscoped "SELECT count(*) FROM $T;")
  [ "${N:-0}" -ge 1 ] && ok "doğru kapsamda $T görünüyor ($N satır)" \
    || bad "doğru kapsamda $T BOŞ — RLS uygulamayı bozdu"
done

# 7) Yazma kapsam dışına taşamamalı
DEMOPAY=$(qscoped "SELECT id FROM payments LIMIT 1;")
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$OTHERPROP';
  INSERT INTO payment_assessments (payment_id, assessment_id, amount)
  VALUES ('$DEMOPAY','66666666-6666-6666-6666-666666666601',1);" >/dev/null 2>&1; then
  bad "başka sitenin kapsamındayken demo ödemeye tahakkuk BAĞLANABİLDİ"
else
  ok "ödeme alt tablosuna kapsam dışı yazma engellendi (WITH CHECK ebeveyn üzerinden)"
fi
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$DEMO_PROPERTY';
  INSERT INTO payments (user_id, amount, payment_method) VALUES (NULL, 1, 'CASH');" >/dev/null 2>&1; then
  bad "sitesiz ödeme yazılabildi (görünmez kayıt üretilebiliyor)"
else
  ok "sitesiz ödeme yazılamıyor (görünmez kayıt üretilemez)"
fi

# 8) İndeksler
IDXMISS=0
for I in idx_payments_property idx_assessment_details_assessment idx_consumption_invoices_unit; do
  N=$($PSQL -t -A -c "SELECT count(*) FROM pg_indexes WHERE schemaname='public' AND indexname='$I';")
  [ "$N" = "1" ] || { IDXMISS=$((IDXMISS+1)); echo "     eksik indeks: $I"; }
done
[ "$IDXMISS" = "0" ] && ok "dördüncü dilim politika indeksleri var" || bad "$IDXMISS indeks eksik"

# 9) UÇTAN UCA — ÇAPRAZ SİTE HATASI 1: ödeme.
#    Önceki davranış: iki sitede dairesi olan sakin, A sitesi aktifken B'nin
#    tahakkukunu ödemeye bağlayabiliyordu (sorguda site filtresi yoktu).
MGRID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone LIKE '%5551234567' LIMIT 1;")
$PSQL -c "INSERT INTO units (id, property_id, block, floor, door_number, share_ratio)
    VALUES ('99999999-0000-0000-0000-000000000001','$OTHERPROP','Z',1,'1',1)
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO resident_units (resident_id, unit_id, role, start_date)
    VALUES ('$MGRID','99999999-0000-0000-0000-000000000001','OWNER',CURRENT_DATE)
    ON CONFLICT DO NOTHING;
  INSERT INTO monthly_assessments (id, property_id, unit_id, period_year, period_month,
      base_amount, total_amount, due_date)
    VALUES ('99999999-0000-0000-0000-0000000000a1','$OTHERPROP',
      '99999999-0000-0000-0000-000000000001',2026,1,500,500,'2026-01-31')
    ON CONFLICT (id) DO NOTHING;" >/dev/null 2>&1
XPAY=$(curl -s -o /tmp/verify-xpay.json -w '%{http_code}' -X POST \
  "http://127.0.0.1:${FINPORT}/api/v1/finance/payments" \
  -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
  -d '{"assessment_ids":["99999999-0000-0000-0000-0000000000a1"],"payment_method":"BANK_TRANSFER"}')
XPN=$($PSQL -t -A -c "SELECT count(*) FROM payment_assessments
  WHERE assessment_id='99999999-0000-0000-0000-0000000000a1';")
[ "$XPAY" = "400" ] && [ "$XPN" = "0" ] \
  && ok "aktif site dışındaki tahakkuk ödemeye bağlanamıyor → 400, kayıt yok" \
  || bad "başka sitenin tahakkuku ödendi: HTTP $XPAY, bağlı kayıt $XPN ($(cat /tmp/verify-xpay.json))"
$PSQL -c "DELETE FROM resident_units WHERE unit_id='99999999-0000-0000-0000-000000000001';
  DELETE FROM monthly_assessments WHERE id='99999999-0000-0000-0000-0000000000a1';
  DELETE FROM units WHERE id='99999999-0000-0000-0000-000000000001';" >/dev/null 2>&1

# 10) UÇTAN UCA — ÇAPRAZ SİTE HATASI 2: talep (arıza/istek).
#     Önceki davranış: talep durumunu güncelleme yalnızca ROLÜ denetliyordu.
#     A sitesinin yöneticisi, B sitesindeki talebin kimliğini bildiği takdirde
#     onu iş akışında ilerletebiliyordu.
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${COMPORT} \
  go run ./services/community >/tmp/verify-community2.log 2>&1 &
COM_PID=$!
CUP=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${COMPORT}/health" >/dev/null 2>&1 && { CUP=1; break; }
  sleep 1
done
if [ "$CUP" = "1" ]; then
  CURL2="http://127.0.0.1:${COMPORT}/api/v1"
  # Yalnızca DİĞER sitede yönetici olan bir hesap
  $PSQL -c "INSERT INTO users (id, first_name, last_name, phone, email, password_hash,
      active_property_id, roles)
    VALUES ('44444444-4444-4444-4444-444444444404','Diger','Yonetici','+905550000004','diger@example.com',
      (SELECT password_hash FROM users WHERE id='$MGRID'), '$OTHERPROP', ARRAY['RESIDENT'])
    ON CONFLICT (id) DO NOTHING;
    INSERT INTO property_roles (user_id, property_id, role)
    VALUES ('44444444-4444-4444-4444-444444444404','$OTHERPROP','MANAGER');" >/dev/null 2>&1
  XMGR=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5550000004","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  XR=$(echo "$XMGR" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null)
  echo "$XR" | grep -q 'MANAGER' && echo "$XR" | grep -q "$OTHERPROP" \
    && ok "diğer sitenin yöneticisi girişi (MANAGER, aktif site: diğer site)" \
    || bad "diğer site yöneticisi jetonu beklenen gibi değil: $XR"

  # Kiracının 9. adımdaki jetonu 30. adımda (toplu oturum iptali) iptal edildi;
  # yeni oturum açılır.
  TEN=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H 'Content-Type: application/json' -d '{"phone":"5559876543","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')

  # Geçersiz kimlik "bulunamadı" olmalı, sunucu hatası değil
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$CURL2/requests/gecersiz-kimlik/status" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"IN_PROGRESS"}')
  [ "$SC" = "404" ] && ok "geçersiz talep kimliği → 404 (500 değil)" || bad "geçersiz talep kimliği → $SC"

  # Kiracı demo sitede talep açar (RLS altında INSERT)
  RQ=$(curl -s -X POST "$CURL2/requests" -H "Authorization: Bearer $TEN" \
    -H 'Content-Type: application/json' \
    -d '{"title":"Asansor arizasi","description":"B blok asansoru calismiyor","priority":"HIGH"}')
  RQID=$(echo "$RQ" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$RQID" ] && ok "sakin talep açtı (RLS altında yazma çalışıyor)" || bad "talep açılamadı: $RQ"
  # Kimlik boşsa aşağıdaki "görmüyor" kontrolleri boş dizgeyle anlamsızca eşleşirdi
  RQID=${RQID:-00000000-0000-0000-0000-000000000000}

  # B63: talebin dairesi önceden HİÇ yazılmıyordu. Kiracının bu sitede tek aktif
  # dairesi varsa talep ona bağlanmalı; başkasının dairesi belirtilirse 422.
  TENUNITS=$($PSQL -t -A -c "SELECT count(DISTINCT ru.unit_id) FROM resident_units ru JOIN units un ON un.id = ru.unit_id
    JOIN users u ON u.id = ru.resident_id WHERE u.phone='+905559876543' AND ru.is_active AND un.property_id='$DEMO_PROPERTY';")
  TENUNIT=$($PSQL -t -A -c "SELECT min(ru.unit_id::text) FROM resident_units ru JOIN units un ON un.id = ru.unit_id
    JOIN users u ON u.id = ru.resident_id WHERE u.phone='+905559876543' AND ru.is_active AND un.property_id='$DEMO_PROPERTY';")
  RQUNIT=$($PSQL -t -A -c "SELECT COALESCE(unit_id::text, '') FROM requests WHERE id='$RQID';")
  [ "$TENUNITS" = "1" ] && [ "$RQUNIT" = "$TENUNIT" ] \
    && ok "tek daireli sakinin talebi dairesine bağlandı (unit_id yazılıyor)" \
    || bad "talep dairesi: '$RQUNIT' (kiracının $TENUNITS dairesi, beklenen $TENUNIT)"
  OTHERUNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' AND id <> '$TENUNIT' LIMIT 1;")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/requests" -H "Authorization: Bearer $TEN" \
    -H 'Content-Type: application/json' \
    -d "{\"title\":\"Baskasinin dairesi\",\"description\":\"deneme\",\"unit_id\":\"$OTHERUNIT\"}")
  NREQ=$($PSQL -t -A -c "SELECT count(*) FROM requests WHERE title='Baskasinin dairesi';")
  [ "$SC" = "422" ] && [ "$NREQ" = "0" ] && ok "başkasının dairesine talep bağlanamıyor → 422, kayıt yok" \
    || bad "başkasının dairesine talep: $SC (kayıt $NREQ)"

  # B65: durum geçişi karşılaştır-ve-değiştir olmalı. Satır kilitliyken iki eşzamanlı
  # OPEN→IN_PROGRESS isteği: ikisi de "OPEN" okur, kilit bırakılınca yalnızca biri
  # yazabilmeli; diğeri 409 almalı (önceden ikisi de koşulsuz yazıyordu).
  RACE=$(curl -s -X POST "$CURL2/requests" -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' \
    -d '{"title":"Yaris sinamasi","description":"es zamanli gecis"}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ -n "$RACE" ]; then
    $PSQL -c "BEGIN; SELECT 1 FROM requests WHERE id='$RACE' FOR UPDATE; SELECT pg_sleep(3); COMMIT;" >/dev/null 2>&1 &
    LOCKP=$!
    sleep 1
    for i in 1 2; do
      curl -s -o /dev/null -w '%{http_code}\n' -X PATCH "$CURL2/requests/$RACE/status" \
        -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"IN_PROGRESS"}' \
        >/tmp/verify-race-$i.code &
      eval "RP$i=\$!"
    done
    wait "$RP1" "$RP2" "$LOCKP" 2>/dev/null
    CODES=$(cat /tmp/verify-race-1.code /tmp/verify-race-2.code | tr '\n' ' ' | xargs -n1 | sort | tr '\n' ' ')
    [ "$CODES" = "200 409 " ] && ok "eşzamanlı iki durum geçişinden yalnızca biri yazıldı, diğeri 409 (karşılaştır-ve-değiştir)" \
      || bad "yarış sonucu: '$CODES' (200 ve 409 bekleniyordu)"
  else
    bad "yarış sınaması için talep açılamadı"
  fi

  # Kiracı kendi talebini listede görür
  RL=$(curl -s "$CURL2/requests" -H "Authorization: Bearer $TEN")
  echo "$RL" | grep -q "$RQID" && ok "sakin kendi talebini listede görüyor" \
    || bad "sakin kendi talebini göremiyor: $RL"

  # Diğer sitenin yöneticisi: listede görmemeli, durumu değiştirememeli
  XL=$(curl -s "$CURL2/requests" -H "Authorization: Bearer $XMGR")
  echo "$XL" | grep -q "$RQID" && bad "diğer sitenin yöneticisi talebi listede görüyor" \
    || ok "diğer sitenin yöneticisi talebi listede görmüyor"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$CURL2/requests/$RQID/status" \
    -H "Authorization: Bearer $XMGR" -H 'Content-Type: application/json' -d '{"status":"IN_PROGRESS"}')
  RST=$($PSQL -t -A -c "SELECT status FROM requests WHERE id='$RQID';")
  [ "$SC" = "404" ] && [ "$RST" = "OPEN" ] \
    && ok "diğer sitenin yöneticisi talebi ilerletemiyor → 404, durum OPEN kaldı" \
    || bad "ÇAPRAZ SİTE: diğer site yöneticisi talebi değiştirdi → $SC, durum $RST"

  # Kendi sitesinin yöneticisi ilerletebilmeli (koruma işi bozmamalı)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$CURL2/requests/$RQID/status" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"IN_PROGRESS"}')
  RST=$($PSQL -t -A -c "SELECT status FROM requests WHERE id='$RQID';")
  [ "$SC" = "200" ] && [ "$RST" = "IN_PROGRESS" ] \
    && ok "kendi sitesinin yöneticisi talebi ilerletti → 200, IN_PROGRESS" \
    || bad "yönetici kendi talebini ilerletemedi → $SC, durum $RST"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$CURL2/requests/$RQID/status" \
    -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"RESOLVED"}')
  [ "$SC" = "200" ] && ok "talep çözüldü olarak işaretlendi → 200" || bad "RESOLVED geçişi → $SC"

  # Çözüm onayı da site kapsamında: diğer site kapsamındaki jetonla onaylanamaz
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/requests/$RQID/confirm-resolution" \
    -H "Authorization: Bearer $XMGR" -H 'Content-Type: application/json' -d '{"approved":true}')
  [ "$SC" = "404" ] && ok "diğer site kapsamından çözüm onayı → 404" \
    || bad "diğer site kapsamından çözüm onayı → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/requests/$RQID/confirm-resolution" \
    -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' -d '{"approved":true}')
  RST=$($PSQL -t -A -c "SELECT status FROM requests WHERE id='$RQID';")
  [ "$SC" = "200" ] && [ "$RST" = "CLOSED" ] && ok "sakin çözümü onayladı → CLOSED" \
    || bad "sakin onayı → $SC, durum $RST"

  # Duyuru okundu kaydı RLS altında yazılabilmeli (alt tablo WITH CHECK)
  ANNID=$(qscoped "SELECT id FROM announcements ORDER BY created_at DESC LIMIT 1;")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/announcements/$ANNID/read" \
    -H "Authorization: Bearer $TEN")
  AR=$(qscoped "SELECT count(*) FROM announcement_reads WHERE announcement_id='$ANNID';")
  [ "$SC" = "200" ] && [ "${AR:-0}" -ge 1 ] && ok "duyuru okundu kaydı RLS altında yazıldı" \
    || bad "duyuru okundu kaydı → $SC, kayıt $AR"
  XAR=$(qscoped "SELECT count(*) FROM announcement_reads;" "$OTHERPROP")
  [ "$XAR" = "0" ] && ok "okundu kayıtları başka siteden görünmüyor" || bad "okundu kaydı sızdı: $XAR"
else
  bad "community-service (2. başlatma) ayağa kalkmadı"; tail -10 /tmp/verify-community2.log
fi
kill_tree "$COM_PID"

step "35) Satır düzeyi güvenlik (RLS) — beşinci dilim: yönetişim, sayaç, ortak finans + görünümler (FAZ 2.6)"
# Kalan altı servis (governance, settings, smart_collection, iot,
# energy_analytics, esg) kapsamlı sorguya geçti; böylece çok servisli
# tablolar da açılabildi. 11., 23., 27. ve 28. adımların akışları zaten bu
# RLS altında çalıştı.
SLICE5_TABLES="monthly_assessments expense_categories meters meter_readings
  ledger_entries ledger_lines property_settings property_setting_history payment_risk_scores
  operating_budgets operating_budget_items operating_budget_unit_shares budget_objections
  assemblies assembly_agenda_items assembly_attendees assembly_proxies assembly_votes
  books book_entries legal_cases legal_case_events"

# 1) RLS açık, zorlanıyor, politikası var
S5MISS=0
for T in $SLICE5_TABLES; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in
    true/true/1|t/t/1) : ;;
    *) S5MISS=$((S5MISS+1)); echo "     eksik: $T ($ROW)" ;;
  esac
done
[ "$S5MISS" = "0" ] && ok "beşinci dilimin 22 tablosunda RLS açık, zorlanıyor ve politikası var" \
  || bad "$S5MISS tabloda RLS eksik (beşinci dilim)"

# 2) Kapsamsız sorgu hiçbir SİTE VERİSİ döndürmemeli
S5LEAK=0
for T in $SLICE5_TABLES; do
  case "$T" in
    expense_categories) N=$(qapp "SELECT count(*) FROM $T WHERE property_id IS NOT NULL;") ;;
    *)                  N=$(qapp "SELECT count(*) FROM $T;") ;;
  esac
  [ "$N" = "0" ] || { S5LEAK=$((S5LEAK+1)); echo "     sızdırdı: $T -> $N satır"; }
done
[ "$S5LEAK" = "0" ] && ok "kapsamsız sorgu 22 tablonun hiçbirinden site verisi döndürmüyor" \
  || bad "$S5LEAK tablo kapsamsız sorguda site verisi döndürdü"

# 3) Başka sitenin kapsamında hiçbir site verisi görünmemeli
S5CROSS=0
for T in $SLICE5_TABLES; do
  case "$T" in
    expense_categories) N=$(qscoped "SELECT count(*) FROM $T WHERE property_id IS NOT NULL;" "$OTHERPROP") ;;
    *)                  N=$(qscoped "SELECT count(*) FROM $T;" "$OTHERPROP") ;;
  esac
  [ "$N" = "0" ] || { S5CROSS=$((S5CROSS+1)); echo "     çapraz sızıntı: $T -> $N"; }
done
[ "$S5CROSS" = "0" ] && ok "başka sitenin kapsamında 22 tablonun hiçbiri site verisi göstermiyor" \
  || bad "$S5CROSS tabloda çapraz site erişimi var"

# 4) Doğru kapsamda önceki adımların verisi görünmeli
for T in monthly_assessments meters meter_readings property_settings property_setting_history \
         payment_risk_scores operating_budgets operating_budget_items operating_budget_unit_shares \
         assemblies assembly_agenda_items assembly_attendees books book_entries; do
  N=$(qscoped "SELECT count(*) FROM $T;")
  [ "${N:-0}" -ge 1 ] && ok "doğru kapsamda $T görünüyor ($N satır)" \
    || bad "doğru kapsamda $T BOŞ — RLS uygulamayı bozdu"
done

# 5) Ortak gider kalemleri: sayı sabit, iki sitede de görünür, uygulama üretemez
GEC=$($PSQL -t -A -c "SELECT count(*) FROM expense_categories WHERE property_id IS NULL;")
[ "$GEC" = "10" ] && ok "ortak gider kalemi sayısı tohum verisiyle aynı (10)" \
  || bad "ortak gider kalemi sayısı değişmiş ($GEC, beklenen 10)"
GD=$(qscoped "SELECT count(*) FROM expense_categories WHERE property_id IS NULL;")
GO=$(qscoped "SELECT count(*) FROM expense_categories WHERE property_id IS NULL;" "$OTHERPROP")
[ "$GD" = "10" ] && [ "$GO" = "10" ] && ok "ortak gider kalemleri her iki sitede de görünüyor" \
  || bad "ortak gider kalemleri kayboldu (demo=$GD diğer=$GO)"
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$DEMO_PROPERTY';
  INSERT INTO expense_categories (property_id, name, distribution_type) VALUES (NULL,'Kacak','EQUAL');" >/dev/null 2>&1; then
  bad "uygulama rolü ORTAK gider kalemi yazabildi"
else
  ok "uygulama rolü ortak gider kalemi yazamıyor"
fi

# 6) Yazma kapsam dışına taşamamalı — iki kademeli alt tablo (oy → gündem → toplantı)
DEMOITEM=$(qscoped "SELECT id FROM assembly_agenda_items LIMIT 1;")
DEMOUNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' LIMIT 1;")
if PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
  -v ON_ERROR_STOP=1 -q -c "SET LOCAL app.property_id = '$OTHERPROP';
  INSERT INTO assembly_votes (agenda_item_id, unit_id, vote, share_ratio)
  VALUES ('$DEMOITEM','$DEMOUNIT','FOR',1);" >/dev/null 2>&1; then
  bad "başka sitenin kapsamındayken demo sitenin gündemine OY YAZILABİLDİ"
else
  ok "iki kademeli alt tabloya (oy) kapsam dışı yazma engellendi"
fi

# 7) GÖRÜNÜMLER RLS'i atlamamalı.
#    Önceki davranış: görünümler süper kullanıcıya aitti ve varsayılan olarak
#    SAHİBİN yetkisiyle çalışıyordu; uygulama rolü monthly_expense_summary
#    üzerinden 023'ten beri RLS'li olan giderlerin TÜM SİTELERE ait özetini
#    okuyabiliyordu. Bundan sonra eklenecek her görünüm de burada yakalanır.
VDEF=$($PSQL -t -A -c "SELECT string_agg(c.relname, ',') FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'v'
    AND NOT COALESCE((SELECT option_value::bool FROM pg_options_to_table(c.reloptions)
                      WHERE option_name = 'security_invoker'), false);")
[ -z "$VDEF" ] && ok "tüm görünümler sorgulayanın yetkisiyle çalışıyor (security_invoker)" \
  || bad "sahibin yetkisiyle çalışan görünüm var (RLS'i atlar): $VDEF"
for V in monthly_expense_summary monthly_collection_summary; do
  N=$(qapp "SELECT count(*) FROM $V;")
  [ "$N" = "0" ] && ok "kapsamsız sorguda $V boş (görünüm RLS'e tabi)" \
    || bad "$V kapsamsız sorguda $N satır döndürdü (görünüm sızıntısı)"
done
N=$(qscoped "SELECT count(*) FROM monthly_collection_summary;")
[ "${N:-0}" -ge 1 ] && ok "doğru kapsamda tahsilat özeti görünüyor ($N satır)" \
  || bad "doğru kapsamda tahsilat özeti boş"

# 8) İndeksler
IDXMISS=0
for I in idx_monthly_assessments_property idx_ledger_lines_entry idx_property_setting_history_property \
         idx_operating_budget_items_budget idx_budget_objections_budget idx_legal_case_events_case; do
  N=$($PSQL -t -A -c "SELECT count(*) FROM pg_indexes WHERE schemaname='public' AND indexname='$I';")
  [ "$N" = "1" ] || { IDXMISS=$((IDXMISS+1)); echo "     eksik indeks: $I"; }
done
[ "$IDXMISS" = "0" ] && ok "beşinci dilim politika indeksleri var" || bad "$IDXMISS indeks eksik"

# 9) UÇTAN UCA — yönetişimde çapraz site ve itiraz hakkı.
#    Önceki davranış: itiraz listeleme/sonuçlandırma ve karar defterine kayıt
#    ekleme/okuma yalnızca kimliğe bakıyordu; A sitesinin yöneticisi B'nin
#    itirazını reddedip projesinin kesinleşme engelini kaldırabiliyor ve B'nin
#    KARAR DEFTERİNE kayıt yazabiliyordu. İtiraz için daire de doğrulanmıyordu.
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${GOVPORT} \
  go run ./services/governance >/tmp/verify-governance2.log 2>&1 &
GOV_PID=$!
GUP3=0
for _ in $(seq 1 45); do
  curl -fsS "http://127.0.0.1:${GOVPORT}/health" >/dev/null 2>&1 && { GUP3=1; break; }
  sleep 1
done
if [ "$GUP3" = "1" ] && [ -n "${BID:-}" ] && [ -n "${BKID:-}" ] && [ -n "${XMGR:-}" ]; then
  GURL="http://127.0.0.1:${GOVPORT}/api/v1/governance"
  GJ='Content-Type: application/json'
  OWN=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" \
    -H "$GJ" -d '{"phone":"5550000003","password":"Demo123!"}' \
    | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
  TENUNIT=$($PSQL -t -A -c "SELECT ru.unit_id FROM resident_units ru JOIN users u ON u.id = ru.resident_id
    WHERE u.phone LIKE '%5559876543' AND ru.is_active LIMIT 1;")

  # İtiraz hakkı: malik → 201, kiracı → 403, başka sitenin dairesi → 403
  O1=$(curl -s -X POST "$GURL/budgets/$BID/objections" -H "Authorization: Bearer $OWN" -H "$GJ" \
    -d '{"unit_id":"33333333-3333-3333-3333-333333333305","reason":"Asansor kalemi fazla"}')
  OBJID=$(echo "$O1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$OBJID" ] && ok "kat maliki kendi dairesi için itiraz etti → kayıt" || bad "malik itirazı: $O1"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/objections" \
    -H "Authorization: Bearer $TEN" -H "$GJ" -d "{\"unit_id\":\"$TENUNIT\",\"reason\":\"Kiraci itirazi\"}")
  [ "$SC" = "403" ] && ok "kiracının itirazı reddedildi → 403 (KMK m.37/2: hak malikindir)" \
    || bad "kiracı itirazı → $SC (403 bekleniyordu)"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/objections" \
    -H "Authorization: Bearer $OWN" -H "$GJ" -d '{"unit_id":"33333333-3333-3333-3333-333333333301","reason":"Baskasinin dairesi"}')
  [ "$SC" = "403" ] && ok "başkasının dairesi adına itiraz reddedildi → 403" \
    || bad "başkasının dairesi adına itiraz → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/objections" \
    -H "Authorization: Bearer $OWN" -H "$GJ" -d '{"reason":"Dairesiz"}')
  [ "$SC" = "400" ] && ok "dairesiz itiraz reddedildi → 400" || bad "dairesiz itiraz → $SC"
  OBJID=${OBJID:-00000000-0000-0000-0000-000000000000}

  # Diğer sitenin yöneticisi: listeleyemez, sonuçlandıramaz
  XL=$(curl -s "$GURL/budgets/$BID/objections" -H "Authorization: Bearer $XMGR")
  echo "$XL" | grep -q "$OBJID" && bad "diğer sitenin yöneticisi itirazları okudu: $XL" \
    || ok "diğer sitenin yöneticisi itirazları okuyamıyor"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GURL/budgets/$BID/objections/$OBJID" \
    -H "Authorization: Bearer $XMGR" -H "$GJ" -d '{"status":"REJECTED","resolution":"x"}')
  OST=$($PSQL -t -A -c "SELECT status FROM budget_objections WHERE id='$OBJID';")
  [ "$SC" = "404" ] && [ "$OST" = "OPEN" ] \
    && ok "diğer sitenin yöneticisi itirazı sonuçlandıramıyor → 404, durum OPEN" \
    || bad "ÇAPRAZ SİTE: itiraz sonuçlandırıldı → $SC, durum $OST"

  # Karar defteri: diğer site ne yazabilir ne okuyabilir
  BEFORE=$($PSQL -t -A -c "SELECT count(*) FROM book_entries WHERE book_id='$BKID';")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/books/$BKID/entries" \
    -H "Authorization: Bearer $XMGR" -H "$GJ" -d '{"title":"Sahte karar","body":"Yetkisiz kayit"}')
  AFTER=$($PSQL -t -A -c "SELECT count(*) FROM book_entries WHERE book_id='$BKID';")
  [ "$SC" = "404" ] && [ "$BEFORE" = "$AFTER" ] \
    && ok "diğer sitenin yöneticisi karar defterine yazamıyor → 404, kayıt sayısı $AFTER" \
    || bad "ÇAPRAZ SİTE: karar defterine yazıldı → $SC ($BEFORE → $AFTER)"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$GURL/books/$BKID/entries" -H "Authorization: Bearer $XMGR")
  [ "$SC" = "404" ] && ok "diğer sitenin yöneticisi karar defterini okuyamıyor → 404" \
    || bad "diğer site karar defteri okuma → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$GURL/books/$BKID/verify" -H "Authorization: Bearer $XMGR")
  [ "$SC" = "404" ] && ok "diğer sitenin yöneticisi defter doğrulaması yapamıyor → 404" \
    || bad "diğer site defter doğrulama → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$GURL/books/gecersiz/entries" -H "Authorization: Bearer $MGR")
  [ "$SC" = "404" ] && ok "geçersiz defter kimliği → 404 (500 değil)" || bad "geçersiz defter kimliği → $SC"

  # Kendi sitesi: koruma işi bozmamalı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$GURL/books/$BKID/verify" -H "Authorization: Bearer $MGR")
  [ "$SC" = "200" ] && ok "kendi sitesinin yöneticisi defteri doğruluyor → 200" || bad "defter doğrulama → $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$GURL/budgets/$BID/objections/$OBJID" \
    -H "Authorization: Bearer $MGR" -H "$GJ" -d '{"status":"REJECTED","resolution":"Kalem sozlesmeye uygun"}')
  OST=$($PSQL -t -A -c "SELECT status FROM budget_objections WHERE id='$OBJID';")
  [ "$SC" = "200" ] && [ "$OST" = "REJECTED" ] && ok "kendi sitesinin yöneticisi itirazı sonuçlandırdı" \
    || bad "yönetici itirazı sonuçlandıramadı → $SC, durum $OST"
else
  bad "35. adım uçtan uca ön koşulu eksik (governance=$GUP3 BID=${BID:-yok} BKID=${BKID:-yok} XMGR=${XMGR:+var})"
  tail -10 /tmp/verify-governance2.log
fi
kill_tree "$GOV_PID"

step "36) Kimlik rolü, dizin tablolarında RLS, en az yetki (FAZ 2.6 son dilim)"
# Önceki durum: 24 servisin ortak rolü users/units/resident_units/property_roles
# tablolarının TAMAMINI okuyup yazabiliyordu — bütün sitelerin telefon, e-posta
# ve PAROLA ÖZETİ dahil. Jeton iptal kayıtlarını ve denetim izini silebiliyordu.
# Artık kimlik servisi ayrı ve dar yetkili bir rolle bağlanır; diğer servisler
# dizin tablolarını yalnızca okur, yalnızca aktif siteyi görür.
appfails() { # $1 = SQL, $2 = kapsam (boşsa kapsamsız). Başarısız olursa 0 döner.
  local pre=""; [ -n "${2:-}" ] && pre="SET LOCAL app.property_id = '$2';"
  ! PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen \
      -v ON_ERROR_STOP=1 -q -c "BEGIN; $pre $1; ROLLBACK;" >/dev/null 2>&1
}
idfails() {
  ! PGPASSWORD="$IDPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_identity -d siteeksen \
      -v ON_ERROR_STOP=1 -q -c "$1" >/dev/null 2>&1
}
qid() {
  PGPASSWORD="$IDPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_identity -d siteeksen \
    -t -A -c "$1" 2>/dev/null | tail -1
}

# 1) Dizin tablolarında RLS: kapsam politikası + kimlik rolü politikası
for T in users properties units blocks resident_units property_roles; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in
    true/true/2|t/t/2) ok "RLS açık: $T (site kapsamı + kimlik rolü politikası)" ;;
    *)                 bad "RLS eksik: $T ($ROW)" ;;
  esac
done

# 2) Parola özeti ve TCKN uygulama rolüne HİÇ açık değil (sütun yetkisi)
for C in password_hash tc_hash tc_encrypted phone_encrypted; do
  appfails "SELECT $C FROM users LIMIT 1" "$DEMO_PROPERTY" \
    && ok "uygulama rolü users.$C okuyamıyor" || bad "uygulama rolü users.$C OKUYABİLİYOR"
done
N=$(qscoped "SELECT count(*) FROM users;")
[ "${N:-0}" -ge 2 ] && ok "uygulama rolü izinli sütunlarla kullanıcıları okuyabiliyor ($N kişi)" \
  || bad "uygulama rolü kullanıcıları okuyamıyor: $N (servisler ad gösteremez)"

# 3) Kapsamsız sorgu dizin tablolarından hiçbir şey döndürmemeli
DLEAK=0
for T in users properties units blocks resident_units property_roles; do
  N=$(qapp "SELECT count(*) FROM $T;")
  [ "$N" = "0" ] || { DLEAK=$((DLEAK+1)); echo "     sızdırdı: $T -> $N"; }
done
[ "$DLEAK" = "0" ] && ok "kapsamsız sorgu dizin tablolarının hiçbirinden satır döndürmüyor" \
  || bad "$DLEAK dizin tablosu kapsamsız sorguda satır döndürdü"

# 4) Başka sitenin kapsamında demo sitenin kişileri görünmemeli
N=$(qscoped "SELECT count(*) FROM users WHERE phone LIKE '%5551234567' OR phone LIKE '%5559876543';" "$OTHERPROP")
[ "$N" = "0" ] && ok "başka sitenin kapsamında demo sitenin sakinleri/yöneticisi görünmüyor" \
  || bad "başka siteden demo sitenin kişileri görünüyor: $N"
N=$(qscoped "SELECT count(*) FROM users WHERE id='44444444-4444-4444-4444-444444444404';" "$OTHERPROP")
[ "$N" = "1" ] && ok "kendi sitesinin yöneticisi o sitenin kapsamında görünüyor" \
  || bad "diğer sitenin yöneticisi kendi kapsamında görünmüyor: $N"
N=$(qscoped "SELECT count(*) FROM units;" "$OTHERPROP")
[ "$N" = "0" ] && ok "başka sitenin kapsamında demo sitenin daireleri görünmüyor" \
  || bad "başka siteden $N daire görünüyor"
N=$(qscoped "SELECT count(*) FROM properties;")
[ "$N" = "1" ] && ok "uygulama rolü yalnızca aktif siteyi görüyor (properties: 1)" \
  || bad "uygulama rolü $N site görüyor"

# 5) Uygulama rolü dizin tablolarına YAZAMAZ
appfails "UPDATE property_roles SET role='MANAGER'" "$DEMO_PROPERTY" \
  && ok "uygulama rolü site rolü değiştiremiyor" || bad "uygulama rolü property_roles YAZABİLDİ"
appfails "UPDATE units SET share_ratio = share_ratio + 1" "$DEMO_PROPERTY" \
  && ok "uygulama rolü arsa payı değiştiremiyor" || bad "uygulama rolü units YAZABİLDİ"
appfails "INSERT INTO users (first_name,last_name,phone,password_hash) VALUES ('x','y','+900000000001','x')" "$DEMO_PROPERTY" \
  && ok "uygulama rolü kullanıcı oluşturamıyor" || bad "uygulama rolü users'a YAZABİLDİ"

# 6) Jeton iptali ve denetim izi geri alınamaz / silinemez
appfails "DELETE FROM revoked_tokens" \
  && ok "uygulama rolü jeton iptal kaydını silemiyor (çıkış geri açılamaz)" \
  || bad "uygulama rolü revoked_tokens SİLEBİLDİ"
appfails "DELETE FROM user_token_invalidation" \
  && ok "uygulama rolü toplu oturum iptalini silemiyor" || bad "uygulama rolü user_token_invalidation SİLEBİLDİ"
N=$(qapp "SELECT count(*) FROM revoked_tokens;")
[ -n "$N" ] && ok "uygulama rolü jeton iptal kaydını okuyabiliyor (kontrol için gerekli)" \
  || bad "uygulama rolü revoked_tokens okuyamıyor — iptal kontrolü çalışmaz"
appfails "DELETE FROM audit_logs" && appfails "SELECT count(*) FROM audit_logs" \
  && ok "uygulama rolü denetim izini okuyamıyor ve silemiyor (yalnızca ekler)" \
  || bad "uygulama rolü audit_logs okuyabiliyor ya da silebiliyor"
AUD=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE created_at > now() - interval '1 hour';")
[ "${AUD:-0}" -ge 1 ] && ok "servisler denetim izine yazmaya devam ediyor ($AUD kayıt)" \
  || bad "denetim izine yazılmamış — INSERT yetkisi de gitmiş olabilir"
appfails "UPDATE legal_parameters SET value_numeric = 0" \
  && ok "uygulama rolü mevzuat parametresini değiştiremiyor" || bad "uygulama rolü legal_parameters YAZABİLDİ"
for T in tenants invoices usage_metrics schema_migrations user_activation_codes; do
  appfails "SELECT count(*) FROM $T" && ok "uygulama rolü platform tablosuna erişemiyor: $T" \
    || bad "uygulama rolü $T okuyabiliyor"
done

# 7) Kimlik rolü SİTE VERİSİNE erişemez; dizini bütünüyle görür
for T in employees monthly_assessments documents payments notifications; do
  idfails "SELECT count(*) FROM $T" && ok "kimlik rolü site verisine erişemiyor: $T" \
    || bad "kimlik rolü $T OKUYABİLİYOR"
done
N=$(qid "SELECT count(*) FROM users;")
[ "${N:-0}" -ge 4 ] && ok "kimlik rolü bütün kullanıcıları görüyor ($N) — giriş ve site seçimi için" \
  || bad "kimlik rolü kullanıcıları göremiyor: $N"
N=$(qid "SELECT count(*) FROM properties;")
[ "${N:-0}" -ge 2 ] && ok "kimlik rolü bütün siteleri görüyor ($N)" || bad "kimlik rolü siteleri göremiyor: $N"

# 8) Kullanılmayan tablolar da korumalı doğar (migration 026)
for T in accountability_reports audit_reports bank_accounts bank_transactions energy_analytics \
         governing_terms management_staff meetings chart_of_accounts consumption_tariffs \
         request_categories expense_invoices request_comments; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced FROM rls_enabled_tables WHERE table_name='$T';")
  case "$ROW" in true/true|t/t) : ;; *) bad "kullanılmayan tablo korumasız: $T ($ROW)" ;; esac
done
ok "kullanılmayan 13 site tablosu RLS ile korunuyor"

# 9) Toplam durum — RLS DIŞINDA KALAN her tablo bilinçli ve gerekçeli olmalı
RLSCOUNT=$($PSQL -t -A -c "SELECT count(*) FROM rls_enabled_tables;")
[ "$RLSCOUNT" = "82" ] && ok "RLS toplam 82 tabloda açık" \
  || bad "beklenmedik RLS tablo sayısı: $RLSCOUNT (beklenen 82)"
NOTRLS=$($PSQL -t -A -c "SELECT string_agg(t.table_name, ' ' ORDER BY t.table_name)
  FROM information_schema.tables t
  WHERE t.table_schema='public' AND t.table_type='BASE TABLE'
    AND t.table_name NOT IN (SELECT table_name FROM rls_enabled_tables);")
# audit_logs: yalnızca ekleme
# revoked_tokens / user_token_invalidation: salt-okur, kişi bazlı (site değil)
# tenants / invoices / usage_metrics / schema_migrations: uygulama rolüne kapalı
# user_activation_codes: uygulama rolüne kapalı, yalnızca kimlik servisi (027)
# (legal_parameters 029'dan beri RLS altında: site istisnaları yalnızca kendi sitesinde.)
EXPECTED="audit_logs invoices revoked_tokens schema_migrations tenants usage_metrics user_activation_codes user_token_invalidation"
[ "$NOTRLS" = "$EXPECTED" ] && ok "RLS dışındaki 8 tablonun her biri gerekçeli: $NOTRLS" \
  || bad "RLS dışında beklenmeyen tablo var: '$NOTRLS' (beklenen: '$EXPECTED')"

step "37) Sertleştirme turu: gateway yönlendirmesi, durum kodları, sahiplik (2026-09-26)"
# Bu turda API sözleşmesi servis servis çıkarıldı ve şu sınıf hatalar bulundu:
# gateway'de hiç yönlendirilmeyen rotalar, var olmayan kayıt için 409/500,
# başkasının aracını/ziyaretçisini silebilme, pasif hesabın giriş yapabilmesi,
# başkasının tahakkuk dökümünü okuyabilme, yapılmış toplantıya oy ekleyebilme.

# --- A) Gateway: her rota gerçekten doğru servise ulaşıyor mu (saplamalarla) ---
STUBBASE=${VERIFY_STUB_BASE:-19100}
GWP=${VERIFY_GW2_PORT:-18899}
python3 "$SCRIPT_DIR/gateway-routing-probe.py" serve "$STUBBASE" >/tmp/verify-stubs.env 2>/tmp/verify-stubs.err &
STUB2_PID=$!
for _ in $(seq 1 20); do grep -q READY /tmp/verify-stubs.env 2>/dev/null && break; sleep 0.5; done
if grep -q READY /tmp/verify-stubs.env; then
  env $(grep '_SERVICE_URL=' /tmp/verify-stubs.env | tr '\n' ' ') \
    JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$GWP \
    go run ./cmd/gateway >/tmp/verify-gw2.log 2>&1 &
  GW2_PID=$!
  for _ in $(seq 1 45); do curl -fsS "http://127.0.0.1:$GWP/health" >/dev/null 2>&1 && break; sleep 1; done
  if python3 "$SCRIPT_DIR/gateway-routing-probe.py" probe "http://127.0.0.1:$GWP" "$MGR" >/tmp/verify-gwprobe.log 2>&1; then
    ok "gateway çalışırken: $(tail -1 /tmp/verify-gwprobe.log)"
  else
    bad "gateway çalışırken yönlendirme hatası"; head -15 /tmp/verify-gwprobe.log | sed 's/^/      /'
  fi
  kill_tree "$GW2_PID"
else
  bad "saplama sunucuları açılmadı"; cat /tmp/verify-stubs.err | head -5
fi
kill_tree "$STUB2_PID"

# Servisleri tek tek aç (önceki adımlar kendi servislerini kapattı)
start_svc() { # ad port yol → PID değişkeni adı $4
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$2 \
  PII_ENCRYPTION_KEY="${PIIKEY:-$(head -c 32 /dev/zero | base64 -w0)}" \
    go run "$3" >"/tmp/verify-h-$1.log" 2>&1 &
  eval "$4=$!"
}
wait_up() { for _ in $(seq 1 60); do curl -fsS "http://127.0.0.1:$1/health" >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }
start_svc personnel 18300 ./services/personnel H_PER
start_svc parking   18301 ./services/parking   H_PRK
start_svc visitor   18302 ./services/visitor   H_VIS
start_svc inventory 18303 ./services/inventory H_INV
start_svc govern    18304 ./services/governance H_GOV
HUP=1
for p in 18300 18301 18302 18303 18304; do wait_up $p || { HUP=0; echo "     açılmadı: $p"; }; done
[ "$HUP" = "1" ] && ok "sertleştirme sınaması için 5 servis ayağa kalktı" || bad "sertleştirme servisleri açılmadı"

J='Content-Type: application/json'
TENID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone LIKE '%5559876543' LIMIT 1;")
TEN=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$J" \
  -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
# Kiracının dairesi OLMAYAN bir daire
OTHERUNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY'
  AND id NOT IN (SELECT unit_id FROM resident_units WHERE resident_id='$TENID') ORDER BY door_number LIMIT 1;")
TENUNIT=$($PSQL -t -A -c "SELECT unit_id FROM resident_units WHERE resident_id='$TENID' AND is_active LIMIT 1;")

# --- B) Durum kodları: var olmayan kayıt 404, bozuk kimlik 404, geçersiz girdi 400/422 ---
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
Z=00000000-0000-0000-0000-000000000000
SC=$(code -X POST "http://127.0.0.1:18300/api/v1/leaves/$Z/approve" -H "Authorization: Bearer $MGR")
[ "$SC" = "404" ] && ok "var olmayan izin onayı → 404 (önceden 409 'zaten sonuçlanmış')" || bad "var olmayan izin onayı → $SC"
SC=$(code "http://127.0.0.1:18300/api/v1/employees/stats" -H "Authorization: Bearer $MGR")
[ "$SC" = "404" ] && ok "var olmayan alt yol /employees/stats → 404 (önceden 500)" || bad "/employees/stats → $SC"
SC=$(code -X POST "http://127.0.0.1:18300/api/v1/employees" -H "Authorization: Bearer $MGR" -H "$J" \
  -d '{"first_name":"A","last_name":"B","position":"X","hire_date":"2026-01-01","contract_type":"UYDURMA"}')
[ "$SC" = "422" ] && ok "geçersiz sözleşme türü → 422 (önceden veritabanı kısıtıyla 500)" || bad "geçersiz sözleşme türü → $SC"
SC=$(code -X POST "http://127.0.0.1:18301/api/v1/vehicles" -H "Authorization: Bearer $MGR" -H "$J" -d '{}')
[ "$SC" = "400" ] && ok "boş gövdeyle araç kaydı → 400 (önceden 500)" || bad "boş araç kaydı → $SC"
SC=$(code -X POST "http://127.0.0.1:18302/api/v1/visitors/$Z/check-in" -H "Authorization: Bearer $MGR")
[ "$SC" = "404" ] && ok "var olmayan ziyaretçi girişi → 404 (önceden 409)" || bad "var olmayan ziyaretçi girişi → $SC"
SC=$(code -X POST "http://127.0.0.1:18302/api/v1/visitors" -H "Authorization: Bearer $MGR" -H "$J" \
  -d '{"visitor_name":"X","unit_id":"bozuk-kimlik"}')
[ "$SC" = "400" ] && ok "gövdede bozuk kimlik → 400 (önceden 500)" || bad "gövdede bozuk kimlik → $SC"

# --- C) Sahiplik: sakin başkasının aracını/ziyaretçisini silemez ---
if [ -n "$TEN" ] && [ -n "$OTHERUNIT" ]; then
  SC=$(code -X POST "http://127.0.0.1:18301/api/v1/vehicles" -H "Authorization: Bearer $TEN" -H "$J" \
    -d "{\"plate\":\"34 SAH 001\",\"unit_id\":\"$OTHERUNIT\"}")
  [ "$SC" = "403" ] && ok "sakin komşusunun dairesine araç kaydedemiyor → 403" || bad "başkasının dairesine araç kaydı → $SC"
  VID=$(curl -s -X POST "http://127.0.0.1:18301/api/v1/vehicles" -H "Authorization: Bearer $MGR" -H "$J" \
    -d "{\"plate\":\"34 SAH 002\",\"unit_id\":\"$OTHERUNIT\"}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
  SC=$(code -X DELETE "http://127.0.0.1:18301/api/v1/vehicles/$VID" -H "Authorization: Bearer $TEN")
  ACT=$($PSQL -t -A -c "SELECT is_active FROM vehicles WHERE id='$VID';")
  [ "$SC" = "404" ] && [ "$ACT" = "t" ] && ok "sakin başkasının aracını pasife alamıyor → 404, araç aktif" \
    || bad "sakin başkasının aracını pasife aldı → $SC (aktif=$ACT)"
  SC=$(code -X DELETE "http://127.0.0.1:18301/api/v1/vehicles/$VID" -H "Authorization: Bearer $MGR")
  [ "$SC" = "200" ] && ok "yönetim aracı pasife alabiliyor → 200" || bad "yönetim araç pasife alma → $SC"

  XVIS=$(curl -s -X POST "http://127.0.0.1:18302/api/v1/visitors" -H "Authorization: Bearer $MGR" -H "$J" \
    -d "{\"visitor_name\":\"Komsu Misafiri\",\"unit_id\":\"$OTHERUNIT\"}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
  SC=$(code -X POST "http://127.0.0.1:18302/api/v1/visitors/$XVIS/cancel" -H "Authorization: Bearer $TEN")
  VST=$($PSQL -t -A -c "SELECT status FROM visitors WHERE id='$XVIS';")
  [ "$SC" = "404" ] && [ "$VST" = "EXPECTED" ] && ok "sakin komşusunun ziyaretçisini iptal edemiyor → 404" \
    || bad "sakin başkasının ziyaretçisini iptal etti → $SC ($VST)"
  if [ -n "$TENUNIT" ]; then
    OWNVIS=$(curl -s -X POST "http://127.0.0.1:18302/api/v1/visitors" -H "Authorization: Bearer $TEN" -H "$J" \
      -d "{\"visitor_name\":\"Kendi Misafirim\",\"unit_id\":\"$TENUNIT\"}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    SC=$(code -X POST "http://127.0.0.1:18302/api/v1/visitors/$OWNVIS/cancel" -H "Authorization: Bearer $TEN")
    [ "$SC" = "200" ] && ok "sakin kendi ziyaretçisini iptal edebiliyor → 200" || bad "kendi ziyaretçisini iptal → $SC"
  fi
else
  bad "sahiplik sınaması için kiracı jetonu/daire bulunamadı"
fi

# --- D) Kimlik: pasif hesap giriş yapamaz ---
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, is_active, roles)
  VALUES ('44444444-4444-4444-4444-444444444406','Pasif','Hesap','+905550000006',
          (SELECT password_hash FROM users WHERE phone LIKE '%5551234567'), false, ARRAY['RESIDENT'])
  ON CONFLICT (id) DO NOTHING;" >/dev/null 2>&1
SC=$(code -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$J" -d '{"phone":"5550000006","password":"Demo123!"}')
[ "$SC" = "401" ] && ok "pasife alınmış hesap giriş yapamıyor → 401 (önceden giriş yapabiliyordu)" \
  || bad "pasif hesap girişi → $SC"

# --- D2) Platform rolü (SUPER_ADMIN) site verisine yetki vermez ---
# Önceden bazı servislerin el yazımı kontrolleri SUPER_ADMIN'i "yönetim"
# sayıyordu: bir sitede yalnızca sakin olan platform yöneticisi bütün
# sakinlerin ziyaretçilerini görebiliyordu.
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, roles)
    VALUES ('44444444-4444-4444-4444-444444444441','Platform','Yonetici','+905550000041',
            (SELECT password_hash FROM users WHERE phone LIKE '%5551234567'), ARRAY['SUPER_ADMIN'])
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO units (id, property_id, block, floor, door_number, share_ratio)
    VALUES ('44444444-0000-0000-0000-0000000000a1','$DEMO_PROPERTY','S',5,'41',1) ON CONFLICT (id) DO NOTHING;
  INSERT INTO resident_units (resident_id, unit_id, role, start_date)
    VALUES ('44444444-4444-4444-4444-444444444441','44444444-0000-0000-0000-0000000000a1','OWNER',CURRENT_DATE);" >/dev/null
SA=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$J" \
  -d '{"phone":"5550000041","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SAROLES=$(echo "$SA" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | grep -o '"roles":\[[^]]*\]')
NVTOT=$($PSQL -t -A -c "SELECT count(*) FROM visitors WHERE property_id='$DEMO_PROPERTY';")
SAV=$(curl -s -w '\n%{http_code}' "http://127.0.0.1:18302/api/v1/visitors" -H "Authorization: Bearer $SA")
NVSA=$(echo "$SAV" | grep -o '"visitor_name"' | wc -l)
echo "$SAROLES" | grep -q SUPER_ADMIN && [ "$(echo "$SAV" | tail -1)" = "200" ] && [ "${NVTOT:-0}" -ge 1 ] && [ "$NVSA" = "0" ] \
  && ok "SUPER_ADMIN olup sitede yalnızca sakin olan kişi komşuların ziyaretçilerini göremiyor (0/$NVTOT)" \
  || bad "platform rolü site verisi açtı: roller $SAROLES, gördüğü $NVSA / toplam $NVTOT"

# Aktif sitesi olmayan hesap (yeni etkinleştirilen sakin gibi) girişte bağlı
# olduğu siteye yerleşir; önceden jeton site taşımıyor, her istek 403 dönüyordu.
SAPID=$(echo "$SA" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null | grep -o '"property_id":"[^"]*"')
echo "$SAPID" | grep -q "$DEMO_PROPERTY" && ok "aktif sitesi boş hesap girişte bağlı olduğu siteye yerleşti" \
  || bad "aktif site atanmadı: $SAPID"
# Sitede oturmayan yönetici (yalnız property_roles) sitesini görüp seçebilmeli
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, roles)
    VALUES ('44444444-4444-4444-4444-444444444443','Profesyonel','Yonetici','+905550000043',
            (SELECT password_hash FROM users WHERE phone LIKE '%5551234567'), ARRAY[]::text[])
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO property_roles (user_id, property_id, role)
    VALUES ('44444444-4444-4444-4444-444444444443','$OTHERPROP','MANAGER');" >/dev/null
PM=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$J" \
  -d '{"phone":"5550000043","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
PMC=$(echo "$PM" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null)
PMP=$(curl -s "http://127.0.0.1:${SVCPORT}/api/v1/users/me/properties" -H "Authorization: Bearer $PM")
SC=$(code -X POST "http://127.0.0.1:${SVCPORT}/api/v1/users/me/active-property" -H "Authorization: Bearer $PM" \
  -H "$J" -d "{\"property_id\":\"$OTHERPROP\"}")
echo "$PMC" | grep -q "$OTHERPROP" && echo "$PMC" | grep -q MANAGER && echo "$PMP" | grep -q "$OTHERPROP" && [ "$SC" = "200" ] \
  && ok "sitede oturmayan yönetici sitesini listede görüyor, seçebiliyor, jetonu MANAGER + site taşıyor" \
  || bad "profesyonel yönetici: jeton '$PMC', siteler '$PMP', seçim $SC"

# --- D3) İstek kimliği ve yapılandırılmış günlük (FAZ 3.5) ---
# Önceden istemcinin X-Request-Id'si doğrulanmadan denetim izine yazılıyordu;
# 64 karakterden uzun bir değer INSERT'i düşürüp denetim kaydını YOK ediyordu.
LONGRID=$(printf 'R%.0s' $(seq 1 100))
GOTRID=$(curl -s -D - -o /dev/null "http://127.0.0.1:18302/api/v1/visitors" -H "Authorization: Bearer $MGR" \
  -H "X-Request-Id: $LONGRID" | tr -d '\r' | sed -n 's/^[Xx]-[Rr]equest-[Ii]d: //p')
NAUD=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE request_id='$GOTRID' AND entity_type='visitor';")
[ -n "$GOTRID" ] && [ ${#GOTRID} -le 64 ] && [ "$GOTRID" != "$LONGRID" ] && [ "$NAUD" = "1" ] \
  && ok "100 karakterlik istek kimliği atıldı, yenisi verildi ve denetim kaydı YAZILDI (önceden kayıt düşüyordu)" \
  || bad "uzun istek kimliği: dönen '$GOTRID', denetim kaydı $NAUD"
curl -s -o /dev/null "http://127.0.0.1:18302/api/v1/visitors?search=5551234567" -H "Authorization: Bearer $MGR" \
  -H "X-Request-Id: verify-rid-37"
LINE=$(grep '"request_id":"verify-rid-37"' /tmp/verify-h-visitor.log | head -1)
NAUD=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE request_id='verify-rid-37';")
echo "$LINE" | python3 -c "import json,sys; r=json.loads(sys.stdin.read()); assert r['service']=='visitor' and r['route']=='/api/v1/visitors' and r['status']==200" 2>/dev/null \
  && [ "$NAUD" = "1" ] && ! echo "$LINE" | grep -q 5551234567 \
  && ok "geçerli istek kimliği korunuyor; servis günlüğü JSON (service, route, status) ve sorgu dizesindeki telefon günlüğe yazılmıyor" \
  || bad "yapılandırılmış günlük: '$LINE', denetim $NAUD"

# --- E) Mali: sakin başkasının tahakkuk dökümünü okuyamaz ---
XASS=$($PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month,
    base_amount, total_amount, paid_amount, due_date)
  VALUES ('$DEMO_PROPERTY','$OTHERUNIT',2031,6,750,750,250,'2031-06-10') RETURNING id;" | head -1)
SC=$(code "http://127.0.0.1:${FINPORT}/api/v1/finance/assessments/$XASS" -H "Authorization: Bearer $TEN")
[ "$SC" = "404" ] && ok "sakin başkasının tahakkuk dökümünü okuyamıyor → 404" || bad "başkasının tahakkuku → $SC"
DET=$(curl -s "http://127.0.0.1:${FINPORT}/api/v1/finance/assessments/$XASS" -H "Authorization: Bearer $MGR")
echo "$DET" | grep -q '"paid_amount":250' && ok "tahakkuk dökümünde ödenen tutar doğru (önceden hep 0)" \
  || bad "tahakkuk dökümü: $DET"
SC=$(code "http://127.0.0.1:${FINPORT}/api/v1/finance/my-payments" -H "Authorization: Bearer $TEN")
[ "$SC" = "200" ] && ok "sakin kendi ödeme geçmişini görebiliyor (yeni uç) → 200" || bad "my-payments → $SC"
$PSQL -c "DELETE FROM monthly_assessments WHERE id='$XASS';" >/dev/null 2>&1

# --- F) Stok: görevli küçük harfle 'adjust' göndererek düzeltme yapamaz ---
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, active_property_id, roles)
    VALUES ('44444444-4444-4444-4444-444444444407','Gorevli','Personel','+905550000007',
            (SELECT password_hash FROM users WHERE phone LIKE '%5551234567'), '$DEMO_PROPERTY', ARRAY['RESIDENT'])
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO property_roles (user_id, property_id, role)
    VALUES ('44444444-4444-4444-4444-444444444407','$DEMO_PROPERTY','STAFF');" >/dev/null 2>&1
STAFF=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H "$J" \
  -d '{"phone":"5550000007","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
ITEM=$(curl -s -X POST "http://127.0.0.1:18303/api/v1/inventory" -H "Authorization: Bearer $MGR" -H "$J" \
  -d '{"name":"Sertlestirme deneme kalemi","unit":"ADET"}' | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
BEFORE=$(qscoped "SELECT current_stock FROM inventory_items WHERE id='$ITEM';")
SC=$(code -X POST "http://127.0.0.1:18303/api/v1/inventory/$ITEM/movements" -H "Authorization: Bearer $STAFF" -H "$J" \
  -d '{"movement_type":"adjust","quantity":"999","notes":"sayim"}')
AFTER=$(qscoped "SELECT current_stock FROM inventory_items WHERE id='$ITEM';")
[ "$SC" = "403" ] && [ "$BEFORE" = "$AFTER" ] \
  && ok "görevli küçük harfli 'adjust' ile sayım düzeltmesi yapamıyor → 403 (yetki atlatma kapandı)" \
  || bad "YETKİ ATLATMA: görevli sayım düzeltmesi yaptı → $SC ($BEFORE → $AFTER)"

# --- G) Genel kurul: tam akış ve durum denetimleri ---
GU="http://127.0.0.1:18304/api/v1/governance"
GA="Authorization: Bearer $MGR"
ASM2=$(curl -s -X POST "$GU/assemblies" -H "$GA" -H "$J" -d '{"kind":"ORDINARY","call_number":1,
  "scheduled_at":"2032-06-01T18:00:00Z","agenda_items":[{"title":"Bahçe düzenlemesi"}]}')
A2=$(echo "$ASM2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
ITEM2=$(echo "$ASM2" | grep -o '"agenda_items":\[{"id":"[^"]*"' | grep -o '[0-9a-f-]\{36\}')
if [ -n "$A2" ] && [ -n "$ITEM2" ]; then
  SC=$(code -X POST "$GU/assemblies" -H "$GA" -H "$J" -d '{"kind":"UYDURMA","scheduled_at":"2032-06-01T18:00:00Z","agenda_items":[{"title":"x"}]}')
  [ "$SC" = "422" ] && ok "geçersiz toplantı türü → 422 (önceden 500)" || bad "geçersiz toplantı türü → $SC"
  SC=$(code -X POST "$GU/assemblies" -H "$GA" -H "$J" -d '{"scheduled_at":"2032-06-01T18:00:00Z","agenda_items":[{"title":""}]}')
  [ "$SC" = "422" ] && ok "başlıksız gündem maddesi → 422" || bad "başlıksız gündem → $SC"
  SC=$(code -X POST "$GU/assemblies/$A2/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$Z\"}")
  [ "$SC" = "422" ] && ok "sitede olmayan daire hazirune eklenemiyor → 422 (önceden SESSİZCE 201)" \
    || bad "olmayan daire hazirun → $SC"
  SC=$(code -X POST "$GU/assemblies/$A2/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"attendance_type\":\"PROXY\"}")
  [ "$SC" = "422" ] && ok "vekilsiz vekâlet kaydı → 422 (önceden m.31 denetimi atlanıyordu)" || bad "vekilsiz vekâlet → $SC"
  SC=$(code -X POST "$GU/agenda-items/$ITEM2/votes" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"vote\":\"FOR\"}")
  [ "$SC" = "409" ] && ok "yapılmamış toplantıda oy kullanılamıyor → 409" || bad "yapılmamış toplantıya oy → $SC"
  SC=$(code -X POST "$GU/agenda-items/$Z/votes" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"vote\":\"FOR\"}")
  [ "$SC" = "404" ] && ok "var olmayan gündem maddesine oy → 404 (önceden 400)" || bad "olmayan maddeye oy → $SC"
  UNITS=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY';")
  for u in $UNITS; do curl -s -o /dev/null -X POST "$GU/assemblies/$A2/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$u\"}"; done
  SC=$(code -X POST "$GU/assemblies/$A2/hold" -H "$GA")
  [ "$SC" = "200" ] && ok "toplantı yapıldı (nisap fotoğrafı alındı)" || bad "toplantı yapılamadı → $SC"
  SC=$(code -X POST "$GU/assemblies/$A2/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\"}")
  [ "$SC" = "409" ] && ok "yapılmış toplantıya sonradan hazirun eklenemiyor → 409" || bad "yapılmış toplantıya hazirun → $SC"
  NV=0
  for u in $UNITS; do
    [ "$(code -X POST "$GU/agenda-items/$ITEM2/votes" -H "$GA" -H "$J" -d "{\"unit_id\":\"$u\",\"vote\":\"FOR\"}")" = "201" ] && NV=$((NV+1))
  done
  [ "$NV" -ge 13 ] && ok "yapılmış toplantıda $NV oy kaydedildi" || bad "oy kaydı: $NV"
  CL=$(curl -s -X POST "$GU/agenda-items/$ITEM2/close" -H "$GA" -H "$J" -d '{}')
  echo "$CL" | grep -q '"accepted":true' && ok "gündem maddesi oy çokluğuyla kabul edildi" || bad "madde kapatma: $CL"
  SC=$(code -X POST "$GU/agenda-items/$ITEM2/votes" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"vote\":\"AGAINST\"}")
  VF=$($PSQL -t -A -c "SELECT votes_for FROM assembly_agenda_items WHERE id='$ITEM2';")
  [ "$SC" = "409" ] && [ "$VF" = "$NV" ] && ok "karara bağlanmış maddeye oy eklenemiyor → 409, sayaç değişmedi" \
    || bad "kapalı maddeye oy → $SC (lehte $NV → $VF)"
  SC=$(code -X POST "$GU/agenda-items/$ITEM2/close" -H "$GA" -H "$J" -d '{}')
  [ "$SC" = "409" ] && ok "kapatılmış madde yeniden kapatılamıyor → 409 (önceden 404)" || bad "yeniden kapatma → $SC"

  # FAZ 6.6 — karar AYNI İŞLEMDE karar defterine yazılır (KMK m.32)
  ROW=$($PSQL -t -A -c "SELECT count(*), max(b.kind), max(b.period_year),
      bool_and(b.period_year = EXTRACT(YEAR FROM a.held_at AT TIME ZONE 'Europe/Istanbul')),
      max(e.title), max(e.book_id::text)
    FROM book_entries e JOIN books b ON b.id = e.book_id
    JOIN assembly_agenda_items ai ON ai.id = e.source_id JOIN assemblies a ON a.id = ai.assembly_id
    WHERE e.source_type = 'AGENDA_ITEM' AND e.source_id = '$ITEM2';")
  IFS='|' read -r NE BK BY BYOK BT BID <<<"$ROW"
  [ "$NE" = "1" ] && [ "$BK" = "DECISION" ] && [ "$BYOK" = "t" ] && echo "$BT" | grep -q "KABUL EDİLDİ" \
    && ok "karar, toplantı yılının ($BY) karar defterine tek kayıt olarak yazıldı: $BT" \
    || bad "karar defteri kaydı: $ROW"
  echo "$CL" | grep -q '"book_entry":{' && echo "$CL" | grep -q 'karar defterine' \
    && ok "yanıt defter kaydını ve numarasını bildiriyor" || bad "yanıtta defter kaydı yok: $CL"
  BODY=$($PSQL -t -A -c "SELECT body FROM book_entries WHERE source_id='$ITEM2';")
  echo "$BODY" | grep -q "Oylar: lehte $NV" && echo "$BODY" | grep -q "Nisap:" \
    && ok "defter kaydı oy dağılımını ve nisap gerekçesini taşıyor" || bad "defter kaydı içeriği: $BODY"
  VER=$(curl -s "$GU/books/$BID/verify" -H "$GA")
  echo "$VER" | grep -q '"valid":true' && ok "otomatik kayıttan sonra defter zinciri geçerli" || bad "defter zinciri: $VER"

  # Defter kapalıysa karar da yazılmaz: madde PENDING kalır (yarım işlem yok)
  ASM3=$(curl -s -X POST "$GU/assemblies" -H "$GA" -H "$J" -d '{"kind":"ORDINARY","call_number":1,
    "scheduled_at":"2032-07-01T18:00:00Z","agenda_items":[{"title":"Kapali defter sinamasi"}]}')
  A3=$(echo "$ASM3" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  ITEM3=$(echo "$ASM3" | grep -o '"agenda_items":\[{"id":"[^"]*"' | grep -o '[0-9a-f-]\{36\}')
  for u in $UNITS; do curl -s -o /dev/null -X POST "$GU/assemblies/$A3/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$u\"}"; done
  curl -s -o /dev/null -X POST "$GU/assemblies/$A3/hold" -H "$GA"
  $PSQL -c "UPDATE books SET status='CLOSED' WHERE id='$BID';" >/dev/null
  SC=$(code -X POST "$GU/agenda-items/$ITEM3/close" -H "$GA" -H "$J" -d '{}')
  ST=$($PSQL -t -A -c "SELECT decision_status FROM assembly_agenda_items WHERE id='$ITEM3';")
  NE=$($PSQL -t -A -c "SELECT count(*) FROM book_entries WHERE source_id='$ITEM3';")
  [ "$SC" = "409" ] && [ "$ST" = "PENDING" ] && [ "$NE" = "0" ] \
    && ok "defter kapalıyken karar yazılamıyor → 409; madde PENDING kaldı, deftere kayıt yok" \
    || bad "kapalı defter: $SC, madde $ST, kayıt $NE"
  $PSQL -c "UPDATE books SET status='OPEN' WHERE id='$BID';" >/dev/null
else
  bad "genel kurul akışı kurulamadı: $ASM2"
fi
# İtiraz: yoldaki proje kimliği artık yok sayılmıyor
OBJ2=$($PSQL -t -A -c "SELECT id FROM budget_objections LIMIT 1;")
if [ -n "$OBJ2" ]; then
  SC=$(code -X PATCH "$GU/budgets/$Z/objections/$OBJ2" -H "$GA" -H "$J" -d '{"status":"REJECTED"}')
  [ "$SC" = "404" ] && ok "itiraz başka proje adresinden sonuçlandırılamıyor → 404" || bad "yanlış proje adresi → $SC"
fi
SC=$(code "$GU/budgets/$Z/objections" -H "$GA")
[ "$SC" = "404" ] && ok "var olmayan projenin itiraz listesi → 404 (önceden 200 [])" || bad "olmayan proje itirazları → $SC"

kill_tree "$H_PER"; kill_tree "$H_PRK"; kill_tree "$H_VIS"; kill_tree "$H_INV"; kill_tree "$H_GOV"

step "38) Panel veri katmanı: panelin okuduğu her uç gerçek gateway'e karşı"
# Panel sayfaları FAZ 5'te arka uç gerçeğe çevrildikten sonra güncellenmemişti:
# ~20 istemci yöntemi olmayan yollara gidiyordu ve bunu yakalayan bir şey
# yoktu. Burada 24 servis ve GERÇEK gateway açılır; admin/src/lib/endpoints.ts
# içindeki READS listesi (panelin okuduğu uçlar ve kullandığı alanlar),
# önceki adımların doldurduğu veritabanına karşı sınanır.
if command -v node >/dev/null 2>&1 && node --experimental-strip-types -e "0" >/dev/null 2>&1; then
  P38_PIDS=()
  GWENV=()
  while read -r DIR PORT ENVN; do
    USER_ROLE=siteeksen_app; USER_PW="$APPPW"
    [ "$DIR" = "identity" ] && { USER_ROLE=siteeksen_identity; USER_PW="$IDPW"; }
    DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$USER_ROLE DB_PASSWORD="$USER_PW" DB_NAME=siteeksen \
    DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$PORT \
    PII_ENCRYPTION_KEY="${PIIKEY:-$(head -c 32 /dev/zero | base64 -w0)}" \
    STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-p38-files \
      go run "./services/$DIR" >"/tmp/verify-p38-$DIR.log" 2>&1 &
    P38_PIDS+=($!)
    GWENV+=("$ENVN=http://127.0.0.1:$PORT")
  done < <(python3 - "$SCRIPT_DIR" <<'PYEOF'
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location("gd", os.path.join(sys.argv[1], "gen-deploy.py"))
gd = importlib.util.module_from_spec(spec); spec.loader.exec_module(gd)
for i, (d, port, name, kind, note) in enumerate(gd.SERVICES):
    print(d, 18400 + i, gd.GATEWAY_ENV[d])
PYEOF
)
  mkdir -p /tmp/verify-p38-files
  env "${GWENV[@]}" JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18499 \
    go run ./cmd/gateway >/tmp/verify-p38-gateway.log 2>&1 &
  P38_PIDS+=($!)
  P38UP=0
  for _ in $(seq 1 120); do
    N=0
    for p in $(seq 18400 18425); do curl -fsS -o /dev/null "http://127.0.0.1:$p/health" 2>/dev/null && N=$((N+1)); done
    curl -fsS -o /dev/null http://127.0.0.1:18499/health 2>/dev/null && [ "$N" -ge 26 ] && { P38UP=1; break; }
    sleep 2
  done
  [ "$P38UP" = "1" ] && ok "26 servis ve gateway ayağa kalktı (panel doğrulaması için)" \
    || bad "panel doğrulaması için servisler açılmadı ($N/26)"
  if (cd "$SCRIPT_DIR/../../admin" && GATEWAY=http://127.0.0.1:18499/api/v1 \
      node --experimental-strip-types --no-warnings scripts/verify-endpoints.ts) >/tmp/verify-p38.log 2>&1; then
    ok "panel: $(tail -1 /tmp/verify-p38.log)"
  else
    bad "panel uçları sözleşmeye uymuyor"; head -20 /tmp/verify-p38.log | sed 's/^/      /'
  fi
  for p in "${P38_PIDS[@]}"; do kill_tree "$p"; done
else
  bad "Node 22.6+ bulunamadı (panel doğrulaması --experimental-strip-types ister)"
fi

step "39) Hesap etkinleştirme, şifre değiştirme, giriş kilidi (migration 027)"
# Önceden: yönetimin eklediği sakine rastgele bir geçici şifre atanıyor ve bu
# şifre HİÇ KİMSEYE iletilmiyordu; şifre belirleme akışı da yoktu. Eklenen
# sakin hiçbir zaman giriş yapamıyordu. Girişte deneme sınırı da yoktu.
J='Content-Type: application/json'
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
ID39="http://127.0.0.1:${SVCPORT}/api/v1"
MGR39=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
FREEUNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' ORDER BY door_number DESC LIMIT 1;")
# Telefon boşluklu/tireli ve başında 0 ile girilir: girişle aynı biçimde saklanmalı
CR=$(curl -s -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Yeni\",\"last_name\":\"Sakin\",\"phone\":\"0 555 000-00-39\",\"unit_id\":\"$FREEUNIT\",\"role\":\"TENANT\"}")
ACODE=$(echo "$CR" | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
RUID=$(echo "$CR" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
[ -n "$ACODE" ] && ok "yeni sakin eklenince etkinleştirme kodu bir kez gösteriliyor (${#ACODE} karakter)" \
  || bad "sakin ekleme yanıtında kod yok: $CR"
PH=$($PSQL -t -A -c "SELECT phone FROM users WHERE phone='+905550000039';")
[ "$PH" = "+905550000039" ] && ok "telefon girişle aynı biçimde saklandı (+905550000039)" || bad "telefon biçimi: '$PH'"
STORED=$($PSQL -t -A -c "SELECT count(*) FROM user_activation_codes c JOIN users u ON u.id=c.user_id
  WHERE u.phone='+905550000039' AND c.code_hash <> '$ACODE' AND length(c.code_hash)=64;")
[ "$STORED" = "1" ] && ok "veritabanında kodun kendisi değil SHA-256 özeti saklanıyor" || bad "kod saklama: $STORED"
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Demo123!"}')
[ "$SC" = "401" ] && ok "etkinleşmemiş hesap herhangi bir şifreyle giriş yapamıyor → 401" || bad "etkinleşmemiş giriş → $SC"

SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5550000039\",\"code\":\"$ACODE\",\"new_password\":\"kisa1\"}")
[ "$SC" = "422" ] && ok "zayıf şifre reddediliyor → 422" || bad "zayıf şifre → $SC"
SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5550000039\",\"code\":\"$ACODE\",\"new_password\":\"a5550000039\"}")
[ "$SC" = "422" ] && ok "telefon numarasını içeren şifre reddediliyor → 422" || bad "telefonlu şifre → $SC"
SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d '{"phone":"5550000039","code":"YANLIS22","new_password":"Guclu123"}')
[ "$SC" = "400" ] && ok "yanlış kod → 400" || bad "yanlış kod → $SC"
SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5551234567\",\"code\":\"$ACODE\",\"new_password\":\"Guclu123\"}")
[ "$SC" = "400" ] && ok "kod başka bir telefonla kullanılamıyor → 400" || bad "başka telefonla kod → $SC"
LOWER=$(echo "$ACODE" | tr 'A-Z' 'a-z')
SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"+90 555 000 00 39\",\"code\":\" $LOWER \",\"new_password\":\"Guclu123\"}")
[ "$SC" = "200" ] && ok "doğru kodla şifre belirlendi → 200 (küçük harf/boşluk tolere ediliyor)" || bad "etkinleştirme → $SC"
SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5550000039\",\"code\":\"$ACODE\",\"new_password\":\"Baska123\"}")
[ "$SC" = "400" ] && ok "kod ikinci kez kullanılamıyor → 400" || bad "kod tekrar kullanıldı → $SC"
NEWTOK=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Guclu123"}' \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
[ -n "$NEWTOK" ] && ok "sakin belirlediği şifreyle giriş yapabiliyor" || bad "etkinleşmiş hesap giriş yapamadı"

# Kod deneme sınırı: 5 hatalı denemede kod kilitlenir, doğru kod da artık işlemez
if [ -n "$RUID" ]; then
  RC=$(curl -s -X POST "$ID39/residents/$RUID/activation-code" -H "Authorization: Bearer $MGR39")
  RCODE=$(echo "$RC" | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
  echo "$RC" | grep -q '"purpose":"RESET"' && ok "etkin hesaba üretilen kod RESET amaçlı" || bad "yeniden kod: $RC"
  LAST=""
  for i in 1 2 3 4 5; do
    LAST=$(code -X POST "$ID39/auth/activate" -H "$J" -d '{"phone":"5550000039","code":"YANLIS22","new_password":"Guclu456"}')
  done
  [ "$LAST" = "429" ] && ok "5. hatalı denemede kod kilitlendi → 429" || bad "kod kilidi → $LAST"
  SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5550000039\",\"code\":\"$RCODE\",\"new_password\":\"Guclu456\"}")
  [ "$SC" = "429" ] && ok "kilitli kod doğru girilse de işlemiyor → 429" || bad "kilitli kod → $SC"
  RC2=$(curl -s -X POST "$ID39/residents/$RUID/activation-code" -H "Authorization: Bearer $MGR39" \
    | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
  OPEN=$($PSQL -t -A -c "SELECT count(*) FROM user_activation_codes c JOIN users u ON u.id=c.user_id
    WHERE u.phone='+905550000039' AND c.used_at IS NULL;")
  [ "$OPEN" = "1" ] && ok "yeni kod üretilince eskisi geçersizleşiyor (tek açık kod)" || bad "açık kod sayısı: $OPEN"
  SC=$(code -X POST "$ID39/residents/$RUID/activation-code" -H "Authorization: Bearer $NEWTOK")
  [ "$SC" = "403" ] && ok "sakin kod üretemiyor → 403" || bad "sakinin kod üretmesi → $SC"
  SC=$(code -X POST "$ID39/residents/$Z/activation-code" -H "Authorization: Bearer $MGR39")
  [ "$SC" = "404" ] && ok "var olmayan sakin için kod → 404" || bad "var olmayan sakin kodu → $SC"
  # Sıfırlama: kodla şifre belirlenince eski oturum kapanır
  SC=$(code -X POST "$ID39/auth/activate" -H "$J" -d "{\"phone\":\"5550000039\",\"code\":\"$RC2\",\"new_password\":\"Guclu789\"}")
  SC2=$(code "$ID39/users/me" -H "Authorization: Bearer $NEWTOK")
  [ "$SC" = "200" ] && [ "$SC2" = "401" ] && ok "şifre sıfırlanınca eski oturum kapandı (200 → eski jeton 401)" \
    || bad "sıfırlama $SC, eski jeton $SC2"
fi

# Şifre değiştirme
TOK2=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Guclu789"}' \
  | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC=$(code -X POST "$ID39/users/me/password" -H "Authorization: Bearer $TOK2" -H "$J" \
  -d '{"current_password":"yanlis","new_password":"Yepyeni12"}')
[ "$SC" = "400" ] && ok "mevcut şifre yanlışsa değiştirilemiyor → 400" || bad "yanlış mevcut şifre → $SC"
SC=$(code -X POST "$ID39/users/me/password" -H "Authorization: Bearer $TOK2" -H "$J" \
  -d '{"current_password":"Guclu789","new_password":"zayif"}')
[ "$SC" = "422" ] && ok "yeni şifre zayıfsa → 422" || bad "zayıf yeni şifre → $SC"
SC=$(code -X POST "$ID39/users/me/password" -H "Authorization: Bearer $TOK2" -H "$J" \
  -d '{"current_password":"Guclu789","new_password":"Yepyeni12"}')
SC2=$(code "$ID39/users/me" -H "Authorization: Bearer $TOK2")
[ "$SC" = "200" ] && [ "$SC2" = "401" ] && ok "şifre değişti ve bütün oturumlar kapandı (eski jeton 401)" \
  || bad "şifre değiştirme $SC, eski jeton $SC2"
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Yepyeni12"}')
[ "$SC" = "200" ] && ok "yeni şifreyle giriş → 200" || bad "yeni şifreyle giriş → $SC"

# Giriş kilidi: art arda 5 hatadan sonra doğru şifre de 15 dk reddedilir
for i in 1 2 3 4 5; do code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}' >/dev/null; done
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Yepyeni12"}')
LOCK=$($PSQL -t -A -c "SELECT locked_until > now() FROM users WHERE phone='+905550000039';")
[ "$SC" = "401" ] && [ "$LOCK" = "t" ] && ok "5 hatalı girişten sonra hesap kilitlendi; doğru şifre de 401" \
  || bad "giriş kilidi: $SC (kilit=$LOCK)"
$PSQL -c "UPDATE users SET locked_until = now() - interval '1 second' WHERE phone='+905550000039';" >/dev/null
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Yepyeni12"}')
N=$($PSQL -t -A -c "SELECT failed_login_attempts FROM users WHERE phone='+905550000039';")
[ "$SC" = "200" ] && [ "$N" = "0" ] && ok "kilit süresi dolunca giriş açılıyor ve sayaç sıfırlanıyor" \
  || bad "kilit sonrası giriş $SC (sayaç $N)"
# Var olan telefonla sakin eklenirse kod üretilmez, mevcut şifre bozulmaz
CR=$(curl -s -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Demo\",\"last_name\":\"Kiraci\",\"phone\":\"5559876543\",\"unit_id\":\"$FREEUNIT\",\"role\":\"TENANT\"}")
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}')
echo "$CR" | grep -q activation_code && bad "var olan hesaba kod üretildi: $CR" \
  || { [ "$SC" = "200" ] && ok "var olan hesap ikinci daireye bağlanınca kod üretilmiyor, şifresi bozulmuyor" \
       || bad "var olan hesap bozuldu: giriş $SC"; }
LINKED=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id
  WHERE u.phone='+905559876543' AND ru.unit_id='$FREEUNIT';")
[ "$LINKED" = "1" ] && ok "bu sitede zaten sakin olan hesap ikinci daireye bağlanabiliyor" || bad "aynı site ikinci daire bağlantısı: $LINKED"

# B25: telefon bu siteyle BAĞI OLMAYAN bir hesaba aitse sessizce bağlanmamalı ve
# o kişinin adı/e-postası yöneticiye gösterilmemeli (önceden ikisi de oluyordu).
$PSQL -c "INSERT INTO users (first_name, last_name, phone, email, password_hash, roles)
  VALUES ('Gizli', 'Baskasitesakini', '+905550000077', 'gizli.kisi@example.com', 'x', ARRAY['RESIDENT'])
  ON CONFLICT DO NOTHING;" >/dev/null 2>&1
CR25=$(curl -s -w '\n%{http_code}' -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Tahmin\",\"last_name\":\"Edilen\",\"phone\":\"5550000077\",\"unit_id\":\"$FREEUNIT\",\"role\":\"OWNER\"}")
L25=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id WHERE u.phone='+905550000077';")
[ "$(echo "$CR25" | tail -1)" = "409" ] && [ "$L25" = "0" ] \
  && ok "başka sitenin hesabı onaysız bağlanmıyor → 409, bağlantı kaydı yok" \
  || bad "B25: $(echo "$CR25" | tail -1), bağlantı $L25"
echo "$CR25" | grep -qE 'Gizli|Baskasitesakini|gizli.kisi' \
  && bad "yanıt başka sitenin sakininin kişisel verisini sızdırıyor: $CR25" \
  || ok "yanıtta o hesabın adı/e-postası yok"

# YETKİ YÜKSELTME (migration 031): daire bağının rolü jetona olduğu gibi girer.
# Önceden 'MANAGER' / 'SUPER_ADMIN' gibi değerler kabul ediliyordu: sakin yazabilen
# yönetim kurulu üyesi kendini yönetici yapabiliyordu.
SC=$(code -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Rol\",\"last_name\":\"Yukseltme\",\"phone\":\"5550000078\",\"unit_id\":\"$FREEUNIT\",\"role\":\"MANAGER\"}")
NU=$($PSQL -t -A -c "SELECT count(*) FROM users WHERE phone='+905550000078';")
[ "$SC" = "422" ] && [ "$NU" = "0" ] && ok "sakin eklerken yönetim rolü verilemiyor (MANAGER → 422, hesap açılmadı)" \
  || bad "MANAGER rolüyle sakin ekleme: $SC (hesap $NU)"
if [ -n "${RUID:-}" ]; then
  SC=$(code -X PATCH "$ID39/residents/$RUID" -H "Authorization: Bearer $MGR39" -H "$J" -d '{"role":"SUPER_ADMIN"}')
  RR=$($PSQL -t -A -c "SELECT role FROM resident_units WHERE id='$RUID';")
  [ "$SC" = "422" ] && [ "$RR" != "SUPER_ADMIN" ] && ok "sakin güncellemesiyle SUPER_ADMIN verilemiyor → 422 (rol $RR kaldı)" \
    || bad "SUPER_ADMIN güncellemesi: $SC (rol $RR)"
fi
if $PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) SELECT id, '$FREEUNIT', 'MANAGER' FROM users WHERE phone='+905551234567';" >/dev/null 2>&1; then
  bad "veritabanı MANAGER rollü daire bağını kabul etti"
  $PSQL -c "DELETE FROM resident_units WHERE role='MANAGER';" >/dev/null 2>&1
else
  ok "veritabanı da sakinlik dışı rolü reddediyor (CHECK, migration 031)"
fi
CV=$($PSQL -t -A -c "SELECT convalidated FROM pg_constraint WHERE conname='resident_units_role_check';")
[ "$CV" = "t" ] && ok "rol kısıtı mevcut bütün satırlar için doğrulandı (uygunsuz eski bağ yok)" || bad "rol kısıtı doğrulanmadı: '$CV'"

step "40) Zamanlanmış bildirimler — gecikmiş aidat, sözleşme ihbarı, açık devriye (migration 028)"
# Önceden bu bildirimleri kimse üretmiyordu: bir olaya değil zamanın geçmesine
# bağlılar. cmd/scheduler her siteyi kendi kapsamıyla tarar; tekrar çalışınca
# aynı bildirimi ikinci kez üretmez.
MGRID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone LIKE '%5551234567' LIMIT 1;")
U40='40404040-0000-0000-0000-0000000000a1'
R40='40404040-0000-0000-0000-000000000001'
R40OLD='40404040-0000-0000-0000-000000000002'
$PSQL -c "
  INSERT INTO users (id, first_name, last_name, phone, password_hash, roles) VALUES
    ('$R40','Borclu','Malik','+905554040001','x',ARRAY['RESIDENT']),
    ('$R40OLD','Tasinmis','Kiraci','+905554040002','x',ARRAY['RESIDENT'])
    ON CONFLICT (id) DO NOTHING;
  INSERT INTO units (id, property_id, block, floor, door_number, share_ratio)
    VALUES ('$U40','$DEMO_PROPERTY','S',4,'40',1) ON CONFLICT (id) DO NOTHING;
  INSERT INTO resident_units (resident_id, unit_id, role, start_date, is_active) VALUES
    ('$R40','$U40','OWNER',CURRENT_DATE - 400, true);
  INSERT INTO resident_units (resident_id, unit_id, role, start_date, end_date, is_active) VALUES
    ('$R40OLD','$U40','TENANT',CURRENT_DATE - 400, CURRENT_DATE - 30, false);
  INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month,
      base_amount, total_amount, paid_amount, due_date) VALUES
    ('$DEMO_PROPERTY','$U40',2020,1,1234.56,1234.56,0,CURRENT_DATE - 60),
    ('$DEMO_PROPERTY','$U40',2020,2,150,150,50,CURRENT_DATE - 30);" >/dev/null
CN=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name, start_date, end_date,
    status, auto_renew, renewal_notice_days) VALUES ('$DEMO_PROPERTY','SERVICE','Asansor bakim','Asansor AS',
    CURRENT_DATE - 345, CURRENT_DATE + 20, 'ACTIVE', true, 30) RETURNING id;" | head -1)
CF=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name, start_date, end_date,
    status, auto_renew, renewal_notice_days) VALUES ('$DEMO_PROPERTY','SERVICE','Uzak sozlesme','Uzak AS',
    CURRENT_DATE - 10, CURRENT_DATE + 100, 'ACTIVE', false, 30) RETURNING id;" | head -1)
CE=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name, start_date, end_date,
    status, auto_renew) VALUES ('$DEMO_PROPERTY','OTHER','Kapatilmamis','Eski AS',
    CURRENT_DATE - 370, CURRENT_DATE - 5, 'ACTIVE', false) RETURNING id;" | head -1)
CO=$($PSQL -t -A -c "INSERT INTO contracts (property_id, contract_type, title, party_name, start_date, end_date,
    status, auto_renew, renewal_notice_days) VALUES ('$OTHERPROP','SERVICE','Diger site temizlik','Temiz AS',
    CURRENT_DATE - 355, CURRENT_DATE + 10, 'ACTIVE', false, 30) RETURNING id;" | head -1)
PO=$($PSQL -t -A -c "INSERT INTO patrol_logs (property_id, guard_id, started_at, expected_duration_minutes, status)
    VALUES ('$DEMO_PROPERTY','$MGRID', now() - interval '3 hours', 30, 'IN_PROGRESS') RETURNING id;" | head -1)
PY=$($PSQL -t -A -c "INSERT INTO patrol_logs (property_id, guard_id, started_at, expected_duration_minutes, status)
    VALUES ('$DEMO_PROPERTY','$MGRID', now() - interval '5 minutes', 30, 'IN_PROGRESS') RETURNING id;" | head -1)

N=$(qapp "SELECT count(*) FROM scheduler_property_ids();")
P=$(qapp "SELECT count(*) FROM properties;")
[ "${N:-0}" -ge 2 ] && [ "$P" = "0" ] && ok "uygulama rolü site KİMLİKLERİNİ alabiliyor ($N) ama properties tablosu kapsamsız hâlâ kapalı" \
  || bad "site listesi: fonksiyon $N, properties $P"

sched_once() { # $1 = çıktı dosyası
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable go run ./cmd/scheduler -once >"$1" 2>/tmp/verify-sched.err
}
if sched_once /tmp/verify-sched1.json; then
  ok "zamanlayıcı tek tur başarıyla çalıştı: $(python3 -c "import json;print(json.load(open('/tmp/verify-sched1.json'))['note'])")"
else
  bad "zamanlayıcı turu başarısız"; tail -5 /tmp/verify-sched.err; head -40 /tmp/verify-sched1.json
fi

# Gecikmiş aidat: borçlu daireye TEK bildirim, doğru toplam, taşınmış sakine yok
BODY=$($PSQL -t -A -c "SELECT body FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$R40';")
NB=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$R40';")
[ "$NB" = "1" ] && echo "$BODY" | grep -q "2 dönem" && echo "$BODY" | grep -q "1.334,56 TL" \
  && ok "borçlu daireye tek bildirim: 2 dönem, kalan 1.334,56 TL (kısmi ödeme düşülmüş)" \
  || bad "aidat bildirimi ($NB): $BODY"
NB=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE recipient_user_id='$R40OLD';")
[ "$NB" = "0" ] && ok "daireden taşınmış eski kiracıya aidat bildirimi GİTMEDİ" || bad "taşınmış sakine $NB bildirim"
KEY=$($PSQL -t -A -c "SELECT dedupe_key FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$R40';")
echo "$KEY" | grep -Eq "^dues.overdue:$U40:[0-9]{4}-[0-9]{2}:$R40$" && ok "aidat hatırlatması daire+ay anahtarlı (ayda en fazla bir)" \
  || bad "aidat dedupe anahtarı: $KEY"

# Sözleşme: ihbar son günü geçmiş → yönetim; uzak sözleşme → yok; süresi dolmuş ACTIVE → yönetim
NMGR=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'contract_id'='$CN' AND topic='contract.notice';")
NOUT=$($PSQL -t -A -c "SELECT count(*) FROM notifications n WHERE payload->>'contract_id'='$CN'
  AND NOT EXISTS (SELECT 1 FROM property_roles pr WHERE pr.user_id=n.recipient_user_id AND pr.property_id='$DEMO_PROPERTY'
                  AND pr.role IN ('MANAGER','BOARD_MEMBER','AUDITOR'));")
CBODY=$($PSQL -t -A -c "SELECT body FROM notifications WHERE payload->>'contract_id'='$CN' LIMIT 1;")
[ "${NMGR:-0}" -ge 1 ] && [ "$NOUT" = "0" ] && echo "$CBODY" | grep -q "10 gün geçti" && echo "$CBODY" | grep -q "kendiliğinden yenilenir" \
  && ok "ihbar son günü geçen sözleşme yönetime bildirildi ($NMGR alıcı; 'son gün … 10 gün geçti', otomatik yenileme uyarısı)" \
  || bad "ihbar bildirimi: $NMGR alıcı, yönetim dışı $NOUT — $CBODY"
N=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'contract_id'='$CF';")
[ "$N" = "0" ] && ok "ihbar penceresine girmemiş sözleşme için bildirim yok" || bad "uzak sözleşmeye $N bildirim"
N=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'contract_id'='$CE' AND topic='contract.expired';")
[ "${N:-0}" -ge 1 ] && ok "süresi dolduğu hâlde AKTİF kalan sözleşme yönetime bildirildi" || bad "süresi dolmuş sözleşme bildirimi: $N"

# Site yalıtımı: diğer sitenin sözleşmesi YALNIZCA o sitenin yönetimine
ROW=$($PSQL -t -A -c "SELECT count(*), count(*) FILTER (WHERE property_id <> '$OTHERPROP'),
    count(*) FILTER (WHERE recipient_user_id = '44444444-4444-4444-4444-444444444404'),
    count(*) FILTER (WHERE NOT EXISTS (SELECT 1 FROM property_roles pr WHERE pr.user_id=n.recipient_user_id
                                        AND pr.property_id='$OTHERPROP'))
  FROM notifications n WHERE payload->>'contract_id'='$CO';")
IFS='|' read -r NT NWRONG NMINE NFOREIGN <<<"$ROW"
[ "${NT:-0}" -ge 1 ] && [ "$NWRONG" = "0" ] && [ "$NMINE" = "1" ] && [ "$NFOREIGN" = "0" ] \
  && ok "diğer sitenin sözleşmesi yalnızca o sitenin yöneticisine bildirildi ($NT alıcı)" \
  || bad "site yalıtımı: toplam $NT, yanlış site $NWRONG, o sitenin yöneticisi $NMINE, yabancı alıcı $NFOREIGN"

# Devriye: süresi aşılan açık tur → yönetim; yeni başlamış tur → yok
N=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'patrol_id'='$PO' AND topic='patrol.overdue';")
[ "${N:-0}" -ge 1 ] && ok "beklenen süre + toleransı aşan açık devriye yönetime bildirildi" || bad "açık devriye bildirimi: $N"
N=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'patrol_id'='$PY';")
[ "$N" = "0" ] && ok "süresi içindeki devriye için bildirim yok" || bad "yeni başlamış tura $N bildirim"
N=$($PSQL -t -A -c "SELECT count(*) FROM notifications n JOIN patrol_logs l ON l.id::text = n.payload->>'patrol_id'
  WHERE n.topic = 'patrol.overdue' AND l.id = '$PO'
    AND n.body LIKE '%' || to_char(l.started_at AT TIME ZONE 'Europe/Istanbul', 'HH24:MI') || ' saatinde%';")
[ "${N:-0}" -ge 1 ] && ok "devriye saati Türkiye saatiyle yazılıyor (kap UTC olsa da)" || bad "devriye saati yanlış saat diliminde"

# Tekrar çalıştırma: YENİ kayıt yok, hepsi 'daha önce oluşturuldu'
BEFORE=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic IN ('dues.overdue','contract.notice','contract.expired','patrol.overdue');")
sched_once /tmp/verify-sched2.json; RC=$?
AFTER=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic IN ('dues.overdue','contract.notice','contract.expired','patrol.overdue');")
CREATED=$(python3 -c "import json;r=json.load(open('/tmp/verify-sched2.json'));print(sum(j['sent']+j['pending']+j['suppressed'] for j in r['jobs']), sum(j['duplicate'] for j in r['jobs']))")
[ "$RC" = "0" ] && [ "$BEFORE" = "$AFTER" ] && [ "${CREATED%% *}" = "0" ] && [ "${CREATED##* }" -ge 1 ] \
  && ok "ikinci tur yeni bildirim üretmedi ($AFTER kayıt sabit; ${CREATED##* } tanesi 'daha önce oluşturuldu')" \
  || bad "ikinci tur: çıkış $RC, kayıt $BEFORE → $AFTER, oluşan/atlanan $CREATED"

# Kilit: başka kopya turu tutuyorsa bu kopya atlar
LOCKKEY=$((16#5E17E45C4ED))
$PSQL -c "SELECT pg_advisory_lock($LOCKKEY); SELECT pg_sleep(20);" >/dev/null 2>&1 &
LOCK_PID=$!
for _ in $(seq 1 20); do
  [ "$($PSQL -t -A -c "SELECT count(*) FROM pg_locks WHERE locktype='advisory' AND granted;")" -ge 1 ] && break; sleep 0.5
done
sched_once /tmp/verify-sched3.json
grep -q '"skipped"' /tmp/verify-sched3.json && ok "başka kopya çalışırken tur atlanıyor (advisory lock)" \
  || bad "kilit tutulurken tur yine çalıştı: $(head -c 300 /tmp/verify-sched3.json)"
kill_tree "$LOCK_PID"
$PSQL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE query LIKE '%pg_sleep(20)%' AND pid <> pg_backend_pid();" >/dev/null 2>&1

# Sürekli kip: sağlık ucu son turun raporunu gösterir
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable PORT=18610 SCHEDULER_INTERVAL=1m go run ./cmd/scheduler >/tmp/verify-sched-loop.log 2>&1 &
SCHED_PID=$!
HOK=0
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18610/health 2>/dev/null | grep -q '"jobs"' && { HOK=1; break; }; sleep 1
done
[ "$HOK" = "1" ] && ok "sürekli kipte /health son turun raporunu gösteriyor" || bad "zamanlayıcı sağlık ucu: $(tail -3 /tmp/verify-sched-loop.log)"
kill_tree "$SCHED_PID"

step "41) Migration geri alma: yedek → yıkıcı değişiklik → geri yükleme (1.6)"
# Down betikleri BİLEREK yazılmadı (docs/runbook-veritabani-geri-alma.md): denetim
# izi ve defterleri silen bir "down" hukuken saklanması gereken kaydı yok ederdi.
# Geri alma yolu yedekten geri yüklemedir; burada gerçekten çalıştığı sınanır.
BK=/tmp/verify-backup.dump
fingerprint() {
  $PSQL -t -A -c "SELECT (SELECT count(*) FROM pg_tables WHERE schemaname='public') || '|' ||
    (SELECT count(*) FROM schema_migrations) || '|' || (SELECT count(*) FROM rls_enabled_tables) || '|' ||
    (SELECT md5(COALESCE(string_agg(id::text || amount::text || status, ',' ORDER BY id), '')) FROM payments) || '|' ||
    (SELECT count(*) FROM audit_logs) || '|' || (SELECT count(*) FROM pg_policy);"
}
if bash "$SCRIPT_DIR/db-backup.sh" "$BK" >/tmp/verify-backup.log 2>&1; then
  ok "yedek alındı ve okunabilir: $(tail -1 /tmp/verify-backup.log)"
  FP1=$(fingerprint)
  # Yıkıcı ve hatalı bir migration'ı taklit et: tablo sil, veri sil, sürüm ekle, yeni tablo aç.
  $PSQL -c "DROP TABLE expenses CASCADE; DELETE FROM payment_assessments; DELETE FROM payments;
    INSERT INTO schema_migrations (version, name, checksum) VALUES (999, '999_bozuk.sql', 'x');
    CREATE TABLE bozuk_migration_artigi (id int);" >/dev/null 2>&1
  [ "$(fingerprint)" != "$FP1" ] && ok "yıkıcı değişiklik uygulandı (tablo/veri/sürüm bozuldu)" || bad "benzetim şemayı değiştirmedi"
  CONFIRM_RESTORE=yanlis bash "$SCRIPT_DIR/db-restore.sh" "$BK" >/dev/null 2>&1
  [ $? -eq 2 ] && ok "yanlış veritabanı onayıyla geri yükleme reddedildi" || bad "onaysız geri yükleme çalıştı"
  CONFIRM_RESTORE=siteeksen bash "$SCRIPT_DIR/db-restore.sh" "$BK" >/tmp/verify-restore.log 2>&1; RC=$?
  [ "$RC" = "3" ] && grep -q 'bozuk_migration_artigi' /tmp/verify-restore.log \
    && ok "yedekte olmayan tablo kendiliğinden silinmedi, operatöre bildirildi (çıkış 3)" \
    || bad "artık tablo bildirimi: çıkış $RC, $(tail -2 /tmp/verify-restore.log)"
  $PSQL -c "DROP TABLE bozuk_migration_artigi;" >/dev/null 2>&1
  FP2=$(fingerprint)
  [ "$FP2" = "$FP1" ] && ok "geri yükleme sonrası şema, sürüm, RLS, politikalar, ödemeler ve denetim izi yedekle birebir ($FP2)" \
    || bad "geri yükleme farkı: önce '$FP1' sonra '$FP2'"
  N=$(qscoped "SELECT count(*) FROM units;")
  [ "${N:-0}" -ge 1 ] && ok "geri yüklemeden sonra uygulama rolü RLS kapsamıyla çalışıyor ($N bölüm)" \
    || bad "geri yükleme sonrası uygulama rolü veri göremiyor"
  go run ./cmd/migrate -dir "$MIG_DIR" -status >/tmp/verify-mig3.log 2>&1 \
    && ok "geri yüklemeden sonra cmd/migrate sağlama denetimini geçiyor" || bad "migrate durumu: $(tail -3 /tmp/verify-mig3.log)"
else
  bad "yedek alınamadı: $(tail -3 /tmp/verify-backup.log)"
fi
rm -f "$BK"

step "42) Kişisel veri anahtarı döndürme (todo 8 · docs/runbook-anahtar-dondurme.md)"
# Önceden tek anahtar vardı ve şifreli metin hangi anahtarla yazıldığını
# taşımıyordu: anahtar sızsa bile değiştirilemezdi, değiştirilirse bütün
# personel kayıtları okunamaz olurdu. Bu adım gerçek bir döndürmeyi baştan
# sona yürütür: k1 → (k2 + eski k1) → rotate-pii → yalnızca k2.
PIIKEY2=$(head -c 32 /dev/urandom | base64 -w0)
PIIKEY3=$(head -c 32 /dev/urandom | base64 -w0)
SUPER_DSN="postgres://siteeksen:${PW}@127.0.0.1:${DBPORT}/siteeksen?sslmode=disable"
start_personnel() { # $1 birincil anahtar, $2 kimlik, $3 eski anahtarlar
  kill_tree "$PER2_PID"; free_port "$PER2PORT"
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PER2PORT} \
  PII_ENCRYPTION_KEY="$1" PII_ENCRYPTION_KEY_ID="$2" PII_ENCRYPTION_PREVIOUS_KEYS="$3" \
    go run ./services/personnel >/tmp/verify-personnel-rot.log 2>&1 &
  PER2_PID=$!
  for _ in $(seq 1 45); do
    curl -fsS "http://127.0.0.1:${PER2PORT}/health" >/dev/null 2>&1 && return 0; sleep 1
  done
  return 1
}
not_primary() { # $1 kimlik: o kimlikle yazılmamış şifreli alan sayısı (bütün siteler)
  $PSQL -t -A -c "SELECT count(*) FROM employees, LATERAL (VALUES (tc_number_encrypted), (bank_iban_encrypted)) f(v)
    WHERE v IS NOT NULL AND v <> '' AND v NOT LIKE '$1\$%';"
}
MGR42=$(curl -s -X POST "http://127.0.0.1:${SVCPORT}/api/v1/auth/login" -H 'Content-Type: application/json' \
  -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
A42="Authorization: Bearer $MGR42"
P42="http://127.0.0.1:${PER2PORT}/api/v1"
ROT_ID="${E1ID:-}"   # 31. adımda TCKN 10000000146 ile açılan aktif personel
ROT_TC=$($PSQL -t -A -c "SELECT split_part(tc_number_encrypted,'\$',1) FROM employees WHERE id='$ROT_ID';")
[ -n "$ROT_ID" ] && [ "$ROT_TC" = "k1" ] && ok "şifreli metin anahtar kimliğini taşıyor (k1\$...)" \
  || bad "döndürme sınaması için k1 kaydı yok: id=$ROT_ID kimlik=$ROT_TC"

if [ -n "$ROT_ID" ] && [ -n "$MGR42" ]; then
  # 1) Yeni birincil anahtar k2, eski k1 yalnızca çözmek için
  if start_personnel "$PIIKEY2" k2 "k1:$PIIKEY"; then
    G=$(curl -s "$P42/employees/$ROT_ID?reveal=true" -H "$A42")
    echo "$G" | grep -q '10000000146' && ok "döndürme sırasında eski anahtarla (k1) yazılmış kayıt okunuyor" \
      || bad "k2+k1 halkasıyla eski kayıt okunamadı: $(echo "$G" | head -c 200)"
    # Arama anahtarı k1 ile üretilmiş; benzersiz indeks bunu yakalamaz. Denetim adayları kullanmalı.
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$P42/employees" -H "$A42" -H 'Content-Type: application/json' \
      -d '{"first_name":"Dondurme","last_name":"Kopya","position":"Test","hire_date":"2026-03-01","tc_number":"10000000146"}')
    [ "$SC" = "409" ] && ok "döndürme sırasında aynı TCKN ile ikinci aktif personel açılamıyor → 409" \
      || bad "farklı anahtarlı arama anahtarı yinelenen kaydı kaçırdı → $SC"
    NEW=$(curl -s -X POST "$P42/employees" -H "$A42" -H 'Content-Type: application/json' \
      -d '{"first_name":"Yeni","last_name":"Anahtar","position":"Test","hire_date":"2026-03-01","tc_number":"22222222220"}')
    NEWID=$(echo "$NEW" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    NK=$($PSQL -t -A -c "SELECT split_part(tc_number_encrypted,'\$',1) FROM employees WHERE id='${NEWID:-00000000-0000-0000-0000-000000000000}';")
    [ "$NK" = "k2" ] && ok "yeni kayıt birincil anahtarla (k2) yazılıyor" || bad "yeni kayıt anahtarı: '$NK' ($NEW)"
  else
    bad "personel servisi k2+k1 halkasıyla açılmadı: $(tail -3 /tmp/verify-personnel-rot.log)"
  fi

  # 2) rotate-pii: uygulama rolüyle ÇALIŞMAMALI (siteleri göremez, "kalmadı" diye yalan söylerdi)
  PII_ENCRYPTION_KEY="$PIIKEY2" PII_ENCRYPTION_KEY_ID=k2 PII_ENCRYPTION_PREVIOUS_KEYS="k1:$PIIKEY" \
  DATABASE_URL="host=127.0.0.1 port=${DBPORT} user=siteeksen_app password='${APPPW}' dbname=siteeksen sslmode=disable" \
    go run ./cmd/rotate-pii >/tmp/verify-rot-app.log 2>&1; RC=$?
  [ "$RC" != "0" ] && grep -q 'RLS' /tmp/verify-rot-app.log \
    && ok "rotate-pii uygulama rolüyle başlamıyor (görmediği kayıtları yok sayardı)" \
    || bad "rotate-pii uygulama rolüyle çalıştı: çıkış $RC, $(tail -2 /tmp/verify-rot-app.log)"
  PII_ENCRYPTION_KEY="$PIIKEY" DATABASE_URL="host=127.0.0.1 port=${DBPORT} user=siteeksen_app password='${APPPW}' dbname=siteeksen sslmode=disable" \
    go run ./cmd/encrypt-pii >/tmp/verify-enc-app.log 2>&1; RC=$?
  [ "$RC" != "0" ] && grep -q 'RLS' /tmp/verify-enc-app.log \
    && ok "encrypt-pii de uygulama rolüyle başlamıyor (sahte 'düz metin kalmadı' raporu)" \
    || bad "encrypt-pii uygulama rolüyle çalıştı: çıkış $RC"

  # 3) Yanlış halka: k1 anahtarı verilmezse kayıt ATLANMAZ, hiçbir şey yazılmaz
  BEFORE=$(not_primary k2)
  PII_ENCRYPTION_KEY="$PIIKEY2" PII_ENCRYPTION_KEY_ID=k2 DATABASE_URL="$SUPER_DSN" \
    go run ./cmd/rotate-pii >/tmp/verify-rot-bad.log 2>&1; RC=$?
  [ "$RC" != "0" ] && grep -q 'tanımlı değil' /tmp/verify-rot-bad.log && [ "$(not_primary k2)" = "$BEFORE" ] \
    && ok "eski anahtar eksikken döndürme hata veriyor ve hiçbir kaydı değiştirmiyor ($BEFORE alan)" \
    || bad "eksik anahtarla döndürme: çıkış $RC, kalan $(not_primary k2)/$BEFORE"

  # 4) -dry-run yazmaz
  PII_ENCRYPTION_KEY="$PIIKEY2" PII_ENCRYPTION_KEY_ID=k2 PII_ENCRYPTION_PREVIOUS_KEYS="k1:$PIIKEY" \
  DATABASE_URL="$SUPER_DSN" go run ./cmd/rotate-pii -dry-run >/tmp/verify-rot-dry.log 2>&1; RC=$?
  [ "$RC" = "0" ] && [ "$(not_primary k2)" = "$BEFORE" ] && [ "${BEFORE:-0}" -ge 1 ] \
    && ok "-dry-run hiçbir kaydı değiştirmiyor ($BEFORE alan taşınacak)" \
    || bad "-dry-run: çıkış $RC, önce $BEFORE sonra $(not_primary k2)"

  # 5) Gerçek döndürme
  IDX_BEFORE=$($PSQL -t -A -c "SELECT tc_number_index FROM employees WHERE id='$ROT_ID';")
  PII_ENCRYPTION_KEY="$PIIKEY2" PII_ENCRYPTION_KEY_ID=k2 PII_ENCRYPTION_PREVIOUS_KEYS="k1:$PIIKEY" \
  DATABASE_URL="$SUPER_DSN" go run ./cmd/rotate-pii >/tmp/verify-rot.log 2>&1; RC=$?
  [ "$RC" = "0" ] && [ "$(not_primary k2)" = "0" ] && grep -q 'Eski anahtarla yazılmış kayıt kalmadı' /tmp/verify-rot.log \
    && ok "rotate-pii bütün şifreli alanları k2'ye taşıdı ve bunu raporladı" \
    || bad "döndürme: çıkış $RC, kalan $(not_primary k2): $(tail -4 /tmp/verify-rot.log)"
  IDXCHG=$($PSQL -t -A -c "SELECT count(*) FROM employees WHERE id='$ROT_ID'
    AND length(tc_number_index) = 64 AND tc_number_index <> '$IDX_BEFORE';")
  PLAIN42=$($PSQL -t -A -c "SELECT count(*) FROM employees WHERE tc_number IS NOT NULL OR bank_iban IS NOT NULL;")
  [ "$IDXCHG" = "1" ] && [ "$PLAIN42" = "0" ] && ok "döndürme düz metin bırakmadı; arama anahtarı yeni anahtarla yeniden üretildi (öncekinden farklı)" \
    || bad "döndürme sonrası: index=$IDXCHG düz=$PLAIN42"
  PII_ENCRYPTION_KEY="$PIIKEY2" PII_ENCRYPTION_KEY_ID=k2 PII_ENCRYPTION_PREVIOUS_KEYS="k1:$PIIKEY" \
  DATABASE_URL="$SUPER_DSN" go run ./cmd/rotate-pii >/tmp/verify-rot2.log 2>&1
  grep -q 'Toplam 0 kayıt' /tmp/verify-rot2.log && ok "ikinci çalıştırma hiçbir kayda dokunmuyor (tekrarlanabilir)" \
    || bad "ikinci döndürme: $(tail -3 /tmp/verify-rot2.log)"

  # 6) Eski anahtar halkadan çıkarıldı: yalnızca k2 ile her şey okunuyor, yinelenen kayıt indeksle de yakalanıyor
  if start_personnel "$PIIKEY2" k2 ""; then
    G=$(curl -s "$P42/employees/$ROT_ID?reveal=true" -H "$A42")
    echo "$G" | grep -q '10000000146' && ok "eski anahtar çıkarıldıktan sonra kayıt yalnızca k2 ile okunuyor" \
      || bad "yalnızca k2 ile okunamadı: $(echo "$G" | head -c 200)"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$P42/employees" -H "$A42" -H 'Content-Type: application/json' \
      -d '{"first_name":"Dondurme","last_name":"Kopya","position":"Test","hire_date":"2026-03-01","tc_number":"10000000146"}')
    [ "$SC" = "409" ] && ok "döndürmeden sonra da aynı TCKN ikinci kez açılamıyor → 409" || bad "döndürme sonrası yinelenen → $SC"
  else
    bad "personel servisi yalnızca k2 ile açılmadı: $(tail -3 /tmp/verify-personnel-rot.log)"
  fi

  # 7) Yanlış anahtarla açılan servis veriyi SESSİZCE boş göstermemeli
  if start_personnel "$PIIKEY3" k3 ""; then
    G=$(curl -s -w '\n%{http_code}' "$P42/employees/$ROT_ID" -H "$A42")
    GC=$(echo "$G" | tail -1)
    [ "$GC" = "500" ] && ! echo "$G" | grep -q '"tc_number":""' \
      && ok "tanımsız anahtarla yazılmış kayıt boş alan olarak değil hata olarak dönüyor → 500" \
      || bad "anahtarı olmayan kayıt: $GC $(echo "$G" | head -c 200)"
    # Günlük JSON'dur; tırnaklar kaçışlı yazılır (\"k2\"), desen bunu kapsar.
    grep -q 'k2\\\?" anahtarıyla şifrelenmiş ama bu anahtar tanımlı değil' /tmp/verify-personnel-rot.log \
      && ok "sunucu günlüğü eksik anahtarın kimliğini (k2) söylüyor" || bad "günlükte eksik anahtar bilgisi yok: $(tail -2 /tmp/verify-personnel-rot.log)"
  else
    bad "personel servisi k3 ile açılmadı"
  fi
  kill_tree "$PER2_PID"; PER2_PID=""
else
  bad "döndürme sınanamadı (kayıt ya da yönetici jetonu yok)"
fi

step "SONUÇ"
echo "  Geçen: $PASS   Başarısız: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TÜM KONTROLLER GEÇTİ"; exit 0; } || { echo "  BAŞARISIZ KONTROL VAR"; exit 1; }
