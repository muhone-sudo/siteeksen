# shellcheck shell=bash
# verify-stack.sh tarafından `source` edilir.
step "69) Pazaryeri veri modeli ve servis: kapsamlar (site/tedarikçi/platform), değiştirilemez defter, sitesiz bildirim, site konumu (077, FAZ M2)"

if python3 "$SCRIPT_DIR/check-market-contract.py" >/tmp/verify-m2-contract.log 2>&1; then
  ok "$(tail -1 /tmp/verify-m2-contract.log) (tasks/api-sozlesmesi.md)"
else
  bad "pazaryeri uçları sözleşmede eksik"; sed 's/^/      /' /tmp/verify-m2-contract.log
fi

# --- Kapsam ve RLS: uygulama rolüyle, oturum değişkeni ayarlanarak ---
# m2app <kapsam SQL'i> <sorgu>: tek transaction'da kapsamı ayarlar, sorguyu çalıştırır, tek değer döner.
m2app() { PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen -t -A -q -v ON_ERROR_STOP=1 \
  -c "BEGIN; $1 $2; COMMIT;" 2>&1 | grep -v '^\(BEGIN\|COMMIT\|SET\)$' | tail -1; }
m2fails() { ! PGPASSWORD="$APPPW" psql -h 127.0.0.1 -p "${DBPORT}" -U siteeksen_app -d siteeksen -q -v ON_ERROR_STOP=1 \
  -c "BEGIN; $1 $2; ROLLBACK;" >/dev/null 2>&1; }
SUPA="SELECT set_config('app.supplier_account_id', '7b000000-0000-4000-8000-00000000000a', true);"
SUPB="SELECT set_config('app.supplier_account_id', '7b000000-0000-4000-8000-00000000000b', true);"
PLAT="SELECT set_config('app.platform_user_id', 'verify', true);"
SITE="SELECT set_config('app.property_id', '$DEMO_PROPERTY', true);"
M2UA=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550009101';")
M2UB=$($PSQL -t -A -c "SELECT id FROM users WHERE phone='+905550009103';")
$PSQL -q -c "INSERT INTO mp_supplier_accounts (id, user_id, package_id, terms_accepted_at, balance_kurus) VALUES
  ('7b000000-0000-4000-8000-00000000000a', '$M2UA', '7a000000-0000-4000-8000-000000000001', now(), 1000),
  ('7b000000-0000-4000-8000-00000000000b', '$M2UB', '7a000000-0000-4000-8000-000000000001', now(), 0)
  ON CONFLICT (id) DO NOTHING;"
OWN=$(m2app "$SUPA" "SELECT count(*) FROM mp_supplier_accounts")
OTHER=$(m2app "$SUPA" "SELECT count(*) FROM mp_supplier_accounts WHERE id='7b000000-0000-4000-8000-00000000000b'")
NONE=$(m2app "" "SELECT count(*) FROM mp_supplier_accounts")
SITEV=$(m2app "$SITE" "SELECT count(*) FROM mp_supplier_accounts")
ALL=$(m2app "$PLAT" "SELECT count(*) FROM mp_supplier_accounts")
[ "$OWN" = "1" ] && [ "$OTHER" = "0" ] && [ "$NONE" = "0" ] && [ "$SITEV" = "0" ] && [ "$ALL" -ge 2 ] \
  && ok "tedarikçi hesabı: kendi kapsamında yalnız kendi satırı (B'ninki 0); kapsamsız ve site kapsamında 0; platform hepsini görür ($ALL)" \
  || bad "hesap kapsamı: kendi=$OWN başkası=$OTHER kapsamsız=$NONE site=$SITEV platform=$ALL"
m2fails "$SUPA" "UPDATE mp_supplier_accounts SET balance_kurus = 999 WHERE id='7b000000-0000-4000-8000-00000000000b' RETURNING 1/0" \
  && ok "tedarikçi A, B'nin bakiyesini değiştiremiyor (satır görünmüyor)" || bad "tedarikçi A başka hesabın satırını güncelleyebildi"
