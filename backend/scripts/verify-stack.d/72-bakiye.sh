# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Adım 71'in hesaplarını (5550009201 onaylı, 5550009202 taslak, platform 5550009301)
# ve 'Usta Pro' paketini kullanır. Sahte iyzico adım 48'de /tmp/fake-iyzico.py olarak yazılır.
step "72) Bakiye ve paket: kartla yükleme, defter, idempotency, uzlaştırma, paket, aidat, kapanış (FAZ M5)"

M5IZ="IYZICO_API_KEY=sandbox-ak IYZICO_SECRET_KEY=sandbox-sk IYZICO_BASE_URL=http://127.0.0.1:19945 IYZICO_CALLBACK_URL=http://127.0.0.1:8888/api/v1/public/payments/iyzico/callback"
m5env() { echo "DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD=$APPPW DB_NAME=siteeksen DB_SSLMODE=disable STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-m3-files JWT_SECRET=verify-secret-key-at-least-32-chars"; }
# Yarım yapılandırma servisi açmaz; dönüş adresi olmadan da açmaz
IYZICO_API_KEY=x env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen DB_SSLMODE=disable \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19943 timeout 60 go run ./services/marketplace >/tmp/verify-m5-bad1.log 2>&1
env $M5IZ DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=siteeksen_app DB_PASSWORD="$APPPW" DB_NAME=siteeksen DB_SSLMODE=disable \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19943 timeout 60 go run ./services/marketplace >/tmp/verify-m5-bad2.log 2>&1
grep -q 'iyzico yapılandırması hatalı' /tmp/verify-m5-bad1.log && grep -q 'MARKET_IYZICO_CALLBACK_URL' /tmp/verify-m5-bad2.log \
  && ok "yarım iyzico yapılandırmasıyla ve dönüş adresi olmadan pazaryeri servisi açılmıyor" \
  || bad "yapılandırma reddi: $(tail -1 /tmp/verify-m5-bad1.log) / $(tail -1 /tmp/verify-m5-bad2.log)"

rm -f /tmp/fake-iyzico.log /tmp/fake-iyzico-mode /tmp/fake-iyzico-init
python3 /tmp/fake-iyzico.py 19945 >/dev/null 2>&1 &
M5F=$!
m5svc() { env $(m5env) DB_USER=$3 DB_PASSWORD="$4" $5 PORT=$1 go run ./$2 >/tmp/verify-m5-$(basename "$2").log 2>&1 & }
m5svc 19941 services/identity siteeksen_identity "$IDPW" ""; M5I=$!
env $(m5env) DB_PASSWORD="$APPPW" $M5IZ MARKET_IYZICO_CALLBACK_URL=http://127.0.0.1:19940/api/v1/public/market/topups/iyzico/callback \
  MARKET_TOPUP_RESULT_URL=https://panel.ornek.test/tedarikci/bakiye MARKET_TOPUP_APP_RESULT_URL='https://tedarikci.ornek.test/#/bakiye' MARKET_JOBS_INTERVAL=2s MARKET_TOPUP_RECONCILE_AGE=10s \
  PORT=19942 go run ./services/marketplace >/tmp/verify-m5-marketplace.log 2>&1 &
