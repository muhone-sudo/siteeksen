# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir. Kendi tedarikçilerini, kategorilerini ve sakinlerini SQL ile kurar (kayıt ve
# onay akışları adım 68–71'de sınandı); talep, eşleşme, öncelik penceresi, kabul, bildirim ve süre dolumunu API'den sınar.
step "73) Talep, eşleşme, öncelik penceresi, kabul (4 sınırı), bildirim, süre dolumu (078, FAZ M6)"

if go test ./services/marketplace/... -count=1 >/tmp/verify-m6-gotest.log 2>&1; then
  ok "go test ./services/marketplace/... (eşleşme: yarıçap sınırı, il, Türkiye geneli, ilçe yedeği, iki şubeden en yakını, çatışma, doğrudan talep; ücret, maskeleme)"
else
  bad "go test ./services/marketplace/...: $(tail -5 /tmp/verify-m6-gotest.log)"
fi

M6T=$(date +%s%N | tail -c 7)
$PSQL -q -c "UPDATE properties SET latitude = 40.990000, longitude = 29.030000, is_active = true WHERE id = '$DEMO_PROPERTY';
  UPDATE mp_settings SET value_int = 30 WHERE key = 'priority_window_minutes';
  UPDATE mp_settings SET value_int = 3 WHERE key = 'resident_daily_request_limit';
  UPDATE mp_settings SET value_int = 4 WHERE key = 'max_accepts_per_request';
  UPDATE mp_settings SET value_int = 72 WHERE key = 'request_ttl_hours';"
M6C=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope) VALUES ('Tesisat M6 $M6T', 10000, 'BOTH') RETURNING id;")
M6CM=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope) VALUES ('Site bakımı M6 $M6T', 20000, 'MANAGEMENT') RETURNING id;")
M6CX=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope, is_active) VALUES ('Kapalı M6 $M6T', 1000, 'BOTH', false) RETURNING id;")
M6PRO=$($PSQL -t -A -c "INSERT INTO mp_packages (name, monthly_fee_kurus, fee_discount_pct, included_requests, monthly_sms, priority_access, phone_in_showcase, rank_weight)
  VALUES ('Talep Pro $M6T', 10000, 50, 1, 1, true, true, 5) RETURNING id;")
M6FREE=$($PSQL -t -A -c "SELECT id FROM mp_packages WHERE is_default;")
for i in 1 2 3 4 5 6 7 8; do
  $PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles)
    SELECT 'Usta', 'M6-$i', '+90555000960$i', password_hash, now(), now(), ARRAY['SUPPLIER'] FROM users WHERE phone='+905551234567'
    ON CONFLICT (phone) DO NOTHING;"
done
for r in 1 2; do
  $PSQL -q -c "INSERT INTO users (first_name, last_name, phone, password_hash, password_set_at, kvkk_consent_at, roles, active_property_id)
    SELECT 'Sakin', 'M6-$r', '+90555000961$r', password_hash, now(), now(), ARRAY['RESIDENT'], '$DEMO_PROPERTY' FROM users WHERE phone='+905551234567'
    ON CONFLICT (phone) DO NOTHING;
    INSERT INTO resident_units (resident_id, unit_id, role, start_date)
    SELECT id, '33333333-3333-3333-3333-33333333332$r', 'OWNER', CURRENT_DATE FROM users WHERE phone='+90555000961$r'
      AND NOT EXISTS (SELECT 1 FROM resident_units ru JOIN users u ON u.id = ru.resident_id WHERE u.phone='+90555000961$r');"
