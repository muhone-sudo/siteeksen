#!/usr/bin/env bash
#
# test-ortami.sh — Tarayıcıdan uçtan uca test için bütün sistemi ayağa kaldırır.
#
#   bash backend/scripts/test-ortami.sh              # başlat (ön planda; Ctrl+C durdurur)
#   bash backend/scripts/test-ortami.sh --stop       # her şeyi durdur
#   YENIDEN_DERLE=1 bash backend/scripts/test-ortami.sh   # Flutter web derlemelerini yenile
#
# dev-up.sh'ın üstüne şunları ekler (yalnız yerel geliştirme; hiçbir şey dışarı gitmez):
#   - SMS  → sahte Netgsm (test araçları sunucusu, /sms)
#   - E-posta → Mailpit (http://localhost:18025)
#   - Kart ödemesi → sahte iyzico, tarayıcıda ödeme sayfası (/iyzico/pay/…)
#   - Veritabanı → Adminer (http://localhost:18080), SALT OKUNUR rol test_okuyucu (RLS'i aşar, yazamaz)
#   - Sakin, yönetici ve tedarikçi uygulamalarının web derlemesi (http://localhost:3102, :3103, :3104)
#   - Panel (http://localhost:3101), API gateway http://localhost:28888 (servisler 28081–28112)
#   Portlar geliştirme ortamından (3001, 8888, 8081–8112) ve docker compose yığınından ayrıdır; compose yığını açıkken de çalışır.
#   - Test hesapları (test-hesaplari.sh): her rol için bir kişi, ikinci site
#   - Zamanlayıcı 1 dakikada bir çalışır
#   - Test sonuçları http://localhost:18000/sonuc sayfasına kaydedilir ($HOME/.siteeksen-test/sonuclar.jsonl;
#     ortam yeniden başlatılsa da kalır)
# Test planı: docs/test-plani/README.md
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLS_PORT=18000
# Test portları: geliştirme portlarına 20000 eklenir (gateway 28888); panel ve uygulamalar 3101–3104.
export DEV_PORT_OFFSET=20000
GW=28888 PANEL=3101 SAKIN=3102 YONETICI=3103 TEDARIKCI=3104
DATA=/tmp/siteeksen-test
DB=siteeksen-dev-db
export PATH=$HOME/flutter/bin:$PATH:/usr/local/go/bin  # snap'teki eski Flutter değil ~/flutter (docs/claude/ortam-ve-komutlar.md)

stop_all() {
  echo ""
  echo "Test ortamı durduruluyor..."
  pkill -f "^python3 -I \S*test-araclari/sunucu\.py" 2>/dev/null
  fuser -k $PANEL/tcp $SAKIN/tcp $YONETICI/tcp $TEDARIKCI/tcp >/dev/null 2>&1
  docker rm -fv siteeksen-test-adminer siteeksen-test-mailpit >/dev/null 2>&1
  bash "$SCRIPT_DIR/dev-up.sh" --stop >/dev/null 2>&1
  pkill -f "^bash \S*scripts/dev-up\.sh$" 2>/dev/null
  echo "Durduruldu."
}

if [ "${1:-}" = "--stop" ]; then
  stop_all
  exit 0
fi

docker info >/dev/null 2>&1 || { echo "Docker çalışmıyor: systemctl --user start docker-desktop"; exit 1; }
for p in $PANEL $SAKIN $YONETICI $TEDARIKCI $GW $TOOLS_PORT 18025 18080 11025 55432; do
  if (exec 3<>/dev/tcp/127.0.0.1/$p) 2>/dev/null; then
    echo "Port $p kullanımda. Önce: bash backend/scripts/test-ortami.sh --stop"; exit 1
  fi
done
trap stop_all EXIT INT TERM
rm -rf "$DATA" && mkdir -p "$DATA"

echo "=== Test araçları (http://localhost:$TOOLS_PORT) ==="
RESULTS=${TEST_SONUC_DOSYASI:-$HOME/.siteeksen-test/sonuclar.jsonl}
python3 -I "$SCRIPT_DIR/test-araclari/sunucu.py" $TOOLS_PORT http://localhost:$GW "$DATA" "$RESULTS" >"$DATA/araclar.log" 2>&1 &
docker run -d --rm --name siteeksen-test-mailpit --label com.docker.compose.project=sitesen --label com.docker.compose.service=test-mailpit -p 127.0.0.1:18025:8025 -p 127.0.0.1:11025:1025 axllent/mailpit:v1.21.8 >/dev/null \
  || { echo "Mailpit açılamadı"; exit 1; }