M5M=$!
M5GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M5GWENV="$M5GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M5GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19941 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19942 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19940 go run ./cmd/gateway >/tmp/verify-m5-gateway.log 2>&1 &
M5G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19941/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19942/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19940/health >/dev/null 2>&1 && break; sleep 1
done
M5=http://127.0.0.1:19940/api/v1/market
m5login() { curl -s -X POST "http://127.0.0.1:19940/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"Demo123!\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
PA="Authorization: Bearer $(m5login 5550009301)"; S1="Authorization: Bearer $(m5login 5550009201)"; S2="Authorization: Bearer $(m5login 5550009202)"
m5() { curl -s -w '|%{http_code}' -X "$1" "$M5$2" -H "$3" -H "$J" ${5:+-H "Idempotency-Key: $5"} ${4:+-d "$4"}; }
jget() { python3 -c "import json,sys; d=json.loads(sys.argv[1].rsplit('|',1)[0]); print(eval(sys.argv[2]))" "$1" "$2" 2>/dev/null; }
ACC1=$($PSQL -t -A -c "SELECT a.id FROM mp_supplier_accounts a JOIN users u ON u.id=a.user_id WHERE u.phone='+905550009201';")
ACC2=$($PSQL -t -A -c "SELECT a.id FROM mp_supplier_accounts a JOIN users u ON u.id=a.user_id WHERE u.phone='+905550009202';")
bal() { $PSQL -t -A -c "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$1';"; }
lsum() { $PSQL -t -A -c "SELECT COALESCE(sum(amount_kurus),0) FROM mp_wallet_ledger WHERE account_id='$1';"; }
cb() { curl -s -X POST "http://127.0.0.1:19940/api/v1/public/market/topups/iyzico/callback" -H 'Accept: application/json' -d "token=$1"; }
tok() { $PSQL -t -A -c "SELECT gateway_token FROM mp_topups WHERE id='$1';"; }

# Bakiye koşulları (M13.3, TBK m.21): kabul edilmeden yükleme 409; eski sürüm kabul edilmez; kabul sürüm + metin özetiyle kaydolur
TT=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":50000}' k-0)
TG=$(m5 GET /terms/balance "$S1"); TVER=$(jget "$TG" "d['version']"); TSHA=$(jget "$TG" "d['sha256']")
TX=$(m5 POST /supplier/terms/balance/accept "$S1" '{"version":"2000-01-01"}')
TA=$(m5 POST /supplier/terms/balance/accept "$S1" "{\"version\":\"$TVER\"}")
TA2=$(m5 POST /supplier/terms/balance/accept "$S1" "{\"version\":\"$TVER\"}")
TROW=$($PSQL -t -A -c "SELECT count(*)||'|'||max(text_sha256)||'|'||max(version) FROM mp_terms_acceptances WHERE account_id='$ACC1';")
TSUM=$(jget "$TG" "__import__('hashlib').sha256(d['text'].encode()).hexdigest()")
[ "${TT##*|}" = "409" ] && grep -q TERMS_REQUIRED <<<"$TT" && grep -q '365 gün' <<<"$TG" && [ "${TX##*|}" = "409" ] && [ "${TA##*|}" = "200" ] \
  && [ "${TA2##*|}" = "200" ] && [ "$TROW" = "1|$TSHA|$TVER" ] && [ "$TSUM" = "$TSHA" ] \
  && ok "bakiye koşulları: kabulsüz yükleme 409 TERMS_REQUIRED; eski sürüm 409; kabul tek satır (sürüm $TVER + metnin SHA-256'sı)" \
  || bad "koşul kabulü: kabulsüz=${TT: -80} eski=${TX##*|} kabul=${TA: -80} tekrar=${TA2##*|} satır=$TROW özet=$TSUM/$TSHA"

TDOC=$(python3 -c "
import json,sys
doc=open(sys.argv[1],encoding='utf-8').read(); txt=doc.split('## Metin\n\n',1)[1].split('\n\n## ',1)[0].strip()
api=json.loads(sys.argv[2].rsplit('|',1)[0])
print(txt==api['text'].strip(), ('Sürüm:** '+api['version']) in doc)" "$SCRIPT_DIR/../../docs/hukuk/tedarikci-bakiye-kosullari.md" "$TG")
[ "$TDOC" = "True True" ] && ok "bakiye koşulları: hukuk taslağındaki metin ve sürüm (docs/hukuk/tedarikci-bakiye-kosullari.md) uygulamadaki metinle birebir aynı" \
  || bad "hukuk taslağı ile uygulama metni farklı: $TDOC"

# Yükleme: anahtarsız 400; başlat; aynı anahtar aynı kaydı döner; farklı tutar 409
B0=$(bal "$ACC1")
T0=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":50000}')
T1=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":50000}' k-1); TID=$(jget "$T1" "d['topup']['id']")
T2=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":50000}' k-1); T3=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":70000}' k-1)
[ "${T0##*|}" = "400" ] && [ "${T1##*|}" = "201" ] && grep -q 'checkout_url' <<<"$T1" && [ "$(jget "$T2" "d['topup']['id']")" = "$TID" ] && [ "${T3##*|}" = "409" ] \
  && ok "yükleme: Idempotency-Key yoksa 400; ödeme sayfası açıldı; aynı anahtar aynı yüklemeyi döndü; farklı tutarla 409" \
  || bad "yükleme başlatma: anahtarsız=${T0##*|} başlat=${T1: -100} tekrar=${T2: -60} farklı=${T3##*|}"
SIG=$(grep -c '"sig_ok": true' /tmp/fake-iyzico.log 2>/dev/null)
C1=$(cb "$(tok "$TID")"); C2=$(cb "$(tok "$TID")")
B1=$(bal "$ACC1"); NL=$($PSQL -t -A -c "SELECT count(*) FROM mp_wallet_ledger WHERE topup_id='$TID';")
[ "$SIG" -ge 1 ] && grep -q '"SUCCEEDED"' <<<"$C1" && grep -q '"SUCCEEDED"' <<<"$C2" && [ "$B1" = "$((B0+50000))" ] && [ "$NL" = "1" ] \
  && ok "ödeme dönüşü: sonuç sağlayıcıdan (imzalı) sorgulandı, bakiye 500 TL arttı; aynı dönüş ikinci kez gelince tek defter satırı" \
  || bad "dönüş: imza=$SIG ilk=$C1 ikinci=$C2 bakiye $B0→$B1 defter=$NL"
R302=$(curl -s -o /dev/null -w '%{http_code}|%{redirect_url}' -X POST "http://127.0.0.1:19940/api/v1/public/market/topups/iyzico/callback" -d "token=$(tok "$TID")")
grep -q '^303|https://panel.ornek.test/tedarikci/bakiye?' <<<"$R302" && ok "tarayıcı dönüşü panelin bakiye sayfasına sonuçla yönlendiriliyor (303)" || bad "yönlendirme: $R302"
# Uygulama içi ödeme (M13.1): uygulama dönüş hedefini "APP" ister; sonuç adresi sunucu ayarından gelir, istemci adres veremez
TA1=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":10000,"return_to":"APP","result_url":"https://kotu.ornek.test/"}' k-app)
TAID=$(jget "$TA1" "d['topup']['id']")
RAPP=$(curl -s -o /dev/null -w '%{http_code}|%{redirect_url}' -X POST "http://127.0.0.1:19940/api/v1/public/market/topups/iyzico/callback" -d "token=$(tok "$TAID")")
[ "$(jget "$TA1" "d['result_url']")" = "https://tedarikci.ornek.test/#/bakiye" ] && [ "$(jget "$T1" "d['result_url']")" = "https://panel.ornek.test/tedarikci/bakiye" ] \
  && [ "${RAPP%%\?*}" = "303|https://tedarikci.ornek.test/#/bakiye" ] && grep -q "[?&]topup_id=$TAID\(&\|$\)" <<<"$RAPP" && grep -q "status=SUCCEEDED" <<<"$RAPP" && [ "$($PSQL -t -A -c "SELECT return_target FROM mp_topups WHERE id='$TAID';")" = "APP" ] \
  && ok "uygulama içi ödeme: yükleme uygulamaya dönüş istedi, yanıtta sonuç adresi (sunucu ayarı) var; iyzico dönüşü uygulamanın bakiye sayfasına 303; istemcinin verdiği adres yok sayıldı" \
  || bad "uygulama dönüşü: başlat=${TA1: -160} yönlendirme=$RAPP"
B1=$(bal "$ACC1")
echo 'FAILURE:10051:Kart limiti yetersiz' > /tmp/fake-iyzico-mode
TF=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":20000}' k-2); CF=$(cb "$(tok "$(jget "$TF" "d['topup']['id']")")")
echo WRONG_PRICE > /tmp/fake-iyzico-mode
TW=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":30000}' k-3); CW=$(cb "$(tok "$(jget "$TW" "d['topup']['id']")")")
B2=$(bal "$ACC1")
grep -q '"FAILED"' <<<"$CF" && grep -q '"FAILED"' <<<"$CW" && grep -q 'uyuşmadı' <<<"$CW" && [ "$B2" = "$B1" ] \
  && ok "başarısız ödeme ve tutarı uyuşmayan ödeme bakiyeye işlenmedi (FAILED; tutar uyuşmazlığı ayrıca söylendi)" \
  || bad "başarısız/uyuşmaz: $CF / $CW / bakiye $B1→$B2"
# Uzlaştırma: dönüşü hiç gelmeyen başarılı ödeme
echo SUCCESS > /tmp/fake-iyzico-mode
TR=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":50000}' k-4); TRID=$(jget "$TR" "d['topup']['id']")
$PSQL -q -c "UPDATE mp_topups SET created_at = now() - interval '1 minute' WHERE id='$TRID';"
for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT status FROM mp_topups WHERE id='$TRID';")" = "SUCCEEDED" ] && break; sleep 1; done
sleep 3
B3=$(bal "$ACC1"); NR=$($PSQL -t -A -c "SELECT count(*) FROM mp_wallet_ledger WHERE topup_id='$TRID';")
[ "$B3" = "$((B2+50000))" ] && [ "$NR" = "1" ] && ok "uzlaştırma: dönüşü gelmeyen başarılı ödeme sonradan bakiyeye yansıdı, tek kez" || bad "uzlaştırma: bakiye $B2→$B3 defter=$NR"
W=$(m5 GET /supplier/wallet "$S1")
[ "$(jget "$W" "d['balance_kurus']")" = "$(lsum "$ACC1")" ] && [ "$(jget "$W" "d['total']")" -ge 2 ] \
  && ok "bakiye ekranı: gösterilen bakiye = defter toplamı ($(lsum "$ACC1") kuruş)" || bad "bakiye ekranı: ${W:0:160} defter=$(lsum "$ACC1")"