done
# Hesap: telefon, paket, dahil talep, SMS hakkı. Bakiye defterle birlikte yüklenir (bakiye = defter toplamı).
m6acc() { $PSQL -t -A -c "INSERT INTO mp_supplier_accounts (user_id, trade_name, status, package_id, terms_accepted_at, period_included_left, period_sms_left)
  SELECT id, 'M6 $1', 'APPROVED', '$2', now(), $3, $4 FROM users WHERE phone='$1'
  ON CONFLICT (user_id) DO UPDATE SET status='APPROVED', package_id=EXCLUDED.package_id, period_included_left=EXCLUDED.period_included_left,
    period_sms_left=EXCLUDED.period_sms_left RETURNING id;"; }
m6fund() { $PSQL -q -c "WITH u AS (UPDATE mp_supplier_accounts SET balance_kurus = balance_kurus + $2 WHERE id='$1' RETURNING balance_kurus)
  INSERT INTO mp_wallet_ledger (account_id, kind, amount_kurus, balance_after, note) SELECT '$1', 'TOPUP', $2, balance_kurus, 'verify M6' FROM u;"; }
m6biz() { $PSQL -t -A -c "WITH b AS (INSERT INTO mp_businesses (account_id, name, phone, address, city, district, latitude, longitude, service_area, radius_km, status)
  VALUES ('$1', '$2 $M6T', '+902165550000', 'Moda Cad. 1', 'İstanbul', 'Kadıköy', $3, 29.030000, 'KM', $4, 'PUBLISHED') RETURNING id, account_id)
  INSERT INTO mp_business_categories (business_id, category_id, account_id) SELECT id, '$5', account_id FROM b RETURNING business_id;"; }
P1=$(m6acc +905550009601 "$M6PRO" 1 1); F1=$(m6acc +905550009602 "$M6FREE" 0 0); F2=$(m6acc +905550009603 "$M6FREE" 0 0)
F3=$(m6acc +905550009604 "$M6FREE" 0 0); F4=$(m6acc +905550009605 "$M6FREE" 0 0); F5=$(m6acc +905550009606 "$M6FREE" 0 0)
NB=$(m6acc +905550009607 "$M6FREE" 0 0); FAR=$(m6acc +905550009608 "$M6FREE" 0 0)
CONF=$($PSQL -t -A -c "INSERT INTO mp_supplier_accounts (user_id, trade_name, status, package_id, terms_accepted_at)
  SELECT id, 'Yönetici Tesisat', 'APPROVED', '$M6FREE', now() FROM users WHERE phone='+905551234567'
  ON CONFLICT (user_id) DO UPDATE SET status='APPROVED' RETURNING id;")
for a in $P1 $F1 $F2 $F3 $F4 $F5 $CONF; do m6fund "$a" 50000; done
m6biz "$P1" 'Pro Tesisat' 40.995000 10 "$M6C" >/dev/null
m6biz "$F1" 'F1 Tesisat' 40.992000 10 "$M6C" >/dev/null
F2B=$(m6biz "$F2" 'F2 Tesisat' 40.993000 10 "$M6C")
m6biz "$F3" 'F3 Tesisat' 40.994000 10 "$M6C" >/dev/null
m6biz "$F4" 'F4 Tesisat' 40.996000 10 "$M6C" >/dev/null
F5FAR=$(m6biz "$F5" 'F5 Uzak şube' 41.030000 10 "$M6C"); F5NEAR=$(m6biz "$F5" 'F5 Yakın şube' 40.991000 5 "$M6C")
m6biz "$NB" 'Bakiyesiz Tesisat' 40.997000 10 "$M6C" >/dev/null
m6biz "$FAR" 'Uzak Tesisat' 41.080000 2 "$M6C" >/dev/null
m6biz "$CONF" 'Yönetici Tesisat' 40.990500 10 "$M6C" >/dev/null
m6biz "$CONF" 'Yönetici Site Bakım' 40.990500 10 "$M6CM" >/dev/null
m6biz "$F1" 'F1 Site Bakım' 40.992000 10 "$M6CM" >/dev/null

rm -f /tmp/fake-netgsm.log
python3 /tmp/fake-netgsm.py 19939 >/dev/null 2>&1 &
M6N=$!
m6svc() { env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen DB_SSLMODE=disable \
  STORAGE_BACKEND=local STORAGE_LOCAL_DIR=/tmp/verify-m3-files MARKET_JOBS_INTERVAL=2s \
  NETGSM_USERCODE=8501112233 NETGSM_PASSWORD=api-sifre NETGSM_MSGHEADER=SITEEKSEN NETGSM_API_URL=http://127.0.0.1:19939 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./$2 >/tmp/verify-m6-$(basename "$2").log 2>&1 & }
m6svc 19931 services/identity siteeksen_identity "$IDPW"; M6I=$!
m6svc 19932 services/marketplace siteeksen_app "$APPPW"; M6M=$!
M6GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M6GWENV="$M6GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M6GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19931 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19932 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19930 go run ./cmd/gateway >/tmp/verify-m6-gateway.log 2>&1 &
M6G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19931/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19932/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19930/health >/dev/null 2>&1 && break; sleep 1
done
M6=http://127.0.0.1:19930/api/v1/market
m6login() { curl -s -X POST "http://127.0.0.1:19930/api/v1/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"Demo123!\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
m6() { curl -s -w '|%{http_code}' -X "$1" "$M6$2" -H "$3" -H "$J" ${4:+-d "$4"}; }
jget() { python3 -c "import json,sys; d=json.loads(sys.argv[1].rsplit('|',1)[0]); print(eval(sys.argv[2]))" "$1" "$2" 2>/dev/null; }
hdr() { echo "Authorization: Bearer $(m6login "$1")"; }
HP1=$(hdr 5550009601); HF1=$(hdr 5550009602); HF2=$(hdr 5550009603); HNB=$(hdr 5550009607); HFAR=$(hdr 5550009608)
R1=$(hdr 5550009611); R2=$(hdr 5550009612); MG=$(hdr 5551234567)
declare -A HF=([$F1]="$HF1" [$F2]="$HF2" [$F3]="$(hdr 5550009604)" [$F4]="$(hdr 5550009605)" [$F5]="$(hdr 5550009606)")
m6sql() { $PSQL -t -A -c "$1"; }

# Talep açma kuralları
RC=$(m6 GET "/requests/match-count?category_id=$M6C" "$R1"); RCM=$(m6 GET "/requests/match-count?category_id=$M6CM&buyer_type=MANAGEMENT" "$MG")
N0=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Musluk\"}")
N1=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"RESIDENT\",\"description\":\"Ortak alan\",\"consent\":true}")
N2=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Ortak alan\",\"consent\":true}")
N3=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6CX\",\"buyer_type\":\"RESIDENT\",\"description\":\"x\",\"consent\":true}")
[ "$(jget "$RC" "d['count']")" = "8" ] && [ "$(jget "$RCM" "d['count']")" = "1" ] && [ "${N0##*|}" = "422" ] && [ "$(jget "$N0" "d['code']")" = "CONSENT" ] \
  && [ "$(jget "$N1" "d['code']")" = "CATEGORY_SCOPE" ] && [ "${N2##*|}" = "403" ] && [ "$(jget "$N3" "d['code']")" = "CATEGORY" ] \
  && ok "talep açma: uygun işletme sayısı 8 (alan dışı hariç); yönetim talebinde yöneticinin kendi hesabı sayılmıyor (1); rızasız 422, yönetim kategorisinde sakin 422, sakin site adına 403, kapalı kategori 422" \
  || bad "talep açma kuralları: sayı=$RC yönetim=$RCM rızasız=$N0 kapsam=${N1: -80} rol=${N2##*|} kapalı=${N3: -60}"

# Alan dışı tek işletme: sayı 0 ve talep açılmaz; Türkiye geneli işletme eklenince 1
M6CE=$($PSQL -t -A -c "INSERT INTO mp_categories (name, request_fee_kurus, buyer_scope) VALUES ('Nakliye M6 $M6T', 5000, 'BOTH') RETURNING id;")
m6biz "$FAR" 'Uzak Nakliye' 41.080000 2 "$M6CE" >/dev/null
E0=$(m6 GET "/requests/match-count?category_id=$M6CE" "$R1")
E1=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6CE\",\"buyer_type\":\"RESIDENT\",\"description\":\"Eşya taşıma\",\"consent\":true}")
$PSQL -q -c "WITH b AS (INSERT INTO mp_businesses (account_id, name, phone, address, city, district, latitude, longitude, service_area, status)
  VALUES ('$NB', 'Türkiye Geneli Nakliye $M6T', '+903125550000', 'Ulus', 'Ankara', 'Altındağ', 39.940000, 32.850000, 'COUNTRY', 'PUBLISHED') RETURNING id, account_id)
  INSERT INTO mp_business_categories (business_id, category_id, account_id) SELECT id, '$M6CE', account_id FROM b;"