echo "=== Backend (dev-up.sh) ==="
export NOTIFY_LOG_SENDER=false
export SMTP_HOST=127.0.0.1 SMTP_PORT=11025 SMTP_TLS=none SMTP_FROM="SiteEksen Test <bildirim@siteeksen.test>"
export NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=test-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:$TOOLS_PORT/netgsm
export IYZICO_API_KEY=sandbox-ak IYZICO_SECRET_KEY=sandbox-sk IYZICO_BASE_URL=http://127.0.0.1:$TOOLS_PORT/iyzico
export IYZICO_CALLBACK_URL=http://localhost:$GW/api/v1/public/payments/iyzico/callback
export PAYMENT_RESULT_URL=http://localhost:$PANEL/odeme-sonuc
# Usta & Hizmet (FAZ M5): tedarikçi bakiye yüklemesinin dönüşü ve sonuç sayfası.
export MARKET_IYZICO_CALLBACK_URL=http://localhost:$GW/api/v1/public/market/topups/iyzico/callback
export MARKET_TOPUP_RESULT_URL=http://localhost:$PANEL/tedarikci/bakiye
# Tedarikçi uygulaması (M13.1): uygulama içi ödeme bu adrese gidişi yakalayıp kapanır; web derlemesi aynı adrese döner.
export MARKET_TOPUP_APP_RESULT_URL="http://localhost:$TEDARIKCI/#/bakiye"
export SCHEDULER_INTERVAL=1m
export CORS_ALLOWED_ORIGINS=http://localhost:$PANEL,http://localhost:$SAKIN,http://localhost:$YONETICI,http://localhost:$TEDARIKCI
bash "$SCRIPT_DIR/dev-up.sh" >"$DATA/dev-up.log" 2>&1 &
for _ in $(seq 1 240); do
  curl -fsS http://127.0.0.1:$GW/health >/dev/null 2>&1 && break
  sleep 1
done
curl -fsS http://127.0.0.1:$GW/health >/dev/null 2>&1 || { echo "Gateway açılmadı; $DATA/dev-up.log ve /tmp/dev-*.log"; tail -20 "$DATA/dev-up.log"; exit 1; }
# Bütün servisler: gateway sağlıklı olsa da arkadaki servis geç açılabilir.
for port in 8081 8082 8083 8084 8085 8086 8087 8089 8090 8091 8092 8093 8094 8096 8097 8098 8099 8100 8101 8102 8103 8104 8105 8107 8111 8112; do
  port=$((port + DEV_PORT_OFFSET))
  for _ in $(seq 1 120); do curl -fsS http://127.0.0.1:$port/health >/dev/null 2>&1 && break; sleep 1; done
  curl -fsS http://127.0.0.1:$port/health >/dev/null 2>&1 || echo "  UYARI: :$port sağlıklı değil (günlük: /tmp/dev-*.log)"
done
echo "  servisler hazır"

echo "=== Salt okunur veritabanı rolü ve Adminer ==="
docker exec "$DB" psql -q -U siteeksen -d siteeksen -c "
  DO \$\$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test_okuyucu') THEN
      CREATE ROLE test_okuyucu LOGIN PASSWORD 'test_okuyucu' BYPASSRLS;
    END IF;
  END \$\$;
  GRANT pg_read_all_data TO test_okuyucu;
  ALTER ROLE test_okuyucu SET default_transaction_read_only = on;" >/dev/null || { echo "rol oluşturulamadı"; exit 1; }
docker run -d --rm --name siteeksen-test-adminer --label com.docker.compose.project=sitesen --label com.docker.compose.service=test-adminer --link "$DB:db" -p 127.0.0.1:18080:8080 \
  -e ADMINER_DEFAULT_SERVER=db adminer:4.8.1 >/dev/null || { echo "Adminer açılamadı"; exit 1; }

echo "=== Test hesapları ==="
bash "$SCRIPT_DIR/test-hesaplari.sh" http://127.0.0.1:$GW/api/v1 | tee "$DATA/hesaplar.txt" | sed 's/^/  /'
[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "Test hesapları oluşturulamadı"; exit 1; }
# Platform yöneticisi (FAZ M1): rol yalnız komutla verilir; kişi şifresini etkinleştirme koduyla belirler.
PA_OUT=$(cd "$ROOT/backend" && DATABASE_URL="postgres://siteeksen:${DEV_DB_PASSWORD:-devpw}@127.0.0.1:55432/siteeksen?sslmode=disable" \
  go run ./cmd/platform-admin -phone 5550000030 -create -first Pelin -last Platform 2>&1)