# Paket
PRO=$($PSQL -t -A -c "SELECT id FROM mp_packages WHERE name='Usta Pro';"); FREE=7a000000-0000-4000-8000-000000000001
P1=$(m5 POST /supplier/package "$S1" "{\"package_id\":\"$PRO\"}")
P2=$(m5 POST /supplier/package "$S2" "{\"package_id\":\"$PRO\"}")
ST1=$($PSQL -t -A -c "SELECT p.name||'|'||a.period_included_left||'|'||a.period_sms_left||'|'||(a.package_renews_at BETWEEN now() + interval '27 days' AND now() + interval '32 days') FROM mp_supplier_accounts a JOIN mp_packages p ON p.id=a.package_id WHERE a.id='$ACC1';")
B4=$(bal "$ACC1")
[ "$(jget "$P1" "d['account']['package']['name']")" = "Usta Pro" ] && [ "$ST1" = "Usta Pro|5|50|true" ] && [ "$B4" = "$((B3-29900))" ] \
  && [ "${P2##*|}" = "409" ] && grep -q 'bakiye yetersiz' <<<"$P2" \
  && ok "paket yükseltme: aidat bakiyeden düştü (299 TL), 5 dahil talep ve 50 SMS hakkı, yenileme ~1 ay sonra; bakiyesi yetmeyen 409" \
  || bad "paket: yükselt=${P1: -80} durum=$ST1 bakiye $B3→$B4 yetersiz=${P2: -80}"