E2=$(m6 GET "/requests/match-count?category_id=$M6CE" "$R1")
[ "$(jget "$E0" "d['count']")" = "0" ] && [ "${E1##*|}" = "422" ] && [ "$(jget "$E1" "d['code']")" = "NO_SUPPLIER" ] && [ "$(jget "$E2" "d['count']")" = "1" ] \
  && [ "$(m6sql "SELECT count(*) FROM mp_requests WHERE category_id='$M6CE';")" = "0" ] \
  && ok "uygun işletme yokken (yalnız alan dışı) sayı 0 ve talep açılmıyor (422, kayıt yok); Türkiye geneli işletme eklenince 1" \
  || bad "uygun işletme sayısı: alan dışı=$E0 talep=${E1: -100} Türkiye geneli=$E2"

Q1=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Mutfak musluğu damlatıyor, 0532 123 45 67 arayın\",\"preferred_time\":\"Akşam\",\"consent\":true}")
REQ1=$(jget "$Q1" "d['request']['id']")
QD=$(m6sql "SELECT description FROM mp_requests WHERE id='$REQ1';")
QC=$(m6sql "SELECT contact_phone FROM mp_request_contacts WHERE request_id='$REQ1';")
QDISP=$(m6sql "SELECT count(*) || '|' || count(*) FILTER (WHERE account_id='$FAR') || '|' || count(*) FILTER (WHERE account_id='$CONF') || '|' ||
  (SELECT business_id FROM mp_request_dispatch WHERE request_id='$REQ1' AND account_id='$F5') FROM mp_request_dispatch WHERE request_id='$REQ1';")
[ "${Q1##*|}" = "201" ] && [ "$(jget "$Q1" "d['dispatched']")" = "8" ] && ! echo "$QD" | grep -q '0532' && echo "$QD" | grep -q 'gizlendi' \
  && [ "$QC" = "+905550009611" ] && [ "$QDISP" = "8|0|1|$F5NEAR" ] \
  && ok "talep açıldı: açıklamadaki telefon gizlendi; 8 hesaba gönderildi (alan dışı yok, sakin talebinde yönetici-tedarikçi var); iki şubeli hesaba tek gönderim, en yakın şubeyle" \
  || bad "talep: ${Q1: -120} açıklama=$QD iletişim=$QC gönderim=$QDISP (uzak=$F5FAR yakın=$F5NEAR)"

# Öncelik penceresi ve önizleme
L1=$(m6 GET /supplier/requests "$HF1"); G1=$(m6 GET "/supplier/requests/$REQ1" "$HF1"); A1=$(m6 POST "/supplier/requests/$REQ1/accept" "$HF1")
LP=$(m6 GET /supplier/requests "$HP1"); GP=$(m6 GET "/supplier/requests/$REQ1" "$HP1")
WIN=$(m6sql "SELECT round(extract(epoch FROM d.visible_at - r.created_at)) FROM mp_request_dispatch d JOIN mp_requests r ON r.id=d.request_id WHERE d.request_id='$REQ1' AND d.account_id='$F1';")
[ "$(jget "$L1" "len([x for x in d['data'] if x['id']=='$REQ1'])")" = "0" ] && [ "${G1##*|}" = "404" ] && [ "${A1##*|}" = "404" ] \
  && [ "$(jget "$LP" "len([x for x in d['data'] if x['id']=='$REQ1'])")" = "1" ] && [ "$WIN" = "1800" ] \
  && ok "öncelik penceresi: ücretsiz hesap talebi listede görmüyor, kimlikle 404, kabul 404; ücretli hesap hemen görüyor; ücretsize görünürlük +30 dk" \
  || bad "pencere: ücretsiz liste=${L1: -80} tek=${G1##*|} kabul=${A1##*|} ücretli=${LP: -80} fark=$WIN"
[ "${GP##*|}" = "200" ] && [ "$(jget "$GP" "'contact' in d or 'contact_name' in d or 'site_address' in d")" = "False" ] && ! echo "$GP" | grep -q '5550009611\|Sakin' \
  && [ "$(jget "$GP" "(d['fee_kurus'], d['uses_included'], d['district'])")" = "(5000, True, 'Kadıköy')" ] \
  && ok "maskeli önizleme: ad, telefon, adres yok; ilçe ve paket indirimli ücret (100 TL → 50 TL), dahil talep hakkı kullanılacağı belli" \
  || bad "önizleme: ${GP:0:300}"
NP=$(m6sql "SELECT string_agg(channel, ',' ORDER BY channel) FROM notifications WHERE topic='market.request.new' AND supplier_account_id='$P1';")
NF=$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.request.new' AND supplier_account_id='$F1';")
SMSP=$(grep -c '"no": "5550009601"' /tmp/fake-netgsm.log 2>/dev/null)
[ "$NP" = "IN_APP,SMS" ] && [ "$NF" = "0" ] && [ "$SMSP" = "1" ] && [ "$(m6sql "SELECT period_sms_left FROM mp_supplier_accounts WHERE id='$P1';")" = "0" ] \
  && ok "bildirim: ücretli hesaba hemen uygulama içi + SMS (sahte Netgsm'e düştü, SMS hakkı 1 → 0); ücretsiz hesaba pencere içinde bildirim yok" \
  || bad "ilk bildirim: ücretli=$NP ücretsiz=$NF sms=$SMSP"

# Pencere biter → zamanlayıcı ücretsizlere bildirir (SMS yok)
m6sql "UPDATE mp_request_dispatch SET visible_at = now() - interval '1 second' WHERE request_id='$REQ1' AND visible_at > now();" >/dev/null
for _ in $(seq 1 15); do
  [ "$(m6sql "SELECT count(*) FROM mp_request_dispatch WHERE request_id='$REQ1' AND notified_at IS NULL;")" = "0" ] && break; sleep 1
done
NF2=$(m6sql "SELECT string_agg(channel, ',') FROM notifications WHERE topic='market.request.new' AND supplier_account_id='$F1';")
L1b=$(m6 GET /supplier/requests "$HF1")
[ "$NF2" = "IN_APP" ] && [ "$(jget "$L1b" "len([x for x in d['data'] if x['id']=='$REQ1'])")" = "1" ] && [ "$(grep -c '"no": "5550009602"' /tmp/fake-netgsm.log)" = "0" ] \
  && ok "pencere bitince zamanlayıcı ücretsiz hesaba bildirdi (yalnız uygulama içi, SMS yok); talep listesinde göründü" \
  || bad "pencere sonu: bildirim=$NF2 liste=${L1b: -100}"

# Eşzamanlı kabul: 5 hesap, en çok 4
rm -f /tmp/verify-m6-race.txt; M6RACE=""
for a in $F1 $F2 $F3 $F4 $F5; do
  ( curl -s -o /dev/null -w '%{http_code}\n' -X POST "$M6/supplier/requests/$REQ1/accept" -H "${HF[$a]}" >>/tmp/verify-m6-race.txt ) &
  M6RACE="$M6RACE $!"
done
for p in $M6RACE; do wait "$p"; done
RACE=$(sort /tmp/verify-m6-race.txt 2>/dev/null | uniq -c | awk '{print $2"x"$1}' | tr '\n' ' ')
RL=$(m6sql "SELECT count(*) FROM mp_wallet_ledger l JOIN mp_request_dispatch d ON d.id=l.dispatch_id WHERE d.request_id='$REQ1' AND l.kind='REQUEST_FEE' AND l.amount_kurus=-10000;")
RS=$(m6sql "SELECT status || '|' || accepted_count FROM mp_requests WHERE id='$REQ1';")
AP=$(m6 POST "/supplier/requests/$REQ1/accept" "$HP1")
WIN1=$(m6sql "SELECT account_id FROM mp_request_dispatch WHERE request_id='$REQ1' AND accepted_at IS NOT NULL LIMIT 1;")
LOSE=$(m6sql "SELECT account_id FROM mp_request_dispatch WHERE request_id='$REQ1' AND accepted_at IS NULL AND account_id IN ('$F1','$F2','$F3','$F4','$F5');")
AG=$(m6 POST "/supplier/requests/$REQ1/accept" "${HF[$WIN1]}")
[ "$RACE" = "200x4 409x1 " ] && [ "$RL" = "4" ] && [ "$RS" = "FULL|4" ] && [ "$(jget "$AP" "d['code']")" = "FULL" ] && [ "$(jget "$AG" "d['code']")" = "ALREADY_ACCEPTED" ] \
  && ok "eşzamanlı 5 kabul: tam 4 başarı, 1 red (409); defterde tam 4 ücret satırı (100 TL); talep DOLU; sonra gelen 409; aynı hesap ikinci kez 409" \
  || bad "eşzamanlı kabul: sonuç=$RACE defter=$RL talep=$RS geç=${AP: -60} tekrar=${AG: -60}"
CW=$(m6 GET "/supplier/requests/$REQ1" "${HF[$WIN1]}"); CL=$(m6 GET "/supplier/requests/$REQ1" "${HF[$LOSE]}")
[ "$(jget "$CW" "d['contact']['phone']")" = "+905550009611" ] && [ "$(jget "$CW" "d['contact']['site_name']")" != "" ] && [ "$(jget "$CL" "'contact' in d")" = "False" ] \
  && ok "kabul eden iletişim bilgisini (ad, telefon, site adresi) görüyor; kabul edemeyen görmüyor" \
  || bad "iletişim: kabul eden=${CW: -200} edemeyen=${CL: -120}"

# Pencere ayarı, bakiyesiz hesap, dahil talep, telefonu gizli talep, SMS hakkı bitmiş ücretli hesap
m6sql "UPDATE mp_settings SET value_int = 45 WHERE key = 'priority_window_minutes';" >/dev/null
Q2=$(m6 POST /requests "$R2" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Kombi su kaçırıyor\",\"phone_hidden\":true,\"consent\":true}")
REQ2=$(jget "$Q2" "d['request']['id']")
WIN2=$(m6sql "SELECT round(extract(epoch FROM d.visible_at - r.created_at)) FROM mp_request_dispatch d JOIN mp_requests r ON r.id=d.request_id WHERE d.request_id='$REQ2' AND d.account_id='$F1';")
m6sql "UPDATE mp_request_dispatch SET visible_at = now() - interval '1 second' WHERE request_id='$REQ2';" >/dev/null
LNB=$(m6 GET /supplier/requests "$HNB"); ANB=$(m6 POST "/supplier/requests/$REQ2/accept" "$HNB")
NBB=$(m6sql "SELECT balance_kurus || '|' || (SELECT count(*) FROM mp_wallet_ledger WHERE account_id='$NB') FROM mp_supplier_accounts WHERE id='$NB';")
[ "$WIN2" = "2700" ] && [ "$(jget "$LNB" "[x['can_afford'] for x in d['data'] if x['id']=='$REQ2']")" = "[False]" ] \
  && [ "${ANB##*|}" = "409" ] && [ "$(jget "$ANB" "d['code']")" = "INSUFFICIENT_BALANCE" ] && [ "$NBB" = "0|0" ] \
  && ok "pencere ayarı 45 dk yapılınca görünürlük +45 dk; bakiyesi 0 olan hesap talebi listede görüyor (karşılayamaz işaretli), kabulü 409 ve bakiye/defter değişmedi" \
  || bad "ayar/bakiyesiz: fark=$WIN2 liste=${LNB: -120} kabul=${ANB: -100} bakiye=$NBB"
PB0=$(m6sql "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$P1';")
AP2=$(m6 POST "/supplier/requests/$REQ2/accept" "$HP1")
PB1=$(m6sql "SELECT balance_kurus || '|' || period_included_left FROM mp_supplier_accounts WHERE id='$P1';")
PL=$(m6sql "SELECT l.kind || '|' || l.amount_kurus FROM mp_wallet_ledger l JOIN mp_request_dispatch d ON d.id=l.dispatch_id WHERE d.request_id='$REQ2' AND d.account_id='$P1';")
[ "${AP2##*|}" = "200" ] && [ "$PB1" = "$PB0|0" ] && [ "$PL" = "INCLUDED_REQUEST|0" ] && [ "$(jget "$AP2" "d['request']['contact']['phone']")" = "None" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.request.new' AND supplier_account_id='$P1' AND channel='SMS';")" = "1" ] \
  && ok "dahil talep hakkıyla kabul: bakiye değişmedi, hak 1 → 0, defterde 0 TL hak satırı; telefonu gizli talepte iletişimde telefon yok; SMS hakkı biten ücretliye ikinci SMS yok" \
  || bad "dahil talep: ${AP2: -160} bakiye=$PB0→$PB1 defter=$PL"

# Komşu ve sakin kapsamı
NG2=$(m6 GET "/requests/$REQ1" "$R2"); NL2=$(m6 GET /requests "$R2"); OWN=$(m6 GET "/requests/$REQ1" "$R1")
[ "${NG2##*|}" = "404" ] && [ "$(jget "$NL2" "len([x for x in d['data'] if x['id']=='$REQ1'])")" = "0" ] && [ "$(jget "$OWN" "len(d['accepted'])")" = "4" ] \
  && ok "aynı sitedeki komşu başkasının talebini kimlikle isteyince 404, listesinde yok; talep sahibi kabul eden 4 işletmeyi görüyor" \
  || bad "komşu: tek=${NG2##*|} liste=${NL2: -100} sahibi=${OWN: -120}"

# Doğrudan talep ve günlük sınır
Q3=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Doğrudan talep\",\"target_business_id\":\"$F2B\",\"consent\":true}")
REQ3=$(jget "$Q3" "d['request']['id']")
D3=$(m6sql "SELECT count(*) || '|' || string_agg(account_id::text, ',') || '|' || bool_and(visible_at <= now()) FROM mp_request_dispatch WHERE request_id='$REQ3';")
F2B0=$(m6sql "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$F2';")
A3=$(m6 POST "/supplier/requests/$REQ3/accept" "$HF2")
F2B1=$(m6sql "SELECT balance_kurus FROM mp_supplier_accounts WHERE id='$F2';")
[ "${Q3##*|}" = "201" ] && [ "$D3" = "1|$F2|true" ] && [ "${A3##*|}" = "200" ] && [ "$((F2B0 - F2B1))" = "10000" ] \
  && [ "$(m6sql "SELECT status || '|' || max_accepts FROM mp_requests WHERE id='$REQ3';")" = "FULL|1" ] \
  && [ "$(m6sql "SELECT count(*) FROM notifications WHERE topic='market.request.new' AND supplier_account_id='$F2' AND payload->>'request_id'='$REQ3';")" -ge 1 ] \
  && ok "doğrudan talep yalnız hedef işletmeye gitti, ücretsiz pakette de hemen görünür ve bildirildi (pencere/kota yok); kabulde aynı ücret (100 TL) düştü" \
  || bad "doğrudan talep: ${Q3: -120} gönderim=$D3 kabul=${A3: -100} bakiye=$F2B0→$F2B1"
Q4=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Üçüncü talep\",\"consent\":true}")
REQ4=$(jget "$Q4" "d['request']['id']")
Q5=$(m6 POST /requests "$R1" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Dördüncü\",\"consent\":true}")
[ "${Q4##*|}" = "201" ] && [ "${Q5##*|}" = "429" ] && [ "$(jget "$Q5" "d['code']")" = "DAILY_LIMIT" ] \
  && ok "sakin günlük talep sınırı (3): dördüncü talep 429" || bad "günlük sınır: üçüncü=${Q4##*|} dördüncü=${Q5: -80}"