PA_CODE=$(sed -n 's/.*etkinleştirme kodu \([A-Z0-9]*\).*/\1/p' <<<"$PA_OUT")
curl -fsS -o /dev/null -X POST http://127.0.0.1:$GW/api/v1/auth/activate -H 'Content-Type: application/json' \
  -d "{\"phone\":\"5550000030\",\"code\":\"$PA_CODE\",\"new_password\":\"Demo123!\"}" \
  && echo "  PLATFORM   5550000030  Pelin Platform  PLATFORM_ADMIN (Usta & Hizmet platform yönetimi) — /platform" | tee -a "$DATA/hesaplar.txt" \
  || { echo "Platform yöneticisi oluşturulamadı: $PA_OUT"; exit 1; }
python3 -I "$SCRIPT_DIR/test-araclari/pazaryeri.py" http://127.0.0.1:$GW/api/v1 http://127.0.0.1:$TOOLS_PORT | tee -a "$DATA/hesaplar.txt" | sed 's/^/  /'
[ "${PIPESTATUS[0]}" -eq 0 ] || { echo "Usta & Hizmet test verisi oluşturulamadı"; exit 1; }

echo "=== Mobil uygulamaların web derlemesi ==="
for app in mobile admin_app supplier_app; do
  # Derleme API adresini içerir; adres değiştiyse (ör. port) yeniden derlenir.
  if [ "${YENIDEN_DERLE:-0}" = "1" ] || [ ! -f "$ROOT/$app/build/web/index.html" ] \
     || [ "$(cat "$ROOT/$app/build/web/.api-base-url" 2>/dev/null)" != "http://localhost:$GW/api/v1" ]; then
    echo "  $app derleniyor (1-2 dk)..."
    (cd "$ROOT/$app" && flutter build web --dart-define=API_BASE_URL=http://localhost:$GW/api/v1 >"$DATA/web-$app.log" 2>&1) \
      || { echo "  $app web derlemesi başarısız: $DATA/web-$app.log"; exit 1; }
    echo "http://localhost:$GW/api/v1" >"$ROOT/$app/build/web/.api-base-url"
  fi
done
python3 -m http.server $SAKIN --bind 127.0.0.1 --directory "$ROOT/mobile/build/web" >/dev/null 2>&1 &
python3 -m http.server $YONETICI --bind 127.0.0.1 --directory "$ROOT/admin_app/build/web" >/dev/null 2>&1 &
python3 -m http.server $TEDARIKCI --bind 127.0.0.1 --directory "$ROOT/supplier_app/build/web" >/dev/null 2>&1 &

echo "=== Panel ==="
if [ ! -f "$ROOT/admin/.env.local" ]; then
  printf 'NEXT_PUBLIC_API_URL=http://localhost:8888/api/v1\nNEXTAUTH_URL=http://localhost:3001\nNEXTAUTH_SECRET=dev-secret-123\n' >"$ROOT/admin/.env.local"
fi
# Ortam değişkenleri .env.local'daki değerlerin önüne geçer (Next.js); panel test gateway'ine bağlanır.
(cd "$ROOT/admin" && NEXT_PUBLIC_API_URL=http://localhost:$GW/api/v1 NEXTAUTH_URL=http://localhost:$PANEL \
  npx next dev -p $PANEL >"$DATA/panel.log" 2>&1 &)
for _ in $(seq 1 120); do curl -fsS -o /dev/null http://localhost:$PANEL/login 2>/dev/null && break; sleep 1; done

cat <<EOF

======================================================================
  TEST ORTAMI HAZIR — araçlar: http://localhost:$TOOLS_PORT

  Panel               http://localhost:$PANEL
  Sakin uygulaması    http://localhost:$SAKIN   (web derlemesi)
  Yönetici uygulaması http://localhost:$YONETICI   (web derlemesi)
  Tedarikçi uygulaması http://localhost:$TEDARIKCI  (SiteEksen Tedarikçi, web derlemesi)
  API gateway         http://localhost:$GW
  Adminer (DB)        http://localhost:18080  sunucu: db · kullanıcı/şifre: test_okuyucu · veritabanı: siteeksen
  E-posta (Mailpit)   http://localhost:18025
  SMS kutusu          http://localhost:$TOOLS_PORT/sms
  Cihaz simülatörü    http://localhost:$TOOLS_PORT/cihaz
  Günlükler           http://localhost:$TOOLS_PORT/gunluk
  Test sonuçları      http://localhost:$TOOLS_PORT/sonuc   (kayıt: $RESULTS)

  Hesaplar: $DATA/hesaplar.txt  ·  Test planı: docs/test-plani/README.md
======================================================================
Durdurmak için Ctrl+C.
EOF
wait