PD=$(m5 POST /supplier/package "$S1" "{\"package_id\":\"$FREE\"}")
ND=$($PSQL -t -A -c "SELECT (next_package_id='$FREE')||'|'||(package_id='$PRO') FROM mp_supplier_accounts WHERE id='$ACC1';")
PC=$(m5 POST /supplier/package "$S1" "{\"package_id\":\"$PRO\"}")
NC=$($PSQL -t -A -c "SELECT next_package_id IS NULL FROM mp_supplier_accounts WHERE id='$ACC1';")
[ "$ND" = "true|true" ] && [ "$NC" = "t" ] && [ "$(bal "$ACC1")" = "$B4" ] \
  && ok "paket düşürme dönem sonuna planlandı (paket hemen değişmedi); mevcut paketi seçmek bekleyen değişikliği iptal etti, ücret alınmadı" \
  || bad "düşürme: $ND iptal=$NC bakiye=$(bal "$ACC1")"

# Aidat yenileme: fiyat değişikliği bir sonraki yenilemede, ikinci tur çift aidat yok, yetmezse ücretsize iniş
renew_now() { $PSQL -q -c "UPDATE mp_supplier_accounts SET package_renews_at = now() - interval '1 minute' WHERE id='$ACC1';"
  for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT package_renews_at IS NULL OR package_renews_at > now() FROM mp_supplier_accounts WHERE id='$ACC1';")" = "t" ] && break; sleep 1; done; sleep 3; }