# Yönetim talebi: çıkar çatışması
QM=$(m6 POST /requests "$MG" "{\"category_id\":\"$M6CM\",\"buyer_type\":\"MANAGEMENT\",\"description\":\"Ortak alan boyası\"}")
REQM=$(jget "$QM" "d['request']['id']")
DM=$(m6sql "SELECT count(*) FILTER (WHERE account_id='$CONF') || '|' || count(*) FILTER (WHERE account_id='$F1') FROM mp_request_dispatch WHERE request_id='$REQM';")
ML=$(m6 GET "/requests?scope=management" "$MG"); RL1=$(m6 GET "/requests?scope=management" "$R1")
[ "${QM##*|}" = "201" ] && [ "$DM" = "0|1" ] && [ "$(jget "$ML" "len([x for x in d['data'] if x['id']=='$REQM'])")" = "1" ] && [ "${RL1##*|}" = "403" ] \
  && ok "yönetim talebi: sitede yönetim görevi olan kişinin tedarikçi hesabına gönderilmedi (çıkar çatışması); site talepleri yönetimde listeleniyor, sakine 403" \
  || bad "yönetim talebi: ${QM: -120} gönderim=$DM liste=${ML: -80} sakin=${RL1##*|}"

# Fotoğraf: sahibi ekler; gönderilen tedarikçi görür; gönderilmeyen ve komşu göremez
PH=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$M6/requests/$REQ1/photos" -H "$R1" -F "file=@/tmp/verify-m3-kimlik.png")
PS=$(code "$M6/supplier/requests/$REQ1/photos/0" -H "${HF[$WIN1]}"); PF=$(code "$M6/supplier/requests/$REQ1/photos/0" -H "$HFAR")
PN=$(code "$M6/requests/$REQ1/photos/0" -H "$R2"); PO=$(code "$M6/requests/$REQ1/photos/0" -H "$R1")
[ "$PH$PS$PF$PN$PO" = "200200404404200" ] \
  && ok "talep fotoğrafı: sahibi ekledi ve görüyor; talebin gönderildiği tedarikçi görüyor; gönderilmeyen tedarikçi ve komşu 404" \
  || bad "fotoğraf: ekle=$PH tedarikçi=$PS gönderilmeyen=$PF komşu=$PN sahibi=$PO"