UA=$(m2app "$SUPA" "SELECT count(*) FROM users WHERE id='$M2UA'")
UB=$(m2app "$SUPA" "SELECT count(*) FROM users WHERE id='$M2UB'")
UM=$(m2app "$SUPA" "SELECT count(*) FROM users WHERE phone='+905551234567'")
[ "$UA" = "1" ] && [ "$UB" = "0" ] && [ "$UM" = "0" ] \
  && ok "kişi tablosu: tedarikçi yalnız kendi kaydını okuyor (başka tedarikçi ve site sakini 0)" || bad "users kapsamı: kendi=$UA başka=$UB sakin=$UM"
m2fails "$SUPA" "UPDATE mp_supplier_accounts SET balance_kurus = -1" \
  && ok "bakiye eksiye düşemiyor (CHECK balance_kurus >= 0)" || bad "bakiye eksiye yazılabildi"

# Defter: eklenir, değiştirilemez, silinemez; yön kuralı
m2app "$SUPA" "INSERT INTO mp_wallet_ledger (account_id, kind, amount_kurus, balance_after, note) VALUES ('7b000000-0000-4000-8000-00000000000a', 'TOPUP', 1000, 1000, 'verify') RETURNING 1" >/dev/null
LID=$($PSQL -t -A -c "SELECT id FROM mp_wallet_ledger WHERE note='verify' LIMIT 1;")
m2fails "$SUPA" "UPDATE mp_wallet_ledger SET amount_kurus = 5 WHERE id='$LID'" && D1=1 || D1=0
$PSQL -c "DELETE FROM mp_wallet_ledger WHERE id='$LID';" >/dev/null 2>&1 && D2=0 || D2=1
m2fails "$SUPA" "INSERT INTO mp_wallet_ledger (account_id, kind, amount_kurus, balance_after) VALUES ('7b000000-0000-4000-8000-00000000000a', 'REQUEST_FEE', 500, 500)" && D3=1 || D3=0
m2fails "$SUPB" "INSERT INTO mp_wallet_ledger (account_id, kind, amount_kurus, balance_after) VALUES ('7b000000-0000-4000-8000-00000000000a', 'TOPUP', 500, 500)" && D4=1 || D4=0
[ -n "$LID" ] && [ "$D1$D2$D3$D4" = "1111" ] \
  && ok "bakiye defteri: güncelleme ve (süper kullanıcıyla bile) silme reddedildi; ücret artı yazılamıyor; B, A'nın defterine yazamıyor" \
  || bad "defter: satır=$LID güncelleme-red=$D1 silme-red=$D2 yön-red=$D3 başkası-red=$D4"