m5 PUT "/platform/packages/$PRO" "$PA" '{"name":"Usta Pro","monthly_fee_kurus":35000,"fee_discount_pct":25,"included_requests":5,"monthly_sms":50,"priority_access":true,"phone_in_showcase":true,"rank_weight":10,"is_active":true}' >/dev/null
$PSQL -q -c "UPDATE mp_supplier_accounts SET period_included_left = 0 WHERE id='$ACC1';"
B5=$(bal "$ACC1"); renew_now; B6=$(bal "$ACC1")
NFEE=$($PSQL -t -A -c "SELECT count(*) FROM mp_wallet_ledger WHERE account_id='$ACC1' AND kind='PACKAGE_FEE';")
HAK=$($PSQL -t -A -c "SELECT period_included_left FROM mp_supplier_accounts WHERE id='$ACC1';")
[ "$B6" = "$((B5-35000))" ] && [ "$NFEE" = "2" ] && [ "$HAK" = "5" ] \
  && ok "aidat yenilendi: yeni fiyat (350 TL) bu yenilemede uygulandı, haklar yenilendi; tur tekrarlarında ikinci aidat yok (toplam 2 aidat satırı)" \
  || bad "yenileme: bakiye $B5→$B6 aidat satırı=$NFEE hak=$HAK"
m5 PUT /platform/settings/low_balance_threshold_kurus "$PA" '{"value":100000}' >/dev/null
while [ "$(bal "$ACC1")" -ge 35000 ]; do renew_now; done
LOWN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE supplier_account_id='$ACC1' AND topic='market.wallet.low';")
renew_now
DG=$($PSQL -t -A -c "SELECT p.is_default||'|'||(a.package_renews_at IS NULL) FROM mp_supplier_accounts a JOIN mp_packages p ON p.id=a.package_id WHERE a.id='$ACC1';")
DGN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE supplier_account_id='$ACC1' AND topic='market.package.downgraded';")
m5 PUT /platform/settings/low_balance_threshold_kurus "$PA" '{"value":5000}' >/dev/null
[ "$DG" = "true|true" ] && [ "$DGN" -ge 1 ] && [ "$LOWN" -ge 1 ] && [ "$(bal "$ACC1")" -ge 0 ] \
  && ok "bakiye aidata yetmeyince ücretsiz pakete inildi ve tedarikçiye bildirildi; eşik altına düşen bakiye için uyarı gitti (borç oluşmadı)" \
  || bad "iniş: paket=$DG iniş bildirimi=$DGN düşük bakiye bildirimi=$LOWN bakiye=$(bal "$ACC1")"

# Kapanış (M13.3): kalan bakiye son 365 gündeki yüklemelerden en yeniden eskiye karşılanan kısmıyla karta iade edilir,
# kalanı EXPIRED_BALANCE; kapanış sonrası sonuçlanan yükleme bakiyeye yazılmaz, karta iade edilir; başarısız iade platform kuyruğunda.
paytopup() { local r; r=$(m5 POST /supplier/topups "${3:-$S1}" "{\"amount_kurus\":$1}" "$2"); local id; id=$(jget "$r" "d['topup']['id']"); cb "$(tok "$id")" >/dev/null; echo "$id"; }
X0=$(paytopup 10000 k-x0); X1=$(paytopup 20000 k-x1); X2=$(paytopup 30000 k-x2)
$PSQL -q -c "UPDATE mp_topups SET completed_at = now() - interval '400 days' WHERE account_id='$ACC1' AND id NOT IN ('$X1','$X2');
  UPDATE mp_topups SET completed_at = now() - interval '200 days' WHERE id='$X1'; UPDATE mp_topups SET completed_at = now() - interval '10 days' WHERE id='$X2';"