# Süre dolumu
m6sql "UPDATE mp_requests SET expires_at = now() - interval '1 second' WHERE id='$REQ4';" >/dev/null
for _ in $(seq 1 15); do [ "$(m6sql "SELECT status FROM mp_requests WHERE id='$REQ4';")" = "EXPIRED" ] && break; sleep 1; done
EX=$(m6sql "SELECT status FROM mp_requests WHERE id='$REQ4';")
EN=$(m6sql "SELECT count(*) FROM notifications n JOIN users u ON u.id=n.recipient_user_id WHERE n.topic='market.request.expired' AND u.phone='+905550009611' AND n.payload->>'request_id'='$REQ4';")
AX=$(m6 POST "/supplier/requests/$REQ4/accept" "$HP1")
[ "$EX" = "EXPIRED" ] && [ "$EN" = "1" ] && [ "${AX##*|}" = "409" ] && [ "$(jget "$AX" "d['code']")" = "CLOSED" ] \
  && ok "süresi dolan talep zamanlayıcıyla kapandı, sahibine bildirildi; kapanan talep kabul edilemez (409)" \
  || bad "süre dolumu: durum=$EX bildirim=$EN kabul=${AX: -80}"

# Pasif site
m6sql "UPDATE properties SET is_active = false WHERE id='$DEMO_PROPERTY';" >/dev/null
QP=$(m6 POST /requests "$R2" "{\"category_id\":\"$M6C\",\"buyer_type\":\"RESIDENT\",\"description\":\"Pasif sitede\",\"consent\":true}")
m6sql "UPDATE properties SET is_active = true WHERE id='$DEMO_PROPERTY';" >/dev/null
[ "${QP##*|}" = "409" ] && [ "$(jget "$QP" "d['code']")" = "PROPERTY_INACTIVE" ] && ok "pasif sitede talep açılamıyor (409)" || bad "pasif site: ${QP: -100}"

[ "$(m6sql "SELECT count(*) FROM audit_logs WHERE event='market.request.accepted';")" -ge 6 ] \
  && ok "kabul (iletişim bilgisinin açılması) işlem kaydında adıyla" || bad "kabul işlem kaydı yok"
DRIFT=$(m6sql "SELECT count(*) FROM mp_supplier_accounts a LEFT JOIN (SELECT account_id, sum(amount_kurus) s FROM mp_wallet_ledger GROUP BY account_id) l ON l.account_id=a.id WHERE a.balance_kurus <> COALESCE(l.s,0);")
[ "$DRIFT" = "0" ] && ok "para tutarlılığı: her hesapta bakiye = defter toplamı (fark 0)" || bad "bakiye/defter farkı olan hesap: $DRIFT"
kill_tree "$M6I"; kill_tree "$M6M"; kill_tree "$M6G"; kill "$M6N" 2>/dev/null
