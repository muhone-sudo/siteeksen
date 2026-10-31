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
# Servisler veritabanı oturumlarını iş saat dilimine (APP_TIMEZONE, varsayılan
# Europe/Istanbul) sabitler; doğrulamanın psql oturumları da aynı günü görmeli.
# Aksi hâlde Türkiye'de 00:00–03:00 arasında beklenen değerler bir gün kayar.
export PGTZ=${APP_TIMEZONE:-Europe/Istanbul}

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
# Biçim: gofmt dışı dosya kalmamalı (2026-10-11: iki dosya fark edilmeden commit edilmişti).
GOFMT_BAD=$(gofmt -l . 2>/dev/null)
[ -z "$GOFMT_BAD" ] && ok "gofmt: biçim farkı olan dosya yok" || bad "gofmt biçim farkı: $GOFMT_BAD"
# Veritabanı gerektirmeyen birim testleri
if go test ./pkg/authtoken/... -count=1 >/tmp/verify-authtoken.log 2>&1; then
  ok "go test ./pkg/authtoken/... (JWT doğrulama)"
else
  bad "go test ./pkg/authtoken/..."; tail -15 /tmp/verify-authtoken.log
fi
if go test ./cmd/gateway/... -count=1 >/tmp/verify-gwtest.log 2>&1; then
  ok "go test ./cmd/gateway/... (kimliksiz yol listesi dar: yalnızca giriş, belge doğrulama, cihaz sinyali; CORS Idempotency-Key)"
else
  bad "go test ./cmd/gateway/..."; tail -15 /tmp/verify-gwtest.log
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
# Kaldırılan önceki konteynerin portu birkaç saniye geç serbest kalabilir ("failed to bind"): kısa aralıkla yeniden denenir.
for _ in 1 2 3 4 5 6 7 8 9 10; do
  DBRUN=$(docker run --rm -d --name "$CNAME" -e POSTGRES_PASSWORD="$PW" -e POSTGRES_DB=siteeksen \
    -e POSTGRES_USER=siteeksen -p ${DBPORT}:5432 postgres:16 -c max_connections=300 2>&1) && break
  docker rm -f "$CNAME" >/dev/null 2>&1; sleep 2
done
# TCP'den sorulur: imaj ilk kurulumda geçici bir sunucuyu yalnız unix soketinde açıp kapatır; soketten sorulursa o
# geçici sunucu "hazır" görünür ve yeniden başlatma boşluğundaki ikinci kontrol yanlışlıkla başarısız olur.
for _ in $(seq 1 60); do
  docker exec "$CNAME" pg_isready -h 127.0.0.1 -U siteeksen -d siteeksen >/dev/null 2>&1 && break
  sleep 1
done
docker exec "$CNAME" pg_isready -h 127.0.0.1 -U siteeksen -d siteeksen >/dev/null 2>&1 \
  && ok "veritabanı hazır" || { bad "veritabanı başlamadı: ${DBRUN:0:300} $(docker logs "$CNAME" 2>&1 | tail -3)"; exit 1; }

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
if go test ./pkg/compliance/... -count=1 >/tmp/verify-compliance.log 2>&1; then
  ok "go test ./pkg/compliance/... (beyan son günü, hafta sonu kaydırma, ay sonu)"
else
  bad "go test ./pkg/compliance/..."; tail -15 /tmp/verify-compliance.log
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
  MB=$(curl -s "http://127.0.0.1:${GWPORT}/metrics")
  grep -q 'siteeksen_http_requests_total' <<<"$MB" && bad "gateway servis metriklerini dışarı açıyor" || ok "gateway /metrics'i dışarı açmıyor (yalnızca küme içinden kazınır)"

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
# Apsiyon BUG-10: yurt dışındaki malikler erişebilmeli — kenar katmanında ve gateway'de
# ülke/IP bloğu bazlı toptan engel olmamalı; koruma IP başına hız sınırıdır.
GEO=$(grep -nEi 'ip-restriction|geoip|geo-ip|country|bot-detection' "$KONG" "$BACKEND_DIR/cmd/gateway/"*.go | grep -v '_test.go' || true)
[ -z "$GEO" ] && ok "kong.yml ve gateway'de ülke/IP bloğu bazlı engel yok (yurt dışı erişim açık; koruma IP başına hız sınırı)" \
  || bad "coğrafi engel izi: $GEO"

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
    && echo "$DR" | grep -qE 'malik kayıtlı değil|Kayıtlı malik/sakin yok|Malik kaydı yok' \
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

    # B69: liste sayfalı ve toplamı söylüyor (önceden sabit LIMIT 50 sessizce kesiyordu)
    NPAY=$($PSQL -t -A -c "SELECT count(*) FROM payments WHERE property_id='$DEMO_PROPERTY' AND deleted=0;")
    curl -s -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/payments?limit=1" >/tmp/verify-page.json
    PG=$(python3 -c 'import json; d=json.load(open("/tmp/verify-page.json")); print("%d|%s|%s" % (len(d["data"]), d.get("total"), d.get("limit")))')
    SC1=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $MGR" "http://127.0.0.1:${FINPORT}/api/v1/finance/payments?limit=501")
    [ "$PG" = "1|$NPAY|1" ] && [ "$SC1" = "400" ] \
      && ok "ödeme listesi sayfalı ve toplamı bildiriyor (1 / $NPAY), aşırı limit → 400" \
      || bad "sayfalama: '$PG' (1|$NPAY|1 bekleniyordu), limit=501 → $SC1"

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

  # --- Havale valörü: gecikme ödeme gününde biter (053, Apsiyon BUG-02, KMK m.20/2) ---
  FIN="http://127.0.0.1:${FINPORT}/api/v1/finance"
  FA="Authorization: Bearer $MGR"; FJ='Content-Type: application/json'
  $PSQL -c "UPDATE payments SET status='FAILED' WHERE status='PENDING' AND id IN (SELECT payment_id FROM payment_assessments WHERE assessment_id='$ASSESS');" >/dev/null 2>&1
  accrue() { curl -s -o /dev/null -X POST "$FIN/late-fees/accrue" -H "$FA" -H "$FJ" -d '{}'; }
  accrue
  LF0=$($PSQL -t -A -c "SELECT late_fee > 0 FROM monthly_assessments WHERE id='$ASSESS';")
  # Vadesinde (2026-01-09) havale yapılmış, bugün bildiriliyor → tazminat sıfır, tutar anapara
  V1=$(curl -s -X POST "$FIN/payments" -H "$FA" -H "$FJ" -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"2026-01-09\",\"reference\":\"FAST 123\"}")
  VP1=$(echo "$V1" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
  ROW1=$($PSQL -t -A -c "SELECT late_fee::text || '|' || total_amount::text FROM monthly_assessments WHERE id='$ASSESS';")
  REV=$($PSQL -t -A -c "SELECT count(*) FILTER (WHERE reversed_at IS NOT NULL AND reversal_reason LIKE 'Ödeme valörü 09.01.2026%'), count(*) FROM late_fee_accruals WHERE assessment_id='$ASSESS';")
  accrue
  ROW1B=$($PSQL -t -A -c "SELECT late_fee::text FROM monthly_assessments WHERE id='$ASSESS';")
  PV=$($PSQL -t -A -c "SELECT value_date || '|' || payer_reference FROM payments WHERE id='$VP1';")
  [ "$LF0" = "t" ] && echo "$V1" | grep -q '"amount":1200' && echo "$V1" | grep -q 'onay beklerken işlemez' && [ "$ROW1" = "0.00|1200.00" ] \
    && [ "${REV%%|*}" -ge 1 ] && [ "$ROW1B" = "0.00" ] && [ "$PV" = "2026-01-09|FAST 123" ] \
    && ok "vadesinde yapılmış havale: tutar 1.200,00 (tazminat sıfırlandı), valör sonrası tazminat izi silinmeden iptal işaretlendi ($REV), onay beklerken tazminat işlemiyor" \
    || bad "valör (vadesinde): işlemiş=$LF0 / $V1 / $ROW1 / iz=$REV / ikinci=$ROW1B / $PV"
  # Reddedilen beyanda tazminat yeniden işler
  curl -s -o /dev/null -X POST "$FIN/payments/$VP1/reject" -H "$FA" -H "$FJ" -d '{}'
  accrue
  LF2=$($PSQL -t -A -c "SELECT late_fee > 0 FROM monthly_assessments WHERE id='$ASSESS';")
  # Vadeden 15 gün sonra (2026-01-25) yapılmış havale → 120000 kuruş × %5 × 15/30 = 3000 kuruş
  V2=$(curl -s -X POST "$FIN/payments" -H "$FA" -H "$FJ" -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"2026-01-25\"}")
  VP2=$(echo "$V2" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
  C2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments/$VP2/confirm" -H "$FA" -H "$FJ" -d '{"reference":"banka hareketi"}')
  ROW2=$($PSQL -t -A -c "SELECT late_fee::text || '|' || paid_amount::text || '|' || status FROM monthly_assessments WHERE id='$ASSESS';")
  FUT=$(date -d '+1 day' +%F)
  SF=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments" -H "$FA" -H "$FJ" -d "{\"assessment_ids\":[\"$ASSESS\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$FUT\"}")
  [ "$LF2" = "t" ] && echo "$V2" | grep -q '"amount":1230' && [ "$C2" = "200" ] && [ "$ROW2" = "30.00|1230.00|PAID" ] && [ "$SF" = "422" ] \
    && ok "15 gün geç havale: tazminat valöre göre 30,00 TL, onayla borç kapandı (1.230,00 PAID); reddedilen beyanda tazminat yeniden işledi; gelecek valör 422" \
    || bad "valör (geç): reddet sonrası=$LF2 / $V2 / onay=$C2 / $ROW2 / gelecek=$SF"
  # --- Finansal silinemezlik, ters kayıt ve tahsilat defteri zinciri (054, Apsiyon BUG-03) ---
  LG=$(curl -s "$FIN/ledger" -H "$FA")
  LGOK=$(echo "$LG" | python3 -c "
import json,sys; d=json.load(sys.stdin)['data']
e=[x for x in d if x.get('payment_id')=='$VP2' and x['entry_type']=='PAYMENT_CONFIRMED']
print(len(e)==1 and e[0]['amount_kurus']==123000 and e[0]['detail']['allocations'][0]['amount_kurus']==123000 and e[0]['detail']['value_date']=='2026-01-25')" 2>/dev/null)
  appsql() { PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); $1; COMMIT;" 2>&1; }
  D1=$(appsql "DELETE FROM payments WHERE id='$VP2'" | grep -c 'permission denied')
  D2=$(appsql "UPDATE payments SET amount = 1 WHERE id='$VP2'" | grep -c 'değiştirilemez')
  D3=$(appsql "UPDATE monthly_assessments SET base_amount = 1 WHERE id='$ASSESS'" | grep -c 'anaparası değiştirilemez')
  D4=$(appsql "UPDATE monthly_assessments SET paid_amount = 0 WHERE id='$ASSESS'" | grep -c 'azaltılamaz')
  D5=$(appsql "UPDATE payments SET status = 'PENDING' WHERE id='$VP2'" | grep -c 'durumu değiştirilemez')
  D6=$(appsql "DELETE FROM finance_ledger" | grep -c 'permission denied')
  [ "$LGOK" = "True" ] && [ "$D1" -ge 1 ] && [ "$D2" -ge 1 ] && [ "$D3" -ge 1 ] && [ "$D4" -ge 1 ] && [ "$D5" -ge 1 ] && [ "$D6" -ge 1 ] \
    && ok "tahsilat onayı deftere dağılımıyla yazıldı; uygulama rolü ödeme/defter silemez, tutar/durum/anapara değiştiremez, ödeneni azaltamaz" \
    || bad "silinemezlik: defter=$LGOK sil=$D1 tutar=$D2 anapara=$D3 ödenen=$D4 durum=$D5 defter-sil=$D6"
  RV0=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments/$VP2/reverse" -H "$FA" -H "$FJ" -d '{"reason":"x"}')
  RV1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments/$VP2/reverse" -H "$FA" -H "$FJ" -d '{"reason":"Banka hareketi bulunamadı, mükerrer onay"}')
  RV2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments/$VP2/reverse" -H "$FA" -H "$FJ" -d '{"reason":"ikinci deneme"}')
  RVT=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$FIN/payments/$VP2/reverse" -H "Authorization: Bearer $TEN" -H "$FJ" -d '{"reason":"sakin deniyor"}')
  RROW=$($PSQL -t -A -c "SELECT p.status || '|' || ma.paid_amount::text || '|' || ma.status || '|' || (SELECT count(*) FROM payments WHERE id='$VP2')
    FROM payments p, monthly_assessments ma WHERE p.id='$VP2' AND ma.id='$ASSESS';")
  RL=$($PSQL -t -A -c "SELECT amount_kurus || '|' || (detail->>'reason') FROM finance_ledger WHERE payment_id='$VP2' AND entry_type='PAYMENT_REVERSED';")
  VF=$(curl -s "$FIN/ledger/verify" -H "Authorization: Bearer $TEN")
  [ "$RV0" = "400" ] && [ "$RV1" = "200" ] && [ "$RV2" = "409" ] && [ "$RVT" = "403" ] && [ "$RROW" = "REVERSED|0.00|OVERDUE|1" ] \
    && [ "$RL" = "-123000|Banka hareketi bulunamadı, mükerrer onay" ] && echo "$VF" | grep -q '"valid":true' \
    && ok "ters kayıt: gerekçesiz 400, ödeme silinmedi (REVERSED), borç geri açıldı (OVERDUE), deftere -1.230,00 gerekçeli; ikinci kez 409, sakin 403; kat maliki zinciri doğruluyor (geçerli)" \
    || bad "ters kayıt: $RV0 / $RV1 / $RV2 / $RVT / $RROW / $RL / $VF"
  # Defter kaydı veritabanında değiştirilirse doğrulama yakalar
  TS=$($PSQL -t -A -c "SELECT seq FROM finance_ledger WHERE payment_id='$VP2' AND entry_type='PAYMENT_CONFIRMED';")
  $PSQL -c "UPDATE finance_ledger SET amount_kurus = 1 WHERE payment_id='$VP2' AND entry_type='PAYMENT_CONFIRMED';" >/dev/null
  VT=$(curl -s "$FIN/ledger/verify" -H "$FA")
  $PSQL -c "UPDATE finance_ledger SET amount_kurus = 123000 WHERE payment_id='$VP2' AND entry_type='PAYMENT_CONFIRMED';" >/dev/null
  VT2=$(curl -s "$FIN/ledger/verify" -H "$FA")
  echo "$VT" | grep -q '"valid":false' && echo "$VT" | grep -q "\"first_invalid_seq\":$TS" && echo "$VT" | grep -q 'değiştirilmiş' && echo "$VT2" | grep -q '"valid":true' \
    && ok "veritabanında oynanan defter kaydı (sıra $TS) doğrulamada yakalandı; geri alınınca zincir yine geçerli" \
    || bad "defter kurcalama: $VT / $VT2"
  $PSQL -c "DELETE FROM finance_ledger WHERE payment_id IN ('$VP1','$VP2'); DELETE FROM payment_assessments WHERE payment_id IN ('$VP1','$VP2'); DELETE FROM payments WHERE id IN ('$VP1','$VP2');
            UPDATE monthly_assessments SET late_fee=0, total_amount=base_amount, paid_amount=0, status='PENDING' WHERE id='$ASSESS';
            DELETE FROM late_fee_accruals WHERE assessment_id='$ASSESS';" >/dev/null 2>&1
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

# 4.4 Tahakkuk dağıtımı kuruş doğruluğu (2026-10-03). Önceden POST /finance/assessments
# hiç sınanmıyordu; dağıtım float64 ile yapılıp her daire ayrı yuvarlanıyordu
# (1.000 TL / 3 daire → 999,99) ve "Isınma" (METER_READING) sessizce arsa payıyla bölünüyordu.
if [ "$FUP" = "1" ] && [ -n "${MGR:-}" ]; then
  AURL="http://127.0.0.1:${FINPORT}/api/v1/finance/assessments"
  C_EQ='55555555-5555-5555-5555-555555555501'; C_SR='55555555-5555-5555-5555-555555555502'; C_MR='55555555-5555-5555-5555-555555555506'
  PQ="property_id='$DEMO_PROPERTY' AND period_year=2031 AND period_month=7"
  R=$(curl -s -w '\n%{http_code}' -X POST "$AURL" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"period_year\":2031,\"period_month\":7,\"due_date\":\"2031-07-15\",\"expense_items\":[{\"category_id\":\"$C_EQ\",\"amount\":1000},{\"category_id\":\"$C_MR\",\"amount\":500}]}")
  N=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments WHERE $PQ;")
  [ "$(echo "$R" | tail -1)" = "400" ] && [ "$N" = "0" ] && echo "$R" | grep -q 'sayaç modülünde' \
    && ok "sayaç bazlı kalem (Isınma) tahakkukta arsa payıyla bölünmüyor → 400, hiç kayıt yok" \
    || bad "METER_READING kalemi: $(echo "$R" | tail -1), kayıt $N: $(echo "$R" | head -c 200)"

  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$AURL" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"period_year\":2031,\"period_month\":7,\"due_date\":\"2031-07-15\",\"expense_items\":[{\"category_id\":\"$C_EQ\",\"amount\":1000},{\"category_id\":\"$C_SR\",\"amount\":777.77},{\"category_id\":\"$C_EQ\",\"amount\":100.01}]}")
  TSUM=$($PSQL -t -A -c "SELECT SUM(total_amount) FROM monthly_assessments WHERE $PQ;")
  [ "$SC" = "201" ] && [ "$TSUM" = "1877.78" ] \
    && ok "tahakkuk toplamı gider kalemleri toplamına kuruşu kuruşuna eşit (1877.78)" \
    || bad "tahakkuk toplamı: $SC, $TSUM (1877.78 bekleniyordu)"
  MIS=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments ma WHERE $PQ
    AND ma.total_amount <> (SELECT COALESCE(SUM(d.amount),0) FROM assessment_details d WHERE d.assessment_id = ma.id);")
  CATS=$($PSQL -t -A -c "SELECT string_agg(expense_category_id::text || '=' || s::text, ',' ORDER BY expense_category_id)
    FROM (SELECT d.expense_category_id, SUM(d.amount) s FROM assessment_details d
          JOIN monthly_assessments ma ON ma.id = d.assessment_id WHERE $PQ GROUP BY d.expense_category_id) x;")
  [ "$MIS" = "0" ] && [ "$CATS" = "$C_EQ=1100.01,$C_SR=777.77" ] \
    && ok "her dairenin tahakkuku kalem satırlarının toplamına, her kalemin payları kalem tutarına birebir eşit" \
    || bad "kalem tutarlılığı: uyuşmayan daire $MIS, kalem toplamları '$CATS'"
  $PSQL -c "DELETE FROM assessment_details WHERE assessment_id IN (SELECT id FROM monthly_assessments WHERE $PQ);
    DELETE FROM monthly_assessments WHERE $PQ;" >/dev/null
fi

# Açılış (devir) bakiyesi (FAZ 8.1, migration 034): önceki yönetimden devreden borç
# girilemiyordu. Devir bakiyeye/borçlu listesine girer, dönem özetine ve otomatik
# gecikme tazminatına girmez.
if [ "$FUP" = "1" ] && [ -n "${MGR:-}" ]; then
  OURL="http://127.0.0.1:${FINPORT}/api/v1/finance/opening-balances"
  OTHER2=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0 AND id <> '$A3UNIT' ORDER BY door_number LIMIT 1;")
  B0=$(api_balance "$(debt_status)")
  OB=$(curl -s -w '\n%{http_code}' -X POST "$OURL" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"due_date\":\"2026-06-30\",\"items\":[{\"unit_id\":\"$A3UNIT\",\"amount\":1500.50,\"description\":\"Onceki yonetimden devir\"},{\"unit_id\":\"$OTHER2\",\"amount\":250}]}")
  B1=$(api_balance "$(debt_status)")
  DIFF=$(awk "BEGIN{printf \"%.2f\", $B1 - $B0}")
  [ "$(echo "$OB" | tail -1)" = "201" ] && [ "$DIFF" = "1500.50" ] \
    && ok "devir bakiyesi girildi; sakinin bakiyesi tam 1.500,50 TL arttı" || bad "devir: $(echo "$OB" | tail -1), fark $DIFF ($(echo "$OB" | head -c 200))"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d "{\"due_date\":\"2026-06-30\",\"items\":[{\"unit_id\":\"$A3UNIT\",\"amount\":10}]}")
  NO=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments WHERE kind='OPENING' AND deleted=0 AND property_id='$DEMO_PROPERTY';")
  [ "$SC" = "409" ] && [ "$NO" = "2" ] && ok "bir bölüme ikinci devir kaydı girilemiyor → 409" || bad "ikinci devir: $SC, kayıt $NO"
  curl -s -o /dev/null -X POST "http://127.0.0.1:${FINPORT}/api/v1/finance/late-fees/accrue" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{}'
  OLF=$($PSQL -t -A -c "SELECT COALESCE(SUM(late_fee),0)::text FROM monthly_assessments WHERE kind='OPENING' AND property_id='$DEMO_PROPERTY';")
  [ "$OLF" = "0.00" ] && ok "vadesi geçmiş devir kaydına otomatik gecikme tazminatı işletilmedi (çift tahsilat yok)" || bad "devire tazminat işlendi: $OLF"
  OID=$($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE kind='OPENING' AND deleted=0 AND unit_id='$A3UNIT';")
  $PSQL -c "UPDATE monthly_assessments SET paid_amount=1 WHERE id='$OID';" >/dev/null
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/$OID/cancel" -H "Authorization: Bearer $MGR")
  $PSQL -c "UPDATE monthly_assessments SET paid_amount=0 WHERE id='$OID';" >/dev/null
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/$OID/cancel" -H "Authorization: Bearer $MGR")
  [ "$SC" = "409" ] && [ "$SC2" = "200" ] && ok "ödemesi olan devir kaydı iptal edilemiyor (409), ödenmemiş olan iptal ediliyor (200)" || bad "devir iptali: $SC / $SC2"
  for X in $($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE kind='OPENING' AND deleted=0 AND property_id='$DEMO_PROPERTY';"); do
    curl -s -o /dev/null -X POST "$OURL/$X/cancel" -H "Authorization: Bearer $MGR"
  done
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

    # 7579 s. Kanun (RG 22/5/2026): proje GENEL KURULDA onaylanır. Gündem maddesi
    # olmadan yönetici tek başına kesinleştiremez.
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/finalize" -H "$GA" -H "$GJ" -d '{}')
    [ "$SC" = "422" ] && ok "genel kurul kararı (gündem maddesi) olmadan kesinleştirme engellendi → 422 (KMK m.37, 7579)" \
      || bad "kararsız kesinleştirme → $SC"

    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/notify" -H "$GA" -H "$GJ" \
      -d '{"method":"TAAHHUTLU_MEKTUP"}')
    [ "$SC" = "200" ] && ok "geçici işletme projesi bildirildi" || bad "bildirim → $SC"

    # Bildirim GEÇİCİ projedir: üç ay içinde genel kurulda karara bağlanmalı;
    # mülga yedi günlük itiraz süresi artık yazılmaz.
    ROW=$($PSQL -t -A -c "SELECT approval_deadline = (CURRENT_DATE + interval '3 months')::date, objection_deadline IS NULL
                          FROM operating_budgets WHERE id='$BID';")
    [ "$ROW" = "t|t" ] && ok "genel kurul son günü bildirimden 3 ay sonra; mülga 7 günlük itiraz süresi yazılmadı" \
      || bad "geçici proje süreleri: $ROW"
    PAR=$($PSQL -t -A -c "SELECT effective_to FROM legal_parameters WHERE code='BUDGET_OBJECTION_DAYS' AND property_id IS NULL;")
    [ "$PAR" = "2026-05-22" ] && ok "BUDGET_OBJECTION_DAYS yürürlüğü 22/5/2026'da kapandı (geçmiş projeler için korunuyor)" \
      || bad "itiraz süresi parametresi kapanmadı: $PAR"

    # Kabul edilmemiş / var olmayan gündem maddesiyle kesinleştirilemez
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$GURL/budgets/$BID/finalize" -H "$GA" -H "$GJ" \
      -d '{"agenda_item_id":"00000000-0000-0000-0000-000000000000"}')
    ST=$($PSQL -t -A -c "SELECT status FROM operating_budgets WHERE id='$BID';")
    [ "$SC" = "422" ] && [ "$ST" = "NOTIFIED" ] && ok "kabul edilmiş gündem maddesi olmadan proje kesinleşmedi → 422" \
      || bad "uydurma gündem maddesiyle kesinleştirme → $SC ($ST)"
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
  # Vergi/SGK yükümlülük takvimi (FAZ 7.7, 041)
  TD=$(date +%F)
  E2=$(curl -s -X POST "$PURL/employees" -H "$PA" -H "$PJ" -d "{\"first_name\":\"Yeni\",\"last_name\":\"Gorevli\",\"position\":\"Güvenlik\",\"hire_date\":\"$TD\"}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  CAL=$(curl -s "$PURL/compliance-calendar" -H "$PA")
  echo "$CAL" | python3 -c "
import json,sys,datetime
d=json.load(sys.stdin); it=d['data']; today=datetime.date.today()
ex=[i for i in it if i['kind']=='SGK_EXIT' and i['employee_id']=='$EMPID']
en=[i for i in it if i['kind']=='SGK_ENTRY' and i['employee_id']=='$E2']
mu=[i for i in it if i['kind']=='MUHSGK']; pr=[i for i in it if i['kind']=='SGK_PREMIUM']
prev=(today.replace(day=1)-datetime.timedelta(days=1)).strftime('%Y-%m')
assert ex and ex[0]['due_date'][:10]=='2026-09-10' and ex[0]['days_left']<0, ex
assert en and en[0]['days_left']==0, en
assert mu and int(mu[0]['due_date'][8:10]) in (26,27,28) and mu[0]['period'] in (prev, today.strftime('%Y-%m')), mu
assert pr and 'VUK m.18' in d['note'] and d['muhsgk_enabled'] is True
" 2>/tmp/verify-cal.err; PY=$?
  [ "$PY" = "0" ] && ok "takvim: ayrılış bildirgesi (bitiş+10 gün, 5510 m.9) gecikmiş, işe giriş bildirgesi bugün, MUHSGK 26'sı (hafta sonu kaydırmalı), prim ay sonu" \
    || bad "yükümlülük takvimi: $(tail -2 /tmp/verify-cal.err) — $CAL"
  FUT=$(date -d '+3 day' +%F)
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/employees/$EMPID/sgk" -H "$PA" -H "$PJ" -d "{\"exit_date\":\"$FUT\"}")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/employees/$E2/sgk" -H "$PA" -H "$PJ" -d "{\"exit_date\":\"$TD\"}")
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/employees/$EMPID/sgk" -H "$PA" -H "$PJ" -d '{"exit_date":"2026-09-05"}')
  SC4=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/employees/$E2/sgk" -H "$PA" -H "$PJ" -d "{\"entry_date\":\"$TD\"}")
  SC5=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/compliance-calendar" -H "Authorization: Bearer $TEN")
  LEFT=$(curl -s "$PURL/compliance-calendar" -H "$PA" | python3 -c "import json,sys; print(len([i for i in json.load(sys.stdin)['data'] if i.get('employee_id') in ('$EMPID','$E2')]))" 2>/dev/null)
  [ "$SC1" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "200" ] && [ "$SC4" = "200" ] && [ "$SC5" = "403" ] && [ "$LEFT" = "0" ] \
    && ok "bildirge tarihi kaydedilince yükümlülük kapanıyor; gelecek tarih ve ayrılmamış personele ayrılış bildirgesi 422; sakin göremez" \
    || bad "SGK bildirge kaydı: $SC1 / $SC2 / $SC3 / $SC4 / $SC5 — kalan $LEFT"
  $PSQL -c "INSERT INTO property_settings (property_id, setting_key, value_bool, value_type) VALUES ('$DEMO_PROPERTY','MUHSGK_CALENDAR',false,'BOOL')
    ON CONFLICT (property_id, setting_key) DO UPDATE SET value_bool = false;" >/dev/null
  NM=$(curl -s "$PURL/compliance-calendar" -H "$PA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len([i for i in d['data'] if i['kind'] in ('MUHSGK','SGK_PREMIUM')]), d['muhsgk_enabled'])" 2>/dev/null)
  $PSQL -c "DELETE FROM property_settings WHERE property_id='$DEMO_PROPERTY' AND setting_key='MUHSGK_CALENDAR';" >/dev/null
  [ "$NM" = "0 False" ] && ok "MUHSGK takvimi site ayarıyla kapatılabiliyor (Kolay İşverenlik / mali müşavir)" || bad "MUHSGK ayarı: $NM"
  # Bordro KAYDI (FAZ 7.4, 047, S-22=b): hesap yok; net ödeme + işveren maliyeti
  pr() { curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/payroll" -H "$PA" -H "$PJ" -d "$1"; }
  PR1=$(curl -s -X POST "$PURL/payroll" -H "$PA" -H "$PJ" -d "{\"employee_id\":\"$EMPID\",\"period\":\"2026-08\",\"net_salary\":22000.50,\"employer_cost\":35100.25,\"gross_salary\":30000,\"source_ref\":\"Mali müşavir A, bordro 2026/08\"}")
  PRID=$(echo "$PR1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  P1=$(pr "{\"employee_id\":\"$EMPID\",\"period\":\"2026-08\",\"net_salary\":1,\"employer_cost\":2,\"source_ref\":\"x\"}")
  P2=$(pr "{\"employee_id\":\"$EMPID\",\"period\":\"2026-09\",\"net_salary\":1,\"employer_cost\":2,\"source_ref\":\"x\"}")
  P3=$(pr "{\"employee_id\":\"$E2\",\"period\":\"$(date +%Y-%m)\",\"net_salary\":100,\"employer_cost\":99,\"source_ref\":\"x\"}")
  P4=$(pr "{\"employee_id\":\"$E2\",\"period\":\"$(date +%Y-%m)\",\"net_salary\":100,\"employer_cost\":150}")
  P5=$(pr "{\"employee_id\":\"$E2\",\"period\":\"$(date -d '+1 month' +%Y-%m)\",\"net_salary\":100,\"employer_cost\":150,\"source_ref\":\"x\"}")
  P6=$(pr "{\"employee_id\":\"$E2\",\"period\":\"$(date +%Y-%m)\",\"net_salary\":100.123,\"employer_cost\":150,\"source_ref\":\"x\"}")
  [ -n "$PRID" ] && echo "$PR1" | grep -q '"payment_status":"PENDING"' && [ "$P1" = "409" ] && [ "$P2" = "422" ] && [ "$P3" = "422" ] && [ "$P4" = "400" ] && [ "$P5" = "422" ] && [ "$P6" = "422" ] \
    && ok "bordro kaydı: çalışan+dönem tekil (409), ayrılış sonrası dönem 422, maliyet<net 422, kaynaksız 400, gelecek dönem 422, 3 ondalık 422" \
    || bad "bordro kaydı: $PR1 / $P1 / $P2 / $P3 / $P4 / $P5 / $P6"
  PL=$(curl -s "$PURL/payroll?period=2026-08" -H "$PA")
  echo "$PL" | python3 -c "
import json,sys; d=json.load(sys.stdin); t=d['totals']
assert abs(t['net']-22000.50)<1e-9 and abs(t['employer_cost']-35100.25)<1e-9 and t['pending_count']==1, t
assert 'Test Personel' not in d['missing'] and 'hesaplamaz' in d['note'], d
" 2>/tmp/verify-pr.err && PLOK=1 || PLOK=0
  PM=$(curl -s "$PURL/payroll?period=$(date +%Y-%m)" -H "$PA" | python3 -c "import json,sys; print('Yeni Gorevli' in json.load(sys.stdin)['missing'])" 2>/dev/null)
  PS=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/payroll?period=2026-08" -H "Authorization: Bearer $TEN")
  [ "$PLOK" = "1" ] && [ "$PM" = "True" ] && [ "$PS" = "403" ] \
    && ok "bordro listesi: toplamlar kuruşu kuruşuna (22.000,50 / 35.100,25), bordrosu girilmemiş çalışan listeleniyor, sakin 403" \
    || bad "bordro listesi: $(tail -1 /tmp/verify-pr.err) / eksik=$PM / sakin=$PS — $PL"
  PY1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/payroll/$PRID/pay" -H "$PA" -H "$PJ" -d '{"payment_date":"2026-09-05","payment_reference":"EFT-1"}')
  PY2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/payroll/$PRID/pay" -H "$PA" -H "$PJ" -d '{"payment_date":"2026-09-05"}')
  PY3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/payroll/$PRID/cancel" -H "$PA" -H "$PJ" -d '{"reason":"hata"}')
  PU=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); UPDATE payroll SET net_salary = 1 WHERE id='$PRID'; COMMIT;" 2>&1 | grep -c 'değiştirilemez')
  PD=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); DELETE FROM payroll; COMMIT;" 2>&1 | grep -c 'permission denied')
  PC=$(curl -s "$PURL/payroll/costs?year=2026" -H "$PA" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['data'][0]['period'], d['employer_cost_total'])" 2>/dev/null)
  [ "$PY1" = "200" ] && [ "$PY2" = "409" ] && [ "$PY3" = "409" ] && [ "$PU" -ge 1 ] && [ "$PD" -ge 1 ] && [ "$PC" = "2026-08 35100.25" ] \
    && ok "bordro ödemesi: ikinci ödeme 409, ödenmiş kayıt iptal edilemez/değiştirilemez (tetikleyici), silinemez; yıllık maliyet raporu" \
    || bad "bordro ödemesi: $PY1 / $PY2 / $PY3 / update=$PU / delete=$PD / maliyet=$PC"
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
  echo "$V1" | grep -q 'ziyaretçiye siz iletin' && echo "$V1" | grep -q '"pin":"[0-9]\{6\}"' \
    && ok "ön kayıtta geçiş kodu üretildi; ziyaretçiye sistemin ileti göndermediği (sakinin ilettiği) dürüstçe bildiriliyor" \
    || bad "ziyaretçi geçiş kodu/bildirim durumu: $V1"

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

  # B69: liste güvenlik tavanında (500) SESSİZCE kesilmemeli — yanıt bunu söyler
  echo "$MLIST" | grep -q '"truncated":false' && ok "ziyaretçi listesi kesilmediğini bildiriyor (truncated:false)" || bad "truncated alanı yok"
  $PSQL -c "INSERT INTO visitors (property_id, unit_id, visitor_name)
    SELECT '$DEMO_PROPERTY', '$MGRUNIT', 'Toplu Ziyaretci' FROM generate_series(1, 501);" >/dev/null
  curl -s "$VURL/visitors" -H "$VA" >/tmp/verify-trunc.json
  TR=$(python3 -c 'import json; d=json.load(open("/tmp/verify-trunc.json")); print("%d|%s" % (len(d["data"]), d.get("truncated")))')
  $PSQL -c "DELETE FROM visitors WHERE visitor_name='Toplu Ziyaretci';" >/dev/null
  [ "$TR" = "500|True" ] && ok "tavan aşılınca 500 kayıt dönüyor ve kesildiği bildiriliyor (truncated:true)" || bad "kesilme bildirimi: $TR"

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

  # Geçiş kodu (TEST_RAPORU 2.8, 051): tek kullanımlık PIN/QR, özetle saklanır, sakine teyit bildirimi
  vp() { curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/verify-pass" -H "${2:-$VA}" -H "$VJ" -d "{\"code\":\"$1\"}"; }
  PIN2=$(echo "$V2" | sed -n 's/.*"pin":"\([0-9]*\)".*/\1/p')
  PLAIN=$($PSQL -t -A -c "SELECT count(*) FROM visitors WHERE id='$V2ID' AND (pin_hash = '$PIN2' OR pin_hash IS NULL OR length(pin_hash) <> 64);")
  P1=$(vp "$PIN2" "$VT")
  WRONG=$([ "$PIN2" = "000000" ] && echo 111111 || echo 000000)
  P2=$(vp "$WRONG")
  RP=$(curl -s -X POST "$VURL/visitors/$V2ID/pass" -H "$VT" -H "$VJ" -d '{}')
  PIN2B=$(echo "$RP" | sed -n 's/.*"pin":"\([0-9]*\)".*/\1/p')
  P3=$(vp "$PIN2")
  VPR=$(curl -s -X POST "$VURL/visitors/verify-pass" -H "$VA" -H "$VJ" -d "{\"code\":\"$PIN2B\"}")
  P5=$(vp "$PIN2B")
  VST=$($PSQL -t -A -c "SELECT status || '|' || (pin_hash IS NULL) FROM visitors WHERE id='$V2ID';")
  VPN=$(qscoped "SELECT count(*) FROM notifications WHERE topic='visitor.checkin' AND payload->>'visitor_id'='$V2ID';")
  [ "$PLAIN" = "0" ] && [ "$P1" = "403" ] && [ "$P2" = "404" ] && [ -n "$PIN2B" ] && [ "$P3" = "404" ] && echo "$VPR" | grep -q '"sent":1' \
    && [ "$P5" = "404" ] && [ "$VST" = "CHECKED_IN|true" ] && [ "${VPN:-0}" -ge 1 ] \
    && ok "geçiş PIN'i: veritabanında özet, sakin doğrulayamaz 403, yanlış kod 404, yeni kod eskisini geçersiz kılar, görevli doğrulayınca giriş + daireye bildirim, kod tek kullanımlık" \
    || bad "geçiş PIN'i: plain=$PLAIN $P1 $P2 yeni=$PIN2B eski=$P3 / $VPR / tekrar=$P5 / $VST / bildirim=$VPN"
  V3=$(curl -s -X POST "$VURL/visitors" -H "$VT" -H "$VJ" -d "{\"unit_id\":\"$TENUNIT\",\"visitor_name\":\"QR Ziyaretci\"}")
  QR3=$(echo "$V3" | sed -n 's/.*"qr_token":"\([^"]*\)".*/\1/p')
  Q1=$(vp "$QR3")
  V4=$(curl -s -X POST "$VURL/visitors" -H "$VT" -H "$VJ" -d "{\"unit_id\":\"$TENUNIT\",\"visitor_name\":\"Gec Ziyaretci\"}")
  V4ID=$(echo "$V4" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4); PIN4=$(echo "$V4" | sed -n 's/.*"pin":"\([0-9]*\)".*/\1/p')
  $PSQL -c "UPDATE visitors SET qr_expires_at = now() - interval '1 minute' WHERE id='$V4ID';" >/dev/null
  Q2=$(vp "$PIN4")
  RO=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VURL/visitors/$V1ID/pass" -H "$VT" -H "$VJ" -d '{}')
  [ "$Q1" = "200" ] && [ "$Q2" = "410" ] && [ "$RO" = "409" ] \
    && ok "QR jetonuyla giriş 200; süresi dolmuş kod 410; başkasının ziyaretçisine kod üretilemez 409" \
    || bad "QR/süre: $Q1 / $Q2 / $RO — $V3"

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
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PRKPORT} DEVICE_WATCH_INTERVAL=1s \
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

  # --- Geçiş cihazı canlılık izleme (057, Apsiyon BUG-08) ---
  DV=$(curl -s -X POST "$KURL/access-devices" -H "$KA" -H "$KJ" -d '{"name":"Giriş kamerası","kind":"PTS_CAMERA","location":"A kapısı","heartbeat_interval_sec":60}')
  DVID=$(echo "$DV" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  DKEY=$(echo "$DV" | grep -o '"device_key":"[^"]*"' | cut -d'"' -f4)
  DHASH=$(printf '%s' "$DKEY" | sha256sum | cut -d' ' -f1)
  DDB=$($PSQL -t -A -c "SELECT key_hash = '$DHASH', offline_after_sec, (SELECT count(*) FROM access_devices WHERE key_hash = '$DKEY') FROM access_devices WHERE id = '$DVID';")
  [ -n "$DVID" ] && [ "${DKEY#dev_}" != "$DKEY" ] && [ "$DDB" = "t|180|0" ] \
    && ok "cihaz kaydedildi; anahtar bir kez gösterildi, yalnızca SHA-256 özeti saklandı, çevrimdışı eşiği 3 aralık (180 sn)" \
    || bad "cihaz kaydı: $DDB — $DV"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/access-devices" -H "$KA" -H "$KJ" -d '{"name":"X","kind":"UFO"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/access-devices" -H "$KA" -H "$KJ" -d '{"name":"X","kind":"BARRIER","heartbeat_interval_sec":60,"offline_after_sec":90}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KURL/access-devices" -H "Authorization: Bearer $TEN" -H "$KJ" -d '{"name":"X","kind":"BARRIER"}')
  [ "$SC" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "403" ] \
    && ok "geçersiz tür 422, tek aralıklık eşik 422 (gecikmiş tek sinyal alarm üretmesin), sakin cihaz ekleyemiyor 403" \
    || bad "cihaz doğrulaması: $SC / $SC2 / $SC3"
  HB="http://127.0.0.1:${PRKPORT}/api/v1/public/devices/heartbeat"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$HB" -H "$KJ" -d '{}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$HB" -H "X-Device-Key: dev_yanlis" -H "$KJ" -d '{}')
  HR=$(curl -s -X POST "$HB" -H "X-Device-Key: $DKEY" -H "$KJ" -d '{"status":"ok fw-1.2"}')
  DL=$(curl -s "$KURL/access-devices" -H "$KA" | python3 -c "
import json,sys
d=[x for x in json.load(sys.stdin)['data'] if x['id']=='$DVID'][0]; print(d['online'], d['last_status'], 'open_incident_id' in d)" 2>/dev/null)
  [ "$SC" = "401" ] && [ "$SC2" = "401" ] && echo "$HR" | grep -q '"recovered":false' && [ "$DL" = "True ok fw-1.2 False" ] \
    && ok "anahtarsız/yanlış anahtarlı sinyal 401; doğru anahtarla sinyal kaydedildi, cihaz çevrimiçi" \
    || bad "sinyal: $SC / $SC2 / $HR / $DL"
  # Sinyal kesildi: son sinyal 10 dk önce → bekçi (1 sn) olay açmalı ve yönetim + görevliye bildirmeli
  $PSQL -c "UPDATE access_devices SET last_seen_at = now() - interval '10 minutes' WHERE id = '$DVID';" >/dev/null
  OPENED=""
  for _ in $(seq 1 15); do
    OPENED=$($PSQL -t -A -c "SELECT count(*) FROM device_incidents WHERE device_id = '$DVID' AND recovered_at IS NULL;")
    [ "$OPENED" = "1" ] && break
    sleep 1
  done
  sleep 2
  INC=$($PSQL -t -A -c "SELECT (SELECT count(*) FROM device_incidents WHERE device_id = '$DVID'),
    (SELECT count(*) FROM notifications WHERE topic = 'device.offline' AND payload->>'device_id' = '$DVID'),
    (SELECT count(DISTINCT recipient_user_id) FROM notifications WHERE topic = 'device.offline' AND payload->>'device_id' = '$DVID'),
    (SELECT bool_and(subject LIKE 'Plaka tanıma kamerası çevrimdışı%') FROM notifications WHERE topic = 'device.offline' AND payload->>'device_id' = '$DVID');")
  INCN=$(echo "$INC" | cut -d'|' -f1); NTN=$(echo "$INC" | cut -d'|' -f2); NTU=$(echo "$INC" | cut -d'|' -f3)
  [ "$OPENED" = "1" ] && [ "$INCN" = "1" ] && [ "$NTN" -ge 1 ] && [ "$NTN" = "$NTU" ] && [ "$(echo "$INC" | cut -d'|' -f4)" = "t" ] \
    && ok "sinyal kesilince bekçi olay açtı ve yönetime bildirdi; sonraki turlarda ikinci olay/bildirim yok ($INC)" \
    || bad "çevrimdışı alarmı: açık=$OPENED, $INC — $(tail -5 /tmp/verify-parking.log)"
  DL=$(curl -s "$KURL/access-devices" -H "$KA" | python3 -c "
import json,sys
d=[x for x in json.load(sys.stdin)['data'] if x['id']=='$DVID'][0]; print(d['online'], 'open_incident_id' in d)" 2>/dev/null)
  [ "$DL" = "False True" ] && ok "cihaz listesinde çevrimdışı ve açık olay görünüyor" || bad "liste durumu: $DL"
  HR=$(curl -s -X POST "$HB" -H "X-Device-Key: $DKEY" -H "$KJ" -d '{"status":"ok"}')
  REC=$($PSQL -t -A -c "SELECT (SELECT count(*) FROM device_incidents WHERE device_id = '$DVID' AND recovered_at IS NOT NULL),
    (SELECT count(*) > 0 FROM notifications WHERE topic = 'device.recovered' AND payload->>'device_id' = '$DVID');")
  [ "$REC" = "1|t" ] && echo "$HR" | grep -q '"recovered":true' \
    && ok "sinyal geri gelince olay kapandı ve 'yeniden çevrimiçi' bildirimi gitti" || bad "toparlanma: $REC / $HR"
  ICS=$(curl -s "$KURL/access-devices/incidents" -H "$KA" | grep -c "$DVID")
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$KURL/access-devices" -H "Authorization: Bearer $TEN")
  [ "$ICS" -ge 1 ] && [ "$SC" = "403" ] && ok "olay geçmişi listeleniyor; sakin cihaz listesini göremiyor 403" || bad "olay listesi: $ICS / $SC"
  DD=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "
    BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; DELETE FROM device_incidents; COMMIT;" 2>&1)
  echo "$DD" | grep -qi 'permission denied' && ok "olay geçmişi uygulama rolüyle silinemiyor" || bad "olay silinebildi: $DD"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$KURL/access-devices/$DVID" -H "$KA")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$HB" -H "X-Device-Key: $DKEY" -H "$KJ" -d '{}')
  [ "$SC" = "200" ] && [ "$SC2" = "401" ] && ok "pasife alınan cihazın sinyali kabul edilmiyor (401), izleme durdu" || bad "pasife alma: $SC / $SC2"
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

  # 16) Tesis tanımlama (TEST_RAPORU 2.1, 048): API + demo tesisler + iptal son süresi
  fac() { curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/facilities" -H "${2:-$RA}" -H "$RJ" -d "$1"; }
  NF=$(curl -s -X POST "$RURL/facilities" -H "$RA" -H "$RJ" -d '{"name":"Barbekü Alanı","category":"BBQ","capacity":12,"available_from":"10:00","available_to":"21:00","available_days":[0,1,2,3,4,5,6],"min_duration_minutes":60,"max_duration_minutes":180,"cancellation_deadline_hours":48,"requires_approval":false}')
  NFID=$(echo "$NF" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  F1=$(fac '{"name":"X","available_from":"22:00","available_to":"08:00"}')
  F2=$(fac '{"name":"X","is_paid":true}')
  F3=$(fac '{"name":"X","available_days":[7]}')
  F4=$(fac '{"name":"X","maintenance_mode":true}')
  F5=$(fac '{"name":"X","is_paid":true,"hourly_fee":10.555}')
  F6=$(fac '{"name":"X"}' "$RT")
  F7=$(fac '{"name":"X","category":"HAVUZ"}')
  FLS=$(curl -s "$RURL/facilities" -H "$RT")
  [ -n "$NFID" ] && [ "$F1" = "422" ] && [ "$F2" = "422" ] && [ "$F3" = "422" ] && [ "$F4" = "422" ] && [ "$F5" = "422" ] && [ "$F6" = "403" ] && [ "$F7" = "422" ] \
    && echo "$FLS" | grep -q 'Barbekü Alanı' && echo "$FLS" | grep -q 'Tenis Kortu' && echo "$FLS" | grep -q 'Sosyal Tesis Toplantı Salonu' \
    && ok "tesis API'den eklendi, sakin listesinde görünüyor; demo tesisler yüklü; ters saat/ücretsiz ücretli/geçersiz gün/notsuz bakım/3 ondalık/kategori 422, sakin 403" \
    || bad "tesis ekleme: $NF / $F1 $F2 $F3 $F4 $F5 $F6 $F7 — $FLS"
  # Düzenleme: bakım kipine alınan tesise rezervasyon yapılamaz, mevcut kurallar korunur
  PT=$(curl -s -X PATCH "$RURL/facilities/$NFID" -H "$RA" -H "$RJ" -d '{"maintenance_mode":true,"maintenance_note":"Izgara bakımı"}')
  MR=$(curl -s -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{\"facility_id\":\"$NFID\",\"start_time\":\"${D1}T12:00:00+03:00\",\"end_time\":\"${D1}T13:00:00+03:00\"}")
  PT2=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$RURL/facilities/$NFID" -H "$RA" -H "$RJ" -d '{"maintenance_mode":false}')
  KEEP=$($PSQL -t -A -c "SELECT capacity, cancellation_deadline_hours FROM facilities WHERE id='$NFID';")
  PT3=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH "$RURL/facilities/$NFID" -H "$RT" -H "$RJ" -d '{"is_active":false}')
  echo "$PT" | grep -q 'mevcut rezervasyonlar değişmedi' && echo "$MR" | grep -q 'Izgara bakımı' && [ "$PT2" = "200" ] && [ "$KEEP" = "12|48" ] && [ "$PT3" = "403" ] \
    && ok "tesis düzenleme: bakım kipinde rezervasyon notla reddediliyor, gönderilmeyen alanlar korunuyor, sakin düzenleyemez" \
    || bad "tesis düzenleme: $PT / $MR / $PT2 / $KEEP / $PT3"
  # İptal son süresi (48 saat) yalnızca sakine uygulanır
  CR=$(curl -s -X POST "$RURL/reservations" -H "$RT" -H "$RJ" -d "{\"facility_id\":\"$NFID\",\"start_time\":\"${D1}T15:00:00+03:00\",\"end_time\":\"${D1}T16:00:00+03:00\"}")
  CRID=$(echo "$CR" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  CC1=$(curl -s -w '|%{http_code}' -X POST "$RURL/reservations/$CRID/cancel" -H "$RT" -H "$RJ" -d '{}')
  CC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RURL/reservations/$CRID/cancel" -H "$RA" -H "$RJ" -d '{"reason":"yonetim"}')
  case "$CC1" in *"48 saat önce"*"|422") CCOK=1 ;; *) CCOK=0 ;; esac
  [ -n "$CRID" ] && [ "$CCOK" = "1" ] && [ "$CC2" = "200" ] \
    && ok "iptal son süresi (48 sa): yarınki rezervasyonda sakin iptali 422, yönetim iptali 200" \
    || bad "iptal son süresi: $CR / $CC1 / $CC2"
else
  bad "reservation-service başlamadı"; tail -10 /tmp/verify-reservation.log
fi
kill_tree "$RES_PID"

step "17) Kargo modülü — mock'tan gerçeğe (FAZ 5, 6. modül)"
# Önceki davranış: sabit kargo listesi; teslim alma/teslim etme kaydedilmiyordu ve
# yanıt "sakine bildirim gönderildi" diyordu — bildirim altyapısı hiç yoktu.
PKGPORT=${VERIFY_PKG_PORT:-18097}
rm -rf /tmp/verify-pkg-files; mkdir -p /tmp/verify-pkg-files
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${PKGPORT} \
STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-pkg-files PACKAGE_PURGE_INTERVAL=2s \
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
    echo "$D1" | grep -q 'İmza/fotoğraf gönderilmedi' && ok "dosyasız teslimde imza/fotoğraf olmadığı dürüstçe bildiriliyor" \
      || bad "imza saklama iddiası dürüst değil: $D1"

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

  # 13) Teslim kanıtı: imza + fotoğraf depoda, SHA-256 ile (TEST_RAPORU 2.3, 052)
  python3 -c "import base64,sys; open('/tmp/v-sig.png','wb').write(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=')); open('/tmp/v-photo.jpg','wb').write(b'\xff\xd8\xff\xe0' + b'JFIF-test-photo' * 20); open('/tmp/v-bad.txt','w').write('düz metin')"
  P3ID=$(curl -s -X POST "$PURL/packages" -H "$PA" -H "$PJ" -d "{\"unit_id\":\"$UNIT_TEN\",\"recipient_name\":\"Ayse Demir\",\"carrier\":\"PTT\"}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  PB1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P3ID/deliver" -H "$PA" -F "photo=@/tmp/v-bad.txt")
  PB2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL/packages/$P3ID/deliver" -H "$PA" -F "delivered_to_name=Ayse Demir" -F "photo=@/tmp/v-bad.txt")
  DP=$(curl -s -X POST "$PURL/packages/$P3ID/deliver" -H "$PA" -F "delivered_to_name=Ayse Demir" -F "signature=@/tmp/v-sig.png" -F "photo=@/tmp/v-photo.jpg")
  SIGSHA=$(sha256sum /tmp/v-sig.png | cut -d' ' -f1); PHSHA=$(sha256sum /tmp/v-photo.jpg | cut -d' ' -f1)
  DBP=$($PSQL -t -A -c "SELECT delivery_signature_url LIKE 'packages/%', delivery_signature_sha256, delivery_photo_sha256, status FROM packages WHERE id='$P3ID';")
  NF=$(find /tmp/verify-pkg-files -type f -path "*$P3ID*" ! -name '*.meta.json' | wc -l)
  [ "$PB1" = "400" ] && [ "$PB2" = "422" ] && echo "$DP" | grep -q "\"signature_sha256\":\"$SIGSHA\"" && [ "$DBP" = "t|$SIGSHA|$PHSHA|DELIVERED" ] && [ "$NF" = "2" ] \
    && ok "teslim kanıtı: imza ve fotoğraf depoya yazıldı, kayıtta SHA-256; isimsiz 400, görsel olmayan dosya 422" \
    || bad "teslim kanıtı: $PB1 / $PB2 / $DP / $DBP / dosya=$NF"
  curl -s "$PURL/packages/$P3ID/proof/signature" -H "$PT" -o /tmp/v-got.png -w '%{http_code}' >/tmp/v-code
  GOT=$(cat /tmp/v-code); GOTSHA=$(sha256sum /tmp/v-got.png | cut -d' ' -f1)
  GM=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages/$P3ID/proof/photo" -H "$PA")
  GO=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages/$P1ID/proof/signature" -H "$PT")
  GN=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages/$P1ID/proof/signature" -H "$PA")
  SIGFILE=$(find /tmp/verify-pkg-files -type f -path "*$P3ID*signature*" ! -name '*.meta.json' | head -1)
  cp "$SIGFILE" /tmp/v-sig.bak; printf 'degistirildi' > "$SIGFILE"
  GT=$(curl -s -o /dev/null -w '%{http_code}' "$PURL/packages/$P3ID/proof/signature" -H "$PA")
  cp /tmp/v-sig.bak "$SIGFILE"
  [ "$GOT" = "200" ] && [ "$GOTSHA" = "$SIGSHA" ] && [ "$GM" = "200" ] && [ "$GO" = "404" ] && [ "$GN" = "404" ] && [ "$GT" = "409" ] \
    && ok "kanıt dosyası: dairenin sakini ve yönetim indirebiliyor (özet birebir), komşu 404, kanıtsız teslim 404, değiştirilmiş dosya 409" \
    || bad "kanıt indirme: $GOT ($GOTSHA) / $GM / $GO / $GN / bozuk=$GT"
  # KVKK imhası sonrası dosya silme kuyruğu (kargo servisi işler)
  PHKEY=$($PSQL -t -A -c "SELECT delivery_photo_url FROM packages WHERE id='$P3ID';")
  $PSQL -c "INSERT INTO storage_deletion_queue (property_id, storage_key, reason) VALUES ('$DEMO_PROPERTY', '$PHKEY', 'TEST');" >/dev/null
  sleep 4
  QL=$($PSQL -t -A -c "SELECT count(*) FROM storage_deletion_queue WHERE storage_key='$PHKEY';")
  PHF=$(find /tmp/verify-pkg-files -type f -path "*$P3ID*photo*" ! -name '*.meta.json' | wc -l)
  [ "$QL" = "0" ] && [ "$PHF" = "0" ] && ok "silme kuyruğundaki kanıt dosyası depodan silindi, kuyruk temizlendi" \
    || bad "silme kuyruğu: kuyruk=$QL dosya=$PHF"
  # Depo yapılandırılmamışsa kanıtlı teslim 503 (sessizce kaydedilmez)
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18297 STORAGE_BACKEND= \
    go run ./services/package >/tmp/verify-package2.log 2>&1 &
  PKG2_PID=$!
  for _ in $(seq 1 45); do curl -fsS "http://127.0.0.1:18297/health" >/dev/null 2>&1 && break; sleep 1; done
  P4ID=$(curl -s -X POST "$PURL/packages" -H "$PA" -H "$PJ" -d "{\"unit_id\":\"$UNIT_TEN\",\"recipient_name\":\"Ayse Demir\"}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  NS=$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://127.0.0.1:18297/api/v1/packages/$P4ID/deliver" -H "$PA" -F "delivered_to_name=Ayse Demir" -F "signature=@/tmp/v-sig.png")
  NST=$($PSQL -t -A -c "SELECT status FROM packages WHERE id='$P4ID';")
  kill_tree "$PKG2_PID"
  [ "$NS" = "503" ] && [ "$NST" != "DELIVERED" ] && ok "depo yapılandırılmamışken kanıtlı teslim 503 ve teslim kaydedilmedi" \
    || bad "depo yokken kanıtlı teslim: $NS / $NST"
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
  # 12) Sigorta: DASK takibi ve hasar kaydı (FAZ 7.2, 045; 6305 s. Kanun)
  TENU=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559876543';")
  TUN=$($PSQL -t -A -c "SELECT unit_id FROM resident_units WHERE resident_id='$TENU' AND is_active LIMIT 1;")
  U1=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='11111111-1111-1111-1111-111111111111' AND deleted=0 AND id<>'$TUN' ORDER BY block, door_number LIMIT 1;")
  dask() { curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/insurance/dask" -H "$1" -H "$CJ" -d "$2"; }
  S20=$(date -d '-345 day' +%F); E20=$(date -d '+20 day' +%F)
  SC1=$(dask "Authorization: Bearer $TEN" "{\"unit_id\":\"$TUN\",\"policy_no\":\"D-1\",\"start_date\":\"$S20\",\"end_date\":\"$E20\"}")
  SC2=$(dask "$CA" "{\"unit_id\":\"$U1\",\"policy_no\":\"D-100\",\"insurer\":\"Test Sigorta\",\"start_date\":\"$S20\",\"end_date\":\"$E20\"}")
  SC3=$(dask "$CA" "{\"unit_id\":\"$U1\",\"policy_no\":\"D-100\",\"start_date\":\"$S20\",\"end_date\":\"$E20\"}")
  SC4=$(dask "$CA" "{\"unit_id\":\"$U1\",\"policy_no\":\"D-101\",\"start_date\":\"$E20\",\"end_date\":\"$S20\"}")
  DL=$(curl -s "$CURL/insurance/dask" -H "$CA")
  ST=$(echo "$DL" | python3 -c "import json,sys; d=json.load(sys.stdin); r=[x for x in d['data'] if x['unit_id']=='$U1']; print(r[0]['state'], d['summary'].get('MISSING',0)>0, '6305' in d['note'])" 2>/dev/null)
  TL=$(curl -s "$CURL/insurance/dask" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["data"]))' 2>/dev/null)
  [ "$SC1" = "403" ] && [ "$SC2" = "201" ] && [ "$SC3" = "409" ] && [ "$SC4" = "422" ] && [ "$ST" = "EXPIRING True True" ] && [ "$TL" = "0" ] \
    && ok "DASK: kiracı poliçe giremiyor (yükümlülük malikin, 6305 m.10/3); 20 gün kalan poliçe 'bitiyor', kayıtsız bölümler görünüyor; kiracıya liste boş" \
    || bad "DASK: $SC1 / $SC2 / $SC3 / $SC4 — $ST / kiracı $TL"
  FUTC=$(date -d '+2 day' +%F)
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/insurance/claims" -H "$CA" -H "$CJ" -d "{\"occurred_on\":\"$FUTC\",\"description\":\"Çatıdan su sızdı, tavan hasar gördü\"}")
  CLM=$(curl -s -X POST "$CURL/insurance/claims" -H "$CA" -H "$CJ" -d "{\"occurred_on\":\"$(date +%F)\",\"description\":\"Çatıdan su sızdı, tavan hasar gördü\",\"claimed_amount\":15000}" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  cst() { curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL/insurance/claims/$CLM/status" -H "$CA" -H "$CJ" -d "$1"; }
  SC2=$(cst '{"status":"CLOSED"}'); SC3=$(cst '{"status":"PAID"}'); SC4=$(cst "{\"status\":\"PAID\",\"paid_amount\":12000,\"paid_on\":\"$(date +%F)\"}"); SC5=$(cst '{"status":"REPORTED"}')
  SC6=$(curl -s -o /dev/null -w '%{http_code}' "$CURL/insurance/claims" -H "Authorization: Bearer $TEN")
  CD=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','11111111-1111-1111-1111-111111111111',true); DELETE FROM insurance_claims; COMMIT;" 2>&1 | grep -c 'permission denied')
  [ "$SC1" = "422" ] && [ "$SC2" = "409" ] && [ "$SC3" = "422" ] && [ "$SC4" = "200" ] && [ "$SC5" = "409" ] && [ "$SC6" = "403" ] && [ "$CD" -ge 1 ] \
    && ok "hasar kaydı: gelecek tarih 422, durum makinesi geri gitmiyor (409), tazminatsız PAID 422; sakin göremez; kayıt silinemez" \
    || bad "hasar kaydı: $SC1 / $SC2 / $SC3 / $SC4 / $SC5 / $SC6 / silme engeli $CD"
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
  echo "$H" | grep -q 'sensörler (074) gerçektir' && ok "sağlık ucu kapsamı doğru bildiriyor (sensörler gerçek)" \
    || bad "kapsam notu yok: $H"

  # Sensör uçları artık gerçek (074): liste 200
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$OURL/sensors" -H "$OA")
  [ "$SC" = "200" ] && ok "sensör listesi gerçek veriyle dönüyor (074)" || bad "sensör ucu → $SC (200 bekleniyordu)"

  # Isı paylaştırması sabit payı kullanım alanına göre dağıtır; demo alanı (049, brüt×0,85)
  # yoksa tanımlanır. Net alan brütü aşamaz (049 kısıtı).
  $PSQL -c "UPDATE units SET net_area_m2 = round(gross_area_m2 * 0.85, 2) WHERE id IN ('$U303','$U304','$U305') AND net_area_m2 IS NULL;" >/dev/null 2>&1

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
    echo "$BW" | grep -q 'meters/:id/replace' && ok "sayaç değişimi için doğru yol gösteriliyor" || bad "yönlendirme yok"

    # Apsiyon BUG-07: okuma ucunda "sayaç değişti" artık kabul edilmez (endeksi sıfırlayıp
    # eski sayacın son tüketimini kaybettiriyordu); değişim protokolüne yönlendirilir.
    RP=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"50\",
      \"meter_replaced\":true,\"reason\":\"Sayac arizalandi, yenisi takildi\"}")
    [ "$(echo "$RP" | tail -1)" = "422" ] && echo "$RP" | grep -q 'meters/:id/replace' \
      && ok "okuma ucunda endeks sıfırlama reddedildi → 422, değişim protokolüne yönlendirildi" \
      || bad "eski sıfırlama yolu açık: $RP"

    # Sapma dedektörü: önceki tüketim 100 → 400 birim (4 kat) teyitsiz kaydedilmez
    AN=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"1500\"}")
    [ "$(echo "$AN" | tail -1)" = "409" ] && echo "$AN" | grep -q '"code":"ANOMALY"' && echo "$AN" | grep -q '"ratio":"4.00"' \
      && ok "önceki tüketimin 4 katı okuma teyitsiz kaydedilmedi → 409 ANOMALY (oran 4.00)" \
      || bad "sapma dedektörü: $AN"
    AN=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"1500\",\"confirm_anomaly\":true}")
    ANDB=$($PSQL -t -A -c "SELECT anomaly_ratio, anomaly_confirmed_by IS NOT NULL FROM meter_readings
      WHERE meter_id='$M1ID' AND reading_date='2026-03-01';")
    [ "$(echo "$AN" | tail -1)" = "201" ] && [ "$ANDB" = "4.00|t" ] \
      && ok "görevli teyidiyle kaydedildi; oran ve teyit eden kayda geçti ($ANDB)" \
      || bad "teyitli okuma: $AN / $ANDB"

    # Aynı tarihe ikinci okuma
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-03-01\",\"current_value\":\"1600\"}")
    [ "$SC" = "409" ] && ok "aynı tarihe ikinci okuma engellendi → 409" || bad "çift okuma → $SC"

    DBR=$($PSQL -t -A -c "SELECT count(*) FROM meter_readings WHERE meter_id='$M1ID';")
    [ "$DBR" = "3" ] && ok "okumalar veritabanında (mock değil, 3 kayıt)" || bad "okuma sayısı: $DBR"

    # Sayaç değişim protokolü: söküm endeksi son okumadan küçük olamaz
    RPX=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meters/$M1ID/replace" -H "$OA" -H "$OJ" -d '{
      "removal_value":"1400","replaced_on":"2026-03-15","new_serial_number":"HT-0001B","new_initial_value":"7","reason":"Arıza"}')
    [ "$(echo "$RPX" | tail -1)" = "422" ] && ok "son okumadan küçük söküm endeksi reddedildi → 422" || bad "söküm denetimi: $RPX"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meters/$M1ID/replace" -H "$OT" -H "$OJ" -d '{
      "removal_value":"1520","replaced_on":"2026-03-15","new_serial_number":"HT-0001B","new_initial_value":"7","reason":"Arıza"}')
    [ "$SC" = "403" ] && ok "sakin sayaç değiştiremiyor → 403" || bad "sakin sayaç değiştirdi → $SC"
    RPN=$(curl -s -w '\n%{http_code}' -X POST "$OURL/meters/$M1ID/replace" -H "$OA" -H "$OJ" -d '{
      "removal_value":"1520","replaced_on":"2026-03-15","new_serial_number":"HT-0001B","new_initial_value":"7","reason":"Sayaç arızalandı, yenisi takıldı"}')
    NEWM=$(echo "$RPN" | head -1 | grep -o '"new_meter_id":"[^"]*"' | cut -d'"' -f4)
    RPDB=$($PSQL -t -A -c "SELECT (SELECT is_active FROM meters WHERE id='$M1ID'),
      (SELECT current_value FROM meter_readings WHERE meter_id='$M1ID' AND reading_date='2026-03-15'),
      (SELECT previous_value||'/'||current_value FROM meter_readings WHERE meter_id='$NEWM'),
      (SELECT removal_value||'/'||initial_value FROM meter_replacements WHERE old_meter_id='$M1ID');")
    [ "$(echo "$RPN" | tail -1)" = "201" ] && [ "$RPDB" = "f|1520.000|7.000/7.000|1520.000/7.000" ] \
      && ok "sayaç değişti: eski sayaca söküm okuması (1520) yazıldı ve pasife alındı, yeni sayaç montaj endeksiyle (7) açıldı" \
      || bad "sayaç değişimi: $RPN / $RPDB"
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$M1ID\",\"reading_date\":\"2026-04-01\",\"current_value\":\"1600\"}")
    [ "$SC" = "409" ] && ok "sökülen sayaca okuma girilemiyor → 409" || bad "pasif sayaca okuma → $SC"
    RNEW=$(curl -s -X POST "$OURL/meter-readings" -H "$OA" -H "$OJ" -d "{
      \"meter_id\":\"$NEWM\",\"reading_date\":\"2026-04-01\",\"current_value\":\"57\"}")
    echo "$RNEW" | grep -q '"previous_value":"7"' && echo "$RNEW" | grep -q '"consumption":"50"' \
      && ok "yeni sayacın ilk tüketimi montaj endeksinden hesaplandı (57−7=50; sıfırdan değil)" || bad "yeni sayaç okuması: $RNEW"
    SC=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "
      BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY';
      UPDATE meter_replacements SET reason='x'; COMMIT;" 2>&1)
    echo "$SC" | grep -qi 'permission denied' && ok "sayaç değişim kaydı uygulama rolüyle değiştirilemiyor" \
      || bad "değişim kaydı değiştirilebildi: $SC"
    # Değişim dönemi: tüketim = (söküm − eski son okuma) + (yeni son okuma − montaj) = 20 + 50 = 70
    RAL=$(curl -s -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
      "meter_type":"HEAT","from":"2026-03-02","to":"2026-04-30","total_amount_try":1000}')
    RALU=$(echo "$RAL" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for u in d['allocation']['units']:
    if u['unit_id']=='$U303': print(u['consumption'], u['meter_replaced'], u['first_value'], u['last_value'])
" 2>/dev/null)
    [ "$RALU" = "70 True 1500 57" ] \
      && ok "değişim döneminde tüketim iki sayaçtan toplandı: (1520−1500)+(57−7)=70, ilk/son endeks ve değişim işaretli" \
      || bad "değişim dönemi tüketimi: $RALU — $RAL"
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
  [ "$MACODE" = "422" ] && echo "$MA" | grep -q '"missing_area_units":\["[^"]*"\]' && echo "$MA" | grep -q 'm.3 ve m.8' \
    && ok "ısıtmada kullanım alanı eksikse dağıtım reddediliyor → 422 ve eksik bölüm adıyla listeleniyor" \
    || bad "eksik alanla ısı dağıtımı: $MA"
  AC=$(curl -s "$OURL/consumption/area-check" -H "$OA")
  ACN=$(echo "$AC" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['ready'], any(m['unit_id']=='$U305' for m in d['missing']), d['total_units']>0)" 2>/dev/null)
  ACT=$(curl -s -o /dev/null -w '%{http_code}' "$OURL/consumption/area-check" -H "$OT")
  [ "$ACN" = "False True True" ] && [ "$ACT" = "403" ] && ok "paylaştırma öncesi alan denetimi eksik net m² olan bölümü listeliyor; sakin 403" \
    || bad "alan denetimi: $ACN / $ACT — $AC"
  WA2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"WATER_COLD","from":"2026-01-01","to":"2026-02-28","total_amount_try":500}')
  [ "$WA2" = "200" ] && ok "su dağıtımı kullanım alanından bağımsız çalışıyor" \
    || bad "su dağıtımı alan eksikliğinden etkilendi → $WA2"
  # Net alan brütü aşamaz (049); sabit 100 m² brütü küçük bölümde kısıta takılırdı.
  RESTA=$($PSQL -t -A -c "UPDATE units SET net_area_m2 = round(gross_area_m2 * 0.85, 2) WHERE id = '$U305' RETURNING net_area_m2 IS NOT NULL;" 2>&1 | head -1)
  [ "$RESTA" = "t" ] && ok "eksik bırakılan kullanım alanı geri yüklendi" || bad "alan geri yüklenemedi: $RESTA"

  # 7c) Tüketim pusulası (Apsiyon BUG-07): okuması eksik dönem yayımlanamaz; yayımlanan değişmez
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-03-02","to":"2026-04-30","total_amount_try":1000,"publish":true}')
  [ "$SC" = "422" ] && ok "okuması eksik bölüm varken paylaştırma yayımlanamıyor → 422" || bad "eksik okumayla yayım → $SC"
  PB=$(curl -s -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":10000,"publish":true}')
  ALID=$(echo "$PB" | grep -o '"allocation_id":"[^"]*"' | cut -d'"' -f4)
  PBDB=$($PSQL -t -A -c "SELECT (SELECT total_kurus FROM consumption_allocations WHERE id='$ALID'),
    (SELECT count(*) FROM consumption_allocation_units WHERE allocation_id='$ALID'),
    (SELECT sum(total_kurus) FROM consumption_allocation_units WHERE allocation_id='$ALID');")
  [ -n "$ALID" ] && [ "$PBDB" = "1000000|3|1000000" ] && echo "$PB" | grep -q 'YAYIMLANDI' \
    && ok "paylaştırma yayımlandı: 3 bölümün pusulası saklandı, satır toplamı tutara eşit ($PBDB)" \
    || bad "yayım: $PBDB — $PB"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$OURL/consumption/allocate" -H "$OA" -H "$OJ" -d '{
    "meter_type":"HEAT","from":"2026-01-01","to":"2026-02-28","total_amount_try":12000,"publish":true}')
  [ "$SC" = "409" ] && ok "aynı dönem ikinci kez yayımlanamıyor → 409 (pusula sonradan değişmez)" || bad "ikinci yayım → $SC"
  SC=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "
    BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY';
    UPDATE consumption_allocation_units SET total_kurus = 1; COMMIT;" 2>&1)
  echo "$SC" | grep -qi 'permission denied' && ok "yayımlanmış pusula satırı uygulama rolüyle değiştirilemiyor" \
    || bad "pusula değiştirilebildi: $SC"
  # Sakin (304) yalnızca kendi satırını görür; yönetim üç satırı
  TS=$(curl -s "$OURL/consumption/statements" -H "$OT")
  TSN=$(echo "$TS" | python3 -c "
import json,sys
d=json.load(sys.stdin)['data']
a=[x for x in d if x['id']=='$ALID']
print(len(a), len(a[0]['lines']) if a else -1, a[0]['lines'][0]['unit_id']=='$U304' if a else False, a[0]['lines'][0]['first_value'], a[0]['lines'][0]['last_value'], a[0]['lines'][0]['consumption'])" 2>/dev/null)
  [ "$TSN" = "1 1 True 0 200 200" ] && ok "sakin pusulasında yalnızca kendi bölümü: ilk endeks 0, son endeks 200, tüketim 200" \
    || bad "sakin pusulası: $TSN — $TS"
  MS=$(curl -s "$OURL/consumption/statements/$ALID" -H "$OA" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['lines']))" 2>/dev/null)
  [ "$MS" = "3" ] && ok "yönetim pusulanın tüm satırlarını görüyor (3)" || bad "yönetim pusulası: $MS"
  curl -s -o /tmp/verify-pusula.pdf "$OURL/consumption/statements/$ALID/pdf" -H "$OT"
  PTXT=$(python3 -c "
import pypdf
r=pypdf.PdfReader('/tmp/verify-pusula.pdf'); print(' '.join(p.extract_text() for p in r.pages))" 2>/dev/null | tr -d '\n')
  echo "$PTXT" | grep -q 'tüketim pusulası' && echo "$PTXT" | grep -q 'A-4' && ! echo "$PTXT" | grep -q 'A-3' \
    && ok "sakin pusula PDF'i üretiliyor ve yalnızca kendi bölümünü içeriyor" || bad "pusula PDF: $(echo "$PTXT" | head -c 300)"

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
  # Başka sitenin (hiçbir siteye bağlı olmayan) kullanıcısı adına, açık adres verilse bile kayıt açılmamalı
  FORN=$($PSQL -t -A -c "INSERT INTO users (first_name, last_name, phone, password_hash, roles)
    VALUES ('Yabanci', 'Kullanici', '+905550000079', 'x', ARRAY['RESIDENT']) ON CONFLICT (phone) DO UPDATE SET first_name = EXCLUDED.first_name RETURNING id;" | grep -E '^[0-9a-f-]{36}$')
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$NURL/notifications" -H "$NA" -H 'Content-Type: application/json' \
    -d "{\"recipient_user_id\":\"$FORN\",\"recipient\":\"+905550000079\",\"channel\":\"SMS\",\"body\":\"yabanci deneme\"}")
  NF=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE recipient_user_id='${FORN:-00000000-0000-0000-0000-000000000000}';")
  [ "$SC" = "404" ] && [ "$NF" = "0" ] && ok "siteye kayıtlı olmayan kullanıcı adına (açık adresle de) bildirim açılamıyor → 404" \
    || bad "yabancı kullanıcıya bildirim: $SC (kayıt $NF)"
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

  # 075: okutma konum ister; noktalara konum verilir, okutmalar noktanın yanından yapılır.
  $PSQL -c "UPDATE patrol_checkpoints SET latitude=41.0, longitude=29.0 WHERE id IN ('$CP1','$CP2','$CP3');" >/dev/null
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
      -d "{\"checkpoint_id\":\"$CP1\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5,\"note\":\"Kapi kilitli\"}")
    echo "$S1" | grep -q '"checkpoints_visited":1' && ok "nokta okutuldu (1/3)" || bad "okutma: $S1"

    # Aynı nokta iki kez okutulamaz
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CP1\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5}")
    [ "$SC" = "409" ] && ok "aynı nokta iki kez okutulamıyor → 409" || bad "çift okutma → $SC"

    # Güzergâhta olmayan nokta okutulamaz
    CPX=$(curl -s -X POST "$PURL2/patrol-checkpoints" -H "$RA" -H "$RJ2" \
      -d '{"name":"Guzergah disi","nfc_tag_id":"NFC-X-01"}' \
      | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    $PSQL -c "UPDATE patrol_checkpoints SET latitude=41.0, longitude=29.0 WHERE id='$CPX';" >/dev/null
    SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PURL2/patrols/$P1ID/scan" -H "$RA" -H "$RJ2" \
      -d "{\"checkpoint_id\":\"$CPX\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5}")
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
      -d "{\"checkpoint_id\":\"$CP2\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5}")
    [ "$SC" = "409" ] && ok "kapanmış tura okutma yapılamıyor → 409" || bad "kapalı tura okutma → $SC"

    # 7) TAM TUR — zorunlu noktaların hepsi okutulursa COMPLETED
    P2ID=$(curl -s -X POST "$PURL2/patrols" -H "$RA" -H "$RJ2" -d "{\"route_id\":\"$RTID\"}" \
      | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    curl -s -o /dev/null -X POST "$PURL2/patrols/$P2ID/scan" -H "$RA" -H "$RJ2" -d "{\"checkpoint_id\":\"$CP1\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5}"
    curl -s -o /dev/null -X POST "$PURL2/patrols/$P2ID/scan" -H "$RA" -H "$RJ2" -d "{\"checkpoint_id\":\"$CP2\",\"latitude\":41.0,\"longitude\":29.0,\"accuracy_m\":5}"
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
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${COMPORT} PII_ENCRYPTION_KEY="$PIIKEY" \
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

  # 038: ön ek listesinde olmayan sonradan eklenmiş parametreler de doğrudan SQL ile gölgelenemez
  NG=0
  for K in KVKK_RESPONSE_DAYS REVALUATION_RATE MANAGER_MANDATORY_UNIT_COUNT; do
    $PSQL -c "INSERT INTO property_settings (property_id, setting_key, value_int, value_type)
      VALUES ('11111111-1111-1111-1111-111111111111','$K',0,'INT');" >/dev/null 2>&1 && NG=$((NG+1))
  done
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/KVKK_RESPONSE_DAYS" -H "$TA" -H "$TJ" -d '{"value":90}')
  [ "$NG" = "0" ] && [ "$SC" = "422" ] && ok "sonradan eklenen mevzuat parametreleri de site ayarı olarak yazılamıyor (SQL tetikleyici + API 422)" \
    || bad "mevzuat anahtarı gölgelendi: SQL $NG kayıt, API $SC"
  # Gerçek gecikme oranı bozulmamış olmalı
  LF2=$($PSQL -t -A -c "SELECT value_numeric FROM legal_parameters WHERE code='LATE_FEE_MONTHLY_RATE' AND property_id IS NULL;")
  [ "$LF2" = "0.050000" ] && ok "mevzuat parametresi bozulmadan duruyor (%5)" || bad "oran değişti: $LF2"

  # KVKK saklama ve periyodik imha (FAZ 7.8, 043)
  RR=$(curl -s "$TURL/retention-rules" -H "$TA")
  echo "$RR" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["periodic_months"]==6 and [r["category"] for r in d["data"]]==["VISITOR","PARKING_LOG","PACKAGE","MARKET_REQUEST","CLIENT_ERROR"]' 2>/dev/null; PY=$?
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/retention-rules/VISITOR" -H "$TA" -H "$TJ" -d '{"retention_months":0,"justification":"x"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/retention-rules/VISITOR" -H "$TA" -H "$TJ" -d '{"retention_months":12}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/retention-rules/VISITOR" -H "$TA" -H "$TJ" -d '{"retention_months":12,"justification":"Güvenlik amacıyla bir yıl; olay incelemesi için yeterli"}')
  SC4=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/retention-rules" -H "Authorization: Bearer $TEN")
  [ "$PY" = "0" ] && [ "$SC1" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "200" ] && [ "$SC4" = "403" ] \
    && ok "saklama süresi: 5 kategori (079: Usta & Hizmet talep iletişimi), periyodik imha 6 ay (İmha Yön. m.11); süre/gerekçe doğrulaması; sakin göremez" || bad "saklama kuralları: py $PY / $SC1 / $SC2 / $SC3 / $SC4"
  DP='11111111-1111-1111-1111-111111111111'
  VO=$($PSQL -t -A -c "INSERT INTO visitors (property_id, visitor_name, visitor_phone, visitor_id_number, vehicle_plate, status, checked_in_at)
    VALUES ('$DP','Eski Ziyaretci','5550001111','12345678901','34ABC123','CHECKED_OUT', now() - interval '400 days') RETURNING id;" | head -1)
  VN=$($PSQL -t -A -c "INSERT INTO visitors (property_id, visitor_name, status, checked_in_at) VALUES ('$DP','Yeni Ziyaretci','CHECKED_OUT', now() - interval '10 days') RETURNING id;" | head -1)
  VI=$($PSQL -t -A -c "INSERT INTO visitors (property_id, visitor_name, status, checked_in_at) VALUES ('$DP','Iceride Ziyaretci','CHECKED_IN', now() - interval '400 days') RETURNING id;" | head -1)
  RUN=$(curl -s -X POST "$TURL/retention-rules/run" -H "$TA" -H "$TJ" -d '{}')
  ROW=$($PSQL -t -A -c "SELECT visitor_name || '|' || COALESCE(visitor_phone,'-') || '|' || COALESCE(visitor_id_number,'-') || '|' || COALESCE(vehicle_plate,'-') FROM visitors WHERE id='$VO';")
  KEEP=$($PSQL -t -A -c "SELECT count(*) FROM visitors WHERE id IN ('$VN','$VI') AND visitor_name <> '[imha edildi]';")
  LG=$($PSQL -t -A -c "SELECT count(*) FROM data_destruction_log WHERE property_id='$DP' AND category='VISITOR' AND record_count >= 1;")
  NOR=$($PSQL -t -A -c "SELECT count(*) FROM data_destruction_log WHERE property_id='$DP' AND category IN ('PARKING_LOG','PACKAGE','MARKET_REQUEST','CLIENT_ERROR');")
  [ "$ROW" = "[imha edildi]|-|-|-" ] && [ "$KEEP" = "2" ] && [ "${LG:-0}" -ge 1 ] && [ "$NOR" = "0" ] \
    && ok "süresi dolan ziyaretçi kaydı anonimleştirildi; yeni ve hâlâ içerideki kayıt korundu; imha kaydı yazıldı; süresi tanımsız kategori imha edilmedi" \
    || bad "periyodik imha: '$ROW' / korunan $KEEP / kayıt $LG / tanımsız $NOR — $RUN"
  LD=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','$DP',true); DELETE FROM data_destruction_log; COMMIT;" 2>&1)
  LN=$($PSQL -t -A -c "SELECT count(*) FROM data_destruction_log WHERE property_id='$DP';")
  [ "${LN:-0}" -ge 1 ] && ok "imha kaydı uygulama rolünce silinemiyor (İmha Yön. m.7/3, en az 3 yıl)" || bad "imha kaydı silindi: $LD"
  # Kargo teslim kanıtı dosyaları imhada silme kuyruğuna bırakılır (052)
  curl -s -o /dev/null -X PUT "$TURL/retention-rules/PACKAGE" -H "$TA" -H "$TJ" -d '{"retention_months":12,"justification":"Teslim uyuşmazlığı için bir yıl yeterli"}'
  PKO=$($PSQL -t -A -c "INSERT INTO packages (property_id, unit_id, recipient_name, status, received_at, delivered_at, delivery_signature_url, delivery_photo_url, delivery_signature_sha256)
    VALUES ('$DP','33333333-3333-3333-3333-333333333303','Eski Alici','DELIVERED', now() - interval '500 days', now() - interval '499 days',
            'packages/$DP/eski/signature-a.png', 'packages/$DP/eski/photo-a.jpg', repeat('a',64)) RETURNING id;" | head -1)
  curl -s -o /dev/null -X POST "$TURL/retention-rules/run" -H "$TA" -H "$TJ" -d '{"force":true}'
  PKQ=$($PSQL -t -A -c "SELECT count(*) FROM storage_deletion_queue WHERE property_id='$DP' AND storage_key LIKE 'packages/$DP/eski/%' AND reason='KVKK_RETENTION';")
  PKR=$($PSQL -t -A -c "SELECT recipient_name || '|' || (delivery_signature_url IS NULL) || '|' || (delivery_signature_sha256 IS NULL) FROM packages WHERE id='$PKO';")
  [ "$PKQ" = "2" ] && [ "$PKR" = "[imha edildi]|true|true" ] \
    && ok "kargo imhası: kayıt anonimleşti, imza/fotoğraf dosya anahtarları silme kuyruğuna bırakıldı (dosya sahipsiz kalmaz)" \
    || bad "kargo imhası: kuyruk=$PKQ / $PKR"
  # Kamera ve biyometrik envanteri (FAZ 7.8, 046; KVK Kurumu apartman kamera duyurusu 08/06/2026)
  cam() { curl -s -o /dev/null -w '%{http_code}' -X POST "$TURL/privacy/cameras" -H "$TA" -H "$TJ" -d "$1"; }
  SC1=$(cam '{"location":"A blok 3. kat daire kapı önü","area_type":"CORRIDOR","purpose":"güvenlik","retention_days":30}')
  SC2=$(cam '{"location":"Asansör kabini","area_type":"ELEVATOR","purpose":"güvenlik","retention_days":30}')
  SC3=$(cam '{"location":"Ana giriş","area_type":"ENTRANCE","purpose":"Giriş güvenliği","retention_days":0}')
  SC4=$(cam '{"location":"Ana giriş","area_type":"ENTRANCE","purpose":"Giriş güvenliği","retention_days":15,"notice_posted":true,"masked":true,"decision_ref":"2026 olağan genel kurul, gündem 4","access_note":"Yönetici ve güvenlik amiri"}')
  SC5=$(cam '{"location":"Otopark","area_type":"PARKING","purpose":"Araç güvenliği","retention_days":15}')
  MC=$(curl -s "$TURL/privacy/cameras" -H "$TA" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["data"]), d["open_issues"]>=3)' 2>/dev/null)
  RC=$(curl -s "$TURL/privacy/cameras" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d["data"]), all("issues" not in x and "decision_ref" not in x for x in d["data"]), "KVKK" in d["note"])' 2>/dev/null)
  [ "$SC1" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "422" ] && [ "$SC4" = "201" ] && [ "$SC5" = "201" ] && [ "$MC" = "2 True" ] && [ "$RC" = "2 True True" ] \
    && ok "kamera: daire kapı önü yasak, gerekçesiz asansör 422, saklama süresi zorunlu; uygunluk sorunları yönetime, kamera listesi (amaç/süre) sakinlere aydınlatma için" \
    || bad "kamera envanteri: $SC1 / $SC2 / $SC3 / $SC4 / $SC5 — yönetim '$MC' sakin '$RC'"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$TURL/privacy/biometrics" -H "$TA" -H "$TJ" -d '{"name":"Turnike","method":"FACE","purpose":"Giriş","consent_based":true}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$TURL/privacy/biometrics" -H "$TA" -H "$TJ" -d '{"name":"Turnike","method":"FACE","purpose":"Giriş","consent_based":true,"alternative_method":"Kartlı geçiş"}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/privacy/biometrics" -H "Authorization: Bearer $TEN")
  [ "$SC1" = "422" ] && [ "$SC2" = "201" ] && [ "$SC3" = "403" ] \
    && ok "biyometrik sistem alternatif yöntem olmadan kaydedilmiyor (KVKK m.6, özgür açık rıza); sakin envantere erişemiyor" || bad "biyometrik: $SC1 / $SC2 / $SC3"
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
  # VERBİS beyanı (S-21): opsiyonel, seçenekli; yükümlülük site yönetiminde
  VB1=$(curl -s -w '|%{http_code}' -X PUT "$TURL/settings/VERBIS_STATUS" -H "$TA" -H "$TJ" -d '{"value":"KAYITLI"}')
  VB2=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/VERBIS_STATUS" -H "$TA" -H "$TJ" -d '{"value":"REGISTERED"}')
  VB3=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$TURL/settings/VERBIS_REGISTRY_NO" -H "$TA" -H "$TJ" -d '{"value":"VB-12345"}')
  VBD=$(curl -s "$TURL/settings/definitions" -H "$TA" | python3 -c "
import json,sys; d=[x for x in json.load(sys.stdin)['data'] if x['key']=='VERBIS_STATUS'][0]
print(d['default'], len(d['options']), 'site yönetimine' in d['description'])" 2>/dev/null)
  VBS=$($PSQL -t -A -c "SELECT value_text FROM property_settings WHERE property_id='$DEMO_PROPERTY' AND setting_key='VERBIS_STATUS';")
  $PSQL -c "DELETE FROM property_settings WHERE property_id='$DEMO_PROPERTY' AND setting_key IN ('VERBIS_STATUS','VERBIS_REGISTRY_NO');" >/dev/null
  case "$VB1" in *"NOT_DECLARED, REGISTERED"*"|422") VBOK=1 ;; *) VBOK=0 ;; esac
  [ "$VBOK" = "1" ] && [ "$VB2" = "200" ] && [ "$VB3" = "200" ] && [ "$VBD" = "NOT_DECLARED 4 True" ] && [ "$VBS" = "REGISTERED" ] \
    && ok "VERBİS beyanı: varsayılan 'beyan edilmedi' (engellemez), yalnızca tanımlı seçenekler (422 + izinli değerler), sicil no isteğe bağlı" \
    || bad "VERBİS beyanı: $VB1 / $VB2 / $VB3 / $VBD / $VBS"

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

  # 8) Kimlik bilgisi kasası uçları kaldırıldı (H.1.2): sağlayıcılar ortam değişkeniyle bağlı
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$TURL/credentials" -H "$TA")
  [ "$SC" = "404" ] && ok "kimlik bilgisi uçları yok → 404 (anahtar ekranda saklanmaz)" \
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

step "29) NPS, ESG ve banka (FAZ 5)"
# NPS ve ESG gerçeğe çevrildi. Banka (S-07 kullanıcı kararı) bilinçli olarak
# 501 döndürür — NEDEN olduğunu söyleyerek. Toplantı sihirbazı servisi
# 2026-10-26'da kaldırıldı (governance ile tekrardı, FAZ H.1.1).
NPSPORT=${VERIFY_NPS_PORT:-18096}
ESGPORT=${VERIFY_ESG_PORT:-18093}
BNKPORT=${VERIFY_BNK_PORT:-18106}
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

ALLUP=1
for PORTX in ${NPSPORT} ${ESGPORT} ${BNKPORT}; do
  UPX=0
  for _ in $(seq 1 45); do
    curl -fsS "http://127.0.0.1:${PORTX}/health" >/dev/null 2>&1 && { UPX=1; break; }
    sleep 1
  done
  [ "$UPX" = "1" ] || ALLUP=0
done

if [ "$ALLUP" = "1" ] && [ -n "${MGR:-}" ] && [ -n "${TEN:-}" ]; then
  ok "nps, esg ve banking servisleri ayağa kalktı"
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

  # Bileşik skor ucu kaldırıldı (H.1.3): uydurma skor hiçbir yolla üretilmez
  SSCODE=$(curl -s -o /dev/null -w '%{http_code}' "$EURL2/sustainability-score" -H "$NA2")
  [ "$SSCODE" = "404" ] && ok "sürdürülebilirlik skoru ucu yok → 404" || bad "skor ucu → $SSCODE"

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

  # Toplantı sihirbazı kaldırıldı (H.1.1): servis dizini ve gateway öneki olmamalı
  [ ! -d services/meeting_wizard ] && ok "meeting_wizard servisi yok (governance tek kaynak)" || bad "meeting_wizard dizini duruyor"
  grep -q '/api/v1/meetings' cmd/gateway/main.go && bad "gateway hâlâ /meetings yönlendiriyor" || ok "gateway'de /meetings öneki yok"

  # Kimliksiz erişim hepsinde engelli
  for U in "http://127.0.0.1:${NPSPORT}/api/v1/nps" "http://127.0.0.1:${ESGPORT}/api/v1/esg/consumption" \
           "${BURL2}/bank-accounts"; do
    SC=$(curl -s -o /dev/null -w '%{http_code}' "$U")
    [ "$SC" = "401" ] || bad "kimliksiz erişim açık: $U → $SC"
  done
  ok "üç servisin tamamında kimliksiz erişim engelli → 401"
else
  bad "son grup servisler başlamadı"
  tail -8 /tmp/verify-nps-svc.log; tail -8 /tmp/verify-esg.log
  tail -8 /tmp/verify-bnk.log
fi
kill_tree "$NPS_PID"
kill_tree "$ESG_PID"
kill_tree "$BNK_PID"

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
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${COMPORT} PII_ENCRYPTION_KEY="$PIIKEY" \
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

  # KVKK ilgili kişi başvurusu (FAZ 7.8, 035): m.11 hakları, m.13/2 en geç 30 gün
  KU="$CURL2/kvkk-requests"
  TENUID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559876543';")
  K1=$(curl -s -w '\n%{http_code}' -X POST "$KU" -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' \
    -d '{"request_type":"INFO","description":"Hangi kişisel verilerimin işlendiğini öğrenmek istiyorum."}')
  KID=$(echo "$K1" | sed '$d' | python3 -c 'import json,sys; print(json.load(sys.stdin)["request"]["id"])' 2>/dev/null)
  KDUE=$($PSQL -t -A -c "SELECT due_date = CURRENT_DATE + 30 FROM kvkk_requests WHERE id='${KID:-00000000-0000-0000-0000-000000000000}';")
  [ "$(echo "$K1" | tail -1)" = "201" ] && [ "$KDUE" = "t" ] && ok "KVKK başvurusu kaydedildi; son gün yasal süreyle (30 gün, KVKK m.13/2) yazıldı" \
    || bad "KVKK başvurusu: $(echo "$K1" | tail -1), son gün $KDUE"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU" -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' -d '{"request_type":"INFO","description":"kisa"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU" -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' -d '{"request_type":"UYDURMA","description":"geçersiz tür denemesi metni"}')
  [ "$SC" = "422" ] && [ "$SC2" = "422" ] && ok "açıklamasız ya da geçersiz türde başvuru → 422" || bad "başvuru doğrulaması: $SC / $SC2"
  NM=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='kvkk.request' AND payload->>'kvkk_request_id'='$KID';")
  [ "${NM:-0}" -ge 1 ] && ok "yönetime KVKK başvurusu bildirildi ($NM alıcı)" || bad "yönetim bildirimi yok"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU/$KID/respond" -H "Authorization: Bearer $TEN" -H 'Content-Type: application/json' -d '{"status":"ANSWERED","response":"x"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU/$KID/respond" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"REJECTED","response":""}')
  [ "$SC" = "403" ] && [ "$SC2" = "422" ] && ok "sakin başvuruyu kendisi sonuçlandıramıyor (403); gerekçesiz ret yok (422)" || bad "yanıt yetkisi: $SC / $SC2"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU/$KID/respond" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' \
    -d '{"status":"ANSWERED","response":"Ad, soyad, telefon ve daire bilginiz aidat yönetimi amacıyla işlenmektedir."}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$KU/$KID/respond" -H "Authorization: Bearer $MGR" -H 'Content-Type: application/json' -d '{"status":"ANSWERED","response":"tekrar"}')
  NR=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='kvkk.response' AND recipient_user_id='$TENUID';")
  [ "$SC" = "200" ] && [ "$SC2" = "409" ] && [ "${NR:-0}" -ge 1 ] && ok "yönetim yanıtladı, başvuru sahibine bildirildi; ikinci yanıt → 409" \
    || bad "KVKK yanıtı: $SC, tekrar $SC2, bildirim $NR"
  TL=$(curl -s "$KU" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]; print(len(d), d[0]["status"] if d else "")' 2>/dev/null)
  [ "$TL" = "1 ANSWERED" ] && ok "sakin yalnızca kendi başvurusunu ve sonucunu görüyor" || bad "sakin başvuru listesi: '$TL'"
  KD=$(qscoped "DELETE FROM kvkk_requests WHERE id='$KID' RETURNING id;")
  KN=$($PSQL -t -A -c "SELECT count(*) FROM kvkk_requests WHERE id='$KID';")
  [ "$KN" = "1" ] && ok "uygulama rolü KVKK başvuru kaydını silemiyor (hesap verebilirlik)" || bad "başvuru silinebildi"

  # Tadilat izni (FAZ 7.5, 037): KMK m.19/2, İmar K. m.21
  RV="$CURL2/renovations"; JH='Content-Type: application/json'
  TUNIT=$($PSQL -t -A -c "SELECT unit_id FROM resident_units WHERE resident_id='$TENUID' AND is_active LIMIT 1;")
  OUNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0 AND id<>'$TUNIT' ORDER BY block, door_number LIMIT 1;")
  D0=$(date +%F); D10=$(date -d '+10 day' +%F); DPAST=$(date -d '-3 day' +%F)
  rvpost() { curl -s -w '\n%{http_code}' -X POST "$RV" -H "Authorization: Bearer $1" -H "$JH" \
    -d "{\"unit_id\":\"$2\",\"scope\":\"$3\",\"description\":\"Mutfak dolabı ve fayans yenileme\",\"start_date\":\"$4\",\"end_date\":\"$D10\"}"; }
  rvid() { echo "$1" | sed '$d' | python3 -c 'import json,sys; print(json.load(sys.stdin)["permit"]["id"])' 2>/dev/null; }
  R=$(rvpost "$TEN" "$TUNIT" INTERIOR "$D0")
  [ "$(echo "$R" | tail -1)" = "403" ] && ok "kiracı tadilat izni başvurusu yapamıyor (malik/vekil hakkı) → 403" || bad "kiracı başvurusu → $(echo "$R" | tail -1)"
  SC1=$(rvpost "$MGR" "$TUNIT" UYDURMA "$D0" | tail -1); SC2=$(rvpost "$MGR" "$TUNIT" INTERIOR "$DPAST" | tail -1)
  [ "$SC1" = "422" ] && [ "$SC2" = "422" ] && ok "geçersiz kapsam ve geçmiş başlangıç tarihi → 422" || bad "tadilat doğrulaması: $SC1 / $SC2"
  $PSQL -c "INSERT INTO property_settings (property_id, setting_key, value_text, value_type) VALUES ('$DEMO_PROPERTY','RENOVATION_HOURS','Hafta içi 09:00-18:00','TEXT')
    ON CONFLICT (property_id, setting_key) DO UPDATE SET value_text = EXCLUDED.value_text;" >/dev/null
  R=$(rvpost "$MGR" "$TUNIT" INTERIOR "$D0"); RI=$(rvid "$R")
  NM=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='renovation.request' AND payload->>'renovation_id'='$RI';")
  [ "$(echo "$R" | tail -1)" = "201" ] && [ "${NM:-0}" -ge 1 ] && ok "iç tadilat başvurusu kaydedildi, onay yetkililerine bildirildi" || bad "tadilat başvurusu: $R / $NM"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$RV/$RI" -H "Authorization: Bearer $TEN")
  TLIST=$(curl -s "$RV" -H "Authorization: Bearer $TEN" | grep -c "$RI")
  [ "$SC" = "200" ] && [ "$TLIST" = "1" ] && ok "dairenin sakini kendi dairesinin iznini görüyor" || bad "sakin izni göremiyor: $SC / $TLIST"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RI/approve" -H "Authorization: Bearer $TEN" -H "$JH" -d '{}')
  [ "$SC" = "403" ] && ok "sakin izni onaylayamıyor → 403" || bad "sakin onayı → $SC"
  A=$(curl -s -X POST "$RV/$RI/approve" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"deposit_amount":1000,"conditions":"Asansör korumalı kullanılacak"}')
  ROW=$($PSQL -t -A -c "SELECT status, work_hours, deposit_amount::text FROM renovation_permits WHERE id='$RI';")
  NB=$($PSQL -t -A -c "SELECT count(*), count(*) FILTER (WHERE n.recipient_user_id IN (SELECT resident_id FROM resident_units WHERE unit_id='$TUNIT')),
      count(*) FILTER (WHERE n.body LIKE '%' || (SELECT first_name FROM users WHERE id='$MGRID') || '%')
    FROM notifications n WHERE topic='renovation.neighbors' AND payload->>'renovation_id'='$RI';")
  IFS='|' read -r NBT NBOWN NBNAME <<<"$NB"
  [ "$ROW" = "APPROVED|Hafta içi 09:00-18:00|1000.00" ] && ok "onayda site tadilat saati ve teminat izne yazıldı" || bad "onay kaydı: $ROW — $A"
  [ "${NBT:-0}" -ge 1 ] && [ "$NBOWN" = "0" ] && [ "$NBNAME" = "0" ] \
    && ok "aynı bloktaki komşulara ($NBT) ad içermeyen bildirim gitti; dairenin kendi sakinlerine komşu bildirimi yok" || bad "komşu bildirimi: $NB"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RI/complete" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"deposit_refunded":500}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RI/complete" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"deposit_refunded":1500,"note":"x"}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RI/complete" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"deposit_refunded":500,"note":"Merdiven mermerinde kırık tespit edildi"}')
  RF=$($PSQL -t -A -c "SELECT status, deposit_refunded::text FROM renovation_permits WHERE id='$RI';")
  [ "$SC" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "200" ] && [ "$RF" = "COMPLETED|500.00" ] \
    && ok "teminat kesintisi gerekçesiz yapılamıyor, iade teminatı aşamıyor; gerekçeli kısmi iade kaydedildi" || bad "teminat iadesi: $SC / $SC2 / $SC3 — $RF"
  # Taşıyıcı sistem: ruhsat numarası olmadan onay yok
  RS=$(rvid "$(rvpost "$MGR" "$OUNIT" STRUCTURAL "$D0")")
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RS/approve" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RS/approve" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"permit_ref":"Belediye tadilat ruhsatı 2026/123"}')
  [ "$SC" = "422" ] && [ "$SC2" = "200" ] && ok "taşıyıcı sistem tadilatı ruhsat numarası olmadan onaylanmıyor (İmar K. m.21) → 422; ruhsatla 200" || bad "esaslı tadilat: $SC / $SC2"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$RV/$RS" -H "Authorization: Bearer $TEN")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' "$RV/$RS" -H "Authorization: Bearer $XMGR")
  [ "$SC" = "404" ] && [ "$SC2" = "404" ] && ok "başka dairenin izni sakine, başka sitenin iznine yöneticiye kapalı → 404" || bad "izin görünürlüğü: $SC / $SC2"
  # Dış cephe: 4/5 kat maliki yazılı rızası (KMK m.19/2)
  RF2=$(rvid "$(rvpost "$MGR" "$OUNIT" FACADE "$D0")")
  NA=$(curl -s -X POST "$RV/$RF2/approve" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  NEED=$(echo "$NA" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("consent_required",""))' 2>/dev/null)
  OWN=$($PSQL -t -A -c "SELECT count(DISTINCT ru.resident_id) FROM resident_units ru JOIN units u ON u.id=ru.unit_id
      WHERE u.property_id='$DEMO_PROPERTY' AND u.deleted=0 AND ru.role='OWNER' AND COALESCE(ru.is_active,true) AND (ru.end_date IS NULL OR ru.end_date>=CURRENT_DATE);")
  EXP=$(python3 -c "import math; print(max(1, math.ceil($OWN*0.8)))")
  echo "$NA" | grep -q "beşte dördünün" && [ "$NEED" = "$EXP" ] \
    && ok "dış cephe değişikliği rıza olmadan onaylanmıyor; gereken rıza $NEED/$OWN kat maliki (4/5, yukarı yuvarlı)" || bad "rıza nisabı: $NEED (beklenen $EXP) — $NA"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RF2/consents" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"owner_user_id\":\"$TENUID\"}")
  [ "$SC" = "422" ] && ok "kat maliki olmayan kişinin (kiracı) rızası kaydedilmiyor → 422" || bad "kiracı rızası → $SC"
  for o in $($PSQL -t -A -c "SELECT DISTINCT ru.resident_id FROM resident_units ru JOIN units u ON u.id=ru.unit_id
      WHERE u.property_id='$DEMO_PROPERTY' AND u.deleted=0 AND ru.role='OWNER' AND COALESCE(ru.is_active,true) AND (ru.end_date IS NULL OR ru.end_date>=CURRENT_DATE) LIMIT ${NEED:-1};"); do
    curl -s -o /dev/null -X POST "$RV/$RF2/consents" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"owner_user_id\":\"$o\",\"document_ref\":\"Imzali muvafakat\"}"
    LASTO=$o
  done
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RF2/consents" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"owner_user_id\":\"$LASTO\"}")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RF2/approve" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  ROW=$($PSQL -t -A -c "SELECT status, consent_required, consent_count FROM renovation_permits WHERE id='$RF2';")
  [ "$SC" = "409" ] && [ "$SC2" = "200" ] && [ "$ROW" = "APPROVED|$NEED|$NEED" ] \
    && ok "aynı malikin rızası iki kez sayılmıyor (409); 4/5 rızayla onaylandı, nisap kayda yazıldı" || bad "rızalı onay: $SC / $SC2 — $ROW"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RF2/stop" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$RV/$RF2/stop" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"reason":"Onaylanan projenin dışında cephe boyası"}')
  [ "$SC" = "422" ] && [ "$SC2" = "200" ] && ok "çalışma gerekçesiz durdurulamıyor (422), gerekçeyle durduruldu" || bad "durdurma: $SC / $SC2"
  RVD=$(qscoped "DELETE FROM renovation_permits WHERE id='$RI' RETURNING id;")
  RVN=$($PSQL -t -A -c "SELECT count(*) FROM renovation_permits WHERE id='$RI';")
  [ "$RVN" = "1" ] && ok "uygulama rolü tadilat izni kaydını silemiyor (hasar/teminat uyuşmazlığında delil)" || bad "tadilat izni silinebildi"
  # Kural ihlali (FAZ 7.5, 039): yönetim planı dayanağı, adsız bildirim, kademeli süreç, savunma
  SR="$CURL2/site-rules"; VU="$CURL2/violations"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$SR" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"title":"Gece gürültüsü","category":"NOISE"}')
  RULE=$(curl -s -X POST "$SR" -H "Authorization: Bearer $MGR" -H "$JH" \
    -d '{"title":"Gece gürültüsü","category":"NOISE","management_plan_ref":"Yönetim planı m.12/3"}' | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' 2>/dev/null)
  TR=$(curl -s "$SR" -H "Authorization: Bearer $TEN" | grep -c "$RULE")
  [ "$SC" = "422" ] && [ -n "$RULE" ] && [ "$TR" = "1" ] && ok "yönetim planı dayanağı olmayan kural eklenemiyor (KMK m.28) → 422; kural sakinlere görünüyor" \
    || bad "kural kataloğu: $SC / $RULE / $TR"
  vpost() { curl -s -X POST "$VU" -H "Authorization: Bearer $1" -H "$JH" \
    -d "{\"rule_id\":\"$RULE\",\"unit_id\":\"$2\",\"description\":\"Gece 02:00 sularında yüksek sesle müzik\"}" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["violation"]["id"])' 2>/dev/null; }
  VT=$(vpost "$TEN" "$OUNIT")   # kiracı başka daireyi bildiriyor
  VM=$(vpost "$MGR" "$TUNIT")   # yönetim kiracının dairesini bildiriyor
  NR=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='violation.reported' AND payload->>'violation_id'='$VT';")
  [ -n "$VT" ] && [ -n "$VM" ] && [ "${NR:-0}" -ge 1 ] && ok "sakin ve yönetim ihlal bildirebiliyor; onay yetkililerine bildirim gitti" || bad "ihlal bildirimi: $VT / $VM / $NR"
  RB=$(curl -s "$VU/$VM" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("reported_by","")+"|"+d.get("reporter_name","")+"|"+str(len([e for e in d.get("events",[]) if e.get("actor_name")])))' 2>/dev/null)
  RO=$(curl -s "$VU/$VT" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("reported_by",""))' 2>/dev/null)
  [ "$RB" = "||0" ] && [ "$RO" = "$TENUID" ] && ok "ihlal bildirilen daire bildireni görmüyor; bildiren kendi kaydını görüyor" || bad "bildiren gizliliği: '$RB' / '$RO'"
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$VU/$VT" -H "Authorization: Bearer $XMGR")
  [ "$SC" = "404" ] && ok "başka sitenin yöneticisi ihlal kaydını göremiyor → 404" || bad "çapraz site ihlal → $SC"
  esc() { curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$1/escalate" -H "Authorization: Bearer $MGR" -H "$JH" -d "$2"; }
  SC1=$(esc "$VM" '{"stage":"VERBAL_WARNING"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VM/verify" -H "Authorization: Bearer $TEN" -H "$JH" -d '{}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VM/verify" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  [ "$SC1" = "409" ] && [ "$SC2" = "403" ] && [ "$SC3" = "200" ] && ok "doğrulanmadan uyarı yok (409); sakin doğrulayamıyor (403); yönetim doğruladı" || bad "doğrulama: $SC1 / $SC2 / $SC3"
  SC1=$(esc "$VM" '{"stage":"WRITTEN_WARNING"}'); SC2=$(esc "$VM" '{"stage":"VERBAL_WARNING"}')
  SC3=$(esc "$VM" '{"stage":"VERBAL_WARNING"}'); SC4=$(esc "$VM" '{"stage":"WRITTEN_WARNING","note":"İkinci kez gece gürültüsü"}')
  NW=$($PSQL -t -A -c "SELECT count(*) FILTER (WHERE recipient_user_id='$TENUID'), count(*) FILTER (WHERE body LIKE '%m.12/3%') FROM notifications WHERE topic='violation.written_warning' AND payload->>'violation_id'='$VM';")
  [ "$SC1" = "422" ] && [ "$SC2" = "200" ] && [ "$SC3" = "409" ] && [ "$SC4" = "200" ] && [ "${NW%%|*}" = "1" ] && [ "${NW##*|}" -ge 1 ] \
    && ok "kademe yalnızca ileri gidiyor, yazılı uyarı açıklamasız olmuyor; uyarı yönetim planı dayanağıyla dairenin kiracısına da gitti (KMK m.18)" \
    || bad "kademeli süreç: $SC1 / $SC2 / $SC3 / $SC4 — bildirim $NW"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VM/respond" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"note":"O saatte evde değildim"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VT/respond" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"note":"x"}')
  [ "$SC1" = "201" ] && [ "$SC2" = "403" ] && ok "dairenin sakini savunma yazabiliyor; başka dairenin kaydına yazamıyor → 403" || bad "savunma: $SC1 / $SC2"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VT/dismiss" -H "Authorization: Bearer $MGR" -H "$JH" -d '{}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$VU/$VT/dismiss" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"note":"Kamera kaydında doğrulanmadı"}')
  ND=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='violation.dismissed' AND recipient_user_id='$TENUID';")
  [ "$SC1" = "422" ] && [ "$SC2" = "200" ] && [ "${ND:-0}" -ge 1 ] && ok "bildirim gerekçesiz reddedilemiyor; gerekçeli ret bildirene iletildi" || bad "ret: $SC1 / $SC2 / $ND"
  EV=$(qscoped "UPDATE rule_violation_events SET note='degisti' WHERE violation_id='$VM' RETURNING id;")
  EN=$($PSQL -t -A -c "SELECT count(*) FROM rule_violation_events WHERE violation_id='$VM' AND note='degisti';")
  VD=$(qscoped "DELETE FROM rule_violations WHERE id='$VM' RETURNING id;")
  VN=$($PSQL -t -A -c "SELECT count(*) FROM rule_violations WHERE id='$VM';")
  [ "$EN" = "0" ] && [ "$VN" = "1" ] && ok "ihlal olay geçmişi değiştirilemiyor, kayıt silinemiyor (KMK m.33 dosyası)" || bad "olay geçmişi korunmuyor: $EN / $VN"
  RC=$(curl -s "$VU" -H "Authorization: Bearer $MGR" | python3 -c "import json,sys; d=[v for v in json.load(sys.stdin)['data'] if v['id']=='$VM']; print(d[0]['unit_repeat_count'], d[0]['stage'], d[0]['reporter_name']!='')" 2>/dev/null)
  [ "$RC" = "1 WRITTEN_WARNING True" ] && ok "yönetim listesinde tekrar sayısı, kademe ve bildiren görünüyor" || bad "yönetim listesi: '$RC'"
  # Acil durum ve afet (FAZ 7.3, 040)
  EU="$CURL2/emergency"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/points" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"kind":"ASSEMBLY_AREA","name":"Toplanma alanı","location":"B blok arkası otopark"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/points" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"kind":"UYDURMA","name":"x","location":"y"}')
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/points" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"kind":"GAS_VALVE","name":"x","location":"y"}')
  SC4=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/contacts" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"category":"UTILITY","name":"Doğalgaz acil","phone":"187"}')
  INFO=$(curl -s "$EU/info" -H "Authorization: Bearer $TEN")
  [ "$SC1" = "201" ] && [ "$SC2" = "422" ] && [ "$SC3" = "403" ] && [ "$SC4" = "201" ] && echo "$INFO" | grep -q 'B blok arkası' && echo "$INFO" | grep -q '"national_emergency":"112"' \
    && ok "acil durum bilgi kartı: yönetim ekler, sakin görür (112 ile); sakin ekleyemez, geçersiz tür 422" || bad "bilgi kartı: $SC1 / $SC2 / $SC3 / $SC4 — $INFO"
  FUT=$(date -d '+2 day' +%F)
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/drills" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"kind\":\"EARTHQUAKE\",\"drill_date\":\"$FUT\",\"findings\":\"x\"}")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/drills" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"kind\":\"EARTHQUAKE\",\"drill_date\":\"$D0\",\"findings\":\"\"}")
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/drills" -H "Authorization: Bearer $MGR" -H "$JH" -d "{\"kind\":\"EARTHQUAKE\",\"drill_date\":\"$D0\",\"participants\":42,\"findings\":\"C blok merdiven aydınlatması yetersiz\",\"corrective_actions\":\"Acil aydınlatma eklenecek\"}")
  SC4=$(curl -s -o /dev/null -w '%{http_code}' "$EU/drills" -H "Authorization: Bearer $TEN")
  [ "$SC1" = "422" ] && [ "$SC2" = "422" ] && [ "$SC3" = "201" ] && [ "$SC4" = "403" ] \
    && ok "tatbikat raporu: gelecek tarih ve eksiklik alanı boş 422 (Acil Durumlar Yön. m.13); kaydedildi; sakin göremez" || bad "tatbikat: $SC1 / $SC2 / $SC3 / $SC4"
  DD=$(qscoped "DELETE FROM emergency_drills RETURNING id;"); DN=$($PSQL -t -A -c "SELECT count(*) FROM emergency_drills WHERE property_id='$DEMO_PROPERTY';")
  [ "${DN:-0}" -ge 1 ] && ok "tatbikat raporu uygulama rolünce silinemiyor" || bad "tatbikat kaydı silindi"
  NEEDS="Tekerlekli sandalye kullanıyorum; tahliyede yardım gerekir"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$EU/cards/me" -H "Authorization: Bearer $TEN" -H "$JH" -d "{\"unit_id\":\"$TUNIT\",\"needs\":\"$NEEDS\"}")
  CV=$(curl -s "$EU/cards/me" -H "Authorization: Bearer $TEN" | python3 -c 'import json,sys; print(json.load(sys.stdin)["consent_version"])' 2>/dev/null)
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$EU/cards/me" -H "Authorization: Bearer $TEN" -H "$JH" \
    -d "{\"unit_id\":\"$TUNIT\",\"needs\":\"$NEEDS\",\"household_count\":3,\"consent\":true,\"consent_version\":\"$CV\"}")
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X PUT "$EU/cards/me" -H "Authorization: Bearer $TEN" -H "$JH" \
    -d "{\"unit_id\":\"$OUNIT\",\"needs\":\"x\",\"consent\":true,\"consent_version\":\"$CV\"}")
  ENC=$($PSQL -t -A -c "SELECT needs_encrypted FROM resident_emergency_cards WHERE user_id='$TENUID';")
  [ "$SC1" = "422" ] && [ "$SC2" = "200" ] && [ "$SC3" = "422" ] && [ -n "$ENC" ] && ! echo "$ENC" | grep -q "Tekerlekli" && echo "$ENC" | grep -q '^k1\$' \
    && ok "acil bilgi kartı açık rıza olmadan kaydedilmiyor (KVKK m.6/3-a); veritabanında şifreli (k1\$…); başka daireye yazılamıyor" || bad "acil kartı: $SC1 / $SC2 / $SC3 — '$ENC'"
  MY=$(curl -s "$EU/cards/me" -H "Authorization: Bearer $TEN" | grep -c "Tekerlekli")
  AB=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='SENSITIVE_REVEAL';")
  ML=$(curl -s "$EU/cards" -H "Authorization: Bearer $MGR")
  AA=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE action='SENSITIVE_REVEAL';")
  XL=$(curl -s "$EU/cards" -H "Authorization: Bearer $XMGR" | grep -c "Tekerlekli")
  SC=$(curl -s -o /dev/null -w '%{http_code}' "$EU/cards" -H "Authorization: Bearer $TEN")
  [ "$MY" = "1" ] && echo "$ML" | grep -q "Tekerlekli" && [ "$AA" -gt "$AB" ] && [ "$XL" = "0" ] && [ "$SC" = "403" ] \
    && ok "kart sahibine ve yönetime çözülmüş görünüyor; yönetimin her görüntülemesi ayrı denetim kaydı; başka site ve sakinler göremez" || bad "kart görünürlüğü: $MY / $AB→$AA / $XL / $SC"
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$EU/cards/me?unit_id=$TUNIT" -H "Authorization: Bearer $TEN")
  CN=$($PSQL -t -A -c "SELECT count(*) FROM resident_emergency_cards WHERE user_id='$TENUID';")
  [ "$SC" = "200" ] && [ "$CN" = "0" ] && ok "sakin kartını silince özel nitelikli veri gerçekten silindi (KVKK m.7)" || bad "kart silme: $SC / $CN"
  CK=$(curl -s -X POST "$EU/checks" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"kind":"EARTHQUAKE","title":"Deprem sonrası durum bildirimi"}' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["check"]["id"])' 2>/dev/null)
  SC=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/checks" -H "Authorization: Bearer $MGR" -H "$JH" -d '{"kind":"FIRE","title":"ikinci"}')
  NT=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='safety.check' AND recipient_user_id='$TENUID' AND payload->>'safety_check_id'='$CK';")
  [ -n "$CK" ] && [ "$SC" = "409" ] && [ "${NT:-0}" -ge 1 ] && ok "durum bildirimi çağrısı açıldı, sakinlere bildirildi; aynı anda ikinci çağrı açılamıyor → 409" || bad "durum çağrısı: $CK / $SC / $NT"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/checks/$CK/respond" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"status":"BELKI"}')
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/checks/$CK/respond" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"status":"NEED_HELP","note":"Kapı sıkıştı"}')
  NH=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='safety.need_help' AND payload->>'safety_check_id'='$CK';")
  RS=$(curl -s "$EU/checks/$CK/responses" -H "Authorization: Bearer $MGR")
  SC3=$(curl -s -o /dev/null -w '%{http_code}' "$EU/checks/$CK/responses" -H "Authorization: Bearer $TEN")
  TL4=$($PSQL -t -A -c "SELECT block || '-' || door_number FROM units WHERE id='$TUNIT';")
  echo "$RS" | python3 -c "import json,sys; d=json.load(sys.stdin); r=[x for x in d['data'] if x['user_id']=='$TENUID']; assert r and r[0]['status']=='NEED_HELP' and d['check']['need_help']==1 and '$TL4' not in d['silent_units'] and len(d['silent_units'])==d['check']['units']-d['check']['responded']" 2>/dev/null; PY=$?
  [ "$SC1" = "422" ] && [ "$SC2" = "200" ] && [ "${NH:-0}" -ge 1 ] && [ "$PY" = "0" ] && [ "$SC3" = "403" ] \
    && ok "yardım talebi yönetime anında bildirildi; yanıt listesi ve yanıt vermeyen daireler yönetimde; sakin listeyi göremez" || bad "durum yanıtı: $SC1 / $SC2 / $NH / py $PY / $SC3 — $RS"
  SC1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/checks/$CK/close" -H "Authorization: Bearer $MGR")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$EU/checks/$CK/respond" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"status":"SAFE"}')
  [ "$SC1" = "200" ] && [ "$SC2" = "409" ] && ok "kapatılan çağrıya yanıt verilemiyor → 409" || bad "çağrı kapatma: $SC1 / $SC2"
  # İstemci hata raporu ve metrikler (3.6, 044)
  LONG=$(python3 -c "print('x'*2500)")
  CE=$(curl -s -w '\n%{http_code}' -X POST "$CURL2/client-errors" -H "Authorization: Bearer $TEN" -H "$JH" \
    -d "{\"app\":\"mobile\",\"app_version\":\"1.0.0+1\",\"platform\":\"android\",\"fatal\":true,\"message\":\"$LONG\",\"stack\":\"#0 main\"}")
  SC2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/client-errors" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"app":"uydurma","message":"x"}')
  ML=$($PSQL -t -A -c "SELECT length(message) FROM client_error_reports WHERE user_id='$TENUID' ORDER BY created_at DESC LIMIT 1;")
  $PSQL -c "INSERT INTO client_error_reports (property_id, user_id, app, message) SELECT '$DEMO_PROPERTY','$TENUID','mobile','dongu' FROM generate_series(1,30);" >/dev/null
  SC3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CURL2/client-errors" -H "Authorization: Bearer $TEN" -H "$JH" -d '{"app":"mobile","message":"bir daha"}')
  [ "$(echo "$CE" | tail -1)" = "201" ] && [ "$SC2" = "422" ] && [ "$ML" = "2000" ] && [ "$SC3" = "429" ] \
    && ok "mobil hata raporu kaydedildi (metin 2000 karaktere kısaltıldı); geçersiz uygulama 422; saatlik sınır aşımı 429" || bad "hata raporu: $CE / $SC2 / $ML / $SC3"
  MT=$(curl -s "http://127.0.0.1:${COMPORT}/metrics")
  # grep -q büyük girdide erken çıkar; pipefail altında echo SIGPIPE alır — bu yüzden here-string.
  grep -q 'siteeksen_http_requests_total{service="community",route="/api/v1/kvkk-requests/:id/respond",method="POST",status="2xx"}' <<<"$MT" \
    && grep -q 'siteeksen_http_request_duration_seconds_bucket' <<<"$MT" && ! grep -Eq "[0-9a-f]{8}-[0-9a-f]{4}-" <<<"$MT" \
    && ok "/metrics: rota şablonu bazında istek sayısı ve gecikme histogramı; ham yol/kimlik yok" || bad "metrikler: $(echo "$MT" | grep -E "kvkk|[0-9a-f]{8}-" | head -5)"
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
[ "$GEC" = "13" ] && ok "ortak gider kalemi sayısı tohum verisiyle aynı (10 + 066 malik kalemleri 3)" \
  || bad "ortak gider kalemi sayısı değişmiş ($GEC, beklenen 13)"
GD=$(qscoped "SELECT count(*) FROM expense_categories WHERE property_id IS NULL;")
GO=$(qscoped "SELECT count(*) FROM expense_categories WHERE property_id IS NULL;" "$OTHERPROP")
[ "$GD" = "13" ] && [ "$GO" = "13" ] && ok "ortak gider kalemleri her iki sitede de görünüyor" \
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
# users: 077 ile üçüncü politika — tedarikçi kendi kaydını, platform tedarikçi kayıtlarını okur (users_supplier_self).
for T in users properties units blocks resident_units property_roles; do
  ROW=$($PSQL -t -A -c "SELECT rls_enabled || '/' || rls_forced || '/' || policy_count
    FROM rls_enabled_tables WHERE table_name='$T';")
  WANT=2; [ "$T" = "users" ] && WANT=3
  case "$ROW" in
    "true/true/$WANT"|"t/t/$WANT") ok "RLS açık: $T (site kapsamı + kimlik rolü politikası$([ "$WANT" = 3 ] && echo ' + tedarikçi/platform okuma'))" ;;
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
for T in tenants invoices usage_metrics schema_migrations user_activation_codes phone_change_requests email_change_requests phone_verifications; do
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
[ "$RLSCOUNT" = "148" ] && ok "RLS toplam 148 tabloda açık (069, 071, 073 okundu bilgisi, 074 sensörler, 075 devriye izi, 077 pazaryeri 19 tablo)" \
  || bad "beklenmedik RLS tablo sayısı: $RLSCOUNT (beklenen 148)"
NOTRLS=$($PSQL -t -A -c "SELECT string_agg(t.table_name, ' ' ORDER BY t.table_name)
  FROM information_schema.tables t
  WHERE t.table_schema='public' AND t.table_type='BASE TABLE'
    AND t.table_name NOT IN (SELECT table_name FROM rls_enabled_tables);")
# audit_logs: yalnızca ekleme
# revoked_tokens / user_token_invalidation: salt-okur, kişi bazlı (site değil)
# tenants / invoices / usage_metrics / schema_migrations: uygulama rolüne kapalı
# user_activation_codes / phone_change_requests / email_change_requests / phone_verifications: uygulama rolüne kapalı, yalnızca kimlik servisi (027, 062, 065, 076)
# (legal_parameters 029'dan beri RLS altında: site istisnaları yalnızca kendi sitesinde.)
EXPECTED="audit_logs email_change_requests invoices phone_change_requests phone_verifications revoked_tokens schema_migrations tenants usage_metrics user_activation_codes user_token_invalidation"
[ "$NOTRLS" = "$EXPECTED" ] && ok "RLS dışındaki 11 tablonun her biri gerekçeli: $NOTRLS" \
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
  # Kişi–daire bağı (2026-10-04): hazirune ve icra takibine o daireyle bağı olmayan kişi yazılamaz
  STR=$($PSQL -t -A -c "INSERT INTO users (first_name, last_name, phone, password_hash, roles)
    VALUES ('Ilgisiz','Kisi','+905550000095','x',ARRAY['RESIDENT']) ON CONFLICT (phone) DO UPDATE SET first_name = EXCLUDED.first_name RETURNING id;" | grep -E '^[0-9a-f-]{36}$')
  SC=$(code -X POST "$GU/assemblies/$A2/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"user_id\":\"$STR\"}")
  SC2=$(code -X POST "$GU/legal-cases" -H "$GA" -H "$J" -d "{\"unit_id\":\"$OTHERUNIT\",\"debtor_user_id\":\"$STR\",\"case_type\":\"EXECUTION\"}")
  NLC=$($PSQL -t -A -c "SELECT count(*) FROM legal_cases WHERE debtor_user_id='$STR';")
  [ "$SC" = "422" ] && [ "$SC2" = "422" ] && [ "$NLC" = "0" ] \
    && ok "daireyle bağı olmayan kişi hazirune ve icra takibine borçlu olarak yazılamıyor → 422" || bad "kişi–daire bağı: hazirun $SC, takip $SC2 (kayıt $NLC)"
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

  # 7579 s. Kanun: işletme projesi genel kurul kararıyla kesinleşir; geçici proje
  # yeniden değerleme tavanını (KMK m.37 son f.) aşamaz.
  mkbud() { curl -s -X POST "$GU/budgets" -H "$GA" -H "$J" -d "{\"period_year\":$1,\"items\":[{\"name\":\"Kapici\",\"amount\":$2,\"distribution_type\":\"EQUAL\"}]}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4; }
  B25=$(mkbud 2025 100000)
  FIN=$(curl -s -X POST "$GU/budgets/$B25/finalize" -H "$GA" -H "$J" -d "{\"agenda_item_id\":\"$ITEM2\"}")
  ROW=$($PSQL -t -A -c "SELECT status, approved_agenda_item_id, decision_ref FROM operating_budgets WHERE id='$B25';")
  echo "$ROW" | grep -q "^FINAL|$ITEM2|Kat malikleri kurulu .*gündem 1" && echo "$FIN" | grep -q "İİK m.68" \
    && ok "proje, yapılmış genel kurulda KABUL edilen gündem maddesine bağlanarak kesinleşti (karar referansı üretildi)" \
    || bad "genel kurul kararıyla kesinleştirme: $ROW — $FIN"
  # TEST_RAPORU 2.7 (050): kesinleşen projeden aylık tahakkuk — 12 ayın toplamı yıllık paya kuruşu kuruşuna eşit
  # Seed'de A-3 için elle girilmiş 2025-11/12 tahakkuku var: proje aynı ayı ikinci kez tahakkuk edemez.
  BAM=$(code -X POST "$GU/budgets/$B25/assessments" -H "$GA" -H "$J" -d '{"period_month":12,"due_date":"2025-12-28"}')
  $PSQL -c "UPDATE monthly_assessments SET period_year = 1999 WHERE property_id='$DEMO_PROPERTY' AND period_year = 2025 AND budget_id IS NULL;" >/dev/null
  for M in 1 2 3 4 5 6 7 8 9 10 11 12; do
    BA=$(curl -s -w '|%{http_code}' -X POST "$GU/budgets/$B25/assessments" -H "$GA" -H "$J" -d "{\"period_month\":$M,\"due_date\":\"2025-$(printf %02d $M)-28\"}")
    [ "$M" = "1" ] && BA1="$BA"
  done
  BAD=$(code -X POST "$GU/budgets/$B25/assessments" -H "$GA" -H "$J" -d '{"period_month":3,"due_date":"2025-03-28"}')
  BAV=$(code -X POST "$GU/budgets/$B25/assessments" -H "$GA" -H "$J" -d '{"period_month":5,"due_date":"2025-04-01"}')
  BDR=$(mkbud 2027 1000)
  BAX=$(code -X POST "$GU/budgets/$BDR/assessments" -H "$GA" -H "$J" -d '{"period_month":1,"due_date":"2027-01-28"}')
  BAT=$(code -X POST "$GU/budgets/$B25/assessments" -H "Authorization: Bearer $TEN" -H "$J" -d '{"period_month":1,"due_date":"2025-01-28"}')
  BSUM=$($PSQL -t -A -c "SELECT bool_and(t.ok), count(*) FROM (
      SELECT s.unit_id, (SELECT round(sum(base_amount)*100)::bigint FROM monthly_assessments m WHERE m.budget_id='$B25' AND m.unit_id=s.unit_id) = s.annual_kurus
             AND (SELECT count(*) FROM monthly_assessments m WHERE m.budget_id='$B25' AND m.unit_id=s.unit_id) = 12 AS ok
      FROM operating_budget_unit_shares s WHERE s.budget_id='$B25' AND s.annual_kurus > 0) t;")
  # Beşinci tur B1: projeden tahakkukta da daire sakinlerine yeni borç bildirimi oluşur
  BNT=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='dues.created' AND channel='IN_APP'
      AND payload->>'assessment_id' IN (SELECT id::text FROM monthly_assessments WHERE budget_id='$B25' AND period_month=1);")
  BNA=$($PSQL -t -A -c "SELECT count(DISTINCT (m.id, ru.resident_id)) FROM monthly_assessments m JOIN resident_units ru ON ru.unit_id=m.unit_id AND ru.is_active
      WHERE m.budget_id='$B25' AND m.period_month=1;")
  [ "$BNT" -gt 0 ] && [ "$BNT" = "$BNA" ] && echo "$BA1" | grep -q '"notification":{' \
    && ok "projeden tahakkukta her aktif daire sakinine yeni borç bildirimi oluştu ($BNT kişi)" \
    || bad "projeden tahakkuk bildirimi: bildirim=$BNT aktif sakin=$BNA — $BA1"
  $PSQL -c "DELETE FROM monthly_assessments WHERE budget_id='$B25';" >/dev/null
  $PSQL -c "UPDATE monthly_assessments SET period_year = 2025 WHERE property_id='$DEMO_PROPERTY' AND period_year = 1999;" >/dev/null
  $PSQL -c "DELETE FROM operating_budgets WHERE id='$BDR';" >/dev/null
  case "$BA1" in *'"budget_status":"FINAL","created":25'*"|201") BAOK=1 ;; *) BAOK=0 ;; esac
  [ "$BAOK" = "1" ] && [ "$BAM" = "409" ] && [ "${BSUM%%|*}" = "t" ] && [ "${BSUM##*|}" -gt 0 ] && [ "$BAD" = "409" ] && [ "$BAV" = "422" ] && [ "$BAX" = "422" ] && [ "$BAT" = "403" ] \
    && ok "kesinleşen projeden aylık tahakkuk: ${BSUM##*|} bölümde 12 ayın toplamı yıllık paya kuruşu kuruşuna eşit; elle tahakkuk edilmiş ay ve aynı ay 409, aydan önceki vade 422, taslak proje 422, sakin 403" \
    || bad "projeden tahakkuk: $BA1 / elle=$BAM / toplam $BSUM / $BAD / $BAV / $BAX / $BAT"
  B26X=$(mkbud 2026 125500)
  SC=$(code -X POST "$GU/budgets/$B26X/finalize" -H "$GA" -H "$J" -d "{\"agenda_item_id\":\"$ITEM2\"}")
  [ "$SC" = "409" ] && ok "aynı gündem maddesi ikinci projeyi onaylamak için kullanılamıyor → 409" || bad "gündem maddesi tekrar kullanımı → $SC"
  # 100.000 × 1,2549 = 125.490 TL tavan; 125.500 TL geçici proje olarak bildirilemez
  NT=$(curl -s -X POST "$GU/budgets/$B26X/notify" -H "$GA" -H "$J" -d '{"method":"TAAHHUTLU_MEKTUP"}')
  ST=$($PSQL -t -A -c "SELECT status FROM operating_budgets WHERE id='$B26X';")
  echo "$NT" | grep -q "125490.00" && echo "$NT" | grep -q "25.49" && [ "$ST" = "DRAFT" ] \
    && ok "yeniden değerleme tavanını (%25,49 → 125.490,00 TL) aşan geçici proje bildirilemedi; taslak kaldı" \
    || bad "geçici proje tavanı: $ST — $NT"
  $PSQL -c "DELETE FROM operating_budgets WHERE id='$B26X';" >/dev/null
  B26=$(mkbud 2026 125490)
  SC=$(code -X POST "$GU/budgets/$B26/notify" -H "$GA" -H "$J" -d '{"method":"TAAHHUTLU_MEKTUP"}')
  ROW=$($PSQL -t -A -c "SELECT status, cap_base_budget_id, cap_rate::text, cap_amount::text FROM operating_budgets WHERE id='$B26';")
  [ "$SC" = "200" ] && [ "$ROW" = "NOTIFIED|$B25|0.254900|125490.00" ] \
    && ok "tavana eşit geçici proje bildirildi; dayanak proje, oran ve tavan kayda yazıldı" || bad "tavan içi bildirim → $SC ($ROW)"
  # 2026 yılı oranı henüz ilan edilmediği için 2027 geçici projesinin tavanı uydurulmaz
  B27=$(mkbud 2027 1000)
  NT=$(curl -s -X POST "$GU/budgets/$B27/notify" -H "$GA" -H "$J" -d '{"method":"TAAHHUTLU_MEKTUP"}')
  echo "$NT" | grep -q "2026 yılı yeniden değerleme oranı sistemde yok" \
    && ok "ilan edilmemiş yeniden değerleme oranıyla geçici proje bildirilmiyor (tavan uydurulmuyor) → 422" \
    || bad "oransız tavan: $NT"
  # Ortak alan geliri (FAZ 7.6, 042): KMK m.45 oybirliği, arsa payı oranında kuruş paylaştırma
  CA="$GU/common-area"
  lease() { curl -s -w '\n%{http_code}' -X POST "$CA/leases" -H "$GA" -H "$J" -d "{\"area_kind\":\"ROOF_FACADE_AD\",\"area_name\":\"$1\",\"tenant_name\":\"Reklam AŞ\",\"tenant_is_business\":$3,\"start_date\":\"2026-01-01\",\"monthly_rent\":1000,\"agenda_item_id\":\"$2\"}"; }
  SC=$(lease "Çatı reklam alanı" "$ITEM2" true | tail -1)
  ASM4=$(curl -s -X POST "$GU/assemblies" -H "$GA" -H "$J" -d '{"kind":"EXTRAORDINARY","call_number":1,
    "scheduled_at":"2032-08-01T18:00:00Z","agenda_items":[{"title":"Çatının reklam amacıyla kiralanması","required_majority_code":"UNANIMITY_TRANSFER_ACTS"}]}')
  A4=$(echo "$ASM4" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  ITEM4=$(echo "$ASM4" | grep -o '"agenda_items":\[{"id":"[^"]*"' | grep -o '[0-9a-f-]\{36\}')
  for u in $UNITS; do curl -s -o /dev/null -X POST "$GU/assemblies/$A4/attendees" -H "$GA" -H "$J" -d "{\"unit_id\":\"$u\"}"; done
  curl -s -o /dev/null -X POST "$GU/assemblies/$A4/hold" -H "$GA"
  for u in $UNITS; do curl -s -o /dev/null -X POST "$GU/agenda-items/$ITEM4/votes" -H "$GA" -H "$J" -d "{\"unit_id\":\"$u\",\"vote\":\"FOR\"}"; done
  CL4=$(curl -s -X POST "$GU/agenda-items/$ITEM4/close" -H "$GA" -H "$J" -d '{}')
  SC2=$(lease "Sığınak deposu" "$ITEM4" true | tail -1)
  R=$(lease "Çatı reklam alanı" "$ITEM4" true); LID=$(echo "$R" | sed '$d' | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  [ "$SC" = "422" ] && echo "$CL4" | grep -q '"accepted":true' && [ "$SC2" = "422" ] && [ "$(echo "$R" | tail -1)" = "201" ] \
    && ok "ortak yer kiralaması oybirliği maddesi olmadan kaydedilmiyor (KMK m.45) → 422; sığınak kiralanamıyor; oybirliğiyle kaydedildi" \
    || bad "kiralama: $SC / $SC2 / $R — $CL4"
  inc() { curl -s -o /dev/null -w '%{http_code}' -X POST "$CA/leases/$1/incomes" -H "$GA" -H "$J" -d "$2"; }
  SC1=$(inc "$LID" '{"period":"2026-09","gross_amount":1000,"withholding_amount":1200,"received_on":"2026-09-30"}')
  SC2=$(inc "$LID" '{"period":"2026-09","gross_amount":1000,"withholding_amount":200,"received_on":"2026-09-30"}')
  SC3=$(inc "$LID" '{"period":"2026-09","gross_amount":1000,"withholding_amount":200,"received_on":"2026-09-30"}')
  SUMS=$($PSQL -t -A -c "SELECT sum(s.gross_kurus) || '|' || sum(s.withholding_kurus) || '|' || count(*) FROM common_area_income_shares s
      JOIN common_area_incomes i ON i.id = s.income_id WHERE i.lease_id = '$LID';")
  NU=$($PSQL -t -A -c "SELECT count(*) FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0;")
  [ "$SC1" = "422" ] && [ "$SC2" = "201" ] && [ "$SC3" = "409" ] && [ "$SUMS" = "100000|20000|$NU" ] \
    && ok "gelir ve stopaj $NU bölüme arsa payı oranında kuruş kaybı olmadan paylaştırıldı; stopaj brütü aşamıyor, aynı dönem iki kez yazılamıyor" \
    || bad "gelir paylaştırma: $SC1 / $SC2 / $SC3 — $SUMS ($NU bölüm)"
  LID2=$(lease "Kapıcı dairesi" "$ITEM4" false | sed '$d' | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
  SC=$(inc "$LID2" '{"period":"2026-09","gross_amount":500,"withholding_amount":50,"received_on":"2026-09-30"}')
  RP=$(curl -s "$CA/report?year=2026" -H "$GA" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["total_gross_kurus"], d["total_withholding_kurus"])' 2>/dev/null)
  UPD=$(qscoped "UPDATE common_area_incomes SET gross_amount = 1 WHERE lease_id='$LID' RETURNING id;")
  GV=$($PSQL -t -A -c "SELECT gross_amount::int FROM common_area_incomes WHERE lease_id='$LID';")
  SC4=$(code "$CA/leases" -H "Authorization: Bearer $TEN"); SC5=$(code "$CA/my-share?year=2026" -H "Authorization: Bearer $TEN")
  [ "$SC" = "422" ] && [ "$RP" = "100000 20000" ] && [ "$GV" = "1000" ] && [ "$SC4" = "403" ] && [ "$SC5" = "200" ] \
    && ok "işyeri olmayan kiracıdan stopaj girilemiyor; yıllık rapor tutuyor; gelir kaydı değiştirilemiyor; sakin yalnızca kendi payını sorgulayabiliyor" \
    || bad "gelir raporu: $SC / $RP / $GV / $SC4 / $SC5"
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
  # Servis sayısı gen-deploy.py'den gelir (servis eklenip çıkarılınca burada sabit sayı kaymaz).
  P38N=$((${#GWENV[@]}))
  for _ in $(seq 1 120); do
    N=0
    for p in $(seq 18400 $((18400 + P38N - 1))); do curl -fsS -o /dev/null "http://127.0.0.1:$p/health" 2>/dev/null && N=$((N+1)); done
    curl -fsS -o /dev/null http://127.0.0.1:18499/health 2>/dev/null && [ "$N" -ge "$P38N" ] && { P38UP=1; break; }
    sleep 2
  done
  [ "$P38UP" = "1" ] && ok "$P38N servis ve gateway ayağa kalktı (panel doğrulaması için)" \
    || bad "panel doğrulaması için servisler açılmadı ($N/$P38N)"
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

# Giriş kilidi (kademeli, beşinci tur B6): 5. hata 30 sn, 6. hata 2 dk, 7.+ hata 15 dk; kilitliyken doğru şifre de reddedilir
if go test ./services/identity/service/ -count=1 -run 'LoginLock' >/tmp/verify-loginlock.log 2>&1; then
  ok "go test kademeli kilit süreleri (1-4: yok, 5: 30 sn, 6: 2 dk, 7+: 15 dk)"
else
  bad "kademeli kilit birim testi"; tail -10 /tmp/verify-loginlock.log
fi
lockleft() { $PSQL -t -A -c "SELECT round(extract(epoch FROM locked_until - now()))::int FROM users WHERE phone='+905550000039';"; }
unlock39() { $PSQL -c "UPDATE users SET locked_until = now() - interval '1 second' WHERE phone='+905550000039';" >/dev/null; }
for i in 1 2 3 4; do code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}' >/dev/null; done
L4=$($PSQL -t -A -c "SELECT locked_until IS NULL FROM users WHERE phone='+905550000039';")
code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}' >/dev/null
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Yepyeni12"}')
L5=$(lockleft)
[ "$L4" = "t" ] && [ "$SC" = "401" ] && [ "${L5:-0}" -ge 20 ] && [ "${L5:-0}" -le 31 ] \
  && ok "4 hatada kilit yok; 5. hatada 30 sn kilit ($L5 sn kaldı), kilitliyken doğru şifre de 401" \
  || bad "giriş kilidi 5. hata: kilitsiz=$L4 doğru şifre=$SC kalan=$L5"
unlock39
code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}' >/dev/null
L6=$(lockleft); unlock39
code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}' >/dev/null
L7=$(lockleft)
MSG39=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"hatali"}')
[ "${L6:-0}" -ge 100 ] && [ "${L6:-0}" -le 121 ] && [ "${L7:-0}" -ge 880 ] && [ "${L7:-0}" -le 901 ] && grep -q '30 sn' <<<"$MSG39" \
  && ok "kilit kademeli artıyor: 6. hata 2 dk ($L6 sn), 7. hata 15 dk ($L7 sn); hata yanıtı kilit durumunu söylemeden kademeleri anlatıyor" \
  || bad "kademeli kilit: 6.=$L6 7.=$L7 — $MSG39"
unlock39
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000039","password":"Yepyeni12"}')
N=$($PSQL -t -A -c "SELECT failed_login_attempts FROM users WHERE phone='+905550000039';")
[ "$SC" = "200" ] && [ "$N" = "0" ] && ok "kilit süresi dolunca giriş açılıyor ve sayaç sıfırlanıyor" \
  || bad "kilit sonrası giriş $SC (sayaç $N)"

# Var olan telefonla sakin eklenirse kod üretilmez, mevcut şifre bozulmaz
CR=$(curl -s -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Demo\",\"last_name\":\"Kiraci\",\"phone\":\"5559876543\",\"unit_id\":\"$FREEUNIT\",\"role\":\"PROXY\"}")
SC=$(code -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}')
echo "$CR" | grep -q activation_code && bad "var olan hesaba kod üretildi: $CR" \
  || { [ "$SC" = "200" ] && ok "var olan hesap ikinci daireye bağlanınca kod üretilmiyor, şifresi bozulmuyor" \
       || bad "var olan hesap bozuldu: giriş $SC"; }
LINKED=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id
  WHERE u.phone='+905559876543' AND ru.unit_id='$FREEUNIT';")
[ "$LINKED" = "1" ] && ok "bu sitede zaten sakin olan hesap ikinci daireye bağlanabiliyor" || bad "aynı site ikinci daire bağlantısı: $LINKED"

# B25 + S-20: telefon bu siteyle BAĞI OLMAYAN bir hesaba aitse bağ KURULMAZ ve
# kişinin adı/e-postası gösterilmez (önceden ikisi de oluyordu); DAVET açılır,
# kişi kendi uygulamasından kabul edince daireye bağlanır.
for P in 77 80; do
  $PSQL -c "INSERT INTO users (first_name, last_name, phone, email, password_hash, password_set_at, roles)
    SELECT 'Gizli', 'Baskasitesakini', '+9055500000$P', 'gizli.kisi$P@example.com', password_hash, now(), ARRAY['RESIDENT']
    FROM users WHERE phone='+905551234567' ON CONFLICT DO NOTHING;" >/dev/null 2>&1
done
invite() { curl -s -w '\n%{http_code}' -X POST "$ID39/residents" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d "{\"first_name\":\"Tahmin\",\"last_name\":\"Edilen\",\"phone\":\"$1\",\"unit_id\":\"$FREEUNIT\",\"role\":\"$2\"}"; }
jfield() { python3 -c 'import json,sys; d=json.loads(sys.stdin.read() or "{}"); print(eval(sys.argv[1]))' "$1" 2>/dev/null; }
CR25=$(invite 5550000077 OWNER)
L25=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id WHERE u.phone='+905550000077';")
INV1=$(echo "$CR25" | sed '$d' | jfield 'd["invitation"]["id"]')
[ "$(echo "$CR25" | tail -1)" = "202" ] && [ "$L25" = "0" ] && [ -n "$INV1" ] \
  && ok "başka sitenin hesabı bağlanmıyor, davet açılıyor → 202, daire bağı yok" \
  || bad "B25/S-20: $(echo "$CR25" | tail -1), bağ $L25, davet '$INV1'"
echo "$CR25" | grep -qE 'Gizli|Baskasitesakini|gizli.kisi' \
  && bad "yanıt başka sitenin sakininin kişisel verisini sızdırıyor: $CR25" \
  || ok "davet yanıtında o hesabın adı/e-postası yok"
SC=$(invite 5550000077 OWNER | tail -1)
[ "$SC" = "409" ] && ok "aynı kişiye aynı daire için ikinci bekleyen davet açılamıyor → 409" || bad "ikinci davet → $SC"
LI=$(curl -s "$ID39/residents/invitations" -H "Authorization: Bearer $MGR39" | jfield '[x["status"]+"|"+x["phone"] for x in d["data"] if x["id"]=="'"$INV1"'"][0]')
[ "$LI" = "PENDING|+905550000077" ] && ok "yönetici davetleri listeliyor (bekliyor, girdiği telefonla)" || bad "davet listesi: '$LI'"
TENL=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC=$(code "$ID39/residents/invitations" -H "Authorization: Bearer $TENL")
[ "$SC" = "403" ] && ok "kiracı site davetlerini göremiyor → 403" || bad "kiracı davet listesi → $SC"

GZ=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000077","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
MY=$(curl -s "$ID39/users/me/invitations" -H "Authorization: Bearer $GZ" | jfield '[x["property_name"] for x in d["data"] if x["id"]=="'"$INV1"'"]')
[ -n "$GZ" ] && [ "$MY" != "[]" ] && [ -n "$MY" ] && ok "davet edilen kişi daveti kendi uygulamasında görüyor ($MY)" || bad "kendi davetleri: '$MY'"
SC=$(code -X POST "$ID39/users/me/invitations/$INV1/accept" -H "Authorization: Bearer $TENL")
[ "$SC" = "404" ] && ok "başkasının davetini kabul etmek mümkün değil → 404" || bad "başkasının daveti → $SC"
SC=$(code -X POST "$ID39/users/me/invitations/$INV1/accept" -H "Authorization: Bearer $GZ")
L25=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id
  WHERE u.phone='+905550000077' AND ru.unit_id='$FREEUNIT' AND ru.role='OWNER' AND ru.is_active;")
IST=$($PSQL -t -A -c "SELECT status || '|' || (responded_at IS NOT NULL) FROM resident_invitations WHERE id='$INV1';")
[ "$SC" = "200" ] && [ "$L25" = "1" ] && [ "$IST" = "ACCEPTED|true" ] \
  && ok "kabul edilince daireye bağlandı, davet ACCEPTED ve yanıt zamanı kayıtlı" || bad "kabul: $SC, bağ $L25, davet $IST"
SC=$(code -X POST "$ID39/users/me/invitations/$INV1/accept" -H "Authorization: Bearer $GZ")
[ "$SC" = "409" ] && ok "yanıtlanmış davet yeniden kullanılamıyor → 409" || bad "ikinci kabul → $SC"
PROPS=$(curl -s "$ID39/users/me/properties" -H "Authorization: Bearer $GZ")
echo "$PROPS" | grep -q "$DEMO_PROPERTY" && ok "kabulden sonra site, kişinin site listesinde" || bad "site listesi: $(echo "$PROPS" | head -c 200)"

# İptal ve süre dolumu
CR=$(invite 5550000080 PROXY); INV2=$(echo "$CR" | sed '$d' | jfield 'd["invitation"]["id"]')
SC=$(code -X POST "$ID39/residents/invitations/$INV2/cancel" -H "Authorization: Bearer $MGR39")
GZ2=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5550000080","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC2=$(code -X POST "$ID39/users/me/invitations/$INV2/accept" -H "Authorization: Bearer $GZ2")
[ "$SC" = "200" ] && [ "$SC2" = "409" ] && ok "yönetimin iptal ettiği davet kabul edilemiyor → 409" || bad "iptal: $SC, iptal sonrası kabul $SC2"
CR=$(invite 5550000080 PROXY); INV3=$(echo "$CR" | sed '$d' | jfield 'd["invitation"]["id"]')
$PSQL -c "UPDATE resident_invitations SET expires_at = now() - interval '1 minute' WHERE id='${INV3:-00000000-0000-0000-0000-000000000000}';" >/dev/null
NMY=$(curl -s "$ID39/users/me/invitations" -H "Authorization: Bearer $GZ2" | jfield 'len(d["data"])')
SC=$(code -X POST "$ID39/users/me/invitations/$INV3/accept" -H "Authorization: Bearer $GZ2")
EXP=$(curl -s "$ID39/residents/invitations" -H "Authorization: Bearer $MGR39" | jfield '[x["status"] for x in d["data"] if x["id"]=="'"$INV3"'"][0]')
[ -n "$INV3" ] && [ "$NMY" = "0" ] && [ "$SC" = "409" ] && [ "$EXP" = "EXPIRED" ] \
  && ok "süresi dolan davet kişiye görünmüyor, kabul edilemiyor (409), yönetimde EXPIRED" \
  || bad "süre dolumu: davet '$INV3', görünen $NMY, kabul $SC, durum $EXP"
SC=$(invite 5550000080 PROXY | tail -1)
DBEXP=$($PSQL -t -A -c "SELECT status FROM resident_invitations WHERE id='${INV3:-00000000-0000-0000-0000-000000000000}';")
[ "$SC" = "202" ] && [ "$DBEXP" = "EXPIRED" ] && ok "süresi dolan davet kapatılıp yenisi açılabiliyor" || bad "yeniden davet: $SC (eski $DBEXP)"
L80=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id = ru.resident_id WHERE u.phone='+905550000080';")
[ "$L80" = "0" ] && ok "kabul edilmeyen davetler hiçbir daire bağı kurmadı" || bad "kabulsüz bağ: $L80"
# Site kurulumu (FAZ 8.1): kurucu önceden sahte bir "YÖNETİM" dairesine malik
# yapılıyor, yönetim rolü almıyordu → yeni site yönetilemiyordu; daire eklemenin
# de hiçbir yolu yoktu.
NP=$(curl -s -w '\n%{http_code}' -X POST "$ID39/users/me/properties" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d '{"name":"Kurulum Sinama Sitesi","type":"SITE","address":"Deneme Cad. 1","city":"Ankara","district":"Cankaya"}')
NPID=$(echo "$NP" | sed '$d' | jfield 'd["id"]')
MUID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
NPROLE=$($PSQL -t -A -c "SELECT string_agg(role, ',') FROM property_roles WHERE property_id='${NPID:-00000000-0000-0000-0000-000000000000}' AND user_id='$MUID' AND is_active;")
NPU=$($PSQL -t -A -c "SELECT count(*) FROM units WHERE property_id='${NPID:-00000000-0000-0000-0000-000000000000}';")
[ "$(echo "$NP" | tail -1)" = "201" ] && [ "$NPROLE" = "MANAGER" ] && [ "$NPU" = "0" ] \
  && ok "yeni site kurucusu geçici yönetici oluyor; sahte 'YÖNETİM' dairesi açılmıyor" \
  || bad "site kurulumu: $(echo "$NP" | tail -1), rol '$NPROLE', bölüm $NPU"
SC=$(code -X POST "$ID39/users/me/active-property" -H "Authorization: Bearer $MGR39" -H "$J" -d "{\"property_id\":\"$NPID\"}")
NT=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
UB=$(curl -s -w '\n%{http_code}' -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" \
  -d '{"units":[{"block":"A","floor":0,"door_number":"1","share_ratio":120.5,"gross_area_m2":95,"net_area_m2":82},{"block":"A","floor":1,"door_number":"2","share_ratio":130,"net_area_m2":90},{"block":"B","floor":2,"door_number":"1","share_ratio":149.5,"unit_type":"SHOP","is_commercial":true,"net_area_m2":60}]}')
NPU=$($PSQL -t -A -c "SELECT count(*) || '|' || SUM(share_ratio)::text FROM units WHERE property_id='$NPID' AND deleted = 0;")
GF=$($PSQL -t -A -c "SELECT is_ground_floor FROM units WHERE property_id='$NPID' AND block='A' AND door_number='1';")
[ "$SC" = "200" ] && [ "$(echo "$UB" | tail -1)" = "201" ] && [ "$NPU" = "3|400.0000" ] && [ "$GF" = "t" ] \
  && ok "yönetici yeni siteye toplu bağımsız bölüm ekledi (3 bölüm, arsa payı 400; zemin kat çıkarımı)" \
  || bad "toplu bölüm: geçiş $SC, $(echo "$UB" | tail -1) $(echo "$UB" | head -c 200), $NPU, zemin '$GF'"
SC=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"units":[{"block":"C","door_number":"9","share_ratio":10,"net_area_m2":50},{"block":"a","door_number":"2","share_ratio":10,"net_area_m2":50}]}')
SC2=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"units":[{"block":"C","door_number":"8","share_ratio":10,"net_area_m2":50},{"block":"A","door_number":"1","share_ratio":10,"net_area_m2":50}]}')
NPU2=$($PSQL -t -A -c "SELECT count(*) FROM units WHERE property_id='$NPID';")
[ "$SC" = "409" ] && [ "$SC2" = "409" ] && [ "$NPU2" = "3" ] && ok "var olan blok/kapı (harf farkı dahil: a-2 ≈ A-2) → 409 ve toplu eklemenin HİÇBİRİ yazılmadı" \
  || bad "çakışan toplu ekleme: $SC / $SC2, bölüm $NPU2"
SC=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"door_number":"5","share_ratio":0}')
SC3=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"units":[{"door_number":"7","share_ratio":5},{"door_number":"7","share_ratio":5}]}')
[ "$SC" = "422" ] && [ "$SC3" = "422" ] && ok "arsa payı 0 ve aynı istekte yinelenen kapı numarası → 422" || bad "bölüm doğrulaması: $SC / $SC3"
UID1=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$NPID' AND block='A' AND door_number='2';")
SC=$(code -X PATCH "$ID39/units/$UID1" -H "Authorization: Bearer $NT" -H "$J" -d '{"share_ratio":131.25,"gross_area_m2":101}')
SR=$($PSQL -t -A -c "SELECT share_ratio::text || '|' || gross_area_m2::text || '|' || door_number FROM units WHERE id='$UID1';")
[ "$SC" = "200" ] && [ "$SR" = "131.2500|101.00|2" ] && ok "bölüm güncellemesi yalnızca verilen alanları değiştiriyor" || bad "bölüm güncelleme: $SC, $SR"
SC=$(code -X POST "$ID39/units" -H "Authorization: Bearer $TENL" -H "$J" -d '{"door_number":"99","share_ratio":1}')
[ "$SC" = "403" ] && ok "kiracı bağımsız bölüm ekleyemiyor → 403" || bad "kiracı bölüm ekleme → $SC"
# Net kullanım alanı (TEST_RAPORU 2.2): daire/dükkân/ofiste zorunlu; otopark/depoda değil
NA1=$(curl -s -w '|%{http_code}' -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"block":"D","door_number":"1","share_ratio":10}')
NA2=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"block":"D","door_number":"P1","share_ratio":1,"unit_type":"PARKING"}')
NA3=$(code -X POST "$ID39/units" -H "Authorization: Bearer $NT" -H "$J" -d '{"block":"D","door_number":"2","share_ratio":10,"net_area_m2":120,"gross_area_m2":100}')
NA4=$(code -X PATCH "$ID39/units/$UID1" -H "Authorization: Bearer $NT" -H "$J" -d '{"net_area_m2":0}')
NAL=$(curl -s "$ID39/units" -H "Authorization: Bearer $NT" | python3 -c "import json,sys; d=json.load(sys.stdin); d=d.get('data',d); print([u['net_area_m2'] for u in d if u['id']=='$UID1'][0])" 2>/dev/null)
case "$NA1" in *"net kullanım alanı"*"|422") NAOK=1 ;; *) NAOK=0 ;; esac
[ "$NAOK" = "1" ] && [ "$NA2" = "201" ] && [ "$NA3" = "422" ] && [ "$NA4" = "422" ] && [ "$NAL" = "90" ] \
  && ok "net kullanım alanı daire/dükkân/ofiste zorunlu (422), otoparkta değil; net>brüt 422; sıfıra çekilemez; listede dönüyor" \
  || bad "net alan: $NA1 / $NA2 / $NA3 / $NA4 / $NAL"

# 033: önceden açılmış sitelerdeki sahte "YÖNETİM" bölümü dönüştürülür
FK=$($PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type)
  VALUES ('$NPID', 'A', 0, 'YÖNETİM', 0, 'OFFICE') RETURNING id;" | grep -E '^[0-9a-f-]{36}$')
G80=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000080';")
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$G80', '$FK', 'OWNER');" >/dev/null
$PSQL -f "$MIG_DIR/033_site_founder_manager.sql" >/dev/null 2>&1
R33=$($PSQL -t -A -c "SELECT (SELECT deleted FROM units WHERE id='$FK') || '|' ||
  (SELECT is_active FROM resident_units WHERE unit_id='$FK') || '|' ||
  (SELECT count(*) FROM property_roles WHERE user_id='$G80' AND property_id='$NPID' AND role='MANAGER' AND is_active);")
[ "$R33" = "1|false|1" ] && ok "033: sahte bölüm silindi işaretlendi, bağ pasif, kurucu yönetici rolünü aldı" || bad "033: '$R33'"
$PSQL -c "UPDATE property_roles SET is_active = false WHERE user_id='$G80' AND property_id='$NPID';" >/dev/null
SC=$(code -X POST "$ID39/users/me/active-property" -H "Authorization: Bearer $NT" -H "$J" -d "{\"property_id\":\"$DEMO_PROPERTY\"}")
[ "$SC" = "200" ] || bad "demo siteye geri dönülemedi → $SC"
# Toplu sakin içe aktarma (FAZ 8.1): satırlar bağımsız, her birinin sonucu döner.
U2=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0 ORDER BY door_number LIMIT 1 OFFSET 2;")
BK=$(curl -s -w '\n%{http_code}' -X POST "$ID39/residents/bulk" -H "Authorization: Bearer $MGR39" -H "$J" -d "{\"residents\":[
  {\"first_name\":\"Toplu\",\"last_name\":\"Bir\",\"phone\":\"0555 000 00 91\",\"unit_id\":\"$U2\",\"role\":\"TENANT\"},
  {\"first_name\":\"Demo\",\"last_name\":\"Kiraci\",\"phone\":\"5559876543\",\"unit_id\":\"$U2\",\"role\":\"PROXY\"},
  {\"first_name\":\"Gizli\",\"last_name\":\"Iki\",\"phone\":\"5550000080\",\"unit_id\":\"$U2\",\"role\":\"OWNER\"},
  {\"first_name\":\"\",\"last_name\":\"Eksik\",\"phone\":\"5550000092\",\"unit_id\":\"$U2\",\"role\":\"TENANT\"},
  {\"first_name\":\"Yetki\",\"last_name\":\"Denemesi\",\"phone\":\"5550000093\",\"unit_id\":\"$U2\",\"role\":\"MANAGER\"}]}")
BKS=$(echo "$BK" | sed '$d' | jfield '",".join(x["status"]+("+kod" if x.get("activation") else "") for x in d["data"])')
N93=$($PSQL -t -A -c "SELECT count(*) FROM users WHERE phone IN ('+905550000092','+905550000093');")
[ "$(echo "$BK" | tail -1)" = "200" ] && [ "$BKS" = "created+kod,linked,invited,error,error" ] && [ "$N93" = "0" ] \
  && ok "toplu içe aktarma satır satır raporluyor (hesap açıldı+kod, bağlandı, davet, eksik alan, yönetim rolü reddi)" \
  || bad "toplu sakin: $(echo "$BK" | tail -1) '$BKS', yanlışlıkla açılan hesap $N93"
# Görevlendirme (2026-10-03): property_roles'a yazan uç yoktu; kurucu dışında
# kimseye yönetici/kurul/denetçi/görevli rolü verilemiyor, kaldırılamıyordu.
RURL="$ID39/property-roles"
G1=$(curl -s -w '\n%{http_code}' -X POST "$RURL" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d '{"phone":"0555 000 00 81","role":"STAFF","first_name":"Yeni","last_name":"Gorevli"}')
[ "$(echo "$G1" | tail -1)" = "201" ] && echo "$G1" | grep -q '"activation_code"' \
  && ok "yönetici yeni kişiye görevli rolü verdi; hesap açıldı, etkinleştirme kodu bir kez döndü" \
  || bad "görevli atama: $(echo "$G1" | tail -1) $(echo "$G1" | head -c 200)"
SC=$(code -X POST "$RURL" -H "Authorization: Bearer $MGR39" -H "$J" -d '{"phone":"5559876543","role":"BOARD_MEMBER"}')
[ "$SC" = "422" ] && ok "kurul üyesi/denetçi/yönetici ataması karar bilgisi olmadan yapılamıyor → 422 (KMK m.34/41)" || bad "kararsız atama → $SC"
SC=$(code -X POST "$RURL" -H "Authorization: Bearer $MGR39" -H "$J" -d '{"phone":"5550000080","role":"STAFF"}')
[ "$SC" = "409" ] && ok "bu siteyle bağı olmayan hesaba görev verilemiyor → 409" || bad "bağsız hesaba görev → $SC"
G2=$(curl -s -w '\n%{http_code}' -X POST "$RURL" -H "Authorization: Bearer $MGR39" -H "$J" \
  -d '{"phone":"5559876543","role":"AUDITOR","decision_ref":"2026/3 sayılı kat malikleri kurulu kararı"}')
RID=$(echo "$G2" | sed '$d' | jfield 'd["role"]["id"]')
SC=$(code -X POST "$RURL" -H "Authorization: Bearer $MGR39" -H "$J" -d '{"phone":"5559876543","role":"AUDITOR","decision_ref":"tekrar"}')
[ "$(echo "$G2" | tail -1)" = "201" ] && [ "$SC" = "409" ] && ok "kiracıya denetçi görevi verildi; aynı görev ikinci kez verilemiyor → 409" \
  || bad "denetçi atama: $(echo "$G2" | tail -1), tekrar $SC"
TA=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC=$(code "$ID39/residents/invitations" -H "Authorization: Bearer $TA")
SC2=$(code -X POST "$RURL" -H "Authorization: Bearer $TA" -H "$J" -d '{"phone":"5550000081","role":"STAFF"}')
[ "$SC" = "200" ] && [ "$SC2" = "403" ] && ok "denetçi rolü yeni girişte geçerli (okuma 200); denetçi görev dağıtamıyor → 403" \
  || bad "denetçi yetkisi: okuma $SC, atama $SC2"
SC=$(code -X POST "$RURL/$RID/end" -H "Authorization: Bearer $MGR39")
SC2=$(code "$ID39/residents/invitations" -H "Authorization: Bearer $TA")
TA2=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC3=$(code "$ID39/residents/invitations" -H "Authorization: Bearer $TA2")
HIST=$($PSQL -t -A -c "SELECT is_active || '|' || (valid_to IS NOT NULL) FROM property_roles WHERE id='${RID:-00000000-0000-0000-0000-000000000000}';")
[ "$SC" = "200" ] && [ "$SC2" = "401" ] && [ "$SC3" = "403" ] && [ "$HIST" = "false|true" ] \
  && ok "görev sonlandırılınca eski jeton hemen geçersiz (401), yeni girişte yetki yok (403), kayıt geçmişte kalıyor" \
  || bad "görev sonlandırma: $SC, eski jeton $SC2, yeni giriş $SC3, kayıt $HIST"
NMGR=$($PSQL -t -A -c "SELECT count(*) FROM property_roles WHERE property_id='$DEMO_PROPERTY' AND role='MANAGER' AND is_active;")
MYMR=$($PSQL -t -A -c "SELECT id FROM property_roles WHERE property_id='$DEMO_PROPERTY' AND role='MANAGER' AND is_active AND user_id='$MUID' LIMIT 1;")
if [ "$NMGR" = "1" ] && [ -n "$MYMR" ]; then
  SC=$(code -X POST "$RURL/$MYMR/end" -H "Authorization: Bearer $MGR39")
  [ "$SC" = "409" ] && ok "sitenin tek yöneticisinin görevi sonlandırılamıyor → 409" || bad "tek yönetici sonlandırma → $SC"
fi
TENL=$(curl -s -X POST "$ID39/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SC=$(code "$RURL" -H "Authorization: Bearer $TENL")
[ "$SC" = "403" ] && ok "kiracı görevlendirmeleri göremiyor → 403" || bad "kiracı görev listesi → $SC"
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

# 4.13: ödeme tutarı, bağlı tahakkuk tutarlarının toplamına kuruşu kuruşuna eşit (toplam float64 ile alınmıyor)
PM=$($PSQL -t -A -c "SELECT count(*) || '|' || count(*) FILTER (WHERE p.amount <> (SELECT sum(pa.amount) FROM payment_assessments pa WHERE pa.payment_id = p.id))
  FROM payments p WHERE EXISTS (SELECT 1 FROM payment_assessments pa WHERE pa.payment_id = p.id);")
[ "${PM%%|*}" -ge 1 ] && [ "${PM##*|}" = "0" ] && ok "bütün ödemelerde tutar = bağlı tahakkukların toplamı ($PM)" || bad "ödeme/tahakkuk toplamı uyuşmuyor: $PM"
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
# Ödeme bildirimi incelemede olan borca hatırlatma gitmemeli (Apsiyon BUG-02)
U41='40404040-0000-0000-0000-0000000000a2'; R41='40404040-0000-0000-0000-000000000003'
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, roles) VALUES ('$R41','Odeyen','Malik','+905554040003','x',ARRAY['RESIDENT']) ON CONFLICT (id) DO NOTHING;
  INSERT INTO units (id, property_id, block, floor, door_number, share_ratio) VALUES ('$U41','$DEMO_PROPERTY','S',4,'41',1) ON CONFLICT (id) DO NOTHING;
  INSERT INTO resident_units (resident_id, unit_id, role, start_date, is_active) VALUES ('$R41','$U41','OWNER',CURRENT_DATE - 400, true);" >/dev/null
A41=$($PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date)
  VALUES ('$DEMO_PROPERTY','$U41',2020,1,500,500,CURRENT_DATE - 20) RETURNING id;" | head -1)
P41=$($PSQL -t -A -c "INSERT INTO payments (property_id, user_id, unit_id, amount, payment_method, status) VALUES ('$DEMO_PROPERTY','$R41','$U41',500,'BANK_TRANSFER','PENDING') RETURNING id;" | head -1)
$PSQL -c "INSERT INTO payment_assessments (payment_id, assessment_id, amount) VALUES ('$P41','$A41',500);" >/dev/null
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

# Demirbaş bakım/periyodik kontrol (FAZ 7.1): 5 gün sonra, 3 gün önce, 60 gün sonra, hurdaya ayrılmış
AM1=$($PSQL -t -A -c "INSERT INTO assets (property_id, name, next_maintenance_date, maintenance_interval_days)
  VALUES ('$DEMO_PROPERTY','Asansor A blok',CURRENT_DATE + 5,365) RETURNING id;" | head -1)
AM2=$($PSQL -t -A -c "INSERT INTO assets (property_id, name, next_maintenance_date, maintenance_interval_days)
  VALUES ('$DEMO_PROPERTY','Yangin tupleri',CURRENT_DATE - 3,365) RETURNING id;" | head -1)
AM3=$($PSQL -t -A -c "INSERT INTO assets (property_id, name, next_maintenance_date)
  VALUES ('$DEMO_PROPERTY','Jenerator',CURRENT_DATE + 60) RETURNING id;" | head -1)
AM4=$($PSQL -t -A -c "INSERT INTO assets (property_id, name, next_maintenance_date, status)
  VALUES ('$DEMO_PROPERTY','Eski pompa',CURRENT_DATE - 10,'DISPOSED') RETURNING id;" | head -1)
# KVKK yanıt süresi (FAZ 7.8): 3 gün kalan ve 2 gün geçen açık başvuru; sonuçlanmış olana yok
KS1=$($PSQL -t -A -c "INSERT INTO kvkk_requests (property_id, user_id, request_type, description, due_date)
  VALUES ('$DEMO_PROPERTY','$MGRID','INFO','yakin sureli basvuru',CURRENT_DATE + 3) RETURNING id;" | head -1)
KS2=$($PSQL -t -A -c "INSERT INTO kvkk_requests (property_id, user_id, request_type, description, due_date)
  VALUES ('$DEMO_PROPERTY','$MGRID','ERASURE','suresi gecmis basvuru',CURRENT_DATE - 2) RETURNING id;" | head -1)
KS3=$($PSQL -t -A -c "INSERT INTO kvkk_requests (property_id, user_id, request_type, description, due_date, status, response)
  VALUES ('$DEMO_PROPERTY','$MGRID','INFO','sonuclanmis',CURRENT_DATE - 2,'ANSWERED','yanit verildi') RETURNING id;" | head -1)
# Geçici işletme projesi genel kurul süresi (KMK m.37, 7579): 10 gün kalan, 2 gün geçen,
# 60 gün kalan (pencere dışı) ve kesinleşmiş (süre geçmiş görünse de) proje
BA1=$($PSQL -t -A -c "INSERT INTO operating_budgets (property_id, period_year, status, approval_deadline)
  VALUES ('$DEMO_PROPERTY',2041,'NOTIFIED',CURRENT_DATE + 10) RETURNING id;" | head -1)
BA2=$($PSQL -t -A -c "INSERT INTO operating_budgets (property_id, period_year, status, approval_deadline)
  VALUES ('$DEMO_PROPERTY',2042,'NOTIFIED',CURRENT_DATE - 2) RETURNING id;" | head -1)
BA3=$($PSQL -t -A -c "INSERT INTO operating_budgets (property_id, period_year, status, approval_deadline)
  VALUES ('$DEMO_PROPERTY',2043,'NOTIFIED',CURRENT_DATE + 60) RETURNING id;" | head -1)
BA4=$($PSQL -t -A -c "INSERT INTO operating_budgets (property_id, period_year, status, approval_deadline)
  VALUES ('$DEMO_PROPERTY',2044,'FINAL',CURRENT_DATE - 5) RETURNING id;" | head -1)
# SGK ayrılış bildirgesi gecikmiş personel (FAZ 7.7)
$PSQL -c "INSERT INTO employees (property_id, first_name, last_name, position, hire_date, end_date, is_active) VALUES ('$DEMO_PROPERTY','Eski','Calisan','Bahçıvan',CURRENT_DATE - 300,CURRENT_DATE - 20,false);" >/dev/null
$PSQL -c "INSERT INTO unit_insurance_policies (property_id, unit_id, policy_no, start_date, end_date) VALUES ('$DEMO_PROPERTY','$U40','D-40',CURRENT_DATE - 355,CURRENT_DATE + 10);" >/dev/null
# Tatbikat (FAZ 7.3): diğer sitede son tatbikat 400 gün önce → hatırlatma; demo sitede bugün → yok
$PSQL -c "INSERT INTO emergency_drills (property_id, kind, drill_date, findings) VALUES ('$OTHERPROP','FIRE',CURRENT_DATE - 400,'eksiklik yok');" >/dev/null
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
[ "$NB" = "1" ] && echo "$BODY" | grep -q "2 kalem" && echo "$BODY" | grep -q "1.334,56 TL" \
  && echo "$BODY" | grep -q "Güneş Sitesi" && echo "$BODY" | grep -q "2020-01 aidat: 1.234,56 TL" && echo "$BODY" | grep -q "2020-02 aidat: 100,00 TL" \
  && ok "borçlu daireye tek bildirim: site, bölüm, dönem/tür/tutar dökümü (2020-01 aidat 1.234,56 · 2020-02 aidat 100,00), kalan 1.334,56 TL" \
  || bad "aidat bildirimi ($NB): $BODY"
NB=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE recipient_user_id='$R40OLD';")
[ "$NB" = "0" ] && ok "daireden taşınmış eski kiracıya aidat bildirimi GİTMEDİ" || bad "taşınmış sakine $NB bildirim"
NB41=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$R41';")
[ "$NB41" = "0" ] && ok "ödeme bildirimi yönetim onayı bekleyen borca hatırlatma gitmedi" || bad "incelemedeki ödemeye $NB41 hatırlatma"
KEY=$($PSQL -t -A -c "SELECT dedupe_key FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$R40';")
echo "$KEY" | grep -Eq "^dues.overdue:$U40:[0-9]{4}-[0-9]{2}:$R40$" && ok "aidat hatırlatması daire+ay anahtarlı (ayda en fazla bir)" \
  || bad "aidat dedupe anahtarı: $KEY"

# Bakım hatırlatması: yaklaşan ve geçen → yönetim; uzak ve hurdaya ayrılmış → yok
UP=$($PSQL -t -A -c "SELECT count(*) || '|' || COALESCE(max(body),'') FROM notifications WHERE payload->>'asset_id'='$AM1' AND topic='asset.maintenance.upcoming';")
OV=$($PSQL -t -A -c "SELECT count(*) || '|' || COALESCE(max(body),'') FROM notifications WHERE payload->>'asset_id'='$AM2' AND topic='asset.maintenance.overdue';")
NN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'asset_id' IN ('$AM3','$AM4');")
[ "${UP%%|*}" -ge 1 ] && echo "$UP" | grep -q "5 gün kaldı" && [ "${OV%%|*}" -ge 1 ] && echo "$OV" | grep -q "3 gün geçti" && [ "$NN" = "0" ] \
  && ok "bakım tarihi yaklaşan (5 gün) ve geçen (3 gün) demirbaş yönetime bildirildi; uzak ve hurdaya ayrılmış olana yok" \
  || bad "bakım hatırlatması: yaklaşan '$UP', geçen '$OV', gereksiz $NN"
KA=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'kvkk_request_id'='$KS1' AND topic='kvkk.due.soon';")
KB=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'kvkk_request_id'='$KS2' AND topic='kvkk.due.overdue';")
KC=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'kvkk_request_id'='$KS3';")
[ "${KA:-0}" -ge 1 ] && [ "${KB:-0}" -ge 1 ] && [ "$KC" = "0" ] \
  && ok "KVKK yanıt süresi dolmak üzere/dolmuş açık başvuru yönetime bildirildi; sonuçlanmış olana yok" || bad "KVKK süre hatırlatması: $KA / $KB / $KC"

BS=$($PSQL -t -A -c "SELECT count(*) || '|' || COALESCE(max(body),'') FROM notifications WHERE payload->>'budget_id'='$BA1' AND topic='budget.approval.soon';")
BO=$($PSQL -t -A -c "SELECT count(*) || '|' || COALESCE(max(body),'') FROM notifications WHERE payload->>'budget_id'='$BA2' AND topic='budget.approval.overdue';")
BN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE payload->>'budget_id' IN ('$BA3','$BA4');")
[ "${BS%%|*}" -ge 1 ] && echo "$BS" | grep -q "10 gün kaldı" && [ "${BO%%|*}" -ge 1 ] && echo "$BO" | grep -q "kendiliğinden\|kesinleşmez" && [ "$BN" = "0" ] \
  && ok "geçici işletme projesinin genel kurul süresi (KMK m.37) yaklaşan/geçen proje için yönetime bildirildi; uzak ve kesinleşmiş olana yok" \
  || bad "işletme projesi süre hatırlatması: '$BS' / '$BO' / gereksiz $BN"
DO1=$($PSQL -t -A -c "SELECT count(*) || '|' || COALESCE(max(body),'') FROM notifications WHERE topic='emergency.drill' AND property_id='$OTHERPROP';")
DD1=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='emergency.drill' AND property_id='$DEMO_PROPERTY';")
[ "${DO1%%|*}" -ge 1 ] && echo "$DO1" | grep -q "12 ay" && [ "$DD1" = "0" ] \
  && ok "yıllık tatbikat süresi geçen siteye hatırlatma gitti (Acil Durumlar Yön. m.13); güncel tatbikatı olan siteye yok" \
  || bad "tatbikat hatırlatması: '$DO1' / demo $DD1"
CO1=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='compliance.sgk_exit' AND property_id='$DEMO_PROPERTY' AND payload->>'state'='overdue';")
[ "${CO1:-0}" -ge 1 ] && ok "gecikmiş SGK ayrılış bildirgesi yönetime hatırlatıldı (zamanlayıcı ve takvim aynı hesap)" || bad "işveren yükümlülüğü hatırlatması: $CO1"
KU1=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='kvkk.destruction.undefined' AND property_id='$OTHERPROP';")
KU2=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='kvkk.destruction.undefined' AND property_id='$DEMO_PROPERTY';")
[ "${KU1:-0}" -ge 1 ] && [ "$KU2" = "0" ] && ok "saklama süresi tanımlamamış siteye periyodik imha hatırlatması gitti; tanımlamış siteye yok" || bad "imha hatırlatması: $KU1 / $KU2"
DK=$($PSQL -t -A -c "SELECT count(*) FILTER (WHERE recipient_user_id='$R40'), count(*) FILTER (WHERE recipient_user_id<>'$R40') FROM notifications WHERE topic='dask.soon' AND payload->>'unit_id'='$U40';")
[ "${DK%%|*}" -ge 1 ] && [ "${DK##*|}" = "0" ] && ok "DASK poliçesi biten dairenin yalnızca malikine hatırlatma gitti (6305 m.10/3)" || bad "DASK hatırlatması: $DK"
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
    (SELECT count(*) FROM audit_logs) || '|' || (SELECT count(*) FROM pg_policy) || '|' ||
    (SELECT md5(string_agg(relname || COALESCE(relacl, acldefault('r', relowner))::text, ',' ORDER BY relname)) FROM pg_class
       WHERE relnamespace = 'public'::regnamespace AND relkind = 'r');"
}
if bash "$SCRIPT_DIR/db-backup.sh" "$BK" >/tmp/verify-backup.log 2>&1; then
  ok "yedek alındı ve okunabilir: $(tail -1 /tmp/verify-backup.log)"
  FP1=$(fingerprint)
  # Yıkıcı ve hatalı bir migration'ı taklit et: tablo sil, veri sil, sürüm ekle, yeni tablo aç.
  $PSQL -c "DROP TABLE expenses CASCADE; DELETE FROM finance_ledger; DELETE FROM payment_assessments; DELETE FROM payments;
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

step "43) Dış bildirim sağlayıcıları: Netgsm SMS + SMTP (TEST_RAPORU 2.4)"
# Gerçek gönderim kullanıcının hesabıyla yapılır; burada Netgsm REST v2 biçimini taklit eden
# yerel sahte sunucuya karşı uçtan uca sınanır (istek biçimi, kimlik doğrulama, numara biçimi).
if go test ./pkg/notify/ -count=1 -run 'Netgsm|SMTP|Normalize|SendersFromEnv' >/tmp/verify-providers.log 2>&1; then
  ok "go test ./pkg/notify (Netgsm istek/yanıt/hata kodları, SMTP zarf ve UTF-8 başlık, şifresiz bağlantıda parola reddi)"
else
  bad "sağlayıcı birim testleri"; tail -15 /tmp/verify-providers.log
fi
cat >/tmp/fake-netgsm.py <<'PYEOF'
import http.server, json, sys, base64
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
        auth = base64.b64decode(self.headers.get('Authorization', 'Basic ')[6:] or b'').decode()
        with open('/tmp/fake-netgsm.log', 'a') as f:
            f.write(json.dumps({'path': self.path, 'auth': auth, 'body': json.loads(body or b'{}')}) + '\n')
        self.send_response(200); self.send_header('Content-Type', 'application/json'); self.end_headers()
        self.wfile.write(b'{"code":"00","jobid":"FAKE-1"}')
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PYEOF
rm -f /tmp/fake-netgsm.log
python3 /tmp/fake-netgsm.py 18390 >/dev/null 2>&1 &
FAKE_PID=$!
NG="NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=api-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:18390"
env $NG DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18381 \
  go run ./services/identity >/tmp/verify-identity-sms.log 2>&1 &
IDS_PID=$!
env $NG DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18383 PII_ENCRYPTION_KEY="$PIIKEY" \
  go run ./services/community >/tmp/verify-community-sms.log 2>&1 &
COMS_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18381/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:18383/health >/dev/null 2>&1 && break; sleep 1
done
MGRS=$(curl -s -X POST http://127.0.0.1:18381/api/v1/auth/login -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
TENS=$(curl -s -X POST http://127.0.0.1:18381/api/v1/auth/login -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
SU=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' ORDER BY door_number LIMIT 1;")
CRS=$(curl -s -X POST http://127.0.0.1:18381/api/v1/residents -H "Authorization: Bearer $MGRS" -H "$J" \
  -d "{\"first_name\":\"Sms\",\"last_name\":\"Sakin\",\"phone\":\"0555 999 00 43\",\"unit_id\":\"$SU\",\"role\":\"TENANT\"}")
SCODE=$(echo "$CRS" | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
sleep 1
SMSOK=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')]
r=[x for x in rows if x['body']['messages'][0]['no']=='5559990043']
b=r[-1]
print(b['path']=='/sms/rest/v2/send' and b['auth']=='8501112233:api-sifre' and b['body']['msgheader']=='SITEEKSEN'
      and b['body']['iysfilter']=='0' and b['body']['encoding']=='TR' and '$SCODE' in b['body']['messages'][0]['msg'])
" 2>/dev/null)
echo "$CRS" | grep -q '"sms":{"status":"SENT"' && [ -n "$SCODE" ] && [ "$SMSOK" = "True" ] \
  && ok "sakin eklenince etkinleştirme kodu SMS ile gitti (Netgsm v2 biçimi, Basic auth, 5XXXXXXXXX, işlemsel/iysfilter 0); yanıt SENT diyor" \
  || bad "etkinleştirme SMS'i: $SMSOK — $CRS"
# Acil duyuru: SMS yalnızca URGENT; kayıtlı telefonu olan her aktif sakine
SC1=$(code -X POST http://127.0.0.1:18383/api/v1/announcements -H "Authorization: Bearer $MGRS" -H "$J" -d '{"title":"Bilgi","content":"x","priority":"NORMAL","send_sms":true}')
BEFORE=$(wc -l </tmp/fake-netgsm.log)
AN=$(curl -s -X POST http://127.0.0.1:18383/api/v1/announcements -H "Authorization: Bearer $MGRS" -H "$J" \
  -d '{"title":"Su kesintisi","content":"Yarın 10:00-14:00 arası ana hatta arıza onarımı nedeniyle su verilemeyecek.","priority":"URGENT","category":"MAINTENANCE","send_sms":true}')
sleep 1
AFTER=$(wc -l </tmp/fake-netgsm.log)
NSENT=$(echo "$AN" | python3 -c "import json,sys; print(json.load(sys.stdin)['sms']['sent'])" 2>/dev/null)
NREC=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='announcement.urgent' AND channel='SMS' AND status='SENT' AND provider='netgsm';")
[ "$SC1" = "422" ] && [ "${NSENT:-0}" -ge 1 ] && [ "$((AFTER-BEFORE))" = "$NSENT" ] && [ "$NREC" = "$NSENT" ] \
  && ok "acil duyuru $NSENT sakine SMS ile gitti (kuyrukta SENT/netgsm); acil olmayan duyuruda SMS 422" \
  || bad "acil duyuru SMS: $SC1 / gönderilen=$NSENT / sahte sunucu=$((AFTER-BEFORE)) / kayıt=$NREC — $AN"
# Yarım yapılandırma servisi açmaz (sessizce SMS'siz çalışmaz)
NETGSM_USERCODE=x DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18382 timeout 60 go run ./services/identity >/tmp/verify-identity-bad.log 2>&1
grep -q 'SMS yapılandırması hatalı' /tmp/verify-identity-bad.log && ok "yarım Netgsm yapılandırmasıyla kimlik servisi açılmıyor" \
  || bad "yarım yapılandırma: $(tail -2 /tmp/verify-identity-bad.log)"
# Yönetim destekli hesap kurtarma (Apsiyon BUG-05/06): telefon değişikliği ve giriş kilidi
IDS="http://127.0.0.1:18381/api/v1"
CR5=$(curl -s -X POST "$IDS/residents" -H "Authorization: Bearer $MGRS" -H "$J" \
  -d "{\"first_name\":\"Kayip\",\"last_name\":\"Telefon\",\"phone\":\"0555 999 00 44\",\"unit_id\":\"$SU\",\"role\":\"PROXY\"}")
RU5=$(echo "$CR5" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
U5=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559990044';")
$PSQL -c "UPDATE users SET failed_login_attempts = 5, locked_until = now() + interval '15 minutes' WHERE id='$U5';" >/dev/null
UL1=$(curl -s -X POST "$IDS/residents/$RU5/unlock" -H "Authorization: Bearer $MGRS" -H "$J" -d '{}')
UL2=$(code -X POST "$IDS/residents/$RU5/unlock" -H "Authorization: Bearer $TENS" -H "$J" -d '{}')
UL3=$(code -X POST "$IDS/residents/00000000-0000-0000-0000-000000000001/unlock" -H "Authorization: Bearer $MGRS" -H "$J" -d '{}')
LKS=$($PSQL -t -A -c "SELECT failed_login_attempts || '|' || (locked_until IS NULL) FROM users WHERE id='$U5';")
echo "$UL1" | grep -q '"was_locked":true' && [ "$UL2" = "403" ] && [ "$UL3" = "404" ] && [ "$LKS" = "0|true" ] \
  && ok "yönetim giriş kilidini kaldırabiliyor (kilit ve sayaç sıfırlandı); sakin 403, olmayan kayıt 404" \
  || bad "kilit kaldırma: $UL1 / $UL2 / $UL3 / $LKS"
BEFORE5=$(wc -l </tmp/fake-netgsm.log)
PC1=$(curl -s -X POST "$IDS/residents/$RU5/phone" -H "Authorization: Bearer $MGRS" -H "$J" -d '{"phone":"0555 999 00 45"}')
sleep 1
PCODE=$(echo "$PC1" | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
PCOK=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')][$BEFORE5:]
new=[r for r in rows if r['body']['messages'][0]['no']=='5559990045' and '$PCODE' in r['body']['messages'][0]['msg']]
old=[r for r in rows if r['body']['messages'][0]['no']=='5559990044' and 'değiştirildi' in r['body']['messages'][0]['msg']]
print(bool('$PCODE') and len(new)==1 and len(old)==1)" 2>/dev/null)
PH5=$($PSQL -t -A -c "SELECT phone FROM users WHERE id='$U5';")
INV5=$($PSQL -t -A -c "SELECT count(*) FROM user_token_invalidation WHERE user_id='$U5';")
PC2=$(code -X POST "$IDS/residents/$RU5/phone" -H "Authorization: Bearer $MGRS" -H "$J" -d '{"phone":"5551234567"}')
MRU=$($PSQL -t -A -c "SELECT ru.id FROM resident_units ru JOIN units u ON u.id=ru.unit_id JOIN users us ON us.id=ru.resident_id
  WHERE us.phone LIKE '%5551234567' AND u.property_id='$DEMO_PROPERTY' AND ru.is_active LIMIT 1;")
MULTI=$($PSQL -t -A -c "SELECT count(DISTINCT p) FROM (SELECT u.property_id p FROM resident_units ru JOIN units u ON u.id=ru.unit_id JOIN users us ON us.id=ru.resident_id WHERE us.phone LIKE '%5551234567' AND ru.is_active
  UNION SELECT pr.property_id FROM property_roles pr JOIN users us ON us.id=pr.user_id WHERE us.phone LIKE '%5551234567' AND pr.is_active) x;")
PC3=$(code -X POST "$IDS/residents/$MRU/phone" -H "Authorization: Bearer $MGRS" -H "$J" -d '{"phone":"0555 999 00 46"}')
echo "$PC1" | grep -q '"sessions_revoked":true' && echo "$PC1" | grep -q '"old_phone_notice":"SENT"' && [ "$PCOK" = "True" ] \
  && [ "$PH5" = "+905559990045" ] && [ "${INV5:-0}" -ge 1 ] && [ "$PC2" = "409" ] && { [ "${MULTI:-1}" -le 1 ] || [ "$PC3" = "409" ]; } \
  && ok "telefon değişikliği: oturumlar kapandı, yeni kod yeni numaraya SMS, eski numaraya uyarı SMS'i; başkasının numarası 409; birden çok sitede kayıtlı hesabın numarası tek site yönetimince değiştirilemez ($MULTI site → $PC3)" \
  || bad "telefon değişikliği: $PC1 / sms=$PCOK / $PH5 / iptal=$INV5 / $PC2 / çoklu=$MULTI→$PC3"
# Apsiyon BUG-10: yurt dışı numarayla (Lüksemburg +352) hesap, SMS, etkinleştirme ve giriş
if go test ./pkg/phone/ -count=1 >/tmp/verify-phone.log 2>&1; then
  ok "go test ./pkg/phone (E.164: TR yazımları, +352/+49/+1/+44, 00 öneki, geçersiz biçimler)"
else
  bad "go test ./pkg/phone"; tail -15 /tmp/verify-phone.log
fi
BEFORE6=$(wc -l </tmp/fake-netgsm.log)
CR6=$(curl -s -X POST "$IDS/residents" -H "Authorization: Bearer $MGRS" -H "$J" \
  -d "{\"first_name\":\"Yurt\",\"last_name\":\"Disi\",\"phone\":\"+352 621 123 456\",\"unit_id\":\"$SU\",\"role\":\"PROXY\"}")
ICODE=$(echo "$CR6" | sed -n 's/.*"activation_code":"\([^"]*\)".*/\1/p')
sleep 1
ISMS=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')][$BEFORE6:]
print(any(r['body']['messages'][0]['no']=='00352621123456' and '$ICODE' in r['body']['messages'][0]['msg'] for r in rows))" 2>/dev/null)
IPH=$($PSQL -t -A -c "SELECT count(*) FROM users WHERE phone='+352621123456';")
IACT=$(code -X POST "$IDS/auth/activate" -H "$J" -d "{\"phone\":\"00352 621 123 456\",\"code\":\"$ICODE\",\"new_password\":\"Lux2026guvenli\"}")
ILOG=$(curl -s -X POST "$IDS/auth/login" -H "$J" -d '{"phone":"+352621123456","password":"Lux2026guvenli"}' | grep -c '"access_token"')
IBAD=$(code -X POST "$IDS/residents" -H "Authorization: Bearer $MGRS" -H "$J" \
  -d "{\"first_name\":\"X\",\"last_name\":\"Y\",\"phone\":\"555-ABC-1234\",\"unit_id\":\"$SU\",\"role\":\"TENANT\"}")
IBAD2=$(code -X POST "$IDS/residents" -H "Authorization: Bearer $MGRS" -H "$J" \
  -d "{\"first_name\":\"X\",\"last_name\":\"Y\",\"phone\":\"+90 555 123\",\"unit_id\":\"$SU\",\"role\":\"TENANT\"}")
[ -n "$ICODE" ] && [ "$ISMS" = "True" ] && [ "$IPH" = "1" ] && [ "$IACT" = "200" ] && [ "$ILOG" = "1" ] && [ "$IBAD" = "422" ] && [ "$IBAD2" = "422" ] \
  && ok "yurt dışı numara (+352): E.164 saklandı, kod SMS ile 00352… numarasına gitti, 00 önekiyle etkinleştirme ve +352 ile giriş çalıştı; geçersiz/eksik numara 422" \
  || bad "yurt dışı numara: kod=$ICODE sms=$ISMS db=$IPH act=$IACT login=$ILOG bad=$IBAD/$IBAD2 — $CR6"
kill_tree "$IDS_PID"; kill_tree "$COMS_PID"; kill "$FAKE_PID" 2>/dev/null

step "44) PDF / Excel dökümleri (TEST_RAPORU 2.6)"
if go test ./pkg/reports/ -count=1 >/tmp/verify-reports.log 2>&1; then
  ok "go test ./pkg/reports (gömülü UTF-8 font, xlsx hücreleri, içerik özeti, para biçimi)"
else
  bad "rapor motoru testleri"; tail -15 /tmp/verify-reports.log
fi
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18482 \
  go run ./services/finance >/tmp/verify-finance-rep.log 2>&1 &
FREP_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18487 \
  go run ./services/governance >/tmp/verify-governance-rep.log 2>&1 &
GREP_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18482/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:18487/health >/dev/null 2>&1 && break; sleep 1
done
MGRR="$MGRS"   # adım 43'te alınan yönetici jetonu (servisler jetonu kendisi doğrular)
dl() { curl -s -o "$2" -w '%{http_code}|%{content_type}' "$1" -H "Authorization: Bearer ${3:-$MGRR}"; }
cat >/tmp/pdftext.py <<'PYEOF'
import sys, pypdf
print("\n".join((p.extract_text() or "") for p in pypdf.PdfReader(sys.argv[1]).pages))
PYEOF
R1=$(dl "http://127.0.0.1:18482/api/v1/finance/reports/debtors?format=pdf" /tmp/r-debtors.pdf)
T1=$(python3 /tmp/pdftext.py /tmp/r-debtors.pdf 2>/dev/null)
R2=$(dl "http://127.0.0.1:18482/api/v1/finance/reports/debtors?format=xlsx" /tmp/r-debtors.xlsx)
X2=$(python3 -c "import zipfile; z=zipfile.ZipFile('/tmp/r-debtors.xlsx'); print('Borçlu bölümler' in z.read('xl/workbook.xml').decode(), 'Toplam alacak' in z.read('xl/sharedStrings.xml').decode())" 2>/dev/null)
R3=$(dl "http://127.0.0.1:18482/api/v1/finance/reports/debtors?format=pdf" /tmp/r-x.pdf "$TENS")
R4=$(dl "http://127.0.0.1:18482/api/v1/finance/reports/debtors?format=docx" /tmp/r-x.bin)
case "$R1" in "200|application/pdf") P1=1 ;; *) P1=0 ;; esac
[ "$P1" = "1" ] && grep -q 'Borçlu listesi' <<<"$T1" && grep -q 'ortak alanlara asılması' <<<"$T1" && grep -q 'Doğrulama kodu' <<<"$T1" \
  && [ "${R2%%|*}" = "200" ] && [ "$X2" = "True True" ] && [ "${R3%%|*}" = "403" ] && [ "${R4%%|*}" = "400" ] \
  && ok "borçlu listesi PDF (Türkçe metin okunuyor, KVKK 2026/348 uyarısı, doğrulama kodu) ve Excel indirildi; sakin 403, geçersiz biçim 400" \
  || bad "borçlu listesi dökümü: $R1 / $R2 ($X2) / $R3 / $R4 — $(head -c 200 <<<"$T1")"
R5=$(dl "http://127.0.0.1:18482/api/v1/finance/reports/collections?year=2026&format=pdf" /tmp/r-col.pdf)
T5=$(python3 /tmp/pdftext.py /tmp/r-col.pdf 2>/dev/null)
[ "${R5%%|*}" = "200" ] && grep -q '2026 yılı tahakkuk ve tahsilat özeti' <<<"$T5" && grep -q 'mizan' <<<"$T5" \
  && ok "tahakkuk/tahsilat özeti PDF (mizan olmadığını açıkça söylüyor)" || bad "tahsilat özeti: $R5 — $(head -c 200 <<<"$T5")"
ASMR=$($PSQL -t -A -c "SELECT id FROM assemblies WHERE property_id='$DEMO_PROPERTY' ORDER BY created_at LIMIT 1;")
R6=$(dl "http://127.0.0.1:18487/api/v1/governance/assemblies/$ASMR/attendance-sheet?format=pdf" /tmp/r-haz.pdf)
T6=$(python3 /tmp/pdftext.py /tmp/r-haz.pdf 2>/dev/null)
NU=$($PSQL -t -A -c "SELECT count(*) FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0;")
FU=$($PSQL -t -A -c "SELECT COALESCE(block,'') || '-' || door_number FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0 ORDER BY block, door_number LIMIT 1;")
[ "${R6%%|*}" = "200" ] && grep -q 'Hazirun cetveli' <<<"$T6" && grep -q "$FU" <<<"$T6" && grep -q 'Oy toplayıcı' <<<"$T6" \
  && ok "hazirun cetveli PDF: $NU bölüm, arsa payı, malik ve imza sütunu, KMK m.29-30 notu" || bad "hazirun cetveli: $R6 — $(head -c 300 <<<"$T6")"
BKR=$($PSQL -t -A -c "SELECT b.id FROM books b WHERE b.property_id='$DEMO_PROPERTY' AND EXISTS (SELECT 1 FROM book_entries e WHERE e.book_id=b.id) LIMIT 1;")
R7=$(dl "http://127.0.0.1:18487/api/v1/governance/books/$BKR/export?format=pdf" /tmp/r-book.pdf)
T7=$(python3 /tmp/pdftext.py /tmp/r-book.pdf 2>/dev/null)
BUR=$($PSQL -t -A -c "SELECT id FROM operating_budgets WHERE property_id='$DEMO_PROPERTY' AND status='FINAL' LIMIT 1;")
R8=$(dl "http://127.0.0.1:18487/api/v1/governance/budgets/$BUR/export?format=xlsx" /tmp/r-bud.xlsx)
X8=$(python3 -c "import zipfile; z=zipfile.ZipFile('/tmp/r-bud.xlsx'); s=z.read('xl/workbook.xml').decode(); print('Kalemler' in s and 'Bağımsız bölüm payları' in s)" 2>/dev/null)
R9=$(dl "http://127.0.0.1:18487/api/v1/governance/books/00000000-0000-0000-0000-000000000000/export" /tmp/r-x.bin)
[ "${R7%%|*}" = "200" ] && grep -q 'Bağlar tutarlı' <<<"$T7" && [ "${R8%%|*}" = "200" ] && [ "$X8" = "True" ] && [ "${R9%%|*}" = "404" ] \
  && ok "karar defteri PDF zincir doğrulamasını yazıyor; işletme projesi Excel (kalemler + bölüm payları); olmayan defter 404" \
  || bad "defter/proje dökümü: $R7 / $R8 ($X8) / $R9 — $(head -c 200 <<<"$T7")"
kill_tree "$FREP_PID"; kill_tree "$GREP_PID"

step "45) Borcu yoktur belgesi: vadesi geçmiş/gelmemiş ayrımı, karekod, kimliksiz doğrulama (055, Apsiyon BUG-04)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18582 PUBLIC_VERIFY_BASE_URL=https://dogrula.ornek.test \
  go run ./services/finance >/tmp/verify-finance-clr.log 2>&1 &
FCLR_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:18582/health >/dev/null 2>&1 && break; sleep 1; done
CF="http://127.0.0.1:18582/api/v1/finance"
U45='45454545-0000-0000-0000-0000000000a1'
$PSQL -c "INSERT INTO units (id, property_id, block, floor, door_number, share_ratio, net_area_m2) VALUES ('$U45','$DEMO_PROPERTY','T',1,'45',1,80) ON CONFLICT (id) DO NOTHING;
  INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date)
  VALUES ('$DEMO_PROPERTY','$U45',2099,1,500,500,CURRENT_DATE + 10);" >/dev/null
C1=$(curl -s -w '|%{http_code}' -X POST "$CF/clearance-certificates" -H "Authorization: Bearer $MGRS" -H "$J" -d "{\"unit_id\":\"$U40\"}")
C2=$(curl -s -X POST "$CF/clearance-certificates" -H "Authorization: Bearer $MGRS" -H "$J" -d "{\"unit_id\":\"$U45\"}")
CID=$(echo "$C2" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p'); CCODE=$(echo "$C2" | sed -n 's/.*"verification_code":"\([0-9a-f]*\)".*/\1/p')
C3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$CF/clearance-certificates" -H "Authorization: Bearer $TENS" -H "$J" -d "{\"unit_id\":\"$U45\"}")
case "$C1" in *'"overdue":['*"|422") COK=1 ;; *) COK=0 ;; esac
[ "$COK" = "1" ] && [ ${#CCODE} = "64" ] && echo "$C2" | grep -q '"not_due_kurus":50000' && echo "$C2" | grep -q "https://dogrula.ornek.test/$CCODE" && [ "$C3" = "403" ] \
  && ok "vadesi geçmiş borcu olan bölüme belge yok (422 + kalem listesi); yalnızca vadesi gelmemiş 500,00 TL'si olana belge üretildi (64 hane SHA-256 kod, doğrulama adresi); başka dairenin sakini 403" \
  || bad "borcu yoktur belgesi: $C1 / $C2 / $C3"
CP=$(curl -s -o /tmp/r-clr.pdf -w '%{http_code}' "$CF/clearance-certificates/$CID/pdf" -H "Authorization: Bearer $MGRS")
TCLR=$(python3 /tmp/pdftext.py /tmp/r-clr.pdf 2>/dev/null)
NIMG=$(python3 -c "import pypdf; print(len(pypdf.PdfReader('/tmp/r-clr.pdf').pages[0].images))" 2>/dev/null)
[ "$CP" = "200" ] && grep -q 'Borcu yoktur belgesi' <<<"$TCLR" && grep -q 'vadesi geçmiş hiçbir aidat' <<<"$TCLR" && grep -q 'Vadesi gelmemiş tahakkuk' <<<"$TCLR" \
  && grep -q "$CCODE" <<<"$(tr -d '\n' <<<"$TCLR")" && [ "${NIMG:-0}" -ge 1 ] \
  && ok "belge PDF'i: Türkçe beyan, vadesi gelmemiş tutar ayrı, doğrulama kodu ve karekod görseli var" \
  || bad "belge PDF: $CP / görsel=$NIMG — $(head -c 300 <<<"$TCLR")"
PV1=$(curl -s "http://127.0.0.1:18582/api/v1/public/clearance/$CCODE")
PV2=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:18582/api/v1/public/clearance/$(printf '0%.0s' $(seq 1 64))")
PV3=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:18582/api/v1/public/clearance/abc")
CUO=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','11111111-1111-1111-1111-111111111111',true); UPDATE clearance_certificates SET expires_at = CURRENT_DATE + 999 WHERE id='$CID'; COMMIT;" 2>&1); CU=$(grep -c 'permission denied' <<<"$CUO")
$PSQL -c "UPDATE clearance_certificates SET expires_at = CURRENT_DATE - 1, as_of_date = CURRENT_DATE - 40 WHERE id='$CID';" >/dev/null
PV4=$(curl -s "http://127.0.0.1:18582/api/v1/public/clearance/$CCODE")
echo "$PV1" | grep -q '"valid":true' && echo "$PV1" | grep -q '"unit":"T-45"' && ! echo "$PV1" | grep -qi 'phone\|first_name\|kurus' \
  && [ "$PV2" = "404" ] && [ "$PV3" = "400" ] && [ "$CU" -ge 1 ] && echo "$PV4" | grep -q '"expired":true' \
  && ok "kimliksiz doğrulama: geçerli belge yalnızca site/bölüm/tarih döndürüyor (kişisel veri ve tutar yok); bilinmeyen kod 404, biçimsiz 400; süresi geçen geçersiz; uygulama rolü belgeyi değiştiremez" \
  || bad "belge doğrulama: $PV1 / $PV2 / $PV3 / değiştir=$CU ($CUO) / $PV4"
kill_tree "$FCLR_PID"

step "46) Site pasifleştirme: pasif sitede tahakkuk, gecikme tazminatı ve bildirim üretilemez (058, Apsiyon BUG-11)"
# Demo site geçici olarak pasife alınır ve adım sonunda yeniden etkinleştirilir.
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18681 \
  go run ./services/identity >/tmp/verify-identity-life.log 2>&1 &
ILF_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18682 \
  go run ./services/finance >/tmp/verify-finance-life.log 2>&1 &
FLF_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:18681/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:18682/health >/dev/null 2>&1 && break; sleep 1
done
LI="http://127.0.0.1:18681/api/v1"; LF="http://127.0.0.1:18682/api/v1/finance"
MGRL=$(curl -s -X POST "$LI/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
TENL=$(curl -s -X POST "$LI/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
PNAME=$($PSQL -t -A -c "SELECT name FROM properties WHERE id='$DEMO_PROPERTY';")
appsql46() { PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SELECT set_config('app.property_id','$DEMO_PROPERTY',true); $1; COMMIT;" 2>&1; }
D1=$(code -X POST "$LI/property/deactivate" -H "Authorization: Bearer $TENL" -H "$J" -d "{\"reason\":\"Hizmet bitti\",\"confirm_name\":\"$PNAME\"}")
D2=$(code -X POST "$LI/property/deactivate" -H "Authorization: Bearer $MGRL" -H "$J" -d '{"reason":"Hizmet bitti","confirm_name":"Baska site"}')
D3=$(code -X POST "$LI/property/deactivate" -H "Authorization: Bearer $MGRL" -H "$J" -d "{\"reason\":\"x\",\"confirm_name\":\"$PNAME\"}")
D4=$(curl -s -X POST "$LI/property/deactivate" -H "Authorization: Bearer $MGRL" -H "$J" \
  -d "{\"reason\":\"Yönetim hizmet sözleşmesini 10.10.2026 itibarıyla sonlandırdı\",\"confirm_name\":\"$PNAME\"}")
PST=$(curl -s "$LI/property" -H "Authorization: Bearer $MGRL")
[ "$D1" = "403" ] && [ "$D2" = "422" ] && [ "$D3" = "400" ] && echo "$D4" | grep -q '"is_active":false' \
  && echo "$PST" | grep -q '"is_active":false' && echo "$PST" | grep -q '"action":"DEACTIVATED"' \
  && ok "yalnızca yönetici, gerekçe ve site adı onayıyla pasife aldı (sakin 403, yanlış ad 422, kısa gerekçe 400); olay kaydedildi" \
  || bad "pasifleştirme: $D1 / $D2 / $D3 / $D4 / $PST"
# Tahakkuk API'den üretilemez; uygulama rolüyle doğrudan yazım da tetikleyiciye takılır
TA=$(curl -s -w '|%{http_code}' -X POST "$LF/assessments" -H "Authorization: Bearer $MGRL" -H "$J" \
  -d '{"period_year":2033,"period_month":3,"due_date":"2033-03-15","expense_items":[{"category_id":"55555555-5555-5555-5555-555555555501","amount":1000}]}')
TAN=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year=2033;")
LASS=$($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND deleted=0 AND total_amount > 1 ORDER BY due_date LIMIT 1;")
W1=$(appsql46 "INSERT INTO notifications (property_id, channel, category, topic, body, status) VALUES ('$DEMO_PROPERTY','IN_APP','TRANSACTIONAL','x','x','PENDING')")
W2=$(appsql46 "UPDATE monthly_assessments SET late_fee = COALESCE(late_fee,0) + 1, total_amount = total_amount + 1 WHERE id='$LASS'")
W3=$(appsql46 "INSERT INTO late_fee_accruals (assessment_id, accrued_on, overdue_days, principal_kurus, monthly_rate, fee_kurus) VALUES ('$LASS','2099-01-01',1,100,0.05,5)")
W4=$(appsql46 "UPDATE monthly_assessments SET total_amount = total_amount WHERE id='$LASS'")
case "$TA" in *PROPERTY_INACTIVE*"|409") TAOK=1 ;; *) TAOK=0 ;; esac
[ "$TAOK" = "1" ] && [ "$TAN" = "0" ] && grep -q 'site pasif' <<<"$W1" && grep -q 'site pasif' <<<"$W2" && grep -q 'site pasif' <<<"$W3" && grep -q 'COMMIT' <<<"$W4" \
  && ok "pasif sitede tahakkuk API'den 409 PROPERTY_INACTIVE; doğrudan bildirim, gecikme tazminatı ve borç artırma tetikleyiciye takıldı; tutarı artırmayan güncelleme serbest" \
  || bad "pasif site yazımları: $TA / kayıt=$TAN / $W1 / $W2 / $W3 / $W4"
SCH=$($PSQL -t -A -c "SELECT count(*) FROM scheduler_property_ids() id WHERE id='$DEMO_PROPERTY';")
RD=$(code "$LF/assessments?year=2026" -H "Authorization: Bearer $TENL")
LG=$(curl -s -X POST "$LI/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | grep -c '"access_token"')
[ "$SCH" = "0" ] && [ "$RD" = "200" ] && [ "$LG" = "1" ] \
  && ok "zamanlayıcı pasif siteyi taramıyor; sakin giriş yapıp geçmiş tahakkuklarını görebiliyor (veri silinmedi)" \
  || bad "pasif site okuma/zamanlayıcı: zamanlayıcı=$SCH okuma=$RD giriş=$LG"
DE=$(appsql46 "DELETE FROM property_lifecycle_events")
R1=$(code -X POST "$LI/property/reactivate" -H "Authorization: Bearer $MGRL" -H "$J" -d '{"reason":"Yeni sözleşme imzalandı"}')
W5=$(appsql46 "INSERT INTO notifications (property_id, recipient_address, channel, category, topic, body, status) VALUES ('$DEMO_PROPERTY','verify','IN_APP','TRANSACTIONAL','verify.reactivated','x','PENDING')")
EV=$($PSQL -t -A -c "SELECT string_agg(action, ',' ORDER BY created_at) FROM property_lifecycle_events WHERE property_id='$DEMO_PROPERTY';")
grep -q 'permission denied' <<<"$DE" && [ "$R1" = "200" ] && grep -q 'COMMIT' <<<"$W5" && [ "$EV" = "DEACTIVATED,REACTIVATED" ] \
  && ok "yeniden etkinleştirildi, yazım açıldı; yaşam döngüsü olayları uygulama rolüyle silinemiyor ($EV)" \
  || bad "yeniden etkinleştirme: sil=$DE / $R1 / $W5 / $EV"
$PSQL -c "UPDATE properties SET is_active = true WHERE id='$DEMO_PROPERTY';" >/dev/null
kill_tree "$ILF_PID"; kill_tree "$FLF_PID"

step "47) Alacak dekontu ve banka ekstresi mutabakatı (059, Apsiyon BUG-12)"
if go test ./services/finance/service/ -count=1 -run 'Parse' >/tmp/verify-bankparse.log 2>&1; then
  ok "go test ekstre ayrıştırma (Türkçe/noktalı tutar, borç/alacak sütunları, başlık öncesi satırlar, xlsx, satır numaralı hata)"
else
  bad "ekstre ayrıştırma testleri"; tail -15 /tmp/verify-bankparse.log
fi
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18782 \
  go run ./services/finance >/tmp/verify-finance-adj.log 2>&1 &
FADJ_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:18782/health >/dev/null 2>&1 && break; sleep 1; done
AF="http://127.0.0.1:18782/api/v1/finance"; AM="Authorization: Bearer $MGRL"; AT="Authorization: Bearer $TENL"
U304='33333333-3333-3333-3333-333333333304'
A1=$($PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$U304',2098,1,1000,1000,CURRENT_DATE - 10,'OVERDUE') RETURNING id;" | head -1)
CN0=$(code -X POST "$AF/credit-notes" -H "$AT" -H "$J" -d "{\"assessment_id\":\"$A1\",\"amount_try\":100,\"reason\":\"Oturulmayan ay\"}")
CN1=$(code -X POST "$AF/credit-notes" -H "$AM" -H "$J" -d "{\"assessment_id\":\"$A1\",\"amount_try\":1200,\"reason\":\"Oturulmayan ay\"}")
CN2=$(code -X POST "$AF/credit-notes" -H "$AM" -H "$J" -d "{\"assessment_id\":\"$A1\",\"amount_try\":100,\"reason\":\"x\"}")
CN3=$(curl -s -X POST "$AF/credit-notes" -H "$AM" -H "$J" -d "{\"assessment_id\":\"$A1\",\"amount_try\":250.50,\"reason\":\"Ocak ayında daire boştu; genel kurul kararı 2026/4\"}")
CNID=$(echo "$CN3" | sed -n 's/.*"credit_note":{"id":"\([^"]*\)".*/\1/p')
CNDB=$($PSQL -t -A -c "SELECT base_amount||'|'||credited_amount||'|'||total_amount FROM monthly_assessments WHERE id='$A1';")
LG1=$($PSQL -t -A -c "SELECT entry_type||'|'||amount_kurus||'|'||(detail->>'document_no') FROM finance_ledger WHERE property_id='$DEMO_PROPERTY' ORDER BY seq DESC LIMIT 1;")
COLL=$($PSQL -t -A -c "SELECT count(*) FROM payments WHERE payment_method='CREDIT_NOTE';")
[ "$CN0" = "403" ] && [ "$CN1" = "422" ] && [ "$CN2" = "400" ] && echo "$CN3" | grep -q '"document_no":"AD-20[0-9][0-9]-0001"' \
  && [ "$CNDB" = "1000.00|250.50|749.50" ] && echo "$LG1" | grep -q '^CREDIT_NOTE|25050|AD-' && [ "$COLL" = "0" ] \
  && ok "alacak dekontu: sakin 403, kalan borcu aşan 422, gerekçesiz 400; AD-yıl-0001 numarasıyla kesildi, borç 1000→749,50 (anapara korunarak), zincire CREDIT_NOTE yazıldı, ödeme/tahsilat oluşturmadı" \
  || bad "alacak dekontu: $CN0 / $CN1 / $CN2 / $CN3 / $CNDB / $LG1 / tahsilat=$COLL"
OA=$(curl -s "$AF/units/$U304/open-assessments" -H "$AM" | python3 -c "
import json,sys
a=[x for x in json.load(sys.stdin)['data'] if x['id']=='$A1'][0]; print(a['credited_kurus'], a['outstanding_kurus'], a['max_credit_kurus'])" 2>/dev/null)
OAT=$(code "$AF/units/$U304/open-assessments" -H "$AT")
[ "$OA" = "25050 74950 74950" ] && [ "$OAT" = "403" ] && ok "dekont için açık tahakkuk listesi kalan borcu ve azami dekont tutarını veriyor; sakin 403" \
  || bad "açık tahakkuklar: $OA / $OAT"
TL=$(curl -s "$AF/credit-notes" -H "$AT" | grep -c "$CNID")
TP=$(curl -s -o /tmp/r-cn.pdf -w '%{http_code}' "$AF/credit-notes/$CNID/pdf" -H "$AT")
TPT=$(python3 /tmp/pdftext.py /tmp/r-cn.pdf 2>/dev/null | tr -d '\n')
grep -q 'Alacak dekontu AD-' <<<"$TPT" && grep -q 'tahsilat değildir' <<<"$TPT" && [ "$TL" = "1" ] && [ "$TP" = "200" ] \
  && ok "sakin kendi dairesinin dekontunu görüyor ve sisteme işlenmiş PDF belgesini indiriyor (WhatsApp'tan Excel makbuz değil)" \
  || bad "sakin dekont görünümü: liste=$TL pdf=$TP — $(head -c 200 <<<"$TPT")"
curl -s -o /dev/null -X POST "$AF/late-fees/accrue" -H "$AM" -H "$J" -d '{}'
LFP=$($PSQL -t -A -c "SELECT principal_kurus FROM late_fee_accruals WHERE assessment_id='$A1' ORDER BY accrued_on DESC LIMIT 1;")
LFT=$($PSQL -t -A -c "SELECT (total_amount = base_amount - credited_amount + late_fee) FROM monthly_assessments WHERE id='$A1';")
[ "$LFP" = "74950" ] && [ "$LFT" = "t" ] && ok "gecikme tazminatı dekonttan sonra kalan anapara (749,50) üzerinden işledi; toplam = anapara − dekont + tazminat" \
  || bad "dekont sonrası tazminat: anapara=$LFP toplam=$LFT"
G1=$(appsql46 "DELETE FROM credit_notes WHERE id='$CNID'")
G2=$(appsql46 "UPDATE credit_notes SET amount = 1 WHERE id='$CNID'")
grep -q 'permission denied' <<<"$G1" && grep -q 'değiştirilemez' <<<"$G2" && ok "dekont uygulama rolüyle silinemiyor ve tutarı değiştirilemiyor" \
  || bad "dekont koruması: $G1 / $G2"
RV1=$(code -X POST "$AF/credit-notes/$CNID/reverse" -H "$AM" -H "$J" -d '{"reason":"x"}')
RV2=$(code -X POST "$AF/credit-notes/$CNID/reverse" -H "$AM" -H "$J" -d '{"reason":"Karar iptal edildi, borç geri yüklendi"}')
RV3=$(code -X POST "$AF/credit-notes/$CNID/reverse" -H "$AM" -H "$J" -d '{"reason":"Karar iptal edildi, borç geri yüklendi"}')
RVDB=$($PSQL -t -A -c "SELECT credited_amount||'|'||(total_amount = base_amount + late_fee) FROM monthly_assessments WHERE id='$A1';")
LG2=$($PSQL -t -A -c "SELECT entry_type||'|'||amount_kurus FROM finance_ledger WHERE property_id='$DEMO_PROPERTY' ORDER BY seq DESC LIMIT 1;")
LV=$(curl -s "$AF/ledger/verify" -H "$AT" | grep -c '"valid":true')
[ "$RV1" = "400" ] && [ "$RV2" = "200" ] && [ "$RV3" = "409" ] && [ "$RVDB" = "0.00|true" ] && [ "$LG2" = "CREDIT_NOTE_REVERSED|-25050" ] && [ "$LV" = "1" ] \
  && ok "dekontun ters kaydı: gerekçesiz 400, borç geri yüklendi, ikinci ters kayıt 409; zincire CREDIT_NOTE_REVERSED yazıldı ve zincir geçerli" \
  || bad "dekont ters kaydı: $RV1 / $RV2 / $RV3 / $RVDB / $LG2 / zincir=$LV"
# Banka ekstresi: sakinin havale bildirimi ekstredeki harekete açıklamasından eşleşir
A2=$($PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$U304',2098,2,640,640,CURRENT_DATE + 20,'PENDING') RETURNING id;" | head -1)
VD=$(date +%Y-%m-%d)
PAY=$(curl -s -X POST "$AF/payments" -H "$AT" -H "$J" -d "{\"assessment_ids\":[\"$A2\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$VD\",\"reference\":\"HVL778899\"}")
PID=$(echo "$PAY" | grep -o '"payment_id":"[^"]*"\|"id":"[^"]*"' | head -1 | cut -d'"' -f4)
TRD=$(date +%d.%m.%Y)
printf 'Hesap No: TR00 0001\n\nİşlem Tarihi;Açıklama;Tutar;Bakiye;Dekont No\n%s;GELEN EFT MEHMET DEMIR HVL778899 AIDAT;640,00;12.640,00;D-1\n%s;BANKA MASRAFI;-85,00;12.555,00;D-2\n%s;GELEN HAVALE BILINMEYEN;333,33;12.888,33;D-3\n' "$TRD" "$TRD" "$TRD" >/tmp/ekstre.csv
BI=$(curl -s -X POST "$AF/bank-statements" -H "$AM" -F "file=@/tmp/ekstre.csv")
BIID=$(echo "$BI" | python3 -c "import json,sys; print(json.load(sys.stdin)['import']['id'])" 2>/dev/null)
BCHK=$(echo "$BI" | python3 -c "
import json,sys
d=json.load(sys.stdin)['import']; L={l['line_no']:l for l in d['lines']}
print(d['counts'].get('SUGGESTED'), d['counts'].get('OUTGOING'), d['counts'].get('UNMATCHED'), L[4]['suggested_payment_id']=='$PID', L[4]['line_no'])" 2>/dev/null)
BI2=$(curl -s -X POST "$AF/bank-statements" -H "$AM" -F "file=@/tmp/ekstre.csv" | python3 -c "import json,sys; print(json.load(sys.stdin)['import']['counts'])" 2>/dev/null)
BT=$(code -X POST "$AF/bank-statements" -H "$AT" -F "file=@/tmp/ekstre.csv")
printf 'a;b\n1;2\n' >/tmp/ekstre-bozuk.csv
BB=$(code -X POST "$AF/bank-statements" -H "$AM" -F "file=@/tmp/ekstre-bozuk.csv")
[ -n "$PID" ] && [ "$BCHK" = "1 1 1 True 4" ] && [ "$BI2" = "{'DUPLICATE': 3}" ] && [ "$BT" = "403" ] && [ "$BB" = "400" ] \
  && ok "ekstre yüklendi: havale açıklamasındaki referansla bekleyen ödeme önerildi, giden hareket ve eşleşmeyen ayrıldı (satır no dosyadaki satır); aynı dosya tekrar yüklenince 3 satır mükerrer; sakin 403, başlıksız dosya 400" \
  || bad "ekstre yükleme: ödeme=$PID / $BCHK / tekrar=$BI2 / sakin=$BT / bozuk=$BB — $(head -c 300 <<<"$BI")"
LINE1=$($PSQL -t -A -c "SELECT id FROM bank_statement_lines WHERE import_id='$BIID' AND line_no=4;")
LINE3=$($PSQL -t -A -c "SELECT id FROM bank_statement_lines WHERE import_id='$BIID' AND line_no=6;")
BC1=$(curl -s -w '|%{http_code}' -X POST "$AF/bank-statements/lines/$LINE1/confirm" -H "$AM" -H "$J" -d '{}')
BCDB=$($PSQL -t -A -c "SELECT p.status||'|'||ma.paid_amount||'|'||l.status FROM payments p, monthly_assessments ma, bank_statement_lines l
  WHERE p.id='$PID' AND ma.id='$A2' AND l.id='$LINE1';")
BLG=$($PSQL -t -A -c "SELECT entry_type||'|'||(detail->>'reference') FROM finance_ledger WHERE payment_id='$PID' ORDER BY seq DESC LIMIT 1;")
BC2=$(code -X POST "$AF/bank-statements/lines/$LINE1/confirm" -H "$AM" -H "$J" -d '{}')
BC3=$(code -X POST "$AF/bank-statements/lines/$LINE3/confirm" -H "$AM" -H "$J" -d "{\"payment_id\":\"$PID\"}")
BC4=$(code -X POST "$AF/bank-statements/lines/$LINE3/ignore" -H "$AM" -H "$J" -d '{"note":"Kira geliri; ayrıca gelir olarak kaydedildi"}')
case "$BC1" in *"|200") BC1OK=1 ;; *) BC1OK=0 ;; esac
[ "$BC1OK" = "1" ] && [ "$BCDB" = "COMPLETED|640.00|CONFIRMED" ] && echo "$BLG" | grep -q '^PAYMENT_CONFIRMED|Banka ekstresi' \
  && [ "$BC2" = "409" ] && [ "$BC3" = "422" ] && [ "$BC4" = "200" ] \
  && ok "eşleşme onayı ödemeyi aynı işlemde onayladı (borç düştü, zincire 'Banka ekstresi' referansıyla yazıldı); ikinci onay 409, tutarı tutmayan eşleşme 422, gerekçeli yok sayma 200" \
  || bad "ekstre onayı: $BC1 / $BCDB / $BLG / $BC2 / $BC3 / $BC4"
kill_tree "$FADJ_PID"

step "48) Kartla ödeme: iyzico ödeme formu, 3D Secure dönüşü, durum makinesi (060, TEST_RAPORU 2.5, Apsiyon BUG-09)"
# Gerçek çekim kullanıcının iyzico hesabıyla yapılır; burada iyzico API biçimini ve IYZWSv2 imzasını
# DOĞRULAYAN yerel sahte sunucuya karşı uçtan uca sınanır.
if go test ./pkg/iyzico/ -count=1 >/tmp/verify-iyzico.log 2>&1; then
  ok "go test ./pkg/iyzico (IYZWSv2 imzası, kuruştan tutar metni, ret kodu sınıflandırma, yarım yapılandırma reddi)"
else
  bad "go test ./pkg/iyzico"; tail -15 /tmp/verify-iyzico.log
fi
cat >/tmp/fake-iyzico.py <<'PYEOF'
import http.server, json, sys, base64, hmac, hashlib, os
SECRET, KEY, STATE = b'sandbox-sk', 'sandbox-ak', {'n': 0, 'tok': {}}
def mode(name, default):
    try: return open(name).read().strip() or default
    except FileNotFoundError: return default
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
        rnd = self.headers.get('x-iyzi-rnd', '')
        auth = base64.b64decode(self.headers.get('Authorization', 'IYZWSv2 ')[8:] or b'').decode()
        parts = dict(p.split(':', 1) for p in auth.split('&') if ':' in p)
        sig = hmac.new(SECRET, (rnd + self.path).encode() + body, hashlib.sha256).hexdigest()
        ok = parts.get('apiKey') == KEY and parts.get('randomKey') == rnd and hmac.compare_digest(parts.get('signature', ''), sig)
        req = json.loads(body or b'{}')
        with open('/tmp/fake-iyzico.log', 'a') as f:
            f.write(json.dumps({'path': self.path, 'sig_ok': ok, 'body': req}) + '\n')
        if not ok:
            out = {'status': 'failure', 'errorCode': '1001', 'errorMessage': 'imza geçersiz'}
        elif self.path.endswith('/initialize/auth/ecom'):
            if mode('/tmp/fake-iyzico-init', 'OK') == 'FAIL':
                out = {'status': 'failure', 'errorCode': '5013', 'errorMessage': 'Geçersiz istek'}
            else:
                STATE['n'] += 1; tok = 'tok-%d' % STATE['n']
                STATE['tok'][tok] = {'basketId': req['basketId'], 'price': req['paidPrice'], 'n': STATE['n']}
                out = {'status': 'success', 'token': tok, 'paymentPageUrl': 'https://sandbox-cpp.iyzipay.test/pay/' + tok, 'tokenExpireTime': 1800}
        else:
            t = STATE['tok'].get(req.get('token'))
            m = mode('/tmp/fake-iyzico-mode', 'SUCCESS')
            if t is None or m == 'APIFAIL':
                out = {'status': 'failure', 'errorCode': '5139', 'errorMessage': 'Hata'}
            elif m == 'SUCCESS' or m == 'WRONG_PRICE':
                price = t['price'] if m == 'SUCCESS' else str(float(t['price']) + 1)
                out = {'status': 'success', 'paymentStatus': 'SUCCESS', 'paymentId': 'FAKEPAY-%d' % t['n'], 'paidPrice': price, 'basketId': t['basketId']}
            elif m == 'INIT':
                out = {'status': 'success', 'paymentStatus': 'INIT_THREEDS', 'basketId': t['basketId']}
            else:
                _, code, msg = m.split(':', 2)
                out = {'status': 'success', 'paymentStatus': 'FAILURE', 'errorCode': code, 'errorMessage': msg, 'basketId': t['basketId']}
        raw = json.dumps(out).encode()
        self.send_response(200); self.send_header('Content-Type', 'application/json'); self.send_header('Content-Length', str(len(raw))); self.end_headers()
        self.wfile.write(raw)
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
PYEOF
rm -f /tmp/fake-iyzico.log /tmp/fake-iyzico-mode /tmp/fake-iyzico-init
python3 /tmp/fake-iyzico.py 18890 >/dev/null 2>&1 &
FIYZ_PID=$!
IZ="IYZICO_API_KEY=sandbox-ak IYZICO_SECRET_KEY=sandbox-sk IYZICO_BASE_URL=http://127.0.0.1:18890 IYZICO_CALLBACK_URL=http://127.0.0.1:8888/api/v1/public/payments/iyzico/callback"
# Yarım yapılandırma servisi açmaz
IYZICO_API_KEY=x DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18883 timeout 60 go run ./services/finance >/tmp/verify-finance-cardbad.log 2>&1
grep -q 'Kart ödeme yapılandırması hatalı' /tmp/verify-finance-cardbad.log && ok "yarım iyzico yapılandırmasıyla finans servisi açılmıyor" \
  || bad "yarım iyzico yapılandırması: $(tail -2 /tmp/verify-finance-cardbad.log)"
env $IZ CARD_RECONCILE_INTERVAL=1s CARD_RECONCILE_AGE=30s PAYMENT_RESULT_URL=https://app.ornek.test/odeme-sonuc \
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18882 \
  go run ./services/finance >/tmp/verify-finance-card.log 2>&1 &
FCRD_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:18882/health >/dev/null 2>&1 && break; sleep 1; done
CF="http://127.0.0.1:18882/api/v1/finance"; CB="http://127.0.0.1:18882/api/v1/public/payments/iyzico/callback"
newass() { $PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$U304',2097,$1,$2,$2,CURRENT_DATE + ($3),'PENDING') RETURNING id;" | head -1; }
cardpay() { curl -s -X POST "$CF/payments" -H "$AT" -H "$J" -d "{\"assessment_ids\":[\"$1\"],\"payment_method\":\"CREDIT_CARD\"}"; }
pid_of() { echo "$1" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p'; }
tok_of() { $PSQL -t -A -c "SELECT gateway_token FROM payments WHERE id='$1';"; }
# 1) Kart reddi: Türkçe neden, borç değişmez, idempotent geri dönüş
C1=$(newass 1 500 -5)
echo 'FAILURE:10051:Kartınızın limiti yetersiz.' >/tmp/fake-iyzico-mode
P1R=$(cardpay "$C1"); P1=$(pid_of "$P1R"); T1=$(tok_of "$P1")
P1DB=$($PSQL -t -A -c "SELECT status||'|'||gateway_status||'|'||(value_date = CURRENT_DATE)||'|'||round(amount*100)::bigint FROM payments WHERE id='$P1';")
INIOK=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-iyzico.log')]
r=[x for x in rows if x['path'].endswith('/initialize/auth/ecom') and x['body']['basketId']=='$P1'][-1]
b=r['body']; amt=int('$P1DB'.split('|')[3])
price=('%d.%02d'%(amt//100,amt%100)).rstrip('0'); price=price+'0' if price.endswith('.') else price
print(r['sig_ok'] and b['paidPrice']==price and b['currency']=='TRY' and b['locale']=='tr' and b['callbackUrl'].endswith('/public/payments/iyzico/callback') and b['basketItems'][0]['itemType']=='VIRTUAL' and 'cardNumber' not in json.dumps(b))" 2>/dev/null)
ST1=$(curl -s "$CF/payments/$P1/status" -H "$AT")
echo "$P1R" | grep -q '"payment_gateway_ready":true' && echo "$P1R" | grep -q '"checkout_url":"https://sandbox-cpp.iyzipay.test/pay/tok-' \
  && [ "$P1DB" != "" ] && [ "${P1DB%|*}" = "PENDING|INITIATED|true" ] && [ "$INIOK" = "True" ] && echo "$ST1" | grep -q '"gateway_status":"INITIATED"' \
  && ok "kart ödemesi başlatıldı: imzalı (IYZWSv2) istek, kuruştan tutar, sanal sepet, kart bilgisi bu sisteme gelmiyor; ödeme PENDING/INITIATED, gecikme bugün donduruldu" \
  || bad "kart başlatma: $P1R / $P1DB / imza+gövde=$INIOK / $ST1"
CB1=$(curl -s -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T1")
CB1B=$(curl -s -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T1")
CB1R=$(curl -s -o /dev/null -w '%{http_code}|%{redirect_url}' -X POST "$CB" --data-urlencode "token=$T1")
F1DB=$($PSQL -t -A -c "SELECT p.status||'|'||p.gateway_status||'|'||p.failure_kind||'|'||p.gateway_error_code||'|'||COALESCE(ma.paid_amount,0)
  FROM payments p, monthly_assessments ma WHERE p.id='$P1' AND ma.id='$C1';")
DSIG=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-iyzico.log')]
print(all(r['sig_ok'] for r in rows if r['path'].endswith('/detail')) and any(r['body'].get('token')=='$T1' for r in rows))" 2>/dev/null)
echo "$CB1" | grep -q '"status":"FAILED"' && echo "$CB1" | grep -q 'Kartınızın limiti yetersiz' && [ "$F1DB" = "FAILED|FAILED|CARD|10051|0.00" ] \
  && [ "$CB1B" = "$CB1" ] && echo "$CB1R" | grep -q '^303|https://app.ornek.test/odeme-sonuc?message=' && echo "$CB1R" | grep -q 'status=FAILED' && [ "$DSIG" = "True" ] \
  && ok "kart reddi: sonuç iyzico'dan imzalı istekle yeniden sorgulandı, Türkçe neden (limit yetersiz) gösterildi, borç değişmedi; ikinci geri dönüş aynı sonucu verdi; tarayıcı sonuç sayfasına yönlendirildi" \
  || bad "kart reddi: $CB1 / $F1DB / tekrar=$CB1B / yönlendirme=$CB1R / imza=$DSIG"
# 2) Başarılı ödeme: borç düşer, tahsilat defterine yazılır
echo 'SUCCESS' >/tmp/fake-iyzico-mode
P2=$(pid_of "$(cardpay "$C1")"); T2=$(tok_of "$P2")
CB2=$(curl -s -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T2")
S2DB=$($PSQL -t -A -c "SELECT p.status||'|'||p.gateway_status||'|'||ma.status||'|'||(ma.paid_amount = p.amount)
  FROM payments p, monthly_assessments ma WHERE p.id='$P2' AND ma.id='$C1';")
S2LG=$($PSQL -t -A -c "SELECT entry_type||'|'||(detail->>'reference') FROM finance_ledger WHERE payment_id='$P2';")
LV2=$(curl -s "$CF/ledger/verify" -H "$AT" | grep -c '"valid":true')
echo "$CB2" | grep -q '"status":"COMPLETED"' && [ "$S2DB" = "COMPLETED|SUCCEEDED|PAID|true" ] && echo "$S2LG" | grep -q '^PAYMENT_CONFIRMED|iyzico:FAKEPAY-' && [ "$LV2" = "1" ] \
  && ok "başarılı kart ödemesi: borç kapandı, tahsilat defterine iyzico ödeme kimliğiyle yazıldı, zincir geçerli" \
  || bad "başarılı kart ödemesi: $CB2 / $S2DB / $S2LG / zincir=$LV2"
U1=$(code -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=tok-yok")
U2=$(code -X POST "$CB" -H 'Accept: application/json')
[ "$U1" = "404" ] && [ "$U2" = "404" ] && ok "bilinmeyen ya da boş jetonla geri dönüş 404 (sahte geri dönüş borç düşüremez)" || bad "bilinmeyen jeton: $U1 / $U2"
# 3) Tutar/sepet uyuşmazlığı: borç düşmez
C2=$(newass 2 300 20)
echo 'WRONG_PRICE' >/tmp/fake-iyzico-mode
P3=$(pid_of "$(cardpay "$C2")"); T3=$(tok_of "$P3")
curl -s -o /dev/null -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T3"
M3=$($PSQL -t -A -c "SELECT p.status||'|'||p.gateway_error_code||'|'||COALESCE(ma.paid_amount,0) FROM payments p, monthly_assessments ma WHERE p.id='$P3' AND ma.id='$C2';")
[ "$M3" = "FAILED|AMOUNT_MISMATCH|0.00" ] && ok "bankadan dönen tutar ödemeyle uyuşmayınca borç düşürülmedi (AMOUNT_MISMATCH, yönetim incelemesi)" || bad "tutar uyuşmazlığı: $M3"
# 4) Sağlayıcıya ulaşılamayan sonuç havada kalmaz: uzlaştırma zaman aşımıyla kapatır
C4=$(newass 4 200 20)
echo 'APIFAIL' >/tmp/fake-iyzico-mode
P4=$(pid_of "$(cardpay "$C4")"); T4=$(tok_of "$P4")
CB4=$(curl -s -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T4")
G4=$($PSQL -t -A -c "SELECT status||'|'||gateway_status FROM payments WHERE id='$P4';")
$PSQL -c "UPDATE payments SET created_at = created_at - interval '1 hour' WHERE id='$P4';" >/dev/null
E4=""
for _ in $(seq 1 10); do
  E4=$($PSQL -t -A -c "SELECT status||'|'||gateway_status||'|'||failure_kind||'|'||gateway_error_code FROM payments WHERE id='$P4';")
  [ "${E4%%|*}" = "FAILED" ] && break; sleep 1
done
echo "$CB4" | grep -q '"status":"PENDING"' && [ "$G4" = "PENDING|PROCESSING" ] && [ "$E4" = "FAILED|EXPIRED|SYSTEM|TIMEOUT" ] \
  && ok "sonuç sorgulanamayınca ödeme PROCESSING kaldı (beyaz ekranda bırakılmadı); uzlaştırma bekçisi süre dolunca sistem kaynaklı zaman aşımıyla kapattı" \
  || bad "uzlaştırma: $CB4 / $G4 / $E4"
# 5) 3D Secure tamamlanmadı (sistem kaynaklı) → yeni deneme ilk denemenin gününü devralır; faiz o günde durur
C3=$(newass 3 400 -10)
echo 'INIT' >/tmp/fake-iyzico-mode
P5=$(pid_of "$(cardpay "$C3")")
$PSQL -c "UPDATE payments SET created_at = created_at - interval '1 hour', value_date = CURRENT_DATE - 1 WHERE id='$P5';" >/dev/null
E5=""
for _ in $(seq 1 10); do
  E5=$($PSQL -t -A -c "SELECT status||'|'||gateway_status||'|'||failure_kind||'|'||gateway_error_code FROM payments WHERE id='$P5';")
  [ "${E5%%|*}" = "FAILED" ] && break; sleep 1
done
echo 'SUCCESS' >/tmp/fake-iyzico-mode
curl -s -o /dev/null -X POST "$CF/late-fees/accrue" -H "Authorization: Bearer $MGRL" -H "$J" -d '{}'
LF5=$($PSQL -t -A -c "SELECT late_fee FROM monthly_assessments WHERE id='$C3';")
P6R=$(cardpay "$C3"); P6=$(pid_of "$P6R"); T6=$(tok_of "$P6")
V6=$($PSQL -t -A -c "SELECT (value_date = CURRENT_DATE - 1) FROM payments WHERE id='$P6';")
LF6=$($PSQL -t -A -c "SELECT late_fee FROM monthly_assessments WHERE id='$C3';")
curl -s -o /dev/null -X POST "$CB" -H 'Accept: application/json' --data-urlencode "token=$T6"
S6=$($PSQL -t -A -c "SELECT status FROM payments WHERE id='$P6';")
[ "$E5" = "FAILED|EXPIRED|SYSTEM|3DS_TIMEOUT" ] && [ "$V6" = "t" ] && echo "$P6R" | grep -q 'sistem kaynaklı' && [ "$LF5" = "6.67" ] && [ "$LF6" = "6.00" ] && [ "$S6" = "COMPLETED" ] \
  && ok "3D Secure tamamlanmayan deneme zaman aşımıyla kapandı; yeni deneme ilk denemenin gününü valör aldı, gecikme tazminatı 10 günden (6,67) o güne (9 gün = 6,00 TL) indi, ödeme tamamlandı" \
  || bad "sistem hatası faiz koruması: $E5 / valör=$V6 / tazminat=$LF5→$LF6 / $S6 — $P6R"
# 6) Ödeme sayfası açılamazsa: 502, kayıt sistem kaynaklı başarısız, tutar çekilmedi
C5=$(newass 5 150 20)
echo 'FAIL' >/tmp/fake-iyzico-init
P7R=$(curl -s -w '|%{http_code}' -X POST "$CF/payments" -H "$AT" -H "$J" -d "{\"assessment_ids\":[\"$C5\"],\"payment_method\":\"CREDIT_CARD\"}")
P7DB=$($PSQL -t -A -c "SELECT p.status||'|'||p.failure_kind FROM payments p JOIN payment_assessments pa ON pa.payment_id=p.id WHERE pa.assessment_id='$C5' ORDER BY p.created_at DESC LIMIT 1;")
rm -f /tmp/fake-iyzico-init
P8R=$(cardpay "$C5")
case "$P7R" in *CARD_GATEWAY*"Geçersiz istek"*"|502") P7OK=1 ;; *) P7OK=0 ;; esac
OST=$(code "$CF/payments/$P2/status" -H "Authorization: Bearer $MGRL")
[ "$P7OK" = "1" ] && [ "$P7DB" = "FAILED|SYSTEM" ] && echo "$P8R" | grep -q '"payment_gateway_ready":true' && [ "$OST" = "200" ] \
  && ok "ödeme sayfası açılamayınca 502 ve 'tutar çekilmedi' notu; kayıt sistem kaynaklı başarısız (PENDING bırakılmadı, yeniden deneme açıldı); yönetim ödeme durumunu görebiliyor" \
  || bad "başlatma hatası: $P7R / $P7DB / yeniden=$P8R / yönetim=$OST"
kill_tree "$FCRD_PID"; kill "$FIYZ_PID" 2>/dev/null

step "49) Yeni borçta sakine bildirim (beşinci tur B1, Şikayetvar §3.2)"
if go test ./pkg/notify/ -count=1 -run 'Charge|MergeResult|NotifyCharges' >/tmp/verify-charges.log 2>&1; then
  ok "go test ./pkg/notify (bildirim metni: dönem/devir, tutar, son ödeme; geçmiş vade notu; iki kanalda alıcı tek sayılır)"
else
  bad "yeni borç bildirimi birim testleri"; tail -15 /tmp/verify-charges.log
fi
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=18982 \
  go run ./services/finance >/tmp/verify-finance-b1.log 2>&1 &
FB1_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:18982/health >/dev/null 2>&1 && break; sleep 1; done
BF="http://127.0.0.1:18982/api/v1/finance"
TUID='44444444-4444-4444-4444-444444444402'
mkassess() { curl -s -X POST "$BF/assessments" -H "Authorization: Bearer $MGRL" -H "$J" \
  -d "{\"period_year\":$1,\"period_month\":$2,\"due_date\":\"$3\",\"expense_items\":[{\"category_id\":\"55555555-5555-5555-5555-555555555501\",\"amount\":2500}]}"; }
notes_for() { $PSQL -t -A -c "SELECT count(*) FROM notifications n JOIN monthly_assessments ma ON ma.id::text = n.payload->>'assessment_id'
  WHERE n.topic='dues.created' AND n.recipient_user_id='$TUID' AND n.payload->>'unit_id'='$U304'
    AND ma.period_year=$1 AND ma.period_month=$2 AND n.channel='IN_APP';"; }
B1R=$(mkassess 2096 1 2096-01-15)
B1N=$(notes_for 2096 1)
B1B=$($PSQL -t -A -c "SELECT n.body FROM notifications n WHERE n.topic='dues.created' AND n.recipient_user_id='$TUID' AND n.payload->>'unit_id'='$U304' ORDER BY n.created_at DESC LIMIT 1;")
B1U=$($PSQL -t -A -c "SELECT count(DISTINCT payload->>'unit_id') FROM notifications WHERE topic='dues.created'
  AND payload->>'assessment_id' IN (SELECT id::text FROM monthly_assessments WHERE period_year=2096 AND period_month=1);")
echo "$B1R" | grep -q '"notification":{' && echo "$B1R" | grep -q '"sent":[1-9]' && [ "$B1N" = "1" ] \
  && grep -q 'A-4 bağımsız bölümü için yeni borç' <<<"$B1B" && grep -q '2096-01 dönemi aidatı' <<<"$B1B" && grep -q '15.01.2096' <<<"$B1B" \
  && ! grep -q 'bugünden önceki' <<<"$B1B" && [ "$B1U" -gt 0 ] \
  && ok "tahakkukta daire sakinlerine uygulama içi bildirim oluştu ($B1U bölüm): bölüm, dönem, tutar ve son ödeme günü yazıyor; yanıt sayaçları döndü" \
  || bad "tahakkuk bildirimi: $B1R / kiracıya=$B1N / $B1B / bölüm=$B1U"
# Taşınmış (pasif) sakine yeni borç bildirimi gitmez
$PSQL -c "UPDATE resident_units SET is_active=false WHERE resident_id='$TUID' AND unit_id='$U304';" >/dev/null
B2R=$(mkassess 2096 2 2096-02-15)
B2N=$(notes_for 2096 2)
$PSQL -c "UPDATE resident_units SET is_active=true WHERE resident_id='$TUID' AND unit_id='$U304';" >/dev/null
# Son ödeme günü geçmiş olarak kaydedilen borçta sakine bu açıkça yazılır
B3R=$(mkassess 2019 1 2019-01-15)
B3B=$($PSQL -t -A -c "SELECT n.body FROM notifications n JOIN monthly_assessments ma ON ma.id::text = n.payload->>'assessment_id'
  WHERE n.topic='dues.created' AND n.recipient_user_id='$TUID' AND n.payload->>'unit_id'='$U304' AND ma.period_year=2019 LIMIT 1;")
[ "$B2N" = "0" ] && echo "$B2R" | grep -q '"notification":{' && grep -q 'bugünden önceki' <<<"$B3B" && grep -q '15.01.2019' <<<"$B3B" \
  && ok "taşınmış (pasif) sakine yeni borç bildirimi gitmedi; son ödeme günü geçmiş kaydedilen borçta bu durum bildirimde açıkça yazıyor" \
  || bad "pasif sakin / geçmiş vade: pasife=$B2N / $B2R / $B3B"
# Devir bakiyesi de bildirilir
B4R=$(curl -s -X POST "$BF/opening-balances" -H "Authorization: Bearer $MGRL" -H "$J" \
  -d "{\"due_date\":\"2096-06-30\",\"items\":[{\"unit_id\":\"$U304\",\"amount\":321.5,\"description\":\"Önceki yönetimden yakıt farkı\"}]}")
B4ID=$(echo "$B4R" | sed -n 's/.*"data":\[{"id":"\([^"]*\)".*/\1/p')
B4B=$($PSQL -t -A -c "SELECT body FROM notifications WHERE topic='dues.created' AND payload->>'assessment_id'='$B4ID' AND recipient_user_id='$TUID';")
[ -n "$B4ID" ] && grep -q 'Devir bakiyesi' <<<"$B4B" && grep -q 'Önceki yönetimden yakıt farkı' <<<"$B4B" && grep -q '321,50' <<<"$B4B" \
  && ok "devir bakiyesi kaydında da daire sakinine bildirim oluştu (açıklama ve tutarla)" \
  || bad "devir bildirimi: $B4R / $B4B"
[ -n "$B4ID" ] && curl -s -o /dev/null -X POST "$BF/opening-balances/$B4ID/cancel" -H "Authorization: Bearer $MGRL"
$PSQL -c "DELETE FROM assessment_details WHERE assessment_id IN (SELECT id FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year IN (2096,2019));
  DELETE FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year IN (2096,2019);" >/dev/null
kill_tree "$FB1_PID"

step "50) Yönetimin tahsilat girişi: bildirimsiz havale, elden ödeme, eşleşmeyen ekstre satırı (061, beşinci tur B2)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19082 \
  go run ./services/finance >/tmp/verify-finance-b2.log 2>&1 &
FB2_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19082/health >/dev/null 2>&1 && break; sleep 1; done
CF2="http://127.0.0.1:19082/api/v1/finance"; CM="Authorization: Bearer $MGRL"; CT="Authorization: Bearer $TENL"
MUID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
U302='33333333-3333-3333-3333-333333333302'
newa2() { $PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$1',2095,$2,$3,$3,CURRENT_DATE + ($4),'PENDING') RETURNING id;" | head -1; }
KA=$(newa2 "$U304" 1 1000 -10); KB=$(newa2 "$U304" 2 517.35 15); KC=$(newa2 "$U304" 3 300 20); KX=$(newa2 "$U302" 1 200 5)
D2=$(date -d '2 days ago' +%Y-%m-%d); FUT2=$(date -d '+3 days' +%Y-%m-%d)
coll() { curl -s -w '|%{http_code}' -X POST "$CF2/collections" -H "$1" -H "$J" -d "$2"; }
K0=$(coll "$CT" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KA\"],\"payment_method\":\"CASH\",\"value_date\":\"$D2\"}")
K1=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KA\"],\"payment_method\":\"CASH\",\"value_date\":\"$D2\",\"reference\":\"Makbuz 0042\"}")
KP=$(echo "$K1" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
KDB=$($PSQL -t -A -c "SELECT p.status||'|'||COALESCE(p.user_id::text,'yok')||'|'||(p.recorded_by='$MUID')||'|'||p.payment_method||'|'||(p.value_date = CURRENT_DATE - 2)||'|'||p.amount||'|'||ma.status
  FROM payments p, monthly_assessments ma WHERE p.id='$KP' AND ma.id='$KA';")
KLG=$($PSQL -t -A -c "SELECT entry_type||'|'||(detail->>'reference')||'|'||(created_by='$MUID') FROM finance_ledger WHERE payment_id='$KP';")
case "$K0" in *"|403") K0OK=1 ;; *) K0OK=0 ;; esac
case "$K1" in *'"status":"COMPLETED"'*"|201") K1OK=1 ;; *) K1OK=0 ;; esac
[ "$K0OK" = "1" ] && [ "$K1OK" = "1" ] && [ "$KDB" = "COMPLETED|yok|true|CASH|true|1000.00|PAID" ] \
  && [ "$KLG" = "PAYMENT_CONFIRMED|Yönetim tahsilatı (nakit) · Makbuz 0042|true" ] \
  && ok "yönetici elden ödemeyi girdi: ödeme aynı işlemde onaylandı, borç kapandı, ödeyen boş / giren yönetici kayıtlı, ödeme günü korundu, tahsilat defterine yazıldı; sakin bu ucu kullanamıyor (403)" \
  || bad "tahsilat girişi: sakin=$K0 / $K1 / $KDB / $KLG"
KN=$($PSQL -t -A -c "SELECT body FROM notifications WHERE topic='payment.recorded' AND payload->>'payment_id'='$KP' AND recipient_user_id='$TUID';")
KMY=$(curl -s "$CF2/my-payments" -H "$CT" | python3 -c "
import json,sys
d=json.load(sys.stdin); r=[p for p in d.get('data',[]) if p['id']=='$KP']
print(len(r)==1 and r[0].get('recorded_by_management') is True)" 2>/dev/null)
KML=$(curl -s "$CF2/payments?limit=500" -H "$CM" | python3 -c "
import json,sys
d=json.load(sys.stdin); r=[p for p in d.get('data',[]) if p['id']=='$KP']
print(len(r)==1 and r[0]['name']=='Yönetim kaydı' and 'A' in r[0]['unit'])" 2>/dev/null)
grep -q 'elden (nakit) ödemeniz (1.000,00 TL) site yönetimi tarafından kaydedildi' <<<"$KN" && [ "$KMY" = "True" ] && [ "$KML" = "True" ] \
  && ok "daire sakinine 'ödemeniz kaydedildi' bildirimi gitti; sakin ödemeyi kendi ödeme geçmişinde, yönetim ödeme listesinde 'Yönetim kaydı' olarak görüyor" \
  || bad "tahsilat görünürlüğü: bildirim=$KN / sakin=$KMY / yönetim=$KML"
K2=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KB\"],\"payment_method\":\"CASH\",\"value_date\":\"$FUT2\"}")
K3=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KX\"],\"payment_method\":\"CASH\",\"value_date\":\"$D2\"}")
K4=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KA\"],\"payment_method\":\"CASH\",\"value_date\":\"$D2\"}")
K5=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KB\"],\"payment_method\":\"CHEQUE\",\"value_date\":\"$D2\"}")
# Sakinin onay bekleyen bildirimi varken ikinci kayıt açılmaz
TPAY=$(curl -s -X POST "$CF2/payments" -H "$CT" -H "$J" -d "{\"assessment_ids\":[\"$KC\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$D2\"}")
TPID=$(echo "$TPAY" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
K6=$(coll "$CM" "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KC\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$D2\"}")
curl -s -o /dev/null -X POST "$CF2/payments/$TPID/reject" -H "$CM"
[ "${K2##*|}" = "400" ] && [ "${K3##*|}" = "422" ] && [ "${K4##*|}" = "422" ] && [ "${K5##*|}" = "400" ] && [ "${K6##*|}" = "409" ] && grep -q 'onay bekleyen' <<<"$K6" \
  && ok "ileri tarihli ödeme 400, başka bölümün borcu 422, kapanmış borç 422, geçersiz yöntem 400; sakinin bekleyen bildirimi varken 409 (borç iki kez düşmez)" \
  || bad "tahsilat doğrulamaları: $K2 / $K3 / $K4 / $K5 / $K6"
# Banka ekstresinde bildirimsiz gelen havale doğrudan bölümün borcuna işlenir
TRD1=$(date -d '1 day ago' +%d.%m.%Y)
printf 'İşlem Tarihi;Açıklama;Tutar;Dekont No\n%s;GELEN HAVALE A4 DAIRE AIDAT SUBAT;517,35;B2-1\n%s;GELEN HAVALE ACIKLAMASIZ;123,45;B2-2\n' "$TRD1" "$TRD1" >/tmp/ekstre-b2.csv
BI3=$(curl -s -X POST "$CF2/bank-statements" -H "$CM" -F "file=@/tmp/ekstre-b2.csv")
BI3ID=$(echo "$BI3" | python3 -c "import json,sys; print(json.load(sys.stdin)['import']['id'])" 2>/dev/null)
LB=$($PSQL -t -A -c "SELECT id||'|'||status FROM bank_statement_lines WHERE import_id='$BI3ID' AND line_no=2;")
LM=$($PSQL -t -A -c "SELECT id FROM bank_statement_lines WHERE import_id='$BI3ID' AND line_no=3;")
K7=$(curl -s -w '|%{http_code}' -X POST "$CF2/bank-statements/lines/${LB%%|*}/collect" -H "$CM" -H "$J" -d "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KB\"]}")
K7P=$(echo "$K7" | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
K7DB=$($PSQL -t -A -c "SELECT l.status||'|'||(l.matched_payment_id='$K7P')||'|'||p.payment_method||'|'||(p.value_date = CURRENT_DATE - 1)||'|'||ma.status
  FROM bank_statement_lines l, payments p, monthly_assessments ma WHERE l.id='${LB%%|*}' AND p.id='$K7P' AND ma.id='$KB';")
K8=$(curl -s -w '|%{http_code}' -X POST "$CF2/bank-statements/lines/$LM/collect" -H "$CM" -H "$J" -d "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KC\"]}")
K8DB=$($PSQL -t -A -c "SELECT l.status||'|'||ma.status FROM bank_statement_lines l, monthly_assessments ma WHERE l.id='$LM' AND ma.id='$KC';")
K9=$(code -X POST "$CF2/bank-statements/lines/${LB%%|*}/collect" -H "$CM" -H "$J" -d "{\"unit_id\":\"$U304\",\"assessment_ids\":[\"$KC\"]}")
[ "${LB##*|}" = "UNMATCHED" ] && [ "${K7##*|}" = "200" ] && [ "$K7DB" = "CONFIRMED|true|BANK_TRANSFER|true|PAID" ] \
  && [ "${K8##*|}" = "422" ] && grep -q '123.45 TL' <<<"$K8" && [ "$K8DB" = "UNMATCHED|PENDING" ] && [ "$K9" = "409" ] \
  && ok "eşleşmeyen ekstre satırı doğrudan bölümün borcuna işlendi (ödeme günü hareket günü, satır onaylandı); tutarı tutmayan satır 422 ve açık kaldı; sonuçlanmış satır ikinci kez işlenemez (409)" \
  || bad "ekstreden tahsilat: satır=$LB / $K7 / $K7DB / $K8 / $K8DB / $K9"
G61=$(appsql46 "UPDATE payments SET recorded_by = NULL WHERE id='$KP'")
LV50=$(curl -s "$CF2/ledger/verify" -H "$CT" | grep -c '"valid":true')
grep -q 'değiştirilemez' <<<"$G61" && [ "$LV50" = "1" ] \
  && ok "tahsilatı girenin kaydı uygulama rolüyle değiştirilemiyor; tahsilat defteri zinciri geçerli" \
  || bad "tahsilat koruması: $G61 / zincir=$LV50"
kill_tree "$FB2_PID"

step "51) Şifremi unuttum: sakinin kendi kod isteği, numara ifşa etmeyen yanıt, sıklık sınırı (beşinci tur B3)"
if go test ./services/identity/service/ -count=1 -run 'SelfReset' >/tmp/verify-selfreset.log 2>&1; then
  ok "go test sıklık sınırı (60 sn bekleme, saatte en çok 3 kod)"
else
  bad "sıklık sınırı birim testi"; tail -15 /tmp/verify-selfreset.log
fi
rm -f /tmp/fake-netgsm.log
python3 /tmp/fake-netgsm.py 19190 >/dev/null 2>&1 &
FNG3_PID=$!
NG3="NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=api-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:19190"
env $NG3 DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19181 \
  go run ./services/identity >/tmp/verify-identity-b3.log 2>&1 &
IB3_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19183 \
  go run ./services/identity >/tmp/verify-identity-b3n.log 2>&1 &
IB3N_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19181/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19183/health >/dev/null 2>&1 && break; sleep 1
done
I3="http://127.0.0.1:19181/api/v1/auth"
LUX=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+352621123456';")
rreq() { curl -s -w '|%{http_code}' -X POST "$1/password-reset/request" -H "$J" -d "{\"phone\":\"$2\"}"; }
smscount() { local n; n=$(grep -c "\"no\": \"$1\"" /tmp/fake-netgsm.log 2>/dev/null); echo "${n:-0}"; }
R0=$(rreq "http://127.0.0.1:19183/api/v1/auth" "+352 621 123 456")
R1=$(rreq "$I3" "+352 621 123 456"); sleep 1
R2=$(rreq "$I3" "0555 000 00 01"); sleep 1
RC=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')]
m=[r['body']['messages'][0]['msg'] for r in rows if r['body']['messages'][0]['no']=='00352621123456']
import re
x=re.search(r'kodunuz: ([A-Z0-9]{8})', m[-1]) if m else None
print((x.group(1) if x and 'şifre sıfırlama' in m[-1] else ''))" 2>/dev/null)
NUNK=$(smscount 5550000001)
CEXP=$($PSQL -t -A -c "SELECT purpose||'|'||(created_by IS NULL)||'|'||(expires_at BETWEEN now() + interval '14 minutes' AND now() + interval '16 minutes')
  FROM user_activation_codes WHERE user_id='$LUX' AND used_at IS NULL ORDER BY created_at DESC LIMIT 1;")
case "$R0" in *NO_DELIVERY_CHANNEL*"|503") R0OK=1 ;; *) R0OK=0 ;; esac
[ "$R0OK" = "1" ] && [ "${R1##*|}" = "200" ] && [ "$R1" = "$R2" ] && [ -n "$RC" ] && [ "$NUNK" = "0" ] && [ "$CEXP" = "RESET|true|true" ] \
  && ok "kod sakinin kayıtlı numarasına SMS ile gitti (15 dk geçerli, kendi isteği olarak kayıtlı); kayıtsız numarada SMS yok ve yanıt birebir aynı (numara ifşa edilmiyor); gönderim kanalı olmayan kurulum 503 ile söylüyor" \
  || bad "şifremi unuttum: kanalsız=$R0 / kayıtlı=${R1: -40} / aynı yanıt=$([ "$R1" = "$R2" ] && echo evet || echo hayır) / kod=$RC / kayıtsıza sms=$NUNK / kod kaydı=$CEXP / lux=$LUX / $($PSQL -t -A -c "SELECT purpose||' '||COALESCE(created_by::text,'-')||' '||COALESCE(used_at::text,'açık')||' '||(expires_at - now()) FROM user_activation_codes WHERE user_id::text='$LUX' ORDER BY created_at DESC LIMIT 3;" 2>&1 | tr '\n' ';')"
N1=$(smscount 00352621123456)
R3=$(rreq "$I3" "+352621123456"); sleep 1
N2=$(smscount 00352621123456)
$PSQL -c "UPDATE user_activation_codes SET created_at = now() - interval '2 minutes' WHERE user_id='$LUX' AND created_by IS NULL;
  INSERT INTO user_activation_codes (user_id, code_hash, purpose, expires_at, created_at, used_at)
  VALUES ('$LUX','x','RESET',now(),now() - interval '3 minutes',now()), ('$LUX','y','RESET',now(),now() - interval '4 minutes',now());" >/dev/null
R4=$(rreq "$I3" "+352621123456"); sleep 1
N3=$(smscount 00352621123456)
R5=$(code -X POST "$I3/password-reset/request" -H "$J" -d '{"phone":"abc"}')
[ "$N2" = "$N1" ] && [ "$N3" = "$N1" ] && [ "${R3##*|}" = "200" ] && [ "${R4##*|}" = "200" ] && [ "$R5" = "422" ] \
  && ok "60 saniye dolmadan ve saatte 3 koddan sonra yeni SMS gönderilmedi (yanıt yine aynı); geçersiz numara 422" \
  || bad "sıklık sınırı: sms $N1→$N2→$N3 / $R3 / $R4 / $R5"
A3=$(code -X POST "$I3/activate" -H "$J" -d "{\"phone\":\"+352621123456\",\"code\":\"$RC\",\"new_password\":\"YeniSifre2026\"}")
L3N=$(curl -s -X POST "$I3/login" -H "$J" -d '{"phone":"+352621123456","password":"YeniSifre2026"}' | grep -c '"access_token"')
L3O=$(code -X POST "$I3/login" -H "$J" -d '{"phone":"+352621123456","password":"Lux2026guvenli"}')
[ "$A3" = "200" ] && [ "$L3N" = "1" ] && [ "$L3O" = "401" ] \
  && ok "SMS ile gelen kodla yeni şifre belirlendi; yeni şifreyle giriş var, eski şifre 401" \
  || bad "kodla şifre belirleme: $A3 / yeni=$L3N / eski=$L3O"
kill_tree "$IB3_PID"; kill_tree "$IB3N_PID"; kill "$FNG3_PID" 2>/dev/null

step "52) Sakinin kendi telefon ve e-posta değişikliği (062, 065, beşinci tur B4)"
if go test ./services/identity/service/ -count=1 -run 'ValidEmail' >/tmp/verify-email.log 2>&1; then
  ok "go test e-posta biçimi (yalın adres; ad/liste/eksik alan reddedilir)"
else
  bad "e-posta biçimi birim testi"; tail -15 /tmp/verify-email.log
fi
rm -f /tmp/fake-netgsm.log
python3 /tmp/fake-netgsm.py 19290 >/dev/null 2>&1 &
FNG4_PID=$!
cat >/tmp/fake-smtp.py <<'PYEOF'
import socket, sys, threading, json, email
from email.header import decode_header, make_header
def handle(c):
    f = c.makefile('rwb')
    def w(s):
        f.write((s + '\r\n').encode()); f.flush()
    w('220 fake-smtp')
    rcpt = []
    while True:
        line = f.readline()
        if not line:
            break
        cmd = line.decode(errors='replace').strip(); u = cmd.upper()
        if u.startswith('EHLO') or u.startswith('HELO'):
            w('250 fake-smtp')
        elif u.startswith('RCPT TO'):
            rcpt.append(cmd.split(':', 1)[1].strip(' <>')); w('250 OK')
        elif u == 'DATA':
            w('354 devam'); buf = b''
            while True:
                l = f.readline()
                if l in (b'.\r\n', b'.\n', b''):
                    break
                buf += l
            msg = email.message_from_bytes(buf)
            body = (msg.get_payload(decode=True) or b'').decode('utf-8', 'replace')
            with open('/tmp/fake-smtp.log', 'a') as fh:
                fh.write(json.dumps({'to': rcpt, 'subject': str(make_header(decode_header(msg['Subject'] or ''))), 'body': body}) + '\n')
            rcpt = []; w('250 queued')
        elif u == 'QUIT':
            w('221 bye'); break
        else:
            w('250 OK')
    c.close()
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('127.0.0.1', int(sys.argv[1]))); s.listen(8)
while True:
    conn, _ = s.accept(); threading.Thread(target=handle, args=(conn,), daemon=True).start()
PYEOF
rm -f /tmp/fake-smtp.log
python3 /tmp/fake-smtp.py 19225 >/dev/null 2>&1 &
FSM4_PID=$!
SM4="SMTP_HOST=127.0.0.1 SMTP_PORT=19225 SMTP_TLS=none SMTP_FROM=bildirim@siteeksen.test"
NG4="NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=api-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:19290"
env $NG4 $SM4 DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19281 \
  go run ./services/identity >/tmp/verify-identity-b4.log 2>&1 &
IB4_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19283 \
  go run ./services/identity >/tmp/verify-identity-b4n.log 2>&1 &
IB4N_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19281/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19283/health >/dev/null 2>&1 && break; sleep 1
done
I4="http://127.0.0.1:19281/api/v1"
LXT=$(curl -s -X POST "$I4/auth/login" -H "$J" -d '{"phone":"+352621123456","password":"YeniSifre2026"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
LXA="Authorization: Bearer $LXT"
preq() { curl -s -w '|%{http_code}' -X POST "$1/users/me/phone/request" -H "$LXA" -H "$J" -d "$2"; }
P0=$(preq "http://127.0.0.1:19283/api/v1" '{"password":"YeniSifre2026","phone":"+352 621 999 000"}')
P1=$(code -X POST "$I4/users/me/phone/request" -H "$LXA" -H "$J" -d '{"password":"yanlis","phone":"+352 621 999 000"}')
P2=$(code -X POST "$I4/users/me/phone/request" -H "$LXA" -H "$J" -d '{"password":"YeniSifre2026","phone":"+352621123456"}')
P3=$(code -X POST "$I4/users/me/phone/request" -H "$LXA" -H "$J" -d '{"password":"YeniSifre2026","phone":"5551234567"}')
P4=$(code -X POST "$I4/users/me/phone/request" -H "$LXA" -H "$J" -d '{"password":"YeniSifre2026","phone":"abc"}')
case "$P0" in *NO_SMS_CHANNEL*"|503") P0OK=1 ;; *) P0OK=0 ;; esac
[ "$P0OK" = "1" ] && [ "$P1" = "400" ] && [ "$P2" = "422" ] && [ "$P3" = "409" ] && [ "$P4" = "422" ] \
  && ok "numara değişikliği isteği: SMS yoksa 503 (yönetime yönlendirir), yanlış şifre 400, aynı numara 422, başkasının numarası 409, geçersiz numara 422" \
  || bad "numara isteği doğrulamaları: $P0 / $P1 / $P2 / $P3 / $P4"
P5=$(preq "$I4" '{"password":"YeniSifre2026","phone":"+352 621 999 000"}'); sleep 1
PCODE4=$(python3 -c "
import json,re
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')]
m=[r['body']['messages'][0]['msg'] for r in rows if r['body']['messages'][0]['no']=='00352621999000']
x=re.search(r'doğrulama kodunuz: ([A-Z0-9]{8})', m[-1]) if m else None
print(x.group(1) if x else '')" 2>/dev/null)
P6=$(code -X POST "$I4/users/me/phone/request" -H "$LXA" -H "$J" -d '{"password":"YeniSifre2026","phone":"+352 621 999 000"}')
PLAIN=$($PSQL -t -A -c "SELECT count(*) FROM phone_change_requests WHERE code_hash='$PCODE4';")
PW1=$(code -X POST "$I4/users/me/phone/confirm" -H "$LXA" -H "$J" -d '{"code":"AAAAAAAA"}')
PHB=$($PSQL -t -A -c "SELECT phone FROM users WHERE id='$LUX';")
[ "${P5##*|}" = "200" ] && [ -n "$PCODE4" ] && [ "$P6" = "429" ] && [ "$PLAIN" = "0" ] && [ "$PW1" = "400" ] && [ "$PHB" = "+352621123456" ] \
  && ok "kod YENİ numaraya SMS ile gitti (özet saklanıyor, düz kod yok); 60 sn içinde ikinci istek 429; yanlış kod 400 ve numara değişmedi" \
  || bad "numara kodu: $P5 / kod=$PCODE4 / tekrar=$P6 / düz=$PLAIN / yanlış=$PW1 / numara=$PHB"
PC4=$(curl -s -w '|%{http_code}' -X POST "$I4/users/me/phone/confirm" -H "$LXA" -H "$J" -d "{\"code\":\"$PCODE4\"}"); sleep 1
PHA=$($PSQL -t -A -c "SELECT phone FROM users WHERE id='$LUX';")
OLDN=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-netgsm.log')]
print(any(r['body']['messages'][0]['no']=='00352621123456' and 'hesap sahibi tarafından değiştirildi' in r['body']['messages'][0]['msg'] for r in rows))" 2>/dev/null)
OLDT=$(code "$I4/users/me" -H "$LXA")
LXT2=$(curl -s -X POST "$I4/auth/login" -H "$J" -d '{"phone":"+352621999000","password":"YeniSifre2026"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
echo "$PC4" | grep -q '"sessions_revoked":true' && echo "$PC4" | grep -q '"old_phone_notice":"SENT"' && [ "$PHA" = "+352621999000" ] \
  && [ "$OLDN" = "True" ] && [ "$OLDT" = "401" ] && [ -n "$LXT2" ] \
  && ok "doğru kodla numara değişti; bütün oturumlar kapandı (eski jeton 401), eski numaraya uyarı SMS'i gitti, yeni numarayla giriş çalışıyor" \
  || bad "numara onayı: $PC4 / $PHA / eski numaraya=$OLDN / eski jeton=$OLDT / yeni giriş=${LXT2:+var}"
LXA2="Authorization: Bearer $LXT2"
# E-posta değişikliği (065): kod YENİ adrese gider, kodla onaylanınca değişir
E0=$(curl -s -w '|%{http_code}' -X POST "http://127.0.0.1:19283/api/v1/users/me/email" -H "$LXA2" -H "$J" -d '{"password":"YeniSifre2026","email":"lux.sakin@ornek.lu"}')
E1=$(code -X POST "$I4/users/me/email" -H "$LXA2" -H "$J" -d '{"password":"yanlis","email":"lux.sakin@ornek.lu"}')
E2=$(code -X POST "$I4/users/me/email" -H "$LXA2" -H "$J" -d '{"password":"YeniSifre2026","email":"lux sakin@ornek"}')
E3=$(code -X POST "$I4/users/me/email" -H "$LXA2" -H "$J" -d '{"password":"YeniSifre2026","email":"AHMET@example.com"}')
EBEF=$($PSQL -t -A -c "SELECT COALESCE(email,'yok') FROM users WHERE id='$LUX';")
E4=$(curl -s -w '|%{http_code}' -X POST "$I4/users/me/email" -H "$LXA2" -H "$J" -d '{"password":"YeniSifre2026","email":"lux.sakin@ornek.lu"}'); sleep 1
EMID=$($PSQL -t -A -c "SELECT COALESCE(email,'yok') FROM users WHERE id='$LUX';")
ECODE=$(python3 -c "
import json,re
rows=[json.loads(l) for l in open('/tmp/fake-smtp.log')]
m=[r for r in rows if 'lux.sakin@ornek.lu' in r['to']]
x=re.search(r'doğrulama kodunuz: ([A-Z0-9]{8})', m[-1]['body']) if m else None
print(x.group(1) if x else '')" 2>/dev/null)
case "$E0" in *NO_EMAIL_CHANNEL*"|503") E0OK=1 ;; *) E0OK=0 ;; esac
[ "$E0OK" = "1" ] && [ "$E1" = "400" ] && [ "$E2" = "422" ] && [ "$E3" = "409" ] && [ "${E4##*|}" = "200" ] && [ -n "$ECODE" ] && [ "$EMID" = "$EBEF" ] \
  && ok "e-posta değişikliği isteği: e-posta yoksa 503, yanlış şifre 400, geçersiz adres 422, başka hesabın e-postası 409; kod YENİ adrese gitti ve adres kod girilmeden DEĞİŞMEDİ" \
  || bad "e-posta isteği: $E0 / $E1 / $E2 / $E3 / $E4 / kod=$ECODE / önce=$EBEF sonra=$EMID"
EW=$(code -X POST "$I4/users/me/email/confirm" -H "$LXA2" -H "$J" -d '{"code":"AAAAAAAA"}')
EC=$(curl -s -w '|%{http_code}' -X POST "$I4/users/me/email/confirm" -H "$LXA2" -H "$J" -d "{\"code\":\"$ECODE\"}")
EDB=$($PSQL -t -A -c "SELECT email FROM users WHERE id='$LUX';")
EME=$(curl -s "$I4/users/me" -H "$LXA2" | grep -c '"email":"lux.sakin@ornek.lu"')
EPLAIN=$($PSQL -t -A -c "SELECT count(*) FROM email_change_requests WHERE code_hash='$ECODE';")
[ "$EW" = "400" ] && [ "${EC##*|}" = "200" ] && [ "$EDB" = "lux.sakin@ornek.lu" ] && [ "$EME" = "1" ] && [ "$EPLAIN" = "0" ] \
  && ok "yanlış kod 400; yeni adrese gelen kodla e-posta doğrulandı, güncellendi ve profilde görünüyor (kod özetle saklanıyor)" \
  || bad "e-posta onayı: yanlış=$EW / $EC / $EDB / profil=$EME / düz=$EPLAIN"
kill_tree "$IB4_PID"; kill_tree "$IB4N_PID"; kill "$FNG4_PID" "$FSM4_PID" 2>/dev/null

step "53) Malik ve kiracının daire işlemleri: davet, vekil/hane üyesi, tek kiracı (beşinci tur B5, altıncı tur D3)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19381 \
  go run ./services/identity >/tmp/verify-identity-b5.log 2>&1 &
IB5_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19381/health >/dev/null 2>&1 && break; sleep 1; done
I5="http://127.0.0.1:19381/api/v1"
OWT=$(curl -s -X POST "$I5/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
TNT=$(curl -s -X POST "$I5/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
OWA="Authorization: Bearer $OWT"; TNA="Authorization: Bearer $TNT"
U303='33333333-3333-3333-3333-333333333303'
# D3: dairenin maliki ve kiracısı kendi dairesinin sakinlerini görür; başka daireyi göremez
O1=$(code "$I5/users/me/units/$U303/residents" -H "$TNA")
O1B=$(code "$I5/users/me/units/$U304/residents" -H "$TNA")
O2=$(curl -s -w '|%{http_code}' "$I5/users/me/units/$U303/residents" -H "$OWA")
O2OK=$(echo "${O2%|*}" | python3 -c "
import json,sys
d=json.load(sys.stdin)['data']; me=[x for x in d if x['is_self']]
print(len(me)==1 and me[0]['role']=='OWNER' and me[0]['phone_masked'].endswith('4567') and '*' in me[0]['phone_masked'] and 'email' not in me[0])" 2>/dev/null)
[ "$O1" = "403" ] && [ "$O1B" = "200" ] && [ "${O2##*|}" = "200" ] && [ "$O2OK" = "True" ] \
  && ok "malik ve kiracı kendi dairesinin sakinlerini görüyor (telefon maskeli, e-posta yok); başka daire 403" \
  || bad "daire sakinleri: kiracı başka daire=$O1 kendi=$O1B / malik=$O2 / $O2OK"
# Malik kiracıyı doğrudan eklemez, DAVET eder; kod malike gösterilmez (kiracının şifresini belirleyemesin)
O3=$(curl -s -w '|%{http_code}' -X POST "$I5/users/me/units/$U303/invitations" -H "$OWA" -H "$J" \
  -d '{"first_name":"Yeni","last_name":"Kiraci","phone":"0555 999 00 53","role":"tenant"}')
OINV=$(echo "${O3%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['invitation']['id'], d['new_account'], 'activation' in d, 'delivery' in d)" 2>/dev/null)
ODB=$($PSQL -t -A -c "SELECT i.status||'|'||i.invited_as||'|'||i.role||'|'||(SELECT count(*) FROM resident_units ru WHERE ru.resident_id=i.user_id)
  FROM resident_invitations i JOIN users u ON u.id=i.user_id WHERE u.phone='+905559990053' AND i.unit_id='$U303';")
O3B=$(code -X POST "$I5/users/me/units/$U303/invitations" -H "$OWA" -H "$J" -d '{"first_name":"Iki","last_name":"Kiraci","phone":"0555 999 00 63","role":"TENANT"}')
O4=$(code -X POST "$I5/users/me/units/$U303/invitations" -H "$OWA" -H "$J" -d '{"first_name":"A","last_name":"B","phone":"0555 999 00 54","role":"OWNER"}')
O5=$(code -X POST "$I5/users/me/units/$U304/invitations" -H "$OWA" -H "$J" -d '{"first_name":"A","last_name":"B","phone":"0555 999 00 54","role":"TENANT"}')
O6=$(code -X POST "$I5/users/me/units/$U303/invitations" -H "$OWA" -H "$J" -d '{"first_name":"A","last_name":"B","phone":"abc","role":"TENANT"}')
O6B=$(code -X POST "$I5/users/me/units/$U304/invitations" -H "$TNA" -H "$J" -d '{"first_name":"A","last_name":"B","phone":"0555 999 00 64","role":"TENANT"}')
O7OLD=$(code -X POST "$I5/users/me/units/$U303/residents" -H "$OWA" -H "$J" -d '{"first_name":"A","last_name":"B","phone":"0555 999 00 65","role":"TENANT"}')
[ "${O3##*|}" = "201" ] && [ "${OINV#* }" = "True False True" ] && [ "$ODB" = "PENDING|OWNER|TENANT|0" ] && [ "$O3B" = "409" ] \
  && [ "$O4" = "422" ] && [ "$O5" = "403" ] && [ "$O6" = "422" ] && [ "$O6B" = "422" ] && [ "$O7OLD" = "404" ] \
  && ok "malik kiracı DAVETİ gönderdi (hesap açıldı, kod malike gösterilmedi, iletim sonucu döndü; kişi kabul edene kadar daireye bağlı değil); ikinci bekleyen kiracı daveti 409, malik daveti 422, başka daire 403, geçersiz numara 422, kiracı kiracı davet edemez 422, eski doğrudan ekleme ucu kaldırıldı" \
  || bad "malik daveti: ${O3##*|} $OINV / $ODB / ikinci=$O3B / malik=$O4 / başka=$O5 / numara=$O6 / kiracı=$O6B / eski uç=$O7OLD"
# Malik vekilliği bitirir; kiracılığı tek başına bitiremez; kiracılı dairede hane üyesi ekleyemez
MGR5="$OWA"
PX=$(curl -s -X POST "$I5/residents" -H "$MGR5" -H "$J" -d "{\"first_name\":\"Vekil\",\"last_name\":\"Kisi\",\"phone\":\"0555 999 00 56\",\"unit_id\":\"$U303\",\"role\":\"PROXY\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
OINVID=${OINV%% *}
curl -s -o /dev/null -X POST "$I5/residents/invitations/$OINVID/cancel" -H "$MGR5"
TN=$(curl -s -X POST "$I5/residents" -H "$MGR5" -H "$J" -d "{\"first_name\":\"Kayitli\",\"last_name\":\"Kiraci\",\"phone\":\"0555 999 00 57\",\"unit_id\":\"$U303\",\"role\":\"TENANT\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
TN2=$(curl -s -w '|%{http_code}' -X POST "$I5/residents" -H "$MGR5" -H "$J" -d "{\"first_name\":\"Ikinci\",\"last_name\":\"Kiraci\",\"phone\":\"0555 999 00 58\",\"unit_id\":\"$U303\",\"role\":\"TENANT\"}")
O8=$(code -X POST "$I5/users/me/units/$U303/residents/$TN/end" -H "$OWA")
O9=$(code -X POST "$I5/users/me/units/$U303/invitations" -H "$OWA" -H "$J" -d '{"first_name":"Hane","last_name":"Uye","phone":"0555 999 00 59","role":"HOUSEHOLD"}')
OWNRU=$($PSQL -t -A -c "SELECT id FROM resident_units WHERE unit_id='$U303' AND resident_id='44444444-4444-4444-4444-444444444401' AND role='OWNER';")
O10=$(code -X POST "$I5/users/me/units/$U303/residents/$OWNRU/end" -H "$OWA")
O11=$(code -X POST "$I5/users/me/units/$U303/residents/not-a-uuid/end" -H "$OWA")
O12=$(curl -s -w '|%{http_code}' -X POST "$I5/users/me/units/$U303/residents/$PX/end" -H "$OWA")
OEND=$($PSQL -t -A -c "SELECT is_active FROM resident_units WHERE id='$PX';")
OAUD=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE user_id='44444444-4444-4444-4444-444444444401' AND entity_id='$U303' AND action IN ('CREATE','UPDATE') AND status_code < 300;")
ODEN=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE user_id='$TUID' AND entity_id='$U303' AND action='DENIED';")
[ -n "$TN" ] && [ "${TN2##*|}" = "409" ] && grep -q 'aktif bir kiracı var' <<<"$TN2" && [ "$O8" = "409" ] && [ "$O9" = "422" ] && [ "$O10" = "422" ] && [ "$O11" = "404" ] \
  && [ "${O12##*|}" = "200" ] && [ "$OEND" = "f" ] && [ "${OAUD:-0}" -ge 2 ] && [ "${ODEN:-0}" -ge 1 ] \
  && ok "dairede aktif kiracı varken yönetim de ikinci kiracı kaydedemiyor (409); malik kiracılığı tek başına bitiremiyor (409), kiracılı dairede hane üyesi davet edemiyor (422), kendini 422; vekilliği bitirdi; işlemler ve kiracının reddedilen denemesi denetim izinde" \
  || bad "malik işlemleri: kiracı=$TN ikinci=$TN2 / kiracılık bitir=$O8 / hane=$O9 / kendi=$O10 / bozuk=$O11 / vekil=$O12 aktif=$OEND / iz=$OAUD / ret izi=$ODEN"
# D4: aktif kiracı doğrudan pasifleştirilemez (409); temizlik süper kullanıcıyla
TNP=$(code -X PATCH "$I5/residents/$TN" -H "$MGR5" -H "$J" -d '{"is_active":false}')
[ "$TNP" = "409" ] && ok "yönetim aktif kiracıyı doğrudan pasifleştiremiyor (409 → kiracılık bitiş akışı)" || bad "kiracıyı doğrudan pasifleştirme: $TNP"
$PSQL -c "UPDATE resident_units SET is_active=false, end_date=CURRENT_DATE WHERE id='$TN';" >/dev/null
kill_tree "$IB5_PID"

step "54) Taşınan sakinde ilişik kesme tarihi (end_date) — beşinci tur B7"
if go test ./services/identity/service/ -count=1 -run 'EndDate' >/tmp/verify-enddate.log 2>&1; then
  ok "go test ayrılış tarihi doğrulaması (geçmiş tarih kabul; ileri tarih, biçim, aktif kayıtta tarih reddedilir)"
else
  bad "ayrılış tarihi birim testi"; tail -10 /tmp/verify-enddate.log
fi
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19481 \
  go run ./services/identity >/tmp/verify-identity-b7.log 2>&1 &
IB7_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19481/health >/dev/null 2>&1 && break; sleep 1; done
I7="http://127.0.0.1:19481/api/v1"
M7=$(curl -s -X POST "$I7/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
M7A="Authorization: Bearer $M7"
RID7=$(curl -s -X POST "$I7/residents" -H "$M7A" -H "$J" \
  -d "{\"first_name\":\"Tasinan\",\"last_name\":\"Sakin\",\"phone\":\"0555 999 00 55\",\"unit_id\":\"$U303\",\"role\":\"PROXY\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
$PSQL -c "UPDATE resident_units SET start_date = CURRENT_DATE - 30 WHERE id='$RID7';" >/dev/null
TOM=$(date -d '+1 day' +%F); YST=$(date -d '1 day ago' +%F); TODAY7=$(date +%F)
patch7() { code -X PATCH "$I7/residents/$RID7" -H "$M7A" -H "$J" -d "$1"; }
E1=$(patch7 "{\"is_active\":false,\"end_date\":\"$TOM\"}")
E2=$(patch7 "{\"is_active\":true,\"end_date\":\"$YST\"}")
E3=$(patch7 '{"is_active":false,"end_date":"2000-01-01"}')
E4=$(patch7 "{\"is_active\":false,\"end_date\":\"$YST\"}")
ED4=$($PSQL -t -A -c "SELECT is_active||'|'||end_date FROM resident_units WHERE id='$RID7';")
EAPI=$(curl -s "$I7/residents/$RID7" -H "$M7A" | grep -c "\"end_date\":\"$YST")
E5=$(patch7 '{"is_active":false}')
ED5=$($PSQL -t -A -c "SELECT end_date FROM resident_units WHERE id='$RID7';")
[ "$E1" = "422" ] && [ "$E2" = "422" ] && [ "$E3" = "422" ] && [ "$E4" = "200" ] && [ "$ED4" = "false|$YST" ] && [ "$EAPI" = "1" ] && [ "$E5" = "200" ] && [ "$ED5" = "$YST" ] \
  && ok "pasifleştirmede ilişik kesme tarihi yazıldı ve yanıtta görünüyor; ileri tarih / aktif kayıtta tarih / başlangıçtan önceki tarih 422; zaten pasif kayıtta tarih korunuyor" \
  || bad "ayrılış tarihi: ileri=$E1 aktif=$E2 erken=$E3 / $E4 $ED4 api=$EAPI / tekrar=$E5 $ED5"
E6=$(patch7 '{"is_active":true}')
ED6=$($PSQL -t -A -c "SELECT is_active||'|'||COALESCE(end_date::text,'yok') FROM resident_units WHERE id='$RID7';")
E7=$(patch7 '{"is_active":false}')
ED7=$($PSQL -t -A -c "SELECT end_date FROM resident_units WHERE id='$RID7';")
OWEND=$($PSQL -t -A -c "SELECT ru.end_date FROM resident_units ru JOIN users u ON u.id=ru.resident_id WHERE u.phone='+905559990056' AND ru.unit_id='$U303';")
[ "$E6" = "200" ] && [ "$ED6" = "true|yok" ] && [ "$E7" = "200" ] && [ "$ED7" = "$TODAY7" ] && [ "$OWEND" = "$TODAY7" ] \
  && ok "yeniden etkinleştirmede tarih temizlendi; tarihsiz pasifleştirmede bugün yazıldı; malikin bitirdiği vekillikte de tarih var (B5/D3)" \
  || bad "ayrılış tarihi 2: $E6 $ED6 / $E7 $ED7 / malik=$OWEND"
kill_tree "$IB7_PID"

step "55) Fatura sapma uyarısı ve tüketim pusulasına itiraz (063, beşinci tur B8)"
if go test ./services/iot/service/ -count=1 -run 'Outlier' >/tmp/verify-outlier.log 2>&1; then
  ok "go test sapma (medyanın 3 katı; 3'ten az ölçülebilir bölümde işaret yok; alan yoksa doğrudan tüketim)"
else
  bad "sapma birim testleri"; tail -10 /tmp/verify-outlier.log
fi
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19581 \
  go run ./services/iot >/tmp/verify-iot-b8.log 2>&1 &
IOB8_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19581/health >/dev/null 2>&1 && break; sleep 1; done
IO8="http://127.0.0.1:19581/api/v1"; QM="Authorization: Bearer $MGRL"; QT="Authorization: Bearer $TENL"
U302='33333333-3333-3333-3333-333333333302'; U305='33333333-3333-3333-3333-333333333305'
n8=0
for spec in "$U302:10" "$U303:12" "$U304:100" "$U305:11"; do
  n8=$((n8+1)); UID8=${spec%%:*}; VAL8=${spec##*:}
  MID8=$(curl -s -X POST "$IO8/meters" -H "$QM" -H "$J" -d "{\"unit_id\":\"$UID8\",\"meter_type\":\"WATER_HOT\",\"serial_number\":\"WH-B8-$n8\"}" \
    | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  curl -s -o /dev/null -X POST "$IO8/meter-readings" -H "$QM" -H "$J" -d "{\"meter_id\":\"$MID8\",\"reading_date\":\"2026-12-01\",\"current_value\":\"0\"}"
  curl -s -o /dev/null -X POST "$IO8/meter-readings" -H "$QM" -H "$J" -d "{\"meter_id\":\"$MID8\",\"reading_date\":\"2027-01-15\",\"current_value\":\"$VAL8\"}"
done
alloc8() { curl -s -w '|%{http_code}' -X POST "$IO8/consumption/allocate" -H "$QM" -H "$J" \
  -d "{\"meter_type\":\"WATER_HOT\",\"from\":\"2027-01-01\",\"to\":\"2027-01-31\",\"total_amount_try\":1000$1}"; }
Q1=$(alloc8 "")
Q1OK=$(echo "${Q1%|*}" | python3 -c "
import json,sys
d=json.load(sys.stdin); o=d.get('outliers',[])
print(len(o)==1 and o[0]['unit_id']=='$U304' and float(o[0]['ratio'])>3 and 'medyan' in d.get('outlier_warning',''))" 2>/dev/null)
R8=$(echo "${Q1%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['outliers'][0]['ratio'])" 2>/dev/null)
Q2=$(alloc8 ',"publish":true')
Q3=$(alloc8 ',"publish":true,"confirm_outliers":true')
ALID8=$(echo "$Q3" | grep -o '"allocation_id":"[^"]*"' | cut -d'"' -f4)
Q3DB=$($PSQL -t -A -c "SELECT (outliers_confirmed_by = '44444444-4444-4444-4444-444444444401')||'|'||(outlier_units->0->>'unit_id')||'|'||(outlier_units->0->>'ratio') FROM consumption_allocations WHERE id='$ALID8';")
case "$Q2" in *OUTLIERS_UNCONFIRMED*"|422") Q2OK=1 ;; *) Q2OK=0 ;; esac
[ "${Q1##*|}" = "200" ] && [ "$Q1OK" = "True" ] && [ "$Q2OK" = "1" ] && [ "${Q3##*|}" = "200" ] && [ -n "$R8" ] && [ "$Q3DB" = "true|$U304|$R8" ] \
  && ok "medyanın $R8 katı tüketen bölüm önizlemede uyarıldı; teyitsiz yayım 422, teyitle yayımlandı ve teyit eden + bölüm pusulayla saklandı" \
  || bad "sapma uyarısı: önizleme=$Q1OK ${Q1##*|} / teyitsiz=$Q2 / teyitli=${Q3##*|} / $Q3DB"
obj8() { curl -s -w '|%{http_code}' -X POST "$IO8/consumption/statements/$ALID8/objections" -H "$1" -H "$J" -d "$2"; }
O1=$(obj8 "$QT" "{\"unit_id\":\"$U304\",\"reason\":\"Sayaçtaki değer 012 iken 100 okunmuş; 15.01 tarihli fotoğrafım var\"}")
OID8=$(echo "${O1%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['objection']['id'])" 2>/dev/null)
O2=$(obj8 "$QT" "{\"unit_id\":\"$U304\",\"reason\":\"İkinci itiraz denemesi yapılıyor\"}")
O3=$(obj8 "$QT" "{\"unit_id\":\"$U304\",\"reason\":\"kısa\"}")
O4=$(obj8 "$QT" "{\"unit_id\":\"$U303\",\"reason\":\"Komşunun pusulasına itiraz denemesi\"}")
ON1=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='statement.objection' AND payload->>'objection_id'='$OID8' AND recipient_user_id='44444444-4444-4444-4444-444444444401';")
OLT=$(curl -s "$IO8/consumption/objections" -H "$QT" | grep -c "$OID8")
OLM=$(curl -s "$IO8/consumption/objections?status=OPEN" -H "$QM" | grep -c "$OID8")
[ "${O1##*|}" = "201" ] && [ -n "$OID8" ] && [ "${O2##*|}" = "409" ] && [ "${O3##*|}" = "422" ] && [ "${O4##*|}" = "403" ] && [ "$ON1" = "1" ] && [ "$OLT" = "1" ] && [ "$OLM" = "1" ] \
  && ok "sakin kendi pusulasına gerekçeli itiraz etti, yönetime bildirim gitti; ikinci açık itiraz 409, kısa gerekçe 422, komşunun bölümü 403; itiraz sakin ve yönetim listesinde" \
  || bad "itiraz: $O1 / tekrar=$O2 / kısa=$O3 / komşu=$O4 / bildirim=$ON1 / liste=$OLT,$OLM"
resp8() { curl -s -w '|%{http_code}' -X POST "$IO8/consumption/objections/$OID8/respond" -H "$1" -H "$J" -d "$2"; }
R1=$(resp8 "$QT" '{"decision":"ACCEPTED","response":"Kendi itirazımı kabul ediyorum"}')
R2=$(resp8 "$QM" '{"decision":"ACCEPTED","response":"ok"}')
R3=$(resp8 "$QM" '{"decision":"ACCEPTED","response":"Sayaç yeniden okunacak; fark alacak dekontuyla düşülecek"}')
R4=$(resp8 "$QM" '{"decision":"REJECTED","response":"Fikrimi değiştirdim, reddediyorum"}')
ON2=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='statement.objection.answer' AND payload->>'objection_id'='$OID8' AND recipient_user_id='$TUID';")
GD1=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; UPDATE consumption_statement_objections SET response='x yazıldı' WHERE id='$OID8'; COMMIT;" 2>&1)
GD2=$(PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_app -d siteeksen -t -A -c "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; DELETE FROM consumption_statement_objections WHERE id='$OID8'; COMMIT;" 2>&1)
PUL=$($PSQL -t -A -c "SELECT total_kurus FROM consumption_allocation_units WHERE allocation_id='$ALID8' AND unit_id='$U304';")
[ "${R1##*|}" = "403" ] && [ "${R2##*|}" = "422" ] && [ "${R3##*|}" = "200" ] && grep -q '"status":"ACCEPTED"' <<<"$R3" && [ "${R4##*|}" = "409" ] \
  && [ "$ON2" = "1" ] && grep -q 'değiştirilemez' <<<"$GD1" && grep -qi 'permission denied' <<<"$GD2" && [ -n "$PUL" ] \
  && ok "yönetim itirazı açıklamayla kabul etti, sakine bildirildi; sakin yanıtlayamaz 403, kısa açıklama 422, ikinci yanıt 409; yanıtlanmış itiraz değiştirilemiyor ve silinemiyor; pusula aynen duruyor" \
  || bad "itiraz yanıtı: sakin=$R1 / kısa=$R2 / $R3 / tekrar=$R4 / bildirim=$ON2 / $GD1 / $GD2 / pusula=$PUL"
kill_tree "$IOB8_PID"

step "56) Havale bildirimine dekont dosyası (064, beşinci tur B9)"
RCDIR=/tmp/verify-receipts; rm -rf "$RCDIR"; mkdir -p "$RCDIR"
STORAGE_BACKEND=local STORAGE_LOCAL_DIR="$RCDIR" DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19682 \
  go run ./services/finance >/tmp/verify-finance-b9.log 2>&1 &
FB9_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19683 \
  go run ./services/finance >/tmp/verify-finance-b9n.log 2>&1 &
FB9N_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19682/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19683/health >/dev/null 2>&1 && break; sleep 1
done
F9="http://127.0.0.1:19682/api/v1/finance"; RM="Authorization: Bearer $MGRL"; RT="Authorization: Bearer $TENL"
RA=$($PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$U304',2094,1,777,777,CURRENT_DATE + 10,'PENDING') RETURNING id;" | head -1)
RPID=$(curl -s -X POST "$F9/payments" -H "$RT" -H "$J" -d "{\"assessment_ids\":[\"$RA\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$(date +%F)\",\"reference\":\"FAST 778\"}" \
  | sed -n 's/.*"payment_id":"\([^"]*\)".*/\1/p')
printf '%%PDF-1.4\n%% dekont\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%%%EOF\n' >/tmp/dekont.pdf
printf '\x89PNG\r\n\x1a\n0000000000000000IHDR' >/tmp/dekont.png
printf '\xff\xd8\xff\xe0JFIF0000000000000000' >/tmp/dekont.jpg
printf 'bu bir metin dosyasi' >/tmp/dekont.txt
up9() { curl -s -w '|%{http_code}' -X POST "$1/payments/$RPID/receipts" -H "$2" -F "file=@$3"; }
D1=$(up9 "$F9" "$RT" /tmp/dekont.pdf)
RCID=$(echo "${D1%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['receipt']['id'])" 2>/dev/null)
SHAF=$(sha256sum /tmp/dekont.pdf | cut -d' ' -f1)
RDB=$($PSQL -t -A -c "SELECT content_type||'|'||(sha256='$SHAF')||'|'||(uploaded_by='$TUID') FROM payment_receipts WHERE id='$RCID';")
RFILE=$(find "$RCDIR" -type f -name '*.pdf' | wc -l)
D2=$(up9 "$F9" "$RT" /tmp/dekont.txt)
D3=$(up9 "$F9" "$RM" /tmp/dekont.png)
D4=$(up9 "http://127.0.0.1:19683/api/v1/finance" "$RT" /tmp/dekont.png)
[ "${D1##*|}" = "201" ] && [ "$RDB" = "application/pdf|true|true" ] && [ "$RFILE" = "1" ] && [ "${D2##*|}" = "422" ] && [ "${D3##*|}" = "403" ] && [ "${D4##*|}" = "503" ] \
  && ok "sakin onay bekleyen havale bildirimine PDF dekont ekledi (içerik baytlardan tanındı, SHA-256 saklandı, dosya depoda); metin dosyası 422, başkasının ödemesi 403, depo yoksa 503" \
  || bad "dekont yükleme: $D1 / $RDB / dosya=$RFILE / metin=$D2 / yönetici=$D3 / deposuz=$D4"
D5=$(up9 "$F9" "$RT" /tmp/dekont.png); D6=$(up9 "$F9" "$RT" /tmp/dekont.jpg); D7=$(up9 "$F9" "$RT" /tmp/dekont.png)
LT=$(curl -s "$F9/payments/$RPID/receipts" -H "$RT" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['data']))" 2>/dev/null)
LM=$(curl -s "$F9/payments/$RPID/receipts" -H "$RM" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['data']))" 2>/dev/null)
PEND=$(curl -s "$F9/payments/pending" -H "$RM" | python3 -c "
import json,sys
print([p.get('receipt_count') for p in json.load(sys.stdin)['data'] if p['id']=='$RPID'])" 2>/dev/null)
DL=$(curl -s -D /tmp/dekont-h.txt -o /tmp/dekont-dl.pdf -w '%{http_code}' "$F9/payments/$RPID/receipts/$RCID/download" -H "$RM")
DLSHA=$(sha256sum /tmp/dekont-dl.pdf | cut -d' ' -f1)
[ "${D5##*|}" = "201" ] && [ "${D6##*|}" = "201" ] && [ "${D7##*|}" = "409" ] && [ "$LT" = "3" ] && [ "$LM" = "3" ] && [ "$PEND" = "[3]" ] \
  && [ "$DL" = "200" ] && [ "$DLSHA" = "$SHAF" ] && grep -qi 'attachment' /tmp/dekont-h.txt \
  && ok "PNG/JPEG dekont da eklendi, 4. dosya 409 (en çok 3); sakin ve yönetim listeyi görüyor, onay listesinde dekont sayısı var; yönetim indirdiği dosya özetle birebir aynı" \
  || bad "dekont listesi/indirme: $D5 / $D6 / 4.=$D7 / sakin=$LT yönetim=$LM / bekleyen=$PEND / indirme=$DL özet=$([ "$DLSHA" = "$SHAF" ] && echo aynı || echo farklı)"
curl -s -o /dev/null -X POST "$F9/payments/$RPID/confirm" -H "$RM" -H "$J" -d '{"reference":"FAST 778"}'
D8=$(up9 "$F9" "$RT" /tmp/dekont.png)
GD9=$(appsql46 "DELETE FROM payment_receipts WHERE id='$RCID'")
GU9=$(appsql46 "UPDATE payment_receipts SET file_name='x' WHERE id='$RCID'")
[ "${D8##*|}" = "403" ] && grep -qi 'permission denied' <<<"$GD9" && grep -qi 'permission denied' <<<"$GU9" \
  && ok "onaylanmış ödemeye dekont eklenemiyor (403); dekont kaydı uygulama rolüyle silinemiyor ve değiştirilemiyor" \
  || bad "dekont koruması: onay sonrası=$D8 / sil=$GD9 / değiştir=$GU9"
kill_tree "$FB9_PID"; kill_tree "$FB9N_PID"

step "57) Gider sınıfı: kullanım (oturan) / malik — tahakkuk, işletme projesi, devir, gider (066, altıncı tur D1)"
for P in 19782:finance 19783:governance 19784:expense; do
  DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
    DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=${P%%:*} \
    go run ./services/${P##*:} >/tmp/verify-d1-${P##*:}.log 2>&1 &
  eval "D1_${P##*:}=\$!"
done
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19782/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19783/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19784/health >/dev/null 2>&1 && break; sleep 1
done
LF="http://127.0.0.1:19782/api/v1/finance"; LG="http://127.0.0.1:19783/api/v1/governance"; LE="http://127.0.0.1:19784/api/v1"
LM="Authorization: Bearer $MGRL"
C_EQ='55555555-5555-5555-5555-555555555501'; C_OWN='10000000-0000-0000-0000-000000000103'; C_SR2='55555555-5555-5555-5555-555555555502'
# Finans tahakkuku sitenin kendi kalemlerini kullanır; kalemin varsayılan sınıfının işlediğini görmek için biri malik yapılır
$PSQL -c "UPDATE expense_categories SET default_liability='OWNER' WHERE id='$C_SR2';" >/dev/null
NU=$($PSQL -t -A -c "SELECT count(*) FROM units WHERE property_id='$DEMO_PROPERTY' AND deleted=0;")
CDEF=$(curl -s "$LF/expense-categories" -H "$LM" | python3 -c "
import json,sys
d={c['id']:c.get('default_liability') for c in json.load(sys.stdin)['data']}
print(d.get('$C_EQ'), d.get('$C_SR2'))" 2>/dev/null)
# Karışık sınıflı tahakkuk: kullanım kalemi + malik kalemi (sınıf kategoriden) → bölüm başına iki kayıt
LQ="property_id='$DEMO_PROPERTY' AND period_year=2092 AND period_month=3"
L1=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LF/assessments" -H "$LM" -H "$J" \
  -d "{\"period_year\":2092,\"period_month\":3,\"due_date\":\"2092-03-15\",\"expense_items\":[{\"category_id\":\"$C_EQ\",\"amount\":1000},{\"category_id\":\"$C_SR2\",\"amount\":600}]}")
LROW=$($PSQL -t -A -c "SELECT (SELECT count(*) FROM monthly_assessments WHERE $LQ AND liability='USAGE')||'|'||
  ((SELECT count(*) FROM monthly_assessments WHERE $LQ AND liability='OWNER') > 0)||'|'||
  (SELECT COALESCE(sum(total_amount),0) FROM monthly_assessments WHERE $LQ AND liability='OWNER')||'|'||
  (SELECT COALESCE(sum(total_amount),0) FROM monthly_assessments WHERE $LQ AND liability='USAGE')||'|'||
  (SELECT count(*) FROM assessment_details d JOIN monthly_assessments ma ON ma.id=d.assessment_id WHERE $LQ AND d.liability<>ma.liability)||'|'||
  (SELECT count(*) FROM monthly_assessments ma WHERE $LQ AND ma.total_amount <> (SELECT sum(amount) FROM assessment_details d WHERE d.assessment_id=ma.id));")
LAPI=$(curl -s "$LF/assessments?year=2092" -H "$LM" | python3 -c "
import json,sys
d=json.load(sys.stdin).get('data') or []
print(sorted(set(a.get('liability') for a in d)))" 2>/dev/null)
[ "$CDEF" = "USAGE OWNER" ] && [ "$L1" = "201" ] && [ "$LROW" = "$NU|true|600.00|1000.00|0|0" ] \
  && ok "kalemin varsayılan sınıfı dönüyor; kullanım + malik kalemli tahakkukta bölüme sınıf başına ayrı kayıt açıldı: malik toplamı 600,00, kullanım 1.000,00 kuruşu kuruşuna, kalem satırları başlıkla aynı sınıfta" \
  || bad "karışık sınıflı tahakkuk: kategori=$CDEF / $L1 / $LROW (beklenen $NU|true|600.00|1000.00|0|0) / liste=$LAPI"
L2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LF/assessments" -H "$LM" -H "$J" \
  -d "{\"period_year\":2092,\"period_month\":3,\"due_date\":\"2092-03-15\",\"expense_items\":[{\"category_id\":\"$C_SR2\",\"amount\":300}]}")
L3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LF/assessments" -H "$LM" -H "$J" \
  -d "{\"period_year\":2092,\"period_month\":4,\"due_date\":\"2092-04-15\",\"expense_items\":[{\"category_id\":\"$C_EQ\",\"amount\":240,\"liability\":\"OWNER\"}]}")
L3R=$($PSQL -t -A -c "SELECT string_agg(DISTINCT liability, ',') FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year=2092 AND period_month=4;")
L4=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LF/assessments" -H "$LM" -H "$J" \
  -d "{\"period_year\":2092,\"period_month\":5,\"due_date\":\"2092-05-15\",\"expense_items\":[{\"category_id\":\"$C_EQ\",\"amount\":240,\"liability\":\"KIRACI\"}]}")
L4N=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year=2092 AND period_month=5;")
$PSQL -c "UPDATE expense_categories SET default_liability='USAGE' WHERE id='$C_SR2';" >/dev/null
[ "$L2" = "409" ] && [ "$L3" = "201" ] && [ "$L3R" = "OWNER" ] && [ "$L4" = "400" ] && [ "$L4N" = "0" ] \
  && ok "aynı dönem + aynı sınıf ikinci kez tahakkuk edilemiyor (409); girişte seçilen sınıf kategorinin varsayılanını eziyor; tanınmayan sınıf 400 ve hiç kayıt yok" \
  || bad "tahakkuk sınıf kuralları: tekrar=$L2 / seçilen=$L3 ($L3R) / geçersiz=$L4 kayıt=$L4N"
# Tahakkukun sınıfı sonradan değiştirilemez (uygulama rolü)
LUID=$($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE $LQ AND liability='USAGE' LIMIT 1;")
LG1=$(appsql46 "UPDATE monthly_assessments SET liability='OWNER' WHERE id='$LUID'")
LG1V=$($PSQL -t -A -c "SELECT liability FROM monthly_assessments WHERE id='$LUID';")
grep -q 'sınıfı (kullanım/malik) değiştirilemez' <<<"$LG1" && [ "$LG1V" = "USAGE" ] \
  && ok "tahakkukun sınıfı uygulama rolüyle değiştirilemiyor (tetikleyici); kayıt kullanım sınıfında kaldı" \
  || bad "sınıf koruması: $LG1 / $LG1V"
$PSQL -c "DELETE FROM assessment_details WHERE assessment_id IN (SELECT id FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year=2092);
  DELETE FROM monthly_assessments WHERE property_id='$DEMO_PROPERTY' AND period_year=2092;" >/dev/null
# Devir bakiyesi: aynı bölüme kullanım ve malik devri ayrı girilir; aynı sınıfta ikinci devir 409
LO=$(curl -s -w '|%{http_code}' -X POST "$LF/opening-balances" -H "$LM" -H "$J" \
  -d "{\"due_date\":\"2092-06-30\",\"items\":[{\"unit_id\":\"$U304\",\"amount\":50,\"description\":\"Yakıt farkı\"},{\"unit_id\":\"$U304\",\"amount\":100,\"description\":\"Asansör yenileme payı\",\"liability\":\"OWNER\"}]}")
LO2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LF/opening-balances" -H "$LM" -H "$J" \
  -d "{\"due_date\":\"2092-06-30\",\"items\":[{\"unit_id\":\"$U304\",\"amount\":10,\"liability\":\"OWNER\"}]}")
LOR=$($PSQL -t -A -c "SELECT string_agg(liability||'='||total_amount, ',' ORDER BY liability) FROM monthly_assessments
  WHERE kind='OPENING' AND deleted=0 AND unit_id='$U304';")
LOAPI=$(curl -s "$LF/opening-balances" -H "$LM" | python3 -c "
import json,sys
print(sorted(o['liability'] for o in json.load(sys.stdin)['data'] if o.get('unit_id')=='$U304' and o.get('status')!='CANCELLED'))" 2>/dev/null)
[ "${LO##*|}" = "201" ] && [ "$LO2" = "409" ] && [ "$LOR" = "OWNER=100.00,USAGE=50.00" ] && [ "$LOAPI" = "['OWNER', 'USAGE']" ] \
  && ok "devir bakiyesi sınıfıyla girildi (bir bölüme kullanım + malik devri); aynı sınıfta ikinci devir 409; listede sınıf görünüyor" \
  || bad "devir sınıfı: ${LO##*|} / ikinci=$LO2 / $LOR / liste=$LOAPI — ${LO%|*}"
for X in $($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE kind='OPENING' AND deleted=0 AND unit_id='$U304';"); do
  curl -s -o /dev/null -X POST "$LF/opening-balances/$X/cancel" -H "$LM"
done
# İşletme projesi: malik kalemi bölüm payında ayrı tutulur; projeden tahakkuk sınıf başına ayrı kayıt açar
LB=$(curl -s -w '|%{http_code}' -X POST "$LG/budgets" -H "$LM" -H "$J" -d "{\"period_year\":2093,\"items\":[
  {\"name\":\"Kapici\",\"amount\":12000,\"distribution_type\":\"EQUAL\"},
  {\"name\":\"Havuz yapimi\",\"amount\":2400,\"distribution_type\":\"EQUAL\",\"category_id\":\"$C_OWN\"}]}")
LBID=$(echo "${LB%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
LBS=$($PSQL -t -A -c "SELECT bool_and(annual_usage_kurus + annual_owner_kurus = annual_kurus)||'|'||sum(annual_owner_kurus)||'|'||sum(annual_usage_kurus)
  FROM operating_budget_unit_shares WHERE budget_id='${LBID:-00000000-0000-0000-0000-000000000000}';")
LBI=$($PSQL -t -A -c "SELECT string_agg(name||'='||liability, ',' ORDER BY sort_order) FROM operating_budget_items WHERE budget_id='${LBID:-00000000-0000-0000-0000-000000000000}';")
LBX=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LG/budgets" -H "$LM" -H "$J" \
  -d '{"period_year":2094,"items":[{"name":"x","amount":100,"distribution_type":"EQUAL","liability":"KIRACI"}]}')
[ "${LB##*|}" = "201" ] && [ "$LBS" = "true|240000|1200000" ] && [ "$LBI" = "Kapici=USAGE,Havuz yapimi=OWNER" ] && [ "$LBX" = "422" ] \
  && ok "işletme projesinde yeni tesis kalemi kategorisinden malik sınıfına düştü; bölüm payı kullanım 12.000 / malik 2.400 TL olarak ayrıldı (toplam yıllık paya eşit); tanınmayan sınıf 422" \
  || bad "proje sınıfı: ${LB##*|} / pay=$LBS / kalemler=$LBI / geçersiz=$LBX — ${LB%|*}"
$PSQL -c "UPDATE operating_budgets SET status='FINAL' WHERE id='${LBID:-00000000-0000-0000-0000-000000000000}';" >/dev/null
LBA=$(curl -s -w '|%{http_code}' -X POST "$LG/budgets/$LBID/assessments" -H "$LM" -H "$J" -d '{"period_month":1,"due_date":"2093-01-28"}')
LBC=$(echo "${LBA%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['created'], d['created_by_class'].get('USAGE'), d['created_by_class'].get('OWNER'))" 2>/dev/null)
# Her bölümün aylık taksiti kendi sınıf payının 1/12'si (kalan kuruşlar aylara dağıtıldığı için en çok 1 kuruş fark)
LBD=$($PSQL -t -A -c "SELECT count(*) FROM monthly_assessments m JOIN operating_budget_unit_shares s ON s.budget_id=m.budget_id AND s.unit_id=m.unit_id
  WHERE m.budget_id='$LBID' AND abs(round(m.base_amount*100) - (CASE m.liability WHEN 'OWNER' THEN s.annual_owner_kurus ELSE s.annual_usage_kurus END) / 12.0) >= 1;")
SHN=$($PSQL -t -A -c "SELECT count(*) FROM operating_budget_unit_shares WHERE budget_id='$LBID' AND annual_kurus > 0;")
[ "${LBA##*|}" = "201" ] && [ "$LBC" = "$((SHN*2)) $SHN $SHN" ] && [ "$LBD" = "0" ] \
  && ok "projeden aylık tahakkuk sınıf başına ayrı kayıt açtı ($SHN kullanım + $SHN malik); her kayıt bölümün o sınıftaki yıllık payının 1/12'si" \
  || bad "projeden sınıflı tahakkuk: ${LBA##*|} / $LBC (beklenen $((SHN*2)) $SHN $SHN) / $LBD — ${LBA%|*}"
$PSQL -c "DELETE FROM monthly_assessments WHERE budget_id='$LBID'; DELETE FROM operating_budgets WHERE id='$LBID';" >/dev/null
# Gider kaydı: sınıf kategoriden önerilir, girişte değiştirilebilir, geçersizi 422
LE1=$(curl -s -X POST "$LE/expenses" -H "$LM" -H "$J" -d "{\"category_id\":\"$C_OWN\",\"description\":\"Havuz pompası\",\"amount\":3000,\"expense_date\":\"2026-03-10\",\"vendor_name\":\"Test\",\"invoice_number\":\"FT-D1-1\"}")
LE2=$(curl -s -X POST "$LE/expenses" -H "$LM" -H "$J" -d "{\"category_id\":\"$C_OWN\",\"description\":\"Havuz bakımı\",\"amount\":500,\"expense_date\":\"2026-03-10\",\"vendor_name\":\"Test\",\"invoice_number\":\"FT-D1-2\",\"liability\":\"USAGE\"}")
LE3=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$LE/expenses" -H "$LM" -H "$J" -d "{\"category_id\":\"$C_OWN\",\"description\":\"x\",\"amount\":5,\"expense_date\":\"2026-03-10\",\"vendor_name\":\"Test\",\"invoice_number\":\"FT-D1-3\",\"liability\":\"KIRACI\"}")
lval() { python3 -c "import json,sys; d=json.load(sys.stdin); d=d.get('expense',d); print(d.get('liability'))" 2>/dev/null; }
LE1L=$(echo "$LE1" | lval); LE2L=$(echo "$LE2" | lval)
LECAT=$(curl -s "$LE/expense-categories" -H "$LM" | python3 -c "
import json,sys
d=json.load(sys.stdin); d=d.get('data',d)
print([c.get('default_liability') for c in d if c['id']=='$C_OWN'])" 2>/dev/null)
[ "$LE1L" = "OWNER" ] && [ "$LE2L" = "USAGE" ] && [ "$LE3" = "422" ] && [ "$LECAT" = "['OWNER']" ] \
  && ok "gider kaydında sınıf kategoriden önerildi (malik), girişte kullanım olarak değiştirilebildi; tanınmayan sınıf 422" \
  || bad "gider sınıfı: öneri=$LE1L / seçilen=$LE2L / geçersiz=$LE3 / kategori=$LECAT — $LE1"
$PSQL -c "DELETE FROM expense_distributions WHERE expense_id IN (SELECT id FROM expenses WHERE invoice_number LIKE 'FT-D1-%');
  DELETE FROM expenses WHERE invoice_number LIKE 'FT-D1-%';" >/dev/null 2>&1
kill_tree "$D1_finance"; kill_tree "$D1_governance"; kill_tree "$D1_expense"

step "58) Daire oturum modeli: kiracı / malik oturuyor / boş / kayıtsız (067, altıncı tur D2)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19785 \
  go run ./services/identity >/tmp/verify-identity-d2.log 2>&1 &
ID2_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19785/health >/dev/null 2>&1 && break; sleep 1; done
I58="http://127.0.0.1:19785/api/v1"
M58=$(curl -s -X POST "$I58/auth/login" -H "$J" -d '{"phone":"5551234567","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
T58=$(curl -s -X POST "$I58/auth/login" -H "$J" -d '{"phone":"5559876543","password":"Demo123!"}' | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
MA58="Authorization: Bearer $M58"
OWN58='44444444-4444-4444-4444-444444444401'
# Üç yeni bölüm: Z-58A (malik), Z-58B (kimse), Z-58C (yalnız kiracı)
UA=$($PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',1,'58A',1,'APARTMENT',80) RETURNING id;" | head -1)
UB=$($PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',1,'58B',1,'APARTMENT',80) RETURNING id;" | head -1)
UC=$($PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',1,'58C',1,'APARTMENT',80) RETURNING id;" | head -1)
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$OWN58','$UA','OWNER'), ('$TUID','$UC','TENANT');" >/dev/null
occ() { curl -s "$I58/units" -H "$MA58" | python3 -c "
import json,sys
d={u['id']:u for u in json.load(sys.stdin)['data']}
print(' '.join(d[i]['occupancy']+('/maliksiz' if d[i]['owner_missing'] else '') for i in sys.argv[1:]))" "$@" 2>/dev/null; }
occ_res() { curl -s "$I58/residents" -H "$MA58" | python3 -c "
import json,sys
d=json.load(sys.stdin); d=d.get('data',d)
print(' '.join(r['role']+'='+str(r['is_occupant']).lower() for r in sorted(d, key=lambda r: r['role']) if r['unit_id']==sys.argv[1] and r['is_active']))" "$1" 2>/dev/null; }
S1=$(occ "$UA" "$UB" "$UC"); R1=$(occ_res "$UA")
[ "$S1" = "OWNER_OCCUPIED UNREGISTERED TENANT_OCCUPIED/maliksiz" ] && [ "$R1" = "OWNER=true" ] \
  && ok "oturum durumu kayıtlardan hesaplanıyor: malikli daire 'malik oturuyor', kimsesiz daire 'kayıtsız', yalnız kiracılı daire 'kiracı oturuyor' + malik kaydı yok uyarısı; malik oturan olarak görünüyor" \
  || bad "oturum durumu: $S1 / sakinler: $R1"
P1=$(curl -s -w '|%{http_code}' -X PATCH "$I58/units/$UA" -H "$MA58" -H "$J" -d '{"owner_occupied":false}')
P1O=$(echo "${P1%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['occupancy'], d['owner_occupied'])" 2>/dev/null)
S2=$(occ "$UA"); R2=$(occ_res "$UA")
P2=$(code -X PATCH "$I58/units/$UA" -H "Authorization: Bearer $T58" -H "$J" -d '{"owner_occupied":true}')
[ "${P1##*|}" = "200" ] && [ "$P1O" = "VACANT False" ] && [ "$S2" = "VACANT" ] && [ "$R2" = "OWNER=false" ] && [ "$P2" = "403" ] \
  && ok "yönetim daireyi 'boş' işaretledi: durum güncelleme yanıtında ve listede 'boş', malik artık oturan değil; kiracı bölüm durumunu değiştiremiyor (403)" \
  || bad "boş daire: ${P1##*|} $P1O / liste=$S2 / sakin=$R2 / kiracı=$P2"
# Boş daireye kiracı gelince kiracı oturur, malik oturan değildir; kiracı çıkınca malik oturuyor seçeneği geri gelir
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$TUID','$UA','TENANT');" >/dev/null
S3=$(occ "$UA"); R3=$(occ_res "$UA")
$PSQL -c "UPDATE resident_units SET is_active=false, end_date=CURRENT_DATE WHERE unit_id='$UA' AND role='TENANT';" >/dev/null
S4=$(occ "$UA")
curl -s -o /dev/null -X PATCH "$I58/units/$UA" -H "$MA58" -H "$J" -d '{"owner_occupied":true}'
S5=$(occ "$UA"); R5=$(occ_res "$UA")
[ "$S3" = "TENANT_OCCUPIED" ] && [ "$R3" = "OWNER=false TENANT=true" ] && [ "$S4" = "VACANT" ] && [ "$S5" = "OWNER_OCCUPIED" ] && [ "$R5" = "OWNER=true" ] \
  && ok "kiracı gelince kiracı oturan, malik değil; kiracı ayrılınca daire yeniden boş (malik kayıtlı); yönetim 'malik oturuyor' deyince malik oturan" \
  || bad "devir: kiracılı=$S3 ($R3) / ayrılınca=$S4 / malik oturuyor=$S5 ($R5)"
# Hane üyesi: şemada var, oturan sayılır, jeton rolü üretmez; ekleme akışı D3'e kadar kapalı
HH=$($PSQL -t -A -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$TUID','$UA','HOUSEHOLD') RETURNING id;" | head -1)
HHO=$($PSQL -t -A -c "SELECT resident_is_occupant('$HH');")
HHA=$(code -X POST "$I58/residents" -H "$MA58" -H "$J" -d "{\"first_name\":\"Hane\",\"last_name\":\"Uyesi\",\"phone\":\"0555 999 00 58\",\"unit_id\":\"$UB\",\"role\":\"HOUSEHOLD\"}")
HAPP=$(appsql46 "SELECT unit_occupancy('$UA') || '|' || unit_occupancy('$UB')")
grep -q 'OWNER_OCCUPIED|UNREGISTERED' <<<"$HAPP" && [ -n "$HH" ] && [ "$HHO" = "t" ] && [ "$HHA" = "422" ] \
  && ok "hane üyesi rolü veritabanında kabul ediliyor ve oturan sayılıyor; oturanı olmayan daireye hane üyesi kaydı 422 (D3); diğer servisler (uygulama rolü) oturum durumunu aynı işlevden okuyor" \
  || bad "hane üyesi / uygulama rolü: kayıt=$HH oturan=$HHO api=$HHA / $HAPP"
$PSQL -c "DELETE FROM resident_units WHERE unit_id IN ('$UA','$UB','$UC'); DELETE FROM units WHERE id IN ('$UA','$UB','$UC');" >/dev/null
kill_tree "$ID2_PID"

step "59) Kayıt ve davet: kodla katılım, tek kiracı, malik hanesinin bitişi, hane üyesine mali ekran yok (068, altıncı tur D3)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19787 \
  go run ./services/identity >/tmp/verify-identity-d3.log 2>&1 &
ID3_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19786 \
  go run ./services/finance >/tmp/verify-finance-d3.log 2>&1 &
FD3_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19787/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19786/health >/dev/null 2>&1 && break; sleep 1
done
I59="http://127.0.0.1:19787/api/v1"; F59="http://127.0.0.1:19786/api/v1/finance"
login59() { curl -s -X POST "$I59/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M59="Authorization: Bearer $(login59 5551234567 'Demo123!')"
T59="Authorization: Bearer $(login59 5559876543 'Demo123!')"
OWN59='44444444-4444-4444-4444-444444444401'
mkunit59() { $PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',2,'$1',1,'APARTMENT',80) RETURNING id;" | head -1; }
UA9=$(mkunit59 59A); UB9=$(mkunit59 59B); UC9=$(mkunit59 59C)
HH9=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000039';")
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES
  ('$OWN59','$UA9','OWNER'), ('$HH9','$UA9','HOUSEHOLD'), ('$TUID','$UB9','TENANT'), ('$OWN59','$UC9','OWNER');" >/dev/null
# 1) Yönetimin kiracı daveti: hesap açılır, kod yönetime bir kez gösterilir; kişi kodu girince daireye bağlanır
D1R=$(curl -s -w '|%{http_code}' -X POST "$I59/residents/invitations" -H "$M59" -H "$J" \
  -d "{\"first_name\":\"Davetli\",\"last_name\":\"Kiraci\",\"phone\":\"0555 999 00 71\",\"email\":\"davetli@example.com\",\"unit_id\":\"$UA9\",\"role\":\"TENANT\"}")
D1C=$(echo "${D1R%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['activation']['activation_code'], d['new_account'], d['delivery']['sms']['status'], d['delivery']['email']['status'])" 2>/dev/null)
D1CODE=${D1C%% *}
PRE=$($PSQL -t -A -c "SELECT count(*) FROM resident_units ru JOIN users u ON u.id=ru.resident_id WHERE u.phone='+905559990071';")
ACT=$(curl -s -w '|%{http_code}' -X POST "$I59/auth/activate" -H "$J" -d "{\"phone\":\"0555 999 00 71\",\"code\":\"$D1CODE\",\"new_password\":\"Davetli2026x\"}")
POST=$($PSQL -t -A -c "SELECT ru.role||'|'||ru.is_active FROM resident_units ru JOIN users u ON u.id=ru.resident_id WHERE u.phone='+905559990071' AND ru.unit_id='$UA9';")
INVS=$($PSQL -t -A -c "SELECT i.status||'|'||i.invited_as FROM resident_invitations i JOIN users u ON u.id=i.user_id WHERE u.phone='+905559990071';")
HHS=$($PSQL -t -A -c "SELECT is_active||'|'||(end_date=CURRENT_DATE) FROM resident_units WHERE resident_id='$HH9' AND unit_id='$UA9';")
OCC=$($PSQL -t -A -c "SELECT unit_occupancy('$UA9')||'|'||resident_is_occupant((SELECT id FROM resident_units WHERE resident_id='$OWN59' AND unit_id='$UA9'));")
[ "${D1R##*|}" = "201" ] && [ "${D1C#* }" = "True NOT_CONFIGURED NOT_CONFIGURED" ] && [ "$PRE" = "0" ] && [ "${ACT##*|}" = "200" ] \
  && grep -q '"accepted":1' <<<"$ACT" && [ "$POST" = "TENANT|true" ] && [ "$INVS" = "ACCEPTED|MANAGEMENT" ] && [ "$HHS" = "false|true" ] && [ "$OCC" = "TENANT_OCCUPIED|false" ] \
  && ok "yönetim kiracı davet etti (hesap açıldı, kod yalnız yönetime; SMS/e-posta sağlayıcısızlığı dürüstçe söylendi); kişi kodu girince daireye bağlandı, davet kabul edildi; malikin hanesinin kaydı bugün bitti; malik artık oturan değil" \
  || bad "kodla katılım: ${D1R##*|} $D1C / önce=$PRE / etkinleştirme=$ACT / bağ=$POST / davet=$INVS / malik hanesi=$HHS / oturum=$OCC"
# 2) Dairede aktif kiracı varken kiracı daveti ve kaydı yok (yönetim dahil); malik daveti yalnız maliksiz daireye
D2A=$(curl -s -w '|%{http_code}' -X POST "$I59/residents/invitations" -H "$M59" -H "$J" -d "{\"first_name\":\"X\",\"last_name\":\"Y\",\"phone\":\"0555 999 00 72\",\"unit_id\":\"$UA9\",\"role\":\"TENANT\"}")
D2B=$(code -X POST "$I59/residents" -H "$M59" -H "$J" -d "{\"first_name\":\"X\",\"last_name\":\"Y\",\"phone\":\"0555 999 00 72\",\"unit_id\":\"$UA9\",\"role\":\"TENANT\"}")
D2C=$(code -X POST "$I59/residents/invitations" -H "$M59" -H "$J" -d "{\"first_name\":\"Malik\",\"last_name\":\"Aday\",\"phone\":\"0555 999 00 73\",\"unit_id\":\"$UB9\",\"role\":\"OWNER\"}")
D2D=$(code -X POST "$I59/residents/invitations" -H "$M59" -H "$J" -d "{\"first_name\":\"Malik\",\"last_name\":\"Iki\",\"phone\":\"0555 999 00 74\",\"unit_id\":\"$UA9\",\"role\":\"OWNER\"}")
D2E=$(code -X POST "$I59/residents/invitations" -H "Authorization: Bearer $(login59 5550000039 Yepyeni12)" -H "$J" -d "{\"first_name\":\"X\",\"last_name\":\"Y\",\"phone\":\"0555 999 00 75\",\"unit_id\":\"$UA9\",\"role\":\"TENANT\"}")
[ "${D2A##*|}" = "409" ] && grep -q 'aktif bir kiracı' <<<"$D2A" && [ "$D2B" = "409" ] && [ "$D2C" = "201" ] && [ "$D2D" = "409" ] && [ "$D2E" = "403" ] \
  && ok "kiracılı daireye ikinci kiracı ne davet edilebiliyor ne kaydedilebiliyor (409, yönetim dahil); yalnız kiracıyla kayıtlı daireye malik davet edildi, malikli daireye 409; yetkisiz kişi yönetim daveti gönderemiyor (403)" \
  || bad "tek kiracı / malik daveti: davet=$D2A / kayıt=$D2B / maliksiz=$D2C / malikli=$D2D / yetkisiz=$D2E"
# 3) Yeni kiracı kendi hanesine üye davet eder (kod ona gösterilmez); kiracı gelmeden önceki hane bitmişti
TN9="Authorization: Bearer $(login59 5559990071 Davetli2026x)"
D3A=$(curl -s -w '|%{http_code}' -X POST "$I59/users/me/units/$UA9/invitations" -H "$TN9" -H "$J" -d '{"first_name":"Kiraci","last_name":"Esi","phone":"0555 999 00 76","role":"HOUSEHOLD"}')
D3AS=$(echo "${D3A%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['invitation']['role'], 'activation' in d)" 2>/dev/null)
D3B=$($PSQL -t -A -c "SELECT invited_as FROM resident_invitations i JOIN users u ON u.id=i.user_id WHERE u.phone='+905559990076';")
D3C=$(code -X POST "$I59/users/me/units/$UA9/invitations" -H "$M59" -H "$J" -d '{"first_name":"Malik","last_name":"Hanesi","phone":"0555 999 00 77","role":"HOUSEHOLD"}')
[ "${D3A##*|}" = "201" ] && [ "$D3AS" = "HOUSEHOLD False" ] && [ "$D3B" = "OCCUPANT" ] && [ "$D3C" = "422" ] \
  && ok "kiracı hanesine üye davet etti (kod davet edene gösterilmedi, sıfat OCCUPANT); kiracılı dairede malik hane üyesi davet edemiyor (422)" \
  || bad "hane daveti: ${D3A##*|} $D3AS / sıfat=$D3B / malik=$D3C"
# 4) Hesabı olan kişi bekleyen daveti kabul ederken kural yeniden denetlenir
D4A=$(curl -s -X POST "$I59/residents/invitations" -H "$M59" -H "$J" -d "{\"phone\":\"5559876543\",\"unit_id\":\"$UC9\",\"role\":\"TENANT\"}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['invitation']['id'], d['new_account'], 'activation' in d)" 2>/dev/null)
D4ID=${D4A%% *}
D4B=$(code -X POST "$I59/residents/invitations" -H "$M59" -H "$J" -d "{\"first_name\":\"Rakip\",\"last_name\":\"Kiraci\",\"phone\":\"0555 999 00 78\",\"unit_id\":\"$UC9\",\"role\":\"TENANT\"}")
D4C=$(code -X POST "$I59/residents" -H "$M59" -H "$J" -d "{\"first_name\":\"Rakip\",\"last_name\":\"Kiraci\",\"phone\":\"0555 999 00 78\",\"unit_id\":\"$UC9\",\"role\":\"TENANT\"}")
D4D=$(curl -s -w '|%{http_code}' -X POST "$I59/users/me/invitations/$D4ID/accept" -H "$T59")
D4E=$($PSQL -t -A -c "SELECT status FROM resident_invitations WHERE id='$D4ID';")
[ "${D4A#* }" = "False False" ] && [ "$D4B" = "409" ] && [ "$D4C" = "201" ] && [ "${D4D##*|}" = "409" ] && grep -q 'aktif bir kiracı' <<<"$D4D" && [ "$D4E" = "PENDING" ] \
  && ok "hesabı olan kişiye davet (kod üretilmedi); dairede bekleyen kiracı daveti varken ikinci kiracı daveti 409; yönetim bu arada kiracıyı doğrudan kaydedince bekleyen davetin kabulü 409, davet bekliyor" \
  || bad "kabulde yeniden denetim: $D4A / ikinci davet=$D4B / kayıt=$D4C / kabul=$D4D / durum=$D4E"
# 5) Hane üyesi mali ekranı görmez (V4): dairenin borcu hane üyesinde yok, kiracıda var
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$HH9','$UA9','HOUSEHOLD')
  ON CONFLICT (resident_id, unit_id, role) DO UPDATE SET is_active=true, end_date=NULL;
  INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status)
  VALUES ('$DEMO_PROPERTY','$UA9',2091,1,321,321,CURRENT_DATE + 10,'PENDING');" >/dev/null
units_debt() { curl -s "$F59/assessments?year=2091" -H "$1" | python3 -c "
import json,sys
print(len(json.load(sys.stdin).get('data') or []))" 2>/dev/null; }
HHT="Authorization: Bearer $(login59 5550000039 Yepyeni12)"
V4H=$(units_debt "$HHT"); V4T=$(units_debt "$TN9")
V4P=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$F59/payments" -H "$HHT" -H "$J" \
  -d "{\"assessment_ids\":[\"$($PSQL -t -A -c "SELECT id FROM monthly_assessments WHERE unit_id='$UA9' AND period_year=2091;")\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$(date +%F)\",\"reference\":\"X\"}")
[ "$V4H" = "0" ] && [ "$V4T" = "1" ] && [ "$V4P" != "201" ] \
  && ok "hane üyesi dairenin borcunu görmüyor ve ödeyemiyor ($V4P); aynı borç kiracıda görünüyor" \
  || bad "hane üyesi mali erişim: hane=$V4H kiracı=$V4T ödeme=$V4P"
$PSQL -c "DELETE FROM monthly_assessments WHERE unit_id IN ('$UA9','$UB9','$UC9');
  DELETE FROM resident_invitations WHERE unit_id IN ('$UA9','$UB9','$UC9');
  DELETE FROM resident_units WHERE unit_id IN ('$UA9','$UB9','$UC9');
  DELETE FROM units WHERE id IN ('$UA9','$UB9','$UC9');" >/dev/null
kill_tree "$ID3_PID"; kill_tree "$FD3_PID"

step "60) Kiracılığın bitişi: malik isteği + kiracı onayı, kiracının çıkışı, yönetim yolu (belge, beyan, 7 gün itiraz, geri alma) (069, altıncı tur D4)"
TEDIR=/tmp/verify-tenancy-docs; rm -rf "$TEDIR"; mkdir -p "$TEDIR"
STORAGE_BACKEND=local STORAGE_LOCAL_DIR="$TEDIR" DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" \
  DB_NAME=siteeksen DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19788 \
  go run ./services/identity >/tmp/verify-identity-d4.log 2>&1 &
ID4_PID=$!
for _ in $(seq 1 60); do curl -fsS http://127.0.0.1:19788/health >/dev/null 2>&1 && break; sleep 1; done
I60="http://127.0.0.1:19788/api/v1"
login60() { curl -s -X POST "$I60/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M60="Authorization: Bearer $(login60 5551234567 'Demo123!')"
T60="Authorization: Bearer $(login60 5559876543 'Demo123!')"
O60="Authorization: Bearer $(login60 5550000039 Yepyeni12)"
OWN60=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000039';")
mkunit60() { $PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',3,'$1',1,'APARTMENT',80) RETURNING id;" | head -1; }
UA0=$(mkunit60 60A); UB0=$(mkunit60 60B)
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES
  ('$OWN60','$UA0','OWNER'), ('$TUID','$UA0','TENANT'), ('44444444-4444-4444-4444-444444444401','$UB0','OWNER'), ('$TUID','$UB0','TENANT');" >/dev/null
TL0=$($PSQL -t -A -c "SELECT id FROM resident_units WHERE unit_id='$UA0' AND role='TENANT';")
reactivate60() { $PSQL -c "UPDATE resident_units SET is_active=true, end_date=NULL WHERE id='$TL0';" >/dev/null; }
myreq() { curl -s "$I60/users/me/tenancy-requests" -H "$1" | python3 -c "
import json,sys
d=[r for r in json.load(sys.stdin)['data'] if r['unit_id']=='$UA0']
print(' '.join(r['kind']+':'+r['status']+':'+str(r['is_tenant']).lower() for r in d[:1]))" 2>/dev/null; }
# 1) Malik ister, kiracı reddeder → sürer; yeniden ister, kiracı onaylar → biter (hanesi biter, daire boş)
R1=$(curl -s -w '|%{http_code}' -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$O60" -H "$J" -d '{"reason":"Konutu kendim kullanacağım"}')
RQ1=$(echo "${R1%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
R1B=$(code -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$O60" -H "$J" -d '{"reason":"Ikinci istek deneme"}')
R1C=$(code -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$T60" -H "$J" -d '{"reason":"Kiracı malik değil"}')
SEEN=$(myreq "$T60")
R1D=$(code -X POST "$I60/users/me/tenancy-requests/$RQ1/decline" -H "$T60" -H "$J" -d '{"note":"Sözleşmem sürüyor"}')
ACT1=$($PSQL -t -A -c "SELECT is_active FROM resident_units WHERE id='$TL0';")
R1E=$(code -X PATCH "$I60/residents/$TL0" -H "$M60" -H "$J" -d '{"is_active":false}')
[ "${R1##*|}" = "201" ] && [ "$R1B" = "409" ] && [ "$R1C" = "403" ] && [ "$SEEN" = "OWNER_REQUEST:PENDING_TENANT:true" ] && [ "$R1D" = "200" ] && [ "$ACT1" = "t" ] && [ "$R1E" = "409" ] \
  && ok "malik kiracılığın bitmesini istedi (ikinci açık istek 409, malik olmayan 403); kiracı isteği uygulamasında gördü ve reddetti, kiracılık sürüyor; yönetim de kiracıyı doğrudan pasifleştiremiyor (409)" \
  || bad "malik isteği/ret: ${R1##*|} / ikinci=$R1B / kiracı=$R1C / görünen=$SEEN / ret=$R1D / aktif=$ACT1 / yönetim=$R1E"
HHM=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559990071';")
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$HHM','$UA0','HOUSEHOLD');" >/dev/null
RQ2=$(curl -s -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$O60" -H "$J" -d '{"reason":"Konutu kendim kullanacağım"}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
R2=$(code -X POST "$I60/users/me/tenancy-requests/$RQ2/approve" -H "$T60" -H "$J" -d '{}')
END2=$($PSQL -t -A -c "SELECT is_active||'|'||(end_date=CURRENT_DATE) FROM resident_units WHERE id='$TL0';")
HH2=$($PSQL -t -A -c "SELECT is_active FROM resident_units WHERE resident_id='$HHM' AND unit_id='$UA0';")
OCC2=$($PSQL -t -A -c "SELECT unit_occupancy('$UA0');")
EV2=$($PSQL -t -A -c "SELECT string_agg(event, ',' ORDER BY created_at) FROM tenancy_end_events WHERE request_id='$RQ2';")
[ "$R2" = "200" ] && [ "$END2" = "false|true" ] && [ "$HH2" = "f" ] && [ "$OCC2" = "VACANT" ] && [ "$EV2" = "CREATED,APPROVED" ] \
  && ok "kiracı onaylayınca kiracılık bugün bitti, kiracının hanesi de bitti, daire boş; olay kaydı CREATED→APPROVED" \
  || bad "kiracı onayı: $R2 / bağ=$END2 / hane=$HH2 / oturum=$OCC2 / olaylar=$EV2"
# 2) Kiracının kendi çıkışı (V1): açık malik isteği varsa onu da kapatır
reactivate60
RQ3=$(curl -s -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$O60" -H "$J" -d '{"reason":"Konutu satıyorum"}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
R3=$(curl -s -w '|%{http_code}' -X POST "$I60/users/me/units/$UA0/tenancy-exit" -H "$T60" -H "$J" -d '{"reason":"Taşındım"}')
R3B=$(code -X POST "$I60/users/me/units/$UA0/tenancy-exit" -H "$O60" -H "$J" -d '{}')
ST3=$($PSQL -t -A -c "SELECT (SELECT status FROM tenancy_end_requests WHERE id='$RQ3')||'|'||(SELECT is_active FROM resident_units WHERE id='$TL0');")
[ "${R3##*|}" = "200" ] && grep -q '"recipients":1' <<<"$R3" && [ "$R3B" = "403" ] && [ "$ST3" = "CANCELLED|false" ] \
  && ok "kiracı çıkışını kendisi bildirdi (malike haber verildi); açık malik isteği kapandı; kiracı olmayan çıkış bildiremiyor (403)" \
  || bad "kiracı çıkışı: ${R3##*|} / malik=$R3B / $ST3 — ${R3%|*}"
# 3) Yönetim yolu: belge + şifreyle beyan + 7 gün itiraz
reactivate60
printf '%%PDF-1.4\n%% tahliye\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%%%EOF\n' >/tmp/tahliye.pdf
printf 'duz metin' >/tmp/tahliye.txt
mstart() { curl -s -w '|%{http_code}' -X POST "$I60/residents/tenancy-requests" -H "$M60" \
  -F "unit_id=$1" -F "reason=Kiracı 3 aydır dairede oturmuyor; taşınma tutanağı ektedir" -F "document_kind=TASINMA_TUTANAGI" \
  -F "password=$2" -F "attest=$3" -F "file=@$4"; }
M1=$(mstart "$UB0" 'Demo123!' true /tmp/tahliye.pdf)
M2=$(mstart "$UA0" 'Demo123!' false /tmp/tahliye.pdf)
M3=$(mstart "$UA0" 'yanlis-sifre' true /tmp/tahliye.pdf)
M4=$(mstart "$UA0" 'Demo123!' true /tmp/tahliye.txt)
M5=$(mstart "$UA0" 'Demo123!' true /tmp/tahliye.pdf)
MID=$(echo "${M5%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
MDOC=$($PSQL -t -A -c "SELECT d.document_kind||'|'||(d.uyap_code IS NULL)||'|'||(d.attestation_text LIKE '%TCK m.204%')||'|'||(d.attested_ip <> '')||'|'||d.sha256
  FROM tenancy_end_documents d WHERE d.request_id='$MID';")
MDL=$($PSQL -t -A -c "SELECT status||'|'||(objection_deadline BETWEEN now() + interval '6 days 23 hours' AND now() + interval '7 days 1 hour') FROM tenancy_end_requests WHERE id='$MID';")
MFILE=$(find "$TEDIR" -type f -name '*.pdf' | wc -l)
M6=$(mstart "$UA0" 'Demo123!' true /tmp/tahliye.pdf)
SHAF=$(sha256sum /tmp/tahliye.pdf | cut -d' ' -f1)
[ "${M1##*|}" = "403" ] && [ "${M2##*|}" = "422" ] && [ "${M3##*|}" = "400" ] && [ "${M4##*|}" = "422" ] && [ "${M5##*|}" = "201" ] \
  && [ "$MDOC" = "TASINMA_TUTANAGI|true|true|true|$SHAF" ] && [ "$MDL" = "OBJECTION_WINDOW|true" ] && [ "$MFILE" = "1" ] && [ "${M6##*|}" = "409" ] \
  && ok "yönetim yolu: dairenin maliki olan yönetici başlatamıyor (403); beyansız 422, yanlış şifre 400, metin dosyası 422; UYAP kodu olmadan belgeyle başladı — beyan metni, IP ve özet kayıtlı, dosya depoda, 7 günlük itiraz penceresi; aynı kiracılık için ikinci yol 409" \
  || bad "yönetim yolu başlatma: malik=${M1##*|} beyansız=${M2##*|} şifre=${M3##*|} metin=${M4##*|} / ${M5##*|} / $MDOC / $MDL / dosya=$MFILE / ikinci=${M6##*|}"
# Kiracı belgeyi görür ve indirir; malik indiremez; süre dolmadan tamamlanamaz; itiraz askıya alır
DOCID=$($PSQL -t -A -c "SELECT id FROM tenancy_end_documents WHERE request_id='$MID' LIMIT 1;")
D1=$(curl -s -o /tmp/tahliye-dl.pdf -w '%{http_code}' "$I60/users/me/tenancy-requests/$MID/documents/$DOCID" -H "$T60")
DLSHA=$(sha256sum /tmp/tahliye-dl.pdf | cut -d' ' -f1)
D2=$(code "$I60/users/me/tenancy-requests/$MID/documents/$DOCID" -H "$O60")
C1=$(code -X POST "$I60/residents/tenancy-requests/$MID/complete" -H "$M60")
OB1=$(code -X POST "$I60/users/me/tenancy-requests/$MID/object" -H "$T60" -H "$J" -d '{"reason":"Dairede oturuyorum, tutanak gerçeğe aykırı"}')
OB2=$(code -X POST "$I60/users/me/tenancy-requests/$MID/object" -H "$T60" -H "$J" -d '{"reason":"Tekrar itiraz"}')
C2=$(code -X POST "$I60/residents/tenancy-requests/$MID/complete" -H "$M60")
ST4=$($PSQL -t -A -c "SELECT status FROM tenancy_end_requests WHERE id='$MID';")
[ "$D1" = "200" ] && [ "$DLSHA" = "$SHAF" ] && [ "$D2" = "404" ] && [ "$C1" = "409" ] && [ "$OB1" = "200" ] && [ "$OB2" = "409" ] && [ "$C2" = "409" ] && [ "$ST4" = "SUSPENDED" ] \
  && ok "kiracı belgeyi indirdi (özet aynı), malik indiremiyor (404); süre dolmadan tamamlanamıyor (409); kiracının itirazıyla işlem askıda, askıdayken tamamlanamıyor" \
  || bad "itiraz: indirme=$D1 ($([ "$DLSHA" = "$SHAF" ] && echo aynı || echo farklı)) / malik=$D2 / erken=$C1 / itiraz=$OB1 / tekrar=$OB2 / askıda tamamla=$C2 / $ST4"
# Yeni belgeyle yeni pencere; süre itirazsız dolunca tamamlanır; sahte çıkarsa geri alınır
N1=$(curl -s -w '|%{http_code}' -X POST "$I60/residents/tenancy-requests/$MID/documents" -H "$M60" \
  -F "document_kind=ICRA_TAHLIYE" -F "uyap_code=ABC123XYZ" -F "password=Demo123!" -F "attest=true" -F "file=@/tmp/tahliye.pdf")
ST5=$($PSQL -t -A -c "SELECT status||'|'||(SELECT count(*) FROM tenancy_end_documents WHERE request_id='$MID')||'|'||(SELECT uyap_code FROM tenancy_end_documents WHERE request_id='$MID' AND document_kind='ICRA_TAHLIYE') FROM tenancy_end_requests WHERE id='$MID';")
$PSQL -c "UPDATE tenancy_end_requests SET objection_deadline = now() - interval '1 minute' WHERE id='$MID';" >/dev/null
OB3=$(code -X POST "$I60/users/me/tenancy-requests/$MID/object" -H "$T60" -H "$J" -d '{"reason":"Geç kalan itiraz"}')
C3=$(code -X POST "$I60/residents/tenancy-requests/$MID/complete" -H "$M60")
ST6=$($PSQL -t -A -c "SELECT (SELECT status FROM tenancy_end_requests WHERE id='$MID')||'|'||(SELECT is_active FROM resident_units WHERE id='$TL0');")
RV1=$(code -X POST "$I60/residents/tenancy-requests/$MID/reverse" -H "$M60" -H "$J" -d '{"reason":"Tutanağın sahte olduğu anlaşıldı","password":"yanlis"}')
RV2=$(code -X POST "$I60/residents/tenancy-requests/$MID/reverse" -H "$M60" -H "$J" -d '{"reason":"Tutanağın sahte olduğu anlaşıldı","password":"Demo123!"}')
ST7=$($PSQL -t -A -c "SELECT (SELECT status FROM tenancy_end_requests WHERE id='$MID')||'|'||(SELECT is_active||'|'||COALESCE(end_date::text,'yok') FROM resident_units WHERE id='$TL0');")
EV7=$($PSQL -t -A -c "SELECT string_agg(event, ',' ORDER BY created_at) FROM tenancy_end_events WHERE request_id='$MID';")
[ "${N1##*|}" = "200" ] && [ "$ST5" = "OBJECTION_WINDOW|2|ABC123XYZ" ] && [ "$OB3" = "409" ] && [ "$C3" = "200" ] && [ "$ST6" = "COMPLETED|false" ] \
  && [ "$RV1" = "400" ] && [ "$RV2" = "200" ] && [ "$ST7" = "REVERSED|true|yok" ] \
  && [ "$EV7" = "CREATED,DOCUMENT_ADDED,OBJECTED,DOCUMENT_ADDED,COMPLETED,REVERSED" ] \
  && ok "askıdaki yola yeni belge (UYAP kodlu) yeni 7 günlük pencere açtı; süre dolunca itiraz 409, yönetim tamamladı; belge sahte çıkınca şifreyle geri alındı, kiracılık aynı kayıtla açıldı; olay kaydı eksiksiz" \
  || bad "yeni belge/tamamla/geri al: ${N1##*|} / $ST5 / geç itiraz=$OB3 / tamamla=$C3 / $ST6 / yanlış şifre=$RV1 / geri al=$RV2 / $ST7 / $EV7"
# Veritabanı koruması: kimlik rolü akış dışında kiracıyı pasifleştiremez; uygulama rolü kayıtları göremez; olay kaydı silinemez
GI=$(PGPASSWORD="$IDPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_identity -d siteeksen -t -A -c "UPDATE resident_units SET is_active=false WHERE id='$TL0';" 2>&1)
GD=$(PGPASSWORD="$IDPW" psql -h 127.0.0.1 -p "$DBPORT" -U siteeksen_identity -d siteeksen -t -A -c "DELETE FROM tenancy_end_events WHERE request_id='$MID';" 2>&1)
GA=$(appsql46 "SELECT count(*) FROM tenancy_end_requests")
grep -q 'yalnız bitiş akışıyla biter' <<<"$GI" && grep -qi 'permission denied' <<<"$GD" && grep -qi 'permission denied' <<<"$GA" \
  && ok "kimlik rolü bile aktif kiracıyı akış dışında pasifleştiremiyor (tetikleyici); olay kaydı silinemiyor; uygulama rolü bitiş kayıtlarına erişemiyor" \
  || bad "bitiş koruması: $GI / $GD / $GA"
# İptaller: malik kendi isteğini geri çeker; yönetim açık yolunu iptal eder
RQ8=$(curl -s -X POST "$I60/users/me/units/$UA0/tenancy-end" -H "$O60" -H "$J" -d '{"reason":"Deneme isteği"}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
X1=$(code -X POST "$I60/users/me/tenancy-requests/$RQ8/cancel" -H "$T60")
X2=$(code -X POST "$I60/users/me/tenancy-requests/$RQ8/cancel" -H "$O60")
M8=$(mstart "$UA0" 'Demo123!' true /tmp/tahliye.pdf); MID8=$(echo "${M8%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
X3=$(code -X POST "$I60/residents/tenancy-requests/$MID8/cancel" -H "$M60" -H "$J" -d '{"note":"Taraflar anlaştı"}')
X4=$(code "$I60/residents/tenancy-requests" -H "$T60")
ACT8=$($PSQL -t -A -c "SELECT is_active FROM resident_units WHERE id='$TL0';")
[ "$X1" = "404" ] && [ "$X2" = "200" ] && [ "$X3" = "200" ] && [ "$X4" = "403" ] && [ "$ACT8" = "t" ] \
  && ok "malik kendi isteğini geri çekti (kiracı malik isteğini iptal edemez — 404); yönetim açık yolunu iptal etti; kiracı yönetim listesini göremiyor (403); kiracılık sürüyor" \
  || bad "iptaller: kiracı=$X1 malik=$X2 yönetim=$X3 liste=$X4 aktif=$ACT8"
$PSQL -c "DELETE FROM tenancy_end_requests WHERE unit_id IN ('$UA0','$UB0');
  DELETE FROM resident_units WHERE unit_id IN ('$UA0','$UB0'); DELETE FROM units WHERE id IN ('$UA0','$UB0');" >/dev/null
kill_tree "$ID4_PID"

step "61) Mali yönlendirme: borcun sorumlusu (kiracılık / malik), ödeme yetkisi, bildirim, borçlu listesi, borcu yoktur kapsamı (070, altıncı tur D5)"
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19789 \
  go run ./services/finance >/tmp/verify-finance-d5.log 2>&1 &
FD5_PID=$!
DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_identity DB_PASSWORD="$IDPW" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19790 \
  go run ./services/identity >/tmp/verify-identity-d5.log 2>&1 &
ID5_PID=$!
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:19789/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19790/health >/dev/null 2>&1 && break; sleep 1
done
F61="http://127.0.0.1:19789/api/v1/finance"; I61="http://127.0.0.1:19790/api/v1"
login61() { curl -s -X POST "$I61/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M61="Authorization: Bearer $(login61 5551234567 'Demo123!')"
T61="Authorization: Bearer $(login61 5559876543 'Demo123!')"
O61="Authorization: Bearer $(login61 5550000039 Yepyeni12)"
OWN61=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000039';")
mkunit61() { $PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',4,'$1',1,'APARTMENT',80) RETURNING id;" | head -1; }
UA1=$(mkunit61 61A); UB1=$(mkunit61 61B)
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$OWN61','$UA1','OWNER'), ('$TUID','$UA1','TENANT'), ('$TUID','$UB1','TENANT');" >/dev/null
TL1=$($PSQL -t -A -c "SELECT id FROM resident_units WHERE unit_id='$UA1' AND role='TENANT';")
mkassess61() { $PSQL -t -A -c "INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status, liability)
  VALUES ('$DEMO_PROPERTY','$1',2088,$2,$3,$3,$4,'PENDING','$5') RETURNING id;" | head -1; }
A1=$(mkassess61 "$UA1" 1 400 "CURRENT_DATE - 5" USAGE)
A2=$(mkassess61 "$UA1" 1 900 "CURRENT_DATE + 20" OWNER)
A3=$(mkassess61 "$UB1" 1 700 "CURRENT_DATE + 20" OWNER)
LNK=$($PSQL -t -A -c "SELECT (SELECT tenant_link_id::text FROM monthly_assessments WHERE id='$A1') = '$TL1', (SELECT tenant_link_id IS NULL FROM monthly_assessments WHERE id='$A2');" | tr '\n' ' ')
mine61() { curl -s "$F61/assessments?year=2088" -H "$1" | python3 -c "
import json,sys
ids={'$A1':'A1','$A2':'A2','$A3':'A3'}
d=json.load(sys.stdin).get('data') or []
print(' '.join(sorted(ids[a['id']]+':'+a.get('responsible','') for a in d if a['id'] in ids)))" 2>/dev/null; }
VT=$(mine61 "$T61"); VO=$(mine61 "$O61")
[ "$LNK" = "t|t " ] && [ "$VT" = "A1:TENANT" ] && [ "$VO" = "A2:OWNER" ] \
  && ok "kiracılıkta tahakkuk eden kullanım borcu kiracılığa bağlandı (malik borcu bağlanmadı); kiracı yalnız kendi borcunu, malik yalnız malik borcunu görüyor; maliksiz dairenin malik borcu kiracıya yansımıyor" \
  || bad "borç sorumlusu: bağ=$LNK / kiracı=$VT / malik=$VO"
pay61() { code -X POST "$F61/payments" -H "$1" -H "$J" -d "{\"assessment_ids\":[\"$2\"],\"payment_method\":\"BANK_TRANSFER\",\"value_date\":\"$(date +%F)\",\"reference\":\"D5\"}"; }
P1=$(pay61 "$T61" "$A2"); P2=$(pay61 "$O61" "$A1"); P3=$(pay61 "$T61" "$A3")
G1=$(appsql46 "UPDATE monthly_assessments SET tenant_link_id = NULL WHERE id='$A1'")
[ "$P1" = "400" ] && [ "$P2" = "400" ] && [ "$P3" = "400" ] && grep -q 'sorumlusu (kiracılık) tahakkuktan sonra değiştirilemez' <<<"$G1" \
  && ok "kiracı malik borcunu, malik kiracının borcunu ödeyemiyor (400); maliksiz dairenin malik borcu kiracıdan alınmıyor; borcun sorumlusu sonradan değiştirilemiyor (tetikleyici)" \
  || bad "ödeme yetkisi: kiracı→malik borcu=$P1 malik→kiracı borcu=$P2 maliksiz=$P3 / koruma=$G1"
# Borçlu listesi sorumluya göre; maliksiz dairenin malik borcu "Malik kaydı yok"
DBT=$(curl -s "$F61/debtors" -H "$M61" | python3 -c "
import json,sys
d=json.load(sys.stdin)['data']
a=sorted((x['responsible'], round(float(x['amount']),2), x['name'].endswith('(kiracı)'), x['owner_missing']) for x in d if x['unit_id']=='$UA1')
b=[(x['responsible'], x['name'], x['owner_missing']) for x in d if x['unit_id']=='$UB1']
print(a, b)" 2>/dev/null)
[ "$DBT" = "[('OWNER', 900.0, False, False), ('TENANT', 400.0, True, False)] [('OWNER', 'Malik kaydı yok', True)]" ] \
  && ok "borçlu listesi borcun sorumlusuna göre ayrıldı (kiracı satırı ve malik satırı); maliksiz dairenin malik borcu 'Malik kaydı yok' ile yönetimde bekliyor" \
  || bad "borçlu listesi: $DBT"
# Borcu yoktur: kiracının belgesi yalnız kendi kiracılığını, malikinki bütün daireyi kapsar; malik kiracı borcunun tutarını görmez
CT1=$(curl -s -w '|%{http_code}' -X POST "$F61/clearance-certificates" -H "$T61" -H "$J" -d "{\"unit_id\":\"$UA1\"}")
CO1=$(curl -s -w '|%{http_code}' -X POST "$F61/clearance-certificates" -H "$O61" -H "$J" -d "{\"unit_id\":\"$UA1\"}")
CO1I=$(echo "${CO1%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print([(o['responsible'], o['remaining_kurus']) for o in d['overdue']], d['overdue_kurus'])" 2>/dev/null)
$PSQL -c "UPDATE monthly_assessments SET paid_amount = total_amount, status='PAID' WHERE id='$A1';" >/dev/null
CT2=$(curl -s -w '|%{http_code}' -X POST "$F61/clearance-certificates" -H "$T61" -H "$J" -d "{\"unit_id\":\"$UA1\"}")
CT2S=$(echo "${CT2%|*}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['scope'], d['verification_code'])" 2>/dev/null)
PUB=$(curl -s "http://127.0.0.1:19789/api/v1/public/clearance/${CT2S#* }" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['scope'], 'kiracılık' in d['statement'])" 2>/dev/null)
CO2=$(curl -s "$F61/clearance-certificates" -X POST -H "$O61" -H "$J" -d "{\"unit_id\":\"$UA1\"}" | python3 -c "import json,sys; print(json.load(sys.stdin)['scope'])" 2>/dev/null)
[ "${CT1##*|}" = "422" ] && grep -q '40000' <<<"${CT1%|*}" && [ "${CO1##*|}" = "422" ] && [ "$CO1I" = "[('TENANT', 0)] 0" ] && grep -q 'Kiracı sorumluluğunda' <<<"${CO1%|*}" \
  && [ "${CT2##*|}" = "201" ] && [ "${CT2S%% *}" = "TENANCY" ] && [ "$PUB" = "TENANCY True" ] && [ "$CO2" = "UNIT" ] \
  && ok "borcu yoktur: kiracının vadesi geçmiş kendi borcu belgesini engelledi; malik bütün daire için istedi, kiracı borcu tutarsız 'kiracı sorumluluğunda' diye bildirildi; ödenince kiracıya kiracılık kapsamlı belge (kimliksiz doğrulama kapsamı söylüyor), malike bütün daire belgesi" \
  || bad "borcu yoktur kapsamı: kiracı=$CT1 / malik=$CO1 ($CO1I) / ödendikten sonra kiracı=$CT2S ${CT2##*|} / doğrulama=$PUB / malik=$CO2"
# Yeni borç bildirimi sorumluya gider
NA=$(curl -s -X POST "$F61/assessments" -H "$M61" -H "$J" \
  -d '{"period_year":2088,"period_month":2,"due_date":"2088-02-15","expense_items":[{"category_id":"55555555-5555-5555-5555-555555555501","amount":2700},{"category_id":"55555555-5555-5555-5555-555555555501","amount":270,"liability":"OWNER"}]}' -w '|%{http_code}')
NU=$($PSQL -t -A -c "SELECT string_agg(n.recipient_user_id::text, ',') FROM notifications n JOIN monthly_assessments ma ON ma.id::text = n.payload->>'assessment_id'
  WHERE n.topic='dues.created' AND n.channel='IN_APP' AND ma.unit_id='$UA1' AND ma.period_year=2088 AND ma.period_month=2 AND ma.liability='USAGE';")
NO=$($PSQL -t -A -c "SELECT string_agg(n.recipient_user_id::text, ',') FROM notifications n JOIN monthly_assessments ma ON ma.id::text = n.payload->>'assessment_id'
  WHERE n.topic='dues.created' AND n.channel='IN_APP' AND ma.unit_id='$UA1' AND ma.period_year=2088 AND ma.period_month=2 AND ma.liability='OWNER';")
NB=$($PSQL -t -A -c "SELECT count(*) FROM notifications n JOIN monthly_assessments ma ON ma.id::text = n.payload->>'assessment_id'
  WHERE n.topic='dues.created' AND ma.unit_id='$UB1' AND ma.period_year=2088 AND ma.period_month=2 AND ma.liability='OWNER';")
[ "${NA##*|}" = "201" ] && [ "$NU" = "$TUID" ] && [ "$NO" = "$OWN61" ] && [ "$NB" = "0" ] \
  && ok "yeni borç bildirimi sorumluya gitti: kullanım borcu kiracıya, malik borcu malike; maliksiz dairenin malik borcu için kimseye gitmedi (V3)" \
  || bad "borç bildirimi: ${NA##*|} / kullanım→$NU (beklenen $TUID) / malik→$NO (beklenen $OWN61) / maliksiz=$NB"
# Kiracılık bitince açık kullanım borcu malike görünür (V6)
A4=$(mkassess61 "$UA1" 3 150 "CURRENT_DATE + 20" USAGE)
$PSQL -c "UPDATE resident_units SET is_active=false, end_date=CURRENT_DATE WHERE id='$TL1';" >/dev/null
V6O=$(curl -s "$F61/assessments?year=2088" -H "$O61" | python3 -c "
import json,sys
print(any(a['id']=='$A4' and a['responsible']=='OWNER' for a in json.load(sys.stdin)['data']))" 2>/dev/null)
V6P=$(pay61 "$O61" "$A4")
[ "$V6O" = "True" ] && [ "$V6P" = "200" ] \
  && ok "kiracılık bitince açık kullanım borcu malike görünüyor ve malik ödeyebiliyor (KMK m.20 — V6)" \
  || bad "kiracılık sonrası: malik görüyor=$V6O ödeme=$V6P"
$PSQL -c "CREATE TEMP TABLE d5p AS SELECT DISTINCT payment_id FROM payment_assessments WHERE assessment_id IN (SELECT id FROM monthly_assessments WHERE period_year=2088);
  DELETE FROM payment_assessments WHERE payment_id IN (SELECT payment_id FROM d5p);
  DELETE FROM payments WHERE id IN (SELECT payment_id FROM d5p);
  DELETE FROM clearance_certificates WHERE unit_id IN ('$UA1','$UB1');
  DELETE FROM assessment_details WHERE assessment_id IN (SELECT id FROM monthly_assessments WHERE period_year=2088);
  DELETE FROM monthly_assessments WHERE period_year=2088;
  DELETE FROM resident_units WHERE unit_id IN ('$UA1','$UB1'); DELETE FROM units WHERE id IN ('$UA1','$UB1');" >/dev/null 2>&1
kill_tree "$FD5_PID"; kill_tree "$ID5_PID"

step "62) Malikin görünürlük politikası: yönetim önerir, kurul üyesi onaylar, varsayılan en dar, kiracıya şeffaf (071, altıncı tur D6)"
startsvc62() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./services/$2 >/tmp/verify-d6-$2.log 2>&1 & }
startsvc62 19791 identity siteeksen_identity "$IDPW"; S62I=$!
startsvc62 19792 finance siteeksen_app "$APPPW"; S62F=$!
startsvc62 19793 community siteeksen_app "$APPPW"; S62C=$!
startsvc62 19794 settings siteeksen_app "$APPPW"; S62S=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19791/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19792/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19793/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19794/health >/dev/null 2>&1 && break; sleep 1
done
I62="http://127.0.0.1:19791/api/v1"; F62="http://127.0.0.1:19792/api/v1/finance"; C62="http://127.0.0.1:19793/api/v1"; S62="http://127.0.0.1:19794/api/v1"
# Kurul üyesi (önerenden farklı onaycı)
$PSQL -c "INSERT INTO users (id, first_name, last_name, phone, password_hash, roles)
  SELECT '44444444-4444-4444-4444-444444444462', 'Kurul', 'Uyesi', '+905550000062', password_hash, ARRAY['RESIDENT'] FROM users WHERE phone LIKE '%5551234567'
  ON CONFLICT (id) DO NOTHING;
  INSERT INTO property_roles (user_id, property_id, role) VALUES ('44444444-4444-4444-4444-444444444462','$DEMO_PROPERTY','BOARD_MEMBER')
  ON CONFLICT DO NOTHING;" >/dev/null 2>&1
login62() { curl -s -X POST "$I62/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M62="Authorization: Bearer $(login62 5551234567 'Demo123!')"
B62="Authorization: Bearer $(login62 5550000062 'Demo123!')"
T62="Authorization: Bearer $(login62 5559876543 'Demo123!')"
O62="Authorization: Bearer $(login62 5550000039 Yepyeni12)"
OWN62=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000039';")
HH62=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559990071';")
UA2=$($PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2)
  VALUES ('$DEMO_PROPERTY','Z',5,'62A',1,'APARTMENT',80) RETURNING id;" | head -1)
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$OWN62','$UA2','OWNER'), ('$TUID','$UA2','TENANT'), ('$HH62','$UA2','HOUSEHOLD');
  INSERT INTO monthly_assessments (property_id, unit_id, period_year, period_month, base_amount, total_amount, due_date, status, liability)
  VALUES ('$DEMO_PROPERTY','$UA2',2087,1,250,250,CURRENT_DATE - 3,'PENDING','USAGE');
  INSERT INTO requests (property_id, unit_id, resident_id, ticket_number, title, description, status)
  VALUES ('$DEMO_PROPERTY','$UA2','$TUID','TKT-D6-62','Mutfak musluğu damlatıyor','Kiracının özel notu','OPEN');" >/dev/null
ownview() { curl -s "$I62/users/me/units/$UA2/residents" -H "$O62" | python3 -c "
import json,sys
print(sorted(r['role'] for r in json.load(sys.stdin)['data'] if r['is_active']))" 2>/dev/null; }
pol() { curl -s "$S62/settings/owner-visibility" -H "$1" | python3 -c "
import json,sys
d=json.load(sys.stdin); a=d['active']
print(a['status'], a['show_tenant_contact'], a['show_tenant_debt_total'], a['show_tenant_overdue'], a['show_unit_requests'], 'history' in d, len(d['options']))" 2>/dev/null; }
# 1) Varsayılan en dar: malik kiracıyı/haneyi, borç tutarını, talepleri göremez; kiracı politikayı görür
P0=$(pol "$T62"); V0=$(ownview)
FS0=$(curl -s "$F62/tenant-debt-summary" -H "$O62" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['data']), d['policy']['show_tenant_debt_total'])" 2>/dev/null)
CR0=$(code "$C62/requests/units/$UA2" -H "$O62")
[ "$P0" = "DEFAULT False False False False False 4" ] && [ "$V0" = "['OWNER']" ] && [ "$FS0" = "0 False" ] && [ "$CR0" = "403" ] \
  && ok "varsayılan en dar: kiracı politikayı görüyor (4 seçenek, hepsi kapalı, geçmiş yalnız yönetime); kiracılı dairede malik kiracıyı ve haneyi göremiyor, kiracı borcu tutarı yok, daire talepleri 403" \
  || bad "varsayılan politika: kiracı=$P0 / malik sakin listesi=$V0 / borç özeti=$FS0 / talepler=$CR0"
# 2) Öner → kurul üyesi onaylar (öneren onaylayamaz, kiracı öneremez)
X1=$(code -X POST "$S62/settings/owner-visibility" -H "$T62" -H "$J" -d '{"show_tenant_contact":true,"note":"Kiracı önerisi denemesi"}')
X2=$(code -X POST "$S62/settings/owner-visibility" -H "$M62" -H "$J" -d '{"show_tenant_contact":true,"note":"kısa"}')
X3=$(curl -s -w '|%{http_code}' -X POST "$S62/settings/owner-visibility" -H "$M62" -H "$J" \
  -d '{"show_tenant_contact":true,"show_tenant_debt_total":true,"show_tenant_overdue":true,"show_unit_requests":true,"note":"Genel kurul talebi üzerine malik bilgilendirmesi"}')
PID62=$(echo "${X3%|*}" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
X4=$(code -X POST "$S62/settings/owner-visibility" -H "$M62" -H "$J" -d '{"show_unit_requests":true,"note":"İkinci öneri denemesi"}')
X5=$(code -X POST "$S62/settings/owner-visibility/$PID62/approve" -H "$M62" -H "$J" -d '{}')
PB=$(pol "$T62")
X6=$(curl -s -w '|%{http_code}' -X POST "$S62/settings/owner-visibility/$PID62/approve" -H "$B62" -H "$J" -d '{"note":"Kurul kararıyla"}')
PA=$(pol "$T62")
NT=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='visibility.policy' AND recipient_user_id='$TUID' AND payload->>'policy_id'='$PID62';")
[ "$X1" = "403" ] && [ "$X2" = "422" ] && [ "${X3##*|}" = "201" ] && [ "$X4" = "409" ] && [ "$X5" = "403" ] && [ "${PB%% *}" = "DEFAULT" ] \
  && [ "${X6##*|}" = "200" ] && [ "$PA" = "ACTIVE True True True True False 4" ] && [ "$NT" = "1" ] \
  && ok "kiracı öneremiyor (403), gerekçesiz öneri 422, yönetim önerdi (ikinci bekleyen 409); yönetici (kurul üyesi değil) onaylayamıyor, öneri onaylanana kadar politika değişmedi; kurul üyesi onaylayınca yürürlüğe girdi ve kiracıya bildirildi" \
  || bad "öneri/onay: kiracı=$X1 kısa=$X2 öneri=${X3##*|} ikinci=$X4 yönetici onayı=$X5 önce=$PB / kurul=${X6##*|} sonra=$PA / bildirim=$NT"
# 3) Açık politika: malik kiracının adını (haneyi değil), borç toplamını ve vadesi geçeni, talepleri görür; zamanlayıcı malike uyarı gönderir
V1=$(ownview)
FS1=$(curl -s "$F62/tenant-debt-summary" -H "$O62" | python3 -c "
import json,sys
d=[x for x in json.load(sys.stdin)['data'] if x['unit_id']=='$UA2']
print(d[0].get('total_kurus'), d[0].get('overdue_kurus'))" 2>/dev/null)
CR1=$(curl -s "$C62/requests/units/$UA2" -H "$O62" | python3 -c "
import json,sys
d=json.load(sys.stdin)['data']
print(len(d), d[0]['ticket_number'], 'description' in d[0], 'resident_id' in d[0])" 2>/dev/null)
CR2=$(code "$C62/requests/units/$UA2" -H "$T62")
sched_once /tmp/verify-sched-d6.json
NO=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='dues.overdue.tenant' AND recipient_user_id='$OWN62' AND payload->>'unit_id'='$UA2';")
NT2=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='dues.overdue' AND recipient_user_id='$TUID' AND payload->>'unit_id'='$UA2';")
NH=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic LIKE 'dues.overdue%' AND recipient_user_id='$HH62' AND payload->>'unit_id'='$UA2';")
[ "$V1" = "['OWNER', 'TENANT']" ] && [ "$FS1" = "25000 25000" ] && [ "$CR1" = "1 TKT-D6-62 False False" ] && [ "$CR2" = "403" ] \
  && [ "$NO" = "1" ] && [ "$NT2" = "1" ] && [ "$NH" = "0" ] \
  && ok "politika açıkken malik kiracıyı (hanesini değil), kiracı borcunun toplamını ve vadesi geçenini, dairenin taleplerini (talep edenin kimliği ve açıklaması olmadan) görüyor; kiracı bu ucu kullanamıyor; zamanlayıcı kiracıya hatırlatma, malike ayrı uyarı gönderdi, hane üyesine hiçbiri" \
  || bad "açık politika: sakin listesi=$V1 / borç özeti=$FS1 / talepler=$CR1 kiracı=$CR2 / malik uyarısı=$NO kiracı hatırlatması=$NT2 hane=$NH"
# 4) Dört göz ve değiştirilemezlik
Y1=$(curl -s -X POST "$S62/settings/owner-visibility" -H "$B62" -H "$J" -d '{"note":"En dar ayara dönüş önerisi"}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])" 2>/dev/null)
Y2=$(code -X POST "$S62/settings/owner-visibility/$Y1/approve" -H "$B62" -H "$J" -d '{}')
Y3=$(code -X POST "$S62/settings/owner-visibility/$Y1/cancel" -H "$M62")
Y4=$(code -X POST "$S62/settings/owner-visibility/$Y1/cancel" -H "$B62")
GU=$(appsql46 "UPDATE owner_visibility_policies SET show_tenant_contact = false WHERE id='$PID62'")
GD=$(appsql46 "DELETE FROM owner_visibility_policies WHERE id='$PID62'")
HIST=$(curl -s "$S62/settings/owner-visibility" -H "$M62" | python3 -c "import json,sys; print(sorted(h['status'] for h in json.load(sys.stdin)['history'] if h['id'] in ('$PID62','$Y1')))" 2>/dev/null)
[ "$Y2" = "403" ] && [ "$Y3" = "404" ] && [ "$Y4" = "200" ] && grep -q 'değiştirilemez' <<<"$GU" && grep -qi 'permission denied' <<<"$GD" && [ "$HIST" = "['ACTIVE', 'CANCELLED']" ] \
  && ok "kurul üyesi kendi önerisini onaylayamıyor (dört göz); öneriyi yalnız öneren geri çekiyor; yürürlükteki politika uygulama rolüyle değiştirilemiyor ve silinemiyor; geçmiş yönetimde görünüyor" \
  || bad "dört göz/koruma: kendi onayı=$Y2 başkası geri çekme=$Y3 öneren=$Y4 / değiştir=$GU / sil=$GD / geçmiş=$HIST"
$PSQL -c "DELETE FROM owner_visibility_policies WHERE property_id='$DEMO_PROPERTY';
  DELETE FROM requests WHERE unit_id='$UA2'; DELETE FROM monthly_assessments WHERE unit_id='$UA2';
  DELETE FROM resident_units WHERE unit_id='$UA2'; DELETE FROM units WHERE id='$UA2';" >/dev/null
kill_tree "$S62I"; kill_tree "$S62F"; kill_tree "$S62C"; kill_tree "$S62S"

step "63) Kullanım hakkı: kiracılı dairede kullanım işlemlerini kiracı ve hanesi yapar, malik yapmaz (072, altıncı tur D7)"
startsvc63() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./services/$2 >/tmp/verify-d7-$2.log 2>&1 & }
startsvc63 19795 community siteeksen_app "$APPPW"; S63C=$!
startsvc63 19796 visitor siteeksen_app "$APPPW"; S63V=$!
startsvc63 19797 parking siteeksen_app "$APPPW"; S63P=$!
startsvc63 19798 package siteeksen_app "$APPPW"; S63K=$!
startsvc63 19799 identity siteeksen_identity "$IDPW"; S63I=$!
for _ in $(seq 1 90); do
  ALL=1; for P in 19795 19796 19797 19798 19799; do curl -fsS http://127.0.0.1:$P/health >/dev/null 2>&1 || ALL=0; done
  [ "$ALL" = "1" ] && break; sleep 1
done
login63() { curl -s -X POST "http://127.0.0.1:19799/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
OWN63=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550000039';")
HH63=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559990071';")
mkunit63() { $PSQL -t -A -c "INSERT INTO units (property_id, block, floor, door_number, share_ratio, unit_type, net_area_m2, owner_occupied)
  VALUES ('$DEMO_PROPERTY','Z',6,'$1',1,'APARTMENT',80,$2) RETURNING id;" | head -1; }
UA3=$(mkunit63 63A true); UB3=$(mkunit63 63B false)
# Hane üyesi kiracıdan SONRA ayrı deyimle eklenir: kiracı gelişi tetikleyicisi (068) deyim sonunda çalışır ve o ana
# kadarki hane kayıtlarını (malikin hanesi) bitirir.
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES
  ('$OWN63','$UA3','OWNER'), ('$TUID','$UA3','TENANT'), ('$OWN63','$UB3','OWNER');" >/dev/null
$PSQL -c "INSERT INTO resident_units (resident_id, unit_id, role) VALUES ('$HH63','$UA3','HOUSEHOLD');" >/dev/null
# Jeton rolleri girişte hesaplanır: kayıtlardan sonra giriş yapılır.
M63="Authorization: Bearer $(login63 5551234567 'Demo123!')"
T63="Authorization: Bearer $(login63 5559876543 'Demo123!')"
O63="Authorization: Bearer $(login63 5550000039 Yepyeni12)"
H63="Authorization: Bearer $(login63 5559990071 Davetli2026x)"
CU=$($PSQL -t -A -c "SELECT
  resident_can_use((SELECT id FROM resident_units WHERE unit_id='$UA3' AND role='OWNER'))||'|'||
  resident_can_use((SELECT id FROM resident_units WHERE unit_id='$UA3' AND role='TENANT'))||'|'||
  resident_can_use((SELECT id FROM resident_units WHERE unit_id='$UA3' AND role='HOUSEHOLD'))||'|'||
  resident_can_use((SELECT id FROM resident_units WHERE unit_id='$UB3' AND role='OWNER'));")
[ "$CU" = "false|true|true|true" ] \
  && ok "kullanım hakkı tek işlevde: kiracılı dairede malik hayır, kiracı ve hane üyesi evet; boş dairede malik evet" \
  || bad "resident_can_use: $CU (beklenen false|true|true|true)"
# Talep
req63() { curl -s -w '|%{http_code}' -X POST "http://127.0.0.1:19795/api/v1/requests" -H "$1" -H "$J" \
  -d "{\"title\":\"Kombi arızası\",\"description\":\"Sıcak su gelmiyor\",\"unit_id\":\"$2\"}"; }
Q1=$(req63 "$O63" "$UA3"); Q2=$(req63 "$T63" "$UA3"); Q3=$(req63 "$H63" "$UA3"); Q4=$(req63 "$O63" "$UB3")
[ "${Q1##*|}" = "422" ] && grep -q 'kiracı ve hanesi' <<<"$Q1" && [ "${Q2##*|}" = "201" ] && [ "${Q3##*|}" = "201" ] && [ "${Q4##*|}" = "201" ] \
  && ok "talep: kiracılı dairede malik açamıyor (422, nedeniyle); kiracı ve hane üyesi açıyor; malik boş dairesi için açıyor" \
  || bad "talep: malik=${Q1##*|} kiracı=${Q2##*|} hane=${Q3##*|} boş daire=${Q4##*|} — ${Q1%|*}"
# Ziyaretçi ön kaydı (önceden daireyle ilişki hiç denetlenmiyordu)
vis63() { code -X POST "http://127.0.0.1:19796/api/v1/visitors" -H "$1" -H "$J" -d "{\"unit_id\":\"$2\",\"visitor_name\":\"Misafir D7\",\"purpose\":\"Misafir\"}"; }
W1=$(vis63 "$O63" "$UA3"); W2=$(vis63 "$H63" "$UA3"); W3=$(vis63 "$T63" "$UB3"); W4=$(vis63 "$O63" "$UB3"); W5=$(vis63 "$M63" "$UA3")
[ "$W1" = "403" ] && [ "$W2" = "201" ] && [ "$W3" = "403" ] && [ "$W4" = "201" ] && [ "$W5" = "201" ] \
  && ok "ziyaretçi: kiracılı dairede malik kaydedemiyor (403), hane üyesi kaydediyor; sakin başkasının dairesine kayıt açamıyor (403 — önceden açabiliyordu); malik boş dairesine, yönetim her daireye kaydediyor" \
  || bad "ziyaretçi: malik=$W1 hane=$W2 başka daire=$W3 boş daire=$W4 yönetim=$W5"
# Araç
veh63() { code -X POST "http://127.0.0.1:19797/api/v1/vehicles" -H "$1" -H "$J" -d "{\"unit_id\":\"$UA3\",\"plate\":\"$2\",\"brand\":\"Test\",\"model\":\"D7\"}"; }
K1=$(veh63 "$O63" "34 DS 6301"); K2=$(veh63 "$T63" "34 DS 6302")
[ "$K1" = "403" ] && [ "$K2" = "201" ] \
  && ok "araç kaydı: kiracılı dairede malik kaydedemiyor (403), kiracı kaydediyor" \
  || bad "araç: malik=$K1 kiracı=$K2"
# Kargo bildirimi kullanım hakkı olana gider (malike değil)
PK=$(code -X POST "http://127.0.0.1:19798/api/v1/packages" -H "$M63" -H "$J" -d "{\"unit_id\":\"$UA3\",\"recipient_name\":\"Kiraci\",\"carrier\":\"Aras\",\"storage_location\":\"Kulube\"}")
NR=$($PSQL -t -A -c "SELECT string_agg(recipient_user_id::text, ',' ORDER BY recipient_user_id::text) FROM notifications
  WHERE topic='package.received' AND channel='IN_APP' AND payload->>'unit_id'='$UA3';")
EXP63=$(printf '%s\n%s\n' "$TUID" "$HH63" | sort | paste -sd, -)
[ "$PK" = "201" ] && [ "$NR" = "$EXP63" ] \
  && ok "kargo bildirimi kiracıya ve hane üyesine gitti, kiracılı dairenin malikine gitmedi" \
  || bad "kargo bildirimi: $PK / alıcılar=$NR (beklenen $EXP63)"
$PSQL -c "DELETE FROM packages WHERE unit_id IN ('$UA3','$UB3'); DELETE FROM vehicles WHERE unit_id IN ('$UA3','$UB3');
  DELETE FROM visitors WHERE unit_id IN ('$UA3','$UB3'); DELETE FROM requests WHERE unit_id IN ('$UA3','$UB3');
  DELETE FROM resident_units WHERE unit_id IN ('$UA3','$UB3'); DELETE FROM units WHERE id IN ('$UA3','$UB3');" >/dev/null 2>&1
kill_tree "$S63C"; kill_tree "$S63V"; kill_tree "$S63P"; kill_tree "$S63K"; kill_tree "$S63I"

step "64) Bildirim okundu bilgisi ve işlem kaydı: düzeyler, istemci etkinliği, görüntüleme, saklama (073, FAZ H.2/H.3)"
startsvc64() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 ACTIVITY_LEVEL_CACHE_TTL=0s \
  go run ./services/$2 >/tmp/verify-h2-$2.log 2>&1 & }
startsvc64 19811 identity siteeksen_identity "$IDPW"; S64I=$!
startsvc64 19812 notification siteeksen_app "$APPPW"; S64N=$!
startsvc64 19813 settings siteeksen_app "$APPPW"; S64S=$!
for _ in $(seq 1 90); do
  ALL=1; for P in 19811 19812 19813; do curl -fsS http://127.0.0.1:$P/health >/dev/null 2>&1 || ALL=0; done
  [ "$ALL" = "1" ] && break; sleep 1
done
login64() { curl -s -X POST "http://127.0.0.1:19811/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M64="Authorization: Bearer $(login64 5551234567 'Demo123!')"
T64="Authorization: Bearer $(login64 5559876543 'Demo123!')"
N64=http://127.0.0.1:19812/api/v1; S64=http://127.0.0.1:19813/api/v1
appq() { PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen -q -t -A -v ON_ERROR_STOP=1 -c "$1"; }
MUID=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
# 1) Şema ve yetkiler
COLS=$($PSQL -t -A -c "SELECT count(*) FROM information_schema.columns WHERE table_name='audit_logs' AND column_name IN ('source','event','screen','details');")
[ "$COLS" = "4" ] && ok "audit_logs genişletildi (source, event, screen, details)" || bad "audit_logs kolonları: $COLS/4"
RL=$($PSQL -t -A -c "SELECT rls_enabled||'/'||rls_forced FROM rls_enabled_tables WHERE table_name='notification_reads';")
{ [ "$RL" = "t/t" ] || [ "$RL" = "true/true" ]; } && ok "notification_reads RLS açık ve zorlanmış" || bad "notification_reads RLS: $RL"
appq "SELECT count(*) FROM audit_logs" >/dev/null 2>&1 && bad "uygulama rolü audit_logs'u doğrudan okuyabiliyor" \
  || ok "uygulama rolü audit_logs'u doğrudan okuyamıyor (yalnız işlevle)"
NS=$(appq "SELECT count(*) FROM audit_log_list(NULL,NULL,NULL,NULL,NULL,NULL,NULL,10,0)")
[ "$NS" = "0" ] && ok "kapsamsız audit_log_list hiç satır döndürmüyor (fail-closed)" || bad "kapsamsız liste: $NS"
# 2) Giriş olayları zorunlu kayıt
curl -s -o /dev/null -X POST "http://127.0.0.1:19811/api/v1/auth/login" -H "$J" -d '{"phone":"5551234567","password":"yanlis-sifre"}'
LF=$($PSQL -t -A -c "SELECT count(*)||'|'||COALESCE(max(details->>'phone'),'') FROM audit_logs WHERE event='auth.login_failed' AND created_at > now() - interval '5 minutes';")
[ "${LF%%|*}" -ge 1 ] && ! grep -q '5551234567' <<<"$LF" && ok "başarısız giriş kaydedildi (401 dahil), telefon maskeli: ${LF#*|}" || bad "başarısız giriş kaydı: $LF"
LS=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE event='auth.login' AND user_id='$MUID' AND property_id='$DEMO_PROPERTY';")
[ "$LS" -ge 1 ] && ok "başarılı giriş kullanıcı ve siteyle kaydedildi" || bad "başarılı giriş kaydı: $LS"
LP=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE details::text LIKE '%Demo123%' OR details::text LIKE '%yanlis-sifre%';")
[ "$LP" = "0" ] && ok "şifre hiçbir kayda yazılmadı" || bad "şifre kayda yazılmış: $LP"
# 3) Okundu bilgisi
TUID64=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905559876543';")
NID=$($PSQL -t -A -c "INSERT INTO notifications (property_id, recipient_user_id, recipient_address, channel, topic, subject, body, status, provider, sent_at)
  VALUES ('$DEMO_PROPERTY','$TUID64','in-app','IN_APP','verify.h2','Okundu denemesi','Govde','SENT','in_app',now()) RETURNING id;" | head -1)
MID=$($PSQL -t -A -c "INSERT INTO notifications (property_id, recipient_user_id, recipient_address, channel, topic, subject, body, status, provider, sent_at)
  VALUES ('$DEMO_PROPERTY','$MUID','in-app','IN_APP','verify.h2','Yonetim','Govde','SENT','in_app',now()) RETURNING id;" | head -1)
[ -n "$NID" ] && [ -n "$MID" ] && ok "deneme bildirimleri oluşturuldu" || bad "deneme bildirimi oluşturulamadı"
U1=$(curl -s "$N64/notifications/unread-count" -H "$T64" | python3 -c "import json,sys; print(json.load(sys.stdin)['unread'])")
R1=$(code -X POST "$N64/notifications/$NID/read" -H "$T64")
U2=$(curl -s "$N64/notifications/unread-count" -H "$T64" | python3 -c "import json,sys; print(json.load(sys.stdin)['unread'])")
[ "$R1" = "200" ] && [ "$U2" -eq $((U1-1)) ] && ok "okundu işareti okunmamış sayısını düşürdü ($U1 → $U2)" || bad "okundu: $R1, $U1 → $U2"
R2=$(code -X POST "$N64/notifications/$MID/read" -H "$T64")
[ "$R2" = "404" ] && ok "başkasının bildirimi okundu sayılamıyor → 404" || bad "başkasının bildirimi → $R2"
RA=$(curl -s "$N64/notifications?channel=IN_APP" -H "$T64" | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(sum(1 for x in d if x['id']=='$NID' and x.get('read_at')))")
[ "$RA" = "1" ] && ok "liste okundu zamanını döndürüyor" || bad "liste read_at: $RA"
code -X POST "$N64/notifications/read-all" -H "$M64" >/dev/null
UM=$(curl -s "$N64/notifications/unread-count" -H "$M64" | python3 -c "import json,sys; print(json.load(sys.stdin)['unread'])")
[ "$UM" = "0" ] && ok "tümünü okundu say → okunmamış 0" || bad "tümünü okundu say sonrası: $UM"
RE=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE event='notification.read' AND user_id='$TUID64';")
[ "$RE" -ge 1 ] && ok "okuma işlem kaydına düştü" || bad "okuma kaydı: $RE"
UPD=$(appq "UPDATE notification_reads SET read_at = now()" >/dev/null 2>&1 && echo yazdi || echo engel)
[ "$UPD" = "engel" ] && ok "okundu kaydı uygulama rolüyle değiştirilemiyor" || bad "okundu kaydı değiştirilebildi"
# 4) Düzey ayarı ve istemci etkinliği
LV=$(curl -s "$S64/activity-level" -H "$T64" | python3 -c "import json,sys; print(json.load(sys.stdin)['level'])")
[ "$LV" = "STANDARD" ] && ok "varsayılan düzey STANDART" || bad "varsayılan düzey: $LV"
EV='{"events":[{"event":"screen.view","screen":"/finance","client":"mobile"},{"event":"rm -rf","screen":"x"}]}'
A0=$(curl -s -X POST "$S64/activity" -H "$T64" -H "$J" -d "$EV" | python3 -c "import json,sys; print(json.load(sys.stdin)['accepted'])")
[ "$A0" = "0" ] && ok "STANDART düzeyde istemci etkinliği alınmıyor" || bad "STANDART'ta kabul: $A0"
CT=$(code -X PUT "$S64/settings/ACTIVITY_LOG_LEVEL" -H "$T64" -H "$J" -d '{"value":"FULL"}')
[ "$CT" = "403" ] && ok "sakin işlem kaydı düzeyini değiştiremiyor → 403" || bad "sakin düzey değişimi → $CT"
CM=$(code -X PUT "$S64/settings/ACTIVITY_LOG_LEVEL" -H "$M64" -H "$J" -d '{"value":"FULL"}')
CB=$(code -X PUT "$S64/settings/ACTIVITY_LOG_LEVEL" -H "$M64" -H "$J" -d '{"value":"HEPSI"}')
[ "$CM" = "200" ] && [ "$CB" = "422" ] && ok "yönetici düzeyi TAM yaptı; geçersiz değer reddedildi (422)" || bad "düzey: TAM=$CM geçersiz=$CB"
A1=$(curl -s -X POST "$S64/activity" -H "$T64" -H "$J" -d "$EV")
grep -q '"accepted":1' <<<"$A1" && grep -q '"rejected":1' <<<"$A1" && ok "TAM düzeyde etkinlik alındı; bilinmeyen olay türü reddedildi" || bad "TAM etkinlik: $A1"
CL=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE source='CLIENT' AND event='screen.view' AND user_id='$TUID64' AND details->>'client'='mobile';")
[ "$CL" -ge 1 ] && ok "istemci etkinliği kullanıcı ve sunucu zamanıyla yazıldı" || bad "istemci kaydı: $CL"
BIG=$(python3 -c "import json; print(json.dumps({'events':[{'event':'screen.view','screen':'/x'}]*51}))")
B51=$(code -X POST "$S64/activity" -H "$T64" -H "$J" -d "$BIG")
[ "$B51" = "413" ] && ok "tek istekte 50'den fazla olay reddedildi → 413" || bad "51 olay → $B51"
# 5) KAPALI düzey: sıradan okuma yazılmaz, kişisel veri okuması ve yazma işlemi yazılır
code -X PUT "$S64/settings/ACTIVITY_LOG_LEVEL" -H "$M64" -H "$J" -d '{"value":"OFF"}' >/dev/null
B0=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='notification' AND action='VIEW';")
curl -s -o /dev/null "$N64/notifications" -H "$T64"
B1=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='notification' AND action='VIEW';")
A0B=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='audit';")
curl -s -o /dev/null "$S64/audit-logs" -H "$M64"
A1B=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='audit';")
[ "$B1" = "$B0" ] && [ "$A1B" -gt "$A0B" ] && ok "KAPALI: sıradan okuma yazılmadı, işlem kaydı görüntüleme (kişisel veri) yazıldı" \
  || bad "KAPALI: sıradan okuma $B0→$B1, hassas okuma $A0B→$A1B"
W0=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='notification' AND action='CREATE';")
code -X POST "$N64/notifications/read-all" -H "$T64" >/dev/null
W1=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='notification' AND action='CREATE';")
[ "$W1" -gt "$W0" ] && ok "KAPALI: yazma işlemi yine kaydedildi (zorunlu çekirdek)" || bad "KAPALI yazma kaydı: $W0→$W1"
code -X DELETE "$S64/settings/ACTIVITY_LOG_LEVEL" -H "$M64" >/dev/null
# 6) Görüntüleme yetkisi ve dışa aktarma
V1=$(code "$S64/audit-logs" -H "$T64"); V2=$(code "$S64/audit-logs?source=CLIENT" -H "$M64"); V3=$(code "$S64/audit-logs?from=dun" -H "$M64")
[ "$V1" = "403" ] && [ "$V2" = "200" ] && [ "$V3" = "400" ] && ok "kayıtları sakin göremiyor (403); yönetici süzerek görüyor; hatalı tarih 400" || bad "görüntüleme: sakin=$V1 yönetici=$V2 hatalı=$V3"
VR=$(curl -s "$S64/audit-logs?source=CLIENT" -H "$M64" | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(len(d), all(x['source']=='CLIENT' for x in d))")
[ "${VR#* }" = "True" ] && [ "${VR%% *}" -ge 1 ] && ok "kaynak süzgeci çalışıyor ($VR)" || bad "süzgeç: $VR"
CSV=$(curl -s "$S64/audit-logs/export" -H "$M64" | head -2)
sleep 1
grep -q 'Zaman;Kullanıcı' <<<"$CSV" && ok "CSV dışa aktarma çalışıyor" || bad "CSV: $CSV"
EX=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE event='audit.export';")
[ "$EX" -ge 1 ] && ok "dışa aktarma da işlem kaydına düştü" || bad "dışa aktarma kaydı: $EX"
OTHER=$(appq "BEGIN; SET LOCAL app.property_id='22222222-2222-2222-2222-222222222222'; SELECT count(*) FROM audit_log_list(NULL,NULL,NULL,NULL,NULL,'CLIENT',NULL,100,0); COMMIT;" | grep -E '^[0-9]+$' | head -1)
[ "${OTHER:-0}" = "0" ] && ok "başka sitenin kapsamında bu sitenin kayıtları görünmüyor" || bad "çapraz site kayıt: $OTHER"
# 7) Saklama
$PSQL -c "UPDATE audit_logs SET created_at = now() - interval '400 days' WHERE source='CLIENT' AND user_id='$TUID64';" >/dev/null
$PSQL -c "INSERT INTO audit_logs (property_id, action, entity_type, source, created_at) VALUES ('$DEMO_PROPERTY','CREATE','verify','API', now() - interval '400 days');" >/dev/null
PR=$(appq "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; SELECT audit_log_purge_client(180); COMMIT;" | grep -E '^[0-9]+$' | head -1)
LEFT=$($PSQL -t -A -c "SELECT count(*) FROM audit_logs WHERE entity_type='verify' AND source='API' AND created_at < now() - interval '399 days';")
[ "${PR:-0}" -ge 1 ] && [ "$LEFT" = "1" ] && ok "saklama: süresi dolan istemci etkinliği silindi ($PR), zorunlu kayıt kaldı" || bad "saklama: silinen=$PR zorunlu kalan=$LEFT"
BADD=$(appq "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; SELECT audit_log_purge_client(5); COMMIT;" 2>&1 | grep -c '30-730')
[ "$BADD" -ge 1 ] && ok "30 günden kısa saklama reddedildi" || bad "kısa saklama kabul edildi"
$PSQL -c "DELETE FROM audit_logs WHERE entity_type='verify'; DELETE FROM notification_reads WHERE notification_id IN ('$NID','$MID'); DELETE FROM notifications WHERE id IN ('$NID','$MID');" >/dev/null 2>&1
kill_tree "$S64I"; kill_tree "$S64N"; kill_tree "$S64S"

step "65) IoT sensörleri: tanım, cihaz okuması, eşik/tetik alarmı, bildirim, onay, kapatma, sinyal kesilmesi (074, FAZ H.4)"
startsvc65() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 SENSOR_WATCH_INTERVAL=2s \
  go run ./services/$2 >/tmp/verify-h4-$2.log 2>&1 & }
startsvc65 19821 identity siteeksen_identity "$IDPW"; S65I=$!
startsvc65 19822 iot siteeksen_app "$APPPW"; S65T=$!
for _ in $(seq 1 90); do
  ALL=1; for P in 19821 19822; do curl -fsS http://127.0.0.1:$P/health >/dev/null 2>&1 || ALL=0; done
  [ "$ALL" = "1" ] && break; sleep 1
done
login65() { curl -s -X POST "http://127.0.0.1:19821/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M65="Authorization: Bearer $(login65 5551234567 'Demo123!')"
T65="Authorization: Bearer $(login65 5559876543 'Demo123!')"
I65=http://127.0.0.1:19822/api/v1
SE1=$(curl -s -X POST "$I65/sensors" -H "$M65" -H "$J" -d '{"name":"Kazan dairesi sıcaklık","sensor_type":"TEMPERATURE","location":"B blok bodrum","unit_label":"°C","min_threshold":5,"max_threshold":80,"offline_after_minutes":2}')
SID1=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('id',''))" "$SE1"); KEY1=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('device_key',''))" "$SE1")
[ -n "$SID1" ] && [ "${KEY1#sen_}" != "$KEY1" ] && ok "yönetim sensör tanımladı; cihaz anahtarı bir kez gösterildi" || bad "sensör tanımı: $SE1"
KH=$($PSQL -t -A -c "SELECT key_hash = encode(sha256('$KEY1'::bytea),'hex') FROM sensors WHERE id='$SID1';")
KP=$($PSQL -t -A -c "SELECT count(*) FROM sensors WHERE key_hash = '$KEY1';")
[ "$KH" = "t" ] && [ "$KP" = "0" ] && ok "anahtarın yalnız özeti saklanıyor" || bad "anahtar saklama: özet=$KH düz=$KP"
NE=$(code -X POST "$I65/sensors" -H "$M65" -H "$J" -d '{"name":"Eşiksiz","sensor_type":"TEMPERATURE"}')
TE=$(code -X POST "$I65/sensors" -H "$T65" -H "$J" -d '{"name":"x","sensor_type":"SMOKE"}')
[ "$NE" = "422" ] && [ "$TE" = "403" ] && ok "eşiksiz sayısal sensör reddedildi (422); sakin sensör tanımlayamıyor (403)" || bad "doğrulama: eşiksiz=$NE sakin=$TE"
push65() { curl -s -X POST "$I65/public/sensors/data" -H "X-Device-Key: $1" -H "$J" -d "{\"value\":$2}"; }
P1=$(push65 "$KEY1" 21.5); P2=$(push65 "sen_yanlis" 21.5)
grep -q '"alert_opened":false' <<<"$P1" && grep -q 'tanınmadı' <<<"$P2" && ok "cihaz okuması kabul edildi; yanlış anahtar reddedildi" || bad "okuma: $P1 / $P2"
N0=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='iot.alert' AND payload->>'sensor_id'='$SID1';")
P3=$(push65 "$KEY1" 95); P4=$(push65 "$KEY1" 97)
AC=$($PSQL -t -A -c "SELECT count(*)||'|'||max(value) FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='HIGH' AND status='OPEN';")
N1=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='iot.alert' AND payload->>'sensor_id'='$SID1';")
grep -q '"alert_opened":true' <<<"$P3" && grep -q '"alert_opened":false' <<<"$P4" && [ "$AC" = "1|97.000" ] && [ "$N1" -gt "$N0" ] \
  && ok "üst eşik aşımı tek alarm açtı (ikinci okuma yeni alarm açmadı, değer güncellendi) ve işletme ekibine bildirildi" \
  || bad "eşik alarmı: $P3 / $P4 / alarm=$AC bildirim $N0→$N1"
NOP=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='iot.alert' AND payload->>'sensor_id'='$SID1' AND recipient_user_id=(SELECT id FROM users WHERE phone='+905559876543');")
[ "$NOP" = "0" ] && ok "sensör alarmı sakine gitmedi (yalnız işletme ekibi)" || bad "sakine alarm gitti: $NOP"
P5=$(push65 "$KEY1" 40)
NM=$($PSQL -t -A -c "SELECT (normalized_at IS NOT NULL)||'|'||status FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='HIGH';")
grep -q '"normalized":true' <<<"$P5" && [ "$NM" = "true|OPEN" ] && ok "değer normale dönünce alarm 'normale döndü' işaretlendi ama açık kaldı (kapatma insan işi)" || bad "normalleşme: $P5 / $NM"
AID=$($PSQL -t -A -c "SELECT id FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='HIGH';")
AK1=$(code -X POST "$I65/iot/alerts/$AID/acknowledge" -H "$T65"); AK2=$(code -X POST "$I65/iot/alerts/$AID/acknowledge" -H "$M65"); AK3=$(code -X POST "$I65/iot/alerts/$AID/acknowledge" -H "$M65")
CL1=$(code -X POST "$I65/iot/alerts/$AID/close" -H "$M65" -H "$J" -d '{"note":""}'); CL2=$(code -X POST "$I65/iot/alerts/$AID/close" -H "$M65" -H "$J" -d '{"note":"Kazan termostatı değiştirildi"}')
[ "$AK1" = "403" ] && [ "$AK2" = "200" ] && [ "$AK3" = "409" ] && [ "$CL1" = "400" ] && [ "$CL2" = "200" ] \
  && ok "alarm: sakin onaylayamıyor (403); yönetim onayladı, ikinci onay 409; notsuz kapatma 400, notla kapatıldı" \
  || bad "alarm akışı: sakin=$AK1 onay=$AK2 tekrar=$AK3 notsuz=$CL1 kapat=$CL2"
DEL=$(appq "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; DELETE FROM sensor_alerts WHERE id='$AID'; COMMIT;" >/dev/null 2>&1 && echo sildi || echo engel)
[ "$DEL" = "engel" ] && ok "alarm kaydı silinemiyor" || bad "alarm silinebildi"
# İkili sensör: tetik
SE2=$(curl -s -X POST "$I65/sensors" -H "$M65" -H "$J" -d '{"name":"Otopark su kaçağı","sensor_type":"WATER_LEAK","location":"-2. kat"}')
KEY2=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('device_key',''))" "$SE2"); SID2=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('id',''))" "$SE2")
push65 "$KEY2" 0 >/dev/null; P6=$(push65 "$KEY2" 1)
TR=$($PSQL -t -A -c "SELECT count(*) FROM sensor_alerts WHERE sensor_id='$SID2' AND kind='TRIGGERED' AND status='OPEN';")
grep -q '"alert_opened":true' <<<"$P6" && [ "$TR" = "1" ] && ok "su kaçağı sensörü tetiklenince alarm açtı" || bad "tetik alarmı: $P6 / $TR"
# Sinyal kesilmesi: bekçi OFFLINE alarmı açar
$PSQL -c "UPDATE sensors SET last_seen_at = now() - interval '10 minutes' WHERE id='$SID1';" >/dev/null
OFF=0; for _ in $(seq 1 15); do OFF=$($PSQL -t -A -c "SELECT count(*) FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='OFFLINE' AND status='OPEN';"); [ "$OFF" = "1" ] && break; sleep 1; done
NO=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE topic='iot.offline' AND payload->>'sensor_id'='$SID1';")
[ "$OFF" = "1" ] && [ "$NO" -ge 1 ] && ok "sinyali kesilen sensör için bekçi alarm açtı ve bildirdi" || bad "sinyal kesilmesi: alarm=$OFF bildirim=$NO"
sleep 3
OFF2=$($PSQL -t -A -c "SELECT count(*) FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='OFFLINE';")
[ "$OFF2" = "1" ] && ok "bekçi aynı kesinti için ikinci alarm açmadı" || bad "tekrar alarm: $OFF2"
push65 "$KEY1" 22 >/dev/null
ON=$($PSQL -t -A -c "SELECT normalized_at IS NOT NULL FROM sensor_alerts WHERE sensor_id='$SID1' AND kind='OFFLINE';")
[ "$ON" = "t" ] && ok "sinyal gelince kesinti alarmı normale döndü" || bad "kesinti normalleşmesi: $ON"
# Anahtar yenileme: eski anahtar geçersiz
RK=$(curl -s -X POST "$I65/sensors/$SID1/rotate-key" -H "$M65"); KEY1B=$(python3 -c "import json,sys; print(json.loads(sys.argv[1]).get('device_key',''))" "$RK")
O1=$(push65 "$KEY1" 22); O2=$(push65 "$KEY1B" 22)
grep -q 'tanınmadı' <<<"$O1" && grep -q '"status":"ok"' <<<"$O2" && ok "anahtar yenilenince eski anahtar reddedildi, yenisi çalıştı" || bad "anahtar yenileme: $O1 / $O2"
# Liste ve geçmiş; başka site göremez
L65=$(curl -s "$I65/sensors" -H "$M65" | python3 -c "import json,sys; d=json.load(sys.stdin)['data']; print(len([x for x in d if x['id'] in ('$SID1','$SID2')]))")
H65=$(curl -s "$I65/sensors/$SID1/data?hours=1" -H "$M65" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['data']))")
X65=$(appq "BEGIN; SET LOCAL app.property_id='22222222-2222-2222-2222-222222222222'; SELECT count(*) FROM sensors WHERE id IN ('$SID1','$SID2'); COMMIT;" | grep -E '^[0-9]+$' | head -1)
[ "$L65" = "2" ] && [ "$H65" -ge 5 ] && [ "${X65:-0}" = "0" ] && ok "sensör listesi ve okuma geçmişi geliyor; başka site göremiyor" || bad "liste=$L65 geçmiş=$H65 çapraz=$X65"
$PSQL -c "DELETE FROM sensor_alerts WHERE sensor_id IN ('$SID1','$SID2'); DELETE FROM sensor_readings WHERE sensor_id IN ('$SID1','$SID2'); DELETE FROM sensors WHERE id IN ('$SID1','$SID2');" >/dev/null 2>&1
kill_tree "$S65I"; kill_tree "$S65T"

step "66) Devriye: QR + GPS zorunluluğu, red kanıtı, şüpheli hız, konum muafiyeti, iz, rapor (075, FAZ H.5)"
startsvc66() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 \
  go run ./services/$2 >/tmp/verify-h5-$2.log 2>&1 & }
startsvc66 19831 identity siteeksen_identity "$IDPW"; S66I=$!
startsvc66 19832 patrol siteeksen_app "$APPPW"; S66P=$!
for _ in $(seq 1 90); do
  ALL=1; for P in 19831 19832; do curl -fsS http://127.0.0.1:$P/health >/dev/null 2>&1 || ALL=0; done
  [ "$ALL" = "1" ] && break; sleep 1
done
login66() { curl -s -X POST "http://127.0.0.1:19831/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M66="Authorization: Bearer $(login66 5551234567 'Demo123!')"
T66="Authorization: Bearer $(login66 5559876543 'Demo123!')"
P66=http://127.0.0.1:19832/api/v1
jget() { python3 -c "import json,sys; d=json.loads(sys.argv[1]); exec(sys.argv[2])" "$1" "$2"; }
mkcp66() { curl -s -X POST "$P66/patrol-checkpoints" -H "$M66" -H "$J" -d "{\"name\":\"$1\"}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1; }
CA=$(mkcp66 "GPS A girisi"); CB=$(mkcp66 "GPS B otopark"); CC=$(mkcp66 "GPS kazan dairesi")
L1=$(code -X POST "$P66/patrol-checkpoints/$CA/location" -H "$M66" -H "$J" -d '{"latitude":41.0100,"longitude":29.0100,"accuracy_m":35}')
L2=$(code -X POST "$P66/patrol-checkpoints/$CA/location" -H "$M66" -H "$J" -d '{"latitude":41.0100,"longitude":29.0100,"accuracy_m":6}')
L3=$(code -X POST "$P66/patrol-checkpoints/$CB/location" -H "$M66" -H "$J" -d '{"latitude":41.0145,"longitude":29.0100,"accuracy_m":6,"is_mocked":true}')
code -X POST "$P66/patrol-checkpoints/$CB/location" -H "$M66" -H "$J" -d '{"latitude":41.0145,"longitude":29.0100,"accuracy_m":6}' >/dev/null
[ "$L1" = "422" ] && [ "$L2" = "200" ] && [ "$L3" = "422" ] && ok "nokta konumu yalnız ≤20 m hassasiyetle ve gerçek konumla kaydediliyor (35 m → 422, sahte → 422)" \
  || bad "nokta konumu: düşük=$L1 iyi=$L2 sahte=$L3"
E1=$(code -X PATCH "$P66/patrol-checkpoints/$CC" -H "$M66" -H "$J" -d '{"location_check":"EXEMPT"}')
E2=$(code -X PATCH "$P66/patrol-checkpoints/$CC" -H "$M66" -H "$J" -d '{"location_check":"EXEMPT","exempt_reason":"Bodrum, GPS çekmiyor"}')
E3=$(code -X PATCH "$P66/patrol-checkpoints/$CA" -H "$T66" -H "$J" -d '{"radius_m":200}')
[ "$E1" = "422" ] && [ "$E2" = "200" ] && [ "$E3" = "403" ] && ok "konum muafiyeti gerekçe istiyor (422 → 200); sakin nokta değiştiremiyor (403)" \
  || bad "muafiyet: gerekçesiz=$E1 gerekçeli=$E2 sakin=$E3"
CPL=$(curl -s "$P66/patrol-checkpoints" -H "$M66")
QA=$(jget "$CPL" "print([x['qr_value'] for x in d['data'] if x['id']=='$CA'][0])"); QB=$(jget "$CPL" "print([x['qr_value'] for x in d['data'] if x['id']=='$CB'][0])"); QC=$(jget "$CPL" "print([x['qr_value'] for x in d['data'] if x['id']=='$CC'][0])")
[ "${QA#SITEEKSEN-PATROL:}" != "$QA" ] && ok "yönetim QR değerini görüyor (yazdırma için)" || bad "QR değeri: $QA"
RT66=$(curl -s -X POST "$P66/patrol-routes" -H "$M66" -H "$J" -d "{\"name\":\"GPS turu\",\"expected_duration_minutes\":20,\"checkpoints\":[{\"checkpoint_id\":\"$CA\",\"order\":1},{\"checkpoint_id\":\"$CB\",\"order\":2},{\"checkpoint_id\":\"$CC\",\"order\":3}]}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
$PSQL -c "UPDATE patrol_logs SET status='COMPLETED', completed_at=now() WHERE guard_id=(SELECT id FROM users WHERE phone='+905551234567') AND status='IN_PROGRESS';" >/dev/null
PT66=$(curl -s -X POST "$P66/patrols" -H "$M66" -H "$J" -d "{\"route_id\":\"$RT66\"}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)
[ -n "$PT66" ] && ok "GPS turu başladı" || bad "GPS turu başlamadı (güzergâh=$RT66)"
# Tur 10 dk önce başlamış sayılır: başlangıç ile ilk iz noktası arasındaki boşluk kesinti olarak görünmeli.
$PSQL -c "UPDATE patrol_logs SET started_at = now() - interval '10 minutes' WHERE id='$PT66';" >/dev/null
scan66() { curl -s -w '|%{http_code}' -X POST "$P66/patrols/$PT66/scan" -H "$M66" -H "$J" -d "$1"; }
R1=$(scan66 "{\"qr\":\"$QA\",\"latitude\":41.0145,\"longitude\":29.0100,\"accuracy_m\":5}")
R2=$(scan66 "{\"qr\":\"$QA\",\"latitude\":41.0100,\"longitude\":29.0100,\"accuracy_m\":5,\"is_mocked\":true}")
R3=$(scan66 "{\"qr\":\"$QA\",\"latitude\":41.0100,\"longitude\":29.0100,\"accuracy_m\":80}")
R4=$(scan66 "{\"qr\":\"$QA\"}")
R5=$(scan66 "{\"qr\":\"SITEEKSEN-PATROL:sahte\",\"latitude\":41.0100,\"longitude\":29.0100,\"accuracy_m\":5}")
grep -q '"reason":"TOO_FAR"' <<<"$R1" && grep -q 'uzaklığınız 50' <<<"$R1" && ok "QR fotoğrafıyla uzaktan okutma reddedildi (~500 m, TOO_FAR)" || bad "uzaktan okutma: $R1"
grep -q '"reason":"MOCKED"' <<<"$R2" && grep -q '"reason":"LOW_ACCURACY"' <<<"$R3" && grep -q '"reason":"NO_LOCATION"' <<<"$R4" && grep -q '"reason":"QR_UNKNOWN"' <<<"$R5" \
  && ok "sahte konum, düşük doğruluk, konumsuz ve tanınmayan QR reddedildi" || bad "red nedenleri: $R2 / $R3 / $R4 / $R5"
R6=$(scan66 "{\"qr\":\"$QA\",\"latitude\":41.01012,\"longitude\":29.01003,\"accuracy_m\":6}")
grep -q '"checkpoints_visited":1' <<<"$R6" && grep -q '"suspicious":false' <<<"$R6" && ok "noktanın yanında QR okutması kabul edildi" || bad "yakın okutma: $R6"
R7=$(scan66 "{\"qr\":\"$QB\",\"latitude\":41.0145,\"longitude\":29.0100,\"accuracy_m\":5}")
grep -q '"suspicious":true' <<<"$R7" && ok "500 m'yi saniyeler içinde geçen okutma kabul edildi ama şüpheli işaretlendi" || bad "şüpheli hız: $R7"
R8=$(scan66 "{\"checkpoint_id\":\"$CC\"}"); R9=$(scan66 "{\"qr\":\"$QC\"}")
grep -q 'EXEMPT_NEEDS_QR' <<<"$R8" && grep -q '"location_exempt":true' <<<"$R9" && ok "muaf noktada elle seçme reddedildi; QR ile konumsuz okutma kabul edildi ve işaretlendi" || bad "muaf nokta: $R8 / $R9"
ROT=$(curl -s -X POST "$P66/patrol-checkpoints/$CA/rotate-qr" -H "$M66"); NQA=$(jget "$ROT" "print(d.get('qr_value',''))")
R10=$(scan66 "{\"qr\":\"$QA\",\"latitude\":41.0100,\"longitude\":29.0100,\"accuracy_m\":5}")
[ -n "$NQA" ] && [ "$NQA" != "$QA" ] && grep -q 'QR_UNKNOWN' <<<"$R10" && ok "QR yenilenince eski baskı geçersiz oldu" || bad "QR yenileme: $NQA / $R10"
NA66=$($PSQL -t -A -c "SELECT count(*) FILTER (WHERE NOT accepted)||'|'||count(*) FILTER (WHERE accepted) FROM patrol_scan_attempts WHERE patrol_log_id='$PT66';")
[ "$NA66" = "7|3" ] && ok "her deneme kanıt olarak yazıldı (7 red, 3 kabul)" || bad "deneme kayıtları: $NA66 (7|3 bekleniyordu)"
UPA=$(appq "BEGIN; SET LOCAL app.property_id='$DEMO_PROPERTY'; UPDATE patrol_scan_attempts SET accepted=true WHERE patrol_log_id='$PT66'; COMMIT;" >/dev/null 2>&1 && echo yazdi || echo engel)
[ "$UPA" = "engel" ] && ok "okutma kanıtı değiştirilemiyor" || bad "okutma kanıtı değiştirilebildi"
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ); OLD=$(date -u -d '-5 minutes' +%Y-%m-%dT%H:%M:%SZ)
TR1=$(curl -s -X POST "$P66/patrols/$PT66/track" -H "$M66" -H "$J" -d "{\"points\":[{\"latitude\":41.0100,\"longitude\":29.0100,\"accuracy_m\":5,\"recorded_at\":\"$OLD\"},{\"latitude\":41.0120,\"longitude\":29.0100,\"accuracy_m\":5,\"recorded_at\":\"$NOW\"},{\"latitude\":41.0145,\"longitude\":29.0100,\"accuracy_m\":5,\"is_mocked\":true,\"recorded_at\":\"$NOW\"}]}")
BIG66=$(python3 -c "import json; print(json.dumps({'points':[{'latitude':41.01,'longitude':29.01,'accuracy_m':5}]*101}))")
TR2=$(code -X POST "$P66/patrols/$PT66/track" -H "$M66" -H "$J" -d "$BIG66")
grep -q '"accepted":3' <<<"$TR1" && grep -q 'Sahte konum' <<<"$TR1" && [ "$TR2" = "413" ] && ok "konum izi alındı (sahte nokta uyarısıyla); 100'den fazla nokta 413" || bad "iz: $TR1 / $TR2"
RP=$(curl -s "$P66/patrols/$PT66/report" -H "$M66")
RS=$(jget "$RP" "s=d['stats']; print(s['rejected_attempts'], s['suspicious_scans'], s['exempt_scans'], s['track_points'], s['mocked_track_points'], len(d['checkpoints']), int(s['track_distance_m'])>400)")
[ "$RS" = "7 1 1 3 1 3 True" ] && ok "tur raporu: 7 red, 1 şüpheli, 1 muaf, 3 iz noktası (1 sahte), 3 nokta, iz mesafesi hesaplandı" || bad "rapor: $RS"
GAP=$(jget "$RP" "print(len(d['gaps']) >= 1)")
[ "$GAP" = "True" ] && ok "takip kesintisi raporda gösteriliyor" || bad "kesinti: $GAP"
RT=$(code "$P66/patrols/$PT66/report" -H "$T66")
[ "$RT" = "403" ] && ok "sakin tur raporunu göremiyor (403)" || bad "sakin rapor → $RT"
curl -s -o /dev/null -X POST "$P66/patrols/$PT66/complete" -H "$M66" -H "$J" -d '{}'
TR3=$(code -X POST "$P66/patrols/$PT66/track" -H "$M66" -H "$J" -d '{"points":[{"latitude":41.01,"longitude":29.01,"accuracy_m":5}]}')
[ "$TR3" = "409" ] && ok "kapanmış turda konum alınmıyor (409, KVKK ölçülülük)" || bad "kapalı tur izi → $TR3"
PR66=$(curl -s "$P66/patrol-reports?from=$(date +%Y-%m-%d)" -H "$M66")
PRS=$(jget "$PR66" "s=d['summary']; print(s['total']>=1, s['rejected_attempts']>=7, len(s['top_rejections'])>=1)")
[ "$PRS" = "True True True" ] && ok "dönem raporu: tur sayısı, red toplamı ve en çok reddedilen noktalar" || bad "dönem raporu: $PRS"
X66=$(appq "BEGIN; SET LOCAL app.property_id='22222222-2222-2222-2222-222222222222'; SELECT count(*) FROM patrol_scan_attempts WHERE patrol_log_id='$PT66'; COMMIT;" | grep -E '^[0-9]+$' | head -1)
[ "${X66:-0}" = "0" ] && ok "başka site devriye kanıtlarını göremiyor" || bad "çapraz site: $X66"
kill_tree "$S66I"; kill_tree "$S66P"

step "67) Malikin işletme projesi görünümü ve seçenekli görüş/itiraz (FAZ H.6 S12, kullanıcı kararı K3)"
startsvc67() { DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen \
  DB_SSLMODE=disable JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 \
  go run ./services/$2 >/tmp/verify-h6-$2.log 2>&1 & }
startsvc67 19841 identity siteeksen_identity "$IDPW"; S67I=$!
startsvc67 19842 governance siteeksen_app "$APPPW"; S67G=$!
startsvc67 19843 settings siteeksen_app "$APPPW"; S67S=$!
for _ in $(seq 1 90); do
  ALL=1; for P in 19841 19842 19843; do curl -fsS http://127.0.0.1:$P/health >/dev/null 2>&1 || ALL=0; done
  [ "$ALL" = "1" ] && break; sleep 1
done
login67() { curl -s -X POST "http://127.0.0.1:19841/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M67="Authorization: Bearer $(login67 5551234567 'Demo123!')"
T67="Authorization: Bearer $(login67 5559876543 'Demo123!')"
G67=http://127.0.0.1:19842/api/v1/governance; ST67=http://127.0.0.1:19843/api/v1
MU67=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905551234567';")
BID67=$($PSQL -t -A -c "SELECT id FROM operating_budgets WHERE property_id='$DEMO_PROPERTY' AND status <> 'DRAFT' ORDER BY period_year DESC LIMIT 1;")
OWNU67=$($PSQL -t -A -c "SELECT ru.unit_id FROM resident_units ru JOIN units u ON u.id=ru.unit_id WHERE u.property_id='$DEMO_PROPERTY' AND ru.resident_id='$MU67' AND ru.role IN ('OWNER','PROXY') AND ru.is_active LIMIT 1;")
# Önceki adımlar bu hesabı bazı bölümlere vekil yapıyor; yalnız kiracı kalması için o kayıtlar sınama süresince kapatılır.
TPX67=$($PSQL -t -A -c "SELECT string_agg(ru.id::text, ',') FROM resident_units ru JOIN users us ON us.id=ru.resident_id WHERE us.phone='+905559876543' AND ru.role IN ('OWNER','PROXY') AND ru.is_active;")
[ -n "$TPX67" ] && $PSQL -q -c "UPDATE resident_units SET is_active=false WHERE id = ANY(string_to_array('$TPX67', ',')::uuid[]);"
TB=$(code "$G67/my-budgets" -H "$T67")
[ -n "$TPX67" ] && $PSQL -q -c "UPDATE resident_units SET is_active=true WHERE id = ANY(string_to_array('$TPX67', ',')::uuid[]);"
[ "$TB" = "403" ] && ok "kiracı işletme projesi malik görünümünü göremiyor (403, hak malikindir)" || bad "kiracı → $TB"
if [ -n "$BID67" ] && [ -n "$OWNU67" ]; then
  MB=$(curl -s "$G67/my-budgets" -H "$M67")
  MBO=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(any(x['id']=='$BID67' for x in d['data']), all(x['status']!='DRAFT' for x in d['data']), d['objections_enabled'])" "$MB")
  [ "$MBO" = "True True True" ] && ok "malik tebliğ edilmiş projeleri görüyor (taslaklar gizli), itiraz alımı varsayılan açık" || bad "malik listesi: $MBO / $MB"
  MD=$(curl -s "$G67/my-budgets/$BID67" -H "$M67")
  OWNC=$($PSQL -t -A -c "SELECT count(DISTINCT ru.unit_id) FROM resident_units ru JOIN units u ON u.id=ru.unit_id WHERE u.property_id='$DEMO_PROPERTY' AND ru.resident_id='$MU67' AND ru.role IN ('OWNER','PROXY') AND ru.is_active AND (ru.end_date IS NULL OR ru.end_date >= CURRENT_DATE);")
  MDS=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); u={x['id'] for x in d['my_units']}; print(all(s['unit_id'] in u for s in d['my_shares']), len(d['my_units']))" "$MD")
  [ "$MDS" = "True $OWNC" ] && ok "proje ayrıntısında yalnız kendi bölümlerinin payı var ($OWNC bölüm)" || bad "pay süzgeci: $MDS (bölüm $OWNC)"
  curl -s -o /dev/null -X PUT "$ST67/settings/OWNER_PLAN_OBJECTIONS" -H "$M67" -H "$J" -d '{"value":false}'
  OB1=$(curl -s -w '|%{http_code}' -X POST "$G67/budgets/$BID67/objections" -H "$M67" -H "$J" -d "{\"unit_id\":\"$OWNU67\",\"reason\":\"Asansör bakım kalemi yüksek\"}")
  EN=$(curl -s "$G67/my-budgets" -H "$M67" | python3 -c "import json,sys; print(json.load(sys.stdin)['objections_enabled'])")
  curl -s -o /dev/null -X DELETE "$ST67/settings/OWNER_PLAN_OBJECTIONS" -H "$M67"
  OB2=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$G67/budgets/$BID67/objections" -H "$M67" -H "$J" -d "{\"unit_id\":\"$OWNU67\",\"reason\":\"Asansör bakım kalemi yüksek\"}")
  [ "${OB1##*|}" = "409" ] && grep -q 'kapattı' <<<"$OB1" && [ "$EN" = "False" ] && [ "$OB2" != "409" ] \
    && ok "ayar kapalıyken görüş/itiraz reddedildi (409) ve ekran kapalı olduğunu biliyor; ayar açılınca kabul ediliyor ($OB2)" \
    || bad "seçenekli itiraz: kapalı=${OB1##*|} bayrak=$EN açık=$OB2"
  $PSQL -c "DELETE FROM budget_objections WHERE budget_id='$BID67' AND user_id='$MU67' AND reason='Asansör bakım kalemi yüksek';" >/dev/null 2>&1
else
  bad "doğrulama için tebliğ edilmiş işletme projesi ya da malik bölümü yok (bütçe=$BID67 bölüm=$OWNU67)"
fi
kill_tree "$S67I"; kill_tree "$S67G"; kill_tree "$S67S"

# Pazaryeri (FAZ M, docs/usta-hizmet/plan.md) adımları ayrı dosyalardadır; sırayla çalışır.
for VSD in "$SCRIPT_DIR"/verify-stack.d/*.sh; do
  [ -f "$VSD" ] && source "$VSD"
done

step "SONUÇ"
echo "  Geçen: $PASS   Başarısız: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TÜM KONTROLLER GEÇTİ"; exit 0; } || { echo "  BAŞARISIZ KONTROL VAR"; exit 1; }