BC=$(bal "$ACC1")
L1=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":15000}' k-l1); L1ID=$(jget "$L1" "d['topup']['id']")
L2=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":25000}' k-l2); L2ID=$(jget "$L2" "d['topup']['id']")
# Uzlaştırma işi bu iki yüklemeyi kendisi sonuçlandırmasın (dönüşleri aşağıda elle, istenen iade kipinde gelir)
$PSQL -q -c "UPDATE mp_topups SET created_at = now() + interval '1 hour' WHERE id IN ('$L1ID','$L2ID');"
K0=$(m5 POST "/platform/accounts/$ACC1/close" "$PA" '{"reason":"x"}')
K1=$(m5 POST "/platform/accounts/$ACC1/close" "$PA" '{"reason":"Tedarikçi talebiyle"}')
KB=$($PSQL -t -A -c "SELECT a.status||'|'||a.balance_kurus||'|'||(SELECT count(*) FROM mp_businesses b WHERE b.account_id=a.id AND b.status<>'CLOSED') FROM mp_supplier_accounts a WHERE a.id='$ACC1';")
KR=$($PSQL -t -A -c "SELECT string_agg(topup_id||':'||amount_kurus||':'||reason, ',' ORDER BY amount_kurus DESC) FROM mp_card_refunds WHERE account_id='$ACC1';")
KL=$($PSQL -t -A -c "SELECT COALESCE(sum(amount_kurus) FILTER (WHERE kind='CARD_REFUND'),0)||'|'||COALESCE(sum(amount_kurus) FILTER (WHERE kind='EXPIRED_BALANCE'),0) FROM mp_wallet_ledger WHERE account_id='$ACC1';")
KT=$(m5 POST /supplier/topups "$S1" '{"amount_kurus":1000}' k-9)
[ "${K0##*|}" = "422" ] && [ "${K1##*|}" = "200" ] && [ "$KB" = "CLOSED|0|0" ] && [ "$KR" = "$X2:30000:CLOSURE,$X1:20000:CLOSURE" ] \
  && [ "$KL" = "-50000|-$((BC-50000))" ] && [ "$(jget "$K1" "d['refund']['expired_kurus']")" = "$((BC-50000))" ] \
  && [ "${KT##*|}" = "409" ] \
  && ok "kapanış: bakiye ($BC kuruş) son 365 gündeki yüklemelerle eşleşti (10 gün: 300 TL, 200 gün: 200 TL karta), 400 günlükten kalan $((BC-50000)) kuruş iade edilmedi; bakiye 0, işletmeler kapandı; kapalı hesaba yükleme 409" \
  || bad "kapanış: gerekçesiz=${K0##*|} kapanış=${K1: -160} durum=$KB iadeler=$KR (beklenen $X2:30000,$X1:20000) defter=$KL bakiye=$BC yükleme=${KT##*|}"