# Puan/yorum değiştirilemez (süper kullanıcıyla zincir kurulur: tetikleyiciler süper kullanıcıda da çalışır)
M2TAG=$(date +%s%N)
M2UNIT=$($PSQL -t -A -c "SELECT id FROM units WHERE property_id='$DEMO_PROPERTY' LIMIT 1;")
M2REQ=$($PSQL -t -A -c "WITH c AS (INSERT INTO mp_categories (name, request_fee_kurus) VALUES ('Doğrulama kategorisi', 1000) ON CONFLICT (parent_id, name) DO UPDATE SET name = EXCLUDED.name RETURNING id),
  b AS (INSERT INTO mp_businesses (account_id, name, phone, address, city, district, latitude, longitude, service_area, radius_km, status)
        VALUES ('7b000000-0000-4000-8000-00000000000a', 'Doğrulama İşletmesi $M2TAG', '+905550009101', 'Adres', 'İstanbul', 'Kadıköy', 40.99, 29.03, 'KM', 10, 'PUBLISHED') RETURNING id),
  r AS (INSERT INTO mp_requests (property_id, requester_user_id, buyer_type, unit_id, category_id, description, city, district, max_accepts, consent_at, expires_at)
        SELECT '$DEMO_PROPERTY', u.id, 'RESIDENT', '$M2UNIT', c.id, 'Doğrulama talebi $M2TAG', 'İstanbul', 'Kadıköy', 4, now(), now() + interval '1 day'
        FROM users u, c WHERE u.phone='+905559876543' RETURNING id),
  d AS (INSERT INTO mp_request_dispatch (request_id, property_id, account_id, business_id, visible_at, accepted_at)
        SELECT r.id, '$DEMO_PROPERTY', '7b000000-0000-4000-8000-00000000000a', b.id, now(), now() FROM r, b RETURNING id, request_id, business_id),
  o AS (INSERT INTO mp_offers (request_id, dispatch_id, property_id, account_id, business_id, amount_kurus, description, valid_until)
        SELECT d.request_id, d.id, '$DEMO_PROPERTY', '7b000000-0000-4000-8000-00000000000a', d.business_id, 150000, 'Teklif', CURRENT_DATE + 7 FROM d RETURNING id, request_id, business_id),
  j AS (INSERT INTO mp_jobs (request_id, offer_id, property_id, account_id, business_id, status, completed_at, completion_source)
        SELECT o.request_id, o.id, '$DEMO_PROPERTY', '7b000000-0000-4000-8000-00000000000a', o.business_id, 'COMPLETED', now(), 'BUYER' FROM o RETURNING id, business_id)
  INSERT INTO mp_reviews (job_id, property_id, account_id, business_id, rating, comment)
  SELECT j.id, '$DEMO_PROPERTY', '7b000000-0000-4000-8000-00000000000a', j.business_id, 4, 'İyi iş' FROM j RETURNING id;" 2>&1)
RV1=$($PSQL -c "UPDATE mp_reviews SET rating = 5 WHERE id='$M2REQ';" >/dev/null 2>&1 && echo değişti || echo red)
RV2=$($PSQL -c "DELETE FROM mp_reviews WHERE id='$M2REQ';" >/dev/null 2>&1 && echo silindi || echo red)
RV3=$($PSQL -c "UPDATE mp_reviews SET reply = 'Teşekkürler', replied_at = now() WHERE id='$M2REQ';" >/dev/null 2>&1 && echo yazıldı || echo red)
RV4=$($PSQL -c "UPDATE mp_reviews SET reply = 'Değişti' WHERE id='$M2REQ';" >/dev/null 2>&1 && echo değişti || echo red)
RATE=$($PSQL -t -A -c "SELECT rating_sum||'/'||rating_count FROM mp_businesses WHERE name='Doğrulama İşletmesi $M2TAG';")
[ "$RV1$RV2$RV3$RV4" = "redredyazıldıred" ] && [ "$RATE" = "4/1" ] \
  && ok "yorum: puan değiştirilemiyor, silinemiyor; tedarikçi yanıtı bir kez yazılıyor; işletme puan özeti tetikleyiciyle 4/1" \
  || bad "yorum koruması: puan=$RV1 silme=$RV2 yanıt=$RV3 ikinci yanıt=$RV4 özet=$RATE (kurulum=$M2REQ)"

# Talep görünürlüğü: site kendi talebini görür; gönderilmiş tedarikçi görür; başka tedarikçi görmez; iletişim yalnız kabul edende
RS=$(m2app "$SITE" "SELECT count(*) FROM mp_requests WHERE description='Doğrulama talebi $M2TAG'")
RA=$(m2app "$SUPA" "SELECT count(*) FROM mp_requests WHERE description='Doğrulama talebi $M2TAG'")
RB=$(m2app "$SUPB" "SELECT count(*) FROM mp_requests WHERE description='Doğrulama talebi $M2TAG'")
RID=$($PSQL -t -A -c "SELECT id FROM mp_requests WHERE description='Doğrulama talebi $M2TAG' LIMIT 1;")
$PSQL -q -c "INSERT INTO mp_request_contacts (request_id, property_id, contact_name, contact_phone) VALUES ('$RID', '$DEMO_PROPERTY', 'Mehmet Demir', '+905559876543') ON CONFLICT DO NOTHING;"
CA=$(m2app "$SUPA" "SELECT count(*) FROM mp_request_contacts WHERE request_id='$RID'")
CB=$(m2app "$SUPB" "SELECT count(*) FROM mp_request_contacts WHERE request_id='$RID'")
CP=$(m2app "$PLAT" "SELECT count(*) FROM mp_request_contacts WHERE request_id='$RID'")
[ "$RS$RA$RB$CA$CB$CP" = "110100" ] \
  && ok "talep: site ve gönderilen tedarikçi görüyor, başka tedarikçi görmüyor; iletişim bilgisi yalnız kabul edende (platform bile göremiyor)" \
  || bad "talep görünürlüğü site=$RS A=$RA B=$RB · iletişim A=$CA B=$CB platform=$CP"
$PSQL -q -c "UPDATE mp_request_dispatch SET visible_at = now() + interval '30 minutes' WHERE request_id='$RID';"
RW=$(m2app "$SUPA" "SELECT count(*) FROM mp_requests WHERE id='$RID'")
RDW=$(m2app "$SUPA" "SELECT count(*) FROM mp_request_dispatch WHERE request_id='$RID'")
$PSQL -q -c "UPDATE mp_request_dispatch SET visible_at = now() WHERE request_id='$RID';"
[ "$RW$RDW" = "00" ] && ok "görünürlük zamanı gelmeden (öncelik penceresi) tedarikçi talebi ve gönderim satırını göremiyor" || bad "pencere: talep=$RW gönderim=$RDW"

# Sitesiz bildirim: tedarikçi alıcılı kayıt, tekilleştirme, kapsam
NIN="INSERT INTO notifications (supplier_account_id, recipient_user_id, recipient_address, channel, topic, body, dedupe_key) VALUES ('7b000000-0000-4000-8000-00000000000a', '$M2UA', '$M2UA', 'IN_APP', 'market.verify', 'Deneme', 'verify-dedupe') RETURNING 1"
N1=$(m2app "$SUPA" "$NIN")
m2fails "$SUPA" "$NIN" && N2=red || N2=kabul
NB=$(m2app "$SUPB" "SELECT count(*) FROM notifications WHERE topic='market.verify'")
NS=$(m2app "$SITE" "SELECT count(*) FROM notifications WHERE topic='market.verify'")
m2fails "$SUPA" "INSERT INTO notifications (recipient_address, channel, topic, body) VALUES ('x', 'IN_APP', 'market.verify', 'sahipsiz')" && N3=red || N3=kabul
m2fails "$SUPB" "INSERT INTO notifications (supplier_account_id, recipient_address, channel, topic, body) VALUES ('7b000000-0000-4000-8000-00000000000a', 'x', 'IN_APP', 'market.verify', 'başkası adına')" && N4=red || N4=kabul
[ "$N1" = "1" ] && [ "$N2$N3$N4" = "redredred" ] && [ "$NB$NS" = "00" ] \
  && ok "sitesiz bildirim: tedarikçi kapsamında yazıldı; aynı dedupe anahtarı reddedildi; sahipsiz ve başkası adına kayıt reddedildi; B ve site göremiyor" \
  || bad "sitesiz bildirim: yaz=$N1 dedupe=$N2 sahipsiz=$N3 başkası=$N4 B=$NB site=$NS"
if go test ./pkg/notify/... -count=1 >/tmp/verify-m2-notify.log 2>&1; then
  ok "go test ./pkg/notify/... (site ya da tedarikçi kapsamı, ikisi birden reddedilir)"
else
  bad "pkg/notify testleri"; tail -10 /tmp/verify-m2-notify.log
fi

# --- Servis + gateway ---
m2svc() { env DB_HOST=127.0.0.1 DB_PORT=${DBPORT} DB_USER=$3 DB_PASSWORD="$4" DB_NAME=siteeksen DB_SSLMODE=disable \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=$1 go run ./$2 >/tmp/verify-m2-$(basename "$2").log 2>&1 & }
m2svc 19971 services/identity siteeksen_identity "$IDPW"; M2I=$!
m2svc 19972 services/marketplace siteeksen_app "$APPPW"; M2M=$!
M2GWENV=""
for n in FINANCE COMMUNITY IOT NOTIFICATION EXPENSE ASSET BULLETIN CONTRACT DOCUMENT ENERGY ESG INVENTORY NPS PACKAGE PARKING \
         PATROL PERSONNEL RESERVATION SETTINGS SMART_COLLECTION SURVEY VISITOR BANKING GOVERNANCE; do
  M2GWENV="$M2GWENV ${n}_SERVICE_URL=http://127.0.0.1:9"
done
env $M2GWENV IDENTITY_SERVICE_URL=http://127.0.0.1:19971 MARKETPLACE_SERVICE_URL=http://127.0.0.1:19972 \
  JWT_SECRET=verify-secret-key-at-least-32-chars PORT=19970 go run ./cmd/gateway >/tmp/verify-m2-gateway.log 2>&1 &
M2G=$!
for _ in $(seq 1 90); do
  curl -fsS http://127.0.0.1:19971/health >/dev/null 2>&1 && curl -fsS http://127.0.0.1:19972/health >/dev/null 2>&1 \
    && curl -fsS http://127.0.0.1:19970/health >/dev/null 2>&1 && break; sleep 1
done
M2GW=http://127.0.0.1:19970/api/v1
m2login() { curl -s -X POST "$M2GW/auth/login" -H "$J" -d "{\"phone\":\"$1\",\"password\":\"$2\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
M2MGR="Authorization: Bearer $(m2login 5551234567 'Demo123!')"
M2SUPT="Authorization: Bearer $(m2login 5550000040 'Demo123!')"
[ "$(code "$M2GW/market/meta")" = "401" ] && ok "gateway → pazaryeri: kimliksiz /market/meta 401" || bad "kimliksiz meta: $(code "$M2GW/market/meta")"
META=$(curl -s "$M2GW/market/meta" -H "$M2MGR")
python3 -c "import json,sys; d=json.loads(sys.argv[1]); assert len(d['settings'])==6 and any(p['is_default'] and p['monthly_fee_kurus']==0 for p in d['packages'])" "$META" 2>/dev/null \
  && ok "gateway → pazaryeri: /market/meta 200 (6 ayar, varsayılan ücretsiz paket)" || bad "meta: ${META:0:200}"
SMS=$(curl -s -w '|%{http_code}' "$M2GW/market/supplier/me" -H "$(printf 'Authorization: Bearer %s' "$(m2login 5550009101 'Esnaf2026x')")")
SMM=$(code "$M2GW/market/supplier/me" -H "$M2MGR")
grep -q '"status":"DRAFT"' <<<"$SMS" && [ "${SMS##*|}" = "200" ] && [ "$SMM" = "403" ] \
  && ok "/market/supplier/me: tedarikçi kendi hesabını görüyor (RLS altında, uygulama rolüyle); yönetici 403" \
  || bad "supplier/me: tedarikçi=${SMS: -120} yönetici=$SMM"

# Site konumu (M2.4)
LC1=$(code -X PUT "$M2GW/property/location" -H "$M2MGR" -H "$J" -d '{"latitude":40.9901,"longitude":29.0292}')
LC2=$(code -X PUT "$M2GW/property/location" -H "$M2MGR" -H "$J" -d '{"latitude":95,"longitude":29}')
LC3=$(code -X PUT "$M2GW/property/location" -H "$M2MGR" -H "$J" -d '{"latitude":40.99}')
LC4=$(code -X PUT "$M2GW/property/location" -H "Authorization: Bearer $(m2login 5559876543 'Demo123!')" -H "$J" -d '{"latitude":1,"longitude":1}')
LCG=$(curl -s "$M2GW/property" -H "$M2MGR")
grep -q '"latitude":40.9901' <<<"$LCG" && [ "$LC1$LC2$LC3$LC4" = "200422400403" ] \
  && ok "site konumu: yönetici kaydetti (GET /property'de görünüyor); aralık dışı 422; tek alan 400; sakin 403" \
  || bad "site konumu: kaydet=$LC1 aralık=$LC2 tek=$LC3 sakin=$LC4 get=${LCG:0:160}"

$PSQL -q -c "DELETE FROM notifications WHERE topic='market.verify';" 2>/dev/null
kill_tree "$M2I"; kill_tree "$M2M"; kill_tree "$M2G"