for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT count(*) FROM mp_card_refunds WHERE account_id='$ACC1' AND status='SUCCEEDED';")" = "2" ] && break; sleep 1; done
RFLOG=$(python3 -c "
import json
rows=[json.loads(l) for l in open('/tmp/fake-iyzico.log') if '/v2/payment/refund' in l]
print(','.join(sorted('%s:%s:%s' % (r['body']['paymentId'], r['body']['price'], r['sig_ok']) for r in rows)))")
PIDS=$($PSQL -t -A -c "SELECT string_agg(gateway_payment_id||':'||CASE WHEN id='$X2' THEN '300.0' ELSE '200.0' END||':True', ',' ORDER BY gateway_payment_id) FROM mp_topups WHERE id IN ('$X1','$X2');")
RN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE supplier_account_id='$ACC1' AND topic='market.refund.completed';")
SR=$(m5 GET /supplier/card-refunds "$S1")
[ "$RFLOG" = "$PIDS" ] && [ "$RN" -ge 2 ] && [ "$(jget "$SR" "len([x for x in d['data'] if x['status']=='SUCCEEDED' and x['gateway_reference']])")" = "2" ] \
  && ok "karta iade: iyzico'ya iki imzalı kısmi iade (ödeme kimliği + tutar) gitti, ikisi SUCCEEDED; tedarikçi iadeleri ve bildirimi görüyor" \
  || bad "iyzico iadesi: çağrılar=$RFLOG beklenen=$PIDS bildirim=$RN tedarikçi=${SR:0:200}"
# Kapanıştan sonra sonuçlanan yükleme: bakiyeye yazılmaz; iyzico reddederse (deneme hakkı 1) FAILED → yeniden dene → SUCCEEDED;
# sonucu bilinmeyen iade (HTTP 500) yeniden denenmez, platform havaleyle elle kapatır.
m5 PUT /platform/settings/card_refund_max_attempts "$PA" '{"value":1}' >/dev/null
echo FAIL > /tmp/fake-iyzico-refund
CL1=$(cb "$(tok "$L1ID")")
for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT status FROM mp_card_refunds WHERE topup_id='$L1ID';")" = "FAILED" ] && break; sleep 1; done
LS=$($PSQL -t -A -c "SELECT (SELECT status FROM mp_topups WHERE id='$L1ID')||'|'||(SELECT count(*) FROM mp_wallet_ledger WHERE topup_id='$L1ID')||'|'||r.reason||'|'||r.status||'|'||r.amount_kurus FROM mp_card_refunds r WHERE r.topup_id='$L1ID';")
DN=$($PSQL -t -A -c "SELECT count(*) FROM notifications WHERE supplier_account_id='$ACC1' AND topic='market.refund.delayed';")
echo OK > /tmp/fake-iyzico-refund
RID1=$($PSQL -t -A -c "SELECT id FROM mp_card_refunds WHERE topup_id='$L1ID';")
RT=$(m5 POST "/platform/card-refunds/$RID1/retry" "$PA")
for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT status FROM mp_card_refunds WHERE id='$RID1';")" = "SUCCEEDED" ] && break; sleep 1; done
RS1=$($PSQL -t -A -c "SELECT status FROM mp_card_refunds WHERE id='$RID1';")
grep -q 'kartınıza iade edilecek' <<<"$CL1" && [ "$LS" = "SUCCEEDED|0|LATE_TOPUP|FAILED|15000" ] && [ "$DN" -ge 1 ] && [ "${RT##*|}" = "200" ] && [ "$RS1" = "SUCCEEDED" ] && [ "$(bal "$ACC1")" = "0" ] \
  && ok "kapanış sonrası yükleme bakiyeye yazılmadı (defter satırı yok), karta iade sırasına girdi; iyzico reddi FAILED + tedarikçiye gecikme bildirimi; platform yeniden deneyince SUCCEEDED" \
  || bad "geç yükleme: dönüş=$CL1 durum=$LS gecikme=$DN yeniden=${RT: -80} son=$RS1 bakiye=$(bal "$ACC1")"
echo HTTP500 > /tmp/fake-iyzico-refund
cb "$(tok "$L2ID")" >/dev/null
for _ in $(seq 1 20); do [ "$($PSQL -t -A -c "SELECT status FROM mp_card_refunds WHERE topup_id='$L2ID';")" = "FAILED" ] && break; sleep 1; done
RID2=$($PSQL -t -A -c "SELECT id FROM mp_card_refunds WHERE topup_id='$L2ID';")
L2PAY=$($PSQL -t -A -c "SELECT gateway_payment_id FROM mp_topups WHERE id='$L2ID';")
ncall() { python3 -c "import json,sys; print(sum(1 for l in open('/tmp/fake-iyzico.log') if '/v2/payment/refund' in l and json.loads(l)['body'].get('paymentId')==sys.argv[1]))" "$L2PAY"; }
NCALL=$(ncall); sleep 5; NCALL2=$(ncall)
PL=$(m5 GET "/platform/card-refunds?status=FAILED" "$PA")
M0=$(m5 POST "/platform/card-refunds/$RID2/manual" "$PA" '{"reference":"","date":"2026-11-01"}')
M1=$(m5 POST "/platform/card-refunds/$RID2/manual" "$PA" '{"reference":"DEK-2026-777","date":"2026-11-01"}')
M2=$(m5 POST "/platform/card-refunds/$RID2/retry" "$PA")
echo OK > /tmp/fake-iyzico-refund
m5 PUT /platform/settings/card_refund_max_attempts "$PA" '{"value":5}' >/dev/null
grep -q 'Sonuç bilinmiyor' <<<"$PL" && [ "$NCALL" = "1" ] && [ "$NCALL2" = "1" ] && [ "${M0##*|}" = "422" ] && [ "$(jget "$M1" "d['status']")" = "MANUAL" ] && [ "${M2##*|}" = "409" ] \
  && ok "sonucu bilinmeyen iade (iyzico HTTP 500) yeniden denenmedi (çift iade yok), platform kuyruğunda; dekontsuz elle kapanış 422, dekontla MANUAL; kapanmış iade yeniden denenemez" \
  || bad "belirsiz iade: kuyruk=${PL:0:200} çağrı $NCALL→$NCALL2 dekontsuz=${M0##*|} dekontlu=${M1: -80} yeniden=${M2##*|}"
# Sıra: bakiye son 365 gündeki yüklemelerin toplamından azsa EN YENİ yüklemeden başlanır (bakiye koşulları m.2)
m5 POST /supplier/terms/balance/accept "$S2" "{\"version\":\"$TVER\"}" >/dev/null
Y1=$(paytopup 20000 k-y1 "$S2"); Y2=$(paytopup 30000 k-y2 "$S2")
$PSQL -q -c "UPDATE mp_topups SET completed_at = now() - interval '200 days' WHERE id='$Y1'; UPDATE mp_topups SET completed_at = now() - interval '10 days' WHERE id='$Y2';"
YP=$(m5 POST /supplier/package "$S2" "{\"package_id\":\"$PRO\"}"); BC2=$(bal "$ACC2")
K2=$(m5 POST "/platform/accounts/$ACC2/close" "$PA" '{"reason":"Kullanılmayan hesap"}')
KR2=$($PSQL -t -A -c "SELECT string_agg(topup_id||':'||amount_kurus, ',') FROM mp_card_refunds WHERE account_id='$ACC2';")
[ "${YP##*|}" = "200" ] && [ "$BC2" = "15000" ] && [ "$(jget "$K2" "d['account']['status']")" = "CLOSED" ] && [ "$KR2" = "$Y2:15000" ] \
  && [ "$(jget "$K2" "d['refund']['expired_kurus']")" = "0" ] && [ "$(bal "$ACC2")" = "0" ] \
  && ok "kapanış sırası: kalan 150 TL, 300 TL ve 200 TL'lik iki yüklemeden EN YENİSİNE (10 günlük) iade edildi; eski yüklemeye dokunulmadı" \
  || bad "kapanış sırası: paket=${YP##*|} bakiye=$BC2 kapanış=${K2: -120} iadeler=$KR2 (beklenen $Y2:15000)"
DRIFT=$($PSQL -t -A -c "SELECT count(*) FROM mp_supplier_accounts a LEFT JOIN (SELECT account_id, sum(amount_kurus) s FROM mp_wallet_ledger GROUP BY account_id) l ON l.account_id=a.id WHERE a.balance_kurus <> COALESCE(l.s,0);")
[ "$DRIFT" = "0" ] && ok "para tutarlılığı: her hesapta bakiye = defter toplamı (fark 0)" || bad "bakiye/defter farkı olan hesap: $DRIFT"
kill_tree "$M5I"; kill_tree "$M5M"; kill_tree "$M5G"; kill "$M5F" 2>/dev/null
